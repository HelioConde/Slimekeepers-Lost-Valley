"""Read-only proxy diagnostics: account eligibility, quota windows, model catalog.

Never prints or writes account identifiers, upstream IDs, email, OAuth tokens,
raw proxy responses, or error bodies. GET only, no inference, no refresh POST.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

from proxy_preflight import NoRedirect, PreflightError, normalize_origin

MODEL_PRIMARY = "gpt-6.2-astra"
MODEL_SECONDARY = "gpt-6-astra"
STATUS_ALLOWLIST = {"active", "disabled", "expired", "banned"}
SOURCE_ALLOWLIST = {"response_headers", "response_event", "usage_endpoint", "unknown"}


class DiagnosticError(RuntimeError):
    pass


def _get_json(opener, origin: str, key: str, route: str) -> dict:
    if not route.startswith("/") or "//" in route or "#" in route:
        raise DiagnosticError("invalid_route")
    request = urllib.request.Request(
        origin + route, method="GET",
        headers={"Authorization": "Bearer " + key, "Accept": "application/json"},
    )
    try:
        with opener.open(request, timeout=12) as response:
            raw = response.read(300_001)
    except urllib.error.HTTPError as error:
        # Never read/print the raw error body, which might include account data.
        raise DiagnosticError("http_" + str(error.code)) from None
    except (urllib.error.URLError, TimeoutError, OSError):
        raise DiagnosticError("upstream_unreachable") from None
    if len(raw) > 300_000:
        raise DiagnosticError("response_too_large")
    try:
        parsed = json.loads(raw)
    except (ValueError, UnicodeError):
        raise DiagnosticError("invalid_json") from None
    if not isinstance(parsed, dict):
        raise DiagnosticError("unexpected_response")
    return parsed


def _date(value):
    if not isinstance(value, str) or len(value) > 40:
        return None
    try:
        item = datetime.fromisoformat(value.replace("Z", "+00:00"))
        if item.tzinfo is None:
            return None
        return item.astimezone(timezone.utc).isoformat(timespec="seconds")
    except ValueError:
        return None


def _rate_window(item):
    if not isinstance(item, dict):
        return None
    percent = item.get("used_percent")
    if isinstance(percent, bool) or not isinstance(percent, (int, float)) or not 0 <= percent <= 100:
        percent = None
    return {
        "limit_reached": item.get("limit_reached") if type(item.get("limit_reached")) is bool else None,
        "allowed": item.get("allowed") if type(item.get("allowed")) is bool else None,
        "used_percent": percent,
        "reset_at_utc": _date(item.get("reset_at")),
    }


def _quota(item):
    if not isinstance(item, dict):
        return {"available": False}
    source = item.get("source")
    return {
        "available": True,
        "source": source if source in SOURCE_ALLOWLIST else "unrecognized",
        "primary": _rate_window(item.get("rate_limit")),
        "secondary": _rate_window(item.get("secondary_rate_limit")),
        "fetched_at_utc": _date(item.get("fetched_at")),
    }


def _account_summary(account, cached_usage, live_usage, live_error):
    status = account.get("status")
    return {
        "status": status if status in STATUS_ALLOWLIST else "unknown",
        "eligible_now": account.get("eligible_now") if type(account.get("eligible_now")) is bool else None,
        "cooldown_until_utc": _date(account.get("cooldown_until")),
        "oauth_expired": bool(
            _date(account.get("oauth_expires")) and
            datetime.fromisoformat(_date(account.get("oauth_expires"))) <= datetime.now(timezone.utc)
        ),
        "cached_quota": _quota(cached_usage.get("cached_quota") if isinstance(cached_usage, dict)
                               else account.get("cached_quota")),
        "live_quota": _quota(
            (live_usage.get("quota_runtime") or live_usage.get("cached_quota"))
            if isinstance(live_usage, dict) else None),
        "live_query": "success" if isinstance(live_usage, dict)
                      else ("failed_" + live_error if live_error else "not_requested"),
    }


def diagnose(base_url: str, api_key: str, *, live: bool = False, opener=None) -> dict:
    origin, kind = normalize_origin(base_url)
    if not isinstance(api_key, str) or len(api_key) < 20 or "\n" in api_key or "\r" in api_key:
        raise DiagnosticError("invalid_api_key")
    if opener is None:
        handlers = [NoRedirect()]
        if kind == "local_loopback":
            handlers.insert(0, urllib.request.ProxyHandler({}))
        opener = urllib.request.build_opener(*handlers)
    health = _get_json(opener, origin, api_key, "/health")
    if health.get("status") != "ok":
        raise DiagnosticError("health_not_ok")
    models = _get_json(opener, origin, api_key, "/v1/models").get("data")
    if not isinstance(models, list):
        raise DiagnosticError("models_missing")
    safe_names = {x["id"] for x in models if isinstance(x, dict) and
                  isinstance(x.get("id"), str) and
                  re.fullmatch(r"[a-zA-Z0-9._-]{1,100}", x["id"])}
    admin = _get_json(opener, origin, api_key, "/admin/accounts").get("accounts")
    if not isinstance(admin, list) or len(admin) > 20:
        raise DiagnosticError("invalid_accounts")
    accounts = []
    for item in admin:
        if not isinstance(item, dict) or not isinstance(item.get("id"), str) or not 1 <= len(item["id"]) <= 160:
            raise DiagnosticError("invalid_account_entry")
        if "/" in item["id"] or ".." in item["id"]:
            raise DiagnosticError("unsafe_account_id")
        encoded_id = urllib.parse.quote(item["id"], safe="")
        base = "/admin/accounts/" + encoded_id + "/usage"
        cached, fresh, fresh_error = None, None, None
        try:
            cached = _get_json(opener, origin, api_key, base + "?cached=true")
        except DiagnosticError:
            pass  # Account view still offers basic eligibility.
        if live:
            try:
                fresh = _get_json(opener, origin, api_key, base)
            except DiagnosticError as ex:
                fresh_error = str(ex)
        accounts.append(_account_summary(item, cached, fresh, fresh_error))
    return {
        "schema": "slimekeepers/proxy-readonly-quota-diagnostics/v1",
        "authenticated": True,
        "accounts_configured": len(admin),
        "preferred_model": MODEL_PRIMARY,
        "preferred_in_catalog": MODEL_PRIMARY in safe_names,
        "fallback_model": MODEL_SECONDARY,
        "fallback_in_catalog": MODEL_SECONDARY in safe_names,
        "catalog_count": len(safe_names),
        "model_catalog_proves_inference_capacity": False,
        "accounts": accounts,
        "live_usage_requested": live,
        "inference_requests": 0,
        "image_requests": 0,
        "credentials_exposed": False,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--live-usage", action="store_true", help="Read upstream account usage using GET only")
    args = parser.parse_args()
    try:
        result = diagnose(
            os.environ.get("CODEX_PROXY_BASE_URL", ""),
            os.environ.get("CODEX_PROXY_API_KEY", ""),
            live=args.live_usage,
        )
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(json.dumps(result, ensure_ascii=False))
    except (PreflightError, DiagnosticError, OSError, ValueError, TypeError, KeyError):
        print('{"status":"blocked","diagnostic":"read_only_failed","inference_requests":0}')
        sys.exit(2)


if __name__ == "__main__":
    main()

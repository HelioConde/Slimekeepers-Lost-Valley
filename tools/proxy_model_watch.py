"""Scheduled Slimekeepers model watch: safe GET metadata and quota gate.

The gate does not perform inference. A separate GitHub Actions job reserves a
one-use remote branch BEFORE attempting an optional, tiny model smoke test.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timedelta, timezone
import json
import os
from pathlib import Path
import sys

PRIMARY = "gpt-6.2-astra"
FALLBACK = "gpt-6-astra"


class WatchError(ValueError):
    pass


def _when(value):
    if not isinstance(value, str):
        return None
    try:
        date = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None
    return date.astimezone(timezone.utc) if date.tzinfo is not None else None


def _window_open(window):
    if not isinstance(window, dict):
        return False
    if window.get("limit_reached") is not False:
        return False
    if window.get("allowed") is False:
        return False
    percent = window.get("used_percent")
    if type(percent) not in (int, float) or not 0 <= percent < 100:
        return False
    return True


def evaluate(preflight: dict, quota: dict, *, now: datetime | None = None) -> dict:
    now = now or datetime.now(timezone.utc)
    if preflight.get("authenticated") is not True or quota.get("authenticated") is not True:
        raise WatchError("unauthenticated")
    model_ids = preflight.get("model_ids")
    if not isinstance(model_ids, list) or len(model_ids) > 200:
        raise WatchError("missing_sanitized_catalog")
    model_ids = sorted(set(value for value in model_ids if isinstance(value, str)))
    available = [name for name in (PRIMARY, FALLBACK) if name in model_ids]
    result = {
        "schema": "slimekeepers/model-watch/v1",
        "observed_at_utc": now.isoformat(timespec="seconds"),
        "catalog_count": preflight.get("model_count"),
        "model_ids": model_ids,
        "preferred_model": PRIMARY,
        "preferred_listed": PRIMARY in model_ids,
        "fallback_model": FALLBACK,
        "fallback_listed": FALLBACK in model_ids,
        "selected_model": preflight.get("selected_model"),
        "quota_readiness": "unavailable",
        "smoke_eligible": False,
        "account_count": len(quota.get("accounts") or []),
        "inference_requests": 0,
        "smoke_attempt_cap": 1,
        "smoke_is_not_game_development": True,
    }
    accounts = quota.get("accounts")
    if not available:
        result["quota_readiness"] = "no_supported_model"
        return result
    if not isinstance(accounts, list) or not accounts:
        result["quota_readiness"] = "no_account_data"
        return result
    if preflight.get("selected_model") not in available:
        result["quota_readiness"] = "selected_model_not_listed"
        return result
    for account in accounts:
        if not isinstance(account, dict):
            continue
        if account.get("status") != "active" or account.get("eligible_now") is not True:
            continue
        if account.get("oauth_expired") is not False:
            continue
        cooldown = _when(account.get("cooldown_until_utc"))
        if cooldown and cooldown > now:
            continue
        if account.get("live_query") != "success":
            continue
        live = account.get("live_quota")
        if not isinstance(live, dict) or live.get("available") is not True:
            continue
        fetched = _when(live.get("fetched_at_utc"))
        if fetched is None or now-fetched > timedelta(minutes=10) or fetched > now+timedelta(minutes=2):
            continue
        if not _window_open(live.get("primary")):
            continue
        secondary = live.get("secondary")
        if secondary is not None and not _window_open(secondary):
            continue
        result["quota_readiness"] = "reported_available"
        result["smoke_eligible"] = True
        return result
    result["quota_readiness"] = "rate_or_eligibility_blocked"
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preflight", type=Path, required=True)
    parser.add_argument("--quota", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        preflight = json.loads(args.preflight.read_text(encoding="utf-8"))
        quota = json.loads(args.quota.read_text(encoding="utf-8"))
        result = evaluate(preflight, quota)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(json.dumps(result, ensure_ascii=False))
        path = os.environ.get("GITHUB_ENV")
        if path:
            with open(path, "a", encoding="utf-8") as file:
                file.write("MODEL_SMOKE_ELIGIBLE=" + ("true" if result["smoke_eligible"] else "false") + "\n")
    except (OSError, ValueError, TypeError, KeyError, WatchError):
        print('{"status":"watch_blocked","inference_requests":0}')
        sys.exit(2)


if __name__ == "__main__":
    main()

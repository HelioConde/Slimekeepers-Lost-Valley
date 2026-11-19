"""One-shot, quota-gated smoke test for an alternative Codex proxy TEXT model.

A remote Git branch must be reserved before this module can POST. No retries.
The production development model priority is deliberately unchanged.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone, timedelta
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import urllib.error
import urllib.request

from proxy_preflight import NoRedirect, PreflightError, normalize_origin
from slimekeepers_codex_proxy import ensure_explicit_authorization, _extract_text, ProxyTextError

CANDIDATES = (
    "gpt-6.2-sol",
    "gpt-6.1-sol",
    "gpt-6-sol",
    "gpt-6-luna",
    "gpt-6.1-terra",
    "gpt-5.6-sol",
    "gpt-5.6-terra",
    "gpt-5.6-luna",
)
EXPECTED = "SLIMEKEEPERS_MODEL_OK"
INSTRUCTION = (
    "Você é um modelo submetido a um teste técnico autorizado. "
    "Não execute ferramentas, comandos ou ações. Responda SOMENTE "
    "com SLIMEKEEPERS_MODEL_OK, sem outras palavras."
)
QUESTION = "Confirme a capacidade de responder por texto."


class SmokeError(ValueError):
    pass


def branch_for(model: str) -> str:
    if model not in CANDIDATES:
        raise SmokeError("Modelo não autorizado para teste individual.")
    return "refs/heads/ai/model-smoke-" + model


def remote_reservations() -> set[str]:
    try:
        result = subprocess.run(
            ["git", "ls-remote", "--heads", "origin", "refs/heads/ai/model-smoke-*"],
            capture_output=True, text=True, check=True, timeout=30,
        )
    except (OSError, subprocess.SubprocessError):
        raise SmokeError("Não foi possível conferir reservas remotas.") from None
    return set(re.findall(r"refs/heads/ai/model-smoke-[a-zA-Z0-9._-]+", result.stdout))


def choose(preflight: dict, reserved: set[str]) -> str | None:
    if preflight.get("authenticated") is not True or preflight.get("inference_requests") != 0:
        raise SmokeError("Catálogo autenticado obrigatório.")
    listed = preflight.get("model_ids")
    if not isinstance(listed, list):
        raise SmokeError("Falta lista autenticada de modelos.")
    return next(
        (name for name in CANDIDATES
         if name in listed and branch_for(name) not in reserved),
        None,
    )


def authorized_for_probe(preflight: dict, watch: dict, model: str,
                         reserved: set[str], *, now: datetime | None = None) -> None:
    now = now or datetime.now(timezone.utc)
    if model not in CANDIDATES or not isinstance(preflight.get("model_ids"), list):
        raise SmokeError("Modelo fora do escopo.")
    if preflight.get("authenticated") is not True or preflight.get("inference_requests") != 0:
        raise SmokeError("Preflight não autenticado.")
    if model not in preflight["model_ids"] or branch_for(model) not in reserved:
        raise SmokeError("Modelo ausente ou sem reserva antes da inferência.")
    if watch.get("smoke_eligible") is not True or watch.get("quota_readiness") != "reported_available":
        raise SmokeError("Cota indisponível; nenhuma inferência permitida.")
    observed = watch.get("observed_at_utc")
    try:
        stamp = datetime.fromisoformat(observed.replace("Z", "+00:00"))
    except (ValueError, TypeError, AttributeError):
        raise SmokeError("Relatório de cota inválido.") from None
    if stamp.tzinfo is None or now - stamp.astimezone(timezone.utc) > timedelta(minutes=10):
        raise SmokeError("Cota desatualizada.")


def probe_text(base_url: str, api_key: str, model: str, *, opener=None) -> dict:
    """Return a sanitized result after exactly one POST; never switch models."""
    ensure_explicit_authorization()
    if model not in CANDIDATES:
        raise SmokeError("Modelo não autorizado.")
    if not isinstance(api_key, str) or len(api_key.strip()) < 20:
        raise SmokeError("Credencial do proxy ausente.")
    origin, kind = normalize_origin(base_url)
    if opener is None:
        handlers = [NoRedirect()]
        if kind == "local_loopback":
            handlers.insert(0, urllib.request.ProxyHandler({}))
        opener = urllib.request.build_opener(*handlers)
    body = json.dumps({
        "model": model, "instructions": INSTRUCTION,
        "input": QUESTION, "max_output_tokens": 96,
        "stream": False, "store": False,
    }, ensure_ascii=False).encode("utf-8")
    request = urllib.request.Request(
        origin + "/v1/responses", method="POST", data=body,
        headers={"Authorization": "Bearer " + api_key.strip(),
                 "Content-Type": "application/json", "Accept": "application/json"},
    )
    result = {"schema": "slimekeepers/alternative-model-smoke/v1", "model": model,
              "test": "minimal_text_response", "inference_requests": 1,
              "retries": 0, "verified": False, "status": "unknown"}
    try:
        with opener.open(request, timeout=60) as response:
            raw = response.read(300_001)
    except urllib.error.HTTPError as exc:
        result["status"] = "http_" + str(exc.code)
        return result
    except (urllib.error.URLError, TimeoutError, OSError):
        result["status"] = "network_or_timeout_unknown"
        return result
    if len(raw) > 300_000:
        result["status"] = "response_too_large"
        return result
    try:
        data = json.loads(raw)
    except (ValueError, UnicodeError):
        result["status"] = "invalid_json"
        return result
    if not isinstance(data, dict) or data.get("model") != model:
        result["status"] = "response_model_mismatch"
        return result
    if _extract_text(data).strip() != EXPECTED:
        result["status"] = "contract_not_verified"
        return result
    result["status"] = "working"
    result["verified"] = True
    usage = data.get("usage", {})
    if isinstance(usage, dict):
        result["usage"] = {
            key: usage.get(key) if type(usage.get(key)) is int
                                and 0 <= usage[key] <= 100000 else None
            for key in ("input_tokens", "output_tokens")
        }
    return result



def inspect_catalog(preflight: dict, base_url: str, api_key: str, *, opener=None) -> dict:
    """GET /v1/models/<id> for each nonimage alternative; no POST."""
    if preflight.get("authenticated") is not True or not isinstance(preflight.get("model_ids"), list):
        raise SmokeError("Preflight autenticado obrigatório.")
    if not isinstance(api_key, str) or len(api_key.strip()) < 20:
        raise SmokeError("Credencial do proxy ausente.")
    origin, kind = normalize_origin(base_url)
    if opener is None:
        handlers = [NoRedirect()]
        if kind == "local_loopback":
            handlers.insert(0, urllib.request.ProxyHandler({}))
        opener = urllib.request.build_opener(*handlers)
    found = set(preflight["model_ids"])
    results = []
    for model in CANDIDATES:
        item = {"model": model, "catalog_listed": model in found,
                "model_endpoint": "not_listed", "text_inference_verified": False}
        if model in found:
            request = urllib.request.Request(
                origin + "/v1/models/" + model, method="GET",
                headers={"Authorization": "Bearer " + api_key.strip(),
                         "Accept": "application/json"},
            )
            try:
                with opener.open(request, timeout=10) as response:
                    raw = response.read(100001)
            except urllib.error.HTTPError as err:
                item["model_endpoint"] = "http_" + str(err.code)
            except (urllib.error.URLError, TimeoutError, OSError):
                item["model_endpoint"] = "unreachable"
            else:
                try:
                    data = json.loads(raw) if len(raw) <= 100000 else None
                except (UnicodeError, ValueError):
                    data = None
                item["model_endpoint"] = ("resolved" if isinstance(data, dict)
                                          and data.get("id") == model else "invalid_response")
        results.append(item)
    return {"schema": "slimekeepers/other-model-catalog-check/v1",
            "status": "get_only", "models": results,
            "http_get_requests": sum(item["catalog_listed"] for item in results),
            "inference_requests": 0, "image_requests": 0}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--operation", choices=["select", "inspect", "run"], required=True)
    parser.add_argument("--preflight", type=Path, required=True)
    parser.add_argument("--watch", type=Path)
    parser.add_argument("--model", choices=CANDIDATES)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    try:
        preflight = json.loads(args.preflight.read_text(encoding="utf-8"))
        if args.operation == "inspect":
            if args.output is None:
                raise SmokeError("Arquivo de saída obrigatório.")
            result = inspect_catalog(preflight, os.getenv("CODEX_PROXY_BASE_URL", ""),
                                     os.getenv("CODEX_PROXY_API_KEY", ""))
            args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n",
                                   encoding="utf-8")
            print(json.dumps(result, ensure_ascii=False))
            return
        if args.operation == "select":
            next_model = choose(preflight, remote_reservations())
            if next_model is None:
                print('{"status":"no_more_models_to_test","inference_requests":0}')
                return
            if not os.environ.get("GITHUB_ENV"):
                raise SmokeError("GITHUB_ENV obrigatório para selecionar modelo.")
            with open(os.environ["GITHUB_ENV"], "a", encoding="utf-8") as file:
                file.write("ALTERNATIVE_SMOKE_MODEL=" + next_model + "\n")
            print(json.dumps({"status": "selected", "model": next_model,
                              "inference_requests": 0}))
            return
        if not args.model or args.watch is None or args.output is None:
            raise SmokeError("Falta o contexto da tentativa.")
        watch = json.loads(args.watch.read_text(encoding="utf-8"))
        authorized_for_probe(preflight, watch, args.model, remote_reservations())
        result = probe_text(os.getenv("CODEX_PROXY_BASE_URL", ""),
                            os.getenv("CODEX_PROXY_API_KEY", ""), args.model)
        args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n",
                               encoding="utf-8")
        print(json.dumps(result, ensure_ascii=False))
        if not result["verified"]:
            sys.exit(1)
    except (SmokeError, ProxyTextError, PreflightError, ValueError, TypeError,
            OSError, KeyError):
        print('{"status":"blocked_before_post_or_environment_error","inference_requests":"unknown"}')
        sys.exit(2)


if __name__ == "__main__":
    main()

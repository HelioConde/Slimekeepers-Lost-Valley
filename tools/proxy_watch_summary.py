"""Sanitized model-check summary for a GitHub Actions run (no network, no secrets)."""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import re

MODELS = ("gpt-6.2-astra", "gpt-6-astra", "gpt-6.2-sol", "gpt-6.1-sol",
          "gpt-6-sol", "gpt-6-luna", "gpt-6.1-terra", "gpt-5.6-sol",
          "gpt-5.6-terra", "gpt-5.6-luna")
VALID = re.compile(r"[a-zA-Z0-9][a-zA-Z0-9._-]{0,99}\Z")
STATES = {"working", "verified", "http_400", "http_401", "http_403",
          "http_404", "http_429", "http_500", "http_502", "http_503",
          "invalid_json", "contract_not_verified", "response_model_mismatch",
          "network_or_timeout_unknown", "response_too_large"}


def load(path):
    if not path or not path.is_file() or path.stat().st_size > 100_000:
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (ValueError, OSError, UnicodeError):
        return {}
    return data if isinstance(data, dict) else {}


def percent(value):
    return str(value) + "%" if type(value) in (int, float) and 0 <= value <= 100 else "indisponivel"


def reset(value):
    try:
        date = datetime.fromisoformat(value.replace("Z", "+00:00"))
        return date.astimezone(timezone.utc).strftime("%d/%m/%Y %H:%M UTC") if date.tzinfo else "indisponivel"
    except (ValueError, AttributeError, TypeError):
        return "indisponivel"


def render(preflight, quota, watch, catalog, main_smoke, alt_smoke):
    raw_list = preflight.get("model_ids")
    listed = set(x for x in raw_list if type(x) is str and VALID.fullmatch(x)) if isinstance(raw_list, list) else set()
    accounts = quota.get("accounts")
    account = accounts[0] if isinstance(accounts, list) and accounts and isinstance(accounts[0], dict) else {}
    live = account.get("live_quota", {})
    live = live if isinstance(live, dict) else {}
    p = live.get("primary") if isinstance(live.get("primary"), dict) else {}
    s = live.get("secondary") if isinstance(live.get("secondary"), dict) else {}
    by_endpoint = {}
    for entry in catalog.get("models", []) if isinstance(catalog.get("models"), list) else []:
        if isinstance(entry, dict) and entry.get("model") in MODELS:
            by_endpoint[entry["model"]] = entry.get("model_endpoint") == "resolved"
    attempted = {}
    for source in (main_smoke, alt_smoke):
        model, state = source.get("model"), source.get("status")
        if model in MODELS and state in STATES:
            attempted[model] = state
    lines = [
        "## Slimekeepers - verificacao do Codex Proxy",
        "",
        "Modelos listados nao significam geracao de texto funcional.",
        "",
        "- Modelos listados: " + str(len(listed)),
        "- Cota principal usada: " + percent(p.get("used_percent")),
        "- Cota secundaria usada: " + percent(s.get("used_percent")),
        "- Reset principal: " + reset(p.get("reset_at_utc")),
        "- Reset secundario: " + reset(s.get("reset_at_utc")),
        "- Smoke permitido por cota: " + ("sim" if watch.get("smoke_eligible") is True else "nao"),
        "",
        "| Modelo | Catalogo | GET individual | Geracao de texto |",
        "|---|---|---|---|",
    ]
    for model in MODELS:
        catalog_status = "sim" if model in listed else "nao"
        endpoint_status = "confirmado" if by_endpoint.get(model) else "nao testado"
        text_status = attempted.get(model, "ainda nao testado")
        lines.append("| " + model + " | " + catalog_status + " | " + endpoint_status + " | " + text_status + " |")
    lines += ["", "Somente status saneado; sem tokens, IDs pessoais ou resposta bruta.", ""]
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser()
    for arg in ("preflight", "quota", "watch", "catalog", "main-smoke", "alt-smoke"):
        parser.add_argument("--" + arg, type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    summary = render(load(args.preflight), load(args.quota), load(args.watch),
                     load(args.catalog), load(args.main_smoke), load(args.alt_smoke))
    args.output.write_text(summary, encoding="utf-8")
    print("Resumo tecnico saneado gerado.")


if __name__ == "__main__":
    main()

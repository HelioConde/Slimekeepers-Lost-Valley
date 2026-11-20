#!/usr/bin/env python3
"""Summarize numeric usage from Claude Code result JSON/JSONL; never print prompts."""
from __future__ import annotations
import argparse
import json
import math
from pathlib import Path
from typing import Any

KEYS = ("input_tokens", "output_tokens", "cache_read_input_tokens", "cache_creation_input_tokens")
MAX_BYTES = 10 * 1024 * 1024

def number(value: Any) -> float:
    return float(value) if isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value) and value >= 0 else 0.0

def summarize(path: Path) -> dict[str, float]:
    if not path.is_file() or path.stat().st_size > MAX_BYTES:
        raise ValueError("Arquivo ausente ou maior que 10 MiB")
    raw = path.read_text(encoding="utf-8")
    try:
        data = json.loads(raw)
        rows = data if isinstance(data, list) else [data]
    except json.JSONDecodeError:
        rows = [json.loads(s) for s in raw.splitlines() if s.strip()]
    results = [r for r in rows if isinstance(r, dict) and r.get("type") == "result"]
    if not results:
        raise ValueError("Nenhum evento type=result; consumo não comprovado")
    total = {k: 0.0 for k in KEYS}
    total["total_cost_usd"] = 0.0
    for r in results:
        u = r.get("usage")
        if not isinstance(u, dict):
            models = r.get("modelUsage")
            u = {k: sum(number(row.get(k)) for row in models.values() if isinstance(row, dict)) for k in KEYS} if isinstance(models, dict) else {}
        for k in KEYS:
            total[k] += number(u.get(k))
        total["total_cost_usd"] += number(r.get("total_cost_usd"))
    return total

def compare(a: dict[str, float], b: dict[str, float]) -> dict[str, float | None]:
    a_tokens = sum(a[k] for k in KEYS)
    b_tokens = sum(b[k] for k in KEYS)
    return {
        "before_tokens": int(a_tokens), "after_tokens": int(b_tokens),
        "token_change_percent": round((b_tokens - a_tokens) * 100 / a_tokens, 2) if a_tokens else None,
        "cost_change_percent": round((b["total_cost_usd"] - a["total_cost_usd"]) * 100 / a["total_cost_usd"], 2) if a["total_cost_usd"] else None,
    }

def main() -> None:
    p = argparse.ArgumentParser(description="Mede o consumo Claude Code (JSON de resultado, apenas campos numéricos)")
    p.add_argument("file", nargs="?", type=Path)
    p.add_argument("--before", type=Path)
    p.add_argument("--after", type=Path)
    args = p.parse_args()
    if args.before is not None or args.after is not None:
        if not args.before or not args.after or args.file:
            p.error("Informe --before A.json --after B.json")
        a, b = summarize(args.before), summarize(args.after)
        result = {"before": a, "after": b, "comparison": compare(a, b)}
    elif args.file is not None:
        result = summarize(args.file)
    else:
        p.error("Informe um JSON ou --before/--after")
    print(json.dumps(result, indent=2, ensure_ascii=False))

if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        raise SystemExit(f"Consumo não medido: {exc}") from None

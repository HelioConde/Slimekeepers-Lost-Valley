#!/usr/bin/env python3
"""Simple, offline Claude status line. JSON input only; no disk or network access."""
import json
import math
import re
import sys

def render(info: dict) -> str:
    model = info.get("model") or {}
    label = str(model.get("display_name") or "Claude") if isinstance(model, dict) else "Claude"
    label = re.sub(r"[^\w .+-]", "", label)[:32] or "Claude"
    context = info.get("context_window") or {}
    pct = context.get("used_percentage") if isinstance(context, dict) else None
    percent = f"{min(100, max(0, float(pct))):.0f}%" if isinstance(pct, (int, float)) and not isinstance(pct, bool) and math.isfinite(pct) else "—"
    cost = info.get("cost") or {}
    usd = cost.get("total_cost_usd") if isinstance(cost, dict) else None
    cost_label = f"USD {usd:.3f}" if isinstance(usd, (int, float)) and not isinstance(usd, bool) and math.isfinite(usd) and usd >= 0 else "—"
    return f"{label} | Contexto {percent} | Sessão {cost_label}"

if __name__ == "__main__":
    raw = sys.stdin.read(128 * 1024 + 1)
    if len(raw) <= 128 * 1024:
        try:
            value = json.loads(raw)
            if isinstance(value, dict):
                print(render(value))
        except (ValueError, TypeError, json.JSONDecodeError):
            pass

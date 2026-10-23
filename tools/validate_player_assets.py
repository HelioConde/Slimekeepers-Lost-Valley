"""Checa sprites que a cena Godot 4 precisa, sem bibliotecas externas.

Uso: python tools/validate_player_assets.py (na raiz do repositório)
"""
from __future__ import annotations

from pathlib import Path
import sys

PROJECT = Path(__file__).resolve().parents[1]
BASE = PROJECT / "sprites" / "Idle"
ANIMATIONS = BASE / "animations"
DIRECTIONS = ("south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west")
IDLE = "The_adventurer_maintains_a_relaxed_idle_stance_whi"
WALK_SOUTH = ("south-f96d7729", "south-2b9cc8e0")
EXPECTED = {"idle": 9, "walk": 6, "run": 8}


def chosen_folder(state: str, direction: str) -> Path:
    clip = {"idle": IDLE, "walk": "Walk", "run": "Running"}[state]
    folder = ANIMATIONS / clip / direction
    if state == "walk" and direction == "south":
        for variant in WALK_SOUTH:
            option = ANIMATIONS / clip / variant
            if option.is_dir():
                return option
    return folder


def main() -> int:
    print(f"Projeto: {PROJECT}")
    if not BASE.is_dir():
        print("ERRO: sprites/Idle ausente. Extraia este pacote na raiz do repositório existente.")
        return 2
    errors = 0
    count = 0
    for state in ("idle", "walk", "run"):
        for direction in DIRECTIONS:
            folder = chosen_folder(state, direction)
            frames = sorted(folder.glob("frame_*.png")) if folder.is_dir() else []
            count += len(frames)
            expected = EXPECTED[state]
            if len(frames) != expected:
                print(f"FALTA: {state}_{direction}: {len(frames)} quadros (esperado {expected}) em {folder.relative_to(PROJECT)}")
                errors += 1
            else:
                print(f"OK: {state}_{direction}: {len(frames)} quadros")
            for index, path in enumerate(frames):
                if path.name != f"frame_{index:03}.png":
                    print(f"AVISO: sequência irregular: {path.relative_to(PROJECT)}")
                    errors += 1
    print(f"\nResultado: {count} PNGs, {errors} conjuntos/quadros com problemas. (Esperado 184.)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())

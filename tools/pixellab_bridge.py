"""Ligação read-only PixelLab para Slimekeepers. Não há POSTs pagos.

Portado da integração do video-forge-ia2. Não expõe IDs ou prompts em logs.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
from uuid import UUID

from pixellab_client import PixelLabClient, PixelLabError


def inventory(client: PixelLabClient) -> dict:
    response = client.characters()
    characters = response.get("characters")
    total = response.get("total")
    if not isinstance(characters, list) or not isinstance(total, int):
        raise PixelLabError("Inventário PixelLab incompleto ou inválido.")
    if len(characters) != total:
        raise PixelLabError("Inventário paginado: não declarar a biblioteca completa.")
    return {
        "status": "connected",
        "characters": total,
        "hint": "Somente leitura. Nenhuma imagem ou animação foi gerada.",
    }


def export_existing(client: PixelLabClient, character_id: str, output: Path) -> dict:
    try:
        safe_id = str(UUID(character_id))
    except (TypeError, ValueError):
        raise PixelLabError("PIXELLAB_CHARACTER_ID deve ser um UUID válido.") from None
    client.character(safe_id)
    output.mkdir(parents=True, exist_ok=True)
    # Não imprimir ID nem URL. Exportações não entram no commit.
    for filename, sheet in (("character-frames.zip", False), ("spritesheet.zip", True)):
        payload = client.download(safe_id, spritesheet=sheet)
        (output / filename).write_bytes(payload)
    return {"status": "exported", "files": ["character-frames.zip", "spritesheet.zip"]}


def main() -> None:
    parser = argparse.ArgumentParser(description="PixelLab para Slimekeepers (somente GET)")
    parser.add_argument("--operation", choices=("plan", "inventory", "export"), default="plan")
    parser.add_argument("--public-artifacts-confirmed", action="store_true")
    args = parser.parse_args()
    if args.operation == "plan":
        print(json.dumps({"status": "ready", "paid_requests": 0, "operation": "plan"}))
        return
    token = os.getenv("PIXELLAB_API_TOKEN", "").strip()
    if not token:
        parser.exit(2, "PIXELLAB_STATUS=TOKEN_NOT_CONFIGURED\n")
    client = PixelLabClient(token)
    try:
        if args.operation == "inventory":
            result = inventory(client)
        else:
            if not args.public_artifacts_confirmed:
                parser.exit(2, "Confirme explicitamente exposição dos ZIPs no repositório público.\n")
            result = export_existing(client, os.getenv("PIXELLAB_CHARACTER_ID", ""),
                                     Path("output/pixellab"))
        print(json.dumps(result, ensure_ascii=False))
    except (PixelLabError, ValueError, KeyError, TypeError, OSError):
        parser.exit(1, "PIXELLAB_STATUS=FAILED; consulte a configuração e a conta sem compartilhar credenciais.\n")


if __name__ == "__main__":
    main()

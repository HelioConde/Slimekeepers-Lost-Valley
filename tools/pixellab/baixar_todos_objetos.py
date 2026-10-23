#!/usr/bin/env python3
"""Baixa todos os objetos existentes na biblioteca PixelLab v2.

Somente leitura/exportação: não solicita novas gerações, nem altera objetos.
Python 3.10+; sem dependências adicionais.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import io
import json
import os
from pathlib import Path
import re
import shutil
import sys
import time
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen
import zipfile

BASE = "https://api.pixellab.ai/v2"
PAGE_SIZE = 100
RETRIES = 5


def get(url: str, token: str, timeout: int = 90):
    """GET autenticado com tentativas limitadas para 429/5xx."""
    last = None
    for attempt in range(RETRIES):
        req = Request(url, headers={
            "Authorization": f"Bearer {token}",
            "User-Agent": "SlimekeepersPixelLabExporter/1.0",
            "Accept": "application/json, application/zip, application/octet-stream",
        })
        try:
            return urlopen(req, timeout=timeout)
        except HTTPError as exc:
            last = exc
            if exc.code not in (429, 500, 502, 503, 504) or attempt == RETRIES - 1:
                raise RuntimeError(f"HTTP {exc.code} ao acessar {url.split('?')[0]}") from exc
            retry_after = exc.headers.get("Retry-After")
            try:
                seconds = min(60, max(1, int(retry_after))) if retry_after else min(30, 2 ** attempt)
            except ValueError:
                seconds = min(30, 2 ** attempt)
            time.sleep(seconds)
        except (URLError, TimeoutError) as exc:
            last = exc
            if attempt == RETRIES - 1:
                raise RuntimeError(f"Falha de rede: {exc}") from exc
            time.sleep(min(30, 2 ** attempt))
    raise RuntimeError(f"Tentativas esgotadas: {last}")


def list_all_objects(token: str) -> list[dict]:
    results = []
    seen = set()
    offset = 0
    while True:
        query = urlencode({"limit": PAGE_SIZE, "offset": offset})
        with get(f"{BASE}/objects?{query}", token) as response:
            payload = json.load(response)
        batch = payload.get("objects", [])
        if not isinstance(batch, list):
            raise RuntimeError("Resposta inesperada: objects não é uma lista")
        for item in batch:
            obj_id = item.get("id")
            if obj_id and obj_id not in seen:
                seen.add(obj_id)
                results.append(item)
        total = payload.get("total")
        offset += len(batch)
        print(f"Consultados {offset}/{total if isinstance(total, int) else '?'} objetos...", flush=True)
        if not batch or (isinstance(total, int) and offset >= total):
            break
        if len(batch) < PAGE_SIZE and not isinstance(total, int):
            break
    return results


def short_name(obj: dict) -> str:
    name = str(obj.get("name") or "").strip()
    prompt = str(obj.get("prompt") or "").strip()
    if name.lower() in ("base", "object", "object 0", ""):
        match = re.match(r"^([a-z][a-z0-9_]{2,64})\s*(?:[—–:-])", prompt, flags=re.I)
        if match:
            name = match.group(1)
    if not name:
        name = "objeto"
    label = re.sub(r"[^a-z0-9_-]+", "_", name.lower()).strip("_-")[:48]
    return label or "objeto"


def object_dir(out_dir: Path, obj: dict) -> Path:
    uid = str(obj["id"])
    if not re.fullmatch(r"[a-zA-Z0-9-]{16,64}", uid):
        raise ValueError("ID inválido retornado pela API")
    return out_dir / f"{short_name(obj)}_{uid[:8]}"


def valid_zip(path: Path) -> bool:
    try:
        with zipfile.ZipFile(path) as archive:
            names = [Path(n).suffix.lower() for n in archive.namelist() if not n.endswith("/")]
            return archive.testzip() is None and ".png" in names and ".json" in names
    except (OSError, zipfile.BadZipFile):
        return False


def safe_extract(zip_path: Path, folder: Path) -> list[str]:
    result = []
    with zipfile.ZipFile(zip_path) as archive:
        for info in archive.infolist():
            if info.is_dir():
                continue
            # A exportação deve conter apenas o spritesheet PNG e um layout JSON.
            # Nunca usamos caminhos do ZIP diretamente: evita path traversal.
            filename = Path(info.filename).name
            if not filename or Path(filename).suffix.lower() not in (".png", ".json"):
                continue
            target = folder / filename
            partial = folder / (filename + ".partial")
            with archive.open(info) as src, partial.open("wb") as dst:
                shutil.copyfileobj(src, dst)
            partial.replace(target)
            result.append(filename)
    return result


def download_one(obj: dict, token: str, out_dir: Path) -> dict:
    uid = str(obj["id"])
    folder = object_dir(out_dir, obj)
    folder.mkdir(parents=True, exist_ok=True)
    archive = folder / "spritesheet.zip"
    try:
        was_cached = valid_zip(archive)
        if not was_cached:
            tmp = folder / "spritesheet.zip.partial"
            try:
                with get(f"{BASE}/objects/{uid}/spritesheet", token, timeout=180) as response:
                    with tmp.open("wb") as dest:
                        shutil.copyfileobj(response, dest, length=1024 * 1024)
                if not valid_zip(tmp):
                    raise RuntimeError("A API não retornou um ZIP válido com PNG e JSON")
                tmp.replace(archive)
            finally:
                tmp.unlink(missing_ok=True)
        extracted = safe_extract(archive, folder)
        return {"id": uid, "name": obj.get("name"), "folder": str(folder),
                "status": "ja_existia" if was_cached else "baixado", "files": extracted}
    except Exception as exc:
        return {"id": uid, "name": obj.get("name"), "folder": str(folder),
                "status": "erro", "error": str(exc)}


def save_json_atomic(path: Path, payload: dict) -> None:
    tmp = path.with_suffix(".json.partial")
    tmp.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    tmp.replace(path)


def main() -> int:
    parser = argparse.ArgumentParser(description="Exporta todos os objetos PixelLab sem limite de 25 por download")
    parser.add_argument("--output", type=Path, default=Path("sprites/objects/pixellab_exports"),
                        help="Pasta de destino (padrão: sprites/objects/pixellab_exports)")
    parser.add_argument("--contains", default="", help="Filtra por nome, prompt ou tags (opcional)")
    parser.add_argument("--max-items", type=int, default=0, help="Baixa no máximo N objetos; 0 = todos")
    parser.add_argument("--workers", type=int, default=3, help="Downloads simultâneos (1 a 4)")
    parser.add_argument("--dry-run", action="store_true", help="Apenas lista objetos, sem baixar")
    args = parser.parse_args()

    token = os.environ.get("PIXELLAB_API_TOKEN", "").strip()
    if not token:
        print("ERRO: configure PIXELLAB_API_TOKEN no PowerShell antes de executar.", file=sys.stderr)
        return 2
    workers = max(1, min(4, args.workers))
    obj_list = list_all_objects(token)
    if args.contains.strip():
        term = args.contains.casefold().strip()
        obj_list = [o for o in obj_list if term in
                    " ".join([str(o.get("name", "")), str(o.get("prompt", "")),
                              " ".join(str(t) for t in o.get("tags", []))]).casefold()]
    if args.max_items > 0:
        obj_list = obj_list[:args.max_items]
    active = [o for o in obj_list if str(o.get("status", "")).lower() not in
              ("pending", "processing", "queued", "failed", "cancelled", "generating")]
    print(f"Encontrados: {len(obj_list)} | Disponíveis para exportação: {len(active)} | Pendentes: {len(obj_list)-len(active)}")
    if args.dry_run:
        for o in obj_list:
            print(f"{o.get('id')} | {str(o.get('status', '?')):<12} | {short_name(o)}")
        return 0

    args.output.mkdir(parents=True, exist_ok=True)
    manifest = {"project": "Slimekeepers: Lost Valley", "source": "PixelLab API v2",
                "listed": len(obj_list), "exportable": len(active), "results": []}
    manifest_file = args.output / "manifest.json"
    save_json_atomic(manifest_file, manifest)
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as pool:
        futures = {pool.submit(download_one, obj, token, args.output): obj for obj in active}
        for future in concurrent.futures.as_completed(futures):
            entry = future.result()
            manifest["results"].append(entry)
            save_json_atomic(manifest_file, manifest)
            print(f"[{entry['status'].upper():>10}] {object_dir(args.output, futures[future]).name}" +
                  (f" — {entry['error']}" if entry['status'] == "erro" else ""), flush=True)
    statuses = [r["status"] for r in manifest["results"]]
    print(f"\nConcluído: {statuses.count('baixado')} novos, {statuses.count('ja_existia')} existentes, "
          f"{statuses.count('erro')} erros.")
    print(f"Destino: {args.output.resolve()}\nManifesto: {manifest_file.resolve()}")
    return 1 if "erro" in statuses else 0


if __name__ == "__main__":
    sys.exit(main())

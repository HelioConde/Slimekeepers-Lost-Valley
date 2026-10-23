import os
import time
import json
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

import requests

# ============================================================
# CONFIGURAÇÃO
# ============================================================

API_BASE = "https://api.pixellab.ai/v2"
API_TOKEN = os.getenv("PIXELLAB_API_TOKEN", "").strip()

# Opcional:
# - Se você já souber o ID do personagem, defina PIXELLAB_CHARACTER_ID.
# - Se não definir, o script tenta pegar o personagem mais recente da sua conta.
CHARACTER_ID = os.getenv("PIXELLAB_CHARACTER_ID", "").strip() or None

# Opcional: se quiser procurar por nome antes de cair no "mais recente"
CHARACTER_NAME_FILTER = os.getenv("PIXELLAB_CHARACTER_NAME", "").strip() or None

# Pasta local para salvar resumo / zip final
OUTPUT_DIR = Path(os.getenv("PIXELLAB_OUTPUT_DIR", "pixellab_output"))
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Quantas requisições de animação vamos disparar ao mesmo tempo.
# Cada animação já gera vários jobs internos (um por direção),
# então não exagere para não bater limite de concorrência da API.
MAX_SUBMIT_WORKERS = int(os.getenv("PIXELLAB_MAX_SUBMIT_WORKERS", "3"))

# Polling dos jobs
POLL_INTERVAL_SECONDS = int(os.getenv("PIXELLAB_POLL_INTERVAL", "6"))
JOB_TIMEOUT_SECONDS = int(os.getenv("PIXELLAB_JOB_TIMEOUT", "1800"))  # 30 min

# Direções: use 8 ou reduza se quiser economizar
ALL_DIRECTIONS = [
    "south",
    "south-east",
    "east",
    "north-east",
    "north",
    "north-west",
    "west",
    "south-west",
]

# ============================================================
# ANIMAÇÕES QUE VOCÊ QUER GERAR
# ============================================================
# Você pode editar à vontade os nomes e descrições abaixo.
# "animation_name" = nome interno na biblioteca
# "action_description" = prompt da ação
# frame_count: recomendado 8 para ações desse tipo
# ============================================================

ANIMATIONS_TO_GENERATE = [
    {
        "animation_name": "pull_axe",
        "action_description": (
            "The character reaches back and smoothly pulls out a woodcutting axe, "
            "ending in a ready stance, keeping the same outfit, face, hair, proportions, "
            "and pixel-art style. The motion should be clean, readable, and game-ready."
        ),
        "frame_count": 8,
        "directions": ALL_DIRECTIONS,
    },
    {
        "animation_name": "pull_shovel",
        "action_description": (
            "The character reaches back and pulls out a shovel, ending in a ready stance "
            "for digging, while preserving the same outfit, silhouette, colors, hair, "
            "and pixel-art style."
        ),
        "frame_count": 8,
        "directions": ALL_DIRECTIONS,
    },
    {
        "animation_name": "pull_hoe",
        "action_description": (
            "The character reaches back and pulls out a farming hoe, ending in a ready "
            "stance, preserving the same outfit, body proportions, and pixel-art style."
        ),
        "frame_count": 8,
        "directions": ALL_DIRECTIONS,
    },
    {
        "animation_name": "pull_pickaxe",
        "action_description": (
            "The character reaches back and pulls out a pickaxe, ending holding it ready "
            "for mining, preserving the same outfit, hair, facial features, and pixel-art style."
        ),
        "frame_count": 8,
        "directions": ALL_DIRECTIONS,
    },
    {
        "animation_name": "pull_watering_can",
        "action_description": (
            "The character reaches to their bag and pulls out a small watering can, "
            "ending in a ready stance to water crops, preserving the same outfit and style."
        ),
        "frame_count": 8,
        "directions": ALL_DIRECTIONS,
    },
    {
        "animation_name": "pull_scythe",
        "action_description": (
            "The character reaches back and pulls out a scythe, ending in a ready harvesting stance, "
            "preserving the same outfit, colors, proportions, and pixel-art style."
        ),
        "frame_count": 8,
        "directions": ALL_DIRECTIONS,
    },
]

# ============================================================
# FUNÇÕES UTILITÁRIAS
# ============================================================

def require_token():
    if not API_TOKEN:
        raise RuntimeError(
            "Defina a variável de ambiente PIXELLAB_API_TOKEN com seu token da PixelLab API."
        )

def headers(json_mode=True):
    h = {"Authorization": f"Bearer {API_TOKEN}"}
    if json_mode:
        h["Content-Type"] = "application/json"
    return h

def api_request(method, path, *, json_body=None, stream=False, timeout=120):
    url = f"{API_BASE}{path}"
    response = requests.request(
        method=method.upper(),
        url=url,
        headers=headers(json_mode=not stream),
        json=json_body,
        stream=stream,
        timeout=timeout,
    )

    if response.status_code >= 400:
        try:
            details = response.json()
        except Exception:
            details = response.text
        raise RuntimeError(
            f"Erro na API {method.upper()} {path} "
            f"[HTTP {response.status_code}]: {details}"
        )

    if stream:
        return response

    if not response.text.strip():
        return {}

    return response.json()

def normalize_character_list(data):
    """
    A API pode retornar lista direta ou estrutura com chave 'characters'/'items'/'results'.
    """
    if isinstance(data, list):
        return data
    if isinstance(data, dict):
        for key in ("characters", "items", "results", "data"):
            value = data.get(key)
            if isinstance(value, list):
                return value
    return []

def parse_datetime_like(item):
    # tentativa leve de ordenação por data
    for key in ("updated_at", "created_at", "modified_at"):
        value = item.get(key)
        if isinstance(value, str):
            return value
    return ""

def list_characters():
    data = api_request("GET", "/characters")
    chars = normalize_character_list(data)
    # ordena decrescente por data, se vier
    chars = sorted(chars, key=parse_datetime_like, reverse=True)
    return chars

def pick_character_id():
    if CHARACTER_ID:
        print(f"[INFO] Usando CHARACTER_ID definido no ambiente: {CHARACTER_ID}")
        return CHARACTER_ID

    chars = list_characters()
    if not chars:
        raise RuntimeError(
            "Nenhum personagem encontrado na sua conta PixelLab. "
            "Defina PIXELLAB_CHARACTER_ID manualmente."
        )

    chosen = None

    if CHARACTER_NAME_FILTER:
        for c in chars:
            name = (c.get("name") or c.get("character_name") or "").strip().lower()
            if CHARACTER_NAME_FILTER.lower() in name:
                chosen = c
                break

    if chosen is None:
        chosen = chars[0]

    cid = chosen.get("id") or chosen.get("character_id")
    if not cid:
        raise RuntimeError(
            "Não foi possível extrair o character_id do retorno de /characters."
        )

    print(
        "[INFO] Personagem selecionado automaticamente:",
        json.dumps(
            {
                "id": cid,
                "name": chosen.get("name") or chosen.get("character_name"),
                "state_name": chosen.get("state_name"),
                "status": chosen.get("status"),
            },
            ensure_ascii=False,
        ),
    )
    return cid

def enqueue_animation(character_id, animation_cfg):
    payload = {
        "character_id": character_id,
        "mode": "v3",
        "animation_name": animation_cfg["animation_name"],
        "action_description": animation_cfg["action_description"],
        "directions": animation_cfg.get("directions", ALL_DIRECTIONS),
        "frame_count": animation_cfg.get("frame_count", 8),
        "keep_first_frame": True,
        # Pode ligar se quiser que a API expanda/refine o prompt:
        # "enhance_prompt": True,
    }

    print(f"[QUEUE] Enfileirando '{payload['animation_name']}'...")
    data = api_request("POST", "/characters/animations", json_body=payload)

    result = {
        "animation_name": payload["animation_name"],
        "payload": payload,
        "response": data,
        "animation_group_id": data.get("animation_group_id"),
        "background_job_ids": data.get("background_job_ids", []),
        "directions": data.get("directions", payload["directions"]),
        "status": data.get("status"),
    }

    print(
        f"[QUEUE] '{payload['animation_name']}' enviada. "
        f"jobs={len(result['background_job_ids'])} "
        f"group={result['animation_group_id']}"
    )
    return result

def poll_job(job_id):
    started = time.time()

    while True:
        data = api_request("GET", f"/background-jobs/{job_id}")
        status = (data.get("status") or "").lower()

        if status in {"completed", "failed", "cancelled"}:
            return data

        elapsed = time.time() - started
        if elapsed > JOB_TIMEOUT_SECONDS:
            raise TimeoutError(f"Timeout no job {job_id}")

        time.sleep(POLL_INTERVAL_SECONDS)

def wait_for_animation_jobs(queue_result):
    final_jobs = []

    for job_id in queue_result["background_job_ids"]:
        print(f"[POLL] {queue_result['animation_name']} -> {job_id}")
        job_data = poll_job(job_id)
        final_jobs.append(job_data)
        print(
            f"[DONE] {queue_result['animation_name']} -> {job_id} "
            f"status={job_data.get('status')}"
        )

    queue_result["job_results"] = final_jobs
    return queue_result

def download_character_zip(character_id, out_file):
    print(f"[ZIP] Baixando ZIP final do personagem em: {out_file}")
    response = api_request(
        "GET",
        f"/characters/{character_id}/zip",
        stream=True,
        timeout=300,
    )
    with open(out_file, "wb") as f:
        for chunk in response.iter_content(chunk_size=8192):
            if chunk:
                f.write(chunk)
    print("[ZIP] Download concluído.")

def save_summary(path, payload):
    path.write_text(
        json.dumps(payload, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    print(f"[SAVE] Resumo salvo em: {path}")

# ============================================================
# EXECUÇÃO
# ============================================================

def main():
    require_token()
    character_id = pick_character_id()

    print(f"[INFO] Gerando {len(ANIMATIONS_TO_GENERATE)} animações para {character_id}")
    print(f"[INFO] Concorrência de envio: {MAX_SUBMIT_WORKERS}")

    queued_results = []
    errors = []

    # 1) Enfileira várias animações em paralelo (aproveitando a queue)
    with ThreadPoolExecutor(max_workers=MAX_SUBMIT_WORKERS) as executor:
        future_map = {
            executor.submit(enqueue_animation, character_id, anim_cfg): anim_cfg
            for anim_cfg in ANIMATIONS_TO_GENERATE
        }

        for future in as_completed(future_map):
            anim_cfg = future_map[future]
            try:
                queued_results.append(future.result())
            except Exception as e:
                errors.append(
                    {
                        "animation_name": anim_cfg.get("animation_name"),
                        "stage": "enqueue",
                        "error": str(e),
                    }
                )

    # Salva queue inicial
    save_summary(OUTPUT_DIR / "queue_results.json", queued_results)

    # 2) Faz polling de todos os jobs
    finished_results = []
    for queued in queued_results:
        try:
            finished = wait_for_animation_jobs(queued)
            finished_results.append(finished)
        except Exception as e:
            errors.append(
                {
                    "animation_name": queued.get("animation_name"),
                    "stage": "poll",
                    "error": str(e),
                }
            )

    # 3) Salva resumo final
    save_summary(OUTPUT_DIR / "finished_results.json", finished_results)

    if errors:
        save_summary(OUTPUT_DIR / "errors.json", errors)
        print("[WARN] Algumas animações tiveram erro. Veja errors.json")
    else:
        print("[OK] Todas as animações concluíram sem erro.")

    # 4) Opcional: baixar ZIP final do personagem com tudo
    download_zip = os.getenv("PIXELLAB_DOWNLOAD_ZIP", "1").strip() == "1"
    if download_zip:
        zip_path = OUTPUT_DIR / f"{character_id}.zip"
        try:
            download_character_zip(character_id, zip_path)
        except Exception as e:
            print(f"[WARN] Não foi possível baixar o ZIP final: {e}")

    print("[FIM] Processo concluído.")

if __name__ == "__main__":
    main()
"""Cliente de texto para Slimekeepers sobre o Codex Proxy do VideoForge-IA.

Não é a API pública oficial da OpenAI. Somente POST /v1/responses, sem retries.
O caller deve executar GET /health e /v1/models antes da primeira inferência.
Nunca registra prompt, token, corpo bruto, IDs de conta ou resposta do modelo.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import urllib.error
import urllib.request

from proxy_preflight import NoRedirect, PreflightError, normalize_origin

PREFERRED_MODEL = "gpt-6.2-astra"
FALLBACK_MODEL = "gpt-6-astra"
ALLOWED_MODELS = {PREFERRED_MODEL, FALLBACK_MODEL}
PING_INSTRUCTION = (
    "Você está verificando apenas a conexão de texto da ferramenta de desenvolvimento "
    "do jogo Slimekeepers: Lost Valley. Não execute ações. "
    "Responda somente com SLIMEKEEPERS_PROXY_OK, sem outras palavras."
)


class ProxyTextError(RuntimeError):
    """Mensagem curta, sem segredos e sem resposta bruta do provedor."""


def _enabled(name: str) -> bool:
    return os.environ.get(name, "").strip().lower() == "true"


def ensure_explicit_authorization() -> None:
    if not all(_enabled(name) for name in (
        "AI_ENABLED", "PAID_CALLS_ENABLED", "CODEX_PROXY_TEXT_AUTHORIZED"
    )):
        raise ProxyTextError("Inferência bloqueada: autorização explícita obrigatória.")
    if os.environ.get("GITHUB_RUN_ATTEMPT", "1") != "1":
        raise ProxyTextError("Não repetir um POST de inferência pelo rerun do GitHub.")


def selected_model(report: dict) -> str:
    if not isinstance(report, dict) or report.get("authenticated") is not True:
        raise ProxyTextError("Preflight autenticado obrigatório antes de gerar texto.")
    model = report.get("selected_model")
    reason = report.get("model_selection_reason")
    expected = {
        PREFERRED_MODEL: "preferred_catalog_available",
        FALLBACK_MODEL: "fallback_primary_absent_from_catalog",
    }
    if model not in ALLOWED_MODELS or reason != expected[model]:
        raise ProxyTextError("Modelo não verificado no catálogo do proxy.")
    if report.get("inference_requests") != 0:
        raise ProxyTextError("Preflight inválido: já registra inferência.")
    return model


def _extract_text(data: dict) -> str:
    if isinstance(data.get("output_text"), str) and data["output_text"]:
        return data["output_text"]
    chunks = []
    for message in data.get("output", []):
        if not isinstance(message, dict) or message.get("type") != "message":
            continue
        for item in message.get("content", []):
            if isinstance(item, dict) and item.get("type") in ("text", "output_text"):
                if isinstance(item.get("text"), str):
                    chunks.append(item["text"])
    return "".join(chunks)


def generate_text(base_url: str, api_key: str, model: str, *,
                  instructions: str, prompt: str, max_output_tokens: int = 300,
                  opener=None) -> dict:
    """Uma única inferência autorizada. Nenhum fallback após enviar o POST."""
    ensure_explicit_authorization()
    if model not in ALLOWED_MODELS:
        raise ProxyTextError("Modelo não permitido; consulte /v1/models primeiro.")
    if not isinstance(api_key, str) or len(api_key.strip()) < 20:
        raise ProxyTextError("CODEX_PROXY_API_KEY ausente ou inválida.")
    if not isinstance(instructions, str) or not isinstance(prompt, str):
        raise ProxyTextError("Instruções ou entrada inválidas.")
    if len((instructions + prompt).encode("utf-8")) > 16000:
        raise ProxyTextError("Entrada maior que o limite desta integração.")
    if type(max_output_tokens) is not int or not 1 <= max_output_tokens <= 800:
        raise ProxyTextError("Limite de saída inválido.")
    try:
        origin, kind = normalize_origin(base_url)
    except PreflightError as exc:
        raise ProxyTextError(str(exc)) from None
    body = json.dumps({
        "model": model, "instructions": instructions,
        "input": prompt, "max_output_tokens": max_output_tokens,
        "stream": False, "store": False,
    }, ensure_ascii=False).encode("utf-8")
    request = urllib.request.Request(
        origin + "/v1/responses", method="POST", data=body,
        headers={"Authorization": "Bearer " + api_key.strip(),
                 "Content-Type": "application/json",
                 "Accept": "application/json"},
    )
    if opener is None:
        handlers = [NoRedirect()]
        if kind == "local_loopback":
            handlers.insert(0, urllib.request.ProxyHandler({}))
        opener = urllib.request.build_opener(*handlers)
    try:
        with opener.open(request, timeout=75) as response:
            raw = response.read(1_000_001)
    except urllib.error.HTTPError as exc:
        raise ProxyTextError(
            "Proxy recusou inferência (HTTP %s); não repetir sem verificar status." % exc.code
        ) from None
    except (urllib.error.URLError, TimeoutError, OSError):
        raise ProxyTextError(
            "Inferência indisponível ou tempo excedido; não repetir o POST."
        ) from None
    if len(raw) > 1_000_000:
        raise ProxyTextError("Resposta do proxy excedeu o tamanho permitido.")
    try:
        data = json.loads(raw)
    except (ValueError, UnicodeError):
        raise ProxyTextError("Proxy retornou JSON inválido.") from None
    if not isinstance(data, dict) or data.get("model") != model:
        raise ProxyTextError("Modelo informado na resposta diverge do solicitado.")
    output = _extract_text(data)
    if not output:
        raise ProxyTextError("Resposta sem texto; não repetir o POST.")
    usage = data.get("usage")
    usage = usage if isinstance(usage, dict) else {}
    tokens = {}
    for key in ("input_tokens", "output_tokens"):
        val = usage.get(key)
        tokens[key] = val if type(val) is int and 0 <= val <= 1_000_000 else None
    return {"model": model, "text": output, "usage": tokens}


def ping(report: dict, *, base_url: str, api_key: str, opener=None) -> dict:
    model = selected_model(report)
    reply = generate_text(base_url, api_key, model, instructions=PING_INSTRUCTION,
                          prompt="Confirme a integração de texto.", max_output_tokens=100,
                          opener=opener)
    if reply["text"].strip() != "SLIMEKEEPERS_PROXY_OK":
        raise ProxyTextError("Resposta recebida, mas contrato do teste não foi confirmado.")
    return {
        "schema": "slimekeepers/codex-proxy-ping/v1",
        "status": "verified",
        "model": model,
        "model_selection_reason": report["model_selection_reason"],
        "text_inference_executed": True,
        "response_contract_verified": True,
        "inference_requests": 1,
        "image_requests": 0,
        "game_files_modified": 0,
        "usage": reply["usage"],
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Teste de uma única resposta Astra")
    parser.add_argument("--preflight", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        report = json.loads(args.preflight.read_text(encoding="utf-8"))
        result = ping(report, base_url=os.getenv("CODEX_PROXY_BASE_URL", ""),
                      api_key=os.getenv("CODEX_PROXY_API_KEY", ""))
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
        print(json.dumps(result, ensure_ascii=False))
    except (ProxyTextError, PreflightError, ValueError, OSError, KeyError, TypeError):
        parser.exit(2, "SLIMEKEEPERS_PROXY_STATUS=BLOCKED_OR_FAILED; nenhum POST sera repetido.\n")


if __name__ == "__main__":
    main()

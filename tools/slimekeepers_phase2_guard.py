"""Hard gate independente para propostas da Fase 2.

Executar SOMENTE após checkout em runner sem segredos. Valida SHA de base,
nomes e tipos dos arquivos editados e linhas novas; não confia no relatório
escrito pelo modelo nem em uma branch de checkpoint como aprovação.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import re
import subprocess

from slimekeepers_phase2_agent import (
    ROOT, Phase2Error, kind, queue, report_path, test_path, editable_paths,
    path_under_root,
)
from slimekeepers_autonomy_guard import validate_source

FORBIDDEN_ADDITIONS = (
    "CODEX_PROXY_API_KEY", "PIXELLAB_API_TOKEN", "GITHUB_TOKEN",
    "refresh_token", "access_token", "HTTPRequest", "HTTPClient",
    "FileAccess", "DirAccess", "OS.", "@tool", "ResourceSaver",
    "ProjectSettings.set_setting", "EditorPlugin", "GDExtension",
    "user://", "res://.github/", "res://.git/",
)


def validate_changed(task: dict, changes: list[tuple[str, str]],
                     sources: dict[str, str], diff: str) -> None:
    mode = kind(task)
    if mode not in ("report", "patch"):
        raise Phase2Error("Modo não executável pelo Astra.")
    if mode == "report":
        expected = {"A": {report_path(task)}}
    else:
        expected = {"A": {test_path(task)}, "M": set(editable_paths(task))}
    seen = set()
    edited = set()
    for status, name in changes:
        if not status in expected or name not in expected[status]:
            raise Phase2Error("Mudança fora do escopo explícito.")
        if name in seen:
            raise Phase2Error("Arquivo repetido.")
        seen.add(name)
        if status == "M":
            edited.add(name)
    if not seen or set(sources) != seen:
        raise Phase2Error("Diff vazio ou inventário inconsistente.")
    if mode == "report":
        if seen != {report_path(task)}:
            raise Phase2Error("Relatório deve ser o único arquivo novo.")
        text = sources[report_path(task)]
        if not text.startswith("#") or len(text) < 200 or len(text.encode("utf-8")) > 12_000:
            raise Phase2Error("Relatório inválido.")
    else:
        if test_path(task) not in seen or not 1 <= len(edited) <= 2:
            raise Phase2Error("Patch exige alteração real e suite própria.")
        validate_source(test_path(task), sources[test_path(task)])
        for p in edited:
            text = sources[p]
            if len(text.encode("utf-8")) > 200_000:
                raise Phase2Error("Arquivo modificado muito grande.")
            if p.endswith(".gd") and not text.lstrip().startswith(("extends ", "class_name ", "@warning_ignore")):
                raise Phase2Error("Arquivo de script com cabeçalho incompatível.")
    if any(x in "\r\x00" for x in diff):
        raise Phase2Error("Diff contém bytes inesperados.")
    # Com git diff -U0, somente linhas adicionadas são verificadas,
    # evitando falsos positivos por chamadas já presentes antes do patch.
    additions = "\n".join(
        line[1:] for line in diff.splitlines()
        if line.startswith("+") and not line.startswith("+++")
    )
    lowered = additions.lower()
    for frag in FORBIDDEN_ADDITIONS:
        if frag == "OS.":
            if re.search(r"(?<![A-Za-z0-9_])OS\s*\.", additions):
                raise Phase2Error("Uso de singleton OS não autorizado.")
        elif frag.lower() in lowered:
            raise Phase2Error("Nova capacidade perigosa ou segredo no patch.")
    if re.search(r"(?m)^\s*(?:run|script|command):", additions) and mode == "patch":
        raise Phase2Error("Patch tentou introduzir instruções de execução.")


def inspect(task_id: str, base_sha: str) -> None:
    if not re.fullmatch(r"[a-f0-9]{40}", base_sha):
        raise Phase2Error("SHA base inválido.")
    task = next((t for t in queue() if t["id"] == task_id), None)
    if not task:
        raise Phase2Error("Tarefa desconhecida.")
    changes_proc = subprocess.run(
        ["git", "diff", "--name-status", "--no-renames", base_sha, "HEAD"],
        cwd=ROOT, capture_output=True, text=True, timeout=25, check=True,
    )
    changes = []
    for line in changes_proc.stdout.splitlines():
        parts = line.split("\t", 1)
        if len(parts) != 2 or parts[0] not in ("A", "M"):
            raise Phase2Error("Status do diff inseguro.")
        changes.append((parts[0], parts[1]))
    sources = {}
    for _, name in changes:
        p = path_under_root(name)
        if not p.is_file() or p.is_symlink():
            raise Phase2Error("Arquivo ausente ou symlink.")
        sources[name] = p.read_text(encoding="utf-8")
    diff = subprocess.run(
        ["git", "diff", "--no-ext-diff", "--no-renames", "--unified=0", base_sha, "HEAD"],
        cwd=ROOT, capture_output=True, text=True, timeout=25, check=True,
    ).stdout
    validate_changed(task, changes, sources, diff)
    print("PASS: fase 2 limitada aos arquivos esperados, diff analisado e execução sem segredos.")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--task-id", required=True)
    parser.add_argument("--base-sha", required=True)
    args = parser.parse_args()
    try:
        inspect(args.task_id, args.base_sha)
    except (Phase2Error, OSError, ValueError, subprocess.SubprocessError) as e:
        parser.exit(2, "PHASE2_QA=BLOCKED: revisar alterações sem repetir inferência.\n")


if __name__ == "__main__":
    main()

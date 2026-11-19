"""Hard gate for autonomously generated, *additive only* Godot modules.

This validator runs in a separate GitHub Actions job without proxy secrets.
Only exactly the two files specified in the trusted task manifest can change.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import re
import subprocess

from slimekeepers_dev_agent import ROOT, DevTaskError, load_tasks, _inside_repo

DANGEROUS = (
    "@tool", "OS.", "FileAccess", "DirAccess", "JavaScriptBridge",
    "HTTPRequest", "HTTPClient", "StreamPeer", "TCPServer", "UDPServer",
    "ResourceSaver", "EditorInterface", "EditorPlugin", "GDExtension",
    "GDScript.new", "ProjectSettings.set_setting", "get_tree().quit",
    "user://", "res://.github/", "res://.git/", "github_token", "access_token",
    "refresh_token", "codeX_proxy_api_key",
)


def validate_source(path: str, content: str) -> None:
    if not 20 <= len(content.encode("utf-8")) <= 18_000:
        raise DevTaskError("Arquivo gerado fora dos limites permitidos.")
    if "\0" in content or "\r" in content:
        raise DevTaskError("Arquivo gerado contem bytes invalidos.")
    if not content.lstrip().startswith("extends "):
        raise DevTaskError("Classe base do script invalida.")
    lowered = content.lower()
    for fragment in DANGEROUS:
        if fragment.lower() in lowered:
            raise DevTaskError("Chamadas com efeitos colaterais proibidas na entrega autonoma.")
    if path.startswith("tests/"):
        if "extends GdUnitTestSuite" not in content[:250]:
            raise DevTaskError("Suite deve ser GdUnit4.")
        methods = re.findall(r"(?m)^\s*func\s+(test_[a-z0-9_]+)\s*\(", content)
        if len(set(methods)) < 3 or len(methods) != len(set(methods)):
            raise DevTaskError("Suite automatica deve declarar ao menos tres testes independentes.")
        if len(re.findall(r"\bassert_[a-z_]+\s*\(", content)) < 4:
            raise DevTaskError("Suite automatica precisa de assercoes suficientes.")
    else:
        if "func " not in content:
            raise DevTaskError("Modulo sem funcionalidade.")


def validate_changes(task: dict, changes: list[tuple[str, str]], files: dict[str, str]) -> None:
    expected = set(task["allowed_files"])
    changed = {path for _, path in changes}
    if changed != expected or any(status != "A" for status, _ in changes):
        raise DevTaskError("O agente tentou sobrescrever arquivos ou alterar caminhos nao autorizados.")
    if set(files) != expected:
        raise DevTaskError("Faltam arquivos para validacao.")
    for path, content in files.items():
        validate_source(path, content)


def inspect_worktree(task_id: str, base_sha: str) -> None:
    tasks = load_tasks()
    task = next((item for item in tasks if item["id"] == task_id), None)
    if task is None or not re.fullmatch(r"[a-f0-9]{40}", base_sha):
        raise DevTaskError("Task/base SHA invalidos.")
    result = subprocess.run(
        ["git", "diff", "--name-status", "--no-renames", base_sha, "HEAD"],
        cwd=ROOT, capture_output=True, text=True, check=True, timeout=20,
    )
    changes = [tuple(line.split("\t", 1)) for line in result.stdout.splitlines()]
    if any(len(entry) != 2 for entry in changes):
        raise DevTaskError("Diff inesperado.")
    files: dict[str, str] = {}
    for name in task["allowed_files"]:
        path = _inside_repo(name)
        if not path.is_file() or path.is_symlink():
            raise DevTaskError("Arquivo gerado ausente ou simbolico.")
        files[name] = path.read_text(encoding="utf-8")
    validate_changes(task, changes, files)
    print("PASS: arquivos novos autorizados, GDScript limitado, suite com testes reais declarados.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--task-id", required=True)
    parser.add_argument("--base-sha", required=True)
    args = parser.parse_args()
    inspect_worktree(args.task_id, args.base_sha)


if __name__ == "__main__":
    main()

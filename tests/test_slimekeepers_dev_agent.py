"""Testes locais do agente. Não acessam proxy, não criam PR e não cobram chamadas."""
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import slimekeepers_dev_agent as dev


def task():
    return {
        "id": "inventory-foundation", "title": "Inventário", "goal": "Criar inventário",
        "allowed_files": ["scripts/systems/collectible_inventory.gd",
                          "tests/forest/test_collectible_inventory.gd"],
        "context_files": [], "acceptance": ["teste"],
    }


def proposal():
    return {"summary": "Inventário e testes propostos", "files": [
        {"path": "scripts/systems/collectible_inventory.gd",
         "content": "extends Node\n\nvar items: Dictionary = {}\n"},
        {"path": "tests/forest/test_collectible_inventory.gd",
         "content": "extends GdUnitTestSuite\n\nfunc test_empty() -> void:\n\tassert_bool(true).is_true()\n"},
    ]}


PREFLIGHT = {
    "authenticated": True, "selected_model": "gpt-6.2-astra",
    "model_selection_reason": "preferred_catalog_available",
    "inference_requests": 0,
}


class DevAgentTests(unittest.TestCase):
    def test_queue_loads_and_has_unique_tasks(self):
        tasks = dev.load_tasks()
        self.assertGreaterEqual(len(tasks), 3)
        self.assertEqual(len({t["id"] for t in tasks}), len(tasks))
        self.assertTrue(all(t["allowed_files"] for t in tasks))

    def test_choose_first_task_not_reserved(self):
        tasks = [task(), {**task(), "id": "next-task"}]
        chosen = dev.choose_task(tasks, "auto", {"ai/inventory-foundation"})
        self.assertEqual(chosen["id"], "next-task")
        self.assertIsNone(dev.choose_task(tasks, "auto", {
            "ai/inventory-foundation", "ai/next-task"}))

    def test_manual_duplicate_reservation_is_blocked(self):
        with self.assertRaises(dev.DevTaskError):
            dev.choose_task([task()], "inventory-foundation", {"ai/inventory-foundation"})

    def test_unknown_task_blocked(self):
        with self.assertRaises(dev.DevTaskError):
            dev.choose_task([task()], "unknown", set())

    def test_rejects_out_of_scope_path(self):
        p = proposal()
        p["files"][0]["path"] = ".github/workflows/evil.yml"
        with self.assertRaises(dev.DevTaskError):
            dev.validate_proposal(p, task())

    def test_rejects_unauthorized_existing_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            target = root / "scripts/systems/collectible_inventory.gd"
            target.parent.mkdir(parents=True)
            target.write_text("approved work", encoding="utf-8")
            with patch.object(dev, "ROOT", root):
                with self.assertRaises(dev.DevTaskError):
                    dev.validate_proposal(proposal(), task())
            self.assertEqual(target.read_text(), "approved work")

    def test_rejects_proposal_missing_test(self):
        p = proposal()
        p["files"] = [p["files"][0]]
        with self.assertRaises(dev.DevTaskError):
            dev.validate_proposal(p, task())

    def test_rejects_credentials_in_generated_source(self):
        p = proposal()
        p["files"][0]["content"] += "\nvar key = 'refresh_token'\n"
        with self.assertRaises(dev.DevTaskError):
            dev.validate_proposal(p, task())

    def test_rejects_wrong_test_base(self):
        p = proposal()
        p["files"][1]["content"] = "extends Node\n\nfunc test_empty() -> void:\n\tpass\n"
        with self.assertRaises(dev.DevTaskError):
            dev.validate_proposal(p, task())

    def test_one_model_call_writes_only_scoped_files_and_reports_review(self):
        calls = []
        def fake_generator(base, key, model, **kwargs):
            calls.append(model)
            return {"text": json.dumps(proposal()),
                    "usage": {"input_tokens": 90, "output_tokens": 100}}
        with tempfile.TemporaryDirectory() as tmp:
            with patch.object(dev, "ROOT", Path(tmp)), \
                 patch.object(dev, "_content_for_model", return_value="contexto"), \
                 patch.dict(os.environ, {"CODEX_PROXY_BASE_URL": "http://127.0.0.1:18080",
                                         "CODEX_PROXY_API_KEY": "synthetic-example"}):
                report = dev.implement(task(), PREFLIGHT, generator=fake_generator)
                self.assertEqual(report["status"], "proposed_for_human_review")
                self.assertFalse(report["godot_runtime_verified"])
                self.assertFalse(report["merged"])
                self.assertEqual(calls, ["gpt-6.2-astra"])
                self.assertTrue((Path(tmp)/"scripts/systems/collectible_inventory.gd").exists())
                self.assertTrue((Path(tmp)/"tests/forest/test_collectible_inventory.gd").exists())

    def test_invalid_json_does_not_retry(self):
        calls = []
        def fake_generator(*args, **kwargs):
            calls.append(1)
            return {"text": "not json"}
        with patch.object(dev, "_content_for_model", return_value="contexto"):
            with self.assertRaises(dev.DevTaskError):
                dev.implement(task(), PREFLIGHT, generator=fake_generator)
        self.assertEqual(len(calls), 1)

    def test_fallback_is_selected_only_from_preflight(self):
        fallback = {**PREFLIGHT, "selected_model": "gpt-6-astra",
                    "model_selection_reason": "fallback_primary_absent_from_catalog"}
        calls = []
        def fake_generator(base, key, model, **kwargs):
            calls.append(model)
            return {"text": json.dumps(proposal()), "usage": {}}
        with tempfile.TemporaryDirectory() as tmp:
            with patch.object(dev, "ROOT", Path(tmp)), \
                 patch.object(dev, "_content_for_model", return_value="contexto"):
                report = dev.implement(task(), fallback, generator=fake_generator)
        self.assertEqual(report["model"], "gpt-6-astra")
        self.assertEqual(calls, ["gpt-6-astra"])


if __name__ == "__main__":
    unittest.main()

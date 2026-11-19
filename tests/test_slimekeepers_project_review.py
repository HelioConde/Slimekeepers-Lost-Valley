"""Offline regression tests; never connect to proxy or run Godot."""
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import slimekeepers_project_review as review

PREFLIGHT = {
    "authenticated": True,
    "selected_model": "gpt-6.2-astra",
    "model_selection_reason": "preferred_catalog_available",
    "inference_requests": 0,
}


class ReviewTests(unittest.TestCase):
    def _create_inputs(self, root):
        for name, _ in review.CONTEXT:
            path = Path(root) / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("extends Node\n# Exemplo público de gameplay Godot.\n", encoding="utf-8")

    def test_context_uses_whitelist_and_no_env(self):
        with tempfile.TemporaryDirectory() as temp:
            self._create_inputs(temp)
            (Path(temp) / ".env").write_text("PRIVATE=never-send\n", encoding="utf-8")
            with patch.object(review, "ROOT", Path(temp)):
                prompt, files = review.context()
            self.assertEqual(len(files), len(review.CONTEXT))
            self.assertNotIn("PRIVATE", prompt)
            self.assertNotIn(".env", prompt)
            self.assertIn("scripts/world/forest_slime.gd", files)
            self.assertLessEqual(len((review.INSTRUCTIONS + prompt).encode("utf-8")), 6200)

    def test_one_request_readonly_and_model_primary(self):
        with tempfile.TemporaryDirectory() as temp:
            self._create_inputs(temp)
            original = (Path(temp) / "README.md").read_text()
            seen = []
            def fake(*args, **kwargs):
                seen.append((args, kwargs))
                return {
                    "text": "## Análise\nO projeto possui base Godot e precisa de testes de integração. "
                            "Prioridade: inventário de coleta antes de outras regiões.",
                    "usage": {"input_tokens": 100, "output_tokens": 50},
                }
            with patch.object(review, "ROOT", Path(temp)):
                result = review.analyze(PREFLIGHT, generator=fake)
            self.assertEqual(len(seen), 1)
            self.assertEqual(seen[0][1]["max_output_tokens"], 850)
            self.assertEqual(seen[0][0][2], "gpt-6.2-astra")
            self.assertEqual(result["game_files_changed"], 0)
            self.assertEqual(result["status"], "reviewed_not_implemented")
            self.assertFalse(result["godot_executed"])
            self.assertEqual((Path(temp) / "README.md").read_text(), original)

    def test_model_fallback_before_post(self):
        report = {**PREFLIGHT, "selected_model": "gpt-6-astra",
                  "model_selection_reason": "fallback_primary_absent_from_catalog"}
        calls = []
        def fake(*args, **kwargs):
            calls.append(args[2])
            return {"text": "Análise Godot: as tarefas pendentes incluem inventário, "
                            "alimentação e vínculos de slimes, com testes separados.", "usage": {}}
        with tempfile.TemporaryDirectory() as temp:
            self._create_inputs(temp)
            with patch.object(review, "ROOT", Path(temp)):
                result = review.analyze(report, generator=fake)
        self.assertEqual(calls, ["gpt-6-astra"])
        self.assertEqual(result["retry_attempts"], 0)

    def test_sensitive_response_not_published(self):
        def fake(*args, **kwargs):
            return {"text": "Tarefa pronta. CODEX_PROXY_API_KEY=not-a-real-secret-but-must-block. "
                            "Análise de teste longa o suficiente para garantir a validação.", "usage": {}}
        with tempfile.TemporaryDirectory() as temp:
            self._create_inputs(temp)
            with patch.object(review, "ROOT", Path(temp)):
                with self.assertRaises(review.ReviewError):
                    review.analyze(PREFLIGHT, generator=fake)

    def test_empty_response_does_not_retry(self):
        calls = []
        def fake(*args, **kwargs):
            calls.append(1)
            return {"text": "", "usage": {}}
        with tempfile.TemporaryDirectory() as temp:
            self._create_inputs(temp)
            with patch.object(review, "ROOT", Path(temp)):
                with self.assertRaises(review.ReviewError):
                    review.analyze(PREFLIGHT, generator=fake)
        self.assertEqual(calls, [1])

    def test_gdscript_context_uses_function_outline_not_full_source(self):
        text = "extends Node\nfunc collect() -> void:\n    var private = 'omit'\nfunc save() -> void:\n    pass\n"
        excerpt = review._excerpt("scripts/systems/game_clock.gd", text, 200)
        self.assertIn("func collect()", excerpt)
        self.assertIn("func save()", excerpt)
        self.assertNotIn("private", excerpt)

    def test_large_plan_only_sends_headings_and_pending_items(self):
        text = "# Plano\n- [x] feito\n- [ ] pendente\nexplicacao longa\n"
        excerpt = review._excerpt("PLANO_DE_DESENVOLVIMENTO.md", text, 300)
        self.assertIn("pendente", excerpt)
        self.assertNotIn("feito", excerpt)
        self.assertNotIn("explicacao longa", excerpt)

    def test_context_missing_file_blocks_before_call(self):
        with tempfile.TemporaryDirectory() as temp:
            with patch.object(review, "ROOT", Path(temp)):
                with self.assertRaises(review.ReviewError):
                    review.context()


if __name__ == "__main__":
    unittest.main()

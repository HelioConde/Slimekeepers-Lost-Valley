"""Testes offline do executor fase 2: nenhum POST de IA."""
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import slimekeepers_phase2_agent as agent
import slimekeepers_phase2_guard as guard


def task(task_id="p2-bag-adapter"):
    return {
        "id": task_id, "title": "Bolsa", "status": "planned",
        "candidate_paths": ["scripts/systems/forest_bag.gd",
                            "docs/narrativa/BIBLIA_NARRATIVA.md"],
        "depends_on": [], "acceptance": ["Manter bolsa consistente"],
    }


def gdunit():
    return ("extends GdUnitTestSuite\n"
            "func test_a() -> void:\n\tassert_bool(true).is_true()\n"
            "func test_b() -> void:\n\tassert_bool(true).is_true()\n"
            "func test_c() -> void:\n\tassert_bool(true).is_true()\n"
            "func test_d() -> void:\n\tassert_bool(true).is_true()\n")


class Phase2AgentTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        path = self.root / "scripts/systems/forest_bag.gd"
        path.parent.mkdir(parents=True)
        path.write_text("extends RefCounted\nfunc count():\n\treturn 0\n", encoding="utf-8")
        self.patch_agent = patch.object(agent, "ROOT", self.root)
        self.patch_guard = patch.object(guard, "ROOT", self.root)
        self.patch_agent.start()
        self.patch_guard.start()

    def tearDown(self):
        self.patch_agent.stop()
        self.patch_guard.stop()
        self.tmp.cleanup()

    def test_reports_are_additive(self):
        t = task("p2-audit-runtime")
        self.assertEqual(agent.kind(t), "report")
        proposal = {"summary": "Auditado", "report": "# Auditoria\n" + "Relação dos sinais e mudanças esperadas.\n" * 10}
        files = agent.prepare(t, proposal)
        self.assertEqual(list(files), ["docs/phase2/p2-audit-runtime.md"])
        self.assertFalse((self.root / list(files)[0]).exists())
        guard.validate_changed(t, [("A", "docs/phase2/p2-audit-runtime.md")],
                               files, "+# Auditoria\n")

    def test_literal_patch_requires_own_suite(self):
        t = task()
        proposal = {"summary": "Bolsa", "edits": [
            {"path": "scripts/systems/forest_bag.gd",
             "find": "func count():\n\treturn 0",
             "replace": "func count():\n\treturn 1"}],
            "test": {"path": agent.test_path(t), "content": gdunit()}}
        files = agent.prepare(t, proposal)
        self.assertEqual(len(files), 2)
        self.assertIn("return 1", files["scripts/systems/forest_bag.gd"])
        self.assertEqual((self.root / "scripts/systems/forest_bag.gd").read_text(),
                         "extends RefCounted\nfunc count():\n\treturn 0\n")
        changes = [("M", "scripts/systems/forest_bag.gd"),
                   ("A", agent.test_path(t))]
        guard.validate_changed(t, changes, files,
                               "+++ b/scripts/systems/forest_bag.gd\n+\treturn 1")
        with self.assertRaises(agent.Phase2Error):
            guard.validate_changed(t, changes + [("M", ".github/workflows/evil.yml")],
                                   files, "+hello")

    def test_rejects_wrong_path_and_nonunique_replace(self):
        t = task()
        base = {"summary": "Bolsa", "edits": [
            {"path": "scripts/systems/forest_bag.gd", "find": "return 0", "replace": "return 1"}],
            "test": {"path": agent.test_path(t), "content": gdunit()}}
        base["edits"][0]["path"] = "docs/narrativa/BIBLIA_NARRATIVA.md"
        with self.assertRaises(agent.Phase2Error):
            agent.prepare(t, base)
        base["edits"][0]["path"] = "scripts/systems/forest_bag.gd"
        base["edits"][0]["find"] = "missing snippet"
        with self.assertRaises(agent.Phase2Error):
            agent.prepare(t, base)
        base["edits"][0]["find"] = "return 0"
        base["edits"][0]["replace"] = "OS.execute('bad')"
        with self.assertRaises(agent.Phase2Error):
            guard.validate_changed(t, [
                ("M", "scripts/systems/forest_bag.gd"),
                ("A", agent.test_path(t))],
                {"scripts/systems/forest_bag.gd": "extends RefCounted\nOS.execute('bad')",
                 agent.test_path(t): gdunit()},
                "+OS.execute('bad')")

    def test_checkpoint_and_dependencies_block_duplicate_post(self):
        t = task("p2-audit-runtime")
        self.assertIsNone(agent.choose([t], "auto", {"p2/p2-audit-runtime"}))
        with self.assertRaises(agent.Phase2Error):
            agent.choose([t], "p2-audit-runtime", {"p2/p2-audit-runtime"})
        blocked = task("p2-contract-inventory")
        blocked["depends_on"] = ["p2-audit-runtime"]
        self.assertIsNone(agent.choose([t, blocked], "auto", {"p2/p2-audit-runtime"}))

    def test_completed_manual_pr_prevents_duplicate_inference(self):
        t = task("p2-cooking-interact")
        t["status"] = "completed"
        self.assertFalse(agent.satisfied(t))
        t["evidence"] = "https://github.com/HelioConde/Slimekeepers-Lost-Valley/pull/44"
        self.assertTrue(agent.satisfied(t))
        self.assertIsNone(agent.choose([t], "auto", set()))
        with self.assertRaises(agent.Phase2Error):
            agent.choose([t], "p2-cooking-interact", set())
        t["evidence"] = "https://example.invalid/pull/44"
        self.assertFalse(agent.satisfied(t))

    def test_visual_and_sensitive_sources_fail_closed(self):
        t = task("p2-pixellab-controlled-job")
        with self.assertRaises(agent.Phase2Error):
            agent.choose([t], t["id"], set())
        with self.assertRaises(agent.Phase2Error):
            agent.path_under_root("../secret")
        with self.assertRaises(agent.Phase2Error):
            agent.path_under_root(".github\\secrets")


if __name__ == "__main__":
    unittest.main()

"""Valida o contrato de planejamento da Fase 2, sem IA, token ou chamadas de rede."""
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
QUEUE = ROOT / "automation" / "phase2_10h_queue.json"
ID = re.compile(r"p2-[a-z0-9]+(?:-[a-z0-9]+)*\Z")


class Phase2BacklogTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads(QUEUE.read_text(encoding="utf-8"))

    def test_schema_and_total_are_coherent(self):
        data = self.manifest
        self.assertEqual(data["schema"], 1)
        self.assertEqual(data["phase"], "2")
        self.assertIn(data["execution_status"], ("planned_not_enabled", "scoped_executor_enabled"))
        tasks = data["tasks"]
        self.assertEqual(len(tasks), 30)
        total = sum(t["estimated_minutes"] for t in tasks)
        self.assertEqual(total, data["estimated_total_minutes"])
        self.assertEqual(total, sum(s["estimated_minutes"] for s in data["stages"]))
        self.assertEqual(total, 600)

    def test_ids_dependencies_and_allowed_scope_are_sane(self):
        seen = set()
        for task in self.manifest["tasks"]:
            task_id = task["id"]
            self.assertRegex(task_id, ID)
            self.assertNotIn(task_id, seen)
            for dep in task["depends_on"]:
                self.assertIn(dep, seen)
            seen.add(task_id)
            self.assertIn(task["status"], ("planned", "blocked", "in_progress", "completed"))
            self.assertGreater(task["estimated_minutes"], 0)
            self.assertTrue(task["acceptance"])
            self.assertTrue(task["candidate_paths"])
            self.assertNotIn("allowed_files", task)  # não equivale a autorização do runner!
            for path in task["candidate_paths"]:
                self.assertFalse(path.startswith("/") or ".." in path.split("/"))
                self.assertNotIn("\\", path)
                self.assertFalse(path == ".git" or path.startswith((".git/", "secrets/", ".env")))

    def test_stages_and_files_have_consistent_coverage(self):
        tasks = self.manifest["tasks"]
        stage_ids = {s["id"] for s in self.manifest["stages"]}
        self.assertEqual(set(t["stage"] for t in tasks), stage_ids)
        for stage in self.manifest["stages"]:
            matching = [t for t in tasks if t["stage"] == stage["id"]]
            self.assertEqual(len(matching), stage["tasks"])
            self.assertEqual(sum(t["estimated_minutes"] for t in matching),
                             stage["estimated_minutes"])
        for t in tasks:
            for path in t["candidate_paths"]:
                self.assertTrue((ROOT / path).exists(), path)


if __name__ == "__main__":
    unittest.main()

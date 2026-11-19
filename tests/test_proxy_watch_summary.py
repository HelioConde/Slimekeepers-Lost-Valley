"""Read-only model summary generation tests."""
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import proxy_watch_summary as summary


class ModelSummaryTests(unittest.TestCase):
    def test_redacts_account_metadata_and_displays_quota(self):
        preflight = {"model_ids": ["gpt-6.2-astra", "gpt-6-astra", "gpt-6.2-sol"]}
        quota = {"accounts": [{
            "email": "private@invalid.test",
            "upstream_account_id": "secret_identifier",
            "live_quota": {"primary": {
                "used_percent": 100, "reset_at_utc": "2026-11-19T18:14:51Z"
            }, "secondary": {"used_percent": 98}}
        }]}
        watch = {"smoke_eligible": False}
        catalog = {"models": [{"model": "gpt-6.2-sol", "model_endpoint": "resolved"}]}
        rendered = summary.render(preflight, quota, watch, catalog, {}, {})
        self.assertIn("100%", rendered)
        self.assertIn("98%", rendered)
        self.assertIn("gpt-6.2-sol | sim | confirmado | ainda nao testado", rendered)
        self.assertNotIn("private@invalid.test", rendered)
        self.assertNotIn("secret_identifier", rendered)

    def test_distinguishes_success_failure_and_catalog(self):
        rendered = summary.render(
            {"model_ids": ["gpt-6.2-astra", "gpt-6.2-sol", "gpt-6-astra"]},
            {}, {"smoke_eligible": True}, {},
            {"model": "gpt-6.2-astra", "status": "verified"},
            {"model": "gpt-6.2-sol", "status": "http_429"},
        )
        self.assertIn("gpt-6.2-astra | sim | nao testado | verified", rendered)
        self.assertIn("gpt-6.2-sol | sim | nao testado | http_429", rendered)
        self.assertIn("gpt-6-astra | sim | nao testado | ainda nao testado", rendered)

    def test_untrusted_model_text_is_never_printed(self):
        report = summary.render({"model_ids": ["gpt-6.2-astra", "<script>danger</script>"]},
                                {}, {}, {"models": [{
                                    "model": "<script>danger</script>",
                                    "model_endpoint": "resolved"
                                }]}, {}, {})
        self.assertNotIn("<script>", report)

    def test_missing_files_render_safely(self):
        with tempfile.TemporaryDirectory() as folder:
            self.assertEqual(summary.load(Path(folder) / "missing.json"), {})
            rendered = summary.render({}, {}, {}, {}, {}, {})
            self.assertIn("indisponivel", rendered)
            self.assertIn("ainda nao testado", rendered)


if __name__ == "__main__":
    unittest.main()

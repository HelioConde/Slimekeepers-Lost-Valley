"""Unit tests. No credentials, network or paid model calls."""
import json
import tempfile
import unittest
from pathlib import Path
from tools.claude_token_usage import summarize, compare
from tools.claude_statusline import render

class TokenEconomyTests(unittest.TestCase):
    def test_summary_ignores_message_content(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "result.jsonl"
            path.write_text("\n".join([
                json.dumps({"type": "assistant", "usage": {"input_tokens": 99999}, "content": "PRIVATE"}),
                json.dumps({"type": "result", "usage": {"input_tokens": 100, "output_tokens": 20, "cache_read_input_tokens": 30}, "total_cost_usd": 0.03})
            ]), encoding="utf-8")
            row = summarize(path)
            self.assertEqual(row["input_tokens"], 100)
            self.assertEqual(row["output_tokens"], 20)
            self.assertEqual(row["total_cost_usd"], 0.03)
    def test_empty_baseline_is_unknown(self):
        a = {k: 0 for k in ("input_tokens", "output_tokens", "cache_read_input_tokens", "cache_creation_input_tokens", "total_cost_usd")}
        self.assertIsNone(compare(a, a)["token_change_percent"])
    def test_requires_result_event(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "bad.json"
            path.write_text('{"type":"assistant"}', encoding="utf-8")
            with self.assertRaises(ValueError):
                summarize(path)
    def test_statusline_never_prints_private_contents(self):
        text = render({"model": {"display_name": "Sonnet"}, "context_window": {"used_percentage": 41}, "cost": {"total_cost_usd": 0.25}, "result": "SECRET"})
        self.assertIn("Contexto 41%", text)
        self.assertNotIn("SECRET", text)

if __name__ == "__main__":
    unittest.main()

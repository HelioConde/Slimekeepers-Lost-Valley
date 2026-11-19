"""Offline tests of other text model smoke tests; no real network calls."""
from datetime import datetime, timezone, timedelta
import io
import json
import os
from pathlib import Path
import sys
import unittest
import urllib.error
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import proxy_alternative_model_smoke as sm

NOW = datetime(2026, 11, 19, 20, 30, tzinfo=timezone.utc)
MODELS = ["gpt-6.2-astra", "gpt-6-astra", *sm.CANDIDATES]


def preflight():
    return {"authenticated": True, "inference_requests": 0, "model_ids": MODELS}


def watch(eligible=True):
    return {"smoke_eligible": eligible,
            "quota_readiness": "reported_available" if eligible else "rate_or_eligibility_blocked",
            "observed_at_utc": "2026-11-19T20:29:00Z"}


class Response:
    def __init__(self, obj):
        self.file = io.BytesIO(json.dumps(obj).encode())
    def __enter__(self):
        return self
    def __exit__(self, *args):
        return False
    def read(self, size):
        return self.file.read(size)


class FakeOpener:
    def __init__(self, *, mode="working"):
        self.calls = []
        self.mode = mode
    def open(self, request, timeout):
        self.calls.append((request.method, json.loads(request.data), timeout))
        if self.mode == "429":
            raise urllib.error.HTTPError(request.full_url, 429, "rate_limited", {}, None)
        if self.mode == "different":
            return Response({"model": "gpt-6-astra", "output_text": sm.EXPECTED})
        return Response({"model": json.loads(request.data)["model"], "output_text": sm.EXPECTED,
                         "usage": {"input_tokens": 32, "output_tokens": 12}})


class AlternativeModelTests(unittest.TestCase):
    def test_candidates_exclude_image_and_prod_priority(self):
        self.assertNotIn("gpt-6.2-astra", sm.CANDIDATES)
        self.assertNotIn("gpt-6-astra", sm.CANDIDATES)
        self.assertTrue(all("image" not in candidate for candidate in sm.CANDIDATES))

    def test_choose_first_available_unreserved(self):
        self.assertEqual(sm.choose(preflight(), set()), "gpt-6.2-sol")
        reserved = {sm.branch_for("gpt-6.2-sol")}
        self.assertEqual(sm.choose(preflight(), reserved), "gpt-6.1-sol")

    def test_queue_finishes_when_all_branches_exist(self):
        reserved = {sm.branch_for(c) for c in sm.CANDIDATES}
        self.assertIsNone(sm.choose(preflight(), reserved))

    def test_missing_catalog_does_not_test(self):
        with self.assertRaises(sm.SmokeError):
            sm.choose({"authenticated": True, "inference_requests": 0}, set())

    def test_gate_requires_quota_and_reserved_branch(self):
        with self.assertRaises(sm.SmokeError):
            sm.authorized_for_probe(preflight(), watch(False), "gpt-6.2-sol",
                                    {sm.branch_for("gpt-6.2-sol")}, now=NOW)
        with self.assertRaises(sm.SmokeError):
            sm.authorized_for_probe(preflight(), watch(), "gpt-6.2-sol",
                                    set(), now=NOW)

    def test_gate_rejects_stale_quota(self):
        stale = watch()
        stale["observed_at_utc"] = "2026-11-19T19:30:00Z"
        with self.assertRaises(sm.SmokeError):
            sm.authorized_for_probe(preflight(), stale, "gpt-6.2-sol",
                                    {sm.branch_for("gpt-6.2-sol")}, now=NOW)

    def test_gate_allows_safe_valid_snapshot(self):
        sm.authorized_for_probe(preflight(), watch(), "gpt-6.2-sol",
                                {sm.branch_for("gpt-6.2-sol")}, now=NOW)

    def test_one_successful_post_to_requested_model(self):
        opener = FakeOpener()
        flags = {"AI_ENABLED": "true", "PAID_CALLS_ENABLED": "true",
                 "CODEX_PROXY_TEXT_AUTHORIZED": "true", "GITHUB_RUN_ATTEMPT": "1"}
        with patch.dict(os.environ, flags):
            report = sm.probe_text("http://127.0.0.1:18080", "x" * 40,
                                   "gpt-6.2-sol", opener=opener)
        self.assertTrue(report["verified"])
        self.assertEqual(report["status"], "working")
        self.assertEqual(report["inference_requests"], 1)
        self.assertEqual(len(opener.calls), 1)
        self.assertEqual(opener.calls[0][1]["model"], "gpt-6.2-sol")
        self.assertEqual(opener.calls[0][1]["max_output_tokens"], 96)

    def test_429_no_retry(self):
        opener = FakeOpener(mode="429")
        flags = {"AI_ENABLED": "true", "PAID_CALLS_ENABLED": "true",
                 "CODEX_PROXY_TEXT_AUTHORIZED": "true", "GITHUB_RUN_ATTEMPT": "1"}
        with patch.dict(os.environ, flags):
            report = sm.probe_text("http://127.0.0.1:18080", "x" * 40,
                                   "gpt-6-sol", opener=opener)
        self.assertFalse(report["verified"])
        self.assertEqual(report["status"], "http_429")
        self.assertEqual(len(opener.calls), 1)

    def test_response_wrong_model_not_verified(self):
        opener = FakeOpener(mode="different")
        flags = {"AI_ENABLED": "true", "PAID_CALLS_ENABLED": "true",
                 "CODEX_PROXY_TEXT_AUTHORIZED": "true", "GITHUB_RUN_ATTEMPT": "1"}
        with patch.dict(os.environ, flags):
            report = sm.probe_text("http://127.0.0.1:18080", "x" * 40,
                                   "gpt-6.2-sol", opener=opener)
        self.assertEqual(report["status"], "response_model_mismatch")

    def test_without_authorization_no_post(self):
        opener = FakeOpener()
        with patch.dict(os.environ, {"AI_ENABLED": "false", "PAID_CALLS_ENABLED": "false",
                                     "CODEX_PROXY_TEXT_AUTHORIZED": "false"}):
            with self.assertRaises(sm.ProxyTextError):
                sm.probe_text("http://127.0.0.1:18080", "x" * 40,
                              "gpt-6.2-sol", opener=opener)
        self.assertEqual(opener.calls, [])


if __name__ == "__main__":
    unittest.main()

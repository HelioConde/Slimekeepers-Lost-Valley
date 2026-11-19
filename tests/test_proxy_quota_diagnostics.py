"""Offline tests for GET-only sanitized quota diagnostics."""
import io
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import proxy_quota_diagnostics as diag


class FakeResponse:
    def __init__(self, obj):
        self.data = io.BytesIO(json.dumps(obj).encode())
    def __enter__(self):
        return self
    def __exit__(self, *args):
        pass
    def read(self, amount):
        return self.data.read(amount)


class FakeOpener:
    def __init__(self, *, live=True):
        self.routes = {
            "/health": {"status": "ok", "accounts": 1},
            "/v1/models": {"data": [
                {"id": "gpt-6.2-astra"}, {"id": "gpt-6-astra"}, {"id": "gpt-image-2"}]},
            "/admin/accounts": {"accounts": [{
                "id": "internal-account-guid", "email": "sensitive@example.com",
                "upstream_account_id": "private-upstream", "status": "active",
                "eligible_now": False, "cooldown_until": "2026-11-19T18:00:00Z",
                "oauth_expires": "2030-01-01T00:00:00Z",
                "cached_quota": {"rate_limit": {"used_percent": 100,
                                               "limit_reached": True, "allowed": False,
                                               "reset_at": "2026-11-19T19:00:00Z"},
                                 "source": "response_headers"}}]},
            "/admin/accounts/internal-account-guid/usage?cached=true": {
                "account_id": "internal-account-guid", "cached_quota": {
                    "rate_limit": {"used_percent": 100, "limit_reached": True,
                                   "reset_at": "2026-11-19T19:00:00Z"},
                    "source": "response_headers"}},
        }
        if live:
            self.routes["/admin/accounts/internal-account-guid/usage"] = {
                "account_id": "internal-account-guid",
                "quota_runtime": {"source": "usage_endpoint",
                                  "rate_limit": {"used_percent": 98, "limit_reached": False,
                                                 "reset_at": "2026-11-19T19:30:00Z"},
                                  "fetched_at": "2026-11-19T17:30:00Z"}
            }
        self.calls = []
    def open(self, request, timeout):
        self.calls.append((request.method, request.full_url, request.get_header("Authorization")))
        path = request.full_url.split("18080", 1)[1]
        if path not in self.routes:
            raise diag.urllib.error.HTTPError(request.full_url, 502, "bad_gateway", {}, None)
        return FakeResponse(self.routes[path])


KEY = "X" * 42
ORIGIN = "http://127.0.0.1:18080"


class QuotaDiagnosticsTests(unittest.TestCase):
    def test_sanitized_get_only_live_quota(self):
        opener = FakeOpener()
        report = diag.diagnose(ORIGIN, KEY, live=True, opener=opener)
        serialized = json.dumps(report)
        self.assertEqual(report["inference_requests"], 0)
        self.assertTrue(report["preferred_in_catalog"])
        self.assertEqual(report["catalog_count"], 3)
        self.assertEqual(report["accounts"][0]["live_quota"]["primary"]["used_percent"], 98)
        self.assertEqual(report["accounts"][0]["cached_quota"]["primary"]["used_percent"], 100)
        self.assertEqual(report["accounts"][0]["cooldown_until_utc"], "2026-11-19T18:00:00+00:00")
        self.assertTrue(all(method == "GET" for method, _, _ in opener.calls))
        self.assertTrue(all(auth == "Bearer " + KEY for _, _, auth in opener.calls))
        self.assertNotIn("sensitive@example.com", serialized)
        self.assertNotIn("private-upstream", serialized)
        self.assertNotIn("internal-account-guid", serialized)
        self.assertNotIn(KEY, serialized)

    def test_readonly_cached_mode_makes_no_upstream_usage_lookup(self):
        opener = FakeOpener()
        report = diag.diagnose(ORIGIN, KEY, live=False, opener=opener)
        self.assertEqual(report["accounts"][0]["live_query"], "not_requested")
        self.assertTrue(all("usage?cached=true" in path for method, path, auth in opener.calls
                            if "/usage" in path))

    def test_live_usage_failure_is_redacted_and_not_retried(self):
        opener = FakeOpener(live=False)
        report = diag.diagnose(ORIGIN, KEY, live=True, opener=opener)
        self.assertEqual(report["accounts"][0]["live_query"], "failed_http_502")
        self.assertEqual(report["accounts"][0]["live_quota"], {"available": False})
        self.assertEqual(sum("/usage" in path and "?cached=true" not in path
                             for _, path, _ in opener.calls), 1)

    def test_model_missing_does_not_claim_capacity(self):
        opener = FakeOpener()
        opener.routes["/v1/models"] = {"data": [{"id": "gpt-6-astra"}]}
        report = diag.diagnose(ORIGIN, KEY, opener=opener)
        self.assertFalse(report["preferred_in_catalog"])
        self.assertTrue(report["fallback_in_catalog"])
        self.assertFalse(report["model_catalog_proves_inference_capacity"])

    def test_rejects_insecure_http_remote(self):
        with self.assertRaises(diag.PreflightError):
            diag.diagnose("http://example.com:8080", KEY, opener=FakeOpener())

    def test_rejects_unsafe_account_identifier_without_request(self):
        opener = FakeOpener()
        opener.routes["/admin/accounts"] = {
            "accounts": [{"id": "../etc", "status": "active"}]}
        with self.assertRaises(diag.DiagnosticError):
            diag.diagnose(ORIGIN, KEY, opener=opener)
        self.assertEqual(len(opener.calls), 3)

    def test_unavailable_quota_is_not_treated_as_zero_usage(self):
        self.assertEqual(diag._quota(None), {"available": False})
        self.assertIsNone(diag._rate_window({"used_percent": -20})["used_percent"])
        self.assertIsNone(diag._rate_window({"used_percent": "50"})["used_percent"])

    def test_strips_invalid_source(self):
        summary = diag._quota({"source": "email:someone@example.com",
                               "rate_limit": {"used_percent": 10}})
        self.assertEqual(summary["source"], "unrecognized")


if __name__ == "__main__":
    unittest.main()

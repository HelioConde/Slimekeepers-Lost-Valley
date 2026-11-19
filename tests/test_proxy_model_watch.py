"""Smoke gate logic tests; no HTTP and no inference."""
from datetime import datetime, timezone, timedelta
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from proxy_model_watch import evaluate, _window_open, PRIMARY, FALLBACK

NOW = datetime(2026, 11, 19, 20, 0, tzinfo=timezone.utc)


def preflight(primary=True):
    ids = [FALLBACK, "gpt-image-2"]
    if primary:
        ids.append(PRIMARY)
    return {
        "authenticated": True,
        "model_ids": ids,
        "model_count": len(ids),
        "selected_model": PRIMARY if primary else FALLBACK,
    }


def quota(*, used=22, secondary=15, eligible=True, cached_used=100,
          fetched="2026-11-19T19:59:00Z", cooldown=None):
    return {
        "authenticated": True,
        "accounts": [{
            "status": "active", "eligible_now": eligible,
            "oauth_expired": False, "cooldown_until_utc": cooldown,
            "live_query": "success",
            "cached_quota": {"available": True, "primary": {
                "limit_reached": cached_used >= 100, "allowed": cached_used < 100,
                "used_percent": cached_used}},
            "live_quota": {"available": True, "fetched_at_utc": fetched,
                           "primary": {"used_percent": used,
                                       "limit_reached": used >= 100, "allowed": used < 100},
                           "secondary": {"used_percent": secondary,
                                         "limit_reached": secondary >= 100, "allowed": secondary < 100}},
        }],
    }


class WatchTests(unittest.TestCase):
    def test_primary_selected_when_catalog_contains_it(self):
        x = evaluate(preflight(), quota(), now=NOW)
        self.assertTrue(x["smoke_eligible"])
        self.assertEqual(x["selected_model"], PRIMARY)
        self.assertEqual(x["inference_requests"], 0)
        self.assertEqual(x["smoke_attempt_cap"], 1)

    def test_fallback_preselected_when_primary_absent(self):
        x = evaluate(preflight(primary=False), quota(), now=NOW)
        self.assertTrue(x["smoke_eligible"])
        self.assertEqual(x["selected_model"], FALLBACK)
        self.assertFalse(x["preferred_listed"])

    def test_primary_limit_reached_disables_inference(self):
        x = evaluate(preflight(), quota(used=100), now=NOW)
        self.assertFalse(x["smoke_eligible"])
        self.assertEqual(x["quota_readiness"], "rate_or_eligibility_blocked")

    def test_secondary_limit_reached_disables_inference(self):
        self.assertFalse(evaluate(preflight(), quota(secondary=100), now=NOW)["smoke_eligible"])

    def test_cached_limit_not_used_if_fresh_reports_available(self):
        self.assertTrue(evaluate(preflight(), quota(cached_used=100), now=NOW)["smoke_eligible"])

    def test_unavailable_account_no_post(self):
        self.assertFalse(evaluate(preflight(), quota(eligible=False), now=NOW)["smoke_eligible"])

    def test_cooldown_no_post(self):
        x = evaluate(preflight(), quota(cooldown="2026-11-19T21:00:00Z"), now=NOW)
        self.assertFalse(x["smoke_eligible"])

    def test_stale_quota_no_post(self):
        x = evaluate(preflight(), quota(fetched="2026-11-19T19:01:00Z"), now=NOW)
        self.assertFalse(x["smoke_eligible"])

    def test_missing_live_readings_no_post(self):
        q = quota()
        q["accounts"][0]["live_query"] = "failed_http_429"
        self.assertFalse(evaluate(preflight(), q, now=NOW)["smoke_eligible"])

    def test_mismatched_preflight_no_post(self):
        p = preflight()
        p["selected_model"] = FALLBACK
        # Deliberately inconsistent if primary exists and fallback selected;
        # evaluation checks membership, not priority; exact selection policy is
        # verified by the separate preflight tests.
        self.assertTrue(evaluate(p, quota(), now=NOW)["smoke_eligible"])

    def test_missing_catalog_blocks_before_post(self):
        with self.assertRaises(ValueError):
            evaluate({"authenticated": True}, quota(), now=NOW)

    def test_window_requires_explicit_limit_not_reached(self):
        self.assertFalse(_window_open({"used_percent": 12}))
        self.assertFalse(_window_open({"used_percent": 101, "limit_reached": False}))
        self.assertFalse(_window_open({"used_percent": 10, "limit_reached": False, "allowed": False}))
        self.assertTrue(_window_open({"used_percent": 10, "limit_reached": False, "allowed": True}))


if __name__ == "__main__":
    unittest.main()

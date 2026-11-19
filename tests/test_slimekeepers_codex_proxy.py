"""Testes sem conexão, token real ou consumo de inferência."""
import json
import os
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from proxy_preflight import PreflightError, probe
from slimekeepers_codex_proxy import (
    ProxyTextError, generate_text, ping, selected_model,
)

KEY = "unit-test-only-proxy-key-1234567"
BASE = "http://127.0.0.1:18080"
GATES = {
    "AI_ENABLED": "true",
    "PAID_CALLS_ENABLED": "true",
    "CODEX_PROXY_TEXT_AUTHORIZED": "true",
    "GITHUB_RUN_ATTEMPT": "1",
}


class Response:
    def __init__(self, value):
        self.raw = json.dumps(value).encode("utf-8")

    def __enter__(self):
        return self

    def __exit__(self, *args):
        return False

    def read(self, length):
        return self.raw[:length]


class Catalog:
    def __init__(self, models, response_model=None):
        self.models = models
        self.post_model = response_model
        self.methods = []
        self.bodies = []

    def open(self, request, timeout):
        self.methods.append(request.get_method())
        if request.get_method() == "GET":
            if request.full_url.endswith("/health"):
                return Response({"status": "ok", "accounts": 1})
            if request.full_url.endswith("/v1/models"):
                return Response({"data": [{"id": m} for m in self.models]})
            raise AssertionError("GET desconhecido")
        if request.get_method() == "POST":
            self.bodies.append(json.loads(request.data))
            return Response({
                "model": self.post_model or self.bodies[-1]["model"],
                "output": [{"type": "message", "content": [
                    {"type": "output_text", "text": "SLIMEKEEPERS_PROXY_OK"}]}],
                "usage": {"input_tokens": 15, "output_tokens": 6},
            })
        raise AssertionError("Método inesperado")


class ProxyTests(unittest.TestCase):
    def preflight(self, models, fake=None):
        fake = fake or Catalog(models)
        r = probe(BASE, KEY, opener=fake,
                  prefer_model="gpt-6.2-astra", fallback_model="gpt-6-astra")
        return r, fake

    def test_prefers_gpt62_from_actual_catalog(self):
        report, fake = self.preflight(["gpt-6-astra", "gpt-6.2-astra"])
        self.assertEqual(selected_model(report), "gpt-6.2-astra")
        self.assertEqual(fake.methods, ["GET", "GET"])

    def test_fallback_only_before_post_if_primary_absent(self):
        report, fake = self.preflight(["gpt-6-astra"])
        self.assertEqual(selected_model(report), "gpt-6-astra")
        with patch.dict(os.environ, GATES):
            value = ping(report, base_url=BASE, api_key=KEY, opener=fake)
        self.assertTrue(value["response_contract_verified"])
        self.assertEqual(fake.methods, ["GET", "GET", "POST"])
        self.assertEqual(fake.bodies[0]["model"], "gpt-6-astra")
        self.assertEqual(value["inference_requests"], 1)

    def test_blocks_if_both_models_missing(self):
        fake = Catalog(["gpt-image-2"])
        with self.assertRaises(PreflightError):
            self.preflight(["gpt-image-2"], fake)
        self.assertEqual(fake.methods, ["GET", "GET"])

    def test_real_ping_checks_selected_model(self):
        report, fake = self.preflight(["gpt-6.2-astra", "gpt-6-astra"])
        with patch.dict(os.environ, GATES):
            result = ping(report, base_url=BASE, api_key=KEY, opener=fake)
        self.assertEqual(result["model"], "gpt-6.2-astra")
        self.assertEqual(result["usage"]["output_tokens"], 6)
        self.assertEqual(len(fake.bodies), 1)
        self.assertFalse(fake.bodies[0]["store"])

    def test_closed_gates_cannot_call_post(self):
        fake = Catalog(["gpt-6.2-astra"])
        with patch.dict(os.environ, {"AI_ENABLED": "false",
                                      "PAID_CALLS_ENABLED": "false",
                                      "CODEX_PROXY_TEXT_AUTHORIZED": "false"}):
            with self.assertRaises(ProxyTextError):
                generate_text(BASE, KEY, "gpt-6.2-astra",
                              instructions="test", prompt="test", opener=fake)
        self.assertEqual(fake.methods, [])

    def test_rerun_blocked(self):
        fake = Catalog(["gpt-6.2-astra"])
        with patch.dict(os.environ, {**GATES, "GITHUB_RUN_ATTEMPT": "2"}):
            with self.assertRaises(ProxyTextError):
                generate_text(BASE, KEY, "gpt-6.2-astra",
                              instructions="test", prompt="test", opener=fake)
        self.assertEqual(fake.methods, [])

    def test_different_response_model_rejected_without_retry(self):
        report, fake = self.preflight(["gpt-6.2-astra"])
        fake.post_model = "gpt-6-astra"
        with patch.dict(os.environ, GATES):
            with self.assertRaisesRegex(ProxyTextError, "diverge"):
                ping(report, base_url=BASE, api_key=KEY, opener=fake)
        self.assertEqual(fake.methods, ["GET", "GET", "POST"])

    def test_requires_preflight(self):
        with self.assertRaises(ProxyTextError):
            selected_model({"authenticated": False, "selected_model": "gpt-6.2-astra"})

    def test_preflight_rejects_insecure_remote_origin(self):
        fake = Catalog(["gpt-6.2-astra"])
        with self.assertRaises(PreflightError):
            probe("http://example.com", KEY, opener=fake,
                  prefer_model="gpt-6.2-astra", fallback_model="gpt-6-astra")
        self.assertEqual(fake.methods, [])


if __name__ == "__main__":
    unittest.main()

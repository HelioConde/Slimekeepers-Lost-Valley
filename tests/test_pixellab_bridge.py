"""Testes locais: sem rede e sem geração de imagens."""
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from pixellab_bridge import inventory, export_existing
from pixellab_client import PixelLabClient, PixelLabError


class StubClient:
    def __init__(self):
        self.calls = []

    def characters(self):
        self.calls.append("GET characters")
        return {"characters": [{"id": "opaque"}], "total": 1}

    def character(self, ident):
        self.calls.append("GET character")
        return {"status": "completed"}

    def download(self, ident, *, spritesheet):
        self.calls.append("GET download")
        return b"PK\\x03\\x04" + b"asset"


class BridgeTests(unittest.TestCase):
    def test_inventory_is_read_only(self):
        stub = StubClient()
        self.assertEqual(inventory(stub)["characters"], 1)
        self.assertEqual(stub.calls, ["GET characters"])

    def test_incomplete_pagination_is_rejected(self):
        stub = StubClient()
        stub.characters = lambda: {"characters": [], "total": 2}
        with self.assertRaises(PixelLabError):
            inventory(stub)

    def test_export_rejects_invalid_id_without_api(self):
        stub = StubClient()
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(PixelLabError):
                export_existing(stub, "not-a-uuid", Path(tmp))
        self.assertFalse(stub.calls)

    def test_export_downloads_existing_only(self):
        stub = StubClient()
        with tempfile.TemporaryDirectory() as tmp:
            result = export_existing(stub, "123e4567-e89b-12d3-a456-426614174000", Path(tmp))
            self.assertEqual(result["status"], "exported")
            self.assertEqual(stub.calls, ["GET character", "GET download", "GET download"])
            self.assertTrue((Path(tmp) / "spritesheet.zip").is_file())

    def test_token_missing_is_rejected(self):
        with self.assertRaises(PixelLabError):
            PixelLabClient("")


if __name__ == "__main__":
    unittest.main()

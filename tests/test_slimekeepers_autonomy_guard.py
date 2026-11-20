"""Autonomous Godot change guard tests: offline, no proxy or files overwritten."""
import sys
from pathlib import Path
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import slimekeepers_autonomy_guard as guard
from slimekeepers_dev_agent import DevTaskError


def task():
    return {"allowed_files": ["scripts/systems/example_rules.gd",
                              "tests/forest/test_example_rules.gd"]}


def files():
    return {
        "scripts/systems/example_rules.gd": (
            "extends RefCounted\n\nfunc matches(value: String) -> bool:\n\treturn not value.is_empty()\n"
        ),
        "tests/forest/test_example_rules.gd": (
            "extends GdUnitTestSuite\n"
            "func test_one() -> void:\n\tassert_bool(true).is_true()\n"
            "func test_two() -> void:\n\tassert_int(1).is_equal(1)\n"
            "func test_three() -> void:\n\tassert_str('hi').is_equal('hi')\n"
            "func test_four() -> void:\n\tassert_bool(false).is_false()\n"
        ),
    }


class GuardTests(unittest.TestCase):
    def test_valid_additive_module(self):
        guard.validate_changes(task(), [("A", f) for f in task()["allowed_files"]], files())

    def test_no_overwrite_existing_file(self):
        with self.assertRaises(DevTaskError):
            guard.validate_changes(task(), [("M", f) for f in task()["allowed_files"]], files())

    def test_no_outside_file_changes(self):
        with self.assertRaises(DevTaskError):
            guard.validate_changes(task(), [("A", f) for f in task()["allowed_files"]]
                                   + [("A", ".github/workflows/unsafe.yml")], files())

    def test_no_missing_file(self):
        with self.assertRaises(DevTaskError):
            guard.validate_changes(task(), [("A", f) for f in task()["allowed_files"]],
                                   {next(iter(files())): next(iter(files().values()))})

    def test_no_network_in_generated_file(self):
        with self.assertRaises(DevTaskError):
            guard.validate_source("scripts/systems/example.gd",
                                  "extends RefCounted\nvar requester = HTTPRequest.new()\n")

    def test_portuguese_comment_ending_os_does_not_trigger_os_api(self):
        guard.validate_source("scripts/systems/example.gd",
                              "extends RefCounted\n## IDs conhecidos.\nfunc valid() -> bool:\n\treturn true\n")

    def test_real_os_singleton_remains_forbidden(self):
        with self.assertRaises(DevTaskError):
            guard.validate_source("scripts/systems/example.gd",
                                  "extends RefCounted\nfunc dangerous():\n\tOS.execute('bad', [])\n")

    def test_no_file_access_in_generated_file(self):
        with self.assertRaises(DevTaskError):
            guard.validate_source("scripts/systems/example.gd",
                                  "extends RefCounted\nvar io = FileAccess.open('user://data', 1)\n")

    def test_no_editor_tool_execution(self):
        with self.assertRaises(DevTaskError):
            guard.validate_source("scripts/systems/example.gd",
                                  "@tool\nextends RefCounted\nfunc test(): pass")

    def test_no_trivial_suite_with_one_assert(self):
        with self.assertRaises(DevTaskError):
            guard.validate_source("tests/forest/test_example.gd",
                                  "extends GdUnitTestSuite\nfunc test_true():\n\tassert_bool(true).is_true()\n")

    def test_no_duplicate_test_names(self):
        bad = files()["tests/forest/test_example_rules.gd"].replace("test_two", "test_one")
        with self.assertRaises(DevTaskError):
            guard.validate_source("tests/forest/test_example_rules.gd", bad)

    def test_detects_script_too_large(self):
        with self.assertRaises(DevTaskError):
            guard.validate_source("scripts/systems/example.gd",
                                  "extends RefCounted\nfunc f():\n\tpass\n" + " " * 19000)


if __name__ == "__main__":
    unittest.main()

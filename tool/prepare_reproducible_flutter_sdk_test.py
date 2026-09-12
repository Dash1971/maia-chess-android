import subprocess
import tempfile
from pathlib import Path
import unittest
from unittest.mock import patch

from prepare_reproducible_flutter_sdk import (
    PATCHED,
    PINNED_FLUTTER_REVISION,
    UNPATCHED,
    invalidate_flutter_tool_snapshot,
    patch_asset_tool,
    verify_flutter_revision,
)


class ReproducibleFlutterSdkTest(unittest.TestCase):
    def test_patch_sorts_variants_and_is_idempotent(self):
        with tempfile.TemporaryDirectory() as directory:
            asset_tool = Path(directory) / "asset.dart"
            asset_tool.write_text(f"before\n{UNPATCHED}\nafter\n")
            self.assertTrue(patch_asset_tool(asset_tool))
            self.assertEqual(asset_tool.read_text(), f"before\n{PATCHED}\nafter\n")
            self.assertFalse(patch_asset_tool(asset_tool))

    def test_patch_refuses_unexpected_or_ambiguous_source(self):
        with tempfile.TemporaryDirectory() as directory:
            asset_tool = Path(directory) / "asset.dart"
            for source in ("unrelated", f"{UNPATCHED}\n{UNPATCHED}"):
                asset_tool.write_text(source)
                with self.assertRaisesRegex(ValueError, "unexpected Flutter"):
                    patch_asset_tool(asset_tool)

    def test_snapshot_invalidation_removes_old_and_current_cache_files(self):
        with tempfile.TemporaryDirectory() as directory:
            flutter_root = Path(directory)
            cache = flutter_root / "bin/cache"
            cache.mkdir(parents=True)
            expected = {
                Path("bin/cache/flutter_tools.snapshot"),
                Path("bin/cache/flutter_tools.snapshot.old"),
                Path("bin/cache/flutter_tools.stamp"),
            }
            for path in expected:
                (flutter_root / path).write_text("cached")
            self.assertEqual(set(invalidate_flutter_tool_snapshot(flutter_root)), expected)
            self.assertEqual(invalidate_flutter_tool_snapshot(flutter_root), [])
            self.assertFalse(any((flutter_root / path).exists() for path in expected))

    @patch("prepare_reproducible_flutter_sdk.subprocess.run")
    def test_revision_guard(self, run):
        run.return_value = subprocess.CompletedProcess([], 0, PINNED_FLUTTER_REVISION + "\n", "")
        verify_flutter_revision(Path("/flutter"))
        run.return_value = subprocess.CompletedProcess([], 0, "wrong\n", "")
        with self.assertRaisesRegex(ValueError, "Refusing to patch Flutter"):
            verify_flutter_revision(Path("/flutter"))


if __name__ == "__main__":
    unittest.main()

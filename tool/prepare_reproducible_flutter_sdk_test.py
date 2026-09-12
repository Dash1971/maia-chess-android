import subprocess
import tempfile
from pathlib import Path
import unittest
from unittest.mock import patch

from prepare_reproducible_flutter_sdk import (
    PATCHED,
    PINNED_FLUTTER_REVISION,
    UNPATCHED,
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

    @patch("prepare_reproducible_flutter_sdk.subprocess.run")
    def test_revision_guard(self, run):
        run.return_value = subprocess.CompletedProcess([], 0, PINNED_FLUTTER_REVISION + "\n", "")
        verify_flutter_revision(Path("/flutter"))
        run.return_value = subprocess.CompletedProcess([], 0, "wrong\n", "")
        with self.assertRaisesRegex(ValueError, "Refusing to patch Flutter"):
            verify_flutter_revision(Path("/flutter"))


if __name__ == "__main__":
    unittest.main()

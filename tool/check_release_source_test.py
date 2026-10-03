import subprocess
import tempfile
import unittest
from pathlib import Path

from check_release_source import check_release_source


class ReleaseSourceGateTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        (self.root / "pubspec.yaml").write_text("version: 2.2.1+78\n", encoding="utf-8")
        changelogs = self.root / "fastlane/metadata/android/en-US/changelogs"
        changelogs.mkdir(parents=True)
        (changelogs / "78.txt").write_text("Mobile Maia 2.2.1 maintenance release.\n", encoding="utf-8")
        subprocess.run(["git", "-C", str(self.root), "add", "-A"], check=True)

    def test_clean_source_passes(self):
        self.assertEqual([], check_release_source(self.root))

    def test_missing_version_changelog_fails(self):
        (self.root / "fastlane/metadata/android/en-US/changelogs/78.txt").unlink()
        self.assertIn("missing Fastlane changelog", "\n".join(check_release_source(self.root)))

    def test_tracked_research_zip_fails_even_outside_app(self):
        archive = self.root / "docs/research/reproduction.zip"
        archive.parent.mkdir(parents=True)
        archive.write_bytes(b"PK\x03\x04")
        subprocess.run(["git", "-C", str(self.root), "add", str(archive)], check=True)
        self.assertIn(str(archive.relative_to(self.root)), "\n".join(check_release_source(self.root)))

    def test_changelog_cannot_describe_older_version(self):
        (self.root / "fastlane/metadata/android/en-US/changelogs/78.txt").write_text(
            "Mobile Maia 2.2.0 notes.\n", encoding="utf-8"
        )
        self.assertIn("must identify version 2.2.1", "\n".join(check_release_source(self.root)))


if __name__ == "__main__":
    unittest.main()

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
        listing = changelogs.parent
        for name in ("title.txt", "short_description.txt", "full_description.txt"):
            (listing / name).write_text("Mobile Maia", encoding="utf-8")
        screenshots = listing / "images/phoneScreenshots"
        screenshots.mkdir(parents=True)
        (screenshots / "1.png").write_bytes(b"screenshot fixture")
        self.git("add", "-A")

    def git(self, *args):
        return subprocess.check_output(["git", "-C", str(self.root), *args], stderr=subprocess.PIPE).decode().strip()

    def commit(self):
        self.git("add", "-A")
        self.git("-c", "user.name=Test", "-c", "user.email=test@example.com",
                 "commit", "-qm", "fixture")
        return self.git("rev-parse", "HEAD")

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

    def test_valid_commit_and_tag_pass(self):
        commit = self.commit()
        self.git("tag", "release")
        self.assertEqual([], check_release_source(self.root, commit))
        self.assertEqual([], check_release_source(self.root, "release"))

    def test_old_commit_missing_changelog_cannot_use_working_tree_fix(self):
        changelog = self.root / "fastlane/metadata/android/en-US/changelogs/78.txt"
        changelog.unlink()
        commit = self.commit()
        changelog.write_text("Mobile Maia 2.2.1 fixed", encoding="utf-8")
        self.assertEqual([], check_release_source(self.root))
        self.assertIn("missing Fastlane changelog", "\n".join(check_release_source(self.root, commit)))

    def test_committed_archive_fails_after_working_tree_removal(self):
        archive = self.root / "reproduction.zip"
        archive.write_bytes(b"PK")
        commit = self.commit()
        archive.unlink()
        self.git("add", "-A")
        self.assertEqual([], check_release_source(self.root))
        self.assertIn("reproduction.zip", "\n".join(check_release_source(self.root, commit)))

    def test_ref_ignores_dirty_pubspec_and_metadata(self):
        commit = self.commit()
        (self.root / "pubspec.yaml").write_text("version: 9.9.9+999", encoding="utf-8")
        (self.root / "fastlane/metadata/android/en-US/title.txt").unlink()
        self.assertEqual([], check_release_source(self.root, commit))

    def test_invalid_ref_fails(self):
        self.assertIn("cannot read Git release source", "\n".join(check_release_source(self.root, "no-such-ref")))

    def test_missing_metadata_fails_in_both_modes(self):
        for name in ("title.txt", "short_description.txt", "full_description.txt"):
            (self.root / "fastlane/metadata/android/en-US" / name).unlink()
        commit = self.commit()
        for ref in (None, commit):
            errors = "\n".join(check_release_source(self.root, ref))
            for name in ("title.txt", "short_description.txt", "full_description.txt"):
                self.assertIn("missing Fastlane metadata: fastlane/metadata/android/en-US/" + name, errors)

    def test_oversize_and_empty_metadata_fail(self):
        for name, limit in (("title.txt", 50), ("short_description.txt", 80), ("full_description.txt", 4000)):
            with self.subTest(name=name):
                path = self.root / "fastlane/metadata/android/en-US" / name
                for content in ("x" * (limit + 1), " "):
                    path.write_text(content, encoding="utf-8")
                    commit = self.commit()
                    for ref in (None, commit):
                        self.assertIn(f"{name} must contain 1–{limit} characters", "\n".join(check_release_source(self.root, ref)))
                path.write_text("x" * limit, encoding="utf-8")
                self.assertEqual([], check_release_source(self.root))

    def test_untracked_screenshot_cannot_satisfy_gate(self):
        self.git("rm", "--cached", "fastlane/metadata/android/en-US/images/phoneScreenshots/1.png")
        self.assertIn("missing tracked Fastlane screenshot", "\n".join(check_release_source(self.root)))
        commit = self.commit()
        self.git("rm", "fastlane/metadata/android/en-US/images/phoneScreenshots/1.png")
        commit = self.commit()
        (self.root / "fastlane/metadata/android/en-US/images/phoneScreenshots").mkdir(parents=True, exist_ok=True)
        (self.root / "fastlane/metadata/android/en-US/images/phoneScreenshots/1.png").write_bytes(b"fixture")
        self.assertIn("missing tracked Fastlane screenshot", "\n".join(check_release_source(self.root, commit)))


if __name__ == "__main__":
    unittest.main()

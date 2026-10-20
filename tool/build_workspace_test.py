import argparse
import contextlib
import io
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

import build_workspace as workspace


class BuildWorkspaceTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.repo = self.root / 'source'
        self.repo.mkdir()
        self.git('init', '-q')
        (self.repo / 'source.txt').write_text('preserve source')
        self.git('add', 'source.txt')
        self.git('-c', 'user.name=Test', '-c', 'user.email=test@example.invalid',
                 'commit', '-qm', 'fixture')
        self.bulk = self.root / 'results/bulk'
        self.evidence = self.root / 'results/evidence.json'
        self.report = self.root / 'results/cleanup.json'
        (self.repo / 'build').mkdir()
        (self.repo / 'build/output.apk').write_text('apk fixture')

    def git(self, *args):
        return subprocess.check_output(['git', '-C', str(self.repo), *args],
                                       stderr=subprocess.STDOUT)

    def run_clean(self, **kwargs):
        args = dict(scratch=None, apply=False, builds_stopped=False,
                    publication_verified=False, abandoned=False,
                    evidence=None, report=None)
        args.update(kwargs)
        with contextlib.redirect_stdout(io.StringIO()):
            workspace.clean(self.repo, argparse.Namespace(**args))

    def init_bulk(self):
        with contextlib.redirect_stdout(io.StringIO()):
            workspace.init_scratch(self.repo, self.bulk)

    def apply(self, **kwargs):
        args = dict(apply=True, builds_stopped=True, publication_verified=True,
                    evidence=self.evidence, report=self.report)
        args.update(kwargs)
        self.run_clean(**args)

    def test_dry_run_preserves_build_and_source(self):
        self.run_clean()
        self.assertTrue((self.repo / 'build/output.apk').exists())
        self.assertTrue((self.repo / 'source.txt').exists())
        self.assertFalse(self.report.exists())

    def test_apply_removes_only_generated_and_owned_bulk_retains_evidence(self):
        self.init_bulk()
        (self.bulk / 'signed.apk').write_text('signed fixture')
        self.evidence.write_text('{"published_apk_verified": true}')
        shared = self.root / 'shared-sdk'
        shared.mkdir()
        (shared / 'keep').write_text('toolchain')
        model = self.repo / 'assets/models/maia3-79m.onnx'
        model.parent.mkdir(parents=True)
        model.write_text('model fixture')
        self.apply(scratch=self.bulk)
        self.assertFalse((self.repo / 'build').exists())
        self.assertFalse(self.bulk.exists())
        for path in (self.repo / 'source.txt', self.repo / '.git',
                     self.evidence, shared / 'keep', model):
            self.assertTrue(path.exists(), path)
        report = json.loads(self.report.read_text())
        self.assertEqual(report['reason'], 'published')
        self.assertEqual(len(report['removed']), 2)
        self.assertIn('free_bytes_after', report)
        self.assertEqual(len(report['evidence_sha256']), 64)

    def test_apply_requires_stopped_builds_completion_reason_and_evidence(self):
        for args in ({'apply': True},
                     {'apply': True, 'builds_stopped': True},
                     {'apply': True, 'builds_stopped': True, 'abandoned': True}):
            with self.subTest(args=args), self.assertRaises(ValueError):
                self.run_clean(**args)
            self.assertTrue((self.repo / 'build/output.apk').exists())

    def test_abandoned_build_can_be_cleaned_with_retained_diagnostics(self):
        self.evidence.parent.mkdir(parents=True)
        self.evidence.write_text('Build failed; retained diagnostic summary.')
        self.apply(publication_verified=False, abandoned=True)
        self.assertEqual(json.loads(self.report.read_text())['reason'], 'abandoned')

    def test_tracked_file_blocks_all_deletion(self):
        self.git('add', 'build/output.apk')
        with self.assertRaisesRegex(ValueError, 'tracked files'):
            workspace.cleanup_plan(self.repo)
        self.assertTrue((self.repo / 'build/output.apk').exists())

    def test_keys_and_nested_checkouts_block_all_deletion(self):
        for name in ('signing.jks', 'key.properties', '.env.passwords', '.git'):
            with self.subTest(name=name):
                path = self.repo / 'build' / name
                path.write_text('must preserve')
                with self.assertRaises(ValueError):
                    workspace.cleanup_plan(self.repo)
                self.assertTrue((self.repo / 'build/output.apk').exists())
                path.unlink()

    def test_symlinked_cleanup_root_is_rejected(self):
        (self.repo / '.dart_tool').symlink_to(self.root / 'missing')
        with self.assertRaises(ValueError):
            workspace.cleanup_plan(self.repo)

    def test_virtualenv_links_are_unlinked_without_following_shared_targets(self):
        self.init_bulk()
        shared = self.root / 'shared-python'
        shared.mkdir()
        (shared / 'python').write_text('shared runtime')
        (self.bulk / 'python').symlink_to(shared / 'python')
        (self.bulk / 'lib64').symlink_to(shared, target_is_directory=True)
        self.evidence.write_text('verified publication')
        self.apply(scratch=self.bulk)
        self.assertFalse(self.bulk.exists())
        self.assertEqual((shared / 'python').read_text(), 'shared runtime')

    def test_existing_or_inside_checkout_scratch_cannot_be_adopted(self):
        with self.assertRaises(ValueError):
            workspace.init_scratch(self.repo, self.repo / 'build')
        self.bulk.mkdir(parents=True)
        with self.assertRaises(FileExistsError):
            workspace.init_scratch(self.repo, self.bulk)

    def test_unmarked_wrong_checkout_and_moved_scratch_are_rejected(self):
        self.bulk.mkdir(parents=True)
        with self.assertRaises(FileNotFoundError):
            workspace.cleanup_plan(self.repo, self.bulk)
        self.bulk.rmdir()
        self.init_bulk()
        moved = self.bulk.with_name('moved')
        self.bulk.rename(moved)
        with self.assertRaisesRegex(ValueError, 'ownership'):
            workspace.cleanup_plan(self.repo, moved)
        marker = json.loads((moved / workspace.MARKER).read_text())
        marker.update(scratch=str(moved), repo=str(self.root / 'other'))
        (moved / workspace.MARKER).write_text(json.dumps(marker))
        with self.assertRaisesRegex(ValueError, 'ownership'):
            workspace.cleanup_plan(self.repo, moved)

    def test_evidence_cannot_be_deleted_or_overwritten(self):
        self.evidence.parent.mkdir(parents=True)
        self.evidence.write_text('retained evidence')
        for args in ({'evidence': self.repo / 'build/output.apk'},
                     {'report': self.repo / 'build/cleanup.json'},
                     {'report': self.evidence}):
            with self.subTest(args=args), self.assertRaises(ValueError):
                self.apply(**args)
            self.assertTrue((self.repo / 'build/output.apk').exists())
        self.assertEqual(self.evidence.read_text(), 'retained evidence')

    def test_macos_builds_need_no_opt_in_and_disk_thresholds_still_apply(self):
        disk = argparse.Namespace(free=30 * workspace.GIB)
        with patch.object(workspace.platform, 'system', return_value='Darwin'), \
                patch.dict(workspace.os.environ, {}, clear=True), \
                patch.object(workspace.shutil, 'disk_usage', return_value=disk):
            # A supported Mac build passes with no opt-in environment setting.
            with contextlib.redirect_stdout(io.StringIO()):
                workspace.preflight(self.repo)
            disk.free = 24 * workspace.GIB
            with self.assertRaisesRegex(ValueError, '25 GiB'):
                workspace.preflight(self.repo)
            disk.free = 25 * workspace.GIB
            with contextlib.redirect_stdout(io.StringIO()):
                workspace.preflight(self.repo)
        with patch.object(workspace.platform, 'system', return_value='Linux'), \
                patch.object(workspace.shutil, 'disk_usage', return_value=disk):
            disk.free = 9 * workspace.GIB
            with self.assertRaisesRegex(ValueError, '10 GiB'):
                workspace.preflight(self.repo)
            disk.free = 10 * workspace.GIB
            with contextlib.redirect_stdout(io.StringIO()):
                workspace.preflight(self.repo)


if __name__ == '__main__':
    unittest.main()

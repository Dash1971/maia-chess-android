"""Small synthetic packages exercise the guard; no Android build or SDK needed."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch
import warnings
import zipfile

from check_board_style_assets import ROOT, check
from verify_release_apk import verify


class BoardStyleAssetsTest(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        self.package = self.root / 'third_party/chessground'
        self.asset = 'assets/piece_sets/cburnett/wK.png'
        self.data = b'approved artwork fixture'
        self.notice = b'licence fixture'
        self.write(self.asset, self.data)
        self.write('notices/COPYING.md', self.notice)
        self.write('pubspec.yaml', b'flutter:\n  assets:\n    - assets/piece_sets/cburnett/\n')
        self.manifest = {
            'approved_piece_sets': ['cburnett'],
            'excluded_piece_sets': {'horsey': 'Not approved'},
            'files': [{'path': self.asset,
                       'sha256': hashlib.sha256(self.data).hexdigest(),
                       'upstream_git_blob': hashlib.sha1(
                           b'blob ' + str(len(self.data)).encode() + b'\0' + self.data).hexdigest()}],
            'notice_files': {'COPYING.md': hashlib.sha256(self.notice).hexdigest()},
        }
        (self.root / 'docs').mkdir()
        self.save_manifest()
        self.apk = self.root / 'fixture.apk'
        self.asset_entry = 'assets/flutter_assets/packages/chessground/' + self.asset
        self.notice_entry = 'assets/flutter_assets/third_party/chessground/notices/COPYING.md'
        self.entries = {self.asset_entry: self.data, self.notice_entry: self.notice}

    def write(self, relative, data):
        path = self.package / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)

    def save_manifest(self):
        (self.root / 'docs/board-style-assets.json').write_text(json.dumps(self.manifest))

    def archive(self):
        with zipfile.ZipFile(self.apk, 'w') as out:
            for name, data in self.entries.items():
                out.writestr(name, data)
        return self.apk

    def test_committed_catalogue_is_approved(self):
        report = check()
        self.assertEqual(report['approved_piece_sets'], 16)
        self.assertEqual(report['excluded_piece_sets'], 24)

    def test_source_and_packaged_assets_and_notices_pass(self):
        report = check(self.archive(), root=self.root)
        self.assertEqual(report['asset_files'], 1)
        self.assertEqual(report['apk_asset_bytes'], len(self.data))

    def test_extra_restricted_piece_set_is_rejected(self):
        self.write('assets/piece_sets/horsey/wK.png', b'unapproved')
        with self.assertRaisesRegex(ValueError, 'Asset allowlist mismatch'):
            check(root=self.root)

    def test_modified_source_artwork_is_rejected(self):
        self.write(self.asset, b'replaced')
        with self.assertRaisesRegex(ValueError, 'Source hash mismatch'):
            check(root=self.root)

    def test_upstream_provenance_is_checked(self):
        self.manifest['files'][0]['upstream_git_blob'] = '0' * 40
        self.save_manifest()
        with self.assertRaisesRegex(ValueError, 'Upstream blob mismatch'):
            check(root=self.root)

    def test_duplicate_manifest_entry_is_rejected(self):
        self.manifest['files'].append(self.manifest['files'][0])
        self.save_manifest()
        with self.assertRaisesRegex(ValueError, 'Duplicate manifest path'):
            check(root=self.root)

    def test_excluded_pubspec_declaration_is_rejected(self):
        with (self.package / 'pubspec.yaml').open('a') as out:
            out.write('    - assets/piece_sets/horsey/\n')
        with self.assertRaisesRegex(ValueError, 'Excluded piece declaration'):
            check(root=self.root)

    def test_modified_source_notice_is_rejected(self):
        self.write('notices/COPYING.md', b'changed licence')
        with self.assertRaisesRegex(ValueError, 'Notice hash mismatch'):
            check(root=self.root)

    def test_missing_or_extra_apk_artwork_is_rejected(self):
        original = dict(self.entries)
        for change in ['missing', 'extra']:
            with self.subTest(change=change):
                self.entries = dict(original)
                if change == 'missing':
                    del self.entries[self.asset_entry]
                else:
                    self.entries[self.asset_entry.replace('cburnett', 'horsey')] = b'extra'
                with self.assertRaisesRegex(ValueError, 'APK assets differ from allowlist'):
                    check(self.archive(), root=self.root)

    def test_modified_apk_artwork_is_rejected(self):
        self.entries[self.asset_entry] = b'changed'
        with self.assertRaisesRegex(ValueError, 'APK asset hash mismatch'):
            check(self.archive(), root=self.root)

    def test_missing_or_changed_apk_notices_are_rejected(self):
        for content in [None, b'changed']:
            with self.subTest(content=content):
                if content is None:
                    self.entries.pop(self.notice_entry, None)
                else:
                    self.entries[self.notice_entry] = content
                with self.assertRaisesRegex(ValueError, 'APK (missing licence notice|notice hash mismatch)'):
                    check(self.archive(), root=self.root)

    def test_duplicate_apk_entries_are_rejected(self):
        self.archive()
        with warnings.catch_warnings():
            warnings.simplefilter('ignore', UserWarning)
            with zipfile.ZipFile(self.apk, 'a') as out:
                out.writestr(self.asset_entry, b'duplicate')
        with self.assertRaisesRegex(ValueError, 'duplicate ZIP entries'):
            check(self.apk, root=self.root)

    def test_python_optimization_cannot_disable_the_gate(self):
        self.write(self.asset, b'unapproved replacement')
        code = 'from pathlib import Path; from check_board_style_assets import check; import sys; check(root=Path(sys.argv[1]))'
        result = subprocess.run([sys.executable, '-O', '-c', code, str(self.root)],
                                cwd=ROOT / 'tool', capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Source hash mismatch', result.stderr)

    def test_release_verification_cannot_skip_failed_artwork_gate(self):
        with patch('verify_release_apk.check_board_style_assets',
                   side_effect=ValueError('unapproved artwork')) as guard, \
                patch('verify_release_apk.sdk_tools') as sdk:
            with self.assertRaisesRegex(ValueError, 'unapproved artwork'):
                verify(SimpleNamespace(apk=self.apk))
            guard.assert_called_once_with(self.apk)
            sdk.assert_not_called()


if __name__ == '__main__':
    unittest.main()

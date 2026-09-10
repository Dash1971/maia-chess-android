import copy
import io
import struct
import unittest
from unittest.mock import Mock
import zipfile

from verify_release_apk import compare_payloads, elf_alignment, payload_names
from verify_release_upgrade import (check_baseline, check_restored, emulator_preflight,
                                    restored_ui_ready, seed_record)


def archive(files):
    stream = io.BytesIO()
    with zipfile.ZipFile(stream, 'w') as package:
        for name, content in files.items():
            package.writestr(name, content)
    return zipfile.ZipFile(io.BytesIO(stream.getvalue()))


class ArtifactChecksTest(unittest.TestCase):
    def test_payload_comparison_ignores_signatures_but_not_added_removed_or_changed_code(self):
        with archive({'lib/app.so': b'old', 'asset': b'same'}) as baseline:
            with archive({'lib/app.so': b'new', 'asset': b'same', 'META-INF/CERT.RSA': b'signature'}) as candidate:
                with self.assertRaisesRegex(ValueError, 'Unexpected APK payload changes'):
                    compare_payloads(candidate, baseline, [])
                self.assertEqual(compare_payloads(candidate, baseline, ['lib/app.so']), ['lib/app.so'])
            for files in ({'lib/app.so': b'old'}, {'lib/app.so': b'old', 'asset': b'same', 'extra': b'data'}):
                with archive(files) as candidate:
                    with self.assertRaisesRegex(ValueError, 'Unexpected APK payload changes'):
                        compare_payloads(candidate, baseline, ['lib/app.so'])

    def test_non_signature_metadata_remains_part_of_comparison(self):
        self.assertEqual(payload_names(['META-INF/MANIFEST.MF', 'META-INF/CERT.SF',
                                        'META-INF/services/plugin', 'lib/app.so']),
                         {'META-INF/services/plugin', 'lib/app.so'})

    def test_native_alignment_rejects_wrong_abi_truncation_and_misaligned_segments(self):
        data = bytearray(120)
        data[:6] = b'\x7fELF\x02\x01'
        struct.pack_into('<H', data, 18, 183)
        struct.pack_into('<Q', data, 32, 64)
        struct.pack_into('<HH', data, 54, 56, 1)
        struct.pack_into('<I', data, 64, 1)
        struct.pack_into('<Q', data, 112, 16384)
        self.assertEqual(elf_alignment(data), [16384])
        corruptions = [data[:100]]
        for offset, format_, value in [(18, '<H', 62), (112, '<Q', 4096),
                                       (112, '<Q', 20000), (72, '<Q', 4096)]:
            broken = data.copy()
            struct.pack_into(format_, broken, offset, value)
            corruptions.append(broken)
        for broken in corruptions:
            with self.assertRaises(ValueError):
                elf_alignment(broken)


class UpgradeChecksTest(unittest.TestCase):
    def test_natural_result_checkpoint_and_result_dialog_readiness(self):
        fixture = seed_record('1. f3 e5 2. g4 Qh4# 0-1')
        baseline = copy.deepcopy(fixture)
        baseline['data']['forcedResult'] = None
        check_baseline(fixture, baseline)
        check_restored(baseline, copy.deepcopy(baseline))
        dialog = b'<hierarchy><node content-desc="Analysis Board"/></hierarchy>'
        self.assertTrue(restored_ui_ready(dialog, 700, True))
        self.assertFalse(restored_ui_ready(dialog, 700, False))
        self.assertFalse(restored_ui_ready(b'<hierarchy/>', 700, True))
        baseline['data']['pgn'] = '1. f3 e5 2. g4 Qh4# 1-0'
        with self.assertRaisesRegex(ValueError, 'game result'):
            check_baseline(fixture, baseline)

    def test_refuses_physical_devices_before_any_mutation(self):
        shell = Mock(return_value=b'0\n')
        with self.assertRaisesRegex(ValueError, 'physical device'):
            emulator_preflight(shell, True)
        shell.assert_called_once_with('getprop', 'ro.kernel.qemu')
        shell.reset_mock()
        with self.assertRaisesRegex(ValueError, 'allow-reset-test-app'):
            emulator_preflight(shell, False)
        shell.assert_not_called()

    def test_refuses_incomplete_boot_wrong_architecture_and_disabled_selinux(self):
        ready = {('getprop', 'ro.kernel.qemu'): b'1', ('getprop', 'ro.debuggable'): b'1',
                 ('getprop', 'ro.product.cpu.abi'): b'arm64-v8a',
                 ('getprop', 'sys.boot_completed'): b'1', ('getenforce',): b'Enforcing'}
        emulator_preflight(lambda *args: ready[args], True)
        for key, value in [(('getprop', 'sys.boot_completed'), b'0'),
                           (('getprop', 'ro.product.cpu.abi'), b'x86_64'),
                           (('getenforce',), b'Permissive')]:
            properties = {**ready, key: value}
            with self.assertRaises(ValueError):
                emulator_preflight(lambda *args: properties[args], True)

    def test_comparison_accepts_merged_notes_and_rejects_lost_notes_branches_or_clocks(self):
        before = seed_record('1. e4 (1. d4 {First note} $1 d5) '
                             '(1. d4 {Second note} $2 d5) e5 1-0')
        after = copy.deepcopy(before)
        after['data']['pgn'] = '1. e4 (1. d4 {First note} {Second note} $1 $2 d5) e5 1-0'
        result = check_restored(before, after)
        self.assertEqual(result['duplicate_lines_before'], 1)
        self.assertEqual(result['duplicate_lines_after'], 0)
        for bad in [before, seed_record('1. e4 e5 1-0')]:
            with self.assertRaises(ValueError):
                check_restored(before, bad)
        for old, new in [('Second note', 'Lost note'), ('$2', ''), ('d5)', 'Nf6)')]:
            broken = copy.deepcopy(after)
            broken['data']['pgn'] = broken['data']['pgn'].replace(old, new)
            with self.assertRaises(ValueError):
                check_restored(before, broken)
        broken = copy.deepcopy(after)
        broken['data']['clockHistory'][-1][0] -= 1
        with self.assertRaisesRegex(ValueError, 'clockHistory'):
            check_restored(before, broken)
        broken = copy.deepcopy(after)
        broken['data']['pgn'] = '1. d4 {First note} {Second note} $1 $2 (1. e4 e5) d5 1-0'
        with self.assertRaisesRegex(ValueError, 'played main line'):
            check_restored(before, broken)

    def test_starting_comments_are_preserved_on_their_variation(self):
        before = seed_record('1. e4 ({Alternative idea} 1. d4 d5) e5 1-0')
        after = copy.deepcopy(before)
        check_restored(before, after)
        after['data']['pgn'] = '1. e4 (1. d4 d5) e5 1-0'
        with self.assertRaisesRegex(ValueError, 'comment'):
            check_restored(before, after)

    def test_fixture_and_empty_or_unfinished_games_have_deterministic_snapshots(self):
        from verify_release_upgrade import FIXTURE
        record = seed_record(FIXTURE.read_text())
        self.assertEqual(len(record['data']['uciMoves']), 59)
        self.assertEqual(len(record['data']['clockHistory']), 60)
        self.assertEqual(seed_record(FIXTURE.read_text()), record)
        for pgn in ('*', '1. e4 *'):
            unfinished = seed_record(pgn)['data']
            self.assertNotIn('forcedResult', unfinished)
            self.assertTrue(unfinished['clockPaused'])
        with self.assertRaisesRegex(ValueError, 'single PGN'):
            seed_record('1. e4 *\n\n1. d4 *')


if __name__ == '__main__':
    unittest.main()

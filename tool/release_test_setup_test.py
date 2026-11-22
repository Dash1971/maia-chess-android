import importlib
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET

import android_release_ui as ui
import release_test_preflight as preflight


class ReleaseTestSetupTest(unittest.TestCase):
    def emulator(self, focus=None, avd='owned', boot=b'1', power=b'mWakefulness=Awake'):
        replies = {('emu', 'avd', 'name'): (avd + '\nOK\n').encode(),
                   ('shell', 'getprop', 'sys.boot_completed'): boot,
                   ('shell', 'dumpsys', 'power'): power,
                   ('shell', 'dumpsys', 'window'): (focus or 'mCurrentFocus=Window{ x app.id/Main}').encode()}
        return lambda *args: replies[args]

    def test_scratch_identity_is_required_and_source_paths_cannot_be_adopted(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve(); repo = root / 'source'; repo.mkdir()
            bulk = root / 'bulk'; bulk.mkdir()
            (bulk / preflight.MARKER).write_text(json.dumps({'repo': str(repo), 'scratch': str(bulk)}))
            with patch.object(preflight, 'REPO', repo):
                self.assertEqual(preflight.owned_scratch(bulk), bulk)
                (bulk / preflight.MARKER).write_text('{}')
                with self.assertRaises(ValueError): preflight.owned_scratch(bulk)
                with self.assertRaises(ValueError): preflight.owned_scratch(repo)
                with self.assertRaises(ValueError): preflight.owned_scratch(root)

    def test_foreground_app_and_owned_ready_emulator_pass(self):
        self.assertTrue(preflight.emulator_health(self.emulator(), 'owned', 'app.id')['awake'])

    def test_anr_wrong_device_sleep_boot_and_wrong_focus_fail_before_test(self):
        for command in [self.emulator(avd='someone-elses'), self.emulator(boot=b'0'),
                        self.emulator(power=b'mWakefulness=Asleep'),
                        self.emulator(focus='mCurrentFocus=null'),
                        self.emulator(focus='mCurrentFocus=Window{Application Not Responding: com.android.systemui}'),
                        self.emulator(focus='mCurrentFocus=Window{com.android.launcher/Main}')]:
            with self.subTest(command=command), self.assertRaises(ValueError):
                preflight.emulator_health(command, 'owned', 'app.id')

    def test_dependency_check_collects_missing_modules_and_signature_api(self):
        def load(name):
            if name in ['click', 'PIL.Image']:
                raise ImportError('missing')
            return object()
        with patch.object(importlib, 'import_module', side_effect=load), \
                patch.object(importlib.metadata, 'version', return_value='test'):
            _, errors = preflight.dependencies()
        self.assertEqual(len(errors), 3)
        self.assertTrue(any('do_copy' in error for error in errors))

    def test_capacity_keeps_disk_reserve_and_exposes_contention_without_killing_jobs(self):
        with tempfile.TemporaryDirectory() as directory, \
                patch.object(preflight.shutil, 'disk_usage', return_value=type('Disk', (), {'free': 40 * preflight.GIB})()), \
                patch.object(preflight.os, 'cpu_count', return_value=10), \
                patch.object(preflight.os, 'getloadavg', return_value=(68, 60, 50), create=True):
            self.assertTrue(preflight.capacity(Path(directory), 20)['warnings'])
            with self.assertRaises(ValueError):
                preflight.capacity(Path(directory), 31)

    def test_transient_invalid_snapshot_retried_but_repeated_errors_fail(self):
        values = iter([b'not XML', b'<hierarchy><node editable="true"/></hierarchy>'])
        ticks = iter(range(20))
        diagnostics = []
        self.assertEqual(ui.wait_snapshot(lambda: next(values), lambda root: True, timeout=10,
                                         clock=lambda: next(ticks), sleep=lambda _: None,
                                         diagnostic=diagnostics.append).tag, 'hierarchy')
        self.assertEqual(diagnostics, [b'not XML'])
        with self.assertRaisesRegex(ValueError, 'Repeated invalid'):
            ui.wait_snapshot(lambda: b'bad', lambda _: True, timeout=10,
                             clock=lambda: 0, sleep=lambda _: None)

    def test_transport_errors_are_not_silently_retried_and_wait_is_bounded(self):
        def broken():
            raise RuntimeError('adb failed')
        with self.assertRaisesRegex(RuntimeError, 'adb failed'):
            ui.wait_snapshot(broken, lambda _: True)
        ticks = iter(range(10))
        with self.assertRaises(TimeoutError):
            ui.wait_snapshot(lambda: b'<hierarchy/>', lambda _: False, timeout=3,
                             clock=lambda: next(ticks), sleep=lambda _: None)

    def test_editable_semantics_not_only_android_class_and_no_coordinate_guess(self):
        root = ET.fromstring('<hierarchy><node class="android.view.View" editable="true" '
                             'focused="true" bounds="[10,20][100,80]"/></hierarchy>')
        self.assertEqual(ui.text_field(root).get('class'), 'android.view.View')
        for raw in ['<hierarchy><node editable="true" bounds="[1,1][2,2]"/><node editable="true" bounds="[3,3][4,4]"/></hierarchy>', '<hierarchy/>', '<hierarchy><node editable="true" bounds="[0,0][0,0]"/></hierarchy>']:
            with self.assertRaises(ValueError):
                ui.text_field(ET.fromstring(raw))


if __name__ == '__main__':
    unittest.main()

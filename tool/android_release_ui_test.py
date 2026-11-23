import copy
import importlib.util
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

spec = importlib.util.spec_from_file_location('operator_ui', Path(__file__).with_name('android_release_ui.py'))
u = importlib.util.module_from_spec(spec)
spec.loader.exec_module(u)


def xml(*nodes, package='app'):
    root = ET.Element('hierarchy')
    window = ET.SubElement(root, 'node', {'bounds': '[0,0][412,892]', 'package': package})
    for attrs in nodes:
        ET.SubElement(window, 'node', dict({'bounds': '[16,120][300,170]', 'enabled': 'true', 'package': package}, **attrs))
    return ET.tostring(root)


class Clock:
    value = 0
    def now(self): return self.value
    def sleep(self, duration): self.value += duration


class LifecycleTests(unittest.TestCase):
    def run_stop(self, values, checkpoint=False, running=False):
        clock = Clock(); events = []; reads = iter(values)
        def read(): return next(reads, values[-1])
        result = u.normal_background_stop(read, lambda: checkpoint, lambda: running,
            lambda: events.append('background'), lambda: events.append('stop'),
            timeout=1, clock=clock.now, sleep=clock.sleep)
        return result, events

    def test_fresh_unlaunched_without_preferences_is_not_a_pending_restore(self):
        self.assertEqual(self.run_stop([None]), ('fresh-unlaunched', ['background', 'stop']))

    def test_missing_prefs_cannot_bypass_guard_for_an_existing_checkpoint(self):
        with self.assertRaises(ValueError): self.run_stop([None], checkpoint=True)

    def test_missing_prefs_cannot_bypass_guard_for_a_running_app(self):
        with self.assertRaises(ValueError): self.run_stop([None], running=True)

    def test_pending_restore_must_finish_before_forced_stop(self):
        pending = b'<map><string name="flutter.sessionRestorePendingV1">token</string></map>'
        self.assertEqual(self.run_stop([pending, pending, b'<map/>'])[1], ['background', 'stop'])

    def test_pending_timeout_never_stops_the_app(self):
        events = []; c = Clock()
        with self.assertRaises(TimeoutError):
            u.normal_background_stop(lambda: b'<map><string name="flutter.sessionRestorePendingV1">x</string></map>',
                lambda: True, lambda: True, lambda: None, lambda: events.append('stop'),
                timeout=1, clock=c.now, sleep=c.sleep)
        self.assertEqual(events, [])

    def test_blocked_restore_is_not_cleared_or_stopped(self):
        with self.assertRaises(ValueError): self.run_stop([b'<map><boolean name="flutter.sessionRestoreBlockedV1" value="true"/></map>'])

    def test_malformed_preferences_are_not_a_fresh_install(self):
        with self.assertRaises(ValueError): self.run_stop([b'cat: file missing'])


class UiTests(unittest.TestCase):
    def test_label_below_viewport_is_not_tapped(self):
        root = ET.fromstring(xml({'text': 'Save', 'bounds': '[16,930][300,970]'}, {'text': 'Save'}))
        self.assertEqual(u.visible_label(root, 'Save').get('bounds'), '[16,120][300,170]')

    def test_native_all_caps_can_be_matched_explicitly(self):
        self.assertEqual(u.visible_label(ET.fromstring(xml({'text': 'READ CLIPBOARD'})), 'Read clipboard', fold_case=True).get('text'), 'READ CLIPBOARD')

    def test_review_readiness_accepts_both_titles_and_requires_real_controls(self):
        for title in ('Analysis Board', 'Game review'):
            root = ET.fromstring(xml({'text': title}, {'text': 'Computer analysis'}, {'text': 'Share and export'}))
            self.assertTrue(u.has_controls(root, ['Computer analysis', 'Share and export'], package='app'))
        self.assertFalse(u.has_controls(ET.fromstring(xml({'text': 'Analysis Board'})), ['Computer analysis']))

    def test_missing_checkbox_metadata_is_a_failure_not_an_unchecked_box(self):
        with self.assertRaises(ValueError): u.checkbox_state(ET.fromstring(xml({'text': 'Include analysis'})), 'Include analysis')

    def test_checked_and_unchecked_are_distinct_observed_states(self):
        for state in (True, False):
            root = ET.fromstring(xml({'text': 'Include analysis', 'checkable': 'true', 'checked': str(state).lower()}))
            self.assertEqual(u.checkbox_state(root, 'Include analysis')[1], state)

    def test_sole_share_receiver_needs_no_destination_caption_or_extra_tap(self):
        events = []
        u.receive_share(lambda: xml({'text': 'Received'}, package='probe'), events.append,
            package='probe', label='Probe', receipt='Received')
        self.assertEqual(events, [])

    def test_real_chooser_is_selected_then_delivery_is_required(self):
        current = [xml({'text': 'Probe'}, package='android')]; clicks = []
        def select(node): clicks.append(node.get('text')); current[0] = xml({'text': 'Received'}, package='probe')
        u.receive_share(lambda: current[0], select, package='probe', label='Probe', receipt='Received')
        self.assertEqual(clicks, ['Probe'])

    def test_receiver_title_while_loading_is_not_a_chooser_item(self):
        states = iter([xml({'text': 'Probe'}, package='probe'), xml({'text': 'Received'}, package='probe')]); clicks = []; c = Clock()
        u.receive_share(lambda: next(states), clicks.append, package='probe', label='Probe', receipt='Received', clock=c.now, sleep=c.sleep)
        self.assertEqual(clicks, [])

    def test_receipt_in_another_package_is_not_delivery(self):
        c = Clock()
        with self.assertRaises(TimeoutError):
            u.receive_share(lambda: xml({'text': 'Received'}, package='wrong'), lambda n: self.fail('unexpected click'),
                package='probe', label='Probe', receipt='Received', timeout=1, clock=c.now, sleep=c.sleep)


class StorageContractTests(unittest.TestCase):
    def test_live_analysis_uses_checkpoint_and_archive_phase_uses_archive(self):
        active = {'id': 'game', 'data': {'session': {'pgn': 'new [%eval 0.3]'}}}
        archived = {'id': 'game', 'data': {'pgn': 'old'}}; before = copy.deepcopy((active, archived))
        self.assertIs(u.persisted_snapshot(active, [archived], 'game', phase='current'), active)
        self.assertIs(u.persisted_snapshot(active, [archived], 'game', phase='archive'), archived)
        self.assertEqual((active, archived), before)

    def test_home_tombstone_uses_the_existing_archive(self):
        archived = {'id': 'game', 'data': {'pgn': 'saved'}}
        self.assertIs(u.persisted_snapshot({'id': 'game', 'data': None}, [archived], 'game', phase='current'), archived)

    def test_another_game_cannot_supply_the_requested_analysis(self):
        with self.assertRaises(ValueError): u.persisted_snapshot({'id': 'other', 'data': {'pgn': 'wrong'}}, [], 'game', phase='current')

    def test_existing_document_cannot_pass_a_new_save_check(self):
        with self.assertRaises(ValueError): u.fresh_document_name('beta13', lambda name: True, token='known')

    def test_two_saves_get_different_task_owned_names(self):
        first = u.fresh_document_name('beta13', lambda name: False)
        second = u.fresh_document_name('beta13', lambda name: False)
        self.assertNotEqual(first, second); self.assertTrue(first.endswith('.pgn'))

    def test_document_names_cannot_escape_the_task_namespace(self):
        with self.assertRaises(ValueError): u.fresh_document_name('../unrelated', lambda name: False)


class VmAuditCommandTests(unittest.TestCase):
    def test_optional_audit_always_enables_vm_service_and_preserves_channel_arguments(self):
        import os
        import subprocess
        import tempfile
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory); fake = folder / 'flutter'; output = folder / 'args'
            fake.write_text('#!/usr/bin/env python3\nimport os,sys,json\nfrom pathlib import Path\nPath(os.environ["AUDIT_ARGS"]).write_text(json.dumps(sys.argv[1:]))\n')
            fake.chmod(0o755)
            env = dict(os.environ, FLUTTER_BIN=str(fake), AUDIT_ARGS=str(output))
            subprocess.run(['bash', str(Path(__file__).with_name('run_classification_vm_audit.sh')),
                            '--flavor', 'preview', '--reporter', 'expanded'], env=env, check=True)
            import json
            self.assertEqual(json.loads(output.read_text()), ['test',
                'tool/hardening/classification/worker_lifecycle_test.dart', '--enable-vmservice',
                '--flavor', 'preview', '--reporter', 'expanded'])


if __name__ == '__main__': unittest.main()

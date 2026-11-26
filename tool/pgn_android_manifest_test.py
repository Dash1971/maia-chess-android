#!/usr/bin/env python3
"""Keep PGN VIEW intents in the native importer, outside Flutter route handling.

Discovered by the existing *_test.py verification suite in both repositories.
This source contract needs no Android build; installed intent tests remain part
of release qualification.
"""
from __future__ import annotations

from pathlib import Path
import unittest
import xml.etree.ElementTree as ET


REPO = Path(__file__).resolve().parents[1]
ANDROID = '{http://schemas.android.com/apk/res/android}'
FLAG = 'flutter_deeplinking_enabled'
PGN_TYPES = {'application/x-chess-pgn', 'application/vnd.chess-pgn'}


def check_native_pgn_routing(manifest: ET.Element) -> None:
    activities = [
        item for item in manifest.findall('./application/activity')
        if item.get(ANDROID + 'name', '').split('.')[-1] == 'MainActivity'
    ]
    if len(activities) != 1:
        raise ValueError('Expected one MainActivity for the native PGN importer')
    activity = activities[0]
    flags = [
        item for item in activity.findall('meta-data')
        if item.get(ANDROID + 'name') == FLAG
    ]
    if len(flags) != 1 or flags[0].get(ANDROID + 'value') != 'false':
        raise ValueError(
            'MainActivity must declare flutter_deeplinking_enabled=false: '
            'PGN content URIs belong to the native document importer'
        )
    accepted = set()
    for intent in activity.findall('intent-filter'):
        actions = {item.get(ANDROID + 'name') for item in intent.findall('action')}
        data = intent.findall('data')
        if ('android.intent.action.VIEW' in actions
                and any(item.get(ANDROID + 'scheme') == 'content' for item in data)):
            accepted.update(item.get(ANDROID + 'mimeType') for item in data)
    if not PGN_TYPES <= accepted:
        raise ValueError('Keep both native PGN content-URI VIEW intent types')


def fixture() -> ET.Element:
    return ET.fromstring('''
        <manifest xmlns:android="http://schemas.android.com/apk/res/android">
          <application android:label="Mobile Maia">
            <activity android:name=".MainActivity">
              <meta-data android:name="flutter_deeplinking_enabled" android:value="false" />
              <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <data android:scheme="content" />
                <data android:mimeType="application/x-chess-pgn" />
                <data android:mimeType="application/vnd.chess-pgn" />
              </intent-filter>
            </activity>
          </application>
        </manifest>
    ''')


class PgnAndroidManifestTest(unittest.TestCase):
    def test_repository_manifest_keeps_pgns_in_native_importer(self):
        path = REPO / 'android/app/src/main/AndroidManifest.xml'
        check_native_pgn_routing(ET.parse(path).getroot())

    def test_missing_opt_out_is_rejected_even_with_matching_comment(self):
        root = fixture()
        activity = root.find('./application/activity')
        activity.remove(activity.find('meta-data'))
        activity.append(ET.Comment('flutter_deeplinking_enabled=false'))
        with self.assertRaisesRegex(ValueError, 'flutter_deeplinking_enabled=false'):
            check_native_pgn_routing(root)

    def test_enabled_flutter_handler_is_rejected(self):
        root = fixture()
        root.find('./application/activity/meta-data').set(ANDROID + 'value', 'true')
        with self.assertRaisesRegex(ValueError, 'flutter_deeplinking_enabled=false'):
            check_native_pgn_routing(root)

    def test_application_level_flag_does_not_protect_main_activity(self):
        root = fixture()
        activity = root.find('./application/activity')
        flag = activity.find('meta-data')
        activity.remove(flag)
        root.find('application').append(flag)
        with self.assertRaisesRegex(ValueError, 'MainActivity must declare'):
            check_native_pgn_routing(root)

    def test_another_activity_flag_does_not_protect_main_activity(self):
        root = fixture()
        activity = root.find('./application/activity')
        flag = activity.find('meta-data')
        activity.remove(flag)
        other = ET.SubElement(root.find('application'), 'activity',
                              {ANDROID + 'name': '.OtherActivity'})
        other.append(flag)
        with self.assertRaisesRegex(ValueError, 'MainActivity must declare'):
            check_native_pgn_routing(root)

    def test_duplicate_flag_is_rejected(self):
        root = fixture()
        ET.SubElement(root.find('./application/activity'), 'meta-data',
                      {ANDROID + 'name': FLAG, ANDROID + 'value': 'true'})
        with self.assertRaisesRegex(ValueError, 'MainActivity must declare'):
            check_native_pgn_routing(root)

    def test_removing_native_view_filter_is_not_a_fix(self):
        root = fixture()
        activity = root.find('./application/activity')
        activity.remove(activity.find('intent-filter'))
        with self.assertRaisesRegex(ValueError, 'native PGN content-URI VIEW'):
            check_native_pgn_routing(root)

    def test_shared_contract_allows_channel_branding_and_full_activity_name(self):
        root = fixture()
        root.find('application').set(ANDROID + 'label', '${appLabel}')
        root.find('./application/activity').set(
            ANDROID + 'name', 'com.dash1971.maia_chess.MainActivity')
        check_native_pgn_routing(root)


if __name__ == '__main__':
    unittest.main()

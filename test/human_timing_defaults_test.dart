import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_organization_test.dart' show settingsApp, openSettings, key;

void main() {
  for (final (name, seed, enabled) in <(String, Map<String, Object>, bool)>[
    ('fresh install', {}, true),
    ('saved off', {'humanTiming': false}, false),
    ('saved on', {'humanTiming': true}, true),
    ('invalid string', {'humanTiming': 'false'}, true),
    ('invalid number', {'humanTiming': 1}, true),
  ]) {
    testWidgets('$name uses the 2.6 timing default only when needed', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(seed);
      await tester.pumpWidget(settingsApp());
      await openSettings(tester);
      expect(
        tester.widget<SwitchListTile>(key('human-timing-setting')).value,
        enabled,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }

  testWidgets('turning the new default off persists through an app restart', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(settingsApp());
    await openSettings(tester);
    final toggle = key('human-timing-setting');
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(
      (await SharedPreferences.getInstance()).getBool('humanTiming'),
      isFalse,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(settingsApp());
    await openSettings(tester);
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

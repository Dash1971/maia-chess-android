import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_organization_test.dart' show settingsApp, openSettings, key;

void main() {
  test(
    'notices cover recommendation boundaries and opening overrides',
    () async {
      final s = await AppLocalizations.delegate.load(const Locale('en'));
      final full = s.samplingFullVarietyNotice;
      final limited = s.samplingRecommendationWarning;
      final deterministic = s.samplingArgmaxNotice;
      final lower = s.samplingLowerNotice;
      final cases = <(double, double, bool, List<String>)>[
        (1, 0.95, true, []),
        (1, 0.95, false, [limited]),
        (1, 0.99, false, [limited]),
        (1, 0.99, true, []),
        (1, 0.94, true, [lower]),
        (1, 0.94, false, [lower, limited]),
        (0.95, 0.95, false, [lower, limited]),
        (1, 0.90, false, [lower, limited]),
        (1, 0.90, true, [lower]),
        (0.5, 1, true, [lower]),
        (0.5, 0.95, true, [lower]),
        (1, 1, false, [full]),
        (1, 1, true, [full]),
        (0, 0.95, false, [deterministic, limited]),
        (0, 0.95, true, [deterministic]),
        (0, 0, false, [deterministic, limited]),
        (0.5, 0, true, [deterministic]),
        (1, 0, false, [deterministic, limited]),
        (0.5, 1, false, [lower, limited]),
      ];
      for (final (temperature, topP, openingVariety, expected) in cases) {
        expect(
          samplingSettingsNotices(
            s,
            temperature: temperature,
            topP: topP,
            openingVariety: openingVariety,
          ),
          expected,
          reason:
              'Temperature $temperature, Top-P $topP, opening $openingVariety',
        );
      }
    },
  );

  testWidgets('fresh UI uses requested ratings and new sampling defaults', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(settingsApp());
    await tester.pumpAndSettle();
    expect(find.text('Play Maia rating: 1500'), findsOneWidget);
    await openSettings(tester);
    expect(find.text('Temperature: 1.00'), findsOneWidget);
    expect(find.text('Top-P: 0.95'), findsOneWidget);
    expect(find.text('Maia analysis rating: 1500'), findsOneWidget);
    expect(
      tester.widget<SettingsInfoSwitch>(key('opening-variety-setting')).value,
      isTrue,
    );
    final second = key('second-maia-engine-setting');
    expect(tester.widget<SwitchListTile>(second).value, isFalse);
    await tester.ensureVisible(second);
    await tester.tap(second);
    await tester.pumpAndSettle();
    expect(find.text('Second Maia analysis rating: 2600'), findsOneWidget);
    expect(key('sampling-recommendation-warning'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  for (final locale in AppLocalizations.supportedLocales) {
    test(
      'strength notices do not depend on opening variety in ${locale.languageCode}',
      () async {
        final s = await AppLocalizations.delegate.load(locale);
        for (final settings in [
          (0.5, 0.95, s.samplingLowerNotice),
          (0.0, 0.95, s.samplingArgmaxNotice),
          (1.0, 0.0, s.samplingArgmaxNotice),
        ]) {
          for (final opening in [true, false]) {
            expect(
              samplingSettingsNotices(
                s,
                temperature: settings.$1,
                topP: settings.$2,
                openingVariety: opening,
              ),
              [settings.$3, if (!opening) s.samplingRecommendationWarning],
            );
          }
        }
      },
    );
    testWidgets(
      'lower settings without opening variety show both notices in ${locale.languageCode}',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'temperatureV2': 0.5,
          'topPV2': 0.95,
          'maxOpeningVarietyV1': false,
        });
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final s = await AppLocalizations.delegate.load(locale);
        await tester.pumpWidget(settingsApp(locale: locale, scale: 2));
        await openSettings(tester);
        final notice = key('sampling-recommendation-warning');
        expect(
          tester.widget<Text>(notice).data,
          '${s.samplingLowerNotice}\n\n${s.samplingRecommendationWarning}',
        );
        await Scrollable.ensureVisible(tester.element(notice), alignment: 0.5);
        await tester.pumpAndSettle();
        expect(notice.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Temperature 0 preserves disabled Top-P and accessible help in ${locale.languageCode}',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'temperatureV2': 0.0,
          'topPV2': 0.85,
          'analysisElo': 1700,
          secondMaiaEloPreferenceKey: 2300,
          'maxOpeningVarietyV1': false,
        });
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final s = await AppLocalizations.delegate.load(locale);
        await tester.pumpWidget(settingsApp(locale: locale, scale: 2));
        await openSettings(tester);
        Slider slider(String id) => tester.widget<Slider>(
          find.descendant(of: key(id), matching: find.byType(Slider)),
        );
        expect(slider('top-p-setting').onChanged, isNull);
        expect(slider('top-p-setting').value, 0.85);
        expect(find.text(s.topPNotUsed), findsOneWidget);
        await tester.ensureVisible(key('top-p-unused-help'));
        await tester.tap(key('top-p-unused-help'));
        await tester.pumpAndSettle();
        expect(find.text(s.topPNotUsedHelp), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(s.close));
        await tester.pumpAndSettle();
        final temperature = slider('temperature-setting');
        temperature.onChanged!(0.5);
        temperature.onChangeEnd!(0.5);
        await tester.pumpAndSettle();
        expect(slider('top-p-setting').onChanged, isNotNull);
        expect(slider('top-p-setting').value, 0.85);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getDouble('topPV2'), 0.85);
        expect(prefs.getInt('analysisElo'), 1700);
        expect(prefs.getInt(secondMaiaEloPreferenceKey), 2300);
        expect(prefs.getBool('maxOpeningVarietyV1'), isFalse);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.pumpWidget(settingsApp(locale: locale, scale: 2));
        await openSettings(tester);
        expect(slider('top-p-setting').value, 0.85);
        expect(slider('temperature-setting').value, 0.5);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }
}

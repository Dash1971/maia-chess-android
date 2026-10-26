import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_organization_test.dart' show settingsApp, openSettings, key;

class _OpeningScreenshotCapture extends SamplingCapture {
  @override
  Future<void> initialize() async {}
  @override
  Future<void> loadStoredData() async {}
}

Finder get variety => key('opening-variety-setting');
Finder get varietySwitch =>
    find.descendant(of: variety, matching: find.byType(Switch));
SettingsInfoSwitch varietyWidget(WidgetTester tester) =>
    tester.widget<SettingsInfoSwitch>(variety);

Future<void> setSamplingSlider(
  WidgetTester tester,
  String id,
  double fraction,
) async {
  final slider = find.descendant(of: key(id), matching: find.byType(Slider));
  await tester.ensureVisible(slider);
  await tester.pumpAndSettle();
  final rect = tester.getRect(slider);
  // Tapping the track exercises the actual slider and its persistence callback.
  await tester.tapAt(
    Offset(rect.left + 24 + (rect.width - 48) * fraction, rect.center.dy),
  );
  await tester.pumpAndSettle();
}

Future<void> disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('new defaults enable opening variety with accessible help', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(settingsApp());
    await openSettings(tester);
    await tester.ensureVisible(key('opening-variety-help'));
    await tester.pumpAndSettle();
    expect(varietyWidget(tester).value, isTrue);
    expect(varietyWidget(tester).onChanged, isNotNull);
    expect(tester.widget<Switch>(varietySwitch).onChanged, isNotNull);
    expect(
      tester
          .getSemantics(key('opening-variety-help'))
          .getSemanticsData()
          .tooltip,
      'Max variety in opening',
    );
    expect(key('opening-variety-help').hitTestable(), findsOneWidget);
    await tester.tap(key('opening-variety-help'));
    await tester.pumpAndSettle();
    final strings = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(strings.maxOpeningVarietyHelp), findsOneWidget);
    await tester.tap(find.text(strings.close));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(varietyWidget(tester).value, isTrue);
    expect(tester.takeException(), isNull);
    semantics.dispose();
    await disposeApp(tester);
  });

  for (final sliderId in ['temperature-setting', 'top-p-setting']) {
    testWidgets(
      '$sliderId enables opening variety and preserves it on relaunch',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'temperatureV2': 1.0,
          'topPV2': 1.0,
          'maxOpeningVarietyV1': false,
        });
        await tester.pumpWidget(settingsApp());
        await openSettings(tester);
        await setSamplingSlider(tester, sliderId, 0.5);
        expect(varietyWidget(tester).onChanged, isNotNull);
        await tester.ensureVisible(varietySwitch);
        await tester.tap(varietySwitch);
        await tester.pumpAndSettle();
        expect(varietyWidget(tester).value, isTrue);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('maxOpeningVarietyV1'), isTrue);
        final prefKey = sliderId == 'temperature-setting'
            ? 'temperatureV2'
            : 'topPV2';
        expect(prefs.getDouble(prefKey), lessThan(1.0));
        await disposeApp(tester);
        await tester.pumpWidget(settingsApp());
        await openSettings(tester);
        expect(varietyWidget(tester).value, isTrue);
        expect(varietyWidget(tester).onChanged, isNotNull);
        await setSamplingSlider(tester, sliderId, 1);
        expect(varietyWidget(tester).value, isFalse);
        expect(varietyWidget(tester).onChanged, isNull);
        expect(prefs.getBool('maxOpeningVarietyV1'), isFalse);
        await disposeApp(tester);
        await tester.pumpWidget(settingsApp());
        await openSettings(tester);
        expect(varietyWidget(tester).value, isFalse);
        expect(varietyWidget(tester).onChanged, isNull);
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      },
    );
  }

  testWidgets(
    'returning one slider to default keeps variety while the other is lower',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'temperatureV2': 0.5,
        'topPV2': 0.9,
        'maxOpeningVarietyV1': true,
      });
      await tester.pumpWidget(settingsApp());
      await openSettings(tester);
      await setSamplingSlider(tester, 'temperature-setting', 1);
      expect(varietyWidget(tester).value, isTrue);
      expect(varietyWidget(tester).onChanged, isNotNull);
      await setSamplingSlider(tester, 'top-p-setting', 1);
      expect(varietyWidget(tester).value, isFalse);
      expect(varietyWidget(tester).onChanged, isNull);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    },
  );

  testWidgets('reset restores opening variety and Top-P 0.95', (tester) async {
    SharedPreferences.setMockInitialValues({
      'temperatureV2': 0.5,
      'maxOpeningVarietyV1': false,
    });
    await tester.pumpWidget(settingsApp());
    await openSettings(tester);
    expect(varietyWidget(tester).value, isFalse);
    await tester.ensureVisible(key('reset-settings-defaults'));
    await tester.tap(key('reset-settings-defaults'));
    await tester.pumpAndSettle();
    await tester.tap(key('confirm-reset-settings'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('maxOpeningVarietyV1'), isTrue);
    expect(prefs.getDouble('temperatureV2'), 1.0);
    expect(prefs.getDouble('topPV2'), 0.95);
    expect(varietyWidget(tester).value, isTrue);
    expect(varietyWidget(tester).onChanged, isNotNull);
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  for (final value in <Object>[
    'true',
    1,
    0.5,
    <String>['true'],
  ]) {
    testWidgets(
      'malformed opening preference $value safely falls back to the new default',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'temperatureV2': 0.5,
          'maxOpeningVarietyV1': value,
        });
        await tester.pumpWidget(settingsApp());
        await openSettings(tester);
        expect(varietyWidget(tester).value, isTrue);
        expect(varietyWidget(tester).onChanged, isNotNull);
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      },
    );
  }

  testWidgets('stale enabled preference at default sampling displays off', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'maxOpeningVarietyV1': true,
      'temperatureV2': 1.0,
      'topPV2': 1.0,
    });
    await tester.pumpWidget(settingsApp());
    await openSettings(tester);
    expect(varietyWidget(tester).value, isFalse);
    expect(varietyWidget(tester).onChanged, isNull);
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
      'opening help scrolls and closes at 320px/200% in ${locale.languageCode}',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'temperatureV2': 1.0,
          'topPV2': 1.0,
        });
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(settingsApp(locale: locale, scale: 2));
        await openSettings(tester);
        final help = key('opening-variety-help');
        await tester.ensureVisible(help);
        await tester.pumpAndSettle();
        final strings = await AppLocalizations.delegate.load(locale);
        expect(help.hitTestable(), findsOneWidget);
        expect(
          tester.getSemantics(help).getSemanticsData().tooltip,
          strings.maxOpeningVariety,
        );
        expect(
          tester.getSemantics(help).id,
          isNot(tester.getSemantics(varietySwitch).id),
        );
        expect(varietyWidget(tester).onChanged, isNull);
        await tester.tap(help);
        await tester.pumpAndSettle();
        expect(find.text(strings.maxOpeningVarietyHelp), findsOneWidget);
        final scrollable = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(Scrollable),
        );
        expect(scrollable, findsWidgets);
        final state = tester.state<ScrollableState>(scrollable.first);
        expect(state.position.maxScrollExtent, greaterThan(0));
        await tester.drag(scrollable.first, const Offset(0, -1000));
        await tester.pumpAndSettle();
        expect(state.position.pixels, greaterThan(0));
        await tester.ensureVisible(find.text(strings.close));
        await tester.tap(find.text(strings.close));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(varietyWidget(tester).value, isFalse);
        expect(tester.takeException(), isNull);
        semantics.dispose();
        await disposeApp(tester);
      },
    );
  }
  final output = Platform.environment['MAIA_OPENING_VARIETY_SCREENSHOT_DIR'];
  if (output != null) {
    testWidgets('render opening variety setting and help', (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final font = Platform.environment['MAIA_REPORT_FONT'];
      if (font != null) {
        final loader = FontLoader('Roboto')
          ..addFont(
            Future.value(ByteData.sublistView(File(font).readAsBytesSync())),
          );
        await tester.runAsync(loader.load);
      }
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await tester.runAsync(icons.load);
      final previousCapture = SamplingCapture.instance;
      final capture = _OpeningScreenshotCapture();
      SamplingCapture.instance = capture;
      addTearDown(() {
        SamplingCapture.instance = previousCapture;
        capture.dispose();
      });
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(key: boundaryKey, child: settingsApp()),
      );
      await openSettings(tester);
      Future<void> shot(String name) async {
        await tester.pumpAndSettle();
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(output).create(recursive: true);
          await File('$output/$name.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await Scrollable.ensureVisible(
        tester.element(key('engine-settings-section')),
        alignment: 0,
      );
      await shot('opening-variety-default');
      await setSamplingSlider(tester, 'temperature-setting', 0.5);
      await tester.ensureVisible(varietySwitch);
      await tester.tap(varietySwitch);
      await tester.pumpAndSettle();
      await Scrollable.ensureVisible(
        tester.element(key('engine-settings-section')),
        alignment: 0,
      );
      await shot('opening-variety-enabled');
      await tester.tap(key('opening-variety-help'));
      await shot('opening-variety-help');
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  }
}

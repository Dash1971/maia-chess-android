import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SettingsCapture extends SamplingCapture {
  bool blockReset = false;
  bool failReset = false;
  @override
  bool get busy => blockReset || super.busy;
  @override
  Future<void> setEnabled(bool value) async {
    if (failReset) throw StateError('Test preference failure');
    await super.setEnabled(value);
  }

  @override
  Future<void> initialize() async {}
  @override
  Future<void> loadStoredData() async {}
}

Widget settingsApp({
  Locale locale = const Locale('en'),
  double scale = 1,
  AppLanguageController? language,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xff5d735f),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xff171a18),
    useMaterial3: true,
    fontFamilyFallback:
        Platform.environment['MAIA_SETTINGS_JAPANESE_FONT'] != null
        ? const ['ScreenshotJapanese']
        : null,
  ),
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: language == null
      ? const GamePage()
      : ListenableBuilder(
          listenable: language,
          builder: (context, _) => AppLanguageSettings(
            selectedCode: language.selectedCode,
            onChanged: language.select,
            child: const GamePage(),
          ),
        ),
);

Finder key(String value) => find.byKey(ValueKey(value));
Future<void> openSettings(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(key('home-settings-button'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _SettingsCapture capture;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    capture = _SettingsCapture()
      ..enabled = true
      ..records = 24;
    SamplingCapture.instance = capture;
  });
  tearDown(() {
    capture.dispose();
    SamplingCapture.instance = SamplingCapture();
  });

  testWidgets(
    'reset restores every Settings preference and preserves stored game data',
    (tester) async {
      final before = <String, Object>{
        'premovesEnabled': false,
        'premovePenalty': true,
        'multiplePremoves': true,
        'humanTiming': true,
        'maiaUseMoveHistoryV1': true,
        'temperatureV2': 0.5,
        'topPV2': 0.9,
        'analysisElo': 1800,
        secondMaiaEnabledPreferenceKey: true,
        secondMaiaEloPreferenceKey: 2200,
        gameAnalysisQualityPreferenceKey: 'thorough',
        gameSoundsPreferenceKey: true,
        gameHapticsPreferenceKey: false,
        'chessnutBoardSounds': false,
        samplingCapturePreference: true,
        appLanguagePreferenceKey: 'ja',
        'savedGame': 'saved-session-sentinel',
        'recentGames': 'saved-games-sentinel',
        maiaPlayEloPreferenceKey: 1800,
      };
      SharedPreferences.setMockInitialValues(before);
      final language = AppLanguageController();
      addTearDown(language.dispose);
      await language.initialize();
      await tester.pumpWidget(settingsApp(language: language));
      await openSettings(tester);
      final prefs = await SharedPreferences.getInstance();
      for (final entry in before.entries) {
        expect(prefs.get(entry.key), entry.value);
      }
      for (final id in [
        'analysis-rating-setting',
        'second-maia-engine-setting',
        'second-maia-rating-setting',
        'game-analysis-quality-thorough',
      ]) {
        expect(
          find.descendant(
            of: key('analysis-settings-section'),
            matching: key(id),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: key('engine-settings-section'),
            matching: key(id),
          ),
          findsNothing,
        );
      }
      expect(
        find.textContaining('See information button for details.'),
        findsNothing,
      );
      for (final id in [
        'premove-penalty-setting',
        'multiple-premoves-setting',
      ]) {
        expect(tester.widget<SwitchListTile>(key(id)).onChanged, isNull);
      }
      await tester.ensureVisible(key('premoves-setting'));
      await tester.tap(key('premoves-setting'));
      await tester.pumpAndSettle();
      for (final id in [
        'premove-penalty-setting',
        'multiple-premoves-setting',
      ]) {
        final child = tester.widget<SwitchListTile>(key(id));
        expect(child.onChanged, isNotNull);
        expect(child.value, isTrue);
        expect(tester.getSize(key(id)).height, greaterThanOrEqualTo(48));
      }
      expect(
        find.descendant(
          of: key('engine-settings-section'),
          matching: key('reset-settings-defaults'),
        ),
        findsNothing,
      );
      await tester.ensureVisible(key('reset-settings-defaults'));
      await tester.tap(key('reset-settings-defaults'));
      await tester.pumpAndSettle();
      await tester.tap(key('confirm-reset-settings'));
      await tester.pumpAndSettle();
      final defaults = <String, Object>{
        'premovesEnabled': true,
        'premovePenalty': false,
        'multiplePremoves': false,
        'humanTiming': false,
        'maiaUseMoveHistoryV1': false,
        'temperatureV2': 1.0,
        'topPV2': 1.0,
        'analysisElo': 1600,
        secondMaiaEnabledPreferenceKey: false,
        secondMaiaEloPreferenceKey: 2400,
        gameAnalysisQualityPreferenceKey: 'fast',
        gameSoundsPreferenceKey: false,
        gameHapticsPreferenceKey: true,
        'chessnutBoardSounds': true,
        samplingCapturePreference: false,
      };
      for (final entry in defaults.entries) {
        expect(prefs.get(entry.key), entry.value);
      }
      for (final id in ['savedGame', 'recentGames', maiaPlayEloPreferenceKey]) {
        expect(prefs.get(id), before[id]);
      }
      expect(capture.records, 24);
      expect(capture.enabled, isFalse);
      expect(language.selectedCode, isNull);
      expect(prefs.containsKey(appLanguagePreferenceKey), isFalse);
      expect(
        tester.getTopLeft(key('reset-settings-defaults')).dy,
        lessThan(tester.getTopLeft(key('copy-diagnostics')).dy),
      );
      expect(key('second-maia-rating-setting'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.pumpWidget(settingsApp(language: language));
      await openSettings(tester);
      expect(
        tester.widget<SwitchListTile>(key('game-sounds-setting')).value,
        isFalse,
      );
      expect(
        tester.widget<SwitchListTile>(key('game-haptics-setting')).value,
        isTrue,
      );
      expect(
        tester.widget<SwitchListTile>(key('chessnut-sounds-toggle')).value,
        isTrue,
      );
      expect(key('game-analysis-quality-fast'), findsOneWidget);
      for (final entry in defaults.entries) {
        expect(prefs.get(entry.key), entry.value);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'reset respects capture operations and recovers from a failed write',
    (tester) async {
      await tester.pumpWidget(settingsApp());
      await openSettings(tester);
      capture.blockReset = true;
      capture.notifyListeners();
      await tester.pump();
      await tester.ensureVisible(key('reset-settings-defaults'));
      expect(
        tester.widget<TextButton>(key('reset-settings-defaults')).onPressed,
        isNull,
      );
      capture.blockReset = false;
      capture.failReset = true;
      capture.notifyListeners();
      await tester.pumpAndSettle();
      await tester.tap(key('reset-settings-defaults'));
      await tester.pumpAndSettle();
      await tester.tap(key('confirm-reset-settings'));
      await tester.pumpAndSettle();
      expect(
        find.text('Some settings could not be reset. Please try again.'),
        findsOneWidget,
      );
      expect(capture.records, 24);
      expect(capture.enabled, isTrue);
      capture.failReset = false;
      await tester.tap(key('reset-settings-defaults'));
      await tester.pumpAndSettle();
      await tester.tap(key('confirm-reset-settings'));
      await tester.pumpAndSettle();
      expect(capture.enabled, isFalse);
      expect(capture.records, 24);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
      'reset confirmation preserves settings on dismissal in ${locale.languageCode}',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final before = <String, Object>{
          'temperatureV2': 0.5,
          'humanTiming': true,
          samplingCapturePreference: true,
          appLanguagePreferenceKey: locale.languageCode,
        };
        SharedPreferences.setMockInitialValues(before);
        await tester.pumpWidget(settingsApp(locale: locale, scale: 2));
        await openSettings(tester);
        final strings = await AppLocalizations.delegate.load(locale);
        final prefs = await SharedPreferences.getInstance();
        for (final dismiss in ['cancel', 'back', 'outside']) {
          await tester.ensureVisible(key('reset-settings-defaults'));
          await tester.tap(key('reset-settings-defaults'));
          await tester.pumpAndSettle();
          expect(find.text(strings.resetSettingsConfirmation), findsOneWidget);
          expect(find.text(strings.resetSettingsKeepData), findsOneWidget);
          expect(key('confirm-reset-settings').hitTestable(), findsOneWidget);
          if (dismiss == 'cancel') {
            await tester.tap(find.text(strings.cancel));
          } else if (dismiss == 'back') {
            await tester.binding.handlePopRoute();
          } else {
            await tester.tapAt(const Offset(1, 1));
          }
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsNothing);
          for (final entry in before.entries) {
            expect(prefs.get(entry.key), entry.value);
          }
          expect(capture.enabled, isTrue);
          expect(capture.records, 24);
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets('reset confirmation cannot proceed while capture becomes busy', (
    tester,
  ) async {
    await tester.pumpWidget(settingsApp());
    await openSettings(tester);
    await tester.ensureVisible(key('reset-settings-defaults'));
    await tester.tap(key('reset-settings-defaults'));
    await tester.pumpAndSettle();
    capture.blockReset = true;
    capture.notifyListeners();
    await tester.pump();
    expect(
      tester.widget<TextButton>(key('confirm-reset-settings')).onPressed,
      isNull,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    capture.blockReset = false;
    capture.notifyListeners();
    await tester.pumpAndSettle();
    expect(capture.enabled, isTrue);
    expect(capture.records, 24);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'all settings actions remain accessible at 320px and 200% in every language',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      try {
        for (final locale in AppLocalizations.supportedLocales) {
          SharedPreferences.setMockInitialValues({
            secondMaiaEnabledPreferenceKey: true,
          });
          final strings = await AppLocalizations.delegate.load(locale);
          await tester.pumpWidget(settingsApp(locale: locale, scale: 2));
          await openSettings(tester);
          for (final id in [
            'premove-penalty-setting',
            'multiple-premoves-setting',
            'maia-history-help',
            'sampling-actions',
            'clear-sampling-data',
            'second-maia-engine-setting',
            'second-maia-rating-setting',
            'game-analysis-quality-fast',
            'reset-settings-defaults',
          ]) {
            final switches = find.descendant(
              of: key(id),
              matching: find.byType(Switch),
            );
            final target = switches.evaluate().isNotEmpty ? switches : key(id);
            await tester.ensureVisible(target);
            await tester.pumpAndSettle();
            expect(
              target.hitTestable(),
              findsOneWidget,
              reason: '${locale.languageCode}: $id',
            );
            expect(
              tester.takeException(),
              isNull,
              reason: '${locale.languageCode}: $id',
            );
          }
          await tester.ensureVisible(key('maia-history-help'));
          await tester.pumpAndSettle();
          final helpNode = tester.getSemantics(key('maia-history-help'));
          expect(
            helpNode.getSemanticsData().tooltip,
            strings.maiaHistorySetting,
          );
          final switchNode = tester.getSemantics(
            find.descendant(
              of: key('maia-history-setting'),
              matching: find.byType(Switch),
            ),
          );
          expect(helpNode.id, isNot(switchNode.id));
          expect(switchNode.label, strings.maiaHistorySetting);
          await tester.ensureVisible(key('sampling-actions'));
          await tester.pumpAndSettle();
          expect(
            tester.getSize(key('clear-sampling-data')).shortestSide,
            greaterThanOrEqualTo(48),
          );
          expect(
            tester.getSize(key('sampling-actions')).shortestSide,
            greaterThanOrEqualTo(48),
          );
          expect(
            tester.getCenter(key('sampling-actions')).dy,
            tester.getCenter(key('clear-sampling-data')).dy,
          );
          expect(
            tester
                .getSemantics(key('clear-sampling-data'))
                .getSemanticsData()
                .tooltip,
            strings.clearSamplingData,
          );
          expect(
            tester
                .getSemantics(
                  find.descendant(
                    of: key('sampling-actions'),
                    matching: find.byType(IconButton),
                  ),
                )
                .getSemanticsData()
                .tooltip,
            contains(strings.shareAndExport),
          );
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        }
      } finally {
        semantics.dispose();
      }
    },
  );

  // Actual Settings screen, opt-in only. No emulator/APK build or CI goldens.
  final output = Platform.environment['MAIA_SETTINGS_SCREENSHOT_DIR'];
  if (output != null) {
    testWidgets('render Settings proposal', (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final previousShadows = debugDisableShadows;
      debugDisableShadows = false;
      try {
        final font = Platform.environment['MAIA_REPORT_FONT']!;
        final loader = FontLoader('Roboto')
          ..addFont(
            Future.value(ByteData.sublistView(File(font).readAsBytesSync())),
          );
        await tester.runAsync(loader.load);
        final japaneseFont =
            Platform.environment['MAIA_SETTINGS_JAPANESE_FONT'];
        if (japaneseFont != null) {
          final japanese = FontLoader('ScreenshotJapanese')
            ..addFont(
              Future.value(
                ByteData.sublistView(File(japaneseFont).readAsBytesSync()),
              ),
            );
          await tester.runAsync(japanese.load);
        }
        final locale = Locale(
          Platform.environment['MAIA_SETTINGS_LOCALE'] ?? 'en',
        );
        final strings = await AppLocalizations.delegate.load(locale);
        for (final family in ['MaterialIcons', 'LichessIcons']) {
          final loader = FontLoader(family)
            ..addFont(
              rootBundle.load(
                family == 'MaterialIcons'
                    ? 'fonts/MaterialIcons-Regular.otf'
                    : 'assets/fonts/LichessIcons.ttf',
              ),
            );
          await tester.runAsync(loader.load);
        }
        SharedPreferences.setMockInitialValues({
          secondMaiaEnabledPreferenceKey: true,
        });
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: settingsApp(locale: locale),
          ),
        );
        await openSettings(tester);
        Future<void> shot(String name) async {
          await tester.pumpAndSettle();
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory(output).create(recursive: true);
            await File('$output/$name.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }

        for (final section in ['game', 'engine', 'analysis']) {
          await Scrollable.ensureVisible(
            tester.element(key('$section-settings-section')),
            alignment: 0,
          );
          await shot(section);
        }
        await tester.ensureVisible(key('copy-diagnostics'));
        await shot('reset-settings');
        await tester.tap(key('reset-settings-defaults'));
        await shot('reset-confirmation');
        await tester.tap(find.text(strings.cancel));
        await tester.pumpAndSettle();
        await tester.ensureVisible(key('sampling-help'));
        await tester.tap(key('sampling-help'));
        await shot('engine-help');
        await tester.tap(find.text(strings.close));
        await tester.pumpAndSettle();
        await tester.ensureVisible(key('maia-history-help'));
        await tester.tap(key('maia-history-help'));
        await shot('history-help');
        await tester.tap(find.text(strings.close));
        await tester.pumpAndSettle();
        final samplingHelp = find.descendant(
          of: key('sampling-data-toggle'),
          matching: find.byType(IconButton),
        );
        await tester.ensureVisible(samplingHelp);
        await tester.tap(samplingHelp);
        await shot('sampling-help');
        await tester.tap(find.text(strings.close));
        await tester.pumpAndSettle();
        await tester.ensureVisible(key('sampling-actions'));
        await tester.tap(key('sampling-actions'));
        await shot('sampling-menu');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      } finally {
        debugDisableShadows = previousShadows;
      }
    });
  }
}

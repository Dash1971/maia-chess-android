import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppDynamicColors palette(Color seed) => (
  light: ColorScheme.fromSeed(seedColor: seed),
  dark: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('system buttons contrast with the app rather than the OS theme', (
    tester,
  ) async {
    await tester.pumpWidget(const MaiaChessApp());
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(GamePage));
    final controller = AppAppearanceSettings.maybeOf(context)!;
    for (final appearance in [
      const AppAppearance(),
      const AppAppearance(mode: ThemeMode.light),
      const AppAppearance(pureBlack: true),
    ]) {
      await controller.select(appearance);
      await tester.pumpAndSettle();
      final style = tester
          .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
            find.byKey(const ValueKey('app-system-ui-style')),
          )
          .value;
      final theme = Theme.of(context);
      expect(style.systemNavigationBarContrastEnforced, isFalse);
      expect(style.systemNavigationBarColor, theme.scaffoldBackgroundColor);
      expect(
        style.systemNavigationBarIconBrightness,
        theme.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      );
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  test('fresh installs and malformed preferences keep the exact old theme', () {
    final previous = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff5d735f),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xff171a18),
      useMaterial3: true,
    );
    for (final stored in [
      null,
      7,
      '{',
      '[]',
      '{}',
      '{"mode":"unknown","systemColors":1,"pureBlack":"yes"}',
    ]) {
      final value = AppAppearance.decode(stored);
      expect(value.mode, ThemeMode.dark);
      expect(value.systemColors, isFalse);
      expect(value.pureBlack, isFalse);
      expect(appTheme(value, Brightness.dark), previous);
    }
  });

  test('darker panels are confined to pure-black dark mode', () {
    final dynamic = palette(Colors.purple);
    for (final system in [false, true]) {
      final normal = AppAppearance(systemColors: system);
      final black = normal.copyWith(pureBlack: true);
      final light = appTheme(normal, Brightness.light, dynamicColors: dynamic);
      expect(appTheme(black, Brightness.light, dynamicColors: dynamic), light);
      final dark = appTheme(normal, Brightness.dark, dynamicColors: dynamic);
      final oled = appTheme(black, Brightness.dark, dynamicColors: dynamic);
      expect(oled.scaffoldBackgroundColor, Colors.black);
      expect(oled.colorScheme.surfaceContainerLow, const Color(0xff080808));
      expect(oled.colorScheme.surfaceContainer, const Color(0xff101010));
      expect(oled.colorScheme.surfaceContainerHigh, const Color(0xff171717));
      expect(oled.colorScheme.surfaceContainerHighest, const Color(0xff202020));
      // Only surface colors change: preserve readable foregrounds, accent
      // colors and the meaning of selected/disabled controls.
      expect(
        oled.colorScheme.copyWith(
          surface: dark.colorScheme.surface,
          surfaceDim: dark.colorScheme.surfaceDim,
          surfaceContainerLowest: dark.colorScheme.surfaceContainerLowest,
          surfaceContainerLow: dark.colorScheme.surfaceContainerLow,
          surfaceContainer: dark.colorScheme.surfaceContainer,
          surfaceContainerHigh: dark.colorScheme.surfaceContainerHigh,
          surfaceContainerHighest: dark.colorScheme.surfaceContainerHighest,
        ),
        dark.colorScheme,
      );
      expect(appTheme(normal, Brightness.dark, dynamicColors: dynamic), dark);
    }
  });

  test(
    'all combinations persist independently and OLED only changes dark mode',
    () async {
      for (final mode in ThemeMode.values) {
        for (final system in [false, true]) {
          for (final black in [false, true]) {
            final value = AppAppearance(
              mode: mode,
              systemColors: system,
              pureBlack: black,
            );
            final controller = AppAppearanceController(
              readColors: () async => null,
            );
            await controller.select(value);
            controller.dispose();
            final restored = AppAppearanceController(
              readColors: () async => null,
            );
            await restored.initialize();
            expect(restored.value.encode(), value.encode());
            final colors = palette(Colors.purple);
            final light = appTheme(
              value,
              Brightness.light,
              dynamicColors: colors,
            );
            final dark = appTheme(
              value,
              Brightness.dark,
              dynamicColors: colors,
            );
            expect(
              light.colorScheme.primary,
              system
                  ? colors.light.primary
                  : appTheme(
                      const AppAppearance(),
                      Brightness.light,
                    ).colorScheme.primary,
            );
            expect(
              dark.colorScheme.primary,
              system
                  ? colors.dark.primary
                  : appTheme(
                      const AppAppearance(),
                      Brightness.dark,
                    ).colorScheme.primary,
            );
            expect(light.scaffoldBackgroundColor, isNot(Colors.black));
            if (black) {
              expect(dark.scaffoldBackgroundColor, Colors.black);
              expect(dark.colorScheme.surface, Colors.black);
              expect(dark.appBarTheme.backgroundColor, Colors.black);
              expect(dark.colorScheme.surfaceContainerLow, isNot(Colors.black));
            }
            restored.dispose();
          }
        }
      }
    },
  );

  test(
    'slow initial read cannot undo a selection; writes stay ordered',
    () async {
      final read = Completer<Object?>();
      final first = Completer<void>();
      final writes = <String>[];
      final controller = AppAppearanceController(
        read: () => read.future,
        readColors: () async => null,
        write: (v) async {
          writes.add(v);
          if (writes.length == 1) await first.future;
        },
      );
      final init = controller.initialize();
      final a = controller.select(const AppAppearance(mode: ThemeMode.light));
      final b = controller.select(
        const AppAppearance(systemColors: true, pureBlack: true),
      );
      read.complete(const AppAppearance().encode());
      await init;
      expect(controller.value.pureBlack, isTrue);
      expect(writes, hasLength(1));
      first.complete();
      await Future.wait([a, b]);
      expect(writes, hasLength(2));
      expect(AppAppearance.decode(writes.last).pureBlack, isTrue);
      controller.dispose();
    },
  );

  test(
    'failed write is reported and later successful write recovers',
    () async {
      var fail = true;
      final controller = AppAppearanceController(
        readColors: () async => null,
        write: (_) async {
          if (fail) throw StateError('disk unavailable');
        },
      );
      await controller.select(const AppAppearance(mode: ThemeMode.light));
      expect(controller.persistenceFailed, isTrue);
      expect(controller.value.mode, ThemeMode.light);
      fail = false;
      await controller.select(const AppAppearance());
      expect(controller.persistenceFailed, isFalse);
      controller.dispose();
    },
  );

  test(
    'platform failures fall back, stale replies and disposal are harmless',
    () async {
      final requests = <Completer<AppDynamicColors?>>[];
      final controller = AppAppearanceController(
        readColors: () {
          final request = Completer<AppDynamicColors?>();
          requests.add(request);
          return request.future;
        },
      );
      final older = controller.refreshColors();
      final newer = controller.refreshColors();
      final colors = palette(Colors.purple);
      requests[1].complete(colors);
      await newer;
      requests[0].complete(palette(Colors.orange));
      await older;
      expect(controller.dynamicColors, colors);
      final failed = controller.refreshColors();
      requests[2].completeError(PlatformException(code: 'unavailable'));
      await failed;
      expect(controller.dynamicColors, isNull);
      final pending = controller.refreshColors();
      controller.dispose();
      requests[3].complete(colors);
      await pending;
    },
  );

  testWidgets(
    'Appearance is below Language; live changes keep routes and page state',
    (tester) async {
      tester.view.physicalSize = const Size(412, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaiaChessApp());
      await tester.pumpAndSettle();
      final state = tester.state(find.byType(GamePage));
      final context = tester.element(find.byType(GamePage));
      final controller = AppAppearanceSettings.maybeOf(context)!;
      final navigator = Navigator.of(context);
      await tester.tap(find.byKey(const ValueKey('home-settings-button')));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('app-language-system'))).dy,
        lessThan(
          tester
              .getTopLeft(
                find.byKey(const ValueKey('appearance-settings-section')),
              )
              .dy,
        ),
      );
      expect(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('appearance-settings-section')),
            )
            .dy,
        lessThan(
          tester
              .getTopLeft(find.byKey(const ValueKey('game-settings-section')))
              .dy,
        ),
      );
      final systemSwitch = tester.widget<SwitchListTile>(
        find.byKey(const ValueKey('appearance-system-colors')),
      );
      expect(systemSwitch.onChanged, isNull); // unsupported platform
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Kept route')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await controller.select(
        const AppAppearance(mode: ThemeMode.light, pureBlack: true),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kept route'), findsOneWidget);
      expect(
        Theme.of(tester.element(find.text('Kept route'))).brightness,
        Brightness.light,
      );
      expect(Navigator.of(context), same(navigator));
      expect(
        tester.state(find.byType(GamePage, skipOffstage: false)),
        same(state),
      );
      navigator.pop();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('appearance-mode-light')),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const MaiaChessApp());
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(GamePage))).brightness,
        Brightness.light,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'system brightness changes and fixed Dark override work without losing state',
    (tester) async {
      await tester.pumpWidget(const MaiaChessApp());
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(GamePage));
      final state = tester.state(find.byType(GamePage));
      final controller = AppAppearanceSettings.maybeOf(context)!;
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await controller.select(const AppAppearance(mode: ThemeMode.system));
      await tester.pumpAndSettle();
      expect(Theme.of(context).brightness, Brightness.light);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      expect(Theme.of(context).brightness, Brightness.dark);
      await controller.select(const AppAppearance());
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(tester.state(find.byType(GamePage)), same(state));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Android palette refresh on resume preserves the route and selected mode',
    (tester) async {
      const channel = MethodChannel('io.material.plugins/dynamic_color');
      var color = 0xff6750a4;
      var requests = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'getCorePalette');
            requests++;
            return Int32List.fromList(List<int>.filled(65, color));
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      await tester.pumpWidget(const MaiaChessApp());
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(GamePage));
      final state = tester.state(find.byType(GamePage));
      final controller = AppAppearanceSettings.maybeOf(context)!;
      expect(controller.dynamicColors, isNotNull);
      await controller.select(const AppAppearance(systemColors: true));
      await tester.pumpAndSettle();
      final before = Theme.of(context).colorScheme.primary;
      color = 0xff006c4c;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(requests, greaterThanOrEqualTo(2));
      expect(Theme.of(context).colorScheme.primary, isNot(before));
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(tester.state(find.byType(GamePage)), same(state));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('semantic text keeps its hue and readable light-theme contrast', (
    tester,
  ) async {
    final theme = appTheme(const AppAppearance(), Brightness.light);
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    for (final color in [
      primaryMaiaAnalysisColor,
      secondaryMaiaAnalysisColor,
      const Color(0xff72b7ee),
      ...MoveClassification.values.map((c) => c.color),
    ]) {
      final foreground = chessTextColor(context, color).computeLuminance();
      for (final background in [
        theme.colorScheme.surface,
        theme.colorScheme.surfaceContainerLow,
        theme.colorScheme.surfaceContainer,
      ]) {
        expect(
          (background.computeLuminance() + 0.05) / (foreground + 0.05),
          greaterThanOrEqualTo(4.5),
        );
      }
    }
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
      'appearance controls fit ${locale.languageCode} at 200% in light and dark',
      (tester) async {
        final strings = await AppLocalizations.delegate.load(locale);
        tester.view.physicalSize = const Size(320, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = AppAppearanceController(
          readColors: () async => palette(Colors.purple),
        );
        await controller.initialize();
        for (final brightness in Brightness.values) {
          await tester.pumpWidget(
            AppAppearanceSettings(
              controller: controller,
              child: MaterialApp(
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                theme: appTheme(
                  const AppAppearance(pureBlack: true),
                  brightness,
                  dynamicColors: controller.dynamicColors,
                ),
                home: const Scaffold(
                  body: SingleChildScrollView(
                    child: AppearanceSettingsSection(),
                  ),
                ),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(2)),
                  child: child!,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          // Exercise the open popup as well as its closed label. System theme
          // must use its own message: French/Hindi language defaults explicitly
          // name language and are incorrect in this control.
          for (final (mode, label) in [
            (ThemeMode.system, strings.appearanceSystemDefault),
            (ThemeMode.light, strings.appearanceLight),
            (ThemeMode.dark, strings.appearanceDark),
          ]) {
            final field = find.byType(DropdownButtonFormField<ThemeMode>);
            await tester.ensureVisible(field);
            await tester.tap(field);
            await tester.pumpAndSettle();
            final option = find.text(label).last;
            await tester.ensureVisible(option);
            await tester.tap(option);
            await tester.pumpAndSettle();
            expect(controller.value.mode, mode);
            expect(tester.takeException(), isNull);
          }
          if (['fr', 'hi'].contains(locale.languageCode)) {
            expect(find.text(strings.systemDefault), findsNothing);
          }
        }
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
      },
    );
  }
}

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget app(
  Widget home, {
  Locale locale = const Locale('en'),
  double scale = 1,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xff5d735f),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xff171a18),
    useMaterial3: true,
  ),
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: home,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('both format choices fit every locale at large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final locale in AppLocalizations.supportedLocales) {
      final s = await AppLocalizations.delegate.load(locale);
      for (final share in [false, true]) {
        await tester.pumpWidget(
          app(
            Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => chooseSamplingFormat(context, share: share),
                  child: const Text('open'),
                ),
              ),
            ),
            locale: locale,
            scale: 2,
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.text(s.samplingReadable), findsOneWidget);
        expect(find.text(s.samplingResearch), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(s.cancel));
        await tester.pumpAndSettle();
      }
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets('format defaults to HTML and allows JSONL', (tester) async {
    bool? result;
    await tester.pumpWidget(
      app(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await chooseSamplingFormat(context, share: false);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<RadioGroup<bool>>(find.byType(RadioGroup<bool>)).groupValue,
      true,
    );
    await tester.tap(find.text('Full research data (JSONL)'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save…'));
    await tester.pumpAndSettle();
    expect(result, false);
  });

  // Opt-in screenshots of the actual widgets; CI never writes golden artifacts.
  final output = Platform.environment['MAIA_REPORT_MOCKUP_DIR'];
  if (output != null) {
    testWidgets('render report proposal for maintainer', (tester) async {
      final previousShadows = debugDisableShadows;
      debugDisableShadows = false;
      try {
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
          final icons = FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
          await tester.runAsync(icons.load);
        }
        final boundaryKey = GlobalKey();
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

        SharedPreferences.setMockInitialValues({});
        final directory = Directory.systemTemp.createTempSync(
          'maia-report-shots',
        );
        final capture = SamplingCapture(directory: directory);
        SamplingCapture.instance = capture;
        await tester.runAsync(() => capture.setEnabled(true));
        capture.records = 24;
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: app(
              Scaffold(
                appBar: AppBar(
                  leading: const BackButton(),
                  title: const Text('Settings'),
                ),
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      const ListTile(title: Text('Temperature: 1.00')),
                      Slider(value: 1, onChanged: (_) {}),
                      const ListTile(title: Text('Top-P: 1.00')),
                      Slider(value: 1, onChanged: (_) {}),
                      SwitchListTile(
                        value: false,
                        onChanged: (_) {},
                        title: const Text('Use move history'),
                      ),
                      const SamplingCaptureSettings(),
                      const ListTile(title: Text('Maia analysis rating: 1600')),
                      Slider(value: 0.5, onChanged: (_) {}),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        capture.records = 24; // Illustrative count, not a user's capture.
        await tester.runAsync(() => capture.setEnabled(true));
        await tester.pumpAndSettle();
        await shot('01-settings');
        await tester.tap(find.byKey(const ValueKey('sampling-actions')));
        await tester.pumpAndSettle();
        await shot('02-actions');
        await tester.tap(find.text('Save…'));
        await tester.pumpAndSettle();
        await shot('03-format');
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('sampling-actions')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Share…'));
        await tester.pumpAndSettle();
        await shot('04-share-format');
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await tester.runAsync(capture.flush);
        capture.dispose();
        SamplingCapture.instance = SamplingCapture();
        directory.deleteSync(recursive: true);
      } finally {
        debugDisableShadows = previousShadows;
      }
    });
  }
}

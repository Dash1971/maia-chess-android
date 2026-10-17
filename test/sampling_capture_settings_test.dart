import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CountingCapture extends SamplingCapture {
  CountingCapture({required super.directory});
  int clearCalls = 0;
  Completer<void>? clearGate;
  bool failClear = false;
  Future<void>? lastClear;

  @override
  Future<void> clear() {
    clearCalls++;
    return lastClear = _clear();
  }

  Future<void> _clear() async {
    await clearGate?.future;
    if (failClear) {
      failed = true; // The storage controller reports failures this way.
      return;
    }
    await super.clear();
  }
}

Widget captureApp() => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: const Scaffold(
    body: SingleChildScrollView(child: SamplingCaptureSettings()),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late CountingCapture capture;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('maia-capture-ui-');
    capture = CountingCapture(directory: directory);
    SamplingCapture.instance = capture;
    await capture.setEnabled(true);
    capture
        .begin(
          gameId: SamplingCapture.newId(),
          generation: 0,
          ply: 0,
          fen: chess.Chess.DEFAULT_POSITION,
          positions: [chess.Chess.DEFAULT_POSITION],
          prefix: [],
          history: false,
          elo: 1600,
          tokens: Float32List(6208),
          backend: 'test',
        )!
        .finish('timeout');
    await capture.flush();
    await capture.setEnabled(false);
  });
  tearDown(() async {
    await capture.flush();
    capture.dispose();
    SamplingCapture.instance = SamplingCapture();
    await directory.delete(recursive: true);
  });
  final clear = find.byKey(const ValueKey('clear-sampling-data'));
  final confirm = find.byKey(const ValueKey('confirm-clear-sampling-data'));
  Map<String, String> storedBytes() => {
    for (final f in directory.listSync(recursive: true).whereType<File>())
      f.path: base64Encode(f.readAsBytesSync()),
  };

  Future<void> finishAsync(WidgetTester tester, Future<void> operation) async {
    var finished = false;
    unawaited(operation.then((_) => finished = true));
    // Disk/isolate completion runs outside the widget test's fake clock.
    for (var i = 0; i < 250 && !finished; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(finished, isTrue);
  }

  testWidgets(
    'open, cancel, back and barrier dismissal preserve capture bytes',
    (tester) async {
      await tester.pumpWidget(captureApp());
      await tester.pumpAndSettle();
      final before = storedBytes();
      for (final dismissal in ['cancel', 'back', 'barrier']) {
        await tester.tap(clear);
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(capture.clearCalls, 0);
        expect(capture.records, 1);
        expect(storedBytes(), before);
        if (dismissal == 'cancel') {
          await tester.tap(find.text('Cancel'));
        } else if (dismissal == 'back') {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tapAt(const Offset(5, 5));
        }
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(capture.clearCalls, 0);
        expect(storedBytes(), before);
        expect(tester.widget<IconButton>(clear).onPressed, isNotNull);
      }
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'repeat taps confirm once, preserve exported copy and update controls',
    (tester) async {
      final saved = File('${directory.path}-saved.jsonl');
      await tester.runAsync(() async {
        await (await capture.export()).copy(saved.path);
      });
      addTearDown(() async {
        if (await saved.exists()) await saved.delete();
      });
      final savedBytes = saved.readAsBytesSync();
      capture.clearGate = Completer<void>();
      await tester.pumpWidget(captureApp());
      await tester.pumpAndSettle();
      final open = tester.widget<IconButton>(clear).onPressed!;
      open();
      open();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(capture.clearCalls, 0);
      final accept = tester.widget<TextButton>(confirm).onPressed!;
      accept();
      accept();
      await tester.pump();
      expect(capture.clearCalls, 1);
      expect(capture.records, 1);
      expect(tester.widget<IconButton>(clear).onPressed, isNull);
      expect(
        tester
            .widget<PopupMenuButton<String>>(
              find.byKey(const ValueKey('sampling-actions')),
            )
            .enabled,
        isFalse,
      );
      open();
      expect(capture.clearCalls, 1);
      capture.clearGate!.complete();
      await tester.pump();
      await finishAsync(tester, capture.lastClear!);
      await tester.pumpAndSettle();
      expect(capture.records, 0);
      expect(storedBytes(), isEmpty);
      expect(saved.readAsBytesSync(), savedBytes);
      expect(find.byType(SamplingCaptureSettings), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Sampling data'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('clear failure gives existing feedback and allows retry', (
    tester,
  ) async {
    capture.failClear = true;
    await tester.pumpWidget(captureApp());
    await tester.pumpAndSettle();
    final before = storedBytes();
    await tester.tap(clear);
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(capture.clearCalls, 1);
    expect(storedBytes(), before);
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text(
          'Could not access sampling data. Playing is unaffected.',
        ),
      ),
      findsOneWidget,
    );
    expect(tester.widget<IconButton>(clear).onPressed, isNotNull);
    capture.failClear = false;
    await tester.tap(clear);
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pump();
    await finishAsync(tester, capture.lastClear!);
    await tester.pumpAndSettle();
    expect(capture.clearCalls, 2);
    expect(capture.records, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('format selection blocks clear and restores it on cancel', (
    tester,
  ) async {
    await tester.pumpWidget(captureApp());
    await tester.pumpAndSettle();
    final open = tester.widget<IconButton>(clear).onPressed!;
    await tester.tap(find.byKey(const ValueKey('sampling-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save…'));
    await tester.pumpAndSettle();
    open();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(confirm, findsNothing);
    expect(capture.clearCalls, 0);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(clear).onPressed, isNotNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('native export lease blocks confirmation until export finishes', (
    tester,
  ) async {
    await tester.pumpWidget(captureApp());
    await tester.pumpAndSettle();
    await tester.tap(clear);
    await tester.pumpAndSettle();
    final opened = Completer<void>();
    final picker = Completer<bool?>();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(maiaEngineChannel, (call) async {
      if (call.method == 'saveSamplingData') {
        opened.complete();
        return picker.future;
      }
      return null;
    });
    try {
      late Future<void> export;
      export = capture.saveDocument();
      await finishAsync(tester, opened.future);
      await tester.pump();
      expect(tester.widget<TextButton>(confirm).onPressed, isNull);
      expect(capture.clearCalls, 0);
      picker.complete(null);
      await finishAsync(tester, export);
      await tester.pumpAndSettle();
      expect(tester.widget<TextButton>(confirm).onPressed, isNotNull);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(capture.records, 1);
    } finally {
      if (!picker.isCompleted) picker.complete(null);
      messenger.setMockMethodCallHandler(maiaEngineChannel, null);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets(
    'retained data controls and scrollable help in every locale at large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final locale in AppLocalizations.supportedLocales) {
        final strings = await AppLocalizations.delegate.load(locale);
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: const Scaffold(
              body: SingleChildScrollView(child: SamplingCaptureSettings()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final toggle = find.byKey(const ValueKey('sampling-data-toggle'));
        expect(tester.widget<SettingsInfoSwitch>(toggle).value, false);
        expect(find.text(strings.samplingData), findsOneWidget);
        expect(find.byTooltip(strings.clearSamplingData), findsOneWidget);
        await tester.ensureVisible(clear);
        await tester.tap(clear);
        await tester.pumpAndSettle();
        expect(find.text(strings.samplingClearConfirmation), findsOneWidget);
        expect(find.text(strings.samplingDeleteData), findsOneWidget);
        final semantics = tester.ensureSemantics();
        expect(tester.getSemantics(confirm).label, strings.samplingDeleteData);
        semantics.dispose();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text(strings.cancel));
        await tester.tap(find.text(strings.cancel));
        await tester.pumpAndSettle();
        expect(capture.records, 1);
        expect(capture.clearCalls, 0);
        await tester.ensureVisible(
          find.byTooltip(strings.saveMaiaSamplingData),
        );
        await tester.tap(find.byTooltip(strings.saveMaiaSamplingData));
        await tester.pumpAndSettle();
        expect(find.text(strings.samplingDataHelp), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(strings.close));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(
          find.byKey(const ValueKey('sampling-actions')),
        );
        await tester.tap(find.byKey(const ValueKey('sampling-actions')));
        await tester.pumpAndSettle();
        expect(find.byType(PopupMenuItem<String>), findsNWidgets(2));
        expect(find.text(strings.samplingSave), findsOneWidget);
        expect(find.text(strings.samplingShare), findsOneWidget);
        await tester.tap(find.text(strings.samplingSave));
        await tester.pumpAndSettle();
        expect(find.text(strings.samplingReadable), findsOneWidget);
        await tester.tap(find.text(strings.cancel));
        await tester.pumpAndSettle();
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}

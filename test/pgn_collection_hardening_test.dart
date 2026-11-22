import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

const game =
    '[Event "Transfer"]\n[White "Alice"]\n[Black "Bob"]\n\n1. e4 {note} e5 *';

class ControlledImportRepository extends SessionRepository {
  ControlledImportRepository(super.directory);
  final entered = Completer<void>();
  final finished = Completer<PgnImportResult>();
  void Function(PgnImportProgress)? update;
  @override
  Future<PgnImportResult> importCollection(
    PgnCollection collection, {
    void Function(PgnImportProgress)? onProgress,
  }) {
    update = onProgress;
    entered.complete();
    return finished.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late SessionRepository store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('maia-import-hardening-');
    store = SessionRepository(dir);
  });
  tearDown(() async {
    ActiveSessionStore.setTestRepository(null);
    await dir.delete(recursive: true);
  });

  Future<Map<String, String>> files() async => {
    await for (final file in dir.list(recursive: true, followLinks: false))
      if (file is File) file.path: base64Encode(await file.readAsBytes()),
  };

  test(
    'skip duplicates within the collection and on repeat import after restart',
    () async {
      final collection = await PgnCollection.parse('$game\n\n$game');
      final first = await store.importCollection(collection);
      expect(first.imported, 1);
      expect(first.duplicates, 1);
      final before = await files();
      final second = await SessionRepository(dir).importCollection(collection);
      expect(second.imported, 0);
      expect(second.duplicates, 2);
      expect(await files(), before);
      expect(await store.recent(), hasLength(1));
    },
  );

  test('existing active and archived games match despite line endings and outer whitespace', () async {
    await store.save({'type': 'game', 'pgn': game, 'recentState': 'active'});
    await store.startNew();
    final other = game.replaceFirst('Transfer', 'Current');
    await store.save({'type': 'game', 'pgn': other, 'recentState': 'active'});
    final before = await files();
    final imported = await store.importCollection(
      await PgnCollection.parse(
        ' \n${game.replaceAll('\n', '\r\n')}\n\n$other\n ',
      ),
    );
    expect(imported.imported, 0);
    expect(imported.duplicates, 2);
    expect(await files(), before);
  });

  test('metadata, comment, variation and clock differences are kept', () async {
    final versions = [
      game,
      game.replaceFirst('Alice', 'Carol'),
      game.replaceFirst('note', 'another note'),
      game.replaceFirst('e5 *', 'e5 (1... c5) *'),
      game.replaceFirst('note', '[%clk 0:04:58]'),
      game.replaceFirst('[Event', '[Source "Personal"]\n[Event'),
    ];
    final result = await store.importCollection(
      await PgnCollection.parse(versions.join('\n\n')),
    );
    expect(result.imported, versions.length);
    expect(result.duplicates, 0);
    expect(await store.recent(), hasLength(versions.length));
  });

  test(
    'duplicate detection uses readable archive backup without modifying it',
    () async {
      final imported = await store.importCollection(
        await PgnCollection.parse('$game\n$game'),
      );
      expect(imported.imported, 1);
      final record =
          (await dir
                  .list(recursive: true)
                  .where((e) => e is File && e.path.endsWith('.json'))
                  .toList())
              .single;
      await File(record.path).copy('${record.path}.previous');
      await File(record.path).writeAsString('{broken');
      final before = await files();
      final result = await store.importCollection(
        await PgnCollection.parse('$game\n$game'),
      );
      expect(result.imported, 0);
      expect(result.duplicates, 2);
      expect(await files(), before);
    },
  );

  test('startup removes only abandoned import directories, preserving checkpoints and links', () async {
    await store.save({'type': 'game', 'pgn': game, 'recentState': 'active'});
    final active = await File('${dir.path}/active.json').readAsString();
    final abandoned = Directory('${dir.path}/.import-123-456.pending');
    await abandoned.create();
    await File('${abandoned.path}/partial.json.pending')
        .writeAsString('{broken');
    final unrelated = Directory('${dir.path}/.import-other.pending');
    await unrelated.create();
    final outside = await Directory.systemTemp.createTemp(
      'maia-import-link-target-',
    );
    addTearDown(() => outside.delete(recursive: true));
    final target = File('${outside.path}/keep');
    await target.writeAsString('keep');
    await Link('${dir.path}/.import-789-123.pending').create(outside.path);
    await File('${dir.path}/active.json.pending').writeAsString('{partial');
    final restarted = SessionRepository(dir);
    expect((await restarted.load())!['pgn'], game);
    expect(await abandoned.exists(), isFalse);
    expect(await unrelated.exists(), isTrue);
    expect(await target.readAsString(), 'keep');
    expect(await File('${dir.path}/active.json').readAsString(), active);
    expect(await File('${dir.path}/active.json.pending').exists(), isTrue);
    expect(await Link('${dir.path}/.import-789-123.pending').exists(), isTrue);
  });

  test('another repository never cleans a live import staging directory', () async {
    final collection = await PgnCollection.parse(
      List.generate(
        1000,
        (i) => game.replaceFirst('Transfer', 'Live $i'),
      ).join('\n\n'),
    );
    final inspected = Completer<void>();
    Future<void>? inspection;
    final operation = store.importCollection(
      collection,
      onProgress: (progress) {
        // This report follows the duplicate scan and at least one staged write.
        if (progress.completed > collection.games.length + 1 &&
            inspection == null &&
            progress.fraction < 1) {
          inspection = () async {
            final staging = await dir
                .list()
                .where((e) => e is Directory && e.path.endsWith('.pending'))
                .toList();
            expect(staging, hasLength(1));
            expect(await SessionRepository(dir).recent(), isEmpty);
            inspected.complete();
          }();
        }
      },
    );
    expect((await operation).imported, 1000);
    expect(inspection, isNotNull);
    await inspection;
    expect(inspected.isCompleted, isTrue);
    expect(await SessionRepository(dir).recent(), hasLength(1000));
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
      'import progress and duplicate summary at 320px / 200% ${locale.languageCode}',
      (tester) async {
        ActiveSessionStore.setTestRepository(store);
        tester.view.physicalSize = const Size(320, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final strings = await AppLocalizations.delegate.load(locale);
        Future<AnalysisSession?>? operation;
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () =>
                      operation = PgnFiles.importText(context, '$game\n$game'),
                  child: const Text('Import'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Import'));
        await tester.pump();
        expect(
          find.byKey(const ValueKey('pgn-import-progress')),
          findsOneWidget,
        );
        expect(find.text(strings.pgnImportProgress), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(
          find.byKey(const ValueKey('pgn-import-progress')),
          findsOneWidget,
        );
        final summary = strings.pgnCollectionImportSummary(1, 1);
        for (var i = 0; i < 150 && find.text(summary).evaluate().isEmpty; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.text(summary), findsOneWidget);
        await operation;
        await tester.pumpAndSettle();
        expect(summary, isNot(contains('#')));
        expect(find.text(summary), findsOneWidget);
        expect(find.byKey(const ValueKey('pgn-import-progress')), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets('progress becomes determinate and disappears only after commit', (
    tester,
  ) async {
    final controlled = ControlledImportRepository(dir);
    ActiveSessionStore.setTestRepository(controlled);
    Future<AnalysisSession?>? operation;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                operation = PgnFiles.importText(context, '$game\n$game');
              },
              child: const Text('Import'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Import'));
    await tester.pump();
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const ValueKey('pgn-import-progress')),
          )
          .value,
      isNull,
    );
    for (var i = 0; i < 100 && !controlled.entered.isCompleted; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(controlled.entered.isCompleted, isTrue);
    controlled.update!(const PgnImportProgress(5, 10));
    await tester.pump();
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const ValueKey('pgn-import-progress')),
          )
          .value,
      0.5,
    );
    controlled.finished.complete(const PgnImportResult(1, 1));
    await tester.pumpAndSettle();
    await operation;
    expect(find.byKey(const ValueKey('pgn-import-progress')), findsNothing);
    expect(find.text('1 game imported · 1 duplicate skipped'), findsOneWidget);
  });

  testWidgets(
    'invalid input closes progress and propagates the error without writes',
    (tester) async {
      ActiveSessionStore.setTestRepository(store);
      Object? error;
      Future<void>? operation;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  operation = PgnFiles.importText(context, 'not a PGN')
                      .then<void>(
                        (_) {},
                        onError: (Object e) {
                          error = e;
                        },
                      );
                },
                child: const Text('Import'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Import'));
      await tester.pump();
      for (var i = 0; i < 100 && error == null; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      await operation;
      await tester.pumpAndSettle();
      expect(error, isFormatException);
      expect(find.byKey(const ValueKey('pgn-import-progress')), findsNothing);
      expect(await tester.runAsync(files), isEmpty);
    },
  );
}

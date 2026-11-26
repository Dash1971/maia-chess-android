import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

import 'pgn_collection_hardening_test.dart'
    show ControlledImportRepository, game;
import 'recent_games_pgn_export_test.dart' show annotated, incomplete, setup;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('maia-parser-progress-');
  });
  tearDown(() async {
    PgnFiles.setTestParser(null);
    ActiveSessionStore.setTestRepository(null);
    await directory.delete(recursive: true);
  });

  test('parsing reports validated source progress including comments, Unicode, variations and BOM', () async {
    final updates = <double>[];
    final parsed = await PgnCollection.parse(
      '\ufeff$annotated\n$incomplete\n$setup',
      onProgress: (p) {
        expect(p.completed, inInclusiveRange(0, p.total));
        updates.add(p.fraction);
      },
    );
    expect(parsed.games, hasLength(3));
    expect(updates.first, 0);
    expect(updates.last, 1);
    expect(updates.any((v) => v > 0 && v < 1), isTrue);
    expect(updates, orderedEquals([...updates]..sort()));
    final count = updates.length;
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(updates, hasLength(count));
  });

  test(
    'invalid later game reports no completion and publishes no files',
    () async {
      final updates = <double>[];
      await expectLater(
        PgnCollection.parse(
          '$incomplete\n\n[Event "Invalid"]\n\n1. e5 *',
          onProgress: (p) => updates.add(p.fraction),
        ),
        throwsFormatException,
      );
      expect(updates.first, 0);
      expect(updates, everyElement(lessThan(1)));
      final count = updates.length;
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(updates, hasLength(count));
      expect(await directory.list().isEmpty, isTrue);
    },
  );

  test('oversized PGN rejects without a completed progress report', () async {
    final updates = <double>[];
    await expectLater(
      PgnCollection.parse(
        'x' * (AnalysisSession.maxPgnBytes + 1),
        onProgress: (p) => updates.add(p.fraction),
      ),
      throwsFormatException,
    );
    expect(updates, everyElement(lessThan(1)));
  });

  Future<void> pumpUntil(WidgetTester tester, bool Function() ready) async {
    for (var i = 0; i < 150 && !ready(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(ready(), isTrue);
  }

  bool hasDimming(WidgetTester tester) => tester
      .widgetList<ModalBarrier>(find.byType(ModalBarrier))
      .any((barrier) => (barrier.color?.a ?? 0) > 0);

  Future<BuildContext> importScreen(
    WidgetTester tester, {
    VoidCallback? onTap,
  }) async {
    late BuildContext page;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              page = context;
              return TextButton(
                onPressed: onTap ?? () {},
                child: const Text('Original screen'),
              );
            },
          ),
        ),
      ),
    );
    return page;
  }

  for (final single in [true, false]) {
    testWidgets(
      'quick ${single ? 'single' : 'collection'} import never shows or dims a dialog',
      (tester) async {
        final parsed = (await tester.runAsync(
          () => PgnCollection.parse(single ? game : '$game\n$incomplete'),
        ))!;
        PgnFiles.setTestParser((_, {onProgress}) async => parsed);
        final store = ControlledImportRepository(directory);
        store.finished.complete(const PgnImportResult(2, 0));
        ActiveSessionStore.setTestRepository(store);
        final context = await importScreen(tester);
        var finished = false;
        AnalysisSession? session;
        final operation =
            PgnFiles.importText(
              context,
              single ? game : '$game\n$incomplete',
            ).then((result) {
              session = result;
              finished = true;
            });
        await tester.pump();
        expect(find.byType(AlertDialog), findsNothing);
        expect(hasDimming(tester), isFalse);
        // Advance no virtual time while the small operation completes.
        await pumpUntil(tester, () => finished);
        await operation;
        await tester.pump();
        expect(session, single ? isNotNull : isNull);
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(AlertDialog), findsNothing);
        expect(hasDimming(tester), isFalse);
        expect(ModalRoute.of(context)!.isCurrent, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'slow parser reveals at 300ms and progress never resets between phases',
    (tester) async {
      final collection = (await tester.runAsync(
        () => PgnCollection.parse('$game\n$incomplete'),
      ))!;
      final parse = Completer<PgnCollection>();
      void Function(PgnImportProgress)? update;
      PgnFiles.setTestParser((_, {onProgress}) {
        update = onProgress;
        return parse.future;
      });
      final store = ControlledImportRepository(directory);
      ActiveSessionStore.setTestRepository(store);
      var taps = 0;
      final context = await importScreen(tester, onTap: () => taps++);
      final operation = PgnFiles.importText(context, '$game\n$incomplete');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 299));
      expect(find.byType(AlertDialog), findsNothing);
      expect(hasDimming(tester), isFalse);
      await tester.tap(find.text('Original screen'), warnIfMissed: false);
      expect(taps, 0);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Original screen'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(hasDimming(tester), isTrue);
      double value() => tester
          .widget<LinearProgressIndicator>(
            find.byKey(const ValueKey('pgn-import-progress')),
          )
          .value!;
      expect(value(), 0);
      update!(const PgnImportProgress(1, 4));
      await tester.pump();
      expect(value(), 0.125);
      update!(const PgnImportProgress(3, 4));
      await tester.pump();
      expect(value(), 0.375);
      parse.complete(collection);
      await tester.pump();
      expect(store.entered.isCompleted, isTrue);
      await tester.pump();
      expect(value(), 0.5);
      store.update!(const PgnImportProgress(0, 10));
      await tester.pump();
      expect(value(), 0.5);
      store.update!(const PgnImportProgress(5, 10));
      await tester.pump();
      expect(value(), 0.75);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(AlertDialog), findsOneWidget);
      store.finished.complete(const PgnImportResult(2, 0));
      await tester.pumpAndSettle();
      await operation;
      await tester.pump();
      expect(find.byType(AlertDialog), findsNothing);
      expect(ModalRoute.of(context)!.isCurrent, isTrue);
      await tester.tap(find.text('Original screen'));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    },
  );

  for (final duringParsing in [true, false]) {
    testWidgets(
      '${duringParsing ? 'parse' : 'storage'} failure removes delayed feedback',
      (tester) async {
        final collection = (await tester.runAsync(
          () => PgnCollection.parse('$game\n$incomplete'),
        ))!;
        final parse = Completer<PgnCollection>();
        PgnFiles.setTestParser((_, {onProgress}) => parse.future);
        final store = ControlledImportRepository(directory);
        ActiveSessionStore.setTestRepository(store);
        final context = await importScreen(tester);
        Object? failure;
        final operation = PgnFiles.importText(context, '$game\n$incomplete')
            .then<void>(
              (_) {},
              onError: (Object error) {
                failure = error;
              },
            );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(AlertDialog), findsOneWidget);
        if (duringParsing) {
          parse.completeError(const FormatException('Invalid PGN'));
        } else {
          parse.complete(collection);
          await tester.pump();
          store.finished.completeError(
            const FileSystemException('Storage unavailable'),
          );
        }
        await tester.pumpAndSettle();
        await operation;
        await tester.pump();
        expect(
          failure,
          duringParsing ? isFormatException : isA<FileSystemException>(),
        );
        expect(find.byType(AlertDialog), findsNothing);
        expect(ModalRoute.of(context)!.isCurrent, isTrue);
        expect(await tester.runAsync(() => directory.list().isEmpty), isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('quick parsing failure never reveals a late dialog', (
    tester,
  ) async {
    PgnFiles.setTestParser((_, {onProgress}) async {
      throw const FormatException('Invalid PGN');
    });
    final context = await importScreen(tester);
    Object? failure;
    final operation = PgnFiles.importText(context, 'invalid').then<void>(
      (_) {},
      onError: (Object error) {
        failure = error;
      },
    );
    await tester.pump();
    await operation;
    await tester.pump(const Duration(seconds: 1));
    expect(failure, isFormatException);
    expect(find.byType(AlertDialog), findsNothing);
    expect(hasDimming(tester), isFalse);
    expect(ModalRoute.of(context)!.isCurrent, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'disposing the screen before the delay leaves no late timer or dialog',
    (tester) async {
      final collection = (await tester.runAsync(
        () => PgnCollection.parse('$game\n$incomplete'),
      ))!;
      final parse = Completer<PgnCollection>();
      PgnFiles.setTestParser((_, {onProgress}) => parse.future);
      final context = await importScreen(tester);
      final operation = PgnFiles.importText(context, '$game\n$incomplete');
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 500));
      parse.complete(collection);
      await tester.pump();
      await operation;
      await tester.pump();
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

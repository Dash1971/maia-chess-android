import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'recent_games_pgn_export_test.dart' show annotated, incomplete, setup;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late SessionRepository store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('maia-collection-');
    store = SessionRepository(dir);
  });
  tearDown(() async {
    ActiveSessionStore.setTestRepository(null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, null);
    await dir.delete(recursive: true);
  });

  Future<Map<String, String>> files() async => {
    await for (final file in dir.list(recursive: true))
      if (file is File) file.path: base64Encode(await file.readAsBytes()),
  };

  Future<void> waitForMessage(WidgetTester tester, String message) async {
    for (var i = 0; i < 150 && find.text(message).evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text(message), findsOneWidget);
  }

  test(
    'collection parsing retains every game, comments, variations and clocks',
    () async {
      const fake =
          '[Event "Real"]\n\n{ Comment\n\n[Event "Fake"]\n* 0-1 }\n1. e4 *';
      final parsed = await PgnCollection.parse(
        '$annotated\n$incomplete\n$setup\n$fake',
      );
      expect(parsed.games, hasLength(4));
      expect(parsed.games.first, contains('[%clk 0:04:58]'));
      expect(parsed.games.first, contains('café'));
      expect(parsed.games.first, contains('1... c5'));
      expect(parsed.games.last, contains('Fake'));
      expect(parsed.games[2], contains('[FEN '));
      expect(
        (await PgnCollection.parse('1. e4 *\n1. d4 *')).games,
        hasLength(2),
      );
      expect(() => parsed.games.add('*'), throwsUnsupportedError);
    },
  );

  test('invalid later game, broken comments, or trailing garbage rejects the whole collection', () async {
    for (final source in [
      '$incomplete\n\n[Event "Invalid"]\n\n1. e5 *',
      '$incomplete\n\n[Event "Broken"]\n\n{ unclosed',
      '$incomplete\n\nnot a PGN',
      '$incomplete\n\n[SetUp "1"]\n[FEN "8/8/8/8/8/8/8/8 w - - 0 1"]\n\n*',
    ]) {
      await expectLater(PgnCollection.parse(source), throwsFormatException);
    }
    expect(await files(), isEmpty);
  });

  test('import and export accept the same 5 MiB UTF-8 boundary', () async {
    expect(AnalysisSession.maxPgnBytes, 5 * 1024 * 1024);
    expect(RecentGamesPgn.maxBytes, AnalysisSession.maxPgnBytes);
    const prefix = '[Event "Large"]\n\n';
    for (final delta in [0, 1]) {
      final text =
          '$prefix{${'x' * (AnalysisSession.maxPgnBytes + delta - prefix.length - 4)}} *';
      expect(utf8.encode(text).length, AnalysisSession.maxPgnBytes + delta);
      if (delta == 0) {
        expect((await PgnCollection.parse(text)).games, hasLength(1));
      } else {
        await expectLater(PgnCollection.parse(text), throwsFormatException);
      }
    }
    final unicode = '{${'😀' * (AnalysisSession.maxPgnBytes ~/ 4)}} *';
    expect(unicode.length, lessThan(AnalysisSession.maxPgnBytes));
    await expectLater(PgnCollection.parse(unicode), throwsFormatException);
  });

  test('a greater-than-2-MiB exported collection imports completely', () async {
    const prefix = '[Event "Large"]\n\n';
    final game = '$prefix{${'x' * (1100 * 1024)}} 1. e4 *';
    final exported = await RecentGamesPgn.export([
      'a',
      'b',
      'c',
    ], (id) async => game.replaceFirst('Large', 'Large $id'));
    expect(utf8.encode(exported).length, greaterThan(2 * 1024 * 1024));
    expect(
      (await store.importCollection(await PgnCollection.parse(exported)))
          .imported,
      3,
    );
    final recent = await SessionRepository(dir).recent();
    expect(recent, hasLength(3));
    for (final entry in recent) {
      expect(entry.isIncomplete, isTrue);
      expect(await store.readPgnForExport(entry.id), contains('1. e4 *'));
    }
  });

  test('import retains current checkpoints, dates, names and every game; open/delete work after restart', () async {
    await store.save({
      'type': 'game',
      'pgn': '[Event "Current"]\n\n$incomplete',
      'recentState': 'active',
    });
    final before = await files();
    final collection = await PgnCollection.parse(
      '$annotated\n$incomplete\n$setup',
    );
    expect((await store.importCollection(collection)).imported, 3);
    final after = await files();
    for (final entry in before.entries) {
      expect(after[entry.key], entry.value);
    }
    final reopened = SessionRepository(dir);
    final games = await reopened.recent();
    expect(games, hasLength(3));
    final named = games.firstWhere((g) => g.title == 'Player — Maia');
    expect(named.history.playedOn, '2026-11-13');
    expect(named.resultLabel, '1-0');
    expect(games.where((g) => g.isIncomplete), hasLength(2));
    expect((await reopened.open(named.id))!['importedPgn'], isTrue);
    await reopened.deleteMany(games.map((g) => g.id));
    expect(
      (await SessionRepository(
        dir,
      ).recent()).where((g) => g.data['importedPgn'] == true),
      isEmpty,
    );
  });

  test('failed publication exposes no partial import and leaves the active game untouched', () async {
    await store.save({
      'type': 'game',
      'pgn': '[Event "Current"]\n\n$incomplete',
      'recentState': 'active',
    });
    await File('${dir.path}/games').writeAsString('obstruction');
    final before = await files();
    final collection = await PgnCollection.parse('$annotated\n$incomplete');
    await expectLater(
      store.importCollection(collection),
      throwsA(isA<FileSystemException>()),
    );
    expect(await files(), before);
    expect(
      await dir
          .list()
          .where((entry) => entry.path.endsWith('.pending'))
          .isEmpty,
      isTrue,
    );
  });

  test(
    'Mobile Maia names retain the recorded rating and player side',
    () async {
      final collection = await PgnCollection.parse(
        '[White "Player"]\n[Black "Maia-3 79M (2400)"]\n\n1. e4 *\n\n'
        '[White "Maia-3 79M (1200)"]\n[Black "Player"]\n\n1. d4 *',
      );
      await store.importCollection(collection);
      final games = await store.recent();
      final white = games.firstWhere((g) => g.data['playerIsWhite'] == true);
      final black = games.firstWhere((g) => g.data['playerIsWhite'] == false);
      expect(white.data['elo'], 2400);
      expect(black.data['elo'], 1200);
      expect((await store.open(black.id))!['elo'], 1200);
    },
  );

  for (final method in ['file', 'paste']) {
    testWidgets('$method collection import keeps the current analysis board', (
      tester,
    ) async {
      ActiveSessionStore.setTestRepository(store);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            maiaEngineChannel,
            (call) async =>
                call.method == 'openPgnFile' ? '$annotated\n$incomplete' : null,
          );
      final initial = AnalysisSession.fromPgn('1. c4 *');
      await tester.pumpWidget(
        MaterialApp(
          home: AnalysisBoardPage(
            initialSession: initial,
            maiaElo: 1600,
            evaluator: (_) async => const StockfishReview(0, ''),
            maiaEvaluator: (_, _) async => null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('analysis-actions-menu')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(method == 'file' ? 'Open PGN file' : 'Load PGN'),
      );
      if (method == 'paste') {
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField),
          '$annotated\n$incomplete',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Load'));
      }
      await waitForMessage(tester, '2 games added to Recent games.');
      expect(
        tester.widget<ReviewPage>(find.byType(ReviewPage)).positions,
        initial.positions,
      );
      expect(
        (await tester.runAsync(() => store.recent()))!
            .where((g) => g.data['importedPgn'] == true),
        hasLength(2),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
      '${locale.languageCode} collection completion fits at 200% text',
      (tester) async {
        ActiveSessionStore.setTestRepository(store);
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final strings = await AppLocalizations.delegate.load(locale);
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
                      PgnFiles.importText(context, '$annotated\n$incomplete'),
                  child: const Text('Import'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Import'));
        final message = strings.pgnCollectionImported(2);
        expect(message, isNot(contains('#')));
        await waitForMessage(tester, message);
        expect((await tester.runAsync(() => store.recent()))!, hasLength(2));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets('opening then saving an imported game keeps its player names', (
    tester,
  ) async {
    ActiveSessionStore.setTestRepository(store);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
    await tester.runAsync(() async {
      store = SessionRepository(dir);
      await store.importCollection(
        await PgnCollection.parse(
          '[White "Alice"]\n[Black "Maia-3 79M (2000)"]\n\n1. e4 *\n\n$incomplete',
        ),
      );
      final game = (await store.recent()).firstWhere(
        (g) => g.title.startsWith('Alice'),
      );
      await store.open(game.id);
    });
    await tester.pumpWidget(const MaterialApp(home: GamePage()));
    for (
      var i = 0;
      i < 150 &&
          find.byKey(const ValueKey('game-home-button')).evaluate().isEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.byKey(const ValueKey('game-home-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    for (var i = 0; i < 50; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byKey(const ValueKey('game-home-button')).evaluate().isEmpty) {
        break;
      }
    }
    final games = (await tester.runAsync(() => store.recent()))!;
    expect(
      games.where((g) => g.title == 'Alice — Maia-3 79M (2000)'),
      hasLength(1),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'a shared collection adds all games without replacing the active game or unblocking recovery',
    (tester) async {
      ActiveSessionStore.setTestRepository(store);
      SharedPreferences.setMockInitialValues({'sessionRestoreBlockedV1': true});
      await tester.runAsync(() async {
        await store.save({
          'type': 'game',
          'pgn': '[Event "Current"]\n\n$incomplete',
          'recentState': 'active',
        });
      });
      final before = (await tester.runAsync(files))!;
      var pending = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(maiaEngineChannel, (call) async {
            if (call.method == 'getPendingPgn' && pending) {
              pending = false;
              return '$annotated\n$incomplete';
            }
            return null;
          });
      await tester.pumpWidget(const MaterialApp(home: GamePage()));
      for (
        var i = 0;
        i < 100 &&
            find.text('2 games added to Recent games.').evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(
        find.text('2 games added to Recent games.'),
        findsOneWidget,
        reason:
            'pending=$pending; visible=${tester.widgetList<Text>(find.byType(Text)).map((w) => w.data).whereType<String>().toList()}',
      );
      expect(find.byType(ReviewPage), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('sessionRestoreBlockedV1'), isTrue);
      final after = (await tester.runAsync(files))!;
      for (final entry in before.entries) {
        expect(after[entry.key], entry.value);
      }
      expect((await tester.runAsync(() => store.recent()))!, hasLength(2));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}

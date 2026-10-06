import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/launch_game.dart' show TestClock;

String _dateTag(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}.'
    '${date.month.toString().padLeft(2, '0')}.'
    '${date.day.toString().padLeft(2, '0')}';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, null),
  );

  String dateOf(Map<String, dynamic> saved) {
    return RegExp(
      r'^\[Date\s+"([^"]+)"\]',
      multiLine: true,
    ).firstMatch(saved['pgn'] as String)!.group(1)!;
  }

  testWidgets('explicit Home start uses local PGN date and resume keeps it', (
    tester,
  ) async {
    final beforeStart = DateTime.now();
    await tester.pumpWidget(const MaterialApp(home: GamePage()));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Start game'));
    await tester.pumpAndSettle();
    final saved = (await ActiveSessionStore.load())!;
    expect(
      dateOf(saved),
      isIn([_dateTag(beforeStart), _dateTag(DateTime.now())]),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const MaterialApp(home: GamePage()));
    await tester.pumpAndSettle();
    expect(dateOf((await ActiveSessionStore.load())!), dateOf(saved));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'restoring historic game preserves date but explicit reset replaces it',
    (tester) async {
      await ActiveSessionStore.save({
        'type': 'game',
        'pgn': '[Date "2001.02.03"]\n\n1. e4 e5 *',
        'timePreset': 'unlimited',
        'playerIsWhite': true,
      });
      await tester.pumpWidget(const MaterialApp(home: GamePage()));
      await tester.pumpAndSettle();
      expect(dateOf((await ActiveSessionStore.load())!), '2001.02.03');
      await tester.tap(find.byKey(const ValueKey('new-game-button')));
      await tester.pumpAndSettle();
      final beforeReset = DateTime.now();
      await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
      await tester.pumpAndSettle();
      final saved = (await ActiveSessionStore.load())!;
      expect(
        dateOf(saved),
        isIn([_dateTag(beforeReset), _dateTag(DateTime.now())]),
      );
      expect(saved['uciMoves'], isEmpty);
      expect(saved['pgn'], isNot(contains('2001.02.03')));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Continue from here starts a new dated game from historical PGN',
    (tester) async {
      final source = AnalysisSession.fromPgn(
        '[Date "2001.02.03"]\n\n1. e4 e5 *',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: AnalysisBoardPage(
            initialSession: source,
            maiaElo: 1600,
            evaluator: (_) async => const StockfishReview(0, 'g1f3'),
            maiaEvaluator: (_, _) async => null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('analysis-actions-menu')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continue from here'));
      await tester.tap(find.text('Continue from here'));
      await tester.pumpAndSettle();
      final beforeStart = DateTime.now();
      await tester.tap(find.byKey(const ValueKey('continuation-start-game')));
      await tester.pumpAndSettle();
      final saved = (await ActiveSessionStore.load())!;
      expect(
        dateOf(saved),
        isIn([_dateTag(beforeStart), _dateTag(DateTime.now())]),
      );
      expect(saved['pgn'], isNot(contains('2001.02.03')));
      expect(source.pgn, contains('[Date "2001.02.03"]'));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'future inner schema shows persistent warning without changing preferences',
    (tester) async {
      final future = jsonEncode({
        'schema': 2,
        'type': 'game',
        'pgn': '1. e4 *',
      });
      SharedPreferences.setMockInitialValues({'activeSessionV1': future});
      await tester.pumpWidget(const MaterialApp(home: GamePage()));
      await tester.pumpAndSettle();
      final strings = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(strings.savedGameVersionUnsupported), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Start game'),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Analysis Board'),
            )
            .onPressed,
        isNull,
      );
      expect(
        (await SharedPreferences.getInstance()).getString('activeSessionV1'),
        future,
      );
      await expectLater(
        ActiveSessionStore.startNew(),
        throwsA(isA<UnsupportedSessionFormatException>()),
      );
      await expectLater(
        ActiveSessionStore.save({'type': 'game', 'pgn': '*'}),
        throwsA(isA<UnsupportedSessionFormatException>()),
      );
      expect(
        (await SharedPreferences.getInstance()).getString('activeSessionV1'),
        future,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('future legacy preference blocks empty repository mutation', (
    tester,
  ) async {
    final directory = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('maia-future-legacy-'),
    ))!;
    final store = (await tester.runAsync(
      () async => SessionRepository(directory),
    ))!;
    ActiveSessionStore.setTestRepository(store);
    await tester.pump();
    addTearDown(() async {
      ActiveSessionStore.setTestRepository(null);
      await tester.runAsync(() => directory.delete(recursive: true));
    });
    final future = jsonEncode({'schema': 2, 'type': 'game', 'pgn': '1. e4 *'});
    SharedPreferences.setMockInitialValues({'activeSessionV1': future});
    await tester.runAsync(() async {
      await expectLater(
        ActiveSessionStore.startNew(gameStartedAt: DateTime.now()),
        throwsA(isA<UnsupportedSessionFormatException>()),
      );
      expect(await Directory(directory.path).list().isEmpty, isTrue);
    });
    expect(
      (await SharedPreferences.getInstance()).getString('activeSessionV1'),
      future,
    );
  });

  testWidgets(
    'committed start survives lifecycle and a covering route without stale save',
    (tester) async {
      final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('maia-start-lifecycle-'),
      ))!;
      final store = (await tester.runAsync(
        () async => _DelayedStartRepository(directory),
      ))!;
      ActiveSessionStore.setTestRepository(store);
      await tester.pump();
      addTearDown(() async {
        ActiveSessionStore.setTestRepository(null);
        await tester.runAsync(() => directory.delete(recursive: true));
      });
      Future<void> flushIo({bool Function()? until}) async {
        for (var i = 0; i < (until == null ? 5 : 250); i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump(const Duration(milliseconds: 20));
          if (until?.call() == true) return;
        }
        if (until != null) {
          expect(
            until(),
            isTrue,
            reason: 'Storage did not settle within 5 seconds',
          );
        }
      }

      await tester.runAsync(
        () => store.save({
          'schema': 1,
          'type': 'game',
          'pgn': '[Date "2001.02.03"]\n\n1. e4 e5 *',
          'timePreset': 'unlimited',
          'playerIsWhite': true,
        }),
      );
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          navigatorObservers: [maiaRouteObserver],
          home: const GamePage(),
        ),
      );
      await flushIo(
        until: () =>
            find.byKey(const ValueKey('new-game-button')).evaluate().isNotEmpty,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('new-game-button')));
      await tester.pumpAndSettle();
      store.delayNext = true;
      await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
      await flushIo(until: () => store.committed.isCompleted);
      expect(store.committed.isCompleted, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Covered')),
        ),
      );
      await tester.pumpAndSettle();
      await flushIo();
      expect(await tester.runAsync(store.load), isNull);
      final beforeReleaseSaves = store.saves;
      store.release.complete();
      await flushIo(until: () => store.saves > beforeReleaseSaves);
      final saved = (await tester.runAsync(store.load))!;
      expect(saved['pgn'], isNot(contains('2001.02.03')));
      expect(saved['uciMoves'], isEmpty);
      expect(saved['clockPaused'], isTrue);
      expect(saved['recentState'], 'active');
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('game-board')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await flushIo();
    },
  );
  testWidgets('failed reset retains game and resumes its clock', (
    tester,
  ) async {
    final directory = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('maia-reset-failure-'),
    ))!;
    final store = (await tester.runAsync(
      () async => _FailingDiscardRepository(directory),
    ))!;
    ActiveSessionStore.setTestRepository(store);
    addTearDown(() async {
      ActiveSessionStore.setTestRepository(null);
      await tester.runAsync(() => directory.delete(recursive: true));
    });
    await tester.runAsync(
      () => store.save({
        'schema': 1,
        'type': 'game',
        'pgn': '[Date "2001.02.03"]\n\n1. e4 e5 *',
        'timePreset': 'blitz',
        'playerIsWhite': true,
        'whiteMillis': 5000,
        'blackMillis': 5000,
      }),
    );
    final clocks = <TestClock>[];
    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(
          clockFactory: () {
            final clock = TestClock(0);
            clocks.add(clock);
            return clock;
          },
        ),
      ),
    );
    Future<void> until(bool Function() condition) async {
      for (var i = 0; i < 250 && !condition(); i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(
        condition(),
        isTrue,
        reason: 'Storage did not settle within 5 seconds',
      );
    }

    await until(
      () => find.byKey(const ValueKey('new-game-button')).evaluate().isNotEmpty,
    );
    expect(clocks.last.isRunning, isTrue);
    final initialClocks = clocks.length;
    await tester.tap(find.byKey(const ValueKey('new-game-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    final strings = await AppLocalizations.delegate.load(const Locale('en'));
    await until(
      () => find.text(strings.gameStorageFailed).evaluate().isNotEmpty,
    );
    expect(clocks.length, initialClocks + 1);
    expect(clocks.last.isRunning, isTrue);
    expect(find.text('e4'), findsOneWidget);
    expect(find.text('e5'), findsOneWidget);
    final retained = (await tester.runAsync(
      () => SessionRepository(directory).load(),
    ))!;
    expect(dateOf(retained), '2001.02.03');
    expect(retained['pgn'], contains('1. e4 e5'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

class _DelayedStartRepository extends SessionRepository {
  _DelayedStartRepository(super.directory);
  bool delayNext = false;
  int saves = 0;

  @override
  Future<void> save(Map<String, dynamic> value) async {
    await super.save(value);
    saves++;
  }

  final committed = Completer<void>();
  final release = Completer<void>();

  @override
  Future<void> startNew({DateTime? gameStartedAt}) async {
    await super.startNew(gameStartedAt: gameStartedAt);
    if (delayNext && gameStartedAt != null) {
      delayNext = false;
      committed.complete();
      await release.future;
    }
  }
}

class _FailingDiscardRepository extends SessionRepository {
  _FailingDiscardRepository(super.directory);
  @override
  Future<void> discardActive() async =>
      throw const FileSystemException('Deliberate test failure');
}

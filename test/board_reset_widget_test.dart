import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

import 'package:chess/chess.dart' as chess;
import 'package:chessground/chessground.dart' as cg;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/electronic_board.dart';
import 'support/sampling_replay.dart' show readExport;

class ResetBoard extends SimulatedElectronicBoard {
  final ledEvents = <String>[];

  @override
  Future<void> setLeds(Iterable<String> squares) async {
    final state = squares.join(',');
    ledEvents.add('request:$state');
    await super.setLeds(squares);
    ledEvents.add('complete:$state');
  }

  @override
  void status(ElectronicBoardConnectionState state) => controller.add(
    ElectronicBoardEvent(
      type: 'status',
      connectionState: state,
      connectionSession: 'reset-board-session',
      boardId: 'reset-board',
    ),
  );
  void newGame() => controller.add(
    const ElectronicBoardEvent(
      type: 'newGame',
      connectionSession: 'reset-board-session',
      boardId: 'reset-board',
    ),
  );
}

/// Hold completion after the real empty reset checkpoint has been persisted.
/// This exposes the interval before _startGame requests physical setup guidance.
class HeldResetRepository extends SessionRepository {
  HeldResetRepository(super.directory);

  final release = Completer<void>();
  bool held = false;
  Map<String, Object?>? lastSaved;

  @override
  Future<void> save(Map<String, Object?> data) async {
    await super.save(data);
    lastSaved = Map.of(data);
    if (data['chessnutResetPending'] == true && !held) {
      held = true;
      await release.future;
    }
  }
}

/// Expose the legitimate gap between discarding the old game and committing
/// the replacement, independent of the host's disk speed.
class DelayedResetRepository extends SessionRepository {
  DelayedResetRepository(super.directory);

  final release = Completer<void>();
  bool waiting = false;

  @override
  Future<void> save(Map<String, Object?> data) async {
    if (data['chessnutResetPending'] == true && !waiting) {
      waiting = true;
      await release.future;
    }
    await super.save(data);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ResetBoard board;
  late WidgetTester currentTester;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    board = ResetBoard();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
  });
  tearDown(() async {
    ActiveSessionStore.setTestRepository(null);
    await board.close();
    await currentTester.runAsync(() => directory.delete(recursive: true));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, null);
  });

  Future<void> flush(WidgetTester tester) async {
    for (var i = 0; i < 100; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 10));
    }
  }

  Future<void> waitFor(
    WidgetTester tester,
    bool Function() ready,
    String description,
  ) async {
    final deadline = Stopwatch()..start();
    while (!ready() && deadline.elapsed < const Duration(seconds: 10)) {
      // Yield to real file I/O, then process widget futures in fake time.
      // Success depends on the observed event, not on a fixed sleep budget.
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(ready(), isTrue, reason: description);
  }

  Future<T> driveCapture<T>(
    WidgetTester tester,
    Future<T> Function() operation,
  ) async {
    var done = false;
    T? result;
    Object? error;
    unawaited(
      operation().then(
        (value) {
          result = value;
          done = true;
        },
        onError: (Object failure) {
          error = failure;
          done = true;
        },
      ),
    );
    for (var i = 0; i < 200 && !done; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(done, isTrue, reason: 'capture filesystem operation completed');
    if (error != null) throw error!;
    return result as T;
  }

  Future<Map<String, dynamic>> waitForSaved(
    WidgetTester tester,
    bool Function(Map<String, dynamic>) ready,
    String description,
  ) async {
    final deadline = Stopwatch()..start();
    Map<String, dynamic>? saved;
    while (deadline.elapsed < const Duration(seconds: 10)) {
      saved = await tester.runAsync<Map<String, dynamic>?>(
        () => SessionRepository(directory).load(),
      );
      await tester.pump(const Duration(milliseconds: 10));
      if (saved != null && ready(saved)) return saved;
    }
    fail('Timed out waiting for $description; last checkpoint: $saved');
  }

  Future<void> initialize(
    WidgetTester tester, {
    SessionRepository Function(Directory)? repositoryFactory,
  }) async {
    currentTester = tester;
    directory = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('maia-reset-widget-'),
    ))!;
    final repository = (await tester.runAsync(
      () async =>
          repositoryFactory?.call(directory) ?? SessionRepository(directory),
    ))!;
    ActiveSessionStore.setTestRepository(repository);
  }

  Future<void> launch(
    WidgetTester tester, {
    bool playerIsWhite = true,
    Future<Float32List> Function(List<String>, int)? evaluator,
    MaiaPlaySettings? sampling,
    SessionRepository Function(Directory)? repositoryFactory,
  }) async {
    await initialize(tester, repositoryFactory: repositoryFactory);
    await tester.runAsync(
      () => ActiveSessionStore.save({
        'type': 'game',
        'pgn': '1. d4 d5 *',
        'playerIsWhite': true,
      }),
    );
    await tester.runAsync(() => ActiveSessionStore.startNew());
    await tester.runAsync(
      () => ActiveSessionStore.save({
        'type': 'game',
        'pgn': playerIsWhite ? '1. e4 e5 *' : '1. e4 *',
        'playerIsWhite': playerIsWhite,
        'elo': 1800,
        'maiaUseMoveHistory': true,
        if (sampling != null) 'maiaSampling': sampling.toJson(),
        'flipped': true,
        'electronicBoard': 'chessnut-go',
        'clockPaused': true,
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(
          electronicBoardTransport: board,
          maiaEvaluator: evaluator,
        ),
      ),
    );
    await flush(tester);
    await tester.pumpAndSettle();
    board.status(ElectronicBoardConnectionState.ready);
    final position = chess.Chess()..move('e4');
    if (playerIsWhite) position.move('e5');
    board.position(position.fen);
    await flush(tester);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'first board press and Cancel preserve active and unrelated games',
    (tester) async {
      await launch(tester);
      final active = await tester.runAsync<Map<String, dynamic>?>(
        () => SessionRepository(directory).load(),
      );
      board.newGame();
      board.newGame();
      await flush(tester);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('Press NEW GAME again'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        (await tester.runAsync<Map<String, dynamic>?>(
          () => SessionRepository(directory).load(),
        ))!['pgn'],
        active!['pgn'],
      );
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await flush(tester);
      await tester.pumpAndSettle();
      expect(
        (await tester.runAsync<Map<String, dynamic>?>(
          () => SessionRepository(directory).load(),
        ))!['pgn'],
        active['pgn'],
      );
      expect(
        await tester.runAsync(() => SessionRepository(directory).recent()),
        hasLength(2),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await flush(tester);
      await tester.pumpAndSettle();
    },
  );

  testWidgets('phone confirmation discards only active game and guides setup', (
    tester,
  ) async {
    await launch(tester);
    await tester.tap(find.byKey(const ValueKey('new-game-button')));
    await flush(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await flush(tester);
    await tester.pumpAndSettle();
    expect(
      await tester.runAsync<Map<String, dynamic>?>(
        () => SessionRepository(directory).load(),
      ),
      containsPair('uciMoves', isEmpty),
    );
    final recent = (await tester.runAsync(
      () => SessionRepository(directory).recent(),
    ))!;
    expect(recent, hasLength(1));
    expect(
      recent.where((g) => g.data['pgn'].toString().contains('d4')),
      hasLength(1),
    );
    expect(board.leds.last.toSet(), {'e2', 'e4', 'e7', 'e5'});
    // Intermediate physical placements belong to setup and cannot create moves.
    final partial = chess.Chess()..move('e4');
    board.position(partial.fen);
    await flush(tester);
    await tester.pumpAndSettle();
    expect(
      await tester.runAsync<Map<String, dynamic>?>(
        () => SessionRepository(directory).load(),
      ),
      containsPair('uciMoves', isEmpty),
    );
    expect(board.leds.last.toSet(), {'e2', 'e4'});
    board.position(chess.Chess.DEFAULT_POSITION);
    await flush(tester);
    await tester.pumpAndSettle();
    expect(board.leds.last, isEmpty);
    expect(
      await tester.runAsync<Map<String, dynamic>?>(
        () => SessionRepository(directory).load(),
      ),
      containsPair('uciMoves', isEmpty),
    );
    expect(find.widgetWithText(FilledButton, 'Start game'), findsNothing);
    expect(find.byKey(const ValueKey('new-game-button')), findsOneWidget);
    final started = (await tester.runAsync<Map<String, dynamic>?>(
      () => SessionRepository(directory).load(),
    ))!;
    expect(started['chessnutResetPending'], isNull);
    expect(started['clockPaused'], false);
    await tester.pumpWidget(const SizedBox.shrink());
    await flush(tester);
    await tester.pumpAndSettle();
  });
  testWidgets('completed reset retains its result and unrelated archives', (
    tester,
  ) async {
    await initialize(tester);
    await tester.runAsync(
      () => ActiveSessionStore.save({
        'type': 'game',
        'pgn': '1. d4 d5 *',
        'playerIsWhite': true,
      }),
    );
    await tester.runAsync(() => ActiveSessionStore.startNew());
    await tester.runAsync(
      () => ActiveSessionStore.save({
        'type': 'game',
        'pgn': '1. f3 e5 2. g4 Qh4# 0-1',
        'recentState': 'completed',
        'playerIsWhite': true,
      }),
    );
    await tester.pumpWidget(
      MaterialApp(home: GamePage(electronicBoardTransport: board)),
    );
    await flush(tester);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await flush(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('new-game-button')));
    await flush(tester);
    await tester.pumpAndSettle();
    expect(
      find.text(
        (await AppLocalizations.delegate.load(const Locale('en')))
            .yourCompletedGameWillRemainInRecentGames,
      ),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Start new game'));
    await flush(tester);
    await tester.pumpAndSettle();
    final recent = (await tester.runAsync(
      () => SessionRepository(directory).recent(),
    ))!;
    expect(
      recent.where((game) => game.data['pgn'].toString().contains('Qh4#')),
      hasLength(1),
    );
    expect(
      recent.where((game) => game.data['pgn'].toString().contains('d4')),
      hasLength(1),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await flush(tester);
    await tester.pumpAndSettle();
  });

  for (final completion in ['during save', 'after save', 'after setup']) {
    for (final delayLed in [false, true]) {
      testWidgets(
        'reset rejects a delayed Maia completion and its LED guidance '
        '(Maia $completion; '
        'LED ${delayLed ? 'reconnected' : 'immediate'})',
        (tester) async {
          late HeldResetRepository repository;
          await initialize(
            tester,
            repositoryFactory: (directory) =>
                repository = HeldResetRepository(directory),
          );
          final pending = Completer<Float32List>();
          final ledCompletion = Completer<void>();
          addTearDown(() {
            if (!pending.isCompleted) pending.complete(Float32List(4352));
            if (!repository.release.isCompleted) repository.release.complete();
            if (!ledCompletion.isCompleted) ledCompletion.complete();
          });
          var requests = 0;
          await tester.runAsync(
            () => ActiveSessionStore.save({
              'type': 'game',
              'pgn': '1. e4 *',
              'playerIsWhite': true,
              'electronicBoard': 'chessnut-go',
              'clockPaused': false,
            }),
          );
          await tester.pumpWidget(
            MaterialApp(
              home: GamePage(
                electronicBoardTransport: board,
                maiaEvaluator: (_, _) {
                  requests++;
                  return pending.future;
                },
              ),
            ),
          );
          await flush(tester);
          await tester.pumpAndSettle();
          board.status(ElectronicBoardConnectionState.ready);
          final physical = chess.Chess()..move('e4');
          board.position(physical.fen);
          await waitFor(
            tester,
            () => requests == 1,
            'old Maia request started',
          );
          await tester.tap(find.byKey(const ValueKey('new-game-button')));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
          await waitFor(
            tester,
            () => repository.held,
            'reset checkpoint saved',
          );

          // The game is already empty on disk, but save completion (and thus
          // reset LED setup) is still held. A snapshot here was the old race.
          expect(
            await tester.runAsync(() => SessionRepository(directory).load()),
            containsPair('uciMoves', isEmpty),
          );
          expect(board.leds.last, isEmpty);
          if (completion == 'during save') {
            pending.complete(Float32List(4352));
            await tester.pump();
            expect(board.leds.last, isEmpty);
          }
          if (delayLed) board.writeGate = ledCompletion;
          repository.release.complete();
          await waitFor(
            tester,
            () => board.leds.last.join(',') == 'e2,e4',
            'reset requests the actual pawn replacement guidance',
          );
          if (completion == 'after save') {
            // Correct reset guidance arrives even with Maia still pending.
            expect(pending.isCompleted, isFalse);
            pending.complete(Float32List(4352));
            await tester.pump();
          }
          expect(board.leds.last, ['e2', 'e4']);
          expect(requests, 1);
          expect(
            await tester.runAsync(() => SessionRepository(directory).load()),
            containsPair('uciMoves', isEmpty),
          );

          if (delayLed) {
            // Reconnect while the previous connection's LED acknowledgement
            // is outstanding. New guidance must complete first; the retired
            // connection's completion must not restore its state/start Maia.
            board.status(ElectronicBoardConnectionState.disconnected);
            board.controller.add(
              const ElectronicBoardEvent(
                type: 'status',
                connectionState: ElectronicBoardConnectionState.ready,
                connectionSession: 'reset-board-reconnected',
                boardId: 'reset-board',
              ),
            );
            physical.move('d5');
            board.position(physical.fen);
            await tester.pump(const Duration(seconds: 2));
            await waitFor(
              tester,
              () => board.ledEvents.contains('complete:d5,d7,e2,e4'),
              'newer LED request completes before the old acknowledgement',
            );
            expect(board.ledEvents, isNot(contains('complete:e2,e4')));
            ledCompletion.complete();
            await tester.pump();
            expect(board.ledEvents, contains('complete:e2,e4'));
            expect(board.leds.last, ['d5', 'd7', 'e2', 'e4']);
            expect(requests, 1);
            expect(
              await tester.runAsync(() => SessionRepository(directory).load()),
              containsPair('uciMoves', isEmpty),
            );
          }
          // Completing physical setup clears guidance without inventing a move.
          board.position(chess.Chess.DEFAULT_POSITION);
          await waitFor(
            tester,
            () => board.leds.last.isEmpty,
            'setup LEDs clear',
          );
          await tester.pumpAndSettle();
          await waitFor(
            tester,
            () =>
                repository.lastSaved?['clockPaused'] == false &&
                repository.lastSaved?['chessnutResetPending'] != true,
            'physical setup finishes and the new game resumes',
          );
          if (completion == 'after setup') {
            pending.complete(Float32List(4352));
            await tester.pump();
          }
          expect(
            tester
                .widget<cg.Chessboard>(find.byKey(const ValueKey('game-board')))
                .controller
                .fen,
            chess.Chess.DEFAULT_POSITION,
          );
          expect(board.leds.last, isEmpty);
          expect(requests, 1);
          expect(
            await tester.runAsync(() => SessionRepository(directory).load()),
            containsPair('uciMoves', isEmpty),
          );
          await tester.pumpWidget(const SizedBox.shrink());
          await flush(tester);
          await tester.pumpAndSettle();
        },
      );
    }
  }
  testWidgets(
    'completion while reset is open refreshes dialog and keeps result',
    (tester) async {
      await initialize(tester);
      await tester.runAsync(
        () => ActiveSessionStore.save({
          'type': 'game',
          'pgn': '1. f3 e5 2. g4 *',
          'playerIsWhite': false,
          'electronicBoard': 'chessnut-go',
          'clockPaused': false,
        }),
      );
      await tester.pumpWidget(
        MaterialApp(home: GamePage(electronicBoardTransport: board)),
      );
      await flush(tester);
      await tester.pumpAndSettle();
      board.status(ElectronicBoardConnectionState.ready);
      final physical = chess.Chess()
        ..move('f3')
        ..move('e5')
        ..move('g4');
      board.position(physical.fen);
      await flush(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('new-game-button')));
      await flush(tester);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Reset'), findsOneWidget);
      physical.move('Qh4#');
      board.position(physical.fen);
      await flush(tester);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Start new game'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Start new game'));
      await flush(tester);
      await tester.pumpAndSettle();
      final recent = (await tester.runAsync(
        () => SessionRepository(directory).recent(),
      ))!;
      expect(
        recent.where((game) => game.data['pgn'].toString().contains('Qh4#')),
        hasLength(1),
      );
      // Completed-game archival and new-session persistence are asynchronous.
      // Wait for the committed checkpoint, not a fixed number of widget frames.
      Map<String, dynamic>? reset;
      for (var attempt = 0; attempt < 50; attempt++) {
        reset = await tester.runAsync<Map<String, dynamic>?>(() async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return SessionRepository(directory).load();
        });
        await tester.pump();
        if (reset?['chessnutResetPending'] == true) break;
      }
      expect(reset, isNotNull);
      expect(reset!['chessnutResetPending'], true);
      expect(reset['uciMoves'], isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      await flush(tester);
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'second deliberate hardware press confirms the existing dialog once',
    (tester) async {
      await launch(tester);
      board.newGame();
      await flush(tester);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      board.newGame();
      board.newGame();
      await flush(tester);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Start game'), findsNothing);
      expect(
        find.byKey(const ValueKey('chessnut-status-banner')),
        findsOneWidget,
      );
      await waitFor(tester, () {
        final squares = board.leds.last.toSet();
        return squares.length == 4 &&
            squares.containsAll({'e2', 'e4', 'e7', 'e5'});
      }, 'reset guidance LEDs');
      expect(board.leds.last.toSet(), {'e2', 'e4', 'e7', 'e5'});
      expect(
        await tester.runAsync<Map<String, dynamic>?>(
          () => SessionRepository(directory).load(),
        ),
        containsPair('uciMoves', isEmpty),
      );
      final recent = (await tester.runAsync(
        () => SessionRepository(directory).recent(),
      ))!;
      expect(recent, hasLength(1));
      expect(
        recent.where((g) => g.data['pgn'].toString().contains('d4')),
        hasLength(1),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await flush(tester);
      await tester.pumpAndSettle();
    },
  );

  for (final playerIsWhite in [true, false]) {
    testWidgets(
      'reset keeps ${playerIsWhite ? "White" : "Black"}, rating and history; starts only after setup',
      (tester) async {
        // A contrary home preference must not change the restored player's side.
        SharedPreferences.setMockInitialValues({
          maiaPlaySidePreferenceKey: playerIsWhite ? 'black' : 'white',
        });
        var requests = 0;
        late DelayedResetRepository repository;
        await launch(
          tester,
          playerIsWhite: playerIsWhite,
          repositoryFactory: (directory) =>
              repository = DelayedResetRepository(directory),
          evaluator: (_, _) async {
            requests++;
            return Float32List(4352);
          },
        );
        board.newGame();
        await flush(tester);
        await tester.pumpAndSettle();
        board.newGame();
        await flush(tester);
        await tester.pumpAndSettle();
        await waitFor(tester, () => repository.waiting, 'reset save started');
        expect(
          await tester.runAsync<Map<String, dynamic>?>(
            () => SessionRepository(directory).load(),
          ),
          isNull,
          reason: 'The discarded game must not survive while reset is saving.',
        );
        expect(requests, 0, reason: 'Maia must wait for the reset checkpoint.');
        repository.release.complete();
        Map<String, dynamic>? checkpoint;
        // File I/O is real asynchronous work: pumpAndSettle only waits for
        // widget frames, so it cannot guarantee that the save has committed.
        final deadline = Stopwatch()..start();
        while (deadline.elapsed < const Duration(seconds: 10)) {
          checkpoint = await tester.runAsync<Map<String, dynamic>?>(
            () => SessionRepository(directory).load(),
          );
          await tester.pump();
          if (checkpoint?['chessnutResetPending'] == true) break;
        }
        expect(checkpoint, containsPair('chessnutResetPending', true));
        var saved = checkpoint!;
        expect(saved['playerIsWhite'], playerIsWhite);
        expect(saved['elo'], 1800);
        expect(saved['maiaUseMoveHistory'], true);
        expect(saved['historyPrefix'], isEmpty);
        expect(saved['flipped'], true);
        expect(saved['chessnutResetPending'], true);
        expect(saved['clockPaused'], true);
        expect(saved['timePreset'], 'unlimited');
        expect(requests, 0);
        expect(saved['uciMoves'], isEmpty);
        expect(find.widgetWithText(FilledButton, 'Start game'), findsNothing);
        board.position((chess.Chess()..move('e4')).fen);
        await flush(tester);
        expect(requests, 0);
        expect(board.leds.last.toSet(), {'e2', 'e4'});
        board.position(chess.Chess.DEFAULT_POSITION);
        await flush(tester);
        await tester.pumpAndSettle();
        saved = await waitForSaved(
          tester,
          (data) =>
              data['chessnutResetPending'] == null &&
              data['clockPaused'] == false &&
              (data['uciMoves'] as List?)?.length == (playerIsWhite ? 0 : 1),
          'completed board setup checkpoint',
        );
        expect(saved['chessnutResetPending'], isNull);
        expect(saved['clockPaused'], false);
        expect(requests, playerIsWhite ? 0 : 1);
        expect(saved['uciMoves'], hasLength(playerIsWhite ? 0 : 1));
        // Duplicate board snapshots cannot start another inference or reset again.
        board.position(chess.Chess.DEFAULT_POSITION);
        await flush(tester);
        expect(requests, playerIsWhite ? 0 : 1);
        await tester.pumpWidget(const SizedBox.shrink());
        await flush(tester);
      },
    );
  }

  for (final variety in [false, true]) {
    testWidgets(
      'Chessnut reset preserves saved sampling with variety $variety despite contrary preferences',
      (tester) async {
        final profile = MaiaPlaySettings(
          temperature: 0,
          topP: 0,
          maxOpeningVariety: variety,
        );
        SharedPreferences.setMockInitialValues({
          'temperatureV2': 0.5,
          'topPV2': 0.95,
          'maxOpeningVarietyV1': !variety,
        });
        // Capture the first actual decision after setup as well as the saved
        // profile; serialization alone would miss a reset using preferences.
        final captureDirectory = (await tester.runAsync(
          () => Directory.systemTemp.createTemp('maia-reset-sampling-'),
        ))!;
        final capture = SamplingCapture(directory: captureDirectory);
        SamplingCapture.instance = capture;
        await driveCapture(tester, () => capture.setEnabled(true));
        addTearDown(() async {
          capture.dispose();
          SamplingCapture.instance = SamplingCapture();
          await tester.runAsync(() => captureDirectory.delete(recursive: true));
        });
        var requests = 0;
        await launch(
          tester,
          playerIsWhite: false,
          sampling: profile,
          evaluator: (_, _) async {
            requests++;
            return Float32List(4352);
          },
        );
        await tester.tap(find.byKey(const ValueKey('new-game-button')));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
        final checkpoint = await waitForSaved(
          tester,
          (data) => data['chessnutResetPending'] == true,
          'sampling-preserving reset checkpoint',
        );
        expect(checkpoint['maiaSampling'], profile.toJson());
        expect(checkpoint['uciMoves'], isEmpty);
        expect(requests, 0);

        board.position(chess.Chess.DEFAULT_POSITION);
        final played = await waitForSaved(
          tester,
          (data) =>
              data['chessnutResetPending'] == null &&
              (data['uciMoves'] as List?)?.length == 1,
          'first Maia move after physical reset setup',
        );
        expect(played['maiaSampling'], profile.toJson());
        expect(requests, 1);
        await flush(tester);
        final records = await driveCapture(tester, () => readExport(capture));
        final sampling = records.single['sampling'] as Map;
        expect(sampling['configuredTemperature'], 0.0);
        expect(sampling['configuredTopP'], 0.0);
        expect(sampling['maxOpeningVariety'], variety);
        expect(sampling['openingVarietyApplied'], variety);
        expect(sampling['fullMoveNumber'], 1);
        expect(sampling['effectiveTemperature'], variety ? 1.0 : 0.0);
        expect(sampling['effectiveTopP'], variety ? 1.0 : 0.0);
        expect(sampling['mode'], variety ? 'random' : 'argmax');
        await tester.pumpWidget(const SizedBox.shrink());
        await flush(tester);
      },
    );
  }

  testWidgets(
    'reset waits across disconnect and background; phone fallback can continue',
    (tester) async {
      var requests = 0;
      await launch(
        tester,
        playerIsWhite: false,
        evaluator: (_, _) async {
          requests++;
          return Float32List(4352);
        },
      );
      board.newGame();
      await flush(tester);
      await tester.pumpAndSettle();
      board.newGame();
      await flush(tester);
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      board.position(chess.Chess.DEFAULT_POSITION);
      await flush(tester);
      expect(requests, 0);
      board.status(ElectronicBoardConnectionState.disconnected);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      board.status(ElectronicBoardConnectionState.ready);
      await flush(tester);
      expect(requests, 0); // Pre-disconnect match cannot start the game.
      board.status(ElectronicBoardConnectionState.disconnected);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('chessnut-play-in-app')));
      await flush(tester);
      await tester.pumpAndSettle();
      expect(requests, 1);
      final saved = await waitForSaved(
        tester,
        (data) =>
            data['electronicBoard'] == null &&
            data['chessnutResetPending'] == null,
        'phone fallback checkpoint',
      );
      expect(saved['electronicBoard'], isNull);
      expect(saved['chessnutResetPending'], isNull);
      expect(saved['playerIsWhite'], false);
      await tester.pumpWidget(const SizedBox.shrink());
      await flush(tester);
    },
  );

  testWidgets('saved reset resumes waiting after app restart', (tester) async {
    await initialize(tester);
    await tester.runAsync(
      () => ActiveSessionStore.save({
        'type': 'game', 'pgn': '*', 'playerIsWhite': false,
        'electronicBoard': 'chessnut-go', 'chessnutResetPending': true,
        'clockPaused':
            false, // Pending setup overrides even stale pause metadata.
      }),
    );
    var requests = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(
          electronicBoardTransport: board,
          maiaEvaluator: (_, _) async {
            requests++;
            return Float32List(4352);
          },
        ),
      ),
    );
    await flush(tester);
    await tester.pumpAndSettle();
    board.status(ElectronicBoardConnectionState.ready);
    board.position((chess.Chess()..move('e4')).fen);
    await flush(tester);
    expect(requests, 0);
    expect(board.leds.last.toSet(), {'e2', 'e4'});
    board.position(chess.Chess.DEFAULT_POSITION);
    await flush(tester);
    await tester.pumpAndSettle();
    expect(requests, 1);
    final saved = (await tester.runAsync<Map<String, dynamic>?>(
      () => SessionRepository(directory).load(),
    ))!;
    expect(saved['chessnutResetPending'], isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await flush(tester);
  });

  testWidgets(
    'a superseded setup snapshot cannot start Maia after a delayed LED write',
    (tester) async {
      var requests = 0;
      await launch(
        tester,
        playerIsWhite: false,
        evaluator: (_, _) async {
          requests++;
          return Float32List(4352);
        },
      );
      board.newGame();
      await flush(tester);
      await tester.pumpAndSettle();
      board.newGame();
      await flush(tester);
      await tester.pumpAndSettle();
      final write = Completer<void>();
      board.writeGate = write;
      board.position(chess.Chess.DEFAULT_POSITION);
      await tester.pump(const Duration(milliseconds: 10));
      // The pieces changed again while the write completing setup was outstanding.
      board.position((chess.Chess()..move('e4')).fen);
      write.complete();
      await flush(tester);
      expect(requests, 0);
      expect(board.leds.last.toSet(), {'e2', 'e4'});
      board.position(chess.Chess.DEFAULT_POSITION);
      await flush(tester);
      expect(requests, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await flush(tester);
    },
  );

  testWidgets(
    'setup completed behind a menu starts after dismissal without another board packet',
    (tester) async {
      var requests = 0;
      await launch(
        tester,
        playerIsWhite: false,
        evaluator: (_, _) async {
          requests++;
          return Float32List(4352);
        },
      );
      board.newGame();
      await flush(tester);
      await tester.pumpAndSettle();
      board.newGame();
      await flush(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('game-actions-menu')));
      await tester.pumpAndSettle();
      board.position(chess.Chess.DEFAULT_POSITION);
      await flush(tester);
      expect(requests, 0);
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await flush(tester);
      expect(requests, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await flush(tester);
    },
  );
}

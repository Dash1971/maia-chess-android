import 'dart:typed_data';
import 'dart:async';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/electronic_board.dart';

const before = 'r3k2r/pppp1ppp/2n5/4P3/8/8/PPP2PPP/R3K2R b KQkq - 0 11';
const target = 'r3k2r/ppp2ppp/2n5/3pP3/8/8/PPP2PPP/R3K2R w KQkq d6 0 12';

class PermissionBoard extends SimulatedElectronicBoard {
  bool denied = true;
  @override
  Future<void> connect() async {
    if (denied) {
      connects++;
      throw PlatformException(code: 'bluetooth_permission_denied');
    }
    await super.connect();
  }
}

class ChoosingBoard extends SimulatedElectronicBoard
    implements DiscoverableBoardTransport {
  final selected = <String>[];
  @override
  Future<void> connect() async {
    connects++;
    status(ElectronicBoardConnectionState.choosing);
    controller.add(
      const ElectronicBoardEvent(
        type: 'candidates',
        candidates: [
          BoardCandidate('go', 'Chessnut Go', BoardKind.chessnut),
          BoardCandidate('air', 'Chessnut Air', BoardKind.chessnut),
          BoardCandidate('prototype', 'DGT Pegasus', BoardKind.pegasus),
        ],
      ),
    );
  }

  @override
  Future<void> discoverBoards() => connect();
  @override
  Future<void> selectBoard(String id) async {
    selected.add(id);
    controller.add(
      ElectronicBoardEvent(
        type: 'status',
        connectionState: ElectronicBoardConnectionState.ready,
        boardKind: BoardKind.chessnut,
        boardId: id,
        connectionSession: 'selected-$id',
        deviceName: 'Chessnut Air',
      ),
    );
    position(chess.Chess.DEFAULT_POSITION);
  }

  @override
  Future<void> reconnectBoard(String? boardId) => connect();
  @override
  Future<void> startBoardGame(String player, String connectionSession) async {}
  @override
  Future<void> movePiece(String uci, String connectionSession) async {}
  @override
  Future<void> acknowledgeMove(bool accepted, String connectionSession) async {}
  @override
  Future<void> confirmPosition(String connectionSession) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late SimulatedElectronicBoard board;
  var predictions = 0;
  setUp(() async {
    board = SimulatedElectronicBoard();
    predictions = 0;
    SharedPreferences.setMockInitialValues({
      maiaPlaySidePreferenceKey: PlayerSide.black.name,
      maiaTimePresetPreferenceKey: TimePreset.custom.name,
      maiaCustomMinutesPreferenceKey: 12,
      maiaCustomIncrementPreferenceKey: 4,
    });
    await ActiveSessionStore.clear();
    messenger.setMockMethodCallHandler(maiaEngineChannel, (call) async {
      if (call.method == 'predict') {
        predictions++;
        return Float32List(4352);
      }
      return null;
    });
  });
  tearDown(() async {
    messenger.setMockMethodCallHandler(maiaEngineChannel, null);
    await ActiveSessionStore.clear();
    await board.close();
  });
  Future<void> screen(
    WidgetTester tester, {
    bool home = false,
    Locale locale = const Locale('en'),
    double scale = 1,
  }) async {
    MaiaInferenceQueue.resetForTesting();
    tester.view.physicalSize = scale > 1
        ? const Size(320, 568)
        : const Size(600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        navigatorObservers: [maiaRouteObserver],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: home
            ? GamePage(electronicBoardTransport: board)
            : AnalysisBoardPage(
                initialSession: AnalysisSession.fromFen(target),
                historyPrefix: const [before],
                useMoveHistory: true,
                maiaElo: 1500,
                electronicBoardTransport: board,
                evaluator: (_) async => const StockfishReview(0, 'e1d1'),
                maiaEvaluator: (_, _) async => null,
              ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final tile = find.byKey(ValueKey(key));
    final toggle = find.descendant(of: tile, matching: find.byType(Switch));
    final f = toggle.evaluate().isNotEmpty ? toggle : tile;
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  }

  Future<void> open(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    await tapKey(tester, 'analysis-actions-menu');
    final strings = await AppLocalizations.delegate.load(locale);
    await tester.ensureVisible(find.text(strings.continueFromHere));
    await tester.tap(find.text(strings.continueFromHere));
    await tester.pumpAndSettle();
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  testWidgets(
    'custom continuation waits for matching pieces, preserves FEN and untimed settings',
    (tester) async {
      await screen(tester);
      await open(tester);
      await tapKey(tester, 'continuation-use-board');
      expect(board.connects, 1);
      expect(find.text('Chessnut connected'), findsOneWidget);
      expect(find.text('Unlimited'), findsOneWidget);
      await tapKey(tester, 'continuation-start-game');
      final game = tester.widget<GamePage>(find.byType(GamePage));
      expect(game.startingFen, target);
      expect(game.startingSide, PlayerSide.black);
      expect(game.startingTimePreset, TimePreset.unlimited);
      expect(game.startingPositionHistory, [before, target]);
      var saved = (await ActiveSessionStore.load())!;
      expect(saved['chessnutResetPending'], true);
      expect(saved['pgn'], contains(target));
      expect(predictions, 0);
      expect(
        board.leds.last.toSet(),
        ChessnutProtocol.mismatchSquares(
          ChessnutProtocol.pieceMapFromFen(chess.Chess.DEFAULT_POSITION),
          ChessnutProtocol.pieceMapFromFen(target),
        ).toSet(),
      );
      board.status(ElectronicBoardConnectionState.disconnected);
      board.position(target); // Late pre-reconnect placement is not readiness.
      await tester.pumpAndSettle();
      expect(predictions, 0);
      board.status(ElectronicBoardConnectionState.ready);
      await tester.pumpAndSettle();
      expect(predictions, 0);
      board.position(target);
      await tester.pumpAndSettle();
      expect(predictions, 1);
      saved = (await ActiveSessionStore.load())!;
      expect(saved['chessnutResetPending'], isNull);
      expect(saved['timePreset'], TimePreset.unlimited.name);
      expect(
        (await SharedPreferences.getInstance()).getString(
          maiaTimePresetPreferenceKey,
        ),
        TimePreset.custom.name,
      );
      expect(tester.takeException(), isNull);
      await dispose(tester);
    },
  );

  testWidgets(
    'cancel a new connection preserves analysis; phone clock restores on toggle off',
    (tester) async {
      await screen(tester);
      await open(tester);
      await tapKey(tester, 'continuation-use-board');
      await tapKey(tester, 'continuation-use-board');
      expect(board.disconnects, 1);
      expect(
        find.byKey(const ValueKey('continuation-custom-minutes')),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(tester.widget<ReviewPage>(find.byType(ReviewPage)).positions, [
        target,
      ]);
      expect(find.byType(GamePage), findsNothing);
      await dispose(tester);
    },
  );

  testWidgets(
    'existing home connection is borrowed without reconnect; cancel restores owner',
    (tester) async {
      await screen(tester, home: true);
      await tapKey(tester, 'home-chessnut-toggle');
      expect(board.connects, 1);
      final analysis = find.widgetWithText(OutlinedButton, 'Analysis Board');
      await tester.ensureVisible(analysis);
      await tester.tap(analysis);
      await tester.pumpAndSettle();
      await open(tester);
      await tapKey(tester, 'continuation-use-board');
      expect(board.connects, 1);
      expect(find.text('Chessnut connected'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(board.disconnects, 0);
      await open(tester);
      await tapKey(tester, 'continuation-use-board');
      await tapKey(tester, 'continuation-start-game');
      expect(board.connects, 1);
      expect(
        (await ActiveSessionStore.load())!['electronicBoard'],
        'chessnut-go',
      );
      await dispose(tester);
    },
  );

  testWidgets(
    'permission failure retries without losing position or controls',
    (tester) async {
      await board.close();
      board = PermissionBoard();
      await screen(tester);
      await open(tester);
      await tapKey(tester, 'continuation-use-board');
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('continuation-start-game')),
            )
            .onPressed,
        isNull,
      );
      (board as PermissionBoard).denied = false;
      await tapKey(tester, 'continuation-board-retry');
      expect(board.connects, 2);
      expect(find.text('Chessnut connected'), findsOneWidget);
      await tapKey(tester, 'continuation-start-game');
      expect(
        tester.widget<GamePage>(find.byType(GamePage)).startingFen,
        target,
      );
      await tapKey(tester, 'chessnut-play-in-app');
      expect((await ActiveSessionStore.load())!['electronicBoard'], isNull);
      expect(predictions, 1);
      await dispose(tester);
    },
  );

  testWidgets('borrow discovery in progress without replacing candidate IDs', (
    tester,
  ) async {
    await tester.runAsync(board.close);
    final discovery = ChoosingBoard();
    board = discovery;
    // Existing owner has a scan in progress underneath analysis.
    final original = BoardConnectionSession.forTransport(board).lease();
    await original.connect();
    await screen(tester);
    await open(tester);
    await tapKey(tester, 'continuation-use-board');
    expect(board.connects, 1);
    expect(
      find.byKey(const ValueKey('board-candidate-prototype')),
      findsNothing,
    );
    await tapKey(tester, 'board-candidate-air');
    expect(discovery.selected, ['air']);
    expect(find.text('Chessnut Air connected'), findsOneWidget);
    await tapKey(tester, 'continuation-start-game');
    expect(tester.widget<GamePage>(find.byType(GamePage)).startingFen, target);
    expect(board.connects, 1);
    await dispose(tester);
    unawaited(original.release());
    await tester.pumpAndSettle();
  });

  testWidgets('backgrounding board chooser safely returns to phone controls', (
    tester,
  ) async {
    await tester.runAsync(board.close);
    board = ChoosingBoard();
    await screen(tester);
    await open(tester);
    await tapKey(tester, 'continuation-use-board');
    expect(find.byKey(const ValueKey('board-candidate-air')), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('board-candidate-air')), findsNothing);
    expect(
      find.byKey(const ValueKey('continuation-custom-minutes')),
      findsOneWidget,
    );
    expect(board.disconnects, 1);
    expect(find.byType(GamePage), findsNothing);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('cancel during a slow connection prevents a late game start', (
    tester,
  ) async {
    final gate = Completer<void>();
    board.connectGate = gate;
    await screen(tester);
    await open(tester);
    await tapKey(tester, 'continuation-use-board');
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(GamePage), findsNothing);
    expect(board.disconnects, 1);
    expect(tester.widget<ReviewPage>(find.byType(ReviewPage)).positions, [
      target,
    ]);
    await dispose(tester);
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
      '${locale.languageCode} continuation connection fits compact enlarged text',
      (tester) async {
        await screen(tester, locale: locale, scale: 2);
        await open(tester, locale: locale);
        await tapKey(tester, 'continuation-use-board');
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('continuation-start-game')).hitTestable(),
          findsOneWidget,
        );
        await dispose(tester);
      },
    );
  }
}

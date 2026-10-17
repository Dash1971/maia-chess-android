import 'dart:async';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiscoveryBoard implements DiscoverableBoardTransport {
  final controller = StreamController<ElectronicBoardEvent>.broadcast(
    sync: true,
  );
  final selected = <String>[];
  final reconnects = <String?>[];
  final motorMoves = <String>[];
  final starts = <String>[];
  final confirmations = <String>[];
  final acknowledgements = <bool>[];
  Completer<void>? acknowledgementGate;
  Completer<void>? startGate;
  int discoveries = 0;
  int disconnects = 0;
  @override
  Stream<ElectronicBoardEvent> get events => controller.stream;
  void status(BoardKind kind, {String id = 'selected-board'}) => controller.add(
    ElectronicBoardEvent(
      type: 'status',
      connectionState: ElectronicBoardConnectionState.ready,
      boardKind: kind,
      boardId: id,
      connectionSession: 'session-$id',
    ),
  );
  void candidates() => controller.add(
    const ElectronicBoardEvent(
      type: 'candidates',
      candidates: [
        BoardCandidate('board-one', 'First board', BoardKind.chessnut),
        BoardCandidate('board-two', 'Second board', BoardKind.pegasus),
      ],
    ),
  );
  void bytes(BoardKind kind, List<int> bytes, {String id = 'selected-board'}) =>
      controller.add(
        ElectronicBoardEvent(
          type: 'boardData',
          boardKind: kind,
          connectionSession: 'session-$id',
          data: bytes,
        ),
      );
  @override
  Future<void> connect() => discoverBoards();
  @override
  Future<void> discoverBoards() async {
    discoveries++;
  }

  @override
  Future<void> selectBoard(String id) async {
    selected.add(id);
  }

  @override
  Future<void> reconnectBoard(String? boardId) async {
    reconnects.add(boardId);
  }

  @override
  Future<void> disconnect() async {
    disconnects++;
  }

  @override
  Future<void> setLeds(Iterable<String> squares) async {}
  @override
  Future<void> beep({int frequencyHz = 1000, int durationMs = 200}) async {}
  @override
  Future<void> startBoardGame(String player, String connectionSession) async {
    starts.add(player);
    if (startGate case final gate?) await gate.future;
  }

  @override
  Future<void> movePiece(String uci, String connectionSession) async {
    motorMoves.add(uci);
  }

  @override
  Future<void> acknowledgeMove(bool accepted, String connectionSession) async {
    acknowledgements.add(accepted);
    if (acknowledgementGate case final gate?) await gate.future;
  }

  @override
  Future<void> confirmPosition(String connectionSession) async {
    confirmations.add(connectionSession);
  }
}

class MotorCheckpointRepository extends SessionRepository {
  MotorCheckpointRepository() : super(Directory.systemTemp);
  Map<String, dynamic>? data;
  final pending = Completer<void>();
  final release = Completer<void>();
  bool blocked = false;
  @override
  Future<bool> hasCheckpoint() async => true;
  @override
  Future<Map<String, dynamic>?> load() async => data;
  @override
  Future<void> startNew({DateTime? gameStartedAt}) async {
    data = null;
  }

  @override
  Future<void> save(Map<String, Object?> snapshot) async {
    if (!blocked && snapshot['pendingPhysicalMaiaMove'] != null) {
      blocked = true;
      pending.complete();
      await release.future;
    }
    data = Map<String, dynamic>.from(snapshot);
  }
}

void main() {
  group(
    'Dev prototype board flows',
    devBoardTests,
    skip: appFlavor != 'dev'
        ? 'Run with --flavor dev; Stable rejection is tested separately.'
        : false,
  );
}

void devBoardTests() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DiscoveryBoard board;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    board = DiscoveryBoard();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
  });
  tearDown(() async {
    await board.controller.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, null);
  });
  Future<void> launch(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(
          electronicBoardTransport: board,
          maiaEvaluator: (_, _) async => Float32List(4352),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enable(WidgetTester tester) async {
    await tester.ensureVisible(
      find.byKey(const ValueKey('home-chessnut-toggle')),
    );
    await tester.tap(find.byKey(const ValueKey('home-chessnut-toggle')));
    await tester.pumpAndSettle();
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  FilledButton start(WidgetTester tester) => tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'Start game'),
  );

  test(
    'board labels use recognized products and conservative fallbacks',
    () async {
      final t = await AppLocalizations.delegate.load(const Locale('en'));
      for (final example in [
        ('Chessnut Go', 'Chessnut Go'),
        (' CHESSNUT_AIR_1234 ', 'Chessnut Air'),
        ('Chessnut Pro', 'Chessnut Pro'),
        ('Chessnut', 'Chessnut'),
        ('Smart Chess', 'Chessnut'),
        ('Chessnut Airship', 'Chessnut'),
        ('Chessnut GoPlus', 'Chessnut'),
        ('DGT Pegasus', 'Chessnut'),
        ('', 'Chessnut'),
      ]) {
        expect(
          electronicBoardDisplayName(t, BoardKind.chessnut, example.$1),
          example.$2,
        );
      }
      expect(
        electronicBoardDisplayName(t, BoardKind.chessnut, null),
        'Chessnut',
      );
      expect(
        electronicBoardDisplayName(t, BoardKind.pegasus, null),
        'DGT Pegasus',
      );
      expect(
        electronicBoardDisplayName(t, BoardKind.squareOff, null),
        'Square Off Grand Kingdom',
      );
      expect(
        electronicBoardDisplayName(t, null, 'unknown alias'),
        'Chessboard',
      );
    },
  );

  testWidgets(
    'named status waits for readiness and follows connection identity',
    (tester) async {
      await launch(tester);
      await enable(tester);
      void status(
        ElectronicBoardConnectionState state, {
        BoardKind kind = BoardKind.chessnut,
        String id = 'go',
        String? name,
      }) => board.controller.add(
        ElectronicBoardEvent(
          type: 'status',
          connectionState: state,
          boardKind: kind,
          boardId: id,
          connectionSession: 'session-$id',
          deviceName: name,
        ),
      );
      final statusBox = find.byKey(const ValueKey('chessnut-setup-status'));
      Finder message(String text) =>
          find.descendant(of: statusBox, matching: find.text(text));
      expect(message('Searching for boards…'), findsOneWidget);
      status(ElectronicBoardConnectionState.connected, name: 'Chessnut Go');
      await tester.pumpAndSettle();
      expect(message('Connecting to board…'), findsOneWidget);
      expect(message('Chessnut Go connected'), findsNothing);
      status(ElectronicBoardConnectionState.ready);
      await tester.pumpAndSettle();
      expect(message('Chessnut Go connected'), findsOneWidget);
      // Readiness must not imply that the physical position is correct.
      board.controller.add(
        const ElectronicBoardEvent(
          type: 'position',
          connectionSession: 'session-go',
          position: {},
        ),
      );
      await tester.pumpAndSettle();
      expect(
        message('Set up the standard starting position on your board.'),
        findsOneWidget,
      );
      status(ElectronicBoardConnectionState.disconnected);
      await tester.pumpAndSettle();
      expect(message('Chessnut Go disconnected'), findsOneWidget);
      // A different unnamed Chessnut must not inherit the old model.
      status(ElectronicBoardConnectionState.ready, id: 'unnamed');
      await tester.pumpAndSettle();
      expect(message('Chessnut connected'), findsOneWidget);
      // Late events from the old session must not restore its name or status.
      status(ElectronicBoardConnectionState.ready, name: 'Chessnut Go');
      await tester.pumpAndSettle();
      expect(message('Chessnut connected'), findsOneWidget);
      for (final entry in [
        (BoardKind.pegasus, 'pegasus', 'DGT Pegasus'),
        (BoardKind.squareOff, 'square-off', 'Square Off Grand Kingdom'),
      ]) {
        status(
          ElectronicBoardConnectionState.ready,
          kind: entry.$1,
          id: entry.$2,
        );
        await tester.pumpAndSettle();
        expect(message('${entry.$3} connected'), findsOneWidget);
        status(
          ElectronicBoardConnectionState.disconnected,
          kind: entry.$1,
          id: entry.$2,
        );
        await tester.pumpAndSettle();
        expect(message('${entry.$3} disconnected'), findsOneWidget);
      }
      await dispose(tester);
    },
  );

  testWidgets(
    'in-game disconnect identifies the board without changing recovery',
    (tester) async {
      await launch(tester);
      await enable(tester);
      board.controller.add(
        const ElectronicBoardEvent(
          type: 'status',
          connectionState: ElectronicBoardConnectionState.ready,
          boardKind: BoardKind.chessnut,
          boardId: 'go',
          connectionSession: 'session-go',
          deviceName: 'Chessnut Go',
        ),
      );
      board.controller.add(
        ElectronicBoardEvent(
          type: 'position',
          connectionSession: 'session-go',
          position: ChessnutProtocol.pieceMapFromFen(
            'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Start game'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Start game'));
      await tester.pumpAndSettle();
      board.controller.add(
        const ElectronicBoardEvent(
          type: 'status',
          connectionState: ElectronicBoardConnectionState.disconnected,
          connectionSession: 'session-go',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('chessnut-status-banner')),
          matching: find.text('Chessnut Go disconnected'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('chessnut-inline-reconnect')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('chessnut-play-in-app')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await dispose(tester);
    },
  );

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
      'named board status fits compact large-text UI in ${locale.languageCode}',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
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
            home: GamePage(electronicBoardTransport: board),
          ),
        );
        await tester.pumpAndSettle();
        await enable(tester);
        board.status(BoardKind.squareOff);
        await tester.pumpAndSettle();
        final status = find.byKey(const ValueKey('chessnut-setup-status'));
        await tester.ensureVisible(status);
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: status,
            matching: find.text(
              strings.namedBoardConnected('Square Off Grand Kingdom'),
            ),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        board.controller.add(
          const ElectronicBoardEvent(
            type: 'status',
            connectionState: ElectronicBoardConnectionState.disconnected,
            connectionSession: 'session-selected-board',
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: status,
            matching: find.text(
              strings.namedBoardDisconnected('Square Off Grand Kingdom'),
            ),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await dispose(tester);
      },
    );
  }

  testWidgets(
    'multiple candidates use one chooser and only explicit selection connects',
    (tester) async {
      await launch(tester);
      await enable(tester);
      expect(board.discoveries, 1);
      board.candidates();
      await tester.pumpAndSettle();
      board.candidates();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(board.selected, isEmpty);
      await tester.tap(find.byKey(const ValueKey('board-candidate-board-two')));
      await tester.pumpAndSettle();
      expect(board.selected, ['board-two']);
      expect(board.reconnects, isEmpty);
      await dispose(tester);
    },
  );

  testWidgets(
    'chooser Cancel disconnects and late candidates after toggle off are ignored',
    (tester) async {
      await launch(tester);
      await enable(tester);
      board.candidates();
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(board.disconnects, 1);
      expect(board.selected, isEmpty);
      await enable(tester);
      board.candidates();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(board.discoveries, 1);
      await dispose(tester);
    },
  );

  testWidgets(
    'background dismisses chooser and resume does not select another board',
    (tester) async {
      await launch(tester);
      await enable(tester);
      board.candidates();
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(board.selected, isEmpty);
      expect(board.discoveries, 1);
      expect(board.reconnects, isEmpty);
      await dispose(tester);
    },
  );

  testWidgets('reopened active game reconnects to its recorded identity', (
    tester,
  ) async {
    await ActiveSessionStore.save({
      'type': 'game',
      'pgn': '1. e4 e5 *',
      'electronicBoard': 'chessnut-go',
      'electronicBoardId': 'recorded-board',
      'playerIsWhite': true,
      'clockPaused': true,
    });
    await launch(tester);
    await tester.tap(find.byKey(const ValueKey('chessnut-inline-reconnect')));
    await tester.pumpAndSettle();
    expect(board.reconnects, ['recorded-board']);
    expect(board.discoveries, 0);
    expect(board.selected, isEmpty);
    await dispose(tester);
  });

  testWidgets(
    'legacy Chessnut save can explicitly select its board after reconnect',
    (tester) async {
      await ActiveSessionStore.save({
        'type': 'game',
        'pgn': '1. e4 e5 *',
        'electronicBoard': 'chessnut-go',
        'playerIsWhite': true,
        'clockPaused': true,
      });
      await launch(tester);
      await tester.tap(find.byKey(const ValueKey('chessnut-inline-reconnect')));
      await tester.pumpAndSettle();
      expect(board.reconnects, [null]);
      board.candidates();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('board-candidate-board-two')),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('board-candidate-board-one')));
      await tester.pumpAndSettle();
      expect(board.selected, ['board-one']);
      expect((await ActiveSessionStore.load())!['pgn'], contains('e4'));
      await dispose(tester);
    },
  );

  testWidgets('completed board archive has no automatic connection', (
    tester,
  ) async {
    await ActiveSessionStore.save({
      'type': 'game',
      'pgn': '1. f3 e5 2. g4 Qh4# 0-1',
      'electronicBoard': 'chessnut-go',
      'electronicBoardId': 'recorded-board',
      'playerIsWhite': true,
    });
    await launch(tester);
    expect(board.reconnects, isEmpty);
    expect(board.discoveries, 0);
    expect(find.byKey(const ValueKey('chessnut-status-banner')), findsNothing);
    expect((await ActiveSessionStore.load())!['pgn'], contains('Qh4#'));
    await dispose(tester);
  });

  testWidgets(
    'Pegasus occupancy needs explicit piece identity confirmation before start',
    (tester) async {
      await launch(tester);
      await enable(tester);
      board.status(BoardKind.pegasus);
      board.bytes(BoardKind.pegasus, [
        0x86,
        0,
        67,
        ...List.generate(64, (i) => i < 16 || i >= 48 ? 1 : 0),
      ]);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(start(tester).onPressed, isNull);
      expect(find.byKey(const ValueKey('board-confirm-setup')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('board-confirm-setup')));
      await tester.pumpAndSettle();
      expect(start(tester).onPressed, isNotNull);
      expect(board.starts, isEmpty);
      expect(board.motorMoves, isEmpty);
      await dispose(tester);
    },
  );

  testWidgets(
    'Square Off requires manual setup and uncorrelated OK cannot finish a motor move',
    (tester) async {
      await launch(tester);
      await tester.tap(find.text('Black').first);
      await tester.pumpAndSettle();
      await enable(tester);
      board.status(BoardKind.squareOff);
      await tester.pumpAndSettle();
      expect(start(tester).onPressed, isNull);
      expect(board.starts, isEmpty);
      expect(board.motorMoves, isEmpty);
      await tester.tap(find.byKey(const ValueKey('board-confirm-setup')));
      await tester.pumpAndSettle();
      expect(start(tester).onPressed, isNotNull);
      expect(board.starts, isEmpty);
      await tester.tap(find.widgetWithText(FilledButton, 'Start game'));
      await tester.pumpAndSettle();
      expect(board.starts, ['black']);
      expect(board.motorMoves, hasLength(1));
      final saved = (await ActiveSessionStore.load())!;
      final pending = saved['pendingPhysicalMaiaMove'];
      expect(pending, isNotNull);
      board.bytes(BoardKind.squareOff, 'OK'.codeUnits);
      await tester.pumpAndSettle();
      expect(
        (await ActiveSessionStore.load())!['pendingPhysicalMaiaMove'],
        pending,
      );
      expect(board.confirmations, isEmpty);
      await tester.tap(find.byKey(const ValueKey('chessnut-status-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Play in app'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('chessnut-status-banner')),
        findsNothing,
      );
      expect(
        (await ActiveSessionStore.load())!['pendingPhysicalMaiaMove'],
        isNull,
      );
      expect(board.motorMoves, hasLength(1));
      await dispose(tester);
    },
  );
  testWidgets(
    'candidates arriving while already backgrounded cannot reopen chooser',
    (tester) async {
      await launch(tester);
      await enable(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      board.candidates();
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(board.selected, isEmpty);
      expect(board.discoveries, 1);
      await dispose(tester);
    },
  );

  testWidgets(
    'retired connection positions and ready events cannot accept setup',
    (tester) async {
      await launch(tester);
      await enable(tester);
      board.status(BoardKind.chessnut, id: 'old');
      await tester.pumpAndSettle();
      board.status(BoardKind.chessnut, id: 'new');
      await tester.pumpAndSettle();
      final initial = ChessnutProtocol.pieceMapFromFen(
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      );
      board.controller.add(
        ElectronicBoardEvent(
          type: 'position',
          position: initial,
          connectionSession: 'session-old',
        ),
      );
      board.status(BoardKind.chessnut, id: 'old');
      board.controller.add(
        ElectronicBoardEvent(
          type: 'position',
          position: initial,
          connectionSession: 'session-old',
        ),
      );
      await tester.pumpAndSettle();
      expect(start(tester).onPressed, isNull);
      board.controller.add(
        ElectronicBoardEvent(
          type: 'position',
          position: initial,
          connectionSession: 'session-new',
        ),
      );
      await tester.pumpAndSettle();
      expect(start(tester).onPressed, isNotNull);
      await dispose(tester);
    },
  );

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
      'compact hardware reset and chooser remain usable in ${locale.languageCode}',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final strings = await AppLocalizations.delegate.load(locale);
        await ActiveSessionStore.save({
          'type': 'game',
          'pgn': '1. e4 e5 *',
          'electronicBoard': 'chessnut-go',
          'playerIsWhite': true,
          'clockPaused': true,
        });
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
            home: GamePage(electronicBoardTransport: board),
          ),
        );
        await tester.pumpAndSettle();
        board.status(BoardKind.chessnut);
        board.controller.add(
          const ElectronicBoardEvent(
            type: 'newGame',
            connectionSession: 'session-selected-board',
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(AlertDialog), findsOneWidget);
        final cancel = find.widgetWithText(TextButton, strings.cancel);
        final confirm = find.widgetWithText(FilledButton, strings.reset);
        expect(cancel.hitTestable(), findsOneWidget);
        expect(confirm.hitTestable(), findsOneWidget);
        await tester.tap(cancel);
        await tester.pumpAndSettle();
        expect((await ActiveSessionStore.load())!['pgn'], contains('e4'));
        await dispose(tester);
        await ActiveSessionStore.startNew();
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
            home: GamePage(electronicBoardTransport: board),
          ),
        );
        await tester.pumpAndSettle();
        final toggle = find.byKey(const ValueKey('home-chessnut-toggle'));
        await tester.ensureVisible(toggle);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        board.candidates();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.ensureVisible(
          find.byKey(const ValueKey('board-candidate-board-two')),
        );
        expect(
          find.byKey(const ValueKey('board-candidate-board-two')).hitTestable(),
          findsOneWidget,
        );
        await tester.tap(find.widgetWithText(TextButton, strings.cancel));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await dispose(tester);
      },
    );
  }
  testWidgets(
    'motor acknowledgement completing after background requires phone recovery',
    (tester) async {
      await launch(tester);
      await enable(tester);
      board.status(BoardKind.squareOff);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('board-confirm-setup')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Start game'));
      await tester.pumpAndSettle();
      board.acknowledgementGate = Completer<void>();
      board.bytes(BoardKind.squareOff, 'e2e4'.codeUnits);
      await tester.pump();
      expect(board.acknowledgements, [true]);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      board.acknowledgementGate!.complete();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('chessnut-inline-reconnect')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('chessnut-play-in-app')),
        findsOneWidget,
      );
      expect(board.motorMoves, isEmpty);
      expect(board.starts, ['white']);
      expect((await ActiveSessionStore.load())!['uciMoves'], isEmpty);
      expect(board.acknowledgements, [true]);
      await tester.tap(find.byKey(const ValueKey('chessnut-play-in-app')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('chessnut-status-banner')),
        findsNothing,
      );
      expect(board.motorMoves, isEmpty);
      await dispose(tester);
    },
  );
  testWidgets(
    'background during motor checkpoint prevents sending or retrying the move',
    (tester) async {
      final repository = MotorCheckpointRepository();
      ActiveSessionStore.setTestRepository(repository);
      addTearDown(() => ActiveSessionStore.setTestRepository(null));
      await launch(tester);
      await tester.tap(find.text('Black').first);
      await tester.pumpAndSettle();
      await enable(tester);
      board.status(BoardKind.squareOff);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('board-confirm-setup')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Start game'));
      await tester.pumpAndSettle();
      expect(repository.pending.isCompleted, isTrue);
      expect(board.motorMoves, isEmpty);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      repository.release.complete();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('chessnut-play-in-app')),
        findsOneWidget,
      );
      expect(board.motorMoves, isEmpty);
      expect(repository.data!['pendingPhysicalMaiaMove'], isNotNull);
      await tester.tap(find.byKey(const ValueKey('chessnut-play-in-app')));
      await tester.pumpAndSettle();
      expect(repository.data!['pendingPhysicalMaiaMove'], isNull);
      expect(board.motorMoves, isEmpty);
      await dispose(tester);
    },
  );

  testWidgets(
    'motor firmware initialization completes before Maia opening work',
    (tester) async {
      await launch(tester);
      await tester.tap(find.text('Black').first);
      await tester.pumpAndSettle();
      await enable(tester);
      board.status(BoardKind.squareOff);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('board-confirm-setup')));
      await tester.pumpAndSettle();
      board.startGate = Completer<void>();
      await tester.tap(find.widgetWithText(FilledButton, 'Start game'));
      await tester.pumpAndSettle();
      expect(board.starts, ['black']);
      expect(board.motorMoves, isEmpty);
      expect((await ActiveSessionStore.load())!['uciMoves'], isEmpty);
      board.startGate!.complete();
      await tester.pumpAndSettle();
      expect(board.motorMoves, hasLength(1));
      expect((await ActiveSessionStore.load())!['uciMoves'], hasLength(1));
      await dispose(tester);
    },
  );
}

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'board_connection_widget_test.dart' show DiscoveryBoard;
import 'fixtures/immediate_maia_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Grand Kingdom permits Stable/Preview/Dev; Pegasus permits only Dev',
    () {
      for (final flavor in ['production', 'unknown']) {
        expect(BoardChannelPolicy.supports(flavor, BoardKind.chessnut), isTrue);
        expect(BoardChannelPolicy.supports(flavor, BoardKind.pegasus), isFalse);
        expect(
          BoardChannelPolicy.supports(flavor, BoardKind.squareOff),
          isFalse,
        );
      }
      for (final flavor in ['stable', '', null]) {
        expect(
          BoardChannelPolicy.supports(flavor, BoardKind.squareOff),
          isTrue,
        );
        expect(BoardChannelPolicy.supports(flavor, BoardKind.pegasus), isFalse);
        expect(BoardChannelPolicy.supports(flavor, BoardKind.chessnut), isTrue);
      }
      expect(
        BoardChannelPolicy.supports('preview', BoardKind.chessnut),
        isTrue,
      );
      expect(
        BoardChannelPolicy.supports('preview', BoardKind.squareOff),
        isTrue,
      );
      expect(
        BoardChannelPolicy.supports('preview', BoardKind.pegasus),
        isFalse,
      );
      for (final kind in BoardKind.values) {
        expect(BoardChannelPolicy.supports('dev', kind), isTrue);
      }
    },
  );

  for (final legacySave in [false, true]) {
    testWidgets(
      'platform transport filters candidates by channel (legacy save: $legacySave)',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        if (legacySave) {
          await ActiveSessionStore.save({
            'type': 'game',
            'pgn': '1. e4 e5 *',
            'electronicBoard': 'chessnut-go',
            'playerIsWhite': true,
            'clockPaused': true,
          });
        }
        const methods = MethodChannel('maia_chess/chessnut');
        const events = MethodChannel('maia_chess/chessnut/events');
        const codec = StandardMethodCodec();
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        final calls = <MethodCall>[];
        messenger.setMockMethodCallHandler(methods, (call) async {
          calls.add(call);
          return null;
        });
        messenger.setMockMethodCallHandler(events, (_) async => null);
        messenger.setMockMethodCallHandler(
          maiaEngineChannel,
          (_) async => null,
        );
        addTearDown(() {
          messenger.setMockMethodCallHandler(methods, null);
          messenger.setMockMethodCallHandler(events, null);
          messenger.setMockMethodCallHandler(maiaEngineChannel, null);
        });
        tester.view.physicalSize = const Size(1000, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        // Use the actual platform transport, not the discoverable test double:
        // its previous flavor check incorrectly excluded unflavored Stable.
        await tester.pumpWidget(
          MaterialApp(
            home: GamePage(
              electronicBoardTransport: ChessnutPlatformTransport.instance,
              maiaEvaluator: (_, _) async => Float32List(4352),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final toggle = find.byKey(
          ValueKey(
            legacySave ? 'chessnut-inline-reconnect' : 'home-chessnut-toggle',
          ),
        );
        await tester.ensureVisible(toggle);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        if (legacySave) {
          expect(calls.where((c) => c.method == 'connect').last.arguments, {
            'mode': 'reconnect',
          });
        }
        final delivered = Completer<void>();
        messenger.handlePlatformMessage(
          events.name,
          codec.encodeSuccessEnvelope({
            'type': 'candidates',
            'candidates': [
              {'id': 'go', 'name': 'Chessnut Go', 'kind': 'chessnut'},
              {'id': 'air', 'name': 'Chessnut Air', 'kind': 'chessnut'},
              {'id': 'dgt', 'name': 'DGT Pegasus', 'kind': 'pegasus'},
              {'id': 'kingdom', 'name': 'Square Off', 'kind': 'squareOff'},
            ],
          }),
          (_) => delivered.complete(),
        );
        await delivered.future;
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('board-candidate-go')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('board-candidate-air')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('board-candidate-dgt')), findsNothing);
        expect(
          find.byKey(const ValueKey('board-candidate-kingdom')),
          BoardChannelPolicy.supports(appFlavor, BoardKind.squareOff) &&
                  !legacySave
              ? findsOneWidget
              : findsNothing,
        );
        final selectedId =
            BoardChannelPolicy.supports(appFlavor, BoardKind.squareOff) &&
                !legacySave
            ? 'kingdom'
            : 'go';
        await tester.tap(find.byKey(ValueKey('board-candidate-$selectedId')));
        await tester.pumpAndSettle();
        expect(calls.where((c) => c.method == 'selectBoard').single.arguments, {
          'candidateId': selectedId,
        });
        expect(find.byType(AlertDialog), findsNothing);
        if (legacySave) {
          expect((await ActiveSessionStore.load())!['pgn'], contains('e4'));
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
      skip: appFlavor == 'dev',
    );
  }
  testWidgets('channels reject ready events from unsupported boards', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final board = DiscoveryBoard();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
    addTearDown(() async {
      await board.controller.close();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(maiaEngineChannel, null);
    });
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
    final toggle = find.byKey(const ValueKey('home-chessnut-toggle'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    board.candidates();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('board-candidate-board-one')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('board-candidate-board-two')),
      findsNothing,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    board.controller.add(
      const ElectronicBoardEvent(
        type: 'status',
        connectionState: ElectronicBoardConnectionState.ready,
        boardKind: BoardKind.chessnut,
        boardId: 'chessnut-go',
        connectionSession: 'preview-chessnut',
        deviceName: 'Chessnut Go',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chessnut Go connected'), findsOneWidget);
    for (final kind in [
      BoardKind.pegasus,
      if (!BoardChannelPolicy.supports(appFlavor, BoardKind.squareOff))
        BoardKind.squareOff,
    ]) {
      board.status(kind);
      await tester.pumpAndSettle();
      expect(find.text('Confirm board setup'), findsNothing);
      expect(board.starts, isEmpty);
      expect(board.motorMoves, isEmpty);
      expect(find.text('Chessnut Go connected'), findsOneWidget);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }, skip: appFlavor == 'dev');

  testWidgets(
    'Stable Grand Kingdom requires setup and never replays a pending motor move',
    (tester) async {
      setImmediateMaiaPreferences({});
      final board = DiscoveryBoard();
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
      addTearDown(() async {
        await board.controller.close();
        messenger.setMockMethodCallHandler(maiaEngineChannel, null);
      });
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Future<void> launch() async {
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

      await launch();
      await tester.tap(find.text('Black').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('home-chessnut-toggle')),
      );
      await tester.tap(find.byKey(const ValueKey('home-chessnut-toggle')));
      await tester.pumpAndSettle();
      board.status(BoardKind.squareOff);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Start game'),
            )
            .onPressed,
        isNull,
      );
      expect(board.starts, isEmpty);
      await tester.tap(find.byKey(const ValueKey('board-confirm-setup')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Start game'));
      await tester.pumpAndSettle();
      expect(board.starts, ['black']);
      expect(board.motorMoves, hasLength(1));
      final saved = (await ActiveSessionStore.load())!;
      final pending = saved['pendingPhysicalMaiaMove'];
      expect(pending, isNotNull);
      expect(saved['timePreset'], TimePreset.unlimited.name);
      board.bytes(BoardKind.squareOff, 'OK'.codeUnits);
      await tester.pumpAndSettle();
      expect(
        (await ActiveSessionStore.load())!['pendingPhysicalMaiaMove'],
        pending,
      );
      expect(board.confirmations, isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      // Repair stale timed metadata before applying wall-clock loss on restore.
      await ActiveSessionStore.save({
        ...saved,
        'timePreset': TimePreset.blitzFiveZero.name,
        'clockPaused': false,
        'whiteMillis': 1,
        'blackMillis': 1,
        'savedAt': DateTime(2020).toIso8601String(),
      });
      await launch();
      expect(board.starts, ['black']);
      expect(board.motorMoves, hasLength(1));
      await tester.tap(find.byKey(const ValueKey('chessnut-play-in-app')));
      await tester.pumpAndSettle();
      final continued = (await ActiveSessionStore.load())!;
      expect(continued['pendingPhysicalMaiaMove'], isNull);
      expect(continued['timePreset'], TimePreset.unlimited.name);
      expect(continued['uciMoves'], saved['uciMoves']);
      expect(board.motorMoves, hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
    skip: !BoardChannelPolicy.supports(appFlavor, BoardKind.squareOff),
  );
}

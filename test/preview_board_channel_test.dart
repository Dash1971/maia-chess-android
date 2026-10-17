import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'board_connection_widget_test.dart' show DiscoveryBoard;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('only Dev permits prototype board adapters', () {
    for (final flavor in ['preview', 'stable', 'production', '', null]) {
      expect(BoardChannelPolicy.supports(flavor, BoardKind.chessnut), isTrue);
      expect(BoardChannelPolicy.supports(flavor, BoardKind.pegasus), isFalse);
      expect(BoardChannelPolicy.supports(flavor, BoardKind.squareOff), isFalse);
    }
    for (final kind in BoardKind.values) {
      expect(BoardChannelPolicy.supports('dev', kind), isTrue);
    }
  });

  for (final legacySave in [false, true]) {
    testWidgets(
      'platform transport keeps board selection in non-Dev builds (legacy save: $legacySave)',
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
          findsNothing,
        );
        await tester.tap(find.byKey(const ValueKey('board-candidate-go')));
        await tester.pumpAndSettle();
        expect(calls.where((c) => c.method == 'selectBoard').single.arguments, {
          'candidateId': 'go',
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
  testWidgets(
    'non-Dev channels filter prototype candidates and reject their ready events',
    (tester) async {
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
      for (final kind in [BoardKind.pegasus, BoardKind.squareOff]) {
        board.status(kind);
        await tester.pumpAndSettle();
        expect(find.text('Confirm board setup'), findsNothing);
        expect(board.starts, isEmpty);
        expect(board.motorMoves, isEmpty);
        expect(find.text('Chessnut Go connected'), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
    skip: appFlavor == 'dev',
  );
}

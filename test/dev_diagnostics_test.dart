import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'board_connection_widget_test.dart' show DiscoveryBoard;
import 'fixtures/immediate_maia_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  setUp(() {
    setImmediateMaiaPreferences({});
    PackageInfo.setMockInitialValues(
      appName: 'Dev',
      packageName: 'dev.test',
      version: 'test',
      buildNumber: '1',
      buildSignature: '',
    );
    calls = [];
    messenger.setMockMethodCallHandler(maiaEngineChannel, (call) async {
      calls.add(call);
      if (call.method == 'devTraceReport') return 'local-board-trace';
      return null;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(maiaEngineChannel, null));

  test(
    'Dev records and reports; other flavors never call the native recorder',
    () async {
      DevDiagnostics.record('grand-kingdom.maia-intended', {'uci': 'e7f8'});
      await Future<void>.delayed(Duration.zero);
      final trace = await DevDiagnostics.recentTrace();
      if (appFlavor == 'dev') {
        expect(trace, 'local-board-trace');
        expect(calls.map((c) => c.method), [
          'devTraceContext',
          'devTraceReport',
        ]);
        expect((calls.first.arguments as Map)['uci'], 'e7f8');
      } else {
        expect(trace, isEmpty);
        expect(calls, isEmpty);
      }
    },
  );

  test('Copy diagnostics includes a bounded Dev trace only in Dev', () async {
    final report = await AppDiagnostics.report();
    expect(report.contains('local-board-trace'), appFlavor == 'dev');
    calls.clear();
    final withoutTrace = await AppDiagnostics.report(includeDevTrace: false);
    expect(withoutTrace, isNot(contains('local-board-trace')));
    expect(calls.where((c) => c.method == 'devTraceReport'), isEmpty);
  });

  test('Recorder failure cannot fail game operations', () async {
    messenger.setMockMethodCallHandler(maiaEngineChannel, (_) async {
      throw PlatformException(code: 'disk_full');
    });
    DevDiagnostics.record('app.lifecycle', {'state': 'paused'});
    await Future<void>.delayed(Duration.zero);
    expect(
      await DevDiagnostics.recentTrace(),
      appFlavor == 'dev' ? 'Dev trace unavailable' : '',
    );
  });

  testWidgets('Dev export sits in diagnostics with no recording switch', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GamePage()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-settings-button')));
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('save-dev-diagnostics'));
    expect(button, appFlavor == 'dev' ? findsOneWidget : findsNothing);
    if (appFlavor == 'dev') {
      await tester.ensureVisible(button);
      await tester.runAsync(() async {
        await tester.tap(button);
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      await tester.pumpAndSettle();
      expect(
        calls.where((c) => c.method == 'saveDevDiagnostics'),
        hasLength(1),
      );
      expect(calls.where((c) => c.method == 'devTraceReport'), isEmpty);
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Grand Kingdom intent carries the actual checkpoint and UCI without changing motor delivery',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final board = DiscoveryBoard();
      addTearDown(board.controller.close);
      await tester.pumpWidget(
        MaterialApp(
          home: GamePage(
            electronicBoardTransport: board,
            maiaEvaluator: (_, _) async => Float32List(4352),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Black').first);
      await tester.tap(find.byKey(const ValueKey('home-chessnut-toggle')));
      await tester.pumpAndSettle();
      board.status(BoardKind.squareOff);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('board-confirm-setup')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Start game'));
      await tester.pumpAndSettle();
      expect(board.motorMoves, hasLength(1));
      final trace = calls
          .where((c) => c.method == 'devTraceContext')
          .map((c) => Map<String, dynamic>.from(c.arguments as Map))
          .toList();
      final intended = trace.singleWhere(
        (e) => e['event'] == 'grand-kingdom.maia-intended',
      );
      final checkpoint = (await ActiveSessionStore.load())!;
      expect(intended['uci'], board.motorMoves.single);
      expect(intended['pending'], checkpoint['pendingPhysicalMaiaMove']);
      expect(intended['beforeFen'], startsWith('rnbqkbnr/pppppppp/'));
      expect(intended['fen'], isNot(intended['beforeFen']));
      expect(intended['pgn'], contains('1.'));
      board.bytes(BoardKind.squareOff, 'OK'.codeUnits);
      await tester.pumpAndSettle();
      expect(board.motorMoves, hasLength(1));
      expect(
        (await ActiveSessionStore.load())!['pendingPhysicalMaiaMove'],
        intended['pending'],
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
    skip: appFlavor != 'dev',
  );
}

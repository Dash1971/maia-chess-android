// Optional VM-service qualification; uses the protocol package bundled with Flutter tests.
// ignore_for_file: depend_on_referenced_packages, avoid_print, invalid_use_of_visible_for_testing_member
import 'dart:async';
import 'dart:developer' as developer;

import 'package:chessground/chessground.dart' as cg;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maia_chess/main.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

const heavyFen =
    '2rq1b1r/p1k5/b1np1p2/Pp1BPppp/2p1nPPP/BPPP1Q2/3N4/R3KR2 w - - 4 23';
const reviews = [
  StockfishReview(
    0,
    'd5c6',
    lines: [
      StockfishLine(evaluation: 0, moves: ['d5c6']),
      StockfishLine(evaluation: 0, moves: ['a1b1']),
    ],
  ),
  StockfishReview(0, 'a7a6'),
];
MoveClassificationJob heavy() => MoveClassifier.startOffMainIsolate(
  scores: reviews,
  positions: [heavyFen, (chess.Chess.fromFEN(heavyFen)..move('Bxc6')).fen],
  uciMoves: const ['d5c6'],
);
Future<VmService> connect() async {
  var info = await developer.Service.getInfo();
  info = info.serverUri == null
      ? await developer.Service.controlWebServer(enable: true)
      : info;
  final uri = info.serverUri!;
  return vmServiceConnectUri(
    uri.replace(scheme: 'ws', path: '${uri.path}ws').toString(),
  );
}

Future<Set<String>> workers(VmService service) async => (await service.getVM())
    .isolates!
    .where((i) => i.name?.contains('_runMoveClassification') == true)
    .map((i) => i.id!)
    .toSet();
void main() {
  test(
    'audit: cancellation exits real VM workers in 25 startup/running races',
    () async {
      final vm = await connect();
      try {
        expect(await workers(vm), isEmpty);
        for (var i = 0; i < 25; i++) {
          final job = heavy();
          final outcome = job.result.then<Object>(
            (v) => v,
            onError: (Object e) => e,
          );
          if (i.isOdd) {
            await job.started;
            expect(await workers(vm), hasLength(1));
          }
          job.cancel();
          job.cancel();
          expect(await outcome, isA<MoveClassificationCancelled>());
          await job.terminated.timeout(const Duration(seconds: 3));
          expect(await workers(vm), isEmpty);
        }
        print(
          'AUDIT 25 real VM spawn/cancel cycles: zero remaining classification isolates',
        );
      } finally {
        await vm.dispose();
      }
    },
  );
  testWidgets(
    'audit: real Review Stop, disposal, background and engine-off terminate worker',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final vm = (await tester.runAsync(connect))!;
      Future<Set<String>> ids() async =>
          (await tester.runAsync(() => workers(vm)))!;
      Future<void> waitForCount(int count) async {
        for (var i = 0; i < 100; i++) {
          await tester.pump();
          if ((await ids()).length == count) return;
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
        }
        expect(await ids(), hasLength(count));
      }

      try {
        for (final action in [
          'stop',
          'dispose',
          'background',
          'engine-off',
          'route-cover',
          'graph-invalidation',
        ]) {
          SharedPreferences.setMockInitialValues({});
          await tester.pumpWidget(
            MaterialApp(
              navigatorObservers: [maiaRouteObserver],
              home: ReviewPage(
                positions: action == 'graph-invalidation'
                    ? [heavyFen]
                    : [
                        heavyFen,
                        (chess.Chess.fromFEN(heavyFen)..move('Bxc6')).fen,
                      ],
                initialVariations: action == 'graph-invalidation'
                    ? const [
                        RecordedVariation(
                          basePly: 0,
                          baseFen: heavyFen,
                          sanMoves: ['Bxc6'],
                        ),
                      ]
                    : const [],
                uciMoves: action == 'graph-invalidation'
                    ? const []
                    : const ['d5c6'],
                sanMoves: action == 'graph-invalidation'
                    ? const []
                    : const ['Bxc6'],
                playerIsWhite: true,
                pgn: '*',
                onHome: () {},
                onSessionChanged: action == 'graph-invalidation'
                    ? (_, _, _) async {}
                    : null,
                evaluator: (_) async => reviews.first,
                maiaEvaluator: (_, _) async => null,
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Computer analysis'));
          await tester.pump();
          await tester.tap(find.byKey(const ValueKey('run-computer-analysis')));
          await waitForCount(1);
          expect(find.text('Graph ready · classifying moves…'), findsOneWidget);
          if (action == 'stop') {
            final stop = find.byKey(const ValueKey('cancel-computer-analysis'));
            await tester.ensureVisible(stop);
            await tester.pump();
            await tester.tap(stop);
          } else if (action == 'dispose') {
            await tester.pumpWidget(const SizedBox.shrink());
          } else if (action == 'background') {
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.paused,
            );
          } else if (action == 'route-cover') {
            unawaited(
              Navigator.of(tester.element(find.byType(ReviewPage))).push(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('Audit cover')),
                ),
              ),
            );
          } else if (action == 'graph-invalidation') {
            tester
                .widget<AnalysisGraph>(find.byType(AnalysisGraph))
                .onSelected(1);
            await tester.pump();
            final board = tester.widget<cg.Chessboard>(
              find.byType(cg.Chessboard),
            );
            final replay = chess.Chess.fromFEN(board.controller.fen);
            final uci = MaiaEncoding.uci(
              replay.moves({'asObjects': true}).cast<chess.Move>().first,
            );
            board.onMove!(dc.NormalMove.fromUci(uci));
          } else {
            await tester.tap(
              find.byKey(const ValueKey('analysis-engine-toggle')),
            );
          }
          await waitForCount(0);
          print('AUDIT $action: actual VM classification isolate gone');
          if (action == 'stop') {
            expect(find.byType(AnalysisGraph), findsOneWidget);
            expect(find.text('Computer analysis stopped.'), findsWidgets);
          }
          await tester.pumpWidget(const SizedBox.shrink());
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pump();
        }
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await waitForCount(0);
        await tester.runAsync(() => vm.dispose());
      }
    },
  );
  test('audit: 300 immediate result, cancellation and exit races', () async {
    final vm = await connect();
    try {
      for (var i = 0; i < 300; i++) {
        final job = MoveClassifier.startOffMainIsolate(
          scores: reviews,
          positions: const [],
          uciMoves: const [],
        );
        final outcome = job.result.then<Object>(
          (v) => v,
          onError: (Object e) => e,
        );
        if (i % 3 == 0) {
          job.cancel();
        }
        if (i % 3 == 1) {
          await job.started;
          await Future<void>.delayed(Duration.zero);
          job.cancel();
        }
        if (i % 3 == 2) {
          expect(await outcome, isA<List<ClassifiedMove>>());
          job.cancel();
        }
        final result = await outcome;
        expect(
          result is List<ClassifiedMove> ||
              result is MoveClassificationCancelled,
          isTrue,
        );
        await job.started.timeout(const Duration(seconds: 3));
        await job.terminated.timeout(const Duration(seconds: 3));
      }
      expect(await workers(vm), isEmpty);
      print(
        'AUDIT 300 fast result/exit/cancel races: passed, zero workers remain',
      );
    } finally {
      await vm.dispose();
    }
  });
}

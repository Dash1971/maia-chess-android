import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

void main() {
  test(
    'seeded queue churn settles every request without concurrent native work',
    () async {
      final rng = Random(20260909);
      final scopes = List.generate(8, (_) => MaiaInferenceScope());
      final gates = <Completer<String>>[];
      final results = <Future<void>>[];
      final suspensions = <Future<void>>[];
      var active = 0;
      var peak = 0;
      var completed = 0;
      final queue = EngineWorkQueue<String, String>(
        run: (fen, _, _) {
          active++;
          peak = max(peak, active);
          final gate = Completer<String>();
          gates.add(gate);
          return gate.future.whenComplete(() => active--);
        },
        stop: () {},
      );
      Future<void> finishOne() async {
        if (gates.isNotEmpty) {
          final gate = gates.removeAt(0);
          if (rng.nextInt(10) == 0) {
            gate.completeError(StateError('simulated native failure'));
          } else {
            gate.complete('result');
          }
        }
        await Future<void>.delayed(Duration.zero);
      }

      for (var i = 0; i < 1000; i++) {
        final scope = scopes[rng.nextInt(scopes.length)];
        switch (rng.nextInt(5)) {
          case 0:
            queue.cancel(scope);
          case 1:
            suspensions.add(queue.suspend());
          case 2:
            queue.resume();
          default:
            results.add(
              queue
                  .add('position-$i', scope: scope, background: rng.nextBool())
                  .then<void>(
                    (_) {
                      completed++;
                    },
                    onError: (Object error, StackTrace _) {
                      expect(
                        error,
                        anyOf(isA<AnalysisCancelled>(), isA<StateError>()),
                      );
                      completed++;
                    },
                  ),
            );
        }
        if (i % 7 == 0) await finishOne();
      }
      queue.resume();
      while (gates.isNotEmpty) {
        await finishOne();
      }
      await Future.wait([...results, ...suspensions])
          .timeout(const Duration(seconds: 5));
      expect(completed, results.length);
      expect(peak, 1);
      expect(active, 0);
    },
  );

  test('long PGN parsing stays bounded and round-trips', () {
    final moves = List.generate(
      250,
      (i) => '${i * 2 + 1}. Nf3 Nf6 ${i * 2 + 2}. Ng1 Ng8',
    ).join(' ');
    final source = '[Result "*"]\n\n$moves *';
    final watch = Stopwatch()..start();
    final session = AnalysisSession.fromPgn(source);
    expect(session.uciMoves, hasLength(1000));
    expect(AnalysisSession.fromPgn(session.pgn).positions, session.positions);
    // A timing record for this host, not a mobile performance assertion.
    // ignore: avoid_print
    print(
      'HARDENING: 1000-ply import plus round-trip ${watch.elapsedMilliseconds} ms',
    );
  }, timeout: const Timeout(Duration(seconds: 30)));
}

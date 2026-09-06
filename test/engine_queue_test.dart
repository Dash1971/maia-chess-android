import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

void main() {
  late EngineWorkQueue<String> queue;
  late List<String> starts;
  late List<Completer<String>> searches;
  late int stops;
  setUp(() {
    starts = [];
    searches = [];
    stops = 0;
    queue = EngineWorkQueue(
      run: (fen, background) {
        starts.add(fen);
        final result = Completer<String>();
        searches.add(result);
        return result.future;
      },
      stop: () {
        stops++;
      },
    );
  });
  Future<void> drain() => Future<void>.delayed(Duration.zero);

  test(
    'replaces stale queued work and drains active output before next search',
    () async {
      final scope = MaiaInferenceScope();
      final first = expectLater(
        queue.add('a', scope: scope),
        throwsA(isA<AnalysisCancelled>()),
      );
      final second = expectLater(
        queue.add('b', scope: scope),
        throwsA(isA<AnalysisCancelled>()),
      );
      final third = queue.add('c', scope: scope);
      expect(starts, ['a']);
      searches[0].complete('old output');
      await drain();
      expect(starts, ['a', 'c']);
      searches[1].complete('current');
      expect(await third, 'current');
      await Future.wait([first, second]);
      expect(stops, 2);
    },
  );

  test(
    'interactive navigation preempts and then resumes independent batch work',
    () async {
      final batch = queue.add(
        'batch',
        scope: MaiaInferenceScope(),
        background: true,
      );
      final selected = queue.add('selected', scope: MaiaInferenceScope());
      expect(stops, 1);
      searches[0].complete('partial batch');
      await drain();
      expect(starts, ['batch', 'selected']);
      searches[1].complete('quick');
      expect(await selected, 'quick');
      await drain();
      expect(starts, ['batch', 'selected', 'batch']);
      searches[2].complete('full batch');
      expect(await batch, 'full batch');
    },
  );

  test(
    'suspend drains native work and cancels even unscoped requests',
    () async {
      final active = expectLater(
        queue.add('active'),
        throwsA(isA<AnalysisCancelled>()),
      );
      final pending = expectLater(
        queue.add('pending'),
        throwsA(isA<AnalysisCancelled>()),
      );
      var suspended = false;
      final pause = queue.suspend().then((_) => suspended = true);
      expect(queue.canRunActive, isFalse);
      await drain();
      expect(suspended, isFalse);
      searches[0].complete('drained');
      await Future.wait([active, pending, pause]);
      final resumed = queue.add('resumed');
      expect(starts, ['active']);
      queue.resume();
      expect(starts, ['active', 'resumed']);
      searches[1].complete('ok');
      expect(await resumed, 'ok');
    },
  );

  test('a native error does not wedge subsequent searches', () async {
    final failed = expectLater(queue.add('bad'), throwsStateError);
    final next = queue.add('good');
    searches[0].completeError(StateError('engine stopped'));
    await drain();
    searches[1].complete('ok');
    await failed;
    expect(await next, 'ok');
  });

  test('a stop state error cannot wedge cancellation or suspend', () async {
    final errors = <Object>[];
    queue = EngineWorkQueue(
      run: (fen, background) {
        starts.add(fen);
        final result = Completer<String>();
        searches.add(result);
        return result.future;
      },
      stop: () => throw StateError('engine already exited'),
      onStopError: (error, _) => errors.add(error),
    );
    final scope = MaiaInferenceScope();
    final cancelled = expectLater(
      queue.add('active', scope: scope),
      throwsA(isA<AnalysisCancelled>()),
    );
    queue.cancel(scope);
    searches.single.complete('late output');
    await cancelled;
    await drain();

    final duringSuspend = expectLater(
      queue.add('suspend'),
      throwsA(isA<AnalysisCancelled>()),
    );
    final suspended = queue.suspend();
    searches.last.complete('drained');
    await Future.wait([duringSuspend, suspended]);
    queue.resume();
    final next = queue.add('next');
    searches.last.complete('ok');

    expect(await next, 'ok');
    expect(errors, hasLength(2));
  });
}

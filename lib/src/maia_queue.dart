part of '../main.dart';

class MaiaInferenceScope {
  int _generation = 0;

  int begin() => ++_generation;
  bool isCurrent(int generation) => generation == _generation;
  void invalidate() => _generation++;
}

class MaiaInferenceQueue {
  static Future<void> _tail = Future<void>.value();
  static bool _firstInferencePending = true;

  @visibleForTesting
  static void resetForTesting() {
    assert(() {
      // Widget tests have separate fake-clock zones. Production never resets
      // the queue; tests reset only after draining their mocked inference.
      _tail = Future<void>.value();
      _firstInferencePending = false;
      return true;
    }());
  }

  static Future<Float32List?> predict(
    Map<String, Object> arguments, {
    MaiaInferenceScope? replaceableScope,
    CapturedDecision? capture,
    Duration timeout = const Duration(seconds: 90),
  }) => _request<Float32List>(
    () => maiaEngineChannel.invokeMethod<Float32List>('predict', arguments),
    replaceableScope: replaceableScope,
    capture: capture,
    timeout: timeout,
  );

  static Future<MaiaInferenceResult?> analyze(
    Map<String, Object> arguments, {
    MaiaInferenceScope? replaceableScope,
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final response = await _request<Object>(
      () => maiaEngineChannel.invokeMethod<Object>('predict', {
        ...arguments,
        'includeValue': true,
      }),
      replaceableScope: replaceableScope,
      timeout: timeout,
    );
    return MaiaInferenceResult.decode(response);
  }

  static Future<T?> _request<T>(
    Future<T?> Function() request, {
    MaiaInferenceScope? replaceableScope,
    CapturedDecision? capture,
    required Duration timeout,
  }) {
    final result = Completer<T?>();
    final generation = replaceableScope?.begin();
    _tail = _tail.catchError((_) {}).then((_) async {
      if (generation != null && !replaceableScope!.isCurrent(generation)) {
        capture?.data['queueOutcome'] = 'cancelled-before-inference';
        result.complete(null);
        return;
      }
      try {
        final firstInference = _firstInferencePending;
        final timer = Stopwatch()..start();
        if (firstInference) {
          _firstInferencePending = false;
          await AppDiagnostics.recordEvent('maia-first-inference-start');
        }
        capture?.data['queueOutcome'] = 'inference-started';
        final response = await request().timeout(timeout);
        capture?.output(response is Float32List ? response : null);
        capture?.data['queueOutcome'] = 'inference-returned';
        if (firstInference) {
          await AppDiagnostics.recordEvent(
            'maia-first-inference-complete durationMs=${timer.elapsedMilliseconds}',
          );
        }
        if (generation != null && !replaceableScope!.isCurrent(generation)) {
          result.complete(null);
          return;
        }
        result.complete(response);
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }
}

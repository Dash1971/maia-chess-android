part of '../main.dart';

class MaiaInferenceScope {
  int _generation = 0;

  int begin() => ++_generation;
  bool isCurrent(int generation) => generation == _generation;
  void invalidate() => _generation++;
}

class MaiaInferenceQueue {
  static Future<void> _tail = Future<void>.value();

  static Future<Float32List?> predict(
    Map<String, Object> arguments, {
    MaiaInferenceScope? replaceableScope,
    Duration timeout = const Duration(seconds: 90),
  }) {
    final result = Completer<Float32List?>();
    final generation = replaceableScope?.begin();
    _tail = _tail.catchError((_) {}).then((_) async {
      if (generation != null && !replaceableScope!.isCurrent(generation)) {
        result.complete(null);
        return;
      }
      try {
        final response = await maiaEngineChannel
            .invokeMethod<Float32List>('predict', arguments)
            .timeout(timeout);
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

part of '../main.dart';

enum BoardResetPress { ignored, armed, confirmed }

/// A monotonic confirmation window, separate from transport duplicate filtering.
/// The protocol has no press identifier. A 500 ms quiet interval conservatively
/// rejects duplicate bursts; the documented 3.2 s hold repeat cannot confirm a
/// 2.5 s window. Physical acceptance is still required for each model/firmware.
class BoardResetConfirmation {
  BoardResetConfirmation({Duration Function()? elapsed})
    : _elapsed = elapsed ?? (Stopwatch()..start()).elapsedGetter;

  static const window = Duration(milliseconds: 2500);
  static const duplicateQuietPeriod = Duration(milliseconds: 500);
  final Duration Function() _elapsed;
  Duration? _lastEvent;
  Duration? _armedAt;
  int? _generation;
  String? _connection;
  bool _consumed = false;

  bool get armed =>
      !_consumed && _armedAt != null && _elapsed() - _armedAt! <= window;

  BoardResetPress press({required int generation, required String connection}) {
    final now = _elapsed();
    final previous = _lastEvent;
    _lastEvent = now;
    if (previous != null && now - previous < duplicateQuietPeriod) {
      return BoardResetPress.ignored;
    }
    if (_consumed) return BoardResetPress.ignored;
    if (armed && _generation == generation && _connection == connection) {
      _consumed = true;
      _armedAt = null;
      return BoardResetPress.confirmed;
    }
    _generation = generation;
    _connection = connection;
    _armedAt = now;
    return BoardResetPress.armed;
  }

  void disarm() {
    _armedAt = null;
    _generation = null;
    _connection = null;
    _consumed = false;
    // Keep the last event so cancellation cannot turn a duplicate into a press.
  }
}

extension on Stopwatch {
  Duration elapsedGetter() => elapsed;
}

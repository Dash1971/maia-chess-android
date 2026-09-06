part of '../main.dart';

class AnalysisCancelled implements Exception {
  const AnalysisCancelled();
}

/// One native search at a time. Foreground requests preempt batch work; a
/// stopped search is drained before the next request consumes native output.
class EngineWorkQueue<T> {
  EngineWorkQueue({required this.run, required this.stop, this.onStopError});
  final Future<T> Function(String, bool) run;
  final void Function() stop;
  final void Function(Object, StackTrace)? onStopError;
  final List<_EngineWork<T>> _pending = [];
  _EngineWork<T>? _active;
  Completer<void>? _idle;
  bool paused = false;
  bool get canRunActive =>
      !paused && _active != null && _active!.current && !_active!.preempted;

  Future<T> add(
    String fen, {
    MaiaInferenceScope? scope,
    bool background = false,
  }) {
    final work = _EngineWork<T>(fen, scope, scope?.begin(), background);
    if (scope != null) {
      _discardWhere((item) => identical(item.scope, scope));
      if (identical(_active?.scope, scope)) _requestStop();
    }
    if (!background && _active?.background == true && _active!.current) {
      _active!.preempted = true;
      _requestStop();
    }
    _pending.add(work);
    _pump();
    return work.result.future;
  }

  void cancel(MaiaInferenceScope scope) {
    scope.invalidate();
    _discardWhere((item) => identical(item.scope, scope));
    if (identical(_active?.scope, scope)) _requestStop();
  }

  void _discardWhere(bool Function(_EngineWork<T>) test) {
    for (final work in _pending.where(test).toList()) {
      work.result.completeError(const AnalysisCancelled());
      _pending.remove(work);
    }
  }

  Future<void> suspend() async {
    paused = true;
    _discardWhere((_) => true);
    if (_active != null) {
      _active!.cancelled = true;
      _requestStop();
      await (_idle ??= Completer<void>()).future;
    }
  }

  void resume() {
    paused = false;
    _pump();
  }

  void _requestStop() {
    try {
      stop();
    } catch (error, stackTrace) {
      // The native process may have exited between the searching-state check
      // and the stop write. Cancellation remains valid and the active run will
      // still drain or fail; do not wedge the queue during lifecycle cleanup.
      onStopError?.call(error, stackTrace);
    }
  }

  void _pump() {
    if (paused || _active != null || _pending.isEmpty) return;
    final foreground = _pending.indexWhere((work) => !work.background);
    final work = _pending.removeAt(foreground < 0 ? 0 : foreground);
    if (!work.current) {
      work.result.completeError(const AnalysisCancelled());
      _pump();
      return;
    }
    work.preempted = false;
    _active = work;
    unawaited(() async {
      try {
        final value = await run(work.fen, work.background);
        if (!work.current) throw const AnalysisCancelled();
        if (!work.preempted) work.result.complete(value);
      } catch (error, stack) {
        if (!work.preempted || !work.current) {
          work.result.completeError(error, stack);
        }
      } finally {
        if (work.preempted && work.current) _pending.add(work);
        _active = null;
        _idle?.complete();
        _idle = null;
        _pump();
      }
    }());
  }
}

class _EngineWork<T> {
  _EngineWork(this.fen, this.scope, this.generation, this.background);
  final String fen;
  final MaiaInferenceScope? scope;
  final int? generation;
  final bool background;
  bool preempted = false;
  bool cancelled = false;
  final result = Completer<T>();
  bool get current =>
      !cancelled && (generation == null || scope!.isCurrent(generation!));
}

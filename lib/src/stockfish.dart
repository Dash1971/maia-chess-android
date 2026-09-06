part of '../main.dart';

class StockfishAnalyzer {
  StockfishAnalyzer._();

  static final instance = StockfishAnalyzer._();
  final Stockfish _engine = Stockfish.instance;
  Future<void>? _startup;
  bool _searching = false;
  Future<void>? _closing;
  late final EngineWorkQueue<StockfishReview> _queue = EngineWorkQueue(
    run: (fen, background) => _evaluateNow(fen, background: background),
    stop: () {
      if (_searching) _engine.stdin = 'stop';
    },
    onStopError: (error, stackTrace) =>
        unawaited(AppDiagnostics.record('stockfish-stop', error, stackTrace)),
  );

  void cancel(MaiaInferenceScope scope) => _queue.cancel(scope);

  Future<void> _ensureStarted() async {
    final startup = _startup ??= _engine.start().then((_) async {
      _engine.stdin = 'setoption name Threads value 2';
      _engine.stdin = 'setoption name Hash value 64';
      _engine.stdin = 'setoption name MultiPV value 2';
      final ready = _engine.stdout.firstWhere((line) => line == 'readyok');
      _engine.stdin = 'isready';
      await ready.timeout(const Duration(seconds: 5));
    });
    try {
      await startup;
    } catch (_) {
      if (identical(_startup, startup)) _startup = null;
      rethrow;
    }
  }

  Future<StockfishReview> evaluate(
    String fen, {
    MaiaInferenceScope? scope,
    bool background = false,
  }) => _queue.add(fen, scope: scope, background: background);

  Future<StockfishReview> _evaluateNow(
    String fen, {
    bool background = false,
  }) async {
    final position = chess.Chess.fromFEN(fen);
    if (position.in_checkmate) {
      final whiteToMove = fen.split(' ')[1] == 'w';
      return StockfishReview(0, '(none)', mate: whiteToMove ? -1 : 1);
    }
    if (position.game_over) return const StockfishReview(0, '(none)');

    await _ensureStarted();
    if (!_queue.canRunActive) throw const AnalysisCancelled();
    final completer = Completer<int>();
    var latest = 0;
    int? latestMate;
    var bestMove = '';
    final lines = <int, StockfishLine>{};
    late StreamSubscription<String> subscription;
    subscription = _engine.stdout.listen((line) {
      if (line.startsWith('info ') && line.contains(' score ')) {
        final multiPv =
            int.tryParse(
              RegExp(r' multipv (\d+)').firstMatch(line)?.group(1) ?? '1',
            ) ??
            1;
        final cp = RegExp(r' score cp (-?\d+)').firstMatch(line);
        final mate = RegExp(r' score mate (-?\d+)').firstMatch(line);
        final pv = RegExp(r' pv (.+)$')
            .firstMatch(line)
            ?.group(1)
            ?.trim()
            .split(RegExp(r'\s+'))
            .where(
              (move) => RegExp(r'^[a-h][1-8][a-h][1-8][qrbn]?$').hasMatch(move),
            )
            .toList(growable: false);
        final score = cp == null ? 0 : int.parse(cp.group(1)!);
        final mateScore = mate == null ? null : int.parse(mate.group(1)!);
        if (pv != null && pv.isNotEmpty) {
          lines[multiPv] = StockfishLine(
            evaluation: score,
            mate: mateScore,
            moves: pv,
          );
        }
        if (multiPv != 1) return;
        if (cp != null) {
          latest = score;
          latestMate = null;
        }
        if (mate != null) {
          latestMate = mateScore;
        }
      }
      if (line.startsWith('bestmove ') && !completer.isCompleted) {
        final fields = line.trim().split(RegExp(r'\s+'));
        final candidate = fields.length > 1 ? fields[1] : '(none)';
        bestMove = RegExp(r'^[a-h][1-8][a-h][1-8][qrbn]?$').hasMatch(candidate)
            ? candidate
            : '(none)';
        if (bestMove == '(none)' && candidate != '(none)') {
          unawaited(
            AppDiagnostics.recordEvent('stockfish-invalid-bestmove:$candidate'),
          );
        }
        completer.complete(latest);
      }
    });
    _engine.stdin = 'position fen $fen';
    _searching = true;
    _engine.stdin = background
        ? 'go depth 16 movetime 1500'
        : 'go depth 16 movetime 350';
    try {
      final sideToMoveScore = await completer.future.timeout(
        const Duration(seconds: 20),
      );
      final blackToMove = fen.split(' ')[1] == 'b';
      final orderedLines = lines.entries.toList(growable: false)
        ..sort((a, b) => a.key.compareTo(b.key));
      return StockfishReview(
        blackToMove ? -sideToMoveScore : sideToMoveScore,
        bestMove,
        mate: latestMate == null
            ? null
            : blackToMove
            ? -latestMate!
            : latestMate,
        lines: orderedLines
            .map((entry) => entry.value.forWhite(blackToMove))
            .toList(growable: false),
      );
    } on TimeoutException {
      // Stop and drain the outstanding search before the next queued request.
      // Otherwise its delayed bestmove can be mistaken for the next position.
      _engine.stdin = 'stop';
      try {
        await completer.future.timeout(const Duration(seconds: 2));
      } on TimeoutException {
        // Never reuse an engine whose output could not be drained. A delayed
        // bestmove from it could otherwise satisfy the next position request.
        await subscription.cancel();
        try {
          await _engine.quit().timeout(const Duration(seconds: 3));
        } finally {
          _startup = null;
        }
      }
      rethrow;
    } finally {
      _searching = false;
      await subscription.cancel();
    }
  }

  Future<void> close() =>
      _closing ??= _closeNow().whenComplete(() => _closing = null);

  Future<void> _closeNow() async {
    try {
      await _queue.suspend();
      if (_startup != null) {
        await _engine.quit().timeout(const Duration(seconds: 3));
      }
    } finally {
      _startup = null;
      _queue.resume();
    }
  }
}

class StockfishReview {
  const StockfishReview(
    this.evaluation,
    this.bestMove, {
    this.mate,
    this.lines = const [],
  });

  final int evaluation;
  final String bestMove;
  final int? mate;
  final List<StockfishLine> lines;

  double get whiteWinningChances {
    final value = mate == null
        ? evaluation.clamp(-1000, 1000)
        : (21 - min(10, mate!.abs())) * 100 * (mate! > 0 ? 1 : -1);
    return 2 / (1 + exp(-0.00368208 * value)) - 1;
  }

  double get whiteWinPercent => 50 + 50 * whiteWinningChances;
}

class StockfishLine {
  const StockfishLine({
    required this.evaluation,
    required this.moves,
    this.mate,
  });

  final int evaluation;
  final int? mate;
  final List<String> moves;

  StockfishLine forWhite(bool blackToMove) => StockfishLine(
    evaluation: blackToMove ? -evaluation : evaluation,
    mate: mate == null ? null : (blackToMove ? -mate! : mate),
    moves: moves,
  );
}

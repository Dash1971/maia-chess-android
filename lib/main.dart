import 'dart:async';
import 'dart:math';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multistockfish/multistockfish.dart';

void main() => runApp(const MaiaChessApp());

class MaiaChessApp extends StatelessWidget {
  const MaiaChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maia Chess',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff5d735f),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xff171a18),
        useMaterial3: true,
      ),
      home: const GamePage(),
    );
  }
}

enum PlayerSide { white, black, random }

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  static const _engineChannel = MethodChannel('maia_chess/engine');
  static const _files = 'abcdefgh';
  static const _pieceSymbols = <String, String>{
    'wp': '♙',
    'wn': '♘',
    'wb': '♗',
    'wr': '♖',
    'wq': '♕',
    'wk': '♔',
    'bp': '♟',
    'bn': '♞',
    'bb': '♝',
    'br': '♜',
    'bq': '♛',
    'bk': '♚',
  };

  chess.Chess _game = chess.Chess();
  final List<String> _positionHistory = [];
  final List<String> _uciMoves = [];
  PlayerSide _sideChoice = PlayerSide.white;
  chess.Color _playerColor = chess.Color.WHITE;
  int _elo = 1500;
  String? _selectedSquare;
  String _status = 'Choose your settings and start a game.';
  bool _started = false;
  bool _engineThinking = false;
  bool _analysisRunning = false;
  int _analysisProgress = 0;

  bool get _playerIsWhite => _playerColor == chess.Color.WHITE;
  bool get _isPlayerTurn => _game.turn == _playerColor;

  void _startGame() {
    final randomWhite = Random.secure().nextBool();
    _playerColor = switch (_sideChoice) {
      PlayerSide.white => chess.Color.WHITE,
      PlayerSide.black => chess.Color.BLACK,
      PlayerSide.random => randomWhite ? chess.Color.WHITE : chess.Color.BLACK,
    };
    setState(() {
      _game = chess.Chess();
      _positionHistory
        ..clear()
        ..add(_game.fen);
      _uciMoves.clear();
      _selectedSquare = null;
      _started = true;
      _status = _playerIsWhite ? 'Your move.' : 'Maia is loading…';
    });
    if (!_playerIsWhite) _playMaiaMove();
  }

  void _tapSquare(String square) {
    if (!_started || _engineThinking || !_isPlayerTurn || _game.game_over) {
      return;
    }
    final piece = _game.get(square);
    if (_selectedSquare == null) {
      if (piece?.color == _playerColor) {
        setState(() => _selectedSquare = square);
      }
      return;
    }

    if (piece?.color == _playerColor) {
      setState(() => _selectedSquare = square);
      return;
    }

    final legalMoves = _game.moves({'asObjects': true}).cast<chess.Move>();
    chess.Move? chosen;
    for (final move in legalMoves) {
      if (move.fromAlgebraic == _selectedSquare && move.toAlgebraic == square) {
        if (chosen == null || move.promotion == chess.Chess.QUEEN) {
          chosen = move;
        }
      }
    }
    if (chosen == null) {
      setState(() => _selectedSquare = null);
      return;
    }

    _uciMoves.add(MaiaEncoding.uci(chosen));
    _game.move(chosen);
    _positionHistory.add(_game.fen);
    setState(() {
      _selectedSquare = null;
      _status = _game.game_over ? _resultText() : 'Maia is thinking…';
    });
    if (!_game.game_over) _playMaiaMove();
  }

  Future<void> _playMaiaMove() async {
    if (_game.game_over) return;
    setState(() {
      _engineThinking = true;
      _status = 'Maia is thinking at $_elo Elo…';
    });
    try {
      final tokens = MaiaEncoding.historicalTokens(_positionHistory);
      final response = await _engineChannel.invokeMethod<List<dynamic>>(
        'predict',
        {'tokens': tokens, 'selfElo': _elo, 'opponentElo': _elo},
      );
      if (response == null || response.length != 4352) {
        throw StateError('Maia returned an invalid policy vector.');
      }
      final logits = response
          .cast<num>()
          .map((value) => value.toDouble())
          .toList();
      final legalMoves = _game.moves({'asObjects': true}).cast<chess.Move>();
      final move = MaiaEncoding.sampleLegalMove(_game, legalMoves, logits);
      if (!mounted) return;
      _uciMoves.add(MaiaEncoding.uci(move));
      _game.move(move);
      _positionHistory.add(_game.fen);
      setState(() {
        _engineThinking = false;
        _status = _game.game_over ? _resultText() : 'Your move.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _engineThinking = false;
        _status = 'Maia error: $error';
      });
    }
  }

  String _resultText() {
    if (_game.in_checkmate) {
      return _game.turn == _playerColor
          ? 'Checkmate — Maia wins.'
          : 'Checkmate — you win!';
    }
    return 'Draw.';
  }

  Future<void> _copyPgn() async {
    await Clipboard.setData(ClipboardData(text: _game.pgn()));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('PGN copied')));
    }
  }

  Future<void> _analyzeGame() async {
    if (_analysisRunning || _positionHistory.length < 2) return;
    setState(() {
      _analysisRunning = true;
      _analysisProgress = 0;
    });
    try {
      final maiaReviews = <({double probability, String topMove})>[];
      for (var i = 0; i < _uciMoves.length; i++) {
        final position = chess.Chess.fromFEN(_positionHistory[i]);
        final response = await _engineChannel.invokeMethod<List<dynamic>>(
          'predict',
          {
            'tokens': MaiaEncoding.historicalTokens(
              _positionHistory.sublist(0, i + 1),
            ),
            'selfElo': _elo,
            'opponentElo': _elo,
          },
        );
        if (response == null) {
          throw StateError('Maia review returned no policy.');
        }
        maiaReviews.add(
          MaiaEncoding.reviewMove(
            position,
            _uciMoves[i],
            response.cast<num>().map((value) => value.toDouble()).toList(),
          ),
        );
        if (mounted) setState(() => _analysisProgress = i + 1);
      }
      final evaluations = <int>[];
      for (var i = 0; i < _positionHistory.length; i++) {
        evaluations.add(
          await StockfishAnalyzer.instance.evaluate(_positionHistory[i]),
        );
        if (mounted) {
          setState(() => _analysisProgress = _uciMoves.length + i + 1);
        }
      }
      if (!mounted) return;
      final moves = _game.san_moves().whereType<String>().toList();
      final entries = <AnalysisEntry>[];
      for (var i = 0; i < moves.length; i++) {
        final before = evaluations[i];
        final after = evaluations[i + 1];
        final loss = i.isEven ? before - after : after - before;
        entries.add(
          AnalysisEntry(
            moves[i],
            after,
            max(0, loss),
            maiaReviews[i].probability,
            maiaReviews[i].topMove,
          ),
        );
      }
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => _analysisSheet(entries),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stockfish analysis failed: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _analysisRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maia Chess'),
        actions: [
          IconButton(
            onPressed: _started ? _startGame : null,
            icon: const Icon(Icons.refresh),
            tooltip: 'New game',
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final boardSize = min(constraints.maxWidth, 560.0);
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_started) _setupCard(),
                      if (_started) ...[
                        _statusCard(),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: boardSize,
                          height: boardSize,
                          child: _board(),
                        ),
                        const SizedBox(height: 12),
                        _gameInfoCard(),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _setupCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Play a human-like opponent',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Maia-3 runs entirely on your phone. No account or network connection is required.',
            ),
            const SizedBox(height: 24),
            const Text('Your side'),
            const SizedBox(height: 8),
            SegmentedButton<PlayerSide>(
              segments: const [
                ButtonSegment(value: PlayerSide.white, label: Text('White')),
                ButtonSegment(value: PlayerSide.black, label: Text('Black')),
                ButtonSegment(value: PlayerSide.random, label: Text('Random')),
              ],
              selected: {_sideChoice},
              onSelectionChanged: (value) =>
                  setState(() => _sideChoice = value.first),
            ),
            const SizedBox(height: 20),
            Text('Maia rating: $_elo'),
            Slider(
              min: 500,
              max: 2500,
              divisions: 20,
              value: _elo.toDouble(),
              label: '$_elo',
              onChanged: (value) => setState(() => _elo = value.round()),
            ),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => setState(() => _elo = 800),
                  child: const Text('Easy 800'),
                ),
                TextButton(
                  onPressed: () => setState(() => _elo = 1500),
                  child: const Text('Medium 1500'),
                ),
                TextButton(
                  onPressed: () => setState(() => _elo = 2200),
                  child: const Text('Hard 2200'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _startGame,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start game'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusCard() {
    return Card(
      child: ListTile(
        leading: _engineThinking
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(_game.game_over ? Icons.flag : Icons.smart_toy_outlined),
        title: Text(_status),
        subtitle: Text('Maia-3 79M · $_elo Elo · offline'),
      ),
    );
  }

  Widget _board() {
    final ranks = _playerIsWhite
        ? List.generate(8, (i) => 8 - i)
        : List.generate(8, (i) => i + 1);
    final files = _playerIsWhite
        ? _files.split('')
        : _files.split('').reversed.toList();
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black54, width: 2),
      ),
      child: Column(
        children: [
          for (final rank in ranks)
            Expanded(
              child: Row(
                children: [
                  for (final file in files)
                    Expanded(
                      child: _square(
                        '$file$rank',
                        (_files.indexOf(file) + rank).isEven,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _square(String square, bool light) {
    final piece = _game.get(square);
    final key = piece == null
        ? null
        : '${piece.color == chess.Color.WHITE ? 'w' : 'b'}${piece.type.name}';
    final selected = square == _selectedSquare;
    return Material(
      color: selected
          ? const Color(0xffd7b94e)
          : light
          ? const Color(0xffd8c7a3)
          : const Color(0xff71846e),
      child: InkWell(
        onTap: () => _tapSquare(square),
        child: Center(
          child: Text(
            key == null ? '' : _pieceSymbols[key]!,
            style: const TextStyle(
              fontSize: 39,
              height: 1,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _gameInfoCard() {
    final moves = _game.san_moves().whereType<String>().toList();
    final moveText = <String>[];
    for (var i = 0; i < moves.length; i += 2) {
      moveText.add(
        '${i ~/ 2 + 1}. ${moves[i]}${i + 1 < moves.length ? ' ${moves[i + 1]}' : ''}',
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(moveText.isEmpty ? 'No moves yet' : moveText.join('  ')),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _copyPgn,
              icon: const Icon(Icons.copy),
              label: const Text('Copy PGN'),
            ),
            if (_game.game_over || moves.length >= 4)
              FilledButton.tonalIcon(
                onPressed: _analysisRunning ? null : _analyzeGame,
                icon: _analysisRunning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.analytics_outlined),
                label: Text(
                  _analysisRunning
                      ? 'Analyzing $_analysisProgress/${_positionHistory.length + _uciMoves.length}'
                      : 'Analyze with Stockfish',
                ),
              ),
            if (_game.game_over)
              FilledButton.icon(
                onPressed: _startGame,
                icon: const Icon(Icons.replay),
                label: const Text('Rematch'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _analysisSheet(List<AnalysisEntry> entries) {
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .72,
        maxChildSize: .94,
        builder: (context, controller) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Maia + Stockfish review',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Text('Maia human likelihood · Stockfish depth 12'),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return ListTile(
                      dense: true,
                      leading: Text(index.isEven ? '${index ~/ 2 + 1}.' : '…'),
                      title: Text(entry.move),
                      subtitle: Text(
                        '${entry.label == null ? '' : '${entry.label} · '}'
                        'Maia ${(entry.maiaProbability * 100).toStringAsFixed(1)}%'
                        '${entry.maiaTopMove == _uciMoves[index] ? '' : ' · expected ${entry.maiaTopMove}'}',
                      ),
                      trailing: Text(entry.evaluationText),
                    );
                  },
                ),
              ),
              OutlinedButton.icon(
                onPressed: _copyPgn,
                icon: const Icon(Icons.copy),
                label: const Text('Copy PGN'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    unawaited(StockfishAnalyzer.instance.close());
    super.dispose();
  }
}

class AnalysisEntry {
  const AnalysisEntry(
    this.move,
    this.evaluation,
    this.loss,
    this.maiaProbability,
    this.maiaTopMove,
  );

  final String move;
  final int evaluation;
  final int loss;
  final double maiaProbability;
  final String maiaTopMove;

  String? get label => switch (loss) {
    >= 300 => 'Blunder',
    >= 150 => 'Mistake',
    >= 70 => 'Inaccuracy',
    _ => null,
  };

  String get evaluationText {
    if (evaluation.abs() >= 10000) {
      return evaluation > 0 ? 'White mates' : 'Black mates';
    }
    final pawns = evaluation / 100;
    return '${pawns >= 0 ? '+' : ''}${pawns.toStringAsFixed(2)}';
  }
}

class StockfishAnalyzer {
  StockfishAnalyzer._();

  static final instance = StockfishAnalyzer._();
  final Stockfish _engine = Stockfish.instance;
  Future<void>? _startup;

  Future<void> _ensureStarted() async {
    _startup ??= _engine.start().then((_) {
      _engine.stdin = 'setoption name Threads value 2';
      _engine.stdin = 'setoption name Hash value 64';
    });
    await _startup;
  }

  Future<int> evaluate(String fen) async {
    await _ensureStarted();
    final completer = Completer<int>();
    var latest = 0;
    late StreamSubscription<String> subscription;
    subscription = _engine.stdout.listen((line) {
      if (line.startsWith('info ') && line.contains(' score ')) {
        final cp = RegExp(r' score cp (-?\d+)').firstMatch(line);
        final mate = RegExp(r' score mate (-?\d+)').firstMatch(line);
        if (cp != null) latest = int.parse(cp.group(1)!);
        if (mate != null) {
          latest = int.parse(mate.group(1)!).isNegative ? -10000 : 10000;
        }
      }
      if (line.startsWith('bestmove ') && !completer.isCompleted) {
        completer.complete(latest);
      }
    });
    _engine.stdin = 'position fen $fen';
    _engine.stdin = 'go depth 12';
    try {
      final sideToMoveScore = await completer.future.timeout(
        const Duration(seconds: 20),
      );
      final blackToMove = fen.split(' ')[1] == 'b';
      return blackToMove ? -sideToMoveScore : sideToMoveScore;
    } finally {
      await subscription.cancel();
    }
  }

  Future<void> close() async {
    await _engine.quit();
    _startup = null;
  }
}

class MaiaEncoding {
  static final Random _random = Random.secure();

  static List<double> historicalTokens(List<String> positions) {
    final recent = positions.length > 8
        ? positions.sublist(positions.length - 8)
        : List<String>.from(positions);
    final padded = <String>[];
    while (padded.length + recent.length < 8) {
      padded.add(recent.first);
    }
    padded.addAll(recent);
    final boards = padded.map(tokenizeFen).toList();
    return List<double>.generate(64 * 97, (index) {
      final square = index ~/ 97;
      final channel = index % 97;
      if (channel == 96) return 0;
      final historyIndex = channel ~/ 12;
      final pieceChannel = channel % 12;
      return boards[historyIndex][square * 12 + pieceChannel];
    });
  }

  static List<double> tokenizeFen(String fen) {
    final parts = fen.split(' ');
    final blackToMove = parts[1] == 'b';
    final result = List<double>.filled(64 * 12, 0);
    final ranks = parts[0].split('/');
    for (var fenRank = 0; fenRank < 8; fenRank++) {
      var file = 0;
      for (final symbol in ranks[fenRank].split('')) {
        final empty = int.tryParse(symbol);
        if (empty != null) {
          file += empty;
          continue;
        }
        final originalWhite = symbol == symbol.toUpperCase();
        final type = symbol.toLowerCase();
        final originalRank = 8 - fenRank;
        final rank = blackToMove ? 9 - originalRank : originalRank;
        final white = blackToMove ? !originalWhite : originalWhite;
        final square = file + (rank - 1) * 8;
        final piece = const {
          'p': 0,
          'n': 1,
          'b': 2,
          'r': 3,
          'q': 4,
          'k': 5,
        }[type]!;
        result[square * 12 + piece + (white ? 0 : 6)] = 1;
        file++;
      }
    }
    return result;
  }

  static chess.Move sampleLegalMove(
    chess.Chess game,
    List<chess.Move> legalMoves,
    List<double> logits,
  ) {
    final scored = legalMoves.map((move) {
      final uci =
          '${move.fromAlgebraic}${move.toAlgebraic}${move.promotion?.name ?? ''}';
      return (
        move: move,
        logit: logits[moveIndex(uci, game.turn == chess.Color.BLACK)],
      );
    }).toList();
    final maxLogit = scored.map((item) => item.logit).reduce(max);
    final weights = scored.map((item) => exp(item.logit - maxLogit)).toList();
    final total = weights.reduce((a, b) => a + b);
    var target = _random.nextDouble() * total;
    for (var i = 0; i < scored.length; i++) {
      target -= weights[i];
      if (target <= 0) return scored[i].move;
    }
    return scored.last.move;
  }

  static ({double probability, String topMove}) reviewMove(
    chess.Chess game,
    String playedMove,
    List<double> logits,
  ) {
    final legalMoves = game.moves({'asObjects': true}).cast<chess.Move>();
    final scored = legalMoves.map((move) {
      final moveUci = uci(move);
      return (
        uci: moveUci,
        logit: logits[moveIndex(moveUci, game.turn == chess.Color.BLACK)],
      );
    }).toList();
    final maxLogit = scored.map((item) => item.logit).reduce(max);
    final weights = scored.map((item) => exp(item.logit - maxLogit)).toList();
    final total = weights.reduce((a, b) => a + b);
    var probability = 0.0;
    var bestIndex = 0;
    for (var i = 0; i < scored.length; i++) {
      if (scored[i].uci == playedMove) probability = weights[i] / total;
      if (weights[i] > weights[bestIndex]) bestIndex = i;
    }
    return (probability: probability, topMove: scored[bestIndex].uci);
  }

  static String uci(chess.Move move) =>
      '${move.fromAlgebraic}${move.toAlgebraic}${move.promotion?.name ?? ''}';

  static int moveIndex(String uci, bool blackToMove) {
    final normalized = blackToMove ? mirrorMove(uci) : uci;
    if (normalized.length == 5) {
      final fromFile = _fileIndex(normalized[0]);
      final toFile = _fileIndex(normalized[2]);
      final piece = const {'q': 0, 'r': 1, 'b': 2, 'n': 3}[normalized[4]]!;
      return 4096 + ((fromFile * 8 + toFile) * 4 + piece);
    }
    return _squareIndex(normalized.substring(0, 2)) * 64 +
        _squareIndex(normalized.substring(2, 4));
  }

  static String mirrorMove(String uci) {
    String mirrorSquare(String square) =>
        '${square[0]}${9 - int.parse(square[1])}';
    return '${mirrorSquare(uci.substring(0, 2))}${mirrorSquare(uci.substring(2, 4))}${uci.length == 5 ? uci[4] : ''}';
  }

  static int _fileIndex(String file) => file.codeUnitAt(0) - 'a'.codeUnitAt(0);
  static int _squareIndex(String square) =>
      _fileIndex(square[0]) + (int.parse(square[1]) - 1) * 8;
}

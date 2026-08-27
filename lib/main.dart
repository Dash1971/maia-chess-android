import 'dart:async';
import 'dart:math';

import 'package:chess/chess.dart' as chess;
import 'package:chessground/chessground.dart' as cg;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multistockfish/multistockfish.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MaiaChessApp());

const maiaEngineChannel = MethodChannel('maia_chess/engine');
const maiaProjectUrl = 'https://github.com/CSSLab/maia3';
const lichessChessgroundUrl =
    'https://github.com/lichess-org/flutter-chessground';
const lichessMultistockfishUrl =
    'https://github.com/lichess-org/dart-multistockfish';

bool isPremoveDestination(String fen, String from, String to) {
  final pieces = cg.readFen(fen);
  return cg
      .premovesOf(dc.Square.fromName(from), pieces, canCastle: true)
      .contains(dc.Square.fromName(to));
}

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

enum TimePreset {
  unlimited,
  bullet,
  blitz,
  blitzFive,
  rapid,
  classical,
  custom,
}

extension TimePresetDetails on TimePreset {
  String get label => switch (this) {
    TimePreset.unlimited => 'Unlimited',
    TimePreset.bullet => '1 + 0',
    TimePreset.blitz => '3 + 2',
    TimePreset.blitzFive => '5 + 3',
    TimePreset.rapid => '10 + 0',
    TimePreset.classical => '15 + 10',
    TimePreset.custom => 'Custom',
  };

  int get minutes => switch (this) {
    TimePreset.bullet => 1,
    TimePreset.blitz => 3,
    TimePreset.blitzFive => 5,
    TimePreset.rapid => 10,
    TimePreset.classical => 15,
    _ => 0,
  };

  int get increment => switch (this) {
    TimePreset.blitz => 2,
    TimePreset.blitzFive => 3,
    TimePreset.classical => 10,
    _ => 0,
  };
}

class ClockSnapshot {
  const ClockSnapshot(this.whiteMillis, this.blackMillis);

  final int whiteMillis;
  final int blackMillis;
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  chess.Chess _game = chess.Chess();
  final List<String> _positionHistory = [];
  final List<String> _uciMoves = [];
  PlayerSide _sideChoice = PlayerSide.white;
  chess.Color _playerColor = chess.Color.WHITE;
  int _elo = 1500;
  String? _selectedSquare;
  String? _premoveFrom;
  String? _premoveTo;
  String _status = 'Choose your settings and start a game.';
  bool _started = false;
  bool _engineThinking = false;
  String? _forcedResult;
  bool _humanTiming = false;
  double _temperature = 0.5;
  double _topP = 0.9;
  TimePreset _timePreset = TimePreset.unlimited;
  int _customMinutes = 10;
  int _customIncrement = 0;
  int _whiteMillis = 0;
  int _blackMillis = 0;
  DateTime? _turnStartedAt;
  Timer? _clockTimer;
  final List<ClockSnapshot> _clockHistory = [];
  int _gameGeneration = 0;
  final Random _timingRandom = Random.secure();

  bool get _playerIsWhite => _playerColor == chess.Color.WHITE;
  bool get _isPlayerTurn => _game.turn == _playerColor;
  bool get _gameFinished => _game.game_over || _forcedResult != null;
  bool get _clockEnabled => _timePreset != TimePreset.unlimited;
  bool get _canTakeBack =>
      !_gameFinished &&
      (_engineThinking ? _uciMoves.isNotEmpty : _uciMoves.length >= 2);
  int get _baseMinutes =>
      _timePreset == TimePreset.custom ? _customMinutes : _timePreset.minutes;
  int get _incrementSeconds => _timePreset == TimePreset.custom
      ? _customIncrement
      : _timePreset.increment;

  @override
  void initState() {
    super.initState();
    unawaited(_loadEnginePreferences());
  }

  Future<void> _loadEnginePreferences() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _humanTiming = preferences.getBool('humanTiming') ?? false;
      _temperature = (preferences.getDouble('temperatureV2') ?? 0.5).clamp(
        0.0,
        1.0,
      );
      _topP = (preferences.getDouble('topPV2') ?? 0.9).clamp(0.0, 1.0);
    });
  }

  Future<void> _saveEnginePreferences() async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setBool('humanTiming', _humanTiming),
      preferences.setDouble('temperatureV2', _temperature),
      preferences.setDouble('topPV2', _topP),
    ]);
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Maia Chess for Android',
      applicationVersion: '1.6.1',
      children: [
        const Text(
          'Powered by Maia-3, the human-like chess engine developed by the '
          'University of Toronto Computational Social Science Lab.',
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => maiaEngineChannel.invokeMethod<void>('openUrl', {
            'url': maiaProjectUrl,
          }),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Maia-3 project and source code'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Board interface, default brown theme, and Cburnett pieces are '
          'provided by Lichess Flutter Chessground. Local Stockfish support '
          'uses Lichess multistockfish.',
        ),
        TextButton.icon(
          onPressed: () => maiaEngineChannel.invokeMethod<void>('openUrl', {
            'url': lichessChessgroundUrl,
          }),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Lichess Flutter Chessground'),
        ),
        TextButton.icon(
          onPressed: () => maiaEngineChannel.invokeMethod<void>('openUrl', {
            'url': lichessMultistockfishUrl,
          }),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Lichess multistockfish'),
        ),
        const Text(
          'This independent community app is not an official Maia-3 or '
          'University of Toronto or Lichess application.',
        ),
      ],
    );
  }

  void _startGame() {
    _gameGeneration++;
    _clockTimer?.cancel();
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
      _premoveFrom = null;
      _premoveTo = null;
      _forcedResult = null;
      _started = true;
      final startingMillis = _baseMinutes * 60 * 1000;
      _whiteMillis = startingMillis;
      _blackMillis = startingMillis;
      _turnStartedAt = _clockEnabled ? DateTime.now() : null;
      _clockHistory
        ..clear()
        ..add(ClockSnapshot(_whiteMillis, _blackMillis));
      _status = _playerIsWhite ? 'Your move.' : 'Game in progress.';
      final date = DateTime.now();
      final dateTag =
          '${date.year.toString().padLeft(4, '0')}.'
          '${date.month.toString().padLeft(2, '0')}.'
          '${date.day.toString().padLeft(2, '0')}';
      _game.set_header([
        'Event',
        'Maia Android App Game',
        'Site',
        'Maia Chess for Android',
        'Date',
        dateTag,
        'Round',
        '-',
        'White',
        _playerIsWhite ? 'Player' : 'Maia-3 79M ($_elo)',
        'Black',
        _playerIsWhite ? 'Maia-3 79M ($_elo)' : 'Player',
        'Result',
        '*',
      ]);
    });
    if (_clockEnabled) {
      _clockTimer = Timer.periodic(
        const Duration(milliseconds: 200),
        (_) => _tickClock(),
      );
    }
    if (!_playerIsWhite) _playMaiaMove();
  }

  int _liveMillis(chess.Color color) {
    final base = color == chess.Color.WHITE ? _whiteMillis : _blackMillis;
    if (!_clockEnabled || _gameFinished || _game.turn != color) return base;
    final started = _turnStartedAt;
    if (started == null) return base;
    return max(0, base - DateTime.now().difference(started).inMilliseconds);
  }

  void _commitClock(chess.Color mover) {
    if (!_clockEnabled) return;
    final remaining = _liveMillis(mover) + _incrementSeconds * 1000;
    if (mover == chess.Color.WHITE) {
      _whiteMillis = remaining;
    } else {
      _blackMillis = remaining;
    }
    _turnStartedAt = DateTime.now();
  }

  void _recordClockSnapshot() {
    _clockHistory.add(ClockSnapshot(_whiteMillis, _blackMillis));
  }

  void _tickClock() {
    if (!mounted || !_started || !_clockEnabled || _gameFinished) return;
    final remaining = _liveMillis(_game.turn);
    if (remaining <= 0) {
      final whiteFlagged = _game.turn == chess.Color.WHITE;
      final result = whiteFlagged ? '0-1' : '1-0';
      _gameGeneration++;
      _clockTimer?.cancel();
      setState(() {
        if (whiteFlagged) {
          _whiteMillis = 0;
        } else {
          _blackMillis = 0;
        }
        _forcedResult = result;
        _engineThinking = false;
        _game.set_header(['Result', result, 'Termination', 'Time forfeit']);
        _status = whiteFlagged
            ? 'White ran out of time.'
            : 'Black ran out of time.';
      });
      return;
    }
    setState(() {});
  }

  Future<void> _tapSquare(String square) async {
    if (!_started || _gameFinished) {
      return;
    }
    if (_engineThinking || !_isPlayerTurn) {
      _tapPremoveSquare(square);
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

    final candidates = _game
        .moves({'asObjects': true})
        .cast<chess.Move>()
        .where(
          (move) =>
              move.fromAlgebraic == _selectedSquare &&
              move.toAlgebraic == square,
        )
        .toList();
    if (candidates.isEmpty) {
      setState(() => _selectedSquare = null);
      return;
    }
    var chosen = candidates.first;
    if (candidates.length > 1) {
      final promotion = await _choosePromotion();
      if (promotion == null || !mounted || _gameFinished || !_isPlayerTurn) {
        return;
      }
      chosen = candidates.firstWhere((move) => move.promotion == promotion);
    }

    _commitClock(_playerColor);
    _uciMoves.add(MaiaEncoding.uci(chosen));
    _game.move(chosen);
    _positionHistory.add(_game.fen);
    _recordClockSnapshot();
    setState(() {
      _selectedSquare = null;
      _status = _game.game_over ? _finishNaturalGame() : 'Game in progress.';
    });
    if (!_game.game_over) _playMaiaMove();
  }

  void _tapPremoveSquare(String square) {
    final piece = _game.get(square);
    if (_premoveFrom == null) {
      if (piece?.color == _playerColor) {
        setState(() {
          _premoveFrom = square;
          _premoveTo = null;
          _status = 'Premove: select destination.';
        });
      }
      return;
    }
    final from = _premoveFrom!;
    if (isPremoveDestination(_game.fen, from, square)) {
      setState(() {
        _premoveTo = square;
        _status = 'Premove queued: $from–$square';
      });
      return;
    }
    if (piece?.color == _playerColor) {
      setState(() {
        _premoveFrom = square;
        _premoveTo = null;
      });
    }
  }

  Future<bool> _playQueuedPremove() async {
    final from = _premoveFrom;
    final to = _premoveTo;
    _premoveFrom = null;
    _premoveTo = null;
    if (from == null || to == null || !_isPlayerTurn || _gameFinished) {
      return false;
    }
    final candidates = _game
        .moves({'asObjects': true})
        .cast<chess.Move>()
        .where((move) => move.fromAlgebraic == from && move.toAlgebraic == to)
        .toList();
    if (candidates.isEmpty) return false;
    var chosen = candidates.first;
    if (candidates.length > 1) {
      final promotion = await _choosePromotion();
      if (promotion == null || !mounted || _gameFinished) return false;
      chosen = candidates.firstWhere((move) => move.promotion == promotion);
    }
    _commitClock(_playerColor);
    _uciMoves.add(MaiaEncoding.uci(chosen));
    _game.move(chosen);
    _positionHistory.add(_game.fen);
    _recordClockSnapshot();
    return true;
  }

  Future<chess.PieceType?> _choosePromotion() => showDialog<chess.PieceType>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Promote pawn'),
      content: const Text('Choose a piece'),
      actions: [
        for (final choice in const [
          (piece: chess.Chess.QUEEN, label: 'Queen'),
          (piece: chess.Chess.ROOK, label: 'Rook'),
          (piece: chess.Chess.BISHOP, label: 'Bishop'),
          (piece: chess.Chess.KNIGHT, label: 'Knight'),
        ])
          TextButton(
            onPressed: () => Navigator.pop(context, choice.piece),
            child: Text(choice.label),
          ),
      ],
    ),
  );

  Future<void> _playMaiaMove() async {
    if (_game.game_over) return;
    final generation = _gameGeneration;
    final thinkingTimer = Stopwatch()..start();
    setState(() => _engineThinking = true);
    try {
      final tokens = MaiaEncoding.historicalTokens(_positionHistory);
      final response = await maiaEngineChannel.invokeMethod<List<dynamic>>(
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
      final move = MaiaEncoding.sampleLegalMove(
        _game,
        legalMoves,
        logits,
        temperature: _temperature,
        topP: _topP,
      );
      if (_humanTiming) {
        final target = _humanThinkDuration();
        final remaining = target - thinkingTimer.elapsed;
        if (remaining > Duration.zero) await Future<void>.delayed(remaining);
      }
      if (!mounted || generation != _gameGeneration || _gameFinished) return;
      _commitClock(_game.turn);
      _uciMoves.add(MaiaEncoding.uci(move));
      _game.move(move);
      _positionHistory.add(_game.fen);
      _recordClockSnapshot();
      final premovePlayed = await _playQueuedPremove();
      if (!mounted || generation != _gameGeneration || _gameFinished) return;
      setState(() {
        _engineThinking = false;
        _status = _game.game_over
            ? _finishNaturalGame()
            : premovePlayed
            ? 'Game in progress.'
            : 'Your move.';
      });
      if (premovePlayed && !_game.game_over) unawaited(_playMaiaMove());
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _engineThinking = false;
        _status = 'Maia error: $error';
      });
    }
  }

  Duration _humanThinkDuration() {
    final u1 = max(_timingRandom.nextDouble(), 0.000001);
    final u2 = _timingRandom.nextDouble();
    final gaussian = sqrt(-2 * log(u1)) * cos(2 * pi * u2);
    var seconds = exp(0.50 + gaussian * 0.44).clamp(0.55, 4.5);
    if (_timingRandom.nextDouble() < 0.06) {
      seconds += 1.5 + _timingRandom.nextDouble() * 3;
    }
    return Duration(milliseconds: (seconds * 1000).round());
  }

  String _resultText() {
    if (_forcedResult != null) {
      return _forcedResult == '1-0'
          ? (_playerIsWhite ? 'You win.' : 'Maia wins.')
          : (_playerIsWhite ? 'Maia wins.' : 'You win.');
    }
    if (_game.in_checkmate) {
      return _game.turn == _playerColor
          ? 'Checkmate — Maia wins.'
          : 'Checkmate — you win!';
    }
    return 'Draw.';
  }

  String _finishNaturalGame() {
    _clockTimer?.cancel();
    final result = _game.in_checkmate
        ? (_game.turn == chess.Color.WHITE ? '0-1' : '1-0')
        : '1/2-1/2';
    _game.set_header(['Result', result]);
    return _resultText();
  }

  Future<void> _resign() async {
    if (!_started || _gameFinished || _engineThinking) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resign game?'),
        content: const Text('This will end the game immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resign'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = _playerIsWhite ? '0-1' : '1-0';
    _gameGeneration++;
    _clockTimer?.cancel();
    setState(() {
      _forcedResult = result;
      _game.set_header(['Result', result, 'Termination', 'Player resigned']);
      _status = 'You resigned — Maia wins.';
    });
  }

  void _goHome() {
    _gameGeneration++;
    _clockTimer?.cancel();
    setState(() {
      _started = false;
      _engineThinking = false;
      _selectedSquare = null;
      _premoveFrom = null;
      _premoveTo = null;
      _status = 'Choose your settings and start a game.';
    });
  }

  void _takeBack() {
    if (!_started || !_canTakeBack) return;
    _gameGeneration++;
    final plies = _engineThinking ? 1 : min(2, _uciMoves.length);
    for (var i = 0; i < plies; i++) {
      _game.undo();
      _uciMoves.removeLast();
      _positionHistory.removeLast();
      if (_clockHistory.length > 1) _clockHistory.removeLast();
    }
    final clock = _clockHistory.last;
    setState(() {
      _whiteMillis = clock.whiteMillis;
      _blackMillis = clock.blackMillis;
      _turnStartedAt = _clockEnabled ? DateTime.now() : null;
      _engineThinking = false;
      _selectedSquare = null;
      _premoveFrom = null;
      _premoveTo = null;
      _forcedResult = null;
      _game.set_header(['Result', '*']);
      _status = 'Move taken back. Your move.';
    });
    if (_clockEnabled) {
      _clockTimer?.cancel();
      _clockTimer = Timer.periodic(
        const Duration(milliseconds: 200),
        (_) => _tickClock(),
      );
    }
  }

  Future<void> _copyPgn() async {
    await Clipboard.setData(ClipboardData(text: _game.pgn()));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('PGN copied')));
    }
  }

  Future<void> _analyzeGame() async {
    if (_positionHistory.length < 2) return;
    final moves = _game.san_moves().whereType<String>().toList();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReviewPage(
          positions: List.unmodifiable(_positionHistory),
          uciMoves: List.unmodifiable(_uciMoves),
          sanMoves: List.unmodifiable(moves),
          playerIsWhite: _playerIsWhite,
          pgn: _game.pgn(),
          onHome: _goHome,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maia Chess'),
        actions: [
          IconButton(
            onPressed: _showAbout,
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
          ),
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
                        if (_clockEnabled) ...[
                          _clockTile(
                            _playerIsWhite
                                ? chess.Color.BLACK
                                : chess.Color.WHITE,
                            'Maia',
                          ),
                          const SizedBox(height: 6),
                        ],
                        SizedBox(
                          width: boardSize,
                          height: boardSize,
                          child: _board(),
                        ),
                        if (_clockEnabled) ...[
                          const SizedBox(height: 6),
                          _clockTile(_playerColor, 'You'),
                        ],
                        MaterialDifference(fen: _game.fen),
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
            const SizedBox(height: 16),
            DropdownButtonFormField<TimePreset>(
              initialValue: _timePreset,
              decoration: const InputDecoration(
                labelText: 'Time control',
                border: OutlineInputBorder(),
              ),
              items: TimePreset.values
                  .map(
                    (preset) => DropdownMenuItem(
                      value: preset,
                      child: Text(preset.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _timePreset = value);
              },
            ),
            if (_timePreset == TimePreset.custom) ...[
              const SizedBox(height: 8),
              Text('Minutes: $_customMinutes'),
              Slider(
                min: 1,
                max: 60,
                divisions: 59,
                value: _customMinutes.toDouble(),
                label: '$_customMinutes',
                onChanged: (value) =>
                    setState(() => _customMinutes = value.round()),
              ),
              Text('Increment: $_customIncrement seconds'),
              Slider(
                min: 0,
                max: 30,
                divisions: 30,
                value: _customIncrement.toDouble(),
                label: '$_customIncrement',
                onChanged: (value) =>
                    setState(() => _customIncrement = value.round()),
              ),
            ],
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: const Text('Advanced'),
              subtitle: const Text('Timing and move sampling'),
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _humanTiming,
                  title: const Text('Human move timing'),
                  subtitle: const Text(
                    'Variable natural pauses before Maia moves',
                  ),
                  onChanged: (value) {
                    setState(() => _humanTiming = value);
                    unawaited(_saveEnginePreferences());
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Temperature: ${_temperature.toStringAsFixed(2)}',
                  ),
                  subtitle: Slider(
                    min: 0.00,
                    max: 1.00,
                    divisions: 20,
                    value: _temperature,
                    label: _temperature.toStringAsFixed(2),
                    onChanged: (value) => setState(() => _temperature = value),
                    onChangeEnd: (_) => unawaited(_saveEnginePreferences()),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Top-P: ${_topP.toStringAsFixed(2)}'),
                  subtitle: Slider(
                    min: 0.00,
                    max: 1.00,
                    divisions: 20,
                    value: _topP,
                    label: _topP.toStringAsFixed(2),
                    onChanged: (value) => setState(() => _topP = value),
                    onChangeEnd: (_) => unawaited(_saveEnginePreferences()),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _humanTiming = false;
                        _temperature = 0.5;
                        _topP = 0.9;
                      });
                      unawaited(_saveEnginePreferences());
                    },
                    child: const Text('Reset engine defaults'),
                  ),
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
        leading: Icon(_gameFinished ? Icons.flag : Icons.smart_toy_outlined),
        title: Text(_status),
        subtitle: Text('Maia-3 79M · $_elo Elo · offline'),
      ),
    );
  }

  Widget _clockTile(chess.Color color, String label) {
    final milliseconds = _liveMillis(color);
    final urgent = milliseconds < 10000;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _game.turn == color && !_gameFinished
              ? const Color(0xfff0f0f0)
              : const Color(0xff343735),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$label  ${_formatClock(milliseconds)}',
          style: TextStyle(
            color: urgent
                ? Colors.redAccent
                : _game.turn == color && !_gameFinished
                ? Colors.black
                : Colors.white70,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  String _formatClock(int milliseconds) {
    final safe = max(0, milliseconds);
    final minutes = safe ~/ 60000;
    final seconds = (safe % 60000) ~/ 1000;
    if (safe < 10000) {
      final tenths = (safe % 1000) ~/ 100;
      return '$minutes:${seconds.toString().padLeft(2, '0')}.$tenths';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _board() {
    final selected = <dc.Square, cg.SquareHighlight>{};
    if (_selectedSquare != null) {
      selected[dc.Square.fromName(_selectedSquare!)] = const cg.SquareHighlight(
        details: cg.HighlightDetails(solidColor: Color(0x99D59120)),
      );
    }
    for (final square in [_premoveFrom, _premoveTo]) {
      if (square != null) {
        selected[dc.Square.fromName(square)] = const cg.SquareHighlight(
          details: cg.HighlightDetails(solidColor: Color(0x99B84A4A)),
        );
      }
    }
    final lastMove = _uciMoves.isEmpty
        ? null
        : dc.NormalMove.fromUci(_uciMoves.last);
    return LayoutBuilder(
      builder: (context, constraints) => cg.StaticChessboard(
        size: constraints.biggest.shortestSide,
        orientation: _playerIsWhite ? dc.Side.white : dc.Side.black,
        fen: _game.fen,
        lastMove: lastMove,
        squareHighlights: selected,
        settings: const cg.StaticChessboardSettings(
          colorScheme: cg.ChessboardColorScheme.brown,
          pieceAssets: cg.PieceSet.cburnettAssets,
          enableCoordinates: true,
        ),
        onTouchedSquare: (square) => unawaited(_tapSquare(square.name)),
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
            if (_gameFinished)
              FilledButton.tonalIcon(
                onPressed: _analyzeGame,
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('Review with Stockfish'),
              ),
            if (!_gameFinished)
              TextButton.icon(
                onPressed: _canTakeBack ? _takeBack : null,
                icon: const Icon(Icons.undo),
                label: const Text('Takeback'),
              ),
            if (!_gameFinished)
              TextButton.icon(
                onPressed: _engineThinking ? null : _resign,
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Resign'),
              ),
            if (_gameFinished) ...[
              FilledButton.icon(
                onPressed: _startGame,
                icon: const Icon(Icons.replay),
                label: const Text('Rematch'),
              ),
              TextButton.icon(
                onPressed: _goHome,
                icon: const Icon(Icons.home_outlined),
                label: const Text('Home'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    unawaited(StockfishAnalyzer.instance.close());
    super.dispose();
  }
}

class ReviewPage extends StatefulWidget {
  const ReviewPage({
    required this.positions,
    required this.uciMoves,
    required this.sanMoves,
    required this.playerIsWhite,
    required this.pgn,
    required this.onHome,
    this.evaluator,
    super.key,
  });

  final List<String> positions;
  final List<String> uciMoves;
  final List<String> sanMoves;
  final bool playerIsWhite;
  final String pgn;
  final VoidCallback onHome;
  final Future<StockfishReview> Function(String fen)? evaluator;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  int _ply = 0;
  final Map<int, StockfishReview> _reviews = {};
  final Set<int> _loading = {};
  String? _analysisError;
  bool _flipped = false;
  bool _fullAnalysisRunning = false;
  int _fullAnalysisProgress = 0;
  List<StockfishReview>? _graphScores;

  StockfishReview? get _review => _reviews[_ply];

  @override
  void initState() {
    super.initState();
    unawaited(_analyzePosition(0));
  }

  Future<void> _analyzePosition(int ply) async {
    if (_reviews.containsKey(ply) || _loading.contains(ply)) return;
    setState(() {
      _loading.add(ply);
      _analysisError = null;
    });
    try {
      final evaluate = widget.evaluator ?? StockfishAnalyzer.instance.evaluate;
      final review = await evaluate(widget.positions[ply]);
      if (mounted) setState(() => _reviews[ply] = review);
    } catch (error) {
      if (mounted) setState(() => _analysisError = 'Stockfish failed: $error');
    } finally {
      if (mounted) setState(() => _loading.remove(ply));
    }
  }

  Future<void> _analyzeFullGame() async {
    if (_fullAnalysisRunning) return;
    setState(() {
      _fullAnalysisRunning = true;
      _fullAnalysisProgress = 0;
      _graphScores = null;
    });
    for (var i = 0; i < widget.positions.length && mounted; i++) {
      await _analyzePosition(i);
      if (mounted) setState(() => _fullAnalysisProgress = i + 1);
    }
    if (!mounted) return;
    setState(() {
      _graphScores = List.generate(
        widget.positions.length,
        (index) => _reviews[index] ?? const StockfishReview(0, ''),
      );
      _fullAnalysisRunning = false;
    });
  }

  Set<cg.Shape> get _arrows {
    final move = _review?.bestMove ?? '';
    if (move.length >= 4 && move != '(none)') {
      return {_arrow(move, const Color(0xff3d9be9))};
    }
    return const {};
  }

  cg.Arrow _arrow(String uci, Color color) => cg.Arrow(
    color: color,
    orig: dc.Square.fromName(uci.substring(0, 2)),
    dest: dc.Square.fromName(uci.substring(2, 4)),
  );

  void _step(int delta) {
    setState(() => _ply = (_ply + delta).clamp(0, widget.positions.length - 1));
    unawaited(_analyzePosition(_ply));
  }

  Future<void> _copyPgn() async {
    await Clipboard.setData(ClipboardData(text: widget.pgn));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('PGN copied')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final evaluation = _review?.evaluation;
    final mate = _review?.mate;
    final moveLabel = _ply == 0
        ? 'Starting position'
        : '${(_ply + 1) ~/ 2}${_ply.isOdd ? '.' : '…'} ${widget.sanMoves[_ply - 1]}';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game review'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _flipped = !_flipped),
            icon: const Icon(Icons.flip_camera_android_outlined),
            tooltip: 'Flip board',
          ),
          IconButton(
            onPressed: _copyPgn,
            icon: const Icon(Icons.copy),
            tooltip: 'Copy PGN',
          ),
          IconButton(
            onPressed: () {
              widget.onHome();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Home',
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Account for the scroll padding, evaluation bar, and gap so the
            // review row has finite dimensions without overflowing narrow phones.
            final boardSize = max(0.0, min(constraints.maxWidth - 56, 560.0));
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      SizedBox(
                        height: boardSize,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            EvaluationBar(evaluation: evaluation, mate: mate),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: boardSize,
                              height: boardSize,
                              child: cg.StaticChessboard(
                                size: boardSize,
                                orientation: _flipped
                                    ? (widget.playerIsWhite
                                          ? dc.Side.black
                                          : dc.Side.white)
                                    : (widget.playerIsWhite
                                          ? dc.Side.white
                                          : dc.Side.black),
                                fen: widget.positions[_ply],
                                lastMove: _ply == 0
                                    ? null
                                    : dc.NormalMove.fromUci(
                                        widget.uciMoves[_ply - 1],
                                      ),
                                shapes: _arrows,
                                settings: const cg.StaticChessboardSettings(
                                  colorScheme: cg.ChessboardColorScheme.brown,
                                  pieceAssets: cg.PieceSet.cburnettAssets,
                                  enableCoordinates: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      MaterialDifference(fen: widget.positions[_ply]),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _ply == 0 ? null : () => _step(-1),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Flexible(
                            child: Text(
                              '$moveLabel  ·  $_ply/${widget.uciMoves.length}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            onPressed: _ply == widget.positions.length - 1
                                ? null
                                : () => _step(1),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                      if (_graphScores != null) ...[
                        const SizedBox(height: 8),
                        AnalysisGraph(
                          scores: _graphScores!,
                          selectedPly: _ply,
                          onSelected: (ply) {
                            setState(() => _ply = ply);
                            unawaited(_analyzePosition(ply));
                          },
                        ),
                      ],
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: _loading.contains(_ply)
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.arrow_upward,
                                      color: Color(0xff3d9be9),
                                    ),
                              title: const Text('Stockfish best move'),
                              subtitle: Text(
                                _analysisError ??
                                    (_review == null
                                        ? 'Analyzing this position…'
                                        : 'Depth 12 · ${_formatEvaluation(_review!)}'),
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: _fullAnalysisRunning
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.show_chart),
                              title: const Text('Computer analysis graph'),
                              subtitle: Text(
                                _fullAnalysisRunning
                                    ? '$_fullAnalysisProgress/${widget.positions.length} positions'
                                    : _graphScores == null
                                    ? 'Analyze the full game on request'
                                    : 'Tap the graph to jump to a position',
                              ),
                              onTap: _fullAnalysisRunning
                                  ? null
                                  : _analyzeFullGame,
                            ),
                          ],
                        ),
                      ),
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

  String _formatEvaluation(StockfishReview review) {
    if (review.mate != null) return '#${review.mate}';
    final pawns = review.evaluation / 100;
    return '${pawns >= 0 ? '+' : ''}${pawns.toStringAsFixed(2)}';
  }
}

class AnalysisGraph extends StatelessWidget {
  const AnalysisGraph({
    required this.scores,
    required this.selectedPly,
    required this.onSelected,
    super.key,
  });

  final List<StockfishReview> scores;
  final int selectedPly;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          onTapDown: (details) {
            if (scores.length < 2) return;
            final fraction = (details.localPosition.dx / constraints.maxWidth)
                .clamp(0.0, 1.0);
            onSelected((fraction * (scores.length - 1)).round());
          },
          child: CustomPaint(
            painter: AnalysisGraphPainter(
              scores: scores,
              selectedPly: selectedPly,
            ),
          ),
        ),
      ),
    );
  }
}

class AnalysisGraphPainter extends CustomPainter {
  AnalysisGraphPainter({required this.scores, required this.selectedPly});

  final List<StockfishReview> scores;
  final int selectedPly;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(8),
    );
    canvas.save();
    canvas.clipRRect(bounds);
    final background = Paint()..color = const Color(0xff262421);
    canvas.drawRRect(bounds, background);
    if (scores.isEmpty) {
      canvas.restore();
      return;
    }
    final path = Path();
    final points = <Offset>[];
    for (var i = 0; i < scores.length; i++) {
      final normalized = scores[i].whiteWinningChances;
      final x = scores.length == 1 ? 0.0 : i * size.width / (scores.length - 1);
      final y = size.height / 2 - normalized * (size.height / 2 - 8);
      points.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final whiteArea = Path()
      ..moveTo(0, size.height)
      ..lineTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      whiteArea.lineTo(point.dx, point.dy);
    }
    whiteArea
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      whiteArea,
      Paint()
        ..color = const Color(0xffeeeeee)
        ..style = PaintingStyle.fill,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      Paint()
        ..color = Colors.black26
        ..strokeWidth = 1,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xff3d9be9)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    final selectedX = scores.length == 1
        ? 0.0
        : selectedPly * size.width / (scores.length - 1);
    canvas.drawLine(
      Offset(selectedX, 0),
      Offset(selectedX, size.height),
      Paint()
        ..color = const Color(0xffe6a23c)
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AnalysisGraphPainter oldDelegate) =>
      oldDelegate.selectedPly != selectedPly || oldDelegate.scores != scores;
}

class EvaluationBar extends StatelessWidget {
  const EvaluationBar({required this.evaluation, this.mate, super.key});

  final int? evaluation;
  final int? mate;

  @override
  Widget build(BuildContext context) {
    final score = evaluation;
    final whiteShare = mate != null
        ? (1 +
                  StockfishReview(
                    score ?? 0,
                    '',
                    mate: mate,
                  ).whiteWinningChances) /
              2
        : score == null
        ? 0.5
        : (1 + StockfishReview(score, '').whiteWinningChances) / 2;
    return SizedBox(
      width: 24,
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: ((1 - whiteShare) * 1000).round(),
                child: Container(color: const Color(0xff262421)),
              ),
              Expanded(
                flex: (whiteShare * 1000).round(),
                child: Container(color: const Color(0xfff0f0f0)),
              ),
            ],
          ),
          if (score != null || mate != null)
            Align(
              alignment: (mate ?? score!) < 0
                  ? Alignment.topCenter
                  : Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    _scoreLabel(score, mate),
                    style: TextStyle(
                      color: (mate ?? score!) < 0 ? Colors.white : Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _scoreLabel(int? score, int? mate) {
    if (mate != null) return '#$mate';
    if (score == null) return '';
    final pawns = score / 100;
    return '${pawns >= 0 ? '+' : ''}${pawns.toStringAsFixed(1)}';
  }
}

class MaterialDifference extends StatelessWidget {
  const MaterialDifference({required this.fen, super.key});

  final String fen;

  @override
  Widget build(BuildContext context) {
    final white = <String, int>{};
    final black = <String, int>{};
    for (final rune in fen.split(' ').first.runes) {
      final piece = String.fromCharCode(rune);
      if (!'prnbqPRNBQ'.contains(piece)) continue;
      final target = piece == piece.toUpperCase() ? white : black;
      final key = piece.toLowerCase();
      target[key] = (target[key] ?? 0) + 1;
    }
    const values = {'p': 1, 'n': 3, 'b': 3, 'r': 5, 'q': 9};
    const whiteGlyphs = {'q': '♕', 'r': '♖', 'b': '♗', 'n': '♘', 'p': '♙'};
    const blackGlyphs = {'q': '♛', 'r': '♜', 'b': '♝', 'n': '♞', 'p': '♟'};
    const order = ['q', 'r', 'b', 'n', 'p'];
    final whiteExtras = <String>[];
    final blackExtras = <String>[];
    var whiteScore = 0;
    var blackScore = 0;
    for (final piece in order) {
      final difference = (white[piece] ?? 0) - (black[piece] ?? 0);
      if (difference > 0) {
        whiteExtras.addAll(List.filled(difference, blackGlyphs[piece]!));
        whiteScore += values[piece]! * difference;
      } else if (difference < 0) {
        blackExtras.addAll(List.filled(-difference, whiteGlyphs[piece]!));
        blackScore += values[piece]! * -difference;
      }
    }
    final net = whiteScore - blackScore;
    return Semantics(
      label: 'Material difference',
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            whiteExtras.isEmpty ? '—' : whiteExtras.join(),
            style: const TextStyle(fontSize: 22),
          ),
          if (net > 0) Text(' +$net'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('material', style: TextStyle(color: Colors.white60)),
          ),
          Text(
            blackExtras.isEmpty ? '—' : blackExtras.join(),
            style: const TextStyle(fontSize: 22),
          ),
          if (net < 0) Text(' +${-net}'),
        ],
      ),
    );
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
  Future<void> _queue = Future<void>.value();

  Future<void> _ensureStarted() async {
    _startup ??= _engine.start().then((_) {
      _engine.stdin = 'setoption name Threads value 2';
      _engine.stdin = 'setoption name Hash value 64';
    });
    await _startup;
  }

  Future<StockfishReview> evaluate(String fen) async {
    final result = Completer<StockfishReview>();
    _queue = _queue.then((_) async {
      try {
        result.complete(await _evaluateNow(fen));
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }

  Future<StockfishReview> _evaluateNow(String fen) async {
    final position = chess.Chess.fromFEN(fen);
    if (position.in_checkmate) {
      final whiteToMove = fen.split(' ')[1] == 'w';
      return StockfishReview(0, '(none)', mate: whiteToMove ? -1 : 1);
    }
    if (position.game_over) return const StockfishReview(0, '(none)');

    await _ensureStarted();
    final completer = Completer<int>();
    var latest = 0;
    int? latestMate;
    var bestMove = '';
    late StreamSubscription<String> subscription;
    subscription = _engine.stdout.listen((line) {
      if (line.startsWith('info ') && line.contains(' score ')) {
        final cp = RegExp(r' score cp (-?\d+)').firstMatch(line);
        final mate = RegExp(r' score mate (-?\d+)').firstMatch(line);
        if (cp != null) {
          latest = int.parse(cp.group(1)!);
          latestMate = null;
        }
        if (mate != null) {
          latestMate = int.parse(mate.group(1)!);
        }
      }
      if (line.startsWith('bestmove ') && !completer.isCompleted) {
        bestMove = line.split(' ')[1];
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
      return StockfishReview(
        blackToMove ? -sideToMoveScore : sideToMoveScore,
        bestMove,
        mate: latestMate == null
            ? null
            : blackToMove
            ? -latestMate!
            : latestMate,
      );
    } finally {
      await subscription.cancel();
    }
  }

  Future<void> close() async {
    await _queue;
    await _engine.quit();
    _startup = null;
  }
}

class StockfishReview {
  const StockfishReview(this.evaluation, this.bestMove, {this.mate});

  final int evaluation;
  final String bestMove;
  final int? mate;

  double get whiteWinningChances {
    final value = mate == null
        ? evaluation.clamp(-1000, 1000)
        : (21 - min(10, mate!.abs())) * 100 * (mate! > 0 ? 1 : -1);
    return 2 / (1 + exp(-0.00368208 * value)) - 1;
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
    List<double> logits, {
    double temperature = 1.0,
    double topP = 1.0,
  }) {
    final safeTopP = topP.clamp(0.0, 1.0);
    if (temperature <= 0) {
      return legalMoves.reduce((best, move) {
        final bestIndex = moveIndex(uci(best), game.turn == chess.Color.BLACK);
        final moveIndexValue = moveIndex(
          uci(move),
          game.turn == chess.Color.BLACK,
        );
        return logits[moveIndexValue] > logits[bestIndex] ? move : best;
      });
    }
    final safeTemperature = temperature.clamp(0.001, 1.0);
    final scored = legalMoves.map((move) {
      final uci =
          '${move.fromAlgebraic}${move.toAlgebraic}${move.promotion?.name ?? ''}';
      return (
        move: move,
        logit:
            logits[moveIndex(uci, game.turn == chess.Color.BLACK)] /
            safeTemperature,
      );
    }).toList();
    final maxLogit = scored.map((item) => item.logit).reduce(max);
    final weighted =
        scored
            .map(
              (item) => (move: item.move, weight: exp(item.logit - maxLogit)),
            )
            .toList()
          ..sort((a, b) => b.weight.compareTo(a.weight));
    final fullTotal = weighted.fold<double>(
      0,
      (sum, item) => sum + item.weight,
    );
    final nucleus = <({chess.Move move, double weight})>[];
    var cumulative = 0.0;
    for (var index = 0; index < weighted.length; index++) {
      final item = weighted[index];
      cumulative += item.weight / fullTotal;
      if (index == 0 || safeTopP >= 1.0 || cumulative <= safeTopP) {
        nucleus.add(item);
      } else {
        break;
      }
    }
    final nucleusTotal = nucleus.fold<double>(
      0,
      (sum, item) => sum + item.weight,
    );
    var target = _random.nextDouble() * nucleusTotal;
    for (final item in nucleus) {
      target -= item.weight;
      if (target <= 0) return item.move;
    }
    return nucleus.last.move;
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

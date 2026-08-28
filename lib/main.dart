import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:chess/chess.dart' as chess;
import 'package:chessground/chessground.dart' as cg;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multistockfish/multistockfish.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(
      AppDiagnostics.record(
        'flutter-framework',
        details.exception,
        details.stack ?? StackTrace.current,
      ),
    );
  };
  ui.PlatformDispatcher.instance.onError = (error, stackTrace) {
    unawaited(AppDiagnostics.record('unhandled-async', error, stackTrace));
    return true;
  };
  ErrorWidget.builder = (_) => const DiagnosticsErrorScreen();
  runApp(const MaiaChessApp());
  unawaited(AppDiagnostics.recordEvent('app-started'));
}

const maiaEngineChannel = MethodChannel('maia_chess/engine');
const maiaProjectUrl = 'https://github.com/CSSLab/maia3';
const lichessChessgroundUrl =
    'https://github.com/lichess-org/flutter-chessground';
const lichessMultistockfishUrl =
    'https://github.com/lichess-org/dart-multistockfish';

class MaiaInferenceQueue {
  static Future<void> _tail = Future<void>.value();
  static int _replaceableGeneration = 0;

  static Future<List<dynamic>?> predict(
    Map<String, Object> arguments, {
    bool replaceable = false,
  }) {
    final result = Completer<List<dynamic>?>();
    final generation = replaceable ? ++_replaceableGeneration : null;
    _tail = _tail.catchError((_) {}).then((_) async {
      if (replaceable && generation != _replaceableGeneration) {
        result.complete(null);
        return;
      }
      try {
        result.complete(
          await maiaEngineChannel.invokeMethod<List<dynamic>>(
            'predict',
            arguments,
          ),
        );
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }
}

class AppDiagnostics {
  static const _key = 'diagnosticEntriesV1';
  static const _maximumEntries = 20;
  static const _maximumEntryCharacters = 8000;
  static Future<void> _writeQueue = Future<void>.value();

  static Future<void> recordEvent(String event) async {
    await _append('${DateTime.now().toUtc().toIso8601String()} [$event]');
  }

  static Future<void> record(
    String source,
    Object error,
    StackTrace stackTrace,
  ) async {
    final entry = StringBuffer()
      ..writeln('${DateTime.now().toUtc().toIso8601String()} [$source]')
      ..writeln(error)
      ..write(stackTrace);
    await _append(entry.toString());
  }

  static Future<void> _append(String entry) async {
    _writeQueue = _writeQueue.then((_) => _writeEntry(entry));
    await _writeQueue;
  }

  static Future<void> _writeEntry(String entry) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final entries = preferences.getStringList(_key) ?? <String>[];
      entries.add(
        entry.length <= _maximumEntryCharacters
            ? entry
            : entry.substring(0, _maximumEntryCharacters),
      );
      if (entries.length > _maximumEntries) {
        entries.removeRange(0, entries.length - _maximumEntries);
      }
      await preferences.setStringList(_key, entries);
    } catch (_) {
      // Diagnostics must never trigger another application failure.
    }
  }

  static Future<String> report() async {
    String version = 'unknown';
    String build = 'unknown';
    try {
      final package = await PackageInfo.fromPlatform();
      version = package.version;
      build = package.buildNumber;
    } catch (_) {}
    final preferences = await SharedPreferences.getInstance();
    final entries = preferences.getStringList(_key) ?? const <String>[];
    return [
      'Mobile Maia diagnostics',
      'version=$version build=$build',
      'exported=${DateTime.now().toUtc().toIso8601String()}',
      if (entries.isEmpty) 'No recorded errors.',
      ...entries,
    ].join('\n\n');
  }

  static Future<void> copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: await report()));
  }
}

class DiagnosticsErrorScreen extends StatelessWidget {
  const DiagnosticsErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xff171a18),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.orange, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Mobile Maia encountered a screen error.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Copy the diagnostics and send them with a description of '
                  'what you tapped immediately before this screen appeared.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: AppDiagnostics.copyToClipboard,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy diagnostics'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

bool isPremoveDestination(String fen, String from, String to) {
  final pieces = cg.readFen(fen);
  return cg
      .premovesOf(dc.Square.fromName(from), pieces, canCastle: true)
      .contains(dc.Square.fromName(to));
}

bool shouldRequestMaiaReply({
  required bool premovePlayed,
  required bool gameOver,
}) => premovePlayed && !gameOver;

class MaiaChessApp extends StatelessWidget {
  const MaiaChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile Maia',
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

class RecordedVariation {
  const RecordedVariation({
    required this.basePly,
    required this.baseFen,
    required this.sanMoves,
    this.children = const [],
  });

  final int basePly;
  final String baseFen;
  final List<String> sanMoves;
  final List<RecordedVariation> children;
}

class PgnVariationExporter {
  static String export(
    String pgn,
    List<String> mainSan,
    List<RecordedVariation> variations, {
    List<String>? mainPositions,
  }) {
    final headerEnd = pgn.indexOf('\n\n');
    final headers = headerEnd < 0 ? '' : pgn.substring(0, headerEnd).trim();
    final result =
        RegExp(
          r'^\[Result "([^"]+)"\]$',
          multiLine: true,
        ).firstMatch(headers)?.group(1) ??
        '*';
    final byBase = <int, List<RecordedVariation>>{};
    for (final variation in variations) {
      if (variation.sanMoves.isNotEmpty) {
        byBase.putIfAbsent(variation.basePly, () => []).add(variation);
      }
    }
    final tokens = <String>[];
    void addVariations(int basePly) {
      for (final variation in byBase[basePly] ?? const []) {
        if (mainPositions != null &&
            (basePly >= mainPositions.length ||
                variation.baseFen != mainPositions[basePly])) {
          continue;
        }
        tokens.add('(${_formatLine(variation)})');
      }
    }

    for (var ply = 0; ply < mainSan.length; ply++) {
      if (ply.isEven) tokens.add('${(ply ~/ 2) + 1}.');
      tokens.add(mainSan[ply]);
      // A RAV is an alternative to the immediately preceding move, so a
      // branch starting at `ply` belongs after the main-line move at `ply`.
      addVariations(ply);
    }
    tokens.add(result);
    return '${headers.isEmpty ? '' : '$headers\n\n'}${tokens.join(' ')}';
  }

  static String _formatLine(RecordedVariation variation) {
    final tokens = <String>[];
    for (var offset = 0; offset < variation.sanMoves.length; offset++) {
      final ply = variation.basePly + offset;
      if (ply.isEven) {
        tokens.add('${(ply ~/ 2) + 1}.');
      } else if (offset == 0) {
        tokens.add('${(ply ~/ 2) + 1}...');
      }
      tokens.add(variation.sanMoves[offset]);
      for (final child in variation.children.where(
        (item) => item.basePly == ply,
      )) {
        tokens.add('(${_formatLine(child)})');
      }
    }
    return tokens.join(' ');
  }
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
  final List<RecordedVariation> _takebackVariations = [];
  PlayerSide _sideChoice = PlayerSide.white;
  chess.Color _playerColor = chess.Color.WHITE;
  int _elo = 1500;
  int _analysisElo = 1600;
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
      _analysisElo = preferences.getInt('analysisElo') ?? 1600;
    });
  }

  Future<void> _saveEnginePreferences() async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setBool('humanTiming', _humanTiming),
      preferences.setDouble('temperatureV2', _temperature),
      preferences.setDouble('topPV2', _topP),
      preferences.setInt('analysisElo', _analysisElo),
    ]);
  }

  Future<void> _showAbout() async {
    String version;
    try {
      version = (await PackageInfo.fromPlatform()).version;
    } catch (_) {
      version = 'Unknown version';
    }
    if (!mounted) return;
    showAboutDialog(
      context: context,
      applicationName: 'Mobile Maia',
      applicationVersion: version,
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
      _takebackVariations.clear();
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
        'Mobile Maia Game',
        'Site',
        'Mobile Maia',
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
      final response = await MaiaInferenceQueue.predict({
        'tokens': tokens,
        'selfElo': _elo,
        'opponentElo': _elo,
      });
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
      if (!mounted || generation != _gameGeneration) return;
      setState(() {
        _engineThinking = false;
        _status = _game.game_over
            ? _finishNaturalGame()
            : premovePlayed
            ? 'Game in progress.'
            : 'Your move.';
      });
      if (shouldRequestMaiaReply(
        premovePlayed: premovePlayed,
        gameOver: _game.game_over,
      )) {
        unawaited(_playMaiaMove());
      }
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
    final history = _game
        .getHistory({'verbose': true})
        .cast<Map<String, dynamic>>()
        .map((move) => move['san'] as String)
        .toList(growable: false);
    final basePly = max(0, history.length - plies);
    final removedSan = history.skip(basePly).toList(growable: false);
    if (removedSan.isNotEmpty) {
      final removedPathFens = _positionHistory.skip(basePly).toSet();
      final nested = _takebackVariations
          .where(
            (variation) =>
                variation.basePly > basePly &&
                removedPathFens.contains(variation.baseFen),
          )
          .toList(growable: false);
      _takebackVariations.removeWhere(nested.contains);
      _takebackVariations.add(
        RecordedVariation(
          basePly: basePly,
          baseFen: _positionHistory[basePly],
          sanMoves: removedSan,
          children: nested,
        ),
      );
    }
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
    await Clipboard.setData(ClipboardData(text: _exportPgn()));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('PGN copied')));
    }
  }

  Future<void> _analyzeGame() async {
    if (_positionHistory.length < 2) return;
    final moves = _game
        .getHistory({'verbose': true})
        .cast<Map<String, dynamic>>()
        .map((move) => move['san'] as String)
        .toList(growable: false);
    final plyCount = min(_uciMoves.length, moves.length);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReviewPage(
          positions: List.unmodifiable(_positionHistory.take(plyCount + 1)),
          uciMoves: List.unmodifiable(_uciMoves.take(plyCount)),
          sanMoves: List.unmodifiable(moves.take(plyCount)),
          playerIsWhite: _playerIsWhite,
          pgn: _exportPgn(),
          initialVariations: List.unmodifiable(_takebackVariations),
          maiaElo: _analysisElo,
          onHome: _goHome,
        ),
      ),
    );
  }

  String _exportPgn() {
    final moves = _game
        .getHistory({'verbose': true})
        .cast<Map<String, dynamic>>()
        .map((move) => move['san'] as String)
        .toList(growable: false);
    return PgnVariationExporter.export(
      _game.pgn(),
      moves,
      _takebackVariations,
      mainPositions: _positionHistory,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile Maia'),
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Maia analysis rating: $_analysisElo'),
                  subtitle: Slider(
                    min: 500,
                    max: 2400,
                    divisions: 19,
                    value: _analysisElo.toDouble(),
                    label: '$_analysisElo',
                    onChanged: (value) =>
                        setState(() => _analysisElo = value.round()),
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
                        _analysisElo = 1600;
                      });
                      unawaited(_saveEnginePreferences());
                    },
                    child: const Text('Reset engine defaults'),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      await AppDiagnostics.copyToClipboard();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Diagnostics copied')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy diagnostics'),
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
    this.initialVariations = const [],
    this.maiaElo = 1600,
    required this.onHome,
    this.evaluator,
    this.maiaEvaluator,
    super.key,
  });

  final List<String> positions;
  final List<String> uciMoves;
  final List<String> sanMoves;
  final bool playerIsWhite;
  final String pgn;
  final List<RecordedVariation> initialVariations;
  final int maiaElo;
  final VoidCallback onHome;
  final Future<StockfishReview> Function(String fen)? evaluator;
  final Future<String?> Function(List<String> positions, int elo)?
  maiaEvaluator;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  int _ply = 0;
  bool _showGraph = false;
  final Map<int, StockfishReview> _reviews = {};
  final Set<int> _loading = {};
  final Map<int, Future<void>> _pendingAnalyses = {};
  String? _analysisError;
  bool _flipped = false;
  bool _fullAnalysisRunning = false;
  int _fullAnalysisProgress = 0;
  List<StockfishReview>? _graphScores;
  final Map<int, String> _maiaMoves = {};
  final Set<int> _maiaLoading = {};
  late final cg.ChessboardController _boardController;
  late dc.Chess _boardPosition;
  late final List<RecordedVariation> _variations;
  RecordedVariation? _openedVariation;
  int? _variationBasePly;
  int _variationIndex = 0;
  final List<String> _variationSan = [];
  final List<String> _variationPositions = [];
  StockfishReview? _variationReview;
  String? _variationMaiaMove;
  bool _variationLoading = false;
  bool _variationMaiaLoading = false;
  String? _variationError;

  bool get _inVariation => _variationBasePly != null;
  String get _currentFen => _inVariation
      ? _variationPositions[_variationIndex]
      : widget.positions[_ply];
  StockfishReview? get _review =>
      _inVariation ? _variationReview : _reviews[_ply];
  int get _maximumPly => max(
    0,
    min(
      widget.positions.length - 1,
      min(widget.uciMoves.length, widget.sanMoves.length),
    ),
  );

  @override
  void initState() {
    super.initState();
    _variations = List.of(widget.initialVariations);
    _boardPosition = dc.Chess.fromSetup(dc.Setup.parseFen(widget.positions[0]));
    _boardController = cg.ChessboardController(game: _boardGameData());
    unawaited(_analyzePosition(0));
    unawaited(_analyzeMaiaPosition(0));
  }

  @override
  void dispose() {
    _boardController.dispose();
    super.dispose();
  }

  cg.GameData _boardGameData() => cg.GameData(
    fen: _boardPosition.fen,
    playerSide:
        _boardPosition.isGameOver ||
            (_inVariation && _variationIndex < _variationSan.length)
        ? cg.PlayerSide.none
        : cg.PlayerSide.both,
    sideToMove: _boardPosition.turn,
    validMoves: dc.makeLegalMoves(_boardPosition),
    kingSquareInCheck: _boardPosition.isCheck
        ? _boardPosition.board.kingOf(_boardPosition.turn)
        : null,
  );

  void _showMainPly(int ply) {
    _variationBasePly = null;
    _openedVariation = null;
    _variationIndex = 0;
    _variationSan.clear();
    _variationPositions.clear();
    _variationReview = null;
    _variationMaiaMove = null;
    _ply = ply.clamp(0, _maximumPly);
    _boardPosition = dc.Chess.fromSetup(
      dc.Setup.parseFen(widget.positions[_ply]),
    );
    _boardController.updatePosition(
      _boardGameData(),
      animate: false,
      resetPremove: true,
    );
    unawaited(_analyzePosition(_ply));
    unawaited(_analyzeMaiaPosition(_ply));
  }

  void _onAnalysisMove(dc.Move move, {bool? viaDragAndDrop}) {
    if (!_boardPosition.isLegal(move)) return;
    final fenBefore = _boardPosition.fen;
    final uci = move.uci;
    final sanGame = chess.Chess.fromFEN(fenBefore);
    final candidate = sanGame
        .moves({'asObjects': true})
        .cast<chess.Move>()
        .where((item) => MaiaEncoding.uci(item) == uci)
        .firstOrNull;
    if (candidate == null) return;
    sanGame.move(candidate);
    final san =
        sanGame
                .getHistory({'verbose': true})
                .cast<Map<String, dynamic>>()
                .last['san']
            as String;
    final opened = _openedVariation;
    final branchingInsideVariation =
        opened != null && _variationIndex < _variationSan.length;
    final basePly = branchingInsideVariation
        ? opened.basePly + _variationIndex
        : _variationBasePly ?? _ply;
    _boardPosition = _boardPosition.playUnchecked(move) as dc.Chess;
    if (branchingInsideVariation) {
      final child = RecordedVariation(
        basePly: basePly,
        baseFen: fenBefore,
        sanMoves: [san],
      );
      final siblings = List<RecordedVariation>.of(opened.children)
        ..removeWhere(
          (item) =>
              item.basePly == basePly &&
              item.sanMoves.isNotEmpty &&
              item.sanMoves.first == san,
        )
        ..add(child);
      final updatedParent = RecordedVariation(
        basePly: opened.basePly,
        baseFen: opened.baseFen,
        sanMoves: opened.sanMoves,
        children: siblings,
      );
      _replaceVariation(_variations, opened, updatedParent);
      _openedVariation = child;
      _variationBasePly = basePly;
      _variationSan
        ..clear()
        ..add(san);
      _variationPositions
        ..clear()
        ..add(fenBefore)
        ..add(_boardPosition.fen);
      _variationIndex = 1;
      _boardController.updatePosition(_boardGameData());
      setState(() {
        _variationReview = null;
        _variationMaiaMove = null;
      });
      unawaited(_analyzeVariation());
      return;
    }
    if (_variationBasePly == null) {
      _variationBasePly = basePly;
      _variationSan.clear();
      _variationPositions
        ..clear()
        ..add(fenBefore);
    }
    _variationSan.add(san);
    _variationPositions.add(_boardPosition.fen);
    _variationIndex = _variationSan.length;
    final updated = RecordedVariation(
      basePly: basePly,
      baseFen: _variationPositions.first,
      sanMoves: List.unmodifiable(_variationSan),
      children: _openedVariation?.children ?? const [],
    );
    if (opened != null) {
      _replaceVariation(_variations, opened, updated);
      _openedVariation = updated;
    } else {
      _variations.removeWhere(
        (item) =>
            item.basePly == basePly &&
            item.sanMoves.isNotEmpty &&
            item.sanMoves.first == _variationSan.first,
      );
      _variations.add(updated);
    }
    _boardController.updatePosition(_boardGameData());
    setState(() {
      _variationReview = null;
      _variationMaiaMove = null;
    });
    unawaited(_analyzeVariation());
  }

  Future<void> _analyzeMaiaPosition(int ply) async {
    // Widget tests commonly inject only Stockfish. Do not invoke the native
    // Maia channel in that case unless a Maia test double was also supplied.
    if (widget.evaluator != null && widget.maiaEvaluator == null) return;
    if (_maiaMoves.containsKey(ply) || _maiaLoading.contains(ply)) return;
    setState(() => _maiaLoading.add(ply));
    try {
      final positions = widget.positions.take(ply + 1).toList(growable: false);
      final injected = widget.maiaEvaluator;
      if (injected != null) {
        final move = await injected(positions, widget.maiaElo);
        if (move != null && mounted) setState(() => _maiaMoves[ply] = move);
        return;
      }
      final response = await MaiaInferenceQueue.predict({
        'tokens': MaiaEncoding.historicalTokens(positions),
        'selfElo': widget.maiaElo,
        'opponentElo': widget.maiaElo,
      }, replaceable: true);
      if (response == null || response.length != 4352) return;
      final game = chess.Chess.fromFEN(widget.positions[ply]);
      if (game.game_over) return;
      final move = MaiaEncoding.sampleLegalMove(
        game,
        game.moves({'asObjects': true}).cast<chess.Move>().toList(),
        response.cast<num>().map((value) => value.toDouble()).toList(),
        temperature: 0,
      );
      if (mounted) setState(() => _maiaMoves[ply] = MaiaEncoding.uci(move));
    } catch (error, stackTrace) {
      unawaited(AppDiagnostics.record('maia-analysis', error, stackTrace));
    } finally {
      if (mounted) setState(() => _maiaLoading.remove(ply));
    }
  }

  Future<void> _analyzeVariation() async {
    final fen = _currentFen;
    setState(() {
      _variationLoading = true;
      _variationError = null;
    });
    try {
      final evaluate = widget.evaluator ?? StockfishAnalyzer.instance.evaluate;
      final review = await evaluate(fen);
      if (!mounted || fen != _currentFen) return;
      setState(() => _variationReview = review);
    } catch (error, stackTrace) {
      if (mounted && fen == _currentFen) {
        setState(() => _variationError = 'Stockfish failed: $error');
      }
      unawaited(
        AppDiagnostics.record('stockfish-variation', error, stackTrace),
      );
    } finally {
      if (mounted && fen == _currentFen) {
        setState(() => _variationLoading = false);
      }
    }
    if (mounted && fen == _currentFen) {
      setState(() => _variationMaiaLoading = true);
    }
    try {
      final injected = widget.maiaEvaluator;
      if (injected != null) {
        final move = await injected([
          ...widget.positions.take((_variationBasePly ?? 0) + 1),
          ..._variationPositions.skip(1).take(_variationIndex),
        ], widget.maiaElo);
        if (move != null && mounted && fen == _currentFen) {
          setState(() => _variationMaiaMove = move);
        }
        return;
      }
      if (widget.evaluator != null) return;
      final response = await MaiaInferenceQueue.predict({
        'tokens': MaiaEncoding.historicalTokens([
          ...widget.positions.take((_variationBasePly ?? 0) + 1),
          ..._variationPositions.skip(1).take(_variationIndex),
        ]),
        'selfElo': widget.maiaElo,
        'opponentElo': widget.maiaElo,
      }, replaceable: true);
      if (response == null || response.length != 4352 || fen != _currentFen) {
        return;
      }
      final game = chess.Chess.fromFEN(fen);
      if (game.game_over) return;
      final move = MaiaEncoding.sampleLegalMove(
        game,
        game.moves({'asObjects': true}).cast<chess.Move>().toList(),
        response.cast<num>().map((value) => value.toDouble()).toList(),
        temperature: 0,
      );
      if (mounted && fen == _currentFen) {
        setState(() => _variationMaiaMove = MaiaEncoding.uci(move));
      }
    } catch (error, stackTrace) {
      unawaited(AppDiagnostics.record('maia-variation', error, stackTrace));
    } finally {
      if (mounted && fen == _currentFen) {
        setState(() => _variationMaiaLoading = false);
      }
    }
  }

  bool _replaceVariation(
    List<RecordedVariation> variations,
    RecordedVariation target,
    RecordedVariation replacement,
  ) {
    for (var index = 0; index < variations.length; index++) {
      final current = variations[index];
      if (identical(current, target)) {
        variations[index] = replacement;
        return true;
      }
      final children = List<RecordedVariation>.of(current.children);
      if (_replaceVariation(children, target, replacement)) {
        variations[index] = RecordedVariation(
          basePly: current.basePly,
          baseFen: current.baseFen,
          sanMoves: current.sanMoves,
          children: children,
        );
        return true;
      }
    }
    return false;
  }

  void _openVariation(RecordedVariation variation, [int? selectedIndex]) {
    final sanGame = chess.Chess.fromFEN(variation.baseFen);
    var position = dc.Chess.fromSetup(dc.Setup.parseFen(variation.baseFen));
    final positions = <String>[variation.baseFen];
    for (final san in variation.sanMoves) {
      final sanOptions = sanGame.moves().cast<String>().toList();
      final moveOptions = sanGame
          .moves({'asObjects': true})
          .cast<chess.Move>()
          .toList();
      final index = sanOptions.indexOf(san);
      if (index < 0) return;
      final uci = MaiaEncoding.uci(moveOptions[index]);
      final move = dc.NormalMove.fromUci(uci);
      if (!position.isLegal(move) || !sanGame.move(moveOptions[index])) return;
      position = position.playUnchecked(move) as dc.Chess;
      positions.add(position.fen);
    }
    setState(() {
      _openedVariation = variation;
      _variationBasePly = variation.basePly;
      _variationIndex = (selectedIndex ?? variation.sanMoves.length).clamp(
        0,
        variation.sanMoves.length,
      );
      _variationSan
        ..clear()
        ..addAll(variation.sanMoves);
      _variationPositions
        ..clear()
        ..addAll(positions);
      _boardPosition = dc.Chess.fromSetup(
        dc.Setup.parseFen(positions[_variationIndex]),
      );
      _variationReview = null;
      _variationMaiaMove = null;
      _boardController.updatePosition(
        _boardGameData(),
        animate: false,
        resetPremove: true,
      );
    });
    unawaited(_analyzeVariation());
  }

  Future<void> _analyzePosition(int ply) async {
    if (_reviews.containsKey(ply)) return;
    final pending = _pendingAnalyses[ply];
    if (pending != null) return pending;
    late Future<void> operation;
    operation = _runAnalysis(ply).whenComplete(() {
      if (identical(_pendingAnalyses[ply], operation)) {
        _pendingAnalyses.remove(ply);
      }
    });
    _pendingAnalyses[ply] = operation;
    return operation;
  }

  Future<void> _runAnalysis(int ply) async {
    setState(() {
      _loading.add(ply);
      _analysisError = null;
    });
    try {
      final evaluate = widget.evaluator ?? StockfishAnalyzer.instance.evaluate;
      final review = await evaluate(widget.positions[ply]);
      if (mounted) setState(() => _reviews[ply] = review);
    } catch (error, stackTrace) {
      unawaited(AppDiagnostics.record('stockfish-analysis', error, stackTrace));
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
    for (var i = 0; i <= _maximumPly && mounted; i++) {
      await _analyzePosition(i);
      if (mounted) setState(() => _fullAnalysisProgress = i + 1);
    }
    if (!mounted) return;
    setState(() {
      _graphScores = List.generate(
        _maximumPly + 1,
        (index) => _reviews[index] ?? const StockfishReview(0, ''),
      );
      _fullAnalysisRunning = false;
    });
  }

  Set<cg.Shape> get _arrows {
    final move = _review?.bestMove ?? '';
    final maiaMove = _inVariation
        ? _variationMaiaMove ?? ''
        : _maiaMoves[_ply] ?? '';
    final valid = RegExp(r'^[a-h][1-8][a-h][1-8][qrbn]?$');
    final arrows = <cg.Shape>{};
    if (valid.hasMatch(move)) {
      arrows.add(_arrow(move, const Color(0xff3d9be9)));
    }
    if (valid.hasMatch(maiaMove) && maiaMove != move) {
      arrows.add(_arrow(maiaMove, const Color(0xffe89b3c)));
    }
    return arrows;
  }

  cg.Arrow _arrow(String uci, Color color) => cg.Arrow(
    color: color,
    orig: dc.Square.fromName(uci.substring(0, 2)),
    dest: dc.Square.fromName(uci.substring(2, 4)),
  );

  Widget _notationMove({
    required String san,
    required bool selected,
    required VoidCallback onTap,
    Key? key,
    bool variation = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      key: key,
      color: selected ? colors.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(3),
      child: InkWell(
        borderRadius: BorderRadius.circular(3),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: variation ? 3 : 6,
            vertical: variation ? 3 : 7,
          ),
          child: Text(
            san,
            style: TextStyle(
              fontSize: variation ? 14 : 16,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? colors.onPrimaryContainer : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _variationLine(RecordedVariation variation, [int depth = 0]) {
    final children = variation.children;
    return Container(
      margin: EdgeInsets.only(top: 3, left: depth * 14.0),
      padding: const EdgeInsets.fromLTRB(8, 3, 6, 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          left: BorderSide(
            width: 3,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 1,
            runSpacing: 1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (
                var index = 0;
                index < variation.sanMoves.length;
                index++
              ) ...[
                if ((variation.basePly + index).isEven)
                  Padding(
                    padding: const EdgeInsets.only(right: 1),
                    child: Text(
                      '${((variation.basePly + index) ~/ 2) + 1}.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else if (index == 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 1),
                    child: Text(
                      '${((variation.basePly + index) ~/ 2) + 1}...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                _notationMove(
                  key: ValueKey('variation-${variation.hashCode}-$index'),
                  san: variation.sanMoves[index],
                  variation: true,
                  selected:
                      identical(_openedVariation, variation) &&
                      _variationIndex == index + 1,
                  onTap: () => _openVariation(variation, index + 1),
                ),
              ],
            ],
          ),
          for (final child in children) _variationLine(child, depth + 1),
        ],
      ),
    );
  }

  Widget _movesNotation() {
    final variationsByBase = <int, List<RecordedVariation>>{};
    for (final variation in _variations) {
      variationsByBase.putIfAbsent(variation.basePly, () => []).add(variation);
    }
    final renderedVariations = <RecordedVariation>{};
    final rows = <Widget>[];
    for (var whiteIndex = 0; whiteIndex < _maximumPly; whiteIndex += 2) {
      final blackIndex = whiteIndex + 1;
      rows.add(
        Container(
          color: (whiteIndex ~/ 2).isOdd
              ? Theme.of(context).colorScheme.surfaceContainerLow
              : Colors.transparent,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 38,
                child: Text(
                  '${(whiteIndex ~/ 2) + 1}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _notationMove(
                    key: ValueKey('main-move-$whiteIndex'),
                    san: widget.sanMoves[whiteIndex],
                    selected: !_inVariation && _ply == whiteIndex + 1,
                    onTap: () => setState(() => _showMainPly(whiteIndex + 1)),
                  ),
                ),
              ),
              Expanded(
                child: blackIndex < _maximumPly
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: _notationMove(
                          key: ValueKey('main-move-$blackIndex'),
                          san: widget.sanMoves[blackIndex],
                          selected: !_inVariation && _ply == blackIndex + 1,
                          onTap: () =>
                              setState(() => _showMainPly(blackIndex + 1)),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
      for (final basePly in [whiteIndex, blackIndex]) {
        for (final variation in variationsByBase[basePly] ?? const []) {
          rows.add(_variationLine(variation));
          renderedVariations.add(variation);
        }
      }
    }
    // A review may begin from a terminal or deliberately truncated main line.
    // Keep analysis branches visible even when there is no corresponding row.
    for (final variation in _variations) {
      if (renderedVariations.add(variation)) {
        rows.add(_variationLine(variation));
      }
    }
    return Container(
      key: const ValueKey('analysis-move-list'),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }

  void _step(int delta) {
    if (_inVariation) {
      final next = (_variationIndex + delta).clamp(0, _variationSan.length);
      setState(() {
        _variationIndex = next;
        _boardPosition = dc.Chess.fromSetup(
          dc.Setup.parseFen(_variationPositions[next]),
        );
        _variationReview = null;
        _variationMaiaMove = null;
        _boardController.updatePosition(
          _boardGameData(),
          animate: false,
          resetPremove: true,
        );
      });
      unawaited(_analyzeVariation());
      return;
    }
    setState(() => _showMainPly(_ply + delta));
  }

  Future<void> _copyPgn() async {
    await Clipboard.setData(
      ClipboardData(
        text: PgnVariationExporter.export(
          widget.pgn,
          widget.sanMoves,
          _variations,
          mainPositions: widget.positions,
        ),
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('PGN copied')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final evaluation = _review?.evaluation;
    final mate = _review?.mate;
    final moveLabel = _inVariation
        ? 'Variation: ${_variationSan.take(_variationIndex).join(' ')}'
        : _ply == 0
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
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: LayoutBuilder(
                    builder: (context, contentConstraints) {
                      // The board row also contains the 24px evaluation bar and
                      // an 8px gap. Compute from the actual padded content width,
                      // not the outer viewport width.
                      final boardSize = max(
                        0.0,
                        min(contentConstraints.maxWidth - 32, 560.0),
                      );
                      return Column(
                        children: [
                          SizedBox(
                            height: boardSize,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                EvaluationBar(
                                  evaluation: evaluation,
                                  mate: mate,
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: boardSize,
                                  height: boardSize,
                                  child: cg.Chessboard(
                                    controller: _boardController,
                                    size: boardSize,
                                    orientation: _flipped
                                        ? (widget.playerIsWhite
                                              ? dc.Side.black
                                              : dc.Side.white)
                                        : (widget.playerIsWhite
                                              ? dc.Side.white
                                              : dc.Side.black),
                                    onMove: _onAnalysisMove,
                                    shapes: _arrows,
                                    settings: const cg.ChessboardSettings(
                                      colorScheme:
                                          cg.ChessboardColorScheme.brown,
                                      pieceAssets: cg.PieceSet.cburnettAssets,
                                      enableCoordinates: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          MaterialDifference(fen: _currentFen),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed:
                                    (_inVariation
                                        ? _variationIndex == 0
                                        : _ply == 0)
                                    ? null
                                    : () => _step(-1),
                                icon: const Icon(Icons.chevron_left),
                              ),
                              Flexible(
                                child: Text(
                                  '$moveLabel  ·  ${_inVariation ? '$_variationIndex/${_variationSan.length}' : '$_ply/$_maximumPly'}',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              IconButton(
                                onPressed:
                                    (_inVariation
                                        ? _variationIndex ==
                                              _variationSan.length
                                        : _ply == _maximumPly)
                                    ? null
                                    : () => _step(1),
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                value: false,
                                icon: Icon(Icons.list_alt),
                                label: Text('Moves'),
                              ),
                              ButtonSegment(
                                value: true,
                                icon: Icon(Icons.show_chart),
                                label: Text('Graph'),
                              ),
                            ],
                            selected: {_showGraph},
                            onSelectionChanged: (selection) =>
                                setState(() => _showGraph = selection.first),
                          ),
                          const SizedBox(height: 8),
                          if (!_showGraph)
                            _movesNotation()
                          else if (_graphScores != null) ...[
                            AccuracySummary(scores: _graphScores!),
                            const SizedBox(height: 8),
                            AnalysisGraph(
                              scores: _graphScores!,
                              selectedPly: _ply,
                              onSelected: (ply) {
                                setState(() => _showMainPly(ply));
                              },
                            ),
                          ] else
                            const Card(
                              child: ListTile(
                                leading: Icon(Icons.info_outline),
                                title: Text('No full-game analysis yet'),
                                subtitle: Text(
                                  'Run computer analysis below to create the graph.',
                                ),
                              ),
                            ),
                          Card(
                            child: Column(
                              children: [
                                ListTile(
                                  leading:
                                      (_inVariation
                                          ? _variationLoading
                                          : _loading.contains(_ply))
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
                                    (_inVariation
                                            ? _variationError
                                            : _analysisError) ??
                                        (_review == null
                                            ? 'Analyzing this position…'
                                            : 'Depth 12 · ${_formatEvaluation(_review!)}'),
                                  ),
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  leading:
                                      (_inVariation
                                          ? _variationMaiaLoading
                                          : _maiaLoading.contains(_ply))
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.arrow_upward,
                                          color: Color(0xffe89b3c),
                                        ),
                                  title: Text(
                                    'Maia ${widget.maiaElo} human move',
                                  ),
                                  subtitle: Text(
                                    (_inVariation
                                                ? _variationMaiaMove
                                                : _maiaMoves[_ply]) ==
                                            null
                                        ? 'Analyzing this position…'
                                        : (_inVariation
                                                  ? _variationMaiaMove
                                                  : _maiaMoves[_ply]) ==
                                              _review?.bestMove
                                        ? 'Matches Stockfish'
                                        : 'Most likely human move',
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
                                        ? '$_fullAnalysisProgress/${_maximumPly + 1} positions'
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
                      );
                    },
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

class GameAccuracy {
  const GameAccuracy({required this.white, required this.black});

  final double? white;
  final double? black;

  static GameAccuracy fromScores(List<StockfishReview> scores) {
    if (scores.length < 2) {
      return const GameAccuracy(white: null, black: null);
    }
    final winPercents = scores.map((score) => score.whiteWinPercent).toList();
    final windowSize = (scores.length ~/ 10).clamp(2, 8);
    final windows = <List<double>>[
      ...List.generate(
        min(windowSize, winPercents.length) - 2,
        (_) => winPercents.take(windowSize).toList(),
      ),
      for (var start = 0; start + windowSize <= winPercents.length; start++)
        winPercents.sublist(start, start + windowSize),
    ];
    final whiteMoves = <(double, double)>[];
    final blackMoves = <(double, double)>[];
    for (var ply = 0; ply + 1 < scores.length; ply++) {
      final whiteMoved = ply.isEven;
      final beforeWhite = winPercents[ply];
      final afterWhite = winPercents[ply + 1];
      final before = whiteMoved ? beforeWhite : 100 - beforeWhite;
      final after = whiteMoved ? afterWhite : 100 - afterWhite;
      final accuracy = moveAccuracy(before, after);
      final weight = _standardDeviation(windows[ply]).clamp(0.5, 12.0);
      (whiteMoved ? whiteMoves : blackMoves).add((accuracy, weight));
    }
    return GameAccuracy(
      white: _gameMean(whiteMoves),
      black: _gameMean(blackMoves),
    );
  }

  static double moveAccuracy(double before, double after) {
    if (after >= before) return 100;
    final loss = before - after;
    return (103.1668100711649 * exp(-0.04354415386753951 * loss) -
            3.166924740191411 +
            1)
        .clamp(0, 100)
        .toDouble();
  }

  static double _standardDeviation(List<double> values) {
    final mean = values.reduce((total, value) => total + value) / values.length;
    final variance =
        values
            .map((value) => pow(value - mean, 2))
            .reduce((total, value) => total + value) /
        values.length;
    return sqrt(variance);
  }

  static double? _gameMean(List<(double, double)> moves) {
    if (moves.isEmpty) return null;
    final totalWeight = moves.fold<double>(0, (total, move) => total + move.$2);
    final weighted =
        moves.fold<double>(0, (total, move) => total + move.$1 * move.$2) /
        totalWeight;
    final harmonic = moves.any((move) => move.$1 == 0)
        ? 0.0
        : moves.length /
              moves.fold<double>(0, (total, move) => total + 1 / move.$1);
    return (weighted + harmonic) / 2;
  }
}

class AccuracySummary extends StatelessWidget {
  const AccuracySummary({required this.scores, super.key});

  final List<StockfishReview> scores;

  @override
  Widget build(BuildContext context) {
    final accuracy = GameAccuracy.fromScores(scores);
    String label(double? value) =>
        value == null ? '—' : '${value.clamp(0, 100).toStringAsFixed(1)}%';
    return Semantics(
      label: 'Game accuracy',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.gps_fixed),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Accuracy',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        Text('White ${label(accuracy.white)}'),
                        Text('Black ${label(accuracy.black)}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final whiteHeight = constraints.maxHeight * whiteShare;
          return Stack(
            children: [
              const Positioned.fill(
                child: ColoredBox(color: Color(0xff262421)),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: whiteHeight,
                child: const ColoredBox(color: Color(0xfff0f0f0)),
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
                          color: (mate ?? score!) < 0
                              ? Colors.white
                              : Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
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
    final startup = _startup ??= _engine.start().then((_) async {
      _engine.stdin = 'setoption name Threads value 2';
      _engine.stdin = 'setoption name Hash value 64';
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

  double get whiteWinPercent => 50 + 50 * whiteWinningChances;
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

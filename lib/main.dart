import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
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
  try {
    await OpeningNames.load();
  } catch (error, stackTrace) {
    // Opening labels are useful but not required for playing or analysis.
    // A damaged optional asset must not prevent the entire app from starting.
    await AppDiagnostics.record('opening-names-load', error, stackTrace);
  }
  runApp(const MaiaChessApp());
  unawaited(AppDiagnostics.recordEvent('app-started'));
}

const maiaEngineChannel = MethodChannel('maia_chess/engine');
const maiaProjectUrl = 'https://github.com/CSSLab/maia3';
const lichessChessgroundUrl =
    'https://github.com/lichess-org/flutter-chessground';
const lichessMultistockfishUrl =
    'https://github.com/lichess-org/dart-multistockfish';
const mobileMaiaSourceUrl =
    'https://github.com/Dash1971/maia-chess-android-preview';
const mobileMaiaLicenseUrl = '$mobileMaiaSourceUrl/blob/main/LICENSE';

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
      title: 'Mobile Maia Preview',
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

  Map<String, Object> toJson() => {
    'basePly': basePly,
    'baseFen': baseFen,
    'sanMoves': sanMoves,
    'children': children.map((item) => item.toJson()).toList(),
  };

  factory RecordedVariation.fromJson(Map<String, dynamic> json) =>
      RecordedVariation(
        basePly: json['basePly'] as int,
        baseFen: json['baseFen'] as String,
        sanMoves: (json['sanMoves'] as List).cast<String>(),
        children: (json['children'] as List? ?? const [])
            .map(
              (item) => RecordedVariation.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(growable: false),
      );
}

class ActiveSessionStore {
  static const _key = 'activeSessionV1';

  static Future<Map<String, dynamic>?> load() async {
    final source = (await SharedPreferences.getInstance()).getString(_key);
    if (source == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(source) as Map);
    } catch (error, stackTrace) {
      await AppDiagnostics.record('active-session-load', error, stackTrace);
      // Do not retry a permanently malformed session on every app launch.
      await clear();
      return null;
    }
  }

  static Future<void> save(Map<String, Object?> value) async {
    await (await SharedPreferences.getInstance()).setString(
      _key,
      jsonEncode({'schema': 1, ...value}),
    );
  }

  static Future<void> clear() async {
    await (await SharedPreferences.getInstance()).remove(_key);
  }
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
    if (mainSan.isEmpty) {
      final rootLines = byBase[0] ?? const <RecordedVariation>[];
      if (rootLines.isNotEmpty) {
        tokens.add(_formatLine(rootLines.first));
        for (final alternative in rootLines.skip(1)) {
          tokens.add('(${_formatLine(alternative)})');
        }
      }
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

class AnalysisSession {
  const AnalysisSession({
    required this.positions,
    required this.uciMoves,
    required this.sanMoves,
    required this.pgn,
  });

  final List<String> positions;
  final List<String> uciMoves;
  final List<String> sanMoves;
  final String pgn;

  Map<String, Object> toJson() => {
    'positions': positions,
    'uciMoves': uciMoves,
    'sanMoves': sanMoves,
    'pgn': pgn,
  };

  factory AnalysisSession.fromJson(Map<String, dynamic> json) =>
      AnalysisSession(
        positions: (json['positions'] as List).cast<String>(),
        uciMoves: (json['uciMoves'] as List).cast<String>(),
        sanMoves: (json['sanMoves'] as List).cast<String>(),
        pgn: json['pgn'] as String,
      );

  factory AnalysisSession.fromFen(String fen) {
    final validation = chess.Chess.validate_fen(fen.trim());
    if (validation['valid'] != true) {
      throw FormatException(validation['error']?.toString() ?? 'Invalid FEN');
    }
    final game = chess.Chess.fromFEN(fen.trim());
    game.set_header([
      'Event',
      'Mobile Maia Analysis',
      'SetUp',
      '1',
      'FEN',
      fen.trim(),
      'Result',
      '*',
    ]);
    return AnalysisSession(
      positions: [game.fen],
      uciMoves: const [],
      sanMoves: const [],
      pgn: game.pgn(),
    );
  }

  factory AnalysisSession.start() =>
      AnalysisSession.fromFen(chess.Chess.DEFAULT_POSITION);

  factory AnalysisSession.fromPgn(String source) {
    final loaded = chess.Chess();
    if (!loaded.load_pgn(source.trim())) {
      throw const FormatException('The PGN could not be parsed.');
    }
    final verbose = loaded.getHistory({
      'verbose': true,
    }).cast<Map<String, dynamic>>();
    final baseFen =
        loaded.header['FEN']?.toString() ?? chess.Chess.DEFAULT_POSITION;
    final replay = chess.Chess.fromFEN(baseFen);
    final positions = <String>[replay.fen];
    final uciMoves = <String>[];
    final sanMoves = <String>[];
    for (final item in verbose) {
      final from = item['from']?.toString();
      final to = item['to']?.toString();
      if (from == null || to == null) {
        throw const FormatException('PGN move is incomplete.');
      }
      final String? promotion = item.containsKey('promotion')
          ? item['promotion'].toString()
          : null;
      final moveData = <String, String>{'from': from, 'to': to};
      if (promotion case final value?) moveData['promotion'] = value;
      final moved = replay.move(moveData);
      if (!moved) {
        throw const FormatException('PGN contains an illegal move.');
      }
      uciMoves.add('$from$to${promotion ?? ''}');
      sanMoves.add(item['san'].toString());
      positions.add(replay.fen);
    }
    return AnalysisSession(
      positions: List.unmodifiable(positions),
      uciMoves: List.unmodifiable(uciMoves),
      sanMoves: List.unmodifiable(sanMoves),
      pgn: loaded.pgn(),
    );
  }
}

class OpeningNames {
  static final Map<String, ({String eco, String name})> _byEpd = {};

  static Future<void> load() async {
    if (_byEpd.isNotEmpty) return;
    final source = await rootBundle.loadString(
      'assets/openings/lichess_openings.tsv',
    );
    for (final line in const LineSplitter().convert(source).skip(1)) {
      final columns = line.split('\t');
      if (columns.length != 5) continue;
      _byEpd[columns[4]] = (eco: columns[0], name: columns[1]);
    }
  }

  static String? identifyPositions(Iterable<String> positions) {
    for (final fen in positions.toList(growable: false).reversed) {
      final fields = fen.split(RegExp(r'\s+'));
      if (fields.length < 4) continue;
      final opening = _byEpd[fields.take(4).join(' ')];
      if (opening != null) return '${opening.eco} · ${opening.name}';
    }
    return null;
  }

  static String? identify(List<String> moves) {
    final game = chess.Chess();
    final positions = <String>[game.fen];
    for (final uci in moves) {
      final candidate = game
          .moves({'asObjects': true})
          .cast<chess.Move>()
          .where((move) => MaiaEncoding.uci(move) == uci)
          .firstOrNull;
      if (candidate == null || !game.move(candidate)) break;
      positions.add(game.fen);
    }
    return identifyPositions(positions);
  }
}

class GamePage extends StatefulWidget {
  const GamePage({
    this.startingFen,
    this.startingSide,
    this.startingElo,
    super.key,
  });

  final String? startingFen;
  final PlayerSide? startingSide;
  final int? startingElo;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with WidgetsBindingObserver {
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
  bool _reviewOpen = false;
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
    WidgetsBinding.instance.addObserver(this);
    if (widget.startingSide != null) _sideChoice = widget.startingSide!;
    if (widget.startingElo != null) _elo = widget.startingElo!;
    unawaited(_loadEnginePreferences());
    if (widget.startingFen != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startGame());
    } else {
      unawaited(_restoreActiveSession());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      if (!_reviewOpen) unawaited(_saveGameState());
    }
  }

  Future<void> _restoreActiveSession() async {
    final saved = await ActiveSessionStore.load();
    if (!mounted || saved == null) return;
    if (saved['type'] == 'analysis') {
      try {
        final session = AnalysisSession.fromJson(
          Map<String, dynamic>.from(saved['session'] as Map),
        );
        final variations = (saved['variations'] as List? ?? const [])
            .map(
              (item) => RecordedVariation.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(growable: false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AnalysisBoardPage(
                initialSession: session,
                maiaElo: saved['maiaElo'] as int? ?? _analysisElo,
                initialVariations: variations,
                initialCurrentFen: saved['currentFen'] as String?,
                initialFlipped: saved['flipped'] as bool? ?? false,
              ),
            ),
          );
        });
      } catch (error, stackTrace) {
        await AppDiagnostics.record(
          'analysis-session-restore',
          error,
          stackTrace,
        );
        await ActiveSessionStore.clear();
      }
      return;
    }
    if (saved['type'] == 'review') {
      try {
        final session = AnalysisSession.fromJson(
          Map<String, dynamic>.from(saved['session'] as Map),
        );
        final variations = (saved['variations'] as List? ?? const [])
            .map(
              (item) => RecordedVariation.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(growable: false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _reviewOpen = true;
          Navigator.of(context)
              .push(
                MaterialPageRoute<void>(
                  builder: (_) => ReviewPage(
                    positions: session.positions,
                    uciMoves: session.uciMoves,
                    sanMoves: session.sanMoves,
                    playerIsWhite: saved['playerIsWhite'] as bool? ?? true,
                    pgn: session.pgn,
                    initialVariations: variations,
                    maiaElo: saved['maiaElo'] as int? ?? _analysisElo,
                    initialCurrentFen: saved['currentFen'] as String?,
                    initialFlipped: saved['flipped'] as bool? ?? false,
                    onSessionChanged: (fen, flipped, updated) =>
                        _saveReviewState(
                          session,
                          saved['playerIsWhite'] as bool? ?? true,
                          fen,
                          flipped,
                          updated,
                        ),
                    onHome: () => unawaited(ActiveSessionStore.clear()),
                  ),
                ),
              )
              .whenComplete(() => _reviewOpen = false);
        });
      } catch (error, stackTrace) {
        await AppDiagnostics.record(
          'review-session-restore',
          error,
          stackTrace,
        );
        await ActiveSessionStore.clear();
      }
      return;
    }
    if (saved['type'] != 'game') return;
    try {
      final restored = chess.Chess();
      if (!restored.load_pgn(saved['pgn'] as String)) {
        throw const FormatException('Saved game PGN is invalid.');
      }
      final savedAt = DateTime.tryParse(saved['savedAt'] as String? ?? '');
      var whiteMillis = saved['whiteMillis'] as int? ?? 0;
      var blackMillis = saved['blackMillis'] as int? ?? 0;
      final preset = TimePreset.values.byName(
        saved['timePreset'] as String? ?? TimePreset.unlimited.name,
      );
      if (savedAt != null &&
          preset != TimePreset.unlimited &&
          saved['forcedResult'] == null &&
          !restored.game_over) {
        final elapsed = DateTime.now().difference(savedAt).inMilliseconds;
        if (restored.turn == chess.Color.WHITE) {
          whiteMillis = max(0, whiteMillis - elapsed);
        } else {
          blackMillis = max(0, blackMillis - elapsed);
        }
      }
      setState(() {
        _game = restored;
        _positionHistory
          ..clear()
          ..addAll((saved['positions'] as List).cast<String>());
        _uciMoves
          ..clear()
          ..addAll((saved['uciMoves'] as List).cast<String>());
        _takebackVariations
          ..clear()
          ..addAll(
            (saved['variations'] as List? ?? const []).map(
              (item) => RecordedVariation.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            ),
          );
        _playerColor = saved['playerIsWhite'] as bool? ?? true
            ? chess.Color.WHITE
            : chess.Color.BLACK;
        _sideChoice = _playerColor == chess.Color.WHITE
            ? PlayerSide.white
            : PlayerSide.black;
        _elo = saved['elo'] as int? ?? 1500;
        _timePreset = preset;
        _customMinutes = saved['customMinutes'] as int? ?? 10;
        _customIncrement = saved['customIncrement'] as int? ?? 0;
        _whiteMillis = whiteMillis;
        _blackMillis = blackMillis;
        _turnStartedAt = _clockEnabled ? DateTime.now() : null;
        _clockHistory
          ..clear()
          ..addAll(
            (saved['clockHistory'] as List? ?? const []).map((item) {
              final values = (item as List).cast<int>();
              return ClockSnapshot(values[0], values[1]);
            }),
          );
        if (_clockHistory.isEmpty) {
          _clockHistory.add(ClockSnapshot(whiteMillis, blackMillis));
        }
        _forcedResult = saved['forcedResult'] as String?;
        _status = saved['status'] as String? ?? 'Game restored.';
        _started = true;
      });
      if (_clockEnabled && !_gameFinished) {
        _clockTimer = Timer.periodic(
          const Duration(milliseconds: 200),
          (_) => _tickClock(),
        );
      }
      if (!_gameFinished && !_isPlayerTurn) unawaited(_playMaiaMove());
    } catch (error, stackTrace) {
      await AppDiagnostics.record('game-session-restore', error, stackTrace);
      await ActiveSessionStore.clear();
    }
  }

  Future<void> _saveGameState() async {
    if (!_started) return;
    await ActiveSessionStore.save({
      'type': 'game',
      'pgn': _game.pgn(),
      'positions': _positionHistory,
      'uciMoves': _uciMoves,
      'variations': _takebackVariations.map((item) => item.toJson()).toList(),
      'playerIsWhite': _playerIsWhite,
      'elo': _elo,
      'timePreset': _timePreset.name,
      'customMinutes': _customMinutes,
      'customIncrement': _customIncrement,
      'whiteMillis': _liveMillis(chess.Color.WHITE),
      'blackMillis': _liveMillis(chess.Color.BLACK),
      'clockHistory': _clockHistory
          .map((item) => [item.whiteMillis, item.blackMillis])
          .toList(),
      'savedAt': DateTime.now().toIso8601String(),
      'forcedResult': _forcedResult,
      'status': _status,
    });
  }

  Future<void> _saveReviewState(
    AnalysisSession session,
    bool playerIsWhite,
    String currentFen,
    bool flipped,
    List<RecordedVariation> variations,
  ) => ActiveSessionStore.save({
    'type': 'review',
    'session': session.toJson(),
    'variations': variations.map((item) => item.toJson()).toList(),
    'currentFen': currentFen,
    'flipped': flipped,
    'playerIsWhite': playerIsWhite,
    'maiaElo': _analysisElo,
  });

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

  Future<void> _showSamplingHelp() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Temperature and Top-P'),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Temperature controls how adventurous Maia is. At 0, Maia '
              'always chooses its most likely human move. Higher values make '
              'less likely moves more common.',
            ),
            SizedBox(height: 14),
            Text(
              'Top-P limits Maia to the smallest group of moves whose '
              'combined probability reaches this value. Lower values narrow '
              'the choice to more likely moves; 1.00 keeps every legal move.',
            ),
            SizedBox(height: 14),
            Text(
              'The defaults (Temperature 0.50 and Top-P 0.90) give some '
              'variety while keeping Maia close to its rating model.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );

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
      applicationName: 'Mobile Maia Preview',
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
        const SizedBox(height: 8),
        const Text(
          'Mobile Maia is free software distributed under AGPL-3.0-only, '
          'without any warranty. You may redistribute and modify it under '
          'the terms of that licence. The complete source code is available '
          'from the project repository.',
        ),
        TextButton.icon(
          onPressed: () => maiaEngineChannel.invokeMethod<void>('openUrl', {
            'url': mobileMaiaLicenseUrl,
          }),
          icon: const Icon(Icons.description_outlined),
          label: const Text('Licence'),
        ),
        TextButton.icon(
          onPressed: () => maiaEngineChannel.invokeMethod<void>('openUrl', {
            'url': mobileMaiaSourceUrl,
          }),
          icon: const Icon(Icons.code),
          label: const Text('Mobile Maia source code'),
        ),
        const Text(
          'This independent community app is not an official Maia-3 or '
          'University of Toronto or Lichess application.',
        ),
      ],
    );
  }

  Future<void> _openAnalysisBoard() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AnalysisBoardPage(
          initialSession: AnalysisSession.start(),
          maiaElo: _analysisElo,
        ),
      ),
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
      _game = widget.startingFen == null
          ? chess.Chess()
          : chess.Chess.fromFEN(widget.startingFen!);
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
      if (widget.startingFen != null &&
          widget.startingFen != chess.Chess.DEFAULT_POSITION) {
        _game.set_header(['SetUp', '1', 'FEN', widget.startingFen!]);
      }
    });
    if (_clockEnabled) {
      _clockTimer = Timer.periodic(
        const Duration(milliseconds: 200),
        (_) => _tickClock(),
      );
    }
    if (!_playerIsWhite) _playMaiaMove();
    unawaited(_saveGameState());
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
      unawaited(_saveGameState());
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
    unawaited(_saveGameState());
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
      if (!mounted || generation != _gameGeneration || _gameFinished) return;
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
      unawaited(_saveGameState());
      if (shouldRequestMaiaReply(
        premovePlayed: premovePlayed,
        gameOver: _game.game_over,
      )) {
        unawaited(_playMaiaMove());
      }
    } catch (error, stackTrace) {
      if (!mounted || generation != _gameGeneration) return;
      unawaited(AppDiagnostics.record('maia-game', error, stackTrace));
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
    unawaited(_saveGameState());
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
    unawaited(ActiveSessionStore.clear());
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
    unawaited(_saveGameState());
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
    final session = AnalysisSession(
      positions: List.unmodifiable(_positionHistory.take(plyCount + 1)),
      uciMoves: List.unmodifiable(_uciMoves.take(plyCount)),
      sanMoves: List.unmodifiable(moves.take(plyCount)),
      pgn: _exportPgn(),
    );
    final initialVariations = List<RecordedVariation>.unmodifiable(
      _takebackVariations,
    );
    await _saveReviewState(
      session,
      _playerIsWhite,
      session.positions.last,
      false,
      initialVariations,
    );
    if (!mounted) return;
    _reviewOpen = true;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReviewPage(
          positions: session.positions,
          uciMoves: session.uciMoves,
          sanMoves: session.sanMoves,
          playerIsWhite: _playerIsWhite,
          pgn: session.pgn,
          initialVariations: initialVariations,
          maiaElo: _analysisElo,
          initialCurrentFen: session.positions.last,
          onSessionChanged: (fen, flipped, variations) => _saveReviewState(
            session,
            _playerIsWhite,
            fen,
            flipped,
            variations,
          ),
          onHome: _goHome,
        ),
      ),
    );
    _reviewOpen = false;
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
        title: const Text('Mobile Maia Preview'),
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
              title: Row(
                children: [
                  const Expanded(child: Text('Advanced')),
                  IconButton(
                    key: const ValueKey('sampling-help'),
                    tooltip: 'About Temperature and Top-P',
                    onPressed: _showSamplingHelp,
                    icon: const Icon(Icons.help_outline),
                  ),
                ],
              ),
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
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openAnalysisBoard,
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('Analysis Board'),
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
                label: const Text('Game Review'),
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
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    super.dispose();
  }
}

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _controller,
      autofocus: true,
      minLines: 3,
      maxLines: 10,
      decoration: InputDecoration(
        hintText: widget.hint,
        border: const OutlineInputBorder(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _controller.text),
        child: const Text('Load'),
      ),
    ],
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class AnalysisBoardPage extends StatefulWidget {
  const AnalysisBoardPage({
    required this.initialSession,
    required this.maiaElo,
    this.initialVariations = const [],
    this.initialCurrentFen,
    this.initialFlipped = false,
    this.evaluator,
    this.maiaEvaluator,
    super.key,
  });

  final AnalysisSession initialSession;
  final int maiaElo;
  final List<RecordedVariation> initialVariations;
  final String? initialCurrentFen;
  final bool initialFlipped;
  final Future<StockfishReview> Function(String fen)? evaluator;
  final Future<String?> Function(List<String> positions, int elo)?
  maiaEvaluator;

  @override
  State<AnalysisBoardPage> createState() => _AnalysisBoardPageState();
}

class _AnalysisBoardPageState extends State<AnalysisBoardPage> {
  late AnalysisSession _session = widget.initialSession;
  late List<RecordedVariation> _initialVariations = widget.initialVariations;
  late String? _initialCurrentFen = widget.initialCurrentFen;
  late bool _initialFlipped = widget.initialFlipped;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    unawaited(
      _saveAnalysisState(
        _initialCurrentFen ?? widget.initialSession.positions.first,
        _initialFlipped,
        _initialVariations,
      ),
    );
  }

  Future<void> _saveAnalysisState(
    String currentFen,
    bool flipped,
    List<RecordedVariation> variations,
  ) => ActiveSessionStore.save({
    'type': 'analysis',
    'session': _session.toJson(),
    'variations': variations.map((item) => item.toJson()).toList(),
    'currentFen': currentFen,
    'flipped': flipped,
    'maiaElo': widget.maiaElo,
  });

  void _replace(AnalysisSession session) {
    setState(() {
      _session = session;
      _initialVariations = const [];
      _initialCurrentFen = session.positions.first;
      _initialFlipped = false;
      _revision++;
    });
    unawaited(_saveAnalysisState(session.positions.first, false, const []));
  }

  Future<String?> _textDialog(String title, String hint) async {
    return showDialog<String>(
      context: context,
      builder: (context) => _TextInputDialog(title: title, hint: hint),
    );
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error.toString())));
  }

  Future<void> _loadFen() async {
    final value = await _textDialog(
      'Load FEN',
      'Paste a complete six-field FEN',
    );
    if (value == null || value.trim().isEmpty) return;
    try {
      _replace(AnalysisSession.fromFen(value));
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _loadPgn() async {
    final value = await _textDialog('Load PGN', 'Paste a PGN game');
    if (value == null || value.trim().isEmpty) return;
    try {
      _replace(AnalysisSession.fromPgn(value));
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _editBoard(String fen) async {
    final edited = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => BoardEditorPage(initialFen: fen)),
    );
    if (edited != null) _replace(AnalysisSession.fromFen(edited));
  }

  Future<void> _playFrom(String fen) async {
    final side = await showDialog<PlayerSide>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Play from this position'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, PlayerSide.white),
            child: const ListTile(
              leading: Icon(Icons.light_mode),
              title: Text('Play White'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, PlayerSide.black),
            child: const ListTile(
              leading: Icon(Icons.dark_mode),
              title: Text('Play Black'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, PlayerSide.random),
            child: const ListTile(
              leading: Icon(Icons.casino_outlined),
              title: Text('Random side'),
            ),
          ),
        ],
      ),
    );
    if (side == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GamePage(
          startingFen: fen,
          startingSide: side,
          startingElo: widget.maiaElo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ReviewPage(
    key: ValueKey(_revision),
    positions: _session.positions,
    uciMoves: _session.uciMoves,
    sanMoves: _session.sanMoves,
    playerIsWhite: true,
    pgn: _session.pgn,
    initialVariations: _initialVariations,
    initialCurrentFen: _initialCurrentFen,
    initialFlipped: _initialFlipped,
    onSessionChanged: _saveAnalysisState,
    maiaElo: widget.maiaElo,
    evaluator: widget.evaluator,
    maiaEvaluator: widget.maiaEvaluator,
    title: 'Analysis Board',
    onHome: () => unawaited(ActiveSessionStore.clear()),
    onLoadFen: _loadFen,
    onLoadPgn: _loadPgn,
    onEditBoard: _editBoard,
    onPlayFromPosition: _playFrom,
  );
}

class BoardEditorPage extends StatefulWidget {
  const BoardEditorPage({required this.initialFen, super.key});

  final String initialFen;

  @override
  State<BoardEditorPage> createState() => _BoardEditorPageState();
}

class _BoardEditorPageState extends State<BoardEditorPage> {
  late chess.Chess _position = chess.Chess.fromFEN(
    widget.initialFen,
    check_validity: false,
  );
  chess.Color _color = chess.Color.WHITE;
  chess.PieceType _piece = chess.PieceType.PAWN;
  bool _whiteTurn = true;
  bool _wk = false;
  bool _wq = false;
  bool _bk = false;
  bool _bq = false;
  String _enPassant = '-';

  @override
  void initState() {
    super.initState();
    final fields = widget.initialFen.split(RegExp(r'\s+'));
    _whiteTurn = fields.length > 1 ? fields[1] == 'w' : true;
    final rights = fields.length > 2 ? fields[2] : '-';
    _wk = rights.contains('K');
    _wq = rights.contains('Q');
    _bk = rights.contains('k');
    _bq = rights.contains('q');
    _enPassant = fields.length > 3 ? fields[3] : '-';
  }

  void _touch(String square) {
    setState(() {
      final existing = _position.get(square);
      if (existing?.type == _piece && existing?.color == _color) {
        _position.remove(square);
      } else {
        _position.remove(square);
        _position.put(chess.Piece(_piece, _color), square);
      }
    });
  }

  String _editedFen() {
    final board = _position.fen.split(RegExp(r'\s+')).first;
    final rights =
        '${_wk ? 'K' : ''}${_wq ? 'Q' : ''}${_bk ? 'k' : ''}${_bq ? 'q' : ''}';
    return '$board ${_whiteTurn ? 'w' : 'b'} ${rights.isEmpty ? '-' : rights} $_enPassant 0 1';
  }

  void _finish() {
    final fen = _editedFen();
    final validation = chess.Chess.validate_fen(fen);
    if (validation['valid'] != true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validation['error'].toString())));
      return;
    }
    Navigator.pop(context, fen);
  }

  @override
  Widget build(BuildContext context) {
    const pieces = <chess.PieceType>[
      chess.PieceType.KING,
      chess.PieceType.QUEEN,
      chess.PieceType.ROOK,
      chess.PieceType.BISHOP,
      chess.PieceType.KNIGHT,
      chess.PieceType.PAWN,
    ];
    const labels = ['K', 'Q', 'R', 'B', 'N', 'P'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Board'),
        actions: [TextButton(onPressed: _finish, child: const Text('Done'))],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: LayoutBuilder(
                      builder: (_, box) => cg.StaticChessboard(
                        size: box.biggest.shortestSide,
                        orientation: dc.Side.white,
                        fen: _position.fen,
                        settings: const cg.StaticChessboardSettings(
                          colorScheme: cg.ChessboardColorScheme.brown,
                          pieceAssets: cg.PieceSet.cburnettAssets,
                          enableCoordinates: true,
                        ),
                        onTouchedSquare: (square) => _touch(square.name),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<chess.Color>(
                    segments: const [
                      ButtonSegment(
                        value: chess.Color.WHITE,
                        label: Text('White pieces'),
                      ),
                      ButtonSegment(
                        value: chess.Color.BLACK,
                        label: Text('Black pieces'),
                      ),
                    ],
                    selected: {_color},
                    onSelectionChanged: (value) =>
                        setState(() => _color = value.first),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: List.generate(
                      pieces.length,
                      (index) => ChoiceChip(
                        label: Text(labels[index]),
                        selected: _piece == pieces[index],
                        onSelected: (_) =>
                            setState(() => _piece = pieces[index]),
                      ),
                    ),
                  ),
                  SwitchListTile(
                    value: _whiteTurn,
                    onChanged: (value) => setState(() => _whiteTurn = value),
                    title: Text(_whiteTurn ? 'White to move' : 'Black to move'),
                  ),
                  ExpansionTile(
                    title: const Text('Castling rights'),
                    children: [
                      CheckboxListTile(
                        value: _wk,
                        onChanged: (v) => setState(() => _wk = v ?? false),
                        title: const Text('White kingside'),
                      ),
                      CheckboxListTile(
                        value: _wq,
                        onChanged: (v) => setState(() => _wq = v ?? false),
                        title: const Text('White queenside'),
                      ),
                      CheckboxListTile(
                        value: _bk,
                        onChanged: (v) => setState(() => _bk = v ?? false),
                        title: const Text('Black kingside'),
                      ),
                      CheckboxListTile(
                        value: _bq,
                        onChanged: (v) => setState(() => _bq = v ?? false),
                        title: const Text('Black queenside'),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _enPassant,
                    decoration: const InputDecoration(
                      labelText: 'En-passant target',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        [
                              '-',
                              for (final rank in [3, 6])
                                for (final file in 'abcdefgh'.split(''))
                                  '$file$rank',
                            ]
                            .map(
                              (square) => DropdownMenuItem(
                                value: square,
                                child: Text(square),
                              ),
                            )
                            .toList(),
                    onChanged: (value) =>
                        setState(() => _enPassant = value ?? '-'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => setState(() {
                          _position = chess.Chess();
                          _whiteTurn = true;
                          _wk = _wq = _bk = _bq = true;
                          _enPassant = '-';
                        }),
                        child: const Text('Starting position'),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _position = chess.Chess.fromFEN(
                            '8/8/8/8/8/8/8/8 w - - 0 1',
                            check_validity: false,
                          );
                          _whiteTurn = true;
                          _wk = _wq = _bk = _bq = false;
                          _enPassant = '-';
                        }),
                        child: const Text('Clear board'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
    this.title = 'Game review',
    this.onLoadFen,
    this.onLoadPgn,
    this.onEditBoard,
    this.onPlayFromPosition,
    this.initialCurrentFen,
    this.initialFlipped = false,
    this.onSessionChanged,
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
  final String title;
  final Future<void> Function()? onLoadFen;
  final Future<void> Function()? onLoadPgn;
  final Future<void> Function(String fen)? onEditBoard;
  final Future<void> Function(String fen)? onPlayFromPosition;
  final String? initialCurrentFen;
  final bool initialFlipped;
  final Future<void> Function(
    String currentFen,
    bool flipped,
    List<RecordedVariation> variations,
  )?
  onSessionChanged;

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
  bool _fullAnalysisClassifying = false;
  int _fullAnalysisCompleted = 0;
  int _fullAnalysisGeneration = 0;
  List<StockfishReview>? _graphScores;
  List<String> _graphPositions = const [];
  List<String> _graphMoves = const [];
  List<ClassifiedMove> _graphClassifications = const [];
  final Map<int, String> _maiaMoves = {};
  final Set<int> _maiaLoading = {};
  late final cg.ChessboardController _boardController;
  late dc.Chess _boardPosition;
  late final List<RecordedVariation> _variations;
  RecordedVariation? _openedVariation;
  int? _variationBasePly;
  int _variationIndex = 0;
  final List<String> _variationSan = [];
  final List<String> _variationUci = [];
  final List<String> _variationPositions = [];
  StockfishReview? _variationReview;
  String? _variationMaiaMove;
  bool _variationLoading = false;
  bool _variationMaiaLoading = false;
  String? _variationError;
  final Set<String> _collapsedVariationKeys = {};

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

  RecordedVariation? get _rootMainline => _maximumPly == 0
      ? _variations
            .where(
              (variation) =>
                  variation.basePly == 0 && variation.sanMoves.isNotEmpty,
            )
            .firstOrNull
      : widget.onSessionChanged != null
      ? _variations
            .where(
              (variation) =>
                  variation.basePly == 0 && variation.sanMoves.isNotEmpty,
            )
            .firstOrNull
      : null;

  ComputerAnalysisLine get _computerAnalysisLine {
    final rootMainline = _rootMainline;
    if (rootMainline == null) {
      final count = min(
        widget.uciMoves.length,
        max(0, widget.positions.length - 1),
      );
      return ComputerAnalysisLine(
        positions: widget.positions,
        uciMoves: widget.uciMoves.take(count).toList(growable: false),
      );
    }
    final game = chess.Chess.fromFEN(rootMainline.baseFen);
    final positions = <String>[game.fen];
    final uciMoves = <String>[];
    for (final san in rootMainline.sanMoves) {
      if (!game.move(san)) break;
      final move = game
          .getHistory({'verbose': true})
          .cast<Map<String, dynamic>>()
          .last;
      uciMoves.add('${move['from']}${move['to']}${move['promotion'] ?? ''}');
      positions.add(game.fen);
    }
    return ComputerAnalysisLine(
      positions: List.unmodifiable(positions),
      uciMoves: List.unmodifiable(uciMoves),
    );
  }

  void _showComputerAnalysisPly(int ply) {
    final rootMainline = _rootMainline;
    if (rootMainline != null) {
      _openVariation(rootMainline, ply);
    } else {
      setState(() => _showMainPly(ply));
    }
  }

  @override
  void initState() {
    super.initState();
    _flipped = widget.initialFlipped;
    _variations = List.of(widget.initialVariations);
    // The Analysis Board owns a mutable tree. Imported PGN mainlines arrive
    // as immutable seed positions, so normalize them into the same root-line
    // representation used by lines played directly on the board. This makes
    // Lichess-style delete/promote operations possible without special cases.
    if (widget.onSessionChanged != null &&
        widget.sanMoves.isNotEmpty &&
        !_variations.any(
          (line) => line.basePly == 0 && line.sanMoves.isNotEmpty,
        )) {
      final attached = _variations
          .where((line) => line.basePly > 0)
          .toList(growable: false);
      _variations.removeWhere((line) => line.basePly > 0);
      _variations.insert(
        0,
        RecordedVariation(
          basePly: 0,
          baseFen: widget.positions.first,
          sanMoves: List.unmodifiable(widget.sanMoves),
          children: attached,
        ),
      );
    }
    _boardPosition = dc.Chess.fromSetup(dc.Setup.parseFen(widget.positions[0]));
    _boardController = cg.ChessboardController(game: _boardGameData());
    final initialFen = widget.initialCurrentFen;
    if (initialFen != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _restoreCurrentFen(initialFen);
      });
    }
    unawaited(_analyzePosition(0));
    unawaited(_analyzeMaiaPosition(0));
  }

  void _notifySessionChanged() {
    final callback = widget.onSessionChanged;
    if (callback != null) {
      unawaited(
        callback(_currentFen, _flipped, List.unmodifiable(_variations)),
      );
    }
  }

  @override
  void dispose() {
    _boardController.dispose();
    super.dispose();
  }

  cg.GameData _boardGameData() => cg.GameData(
    fen: _boardPosition.fen,
    playerSide: _boardPosition.isGameOver
        ? cg.PlayerSide.none
        : cg.PlayerSide.both,
    sideToMove: _boardPosition.turn,
    validMoves: dc.makeLegalMoves(_boardPosition),
    kingSquareInCheck: _boardPosition.isCheck
        ? _boardPosition.board.kingOf(_boardPosition.turn)
        : null,
    lastMove: _selectedLastMove,
  );

  dc.Move? get _selectedLastMove {
    final uci = _inVariation
        ? (_variationIndex == 0 ? null : _variationUci[_variationIndex - 1])
        : (_ply == 0 ? null : widget.uciMoves[_ply - 1]);
    if (uci == null ||
        !RegExp(r'^[a-h][1-8][a-h][1-8][qrbn]?$').hasMatch(uci)) {
      return null;
    }
    return dc.NormalMove.fromUci(uci);
  }

  void _showMainPly(int ply) {
    _variationBasePly = null;
    _openedVariation = null;
    _variationIndex = 0;
    _variationSan.clear();
    _variationUci.clear();
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
    _notifySessionChanged();
  }

  void _onAnalysisMove(dc.Move move, {bool? viaDragAndDrop}) {
    if (!_boardPosition.isLegal(move)) return;
    final analysisMovesBefore = widget.onSessionChanged == null
        ? null
        : List<String>.of(_computerAnalysisLine.uciMoves);
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
      if (_variationIndex == 0) {
        // A move from the branch's starting position is a sibling RAV, not a
        // child of the branch's first move. Keeping this distinction is what
        // makes the exported PGN tree round-trip correctly.
        _insertSiblingVariation(opened, child);
      } else {
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
      }
      _openedVariation = child;
      _variationBasePly = basePly;
      _variationSan
        ..clear()
        ..add(san);
      _variationUci
        ..clear()
        ..add(uci);
      _variationPositions
        ..clear()
        ..add(fenBefore)
        ..add(_boardPosition.fen);
      _variationIndex = 1;
      _boardController.updatePosition(_boardGameData());
      setState(() {
        _invalidateGraphAnalysisIfLineChanged(analysisMovesBefore);
        _variationReview = null;
        _variationMaiaMove = null;
      });
      unawaited(_analyzeVariation());
      _notifySessionChanged();
      return;
    }
    if (_variationBasePly == null) {
      _variationBasePly = basePly;
      _variationSan.clear();
      _variationUci.clear();
      _variationPositions
        ..clear()
        ..add(fenBefore);
    }
    _variationSan.add(san);
    _variationUci.add(uci);
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
      _invalidateGraphAnalysisIfLineChanged(analysisMovesBefore);
      _variationReview = null;
      _variationMaiaMove = null;
    });
    unawaited(_analyzeVariation());
    _notifySessionChanged();
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

  void _insertSiblingVariation(
    RecordedVariation target,
    RecordedVariation sibling,
  ) {
    bool insert(List<RecordedVariation> lines) {
      for (var index = 0; index < lines.length; index++) {
        final current = lines[index];
        if (identical(current, target)) {
          lines.removeWhere(
            (item) =>
                item.basePly == sibling.basePly &&
                item.sanMoves.isNotEmpty &&
                item.sanMoves.first == sibling.sanMoves.first,
          );
          lines.add(sibling);
          return true;
        }
        final children = List<RecordedVariation>.of(current.children);
        if (insert(children)) {
          lines[index] = RecordedVariation(
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

    if (!insert(_variations)) _variations.add(sibling);
  }

  String _variationKey(RecordedVariation line) =>
      '${line.baseFen}|${line.sanMoves.firstOrNull ?? ''}';

  String _fenAt(RecordedVariation line, int moveIndex) {
    final game = chess.Chess.fromFEN(line.baseFen);
    for (final san in line.sanMoves.take(moveIndex)) {
      if (!game.move(san)) break;
    }
    return game.fen;
  }

  RecordedVariation? _deleteVariationFrom(
    RecordedVariation target,
    int moveIndex,
  ) {
    RecordedVariation? replacement;
    bool removeFrom(List<RecordedVariation> lines) {
      for (var index = 0; index < lines.length; index++) {
        final current = lines[index];
        if (identical(current, target)) {
          if (moveIndex <= 1) {
            lines.removeAt(index);
          } else {
            final deletedPly = current.basePly + moveIndex - 1;
            replacement = RecordedVariation(
              basePly: current.basePly,
              baseFen: current.baseFen,
              sanMoves: List.unmodifiable(current.sanMoves.take(moveIndex - 1)),
              children: current.children
                  .where((child) => child.basePly < deletedPly)
                  .toList(growable: false),
            );
            lines[index] = replacement!;
          }
          return true;
        }
        final children = List<RecordedVariation>.of(current.children);
        if (removeFrom(children)) {
          lines[index] = RecordedVariation(
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

    removeFrom(_variations);
    return replacement;
  }

  RecordedVariation _promoteVariationOnce(RecordedVariation target) {
    final topIndex = _variations.indexWhere((line) => identical(line, target));
    if (topIndex >= 0) {
      if (topIndex > 0) {
        _variations
          ..removeAt(topIndex)
          ..insert(0, target);
      }
      return target;
    }

    RecordedVariation? promoted;
    bool promoteIn(List<RecordedVariation> lines) {
      for (var index = 0; index < lines.length; index++) {
        final parent = lines[index];
        final directIndex = parent.children.indexWhere(
          (line) => identical(line, target),
        );
        if (directIndex >= 0) {
          final branchPly = target.basePly;
          final offset = (branchPly - parent.basePly).clamp(
            0,
            parent.sanMoves.length,
          );
          final oldTail = parent.sanMoves.skip(offset).toList(growable: false);
          final siblings = parent.children
              .where(
                (line) => !identical(line, target) && line.basePly <= branchPly,
              )
              .toList();
          if (oldTail.isNotEmpty) {
            siblings.add(
              RecordedVariation(
                basePly: branchPly,
                baseFen: target.baseFen,
                sanMoves: oldTail,
                children: parent.children
                    .where((line) => line.basePly > branchPly)
                    .toList(growable: false),
              ),
            );
          }
          siblings.addAll(target.children);
          promoted = RecordedVariation(
            basePly: parent.basePly,
            baseFen: parent.baseFen,
            sanMoves: [...parent.sanMoves.take(offset), ...target.sanMoves],
            children: siblings,
          );
          lines[index] = promoted!;
          return true;
        }
        final children = List<RecordedVariation>.of(parent.children);
        if (promoteIn(children)) {
          lines[index] = RecordedVariation(
            basePly: parent.basePly,
            baseFen: parent.baseFen,
            sanMoves: parent.sanMoves,
            children: children,
          );
          return true;
        }
      }
      return false;
    }

    promoteIn(_variations);
    return promoted ?? target;
  }

  bool _isTopLevelVariation(RecordedVariation target) =>
      _variations.any((line) => identical(line, target));

  Future<void> _showMoveActions(
    RecordedVariation line,
    int moveIndex, {
    required bool variation,
  }) async {
    if (widget.onSessionChanged == null) return;
    final selectedFen = _fenAt(line, moveIndex);
    final previousFen = _fenAt(line, moveIndex - 1);
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                line.sanMoves[moveIndex - 1],
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(height: 1),
            if (variation) ...[
              ListTile(
                leading: const Icon(Icons.subtitles_off),
                title: Text(
                  _collapsedVariationKeys.contains(_variationKey(line))
                      ? 'Expand variations'
                      : 'Collapse variations',
                ),
                onTap: () => Navigator.pop(context, 'collapse'),
              ),
              ListTile(
                leading: const Icon(Icons.expand_less),
                title: const Text('Promote variation'),
                onTap: () => Navigator.pop(context, 'promote'),
              ),
              ListTile(
                leading: const Icon(Icons.check),
                title: const Text('Make main line'),
                onTap: () => Navigator.pop(context, 'mainline'),
              ),
            ],
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete from here'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    final analysisMovesBefore = List<String>.of(_computerAnalysisLine.uciMoves);
    setState(() {
      switch (action) {
        case 'collapse':
          final key = _variationKey(line);
          if (!_collapsedVariationKeys.remove(key)) {
            _collapsedVariationKeys.add(key);
          }
          break;
        case 'delete':
          _deleteVariationFrom(line, moveIndex);
          break;
        case 'promote':
          _promoteVariationOnce(line);
          break;
        case 'mainline':
          var promoted = line;
          while (!_isTopLevelVariation(promoted) ||
              _variations.indexOf(promoted) > 0) {
            final next = _promoteVariationOnce(promoted);
            if (identical(next, promoted) && _variations.indexOf(next) == 0) {
              break;
            }
            promoted = next;
          }
          break;
      }
      if (action != 'collapse') {
        _invalidateGraphAnalysisIfLineChanged(analysisMovesBefore);
      }
    });
    if (action == 'delete') {
      _restoreCurrentFen(previousFen);
    } else if (action == 'promote' || action == 'mainline') {
      _restoreCurrentFen(selectedFen);
    }
    _notifySessionChanged();
  }

  void _openVariation(RecordedVariation variation, [int? selectedIndex]) {
    final sanGame = chess.Chess.fromFEN(variation.baseFen);
    var position = dc.Chess.fromSetup(dc.Setup.parseFen(variation.baseFen));
    final positions = <String>[variation.baseFen];
    final uciMoves = <String>[];
    for (final san in variation.sanMoves) {
      final sanOptions = sanGame.moves().cast<String>().toList();
      final moveOptions = sanGame
          .moves({'asObjects': true})
          .cast<chess.Move>()
          .toList();
      final index = sanOptions.indexOf(san);
      if (index < 0) return;
      final uci = MaiaEncoding.uci(moveOptions[index]);
      uciMoves.add(uci);
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
      _variationUci
        ..clear()
        ..addAll(uciMoves);
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
    _notifySessionChanged();
  }

  void _restoreCurrentFen(String fen) {
    final mainIndex = widget.positions.indexOf(fen);
    if (mainIndex >= 0) {
      setState(() => _showMainPly(mainIndex));
      return;
    }
    bool visit(RecordedVariation variation) {
      final game = chess.Chess.fromFEN(variation.baseFen);
      if (variation.baseFen == fen) {
        _openVariation(variation, 0);
        return true;
      }
      for (var index = 0; index < variation.sanMoves.length; index++) {
        if (!game.move(variation.sanMoves[index])) break;
        if (game.fen == fen) {
          _openVariation(variation, index + 1);
          return true;
        }
      }
      return variation.children.any(visit);
    }

    _variations.any(visit);
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

  void _invalidateGraphAnalysisState() {
    _fullAnalysisGeneration++;
    _fullAnalysisRunning = false;
    _fullAnalysisClassifying = false;
    _fullAnalysisCompleted = 0;
    _graphScores = null;
    _graphPositions = const [];
    _graphMoves = const [];
    _graphClassifications = const [];
  }

  void _invalidateGraphAnalysisIfLineChanged(List<String>? previousMoves) {
    if (previousMoves == null) return;
    final currentMoves = _computerAnalysisLine.uciMoves;
    if (previousMoves.length == currentMoves.length) {
      var unchanged = true;
      for (var index = 0; index < previousMoves.length; index++) {
        if (previousMoves[index] != currentMoves[index]) {
          unchanged = false;
          break;
        }
      }
      if (unchanged) return;
    }
    _invalidateGraphAnalysisState();
  }

  Future<void> _analyzeFullGame() async {
    if (_fullAnalysisRunning) return;
    final line = _computerAnalysisLine;
    final positions = line.positions;
    final generation = ++_fullAnalysisGeneration;
    setState(() {
      _fullAnalysisRunning = true;
      _fullAnalysisClassifying = false;
      _fullAnalysisCompleted = 0;
      _graphScores = null;
      _graphPositions = const [];
      _graphMoves = const [];
      _graphClassifications = const [];
      _analysisError = null;
    });
    final scores = <StockfishReview>[];
    final evaluate = widget.evaluator ?? StockfishAnalyzer.instance.evaluate;
    for (var i = 0; i < positions.length; i++) {
      if (!mounted || generation != _fullAnalysisGeneration) return;
      try {
        final matchesFixedMainline =
            i < widget.positions.length && positions[i] == widget.positions[i];
        if (matchesFixedMainline) {
          await _pendingAnalyses[i];
        }
        if (!mounted || generation != _fullAnalysisGeneration) return;
        final review = matchesFixedMainline
            ? (_reviews[i] ?? await evaluate(positions[i]))
            : await evaluate(positions[i]);
        if (!mounted || generation != _fullAnalysisGeneration) return;
        scores.add(review);
        if (i < widget.positions.length &&
            positions[i] == widget.positions[i]) {
          _reviews[i] = review;
        }
      } catch (error, stackTrace) {
        if (!mounted || generation != _fullAnalysisGeneration) return;
        unawaited(
          AppDiagnostics.record('stockfish-full-analysis', error, stackTrace),
        );
        _analysisError = 'Computer analysis failed: $error';
        break;
      }
      if (mounted) setState(() => _fullAnalysisCompleted = i + 1);
    }
    if (!mounted || generation != _fullAnalysisGeneration) return;
    var classifications = const <ClassifiedMove>[];
    if (scores.length == positions.length) {
      setState(() => _fullAnalysisClassifying = true);
      try {
        classifications = await MoveClassifier.classifyOffMainIsolate(
          scores: scores,
          positions: positions,
          uciMoves: line.uciMoves,
        );
      } catch (error, stackTrace) {
        if (!mounted || generation != _fullAnalysisGeneration) return;
        unawaited(
          AppDiagnostics.record('move-classification', error, stackTrace),
        );
        _analysisError = 'Move classification failed: $error';
      }
    }
    if (!mounted || generation != _fullAnalysisGeneration) return;
    setState(() {
      if (scores.length == positions.length && _analysisError == null) {
        _graphScores = List.unmodifiable(scores);
        _graphPositions = List.unmodifiable(positions);
        _graphMoves = List.unmodifiable(line.uciMoves);
        _graphClassifications = classifications;
      } else {
        _analysisError ??= 'Computer analysis did not complete. Try again.';
      }
      _fullAnalysisRunning = false;
      _fullAnalysisClassifying = false;
    });
  }

  Set<cg.Shape> get _arrows {
    final stockfishMoves = _stockfishMoves;
    final maiaMove = _inVariation
        ? _variationMaiaMove ?? ''
        : _maiaMoves[_ply] ?? '';
    final valid = RegExp(r'^[a-h][1-8][a-h][1-8][qrbn]?$');
    final arrows = <cg.Shape>{};
    const stockfishColors = [Color(0xff3d9be9), Color(0xff8ac8f5)];
    for (var index = 0; index < stockfishMoves.length; index++) {
      final move = stockfishMoves[index];
      if (move != maiaMove) {
        arrows.add(_arrow(move, stockfishColors[index]));
      }
    }
    if (valid.hasMatch(maiaMove) && !stockfishMoves.contains(maiaMove)) {
      arrows.add(_arrow(maiaMove, const Color(0xffe89b3c)));
    }
    return arrows;
  }

  List<String> get _stockfishMoves {
    final review = _review;
    if (review == null) return const [];
    final valid = RegExp(r'^[a-h][1-8][a-h][1-8][qrbn]?$');
    final candidates = <String>[
      if (review.lines.isNotEmpty && review.lines.first.moves.isNotEmpty)
        review.lines.first.moves.first
      else
        review.bestMove,
      if (review.lines.length > 1 && review.lines[1].moves.isNotEmpty)
        review.lines[1].moves.first,
    ];
    return candidates
        .where(valid.hasMatch)
        .toSet()
        .take(2)
        .toList(growable: false);
  }

  ({String uci, Color tailColor})? get _agreementArrow {
    final maiaMove = _inVariation
        ? _variationMaiaMove ?? ''
        : _maiaMoves[_ply] ?? '';
    final index = _stockfishMoves.indexOf(maiaMove);
    if (index < 0) return null;
    return (
      uci: maiaMove,
      tailColor: index == 0 ? const Color(0xff3d9be9) : const Color(0xff8ac8f5),
    );
  }

  MoveClassification? _classificationAt(int graphPly) => _graphClassifications
      .where((move) => move.ply == graphPly)
      .firstOrNull
      ?.classification;

  ({String square, MoveClassification classification})?
  get _currentBoardAnnotation {
    if (_inVariation && !identical(_openedVariation, _rootMainline)) {
      return null;
    }
    final graphPly = _inVariation ? _variationIndex : _ply;
    if (graphPly <= 0 || graphPly > _graphMoves.length) return null;
    final classification = _classificationAt(graphPly);
    if (classification == null) return null;
    final uci = _graphMoves[graphPly - 1];
    if (uci.length < 4) return null;
    return (square: uci.substring(2, 4), classification: classification);
  }

  cg.Arrow _arrow(String uci, Color color) => cg.Arrow(
    color: color,
    orig: dc.Square.fromName(uci.substring(0, 2)),
    dest: dc.Square.fromName(uci.substring(2, 4)),
  );

  String _sanForUci(String fen, String uci) {
    final game = chess.Chess.fromFEN(fen);
    final candidate = game
        .moves({'asObjects': true})
        .cast<chess.Move>()
        .where((move) => MaiaEncoding.uci(move) == uci)
        .firstOrNull;
    if (candidate == null) return uci;
    game.move(candidate);
    return game
        .getHistory({'verbose': true})
        .cast<Map<String, dynamic>>()
        .last['san']
        .toString();
  }

  String _pvSan(StockfishLine line) {
    final game = chess.Chess.fromFEN(_currentFen);
    final san = <String>[];
    for (final uci in line.moves.take(8)) {
      final candidate = game
          .moves({'asObjects': true})
          .cast<chess.Move>()
          .where((move) => MaiaEncoding.uci(move) == uci)
          .firstOrNull;
      if (candidate == null) break;
      game.move(candidate);
      san.add(
        game
            .getHistory({'verbose': true})
            .cast<Map<String, dynamic>>()
            .last['san']
            .toString(),
      );
    }
    return san.join(' ');
  }

  Widget _engineLinesPanel() {
    final review = _review;
    final maiaMove = _inVariation ? _variationMaiaMove : _maiaMoves[_ply];
    final stockfishLines = review?.lines.isNotEmpty == true
        ? review!.lines.take(2).toList(growable: false)
        : review == null || review.bestMove == '(none)'
        ? const <StockfishLine>[]
        : [
            StockfishLine(
              evaluation: review.evaluation,
              mate: review.mate,
              moves: [review.bestMove],
            ),
          ];
    final loading = _inVariation ? _variationLoading : _loading.contains(_ply);
    final error = _inVariation ? _variationError : _analysisError;
    final maiaLoading = _inVariation
        ? _variationMaiaLoading
        : _maiaLoading.contains(_ply);
    final maiaStockfishIndex = maiaMove == null
        ? -1
        : _stockfishMoves.indexOf(maiaMove);
    Widget engineRow({
      required String label,
      required Color color,
      required String text,
      Key? key,
    }) => SizedBox(
      key: key,
      height: 26,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
    return Container(
      key: const ValueKey('analysis-engine-lines'),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Column(
        children: [
          for (var index = 0; index < 2; index++)
            engineRow(
              key: ValueKey('stockfish-line-${index + 1}'),
              label: index < stockfishLines.length
                  ? _formatLineEvaluation(stockfishLines[index])
                  : 'SF${index + 1}',
              color: const Color(0xff72b7ee),
              text:
                  error ??
                  (index < stockfishLines.length
                      ? _pvSan(stockfishLines[index])
                      : loading
                      ? 'Analyzing…'
                      : '—'),
            ),
          engineRow(
            key: const ValueKey('maia-engine-line'),
            label: 'M${widget.maiaElo}',
            color: const Color(0xffe89b3c),
            text: maiaMove == null
                ? maiaLoading
                      ? 'Analyzing…'
                      : '—'
                : maiaStockfishIndex >= 0
                ? '${_sanForUci(_currentFen, maiaMove)} · Matches Stockfish${maiaStockfishIndex == 0 ? '' : ' #2'}'
                : _sanForUci(_currentFen, maiaMove),
          ),
        ],
      ),
    );
  }

  String _formatLineEvaluation(StockfishLine line) {
    if (line.mate != null) return '#${line.mate}';
    final pawns = line.evaluation / 100;
    return '${pawns >= 0 ? '+' : ''}${pawns.toStringAsFixed(1)}';
  }

  Widget _notationMove({
    required String san,
    required bool selected,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    Key? key,
    bool variation = false,
    MoveClassification? classification,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      key: key,
      color: selected ? colors.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(3),
      child: InkWell(
        borderRadius: BorderRadius.circular(3),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: variation ? 3 : 6,
            vertical: variation ? 3 : 7,
          ),
          child: Text(
            '$san${classification?.symbol ?? ''}',
            style: TextStyle(
              fontSize: variation ? 14 : 16,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? colors.onPrimaryContainer
                  : classification?.color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _variationLine(RecordedVariation variation, [int depth = 0]) =>
      Container(
        width: double.infinity,
        margin: EdgeInsets.only(left: 34 + depth * 14.0),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 1,
              runSpacing: 0,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '(',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                for (
                  var index = 0;
                  index < variation.sanMoves.length;
                  index++
                ) ...[
                  if ((variation.basePly + index).isEven)
                    Text(
                      '${((variation.basePly + index) ~/ 2) + 1}.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    )
                  else if (index == 0)
                    Text(
                      '${((variation.basePly + index) ~/ 2) + 1}...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    onLongPress: () =>
                        _showMoveActions(variation, index + 1, variation: true),
                  ),
                ],
                Text(
                  ')',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (!_collapsedVariationKeys.contains(_variationKey(variation)))
              for (final child in variation.children)
                _variationLine(child, depth + 1),
          ],
        ),
      );

  Widget _movesNotation() {
    final rootMainline = _rootMainline;
    final variationsByBase = <int, List<RecordedVariation>>{};
    for (final variation in _variations) {
      if (identical(variation, rootMainline)) continue;
      variationsByBase.putIfAbsent(variation.basePly, () => []).add(variation);
    }
    final renderedVariations = <RecordedVariation>{};
    final rows = <Widget>[];
    final mainlineLength = rootMainline?.sanMoves.length ?? _maximumPly;
    for (var whiteIndex = 0; whiteIndex < mainlineLength; whiteIndex += 2) {
      Widget move(int index) => _notationMove(
        key: ValueKey('mainline-move-$index'),
        san: rootMainline?.sanMoves[index] ?? widget.sanMoves[index],
        classification: _classificationAt(index + 1),
        selected: rootMainline != null
            ? identical(_openedVariation, rootMainline) &&
                  _variationIndex == index + 1
            : !_inVariation && _ply == index + 1,
        onTap: rootMainline != null
            ? () => _openVariation(rootMainline, index + 1)
            : () => setState(() => _showMainPly(index + 1)),
        onLongPress: rootMainline != null
            ? () => _showMoveActions(rootMainline, index + 1, variation: false)
            : null,
      );
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 34,
              child: Text(
                '${(whiteIndex ~/ 2) + 1}.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Expanded(child: move(whiteIndex)),
            Expanded(
              child: whiteIndex + 1 < mainlineLength
                  ? move(whiteIndex + 1)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
      for (final basePly in [whiteIndex, whiteIndex + 1]) {
        final attachedVariations = <RecordedVariation>[
          ...variationsByBase[basePly] ?? const [],
          if (rootMainline != null)
            ...rootMainline.children.where((child) => child.basePly == basePly),
        ];
        for (final variation in attachedVariations) {
          rows.add(_variationLine(variation));
          renderedVariations.add(variation);
        }
      }
    }
    // A review may begin from a terminal or deliberately truncated main line.
    // Keep analysis branches visible even when there is no corresponding row.
    for (final variation in _variations) {
      if (identical(variation, rootMainline)) continue;
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
      child: SingleChildScrollView(
        key: const ValueKey('analysis-move-scroll'),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: rows),
      ),
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
      _notifySessionChanged();
      return;
    }
    setState(() => _showMainPly(_ply + delta));
  }

  Future<void> _copyPgn() async {
    await Clipboard.setData(
      ClipboardData(
        text: PgnVariationExporter.export(
          widget.pgn,
          _rootMainline == null ? widget.sanMoves : const [],
          _variations,
          mainPositions: _rootMainline == null ? widget.positions : null,
        ),
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('PGN copied')));
    }
  }

  Future<void> _copyFen() async {
    await Clipboard.setData(ClipboardData(text: _currentFen));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('FEN copied')));
    }
  }

  Widget _analysisTabBar() {
    final colors = Theme.of(context).colorScheme;
    Widget tab({
      required bool graph,
      required IconData icon,
      required String tooltip,
    }) {
      final selected = _showGraph == graph;
      return Expanded(
        child: Tooltip(
          message: tooltip,
          child: Semantics(
            button: true,
            selected: selected,
            label: tooltip,
            child: InkWell(
              key: ValueKey(graph ? 'graph-tab' : 'moves-tab'),
              onTap: () => setState(() => _showGraph = graph),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected ? colors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: colors.surface,
      child: Row(
        children: [
          tab(
            graph: false,
            icon: Icons.account_tree_outlined,
            tooltip: 'Moves',
          ),
          tab(
            graph: true,
            icon: Icons.area_chart_outlined,
            tooltip: 'Computer analysis',
          ),
        ],
      ),
    );
  }

  Widget _movesTab() => Column(
    children: [
      Expanded(child: _movesNotation()),
      SizedBox(
        height: 52,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              key: const ValueKey('previous-move-button'),
              tooltip: 'Previous move',
              constraints: const BoxConstraints(minWidth: 80, minHeight: 48),
              onPressed: (_inVariation ? _variationIndex == 0 : _ply == 0)
                  ? null
                  : () => _step(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              key: const ValueKey('next-move-button'),
              tooltip: 'Next move',
              constraints: const BoxConstraints(minWidth: 80, minHeight: 48),
              onPressed:
                  (_inVariation
                      ? _variationIndex == _variationSan.length
                      : _ply == _maximumPly)
                  ? null
                  : () => _step(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _graphTab() {
    final scores = _graphScores;
    if (scores != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            AccuracySummary(scores: scores),
            const SizedBox(height: 8),
            AnalysisGraph(
              scores: scores,
              positions: _graphPositions,
              classifications: _graphClassifications,
              selectedPly: _rootMainline == null ? _ply : _variationIndex,
              onSelected: _showComputerAnalysisPly,
            ),
            const SizedBox(height: 8),
            MoveClassificationSummary(
              moves: _graphClassifications,
              selectedPly: _rootMainline == null ? _ply : _variationIndex,
              onSelected: _showComputerAnalysisPly,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _analyzeFullGame,
              icon: const Icon(Icons.refresh),
              label: const Text('Run computer analysis again'),
            ),
          ],
        ),
      );
    }
    final total = _computerAnalysisLine.positions.length;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_fullAnalysisRunning) ...[
              LinearProgressIndicator(
                value: _fullAnalysisClassifying
                    ? null
                    : total == 0
                    ? null
                    : _fullAnalysisCompleted / total,
              ),
              const SizedBox(height: 10),
              Text(
                _fullAnalysisClassifying
                    ? 'Classifying moves…'
                    : 'Analyzing $_fullAnalysisCompleted of $total positions…',
              ),
            ] else ...[
              const Text(
                'Run computer analysis to generate the evaluation graph and White/Black accuracy.',
                textAlign: TextAlign.center,
              ),
              if (_analysisError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _analysisError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const ValueKey('run-computer-analysis'),
                onPressed: _analyzeFullGame,
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('Run computer analysis'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final evaluation = _review?.evaluation;
    final mate = _review?.mate;
    final openingName = OpeningNames.identifyPositions([
      ...widget.positions.take(
        (_inVariation ? (_variationBasePly ?? 0) : _ply) + 1,
      ),
      if (_inVariation) ..._variationPositions.skip(1).take(_variationIndex),
    ]);
    final boardOrientation = _flipped
        ? (widget.playerIsWhite ? dc.Side.black : dc.Side.white)
        : (widget.playerIsWhite ? dc.Side.white : dc.Side.black);
    final agreement = _agreementArrow;
    final boardAnnotation = _currentBoardAnnotation;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: () {
              setState(() => _flipped = !_flipped);
              _notifySessionChanged();
            },
            icon: const Icon(Icons.flip_camera_android_outlined),
            tooltip: 'Flip board',
          ),
          IconButton(
            onPressed: _copyPgn,
            icon: const Icon(Icons.copy),
            tooltip: 'Copy PGN',
          ),
          if (widget.onLoadFen != null)
            PopupMenuButton<String>(
              tooltip: 'Analysis Board actions',
              onSelected: (value) async {
                switch (value) {
                  case 'fen':
                    await widget.onLoadFen?.call();
                  case 'pgn':
                    await widget.onLoadPgn?.call();
                  case 'edit':
                    await widget.onEditBoard?.call(_currentFen);
                  case 'play':
                    await widget.onPlayFromPosition?.call(_currentFen);
                  case 'copyFen':
                    await _copyFen();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'fen',
                  child: ListTile(
                    leading: Icon(Icons.content_paste),
                    title: Text('Load FEN'),
                  ),
                ),
                PopupMenuItem(
                  value: 'pgn',
                  child: ListTile(
                    leading: Icon(Icons.article_outlined),
                    title: Text('Load PGN'),
                  ),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit Board'),
                  ),
                ),
                PopupMenuItem(
                  value: 'play',
                  child: ListTile(
                    leading: Icon(Icons.play_arrow),
                    title: Text('Play from here'),
                  ),
                ),
                PopupMenuItem(
                  value: 'copyFen',
                  child: ListTile(
                    leading: Icon(Icons.copy),
                    title: Text('Copy FEN'),
                  ),
                ),
              ],
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
            final contentWidth = min(constraints.maxWidth, 600.0);
            final boardByWidth = max(0.0, contentWidth - 32);
            final boardByHeight = max(190.0, constraints.maxHeight - 365);
            final boardSize = min(boardByWidth, min(boardByHeight, 560.0));
            return Center(
              child: SizedBox(
                width: contentWidth,
                height: constraints.maxHeight,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                      child: _engineLinesPanel(),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: boardSize,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          EvaluationBar(evaluation: evaluation, mate: mate),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: boardSize,
                            height: boardSize,
                            child: Stack(
                              children: [
                                cg.Chessboard(
                                  controller: _boardController,
                                  size: boardSize,
                                  orientation: boardOrientation,
                                  onMove: _onAnalysisMove,
                                  shapes: _arrows,
                                  settings: const cg.ChessboardSettings(
                                    colorScheme: cg.ChessboardColorScheme.brown,
                                    pieceAssets: cg.PieceSet.cburnettAssets,
                                    enableCoordinates: true,
                                  ),
                                ),
                                if (agreement != null ||
                                    boardAnnotation != null)
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: CustomPaint(
                                        key: const ValueKey(
                                          'review-board-overlay',
                                        ),
                                        painter: ReviewBoardOverlayPainter(
                                          orientation: boardOrientation,
                                          agreementUci: agreement?.uci,
                                          agreementTailColor:
                                              agreement?.tailColor,
                                          annotationSquare:
                                              boardAnnotation?.square,
                                          classification:
                                              boardAnnotation?.classification,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 28,
                      child: openingName == null
                          ? const SizedBox.shrink()
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.menu_book_outlined, size: 16),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    openingName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    _analysisTabBar(),
                    Expanded(
                      child: SizedBox(
                        key: const ValueKey('analysis-tab-panel'),
                        width: double.infinity,
                        child: _showGraph ? _graphTab() : _movesTab(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ComputerAnalysisLine {
  const ComputerAnalysisLine({required this.positions, required this.uciMoves});

  final List<String> positions;
  final List<String> uciMoves;
}

enum MoveClassification {
  brilliant('!!', 'Brilliant', Color(0xff15aabf)),
  good('!', 'Good', Color(0xff12b886)),
  interesting('!?', 'Interesting', Color(0xff82c91e)),
  dubious('?!', 'Dubious', Color(0xfffab005)),
  mistake('?', 'Mistake', Color(0xfffd7e14)),
  blunder('??', 'Blunder', Color(0xfffa5252));

  const MoveClassification(this.symbol, this.label, this.color);

  final String symbol;
  final String label;
  final Color color;
}

class ClassifiedMove {
  const ClassifiedMove({required this.ply, required this.classification});

  final int ply;
  final MoveClassification classification;
  bool get whiteMoved => ply.isOdd;
}

class MoveClassifier {
  // This is a visual annotation heuristic, not the engine evaluation. Keep the
  // quiescence probe deliberately small so a long review can never monopolize
  // the UI; classification itself also runs outside the main isolate.
  static const _captureSearchNodeLimit = 64;

  static Future<List<ClassifiedMove>> classifyOffMainIsolate({
    required List<StockfishReview> scores,
    required List<String> positions,
    required List<String> uciMoves,
  }) {
    // Threshold-only classification is cheap and common in injected tests or
    // engines without MultiPV. The sacrifice heuristic is the expensive part.
    if (!scores.any((score) => score.lines.length > 1)) {
      return Future.value(
        classify(scores: scores, positions: positions, uciMoves: uciMoves),
      );
    }
    return Isolate.run(
      () => classify(scores: scores, positions: positions, uciMoves: uciMoves),
    );
  }

  static List<ClassifiedMove> classify({
    required List<StockfishReview> scores,
    required List<String> positions,
    required List<String> uciMoves,
  }) {
    final count = min(
      uciMoves.length,
      min(max(0, scores.length - 1), max(0, positions.length - 1)),
    );
    final result = <ClassifiedMove>[];
    final materialEvaluator = _NaiveMaterialEvaluator(
      nodeLimit: _captureSearchNodeLimit,
    );
    for (var ply = 1; ply <= count; ply++) {
      final whiteMoved = ply.isOdd;
      final previous = _normalized(scores[ply - 1], whiteMoved);
      final next = _normalized(scores[ply], whiteMoved);
      final loss = _winChance(previous) - _winChance(next);
      MoveClassification? classification;
      if (loss > 20) {
        classification = MoveClassification.blunder;
      } else if (loss > 10) {
        classification = MoveClassification.mistake;
      } else if (loss > 5) {
        classification = MoveClassification.dubious;
      } else {
        final previousReview = scores[ply - 1];
        final lines = previousReview.lines;
        if (lines.length > 1 &&
            lines[0].moves.isNotEmpty &&
            lines[1].moves.isNotEmpty) {
          final best = _normalizedLine(lines[0], whiteMoved);
          final second = _normalizedLine(lines[1], whiteMoved);
          final isSacrifice = _isSacrifice(
            positions[ply - 1],
            positions[ply],
            materialEvaluator,
          );
          if (_winChance(best) - _winChance(second) > 10 &&
              uciMoves[ply - 1] == lines[0].moves.first) {
            if (isSacrifice) {
              classification = MoveClassification.brilliant;
            } else {
              final beforePrevious = ply > 1
                  ? _normalized(scores[ply - 2], whiteMoved)
                  : 0;
              if (_winChance(best) - _winChance(beforePrevious) > 5) {
                classification = MoveClassification.good;
              }
            }
          } else if (isSacrifice && next > -200) {
            classification = MoveClassification.interesting;
          }
        }
      }
      if (classification != null) {
        result.add(ClassifiedMove(ply: ply, classification: classification));
      }
    }
    return List.unmodifiable(result);
  }

  static int _normalized(StockfishReview review, bool whiteMoved) {
    final value = review.mate == null
        ? review.evaluation.clamp(-1000, 1000)
        : 1000 * review.mate!.sign;
    return whiteMoved ? value : -value;
  }

  static int _normalizedLine(StockfishLine line, bool whiteMoved) {
    final value = line.mate == null
        ? line.evaluation.clamp(-1000, 1000)
        : 1000 * line.mate!.sign;
    return whiteMoved ? value : -value;
  }

  static double _winChance(int centipawns) =>
      50 + 50 * (2 / (1 + exp(-0.00368208 * centipawns)) - 1);

  static bool _isSacrifice(
    String beforeFen,
    String afterFen,
    _NaiveMaterialEvaluator evaluator,
  ) {
    final before = evaluator.evaluate(beforeFen);
    final after = -evaluator.evaluate(afterFen);
    return before > after + 100;
  }

  static int _materialForTurn(String fen) {
    const values = {'p': 90, 'n': 300, 'b': 300, 'r': 500, 'q': 1000};
    var white = 0;
    var black = 0;
    for (final rune in fen.split(' ').first.runes) {
      final piece = String.fromCharCode(rune);
      final value = values[piece.toLowerCase()] ?? 0;
      if (piece == piece.toUpperCase()) {
        white += value;
      } else {
        black += value;
      }
    }
    final score = white - black;
    return fen.split(' ')[1] == 'w' ? score : -score;
  }

  static int _pieceValue(chess.PieceType piece) => switch (piece.name) {
    'p' => 90,
    'n' || 'b' => 300,
    'r' => 500,
    'q' => 1000,
    _ => 0,
  };
}

class _NaiveMaterialEvaluator {
  _NaiveMaterialEvaluator({required this.nodeLimit});

  final int nodeLimit;
  final Map<String, int> _cache = {};

  int evaluate(String fen) => _cache.putIfAbsent(fen, () {
    final position = chess.Chess.fromFEN(fen);
    final moves = position
        .moves({'asObjects': true})
        .cast<chess.Move>()
        .toList(growable: false);
    if (moves.isEmpty) return position.in_checkmate ? -10000 : 0;
    final budget = _CaptureSearchBudget(nodeLimit);
    var best = -10000;
    for (final move in moves) {
      final next = chess.Chess.fromFEN(position.fen)..move(move);
      best = max(best, -_captureSearch(next, -10000, 10000, budget));
      if (budget.exhausted) break;
    }
    return best;
  });

  int _captureSearch(
    chess.Chess position,
    int alpha,
    int beta,
    _CaptureSearchBudget budget,
  ) {
    var lower = alpha;
    final standPat = MoveClassifier._materialForTurn(position.fen);
    if (!budget.takeNode()) return standPat;
    if (standPat >= beta) return beta;
    lower = max(lower, standPat);
    final captures =
        position
            .moves({'asObjects': true})
            .cast<chess.Move>()
            .where((move) => move.captured != null)
            .toList(growable: false)
          ..sort(
            (a, b) =>
                MoveClassifier._pieceValue(b.captured!)
                    .compareTo(MoveClassifier._pieceValue(a.captured!)),
          );
    for (final capture in captures) {
      final next = chess.Chess.fromFEN(position.fen)..move(capture);
      final value = -_captureSearch(next, -beta, -lower, budget);
      if (value >= beta) return beta;
      lower = max(lower, value);
      if (budget.exhausted) break;
    }
    return lower;
  }
}

class _CaptureSearchBudget {
  _CaptureSearchBudget(this.remaining);

  int remaining;
  bool get exhausted => remaining <= 0;

  bool takeNode() {
    if (remaining <= 0) return false;
    remaining--;
    return true;
  }
}

class MoveClassificationSummary extends StatelessWidget {
  const MoveClassificationSummary({
    required this.moves,
    required this.selectedPly,
    required this.onSelected,
    super.key,
  });

  final List<ClassifiedMove> moves;
  final int selectedPly;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    Widget countButton(
      List<ClassifiedMove> matches,
      String side,
      MoveClassification classification,
    ) {
      final selected = matches.any((move) => move.ply == selectedPly);
      final next =
          matches.where((move) => move.ply > selectedPly).firstOrNull ??
          matches.firstOrNull;
      final label = '${matches.length} $side ${classification.label} moves';
      return SizedBox(
        width: 48,
        height: 48,
        child: Semantics(
          button: matches.isNotEmpty,
          selected: selected,
          label: label,
          hint: matches.isEmpty ? null : 'Go to next',
          child: Tooltip(
            message: matches.isEmpty ? label : '$label · tap for next',
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: next == null ? null : () => onSelected(next.ply),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: selected
                      ? classification.color.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(child: Text('${matches.length}')),
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      key: const ValueKey('move-classification-summary'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            const Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Text('W', textAlign: TextAlign.center),
                ),
                Expanded(child: SizedBox.shrink()),
                SizedBox(
                  width: 48,
                  child: Text('B', textAlign: TextAlign.center),
                ),
              ],
            ),
            for (final classification in MoveClassification.values)
              Builder(
                builder: (context) {
                  final white = moves
                      .where(
                        (move) =>
                            move.whiteMoved &&
                            move.classification == classification,
                      )
                      .toList(growable: false);
                  final black = moves
                      .where(
                        (move) =>
                            !move.whiteMoved &&
                            move.classification == classification,
                      )
                      .toList(growable: false);
                  return DefaultTextStyle.merge(
                    style: TextStyle(color: classification.color),
                    child: Row(
                      children: [
                        countButton(white, 'White', classification),
                        SizedBox(
                          width: 42,
                          child: Text(
                            classification.symbol,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            classification.label,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        countButton(black, 'Black', classification),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class GamePhases {
  const GamePhases({this.middlegamePly, this.endgamePly});

  final int? middlegamePly;
  final int? endgamePly;
}

class GamePhaseDetector {
  static GamePhases detect(List<String> positions) {
    int? middlegame;
    int? endgame;
    for (var ply = 0; ply < positions.length; ply++) {
      final board = _pieces(positions[ply]);
      final majorMinorCount = board
          .where((piece) => 'qrbn'.contains(piece.piece.toLowerCase()))
          .length;
      if (middlegame == null &&
          (majorMinorCount <= 10 ||
              _backrankSparse(board) ||
              _mixedness(board) > 150)) {
        middlegame = ply;
      }
      if (middlegame != null && endgame == null && majorMinorCount <= 6) {
        endgame = ply;
      }
    }
    return GamePhases(middlegamePly: middlegame, endgamePly: endgame);
  }

  static List<({String piece, int file, int rank})> _pieces(String fen) {
    final result = <({String piece, int file, int rank})>[];
    final ranks = fen.split(' ').first.split('/');
    for (var row = 0; row < ranks.length; row++) {
      var file = 0;
      for (final rune in ranks[row].runes) {
        final value = String.fromCharCode(rune);
        final empty = int.tryParse(value);
        if (empty != null) {
          file += empty;
        } else {
          result.add((piece: value, file: file, rank: 7 - row));
          file++;
        }
      }
    }
    return result;
  }

  static bool _backrankSparse(
    List<({String piece, int file, int rank})> board,
  ) {
    final white = board
        .where(
          (piece) =>
              piece.rank == 0 && piece.piece == piece.piece.toUpperCase(),
        )
        .length;
    final black = board
        .where(
          (piece) =>
              piece.rank == 7 && piece.piece == piece.piece.toLowerCase(),
        )
        .length;
    return white < 4 || black < 4;
  }

  static int _mixedness(List<({String piece, int file, int rank})> board) {
    var total = 0;
    for (var y = 0; y <= 6; y++) {
      for (var x = 0; x <= 6; x++) {
        final region = board.where(
          (piece) =>
              piece.file >= x &&
              piece.file <= x + 1 &&
              piece.rank >= y &&
              piece.rank <= y + 1,
        );
        final white = region
            .where((piece) => piece.piece == piece.piece.toUpperCase())
            .length;
        final black = region.length - white;
        total += _regionScore(y + 1, white, black);
      }
    }
    return total;
  }

  static int _regionScore(int y, int white, int black) {
    if (white == 0 && black == 0) return 0;
    if (white == 1 && black == 0) return 1 + (8 - y);
    if (white == 2 && black == 0) return y > 2 ? 2 + (y - 2) : 0;
    if (white == 3 && black == 0) return y > 1 ? 3 + (y - 1) : 0;
    if (white == 4 && black == 0) return y > 1 ? 3 + (y - 1) : 0;
    if (white == 0 && black == 1) return 1 + y;
    if (white == 1 && black == 1) return 5 + (4 - y).abs();
    if (white == 2 && black == 1) return 4 + (y - 1);
    if (white == 3 && black == 1) return 5 + (y - 1);
    if (white == 0 && black == 2) return y < 6 ? 2 + (6 - y) : 0;
    if (white == 1 && black == 2) return 4 + (7 - y);
    if (white == 2 && black == 2) return 7;
    if (white == 0 && black == 3) return y < 7 ? 3 + (7 - y) : 0;
    if (white == 1 && black == 3) return 5 + (7 - y);
    if (white == 0 && black == 4) return y < 7 ? 3 + (7 - y) : 0;
    return 0;
  }
}

class ReviewBoardOverlayPainter extends CustomPainter {
  const ReviewBoardOverlayPainter({
    required this.orientation,
    this.agreementUci,
    this.agreementTailColor,
    this.annotationSquare,
    this.classification,
  });

  final dc.Side orientation;
  final String? agreementUci;
  final Color? agreementTailColor;
  final String? annotationSquare;
  final MoveClassification? classification;

  Offset _squareCenter(String square, double squareSize) {
    final file = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = int.parse(square[1]) - 1;
    final x = orientation == dc.Side.white ? file : 7 - file;
    final y = orientation == dc.Side.white ? 7 - rank : rank;
    return Offset((x + 0.5) * squareSize, (y + 0.5) * squareSize);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final squareSize = size.width / 8;
    final agreement = agreementUci;
    if (agreement != null && agreement.length >= 4) {
      final from = _squareCenter(agreement.substring(0, 2), squareSize);
      final to = _squareCenter(agreement.substring(2, 4), squareSize);
      final angle = atan2(to.dy - from.dy, to.dx - from.dx);
      final start = from + Offset(cos(angle), sin(angle)) * (squareSize / 3);
      final arrowSize = squareSize * 0.48;
      const arrowAngle = pi / 5;
      final arrowHeight = arrowSize * sin((pi - arrowAngle * 2) / 2);
      final headOffset = Offset(cos(angle), sin(angle)) * arrowHeight;
      canvas.drawLine(
        start,
        to - headOffset,
        Paint()
          ..color = agreementTailColor ?? const Color(0xff3d9be9)
          ..strokeWidth = squareSize / 4
          ..strokeCap = StrokeCap.butt,
      );
      final head = Path()
        ..moveTo(
          to.dx - arrowSize * cos(angle - arrowAngle),
          to.dy - arrowSize * sin(angle - arrowAngle),
        )
        ..lineTo(to.dx, to.dy)
        ..lineTo(
          to.dx - arrowSize * cos(angle + arrowAngle),
          to.dy - arrowSize * sin(angle + arrowAngle),
        )
        ..close();
      canvas.drawPath(head, Paint()..color = const Color(0xffe89b3c));
    }

    final square = annotationSquare;
    final moveClass = classification;
    if (square == null || moveClass == null) return;
    final center = _squareCenter(square, squareSize);
    canvas.drawRect(
      Rect.fromCenter(center: center, width: squareSize, height: squareSize),
      Paint()..color = moveClass.color.withValues(alpha: 0.22),
    );
    final badgeCenter = center + Offset(squareSize * 0.34, -squareSize * 0.34);
    canvas.drawCircle(
      badgeCenter + const Offset(0, 1),
      squareSize * 0.24,
      Paint()..color = Colors.black38,
    );
    canvas.drawCircle(
      badgeCenter,
      squareSize * 0.23,
      Paint()..color = moveClass.color,
    );
    final text = TextPainter(
      text: TextSpan(
        text: moveClass.symbol,
        style: TextStyle(
          color: Colors.white,
          fontSize: squareSize * (moveClass.symbol.length > 1 ? 0.25 : 0.32),
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, badgeCenter - Offset(text.width / 2, text.height / 2));
  }

  @override
  bool shouldRepaint(covariant ReviewBoardOverlayPainter oldDelegate) =>
      oldDelegate.orientation != orientation ||
      oldDelegate.agreementUci != agreementUci ||
      oldDelegate.agreementTailColor != agreementTailColor ||
      oldDelegate.annotationSquare != annotationSquare ||
      oldDelegate.classification != classification;
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
    String label(double? value) => value == null
        ? 'Not enough moves'
        : '${value.clamp(0, 100).toStringAsFixed(1)}%';
    Widget playerAccuracy(String side, double? value) => Expanded(
      child: Column(
        children: [
          Text(side, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(
            label(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
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
                    Row(
                      children: [
                        playerAccuracy('White', accuracy.white),
                        const SizedBox(width: 12),
                        playerAccuracy('Black', accuracy.black),
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
    required this.positions,
    required this.classifications,
    required this.selectedPly,
    required this.onSelected,
    super.key,
  });

  final List<StockfishReview> scores;
  final List<String> positions;
  final List<ClassifiedMove> classifications;
  final int selectedPly;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = scores[selectedPly.clamp(0, scores.length - 1)];
    final scoreLabel = selected.mate == null
        ? '${selected.evaluation >= 0 ? '+' : ''}${(selected.evaluation / 100).toStringAsFixed(1)}'
        : '#${selected.mate}';
    final boundedPly = selectedPly.clamp(0, scores.length - 1);
    return Semantics(
      label: 'Computer analysis graph',
      value: 'Position $boundedPly of ${scores.length - 1}, $scoreLabel',
      increasedValue: boundedPly < scores.length - 1
          ? 'Position ${boundedPly + 1}'
          : null,
      decreasedValue: boundedPly > 0 ? 'Position ${boundedPly - 1}' : null,
      onIncrease: boundedPly < scores.length - 1
          ? () => onSelected(boundedPly + 1)
          : null,
      onDecrease: boundedPly > 0 ? () => onSelected(boundedPly - 1) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Position $boundedPly of ${scores.length - 1}  ·  $scoreLabel',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          SizedBox(
            height: 130,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  if (scores.length < 2) return;
                  final fraction =
                      (details.localPosition.dx / constraints.maxWidth).clamp(
                        0.0,
                        1.0,
                      );
                  onSelected((fraction * (scores.length - 1)).round());
                },
                child: CustomPaint(
                  painter: AnalysisGraphPainter(
                    scores: scores,
                    positions: positions,
                    classifications: classifications,
                    selectedPly: selectedPly,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnalysisGraphPainter extends CustomPainter {
  AnalysisGraphPainter({
    required this.scores,
    this.positions = const [],
    this.classifications = const [],
    required this.selectedPly,
  });

  final List<StockfishReview> scores;
  final List<String> positions;
  final List<ClassifiedMove> classifications;
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
    final phases = GamePhaseDetector.detect(positions);
    void phaseLine(int ply, String label) {
      if (scores.length < 2 || ply <= 0 || ply >= scores.length) return;
      final x = ply * size.width / (scores.length - 1);
      final paint = Paint()
        ..color = const Color(0xffa0a0a0)
        ..strokeWidth = 1;
      for (var y = 0.0; y < size.height; y += 8) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, min(y + 4, size.height)),
          paint,
        );
      }
      final text = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Color(0xffd0d0d0),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: max(0.0, size.width - x - 4));
      text.paint(canvas, Offset(min(x + 4, size.width - text.width), 4));
    }

    final initialPhase = phases.endgamePly == 0
        ? 'Endgame'
        : phases.middlegamePly == 0
        ? 'Middlegame'
        : 'Opening';
    final opening = TextPainter(
      text: TextSpan(
        text: initialPhase,
        style: const TextStyle(
          color: Color(0xffd0d0d0),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    opening.paint(canvas, const Offset(5, 4));
    if (phases.middlegamePly != null) {
      phaseLine(phases.middlegamePly!, 'Middlegame');
    }
    if (phases.endgamePly != null) {
      phaseLine(phases.endgamePly!, 'Endgame');
    }
    for (final move in classifications) {
      if (move.ply < 0 || move.ply >= points.length) continue;
      canvas.drawCircle(
        points[move.ply],
        4,
        Paint()
          ..color = move.classification.color
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        points[move.ply],
        4,
        Paint()
          ..color = const Color(0xffeeeeee)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }
    final boundedSelectedPly = selectedPly.clamp(0, scores.length - 1);
    final selectedX = scores.length == 1
        ? 0.0
        : boundedSelectedPly * size.width / (scores.length - 1);
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
      oldDelegate.selectedPly != selectedPly ||
      oldDelegate.scores != scores ||
      oldDelegate.positions != positions ||
      oldDelegate.classifications != classifications;
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
    if (whiteExtras.isEmpty && blackExtras.isEmpty) {
      return const SizedBox.shrink();
    }
    return Semantics(
      label: 'Material difference',
      child: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (whiteExtras.isNotEmpty) ...[
              Text(
                whiteExtras.join(),
                style: const TextStyle(fontSize: 15, height: 1),
              ),
              if (net > 0) Text(' +$net', style: const TextStyle(fontSize: 12)),
            ],
            if (whiteExtras.isNotEmpty && blackExtras.isNotEmpty)
              const SizedBox(width: 12),
            if (blackExtras.isNotEmpty) ...[
              Text(
                blackExtras.join(),
                style: const TextStyle(fontSize: 15, height: 1),
              ),
              if (net < 0)
                Text(' +${-net}', style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
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
    _engine.stdin = 'go depth 12';
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

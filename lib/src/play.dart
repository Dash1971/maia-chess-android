part of '../main.dart';

class GamePage extends StatefulWidget {
  const GamePage({
    this.startingFen,
    this.startingSide,
    this.startingElo,
    this.maiaEvaluator,
    this.electronicBoardTransport,
    this.clockFactory,
    super.key,
  });

  final Stopwatch Function()? clockFactory;
  final String? startingFen;
  final PlayerSide? startingSide;
  final int? startingElo;
  final Future<Float32List> Function(List<String> positions, int elo)?
  maiaEvaluator;
  final ElectronicBoardTransport? electronicBoardTransport;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with WidgetsBindingObserver {
  chess.Chess _game = chess.Chess();
  final List<String> _positionHistory = [];
  final List<String> _uciMoves = [];
  List<String> _liveSanMoves = const [];
  final List<RecordedVariation> _takebackVariations = [];
  PlayerSide _sideChoice = PlayerSide.white;
  chess.Color _playerColor = chess.Color.WHITE;
  int _elo = 1500;
  int _analysisElo = 1600;
  late final cg.ChessboardController _gameBoardController;
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
  Stopwatch? _turnStartedAt;
  bool _clockPaused = false;
  bool _naturalGameOver = false;
  bool _maiaFailed = false;
  final MaiaInferenceScope _gameInferenceScope = MaiaInferenceScope();
  Timer? _clockTimer;
  late final ValueNotifier<ClockSnapshot> _clockDisplay;
  final List<ClockSnapshot> _clockHistory = [];
  int _gameGeneration = 0;
  bool _reviewOpen = false;
  List<RecordedVariation>? _reviewVariationSnapshot;
  bool _advancedExpanded = false;
  bool _playEloChangedSinceLoad = false;
  bool _screenWakeLockEnabled = false;
  bool _boardFlipped = false;
  bool _resultDialogShown = false;
  bool _savedAsIncomplete = false;
  int? _viewedPly;
  final ScrollController _liveMovesController = ScrollController();
  final Random _timingRandom = Random();
  late final ElectronicBoardTransport _chessnut;
  late final ChessnutLedController _chessnutLeds;
  StreamSubscription<ElectronicBoardEvent>? _chessnutSubscription;
  ElectronicBoardConnectionState _chessnutState =
      ElectronicBoardConnectionState.disconnected;
  String _chessnutMessage = 'Chessnut Go is disconnected.';
  String? _chessnutDeviceName;
  int? _chessnutBatteryPercent;
  bool _chessnutCharging = false;
  Map<String, String>? _chessnutPosition;
  bool _useChessnutGo = false;
  bool _chessnutSoundsEnabled = true;
  bool _chessnutGameActive = false;
  bool _chessnutTakebackRestoreActive = false;
  bool _physicalMoveInProgress = false;
  String? _pendingPhysicalMaiaMove;
  String? _lastChessnutIllegalPosition;
  bool _processingChessnutPosition = false;
  Map<String, String>? _queuedChessnutPosition;
  Timer? _chessnutLedRefreshTimer;
  int _chessnutLedRefreshGeneration = 0;
  int? _chessnutLedRefreshInFlightGeneration;

  bool get _playerIsWhite => _playerColor == chess.Color.WHITE;
  bool get _isPlayerTurn => _game.turn == _playerColor;
  bool get _gameFinished => _naturalGameOver || _forcedResult != null;
  int get _displayPly => _viewedPly ?? max(0, _positionHistory.length - 1);
  bool get _isViewingLivePosition =>
      _viewedPly == null || _displayPly == _positionHistory.length - 1;
  bool get _clockEnabled => _timePreset != TimePreset.unlimited;
  bool get _chessnutReady =>
      _chessnutState == ElectronicBoardConnectionState.ready;
  bool get _chessnutStartPositionReady {
    final observed = _chessnutPosition;
    if (!_chessnutReady || observed == null) return false;
    return ChessnutProtocol.positionsMatch(
      observed,
      ChessnutProtocol.pieceMapFromFen(chess.Chess.DEFAULT_POSITION),
    );
  }

  dc.Side get _boardOrientation {
    final playerSide = _playerIsWhite ? dc.Side.white : dc.Side.black;
    if (!_boardFlipped) return playerSide;
    return playerSide == dc.Side.white ? dc.Side.black : dc.Side.white;
  }

  chess.Color get _bottomBoardColor => _boardOrientation == dc.Side.white
      ? chess.Color.WHITE
      : chess.Color.BLACK;
  chess.Color get _topBoardColor => _bottomBoardColor == chess.Color.WHITE
      ? chess.Color.BLACK
      : chess.Color.WHITE;
  bool get _canTakeBack {
    if (_gameFinished || _uciMoves.isEmpty) return false;
    if (_chessnutGameActive) {
      return _chessnutReady &&
          !_physicalMoveInProgress &&
          !_chessnutTakebackRestoreActive;
    }
    return !_isPlayerTurn || _uciMoves.length >= 2;
  }

  int get _baseMinutes =>
      _timePreset == TimePreset.custom ? _customMinutes : _timePreset.minutes;
  int get _incrementSeconds => _timePreset == TimePreset.custom
      ? _customIncrement
      : _timePreset.increment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clockDisplay = ValueNotifier(const ClockSnapshot(0, 0));
    _chessnut =
        widget.electronicBoardTransport ?? ChessnutPlatformTransport.instance;
    _chessnutLeds = ChessnutLedController(_chessnut);
    _gameBoardController = cg.ChessboardController(game: _gameBoardData());
    if (widget.startingSide != null) _sideChoice = widget.startingSide!;
    if (widget.startingElo != null) _elo = widget.startingElo!;
    if (widget.startingFen == null) {
      maiaEngineChannel.setMethodCallHandler((call) async {
        if (call.method == 'pgnReceived') {
          _incomingPgnCheckRequested = true;
          await _checkIncomingPgn();
        }
      });
    }
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await _loadEnginePreferences();
    if (!mounted) return;
    if (widget.startingFen != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startGame());
    } else {
      await _restoreActiveSession();
      if (!mounted) return;
      setState(() => _initialized = true);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(_checkIncomingPgn()),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _pauseGame();
      if (!_reviewOpen) unawaited(_saveGameState());
    }
    if (state == AppLifecycleState.resumed) {
      _resumeGame();
      final position = _chessnutPosition;
      if (_chessnutGameActive && position != null) {
        _queueChessnutPosition(position);
      }
    }
    _updateScreenWakeLock(state);
  }

  Future<void> _restoreActiveSession([Map<String, dynamic>? selected]) async {
    final saved = selected ?? await ActiveSessionStore.load();
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
                initialTreeIsAuthoritative:
                    saved['treeIsAuthoritative'] == true,
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
        if (saved['activeGame'] case final Map game) {
          _reviewOpen = true;
          await _restoreGame(Map<String, dynamic>.from(game), paused: true);
        }
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
                    initialTreeIsAuthoritative:
                        saved['treeIsAuthoritative'] == true,
                    maiaElo: saved['maiaElo'] as int? ?? _analysisElo,
                    initialCurrentFen: saved['currentFen'] as String?,
                    initialFlipped: saved['flipped'] as bool? ?? false,
                    onSessionChanged: (fen, flipped, updated) =>
                        _handleReviewSessionChanged(
                          session,
                          saved['playerIsWhite'] as bool? ?? true,
                          fen,
                          flipped,
                          updated,
                        ),
                    onHome: ActiveSessionStore.clear,
                    returnToGame: _started && !_gameFinished,
                  ),
                ),
              )
              .whenComplete(() {
                _reviewOpen = false;
                _resumeGame();
                unawaited(_saveGameState());
              });
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
    if (saved['type'] == 'game') await _restoreGame(saved);
  }

  Future<void> _restoreGame(
    Map<String, dynamic> saved, {
    bool paused = false,
  }) async {
    try {
      final savedPgn = saved['pgn'] as String;
      final restoredSession = AnalysisSession.fromPgn(savedPgn);
      final restored = chess.Chess.fromFEN(restoredSession.positions.first);
      for (final san in restoredSession.sanMoves) {
        restored.move(san);
      }
      final headers = dc.PgnGame.parsePgn(
        savedPgn,
        initHeaders: dc.PgnGame.emptyHeaders,
      ).headers;
      restored.set_header([
        for (final entry in headers.entries) ...[entry.key, entry.value],
      ]);
      final savedAt = DateTime.tryParse(saved['savedAt'] as String? ?? '');
      var whiteMillis = saved['whiteMillis'] as int? ?? 0;
      var blackMillis = saved['blackMillis'] as int? ?? 0;
      final preset = TimePreset.values.byName(
        saved['timePreset'] as String? ?? TimePreset.unlimited.name,
      );
      if (savedAt != null &&
          preset != TimePreset.unlimited &&
          saved['clockPaused'] != true &&
          saved['forcedResult'] == null &&
          !restored.game_over) {
        // Wall-clock corrections must never add time to a saved clock.
        final elapsed = max(
          0,
          DateTime.now().difference(savedAt).inMilliseconds,
        );
        if (restored.turn == chess.Color.WHITE) {
          whiteMillis = max(0, whiteMillis - elapsed);
        } else {
          blackMillis = max(0, blackMillis - elapsed);
        }
      }
      setState(() {
        _game = restored;
        _naturalGameOver = restored.game_over;
        _clockPaused = paused;
        _maiaFailed = saved['maiaFailed'] == true;
        if (_maiaFailed) _clockPaused = true;
        _positionHistory
          ..clear()
          ..addAll(restoredSession.positions);
        _uciMoves
          ..clear()
          ..addAll(restoredSession.uciMoves);
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
        _turnStartedAt = _clockEnabled
            ? ((widget.clockFactory?.call() ?? Stopwatch())..start())
            : null;
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
        _boardFlipped = saved['flipped'] as bool? ?? false;
        _savedAsIncomplete =
            saved['recentState'] == 'incomplete' ||
            (saved['recentState'] == null &&
                saved['forcedResult'] == null &&
                !restored.game_over);
        _viewedPly = null;
        _chessnutGameActive = saved['electronicBoard'] == 'chessnut-go';
        _useChessnutGo = _chessnutGameActive;
        if (_chessnutGameActive) _timePreset = TimePreset.unlimited;
        _pendingPhysicalMaiaMove = saved['pendingPhysicalMaiaMove'] as String?;
        _chessnutTakebackRestoreActive =
            saved['chessnutTakebackRestore'] == true;
        _lastChessnutIllegalPosition = null;
        if (_chessnutGameActive) {
          _status = 'Reconnect Chessnut Go to continue.';
        }
        _started = true;
      });
      if (_chessnutGameActive) _ensureChessnutListening();
      _syncGameBoard(animate: false, resetPremove: true);
      if (_clockEnabled && !_gameFinished) {
        _clockTimer = Timer.periodic(
          const Duration(milliseconds: 200),
          (_) => _tickClock(),
        );
      }
      if (!_clockPaused &&
          !_gameFinished &&
          !_isPlayerTurn &&
          !_chessnutGameActive) {
        unawaited(_playMaiaMove());
      }
      if (_gameFinished &&
          (!_chessnutGameActive || _pendingPhysicalMaiaMove == null)) {
        _scheduleGameConclusion();
      }
    } catch (error, stackTrace) {
      await AppDiagnostics.record('game-session-restore', error, stackTrace);
      await ActiveSessionStore.clear();
    }
  }

  void _pauseGame() {
    if (!_started || _clockPaused || _gameFinished) return;
    _whiteMillis = _liveMillis(chess.Color.WHITE);
    _blackMillis = _liveMillis(chess.Color.BLACK);
    _turnStartedAt?.stop();
    _clockPaused = true;
    _gameGeneration++;
    _gameInferenceScope.invalidate();
    _engineThinking = false;
    _publishClock();
  }

  void _resumeGame() {
    if (!mounted ||
        !_started ||
        _reviewOpen ||
        _gameFinished ||
        _maiaFailed ||
        !_clockPaused) {
      return;
    }
    _clockPaused = false;
    _turnStartedAt = _clockEnabled
        ? ((widget.clockFactory?.call() ?? Stopwatch())..start())
        : null;
    _tickClock();
    if (!_isPlayerTurn && !_gameFinished) unawaited(_playMaiaMove());
    setState(() {});
  }

  Future<void> _saveGameState() async {
    if (!_started || _reviewOpen) return;
    await ActiveSessionStore.save(_gameSnapshot());
  }

  Map<String, Object?> _gameSnapshot({String? recentState}) => {
    'type': 'game',
    'recentState':
        recentState ??
        (_gameFinished
            ? 'completed'
            : _savedAsIncomplete
            ? 'incomplete'
            : 'active'),
    'pgn': _game.pgn(),
    'positions': List<String>.of(_positionHistory),
    'uciMoves': List<String>.of(_uciMoves),
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
    // UTC keeps elapsed-clock recovery stable if Android's timezone changes
    // while the process is stopped. Legacy local timestamps still parse.
    'savedAt': DateTime.now().toUtc().toIso8601String(),
    'forcedResult': _forcedResult,
    'status': _status,
    'clockPaused': _clockPaused,
    'maiaFailed': _maiaFailed,
    'flipped': _boardFlipped,
    if (_chessnutGameActive) 'electronicBoard': 'chessnut-go',
    if (_pendingPhysicalMaiaMove != null)
      'pendingPhysicalMaiaMove': _pendingPhysicalMaiaMove,
    if (_chessnutTakebackRestoreActive) 'chessnutTakebackRestore': true,
  };

  Future<void> _saveReviewState(
    AnalysisSession session,
    bool playerIsWhite,
    String currentFen,
    bool flipped,
    List<RecordedVariation> variations,
  ) => ActiveSessionStore.save({
    'type': 'review',
    'treeIsAuthoritative': true,
    if (_started) 'activeGame': _gameSnapshot(),
    'session': session.toJson(),
    'variations': variations.map((item) => item.toJson()).toList(),
    'currentFen': currentFen,
    'flipped': flipped,
    'playerIsWhite': playerIsWhite,
    'maiaElo': _analysisElo,
  });

  Future<void> _handleReviewSessionChanged(
    AnalysisSession session,
    bool playerIsWhite,
    String currentFen,
    bool flipped,
    List<RecordedVariation> variations,
  ) {
    final previous = _reviewVariationSnapshot;
    var variationsChanged =
        previous == null || previous.length != variations.length;
    if (!variationsChanged) {
      for (var index = 0; index < variations.length; index++) {
        if (!identical(previous[index], variations[index])) {
          variationsChanged = true;
          break;
        }
      }
    }
    if (variationsChanged) {
      final annotations = PgnVariationExporter.annotationsForMainline(
        session.sanMoves,
        variations,
      );
      _takebackVariations
        ..clear()
        ..addAll(annotations);
      _reviewVariationSnapshot = List.unmodifiable(variations);
    }
    return _saveReviewState(
      session,
      playerIsWhite,
      currentFen,
      flipped,
      variations,
    );
  }

  Future<void> _loadEnginePreferences() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    final savedPlayElo = preferences.getInt(maiaPlayEloPreferenceKey);
    setState(() {
      if (widget.startingElo == null && !_playEloChangedSinceLoad) {
        _elo = (savedPlayElo ?? 1500).clamp(500, 2500);
      }
      _humanTiming = preferences.getBool('humanTiming') ?? false;
      _temperature = (preferences.getDouble('temperatureV2') ?? 0.5).clamp(
        0.0,
        1.0,
      );
      _topP = (preferences.getDouble('topPV2') ?? 0.9).clamp(0.0, 1.0);
      _analysisElo = preferences.getInt('analysisElo') ?? 1600;
      _chessnutSoundsEnabled =
          preferences.getBool('chessnutBoardSounds') ?? true;
    });
  }

  void _changePlayElo(int elo, {required bool persist}) {
    final normalized = elo.clamp(500, 2500);
    _playEloChangedSinceLoad = true;
    setState(() => _elo = normalized);
    if (persist) {
      unawaited(_persistPlayElo(normalized));
    }
  }

  Future<void> _persistPlayElo(int elo) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(maiaPlayEloPreferenceKey, elo);
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

  Future<void> _setChessnutSoundsEnabled(bool enabled) async {
    setState(() => _chessnutSoundsEnabled = enabled);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('chessnutBoardSounds', enabled);
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
          'Game Review move classification and sacrifice-detection heuristics '
          'are adapted from the En Croissant open-source chess GUI.',
        ),
        TextButton.icon(
          onPressed: () => maiaEngineChannel.invokeMethod<void>('openUrl', {
            'url': enCroissantProjectUrl,
          }),
          icon: const Icon(Icons.open_in_new),
          label: const Text('En Croissant project and source code'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Mobile Maia is free software distributed under AGPL-3.0-only, '
          'without any warranty. You may redistribute and modify it under '
          'the terms of that licence. The complete source code is available '
          'from the project repository.',
        ),
        TextButton.icon(
          onPressed: () => showLicensePage(
            context: context,
            applicationName: 'Mobile Maia Preview',
          ),
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
          'University of Toronto, Lichess, or En Croissant application.',
        ),
      ],
    );
  }

  Future<void> _openPgnFile() async {
    try {
      final session = await PgnFiles.open();
      if (session != null && mounted) await _openImportedSession(session);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  bool _importing = false;
  bool _initialized = false;
  bool _incomingPgnCheckRequested = false;
  Future<void> _checkIncomingPgn() async {
    if (!_initialized || !mounted) return;
    if (_importing) {
      _incomingPgnCheckRequested = true;
      return;
    }
    _importing = true;
    _incomingPgnCheckRequested = false;
    var consumed = false;
    try {
      final text = await maiaEngineChannel.invokeMethod<String>(
        'getPendingPgn',
      );
      if (text != null) {
        consumed = true;
        final session = await Isolate.run(() => AnalysisSession.fromPgn(text));
        if (mounted) await _openImportedSession(session);
      }
    } on MissingPluginException {
      /* No Android document bridge in host tests. */
    } on PlatformException catch (error) {
      consumed = error.code == 'pgn_read_failed';
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open PGN: $error')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open PGN: $error')));
      }
    } finally {
      _importing = false;
      if (mounted && (consumed || _incomingPgnCheckRequested)) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => unawaited(_checkIncomingPgn()),
        );
      }
    }
  }

  Future<void> _openImportedSession(AnalysisSession session) async {
    _pauseGame();
    await _saveGameState();
    await ActiveSessionStore.startNew();
    if (!mounted) return;
    _reviewOpen = false;
    _clockTimer?.cancel();
    setState(() {
      _started = false;
      _engineThinking = false;
    });
    Navigator.of(context).popUntil((route) => route.isFirst);
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              AnalysisBoardPage(initialSession: session, maiaElo: _analysisElo),
        ),
      ),
    );
  }

  Future<void> _showRecentGames() async {
    final selected = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const RecentGamesPage()),
    );
    if (selected != null && mounted) await _restoreActiveSession(selected);
  }

  Future<void> _openAnalysisBoard() async {
    await ActiveSessionStore.startNew();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AnalysisBoardPage(
          initialSession: AnalysisSession.start(),
          maiaElo: _analysisElo,
        ),
      ),
    );
  }

  void _ensureChessnutListening() {
    _chessnutSubscription ??= _chessnut.events.listen(
      _handleChessnutEvent,
      onError: (Object error, StackTrace stackTrace) {
        unawaited(AppDiagnostics.record('chessnut-events', error, stackTrace));
        _chessnutLeds.invalidate();
        if (!mounted) return;
        setState(() {
          _chessnutState = ElectronicBoardConnectionState.error;
          _chessnutMessage = 'Chessnut connection error.';
          if (_chessnutGameActive) _status = _chessnutMessage;
        });
      },
    );
  }

  Future<void> _setUseChessnutGo(bool enabled) async {
    if (_started) return;
    setState(() {
      _useChessnutGo = enabled;
      if (enabled) _timePreset = TimePreset.unlimited;
    });
    if (enabled) {
      await _connectChessnut();
    } else {
      await _disconnectChessnut();
    }
  }

  Future<void> _connectChessnut() async {
    _ensureChessnutListening();
    if (mounted) {
      setState(() {
        _chessnutPosition = null;
        _chessnutState = ElectronicBoardConnectionState.scanning;
        _chessnutMessage = 'Searching for Chessnut Go…';
      });
    }
    try {
      await _chessnut.connect();
    } on PlatformException catch (error, stackTrace) {
      unawaited(AppDiagnostics.record('chessnut-connect', error, stackTrace));
      if (!mounted) return;
      setState(() {
        _chessnutState = ElectronicBoardConnectionState.error;
        _chessnutMessage = error.message ?? 'Could not connect Chessnut Go.';
        if (_chessnutGameActive) _status = _chessnutMessage;
      });
    } on MissingPluginException catch (error, stackTrace) {
      unawaited(
        AppDiagnostics.record('chessnut-unavailable', error, stackTrace),
      );
      if (!mounted) return;
      setState(() {
        _chessnutState = ElectronicBoardConnectionState.error;
        _chessnutMessage = 'Chessnut Go support is available on Android.';
      });
    }
  }

  Future<void> _disconnectChessnut() async {
    _stopChessnutLedRefresh();
    try {
      if (_chessnutReady) await _chessnut.setLeds(const []);
      await _chessnut.disconnect();
    } on PlatformException catch (error, stackTrace) {
      unawaited(
        AppDiagnostics.record('chessnut-disconnect', error, stackTrace),
      );
    } on MissingPluginException {
      // Unit tests and non-Android builds have no Chessnut platform bridge.
    }
    if (!mounted) return;
    setState(() {
      _chessnutState = ElectronicBoardConnectionState.disconnected;
      _chessnutMessage = 'Chessnut Go is disconnected.';
      _chessnutPosition = null;
      if (_chessnutGameActive) _status = 'Reconnect Chessnut Go to continue.';
    });
  }

  void _handleChessnutEvent(ElectronicBoardEvent event) {
    if (!mounted) return;
    if (event.type == 'battery') {
      setState(() {
        _chessnutBatteryPercent = event.batteryPercent;
        _chessnutCharging = event.charging ?? false;
      });
      return;
    }
    if (event.type == 'position') {
      final position = event.position;
      if (position == null) return;
      setState(() => _chessnutPosition = position);
      _queueChessnutPosition(position);
      return;
    }
    final nextState = event.connectionState;
    if (nextState == null) return;
    if (nextState != _chessnutState) _chessnutLeds.invalidate();
    setState(() {
      _chessnutState = nextState;
      _chessnutMessage = event.message ?? _chessnutMessage;
      _chessnutDeviceName = event.deviceName ?? _chessnutDeviceName;
      if (_chessnutGameActive &&
          (nextState == ElectronicBoardConnectionState.disconnected ||
              nextState == ElectronicBoardConnectionState.error)) {
        _status = nextState == ElectronicBoardConnectionState.disconnected
            ? 'Reconnect Chessnut Go to continue.'
            : _chessnutMessage;
      }
    });
    if (nextState == ElectronicBoardConnectionState.ready) {
      if (_pendingPhysicalMaiaMove != null) {
        _startChessnutLedRefresh(immediate: true);
      } else if (_chessnutTakebackRestoreActive) {
        _startChessnutLedRefresh(immediate: true);
      }
      final position = _chessnutPosition;
      if (position != null) _queueChessnutPosition(position);
    } else if (nextState == ElectronicBoardConnectionState.disconnected ||
        nextState == ElectronicBoardConnectionState.error) {
      _stopChessnutLedRefresh();
    }
  }

  void _queueChessnutPosition(Map<String, String> position) {
    _queuedChessnutPosition = position;
    if (_processingChessnutPosition) return;
    _processingChessnutPosition = true;
    unawaited(_drainChessnutPositions());
  }

  Future<void> _drainChessnutPositions() async {
    try {
      while (mounted && _queuedChessnutPosition != null) {
        final position = _queuedChessnutPosition!;
        _queuedChessnutPosition = null;
        await _handleChessnutPosition(position);
      }
    } catch (error, stackTrace) {
      await AppDiagnostics.record('chessnut-position', error, stackTrace);
    } finally {
      _processingChessnutPosition = false;
      if (mounted && _queuedChessnutPosition != null) {
        _queueChessnutPosition(_queuedChessnutPosition!);
      }
    }
  }

  Future<void> _handleChessnutPosition(Map<String, String> observed) async {
    if (!_useChessnutGo || !_chessnutReady) return;
    if (!_started) {
      final expected = ChessnutProtocol.pieceMapFromFen(
        chess.Chess.DEFAULT_POSITION,
      );
      final matches = ChessnutProtocol.positionsMatch(observed, expected);
      await _setChessnutLeds(
        matches
            ? const []
            : ChessnutProtocol.mismatchSquares(observed, expected),
      );
      if (!mounted) return;
      setState(() {
        _chessnutMessage = matches
            ? 'Chessnut Go is ready.'
            : 'Set up the standard starting position on Chessnut Go.';
      });
      return;
    }
    if (!_chessnutGameActive) return;

    final expected = ChessnutProtocol.pieceMapFromFen(_game.fen);
    if (_chessnutTakebackRestoreActive) {
      final matches = ChessnutProtocol.positionsMatch(observed, expected);
      final mismatch = matches
          ? const <String>[]
          : ChessnutProtocol.mismatchSquares(observed, expected);
      await _setChessnutLeds(mismatch);
      _lastChessnutIllegalPosition = null;
      if (!mounted) return;
      if (matches) {
        _stopChessnutLedRefresh();
        setState(() {
          _chessnutTakebackRestoreActive = false;
          _status = _isPlayerTurn
              ? 'Takeback complete. Your move on Chessnut Go.'
              : 'Takeback complete. Maia is thinking…';
        });
        unawaited(_saveGameState());
        if (!_isPlayerTurn && !_engineThinking) unawaited(_playMaiaMove());
      } else {
        setState(
          () => _status = 'Takeback: restore the lit squares on Chessnut Go.',
        );
      }
      return;
    }
    if (ChessnutProtocol.positionsMatch(observed, expected)) {
      final generation = _gameGeneration;
      final matchedFen = _game.fen;
      final matchedPendingMove = _pendingPhysicalMaiaMove;
      _stopChessnutLedRefresh();
      await _setChessnutLeds(const []);
      // A Bluetooth completion can arrive after Maia advances the game.
      // Only acknowledge the position and pending move that we matched.
      if (!mounted ||
          generation != _gameGeneration ||
          matchedFen != _game.fen ||
          matchedPendingMove != _pendingPhysicalMaiaMove) {
        return;
      }
      _lastChessnutIllegalPosition = null;
      final confirmedMaiaMove = _pendingPhysicalMaiaMove != null;
      setState(() {
        _pendingPhysicalMaiaMove = null;
        if (_gameFinished) {
          _status = _game.game_over ? _finishNaturalGame() : _resultText();
        } else if (_isPlayerTurn) {
          _status = 'Your move on Chessnut Go.';
        } else if (!_engineThinking) {
          _status = 'Maia is thinking…';
        }
      });
      if (confirmedMaiaMove) {
        unawaited(_saveGameState());
        if (_gameFinished) _scheduleGameConclusion();
      }
      if (!_gameFinished && !_isPlayerTurn && !_engineThinking) {
        unawaited(_playMaiaMove());
      }
      return;
    }

    if (_pendingPhysicalMaiaMove != null) {
      _lastChessnutIllegalPosition = null;
      await _setChessnutLeds(
        ChessnutProtocol.mismatchSquares(observed, expected),
      );
      if (mounted) {
        setState(() => _status = 'Complete Maia’s lit move on Chessnut Go.');
      }
      return;
    }
    if (!_isPlayerTurn || _engineThinking || _physicalMoveInProgress) return;

    final uci = ChessnutProtocol.inferLegalMove(_game, observed);
    if (uci != null) {
      _lastChessnutIllegalPosition = null;
      _physicalMoveInProgress = true;
      try {
        await _setChessnutLeds(const []);
        await _commitHumanMove(uci, fromChessnut: true);
      } finally {
        _physicalMoveInProgress = false;
      }
      return;
    }

    final completeAttempt = ChessnutProtocol.looksLikeCompleteMoveAttempt(
      _game,
      observed,
    );
    if (completeAttempt) {
      final signature = _chessnutPositionSignature(observed);
      if (_lastChessnutIllegalPosition != signature) {
        _lastChessnutIllegalPosition = signature;
        await _beepChessnut();
      }
    } else {
      _lastChessnutIllegalPosition = null;
    }
    await _setChessnutLeds(
      completeAttempt
          ? ChessnutProtocol.mismatchSquares(observed, expected)
          : const [],
    );
    if (!mounted) return;
    setState(() {
      _status = completeAttempt
          ? 'That position is not a legal move. Correct the lit squares.'
          : 'Complete your move on Chessnut Go.';
    });
  }

  Future<void> _setChessnutLeds(
    Iterable<String> squares, {
    bool refresh = false,
  }) async {
    if (!_chessnutReady) return;
    try {
      await _chessnutLeds.setLeds(squares, refresh: refresh);
    } on PlatformException catch (error, stackTrace) {
      unawaited(AppDiagnostics.record('chessnut-leds', error, stackTrace));
    }
  }

  Future<void> _beepChessnut() async {
    if (!_chessnutGameActive || !_chessnutReady || !_chessnutSoundsEnabled) {
      return;
    }
    try {
      await _chessnut.beep();
      // Match the CLI's alert pacing before another board command is sent.
      await Future<void>.delayed(const Duration(milliseconds: 200));
    } catch (error, stackTrace) {
      unawaited(AppDiagnostics.record('chessnut-beep', error, stackTrace));
    }
  }

  String _chessnutPositionSignature(Map<String, String> position) {
    final entries = position.entries.toList(growable: false)
      ..sort((left, right) => left.key.compareTo(right.key));
    return entries.map((entry) => '${entry.key}${entry.value}').join();
  }

  void _startChessnutLedRefresh({bool immediate = false}) {
    _chessnutLedRefreshTimer?.cancel();
    if (_pendingPhysicalMaiaMove == null && !_chessnutTakebackRestoreActive) {
      _chessnutLedRefreshGeneration++;
      return;
    }
    final generation = ++_chessnutLedRefreshGeneration;
    if (immediate) unawaited(_refreshPendingChessnutLeds(generation));
    _chessnutLedRefreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => unawaited(_refreshPendingChessnutLeds(generation)),
    );
  }

  void _stopChessnutLedRefresh() {
    _chessnutLedRefreshTimer?.cancel();
    _chessnutLedRefreshTimer = null;
    _chessnutLedRefreshGeneration++;
  }

  Future<void> _refreshPendingChessnutLeds(int generation) async {
    if (generation != _chessnutLedRefreshGeneration) return;
    if (_chessnutLedRefreshInFlightGeneration == generation) return;
    _chessnutLedRefreshInFlightGeneration = generation;
    try {
      final pending = _pendingPhysicalMaiaMove;
      if (!mounted ||
          !_chessnutGameActive ||
          (pending == null && !_chessnutTakebackRestoreActive)) {
        if (generation == _chessnutLedRefreshGeneration) {
          _stopChessnutLedRefresh();
        }
        return;
      }
      if (!_chessnutReady) return;
      final observed = _chessnutPosition;
      final squares = observed == null
          ? pending == null
                ? const <String>[]
                : [pending.substring(0, 2), pending.substring(2, 4)]
          : ChessnutProtocol.mismatchSquares(
              observed,
              ChessnutProtocol.pieceMapFromFen(_game.fen),
            );
      if (squares.isNotEmpty && generation == _chessnutLedRefreshGeneration) {
        await _setChessnutLeds(squares, refresh: true);
      }
    } finally {
      if (_chessnutLedRefreshInFlightGeneration == generation) {
        _chessnutLedRefreshInFlightGeneration = null;
      }
    }
  }

  Future<void> _showChessnutPanel() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                _chessnutReady ? Icons.bluetooth_connected : Icons.bluetooth,
              ),
              title: Text(_chessnutDeviceName ?? 'Chessnut Go'),
              subtitle: Text(_chessnutMessage),
              trailing: _chessnutBatteryPercent == null
                  ? null
                  : Text(
                      '$_chessnutBatteryPercent%${_chessnutCharging ? ' ⚡' : ''}',
                    ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.volume_up_outlined),
              value: _chessnutSoundsEnabled,
              title: const Text('Board sounds'),
              subtitle: const Text('Check, checkmate, and illegal moves'),
              onChanged: (enabled) =>
                  Navigator.pop(context, enabled ? 'sounds-on' : 'sounds-off'),
            ),
            if (_chessnutReady)
              ListTile(
                leading: const Icon(Icons.bluetooth_disabled),
                title: const Text('Disconnect'),
                onTap: () => Navigator.pop(context, 'disconnect'),
              )
            else
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Reconnect'),
                onTap: () => Navigator.pop(context, 'connect'),
              ),
          ],
        ),
      ),
    );
    if (action == 'connect') await _connectChessnut();
    if (action == 'disconnect') await _disconnectChessnut();
    if (action == 'sounds-on') await _setChessnutSoundsEnabled(true);
    if (action == 'sounds-off') await _setChessnutSoundsEnabled(false);
  }

  Widget _chessnutStatusBanner() => Semantics(
    label: _status,
    child: Container(
      key: const ValueKey('chessnut-status-banner'),
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(
            _chessnutReady
                ? Icons.bluetooth_connected
                : Icons.bluetooth_disabled,
            size: 17,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              _status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          if (_chessnutBatteryPercent != null)
            Text(
              '$_chessnutBatteryPercent%${_chessnutCharging ? ' ⚡' : ''}',
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
    ),
  );

  cg.GameData _gameBoardData() {
    final ply = _displayPly
        .clamp(0, max(0, _positionHistory.length - 1))
        .toInt();
    final fen = _positionHistory.isEmpty ? _game.fen : _positionHistory[ply];
    final position = dc.Chess.fromSetup(dc.Setup.parseFen(fen));
    final lastMove = ply == 0 || _uciMoves.isEmpty
        ? null
        : dc.NormalMove.fromUci(_uciMoves[ply - 1]);
    return cg.GameData(
      fen: fen,
      playerSide:
          !_started ||
              _gameFinished ||
              !_isViewingLivePosition ||
              _chessnutGameActive
          ? cg.PlayerSide.none
          : _playerIsWhite
          ? cg.PlayerSide.white
          : cg.PlayerSide.black,
      sideToMove: position.turn,
      validMoves: dc.makeLegalMoves(position),
      kingSquareInCheck: position.isCheck
          ? position.board.kingOf(position.turn)
          : null,
      lastMove: lastMove,
    );
  }

  void _syncGameBoard({bool animate = true, bool resetPremove = false}) {
    _naturalGameOver = _game.game_over;
    _liveSanMoves = _game
        .getHistory({'verbose': true})
        .cast<Map<String, dynamic>>()
        .map((move) => move['san'] as String)
        .toList(growable: false);
    _gameBoardController.updatePosition(
      _gameBoardData(),
      animate: animate,
      resetPremove: resetPremove,
    );
    _publishClock();
    _updateScreenWakeLock();
    _scrollLiveMovesToEnd();
  }

  void _stepGameHistory(int delta) {
    if (_positionHistory.isEmpty) return;
    final last = _positionHistory.length - 1;
    final next = (_displayPly + delta).clamp(0, last);
    setState(() => _viewedPly = next == last ? null : next);
    _gameBoardController.updatePosition(
      _gameBoardData(),
      animate: true,
      resetPremove: true,
    );
  }

  void _scrollLiveMovesToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_liveMovesController.hasClients) return;
      _liveMovesController.animateTo(
        _liveMovesController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  void _publishClock() {
    _clockDisplay.value = ClockSnapshot(
      _liveMillis(chess.Color.WHITE),
      _liveMillis(chess.Color.BLACK),
    );
  }

  void _updateScreenWakeLock([AppLifecycleState? lifecycleState]) {
    final foreground =
        (lifecycleState ?? WidgetsBinding.instance.lifecycleState) ==
        AppLifecycleState.resumed;
    final enabled = foreground && _started && !_gameFinished;
    if (_screenWakeLockEnabled == enabled) return;
    _screenWakeLockEnabled = enabled;
    unawaited(
      maiaEngineChannel
          .invokeMethod<void>('setKeepScreenOn', {'enabled': enabled})
          .catchError(
            (Object error, StackTrace stackTrace) =>
                AppDiagnostics.record('screen-wake-lock', error, stackTrace),
          ),
    );
  }

  void _startGame({bool archiveCurrent = true}) {
    if (_useChessnutGo && !_chessnutStartPositionReady) {
      final message = !_chessnutReady
          ? 'Connect Chessnut Go before starting.'
          : 'Set up the standard starting position on Chessnut Go.';
      setState(() => _chessnutMessage = message);
      final observed = _chessnutPosition;
      if (_chessnutReady && observed != null) {
        unawaited(
          _setChessnutLeds(
            ChessnutProtocol.mismatchSquares(
              observed,
              ChessnutProtocol.pieceMapFromFen(chess.Chess.DEFAULT_POSITION),
            ),
          ),
        );
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    _pauseGame();
    if (archiveCurrent) {
      unawaited(_saveGameState());
      unawaited(ActiveSessionStore.startNew());
    }
    _gameGeneration++;
    _gameInferenceScope.invalidate();
    _clockTimer?.cancel();
    _stopChessnutLedRefresh();
    final randomWhite = Random().nextBool();
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
      _reviewVariationSnapshot = null;
      _forcedResult = null;
      _naturalGameOver = false;
      _engineThinking = false;
      _maiaFailed = false;
      _clockPaused = false;
      _boardFlipped = false;
      _resultDialogShown = false;
      _savedAsIncomplete = false;
      _viewedPly = null;
      _chessnutGameActive = _useChessnutGo;
      _pendingPhysicalMaiaMove = null;
      _chessnutTakebackRestoreActive = false;
      _lastChessnutIllegalPosition = null;
      _started = true;
      final startingMillis = _baseMinutes * 60 * 1000;
      _whiteMillis = startingMillis;
      _blackMillis = startingMillis;
      _turnStartedAt = _clockEnabled
          ? ((widget.clockFactory?.call() ?? Stopwatch())..start())
          : null;
      _clockHistory
        ..clear()
        ..add(ClockSnapshot(_whiteMillis, _blackMillis));
      _status = _chessnutGameActive
          ? (_isPlayerTurn ? 'Your move on Chessnut Go.' : 'Maia is thinking…')
          : (_isPlayerTurn ? 'Your move.' : 'Game in progress.');
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
    _syncGameBoard(animate: false, resetPremove: true);
    if (_clockEnabled) {
      _clockTimer = Timer.periodic(
        const Duration(milliseconds: 200),
        (_) => _tickClock(),
      );
    }
    if (!_isPlayerTurn) unawaited(_playMaiaMove());
    unawaited(_saveGameState());
  }

  int _liveMillis(chess.Color color) {
    final base = color == chess.Color.WHITE ? _whiteMillis : _blackMillis;
    if (!_clockEnabled ||
        _clockPaused ||
        _gameFinished ||
        _game.turn != color) {
      return base;
    }
    final started = _turnStartedAt;
    if (started == null) return base;
    return max(0, base - started.elapsedMilliseconds);
  }

  bool _commitClock(chess.Color mover) {
    if (_clockPaused) return false;
    if (!_clockEnabled) return true;
    if (_liveMillis(mover) <= 0) {
      _tickClock();
      return false;
    }
    final remaining = _liveMillis(mover) + _incrementSeconds * 1000;
    if (mover == chess.Color.WHITE) {
      _whiteMillis = remaining;
    } else {
      _blackMillis = remaining;
    }
    _turnStartedAt = (widget.clockFactory?.call() ?? Stopwatch())..start();
    return true;
  }

  void _recordClockSnapshot() {
    _clockHistory.add(ClockSnapshot(_whiteMillis, _blackMillis));
  }

  void _tickClock() {
    if (!mounted ||
        !_started ||
        !_clockEnabled ||
        _clockPaused ||
        _gameFinished) {
      return;
    }
    final remaining = _liveMillis(_game.turn);
    if (remaining <= 0) {
      final whiteFlagged = _game.turn == chess.Color.WHITE;
      final result = whiteFlagged ? '0-1' : '1-0';
      _gameGeneration++;
      _gameInferenceScope.invalidate();
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
      _syncGameBoard(animate: false, resetPremove: true);
      unawaited(_saveGameState());
      _scheduleGameConclusion();
      return;
    }
    _publishClock();
  }

  Future<void> _onGameBoardMove(dc.Move move, {bool? viaDragAndDrop}) async {
    if (!_started ||
        _gameFinished ||
        _engineThinking ||
        !_isPlayerTurn ||
        !_isViewingLivePosition ||
        _chessnutGameActive) {
      return;
    }
    await _commitHumanMove(move.uci);
  }

  Future<void> _commitHumanMove(String uci, {bool fromChessnut = false}) async {
    if (!_started ||
        _gameFinished ||
        _engineThinking ||
        !_isPlayerTurn ||
        !_isViewingLivePosition ||
        (fromChessnut && (!_chessnutGameActive || !_chessnutReady))) {
      return;
    }
    final chosen = _game
        .moves({'asObjects': true})
        .cast<chess.Move>()
        .where((candidate) => MaiaEncoding.uci(candidate) == uci)
        .firstOrNull;
    if (chosen == null) return;

    if (!_commitClock(_playerColor)) return;
    _uciMoves.add(uci);
    _game.move(chosen);
    _positionHistory.add(_game.fen);
    _recordClockSnapshot();
    if (_game.in_check) await _beepChessnut();
    setState(() {
      _status = _game.game_over
          ? _finishNaturalGame()
          : _chessnutGameActive
          ? 'Maia is thinking…'
          : 'Game in progress.';
    });
    _syncGameBoard();
    unawaited(_saveGameState());
    if (_game.game_over) {
      if (_chessnutGameActive) unawaited(_setChessnutLeds(const []));
      _scheduleGameConclusion();
    } else {
      unawaited(_playMaiaMove());
    }
  }

  Future<bool> _playQueuedPremove() async {
    if (_chessnutGameActive) return false;
    final move = _gameBoardController.premove;
    _gameBoardController.premove = null;
    if (move is! dc.NormalMove || !_isPlayerTurn || _gameFinished) {
      return false;
    }
    final chosen = _game
        .moves({'asObjects': true})
        .cast<chess.Move>()
        .where((candidate) => MaiaEncoding.uci(candidate) == move.uci)
        .firstOrNull;
    if (chosen == null) return false;
    if (!_commitClock(_playerColor)) return false;
    _uciMoves.add(move.uci);
    _game.move(chosen);
    _positionHistory.add(_game.fen);
    _recordClockSnapshot();
    _syncGameBoard();
    return true;
  }

  Future<void> _playMaiaMove() async {
    if (_gameFinished ||
        _isPlayerTurn ||
        _clockPaused ||
        _reviewOpen ||
        _engineThinking) {
      return;
    }
    if (_chessnutGameActive && !_chessnutReady) {
      if (mounted) {
        setState(() => _status = 'Reconnect Chessnut Go to continue.');
      }
      return;
    }
    final generation = _gameGeneration;
    final thinkingTimer = (widget.clockFactory?.call() ?? Stopwatch())..start();
    setState(() {
      _engineThinking = true;
      _maiaFailed = false;
    });
    try {
      final tokens = MaiaEncoding.historicalTokens(_positionHistory);
      final response = widget.maiaEvaluator != null
          ? await widget.maiaEvaluator!(
              List.unmodifiable(_positionHistory),
              _elo,
            )
          : await MaiaInferenceQueue.predict({
              'tokens': tokens,
              'selfElo': _elo,
              'opponentElo': _elo,
            }, replaceableScope: _gameInferenceScope);
      if (!mounted || generation != _gameGeneration || _gameFinished) return;
      if (response == null || response.length != 4352) {
        throw StateError('Maia returned an invalid policy vector.');
      }
      final logits = response.toList(growable: false);
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
      if (!_commitClock(_game.turn)) return;
      final maiaUci = MaiaEncoding.uci(move);
      _uciMoves.add(maiaUci);
      _game.move(move);
      _positionHistory.add(_game.fen);
      _recordClockSnapshot();
      _syncGameBoard();
      final naturalResult = _game.game_over ? _finishNaturalGame() : null;
      if (_chessnutGameActive) {
        if (_game.in_check) await _beepChessnut();
        setState(() {
          _engineThinking = false;
          _pendingPhysicalMaiaMove = maiaUci;
          _status = 'Make Maia’s lit move on Chessnut Go.';
        });
        await _setChessnutLeds([
          maiaUci.substring(0, 2),
          maiaUci.substring(2, 4),
        ]);
        if (!mounted || generation != _gameGeneration) return;
        _startChessnutLedRefresh();
        if (!mounted || generation != _gameGeneration) return;
        unawaited(_saveGameState());
        final observed = _chessnutPosition;
        if (observed != null) _queueChessnutPosition(observed);
        return;
      }
      final premovePlayed = await _playQueuedPremove();
      if (!mounted || generation != _gameGeneration) return;
      setState(() {
        _engineThinking = false;
        _status =
            naturalResult ??
            (premovePlayed ? 'Game in progress.' : 'Your move.');
      });
      unawaited(_saveGameState());
      if (_game.game_over) _scheduleGameConclusion();
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
        _maiaFailed = true;
        _status = 'Maia error. Please retry.';
      });
      _pauseGame();
      unawaited(_saveGameState());
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
    _gameInferenceScope.invalidate();
    _clockTimer?.cancel();
    _stopChessnutLedRefresh();
    setState(() {
      _forcedResult = result;
      _game.set_header(['Result', result, 'Termination', 'Player resigned']);
      _status = 'You resigned — Maia wins.';
    });
    _syncGameBoard(animate: false, resetPremove: true);
    if (_chessnutGameActive) unawaited(_setChessnutLeds(const []));
    unawaited(_saveGameState());
    _scheduleGameConclusion();
  }

  Future<void> _goHome() async {
    _pauseGame();
    _savedAsIncomplete = !_gameFinished;
    final snapshot = _gameSnapshot();
    await ActiveSessionStore.save(snapshot);
    await ActiveSessionStore.clear();
    if (!mounted) return;
    _gameGeneration++;
    _gameInferenceScope.invalidate();
    _clockTimer?.cancel();
    _stopChessnutLedRefresh();
    if (_chessnutGameActive) await _setChessnutLeds(const []);
    setState(() {
      _started = false;
      _engineThinking = false;
      _chessnutGameActive = false;
      _pendingPhysicalMaiaMove = null;
      _chessnutTakebackRestoreActive = false;
      _lastChessnutIllegalPosition = null;
      _status = 'Choose your settings and start a game.';
    });
    _syncGameBoard(animate: false, resetPremove: true);
  }

  Future<bool> _confirmEraseCurrentGame() async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Leave current game?'),
          content: const Text('Your game will be kept in Recent games.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _requestHome() async {
    if (!await _confirmEraseCurrentGame() || !mounted) return;
    await _goHome();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _requestNewGame() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Reset game?'),
            content: const Text('This game will be permanently erased.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Reset'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    _pauseGame();
    await ActiveSessionStore.discardActive();
    if (!mounted) return;
    if (_chessnutGameActive) {
      _stopChessnutLedRefresh();
      await _setChessnutLeds(const []);
      setState(() {
        _started = false;
        _engineThinking = false;
        _chessnutGameActive = false;
        _pendingPhysicalMaiaMove = null;
        _chessnutTakebackRestoreActive = false;
        _lastChessnutIllegalPosition = null;
        _status = 'Choose your settings and start a game.';
      });
      _syncGameBoard(animate: false, resetPremove: true);
      final position = _chessnutPosition;
      if (position != null) _queueChessnutPosition(position);
      return;
    }
    _startGame(archiveCurrent: false);
  }

  Future<void> _takeBack() async {
    if (!_started || !_canTakeBack) return;
    final chessnutTakeback = _chessnutGameActive;
    final observed = _chessnutPosition;
    _gameGeneration++;
    _gameInferenceScope.invalidate();
    if (chessnutTakeback) _stopChessnutLedRefresh();
    final plies = chessnutTakeback
        ? (_engineThinking ? 1 : min(2, _uciMoves.length))
        : !_isPlayerTurn
        ? 1
        : min(2, _uciMoves.length);
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
      _turnStartedAt = _clockEnabled
          ? ((widget.clockFactory?.call() ?? Stopwatch())..start())
          : null;
      _engineThinking = false;
      _forcedResult = null;
      _viewedPly = null;
      _game.set_header(['Result', '*']);
      _clockPaused = false;
      _maiaFailed = false;
      _pendingPhysicalMaiaMove = null;
      _chessnutTakebackRestoreActive = chessnutTakeback;
      _lastChessnutIllegalPosition = null;
      _status = chessnutTakeback
          ? 'Takeback: restore the lit squares on Chessnut Go.'
          : 'Move taken back. Your move.';
    });
    _syncGameBoard(animate: false, resetPremove: true);
    if (_clockEnabled) {
      _clockTimer?.cancel();
      _clockTimer = Timer.periodic(
        const Duration(milliseconds: 200),
        (_) => _tickClock(),
      );
    }
    if (chessnutTakeback) {
      final target = ChessnutProtocol.pieceMapFromFen(_game.fen);
      final mismatch = observed == null
          ? target.keys.toList(growable: false)
          : ChessnutProtocol.mismatchSquares(observed, target);
      await _setChessnutLeds(mismatch);
      if (!mounted) return;
      if (mismatch.isEmpty) {
        setState(() {
          _chessnutTakebackRestoreActive = false;
          _status = _isPlayerTurn
              ? 'Takeback complete. Your move on Chessnut Go.'
              : 'Takeback complete. Maia is thinking…';
        });
        if (!_isPlayerTurn && !_engineThinking) unawaited(_playMaiaMove());
      } else {
        _startChessnutLedRefresh();
      }
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

  Future<void> _copyCurrentFen() async {
    await Clipboard.setData(ClipboardData(text: _game.fen));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('FEN copied')));
    }
  }

  Future<void> _showGameMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(CupertinoIcons.arrow_2_squarepath),
              title: const Text('Flip board'),
              onTap: () => Navigator.pop(context, 'flip'),
            ),
            ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text('Analysis Board'),
              onTap: () => Navigator.pop(context, 'analysis'),
            ),
            ListTile(
              enabled: !_gameFinished && !_engineThinking,
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Resign'),
              onTap: !_gameFinished && !_engineThinking
                  ? () => Navigator.pop(context, 'resign')
                  : null,
            ),
            ListTile(
              enabled: _canTakeBack,
              leading: const Icon(CupertinoIcons.arrow_uturn_left),
              title: const Text('Take back move'),
              onTap: _canTakeBack
                  ? () => Navigator.pop(context, 'takeback')
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Reset game'),
              onTap: () => Navigator.pop(context, 'new'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'flip':
        setState(() => _boardFlipped = !_boardFlipped);
        unawaited(_saveGameState());
      case 'analysis':
        await _analyzeGame();
      case 'resign':
        await _resign();
      case 'takeback':
        await _takeBack();
      case 'new':
        await _requestNewGame();
    }
  }

  void _scheduleGameConclusion() {
    if (!_gameFinished || _resultDialogShown) return;
    _resultDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _gameFinished) unawaited(_showGameConclusion());
    });
  }

  Future<void> _showGameConclusion() async {
    final result = _forcedResult ?? _game.header['Result']?.toString() ?? '*';
    final title = switch (result) {
      '1-0' => 'White is victorious',
      '0-1' => 'Black is victorious',
      _ => 'The game is a draw',
    };
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        key: const ValueKey('game-conclusion-dialog'),
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'analysis'),
            child: const Text('Analysis Board'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'rematch'),
            child: const Text('Rematch'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'rematch') {
      if (_chessnutGameActive) {
        await _goHome();
        final position = _chessnutPosition;
        if (position != null) _queueChessnutPosition(position);
      } else {
        _startGame();
      }
    } else if (action == 'analysis') {
      await _analyzeGame();
    }
  }

  Future<void> _analyzeGame() async {
    _pauseGame();
    _reviewOpen = true;
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
      PgnVariationExporter.parseTree(session.pgn),
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
          title: 'Analysis Board',
          returnToGame: !_gameFinished,
          onSessionChanged: (fen, flipped, variations) =>
              _handleReviewSessionChanged(
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
    _resumeGame();
    unawaited(_saveGameState());
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
        automaticallyImplyLeading: false,
        leading: _started
            ? IconButton(
                key: const ValueKey('game-home-button'),
                onPressed: _requestHome,
                icon: const Icon(Icons.home_outlined),
                tooltip: 'Home',
              )
            : null,
        title: Text(_started ? '' : 'Mobile Maia Preview'),
        actions: [
          if (!_started)
            IconButton(
              onPressed: _showAbout,
              icon: const Icon(Icons.info_outline),
              tooltip: 'About',
            ),
          if (_started) ...[
            if (_chessnutGameActive)
              IconButton(
                key: const ValueKey('chessnut-status-button'),
                onPressed: _showChessnutPanel,
                icon: Icon(
                  _chessnutReady
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                ),
                tooltip: 'Chessnut Go status',
              ),
            IconButton(
              key: const ValueKey('new-game-button'),
              onPressed: _requestNewGame,
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset game',
            ),
            PopupMenuButton<String>(
              key: const ValueKey('game-share-menu'),
              tooltip: 'Share and export',
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == 'pgn') await _copyPgn();
                if (value == 'fen') await _copyCurrentFen();
                if (value == 'save') {
                  if (context.mounted) {
                    await PgnFiles.export(context, _exportPgn());
                  }
                }
                if (value == 'share') {
                  if (context.mounted) {
                    await PgnFiles.export(context, _exportPgn(), share: true);
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'save',
                  child: ListTile(
                    leading: Icon(Icons.save_alt),
                    title: Text('Save PGN file'),
                  ),
                ),
                PopupMenuItem(
                  value: 'share',
                  child: ListTile(
                    leading: Icon(Icons.share_outlined),
                    title: Text('Share PGN'),
                  ),
                ),
                PopupMenuItem(
                  value: 'pgn',
                  child: ListTile(
                    leading: Icon(Icons.description_outlined),
                    title: Text('Copy PGN'),
                  ),
                ),
                PopupMenuItem(
                  value: 'fen',
                  child: ListTile(
                    leading: Icon(Icons.content_copy),
                    title: Text('Copy FEN'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (!_started) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: _setupCard(),
                  ),
                ),
              );
            }

            if (constraints.maxWidth > constraints.maxHeight &&
                constraints.maxWidth >= 600) {
              final rowHeight = max(
                44.0,
                MediaQuery.textScalerOf(context).scale(20) + 20,
              );
              final size = min(
                constraints.maxHeight - 16 - rowHeight * 2,
                constraints.maxWidth * 0.5,
              ).clamp(80.0, 560.0);
              return Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    SizedBox(
                      width: max(size, 240.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: rowHeight,
                            child: _playerInfoRow(
                              _topBoardColor,
                              _playerLabel(_topBoardColor),
                            ),
                          ),
                          SizedBox(width: size, height: size, child: _board()),
                          SizedBox(
                            height: rowHeight,
                            child: _playerInfoRow(
                              _bottomBoardColor,
                              _playerLabel(_bottomBoardColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          _liveMoveStrip(),
                          if (_chessnutGameActive) ...[
                            const SizedBox(height: 6),
                            _chessnutStatusBanner(),
                          ],
                          const Spacer(),
                          if (_maiaFailed)
                            TextButton(
                              onPressed: () {
                                _maiaFailed = false;
                                _resumeGame();
                              },
                              child: const Text('Maia error. Retry'),
                            )
                          else if (_engineThinking)
                            const Text('Maia is thinking…'),
                          _liveGameControls(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            final contentWidth = min(
              max(0.0, constraints.maxWidth - 24),
              560.0,
            );
            final contentHeight = max(0.0, constraints.maxHeight - 16);
            // Keep the live board fixed while moves alone scroll horizontally.
            final boardSize = min(
              contentWidth,
              max(
                0.0,
                contentHeight -
                    (_maiaFailed ? 268 : 244) -
                    (_chessnutGameActive ? 38 : 0),
              ),
            );
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Center(
                child: SizedBox(
                  width: contentWidth,
                  height: contentHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _liveMoveStrip(),
                      if (_chessnutGameActive) ...[
                        const SizedBox(height: 6),
                        _chessnutStatusBanner(),
                      ],
                      const SizedBox(height: 6),
                      _playerInfoRow(
                        _topBoardColor,
                        _playerLabel(_topBoardColor),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: SizedBox(
                          width: boardSize,
                          height: boardSize,
                          child: _board(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _playerInfoRow(
                        _bottomBoardColor,
                        _playerLabel(_bottomBoardColor),
                      ),
                      const Spacer(),
                      if (_maiaFailed)
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Maia error. Please retry.',
                                maxLines: 1,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                _maiaFailed = false;
                                _resumeGame();
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        )
                      else if (_engineThinking)
                        const Text(
                          'Maia is thinking…',
                          textAlign: TextAlign.center,
                        ),
                      _liveGameControls(),
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
              onChanged: (value) =>
                  _changePlayElo(value.round(), persist: false),
              onChangeEnd: (value) =>
                  _changePlayElo(value.round(), persist: true),
            ),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => _changePlayElo(800, persist: true),
                  child: const Text('Easy 800'),
                ),
                TextButton(
                  onPressed: () => _changePlayElo(1500, persist: true),
                  child: const Text('Medium 1500'),
                ),
                TextButton(
                  onPressed: () => _changePlayElo(2200, persist: true),
                  child: const Text('Hard 2200'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TimePreset>(
              isExpanded: true,
              initialValue: _timePreset,
              decoration: const InputDecoration(
                labelText: 'Time control',
                border: OutlineInputBorder(),
              ),
              items: TimePreset.values
                  .map(
                    (preset) => DropdownMenuItem(
                      value: preset,
                      child: Text(
                        preset.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _useChessnutGo
                  ? null
                  : (value) {
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
              onExpansionChanged: (expanded) =>
                  setState(() => _advancedExpanded = expanded),
              title: Row(
                children: [
                  const Expanded(child: Text('Advanced')),
                  if (_advancedExpanded)
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
            const SizedBox(height: 8),
            SwitchListTile(
              key: const ValueKey('chessnut-go-toggle'),
              contentPadding: EdgeInsets.zero,
              value: _useChessnutGo,
              title: const Text('Chessnut Go (experimental)'),
              subtitle: const Text(
                'Enter moves on the physical board and follow Maia’s LEDs.',
              ),
              onChanged: (value) => unawaited(_setUseChessnutGo(value)),
            ),
            if (_useChessnutGo) ...[
              SwitchListTile(
                key: const ValueKey('chessnut-sounds-toggle'),
                contentPadding: EdgeInsets.zero,
                value: _chessnutSoundsEnabled,
                title: const Text('Board sounds'),
                subtitle: const Text(
                  'Beep for check, checkmate, and completed illegal moves.',
                ),
                onChanged: (value) =>
                    unawaited(_setChessnutSoundsEnabled(value)),
              ),
              Container(
                key: const ValueKey('chessnut-setup-status'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _chessnutReady
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth_searching,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_chessnutMessage)),
                    if (_chessnutBatteryPercent != null)
                      Text(
                        '$_chessnutBatteryPercent%${_chessnutCharging ? ' ⚡' : ''}',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _chessnutReady
                    ? _disconnectChessnut
                    : _connectChessnut,
                icon: Icon(
                  _chessnutReady ? Icons.bluetooth_disabled : Icons.bluetooth,
                ),
                label: Text(
                  _chessnutReady ? 'Disconnect' : 'Connect Chessnut Go',
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'The first preview supports standard-position, unlimited games only.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed:
                  (_initialized || widget.startingFen != null) &&
                      (!_useChessnutGo || _chessnutStartPositionReady)
                  ? _startGame
                  : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start game'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _initialized ? _openAnalysisBoard : null,
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('Analysis Board'),
            ),
            TextButton.icon(
              onPressed: _showRecentGames,
              icon: const Icon(Icons.history),
              label: const Text('Recent games'),
            ),
            TextButton.icon(
              onPressed: _openPgnFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Open PGN file'),
            ),
          ],
        ),
      ),
    );
  }

  String _playerLabel(chess.Color color) =>
      color == _playerColor ? 'You' : 'Maia3 ${_elo}elo';

  Widget _liveMoveStrip() {
    final moves = _liveSanMoves;
    final children = <Widget>[];
    for (var index = 0; index < moves.length; index++) {
      final root = _positionHistory.first.split(' ');
      final absolute =
          ((int.tryParse(root[5]) ?? 1) - 1) * 2 +
          (root[1] == 'b' ? 1 : 0) +
          index;
      if (index == 0 || absolute.isEven) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 4),
            child: Text(
              '${absolute ~/ 2 + 1}${absolute.isOdd ? '...' : '.'}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        );
      }
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            moves[index],
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
    return Container(
      key: const ValueKey('live-move-strip'),
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.centerLeft,
      child: moves.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Game ready',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : SingleChildScrollView(
              key: const ValueKey('live-move-scroll'),
              controller: _liveMovesController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 12),
              child: Row(children: children),
            ),
    );
  }

  Widget _liveGameControls() => SizedBox(
    key: const ValueKey('live-game-controls'),
    height: 52,
    child: Row(
      children: [
        Expanded(
          child: Center(
            child: IconButton(
              key: const ValueKey('game-actions-menu'),
              onPressed: _showGameMenu,
              icon: const Icon(Icons.menu),
              tooltip: 'Game menu',
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: IconButton(
              key: const ValueKey('quick-resign-button'),
              onPressed: !_gameFinished && !_engineThinking ? _resign : null,
              icon: const Icon(CupertinoIcons.flag),
              tooltip: 'Resign',
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: IconButton(
              key: const ValueKey('game-previous-move-button'),
              onPressed: _displayPly == 0 ? null : () => _stepGameHistory(-1),
              icon: const Icon(CupertinoIcons.chevron_back),
              tooltip: 'Previous move',
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: IconButton(
              key: const ValueKey('game-next-move-button'),
              onPressed: _isViewingLivePosition
                  ? null
                  : () => _stepGameHistory(1),
              icon: const Icon(CupertinoIcons.chevron_forward),
              tooltip: 'Next move',
            ),
          ),
        ),
      ],
    ),
  );

  Widget _playerInfoRow(chess.Color color, String label) {
    return SizedBox(
      height: max(
        _clockEnabled ? 44.0 : 24.0,
        MediaQuery.textScalerOf(context).scale(_clockEnabled ? 20 : 14) + 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                MaterialDifference(fen: _game.fen, side: color),
              ],
            ),
          ),
          if (_clockEnabled) _clockTile(color),
        ],
      ),
    );
  }

  Widget _clockTile(chess.Color color) {
    return ValueListenableBuilder<ClockSnapshot>(
      valueListenable: _clockDisplay,
      builder: (context, clock, _) {
        final milliseconds = color == chess.Color.WHITE
            ? clock.whiteMillis
            : clock.blackMillis;
        final urgent = milliseconds < 10000;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _game.turn == color && !_gameFinished
                ? const Color(0xfff0f0f0)
                : const Color(0xff343735),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            _formatClock(milliseconds),
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
        );
      },
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
    return LayoutBuilder(
      builder: (context, constraints) => cg.Chessboard(
        key: const ValueKey('game-board'),
        size: constraints.biggest.shortestSide,
        orientation: _boardOrientation,
        controller: _gameBoardController,
        onMove: _onGameBoardMove,
        settings: mobileMaiaInteractiveBoardSettings,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    _stopChessnutLedRefresh();
    _gameInferenceScope.invalidate();
    _started = false;
    _updateScreenWakeLock(AppLifecycleState.detached);
    _clockDisplay.dispose();
    _liveMovesController.dispose();
    unawaited(_chessnutSubscription?.cancel());
    _gameBoardController.dispose();
    super.dispose();
  }
}

part of '../main.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({
    required this.positions,
    required this.uciMoves,
    required this.sanMoves,
    required this.playerIsWhite,
    required this.pgn,
    this.initialVariations = const [],
    this.initialTreeIsAuthoritative = false,
    this.maiaElo = 1600,
    required this.onHome,
    this.returnToGame = false,
    this.evaluator,
    this.maiaEvaluator,
    this.classifier,
    this.title = 'Game review',
    this.onLoadFen,
    this.onLoadPgn,
    this.onLoadPgnFile,
    this.onClearMoves,
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
  final bool initialTreeIsAuthoritative;
  final int maiaElo;
  final FutureOr<void> Function() onHome;
  final bool returnToGame;
  final Future<StockfishReview> Function(String fen)? evaluator;
  final Future<String?> Function(List<String> positions, int elo)?
  maiaEvaluator;
  final MoveClassificationRunner? classifier;
  final String title;
  final Future<void> Function()? onLoadFen;
  final Future<void> Function()? onLoadPgn;
  final Future<void> Function()? onLoadPgnFile;
  final Future<void> Function()? onClearMoves;
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

class _ReviewPageState extends State<ReviewPage>
    with WidgetsBindingObserver, RouteAware {
  int _ply = 0;
  bool _showGraph = false;
  bool _engineEnabled = true;
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
  final Map<String, StockfishReview> _variationReviewCache = {};
  final Map<String, Future<StockfishReview>> _pendingVariationReviews = {};
  final Map<String, String> _variationMaiaCache = {};
  final Map<String, Future<String?>> _pendingVariationMaia = {};
  bool _sessionNotificationScheduled = false;
  final Set<String> _collapsedVariationKeys = {};
  final MaiaInferenceScope _maiaInferenceScope = MaiaInferenceScope();
  final MaiaInferenceScope _stockfishScope = MaiaInferenceScope();
  final MaiaInferenceScope _batchScope = MaiaInferenceScope();
  bool _foreground = true;
  bool _routeVisible = true;
  bool _appForeground = true;
  Timer? _refinementTimer;

  void _cancelSelectedWork() {
    _refinementTimer?.cancel();
    StockfishAnalyzer.instance.cancel(_stockfishScope);
    _maiaInferenceScope.invalidate();
    // A revisit must enqueue fresh work instead of reusing a cancelled future.
    if (widget.evaluator == null) {
      _pendingAnalyses.clear();
      _pendingVariationReviews.clear();
      _loading.clear();
    }
    if (widget.maiaEvaluator == null) {
      _pendingVariationMaia.clear();
      _maiaLoading.clear();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) maiaRouteObserver.subscribe(this, route);
  }

  @override
  void didPushNext() {
    _routeVisible = false;
    _updateAnalysisActivity();
  }

  @override
  void didPopNext() {
    _routeVisible = true;
    _updateAnalysisActivity();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appForeground = state == AppLifecycleState.resumed;
    _updateAnalysisActivity();
  }

  void _updateAnalysisActivity() {
    _foreground = _appForeground && _routeVisible;
    if (!_foreground) {
      _cancelSelectedWork();
      StockfishAnalyzer.instance.cancel(_batchScope);
      _fullAnalysisGeneration++;
      _fullAnalysisRunning = false;
      _fullAnalysisClassifying = false;
    } else if (_engineEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_inVariation) {
          unawaited(_analyzeVariation());
        } else {
          unawaited(_analyzePosition(_ply));
          unawaited(_analyzeMaiaPosition(_ply));
        }
        setState(() {});
      });
    }
  }

  Future<StockfishReview> _evaluateSelected(String fen) {
    if (!_foreground || !_engineEnabled) throw const AnalysisCancelled();
    return widget.evaluator?.call(fen) ??
        StockfishAnalyzer.instance.evaluate(fen, scope: _stockfishScope);
  }

  void _refineSelected(String fen) {
    if (widget.evaluator != null) return;
    _refinementTimer?.cancel();
    _refinementTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted || !_foreground || !_engineEnabled || _currentFen != fen) {
        return;
      }
      try {
        final score = await StockfishAnalyzer.instance.evaluate(
          fen,
          scope: _stockfishScope,
          background: true,
        );
        if (!mounted || !_foreground || !_engineEnabled || _currentFen != fen) {
          return;
        }
        setState(() {
          if (_inVariation) {
            _variationReview = score;
            _variationReviewCache[fen] = score;
          } else {
            _reviews[_ply] = score;
          }
        });
      } on AnalysisCancelled {
        /* Navigation takes priority. */
      } catch (error, stack) {
        unawaited(AppDiagnostics.record('stockfish-refine', error, stack));
      }
    });
  }

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
      ? _variations.where((variation) => variation.basePly == 0).firstOrNull
      : widget.onSessionChanged != null
      ? _variations.where((variation) => variation.basePly == 0).firstOrNull
      : null;

  final Expando<ComputerAnalysisLine> _lineCache = Expando();

  ComputerAnalysisLine _replayLine(RecordedVariation line) {
    final cached = _lineCache[line];
    if (cached != null) return cached;
    final game = chess.Chess.fromFEN(line.baseFen);
    final positions = <String>[game.fen];
    final moves = <String>[];
    for (final san in line.sanMoves) {
      if (!game.move(san)) {
        throw FormatException('Illegal variation move: $san');
      }
      moves.add(MaiaEncoding.uci(game.history.last.move));
      positions.add(game.fen);
    }
    return _lineCache[line] = ComputerAnalysisLine(
      positions: List.unmodifiable(positions),
      uciMoves: List.unmodifiable(moves),
    );
  }

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
    return _replayLine(rootMainline);
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
    WidgetsBinding.instance.addObserver(this);
    _flipped = widget.initialFlipped;
    _variations = List.of(widget.initialVariations);
    if (widget.onSessionChanged != null &&
        !widget.initialTreeIsAuthoritative &&
        widget.sanMoves.isNotEmpty) {
      bool sameLine(RecordedVariation line) =>
          line.basePly == 0 && _sameMoves(line.sanMoves, widget.sanMoves);
      final parsed = PgnVariationExporter.parseTree(widget.pgn);
      if (parsed.isNotEmpty && sameLine(parsed.first)) {
        // The complete seed PGN includes its comments and imported variations.
        _variations
          ..clear()
          ..addAll(parsed);
        for (final line in widget.initialVariations) {
          if (!sameLine(line) &&
              !_variations.any(
                (v) =>
                    v.basePly == line.basePly &&
                    _sameMoves(v.sanMoves, line.sanMoves),
              )) {
            if (line.basePly == 0) {
              _variations.add(line);
            } else if (!_variations.first.children.any(
              (v) =>
                  v.basePly == line.basePly &&
                  _sameMoves(v.sanMoves, line.sanMoves),
            )) {
              final root = _variations.first;
              _variations[0] = RecordedVariation(
                basePly: 0,
                baseFen: root.baseFen,
                sanMoves: root.sanMoves,
                annotations: root.annotations,
                children: [...root.children, line],
              );
            }
          }
        }
      } else if (!_variations.any(sameLine)) {
        final attached = _variations.where((line) => line.basePly > 0).toList();
        _variations.removeWhere((line) => line.basePly > 0);
        _variations.insert(
          0,
          RecordedVariation(
            basePly: 0,
            baseFen: widget.positions.first,
            sanMoves: widget.sanMoves,
            children: attached,
          ),
        );
      }
    }
    if (widget.onSessionChanged != null &&
        widget.initialTreeIsAuthoritative &&
        _variations.isEmpty) {
      _variations.add(
        RecordedVariation(
          basePly: 0,
          baseFen: widget.positions.first,
          sanMoves: const [],
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
    if (callback == null || _sessionNotificationScheduled) return;
    _sessionNotificationScheduled = true;
    // Persist the potentially large review tree only after Flutter has painted
    // the move. Game Review also derives export annotations here, so doing the
    // work synchronously made a played variation feel heavier than the same
    // move on a short Analysis Board session.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sessionNotificationScheduled = false;
      if (!mounted) return;
      unawaited(
        callback(_currentFen, _flipped, List.unmodifiable(_variations)),
      );
    });
  }

  @override
  void dispose() {
    maiaRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _refinementTimer?.cancel();
    StockfishAnalyzer.instance.cancel(_stockfishScope);
    StockfishAnalyzer.instance.cancel(_batchScope);
    _maiaInferenceScope.invalidate();
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

  static bool _sameMoves(List<String> a, List<String> b) =>
      a.length == b.length &&
      List.generate(a.length, (i) => a[i] == b[i]).every((v) => v);

  void _showMainPly(int ply) {
    _cancelSelectedWork();
    final root = _rootMainline;
    if (root != null) {
      _openVariation(root, ply);
      return;
    }

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
    _cancelSelectedWork();
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
    final selectedPly = _inVariation
        ? (_variationBasePly! + _variationIndex)
        : _ply;
    if (opened != null &&
        _variationIndex < opened.sanMoves.length &&
        opened.sanMoves[_variationIndex] == san) {
      _openVariation(opened, _variationIndex + 1);
      return;
    }
    final path = opened == null ? null : _pathToVariation(opened);
    final candidates = <RecordedVariation>[
      if (opened != null) ...opened.children,
      if (opened != null && _variationIndex == 0)
        ...(path != null && path.length > 1
            ? path[path.length - 2].children
            : _variations),
      if (opened == null) ..._variations,
    ];
    final existing = candidates
        .where(
          (line) =>
              line.basePly == selectedPly &&
              line.sanMoves.firstOrNull == san &&
              line.baseFen == fenBefore,
        )
        .firstOrNull;
    if (existing != null) {
      _openVariation(existing, 1);
      return;
    }
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
          annotations: opened.annotations,
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
      annotations: _openedVariation?.annotations ?? const [],
      children: _openedVariation?.children ?? const [],
    );
    if (opened != null) {
      _replaceVariation(_variations, opened, updated);
      _openedVariation = updated;
    } else {
      final rootMainline = _rootMainline;
      if (rootMainline != null && basePly > rootMainline.basePly) {
        final children = List<RecordedVariation>.of(rootMainline.children)
          ..removeWhere(
            (item) =>
                item.basePly == basePly &&
                item.sanMoves.isNotEmpty &&
                item.sanMoves.first == _variationSan.first,
          )
          ..add(updated);
        _replaceVariation(
          _variations,
          rootMainline,
          RecordedVariation(
            basePly: rootMainline.basePly,
            baseFen: rootMainline.baseFen,
            sanMoves: rootMainline.sanMoves,
            annotations: rootMainline.annotations,
            children: children,
          ),
        );
        _openedVariation = updated;
      } else {
        _variations.removeWhere(
          (item) =>
              item.basePly == basePly &&
              item.sanMoves.isNotEmpty &&
              item.sanMoves.first == _variationSan.first,
        );
        _variations.add(updated);
        // A line authored directly from the Analysis Board is still the
        // currently opened line. Without this reference, stepping backward
        // and playing a different move appends that move to the end of the
        // root SAN list, shifting White moves into Black's column instead of
        // creating a sibling variation at the selected ply.
        _openedVariation = updated;
      }
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
    if (!_engineEnabled || !_foreground) return;
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
      }, replaceableScope: _maiaInferenceScope);
      if (response == null || response.length != 4352) return;
      final game = chess.Chess.fromFEN(widget.positions[ply]);
      if (game.game_over) return;
      final move = MaiaEncoding.sampleLegalMove(
        game,
        game.moves({'asObjects': true}).cast<chess.Move>().toList(),
        response.toList(growable: false),
        temperature: 0,
      );
      if (mounted) setState(() => _maiaMoves[ply] = MaiaEncoding.uci(move));
    } catch (error, stackTrace) {
      unawaited(AppDiagnostics.record('maia-analysis', error, stackTrace));
    } finally {
      if (mounted) setState(() => _maiaLoading.remove(ply));
    }
  }

  Future<StockfishReview> _stockfishForVariation(String fen) {
    final cached = _variationReviewCache[fen];
    if (cached != null) return Future.value(cached);
    final pending = _pendingVariationReviews[fen];
    if (pending != null) return pending;
    final evaluate = _evaluateSelected;
    late Future<StockfishReview> operation;
    operation = evaluate(fen)
        .then((review) {
          _variationReviewCache[fen] = review;
          return review;
        })
        .whenComplete(() {
          if (identical(_pendingVariationReviews[fen], operation)) {
            _pendingVariationReviews.remove(fen);
          }
        });
    _pendingVariationReviews[fen] = operation;
    return operation;
  }

  List<RecordedVariation>? _pathToVariation(RecordedVariation target) {
    List<RecordedVariation>? visit(
      List<RecordedVariation> lines,
      List<RecordedVariation> ancestors,
    ) {
      for (final line in lines) {
        final path = [...ancestors, line];
        if (identical(line, target)) return path;
        final nested = visit(line.children, path);
        if (nested != null) return nested;
      }
      return null;
    }

    return visit(_variations, const []);
  }

  List<String> _variationHistory() {
    final target = _openedVariation;
    final path = target == null ? null : _pathToVariation(target);
    if (path == null || path.isEmpty) {
      return [
        ...widget.positions.take((_variationBasePly ?? 0) + 1),
        ..._variationPositions.skip(1).take(_variationIndex),
      ];
    }

    final first = path.first;
    final history = first.basePly == 0
        ? <String>[first.baseFen]
        : widget.positions.take(first.basePly + 1).toList();
    for (var depth = 0; depth < path.length - 1; depth++) {
      final line = path[depth];
      final next = path[depth + 1];
      final game = chess.Chess.fromFEN(line.baseFen);
      for (var offset = 0; offset < line.sanMoves.length; offset++) {
        if (!game.move(line.sanMoves[offset])) break;
        final plyAfterMove = line.basePly + offset + 1;
        if (plyAfterMove <= next.basePly) history.add(game.fen);
        if (plyAfterMove >= next.basePly) break;
      }
    }
    history.addAll(_variationPositions.skip(1).take(_variationIndex));
    return history;
  }

  String _variationHistoryKey(List<String> positions) => positions.join('\n');

  Future<String?> _maiaForVariation(List<String> positions, String fen) {
    final key = _variationHistoryKey(positions);
    final cached = _variationMaiaCache[key];
    if (cached != null) return Future.value(cached);
    final pending = _pendingVariationMaia[key];
    if (pending != null) return pending;
    late Future<String?> operation;
    operation = _runVariationMaia(positions, fen)
        .then((move) {
          if (move != null) _variationMaiaCache[key] = move;
          return move;
        })
        .whenComplete(() {
          if (identical(_pendingVariationMaia[key], operation)) {
            _pendingVariationMaia.remove(key);
          }
        });
    _pendingVariationMaia[key] = operation;
    return operation;
  }

  Future<String?> _runVariationMaia(List<String> positions, String fen) async {
    final injected = widget.maiaEvaluator;
    if (injected != null) return injected(positions, widget.maiaElo);
    if (widget.evaluator != null) return null;
    final response = await MaiaInferenceQueue.predict({
      'tokens': MaiaEncoding.historicalTokens(positions),
      'selfElo': widget.maiaElo,
      'opponentElo': widget.maiaElo,
    }, replaceableScope: _maiaInferenceScope);
    if (response == null || response.length != 4352) return null;
    final game = chess.Chess.fromFEN(fen);
    if (game.game_over) return null;
    final move = MaiaEncoding.sampleLegalMove(
      game,
      game.moves({'asObjects': true}).cast<chess.Move>().toList(),
      response.toList(growable: false),
      temperature: 0,
    );
    return MaiaEncoding.uci(move);
  }

  Future<void> _analyzeVariation() async {
    if (!_engineEnabled || !_foreground) return;
    final fen = _currentFen;
    final history = _variationHistory();
    final historyKey = _variationHistoryKey(history);
    final cachedReview = _variationReviewCache[fen];
    final cachedMaia = _variationMaiaCache[historyKey];
    setState(() {
      _variationReview = cachedReview;
      _variationMaiaMove = cachedMaia;
      _variationLoading = cachedReview == null;
      _variationMaiaLoading = false;
      _variationError = null;
    });
    try {
      final review = cachedReview ?? await _stockfishForVariation(fen);
      if (!mounted || fen != _currentFen) return;
      setState(() => _variationReview = review);
      _refineSelected(fen);
    } on AnalysisCancelled {
      return;
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
    if (cachedMaia != null ||
        !mounted ||
        !_foreground ||
        !_engineEnabled ||
        fen != _currentFen) {
      return;
    }
    if (mounted && fen == _currentFen) {
      setState(() => _variationMaiaLoading = true);
    }
    try {
      final move = await _maiaForVariation(history, fen);
      if (move != null && mounted && fen == _currentFen) {
        setState(() => _variationMaiaMove = move);
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
          annotations: current.annotations,
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
            annotations: current.annotations,
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
            if (identical(current, _rootMainline)) {
              lines[index] = RecordedVariation(
                basePly: 0,
                baseFen: current.baseFen,
                sanMoves: const [],
              );
            } else {
              lines.removeAt(index);
            }
          } else {
            final deletedPly = current.basePly + moveIndex - 1;
            replacement = RecordedVariation(
              basePly: current.basePly,
              baseFen: current.baseFen,
              sanMoves: List.unmodifiable(current.sanMoves.take(moveIndex - 1)),
              annotations: current.annotations.take(moveIndex - 1).toList(),
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
            annotations: current.annotations,
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
                annotations: parent.annotations.skip(offset).toList(),
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
            annotations: [
              for (var i = 0; i < offset; i++)
                i < parent.annotations.length
                    ? parent.annotations[i]
                    : <String, dynamic>{},
              ...target.annotations,
            ],
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
            annotations: parent.annotations,
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
    _cancelSelectedWork();
    final replay = _replayLine(variation);
    final positions = replay.positions;
    final uciMoves = replay.uciMoves;
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

    if (_variations.any(visit)) return;
    final mainIndex = widget.positions.indexOf(fen);
    if (mainIndex >= 0) {
      setState(() => _showMainPly(mainIndex));
      return;
    }
    final root = _rootMainline;
    if (root != null) _openVariation(root, 0);
  }

  Future<void> _analyzePosition(int ply) async {
    if (!_engineEnabled || !_foreground) return;
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
      final evaluate = _evaluateSelected;
      final review = await evaluate(widget.positions[ply]);
      if (mounted) {
        setState(() => _reviews[ply] = review);
        if (_currentFen == widget.positions[ply]) {
          _refineSelected(widget.positions[ply]);
        }
      }
    } on AnalysisCancelled {
      // Selected position changed.
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
    if (!_engineEnabled || !_foreground || _fullAnalysisRunning) return;
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
    final evaluate =
        widget.evaluator ??
        (String fen) => StockfishAnalyzer.instance.evaluate(
          fen,
          scope: _batchScope,
          background: true,
        );
    for (var i = 0; i < positions.length; i++) {
      if (!mounted || generation != _fullAnalysisGeneration) return;
      try {
        final matchesFixedMainline =
            i < widget.positions.length && positions[i] == widget.positions[i];
        if (matchesFixedMainline) {
          await _pendingAnalyses[i];
        }
        if (!mounted || generation != _fullAnalysisGeneration) return;
        final review = matchesFixedMainline && widget.evaluator != null
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
    if (scores.length != positions.length) {
      setState(() {
        _analysisError ??= 'Computer analysis did not complete. Try again.';
        _fullAnalysisRunning = false;
      });
      return;
    }

    // Stockfish's complete graph and accuracy are already useful. Publish
    // them immediately instead of making the user wait for the separate
    // annotation heuristic, which can take a few more seconds on a phone.
    setState(() {
      _analysisError = null;
      _graphScores = List.unmodifiable(scores);
      _graphPositions = List.unmodifiable(positions);
      _graphMoves = List.unmodifiable(line.uciMoves);
      _fullAnalysisClassifying = true;
    });
    try {
      final classify =
          widget.classifier ?? MoveClassifier.classifyOffMainIsolate;
      final classifications = await classify(
        scores: scores,
        positions: positions,
        uciMoves: line.uciMoves,
      );
      if (!mounted || generation != _fullAnalysisGeneration) return;
      setState(() => _graphClassifications = classifications);
    } catch (error, stackTrace) {
      if (!mounted || generation != _fullAnalysisGeneration) return;
      unawaited(
        AppDiagnostics.record('move-classification', error, stackTrace),
      );
      setState(() => _analysisError = 'Move classification failed: $error');
    }
    if (!mounted || generation != _fullAnalysisGeneration) return;
    setState(() {
      _fullAnalysisRunning = false;
      _fullAnalysisClassifying = false;
    });
  }

  void _cancelFullAnalysis() {
    if (!_fullAnalysisRunning) return;
    StockfishAnalyzer.instance.cancel(_batchScope);
    setState(() {
      _fullAnalysisGeneration++;
      _fullAnalysisRunning = false;
      _fullAnalysisClassifying = false;
      _analysisError = 'Computer analysis stopped.';
    });
  }

  Set<cg.Shape> get _arrows {
    if (!_engineEnabled) return const {};
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

  int get _selectedComputerAnalysisPly {
    if (!_inVariation) return _ply;
    if (identical(_openedVariation, _rootMainline)) return _variationIndex;
    // A side variation does not have a one-to-one graph position. Keep the
    // cursor at the branch point on the analysed root line.
    return _variationBasePly ?? 0;
  }

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
      height: max(26, MediaQuery.textScalerOf(context).scale(16) * 1.375),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: max(64, MediaQuery.textScalerOf(context).scale(52)),
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

  int _absolutePly(int relative) {
    final fields = widget.positions.first.split(' ');
    return (int.parse(fields[5]) - 1) * 2 +
        (fields[1] == 'b' ? 1 : 0) +
        relative;
  }

  Widget _variationLine(
    RecordedVariation variation, [
    int depth = 0,
  ]) => Container(
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
            for (var index = 0; index < variation.sanMoves.length; index++) ...[
              if (_absolutePly(variation.basePly + index).isEven)
                Text(
                  '${(_absolutePly(variation.basePly + index) ~/ 2) + 1}.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              else if (index == 0)
                Text(
                  '${(_absolutePly(variation.basePly + index) ~/ 2) + 1}...',
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
    final mainlineMoves = rootMainline?.sanMoves ?? widget.sanMoves;
    final variationsByBase = <int, List<RecordedVariation>>{};
    for (final variation in _variations) {
      if (identical(variation, rootMainline)) continue;
      variationsByBase.putIfAbsent(variation.basePly, () => []).add(variation);
    }
    final renderedVariations = <RecordedVariation>{};
    final rows = <Widget>[];
    final mainlineLength = rootMainline == null
        ? min(_maximumPly, mainlineMoves.length)
        : mainlineMoves.length;
    for (
      var whiteIndex = _absolutePly(0).isOdd ? -1 : 0;
      whiteIndex < mainlineLength;
      whiteIndex += 2
    ) {
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 34,
              child: Text(
                '${(_absolutePly(whiteIndex) ~/ 2) + 1}.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Expanded(
              child: whiteIndex < 0
                  ? const SizedBox.shrink()
                  : _mainlineNotationMove(
                      rootMainline: rootMainline,
                      moves: mainlineMoves,
                      index: whiteIndex,
                    ),
            ),
            Expanded(
              child: whiteIndex + 1 < mainlineLength
                  ? _mainlineNotationMove(
                      rootMainline: rootMainline,
                      moves: mainlineMoves,
                      index: whiteIndex + 1,
                    )
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

  Widget _mainlineNotationMove({
    required RecordedVariation? rootMainline,
    required List<String> moves,
    required int index,
  }) => _notationMove(
    key: ValueKey('mainline-move-$index'),
    san: moves[index],
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

  void _step(int delta) {
    _cancelSelectedWork();
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

  String _exportReviewPgn() => PgnVariationExporter.export(
    widget.pgn,
    _rootMainline == null ? widget.sanMoves : const [],
    _variations,
    mainPositions: _rootMainline == null ? widget.positions : null,
  );

  Future<void> _copyPgn() async {
    await Clipboard.setData(ClipboardData(text: _exportReviewPgn()));
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

  bool get _hasAnalysisMenu =>
      widget.onClearMoves != null ||
      widget.onEditBoard != null ||
      widget.onPlayFromPosition != null;

  void _flipAnalysisBoard() {
    setState(() => _flipped = !_flipped);
    _notifySessionChanged();
  }

  void _toggleAnalysisEngine() {
    final enabled = !_engineEnabled;
    _refinementTimer?.cancel();
    setState(() {
      _engineEnabled = enabled;
      if (!enabled) {
        _showGraph = false;
        _fullAnalysisGeneration++;
        _fullAnalysisRunning = false;
        _fullAnalysisClassifying = false;
      }
    });
    if (!enabled) {
      _cancelSelectedWork();
      StockfishAnalyzer.instance.cancel(_batchScope);
      if (widget.evaluator == null) {
        unawaited(
          StockfishAnalyzer.instance.close().catchError(
            (Object error, StackTrace stackTrace) => AppDiagnostics.record(
              'stockfish-toggle-off',
              error,
              stackTrace,
            ),
          ),
        );
      }
      return;
    }
    if (_inVariation) {
      unawaited(_analyzeVariation());
    } else {
      unawaited(_analyzePosition(_ply));
      unawaited(_analyzeMaiaPosition(_ply));
    }
  }

  Future<void> _showAnalysisMenu() async {
    if (!_hasAnalysisMenu) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.onLoadFen != null)
                ListTile(
                  leading: const Icon(Icons.content_paste),
                  title: const Text('Load FEN'),
                  onTap: () => Navigator.pop(context, 'fen'),
                ),
              if (widget.onLoadPgn != null)
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Load PGN'),
                  onTap: () => Navigator.pop(context, 'pgn'),
                ),
              if (widget.onLoadPgnFile != null)
                ListTile(
                  leading: const Icon(Icons.folder_open),
                  title: const Text('Open PGN file'),
                  onTap: () => Navigator.pop(context, 'file'),
                ),

              if (widget.onClearMoves != null)
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined),
                  title: const Text('Clear moves'),
                  onTap: () => Navigator.pop(context, 'clear'),
                ),
              if (widget.onEditBoard != null)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Board Editor'),
                  onTap: () => Navigator.pop(context, 'edit'),
                ),
              if (widget.onPlayFromPosition != null)
                ListTile(
                  leading: const Icon(Icons.play_arrow),
                  title: const Text('Continue from here'),
                  onTap: () => Navigator.pop(context, 'continue'),
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'fen':
        await widget.onLoadFen?.call();
      case 'pgn':
        await widget.onLoadPgn?.call();
      case 'file':
        await widget.onLoadPgnFile?.call();
      case 'clear':
        await widget.onClearMoves?.call();
      case 'edit':
        await widget.onEditBoard?.call(_currentFen);
      case 'continue':
        await widget.onPlayFromPosition?.call(_currentFen);
    }
  }

  Widget _analysisControls() {
    Widget slot(Widget child) => Expanded(child: Center(child: child));

    return SizedBox(
      key: const ValueKey('analysis-controls'),
      height: 52,
      child: Row(
        children: [
          slot(
            IconButton(
              key: const ValueKey('analysis-actions-menu'),
              onPressed: _hasAnalysisMenu ? _showAnalysisMenu : null,
              icon: const Icon(Icons.menu),
              tooltip: 'Analysis menu',
            ),
          ),
          slot(
            IconButton(
              key: const ValueKey('analysis-flip-button'),
              onPressed: _flipAnalysisBoard,
              icon: const Icon(CupertinoIcons.arrow_2_squarepath),
              tooltip: 'Flip board',
            ),
          ),
          slot(
            Tooltip(
              message: _engineEnabled ? 'Turn engine off' : 'Turn engine on',
              child: TextButton.icon(
                key: const ValueKey('analysis-engine-toggle'),
                onPressed: _toggleAnalysisEngine,
                icon: Icon(
                  Icons.power_settings_new,
                  color: _engineEnabled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                label: Text(
                  'SF',
                  style: TextStyle(
                    color: _engineEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          slot(
            IconButton(
              key: const ValueKey('previous-move-button'),
              tooltip: 'Previous move',
              onPressed: (_inVariation ? _variationIndex == 0 : _ply == 0)
                  ? null
                  : () => _step(-1),
              icon: const Icon(CupertinoIcons.chevron_back),
            ),
          ),
          slot(
            IconButton(
              key: const ValueKey('next-move-button'),
              tooltip: 'Next move',
              onPressed:
                  (_inVariation
                      ? _variationIndex == _variationSan.length
                      : _ply == _maximumPly)
                  ? null
                  : () => _step(1),
              icon: const Icon(CupertinoIcons.chevron_forward),
            ),
          ),
        ],
      ),
    );
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
              onTap: graph && !_engineEnabled
                  ? null
                  : () => setState(() => _showGraph = graph),
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
                  color: graph && !_engineEnabled
                      ? colors.onSurface.withValues(alpha: 0.28)
                      : selected
                      ? colors.primary
                      : colors.onSurfaceVariant,
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

  Widget _movesTab() => _movesNotation();

  Widget _graphTab() {
    final scores = _graphScores;
    if (scores != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            AccuracySummary(
              scores: scores,
              startsWithWhite: _graphPositions.first.split(' ')[1] == 'w',
            ),
            const SizedBox(height: 8),
            AnalysisGraph(
              scores: scores,
              positions: _graphPositions,
              classifications: _graphClassifications,
              selectedPly: _selectedComputerAnalysisPly,
              onSelected: _showComputerAnalysisPly,
            ),
            const SizedBox(height: 8),
            if (_fullAnalysisClassifying) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text(
                'Graph ready · classifying moves…',
                textAlign: TextAlign.center,
              ),
            ] else
              MoveClassificationSummary(
                moves: _graphClassifications,
                selectedPly: _selectedComputerAnalysisPly,
                onSelected: _showComputerAnalysisPly,
              ),
            if (_analysisError != null) ...[
              const SizedBox(height: 8),
              Text(
                _analysisError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _fullAnalysisRunning ? null : _analyzeFullGame,
              icon: const Icon(Icons.refresh),
              label: const Text('Run computer analysis again'),
            ),
          ],
        ),
      );
    }
    final total = _computerAnalysisLine.positions.length;
    return SingleChildScrollView(
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
              const SizedBox(height: 8),
              TextButton.icon(
                key: const ValueKey('cancel-computer-analysis'),
                onPressed: _cancelFullAnalysis,
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Stop analysis'),
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
    final agreement = _engineEnabled ? _agreementArrow : null;
    final boardAnnotation = _engineEnabled ? _currentBoardAnnotation : null;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () async {
            if (widget.returnToGame) {
              Navigator.of(context).pop();
              return;
            }
            await widget.onHome();
            if (context.mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
          icon: Icon(
            widget.returnToGame ? Icons.arrow_back : Icons.home_outlined,
          ),
          tooltip: widget.returnToGame ? 'Back to game' : 'Home',
        ),
        title: Text(widget.title),
        actions: [
          PopupMenuButton<String>(
            key: const ValueKey('analysis-share-menu'),
            tooltip: 'Share and export',
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'pgn') await _copyPgn();
              if (value == 'fen') await _copyFen();
              if (value == 'save') {
                if (context.mounted) {
                  await PgnFiles.export(context, _exportReviewPgn());
                }
              }
              if (value == 'share') {
                if (context.mounted) {
                  await PgnFiles.export(
                    context,
                    _exportReviewPgn(),
                    share: true,
                  );
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
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscape =
                constraints.maxWidth > constraints.maxHeight &&
                constraints.maxWidth >= 600;
            final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
            final boardGutter =
                max(24.0, MediaQuery.textScalerOf(context).scale(24)) + 8;
            final engineHeight = _engineEnabled
                ? 3 * max(26.0, 22.0 * textScale) + 20
                : 0.0;
            Widget board(double size) => SizedBox(
              width: size + boardGutter,
              height: size,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: size,
                    height: size,
                    child: Stack(
                      children: [
                        cg.Chessboard(
                          controller: _boardController,
                          size: size,
                          orientation: boardOrientation,
                          onMove: _onAnalysisMove,
                          shapes: _arrows,
                          settings: mobileMaiaInteractiveBoardSettings,
                        ),
                        if (agreement != null || boardAnnotation != null)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                key: const ValueKey('review-board-overlay'),
                                painter: ReviewBoardOverlayPainter(
                                  orientation: boardOrientation,
                                  agreementUci: agreement?.uci,
                                  agreementTailColor: agreement?.tailColor,
                                  annotationSquare: boardAnnotation?.square,
                                  classification:
                                      boardAnnotation?.classification,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  EvaluationBar(
                    evaluation: evaluation,
                    mate: mate,
                    enabled: _engineEnabled,
                  ),
                ],
              ),
            );
            Widget details() => LayoutBuilder(
              builder: (context, available) {
                final header = <Widget>[
                  SizedBox(
                    height: 28,
                    child: openingName == null
                        ? const SizedBox.shrink()
                        : Center(
                            child: Text(
                              openingName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                  ),
                  if (_engineEnabled)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
                      child: _engineLinesPanel(),
                    ),
                  _analysisTabBar(),
                ];
                final panel = SizedBox(
                  key: const ValueKey('analysis-tab-panel'),
                  width: double.infinity,
                  child: _showGraph ? _graphTab() : _movesTab(),
                );
                if (available.maxHeight < engineHeight + 188) {
                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              ...header,
                              SizedBox(height: 220, child: panel),
                            ],
                          ),
                        ),
                      ),
                      _analysisControls(),
                    ],
                  );
                }
                return Column(
                  children: [
                    ...header,
                    Expanded(child: panel),
                    _analysisControls(),
                  ],
                );
              },
            );
            if (landscape) {
              final size = min(
                constraints.maxHeight - 16,
                constraints.maxWidth * 0.48 - boardGutter,
              ).clamp(80.0, 560.0);
              return Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    board(size),
                    const SizedBox(width: 8),
                    Expanded(child: details()),
                  ],
                ),
              );
            }
            final width = min(constraints.maxWidth, 600.0);
            final size = min(
              width - boardGutter,
              max(80.0, constraints.maxHeight - engineHeight - 220),
            );
            return Center(
              child: SizedBox(
                width: width,
                height: constraints.maxHeight,
                child: Column(
                  children: [
                    board(size),
                    Expanded(child: details()),
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

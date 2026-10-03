part of '../main.dart';

class _ContinuationSettings {
  const _ContinuationSettings({
    required this.side,
    required this.elo,
    required this.timePreset,
    required this.customMinutes,
    required this.customIncrement,
  });

  final PlayerSide side;
  final int elo;
  final TimePreset timePreset;
  final int customMinutes;
  final int customIncrement;
}

class _ContinueFromHereDialog extends StatefulWidget {
  const _ContinueFromHereDialog({required this.defaults});

  final _ContinuationSettings defaults;

  @override
  State<_ContinueFromHereDialog> createState() =>
      _ContinueFromHereDialogState();
}

class _ContinueFromHereDialogState extends State<_ContinueFromHereDialog> {
  late PlayerSide _side = widget.defaults.side;
  late int _elo = widget.defaults.elo;
  late TimePreset _timePreset = widget.defaults.timePreset;
  late int _customMinutes = widget.defaults.customMinutes;
  late int _customIncrement = widget.defaults.customIncrement;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Continue from here'),
    content: SizedBox(
      width: 400,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<PlayerSide>(
              key: const ValueKey('continuation-side'),
              initialValue: _side,
              decoration: const InputDecoration(labelText: 'Your side'),
              items: const [
                DropdownMenuItem(value: PlayerSide.white, child: Text('White')),
                DropdownMenuItem(value: PlayerSide.black, child: Text('Black')),
                DropdownMenuItem(
                  value: PlayerSide.random,
                  child: Text('Random'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _side = value);
              },
            ),
            const SizedBox(height: 12),
            Text('Play Maia rating: $_elo'),
            Slider(
              key: const ValueKey('continuation-rating'),
              min: maiaMinimumRating.toDouble(),
              max: maiaMaximumRating.toDouble(),
              divisions: maiaRatingDivisions,
              value: _elo.toDouble(),
              label: '$_elo',
              onChanged: (value) => setState(() => _elo = value.round()),
            ),
            DropdownButtonFormField<TimePreset>(
              key: const ValueKey('continuation-time-control'),
              initialValue: _timePreset,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Time control'),
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
              const SizedBox(height: 12),
              Text('Minutes: $_customMinutes'),
              Slider(
                key: const ValueKey('continuation-custom-minutes'),
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
                key: const ValueKey('continuation-custom-increment'),
                min: 0,
                max: 30,
                divisions: 30,
                value: _customIncrement.toDouble(),
                label: '$_customIncrement',
                onChanged: (value) =>
                    setState(() => _customIncrement = value.round()),
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const ValueKey('continuation-start-game'),
        onPressed: () => Navigator.pop(
          context,
          _ContinuationSettings(
            side: _side,
            elo: _elo,
            timePreset: _timePreset,
            customMinutes: _customMinutes,
            customIncrement: _customIncrement,
          ),
        ),
        child: const Text('Start game'),
      ),
    ],
  );
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
    this.secondMaiaElo,
    this.initialVariations = const [],
    this.initialTreeIsAuthoritative = false,
    this.initialCurrentFen,
    this.initialFlipped = false,
    this.gameAnalysisQuality = GameAnalysisQuality.fast,
    this.evaluator,
    this.maiaEvaluator,
    this.maiaPolicyEvaluator,
    super.key,
  });

  final AnalysisSession initialSession;
  final int maiaElo;
  final int? secondMaiaElo;
  final List<RecordedVariation> initialVariations;
  final bool initialTreeIsAuthoritative;
  final String? initialCurrentFen;
  final bool initialFlipped;
  final GameAnalysisQuality gameAnalysisQuality;
  final Future<StockfishReview> Function(String fen)? evaluator;
  final Future<String?> Function(List<String> positions, int elo)?
  maiaEvaluator;
  final Future<List<double>?> Function(List<String> positions, int elo)?
  maiaPolicyEvaluator;

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
    if (!widget.initialTreeIsAuthoritative && _initialVariations.isEmpty) {
      _initialVariations = PgnVariationExporter.parseTree(_session.pgn);
    }
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
    'treeIsAuthoritative': true,
    'session': _session.toJson(),
    'variations': variations.map((item) => item.toJson()).toList(),
    'currentFen': currentFen,
    'flipped': flipped,
    'maiaElo': widget.maiaElo,
    if (widget.secondMaiaElo != null) 'secondMaiaElo': widget.secondMaiaElo,
  });

  void _replace(AnalysisSession session) {
    setState(() {
      _session = session;
      _initialVariations = PgnVariationExporter.parseTree(session.pgn);
      _initialCurrentFen = session.positions.first;
      _initialFlipped = false;
      _revision++;
    });
    unawaited(
      _saveAnalysisState(session.positions.first, false, _initialVariations),
    );
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

  Future<void> _loadPgnFile() async {
    try {
      final session = await PgnFiles.open();
      if (session != null && mounted) {
        await ActiveSessionStore.startNew();
        if (mounted) _replace(session);
      }
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _loadPgn() async {
    final value = await _textDialog('Load PGN', 'Paste a PGN game');
    if (value == null || value.trim().isEmpty) return;
    try {
      final session = await AnalysisSession.fromPgnAsync(value);
      if (!mounted) return;
      await ActiveSessionStore.startNew();
      if (mounted) _replace(session);
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
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    final defaults = _ContinuationSettings(
      side: _readValidatedPreference<PlayerSide>(
        preferences,
        maiaPlaySidePreferenceKey,
        fallback: PlayerSide.white,
        decode: (value) => value is String
            ? PlayerSide.values.where((side) => side.name == value).firstOrNull
            : null,
      ),
      elo: _readMaiaRatingPreference(
        preferences,
        maiaPlayEloPreferenceKey,
        fallback: 1500,
      ),
      timePreset: _readValidatedPreference<TimePreset>(
        preferences,
        maiaTimePresetPreferenceKey,
        fallback: TimePreset.unlimited,
        decode: (value) => value is String
            ? TimePreset.values
                  .where((preset) => preset.name == value)
                  .firstOrNull
            : null,
      ),
      customMinutes: _readValidatedPreference<int>(
        preferences,
        maiaCustomMinutesPreferenceKey,
        fallback: 10,
        decode: (value) =>
            value is int && value >= 1 && value <= 60 ? value : null,
      ),
      customIncrement: _readValidatedPreference<int>(
        preferences,
        maiaCustomIncrementPreferenceKey,
        fallback: 0,
        decode: (value) =>
            value is int && value >= 0 && value <= 30 ? value : null,
      ),
    );
    final selection = await showDialog<_ContinuationSettings>(
      context: context,
      builder: (context) => _ContinueFromHereDialog(defaults: defaults),
    );
    if (selection == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GamePage(
          startingFen: fen,
          startingSide: selection.side,
          startingElo: selection.elo,
          startingTimePreset: selection.timePreset,
          startingCustomMinutes: selection.customMinutes,
          startingCustomIncrement: selection.customIncrement,
        ),
      ),
    );
  }

  Future<void> _clearMoves() async {
    _replace(AnalysisSession.fromFen(_session.positions.first));
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
    initialTreeIsAuthoritative:
        _revision == 0 && widget.initialTreeIsAuthoritative,
    initialCurrentFen: _initialCurrentFen,
    initialFlipped: _initialFlipped,
    gameAnalysisQuality: widget.gameAnalysisQuality,
    onSessionChanged: _saveAnalysisState,
    maiaElo: widget.maiaElo,
    secondMaiaElo: widget.secondMaiaElo,
    evaluator: widget.evaluator,
    maiaEvaluator: widget.maiaEvaluator,
    maiaPolicyEvaluator: widget.maiaPolicyEvaluator,
    title: 'Analysis Board',
    onHome: ActiveSessionStore.clear,
    onLoadFen: _loadFen,
    onLoadPgn: _loadPgn,
    onLoadPgnFile: _loadPgnFile,
    onClearMoves: _clearMoves,
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
  bool _flipped = false;

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
    try {
      AnalysisSession.validateFen(fen);
    } catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
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
        actions: [
          IconButton(
            key: const ValueKey('board-editor-flip'),
            tooltip: 'Flip board',
            onPressed: () => setState(() => _flipped = !_flipped),
            icon: const Icon(CupertinoIcons.arrow_2_squarepath),
          ),
          TextButton(onPressed: _finish, child: const Text('Done')),
        ],
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
                        orientation: _flipped ? dc.Side.black : dc.Side.white,
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

typedef MoveClassificationRunner = Future<List<ClassifiedMove>> Function({
  required List<StockfishReview> scores,
  required List<String> positions,
  required List<String> uciMoves,
});

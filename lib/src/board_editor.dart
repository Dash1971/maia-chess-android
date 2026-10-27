part of '../main.dart';

/// Standard-chess draft state. Illegal/incomplete positions remain editable.
/// Interaction reference: Lichess mobile v0.30.1 (see docs/BOARD_EDITOR.md).
class BoardEditorDraft {
  BoardEditorDraft(String fen) {
    load(fen);
  }
  Map<dc.Square, dc.Piece> pieces = {};
  dc.Side turn = dc.Side.white;
  Set<String> castling = {};
  String enPassant = '-';
  int halfmoves = 0, fullmoves = 1;

  void load(String value) {
    final fields = value.trim().split(RegExp(r'\s+'));
    if (value.length > 512 ||
        ![1, 6].contains(fields.length) ||
        !RegExp(r'^[pnbrqkPNBRQK1-8/]+$').hasMatch(fields.first)) {
      throw const FormatException('Expected a standard-chess FEN');
    }
    final setup = dc.Setup.parseFen(value.trim());
    final next = cg.readFen(fields.first);
    if (fields.length == 6) {
      if (!RegExp(r'^(-|K?Q?k?q?)$').hasMatch(fields[2]) ||
          !RegExp(r'^(-|[a-h][36])$').hasMatch(fields[3]) ||
          setup.fullmoves < 1) {
        throw const FormatException('Invalid FEN metadata');
      }
      turn = setup.turn;
      castling = fields[2] == '-' ? {} : fields[2].split('').toSet();
      enPassant = fields[3];
      halfmoves = setup.halfmoves;
      fullmoves = setup.fullmoves;
    }
    pieces = Map.of(next);
  }

  void edit(dc.Square square, dc.Piece? piece) {
    if (piece == null || pieces[square] == piece) {
      pieces.remove(square);
    } else {
      pieces[square] = piece;
    }
  }

  void move(dc.Square? origin, dc.Square destination, dc.Piece piece) {
    if (origin == destination) return;
    if (origin != null) pieces.remove(origin);
    pieces[destination] = piece;
  }

  void clear() {
    pieces.clear();
    castling.clear();
    enPassant = '-';
  }

  bool canCastle(String right) {
    final white = right == right.toUpperCase();
    final side = white ? dc.Side.white : dc.Side.black;
    final king = white ? dc.Square.e1 : dc.Square.e8;
    final rook = switch (right) {
      'K' => dc.Square.h1,
      'Q' => dc.Square.a1,
      'k' => dc.Square.h8,
      _ => dc.Square.a8,
    };
    return pieces[king] == dc.Piece(color: side, role: dc.Role.king) &&
        pieces[rook] == dc.Piece(color: side, role: dc.Role.rook);
  }

  String get fen {
    final rights = [
      'K',
      'Q',
      'k',
      'q',
    ].where((r) => castling.contains(r) && canCastle(r)).join();
    return '${cg.writeFen(pieces)} ${turn == dc.Side.white ? 'w' : 'b'} ${rights.isEmpty ? '-' : rights} $enPassant $halfmoves $fullmoves';
  }

  String validatedFen() {
    final value = fen;
    dc.Chess.fromSetup(dc.Setup.parseFen(value));
    AnalysisSession.validateFen(value);
    return value;
  }
}

class BoardEditorPage extends StatefulWidget {
  const BoardEditorPage({required this.initialFen, this.onContinue, super.key});
  final String initialFen;
  final Future<void> Function(String fen)? onContinue;
  @override
  State<BoardEditorPage> createState() => _BoardEditorPageState();
}

class _BoardEditorPageState extends State<BoardEditorPage> {
  late final BoardEditorDraft _draft = BoardEditorDraft(widget.initialFen);
  cg.EditorPointerMode _mode = cg.EditorPointerMode.drag;
  dc.Piece? _placement;
  dc.Square? _selected;
  bool _flipped = false, _continuing = false;
  Offset? _pointerDown;
  final _boardKey = GlobalKey();

  void _change(VoidCallback change) => setState(() {
    change();
    _selected = null;
  });
  void _tool(cg.EditorPointerMode mode, [dc.Piece? piece]) => _change(() {
    _mode = mode;
    _placement = piece;
  });
  String _pieceLabel(dc.Piece piece) => switch (piece.kind) {
    dc.PieceKind.whitePawn => l10n(context).editorWhitePawn,
    dc.PieceKind.whiteKnight => l10n(context).editorWhiteKnight,
    dc.PieceKind.whiteBishop => l10n(context).editorWhiteBishop,
    dc.PieceKind.whiteRook => l10n(context).editorWhiteRook,
    dc.PieceKind.whiteQueen => l10n(context).editorWhiteQueen,
    dc.PieceKind.whiteKing => l10n(context).editorWhiteKing,
    dc.PieceKind.blackPawn => l10n(context).editorBlackPawn,
    dc.PieceKind.blackKnight => l10n(context).editorBlackKnight,
    dc.PieceKind.blackBishop => l10n(context).editorBlackBishop,
    dc.PieceKind.blackRook => l10n(context).editorBlackRook,
    dc.PieceKind.blackQueen => l10n(context).editorBlackQueen,
    dc.PieceKind.blackKing => l10n(context).editorBlackKing,
  };
  void _touch(dc.Square square) {
    if (_mode == cg.EditorPointerMode.edit) {
      _change(() => _draft.edit(square, _placement));
      return;
    }
    setState(() {
      final from = _selected;
      if (from != null && _draft.pieces[from] != null) {
        _draft.move(from, square, _draft.pieces[from]!);
        _selected = null;
      } else {
        _selected = _draft.pieces.containsKey(square) ? square : null;
      }
    });
  }

  String? _validated() {
    try {
      return _draft.validatedFen();
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n(context).invalidPosition)));
      return null;
    }
  }

  void _finish() {
    final fen = _validated();
    if (fen != null) Navigator.pop(context, fen);
  }

  Future<void> _continue() async {
    if (_continuing || widget.onContinue == null) return;
    final fen = _validated();
    if (fen == null) return;
    setState(() => _continuing = true);
    try {
      await widget.onContinue!(fen);
    } finally {
      if (mounted) setState(() => _continuing = false);
    }
  }

  Future<void> _load() async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) => _TextInputDialog(
        title: l10n(context).loadFen,
        hint: l10n(context).pasteFen,
      ),
    );
    if (value == null || !mounted) return;
    try {
      _change(() => _draft.load(value));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n(context).invalidPosition)));
      }
    }
  }

  Future<void> _export() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: Text(l10n(context).editorShareFen),
              onTap: () => Navigator.pop(context, 'share'),
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: Text(l10n(context).copyFen),
              onTap: () => Navigator.pop(context, 'copy'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    if (action == 'share') {
      try {
        await maiaEngineChannel.invokeMethod<void>('shareFen', {
          'fen': _draft.fen,
          'shareTitle': l10n(context).editorShareFen,
        });
        return;
      } catch (error, stack) {
        unawaited(AppDiagnostics.record('share-fen', error, stack));
      }
    }
    await Clipboard.setData(ClipboardData(text: _draft.fen));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n(context).fenCopied)));
    }
  }

  Future<void> _menu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (id, icon, label) in [
                ('start', Icons.restart_alt, l10n(context).startingPosition),
                ('load', Icons.input, l10n(context).loadFen),
                (
                  'continue',
                  Icons.play_arrow_outlined,
                  l10n(context).continueFromHere,
                ),
                ('clear', Icons.delete_outline, l10n(context).clearBoard),
              ])
                ListTile(
                  key: ValueKey('editor-menu-$id'),
                  leading: Icon(icon),
                  title: Text(label),
                  enabled:
                      id != 'continue' ||
                      (widget.onContinue != null && !_continuing),
                  onTap: () => Navigator.pop(context, id),
                ),
            ],
          ),
        ),
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'start':
        _change(() => _draft.load(dc.Chess.initial.fen));
      case 'clear':
        _change(_draft.clear);
      case 'load':
        await _load();
      case 'continue':
        await _continue();
    }
  }

  Future<void> _settings() async {
    final half = TextEditingController(text: '${_draft.halfmoves}');
    final full = TextEditingController(text: '${_draft.fullmoves}');
    final form = GlobalKey<FormState>();
    ModalRoute<void>? sheetRoute;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, sheetState) {
          sheetRoute = ModalRoute.of<void>(context);
          void update(VoidCallback change) {
            _change(change);
            sheetState(() {});
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * .85,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n(context).editorPositionSettings,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        RadioGroup<dc.Side>(
                          groupValue: _draft.turn,
                          onChanged: (side) {
                            if (side != null) update(() => _draft.turn = side);
                          },
                          child: Column(
                            children: [
                              for (final side in dc.Side.values)
                                RadioListTile<dc.Side>(
                                  key: ValueKey('editor-turn-${side.name}'),
                                  value: side,
                                  title: Text(
                                    side == dc.Side.white
                                        ? l10n(context).whiteToMove
                                        : l10n(context).blackToMove,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          l10n(context).castlingRights,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(1.5),
                            1: FlexColumnWidth(),
                            2: FlexColumnWidth(),
                          },
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          children: [
                            const TableRow(
                              children: [
                                SizedBox(),
                                Center(child: Text('O-O')),
                                Center(child: Text('O-O-O')),
                              ],
                            ),
                            for (final side in dc.Side.values)
                              TableRow(
                                children: [
                                  Text(
                                    side == dc.Side.white
                                        ? l10n(context).white
                                        : l10n(context).black,
                                  ),
                                  for (final kingSide in [true, false])
                                    Builder(
                                      builder: (context) {
                                        final right = side == dc.Side.white
                                            ? (kingSide ? 'K' : 'Q')
                                            : (kingSide ? 'k' : 'q');
                                        final label = side == dc.Side.white
                                            ? (kingSide
                                                  ? l10n(context).whiteKingside
                                                  : l10n(context)
                                                        .whiteQueenside)
                                            : (kingSide
                                                  ? l10n(context).blackKingside
                                                  : l10n(context)
                                                        .blackQueenside);
                                        return Semantics(
                                          label: label,
                                          child: Checkbox(
                                            key: ValueKey(
                                              'editor-castle-$right',
                                            ),
                                            value:
                                                _draft.castling.contains(
                                                  right,
                                                ) &&
                                                _draft.canCastle(right),
                                            onChanged: _draft.canCastle(right)
                                                ? (enabled) => update(() {
                                                    if (enabled == true) {
                                                      _draft.castling.add(
                                                        right,
                                                      );
                                                    } else {
                                                      _draft.castling.remove(
                                                        right,
                                                      );
                                                    }
                                                  })
                                                : null,
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                          ],
                        ),
                        ExpansionTile(
                          title: Text(l10n(context).editorFenMetadata),
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _draft.enPassant,
                              decoration: InputDecoration(
                                labelText: l10n(context).enPassantTarget,
                              ),
                              items: [
                                for (final square in [
                                  '-',
                                  for (final rank in [3, 6])
                                    for (final file in 'abcdefgh'.split(''))
                                      '$file$rank',
                                ])
                                  DropdownMenuItem(
                                    value: square,
                                    child: Text(square),
                                  ),
                              ],
                              onChanged: (value) =>
                                  update(() => _draft.enPassant = value ?? '-'),
                            ),
                            for (final isFull in [false, true])
                              TextFormField(
                                key: ValueKey(
                                  isFull
                                      ? 'editor-fullmove'
                                      : 'editor-halfmove',
                                ),
                                controller: isFull ? full : half,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: isFull
                                      ? l10n(context).editorFullmoveNumber
                                      : l10n(context).editorHalfmoveClock,
                                ),
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                validator: (value) {
                                  final n = int.tryParse(value ?? '');
                                  return n == null ||
                                          n < (isFull ? 1 : 0) ||
                                          n > 9999
                                      ? l10n(context).invalidPosition
                                      : null;
                                },
                                onChanged: (value) {
                                  final n = int.tryParse(value);
                                  if (n != null &&
                                      n >= (isFull ? 1 : 0) &&
                                      n <= 9999) {
                                    update(() {
                                      if (isFull) {
                                        _draft.fullmoves = n;
                                      } else {
                                        _draft.halfmoves = n;
                                      }
                                    });
                                  }
                                },
                              ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            if (form.currentState?.validate() == true) {
                              Navigator.pop(context);
                            }
                          },
                          child: Text(l10n(context).done),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    // The result future completes at pop; fields live through the reverse animation.
    await sheetRoute?.completed;
    half.dispose();
    full.dispose();
  }

  Widget _palette(dc.Side side, double width) {
    final preferences = boardPreferencesOf(context);
    final size = width >= 352 ? width / 8 : width / 4;
    final colors = Theme.of(context).colorScheme;
    Widget tool(
      String id,
      String label,
      bool selected,
      Widget child,
      VoidCallback press,
    ) => Semantics(
      key: ValueKey('editor-$id-${side.name}'),
      selected: selected,
      label: label,
      button: true,
      onTap: press,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: SizedBox(
          width: size,
          height: 44,
          child: Material(
            color: selected
                ? colors.secondaryContainer
                : colors.surfaceContainerHighest,
            child: InkWell(
              onTap: press,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
    return Wrap(
      children: [
        tool(
          'move',
          l10n(context).editorMoveTool,
          _mode == cg.EditorPointerMode.drag,
          const Icon(Icons.pan_tool_outlined),
          () => _tool(cg.EditorPointerMode.drag),
        ),
        for (final role in [
          dc.Role.pawn,
          dc.Role.knight,
          dc.Role.bishop,
          dc.Role.rook,
          dc.Role.king,
          dc.Role.queen,
        ])
          Builder(
            builder: (context) {
              final piece = dc.Piece(color: side, role: role);
              return Draggable<dc.Piece>(
                data: piece,
                onDragStarted: () => _tool(cg.EditorPointerMode.drag),
                onDragEnd: (_) => _tool(cg.EditorPointerMode.drag),
                feedback: cg.PieceDragFeedback(
                  piece: piece,
                  squareSize: 44,
                  pieceAssets: preferences.pieces.assets,
                ),
                child: tool(
                  role.name,
                  _pieceLabel(piece),
                  _mode == cg.EditorPointerMode.edit && _placement == piece,
                  Image(
                    image: preferences.pieces.assets[piece.kind]!,
                    width: 40,
                    height: 40,
                    excludeFromSemantics: true,
                  ),
                  () => _tool(cg.EditorPointerMode.edit, piece),
                ),
              );
            },
          ),
        tool(
          'erase',
          l10n(context).editorEraseTool,
          _mode == cg.EditorPointerMode.edit && _placement == null,
          const Icon(Icons.delete_outline),
          () => _tool(cg.EditorPointerMode.edit),
        ),
      ],
    );
  }

  Widget _board(double size) {
    final orientation = _flipped ? dc.Side.black : dc.Side.white;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          Listener(
            key: _boardKey,
            onPointerDown: (event) => _pointerDown = event.localPosition,
            onPointerUp: (event) {
              if (_mode != cg.EditorPointerMode.drag ||
                  _pointerDown == null ||
                  (event.localPosition - _pointerDown!).distance > 8) {
                return;
              }
              final file = (event.localPosition.dx / (size / 8)).floor().clamp(
                0,
                7,
              );
              final rank =
                  7 - (event.localPosition.dy / (size / 8)).floor().clamp(0, 7);
              _touch(
                dc.Square.fromCoords(
                  dc.File.values[orientation == dc.Side.white
                      ? file
                      : 7 - file],
                  dc.Rank.values[orientation == dc.Side.white
                      ? rank
                      : 7 - rank],
                ),
              );
            },
            child: cg.ChessboardEditor(
              key: const ValueKey('board-editor-board'),
              size: size,
              orientation: orientation,
              pieces: Map.of(_draft.pieces),
              pointerMode: _mode,
              settings: boardPreferencesOf(context).interactiveSettings,
              squareHighlights: {
                ?_selected: cg.SquareHighlight(
                  details: boardPreferencesOf(context).board.scheme.selected,
                ),
              },
              onEditedSquare: (square) =>
                  _change(() => _draft.edit(square, _placement)),
              onDroppedPiece: (origin, destination, piece) =>
                  _change(() => _draft.move(origin, destination, piece)),
              onDiscardedPiece: (square) =>
                  _change(() => _draft.pieces.remove(square)),
            ),
          ),
          // Unpainted semantics nodes do not intercept pointer/drag hit testing.
          for (final square in dc.Square.values)
            Positioned(
              left:
                  (orientation == dc.Side.white
                      ? square.file
                      : 7 - square.file) *
                  size /
                  8,
              top:
                  (orientation == dc.Side.white
                      ? 7 - square.rank
                      : square.rank) *
                  size /
                  8,
              width: size / 8,
              height: size / 8,
              child: Semantics(
                key: ValueKey('editor-square-${square.name}'),
                label:
                    '${square.name}: ${_draft.pieces[square] == null ? l10n(context).editorEmptySquare : _pieceLabel(_draft.pieces[square]!)}',
                button: true,
                onTap: () => _touch(square),
                child: const SizedBox.expand(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _toolbar() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      IconButton(
        key: const ValueKey('editor-menu'),
        tooltip: l10n(context).analysisMenu,
        onPressed: _menu,
        icon: const Icon(Icons.menu),
      ),
      IconButton(
        key: const ValueKey('board-editor-flip'),
        tooltip: l10n(context).flipBoard,
        onPressed: () => setState(() => _flipped = !_flipped),
        icon: const Icon(CupertinoIcons.arrow_2_squarepath),
      ),
      IconButton(
        key: const ValueKey('editor-analyze'),
        tooltip: l10n(context).analysisBoard,
        onPressed: _finish,
        icon: const Icon(Icons.analytics_outlined),
      ),
      IconButton(
        key: const ValueKey('editor-settings'),
        tooltip: l10n(context).editorPositionSettings,
        onPressed: _settings,
        icon: const Icon(Icons.tune),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(l10n(context).boardEditor),
      actions: [
        Tooltip(
          message: l10n(context).editorImageImportUnavailable,
          child: IconButton(
            onPressed: null,
            icon: const Icon(Icons.photo_camera_outlined),
            tooltip: l10n(context).editorImageImportUnavailable,
          ),
        ),
        IconButton(
          key: const ValueKey('editor-share'),
          onPressed: _export,
          tooltip: l10n(context).shareAndExport,
          icon: const Icon(Icons.share_outlined),
        ),
      ],
    ),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, box) {
          if (box.maxWidth > box.maxHeight && box.maxWidth >= 600) {
            final board = min(
              box.maxHeight,
              box.maxWidth * .56,
            ).clamp(80.0, 560.0);
            return Row(
              children: [
                _board(board),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, right) => Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _palette(
                          _flipped ? dc.Side.white : dc.Side.black,
                          right.maxWidth,
                        ),
                        _palette(
                          _flipped ? dc.Side.black : dc.Side.white,
                          right.maxWidth,
                        ),
                        _toolbar(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          final width = min(box.maxWidth, 560.0),
              paletteHeight = width >= 352 ? 44.0 : 88.0;
          final board = min(
            width,
            max(80.0, box.maxHeight - 2 * paletteHeight - 56),
          );
          return Center(
            child: SizedBox(
              width: width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _palette(_flipped ? dc.Side.white : dc.Side.black, width),
                  _board(board),
                  _palette(_flipped ? dc.Side.black : dc.Side.white, width),
                  _toolbar(),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

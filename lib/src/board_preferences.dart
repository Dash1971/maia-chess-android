part of '../main.dart';

const boardPreferenceKey = 'boardPreferencesV1';

@immutable
class BoardPreferences {
  const BoardPreferences({
    this.board = BoardDesign.brown,
    this.pieces = PieceDesign.cburnett,
    this.coordinates = true,
    this.legalMoves = true,
    this.lastMove = true,
    this.animation = true,
    this.magnify = true,
    this.dragTarget = cg.DragTargetKind.circle,
  });

  final BoardDesign board;
  final PieceDesign pieces;
  final bool coordinates, legalMoves, lastMove, animation, magnify;
  final cg.DragTargetKind dragTarget;

  factory BoardPreferences.decode(Object? stored) {
    try {
      final data = stored is String ? jsonDecode(stored) : null;
      if (data is! Map) return const BoardPreferences();
      // A malformed field falls back independently, preserving valid choices.
      bool flag(String key) => data[key] is bool ? data[key] as bool : true;
      return BoardPreferences(
        board:
            BoardDesign.values
                .where((value) => value.name == data['board'])
                .firstOrNull ??
            BoardDesign.brown,
        pieces:
            PieceDesign.values
                .where((value) => value.name == data['pieces'])
                .firstOrNull ??
            PieceDesign.cburnett,
        coordinates: flag('coordinates'),
        legalMoves: flag('legalMoves'),
        lastMove: flag('lastMove'),
        animation: flag('animation'),
        magnify: flag('magnify'),
        dragTarget:
            cg.DragTargetKind.values
                .where((value) => value.name == data['dragTarget'])
                .firstOrNull ??
            cg.DragTargetKind.circle,
      );
    } on FormatException {
      return const BoardPreferences();
    }
  }

  String encode() => jsonEncode({
    'board': board.name,
    'pieces': pieces.name,
    'coordinates': coordinates,
    'legalMoves': legalMoves,
    'lastMove': lastMove,
    'animation': animation,
    'magnify': magnify,
    'dragTarget': dragTarget.name,
  });

  BoardPreferences copyWith({
    BoardDesign? board,
    PieceDesign? pieces,
    bool? coordinates,
    bool? legalMoves,
    bool? lastMove,
    bool? animation,
    bool? magnify,
    cg.DragTargetKind? dragTarget,
  }) => BoardPreferences(
    board: board ?? this.board,
    pieces: pieces ?? this.pieces,
    coordinates: coordinates ?? this.coordinates,
    legalMoves: legalMoves ?? this.legalMoves,
    lastMove: lastMove ?? this.lastMove,
    animation: animation ?? this.animation,
    magnify: magnify ?? this.magnify,
    dragTarget: dragTarget ?? this.dragTarget,
  );

  cg.ChessboardSettings get interactiveSettings =>
      mobileMaiaInteractiveBoardSettings.copyWith(
        colorScheme: board.scheme,
        pieceAssets: pieces.assets,
        enableCoordinates: coordinates,
        showValidMoves: legalMoves,
        showLastMove: lastMove,
        animationDuration: animation
            ? const Duration(milliseconds: 150)
            : Duration.zero,
        dragFeedbackScale: magnify ? 2.0 : 1.0,
        // Keep the lifted touch-drag behavior, independently of magnification.
        dragFeedbackOffset: const Offset(0, -1),
        dragTargetKind: dragTarget,
      );

  cg.StaticChessboardSettings get editorSettings => cg.StaticChessboardSettings(
    colorScheme: board.scheme,
    pieceAssets: pieces.assets,
    enableCoordinates: coordinates,
    // Preserve the editor's previous 200 ms duration when enabled.
    animationDuration: animation
        ? const Duration(milliseconds: 200)
        : Duration.zero,
  );
}

/// Serializes writes without coupling a board rebuild to session/engine state.
class BoardPreferencesController extends ChangeNotifier {
  BoardPreferencesController({
    Future<Object?> Function()? read,
    Future<void> Function(String)? write,
  }) : _read = read ?? _readPreference,
       _write = write ?? writePreference;

  final Future<Object?> Function() _read;
  final Future<void> Function(String) _write;
  BoardPreferences value = const BoardPreferences();
  bool persistenceFailed = false;
  bool _disposed = false;
  int _revision = 0;
  Future<void> _pendingWrite = Future<void>.value();

  static Future<Object?> _readPreference() async =>
      (await SharedPreferences.getInstance()).get(boardPreferenceKey);

  static Future<void> writePreference(String value) async {
    if (!await (await SharedPreferences.getInstance()).setString(
      boardPreferenceKey,
      value,
    )) {
      throw StateError('Board preference write failed');
    }
  }

  Future<void> initialize() async {
    final revision = _revision;
    try {
      final stored = await _read();
      if (!_disposed && revision == _revision) {
        value = BoardPreferences.decode(stored);
        notifyListeners();
        _releaseUnusedPieceImages();
      }
    } catch (error, stack) {
      _failure(revision, error, stack);
    }
  }

  Future<void> select(BoardPreferences next) {
    if (_disposed) return Future<void>.value();
    final revision = ++_revision;
    value = next;
    persistenceFailed = false;
    notifyListeners();
    _releaseUnusedPieceImages();
    return _pendingWrite = _pendingWrite.then((_) async {
      try {
        await _write(next.encode());
        if (!_disposed && revision == _revision) {
          persistenceFailed = false;
          notifyListeners();
        }
      } catch (error, stack) {
        _failure(revision, error, stack);
      }
    });
  }

  // All app boards read this scope. Wait until their settings/painters have
  // switched before disposing old raw images; never evict during a paint.
  void _releaseUnusedPieceImages() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      final scheme = value.board.scheme;
      final keep = {
        ...value.pieces.assets.values,
        if (scheme.lastMove.image != null) scheme.lastMove.image!,
        if (scheme.selected.image != null) scheme.selected.image!,
      };
      final cache = cg.ChessgroundImages.instance;
      for (final key in cache.keys) {
        if (!keep.contains(key)) cache.evict(key);
      }
    });
  }

  void _failure(int revision, Object error, StackTrace stack) {
    unawaited(AppDiagnostics.record('board-preference', error, stack));
    if (!_disposed && revision == _revision) {
      persistenceFailed = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class BoardPreferencesScope
    extends InheritedNotifier<BoardPreferencesController> {
  const BoardPreferencesScope({
    required BoardPreferencesController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static BoardPreferencesController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<BoardPreferencesScope>()
      ?.notifier;
}

BoardPreferences boardPreferencesOf(BuildContext context) =>
    BoardPreferencesScope.maybeOf(context)?.value ?? const BoardPreferences();

String dragTargetLabel(BuildContext context, cg.DragTargetKind target) =>
    switch (target) {
      cg.DragTargetKind.circle => l10n(context).boardTargetCircle,
      cg.DragTargetKind.square => l10n(context).boardTargetSquare,
      cg.DragTargetKind.none => l10n(context).boardTargetNone,
    };

class BoardSettingsSection extends StatelessWidget {
  const BoardSettingsSection({super.key});

  Future<void> _chooseTarget(
    BuildContext context,
    BoardPreferencesController controller,
  ) async {
    final selected = await showDialog<cg.DragTargetKind>(
      context: context,
      builder: (context) {
        var choice = controller.value.dragTarget;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(l10n(context).boardDragTarget),
            scrollable: true,
            content: RadioGroup<cg.DragTargetKind>(
              groupValue: choice,
              onChanged: (value) {
                if (value != null) setState(() => choice = value);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final target in cg.DragTargetKind.values)
                    RadioListTile<cg.DragTargetKind>(
                      key: ValueKey('board-target-${target.name}'),
                      value: target,
                      title: Text(dragTargetLabel(context, target)),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n(context).cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, choice),
                child: Text(l10n(context).done),
              ),
            ],
          ),
        );
      },
    );
    if (selected != null && context.mounted) {
      await controller.select(controller.value.copyWith(dragTarget: selected));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = BoardPreferencesScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();
    final value = controller.value;
    final strings = l10n(context);
    Widget toggle(
      String key,
      String label,
      bool enabled,
      BoardPreferences Function(bool) next,
    ) => SwitchListTile(
      key: ValueKey('board-$key'),
      title: Text(label),
      value: enabled,
      onChanged: (enabled) => unawaited(controller.select(next(enabled))),
    );
    return Card(
      key: const ValueKey('board-settings-section'),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: const Icon(Icons.grid_on_outlined),
            title: Semantics(
              header: true,
              child: Text(
                strings.boardSettings,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            key: const ValueKey('board-design-selector'),
            leading: SizedBox.square(
              dimension: 44,
              child: value.board.scheme.background,
            ),
            title: Text(strings.boardDesign),
            subtitle: Text(value.board.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const BoardStylePicker(pieceSets: false),
              ),
            ),
          ),
          ListTile(
            key: const ValueKey('board-piece-selector'),
            leading: SizedBox.square(
              dimension: 44,
              child: Image(
                image: value.pieces.assets[dc.PieceKind.whiteKnight]!,
                excludeFromSemantics: true,
              ),
            ),
            title: Text(strings.boardPieceSet),
            subtitle: Text(value.pieces.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const BoardStylePicker(pieceSets: true),
              ),
            ),
          ),
          const Divider(height: 1),
          toggle(
            'coordinates',
            strings.boardCoordinates,
            value.coordinates,
            (enabled) => value.copyWith(coordinates: enabled),
          ),
          toggle(
            'legal-moves',
            strings.boardLegalMoves,
            value.legalMoves,
            (enabled) => value.copyWith(legalMoves: enabled),
          ),
          toggle(
            'last-move',
            strings.boardLastMove,
            value.lastMove,
            (enabled) => value.copyWith(lastMove: enabled),
          ),
          toggle(
            'animation',
            strings.boardAnimation,
            value.animation,
            (enabled) => value.copyWith(animation: enabled),
          ),
          toggle(
            'magnify',
            strings.boardMagnify,
            value.magnify,
            (enabled) => value.copyWith(magnify: enabled),
          ),
          ListTile(
            key: const ValueKey('board-drag-target'),
            title: Text(strings.boardDragTarget),
            subtitle: Text(dragTargetLabel(context, value.dragTarget)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _chooseTarget(context, controller),
          ),
          if (controller.persistenceFailed)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Semantics(
                liveRegion: true,
                child: Text(strings.boardPreferenceError),
              ),
            ),
        ],
      ),
    );
  }
}

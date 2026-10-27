part of '../main.dart';

/// Recorded fixed catalogue, rather than automatically exposing package enums.
enum BoardDesign {
  brown('Brown', cg.ChessboardColorScheme.brown),
  wood('Wood', cg.ChessboardColorScheme.wood),
  wood2('Wood 2', cg.ChessboardColorScheme.wood2),
  wood3('Wood 3', cg.ChessboardColorScheme.wood3),
  wood4('Wood 4', cg.ChessboardColorScheme.wood4),
  maple('Maple', cg.ChessboardColorScheme.maple),
  maple2('Maple 2', cg.ChessboardColorScheme.maple2),
  blue('Blue', cg.ChessboardColorScheme.blue),
  blue2('Blue 2', cg.ChessboardColorScheme.blue2),
  blue3('Blue 3', cg.ChessboardColorScheme.blue3),
  blueMarble('Blue Marble', cg.ChessboardColorScheme.blueMarble),
  canvas('Canvas', cg.ChessboardColorScheme.canvas),
  leather('Leather', cg.ChessboardColorScheme.leather),
  ic('IC', cg.ChessboardColorScheme.ic),
  green('Green', cg.ChessboardColorScheme.green),
  marble('Marble', cg.ChessboardColorScheme.marble),
  greenPlastic('Green Plastic', cg.ChessboardColorScheme.greenPlastic),
  grey('Grey', cg.ChessboardColorScheme.grey),
  metal('Metal', cg.ChessboardColorScheme.metal),
  olive('Olive', cg.ChessboardColorScheme.olive),
  newspaper('Newspaper', cg.ChessboardColorScheme.newspaper),
  purple('Purple', cg.ChessboardColorScheme.purple),
  purpleDiag('Purple-Diag', cg.ChessboardColorScheme.purpleDiag),
  pinkPyramid('Pink', cg.ChessboardColorScheme.pinkPyramid),
  horsey('Horsey', cg.ChessboardColorScheme.horsey);

  const BoardDesign(this.label, this.scheme);
  final String label;
  final cg.ChessboardColorScheme scheme;
}

/// This allowlist is matched to the filtered package and its provenance manifest.
enum PieceDesign {
  cburnett('Cburnett', cg.PieceSet.cburnett),
  merida('Merida', cg.PieceSet.merida),
  pirouetti('Pirouetti', cg.PieceSet.pirouetti),
  chessnut('Chessnut', cg.PieceSet.chessnut),
  kosal('Kosal', cg.PieceSet.kosal),
  fantasy('Fantasy', cg.PieceSet.fantasy),
  spatial('Spatial', cg.PieceSet.spatial),
  celtic('Celtic', cg.PieceSet.celtic),
  pixel('Pixel', cg.PieceSet.pixel),
  firi('Firi', cg.PieceSet.firi),
  rhosgfx('RhosGFX', cg.PieceSet.rhosgfx),
  governor('Governor', cg.PieceSet.governor),
  mpchess('Mpchess', cg.PieceSet.mpchess),
  shapes('Shapes', cg.PieceSet.shapes),
  kiwenSuwi('Kiwen-suwi', cg.PieceSet.kiwenSuwi),
  letter('Letter', cg.PieceSet.letter);

  const PieceDesign(this.label, this.source);
  final String label;
  final cg.PieceSet source;
  cg.PieceAssets get assets => source.assets;
}

const boardStylePreviewFen =
    'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2';

class BoardStylePreview extends StatelessWidget {
  const BoardStylePreview({
    required this.preferences,
    this.coordinates = true,
    this.size = 240,
    super.key,
  });
  final BoardPreferences preferences;
  final bool coordinates;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: cg.StaticChessboard(
      size: size,
      orientation: dc.Side.white,
      fen: boardStylePreviewFen,
      lastMove: dc.NormalMove.fromUci('e7e5'),
      settings: cg.StaticChessboardSettings.fromBoardSettings(
        preferences.interactiveSettings,
      ).copyWith(enableCoordinates: coordinates && preferences.coordinates),
    ),
  );
}

class BoardStylePicker extends StatelessWidget {
  const BoardStylePicker({required this.pieceSets, super.key});
  final bool pieceSets;

  @override
  Widget build(BuildContext context) {
    final controller = BoardPreferencesScope.maybeOf(context)!;
    final preferences = controller.value;
    final strings = l10n(context);
    final colors = Theme.of(context).colorScheme;
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return Scaffold(
      appBar: AppBar(
        title: Text(pieceSets ? strings.boardPieceSet : strings.boardDesign),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.done),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: CustomScrollView(
              key: ValueKey(
                pieceSets ? 'piece-style-grid' : 'board-style-grid',
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      children: [
                        LayoutBuilder(
                          builder: (context, box) => BoardStylePreview(
                            preferences: preferences,
                            size: min(240, box.maxWidth),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            '${preferences.board.label} · ${preferences.pieces.label}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverLayoutBuilder(
                    builder: (context, box) {
                      final columns = (box.crossAxisExtent / (108 * scale))
                          .floor()
                          .clamp(1, 4);
                      final tileWidth =
                          (box.crossAxisExtent - (columns - 1) * 12) / columns;
                      return SliverGrid.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent:
                              (pieceSets ? 76 : tileWidth) + 54 * scale,
                        ),
                        itemCount: pieceSets
                            ? PieceDesign.values.length
                            : BoardDesign.values.length,
                        itemBuilder: (context, index) {
                          final board = pieceSets
                              ? preferences.board
                              : BoardDesign.values[index];
                          final pieces = pieceSets
                              ? PieceDesign.values[index]
                              : preferences.pieces;
                          final selected = pieceSets
                              ? pieces == preferences.pieces
                              : board == preferences.board;
                          final label = pieceSets ? pieces.label : board.label;
                          final choice = preferences.copyWith(
                            board: board,
                            pieces: pieces,
                          );
                          return Semantics(
                            key: ValueKey(
                              'style-${pieceSets ? 'pieces-${pieces.name}' : 'board-${board.name}'}',
                            ),
                            selected: selected,
                            label: label,
                            button: true,
                            onTap: () => unawaited(controller.select(choice)),
                            excludeSemantics: true,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.all(4),
                                backgroundColor: selected
                                    ? colors.secondaryContainer
                                    : null,
                                side: BorderSide(
                                  color: selected
                                      ? colors.primary
                                      : colors.outlineVariant,
                                  width: selected ? 2 : 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () =>
                                  unawaited(controller.select(choice)),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: pieceSets
                                          ? _PieceSetSample(preferences: choice)
                                          : SizedBox.square(
                                              dimension: tileWidth - 12,
                                              child: board.scheme.background,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (selected) ...[
                                        const Icon(Icons.check, size: 16),
                                        const SizedBox(width: 4),
                                      ],
                                      Flexible(
                                        child: Text(
                                          label,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                if (controller.persistenceFailed)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(strings.boardPreferenceError),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PieceSetSample extends StatelessWidget {
  const _PieceSetSample({required this.preferences});
  final BoardPreferences preferences;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final square = min(box.maxWidth / 3, box.maxHeight / 2);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final side in dc.Side.values)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (index, role) in [
                  dc.Role.king,
                  dc.Role.queen,
                  dc.Role.knight,
                ].indexed)
                  ColoredBox(
                    color: (index + side.index).isEven
                        ? preferences.board.scheme.lightSquare
                        : preferences.board.scheme.darkSquare,
                    child: Image(
                      image: preferences
                          .pieces
                          .assets[dc.Piece(color: side, role: role).kind]!,
                      width: square,
                      height: square,
                      excludeFromSemantics: true,
                    ),
                  ),
              ],
            ),
        ],
      );
    },
  );
}

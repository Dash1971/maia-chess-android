import 'package:chessground/chessground.dart' as cg;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:maia_chess/l10n/app_localizations.dart';

void main() {
  test('draft FEN retains counters and EP; failed load is atomic', () {
    final draft = BoardEditorDraft('4k3/8/8/3pP3/8/8/8/4K3 w - d6 17 42');
    expect(draft.fen, endsWith('w - d6 17 42'));
    final before = draft.fen;
    expect(() => draft.load('8/8/8/8/8/8/8/8 w - a9 0 1'), throwsA(anything));
    expect(draft.fen, before);
    draft.load('4k3/8/8/3pP3/8/8/8/4K3');
    expect(draft.fen, before);
    draft.turn = dc.Side.black;
    expect(draft.fen, endsWith('b - d6 17 42'));
  });
  test(
    'draft permits missing/extra kings but validates only a final position',
    () {
      final draft = BoardEditorDraft(dc.Chess.initial.fen)..clear();
      draft.edit(
        dc.Square.e1,
        const dc.Piece(color: dc.Side.white, role: dc.Role.king),
      );
      draft.edit(
        dc.Square.e2,
        const dc.Piece(color: dc.Side.white, role: dc.Role.king),
      );
      expect(draft.pieces.length, 2);
      expect(draft.validatedFen, throwsA(anything));
      draft.pieces.remove(dc.Square.e2);
      draft.edit(
        dc.Square.e8,
        const dc.Piece(color: dc.Side.black, role: dc.Role.king),
      );
      expect(draft.validatedFen(), draft.fen);
    },
  );
  test(
    'repeat placement toggles; movements preserve unrelated pieces and clocks',
    () {
      final draft = BoardEditorDraft(dc.Chess.initial.fen);
      const knight = dc.Piece(color: dc.Side.white, role: dc.Role.knight);
      draft.edit(dc.Square.d4, knight);
      draft.edit(dc.Square.d4, knight);
      expect(draft.pieces[dc.Square.d4], isNull);
      draft.move(dc.Square.b1, dc.Square.d4, knight);
      expect(draft.pieces[dc.Square.b1], isNull);
      expect(draft.pieces[dc.Square.d4], knight);
      expect(draft.pieces[dc.Square.e1]?.role, dc.Role.king);
      expect(draft.fullmoves, 1);
      draft.pieces.remove(dc.Square.h1);
      expect(draft.fen.split(' ')[2], 'Qkq');
    },
  );

  Widget app({
    String? fen,
    Future<void> Function(String)? onContinue,
    Locale locale = const Locale('en'),
    double scale = 1,
  }) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: BoardEditorPage(
      initialFen: fen ?? dc.Chess.initial.fen,
      onContinue: onContinue,
    ),
  );
  cg.ChessboardEditor board(WidgetTester tester) =>
      tester.widget(find.byType(cg.ChessboardEditor));
  Offset point(WidgetTester tester, dc.Square square) {
    final b = board(tester);
    final white = b.orientation == dc.Side.white;
    return tester.getTopLeft(find.byType(cg.ChessboardEditor)) +
        Offset(
          (white ? square.file + .5 : 7.5 - square.file) * b.size / 8,
          (white ? 7.5 - square.rank : square.rank + .5) * b.size / 8,
        );
  }

  for (final flipped in [false, true]) {
    testWidgets('real touch/palette drag/move/erase (flipped=$flipped)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      if (flipped) {
        await tester.tap(find.byKey(const ValueKey('board-editor-flip')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const ValueKey('editor-knight-white')));
      await tester.pumpAndSettle();
      await tester.tapAt(point(tester, dc.Square.d4));
      await tester.pumpAndSettle();
      expect(board(tester).pieces[dc.Square.d4]?.role, dc.Role.knight);
      await tester.tapAt(point(tester, dc.Square.d4));
      await tester.pumpAndSettle();
      expect(board(tester).pieces[dc.Square.d4], isNull);
      final palette = find.byKey(const ValueKey('editor-queen-black'));
      final from = tester.getCenter(palette), to = point(tester, dc.Square.d4);
      await tester.dragFrom(from, to - from);
      await tester.pumpAndSettle();
      expect(
        board(tester).pieces[dc.Square.d4],
        const dc.Piece(color: dc.Side.black, role: dc.Role.queen),
      );
      final a = point(tester, dc.Square.d4), b = point(tester, dc.Square.e4);
      await tester.dragFrom(a, b - a);
      await tester.pumpAndSettle();
      expect(board(tester).pieces[dc.Square.d4], isNull);
      expect(board(tester).pieces[dc.Square.e4]?.role, dc.Role.queen);
      await tester.tap(find.byKey(const ValueKey('editor-erase-white')));
      await tester.pumpAndSettle();
      await tester.tapAt(point(tester, dc.Square.e4));
      await tester.pumpAndSettle();
      expect(board(tester).pieces[dc.Square.e4], isNull);
    });
  }
  testWidgets(
    'position settings expose four castling rights and preserve counters',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('editor-settings')));
      await tester.pumpAndSettle();
      for (final right in ['K', 'Q', 'k', 'q']) {
        expect(find.byKey(ValueKey('editor-castle-$right')), findsOneWidget);
      }
      await tester.tap(find.byKey(const ValueKey('editor-castle-K')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('editor-turn-black')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('FEN metadata'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('editor-fullmove')));
      await tester.enterText(
        find.byKey(const ValueKey('editor-fullmove')),
        '42',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Done'));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('editor-share')));
      await tester.pumpAndSettle();
      expect(find.text('Share FEN'), findsOneWidget);
      expect(find.text('Copy FEN'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'incomplete analysis/continuation is blocked without leaving the editor',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        app(
          fen: '8/8/8/8/8/8/8/8 w - - 7 12',
          onContinue: (_) async {
            calls++;
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('editor-analyze')));
      await tester.pumpAndSettle();
      expect(find.byType(BoardEditorPage), findsOneWidget);
      expect(
        find.text('Invalid position. Check the board and FEN.'),
        findsOneWidget,
      );
      ScaffoldMessenger.of(tester.element(find.byType(BoardEditorPage)))
          .removeCurrentSnackBar();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('editor-menu')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Variant'), findsNothing);
      expect(find.textContaining('Challenge'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('editor-menu-continue')));
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.byType(BoardEditorPage), findsOneWidget);
    },
  );
  testWidgets(
    'continuation receives the edited FEN through the existing callback',
    (tester) async {
      String? continuation;
      await tester.pumpWidget(
        app(
          onContinue: (fen) async {
            continuation = fen;
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('editor-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('editor-menu-continue')));
      await tester.pumpAndSettle();
      expect(continuation, dc.Chess.initial.fen);
      expect(find.byType(BoardEditorPage), findsOneWidget);
    },
  );
  // These are whole singular phrases, not the plural White/Black player labels
  // joined to a role. King/queen exercise both grammatical genders where needed.
  const pieceNames = {
    'en': ['White king', 'White queen', 'Black king', 'Black queen'],
    'es': ['Rey blanco', 'Dama blanca', 'Rey negro', 'Dama negra'],
    'pt': ['Rei branco', 'Dama branca', 'Rei preto', 'Dama preta'],
    'fr': ['Roi blanc', 'Dame blanche', 'Roi noir', 'Dame noire'],
    'de': ['Weißer König', 'Weiße Dame', 'Schwarzer König', 'Schwarze Dame'],
    'ru': ['Белый король', 'Белый ферзь', 'Чёрный король', 'Чёрный ферзь'],
    'hi': ['सफेद राजा', 'सफेद वज़ीर', 'काला राजा', 'काला वज़ीर'],
    'ja': ['白のキング', '白のクイーン', '黒のキング', '黒のクイーン'],
    'ko': ['백 킹', '백 퀸', '흑 킹', '흑 퀸'],
    'zh': ['白王', '白后', '黑王', '黑后'],
  };
  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
      '${locale.languageCode} editor uses singular coloured-piece labels',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(app(locale: locale));
          await tester.pumpAndSettle();
          const kinds = [
            dc.PieceKind.whiteKing,
            dc.PieceKind.whiteQueen,
            dc.PieceKind.blackKing,
            dc.PieceKind.blackQueen,
          ];
          const squares = ['e1', 'd1', 'e8', 'd8'];
          final expected = pieceNames[locale.languageCode]!;
          for (var i = 0; i < kinds.length; i++) {
            final kind = kinds[i];
            final tool = find.byKey(
              ValueKey('editor-${kind.role.name}-${kind.side.name}'),
            );
            expect(tester.getSemantics(tool).label, expected[i]);
            final tooltip = tester.widget<Tooltip>(
              find.descendant(of: tool, matching: find.byType(Tooltip)),
            );
            expect(tooltip.message, expected[i]);
            final square = find.byKey(ValueKey('editor-square-${squares[i]}'));
            expect(
              tester.getSemantics(square).label,
              '${squares[i]}: ${expected[i]}',
            );
          }
          // Every kind is present, distinct, and translated; no generic fallback.
          final labels = <String>{};
          for (final kind in dc.PieceKind.values) {
            final tool = find.byKey(
              ValueKey('editor-${kind.role.name}-${kind.side.name}'),
            );
            final label = tester.getSemantics(tool).label;
            expect(label, isNotEmpty);
            labels.add(label);
          }
          expect(labels, hasLength(12));
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
      '${locale.languageCode} editor and sheet fit narrow/landscape at 200%',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        for (final size in [const Size(320, 640), const Size(640, 320)]) {
          tester.view.physicalSize = size;
          await tester.pumpWidget(app(locale: locale, scale: 2));
          await tester.pumpAndSettle();
          expect(board(tester).size, greaterThan(150));
          await tester.tap(find.byKey(const ValueKey('editor-settings')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}

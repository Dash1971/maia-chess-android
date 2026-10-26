import 'package:chessground/chessground.dart' as cg;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:maia_chess/main.dart';
import 'package:maia_chess/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android editor touch, palette drag, board drag, flip and clipboard',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BoardEditorPage(initialFen: dc.Chess.initial.fen),
        ),
      );
      await tester.pumpAndSettle();
      cg.ChessboardEditor board() =>
          tester.widget(find.byType(cg.ChessboardEditor));
      Offset point(dc.Square square) {
        final b = board();
        final white = b.orientation == dc.Side.white;
        return tester.getTopLeft(find.byType(cg.ChessboardEditor)) +
            Offset(
              (white ? square.file + .5 : 7.5 - square.file) * b.size / 8,
              (white ? 7.5 - square.rank : square.rank + .5) * b.size / 8,
            );
      }

      for (final flip in [false, true]) {
        if (flip) {
          await tester.tap(find.byKey(const ValueKey('board-editor-flip')));
          await tester.pumpAndSettle();
        }
        final knight = find.byKey(const ValueKey('editor-knight-white'));
        await tester.tap(knight);
        await tester.pumpAndSettle();
        await tester.tapAt(point(dc.Square.d4));
        await tester.pumpAndSettle();
        expect(board().pieces[dc.Square.d4]?.role, dc.Role.knight);
        await tester.tapAt(point(dc.Square.d4));
        await tester.pumpAndSettle();
        expect(board().pieces[dc.Square.d4], isNull);
        await tester.dragFrom(
          tester.getCenter(knight),
          point(dc.Square.d4) - tester.getCenter(knight),
        );
        await tester.pumpAndSettle();
        expect(board().pieces[dc.Square.d4]?.role, dc.Role.knight);
        await tester.dragFrom(
          point(dc.Square.d4),
          point(dc.Square.f5) - point(dc.Square.d4),
        );
        await tester.pumpAndSettle();
        expect(board().pieces[dc.Square.d4], isNull);
        expect(board().pieces[dc.Square.f5]?.role, dc.Role.knight);
        await tester.tap(find.byKey(const ValueKey('editor-erase-white')));
        await tester.pumpAndSettle();
        await tester.tapAt(point(dc.Square.f5));
        await tester.pumpAndSettle();
        expect(board().pieces[dc.Square.f5], isNull);
      }
      await tester.tap(find.byKey(const ValueKey('editor-share')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy FEN'));
      await tester.pumpAndSettle();
      expect(
        (await Clipboard.getData(Clipboard.kTextPlain))?.text,
        dc.Chess.initial.fen,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

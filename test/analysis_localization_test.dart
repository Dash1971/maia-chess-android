import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:maia_chess/main.dart';

void main() {
  for (final locale in ['ja', 'zh', 'ko', 'es', 'de', 'fr', 'ru', 'hi', 'pt']) {
    testWidgets('board editor is localized at 200% in $locale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const BoardEditorPage(initialFen: chess.Chess.DEFAULT_POSITION),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(BoardEditorPage));
      final strings = AppLocalizations.of(context)!;
      expect(find.text(strings.editBoard), findsOneWidget);
      expect(find.text(strings.pieceKing), findsOneWidget);
      expect(find.text(strings.whitePieces), findsOneWidget);
      expect(find.text('Edit Board'), findsNothing);
      expect(tester.takeException(), isNull);
    });
    testWidgets('classification labels use the selected locale in $locale', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MoveClassificationSummary(
              moves: const [
                ClassifiedMove(
                  ply: 1,
                  classification: MoveClassification.brilliant,
                ),
              ],
              selectedPly: 0,
              onSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(MoveClassificationSummary));
      final strings = AppLocalizations.of(context)!;
      expect(find.text(strings.classificationBrilliant), findsOneWidget);
      expect(find.text('Brilliant'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}

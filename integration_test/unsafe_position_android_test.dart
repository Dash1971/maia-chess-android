import 'dart:typed_data';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:maia_chess/main.dart';
import 'package:maia_chess/l10n/app_localizations.dart';

const reportedFen =
    'r1bqk1nr/ppppbppp/2n5/4R3/4R3/4RN2/PPPP1PPP/RNBQKB1R w KQkq - 0 1';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('unsafe editor position is blocked; real engines still work', (
    tester,
  ) async {
    var continued = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BoardEditorPage(
          initialFen: reportedFen,
          onContinue: (_) async => continued = true,
        ),
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
    await tester.tap(find.byKey(const ValueKey('editor-menu-continue')));
    await tester.pumpAndSettle();
    expect(continued, isFalse);
    expect(find.byType(BoardEditorPage), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    final engine = StockfishAnalyzer.instance;
    for (final fen in [reportedFen, reportedFen.replaceFirst(' w ', ' b ')]) {
      await expectLater(engine.evaluate(fen), throwsFormatException);
      expect(() => MaiaEncoding.historicalTokens([fen]), throwsFormatException);
    }
    // Real FFI/native libraries, not mocks: rejection leaves the queue usable.
    final review = await engine.evaluate(chess.Chess.DEFAULT_POSITION);
    expect(review.evaluation.isFinite, isTrue);
    final prediction = await MaiaInferenceQueue.predict({
      'tokens': MaiaEncoding.historicalTokens([chess.Chess.DEFAULT_POSITION]),
      'selfElo': 1500,
      'opponentElo': 1500,
    }, timeout: const Duration(minutes: 3));
    expect(prediction, isA<Float32List>());
    expect(prediction, hasLength(4352));
    expect(prediction!.every((value) => value.isFinite), isTrue);
    await engine.close();
    expect(tester.takeException(), isNull);
  });
}

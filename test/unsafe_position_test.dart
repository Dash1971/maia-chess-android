import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stockfish_failure_test.dart' show FakeStockfish;

const reportedBoard = 'r1bqk1nr/ppppbppp/2n5/4R3/4R3/4RN2/PPPP1PPP/RNBQKB1R';

class RecordingStockfish extends FakeStockfish {
  final commands = <String>[];
  @override
  set stdin(String command) {
    commands.add(command);
    super.stdin = command;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final unsafe = <String>[
    for (final turn in ['w', 'b']) '$reportedBoard $turn KQkq - 0 1',
    // Under 32 pieces, but nine pawns or promotions without missing pawns.
    '4k3/8/8/8/P7/8/PPPPPPPP/4K3 w - - 0 1',
    '4k3/8/8/8/8/R7/PPPPPPPP/R3K2R w - - 0 1',
    '4k3/8/8/8/8/8/8/8 w - - 0 1',
    '4k3/8/8/8/8/8/8/3KK3 w - - 0 1',
    '4k3/8/8/8/8/8/8/P3K3 w - - 0 1',
    '4k3/8/8/8/8/8/4R3/4K3 w - - 0 1',
    '${chess.Chess.DEFAULT_POSITION}\ngo depth 1',
    '4k3/8/8/8/8/8/8/4K3 w - - 32768 1',
    '4k3/8/8/8/8/8/8/4K3 w - - 0 100001',
    '4k3/8/8/8/8/8/8/4K3 w - - 9999999999999999999999 1',
  ];
  test(
    'surrounding whitespace cannot reach the native command stream',
    () async {
      final native = RecordingStockfish();
      final analyzer = StockfishAnalyzer.withFactory(native.create);
      const fen = chess.Chess.DEFAULT_POSITION;
      await analyzer.evaluate('\n  $fen \t\n');
      expect(
        native.commands.where((command) => command.startsWith('position ')),
        ['position fen $fen'],
      );
      expect(native.commands.any((command) => command.contains('\n')), isFalse);
      expect(
        MaiaEncoding.tokenizeFen('\n $fen \t'),
        MaiaEncoding.tokenizeFen(fen),
      );
      await analyzer.close();
      await native.output.close();
    },
  );
  for (var i = 0; i < unsafe.length; i++) {
    final fen = unsafe[i];
    test(
      'unsafe position $i is rejected at import and both engine boundaries',
      () async {
        expect(() => AnalysisSession.fromFen(fen), throwsFormatException);
        if (!fen.contains('\n')) {
          expect(
            () => AnalysisSession.fromPgn('[SetUp "1"]\n[FEN "$fen"]\n\n*'),
            throwsFormatException,
          );
        }
        expect(
          () => MaiaEncoding.historicalTokens([fen]),
          throwsFormatException,
        );
        expect(
          () => MaiaEncoding.historicalTokens([
            fen,
            chess.Chess.DEFAULT_POSITION,
          ], useMoveHistory: true),
          throwsFormatException,
        );
        final native = FakeStockfish();
        final analyzer = StockfishAnalyzer.withFactory(native.create);
        await expectLater(analyzer.evaluate(fen), throwsFormatException);
        expect(
          native.starts,
          0,
          reason: 'Do not start or send commands to native Stockfish',
        );
        // Rejection must not poison the request queue.
        expect(
          (await analyzer.evaluate(chess.Chess.DEFAULT_POSITION)).evaluation,
          42,
        );
        await analyzer.close();
        await native.output.close();
      },
    );
  }
  for (final fen in [
    chess.Chess.DEFAULT_POSITION,
    // Five rooks are valid if enough pawns could have promoted.
    '4k3/8/8/8/8/RR6/PPPPP3/RR1K3R w - - 0 1',
    '4k3/8/8/8/8/8/8/4K3 w - - 9999 9999',
    '7k/6Q1/6K1/8/8/8/8/8 b - - 0 1',
    '7k/5Q2/6K1/8/8/8/8/8 b - - 0 1',
  ]) {
    test(
      'safe promoted, terminal and boundary position remains supported: $fen',
      () {
        expect(() => AnalysisSession.validateFen(fen), returnsNormally);
        expect(MaiaEncoding.historicalTokens([fen]), hasLength(64 * 97));
      },
    );
  }
  testWidgets(
    'reported board cannot leave editor through Analyze or Continue',
    (tester) async {
      var continued = false;
      final fen = '$reportedBoard w KQkq - 0 1';
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BoardEditorPage(
            initialFen: fen,
            onContinue: (_) async {
              continued = true;
            },
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
      expect(tester.takeException(), isNull);
    },
  );
}

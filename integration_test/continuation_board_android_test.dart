import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:maia_chess/main.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/fixtures/electronic_board.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android continuation handoff preserves FEN and uses real79M after physical match',
    (tester) async {
      expect(appFlavor ?? '', anyOf('', 'stable'));
      const before = 'r3k2r/pppp1ppp/2n5/4P3/8/8/PPP2PPP/R3K2R b KQkq - 0 11';
      const target = 'r3k2r/ppp2ppp/2n5/3pP3/8/8/PPP2PPP/R3K2R w KQkq d6 0 12';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(maiaPlaySidePreferenceKey, PlayerSide.white.name);
      await prefs.setString(
        maiaTimePresetPreferenceKey,
        TimePreset.custom.name,
      );
      await prefs.setInt(maiaCustomMinutesPreferenceKey, 12);
      await prefs.setInt(maiaCustomIncrementPreferenceKey, 4);
      await ActiveSessionStore.clear();
      final board = SimulatedElectronicBoard();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          navigatorObservers: [maiaRouteObserver],
          home: AnalysisBoardPage(
            initialSession: AnalysisSession.fromFen(target),
            historyPrefix: const [before],
            useMoveHistory: true,
            maiaElo: 1500,
            electronicBoardTransport: board,
            evaluator: (_) async => const StockfishReview(0, 'e1d1'),
            maiaEvaluator: (_, _) async => null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> tapKey(String key) async {
        final tile = find.byKey(ValueKey(key));
        final toggle = find.descendant(of: tile, matching: find.byType(Switch));
        final target = toggle.evaluate().isNotEmpty ? toggle : tile;
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      await tapKey('analysis-actions-menu');
      await tester.ensureVisible(find.text('Continue from here'));
      await tester.tap(find.text('Continue from here'));
      await tester.pumpAndSettle();
      await tapKey('continuation-use-board');
      expect(board.connects, 1);
      await tapKey('continuation-start-game');
      var saved = (await ActiveSessionStore.load())!;
      expect(saved['positions'], [target]);
      expect(saved['historyPrefix'], [before]);
      expect(saved['timePreset'], TimePreset.unlimited.name);
      expect(saved['chessnutResetPending'], true);
      expect(saved['uciMoves'], isEmpty);
      expect((saved['pgn'] as String), contains(target));
      expect(board.leds.last, isNotEmpty);
      board.position(target);
      await tester.pumpAndSettle();
      saved = (await ActiveSessionStore.load())!;
      expect(saved['chessnutResetPending'], isNull);
      final position = chess.Chess.fromFEN(target);
      expect(position.move({'from': 'e5', 'to': 'd6'}), isTrue);
      board.position(position.fen);
      for (var n = 0; n < 300; n++) {
        await tester.pump(const Duration(milliseconds: 100));
        saved = (await ActiveSessionStore.load())!;
        if ((saved['uciMoves'] as List).length >= 2) break;
      }
      expect((saved['uciMoves'] as List).length, greaterThanOrEqualTo(2));
      expect((saved['uciMoves'] as List).first, 'e5d6');
      expect((saved['positions'] as List).first, target);
      expect(saved['historyPrefix'], [before]);
      expect(saved['maiaUseMoveHistory'], true);
      expect(
        prefs.getString(maiaTimePresetPreferenceKey),
        TimePreset.custom.name,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await board.close();
    },
  );
}

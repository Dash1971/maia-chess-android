import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:maia_chess/main.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Stable 79M outcome head, independent ratings, header and persistence',
    (tester) async {
      expect(appFlavor ?? '', anyOf('', 'stable'));
      final session = AnalysisSession.fromPgn('1. e4 *');
      final outputs = <int, MaiaInferenceResult>{};
      for (final rating in [1500, 2600]) {
        final watch = Stopwatch()..start();
        final output = await tester.runAsync(
          () => MaiaInferenceQueue.analyze({
            'tokens': MaiaEncoding.historicalTokens([session.positions.first]),
            'selfElo': rating,
            'opponentElo': rating,
          }, timeout: const Duration(minutes: 3)),
        );
        expect(output, isNotNull);
        expect(output!.moveLogits, hasLength(4352));
        final outcome = output.outcome!;
        expect(outcome.loss + outcome.draw + outcome.win, closeTo(1, 1e-8));
        expect(
          outcome.whiteScore(session.positions.first),
          inInclusiveRange(0, 1),
        );
        outputs[rating] = output;
        debugPrint(
          'MAIA_SCORE_NATIVE ${jsonEncode({'rating': rating, 'loss': outcome.loss, 'draw': outcome.draw, 'win': outcome.win, 'elapsedMs': watch.elapsedMilliseconds})}',
        );
      }
      final legacyWatch = Stopwatch()..start();
      final legacy = await tester.runAsync(
        () => MaiaInferenceQueue.predict({
          'tokens': MaiaEncoding.historicalTokens([session.positions.first]),
          'selfElo': 1500,
          'opponentElo': 1500,
        }),
      );
      expect(legacy, hasLength(4352));
      debugPrint('MAIA_SCORE_LEGACY_MS ${legacyWatch.elapsedMilliseconds}');
      final storage = await SharedPreferences.getInstance();
      final previous = storage.getBool(maiaScorePreferenceKey);
      final controller = MaiaScoreController();
      addTearDown(() async {
        controller.dispose();
        if (previous == null) {
          await storage.remove(maiaScorePreferenceKey);
        } else {
          await storage.setBool(maiaScorePreferenceKey, previous);
        }
      });
      await controller.select(false);
      await tester.pumpWidget(
        MaiaScoreScope(
          controller: controller,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ReviewPage(
              positions: [session.positions.first],
              uciMoves: const [],
              sanMoves: const [],
              pgn: '*',
              playerIsWhite: true,
              onHome: () {},
              title: 'Analysis Board',
              maiaElo: 1500,
              secondMaiaElo: 2600,
              evaluator: (_) async => const StockfishReview(0, 'e2e4'),
              maiaInferenceEvaluator: (_, rating) async => outputs[rating],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final panel = tester.getRect(
        find.byKey(const ValueKey('analysis-tab-panel')),
      );
      await controller.select(true);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(const ValueKey('analysis-tab-panel'))),
        panel,
      );
      expect(find.byKey(const ValueKey('maia-score-primary')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('maia-score-secondary')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('maia-score-details')));
      await tester.pumpAndSettle();
      expect(find.text('Maia score'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await storage.reload();
      final restarted = MaiaScoreController();
      await restarted.initialize();
      expect(restarted.enabled, isTrue);
      restarted.dispose();
    },
  );
}

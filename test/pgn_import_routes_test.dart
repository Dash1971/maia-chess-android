import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/variation_navigation_game.dart';

Future<void> _waitForImport(WidgetTester tester) async {
  // Real isolates complete outside the widget test's fake clock.
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final pages = tester.widgetList<ReviewPage>(find.byType(ReviewPage));
    if (pages.any((page) => page.sanMoves.lastOrNull == 'Ra4#')) return;
  }
  fail(
    'PGN import did not open the reported game; '
    '${tester.widgetList<Text>(find.byType(Text)).map((text) => text.data).whereType<String>().where((text) => text.contains("PGN"))}',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, null);
  });

  testWidgets(
    'shared PGN is parsed without sending the mounted screen to an isolate',
    (tester) async {
      var pending = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(maiaEngineChannel, (call) async {
            if (call.method == 'getPendingPgn' && pending) {
              pending = false;
              return variationNavigationPgn;
            }
            return null;
          });
      await tester.pumpWidget(const MaterialApp(home: GamePage()));
      await _waitForImport(tester);
      expect(pending, isFalse);
      expect(find.textContaining('Could not open PGN'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'pasted PGN uses the background parser and retains its variations',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AnalysisBoardPage(
            initialSession: AnalysisSession.start(),
            maiaElo: 1600,
            evaluator: (_) async => const StockfishReview(0, ''),
            maiaEvaluator: (_, _) async => null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('analysis-actions-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Load PGN'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), variationNavigationPgn);
      await tester.tap(find.widgetWithText(FilledButton, 'Load'));
      await _waitForImport(tester);
      expect(find.text('Qc3'), findsOneWidget);
      expect(find.text('Bxf7+'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('file picker PGN import still opens the full game', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          maiaEngineChannel,
          (call) async =>
              call.method == 'openPgnFile' ? variationNavigationPgn : null,
        );
    await tester.pumpWidget(const MaterialApp(home: GamePage()));
    await tester.pumpAndSettle();
    final open = find.text('Open PGN file');
    await tester.ensureVisible(open);
    await tester.tap(open);
    await _waitForImport(tester);
    expect(find.textContaining('Could not open PGN'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

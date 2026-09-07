import 'package:chess/chess.dart' as chess;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ActiveSessionStore.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
  });

  tearDown(() async {
    await ActiveSessionStore.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, null);
  });

  test('material phase uses the documented endgame boundary', () {
    expect(maiaMaterialPhase(chess.Chess.DEFAULT_POSITION), 24);
    expect(maiaMaterialPhase('8/8/8/8/8/8/R6r/K6k w - - 0 1'), 4);
    expect(maiaMaterialPhase('7q/8/8/8/8/8/Q7/K6k w - - 0 1'), 8);
    expect(maiaMaterialPhase('6nq/8/8/8/8/8/QN6/K6k w - - 0 1'), 10);
    expect(isMaiaDrawOfferEndgame('7q/8/8/8/8/8/Q7/K6k w - - 0 1'), isTrue);
    expect(isMaiaDrawOfferEndgame('6nq/8/8/8/8/8/QN6/K6k w - - 0 1'), isFalse);
  });

  test('Maia accepts equality or worse and declines a real advantage', () {
    const endgame = '8/8/8/8/8/7k/R7/K7 w - - 0 1';
    expect(
      shouldMaiaAcceptDraw(
        fen: endgame,
        maiaIsWhite: false,
        whiteEvaluation: -30,
      ),
      isTrue,
    );
    expect(
      shouldMaiaAcceptDraw(
        fen: endgame,
        maiaIsWhite: false,
        whiteEvaluation: -31,
      ),
      isFalse,
    );
    expect(
      shouldMaiaAcceptDraw(
        fen: endgame,
        maiaIsWhite: false,
        whiteEvaluation: 250,
      ),
      isTrue,
    );
    expect(
      shouldMaiaAcceptDraw(
        fen: endgame,
        maiaIsWhite: false,
        whiteEvaluation: 0,
        whiteMate: -2,
      ),
      isFalse,
    );
    expect(
      shouldMaiaAcceptDraw(
        fen: endgame,
        maiaIsWhite: false,
        whiteEvaluation: 0,
        whiteMate: 2,
      ),
      isTrue,
    );
  });

  testWidgets('last side and time-control settings survive a restart', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: GamePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Random'));
    await tester.pump();
    await tester.tap(find.text('Unlimited'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom').last);
    await tester.pumpAndSettle();

    final sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
    sliders[1].onChanged!(17);
    sliders[1].onChangeEnd!(17);
    sliders[2].onChanged!(6);
    sliders[2].onChangeEnd!(6);
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(maiaPlaySidePreferenceKey), 'random');
    expect(preferences.getString(maiaTimePresetPreferenceKey), 'custom');
    expect(preferences.getInt(maiaCustomMinutesPreferenceKey), 17);
    expect(preferences.getInt(maiaCustomIncrementPreferenceKey), 6);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: GamePage()));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SegmentedButton<PlayerSide>>(
            find.byType(SegmentedButton<PlayerSide>),
          )
          .selected,
      {PlayerSide.random},
    );
    expect(find.text('Minutes: 17'), findsOneWidget);
    expect(find.text('Increment: 6 seconds'), findsOneWidget);
  });

  testWidgets('an accepted offer records a draw by agreement', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const fen = '8/8/8/8/8/7k/R7/K7 w - - 0 1';

    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(
          startingFen: fen,
          startingSide: PlayerSide.white,
          drawEvaluator: (_) async => const StockfishReview(0, 'a2a3'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('game-actions-menu')));
    await tester.pumpAndSettle();
    expect(find.text('Offer draw'), findsOneWidget);
    await tester.tap(find.text('Offer draw'));
    await tester.pumpAndSettle();
    expect(find.text('Offer draw?'), findsOneWidget);
    await tester.tap(find.text('Offer draw'));
    await tester.pumpAndSettle();

    expect(find.text('The game is a draw'), findsOneWidget);
    final saved = await ActiveSessionStore.load();
    expect(saved!['forcedResult'], '1/2-1/2');
    expect(saved['pgn'], contains('[Termination "Draw by agreement"]'));
    expect(saved['pgn'], contains('[Result "1/2-1/2"]'));
  });

  testWidgets('a declined offer cannot repeat in the unchanged position', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const fen = '8/8/8/8/8/7k/R7/K7 w - - 0 1';

    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(
          startingFen: fen,
          startingSide: PlayerSide.white,
          drawEvaluator: (_) async => const StockfishReview(-31, 'h3g3'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('game-actions-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Offer draw'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Offer draw'));
    await tester.pumpAndSettle();
    expect(find.text('Maia declined the draw.'), findsWidgets);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('game-actions-menu')));
    await tester.pumpAndSettle();
    expect(find.text('Offer draw'), findsNothing);
  });

  testWidgets('evaluation label follows the advantaged side when flipped', (
    tester,
  ) async {
    Future<double> labelY(dc.Side orientation, int evaluation) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: EvaluationBar(
                evaluation: evaluation,
                orientation: orientation,
              ),
            ),
          ),
        ),
      );
      return tester
          .getCenter(find.byKey(const ValueKey('evaluation-score-label')))
          .dy;
    }

    expect(await labelY(dc.Side.white, 100), greaterThan(150));
    expect(await labelY(dc.Side.black, 100), lessThan(150));
    expect(await labelY(dc.Side.white, -100), lessThan(150));
    expect(await labelY(dc.Side.black, -100), greaterThan(150));
  });
}

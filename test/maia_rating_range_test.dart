import 'dart:typed_data';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/launch_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ActiveSessionStore.clear();
    messenger.setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
  });
  tearDown(() async {
    await ActiveSessionStore.clear();
    messenger.setMockMethodCallHandler(maiaEngineChannel, null);
  });

  void largeScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  void expectRange(Slider slider) {
    expect(slider.min, 600);
    expect(slider.max, 2600);
    expect(slider.divisions, 20);
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('home-settings-button')));
    await tester.pumpAndSettle();
  }

  Slider ratingSlider(WidgetTester tester, String label) =>
      tester.widget<Slider>(
        find.descendant(
          of: find.ancestor(
            of: find.text(label),
            matching: find.byType(ListTile),
          ),
          matching: find.byType(Slider),
        ),
      );

  testWidgets('2600 reaches both analysis engines through the real channel', (
    tester,
  ) async {
    largeScreen(tester);
    final received = <int>[];
    messenger.setMockMethodCallHandler(maiaEngineChannel, (call) async {
      if (call.method == 'predict') {
        final arguments = Map<Object?, Object?>.from(call.arguments as Map);
        received.add(arguments['selfElo'] as int);
        expect(arguments['opponentElo'], arguments['selfElo']);
        return Float32List(4352);
      }
      return null;
    });
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          positions: const [chess.Chess.DEFAULT_POSITION],
          uciMoves: const [],
          sanMoves: const [],
          playerIsWhite: true,
          pgn: '*',
          onHome: () {},
          maiaElo: 2600,
          secondMaiaElo: 2600,
          stockfishAnalyzer: StockfishAnalyzer.withFactory(
            () async => throw StateError('No native Stockfish in widget test'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(received, [2600, 2600]);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    for (final startingRating in [500, 2600, 5000]) {
      final received = <int>[];
      SharedPreferences.setMockInitialValues({'humanTiming': false});
      messenger.setMockMethodCallHandler(maiaEngineChannel, (call) async {
        if (call.method == 'predict') {
          received.add((call.arguments as Map)['selfElo'] as int);
          expect((call.arguments as Map)['opponentElo'], received.last);
          return Float32List(4352);
        }
        return null;
      });
      await tester.pumpWidget(
        MaterialApp(
          home: GamePage(
            startingFen: chess.Chess.DEFAULT_POSITION,
            startingSide: PlayerSide.black,
            startingElo: startingRating,
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(received, [normalizeMaiaRating(startingRating)]);
      expect(
        (await ActiveSessionStore.load())?['elo'],
        normalizeMaiaRating(startingRating),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  for (final rating in [500, 600, 650, 1600, 2400, 2500, 2600]) {
    testWidgets('all saved ratings $rating reload and legacy 500 migrates', (
      tester,
    ) async {
      largeScreen(tester);
      SharedPreferences.setMockInitialValues({
        maiaPlayEloPreferenceKey: rating,
        'analysisElo': rating,
        secondMaiaEloPreferenceKey: rating,
        secondMaiaEnabledPreferenceKey: true,
      });
      final expected = rating == 500 ? 600 : rating;
      for (var restart = 0; restart < 2; restart++) {
        await tester.pumpWidget(const MaterialApp(home: GamePage()));
        await tester.pumpAndSettle();
        expect(find.text('Play Maia rating: $expected'), findsOneWidget);
        final play = tester.widget<Slider>(find.byType(Slider).first);
        expectRange(play);
        expect(play.value, expected);
        await openSettings(tester);
        for (final label in [
          'Maia analysis rating: $expected',
          'Second Maia analysis rating: $expected',
        ]) {
          expectRange(ratingSlider(tester, label));
          expect(ratingSlider(tester, label).value, expected);
        }
        final preferences = await SharedPreferences.getInstance();
        for (final key in [
          maiaPlayEloPreferenceKey,
          'analysisElo',
          secondMaiaEloPreferenceKey,
        ]) {
          expect(preferences.getInt(key), expected);
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    });
  }

  for (final invalid in <Object>['2600', 2600.0, 500.0, true, 400, 550, 2700]) {
    testWidgets('invalid rating $invalid resets without slider exceptions', (
      tester,
    ) async {
      largeScreen(tester);
      SharedPreferences.setMockInitialValues({
        maiaPlayEloPreferenceKey: invalid,
        'analysisElo': invalid,
        secondMaiaEloPreferenceKey: invalid,
        secondMaiaEnabledPreferenceKey: true,
      });
      await tester.pumpWidget(const MaterialApp(home: GamePage()));
      await tester.pumpAndSettle();
      expect(find.text('Play Maia rating: 1500'), findsOneWidget);
      await openSettings(tester);
      expect(find.text('Maia analysis rating: 1600'), findsOneWidget);
      expect(find.text('Second Maia analysis rating: 2400'), findsOneWidget);
      final preferences = await SharedPreferences.getInstance();
      for (final key in [
        maiaPlayEloPreferenceKey,
        'analysisElo',
        secondMaiaEloPreferenceKey,
      ]) {
        expect(preferences.containsKey(key), isFalse);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Play and both analysis sliders persist the new upper endpoint', (
    tester,
  ) async {
    largeScreen(tester);
    SharedPreferences.setMockInitialValues({
      secondMaiaEnabledPreferenceKey: true,
    });
    await tester.pumpWidget(const MaterialApp(home: GamePage()));
    await tester.pumpAndSettle();
    final play = tester.widget<Slider>(find.byType(Slider).first);
    play.onChanged!(2600);
    play.onChangeEnd!(2600);
    await tester.pumpAndSettle();
    await openSettings(tester);
    for (final label in [
      'Maia analysis rating: 1600',
      'Second Maia analysis rating: 2400',
    ]) {
      final slider = ratingSlider(tester, label);
      slider.onChanged!(2600);
      slider.onChangeEnd!(2600);
      await tester.pumpAndSettle();
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const MaterialApp(home: GamePage()));
    await tester.pumpAndSettle();
    expect(find.text('Play Maia rating: 2600'), findsOneWidget);
    await openSettings(tester);
    expect(find.text('Maia analysis rating: 2600'), findsOneWidget);
    expect(find.text('Second Maia analysis rating: 2600'), findsOneWidget);
  });

  for (final rating in [500, 2600]) {
    testWidgets('Continue defaults $rating migrate and upper endpoint starts', (
      tester,
    ) async {
      largeScreen(tester);
      SharedPreferences.setMockInitialValues({
        maiaPlayEloPreferenceKey: rating,
      });
      await tester.pumpWidget(
        MaterialApp(
          home: AnalysisBoardPage(
            initialSession: AnalysisSession.fromFen(
              chess.Chess.DEFAULT_POSITION,
            ),
            maiaElo: 1600,
            evaluator: (_) async => const StockfishReview(0, 'e2e4'),
            maiaEvaluator: (_, _) async => null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('analysis-actions-menu')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continue from here'));
      await tester.tap(find.text('Continue from here'));
      await tester.pumpAndSettle();
      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('continuation-rating')),
      );
      expectRange(slider);
      expect(slider.value, rating == 500 ? 600 : 2600);
      slider.onChanged!(2600);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('continuation-start-game')));
      await tester.pumpAndSettle();
      expect(tester.widget<GamePage>(find.byType(GamePage)).startingElo, 2600);
      expect((await ActiveSessionStore.load())?['elo'], 2600);
      expect(
        (await SharedPreferences.getInstance()).getInt(
          maiaPlayEloPreferenceKey,
        ),
        rating == 500 ? 600 : 2600,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }

  for (final type in ['analysis', 'review']) {
    for (final savedRating in <Object?>[500, 650, 2600, '2600', 2700, null]) {
      testWidgets('$type restore validates analysis ratings $savedRating', (
        tester,
      ) async {
        largeScreen(tester);
        SharedPreferences.setMockInitialValues({
          'analysisElo': 1700,
          secondMaiaEloPreferenceKey: 2200,
          secondMaiaEnabledPreferenceKey: true,
        });
        final session = AnalysisSession.fromFen(
          '8/8/8/8/8/4k3/8/4K3 w - - 0 1',
        );
        await ActiveSessionStore.save({
          'type': type,
          'session': session.toJson(),
          'maiaElo': savedRating,
          'secondMaiaElo': savedRating,
          'treeIsAuthoritative': true,
          'variations': <Object?>[],
        });
        await tester.pumpWidget(const MaterialApp(home: GamePage()));
        await tester.pumpAndSettle();
        final primary = savedRating == 500
            ? 600
            : savedRating is int && savedRating >= 600 && savedRating <= 2600
            ? savedRating
            : 1700;
        final secondary = savedRating == null
            ? null
            : savedRating == 500
            ? 600
            : savedRating is int && savedRating >= 600 && savedRating <= 2600
            ? savedRating
            : 2200;
        final review = tester.widget<ReviewPage>(find.byType(ReviewPage));
        expect(review.maiaElo, primary);
        expect(review.secondMaiaElo, secondary);
        expect(review.positions, session.positions);
        expect(AnalysisSession.fromPgn(review.pgn).positions, session.positions);
        expect(review.initialTreeIsAuthoritative, isTrue);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      });
    }
  }

  testWidgets('legacy active-game rating stays 500 until a new game starts', (
    tester,
  ) async {
    largeScreen(tester);
    SharedPreferences.setMockInitialValues({maiaPlayEloPreferenceKey: 500});
    await ActiveSessionStore.save({
      ...gameRecord(preset: 'unlimited'),
      'elo': 500,
      'pgn': '[White "Player"]\n[Black "Maia-3 79M (500)"]\n[Result "*"]\n\n*',
    });
    await tester.pumpWidget(const MaterialApp(home: GamePage()));
    await tester.pumpAndSettle();
    expect((await ActiveSessionStore.load())?['elo'], 500);
    expect(
      (await SharedPreferences.getInstance()).getInt(maiaPlayEloPreferenceKey),
      600,
    );
    await tester.tap(find.byKey(const ValueKey('game-home-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue').last);
    await tester.pumpAndSettle();
    expect(find.text('Play Maia rating: 600'), findsOneWidget);
    expectRange(tester.widget<Slider>(find.byType(Slider).first));
    expect(await ActiveSessionStore.load(), isNull);
    await openSettings(tester);
    expect(await ActiveSessionStore.load(), isNull);
    await tester.tap(find.byKey(const ValueKey('settings-back-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start game'));
    await tester.pumpAndSettle();
    expect((await ActiveSessionStore.load())?['elo'], 600);
    expect(
      (await ActiveSessionStore.load())?['pgn'],
      contains('Maia-3 79M (600)'),
    );
    expect(tester.takeException(), isNull);
  });
}

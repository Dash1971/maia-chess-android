import 'dart:typed_data';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final start = chess.Chess.DEFAULT_POSITION;
  final game = chess.Chess()..move('e4');
  final afterE4 = game.fen;
  final captures = <List<double>>[];
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ActiveSessionStore.clear();
    captures.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, (call) async {
          if (call.method == 'predict') {
            expect(call.arguments['tokens'], isA<Float32List>());
            captures.add(
              (call.arguments['tokens'] as List)
                  .cast<num>()
                  .map((v) => v.toDouble())
                  .toList(),
            );
            return Float32List(4352);
          }
          return null;
        });
  });
  tearDown(() async {
    await ActiveSessionStore.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, null);
  });
  test(
    'restored prefix requires a legal chain and at most seven positions',
    () {
      expect(restoreMaiaHistoryPrefix([start], afterE4), [start]);
      for (final invalid in [
        null,
        'invalid',
        [1],
        ['not a fen'],
        [afterE4],
        List.filled(8, start),
      ]) {
        expect(restoreMaiaHistoryPrefix(invalid, afterE4), isEmpty);
      }
    },
  );
  testWidgets(
    'continuation encodes frozen on/off history and restores snapshots',
    (tester) async {
      for (final enabled in [false, true]) {
        captures.clear();
        await ActiveSessionStore.clear();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('maiaUseMoveHistoryV1', !enabled);
        await tester.pumpWidget(
          MaterialApp(
            home: GamePage(
              startingFen: afterE4,
              startingSide: PlayerSide.white,
              startingUseMoveHistory: enabled,
              startingPositionHistory: [start, afterE4],
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (var i = 0; i < 50 && captures.isEmpty; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump();
        }
        expect(captures, hasLength(1));
        expect(
          captures.single,
          MaiaEncoding.historicalTokens([
            start,
            afterE4,
          ], useMoveHistory: enabled),
        );
        final saved = await ActiveSessionStore.load();
        expect(saved!['maiaUseMoveHistory'], enabled);
        expect(saved['historyPrefix'], [start]);
        await prefs.setBool('maiaUseMoveHistoryV1', !enabled);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.pumpWidget(const MaterialApp(home: GamePage()));
        await tester.pumpAndSettle();
        expect(
          (await ActiveSessionStore.load())!['maiaUseMoveHistory'],
          enabled,
        );
        expect((await ActiveSessionStore.load())!['historyPrefix'], [start]);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
      captures.clear();
      await ActiveSessionStore.clear();
      await tester.pumpWidget(
        MaterialApp(
          home: GamePage(
            startingFen: afterE4,
            startingSide: PlayerSide.white,
            startingUseMoveHistory: true,
            startingPositionHistory: ['invalid', afterE4],
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 50 && captures.isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      expect(
        captures.single,
        MaiaEncoding.historicalTokens([afterE4], useMoveHistory: true),
      );
      expect((await ActiveSessionStore.load())!['historyPrefix'], isEmpty);
      final legacy = Map<String, Object?>.from(
        (await ActiveSessionStore.load())!,
      );
      legacy.remove('maiaUseMoveHistory');
      legacy['pgn'] = AnalysisSession.fromFen(afterE4).pgn;
      legacy['positions'] = [afterE4];
      legacy['uciMoves'] = <String>[];
      legacy['clockPaused'] = false;
      legacy['historyPrefix'] = [start];
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await ActiveSessionStore.save(legacy);
      await (await SharedPreferences.getInstance()).setBool(
        'maiaUseMoveHistoryV1',
        true,
      );
      captures.clear();
      await tester.pumpWidget(const MaterialApp(home: GamePage()));
      await tester.pumpAndSettle();
      for (var i = 0; i < 50 && captures.isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(
        captures.single,
        MaiaEncoding.historicalTokens([start, afterE4], useMoveHistory: false),
      );
      expect((await ActiveSessionStore.load())!['maiaUseMoveHistory'], false);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await ActiveSessionStore.clear();
      captures.clear();
      await tester.pumpWidget(
        MaterialApp(
          home: GamePage(
            startingFen: afterE4,
            startingSide: PlayerSide.white,
            startingPositionHistory: [start, afterE4],
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 50 && captures.isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(
        captures.single,
        MaiaEncoding.historicalTokens([start, afterE4], useMoveHistory: true),
      );
      expect((await ActiveSessionStore.load())!['maiaUseMoveHistory'], true);
    },
  );

  testWidgets(
    'saved analysis retains history across navigation and drops context after FEN replacement',
    (tester) async {
      await ActiveSessionStore.save({
        'type': 'analysis',
        'session': AnalysisSession.fromFen(afterE4).toJson(),
        'maiaUseMoveHistory': true,
        'historyPrefix': [start],
        'currentFen': afterE4,
      });
      await tester.pumpWidget(const MaterialApp(home: GamePage()));
      await tester.pumpAndSettle();
      final analysis = tester.widget<AnalysisBoardPage>(
        find.byType(AnalysisBoardPage),
      );
      expect(analysis.useMoveHistory, true);
      expect(analysis.historyPrefix, [start]);
      final review = tester.widget<ReviewPage>(find.byType(ReviewPage));
      expect(review.useMoveHistory, true);
      expect(review.historyPrefix, [start]);
      await tester.tap(find.byKey(const ValueKey('analysis-flip-button')));
      await tester.pumpAndSettle();
      expect((await ActiveSessionStore.load())!['maiaUseMoveHistory'], true);
      expect((await ActiveSessionStore.load())!['historyPrefix'], [start]);
      await tester.tap(find.byKey(const ValueKey('analysis-actions-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Load FEN'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), start);
      await tester.tap(find.text('Load').last);
      await tester.pumpAndSettle();
      expect((await ActiveSessionStore.load())!['historyPrefix'], isEmpty);
      expect((await ActiveSessionStore.load())!['maiaUseMoveHistory'], true);
    },
  );

  testWidgets(
    'saved review preserves its original mode and prefix while navigating',
    (tester) async {
      final session = AnalysisSession.fromPgn(
        '[SetUp "1"]\n[FEN "$afterE4"]\n\n1... e5 *',
      );
      await ActiveSessionStore.save({
        'type': 'review',
        'session': session.toJson(),
        'maiaUseMoveHistory': true,
        'historyPrefix': [start],
        'currentFen': afterE4,
        'playerIsWhite': true,
      });
      await tester.pumpWidget(const MaterialApp(home: GamePage()));
      await tester.pumpAndSettle();
      final page = tester.widget<ReviewPage>(find.byType(ReviewPage));
      expect(page.useMoveHistory, true);
      expect(page.historyPrefix, [start]);
      await tester.tap(find.byKey(const ValueKey('next-move-button')));
      await tester.pumpAndSettle();
      final saved = (await ActiveSessionStore.load())!;
      expect(saved['maiaUseMoveHistory'], true);
      expect(saved['historyPrefix'], [start]);
      expect(saved['currentFen'], session.positions.last);
    },
  );
  testWidgets('reset engine defaults disables persisted history', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'maiaUseMoveHistoryV1': true});
    await tester.pumpWidget(const MaterialApp(home: GamePage()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-settings-button')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SettingsInfoSwitch>(
            find.byKey(const ValueKey('maia-history-setting')),
          )
          .value,
      true,
    );
    await tester.ensureVisible(find.text('Reset settings to default'));
    await tester.tap(find.text('Reset settings to default'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-reset-settings')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SettingsInfoSwitch>(
            find.byKey(const ValueKey('maia-history-setting')),
          )
          .value,
      false,
    );
    expect(
      (await SharedPreferences.getInstance()).getBool('maiaUseMoveHistoryV1'),
      false,
    );
  });
  for (final malformed in [null, 'true', 1]) {
    testWidgets('history preference defaults safely for $malformed', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'maiaUseMoveHistoryV1': ?malformed,
      });
      await tester.pumpWidget(const MaterialApp(home: GamePage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-settings-button')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SettingsInfoSwitch>(
              find.byKey(const ValueKey('maia-history-setting')),
            )
            .value,
        false,
      );
      expect(
        (await SharedPreferences.getInstance()).get('maiaUseMoveHistoryV1'),
        isNull,
      );
    });
  }
}

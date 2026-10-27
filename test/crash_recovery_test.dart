import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'unsafe_position_test.dart' show reportedBoard;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var previousCrash = false;
  setUp(() {
    previousCrash = false;
    SharedPreferences.setMockInitialValues({
      maiaPlayEloPreferenceKey: 1700,
      'sentinelSetting': 'keep',
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          maiaEngineChannel,
          (call) async =>
              call.method == 'previousProcessFailed' ? previousCrash : null,
        );
  });
  tearDown(() {
    ActiveSessionStore.setTestRepository(null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, null);
  });

  test('interrupted auto-restore stays blocked; normal background and explicit new session reset it', () async {
    expect(await ActiveSessionStore.beginAutomaticRestore(), isTrue);
    // A widget recreation within this process is not a crash.
    expect(await ActiveSessionStore.beginAutomaticRestore(), isTrue);
    // Simulate process death: a marker belonging to another process.
    await (await SharedPreferences.getInstance()).setString(
      'sessionRestorePendingV1',
      'previous-process',
    );
    expect(await ActiveSessionStore.beginAutomaticRestore(), isFalse);
    await ActiveSessionStore.finishAutomaticRestore();
    expect(await ActiveSessionStore.beginAutomaticRestore(), isFalse);
    await ActiveSessionStore.startNew();
    expect(await ActiveSessionStore.beginAutomaticRestore(), isTrue);
    await ActiveSessionStore.finishAutomaticRestore();
    expect(await ActiveSessionStore.beginAutomaticRestore(), isTrue);
  });

  for (final source in [
    'native-crash',
    'interrupted-restore',
    'invalid-pgn',
    'invalid-current-fen',
    'invalid-review',
    'invalid-variation',
    'invalid-game',
  ]) {
    testWidgets(
      'Home recovery preserves archive/checkpoint/settings: $source',
      (tester) async {
        final directory = await tester.runAsync(
          () => Directory.systemTemp.createTemp('maia-crash-recovery-'),
        );
        final store = (await tester.runAsync(
          () async => SessionRepository(directory!),
        ))!;
        ActiveSessionStore.setTestRepository(store);
        addTearDown(() async {
          await directory!.delete(recursive: true);
        });
        final good = AnalysisSession.fromPgn('1. f3 e5 2. g4 Qh4# 0-1');
        final saved = <String, Object?>{
          'type': source == 'invalid-review'
              ? 'review'
              : source == 'invalid-game'
              ? 'game'
              : 'analysis',
          if (source == 'invalid-game')
            'pgn': '[SetUp "1"]\n[FEN "$reportedBoard w KQkq - 0 1"]\n\n*',
          if (source == 'invalid-review')
            'activeGame': {'type': 'game', 'pgn': good.pgn},
          if (source == 'invalid-variation')
            'variations': [
              {
                'basePly': 0,
                'baseFen': '$reportedBoard w KQkq - 0 1',
                'sanMoves': <String>[],
              },
            ],
          'session': source == 'invalid-pgn'
              ? {'pgn': '[SetUp "1"]\n[FEN "$reportedBoard w KQkq - 0 1"]\n\n*'}
              : good.toJson(),
          'currentFen':
              ['invalid-current-fen', 'invalid-review'].contains(source)
              ? '$reportedBoard w KQkq - 0 1'
              : good.positions.last,
        };
        late String archiveBefore;
        late String checkpointBefore;
        await tester.runAsync(() async {
          await ActiveSessionStore.save({'type': 'game', 'pgn': good.pgn});
          await ActiveSessionStore.startNew();
          await ActiveSessionStore.save(saved);
          archiveBefore = jsonEncode(
            (await store.recent()).map((e) => [e.id, e.data]).toList(),
          );
          checkpointBefore = jsonEncode(await store.load());
        });
        previousCrash = source == 'native-crash';
        if (source == 'interrupted-restore') {
          await (await SharedPreferences.getInstance()).setString(
            'sessionRestorePendingV1',
            'previous-process',
          );
        }
        for (var restart = 0; restart < 2; restart++) {
          await tester.pumpWidget(const MaiaChessApp());
          // Real filesystem work must run outside the widget fake clock.
          for (var i = 0; i < 15; i++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 10)),
            );
            await tester.pump();
          }
          await tester.pumpAndSettle();
          expect(find.text('Start game'), findsOneWidget);
          expect(find.byType(AnalysisBoardPage), findsNothing);
          expect(find.byType(ReviewPage), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }
        await tester.runAsync(() async {
          expect(
            jsonEncode(await SessionRepository(directory!).load()),
            checkpointBefore,
          );
          expect(
            jsonEncode(
              (await SessionRepository(
                directory,
              ).recent()).map((e) => [e.id, e.data]).toList(),
            ),
            archiveBefore,
          );
        });
        final preferences = await SharedPreferences.getInstance();
        expect(preferences.getString('sentinelSetting'), 'keep');
        expect(preferences.getInt(maiaPlayEloPreferenceKey), 1700);
        // Explicitly opening an unaffected saved game remains possible.
        await tester.runAsync(() async {
          final reopened = SessionRepository(directory!);
          ActiveSessionStore.setTestRepository(reopened);
          final game = (await reopened.recent()).firstWhere(
            (e) => e.data['type'] == 'game' && e.data['pgn'] == good.pgn,
          );
          expect((await ActiveSessionStore.open(game.id))!['pgn'], good.pgn);
        });
        previousCrash = false;
        expect(await ActiveSessionStore.beginAutomaticRestore(), isTrue);
      },
    );
  }
}

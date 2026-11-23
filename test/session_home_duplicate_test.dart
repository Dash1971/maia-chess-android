import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Hold the Home transition after its real disk tombstone is committed. Android
// can background the still-mounted game while the transition is finishing.
class _HeldHomeRepository extends SessionRepository {
  _HeldHomeRepository(super.directory);
  bool hold = false;
  final cleared = Completer<void>();
  final release = Completer<void>();

  @override
  Future<void> startNew({DateTime? gameStartedAt}) async {
    await super.startNew(gameStartedAt: gameStartedAt);
    if (hold) {
      cleared.complete();
      await release.future;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'backgrounding while returning Home cannot copy a finished game',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final dir = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('maia-home-duplicate-'),
      ))!;
      final store = _HeldHomeRepository(dir);
      ActiveSessionStore.setTestRepository(store);
      addTearDown(() async {
        if (!store.release.isCompleted) store.release.complete();
        ActiveSessionStore.setTestRepository(null);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(maiaEngineChannel, null);
        await dir.delete(recursive: true);
      });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
      await tester.runAsync(
        () => store.save({
          'schema': 1,
          'type': 'game',
          'recentState': 'completed',
          'pgn': '[Date "2026.10.14"]\n\n1. f3 e5 2. g4 Qh4# 0-1',
          'playerIsWhite': true,
          'timePreset': 'unlimited',
          'clockPaused': true,
        }),
      );
      final original = (await tester.runAsync(store.recent))!.single.id;
      await tester.pumpWidget(const MaiaChessApp());
      for (var i = 0; i < 100; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump(const Duration(milliseconds: 100));
        if (find
            .byKey(const ValueKey('game-conclusion-dialog'))
            .evaluate()
            .isNotEmpty) {
          break;
        }
      }
      expect(
        find.byKey(const ValueKey('game-conclusion-dialog')),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      store.hold = true;
      await tester.tap(find.byTooltip('Home').first);
      for (var i = 0; i < 100 && !store.cleared.isCompleted; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      expect(store.cleared.isCompleted, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      store.release.complete();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      for (var i = 0; i < 30; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      final saved = (await tester.runAsync(store.recent))!;
      expect(saved.map((game) => game.id).toList(), [original]);
      expect(await tester.runAsync(store.load), isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}

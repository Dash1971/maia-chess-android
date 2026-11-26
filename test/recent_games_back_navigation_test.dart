import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Exercise the real screens and save/clear/open calls without filesystem timing
// or a native engine. SessionRepository's transactional storage has its own tests.
class _Archive extends SessionRepository {
  _Archive() : super(Directory('unused-recent-navigation-test'));

  final records = <String, Map<String, dynamic>>{
    for (var i = 0; i < 80; i++)
      'game-$i': {
        'schema': 1,
        'type': 'game',
        'recentState': i == 41 ? 'incomplete' : 'completed',
        'pgn': i == 41 ? '1. e4 e5 *' : '1. f3 e5 2. g4 Qh4# 0-1',
        'playerIsWhite': true,
        'timePreset': 'unlimited',
        'clockPaused': true,
      },
  };
  String? activeId;
  Map<String, dynamic>? active;
  bool failSave = false;
  Completer<void>? heldSave;

  @override
  Future<bool> hasCheckpoint() async => true;

  @override
  Future<Map<String, dynamic>?> load() async => active;

  @override
  Future<List<RecentSession>> recent({bool restoreBlocked = false}) async => [
    for (final entry in records.entries)
      RecentSession(entry.key, DateTime.utc(2026), entry.value),
  ];

  @override
  Future<Map<String, dynamic>?> open(String id) async {
    activeId = id;
    return active = Map.of(records[id]!);
  }

  @override
  Future<void> save(Map<String, Object?> data) async {
    if (failSave) throw const FileSystemException('test save failure');
    await heldSave?.future;
    active = Map<String, dynamic>.of(data);
    if (activeId != null) records[activeId!] = active!;
  }

  @override
  Future<void> startNew({DateTime? gameStartedAt}) async {
    activeId = null;
    active = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Archive archive;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    archive = _Archive();
    ActiveSessionStore.setTestRepository(archive);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
  });
  tearDown(() {
    ActiveSessionStore.setTestRepository(null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, null);
  });

  Future<void> mount(WidgetTester tester, {bool largeText = false}) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    if (largeText) {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }
    await tester.pumpWidget(const MaiaChessApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Recent games'));
    await tester.tap(find.text('Recent games'));
    await tester.pumpAndSettle();
  }

  Finder row(int id) => find.byKey(ValueKey('recent-game-game-$id'));
  ScrollPosition position(WidgetTester tester) => tester
      .state<ScrollableState>(
        find.descendant(
          of: find.byType(RecentGamesPage),
          matching: find.byType(Scrollable),
        ),
      )
      .position;

  Future<void> open(WidgetTester tester, int id) async {
    await tester.scrollUntilVisible(row(id), 600);
    await tester.pumpAndSettle();
    await tester.tap(row(id));
    await tester.pumpAndSettle();
  }

  Future<void> back(WidgetTester tester, {bool predictive = false}) async {
    if (predictive) {
      for (final method in ['startBackGesture', 'commitBackGesture']) {
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/backgesture',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall(
              method,
              method == 'startBackGesture'
                  ? <String, dynamic>{
                      'touchOffset': <double>[0, 300],
                      'progress': 0.0,
                      'swipeEdge': 0,
                    }
                  : null,
            ),
          ),
          (_) {},
        );
      }
    } else {
      await tester.binding.handlePopRoute();
    }
    await tester.pumpAndSettle();
  }

  for (final largeText in [false, true]) {
    for (final predictive in [false, true]) {
      testWidgets(
        'saved games retain list position: largeText=$largeText predictive=$predictive',
        (tester) async {
          await mount(tester, largeText: largeText);
          await tester.scrollUntilVisible(row(40), 600);
          await tester.pumpAndSettle();
          final offset = position(tester).pixels;
          final rowY = tester.getTopLeft(row(40)).dy;
          expect(offset, greaterThan(0));
          await tester.tap(row(40));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('game-conclusion-dialog')),
            findsOneWidget,
          );
          await back(
            tester,
            predictive: predictive,
          ); // Dismiss the result first.
          expect(find.byType(RecentGamesPage), findsNothing);
          await back(tester, predictive: predictive);
          expect(find.byType(RecentGamesPage), findsOneWidget);
          expect(position(tester).pixels, closeTo(offset, 0.1));
          expect(tester.getTopLeft(row(40)).dy, closeTo(rowY, 0.1));
          expect(archive.active, isNull);
          expect(archive.records['game-40']!['recentState'], 'completed');

          await open(tester, 41);
          await back(tester, predictive: predictive);
          expect(find.text('Leave current game?'), findsOneWidget);
          await back(tester, predictive: predictive); // Cancel.
          expect(find.byType(RecentGamesPage), findsNothing);
          expect(archive.activeId, 'game-41');
          await back(tester, predictive: predictive);
          await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
          await tester.pumpAndSettle();
          expect(find.byType(RecentGamesPage), findsOneWidget);
          expect(archive.records['game-41']!['recentState'], 'incomplete');
          expect(archive.active, isNull);
          expect(archive.records, hasLength(80));
          await back(tester, predictive: predictive);
          expect(find.text('Start game'), findsOneWidget);
        },
      );
    }
  }

  testWidgets(
    'finishing an incomplete saved game still returns to the same list position',
    (tester) async {
      await mount(tester);
      await tester.scrollUntilVisible(row(41), 600);
      await tester.pumpAndSettle();
      final offset = position(tester).pixels;
      final rowY = tester.getTopLeft(row(41)).dy;
      await tester.tap(row(41));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('quick-resign-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Resign'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('game-conclusion-dialog')),
        findsOneWidget,
      );
      await back(tester);
      expect(find.byType(RecentGamesPage), findsNothing);
      await back(tester);
      expect(find.text('Leave current game?'), findsNothing);
      expect(find.byType(RecentGamesPage), findsOneWidget);
      expect(position(tester).pixels, closeTo(offset, 0.1));
      expect(tester.getTopLeft(row(41)).dy, closeTo(rowY, 0.1));
      expect(archive.records['game-41']!['recentState'], 'completed');
      expect(archive.records['game-41']!['forcedResult'], '0-1');
      expect(archive.records, hasLength(80));
      expect(archive.active, isNull);
    },
  );

  testWidgets('Home from a saved game discards the return position', (
    tester,
  ) async {
    await mount(tester);
    await open(tester, 40);
    await back(tester); // Result dialog.
    await tester.tap(find.byKey(const ValueKey('game-home-button')));
    await tester.pumpAndSettle();
    expect(find.text('Start game'), findsOneWidget);
    expect(find.byType(RecentGamesPage), findsNothing);
    await tester.tap(find.text('Recent games'));
    await tester.pumpAndSettle();
    expect(position(tester).pixels, 0);
  });

  for (final home in [false, true]) {
    testWidgets(
      'saved game analysis ${home ? 'Home' : 'Back'} keeps the correct destination',
      (tester) async {
        await mount(tester);
        await open(tester, 40);
        await tester.tap(find.widgetWithText(TextButton, 'Analysis Board'));
        await tester.pumpAndSettle();
        expect(find.byType(ReviewPage), findsOneWidget);
        if (home) {
          await tester.tap(find.byTooltip('Home'));
          await tester.pumpAndSettle();
          expect(find.text('Start game'), findsOneWidget);
          expect(find.byType(RecentGamesPage), findsNothing);
          await tester.tap(find.text('Recent games'));
          await tester.pumpAndSettle();
          expect(position(tester).pixels, 0);
        } else {
          await back(tester);
          expect(find.byType(ReviewPage), findsNothing);
          expect(
            find.byKey(const ValueKey('game-home-button')),
            findsOneWidget,
          );
          await back(tester);
          expect(find.byType(RecentGamesPage), findsOneWidget);
          expect(row(40).hitTestable(), findsOneWidget);
        }
      },
    );
  }

  testWidgets('failed save keeps the game and its return context for retry', (
    tester,
  ) async {
    await mount(tester);
    await open(tester, 40);
    await back(tester);
    archive.failSave = true;
    await back(tester);
    expect(find.byType(RecentGamesPage), findsNothing);
    expect(find.byKey(const ValueKey('game-home-button')), findsOneWidget);
    expect(archive.activeId, 'game-40');
    archive.failSave = false;
    await back(tester);
    expect(find.byType(RecentGamesPage), findsOneWidget);
    expect(row(40).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('repeated Back during saving returns to only one list', (
    tester,
  ) async {
    await mount(tester);
    await open(tester, 40);
    await back(tester);
    archive.heldSave = Completer<void>();
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    archive.heldSave!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(RecentGamesPage), findsOneWidget);
    await back(tester);
    expect(find.byType(RecentGamesPage), findsNothing);
    expect(find.text('Start game'), findsOneWidget);
  });
}

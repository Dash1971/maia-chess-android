import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

const first = '[Event "First"]\n\n1. e4 {keep} e5 (1... c5) *';
const second = '[Event "Second"]\n\n1. d4 d5 *';
const invalid = '[Event "Invalid"]\n\n1. e9 *';

Future<void> until(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 200 && !done(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(done(), isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late SessionRepository store;
  String? picked;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('maia-pgn-destinations-');
    store = SessionRepository(dir);
    ActiveSessionStore.setTestRepository(store);
    picked = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          maiaEngineChannel,
          (call) async => call.method == 'openPgnFile' ? picked : null,
        );
  });
  tearDown(() async {
    ActiveSessionStore.setTestRepository(null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, null);
    await dir.delete(recursive: true);
  });

  test(
    'first-game parser preserves annotations and ignores an invalid later game',
    () async {
      final progress = <double>[];
      final parsed = await PgnCollection.parseFirst(
        '$first\n\n$invalid',
        onProgress: (update) => progress.add(update.fraction),
      );
      expect(parsed.games, [first]);
      expect(parsed.hasMoreGames, isTrue);
      expect(progress.last, 1);
      final session = AnalysisSession.fromPgn(parsed.games.single);
      expect(session.sanMoves, ['e4', 'e5']);
      expect(session.pgn, contains('keep'));
      expect(session.pgn, contains('c5'));
      await expectLater(
        PgnCollection.parse('$first\n\n$invalid'),
        throwsFormatException,
      );
    },
  );

  test(
    'first-game parser does not mistake comments and variations for games',
    () async {
      const source = '1. e4 { [Event "Fake"] 1-0 } e5 (1... c5 { * }) *';
      final parsed = await PgnCollection.parseFirst(source);
      expect(parsed.games, [source]);
      expect(parsed.hasMoreGames, isFalse);
      await expectLater(
        PgnCollection.parseFirst(invalid),
        throwsFormatException,
      );
    },
  );

  test(
    'first-game analysis still enforces the complete file size limit',
    () async {
      final source = '$first\n\n{${'x' * AnalysisSession.maxPgnBytes}}';
      await expectLater(
        PgnCollection.parseFirst(source),
        throwsFormatException,
      );
    },
  );

  Future<void> recent(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    bool large = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(large ? 2 : 1)),
          child: child!,
        ),
        home: const RecentGamesPage(),
      ),
    );
    await until(
      tester,
      () => find.byType(CircularProgressIndicator).evaluate().isEmpty,
    );
    await tester.tap(find.byKey(const ValueKey('recent-games-menu')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'empty Recent games imports a collection and skips repeated content',
    (tester) async {
      await tester.runAsync(
        () => store.save({
          'type': 'game',
          'recentState': 'active',
          'pgn': '1. c4 *',
        }),
      );
      final active = await tester.runAsync(store.load);
      picked = '$first\n\n$second\n\n$first';
      await recent(tester);
      await tester.tap(find.text('Import PGN'));
      await until(
        tester,
        () => find.textContaining('2 games imported').evaluate().isNotEmpty,
      );
      await until(
        tester,
        () => tester
            .widget<PopupMenuButton<String>>(
              find.byKey(const ValueKey('recent-games-menu')),
            )
            .enabled,
      );
      expect(find.textContaining('1 duplicate skipped'), findsOneWidget);
      expect(find.byType(AnalysisBoardPage), findsNothing);
      expect(await tester.runAsync(store.load), active);
      expect(await tester.runAsync(store.recent), hasLength(2));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Recent games imports a single game into the list without opening analysis',
    (tester) async {
      picked = first;
      await recent(tester);
      await tester.tap(find.text('Import PGN'));
      await until(
        tester,
        () => find.text('1 game added to Recent games.').evaluate().isNotEmpty,
      );
      await until(
        tester,
        () => tester
            .widget<PopupMenuButton<String>>(
              find.byKey(const ValueKey('recent-games-menu')),
            )
            .enabled,
      );
      expect(await tester.runAsync(store.recent), hasLength(1));
      expect(await tester.runAsync(store.load), isNull);
      expect(find.byType(AnalysisBoardPage), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Recent games cancellation and invalid collections leave existing games intact',
    (tester) async {
      await tester.runAsync(
        () async => store.importCollection(await PgnCollection.parse(first)),
      );
      await recent(tester);
      await tester.tap(find.text('Import PGN'));
      await tester.pumpAndSettle();
      await until(
        tester,
        () => tester
            .widget<PopupMenuButton<String>>(
              find.byKey(const ValueKey('recent-games-menu')),
            )
            .enabled,
      );
      expect(await tester.runAsync(store.recent), hasLength(1));
      picked = '$second\n\n$invalid';
      await tester.tap(find.byKey(const ValueKey('recent-games-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import PGN'));
      await until(
        tester,
        () => find.text('Could not open PGN.').evaluate().isNotEmpty,
      );
      await until(
        tester,
        () => tester
            .widget<PopupMenuButton<String>>(
              find.byKey(const ValueKey('recent-games-menu')),
            )
            .enabled,
      );
      expect(await tester.runAsync(store.recent), hasLength(1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Analysis Board file menu opens the first game without importing the collection',
    (tester) async {
      picked = '$first\n\n$second';
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
      await tester.tap(find.text('Open PGN file'));
      await until(
        tester,
        () => find
            .textContaining('Only the first game was opened.')
            .evaluate()
            .isNotEmpty,
      );
      await until(
        tester,
        () =>
            tester
                .widget<ReviewPage>(find.byType(ReviewPage))
                .sanMoves
                .length ==
            2,
      );
      final page = tester.widget<ReviewPage>(find.byType(ReviewPage));
      expect(page.sanMoves, ['e4', 'e5']);
      expect(
        await tester.runAsync(() => SessionRepository(dir).recent()),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
      'analysis first-game notice and empty-list import at 320px/200% ${locale.languageCode}',
      (tester) async {
        tester.view.physicalSize = const Size(320, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final strings = await AppLocalizations.delegate.load(locale);
        picked = '$first\n\n$invalid';
        await recent(tester, locale: locale, large: true);
        expect(find.text(strings.recentImportGames), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    final session = await PgnFiles.open(context);
                    expect(session!.sanMoves, ['e4', 'e5']);
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await until(
          tester,
          () => find.text(strings.pgnFirstGameOnly).evaluate().isNotEmpty,
        );
        expect(await tester.runAsync(store.recent), isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }
}

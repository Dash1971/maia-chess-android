import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:maia_chess/main.dart';

RecentSession record(Map<String, dynamic> data, {String id = 'game'}) =>
    RecentSession(id, DateTime.utc(2035), {
      'type': 'game',
      'recentState': 'completed',
      'elo': 1600,
      ...data,
    }, history: const GameHistory(playedOn: '2020-02-29'));

ThemeData theme(Brightness brightness) => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xff5d735f),
    brightness: brightness,
  ),
  scaffoldBackgroundColor: brightness == Brightness.dark
      ? const Color(0xff171a18)
      : null,
  useMaterial3: true,
);

Future<void> showGames(
  WidgetTester tester,
  List<RecentSession> games, {
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.dark,
  double scale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme(brightness),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: RecentGamesPage(loadGames: () async => games),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('player-relative result interpretation', () {
    for (final (white, result, outcome) in [
      (true, '1-0', RecentGameOutcome.win),
      (true, '0-1', RecentGameOutcome.loss),
      (false, '1-0', RecentGameOutcome.loss),
      (false, '0-1', RecentGameOutcome.win),
      (true, '1/2-1/2', RecentGameOutcome.draw),
      (false, '1/2-1/2', RecentGameOutcome.draw),
    ]) {
      test('$white / $result uses saved side despite random/flipped view', () {
        final game = record({
          'playerIsWhite': white,
          'sideChoice': 'random',
          'flipped': white,
          'pgn': '[Result "$result"]\n\n$result',
        });
        expect(game.resultLabel, result);
        expect(game.outcome, outcome);
        expect(game.isIncomplete, isFalse);
      });
    }

    test(
      'missing/invalid side is neutral for decisive games, draw is known',
      () {
        for (final side in [null, 'white', 1]) {
          for (final result in ['1-0', '0-1', '1/2-1/2']) {
            final game = record({
              'playerIsWhite': side,
              'pgn': '[Result "$result"]',
            });
            expect(
              game.outcome,
              result == '1/2-1/2'
                  ? RecentGameOutcome.draw
                  : RecentGameOutcome.unknown,
            );
          }
        }
      },
    );

    test('forced results override PGN; explicit incomplete overrides both', () {
      for (final result in ['1-0', '0-1', '1/2-1/2']) {
        final data = {
          'playerIsWhite': true,
          'forcedResult': result,
          'pgn': '[Result "*"]\n\n1. e4 *',
        };
        expect(record(data).resultLabel, result);
        expect(record({...data, 'pgn': '[Result "0-1"]'}).resultLabel, result);
        final incomplete = record({...data, 'recentState': 'incomplete'});
        expect(incomplete.resultLabel, 'Incomplete');
        expect(incomplete.outcome, RecentGameOutcome.incomplete);
      }
      expect(
        record({
          'playerIsWhite': true,
          'forcedResult': 'invalid',
          'pgn': '[Result "1-0"]',
        }).outcome,
        RecentGameOutcome.unknown,
      );
    });

    test('legacy unfinished and nested completed PGNs remain readable', () {
      expect(
        record({'recentState': null, 'pgn': '[Result "*"]'}).outcome,
        RecentGameOutcome.incomplete,
      );
      final nested = record({
        'recentState': null,
        'playerIsWhite': false,
        'session': {'pgn': '[Result "0-1"]'},
      });
      expect(nested.outcome, RecentGameOutcome.win);
      expect(nested.isIncomplete, isFalse);
    });

    test(
      'ambiguous headers and malformed data never acquire a result color',
      () {
        for (final data in <Map<String, dynamic>>[
          {'pgn': '[Result "1-0"]\n[Result "0-1"]'},
          {'pgn': '[Result "1-0"]\n[Result "1-0"]'},
          {'pgn': '[Result "1-0"]${' ' * 8200}[Result "0-1"]'},
          {'pgn': '[Result "unknown"]'},
          {'pgn': '[Result "1-0"]\n[Result "0-1"'},
          {'pgn': '[Result "1-0"'},
          {'pgn': 17},
          {'session': 'invalid'},
          {'pgn': '[Event "${'x' * 9000}"]\n[Result "1-0"]'},
          {'pgn': '[Event "Game"]\n\n1. e4 {\n[Result "1-0"]\n}'},
        ]) {
          final game = record({'playerIsWhite': true, ...data});
          expect(game.outcome, RecentGameOutcome.unknown, reason: '$data');
          expect(game.resultLabel, 'Completed');
        }
      },
    );

    test(
      'valid BOM and escaped headers work; comments do not override result',
      () {
        final game = record({
          'playerIsWhite': true,
          'pgn':
              '\uFEFF[Event "A \\"quote\\""]\n[Result "1-0"]\n\n'
              '1. e4 {\n[Result "0-1"]\n} 1-0',
        });
        expect(game.outcome, RecentGameOutcome.win);
        expect(game.resultLabel, '1-0');
      },
    );
  });

  for (final brightness in Brightness.values) {
    test('result colors have 4.5:1 subtitle contrast in $brightness', () {
      final t = theme(brightness);
      for (final outcome in RecentGameOutcome.values) {
        final color = outcome.colorFor(brightness);
        if (outcome == RecentGameOutcome.unknown) {
          expect(color, isNull);
          continue;
        }
        // Include the selected-row fill as well as the normal background.
        for (final background in [
          t.scaffoldBackgroundColor,
          Color.alphaBlend(
            t.colorScheme.primary.withValues(alpha: .12),
            t.scaffoldBackgroundColor,
          ),
        ]) {
          final a = color!.computeLuminance();
          final b = background.computeLuminance();
          expect(
            (math.max(a, b) + .05) / (math.min(a, b) + .05),
            greaterThanOrEqualTo(4.5),
            reason: '$outcome $background',
          );
        }
      }
    });
  }

  for (final locale in AppLocalizations.supportedLocales) {
    for (final brightness in Brightness.values) {
      testWidgets('result-only spans and semantics: $locale $brightness', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();

        final games = [
          record({'playerIsWhite': false, 'pgn': '[Result "0-1"]'}, id: 'win'),
          record({'playerIsWhite': false, 'pgn': '[Result "1-0"]'}, id: 'loss'),
          record({
            'playerIsWhite': true,
            'pgn': '[Result "1/2-1/2"]',
          }, id: 'draw'),
          record({'recentState': 'incomplete'}, id: 'incomplete'),
          record({'pgn': '[Result "1-0"]'}, id: 'unknown'),
        ];
        final before = games
            .map((g) => Map<String, dynamic>.of(g.data))
            .toList();
        await showGames(tester, games, locale: locale, brightness: brightness);
        final context = tester.element(find.byType(RecentGamesPage));
        final strings = AppLocalizations.of(context)!;
        final date = MaterialLocalizations.of(context)
            .formatCompactDate(DateTime.utc(2020, 2, 29));
        for (final game in games) {
          final tile = tester.widget<ListTile>(
            find.byKey(ValueKey('recent-game-${game.id}')),
          );
          final subtitle = tile.subtitle! as Text;
          final result = game.localizedResult(context);
          expect(
            subtitle.textSpan!.toPlainText(),
            strings.recentGameSummary(result, date),
          );
          final spans = (subtitle.textSpan! as TextSpan).children!
              .cast<TextSpan>();
          final resultSpan = spans.singleWhere((span) => span.text == result);
          expect(resultSpan.style!.color, game.outcome.colorFor(brightness));
          for (final span in spans.where((span) => span != resultSpan)) {
            expect(
              span.style,
              isNull,
            ); // Date/punctuation inherit unchanged style.
          }
          expect((tile.title! as Text).style, isNull);
          expect(tile.tileColor, isNull);
          final description = switch (game.outcome) {
            RecentGameOutcome.win => strings.recentWinResult(result),
            RecentGameOutcome.loss => strings.recentLossResult(result),
            RecentGameOutcome.draw => strings.recentDrawResult(result),
            _ => result,
          };
          expect(
            subtitle.semanticsLabel,
            strings.recentGameSummary(description, date),
          );
          expect(
            find.bySemanticsLabel(RegExp(RegExp.escape(description))),
            findsWidgets,
          );
        }
        expect(games.map((g) => g.data).toList(), before);
        expect(find.text(strings.recentGames), findsOneWidget);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      });
    }
  }

  testWidgets('narrow translated rows support large text and selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await showGames(
      tester,
      [
        record({'playerIsWhite': false, 'pgn': '[Result "1/2-1/2"]'}),
      ],
      locale: const Locale('de'),
      scale: 2,
    );
    expect(tester.takeException(), isNull);
    await tester.longPress(find.byKey(const ValueKey('recent-game-game')));
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

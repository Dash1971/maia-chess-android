import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

final _games = [
  for (final id in ['first', 'second'])
    RecentSession(id, DateTime.utc(2026), {
      'type': 'game',
      'recentState': 'completed',
      'pgn': '[Event "$id"]\n[Result "1-0"]\n\n1. e4 1-0',
    }),
];

void main() {
  testWidgets('Recent games admits only one open while storage is pending', (
    tester,
  ) async {
    final pending = Completer<Map<String, dynamic>?>();
    final opened = <String>[];
    Map<String, dynamic>? selected;
    var returned = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                selected = await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecentGamesPage(
                      loadGames: () async => _games,
                      openGame: (id) {
                        opened.add(id);
                        return pending.future;
                      },
                    ),
                  ),
                );
                returned = true;
              },
              child: const Text('Recent'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Recent'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('first'));
    // A second tap can arrive before a new frame disables the controls.
    await tester.tap(find.text('second'));
    final requests = List<String>.of(opened);
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(returned, isFalse);
    expect(find.byType(RecentGamesPage), findsOneWidget);
    pending.complete(_games.first.data);
    await tester.pumpAndSettle();
    expect(requests, ['first']);
    expect(selected, _games.first.data);
    expect(find.text('Recent'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed Recent-game open stays usable and can be retried', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: RecentGamesPage(
          loadGames: () async => _games,
          openGame: (_) async {
            attempts++;
            throw const FileSystemException('Synthetic read failure');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (var attempt = 1; attempt <= 2; attempt++) {
      await tester.tap(find.text('first'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.text('Could not open saved game. Please try again.'),
        findsOneWidget,
      );
      expect(attempts, attempt);
    }
  });

  testWidgets('failed deletion shows an error and permits a successful retry', (
    tester,
  ) async {
    final games = List<RecentSession>.of(_games);
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: RecentGamesPage(
          loadGames: () async => List.of(games),
          deleteGames: (ids) async {
            if (++attempts == 1) {
              throw const FileSystemException('Synthetic delete failure');
            }
            games.removeWhere((game) => ids.contains(game.id));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (var attempt = 1; attempt <= 2; attempt++) {
      await tester.tap(find.byTooltip('Delete saved game').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(attempts, attempt);
      if (attempt == 1) {
        expect(
          find.text('Could not delete saved games. Please try again.'),
          findsOneWidget,
        );
        expect(find.text('first'), findsOneWidget);
      } else {
        expect(find.text('first'), findsNothing);
        expect(find.text('second'), findsOneWidget);
      }
    }
  });
}

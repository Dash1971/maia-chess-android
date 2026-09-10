import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

List<RecentSession> _records() => [
  for (final id in ['first', 'second'])
    RecentSession(id, DateTime.utc(2026), {
      'type': 'game',
      'recentState': 'completed',
      'pgn': '[Event "$id"]\n[Result "1-0"]\n\n1. e4 1-0',
    }),
];

Future<void> _openRecent(
  WidgetTester tester, {
  required Future<List<RecentSession>> Function() load,
  required Future<Map<String, dynamic>?> Function(String) open,
  required void Function(Map<String, dynamic>?) selected,
  Future<void> Function(Iterable<String>)? delete,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              selected(
                await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecentGamesPage(
                      loadGames: load,
                      openGame: open,
                      deleteGames: delete,
                    ),
                  ),
                ),
              );
            },
            child: const Text('Open recent'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open recent'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'cancel and Back dismiss deletion without blocking a later open',
    (tester) async {
      final games = _records();
      var deletions = 0;
      Map<String, dynamic>? selected;
      await _openRecent(
        tester,
        load: () async => games,
        open: (id) async => games.singleWhere((game) => game.id == id).data,
        delete: (_) async {
          deletions++;
        },
        selected: (value) => selected = value,
      );
      for (final cancelWithBack in [false, true]) {
        final buttons = tester
            .widgetList<IconButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is IconButton &&
                    widget.tooltip == 'Delete saved game',
              ),
            )
            .toList();
        // Deliver both button callbacks in one turn, before a confirmation
        // frame can intercept the second pointer event.
        buttons.first.onPressed!();
        buttons.last.onPressed!();
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsNothing);
        if (cancelWithBack) {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
        }
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(RecentGamesPage), findsOneWidget);
        expect(deletions, 0);
        expect(selected, isNull);
      }
      await tester.tap(find.text('second'));
      await tester.pumpAndSettle();
      expect(selected, games.last.data);
      expect(find.text('Open recent'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'partial batch deletion refreshes selection and retries only remaining records',
    (tester) async {
      final games = _records();
      final batches = <Set<String>>[];
      await tester.pumpWidget(
        MaterialApp(
          home: RecentGamesPage(
            loadGames: () async => List.of(games),
            deleteGames: (ids) async {
              batches.add(ids.toSet());
              if (batches.length == 1) {
                games.removeWhere((game) => game.id == 'first');
                throw const FileSystemException(
                  'Synthetic partial batch failure',
                );
              }
              games.removeWhere((game) => ids.contains(game.id));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('recent-games-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select games'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('select-all-games')));
      await tester.pumpAndSettle();
      expect(find.text('2 selected'), findsOneWidget);
      for (var attempt = 0; attempt < 2; attempt++) {
        await tester.tap(find.byKey(const ValueKey('delete-selected-games')));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (attempt == 0) {
          expect(find.text('first'), findsNothing);
          expect(find.text('second'), findsOneWidget);
          expect(find.text('1 selected'), findsOneWidget);
          expect(
            find.text('Could not delete saved games. Please try again.'),
            findsOneWidget,
          );
        }
      }
      expect(batches, [
        {'first', 'second'},
        {'second'},
      ]);
      expect(
        find.textContaining('Completed games and incomplete games'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('delete-selected-games')), findsNothing);
    },
  );

  testWidgets(
    'unavailable record reports an error and another record still opens',
    (tester) async {
      final games = _records();
      final requested = <String>[];
      Map<String, dynamic>? selected;
      await _openRecent(
        tester,
        load: () async => games,
        open: (id) async {
          requested.add(id);
          return id == 'first' ? null : games.last.data;
        },
        selected: (value) => selected = value,
      );
      await tester.tap(find.text('first'));
      await tester.pumpAndSettle();
      expect(
        find.text('Could not open saved game. Please try again.'),
        findsOneWidget,
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(selected, isNull);
      await tester.tap(find.text('second'));
      await tester.pumpAndSettle();
      expect(requested, ['first', 'second']);
      expect(selected, games.last.data);
      expect(find.text('Open recent'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

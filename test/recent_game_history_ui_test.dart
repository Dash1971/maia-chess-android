import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:maia_chess/l10n/app_localizations.dart';

void main() {
  for (final locale in ['en', 'ja', 'zh', 'ko', 'es']) {
    testWidgets('recent dates in $locale use played day or explicit unknown', (
      tester,
    ) async {
      final games = [
        RecentSession('known', DateTime.utc(2035, 1, 1), {
          'type': 'game',
          'recentState': 'completed',
          'pgn': '[Date "2020.02.29"]\n[Result "1-0"]\n\n1-0',
        }),
        RecentSession('unknown', DateTime.utc(2035, 1, 1), {
          'type': 'game',
          'recentState': 'completed',
          'pgn': '[Date "????.??.??"]\n[Result "0-1"]\n\n0-1',
        }),
      ];
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: RecentGamesPage(loadGames: () async => games),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(RecentGamesPage));
      final strings = AppLocalizations.of(context)!;
      final day = MaterialLocalizations.of(context)
          .formatCompactDate(DateTime.utc(2020, 2, 29));
      expect(find.text(strings.recentGameSummary('1-0', day)), findsOneWidget);
      expect(
        find.text(strings.recentGameSummary('0-1', strings.dateUnknown)),
        findsOneWidget,
      );
      expect(find.textContaining('2035'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}

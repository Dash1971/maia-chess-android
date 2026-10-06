import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(maiaEngineChannel, null));

  Widget localized(Locale locale, Widget home) => MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );

  for (final language in [
    'en',
    'ja',
    'zh',
    'ko',
    'es',
    'de',
    'fr',
    'ru',
    'hi',
    'pt',
  ]) {
    testWidgets(
      'Recent Games $language localizes deletion and original metadata',
      (tester) async {
        final data = <String, dynamic>{
          'type': 'game',
          'playerIsWhite': false,
          'elo': 500,
          'recentState': 'incomplete',
          'pgn': '[Black "Maia 500"]\n[Date "2026.09.05"]\n[Result "*"]\n\n1. e4 *',
        };
        final original = Map<String, dynamic>.from(data);
        final date = DateTime(2026, 9, 5);
        final games = [
          RecentSession('one', date, data),
          RecentSession('two', date, {...data}),
        ];
        await tester.pumpWidget(
          localized(
            Locale(language),
            RecentGamesPage(
              loadGames: () async => games,
              deleteGames: (_) async =>
                  throw StateError('canonical filesystem detail'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final strings = AppLocalizations.of(
          tester.element(find.byType(RecentGamesPage)),
        )!;
        expect(find.text(strings.recentMaiaPlayer('500')), findsNWidgets(2));
        expect(
          find.text(
            strings.recentGameSummary(
              strings.recentIncomplete,
              MaterialLocalizations.of(
                tester.element(find.byType(RecentGamesPage)),
              ).formatCompactDate(date),
            ),
          ),
          findsNWidgets(2),
        );
        await tester.tap(find.byKey(const ValueKey('recent-games-menu')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(strings.recentDeleteAll));
        await tester.pumpAndSettle();
        expect(find.text(strings.recentDeleteTitle(2)), findsOneWidget);
        expect(find.text(strings.recentDeleteWarning(2)), findsOneWidget);
        await tester.tap(find.text(strings.deleteAction));
        await tester.pumpAndSettle();
        expect(find.text(strings.recentDeleteFailed), findsOneWidget);
        expect(
          find.textContaining('canonical filesystem detail'),
          findsNothing,
        );
        expect(data, original);
        // The singular warning uses its own ICU branch and opens without rewriting data.
        await tester.tap(find.byTooltip(strings.recentDeleteOne).first);
        await tester.pumpAndSettle();
        expect(find.text(strings.recentDeleteTitle(1)), findsOneWidget);
        expect(find.text(strings.recentDeleteWarning(1)), findsOneWidget);
        await tester.tap(find.text(strings.cancel));
        await tester.pumpAndSettle();
        expect(data, original);
      },
    );

    testWidgets(
      'PGN share $language passes localized native chooser title and exact PGN',
      (tester) async {
        final calls = <MethodCall>[];
        messenger.setMockMethodCallHandler(maiaEngineChannel, (call) async {
          calls.add(call);
          return null;
        });
        const pgn = '[White "Player"]\n[Result "*"]\n\n1. e4 *';
        await tester.pumpWidget(
          localized(
            Locale(language),
            Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => PgnFiles.export(context, pgn, share: true),
                  child: const Text('test share'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final strings = AppLocalizations.of(
          tester.element(find.text('test share')),
        )!;
        await tester.tap(find.text('test share'));
        await tester.pumpAndSettle();
        expect(calls.single.method, 'sharePgn');
        expect(calls.single.arguments, {
          'pgn': pgn,
          'shareTitle': strings.sharePgn,
        });
      },
    );

    testWidgets('diagnostic fallback $language uses translated instructions', (
      tester,
    ) async {
      await tester.pumpWidget(
        localized(Locale(language), const DiagnosticsErrorScreen()),
      );
      await tester.pumpAndSettle();
      final strings = AppLocalizations.of(
        tester.element(find.byType(DiagnosticsErrorScreen)),
      )!;
      expect(find.text(strings.diagnosticsScreenError), findsOneWidget);
      expect(find.text(strings.diagnosticsScreenInstructions), findsOneWidget);
      expect(find.text(strings.copyDiagnostics), findsOneWidget);
    });
  }
}

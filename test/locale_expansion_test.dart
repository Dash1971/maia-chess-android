import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:maia_chess/main.dart';

void main() {
  test(
    'Brazilian Portuguese zero and one counts use natural agreement',
    () async {
      final strings = await AppLocalizations.delegate.load(const Locale('pt'));
      for (final (count, pawn, selected) in [
        (0, 'peões', 'selecionadas'),
        (1, 'peão', 'selecionada'),
        (2, 'peões', 'selecionadas'),
      ]) {
        expect(strings.materialPawn(count), '$count $pawn');
        expect(strings.recentSelectedCount(count), '$count $selected');
      }
    },
  );

  test('Hindi zero counts do not use singular pawn wording', () async {
    final strings = await AppLocalizations.delegate.load(const Locale('hi'));
    for (final (count, pawn) in [(0, 'प्यादे'), (1, 'प्यादा'), (2, 'प्यादे')]) {
      expect(strings.materialPawn(count), '$count $pawn');
      expect(strings.recentSelectedCount(count), 'चुने गए खेल: $count');
    }
  });

  test(
    'Russian counts select one, few and many across teen boundaries',
    () async {
      final strings = await AppLocalizations.delegate.load(const Locale('ru'));
      for (final (count, pawn, game, selected) in [
        (0, 'пешек', 'сохранённых партий', 'Выбрано 0 партий'),
        (1, 'пешка', 'сохранённую партию', 'Выбрана 1 партия'),
        (2, 'пешки', 'сохранённые партии', 'Выбраны 2 партии'),
        (5, 'пешек', 'сохранённых партий', 'Выбрано 5 партий'),
        (11, 'пешек', 'сохранённых партий', 'Выбрано 11 партий'),
        (21, 'пешка', 'сохранённую партию', 'Выбрана 21 партия'),
        (22, 'пешки', 'сохранённые партии', 'Выбраны 22 партии'),
        (25, 'пешек', 'сохранённых партий', 'Выбрано 25 партий'),
        (111, 'пешек', 'сохранённых партий', 'Выбрано 111 партий'),
      ]) {
        expect(strings.materialPawn(count), '$count $pawn');
        expect(strings.recentDeleteTitle(count), 'Удалить $count $game?');
        expect(strings.recentSelectedCount(count), selected);
      }
    },
  );

  for (final (code, decimal) in [
    ('de', '0,95'),
    ('fr', '0,95'),
    ('ru', '0,95'),
    ('hi', '0.95'),
    ('pt', '0,95'),
  ]) {
    testWidgets('$code displays locale decimals and ungrouped chess ratings', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(code),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) => Text(
              '${displayNumber(context, 0.95, decimalDigits: 2)} / '
              '${displayNumber(context, 1500)}',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('$decimal / 1500'), findsOneWidget);
    });
  }
}

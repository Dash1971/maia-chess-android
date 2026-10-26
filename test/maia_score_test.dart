import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:chessground/chessground.dart' as cg;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

MaiaInferenceResult result(double loss, double draw, double win) =>
    MaiaInferenceResult(
      Float32List(4352),
      outcome: MaiaOutcome.fromLogits([log(loss), log(draw), log(win)]),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'Loss/Draw/Win normalization, half draws and side-to-move perspective',
    () {
      final outcome = MaiaOutcome.fromLogits([log(.2), log(.4), log(.4)])!;
      expect(outcome.loss, closeTo(.2, 1e-12));
      expect(outcome.draw, closeTo(.4, 1e-12));
      expect(outcome.win, closeTo(.4, 1e-12));
      expect(
        outcome.whiteScore('8/8/8/8/8/8/8/8 w - - 0 1'),
        closeTo(.6, 1e-12),
      );
      expect(
        outcome.whiteScore('8/8/8/8/8/8/8/8 b - - 0 1'),
        closeTo(.4, 1e-12),
      );
      expect(
        MaiaOutcome.fromLogits([-1000, 1000, -1000])!
            .whiteScore('8/8/8/8/8/8/8/8 w - - 0 1'),
        .5,
      );
      final shifted = MaiaOutcome.fromLogits([
        1000 + log(.2),
        1000 + log(.4),
        1000 + log(.4),
      ])!;
      expect(shifted.win, closeTo(.4, 1e-12));
      for (final logits in [
        <double>[],
        [1.0, 2.0],
        [1.0, 2.0, 3.0, 4.0],
        [double.nan, 0.0, 0.0],
        [double.infinity, 0.0, 0.0],
      ]) {
        expect(MaiaOutcome.fromLogits(logits), isNull);
      }
    },
  );
  test(
    'mixed protocol keeps move-only compatibility without inventing an outcome',
    () {
      final moves = Float32List(4352);
      expect(MaiaInferenceResult.decode(moves)!.outcome, isNull);
      expect(
        MaiaInferenceResult.decode({
          'move_logits': moves,
          'value_logits': Float32List.fromList([0, 1, 2]),
        })!.outcome,
        isNotNull,
      );
      expect(
        MaiaInferenceResult.decode({
          'move_logits': moves,
          'value_logits': Float32List(4),
        })!.outcome,
        isNull,
      );
      expect(
        MaiaInferenceResult.decode({'move_logits': Float32List(3)}),
        isNull,
      );
    },
  );
  test(
    'visible preference defaults off, validates types and survives reload',
    () async {
      for (final value in [null, 7, 'true', false]) {
        SharedPreferences.setMockInitialValues({
          maiaScorePreferenceKey: ?value,
        });
        final controller = MaiaScoreController();
        await controller.initialize();
        expect(controller.enabled, isFalse);
        controller.dispose();
      }
      final controller = MaiaScoreController();
      await controller.select(true);
      controller.dispose();
      final restarted = MaiaScoreController();
      await restarted.initialize();
      expect(restarted.enabled, isTrue);
      await restarted.select(false);
      expect(
        (await SharedPreferences.getInstance()).getBool(maiaScorePreferenceKey),
        isFalse,
      );
      restarted.dispose();
    },
  );
  test('analysis requests outcome and move logits on the same serialized native call', () async {
    MaiaInferenceQueue.resetForTesting();
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, (call) async {
          calls.add(call);
          return call.arguments['includeValue'] == true
              ? {
                  'move_logits': Float32List(4352),
                  'value_logits': Float32List.fromList([0, 0, 0]),
                }
              : Float32List(4352);
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(maiaEngineChannel, null),
    );
    final output = await MaiaInferenceQueue.analyze({
      'tokens': Float32List(6208),
      'selfElo': 1500,
      'opponentElo': 1500,
    });
    expect(output!.outcome!.draw, closeTo(1 / 3, 1e-8));
    expect(calls.single.method, 'predict');
    expect(calls.single.arguments['includeValue'], true);
    expect(
      await MaiaInferenceQueue.predict({
        'tokens': Float32List(6208),
        'selfElo': 1500,
        'opponentElo': 1500,
      }),
      hasLength(4352),
    );
  });

  final session = AnalysisSession.fromPgn('1. e4 e5 2. Nf3 Nc6 *');
  Widget app(
    MaiaScoreController controller, {
    int elo = 1500,
    int? second = 2600,
    Locale locale = const Locale('en'),
    double scale = 1,
    AnalysisSession? positionSession,
    Future<MaiaInferenceResult?> Function(List<String>, int)? infer,
  }) => MaiaScoreScope(
    controller: controller,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: ReviewPage(
        positions: (positionSession ?? session).positions,
        uciMoves: (positionSession ?? session).uciMoves,
        sanMoves: (positionSession ?? session).sanMoves,
        pgn: (positionSession ?? session).pgn,
        playerIsWhite: true,
        onHome: () {},
        maiaElo: elo,
        secondMaiaElo: second,
        evaluator: (_) async => const StockfishReview(0, 'e2e4'),
        maiaInferenceEvaluator:
            infer ??
            (_, rating) async =>
                rating == 1500 ? result(.2, .4, .4) : result(.6, .2, .2),
      ),
    ),
  );
  testWidgets(
    'each engine has its own rating-conditioned score and board size is unchanged',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = MaiaScoreController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(app(controller));
      await tester.pumpAndSettle();
      final moveRect = tester.getRect(
        find.byKey(const ValueKey('analysis-tab-panel')),
      );
      final before = tester
          .widget<cg.Chessboard>(find.byType(cg.Chessboard))
          .size;
      expect(find.byKey(const ValueKey('maia-score-primary')), findsNothing);
      await controller.select(true);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('M1500 White 60%'), findsOneWidget);
      expect(find.bySemanticsLabel('M2600 Black 70%'), findsOneWidget);
      expect(
        tester.widget<cg.Chessboard>(find.byType(cg.Chessboard)).size,
        before,
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('analysis-tab-panel'))),
        moveRect,
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('maia-score-details'))).bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(AppBar)).bottom),
      );
      expect(find.byType(EvaluationBar), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('analysis-flip-button')));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('M1500 White 60%'), findsOneWidget);
      expect(find.bySemanticsLabel('M2600 Black 70%'), findsOneWidget);
    },
  );
  for (final locale in AppLocalizations.supportedLocales) {
    for (final second in <int?>[null, 2600]) {
      testWidgets(
        '${locale.languageCode} score labels stay anchored (second=$second)',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final controller = MaiaScoreController();
          addTearDown(controller.dispose);
          await controller.select(true);
          for (final config in [(560.0, 1.0), (390.0, 1.0), (320.0, 2.0)]) {
            await tester.pumpWidget(const SizedBox());
            tester.view.physicalSize = Size(config.$1, 844);
            final pending = <String, Completer<MaiaInferenceResult?>>{};
            Future<MaiaInferenceResult?> infer(List<String> history, int elo) =>
                pending
                    .putIfAbsent('${history.length}:$elo', () => Completer())
                    .future;
            await tester.pumpWidget(
              app(
                controller,
                locale: locale,
                scale: config.$2,
                second: second,
                infer: infer,
              ),
            );
            await tester.pumpAndSettle();
            final keys = [
              'maia-score-primary',
              if (second != null) 'maia-score-secondary',
            ];
            Map<String, Rect> geometry() {
              final result = <String, Rect>{
                'details': tester.getRect(
                  find.byKey(const ValueKey('maia-score-details')),
                ),
                'board': tester.getRect(find.byType(cg.Chessboard)),
              };
              for (final key in keys) {
                final row = find.byKey(ValueKey(key));
                result[key] = tester.getRect(row);
                for (final column in ['marker-slot', 'value']) {
                  result['$key-$column'] = tester.getRect(
                    find.byKey(ValueKey('$key-$column')),
                  );
                }
                final value = tester.widget<Text>(
                  find.byKey(ValueKey('$key-value')),
                );
                expect(value.textAlign, TextAlign.start);
                final disc = find.byKey(ValueKey('$key-disc'));
                if (disc.evaluate().isNotEmpty) {
                  final circle = tester.getRect(disc);
                  final number = result['$key-value']!;
                  expect(number.left - circle.right, closeTo(4, .01));
                }
                final rating = find.descendant(
                  of: row,
                  matching: find.byWidgetPredicate(
                    (w) => w is Text && (w.data?.startsWith('M') ?? false),
                  ),
                );
                if (rating.evaluate().isNotEmpty) {
                  result['$key-label'] = tester.getRect(rating);
                }
              }
              if (second != null) {
                for (final column in ['marker-slot', 'value']) {
                  expect(
                    result['maia-score-primary-$column']!.left,
                    result['maia-score-secondary-$column']!.left,
                  );
                }
              }
              return result;
            }

            final initial = geometry();
            if (config.$1 == 560 && locale.languageCode == 'en') {
              expect(initial.containsKey('maia-score-primary-label'), isTrue);
            }
            void unchanged() {
              expect(geometry(), initial);
              expect(tester.takeException(), isNull);
            }

            // The two engines complete independently; neither can move a label.
            pending['1:1500']!.complete(result(.2, .4, .4));
            await tester.pumpAndSettle();
            unchanged();
            if (second != null) {
              pending['1:$second']!.complete(result(.9998, .0001, .0001));
              await tester.pumpAndSettle();
              unchanged();
            }
            await tester.tap(find.byKey(const ValueKey('next-move-button')));
            await tester.pumpAndSettle();
            unchanged();
            pending['2:1500']!.complete(result(.25, .5, .25));
            if (second != null) pending['2:$second']!.complete(null);
            await tester.pumpAndSettle();
            unchanged();
            // Terminal states have different text but the same reserved columns.
            await tester.pumpWidget(const SizedBox());
            await tester.pumpWidget(
              app(
                controller,
                locale: locale,
                scale: config.$2,
                second: second,
                positionSession: AnalysisSession.fromFen(
                  '7k/6Q1/5K2/8/8/8/8/8 b - - 0 1',
                ),
                infer: (_, _) async =>
                    throw StateError('terminal position must not infer'),
              ),
            );
            await tester.pumpAndSettle();
            unchanged();
          }
        },
      );
    }
  }

  testWidgets('late results cannot replace the selected rating and position', (
    tester,
  ) async {
    final controller = MaiaScoreController();
    addTearDown(controller.dispose);
    await controller.select(true);
    final old = Completer<MaiaInferenceResult?>(),
        current = Completer<MaiaInferenceResult?>();
    Future<MaiaInferenceResult?> infer(List<String> _, int elo) =>
        elo == 1500 ? old.future : current.future;
    await tester.pumpWidget(app(controller, second: null, infer: infer));
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      app(controller, elo: 1800, second: null, infer: infer),
    );
    await tester.pumpAndSettle();
    old.complete(result(.05, .1, .85));
    await tester.pumpAndSettle();
    expect(find.textContaining('90%'), findsNothing);
    current.complete(result(.2, .2, .6));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('M1800 White 70%'), findsOneWidget);
    expect(find.textContaining('M1500 White'), findsNothing);
  });
  testWidgets(
    'selected-position change converts Black perspective and clears stale values',
    (tester) async {
      final controller = MaiaScoreController();
      addTearDown(controller.dispose);
      await controller.select(true);
      final after = Completer<MaiaInferenceResult?>();
      await tester.pumpWidget(
        app(
          controller,
          second: null,
          infer: (history, _) async =>
              history.length == 1 ? result(.2, .4, .4) : after.future,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('M1500 White 60%'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('next-move-button')));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('M1500 White 60%'), findsNothing);
      after.complete(result(.2, .4, .4));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('M1500 Black 60%'), findsOneWidget);
    },
  );
  testWidgets(
    'missing outcomes and terminal positions do not invent percentages',
    (tester) async {
      final controller = MaiaScoreController();
      addTearDown(controller.dispose);
      await controller.select(true);
      await tester.pumpWidget(
        app(
          controller,
          second: null,
          infer: (_, _) async => MaiaInferenceResult(Float32List(4352)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('M1500 Unavailable'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('maia-score-primary')),
          matching: find.text('—'),
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(
        app(
          controller,
          second: null,
          positionSession: AnalysisSession.fromFen(
            '7k/6Q1/5K2/8/8/8/8/8 b - - 0 1',
          ),
          infer: (_, _) async =>
              throw StateError('terminal position must not infer'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('M1500 White is victorious'),
        findsOneWidget,
      );
      expect(find.text('1–0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
      '${locale.languageCode} two scores and settings fit at 200% narrow/landscape',
      (tester) async {
        final controller = MaiaScoreController();
        addTearDown(controller.dispose);
        await controller.select(true);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        for (final size in [const Size(320, 640), const Size(640, 320)]) {
          tester.view.physicalSize = size;
          await controller.select(false);
          await tester.pumpWidget(app(controller, locale: locale, scale: 2));
          await tester.pumpAndSettle();
          final boardRect = tester.getRect(find.byType(cg.Chessboard));
          final engineRect = tester.getRect(
            find.byKey(const ValueKey('analysis-engine-lines')),
          );
          final moveRect = tester.getRect(
            find.byKey(const ValueKey('analysis-tab-panel')),
          );
          await controller.select(true);
          await tester.pumpAndSettle();
          expect(tester.getRect(find.byType(cg.Chessboard)), boardRect);
          expect(
            tester.getRect(find.byKey(const ValueKey('analysis-engine-lines'))),
            engineRect,
          );
          expect(
            tester.getRect(find.byKey(const ValueKey('analysis-tab-panel'))),
            moveRect,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(
            MaiaScoreScope(
              controller: controller,
              child: MaterialApp(
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(2)),
                  child: child!,
                ),
                home: const Scaffold(
                  body: SingleChildScrollView(child: MaiaScoreSetting()),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            find.text(
              AppLocalizations.of(
                tester.element(find.byType(MaiaScoreSetting)),
              )!.maiaScoreHelp,
            ),
            findsNothing,
          );
          await tester.tap(find.byKey(const ValueKey('maia-score-help')));
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsOneWidget);
          if (locale.languageCode == 'es') {
            expect(
              find.textContaining(
                'La estimación supone que ambos jugadores tienen el Elo de análisis '
                'seleccionado para Maia. Si activas dos Maias, cada una calcula su '
                'estimación con su propio Elo.',
              ),
              findsOneWidget,
            );
            expect(find.textContaining('puntuación de análisis'), findsNothing);
          }

          expect(tester.takeException(), isNull);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
        }
      },
    );
  }
}

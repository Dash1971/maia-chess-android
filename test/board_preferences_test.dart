// Inspect Chessground's real highlight notifier to verify selection survival.
// ignore_for_file: invalid_use_of_internal_member
import 'dart:async';
import 'dart:io';

import 'package:chessground/chessground.dart' as cg;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('legacy and malformed values preserve defaults field by field', () {
    for (final raw in [null, 7, '{', '[]', '{}', '{"dragTarget":"other"}']) {
      expect(
        BoardPreferences.decode(raw).encode(),
        const BoardPreferences().encode(),
      );
    }
    final mixed = BoardPreferences.decode(
      '{"coordinates":false,"animation":"no","legalMoves":0,"lastMove":null,"dragTarget":"square"}',
    );
    expect(mixed.coordinates, isFalse);
    expect(mixed.animation, isTrue);
    expect(mixed.legalMoves, isTrue);
    expect(mixed.lastMove, isTrue);
    expect(mixed.dragTarget, cg.DragTargetKind.square);
  });

  test('preferences round-trip through storage and reset', () async {
    final first = BoardPreferencesController();
    await first.initialize();
    final choice = const BoardPreferences(
      coordinates: false,
      legalMoves: false,
      lastMove: false,
      animation: false,
      magnify: false,
      dragTarget: cg.DragTargetKind.none,
    );
    await first.select(choice);
    first.dispose();
    final second = BoardPreferencesController();
    await second.initialize();
    expect(second.value.encode(), choice.encode());
    await second.select(const BoardPreferences());
    final third = BoardPreferencesController();
    await third.initialize();
    expect(third.value.encode(), const BoardPreferences().encode());
    second.dispose();
    third.dispose();
  });

  test(
    'late initialization and queued writes cannot override newer choices',
    () async {
      final read = Completer<Object?>();
      final gate = Completer<void>();
      final written = <String>[];
      final controller = BoardPreferencesController(
        read: () => read.future,
        write: (value) async {
          if (written.isEmpty) await gate.future;
          written.add(value);
        },
      );
      final initializing = controller.initialize();
      final first = controller.select(
        const BoardPreferences(coordinates: false),
      );
      final second = controller.select(const BoardPreferences(lastMove: false));
      read.complete(const BoardPreferences().encode());
      await initializing;
      expect(controller.value.lastMove, isFalse);
      gate.complete();
      await Future.wait([first, second]);
      expect(BoardPreferences.decode(written.last).lastMove, isFalse);
      controller.dispose();
    },
  );

  test('failed writes report a retryable error', () async {
    var fail = true;
    final controller = BoardPreferencesController(
      write: (_) async {
        if (fail) throw StateError('disk failure');
      },
    );
    await controller.select(const BoardPreferences(coordinates: false));
    expect(controller.persistenceFailed, isTrue);
    expect(controller.value.coordinates, isFalse);
    fail = false;
    await controller.select(controller.value);
    expect(controller.persistenceFailed, isFalse);
    controller.dispose();
  });

  test('six settings retain unrelated board input and highlight meanings', () {
    const defaults = BoardPreferences();
    expect(defaults.interactiveSettings, mobileMaiaInteractiveBoardSettings);
    final settings = defaults
        .copyWith(
          lastMove: false,
          legalMoves: false,
          animation: false,
          magnify: false,
          dragTarget: cg.DragTargetKind.square,
        )
        .interactiveSettings;
    expect(settings.showLastMove, isFalse);
    expect(settings.showValidMoves, isFalse);
    expect(settings.animationDuration, Duration.zero);
    expect(settings.dragFeedbackScale, 1);
    expect(settings.dragFeedbackOffset, const Offset(0, -1));
    expect(settings.dragTargetKind, cg.DragTargetKind.square);
    expect(settings.enablePremoves, isTrue);
    expect(settings.pieceShiftMethod, cg.PieceShiftMethod.either);
    expect(settings.drawShape, mobileMaiaInteractiveBoardSettings.drawShape);
    expect(
      settings.colorScheme.selected,
      mobileMaiaInteractiveBoardSettings.colorScheme.selected,
    );
  });

  testWidgets('target chooser Cancel and Done are independent and accessible', (
    tester,
  ) async {
    final controller = BoardPreferencesController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      BoardPreferencesScope(
        controller: controller,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(child: BoardSettingsSection()),
          ),
        ),
      ),
    );
    final target = find.byKey(const ValueKey('board-drag-target'));
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('board-target-square')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(controller.value.dragTarget, cg.DragTargetKind.circle);
    await tester.tap(target);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('board-target-none')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(controller.value.dragTarget, cg.DragTargetKind.none);
    expect(controller.value.coordinates, isTrue);
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
      '${locale.languageCode} controls fit narrow and landscape at 200% text',
      (tester) async {
        final controller = BoardPreferencesController();
        addTearDown(controller.dispose);
        for (final size in [const Size(320, 640), const Size(640, 320)]) {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          await tester.pumpWidget(
            BoardPreferencesScope(
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
                  body: SingleChildScrollView(child: BoardSettingsSection()),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final last = find.byKey(const ValueKey('board-drag-target'));
          await tester.ensureVisible(last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byType(SwitchListTile), findsNWidgets(5));
        }
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );
  }

  testWidgets(
    'Review preference rebuild retains controller, position, selection and annotations',
    (tester) async {
      tester.view.physicalSize = const Size(576, 1280);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final prefs = BoardPreferencesController();
      addTearDown(prefs.dispose);
      final session = AnalysisSession.fromPgn(
        File('test/fixtures/analysis-selection.pgn').readAsStringSync(),
      );
      await tester.pumpWidget(
        BoardPreferencesScope(
          controller: prefs,
          child: MaterialApp(
            home: ReviewPage(
              positions: session.positions,
              uciMoves: session.uciMoves,
              sanMoves: session.sanMoves,
              pgn: session.pgn,
              playerIsWhite: true,
              initialCurrentFen: session.positions[40],
              onHome: () {},
              evaluator: (_) async => const StockfishReview(0, 'e5b8'),
              maiaEvaluator: (_, _) async => null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final finder = find.byType(cg.Chessboard);
      final before = tester.widget<cg.Chessboard>(finder);
      final state = tester.state(finder);
      final square = before.size / 8;
      await tester.tapAt(
        tester.getTopLeft(finder) + Offset(4.5 * square, 3.5 * square),
      );
      await tester.pumpAndSettle();
      expect(before.controller.highlightNotifier.selected, dc.Square.e5);
      await prefs.select(
        prefs.value.copyWith(
          lastMove: false,
          legalMoves: false,
          animation: false,
        ),
      );
      await tester.pumpAndSettle();
      final after = tester.widget<cg.Chessboard>(finder);
      expect(identical(state, tester.state(finder)), isTrue);
      expect(identical(before.controller, after.controller), isTrue);
      expect(after.controller.game.fen, before.controller.game.fen);
      expect(after.controller.highlightNotifier.selected, dc.Square.e5);
      expect(after.controller.highlightNotifier.moveDests, isEmpty);
      expect(after.shapes, before.shapes);
      expect(after.annotations, before.annotations);
      expect(after.controller.animationDuration, Duration.zero);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:maia_chess/main.dart';

import 'board_connection_widget_test.dart' show DiscoveryBoard;
import 'fixtures/immediate_maia_preferences.dart';

class FailingDiscoveryBoard extends DiscoveryBoard {
  Object? failure;

  @override
  Future<void> discoverBoards() async {
    if (failure case final error?) throw error;
    await super.discoverBoards();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FailingDiscoveryBoard board;
  setUp(() {
    setImmediateMaiaPreferences({});
    board = FailingDiscoveryBoard();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
  });
  tearDown(() async {
    await board.controller.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, null);
  });

  Future<void> mount(
    WidgetTester tester,
    Locale locale, {
    bool compact = true,
  }) async {
    tester.view.physicalSize = compact
        ? const Size(320, 640)
        : const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(compact ? 2 : 1)),
          child: child!,
        ),
        home: GamePage(
          electronicBoardTransport: board,
          maiaEvaluator: (_, _) async => Float32List(4352),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final toggle = find.byKey(const ValueKey('home-chessnut-toggle'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  for (final locale in AppLocalizations.supportedLocales) {
    for (final failure in [
      'permission_pending',
      'bluetooth_disabled',
      'plugin',
    ]) {
      testWidgets(
        '${locale.languageCode} $failure recovery is board-neutral at 200% text',
        (tester) async {
          board.failure = failure == 'plugin'
              ? MissingPluginException()
              : PlatformException(code: failure);
          await mount(tester, locale);
          final strings = await AppLocalizations.delegate.load(locale);
          final message = switch (failure) {
            'permission_pending' => strings.chessnutPermissionPending,
            'bluetooth_disabled' => strings.chessnutBluetoothDisabled,
            _ => strings.chessnutAndroidOnly,
          };
          expect(message, isNot(contains('Chessnut')));
          expect(message, isNot(contains('Pegasus')));
          final status = find.byKey(const ValueKey('chessnut-setup-status'));
          await tester.ensureVisible(status);
          await tester.pumpAndSettle();
          expect(
            find.descendant(of: status, matching: find.text(message)),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await dispose(tester);
        },
      );
    }

    testWidgets(
      '${locale.languageCode} Grand Kingdom supported labels and status are board-neutral',
      (tester) async {
        await mount(tester, locale, compact: false);
        board.status(BoardKind.squareOff);
        await tester.pumpAndSettle();
        final supported = await AppLocalizations.delegate.load(locale);
        expect(find.text(supported.electronicBoard), findsWidgets);
        expect(supported.chessnutBoard, 'Chessnut');
        final qualifier = RegExp(switch (locale.languageCode) {
          'ja' => '試験',
          'zh' => '实验',
          'ko' => '실험',
          'hi' => 'प्रायोगिक',
          'ru' => 'эксперимент',
          'fr' => 'expériment',
          _ => 'experiment',
        }, caseSensitive: false);
        for (final label in [
          supported.electronicBoard,
          supported.chessnutBoard,
          supported.boardMotorRecovery,
        ]) {
          expect(qualifier.hasMatch(label), isFalse);
        }
        expect(
          tester
              .widgetList<Text>(find.byType(Text))
              .map((t) => t.data)
              .whereType<String>()
              .any(qualifier.hasMatch),
          isFalse,
        );
        expect(
          find.byKey(const ValueKey('board-confirm-setup')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('board-confirm-setup')));
        await tester.pumpAndSettle();
        final strings = await AppLocalizations.delegate.load(locale);
        await tester.tap(find.widgetWithText(FilledButton, strings.startGame));
        await tester.pumpAndSettle();
        final button = tester.widget<IconButton>(
          find.byKey(const ValueKey('chessnut-status-button')),
        );
        expect(button.tooltip, strings.chessnutStatus);
        expect(button.tooltip, isNot(contains('Chessnut')));
        expect(board.starts, ['white']);
        expect(board.motorMoves, isEmpty);
        expect(tester.takeException(), isNull);
        await dispose(tester);
      },
    );
  }
}

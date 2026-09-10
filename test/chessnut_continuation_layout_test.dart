import 'dart:io';
import 'dart:ui' as ui;

import 'package:chessground/chessground.dart' as cg;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/electronic_board.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final directory = Platform.environment['MAIA_FONT_DIR'];
    if (directory == null) return;
    for (final (family, path) in [
      ('Roboto', '$directory/Roboto-Regular.ttf'),
      ('MaterialIcons', '$directory/MaterialIcons-Regular.otf'),
      (
        'packages/cupertino_icons/CupertinoIcons',
        '$directory/CupertinoIcons.ttf',
      ),
      ('LichessIcons', 'assets/fonts/LichessIcons.ttf'),
    ]) {
      await (FontLoader(
        family,
      )..addFont(File(path).readAsBytes().then(ByteData.sublistView))).load();
    }
  });

  for (final (name, size, scale) in [
    ('portrait', const Size(360, 720), 1.0),
    ('compact-large-text', const Size(320, 568), 2.0),
    ('landscape', const Size(800, 360), 1.0),
    ('landscape-large-text', const Size(800, 360), 2.0),
  ]) {
    testWidgets('connection choices and status menu fit $name', (tester) async {
      SharedPreferences.setMockInitialValues({});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(maiaEngineChannel, null),
      );
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await ActiveSessionStore.save({
        'type': 'game',
        'recentState': 'incomplete',
        'pgn': '1. e4 e5 2. Nf3 Nc6 *',
        'electronicBoard': 'chessnut-go',
        'clockPaused': true,
      });
      final board = SimulatedElectronicBoard();
      final capture = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme:
                ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xff5d735f),
                    brightness: Brightness.dark,
                  ),
                  scaffoldBackgroundColor: const Color(0xff171a18),
                  useMaterial3: true,
                ).copyWith(
                  textTheme: ThemeData.dark().textTheme.apply(
                    fontFamily: 'Roboto',
                  ),
                ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: GamePage(electronicBoardTransport: board),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(cg.Chessboard)).shortestSide,
        greaterThan(80),
      );
      for (final key in ['chessnut-inline-reconnect', 'chessnut-play-in-app']) {
        final target = find.byKey(ValueKey(key));
        expect(target.hitTestable(), findsOneWidget);
        expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
      }
      final directory = Platform.environment['MAIA_CAPTURE_DIR'];
      if (directory != null) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pumpAndSettle();
        final boundary =
            capture.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('$directory/chessnut-$name.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.tap(find.byKey(const ValueKey('chessnut-status-button')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final phone = find.widgetWithText(ListTile, 'Play in app');
      await tester.ensureVisible(phone);
      await tester.tap(phone);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('chessnut-status-banner')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('game-actions-menu')));
      await tester.pumpAndSettle();
      final reset = find.widgetWithText(ListTile, 'Reset game');
      await tester.ensureVisible(reset);
      expect(reset.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await board.close();
    });
  }
}

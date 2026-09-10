import 'dart:io';
import 'dart:ui' as ui;

import 'package:chessground/chessground.dart' as cg;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/launch_game.dart';

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
    testWidgets('multiple premove preview fits $name', (tester) async {
      SharedPreferences.setMockInitialValues({'multiplePremoves': true});
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
      await ActiveSessionStore.save(
        gameRecord(
          pgn: '1. e4 *',
          preset: 'blitz',
          history: [
            [180000, 180000],
            [179999, 180000],
          ],
        ),
      );
      final maia = ControlledMaia();
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
            home: GamePage(
              maiaEvaluator: maia.call,
              clockFactory: () => TestClock(0),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(cg.Chessboard)).shortestSide,
        greaterThan(80),
      );
      final sizeBefore = tester.getSize(find.byType(cg.Chessboard));
      for (final uci in ['g1f3', 'f3g5', 'g5f3', 'b1c3', 'c3d5']) {
        await queueMove(tester, uci);
      }
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(cg.Chessboard)), sizeBefore);
      final cancel = find.byKey(const ValueKey('cancel-premoves'));
      expect(cancel.hitTestable(), findsOneWidget);
      expect(tester.getSize(cancel).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
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
          await File('$directory/premoves-$name.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('premove-queue')), findsNothing);
      expect(tester.getSize(find.byType(cg.Chessboard)), sizeBefore);
      expect(tester.takeException(), isNull);
      await disposeGame(tester);
    });
  }
}

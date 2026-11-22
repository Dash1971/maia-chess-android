import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

final _games = [
  for (var i = 0; i < 20; i++)
    RecentSession('row-$i', DateTime.utc(2030), {
      'type': 'game',
      'recentState': i >= 4 && i < 8 ? 'incomplete' : 'completed',
      'elo': 1600,
      'playerIsWhite': i < 4 || i >= 8,
      'pgn':
          '[Date "2026.10.${i < 4
              ? '26'
              : i < 8
              ? '25'
              : '23'}"]\n'
          '[Result "${i >= 4 && i < 8
              ? '*'
              : i >= 8
              ? '1-0'
              : '0-1'}"]',
    }),
];

void main() {
  final font = Platform.environment['MAIA_REPORT_FONT'];
  setUpAll(() async {
    if (font != null) {
      await (FontLoader(
        'Roboto',
      )..addFont(File(font).readAsBytes().then(ByteData.sublistView))).load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });

  Future<void> show(
    WidgetTester tester, {
    double width = 600,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      RepaintBoundary(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(useMaterial3: true)
              .copyWith(scaffoldBackgroundColor: Colors.black),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RecentGamesPage(loadGames: () async => _games),
                  ),
                ),
                child: const Text('Home'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
  }

  testWidgets('Incomplete fits one line, centered and muted with equal gaps', (
    tester,
  ) async {
    await show(tester);
    final row = find.byKey(const ValueKey('recent-game-row-4'));
    final date = find.descendant(of: row, matching: find.text('2026/10/25'));
    final game = find.descendant(
      of: row,
      matching: find.text('Maia 1600 — Player'),
    );
    final result = find.descendant(of: row, matching: find.text('Incomplete'));
    final text = tester.widget<Text>(result);
    expect(text.textAlign, TextAlign.center);
    expect(text.semanticsLabel, 'Incomplete');
    expect(
      text.style?.color,
      Theme.of(tester.element(row)).colorScheme.onSurfaceVariant,
    );
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: result, matching: find.byType(RichText)),
    );
    expect(paragraph.didExceedMaxLines, isFalse);
    final boxes = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 10),
    );
    expect(boxes, hasLength(1));
    expect(boxes.single.right, lessThanOrEqualTo(tester.getSize(result).width));
    expect(
      tester.getTopLeft(game).dx - tester.getTopRight(date).dx,
      closeTo(16, 0.1),
    );
    expect(
      tester.getTopLeft(result).dx - tester.getTopRight(game).dx,
      closeTo(16, 0.1),
    );
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final predictive in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Back cancels selection before leaving: predictive=$predictive scale=$scale',
        (tester) async {
          await show(tester, width: 393, scale: scale);
          await tester.longPress(
            find.byKey(const ValueKey('recent-game-row-0')),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('delete-selected-games')),
            findsOneWidget,
          );
          if (predictive) {
            for (final method in ['startBackGesture', 'commitBackGesture']) {
              await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
                'flutter/backgesture',
                const StandardMethodCodec().encodeMethodCall(
                  MethodCall(
                    method,
                    method == 'startBackGesture'
                        ? <String, dynamic>{
                            'touchOffset': <double>[0, 300],
                            'progress': 0.0,
                            'swipeEdge': 0,
                          }
                        : null,
                  ),
                ),
                (_) {},
              );
            }
          } else {
            await tester.binding.handlePopRoute();
          }
          await tester.pumpAndSettle();
          expect(find.byType(RecentGamesPage), findsOneWidget);
          expect(
            find.byKey(const ValueKey('delete-selected-games')),
            findsNothing,
          );
          expect(find.byType(Checkbox), findsNothing);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.text('Home'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  if (font != null) {
    testWidgets('Pixel 6a width fits results and captures the real layout', (
      tester,
    ) async {
      await show(tester, width: 393);
      expect(find.byKey(const ValueKey('recent-table-header')), findsOneWidget);
      final row = find.byKey(const ValueKey('recent-game-row-4'));
      final result = find.descendant(
        of: row,
        matching: find.text('Incomplete'),
      );
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: result, matching: find.byType(RichText)),
      );
      final boxes = paragraph.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 10),
      );
      expect(boxes, hasLength(1));
      expect(
        boxes.single.right,
        lessThanOrEqualTo(tester.getSize(result).width),
      );
      expect(tester.takeException(), isNull);
      final output = Platform.environment['MAIA_LAYOUT_CAPTURE'];
      if (output != null) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byType(RepaintBoundary).first,
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(output).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}

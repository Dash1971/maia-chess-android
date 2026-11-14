// Deterministic captures of the production ReviewPage selection and Flutter painters.
// No neural inference, model download, or app setting changes are involved.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:chess/chess.dart' as chess;
import 'package:chessground/chessground.dart' as cg;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

String hex(Color color) =>
    '#${color.toARGB32().toRadixString(16).substring(2)}';

void main() {
  final fixtures = jsonDecode(
    File('test/fixtures/arrow_behavior.json').readAsStringSync(),
  ) as Map;
  final output = Platform.environment['ARROW_CAPTURE_DIR'];
  final results = <Map<String, dynamic>>[];
  setUpAll(() async {
    await OpeningNames.load();
    final font = Platform.environment['ARROW_CAPTURE_FONT'];
    if (font != null) {
      await (FontLoader('Roboto')..addFont(
            Future.value(ByteData.sublistView(File(font).readAsBytesSync())),
          ))
          .load();
    }
  });
  tearDownAll(() {
    if (output != null) {
      Directory(output).createSync(recursive: true);
      File(
        '$output/mobile-results.json',
      ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(results));
    }
  });
  test(
    'all fixture roots, named pieces and selected badge moves are legal',
    () {
      for (final c in fixtures['cases'] as List) {
        final fen = c['fen'] as String;
        final game = chess.Chess.fromFEN(fen);
        final roots = <String>{
          ...List<String>.from(c['sf'] as List),
          if (c['maia'] != null) c['maia'] as String,
          if (c['second'] != null) c['second'] as String,
        };
        for (final uci in roots) {
          final replay = chess.Chess.fromFEN(fen);
          expect(
            replay.move({
              'from': uci.substring(0, 2),
              'to': uci.substring(2, 4),
              if (uci.length > 4) 'promotion': uci[4],
            }),
            isTrue,
            reason: '${c['id']}: $uci',
          );
        }
        const roles = {
          'p': 'pawn',
          'n': 'knight',
          'b': 'bishop',
          'r': 'rook',
          'q': 'queen',
          'k': 'king',
        };
        for (final entry in (c['expectedPieces'] as Map).entries) {
          final piece = game.get(entry.key as String);
          expect(piece, isNotNull, reason: '${c['id']}: ${entry.key}');
          expect(
            '${piece!.color.name.toLowerCase()} ${roles[piece.type.name]}',
            entry.value,
          );
        }
        if (c['badge'] != null) {
          final last = c['lastMove'] as String;
          final replay = chess.Chess.fromFEN(c['previousFen'] as String);
          expect(
            replay.move({
              'from': last.substring(0, 2),
              'to': last.substring(2, 4),
            }),
            isTrue,
          );
          expect(
            replay.fen.split(' ').take(4).join(' '),
            fen.split(' ').take(4).join(' '),
          );
          expect(last.substring(2, 4), c['badgeSquare']);
          expect(game.get(c['badgeSquare'] as String)!.color, isNot(game.turn));
        }
      }
    },
  );
  for (final c in fixtures['cases'] as List) {
    for (final orientation in dc.Side.values) {
      testWidgets(
        '${c['id']} ${orientation.name}: real selection, arrows and badge',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(1100, 1000));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final sf = List<String>.from(c['sf'] as List);
          final fen = c['fen'] as String;
          await tester.pumpWidget(
            MaterialApp(
              home: ReviewPage(
                key: ValueKey('${c['id']}-${orientation.name}'),
                positions: [fen],
                uciMoves: const [],
                sanMoves: const [],
                playerIsWhite: orientation == dc.Side.white,
                pgn: '*',
                onHome: () {},
                maiaElo: 1600,
                secondMaiaElo: 2600,
                evaluator: (_) async => StockfishReview(
                  0,
                  sf.isEmpty ? '(none)' : sf.first,
                  lines: [
                    for (final move in sf)
                      StockfishLine(evaluation: 0, moves: [move]),
                  ],
                ),
                maiaEvaluator: (_, elo) async =>
                    (elo == 1600 ? c['maia'] : c['second']) as String?,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final original = tester.widget<cg.Chessboard>(
            find.byType(cg.Chessboard),
          );
          final shapes = original.shapes;
          final overlays = find.byKey(const ValueKey('review-board-overlay'));
          final agreements = overlays.evaluate().isEmpty
              ? <ReviewAgreementArrow>[]
              : (tester.widget<CustomPaint>(overlays).painter!
                        as ReviewBoardOverlayPainter)
                    .agreementArrows;
          final descriptor = <Map<String, dynamic>>[
            for (final arrow in shapes.whereType<cg.Arrow>())
              {
                'uci': '${arrow.orig.name}${arrow.dest.name}',
                'tail': [hex(arrow.color)],
                'head': [hex(arrow.color)],
                'layer': 'ordinary',
              },
            for (final arrow in agreements)
              {
                'uci': arrow.uci,
                'tail': arrow.tailColors.map(hex).toList(),
                'head': arrow.headColors.map(hex).toList(),
                'layer': 'agreement',
              },
          ];
          final unique = {
            ...sf,
            if (c['maia'] != null) c['maia'],
            if (c['second'] != null) c['second'],
          };
          // Chessground's ordinary Arrow stores endpoints; promotion suffix remains
          // in ReviewAgreementArrow only. Compare destination geometry separately.
          expect(
            descriptor.map((a) => (a['uci'] as String).substring(0, 4)).toSet(),
            unique.map((move) => (move as String).substring(0, 4)).toSet(),
          );
          expect(descriptor, hasLength(unique.length));
          expect(
            descriptor
                .skipWhile((a) => a['layer'] == 'ordinary')
                .every((a) => a['layer'] == 'agreement'),
            isTrue,
          );
          final classification = MoveClassification.values
              .where((v) => v.name == c['badge'])
              .firstOrNull;
          final boundaryKey = GlobalKey();
          final size = (c['size'] as num?)?.toDouble() ?? 400;
          final controller = cg.ChessboardController(
            game: cg.GameData(
              fen: fen,
              playerSide: cg.PlayerSide.none,
              sideToMove: fen.split(' ')[1] == 'w'
                  ? dc.Side.white
                  : dc.Side.black,
              validMoves: const {},
              lastMove: c['lastMove'] == null
                  ? null
                  : dc.NormalMove.fromUci(c['lastMove'] as String),
            ),
          );
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: RepaintBoundary(
                    key: boundaryKey,
                    child: SizedBox(
                      width: size,
                      height: size,
                      child: Stack(
                        children: [
                          cg.Chessboard(
                            size: size,
                            controller: controller,
                            orientation: orientation,
                            shapes: shapes,
                            settings: original.settings.copyWith(
                              animationDuration: Duration.zero,
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: ReviewBoardOverlayPainter(
                                  orientation: orientation,
                                  agreementArrows: agreements,
                                  annotationSquare: classification == null
                                      ? null
                                      : c['badgeSquare'] as String,
                                  classification: classification,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (output != null) {
            // Allow asynchronous SVG asset decode in the real Chessground board.
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 60)),
            );
            await tester.pumpAndSettle();
          }
          if (output != null) {
            await tester.runAsync(() async {
              Directory(output).createSync(recursive: true);
              final image =
                  await (boundaryKey.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage(pixelRatio: 1);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File('$output/${c['id']}-${orientation.name}.png')
                  .writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          results.add({
            'id': c['id'],
            'orientation': orientation.name,
            'arrows': descriptor,
            'badge': c['badge'],
          });
          await tester.pumpWidget(const SizedBox.shrink());
          controller.dispose();
        },
      );
    }
  }
}

import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:chess/chess.dart' as chess;
import 'package:chessground/chessground.dart' as cg;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManualStopwatch extends Stopwatch {
  int milliseconds = 0;
  @override
  int get elapsedMilliseconds => milliseconds;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final directory = Platform.environment['MAIA_FONT_DIR'];
    if (directory == null) return;
    for (final (family, path) in [
      ('Roboto', '$directory/Roboto-Regular.ttf'),
      ('MaterialIcons', '$directory/MaterialIcons-Regular.otf'),
      ('LichessIcons', 'assets/fonts/LichessIcons.ttf'),
    ]) {
      final loader = FontLoader(family)
        ..addFont(File(path).readAsBytes().then(ByteData.sublistView));
      await loader.load();
    }
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, (_) async => null);
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, null),
  );
  test('PGN JSON round-trip retains nested siblings, comments and NAGs', () {
    const pgn =
        '[Event "Notes"]\n[Result "*"]\n\n{Introduction} 1. e4 \$1 {Main} (1. d4 {Queen pawn} d5 (1... Nf6 \$5)) e5 (1... c5 {Sicilian}) 2. Nf3 *';
    final session = AnalysisSession.fromPgn(pgn);
    final restored = AnalysisSession.fromJson(
      jsonDecode(jsonEncode(session.toJson())),
    );
    final tree = PgnVariationExporter.parseTree(restored.pgn)
        .map(
          (line) =>
              RecordedVariation.fromJson(jsonDecode(jsonEncode(line.toJson()))),
        )
        .toList();
    final output = PgnVariationExporter.export(restored.pgn, [], tree);
    final parsed = dc.PgnGame.parsePgn(output);
    expect(parsed.moves.children.map((node) => node.data.san), ['e4', 'd4']);
    expect(parsed.moves.children.first.children.map((node) => node.data.san), [
      'e5',
      'c5',
    ]);
    expect(parsed.moves.children.last.children.map((node) => node.data.san), [
      'd5',
      'Nf6',
    ]);
    expect(parsed.moves.children.first.data.nags, [1]);
    for (final note in ['Introduction', 'Main', 'Queen pawn', 'Sicilian']) {
      expect(output, contains(note));
    }
    expect(AnalysisSession.fromPgn(output).sanMoves, ['e4', 'e5', 'Nf3']);
  });

  test('PGN headers cannot hide malformed or truncated movetext', () {
    expect(
      () => AnalysisSession.fromPgn(
        '[Event "Broken"]\n[Result "*"]\n\n1. DefinitelyNotAMove *',
      ),
      throwsFormatException,
    );
    expect(
      () => AnalysisSession.fromPgn(
        '[Event "Broken"]\n[Result "*"]\n\n1. e4 e5 2. garbage *',
      ),
      throwsFormatException,
    );
    expect(
      AnalysisSession.fromPgn('[Event "Empty"]\n[Result "*"]\n\n*').sanMoves,
      isEmpty,
    );
  });

  testWidgets('a move arriving after flag fall cannot gain an increment', (
    tester,
  ) async {
    final clock = ManualStopwatch();
    final session = AnalysisSession.start();
    await ActiveSessionStore.save({
      'type': 'game',
      'pgn': session.pgn,
      'positions': session.positions,
      'uciMoves': [],
      'timePreset': 'blitz',
      'whiteMillis': 50,
      'blackMillis': 180000,
      'clockPaused': true,
      'playerIsWhite': true,
    });
    await tester.pumpWidget(
      MaterialApp(home: GamePage(clockFactory: () => clock)),
    );
    await tester.pumpAndSettle();
    clock.milliseconds = 51;
    tester.widget<cg.Chessboard>(find.byType(cg.Chessboard)).onMove!(
      dc.NormalMove.fromUci('e2e4'),
    );
    await tester.pumpAndSettle();
    final saved = await ActiveSessionStore.load();
    expect(saved!['uciMoves'], isEmpty);
    expect(saved['whiteMillis'], 0);
    expect(saved['forcedResult'], '0-1');
  });

  testWidgets('game checkpoints use timezone-stable UTC timestamps', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GamePage(
          startingFen: chess.Chess.DEFAULT_POSITION,
          startingSide: PlayerSide.white,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final saved = await ActiveSessionStore.load();
    expect(saved!['type'], 'game');
    expect(DateTime.parse(saved['savedAt'] as String).isUtc, isTrue);
  });

  testWidgets('a future saved timestamp cannot add clock time', (tester) async {
    final clock = ManualStopwatch();
    final session = AnalysisSession.start();
    await ActiveSessionStore.save({
      'type': 'game',
      'pgn': session.pgn,
      'positions': session.positions,
      'uciMoves': <String>[],
      'timePreset': 'blitz',
      'whiteMillis': 1000,
      'blackMillis': 180000,
      'clockPaused': false,
      'savedAt': DateTime.now()
          .add(const Duration(minutes: 1))
          .toUtc()
          .toIso8601String(),
      'playerIsWhite': true,
    });

    await tester.pumpWidget(
      MaterialApp(home: GamePage(clockFactory: () => clock)),
    );
    await tester.pumpAndSettle();

    expect(find.text('0:01.0'), findsOneWidget);
    expect(find.text('1:01'), findsNothing);
  });

  testWidgets('Retry completes the failed Maia turn once', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(
          startingFen: chess.Chess.DEFAULT_POSITION,
          startingSide: PlayerSide.black,
          maiaEvaluator: (_, _) async {
            if (++attempts == 1) throw StateError('unavailable');
            final policy = Float32List(4352)..fillRange(0, 4352, -100);
            policy[MaiaEncoding.moveIndex('e2e4', false)] = 100;
            return policy;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Retry'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.textContaining('Maia error'), findsNothing);
    expect((await ActiveSessionStore.load())!['uciMoves'], ['e2e4']);
  });

  testWidgets('restored review returns to its paused active game', (
    tester,
  ) async {
    final session = AnalysisSession.fromPgn('1. e4 e5 *');
    await ActiveSessionStore.save({
      'type': 'review',
      'session': session.toJson(),
      'treeIsAuthoritative': true,
      'variations': PgnVariationExporter.parseTree(session.pgn)
          .map((v) => v.toJson())
          .toList(),
      'currentFen': session.positions.last,
      'activeGame': {
        'pgn': session.pgn,
        'playerIsWhite': true,
        'clockPaused': true,
      },
    });
    await tester.pumpWidget(const MaterialApp(home: GamePage()));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Back to game'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to game'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('game-board')), findsOneWidget);
    final restored = await ActiveSessionStore.load();
    expect(restored!['type'], 'game');
    expect(restored['uciMoves'], ['e2e4', 'e7e5']);
  });

  testWidgets('covering review with another page pauses full-game analysis', (
    tester,
  ) async {
    final session = AnalysisSession.fromPgn('1. e4 e5 *');
    final gate = Completer<StockfishReview>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [maiaRouteObserver],
        home: ReviewPage(
          positions: session.positions,
          uciMoves: session.uciMoves,
          sanMoves: session.sanMoves,
          pgn: session.pgn,
          playerIsWhite: true,
          onHome: () {},
          evaluator: (_) {
            if (++calls == 2) return gate.future;
            return Future.value(const StockfishReview(0, 'e2e4'));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('graph-tab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('run-computer-analysis')));
    await tester.pump();
    expect(calls, 2);
    unawaited(
      Navigator.of(tester.element(find.byType(ReviewPage))).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Editor')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    gate.complete(const StockfishReview(0, 'e7e5'));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  for (final (name, size, scale) in [
    ('portrait', const Size(360, 720), 1.0),
    ('small-large-text', const Size(320, 568), 2.0),
    ('landscape', const Size(800, 360), 1.0),
    ('landscape-large-text', const Size(800, 360), 2.0),
  ]) {
    for (final review in [false, true]) {
      testWidgets('${review ? 'review' : 'play'} fits $name', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final session = AnalysisSession.fromPgn(
          '1. e4 c5 2. Nf3 d6 3. d4 cxd4 *',
        );
        final capture = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: capture,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData.dark(useMaterial3: true).copyWith(
                textTheme: ThemeData.dark().textTheme.apply(
                  fontFamily: 'Roboto',
                ),
              ),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: review
                  ? ReviewPage(
                      positions: session.positions,
                      uciMoves: session.uciMoves,
                      sanMoves: session.sanMoves,
                      pgn: session.pgn,
                      playerIsWhite: true,
                      onHome: () {},
                      evaluator: (_) async => const StockfishReview(
                        23,
                        'e2e4',
                        lines: [
                          StockfishLine(
                            evaluation: 23,
                            moves: ['e2e4', 'c7c5'],
                          ),
                          StockfishLine(
                            evaluation: 12,
                            moves: ['d2d4', 'd7d5'],
                          ),
                        ],
                      ),
                      maiaEvaluator: (_, _) async => 'e2e4',
                    )
                  : const GamePage(
                      startingFen: chess.Chess.DEFAULT_POSITION,
                      startingSide: PlayerSide.white,
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
        final directory = Platform.environment['MAIA_CAPTURE_DIR'];
        if (directory != null) {
          final boundary =
              capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File('$directory/${review ? 'review' : 'play'}-$name.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      });
    }
  }
}

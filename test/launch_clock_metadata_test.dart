import 'package:chess/chess.dart' as chess;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

void main() {
  test(
    'incomplete and malformed histories retain their original ply indices',
    () {
      final history = restoreClockHistory([
        [60000, 60000],
        null,
        [50000],
        [-1, 30000],
        ['bad', 2],
        [42001, 31009],
      ], 7);
      expect(history.length, 7);
      expect(history.first!.whiteMillis, 60000);
      for (final index in [1, 2, 3, 4, 6]) {
        expect(history[index], isNull);
      }
      expect(history[5]!.blackMillis, 31009);
      expect(restoreClockHistory(null, 3), [null, null, null]);
    },
  );

  for (final control in [(300, 5), (600, 0), (420, 13)]) {
    test(
      'PGN clocks: exact ${control.$1}+${control.$2}, no export-time deduction',
      () {
        final result = PgnClockExporter.export(
          '1. e4 e5 2. Nf3 *',
          baseSeconds: control.$1,
          incrementSeconds: control.$2,
          history: const [
            ClockSnapshot(300000, 300000),
            ClockSnapshot(299800, 300000),
            ClockSnapshot(299800, 298650),
            ClockSnapshot(301001, 298650),
          ],
        );
        final pgn = dc.PgnGame.parsePgn(result);
        expect(pgn.headers['TimeControl'], '${control.$1}+${control.$2}');
        expect(pgn.moves.mainline().map((move) => move.comments!.single), [
          '[%clk 0:04:59.800]',
          '[%clk 0:04:58.650]',
          '[%clk 0:05:01.001]',
        ]);
        expect(
          PgnClockExporter.export(
            result,
            baseSeconds: 300,
            history: const [null, ClockSnapshot(99, 99)],
          ),
          result,
        );
      },
    );
  }

  test('clock export retains imported annotations and never annotates variations', () {
    const source =
        '[TimeControl "600+7"]\n[Event "Example"]\n[Result "*"]\n\n'
        '{Intro} 1. e4 \$1 {Good [%clk 0:09:59.123]} (1. d4 \$5 {Try this} d5) '
        'e5 {Reply} (1... c5 {[%clk 0:09:57.432]}) 2. Nf3 *';
    final output = PgnClockExporter.export(
      source,
      baseSeconds: 999,
      history: const [null, ClockSnapshot(5, 5), ClockSnapshot(8, 598001)],
    );
    final parsed = dc.PgnGame.parsePgn(output);
    expect(parsed.headers['TimeControl'], '600+7');
    expect(parsed.headers['Event'], 'Example');
    expect(parsed.comments, ['Intro']);
    expect(parsed.moves.children.first.data.nags, [1]);
    expect(parsed.moves.children.last.data.nags, [5]);
    expect(parsed.moves.children.last.data.comments, ['Try this']);
    expect(output, contains('Good [%clk 0:09:59.123]'));
    expect(output, contains('Reply'));
    expect(output, contains('[%clk 0:09:58.001]'));
    expect(output, contains('[%clk 0:09:57.432]'));
    expect(RegExp(r'\[%clk ').allMatches(output).length, 3);
  });

  test('Black-to-move custom FEN clocks use the mover, not odd/even ply', () {
    final game = chess.Chess();
    game.move('e4');
    final output = PgnClockExporter.export(
      '[FEN "${game.fen}"]\n[SetUp "1"]\n\n1... e5 2. Nf3 *',
      baseSeconds: 60,
      history: const [
        ClockSnapshot(60000, 60000),
        ClockSnapshot(60000, 59999),
        ClockSnapshot(59901, 59999),
      ],
    );
    expect(
      dc.PgnGame.parsePgn(output).moves
          .mainline()
          .map((node) => node.comments!.single),
      ['[%clk 0:00:59.999]', '[%clk 0:00:59.901]'],
    );
  });

  test('unlimited and unknown histories never invent move clocks', () {
    const source = '1. e4 *';
    expect(
      PgnClockExporter.export(
        source,
        history: const [ClockSnapshot(0, 0), ClockSnapshot(0, 0)],
      ),
      source,
    );
    final output = PgnClockExporter.export(
      source,
      baseSeconds: 60,
      history: [null, null],
    );
    expect(output, isNot(contains('[%clk')));
    expect(output, contains('[TimeControl "60+0"]'));
    expect(PgnClockExporter.format(3599999), '0:59:59.999');
    expect(PgnClockExporter.format(3600000), '1:00:00.000');
    expect(PgnClockExporter.format(1), '0:00:00.001');
  });

  test('multiple premoves project repeated pieces, captures and overlapping squares', () {
    final queue = PremoveSequence();
    for (final uci in ['g1f3', 'f3g5', 'g5f3', 'e2e4']) {
      expect(
        queue.add(
          chess.Chess.DEFAULT_POSITION,
          dc.Side.white,
          dc.NormalMove.fromUci(uci),
        ),
        isTrue,
      );
    }
    final board = dc.Setup.parseFen(
      queue.project(chess.Chess.DEFAULT_POSITION, dc.Side.white),
    ).board;
    expect(board.pieceAt(dc.Square.f3), dc.Piece.whiteKnight);
    expect(board.pieceAt(dc.Square.g1), isNull);
    expect(board.pieceAt(dc.Square.e4), dc.Piece.whitePawn);
    expect(queue.destinations[dc.Square.f3], true);
    expect(queue.destinations[dc.Square.g5], false);
    expect(queue.takeNext()!.uci, 'g1f3');
    expect(queue.length, 3);
    queue.clear();
    expect(queue.isEmpty, isTrue);
  });

  for (final side in dc.Side.values) {
    test(
      'projection handles ${side.name} castling, promotion and en passant',
      () {
        final white = side == dc.Side.white;
        final fen = white
            ? '4k3/P7/8/3pP3/8/8/8/4K2R b K - 0 1'
            : '4k2r/8/8/8/3Pp3/8/p7/4K3 w k - 0 1';
        final queue = PremoveSequence();
        for (final uci
            in white
                ? ['e1h1', 'h1h2', 'a7a8n', 'e5d6']
                : ['e8h8', 'h8h7', 'a2a1n', 'e4d3']) {
          // The rook is projected onto f1/f8 by castling; its old square is empty.
          final expected = uci != (white ? 'h1h2' : 'h8h7');
          expect(queue.add(fen, side, dc.NormalMove.fromUci(uci)), expected);
        }
        final board = dc.Setup.parseFen(queue.project(fen, side)).board;
        expect(
          board.pieceAt(white ? dc.Square.f1 : dc.Square.f8)?.role,
          dc.Role.rook,
        );
        expect(
          board.pieceAt(white ? dc.Square.g1 : dc.Square.g8)?.role,
          dc.Role.king,
        );
        expect(
          board.pieceAt(white ? dc.Square.a8 : dc.Square.a1)?.role,
          dc.Role.knight,
        );
        expect(board.pieceAt(white ? dc.Square.d5 : dc.Square.d4), isNull);
      },
    );
  }
  test('premove sequence is bounded and rejects impossible geometry', () {
    final queue = PremoveSequence();
    expect(
      queue.add(
        chess.Chess.DEFAULT_POSITION,
        dc.Side.white,
        dc.NormalMove.fromUci('g1g5'),
      ),
      false,
    );
    for (var index = 0; index < 1000; index++) {
      expect(
        queue.add(
          chess.Chess.DEFAULT_POSITION,
          dc.Side.white,
          dc.NormalMove.fromUci(index.isEven ? 'g1f3' : 'f3g1'),
        ),
        index < 64,
      );
    }
    expect(queue.length, 64);
    expect(
      queue
          .project(chess.Chess.DEFAULT_POSITION, dc.Side.white)
          .split(' ')
          .first,
      chess.Chess.DEFAULT_POSITION.split(' ').first,
    );
  });
}

import 'package:chess/chess.dart' as chess;
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

List<int> frame(int type, List<int> payload) {
  final length = payload.length + 3;
  return [type, length >> 7, length & 0x7f, ...payload];
}

Set<String> occupancy(chess.Chess game) =>
    ChessnutProtocol.pieceMapFromFen(game.fen).keys.toSet();

List<int> dump(Set<String> occupied) => frame(0x86, [
  for (var index = 0; index < 64; index++)
    occupied.contains(PegasusDecoder.square(index)) ? 1 : 0,
]);

Set<String> afterMove(chess.Chess game, String uci) {
  final next = chess.Chess.fromFEN(game.fen);
  expect(
    next.move({
      'from': uci.substring(0, 2),
      'to': uci.substring(2, 4),
      if (uci.length == 5) 'promotion': uci[4],
    }),
    isTrue,
  );
  return occupancy(next);
}

void main() {
  group('SquareOffDecoder', () {
    late Duration now;
    late SquareOffDecoder decoder;
    String? add(String text) => decoder.add(text.codeUnits);
    setUp(() {
      now = Duration.zero;
      decoder = SquareOffDecoder(elapsed: () => now);
    });

    test('only exact ASCII coordinate moves produce candidates', () {
      expect(add('e2e4'), 'e2e4');
      expect(add('a7a8'), 'a7a8');
      for (final metadata in [
        'e2e4q',
        'xe2e4z',
        'E2E4',
        'e9e4',
        'i2e4',
        'BATTERY',
        '85%',
        '\n',
      ]) {
        decoder.reset();
        if (metadata.startsWith('e2e4')) {
          expect(() => add(metadata), throwsFormatException);
        } else {
          expect(add(metadata), isNull);
        }
      }
    });

    test(
      'reference ASCII whitespace trimming accepts moves and control replies',
      () {
        expect(add(' e2e4\r\n'), 'e2e4');
        expect(add('OK\r\n'), isNull);
        expect(add(' \t\r\n'), isNull);
        expect(() => add('ERR\r\n'), throwsFormatException);
      },
    );

    test('all fragmentation boundaries and bytewise move input', () {
      const move = 'e2e4';
      for (var boundary = 1; boundary < move.length; boundary++) {
        decoder.reset();
        expect(add(move.substring(0, boundary)), isNull);
        expect(add(move.substring(boundary)), move);
      }
      decoder.reset();
      expect(add('e'), isNull);
      expect(add('2'), isNull);
      expect(add('e'), isNull);
      expect(add('4'), move);
    });

    test('fragment lifetime is bounded from its first byte', () {
      expect(add('e'), isNull);
      now = const Duration(milliseconds: 600);
      expect(add('2'), isNull);
      now = const Duration(milliseconds: 1001);
      expect(add('e4'), isNull);
      decoder.reset();
      now = Duration.zero;
      expect(add('e2'), isNull);
      now = const Duration(milliseconds: 1000);
      expect(add('e4'), 'e2e4');
    });

    test('expired and backwards-clock fragments never merge', () {
      expect(add('e2'), isNull);
      now = const Duration(milliseconds: 1001);
      expect(add('e4'), isNull);
      expect(add('OK'), isNull);
      expect(add('a2a4'), 'a2a4');
      now = const Duration(seconds: 2);
      expect(add('e2'), isNull);
      now = const Duration(seconds: 1);
      expect(add('e4'), isNull);
      decoder.reset();
      expect(add('a2a4'), 'a2a4');
    });

    test('complete numeric battery notifications cannot prefix a move', () {
      for (final battery in ['0', '85', '100']) {
        expect(add(battery), isNull);
        expect(add('e2e4'), 'e2e4');
      }
      expect(add('e2'), isNull);
      expect(add('85'), isNull);
      expect(add('e2e4'), 'e2e4');
    });

    test('control tokens are handled without becoming positions', () {
      expect(add('OK'), isNull);
      expect(add('O'), isNull);
      expect(add('K'), isNull);
      expect(() => add('ERR'), throwsFormatException);
      expect(add('E'), isNull);
      expect(add('R'), isNull);
      expect(() => add('R'), throwsFormatException);
      expect(add('e2'), isNull);
      expect(() => add('ERR'), throwsFormatException);
      expect(add('e2e4'), 'e2e4');
    });

    test('coalesced messages are rejected rather than split into moves', () {
      for (final text in ['e2e4d7d5', 'e2e4OK', 'OKe2e4', 'ERRe2e4']) {
        expect(() => add(text), throwsFormatException);
        expect(add('a2a4'), 'a2a4');
      }
    });

    test('malformed prefixes clear fragments without extracting a suffix', () {
      expect(add('e2'), isNull);
      expect(add('junk'), isNull);
      expect(add('e4'), isNull);
      decoder.reset();
      expect(add('malformede2e4'), isNull);
      expect(add('a2a4'), 'a2a4');
      expect(add('e2'), isNull);
      expect(add(' '), isNull);
      expect(add('e4'), isNull);
    });

    test('reset and invalid ASCII or oversized messages discard buffers', () {
      expect(add('e2'), isNull);
      decoder.reset();
      expect(add('e4'), isNull);
      for (final bytes in [
        [-1],
        [128],
        [256],
        List.filled(65, 65),
      ]) {
        decoder.reset();
        expect(add('e2'), isNull);
        expect(() => decoder.add(bytes), throwsFormatException);
        expect(add('e2e4'), 'e2e4');
      }
      expect(add('e2'), isNull);
      expect(() => decoder.add(List.filled(63, 65)), throwsFormatException);
      expect(add('e2e4'), 'e2e4');
      expect(decoder.add(List.filled(64, 65)), isNull);
      expect(add('e2e4'), 'e2e4');
    });
  });

  group('PegasusDecoder', () {
    final initial = occupancy(chess.Chess());
    final encoded = dump(initial);

    test('all board-dump split boundaries and bytewise notifications', () {
      for (var boundary = 0; boundary <= encoded.length; boundary++) {
        final decoder = PegasusDecoder();
        final reports = [
          ...decoder.add(encoded.sublist(0, boundary)),
          ...decoder.add(encoded.sublist(boundary)),
        ];
        expect(reports, [initial], reason: 'split at $boundary');
      }
      final decoder = PegasusDecoder();
      final reports = <Set<String>>[];
      for (final byte in encoded) {
        reports.addAll(decoder.add([byte]));
      }
      expect(reports, [initial]);
    });

    test('coalesced dump and updates preserve independent snapshots', () {
      final reports = PegasusDecoder().add([
        ...encoded,
        ...frame(0x8e, [52, 0]), // e2 lifted
        ...frame(0x8e, [36, 1]), // e4 placed
      ]);
      expect(reports, [
        initial,
        initial.difference({'e2'}),
        initial.difference({'e2'}).union({'e4'}),
      ]);
      expect(PegasusDecoder.square(0), 'a8');
      expect(PegasusDecoder.square(63), 'h1');
    });

    test('every split of coalesced dump/update stream yields same reports', () {
      final stream = [
        ...encoded,
        ...frame(0x8e, [52, 0]),
      ];
      for (var boundary = 0; boundary <= stream.length; boundary++) {
        final decoder = PegasusDecoder();
        expect(
          [
            ...decoder.add(stream.sublist(0, boundary)),
            ...decoder.add(stream.sublist(boundary)),
          ],
          [
            initial,
            initial.difference({'e2'}),
          ],
          reason: 'split at $boundary',
        );
      }
    });

    test('updates before a fresh dump cannot create board state', () {
      final decoder = PegasusDecoder();
      expect(decoder.add(frame(0x8e, [36, 1])), isEmpty);
      decoder.add(encoded);
      decoder.reset();
      expect(decoder.add(frame(0x8e, [36, 1])), isEmpty);
      expect(decoder.add(encoded), [initial]);
    });

    test('reset discards partial frame and prior occupancy', () {
      final decoder = PegasusDecoder();
      decoder.add(encoded.sublist(0, 19));
      decoder.reset();
      expect(decoder.add(dump({'h1'})), [
        {'h1'},
      ]);
    });

    test('invalid framing clears state and permits a fresh dump', () {
      final invalid = <List<int>>[
        [0x01, 0, 3],
        [0x86, 0x80, 3],
        [0x86, 0, 0x80],
        [0x86, 0, 2],
        [0x86, 3, 0],
        [-1],
        [256],
        List.filled(513, 0),
        frame(0x86, List.filled(63, 0)),
        frame(0x8e, [64, 1]),
        frame(0x8e, [0, 2]),
        frame(0x8e, [0]),
      ];
      for (final bytes in invalid) {
        final decoder = PegasusDecoder()..add(encoded);
        expect(
          () => decoder.add(bytes),
          throwsFormatException,
          reason: '$bytes',
        );
        expect(decoder.add(frame(0x8e, [36, 1])), isEmpty);
        expect(decoder.add(encoded), [initial]);
      }
    });

    test('locked and unknown piece data never becomes playable occupancy', () {
      for (final code in [2, 0x7f, 0xff]) {
        final decoder = PegasusDecoder();
        expect(
          () => decoder.add(frame(0x86, List.filled(64, code))),
          throwsFormatException,
        );
        expect(decoder.add(frame(0x8e, [36, 1])), isEmpty);
      }
      for (final payload in [
        <int>[],
        [0],
        [2],
        [1, 1],
      ]) {
        final decoder = PegasusDecoder()..add(encoded);
        expect(() => decoder.add(frame(0xa5, payload)), throwsFormatException);
        expect(decoder.add(frame(0x8e, [36, 1])), isEmpty);
      }
      expect(PegasusDecoder().add(frame(0xa5, [1])), isEmpty);
    });

    test('unknown framed metadata cannot mutate occupancy', () {
      final decoder = PegasusDecoder()..add(encoded);
      expect(decoder.add(frame(0x93, [1, 2])), isEmpty);
      expect(decoder.add(frame(0x8e, [52, 0])), [
        initial.difference({'e2'}),
      ]);
    });
  });

  group('OccupancyMoveResolver', () {
    test('quiet move has one candidate after placement, none on lift only', () {
      final game = chess.Chess();
      final resolver = OccupancyMoveResolver();
      final initial = occupancy(game);
      resolver.observe(game, initial.difference({'e2'}));
      expect(resolver.candidates(game, initial.difference({'e2'})), isEmpty);
      final moved = afterMove(game, 'e2e4');
      resolver.observe(game, moved);
      final choices = resolver.candidates(game, moved);
      expect(choices, ['e2e4']);
      expect(resolver.needsConfirmation(game, choices), isFalse);
      expect(game.fen, chess.Chess.DEFAULT_POSITION);
    });

    test('capture destination ambiguity requires explicit confirmation', () {
      final game = chess.Chess.fromFEN('4k3/8/8/2p1p3/3P4/8/8/4K3 w - - 0 1');
      final resolver = OccupancyMoveResolver();
      final liftedAttacker = occupancy(game).difference({'d4'});
      resolver.observe(game, liftedAttacker);
      final choices = resolver.candidates(game, liftedAttacker);
      expect(choices, unorderedEquals(['d4c5', 'd4e5']));
      expect(resolver.needsConfirmation(game, choices), isTrue);
    });

    test('observed victim lift selects the witnessed capture destination', () {
      final game = chess.Chess.fromFEN('4k3/8/8/2p1p3/3P4/8/8/4K3 w - - 0 1');
      final resolver = OccupancyMoveResolver();
      resolver.observe(game, occupancy(game).difference({'c5'}));
      final completed = afterMove(game, 'd4c5');
      resolver.observe(game, completed);
      final choices = resolver.candidates(game, completed);
      expect(choices, ['d4c5']);
      expect(resolver.needsConfirmation(game, choices), isFalse);
    });

    test('even a unique capture needs confirmation without a victim lift', () {
      final game = chess.Chess.fromFEN('4k3/8/8/2p5/3P4/8/8/4K3 w - - 0 1');
      final resolver = OccupancyMoveResolver();
      final physical = afterMove(game, 'd4c5');
      resolver.observe(game, physical);
      final choices = resolver.candidates(game, physical);
      expect(choices, ['d4c5']);
      expect(resolver.needsConfirmation(game, choices), isTrue);
    });

    test('cancelled victim lift cannot prove a later capture', () {
      final game = chess.Chess.fromFEN('4k3/8/8/2p5/3P4/8/8/4K3 w - - 0 1');
      final resolver = OccupancyMoveResolver();
      final initial = occupancy(game);
      resolver.observe(game, initial.difference({'c5'}));
      resolver.observe(game, initial); // Victim was put back; move cancelled.
      final attackerOnlyLifted = initial.difference({'d4'});
      resolver.observe(game, attackerOnlyLifted);
      final choices = resolver.candidates(game, attackerOnlyLifted);
      expect(choices, ['d4c5']);
      expect(resolver.needsConfirmation(game, choices), isTrue);
    });

    test('all promotion identities remain candidates for user selection', () {
      final game = chess.Chess.fromFEN('4k3/P7/8/8/8/8/8/4K3 w - - 0 1');
      final resolver = OccupancyMoveResolver();
      final physical = afterMove(game, 'a7a8q');
      resolver.observe(game, physical);
      final choices = resolver.candidates(game, physical);
      expect(choices, unorderedEquals(['a7a8q', 'a7a8r', 'a7a8b', 'a7a8n']));
      expect(resolver.needsConfirmation(game, choices), isTrue);
    });

    test('en passant requires captured pawn removal as well as placement', () {
      final game = chess.Chess.fromFEN('4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1');
      final resolver = OccupancyMoveResolver();
      final incomplete = occupancy(game).difference({'e5'}).union({'d6'});
      resolver.observe(game, incomplete);
      expect(resolver.candidates(game, incomplete), isEmpty);
      final physical = afterMove(game, 'e5d6');
      resolver.observe(game, physical);
      final choices = resolver.candidates(game, physical);
      expect(choices, ['e5d6']);
      expect(resolver.needsConfirmation(game, choices), isFalse);
    });

    test('castling resolves only after both king and rook are placed', () {
      final game = chess.Chess.fromFEN('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
      final resolver = OccupancyMoveResolver();
      final kingOnly = occupancy(game).difference({'e1'}).union({'g1'});
      resolver.observe(game, kingOnly);
      expect(resolver.candidates(game, kingOnly), isEmpty);
      final physical = afterMove(game, 'e1g1');
      resolver.observe(game, physical);
      final choices = resolver.candidates(game, physical);
      expect(choices, ['e1g1']);
      expect(resolver.needsConfirmation(game, choices), isFalse);
    });

    test(
      'new logical position and explicit reset discard old lift evidence',
      () {
        final game = chess.Chess();
        final resolver = OccupancyMoveResolver();
        resolver.observe(game, occupancy(game).difference({'a2'}));
        expect(resolver.lifted, contains('a2'));
        game.move('e4');
        resolver.observe(game, occupancy(game));
        expect(resolver.lifted, isEmpty);
        resolver.observe(game, occupancy(game).difference({'a2'}));
        resolver.reset();
        expect(resolver.lifted, isEmpty);
      },
    );
  });
}

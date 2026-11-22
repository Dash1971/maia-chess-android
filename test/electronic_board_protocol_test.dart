import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

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
}

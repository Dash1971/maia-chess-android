import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

void main() {
  Map<String, Object> packet(List<Object> data, {bool ready = true}) => {
    'type': 'position',
    'data': data,
    'nativeReady': ready,
    'gattPresent': ready,
    'deviceName': 'PRIVATE-BOARD',
  };
  final valid = List<int>.filled(32, 0);
  final bad = [0x0e, ...List<int>.filled(31, 0)];

  test('failure-only diagnostics, throttling and automatic recovery', () {
    var ms = 100;
    final decoder = ChessnutEventDecoder(detailed: true, elapsedMs: () => ms);
    expect(decoder.decode(packet(valid)).diagnostic, isNull);
    ms = 300;
    final error = decoder.decode(packet(bad));
    expect(error.diagnostic, contains('lastValidAgoMs=200'));
    expect(error.diagnostic, contains('byteOffset=0 nibble=0 pieceCode=0xe'));
    expect(error.diagnostic, contains('excerptOffset=0 excerpt=0e00'));
    expect(error.diagnostic, isNot(contains('PRIVATE')));
    for (var i = 0; i < 1000; i++) {
      ms++;
      expect(decoder.decode(packet(bad)).diagnostic, isNull);
    }
    ms = 10300;
    expect(decoder.decode(packet(bad)).diagnostic, contains('failures=1002'));
    ms = 10400;
    final recovered = decoder.decode(packet(valid));
    expect(recovered.connectionState, ElectronicBoardConnectionState.ready);
    expect(
      recovered.diagnostic,
      contains('recovery=valid-position afterMs=10100'),
    );
    expect(recovered.diagnostic, contains('afterReconnect=false'));
    expect(decoder.decode(packet(valid)).diagnostic, isNull);
  });

  test(
    'stable/unknown flavor omits byte context and no frame gets persisted',
    () {
      final event = ChessnutEventDecoder().decode(packet(bad));
      expect(event.diagnostic, isNot(contains('excerpt')));
      expect(event.diagnostic, isNot(contains('byteOffset')));
      expect(event.diagnostic, contains('lastValidAgoMs=unknown'));
    },
  );

  test('reported 38-byte error includes notification-relative offset', () {
    final data = [0x01, 0x24, 0, 0xe0, ...List<int>.filled(30, 0), 0, 0, 0, 0];
    final event = ChessnutEventDecoder(detailed: true).decode(packet(data));
    expect(event.diagnostic, contains('payloadLength=38'));
    expect(event.diagnostic, contains('byteOffset=3 nibble=1 pieceCode=0xe'));
    expect(event.diagnostic, contains('excerptOffset=2 excerpt=00e000'));
  });

  test('reconnect is distinguished from decode recovery without reconnect', () {
    var ms = 0;
    final decoder = ChessnutEventDecoder(elapsedMs: () => ms);
    decoder.decode(packet(bad));
    decoder.decode({'type': 'status', 'state': 'disconnected'});
    ms = 1000;
    decoder.decode({'type': 'status', 'state': 'scanning'});
    decoder.decode({'type': 'status', 'state': 'ready'});
    ms = 1200;
    expect(
      decoder.decode(packet(valid)).diagnostic,
      contains('afterMs=1200 failures=1 afterReconnect=true'),
    );
  });

  test('a valid frame cannot manufacture native connection readiness', () {
    final decoder = ChessnutEventDecoder();
    decoder.decode(packet(bad));
    final recovered = decoder.decode(packet(valid, ready: false));
    expect(recovered.connectionState, isNull);
    expect(
      recovered.diagnostic,
      contains('nativeReady=false gattPresent=false'),
    );
  });

  test(
    'malformed platform values are bounded errors, never stream exceptions',
    () {
      for (final data in [
        null,
        'secret',
        [double.nan],
        [1.5],
        [true],
        ['private'],
        [-1, ...List.filled(31, 0)],
        [256, ...List.filled(31, 0)],
        List.filled(513, 0),
        [],
      ]) {
        final event = ChessnutEventDecoder(detailed: true)
            .decode({'type': 'position', 'data': data});
        expect(event.connectionState, ElectronicBoardConnectionState.error);
        expect(event.diagnostic, isNot(contains('secret')));
        expect(event.diagnostic, isNot(contains('private')));
      }
    },
  );

  test(
    'reviewed replay is deterministic and drives the production decoder',
    () {
      final records = File('test/fixtures/board_protocol/decode-recovery.jsonl')
          .readAsLinesSync()
          .map((s) => jsonDecode(s) as Map<String, dynamic>)
          .toList();
      List<String> replay() {
        var ms = 0;
        final decoder = ChessnutEventDecoder(
          detailed: true,
          elapsedMs: () => ms,
        );
        final output = <String>[];
        for (final r in records.skip(1)) {
          ms = r['t_ms'] as int;
          if (r['direction'] != 'rx' || r['characteristic'] != 'data') continue;
          final hex = r['hex'] as String;
          final bytes = [
            for (var i = 0; i < hex.length; i += 2)
              int.parse(hex.substring(i, i + 2), radix: 16),
          ];
          final e = decoder.decode(packet(bytes));
          output.add('${e.type}|${e.position?['e4']}|${e.diagnostic}');
        }
        return output;
      }

      expect(replay(), replay());
      expect(replay(), hasLength(3));
      expect(replay()[1], contains('pieceCode=0xe'));
      expect(replay().last, contains('position|P|'));
      expect(replay().last, contains('afterMs=200'));
    },
  );
}

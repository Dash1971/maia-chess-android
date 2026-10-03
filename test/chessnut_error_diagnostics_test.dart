import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('maia_chess/chessnut/events');
  const codec = StandardMethodCodec();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    messenger.setMockMethodCallHandler(channel, (_) async => null);
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  Future<ElectronicBoardEvent> decode(Object? value) async {
    final next = ChessnutPlatformTransport.instance.events.first;
    // Let the EventChannel install its listener before delivering an event.
    await Future<void>.delayed(Duration.zero);
    final delivered = Completer<void>();
    messenger.handlePlatformMessage(
      channel.name,
      codec.encodeSuccessEnvelope(value),
      (_) => delivered.complete(),
    );
    await delivered.future;
    return next;
  }

  test(
    'malformed position reports reason and link flags without packet data',
    () async {
      final event = await decode({
        'type': 'position',
        'data': [0xdd, ...List<int>.filled(31, 0)],
        'nativeReady': true,
        'gattPresent': true,
        'deviceName': 'Private board name',
      });

      expect(event.connectionState, ElectronicBoardConnectionState.error);
      expect(event.diagnostic, contains('errorSource=position-decode'));
      expect(event.diagnostic, contains('Unknown Chessnut piece code'));
      expect(event.diagnostic, contains('payloadLength=32'));
      expect(event.diagnostic, contains('nativeReady=true gattPresent=true'));
      expect(event.diagnostic, isNot(contains('Private board name')));
      expect(event.diagnostic, isNot(contains('[221,')));
    },
  );

  test('native error reason reaches the diagnostic event', () async {
    final event = await decode({
      'type': 'status',
      'state': 'error',
      'message': 'Connection failed.',
      'diagnostic': 'errorSource=native reason=connection-failed nativeReady=false gattPresent=false',
    });

    expect(event.connectionState, ElectronicBoardConnectionState.error);
    expect(event.diagnostic, contains('reason=connection-failed'));
    expect(event.message, 'Connection failed.');
  });
}

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

  final channelCalls = <String>[];
  setUp(() {
    channelCalls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      channelCalls.add(call.method);
      return null;
    });
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

  test('concurrent listeners each receive recovery and cancellation releases native stream', () async {
    final a = StreamIterator(ChessnutPlatformTransport.instance.events);
    final b = StreamIterator(ChessnutPlatformTransport.instance.events);
    Future<void> send(List<int> bytes) async {
      final pending = [a.moveNext(), b.moveNext()];
      await Future<void>.delayed(Duration.zero);
      messenger.handlePlatformMessage(
        channel.name,
        codec.encodeSuccessEnvelope({
          'type': 'position',
          'data': bytes,
          'nativeReady': true,
          'gattPresent': true,
        }),
        (_) {},
      );
      expect(await Future.wait(pending), [true, true]);
    }

    await send([0x0e, ...List<int>.filled(31, 0)]);
    expect(a.current.diagnostic, contains('failures=1'));
    expect(b.current.diagnostic, contains('failures=1'));
    await send(List<int>.filled(32, 0));
    for (final event in [a.current, b.current]) {
      expect(event.connectionState, ElectronicBoardConnectionState.ready);
      expect(event.diagnostic, contains('recovery=valid-position'));
    }
    await a.cancel();
    expect(channelCalls.where((call) => call == 'cancel'), isEmpty);
    await b.cancel();
    await Future<void>.delayed(Duration.zero);
    expect(channelCalls.where((call) => call == 'cancel'), hasLength(1));
    // A new subscription starts a new observation interval; no stale recovery.
    final fresh = await decode({
      'type': 'position',
      'data': List<int>.filled(32, 0),
    });
    expect(fresh.diagnostic, isNull);
  });

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

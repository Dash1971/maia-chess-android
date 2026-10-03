import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('maia_chess/sound_effect');
  const codec = StandardMethodCodec();
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  Future<void> notify(String method) async {
    final done = Completer<void>();
    messenger.handlePlatformMessage(
      channel.name,
      codec.encodeMethodCall(MethodCall(method, {'soundId': 'move'})),
      (_) => done.complete(),
    );
    await done.future;
  }

  test('native request failure reaches the caller', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'sound_load_failed');
    });
    await expectLater(
      SoundEffect().load('move', 'missing.mp3'),
      throwsA(isA<PlatformException>()),
    );
  });

  for (final success in [true, false]) {
    test('early native callback stays handled (success=$success)', () async {
      messenger.setMockMethodCallHandler(channel, (_) async {
        await notify(success ? 'onLoadComplete' : 'onLoadError');
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return null;
      });
      final load = SoundEffect().load('move', 'asset.mp3');
      if (success) {
        await load;
      } else {
        await expectLater(load, throwsStateError);
      }
    });
  }

  test('release during a pending request stays handled', () async {
    final reply = Completer<void>();
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'load') await reply.future;
      return null;
    });
    final player = SoundEffect();
    final checked = expectLater(
      player.load('move', 'asset.mp3'),
      throwsStateError,
    );
    await Future<void>.delayed(Duration.zero);
    await player.release();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    reply.complete();
    await checked;
  });

  test('late request failure does not remove a replacement load', () async {
    final firstReply = Completer<void>();
    var requests = 0;
    messenger.setMockMethodCallHandler(channel, (_) async {
      if (++requests == 1) await firstReply.future;
      return null;
    });
    final player = SoundEffect();
    final replaced = expectLater(
      player.load('move', 'first.mp3'),
      throwsStateError,
    );
    final replacement = player.load('move', 'second.mp3');
    firstReply.completeError(PlatformException(code: 'sound_load_failed'));
    await replaced;
    await Future<void>.delayed(Duration.zero);
    await notify('onLoadComplete');
    await replacement;
  });

  test('unknown callback does not consume the pending load', () async {
    final load = SoundEffect().load('move', 'asset.mp3');
    await notify('unrelated');
    await notify('onLoadComplete');
    await load;
  });

  for (final missingReply in [false, true]) {
    testWidgets(
      'lost native completion is bounded (missingReply=$missingReply)',
      (tester) async {
        final reply = Completer<void>();
        messenger.setMockMethodCallHandler(channel, (_) async {
          if (missingReply) await reply.future;
          return null;
        });
        final load = SoundEffect().load('move', 'asset.mp3');
        final checked = expectLater(load, throwsA(isA<TimeoutException>()));
        await tester.pump(const Duration(seconds: 11));
        await checked;
        // Late platform replies and callbacks must remain harmless after timeout.
        reply.complete();
        await tester.pump();
        await notify('onLoadError');
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  }

  test('waits for native load completion and clamps playback volume', () async {
    final player = SoundEffect();
    await player.initialize(maxStreams: 2);
    expect(calls.single.method, 'initialize');
    expect(calls.single.arguments, {'maxStreams': 2});

    var loaded = false;
    final load = player
        .load('move', 'assets/sounds/standard/move.mp3')
        .then((_) => loaded = true);
    await Future<void>.delayed(Duration.zero);
    expect(loaded, isFalse);
    expect(calls.last.method, 'load');

    final callback = Completer<void>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          channel.name,
          codec.encodeMethodCall(
            const MethodCall('onLoadComplete', {'soundId': 'move'}),
          ),
          (_) => callback.complete(),
        );
    await callback.future;
    await load;
    expect(loaded, isTrue);

    await player.play('move', volume: 2);
    expect(calls.last.method, 'play');
    expect(calls.last.arguments, {'soundId': 'move', 'volume': 1.0});
  });
}

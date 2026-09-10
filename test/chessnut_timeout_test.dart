import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('maia_chess/chessnut');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));
  for (final command in ['setLeds', 'beep']) {
    testWidgets(
      '$command with a lost native completion closes the stalled connection',
      (tester) async {
        final gate = Completer<void>();
        var disconnects = 0;
        Object? error;
        messenger.setMockMethodCallHandler(channel, (call) async {
          if (call.method == command) await gate.future;
          if (call.method == 'disconnect') disconnects++;
          return null;
        });
        final transport = ChessnutPlatformTransport.instance;
        final future =
            (command == 'setLeds'
                    ? transport.setLeds(['e2', 'e4'])
                    : transport.beep())
                .catchError((Object caught) {
                  error = caught;
                });
        await tester.pump(const Duration(seconds: 11));
        await tester.pump();
        final closed = disconnects;
        final failure = error;
        gate.complete();
        await tester.pump();
        await future;
        expect(closed, 1);
        expect(
          failure,
          isA<PlatformException>().having(
            (e) => e.code,
            'code',
            'write_timeout',
          ),
        );
      },
    );
  }
  testWidgets('an old command timeout cannot disconnect a newer connection', (
    tester,
  ) async {
    final gate = Completer<void>();
    var disconnects = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'setLeds') await gate.future;
      if (call.method == 'disconnect') disconnects++;
      return null;
    });
    final transport = ChessnutPlatformTransport.instance;
    final pending = transport.setLeds(['e2', 'e4']).catchError((Object _) {});
    await tester.pump();
    await transport.disconnect();
    await transport.connect();
    await tester.pump(const Duration(seconds: 11));
    gate.complete();
    await tester.pump();
    await pending;
    expect(disconnects, 1);
  });
}

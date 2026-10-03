import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

void main() {
  testWidgets('navigator exposes two large controls with long-press jumps', (
    tester,
  ) async {
    final feedback = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate' ||
            call.method == 'SystemSound.play') {
          feedback.add(call);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    var selected = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MoveHistoryNavigator(
            previousKey: const ValueKey('previous'),
            nextKey: const ValueKey('next'),
            canGoBack: true,
            canGoForward: true,
            onFirst: () => selected = 'first',
            onPrevious: () => selected = 'previous',
            onNext: () => selected = 'next',
            onLast: () => selected = 'last',
          ),
        ),
      ),
    );

    for (final key in const ['previous', 'next']) {
      final size = tester.getSize(find.byKey(ValueKey(key)));
      expect(size.height, 56);
      expect(size.width, greaterThanOrEqualTo(72));
    }
    expect(find.bySemanticsLabel('Previous move'), findsOneWidget);
    expect(find.bySemanticsLabel('Next move'), findsOneWidget);
    expect(find.byIcon(Icons.first_page), findsNothing);
    expect(find.byIcon(Icons.last_page), findsNothing);

    await tester.tap(find.byKey(const ValueKey('previous')));
    expect(selected, 'previous');
    await tester.tap(find.byKey(const ValueKey('next')));
    expect(selected, 'next');
    await tester.longPress(find.byKey(const ValueKey('previous')));
    expect(selected, 'first');
    await tester.longPress(find.byKey(const ValueKey('next')));
    expect(selected, 'last');
    expect(feedback, isEmpty, reason: 'Browsing history is silent');
  });

  testWidgets('navigator keeps large arrows below actions on narrow layouts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(280, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Scaffold(
            body: MoveHistoryNavigator(
              previousKey: const ValueKey('previous'),
              nextKey: const ValueKey('next'),
              canGoBack: true,
              canGoForward: true,
              onFirst: () {},
              onPrevious: () {},
              onNext: () {},
              onLast: () {},
              headerActionWidth: 56,
              headerActions: const [
                Icon(Icons.menu, key: ValueKey('action-1')),
                Icon(Icons.flip, key: ValueKey('action-2')),
                Icon(Icons.power, key: ValueKey('action-3')),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getCenter(find.byKey(const ValueKey('action-1'))).dy,
      lessThan(tester.getCenter(find.byKey(const ValueKey('previous'))).dy),
    );
    for (final key in const ['previous', 'next']) {
      final size = tester.getSize(find.byKey(ValueKey(key)));
      expect(size.height, 56);
      expect(size.width, greaterThanOrEqualTo(72));
    }
    expect(tester.takeException(), isNull);
  });
}

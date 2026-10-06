import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a slow initial read cannot override a new user selection', () async {
    final read = Completer<Object?>();
    final writes = <String?>[];
    final controller = AppLanguageController(
      read: () => read.future,
      write: (code) async {
        writes.add(code);
      },
    );
    addTearDown(controller.dispose);
    final initialize = controller.initialize();
    await controller.select('es');
    read.complete('ja');
    await initialize;
    expect(controller.selectedCode, 'es');
    expect(writes, ['es']);
  });

  test(
    'rapid selections serialize writes; the latest selection wins',
    () async {
      final firstWrite = Completer<void>();
      final writes = <String?>[];
      final controller = AppLanguageController(
        read: () async => null,
        write: (code) async {
          writes.add(code);
          if (writes.length == 1) await firstWrite.future;
        },
      );
      addTearDown(controller.dispose);
      final first = controller.select('ja');
      final second = controller.select('ko');
      final third = controller.select(null);
      await Future<void>.delayed(Duration.zero);
      expect(writes, ['ja']);
      expect(controller.selectedCode, isNull);
      firstWrite.complete();
      await Future.wait([first, second, third]);
      expect(writes, ['ja', 'ko', null]);
      expect(controller.persistenceFailed, isFalse);
    },
  );

  test('read failure falls back without throwing or changing a game', () async {
    SharedPreferences.setMockInitialValues({'activeSessionV1': 'retained'});
    final controller = AppLanguageController(
      read: () async => throw StateError('read failed'),
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    expect(controller.selectedCode, isNull);
    expect(controller.persistenceFailed, isTrue);
    expect(
      (await SharedPreferences.getInstance()).getString('activeSessionV1'),
      'retained',
    );
  });

  test(
    'failed write is reported; retry succeeds and clears the warning',
    () async {
      var fail = true;
      final controller = AppLanguageController(
        write: (_) async {
          if (fail) throw StateError('disk failure');
        },
      );
      addTearDown(controller.dispose);
      await controller.select('zh');
      expect(controller.selectedCode, 'zh');
      expect(controller.persistenceFailed, isTrue);
      fail = false;
      await controller.select('zh');
      expect(controller.persistenceFailed, isFalse);
    },
  );

  test(
    'an obsolete write failure cannot mark a newer selection failed',
    () async {
      final pending = Completer<void>();
      final controller = AppLanguageController(
        write: (code) async {
          if (code == 'ja') {
            await pending.future;
            throw StateError('old write');
          }
        },
      );
      addTearDown(controller.dispose);
      final old = controller.select('ja');
      final latest = controller.select('es');
      pending.complete();
      await Future.wait([old, latest]);
      expect(controller.selectedCode, 'es');
      expect(controller.persistenceFailed, isFalse);
    },
  );

  test(
    'invalid stored choice is removed before a later valid selection',
    () async {
      final writes = <String?>[];
      final controller = AppLanguageController(
        read: () async => 42,
        write: (code) async {
          writes.add(code);
        },
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      await controller.select('ko');
      expect(writes, [null, 'ko']);
      expect(controller.selectedCode, 'ko');
    },
  );

  test('late completion after disposal does not notify', () async {
    final pending = Completer<Object?>();
    final controller = AppLanguageController(read: () => pending.future);
    var notifications = 0;
    controller.addListener(() => notifications++);
    final initialize = controller.initialize();
    controller.dispose();
    pending.complete('ja');
    await initialize;
    expect(notifications, 0);
  });

  test('regional and script-aware locale resolution is deliberate', () {
    final supported = AppLocalizations.supportedLocales;
    for (final locale in [
      const Locale('zh', 'CN'),
      const Locale('zh', 'SG'),
      const Locale('zh'),
      const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hans',
        countryCode: 'HK',
      ),
    ]) {
      expect(resolveAppLocale([locale], supported), const Locale('zh'));
    }
    for (final locale in [
      const Locale('zh', 'TW'),
      const Locale('zh', 'HK'),
      const Locale('zh', 'MO'),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    ]) {
      expect(resolveAppLocale([locale], supported), const Locale('en'));
      expect(
        resolveAppLocale([locale, const Locale('ja')], supported),
        const Locale('ja'),
      );
    }
    expect(
      resolveAppLocale([const Locale('es', 'MX')], supported),
      const Locale('es'),
    );
    expect(
      resolveAppLocale([const Locale('ko', 'KR')], supported),
      const Locale('ko'),
    );
    expect(
      resolveAppLocale([const Locale('it'), const Locale('es')], supported),
      const Locale('es'),
    );
    for (final locale in [
      const Locale('de', 'DE'),
      const Locale('de', 'AT'),
      const Locale('de', 'CH'),
      const Locale('fr', 'FR'),
      const Locale('fr', 'CA'),
      const Locale('ru', 'RU'),
      const Locale('ru', 'KZ'),
      const Locale('hi', 'IN'),
      const Locale('pt'),
      const Locale('pt', 'BR'),
      const Locale('pt', 'PT'),
    ]) {
      expect(
        resolveAppLocale([locale], supported),
        Locale(locale.languageCode),
      );
    }
  });
}

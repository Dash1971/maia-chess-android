import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/l10n/app_localizations.dart';
import 'package:maia_chess/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

const annotated = '''[Event "Annotated"]
[Date "2026.11.13"]
[White "Player"]
[Black "Maia"]
[Result "1-0"]

{ Opening note with [Result "0-1"] and * inside a comment }
1. e4 { [%clk 0:04:58] café } e5 (1... c5 { Sicilian }) 2. Nf3 \$1 Nc6 1-0
''';
const incomplete = '[Event "Incomplete"]\n[Result "*"]\n\n1. d4 d5 *';
const setup = '''[Event "Setup"]
[SetUp "1"]
[FEN "4k3/4p3/8/8/8/8/4P3/4K3 w - - 0 1"]
[Result "*"]

1. e4 e5 *''';
final sources = {'one': annotated, 'two': incomplete, 'three': setup};
final games = [
  for (final entry in sources.entries)
    RecentSession(entry.key, DateTime.utc(2026, 11, 13), {
      'type': 'game',
      'pgn': entry.value,
    }),
];

List<dc.PgnGame<dc.PgnNodeData>> parse(String pgn) =>
    dc.PgnGame.parseMultiGamePgn(pgn, initHeaders: dc.PgnGame.emptyHeaders);

Future<void> waitForExport(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 100; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final blocked = tester
        .widgetList<AbsorbPointer>(find.byType(AbsorbPointer))
        .any((w) => w.absorbing && w.child is Scaffold);
    if (!blocked) {
      await tester.pumpAndSettle();
      return;
    }
  }
  fail('Export did not complete');
}

Widget page({
  Future<String?> Function(String)? read,
  List<RecentSession>? records,
  String locale = 'en',
  double scale = 1,
}) => MaterialApp(
  locale: Locale(locale),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: RecentGamesPage(
    loadGames: () async => records ?? games,
    readPgnForExport: read ?? (id) async => sources[id],
  ),
);

Future<void> select(WidgetTester tester, List<String> ids) async {
  await tester.longPress(find.byKey(ValueKey('recent-game-${ids.first}')));
  await tester.pumpAndSettle();
  for (final id in ids.skip(1)) {
    await tester.tap(find.byKey(ValueKey('recent-game-$id')));
    await tester.pumpAndSettle();
  }
}

Future<void> export(WidgetTester tester, {bool share = false}) async {
  await tester.tap(find.byKey(const ValueKey('export-selected-games')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(share ? 'Share PGN' : 'Save PGN file'));
  await waitForExport(tester);
}

// Size the serialized record, including headers/comments and the separator,
// rather than assuming source length equals the final UTF-8 export size.
Future<String> gameWithExportSize(int bytes) async {
  const template = '[Event "Sized"]\n\n{x} *';
  final baseline = await RecentGamesPgn.export([
    'sample',
  ], (_) async => template);
  return template.replaceFirst(
    '{x}',
    '{${'x' * (bytes - utf8.encode(baseline).length + 1)}}',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, null);
  });

  test('one or several games round-trip with metadata, comments, clocks, NAGs and variations', () async {
    for (final ids in [
      ['one'],
      ['one', 'two', 'three'],
    ]) {
      final pgn = await RecentGamesPgn.export(ids, (id) async => sources[id]);
      final parsed = parse(pgn);
      expect(parsed, hasLength(ids.length));
      expect(pgn, endsWith('\n\n'));
      for (var i = 0; i < ids.length; i++) {
        final original = dc.PgnGame.parsePgn(
          sources[ids[i]]!,
          initHeaders: dc.PgnGame.emptyHeaders,
        );
        expect(parsed[i].headers, original.headers);
        expect(parsed[i].makePgn(), original.makePgn());
      }
      expect(parsed.first.headers['Result'], '1-0');
      expect(pgn, contains('[%clk 0:04:58]'));
      expect(pgn, contains('café'));
      expect(pgn, contains('Sicilian'));
      expect(pgn, contains('\$1'));
    }
  });

  test('rejects empty, duplicate, missing, illegal and multi-game records without silent omissions', () async {
    expect(RecentGamesPgn.export([], (_) async => '*'), throwsFormatException);
    expect(
      RecentGamesPgn.export(['a', 'a'], (_) async => '*'),
      throwsFormatException,
    );
    expect(
      RecentGamesPgn.export(['a'], (_) async => null),
      throwsFormatException,
    );
    expect(
      RecentGamesPgn.export(['a'], (_) async => '1. e5 *'),
      throwsFormatException,
    );
    expect(
      RecentGamesPgn.export(['a'], (_) async => '$incomplete\n\n$annotated'),
      throwsFormatException,
    );
    expect(
      RecentGamesPgn.export(['a'], (_) async => '1. e4 * 1. d4 *'),
      throwsFormatException,
    );
  });

  test('PGN escape lines do not become moves or erase percent lines inside comments', () async {
    const pgn =
        '   % ignored before headers\n[Event "Escapes"]\n\n{ Note % inside the comment stays }\n1. e4 *';
    final output = await RecentGamesPgn.export(['a'], (_) async => pgn);
    expect(output, contains('inside the comment stays'));
    expect(dc.PgnGame.parsePgn(output).headers['Event'], 'Escapes');
    expect(output, isNot(contains('ignored before headers')));
  });

  test(
    'tag-like text and result tokens inside multiline comments remain one game',
    () async {
      const pgn =
          '[Event "Real"]\n\n{ Note\n\n[Event "Fake"]\n* 0-1 }\n1. e4 *';
      final output = await RecentGamesPgn.export(['a'], (_) async => pgn);
      expect(dc.PgnGame.parsePgn(output).headers['Event'], 'Real');
      expect(output, contains('Fake'));
    },
  );

  test('UTF-8 and combined-file size are bounded before invoking any document action', () async {
    final unicode = '{${'😀' * (RecentGamesPgn.maxBytes ~/ 4)}} *';
    expect(unicode.length, lessThan(RecentGamesPgn.maxBytes));
    expect(
      RecentGamesPgn.export(['a'], (_) async => unicode),
      throwsA(isA<PgnExportGameTooLarge>()),
    );
    final reads = <String>[];
    // Each game remains below the unchanged 5 MiB individual parser limit.
    final large =
        '[Event "Large"]\n\n{${'x' * (RecentGamesPgn.maxBytes ~/ 3 + 100)}} *';
    await expectLater(
      RecentGamesPgn.export(['a', 'b', 'c', 'd'], (id) async {
        reads.add(id);
        return large;
      }),
      throwsA(isA<PgnExportTooLarge>()),
    );
    expect(reads, ['a', 'b', 'c']);
  });

  test(
    'combined export accepts exactly 5 MiB and rejects one byte over',
    () async {
      const oneMiB = 1024 * 1024;
      final game = await gameWithExportSize(oneMiB);
      final ids = List.generate(5, (i) => '$i');
      for (final delta in [-1, 0, 1]) {
        final last = await gameWithExportSize(oneMiB + delta);
        final result = RecentGamesPgn.export(
          ids,
          (id) async => id == '4' ? last : game,
        );
        if (delta > 0) {
          await expectLater(result, throwsA(isA<PgnExportTooLarge>()));
        } else {
          expect(utf8.encode(await result).length, 5 * oneMiB + delta);
        }
      }
    },
  );

  test('single-game imports still reject more than 5 MiB of UTF-8', () {
    final oversized = '{${'x' * (5 * 1024 * 1024)}} *';
    expect(() => AnalysisSession.fromPgn(oversized), throwsFormatException);
    final multibyte = '{${'😀' * (5 * 1024 * 1024 ~/ 4)}} *';
    expect(multibyte.length, lessThan(5 * 1024 * 1024));
    expect(() => AnalysisSession.fromPgn(multibyte), throwsFormatException);
  });

  test('individual export limit is distinct from the collection limit', () async {
    for (final delta in [-1, 0, 1]) {
      const prefix = '[Event "Sized"]\n\n';
      final pgn =
          '$prefix{${'x' * (AnalysisSession.maxPgnBytes + delta - prefix.length - 4)}} *';
      expect(utf8.encode(pgn).length, AnalysisSession.maxPgnBytes + delta);
      final result = RecentGamesPgn.export(['one'], (_) async => pgn);
      if (delta > 0) {
        await expectLater(result, throwsA(isA<PgnExportGameTooLarge>()));
      } else {
        expect(() => AnalysisSession.fromPgn(pgn), returnsNormally);
        // Normalized headers/separators must also fit the same 5 MiB cap.
        await expectLater(result, throwsA(isA<PgnExportGameTooLarge>()));
      }
    }
    final multibyte = '{${'😀' * (AnalysisSession.maxPgnBytes ~/ 4)}} *';
    expect(multibyte.length, lessThan(AnalysisSession.maxPgnBytes));
    await expectLater(
      RecentGamesPgn.export(['one'], (_) async => multibyte),
      throwsA(isA<PgnExportGameTooLarge>()),
    );
    await expectLater(
      RecentGamesPgn.export([
        'one',
      ], (_) async => 'x' * (RecentGamesPgn.maxBytes + 1)),
      throwsA(isA<PgnExportGameTooLarge>()),
    );
  });

  test(
    'a large collection exports sequentially in the supplied order',
    () async {
      final ids = List.generate(200, (i) => 'game-$i');
      var active = 0, maximum = 0;
      final result = await RecentGamesPgn.export(ids, (id) async {
        active++;
        if (active > maximum) maximum = active;
        await Future<void>.delayed(Duration.zero);
        active--;
        return '[Event "$id"]\n\n1. e4 *';
      });
      expect(maximum, 1);
      expect(parse(result).map((g) => g.headers['Event']), ids);
    },
  );

  test('repository export reads archived/active records without changing any stored bytes or dates', () async {
    final dir = await Directory.systemTemp.createTemp('maia-export-');
    addTearDown(() => dir.delete(recursive: true));
    final repo = SessionRepository(dir);
    await repo.save({'type': 'game', 'pgn': annotated});
    await repo.startNew();
    await repo.save({'type': 'game', 'pgn': incomplete});
    final recent = await repo.recent();
    Future<Map<String, String>> snapshot() async => {
      await for (final f in dir.list(recursive: true))
        if (f is File) f.path: await f.readAsString(),
    };
    final before = await snapshot();
    final output = await RecentGamesPgn.export(
      recent.map((g) => g.id).toList(),
      repo.readPgnForExport,
    );
    expect(parse(output), hasLength(2));
    expect(await snapshot(), before);
    expect((await repo.load())!['pgn'], incomplete);
    expect(await repo.readPgnForExport('missing'), isNull);
    expect(await snapshot(), before);
  });

  testWidgets('selected Save uses display order and preserves the selection', (
    tester,
  ) async {
    final calls = <MethodCall>[], reads = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(maiaEngineChannel, (call) async {
          if (call.method == 'savePgnFile') {
            calls.add(call);
            return true;
          }
          return null;
        });
    await tester.pumpWidget(
      page(
        read: (id) async {
          reads.add(id);
          return sources[id];
        },
      ),
    );
    await tester.pumpAndSettle();
    await select(tester, ['three', 'one']);
    await export(tester);
    expect(reads, ['one', 'three']);
    expect(calls.single.method, 'savePgnFile');
    expect(
      parse((calls.single.arguments as Map)['pgn'] as String)
          .map((g) => g.headers['Event']),
      ['Annotated', 'Setup'],
    );
    expect(find.text('2 selected'), findsOneWidget);
    expect(find.text('PGN saved'), findsOneWidget);
  });

  testWidgets(
    'oversized 10000-game selection saves nothing, retains selection and permits retry',
    (tester) async {
      const message =
          'Selected games exceed the 5 MB export limit. Select fewer games and try again.';
      final large = (await tester.runAsync(
        () => gameWithExportSize(1024 * 1024),
      ))!;
      final records = [
        for (var i = 0; i < 10000; i++)
          RecentSession('game-$i', DateTime.utc(2026, 11, 13), {
            'type': 'game',
            'pgn': incomplete,
          }),
      ];
      final calls = <MethodCall>[];
      final reads = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(maiaEngineChannel, (call) async {
            calls.add(call);
            return true;
          });
      await tester.pumpWidget(
        page(
          records: records,
          read: (id) async {
            reads.add(id);
            return large;
          },
        ),
      );
      await tester.pumpAndSettle();
      await select(tester, ['game-0']);
      await tester.tap(find.byKey(const ValueKey('select-all-games')));
      await tester.pumpAndSettle();
      final strings = AppLocalizations.of(
        tester.element(find.byType(RecentGamesPage)),
      )!;
      expect(find.text(strings.recentSelectedCount(10000)), findsOneWidget);
      for (final share in [false, true]) {
        reads.clear();
        await export(tester, share: share);
        expect(reads, List.generate(6, (i) => 'game-$i'));
        expect(
          calls.where(
            (c) => c.method == 'sharePgn' || c.method == 'savePgnFile',
          ),
          isEmpty,
        );
        expect(find.text(message), findsOneWidget);
        expect(find.text(strings.recentSelectedCount(10000)), findsOneWidget);
      }
      await tester.tap(find.byKey(const ValueKey('select-all-games')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('recent-game-game-0')));
      await tester.pumpAndSettle();
      await export(tester);
      expect(calls.where((c) => c.method == 'savePgnFile').length, 1);
      expect(find.text('1 selected'), findsOneWidget);
      expect(records.every((r) => r.data['pgn'] == incomplete), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Select all shares all games through the existing native chooser',
    (tester) async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(maiaEngineChannel, (call) async {
            if (call.method == 'sharePgn') calls.add(call);
            return null;
          });
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();
      await select(tester, ['two']);
      await tester.tap(find.byKey(const ValueKey('select-all-games')));
      await tester.pumpAndSettle();
      await export(tester, share: true);
      expect(calls.single.method, 'sharePgn');
      expect(
        parse((calls.single.arguments as Map)['pgn'] as String),
        hasLength(3),
      );
      expect((calls.single.arguments as Map)['shareTitle'], 'Share PGN');
      expect(find.text('3 selected'), findsOneWidget);
    },
  );

  testWidgets(
    'save cancellation and native failure retain selection and allow retry',
    (tester) async {
      var attempt = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(maiaEngineChannel, (call) async {
            if (call.method != 'savePgnFile') return null;
            attempt++;
            if (attempt == 1) return null;
            if (attempt == 2) throw PlatformException(code: 'document_failed');
            return true;
          });
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();
      await select(tester, ['one']);
      await export(tester);
      expect(find.text('PGN saved'), findsNothing);
      expect(find.text('1 selected'), findsOneWidget);
      await export(tester);
      expect(
        find.text(
          'Could not export the selected games. Saved games were not changed.',
        ),
        findsOneWidget,
      );
      expect(find.text('1 selected'), findsOneWidget);
      await export(tester);
      expect(attempt, 3);
      expect(find.text('PGN saved'), findsOneWidget);
    },
  );

  testWidgets(
    'missing or unreadable selected record never invokes native export',
    (tester) async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(maiaEngineChannel, (call) async {
            calls.add(call);
            return null;
          });
      await tester.pumpWidget(
        page(read: (id) async => id == 'two' ? null : sources[id]),
      );
      await tester.pumpAndSettle();
      await select(tester, ['one', 'two']);
      await export(tester);
      expect(
        calls.where((c) => c.method == 'sharePgn' || c.method == 'savePgnFile'),
        isEmpty,
      );
      expect(find.text('2 selected'), findsOneWidget);
      expect(
        find.text(
          'Could not export the selected games. Saved games were not changed.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'empty selection disables export and concurrent callbacks are ignored',
    (tester) async {
      final read = Completer<String?>();
      var reads = 0;
      await tester.pumpWidget(
        page(
          read: (_) {
            reads++;
            return read.future;
          },
        ),
      );
      await tester.pumpAndSettle();
      await select(tester, ['one']);
      await tester.tap(find.byKey(const ValueKey('select-all-games')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('select-all-games')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PopupMenuButton<bool>>(
              find.byKey(const ValueKey('export-selected-games')),
            )
            .enabled,
        isFalse,
      );
      await tester.tap(find.byKey(const ValueKey('recent-game-one')));
      await tester.pumpAndSettle();
      final menu = tester.widget<PopupMenuButton<bool>>(
        find.byKey(const ValueKey('export-selected-games')),
      );
      final cancel = tester.widget<IconButton>(
        find.byWidgetPredicate(
          (w) => w is IconButton && w.tooltip == 'Cancel selection',
        ),
      );
      final all = tester.widget<IconButton>(
        find.byKey(const ValueKey('select-all-games')),
      );
      menu.onSelected!(false);
      menu.onSelected!(false);
      cancel.onPressed!();
      all.onPressed!();
      expect(reads, 1);
      read.complete(null);
      await waitForExport(tester);
      expect(find.text('1 selected'), findsOneWidget);
    },
  );

  for (final locale in [
    'en',
    'ja',
    'zh',
    'ko',
    'es',
    'de',
    'fr',
    'ru',
    'hi',
    'pt',
  ]) {
    testWidgets(
      '$locale oversized individual game keeps selection and allows retry',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final calls = <MethodCall>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(maiaEngineChannel, (call) async {
              calls.add(call);
              return true;
            });
        var oversized = true;
        final pgn = '{${'x' * (AnalysisSession.maxPgnBytes - 3)}} *';
        await tester.pumpWidget(
          page(
            locale: locale,
            scale: 2,
            read: (_) async => oversized ? pgn : incomplete,
          ),
        );
        await tester.pumpAndSettle();
        await select(tester, ['one']);
        final strings = AppLocalizations.of(
          tester.element(find.byType(RecentGamesPage)),
        )!;
        final menu = find.byKey(const ValueKey('export-selected-games'));
        for (final share in [false, true]) {
          await tester.tap(menu);
          await tester.pumpAndSettle();
          await tester.tap(
            find.text(share ? strings.sharePgn : strings.savePgnFile),
          );
          await waitForExport(tester);
          expect(find.text(strings.recentExportGameTooLarge), findsOneWidget);
          expect(find.text(strings.recentExportTooLarge), findsNothing);
          expect(find.text(strings.recentExportFailed), findsNothing);
          expect(find.text(strings.recentSelectedCount(1)), findsOneWidget);
          expect(
            calls.where(
              (call) =>
                  call.method == 'savePgnFile' || call.method == 'sharePgn',
            ),
            isEmpty,
          );
          expect(tester.takeException(), isNull);
          await tester.pump(const Duration(seconds: 5));
          await tester.pumpAndSettle();
        }
        oversized = false;
        await tester.tap(menu);
        await tester.pumpAndSettle();
        await tester.tap(find.text(strings.savePgnFile));
        await waitForExport(tester);
        expect(
          calls
              .where(
                (call) =>
                    call.method == 'savePgnFile' || call.method == 'sharePgn',
              )
              .single
              .method,
          'savePgnFile',
        );
        expect(find.text(strings.recentSelectedCount(1)), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '$locale selection, export menu and size error fit 320px at 200% text',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          page(
            locale: locale,
            scale: 2,
            read: (_) async => throw const PgnExportTooLarge(),
          ),
        );
        await tester.pumpAndSettle();
        await select(tester, ['one']);
        final target = find.byKey(const ValueKey('export-selected-games'));
        expect(target.hitTestable(), findsOneWidget);
        await tester.tap(target);
        await tester.pumpAndSettle();
        final strings = AppLocalizations.of(
          tester.element(find.byType(RecentGamesPage)),
        )!;
        expect(find.text(strings.savePgnFile).hitTestable(), findsOneWidget);
        expect(find.text(strings.sharePgn).hitTestable(), findsOneWidget);
        await tester.tap(find.text(strings.savePgnFile));
        await waitForExport(tester);
        expect(find.text(strings.recentExportTooLarge), findsOneWidget);
        expect(find.text(strings.recentSelectedCount(1)), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

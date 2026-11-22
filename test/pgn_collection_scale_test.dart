import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

void main() {
  test('10,000 games near 5 MiB: import, repeat import and Recent games stay responsive', () async {
    final dir = await Directory.systemTemp.createTemp('maia-import-scale-');
    addTearDown(() => dir.delete(recursive: true));
    const count = 10000;
    const template =
        '[Event "Scale 00000000"]\n[White "Alice"]\n[Black "Bob"]\n[Date "2026.11.22"]\n[Result "*"]\n\n1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 {COMMENT} *\n\n';
    final padding =
        AnalysisSession.maxPgnBytes ~/ count -
        template.length +
        'COMMENT'.length;
    final source = List.generate(
      count,
      (i) => template
          .replaceFirst('00000000', i.toString().padLeft(8, '0'))
          .replaceFirst('COMMENT', 'x' * padding),
    ).join();
    final bytes = utf8.encode(source).length;
    expect(bytes, lessThanOrEqualTo(AnalysisSession.maxPgnBytes));
    expect(bytes, greaterThan(AnalysisSession.maxPgnBytes - count));
    var ticks = 0,
        lastTick = DateTime.now(),
        worstGapMs = 0,
        peakRss = ProcessInfo.currentRss;
    final heartbeat = Timer.periodic(const Duration(milliseconds: 10), (_) {
      final now = DateTime.now();
      final gap = now.difference(lastTick).inMilliseconds;
      if (gap > worstGapMs) worstGapMs = gap;
      lastTick = now;
      ticks++;
      if (ProcessInfo.currentRss > peakRss) peakRss = ProcessInfo.currentRss;
    });
    addTearDown(heartbeat.cancel);
    final watch = Stopwatch()..start();
    final parsing = <double>[];
    final collection = await PgnCollection.parse(
      source,
      onProgress: (p) => parsing.add(p.fraction),
    );
    expect(parsing.first, 0);
    expect(parsing.last, 1);
    expect(parsing.any((value) => value > 0 && value < 1), isTrue);
    expect(parsing, orderedEquals([...parsing]..sort()));
    final parseMs = watch.elapsedMilliseconds;
    final store = SessionRepository(dir);
    final updates = <double>[];
    watch.reset();
    final first = await store.importCollection(
      collection,
      onProgress: (p) => updates.add(p.fraction),
    );
    final importMs = watch.elapsedMilliseconds;
    expect(first.imported, count);
    expect(first.duplicates, 0);
    expect(updates.length, greaterThan(2));
    expect(updates.last, 1);
    expect(updates, orderedEquals([...updates]..sort()));
    watch.reset();
    final recent = await SessionRepository(dir).recent();
    final recentMs = watch.elapsedMilliseconds;
    expect(recent, hasLength(count));
    expect(recent.first.title, 'Alice — Bob');
    watch.reset();
    final second = await store.importCollection(collection);
    final duplicateMs = watch.elapsedMilliseconds;
    expect(second.imported, 0);
    expect(second.duplicates, count);
    expect(await store.recent(), hasLength(count));
    expect(ticks, greaterThan(10));
    heartbeat.cancel();
    // Observational host timings, not phone performance promises or flaky CI deadlines.
    // ignore: avoid_print
    print(
      'PGN_SCALE games=$count bytes=$bytes parse_ms=$parseMs import_ms=$importMs recent_ms=$recentMs repeat_ms=$duplicateMs parse_progress_updates=${parsing.length} progress_updates=${updates.length} heartbeat_ticks=$ticks max_heartbeat_gap_ms=$worstGapMs process_peak_rss_bytes=$peakRss',
    );
  }, timeout: const Timeout(Duration(minutes: 4)));
}

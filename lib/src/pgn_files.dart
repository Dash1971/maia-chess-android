part of '../main.dart';

typedef PgnCollectionParser = Future<PgnCollection> Function(
  String source, {
  void Function(PgnImportProgress)? onProgress,
});

class PgnFiles {
  static PgnCollectionParser? _testParser;

  @visibleForTesting
  static void setTestParser(PgnCollectionParser? parser) {
    assert(() {
      _testParser = parser;
      return true;
    }());
  }

  static Future<void> export(
    BuildContext context,
    String pgn, {
    bool share = false,
    String? failureMessage,
  }) async {
    try {
      final saved = await maiaEngineChannel.invokeMethod<Object>(
        share ? 'sharePgn' : 'savePgnFile',
        {'pgn': pgn, if (share) 'shareTitle': l10n(context).sharePgn},
      );
      if (context.mounted && !share && saved == true) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n(context).pgnSaved)));
      }
    } catch (error, stack) {
      unawaited(AppDiagnostics.record('pgn-export', error, stack));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failureMessage ?? l10n(context).pgnExportFailed),
          ),
        );
      }
    }
  }

  static Future<AnalysisSession?> importText(
    BuildContext context,
    String text,
  ) async {
    if (!context.mounted) return null;
    final progress = ValueNotifier<double>(0);
    final visible = ValueNotifier<bool>(false);
    final navigator = Navigator.of(context, rootNavigator: true);
    final route = _PgnProgressRoute(
      visible: visible,
      progress: progress,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
    );
    // Retain the existing input/Back guard immediately, without displaying or
    // dimming anything until the import has lasted 300 ms.
    unawaited(navigator.push(route));
    final reveal = Timer(const Duration(milliseconds: 300), route.reveal);
    PgnImportResult? result;
    try {
      final collection = await (_testParser ?? PgnCollection.parse)(
        text,
        onProgress: (update) => progress.value = update.fraction / 2,
      );
      progress.value = 0.5;
      if (collection.games.length == 1) {
        final session = await AnalysisSession.fromPgnAsync(
          collection.games.single,
        );
        progress.value = 1;
        return session;
      }
      if (!context.mounted) return null;
      result = await ActiveSessionStore.importCollection(
        collection,
        onProgress: (update) => progress.value = 0.5 + update.fraction / 2,
      );
    } finally {
      reveal.cancel();
      if (navigator.mounted && route.isActive) navigator.removeRoute(route);
      progress.dispose();
      visible.dispose();
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              result.duplicates == 0
                  ? l10n(context).pgnCollectionImported(result.imported)
                  : l10n(context).pgnCollectionImportSummary(
                      result.imported,
                      result.duplicates,
                    ),
            ),
          ),
        );
    }
    return null;
  }

  static Future<AnalysisSession?> open(BuildContext context) async {
    final text = await maiaEngineChannel.invokeMethod<String>('openPgnFile');
    return text == null || !context.mounted ? null : importText(context, text);
  }
}

/// The transparent route preserves the existing busy guard for quick imports.
/// Revealing it changes only the dialog and dimming, not navigation state.
class _PgnProgressRoute extends RawDialogRoute<void> {
  _PgnProgressRoute({
    required ValueNotifier<bool> visible,
    required ValueNotifier<double> progress,
    required CapturedThemes themes,
  }) : _visible = visible,
       super(
         barrierDismissible: false,
         transitionDuration: Duration.zero,
         traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
         pageBuilder: (context, _, _) => PopScope(
           canPop: false,
           child: ValueListenableBuilder<bool>(
             valueListenable: visible,
             builder: (context, shown, _) => shown
                 ? themes.wrap(
                     SafeArea(
                       child: AlertDialog(
                         title: Text(l10n(context).pgnImportProgress),
                         content: ValueListenableBuilder<double>(
                           valueListenable: progress,
                           builder: (context, value, _) =>
                               LinearProgressIndicator(
                                 key: const ValueKey('pgn-import-progress'),
                                 value: value,
                                 semanticsLabel: l10n(context)
                                     .pgnImportProgress,
                               ),
                         ),
                       ),
                     ),
                   )
                 : const SizedBox.shrink(),
           ),
         ),
       );

  final ValueNotifier<bool> _visible;
  @override
  Color? get barrierColor =>
      _visible.value ? Colors.black54 : Colors.transparent;

  void reveal() {
    if (!isActive) return;
    _visible.value = true;
    changedInternalState();
  }
}

class PgnImportResult {
  const PgnImportResult(this.imported, this.duplicates);
  final int imported;
  final int duplicates;
}

class PgnImportProgress {
  const PgnImportProgress(this.completed, this.total);
  final int completed;
  final int total;
  double get fraction => total == 0 ? 0 : (completed / total).clamp(0, 1);
}

class PgnExportTooLarge implements Exception {
  const PgnExportTooLarge();
}

class PgnExportGameTooLarge implements Exception {
  const PgnExportGameTooLarge();
}

/// Validated PGNs only: comments and variations cannot create game boundaries.
class PgnCollection {
  PgnCollection._(this.games, this.headers);
  final List<String> games;
  final List<Map<String, String>> headers;

  static Future<PgnCollection> parse(
    String source, {
    void Function(PgnImportProgress)? onProgress,
  }) async {
    if (onProgress == null) return _runParser(source, null);
    final port = ReceivePort();
    final finished = Completer<void>();
    final subscription = port.listen((message) {
      final values = message as List<int>;
      onProgress(PgnImportProgress(values[0], values[1]));
      if (values[0] == values[1] && !finished.isCompleted) finished.complete();
    });
    try {
      onProgress(PgnImportProgress(0, source.length));
      final parsed = await _runParser(source, port.sendPort);
      // Drain the worker's ordered progress stream before handing off phases.
      await finished.future;
      onProgress(const PgnImportProgress(1, 1));
      return parsed;
    } finally {
      port.close();
      await subscription.cancel();
    }
  }

  // Keep this closure separate from callbacks/ports in the coordinating isolate.
  static Future<PgnCollection> _runParser(String source, SendPort? progress) =>
      Isolate.run(() => _parse(source, progress));

  static PgnCollection _parse(String source, SendPort? progress) {
    if (source.length > AnalysisSession.maxPgnBytes ||
        utf8.encode(source).length > AnalysisSession.maxPgnBytes) {
      throw const FormatException('PGN exceeds 5 MB.');
    }
    final text = source.replaceFirst(RegExp(r'^\uFEFF'), '');
    final tag = RegExp(r'\[([A-Za-z0-9_]+)\s+"((?:[^"\\]|\\.)*)"\s*\]');
    final result = RegExp(r'(?:1/2-1/2|1-0|0-1|\*)(?=\s|$)');
    final games = <String>[];
    final headers = <Map<String, String>>[];
    var start = 0, depth = 0;
    var brace = false, line = false, seenMove = false, ended = false;
    final reports = Stopwatch()..start();
    void report(int end, {bool force = false}) {
      if (progress != null && (force || reports.elapsedMilliseconds >= 40)) {
        progress.send(<int>[end, text.length]);
        reports.reset();
      }
    }

    void add(int end) {
      final raw = text.substring(start, end).trim();
      if (raw.isEmpty) return;
      final normalized = RecentGamesPgn._singleGame(raw).trim();
      games.add(raw);
      headers.add(
        Map.unmodifiable(
          dc.PgnGame.parsePgn(
            normalized,
            initHeaders: dc.PgnGame.emptyHeaders,
          ).headers,
        ),
      );
      // Advance only after the entire game, including variations, validates.
      report(end, force: games.length == 1);
    }

    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      if (brace) {
        if (c == '}') brace = false;
        continue;
      }
      if (line) {
        if (c == '\n' || c == '\r') line = false;
        continue;
      }
      if (c.trim().isEmpty) continue;
      if (c == '{') {
        brace = true;
        continue;
      }
      if (c == ';' ||
          (c == '%' &&
              text
                  .substring(text.lastIndexOf('\n', i) + 1, i)
                  .trim()
                  .isEmpty)) {
        line = true;
        continue;
      }
      if (depth == 0 && ((c == '[' && seenMove) || ended)) {
        add(i);
        start = i;
        seenMove = ended = false;
      }
      if (c == '[') {
        final match = tag.matchAsPrefix(text, i);
        if (depth != 0 || match == null) {
          throw const FormatException('Malformed PGN header.');
        }
        i = match.end - 1;
        continue;
      }
      if (c == '(') depth++;
      if (c == ')') depth--;
      if (depth == 0 && (i == 0 || text[i - 1].trim().isEmpty)) {
        final match = result.matchAsPrefix(text, i);
        if (match != null) {
          ended = true;
          i = match.end - 1;
        }
      }
      seenMove = true;
    }
    add(text.length);
    if (games.isEmpty) throw const FormatException('The PGN contains no game.');
    report(text.length, force: true);
    return PgnCollection._(
      List.unmodifiable(games),
      List.unmodifiable(headers),
    );
  }
}

/// Match Android's 5 MiB PGN export limit, including UTF-8 and separators.
/// Imports and individual games use the same 5 MiB limit.
/// Read and validate one game at a time; only the bounded combined PGN is retained.
class RecentGamesPgn {
  static const maxBytes = AnalysisSession.maxPgnBytes;

  static Future<String> export(
    List<String> orderedIds,
    Future<String?> Function(String id) readPgn,
  ) async {
    if (orderedIds.isEmpty || orderedIds.toSet().length != orderedIds.length) {
      throw const FormatException(
        'Expected a nonempty selection of unique games.',
      );
    }
    final output = StringBuffer();
    var bytes = 0;
    for (final id in orderedIds) {
      final source = await readPgn(id);
      if (source == null || source.trim().isEmpty) {
        throw const FormatException(
          'A selected game is missing or unreadable.',
        );
      }
      if (source.length > AnalysisSession.maxPgnBytes ||
          utf8.encode(source).length > AnalysisSession.maxPgnBytes) {
        throw const PgnExportGameTooLarge();
      }
      final game = await Isolate.run(() => _singleGame(source));
      final gameBytes = utf8.encode(game).length;
      if (gameBytes > maxBytes) throw const PgnExportGameTooLarge();
      bytes += gameBytes;
      if (bytes > maxBytes) throw const PgnExportTooLarge();
      output.write(game);
    }
    return output.toString();
  }

  static String _singleGame(String source) {
    final text = source.trim();
    _validateSingleGame(text);
    // Existing parser checks tokens, starting position and every variation,
    // preserving supported headers, comments, NAGs, clocks and branch structure.
    return '${AnalysisSession.fromPgn(text).pgn}\n\n';
  }

  static void _validateSingleGame(String text) {
    // Reject a second game instead of allowing the single-game parser to drop it.
    // Comments (including tag-like text), tags and variations cannot terminate
    // the mainline. The caller validates/re-serializes with the individual importer.
    final scan = text.replaceAll(RegExp(r'^\s*%.*$', multiLine: true), '');
    final tag = RegExp(r'\[([A-Za-z0-9_]+)\s+"((?:[^"\\]|\\.)*)"\s*\]');
    final top = StringBuffer();
    var brace = false, line = false, seenMove = false;
    var depth = 0;
    for (var i = 0; i < scan.length; i++) {
      final c = scan[i];
      if (brace) {
        if (c == '}') brace = false;
        continue;
      }
      if (line) {
        if (c == '\n' || c == '\r') {
          line = false;
          top.write(' ');
        }
        continue;
      }
      if (c == '{') {
        brace = true;
        top.write(' ');
        continue;
      }
      if (c == ';' || (c == '%' && (i == 0 || scan[i - 1] == '\n'))) {
        line = true;
        continue;
      }
      if (c == '[') {
        final match = tag.matchAsPrefix(scan, i);
        if (seenMove || depth != 0 || match == null) {
          throw const FormatException(
            'Unexpected PGN header in selected game.',
          );
        }
        i = match.end - 1;
        continue;
      }
      if (c.trim().isNotEmpty) seenMove = true;
      if (c == '(') {
        depth++;
        continue;
      }
      if (c == ')') {
        depth--;
        top.write(' ');
        continue;
      }
      if (depth == 0) top.write(c);
    }
    final mainline = top.toString();
    final result = RegExp(r'1/2-1/2|1-0|0-1|\*').firstMatch(mainline);
    if (result != null && mainline.substring(result.end).trim().isNotEmpty) {
      throw const FormatException('More than one game in a saved game record.');
    }
  }
}

part of '../main.dart';

class PgnFiles {
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
    final collection = await PgnCollection.parse(text);
    if (collection.games.length == 1) {
      return AnalysisSession.fromPgnAsync(collection.games.single);
    }
    if (!context.mounted) return null;
    final count = await ActiveSessionStore.importCollection(collection);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n(context).pgnCollectionImported(count))),
        );
    }
    return null;
  }

  static Future<AnalysisSession?> open(BuildContext context) async {
    final text = await maiaEngineChannel.invokeMethod<String>('openPgnFile');
    return text == null || !context.mounted ? null : importText(context, text);
  }
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

  static Future<PgnCollection> parse(String source) => Isolate.run(() {
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
    return PgnCollection._(
      List.unmodifiable(games),
      List.unmodifiable(headers),
    );
  });
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
      bytes += utf8.encode(game).length;
      if (bytes > maxBytes) throw const PgnExportTooLarge();
      output.write(game);
    }
    return output.toString();
  }

  static String _singleGame(String source) {
    // Reject a second game instead of allowing the single-game parser to drop it.
    // Comments (including tag-like text), tags and variations cannot terminate
    // the mainline. Validation/re-serialization below uses the individual importer.
    final text = source.trim();
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
    // Existing parser checks tokens, starting position and every variation,
    // preserving supported headers, comments, NAGs, clocks and branch structure.
    return '${AnalysisSession.fromPgn(text).pgn}\n\n';
  }
}

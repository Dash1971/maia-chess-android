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

  static Future<AnalysisSession?> open() async {
    final text = await maiaEngineChannel.invokeMethod<String>('openPgnFile');
    return text == null ? null : AnalysisSession.fromPgnAsync(text);
  }
}

class PgnExportTooLarge implements Exception {
  const PgnExportTooLarge();
}

/// Match Android's 5 MiB PGN export limit, including UTF-8 and separators.
/// Imports and the individual-game parser retain their separate 2 MiB limit.
/// Read and validate one game at a time; only the bounded combined PGN is retained.
class RecentGamesPgn {
  static const maxBytes = 5 * 1024 * 1024;

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
      if (source.length > maxBytes || utf8.encode(source).length > maxBytes) {
        throw const PgnExportTooLarge();
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

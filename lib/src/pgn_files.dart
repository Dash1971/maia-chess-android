part of '../main.dart';

class PgnFiles {
  static Future<void> export(
    BuildContext context,
    String pgn, {
    bool share = false,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n(context).pgnExportFailed)));
      }
    }
  }

  static Future<AnalysisSession?> open() async {
    final text = await maiaEngineChannel.invokeMethod<String>('openPgnFile');
    return text == null ? null : AnalysisSession.fromPgnAsync(text);
  }
}

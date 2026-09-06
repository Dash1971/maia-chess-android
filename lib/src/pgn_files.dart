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
        {'pgn': pgn},
      );
      if (context.mounted && !share && saved == true) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('PGN saved')));
      }
    } catch (error, stack) {
      unawaited(AppDiagnostics.record('pgn-export', error, stack));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not export PGN. Your game is still saved locally.',
            ),
          ),
        );
      }
    }
  }

  static Future<AnalysisSession?> open() async {
    final text = await maiaEngineChannel.invokeMethod<String>('openPgnFile');
    return text == null
        ? null
        : Isolate.run(() => AnalysisSession.fromPgn(text));
  }
}

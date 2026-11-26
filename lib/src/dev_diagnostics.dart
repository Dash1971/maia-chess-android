part of '../main.dart';

/// Automatic breadcrumbs only in the red-icon Dev app. No image/model payloads.
class DevDiagnostics {
  static void record(String event, [Map<String, String> values = const {}]) {
    if (appFlavor != 'dev') return;
    unawaited(
      maiaEngineChannel
          .invokeMethod<void>('devTraceContext', {'event': event, ...values})
          .catchError((Object _) {}),
    );
  }

  static Future<String> recentTrace() async {
    if (appFlavor != 'dev') return '';
    try {
      return await maiaEngineChannel.invokeMethod<String>('devTraceReport') ??
          '';
    } catch (_) {
      return 'Dev trace unavailable';
    }
  }

  static Future<void> save(BuildContext context) async {
    if (appFlavor != 'dev') return;
    try {
      await maiaEngineChannel.invokeMethod<Object>('saveDevDiagnostics', {
        'report': await AppDiagnostics.report(includeDevTrace: false),
      });
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n(context).devDiagnosticsExportFailed)),
        );
      }
    }
  }
}

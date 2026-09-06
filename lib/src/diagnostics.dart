part of '../main.dart';

class AppDiagnostics {
  static const _key = 'diagnosticEntriesV1';
  static const _maximumEntries = 20;
  static const _maximumEntryCharacters = 8000;
  static Future<void> _writeQueue = Future<void>.value();

  static Future<void> recordEvent(String event) async {
    await _append('${DateTime.now().toUtc().toIso8601String()} [$event]');
  }

  static Future<void> record(
    String source,
    Object error,
    StackTrace stackTrace,
  ) async {
    final entry = StringBuffer()
      ..writeln('${DateTime.now().toUtc().toIso8601String()} [$source]')
      ..writeln(error)
      ..write(stackTrace);
    await _append(entry.toString());
  }

  static Future<void> _append(String entry) async {
    _writeQueue = _writeQueue.then((_) => _writeEntry(entry));
    await _writeQueue;
  }

  static Future<void> _writeEntry(String entry) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final entries = preferences.getStringList(_key) ?? <String>[];
      entries.add(
        entry.length <= _maximumEntryCharacters
            ? entry
            : entry.substring(0, _maximumEntryCharacters),
      );
      if (entries.length > _maximumEntries) {
        entries.removeRange(0, entries.length - _maximumEntries);
      }
      await preferences.setStringList(_key, entries);
    } catch (_) {
      // Diagnostics must never trigger another application failure.
    }
  }

  static Future<String> report() async {
    String version = 'unknown';
    String build = 'unknown';
    try {
      final package = await PackageInfo.fromPlatform();
      version = package.version;
      build = package.buildNumber;
    } catch (_) {}
    final preferences = await SharedPreferences.getInstance();
    final entries = preferences.getStringList(_key) ?? const <String>[];
    return [
      'Mobile Maia diagnostics',
      'version=$version build=$build',
      'exported=${DateTime.now().toUtc().toIso8601String()}',
      if (entries.isEmpty) 'No recorded errors.',
      ...entries,
    ].join('\n\n');
  }

  static Future<void> copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: await report()));
  }
}

class DiagnosticsErrorScreen extends StatelessWidget {
  const DiagnosticsErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xff171a18),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.orange, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Mobile Maia encountered a screen error.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Copy the diagnostics and send them with a description of '
                  'what you tapped immediately before this screen appeared.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: AppDiagnostics.copyToClipboard,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy diagnostics'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

bool isPremoveDestination(String fen, String from, String to) {
  final pieces = cg.readFen(fen);
  return cg
      .premovesOf(dc.Square.fromName(from), pieces, canCastle: true)
      .contains(dc.Square.fromName(to));
}

part of '../main.dart';

class AppDiagnostics {
  static const _key = 'diagnosticEntriesV1';
  static const _maximumEntries = 40;
  static const _maximumEntryCharacters = 8000;
  static const _maximumTotalCharacters = 128000;
  static const _maximumAge = Duration(days: 14);
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
      final entries = _prune(
        preferences.getStringList(_key) ?? const <String>[],
        DateTime.now().toUtc(),
      );
      entries.add(
        entry.length <= _maximumEntryCharacters
            ? entry
            : entry.substring(0, _maximumEntryCharacters),
      );
      await preferences.setStringList(
        _key,
        _prune(entries, DateTime.now().toUtc()),
      );
    } catch (_) {
      // Diagnostics must never trigger another application failure.
    }
  }

  static List<String> _prune(List<String> source, DateTime now) {
    final cutoff = now.subtract(_maximumAge);
    final entries = source
        .map(
          (entry) => entry.length <= _maximumEntryCharacters
              ? entry
              : entry.substring(0, _maximumEntryCharacters),
        )
        .where((entry) {
          final separator = entry.indexOf(' ');
          if (separator <= 0) return true;
          final timestamp = DateTime.tryParse(entry.substring(0, separator));
          return timestamp == null || !timestamp.toUtc().isBefore(cutoff);
        })
        .toList(growable: true);
    if (entries.length > _maximumEntries) {
      entries.removeRange(0, entries.length - _maximumEntries);
    }
    var total = entries.fold<int>(0, (sum, entry) => sum + entry.length);
    while (entries.length > 1 && total > _maximumTotalCharacters) {
      total -= entries.removeAt(0).length;
    }
    return entries;
  }

  static String _mib(Object? bytes) {
    if (bytes is! num) return 'unknown';
    return (bytes.toDouble() / (1024 * 1024)).toStringAsFixed(1);
  }

  static String _text(Object? value) {
    final result = value?.toString().trim();
    return result == null || result.isEmpty ? 'unknown' : result;
  }

  static Future<List<String>> _platformReport() async {
    if (!Platform.isAndroid) return ['platform=${Platform.operatingSystem}'];
    try {
      final value = await maiaEngineChannel.invokeMethod<Object?>(
        'systemDiagnostics',
      );
      if (value is! Map) return const ['androidDiagnostics=unavailable'];
      final data = Map<String, dynamic>.from(value);
      final abis = (data['supportedAbis'] as List? ?? const [])
          .map((item) => item.toString())
          .join(',');
      final bluetooth = data['bluetooth'] is Map
          ? Map<String, dynamic>.from(data['bluetooth'] as Map)
          : const <String, dynamic>{};
      final lines = <String>[
        'device=${_text(data['manufacturer'])} ${_text(data['model'])} '
            'device=${_text(data['device'])} product=${_text(data['product'])}',
        'android=${_text(data['androidRelease'])} sdk=${_text(data['sdkInt'])} '
            'securityPatch=${_text(data['securityPatch'])} '
            'buildId=${_text(data['buildId'])} '
            'buildDisplay=${_text(data['buildDisplay'])}',
        'abis=${abis.isEmpty ? 'unknown' : abis} '
            'pageSizeBytes=${_text(data['pageSizeBytes'])} '
            'processors=${_text(data['processors'])}',
        'ramMiB=total:${_mib(data['ramTotalBytes'])} '
            'available:${_mib(data['ramAvailableBytes'])} '
            'lowThreshold:${_mib(data['ramLowThresholdBytes'])} '
            'low:${_text(data['ramLow'])} '
            'lowRamDevice:${_text(data['lowRamDevice'])} '
            'lowMemoryKillReports:${_text(data['lowMemoryKillReportSupported'])}',
        'heapMiB=class:${_text(data['memoryClassMb'])} '
            'largeClass:${_text(data['largeMemoryClassMb'])} '
            'max:${_mib(data['heapMaxBytes'])} '
            'total:${_mib(data['heapTotalBytes'])} '
            'free:${_mib(data['heapFreeBytes'])}',
        'storageMiB=free:${_mib(data['storageFreeBytes'])} '
            'total:${_mib(data['storageTotalBytes'])} '
            'modelCache:${_mib(data['modelCacheBytes'])} '
            'modelExpected:${_mib(data['modelCacheExpectedBytes'])} '
            'modelValid:${_text(data['modelCacheValid'])}',
        'bluetooth=available:${_text(bluetooth['available'])} '
            'enabled:${_text(bluetooth['enabled'])} '
            'permissions:${_text(bluetooth['permissions'])} '
            'state:${_text(bluetooth['state'])} '
            'ready:${_text(bluetooth['ready'])} '
            'scanActive:${_text(bluetooth['scanActive'])} '
            'gattPresent:${_text(bluetooth['gattPresent'])} '
            'lastGattStatus:${_text(bluetooth['lastGattStatus'])} '
            'scanAttempts:${_text(bluetooth['scanAttempts'])} '
            'unexpectedDisconnects:${_text(bluetooth['unexpectedDisconnects'])} '
            'pendingWrites:${_text(bluetooth['pendingWrites'])}',
      ];
      final exits = data['previousExits'] as List? ?? const [];
      if (exits.isEmpty) {
        lines.add('previousExit=none-or-unavailable');
      } else {
        for (var index = 0; index < exits.length; index++) {
          final raw = exits[index];
          if (raw is! Map) continue;
          final exit = Map<String, dynamic>.from(raw);
          final timestamp = exit['timestampMs'] is num
              ? DateTime.fromMillisecondsSinceEpoch(
                  (exit['timestampMs'] as num).toInt(),
                  isUtc: true,
                ).toIso8601String()
              : 'unknown';
          lines.add(
            'previousExit[$index]=timestamp:$timestamp '
            'reason:${_text(exit['reasonName'])}(${_text(exit['reason'])}) '
            'status:${_text(exit['status'])} '
            'importance:${_text(exit['importance'])} '
            'pssKiB:${_text(exit['pssKb'])} rssKiB:${_text(exit['rssKb'])} '
            'state:${_text(exit['stateSummary'])} '
            'description:${_text(exit['description'])}',
          );
        }
      }
      return lines;
    } catch (_) {
      return const ['androidDiagnostics=unavailable'];
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
    final entries = _prune(
      preferences.getStringList(_key) ?? const <String>[],
      DateTime.now().toUtc(),
    );
    await preferences.setStringList(_key, entries);
    final platform = await _platformReport();
    final analysisQuality = GameAnalysisQuality.fromStoredName(
      preferences.getString(gameAnalysisQualityPreferenceKey),
    );
    return [
      'Mobile Maia diagnostics',
      'version=$version build=$build',
      'exported=${DateTime.now().toUtc().toIso8601String()}',
      'retention=maxAgeDays:${_maximumAge.inDays} '
          'maxEntries:$_maximumEntries '
          'maxEntryCharacters:$_maximumEntryCharacters '
          'maxTotalCharacters:$_maximumTotalCharacters',
      'gameAnalysisQuality=${analysisQuality.name} '
          'depth=${analysisQuality.depth} '
          'moveTimeMs=${analysisQuality.moveTimeMs}',
      ...platform,
      if (entries.isEmpty) 'No recorded diagnostic events.',
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

part of '../main.dart';

const samplingCapturePreference = 'saveMaiaSamplingDataV1';

/// Separate from diagnostics. No inference, network access, or random draws.
class SamplingCapture extends ChangeNotifier {
  SamplingCapture({
    this.directory,
    this.limitBytes = 64 * 1024 * 1024,
    this.limitGames = 10,
  });
  static SamplingCapture instance = SamplingCapture();
  static int _sequence = 0;
  static final _process = DateTime.now().microsecondsSinceEpoch.toString();
  static String newId() =>
      '$_process-${(++_sequence).toString().padLeft(8, '0')}';
  final Directory? directory;
  final int limitBytes;
  final int limitGames;
  bool get hasStorage => _path != null;
  bool enabled = false;
  bool failed = false;
  bool _busy = false;
  bool _documentExport = false;
  bool get busy => _busy || _documentExport;
  bool _clearing = false;
  int records = 0;
  int prunedGames = 0;
  int dropped = 0;
  int _epoch = 0;
  int _queued = 0;
  String? _path;
  Future<void>? _initializing;
  Future<void>? _preparing;
  bool _initialized = false;
  Future<void> _writes = Future.value();
  Map<String, Object?> _metadata = const {};
  final Set<CapturedDecision> _inFlight = {};
  String? _currentGame;

  Future<void> initialize() async {
    if (_initialized) return;
    await (_initializing ??= _initialize());
    _initialized = true;
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    enabled = prefs.get(samplingCapturePreference) == true;
    // Off by default does not touch capture storage or query native metadata.
    if (enabled) await _prepare();
  }

  Future<void> _prepare() async {
    if (_path != null) return;
    // Settings may load existing data while the user enables recording.
    // Share preparation so pruning and the initial counters run only once.
    final pending = _preparing ??= _prepareStorage();
    try {
      await pending;
    } finally {
      if (identical(_preparing, pending)) _preparing = null;
    }
  }

  Future<void> _prepareStorage() async {
    try {
      final root =
          directory?.path ??
          '${await maiaEngineChannel.invokeMethod<String>('dataDirectory')}/sampling-data';
      if (directory == null && root.startsWith('null/')) {
        throw const FileSystemException('Sampling storage unavailable');
      }
      final metadata = directory != null
          ? <String, Object?>{'backend': 'test'}
          : Map<String, Object?>.from(
              await maiaEngineChannel.invokeMapMethod<String, Object?>(
                    'samplingMetadata',
                  ) ??
                  {},
            );
      final stats = await _samplingStatsAsync(root, limitGames);
      _path = root;
      _metadata = Map.unmodifiable(metadata);
      records = stats.$1;
      prunedGames = stats.$2;
      dropped = stats.$3;
    } catch (_) {
      failed = true;
    }
  }

  Future<void> loadStoredData() async {
    await initialize();
    await _prepare();
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    await initialize();
    await (await SharedPreferences.getInstance()).setBool(
      samplingCapturePreference,
      value,
    );
    enabled = value;
    if (value) await _prepare();
    notifyListeners();
  }

  CapturedDecision? begin({
    required String gameId,
    required int generation,
    required int ply,
    required String fen,
    required List<String> positions,
    required List<String> prefix,
    required bool history,
    required int elo,
    required Float32List tokens,
    required String backend,
    Map<String, Object?>? game,
  }) {
    if (!enabled || failed || _clearing || _path == null) return null;
    _currentGame = gameId;
    if (_queued >= 16 || _inFlight.length >= 8) {
      dropped++;
      // Persist the accumulated loss marker when the queue next drains.
      return null;
    }
    final ticket = CapturedDecision._(this, _epoch, {
      'schema': 1,
      'algorithm': 'mobile-maia-sampler-v1',
      'requestId': newId(),
      'gameId': gameId,
      'generation': generation,
      'ply': ply,
      'fen': fen,
      'side': fen.split(' ')[1],
      'fullMove': int.parse(fen.split(' ')[5]),
      'startedAt': DateTime.now().toUtc().toIso8601String(),
      'context': _metadata,
      if (game != null) 'game': Map<String, Object?>.from(game),
      'sourceRevision': const String.fromEnvironment('MAIA_SOURCE_REVISION'),
      'inferenceBackend': backend,
      'cache': 'no-play-policy-cache',
      'selfElo': elo,
      'opponentElo': elo,
      'historyEnabled': history,
      'positions': List<String>.of(positions),
      'continuationPrefix': List<String>.of(prefix),
      'historyWindow': MaiaEncoding.historyWindow(
        positions,
        useMoveHistory: history,
      ),
      'tokens': _copySamplingFloats(tokens),
      'outcome': 'pending',
      // The option can be enabled midway, records can be evicted or lost on
      // process death. Never label a capture as a complete game by inference.
      'coverage': 'captured-decisions-only',
    });
    _inFlight.add(ticket);
    _save(ticket, finalRecord: false);
    return ticket;
  }

  void _save(CapturedDecision ticket, {required bool finalRecord}) {
    if (ticket.epoch != _epoch) return;
    final path = _path!;
    final data = Map<String, Object?>.from(ticket.data);
    // A late inference completion must not overwrite a newer game result.
    if (finalRecord) data.remove('game');
    final epoch = _epoch;
    final protected = {
      _currentGame,
      ..._inFlight.map((t) => t.data['gameId']),
    }.whereType<String>().toSet();
    final limit = limitBytes;
    final games = limitGames;
    _queued++;
    _writes = _writes
        .then((_) async {
          if (epoch != _epoch) return;
          final losses = dropped;
          final stats = await _samplingWriteAsync(
            path,
            data,
            protected,
            limit,
            losses,
            games,
          );
          if (epoch == _epoch) {
            records = stats.$1;
            prunedGames = stats.$2;
            dropped = max(dropped, stats.$3);
          }
        })
        .catchError((Object _) {
          failed = true;
        })
        .whenComplete(() {
          _queued--;
          if (finalRecord) _inFlight.remove(ticket);
          notifyListeners();
        });
  }

  /// Small metadata updates share the write queue; never recreate pruned games.
  /// Also updates an existing capture after recording has been switched off.
  void updateGame(String gameId, Map<String, Object?> summary) {
    if (_path == null || _clearing || failed || _queued >= 16) return;
    final root = _path!;
    final epoch = _epoch;
    final data = Map<String, Object?>.from(summary);
    final limit = limitBytes;
    _queued++;
    _writes = _writes
        .then((_) async {
          if (epoch != _epoch) return;
          await _samplingUpdateGameAsync(root, gameId, data, limit);
        })
        .catchError((Object _) {
          failed = true;
        })
        .whenComplete(() {
          _queued--;
          notifyListeners();
        });
  }

  Future<void> flush() async {
    if (_queued > 0 || busy) await _writes;
  }

  Future<void> clear() async {
    if (busy) return;
    _busy = true;
    _clearing = true;
    _epoch++; // In-flight requests cannot recreate explicitly cleared data.
    _inFlight.clear();
    notifyListeners();
    try {
      await _writes;
      await _prepare();
      final path = _path;
      if (path == null) throw StateError('Sampling storage unavailable');
      await Isolate.run(() {
        final root = Directory(path);
        if (root.existsSync()) root.deleteSync(recursive: true);
        root.createSync(recursive: true);
      });
      records = prunedGames = dropped = 0;
      failed = false;
    } catch (_) {
      failed = true;
    } finally {
      _clearing = false;
      _busy = false;
      notifyListeners();
    }
  }

  /// Lease covers snapshot creation, report generation and native handoff.
  /// Gameplay writes can continue after the snapshot cutoff.
  Future<T> _withSnapshot<T>(Future<T> Function(File) action) async {
    if (busy) throw StateError('Sampling export already open');
    _documentExport = true;
    notifyListeners();
    File? file;
    try {
      file = await _export();
      return await action(file);
    } finally {
      try {
        if (file != null) {
          for (final path in [file.path, '${file.parent.path}/report.html']) {
            final temporary = File(path);
            if (await temporary.exists()) await temporary.delete();
          }
        }
      } finally {
        _documentExport = false;
        notifyListeners();
      }
    }
  }

  Future<void> saveDocument({
    bool share = false,
    bool readable = false,
    Map<String, String>? text,
    String locale = 'en',
    Map<String, String> pieceImages = const {},
  }) => _withSnapshot((file) async {
    if (readable) {
      final path = file.path;
      final labels = text!;
      await Isolate.run(() async {
        final report = await SamplingReport.read(File(path));
        await writeSamplingReportHtml(
          report,
          File('${File(path).parent.path}/report.html'),
          labels,
          locale,
          pieceImages,
        );
      });
    }
    await maiaEngineChannel.invokeMethod<bool>('saveSamplingData', {
      'share': share,
      'readable': readable,
      'shareTitle': text?['title'] ?? '',
    });
  });

  Future<File> export() {
    if (_documentExport) throw StateError('Sampling document picker is open');
    return _export();
  }

  Future<File> _export() async {
    await initialize();
    await _prepare();
    if (_path == null || _busy) throw StateError('Sampling export unavailable');
    _busy = true;
    notifyListeners();
    try {
      await _writes;
      final root = _path!;
      final losses = dropped;
      final storageFailed = failed;
      // Serialize with subsequent capture writes/clear to get a coherent cutoff.
      final completer = Completer<File>();
      _writes = _writes.then((_) async {
        try {
          final path = await _samplingExportAsync(root, losses, storageFailed);
          completer.complete(File(path));
        } catch (e, st) {
          completer.completeError(e, st);
        }
      });
      return await completer.future;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}

class CapturedDecision {
  CapturedDecision._(this.owner, this.epoch, this.data);
  final SamplingCapture owner;
  final int epoch;
  final Map<String, Object?> data;
  bool _finished = false;
  void output(Float32List? logits) {
    if (logits != null) data['logits'] = _copySamplingFloats(logits);
  }

  void sampling(Map<String, Object?> trace) => data['sampling'] = trace;
  void finish(
    String outcome, {
    String? committedFen,
    String? move,
    String? error,
  }) {
    if (_finished) return;
    _finished = true;
    data.addAll({
      'outcome': outcome,
      'finishedAt': DateTime.now().toUtc().toIso8601String(),
      'committedFen': ?committedFen,
      'committedMove': ?move,
      'error': ?error,
    });
    owner._save(this, finalRecord: true);
  }
}

Map<String, Object?> _samplingMeta(String root) {
  final f = File('$root/retention.json');
  if (!f.existsSync()) return {'prunedGames': 0, 'dropped': 0};
  return Map<String, Object?>.from(jsonDecode(f.readAsStringSync()) as Map);
}

void _samplingAtomic(File file, String content) {
  file.parent.createSync(recursive: true);
  final temporary = File('${file.path}.tmp');
  temporary.writeAsStringSync(content, flush: true);
  temporary.renameSync(file.path);
}

List<Directory> _samplingGames(String root) {
  final d = Directory('$root/games');
  if (!d.existsSync()) return [];
  return d.listSync(followLinks: false).whereType<Directory>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

List<File> _samplingFiles(Directory directory) =>
    directory
        .listSync(followLinks: false)
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
(int, int, int) _samplingStats(String root) {
  final meta = _samplingMeta(root);
  return (
    _samplingGames(root).fold(0, (n, d) => n + _samplingFiles(d).length),
    meta['prunedGames'] as int,
    meta['dropped'] as int,
  );
}

int _samplingGameBytes(Directory game) => game
    .listSync(followLinks: false)
    .whereType<File>()
    .fold(0, (n, f) => n + f.lengthSync());

void _updateSamplingGame(
  String root,
  String id,
  Map<String, Object?> data,
  int limit,
) {
  if (!RegExp(r'^\d+-\d+$').hasMatch(id)) {
    throw const FormatException('Invalid capture identifier');
  }
  final directory = Directory('$root/games/$id');
  if (!directory.existsSync()) return;
  final file = File('${directory.path}/summary.meta');
  // Dates identify the original game, never the last visit or export.
  if (file.existsSync()) {
    final previous = jsonDecode(file.readAsStringSync()) as Map;
    if (previous['startedAt'] != null) {
      data['startedAt'] = previous['startedAt'];
    }
  }
  final encoded = jsonEncode(data);
  final bytes = utf8.encode(encoded).length;
  if (bytes > 8192) throw const FormatException('Game summary too large');
  final total = _samplingGames(root)
      .fold<int>(0, (n, d) => n + _samplingGameBytes(d));
  if (total - (file.existsSync() ? file.lengthSync() : 0) + bytes > limit) {
    // Never keep a stale result if the new summary cannot fit.
    if (file.existsSync()) file.deleteSync();
    return;
  }
  _samplingAtomic(file, encoded);
}

Float32List _copySamplingFloats(Float32List values) => Float32List.view(
  Uint8List.fromList(
    values.buffer.asUint8List(values.offsetInBytes, values.lengthInBytes),
  ).buffer,
);

Map<String, Object> _samplingFloats(Float32List values) {
  final raw = Uint8List.fromList(
    values.buffer.asUint8List(values.offsetInBytes, values.lengthInBytes),
  );
  if (Endian.host != Endian.little) {
    for (var i = 0; i < raw.length; i += 4) {
      final a = raw[i];
      final b = raw[i + 1];
      raw[i] = raw[i + 3];
      raw[i + 1] = raw[i + 2];
      raw[i + 2] = b;
      raw[i + 3] = a;
    }
  }
  return {
    'encoding': 'float32-le-base64',
    'length': values.length,
    'sha256': crypto.sha256.convert(raw).toString(),
    'data': base64Encode(raw),
  };
}

(int, int, int) _writeSamplingRecord(
  String root,
  Map<String, Object?> data,
  Set<String> protected,
  int limit,
  int losses,
  int maxGames,
) {
  final meta = _samplingMeta(root);
  meta['dropped'] = max(meta['dropped'] as int, losses);
  final game = data['gameId'] as String;
  final id = data['requestId'] as String;
  // Identifiers are generated locally, but restored game IDs are untrusted.
  if (!RegExp(r'^\d+-\d+$').hasMatch(game) ||
      !RegExp(r'^\d+-\d+$').hasMatch(id)) {
    throw const FormatException('Invalid capture identifier');
  }
  // Raw legal policy is derived from the exact output snapshot off the UI
  // isolate. The sampler's actual weighted order/draw is retained separately.
  if (data['sampling'] case final Map<String, Object?> trace) {
    if (data['logits'] case final Float32List logits) {
      final legal = (trace['legalOrder'] as List).cast<Map<String, Object?>>();
      final scores = legal.map((m) => logits[m['index'] as int]).toList();
      final peak = scores.reduce(max);
      final weights = scores.map((s) => exp(s - peak)).toList();
      final total = weights.reduce((a, b) => a + b);
      data['rawLegalPolicy'] = [
        for (var i = 0; i < legal.length; i++)
          {'uci': legal[i]['uci'], 'probability': weights[i] / total},
      ];
    }
  }
  for (final name in ['tokens', 'logits']) {
    if (data[name] case final Float32List values) {
      data[name] = _samplingFloats(values);
    }
  }
  data['fenSha256'] = crypto.sha256
      .convert(utf8.encode(data['fen'] as String))
      .toString();
  if (data['committedFen'] case final String fen) {
    data['committedFenSha256'] = crypto.sha256
        .convert(utf8.encode(fen))
        .toString();
  }
  final summary = data.remove('game') as Map<String, Object?>?;
  final payload = jsonEncode(data);
  final envelope = jsonEncode({
    'sha256': crypto.sha256.convert(utf8.encode(payload)).toString(),
    'record': payload,
  });
  final bytes = utf8.encode(envelope).length;
  final destination = File('$root/games/$game/$id.json');
  final games = _samplingGames(root);
  var size = games.fold<int>(0, (n, d) => n + _samplingGameBytes(d));
  var count = games.length + (destination.parent.existsSync() ? 0 : 1);
  final cutoff = meta['evictedThrough'] as String?;
  if (!destination.parent.existsSync() &&
      cutoff != null &&
      game.compareTo(cutoff) <= 0) {
    // Resuming an evicted old game must not push out newer games or return a
    // misleading tail-only capture. Clear resets this bounded watermark.
    return _samplingStats(root);
  }
  final replacedBytes = destination.existsSync() ? destination.lengthSync() : 0;
  for (final old
      in bytes > 512 * 1024 || bytes > limit ? <Directory>[] : games) {
    if (size - replacedBytes + bytes <= limit && count <= maxGames) break;
    final oldId = old.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (protected.contains(oldId) || oldId == game) continue;
    if (count > maxGames &&
        oldId.compareTo(game) > 0 &&
        !destination.parent.existsSync()) {
      return _samplingStats(root);
    }
    size -= _samplingGameBytes(old);
    count--;
    final previous = meta['evictedThrough'] as String?;
    if (previous == null || oldId.compareTo(previous) > 0) {
      meta['evictedThrough'] = oldId;
    }
    old.deleteSync(recursive: true);
    meta['prunedGames'] = (meta['prunedGames'] as int) + 1;
  }
  if (bytes > 512 * 1024 ||
      size - replacedBytes + bytes > limit ||
      count > maxGames) {
    // A single exceptionally long game may fill the store; keep prior records
    // and mark incomplete capture rather than exceed the cap or lose this game.
    meta['dropped'] = (meta['dropped'] as int) + 1;
  } else {
    _samplingAtomic(destination, envelope);
    if (summary != null) _updateSamplingGame(root, game, summary, limit);
  }
  _samplingAtomic(File('$root/retention.json'), jsonEncode(meta));
  return _samplingStats(root);
}

String _exportSampling(String root, int losses, bool storageFailed) {
  final meta = _samplingMeta(root);
  final file = File('$root/export.jsonl');
  file.parent.createSync(recursive: true);
  final out = file.openSync(mode: FileMode.write);
  final digestOutput = <crypto.Digest>[];
  final digestSink = crypto.sha256.startChunkedConversion(
    _SamplingDigestSink(digestOutput),
  );
  var count = 0;
  var complete = false;
  try {
    final games = _samplingGames(root).reversed.toList(growable: false);
    final summaries = <String, Object?>{};
    for (final game in games) {
      final summary = File('${game.path}/summary.meta');
      if (summary.existsSync() && summary.lengthSync() <= 8192) {
        summaries[game.uri.pathSegments.where((s) => s.isNotEmpty).last] =
            jsonDecode(summary.readAsStringSync());
      }
    }
    final manifest =
        '${jsonEncode({'type': 'manifest', 'schema': 1, 'algorithm': 'mobile-maia-sampler-v1', 'coverage': 'captured-decisions-only', 'prunedGames': meta['prunedGames'], 'storageErrorObserved': storageFailed, 'droppedRecords': max(meta['dropped'] as int, losses), 'pendingMeans': 'no terminal outcome durably observed; possibly interrupted', 'createdAt': DateTime.now().toUtc().toIso8601String(), 'games': summaries, 'gameOrder': 'newest-first'})}\n';
    out.writeStringSync(manifest);
    digestSink.add(utf8.encode(manifest));
    for (final game in games) {
      for (final record in _samplingFiles(game)) {
        final bytes = record.readAsBytesSync();
        final envelope = jsonDecode(utf8.decode(bytes)) as Map;
        if (crypto.sha256
                .convert(utf8.encode(envelope['record'] as String))
                .toString() !=
            envelope['sha256']) {
          throw const FormatException('Corrupt sampling record');
        }
        out.writeFromSync(bytes);
        out.writeByteSync(10);
        digestSink.add(bytes);
        digestSink.add([10]);
        count++;
      }
    }
    digestSink.close();
    out.writeStringSync(
      '${jsonEncode({'type': 'footer', 'records': count, 'contentSha256': digestOutput.single.toString()})}\n',
    );
    out.flushSync();
    complete = true;
  } finally {
    out.closeSync();
    if (!complete && file.existsSync()) file.deleteSync();
  }
  return file.path;
}

class _SamplingDigestSink implements Sink<crypto.Digest> {
  _SamplingDigestSink(this.values);
  final List<crypto.Digest> values;
  @override
  void add(crypto.Digest value) => values.add(value);
  @override
  void close() {}
}

// Top-level boundaries prevent Dart closures from capturing the controller's
// unsendable Future/Completer state when spawning the worker isolate.
Future<(int, int, int)> _samplingStatsAsync(String root, int maxGames) =>
    Isolate.run(() {
      final games = _samplingGames(root);
      if (games.length > maxGames) {
        final meta = _samplingMeta(root);
        for (final old in games.take(games.length - maxGames)) {
          final id = old.uri.pathSegments.where((s) => s.isNotEmpty).last;
          final previous = meta['evictedThrough'] as String?;
          if (previous == null || id.compareTo(previous) > 0) {
            meta['evictedThrough'] = id;
          }
          old.deleteSync(recursive: true);
          meta['prunedGames'] = (meta['prunedGames'] as int) + 1;
        }
        _samplingAtomic(File('$root/retention.json'), jsonEncode(meta));
      }
      return _samplingStats(root);
    });
Future<(int, int, int)> _samplingWriteAsync(
  String root,
  Map<String, Object?> data,
  Set<String> protected,
  int limit,
  int losses,
  int maxGames,
) => Isolate.run(
  () => _writeSamplingRecord(root, data, protected, limit, losses, maxGames),
);
Future<String> _samplingExportAsync(
  String root,
  int losses,
  bool storageFailed,
) => Isolate.run(() => _exportSampling(root, losses, storageFailed));

Future<void> _samplingUpdateGameAsync(
  String root,
  String gameId,
  Map<String, Object?> data,
  int limit,
) => Isolate.run(() => _updateSamplingGame(root, gameId, data, limit));

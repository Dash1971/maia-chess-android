part of '../main.dart';

class RecentSession {
  RecentSession(this.id, this.updatedAt, this.data, {GameHistory? history})
    : history = history ?? GameHistory.fromLegacy(data);
  final GameHistory history;
  final String id;
  final DateTime updatedAt;
  final Map<String, dynamic> data;
  bool get isIncomplete => resultLabel == 'Incomplete';

  /// Read only the header block, never Result-like text in comments/variations.
  /// Null means ambiguous/malformed; '*' means no completed result is known.
  String? get _pgnResult {
    final session = data['session'];
    final source = data['pgn'] ?? (session is Map ? session['pgn'] : null);
    if (source == null) return '*';
    if (source is! String) return null;
    final headers = source.substring(0, min(source.length, 8192));
    final tag = RegExp(r'\s*\[([A-Za-z0-9_]+)\s+"((?:[^"\\]|\\.)*)"\s*\]');
    var offset = headers.startsWith('\uFEFF') ? 1 : 0;
    String? result;
    while (true) {
      final match = tag.matchAsPrefix(headers, offset);
      if (match == null) break;
      offset = match.end;
      if (match[1] == 'Result') {
        if (result != null) {
          return null; // Duplicate tags are not authoritative.
        }
        result = match[2];
      }
    }
    final remainder = headers.substring(offset).trimLeft();
    if (remainder.startsWith('[') ||
        (remainder.isEmpty && source.length > headers.length)) {
      return null; // Malformed or truncated header block.
    }
    return result == null || result == '*' || _isFinalResult(result)
        ? result ?? '*'
        : null;
  }

  String get title {
    if (data['importedPgn'] == true) {
      return '${data['importedWhite'] ?? 'White'} — ${data['importedBlack'] ?? 'Black'}';
    }
    final maia = 'Maia ${data['elo'] ?? 1600}';
    final playerIsWhite = data['playerIsWhite'];
    return playerIsWhite is! bool || playerIsWhite
        ? 'Player — $maia'
        : '$maia — Player';
  }

  String localizedTitle(BuildContext context) {
    final strings = l10n(context);
    if (data['importedPgn'] == true) {
      return '${data['importedWhite'] ?? strings.white} — ${data['importedBlack'] ?? strings.black}';
    }
    final rating = data['elo'];
    final displayRating = NumberFormat(
      '0',
      strings.localeName,
    ).format(rating is num ? rating : 1600);
    return data['playerIsWhite'] is! bool || data['playerIsWhite'] == true
        ? strings.recentPlayerMaia(displayRating)
        : strings.recentMaiaPlayer(displayRating);
  }

  String localizedResult(BuildContext context) {
    final result = resultLabel;
    return result == 'Incomplete'
        ? l10n(context).recentIncomplete
        : result == 'Completed'
        ? l10n(context).recentCompleted
        : result;
  }

  String get resultLabel {
    if (data['recentState'] == 'incomplete') return 'Incomplete';
    final forcedResult = data['forcedResult'];
    // Resignation/timeouts can override an unfinished PGN. Invalid forced data
    // must not silently fall back to a different historical result.
    if (forcedResult != null) {
      return forcedResult is String && _isFinalResult(forcedResult)
          ? forcedResult
          : 'Completed';
    }
    final result = _pgnResult;
    if (result != null && _isFinalResult(result)) return result;
    return data['recentState'] == null && result == '*'
        ? 'Incomplete'
        : 'Completed';
  }

  RecentGameOutcome get outcome => switch (resultLabel) {
    'Incomplete' => RecentGameOutcome.incomplete,
    '1/2-1/2' => RecentGameOutcome.draw,
    '1-0' => switch (data['playerIsWhite']) {
      true => RecentGameOutcome.win,
      false => RecentGameOutcome.loss,
      _ => RecentGameOutcome.unknown,
    },
    '0-1' => switch (data['playerIsWhite']) {
      false => RecentGameOutcome.win,
      true => RecentGameOutcome.loss,
      _ => RecentGameOutcome.unknown,
    },
    _ => RecentGameOutcome.unknown,
  };

  static bool _isFinalResult(String result) =>
      result == '1-0' || result == '0-1' || result == '1/2-1/2';
}

/// Presentation only: no mutation of saved games or persisted statistics.
enum RecentGameOutcome {
  win,
  loss,
  draw,
  incomplete,
  unknown;

  Color? colorFor(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return switch (this) {
      win => Color(dark ? 0xff81c784 : 0xff286332),
      loss => Color(dark ? 0xffe99b98 : 0xffa13232),
      draw => Color(dark ? 0xffd6bd69 : 0xff705900),
      incomplete => Color(dark ? 0xff8cbbd9 : 0xff326480),
      unknown => null,
    };
  }
}

/// Insert a styled result through the localization placeholder, so translated
/// date/result order and punctuation remain owned by the existing message.
Widget _recentResultSubtitle(
  BuildContext context,
  RecentSession game,
  String date,
) {
  final strings = l10n(context);
  final result = game.localizedResult(context);
  final outcome = game.outcome;
  final description = switch (outcome) {
    RecentGameOutcome.win => strings.recentWinResult(result),
    RecentGameOutcome.loss => strings.recentLossResult(result),
    RecentGameOutcome.draw => strings.recentDrawResult(result),
    _ => result,
  };
  const marker = '\uFFFC';
  final parts = strings.recentGameSummary(marker, date).split(marker);
  return Text.rich(
    TextSpan(
      children: [
        for (var index = 0; index < parts.length; index++) ...[
          if (index > 0)
            TextSpan(
              text: result,
              style: TextStyle(color: _recentResultColor(context, game)),
            ),
          TextSpan(text: parts[index]),
        ],
      ],
    ),
    semanticsLabel: strings.recentGameSummary(description, date),
  );
}

Color? _recentResultColor(BuildContext context, RecentSession game) =>
    game.isIncomplete
    ? Theme.of(context).colorScheme.onSurfaceVariant
    : game.outcome.colorFor(Theme.of(context).brightness);

String _recentGameDate(BuildContext context, DateTime? date) => date == null
    ? l10n(context).dateUnknown
    : '${date.year.toString().padLeft(4, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.day.toString().padLeft(2, '0')}';

/// App-private, transactional files. Each successful write retains the previous
/// readable checkpoint. Archived games are separate files, not rewritten per move.
class SessionRepository {
  SessionRepository(this.directory) : _inWorker = false;
  SessionRepository._worker(this.directory) : _inWorker = true;
  final bool _inWorker;
  bool _cleanedImports = false;
  static final _activeImports = <String>{};
  final Directory directory;
  Future<void> _tail = Future.value();
  String? _activeId;
  Map<String, dynamic>? _activeEnvelope;
  bool _activeLoaded = false;

  void _rememberActive(Map<String, dynamic>? envelope) {
    // Freeze legacy history from the original payload before exposing any data
    // to a screen or replacing it with an edited autosave snapshot.
    _activeEnvelope =
        envelope != null && GameHistory.gameData(envelope['data']) != null
        ? _withHistory(envelope)
        : envelope;
    _activeLoaded = true;
    _activeId =
        envelope != null &&
            (envelope['data'] != null || envelope.containsKey('gameHistory'))
        ? envelope['id'] as String
        : null;
  }

  Future<Map<String, dynamic>?> _current() async {
    if (!_activeLoaded) _rememberActive(await _read(_active));
    return _activeEnvelope;
  }

  Map<String, dynamic> _withHistory(Map<String, dynamic> envelope) {
    if (GameHistory.gameData(envelope['data']) == null) {
      return {...envelope}..remove('gameHistory');
    }
    // Presence, including an explicitly unknown date, is authoritative.
    if (envelope.containsKey('gameHistory')) return envelope;
    return {
      ...envelope,
      'gameHistory': GameHistory.fromLegacy(envelope['data']).toJson(),
    };
  }

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        if (!_cleanedImports) {
          await _cleanupAbandonedImports();
          _cleanedImports = true;
        }
        result.complete(await action());
      } catch (error, stack) {
        result.completeError(error, stack);
      }
    });
    return result.future;
  }

  Future<Map<String, dynamic>?> _readFile(File file) async {
    try {
      // A pending write can end halfway through a UTF-8 character. Decode
      // its bytes explicitly so it follows the malformed-JSON recovery path.
      final source = file.path.endsWith('.pending')
          ? utf8.decode(await file.readAsBytes())
          : await file.readAsString();
      final decoded = _inWorker
          ? jsonDecode(source)
          : await Isolate.run(() => jsonDecode(source));
      if (decoded is Map &&
          decoded.containsKey('version') &&
          decoded['version'] != 1) {
        throw UnsupportedSessionFormatException('envelope', decoded['version']);
      }
      if (decoded is! Map ||
          decoded['version'] != 1 ||
          decoded['id'] is! String ||
          !RegExp(r'^[0-9a-z-]+$').hasMatch(decoded['id'] as String) ||
          (decoded['updatedAt'] != null && decoded['updatedAt'] is! String) ||
          (decoded['data'] != null && decoded['data'] is! Map)) {
        return null;
      }
      if (decoded.containsKey('gameHistory')) {
        GameHistory.fromJson(decoded['gameHistory']);
      }
      final data = decoded['data'];
      validateSessionSchema(data);
      if (data is Map && data['pgn'] != null && data['pgn'] is! String) {
        return null;
      }
      return Map<String, dynamic>.from(decoded);
    } on FileSystemException catch (error) {
      if (error.osError?.errorCode == 2) return null; // Not found.
      // A directory cannot contain a newer-format checkpoint. It may obstruct
      // a pending write, but must not hide the last readable saved game.
      if (error.osError?.errorCode == 21) return null; // Is a directory.
      rethrow; // An unreadable save must not be treated as disposable/missing.
    } on FormatException {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _read(File file) async {
    final primary = await _readFile(file);
    final previous = await _readFile(File('${file.path}.previous'));
    await _readFile(File('${file.path}.pending'));
    return primary ?? previous;
  }

  Future<void> _write(File file, Map<String, Object?> envelope) async {
    // Preflight all generations before creating a pending file or rotating
    // backups. An older app must never overwrite a newer saved format.
    final primary = await _readFile(file);
    await _readFile(File('${file.path}.previous'));
    await _readFile(File('${file.path}.pending'));
    await file.parent.create(recursive: true);
    final payload = envelope;
    final encoded = _inWorker
        ? jsonEncode(payload)
        : await Isolate.run(() => jsonEncode(payload));
    final temporary = File('${file.path}.pending');
    await temporary.writeAsString(encoded, flush: true);
    if (primary != null) {
      await file.rename('${file.path}.previous');
    }
    await temporary.rename(file.path);
    if (file.path == _active.path) _rememberActive(envelope);
  }

  File get _active => File('${directory.path}/active.json');
  static final _importId = RegExp(r'^(import-[0-9]+-[0-9]+)-[0-9]+$');
  File _archiveFile(String id) {
    if (!RegExp(r'^[0-9a-z-]+$').hasMatch(id)) {
      throw const FormatException('Invalid session identifier');
    }
    final batch = _importId.firstMatch(id)?.group(1);
    return File(
      '${directory.path}/games/${batch == null ? '' : '$batch/'}$id.json',
    );
  }

  /// Only abandoned import directories are disposable, never save checkpoints.
  /// Repositories in the coordinating isolate share the active set, so another
  /// instance there cannot clean a collection being prepared by the worker.
  Future<void> _cleanupAbandonedImports() async {
    if (!await directory.exists()) return;
    await for (final entry in directory.list(followLinks: false)) {
      if (entry is Directory &&
          RegExp(r'^\.import-[0-9]+-[0-9]+\.pending$')
              .hasMatch(entry.path.split('/').last) &&
          !_activeImports.contains(entry.path)) {
        await entry.delete(recursive: true);
      }
    }
  }

  static String? _storedPgn(Map<String, dynamic>? envelope) {
    final data = envelope == null
        ? null
        : _recentGameData(envelope['data'], includeLive: true);
    final session = data?['session'];
    final pgn = data?['pgn'] ?? (session is Map ? session['pgn'] : null);
    return pgn is String ? pgn : null;
  }

  static final _identityTag = RegExp(
    r'\[([A-Za-z0-9][A-Za-z0-9_+#=:-]*)\s+"((?:[^"\\]|\\["\\])*)"\]',
  );

  /// Use the exporter's formatting, without replaying every saved game. Raw
  /// fallback protects metadata or annotations the serializer would discard.
  static String _pgnFingerprint(String pgn) {
    final text = pgn.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    var identity = 'raw:$text';
    try {
      if (text.length <= AnalysisSession.maxPgnBytes) {
        RecentGamesPgn._validateSingleGame(text);
        AnalysisSession._validatePgnTokens(text);
        final parsed = dc.PgnGame.parsePgn(
          text,
          initHeaders: dc.PgnGame.emptyHeaders,
        );
        final declared = <String, String>{};
        var brace = false, lossless = true;
        for (var i = 0; i < text.length; i++) {
          final c = text[i];
          if (brace) {
            if (c == '}') brace = false;
          } else if (c == '{') {
            brace = true;
          } else if (c == '[') {
            final tag = _identityTag.matchAsPrefix(text, i);
            if (tag == null || declared.containsKey(tag[1])) {
              lossless = false;
              break;
            }
            final key = tag[1]!;
            final value = tag[2]!
                .replaceAll(r'\"', '"')
                .replaceAll(r'\\', r'\');
            declared[key] = value;
            if (parsed.headers[key] != value) {
              lossless = false;
              break;
            }
            i = tag.end - 1;
          } else if (c == ';' || c == '%') {
            // The serializer omits line comments and escape lines entirely.
            lossless = false;
            break;
          }
        }
        if (lossless) identity = 'pgn:${parsed.makePgn().trim()}';
      }
    } on FormatException {
      // Malformed legacy records must not become a valid-looking duplicate.
    } on ArgumentError {
      // Includes malformed legacy setup headers rejected by makePgn().
    }
    return crypto.sha256.convert(utf8.encode(identity)).toString();
  }

  /// Publish all new games with one directory rename. Validation, duplicate
  /// checks and file writes run off the UI isolate, under this repository queue.
  Future<PgnImportResult> importCollection(
    PgnCollection collection, {
    void Function(PgnImportProgress)? onProgress,
  }) => _serial(() async {
    final now = DateTime.now().toUtc();
    final batch =
        'import-${now.microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 30)}';
    final root = directory.path;
    final staging = '$root/.$batch.pending';
    final port = ReceivePort();
    final updates = port.listen((message) {
      if (message is List<int>) {
        onProgress?.call(PgnImportProgress(message[0], message[1]));
      }
    });
    final sender = port.sendPort;
    _activeImports.add(staging);
    try {
      final result = await _runImportWorker(
        root,
        collection,
        batch,
        now,
        sender,
      );
      onProgress?.call(const PgnImportProgress(1, 1));
      return result;
    } finally {
      port.close();
      await updates.cancel();
      _activeImports.remove(staging);
    }
  });

  static Future<PgnImportResult> _runImportWorker(
    String root,
    PgnCollection collection,
    String batch,
    DateTime now,
    SendPort sender,
  ) => Isolate.run(
    () =>
        SessionRepository._worker(Directory(root))
            ._importCollection(collection, batch, now, sender),
  );

  Future<PgnImportResult> _importCollection(
    PgnCollection collection,
    String batch,
    DateTime now,
    SendPort progress,
  ) async {
    final staging = Directory('${directory.path}/.$batch.pending');
    final destination = Directory('${directory.path}/games/$batch');
    final existing = [...await _archiveNames(), _active.path];
    final total = existing.length + 2 * collection.games.length;
    var completed = 0;
    final timer = Stopwatch()..start();
    void report({bool force = false}) {
      if (force || timer.elapsedMilliseconds >= 40) {
        progress.send(<int>[completed, total]);
        timer.reset();
      }
    }

    report(force: true);
    final seen = <String>{};
    for (final file in existing) {
      final pgn = _storedPgn(await _read(File(file)));
      if (pgn != null) seen.add(_pgnFingerprint(pgn));
      completed++;
      report();
    }
    final selected = <int>[];
    for (var i = 0; i < collection.games.length; i++) {
      if (seen.add(_pgnFingerprint(collection.games[i]))) selected.add(i);
      completed++;
      report();
    }
    final duplicates = collection.games.length - selected.length;
    completed += duplicates;
    if (selected.isEmpty) {
      progress.send(<int>[total, total]);
      return PgnImportResult(0, duplicates);
    }
    try {
      await staging.create(recursive: true);
      for (final i in selected) {
        final pgn = collection.games[i];
        final headers = collection.headers[i];
        final result = headers['Result'] ?? '*';
        final maiaName = RegExp(r'^Maia-3 79M \(([0-9]{3,4})\)$');
        final whiteMaia = maiaName.firstMatch(headers['White'] ?? '');
        final blackMaia = maiaName.firstMatch(headers['Black'] ?? '');
        final maia = whiteMaia ?? blackMaia;
        final maiaRating = maia == null
            ? null
            : _decodeMaiaRating(int.tryParse(maia[1]!));
        final data = <String, Object?>{
          'schema': 1,
          'type': 'game',
          'pgn': pgn,
          'recentState': result == '*' ? 'incomplete' : 'completed',
          'clockPaused': true,
          'importedPgn': true,
          'importedWhite': ?headers['White'],
          'importedBlack': ?headers['Black'],
          if (maiaRating != null &&
              (whiteMaia == null || blackMaia == null)) ...{
            'playerIsWhite': blackMaia != null,
            'elo': maiaRating,
          },
        };
        final id =
            '$batch-${(collection.games.length - i).toString().padLeft(8, '0')}';
        await _write(
          File('${staging.path}/$id.json'),
          _withHistory({
            'version': 1,
            'id': id,
            'updatedAt': now.toIso8601String(),
            'data': data,
          }),
        );
        completed++;
        report();
      }
      await destination.parent.create(recursive: true);
      await staging.rename(destination.path);
      progress.send(<int>[total, total]);
      return PgnImportResult(selected.length, duplicates);
    } finally {
      if (await staging.exists()) await staging.delete(recursive: true);
    }
  }

  Future<bool> hasCheckpoint() =>
      _serial(() async => await _read(_active) != null);

  Future<Map<String, dynamic>?> load() => _serial(() async {
    final envelope = await _read(_active);
    _rememberActive(envelope);
    return envelope?['data'] == null
        ? null
        : Map<String, dynamic>.from(_detach(envelope!['data']) as Map);
  });

  static Object? _detach(Object? value) => switch (value) {
    Map() => value.map((key, item) => MapEntry(key, _detach(item))),
    List() => value.map(_detach).toList(),
    _ => value,
  };

  Future<void> save(Map<String, Object?> data) {
    final snapshot = Map<String, Object?>.from(_detach(data) as Map);
    return _serial(() async {
      final previous = await _current();
      final now = DateTime.now();
      final id =
          _activeId ??
          '${now.microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 30)}';
      await _write(
        _active,
        _withHistory({
          if (previous?['id'] == id) ...previous!,
          'version': 1,
          'id': id,
          'updatedAt': now.toUtc().toIso8601String(),
          'data': snapshot,
        }),
      );
    });
  }

  static Map<String, dynamic>? _recentGameData(
    Object? value, {
    bool includeLive = true,
  }) {
    if (value is! Map) return null;
    final data = Map<String, dynamic>.from(value);
    if (data['type'] == 'review') {
      return _recentGameData(data['activeGame'], includeLive: includeLive);
    }
    if (data['type'] != 'game') return null;
    final state = data['recentState'];
    // Freeze the last saved clock when a live game becomes a manual recovery.
    if (state == 'active') {
      if (!includeLive) return null;
      return {...data, 'recentState': 'incomplete', 'clockPaused': true};
    }
    // Older saves have no recentState and derive their label from the PGN.
    if (state == null || state == 'incomplete' || state == 'completed') {
      return data;
    }
    return null;
  }

  Future<void> _archive() async {
    final envelope = await _current();
    final data = _recentGameData(envelope?['data']);
    if (envelope != null && data != null) {
      await _write(
        _archiveFile(envelope['id'] as String),
        _withHistory({...envelope, 'data': data}),
      );
    }
  }

  Future<void> startNew({DateTime? gameStartedAt}) => _serial(() async {
    await _read(_active); // Preflight before archiving another generation.
    await _archive();
    await _write(_active, {
      'version': 1,
      'id': gameStartedAt == null
          ? _activeId ?? 'none'
          : '${gameStartedAt.microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 30)}',
      'data': null,
      if (gameStartedAt != null)
        'gameHistory': GameHistory.started(gameStartedAt).toJson(),
    });
    final previous = File('${_active.path}.previous');
    if (await previous.exists()) await previous.delete();
    if (gameStartedAt == null) _activeId = null;
  });

  Future<void> discardActive() => _serial(() async {
    final envelope = await _read(_active);
    final id = envelope?['id'] as String? ?? _activeId ?? 'none';
    await _read(_archiveFile(id));
    // Write the tombstone first so a process death can never restore the
    // discarded game as active. Remove every archived recovery generation as
    // well, because Reset means erase rather than add to Recent games.
    await _write(_active, {'version': 1, 'id': id, 'data': null});
    final previous = File('${_active.path}.previous');
    if (await previous.exists()) await previous.delete();
    _activeId = null;
    await _deleteArchiveFiles(id);
  });

  Future<Set<String>> _archiveNames() async {
    final names = <String>{};
    final archive = Directory('${directory.path}/games');
    if (await archive.exists()) {
      await for (final entity in archive.list()) {
        if (entity is Directory &&
            RegExp(r'^import-[0-9]+-[0-9]+$')
                .hasMatch(entity.path.split('/').last)) {
          await for (final file in entity.list(followLinks: false)) {
            if (file is File &&
                (file.path.endsWith('.json') ||
                    file.path.endsWith('.json.previous'))) {
              names.add(file.path.replaceFirst(RegExp(r'\.previous$'), ''));
            }
          }
        }
        if (entity is File &&
            (entity.path.endsWith('.json') ||
                entity.path.endsWith('.json.previous'))) {
          names.add(entity.path.replaceFirst(RegExp(r'\.previous$'), ''));
        }
      }
    }
    return names;
  }

  Future<List<RecentSession>> recent({bool restoreBlocked = false}) =>
      _serial(() => _runRecentWorker(directory.path, restoreBlocked));

  static Future<List<RecentSession>> _runRecentWorker(
    String root,
    bool restoreBlocked,
  ) => Isolate.run(
    () =>
        SessionRepository._worker(Directory(root))
            ._recent(restoreBlocked: restoreBlocked),
  );

  Future<List<RecentSession>> _recent({required bool restoreBlocked}) async {
    final entries = <String, RecentSession>{};
    void add(Map<String, dynamic>? envelope, {bool includeLive = false}) {
      if (envelope == null) return;
      final data = _recentGameData(envelope['data'], includeLive: includeLive);
      if (data == null) return;
      final id = envelope['id'] as String;
      entries[id] = RecentSession(
        id,
        DateTime.tryParse(envelope['updatedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        data,
        history: envelope.containsKey('gameHistory')
            ? GameHistory.fromJson(envelope['gameHistory'])
            : GameHistory.fromLegacy(data),
      );
    }

    for (final name in await _archiveNames()) {
      add(await _read(File(name)));
    }
    add(await _read(_active), includeLive: restoreBlocked);
    return entries.values.toList()..sort((a, b) {
      final day = (b.history.playedOn ?? '').compareTo(
        a.history.playedOn ?? '',
      );
      if (day != 0) return day;
      final aStart = a.history.startedAt;
      final bStart = b.history.startedAt;
      if (aStart != null && bStart == null) return -1;
      if (aStart == null && bStart != null) return 1;
      final time = aStart == null ? 0 : bStart!.compareTo(aStart);
      return time != 0 ? time : b.id.compareTo(a.id);
    });
  }

  Future<Map<String, dynamic>?> open(String id) => _serial(() async {
    final archive = _archiveFile(id); // Validate the id before any writes.
    final active = await _read(_active);
    final archived = await _read(archive);
    final entry =
        active?['id'] == id && _recentGameData(active?['data']) != null
        ? active
        : archived;
    if (entry == null) return null;
    final data = _recentGameData(entry['data']);
    if (data == null) return null;
    _rememberActive(active);
    await _archive();
    await _write(_active, _withHistory({...entry, 'data': data}));
    return Map<String, dynamic>.from(_detach(data) as Map);
  });

  /// Export must never call open(), which archives/replaces the active session.
  Future<String?> readPgnForExport(String id) => _serial(() async {
    final archive = _archiveFile(id);
    final active = await _read(_active);
    final entry =
        active?['id'] == id && _recentGameData(active?['data']) != null
        ? active
        : await _read(archive);
    if (entry == null || entry['id'] != id) return null;
    final data = _recentGameData(entry['data']);
    final session = data?['session'];
    final pgn = data?['pgn'] ?? (session is Map ? session['pgn'] : null);
    return pgn is String ? pgn : null;
  });

  Future<void> delete(String id) => _serial(() async {
    await _read(_archiveFile(id));
    // Tombstone the active checkpoint before touching its archive. A process
    // death can then leave an incomplete deletion visible in Recent games, but
    // it cannot restore the deleted session as the active game on next launch.
    if ((await _read(_active))?['id'] == id) {
      await _write(_active, {'version': 1, 'id': id, 'data': null});
      final previous = File('${_active.path}.previous');
      if (await previous.exists()) await previous.delete();
      _activeId = null;
    }
    await _deleteArchiveFiles(id);
  });

  Future<void> deleteMany(Iterable<String> ids) {
    final targets = ids.toSet();
    for (final id in targets) {
      if (!RegExp(r'^[0-9a-z-]+$').hasMatch(id)) {
        throw const FormatException('Invalid session identifier');
      }
    }
    return _serial(() async {
      final activeId = (await _read(_active))?['id'] as String?;
      for (final id in targets) {
        await _read(_archiveFile(id));
      }
      if (activeId != null && targets.contains(activeId)) {
        await _write(_active, {'version': 1, 'id': activeId, 'data': null});
        final previous = File('${_active.path}.previous');
        if (await previous.exists()) await previous.delete();
        _activeId = null;
      }
      for (final id in targets) {
        await _deleteArchiveFiles(id);
      }
    });
  }

  Future<void> _deleteArchiveFiles(String id) async {
    final archive = _archiveFile(id);
    // Delete rollback files first and the primary last. If deletion is
    // interrupted, _read() must never resurrect an older .previous copy after
    // the primary has disappeared.
    for (final suffix in ['.pending', '.previous', '']) {
      final file = File('${archive.path}$suffix');
      if (await file.exists()) await file.delete();
    }
  }
}

class RecentGamesPage extends StatefulWidget {
  const RecentGamesPage({
    this.loadGames,
    this.openGame,
    this.deleteGames,
    this.readPgnForExport,
    super.key,
  });

  final Future<List<RecentSession>> Function()? loadGames;
  final Future<Map<String, dynamic>?> Function(String id)? openGame;
  final Future<void> Function(Iterable<String> ids)? deleteGames;
  final Future<String?> Function(String id)? readPgnForExport;

  @override
  State<RecentGamesPage> createState() => _RecentGamesPageState();
}

class _RecentGamesPageState extends State<RecentGamesPage> {
  List<RecentSession>? _games;
  Object? _loadError;
  bool _selecting = false;
  bool _busy = false;
  bool _updatingFiles = false;
  bool _exporting = false;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  Future<void> _reload() async {
    try {
      final games =
          await (widget.loadGames?.call() ?? ActiveSessionStore.recent());
      if (!mounted) return;
      setState(() {
        _games = games;
        _loadError = null;
        _selected.removeWhere((id) => !games.any((game) => game.id == id));
        if (games.isEmpty) _selecting = false;
      });
    } catch (error, stackTrace) {
      unawaited(AppDiagnostics.record('recent-games-load', error, stackTrace));
      if (!mounted) return;
      setState(() => _loadError = error);
    }
  }

  void _toggleSelection(String id) {
    if (_busy) return;
    setState(() {
      _selecting = true;
      if (!_selected.add(id)) _selected.remove(id);
    });
  }

  void _cancelSelection() {
    if (_busy) return;
    setState(() {
      _selecting = false;
      _selected.clear();
    });
  }

  Future<void> _exportSelected({required bool share}) async {
    if (_busy || _selected.isEmpty) return;
    // Selection order is irrelevant: use the exact displayed Recent Games order.
    final ids = [
      for (final game in _games ?? <RecentSession>[])
        if (_selected.contains(game.id)) game.id,
    ];
    if (ids.isEmpty) return;
    setState(() {
      _busy = true;
      _exporting = true;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    try {
      final pgn = await RecentGamesPgn.export(
        ids,
        widget.readPgnForExport ?? ActiveSessionStore.readPgnForExport,
      );
      if (!mounted) return;
      await PgnFiles.export(
        context,
        pgn,
        share: share,
        failureMessage: l10n(context).recentExportFailed,
      );
    } catch (error, stackTrace) {
      unawaited(
        AppDiagnostics.record('recent-games-export', error, stackTrace),
      );
      if (mounted) {
        _showOperationError(switch (error) {
          PgnExportGameTooLarge() => l10n(context).recentExportGameTooLarge,
          PgnExportTooLarge() => l10n(context).recentExportTooLarge,
          _ => l10n(context).recentExportFailed,
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _exporting = false;
        });
      }
    }
  }

  Future<void> _deleteGames(List<RecentSession> games) async {
    if (_busy || games.isEmpty) return;
    setState(() => _busy = true);
    try {
      await _confirmAndDeleteGames(games);
    } catch (error, stackTrace) {
      unawaited(
        AppDiagnostics.record('recent-games-delete', error, stackTrace),
      );
      if (mounted) {
        _showOperationError(l10n(context).recentDeleteFailed);
        // A batch can fail after deleting some entries. Refresh the list so a
        // retry targets the records that actually remain.
        await _reload();
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _updatingFiles = false;
        });
      }
    }
  }

  void _showOperationError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openGame(RecentSession game) async {
    // Guard synchronously as another tap may arrive before the busy frame.
    if (_busy) return;
    setState(() {
      _busy = true;
      _updatingFiles = true;
    });
    var opened = false;
    try {
      final data =
          await (widget.openGame?.call(game.id) ??
              ActiveSessionStore.open(game.id));
      if (!mounted) return;
      if (data == null) {
        _showOperationError(l10n(context).recentOpenFailed);
      } else {
        Navigator.pop(context, data);
        opened = true;
      }
    } catch (error, stackTrace) {
      unawaited(AppDiagnostics.record('recent-games-open', error, stackTrace));
      if (mounted) {
        _showOperationError(l10n(context).recentOpenFailed);
      }
    } finally {
      // Keep rejecting callbacks while a successfully opened page exits.
      if (mounted && !opened) {
        setState(() {
          _busy = false;
          _updatingFiles = false;
        });
      }
    }
  }

  Future<void> _confirmAndDeleteGames(List<RecentSession> games) async {
    final count = games.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n(context).recentDeleteTitle(count)),
        content: Text(l10n(context).recentDeleteWarning(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n(context).deleteAction),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _updatingFiles = true);
    final ids = games.map((game) => game.id);
    if (widget.deleteGames case final deleteGames?) {
      await deleteGames(ids);
    } else {
      await ActiveSessionStore.deleteMany(ids);
    }
    if (!mounted) return;
    setState(() {
      _selected.clear();
      _selecting = false;
      _games = null;
    });
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final games = _games;
    final page = Scaffold(
      appBar: AppBar(
        bottom: _updatingFiles || _exporting
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  semanticsLabel: _exporting
                      ? l10n(context).recentExportGames
                      : l10n(context).recentUpdating,
                ),
              )
            : null,
        leading: _selecting
            ? IconButton(
                tooltip: l10n(context).recentCancelSelection,
                onPressed: _cancelSelection,
                icon: const Icon(Icons.close),
              )
            : null,
        title: Text(
          _selecting
              ? l10n(context).recentSelectedCount(_selected.length)
              : l10n(context).recentGames,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_selecting && games != null) ...[
            PopupMenuButton<bool>(
              key: const ValueKey('export-selected-games'),
              tooltip: l10n(context).recentExportGames,
              enabled: _selected.isNotEmpty && !_busy,
              icon: const Icon(Icons.ios_share_outlined),
              onSelected: (share) => unawaited(_exportSelected(share: share)),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: false,
                  child: Text(l10n(context).savePgnFile),
                ),
                PopupMenuItem(value: true, child: Text(l10n(context).sharePgn)),
              ],
            ),
            IconButton(
              key: const ValueKey('select-all-games'),
              tooltip: _selected.length == games.length
                  ? l10n(context).recentClearSelection
                  : l10n(context).recentSelectAll,
              onPressed: () {
                if (_busy) return;
                setState(() {
                  if (_selected.length == games.length) {
                    _selected.clear();
                  } else {
                    _selected.addAll(games.map((game) => game.id));
                  }
                });
              },
              icon: const Icon(Icons.select_all),
            ),
            IconButton(
              key: const ValueKey('delete-selected-games'),
              tooltip: l10n(context).recentDeleteSelected,
              onPressed: _selected.isEmpty
                  ? null
                  : () => _deleteGames(
                      games
                          .where((game) => _selected.contains(game.id))
                          .toList(),
                    ),
              icon: const Icon(Icons.delete_outline),
            ),
          ] else if (games != null && games.isNotEmpty)
            PopupMenuButton<String>(
              key: const ValueKey('recent-games-menu'),
              onSelected: (action) {
                if (action == 'select') setState(() => _selecting = true);
                if (action == 'delete-all') unawaited(_deleteGames(games));
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'select',
                  child: Text(l10n(context).recentSelectGames),
                ),
                PopupMenuItem(
                  value: 'delete-all',
                  child: Text(l10n(context).recentDeleteAll),
                ),
              ],
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (_loadError != null) {
            return Center(child: Text(l10n(context).recentLoadFailed));
          }
          if (games == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (games.isEmpty) {
            return Center(
              child: Text(
                l10n(context).recentEmpty,
                textAlign: TextAlign.center,
              ),
            );
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final strings = l10n(context);
              final theme = Theme.of(context).textTheme;
              final dateStyle = theme.bodySmall!.copyWith(
                fontFeatures: const [ui.FontFeature.tabularFigures()],
              );
              final resultStyle = theme.bodyMedium!;
              double textWidth(String text, TextStyle style) {
                final painter = TextPainter(
                  text: TextSpan(text: text, style: style),
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                  maxLines: 1,
                )..layout();
                final width = painter.width.ceilToDouble() + 2;
                painter.dispose();
                return width;
              }

              final dateWidth = [
                textWidth(strings.recentDateColumn, theme.labelMedium!),
                textWidth('8888/88/88', dateStyle),
                if (games.any((game) => game.history.playedDate == null))
                  textWidth(strings.dateUnknown, dateStyle),
              ].reduce(max);
              final resultWidth = [
                textWidth(strings.recentResultColumn, theme.labelMedium!),
                for (final label in {
                  strings.recentIncomplete,
                  strings.recentCompleted,
                  '1/2-1/2',
                })
                  textWidth(label, resultStyle),
              ].reduce(max);
              final minimumGameWidth = MediaQuery.textScalerOf(context)
                  .scale(96);
              if (min(constraints.maxWidth, 1100) <
                  dateWidth +
                      resultWidth +
                      minimumGameWidth +
                      56 +
                      (_selecting ? 48 : 0)) {
                return ListView.builder(
                  key: const PageStorageKey('recent-games-list'),
                  itemCount: games.length,
                  itemBuilder: (context, index) {
                    final game = games[index];
                    final date = game.history.playedDate;
                    return ListTile(
                      key: ValueKey('recent-game-${game.id}'),
                      selected: _selected.contains(game.id),
                      leading: _selecting
                          ? Checkbox(
                              value: _selected.contains(game.id),
                              onChanged: (_) => _toggleSelection(game.id),
                            )
                          : null,
                      title: Text(game.localizedTitle(context)),
                      subtitle: _recentResultSubtitle(
                        context,
                        game,
                        _recentGameDate(context, date),
                      ),
                      onTap: () {
                        if (_busy) return;
                        if (_selecting) {
                          _toggleSelection(game.id);
                          return;
                        }
                        unawaited(_openGame(game));
                      },
                      onLongPress: () => _toggleSelection(game.id),
                    );
                  },
                );
              }
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    children: [
                      Padding(
                        key: const ValueKey('recent-table-header'),
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          12,
                          8,
                          12,
                          8,
                        ),
                        child: DefaultTextStyle(
                          style: Theme.of(context).textTheme.labelMedium!,
                          child: Row(
                            children: [
                              if (_selecting) const SizedBox(width: 48),
                              SizedBox(
                                width: dateWidth,
                                child: Semantics(
                                  header: true,
                                  child: Text(strings.recentDateColumn),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Semantics(
                                  header: true,
                                  child: Text(
                                    strings.recentGameColumn,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: resultWidth,
                                child: Semantics(
                                  header: true,
                                  child: Text(
                                    strings.recentResultColumn,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.builder(
                          key: const PageStorageKey('recent-games-list'),
                          itemCount: games.length,
                          itemBuilder: (context, index) {
                            final game = games[index];
                            final played = game.history.playedDate;
                            final date = _recentGameDate(context, played);
                            final result = game.localizedResult(context);
                            final description = switch (game.outcome) {
                              RecentGameOutcome.win => strings.recentWinResult(
                                result,
                              ),
                              RecentGameOutcome.loss =>
                                strings.recentLossResult(result),
                              RecentGameOutcome.draw =>
                                strings.recentDrawResult(result),
                              _ => result,
                            };
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  key: ValueKey('recent-game-${game.id}'),
                                  minTileHeight: 52,
                                  minVerticalPadding: 4,
                                  horizontalTitleGap: 16,
                                  contentPadding:
                                      const EdgeInsetsDirectional.symmetric(
                                        horizontal: 12,
                                      ),
                                  selected: _selected.contains(game.id),
                                  leading: SizedBox(
                                    width: dateWidth + (_selecting ? 48 : 0),
                                    child: Row(
                                      children: [
                                        if (_selecting)
                                          SizedBox(
                                            width: 48,
                                            child: Checkbox(
                                              value: _selected.contains(
                                                game.id,
                                              ),
                                              onChanged: (_) =>
                                                  _toggleSelection(game.id),
                                            ),
                                          ),
                                        Expanded(
                                          child: Text(
                                            date,
                                            maxLines: 1,
                                            softWrap: false,
                                            style: dateStyle,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          game.localizedTitle(context),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      SizedBox(
                                        width: resultWidth,
                                        child: Text(
                                          result,
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          softWrap: false,
                                          semanticsLabel: description,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: _recentResultColor(
                                                  context,
                                                  game,
                                                ),
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    if (_busy) return;
                                    if (_selecting) {
                                      _toggleSelection(game.id);
                                    } else {
                                      unawaited(_openGame(game));
                                    }
                                  },
                                  onLongPress: () => _toggleSelection(game.id),
                                ),
                                const Divider(height: 1),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
    return PopScope(
      canPop: !_busy && !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selecting) _cancelSelection();
      },
      child: AbsorbPointer(absorbing: _busy, child: page),
    );
  }
}

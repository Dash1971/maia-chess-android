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
    final maia = 'Maia ${data['elo'] ?? 1600}';
    final playerIsWhite = data['playerIsWhite'];
    return playerIsWhite is! bool || playerIsWhite
        ? 'Player — $maia'
        : '$maia — Player';
  }

  String localizedTitle(BuildContext context) {
    final strings = l10n(context);
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
              style: TextStyle(
                color: outcome.colorFor(Theme.of(context).brightness),
              ),
            ),
          TextSpan(text: parts[index]),
        ],
      ],
    ),
    semanticsLabel: strings.recentGameSummary(description, date),
  );
}

/// App-private, transactional files. Each successful write retains the previous
/// readable checkpoint. Archived games are separate files, not rewritten per move.
class SessionRepository {
  SessionRepository(this.directory);
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
        result.complete(await action());
      } catch (error, stack) {
        result.completeError(error, stack);
      }
    });
    return result.future;
  }

  Future<Map<String, dynamic>?> _readFile(File file) async {
    try {
      final source = await file.readAsString();
      final decoded = await Isolate.run(() => jsonDecode(source));
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
    final encoded = await Isolate.run(() => jsonEncode(payload));
    final temporary = File('${file.path}.pending');
    await temporary.writeAsString(encoded, flush: true);
    if (primary != null) {
      await file.rename('${file.path}.previous');
    }
    await temporary.rename(file.path);
    if (file.path == _active.path) _rememberActive(envelope);
  }

  File get _active => File('${directory.path}/active.json');
  File _archiveFile(String id) {
    if (!RegExp(r'^[0-9a-z-]+$').hasMatch(id)) {
      throw const FormatException('Invalid session identifier');
    }
    return File('${directory.path}/games/$id.json');
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

  static Map<String, dynamic>? _recentGameData(Object? value) {
    if (value is! Map) return null;
    final data = Map<String, dynamic>.from(value);
    if (data['type'] == 'review') {
      return _recentGameData(data['activeGame']);
    }
    if (data['type'] != 'game') return null;
    final state = data['recentState'];
    // Sessions written before recentState existed remain visible and are
    // labelled from their PGN result. New live checkpoints stay recovery-only.
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

  Future<List<RecentSession>> recent() => _serial(() async {
    final entries = <String, RecentSession>{};
    void add(Map<String, dynamic>? envelope) {
      if (envelope == null) return;
      final data = _recentGameData(envelope['data']);
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

    final archive = Directory('${directory.path}/games');
    if (await archive.exists()) {
      final names = <String>{};
      await for (final entity in archive.list()) {
        if (entity is File &&
            (entity.path.endsWith('.json') ||
                entity.path.endsWith('.json.previous'))) {
          names.add(entity.path.replaceFirst(RegExp(r'\.previous$'), ''));
        }
      }
      for (final name in names) {
        add(await _read(File(name)));
      }
    }
    add(await _read(_active));
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
  });

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
    super.key,
  });

  final Future<List<RecentSession>> Function()? loadGames;
  final Future<Map<String, dynamic>?> Function(String id)? openGame;
  final Future<void> Function(Iterable<String> ids)? deleteGames;

  @override
  State<RecentGamesPage> createState() => _RecentGamesPageState();
}

class _RecentGamesPageState extends State<RecentGamesPage> {
  List<RecentSession>? _games;
  Object? _loadError;
  bool _selecting = false;
  bool _busy = false;
  bool _updatingFiles = false;
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
        bottom: _updatingFiles
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  semanticsLabel: l10n(context).recentUpdating,
                ),
              )
            : null,
        leading: _selecting
            ? IconButton(
                tooltip: l10n(context).recentCancelSelection,
                onPressed: () => setState(() {
                  _selecting = false;
                  _selected.clear();
                }),
                icon: const Icon(Icons.close),
              )
            : null,
        title: Text(
          _selecting
              ? l10n(context).recentSelectedCount(_selected.length)
              : l10n(context).recentGames,
        ),
        actions: [
          if (_selecting && games != null) ...[
            IconButton(
              key: const ValueKey('select-all-games'),
              tooltip: _selected.length == games.length
                  ? l10n(context).recentClearSelection
                  : l10n(context).recentSelectAll,
              onPressed: () => setState(() {
                if (_selected.length == games.length) {
                  _selected.clear();
                } else {
                  _selected.addAll(games.map((game) => game.id));
                }
              }),
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
          return ListView.builder(
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
                  date == null
                      ? l10n(context).dateUnknown
                      : MaterialLocalizations.of(context)
                            .formatCompactDate(date),
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
                trailing: _selecting
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: l10n(context).recentDeleteOne,
                        onPressed: () => _deleteGames([game]),
                      ),
              );
            },
          );
        },
      ),
    );
    return PopScope(
      canPop: !_busy,
      child: AbsorbPointer(absorbing: _busy, child: page),
    );
  }
}

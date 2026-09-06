part of '../main.dart';

class RecentSession {
  const RecentSession(this.id, this.updatedAt, this.data);
  final String id;
  final DateTime updatedAt;
  final Map<String, dynamic> data;
  bool get isIncomplete =>
      data['recentState'] == 'incomplete' ||
      (data['recentState'] == null &&
          (data['forcedResult'] == null) &&
          !_pgnHasFinalResult(data['pgn'] as String?));

  static bool _pgnHasFinalResult(String? pgn) {
    if (pgn == null) return false;
    final result = RegExp(
      r'^\[Result\s+"(1-0|0-1|1/2-1/2)"\]\s*$',
      multiLine: true,
    ).firstMatch(pgn);
    return result != null;
  }

  String get title {
    final pgn = data['pgn'] ?? (data['session'] as Map?)?['pgn'];
    // Listing a long game must not parse its move tree on the UI isolate.
    final eventHeader = pgn is String
        ? RegExp(
            r'^\[Event .*$',
            multiLine: true,
          ).firstMatch(pgn.substring(0, min(pgn.length, 8192)))?.group(0)
        : null;
    final event = eventHeader == null
        ? null
        : dc.PgnGame.parsePgn(
            eventHeader,
            initHeaders: dc.PgnGame.emptyHeaders,
          ).headers['Event'];
    return event != null && event != '?' && !event.startsWith('Mobile Maia')
        ? event
        : 'Game · Maia ${data['elo'] ?? 1600}';
  }
}

/// App-private, transactional files. Each successful write retains the previous
/// readable checkpoint. Archived games are separate files, not rewritten per move.
class SessionRepository {
  SessionRepository(this.directory);
  final Directory directory;
  Future<void> _tail = Future.value();
  String? _activeId;

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
      if (decoded is! Map ||
          decoded['version'] != 1 ||
          decoded['id'] is! String ||
          (decoded['data'] != null && decoded['data'] is! Map)) {
        return null;
      }
      return Map<String, dynamic>.from(decoded);
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _read(File file) async =>
      await _readFile(file) ?? await _readFile(File('${file.path}.previous'));

  Future<void> _write(File file, Map<String, Object?> envelope) async {
    await file.parent.create(recursive: true);
    final payload = envelope;
    final encoded = await Isolate.run(() => jsonEncode(payload));
    final temporary = File('${file.path}.pending');
    await temporary.writeAsString(encoded, flush: true);
    if (await _readFile(file) != null) {
      await file.rename('${file.path}.previous');
    }
    await temporary.rename(file.path);
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
    _activeId = envelope?['id'] as String?;
    return envelope?['data'] == null
        ? null
        : Map<String, dynamic>.from(envelope!['data'] as Map);
  });

  static Object? _detach(Object? value) => switch (value) {
    Map() => value.map((key, item) => MapEntry(key, _detach(item))),
    List() => value.map(_detach).toList(),
    _ => value,
  };

  Future<void> save(Map<String, Object?> data) {
    // Transfer to the isolate from a detached snapshot, never a live game list.
    final snapshot = Map<String, Object?>.from(_detach(data) as Map);
    return _serial(() async {
      _activeId ??=
          '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 30)}';
      await _write(_active, {
        'version': 1,
        'id': _activeId,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'data': snapshot,
      });
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
    final envelope = await _read(_active);
    final data = _recentGameData(envelope?['data']);
    if (envelope != null && data != null) {
      await _write(_archiveFile(envelope['id'] as String), {
        ...envelope,
        'data': data,
      });
    }
  }

  Future<void> startNew() => _serial(() async {
    await _archive();
    await _write(_active, {
      'version': 1,
      'id': _activeId ?? 'none',
      'data': null,
    });
    final previous = File('${_active.path}.previous');
    if (await previous.exists()) await previous.delete();
    _activeId = null;
  });

  Future<void> discardActive() => _serial(() async {
    final envelope = await _read(_active);
    final id = envelope?['id'] as String? ?? _activeId ?? 'none';
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
    return entries.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  });

  Future<Map<String, dynamic>?> open(String id) => _serial(() async {
    await _archive();
    final entry = await _read(_archiveFile(id));
    if (entry == null) return null;
    final data = _recentGameData(entry['data']);
    if (data == null) return null;
    _activeId = id;
    await _write(_active, {...entry, 'data': data});
    return data;
  });

  Future<void> delete(String id) => _serial(() async {
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
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      _selecting = true;
      if (!_selected.add(id)) _selected.remove(id);
    });
  }

  Future<void> _deleteGames(List<RecentSession> games) async {
    if (games.isEmpty) return;
    final count = games.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(count == 1 ? 'Delete saved game?' : 'Delete $count games?'),
        content: Text(
          count == 1
              ? 'This saved game will be permanently deleted.'
              : 'These $count saved games will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
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
    return Scaffold(
      appBar: AppBar(
        leading: _selecting
            ? IconButton(
                tooltip: 'Cancel selection',
                onPressed: () => setState(() {
                  _selecting = false;
                  _selected.clear();
                }),
                icon: const Icon(Icons.close),
              )
            : null,
        title: Text(
          _selecting ? '${_selected.length} selected' : 'Recent games',
        ),
        actions: [
          if (_selecting && games != null) ...[
            IconButton(
              key: const ValueKey('select-all-games'),
              tooltip: _selected.length == games.length
                  ? 'Clear selection'
                  : 'Select all games',
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
              tooltip: 'Delete selected games',
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
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'select', child: Text('Select games')),
                PopupMenuItem(
                  value: 'delete-all',
                  child: Text('Delete all games'),
                ),
              ],
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (_loadError != null) {
            return const Center(
              child: Text('Could not load saved games. Please try again.'),
            );
          }
          if (games == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (games.isEmpty) {
            return const Center(
              child: Text(
                'Completed games and incomplete games saved from Home will appear here.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              final date = game.updatedAt.toLocal();
              return ListTile(
                selected: _selected.contains(game.id),
                leading: _selecting
                    ? Checkbox(
                        value: _selected.contains(game.id),
                        onChanged: (_) => _toggleSelection(game.id),
                      )
                    : null,
                title: Text(game.title),
                subtitle: Text(
                  '${game.isIncomplete ? 'Incomplete' : 'Completed'} · '
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                ),
                onTap: () async {
                  if (_selecting) {
                    _toggleSelection(game.id);
                    return;
                  }
                  final data =
                      await (widget.openGame?.call(game.id) ??
                          ActiveSessionStore.open(game.id));
                  if (context.mounted && data != null) {
                    Navigator.pop(context, data);
                  }
                },
                onLongPress: () => _toggleSelection(game.id),
                trailing: _selecting
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete saved game',
                        onPressed: () => _deleteGames([game]),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}

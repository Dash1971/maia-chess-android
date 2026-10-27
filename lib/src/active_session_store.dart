part of '../main.dart';

class ActiveSessionStore {
  static const _key = 'activeSessionV1';
  static const _restorePending = 'sessionRestorePendingV1';
  static const _restoreBlocked = 'sessionRestoreBlockedV1';
  static final _restoreProcessToken =
      '${DateTime.now().microsecondsSinceEpoch}:${Random.secure().nextInt(1 << 32)}';

  /// Keep the checkpoint and archive untouched when a previous process died.
  /// A pending restore also protects devices without Android exit reports.
  static Future<bool> beginAutomaticRestore() async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(_restoreBlocked) == true) return false;
    final pending = preferences.get(_restorePending);
    var interrupted = pending != null && pending != _restoreProcessToken;
    try {
      if (_usingRepository) {
        interrupted |=
            await maiaEngineChannel
                .invokeMethod<bool>('previousProcessFailed')
                .timeout(const Duration(seconds: 2)) ==
            true;
      }
    } on MissingPluginException {
      // Older/non-Android hosts still have the persistent restore marker.
    } catch (error, stack) {
      await AppDiagnostics.record('session-exit-report', error, stack);
    }
    if (interrupted) {
      await blockAutomaticRestore();
      return false;
    }
    if (!await preferences.setString(_restorePending, _restoreProcessToken)) {
      throw const FileSystemException('Could not protect session restoration');
    }
    return true;
  }

  static Future<void> blockAutomaticRestore() async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setBool(_restoreBlocked, true)) {
      throw const FileSystemException('Could not protect session restoration');
    }
  }

  /// A normal trip to the background is not evidence of a failed restore.
  static Future<void> finishAutomaticRestore() async {
    await (await SharedPreferences.getInstance()).remove(_restorePending);
  }

  static Future<void> _allowAutomaticRestore() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_restorePending);
    await preferences.remove(_restoreBlocked);
  }

  static Future<SessionRepository>? _repository;
  static SessionRepository? _testRepository;

  /// Debug-only override for exercising real file storage in host tests.
  @visibleForTesting
  static void setTestRepository(SessionRepository? store) {
    assert(() {
      _testRepository = store;
      return true;
    }());
  }

  static bool get _usingRepository =>
      Platform.isAndroid || _testRepository != null;

  static Future<void> _validateLegacyCheckpoint() async {
    final source = (await SharedPreferences.getInstance()).getString(_key);
    if (source == null) return;
    if (_usingRepository && await (await repository).hasCheckpoint()) return;
    try {
      validateSessionSchema(jsonDecode(source));
    } on FormatException {
      // Malformed legacy JSON is handled by the normal recovery path.
    }
  }

  static Future<SessionRepository> get repository => _testRepository != null
      ? Future.value(_testRepository!)
      : _repository ??= () async {
          final path = await maiaEngineChannel.invokeMethod<String>(
            'dataDirectory',
          );
          if (path == null) {
            throw const FileSystemException('Session storage unavailable');
          }
          return SessionRepository(Directory('$path/sessions'));
        }();

  static Future<void> startNew({DateTime? gameStartedAt}) async {
    await _validateLegacyCheckpoint();
    if (_usingRepository) {
      await (await repository).startNew(gameStartedAt: gameStartedAt);
    } else {
      await (await SharedPreferences.getInstance()).remove(_key);
    }
    await _allowAutomaticRestore();
  }

  static Future<void> discardActive() async {
    await _validateLegacyCheckpoint();
    if (_usingRepository) {
      await (await repository).discardActive();
    } else {
      await (await SharedPreferences.getInstance()).remove(_key);
    }
    await _allowAutomaticRestore();
  }

  static Future<List<RecentSession>> recent() async =>
      _usingRepository ? (await repository).recent() : [];
  static Future<Map<String, dynamic>?> open(String id) async {
    final saved = await (await repository).open(id);
    await _allowAutomaticRestore();
    return saved;
  }

  static Future<void> delete(String id) async => (await repository).delete(id);
  static Future<void> deleteMany(Iterable<String> ids) async =>
      (await repository).deleteMany(ids);

  static Future<Map<String, dynamic>?> load() async {
    if (_usingRepository) {
      return restoreOrMigrate(
        await repository,
        await SharedPreferences.getInstance(),
      );
    }
    final source = (await SharedPreferences.getInstance()).getString(_key);
    if (source == null) return null;
    try {
      final decoded = Map<String, dynamic>.from(jsonDecode(source) as Map);
      validateSessionSchema(decoded);
      if (decoded['schema'] != 1) {
        await AppDiagnostics.recordEvent(
          'active-session-unsupported-schema:${decoded['schema']}',
        );
        await clear();
        return null;
      }
      return decoded;
    } on UnsupportedSessionFormatException {
      rethrow;
    } catch (error, stackTrace) {
      await AppDiagnostics.record('active-session-load', error, stackTrace);
      // Do not retry a permanently malformed session on every app launch.
      await clear();
      return null;
    }
  }

  /// If a process dies after writing the new file but before removing the old
  /// preference, the file (including a Home tombstone) remains authoritative.
  static Future<Map<String, dynamic>?> restoreOrMigrate(
    SessionRepository store,
    SharedPreferences preferences,
  ) async {
    final saved = await store.load();
    validateSessionSchema(saved);
    if (await store.hasCheckpoint()) {
      await preferences.remove(_key);
      return saved;
    }
    final legacy = preferences.getString(_key);
    if (legacy == null) return null;
    Map<String, dynamic> decoded;
    try {
      decoded = Map<String, dynamic>.from(jsonDecode(legacy) as Map);
      validateSessionSchema(decoded);
      if (decoded['schema'] != 1) return null;
    } on UnsupportedSessionFormatException {
      rethrow;
    } catch (error, stack) {
      await AppDiagnostics.record('legacy-session-load', error, stack);
      return null;
    }
    await store.save(decoded);
    await preferences.remove(_key);
    return decoded;
  }

  static Future<void> save(Map<String, Object?> value) async {
    await _validateLegacyCheckpoint();
    if (_usingRepository) {
      await (await repository).save({'schema': 1, ...value});
      return;
    }
    validateSessionSchema({'schema': 1, ...value});
    await (await SharedPreferences.getInstance()).setString(
      _key,
      jsonEncode({'schema': 1, ...value}),
    );
  }

  static Future<void> clear() async {
    await _validateLegacyCheckpoint();
    if (_usingRepository) {
      await (await repository).startNew();
      await _allowAutomaticRestore();
      return;
    }
    await (await SharedPreferences.getInstance()).remove(_key);
    await _allowAutomaticRestore();
  }
}

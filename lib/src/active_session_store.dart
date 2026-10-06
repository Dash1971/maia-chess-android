part of '../main.dart';

class ActiveSessionStore {
  static const _key = 'activeSessionV1';
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
  }

  static Future<void> discardActive() async {
    await _validateLegacyCheckpoint();
    if (_usingRepository) {
      await (await repository).discardActive();
    } else {
      await (await SharedPreferences.getInstance()).remove(_key);
    }
  }

  static Future<List<RecentSession>> recent() async =>
      _usingRepository ? (await repository).recent() : [];
  static Future<Map<String, dynamic>?> open(String id) async =>
      (await repository).open(id);
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
      return;
    }
    await (await SharedPreferences.getInstance()).remove(_key);
  }
}

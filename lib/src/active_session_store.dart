part of '../main.dart';

class ActiveSessionStore {
  static const _key = 'activeSessionV1';
  static Future<SessionRepository>? _repository;
  static Future<SessionRepository> get repository => _repository ??= () async {
    final path = await maiaEngineChannel.invokeMethod<String>('dataDirectory');
    if (path == null) {
      throw const FileSystemException('Session storage unavailable');
    }
    return SessionRepository(Directory('$path/sessions'));
  }();

  static Future<void> startNew() async {
    if (Platform.isAndroid) {
      await (await repository).startNew();
    } else {
      await (await SharedPreferences.getInstance()).remove(_key);
    }
  }

  static Future<void> discardActive() async {
    if (Platform.isAndroid) {
      await (await repository).discardActive();
    } else {
      await (await SharedPreferences.getInstance()).remove(_key);
    }
  }

  static Future<List<RecentSession>> recent() async =>
      Platform.isAndroid ? (await repository).recent() : [];
  static Future<Map<String, dynamic>?> open(String id) async =>
      (await repository).open(id);
  static Future<void> delete(String id) async => (await repository).delete(id);
  static Future<void> deleteMany(Iterable<String> ids) async =>
      (await repository).deleteMany(ids);

  static Future<Map<String, dynamic>?> load() async {
    if (Platform.isAndroid) {
      return restoreOrMigrate(
        await repository,
        await SharedPreferences.getInstance(),
      );
    }
    final source = (await SharedPreferences.getInstance()).getString(_key);
    if (source == null) return null;
    try {
      final decoded = Map<String, dynamic>.from(jsonDecode(source) as Map);
      if (decoded['schema'] != 1) {
        await AppDiagnostics.recordEvent(
          'active-session-unsupported-schema:${decoded['schema']}',
        );
        await clear();
        return null;
      }
      return decoded;
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
    if (await store.hasCheckpoint()) {
      await preferences.remove(_key);
      return saved;
    }
    final legacy = preferences.getString(_key);
    if (legacy == null) return null;
    Map<String, dynamic> decoded;
    try {
      decoded = Map<String, dynamic>.from(jsonDecode(legacy) as Map);
      if (decoded['schema'] != 1) return null;
    } catch (error, stack) {
      await AppDiagnostics.record('legacy-session-load', error, stack);
      return null;
    }
    await store.save(decoded);
    await preferences.remove(_key);
    return decoded;
  }

  static Future<void> save(Map<String, Object?> value) async {
    if (Platform.isAndroid) {
      await (await repository).save({'schema': 1, ...value});
      return;
    }
    await (await SharedPreferences.getInstance()).setString(
      _key,
      jsonEncode({'schema': 1, ...value}),
    );
  }

  static Future<void> clear() async {
    if (Platform.isAndroid) {
      await (await repository).startNew();
      return;
    }
    await (await SharedPreferences.getInstance()).remove(_key);
  }
}

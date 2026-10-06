part of '../main.dart';

/// Historical facts, independent of autosave and review activity. A UTC
/// DateTime is used only as a calendar container by [playedDate], never converted
/// to the device timezone. Legacy PGNs establish a day, not an exact start time.
class GameHistory {
  const GameHistory({this.playedOn, this.startedAt});
  final String? playedOn;
  final DateTime? startedAt;

  DateTime? get playedDate => _calendarDate(playedOn);

  factory GameHistory.started(DateTime instant) =>
      GameHistory(playedOn: _dateText(instant), startedAt: instant.toUtc());

  factory GameHistory.fromJson(Object? value) {
    if (value is! Map) return const GameHistory();
    if (value['version'] != 1) {
      throw UnsupportedSessionFormatException('gameHistory', value['version']);
    }
    final date = _calendarDate(value['playedOn']);
    if (date == null) return const GameHistory();
    final timestamp = value['startedAt'];
    final parsed = timestamp is String ? DateTime.tryParse(timestamp) : null;
    // We write canonical UTC timestamps. Do not normalize malformed dates into
    // a believable start instant or reinterpret an unzoned legacy value.
    final started =
        parsed != null && parsed.isUtc && parsed.toIso8601String() == timestamp
        ? parsed
        : null;
    return GameHistory(playedOn: _dateText(date), startedAt: started);
  }

  factory GameHistory.fromLegacy(Object? data) {
    final game = gameData(data);
    final pgn = game?['pgn'];
    if (pgn is! String) return const GameHistory();
    final header = RegExp(r'\s*\[([A-Za-z0-9_]+)\s+"((?:[^"\\]|\\.)*)"\s*\]');
    var offset = pgn.startsWith('\uFEFF') ? 1 : 0;
    String? date;
    var count = 0;
    while (offset < pgn.length) {
      final match = header.matchAsPrefix(pgn, offset);
      if (match == null) {
        break; // Never interpret tags inside movetext/comments.
      }
      offset = match.end;
      if (offset > 8192) return const GameHistory();
      if (match[1] == 'Date') {
        count++;
        date = match[2];
      }
    }
    if (count != 1 ||
        date == null ||
        !RegExp(r'^\d{4}\.\d{2}\.\d{2}$').hasMatch(date)) {
      return const GameHistory();
    }
    final parsed = _calendarDate(date.replaceAll('.', '-'));
    return GameHistory(playedOn: parsed == null ? null : _dateText(parsed));
  }

  static Map? gameData(Object? data) {
    if (data is! Map) return null;
    if (data['type'] == 'review') {
      final game = data['activeGame'];
      return game is Map && game['type'] == 'game' ? game : null;
    }
    return data['type'] == 'game' ? data : null;
  }

  static DateTime? _calendarDate(Object? text) {
    if (text is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
      return null;
    }
    final year = int.parse(text.substring(0, 4));
    final month = int.parse(text.substring(5, 7));
    final day = int.parse(text.substring(8));
    if (year < 1 || month < 1 || month > 12 || day < 1 || day > 31) return null;
    final date = DateTime.utc(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }

  static String _dateText(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Map<String, Object?> toJson() => {
    'version': 1,
    'playedOn': playedOn,
    'startedAt': startedAt?.toUtc().toIso8601String(),
  };
}

/// A newer format is not corruption: neither overwrite it nor roll back to an
/// older backup. The caller's existing storage-error UI can report the failure.
class UnsupportedSessionFormatException implements Exception {
  const UnsupportedSessionFormatException(this.area, this.version);
  final String area;
  final Object? version;
  @override
  String toString() =>
      'Unsupported saved-session $area version: $version. '
      'Update Mobile Maia to read this data; the unsupported data was preserved.';
}

/// Missing schema belongs to legacy snapshots. An explicit unsupported schema
/// is not corruption and must not be rewritten by an older reader.
void validateSessionSchema(Object? data) {
  if (data is! Map) return;
  if (data.containsKey('schema') && data['schema'] != 1) {
    throw UnsupportedSessionFormatException('session', data['schema']);
  }
  if (data['type'] == 'review') {
    final game = data['activeGame'];
    if (game is Map && game.containsKey('schema') && game['schema'] != 1) {
      throw UnsupportedSessionFormatException('activeGame', game['schema']);
    }
  }
}

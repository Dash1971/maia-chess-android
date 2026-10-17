part of '../main.dart';

enum BoardKind { chessnut, pegasus, squareOff }

/// Canonical product names, never a Bluetooth address or an unrecognized alias.
String electronicBoardDisplayName(
  AppLocalizations translations,
  BoardKind? kind,
  String? deviceName,
) {
  if (kind == BoardKind.chessnut) {
    final model = RegExp(
      r'^chessnut[\s_-]*(go|air|pro)(?=$|[\s_-])',
      caseSensitive: false,
    ).firstMatch(deviceName?.trim() ?? '')?.group(1)?.toLowerCase();
    return switch (model) {
      'go' => 'Chessnut Go',
      'air' => 'Chessnut Air',
      'pro' => 'Chessnut Pro',
      _ => 'Chessnut',
    };
  }
  return switch (kind) {
    BoardKind.pegasus => 'DGT Pegasus',
    BoardKind.squareOff => 'Square Off Grand Kingdom',
    _ => translations.chessboardDeviceName,
  };
}

/// Channel restriction independent of discovered devices or persisted preferences.
class BoardChannelPolicy {
  static bool supports(String? flavor, BoardKind kind) =>
      kind == BoardKind.chessnut || flavor == 'dev';
}

class BoardCandidate {
  const BoardCandidate(this.id, this.name, this.kind);
  final String id;
  final String name;
  final BoardKind kind;
}

abstract interface class DiscoverableBoardTransport
    implements ElectronicBoardTransport {
  Future<void> discoverBoards();
  Future<void> selectBoard(String id);
  Future<void> reconnectBoard(String? boardId);
  Future<void> startBoardGame(String player, String connectionSession);
  Future<void> movePiece(String uci, String connectionSession);
  Future<void> acknowledgeMove(bool accepted, String connectionSession);
  Future<void> confirmPosition(String connectionSession);
}

/// Square Off inbound notifications have no verified wire delimiter. Accept
/// only an exact four-character UCI move, bounded fragments, or known controls.
/// Metadata and malformed prefixes never become inferred board moves.
class SquareOffDecoder {
  SquareOffDecoder({Duration Function()? elapsed})
    : _elapsed = elapsed ?? _monotonicClock();

  static Duration Function() _monotonicClock() {
    final watch = Stopwatch()..start();
    return () => watch.elapsed;
  }

  final Duration Function() _elapsed;
  String _buffer = '';
  Duration? _fragmentStarted;
  static final _move = RegExp(r'^[a-h][1-8][a-h][1-8]$');
  static final _numeric = RegExp(r'^[0-9]+$');

  String? add(List<int> bytes) {
    final now = _elapsed();
    final started = _fragmentStarted;
    if (started != null &&
        (now < started || now - started > const Duration(milliseconds: 1000))) {
      reset();
    }
    if (bytes.any((byte) => byte < 0 || byte > 127) ||
        _buffer.length + bytes.length > 64) {
      reset();
      throw const FormatException('Invalid board message');
    }
    if (bytes.isEmpty) return null;
    final notification = String.fromCharCodes(bytes).trim();
    if (notification.isEmpty) {
      reset();
      return null;
    }
    if (notification == 'ERR') {
      reset();
      throw const FormatException('Board rejected move');
    }
    if (notification == 'OK') {
      reset();
      return null;
    }
    // Battery replies are complete notification messages, not UCI fragments.
    if (_numeric.hasMatch(notification) &&
        (_buffer.isEmpty || !_isMovePrefix(_buffer + notification))) {
      reset();
      return null;
    }
    final message = _buffer + notification;
    if (message == 'ERR') {
      reset();
      throw const FormatException('Board rejected move');
    }
    if (message == 'OK') {
      reset();
      return null;
    }
    if (_move.hasMatch(message)) {
      reset();
      return message;
    }
    if ((message.length > 4 && _move.hasMatch(message.substring(0, 4))) ||
        (message.length > 2 && message.startsWith('OK')) ||
        (message.length > 3 && message.startsWith('ERR'))) {
      reset();
      throw const FormatException('Unframed board messages');
    }
    if (_isMovePrefix(message) ||
        'OK'.startsWith(message) ||
        'ERR'.startsWith(message)) {
      _buffer = message;
      _fragmentStarted ??= now;
      return null;
    }
    reset();
    return null;
  }

  static bool _isMovePrefix(String value) {
    if (value.isEmpty || value.length > 4) return false;
    for (var index = 0; index < value.length; index++) {
      final code = value.codeUnitAt(index);
      final valid = index.isEven
          ? code >= 97 && code <= 104
          : code >= 49 && code <= 56;
      if (!valid) return false;
    }
    return true;
  }

  void reset() {
    _buffer = '';
    _fragmentStarted = null;
  }
}

/// Streaming DGT framing. No manufacturer initialization keys are included.
/// Unknown/locked occupancy must never become an empty, playable board.
class PegasusDecoder {
  final List<int> _buffer = [];
  final Set<String> _occupied = {};
  bool _hasDump = false;

  static String square(int index) {
    if (index < 0 || index >= 64) throw const FormatException('Invalid square');
    return '${String.fromCharCode(97 + index % 8)}${8 - index ~/ 8}';
  }

  List<Set<String>> add(List<int> bytes) {
    if (bytes.any((b) => b < 0 || b > 255) ||
        _buffer.length + bytes.length > 512) {
      reset();
      throw const FormatException('Invalid board frame');
    }
    _buffer.addAll(bytes);
    final positions = <Set<String>>[];
    while (_buffer.length >= 3) {
      if (_buffer[0] < 0x80 || _buffer[1] > 127 || _buffer[2] > 127) {
        reset();
        throw const FormatException('Invalid board frame');
      }
      final length = (_buffer[1] << 7) | _buffer[2];
      if (length < 3 || length > 256) {
        reset();
        throw const FormatException('Invalid board frame length');
      }
      if (_buffer.length < length) break;
      final frame = _buffer.sublist(0, length);
      _buffer.removeRange(0, length);
      final type = frame[0];
      final data = frame.sublist(3);
      if (type == 0xa5 && (data.length != 1 || data.single != 1)) {
        reset();
        throw const FormatException('Pegasus is locked');
      }
      if (type == 0x86) {
        if (data.length != 64 || data.any((b) => b != 0 && b != 1)) {
          reset();
          throw const FormatException('Invalid or locked board position');
        }
        _occupied.clear();
        for (var i = 0; i < 64; i++) {
          if (data[i] == 1) _occupied.add(square(i));
        }
        _hasDump = true;
        positions.add(Set.of(_occupied));
      } else if (type == 0x8e) {
        if (data.length != 2 || data[0] > 63 || data[1] > 1) {
          reset();
          throw const FormatException('Invalid board square update');
        }
        if (!_hasDump) continue;
        if (data[1] == 1) {
          _occupied.add(square(data[0]));
        } else {
          _occupied.remove(square(data[0]));
        }
        positions.add(Set.of(_occupied));
      }
    }
    return positions;
  }

  void reset() {
    _buffer.clear();
    _occupied.clear();
    _hasDump = false;
  }
}

/// Track lifts separately from final occupancy, which alone cannot distinguish
/// which occupied square was captured on. Never invent piece identities.
class OccupancyMoveResolver {
  String? _fen;
  final Set<String> lifted = {};

  void observe(chess.Chess game, Set<String> occupied) {
    if (_fen != game.fen) {
      _fen = game.fen;
      lifted.clear();
    }
    final expected = ChessnutProtocol.pieceMapFromFen(game.fen).keys.toSet();
    if (setEquals(expected, occupied)) {
      lifted.clear();
    } else {
      lifted.addAll(expected.difference(occupied));
    }
  }

  List<String> candidates(chess.Chess game, Set<String> occupied) {
    final result = <String>[];
    for (final move in game.moves({'asObjects': true}).cast<chess.Move>()) {
      final uci = MaiaEncoding.uci(move);
      final next = chess.Chess.fromFEN(game.fen);
      if (!next.move(move)) continue;
      final expected = ChessnutProtocol.pieceMapFromFen(next.fen).keys.toSet();
      if (expected.length == occupied.length &&
          expected.containsAll(occupied)) {
        result.add(uci);
      }
    }
    // Destination-lift evidence disambiguates captures when it was observed.
    final witnessed = result
        .where((uci) => lifted.contains(uci.substring(2, 4)))
        .toList();
    return witnessed.isNotEmpty ? witnessed : result;
  }

  bool needsConfirmation(chess.Chess game, List<String> candidates) =>
      candidates.length != 1 ||
      (candidates.isNotEmpty &&
          game.get(candidates.single.substring(2, 4)) != null &&
          !lifted.contains(candidates.single.substring(2, 4)));

  void reset() {
    _fen = null;
    lifted.clear();
  }
}

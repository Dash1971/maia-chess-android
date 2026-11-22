part of '../main.dart';

enum BoardKind { chessnut, squareOff }

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
    BoardKind.squareOff => 'Square Off Grand Kingdom',
    _ => translations.chessboardDeviceName,
  };
}

/// Channel restriction independent of discovered devices or persisted preferences.
class BoardChannelPolicy {
  static bool supports(String? flavor, BoardKind kind) =>
      kind == BoardKind.chessnut ||
      (const {'', 'stable', 'preview', 'dev'}.contains(flavor ?? '') &&
          kind == BoardKind.squareOff);
}

/// Keep promotion identity in chess/storage; the verified wire command contains
/// coordinates only. Physical replacement always needs explicit confirmation.
class SquareOffMotorMove {
  SquareOffMotorMove(this.uci) {
    if (!RegExp(r'^[a-h][1-8][a-h][1-8]([qrbn])?$').hasMatch(uci) ||
        uci.substring(0, 2) == uci.substring(2, 4) ||
        (uci.length == 5 &&
            !((uci[1] == '7' && uci[3] == '8') ||
                (uci[1] == '2' && uci[3] == '1')))) {
      throw const FormatException('Invalid motor move');
    }
  }
  final String uci;
  String get coordinates => uci.substring(0, 4);
  String? get promotion => uci.length == 5 ? uci[4] : null;
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

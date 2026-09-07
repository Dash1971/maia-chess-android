part of '../main.dart';

enum ElectronicBoardConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  ready,
  error,
}

class ElectronicBoardEvent {
  const ElectronicBoardEvent({
    required this.type,
    this.connectionState,
    this.message,
    this.deviceName,
    this.position,
    this.batteryPercent,
    this.charging,
  });

  final String type;
  final ElectronicBoardConnectionState? connectionState;
  final String? message;
  final String? deviceName;
  final Map<String, String>? position;
  final int? batteryPercent;
  final bool? charging;
}

abstract interface class ElectronicBoardTransport {
  Stream<ElectronicBoardEvent> get events;

  Future<void> connect();
  Future<void> disconnect();
  Future<void> setLeds(Iterable<String> squares);
  Future<void> beep({int frequencyHz = 1000, int durationMs = 200});
}

/// Coalesces unchanged guidance while preserving explicit recovery refreshes.
class ChessnutLedController {
  ChessnutLedController(this._transport);

  final ElectronicBoardTransport _transport;
  String? _state;
  Object? _request;
  Future<void>? _inFlight;

  /// The next request must reach the board after a connection change.
  void invalidate() {
    _state = null;
    _request = null;
    _inFlight = null;
  }

  Future<void> setLeds(Iterable<String> squares, {bool refresh = false}) {
    final normalized =
        squares.map((square) => square.trim().toLowerCase()).toSet().toList()
          ..sort();
    final state = normalized.join(',');
    if (_state == state && (!refresh || _inFlight != null)) {
      return _inFlight ?? Future<void>.value();
    }
    final request = Object();
    _state = state;
    _request = request;
    final completion = Future<void>.sync(() => _transport.setLeds(normalized))
        .then<void>(
          (_) {},
          onError: (Object error, StackTrace stackTrace) {
            if (identical(_request, request)) invalidate();
            Error.throwWithStackTrace(error, stackTrace);
          },
        )
        .whenComplete(() {
          if (identical(_request, request)) _inFlight = null;
        });
    _inFlight = completion;
    return completion;
  }
}

class ChessnutPlatformTransport implements ElectronicBoardTransport {
  ChessnutPlatformTransport._();

  static final ChessnutPlatformTransport instance =
      ChessnutPlatformTransport._();
  static const MethodChannel _methods = MethodChannel('maia_chess/chessnut');
  static const EventChannel _nativeEvents = EventChannel(
    'maia_chess/chessnut/events',
  );
  static final Stream<ElectronicBoardEvent> _events = _nativeEvents
      .receiveBroadcastStream()
      .map((dynamic value) => _decodeEvent(value));

  @override
  Stream<ElectronicBoardEvent> get events => _events;

  @override
  Future<void> connect() => _methods.invokeMethod<void>('connect');

  @override
  Future<void> disconnect() => _methods.invokeMethod<void>('disconnect');

  @override
  Future<void> setLeds(Iterable<String> squares) => _methods.invokeMethod<void>(
    'setLeds',
    {'command': ChessnutProtocol.encodeLedCommand(squares)},
  );

  @override
  Future<void> beep({int frequencyHz = 1000, int durationMs = 200}) =>
      _methods.invokeMethod<void>('beep', {
        'command': ChessnutProtocol.encodeBeepCommand(
          frequencyHz: frequencyHz,
          durationMs: durationMs,
        ),
      });

  static ElectronicBoardEvent _decodeEvent(dynamic value) {
    if (value is! Map) {
      return const ElectronicBoardEvent(
        type: 'status',
        connectionState: ElectronicBoardConnectionState.error,
        message: 'Invalid Chessnut event.',
      );
    }
    final event = Map<String, dynamic>.from(value);
    final type = event['type'] as String? ?? 'status';
    if (type == 'position') {
      try {
        final bytes = (event['data'] as List? ?? const [])
            .map((item) => (item as num).toInt())
            .toList(growable: false);
        return ElectronicBoardEvent(
          type: type,
          position: ChessnutProtocol.decodePosition(bytes),
        );
      } on FormatException catch (error) {
        return ElectronicBoardEvent(
          type: 'status',
          connectionState: ElectronicBoardConnectionState.error,
          message: error.message,
        );
      }
    }
    if (type == 'battery') {
      return ElectronicBoardEvent(
        type: type,
        batteryPercent: (event['percent'] as num?)?.toInt(),
        charging: event['charging'] as bool?,
      );
    }
    final rawState = event['state'] as String? ?? 'error';
    final state = ElectronicBoardConnectionState.values.firstWhere(
      (candidate) => candidate.name == rawState,
      orElse: () => ElectronicBoardConnectionState.error,
    );
    return ElectronicBoardEvent(
      type: type,
      connectionState: state,
      message: event['message'] as String?,
      deviceName: event['deviceName'] as String?,
    );
  }
}

class ChessnutProtocol {
  // Protocol constants follow Chessnut's published e-board API. Payload and
  // LED mapping were cross-checked against Roberto Marabini's GPL-3.0
  // chessnutair implementation and the physically tested Chessnut Maia CLI.
  static const Map<int, String> _pieceCodes = {
    0x0: '.',
    0x1: 'q',
    0x2: 'k',
    0x3: 'b',
    0x4: 'p',
    0x5: 'n',
    0x6: 'R',
    0x7: 'P',
    0x8: 'r',
    0x9: 'B',
    0xA: 'N',
    0xB: 'Q',
    0xC: 'K',
  };
  static const _payloadFiles = ['h', 'g', 'f', 'e', 'd', 'c', 'b', 'a'];

  static Map<String, String> decodePosition(List<int> notification) {
    final List<int> payload;
    if (notification.length == 32) {
      payload = notification;
    } else if (notification.length >= 34 &&
        notification[0] == 0x01 &&
        notification[1] == 0x24) {
      payload = notification.sublist(2, 34);
    } else {
      throw const FormatException(
        'Expected a 32-byte Chessnut payload or board notification.',
      );
    }

    final pieces = <String, String>{};
    var index = 0;
    for (var rank = 8; rank >= 1; rank--) {
      for (var filePair = 0; filePair < 8; filePair += 2) {
        final byte = payload[index++];
        if (byte < 0 || byte > 255) {
          throw const FormatException('Invalid Chessnut payload byte.');
        }
        final codes = [byte & 0x0f, byte >> 4];
        for (var offset = 0; offset < 2; offset++) {
          final piece = _pieceCodes[codes[offset]];
          if (piece == null) {
            throw FormatException(
              'Unknown Chessnut piece code: 0x${codes[offset].toRadixString(16)}.',
            );
          }
          if (piece != '.') {
            pieces['${_payloadFiles[filePair + offset]}$rank'] = piece;
          }
        }
      }
    }
    return Map.unmodifiable(pieces);
  }

  static List<int> encodeLedCommand(Iterable<String> squares) {
    final rows = List<int>.filled(8, 0);
    for (final square in squares) {
      final normalized = square.trim().toLowerCase();
      if (!RegExp(r'^[a-h][1-8]$').hasMatch(normalized)) {
        throw ArgumentError.value(square, 'squares', 'Invalid chess square');
      }
      final file = normalized.codeUnitAt(0) - 'a'.codeUnitAt(0);
      final rank = int.parse(normalized[1]);
      rows[8 - rank] |= 1 << (7 - file);
    }
    return [0x0a, 0x08, ...rows];
  }

  static List<int> encodeBeepCommand({
    int frequencyHz = 1000,
    int durationMs = 200,
  }) {
    // Command shape follows Chessnut's MIT-licensed EasyLinkSDK `cl_beep`
    // implementation. See THIRD_PARTY_NOTICES.md.
    if (frequencyHz < 1 || frequencyHz > 0xffff) {
      throw ArgumentError.value(
        frequencyHz,
        'frequencyHz',
        'Must be in 1..65535',
      );
    }
    if (durationMs < 1 || durationMs > 0xffff) {
      throw ArgumentError.value(
        durationMs,
        'durationMs',
        'Must be in 1..65535',
      );
    }
    return [
      0x0b,
      0x04,
      frequencyHz >> 8,
      frequencyHz & 0xff,
      durationMs >> 8,
      durationMs & 0xff,
    ];
  }

  static Map<String, String> pieceMapFromFen(String fen) {
    final placement = fen.split(RegExp(r'\s+')).first;
    final ranks = placement.split('/');
    if (ranks.length != 8) throw const FormatException('Invalid FEN.');
    final pieces = <String, String>{};
    for (var rankIndex = 0; rankIndex < 8; rankIndex++) {
      var fileIndex = 0;
      for (final rune in ranks[rankIndex].runes) {
        final character = String.fromCharCode(rune);
        final empty = int.tryParse(character);
        if (empty != null) {
          fileIndex += empty;
          continue;
        }
        if (!RegExp(r'^[prnbqkPRNBQK]$').hasMatch(character) ||
            fileIndex >= 8) {
          throw const FormatException('Invalid FEN piece placement.');
        }
        pieces['${String.fromCharCode('a'.codeUnitAt(0) + fileIndex)}${8 - rankIndex}'] =
            character;
        fileIndex++;
      }
      if (fileIndex != 8) throw const FormatException('Invalid FEN rank.');
    }
    return Map.unmodifiable(pieces);
  }

  static List<String> mismatchSquares(
    Map<String, String> observed,
    Map<String, String> expected,
  ) {
    final squares =
        {...observed.keys, ...expected.keys}
            .where((square) => observed[square] != expected[square])
            .toList(growable: false)
          ..sort();
    return squares;
  }

  static String? inferLegalMove(
    chess.Chess game,
    Map<String, String> observed,
  ) {
    String? match;
    for (final move in game.moves({'asObjects': true}).cast<chess.Move>()) {
      final candidate = chess.Chess.fromFEN(game.fen);
      if (!candidate.move(move)) continue;
      if (!_samePosition(pieceMapFromFen(candidate.fen), observed)) continue;
      final uci = MaiaEncoding.uci(move);
      if (match != null) return null;
      match = uci;
    }
    return match;
  }

  static bool looksLikeCompleteMoveAttempt(
    chess.Chess game,
    Map<String, String> observed,
  ) {
    final before = pieceMapFromFen(game.fen);
    final whiteToMove = game.turn == chess.Color.WHITE;
    bool movingPiece(String? piece) =>
        piece != null &&
        (whiteToMove
            ? piece == piece.toUpperCase()
            : piece == piece.toLowerCase());
    final removed = before.entries.any(
      (entry) => movingPiece(entry.value) && observed[entry.key] != entry.value,
    );
    final added = observed.entries.any(
      (entry) => movingPiece(entry.value) && before[entry.key] != entry.value,
    );
    return removed && added;
  }

  static bool positionsMatch(
    Map<String, String> left,
    Map<String, String> right,
  ) => _samePosition(left, right);

  static bool _samePosition(
    Map<String, String> left,
    Map<String, String> right,
  ) {
    if (left.length != right.length) return false;
    return left.entries.every((entry) => right[entry.key] == entry.value);
  }
}

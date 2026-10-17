part of '../main.dart';

enum ElectronicBoardConnectionState {
  disconnected,
  scanning,
  choosing,
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
    this.diagnostic,
    this.boardKind,
    this.boardId,
    this.connectionSession,
    this.candidates,
    this.data,
  });

  final String type;
  final ElectronicBoardConnectionState? connectionState;
  final String? message;
  final String? deviceName;
  final Map<String, String>? position;
  final int? batteryPercent;
  final bool? charging;
  final String? diagnostic;
  final BoardKind? boardKind;
  final String? boardId;
  final String? connectionSession;
  final List<BoardCandidate>? candidates;
  final List<int>? data;
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

class ChessnutPlatformTransport implements DiscoverableBoardTransport {
  ChessnutPlatformTransport._();

  static final ChessnutPlatformTransport instance =
      ChessnutPlatformTransport._();
  static const MethodChannel _methods = MethodChannel('maia_chess/chessnut');
  static const EventChannel _nativeEvents = EventChannel(
    'maia_chess/chessnut/events',
  );
  static final _rawEvents = _nativeEvents.receiveBroadcastStream();
  // Each listener owns its decoder history. Mapping a broadcast stream with a
  // shared stateful decoder would process each frame twice with two listeners,
  // consuming recovery evidence before the game screen could receive it.
  static final Stream<ElectronicBoardEvent> _events = Stream.multi((
    controller,
  ) {
    final decoder = ChessnutEventDecoder(
      detailed: appFlavor == 'dev' || appFlavor == 'preview',
    );
    final subscription = _rawEvents.listen(
      (value) => controller.addSync(decoder.decode(value)),
      onError: controller.addErrorSync,
      onDone: controller.closeSync,
    );
    controller.onCancel = subscription.cancel;
  }, isBroadcast: true);

  @override
  Stream<ElectronicBoardEvent> get events => _events;

  int _connectionGeneration = 0;

  @override
  Future<void> discoverBoards() {
    _connectionGeneration++;
    return _methods.invokeMethod<void>('discover');
  }

  @override
  Future<void> selectBoard(String id) {
    _connectionGeneration++;
    return _methods.invokeMethod<void>('selectBoard', {'candidateId': id});
  }

  @override
  Future<void> reconnectBoard(String? boardId) {
    _connectionGeneration++;
    return _methods.invokeMethod<void>('connect', {
      'mode': 'reconnect',
      'boardId': ?boardId,
    });
  }

  @override
  Future<void> startBoardGame(String player, String connectionSession) =>
      _sendCommand('startBoardGame', {
        'player': player,
        'connectionSession': connectionSession,
      });
  @override
  Future<void> movePiece(String uci, String connectionSession) => _sendCommand(
    'movePiece',
    {'uci': uci, 'connectionSession': connectionSession},
  );
  @override
  Future<void> confirmPosition(String connectionSession) =>
      _sendCommand('confirmPosition', {'connectionSession': connectionSession});
  @override
  Future<void> acknowledgeMove(bool accepted, String connectionSession) =>
      _sendCommand('acknowledgeMove', {
        'accepted': accepted,
        'connectionSession': connectionSession,
      });

  @override
  Future<void> connect() {
    _connectionGeneration++;
    return _methods.invokeMethod<void>('connect');
  }

  @override
  Future<void> disconnect() {
    _connectionGeneration++;
    return _methods.invokeMethod<void>('disconnect');
  }

  Future<void> _sendCommand(
    String method,
    Map<String, Object> arguments,
  ) async {
    final generation = _connectionGeneration;
    try {
      await _methods
          .invokeMethod<void>(method, arguments)
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      // A missing Android write callback otherwise wedges every later command.
      // Closing GATT also invalidates its late callbacks in the native bridge.
      if (generation == _connectionGeneration) {
        try {
          await disconnect().timeout(const Duration(seconds: 2));
        } catch (error, stackTrace) {
          unawaited(
            AppDiagnostics.record(
              'chessnut-timeout-disconnect',
              error,
              stackTrace,
            ),
          );
        }
      }
      throw PlatformException(
        code: 'write_timeout',
        message: 'Chessnut command timed out. Reconnect the board to continue.',
      );
    }
  }

  @override
  Future<void> setLeds(Iterable<String> squares) => _sendCommand('setLeds', {
    'command': ChessnutProtocol.encodeLedCommand(squares),
    'squares': [
      for (final s in squares) (8 - int.parse(s[1])) * 8 + s.codeUnitAt(0) - 97,
    ],
  });

  @override
  Future<void> beep({int frequencyHz = 1000, int durationMs = 200}) =>
      _sendCommand('beep', {
        'command': ChessnutProtocol.encodeBeepCommand(
          frequencyHz: frequencyHz,
          durationMs: durationMs,
        ),
      });
}

/// Bounded failure diagnostics, independent of the BLE transport for replay.
/// Successful positions are never logged except once after a decode failure.
class ChessnutEventDecoder {
  ChessnutEventDecoder({this.detailed = false, int Function()? elapsedMs})
    : _elapsedMs =
          elapsedMs ?? (Stopwatch()..start()).elapsedMillisecondsGetter;

  final bool detailed;
  final int Function() _elapsedMs;
  int? _lastValidMs;
  int? _firstFailureMs;
  int? _lastReportMs;
  int _failures = 0;
  bool _reconnectAfterFailure = false;

  static String _flag(Object? value) => value is bool ? '$value' : 'unknown';
  static String _age(int now, int? then) =>
      then == null ? 'unknown' : '${(now - then).clamp(0, 86400000)}';

  ElectronicBoardEvent decode(dynamic value) {
    if (value is! Map) {
      return const ElectronicBoardEvent(
        type: 'status',
        connectionState: ElectronicBoardConnectionState.error,
        message: 'Invalid Chessnut event.',
        diagnostic: 'errorSource=event-decode reason=invalidEvent',
      );
    }
    final event = value;
    final type = event['type'];
    final now = _elapsedMs();
    final boardKind = BoardKind.values
        .where((k) => k.name == event['boardKind'])
        .firstOrNull;
    final boardId = event['boardId'] is String
        ? event['boardId'] as String
        : null;
    final connectionSession = event['connectionSession'] is String
        ? event['connectionSession'] as String
        : null;
    if (type == 'newGame' || type == 'boardData' || type == 'candidates') {
      final raw = event['data'];
      final rows = event['candidates'];
      return ElectronicBoardEvent(
        type: type as String,
        boardKind: boardKind,
        boardId: boardId,
        connectionSession: connectionSession,
        data:
            raw is List &&
                raw.length <= 512 &&
                raw.every((v) => v is int && v >= 0 && v <= 255)
            ? raw.cast<int>()
            : null,
        candidates: rows is List && rows.length <= 32
            ? [
                for (final row in rows)
                  if (row is Map &&
                      row['id'] is String &&
                      row['name'] is String &&
                      BoardKind.values.any((k) => k.name == row['kind']))
                    BoardCandidate(
                      row['id'] as String,
                      (row['name'] as String).substring(
                        0,
                        min(64, (row['name'] as String).length),
                      ),
                      BoardKind.values.firstWhere((k) => k.name == row['kind']),
                    ),
              ]
            : null,
      );
    }
    if (type == 'position') {
      final rawData = event['data'];
      try {
        if (rawData is! List ||
            rawData.length > 512 ||
            rawData.any((item) => item is! int)) {
          throw const ChessnutPositionException(
            'Invalid Chessnut payload byte.',
          );
        }
        final bytes = rawData.cast<int>();
        final position = ChessnutProtocol.decodePosition(bytes);
        final recovered = _firstFailureMs != null;
        final diagnostic = recovered
            ? 'errorSource=position-decode recovery=valid-position '
                  'afterMs=${_age(now, _firstFailureMs)} failures=$_failures '
                  'afterReconnect=$_reconnectAfterFailure '
                  'nativeReady=${_flag(event['nativeReady'])} '
                  'gattPresent=${_flag(event['gattPresent'])}'
            : null;
        _lastValidMs = now;
        _firstFailureMs = null;
        _lastReportMs = null;
        _failures = 0;
        _reconnectAfterFailure = false;
        return ElectronicBoardEvent(
          type: 'position',
          boardKind: boardKind,
          boardId: boardId,
          connectionSession: connectionSession,
          position: position,
          // Parsing a position is not proof that GATT is ready. Only recover
          // application readiness when the native bridge confirms both flags.
          connectionState:
              recovered &&
                  event['nativeReady'] == true &&
                  event['gattPresent'] == true
              ? ElectronicBoardConnectionState.ready
              : null,
          diagnostic: diagnostic,
        );
      } on ChessnutPositionException catch (error) {
        _firstFailureMs ??= now;
        _failures = min(_failures + 1, 1000000);
        final report = _lastReportMs == null || now - _lastReportMs! >= 10000;
        if (report) _lastReportMs = now;
        final context = detailed ? error.diagnosticContext(rawData) : '';
        return ElectronicBoardEvent(
          type: 'status',
          connectionState: ElectronicBoardConnectionState.error,
          message: error.message,
          diagnostic: report
              ? 'errorSource=position-decode reason=${error.message} '
                    'payloadLength=${rawData is List ? rawData.length : 'unknown'} '
                    'nativeReady=${_flag(event['nativeReady'])} '
                    'gattPresent=${_flag(event['gattPresent'])} '
                    'lastValidAgoMs=${_age(now, _lastValidMs)} failures=$_failures'
                    '$context'
              : null,
        );
      }
    }
    if (type == 'battery') {
      final percent = event['percent'];
      return ElectronicBoardEvent(
        type: 'battery',
        boardKind: boardKind,
        boardId: boardId,
        connectionSession: connectionSession,
        batteryPercent: percent is int && percent >= 0 && percent <= 100
            ? percent
            : null,
        charging: event['charging'] is bool ? event['charging'] as bool : null,
      );
    }
    final rawState = event['state'];
    final state = ElectronicBoardConnectionState.values.firstWhere(
      (candidate) => candidate.name == rawState,
      orElse: () => ElectronicBoardConnectionState.error,
    );
    if (_firstFailureMs != null &&
        (state == ElectronicBoardConnectionState.scanning ||
            state == ElectronicBoardConnectionState.connecting)) {
      _reconnectAfterFailure = true;
    }
    return ElectronicBoardEvent(
      type: 'status',
      boardKind: boardKind,
      boardId: boardId,
      connectionSession: connectionSession,
      connectionState: state,
      message: event['message'] is String ? event['message'] as String : null,
      deviceName: event['deviceName'] is String
          ? event['deviceName'] as String
          : null,
      diagnostic: event['diagnostic'] is String
          ? event['diagnostic'] as String
          : null,
    );
  }
}

extension on Stopwatch {
  int elapsedMillisecondsGetter() => elapsedMilliseconds;
}

class ChessnutPositionException extends FormatException {
  const ChessnutPositionException(
    super.message, {
    this.byteOffset,
    this.nibble,
    this.code,
  });
  final int? byteOffset;
  final int? nibble;
  final int? code;

  String diagnosticContext(Object? data) {
    final offset = byteOffset;
    if (offset == null || data is! List || offset >= data.length) return '';
    final start = max(0, offset - 1);
    final end = min(data.length, offset + 2);
    final excerpt = data.sublist(start, end);
    if (excerpt.any((b) => b is! int || b < 0 || b > 255)) return '';
    return ' byteOffset=$offset nibble=${nibble ?? 'unknown'}'
        '${code == null ? '' : ' pieceCode=0x${code!.toRadixString(16)}'}'
        ' excerptOffset=$start excerpt=${excerpt.map((b) => (b as int).toRadixString(16).padLeft(2, '0')).join()}';
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
    final int headerBytes;
    if (notification.length == 32) {
      payload = notification;
      headerBytes = 0;
    } else if (notification.length >= 34 &&
        notification[0] == 0x01 &&
        notification[1] == 0x24) {
      payload = notification.sublist(2, 34);
      headerBytes = 2;
    } else {
      throw const ChessnutPositionException(
        'Expected a 32-byte Chessnut payload or board notification.',
      );
    }

    final pieces = <String, String>{};
    var index = 0;
    for (var rank = 8; rank >= 1; rank--) {
      for (var filePair = 0; filePair < 8; filePair += 2) {
        final byte = payload[index++];
        if (byte < 0 || byte > 255) {
          throw ChessnutPositionException(
            'Invalid Chessnut payload byte.',
            byteOffset: headerBytes + index - 1,
          );
        }
        final codes = [byte & 0x0f, byte >> 4];
        for (var offset = 0; offset < 2; offset++) {
          final piece = _pieceCodes[codes[offset]];
          if (piece == null) {
            throw ChessnutPositionException(
              'Unknown Chessnut piece code: 0x${codes[offset].toRadixString(16)}.',
              byteOffset: headerBytes + index - 1,
              nibble: offset,
              code: codes[offset],
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

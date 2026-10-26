part of '../main.dart';

/// One decoder/subscription per physical transport. A continuation borrows the
/// connection from the covered game, then transfers the same lease to its game.
/// Inactive owners cannot send commands or consume board input.
class BoardConnectionSession {
  BoardConnectionSession._(this.transport);
  static final _sessions = Expando<BoardConnectionSession>();
  static BoardConnectionSession forTransport(
    ElectronicBoardTransport transport,
  ) {
    if (transport is BoardConnectionLease) return transport.session;
    return _sessions[transport] ??= BoardConnectionSession._(transport);
  }

  final ElectronicBoardTransport transport;
  final Set<BoardConnectionLease> _leases = {};
  StreamSubscription<ElectronicBoardEvent>? _subscription;
  BoardConnectionLease? _owner;
  ElectronicBoardEvent? _status, _position, _battery, _candidates;
  final Set<String> _retired = {};
  Future<void> _commands = Future.value();
  int _commandEpoch = 0;

  BoardConnectionLease lease() {
    if (_leases.isEmpty) {
      // A newly opened screen must not inherit a disposed owner's command tail.
      _commandEpoch++;
      _commands = Future.value();
    }
    final lease = transport is DiscoverableBoardTransport
        ? _DiscoverableBoardLease._(this)
        : BoardConnectionLease._(this);
    _leases.add(lease);
    return lease;
  }

  Iterable<ElectronicBoardEvent> get snapshot sync* {
    if (_status case final status?) yield status;
    if (_battery case final battery?) yield battery;
    if (_position case final position?) yield position;
    if (_candidates case final candidates?) yield candidates;
  }

  void _listen() {
    _subscription ??= transport.events.listen(
      _receive,
      onError: (Object error, StackTrace stack) {
        _position = null;
        _status = ElectronicBoardEvent(
          type: 'status',
          connectionState: ElectronicBoardConnectionState.error,
          boardKind: _status?.boardKind,
          boardId: _status?.boardId,
          connectionSession: _status?.connectionSession,
          deviceName: _status?.deviceName,
        );
        _owner?._events.addError(error, stack);
      },
    );
  }

  void _receive(ElectronicBoardEvent event) {
    if (!BoardChannelPolicy.supports(
      appFlavor,
      event.boardKind ?? BoardKind.chessnut,
    )) {
      return;
    }
    final session = event.connectionSession;
    if (session != null && _retired.contains(session)) return;
    if (event.type != 'status' &&
        event.type != 'candidates' &&
        session != null &&
        session != _status?.connectionSession) {
      return;
    }
    if (event.type == 'status') {
      final previous = _status;
      final changed = session != null && session != previous?.connectionSession;
      if (changed ||
          event.connectionState ==
              ElectronicBoardConnectionState.disconnected) {
        // A new native connection must not wait for an old connection's ACK.
        _commandEpoch++;
        _commands = Future.value();
      }
      if (changed) {
        if (previous?.connectionSession case final old?) _retired.add(old);
        if (_retired.length > 16) _retired.remove(_retired.first);
        _position = null;
        _battery = null;
      }
      if (event.connectionState != ElectronicBoardConnectionState.ready) {
        _position = null;
      }
      _candidates = null;
      _status = ElectronicBoardEvent(
        type: 'status',
        connectionState: event.connectionState,
        deviceName: event.deviceName ?? (changed ? null : previous?.deviceName),
        boardKind: event.boardKind ?? previous?.boardKind,
        boardId: event.boardId ?? previous?.boardId,
        connectionSession: session ?? previous?.connectionSession,
        message: event.message,
        diagnostic: event.diagnostic,
      );
    } else if (event.type == 'position') {
      if (event.connectionState == ElectronicBoardConnectionState.ready &&
          _status?.connectionState == ElectronicBoardConnectionState.error) {
        _status = ElectronicBoardEvent(
          type: 'status',
          connectionState: ElectronicBoardConnectionState.ready,
          boardKind: _status?.boardKind,
          boardId: _status?.boardId,
          connectionSession: _status?.connectionSession,
          deviceName: _status?.deviceName,
        );
      }
      if (_status?.connectionState == ElectronicBoardConnectionState.ready ||
          event.connectionState == ElectronicBoardConnectionState.ready) {
        _position = event;
      }
    } else if (event.type == 'battery') {
      _battery = event;
    } else if (event.type == 'candidates') {
      _candidates = event;
    }
    _owner?._events.add(event);
  }

  void _activate(BoardConnectionLease lease) {
    if (lease._disposed || identical(_owner, lease)) return;
    // Keep in-flight writes ordered, but retire queued work from any prior
    // ownership period, even when cancellation later restores the same lease.
    _commandEpoch++;
    _listen();
    // Reactivating a covered lease must not create a cycle in the return chain.
    for (var cursor = _owner; cursor != null; cursor = cursor._previous) {
      if (identical(cursor._previous, lease)) {
        cursor._previous = lease._previous;
        break;
      }
    }
    lease._previous = _owner;
    final previous = _owner;
    _owner = lease;
    previous?.onSuspended?.call();
    for (final event in snapshot) {
      lease._events.add(event);
    }
  }

  Future<void> _command(
    BoardConnectionLease lease,
    Future<void> Function() operation,
  ) {
    final epoch = _commandEpoch;
    final run = _commands.then((_) async {
      if (!lease.isOwner || epoch != _commandEpoch) return;
      await operation().timeout(const Duration(seconds: 10));
    });
    _commands = run.catchError((Object _) {});
    return run;
  }

  Future<void> _release(
    BoardConnectionLease lease, {
    required bool disconnect,
    required bool restorePrevious,
  }) async {
    if (lease._disposed) return;
    if (lease.isOwner && disconnect) {
      try {
        await _command(lease, transport.disconnect);
      } catch (error, stack) {
        await AppDiagnostics.record('board-handoff-disconnect', error, stack);
      }
      if (lease.isOwner) {
        _position = null;
        _battery = null;
        _candidates = null;
        _status = const ElectronicBoardEvent(
          type: 'status',
          connectionState: ElectronicBoardConnectionState.disconnected,
        );
      }
    }
    if (lease.isOwner) {
      _commandEpoch++;
      _owner = null;
      var previous = lease._previous;
      while (previous != null && previous._disposed) {
        previous = previous._previous;
      }
      if (restorePrevious && previous != null) {
        _owner = previous;
        final restored = previous;
        // Cancellation can occur during route disposal, when setState is locked.
        scheduleMicrotask(() {
          if (!restored.isOwner || restored._events.isClosed) return;
          for (final event in snapshot) {
            restored._events.add(event);
          }
        });
      }
    }
    lease._disposed = true;
    _leases.remove(lease);
    await lease._events.close();
    if (_leases.isEmpty) {
      final subscription = _subscription;
      _subscription = null;
      await subscription?.cancel();
      if (_leases.isEmpty) {
        _status = _position = _battery = _candidates = null;
        _retired.clear();
      }
    }
  }
}

class BoardConnectionLease implements ElectronicBoardTransport {
  BoardConnectionLease._(this.session);
  final BoardConnectionSession session;
  late final StreamController<ElectronicBoardEvent> _events =
      StreamController<ElectronicBoardEvent>.broadcast(
        sync: true,
        onListen: () {
          if (isOwner) {
            scheduleMicrotask(() {
              if (!isOwner || _events.isClosed) return;
              for (final event in session.snapshot) {
                _events.add(event);
              }
            });
          }
        },
      );
  BoardConnectionLease? _previous;
  bool _disposed = false;
  VoidCallback? onSuspended;
  bool get isOwner => !_disposed && identical(session._owner, this);
  ElectronicBoardEvent? get status => session._status;
  bool get ready =>
      status?.connectionState == ElectronicBoardConnectionState.ready;
  ElectronicBoardTransport get rawTransport => session.transport;
  void activate() => session._activate(this);
  Future<void> release({
    bool disconnect = false,
    bool restorePrevious = false,
  }) => session._release(
    this,
    disconnect: disconnect,
    restorePrevious: restorePrevious,
  );

  @override
  Stream<ElectronicBoardEvent> get events => _events.stream;

  Future<void> command(Future<void> Function() operation) =>
      session._command(this, operation);
  @override
  Future<void> connect() {
    activate();
    return command(rawTransport.connect);
  }

  @override
  Future<void> disconnect() => command(rawTransport.disconnect);
  @override
  Future<void> setLeds(Iterable<String> squares) =>
      command(() => rawTransport.setLeds(squares));
  @override
  Future<void> beep({int frequencyHz = 1000, int durationMs = 200}) async {
    // Sound acknowledgements must not delay position LEDs or disconnection.
    // Native transport still orders its writes; only LED/handoff commands need
    // the extra cross-owner ordering maintained by this session.
    if (!isOwner) return;
    await rawTransport
        .beep(frequencyHz: frequencyHz, durationMs: durationMs)
        .timeout(const Duration(seconds: 10));
  }
}

class _DiscoverableBoardLease extends BoardConnectionLease
    implements DiscoverableBoardTransport {
  _DiscoverableBoardLease._(super.session) : super._();
  DiscoverableBoardTransport get _raw =>
      rawTransport as DiscoverableBoardTransport;
  @override
  Future<void> discoverBoards() {
    activate();
    return command(_raw.discoverBoards);
  }

  @override
  Future<void> selectBoard(String id) => command(() => _raw.selectBoard(id));
  @override
  Future<void> reconnectBoard(String? boardId) {
    activate();
    return command(() => _raw.reconnectBoard(boardId));
  }

  @override
  Future<void> startBoardGame(String player, String connectionSession) =>
      command(() => _raw.startBoardGame(player, connectionSession));
  @override
  Future<void> movePiece(String uci, String connectionSession) =>
      command(() => _raw.movePiece(uci, connectionSession));
  @override
  Future<void> acknowledgeMove(bool accepted, String connectionSession) =>
      command(() => _raw.acknowledgeMove(accepted, connectionSession));
  @override
  Future<void> confirmPosition(String connectionSession) =>
      command(() => _raw.confirmPosition(connectionSession));
}

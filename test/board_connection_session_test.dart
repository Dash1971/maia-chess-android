import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

class _SessionBoard implements DiscoverableBoardTransport {
  final _source = StreamController<ElectronicBoardEvent>.broadcast(sync: true);
  int listeners = 0;
  int activeListeners = 0;
  int cancellations = 0;
  final commands = <String>[];
  List<String> displayedLeds = [];
  Completer<void>? ledGate;
  Completer<void>? beepGate;
  final ledEntered = Completer<void>();

  late final _events = Stream<ElectronicBoardEvent>.multi((controller) {
    listeners++;
    activeListeners++;
    final subscription = _source.stream.listen(
      controller.addSync,
      onError: controller.addErrorSync,
      onDone: controller.closeSync,
    );
    controller.onCancel = () async {
      activeListeners--;
      cancellations++;
      await subscription.cancel();
    };
  }, isBroadcast: true);

  @override
  Stream<ElectronicBoardEvent> get events => _events;

  void emit(ElectronicBoardEvent event) => _source.add(event);

  void fail(Object error) => _source.addError(error, StackTrace.current);

  void ready(String session) => emit(
    ElectronicBoardEvent(
      type: 'status',
      connectionState: ElectronicBoardConnectionState.ready,
      boardKind: BoardKind.chessnut,
      boardId: 'board-$session',
      connectionSession: session,
      deviceName: 'Chessnut Air',
    ),
  );

  void position(String session, Map<String, String> pieces) => emit(
    ElectronicBoardEvent(
      type: 'position',
      connectionSession: session,
      position: pieces,
    ),
  );

  void battery(String session, int percent) => emit(
    ElectronicBoardEvent(
      type: 'battery',
      connectionSession: session,
      batteryPercent: percent,
    ),
  );

  @override
  Future<void> connect() async => commands.add('connect');
  @override
  Future<void> disconnect() async => commands.add('disconnect');
  @override
  Future<void> discoverBoards() async => commands.add('discover');
  @override
  Future<void> selectBoard(String id) async => commands.add('select:$id');
  @override
  Future<void> reconnectBoard(String? boardId) async =>
      commands.add('reconnect:$boardId');
  @override
  Future<void> startBoardGame(String player, String connectionSession) async =>
      commands.add('start:$player:$connectionSession');
  @override
  Future<void> movePiece(String uci, String connectionSession) async =>
      commands.add('move:$uci:$connectionSession');
  @override
  Future<void> acknowledgeMove(bool accepted, String connectionSession) async =>
      commands.add('ack:$accepted:$connectionSession');
  @override
  Future<void> confirmPosition(String connectionSession) async =>
      commands.add('confirm:$connectionSession');
  @override
  Future<void> beep({int frequencyHz = 1000, int durationMs = 200}) async {
    commands.add('beep:$frequencyHz:$durationMs');
    await beepGate?.future;
  }

  @override
  Future<void> setLeds(Iterable<String> squares) async {
    final requested = squares.toList();
    commands.add('led:${requested.join(',')}');
    if (!ledEntered.isCompleted) ledEntered.complete();
    final gate = ledGate;
    ledGate = null;
    if (gate != null) await gate.future;
    displayedLeds = requested;
  }

  Future<void> close() => _source.close();
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  group('Board connection ownership', () {
    late _SessionBoard board;
    late BoardConnectionSession session;
    late List<BoardConnectionLease> leases;
    late List<Completer<void>> gates;
    late List<StreamSubscription<ElectronicBoardEvent>> subscriptions;

    BoardConnectionLease lease() {
      final result = session.lease();
      leases.add(result);
      return result;
    }

    List<ElectronicBoardEvent> observe(
      BoardConnectionLease owner, {
      List<Object>? errors,
    }) {
      final received = <ElectronicBoardEvent>[];
      subscriptions.add(
        owner.events.listen(received.add, onError: errors?.add),
      );
      return received;
    }

    setUp(() {
      board = _SessionBoard();
      session = BoardConnectionSession.forTransport(board);
      leases = [];
      gates = [];
      subscriptions = [];
    });

    tearDown(() async {
      for (final gate in gates) {
        if (!gate.isCompleted) gate.complete();
      }
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      for (final owner in leases.reversed) {
        await owner.release();
      }
      await board.close();
    });

    test(
      'all leases share one underlying listener until the last release',
      () async {
        final first = lease();
        final second = lease();
        observe(first);
        observe(second);
        first.activate();
        second.activate();
        await _flush();

        expect(BoardConnectionSession.forTransport(board), same(session));
        expect(BoardConnectionSession.forTransport(first), same(session));
        expect(board.listeners, 1);
        expect(board.activeListeners, 1);
        await second.release();
        expect(board.cancellations, 0);
        await first.release();
        expect(board.activeListeners, 0);
        expect(board.cancellations, 1);
      },
    );

    test(
      'handoff replays connection and position only to the new owner',
      () async {
        final home = lease();
        final homeEvents = observe(home);
        var suspended = 0;
        home.onSuspended = () => suspended++;
        home.activate();
        board.ready('current');
        board.battery('current', 81);
        board.position('current', {'e1': 'K', 'e8': 'k'});
        await _flush();
        homeEvents.clear();

        final continuation = lease();
        final continuedEvents = observe(continuation);
        continuation.activate();
        await _flush();
        expect(home.isOwner, isFalse);
        expect(continuation.isOwner, isTrue);
        expect(suspended, 1);
        expect(continuedEvents.map((event) => event.type), [
          'status',
          'battery',
          'position',
        ]);
        expect(continuedEvents.first.boardId, 'board-current');
        expect(continuedEvents.first.connectionSession, 'current');
        expect(continuedEvents.first.deviceName, 'Chessnut Air');
        expect(continuedEvents.last.position, {'e1': 'K', 'e8': 'k'});
        expect(homeEvents, isEmpty);
        expect(board.commands, isEmpty);

        await subscriptions.last.cancel();
        final lateObserver = observe(continuation);
        await _flush();
        expect(lateObserver.map((event) => event.type), [
          'status',
          'battery',
          'position',
        ]);
        expect(board.listeners, 1);
        board.position('current', {'d1': 'K', 'e8': 'k'});
        await _flush();
        expect(homeEvents, isEmpty);
        expect(lateObserver.last.position, {'d1': 'K', 'e8': 'k'});
      },
    );

    test('inactive owners cannot send physical-board commands', () async {
      final home = lease();
      home.activate();
      final continuation = lease();
      continuation.activate();
      final inactive = home as DiscoverableBoardTransport;

      await Future.wait([
        home.setLeds(['a1']),
        home.beep(),
        home.disconnect(),
        inactive.selectBoard('other'),
        inactive.startBoardGame('white', 'current'),
        inactive.movePiece('e2e4', 'current'),
        inactive.acknowledgeMove(true, 'current'),
        inactive.confirmPosition('current'),
      ]);
      expect(board.commands, isEmpty);
      await continuation.setLeds(['e4']);
      expect(board.commands, ['led:e4']);
      expect(board.displayedLeds, ['e4']);
    });

    test(
      'cancelled borrowing restores the previous owner and latest position',
      () async {
        final home = lease();
        final homeEvents = observe(home);
        home.activate();
        board.ready('current');
        board.position('current', {'e1': 'K'});
        await _flush();
        final dialog = lease();
        observe(dialog);
        dialog.activate();
        homeEvents.clear();
        board.position('current', {'d1': 'K'});
        await _flush();
        expect(homeEvents, isEmpty);

        await dialog.release(restorePrevious: true);
        await _flush();
        expect(home.isOwner, isTrue);
        expect(dialog.isOwner, isFalse);
        expect(homeEvents.map((event) => event.type), ['status', 'position']);
        expect(homeEvents.last.position, {'d1': 'K'});
        expect(board.commands, isEmpty);
        await home.setLeds(['d1']);
        expect(board.commands, ['led:d1']);
      },
    );

    test('sound acknowledgement cannot block LEDs or disconnect', () async {
      final owner = lease();
      owner.activate();
      final gate = Completer<void>();
      gates.add(gate);
      board.beepGate = gate;
      final sound = owner.beep();
      await owner.setLeds(['e4']);
      await owner.disconnect();
      expect(board.commands, ['beep:1000:200', 'led:e4', 'disconnect']);
      gate.complete();
      await sound;
    });

    test(
      'late old LED completion precedes the new owners final guidance',
      () async {
        final home = lease();
        home.activate();
        final gate = Completer<void>();
        gates.add(gate);
        board.ledGate = gate;
        final oldWrite = home.setLeds(['a1']);
        await board.ledEntered.future;
        final skippedWrite = home.setLeds(['b1']);
        final continuation = lease();
        continuation.activate();
        final finalWrite = continuation.setLeds(['e4']);
        await _flush();
        expect(board.commands, ['led:a1']);
        expect(board.displayedLeds, isEmpty);

        gate.complete();
        await Future.wait([oldWrite, skippedWrite, finalWrite]);
        expect(board.commands, ['led:a1', 'led:e4']);
        expect(board.displayedLeds, ['e4']);
      },
    );

    test(
      'cancelled borrowing invalidates the restored owners old queued commands',
      () async {
        final home = lease();
        home.activate();
        board.ready('current');
        final gate = Completer<void>();
        gates.add(gate);
        board.ledGate = gate;
        final inFlight = home.setLeds(['a1']);
        await board.ledEntered.future;
        final obsolete = home.setLeds(['b1']);
        final dialog = lease();
        dialog.activate();
        await dialog.release(restorePrevious: true);
        expect(home.isOwner, isTrue);
        final current = home.setLeds(['e4']);
        gate.complete();
        await Future.wait([inFlight, obsolete, current]);
        expect(board.commands, ['led:a1', 'led:e4']);
        expect(board.displayedLeds, ['e4']);
      },
    );

    test(
      'obsolete connection sessions cannot overwrite or replay current state',
      () async {
        final owner = lease();
        final events = observe(owner);
        owner.activate();
        board.ready('old');
        board.position('old', {'a1': 'K'});
        board.battery('old', 20);
        board.ready('current');
        await _flush();
        expect(session.snapshot.map((event) => event.type), ['status']);
        events.clear();

        board.ready('old');
        board.position('old', {'b1': 'K'});
        board.battery('old', 90);
        board.position('unknown', {'c1': 'K'});
        await _flush();
        expect(events, isEmpty);
        expect(owner.status?.connectionSession, 'current');
        expect(session.snapshot.map((event) => event.type), ['status']);
        board.position('current', {'e1': 'K'});
        await _flush();
        expect(events.single.position, {'e1': 'K'});
      },
    );

    test(
      'stream errors preserve identity and valid recovery replays ready',
      () async {
        final owner = lease();
        final errors = <Object>[];
        final events = observe(owner, errors: errors);
        owner.activate();
        board.ready('current');
        board.position('current', {'a1': 'K'});
        await _flush();
        final failure = StateError('temporary event-stream failure');
        board.fail(failure);
        await _flush();
        expect(errors, [same(failure)]);
        expect(owner.ready, isFalse);
        expect(owner.status?.connectionSession, 'current');
        expect(owner.status?.boardId, 'board-current');
        expect(owner.status?.boardKind, BoardKind.chessnut);
        expect(owner.status?.deviceName, 'Chessnut Air');
        expect(session.snapshot.map((event) => event.type), ['status']);
        events.clear();

        board.emit(
          const ElectronicBoardEvent(
            type: 'position',
            connectionSession: 'current',
            connectionState: ElectronicBoardConnectionState.ready,
            position: {'e1': 'K'},
          ),
        );
        await _flush();
        expect(events.single.position, {'e1': 'K'});
        expect(owner.ready, isTrue);
        expect(owner.status?.connectionSession, 'current');
        final borrower = lease();
        final replayed = observe(borrower);
        borrower.activate();
        await _flush();
        expect(replayed.map((event) => event.type), ['status', 'position']);
        expect(
          replayed.first.connectionState,
          ElectronicBoardConnectionState.ready,
        );
        expect(replayed.first.boardId, 'board-current');
        expect(replayed.last.position, {'e1': 'K'});
        expect(board.commands, isEmpty);
      },
    );

    test(
      'reactivating a covered owner keeps the previous chain acyclic',
      () async {
        final first = lease();
        final second = lease();
        final third = lease();
        observe(first);
        observe(second);
        observe(third);
        first.activate();
        second.activate();
        third.activate();
        first.activate();
        expect(first.isOwner, isTrue);
        expect(second.isOwner, isFalse);
        expect(third.isOwner, isFalse);

        await first.release(restorePrevious: true);
        expect(third.isOwner, isTrue);
        await third.release(restorePrevious: true);
        expect(second.isOwner, isTrue);
        await second.release(restorePrevious: true);
        expect(first.isOwner, isFalse);
        expect(second.isOwner, isFalse);
        expect(third.isOwner, isFalse);
        expect(board.activeListeners, 0);
        expect(board.cancellations, 1);
      },
    );

    for (final transition in ['disconnected', 'new session']) {
      test('$transition frees commands from an obsolete pending ACK', () async {
        final owner = lease();
        owner.activate();
        board.ready('old');
        final gate = Completer<void>();
        gates.add(gate);
        board.ledGate = gate;
        final pendingWrite = owner.setLeds(['a1']);
        await board.ledEntered.future;
        final obsoleteQueuedCommand = owner.setLeds(['b1']);
        if (transition == 'disconnected') {
          board.emit(
            const ElectronicBoardEvent(
              type: 'status',
              connectionState: ElectronicBoardConnectionState.disconnected,
              connectionSession: 'old',
            ),
          );
        } else {
          board.ready('new');
        }
        await _flush();

        // This must complete while the old transport write is still blocked.
        await owner.setLeds(['e4']).timeout(const Duration(seconds: 1));
        expect(gate.isCompleted, isFalse);
        expect(board.commands, ['led:a1', 'led:e4']);
        gate.complete();
        await Future.wait([pendingWrite, obsoleteQueuedCommand]);
        expect(board.commands, ['led:a1', 'led:e4']);
      });
    }

    test(
      'fresh owner does not inherit a disposed sessions command tail',
      () async {
        final oldOwner = lease();
        oldOwner.activate();
        final gate = Completer<void>();
        gates.add(gate);
        board.ledGate = gate;
        final pending = oldOwner.setLeds(['a1']);
        await board.ledEntered.future;
        await oldOwner.release();
        final fresh = lease();
        fresh.activate();
        await fresh.setLeds(['e4']).timeout(const Duration(seconds: 1));
        expect(gate.isCompleted, isFalse);
        expect(board.commands, ['led:a1', 'led:e4']);
        gate.complete();
        await pending;
      },
    );

    test('release does not reactivate a covered owner by default', () async {
      final home = lease();
      final homeEvents = observe(home);
      home.activate();
      final continuation = lease();
      continuation.activate();
      await continuation.release();
      expect(home.isOwner, isFalse);
      expect(continuation.isOwner, isFalse);
      board.ready('current');
      board.position('current', {'e1': 'K'});
      await _flush();
      expect(homeEvents, isEmpty);
      await home.setLeds(['a1']);
      expect(board.commands, isEmpty);
      expect(board.activeListeners, 1);
    });
  });
}

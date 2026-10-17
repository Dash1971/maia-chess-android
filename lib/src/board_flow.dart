part of '../main.dart';

enum BoardProblem { locked, motor, generic }

extension _ElectronicBoardFlow on _GamePageState {
  // The tested connection flow is shared by every channel. BoardChannelPolicy
  // independently restricts prototype adapters to Dev.
  bool get _genericBoards => _chessnut is DiscoverableBoardTransport;
  bool get _legacyChessnutSelection =>
      _chessnutGameActive &&
      _boardKind == BoardKind.chessnut &&
      _selectedBoardId == null;

  DiscoverableBoardTransport? get _discovery =>
      _genericBoards && _chessnut is DiscoverableBoardTransport
      ? _chessnut
      : null;

  String get _boardDisplayName => electronicBoardDisplayName(
    l10n(context),
    _boardNameKind ??
        (_chessnutGameActive || !_genericBoards ? _boardKind : null),
    _chessnutDeviceName,
  );

  String _boardText(_PlayMessage message) {
    final t = l10n(context);
    if (message == _PlayMessage.chessnutReady && _chessnutReady) {
      return t.namedBoardConnected(_boardDisplayName);
    }
    if (message == _PlayMessage.chessnutIsDisconnected) {
      return t.namedBoardDisconnected(_boardDisplayName);
    }
    if (!_genericBoards) return message.text(context);
    if (_chessnutState == ElectronicBoardConnectionState.error &&
        _boardProblem != null) {
      return switch (_boardProblem!) {
        BoardProblem.locked => t.boardLockedPegasus,
        BoardProblem.motor => t.boardMotorRecovery,
        BoardProblem.generic => t.boardConnectionError,
      };
    }
    if (_chessnutState == ElectronicBoardConnectionState.choosing) {
      return t.boardWaitingForSelection;
    }
    return switch (message) {
      _PlayMessage.searchingChessnut => t.boardSearching,
      _PlayMessage.connectingChessnut => t.boardConnecting,
      _PlayMessage.chessnutConnectionError ||
      _PlayMessage.couldNotConnectChessnut => t.boardConnectionError,
      _PlayMessage.chessnutStartingPosition => t.boardStartingPosition,
      _PlayMessage.reconnectChessnut ||
      _PlayMessage.connectChessnutFirst => t.boardReconnect,
      _PlayMessage.yourMoveChessnut ||
      _PlayMessage.takebackCompleteYourMove => t.yourMove,
      _PlayMessage.completeMaiaLitMove ||
      _PlayMessage.makeMaiaLitMove ||
      _PlayMessage.completeYourChessnutMove => t.boardPhysicalMove,
      _PlayMessage.restoreLitSquares => t.boardResetPhysical,
      _ => message.text(context),
    };
  }

  void _cancelBoardInteractions() {
    _boardSettleTimer?.cancel();
    _boardInteractionEpoch++;
    _disarmBoardReset();
    final dialog = _boardDialogContext;
    _boardDialogContext = null;
    if (dialog != null && dialog.mounted) {
      final route = ModalRoute.of(dialog);
      if (route != null && route.isCurrent) {
        Navigator.of(dialog).pop();
      } else if (route != null) {
        Navigator.of(dialog).removeRoute(route);
      }
    }
  }

  void _resetBoardProtocol() {
    _cancelBoardInteractions();
    _pegasusDecoder.reset();
    _occupancyResolver.reset();
    _physicalOccupancy = null;
    _squareOffDecoder.reset();
    _deferredSquareOffMove = null;
    _boardSetupConfirmed = false;
    _boardProblem = null;
  }

  Future<void> _chooseOtherBoard() async {
    final transport = _discovery;
    if (transport == null || _started) return;
    _resetBoardProtocol();
    if (_boardConnectionSession != null) {
      _retiredBoardSessions.add(_boardConnectionSession!);
    }
    _boardConnectionSession = null;
    _chessnutPosition = null;
    _chessnutDeviceName = null;
    _boardNameKind = null;
    _chessnutLeds.invalidate();
    _updateBoardUi(() {
      _chessnutBatteryPercent = null;
      _chessnutState = ElectronicBoardConnectionState.scanning;
      _chessnutMessage = _PlayMessage.searchingChessnut;
    });
    final epoch = _boardInteractionEpoch;
    try {
      await transport.discoverBoards();
    } catch (error, stack) {
      _boardFailure(error, stack, epoch: epoch);
    }
  }

  Future<void> _showBoardCandidates(List<BoardCandidate> candidates) async {
    candidates = candidates
        .where(
          (candidate) =>
              BoardChannelPolicy.supports(appFlavor, candidate.kind) &&
              (!_legacyChessnutSelection ||
                  candidate.kind == BoardKind.chessnut),
        )
        .toList();
    if (!_feedbackForeground ||
        !_feedbackRouteVisible ||
        (_started && !_legacyChessnutSelection) ||
        !_useChessnutGo ||
        candidates.isEmpty ||
        _discovery == null) {
      return;
    }
    _cancelBoardInteractions();
    final epoch = _boardInteractionEpoch;
    final selected = await showDialog<String>(
      context: context,
      builder: (dialog) {
        _boardDialogContext = dialog;
        return AlertDialog(
          scrollable: true,
          title: Text(l10n(dialog).chooseBoard),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final candidate in candidates)
                  ListTile(
                    key: ValueKey('board-candidate-${candidate.id}'),
                    leading: const Icon(Icons.bluetooth),
                    title: Text(candidate.name),
                    subtitle: Text(switch (candidate.kind) {
                      BoardKind.chessnut => 'Chessnut',
                      BoardKind.pegasus => 'DGT Pegasus',
                      BoardKind.squareOff => 'Square Off Grand Kingdom',
                    }),
                    onTap: () => Navigator.pop(dialog, candidate.id),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: Text(l10n(dialog).cancel),
            ),
          ],
        );
      },
    );
    if (epoch != _boardInteractionEpoch ||
        !mounted ||
        !_useChessnutGo ||
        (_started && !_legacyChessnutSelection)) {
      return;
    }
    _boardDialogContext = null;
    if (selected == null) {
      await _disconnectChessnut();
      return;
    }
    try {
      await _discovery!.selectBoard(selected);
    } catch (error, stack) {
      _boardFailure(error, stack, epoch: epoch);
    }
  }

  void _boardFailure(
    Object error,
    StackTrace stack, {
    int? epoch,
    String? session,
  }) {
    if (!mounted ||
        (epoch != null && epoch != _boardInteractionEpoch) ||
        (session != null && session != _boardConnectionSession)) {
      return;
    }
    _cancelBoardInteractions();
    _chessnutLeds.invalidate();
    _chessnutPosition = null;
    _queuedChessnutPosition = null;
    _squareOffDecoder.reset();
    _pegasusDecoder.reset();
    _boardProblem = error.toString().toLowerCase().contains('locked')
        ? BoardProblem.locked
        : _boardKind == BoardKind.squareOff
        ? BoardProblem.motor
        : BoardProblem.generic;
    _updateBoardUi(() {
      _chessnutState = ElectronicBoardConnectionState.error;
      _chessnutMessage = _PlayMessage.chessnutConnectionError;
    });
    unawaited(AppDiagnostics.record('electronic-board', error, stack));
  }

  void _receiveBoardData(ElectronicBoardEvent event) {
    if (!_genericBoards ||
        event.connectionSession == null ||
        event.connectionSession != _boardConnectionSession ||
        event.boardKind != _boardKind) {
      return;
    }
    try {
      final bytes = event.data;
      if (bytes == null) throw const FormatException('Invalid board event');
      if (_boardKind == BoardKind.pegasus) {
        for (final occupied in _pegasusDecoder.add(bytes)) {
          _physicalOccupancy = occupied;
          _occupancyResolver.observe(_game, occupied);
          _boardSettleTimer?.cancel();
          final epoch = _boardInteractionEpoch;
          _boardSettleTimer = Timer(const Duration(milliseconds: 350), () {
            if (mounted && epoch == _boardInteractionEpoch && _chessnutReady) {
              unawaited(_applyOccupancy(occupied));
            }
          });
        }
      } else if (_boardKind == BoardKind.squareOff) {
        final uci = _squareOffDecoder.add(bytes);
        if (uci != null) unawaited(_receiveSquareOffMove(uci));
      }
    } catch (error, stack) {
      _boardFailure(error, stack);
    }
  }

  Future<String?> _confirmBoardMove(List<String> candidates) async {
    if (!_feedbackForeground ||
        !_feedbackRouteVisible ||
        _boardDialogContext != null ||
        candidates.isEmpty) {
      return null;
    }
    final fen = _game.fen;
    final epoch = _boardInteractionEpoch;
    final selected = await showDialog<String>(
      context: context,
      builder: (dialog) {
        _boardDialogContext = dialog;
        return AlertDialog(
          scrollable: true,
          title: Text(l10n(dialog).boardChooseMove),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n(dialog).boardAmbiguousMove),
                  for (final uci in candidates)
                    ListTile(
                      title: Text(uci),
                      onTap: () => Navigator.pop(dialog, uci),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: Text(l10n(dialog).cancel),
            ),
          ],
        );
      },
    );
    if (!mounted ||
        epoch != _boardInteractionEpoch ||
        fen != _game.fen ||
        !_chessnutReady) {
      return null;
    }
    _boardDialogContext = null;
    return selected;
  }

  Future<void> _applyOccupancy(Set<String> occupied) async {
    if (!_useChessnutGo ||
        !_chessnutReady ||
        _boardKind != BoardKind.pegasus ||
        !_feedbackForeground ||
        !_feedbackRouteVisible) {
      return;
    }
    final expected = ChessnutProtocol.pieceMapFromFen(
      _started ? _game.fen : chess.Chess.DEFAULT_POSITION,
    );
    final matches =
        occupied.length == expected.length &&
        occupied.containsAll(expected.keys);
    final pending = _pendingPhysicalMaiaMove;
    if (matches && pending != null && _positionHistory.length > 1) {
      final before = chess.Chess.fromFEN(
        _positionHistory[_positionHistory.length - 2],
      );
      final needsPhysicalConfirmation =
          pending.length == 5 ||
          (before.get(pending.substring(2, 4)) != null &&
              !_occupancyResolver.lifted.contains(pending.substring(2, 4)));
      if (needsPhysicalConfirmation) {
        final epoch = _boardInteractionEpoch;
        final confirmed = await _confirmBoardMove([pending]);
        if (confirmed == null ||
            !mounted ||
            epoch != _boardInteractionEpoch ||
            _pendingPhysicalMaiaMove != pending ||
            _physicalOccupancy == null ||
            !setEquals(_physicalOccupancy!, occupied)) {
          return;
        }
      }
    }
    if (!_started ||
        _pendingPhysicalMaiaMove != null ||
        _chessnutTakebackRestoreActive ||
        !_isPlayerTurn ||
        matches) {
      final position = {
        for (final square in occupied) square: expected[square] ?? '?',
      };
      _updateBoardUi(() => _chessnutPosition = position);
      _queueChessnutPosition(position);
      return;
    }
    if (_engineThinking ||
        _physicalMoveInProgress ||
        _clockPaused ||
        _boardDialogContext != null) {
      return;
    }
    final candidates = _occupancyResolver.candidates(_game, occupied);
    if (candidates.isEmpty) {
      await _setChessnutLeds(const []);
      return;
    }
    final fen = _game.fen;
    final epoch = _boardInteractionEpoch;
    final chosen = _occupancyResolver.needsConfirmation(_game, candidates)
        ? await _confirmBoardMove(candidates)
        : candidates.single;
    if (chosen == null ||
        !mounted ||
        fen != _game.fen ||
        epoch != _boardInteractionEpoch ||
        _physicalOccupancy == null ||
        !setEquals(_physicalOccupancy!, occupied)) {
      return;
    }
    final next = chess.Chess.fromFEN(fen);
    if (!next.move({
      'from': chosen.substring(0, 2),
      'to': chosen.substring(2, 4),
      if (chosen.length == 5) 'promotion': chosen[4],
    })) {
      return;
    }
    final position = ChessnutProtocol.pieceMapFromFen(next.fen);
    _updateBoardUi(() => _chessnutPosition = position);
    _queueChessnutPosition(position);
    _occupancyResolver.reset();
  }

  Future<void> _receiveSquareOffMove(
    String prefix, {
    bool requireConfirmation = false,
  }) async {
    if (!_feedbackForeground || !_feedbackRouteVisible) {
      if (_deferredSquareOffMove == null || _deferredSquareOffMove == prefix) {
        _deferredSquareOffMove = prefix;
      } else {
        _boardFailure(
          StateError('Ambiguous deferred board input'),
          StackTrace.current,
        );
      }
      return;
    }
    final transport = _discovery;
    final session = _boardConnectionSession;
    if (transport == null ||
        session == null ||
        !_started ||
        !_chessnutGameActive ||
        !_chessnutReady ||
        !_isPlayerTurn ||
        _engineThinking ||
        _startingGame ||
        _physicalMoveInProgress ||
        _clockPaused) {
      return;
    }
    final choices = _game
        .moves({'asObjects': true})
        .cast<chess.Move>()
        .map(MaiaEncoding.uci)
        .where((u) => u.startsWith(prefix))
        .toList();
    final epoch = _boardInteractionEpoch;
    if (choices.isEmpty) {
      try {
        await transport.acknowledgeMove(false, session);
      } catch (e, s) {
        _boardFailure(e, s, epoch: epoch, session: session);
      }
      return;
    }
    final fen = _game.fen;
    final selected = choices.length == 1 && !requireConfirmation
        ? choices.single
        : await _confirmBoardMove(choices);
    if (selected == null ||
        !mounted ||
        fen != _game.fen ||
        epoch != _boardInteractionEpoch ||
        session != _boardConnectionSession) {
      return;
    }
    final sourceGame = _game;
    _physicalMoveInProgress = true;
    try {
      await transport.acknowledgeMove(true, session);
      if (!mounted ||
          !identical(sourceGame, _game) ||
          fen != _game.fen ||
          session != _boardConnectionSession ||
          !_chessnutGameActive) {
        return;
      }
      if (epoch != _boardInteractionEpoch || !_gameCanRun) {
        _boardFailure(
          StateError('Motor input acknowledgement interrupted'),
          StackTrace.current,
          session: session,
        );
        return;
      }
      _pendingPhysicalMaiaMove = null;
      await _commitHumanMove(selected, fromChessnut: true);
      _chessnutPosition = ChessnutProtocol.pieceMapFromFen(_game.fen);
    } catch (e, s) {
      if (mounted &&
          identical(sourceGame, _game) &&
          fen == _game.fen &&
          _chessnutGameActive) {
        _boardFailure(e, s, session: session);
      }
    } finally {
      if (identical(sourceGame, _game) && session == _boardConnectionSession) {
        _physicalMoveInProgress = false;
      }
    }
  }

  Future<bool> _startSquareOffGame() async {
    if (!_chessnutGameActive || _boardKind != BoardKind.squareOff) return true;
    final session = _boardConnectionSession;
    if (session == null || _discovery == null || !_boardSetupConfirmed) {
      return false;
    }
    final generation = _gameGeneration;
    final epoch = _boardInteractionEpoch;
    try {
      await _discovery!.startBoardGame(
        _playerIsWhite ? 'white' : 'black',
        session,
      );
      if (!mounted ||
          session != _boardConnectionSession ||
          generation != _gameGeneration ||
          !_chessnutGameActive) {
        return false;
      }
      if (epoch != _boardInteractionEpoch || !_gameCanRun) {
        _boardFailure(
          StateError('Motor game initialization interrupted'),
          StackTrace.current,
          session: session,
        );
        return false;
      }
      return _started && _chessnutReady;
    } catch (e, s) {
      if (mounted && generation == _gameGeneration && _chessnutGameActive) {
        _boardFailure(e, s, session: session);
      }
      return false;
    }
  }

  Future<void> _sendMotorMove(String uci) async {
    final sourceGame = _game;
    final session = _boardConnectionSession;
    final epoch = _boardInteractionEpoch;
    if (session == null || _discovery == null) return;
    // Checkpoints precede physical side effects. An uncertain command is never
    // resent automatically after reconnect/restart.
    await _saveGameState();
    if (!mounted ||
        !_chessnutGameActive ||
        !_chessnutReady ||
        session != _boardConnectionSession ||
        !identical(sourceGame, _game) ||
        _pendingPhysicalMaiaMove != uci) {
      return;
    }
    if (epoch != _boardInteractionEpoch || !_gameCanRun) {
      _boardFailure(
        StateError('Motor command interrupted before dispatch'),
        StackTrace.current,
        session: session,
      );
      return;
    }
    if (uci.length != 4) {
      _boardFailure(
        StateError('Motor promotion requires on-screen continuation'),
        StackTrace.current,
      );
      return;
    }
    try {
      await _discovery!.movePiece(uci, session);
    } catch (e, s) {
      if (mounted && identical(sourceGame, _game) && _chessnutGameActive) {
        _boardFailure(e, s, session: session);
      }
    }
  }

  Future<void> _confirmMotorPosition() async {
    if (!_feedbackForeground ||
        !_feedbackRouteVisible ||
        !_chessnutReady ||
        _boardKind != BoardKind.squareOff ||
        _pendingPhysicalMaiaMove == null ||
        _boardDialogContext != null) {
      return;
    }
    final epoch = _boardInteractionEpoch;
    final fen = _game.fen;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) {
        _boardDialogContext = dialog;
        return AlertDialog(
          scrollable: true,
          title: Text(l10n(dialog).boardConfirmPosition),
          content: Text(l10n(dialog).boardConfirmPositionHelp),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: Text(l10n(dialog).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: Text(l10n(dialog).continueAction),
            ),
          ],
        );
      },
    );
    if (!mounted || epoch != _boardInteractionEpoch || fen != _game.fen) return;
    _boardDialogContext = null;
    if (confirmed != true || !_chessnutReady) return;
    final session = _boardConnectionSession;
    if (session == null || _discovery == null) return;
    try {
      await _discovery!.confirmPosition(session);
    } catch (e, s) {
      _boardFailure(e, s, epoch: epoch, session: session);
      return;
    }
    if (!mounted ||
        epoch != _boardInteractionEpoch ||
        session != _boardConnectionSession ||
        fen != _game.fen) {
      return;
    }
    final position = ChessnutProtocol.pieceMapFromFen(fen);
    _updateBoardUi(() => _chessnutPosition = position);
    _queueChessnutPosition(position);
  }

  void _resumeBoardInput() {
    if (!_genericBoards ||
        !_feedbackForeground ||
        !_feedbackRouteVisible ||
        !_useChessnutGo ||
        !_chessnutReady) {
      return;
    }
    final occupancy = _physicalOccupancy;
    if (_boardKind == BoardKind.pegasus && occupancy != null) {
      unawaited(_applyOccupancy(occupancy));
    }
    final deferred = _deferredSquareOffMove;
    _deferredSquareOffMove = null;
    if (_boardKind == BoardKind.squareOff && deferred != null) {
      unawaited(_receiveSquareOffMove(deferred, requireConfirmation: true));
    }
  }
}

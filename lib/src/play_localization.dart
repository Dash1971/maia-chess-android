part of '../main.dart';

/// Presentation state is persisted using stable codes and migrated from old saves.
enum _PlayMessage {
  chessnutBluetoothUnavailable,
  chessnutPermissionPending,
  chessnutBluetoothDisabled,
  chooseSettings,
  gameRestored,
  reconnectChessnut,
  chessnutConnectionError,
  searchingChessnut,
  connectingChessnut,
  couldNotConnectChessnut,
  chessnutAndroidOnly,
  chessnutIsDisconnected,
  yourMove,
  yourMoveChessnut,
  chessnutReady,
  chessnutStartingPosition,
  takebackCompleteYourMove,
  takebackCompleteThinking,
  restoreLitSquares,
  completeMaiaLitMove,
  illegalChessnutPosition,
  completeYourChessnutMove,
  connectChessnutFirst,
  gameInProgress,
  timeoutInsufficientMaterial,
  whiteOutOfTime,
  blackOutOfTime,
  makeMaiaLitMove,
  checkmateMaiaWins,
  checkmateYouWin,
  drawResult,
  drawByAgreement,
  youWin,
  maiaWins,
  gameEnded,
  consideringDraw,
  maiaDeclinedDraw,
  couldNotEvaluateDraw,
  youResigned,
  moveTakenBack,
  maiaIsThinking,
  maiaErrorPleaseRetry;

  String get legacy => switch (this) {
    _PlayMessage.connectingChessnut => 'Connecting to Chessnut…',
    _PlayMessage.chessnutBluetoothDisabled =>
      'Turn on Bluetooth, then reconnect Chessnut.',
    _PlayMessage.chessnutPermissionPending =>
      'Allow Bluetooth permissions, then reconnect Chessnut.',
    _PlayMessage.chessnutBluetoothUnavailable =>
      'Bluetooth is unavailable on this device.',
    _PlayMessage.chooseSettings => 'Choose your settings and start a game.',
    _PlayMessage.gameRestored => 'Game restored.',
    _PlayMessage.reconnectChessnut => 'Reconnect Chessnut to continue.',
    _PlayMessage.chessnutConnectionError => 'Chessnut connection error.',
    _PlayMessage.searchingChessnut => 'Searching for Chessnut…',
    _PlayMessage.couldNotConnectChessnut => 'Could not connect Chessnut.',
    _PlayMessage.chessnutAndroidOnly =>
      'Chessnut support is available on Android.',
    _PlayMessage.chessnutIsDisconnected => 'Chessnut is disconnected.',
    _PlayMessage.yourMove => 'Your move.',
    _PlayMessage.yourMoveChessnut => 'Your move on Chessnut.',
    _PlayMessage.chessnutReady => 'Chessnut is ready.',
    _PlayMessage.chessnutStartingPosition =>
      'Set up the standard starting position on Chessnut.',
    _PlayMessage.takebackCompleteYourMove =>
      'Takeback complete. Your move on Chessnut.',
    _PlayMessage.takebackCompleteThinking =>
      'Takeback complete. Maia is thinking…',
    _PlayMessage.restoreLitSquares =>
      'Takeback: restore the lit squares on Chessnut.',
    _PlayMessage.completeMaiaLitMove => 'Complete Maia’s lit move on Chessnut.',
    _PlayMessage.illegalChessnutPosition =>
      'That position is not a legal move. Correct the lit squares.',
    _PlayMessage.completeYourChessnutMove => 'Complete your move on Chessnut.',
    _PlayMessage.connectChessnutFirst => 'Connect Chessnut before starting.',
    _PlayMessage.gameInProgress => 'Game in progress.',
    _PlayMessage.timeoutInsufficientMaterial =>
      'Draw — timeout against insufficient material.',
    _PlayMessage.whiteOutOfTime => 'White ran out of time.',
    _PlayMessage.blackOutOfTime => 'Black ran out of time.',
    _PlayMessage.makeMaiaLitMove => 'Make Maia’s lit move on Chessnut.',
    _PlayMessage.checkmateMaiaWins => 'Checkmate — Maia wins.',
    _PlayMessage.checkmateYouWin => 'Checkmate — you win!',
    _PlayMessage.drawResult => 'Draw.',
    _PlayMessage.drawByAgreement => 'Draw by agreement.',
    _PlayMessage.youWin => 'You win.',
    _PlayMessage.maiaWins => 'Maia wins.',
    _PlayMessage.gameEnded => 'Game ended.',
    _PlayMessage.consideringDraw => 'Maia is considering the draw offer…',
    _PlayMessage.maiaDeclinedDraw => 'Maia declined the draw.',
    _PlayMessage.couldNotEvaluateDraw => 'Could not evaluate the draw offer.',
    _PlayMessage.youResigned => 'You resigned — Maia wins.',
    _PlayMessage.moveTakenBack => 'Move taken back. Your move.',
    _PlayMessage.maiaIsThinking => 'Maia is thinking…',
    _PlayMessage.maiaErrorPleaseRetry => 'Maia error. Please retry.',
  };

  String text(BuildContext context) => switch (this) {
    _PlayMessage.connectingChessnut => l10n(context).connectingChessnut,
    _PlayMessage.chessnutBluetoothDisabled => l10n(
      context,
    ).chessnutBluetoothDisabled,
    _PlayMessage.chessnutPermissionPending => l10n(
      context,
    ).chessnutPermissionPending,
    _PlayMessage.chessnutBluetoothUnavailable => l10n(
      context,
    ).chessnutBluetoothUnavailable,
    _PlayMessage.chooseSettings => l10n(context).chooseSettings,
    _PlayMessage.gameRestored => l10n(context).gameRestored,
    _PlayMessage.reconnectChessnut => l10n(context).reconnectChessnut,
    _PlayMessage.chessnutConnectionError => l10n(
      context,
    ).chessnutConnectionError,
    _PlayMessage.searchingChessnut => l10n(context).searchingChessnut,
    _PlayMessage.couldNotConnectChessnut => l10n(
      context,
    ).couldNotConnectChessnut,
    _PlayMessage.chessnutAndroidOnly => l10n(context).chessnutAndroidOnly,
    _PlayMessage.chessnutIsDisconnected => l10n(context).chessnutIsDisconnected,
    _PlayMessage.yourMove => l10n(context).yourMove,
    _PlayMessage.yourMoveChessnut => l10n(context).yourMoveChessnut,
    _PlayMessage.chessnutReady => l10n(context).chessnutReady,
    _PlayMessage.chessnutStartingPosition => l10n(
      context,
    ).chessnutStartingPosition,
    _PlayMessage.takebackCompleteYourMove => l10n(
      context,
    ).takebackCompleteYourMove,
    _PlayMessage.takebackCompleteThinking => l10n(
      context,
    ).takebackCompleteThinking,
    _PlayMessage.restoreLitSquares => l10n(context).restoreLitSquares,
    _PlayMessage.completeMaiaLitMove => l10n(context).completeMaiaLitMove,
    _PlayMessage.illegalChessnutPosition => l10n(
      context,
    ).illegalChessnutPosition,
    _PlayMessage.completeYourChessnutMove => l10n(
      context,
    ).completeYourChessnutMove,
    _PlayMessage.connectChessnutFirst => l10n(context).connectChessnutFirst,
    _PlayMessage.gameInProgress => l10n(context).gameInProgress,
    _PlayMessage.timeoutInsufficientMaterial => l10n(
      context,
    ).timeoutInsufficientMaterial,
    _PlayMessage.whiteOutOfTime => l10n(context).whiteOutOfTime,
    _PlayMessage.blackOutOfTime => l10n(context).blackOutOfTime,
    _PlayMessage.makeMaiaLitMove => l10n(context).makeMaiaLitMove,
    _PlayMessage.checkmateMaiaWins => l10n(context).checkmateMaiaWins,
    _PlayMessage.checkmateYouWin => l10n(context).checkmateYouWin,
    _PlayMessage.drawResult => l10n(context).drawResult,
    _PlayMessage.drawByAgreement => l10n(context).drawByAgreement,
    _PlayMessage.youWin => l10n(context).youWin,
    _PlayMessage.maiaWins => l10n(context).maiaWins,
    _PlayMessage.gameEnded => l10n(context).gameEnded,
    _PlayMessage.consideringDraw => l10n(context).consideringDraw,
    _PlayMessage.maiaDeclinedDraw => l10n(context).maiaDeclinedDraw,
    _PlayMessage.couldNotEvaluateDraw => l10n(context).couldNotEvaluateDraw,
    _PlayMessage.youResigned => l10n(context).youResigned,
    _PlayMessage.moveTakenBack => l10n(context).moveTakenBack,
    _PlayMessage.maiaIsThinking => l10n(context).maiaIsThinking,
    _PlayMessage.maiaErrorPleaseRetry => l10n(context).maiaErrorPleaseRetry,
  };

  static _PlayMessage fromPlatformError(String code) => switch (code) {
    'bluetooth_unavailable' => _PlayMessage.chessnutBluetoothUnavailable,
    'permission_pending' => _PlayMessage.chessnutPermissionPending,
    'bluetooth_disabled' => _PlayMessage.chessnutBluetoothDisabled,
    _ => _PlayMessage.couldNotConnectChessnut,
  };

  static _PlayMessage restore(Object? saved) {
    for (final message in values) {
      if (saved == message.name || saved == message.legacy) return message;
    }
    return _PlayMessage.gameRestored;
  }

  static _PlayMessage fromConnection(
    ElectronicBoardConnectionState state,
  ) => switch (state) {
    ElectronicBoardConnectionState.disconnected =>
      _PlayMessage.chessnutIsDisconnected,
    ElectronicBoardConnectionState.scanning => _PlayMessage.searchingChessnut,
    ElectronicBoardConnectionState.connecting ||
    ElectronicBoardConnectionState.connected => _PlayMessage.connectingChessnut,
    ElectronicBoardConnectionState.ready => _PlayMessage.chessnutReady,
    ElectronicBoardConnectionState.error =>
      _PlayMessage.chessnutConnectionError,
  };
}

String localizedTimePreset(
  BuildContext context,
  TimePreset preset,
) => switch (preset) {
  TimePreset.unlimited => l10n(context).unlimited,
  TimePreset.custom => l10n(context).custom,
  _ =>
    '${displayNumber(context, preset.minutes)} + ${displayNumber(context, preset.increment)}',
};

String localizedAnalysisQuality(
  BuildContext context,
  GameAnalysisQuality quality,
) => switch (quality) {
  GameAnalysisQuality.fast => l10n(context).fast,
  GameAnalysisQuality.balanced => l10n(context).balanced,
  GameAnalysisQuality.thorough => l10n(context).thorough,
};

String localizedAnalysisQualityDescription(
  BuildContext context,
  GameAnalysisQuality quality,
) => l10n(context).analysisQualityDetails(
  displayNumber(context, quality.depth),
  displayNumber(
    context,
    quality.moveTimeMs / 1000,
    decimalDigits: quality.moveTimeMs % 1000 == 0 ? 0 : 1,
  ),
  displayNumber(context, switch (quality) {
    GameAnalysisQuality.fast => 3,
    GameAnalysisQuality.balanced => 6,
    GameAnalysisQuality.thorough => 9,
  }),
);

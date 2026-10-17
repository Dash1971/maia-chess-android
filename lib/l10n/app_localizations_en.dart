// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get about => 'About';

  @override
  String get analysisBoard => 'Analysis Board';

  @override
  String get back => 'Back';

  @override
  String get black => 'Black';

  @override
  String get cancelPremoves => 'Cancel premoves';

  @override
  String get chessnutExperimental => 'Chessnut (experimental)';

  @override
  String get connectChessnut => 'Connect Chessnut';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get engineSettings => 'Engine settings';

  @override
  String get gameMenu => 'Game menu';

  @override
  String get gameReady => 'Game ready';

  @override
  String get gameSettings => 'Game settings';

  @override
  String get home => 'Home';

  @override
  String get playMaia => 'Play Maia';

  @override
  String get random => 'Random';

  @override
  String get recentGames => 'Recent games';

  @override
  String get resign => 'Resign';

  @override
  String get settings => 'Settings';

  @override
  String get startGame => 'Start game';

  @override
  String get timeControl => 'Time control';

  @override
  String get white => 'White';

  @override
  String get unlimited => 'Unlimited';

  @override
  String get custom => 'Custom';

  @override
  String get seconds => 'seconds';

  @override
  String get yourSide => 'Your side';

  @override
  String get you => 'You';

  @override
  String get systemDefault => 'System default';

  @override
  String get language => 'Language';

  @override
  String get playMaiaRating => 'Play Maia rating';

  @override
  String get minutes => 'Minutes';

  @override
  String get increment => 'Increment';

  @override
  String get gameSounds => 'Game sounds';

  @override
  String get movesCapturesErrorsAndGameEnd =>
      'Moves, captures, errors, and game end';

  @override
  String get hapticFeedback => 'Touch feedback';

  @override
  String get touchFeedbackForMovesChecksErrorsAndGameEnd =>
      'Touch feedback for moves, checks, errors, and game end';

  @override
  String get premoves => 'Premoves';

  @override
  String get queueAMoveWhileMaiaIsThinking =>
      'Queue a move while Maia is thinking';

  @override
  String get oneHundredMsPremovePenalty => '100 ms premove penalty';

  @override
  String get use01SecondsPerPremoveInTimedGames =>
      'Use 0.1 seconds per premove in timed games';

  @override
  String get allowMultiplePremoves => 'Allow multiple premoves';

  @override
  String get queueASequenceAnIllegalMoveCancelsTheRest =>
      'Queue a sequence; an illegal move cancels the rest';

  @override
  String get humanMoveTiming => 'Human move timing';

  @override
  String get variableNaturalPausesBeforeMaiaMoves =>
      'Variable natural pauses before Maia moves';

  @override
  String get aboutTemperatureAndTopP => 'About Temperature and Top-P';

  @override
  String get temperature => 'Temperature';

  @override
  String get topP => 'Top-P';

  @override
  String get maxOpeningVariety => 'Max variety in opening';

  @override
  String get maxOpeningVarietyHelp =>
      'Not needed when Temperature and Top-P are at their default values of 1.0 / 1.0. Uses 1.0 / 1.0 for the first five moves by each side, then returns to your configured settings from move 6.\n\nThe goal is to give Maia maximum opening variety while allowing potentially stronger play later in the game by reducing the chance of low-probability moves through lower Temperature and/or Top-P.';

  @override
  String get maiaAnalysisRating => 'Maia analysis rating';

  @override
  String get addSecondMaiaEngine => 'Add second Maia engine';

  @override
  String get compareAnotherMaiaRatingInAnalysisAndReview =>
      'Compare another Maia rating in analysis and review';

  @override
  String get secondMaiaAnalysisRating => 'Second Maia analysis rating';

  @override
  String get gameAnalysisQuality => 'Game analysis quality';

  @override
  String get resetSettingsDefaults => 'Reset settings to default';

  @override
  String get boardSounds => 'Board sounds';

  @override
  String get beepForCheckCheckmateAndCompletedIllegalMoves =>
      'Beep for check, checkmate, and completed illegal moves.';

  @override
  String get copyDiagnostics => 'Copy diagnostics';

  @override
  String get diagnosticsCopied => 'Diagnostics copied';

  @override
  String get newGame => 'New game';

  @override
  String get resetGame => 'Reset game';

  @override
  String get shareAndExport => 'Share and export';

  @override
  String get savePgnFile => 'Save PGN file';

  @override
  String get sharePgn => 'Share PGN';

  @override
  String get copyPgn => 'Copy PGN';

  @override
  String get copyFen => 'Copy FEN';

  @override
  String get maiaErrorRetry => 'Maia error. Retry';

  @override
  String get maiaErrorPleaseRetry => 'Maia error. Please retry.';

  @override
  String get retry => 'Retry';

  @override
  String get maiaIsThinking => 'Maia is thinking…';

  @override
  String get history => 'HISTORY';

  @override
  String get start => 'START';

  @override
  String get chessnutStatus => 'Chessnut status';

  @override
  String get leaveCurrentGame => 'Leave current game?';

  @override
  String get yourGameWillBeKeptInRecentGames =>
      'Your game will be kept in Recent games.';

  @override
  String get cancel => 'Cancel';

  @override
  String get continueAction => 'Continue';

  @override
  String get startANewGame => 'Start a new game?';

  @override
  String get resetGameQuestion => 'Reset game?';

  @override
  String get yourCompletedGameWillRemainInRecentGames =>
      'Your completed game will remain in Recent Games.';

  @override
  String get thisGameWillBePermanentlyErased =>
      'This game will be permanently erased.';

  @override
  String get startNewGame => 'Start new game';

  @override
  String get reset => 'Reset';

  @override
  String get flipBoard => 'Flip board';

  @override
  String get offerDraw => 'Offer draw';

  @override
  String get takeBackMove => 'Takeback';

  @override
  String get whiteIsVictorious => 'White is victorious';

  @override
  String get blackIsVictorious => 'Black is victorious';

  @override
  String get theGameIsADraw => 'The game is a draw';

  @override
  String get theGameHasEnded => 'The game has ended';

  @override
  String get rematch => 'Rematch';

  @override
  String get fast => 'Fast';

  @override
  String get balanced => 'Balanced';

  @override
  String get thorough => 'Thorough';

  @override
  String get continueFromHere => 'Continue from here';

  @override
  String get load => 'Load';

  @override
  String get editBoard => 'Edit Board';

  @override
  String get done => 'Done';

  @override
  String get whitePieces => 'White pieces';

  @override
  String get blackPieces => 'Black pieces';

  @override
  String get whiteToMove => 'White to move';

  @override
  String get blackToMove => 'Black to move';

  @override
  String get castlingRights => 'Castling rights';

  @override
  String get whiteKingside => 'White kingside';

  @override
  String get whiteQueenside => 'White queenside';

  @override
  String get blackKingside => 'Black kingside';

  @override
  String get blackQueenside => 'Black queenside';

  @override
  String get enPassantTarget => 'En-passant target';

  @override
  String get startingPosition => 'Starting position';

  @override
  String get clearBoard => 'Clear board';

  @override
  String get loadFen => 'Load FEN';

  @override
  String get loadPgn => 'Load PGN';

  @override
  String get openPgnFile => 'Open PGN file';

  @override
  String get clearMoves => 'Clear moves';

  @override
  String get boardEditor => 'Board Editor';

  @override
  String get endPosition => 'end position';

  @override
  String get analysisMenu => 'Analysis menu';

  @override
  String get turnEngineOff => 'Turn engine off';

  @override
  String get turnEngineOn => 'Turn engine on';

  @override
  String get moves => 'Moves';

  @override
  String get computerAnalysis => 'Computer analysis';

  @override
  String get backToGame => 'Back to game';

  @override
  String get expandVariations => 'Expand variations';

  @override
  String get collapseVariations => 'Collapse variations';

  @override
  String get promoteVariation => 'Promote variation';

  @override
  String get makeMainLine => 'Make main line';

  @override
  String get deleteFromHere => 'Delete from here';

  @override
  String get analyzing => 'Analyzing…';

  @override
  String get noLegalMoves => 'No legal moves';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get analysisFailed => 'Analysis failed. Please retry.';

  @override
  String get analysisStopped => 'Computer analysis stopped.';

  @override
  String get classifyingMoves => 'Classifying moves…';

  @override
  String get graphReadyClassifying => 'Graph ready · classifying moves…';

  @override
  String get stopAnalysis => 'Stop analysis';

  @override
  String get runAnalysisAgain => 'Run computer analysis again';

  @override
  String get runAnalysis => 'Run computer analysis';

  @override
  String get analysisExplanation =>
      'Run computer analysis to generate the evaluation graph and White/Black accuracy.';

  @override
  String get pgnCopied => 'PGN copied';

  @override
  String get fenCopied => 'FEN copied';

  @override
  String get rawProbabilitiesExplanation =>
      'Raw model probabilities normalized across every legal move. Temperature and Top-P are not applied.';

  @override
  String get showRawProbabilities => 'Show full raw model probabilities';

  @override
  String get pasteFen => 'Paste a complete six-field FEN';

  @override
  String get pastePgn => 'Paste a PGN game';

  @override
  String get invalidPosition => 'Invalid position. Check the board and FEN.';

  @override
  String get pgnLoadFailed =>
      'Could not load the PGN game. Check the file or pasted text.';

  @override
  String get goToNext => 'Go to next';

  @override
  String tapForNext(String label) {
    return '$label · tap for next';
  }

  @override
  String get notEnoughMoves => 'Not enough moves';

  @override
  String get gameAccuracy => 'Game accuracy';

  @override
  String get accuracy => 'Accuracy';

  @override
  String get analysisGraph => 'Computer analysis graph';

  @override
  String maiaMoveProbabilities(int elo) {
    return 'Maia $elo move probabilities';
  }

  @override
  String otherProbability(String probability) {
    return 'Other $probability';
  }

  @override
  String otherLegalProbability(String probability) {
    return 'other legal moves $probability';
  }

  @override
  String maiaProbabilitySemantics(String title, String moves) {
    return '$title. $moves.';
  }

  @override
  String analysisProgress(int completed, int total) {
    return 'Analyzing $completed of $total positions…';
  }

  @override
  String graphPosition(int position, int total, String score) {
    return 'Position $position of $total  ·  $score';
  }

  @override
  String positionNumber(int position) {
    return 'Position $position';
  }

  @override
  String classificationCount(int count, String side, String classification) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count $side $classification moves',
      one: '$count $side $classification move',
    );
    return '$_temp0';
  }

  @override
  String get classificationBrilliant => 'Brilliant';

  @override
  String get classificationGood => 'Good';

  @override
  String get classificationInteresting => 'Interesting';

  @override
  String get classificationDubious => 'Dubious';

  @override
  String get classificationMistake => 'Mistake';

  @override
  String get classificationBlunder => 'Blunder';

  @override
  String get gameReview => 'Game review';

  @override
  String materialPawn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pawns',
      one: '$count pawn',
    );
    return '$_temp0';
  }

  @override
  String materialKnight(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count knights',
      one: '$count knight',
    );
    return '$_temp0';
  }

  @override
  String materialBishop(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bishops',
      one: '$count bishop',
    );
    return '$_temp0';
  }

  @override
  String materialRook(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rooks',
      one: '$count rook',
    );
    return '$_temp0';
  }

  @override
  String materialQueen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count queens',
      one: '$count queen',
    );
    return '$_temp0';
  }

  @override
  String materialAdvantage(String score) {
    return '$score material advantage';
  }

  @override
  String materialDescription(String side, String description) {
    return '$side material: $description';
  }

  @override
  String get previousMove => 'Previous move';

  @override
  String get nextMove => 'Next move';

  @override
  String get beginning => 'beginning';

  @override
  String get latestPosition => 'latest position';

  @override
  String holdForDestination(String destination) {
    return 'Hold for $destination';
  }

  @override
  String get phaseOpening => 'Opening';

  @override
  String get phaseMiddlegame => 'Middlegame';

  @override
  String get phaseEndgame => 'Endgame';

  @override
  String get pieceKing => 'King';

  @override
  String get pieceQueen => 'Queen';

  @override
  String get pieceRook => 'Rook';

  @override
  String get pieceBishop => 'Bishop';

  @override
  String get pieceKnight => 'Knight';

  @override
  String get piecePawn => 'Pawn';

  @override
  String recentPlayerMaia(String rating) {
    return 'Player — Maia $rating';
  }

  @override
  String recentMaiaPlayer(String rating) {
    return 'Maia $rating — Player';
  }

  @override
  String get recentIncomplete => 'Incomplete';

  @override
  String get recentCompleted => 'Completed';

  @override
  String get recentDeleteFailed =>
      'Could not delete saved games. Please try again.';

  @override
  String get recentOpenFailed => 'Could not open saved game. Please try again.';

  @override
  String recentDeleteTitle(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $countString games?',
      one: 'Delete saved game?',
    );
    return '$_temp0';
  }

  @override
  String recentDeleteWarning(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'These $countString saved games will be permanently deleted.',
      one: 'This saved game will be permanently deleted.',
    );
    return '$_temp0';
  }

  @override
  String get deleteAction => 'Delete';

  @override
  String get recentUpdating => 'Updating saved games';

  @override
  String get recentCancelSelection => 'Cancel selection';

  @override
  String get recentClearSelection => 'Clear selection';

  @override
  String get recentSelectAll => 'Select all games';

  @override
  String get recentDeleteSelected => 'Delete selected games';

  @override
  String get recentSelectGames => 'Select games';

  @override
  String get recentDeleteAll => 'Delete all games';

  @override
  String get recentDeleteOne => 'Delete saved game';

  @override
  String recentSelectedCount(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString selected';
  }

  @override
  String get recentLoadFailed =>
      'Could not load saved games. Please try again.';

  @override
  String get recentEmpty =>
      'Completed games and incomplete games saved from Home will appear here.';

  @override
  String recentGameSummary(String result, String date) {
    return '$result · $date';
  }

  @override
  String get diagnosticsScreenError =>
      'Mobile Maia encountered a screen error.';

  @override
  String get diagnosticsScreenInstructions =>
      'Copy the diagnostics and send them with a description of what you tapped immediately before this screen appeared.';

  @override
  String get pgnSaved => 'PGN saved';

  @override
  String get pgnExportFailed =>
      'Could not export PGN. Your game is still saved locally.';

  @override
  String get languagePreferenceError =>
      'The language could not be saved or restored. Your games are unaffected. Please try selecting the language again.';

  @override
  String playRatingValue(String rating) {
    return 'Play Maia rating: $rating';
  }

  @override
  String minutesValue(String minutes) {
    return 'Minutes: $minutes';
  }

  @override
  String incrementSecondsValue(String seconds) {
    return 'Increment: $seconds seconds';
  }

  @override
  String get chooseSettings => 'Choose your settings and start a game.';

  @override
  String get gameRestored => 'Game restored.';

  @override
  String get reconnectChessnut => 'Reconnect Chessnut to continue.';

  @override
  String get chessnutConnectionError => 'Chessnut connection error.';

  @override
  String get searchingChessnut => 'Searching for Chessnut…';

  @override
  String get couldNotConnectChessnut => 'Could not connect Chessnut.';

  @override
  String get chessnutAndroidOnly => 'Chessnut support is available on Android.';

  @override
  String get chessnutIsDisconnected => 'Chessnut is disconnected.';

  @override
  String get yourMove => 'Your turn.';

  @override
  String get yourMoveChessnut => 'Your turn on Chessnut.';

  @override
  String get chessnutReady => 'Chessnut is ready.';

  @override
  String get chessnutStartingPosition =>
      'Set up the standard starting position on Chessnut.';

  @override
  String get takebackCompleteYourMove =>
      'Takeback complete. Your turn on Chessnut.';

  @override
  String get takebackCompleteThinking => 'Takeback complete. Maia is thinking…';

  @override
  String get restoreLitSquares =>
      'Takeback: restore the lit squares on Chessnut.';

  @override
  String get completeMaiaLitMove => 'Complete Maia’s lit move on Chessnut.';

  @override
  String get illegalChessnutPosition =>
      'That position is not a legal move. Correct the lit squares.';

  @override
  String get completeYourChessnutMove => 'Complete your move on Chessnut.';

  @override
  String get connectChessnutFirst => 'Connect Chessnut before starting.';

  @override
  String get gameInProgress => 'Game in progress.';

  @override
  String get timeoutInsufficientMaterial =>
      'Draw — timeout against insufficient material.';

  @override
  String get whiteOutOfTime => 'White ran out of time.';

  @override
  String get blackOutOfTime => 'Black ran out of time.';

  @override
  String get makeMaiaLitMove => 'Make Maia’s lit move on Chessnut.';

  @override
  String get checkmateMaiaWins => 'Checkmate — Maia wins.';

  @override
  String get checkmateYouWin => 'Checkmate — you win!';

  @override
  String get drawResult => 'Draw.';

  @override
  String get drawByAgreement => 'Draw by agreement.';

  @override
  String get youWin => 'You win.';

  @override
  String get maiaWins => 'Maia wins.';

  @override
  String get gameEnded => 'Game ended.';

  @override
  String get consideringDraw => 'Maia is considering the draw offer…';

  @override
  String get maiaDeclinedDraw => 'Maia declined the draw.';

  @override
  String get couldNotEvaluateDraw => 'Could not evaluate the draw offer.';

  @override
  String get youResigned => 'You resigned — Maia wins.';

  @override
  String get moveTakenBack => 'Move taken back. Your turn.';

  @override
  String get connectingChessnut => 'Connecting to Chessnut…';

  @override
  String get chessnutUnavailable => 'Chessnut unavailable';

  @override
  String get chessnutDisconnected => 'Chessnut disconnected';

  @override
  String get reconnect => 'Reconnect';

  @override
  String get playInApp => 'Play in app';

  @override
  String get continueGameOnScreen => 'Continue this game on screen';

  @override
  String get checkCheckmateIllegalMoves =>
      'Check, checkmate, and illegal moves';

  @override
  String get offerDrawQuestion => 'Offer draw?';

  @override
  String get resignGameQuestion => 'Resign game?';

  @override
  String get resignEndsImmediately => 'This will end the game immediately.';

  @override
  String get premoveLimit => 'Up to 64 premoves can be queued.';

  @override
  String get chessnutGameRestriction =>
      'Chessnut play supports standard-position, unlimited games only.';

  @override
  String get samplingTitle => 'Temperature and Top-P';

  @override
  String get samplingDefaultsQuestion => 'Choose how much variety you want';

  @override
  String get samplingResearch => 'Full research data (JSONL)';

  @override
  String get samplingResearchLink => 'Full research data';

  @override
  String get close => 'Close';

  @override
  String get unknownVersion => 'Unknown version';

  @override
  String get maiaProjectSource => 'Maia-3 project and source code';

  @override
  String get enCroissantProjectSource => 'En Croissant project and source code';

  @override
  String get licence => 'Licence';

  @override
  String get mobileMaiaSource => 'Mobile Maia source code';

  @override
  String get aboutPoweredBy =>
      'Powered by Maia-3, the human-like chess engine developed by the University of Toronto Computational Social Science Lab.';

  @override
  String get aboutOffline =>
      'Maia-3 runs entirely on your phone. No account or network connection is required.';

  @override
  String get aboutBoardCredits =>
      'Board interface, default brown theme, and Cburnett pieces are provided by Lichess Flutter Chessground. Local Stockfish support uses Lichess multistockfish.';

  @override
  String get aboutReviewCredits =>
      'Game Review move classification and sacrifice-detection heuristics are adapted from the En Croissant open-source chess GUI.';

  @override
  String get aboutLicence =>
      'Mobile Maia is free software distributed under AGPL-3.0-only, without any warranty. You may redistribute and modify it under the terms of that licence. The complete source code is available from the project repository.';

  @override
  String get aboutIndependent =>
      'This independent community app is not an official Maia-3 or University of Toronto, Lichess, or En Croissant application.';

  @override
  String get samplingRecommendationWarning =>
      'Lowering Temperature or Top-P may make Maia stronger in the middlegame, but reduce opening variety. See the information button for details.';

  @override
  String get couldNotOpenPgn => 'Could not open PGN.';

  @override
  String temperatureValue(String value) {
    return 'Temperature: $value';
  }

  @override
  String topPValue(String value) {
    return 'Top-P: $value';
  }

  @override
  String analysisRatingValue(String rating) {
    return 'Maia analysis rating: $rating';
  }

  @override
  String secondAnalysisRatingValue(String rating) {
    return 'Second Maia analysis rating: $rating';
  }

  @override
  String premovesList(String moves) {
    return 'Premoves: $moves';
  }

  @override
  String maiaOpponentRating(String rating) {
    return 'Maia3 ${rating}elo';
  }

  @override
  String analysisQualityDetails(
    String depth,
    String seconds,
    String extraSeconds,
  ) {
    return 'Depth $depth · up to $seconds seconds per position, plus up to $extraSeconds seconds checking standout moves.';
  }

  @override
  String chessnutBattery(String percent, String charging) {
    String _temp0 = intl.Intl.selectLogic(charging, {'yes': ' ⚡', 'other': ''});
    return '$percent%$_temp0';
  }

  @override
  String get chessnutBluetoothUnavailable =>
      'Bluetooth is unavailable on this device.';

  @override
  String get chessnutPermissionPending =>
      'Allow Bluetooth permissions, then reconnect Chessnut.';

  @override
  String get chessnutBluetoothDisabled =>
      'Turn on Bluetooth, then reconnect Chessnut.';

  @override
  String get whiteShort => 'W';

  @override
  String get blackShort => 'B';

  @override
  String get dateUnknown => 'Date unknown';

  @override
  String get savedGameVersionUnsupported =>
      'This saved data uses an unsupported format. Update Mobile Maia to open it. This data has been preserved.';

  @override
  String get gameStorageFailed =>
      'Could not access saved-game storage. Please try again.';

  @override
  String recentWinResult(String result) {
    return 'Win ($result)';
  }

  @override
  String recentLossResult(String result) {
    return 'Loss ($result)';
  }

  @override
  String recentDrawResult(String result) {
    return 'Draw ($result)';
  }

  @override
  String get electronicBoardExperimental => 'Electronic board (experimental)';

  @override
  String get connectBoard => 'Connect board';

  @override
  String get chooseBoard => 'Choose a board';

  @override
  String get chooseAnotherBoard => 'Choose another board';

  @override
  String get boardSearching => 'Searching for boards…';

  @override
  String get boardConnecting => 'Connecting to board…';

  @override
  String get boardDisconnected => 'Board disconnected';

  @override
  String get boardConnectionError =>
      'Could not connect. Check Bluetooth and the board, then retry.';

  @override
  String get boardStartingPosition =>
      'Set up the standard starting position on your board.';

  @override
  String get boardReady => 'Board ready';

  @override
  String get boardExperimentalNotice =>
      'New board support is experimental. Please verify moves on both screens and report connection problems.';

  @override
  String get boardGameRestriction =>
      'Electronic-board games start from the standard position and use unlimited time.';

  @override
  String get boardConfirmSetup => 'I have set up the starting position';

  @override
  String get boardConfirmSetupHelp =>
      'Check every piece before starting. This board cannot verify piece identity.';

  @override
  String get boardChooseMove => 'Confirm your board move';

  @override
  String get boardAmbiguousMove =>
      'The board cannot distinguish these moves. Choose the move you played.';

  @override
  String get boardUnavailable =>
      'This board is not ready. Reconnect, or continue on your phone.';

  @override
  String get boardNewGameConfirmInstruction =>
      'Press NEW GAME again within 2.5 seconds to confirm, or use the buttons below.';

  @override
  String get boardNewGameConfirmationExpired =>
      'To confirm on the board, press NEW GAME twice within 2.5 seconds.';

  @override
  String get boardPhysicalMove => 'Complete the move on your board.';

  @override
  String get boardResetPhysical =>
      'Restore the position shown on screen before continuing.';

  @override
  String get boardNoResults =>
      'No supported board found. Wake your board and try again.';

  @override
  String get boardWaitingForSelection => 'Choose a board to connect.';

  @override
  String get boardReconnect => 'Reconnect board';

  @override
  String get boardLockedPegasus =>
      'Pegasus is locked. This Dev build does not include its manufacturer initialization key.';

  @override
  String get boardMotorRecovery =>
      'Continue on your phone. This experimental adapter cannot safely restore the board’s motor state.';

  @override
  String get boardConfirmPosition => 'Confirm the physical position';

  @override
  String get boardConfirmPositionHelp =>
      'Check that every piece matches the position on screen.';

  @override
  String get maiaHistorySetting => 'Use move history';

  @override
  String get maiaHistoryHelp =>
      'Let Maia consider up to seven previous positions as well as the current position. This improved prediction of human moves by about 2 percentage points in our tests with the 79M model, but sometimes encouraged repeated copying in low-rated openings. We were not able to establish a strength increase. Off is recommended for now.';

  @override
  String get maiaHistoryResearch => 'Read the move-history research';

  @override
  String get maiaHistoryOn => 'Move history: on';

  @override
  String get maiaHistoryOff => 'Move history: off';

  @override
  String get chessboardDeviceName => 'Chessboard';

  @override
  String namedBoardConnected(String boardName) {
    return '$boardName connected';
  }

  @override
  String namedBoardDisconnected(String boardName) {
    return '$boardName disconnected';
  }

  @override
  String get saveMaiaSamplingData => 'Save Maia sampling data';

  @override
  String get samplingDataHelp =>
      'Save Maia’s move probabilities, settings and selected moves on this device to explore how it plays.\n\nExported files contain board positions, move history and model inputs and decisions.\n\nThe last 10 recorded games are saved and presented newest first. Older games may be removed sooner if the storage limit is reached. This is separate from Recent Games.\n\nUse this feature if you are interested in studying the technical details of how Maia works. Data cannot be viewed in the app. It is exported to an easy-to-view HTML file containing a subset of the data, or a JSONL file containing all the recorded data.\n\nThis is off by default, and we recommend keeping it off unless you are interested in researching how Maia works.';

  @override
  String get clearSamplingData => 'Clear sampling data';

  @override
  String samplingDataStatus(int count) {
    return '$count decisions saved';
  }

  @override
  String get samplingDataError =>
      'Could not access sampling data. Playing is unaffected.';

  @override
  String get samplingSave => 'Save…';

  @override
  String get samplingShare => 'Share…';

  @override
  String get samplingSummary => 'Maia’s choices';

  @override
  String get samplingReadable => 'Readable report (HTML)';

  @override
  String get samplingReadableHint =>
      'Moves, probabilities and board diagrams. Opens in a browser.';

  @override
  String get samplingResearchHint =>
      'Raw model inputs and outputs for technical analysis.';

  @override
  String get samplingReportExplanation =>
      'Percentages show the chance of each move being selected after your Temperature and Top-P settings were applied. They are not winning chances or move-quality scores.';

  @override
  String get samplingReportPartial =>
      'Only recorded Maia decisions are shown, not a complete game. Takebacks and retries can repeat a move number.';

  @override
  String get samplingReportMissing =>
      'Some capture data was removed or could not be saved. This report may have gaps.';

  @override
  String get samplingPlayed => 'Played';

  @override
  String get samplingNotPlayed => 'Not recorded as played';

  @override
  String get samplingAlternatives => 'Likely alternatives';

  @override
  String samplingGame(String number) {
    return 'Game $number';
  }

  @override
  String samplingRecords(String count) {
    return 'Recorded decisions: $count';
  }

  @override
  String get samplingMostProbable => 'Most probable';

  @override
  String get samplingPlayedMostProbable => 'Played the most probable move';

  @override
  String samplingChance(String move, String odds) {
    return '$move had about a 1 in $odds chance of being played.';
  }

  @override
  String samplingCertain(String move) {
    return '$move was certain to be selected (100%).';
  }

  @override
  String samplingAlmostCertain(String move) {
    return '$move was almost certain to be selected.';
  }

  @override
  String get samplingReportRetention =>
      'The last 10 recorded games are saved and presented newest first. Older games may be removed sooner if the storage limit is reached.';

  @override
  String get samplingJumpToGame => 'Jump to game';

  @override
  String get samplingBackToGames => 'Back to game list';

  @override
  String get samplingIncomplete => 'Incomplete';

  @override
  String get samplingUnknownResult => 'Unknown result';

  @override
  String get samplingOpeningUnknown => 'Unknown opening';

  @override
  String get samplingTimeUnknown => 'Unknown time';

  @override
  String get samplingWin => 'Victory';

  @override
  String get samplingLoss => 'Defeat';

  @override
  String get samplingDraw => 'Draw';

  @override
  String get samplingDeleteData => 'Delete data';

  @override
  String get samplingClearConfirmation =>
      'Delete all Maia sampling data? It cannot be recovered.';

  @override
  String get analysisSettings => 'Analysis settings';

  @override
  String get samplingData => 'Sampling data';

  @override
  String get resetSettingsDefaultsScope =>
      'Resets all settings on this screen. Saved games and sampling data are kept.';

  @override
  String get settingsResetError =>
      'Some settings could not be reset. Please try again.';

  @override
  String get resetSettingsConfirmation => 'Reset all settings to default?';

  @override
  String get resetSettingsKeepData =>
      'Your saved games and sampling data will be kept.';

  @override
  String get resetSettingsAction => 'Reset settings';

  @override
  String get samplingHelpIntro =>
      'Temperature and Top-P control how Maia chooses between moves.';

  @override
  String get samplingHelpVariety =>
      'Increasing Temperature and Top-P is like making Maia a more volatile player, as Maia becomes more likely to play low-probability moves. These may be blunders, but they may also be brilliant moves!';

  @override
  String get samplingHelpDefaults =>
      'If you value maximum variety, and you also want Maia to play a broad range of human openings, including sidelines, then keep the default values of 1.0 and 1.0.';

  @override
  String get samplingHelpStrength =>
      'If you prefer a stronger opponent playing fewer blunders, experiment with moving Temperature and Top-P values down.';

  @override
  String get samplingHelpArgmax =>
      'Setting Temperature to 0 will cause Maia to use argmax, which is a technical way of saying that Maia will always play what it predicts is the most probable human move in a given position. Careful! In our research at the 1600 setting, argmax Maia outperformed Maia at 1.0 / 1.0 by the equivalent of about 300 Elo points in direct matches.';

  @override
  String get samplingHelpTopP =>
      'For balanced play, you may consider keeping Temperature at 1.0 and setting Top-P to 0.95. This maintains variety while eliminating low-probability moves, which can often be blunders—but can also be good moves. Top-P essentially cuts off low-probability moves. Setting it to 0.95 keeps moves accounting for at least 95% of the probability after Temperature is applied. The remaining moves cannot be selected by Maia.';

  @override
  String get samplingHelpResearchIntro =>
      'We experimented with these settings at 1600 Elo and published our full findings here:';
}

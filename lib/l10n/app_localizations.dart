import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// Home / game setup: About
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Home / game setup: Analysis Board
  ///
  /// In en, this message translates to:
  /// **'Analysis Board'**
  String get analysisBoard;

  /// Home / game setup: Back
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Home / game setup: Black
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get black;

  /// Home / game setup: Cancel premoves
  ///
  /// In en, this message translates to:
  /// **'Cancel premoves'**
  String get cancelPremoves;

  /// Home / game setup: Chessnut (experimental)
  ///
  /// In en, this message translates to:
  /// **'Chessnut (experimental)'**
  String get chessnutExperimental;

  /// Home / game setup: Connect Chessnut
  ///
  /// In en, this message translates to:
  /// **'Connect Chessnut'**
  String get connectChessnut;

  /// Home / game setup: Disconnect
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// Home / game setup: Engine settings
  ///
  /// In en, this message translates to:
  /// **'Engine settings'**
  String get engineSettings;

  /// Home / game setup: Game menu
  ///
  /// In en, this message translates to:
  /// **'Game menu'**
  String get gameMenu;

  /// Home / game setup: Game ready
  ///
  /// In en, this message translates to:
  /// **'Game ready'**
  String get gameReady;

  /// Home / game setup: Game settings
  ///
  /// In en, this message translates to:
  /// **'Game settings'**
  String get gameSettings;

  /// Home / game setup: Home
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Home / game setup: Play Maia
  ///
  /// In en, this message translates to:
  /// **'Play Maia'**
  String get playMaia;

  /// Home / game setup: Random
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get random;

  /// Home / game setup: Recent games
  ///
  /// In en, this message translates to:
  /// **'Recent games'**
  String get recentGames;

  /// Home / game setup: Resign
  ///
  /// In en, this message translates to:
  /// **'Resign'**
  String get resign;

  /// Home / game setup: Settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Home / game setup: Start game
  ///
  /// In en, this message translates to:
  /// **'Start game'**
  String get startGame;

  /// Home / game setup: Time control
  ///
  /// In en, this message translates to:
  /// **'Time control'**
  String get timeControl;

  /// Home / game setup: White
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get white;

  /// Home / game setup: Unlimited
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimited;

  /// Home / game setup: Custom
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// Home / game setup: seconds
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// Home / game setup: Your side
  ///
  /// In en, this message translates to:
  /// **'Your side'**
  String get yourSide;

  /// Home / game setup: You
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// Settings: System default
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// Settings: Language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Settings: Play Maia rating
  ///
  /// In en, this message translates to:
  /// **'Play Maia rating'**
  String get playMaiaRating;

  /// Settings: Minutes
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutes;

  /// Time added to a player’s chess clock after each move, in seconds. Not a generic numeric increment.
  ///
  /// In en, this message translates to:
  /// **'Increment'**
  String get increment;

  /// Settings: Game sounds
  ///
  /// In en, this message translates to:
  /// **'Game sounds'**
  String get gameSounds;

  /// Settings: Moves, captures, errors, and game end
  ///
  /// In en, this message translates to:
  /// **'Moves, captures, errors, and game end'**
  String get movesCapturesErrorsAndGameEnd;

  /// Settings: Haptic feedback
  ///
  /// In en, this message translates to:
  /// **'Touch feedback'**
  String get hapticFeedback;

  /// Settings: Touch feedback for moves, checks, errors, and game end
  ///
  /// In en, this message translates to:
  /// **'Touch feedback for moves, checks, errors, and game end'**
  String get touchFeedbackForMovesChecksErrorsAndGameEnd;

  /// Settings: Premoves
  ///
  /// In en, this message translates to:
  /// **'Premoves'**
  String get premoves;

  /// Settings: Queue a move while Maia is thinking
  ///
  /// In en, this message translates to:
  /// **'Queue a move while Maia is thinking'**
  String get queueAMoveWhileMaiaIsThinking;

  /// Settings: 100 ms premove penalty
  ///
  /// In en, this message translates to:
  /// **'100 ms premove penalty'**
  String get oneHundredMsPremovePenalty;

  /// Settings: Use 0.1 seconds per premove in timed games
  ///
  /// In en, this message translates to:
  /// **'Use 0.1 seconds per premove in timed games'**
  String get use01SecondsPerPremoveInTimedGames;

  /// Settings: Allow multiple premoves
  ///
  /// In en, this message translates to:
  /// **'Allow multiple premoves'**
  String get allowMultiplePremoves;

  /// Settings: Queue a sequence; an illegal move cancels the rest
  ///
  /// In en, this message translates to:
  /// **'Queue a sequence; an illegal move cancels the rest'**
  String get queueASequenceAnIllegalMoveCancelsTheRest;

  /// Toggle for optional random pauses before Maia moves. Changes timing only, not move selection, strength, or a learned human-time model.
  ///
  /// In en, this message translates to:
  /// **'Human move timing'**
  String get humanMoveTiming;

  /// Settings: Variable natural pauses before Maia moves
  ///
  /// In en, this message translates to:
  /// **'Variable natural pauses before Maia moves'**
  String get variableNaturalPausesBeforeMaiaMoves;

  /// Settings: About Temperature and Top-P
  ///
  /// In en, this message translates to:
  /// **'About Temperature and Top-P'**
  String get aboutTemperatureAndTopP;

  /// Settings: Temperature
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// Settings: Top-P
  ///
  /// In en, this message translates to:
  /// **'Top-P'**
  String get topP;

  /// Settings: Maia analysis rating
  ///
  /// In en, this message translates to:
  /// **'Maia analysis rating'**
  String get maiaAnalysisRating;

  /// Settings: Add second Maia engine
  ///
  /// In en, this message translates to:
  /// **'Add second Maia engine'**
  String get addSecondMaiaEngine;

  /// Settings: Compare another Maia rating in analysis and review
  ///
  /// In en, this message translates to:
  /// **'Compare another Maia rating in analysis and review'**
  String get compareAnotherMaiaRatingInAnalysisAndReview;

  /// Settings: Second Maia analysis rating
  ///
  /// In en, this message translates to:
  /// **'Second Maia analysis rating'**
  String get secondMaiaAnalysisRating;

  /// Settings: Game analysis quality
  ///
  /// In en, this message translates to:
  /// **'Game analysis quality'**
  String get gameAnalysisQuality;

  /// Settings: Reset engine defaults
  ///
  /// In en, this message translates to:
  /// **'Reset engine defaults'**
  String get resetEngineDefaults;

  /// Settings: Board sounds
  ///
  /// In en, this message translates to:
  /// **'Board sounds'**
  String get boardSounds;

  /// Chessnut sound setting. Illegal-move feedback occurs only after the physical move is completed, not while a piece is being lifted or moved. Describe the user-facing event naturally rather than literally translating "completed illegal moves".
  ///
  /// In en, this message translates to:
  /// **'Beep for check, checkmate, and completed illegal moves.'**
  String get beepForCheckCheckmateAndCompletedIllegalMoves;

  /// Settings: Copy diagnostics
  ///
  /// In en, this message translates to:
  /// **'Copy diagnostics'**
  String get copyDiagnostics;

  /// Settings: Diagnostics copied
  ///
  /// In en, this message translates to:
  /// **'Diagnostics copied'**
  String get diagnosticsCopied;

  /// Live game: New game
  ///
  /// In en, this message translates to:
  /// **'New game'**
  String get newGame;

  /// Live game: Reset game
  ///
  /// In en, this message translates to:
  /// **'Reset game'**
  String get resetGame;

  /// Live game: Share and export
  ///
  /// In en, this message translates to:
  /// **'Share and export'**
  String get shareAndExport;

  /// Live game: Save PGN file
  ///
  /// In en, this message translates to:
  /// **'Save PGN file'**
  String get savePgnFile;

  /// Live game: Share PGN
  ///
  /// In en, this message translates to:
  /// **'Share PGN'**
  String get sharePgn;

  /// Live game: Copy PGN
  ///
  /// In en, this message translates to:
  /// **'Copy PGN'**
  String get copyPgn;

  /// Live game: Copy FEN
  ///
  /// In en, this message translates to:
  /// **'Copy FEN'**
  String get copyFen;

  /// Live game: Maia error. Retry
  ///
  /// In en, this message translates to:
  /// **'Maia error. Retry'**
  String get maiaErrorRetry;

  /// Live game: Maia error. Please retry.
  ///
  /// In en, this message translates to:
  /// **'Maia error. Please retry.'**
  String get maiaErrorPleaseRetry;

  /// Live game: Retry
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Live game: Maia is thinking…
  ///
  /// In en, this message translates to:
  /// **'Maia is thinking…'**
  String get maiaIsThinking;

  /// Live game: HISTORY
  ///
  /// In en, this message translates to:
  /// **'HISTORY'**
  String get history;

  /// Live game: START
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get start;

  /// Live game: Chessnut status
  ///
  /// In en, this message translates to:
  /// **'Chessnut status'**
  String get chessnutStatus;

  /// Live game: Leave current game?
  ///
  /// In en, this message translates to:
  /// **'Leave current game?'**
  String get leaveCurrentGame;

  /// Live game: Your game will be kept in Recent games.
  ///
  /// In en, this message translates to:
  /// **'Your game will be kept in Recent games.'**
  String get yourGameWillBeKeptInRecentGames;

  /// Live game: Cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Live game: Continue
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// Live game: Start a new game?
  ///
  /// In en, this message translates to:
  /// **'Start a new game?'**
  String get startANewGame;

  /// Live game: Reset game?
  ///
  /// In en, this message translates to:
  /// **'Reset game?'**
  String get resetGameQuestion;

  /// Live game: Your completed game will remain in Recent Games.
  ///
  /// In en, this message translates to:
  /// **'Your completed game will remain in Recent Games.'**
  String get yourCompletedGameWillRemainInRecentGames;

  /// Live game: This game will be permanently erased.
  ///
  /// In en, this message translates to:
  /// **'This game will be permanently erased.'**
  String get thisGameWillBePermanentlyErased;

  /// Live game: Start new game
  ///
  /// In en, this message translates to:
  /// **'Start new game'**
  String get startNewGame;

  /// Live game: Reset
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Live game: Flip board
  ///
  /// In en, this message translates to:
  /// **'Flip board'**
  String get flipBoard;

  /// Live game: Offer draw
  ///
  /// In en, this message translates to:
  /// **'Offer draw'**
  String get offerDraw;

  /// Undo action. Depending on turn and board mode, this can undo one or two plies; avoid promising exactly one ply.
  ///
  /// In en, this message translates to:
  /// **'Takeback'**
  String get takeBackMove;

  /// Live game: White is victorious
  ///
  /// In en, this message translates to:
  /// **'White is victorious'**
  String get whiteIsVictorious;

  /// Live game: Black is victorious
  ///
  /// In en, this message translates to:
  /// **'Black is victorious'**
  String get blackIsVictorious;

  /// Live game: The game is a draw
  ///
  /// In en, this message translates to:
  /// **'The game is a draw'**
  String get theGameIsADraw;

  /// Live game: The game has ended
  ///
  /// In en, this message translates to:
  /// **'The game has ended'**
  String get theGameHasEnded;

  /// Live game: Rematch
  ///
  /// In en, this message translates to:
  /// **'Rematch'**
  String get rematch;

  /// Analysis quality: Fast
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get fast;

  /// Analysis quality: Balanced
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get balanced;

  /// Analysis quality: Thorough
  ///
  /// In en, this message translates to:
  /// **'Thorough'**
  String get thorough;

  /// Analysis Board / Review: Continue from here
  ///
  /// In en, this message translates to:
  /// **'Continue from here'**
  String get continueFromHere;

  /// Analysis Board / Review: Load
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get load;

  /// Analysis Board / Review: Edit Board
  ///
  /// In en, this message translates to:
  /// **'Edit Board'**
  String get editBoard;

  /// Analysis Board / Review: Done
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Analysis Board / Review: White pieces
  ///
  /// In en, this message translates to:
  /// **'White pieces'**
  String get whitePieces;

  /// Analysis Board / Review: Black pieces
  ///
  /// In en, this message translates to:
  /// **'Black pieces'**
  String get blackPieces;

  /// Analysis Board / Review: White to move
  ///
  /// In en, this message translates to:
  /// **'White to move'**
  String get whiteToMove;

  /// Analysis Board / Review: Black to move
  ///
  /// In en, this message translates to:
  /// **'Black to move'**
  String get blackToMove;

  /// Board editor heading for FEN castling rights retained by king/rooks. Rights do not mean castling is legal immediately: blocked squares or check may still prevent it.
  ///
  /// In en, this message translates to:
  /// **'Castling rights'**
  String get castlingRights;

  /// Board Editor castling-rights checkbox: whiteKingside. Kingside is short castling (O-O); queenside is long castling (O-O-O).
  ///
  /// In en, this message translates to:
  /// **'White kingside'**
  String get whiteKingside;

  /// Board Editor castling-rights checkbox: whiteQueenside. Kingside is short castling (O-O); queenside is long castling (O-O-O).
  ///
  /// In en, this message translates to:
  /// **'White queenside'**
  String get whiteQueenside;

  /// Board Editor castling-rights checkbox: blackKingside. Kingside is short castling (O-O); queenside is long castling (O-O-O).
  ///
  /// In en, this message translates to:
  /// **'Black kingside'**
  String get blackKingside;

  /// Board Editor castling-rights checkbox: blackQueenside. Kingside is short castling (O-O); queenside is long castling (O-O-O).
  ///
  /// In en, this message translates to:
  /// **'Black queenside'**
  String get blackQueenside;

  /// Analysis Board / Review: En-passant target
  ///
  /// In en, this message translates to:
  /// **'En-passant target'**
  String get enPassantTarget;

  /// Analysis Board / Review: Starting position
  ///
  /// In en, this message translates to:
  /// **'Starting position'**
  String get startingPosition;

  /// Analysis Board / Review: Clear board
  ///
  /// In en, this message translates to:
  /// **'Clear board'**
  String get clearBoard;

  /// Analysis Board / Review: Load FEN
  ///
  /// In en, this message translates to:
  /// **'Load FEN'**
  String get loadFen;

  /// Analysis Board / Review: Load PGN
  ///
  /// In en, this message translates to:
  /// **'Load PGN'**
  String get loadPgn;

  /// Analysis Board / Review: Open PGN file
  ///
  /// In en, this message translates to:
  /// **'Open PGN file'**
  String get openPgnFile;

  /// Analysis Board / Review: Clear moves
  ///
  /// In en, this message translates to:
  /// **'Clear moves'**
  String get clearMoves;

  /// Analysis Board / Review: Board Editor
  ///
  /// In en, this message translates to:
  /// **'Board Editor'**
  String get boardEditor;

  /// Analysis Board / Review: end position
  ///
  /// In en, this message translates to:
  /// **'end position'**
  String get endPosition;

  /// Analysis Board / Review: Analysis menu
  ///
  /// In en, this message translates to:
  /// **'Analysis menu'**
  String get analysisMenu;

  /// Analysis Board / Review: Turn engine off
  ///
  /// In en, this message translates to:
  /// **'Turn engine off'**
  String get turnEngineOff;

  /// Analysis Board / Review: Turn engine on
  ///
  /// In en, this message translates to:
  /// **'Turn engine on'**
  String get turnEngineOn;

  /// Analysis Board / Review: Moves
  ///
  /// In en, this message translates to:
  /// **'Moves'**
  String get moves;

  /// Analysis Board / Review: Computer analysis
  ///
  /// In en, this message translates to:
  /// **'Computer analysis'**
  String get computerAnalysis;

  /// Analysis Board / Review: Back to game
  ///
  /// In en, this message translates to:
  /// **'Back to game'**
  String get backToGame;

  /// Analysis and review UI: Expand variations
  ///
  /// In en, this message translates to:
  /// **'Expand variations'**
  String get expandVariations;

  /// Analysis and review UI: Collapse variations
  ///
  /// In en, this message translates to:
  /// **'Collapse variations'**
  String get collapseVariations;

  /// Review-tree action: promote a variation one parent level; a top-level variation moves to the first position. Not pawn promotion. Distinct from Make main line, which promotes repeatedly to the top.
  ///
  /// In en, this message translates to:
  /// **'Promote variation'**
  String get promoteVariation;

  /// Review-tree action: promote a variation repeatedly until it becomes the main line. This changes the displayed analysis tree, not the historical moves actually played.
  ///
  /// In en, this message translates to:
  /// **'Make main line'**
  String get makeMainLine;

  /// Analysis and review UI: Delete from here
  ///
  /// In en, this message translates to:
  /// **'Delete from here'**
  String get deleteFromHere;

  /// Analysis and review UI: Analyzing…
  ///
  /// In en, this message translates to:
  /// **'Analyzing…'**
  String get analyzing;

  /// Analysis and review UI: No legal moves
  ///
  /// In en, this message translates to:
  /// **'No legal moves'**
  String get noLegalMoves;

  /// Analysis and review UI: Unavailable
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// Analysis and review UI: Analysis failed. Please retry.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed. Please retry.'**
  String get analysisFailed;

  /// Analysis and review UI: Computer analysis stopped.
  ///
  /// In en, this message translates to:
  /// **'Computer analysis stopped.'**
  String get analysisStopped;

  /// Analysis and review UI: Classifying moves…
  ///
  /// In en, this message translates to:
  /// **'Classifying moves…'**
  String get classifyingMoves;

  /// Analysis and review UI: Graph ready · classifying moves…
  ///
  /// In en, this message translates to:
  /// **'Graph ready · classifying moves…'**
  String get graphReadyClassifying;

  /// Analysis and review UI: Stop analysis
  ///
  /// In en, this message translates to:
  /// **'Stop analysis'**
  String get stopAnalysis;

  /// Analysis and review UI: Run computer analysis again
  ///
  /// In en, this message translates to:
  /// **'Run computer analysis again'**
  String get runAnalysisAgain;

  /// Analysis and review UI: Run computer analysis
  ///
  /// In en, this message translates to:
  /// **'Run computer analysis'**
  String get runAnalysis;

  /// Analysis and review UI: Run computer analysis to generate the evaluation graph and White/Black accuracy.
  ///
  /// In en, this message translates to:
  /// **'Run computer analysis to generate the evaluation graph and White/Black accuracy.'**
  String get analysisExplanation;

  /// Play screen: PGN copied
  ///
  /// In en, this message translates to:
  /// **'PGN copied'**
  String get pgnCopied;

  /// Play screen: FEN copied
  ///
  /// In en, this message translates to:
  /// **'FEN copied'**
  String get fenCopied;

  /// Analysis and review UI: Raw model probabilities normalized across every legal move. Temperature and Top-P are not applied.
  ///
  /// In en, this message translates to:
  /// **'Raw model probabilities normalized across every legal move. Temperature and Top-P are not applied.'**
  String get rawProbabilitiesExplanation;

  /// Analysis and review UI: Show full raw model probabilities
  ///
  /// In en, this message translates to:
  /// **'Show full raw model probabilities'**
  String get showRawProbabilities;

  /// Analysis and review UI: Paste a complete six-field FEN
  ///
  /// In en, this message translates to:
  /// **'Paste a complete six-field FEN'**
  String get pasteFen;

  /// Analysis and review UI: Paste a PGN game
  ///
  /// In en, this message translates to:
  /// **'Paste a PGN game'**
  String get pastePgn;

  /// Analysis and review UI: Invalid position. Check the board and FEN.
  ///
  /// In en, this message translates to:
  /// **'Invalid position. Check the board and FEN.'**
  String get invalidPosition;

  /// Analysis and review UI: Could not load the PGN game. Check the file or pasted text.
  ///
  /// In en, this message translates to:
  /// **'Could not load the PGN game. Check the file or pasted text.'**
  String get pgnLoadFailed;

  /// Analysis and review UI: Go to next
  ///
  /// In en, this message translates to:
  /// **'Go to next'**
  String get goToNext;

  /// Analysis and review UI: {label} · tap for next
  ///
  /// In en, this message translates to:
  /// **'{label} · tap for next'**
  String tapForNext(String label);

  /// Analysis and review UI: Not enough moves
  ///
  /// In en, this message translates to:
  /// **'Not enough moves'**
  String get notEnoughMoves;

  /// Analysis and review UI: Game accuracy
  ///
  /// In en, this message translates to:
  /// **'Game accuracy'**
  String get gameAccuracy;

  /// Analysis and review UI: Accuracy
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracy;

  /// Analysis and review UI: Computer analysis graph
  ///
  /// In en, this message translates to:
  /// **'Computer analysis graph'**
  String get analysisGraph;

  /// Analysis and review UI: Maia {elo} move probabilities
  ///
  /// In en, this message translates to:
  /// **'Maia {elo} move probabilities'**
  String maiaMoveProbabilities(int elo);

  /// Analysis and review UI: Other {probability}
  ///
  /// In en, this message translates to:
  /// **'Other {probability}'**
  String otherProbability(String probability);

  /// Analysis and review UI: other legal moves {probability}
  ///
  /// In en, this message translates to:
  /// **'other legal moves {probability}'**
  String otherLegalProbability(String probability);

  /// Analysis and review UI: {title}. {moves}.
  ///
  /// In en, this message translates to:
  /// **'{title}. {moves}.'**
  String maiaProbabilitySemantics(String title, String moves);

  /// Analysis and review UI: Analyzing {completed} of {total} positions…
  ///
  /// In en, this message translates to:
  /// **'Analyzing {completed} of {total} positions…'**
  String analysisProgress(int completed, int total);

  /// Analysis and review UI: Position {position} of {total}, {score}
  ///
  /// In en, this message translates to:
  /// **'Position {position} of {total}  ·  {score}'**
  String graphPosition(int position, int total, String score);

  /// Analysis and review UI: Position {position}
  ///
  /// In en, this message translates to:
  /// **'Position {position}'**
  String positionNumber(int position);

  /// Analysis and review UI: {count, plural, one{{count} {side} {classification} move} other{{count} {side} {classification} moves}}
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} {side} {classification} move} other{{count} {side} {classification} moves}}'**
  String classificationCount(int count, String side, String classification);

  /// Chess annotation !! (brilliant move). Describes the move, not praise addressed to the player. Keep distinct from good (!).
  ///
  /// In en, this message translates to:
  /// **'Brilliant'**
  String get classificationBrilliant;

  /// Chess annotation ! (good move). Keep distinct from brilliant (!!).
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get classificationGood;

  /// Chess annotation !? (interesting move, deserving attention). Not a claim that the move is entertaining, and not the dubious ?! category.
  ///
  /// In en, this message translates to:
  /// **'Interesting'**
  String get classificationInteresting;

  /// Chess annotation ?! (dubious or questionable move). Keep distinct from interesting (!?), mistake (?) and blunder (??).
  ///
  /// In en, this message translates to:
  /// **'Dubious'**
  String get classificationDubious;

  /// Chess annotation ? (mistake). Less severe than blunder (??).
  ///
  /// In en, this message translates to:
  /// **'Mistake'**
  String get classificationMistake;

  /// Chess annotation ?? (blunder, serious mistake). More severe than mistake (?).
  ///
  /// In en, this message translates to:
  /// **'Blunder'**
  String get classificationBlunder;

  /// Analysis and review UI: Game review
  ///
  /// In en, this message translates to:
  /// **'Game review'**
  String get gameReview;

  /// Analysis and review UI: {count, plural, one{{count} pawn} other{{count} pawns}}
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} pawn} other{{count} pawns}}'**
  String materialPawn(int count);

  /// Analysis and review UI: {count, plural, one{{count} knight} other{{count} knights}}
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} knight} other{{count} knights}}'**
  String materialKnight(int count);

  /// Analysis and review UI: {count, plural, one{{count} bishop} other{{count} bishops}}
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} bishop} other{{count} bishops}}'**
  String materialBishop(int count);

  /// Analysis and review UI: {count, plural, one{{count} rook} other{{count} rooks}}
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} rook} other{{count} rooks}}'**
  String materialRook(int count);

  /// Analysis and review UI: {count, plural, one{{count} queen} other{{count} queens}}
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} queen} other{{count} queens}}'**
  String materialQueen(int count);

  /// Analysis and review UI: {score} material advantage
  ///
  /// In en, this message translates to:
  /// **'{score} material advantage'**
  String materialAdvantage(String score);

  /// Spoken board label for this side's material difference relative to the opponent, not its entire remaining army. {side} is White/Black; {description} lists extra pieces and any material advantage score.
  ///
  /// In en, this message translates to:
  /// **'{side} material: {description}'**
  String materialDescription(String side, String description);

  /// Analysis and review UI: Previous move
  ///
  /// In en, this message translates to:
  /// **'Previous move'**
  String get previousMove;

  /// Analysis and review UI: Next move
  ///
  /// In en, this message translates to:
  /// **'Next move'**
  String get nextMove;

  /// Analysis and review UI: beginning
  ///
  /// In en, this message translates to:
  /// **'beginning'**
  String get beginning;

  /// Analysis and review UI: latest position
  ///
  /// In en, this message translates to:
  /// **'latest position'**
  String get latestPosition;

  /// Analysis and review UI: Hold for {destination}
  ///
  /// In en, this message translates to:
  /// **'Hold for {destination}'**
  String holdForDestination(String destination);

  /// Chess review UI: Opening
  ///
  /// In en, this message translates to:
  /// **'Opening'**
  String get phaseOpening;

  /// Chess review UI: Middlegame
  ///
  /// In en, this message translates to:
  /// **'Middlegame'**
  String get phaseMiddlegame;

  /// Chess review UI: Endgame
  ///
  /// In en, this message translates to:
  /// **'Endgame'**
  String get phaseEndgame;

  /// Chess review UI: King
  ///
  /// In en, this message translates to:
  /// **'King'**
  String get pieceKing;

  /// Chess review UI: Queen
  ///
  /// In en, this message translates to:
  /// **'Queen'**
  String get pieceQueen;

  /// Chess review UI: Rook
  ///
  /// In en, this message translates to:
  /// **'Rook'**
  String get pieceRook;

  /// Chess review UI: Bishop
  ///
  /// In en, this message translates to:
  /// **'Bishop'**
  String get pieceBishop;

  /// Chess review UI: Knight
  ///
  /// In en, this message translates to:
  /// **'Knight'**
  String get pieceKnight;

  /// Chess review UI: Pawn
  ///
  /// In en, this message translates to:
  /// **'Pawn'**
  String get piecePawn;

  /// Recent Games display only; preserve canonical game/PGN data.
  ///
  /// In en, this message translates to:
  /// **'Player — Maia {rating}'**
  String recentPlayerMaia(String rating);

  /// Recent Games display only; preserve canonical game/PGN data.
  ///
  /// In en, this message translates to:
  /// **'Maia {rating} — Player'**
  String recentMaiaPlayer(String rating);

  /// Recent Games display only; preserve canonical game/PGN data.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get recentIncomplete;

  /// Recent Games display only; preserve canonical game/PGN data.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get recentCompleted;

  /// Recent Games display only; preserve canonical game/PGN data.
  ///
  /// In en, this message translates to:
  /// **'Could not delete saved games. Please try again.'**
  String get recentDeleteFailed;

  /// Recent Games display only; preserve canonical game/PGN data.
  ///
  /// In en, this message translates to:
  /// **'Could not open saved game. Please try again.'**
  String get recentOpenFailed;

  /// Recent Games display only; preserve canonical game/PGN data.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Delete saved game?} other{Delete {count} games?}}'**
  String recentDeleteTitle(num count);

  /// Recent Games display only; preserve canonical game/PGN data.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{This saved game will be permanently deleted.} other{These {count} saved games will be permanently deleted.}}'**
  String recentDeleteWarning(num count);

  /// User-facing diagnostic or PGN operation text. Diagnostic logs remain canonical.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// Recent Games display only; preserve canonical game/PGN data.
  ///
  /// In en, this message translates to:
  /// **'Updating saved games'**
  String get recentUpdating;

  /// Recent Games display only; preserve canonical game/PGN data.
  ///
  /// In en, this message translates to:
  /// **'Cancel selection'**
  String get recentCancelSelection;

  /// Recent Games display only; preserve canonical game/PGN data.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get recentClearSelection;

  /// Recent Games display only; preserve canonical game/PGN data.
  ///
  /// In en, this message translates to:
  /// **'Select all games'**
  String get recentSelectAll;

  /// Recent Games display only; preserve canonical game/PGN data.
  ///
  /// In en, this message translates to:
  /// **'Delete selected games'**
  String get recentDeleteSelected;

  /// Recent Games display only; preserve canonical game/PGN data.
  ///
  /// In en, this message translates to:
  /// **'Select games'**
  String get recentSelectGames;

  /// Recent Games display only; preserve canonical game/PGN data.
  ///
  /// In en, this message translates to:
  /// **'Delete all games'**
  String get recentDeleteAll;

  /// Recent Games display only; preserve canonical game/PGN data.
  ///
  /// In en, this message translates to:
  /// **'Delete saved game'**
  String get recentDeleteOne;

  /// Recent Games display only; preserve canonical game/PGN data.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String recentSelectedCount(num count);

  /// Recent Games display only; preserve canonical game/PGN data.
  ///
  /// In en, this message translates to:
  /// **'Could not load saved games. Please try again.'**
  String get recentLoadFailed;

  /// Recent Games display only; preserve canonical game/PGN data.
  ///
  /// In en, this message translates to:
  /// **'Completed games and incomplete games saved from Home will appear here.'**
  String get recentEmpty;

  /// Recent Games display only; preserve canonical game/PGN data.
  ///
  /// In en, this message translates to:
  /// **'{result} · {date}'**
  String recentGameSummary(String result, String date);

  /// User-facing diagnostic or PGN operation text. Diagnostic logs remain canonical.
  ///
  /// In en, this message translates to:
  /// **'Mobile Maia encountered a screen error.'**
  String get diagnosticsScreenError;

  /// User-facing diagnostic or PGN operation text. Diagnostic logs remain canonical.
  ///
  /// In en, this message translates to:
  /// **'Copy the diagnostics and send them with a description of what you tapped immediately before this screen appeared.'**
  String get diagnosticsScreenInstructions;

  /// User-facing diagnostic or PGN operation text. Diagnostic logs remain canonical.
  ///
  /// In en, this message translates to:
  /// **'PGN saved'**
  String get pgnSaved;

  /// User-facing diagnostic or PGN operation text. Diagnostic logs remain canonical.
  ///
  /// In en, this message translates to:
  /// **'Could not export PGN. Your game is still saved locally.'**
  String get pgnExportFailed;

  /// Inline Settings warning when reading or writing the language preference fails. The current in-memory language remains usable.
  ///
  /// In en, this message translates to:
  /// **'The language could not be saved or restored. Your games are unaffected. Please try selecting the language again.'**
  String get languagePreferenceError;

  /// Localized play label with numeric display values or canonical chess moves.
  ///
  /// In en, this message translates to:
  /// **'Play Maia rating: {rating}'**
  String playRatingValue(String rating);

  /// Localized play label with numeric display values or canonical chess moves.
  ///
  /// In en, this message translates to:
  /// **'Minutes: {minutes}'**
  String minutesValue(String minutes);

  /// Localized play label with numeric display values or canonical chess moves.
  ///
  /// In en, this message translates to:
  /// **'Increment: {seconds} seconds'**
  String incrementSecondsValue(String seconds);

  /// Play screen: Choose your settings and start a game.
  ///
  /// In en, this message translates to:
  /// **'Choose your settings and start a game.'**
  String get chooseSettings;

  /// Play screen: Game restored.
  ///
  /// In en, this message translates to:
  /// **'Game restored.'**
  String get gameRestored;

  /// Play screen: Reconnect Chessnut to continue.
  ///
  /// In en, this message translates to:
  /// **'Reconnect Chessnut to continue.'**
  String get reconnectChessnut;

  /// Play screen: Chessnut connection error.
  ///
  /// In en, this message translates to:
  /// **'Chessnut connection error.'**
  String get chessnutConnectionError;

  /// Play screen: Searching for Chessnut…
  ///
  /// In en, this message translates to:
  /// **'Searching for Chessnut…'**
  String get searchingChessnut;

  /// Play screen: Could not connect Chessnut.
  ///
  /// In en, this message translates to:
  /// **'Could not connect Chessnut.'**
  String get couldNotConnectChessnut;

  /// Play screen: Chessnut support is available on Android.
  ///
  /// In en, this message translates to:
  /// **'Chessnut support is available on Android.'**
  String get chessnutAndroidOnly;

  /// Play screen: Chessnut is disconnected.
  ///
  /// In en, this message translates to:
  /// **'Chessnut is disconnected.'**
  String get chessnutIsDisconnected;

  /// Play screen: Your move.
  ///
  /// In en, this message translates to:
  /// **'Your turn.'**
  String get yourMove;

  /// Play screen: Your move on Chessnut.
  ///
  /// In en, this message translates to:
  /// **'Your turn on Chessnut.'**
  String get yourMoveChessnut;

  /// Play screen: Chessnut is ready.
  ///
  /// In en, this message translates to:
  /// **'Chessnut is ready.'**
  String get chessnutReady;

  /// Play screen: Set up the standard starting position on Chessnut.
  ///
  /// In en, this message translates to:
  /// **'Set up the standard starting position on Chessnut.'**
  String get chessnutStartingPosition;

  /// Play screen: Takeback complete. Your move on Chessnut.
  ///
  /// In en, this message translates to:
  /// **'Takeback complete. Your turn on Chessnut.'**
  String get takebackCompleteYourMove;

  /// Play screen: Takeback complete. Maia is thinking…
  ///
  /// In en, this message translates to:
  /// **'Takeback complete. Maia is thinking…'**
  String get takebackCompleteThinking;

  /// Play screen: Takeback: restore the lit squares on Chessnut.
  ///
  /// In en, this message translates to:
  /// **'Takeback: restore the lit squares on Chessnut.'**
  String get restoreLitSquares;

  /// Play screen: Complete Maia’s lit move on Chessnut.
  ///
  /// In en, this message translates to:
  /// **'Complete Maia’s lit move on Chessnut.'**
  String get completeMaiaLitMove;

  /// Play screen: That position is not a legal move. Correct the lit squares.
  ///
  /// In en, this message translates to:
  /// **'That position is not a legal move. Correct the lit squares.'**
  String get illegalChessnutPosition;

  /// Play screen: Complete your move on Chessnut.
  ///
  /// In en, this message translates to:
  /// **'Complete your move on Chessnut.'**
  String get completeYourChessnutMove;

  /// Play screen: Connect Chessnut before starting.
  ///
  /// In en, this message translates to:
  /// **'Connect Chessnut before starting.'**
  String get connectChessnutFirst;

  /// Play screen: Game in progress.
  ///
  /// In en, this message translates to:
  /// **'Game in progress.'**
  String get gameInProgress;

  /// Play screen: Draw — timeout against insufficient material.
  ///
  /// In en, this message translates to:
  /// **'Draw — timeout against insufficient material.'**
  String get timeoutInsufficientMaterial;

  /// Play screen: White ran out of time.
  ///
  /// In en, this message translates to:
  /// **'White ran out of time.'**
  String get whiteOutOfTime;

  /// Play screen: Black ran out of time.
  ///
  /// In en, this message translates to:
  /// **'Black ran out of time.'**
  String get blackOutOfTime;

  /// Play screen: Make Maia’s lit move on Chessnut.
  ///
  /// In en, this message translates to:
  /// **'Make Maia’s lit move on Chessnut.'**
  String get makeMaiaLitMove;

  /// Play screen: Checkmate — Maia wins.
  ///
  /// In en, this message translates to:
  /// **'Checkmate — Maia wins.'**
  String get checkmateMaiaWins;

  /// Play screen: Checkmate — you win!
  ///
  /// In en, this message translates to:
  /// **'Checkmate — you win!'**
  String get checkmateYouWin;

  /// Play screen: Draw.
  ///
  /// In en, this message translates to:
  /// **'Draw.'**
  String get drawResult;

  /// Play screen: Draw by agreement.
  ///
  /// In en, this message translates to:
  /// **'Draw by agreement.'**
  String get drawByAgreement;

  /// Play screen: You win.
  ///
  /// In en, this message translates to:
  /// **'You win.'**
  String get youWin;

  /// Play screen: Maia wins.
  ///
  /// In en, this message translates to:
  /// **'Maia wins.'**
  String get maiaWins;

  /// Play screen: Game ended.
  ///
  /// In en, this message translates to:
  /// **'Game ended.'**
  String get gameEnded;

  /// Play screen: Maia is considering the draw offer…
  ///
  /// In en, this message translates to:
  /// **'Maia is considering the draw offer…'**
  String get consideringDraw;

  /// Play screen: Maia declined the draw.
  ///
  /// In en, this message translates to:
  /// **'Maia declined the draw.'**
  String get maiaDeclinedDraw;

  /// Play screen: Could not evaluate the draw offer.
  ///
  /// In en, this message translates to:
  /// **'Could not evaluate the draw offer.'**
  String get couldNotEvaluateDraw;

  /// Play screen: You resigned — Maia wins.
  ///
  /// In en, this message translates to:
  /// **'You resigned — Maia wins.'**
  String get youResigned;

  /// Play screen: Move taken back. Your move.
  ///
  /// In en, this message translates to:
  /// **'Move taken back. Your turn.'**
  String get moveTakenBack;

  /// Play screen: Connecting to Chessnut…
  ///
  /// In en, this message translates to:
  /// **'Connecting to Chessnut…'**
  String get connectingChessnut;

  /// Play screen: Chessnut unavailable
  ///
  /// In en, this message translates to:
  /// **'Chessnut unavailable'**
  String get chessnutUnavailable;

  /// Play screen: Chessnut disconnected
  ///
  /// In en, this message translates to:
  /// **'Chessnut disconnected'**
  String get chessnutDisconnected;

  /// Play screen: Reconnect
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get reconnect;

  /// Play screen: Play in app
  ///
  /// In en, this message translates to:
  /// **'Play in app'**
  String get playInApp;

  /// Play screen: Continue this game on screen
  ///
  /// In en, this message translates to:
  /// **'Continue this game on screen'**
  String get continueGameOnScreen;

  /// Play screen: Check, checkmate, and illegal moves
  ///
  /// In en, this message translates to:
  /// **'Check, checkmate, and illegal moves'**
  String get checkCheckmateIllegalMoves;

  /// Play screen: Offer draw?
  ///
  /// In en, this message translates to:
  /// **'Offer draw?'**
  String get offerDrawQuestion;

  /// Play screen: Resign game?
  ///
  /// In en, this message translates to:
  /// **'Resign game?'**
  String get resignGameQuestion;

  /// Play screen: This will end the game immediately.
  ///
  /// In en, this message translates to:
  /// **'This will end the game immediately.'**
  String get resignEndsImmediately;

  /// Play screen: Up to 64 premoves can be queued.
  ///
  /// In en, this message translates to:
  /// **'Up to 64 premoves can be queued.'**
  String get premoveLimit;

  /// Play screen: Chessnut play supports standard-position, unlimited games only.
  ///
  /// In en, this message translates to:
  /// **'Chessnut play supports standard-position, unlimited games only.'**
  String get chessnutGameRestriction;

  /// Play screen: Temperature and Top-P
  ///
  /// In en, this message translates to:
  /// **'Temperature and Top-P'**
  String get samplingTitle;

  /// Play screen: Why Temperature 1.00 and Top-P 1.00?
  ///
  /// In en, this message translates to:
  /// **'Why Temperature 1.00 and Top-P 1.00?'**
  String get samplingDefaultsQuestion;

  /// Play screen: Read the sampling research
  ///
  /// In en, this message translates to:
  /// **'Read the sampling research'**
  String get samplingResearch;

  /// Play screen: Close
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Play screen: Unknown version
  ///
  /// In en, this message translates to:
  /// **'Unknown version'**
  String get unknownVersion;

  /// Play screen: Maia-3 project and source code
  ///
  /// In en, this message translates to:
  /// **'Maia-3 project and source code'**
  String get maiaProjectSource;

  /// Play screen: En Croissant project and source code
  ///
  /// In en, this message translates to:
  /// **'En Croissant project and source code'**
  String get enCroissantProjectSource;

  /// Play screen: Licence
  ///
  /// In en, this message translates to:
  /// **'Licence'**
  String get licence;

  /// Play screen: Mobile Maia source code
  ///
  /// In en, this message translates to:
  /// **'Mobile Maia source code'**
  String get mobileMaiaSource;

  /// Play help, about or error message: These settings let Maia use its full range of predicted human moves. In our tests at the 1600 setting, they produced opening choices much closer to rating-filtered Lichess games.
  ///
  /// In en, this message translates to:
  /// **'These settings let Maia use its full range of predicted human moves. In our tests at the 1600 setting, they produced opening choices much closer to rating-filtered Lichess games.'**
  String get samplingFullRange;

  /// Play help, about or error message: Lower settings reduce variety and can make Maia stronger. We favor a more human opening repertoire over maximum strength. Maia’s rating describes the players it models, rather than guaranteeing an exact playing strength.
  ///
  /// In en, this message translates to:
  /// **'Lower settings reduce variety and can make Maia stronger. We favor a more human opening repertoire over maximum strength. Maia’s rating describes the players it models, rather than guaranteeing an exact playing strength.'**
  String get samplingStrength;

  /// Play help, about or error message: Temperature controls how adventurous Maia is. At 0, Maia always chooses its most likely human move. Higher values make less likely moves more common.
  ///
  /// In en, this message translates to:
  /// **'Temperature controls how concentrated Maia’s move probabilities are. At 0, Maia always chooses the move the model predicts humans are most likely to play. Lower positive values favor the most likely moves more strongly; higher values give less likely moves more chance.'**
  String get samplingTemperatureHelp;

  /// Play help, about or error message: Top-P limits Maia to the smallest group of moves whose combined probability reaches this value. Lower values narrow the choice to more likely moves; 1.00 keeps every legal move.
  ///
  /// In en, this message translates to:
  /// **'Top-P ranks moves from most to least likely, then keeps the smallest leading group whose combined probability reaches this value. Lower values restrict the choice to more likely moves; 1.00 keeps every legal move.'**
  String get samplingTopPHelp;

  /// Play help, about or error message: Powered by Maia-3, the human-like chess engine developed by the University of Toronto Computational Social Science Lab.
  ///
  /// In en, this message translates to:
  /// **'Powered by Maia-3, the human-like chess engine developed by the University of Toronto Computational Social Science Lab.'**
  String get aboutPoweredBy;

  /// Play help, about or error message: Maia-3 runs entirely on your phone. No account or network connection is required.
  ///
  /// In en, this message translates to:
  /// **'Maia-3 runs entirely on your phone. No account or network connection is required.'**
  String get aboutOffline;

  /// Play help, about or error message: Board interface, default brown theme, and Cburnett pieces are provided by Lichess Flutter Chessground. Local Stockfish support uses Lichess multistockfish.
  ///
  /// In en, this message translates to:
  /// **'Board interface, default brown theme, and Cburnett pieces are provided by Lichess Flutter Chessground. Local Stockfish support uses Lichess multistockfish.'**
  String get aboutBoardCredits;

  /// Play help, about or error message: Game Review move classification and sacrifice-detection heuristics are adapted from the En Croissant open-source chess GUI.
  ///
  /// In en, this message translates to:
  /// **'Game Review move classification and sacrifice-detection heuristics are adapted from the En Croissant open-source chess GUI.'**
  String get aboutReviewCredits;

  /// Play help, about or error message: Mobile Maia is free software distributed under AGPL-3.0-only, without any warranty. You may redistribute and modify it under the terms of that licence. The complete source code is available from the project repository.
  ///
  /// In en, this message translates to:
  /// **'Mobile Maia is free software distributed under AGPL-3.0-only, without any warranty. You may redistribute and modify it under the terms of that licence. The complete source code is available from the project repository.'**
  String get aboutLicence;

  /// Play help, about or error message: This independent community app is not an official Maia-3 or University of Toronto, Lichess, or En Croissant application.
  ///
  /// In en, this message translates to:
  /// **'This independent community app is not an official Maia-3 or University of Toronto, Lichess, or En Croissant application.'**
  String get aboutIndependent;

  /// Play help, about or error message: Temperature or Top-P differs from the recommended 1.00. See the information button for details.
  ///
  /// In en, this message translates to:
  /// **'Temperature or Top-P differs from the recommended 1.00. See the information button for details.'**
  String get samplingRecommendationWarning;

  /// Play help, about or error message: Could not open PGN.
  ///
  /// In en, this message translates to:
  /// **'Could not open PGN.'**
  String get couldNotOpenPgn;

  /// Localized play label with numeric display values or canonical chess moves.
  ///
  /// In en, this message translates to:
  /// **'Temperature: {value}'**
  String temperatureValue(String value);

  /// Localized play label with numeric display values or canonical chess moves.
  ///
  /// In en, this message translates to:
  /// **'Top-P: {value}'**
  String topPValue(String value);

  /// Localized play label with numeric display values or canonical chess moves.
  ///
  /// In en, this message translates to:
  /// **'Maia analysis rating: {rating}'**
  String analysisRatingValue(String rating);

  /// Localized play label with numeric display values or canonical chess moves.
  ///
  /// In en, this message translates to:
  /// **'Second Maia analysis rating: {rating}'**
  String secondAnalysisRatingValue(String rating);

  /// Localized play label with numeric display values or canonical chess moves.
  ///
  /// In en, this message translates to:
  /// **'Premoves: {moves}'**
  String premovesList(String moves);

  /// Localized play label with numeric display values or canonical chess moves.
  ///
  /// In en, this message translates to:
  /// **'Maia3 {rating}elo'**
  String maiaOpponentRating(String rating);

  /// Localized play label with numeric display values or canonical chess moves.
  ///
  /// In en, this message translates to:
  /// **'Depth {depth} · up to {seconds} seconds per position, plus up to {extraSeconds} seconds checking standout moves.'**
  String analysisQualityDetails(
    String depth,
    String seconds,
    String extraSeconds,
  );

  /// Localized play label with numeric display values or canonical chess moves.
  ///
  /// In en, this message translates to:
  /// **'{percent}%{charging, select, yes{ ⚡} other{}}'**
  String chessnutBattery(String percent, String charging);

  /// Actionable Chessnut connection failure; native diagnostic details are recorded separately.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is unavailable on this device.'**
  String get chessnutBluetoothUnavailable;

  /// Actionable Chessnut connection failure; native diagnostic details are recorded separately.
  ///
  /// In en, this message translates to:
  /// **'Allow Bluetooth permissions, then reconnect Chessnut.'**
  String get chessnutPermissionPending;

  /// Actionable Chessnut connection failure; native diagnostic details are recorded separately.
  ///
  /// In en, this message translates to:
  /// **'Turn on Bluetooth, then reconnect Chessnut.'**
  String get chessnutBluetoothDisabled;

  /// Compact chess-side column header in classification summary. White/black initials or one-character labels; full localized side names remain in accessibility labels.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get whiteShort;

  /// Compact chess-side column header in classification summary. White/black initials or one-character labels; full localized side names remain in accessibility labels.
  ///
  /// In en, this message translates to:
  /// **'B'**
  String get blackShort;

  /// Recent Games date when no trustworthy original calendar date can be recovered. Do not imply today or last saved.
  ///
  /// In en, this message translates to:
  /// **'Date unknown'**
  String get dateUnknown;

  /// Persistent warning when a saved session or its backup uses an unsupported format. Creation is blocked to protect the files; update the app, never delete or overwrite automatically.
  ///
  /// In en, this message translates to:
  /// **'This saved data uses an unsupported format. Update Mobile Maia to open it. This data has been preserved.'**
  String get savedGameVersionUnsupported;

  /// Recoverable saved-game storage access/write failure. Do not promise the current game was written successfully; starting a new game is aborted.
  ///
  /// In en, this message translates to:
  /// **'Could not access saved-game storage. Please try again.'**
  String get gameStorageFailed;

  /// Screen-reader description of a saved game result, from the human player's perspective. Only spoken; visible text remains standard chess result notation.
  ///
  /// In en, this message translates to:
  /// **'Win ({result})'**
  String recentWinResult(String result);

  /// Screen-reader description of a saved game result, from the human player's perspective. Only spoken; visible text remains standard chess result notation.
  ///
  /// In en, this message translates to:
  /// **'Loss ({result})'**
  String recentLossResult(String result);

  /// Screen-reader description of a saved game result, from the human player's perspective. Only spoken; visible text remains standard chess result notation.
  ///
  /// In en, this message translates to:
  /// **'Draw ({result})'**
  String recentDrawResult(String result);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'ja',
    'ko',
    'pt',
    'ru',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

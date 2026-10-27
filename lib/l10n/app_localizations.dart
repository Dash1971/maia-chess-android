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

  /// System-default option in the LANGUAGE selector only. Follows the supported device-language preference. Never reuse for theme/brightness; use appearanceSystemDefault there.
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

  /// AI sampling temperature: rescales legal-move logits before softmax; not physical device temperature. At zero Maia selects an argmax. Use the same localized term in help, value announcements and HTML reports. Official localized AI terminology sources: docs/TRANSLATION_QUALITY_REVIEW.md.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// Top-P (nucleus sampling): retain the smallest highest-probability candidate set whose cumulative probability reaches P, including the crossing move. Keep the conventional Top-P identifier. Not a per-move percentage cutoff. Official AI terminology sources: docs/TRANSLATION_QUALITY_REVIEW.md.
  ///
  /// In en, this message translates to:
  /// **'Top-P'**
  String get topP;

  /// Settings: maximize opening variety for the first five moves by each side
  ///
  /// In en, this message translates to:
  /// **'Max variety in opening'**
  String get maxOpeningVariety;

  /// Maia-specific sampling guidance for the 2.5 default proposal. Preserve probability mass versus individual move probability, the five-full-move boundary and conditional direct-match strength claims. Not a Lichess equivalent. Explanation selector changes prose only.
  ///
  /// In en, this message translates to:
  /// **'On by default. Uses Temperature and Top-P 1.0 / 1.0 for the first five moves by each side, then your configured settings from move 6. This keeps broad opening choices while allowing you to trim low-probability moves later. It follows the position’s move number, including when resuming or continuing a game.\n\nNot needed at 1.0 / 1.0: the switch is off and unavailable because those settings already give full variety throughout.'**
  String get maxOpeningVarietyHelp;

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

  /// Settings: Reset settings on this screen to their defaults
  ///
  /// In en, this message translates to:
  /// **'Reset settings to default'**
  String get resetSettingsDefaults;

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

  /// Destination in the navigation hint Hold for main line. Returns from a variation to its main-line branch point without changing moves.
  ///
  /// In en, this message translates to:
  /// **'main line'**
  String get mainLine;

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

  /// Play screen: Chessnut games have no clock.
  ///
  /// In en, this message translates to:
  /// **'Chessnut games use unlimited time.'**
  String get chessnutGameRestriction;

  /// Play screen: Temperature and Top-P
  ///
  /// In en, this message translates to:
  /// **'Temperature and Top-P'**
  String get samplingTitle;

  /// Maia-specific sampling help: Choose how much variety you want
  ///
  /// In en, this message translates to:
  /// **'Choose how much variety you want'**
  String get samplingDefaultsQuestion;

  /// Maia-specific offline sampling report; use Lichess vocabulary where the action matches.
  ///
  /// In en, this message translates to:
  /// **'Full research data (JSONL)'**
  String get samplingResearch;

  /// Maia-specific sampling guidance for the 2.5 default proposal. Preserve probability mass versus individual move probability, the five-full-move boundary and conditional direct-match strength claims. Not a Lichess equivalent. Explanation selector changes prose only.
  ///
  /// In en, this message translates to:
  /// **'Visual guide and research'**
  String get samplingResearchLink;

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

  /// Maia-specific sampling guidance for the 2.5 default proposal. Preserve probability mass versus individual move probability, the five-full-move boundary and conditional direct-match strength claims. Not a Lichess equivalent. Explanation selector changes prose only.
  ///
  /// In en, this message translates to:
  /// **'Maia may play a more limited opening repertoire with Max variety in opening disabled.'**
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

  /// Electronic board Dev support: Experimental electronic-board settings section title; includes occupancy-only and motorized boards.
  ///
  /// In en, this message translates to:
  /// **'Electronic board (experimental)'**
  String get electronicBoardExperimental;

  /// Electronic board Dev support: Button that opens electronic-board scan and connection flow.
  ///
  /// In en, this message translates to:
  /// **'Connect board'**
  String get connectBoard;

  /// Electronic board Dev support: Discovered-board picker title.
  ///
  /// In en, this message translates to:
  /// **'Choose a board'**
  String get chooseBoard;

  /// Electronic board Dev support: Button to rescan and select a different board.
  ///
  /// In en, this message translates to:
  /// **'Choose another board'**
  String get chooseAnotherBoard;

  /// Electronic board Dev support: Bluetooth board scan in progress.
  ///
  /// In en, this message translates to:
  /// **'Searching for boards…'**
  String get boardSearching;

  /// Electronic board Dev support: Bluetooth board connection in progress.
  ///
  /// In en, this message translates to:
  /// **'Connecting to board…'**
  String get boardConnecting;

  /// Electronic board Dev support: Board connection lost status.
  ///
  /// In en, this message translates to:
  /// **'Board disconnected'**
  String get boardDisconnected;

  /// Electronic board Dev support: Connection failure recovery instruction; Bluetooth is a product/protocol name.
  ///
  /// In en, this message translates to:
  /// **'Could not connect. Check Bluetooth and the board, then retry.'**
  String get boardConnectionError;

  /// Electronic board Dev support: Physical standard initial-position setup instruction.
  ///
  /// In en, this message translates to:
  /// **'Set up the standard starting position on your board.'**
  String get boardStartingPosition;

  /// Electronic board Dev support: Physical board synchronization complete status.
  ///
  /// In en, this message translates to:
  /// **'Board ready'**
  String get boardReady;

  /// Electronic board Dev support: Experimental support notice; compare the app screens and report connection issues.
  ///
  /// In en, this message translates to:
  /// **'New board support is experimental. Please verify moves on both screens and report connection problems.'**
  String get boardExperimentalNotice;

  /// Electronic board support: physical-board games have no clock.
  ///
  /// In en, this message translates to:
  /// **'Electronic-board games use unlimited time.'**
  String get boardGameRestriction;

  /// Electronic board Dev support: User confirmation of physical standard initial-position setup.
  ///
  /// In en, this message translates to:
  /// **'I have set up the starting position'**
  String get boardConfirmSetup;

  /// Electronic board Dev support: Occupancy-only board limitation: it senses presence, not piece identity.
  ///
  /// In en, this message translates to:
  /// **'Check every piece before starting. This board cannot verify piece identity.'**
  String get boardConfirmSetupHelp;

  /// Electronic board Dev support: Title of legal-move ambiguity picker.
  ///
  /// In en, this message translates to:
  /// **'Confirm your board move'**
  String get boardChooseMove;

  /// Electronic board Dev support: Occupancy-only ambiguity explanation; player chooses the move actually made.
  ///
  /// In en, this message translates to:
  /// **'The board cannot distinguish these moves. Choose the move you played.'**
  String get boardAmbiguousMove;

  /// Electronic board Dev support: Board unavailable recovery: reconnect or continue with phone input.
  ///
  /// In en, this message translates to:
  /// **'This board is not ready. Reconnect, or continue on your phone.'**
  String get boardUnavailable;

  /// Electronic board Dev support: Physical NEW GAME button second-press confirmation within 2.5 seconds; retain NEW GAME hardware marking.
  ///
  /// In en, this message translates to:
  /// **'Press NEW GAME again within 2.5 seconds to confirm, or use the buttons below.'**
  String get boardNewGameConfirmInstruction;

  /// Electronic board Dev support: Expired physical NEW GAME confirmation instruction; retain NEW GAME hardware marking.
  ///
  /// In en, this message translates to:
  /// **'To confirm on the board, press NEW GAME twice within 2.5 seconds.'**
  String get boardNewGameConfirmationExpired;

  /// Electronic board Dev support: Instruction to finish a physical move before proceeding.
  ///
  /// In en, this message translates to:
  /// **'Complete the move on your board.'**
  String get boardPhysicalMove;

  /// Electronic board Dev support: Instruction to restore physical board to the app position before proceeding.
  ///
  /// In en, this message translates to:
  /// **'Restore the position shown on screen before continuing.'**
  String get boardResetPhysical;

  /// Electronic board Dev support: Empty supported Bluetooth board scan result and recovery instruction.
  ///
  /// In en, this message translates to:
  /// **'No supported board found. Wake your board and try again.'**
  String get boardNoResults;

  /// Electronic board Dev support: Disconnected status while waiting for player to select a board.
  ///
  /// In en, this message translates to:
  /// **'Choose a board to connect.'**
  String get boardWaitingForSelection;

  /// Electronic board Dev support: Button to reconnect selected physical board.
  ///
  /// In en, this message translates to:
  /// **'Reconnect board'**
  String get boardReconnect;

  /// Electronic board Dev support: Manufacturer initialization missing/locked state; Dev means the separate development build.
  ///
  /// In en, this message translates to:
  /// **'Pegasus is locked. This Dev build does not include its manufacturer initialization key.'**
  String get boardLockedPegasus;

  /// Electronic board Dev support: Motorized-board safety recovery instruction; continue with phone input because firmware motor state cannot be restored.
  ///
  /// In en, this message translates to:
  /// **'Continue on your phone. This experimental adapter cannot safely restore the board’s motor state.'**
  String get boardMotorRecovery;

  /// Electronic board Dev support: Button to explicitly confirm physical-board setup matches the current logical position.
  ///
  /// In en, this message translates to:
  /// **'Confirm the physical position'**
  String get boardConfirmPosition;

  /// Electronic board Dev support: Help for explicit physical-position confirmation, including piece identities.
  ///
  /// In en, this message translates to:
  /// **'Check that every piece matches the position on screen.'**
  String get boardConfirmPositionHelp;

  /// Maia-specific history setting/help: Use move history
  ///
  /// In en, this message translates to:
  /// **'Use move history'**
  String get maiaHistorySetting;

  /// Maia-specific move-history help. The prediction gain is about 2 percentage points (57.00% to 59.36%), not a relative 2%. A playing-strength increase was not established; do not imply a full-game strength trial.
  ///
  /// In en, this message translates to:
  /// **'Let Maia use up to seven previous positions when choosing a move. In our tests with the 79M model, this improved prediction of human moves by about 2 percentage points, but sometimes led to repeated copying in lower-rated openings. We recommend leaving this off for now.'**
  String get maiaHistoryHelp;

  /// Maia-specific history setting/help: Read the move-history research
  ///
  /// In en, this message translates to:
  /// **'Read the move-history research'**
  String get maiaHistoryResearch;

  /// Maia-specific history setting/help: Move history: on
  ///
  /// In en, this message translates to:
  /// **'Move history: on'**
  String get maiaHistoryOn;

  /// Maia-specific history setting/help: Move history: off
  ///
  /// In en, this message translates to:
  /// **'Move history: off'**
  String get maiaHistoryOff;

  /// Generic electronic chessboard name when no brand or model is known.
  ///
  /// In en, this message translates to:
  /// **'Chessboard'**
  String get chessboardDeviceName;

  /// Electronic board status, only after transport is ready. Board name is a canonical product name or the localized generic chessboard name.
  ///
  /// In en, this message translates to:
  /// **'{boardName} connected'**
  String namedBoardConnected(String boardName);

  /// Electronic board disconnected status. Keep the last known board name until another connection begins.
  ///
  /// In en, this message translates to:
  /// **'{boardName} disconnected'**
  String namedBoardDisconnected(String boardName);

  /// App-specific opt-in local Maia decision capture; separate from diagnostics and Recent Games.
  ///
  /// In en, this message translates to:
  /// **'Save Maia sampling data'**
  String get saveMaiaSamplingData;

  /// Maia-specific research capture help: last ten recorded games, separate from Recent Games; readable HTML subset versus all recorded data in JSONL, viewed outside the app. Off by default and recommended off unless researching. All recorded data does not promise a complete game capture.
  ///
  /// In en, this message translates to:
  /// **'Save Maia’s move probabilities, settings and selected moves on this device to explore how it plays.\n\nExported files contain board positions, move history and model inputs and decisions.\n\nThe last 10 recorded games are saved and presented newest first. Older games may be removed sooner if the storage limit is reached. This is separate from Recent Games.\n\nUse this feature if you are interested in studying the technical details of how Maia works. Data cannot be viewed in the app. It is exported to an easy-to-view HTML file containing a subset of the data, or a JSONL file containing all the recorded data.\n\nThis is off by default, and we recommend keeping it off unless you are interested in researching how Maia works.'**
  String get samplingDataHelp;

  /// App-specific opt-in local Maia decision capture; separate from diagnostics and Recent Games.
  ///
  /// In en, this message translates to:
  /// **'Clear sampling data'**
  String get clearSamplingData;

  /// App-specific opt-in local Maia decision capture; separate from diagnostics and Recent Games.
  ///
  /// In en, this message translates to:
  /// **'{count} decisions saved'**
  String samplingDataStatus(int count);

  /// App-specific opt-in local Maia decision capture; separate from diagnostics and Recent Games.
  ///
  /// In en, this message translates to:
  /// **'Could not access sampling data. Playing is unaffected.'**
  String get samplingDataError;

  /// Maia-specific offline sampling report; use Lichess vocabulary where the action matches.
  ///
  /// In en, this message translates to:
  /// **'Save…'**
  String get samplingSave;

  /// Maia-specific offline sampling report; use Lichess vocabulary where the action matches.
  ///
  /// In en, this message translates to:
  /// **'Share…'**
  String get samplingShare;

  /// Maia-specific offline sampling report; use Lichess vocabulary where the action matches.
  ///
  /// In en, this message translates to:
  /// **'Maia’s choices'**
  String get samplingSummary;

  /// Maia-specific offline sampling report; use Lichess vocabulary where the action matches.
  ///
  /// In en, this message translates to:
  /// **'Readable report (HTML)'**
  String get samplingReadable;

  /// Maia-specific offline sampling report; use Lichess vocabulary where the action matches.
  ///
  /// In en, this message translates to:
  /// **'Moves, probabilities and board diagrams. Opens in a browser.'**
  String get samplingReadableHint;

  /// Maia-specific offline sampling report; use Lichess vocabulary where the action matches.
  ///
  /// In en, this message translates to:
  /// **'Raw model inputs and outputs for technical analysis.'**
  String get samplingResearchHint;

  /// HTML report introduction. Refer to the same translated Temperature/Top-P names as Settings; these are selection probabilities after sampling settings, not winning chances or objective quality scores.
  ///
  /// In en, this message translates to:
  /// **'Percentages show the chance of each move being selected after your Temperature and Top-P settings were applied. They are not winning chances or move-quality scores.'**
  String get samplingReportExplanation;

  /// Maia-specific offline sampling report; use Lichess vocabulary where the action matches.
  ///
  /// In en, this message translates to:
  /// **'Only recorded Maia decisions are shown, not a complete game. Takebacks and retries can repeat a move number.'**
  String get samplingReportPartial;

  /// Maia-specific offline sampling report; use Lichess vocabulary where the action matches.
  ///
  /// In en, this message translates to:
  /// **'Some capture data was removed or could not be saved. This report may have gaps.'**
  String get samplingReportMissing;

  /// Maia-specific offline sampling report; use Lichess vocabulary where the action matches.
  ///
  /// In en, this message translates to:
  /// **'Played'**
  String get samplingPlayed;

  /// Maia-specific offline sampling report; use Lichess vocabulary where the action matches.
  ///
  /// In en, this message translates to:
  /// **'Not recorded as played'**
  String get samplingNotPlayed;

  /// Maia-specific offline sampling report; use Lichess vocabulary where the action matches.
  ///
  /// In en, this message translates to:
  /// **'Likely alternatives'**
  String get samplingAlternatives;

  /// Maia-specific offline sampling report; use Lichess vocabulary where the action matches.
  ///
  /// In en, this message translates to:
  /// **'Game {number}'**
  String samplingGame(String number);

  /// Maia-specific offline sampling report; use Lichess vocabulary where the action matches.
  ///
  /// In en, this message translates to:
  /// **'Recorded decisions: {count}'**
  String samplingRecords(String count);

  /// Offline report of recorded Maia selection probabilities after Temperature and Top-P.
  ///
  /// In en, this message translates to:
  /// **'Most probable'**
  String get samplingMostProbable;

  /// Offline report of recorded Maia selection probabilities after Temperature and Top-P.
  ///
  /// In en, this message translates to:
  /// **'Played the most probable move'**
  String get samplingPlayedMostProbable;

  /// Offline report of recorded Maia selection probabilities after Temperature and Top-P.
  ///
  /// In en, this message translates to:
  /// **'{move} had about a 1 in {odds} chance of being played.'**
  String samplingChance(String move, String odds);

  /// Offline report of recorded Maia selection probabilities after Temperature and Top-P.
  ///
  /// In en, this message translates to:
  /// **'{move} was certain to be selected (100%).'**
  String samplingCertain(String move);

  /// Offline report of recorded Maia selection probabilities after Temperature and Top-P.
  ///
  /// In en, this message translates to:
  /// **'{move} was almost certain to be selected.'**
  String samplingAlmostCertain(String move);

  /// Explains report game order, ten-game retention, and earlier removal under the storage limit.
  ///
  /// In en, this message translates to:
  /// **'The last 10 recorded games are saved and presented newest first. Older games may be removed sooner if the storage limit is reached.'**
  String get samplingReportRetention;

  /// Accessible game chooser label for jumping to a game section.
  ///
  /// In en, this message translates to:
  /// **'Jump to game'**
  String get samplingJumpToGame;

  /// Navigation link back to the report game list.
  ///
  /// In en, this message translates to:
  /// **'Back to game list'**
  String get samplingBackToGames;

  /// Recorded game has no final result yet.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get samplingIncomplete;

  /// No known result is available in this historical record.
  ///
  /// In en, this message translates to:
  /// **'Unknown result'**
  String get samplingUnknownResult;

  /// No opening name is available for this game.
  ///
  /// In en, this message translates to:
  /// **'Unknown opening'**
  String get samplingOpeningUnknown;

  /// No valid timestamp is available for this game.
  ///
  /// In en, this message translates to:
  /// **'Unknown time'**
  String get samplingTimeUnknown;

  /// Recorded game result: the human player won.
  ///
  /// In en, this message translates to:
  /// **'Victory'**
  String get samplingWin;

  /// Recorded game result: the human player lost.
  ///
  /// In en, this message translates to:
  /// **'Defeat'**
  String get samplingLoss;

  /// Recorded game result: the game was drawn.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get samplingDraw;

  /// Sampling data: destructive confirmation button. Lichess Delete adapted with an explicit data object.
  ///
  /// In en, this message translates to:
  /// **'Delete data'**
  String get samplingDeleteData;

  /// Sampling data: confirm irreversible deletion of app-local captures only, excluding separately saved/shared exports.
  ///
  /// In en, this message translates to:
  /// **'Delete all Maia sampling data? It cannot be recovered.'**
  String get samplingClearConfirmation;

  /// Settings section for analysis ratings and full-game analysis quality. Uses Lichess preferencesAnalysisSettings.
  ///
  /// In en, this message translates to:
  /// **'Analysis settings'**
  String get analysisSettings;

  /// Settings: stored Maia sampling captures, with saved count and export/delete actions.
  ///
  /// In en, this message translates to:
  /// **'Sampling data'**
  String get samplingData;

  /// Reset all preferences shown on Settings, including language, sounds and recording; preserve stored games and captures.
  ///
  /// In en, this message translates to:
  /// **'Resets all settings on this screen. Saved games and sampling data are kept.'**
  String get resetSettingsDefaultsScope;

  /// Settings reset persistence failure; retry is safe and saved games are unaffected.
  ///
  /// In en, this message translates to:
  /// **'Some settings could not be reset. Please try again.'**
  String get settingsResetError;

  /// Settings reset confirmation: question.
  ///
  /// In en, this message translates to:
  /// **'Reset all settings to default?'**
  String get resetSettingsConfirmation;

  /// Settings reset confirmation: preservation notice.
  ///
  /// In en, this message translates to:
  /// **'Your saved games and sampling data will be kept.'**
  String get resetSettingsKeepData;

  /// Settings reset confirmation: explicit confirmation action.
  ///
  /// In en, this message translates to:
  /// **'Reset settings'**
  String get resetSettingsAction;

  /// Engine help: Introduction and recommended defaults. Legacy message ID retained; English revised 2026-10-25. All supported languages translate this approved English explanation. Maia-specific, not a Lichess equivalent.
  ///
  /// In en, this message translates to:
  /// **'Temperature and Top-P combine to set the amount of variety in Maia’s play.\n\nWe recommend Temperature 1.0, Top-P 0.95, and Max variety in opening enabled. These are the default settings. Based on our research, they offer a good balance of human-like play, opening variety and fewer unusual blunders.\n\nRead on to learn how these settings work.'**
  String get samplingHelpIntro;

  /// Engine help: Temperature section and opening probability examples. Legacy message ID retained; English revised 2026-10-25. All supported languages translate this approved English explanation. Maia-specific, not a Lichess equivalent.
  ///
  /// In en, this message translates to:
  /// **'Temperature\n\nAt Temperature 0, Maia always plays the move it predicts a player at the selected Elo is most likely to play. This is technically called argmax.\n\nAt Temperature 1, Maia considers the full range of moves it predicts a player at the selected Elo might play, choosing among them according to their probabilities.\n\nAt a Temperature between 0 and 1, Maia puts more weight on the moves it considers most likely. Lower Temperature values make Maia\'s choices more predictable.\n\nFor example, in our tests with the 79M model at rating inputs of 1600 for both players, Maia’s opening probabilities as White were approximately:\n\n• 1. e4: 64%\n• 1. d4: 25%\n• 1. c4: 3%\n• All other moves combined: 8%\n\nAt Temperature 0, Maia always played 1. e4\n\nAt Temperature 0.5, it played 1. e4 about 86% of the time and 1. d4 about 13% of the time. Other moves remained possible, but together accounted for less than 1%.\n\nAt Temperature 1, Maia followed the original probabilities listed above.'**
  String get samplingHelpVariety;

  /// Engine help: Top-P section and filtering example. Legacy message ID retained; English revised 2026-10-25. All supported languages translate this approved English explanation. Maia-specific, not a Lichess equivalent.
  ///
  /// In en, this message translates to:
  /// **'Top-P\n\nTop-P filters the available moves after Temperature adjusts their probabilities.\n\nAt Top-P 1, no filtering is applied. All available moves can be played according to their temperature-adjusted probabilities.\n\nAt Top-P 0.95, Maia keeps the most likely moves whose combined probability reaches at least 95%, then chooses among them. The excluded moves account for at most 5% of the probability.\n\nAt Top-P 0, Maia always chooses the most likely move. This has the same effect as Temperature 0: either setting is sufficient to produce argmax.\n\nIn our opening example, Temperature 1 and Top-P 0.60 would make Maia always play 1. e4. That move alone accounts for about 64% of the probability, so no other moves are needed to reach the 60% threshold.'**
  String get samplingHelpDefaults;

  /// Engine help: Effect on play, analogy and direct-match research. Legacy message ID retained; English revised 2026-10-25. All supported languages translate this approved English explanation. Maia-specific, not a Lichess equivalent.
  ///
  /// In en, this message translates to:
  /// **'How do these settings affect Maia’s play?\n\nYou can think of Top-P as an angel on Maia’s shoulder. At 0, the angel tells Maia to ignore lower-probability moves, which can include blunders or unsound moves. At 1.0, the angel has gone, and Maia could select even the craziest, most improbable move.\n\nIn our direct-match tests at the 1600 setting, argmax outperformed Temperature 1.0 / Top-P 1.0 by the equivalent of about 300 Elo points. However, argmax also limited opening choices to a narrow range of mainly main lines.'**
  String get samplingHelpStrength;

  /// Engine help: Opening variety override. Legacy message ID retained; English revised 2026-10-25. All supported languages translate this approved English explanation. Maia-specific, not a Lichess equivalent.
  ///
  /// In en, this message translates to:
  /// **'So, we introduced Max variety in opening: a toggle which sets Maia to play with Temperature 1.0 and Top-P 1.0 for the first five moves by each side. You might see some crazy things in the opening phase! From move six, Maia switches to your configured settings.'**
  String get samplingHelpArgmax;

  /// Engine help: Recommended play and strongest tested setting. Legacy message ID retained; English revised 2026-10-25. All supported languages translate this approved English explanation. Maia-specific, not a Lichess equivalent.
  ///
  /// In en, this message translates to:
  /// **'We recommend keeping max opening variety on and Temperature set to 1.0 and Top-P set to 0.95. This is like having a creative player with an angel on its shoulder that at least talks it out of playing the totally far-out moves—the least likely moves whose combined probability is up to 5%. These might be brilliant, true, but they can also be silly blunders. So this should make for a good balance of variety in the opening, creativity in the middle game, and stronger play through the exclusion of some very low-probability blunders.\n\nFor those feeling brave, Temperature 0 produced the strongest play in our tests. Good luck!'**
  String get samplingHelpTopP;

  /// Maia-specific sampling guidance for the 2.5 default proposal. Preserve probability mass versus individual move probability, the five-full-move boundary and conditional direct-match strength claims. Not a Lichess equivalent. Explanation selector changes prose only.
  ///
  /// In en, this message translates to:
  /// **'See the visual guide for the research behind these choices, with links to the full results.'**
  String get samplingHelpResearchIntro;

  /// Maia-specific sampling guidance for the 2.5 default proposal. Preserve probability mass versus individual move probability, the five-full-move boundary and conditional direct-match strength claims. Not a Lichess equivalent. Explanation selector changes prose only.
  ///
  /// In en, this message translates to:
  /// **'Maia may play more unusual blunders with Temperature and Top-P at 1.0 / 1.0.'**
  String get samplingFullVarietyNotice;

  /// Strength notice when Temperature or Top-P is zero, with or without opening variety. Includes Good luck. The opening override timing is explained in the help, not this short notice. Maia-specific, no Lichess equivalent.
  ///
  /// In en, this message translates to:
  /// **'Maia may play stronger with Temperature or Top-P at 0. Good luck!'**
  String get samplingArgmaxNotice;

  /// Maia-specific sampling guidance for the 2.5 default proposal. Preserve probability mass versus individual move probability, the five-full-move boundary and conditional direct-match strength claims. Not a Lichess equivalent. Explanation selector changes prose only.
  ///
  /// In en, this message translates to:
  /// **'Top-P: Not used'**
  String get topPNotUsed;

  /// Maia-specific sampling guidance for the 2.5 default proposal. Preserve probability mass versus individual move probability, the five-full-move boundary and conditional direct-match strength claims. Not a Lichess equivalent. Explanation selector changes prose only.
  ///
  /// In en, this message translates to:
  /// **'Why Top-P is not used'**
  String get topPNotUsedTitle;

  /// Maia-specific sampling guidance for the 2.5 default proposal. Preserve probability mass versus individual move probability, the five-full-move boundary and conditional direct-match strength claims. Not a Lichess equivalent. Explanation selector changes prose only.
  ///
  /// In en, this message translates to:
  /// **'At Temperature 0, Maia always chooses a most likely move, so Top-P has no effect. Your Top-P value is kept and becomes available again when you raise Temperature. If Max variety in opening is on, the first five moves by each side still use 1.0 / 1.0.'**
  String get topPNotUsedHelp;

  /// Neutral strength notice when either positive sampling setting is below its recommended default (Temperature < 1.0 or Top-P < 0.95), with or without opening variety. Also show the limited-opening notice when opening variety is off. No move-number qualifier or Good luck. Zero settings use the separate argmax notice. Maia-specific, no Lichess equivalent.
  ///
  /// In en, this message translates to:
  /// **'Maia may play stronger with lower Temperature or Top-P.'**
  String get samplingLowerNotice;

  /// Appearance setting: Appearance
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Appearance setting: Use system colors
  ///
  /// In en, this message translates to:
  /// **'Use system colors'**
  String get appearanceSystemColors;

  /// Appearance setting: Match your Android color palette
  ///
  /// In en, this message translates to:
  /// **'Match your Android color palette'**
  String get appearanceSystemColorsHelp;

  /// Appearance setting: Unavailable on this device. Requires Android 12 or later.
  ///
  /// In en, this message translates to:
  /// **'Unavailable on this device. Requires Android 12 or later.'**
  String get appearanceSystemColorsUnavailable;

  /// Appearance setting: Pure black background
  ///
  /// In en, this message translates to:
  /// **'Pure black background'**
  String get appearancePureBlack;

  /// Appearance setting: Use black backgrounds in dark mode
  ///
  /// In en, this message translates to:
  /// **'Use black backgrounds in dark mode'**
  String get appearancePureBlackHelp;

  /// Appearance setting: Appearance changed, but could not be saved. Please try again.
  ///
  /// In en, this message translates to:
  /// **'Appearance changed, but could not be saved. Please try again.'**
  String get appearancePreferenceError;

  /// Appearance mode label, following Lichess.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get appearanceTheme;

  /// Light appearance mode, not brightness intensity or piece color. Lichess baseline with documented Google platform-wording adaptations in docs/TRANSLATION_QUALITY_REVIEW.md.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceLight;

  /// Dark appearance mode, not literal black or piece color. Pure-black backgrounds are a separate setting. Lichess baseline with documented Google platform-wording adaptations in docs/TRANSLATION_QUALITY_REVIEW.md.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceDark;

  /// System-default option in the THEME selector only. Follow device light/dark brightness; independent of language, Android accent colors and pure-black backgrounds. Lichess deviceTheme where available; sourced fallback in docs/TRANSLATION_QUALITY_REVIEW.md.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get appearanceSystemDefault;

  /// Compact Board section heading, including board display and touch-drag aids.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get boardSettings;

  /// Board settings control; see the pinned Lichess terminology reference for scope.
  ///
  /// In en, this message translates to:
  /// **'Board coordinates'**
  String get boardCoordinates;

  /// Switch for legal destination dots. Already committed premove overlays are independent.
  ///
  /// In en, this message translates to:
  /// **'Legal-move destinations'**
  String get boardLegalMoves;

  /// Switch for last-move highlights only. Check, selection, premoves and arrows stay independent.
  ///
  /// In en, this message translates to:
  /// **'Last-move highlight'**
  String get boardLastMove;

  /// Board settings control; see the pinned Lichess terminology reference for scope.
  ///
  /// In en, this message translates to:
  /// **'Piece animation'**
  String get boardAnimation;

  /// Board settings control; see the pinned Lichess terminology reference for scope.
  ///
  /// In en, this message translates to:
  /// **'Magnify dragged piece'**
  String get boardMagnify;

  /// Board settings control; see the pinned Lichess terminology reference for scope.
  ///
  /// In en, this message translates to:
  /// **'Dragged piece target'**
  String get boardDragTarget;

  /// Board settings control; see the pinned Lichess terminology reference for scope.
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get boardTargetCircle;

  /// Board settings control; see the pinned Lichess terminology reference for scope.
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get boardTargetSquare;

  /// Board settings control; see the pinned Lichess terminology reference for scope.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get boardTargetNone;

  /// Board preference persistence failed; the displayed choice can be retried.
  ///
  /// In en, this message translates to:
  /// **'Could not save board settings. Please try again.'**
  String get boardPreferenceError;

  /// Visual board design selector. Style names are upstream artwork names and remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get boardDesign;

  /// Visual piece set selector. Style names are upstream artwork names and remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'Piece set'**
  String get boardPieceSet;

  /// User-approved Maia win (score) percentage setting/help, 2026-10-26. The model estimates expected game points including half-point draws. Preserve the 60 points in 100 games example, independent rating inputs and human/Stockfish comparison. Maia-specific, not a direct Lichess equivalent.
  ///
  /// In en, this message translates to:
  /// **'Show Maia win (score) %'**
  String get showMaiaScore;

  /// Maia outcome/expected-score feature. The percentage is P(win)+half P(draw), rating-conditioned for both players, not strict P(win). Keep separate from human move-choice probabilities and Stockfish.
  ///
  /// In en, this message translates to:
  /// **'Maia score'**
  String get maiaScore;

  /// Maia outcome/expected-score feature. The percentage is P(win)+half P(draw), rating-conditioned for both players, not strict P(win). Keep separate from human move-choice probabilities and Stockfish.
  ///
  /// In en, this message translates to:
  /// **'Equal'**
  String get maiaScoreEqual;

  /// User-approved Maia win (score) percentage setting/help, 2026-10-26. The model estimates expected game points including half-point draws. Preserve the 60 points in 100 games example, independent rating inputs and human/Stockfish comparison. Maia-specific, not a direct Lichess equivalent.
  ///
  /// In en, this message translates to:
  /// **'Shows Maia’s assessment of winning (scoring) chances at the top of the screen.\nThe white or black dot tells you which side the percentage describes.'**
  String get maiaScoreHelp;

  /// User-approved Maia win (score) percentage setting/help, 2026-10-26. The model estimates expected game points including half-point draws. Preserve the 60 points in 100 games example, independent rating inputs and human/Stockfish comparison. Maia-specific, not a direct Lichess equivalent.
  ///
  /// In en, this message translates to:
  /// **'For example, White 60% means Maia estimates White would score about 60 points across 100 games from this position. A win earns 1 point; a draw earns ½.'**
  String get maiaScoreExpectedHelp;

  /// User-approved Maia win (score) percentage setting/help, 2026-10-26. The model estimates expected game points including half-point draws. Preserve the 60 points in 100 games example, independent rating inputs and human/Stockfish comparison. Maia-specific, not a direct Lichess equivalent.
  ///
  /// In en, this message translates to:
  /// **'The estimate uses the selected Maia analysis rating for both players. With two Maias enabled, each shows its own estimate at its own rating.'**
  String get maiaScoreInputsHelp;

  /// Maia outcome/expected-score feature. The percentage is P(win)+half P(draw), rating-conditioned for both players, not strict P(win). Keep separate from human move-choice probabilities and Stockfish.
  ///
  /// In en, this message translates to:
  /// **'Could not save Maia score settings. Please try again.'**
  String get maiaScorePreferenceError;

  /// Link to the English-language research report on Maia expected-score reliability. Maia-specific, no direct Lichess equivalent. Non-English labels identify the report language.
  ///
  /// In en, this message translates to:
  /// **'How reliable is Maia’s score?'**
  String get maiaScoreResearchLink;

  /// User-approved Maia win (score) percentage setting/help, 2026-10-26. The model estimates expected game points including half-point draws. Preserve the 60 points in 100 games example, independent rating inputs and human/Stockfish comparison. Maia-specific, not a direct Lichess equivalent.
  ///
  /// In en, this message translates to:
  /// **'It can be useful to contrast with Stockfish evaluation. Just because Stockfish thinks one side is better, does not mean that it is easy for a human to find the right moves to convert!'**
  String get maiaScoreStockfishHelp;

  /// Standard-chess board editor: Move pieces. Tool labels must distinguish moving existing pieces, repeated placement and erasure. FEN counters are preserved; camera recognition is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Move pieces'**
  String get editorMoveTool;

  /// Standard-chess board editor: Erase pieces. Tool labels must distinguish moving existing pieces, repeated placement and erasure. FEN counters are preserved; camera recognition is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Erase pieces'**
  String get editorEraseTool;

  /// Standard-chess board editor: Empty square. Tool labels must distinguish moving existing pieces, repeated placement and erasure. FEN counters are preserved; camera recognition is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Empty square'**
  String get editorEmptySquare;

  /// Standard-chess board editor: Position settings. Tool labels must distinguish moving existing pieces, repeated placement and erasure. FEN counters are preserved; camera recognition is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Position settings'**
  String get editorPositionSettings;

  /// Standard-chess board editor: Import position from image (not yet available). Tool labels must distinguish moving existing pieces, repeated placement and erasure. FEN counters are preserved; camera recognition is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Import position from image (not yet available)'**
  String get editorImageImportUnavailable;

  /// Standard-chess board editor: Share FEN. Tool labels must distinguish moving existing pieces, repeated placement and erasure. FEN counters are preserved; camera recognition is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Share FEN'**
  String get editorShareFen;

  /// Standard-chess board editor: FEN metadata. Tool labels must distinguish moving existing pieces, repeated placement and erasure. FEN counters are preserved; camera recognition is unavailable.
  ///
  /// In en, this message translates to:
  /// **'FEN metadata'**
  String get editorFenMetadata;

  /// Standard-chess board editor: Halfmove clock. Tool labels must distinguish moving existing pieces, repeated placement and erasure. FEN counters are preserved; camera recognition is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Halfmove clock'**
  String get editorHalfmoveClock;

  /// Standard-chess board editor: Move number. Tool labels must distinguish moving existing pieces, repeated placement and erasure. FEN counters are preserved; camera recognition is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Move number'**
  String get editorFullmoveNumber;

  /// Complete singular name of a white pawn, used in editor palette tooltips and board-square accessibility labels. Use natural word order and gender agreement; keep the pinned Lichess piece-name terminology.
  ///
  /// In en, this message translates to:
  /// **'White pawn'**
  String get editorWhitePawn;

  /// Complete singular name of a white knight, used in editor palette tooltips and board-square accessibility labels. Use natural word order and gender agreement; keep the pinned Lichess piece-name terminology.
  ///
  /// In en, this message translates to:
  /// **'White knight'**
  String get editorWhiteKnight;

  /// Complete singular name of a white bishop, used in editor palette tooltips and board-square accessibility labels. Use natural word order and gender agreement; keep the pinned Lichess piece-name terminology.
  ///
  /// In en, this message translates to:
  /// **'White bishop'**
  String get editorWhiteBishop;

  /// Complete singular name of a white rook, used in editor palette tooltips and board-square accessibility labels. Use natural word order and gender agreement; keep the pinned Lichess piece-name terminology.
  ///
  /// In en, this message translates to:
  /// **'White rook'**
  String get editorWhiteRook;

  /// Complete singular name of a white queen, used in editor palette tooltips and board-square accessibility labels. Use natural word order and gender agreement; keep the pinned Lichess piece-name terminology.
  ///
  /// In en, this message translates to:
  /// **'White queen'**
  String get editorWhiteQueen;

  /// Complete singular name of a white king, used in editor palette tooltips and board-square accessibility labels. Use natural word order and gender agreement; keep the pinned Lichess piece-name terminology.
  ///
  /// In en, this message translates to:
  /// **'White king'**
  String get editorWhiteKing;

  /// Complete singular name of a black pawn, used in editor palette tooltips and board-square accessibility labels. Use natural word order and gender agreement; keep the pinned Lichess piece-name terminology.
  ///
  /// In en, this message translates to:
  /// **'Black pawn'**
  String get editorBlackPawn;

  /// Complete singular name of a black knight, used in editor palette tooltips and board-square accessibility labels. Use natural word order and gender agreement; keep the pinned Lichess piece-name terminology.
  ///
  /// In en, this message translates to:
  /// **'Black knight'**
  String get editorBlackKnight;

  /// Complete singular name of a black bishop, used in editor palette tooltips and board-square accessibility labels. Use natural word order and gender agreement; keep the pinned Lichess piece-name terminology.
  ///
  /// In en, this message translates to:
  /// **'Black bishop'**
  String get editorBlackBishop;

  /// Complete singular name of a black rook, used in editor palette tooltips and board-square accessibility labels. Use natural word order and gender agreement; keep the pinned Lichess piece-name terminology.
  ///
  /// In en, this message translates to:
  /// **'Black rook'**
  String get editorBlackRook;

  /// Complete singular name of a black queen, used in editor palette tooltips and board-square accessibility labels. Use natural word order and gender agreement; keep the pinned Lichess piece-name terminology.
  ///
  /// In en, this message translates to:
  /// **'Black queen'**
  String get editorBlackQueen;

  /// Complete singular name of a black king, used in editor palette tooltips and board-square accessibility labels. Use natural word order and gender agreement; keep the pinned Lichess piece-name terminology.
  ///
  /// In en, this message translates to:
  /// **'Black king'**
  String get editorBlackKing;

  /// Continue from here dialog: toggle for playing the selected position on a physical electronic chessboard.
  ///
  /// In en, this message translates to:
  /// **'Use electronic board'**
  String get continuationUseBoard;

  /// Continue from here dialog: instruction shown before a supported physical board is connected.
  ///
  /// In en, this message translates to:
  /// **'Connect a supported board.'**
  String get continuationConnectHelp;

  /// Continue from here dialog: explains that physical-board games do not use a clock.
  ///
  /// In en, this message translates to:
  /// **'Electronic-board games are untimed.'**
  String get continuationBoardUntimed;

  /// Continuation game setup: heading while the player arranges physical pieces to match the selected position.
  ///
  /// In en, this message translates to:
  /// **'Set up board'**
  String get continuationSetUpBoard;

  /// Continuation game setup: arrange the position displayed in the app on the physical board; play begins automatically when the pieces match.
  ///
  /// In en, this message translates to:
  /// **'Set up the position shown on your board. The game starts when the pieces match.'**
  String get continuationSetupHelp;

  /// Continue from here dialog: explains that custom-position continuation currently supports only Chessnut hardware.
  ///
  /// In en, this message translates to:
  /// **'Continuing from a position currently supports Chessnut boards only.'**
  String get continuationBoardUnsupported;
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

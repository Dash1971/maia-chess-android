// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get about => 'À propos';

  @override
  String get analysisBoard => 'Échiquier d\'analyse';

  @override
  String get back => 'Retour';

  @override
  String get black => 'Noirs';

  @override
  String get cancelPremoves => 'Annuler les pré-coups';

  @override
  String get chessnutExperimental => 'Chessnut (expérimental)';

  @override
  String get connectChessnut => 'Connecter Chessnut';

  @override
  String get disconnect => 'Déconnecter';

  @override
  String get engineSettings => 'Paramètres du moteur d\'analyse';

  @override
  String get gameMenu => 'Menu de la partie';

  @override
  String get gameReady => 'Partie prête';

  @override
  String get gameSettings => 'Paramètres de la partie';

  @override
  String get home => 'Accueil';

  @override
  String get playMaia => 'Jouer contre Maia';

  @override
  String get random => 'Couleur aléatoire';

  @override
  String get recentGames => 'Parties récentes';

  @override
  String get resign => 'Abandonner';

  @override
  String get settings => 'Paramètres';

  @override
  String get startGame => 'Commencer la partie';

  @override
  String get timeControl => 'Cadence';

  @override
  String get white => 'Blancs';

  @override
  String get unlimited => 'Illimité';

  @override
  String get custom => 'Personnalisée';

  @override
  String get seconds => 'secondes';

  @override
  String get yourSide => 'Votre couleur';

  @override
  String get you => 'Vous';

  @override
  String get systemDefault => 'Langue du système';

  @override
  String get language => 'Langue';

  @override
  String get playMaiaRating => 'Classement de Maia pour jouer';

  @override
  String get minutes => 'Minutes';

  @override
  String get increment => 'Incrément';

  @override
  String get gameSounds => 'Sons du jeu';

  @override
  String get movesCapturesErrorsAndGameEnd =>
      'Coups, prises, erreurs et fin de partie';

  @override
  String get hapticFeedback => 'Retour tactile';

  @override
  String get touchFeedbackForMovesChecksErrorsAndGameEnd =>
      'Vibrations pour les coups, les échecs, les erreurs et la fin de partie';

  @override
  String get premoves => 'Pré-coups';

  @override
  String get queueAMoveWhileMaiaIsThinking =>
      'Préparer un coup pendant que Maia réfléchit';

  @override
  String get oneHundredMsPremovePenalty => 'Pénalité de 100 ms par pré-coup';

  @override
  String get use01SecondsPerPremoveInTimedGames =>
      'Décompter 0,1 seconde par pré-coup dans les parties chronométrées';

  @override
  String get allowMultiplePremoves => 'Autoriser plusieurs pré-coups';

  @override
  String get queueASequenceAnIllegalMoveCancelsTheRest =>
      'Préparer une suite de coups ; un coup illégal annule les suivants';

  @override
  String get humanMoveTiming => 'Pauses avant les coups de Maia';

  @override
  String get variableNaturalPausesBeforeMaiaMoves =>
      'Pauses naturelles de durée variable avant les coups de Maia';

  @override
  String get aboutTemperatureAndTopP =>
      'À propos de la température et du Top-P';

  @override
  String get temperature => 'Température';

  @override
  String get topP => 'Top-P';

  @override
  String get maxOpeningVariety => 'Variété maximale dans l’ouverture';

  @override
  String get maxOpeningVarietyHelp =>
      'Activée par défaut. Utilise température et Top-P 1,0 / 1,0 pendant les cinq premiers coups de chaque camp, puis vos réglages dès le sixième. Cela préserve un large choix d’ouvertures tout en permettant d’écarter ensuite les coups peu probables. Le numéro de coup de la position est respecté, même lors d’une reprise.\n\nInutile à 1,0 / 1,0 : l’interrupteur est désactivé et non sélectionnable, car ces valeurs offrent déjà toute la variété pendant la partie.';

  @override
  String get maiaAnalysisRating => 'Classement de Maia pour l’analyse';

  @override
  String get addSecondMaiaEngine => 'Ajouter un second moteur Maia';

  @override
  String get compareAnotherMaiaRatingInAnalysisAndReview =>
      'Comparer un autre classement de Maia lors de l’analyse et de la révision';

  @override
  String get secondMaiaAnalysisRating =>
      'Classement du second Maia pour l’analyse';

  @override
  String get gameAnalysisQuality => 'Qualité de l’analyse de la partie';

  @override
  String get resetSettingsDefaults => 'Rétablir les réglages par défaut';

  @override
  String get boardSounds => 'Sons de l’échiquier';

  @override
  String get beepForCheckCheckmateAndCompletedIllegalMoves =>
      'Signal sonore en cas d’échec, d’échec et mat ou de coup illégal une fois les pièces posées.';

  @override
  String get copyDiagnostics => 'Copier les données de diagnostic';

  @override
  String get diagnosticsCopied => 'Données de diagnostic copiées';

  @override
  String get newGame => 'Nouvelle partie';

  @override
  String get resetGame => 'Réinitialiser la partie';

  @override
  String get shareAndExport => 'Partager et exporter';

  @override
  String get savePgnFile => 'Enregistrer un fichier PGN';

  @override
  String get sharePgn => 'Partager le PGN';

  @override
  String get copyPgn => 'Copier le fichier PGN';

  @override
  String get copyFen => 'Copier la FEN';

  @override
  String get maiaErrorRetry => 'Erreur de Maia. Réessayer';

  @override
  String get maiaErrorPleaseRetry => 'Erreur de Maia. Veuillez réessayer.';

  @override
  String get retry => 'Réessayer';

  @override
  String get maiaIsThinking => 'Maia réfléchit…';

  @override
  String get history => 'HISTORIQUE';

  @override
  String get start => 'DÉBUT';

  @override
  String get chessnutStatus => 'État de Chessnut';

  @override
  String get leaveCurrentGame => 'Quitter la partie en cours ?';

  @override
  String get yourGameWillBeKeptInRecentGames =>
      'Votre partie sera conservée dans les parties récentes.';

  @override
  String get cancel => 'Annuler';

  @override
  String get continueAction => 'Continuer';

  @override
  String get startANewGame => 'Commencer une nouvelle partie ?';

  @override
  String get resetGameQuestion => 'Réinitialiser la partie ?';

  @override
  String get yourCompletedGameWillRemainInRecentGames =>
      'Votre partie terminée restera dans les parties récentes.';

  @override
  String get thisGameWillBePermanentlyErased =>
      'Cette partie sera définitivement effacée.';

  @override
  String get startNewGame => 'Commencer une nouvelle partie';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get flipBoard => 'Tourner l\'échiquier';

  @override
  String get offerDraw => 'Proposer la nulle';

  @override
  String get takeBackMove => 'Annuler le coup';

  @override
  String get whiteIsVictorious => 'Victoire des Blancs';

  @override
  String get blackIsVictorious => 'Victoire des Noirs';

  @override
  String get theGameIsADraw => 'La partie est nulle.';

  @override
  String get theGameHasEnded => 'La partie est terminée';

  @override
  String get rematch => 'Revanche';

  @override
  String get fast => 'Rapide';

  @override
  String get balanced => 'Équilibrée';

  @override
  String get thorough => 'Approfondie';

  @override
  String get continueFromHere => 'Continuer depuis cette position';

  @override
  String get load => 'Charger';

  @override
  String get editBoard => 'Modifier la position';

  @override
  String get done => 'Terminé';

  @override
  String get whitePieces => 'Pièces blanches';

  @override
  String get blackPieces => 'Pièces noires';

  @override
  String get whiteToMove => 'Trait aux Blancs';

  @override
  String get blackToMove => 'Trait aux Noirs';

  @override
  String get castlingRights => 'Droits de roque';

  @override
  String get whiteKingside => 'Petit roque des Blancs';

  @override
  String get whiteQueenside => 'Grand roque des Blancs';

  @override
  String get blackKingside => 'Petit roque des Noirs';

  @override
  String get blackQueenside => 'Grand roque des Noirs';

  @override
  String get enPassantTarget => 'Case cible de la prise en passant';

  @override
  String get startingPosition => 'Position de départ';

  @override
  String get clearBoard => 'Vider l\'échiquier';

  @override
  String get loadFen => 'Charger une FEN';

  @override
  String get loadPgn => 'Charger un PGN';

  @override
  String get openPgnFile => 'Ouvrir un fichier PGN';

  @override
  String get clearMoves => 'Effacer les coups';

  @override
  String get boardEditor => 'Éditeur de position';

  @override
  String get endPosition => 'position finale';

  @override
  String get analysisMenu => 'Menu d’analyse';

  @override
  String get turnEngineOff => 'Désactiver le moteur';

  @override
  String get turnEngineOn => 'Activer le moteur';

  @override
  String get moves => 'Coups';

  @override
  String get computerAnalysis => 'Analyse de l\'ordinateur';

  @override
  String get backToGame => 'Retour à la partie';

  @override
  String get expandVariations => 'Afficher les variantes';

  @override
  String get collapseVariations => 'Masquer les variantes';

  @override
  String get promoteVariation => 'Promouvoir la variante';

  @override
  String get mainLine => 'variante principale';

  @override
  String get makeMainLine => 'En faire la variante principale';

  @override
  String get deleteFromHere => 'Supprimer à partir d\'ici';

  @override
  String get analyzing => 'Analyse en cours…';

  @override
  String get noLegalMoves => 'Aucun coup légal';

  @override
  String get unavailable => 'Indisponible';

  @override
  String get analysisFailed => 'Échec de l’analyse. Veuillez réessayer.';

  @override
  String get analysisStopped => 'Analyse de l’ordinateur arrêtée.';

  @override
  String get classifyingMoves => 'Classification des coups…';

  @override
  String get graphReadyClassifying =>
      'Graphique prêt · classification des coups…';

  @override
  String get stopAnalysis => 'Arrêter l’analyse';

  @override
  String get runAnalysisAgain => 'Relancer l’analyse de l’ordinateur';

  @override
  String get runAnalysis => 'Lancer l’analyse de l’ordinateur';

  @override
  String get analysisExplanation =>
      'Lancez l’analyse de l’ordinateur pour obtenir le graphique d’évaluation et la précision des Blancs et des Noirs.';

  @override
  String get pgnCopied => 'PGN copié.';

  @override
  String get fenCopied => 'FEN copiée';

  @override
  String get rawProbabilitiesExplanation =>
      'Probabilités brutes du modèle, normalisées sur l’ensemble des coups légaux. La température et le Top-P ne sont pas appliqués.';

  @override
  String get showRawProbabilities =>
      'Afficher toutes les probabilités brutes du modèle';

  @override
  String get pasteFen => 'Coller une FEN complète à six champs';

  @override
  String get pastePgn => 'Coller une partie au format PGN';

  @override
  String get invalidPosition =>
      'Position invalide. Vérifiez l’échiquier et la FEN.';

  @override
  String get pgnLoadFailed =>
      'Impossible de charger la partie PGN. Vérifiez le fichier ou le texte collé.';

  @override
  String get goToNext => 'Passer au suivant';

  @override
  String tapForNext(String label) {
    return '$label · toucher pour passer au suivant';
  }

  @override
  String get notEnoughMoves => 'Pas assez de coups';

  @override
  String get gameAccuracy => 'Précision de la partie';

  @override
  String get accuracy => 'Précision';

  @override
  String get analysisGraph => 'Graphique d’analyse de l’ordinateur';

  @override
  String maiaMoveProbabilities(int elo) {
    return 'Probabilités des coups de Maia $elo';
  }

  @override
  String otherProbability(String probability) {
    return 'Autres : $probability';
  }

  @override
  String otherLegalProbability(String probability) {
    return 'autres coups légaux : $probability';
  }

  @override
  String maiaProbabilitySemantics(String title, String moves) {
    return '$title. $moves.';
  }

  @override
  String analysisProgress(int completed, int total) {
    return 'Analyse des positions : $completed sur $total…';
  }

  @override
  String graphPosition(int position, int total, String score) {
    return 'Position $position sur $total  ·  $score';
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
      other: '$count coups · $side · $classification',
      one: '$count coup · $side · $classification',
    );
    return '$_temp0';
  }

  @override
  String get classificationBrilliant => 'Excellent coup';

  @override
  String get classificationGood => 'Bon coup';

  @override
  String get classificationInteresting => 'Coup intéressant';

  @override
  String get classificationDubious => 'Coup douteux';

  @override
  String get classificationMistake => 'Erreur';

  @override
  String get classificationBlunder => 'Gaffe';

  @override
  String get gameReview => 'Révision de la partie';

  @override
  String materialPawn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pions',
      one: '$count pion',
    );
    return '$_temp0';
  }

  @override
  String materialKnight(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cavaliers',
      one: '$count cavalier',
    );
    return '$_temp0';
  }

  @override
  String materialBishop(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fous',
      one: '$count fou',
    );
    return '$_temp0';
  }

  @override
  String materialRook(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tours',
      one: '$count tour',
    );
    return '$_temp0';
  }

  @override
  String materialQueen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dames',
      one: '$count dame',
    );
    return '$_temp0';
  }

  @override
  String materialAdvantage(String score) {
    return 'Avantage matériel : $score';
  }

  @override
  String materialDescription(String side, String description) {
    return 'Différence de matériel pour les $side : $description';
  }

  @override
  String get previousMove => 'Coup précédent';

  @override
  String get nextMove => 'Coup suivant';

  @override
  String get beginning => 'le début';

  @override
  String get latestPosition => 'la dernière position';

  @override
  String holdForDestination(String destination) {
    return 'Appui long : $destination';
  }

  @override
  String get phaseOpening => 'Ouverture';

  @override
  String get phaseMiddlegame => 'Milieu de partie';

  @override
  String get phaseEndgame => 'Fin de partie';

  @override
  String get pieceKing => 'Roi';

  @override
  String get pieceQueen => 'Dame';

  @override
  String get pieceRook => 'Tour';

  @override
  String get pieceBishop => 'Fou';

  @override
  String get pieceKnight => 'Cavalier';

  @override
  String get piecePawn => 'Pion';

  @override
  String recentPlayerMaia(String rating) {
    return 'Vous — Maia $rating';
  }

  @override
  String recentMaiaPlayer(String rating) {
    return 'Maia $rating — Vous';
  }

  @override
  String get recentIncomplete => 'Inachevée';

  @override
  String get recentCompleted => 'Terminée';

  @override
  String get recentDeleteFailed =>
      'Impossible de supprimer les parties enregistrées. Veuillez réessayer.';

  @override
  String get recentOpenFailed =>
      'Impossible d’ouvrir la partie enregistrée. Veuillez réessayer.';

  @override
  String recentDeleteTitle(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Supprimer $countString parties ?',
      one: 'Supprimer la partie enregistrée ?',
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
      other:
          'Ces $countString parties enregistrées seront définitivement supprimées.',
      one: 'Cette partie enregistrée sera définitivement supprimée.',
    );
    return '$_temp0';
  }

  @override
  String get deleteAction => 'Effacer';

  @override
  String get recentUpdating => 'Mise à jour des parties enregistrées';

  @override
  String get recentCancelSelection => 'Annuler la sélection';

  @override
  String get recentClearSelection => 'Tout désélectionner';

  @override
  String get recentSelectAll => 'Sélectionner toutes les parties';

  @override
  String get recentDeleteSelected => 'Supprimer les parties sélectionnées';

  @override
  String get recentSelectGames => 'Sélectionner des parties';

  @override
  String get recentDeleteAll => 'Supprimer toutes les parties';

  @override
  String get recentDeleteOne => 'Supprimer la partie enregistrée';

  @override
  String recentSelectedCount(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Sélection : $countString';
  }

  @override
  String get recentLoadFailed =>
      'Impossible de charger les parties enregistrées. Veuillez réessayer.';

  @override
  String get recentEmpty =>
      'Les parties terminées et les parties inachevées enregistrées lors du retour à l’accueil apparaîtront ici.';

  @override
  String recentGameSummary(String result, String date) {
    return '$result · $date';
  }

  @override
  String get diagnosticsScreenError =>
      'Mobile Maia a rencontré une erreur d’affichage.';

  @override
  String get diagnosticsScreenInstructions =>
      'Copiez les données de diagnostic et envoyez-les en décrivant ce que vous avez touché juste avant l’apparition de cet écran.';

  @override
  String get pgnSaved => 'PGN enregistré';

  @override
  String get pgnExportFailed =>
      'Impossible d’exporter le PGN. Votre partie reste enregistrée sur cet appareil.';

  @override
  String get languagePreferenceError =>
      'Impossible d’enregistrer ou de restaurer la langue. Vos parties sont intactes. Veuillez sélectionner à nouveau la langue.';

  @override
  String playRatingValue(String rating) {
    return 'Classement de Maia pour jouer : $rating';
  }

  @override
  String minutesValue(String minutes) {
    return 'Minutes : $minutes';
  }

  @override
  String incrementSecondsValue(String seconds) {
    return 'Incrément : $seconds s';
  }

  @override
  String get chooseSettings =>
      'Choisissez vos paramètres et commencez une partie.';

  @override
  String get gameRestored => 'Partie restaurée.';

  @override
  String get reconnectChessnut => 'Reconnectez Chessnut pour continuer.';

  @override
  String get chessnutConnectionError => 'Erreur de connexion à Chessnut.';

  @override
  String get searchingChessnut => 'Recherche de Chessnut…';

  @override
  String get couldNotConnectChessnut => 'Impossible de connecter Chessnut.';

  @override
  String get chessnutAndroidOnly =>
      'La prise en charge de Chessnut est disponible sur Android.';

  @override
  String get chessnutIsDisconnected => 'Chessnut est déconnecté.';

  @override
  String get yourMove => 'À votre tour.';

  @override
  String get yourMoveChessnut => 'À votre tour sur Chessnut.';

  @override
  String get chessnutReady => 'Chessnut est prêt.';

  @override
  String get chessnutStartingPosition =>
      'Disposez les pièces dans la position initiale standard sur Chessnut.';

  @override
  String get takebackCompleteYourMove =>
      'Retour effectué. À votre tour sur Chessnut.';

  @override
  String get takebackCompleteThinking => 'Retour effectué. Maia réfléchit…';

  @override
  String get restoreLitSquares =>
      'Retour en arrière : rétablissez les pièces sur les cases éclairées de Chessnut.';

  @override
  String get completeMaiaLitMove =>
      'Terminez le coup de Maia indiqué par les cases éclairées de Chessnut.';

  @override
  String get illegalChessnutPosition =>
      'Cette position ne correspond pas à un coup légal. Corrigez les cases éclairées.';

  @override
  String get completeYourChessnutMove => 'Terminez votre coup sur Chessnut.';

  @override
  String get connectChessnutFirst => 'Connectez Chessnut avant de commencer.';

  @override
  String get gameInProgress => 'Partie en cours.';

  @override
  String get timeoutInsufficientMaterial =>
      'Partie nulle — temps écoulé, matériel adverse insuffisant pour mater.';

  @override
  String get whiteOutOfTime => 'Les blancs sont tombés au temps';

  @override
  String get blackOutOfTime => 'Les noirs sont tombés au temps';

  @override
  String get makeMaiaLitMove =>
      'Jouez le coup de Maia indiqué par les cases éclairées de Chessnut.';

  @override
  String get checkmateMaiaWins => 'Échec et mat — Maia gagne.';

  @override
  String get checkmateYouWin => 'Échec et mat — vous gagnez !';

  @override
  String get drawResult => 'Partie nulle';

  @override
  String get drawByAgreement => 'Partie nulle par accord mutuel';

  @override
  String get youWin => 'Vous gagnez.';

  @override
  String get maiaWins => 'Maia gagne.';

  @override
  String get gameEnded => 'Partie terminée.';

  @override
  String get consideringDraw => 'Maia examine la proposition de nulle…';

  @override
  String get maiaDeclinedDraw => 'Maia a refusé la nulle.';

  @override
  String get couldNotEvaluateDraw =>
      'Impossible d’évaluer la proposition de nulle.';

  @override
  String get youResigned => 'Vous avez abandonné — Maia gagne.';

  @override
  String get moveTakenBack => 'Retour effectué. À votre tour.';

  @override
  String get connectingChessnut => 'Connexion à Chessnut…';

  @override
  String get chessnutUnavailable => 'Chessnut indisponible';

  @override
  String get chessnutDisconnected => 'Chessnut déconnecté';

  @override
  String get reconnect => 'Reconnecter';

  @override
  String get playInApp => 'Jouer dans l’application';

  @override
  String get continueGameOnScreen => 'Continuer cette partie à l’écran';

  @override
  String get checkCheckmateIllegalMoves =>
      'Échec, échec et mat et coups illégaux';

  @override
  String get offerDrawQuestion => 'Proposer la nulle ?';

  @override
  String get resignGameQuestion => 'Abandonner la partie ?';

  @override
  String get resignEndsImmediately =>
      'Cela mettra immédiatement fin à la partie.';

  @override
  String get premoveLimit => 'Vous pouvez préparer jusqu’à 64 pré-coups.';

  @override
  String get chessnutGameRestriction =>
      'Les parties sur Chessnut sont sans limite de temps.';

  @override
  String get samplingTitle => 'Température et Top-P';

  @override
  String get samplingDefaultsQuestion =>
      'Choisissez la variété de jeu souhaitée';

  @override
  String get samplingResearch => 'Données de recherche complètes (JSONL)';

  @override
  String get samplingResearchLink => 'Guide visuel et recherche (en anglais)';

  @override
  String get close => 'Fermer';

  @override
  String get unknownVersion => 'Version inconnue';

  @override
  String get maiaProjectSource => 'Projet Maia-3 et code source';

  @override
  String get enCroissantProjectSource => 'Projet En Croissant et code source';

  @override
  String get licence => 'Licence';

  @override
  String get mobileMaiaSource => 'Code source de Mobile Maia';

  @override
  String get aboutPoweredBy =>
      'Propulsé par Maia-3, un moteur d’échecs développé par le Computational Social Science Lab de l’Université de Toronto pour imiter le jeu humain.';

  @override
  String get aboutOffline =>
      'Maia-3 fonctionne entièrement sur votre téléphone. Aucun compte ni connexion réseau n’est nécessaire.';

  @override
  String get aboutBoardCredits =>
      'L’interface de l’échiquier, le thème brun par défaut et les pièces Cburnett sont fournis par Lichess Flutter Chessground. La prise en charge locale de Stockfish utilise Lichess multistockfish.';

  @override
  String get aboutReviewCredits =>
      'La classification des coups et les heuristiques de détection des sacrifices de la révision des parties sont adaptées de l’interface d’échecs libre En Croissant.';

  @override
  String get aboutLicence =>
      'Mobile Maia est un logiciel libre distribué sous licence AGPL-3.0-only, sans aucune garantie. Vous pouvez le redistribuer et le modifier selon les termes de cette licence. Le code source complet est disponible dans le dépôt du projet.';

  @override
  String get aboutIndependent =>
      'Cette application communautaire indépendante n’est pas une application officielle de Maia-3, de l’Université de Toronto, de Lichess ou d’En Croissant.';

  @override
  String get samplingRecommendationWarning =>
      'Le répertoire de Maia peut être plus limité si la variété maximale en ouverture est désactivée.';

  @override
  String get couldNotOpenPgn => 'Impossible d’ouvrir le PGN.';

  @override
  String temperatureValue(String value) {
    return 'Température : $value';
  }

  @override
  String topPValue(String value) {
    return 'Top-P : $value';
  }

  @override
  String analysisRatingValue(String rating) {
    return 'Classement de Maia pour l’analyse : $rating';
  }

  @override
  String secondAnalysisRatingValue(String rating) {
    return 'Classement du second Maia pour l’analyse : $rating';
  }

  @override
  String premovesList(String moves) {
    return 'Pré-coups : $moves';
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
    return 'Profondeur $depth · jusqu’à $seconds s par position, plus jusqu’à $extraSeconds s pour vérifier les coups remarquables.';
  }

  @override
  String chessnutBattery(String percent, String charging) {
    String _temp0 = intl.Intl.selectLogic(charging, {'yes': ' ⚡', 'other': ''});
    return '$percent %$_temp0';
  }

  @override
  String get chessnutBluetoothUnavailable =>
      'Le Bluetooth n’est pas disponible sur cet appareil.';

  @override
  String get chessnutPermissionPending =>
      'Accordez les autorisations Bluetooth, puis reconnectez Chessnut.';

  @override
  String get chessnutBluetoothDisabled =>
      'Activez le Bluetooth, puis reconnectez Chessnut.';

  @override
  String get whiteShort => 'B';

  @override
  String get blackShort => 'N';

  @override
  String get dateUnknown => 'Date inconnue';

  @override
  String get savedGameVersionUnsupported =>
      'Ces données sauvegardées utilisent un format non pris en charge. Mettez Mobile Maia à jour pour les ouvrir. Les données ont été conservées.';

  @override
  String get gameStorageFailed =>
      'Impossible d’accéder au stockage des parties sauvegardées. Veuillez réessayer.';

  @override
  String recentWinResult(String result) {
    return 'Victoire ($result)';
  }

  @override
  String recentLossResult(String result) {
    return 'Défaite ($result)';
  }

  @override
  String recentDrawResult(String result) {
    return 'Nulle ($result)';
  }

  @override
  String get electronicBoardExperimental =>
      'Échiquier électronique (expérimental)';

  @override
  String get connectBoard => 'Connecter l’échiquier';

  @override
  String get chooseBoard => 'Choisir un échiquier';

  @override
  String get chooseAnotherBoard => 'Choisir un autre échiquier';

  @override
  String get boardSearching => 'Recherche d’échiquiers…';

  @override
  String get boardConnecting => 'Connexion à l’échiquier…';

  @override
  String get boardDisconnected => 'Échiquier déconnecté';

  @override
  String get boardConnectionError =>
      'Connexion impossible. Vérifiez le Bluetooth et l’échiquier, puis réessayez.';

  @override
  String get boardStartingPosition =>
      'Placez la position de départ standard sur votre échiquier.';

  @override
  String get boardReady => 'Échiquier prêt';

  @override
  String get boardExperimentalNotice =>
      'La prise en charge de nouveaux échiquiers est expérimentale. Vérifiez les coups sur les deux écrans et signalez les problèmes de connexion.';

  @override
  String get boardGameRestriction =>
      'Les parties sur échiquier électronique sont sans limite de temps.';

  @override
  String get boardConfirmSetup => 'J’ai placé la position de départ';

  @override
  String get boardConfirmSetupHelp =>
      'Vérifiez chaque pièce avant de commencer. Cet échiquier ne peut pas identifier le type de pièce.';

  @override
  String get boardChooseMove => 'Confirmer votre coup sur l’échiquier';

  @override
  String get boardAmbiguousMove =>
      'L’échiquier ne peut pas distinguer ces coups. Choisissez celui que vous avez joué.';

  @override
  String get boardUnavailable =>
      'L’échiquier n’est pas prêt. Reconnectez-le ou continuez sur votre téléphone.';

  @override
  String get boardNewGameConfirmInstruction =>
      'Appuyez à nouveau sur NEW GAME dans les 2,5 secondes pour confirmer, ou utilisez les boutons ci-dessous.';

  @override
  String get boardNewGameConfirmationExpired =>
      'Pour confirmer sur l’échiquier, appuyez deux fois sur NEW GAME en 2,5 secondes.';

  @override
  String get boardPhysicalMove => 'Terminez le coup sur votre échiquier.';

  @override
  String get boardResetPhysical =>
      'Avant de continuer, rétablissez sur l’échiquier la position affichée à l’écran.';

  @override
  String get boardNoResults =>
      'Aucun échiquier compatible trouvé. Réveillez votre échiquier et réessayez.';

  @override
  String get boardWaitingForSelection => 'Choisissez un échiquier à connecter.';

  @override
  String get boardReconnect => 'Reconnecter l’échiquier';

  @override
  String get boardLockedPegasus =>
      'Pegasus est verrouillé. Cette version Dev ne contient pas la clé d’initialisation du fabricant.';

  @override
  String get boardMotorRecovery =>
      'Continuez sur votre téléphone. Cet adaptateur expérimental ne peut pas rétablir en toute sécurité l’état du moteur de l’échiquier.';

  @override
  String get boardConfirmPosition =>
      'Confirmer la position sur l’échiquier physique';

  @override
  String get boardConfirmPositionHelp =>
      'Vérifiez que chaque pièce correspond à la position affichée à l’écran.';

  @override
  String get maiaHistorySetting => 'Utiliser l’historique des positions';

  @override
  String get maiaHistoryHelp =>
      'Permet à Maia d’utiliser jusqu’à sept positions précédentes pour choisir un coup. Dans nos tests avec le modèle 79M, cela a amélioré la précision des prédictions des coups humains d’environ 2 points de pourcentage, mais a parfois entraîné une imitation répétée des coups dans les ouvertures à faible niveau Elo. Pour l’instant, nous recommandons de laisser cette option désactivée.';

  @override
  String get maiaHistoryResearch =>
      'Lire l’étude sur l’historique des positions (en anglais)';

  @override
  String get maiaHistoryOn => 'Historique des positions : activé';

  @override
  String get maiaHistoryOff => 'Historique des positions : désactivé';

  @override
  String get chessboardDeviceName => 'Échiquier';

  @override
  String namedBoardConnected(String boardName) {
    return '$boardName : connecté';
  }

  @override
  String namedBoardDisconnected(String boardName) {
    return '$boardName : déconnecté';
  }

  @override
  String get saveMaiaSamplingData => 'Enregistrer les données de choix de Maia';

  @override
  String get samplingDataHelp =>
      'Enregistrez les probabilités des coups de Maia, les réglages et les coups choisis sur cet appareil pour explorer sa façon de jouer.\n\nLes fichiers exportés contiennent les positions, l’historique des coups ainsi que les données d’entrée et les décisions du modèle.\n\nLes 10 dernières parties avec des données enregistrées sont conservées et présentées de la plus récente à la plus ancienne. Les parties plus anciennes peuvent être supprimées plus tôt si la limite de stockage est atteinte. Ces données sont distinctes des parties récentes.\n\nUtilisez cette fonction si vous souhaitez étudier les détails techniques du fonctionnement de Maia. Les données ne peuvent pas être consultées dans l’application. Elles sont exportées dans un fichier HTML facile à consulter contenant une partie des données, ou dans un fichier JSONL contenant toutes les données enregistrées.\n\nCette fonction est désactivée par défaut. Nous vous recommandons de la laisser désactivée, sauf si vous souhaitez étudier le fonctionnement de Maia.';

  @override
  String get clearSamplingData => 'Effacer les données de choix';

  @override
  String samplingDataStatus(int count) {
    return 'Décisions enregistrées : $count';
  }

  @override
  String get samplingDataError =>
      'Impossible d’accéder aux données de choix. Vous pouvez continuer à jouer.';

  @override
  String get samplingSave => 'Enregistrer…';

  @override
  String get samplingShare => 'Partager…';

  @override
  String get samplingSummary => 'Les choix de Maia';

  @override
  String get samplingReadable => 'Rapport lisible (HTML)';

  @override
  String get samplingReadableHint =>
      'Coups, probabilités et diagrammes. À ouvrir dans un navigateur.';

  @override
  String get samplingResearchHint =>
      'Entrées et sorties brutes du modèle pour une analyse technique.';

  @override
  String get samplingReportExplanation =>
      'Les pourcentages indiquent la probabilité de sélection de chaque coup après application de vos réglages de température et de Top-P. Ils ne représentent ni les chances de gagner ni la qualité des coups.';

  @override
  String get samplingReportPartial =>
      'Seules les décisions enregistrées de Maia sont affichées, pas une partie complète. Les reprises de coups et les nouvelles tentatives peuvent répéter un numéro de coup.';

  @override
  String get samplingReportMissing =>
      'Certaines données ont été supprimées ou n’ont pas pu être enregistrées. Le rapport peut comporter des lacunes.';

  @override
  String get samplingPlayed => 'Coup joué';

  @override
  String get samplingNotPlayed => 'Non enregistré comme joué';

  @override
  String get samplingAlternatives => 'Autres coups probables';

  @override
  String samplingGame(String number) {
    return 'Partie $number';
  }

  @override
  String samplingRecords(String count) {
    return 'Décisions enregistrées : $count';
  }

  @override
  String get samplingMostProbable => 'Le plus probable';

  @override
  String get samplingPlayedMostProbable =>
      'Le coup le plus probable a été joué';

  @override
  String samplingChance(String move, String odds) {
    return '$move avait environ 1 chance sur $odds d’être joué.';
  }

  @override
  String samplingCertain(String move) {
    return '$move serait sélectionné à coup sûr (100 %).';
  }

  @override
  String samplingAlmostCertain(String move) {
    return '$move avait une probabilité presque certaine d’être sélectionné.';
  }

  @override
  String get samplingReportRetention =>
      'Les 10 dernières parties enregistrées sont conservées et affichées de la plus récente à la plus ancienne. Les parties anciennes peuvent être supprimées plus tôt si la limite de stockage est atteinte.';

  @override
  String get samplingJumpToGame => 'Aller à la partie';

  @override
  String get samplingBackToGames => 'Retour à la liste des parties';

  @override
  String get samplingIncomplete => 'Inachevée';

  @override
  String get samplingUnknownResult => 'Résultat inconnu';

  @override
  String get samplingOpeningUnknown => 'Ouverture inconnue';

  @override
  String get samplingTimeUnknown => 'Heure inconnue';

  @override
  String get samplingWin => 'Victoire';

  @override
  String get samplingLoss => 'Défaite';

  @override
  String get samplingDraw => 'Partie nulle';

  @override
  String get samplingDeleteData => 'Effacer les données';

  @override
  String get samplingClearConfirmation =>
      'Effacer toutes les données de choix de coups de Maia ? Elles ne pourront pas être récupérées.';

  @override
  String get analysisSettings => 'Paramètres d\'analyse';

  @override
  String get samplingData => 'Données de choix de coups';

  @override
  String get resetSettingsDefaultsScope =>
      'Rétablit tous les réglages de cet écran. Les parties et les données de choix de coups enregistrées sont conservées.';

  @override
  String get settingsResetError =>
      'Certains réglages n’ont pas pu être réinitialisés. Veuillez réessayer.';

  @override
  String get resetSettingsConfirmation =>
      'Rétablir tous les réglages par défaut ?';

  @override
  String get resetSettingsKeepData =>
      'Vos parties et données de choix de coups enregistrées seront conservées.';

  @override
  String get resetSettingsAction => 'Rétablir les réglages';

  @override
  String get samplingHelpIntro =>
      'La température et Top-P déterminent ensemble la variété dans le jeu de Maia.\n\nNous recommandons une température de 1,0, Top-P à 0,95 et l’option « Variété maximale dans l’ouverture » activée. Ce sont les réglages par défaut. D’après notre recherche, ils offrent un bon équilibre entre un jeu proche de celui des humains, des ouvertures variées et moins de gaffes inhabituelles.\n\nLa suite explique comment fonctionnent ces réglages.';

  @override
  String get samplingHelpVariety =>
      'Température\n\nÀ température 0, Maia joue toujours le coup qu’elle prédit comme le plus probable pour un joueur de l’Elo sélectionné. C’est ce que l’on appelle techniquement argmax.\n\nÀ température 1, Maia envisage tous les coups qu’elle prédit qu’un joueur de l’Elo sélectionné pourrait jouer, et choisit parmi eux selon leurs probabilités.\n\nAvec une température entre 0 et 1, Maia donne davantage de poids aux coups qu’elle estime les plus probables. Plus la température est basse, plus ses choix sont prévisibles.\n\nPar exemple, dans nos tests avec le modèle 79M et une valeur Elo de 1600 en entrée pour les deux joueurs, les probabilités du premier coup de Maia avec les blancs étaient approximativement les suivantes :\n\n• 1. e4 : 64 %\n• 1. d4 : 25 %\n• 1. c4 : 3 %\n• Tous les autres coups réunis : 8 %\n\nÀ température 0, Maia jouait toujours 1. e4.\n\nÀ température 0,5, elle jouait 1. e4 environ 86 % du temps et 1. d4 environ 13 % du temps. Les autres coups restaient possibles, mais représentaient ensemble moins de 1 %.\n\nÀ température 1, Maia suivait les probabilités d’origine indiquées ci-dessus.';

  @override
  String get samplingHelpDefaults =>
      'Top-P\n\nTop-P filtre les coups disponibles après que la température a ajusté leurs probabilités.\n\nAvec Top-P à 1, aucun filtrage n’est appliqué. Tous les coups disponibles peuvent être joués selon leurs probabilités ajustées par la température.\n\nAvec Top-P à 0,95, Maia conserve les coups les plus probables jusqu’à ce que leur probabilité cumulée atteigne au moins 95 %, puis choisit parmi eux. Les coups exclus représentent au maximum 5 % de la probabilité.\n\nAvec Top-P à 0, Maia choisit toujours le coup le plus probable. L’effet est le même qu’avec une température de 0 : mettre l’un ou l’autre réglage à 0 suffit pour obtenir argmax.\n\nDans notre exemple d’ouverture, une température de 1 et Top-P à 0,60 feraient toujours jouer 1. e4 à Maia. Ce coup représente à lui seul environ 64 % de la probabilité ; aucun autre coup n’est donc nécessaire pour atteindre le seuil de 60 %.';

  @override
  String get samplingHelpStrength =>
      'Comment ces réglages influencent-ils le jeu de Maia ?\n\nVous pouvez voir Top-P comme un ange sur l’épaule de Maia. À 0, l’ange dit à Maia d’ignorer les coups moins probables, qui peuvent comprendre des gaffes ou des coups peu solides. À 1,0, l’ange est parti, et Maia pourrait même choisir le coup le plus fou et le plus improbable.\n\nDans nos tests en confrontation directe au réglage 1600, argmax a surpassé température 1,0 / Top-P 1,0 d’un écart équivalant à environ 300 points Elo. Cependant, argmax limitait aussi les choix d’ouverture à un éventail restreint, composé surtout de variantes principales.';

  @override
  String get samplingHelpArgmax =>
      'Nous avons donc introduit « Variété maximale dans l’ouverture » : un interrupteur qui fait jouer Maia avec une température de 1,0 et Top-P à 1,0 pendant les cinq premiers coups de chaque camp. Vous pourriez voir des choses folles dans l’ouverture ! À partir du sixième coup, Maia revient aux réglages que vous avez configurés.';

  @override
  String get samplingHelpTopP =>
      'Nous recommandons de garder « Variété maximale dans l’ouverture » activée, avec la température réglée sur 1,0 et Top-P sur 0,95. C’est comme un joueur créatif avec un ange sur l’épaule, qui le dissuade au moins de jouer les coups complètement farfelus : les coups les moins probables dont la probabilité cumulée représente jusqu’à 5 %. Ils pourraient certes être brillants, mais aussi être des gaffes absurdes. Cela devrait offrir un bon équilibre entre variété en ouverture, créativité en milieu de partie et jeu plus fort grâce à l’exclusion de certaines gaffes très peu probables.\n\nPour les plus courageux, la température 0 a produit le jeu le plus fort dans nos tests. Bonne chance !';

  @override
  String get samplingHelpResearchIntro =>
      'Le guide visuel présente la recherche derrière ces choix et les liens vers les résultats complets.';

  @override
  String get samplingFullVarietyNotice =>
      'Maia peut commettre davantage de gaffes inhabituelles avec température et Top-P à 1,0 / 1,0.';

  @override
  String get samplingArgmaxNotice =>
      'Maia peut jouer plus fort avec température ou Top-P à 0. Bonne chance !';

  @override
  String get topPNotUsed => 'Top-P : non utilisé';

  @override
  String get topPNotUsedTitle => 'Pourquoi Top-P est inutilisé';

  @override
  String get topPNotUsedHelp =>
      'À température 0, Maia choisit toujours un coup de probabilité maximale : Top-P est donc sans effet. Sa valeur est conservée et redevient disponible quand vous augmentez la température. Si la variété en ouverture est activée, les cinq premiers coups de chaque camp utilisent toujours 1,0 / 1,0.';

  @override
  String get samplingLowerNotice =>
      'Maia peut jouer plus fort avec une température ou un Top-P plus bas.';

  @override
  String get appearance => 'Apparence';

  @override
  String get appearanceSystemColors => 'Utiliser les couleurs du système';

  @override
  String get appearanceSystemColorsHelp =>
      'Utiliser la palette de couleurs Android';

  @override
  String get appearanceSystemColorsUnavailable =>
      'Indisponible sur cet appareil. Nécessite Android 12 ou une version ultérieure.';

  @override
  String get appearancePureBlack => 'Fond noir pur';

  @override
  String get appearancePureBlackHelp =>
      'Utiliser des fonds noirs en mode sombre';

  @override
  String get appearancePreferenceError =>
      'L’apparence a changé, mais n’a pas pu être enregistrée. Veuillez réessayer.';

  @override
  String get appearanceTheme => 'Thème';

  @override
  String get appearanceLight => 'Clair';

  @override
  String get appearanceDark => 'Sombre';

  @override
  String get appearanceSystemDefault => 'Thème de l\'appareil';

  @override
  String get boardSettings => 'Échiquier';

  @override
  String get boardCoordinates => 'Coordonnées';

  @override
  String get boardLegalMoves => 'Destinations des coups légaux';

  @override
  String get boardLastMove => 'Surbrillance du dernier coup';

  @override
  String get boardAnimation => 'Animation des pièces';

  @override
  String get boardMagnify => 'Grossir la pièce déplacée';

  @override
  String get boardDragTarget => 'Cible de la pièce déplacée';

  @override
  String get boardTargetCircle => 'Cercle';

  @override
  String get boardTargetSquare => 'Carré';

  @override
  String get boardTargetNone => 'Aucune';

  @override
  String get boardPreferenceError =>
      'Impossible d’enregistrer les réglages de l’échiquier. Réessayez.';

  @override
  String get boardDesign => 'Échiquier';

  @override
  String get boardPieceSet => 'Jeu de pièces';

  @override
  String get showMaiaScore => 'Afficher les chances de gain (score) Maia en %';

  @override
  String get maiaScore => 'Score Maia';

  @override
  String get maiaScoreEqual => 'Équilibré';

  @override
  String get maiaScoreHelp =>
      'Affiche en haut de l’écran l’évaluation par Maia des chances de gagner (de marquer des points).\nLe point blanc ou noir indique à quel camp correspond le pourcentage.';

  @override
  String get maiaScoreExpectedHelp =>
      'Par exemple, Blancs 60% signifie que Maia estime que les Blancs marqueraient environ 60 points sur 100 parties à partir de cette position. Une victoire rapporte 1 point ; une nulle, ½ point.';

  @override
  String get maiaScoreInputsHelp =>
      'L’estimation utilise le classement d’analyse Maia sélectionné pour les deux joueurs. Si deux Maias sont activées, chacune affiche sa propre estimation à son propre classement.';

  @override
  String get maiaScorePreferenceError =>
      'Impossible d’enregistrer les réglages du score Maia. Réessayez.';

  @override
  String get maiaScoreResearchLink =>
      'Le score de Maia est-il fiable ? (en anglais)';

  @override
  String get maiaScoreStockfishHelp =>
      'Il peut être utile de comparer cette estimation à l’évaluation de Stockfish. Ce n’est pas parce que Stockfish juge un camp meilleur qu’il est facile pour un humain de trouver les bons coups pour concrétiser cet avantage !';

  @override
  String get editorMoveTool => 'Déplacer les pièces';

  @override
  String get editorEraseTool => 'Effacer les pièces';

  @override
  String get editorEmptySquare => 'Case vide';

  @override
  String get editorPositionSettings => 'Réglages de la position';

  @override
  String get editorImageImportUnavailable =>
      'Importer une position depuis une image (pas encore disponible)';

  @override
  String get editorShareFen => 'Partager la FEN';

  @override
  String get editorFenMetadata => 'Métadonnées FEN';

  @override
  String get editorHalfmoveClock => 'Compteur de demi-coups';

  @override
  String get editorFullmoveNumber => 'Numéro du coup';

  @override
  String get editorWhitePawn => 'Pion blanc';

  @override
  String get editorWhiteKnight => 'Cavalier blanc';

  @override
  String get editorWhiteBishop => 'Fou blanc';

  @override
  String get editorWhiteRook => 'Tour blanche';

  @override
  String get editorWhiteQueen => 'Dame blanche';

  @override
  String get editorWhiteKing => 'Roi blanc';

  @override
  String get editorBlackPawn => 'Pion noir';

  @override
  String get editorBlackKnight => 'Cavalier noir';

  @override
  String get editorBlackBishop => 'Fou noir';

  @override
  String get editorBlackRook => 'Tour noire';

  @override
  String get editorBlackQueen => 'Dame noire';

  @override
  String get editorBlackKing => 'Roi noir';

  @override
  String get continuationUseBoard => 'Utiliser un échiquier électronique';

  @override
  String get continuationConnectHelp => 'Connectez un échiquier compatible.';

  @override
  String get continuationBoardUntimed =>
      'Les parties sur échiquier électronique sont sans limite de temps.';

  @override
  String get continuationSetUpBoard => 'Placer les pièces';

  @override
  String get continuationSetupHelp =>
      'Reproduisez la position affichée sur votre échiquier. La partie commence lorsque les pièces correspondent.';

  @override
  String get continuationBoardUnsupported =>
      'Pour le moment, seuls les échiquiers Chessnut permettent de continuer depuis une position.';

  @override
  String get sessionRecovery =>
      'Mobile Maia a ouvert l’accueil pour éviter de rouvrir une session qui a pu provoquer un plantage. Vos parties enregistrées et vos réglages ont été conservés.';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get about => 'Über';

  @override
  String get analysisBoard => 'Analysebrett';

  @override
  String get back => 'Zurück';

  @override
  String get black => 'Schwarz';

  @override
  String get cancelPremoves => 'Vorauszüge abbrechen';

  @override
  String get chessnutExperimental => 'Chessnut (experimentell)';

  @override
  String get connectChessnut => 'Chessnut verbinden';

  @override
  String get disconnect => 'Verbindung trennen';

  @override
  String get engineSettings => 'Engine-Einstellungen';

  @override
  String get gameMenu => 'Partiemenü';

  @override
  String get gameReady => 'Partie bereit';

  @override
  String get gameSettings => 'Partieeinstellungen';

  @override
  String get home => 'Start';

  @override
  String get playMaia => 'Gegen Maia spielen';

  @override
  String get random => 'Zufällige Farbe';

  @override
  String get recentGames => 'Neueste Partien';

  @override
  String get resign => 'Aufgeben';

  @override
  String get settings => 'Einstellungen';

  @override
  String get startGame => 'Partie starten';

  @override
  String get timeControl => 'Bedenkzeit';

  @override
  String get white => 'Weiß';

  @override
  String get unlimited => 'Unbegrenzt';

  @override
  String get custom => 'Andere Spielzeit';

  @override
  String get seconds => 'Sekunden';

  @override
  String get yourSide => 'Deine Farbe';

  @override
  String get you => 'Du';

  @override
  String get systemDefault => 'Systemstandard';

  @override
  String get language => 'Sprache';

  @override
  String get playMaiaRating => 'Maia-Rating (Spiel)';

  @override
  String get minutes => 'Minuten';

  @override
  String get increment => 'Inkrement';

  @override
  String get gameSounds => 'Partietöne';

  @override
  String get movesCapturesErrorsAndGameEnd =>
      'Züge, Schlagen, Fehler und Partieende';

  @override
  String get hapticFeedback => 'Haptisches Feedback';

  @override
  String get touchFeedbackForMovesChecksErrorsAndGameEnd =>
      'Vibration bei Zügen, Schachgeboten, Fehlern und Partieende';

  @override
  String get premoves => 'Vorauszüge';

  @override
  String get queueAMoveWhileMaiaIsThinking =>
      'Einen Zug vormerken, während Maia nachdenkt';

  @override
  String get oneHundredMsPremovePenalty => '100 ms Zeitabzug pro Vorauszug';

  @override
  String get use01SecondsPerPremoveInTimedGames =>
      'Bei Partien mit Bedenkzeit 0,1 Sekunden pro Vorauszug abziehen';

  @override
  String get allowMultiplePremoves => 'Mehrere Vorauszüge erlauben';

  @override
  String get queueASequenceAnIllegalMoveCancelsTheRest =>
      'Eine Zugfolge vormerken; ein regelwidriger Zug verwirft die restlichen Züge';

  @override
  String get humanMoveTiming => 'Natürliche Zugpausen';

  @override
  String get variableNaturalPausesBeforeMaiaMoves =>
      'Unterschiedlich lange, natürliche Pausen vor Maias Zügen';

  @override
  String get aboutTemperatureAndTopP => 'Über Temperatur und Top-P';

  @override
  String get temperature => 'Temperatur';

  @override
  String get topP => 'Top-P';

  @override
  String get maxOpeningVariety => 'Maximale Vielfalt in der Eröffnung';

  @override
  String get maxOpeningVarietyHelp =>
      'Nicht nötig, wenn Temperatur und Top-P auf den Standardwerten 1,0 / 1,0 stehen. Für die ersten fünf Züge jeder Seite werden 1,0 / 1,0 verwendet. Ab dem 6. Zug gelten wieder deine eingestellten Werte.\n\nZiel ist eine möglichst große Eröffnungsvielfalt für Maia. Im weiteren Partieverlauf kann Maia möglicherweise stärker spielen, indem niedrigere Werte für Temperatur und/oder Top-P die Auswahl von Zügen mit geringer Wahrscheinlichkeit seltener machen.';

  @override
  String get maiaAnalysisRating => 'Maia-Rating (Analyse)';

  @override
  String get addSecondMaiaEngine => 'Zweite Maia-Engine hinzufügen';

  @override
  String get compareAnotherMaiaRatingInAnalysisAndReview =>
      'Ein weiteres Maia-Rating in Analyse und Partierückblick vergleichen';

  @override
  String get secondMaiaAnalysisRating => 'Zweites Maia-Rating (Analyse)';

  @override
  String get gameAnalysisQuality => 'Qualität der Partieanalyse';

  @override
  String get resetSettingsDefaults => 'Einstellungen zurücksetzen';

  @override
  String get boardSounds => 'Bretttöne';

  @override
  String get beepForCheckCheckmateAndCompletedIllegalMoves =>
      'Signalton bei Schach, Schachmatt und nach Ausführung eines regelwidrigen Zugs.';

  @override
  String get copyDiagnostics => 'Diagnosedaten kopieren';

  @override
  String get diagnosticsCopied => 'Diagnosedaten kopiert';

  @override
  String get newGame => 'Neue Partie';

  @override
  String get resetGame => 'Partie zurücksetzen';

  @override
  String get shareAndExport => 'Teilen und exportieren';

  @override
  String get savePgnFile => 'PGN-Datei speichern';

  @override
  String get sharePgn => 'PGN teilen';

  @override
  String get copyPgn => 'PGN kopieren';

  @override
  String get copyFen => 'FEN kopieren';

  @override
  String get maiaErrorRetry => 'Maia-Fehler. Erneut versuchen';

  @override
  String get maiaErrorPleaseRetry => 'Maia-Fehler. Bitte erneut versuchen.';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get maiaIsThinking => 'Maia denkt nach…';

  @override
  String get history => 'VERLAUF';

  @override
  String get start => 'START';

  @override
  String get chessnutStatus => 'Chessnut-Status';

  @override
  String get leaveCurrentGame => 'Aktuelle Partie verlassen?';

  @override
  String get yourGameWillBeKeptInRecentGames =>
      'Deine Partie wird unter „Neueste Partien“ gespeichert.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get continueAction => 'Fortfahren';

  @override
  String get startANewGame => 'Eine neue Partie starten?';

  @override
  String get resetGameQuestion => 'Partie zurücksetzen?';

  @override
  String get yourCompletedGameWillRemainInRecentGames =>
      'Deine beendete Partie bleibt unter „Neueste Partien“ gespeichert.';

  @override
  String get thisGameWillBePermanentlyErased =>
      'Diese Partie wird endgültig gelöscht.';

  @override
  String get startNewGame => 'Neue Partie starten';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get flipBoard => 'Brett drehen';

  @override
  String get offerDraw => 'Remis anbieten';

  @override
  String get takeBackMove => 'Zugrücknahme';

  @override
  String get whiteIsVictorious => 'Weiß gewinnt';

  @override
  String get blackIsVictorious => 'Schwarz gewinnt';

  @override
  String get theGameIsADraw => 'Das Spiel ist Remis.';

  @override
  String get theGameHasEnded => 'Die Partie ist beendet';

  @override
  String get rematch => 'Revanche';

  @override
  String get fast => 'Schnell';

  @override
  String get balanced => 'Ausgewogen';

  @override
  String get thorough => 'Gründlich';

  @override
  String get continueFromHere => 'Von hier aus weiterspielen';

  @override
  String get load => 'Laden';

  @override
  String get editBoard => 'Stellung bearbeiten';

  @override
  String get done => 'Fertig';

  @override
  String get whitePieces => 'Weiße Figuren';

  @override
  String get blackPieces => 'Schwarze Figuren';

  @override
  String get whiteToMove => 'Weiß am Zug';

  @override
  String get blackToMove => 'Schwarz am Zug';

  @override
  String get castlingRights => 'Rochaderechte';

  @override
  String get whiteKingside => 'Weiß O-O';

  @override
  String get whiteQueenside => 'Weiß O-O-O';

  @override
  String get blackKingside => 'Schwarz O-O';

  @override
  String get blackQueenside => 'Schwarz O-O-O';

  @override
  String get enPassantTarget => 'En-passant-Zielfeld';

  @override
  String get startingPosition => 'Anfangsposition';

  @override
  String get clearBoard => 'Brett räumen';

  @override
  String get loadFen => 'FEN laden';

  @override
  String get loadPgn => 'PGN laden';

  @override
  String get openPgnFile => 'PGN-Datei öffnen';

  @override
  String get clearMoves => 'Züge löschen';

  @override
  String get boardEditor => 'Stellung aufbauen';

  @override
  String get endPosition => 'Endstellung';

  @override
  String get analysisMenu => 'Analysemenü';

  @override
  String get turnEngineOff => 'Engine ausschalten';

  @override
  String get turnEngineOn => 'Engine einschalten';

  @override
  String get moves => 'Züge';

  @override
  String get computerAnalysis => 'Computer-Analyse';

  @override
  String get backToGame => 'Zurück zur Partie';

  @override
  String get expandVariations => 'Varianten ausklappen';

  @override
  String get collapseVariations => 'Varianten einklappen';

  @override
  String get promoteVariation => 'Variante aufwerten';

  @override
  String get makeMainLine => 'Zur Hauptvariante machen';

  @override
  String get deleteFromHere => 'Ab hier löschen';

  @override
  String get analyzing => 'Analyse läuft…';

  @override
  String get noLegalMoves => 'Keine regelgerechten Züge';

  @override
  String get unavailable => 'Nicht verfügbar';

  @override
  String get analysisFailed =>
      'Analyse fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get analysisStopped => 'Computer-Analyse angehalten.';

  @override
  String get classifyingMoves => 'Züge werden eingestuft…';

  @override
  String get graphReadyClassifying =>
      'Diagramm fertig · Züge werden eingestuft…';

  @override
  String get stopAnalysis => 'Analyse anhalten';

  @override
  String get runAnalysisAgain => 'Computer-Analyse erneut starten';

  @override
  String get runAnalysis => 'Computer-Analyse starten';

  @override
  String get analysisExplanation =>
      'Starte die Computer-Analyse, um das Bewertungsdiagramm und die Genauigkeit für Weiß und Schwarz zu berechnen.';

  @override
  String get pgnCopied => 'PGN kopiert.';

  @override
  String get fenCopied => 'FEN kopiert';

  @override
  String get rawProbabilitiesExplanation =>
      'Rohe Modellwahrscheinlichkeiten, über alle regelgerechten Züge normalisiert. Temperatur und Top-P werden nicht angewendet.';

  @override
  String get showRawProbabilities =>
      'Alle rohen Modellwahrscheinlichkeiten anzeigen';

  @override
  String get pasteFen => 'Eine vollständige FEN mit sechs Feldern einfügen';

  @override
  String get pastePgn => 'Eine Partie im PGN-Format einfügen';

  @override
  String get invalidPosition =>
      'Ungültige Stellung. Prüfe das Brett und die FEN.';

  @override
  String get pgnLoadFailed =>
      'Die PGN-Partie konnte nicht geladen werden. Prüfe die Datei oder den eingefügten Text.';

  @override
  String get goToNext => 'Zum nächsten Zug';

  @override
  String tapForNext(String label) {
    return '$label · für den nächsten Zug tippen';
  }

  @override
  String get notEnoughMoves => 'Nicht genügend Züge';

  @override
  String get gameAccuracy => 'Partiegenauigkeit';

  @override
  String get accuracy => 'Genauigkeit';

  @override
  String get analysisGraph => 'Diagramm der Computer-Analyse';

  @override
  String maiaMoveProbabilities(int elo) {
    return 'Zugwahrscheinlichkeiten von Maia $elo';
  }

  @override
  String otherProbability(String probability) {
    return 'Sonstige $probability';
  }

  @override
  String otherLegalProbability(String probability) {
    return 'andere regelgerechte Züge $probability';
  }

  @override
  String maiaProbabilitySemantics(String title, String moves) {
    return '$title. $moves.';
  }

  @override
  String analysisProgress(int completed, int total) {
    return 'Analysierte Stellungen: $completed von $total…';
  }

  @override
  String graphPosition(int position, int total, String score) {
    return 'Stellung $position von $total  ·  $score';
  }

  @override
  String positionNumber(int position) {
    return 'Stellung $position';
  }

  @override
  String classificationCount(int count, String side, String classification) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$side: $count Züge mit Bewertung „$classification“',
      one: '$side: $count Zug mit Bewertung „$classification“',
    );
    return '$_temp0';
  }

  @override
  String get classificationBrilliant => 'Brillanter Zug';

  @override
  String get classificationGood => 'Guter Zug';

  @override
  String get classificationInteresting => 'Interessanter Zug';

  @override
  String get classificationDubious => 'Fragwürdiger Zug';

  @override
  String get classificationMistake => 'Fehler';

  @override
  String get classificationBlunder => 'Grober Patzer';

  @override
  String get gameReview => 'Partierückblick';

  @override
  String materialPawn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bauern',
      one: '$count Bauer',
    );
    return '$_temp0';
  }

  @override
  String materialKnight(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Springer',
      one: '$count Springer',
    );
    return '$_temp0';
  }

  @override
  String materialBishop(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Läufer',
      one: '$count Läufer',
    );
    return '$_temp0';
  }

  @override
  String materialRook(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Türme',
      one: '$count Turm',
    );
    return '$_temp0';
  }

  @override
  String materialQueen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Damen',
      one: '$count Dame',
    );
    return '$_temp0';
  }

  @override
  String materialAdvantage(String score) {
    return '$score Materialvorteil';
  }

  @override
  String materialDescription(String side, String description) {
    return 'Materialunterschied für $side: $description';
  }

  @override
  String get previousMove => 'Vorheriger Zug';

  @override
  String get nextMove => 'Nächster Zug';

  @override
  String get beginning => 'Anfang';

  @override
  String get latestPosition => 'aktuelle Stellung';

  @override
  String holdForDestination(String destination) {
    return 'Gedrückt halten: $destination';
  }

  @override
  String get phaseOpening => 'Eröffnung';

  @override
  String get phaseMiddlegame => 'Mittelspiel';

  @override
  String get phaseEndgame => 'Endspiel';

  @override
  String get pieceKing => 'König';

  @override
  String get pieceQueen => 'Dame';

  @override
  String get pieceRook => 'Turm';

  @override
  String get pieceBishop => 'Läufer';

  @override
  String get pieceKnight => 'Springer';

  @override
  String get piecePawn => 'Bauer';

  @override
  String recentPlayerMaia(String rating) {
    return 'Spieler — Maia $rating';
  }

  @override
  String recentMaiaPlayer(String rating) {
    return 'Maia $rating — Spieler';
  }

  @override
  String get recentIncomplete => 'Unvollständig';

  @override
  String get recentCompleted => 'Beendet';

  @override
  String get recentDeleteFailed =>
      'Gespeicherte Partien konnten nicht gelöscht werden. Bitte erneut versuchen.';

  @override
  String get recentOpenFailed =>
      'Die gespeicherte Partie konnte nicht geöffnet werden. Bitte erneut versuchen.';

  @override
  String recentDeleteTitle(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString Partien löschen?',
      one: 'Gespeicherte Partie löschen?',
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
          'Diese $countString gespeicherten Partien werden endgültig gelöscht.',
      one: 'Diese gespeicherte Partie wird endgültig gelöscht.',
    );
    return '$_temp0';
  }

  @override
  String get deleteAction => 'Löschen';

  @override
  String get recentUpdating => 'Gespeicherte Partien werden aktualisiert';

  @override
  String get recentCancelSelection => 'Auswahl abbrechen';

  @override
  String get recentClearSelection => 'Auswahl aufheben';

  @override
  String get recentSelectAll => 'Alle Partien auswählen';

  @override
  String get recentDeleteSelected => 'Ausgewählte Partien löschen';

  @override
  String get recentSelectGames => 'Partien auswählen';

  @override
  String get recentDeleteAll => 'Alle Partien löschen';

  @override
  String get recentDeleteOne => 'Gespeicherte Partie löschen';

  @override
  String recentSelectedCount(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString ausgewählt';
  }

  @override
  String get recentLoadFailed =>
      'Gespeicherte Partien konnten nicht geladen werden. Bitte erneut versuchen.';

  @override
  String get recentEmpty =>
      'Hier erscheinen beendete Partien und unvollständige Partien, die beim Wechsel zur Startseite gespeichert wurden.';

  @override
  String recentGameSummary(String result, String date) {
    return '$result · $date';
  }

  @override
  String get diagnosticsScreenError =>
      'Bei Mobile Maia ist ein Anzeigefehler aufgetreten.';

  @override
  String get diagnosticsScreenInstructions =>
      'Kopiere die Diagnosedaten und sende sie zusammen mit einer Beschreibung dessen, was du direkt vor dem Erscheinen dieser Ansicht angetippt hast.';

  @override
  String get pgnSaved => 'PGN gespeichert';

  @override
  String get pgnExportFailed =>
      'PGN konnte nicht exportiert werden. Deine Partie ist weiterhin lokal gespeichert.';

  @override
  String get languagePreferenceError =>
      'Die Sprache konnte nicht gespeichert oder wiederhergestellt werden. Deine Partien sind davon nicht betroffen. Bitte wähle die Sprache erneut aus.';

  @override
  String playRatingValue(String rating) {
    return 'Maia-Rating (Spiel): $rating';
  }

  @override
  String minutesValue(String minutes) {
    return 'Minuten: $minutes';
  }

  @override
  String incrementSecondsValue(String seconds) {
    return 'Inkrement: $seconds s';
  }

  @override
  String get chooseSettings =>
      'Wähle deine Einstellungen und starte eine Partie.';

  @override
  String get gameRestored => 'Partie wiederhergestellt.';

  @override
  String get reconnectChessnut => 'Verbinde Chessnut erneut, um fortzufahren.';

  @override
  String get chessnutConnectionError =>
      'Fehler bei der Verbindung mit Chessnut.';

  @override
  String get searchingChessnut => 'Chessnut wird gesucht…';

  @override
  String get couldNotConnectChessnut =>
      'Chessnut konnte nicht verbunden werden.';

  @override
  String get chessnutAndroidOnly => 'Chessnut wird auf Android unterstützt.';

  @override
  String get chessnutIsDisconnected =>
      'Die Verbindung zu Chessnut ist getrennt.';

  @override
  String get yourMove => 'Du bist am Zug.';

  @override
  String get yourMoveChessnut => 'Du bist auf Chessnut am Zug.';

  @override
  String get chessnutReady => 'Chessnut ist bereit.';

  @override
  String get chessnutStartingPosition =>
      'Baue die Grundstellung auf Chessnut auf.';

  @override
  String get takebackCompleteYourMove =>
      'Zugrücknahme abgeschlossen. Du bist auf Chessnut am Zug.';

  @override
  String get takebackCompleteThinking =>
      'Zugrücknahme abgeschlossen. Maia denkt nach…';

  @override
  String get restoreLitSquares =>
      'Zugrücknahme: Stelle die Stellung auf den beleuchteten Feldern von Chessnut wieder her.';

  @override
  String get completeMaiaLitMove =>
      'Führe Maias angezeigten Zug auf Chessnut zu Ende.';

  @override
  String get illegalChessnutPosition =>
      'Diese Stellung ergibt sich nicht aus einem regelgerechten Zug. Korrigiere die beleuchteten Felder.';

  @override
  String get completeYourChessnutMove =>
      'Führe deinen Zug auf Chessnut zu Ende.';

  @override
  String get connectChessnutFirst => 'Verbinde Chessnut vor dem Start.';

  @override
  String get gameInProgress => 'Partie läuft.';

  @override
  String get timeoutInsufficientMaterial =>
      'Remis — Zeitüberschreitung bei unzureichendem Mattmaterial des Gegners.';

  @override
  String get whiteOutOfTime => 'Zeitüberschreitung von Weiß';

  @override
  String get blackOutOfTime => 'Zeitüberschreitung von Schwarz';

  @override
  String get makeMaiaLitMove => 'Führe Maias angezeigten Zug auf Chessnut aus.';

  @override
  String get checkmateMaiaWins => 'Schachmatt — Maia gewinnt.';

  @override
  String get checkmateYouWin => 'Schachmatt — du gewinnst!';

  @override
  String get drawResult => 'Remis';

  @override
  String get drawByAgreement => 'Remis durch Einigung';

  @override
  String get youWin => 'Du gewinnst.';

  @override
  String get maiaWins => 'Maia gewinnt.';

  @override
  String get gameEnded => 'Partie beendet.';

  @override
  String get consideringDraw => 'Maia prüft das Remisangebot…';

  @override
  String get maiaDeclinedDraw => 'Maia hat das Remisangebot abgelehnt.';

  @override
  String get couldNotEvaluateDraw =>
      'Das Remisangebot konnte nicht bewertet werden.';

  @override
  String get youResigned => 'Du hast aufgegeben — Maia gewinnt.';

  @override
  String get moveTakenBack => 'Zugrücknahme abgeschlossen. Du bist am Zug.';

  @override
  String get connectingChessnut => 'Verbindung mit Chessnut wird hergestellt…';

  @override
  String get chessnutUnavailable => 'Chessnut nicht verfügbar';

  @override
  String get chessnutDisconnected => 'Chessnut-Verbindung getrennt';

  @override
  String get reconnect => 'Erneut verbinden';

  @override
  String get playInApp => 'In der App spielen';

  @override
  String get continueGameOnScreen =>
      'Diese Partie auf dem Bildschirm fortsetzen';

  @override
  String get checkCheckmateIllegalMoves =>
      'Schach, Schachmatt und regelwidrige Züge';

  @override
  String get offerDrawQuestion => 'Remis anbieten?';

  @override
  String get resignGameQuestion => 'Partie aufgeben?';

  @override
  String get resignEndsImmediately => 'Dadurch wird die Partie sofort beendet.';

  @override
  String get premoveLimit =>
      'Es können bis zu 64 Vorauszüge vorgemerkt werden.';

  @override
  String get chessnutGameRestriction =>
      'Mit Chessnut sind nur Partien ohne Zeitbegrenzung aus der Grundstellung möglich.';

  @override
  String get samplingTitle => 'Temperatur und Top-P';

  @override
  String get samplingDefaultsQuestion =>
      'Wähle, wie abwechslungsreich Maia spielen soll';

  @override
  String get samplingResearch => 'Vollständige Forschungsdaten (JSONL)';

  @override
  String get samplingResearchLink => 'Vollständige Forschungsdaten (Englisch)';

  @override
  String get close => 'Schließen';

  @override
  String get unknownVersion => 'Unbekannte Version';

  @override
  String get maiaProjectSource => 'Maia-3-Projekt und Quellcode';

  @override
  String get enCroissantProjectSource =>
      'Projekt und Quellcode von En Croissant';

  @override
  String get licence => 'Lizenz';

  @override
  String get mobileMaiaSource => 'Quellcode von Mobile Maia';

  @override
  String get aboutPoweredBy =>
      'Basiert auf Maia-3, der menschenähnlichen Schachengine des Computational Social Science Lab der University of Toronto.';

  @override
  String get aboutOffline =>
      'Maia-3 läuft vollständig auf deinem Smartphone. Ein Konto oder eine Netzwerkverbindung ist nicht erforderlich.';

  @override
  String get aboutBoardCredits =>
      'Brettoberfläche, braunes Standarddesign und Cburnett-Figuren stammen von Lichess Flutter Chessground. Für die lokale Stockfish-Unterstützung wird Lichess multistockfish verwendet.';

  @override
  String get aboutReviewCredits =>
      'Die Zugeinstufung und die Heuristiken zur Opfererkennung im Partierückblick wurden aus der quelloffenen Schachoberfläche En Croissant übernommen und angepasst.';

  @override
  String get aboutLicence =>
      'Mobile Maia ist freie Software unter der Lizenz AGPL-3.0-only und wird ohne jegliche Gewährleistung bereitgestellt. Du darfst sie gemäß den Bedingungen dieser Lizenz weitergeben und verändern. Der vollständige Quellcode ist im Projekt-Repository verfügbar.';

  @override
  String get aboutIndependent =>
      'Diese unabhängige Community-App ist keine offizielle Anwendung von Maia-3, der University of Toronto, Lichess oder En Croissant.';

  @override
  String get samplingRecommendationWarning =>
      'Niedrigere Werte für Temperatur oder Top-P können Maia im Mittelspiel stärker machen, verringern aber die Eröffnungsvielfalt. Näheres steht unter dem Infosymbol.';

  @override
  String get couldNotOpenPgn => 'PGN konnte nicht geöffnet werden.';

  @override
  String temperatureValue(String value) {
    return 'Temperatur: $value';
  }

  @override
  String topPValue(String value) {
    return 'Top-P: $value';
  }

  @override
  String analysisRatingValue(String rating) {
    return 'Maia-Rating (Analyse): $rating';
  }

  @override
  String secondAnalysisRatingValue(String rating) {
    return 'Zweites Maia-Rating (Analyse): $rating';
  }

  @override
  String premovesList(String moves) {
    return 'Vorauszüge: $moves';
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
    return 'Tiefe $depth · bis zu $seconds s pro Stellung, zusätzlich bis zu $extraSeconds s zur Prüfung herausragender Züge.';
  }

  @override
  String chessnutBattery(String percent, String charging) {
    String _temp0 = intl.Intl.selectLogic(charging, {'yes': ' ⚡', 'other': ''});
    return '$percent%$_temp0';
  }

  @override
  String get chessnutBluetoothUnavailable =>
      'Bluetooth ist auf diesem Gerät nicht verfügbar.';

  @override
  String get chessnutPermissionPending =>
      'Erteile die Bluetooth-Berechtigungen und verbinde Chessnut dann erneut.';

  @override
  String get chessnutBluetoothDisabled =>
      'Aktiviere Bluetooth und verbinde Chessnut dann erneut.';

  @override
  String get whiteShort => 'W';

  @override
  String get blackShort => 'S';

  @override
  String get dateUnknown => 'Datum unbekannt';

  @override
  String get savedGameVersionUnsupported =>
      'Diese gespeicherten Daten verwenden ein nicht unterstütztes Format. Aktualisiere Mobile Maia, um sie zu öffnen. Die Daten wurden beibehalten.';

  @override
  String get gameStorageFailed =>
      'Auf den Speicher für gespeicherte Partien konnte nicht zugegriffen werden. Bitte versuche es erneut.';

  @override
  String recentWinResult(String result) {
    return 'Sieg ($result)';
  }

  @override
  String recentLossResult(String result) {
    return 'Niederlage ($result)';
  }

  @override
  String recentDrawResult(String result) {
    return 'Remis ($result)';
  }

  @override
  String get electronicBoardExperimental =>
      'Elektronisches Schachbrett (experimentell)';

  @override
  String get connectBoard => 'Brett verbinden';

  @override
  String get chooseBoard => 'Brett auswählen';

  @override
  String get chooseAnotherBoard => 'Anderes Brett auswählen';

  @override
  String get boardSearching => 'Bretter werden gesucht…';

  @override
  String get boardConnecting => 'Verbindung zum Brett wird hergestellt…';

  @override
  String get boardDisconnected => 'Brett getrennt';

  @override
  String get boardConnectionError =>
      'Verbindung fehlgeschlagen. Prüfe Bluetooth und das Brett und versuche es erneut.';

  @override
  String get boardStartingPosition =>
      'Baue die normale Anfangsposition auf deinem Brett auf.';

  @override
  String get boardReady => 'Brett bereit';

  @override
  String get boardExperimentalNotice =>
      'Die Unterstützung neuer Bretter ist experimentell. Prüfe die Züge auf beiden Bildschirmen und melde Verbindungsprobleme.';

  @override
  String get boardGameRestriction =>
      'Partien mit elektronischem Brett beginnen in der normalen Anfangsposition und ohne Zeitlimit.';

  @override
  String get boardConfirmSetup => 'Ich habe die Anfangsposition aufgebaut';

  @override
  String get boardConfirmSetupHelp =>
      'Prüfe vor dem Start jede Figur. Dieses Brett kann die Figurenart nicht erkennen.';

  @override
  String get boardChooseMove => 'Brettzug bestätigen';

  @override
  String get boardAmbiguousMove =>
      'Das Brett kann diese Züge nicht unterscheiden. Wähle den Zug, den du gespielt hast.';

  @override
  String get boardUnavailable =>
      'Das Brett ist nicht bereit. Verbinde es erneut oder spiele auf deinem Smartphone weiter.';

  @override
  String get boardNewGameConfirmInstruction =>
      'Drücke zur Bestätigung innerhalb von 2,5 Sekunden erneut NEW GAME oder nutze die Schaltflächen unten.';

  @override
  String get boardNewGameConfirmationExpired =>
      'Drücke zur Bestätigung am Brett zweimal innerhalb von 2,5 Sekunden NEW GAME.';

  @override
  String get boardPhysicalMove =>
      'Führe den Zug auf deinem Brett vollständig aus.';

  @override
  String get boardResetPhysical =>
      'Stelle vor dem Fortsetzen die auf dem Bildschirm angezeigte Stellung auf dem Brett wieder her.';

  @override
  String get boardNoResults =>
      'Kein unterstütztes Brett gefunden. Wecke dein Brett auf und versuche es erneut.';

  @override
  String get boardWaitingForSelection => 'Wähle ein Brett zum Verbinden.';

  @override
  String get boardReconnect => 'Brett erneut verbinden';

  @override
  String get boardLockedPegasus =>
      'Pegasus ist gesperrt. Diese Dev-Version enthält keinen Initialisierungsschlüssel des Herstellers.';

  @override
  String get boardMotorRecovery =>
      'Spiele auf deinem Smartphone weiter. Dieser experimentelle Adapter kann den Motorzustand des Bretts nicht sicher wiederherstellen.';

  @override
  String get boardConfirmPosition => 'Stellung auf dem Brett bestätigen';

  @override
  String get boardConfirmPositionHelp =>
      'Prüfe, ob jede Figur mit der Stellung auf dem Bildschirm übereinstimmt.';

  @override
  String get maiaHistorySetting => 'Stellungsverlauf verwenden';

  @override
  String get maiaHistoryHelp =>
      'Lass Maia neben der aktuellen Stellung bis zu sieben vorherige Stellungen berücksichtigen. In unseren Tests mit dem 79M-Modell verbesserte dies die Genauigkeit der Vorhersage menschlicher Züge um etwa 2 Prozentpunkte, förderte aber manchmal das wiederholte Nachahmen von Zügen in Eröffnungen bei niedrigen Ratings. Eine Steigerung der Spielstärke konnten wir nicht feststellen. Vorerst empfehlen wir, diese Option ausgeschaltet zu lassen.';

  @override
  String get maiaHistoryResearch =>
      'Studie zum Stellungsverlauf lesen (Englisch)';

  @override
  String get maiaHistoryOn => 'Stellungsverlauf: an';

  @override
  String get maiaHistoryOff => 'Stellungsverlauf: aus';

  @override
  String get chessboardDeviceName => 'Schachbrett';

  @override
  String namedBoardConnected(String boardName) {
    return '$boardName verbunden';
  }

  @override
  String namedBoardDisconnected(String boardName) {
    return '$boardName getrennt';
  }

  @override
  String get saveMaiaSamplingData => 'Maias Zugauswahldaten speichern';

  @override
  String get samplingDataHelp =>
      'Speichere Maias Zugwahrscheinlichkeiten, Einstellungen und gewählte Züge auf diesem Gerät, um zu untersuchen, wie Maia spielt.\n\nExportierte Dateien enthalten Brettstellungen, den Zugverlauf sowie Modelleingaben und Entscheidungen.\n\nDie letzten 10 aufgezeichneten Partien werden gespeichert und mit der neuesten zuerst angezeigt. Ältere Partien können früher entfernt werden, wenn das Speicherlimit erreicht ist. Diese Daten sind vom Bereich „Neueste Partien“ getrennt.\n\nNutze diese Funktion, wenn du die technischen Details von Maias Funktionsweise untersuchen möchtest. Die Daten können nicht in der App angesehen werden. Sie werden als leicht lesbare HTML-Datei mit einem Teil der Daten oder als JSONL-Datei mit allen aufgezeichneten Daten exportiert.\n\nDie Funktion ist standardmäßig ausgeschaltet. Wir empfehlen, sie ausgeschaltet zu lassen, sofern du nicht untersuchen möchtest, wie Maia funktioniert.';

  @override
  String get clearSamplingData => 'Zugauswahldaten löschen';

  @override
  String samplingDataStatus(int count) {
    return 'Gespeicherte Entscheidungen: $count';
  }

  @override
  String get samplingDataError =>
      'Kein Zugriff auf die Zugauswahldaten. Das Spielen ist nicht betroffen.';

  @override
  String get samplingSave => 'Speichern…';

  @override
  String get samplingShare => 'Teilen…';

  @override
  String get samplingSummary => 'Maias Zugwahl';

  @override
  String get samplingReadable => 'Lesbarer Bericht (HTML)';

  @override
  String get samplingReadableHint =>
      'Züge, Wahrscheinlichkeiten und Stellungsbilder. Öffnet sich im Browser.';

  @override
  String get samplingResearchHint =>
      'Rohe Modelleingaben und -ausgaben für technische Analysen.';

  @override
  String get samplingReportExplanation =>
      'Die Prozentwerte zeigen, mit welcher Wahrscheinlichkeit jeder Zug nach Anwendung deiner Einstellungen für Temperatur und Top-P ausgewählt wurde. Sie sind keine Gewinnchancen oder Bewertungen der Zugqualität.';

  @override
  String get samplingReportPartial =>
      'Nur aufgezeichnete Maia-Entscheidungen werden angezeigt, keine vollständige Partie. Durch Zugrücknahmen oder erneute Versuche können Zugnummern mehrfach vorkommen.';

  @override
  String get samplingReportMissing =>
      'Einige Daten wurden entfernt oder konnten nicht gespeichert werden. Der Bericht kann Lücken enthalten.';

  @override
  String get samplingPlayed => 'Gespielt';

  @override
  String get samplingNotPlayed => 'Nicht als gespielt erfasst';

  @override
  String get samplingAlternatives => 'Wahrscheinliche Alternativen';

  @override
  String samplingGame(String number) {
    return 'Partie $number';
  }

  @override
  String samplingRecords(String count) {
    return 'Aufgezeichnete Entscheidungen: $count';
  }

  @override
  String get samplingMostProbable => 'Am wahrscheinlichsten';

  @override
  String get samplingPlayedMostProbable =>
      'Der wahrscheinlichste Zug wurde gespielt';

  @override
  String samplingChance(String move, String odds) {
    return '$move hatte eine Auswahlwahrscheinlichkeit von ungefähr 1 zu $odds.';
  }

  @override
  String samplingCertain(String move) {
    return '$move wurde mit Sicherheit ausgewählt (100 %).';
  }

  @override
  String samplingAlmostCertain(String move) {
    return '$move wurde mit nahezu vollständiger Sicherheit ausgewählt.';
  }

  @override
  String get samplingReportRetention =>
      'Die letzten 10 aufgezeichneten Partien werden gespeichert und mit der neuesten zuerst angezeigt. Ältere Partien können früher entfernt werden, wenn das Speicherlimit erreicht ist.';

  @override
  String get samplingJumpToGame => 'Zur Partie springen';

  @override
  String get samplingBackToGames => 'Zurück zur Partienliste';

  @override
  String get samplingIncomplete => 'Nicht beendet';

  @override
  String get samplingUnknownResult => 'Ergebnis unbekannt';

  @override
  String get samplingOpeningUnknown => 'Eröffnung unbekannt';

  @override
  String get samplingTimeUnknown => 'Zeit unbekannt';

  @override
  String get samplingWin => 'Sieg';

  @override
  String get samplingLoss => 'Niederlage';

  @override
  String get samplingDraw => 'Remis';

  @override
  String get samplingDeleteData => 'Daten löschen';

  @override
  String get samplingClearConfirmation =>
      'Alle Zugauswahldaten von Maia löschen? Sie lassen sich nicht wiederherstellen.';

  @override
  String get analysisSettings => 'Analyse-Einstellungen';

  @override
  String get samplingData => 'Zugauswahldaten';

  @override
  String get resetSettingsDefaultsScope =>
      'Setzt alle Einstellungen auf dieser Seite zurück. Gespeicherte Partien und Sampling-Daten bleiben erhalten.';

  @override
  String get settingsResetError =>
      'Einige Einstellungen konnten nicht zurückgesetzt werden. Bitte versuche es erneut.';

  @override
  String get resetSettingsConfirmation => 'Alle Einstellungen zurücksetzen?';

  @override
  String get resetSettingsKeepData =>
      'Deine gespeicherten Partien und Sampling-Daten bleiben erhalten.';

  @override
  String get resetSettingsAction => 'Einstellungen zurücksetzen';

  @override
  String get samplingHelpIntro =>
      'Temperatur und Top-P steuern, wie Maia zwischen den möglichen Zügen auswählt.';

  @override
  String get samplingHelpVariety =>
      'Wenn du Temperatur und Top-P erhöhst, spielt Maia unberechenbarer, weil sie häufiger Züge mit geringer Wahrscheinlichkeit auswählt. Das können grobe Patzer sein, aber auch brillante Züge!';

  @override
  String get samplingHelpDefaults =>
      'Wenn du möglichst viel Abwechslung möchtest und Maia ein breites Spektrum menschlicher Eröffnungen einschließlich Nebenvarianten spielen soll, behalte die Standardwerte 1,0 und 1,0 bei.';

  @override
  String get samplingHelpStrength =>
      'Wenn du einen stärkeren Gegner bevorzugst, der weniger grobe Patzer macht, probiere niedrigere Werte für Temperatur und Top-P aus.';

  @override
  String get samplingHelpArgmax =>
      'Bei Temperatur 0 verwendet Maia argmax. Das ist der Fachbegriff dafür, dass Maia in einer Stellung immer den Zug spielt, den sie für einen Menschen als am wahrscheinlichsten vorhersagt. Achtung! In unserer Untersuchung mit der Rating-Einstellung 1600 erzielte argmax-Maia in direkten Partien gegen Maia mit 1,0 / 1,0 einen Vorsprung, der etwa 300 Elo-Punkten entspricht.';

  @override
  String get samplingHelpTopP =>
      'Für ein ausgewogenes Spiel kannst du die Temperatur bei 1,0 belassen und Top-P auf 0,95 setzen. So bleibt Abwechslung erhalten, während Züge mit geringer Wahrscheinlichkeit ausgeschlossen werden. Diese können oft grobe Patzer sein, aber auch gute Züge. Top-P schneidet im Grunde die unwahrscheinlichsten Züge ab. Bei 0,95 bleiben so viele Züge übrig, dass sie nach Anwendung der Temperatur zusammen mindestens 95 % der Wahrscheinlichkeit abdecken. Die übrigen Züge kann Maia nicht auswählen.';

  @override
  String get samplingHelpResearchIntro =>
      'Wir haben diese Einstellungen bei 1600 Elo getestet und unsere vollständigen Ergebnisse hier veröffentlicht:';
}

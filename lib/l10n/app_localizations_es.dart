// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get about => 'Acerca de';

  @override
  String get analysisBoard => 'Tablero de análisis';

  @override
  String get back => 'Volver';

  @override
  String get black => 'Negras';

  @override
  String get cancelPremoves => 'Cancelar movimientos anticipados';

  @override
  String get chessnutExperimental => 'Chessnut (experimental)';

  @override
  String get connectChessnut => 'Conectar Chessnut';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get engineSettings => 'Ajustes del motor';

  @override
  String get gameMenu => 'Menú de partida';

  @override
  String get gameReady => 'Partida lista';

  @override
  String get gameSettings => 'Ajustes de partida';

  @override
  String get home => 'Inicio';

  @override
  String get playMaia => 'Jugar contra Maia';

  @override
  String get random => 'Color aleatorio';

  @override
  String get recentGames => 'Partidas recientes';

  @override
  String get resign => 'Abandonar';

  @override
  String get settings => 'Preferencias';

  @override
  String get startGame => 'Iniciar partida';

  @override
  String get timeControl => 'Control de tiempo';

  @override
  String get white => 'Blancas';

  @override
  String get unlimited => 'Ilimitado';

  @override
  String get custom => 'Personalizado';

  @override
  String get seconds => 'segundos';

  @override
  String get yourSide => 'Tu color';

  @override
  String get you => 'Tú';

  @override
  String get systemDefault => 'Predeterminado del sistema';

  @override
  String get language => 'Idioma';

  @override
  String get playMaiaRating => 'Elo de Maia para jugar';

  @override
  String get minutes => 'Minutos';

  @override
  String get increment => 'Incremento';

  @override
  String get gameSounds => 'Sonidos de partida';

  @override
  String get movesCapturesErrorsAndGameEnd =>
      'Jugadas, capturas, errores y final de partida';

  @override
  String get hapticFeedback => 'Respuesta táctil';

  @override
  String get touchFeedbackForMovesChecksErrorsAndGameEnd =>
      'Vibración para jugadas, jaques, errores y final de partida';

  @override
  String get premoves => 'Movimientos anticipados';

  @override
  String get queueAMoveWhileMaiaIsThinking =>
      'Prepara una jugada mientras Maia piensa';

  @override
  String get oneHundredMsPremovePenalty =>
      'Descontar 0,1 s por movimiento anticipado';

  @override
  String get use01SecondsPerPremoveInTimedGames =>
      'En partidas con tiempo, cada movimiento anticipado consume 0,1 segundos de tu reloj.';

  @override
  String get allowMultiplePremoves => 'Permitir varios movimientos anticipados';

  @override
  String get queueASequenceAnIllegalMoveCancelsTheRest =>
      'Prepara varias jugadas; si una no es legal, se cancela junto con las siguientes';

  @override
  String get humanMoveTiming => 'Pausas naturales';

  @override
  String get variableNaturalPausesBeforeMaiaMoves =>
      'Maia hace pausas de distinta duración antes de jugar';

  @override
  String get aboutTemperatureAndTopP => 'Acerca de Temperatura y Top-P';

  @override
  String get temperature => 'Temperatura';

  @override
  String get topP => 'Top-P';

  @override
  String get maxOpeningVariety => 'Máxima variedad en la apertura';

  @override
  String get maxOpeningVarietyHelp =>
      'Activada por defecto. Usa temperatura y Top-P 1,0 / 1,0 durante las primeras cinco jugadas de cada bando y tus ajustes desde la sexta. Mantiene opciones amplias en la apertura y permite descartar jugadas poco probables después. Respeta el número de jugada de la posición, también al reanudar o continuar una partida.\n\nNo hace falta con 1,0 / 1,0: el interruptor queda apagado y no se puede activar porque esos ajustes ya ofrecen toda la variedad durante la partida.';

  @override
  String get maiaAnalysisRating => 'Elo de Maia para analizar';

  @override
  String get addSecondMaiaEngine => 'Añadir un segundo motor Maia';

  @override
  String get compareAnotherMaiaRatingInAnalysisAndReview =>
      'Compara dos niveles de Maia al analizar posiciones y revisar partidas';

  @override
  String get secondMaiaAnalysisRating => 'Elo del segundo Maia';

  @override
  String get gameAnalysisQuality => 'Calidad del análisis de partida';

  @override
  String get resetSettingsDefaults => 'Restablecer los ajustes predeterminados';

  @override
  String get boardSounds => 'Avisos del tablero electrónico';

  @override
  String get beepForCheckCheckmateAndCompletedIllegalMoves =>
      'Avisos sonoros de jaque y jaque mate, y de jugadas ilegales una vez completadas.';

  @override
  String get copyDiagnostics => 'Copiar información de diagnóstico';

  @override
  String get diagnosticsCopied => 'Información de diagnóstico copiada';

  @override
  String get newGame => 'Nueva Partida';

  @override
  String get resetGame => 'Reiniciar partida';

  @override
  String get shareAndExport => 'Compartir y exportar';

  @override
  String get savePgnFile => 'Guardar archivo PGN';

  @override
  String get sharePgn => 'Compartir PGN';

  @override
  String get copyPgn => 'Copiar PGN';

  @override
  String get copyFen => 'Copiar FEN';

  @override
  String get maiaErrorRetry => 'Error de Maia. Reintentar';

  @override
  String get maiaErrorPleaseRetry => 'Error de Maia. Vuelve a intentarlo.';

  @override
  String get retry => 'Reintentar';

  @override
  String get maiaIsThinking => 'Maia está pensando…';

  @override
  String get history => 'HISTORIAL';

  @override
  String get start => 'INICIO';

  @override
  String get chessnutStatus => 'Estado de Chessnut';

  @override
  String get leaveCurrentGame => '¿Salir de la partida actual?';

  @override
  String get yourGameWillBeKeptInRecentGames =>
      'La partida se guardará en Partidas recientes.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get continueAction => 'Continuar';

  @override
  String get startANewGame => '¿Iniciar una nueva partida?';

  @override
  String get resetGameQuestion => '¿Reiniciar la partida?';

  @override
  String get yourCompletedGameWillRemainInRecentGames =>
      'La partida terminada permanecerá en Partidas recientes.';

  @override
  String get thisGameWillBePermanentlyErased =>
      'Esta partida se borrará permanentemente.';

  @override
  String get startNewGame => 'Iniciar nueva partida';

  @override
  String get reset => 'Reiniciar';

  @override
  String get flipBoard => 'Girar el tablero';

  @override
  String get offerDraw => 'Ofrecer tablas';

  @override
  String get takeBackMove => 'Deshacer jugada';

  @override
  String get whiteIsVictorious => 'Las blancas ganan';

  @override
  String get blackIsVictorious => 'Las negras ganan';

  @override
  String get theGameIsADraw => 'La partida es tablas.';

  @override
  String get theGameHasEnded => 'La partida ha terminado';

  @override
  String get rematch => 'Revancha';

  @override
  String get fast => 'Rápido';

  @override
  String get balanced => 'Equilibrado';

  @override
  String get thorough => 'Exhaustivo';

  @override
  String get continueFromHere => 'Continuar desde aquí';

  @override
  String get load => 'Cargar';

  @override
  String get editBoard => 'Editar tablero';

  @override
  String get done => 'Listo';

  @override
  String get whitePieces => 'Piezas blancas';

  @override
  String get blackPieces => 'Piezas negras';

  @override
  String get whiteToMove => 'Juegan las blancas';

  @override
  String get blackToMove => 'Juegan las negras';

  @override
  String get castlingRights => 'Derechos de enroque';

  @override
  String get whiteKingside => 'Enroque corto de blancas';

  @override
  String get whiteQueenside => 'Enroque largo de blancas';

  @override
  String get blackKingside => 'Enroque corto de negras';

  @override
  String get blackQueenside => 'Enroque largo de negras';

  @override
  String get enPassantTarget => 'Casilla de captura al paso';

  @override
  String get startingPosition => 'Posición inicial';

  @override
  String get clearBoard => 'Limpiar el tablero';

  @override
  String get loadFen => 'Cargar FEN';

  @override
  String get loadPgn => 'Cargar PGN';

  @override
  String get openPgnFile => 'Abrir archivo PGN';

  @override
  String get clearMoves => 'Borrar jugadas';

  @override
  String get boardEditor => 'Editor de tablero';

  @override
  String get endPosition => 'la posición final';

  @override
  String get analysisMenu => 'Menú de análisis';

  @override
  String get turnEngineOff => 'Desactivar motor';

  @override
  String get turnEngineOn => 'Activar motor';

  @override
  String get moves => 'Jugadas';

  @override
  String get computerAnalysis => 'Análisis del ordenador';

  @override
  String get backToGame => 'Volver a la partida';

  @override
  String get expandVariations => 'Abrir variantes';

  @override
  String get collapseVariations => 'Cerrar variantes';

  @override
  String get promoteVariation => 'Promocionar variante';

  @override
  String get mainLine => 'la línea principal';

  @override
  String get makeMainLine => 'Convertir en línea principal';

  @override
  String get deleteFromHere => 'Borrar a partir de aquí';

  @override
  String get analyzing => 'Analizando…';

  @override
  String get noLegalMoves => 'Sin jugadas legales';

  @override
  String get unavailable => 'No disponible';

  @override
  String get analysisFailed => 'El análisis falló. Inténtalo de nuevo.';

  @override
  String get analysisStopped => 'Se detuvo el análisis.';

  @override
  String get classifyingMoves => 'Clasificando jugadas…';

  @override
  String get graphReadyClassifying => 'Gráfico listo · clasificando jugadas…';

  @override
  String get stopAnalysis => 'Detener análisis';

  @override
  String get runAnalysisAgain => 'Repetir análisis';

  @override
  String get runAnalysis => 'Ejecutar análisis';

  @override
  String get analysisExplanation =>
      'Ejecuta el análisis para generar el gráfico de evaluación y la precisión de blancas y negras.';

  @override
  String get pgnCopied => 'PGN copiado.';

  @override
  String get fenCopied => 'FEN copiado';

  @override
  String get rawProbabilitiesExplanation =>
      'Probabilidades originales del modelo normalizadas entre todas las jugadas legales. No se aplican los ajustes de Temperatura ni Top-P.';

  @override
  String get showRawProbabilities =>
      'Mostrar todas las probabilidades originales del modelo';

  @override
  String get pasteFen => 'Pega un FEN completo de seis campos';

  @override
  String get pastePgn => 'Pega una partida PGN';

  @override
  String get invalidPosition =>
      'Posición inválida. Revisa el tablero y el FEN.';

  @override
  String get pgnLoadFailed =>
      'No se pudo cargar el PGN. Revisa el archivo o el texto pegado.';

  @override
  String get goToNext => 'Ir al siguiente';

  @override
  String tapForNext(String label) {
    return '$label · toca para ir al siguiente';
  }

  @override
  String get notEnoughMoves => 'No hay suficientes jugadas';

  @override
  String get gameAccuracy => 'Precisión de la partida';

  @override
  String get accuracy => 'Precisión';

  @override
  String get analysisGraph => 'Gráfico del análisis';

  @override
  String maiaMoveProbabilities(int elo) {
    return 'Probabilidades de las jugadas de Maia $elo';
  }

  @override
  String otherProbability(String probability) {
    return 'Otras $probability';
  }

  @override
  String otherLegalProbability(String probability) {
    return 'otras jugadas legales $probability';
  }

  @override
  String maiaProbabilitySemantics(String title, String moves) {
    return '$title. $moves.';
  }

  @override
  String analysisProgress(int completed, int total) {
    return 'Analizando $completed de $total posiciones…';
  }

  @override
  String graphPosition(int position, int total, String score) {
    return 'Posición $position de $total, $score';
  }

  @override
  String positionNumber(int position) {
    return 'Posición $position';
  }

  @override
  String classificationCount(int count, String side, String classification) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jugadas',
      one: '$count jugada',
    );
    return '$side · $classification: $_temp0';
  }

  @override
  String get classificationBrilliant => 'Jugada brillante';

  @override
  String get classificationGood => 'Buena jugada';

  @override
  String get classificationInteresting => 'Jugada interesante';

  @override
  String get classificationDubious => 'Jugada dudosa';

  @override
  String get classificationMistake => 'Error';

  @override
  String get classificationBlunder => 'Error grave';

  @override
  String get gameReview => 'Revisión de la partida';

  @override
  String materialPawn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count peones',
      one: '$count peón',
    );
    return '$_temp0';
  }

  @override
  String materialKnight(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count caballos',
      one: '$count caballo',
    );
    return '$_temp0';
  }

  @override
  String materialBishop(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alfiles',
      one: '$count alfil',
    );
    return '$_temp0';
  }

  @override
  String materialRook(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count torres',
      one: '$count torre',
    );
    return '$_temp0';
  }

  @override
  String materialQueen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count damas',
      one: '$count dama',
    );
    return '$_temp0';
  }

  @override
  String materialAdvantage(String score) {
    return 'Ventaja material de $score';
  }

  @override
  String materialDescription(String side, String description) {
    return 'Diferencia material de $side: $description';
  }

  @override
  String get previousMove => 'Jugada anterior';

  @override
  String get nextMove => 'Jugada siguiente';

  @override
  String get beginning => 'la posición inicial';

  @override
  String get latestPosition => 'la última posición';

  @override
  String holdForDestination(String destination) {
    return 'Mantén pulsado para ir a $destination';
  }

  @override
  String get phaseOpening => 'Apertura';

  @override
  String get phaseMiddlegame => 'Medio juego';

  @override
  String get phaseEndgame => 'Final';

  @override
  String get pieceKing => 'Rey';

  @override
  String get pieceQueen => 'Dama';

  @override
  String get pieceRook => 'Torre';

  @override
  String get pieceBishop => 'Alfil';

  @override
  String get pieceKnight => 'Caballo';

  @override
  String get piecePawn => 'Peón';

  @override
  String recentPlayerMaia(String rating) {
    return 'Jugador — Maia $rating';
  }

  @override
  String recentMaiaPlayer(String rating) {
    return 'Maia $rating — Jugador';
  }

  @override
  String get recentIncomplete => 'Sin terminar';

  @override
  String get recentCompleted => 'Finalizada';

  @override
  String get recentDeleteFailed =>
      'No se pudieron borrar las partidas guardadas. Inténtalo de nuevo.';

  @override
  String get recentOpenFailed =>
      'No se pudo abrir la partida guardada. Inténtalo de nuevo.';

  @override
  String recentDeleteTitle(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Borrar $countString partidas?',
      one: '¿Borrar la partida guardada?',
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
          'Estas $countString partidas guardadas se borrarán definitivamente.',
      one: 'Esta partida guardada se borrará definitivamente.',
    );
    return '$_temp0';
  }

  @override
  String get deleteAction => 'Borrar';

  @override
  String get recentUpdating => 'Actualizando las partidas guardadas';

  @override
  String get recentCancelSelection => 'Cancelar selección';

  @override
  String get recentClearSelection => 'Deseleccionar todo';

  @override
  String get recentSelectAll => 'Seleccionar todas las partidas';

  @override
  String get recentDeleteSelected => 'Borrar las partidas seleccionadas';

  @override
  String get recentSelectGames => 'Seleccionar partidas';

  @override
  String get recentDeleteAll => 'Borrar todas las partidas';

  @override
  String get recentDeleteOne => 'Borrar la partida guardada';

  @override
  String recentSelectedCount(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString seleccionadas',
      one: '$countString seleccionada',
    );
    return '$_temp0';
  }

  @override
  String get recentLoadFailed =>
      'No se pudieron cargar las partidas guardadas. Inténtalo de nuevo.';

  @override
  String get recentEmpty =>
      'Aquí aparecerán las partidas finalizadas y las partidas sin terminar que guardes al volver a Inicio.';

  @override
  String recentGameSummary(String result, String date) {
    return '$result · $date';
  }

  @override
  String get diagnosticsScreenError =>
      'Se ha producido un error de pantalla en Mobile Maia.';

  @override
  String get diagnosticsScreenInstructions =>
      'Copia los datos de diagnóstico y envíalos junto con una descripción de lo que pulsaste justo antes de que apareciera esta pantalla.';

  @override
  String get pgnSaved => 'PGN guardado';

  @override
  String get pgnExportFailed =>
      'No se pudo exportar el PGN. Tu partida sigue guardada en el dispositivo.';

  @override
  String get languagePreferenceError =>
      'No se pudo guardar o recuperar el idioma. Tus partidas no se han modificado. Vuelve a seleccionar el idioma.';

  @override
  String playRatingValue(String rating) {
    return 'Elo de Maia para jugar: $rating';
  }

  @override
  String minutesValue(String minutes) {
    return 'Minutos: $minutes';
  }

  @override
  String incrementSecondsValue(String seconds) {
    return 'Incremento (s): $seconds';
  }

  @override
  String get chooseSettings => 'Elige los ajustes e inicia una partida.';

  @override
  String get gameRestored => 'Partida restaurada.';

  @override
  String get reconnectChessnut => 'Vuelve a conectar Chessnut para continuar.';

  @override
  String get chessnutConnectionError => 'Error de conexión con Chessnut.';

  @override
  String get searchingChessnut => 'Buscando Chessnut…';

  @override
  String get couldNotConnectChessnut => 'No se pudo conectar Chessnut.';

  @override
  String get chessnutAndroidOnly =>
      'La conexión con Chessnut está disponible en Android.';

  @override
  String get chessnutIsDisconnected => 'Chessnut está desconectado.';

  @override
  String get yourMove => 'Tu turno.';

  @override
  String get yourMoveChessnut => 'Haz tu jugada en Chessnut.';

  @override
  String get chessnutReady => 'Chessnut está listo.';

  @override
  String get chessnutStartingPosition =>
      'Coloca la posición inicial estándar en Chessnut.';

  @override
  String get takebackCompleteYourMove =>
      'Posición restaurada. Haz tu jugada en Chessnut.';

  @override
  String get takebackCompleteThinking =>
      'Posición restaurada. Maia está pensando…';

  @override
  String get restoreLitSquares =>
      'Para deshacer, vuelve a colocar las piezas en las casillas iluminadas de Chessnut.';

  @override
  String get completeMaiaLitMove =>
      'Completa en Chessnut la jugada de Maia indicada por las luces.';

  @override
  String get illegalChessnutPosition =>
      'La posición no corresponde a una jugada legal. Corrige la colocación de las piezas en las casillas iluminadas.';

  @override
  String get completeYourChessnutMove => 'Termina tu jugada en Chessnut.';

  @override
  String get connectChessnutFirst => 'Conecta Chessnut antes de empezar.';

  @override
  String get gameInProgress => 'Partida en curso.';

  @override
  String get timeoutInsufficientMaterial =>
      'Tablas por tiempo agotado: el otro bando no tiene material suficiente para dar mate.';

  @override
  String get whiteOutOfTime => 'Las blancas se quedaron sin tiempo';

  @override
  String get blackOutOfTime => 'Las negras se quedaron sin tiempo';

  @override
  String get makeMaiaLitMove =>
      'Realiza en Chessnut la jugada de Maia indicada por las luces.';

  @override
  String get checkmateMaiaWins => 'Jaque mate: Maia gana.';

  @override
  String get checkmateYouWin => '¡Jaque mate: ganas tú!';

  @override
  String get drawResult => 'Tablas';

  @override
  String get drawByAgreement => 'Tablas de mutuo acuerdo';

  @override
  String get youWin => 'Ganas tú.';

  @override
  String get maiaWins => 'Maia gana.';

  @override
  String get gameEnded => 'Partida finalizada.';

  @override
  String get consideringDraw => 'Maia está considerando la oferta de tablas…';

  @override
  String get maiaDeclinedDraw => 'Maia rechazó la oferta de tablas.';

  @override
  String get couldNotEvaluateDraw => 'No se pudo evaluar la oferta de tablas.';

  @override
  String get youResigned => 'Abandonaste: Maia gana.';

  @override
  String get moveTakenBack => 'Posición restaurada. Tu turno.';

  @override
  String get connectingChessnut => 'Conectando con Chessnut…';

  @override
  String get chessnutUnavailable => 'Chessnut no disponible';

  @override
  String get chessnutDisconnected => 'Chessnut desconectado';

  @override
  String get reconnect => 'Reconectar';

  @override
  String get playInApp => 'Jugar en la aplicación';

  @override
  String get continueGameOnScreen => 'Continuar esta partida en pantalla';

  @override
  String get checkCheckmateIllegalMoves =>
      'Jaque, jaque mate y jugadas ilegales';

  @override
  String get offerDrawQuestion => '¿Ofrecer tablas?';

  @override
  String get resignGameQuestion => '¿Abandonar la partida?';

  @override
  String get resignEndsImmediately => 'La partida terminará inmediatamente.';

  @override
  String get premoveLimit =>
      'Puedes preparar hasta 64 movimientos anticipados.';

  @override
  String get chessnutGameRestriction =>
      'Las partidas con Chessnut no tienen límite de tiempo.';

  @override
  String get samplingTitle => 'Temperatura y Top-P';

  @override
  String get samplingDefaultsQuestion => 'Elige cuánta variedad quieres';

  @override
  String get samplingResearch => 'Datos completos de investigación (JSONL)';

  @override
  String get samplingResearchLink => 'Guía visual e investigación (en inglés)';

  @override
  String get close => 'Cerrar';

  @override
  String get unknownVersion => 'Versión desconocida';

  @override
  String get maiaProjectSource => 'Proyecto y código fuente de Maia-3';

  @override
  String get enCroissantProjectSource =>
      'Proyecto y código fuente de En Croissant';

  @override
  String get licence => 'Licencia';

  @override
  String get mobileMaiaSource => 'Código fuente de Mobile Maia';

  @override
  String get aboutPoweredBy =>
      'Utiliza Maia-3, el motor de ajedrez de estilo humano desarrollado por el Laboratorio de Ciencias Sociales Computacionales de la Universidad de Toronto.';

  @override
  String get aboutOffline =>
      'Maia-3 funciona íntegramente en tu teléfono. No requiere cuenta ni conexión a Internet.';

  @override
  String get aboutBoardCredits =>
      'La interfaz del tablero, el tema marrón predeterminado y las piezas Cburnett proceden de Lichess Flutter Chessground. El motor Stockfish local utiliza Lichess multistockfish.';

  @override
  String get aboutReviewCredits =>
      'La clasificación de jugadas y los criterios de detección de sacrificios de la revisión de partidas se han adaptado de la interfaz de ajedrez de código abierto En Croissant.';

  @override
  String get aboutLicence =>
      'Mobile Maia es software libre distribuido bajo AGPL-3.0-only, sin garantía alguna. Puedes redistribuirlo y modificarlo según esa licencia. El código fuente completo está disponible en el repositorio del proyecto.';

  @override
  String get aboutIndependent =>
      'Esta aplicación independiente de la comunidad no es una aplicación oficial de Maia-3, la Universidad de Toronto, Lichess ni En Croissant.';

  @override
  String get samplingRecommendationWarning =>
      'Maia puede tener un repertorio de aperturas más limitado si desactivas la máxima variedad en la apertura.';

  @override
  String get couldNotOpenPgn => 'No se pudo abrir el PGN.';

  @override
  String temperatureValue(String value) {
    return 'Temperatura: $value';
  }

  @override
  String topPValue(String value) {
    return 'Top-P: $value';
  }

  @override
  String analysisRatingValue(String rating) {
    return 'Elo de Maia para analizar: $rating';
  }

  @override
  String secondAnalysisRatingValue(String rating) {
    return 'Elo del segundo Maia: $rating';
  }

  @override
  String premovesList(String moves) {
    return 'Movimientos anticipados: $moves';
  }

  @override
  String maiaOpponentRating(String rating) {
    return 'Maia3 $rating Elo';
  }

  @override
  String analysisQualityDetails(
    String depth,
    String seconds,
    String extraSeconds,
  ) {
    return 'Profundidad $depth · hasta $seconds segundos por posición y hasta $extraSeconds segundos adicionales para comprobar jugadas destacadas.';
  }

  @override
  String chessnutBattery(String percent, String charging) {
    String _temp0 = intl.Intl.selectLogic(charging, {'yes': ' ⚡', 'other': ''});
    return '$percent%$_temp0';
  }

  @override
  String get chessnutBluetoothUnavailable =>
      'Bluetooth no está disponible en este dispositivo.';

  @override
  String get chessnutPermissionPending =>
      'Permite el acceso a Bluetooth y vuelve a conectar Chessnut.';

  @override
  String get chessnutBluetoothDisabled =>
      'Activa Bluetooth y vuelve a conectar Chessnut.';

  @override
  String get whiteShort => 'B';

  @override
  String get blackShort => 'N';

  @override
  String get dateUnknown => 'Fecha desconocida';

  @override
  String get savedGameVersionUnsupported =>
      'Estos datos guardados usan un formato no compatible. Actualiza Mobile Maia para abrirlos. Estos datos se han conservado.';

  @override
  String get gameStorageFailed =>
      'No se pudo acceder al almacenamiento de partidas. Vuelve a intentarlo.';

  @override
  String recentWinResult(String result) {
    return 'Victoria ($result)';
  }

  @override
  String recentLossResult(String result) {
    return 'Derrota ($result)';
  }

  @override
  String recentDrawResult(String result) {
    return 'Tablas ($result)';
  }

  @override
  String get electronicBoardExperimental =>
      'Tablero electrónico (experimental)';

  @override
  String get connectBoard => 'Conectar tablero';

  @override
  String get chooseBoard => 'Elegir un tablero';

  @override
  String get chooseAnotherBoard => 'Elegir otro tablero';

  @override
  String get boardSearching => 'Buscando tableros…';

  @override
  String get boardConnecting => 'Conectando al tablero…';

  @override
  String get boardDisconnected => 'Tablero desconectado';

  @override
  String get boardConnectionError =>
      'No se pudo conectar. Comprueba el Bluetooth y el tablero e inténtalo de nuevo.';

  @override
  String get boardStartingPosition =>
      'Coloca la posición inicial estándar en tu tablero.';

  @override
  String get boardReady => 'Tablero listo';

  @override
  String get boardExperimentalNotice =>
      'La compatibilidad con nuevos tableros es experimental. Verifica las jugadas en ambas pantallas e informa de los problemas de conexión.';

  @override
  String get boardGameRestriction =>
      'Las partidas con tablero electrónico no tienen límite de tiempo.';

  @override
  String get boardConfirmSetup => 'He colocado la posición inicial';

  @override
  String get boardConfirmSetupHelp =>
      'Comprueba todas las piezas antes de empezar. Este tablero no puede identificar el tipo de pieza.';

  @override
  String get boardChooseMove => 'Confirma tu jugada en el tablero';

  @override
  String get boardAmbiguousMove =>
      'El tablero no puede distinguir estas jugadas. Elige la que has realizado.';

  @override
  String get boardUnavailable =>
      'El tablero no está listo. Vuelve a conectarlo o continúa en tu teléfono.';

  @override
  String get boardNewGameConfirmInstruction =>
      'Pulsa NEW GAME otra vez antes de 2,5 segundos para confirmar o usa los botones de abajo.';

  @override
  String get boardNewGameConfirmationExpired =>
      'Para confirmar en el tablero, pulsa NEW GAME dos veces en 2,5 segundos.';

  @override
  String get boardPhysicalMove => 'Completa la jugada en tu tablero.';

  @override
  String get boardResetPhysical =>
      'Restablece en el tablero la posición que aparece en pantalla antes de continuar.';

  @override
  String get boardNoResults =>
      'No se ha encontrado ningún tablero compatible. Activa tu tablero e inténtalo de nuevo.';

  @override
  String get boardWaitingForSelection => 'Elige un tablero para conectar.';

  @override
  String get boardReconnect => 'Reconectar tablero';

  @override
  String get boardLockedPegasus =>
      'Pegasus está bloqueado. Esta versión Dev no incluye la clave de inicialización del fabricante.';

  @override
  String get boardMotorRecovery =>
      'Continúa en tu teléfono. Este adaptador experimental no puede restablecer con seguridad el estado del motor del tablero.';

  @override
  String get boardConfirmPosition => 'Confirmar la posición del tablero físico';

  @override
  String get boardConfirmPositionHelp =>
      'Comprueba que todas las piezas coincidan con la posición en pantalla.';

  @override
  String get maiaHistorySetting => 'Usar el historial de jugadas';

  @override
  String get maiaHistoryHelp =>
      'Permite que Maia use hasta siete posiciones anteriores al elegir una jugada. En nuestras pruebas con el modelo 79M, esto mejoró la precisión al predecir jugadas humanas en unos 2 puntos porcentuales, pero a veces llevó a imitar repetidamente jugadas en aperturas de jugadores con menor Elo. Por ahora, recomendamos dejarlo desactivado.';

  @override
  String get maiaHistoryResearch =>
      'Leer la investigación sobre el historial de jugadas (en inglés)';

  @override
  String get maiaHistoryOn => 'Historial de jugadas: activado';

  @override
  String get maiaHistoryOff => 'Historial de jugadas: desactivado';

  @override
  String get chessboardDeviceName => 'Tablero';

  @override
  String namedBoardConnected(String boardName) {
    return '$boardName: conectado';
  }

  @override
  String namedBoardDisconnected(String boardName) {
    return '$boardName: desconectado';
  }

  @override
  String get saveMaiaSamplingData => 'Guardar datos de selección de Maia';

  @override
  String get samplingDataHelp =>
      'Guarda las probabilidades de las jugadas de Maia, los ajustes y las jugadas elegidas en este dispositivo para explorar cómo juega.\n\nLos archivos exportados contienen posiciones del tablero, el historial de jugadas y los datos de entrada y las decisiones del modelo.\n\nSe guardan las últimas 10 partidas con datos registrados y se presentan de la más reciente a la más antigua. Las partidas anteriores pueden eliminarse antes si se alcanza el límite de almacenamiento. Estos datos son independientes de las partidas recientes.\n\nUtiliza esta función si te interesa estudiar los detalles técnicos del funcionamiento de Maia. Los datos no se pueden consultar en la aplicación. Se exportan a un archivo HTML fácil de consultar que contiene parte de los datos, o a un archivo JSONL con todos los datos registrados.\n\nEstá desactivada por defecto y recomendamos mantenerla así, salvo que te interese investigar cómo funciona Maia.';

  @override
  String get clearSamplingData => 'Borrar datos de selección';

  @override
  String samplingDataStatus(int count) {
    return 'Decisiones guardadas: $count';
  }

  @override
  String get samplingDataError =>
      'No se ha podido acceder a los datos de selección. Puedes seguir jugando.';

  @override
  String get samplingSave => 'Guardar…';

  @override
  String get samplingShare => 'Compartir…';

  @override
  String get samplingSummary => 'Las decisiones de Maia';

  @override
  String get samplingReadable => 'Informe legible (HTML)';

  @override
  String get samplingReadableHint =>
      'Jugadas, probabilidades y diagramas. Se abre en el navegador.';

  @override
  String get samplingResearchHint =>
      'Entradas y salidas originales del modelo para análisis técnico.';

  @override
  String get samplingReportExplanation =>
      'Los porcentajes indican la probabilidad de que se eligiera cada jugada tras aplicar tus ajustes de Temperatura y Top-P. No son probabilidades de ganar ni valoraciones de la calidad de las jugadas.';

  @override
  String get samplingReportPartial =>
      'Solo se muestran las decisiones de Maia registradas, no una partida completa. Al deshacer jugadas o reintentar, un número de jugada puede aparecer más de una vez.';

  @override
  String get samplingReportMissing =>
      'Algunos datos se eliminaron o no se pudieron guardar. Puede haber lagunas en el informe.';

  @override
  String get samplingPlayed => 'Jugada realizada';

  @override
  String get samplingNotPlayed => 'No consta como realizada';

  @override
  String get samplingAlternatives => 'Alternativas probables';

  @override
  String samplingGame(String number) {
    return 'Partida $number';
  }

  @override
  String samplingRecords(String count) {
    return 'Decisiones registradas: $count';
  }

  @override
  String get samplingMostProbable => 'Más probable';

  @override
  String get samplingPlayedMostProbable => 'Se jugó la opción más probable';

  @override
  String samplingChance(String move, String odds) {
    return '$move tenía aproximadamente 1 posibilidad entre $odds de ser elegida.';
  }

  @override
  String samplingCertain(String move) {
    return '$move se elegiría con certeza (100 %).';
  }

  @override
  String samplingAlmostCertain(String move) {
    return 'Era casi seguro que se elegiría $move.';
  }

  @override
  String get samplingReportRetention =>
      'Se guardan las últimas 10 partidas registradas y se muestran de la más reciente a la más antigua. Las partidas antiguas pueden eliminarse antes si se alcanza el límite de almacenamiento.';

  @override
  String get samplingJumpToGame => 'Ir a la partida';

  @override
  String get samplingBackToGames => 'Volver a la lista de partidas';

  @override
  String get samplingIncomplete => 'Sin terminar';

  @override
  String get samplingUnknownResult => 'Resultado desconocido';

  @override
  String get samplingOpeningUnknown => 'Apertura desconocida';

  @override
  String get samplingTimeUnknown => 'Hora desconocida';

  @override
  String get samplingWin => 'Victoria';

  @override
  String get samplingLoss => 'Derrota';

  @override
  String get samplingDraw => 'Tablas';

  @override
  String get samplingDeleteData => 'Borrar datos';

  @override
  String get samplingClearConfirmation =>
      '¿Borrar todos los datos de selección de jugadas de Maia? No se podrán recuperar.';

  @override
  String get analysisSettings => 'Preferencias de análisis';

  @override
  String get samplingData => 'Datos de selección de jugadas';

  @override
  String get resetSettingsDefaultsScope =>
      'Restablece todos los ajustes de esta pantalla. Se conservan las partidas guardadas y los datos de selección de jugadas.';

  @override
  String get settingsResetError =>
      'No se han podido restablecer algunos ajustes. Inténtalo de nuevo.';

  @override
  String get resetSettingsConfirmation =>
      '¿Restablecer todos los ajustes predeterminados?';

  @override
  String get resetSettingsKeepData =>
      'Se conservarán tus partidas guardadas y los datos de selección de jugadas.';

  @override
  String get resetSettingsAction => 'Restablecer ajustes';

  @override
  String get samplingHelpIntro =>
      'La temperatura y Top-P se combinan para determinar la variedad en el juego de Maia.\n\nRecomendamos una temperatura de 1,0, Top-P de 0,95 y Máxima variedad en la apertura activada. Estos son los ajustes predeterminados. Según nuestra investigación, ofrecen un buen equilibrio entre un juego parecido al humano, variedad en la apertura y menos errores graves poco habituales.\n\nSigue leyendo para saber cómo funcionan estos ajustes.';

  @override
  String get samplingHelpVariety =>
      'Temperatura\n\nCon temperatura 0, Maia siempre juega la jugada que predice como la más probable para un jugador del Elo seleccionado. Esto se llama técnicamente argmax.\n\nCon temperatura 1, Maia considera todas las jugadas que predice que podría hacer un jugador del Elo seleccionado y elige entre ellas según sus probabilidades.\n\nCon una temperatura entre 0 y 1, Maia da más peso a las jugadas que considera más probables. Cuanto menor es la temperatura, más predecibles son sus elecciones.\n\nPor ejemplo, en nuestras pruebas con el modelo 79M y un Elo de entrada de 1600 para ambos jugadores, las probabilidades de apertura de Maia con blancas fueron aproximadamente:\n\n• 1. e4: 64%\n• 1. d4: 25%\n• 1. c4: 3%\n• Todas las demás jugadas juntas: 8%\n\nCon temperatura 0, Maia siempre jugó 1. e4.\n\nCon temperatura 0,5, jugó 1. e4 aproximadamente el 86% de las veces y 1. d4 aproximadamente el 13%. Las demás jugadas seguían siendo posibles, pero juntas sumaban menos del 1%.\n\nCon temperatura 1, Maia siguió las probabilidades originales indicadas arriba.';

  @override
  String get samplingHelpDefaults =>
      'Top-P\n\nTop-P filtra las jugadas disponibles después de que la temperatura ajuste sus probabilidades.\n\nCon Top-P 1, no se aplica ningún filtro. Todas las jugadas disponibles pueden jugarse según sus probabilidades ajustadas por la temperatura.\n\nCon Top-P 0,95, Maia conserva las jugadas más probables hasta que su probabilidad conjunta alcanza al menos el 95% y después elige entre ellas. Las jugadas excluidas representan como máximo el 5% de la probabilidad.\n\nCon Top-P 0, Maia siempre elige la jugada más probable. Tiene el mismo efecto que temperatura 0: basta con poner cualquiera de los dos ajustes a 0 para obtener argmax.\n\nEn nuestro ejemplo de apertura, temperatura 1 y Top-P 0,60 harían que Maia siempre jugara 1. e4. Esa jugada por sí sola representa alrededor del 64% de la probabilidad, así que no hacen falta otras para alcanzar el umbral del 60%.';

  @override
  String get samplingHelpStrength =>
      '¿Cómo afectan estos ajustes al juego de Maia?\n\nPuedes imaginar Top-P como un ángel en el hombro de Maia. Con 0, el ángel le dice a Maia que ignore las jugadas menos probables, que pueden incluir errores graves o jugadas poco sólidas. Con 1,0, el ángel se ha ido y Maia podría elegir incluso la jugada más disparatada e improbable.\n\nEn nuestras pruebas de enfrentamientos directos con el ajuste de 1600, argmax superó a temperatura 1,0 / Top-P 1,0 por el equivalente a unos 300 puntos Elo. Sin embargo, argmax también limitó las opciones de apertura a un repertorio reducido, compuesto principalmente por líneas principales.';

  @override
  String get samplingHelpArgmax =>
      'Por eso introdujimos Máxima variedad en la apertura: un interruptor que hace que Maia juegue con temperatura 1,0 y Top-P 1,0 durante las primeras cinco jugadas de cada bando. ¡Puede que veas alguna locura en la apertura! A partir de la sexta jugada, Maia vuelve a los ajustes que hayas configurado.';

  @override
  String get samplingHelpTopP =>
      'Recomendamos mantener activada Máxima variedad en la apertura, con la temperatura en 1,0 y Top-P en 0,95. Es como tener un jugador creativo con un ángel en el hombro que, al menos, lo disuade de jugar las jugadas más descabelladas: las menos probables, cuya probabilidad conjunta suma hasta un 5%. Es cierto que podrían ser brillantes, pero también pueden ser errores graves y absurdos. Así se busca un buen equilibrio entre variedad en la apertura, creatividad en el medio juego y un juego más fuerte al excluir algunos errores graves de probabilidad muy baja.\n\nPara quienes se atrevan, la temperatura 0 produjo el juego más fuerte en nuestras pruebas. ¡Buena suerte!';

  @override
  String get samplingHelpResearchIntro =>
      'Consulta la guía visual para conocer la investigación que respalda estas decisiones y acceder a los resultados completos.';

  @override
  String get samplingFullVarietyNotice =>
      'Maia puede cometer más errores graves poco habituales con temperatura y Top-P en 1,0 / 1,0.';

  @override
  String get samplingArgmaxNotice =>
      'Maia puede jugar más fuerte con temperatura o Top-P en 0. ¡Buena suerte!';

  @override
  String get topPNotUsed => 'Top-P: No se usa';

  @override
  String get topPNotUsedTitle => 'Por qué no se usa Top-P';

  @override
  String get topPNotUsedHelp =>
      'Con temperatura 0, Maia siempre elige una de las jugadas más probables, así que Top-P no tiene efecto. Su valor se conserva y vuelve a estar disponible al subir la temperatura. Si la máxima variedad en la apertura está activada, las primeras cinco jugadas de cada bando siguen usando 1,0 / 1,0.';

  @override
  String get samplingLowerNotice =>
      'Maia puede jugar más fuerte con una temperatura o un Top-P más bajos.';

  @override
  String get appearance => 'Apariencia';

  @override
  String get appearanceSystemColors => 'Usar colores del sistema';

  @override
  String get appearanceSystemColorsHelp =>
      'Usar la paleta de colores de Android';

  @override
  String get appearanceSystemColorsUnavailable =>
      'No disponible en este dispositivo. Requiere Android 12 o posterior.';

  @override
  String get appearancePureBlack => 'Fondo negro puro';

  @override
  String get appearancePureBlackHelp => 'Usar fondos negros en el modo oscuro';

  @override
  String get appearancePreferenceError =>
      'La apariencia ha cambiado, pero no se ha podido guardar. Inténtalo de nuevo.';

  @override
  String get appearanceTheme => 'Tema';

  @override
  String get appearanceLight => 'Claro';

  @override
  String get appearanceDark => 'Oscuro';

  @override
  String get appearanceSystemDefault => 'Tema del dispositivo';

  @override
  String get boardSettings => 'Tablero';

  @override
  String get boardCoordinates => 'Coordenadas del tablero';

  @override
  String get boardLegalMoves => 'Destinos de movimientos legales';

  @override
  String get boardLastMove => 'Resaltar el último movimiento';

  @override
  String get boardAnimation => 'Animación de las piezas';

  @override
  String get boardMagnify => 'Aumentar la pieza arrastrada';

  @override
  String get boardDragTarget => 'Marcador de destino de la pieza arrastrada';

  @override
  String get boardTargetCircle => 'Círculo';

  @override
  String get boardTargetSquare => 'Cuadrado';

  @override
  String get boardTargetNone => 'Ninguna';

  @override
  String get boardPreferenceError =>
      'No se han podido guardar los ajustes del tablero. Inténtalo de nuevo.';

  @override
  String get boardDesign => 'Tablero';

  @override
  String get boardPieceSet => 'Estilo de piezas';

  @override
  String get showMaiaScore => 'Mostrar victoria (puntuación) de Maia en %';

  @override
  String get maiaScore => 'Puntuación Maia';

  @override
  String get maiaScoreEqual => 'Igualada';

  @override
  String get maiaScoreHelp =>
      'Muestra en la parte superior de la pantalla la evaluación de Maia sobre las posibilidades de ganar (puntuar).\nEl punto blanco o negro indica a qué bando se refiere el porcentaje.';

  @override
  String get maiaScoreExpectedHelp =>
      'Por ejemplo, Blancas 60% significa que Maia estima que las blancas conseguirían unos 60 puntos en 100 partidas desde esta posición. Una victoria vale 1 punto; unas tablas, ½.';

  @override
  String get maiaScoreInputsHelp =>
      'La estimación supone que ambos jugadores tienen el Elo de análisis seleccionado para Maia. Si activas dos Maias, cada una calcula su estimación con su propio Elo.';

  @override
  String get maiaScorePreferenceError =>
      'No se han podido guardar los ajustes de puntuación Maia. Inténtalo de nuevo.';

  @override
  String get maiaScoreResearchLink =>
      '¿Qué tan fiable es la puntuación de Maia? (en inglés)';

  @override
  String get maiaScoreStockfishHelp =>
      'Puede ser útil compararla con la evaluación de Stockfish. Que Stockfish considere que un bando está mejor no significa que a una persona le resulte fácil encontrar las jugadas correctas para convertir esa ventaja en victoria.';

  @override
  String get editorMoveTool => 'Mover piezas';

  @override
  String get editorEraseTool => 'Borrar piezas';

  @override
  String get editorEmptySquare => 'Casilla vacía';

  @override
  String get editorPositionSettings => 'Ajustes de la posición';

  @override
  String get editorImageImportUnavailable =>
      'Importar posición desde una imagen (aún no disponible)';

  @override
  String get editorShareFen => 'Compartir FEN';

  @override
  String get editorFenMetadata => 'Metadatos FEN';

  @override
  String get editorHalfmoveClock => 'Contador de medias jugadas';

  @override
  String get editorFullmoveNumber => 'Número de jugada';

  @override
  String get editorWhitePawn => 'Peón blanco';

  @override
  String get editorWhiteKnight => 'Caballo blanco';

  @override
  String get editorWhiteBishop => 'Alfil blanco';

  @override
  String get editorWhiteRook => 'Torre blanca';

  @override
  String get editorWhiteQueen => 'Dama blanca';

  @override
  String get editorWhiteKing => 'Rey blanco';

  @override
  String get editorBlackPawn => 'Peón negro';

  @override
  String get editorBlackKnight => 'Caballo negro';

  @override
  String get editorBlackBishop => 'Alfil negro';

  @override
  String get editorBlackRook => 'Torre negra';

  @override
  String get editorBlackQueen => 'Dama negra';

  @override
  String get editorBlackKing => 'Rey negro';

  @override
  String get continuationUseBoard => 'Usar tablero electrónico';

  @override
  String get continuationConnectHelp => 'Conecta un tablero compatible.';

  @override
  String get continuationBoardUntimed =>
      'Las partidas con tablero electrónico no tienen límite de tiempo.';

  @override
  String get continuationSetUpBoard => 'Preparar el tablero';

  @override
  String get continuationSetupHelp =>
      'Coloca en tu tablero la posición que aparece en pantalla. La partida empieza cuando las piezas coinciden.';

  @override
  String get continuationBoardUnsupported =>
      'Por ahora, continuar desde una posición solo es compatible con los tableros Chessnut.';
}

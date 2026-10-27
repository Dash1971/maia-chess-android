// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get about => 'Sobre';

  @override
  String get analysisBoard => 'Análise';

  @override
  String get back => 'Voltar';

  @override
  String get black => 'Pretas';

  @override
  String get cancelPremoves => 'Cancelar pré-movimentos';

  @override
  String get chessnutExperimental => 'Chessnut (experimental)';

  @override
  String get connectChessnut => 'Conectar Chessnut';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get engineSettings => 'Configurações do motor';

  @override
  String get gameMenu => 'Menu da partida';

  @override
  String get gameReady => 'Partida pronta';

  @override
  String get gameSettings => 'Configurações da partida';

  @override
  String get home => 'Início';

  @override
  String get playMaia => 'Jogar contra o Maia';

  @override
  String get random => 'Cor aleatória';

  @override
  String get recentGames => 'Partidas recentes';

  @override
  String get resign => 'Desistir';

  @override
  String get settings => 'Configurações';

  @override
  String get startGame => 'Iniciar partida';

  @override
  String get timeControl => 'Ritmo';

  @override
  String get white => 'Brancas';

  @override
  String get unlimited => 'Ilimitado';

  @override
  String get custom => 'Personalizado';

  @override
  String get seconds => 'segundos';

  @override
  String get yourSide => 'Sua cor';

  @override
  String get you => 'Você';

  @override
  String get systemDefault => 'Padrão do sistema';

  @override
  String get language => 'Idioma';

  @override
  String get playMaiaRating => 'Rating do Maia nas partidas';

  @override
  String get minutes => 'Minutos';

  @override
  String get increment => 'Incremento';

  @override
  String get gameSounds => 'Sons da partida';

  @override
  String get movesCapturesErrorsAndGameEnd =>
      'Lances, capturas, erros e fim da partida';

  @override
  String get hapticFeedback => 'Feedback por toque';

  @override
  String get touchFeedbackForMovesChecksErrorsAndGameEnd =>
      'Vibração para lances, xeques, erros e fim da partida';

  @override
  String get premoves => 'Pré-movimentos';

  @override
  String get queueAMoveWhileMaiaIsThinking =>
      'Programar um lance enquanto o Maia pensa';

  @override
  String get oneHundredMsPremovePenalty =>
      'Desconto de 100 ms por pré-movimento';

  @override
  String get use01SecondsPerPremoveInTimedGames =>
      'Consumir 0,1 segundo por pré-movimento em partidas com relógio';

  @override
  String get allowMultiplePremoves => 'Permitir vários pré-movimentos';

  @override
  String get queueASequenceAnIllegalMoveCancelsTheRest =>
      'Programar uma sequência; um lance ilegal cancela os demais';

  @override
  String get humanMoveTiming => 'Pausas como as de um jogador humano';

  @override
  String get variableNaturalPausesBeforeMaiaMoves =>
      'Pausas naturais de duração variável antes dos lances do Maia';

  @override
  String get aboutTemperatureAndTopP => 'Sobre temperatura e Top-P';

  @override
  String get temperature => 'Temperatura';

  @override
  String get topP => 'Top-P';

  @override
  String get maxOpeningVariety => 'Máxima variedade na abertura';

  @override
  String get maxOpeningVarietyHelp =>
      'Ativada por padrão. Usa temperatura e Top-P 1,0 / 1,0 nos primeiros cinco lances de cada lado e suas configurações a partir do sexto. Preserva opções amplas na abertura e permite excluir lances pouco prováveis depois. Respeita o número do lance da posição, inclusive ao retomar ou continuar uma partida.\n\nDesnecessária em 1,0 / 1,0: a opção fica desligada e indisponível, pois esses valores já oferecem toda a variedade durante a partida.';

  @override
  String get maiaAnalysisRating => 'Rating do Maia na análise';

  @override
  String get addSecondMaiaEngine => 'Adicionar um segundo motor Maia';

  @override
  String get compareAnotherMaiaRatingInAnalysisAndReview =>
      'Comparar outro rating do Maia na análise e na revisão';

  @override
  String get secondMaiaAnalysisRating => 'Rating do segundo Maia na análise';

  @override
  String get gameAnalysisQuality => 'Qualidade da análise da partida';

  @override
  String get resetSettingsDefaults => 'Restaurar configurações padrão';

  @override
  String get boardSounds => 'Sons do tabuleiro';

  @override
  String get beepForCheckCheckmateAndCompletedIllegalMoves =>
      'Emitir um som para xeque, xeque-mate e após terminar de executar um lance ilegal no tabuleiro.';

  @override
  String get copyDiagnostics => 'Copiar diagnóstico';

  @override
  String get diagnosticsCopied => 'Diagnóstico copiado';

  @override
  String get newGame => 'Nova partida';

  @override
  String get resetGame => 'Reiniciar partida';

  @override
  String get shareAndExport => 'Compartilhar e exportar';

  @override
  String get savePgnFile => 'Salvar arquivo PGN';

  @override
  String get sharePgn => 'Compartilhar PGN';

  @override
  String get copyPgn => 'Copiar PGN';

  @override
  String get copyFen => 'Copiar FEN';

  @override
  String get maiaErrorRetry => 'Erro no Maia. Tentar novamente';

  @override
  String get maiaErrorPleaseRetry => 'Erro no Maia. Tente novamente.';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get maiaIsThinking => 'O Maia está pensando…';

  @override
  String get history => 'HISTÓRICO';

  @override
  String get start => 'INÍCIO';

  @override
  String get chessnutStatus => 'Status do Chessnut';

  @override
  String get leaveCurrentGame => 'Sair da partida atual?';

  @override
  String get yourGameWillBeKeptInRecentGames =>
      'Sua partida será mantida em Partidas recentes.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get continueAction => 'Continuar';

  @override
  String get startANewGame => 'Iniciar uma nova partida?';

  @override
  String get resetGameQuestion => 'Reiniciar partida?';

  @override
  String get yourCompletedGameWillRemainInRecentGames =>
      'Sua partida concluída continuará em Partidas recentes.';

  @override
  String get thisGameWillBePermanentlyErased =>
      'Esta partida será apagada permanentemente.';

  @override
  String get startNewGame => 'Iniciar nova partida';

  @override
  String get reset => 'Reiniciar';

  @override
  String get flipBoard => 'Girar o tabuleiro';

  @override
  String get offerDraw => 'Propor empate';

  @override
  String get takeBackMove => 'Voltar jogada';

  @override
  String get whiteIsVictorious => 'Brancas vencem';

  @override
  String get blackIsVictorious => 'Pretas vencem';

  @override
  String get theGameIsADraw => 'A partida terminou em empate.';

  @override
  String get theGameHasEnded => 'A partida terminou';

  @override
  String get rematch => 'Revanche';

  @override
  String get fast => 'Rápida';

  @override
  String get balanced => 'Equilibrada';

  @override
  String get thorough => 'Detalhada';

  @override
  String get continueFromHere => 'Continuar daqui';

  @override
  String get load => 'Carregar';

  @override
  String get editBoard => 'Editar tabuleiro';

  @override
  String get done => 'Concluir';

  @override
  String get whitePieces => 'Peças brancas';

  @override
  String get blackPieces => 'Peças pretas';

  @override
  String get whiteToMove => 'Brancas jogam';

  @override
  String get blackToMove => 'Pretas jogam';

  @override
  String get castlingRights => 'Direitos de roque';

  @override
  String get whiteKingside => 'Roque curto das brancas';

  @override
  String get whiteQueenside => 'Roque longo das brancas';

  @override
  String get blackKingside => 'Roque curto das pretas';

  @override
  String get blackQueenside => 'Roque longo das pretas';

  @override
  String get enPassantTarget => 'Casa-alvo de en passant';

  @override
  String get startingPosition => 'Posição inicial';

  @override
  String get clearBoard => 'Limpar tabuleiro';

  @override
  String get loadFen => 'Carregar FEN';

  @override
  String get loadPgn => 'Carregar PGN';

  @override
  String get openPgnFile => 'Abrir arquivo PGN';

  @override
  String get clearMoves => 'Limpar lances';

  @override
  String get boardEditor => 'Editor de tabuleiro';

  @override
  String get endPosition => 'posição final';

  @override
  String get analysisMenu => 'Menu de análise';

  @override
  String get turnEngineOff => 'Desativar motor';

  @override
  String get turnEngineOn => 'Ativar motor';

  @override
  String get moves => 'Lances';

  @override
  String get computerAnalysis => 'Análise do computador';

  @override
  String get backToGame => 'Retorne à partida';

  @override
  String get expandVariations => 'Expandir variações';

  @override
  String get collapseVariations => 'Recolher variações';

  @override
  String get promoteVariation => 'Promover variante';

  @override
  String get mainLine => 'linha principal';

  @override
  String get makeMainLine => 'Transformar em linha principal';

  @override
  String get deleteFromHere => 'Excluir a partir daqui';

  @override
  String get analyzing => 'Analisando…';

  @override
  String get noLegalMoves => 'Nenhum lance legal';

  @override
  String get unavailable => 'Indisponível';

  @override
  String get analysisFailed => 'A análise falhou. Tente novamente.';

  @override
  String get analysisStopped => 'Análise do computador interrompida.';

  @override
  String get classifyingMoves => 'Classificando lances…';

  @override
  String get graphReadyClassifying => 'Gráfico pronto · classificando lances…';

  @override
  String get stopAnalysis => 'Interromper análise';

  @override
  String get runAnalysisAgain => 'Executar novamente a análise do computador';

  @override
  String get runAnalysis => 'Executar análise do computador';

  @override
  String get analysisExplanation =>
      'Execute a análise do computador para gerar o gráfico de avaliação e a precisão das brancas e das pretas.';

  @override
  String get pgnCopied => 'PGN copiado.';

  @override
  String get fenCopied => 'FEN copiada';

  @override
  String get rawProbabilitiesExplanation =>
      'Probabilidades brutas do modelo, normalizadas entre todos os lances legais. Temperatura e Top-P não são aplicados.';

  @override
  String get showRawProbabilities =>
      'Mostrar todas as probabilidades brutas do modelo';

  @override
  String get pasteFen => 'Cole uma FEN completa com seis campos';

  @override
  String get pastePgn => 'Cole uma partida em PGN';

  @override
  String get invalidPosition =>
      'Posição inválida. Verifique o tabuleiro e a FEN.';

  @override
  String get pgnLoadFailed =>
      'Não foi possível carregar a partida em PGN. Verifique o arquivo ou o texto colado.';

  @override
  String get goToNext => 'Ir para o próximo';

  @override
  String tapForNext(String label) {
    return '$label · toque para ir ao próximo';
  }

  @override
  String get notEnoughMoves => 'Lances insuficientes';

  @override
  String get gameAccuracy => 'Precisão da partida';

  @override
  String get accuracy => 'Precisão';

  @override
  String get analysisGraph => 'Gráfico da análise do computador';

  @override
  String maiaMoveProbabilities(int elo) {
    return 'Probabilidades dos lances do Maia $elo';
  }

  @override
  String otherProbability(String probability) {
    return 'Outros $probability';
  }

  @override
  String otherLegalProbability(String probability) {
    return 'outros lances legais $probability';
  }

  @override
  String maiaProbabilitySemantics(String title, String moves) {
    return '$title. $moves.';
  }

  @override
  String analysisProgress(int completed, int total) {
    return 'Posições analisadas: $completed de $total…';
  }

  @override
  String graphPosition(int position, int total, String score) {
    return 'Posição $position de $total  ·  $score';
  }

  @override
  String positionNumber(int position) {
    return 'Posição $position';
  }

  @override
  String classificationCount(int count, String side, String classification) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$side · $classification: $count lances',
      one: '$side · $classification: $count lance',
      zero: '$side · $classification: $count lances',
    );
    return '$_temp0';
  }

  @override
  String get classificationBrilliant => 'Jogada excelente';

  @override
  String get classificationGood => 'Boa jogada';

  @override
  String get classificationInteresting => 'Jogada interessante';

  @override
  String get classificationDubious => 'Lance questionável';

  @override
  String get classificationMistake => 'Erro';

  @override
  String get classificationBlunder => 'Erro grave';

  @override
  String get gameReview => 'Revisão da partida';

  @override
  String materialPawn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count peões',
      one: '$count peão',
      zero: '$count peões',
    );
    return '$_temp0';
  }

  @override
  String materialKnight(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cavalos',
      one: '$count cavalo',
      zero: '$count cavalos',
    );
    return '$_temp0';
  }

  @override
  String materialBishop(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bispos',
      one: '$count bispo',
      zero: '$count bispos',
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
      zero: '$count torres',
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
      zero: '$count damas',
    );
    return '$_temp0';
  }

  @override
  String materialAdvantage(String score) {
    return 'vantagem material de $score';
  }

  @override
  String materialDescription(String side, String description) {
    return 'Diferença de material das $side: $description';
  }

  @override
  String get previousMove => 'Lance anterior';

  @override
  String get nextMove => 'Próximo lance';

  @override
  String get beginning => 'início';

  @override
  String get latestPosition => 'última posição';

  @override
  String holdForDestination(String destination) {
    return 'Mantenha pressionado: $destination';
  }

  @override
  String get phaseOpening => 'Abertura';

  @override
  String get phaseMiddlegame => 'Meio-jogo';

  @override
  String get phaseEndgame => 'Finais';

  @override
  String get pieceKing => 'Rei';

  @override
  String get pieceQueen => 'Dama';

  @override
  String get pieceRook => 'Torre';

  @override
  String get pieceBishop => 'Bispo';

  @override
  String get pieceKnight => 'Cavalo';

  @override
  String get piecePawn => 'Peão';

  @override
  String recentPlayerMaia(String rating) {
    return 'Jogador — Maia $rating';
  }

  @override
  String recentMaiaPlayer(String rating) {
    return 'Maia $rating — Jogador';
  }

  @override
  String get recentIncomplete => 'Incompleta';

  @override
  String get recentCompleted => 'Concluída';

  @override
  String get recentDeleteFailed =>
      'Não foi possível excluir as partidas salvas. Tente novamente.';

  @override
  String get recentOpenFailed =>
      'Não foi possível abrir a partida salva. Tente novamente.';

  @override
  String recentDeleteTitle(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Excluir $countString partidas?',
      one: 'Excluir partida salva?',
      zero: 'Excluir $countString partidas?',
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
          'Estas $countString partidas salvas serão excluídas permanentemente.',
      one: 'Esta partida salva será excluída permanentemente.',
      zero:
          'Estas $countString partidas salvas serão excluídas permanentemente.',
    );
    return '$_temp0';
  }

  @override
  String get deleteAction => 'Excluir';

  @override
  String get recentUpdating => 'Atualizando partidas salvas';

  @override
  String get recentCancelSelection => 'Cancelar seleção';

  @override
  String get recentClearSelection => 'Limpar seleção';

  @override
  String get recentSelectAll => 'Selecionar todas as partidas';

  @override
  String get recentDeleteSelected => 'Excluir partidas selecionadas';

  @override
  String get recentSelectGames => 'Selecionar partidas';

  @override
  String get recentDeleteAll => 'Excluir todas as partidas';

  @override
  String get recentDeleteOne => 'Excluir partida salva';

  @override
  String recentSelectedCount(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString selecionadas',
      one: '$countString selecionada',
      zero: '$countString selecionadas',
    );
    return '$_temp0';
  }

  @override
  String get recentLoadFailed =>
      'Não foi possível carregar as partidas salvas. Tente novamente.';

  @override
  String get recentEmpty =>
      'As partidas concluídas e as partidas incompletas salvas ao voltar ao Início aparecerão aqui.';

  @override
  String recentGameSummary(String result, String date) {
    return '$result · $date';
  }

  @override
  String get diagnosticsScreenError =>
      'O Mobile Maia encontrou um erro nesta tela.';

  @override
  String get diagnosticsScreenInstructions =>
      'Copie o diagnóstico e envie-o com uma descrição do que você tocou imediatamente antes de esta tela aparecer.';

  @override
  String get pgnSaved => 'PGN salvo';

  @override
  String get pgnExportFailed =>
      'Não foi possível exportar o PGN. Sua partida continua salva no dispositivo.';

  @override
  String get languagePreferenceError =>
      'Não foi possível salvar ou restaurar o idioma. Suas partidas não foram afetadas. Tente selecionar o idioma novamente.';

  @override
  String playRatingValue(String rating) {
    return 'Rating do Maia nas partidas: $rating';
  }

  @override
  String minutesValue(String minutes) {
    return 'Minutos: $minutes';
  }

  @override
  String incrementSecondsValue(String seconds) {
    return 'Incremento: $seconds s';
  }

  @override
  String get chooseSettings => 'Escolha as configurações e inicie uma partida.';

  @override
  String get gameRestored => 'Partida restaurada.';

  @override
  String get reconnectChessnut => 'Reconecte o Chessnut para continuar.';

  @override
  String get chessnutConnectionError => 'Erro de conexão com o Chessnut.';

  @override
  String get searchingChessnut => 'Procurando Chessnut…';

  @override
  String get couldNotConnectChessnut => 'Não foi possível conectar o Chessnut.';

  @override
  String get chessnutAndroidOnly =>
      'O suporte ao Chessnut está disponível no Android.';

  @override
  String get chessnutIsDisconnected => 'O Chessnut está desconectado.';

  @override
  String get yourMove => 'Sua vez.';

  @override
  String get yourMoveChessnut => 'Sua vez de jogar no Chessnut.';

  @override
  String get chessnutReady => 'O Chessnut está pronto.';

  @override
  String get chessnutStartingPosition =>
      'Monte a posição inicial padrão no Chessnut.';

  @override
  String get takebackCompleteYourMove =>
      'Lances desfeitos. Sua vez de jogar no Chessnut.';

  @override
  String get takebackCompleteThinking =>
      'Lances desfeitos. O Maia está pensando…';

  @override
  String get restoreLitSquares =>
      'Para desfazer: restaure a posição nas casas iluminadas do Chessnut.';

  @override
  String get completeMaiaLitMove =>
      'Conclua o lance do Maia indicado pelas luzes do Chessnut.';

  @override
  String get illegalChessnutPosition =>
      'Essa posição não corresponde a um lance legal. Corrija as casas iluminadas.';

  @override
  String get completeYourChessnutMove => 'Conclua seu lance no Chessnut.';

  @override
  String get connectChessnutFirst => 'Conecte o Chessnut antes de começar.';

  @override
  String get gameInProgress => 'Partida em andamento.';

  @override
  String get timeoutInsufficientMaterial =>
      'Empate — tempo esgotado, mas o adversário não tem material suficiente para dar mate.';

  @override
  String get whiteOutOfTime => 'Brancas ficaram sem tempo';

  @override
  String get blackOutOfTime => 'Pretas ficaram sem tempo';

  @override
  String get makeMaiaLitMove =>
      'Execute o lance do Maia indicado pelas luzes do Chessnut.';

  @override
  String get checkmateMaiaWins => 'Xeque-mate — o Maia venceu.';

  @override
  String get checkmateYouWin => 'Xeque-mate — você venceu!';

  @override
  String get drawResult => 'Empate';

  @override
  String get drawByAgreement => 'Empate por acordo mútuo';

  @override
  String get youWin => 'Você venceu.';

  @override
  String get maiaWins => 'O Maia venceu.';

  @override
  String get gameEnded => 'Partida encerrada.';

  @override
  String get consideringDraw => 'O Maia está avaliando a oferta de empate…';

  @override
  String get maiaDeclinedDraw => 'O Maia recusou o empate.';

  @override
  String get couldNotEvaluateDraw =>
      'Não foi possível avaliar a oferta de empate.';

  @override
  String get youResigned => 'Você desistiu — o Maia venceu.';

  @override
  String get moveTakenBack => 'Lances desfeitos. Sua vez.';

  @override
  String get connectingChessnut => 'Conectando ao Chessnut…';

  @override
  String get chessnutUnavailable => 'Chessnut indisponível';

  @override
  String get chessnutDisconnected => 'Chessnut desconectado';

  @override
  String get reconnect => 'Reconectar';

  @override
  String get playInApp => 'Jogar no aplicativo';

  @override
  String get continueGameOnScreen => 'Continuar esta partida na tela';

  @override
  String get checkCheckmateIllegalMoves => 'Xeque, xeque-mate e lances ilegais';

  @override
  String get offerDrawQuestion => 'Propor empate?';

  @override
  String get resignGameQuestion => 'Desistir da partida?';

  @override
  String get resignEndsImmediately => 'Isso encerrará a partida imediatamente.';

  @override
  String get premoveLimit => 'É possível programar até 64 pré-movimentos.';

  @override
  String get chessnutGameRestriction =>
      'As partidas com Chessnut não têm limite de tempo.';

  @override
  String get samplingTitle => 'Temperatura e Top-P';

  @override
  String get samplingDefaultsQuestion => 'Escolha quanta variedade você quer';

  @override
  String get samplingResearch => 'Dados completos de pesquisa (JSONL)';

  @override
  String get samplingResearchLink => 'Guia visual e pesquisa (em inglês)';

  @override
  String get close => 'Fechar';

  @override
  String get unknownVersion => 'Versão desconhecida';

  @override
  String get maiaProjectSource => 'Projeto Maia-3 e código-fonte';

  @override
  String get enCroissantProjectSource => 'Projeto En Croissant e código-fonte';

  @override
  String get licence => 'Licença';

  @override
  String get mobileMaiaSource => 'Código-fonte do Mobile Maia';

  @override
  String get aboutPoweredBy =>
      'Utiliza o Maia-3, o motor de xadrez que joga como humanos, desenvolvido pelo Laboratório de Ciências Sociais Computacionais da University of Toronto.';

  @override
  String get aboutOffline =>
      'O Maia-3 funciona inteiramente no seu celular. Não é necessário ter uma conta ou conexão à internet.';

  @override
  String get aboutBoardCredits =>
      'A interface do tabuleiro, o tema marrom padrão e as peças Cburnett são fornecidos pelo Lichess Flutter Chessground. O suporte ao Stockfish no dispositivo utiliza o Lichess multistockfish.';

  @override
  String get aboutReviewCredits =>
      'A classificação dos lances na Revisão da partida e as heurísticas de detecção de sacrifícios foram adaptadas da interface de xadrez de código aberto En Croissant.';

  @override
  String get aboutLicence =>
      'O Mobile Maia é um software livre distribuído sob a licença AGPL-3.0-only, sem qualquer garantia. Você pode redistribuí-lo e modificá-lo conforme os termos dessa licença. O código-fonte completo está disponível no repositório do projeto.';

  @override
  String get aboutIndependent =>
      'Este aplicativo independente da comunidade não é um aplicativo oficial do Maia-3, da University of Toronto, do Lichess ou do En Croissant.';

  @override
  String get samplingRecommendationWarning =>
      'O repertório de aberturas de Maia pode ficar mais limitado com a variedade máxima na abertura desativada.';

  @override
  String get couldNotOpenPgn => 'Não foi possível abrir o PGN.';

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
    return 'Rating do Maia na análise: $rating';
  }

  @override
  String secondAnalysisRatingValue(String rating) {
    return 'Rating do segundo Maia na análise: $rating';
  }

  @override
  String premovesList(String moves) {
    return 'Pré-movimentos: $moves';
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
    return 'Profundidade $depth · até $seconds s por posição, mais até $extraSeconds s para verificar lances que se destacam.';
  }

  @override
  String chessnutBattery(String percent, String charging) {
    String _temp0 = intl.Intl.selectLogic(charging, {'yes': ' ⚡', 'other': ''});
    return '$percent%$_temp0';
  }

  @override
  String get chessnutBluetoothUnavailable =>
      'O Bluetooth não está disponível neste dispositivo.';

  @override
  String get chessnutPermissionPending =>
      'Conceda as permissões de Bluetooth e reconecte o Chessnut.';

  @override
  String get chessnutBluetoothDisabled =>
      'Ative o Bluetooth e reconecte o Chessnut.';

  @override
  String get whiteShort => 'B';

  @override
  String get blackShort => 'P';

  @override
  String get dateUnknown => 'Data desconhecida';

  @override
  String get savedGameVersionUnsupported =>
      'Estes dados salvos usam um formato não compatível. Atualize o Mobile Maia para abri-los. Os dados foram preservados.';

  @override
  String get gameStorageFailed =>
      'Não foi possível acessar o armazenamento das partidas salvas. Tente novamente.';

  @override
  String recentWinResult(String result) {
    return 'Vitória ($result)';
  }

  @override
  String recentLossResult(String result) {
    return 'Derrota ($result)';
  }

  @override
  String recentDrawResult(String result) {
    return 'Empate ($result)';
  }

  @override
  String get electronicBoardExperimental =>
      'Tabuleiro eletrônico (experimental)';

  @override
  String get connectBoard => 'Conectar tabuleiro';

  @override
  String get chooseBoard => 'Escolher um tabuleiro';

  @override
  String get chooseAnotherBoard => 'Escolher outro tabuleiro';

  @override
  String get boardSearching => 'Procurando tabuleiros…';

  @override
  String get boardConnecting => 'Conectando ao tabuleiro…';

  @override
  String get boardDisconnected => 'Tabuleiro desconectado';

  @override
  String get boardConnectionError =>
      'Não foi possível conectar. Verifique o Bluetooth e o tabuleiro e tente novamente.';

  @override
  String get boardStartingPosition =>
      'Monte a posição inicial padrão no seu tabuleiro.';

  @override
  String get boardReady => 'Tabuleiro pronto';

  @override
  String get boardExperimentalNotice =>
      'O suporte a novos tabuleiros é experimental. Confira os lances nas duas telas e relate problemas de conexão.';

  @override
  String get boardGameRestriction =>
      'As partidas com tabuleiro eletrônico não têm limite de tempo.';

  @override
  String get boardConfirmSetup => 'Montei a posição inicial';

  @override
  String get boardConfirmSetupHelp =>
      'Confira cada peça antes de começar. Este tabuleiro não consegue identificar o tipo de peça.';

  @override
  String get boardChooseMove => 'Confirme seu lance no tabuleiro';

  @override
  String get boardAmbiguousMove =>
      'O tabuleiro não consegue distinguir esses lances. Escolha o lance que você fez.';

  @override
  String get boardUnavailable =>
      'O tabuleiro não está pronto. Reconecte ou continue no celular.';

  @override
  String get boardNewGameConfirmInstruction =>
      'Pressione NEW GAME novamente em até 2,5 segundos para confirmar ou use os botões abaixo.';

  @override
  String get boardNewGameConfirmationExpired =>
      'Para confirmar no tabuleiro, pressione NEW GAME duas vezes em até 2,5 segundos.';

  @override
  String get boardPhysicalMove => 'Complete o lance no seu tabuleiro.';

  @override
  String get boardResetPhysical =>
      'Antes de continuar, restaure no tabuleiro a posição exibida na tela.';

  @override
  String get boardNoResults =>
      'Nenhum tabuleiro compatível encontrado. Ative seu tabuleiro e tente novamente.';

  @override
  String get boardWaitingForSelection => 'Escolha um tabuleiro para conectar.';

  @override
  String get boardReconnect => 'Reconectar tabuleiro';

  @override
  String get boardLockedPegasus =>
      'O Pegasus está bloqueado. Esta versão Dev não inclui a chave de inicialização do fabricante.';

  @override
  String get boardMotorRecovery =>
      'Continue no celular. Este adaptador experimental não consegue restaurar com segurança o estado do motor do tabuleiro.';

  @override
  String get boardConfirmPosition => 'Confirmar a posição do tabuleiro físico';

  @override
  String get boardConfirmPositionHelp =>
      'Confira se todas as peças correspondem à posição na tela.';

  @override
  String get maiaHistorySetting => 'Usar histórico de posições';

  @override
  String get maiaHistoryHelp =>
      'Permita que o Maia use até sete posições anteriores ao escolher um lance. Nos nossos testes com o modelo 79M, isso melhorou a precisão das previsões de lances humanos em cerca de 2 pontos percentuais, mas às vezes levou à imitação repetida de lances em aberturas de jogadores com rating mais baixo. Por enquanto, recomendamos deixar esta opção desativada.';

  @override
  String get maiaHistoryResearch =>
      'Ler a pesquisa sobre o histórico de posições (em inglês)';

  @override
  String get maiaHistoryOn => 'Histórico de posições: ativado';

  @override
  String get maiaHistoryOff => 'Histórico de posições: desativado';

  @override
  String get chessboardDeviceName => 'Tabuleiro';

  @override
  String namedBoardConnected(String boardName) {
    return '$boardName: conectado';
  }

  @override
  String namedBoardDisconnected(String boardName) {
    return '$boardName: desconectado';
  }

  @override
  String get saveMaiaSamplingData => 'Salvar dados de seleção do Maia';

  @override
  String get samplingDataHelp =>
      'Salve as probabilidades dos lances do Maia, as configurações e os lances escolhidos neste dispositivo para explorar como ele joga.\n\nOs arquivos exportados contêm posições do tabuleiro, o histórico de lances e as entradas e decisões do modelo.\n\nAs últimas 10 partidas com dados registrados são salvas e apresentadas da mais recente para a mais antiga. Partidas anteriores podem ser removidas antes se o limite de armazenamento for atingido. Esses dados são separados das partidas recentes.\n\nUse este recurso se você tiver interesse em estudar os detalhes técnicos de como o Maia funciona. Os dados não podem ser visualizados no aplicativo. Eles são exportados para um arquivo HTML fácil de visualizar com parte dos dados, ou para um arquivo JSONL com todos os dados registrados.\n\nO recurso fica desativado por padrão, e recomendamos mantê-lo assim, a menos que você tenha interesse em pesquisar como o Maia funciona.';

  @override
  String get clearSamplingData => 'Apagar dados de seleção';

  @override
  String samplingDataStatus(int count) {
    return 'Decisões salvas: $count';
  }

  @override
  String get samplingDataError =>
      'Não foi possível acessar os dados de seleção. Isso não afeta o jogo.';

  @override
  String get samplingSave => 'Salvar…';

  @override
  String get samplingShare => 'Compartilhar…';

  @override
  String get samplingSummary => 'As escolhas do Maia';

  @override
  String get samplingReadable => 'Relatório legível (HTML)';

  @override
  String get samplingReadableHint =>
      'Lances, probabilidades e diagramas. Abre no navegador.';

  @override
  String get samplingResearchHint =>
      'Entradas e saídas brutas do modelo para análise técnica.';

  @override
  String get samplingReportExplanation =>
      'As porcentagens indicam a chance de cada lance ser escolhido após a aplicação das suas configurações de Temperatura e Top-P. Não são chances de vitória nem avaliações da qualidade dos lances.';

  @override
  String get samplingReportPartial =>
      'Apenas as decisões registradas do Maia são mostradas, não uma partida completa. Voltar lances ou tentar novamente pode repetir um número de lance.';

  @override
  String get samplingReportMissing =>
      'Alguns dados foram removidos ou não puderam ser salvos. O relatório pode conter lacunas.';

  @override
  String get samplingPlayed => 'Lance jogado';

  @override
  String get samplingNotPlayed => 'Não registrado como jogado';

  @override
  String get samplingAlternatives => 'Alternativas prováveis';

  @override
  String samplingGame(String number) {
    return 'Partida $number';
  }

  @override
  String samplingRecords(String count) {
    return 'Decisões registradas: $count';
  }

  @override
  String get samplingMostProbable => 'Mais provável';

  @override
  String get samplingPlayedMostProbable => 'O lance mais provável foi jogado';

  @override
  String samplingChance(String move, String odds) {
    return '$move tinha aproximadamente 1 chance em $odds de ser escolhido.';
  }

  @override
  String samplingCertain(String move) {
    return '$move seria escolhido com certeza (100%).';
  }

  @override
  String samplingAlmostCertain(String move) {
    return 'Era quase certo que $move seria escolhido.';
  }

  @override
  String get samplingReportRetention =>
      'As últimas 10 partidas registradas são salvas e mostradas da mais recente para a mais antiga. As partidas antigas podem ser removidas antes se o limite de armazenamento for atingido.';

  @override
  String get samplingJumpToGame => 'Ir para a partida';

  @override
  String get samplingBackToGames => 'Voltar à lista de partidas';

  @override
  String get samplingIncomplete => 'Não concluída';

  @override
  String get samplingUnknownResult => 'Resultado desconhecido';

  @override
  String get samplingOpeningUnknown => 'Abertura desconhecida';

  @override
  String get samplingTimeUnknown => 'Horário desconhecido';

  @override
  String get samplingWin => 'Vitória';

  @override
  String get samplingLoss => 'Derrota';

  @override
  String get samplingDraw => 'Empate';

  @override
  String get samplingDeleteData => 'Excluir dados';

  @override
  String get samplingClearConfirmation =>
      'Excluir todos os dados de seleção de jogadas do Maia? Não será possível recuperá-los.';

  @override
  String get analysisSettings => 'Configurações de análise';

  @override
  String get samplingData => 'Dados de seleção de jogadas';

  @override
  String get resetSettingsDefaultsScope =>
      'Restaura todas as configurações desta tela. As partidas salvas e os dados de seleção de jogadas são mantidos.';

  @override
  String get settingsResetError =>
      'Não foi possível restaurar algumas configurações. Tente novamente.';

  @override
  String get resetSettingsConfirmation =>
      'Restaurar todas as configurações padrão?';

  @override
  String get resetSettingsKeepData =>
      'Suas partidas salvas e os dados de seleção de jogadas serão mantidos.';

  @override
  String get resetSettingsAction => 'Restaurar configurações';

  @override
  String get samplingHelpIntro =>
      'A temperatura e o Top-P se combinam para definir a variedade no jogo do Maia.\n\nRecomendamos temperatura 1,0, Top-P 0,95 e Máxima variedade na abertura ativada. Essas são as configurações padrão. Segundo nossa pesquisa, elas oferecem um bom equilíbrio entre um jogo parecido com o humano, variedade na abertura e menos erros graves incomuns.\n\nContinue lendo para entender como essas configurações funcionam.';

  @override
  String get samplingHelpVariety =>
      'Temperatura\n\nCom temperatura 0, o Maia sempre joga o lance que prevê ser o mais provável para um jogador com o Elo selecionado. Isso é chamado tecnicamente de argmax.\n\nCom temperatura 1, o Maia considera todos os lances que prevê que um jogador com o Elo selecionado poderia jogar, escolhendo entre eles de acordo com suas probabilidades.\n\nCom uma temperatura entre 0 e 1, o Maia dá mais peso aos lances que considera mais prováveis. Quanto menor a temperatura, mais previsíveis ficam suas escolhas.\n\nPor exemplo, nos nossos testes com o modelo 79M e entradas de rating de 1600 para ambos os jogadores, as probabilidades do primeiro lance do Maia com as brancas foram aproximadamente:\n\n• 1. e4: 64%\n• 1. d4: 25%\n• 1. c4: 3%\n• Todos os outros lances juntos: 8%\n\nCom temperatura 0, o Maia sempre jogou 1. e4.\n\nCom temperatura 0,5, jogou 1. e4 em cerca de 86% das vezes e 1. d4 em cerca de 13%. Outros lances continuaram possíveis, mas juntos representaram menos de 1%.\n\nCom temperatura 1, o Maia seguiu as probabilidades originais listadas acima.';

  @override
  String get samplingHelpDefaults =>
      'Top-P\n\nO Top-P filtra os lances disponíveis depois que a temperatura ajusta suas probabilidades.\n\nCom Top-P 1, não há filtragem. Todos os lances disponíveis podem ser jogados de acordo com suas probabilidades ajustadas pela temperatura.\n\nCom Top-P 0,95, o Maia mantém os lances mais prováveis até que sua probabilidade somada atinja pelo menos 95%, e então escolhe entre eles. Os lances excluídos representam no máximo 5% da probabilidade.\n\nCom Top-P 0, o Maia sempre escolhe o lance mais provável. O efeito é o mesmo que o da temperatura 0: basta definir qualquer um dos dois como 0 para obter argmax.\n\nNo nosso exemplo de abertura, temperatura 1 e Top-P 0,60 fariam o Maia sempre jogar 1. e4. Esse lance sozinho representa cerca de 64% da probabilidade, então não são necessários outros lances para atingir o limite de 60%.';

  @override
  String get samplingHelpStrength =>
      'Como essas configurações afetam o jogo do Maia?\n\nVocê pode imaginar o Top-P como um anjo no ombro do Maia. Em 0, o anjo diz ao Maia para ignorar os lances menos prováveis, que podem incluir erros graves ou lances pouco sólidos. Em 1,0, o anjo foi embora, e o Maia pode escolher até o lance mais maluco e improvável.\n\nNos nossos testes de confronto direto com a configuração de 1600, argmax superou temperatura 1,0 / Top-P 1,0 pelo equivalente a cerca de 300 pontos Elo. No entanto, argmax também limitou as opções de abertura a um repertório restrito, composto principalmente por linhas principais.';

  @override
  String get samplingHelpArgmax =>
      'Por isso, introduzimos Máxima variedade na abertura: uma opção que faz o Maia jogar com temperatura 1,0 e Top-P 1,0 nos primeiros cinco lances de cada lado. Você pode ver algumas loucuras na abertura! A partir do sexto lance, o Maia volta às configurações que você definiu.';

  @override
  String get samplingHelpTopP =>
      'Recomendamos manter Máxima variedade na abertura ativada, com a temperatura em 1,0 e o Top-P em 0,95. É como ter um jogador criativo com um anjo no ombro, que pelo menos o convence a não jogar os lances totalmente descabidos: os menos prováveis, cuja probabilidade somada chega a até 5%. Eles podem ser brilhantes, é verdade, mas também podem ser erros graves e bobos. Assim, deve haver um bom equilíbrio entre variedade na abertura, criatividade no meio-jogo e um jogo mais forte ao excluir alguns erros graves de probabilidade muito baixa.\n\nPara quem tem coragem, a temperatura 0 produziu o jogo mais forte nos nossos testes. Boa sorte!';

  @override
  String get samplingHelpResearchIntro =>
      'O guia visual explica a pesquisa por trás dessas escolhas e traz links para os resultados completos.';

  @override
  String get samplingFullVarietyNotice =>
      'Maia pode cometer mais erros graves incomuns com temperatura e Top-P em 1,0 / 1,0.';

  @override
  String get samplingArgmaxNotice =>
      'Maia pode jogar mais forte com temperatura ou Top-P em 0. Boa sorte!';

  @override
  String get topPNotUsed => 'Top-P: Não utilizado';

  @override
  String get topPNotUsedTitle => 'Por que Top-P não é utilizado';

  @override
  String get topPNotUsedHelp =>
      'Com temperatura 0, Maia sempre escolhe um dos lances mais prováveis, então Top-P não tem efeito. Seu valor é mantido e volta a ficar disponível ao aumentar a temperatura. Se a variedade na abertura estiver ativada, os primeiros cinco lances de cada lado continuam usando 1,0 / 1,0.';

  @override
  String get samplingLowerNotice =>
      'Maia pode jogar mais forte com uma temperatura ou um Top-P mais baixos.';

  @override
  String get appearance => 'Aparência';

  @override
  String get appearanceSystemColors => 'Usar cores do sistema';

  @override
  String get appearanceSystemColorsHelp => 'Usar a paleta de cores do Android';

  @override
  String get appearanceSystemColorsUnavailable =>
      'Indisponível neste dispositivo. Requer Android 12 ou posterior.';

  @override
  String get appearancePureBlack => 'Fundo preto puro';

  @override
  String get appearancePureBlackHelp => 'Usar fundos pretos no modo escuro';

  @override
  String get appearancePreferenceError =>
      'A aparência foi alterada, mas não foi possível salvá-la. Tente novamente.';

  @override
  String get appearanceTheme => 'Tema';

  @override
  String get appearanceLight => 'Claro';

  @override
  String get appearanceDark => 'Escuro';

  @override
  String get appearanceSystemDefault => 'Tema do dispositivo';

  @override
  String get boardSettings => 'Tabuleiro';

  @override
  String get boardCoordinates => 'Coordenadas do tabuleiro';

  @override
  String get boardLegalMoves => 'Destinos de lances legais';

  @override
  String get boardLastMove => 'Destacar o último lance';

  @override
  String get boardAnimation => 'Animação das peças';

  @override
  String get boardMagnify => 'Ampliar peça segurada';

  @override
  String get boardDragTarget => 'Alvo da peça arrastada';

  @override
  String get boardTargetCircle => 'Círculo';

  @override
  String get boardTargetSquare => 'Casa';

  @override
  String get boardTargetNone => 'Nenhum';

  @override
  String get boardPreferenceError =>
      'Não foi possível salvar as configurações do tabuleiro. Tente novamente.';

  @override
  String get boardDesign => 'Tabuleiro';

  @override
  String get boardPieceSet => 'Estilo das peças';

  @override
  String get showMaiaScore => 'Mostrar vitória (pontuação) da Maia em %';

  @override
  String get maiaScore => 'Pontuação Maia';

  @override
  String get maiaScoreEqual => 'Equilibrado';

  @override
  String get maiaScoreHelp =>
      'Mostra no topo da tela a avaliação da Maia sobre as chances de vencer (pontuar).\nO ponto branco ou preto indica a qual lado a porcentagem se refere.';

  @override
  String get maiaScoreExpectedHelp =>
      'Por exemplo, Brancas 60% significa que a Maia estima que as brancas fariam cerca de 60 pontos em 100 partidas a partir desta posição. Uma vitória vale 1 ponto; um empate, ½.';

  @override
  String get maiaScoreInputsHelp =>
      'A estimativa usa a classificação de análise selecionada para a Maia nos dois jogadores. Com duas Maias ativadas, cada uma mostra sua própria estimativa na sua própria classificação.';

  @override
  String get maiaScorePreferenceError =>
      'Não foi possível salvar as configurações da pontuação Maia. Tente novamente.';

  @override
  String get maiaScoreResearchLink =>
      'Qual é a confiabilidade da pontuação da Maia? (em inglês)';

  @override
  String get maiaScoreStockfishHelp =>
      'Pode ser útil comparar com a avaliação do Stockfish. Só porque o Stockfish considera um lado melhor, isso não significa que seja fácil para uma pessoa encontrar os lances certos para transformar a vantagem em vitória!';

  @override
  String get editorMoveTool => 'Mover peças';

  @override
  String get editorEraseTool => 'Apagar peças';

  @override
  String get editorEmptySquare => 'Casa vazia';

  @override
  String get editorPositionSettings => 'Configurações da posição';

  @override
  String get editorImageImportUnavailable =>
      'Importar posição de imagem (ainda indisponível)';

  @override
  String get editorShareFen => 'Compartilhar FEN';

  @override
  String get editorFenMetadata => 'Metadados FEN';

  @override
  String get editorHalfmoveClock => 'Contador de meios-lances';

  @override
  String get editorFullmoveNumber => 'Número do lance';

  @override
  String get editorWhitePawn => 'Peão branco';

  @override
  String get editorWhiteKnight => 'Cavalo branco';

  @override
  String get editorWhiteBishop => 'Bispo branco';

  @override
  String get editorWhiteRook => 'Torre branca';

  @override
  String get editorWhiteQueen => 'Dama branca';

  @override
  String get editorWhiteKing => 'Rei branco';

  @override
  String get editorBlackPawn => 'Peão preto';

  @override
  String get editorBlackKnight => 'Cavalo preto';

  @override
  String get editorBlackBishop => 'Bispo preto';

  @override
  String get editorBlackRook => 'Torre preta';

  @override
  String get editorBlackQueen => 'Dama preta';

  @override
  String get editorBlackKing => 'Rei preto';

  @override
  String get continuationUseBoard => 'Usar tabuleiro eletrônico';

  @override
  String get continuationConnectHelp => 'Conecte um tabuleiro compatível.';

  @override
  String get continuationBoardUntimed =>
      'As partidas com tabuleiro eletrônico não têm limite de tempo.';

  @override
  String get continuationSetUpBoard => 'Preparar tabuleiro';

  @override
  String get continuationSetupHelp =>
      'Monte no seu tabuleiro a posição mostrada na tela. A partida começa quando a posição das peças coincidir.';

  @override
  String get continuationBoardUnsupported =>
      'No momento, continuar a partir de uma posição só é compatível com tabuleiros Chessnut.';
}

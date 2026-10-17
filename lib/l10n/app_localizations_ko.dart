// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get about => '앱 정보';

  @override
  String get analysisBoard => '분석';

  @override
  String get back => '뒤로';

  @override
  String get black => '흑';

  @override
  String get cancelPremoves => '미리두기 취소';

  @override
  String get chessnutExperimental => 'Chessnut(실험 기능)';

  @override
  String get connectChessnut => 'Chessnut 연결';

  @override
  String get disconnect => '연결 해제';

  @override
  String get engineSettings => '엔진 설정';

  @override
  String get gameMenu => '대국 메뉴';

  @override
  String get gameReady => '대국 준비 완료';

  @override
  String get gameSettings => '대국 설정';

  @override
  String get home => '홈';

  @override
  String get playMaia => 'Maia와 대국';

  @override
  String get random => '무작위';

  @override
  String get recentGames => '최근 대국';

  @override
  String get resign => '기권하기';

  @override
  String get settings => '설정';

  @override
  String get startGame => '대국 시작';

  @override
  String get timeControl => '시간 제한';

  @override
  String get white => '백';

  @override
  String get unlimited => '무제한';

  @override
  String get custom => '사용자 지정';

  @override
  String get seconds => '초';

  @override
  String get yourSide => '내 기물 색';

  @override
  String get you => '나';

  @override
  String get systemDefault => '시스템 기본값';

  @override
  String get language => '언어';

  @override
  String get playMaiaRating => '상대 Maia 레이팅';

  @override
  String get minutes => '분';

  @override
  String get increment => '추가 시간';

  @override
  String get gameSounds => '대국 소리';

  @override
  String get movesCapturesErrorsAndGameEnd => '기물 이동, 잡기, 오류 및 대국 종료 시 소리';

  @override
  String get hapticFeedback => '터치 피드백';

  @override
  String get touchFeedbackForMovesChecksErrorsAndGameEnd =>
      '수, 체크, 오류 및 대국 종료 시 진동';

  @override
  String get premoves => '미리두기';

  @override
  String get queueAMoveWhileMaiaIsThinking => 'Maia가 생각하는 동안 다음 수를 미리 입력';

  @override
  String get oneHundredMsPremovePenalty => '미리두기 1회당 100ms 차감';

  @override
  String get use01SecondsPerPremoveInTimedGames =>
      '시간 제한이 있는 대국에서 미리두기 1회당 0.1초 차감';

  @override
  String get allowMultiplePremoves => '여러 수 미리두기 허용';

  @override
  String get queueASequenceAnIllegalMoveCancelsTheRest =>
      '여러 수를 미리 입력합니다. 규칙에 맞지 않는 수가 나오면 그 수와 이후의 수가 취소됩니다';

  @override
  String get humanMoveTiming => '자연스러운 착수 간격';

  @override
  String get variableNaturalPausesBeforeMaiaMoves =>
      'Maia가 수를 두기 전 대기 시간을 자연스럽게 조절합니다';

  @override
  String get aboutTemperatureAndTopP => '온도와 Top-P 정보';

  @override
  String get temperature => '온도';

  @override
  String get topP => 'Top-P';

  @override
  String get maxOpeningVariety => '오프닝 다양성 최대화';

  @override
  String get maxOpeningVarietyHelp =>
      '온도와 Top-P가 기본값인 1.0 / 1.0이면 필요하지 않습니다. 양측이 각각 처음 다섯 수를 둘 때는 1.0 / 1.0을 사용하고, 여섯 번째 수부터는 설정한 값으로 돌아갑니다.\n\nMaia의 오프닝을 최대한 다양하게 하면서, 이후에는 온도나 Top-P를 낮춰 확률이 낮은 수를 선택할 가능성을 줄임으로써 더 강한 플레이를 할 수 있도록 하는 것이 목적입니다.';

  @override
  String get maiaAnalysisRating => 'Maia 분석 레이팅';

  @override
  String get addSecondMaiaEngine => '두 번째 Maia 엔진 추가';

  @override
  String get compareAnotherMaiaRatingInAnalysisAndReview =>
      '분석과 복기에서 다른 Maia 레이팅 비교';

  @override
  String get secondMaiaAnalysisRating => '두 번째 Maia 분석 레이팅';

  @override
  String get gameAnalysisQuality => '대국 분석 품질';

  @override
  String get resetSettingsDefaults => '설정을 기본값으로 초기화';

  @override
  String get boardSounds => '전자 보드 알림음';

  @override
  String get beepForCheckCheckmateAndCompletedIllegalMoves =>
      '체크, 체크메이트 또는 규칙에 어긋나는 수를 뒀을 때 알림음을 냅니다.';

  @override
  String get copyDiagnostics => '진단 정보 복사';

  @override
  String get diagnosticsCopied => '진단 정보가 복사되었습니다';

  @override
  String get newGame => '새 게임';

  @override
  String get resetGame => '대국 초기화';

  @override
  String get shareAndExport => '공유 및 내보내기';

  @override
  String get savePgnFile => 'PGN 파일 저장';

  @override
  String get sharePgn => 'PGN 공유';

  @override
  String get copyPgn => 'PGN 복사';

  @override
  String get copyFen => 'FEN 복사';

  @override
  String get maiaErrorRetry => 'Maia 오류: 다시 시도';

  @override
  String get maiaErrorPleaseRetry => 'Maia에 오류가 발생했습니다. 다시 시도해 주세요.';

  @override
  String get retry => '재시도';

  @override
  String get maiaIsThinking => 'Maia가 생각하는 중…';

  @override
  String get history => '기록';

  @override
  String get start => '시작';

  @override
  String get chessnutStatus => 'Chessnut 상태';

  @override
  String get leaveCurrentGame => '현재 대국을 나가시겠습니까?';

  @override
  String get yourGameWillBeKeptInRecentGames => '대국은 최근 대국에 보관됩니다.';

  @override
  String get cancel => '취소';

  @override
  String get continueAction => '계속';

  @override
  String get startANewGame => '새 대국을 시작하시겠습니까?';

  @override
  String get resetGameQuestion => '대국을 초기화하시겠습니까?';

  @override
  String get yourCompletedGameWillRemainInRecentGames => '완료된 대국은 최근 대국에 남습니다.';

  @override
  String get thisGameWillBePermanentlyErased => '이 대국은 영구적으로 삭제됩니다.';

  @override
  String get startNewGame => '새 대국 시작';

  @override
  String get reset => '초기화';

  @override
  String get flipBoard => '보드 돌리기';

  @override
  String get offerDraw => '무승부 요청';

  @override
  String get takeBackMove => '무르기';

  @override
  String get whiteIsVictorious => '백 승리';

  @override
  String get blackIsVictorious => '흑 승리';

  @override
  String get theGameIsADraw => '무승부 대국입니다.';

  @override
  String get theGameHasEnded => '대국 종료';

  @override
  String get rematch => '재대결';

  @override
  String get fast => '빠름';

  @override
  String get balanced => '균형';

  @override
  String get thorough => '정밀';

  @override
  String get continueFromHere => '여기서부터 시작';

  @override
  String get load => '불러오기';

  @override
  String get editBoard => '보드 편집';

  @override
  String get done => '완료';

  @override
  String get whitePieces => '백 기물';

  @override
  String get blackPieces => '흑 기물';

  @override
  String get whiteToMove => '백 차례';

  @override
  String get blackToMove => '흑 차례';

  @override
  String get castlingRights => '캐슬링 권리';

  @override
  String get whiteKingside => '백 킹사이드';

  @override
  String get whiteQueenside => '백 퀸사이드';

  @override
  String get blackKingside => '흑 킹사이드';

  @override
  String get blackQueenside => '흑 퀸사이드';

  @override
  String get enPassantTarget => '앙파상 대상 칸';

  @override
  String get startingPosition => '시작 포지션';

  @override
  String get clearBoard => '보드 지우기';

  @override
  String get loadFen => 'FEN 불러오기';

  @override
  String get loadPgn => 'PGN 불러오기';

  @override
  String get openPgnFile => 'PGN 파일 열기';

  @override
  String get clearMoves => '수 삭제';

  @override
  String get boardEditor => '보드 편집기';

  @override
  String get endPosition => '마지막 포지션';

  @override
  String get analysisMenu => '분석 메뉴';

  @override
  String get turnEngineOff => '엔진 끄기';

  @override
  String get turnEngineOn => '엔진 켜기';

  @override
  String get moves => '수';

  @override
  String get computerAnalysis => '컴퓨터 분석';

  @override
  String get backToGame => '대국으로 돌아가기';

  @override
  String get expandVariations => '라인 펼치기';

  @override
  String get collapseVariations => '라인 접기';

  @override
  String get promoteVariation => '라인 승격하기';

  @override
  String get makeMainLine => '주 라인으로 하기';

  @override
  String get deleteFromHere => '여기서부터 삭제';

  @override
  String get analyzing => '분석 중…';

  @override
  String get noLegalMoves => '합법적인 수 없음';

  @override
  String get unavailable => '사용 불가';

  @override
  String get analysisFailed => '분석에 실패했습니다. 다시 시도해 주세요.';

  @override
  String get analysisStopped => '컴퓨터 분석이 중지되었습니다.';

  @override
  String get classifyingMoves => '수를 분류하는 중…';

  @override
  String get graphReadyClassifying => '그래프 준비 완료 · 수 분류 중…';

  @override
  String get stopAnalysis => '분석 중지';

  @override
  String get runAnalysisAgain => '컴퓨터 분석 다시 실행';

  @override
  String get runAnalysis => '컴퓨터 분석 실행';

  @override
  String get analysisExplanation => '컴퓨터 분석을 실행하면 평가 그래프와 백·흑의 정확도가 표시됩니다.';

  @override
  String get pgnCopied => 'PGN 복사 완료.';

  @override
  String get fenCopied => 'FEN 복사됨';

  @override
  String get rawProbabilitiesExplanation =>
      '모든 합법적인 수에 대해 정규화한 모델의 원시 확률입니다. 온도와 Top-P 설정은 적용되지 않습니다.';

  @override
  String get showRawProbabilities => '전체 모델 원시 확률 표시';

  @override
  String get pasteFen => '6개 필드가 모두 포함된 FEN 붙여넣기';

  @override
  String get pastePgn => 'PGN 기보 붙여넣기';

  @override
  String get invalidPosition => '유효하지 않은 포지션입니다. 보드와 FEN을 확인해 주세요.';

  @override
  String get pgnLoadFailed => 'PGN 기보를 불러올 수 없습니다. 파일 또는 붙여넣은 텍스트를 확인해 주세요.';

  @override
  String get goToNext => '다음으로 이동';

  @override
  String tapForNext(String label) {
    return '$label · 탭하여 다음으로';
  }

  @override
  String get notEnoughMoves => '수가 부족합니다';

  @override
  String get gameAccuracy => '대국 정확도';

  @override
  String get accuracy => '정확도';

  @override
  String get analysisGraph => '컴퓨터 분석 그래프';

  @override
  String maiaMoveProbabilities(int elo) {
    return 'Maia $elo 수 확률';
  }

  @override
  String otherProbability(String probability) {
    return '기타 $probability';
  }

  @override
  String otherLegalProbability(String probability) {
    return '기타 합법적인 수 $probability';
  }

  @override
  String maiaProbabilitySemantics(String title, String moves) {
    return '$title. $moves.';
  }

  @override
  String analysisProgress(int completed, int total) {
    return '분석 중… $total개 포지션 중 $completed개 완료';
  }

  @override
  String graphPosition(int position, int total, String score) {
    return '포지션 $position/$total, $score';
  }

  @override
  String positionNumber(int position) {
    return '포지션 $position';
  }

  @override
  String classificationCount(int count, String side, String classification) {
    return '$side $classification: $count수';
  }

  @override
  String get classificationBrilliant => '매우 좋은 수';

  @override
  String get classificationGood => '좋은 수';

  @override
  String get classificationInteresting => '흥미로운 수';

  @override
  String get classificationDubious => '애매한 수';

  @override
  String get classificationMistake => '실수';

  @override
  String get classificationBlunder => '블런더';

  @override
  String get gameReview => '대국 복기';

  @override
  String materialPawn(int count) {
    return '폰 $count개';
  }

  @override
  String materialKnight(int count) {
    return '나이트 $count개';
  }

  @override
  String materialBishop(int count) {
    return '비숍 $count개';
  }

  @override
  String materialRook(int count) {
    return '룩 $count개';
  }

  @override
  String materialQueen(int count) {
    return '퀸 $count개';
  }

  @override
  String materialAdvantage(String score) {
    return '기물 우위 $score';
  }

  @override
  String materialDescription(String side, String description) {
    return '$side 기물 차이: $description';
  }

  @override
  String get previousMove => '이전 수';

  @override
  String get nextMove => '다음 수';

  @override
  String get beginning => '시작';

  @override
  String get latestPosition => '최신 포지션';

  @override
  String holdForDestination(String destination) {
    return '길게 누르면 $destination 위치로 이동합니다';
  }

  @override
  String get phaseOpening => '오프닝';

  @override
  String get phaseMiddlegame => '미들게임';

  @override
  String get phaseEndgame => '엔드게임';

  @override
  String get pieceKing => '킹';

  @override
  String get pieceQueen => '퀸';

  @override
  String get pieceRook => '룩';

  @override
  String get pieceBishop => '비숍';

  @override
  String get pieceKnight => '나이트';

  @override
  String get piecePawn => '폰';

  @override
  String recentPlayerMaia(String rating) {
    return '플레이어 — Maia $rating';
  }

  @override
  String recentMaiaPlayer(String rating) {
    return 'Maia $rating — 플레이어';
  }

  @override
  String get recentIncomplete => '미완료';

  @override
  String get recentCompleted => '완료';

  @override
  String get recentDeleteFailed => '저장된 대국을 삭제하지 못했습니다. 다시 시도해 주세요.';

  @override
  String get recentOpenFailed => '저장된 대국을 열지 못했습니다. 다시 시도해 주세요.';

  @override
  String recentDeleteTitle(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '저장된 대국 $countString개를 삭제할까요?';
  }

  @override
  String recentDeleteWarning(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '저장된 대국 $countString개가 영구적으로 삭제됩니다.';
  }

  @override
  String get deleteAction => '삭제';

  @override
  String get recentUpdating => '저장된 대국 업데이트 중';

  @override
  String get recentCancelSelection => '선택 취소';

  @override
  String get recentClearSelection => '선택 해제';

  @override
  String get recentSelectAll => '모든 대국 선택';

  @override
  String get recentDeleteSelected => '선택한 대국 삭제';

  @override
  String get recentSelectGames => '대국 선택';

  @override
  String get recentDeleteAll => '모든 대국 삭제';

  @override
  String get recentDeleteOne => '저장된 대국 삭제';

  @override
  String recentSelectedCount(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString개 선택됨';
  }

  @override
  String get recentLoadFailed => '저장된 대국을 불러오지 못했습니다. 다시 시도해 주세요.';

  @override
  String get recentEmpty => '완료된 대국과 홈으로 돌아갈 때 저장한 미완료 대국이 여기에 표시됩니다.';

  @override
  String recentGameSummary(String result, String date) {
    return '$result · $date';
  }

  @override
  String get diagnosticsScreenError => 'Mobile Maia 화면에 오류가 발생했습니다.';

  @override
  String get diagnosticsScreenInstructions =>
      '진단 정보를 복사하고 이 화면이 나타나기 직전에 무엇을 눌렀는지 설명과 함께 보내 주세요.';

  @override
  String get pgnSaved => 'PGN 저장됨';

  @override
  String get pgnExportFailed => 'PGN을 내보내지 못했습니다. 대국은 기기에 계속 저장되어 있습니다.';

  @override
  String get languagePreferenceError =>
      '언어 설정을 저장하거나 복원하지 못했습니다. 대국 데이터에는 영향이 없습니다. 언어를 다시 선택해 주세요.';

  @override
  String playRatingValue(String rating) {
    return '상대 Maia 레이팅: $rating';
  }

  @override
  String minutesValue(String minutes) {
    return '분: $minutes';
  }

  @override
  String incrementSecondsValue(String seconds) {
    return '추가 시간: $seconds초';
  }

  @override
  String get chooseSettings => '설정을 선택하고 대국을 시작하세요.';

  @override
  String get gameRestored => '대국을 복원했습니다.';

  @override
  String get reconnectChessnut => '계속하려면 Chessnut에 다시 연결하세요.';

  @override
  String get chessnutConnectionError => 'Chessnut 연결 오류입니다.';

  @override
  String get searchingChessnut => 'Chessnut 검색 중…';

  @override
  String get couldNotConnectChessnut => 'Chessnut에 연결할 수 없습니다.';

  @override
  String get chessnutAndroidOnly => 'Chessnut은 Android에서 사용할 수 있습니다.';

  @override
  String get chessnutIsDisconnected => 'Chessnut이 연결되지 않았습니다.';

  @override
  String get yourMove => '당신 차례입니다.';

  @override
  String get yourMoveChessnut => 'Chessnut에서 수를 두세요.';

  @override
  String get chessnutReady => 'Chessnut이 준비되었습니다.';

  @override
  String get chessnutStartingPosition => 'Chessnut에 표준 시작 포지션대로 기물을 배치하세요.';

  @override
  String get takebackCompleteYourMove => '무르기가 완료되었습니다. Chessnut에서 수를 두세요.';

  @override
  String get takebackCompleteThinking => '무르기가 완료되었습니다. Maia가 생각 중…';

  @override
  String get restoreLitSquares => '무르기: Chessnut에서 불이 켜진 칸의 기물을 원래 위치로 되돌리세요.';

  @override
  String get completeMaiaLitMove => 'Chessnut에서 불빛으로 표시된 Maia의 수를 완료하세요.';

  @override
  String get illegalChessnutPosition =>
      '규칙에 맞는 수가 아닙니다. 불이 켜진 칸의 기물 배치를 바로잡으세요.';

  @override
  String get completeYourChessnutMove => 'Chessnut에서 두던 수를 마저 두세요.';

  @override
  String get connectChessnutFirst => '시작하기 전에 Chessnut을 연결하세요.';

  @override
  String get gameInProgress => '대국 진행 중입니다.';

  @override
  String get timeoutInsufficientMaterial =>
      '무승부 — 시간이 초과되었지만 시간이 남은 쪽에 체크메이트할 기물이 부족합니다.';

  @override
  String get whiteOutOfTime => '백 시간 초과';

  @override
  String get blackOutOfTime => '흑 시간 초과';

  @override
  String get makeMaiaLitMove => 'Chessnut에서 불빛으로 표시된 Maia의 수를 두세요.';

  @override
  String get checkmateMaiaWins => '체크메이트 — Maia가 이겼습니다.';

  @override
  String get checkmateYouWin => '체크메이트 — 당신이 이겼습니다!';

  @override
  String get drawResult => '무승부';

  @override
  String get drawByAgreement => '상호 동의에 의한 무승부';

  @override
  String get youWin => '당신이 이겼습니다.';

  @override
  String get maiaWins => 'Maia가 이겼습니다.';

  @override
  String get gameEnded => '대국이 끝났습니다.';

  @override
  String get consideringDraw => 'Maia가 무승부 제안을 검토 중…';

  @override
  String get maiaDeclinedDraw => 'Maia가 무승부 제안을 거절했습니다.';

  @override
  String get couldNotEvaluateDraw => '무승부 제안을 평가할 수 없습니다.';

  @override
  String get youResigned => '기권했습니다 — Maia가 이겼습니다.';

  @override
  String get moveTakenBack => '수를 물렀습니다. 당신 차례입니다.';

  @override
  String get connectingChessnut => 'Chessnut 연결 중…';

  @override
  String get chessnutUnavailable => 'Chessnut을 사용할 수 없음';

  @override
  String get chessnutDisconnected => 'Chessnut 연결 끊김';

  @override
  String get reconnect => '다시 연결';

  @override
  String get playInApp => '앱에서 대국';

  @override
  String get continueGameOnScreen => '화면에서 이 대국 계속하기';

  @override
  String get checkCheckmateIllegalMoves => '체크, 체크메이트, 규칙에 맞지 않는 수';

  @override
  String get offerDrawQuestion => '무승부를 제안할까요?';

  @override
  String get resignGameQuestion => '기권할까요?';

  @override
  String get resignEndsImmediately => '대국이 즉시 종료됩니다.';

  @override
  String get premoveLimit => '최대 64수까지 미리 입력할 수 있습니다.';

  @override
  String get chessnutGameRestriction =>
      'Chessnut 대국은 표준 시작 포지션에서 시작하는 시간 무제한 대국만 지원합니다.';

  @override
  String get samplingTitle => '온도와 Top-P';

  @override
  String get samplingDefaultsQuestion => '원하는 수의 다양성을 선택하세요';

  @override
  String get samplingResearch => '전체 연구 데이터 (JSONL)';

  @override
  String get samplingResearchLink => '전체 연구 데이터 (영어)';

  @override
  String get close => '닫기';

  @override
  String get unknownVersion => '버전 알 수 없음';

  @override
  String get maiaProjectSource => 'Maia-3 프로젝트 및 소스 코드';

  @override
  String get enCroissantProjectSource => 'En Croissant 프로젝트 및 소스 코드';

  @override
  String get licence => '라이선스';

  @override
  String get mobileMaiaSource => 'Mobile Maia 소스 코드';

  @override
  String get aboutPoweredBy =>
      '토론토 대학교 계산사회과학 연구실이 개발한 사람처럼 두는 체스 엔진 Maia-3를 사용합니다.';

  @override
  String get aboutOffline =>
      'Maia-3는 휴대폰에서 완전히 실행됩니다. 계정이나 네트워크 연결이 필요하지 않습니다.';

  @override
  String get aboutBoardCredits =>
      '보드 인터페이스, 기본 갈색 테마와 Cburnett 기물은 Lichess Flutter Chessground에서 제공합니다. 로컬 Stockfish 지원에는 Lichess multistockfish를 사용합니다.';

  @override
  String get aboutReviewCredits =>
      '대국 복기의 수 분류와 희생 감지 휴리스틱은 오픈 소스 체스 GUI En Croissant를 기반으로 합니다.';

  @override
  String get aboutLicence =>
      'Mobile Maia는 AGPL-3.0-only로 배포되는 자유 소프트웨어이며 어떠한 보증도 없습니다. 해당 라이선스에 따라 재배포하고 수정할 수 있습니다. 전체 소스 코드는 프로젝트 저장소에서 확인할 수 있습니다.';

  @override
  String get aboutIndependent =>
      '이 앱은 독립적인 커뮤니티 앱이며 Maia-3, 토론토 대학교, Lichess 또는 En Croissant의 공식 앱이 아닙니다.';

  @override
  String get samplingRecommendationWarning =>
      '온도나 Top-P를 낮추면 미들게임에서 Maia가 더 강해질 수 있지만, 오프닝의 다양성은 줄어듭니다. 자세한 내용은 정보 버튼을 확인하세요.';

  @override
  String get couldNotOpenPgn => 'PGN을 열 수 없습니다.';

  @override
  String temperatureValue(String value) {
    return '온도: $value';
  }

  @override
  String topPValue(String value) {
    return 'Top-P: $value';
  }

  @override
  String analysisRatingValue(String rating) {
    return 'Maia 분석 레이팅: $rating';
  }

  @override
  String secondAnalysisRatingValue(String rating) {
    return '두 번째 Maia 분석 레이팅: $rating';
  }

  @override
  String premovesList(String moves) {
    return '미리두기: $moves';
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
    return '깊이 $depth · 포지션당 최대 $seconds초, 눈에 띄는 수 확인에 추가로 최대 $extraSeconds초.';
  }

  @override
  String chessnutBattery(String percent, String charging) {
    String _temp0 = intl.Intl.selectLogic(charging, {'yes': ' ⚡', 'other': ''});
    return '$percent%$_temp0';
  }

  @override
  String get chessnutBluetoothUnavailable => '이 기기에서 Bluetooth를 사용할 수 없습니다.';

  @override
  String get chessnutPermissionPending =>
      'Bluetooth 권한을 허용한 다음 Chessnut에 다시 연결하세요.';

  @override
  String get chessnutBluetoothDisabled => 'Bluetooth를 켠 다음 Chessnut에 다시 연결하세요.';

  @override
  String get whiteShort => '백';

  @override
  String get blackShort => '흑';

  @override
  String get dateUnknown => '대국 날짜 알 수 없음';

  @override
  String get savedGameVersionUnsupported =>
      '지원하지 않는 형식의 저장 데이터입니다. Mobile Maia를 업데이트한 후 열어 주세요. 이 데이터는 보존되어 있습니다.';

  @override
  String get gameStorageFailed => '저장된 대국에 접근할 수 없습니다. 다시 시도해 주세요.';

  @override
  String recentWinResult(String result) {
    return '승리 ($result)';
  }

  @override
  String recentLossResult(String result) {
    return '패배 ($result)';
  }

  @override
  String recentDrawResult(String result) {
    return '무승부 ($result)';
  }

  @override
  String get electronicBoardExperimental => '전자 체스보드(실험 기능)';

  @override
  String get connectBoard => '체스보드 연결';

  @override
  String get chooseBoard => '체스보드 선택';

  @override
  String get chooseAnotherBoard => '다른 체스보드 선택';

  @override
  String get boardSearching => '체스보드 검색 중…';

  @override
  String get boardConnecting => '체스보드 연결 중…';

  @override
  String get boardDisconnected => '체스보드 연결이 끊어졌습니다';

  @override
  String get boardConnectionError => '연결하지 못했습니다. 블루투스와 체스보드를 확인한 뒤 다시 시도하세요.';

  @override
  String get boardStartingPosition => '체스보드에 표준 시작 포지션을 배치하세요.';

  @override
  String get boardReady => '체스보드가 준비되었습니다';

  @override
  String get boardExperimentalNotice =>
      '새 체스보드 지원은 실험 단계입니다. 두 화면에서 수를 확인하고 연결 문제를 알려 주세요.';

  @override
  String get boardGameRestriction => '전자 체스보드 대국은 표준 시작 포지션에서 무제한 시간으로 시작합니다.';

  @override
  String get boardConfirmSetup => '시작 포지션을 배치했습니다';

  @override
  String get boardConfirmSetupHelp =>
      '시작 전에 모든 기물을 확인하세요. 이 체스보드는 기물의 종류를 식별할 수 없습니다.';

  @override
  String get boardChooseMove => '체스보드에서 둔 수 확인';

  @override
  String get boardAmbiguousMove => '체스보드가 이 수들을 구별할 수 없습니다. 실제로 둔 수를 선택하세요.';

  @override
  String get boardUnavailable => '체스보드가 준비되지 않았습니다. 다시 연결하거나 휴대전화에서 계속하세요.';

  @override
  String get boardNewGameConfirmInstruction =>
      '2.5초 안에 NEW GAME을 다시 눌러 확인하거나 아래 버튼을 사용하세요.';

  @override
  String get boardNewGameConfirmationExpired =>
      '체스보드에서 확인하려면 2.5초 안에 NEW GAME을 두 번 누르세요.';

  @override
  String get boardPhysicalMove => '체스보드에서 수를 완성하세요.';

  @override
  String get boardResetPhysical => '계속하기 전에 체스보드를 화면에 표시된 포지션으로 되돌리세요.';

  @override
  String get boardNoResults => '지원되는 체스보드를 찾지 못했습니다. 체스보드를 깨운 뒤 다시 시도하세요.';

  @override
  String get boardWaitingForSelection => '연결할 체스보드를 선택하세요.';

  @override
  String get boardReconnect => '체스보드 다시 연결';

  @override
  String get boardLockedPegasus =>
      'Pegasus가 잠겨 있습니다. 이 Dev 빌드에는 제조사의 초기화 키가 포함되어 있지 않습니다.';

  @override
  String get boardMotorRecovery =>
      '휴대전화에서 계속하세요. 이 실험용 연결 기능은 체스보드의 모터 상태를 안전하게 복원할 수 없습니다.';

  @override
  String get boardConfirmPosition => '실제 체스보드 포지션 확인';

  @override
  String get boardConfirmPositionHelp => '모든 기물이 화면에 표시된 포지션과 일치하는지 확인하세요.';

  @override
  String get maiaHistorySetting => '이전 포지션 사용';

  @override
  String get maiaHistoryHelp =>
      'Maia가 현재 포지션과 함께 이전 포지션을 최대 7개까지 고려하도록 합니다. 79M 모델을 사용한 저희 테스트에서는 사람의 수를 예측하는 정확도가 약 2%포인트 높아졌지만, 낮은 레이팅의 오프닝에서 상대의 수를 계속 따라 하는 경향이 강해지기도 했습니다. 실력 향상은 확인하지 못했습니다. 현재는 끄는 것을 권장합니다.';

  @override
  String get maiaHistoryResearch => '이전 포지션 연구 읽기 (영어)';

  @override
  String get maiaHistoryOn => '이전 포지션: 켜짐';

  @override
  String get maiaHistoryOff => '이전 포지션: 꺼짐';

  @override
  String get chessboardDeviceName => '체스보드';

  @override
  String namedBoardConnected(String boardName) {
    return '$boardName 연결됨';
  }

  @override
  String namedBoardDisconnected(String boardName) {
    return '$boardName 연결 끊김';
  }

  @override
  String get saveMaiaSamplingData => 'Maia 수 선택 데이터 저장';

  @override
  String get samplingDataHelp =>
      'Maia가 어떻게 두는지 살펴볼 수 있도록 수별 확률, 설정, 선택한 수를 이 기기에 저장합니다.\n\n내보낸 파일에는 보드 포지션, 수 기록, 모델 입력 및 선택 결과가 포함됩니다.\n\n데이터가 기록된 최근 10경기를 저장하고 최신 경기부터 보여 줍니다. 저장 용량 한도에 도달하면 이전 경기 데이터가 더 일찍 삭제될 수 있습니다. 이 데이터는 최근 대국과 별개입니다.\n\nMaia의 작동 원리를 기술적으로 자세히 연구하고 싶다면 이 기능을 사용하세요. 데이터는 앱 안에서 볼 수 없습니다. 일부 데이터를 보기 쉽게 정리한 HTML 파일이나 기록된 모든 데이터가 담긴 JSONL 파일로 내보낼 수 있습니다.\n\n기본값은 꺼짐이며, Maia의 작동 원리를 연구하려는 경우가 아니라면 꺼 두는 것을 권장합니다.';

  @override
  String get clearSamplingData => '수 선택 데이터 삭제';

  @override
  String samplingDataStatus(int count) {
    return '판단 $count개 저장됨';
  }

  @override
  String get samplingDataError => '수 선택 데이터에 접근할 수 없습니다. 대국에는 영향이 없습니다.';

  @override
  String get samplingSave => '저장하기…';

  @override
  String get samplingShare => '공유…';

  @override
  String get samplingSummary => 'Maia의 수 선택';

  @override
  String get samplingReadable => '읽기 쉬운 보고서 (HTML)';

  @override
  String get samplingReadableHint => '브라우저에서 수, 확률, 보드 그림을 볼 수 있습니다.';

  @override
  String get samplingResearchHint => '기술 분석을 위한 모델의 원시 입력과 출력입니다.';

  @override
  String get samplingReportExplanation =>
      '백분율은 당시 Temperature와 Top-P 설정을 적용한 뒤 각 수가 선택될 확률입니다. 승률이나 수의 좋고 나쁨을 나타내는 점수가 아닙니다.';

  @override
  String get samplingReportPartial =>
      '기록된 Maia의 판단만 표시하며, 전체 기보는 아닙니다. 무르기나 재시도로 같은 수 번호가 반복될 수 있습니다.';

  @override
  String get samplingReportMissing =>
      '일부 기록이 삭제되었거나 저장되지 않았습니다. 보고서에 누락된 내용이 있을 수 있습니다.';

  @override
  String get samplingPlayed => '둔 수';

  @override
  String get samplingNotPlayed => '실제로 둔 기록 없음';

  @override
  String get samplingAlternatives => '선택 가능성이 높은 다른 수';

  @override
  String samplingGame(String number) {
    return '게임 $number';
  }

  @override
  String samplingRecords(String count) {
    return '기록된 판단: $count';
  }

  @override
  String get samplingMostProbable => '선택 확률이 가장 높은 수';

  @override
  String get samplingPlayedMostProbable => '선택 확률이 가장 높은 수를 두었습니다';

  @override
  String samplingChance(String move, String odds) {
    return '$move 선택 확률은 약 $odds분의 1이었습니다.';
  }

  @override
  String samplingCertain(String move) {
    return '$move 선택 확률은 100%였습니다.';
  }

  @override
  String samplingAlmostCertain(String move) {
    return '$move 선택 확률은 거의 100%였습니다.';
  }

  @override
  String get samplingReportRetention =>
      '최근 기록한 10개 대국을 저장하고 최신순으로 표시합니다. 저장 용량 한도에 도달하면 이전 대국이 더 일찍 삭제될 수 있습니다.';

  @override
  String get samplingJumpToGame => '대국으로 이동';

  @override
  String get samplingBackToGames => '대국 목록으로 돌아가기';

  @override
  String get samplingIncomplete => '미완료';

  @override
  String get samplingUnknownResult => '결과 알 수 없음';

  @override
  String get samplingOpeningUnknown => '오프닝 알 수 없음';

  @override
  String get samplingTimeUnknown => '시간 알 수 없음';

  @override
  String get samplingWin => '승리';

  @override
  String get samplingLoss => '패배';

  @override
  String get samplingDraw => '무승부';

  @override
  String get samplingDeleteData => '데이터 삭제';

  @override
  String get samplingClearConfirmation =>
      'Maia의 수 선택 데이터를 모두 삭제할까요? 복구할 수 없습니다.';

  @override
  String get analysisSettings => '분석 설정';

  @override
  String get samplingData => '수 선택 데이터';

  @override
  String get resetSettingsDefaultsScope =>
      '이 화면의 모든 설정을 기본값으로 되돌립니다. 저장된 대국과 샘플링 데이터는 유지됩니다.';

  @override
  String get settingsResetError => '일부 설정을 초기화하지 못했습니다. 다시 시도해 주세요.';

  @override
  String get resetSettingsConfirmation => '모든 설정을 기본값으로 되돌릴까요?';

  @override
  String get resetSettingsKeepData => '저장된 대국과 샘플링 데이터는 유지됩니다.';

  @override
  String get resetSettingsAction => '설정 초기화';

  @override
  String get samplingHelpIntro => '온도와 Top-P는 Maia가 여러 수 중에서 어떤 수를 선택할지 조절합니다.';

  @override
  String get samplingHelpVariety =>
      '온도와 Top-P를 높이면 Maia가 낮은 확률의 수를 둘 가능성이 커져, 기복이 더 큰 선수처럼 플레이합니다. 이런 수는 블런더일 수도 있지만, 매우 좋은 수일 수도 있습니다!';

  @override
  String get samplingHelpDefaults =>
      '최대한 다양한 대국을 즐기고 싶고, 비주류 변화까지 포함해 사람들이 두는 폭넓은 오프닝을 Maia가 구사하길 원한다면 기본값인 1.0과 1.0을 유지하세요.';

  @override
  String get samplingHelpStrength =>
      '블런더를 덜 하는 더 강한 상대를 원한다면 온도와 Top-P 값을 낮춰 보세요.';

  @override
  String get samplingHelpArgmax =>
      '온도를 0으로 설정하면 Maia는 argmax라는 방식을 사용합니다. 쉽게 말해, 주어진 포지션에서 사람이 둘 가능성이 가장 높다고 Maia가 예측한 수를 항상 선택한다는 뜻입니다. 주의하세요! 레이팅을 1600으로 설정한 저희 연구에서 argmax Maia는 1.0 / 1.0 Maia와의 직접 대결에서 약 300 Elo 차이에 해당하는 우위를 보였습니다.';

  @override
  String get samplingHelpTopP =>
      '강함과 다양성의 균형을 원한다면 온도를 1.0으로 유지하고 Top-P를 0.95로 설정해 보세요. 다양성을 유지하면서 낮은 확률의 수를 제외할 수 있습니다. 이런 수는 블런더인 경우가 많지만 좋은 수일 수도 있습니다. Top-P는 간단히 말해 낮은 확률의 수를 후보에서 제외하는 설정입니다. 0.95로 설정하면 온도가 적용된 뒤의 확률을 합해 최소 95%가 되는 수들을 남깁니다. 나머지 수는 Maia가 선택할 수 없습니다.';

  @override
  String get samplingHelpResearchIntro =>
      '저희는 1600 Elo 설정에서 이 값들을 실험했으며, 전체 연구 결과를 여기에 공개했습니다:';
}

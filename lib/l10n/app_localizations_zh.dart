// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get about => '关于';

  @override
  String get analysisBoard => '分析面板';

  @override
  String get back => '返回';

  @override
  String get black => '黑方';

  @override
  String get cancelPremoves => '取消预走棋';

  @override
  String get chessnutExperimental => 'Chessnut（实验性）';

  @override
  String get connectChessnut => '连接 Chessnut';

  @override
  String get disconnect => '断开连接';

  @override
  String get engineSettings => '引擎设置';

  @override
  String get gameMenu => '对局菜单';

  @override
  String get gameReady => '对局已准备就绪';

  @override
  String get gameSettings => '对局设置';

  @override
  String get home => '首页';

  @override
  String get playMaia => '与 Maia 对弈';

  @override
  String get random => '随机';

  @override
  String get recentGames => '最近对局';

  @override
  String get resign => '认输';

  @override
  String get settings => '设置';

  @override
  String get startGame => '开始对局';

  @override
  String get timeControl => '时间限制';

  @override
  String get white => '白方';

  @override
  String get unlimited => '无限制';

  @override
  String get custom => '自定义';

  @override
  String get seconds => '秒';

  @override
  String get yourSide => '执棋颜色';

  @override
  String get you => '你';

  @override
  String get systemDefault => '跟随系统';

  @override
  String get language => '语言';

  @override
  String get playMaiaRating => '对手 Maia 的等级分';

  @override
  String get minutes => '分钟';

  @override
  String get increment => '每步加秒';

  @override
  String get gameSounds => '对局音效';

  @override
  String get movesCapturesErrorsAndGameEnd => '走棋、吃子、错误及对局结束时的音效';

  @override
  String get hapticFeedback => '触控反馈';

  @override
  String get touchFeedbackForMovesChecksErrorsAndGameEnd => '走棋、将军、错误及对局结束时的振动';

  @override
  String get premoves => '预走棋';

  @override
  String get queueAMoveWhileMaiaIsThinking => '在 Maia 思考时预设下一步棋';

  @override
  String get oneHundredMsPremovePenalty => '每次预走棋扣除 100 毫秒';

  @override
  String get use01SecondsPerPremoveInTimedGames => '计时对局中每步预走棋扣除 0.1 秒';

  @override
  String get allowMultiplePremoves => '允许多步预走棋';

  @override
  String get queueASequenceAnIllegalMoveCancelsTheRest =>
      '可预设多步棋；若某一步无法合法走出，将取消该步及之后的预走棋';

  @override
  String get humanMoveTiming => '走棋前随机停顿';

  @override
  String get variableNaturalPausesBeforeMaiaMoves => 'Maia 走棋前加入时长不一的自然停顿';

  @override
  String get aboutTemperatureAndTopP => '关于温度和 Top-P';

  @override
  String get temperature => '温度';

  @override
  String get topP => 'Top-P';

  @override
  String get maxOpeningVariety => '开局多样性最大化';

  @override
  String get maxOpeningVarietyHelp =>
      '默认开启。双方前五步使用温度和Top-P 1.0 / 1.0，从第六步开始使用您配置的设置。这样可保留广泛的开局选择，同时在之后去掉部分低概率走法。恢复对局或从某局面继续时，也按该局面的回合数执行。\n\n在1.0 / 1.0时无需此选项：这些设置已在全局保留完整多样性，因此开关显示为关闭且不可选。';

  @override
  String get maiaAnalysisRating => 'Maia 分析等级分';

  @override
  String get addSecondMaiaEngine => '添加第二个 Maia 引擎';

  @override
  String get compareAnotherMaiaRatingInAnalysisAndReview =>
      '在分析和复盘中比较另一等级分的 Maia';

  @override
  String get secondMaiaAnalysisRating => '第二个 Maia 的分析等级分';

  @override
  String get gameAnalysisQuality => '对局分析质量';

  @override
  String get resetSettingsDefaults => '恢复默认设置';

  @override
  String get boardSounds => '电子棋盘提示音';

  @override
  String get beepForCheckCheckmateAndCompletedIllegalMoves =>
      '将军、将杀或走完不合规则的一步棋时发出提示音。';

  @override
  String get copyDiagnostics => '复制诊断信息';

  @override
  String get diagnosticsCopied => '已复制诊断信息';

  @override
  String get newGame => '新的对局';

  @override
  String get resetGame => '重置对局';

  @override
  String get shareAndExport => '分享与导出';

  @override
  String get savePgnFile => '保存 PGN 文件';

  @override
  String get sharePgn => '分享 PGN';

  @override
  String get copyPgn => '复制 PGN';

  @override
  String get copyFen => '复制 FEN';

  @override
  String get maiaErrorRetry => 'Maia 出错。重试';

  @override
  String get maiaErrorPleaseRetry => 'Maia 出错。请重试。';

  @override
  String get retry => '重试';

  @override
  String get maiaIsThinking => 'Maia 正在思考…';

  @override
  String get history => '历史局面';

  @override
  String get start => '初始局面';

  @override
  String get chessnutStatus => 'Chessnut 状态';

  @override
  String get leaveCurrentGame => '离开当前对局？';

  @override
  String get yourGameWillBeKeptInRecentGames => '对局将保留在“最近对局”中。';

  @override
  String get cancel => '取消';

  @override
  String get continueAction => '继续';

  @override
  String get startANewGame => '开始新对局？';

  @override
  String get resetGameQuestion => '重置对局？';

  @override
  String get yourCompletedGameWillRemainInRecentGames => '已结束的对局仍会保留在“最近对局”中。';

  @override
  String get thisGameWillBePermanentlyErased => '该对局将被永久删除。';

  @override
  String get startNewGame => '开始新对局';

  @override
  String get reset => '重置';

  @override
  String get flipBoard => '翻转棋盘';

  @override
  String get offerDraw => '提出和棋';

  @override
  String get takeBackMove => '悔棋';

  @override
  String get whiteIsVictorious => '白方胜局';

  @override
  String get blackIsVictorious => '黑方胜局';

  @override
  String get theGameIsADraw => '对局和棋。';

  @override
  String get theGameHasEnded => '对局已结束';

  @override
  String get rematch => '重赛';

  @override
  String get fast => '快速';

  @override
  String get balanced => '均衡';

  @override
  String get thorough => '详细';

  @override
  String get continueFromHere => '从此处继续';

  @override
  String get load => '加载';

  @override
  String get editBoard => '编辑棋盘';

  @override
  String get done => '完成';

  @override
  String get whitePieces => '白方棋子';

  @override
  String get blackPieces => '黑方棋子';

  @override
  String get whiteToMove => '白方走棋';

  @override
  String get blackToMove => '黑方走棋';

  @override
  String get castlingRights => '王车易位权';

  @override
  String get whiteKingside => '白方短易位';

  @override
  String get whiteQueenside => '白方长易位';

  @override
  String get blackKingside => '黑方短易位';

  @override
  String get blackQueenside => '黑方长易位';

  @override
  String get enPassantTarget => '吃过路兵目标格';

  @override
  String get startingPosition => '起始局面';

  @override
  String get clearBoard => '清空棋盘';

  @override
  String get loadFen => '加载 FEN';

  @override
  String get loadPgn => '加载 PGN';

  @override
  String get openPgnFile => '打开 PGN 文件';

  @override
  String get clearMoves => '清除着法';

  @override
  String get boardEditor => '棋盘编辑器';

  @override
  String get endPosition => '最终局面';

  @override
  String get analysisMenu => '分析菜单';

  @override
  String get turnEngineOff => '关闭引擎';

  @override
  String get turnEngineOn => '开启引擎';

  @override
  String get moves => '着法';

  @override
  String get computerAnalysis => '电脑分析';

  @override
  String get backToGame => '返回对局';

  @override
  String get expandVariations => '展开变着';

  @override
  String get collapseVariations => '折叠变着';

  @override
  String get promoteVariation => '提升变着';

  @override
  String get mainLine => '主线';

  @override
  String get makeMainLine => '设为主线';

  @override
  String get deleteFromHere => '从此处开始删除';

  @override
  String get analyzing => '分析中…';

  @override
  String get noLegalMoves => '无合法着法';

  @override
  String get unavailable => '不可用';

  @override
  String get analysisFailed => '分析失败，请重试。';

  @override
  String get analysisStopped => '电脑分析已停止。';

  @override
  String get classifyingMoves => '正在对着法分类…';

  @override
  String get graphReadyClassifying => '图表已就绪 · 正在对着法分类…';

  @override
  String get stopAnalysis => '停止分析';

  @override
  String get runAnalysisAgain => '重新运行电脑分析';

  @override
  String get runAnalysis => '运行电脑分析';

  @override
  String get analysisExplanation => '运行电脑分析以生成评估图表和白方、黑方的准确度。';

  @override
  String get pgnCopied => 'PGN 复制成功！';

  @override
  String get fenCopied => '已复制 FEN';

  @override
  String get rawProbabilitiesExplanation => '模型原始概率已在所有合法着法间归一化，未应用温度和 Top-P。';

  @override
  String get showRawProbabilities => '显示所有模型原始概率';

  @override
  String get pasteFen => '粘贴包含全部六个字段的 FEN';

  @override
  String get pastePgn => '粘贴 PGN 棋谱';

  @override
  String get invalidPosition => '局面无效，请检查棋盘和 FEN。';

  @override
  String get pgnLoadFailed => '无法加载 PGN 棋谱，请检查文件或粘贴的文本。';

  @override
  String get goToNext => '转到下一个';

  @override
  String tapForNext(String label) {
    return '$label · 点击转到下一个';
  }

  @override
  String get notEnoughMoves => '着法数量不足';

  @override
  String get gameAccuracy => '对局准确度';

  @override
  String get accuracy => '准确度';

  @override
  String get analysisGraph => '电脑分析图表';

  @override
  String maiaMoveProbabilities(int elo) {
    return 'Maia $elo 着法概率';
  }

  @override
  String otherProbability(String probability) {
    return '其他 $probability';
  }

  @override
  String otherLegalProbability(String probability) {
    return '其他合法着法 $probability';
  }

  @override
  String maiaProbabilitySemantics(String title, String moves) {
    return '$title。$moves。';
  }

  @override
  String analysisProgress(int completed, int total) {
    return '正在分析…已完成 $completed/$total 个局面';
  }

  @override
  String graphPosition(int position, int total, String score) {
    return '局面 $position/$total，$score';
  }

  @override
  String positionNumber(int position) {
    return '局面 $position';
  }

  @override
  String classificationCount(int count, String side, String classification) {
    return '$side的$classification：$count 步';
  }

  @override
  String get classificationBrilliant => '妙着';

  @override
  String get classificationGood => '好着';

  @override
  String get classificationInteresting => '趣味着法';

  @override
  String get classificationDubious => '可疑着法';

  @override
  String get classificationMistake => '错着';

  @override
  String get classificationBlunder => '败着';

  @override
  String get gameReview => '对局复盘';

  @override
  String materialPawn(int count) {
    return '$count 个兵';
  }

  @override
  String materialKnight(int count) {
    return '$count 个马';
  }

  @override
  String materialBishop(int count) {
    return '$count 个象';
  }

  @override
  String materialRook(int count) {
    return '$count 个车';
  }

  @override
  String materialQueen(int count) {
    return '$count 个后';
  }

  @override
  String materialAdvantage(String score) {
    return '子力优势 $score';
  }

  @override
  String materialDescription(String side, String description) {
    return '$side子力差距：$description';
  }

  @override
  String get previousMove => '上一步';

  @override
  String get nextMove => '下一步';

  @override
  String get beginning => '起始局面';

  @override
  String get latestPosition => '最新局面';

  @override
  String holdForDestination(String destination) {
    return '长按前往$destination';
  }

  @override
  String get phaseOpening => '开局';

  @override
  String get phaseMiddlegame => '中局';

  @override
  String get phaseEndgame => '残局';

  @override
  String get pieceKing => '王';

  @override
  String get pieceQueen => '后';

  @override
  String get pieceRook => '车';

  @override
  String get pieceBishop => '象';

  @override
  String get pieceKnight => '马';

  @override
  String get piecePawn => '兵';

  @override
  String recentPlayerMaia(String rating) {
    return '玩家 — Maia $rating';
  }

  @override
  String recentMaiaPlayer(String rating) {
    return 'Maia $rating — 玩家';
  }

  @override
  String get recentIncomplete => '未完成';

  @override
  String get recentCompleted => '已完成';

  @override
  String get recentDeleteFailed => '无法删除已保存的对局。请重试。';

  @override
  String get recentOpenFailed => '无法打开已保存的对局。请重试。';

  @override
  String recentDeleteTitle(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '删除 $countString 局已保存的对局？';
  }

  @override
  String recentDeleteWarning(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '这 $countString 局已保存的对局将被永久删除。';
  }

  @override
  String get deleteAction => '删除';

  @override
  String get recentUpdating => '正在更新已保存的对局';

  @override
  String get recentCancelSelection => '取消选择';

  @override
  String get recentClearSelection => '清除选择';

  @override
  String get recentSelectAll => '选择所有对局';

  @override
  String get recentDeleteSelected => '删除所选对局';

  @override
  String get recentSelectGames => '选择对局';

  @override
  String get recentDeleteAll => '删除所有对局';

  @override
  String get recentDeleteOne => '删除已保存的对局';

  @override
  String recentSelectedCount(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '已选择 $countString 局';
  }

  @override
  String get recentLoadFailed => '无法加载已保存的对局。请重试。';

  @override
  String get recentEmpty => '已完成的对局，以及返回首页时保存的未完成对局，会显示在这里。';

  @override
  String recentGameSummary(String result, String date) {
    return '$result · $date';
  }

  @override
  String get diagnosticsScreenError => 'Mobile Maia 的界面出现了错误。';

  @override
  String get diagnosticsScreenInstructions => '请复制诊断信息，并在发送时说明出现此界面前点击了什么。';

  @override
  String get pgnSaved => 'PGN 已保存';

  @override
  String get pgnExportFailed => '无法导出 PGN。你的对局仍保存在本机。';

  @override
  String get languagePreferenceError => '无法保存或恢复语言设置。对局数据不受影响，请重新选择语言。';

  @override
  String playRatingValue(String rating) {
    return '对手 Maia 的等级分：$rating';
  }

  @override
  String minutesValue(String minutes) {
    return '分钟：$minutes';
  }

  @override
  String incrementSecondsValue(String seconds) {
    return '每步加秒：$seconds 秒';
  }

  @override
  String get chooseSettings => '选择设置并开始对局。';

  @override
  String get gameRestored => '已恢复对局。';

  @override
  String get reconnectChessnut => '请重新连接 Chessnut 以继续。';

  @override
  String get chessnutConnectionError => 'Chessnut 连接出错。';

  @override
  String get searchingChessnut => '正在搜索 Chessnut…';

  @override
  String get couldNotConnectChessnut => '无法连接 Chessnut。';

  @override
  String get chessnutAndroidOnly => 'Android 版支持连接 Chessnut。';

  @override
  String get chessnutIsDisconnected => 'Chessnut 未连接。';

  @override
  String get yourMove => '轮到你走棋。';

  @override
  String get yourMoveChessnut => '请在 Chessnut 上走棋。';

  @override
  String get chessnutReady => 'Chessnut 已就绪。';

  @override
  String get chessnutStartingPosition => '请在 Chessnut 上摆好标准初始局面。';

  @override
  String get takebackCompleteYourMove => '悔棋完成。请在 Chessnut 上走棋。';

  @override
  String get takebackCompleteThinking => '悔棋完成。Maia 正在思考…';

  @override
  String get restoreLitSquares => '悔棋：请还原 Chessnut 亮灯格上的棋子。';

  @override
  String get completeMaiaLitMove => '请在 Chessnut 上完成亮灯指示的 Maia 着法。';

  @override
  String get illegalChessnutPosition => '这不是合法走棋后的局面。请纠正亮灯格上的棋子。';

  @override
  String get completeYourChessnutMove => '请在 Chessnut 上完成你的走棋。';

  @override
  String get connectChessnutFirst => '开始前请连接 Chessnut。';

  @override
  String get gameInProgress => '对局进行中。';

  @override
  String get timeoutInsufficientMaterial => '和棋——虽然超时，但对方子力不足以将杀。';

  @override
  String get whiteOutOfTime => '白方超时';

  @override
  String get blackOutOfTime => '黑方超时';

  @override
  String get makeMaiaLitMove => '请在 Chessnut 上按亮灯指示走出 Maia 的着法。';

  @override
  String get checkmateMaiaWins => '将杀——Maia 获胜。';

  @override
  String get checkmateYouWin => '将杀——你获胜！';

  @override
  String get drawResult => '平局';

  @override
  String get drawByAgreement => '双方同意和棋';

  @override
  String get youWin => '你获胜。';

  @override
  String get maiaWins => 'Maia 获胜。';

  @override
  String get gameEnded => '对局已结束。';

  @override
  String get consideringDraw => 'Maia 正在考虑和棋提议…';

  @override
  String get maiaDeclinedDraw => 'Maia 拒绝了和棋提议。';

  @override
  String get couldNotEvaluateDraw => '无法评估和棋提议。';

  @override
  String get youResigned => '你已认输——Maia 获胜。';

  @override
  String get moveTakenBack => '已悔棋。轮到你走棋。';

  @override
  String get connectingChessnut => '正在连接 Chessnut…';

  @override
  String get chessnutUnavailable => 'Chessnut 不可用';

  @override
  String get chessnutDisconnected => 'Chessnut 已断开连接';

  @override
  String get reconnect => '重新连接';

  @override
  String get playInApp => '在应用中下棋';

  @override
  String get continueGameOnScreen => '在屏幕上继续此对局';

  @override
  String get checkCheckmateIllegalMoves => '将军、将杀和非法走法';

  @override
  String get offerDrawQuestion => '提出和棋？';

  @override
  String get resignGameQuestion => '认输？';

  @override
  String get resignEndsImmediately => '这将立即结束对局。';

  @override
  String get premoveLimit => '最多可设置 64 步预走棋。';

  @override
  String get chessnutGameRestriction => 'Chessnut 对局不限时。';

  @override
  String get samplingTitle => '温度和 Top-P';

  @override
  String get samplingDefaultsQuestion => '选择你想要的变化程度';

  @override
  String get samplingResearch => '完整研究数据（JSONL）';

  @override
  String get samplingResearchLink => '图解指南与研究（英文）';

  @override
  String get close => '关闭';

  @override
  String get unknownVersion => '版本未知';

  @override
  String get maiaProjectSource => 'Maia-3 项目与源代码';

  @override
  String get enCroissantProjectSource => 'En Croissant 项目与源代码';

  @override
  String get licence => '许可证';

  @override
  String get mobileMaiaSource => 'Mobile Maia 源代码';

  @override
  String get aboutPoweredBy => '由多伦多大学计算社会科学实验室开发、模仿人类棋风的国际象棋引擎 Maia-3 提供支持。';

  @override
  String get aboutOffline => 'Maia-3 完全在手机上运行，无需账户或网络连接。';

  @override
  String get aboutBoardCredits =>
      '棋盘界面、默认棕色主题和 Cburnett 棋子由 Lichess Flutter Chessground 提供。本地 Stockfish 支持使用 Lichess multistockfish。';

  @override
  String get aboutReviewCredits =>
      '对局复盘中的着法分类和弃子检测启发式算法改编自开源国际象棋界面 En Croissant。';

  @override
  String get aboutLicence =>
      'Mobile Maia 是依照 AGPL-3.0-only 分发的自由软件，不提供任何担保。你可以按照该许可证的条款重新分发和修改。完整源代码可在项目仓库中获取。';

  @override
  String get aboutIndependent =>
      '这是一款独立的社区应用，并非 Maia-3、多伦多大学、Lichess 或 En Croissant 的官方应用。';

  @override
  String get samplingRecommendationWarning => '关闭开局多样性最大化后，Maia的开局选择可能更有限。';

  @override
  String get couldNotOpenPgn => '无法打开 PGN。';

  @override
  String temperatureValue(String value) {
    return '温度：$value';
  }

  @override
  String topPValue(String value) {
    return 'Top-P：$value';
  }

  @override
  String analysisRatingValue(String rating) {
    return 'Maia 分析等级分：$rating';
  }

  @override
  String secondAnalysisRatingValue(String rating) {
    return '第二个 Maia 的分析等级分：$rating';
  }

  @override
  String premovesList(String moves) {
    return '预走棋：$moves';
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
    return '搜索深度 $depth · 每个局面最多分析 $seconds 秒，另用最多 $extraSeconds 秒复核出色着法。';
  }

  @override
  String chessnutBattery(String percent, String charging) {
    String _temp0 = intl.Intl.selectLogic(charging, {'yes': ' ⚡', 'other': ''});
    return '$percent%$_temp0';
  }

  @override
  String get chessnutBluetoothUnavailable => '此设备无法使用蓝牙。';

  @override
  String get chessnutPermissionPending => '请授予蓝牙权限，然后重新连接 Chessnut。';

  @override
  String get chessnutBluetoothDisabled => '请开启蓝牙，然后重新连接 Chessnut。';

  @override
  String get whiteShort => '白';

  @override
  String get blackShort => '黑';

  @override
  String get dateUnknown => '对局日期未知';

  @override
  String get savedGameVersionUnsupported =>
      '此保存数据使用尚不支持的格式。请更新 Mobile Maia 后再打开。此数据已保留。';

  @override
  String get gameStorageFailed => '无法访问对局存储。请重试。';

  @override
  String recentWinResult(String result) {
    return '获胜（$result）';
  }

  @override
  String recentLossResult(String result) {
    return '落败（$result）';
  }

  @override
  String recentDrawResult(String result) {
    return '和棋（$result）';
  }

  @override
  String get electronicBoardExperimental => '电子棋盘（实验性功能）';

  @override
  String get connectBoard => '连接棋盘';

  @override
  String get chooseBoard => '选择棋盘';

  @override
  String get chooseAnotherBoard => '选择其他棋盘';

  @override
  String get boardSearching => '正在搜索棋盘…';

  @override
  String get boardConnecting => '正在连接棋盘…';

  @override
  String get boardDisconnected => '棋盘连接已断开';

  @override
  String get boardConnectionError => '无法连接。请检查蓝牙和棋盘，然后重试。';

  @override
  String get boardStartingPosition => '请在棋盘上摆好标准起始局面。';

  @override
  String get boardReady => '棋盘已就绪';

  @override
  String get boardExperimentalNotice => '新棋盘支持仍处于实验阶段。请核对两个屏幕上的走法，并报告连接问题。';

  @override
  String get boardGameRestriction => '电子棋盘对局不限时。';

  @override
  String get boardConfirmSetup => '我已摆好起始局面';

  @override
  String get boardConfirmSetupHelp => '开始前请检查每个棋子。此棋盘无法识别棋子种类。';

  @override
  String get boardChooseMove => '确认棋盘上的走法';

  @override
  String get boardAmbiguousMove => '棋盘无法区分这些走法。请选择你实际走出的那一步。';

  @override
  String get boardUnavailable => '棋盘尚未就绪。请重新连接，或在手机上继续。';

  @override
  String get boardNewGameConfirmInstruction =>
      '请在2.5秒内再次按下NEW GAME以确认，或使用下方按钮。';

  @override
  String get boardNewGameConfirmationExpired => '如需在棋盘上确认，请在2.5秒内按两次NEW GAME。';

  @override
  String get boardPhysicalMove => '请在棋盘上完成这一步。';

  @override
  String get boardResetPhysical => '继续前，请将棋盘恢复为屏幕上显示的局面。';

  @override
  String get boardNoResults => '未找到支持的棋盘。请唤醒棋盘后重试。';

  @override
  String get boardWaitingForSelection => '请选择要连接的棋盘。';

  @override
  String get boardReconnect => '重新连接棋盘';

  @override
  String get boardLockedPegasus => 'Pegasus已锁定。此Dev版本未包含厂商的初始化密钥。';

  @override
  String get boardMotorRecovery => '请在手机上继续。此实验性连接功能无法安全恢复棋盘的电机状态。';

  @override
  String get boardConfirmPosition => '确认实体棋盘局面';

  @override
  String get boardConfirmPositionHelp => '请确认每个棋子的位置都与屏幕上显示的局面一致。';

  @override
  String get maiaHistorySetting => '使用历史局面';

  @override
  String get maiaHistoryHelp =>
      '让Maia在选择走法时参考最多七个先前局面。在我们使用79M模型的测试中，这使人类走法的预测准确率提高了约2个百分点，但有时也会导致低等级分的开局中反复模仿对手的走法。目前建议保持关闭。';

  @override
  String get maiaHistoryResearch => '阅读历史局面研究（英文）';

  @override
  String get maiaHistoryOn => '历史局面：开启';

  @override
  String get maiaHistoryOff => '历史局面：关闭';

  @override
  String get chessboardDeviceName => '棋盘';

  @override
  String namedBoardConnected(String boardName) {
    return '已连接$boardName';
  }

  @override
  String namedBoardDisconnected(String boardName) {
    return '$boardName已断开连接';
  }

  @override
  String get saveMaiaSamplingData => '保存 Maia 选招数据';

  @override
  String get samplingDataHelp =>
      '将 Maia 的走法概率、设置和所选走法保存在此设备上，以便研究它如何下棋。\n\n导出的文件包含棋盘局面、走法历史，以及模型的输入和决策。\n\n最近 10 局有记录的对局数据会被保存，并按从新到旧的顺序呈现。如果达到存储上限，较早的对局数据可能会提前删除。这些数据与“最近对局”分开保存。\n\n如果您想研究 Maia 工作原理的技术细节，可以使用此功能。数据无法在应用内查看。您可以导出包含部分数据、便于查看的 HTML 文件，或包含所有已记录数据的 JSONL 文件。\n\n此功能默认关闭。除非您想研究 Maia 的工作原理，否则我们建议保持关闭。';

  @override
  String get clearSamplingData => '清除选招数据';

  @override
  String samplingDataStatus(int count) {
    return '已保存 $count 条决策';
  }

  @override
  String get samplingDataError => '无法访问选招数据。不影响对局。';

  @override
  String get samplingSave => '保存…';

  @override
  String get samplingShare => '分享…';

  @override
  String get samplingSummary => 'Maia 的选择';

  @override
  String get samplingReadable => '易读报告（HTML）';

  @override
  String get samplingReadableHint => '在浏览器中查看走法、概率和棋盘图。';

  @override
  String get samplingResearchHint => '供技术分析使用的模型原始输入和输出。';

  @override
  String get samplingReportExplanation =>
      '百分比表示应用当时的 温度 和 Top-P 设置后，每步棋被选中的概率，并非获胜概率或走法质量评分。';

  @override
  String get samplingReportPartial =>
      '仅显示已记录的 Maia 决策，并非完整棋谱。悔棋或重试可能导致同一回合出现多条记录。';

  @override
  String get samplingReportMissing => '部分记录已被删除或未能保存。此报告可能存在缺失。';

  @override
  String get samplingPlayed => '实际走法';

  @override
  String get samplingNotPlayed => '未记录为已走';

  @override
  String get samplingAlternatives => '其他可能走法';

  @override
  String samplingGame(String number) {
    return '对局 $number';
  }

  @override
  String samplingRecords(String count) {
    return '已记录决策：$count';
  }

  @override
  String get samplingMostProbable => '最可能的走法';

  @override
  String get samplingPlayedMostProbable => '下出了最可能的走法';

  @override
  String samplingChance(String move, String odds) {
    return '$move 被选中的概率约为 $odds 分之一。';
  }

  @override
  String samplingCertain(String move) {
    return '$move 必定会被选中（100%）。';
  }

  @override
  String samplingAlmostCertain(String move) {
    return '$move 几乎必定会被选中。';
  }

  @override
  String get samplingReportRetention =>
      '保存最近记录的10局棋，并按从新到旧的顺序显示。达到存储上限时，较早的对局可能会提前删除。';

  @override
  String get samplingJumpToGame => '跳转到对局';

  @override
  String get samplingBackToGames => '返回对局列表';

  @override
  String get samplingIncomplete => '未完成';

  @override
  String get samplingUnknownResult => '结果未知';

  @override
  String get samplingOpeningUnknown => '开局未知';

  @override
  String get samplingTimeUnknown => '时间未知';

  @override
  String get samplingWin => '胜局';

  @override
  String get samplingLoss => '负局';

  @override
  String get samplingDraw => '平局';

  @override
  String get samplingDeleteData => '删除数据';

  @override
  String get samplingClearConfirmation => '要删除所有 Maia 选招数据吗？删除后无法恢复。';

  @override
  String get analysisSettings => '分析设置';

  @override
  String get samplingData => '选招数据';

  @override
  String get resetSettingsDefaultsScope => '将此页面上的所有设置恢复为默认值。已保存的对局和选招数据会保留。';

  @override
  String get settingsResetError => '部分设置未能重置，请重试。';

  @override
  String get resetSettingsConfirmation => '将所有设置恢复为默认值？';

  @override
  String get resetSettingsKeepData => '已保存的对局和选招数据会保留。';

  @override
  String get resetSettingsAction => '重置设置';

  @override
  String get samplingHelpIntro =>
      '温度和Top-P共同决定Maia走法的多样性。\n\n我们建议将温度设为1.0、Top-P设为0.95，并开启“开局多样性最大化”。这些就是默认设置。根据我们的研究，这些设置能在拟人化的走法、开局多样性和减少不寻常的败着之间取得良好的平衡。\n\n下面介绍这些设置的工作原理。';

  @override
  String get samplingHelpVariety =>
      '温度\n\n温度为0时，Maia总是选择它预测所选Elo等级分的棋手最有可能走的一步。这在技术上称为argmax。\n\n温度为1时，Maia会考虑它预测所选Elo等级分的棋手可能采用的全部走法，并按各自的概率从中选择。\n\n温度介于0和1之间时，Maia会更偏重它认为最可能的走法。温度越低，Maia的选择就越容易预测。\n\n例如，在我们使用79M模型、将双方等级分输入均设为1600的测试中，Maia执白时的第一步走法概率大致如下：\n\n• 1. e4：64%\n• 1. d4：25%\n• 1. c4：3%\n• 其他所有走法合计：8%\n\n温度为0时，Maia总是走1. e4。\n\n温度为0.5时，约86%的时候走1. e4，约13%的时候走1. d4。其他走法仍有可能出现，但合计不到1%。\n\n温度为1时，Maia按上面列出的原始概率选择走法。';

  @override
  String get samplingHelpDefaults =>
      'Top-P\n\nTop-P在温度调整概率之后，筛选可供选择的走法。\n\nTop-P为1时，不进行筛选。所有候选走法都可以按温度调整后的概率被选中。\n\nTop-P为0.95时，Maia按概率从高到低保留走法，直到累计概率达到至少95%，然后从中选择。被排除走法的累计概率最多为5%。\n\nTop-P为0时，Maia总是选择概率最高的走法。这与温度为0的效果相同：只要其中一个设为0，就会使用argmax。\n\n在前面的开局示例中，温度为1、Top-P为0.60时，Maia总是会走1. e4。仅这一步就占约64%的概率，因此无需其他走法便能达到60%的阈值。';

  @override
  String get samplingHelpStrength =>
      '这些设置会怎样影响Maia的走法？\n\n你可以把Top-P想象成Maia肩上的天使。设为0时，天使会告诉Maia忽略概率较低的走法，其中可能包括败着或不合理的走法。设为1.0时，天使离开了，Maia甚至可能选择最疯狂、最不可能出现的走法。\n\n在等级分设置为1600的直接对局测试中，argmax的表现优于温度1.0 / Top-P 1.0，相当于约300个Elo等级分的差距。不过，argmax也把开局选择限制在以主线为主的较小范围内。';

  @override
  String get samplingHelpArgmax =>
      '因此，我们加入了“开局多样性最大化”：开启后，Maia会在双方各自的前五步使用温度1.0和Top-P 1.0。你可能会在开局阶段看到一些疯狂的走法！从第六步起，Maia就会切换回你配置的设置。';

  @override
  String get samplingHelpTopP =>
      '我们建议保持“开局多样性最大化”开启，温度保持为1.0，Top-P保持为0.95。这就像一位富有创造力的棋手肩上有个天使，至少能劝它放弃那些特别离谱的走法——也就是概率最低、合计概率不超过5%的那些走法。它们可能是妙招，没错，但也可能是愚蠢的败着。因此，这应该能在开局的多样性、中局的创造力，以及通过排除部分极低概率的败着所获得的更强表现之间，取得良好的平衡。\n\n如果你勇于挑战，温度0在我们的测试中表现最强。祝你好运！';

  @override
  String get samplingHelpResearchIntro => '查看图解指南，了解这些选择背后的研究，并访问完整结果。';

  @override
  String get samplingFullVarietyNotice =>
      '温度和Top-P为1.0 / 1.0时，Maia可能走出更多不寻常的败着。';

  @override
  String get samplingArgmaxNotice => '温度或Top-P为0时，Maia可能更强。祝您好运！';

  @override
  String get topPNotUsed => 'Top-P：不使用';

  @override
  String get topPNotUsedTitle => '为什么不使用Top-P';

  @override
  String get topPNotUsedHelp =>
      '温度为0时，Maia总是选择一个概率最高的走法，因此Top-P不起作用。您的Top-P值会保留，提高温度后可再次使用。如果开启开局多样性，双方的前五步仍使用1.0 / 1.0。';

  @override
  String get samplingLowerNotice => '降低温度或Top-P后，Maia可能会下得更强。';

  @override
  String get appearance => '外观';

  @override
  String get appearanceSystemColors => '使用系统颜色';

  @override
  String get appearanceSystemColorsHelp => '使用 Android 的配色';

  @override
  String get appearanceSystemColorsUnavailable => '此设备不支持。需要 Android 12 或更高版本。';

  @override
  String get appearancePureBlack => '纯黑背景';

  @override
  String get appearancePureBlackHelp => '在深色模式下使用纯黑背景';

  @override
  String get appearancePreferenceError => '外观已更改，但无法保存。请重试。';

  @override
  String get appearanceTheme => '主题';

  @override
  String get appearanceLight => '浅色';

  @override
  String get appearanceDark => '深色';

  @override
  String get appearanceSystemDefault => '跟随系统';

  @override
  String get boardSettings => '棋盘';

  @override
  String get boardCoordinates => '棋盘坐标';

  @override
  String get boardLegalMoves => '合法走法落点';

  @override
  String get boardLastMove => '上一步高亮';

  @override
  String get boardAnimation => '棋子动画';

  @override
  String get boardMagnify => '放大拖动的棋子';

  @override
  String get boardDragTarget => '拖动棋子落点标记';

  @override
  String get boardTargetCircle => '圆形';

  @override
  String get boardTargetSquare => '方形';

  @override
  String get boardTargetNone => '无';

  @override
  String get boardPreferenceError => '无法保存棋盘设置。请重试。';

  @override
  String get boardDesign => '棋盘';

  @override
  String get boardPieceSet => '棋子样式';

  @override
  String get showMaiaScore => '显示 Maia 胜率（得分率）';

  @override
  String get maiaScore => 'Maia 得分';

  @override
  String get maiaScoreEqual => '均势';

  @override
  String get maiaScoreHelp => '在屏幕顶部显示 Maia 对获胜（得分）机会的评估。\n白色或黑色圆点表示该百分比对应哪一方。';

  @override
  String get maiaScoreExpectedHelp =>
      '例如，“白方 60%”表示 Maia 估计，从此局面开始下100盘棋，白方大约能得到60分。获胜得1分，和棋得½分。';

  @override
  String get maiaScoreInputsHelp =>
      '该估计将所选的 Maia 分析等级分应用于双方。启用两个 Maia 时，每个 Maia 都会按各自的等级分显示自己的估计。';

  @override
  String get maiaScorePreferenceError => '无法保存 Maia 得分设置。请重试。';

  @override
  String get maiaScoreResearchLink => 'Maia的得分预测有多可靠？（英文）';

  @override
  String get maiaScoreStockfishHelp =>
      '与 Stockfish 的评估对照来看可能会很有用。Stockfish 认为某一方更好，并不意味着人类就能轻易找到将优势转化为胜利的正确着法！';

  @override
  String get editorMoveTool => '移动棋子';

  @override
  String get editorEraseTool => '移除棋子';

  @override
  String get editorEmptySquare => '空格';

  @override
  String get editorPositionSettings => '局面设置';

  @override
  String get editorImageImportUnavailable => '从图片导入局面（尚不可用）';

  @override
  String get editorShareFen => '分享 FEN';

  @override
  String get editorFenMetadata => 'FEN 元数据';

  @override
  String get editorHalfmoveClock => '半回合计数';

  @override
  String get editorFullmoveNumber => '回合数';

  @override
  String get editorWhitePawn => '白兵';

  @override
  String get editorWhiteKnight => '白马';

  @override
  String get editorWhiteBishop => '白象';

  @override
  String get editorWhiteRook => '白车';

  @override
  String get editorWhiteQueen => '白后';

  @override
  String get editorWhiteKing => '白王';

  @override
  String get editorBlackPawn => '黑兵';

  @override
  String get editorBlackKnight => '黑马';

  @override
  String get editorBlackBishop => '黑象';

  @override
  String get editorBlackRook => '黑车';

  @override
  String get editorBlackQueen => '黑后';

  @override
  String get editorBlackKing => '黑王';

  @override
  String get continuationUseBoard => '使用电子棋盘';

  @override
  String get continuationConnectHelp => '请连接受支持的棋盘。';

  @override
  String get continuationBoardUntimed => '电子棋盘对局不限时。';

  @override
  String get continuationSetUpBoard => '摆好棋盘';

  @override
  String get continuationSetupHelp => '请在棋盘上摆出屏幕所示的局面。棋子位置一致后，对局即开始。';

  @override
  String get continuationBoardUnsupported => '目前仅支持使用 Chessnut 棋盘从指定局面继续对局。';

  @override
  String get sessionRecovery =>
      '为避免重新打开可能导致崩溃的会话，Mobile Maia 已返回主页。已保存的对局和设置均已保留。';
}

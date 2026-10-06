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
  String get resetEngineDefaults => '恢复引擎默认设置';

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
  String get chessnutGameRestriction => 'Chessnut 仅支持从标准初始局面开始的无时限对局。';

  @override
  String get samplingTitle => '温度和 Top-P';

  @override
  String get samplingDefaultsQuestion => '为什么温度和 Top-P 都设为 1.00？';

  @override
  String get samplingResearch => '阅读采样研究';

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
  String get samplingFullRange =>
      '这些设置让 Maia 可在模型预测的完整人类着法范围内选择。在等级分设为 1600 的测试中，其开局选择更接近按等级分筛选的 Lichess 对局。';

  @override
  String get samplingStrength =>
      '较低的设置会减少着法的多样性，并可能让 Maia 更强。我们更重视接近人类棋手的开局选择，而不是追求最大棋力。Maia 的等级分表示其模拟的棋手群体，并不保证相同的实战棋力。';

  @override
  String get samplingTemperatureHelp =>
      '温度控制 Maia 的走法概率有多集中。设为 0 时，Maia 总是选择模型预测人类最可能走的一步。大于 0 的较低值会使选择更集中于高概率走法；较高值则让低概率走法有更多机会被选中。';

  @override
  String get samplingTopPHelp =>
      'Top-P 将走法按概率从高到低排序，保留累计概率达到设定值的最小一组走法。较低值会将选择限制在高概率走法中；1.00 则保留所有合法走法。';

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
  String get samplingRecommendationWarning =>
      '温度或 Top-P 与推荐值 1.00 不同。详情请点击信息按钮。';

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
}

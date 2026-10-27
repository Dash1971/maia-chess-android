// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get about => 'アプリについて';

  @override
  String get analysisBoard => '棋譜解析';

  @override
  String get back => '戻る';

  @override
  String get black => '黒';

  @override
  String get cancelPremoves => 'プリムーブを取り消す';

  @override
  String get chessnutExperimental => 'Chessnut（試験的機能）';

  @override
  String get connectChessnut => 'Chessnutに接続';

  @override
  String get disconnect => '切断';

  @override
  String get engineSettings => 'エンジンの設定';

  @override
  String get gameMenu => '対局メニュー';

  @override
  String get gameReady => '対局の準備完了';

  @override
  String get gameSettings => '対局設定';

  @override
  String get home => 'ホーム';

  @override
  String get playMaia => 'Maiaと対局';

  @override
  String get random => 'ランダム';

  @override
  String get recentGames => '最近の対局';

  @override
  String get resign => '投了';

  @override
  String get settings => '設定';

  @override
  String get startGame => '対局開始';

  @override
  String get timeControl => '持時間';

  @override
  String get white => '白';

  @override
  String get unlimited => '無制限';

  @override
  String get custom => '自由設定';

  @override
  String get seconds => '秒';

  @override
  String get yourSide => '駒の色';

  @override
  String get you => 'あなた';

  @override
  String get systemDefault => '端末の設定に従う';

  @override
  String get language => '言語';

  @override
  String get playMaiaRating => '対局用Maiaのレーティング';

  @override
  String get minutes => '分';

  @override
  String get increment => '追加時間';

  @override
  String get gameSounds => '対局の効果音';

  @override
  String get movesCapturesErrorsAndGameEnd => '指し手、駒取り、エラー、対局終了時の音';

  @override
  String get hapticFeedback => '触覚フィードバック';

  @override
  String get touchFeedbackForMovesChecksErrorsAndGameEnd =>
      '指し手、チェック、エラー、対局終了時の振動';

  @override
  String get premoves => 'プリムーブ';

  @override
  String get queueAMoveWhileMaiaIsThinking => 'Maiaの手番中に次の手を予約';

  @override
  String get oneHundredMsPremovePenalty => 'プリムーブの0.1秒消費';

  @override
  String get use01SecondsPerPremoveInTimedGames => '持ち時間ありの対局でプリムーブごとに0.1秒消費';

  @override
  String get allowMultiplePremoves => '複数のプリムーブを許可';

  @override
  String get queueASequenceAnIllegalMoveCancelsTheRest =>
      '複数の手を予約できます。指せない手があると、そこから先の予約は取り消されます';

  @override
  String get humanMoveTiming => '人間らしい思考時間';

  @override
  String get variableNaturalPausesBeforeMaiaMoves =>
      'Maiaが指すまでの待ち時間に自然なばらつきを加えます';

  @override
  String get aboutTemperatureAndTopP => '温度とTop-Pについて';

  @override
  String get temperature => '温度';

  @override
  String get topP => 'Top-P';

  @override
  String get maxOpeningVariety => '序盤の多様性を最大にする';

  @override
  String get maxOpeningVarietyHelp =>
      '初期設定ではオンです。双方の最初の5手には温度とTop-P 1.0 / 1.0を使い、6手目から設定した値を使います。序盤の幅広い選択肢を保ちつつ、その後は確率の低い手を絞れます。再開や途中局面からの対局でも、その局面の手数に従います。\n\n1.0 / 1.0では最初から最後まで幅広い候補を使うため、このスイッチは不要となり、オフの状態で選択できなくなります。';

  @override
  String get maiaAnalysisRating => '解析用Maiaのレーティング';

  @override
  String get addSecondMaiaEngine => '2つ目のMaiaエンジンを追加';

  @override
  String get compareAnotherMaiaRatingInAnalysisAndReview =>
      '解析や棋譜レビューで、異なるレーティングのMaiaを比較します';

  @override
  String get secondMaiaAnalysisRating => '2つ目のMaiaのレーティング';

  @override
  String get gameAnalysisQuality => '対局解析の品質';

  @override
  String get resetSettingsDefaults => '設定を初期値に戻す';

  @override
  String get boardSounds => '電子盤の通知音';

  @override
  String get beepForCheckCheckmateAndCompletedIllegalMoves =>
      'チェック、チェックメイト、反則手を指したときに音で知らせます。';

  @override
  String get copyDiagnostics => '診断情報をコピー';

  @override
  String get diagnosticsCopied => '診断情報をコピーしました';

  @override
  String get newGame => '新しい対局';

  @override
  String get resetGame => '対局をリセット';

  @override
  String get shareAndExport => '共有とエクスポート';

  @override
  String get savePgnFile => 'PGNファイルを保存';

  @override
  String get sharePgn => 'PGN を共有';

  @override
  String get copyPgn => 'PGN をコピー';

  @override
  String get copyFen => 'FENをコピー';

  @override
  String get maiaErrorRetry => 'Maiaエラー：再試行';

  @override
  String get maiaErrorPleaseRetry => 'Maiaでエラーが発生しました。再試行してください。';

  @override
  String get retry => 'もう一度';

  @override
  String get maiaIsThinking => 'Maiaが思考中…';

  @override
  String get history => '履歴';

  @override
  String get start => '開始';

  @override
  String get chessnutStatus => 'Chessnutの状態';

  @override
  String get leaveCurrentGame => '対局から離れますか？';

  @override
  String get yourGameWillBeKeptInRecentGames => '対局は「最近の対局」に保存されます。';

  @override
  String get cancel => 'キャンセル';

  @override
  String get continueAction => '続ける';

  @override
  String get startANewGame => '新しい対局を始めますか？';

  @override
  String get resetGameQuestion => '対局をリセットしますか？';

  @override
  String get yourCompletedGameWillRemainInRecentGames => '終了した対局は「最近の対局」に残ります。';

  @override
  String get thisGameWillBePermanentlyErased => 'この対局は完全に削除されます。';

  @override
  String get startNewGame => '新しい対局を開始';

  @override
  String get reset => 'リセット';

  @override
  String get flipBoard => '盤の上下反転';

  @override
  String get offerDraw => '引き分けを提案する';

  @override
  String get takeBackMove => '待った';

  @override
  String get whiteIsVictorious => '白の勝ちです';

  @override
  String get blackIsVictorious => '黒の勝ちです';

  @override
  String get theGameIsADraw => 'ドロー（引き分け）です。';

  @override
  String get theGameHasEnded => '対局終了';

  @override
  String get rematch => '再対局';

  @override
  String get fast => '高速';

  @override
  String get balanced => '標準';

  @override
  String get thorough => '詳細';

  @override
  String get continueFromHere => 'この局面から対局';

  @override
  String get load => '読み込む';

  @override
  String get editBoard => '盤面を編集';

  @override
  String get done => '完了';

  @override
  String get whitePieces => '白の駒';

  @override
  String get blackPieces => '黒の駒';

  @override
  String get whiteToMove => '白の手番';

  @override
  String get blackToMove => '黒の手番';

  @override
  String get castlingRights => 'キャスリングの権利';

  @override
  String get whiteKingside => '白のキングサイド';

  @override
  String get whiteQueenside => '白のクイーンサイド';

  @override
  String get blackKingside => '黒のキングサイド';

  @override
  String get blackQueenside => '黒のクイーンサイド';

  @override
  String get enPassantTarget => 'アンパッサンの対象マス';

  @override
  String get startingPosition => '開始局面';

  @override
  String get clearBoard => '盤面をクリアする';

  @override
  String get loadFen => 'FENを読み込む';

  @override
  String get loadPgn => 'PGNを読み込む';

  @override
  String get openPgnFile => 'PGNファイルを開く';

  @override
  String get clearMoves => '指し手を消去';

  @override
  String get boardEditor => '盤面入力';

  @override
  String get endPosition => '最後の局面';

  @override
  String get analysisMenu => '解析メニュー';

  @override
  String get turnEngineOff => 'エンジンをオフ';

  @override
  String get turnEngineOn => 'エンジンをオン';

  @override
  String get moves => '指し手';

  @override
  String get computerAnalysis => 'コンピューター解析';

  @override
  String get backToGame => 'ゲームに戻る';

  @override
  String get expandVariations => '変化手順を表示する';

  @override
  String get collapseVariations => '変化手順をかくす';

  @override
  String get promoteVariation => '変化を上位の手順にする';

  @override
  String get mainLine => '主手順';

  @override
  String get makeMainLine => '主手順にする';

  @override
  String get deleteFromHere => 'これ以降を削除';

  @override
  String get analyzing => '解析中…';

  @override
  String get noLegalMoves => '合法手なし';

  @override
  String get unavailable => '利用できません';

  @override
  String get analysisFailed => '解析に失敗しました。再試行してください。';

  @override
  String get analysisStopped => 'コンピューター解析を停止しました。';

  @override
  String get classifyingMoves => '指し手を分類中…';

  @override
  String get graphReadyClassifying => 'グラフ生成完了 · 指し手を分類中…';

  @override
  String get stopAnalysis => '解析を停止';

  @override
  String get runAnalysisAgain => 'コンピューター解析を再実行';

  @override
  String get runAnalysis => 'コンピューター解析を実行';

  @override
  String get analysisExplanation => 'コンピューター解析で評価値グラフと白・黒それぞれの指し手の正確度を表示します。';

  @override
  String get pgnCopied => 'PGNをコピーしました。';

  @override
  String get fenCopied => 'FENをコピーしました';

  @override
  String get rawProbabilitiesExplanation =>
      '全合法手で正規化したモデルの生の確率です。温度とTop-Pは適用されません。';

  @override
  String get showRawProbabilities => 'モデルの生の確率をすべて表示';

  @override
  String get pasteFen => '6項目すべてを含むFENを貼り付け';

  @override
  String get pastePgn => 'PGNの棋譜を貼り付け';

  @override
  String get invalidPosition => '無効な局面です。盤面とFENを確認してください。';

  @override
  String get pgnLoadFailed => 'PGNを読み込めませんでした。ファイルや貼り付けた棋譜を確認してください。';

  @override
  String get goToNext => '次へ移動';

  @override
  String tapForNext(String label) {
    return '$label · タップで次へ';
  }

  @override
  String get notEnoughMoves => '指し手が不足しています';

  @override
  String get gameAccuracy => '対局の正確度';

  @override
  String get accuracy => '正確度';

  @override
  String get analysisGraph => 'コンピューター解析グラフ';

  @override
  String maiaMoveProbabilities(int elo) {
    return 'Maia $eloの指し手の確率';
  }

  @override
  String otherProbability(String probability) {
    return 'その他 $probability';
  }

  @override
  String otherLegalProbability(String probability) {
    return 'その他の合法手 $probability';
  }

  @override
  String maiaProbabilitySemantics(String title, String moves) {
    return '$title。$moves。';
  }

  @override
  String analysisProgress(int completed, int total) {
    return '解析中… $total局面中$completed局面が完了';
  }

  @override
  String graphPosition(int position, int total, String score) {
    return '局面 $position / $total、$score';
  }

  @override
  String positionNumber(int position) {
    return '局面 $position';
  }

  @override
  String classificationCount(int count, String side, String classification) {
    return '$sideの$classification：$count手';
  }

  @override
  String get classificationBrilliant => '妙手';

  @override
  String get classificationGood => '好手';

  @override
  String get classificationInteresting => '面白い手';

  @override
  String get classificationDubious => '疑問手';

  @override
  String get classificationMistake => '悪手';

  @override
  String get classificationBlunder => '大悪手';

  @override
  String get gameReview => '対局レビュー';

  @override
  String materialPawn(int count) {
    return 'ポーン$count個';
  }

  @override
  String materialKnight(int count) {
    return 'ナイト$count個';
  }

  @override
  String materialBishop(int count) {
    return 'ビショップ$count個';
  }

  @override
  String materialRook(int count) {
    return 'ルーク$count個';
  }

  @override
  String materialQueen(int count) {
    return 'クイーン$count個';
  }

  @override
  String materialAdvantage(String score) {
    return '駒得 $score';
  }

  @override
  String materialDescription(String side, String description) {
    return '$sideの駒の差：$description';
  }

  @override
  String get previousMove => '前の手';

  @override
  String get nextMove => '次の手';

  @override
  String get beginning => '開始局面';

  @override
  String get latestPosition => '最新の局面';

  @override
  String holdForDestination(String destination) {
    return '長押しで$destinationへ';
  }

  @override
  String get phaseOpening => '序盤';

  @override
  String get phaseMiddlegame => '中盤';

  @override
  String get phaseEndgame => '終盤';

  @override
  String get pieceKing => 'キング';

  @override
  String get pieceQueen => 'クイーン';

  @override
  String get pieceRook => 'ルーク';

  @override
  String get pieceBishop => 'ビショップ';

  @override
  String get pieceKnight => 'ナイト';

  @override
  String get piecePawn => 'ポーン';

  @override
  String recentPlayerMaia(String rating) {
    return 'プレイヤー — Maia $rating';
  }

  @override
  String recentMaiaPlayer(String rating) {
    return 'Maia $rating — プレイヤー';
  }

  @override
  String get recentIncomplete => '未完了';

  @override
  String get recentCompleted => '完了';

  @override
  String get recentDeleteFailed => '保存した対局を削除できませんでした。もう一度お試しください。';

  @override
  String get recentOpenFailed => '保存した対局を開けませんでした。もう一度お試しください。';

  @override
  String recentDeleteTitle(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '保存した対局を$countString局削除しますか？';
  }

  @override
  String recentDeleteWarning(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '保存した対局$countString局が完全に削除されます。';
  }

  @override
  String get deleteAction => '削除';

  @override
  String get recentUpdating => '保存した対局を更新中';

  @override
  String get recentCancelSelection => '選択をキャンセル';

  @override
  String get recentClearSelection => '選択を解除';

  @override
  String get recentSelectAll => 'すべての対局を選択';

  @override
  String get recentDeleteSelected => '選択した対局を削除';

  @override
  String get recentSelectGames => '対局を選択';

  @override
  String get recentDeleteAll => 'すべての対局を削除';

  @override
  String get recentDeleteOne => '保存した対局を削除';

  @override
  String recentSelectedCount(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString局を選択中';
  }

  @override
  String get recentLoadFailed => '保存した対局を読み込めませんでした。もう一度お試しください。';

  @override
  String get recentEmpty => '終了した対局と、ホームに戻る際に保存した未完了の対局がここに表示されます。';

  @override
  String recentGameSummary(String result, String date) {
    return '$result · $date';
  }

  @override
  String get diagnosticsScreenError => 'Mobile Maiaの画面でエラーが発生しました。';

  @override
  String get diagnosticsScreenInstructions =>
      '診断情報をコピーし、この画面が表示される直前にタップした操作の説明と一緒に送信してください。';

  @override
  String get pgnSaved => 'PGNを保存しました';

  @override
  String get pgnExportFailed => 'PGNをエクスポートできませんでした。対局は引き続き端末に保存されています。';

  @override
  String get languagePreferenceError =>
      '言語設定を保存または復元できませんでした。対局データに影響はありません。もう一度言語を選択してください。';

  @override
  String playRatingValue(String rating) {
    return '対局するMaiaのレーティング：$rating';
  }

  @override
  String minutesValue(String minutes) {
    return '持ち時間（分）：$minutes';
  }

  @override
  String incrementSecondsValue(String seconds) {
    return '追加時間：$seconds秒';
  }

  @override
  String get chooseSettings => '設定を選んで対局を始めましょう。';

  @override
  String get gameRestored => '対局を復元しました。';

  @override
  String get reconnectChessnut => '続けるにはChessnutに再接続してください。';

  @override
  String get chessnutConnectionError => 'Chessnutの接続エラー。';

  @override
  String get searchingChessnut => 'Chessnutを検索中…';

  @override
  String get couldNotConnectChessnut => 'Chessnutに接続できませんでした。';

  @override
  String get chessnutAndroidOnly => 'Chessnutへの接続機能はAndroidで利用できます。';

  @override
  String get chessnutIsDisconnected => 'Chessnutは未接続です。';

  @override
  String get yourMove => 'あなたの手番です。';

  @override
  String get yourMoveChessnut => 'Chessnutで指してください。';

  @override
  String get chessnutReady => 'Chessnutの準備ができました。';

  @override
  String get chessnutStartingPosition => 'Chessnutに標準の初期配置を並べてください。';

  @override
  String get takebackCompleteYourMove => '手を戻しました。Chessnutで指してください。';

  @override
  String get takebackCompleteThinking => '手を戻しました。Maiaが思考中…';

  @override
  String get restoreLitSquares => '手を戻すには、Chessnutの点灯したマスの駒を元に戻してください。';

  @override
  String get completeMaiaLitMove => 'Chessnutの点灯したマスに従って、Maiaの手を最後まで指してください。';

  @override
  String get illegalChessnutPosition =>
      '合法な手を指した後の局面ではありません。点灯したマスの駒を修正してください。';

  @override
  String get completeYourChessnutMove => 'Chessnutで指しかけた手を最後まで指してください。';

  @override
  String get connectChessnutFirst => '開始前にChessnutを接続してください。';

  @override
  String get gameInProgress => '対局中。';

  @override
  String get timeoutInsufficientMaterial =>
      '引き分け — 時間切れですが、相手は残りの駒でチェックメイトできません。';

  @override
  String get whiteOutOfTime => '白が時間切れになりました';

  @override
  String get blackOutOfTime => '黒が時間切れになりました';

  @override
  String get makeMaiaLitMove => 'Chessnutの点灯したマスに従って、Maiaの指し手を盤上で再現してください。';

  @override
  String get checkmateMaiaWins => 'チェックメイト — Maiaの勝ちです。';

  @override
  String get checkmateYouWin => 'チェックメイト — あなたの勝ちです！';

  @override
  String get drawResult => '引き分け';

  @override
  String get drawByAgreement => '合意によるドロー';

  @override
  String get youWin => 'あなたの勝ちです。';

  @override
  String get maiaWins => 'Maiaの勝ちです。';

  @override
  String get gameEnded => '対局が終了しました。';

  @override
  String get consideringDraw => 'Maiaが引き分けの提案を検討中…';

  @override
  String get maiaDeclinedDraw => 'Maiaは引き分けを断りました。';

  @override
  String get couldNotEvaluateDraw => '引き分けの提案を評価できませんでした。';

  @override
  String get youResigned => '投了しました — Maiaの勝ちです。';

  @override
  String get moveTakenBack => '手を戻しました。あなたの手番です。';

  @override
  String get connectingChessnut => 'Chessnutに接続中…';

  @override
  String get chessnutUnavailable => 'Chessnutを利用できません';

  @override
  String get chessnutDisconnected => 'Chessnut未接続';

  @override
  String get reconnect => '再接続';

  @override
  String get playInApp => 'アプリで対局';

  @override
  String get continueGameOnScreen => '画面でこの対局を続ける';

  @override
  String get checkCheckmateIllegalMoves => 'チェック・チェックメイト・反則手';

  @override
  String get offerDrawQuestion => '引き分けを提案しますか？';

  @override
  String get resignGameQuestion => '投了しますか？';

  @override
  String get resignEndsImmediately => '対局は直ちに終了します。';

  @override
  String get premoveLimit => 'プリムーブは64手まで予約できます。';

  @override
  String get chessnutGameRestriction => 'Chessnutでの対局は持ち時間無制限です。';

  @override
  String get samplingTitle => '温度とTop-P';

  @override
  String get samplingDefaultsQuestion => '指し手の多様さを選ぶ';

  @override
  String get samplingResearch => '研究用の全データ（JSONL）';

  @override
  String get samplingResearchLink => '図で見るガイドと研究（英文）';

  @override
  String get close => '閉じる';

  @override
  String get unknownVersion => 'バージョン不明';

  @override
  String get maiaProjectSource => 'Maia-3のプロジェクトとソースコード';

  @override
  String get enCroissantProjectSource => 'En Croissantのプロジェクトとソースコード';

  @override
  String get licence => 'ライセンス';

  @override
  String get mobileMaiaSource => 'Mobile Maiaのソースコード';

  @override
  String get aboutPoweredBy =>
      'トロント大学の計算社会科学研究室が開発した、人間らしく指すチェスエンジンMaia-3を使用しています。';

  @override
  String get aboutOffline => 'Maia-3はスマートフォン上で完結して動作します。アカウントやネットワーク接続は不要です。';

  @override
  String get aboutBoardCredits =>
      '盤面インターフェース、標準の茶色テーマ、Cburnettの駒はLichess Flutter Chessgroundが提供しています。端末上のStockfishにはLichess multistockfishを使用しています。';

  @override
  String get aboutReviewCredits =>
      '対局レビューの手の分類と駒の犠牲を検出する手法は、オープンソースのチェスGUI「En Croissant」を基にしています。';

  @override
  String get aboutLicence =>
      'Mobile MaiaはAGPL-3.0-onlyで配布される自由ソフトウェアで、いかなる保証もありません。このライセンスの条件に従って再配布・改変できます。完全なソースコードはプロジェクトのリポジトリで公開されています。';

  @override
  String get aboutIndependent =>
      'このアプリはコミュニティによる独立したアプリです。Maia-3、トロント大学、Lichess、En Croissantの公式アプリではありません。';

  @override
  String get samplingRecommendationWarning =>
      '「序盤の多様性を最大にする」をオフにすると、Maiaのオープニングの幅が狭くなる可能性があります。';

  @override
  String get couldNotOpenPgn => 'PGNを開けませんでした。';

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
    return '解析用Maiaのレーティング：$rating';
  }

  @override
  String secondAnalysisRatingValue(String rating) {
    return '2つ目の解析用Maiaのレーティング：$rating';
  }

  @override
  String premovesList(String moves) {
    return 'プリムーブ：$moves';
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
    return '深さ$depth・1局面あたり最大$seconds秒、注目すべき手の確認にさらに最大$extraSeconds秒。';
  }

  @override
  String chessnutBattery(String percent, String charging) {
    String _temp0 = intl.Intl.selectLogic(charging, {'yes': ' ⚡', 'other': ''});
    return '$percent%$_temp0';
  }

  @override
  String get chessnutBluetoothUnavailable => 'この端末ではBluetoothを利用できません。';

  @override
  String get chessnutPermissionPending =>
      'Bluetoothの権限を許可してからChessnutに再接続してください。';

  @override
  String get chessnutBluetoothDisabled =>
      'BluetoothをオンにしてからChessnutに再接続してください。';

  @override
  String get whiteShort => '白';

  @override
  String get blackShort => '黒';

  @override
  String get dateUnknown => '対局日不明';

  @override
  String get savedGameVersionUnsupported =>
      'この保存データは未対応の形式です。Mobile Maiaを更新してから開いてください。このデータは保持されています。';

  @override
  String get gameStorageFailed => '対局の保存先にアクセスできませんでした。もう一度お試しください。';

  @override
  String recentWinResult(String result) {
    return '勝ち（$result）';
  }

  @override
  String recentLossResult(String result) {
    return '負け（$result）';
  }

  @override
  String recentDrawResult(String result) {
    return '引き分け（$result）';
  }

  @override
  String get electronicBoardExperimental => '電子チェス盤（試験的機能）';

  @override
  String get connectBoard => 'チェス盤に接続';

  @override
  String get chooseBoard => 'チェス盤を選択';

  @override
  String get chooseAnotherBoard => '別のチェス盤を選択';

  @override
  String get boardSearching => 'チェス盤を検索中…';

  @override
  String get boardConnecting => 'チェス盤に接続中…';

  @override
  String get boardDisconnected => 'チェス盤との接続が切れました';

  @override
  String get boardConnectionError =>
      '接続できませんでした。Bluetoothとチェス盤を確認して、もう一度お試しください。';

  @override
  String get boardStartingPosition => 'チェス盤に標準の初期配置を並べてください。';

  @override
  String get boardReady => 'チェス盤の準備ができました';

  @override
  String get boardExperimentalNotice =>
      '新しいチェス盤への対応は試験段階です。両方の画面で指し手を確認し、接続の問題をご報告ください。';

  @override
  String get boardGameRestriction => '電子チェス盤での対局は持ち時間無制限です。';

  @override
  String get boardConfirmSetup => '初期配置を並べました';

  @override
  String get boardConfirmSetupHelp => '開始前にすべての駒を確認してください。このチェス盤は駒の種類を識別できません。';

  @override
  String get boardChooseMove => 'チェス盤での指し手を確定';

  @override
  String get boardAmbiguousMove => 'チェス盤ではこれらの指し手を区別できません。実際に指した手を選んでください。';

  @override
  String get boardUnavailable => 'チェス盤の準備ができていません。再接続するか、スマートフォンで続けてください。';

  @override
  String get boardNewGameConfirmInstruction =>
      '確定するには2.5秒以内にNEW GAMEをもう一度押すか、下のボタンを使ってください。';

  @override
  String get boardNewGameConfirmationExpired =>
      'チェス盤で確定するには、2.5秒以内にNEW GAMEを2回押してください。';

  @override
  String get boardPhysicalMove => 'チェス盤で指し手を完了してください。';

  @override
  String get boardResetPhysical => '続ける前に、チェス盤を画面に表示された局面に戻してください。';

  @override
  String get boardNoResults => '対応するチェス盤が見つかりません。チェス盤を起動して、もう一度お試しください。';

  @override
  String get boardWaitingForSelection => '接続するチェス盤を選んでください。';

  @override
  String get boardReconnect => 'チェス盤に再接続';

  @override
  String get boardLockedPegasus =>
      'Pegasusはロックされています。このDev版にはメーカーの初期化キーが含まれていません。';

  @override
  String get boardMotorRecovery =>
      'スマートフォンで続けてください。この試験的な接続機能では、チェス盤のモーターの状態を安全に復元できません。';

  @override
  String get boardConfirmPosition => 'チェス盤の局面を確認';

  @override
  String get boardConfirmPositionHelp => 'すべての駒が画面の局面と一致していることを確認してください。';

  @override
  String get maiaHistorySetting => '過去の局面を使う';

  @override
  String get maiaHistoryHelp =>
      'Maiaが指し手を選ぶ際に、最大7つ前までの局面を使えるようにします。79Mモデルを使った私たちのテストでは、人間の指し手の予測精度が約2パーセントポイント向上しましたが、低レーティングの序盤で相手の手を繰り返しまねることもありました。当面はオフのままにしておくことをおすすめします。';

  @override
  String get maiaHistoryResearch => '過去の局面の研究を読む（英文）';

  @override
  String get maiaHistoryOn => '過去の局面：使用';

  @override
  String get maiaHistoryOff => '過去の局面：不使用';

  @override
  String get chessboardDeviceName => 'チェスボード';

  @override
  String namedBoardConnected(String boardName) {
    return '$boardNameに接続しました';
  }

  @override
  String namedBoardDisconnected(String boardName) {
    return '$boardName未接続';
  }

  @override
  String get saveMaiaSamplingData => 'Maiaの手の選択データを保存';

  @override
  String get samplingDataHelp =>
      'Maiaがどのように指すかを調べるために、各手の確率、設定、選ばれた手をこの端末に保存します。\n\n書き出したファイルには、盤面、指し手の履歴、モデルへの入力と選択結果が含まれます。\n\n直近10局分の記録データが保存され、新しい順に表示されます。保存容量の上限に達すると、それより早く古い対局のデータが削除される場合があります。「最近の対局」とは別のデータです。\n\nMaiaの仕組みを技術的に詳しく調べたい方のための機能です。データはアプリ内では閲覧できません。一部のデータをまとめた見やすいHTMLファイル、または記録されたすべてのデータを含むJSONLファイルに書き出せます。\n\n初期設定はオフです。Maiaの仕組みを研究したい場合を除き、オフのままにすることをおすすめします。';

  @override
  String get clearSamplingData => '手の選択データを削除';

  @override
  String samplingDataStatus(int count) {
    return '$count件の判断を保存済み';
  }

  @override
  String get samplingDataError => '手の選択データにアクセスできませんでした。対局への影響はありません。';

  @override
  String get samplingSave => '保存…';

  @override
  String get samplingShare => '共有…';

  @override
  String get samplingSummary => 'Maiaの指し手';

  @override
  String get samplingReadable => '読みやすいレポート（HTML）';

  @override
  String get samplingReadableHint => '指し手、確率、盤面図をブラウザーで表示します。';

  @override
  String get samplingResearchHint => '技術的な分析に使うモデルの生の入出力です。';

  @override
  String get samplingReportExplanation =>
      'パーセントは、その時点の温度とTop-P設定を適用した後に各指し手が選ばれる確率です。勝率や手の良し悪しを表すものではありません。';

  @override
  String get samplingReportPartial =>
      '記録されたMaiaの判断のみを表示します。完全な棋譜ではありません。待ったや再試行により、同じ手数が複数回表示されることがあります。';

  @override
  String get samplingReportMissing =>
      '一部のデータが削除されたか、保存できませんでした。記録が抜けている可能性があります。';

  @override
  String get samplingPlayed => '指した手';

  @override
  String get samplingNotPlayed => '実際に指した記録なし';

  @override
  String get samplingAlternatives => '選ばれやすい他の手';

  @override
  String samplingGame(String number) {
    return '対局 $number';
  }

  @override
  String samplingRecords(String count) {
    return '記録された判断：$count';
  }

  @override
  String get samplingMostProbable => '最も選ばれやすい手';

  @override
  String get samplingPlayedMostProbable => '最も選ばれやすい手を指しました';

  @override
  String samplingChance(String move, String odds) {
    return '$moveが選ばれる確率は約$odds分の1でした。';
  }

  @override
  String samplingCertain(String move) {
    return '$moveが必ず選ばれる設定でした（100%）。';
  }

  @override
  String samplingAlmostCertain(String move) {
    return '$moveが選ばれる確率は、ほぼ100%でした。';
  }

  @override
  String get samplingReportRetention =>
      '記録した直近10局を保存し、新しい順に表示します。保存容量の上限に達した場合は、古い対局がそれより早く削除されることがあります。';

  @override
  String get samplingJumpToGame => '対局へ移動';

  @override
  String get samplingBackToGames => '対局一覧に戻る';

  @override
  String get samplingIncomplete => '未完了';

  @override
  String get samplingUnknownResult => '結果不明';

  @override
  String get samplingOpeningUnknown => 'オープニング不明';

  @override
  String get samplingTimeUnknown => '時刻不明';

  @override
  String get samplingWin => '勝ち';

  @override
  String get samplingLoss => '負け';

  @override
  String get samplingDraw => '引き分け';

  @override
  String get samplingDeleteData => 'データを削除';

  @override
  String get samplingClearConfirmation => 'Maiaの手の選択データをすべて削除しますか？ 復元はできません。';

  @override
  String get analysisSettings => '解析に関する設定';

  @override
  String get samplingData => '手の選択データ';

  @override
  String get resetSettingsDefaultsScope =>
      'この画面のすべての設定を初期値に戻します。保存済みの対局と手の選択データは残ります。';

  @override
  String get settingsResetError => '一部の設定を初期値に戻せませんでした。もう一度お試しください。';

  @override
  String get resetSettingsConfirmation => 'すべての設定を初期値に戻しますか？';

  @override
  String get resetSettingsKeepData => '保存済みの対局と手の選択データは残ります。';

  @override
  String get resetSettingsAction => '設定を初期値に戻す';

  @override
  String get samplingHelpIntro =>
      '温度とTop-Pを組み合わせることで、Maiaの指し手にどのくらい多様性を持たせるかが決まります。\n\n温度1.0、Top-P 0.95、「序盤の多様性を最大にする」をオンにすることをおすすめします。これらが初期設定です。私たちの研究では、人間らしい指し方、序盤の多様性、意外な大悪手の少なさの、よいバランスが得られました。\n\nそれぞれの設定の仕組みを以下で説明します。';

  @override
  String get samplingHelpVariety =>
      '温度\n\n温度0では、選択したEloのプレイヤーが最も指しそうだとMaiaが予測する手を必ず指します。これは技術的にはargmaxと呼ばれます。\n\n温度1では、選択したEloのプレイヤーが指す可能性があるとMaiaが予測するすべての手を候補とし、それぞれの確率に応じて選びます。\n\n温度が0と1の間の場合、Maiaはより指されやすいと判断した手を重視します。温度を下げるほど、Maiaの選ぶ手は予測しやすくなります。\n\n例えば、79Mモデルを使い、両プレイヤーのレーティング入力を1600にした私たちのテストでは、Maiaが白番で最初に指す手の確率はおよそ次のとおりでした。\n\n• 1. e4：64%\n• 1. d4：25%\n• 1. c4：3%\n• その他の手の合計：8%\n\n温度0では、Maiaは必ず1. e4を指しました。\n\n温度0.5では、1. e4を約86%、1. d4を約13%の割合で指しました。その他の手も選ばれる可能性はありましたが、合計で1%未満でした。\n\n温度1では、Maiaは上記の元の確率に従って指しました。';

  @override
  String get samplingHelpDefaults =>
      'Top-P\n\nTop-Pは、温度によって確率が調整された後に、候補となる手を絞り込みます。\n\nTop-P 1では、絞り込みは行われません。すべての候補手が、温度適用後の確率に応じて選ばれます。\n\nTop-P 0.95では、確率の高い順に、合計確率が95%以上に達するまでの手を残し、その中から選びます。除かれる手の合計確率は最大5%です。\n\nTop-P 0では、Maiaは必ず最も確率の高い手を選びます。これは温度0と同じ効果です。どちらか一方を0にするだけでargmaxになります。\n\n先ほどの初手の例では、温度1、Top-P 0.60にすると、Maiaは必ず1. e4を指します。この手だけで確率の約64%を占めるため、60%のしきい値に達するのに他の手は必要ありません。';

  @override
  String get samplingHelpStrength =>
      'これらの設定はMaiaの指し方にどう影響するのでしょうか？\n\nTop-Pは、Maiaの肩に乗った天使だと考えてください。0では、天使がMaiaに、確率の低い手は無視するよう助言します。そうした手には大悪手や無理のある手も含まれます。1.0では、天使はいなくなり、Maiaは最も奇抜で指されにくい手さえ選ぶことがあります。\n\nレーティング設定1600での直接対戦テストでは、argmaxは温度1.0 / Top-P 1.0を約300 Elo相当上回る成績を収めました。ただし、オープニングの選択肢も、主にメインラインの狭い範囲に限られるようになりました。';

  @override
  String get samplingHelpArgmax =>
      'そこで、「序盤の多様性を最大にする」を導入しました。白黒それぞれの最初の5手は、温度1.0、Top-P 1.0でMaiaに指させるスイッチです。序盤には驚くような手が出るかもしれません！ 6手目からは、指定した設定に切り替わります。';

  @override
  String get samplingHelpTopP =>
      '「序盤の多様性を最大にする」はオンのまま、温度は1.0、Top-Pは0.95のままにしておくことをおすすめします。創造的なプレイヤーの肩に天使が乗り、少なくとも極端に奇抜な手は思いとどまらせるようなイメージです。除かれるのは、確率の低い手のうち、合計確率が最大5%になる部分です。そうした手には妙手もあるでしょうが、単純な大悪手もあり得ます。序盤の多様性、中盤の創造性、そして非常に確率の低い大悪手の一部を除くことによる強さの、よいバランスが期待できます。\n\n腕に自信のある方は、温度を0にしてみてください。私たちのテストでは、最も強い指し方となりました。健闘を祈ります！';

  @override
  String get samplingHelpResearchIntro =>
      '設定を選んだ理由を図で紹介しています。詳しい研究結果へのリンクもあります。';

  @override
  String get samplingFullVarietyNotice =>
      '温度とTop-Pが1.0 / 1.0の場合、Maiaが意外な大悪手を指すことが増える可能性があります。';

  @override
  String get samplingArgmaxNotice => '温度またはTop-Pが0の場合、Maiaがより強くなる可能性があります。幸運を！';

  @override
  String get topPNotUsed => 'Top-P：使用しません';

  @override
  String get topPNotUsedTitle => 'Top-Pを使用しない理由';

  @override
  String get topPNotUsedHelp =>
      '温度が0の場合、Maiaは最も確率の高い手を必ず選ぶため、Top-Pは影響しません。Top-Pの値は保存され、温度を上げると再び使えます。序盤の多様性がオンなら、双方の最初の5手には引き続き1.0 / 1.0を使います。';

  @override
  String get samplingLowerNotice => '温度またはTop-Pを低くすると、Maiaがより強くなる可能性があります。';

  @override
  String get appearance => '外観';

  @override
  String get appearanceSystemColors => 'OS と同じ色設定を使う';

  @override
  String get appearanceSystemColorsHelp => 'Android のカラーパレットに合わせる';

  @override
  String get appearanceSystemColorsUnavailable =>
      'この端末では利用できません。Android 12 以降が必要です。';

  @override
  String get appearancePureBlack => '完全な黒の背景';

  @override
  String get appearancePureBlackHelp => 'ダークモードで背景を真っ黒にする';

  @override
  String get appearancePreferenceError => '外観を変更しましたが、保存できませんでした。もう一度お試しください。';

  @override
  String get appearanceTheme => 'テーマ';

  @override
  String get appearanceLight => 'ライト';

  @override
  String get appearanceDark => 'ダーク';

  @override
  String get appearanceSystemDefault => 'デバイスの設定に従う';

  @override
  String get boardSettings => '盤';

  @override
  String get boardCoordinates => 'マスの座標';

  @override
  String get boardLegalMoves => '合法手の移動先';

  @override
  String get boardLastMove => '直前の手の強調表示';

  @override
  String get boardAnimation => '駒のアニメーション';

  @override
  String get boardMagnify => 'ドラッグ中の駒を拡大';

  @override
  String get boardDragTarget => 'ドラッグ移動時の駒の照準';

  @override
  String get boardTargetCircle => '円形';

  @override
  String get boardTargetSquare => '四角形';

  @override
  String get boardTargetNone => '無効';

  @override
  String get boardPreferenceError => '盤の設定を保存できませんでした。もう一度お試しください。';

  @override
  String get boardDesign => '盤のデザイン';

  @override
  String get boardPieceSet => '駒のデザイン';

  @override
  String get showMaiaScore => 'Maiaの勝利（得点）率を表示';

  @override
  String get maiaScore => 'Maiaスコア';

  @override
  String get maiaScoreEqual => '互角';

  @override
  String get maiaScoreHelp =>
      '画面上部に、Maiaが評価した勝利（得点）の見込みを表示します。\n白または黒の点は、その割合がどちらの側を表しているかを示します。';

  @override
  String get maiaScoreExpectedHelp =>
      '例えば「白 60%」は、この局面から100局指した場合に、白が合計約60点を獲得するとMaiaが見積もっていることを意味します。勝ちは1点、引き分けは½点です。';

  @override
  String get maiaScoreInputsHelp =>
      'この評価では、選択したMaiaの解析レーティングを両者に適用します。Maiaを2つ有効にすると、それぞれが自身のレーティングでの評価を表示します。';

  @override
  String get maiaScorePreferenceError => 'Maiaスコアの設定を保存できませんでした。もう一度お試しください。';

  @override
  String get maiaScoreResearchLink => 'Maiaのスコアはどのくらい信頼できる？（英文）';

  @override
  String get maiaScoreStockfishHelp =>
      'Stockfishの評価と比べるのも役立ちます。Stockfishが一方を有利と評価していても、人間がその優位を勝ちに結び付ける正しい手を見つけやすいとは限りません！';

  @override
  String get editorMoveTool => '駒を移動';

  @override
  String get editorEraseTool => '駒を削除';

  @override
  String get editorEmptySquare => '空きマス';

  @override
  String get editorPositionSettings => '局面の設定';

  @override
  String get editorImageImportUnavailable => '画像から局面を読み込む（準備中）';

  @override
  String get editorShareFen => 'FENを共有';

  @override
  String get editorFenMetadata => 'FENの詳細';

  @override
  String get editorHalfmoveClock => '半手カウンター';

  @override
  String get editorFullmoveNumber => '手数';

  @override
  String get editorWhitePawn => '白のポーン';

  @override
  String get editorWhiteKnight => '白のナイト';

  @override
  String get editorWhiteBishop => '白のビショップ';

  @override
  String get editorWhiteRook => '白のルーク';

  @override
  String get editorWhiteQueen => '白のクイーン';

  @override
  String get editorWhiteKing => '白のキング';

  @override
  String get editorBlackPawn => '黒のポーン';

  @override
  String get editorBlackKnight => '黒のナイト';

  @override
  String get editorBlackBishop => '黒のビショップ';

  @override
  String get editorBlackRook => '黒のルーク';

  @override
  String get editorBlackQueen => '黒のクイーン';

  @override
  String get editorBlackKing => '黒のキング';

  @override
  String get continuationUseBoard => '電子チェス盤を使用';

  @override
  String get continuationConnectHelp => '対応するチェス盤を接続してください。';

  @override
  String get continuationBoardUntimed => '電子チェス盤での対局は持ち時間無制限です。';

  @override
  String get continuationSetUpBoard => '駒を配置';

  @override
  String get continuationSetupHelp =>
      '画面に表示された局面をチェス盤に並べてください。駒の配置が一致すると対局が始まります。';

  @override
  String get continuationBoardUnsupported =>
      '指定した局面からの対局は、現在Chessnutのチェス盤のみ対応しています。';

  @override
  String get sessionRecovery =>
      'クラッシュの原因となった可能性があるセッションを再開せず、ホームを開きました。保存済みの対局と設定は保持されています。';
}

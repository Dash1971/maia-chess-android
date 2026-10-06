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
  String get resetEngineDefaults => 'エンジン設定を初期化';

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
  String get chessnutGameRestriction =>
      'Chessnutでの対局は、標準の初期配置・持ち時間無制限の場合のみ対応しています。';

  @override
  String get samplingTitle => '温度とTop-P';

  @override
  String get samplingDefaultsQuestion => 'なぜ温度とTop-Pの推奨値は1.00なのですか？';

  @override
  String get samplingResearch => 'サンプリングの研究を読む';

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
  String get samplingFullRange =>
      'これらの設定では、Maiaが予測する人間の指し手を幅広く選べます。レーティング1600の設定でのテストでは、序盤の指し手の選択が、レーティングで絞り込んだLichessの対局により近くなりました。';

  @override
  String get samplingStrength =>
      '設定値を下げると指し手の多様性が減り、Maiaが強くなることがあります。私たちは強さを最大にすることより、人間らしいオープニングのレパートリーを重視しています。Maiaのレーティングは、モデルが模倣するプレイヤーのレーティングを示すもので、対局時の正確な棋力を保証するものではありません。';

  @override
  String get samplingTemperatureHelp =>
      '温度は、Maiaが選ぶ手の確率の集中度を調整します。0では、モデルが人間に最も選ばれやすいと予測した手を常に選びます。0より大きい低い値では確率の高い手に選択が集中し、高い値では確率の低い手も選ばれやすくなります。';

  @override
  String get samplingTopPHelp =>
      'Top-Pは手を確率の高い順に並べ、合計確率が設定値に達するまでの最小のグループを候補にします。低い値では確率の高い手に選択が絞られ、1.00ではすべての合法手が候補に残ります。';

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
      '温度またはTop-Pが推奨値の1.00と異なります。詳細は情報ボタンをご覧ください。';

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
}

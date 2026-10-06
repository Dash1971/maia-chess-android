// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get about => 'О приложении';

  @override
  String get analysisBoard => 'Анализировать партию';

  @override
  String get back => 'Назад';

  @override
  String get black => 'Чёрные';

  @override
  String get cancelPremoves => 'Отменить предварительные ходы';

  @override
  String get chessnutExperimental => 'Chessnut (экспериментально)';

  @override
  String get connectChessnut => 'Подключить Chessnut';

  @override
  String get disconnect => 'Отключить';

  @override
  String get engineSettings => 'Настройки движка';

  @override
  String get gameMenu => 'Меню партии';

  @override
  String get gameReady => 'Всё готово к партии';

  @override
  String get gameSettings => 'Настройки партии';

  @override
  String get home => 'Главная';

  @override
  String get playMaia => 'Играть с Maia';

  @override
  String get random => 'Случайный цвет';

  @override
  String get recentGames => 'Недавние игры';

  @override
  String get resign => 'Сдаться';

  @override
  String get settings => 'Настройки';

  @override
  String get startGame => 'Начать партию';

  @override
  String get timeControl => 'Контроль времени';

  @override
  String get white => 'Белые';

  @override
  String get unlimited => 'Отсутствует';

  @override
  String get custom => 'Своя игра';

  @override
  String get seconds => 'секунды';

  @override
  String get yourSide => 'Ваш цвет';

  @override
  String get you => 'Вы';

  @override
  String get systemDefault => 'Как в системе';

  @override
  String get language => 'Язык (Language)';

  @override
  String get playMaiaRating => 'Рейтинг Maia в игре';

  @override
  String get minutes => 'Минуты';

  @override
  String get increment => 'Добавка';

  @override
  String get gameSounds => 'Звуки игры';

  @override
  String get movesCapturesErrorsAndGameEnd =>
      'Ходы, взятия, ошибки и завершение партии';

  @override
  String get hapticFeedback => 'Реакция на касание';

  @override
  String get touchFeedbackForMovesChecksErrorsAndGameEnd =>
      'Виброотклик при ходах, шахах, ошибках и завершении партии';

  @override
  String get premoves => 'Предварительные ходы';

  @override
  String get queueAMoveWhileMaiaIsThinking =>
      'Задавайте ход заранее, пока Maia думает';

  @override
  String get oneHundredMsPremovePenalty => '100 мс на предварительный ход';

  @override
  String get use01SecondsPerPremoveInTimedGames =>
      'В партиях с часами каждый предварительный ход расходует 0,1 секунды';

  @override
  String get allowMultiplePremoves =>
      'Разрешить несколько предварительных ходов';

  @override
  String get queueASequenceAnIllegalMoveCancelsTheRest =>
      'Задавайте последовательность; невозможный ход отменяет все последующие';

  @override
  String get humanMoveTiming => 'Паузы как у человека';

  @override
  String get variableNaturalPausesBeforeMaiaMoves =>
      'Паузы разной длительности перед ходами Maia';

  @override
  String get aboutTemperatureAndTopP => 'О температуре и Top-P';

  @override
  String get temperature => 'Температура';

  @override
  String get topP => 'Top-P';

  @override
  String get maiaAnalysisRating => 'Рейтинг Maia для анализа';

  @override
  String get addSecondMaiaEngine => 'Добавить второй движок Maia';

  @override
  String get compareAnotherMaiaRatingInAnalysisAndReview =>
      'Сравнивайте с другим рейтингом Maia при анализе и разборе';

  @override
  String get secondMaiaAnalysisRating => 'Второй рейтинг Maia для анализа';

  @override
  String get gameAnalysisQuality => 'Качество анализа партии';

  @override
  String get resetEngineDefaults => 'Сбросить настройки движка';

  @override
  String get boardSounds => 'Звуки доски';

  @override
  String get beepForCheckCheckmateAndCompletedIllegalMoves =>
      'Звуковой сигнал при шахе, мате и после выполнения невозможного хода на доске.';

  @override
  String get copyDiagnostics => 'Скопировать диагностику';

  @override
  String get diagnosticsCopied => 'Диагностика скопирована';

  @override
  String get newGame => 'Новая игра';

  @override
  String get resetGame => 'Начать партию заново';

  @override
  String get shareAndExport => 'Поделиться и экспортировать';

  @override
  String get savePgnFile => 'Сохранить файл PGN';

  @override
  String get sharePgn => 'Поделиться PGN';

  @override
  String get copyPgn => 'Копировать PGN';

  @override
  String get copyFen => 'Скопировать FEN';

  @override
  String get maiaErrorRetry => 'Ошибка Maia. Повторить';

  @override
  String get maiaErrorPleaseRetry => 'Ошибка Maia. Попробуйте ещё раз.';

  @override
  String get retry => 'Повторить';

  @override
  String get maiaIsThinking => 'Maia думает…';

  @override
  String get history => 'ХОДЫ';

  @override
  String get start => 'НАЧАЛО';

  @override
  String get chessnutStatus => 'Состояние Chessnut';

  @override
  String get leaveCurrentGame => 'Выйти из текущей партии?';

  @override
  String get yourGameWillBeKeptInRecentGames =>
      'Ваша партия сохранится в разделе «Недавние игры».';

  @override
  String get cancel => 'Отменить';

  @override
  String get continueAction => 'Продолжить';

  @override
  String get startANewGame => 'Начать новую партию?';

  @override
  String get resetGameQuestion => 'Начать партию заново?';

  @override
  String get yourCompletedGameWillRemainInRecentGames =>
      'Завершённая партия останется в разделе «Недавние игры».';

  @override
  String get thisGameWillBePermanentlyErased =>
      'Эта партия будет удалена без возможности восстановления.';

  @override
  String get startNewGame => 'Начать новую партию';

  @override
  String get reset => 'Сбросить';

  @override
  String get flipBoard => 'Перевернуть доску';

  @override
  String get offerDraw => 'Предложить ничью';

  @override
  String get takeBackMove => 'Вернуть ход';

  @override
  String get whiteIsVictorious => 'Победа белых';

  @override
  String get blackIsVictorious => 'Победа чёрных';

  @override
  String get theGameIsADraw => 'Игра окончилась вничью.';

  @override
  String get theGameHasEnded => 'Партия завершена';

  @override
  String get rematch => 'Реванш';

  @override
  String get fast => 'Быстрый';

  @override
  String get balanced => 'Сбалансированный';

  @override
  String get thorough => 'Подробный';

  @override
  String get continueFromHere => 'Продолжить с этой позиции';

  @override
  String get load => 'Загрузить';

  @override
  String get editBoard => 'Изменить позицию';

  @override
  String get done => 'Готово';

  @override
  String get whitePieces => 'Белые фигуры';

  @override
  String get blackPieces => 'Чёрные фигуры';

  @override
  String get whiteToMove => 'Ход белых';

  @override
  String get blackToMove => 'Ход чёрных';

  @override
  String get castlingRights => 'Право на рокировку';

  @override
  String get whiteKingside => 'Короткая рокировка белых';

  @override
  String get whiteQueenside => 'Длинная рокировка белых';

  @override
  String get blackKingside => 'Короткая рокировка чёрных';

  @override
  String get blackQueenside => 'Длинная рокировка чёрных';

  @override
  String get enPassantTarget => 'Поле взятия на проходе';

  @override
  String get startingPosition => 'Начальная позиция';

  @override
  String get clearBoard => 'Очистить доску';

  @override
  String get loadFen => 'Загрузить FEN';

  @override
  String get loadPgn => 'Загрузить PGN';

  @override
  String get openPgnFile => 'Открыть файл PGN';

  @override
  String get clearMoves => 'Очистить ходы';

  @override
  String get boardEditor => 'Редактор доски';

  @override
  String get endPosition => 'конечная позиция';

  @override
  String get analysisMenu => 'Меню анализа';

  @override
  String get turnEngineOff => 'Выключить движок';

  @override
  String get turnEngineOn => 'Включить движок';

  @override
  String get moves => 'Ходы';

  @override
  String get computerAnalysis => 'Компьютерный анализ';

  @override
  String get backToGame => 'Вернуться к игре';

  @override
  String get expandVariations => 'Развернуть варианты';

  @override
  String get collapseVariations => 'Свернуть варианты';

  @override
  String get promoteVariation => 'Повысить приоритет варианта';

  @override
  String get makeMainLine => 'Сделать этот вариант главным';

  @override
  String get deleteFromHere => 'Удалить с этого места';

  @override
  String get analyzing => 'Анализ…';

  @override
  String get noLegalMoves => 'Нет допустимых ходов';

  @override
  String get unavailable => 'Недоступно';

  @override
  String get analysisFailed =>
      'Не удалось выполнить анализ. Попробуйте ещё раз.';

  @override
  String get analysisStopped => 'Компьютерный анализ остановлен.';

  @override
  String get classifyingMoves => 'Классификация ходов…';

  @override
  String get graphReadyClassifying => 'График готов · классификация ходов…';

  @override
  String get stopAnalysis => 'Остановить анализ';

  @override
  String get runAnalysisAgain => 'Повторить компьютерный анализ';

  @override
  String get runAnalysis => 'Выполнить компьютерный анализ';

  @override
  String get analysisExplanation =>
      'Выполните компьютерный анализ, чтобы построить график оценки и узнать точность игры белых и чёрных.';

  @override
  String get pgnCopied => 'PGN скопирован';

  @override
  String get fenCopied => 'FEN скопирован';

  @override
  String get rawProbabilitiesExplanation =>
      'Исходные вероятности выбора хода моделью, нормализованные по всем допустимым ходам. Температура и Top-P не применяются.';

  @override
  String get showRawProbabilities => 'Показать все исходные вероятности модели';

  @override
  String get pasteFen => 'Вставьте полный FEN из шести полей';

  @override
  String get pastePgn => 'Вставьте партию в формате PGN';

  @override
  String get invalidPosition => 'Недопустимая позиция. Проверьте доску и FEN.';

  @override
  String get pgnLoadFailed =>
      'Не удалось загрузить партию PGN. Проверьте файл или вставленный текст.';

  @override
  String get goToNext => 'Перейти к следующему ходу';

  @override
  String tapForNext(String label) {
    return '$label · нажмите для перехода к следующему ходу';
  }

  @override
  String get notEnoughMoves => 'Недостаточно ходов';

  @override
  String get gameAccuracy => 'Точность игры';

  @override
  String get accuracy => 'Точность';

  @override
  String get analysisGraph => 'График компьютерного анализа';

  @override
  String maiaMoveProbabilities(int elo) {
    return 'Вероятности выбора ходов Maia $elo';
  }

  @override
  String otherProbability(String probability) {
    return 'Остальные $probability';
  }

  @override
  String otherLegalProbability(String probability) {
    return 'другие допустимые ходы $probability';
  }

  @override
  String maiaProbabilitySemantics(String title, String moves) {
    return '$title. $moves.';
  }

  @override
  String analysisProgress(int completed, int total) {
    return 'Анализ позиций: $completed из $total…';
  }

  @override
  String graphPosition(int position, int total, String score) {
    return 'Позиция $position из $total · $score';
  }

  @override
  String positionNumber(int position) {
    return 'Позиция $position';
  }

  @override
  String classificationCount(int count, String side, String classification) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count хода',
      many: '$count ходов',
      few: '$count хода',
      one: '$count ход',
    );
    return '$side · $classification: $_temp0';
  }

  @override
  String get classificationBrilliant => 'Отличный ход';

  @override
  String get classificationGood => 'Хороший ход';

  @override
  String get classificationInteresting => 'Интересный ход';

  @override
  String get classificationDubious => 'Сомнительный ход';

  @override
  String get classificationMistake => 'Ошибка';

  @override
  String get classificationBlunder => 'Зевок';

  @override
  String get gameReview => 'Разбор партии';

  @override
  String materialPawn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count пешки',
      many: '$count пешек',
      few: '$count пешки',
      one: '$count пешка',
    );
    return '$_temp0';
  }

  @override
  String materialKnight(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count коня',
      many: '$count коней',
      few: '$count коня',
      one: '$count конь',
    );
    return '$_temp0';
  }

  @override
  String materialBishop(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count слона',
      many: '$count слонов',
      few: '$count слона',
      one: '$count слон',
    );
    return '$_temp0';
  }

  @override
  String materialRook(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ладьи',
      many: '$count ладей',
      few: '$count ладьи',
      one: '$count ладья',
    );
    return '$_temp0';
  }

  @override
  String materialQueen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ферзя',
      many: '$count ферзей',
      few: '$count ферзя',
      one: '$count ферзь',
    );
    return '$_temp0';
  }

  @override
  String materialAdvantage(String score) {
    return 'материальный перевес $score';
  }

  @override
  String materialDescription(String side, String description) {
    return '$side · разница в материале: $description';
  }

  @override
  String get previousMove => 'Предыдущий ход';

  @override
  String get nextMove => 'Следующий ход';

  @override
  String get beginning => 'начало партии';

  @override
  String get latestPosition => 'последняя позиция';

  @override
  String holdForDestination(String destination) {
    return 'Удерживайте для перехода: $destination';
  }

  @override
  String get phaseOpening => 'Дебют';

  @override
  String get phaseMiddlegame => 'Миттельшпиль';

  @override
  String get phaseEndgame => 'Эндшпиль';

  @override
  String get pieceKing => 'Король';

  @override
  String get pieceQueen => 'Ферзь';

  @override
  String get pieceRook => 'Ладья';

  @override
  String get pieceBishop => 'Слон';

  @override
  String get pieceKnight => 'Конь';

  @override
  String get piecePawn => 'Пешка';

  @override
  String recentPlayerMaia(String rating) {
    return 'Игрок — Maia $rating';
  }

  @override
  String recentMaiaPlayer(String rating) {
    return 'Maia $rating — Игрок';
  }

  @override
  String get recentIncomplete => 'Не завершена';

  @override
  String get recentCompleted => 'Завершена';

  @override
  String get recentDeleteFailed =>
      'Не удалось удалить сохранённые партии. Попробуйте ещё раз.';

  @override
  String get recentOpenFailed =>
      'Не удалось открыть сохранённую партию. Попробуйте ещё раз.';

  @override
  String recentDeleteTitle(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Удалить сохранённые партии ($countString)?',
      many: 'Удалить $countString сохранённых партий?',
      few: 'Удалить $countString сохранённые партии?',
      one: 'Удалить $countString сохранённую партию?',
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
          'Сохранённые партии ($countString) будут удалены без возможности восстановления.',
      many:
          '$countString сохранённых партий будут удалены без возможности восстановления.',
      few:
          '$countString сохранённые партии будут удалены без возможности восстановления.',
      one:
          '$countString сохранённая партия будет удалена без возможности восстановления.',
    );
    return '$_temp0';
  }

  @override
  String get deleteAction => 'Удалить';

  @override
  String get recentUpdating => 'Обновление сохранённых партий';

  @override
  String get recentCancelSelection => 'Отменить выбор';

  @override
  String get recentClearSelection => 'Снять выделение';

  @override
  String get recentSelectAll => 'Выбрать все партии';

  @override
  String get recentDeleteSelected => 'Удалить выбранные партии';

  @override
  String get recentSelectGames => 'Выбрать партии';

  @override
  String get recentDeleteAll => 'Удалить все партии';

  @override
  String get recentDeleteOne => 'Удалить сохранённую партию';

  @override
  String recentSelectedCount(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Выбрано партий: $countString',
      many: 'Выбрано $countString партий',
      few: 'Выбраны $countString партии',
      one: 'Выбрана $countString партия',
    );
    return '$_temp0';
  }

  @override
  String get recentLoadFailed =>
      'Не удалось загрузить сохранённые партии. Попробуйте ещё раз.';

  @override
  String get recentEmpty =>
      'Здесь появятся завершённые партии и незавершённые партии, сохранённые при переходе на главную.';

  @override
  String recentGameSummary(String result, String date) {
    return '$result · $date';
  }

  @override
  String get diagnosticsScreenError =>
      'В Mobile Maia произошла ошибка отображения экрана.';

  @override
  String get diagnosticsScreenInstructions =>
      'Скопируйте диагностику и отправьте её вместе с описанием того, на что вы нажали непосредственно перед появлением этого экрана.';

  @override
  String get pgnSaved => 'PGN сохранён';

  @override
  String get pgnExportFailed =>
      'Не удалось экспортировать PGN. Ваша партия по-прежнему сохранена на устройстве.';

  @override
  String get languagePreferenceError =>
      'Не удалось сохранить или восстановить выбранный язык. Ваши партии не затронуты. Попробуйте выбрать язык ещё раз.';

  @override
  String playRatingValue(String rating) {
    return 'Рейтинг Maia в игре: $rating';
  }

  @override
  String minutesValue(String minutes) {
    return 'Минуты: $minutes';
  }

  @override
  String incrementSecondsValue(String seconds) {
    return 'Добавление на ход (с): $seconds';
  }

  @override
  String get chooseSettings => 'Выберите настройки и начните партию.';

  @override
  String get gameRestored => 'Партия восстановлена.';

  @override
  String get reconnectChessnut =>
      'Подключите Chessnut заново, чтобы продолжить.';

  @override
  String get chessnutConnectionError => 'Ошибка подключения Chessnut.';

  @override
  String get searchingChessnut => 'Поиск Chessnut…';

  @override
  String get couldNotConnectChessnut => 'Не удалось подключить Chessnut.';

  @override
  String get chessnutAndroidOnly => 'Поддержка Chessnut доступна на Android.';

  @override
  String get chessnutIsDisconnected => 'Chessnut отключён.';

  @override
  String get yourMove => 'Ваш ход.';

  @override
  String get yourMoveChessnut => 'Ваш ход на Chessnut.';

  @override
  String get chessnutReady => 'Chessnut готов.';

  @override
  String get chessnutStartingPosition =>
      'Расставьте фигуры в стандартной начальной позиции на Chessnut.';

  @override
  String get takebackCompleteYourMove =>
      'Возврат выполнен. Ваш ход на Chessnut.';

  @override
  String get takebackCompleteThinking => 'Возврат выполнен. Maia думает…';

  @override
  String get restoreLitSquares =>
      'Возврат: восстановите положение фигур на подсвеченных полях Chessnut.';

  @override
  String get completeMaiaLitMove =>
      'Завершите ход Maia по подсказке подсветки на Chessnut.';

  @override
  String get illegalChessnutPosition =>
      'Эта позиция не соответствует допустимому ходу. Исправьте положение фигур на подсвеченных полях.';

  @override
  String get completeYourChessnutMove => 'Завершите свой ход на Chessnut.';

  @override
  String get connectChessnutFirst =>
      'Подключите Chessnut перед началом партии.';

  @override
  String get gameInProgress => 'Партия продолжается.';

  @override
  String get timeoutInsufficientMaterial =>
      'Ничья — время истекло, но у соперника недостаточно материала для мата.';

  @override
  String get whiteOutOfTime => 'У белых закончилось время.';

  @override
  String get blackOutOfTime => 'У чёрных закончилось время.';

  @override
  String get makeMaiaLitMove =>
      'Выполните ход Maia по подсказке подсветки на Chessnut.';

  @override
  String get checkmateMaiaWins => 'Мат — победа Maia.';

  @override
  String get checkmateYouWin => 'Мат — вы победили!';

  @override
  String get drawResult => 'Ничья';

  @override
  String get drawByAgreement => 'Ничья по обоюдному согласию';

  @override
  String get youWin => 'Вы победили.';

  @override
  String get maiaWins => 'Победа Maia.';

  @override
  String get gameEnded => 'Партия завершена.';

  @override
  String get consideringDraw => 'Maia обдумывает предложение ничьей…';

  @override
  String get maiaDeclinedDraw => 'Maia отклонила предложение ничьей.';

  @override
  String get couldNotEvaluateDraw => 'Не удалось оценить предложение ничьей.';

  @override
  String get youResigned => 'Вы сдались — победа Maia.';

  @override
  String get moveTakenBack => 'Возврат выполнен. Ваш ход.';

  @override
  String get connectingChessnut => 'Подключение к Chessnut…';

  @override
  String get chessnutUnavailable => 'Chessnut недоступен';

  @override
  String get chessnutDisconnected => 'Chessnut отключён';

  @override
  String get reconnect => 'Подключить заново';

  @override
  String get playInApp => 'Играть в приложении';

  @override
  String get continueGameOnScreen => 'Продолжить эту партию на экране';

  @override
  String get checkCheckmateIllegalMoves => 'Шах, мат и невозможные ходы';

  @override
  String get offerDrawQuestion => 'Предложить ничью?';

  @override
  String get resignGameQuestion => 'Сдаться?';

  @override
  String get resignEndsImmediately => 'Это немедленно завершит партию.';

  @override
  String get premoveLimit => 'Можно задать до 64 предварительных ходов.';

  @override
  String get chessnutGameRestriction =>
      'Chessnut поддерживает только партии без ограничения времени из стандартной начальной позиции.';

  @override
  String get samplingTitle => 'Температура и Top-P';

  @override
  String get samplingDefaultsQuestion =>
      'Почему температура 1.00 и Top-P 1.00?';

  @override
  String get samplingResearch => 'Прочитать исследование выбора ходов';

  @override
  String get close => 'Закрыть';

  @override
  String get unknownVersion => 'Неизвестная версия';

  @override
  String get maiaProjectSource => 'Проект Maia-3 и исходный код';

  @override
  String get enCroissantProjectSource => 'Проект En Croissant и исходный код';

  @override
  String get licence => 'Лицензия';

  @override
  String get mobileMaiaSource => 'Исходный код Mobile Maia';

  @override
  String get samplingFullRange =>
      'Эти настройки позволяют Maia выбирать из всего спектра предсказываемых человеческих ходов. В наших тестах при рейтинге 1600 выбор дебютных ходов был намного ближе к партиям Lichess, отобранным по рейтингу игроков.';

  @override
  String get samplingStrength =>
      'Более низкие значения уменьшают разнообразие ходов и могут сделать Maia сильнее. Мы предпочитаем более человеческий дебютный репертуар максимальной силе игры. Рейтинг Maia описывает игроков, поведение которых она моделирует, и не гарантирует точно такую же силу игры.';

  @override
  String get samplingTemperatureHelp =>
      'Температура определяет, насколько вероятности выбора Maia сосредоточены на отдельных ходах. При 0 Maia всегда выбирает ход, который, по прогнозу модели, люди сыграли бы с наибольшей вероятностью. Низкие положительные значения усиливают предпочтение наиболее вероятных ходов; высокие дают больше шансов менее вероятным ходам.';

  @override
  String get samplingTopPHelp =>
      'Top-P упорядочивает ходы от наиболее до наименее вероятных, затем оставляет наименьшую группу ходов в начале списка, суммарная вероятность которой достигает этого значения. Низкие значения ограничивают выбор более вероятными ходами; 1.00 сохраняет все допустимые ходы.';

  @override
  String get aboutPoweredBy =>
      'Приложение работает на Maia-3 — шахматном движке, моделирующем человеческую игру, разработанном лабораторией вычислительных социальных наук Торонтского университета.';

  @override
  String get aboutOffline =>
      'Maia-3 работает полностью на вашем телефоне. Учётная запись и подключение к сети не требуются.';

  @override
  String get aboutBoardCredits =>
      'Интерфейс доски, стандартная коричневая тема и фигуры Cburnett предоставлены Lichess Flutter Chessground. Для работы Stockfish на устройстве используется Lichess multistockfish.';

  @override
  String get aboutReviewCredits =>
      'Классификация ходов и эвристики распознавания жертв в разборе партии адаптированы из шахматного приложения En Croissant с открытым исходным кодом.';

  @override
  String get aboutLicence =>
      'Mobile Maia — свободное программное обеспечение, распространяемое по лицензии AGPL-3.0-only без каких-либо гарантий. Вы можете распространять и изменять его на условиях этой лицензии. Полный исходный код доступен в репозитории проекта.';

  @override
  String get aboutIndependent =>
      'Это независимое приложение сообщества. Оно не является официальным приложением Maia-3, Торонтского университета, Lichess или En Croissant.';

  @override
  String get samplingRecommendationWarning =>
      'Температура или Top-P отличается от рекомендуемого значения 1.00. Подробности доступны по кнопке информации.';

  @override
  String get couldNotOpenPgn => 'Не удалось открыть PGN.';

  @override
  String temperatureValue(String value) {
    return 'Температура: $value';
  }

  @override
  String topPValue(String value) {
    return 'Top-P: $value';
  }

  @override
  String analysisRatingValue(String rating) {
    return 'Рейтинг Maia для анализа: $rating';
  }

  @override
  String secondAnalysisRatingValue(String rating) {
    return 'Второй рейтинг Maia для анализа: $rating';
  }

  @override
  String premovesList(String moves) {
    return 'Предварительные ходы: $moves';
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
    return 'Глубина $depth · до $seconds с на позицию и ещё до $extraSeconds с на проверку выдающихся ходов.';
  }

  @override
  String chessnutBattery(String percent, String charging) {
    String _temp0 = intl.Intl.selectLogic(charging, {'yes': ' ⚡', 'other': ''});
    return '$percent%$_temp0';
  }

  @override
  String get chessnutBluetoothUnavailable =>
      'Bluetooth недоступен на этом устройстве.';

  @override
  String get chessnutPermissionPending =>
      'Разрешите доступ к Bluetooth, затем подключите Chessnut заново.';

  @override
  String get chessnutBluetoothDisabled =>
      'Включите Bluetooth, затем подключите Chessnut заново.';

  @override
  String get whiteShort => 'Б';

  @override
  String get blackShort => 'Ч';

  @override
  String get dateUnknown => 'Дата неизвестна';

  @override
  String get savedGameVersionUnsupported =>
      'Эти сохранённые данные имеют неподдерживаемый формат. Обновите Mobile Maia, чтобы открыть их. Данные сохранены.';

  @override
  String get gameStorageFailed =>
      'Не удалось получить доступ к хранилищу сохранённых партий. Повторите попытку.';

  @override
  String recentWinResult(String result) {
    return 'Победа ($result)';
  }

  @override
  String recentLossResult(String result) {
    return 'Поражение ($result)';
  }

  @override
  String recentDrawResult(String result) {
    return 'Ничья ($result)';
  }
}

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
  String get maxOpeningVariety => 'Максимальное разнообразие в дебюте';

  @override
  String get maxOpeningVarietyHelp =>
      'Не требуется, если Температура и Top-P имеют значения по умолчанию 1,0 / 1,0. Для первых пяти ходов каждой стороны используются значения 1,0 / 1,0, а с 6-го хода снова применяются ваши настройки.\n\nЦель — обеспечить Maia максимальное разнообразие в дебюте и возможность более сильной игры в дальнейшем: снижение Температуры и/или Top-P уменьшает шанс выбора маловероятных ходов.';

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
  String get resetSettingsDefaults => 'Восстановить настройки по умолчанию';

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
    return 'Добавка: $seconds с';
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
  String get whiteOutOfTime => 'Белые просрочили время';

  @override
  String get blackOutOfTime => 'У черных закончилось время';

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
      'Выберите, насколько разнообразной будет игра';

  @override
  String get samplingResearch => 'Полные данные для исследования (JSONL)';

  @override
  String get samplingResearchLink =>
      'Полные данные для исследования (на английском)';

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
      'Снижение температуры или Top-P может усилить игру Maia в миттельшпиле, но уменьшает разнообразие дебютов. Подробнее — по кнопке информации.';

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

  @override
  String get electronicBoardExperimental =>
      'Электронная доска (экспериментально)';

  @override
  String get connectBoard => 'Подключить доску';

  @override
  String get chooseBoard => 'Выбрать доску';

  @override
  String get chooseAnotherBoard => 'Выбрать другую доску';

  @override
  String get boardSearching => 'Поиск досок…';

  @override
  String get boardConnecting => 'Подключение к доске…';

  @override
  String get boardDisconnected => 'Доска отключена';

  @override
  String get boardConnectionError =>
      'Не удалось подключиться. Проверьте Bluetooth и доску и повторите попытку.';

  @override
  String get boardStartingPosition =>
      'Расставьте фигуры на доске в стандартной начальной позиции.';

  @override
  String get boardReady => 'Доска готова';

  @override
  String get boardExperimentalNotice =>
      'Поддержка новых досок экспериментальная. Проверяйте ходы на обоих экранах и сообщайте о проблемах с подключением.';

  @override
  String get boardGameRestriction =>
      'Партии на электронной доске начинаются со стандартной начальной позиции и идут без ограничения времени.';

  @override
  String get boardConfirmSetup => 'Я расставил фигуры в начальной позиции';

  @override
  String get boardConfirmSetupHelp =>
      'Перед началом проверьте каждую фигуру. Эта доска не может определять тип фигуры.';

  @override
  String get boardChooseMove => 'Подтвердите ход на доске';

  @override
  String get boardAmbiguousMove =>
      'Доска не может различить эти ходы. Выберите ход, который вы сделали.';

  @override
  String get boardUnavailable =>
      'Доска не готова. Подключите её заново или продолжите на телефоне.';

  @override
  String get boardNewGameConfirmInstruction =>
      'Для подтверждения нажмите NEW GAME ещё раз в течение 2,5 секунды или используйте кнопки ниже.';

  @override
  String get boardNewGameConfirmationExpired =>
      'Для подтверждения на доске нажмите NEW GAME дважды в течение 2,5 секунды.';

  @override
  String get boardPhysicalMove => 'Завершите ход на доске.';

  @override
  String get boardResetPhysical =>
      'Прежде чем продолжить, восстановите на доске позицию, показанную на экране.';

  @override
  String get boardNoResults =>
      'Совместимая доска не найдена. Разбудите доску и повторите попытку.';

  @override
  String get boardWaitingForSelection => 'Выберите доску для подключения.';

  @override
  String get boardReconnect => 'Подключить доску заново';

  @override
  String get boardLockedPegasus =>
      'Pegasus заблокирован. Эта Dev-сборка не содержит ключ инициализации производителя.';

  @override
  String get boardMotorRecovery =>
      'Продолжите на телефоне. Этот экспериментальный адаптер не может безопасно восстановить состояние мотора доски.';

  @override
  String get boardConfirmPosition => 'Подтвердить позицию на физической доске';

  @override
  String get boardConfirmPositionHelp =>
      'Проверьте, что каждая фигура соответствует позиции на экране.';

  @override
  String get maiaHistorySetting => 'Учитывать историю позиций';

  @override
  String get maiaHistoryHelp =>
      'Позвольте Maia учитывать до семи предыдущих позиций вместе с текущей. В наших тестах с моделью 79M это повысило точность предсказания человеческих ходов примерно на 2 процентных пункта, но иногда усиливало склонность многократно копировать ходы соперника в дебютах при низком рейтинге. Установить повышение силы игры нам не удалось. Пока рекомендуем оставить эту настройку выключенной.';

  @override
  String get maiaHistoryResearch =>
      'Читать исследование истории позиций (на английском)';

  @override
  String get maiaHistoryOn => 'История позиций: включена';

  @override
  String get maiaHistoryOff => 'История позиций: выключена';

  @override
  String get chessboardDeviceName => 'Шахматная доска';

  @override
  String namedBoardConnected(String boardName) {
    return '$boardName: подключено';
  }

  @override
  String namedBoardDisconnected(String boardName) {
    return '$boardName: отключено';
  }

  @override
  String get saveMaiaSamplingData => 'Сохранять данные о выборе ходов Maia';

  @override
  String get samplingDataHelp =>
      'Сохраняйте вероятности ходов Maia, настройки и выбранные ходы на этом устройстве, чтобы изучать её игру.\n\nЭкспортируемые файлы содержат позиции на доске, историю ходов, входные данные и решения модели.\n\nСохраняются последние 10 партий с записанными данными, начиная с самой новой. Старые партии могут быть удалены раньше, если достигнут лимит хранилища. Эти данные хранятся отдельно от раздела «Недавние игры».\n\nИспользуйте эту функцию, если вам интересно изучить технические подробности работы Maia. Просмотреть данные в приложении нельзя. Они экспортируются в удобный для просмотра HTML-файл с частью данных или в JSONL-файл со всеми записанными данными.\n\nПо умолчанию функция выключена. Рекомендуем оставить её выключенной, если вы не планируете исследовать работу Maia.';

  @override
  String get clearSamplingData => 'Удалить данные о выборе ходов';

  @override
  String samplingDataStatus(int count) {
    return 'Сохранено решений: $count';
  }

  @override
  String get samplingDataError =>
      'Не удалось получить доступ к данным о выборе ходов. Это не мешает игре.';

  @override
  String get samplingSave => 'Сохранить…';

  @override
  String get samplingShare => 'Поделиться…';

  @override
  String get samplingSummary => 'Выбор ходов Maia';

  @override
  String get samplingReadable => 'Читаемый отчёт (HTML)';

  @override
  String get samplingReadableHint =>
      'Ходы, вероятности и диаграммы. Открывается в браузере.';

  @override
  String get samplingResearchHint =>
      'Исходные входные и выходные данные модели для технического анализа.';

  @override
  String get samplingReportExplanation =>
      'Проценты показывают вероятность выбора каждого хода после применения ваших настроек температуры и Top-P. Это не шансы на победу и не оценка качества хода.';

  @override
  String get samplingReportPartial =>
      'Показаны только записанные решения Maia, а не полная партия. Из-за отмены ходов и повторных попыток номера ходов могут повторяться.';

  @override
  String get samplingReportMissing =>
      'Часть данных удалена или не была сохранена. В отчёте могут быть пропуски.';

  @override
  String get samplingPlayed => 'Сыграно';

  @override
  String get samplingNotPlayed => 'Не записан как сыгранный';

  @override
  String get samplingAlternatives => 'Вероятные альтернативы';

  @override
  String samplingGame(String number) {
    return 'Партия $number';
  }

  @override
  String samplingRecords(String count) {
    return 'Записано решений: $count';
  }

  @override
  String get samplingMostProbable => 'Наиболее вероятный';

  @override
  String get samplingPlayedMostProbable => 'Сыгран наиболее вероятный ход';

  @override
  String samplingChance(String move, String odds) {
    return 'Вероятность выбора хода $move составляла примерно 1 из $odds.';
  }

  @override
  String samplingCertain(String move) {
    return 'Ход $move выбирался гарантированно (100%).';
  }

  @override
  String samplingAlmostCertain(String move) {
    return 'Ход $move выбирался почти наверняка.';
  }

  @override
  String get samplingReportRetention =>
      'Последние 10 записанных партий сохраняются и отображаются от новых к старым. Старые партии могут быть удалены раньше, если достигнут лимит хранилища.';

  @override
  String get samplingJumpToGame => 'Перейти к партии';

  @override
  String get samplingBackToGames => 'К списку партий';

  @override
  String get samplingIncomplete => 'Не завершена';

  @override
  String get samplingUnknownResult => 'Результат неизвестен';

  @override
  String get samplingOpeningUnknown => 'Дебют неизвестен';

  @override
  String get samplingTimeUnknown => 'Время неизвестно';

  @override
  String get samplingWin => 'Победа';

  @override
  String get samplingLoss => 'Поражение';

  @override
  String get samplingDraw => 'Ничья';

  @override
  String get samplingDeleteData => 'Удалить данные';

  @override
  String get samplingClearConfirmation =>
      'Удалить все данные о выборе ходов Maia? Восстановить их будет невозможно.';

  @override
  String get analysisSettings => 'Настройки анализа';

  @override
  String get samplingData => 'Данные о выборе ходов';

  @override
  String get resetSettingsDefaultsScope =>
      'Сбрасывает все настройки на этом экране. Сохранённые партии и данные выборки сохраняются.';

  @override
  String get settingsResetError =>
      'Не удалось сбросить некоторые настройки. Попробуйте ещё раз.';

  @override
  String get resetSettingsConfirmation =>
      'Восстановить все настройки по умолчанию?';

  @override
  String get resetSettingsKeepData =>
      'Ваши сохранённые партии и данные выборки сохранятся.';

  @override
  String get resetSettingsAction => 'Сбросить настройки';

  @override
  String get samplingHelpIntro =>
      'Температура и Top-P определяют, как Maia выбирает между возможными ходами.';

  @override
  String get samplingHelpVariety =>
      'При повышении Температуры и Top-P Maia становится более непредсказуемым соперником, поскольку чаще выбирает маловероятные ходы. Это могут быть зевки, но могут быть и отличные ходы!';

  @override
  String get samplingHelpDefaults =>
      'Если вам нужно максимальное разнообразие и вы хотите, чтобы Maia играла широкий набор человеческих дебютов, включая побочные варианты, оставьте значения по умолчанию: 1,0 и 1,0.';

  @override
  String get samplingHelpStrength =>
      'Если вы предпочитаете более сильного соперника, который реже зевает, попробуйте уменьшить значения Температуры и Top-P.';

  @override
  String get samplingHelpArgmax =>
      'При Температуре 0 Maia использует argmax. Этот технический термин означает, что Maia всегда играет ход, который, по её прогнозу, человек с наибольшей вероятностью выберет в данной позиции. Осторожно! В нашем исследовании при настройке рейтинга 1600 Maia с argmax превосходила Maia с настройками 1,0 / 1,0 в прямых встречах на величину, эквивалентную примерно 300 пунктам Elo.';

  @override
  String get samplingHelpTopP =>
      'Для баланса силы и разнообразия можно оставить Температуру на 1,0 и установить Top-P на 0,95. Это сохраняет разнообразие, исключая маловероятные ходы, которые часто могут быть зевками, но могут быть и хорошими ходами. По сути, Top-P отсекает наименее вероятные ходы. При значении 0,95 остаются ходы, на которые приходится в сумме не менее 95 % вероятности после применения Температуры. Остальные ходы Maia выбрать не сможет.';

  @override
  String get samplingHelpResearchIntro =>
      'Мы экспериментировали с этими настройками при рейтинге 1600 Elo и опубликовали все результаты здесь:';
}

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:chess/chess.dart' as chess;
import 'package:chessground/chessground.dart' as cg;
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show
        LicenseRegistry,
        LicenseEntryWithLineBreaks,
        mapEquals,
        listEquals,
        visibleForTesting;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:multistockfish/multistockfish.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';

part 'src/engine_queue.dart';
part 'src/session_repository.dart';
part 'src/session_history.dart';
part 'src/pgn_files.dart';

part 'src/maia_queue.dart';
part 'src/diagnostics.dart';
part 'src/session_types.dart';
part 'src/variation_tree.dart';
part 'src/game_clocks.dart';
part 'src/human_timing.dart';
part 'src/premoves.dart';
part 'src/active_session_store.dart';
part 'src/session_model.dart';
part 'src/openings.dart';
part 'src/chessnut.dart';
part 'src/history_navigation.dart';
part 'src/sound_effect.dart';
part 'src/game_feedback.dart';
part 'src/play.dart';
part 'src/play_localization.dart';
part 'src/analysis_board.dart';
part 'src/review.dart';
part 'src/review_widgets.dart';
part 'src/stockfish.dart';
part 'src/maia.dart';
part 'src/app_language.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Mobile Maia / Maia-3',
    ], await rootBundle.loadString('LICENSE'));
    yield LicenseEntryWithLineBreaks([
      'Mobile Maia third-party notices',
    ], await rootBundle.loadString('THIRD_PARTY_NOTICES.md'));
  });
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(
      AppDiagnostics.record(
        'flutter-framework',
        details.exception,
        details.stack ?? StackTrace.current,
      ),
    );
  };
  ui.PlatformDispatcher.instance.onError = (error, stackTrace) {
    unawaited(AppDiagnostics.record('unhandled-async', error, stackTrace));
    return true;
  };
  ErrorWidget.builder = (_) => const DiagnosticsErrorScreen();
  runApp(const MaiaChessApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Opening labels are useful but several taps away. Load them after the
    // first frame instead of making every cold start parse the full TSV asset.
    unawaited(
      OpeningNames.load().catchError((Object error, StackTrace stackTrace) {
        return AppDiagnostics.record('opening-names-load', error, stackTrace);
      }),
    );
  });
  unawaited(AppDiagnostics.recordEvent('app-started'));
}

final maiaRouteObserver = RouteObserver<PageRoute<dynamic>>();

const maiaEngineChannel = MethodChannel('maia_chess/engine');
const maiaProjectUrl = 'https://github.com/CSSLab/maia3';
const lichessChessgroundUrl =
    'https://github.com/lichess-org/flutter-chessground';
const lichessMultistockfishUrl =
    'https://github.com/lichess-org/dart-multistockfish';
const enCroissantProjectUrl =
    'https://github.com/franciscoBSalgueiro/en-croissant';
const mobileMaiaSourceUrl =
    'https://github.com/Dash1971/maia-chess-android';
const mobileMaiaLicenseUrl = '$mobileMaiaSourceUrl/blob/main/LICENSE';
const maiaPlayEloPreferenceKey = 'maiaPlayEloV1';
const maiaPlaySidePreferenceKey = 'maiaPlaySideV1';
const maiaTimePresetPreferenceKey = 'maiaTimePresetV1';
const maiaCustomMinutesPreferenceKey = 'maiaCustomMinutesV1';
const maiaCustomIncrementPreferenceKey = 'maiaCustomIncrementV1';
const gameAnalysisQualityPreferenceKey = 'gameAnalysisQualityV1';
const secondMaiaEnabledPreferenceKey = 'secondMaiaEnabledV1';
const secondMaiaEloPreferenceKey = 'secondMaiaEloV1';

// Match the Lichess app defaults across live play, Analysis Board, and Game
// Review: magnify touch drags, lift the piece above the pointer, show the
// circular drop target, and retain the 150 ms move animation.
const mobileMaiaInteractiveBoardSettings = cg.ChessboardSettings(
  colorScheme: cg.ChessboardColorScheme.brown,
  pieceAssets: cg.PieceSet.cburnettAssets,
  enableCoordinates: true,
  animationDuration: Duration(milliseconds: 150),
  dragFeedbackScale: 2.0,
  dragFeedbackOffset: Offset(0.0, -1.0),
  dragTargetKind: cg.DragTargetKind.circle,
  enablePremoves: true,
  pieceShiftMethod: cg.PieceShiftMethod.either,
);

bool shouldRequestMaiaReply({
  required bool premovePlayed,
  required bool gameOver,
}) => premovePlayed && !gameOver;

class MaiaChessApp extends StatefulWidget {
  const MaiaChessApp({super.key});

  @override
  State<MaiaChessApp> createState() => _MaiaChessAppState();
}

class _MaiaChessAppState extends State<MaiaChessApp>
    with WidgetsBindingObserver {
  Timer? _maiaReleaseTimer;
  final AppLanguageController _language = AppLanguageController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _language.addListener(_languageChanged);
    unawaited(_language.initialize());
  }

  void _languageChanged() {
    if (mounted) setState(() {});
  }

  void _setLanguage(String? code) => unawaited(_language.select(code));

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(
        StockfishAnalyzer.instance.close().catchError(
          (Object error, StackTrace stackTrace) =>
              AppDiagnostics.record('stockfish-close', error, stackTrace),
        ),
      );
      _maiaReleaseTimer?.cancel();
      _maiaReleaseTimer = Timer(const Duration(seconds: 30), _releaseMaia);
    } else if (state == AppLifecycleState.resumed) {
      _maiaReleaseTimer?.cancel();
    }
  }

  void _releaseMaia() {
    unawaited(
      maiaEngineChannel
          .invokeMethod<void>('release')
          .catchError(
            (Object error, StackTrace stack) =>
                AppDiagnostics.record('maia-close', error, stack),
          ),
    );
  }

  @override
  void didHaveMemoryPressure() {
    _maiaReleaseTimer?.cancel();
    _releaseMaia();
  }

  @override
  void dispose() {
    _maiaReleaseTimer?.cancel();
    _language.removeListener(_languageChanged);
    _language.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile Maia',
      locale: _language.selectedCode == null
          ? null
          : Locale(_language.selectedCode!),
      localeListResolutionCallback: resolveAppLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      navigatorObservers: [maiaRouteObserver],
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff5d735f),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xff171a18),
        useMaterial3: true,
      ),
      home: AppLanguageSettings(
        selectedCode: _language.selectedCode,
        persistenceFailed: _language.persistenceFailed,
        onChanged: _setLanguage,
        child: const GamePage(),
      ),
    );
  }
}

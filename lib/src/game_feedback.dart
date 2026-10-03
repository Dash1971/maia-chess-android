part of '../main.dart';

const gameSoundsPreferenceKey = 'gameSoundsV1';
const gameHapticsPreferenceKey = 'gameHapticsV1';

enum GameFeedbackEvent {
  move,
  capture,
  moveCheck,
  captureCheck,
  invalid,
  gameEnd,
}

enum GameFeedbackSound { move, capture, error, dong }

enum GameFeedbackHaptic { light, medium }

class GameFeedbackPlan {
  const GameFeedbackPlan(this.sound, this.haptic);

  final GameFeedbackSound sound;
  final GameFeedbackHaptic haptic;
}

GameFeedbackPlan gameFeedbackPlan(GameFeedbackEvent event) => switch (event) {
  GameFeedbackEvent.move => const GameFeedbackPlan(
    GameFeedbackSound.move,
    GameFeedbackHaptic.light,
  ),
  GameFeedbackEvent.capture => const GameFeedbackPlan(
    GameFeedbackSound.capture,
    GameFeedbackHaptic.light,
  ),
  GameFeedbackEvent.moveCheck => const GameFeedbackPlan(
    GameFeedbackSound.move,
    GameFeedbackHaptic.medium,
  ),
  GameFeedbackEvent.captureCheck => const GameFeedbackPlan(
    GameFeedbackSound.capture,
    GameFeedbackHaptic.medium,
  ),
  GameFeedbackEvent.invalid => const GameFeedbackPlan(
    GameFeedbackSound.error,
    GameFeedbackHaptic.medium,
  ),
  GameFeedbackEvent.gameEnd => const GameFeedbackPlan(
    GameFeedbackSound.dong,
    GameFeedbackHaptic.medium,
  ),
};

bool shouldEmitPhoneGameFeedback({
  required bool chessnutActive,
  required bool soundsEnabled,
  required bool hapticsEnabled,
}) => !chessnutActive && (soundsEnabled || hapticsEnabled);

GameFeedbackEvent acceptedMoveFeedbackEvent({
  required bool capture,
  required bool check,
}) => switch ((capture, check)) {
  (true, true) => GameFeedbackEvent.captureCheck,
  (true, false) => GameFeedbackEvent.capture,
  (false, true) => GameFeedbackEvent.moveCheck,
  (false, false) => GameFeedbackEvent.move,
};

class GameFeedbackService {
  GameFeedbackService({SoundEffect? soundEffect})
    : _soundEffect = soundEffect ?? SoundEffect();

  static final instance = GameFeedbackService();

  final SoundEffect _soundEffect;
  Future<void>? _initialization;
  bool _soundAvailable = true;

  Future<void> play(
    GameFeedbackEvent event, {
    required bool soundsEnabled,
    required bool hapticsEnabled,
    required bool Function() isCurrent,
  }) async {
    if (!isCurrent()) return;
    final plan = gameFeedbackPlan(event);
    if (soundsEnabled) unawaited(_playSound(plan.sound, isCurrent));
    if (hapticsEnabled) unawaited(_playHaptic(plan.haptic));
  }

  Future<void> _ensureInitialized() async {
    if (_initialization case final initialization?) {
      await initialization;
      return;
    }
    _initialization = _initialize();
    await _initialization!;
  }

  Future<void> _initialize() async {
    try {
      await _soundEffect.initialize(maxStreams: 2);
      await Future.wait(
        GameFeedbackSound.values.map(
          (sound) => _soundEffect.load(
            sound.name,
            'assets/sounds/standard/${sound.name}.mp3',
          ),
        ),
      );
    } catch (_) {
      _soundAvailable = false;
      // Audio is optional. Unsupported platforms continue without feedback.
    }
  }

  Future<void> _playSound(
    GameFeedbackSound sound,
    bool Function() isCurrent,
  ) async {
    if (!_soundAvailable || !isCurrent()) return;
    await _ensureInitialized();
    // Loading may finish after a route/lifecycle/game or preference change.
    if (!_soundAvailable || !isCurrent()) return;
    try {
      await _soundEffect.play(sound.name);
    } catch (error, stackTrace) {
      unawaited(AppDiagnostics.record('game-sound-play', error, stackTrace));
    }
  }

  Future<void> _playHaptic(GameFeedbackHaptic haptic) async {
    try {
      await switch (haptic) {
        GameFeedbackHaptic.light => HapticFeedback.lightImpact(),
        GameFeedbackHaptic.medium => HapticFeedback.mediumImpact(),
      };
    } catch (_) {
      // Haptics are optional. Unsupported devices continue without feedback.
    }
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

void main() {
  test('accepted moves map to Lichess-style sound and haptic events', () {
    expect(
      acceptedMoveFeedbackEvent(capture: false, check: false),
      GameFeedbackEvent.move,
    );
    expect(
      acceptedMoveFeedbackEvent(capture: true, check: false),
      GameFeedbackEvent.capture,
    );
    expect(
      acceptedMoveFeedbackEvent(capture: false, check: true),
      GameFeedbackEvent.moveCheck,
    );
    expect(
      acceptedMoveFeedbackEvent(capture: true, check: true),
      GameFeedbackEvent.captureCheck,
    );

    expect(
      gameFeedbackPlan(GameFeedbackEvent.move).sound,
      GameFeedbackSound.move,
    );
    expect(
      gameFeedbackPlan(GameFeedbackEvent.capture).sound,
      GameFeedbackSound.capture,
    );
    expect(
      gameFeedbackPlan(GameFeedbackEvent.moveCheck).haptic,
      GameFeedbackHaptic.medium,
    );
    expect(
      gameFeedbackPlan(GameFeedbackEvent.captureCheck).haptic,
      GameFeedbackHaptic.medium,
    );
    expect(
      gameFeedbackPlan(GameFeedbackEvent.invalid).sound,
      GameFeedbackSound.error,
    );
    expect(
      gameFeedbackPlan(GameFeedbackEvent.gameEnd).sound,
      GameFeedbackSound.dong,
    );
  });

  test('phone feedback is independently configurable and Chessnut-safe', () {
    expect(
      shouldEmitPhoneGameFeedback(
        chessnutActive: false,
        soundsEnabled: true,
        hapticsEnabled: false,
      ),
      isTrue,
    );
    expect(
      shouldEmitPhoneGameFeedback(
        chessnutActive: false,
        soundsEnabled: false,
        hapticsEnabled: true,
      ),
      isTrue,
    );
    expect(
      shouldEmitPhoneGameFeedback(
        chessnutActive: false,
        soundsEnabled: false,
        hapticsEnabled: false,
      ),
      isFalse,
    );
    expect(
      shouldEmitPhoneGameFeedback(
        chessnutActive: true,
        soundsEnabled: true,
        hapticsEnabled: true,
      ),
      isFalse,
    );
  });
}

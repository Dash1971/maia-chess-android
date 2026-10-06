part of '../main.dart';

/// Total move-time target, including inference. A null initial time is Unlimited.
/// Use the configured time control, never the remaining clock, to select a tier.
Duration sampleHumanMoveTime(
  Random random, {
  required int? baseSeconds,
  required int incrementSeconds,
}) {
  final u1 = max(random.nextDouble(), 0.000001);
  final u2 = random.nextDouble();
  final gaussian = sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  var seconds = exp(0.50 + gaussian * 0.44).clamp(0.55, 4.5);
  if (random.nextDouble() < 0.06) {
    seconds += 1.5 + random.nextDouble() * 3;
  }
  if (baseSeconds == 60 && incrementSeconds == 0) {
    // Include the occasional extra pause before halving and capping the target.
    seconds = min(seconds / 2, 3.0);
  } else if ((baseSeconds == 120 && incrementSeconds == 1) ||
      (baseSeconds == 180 &&
          (incrementSeconds == 0 || incrementSeconds == 2))) {
    seconds = min(seconds * 0.75, 4.5);
  }
  return Duration(milliseconds: (seconds * 1000).round());
}

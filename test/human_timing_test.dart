import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maia_chess/main.dart';

class SequenceRandom implements Random {
  SequenceRandom(this.values);
  final List<double> values;
  int calls = 0;
  @override
  double nextDouble() => values[calls++];
  @override
  bool nextBool() => throw UnsupportedError('Unexpected RNG use');
  @override
  int nextInt(int max) => throw UnsupportedError('Unexpected RNG use');
}

// Frozen pre-#86 formula: protects other controls against distribution drift.
Duration legacyTarget(Random random) {
  final u1 = max(random.nextDouble(), 0.000001);
  final u2 = random.nextDouble();
  final gaussian = sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  var seconds = exp(0.50 + gaussian * 0.44).clamp(0.55, 4.5);
  if (random.nextDouble() < 0.06) {
    seconds += 1.5 + random.nextDouble() * 3;
  }
  return Duration(milliseconds: (seconds * 1000).round());
}

void main() {
  test('1+0 bounds include the rare pause and millisecond rounding', () {
    for (final (draws, expected) in [
      ([0.0, 0.5, 0.5], 275),
      ([0.0, 0.0, 0.06], 2250),
      ([0.0, 0.0, 0.059999, 0.0], 3000),
      ([0.0, 0.0, 0.0, 0.999999999], 3000),
    ]) {
      final random = SequenceRandom(draws);
      expect(
        sampleHumanMoveTime(random, baseSeconds: 60, incrementSeconds: 0),
        Duration(milliseconds: expected),
      );
      expect(random.calls, draws.length);
    }
  });

  for (final (base, increment) in [
    (60, 1),
    (60, 2),
    (300, 0),
    (300, 3),
    (600, 0),
    (600, 5),
    (900, 10),
    (1800, 0),
    (1800, 20),
    (30, 0),
    (120, 0),
    (null, 0),
  ]) {
    test('other control $base+$increment keeps exact legacy samples', () {
      final current = Random(86);
      final legacy = Random(86);
      for (var i = 0; i < 1000; i++) {
        expect(
          sampleHumanMoveTime(
            current,
            baseSeconds: base,
            incrementSeconds: increment,
          ),
          legacyTarget(legacy),
        );
      }
    });
  }

  for (final (base, increment, lower, upper, meanLow, meanHigh) in [
    (60, 0, 275, 3000, 970, 1020),
    (120, 1, 413, 4500, 1450, 1530),
    (180, 0, 413, 4500, 1450, 1530),
    (180, 2, 413, 4500, 1450, 1530),
  ]) {
    test(
      'seeded $base+$increment distribution has the intended mean and cap',
      () {
        final random = Random(86);
        var total = 0;
        var capped = 0;
        const count = 50000;
        for (var i = 0; i < count; i++) {
          final millis = sampleHumanMoveTime(
            random,
            baseSeconds: base,
            incrementSeconds: increment,
          ).inMilliseconds;
          expect(millis, inInclusiveRange(lower, upper));
          total += millis;
          if (millis == upper) capped++;
        }
        expect(total / count, inInclusiveRange(meanLow, meanHigh));
        expect(capped, greaterThan(0));
      },
    );
  }

  test('middle tier caps after the rare pause and rounds its lower bound', () {
    expect(
      sampleHumanMoveTime(
        SequenceRandom([0, 0.5, 0.5]),
        baseSeconds: 120,
        incrementSeconds: 1,
      ),
      const Duration(milliseconds: 413),
    );
    expect(
      sampleHumanMoveTime(
        SequenceRandom([0, 0, 0, 0.999999999]),
        baseSeconds: 180,
        incrementSeconds: 0,
      ),
      const Duration(milliseconds: 4500),
    );
  });
}

part of '../main.dart';

enum PlayerSide { white, black, random }

enum TimePreset {
  unlimited,
  bullet,
  blitz,
  blitzFive,
  rapid,
  classical,
  custom,
}

extension TimePresetDetails on TimePreset {
  String get label => switch (this) {
    TimePreset.unlimited => 'Unlimited',
    TimePreset.bullet => '1 + 0',
    TimePreset.blitz => '3 + 2',
    TimePreset.blitzFive => '5 + 3',
    TimePreset.rapid => '10 + 0',
    TimePreset.classical => '15 + 10',
    TimePreset.custom => 'Custom',
  };

  int get minutes => switch (this) {
    TimePreset.bullet => 1,
    TimePreset.blitz => 3,
    TimePreset.blitzFive => 5,
    TimePreset.rapid => 10,
    TimePreset.classical => 15,
    _ => 0,
  };

  int get increment => switch (this) {
    TimePreset.blitz => 2,
    TimePreset.blitzFive => 3,
    TimePreset.classical => 10,
    _ => 0,
  };
}

class ClockSnapshot {
  const ClockSnapshot(this.whiteMillis, this.blackMillis);

  final int whiteMillis;
  final int blackMillis;
}

class RecordedVariation {
  const RecordedVariation({
    required this.basePly,
    required this.baseFen,
    required this.sanMoves,
    this.children = const [],
    this.annotations = const [],
  });

  final int basePly;
  final String baseFen;
  final List<String> sanMoves;
  final List<RecordedVariation> children;
  final List<Map<String, dynamic>> annotations;

  Map<String, Object> toJson() => {
    'basePly': basePly,
    'baseFen': baseFen,
    'sanMoves': sanMoves,
    'children': children.map((item) => item.toJson()).toList(),
    'annotations': annotations,
  };

  factory RecordedVariation.fromJson(Map<String, dynamic> json) =>
      RecordedVariation(
        annotations: (json['annotations'] as List? ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList(),
        basePly: json['basePly'] as int,
        baseFen: json['baseFen'] as String,
        sanMoves: (json['sanMoves'] as List).cast<String>(),
        children: (json['children'] as List? ?? const [])
            .map(
              (item) => RecordedVariation.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(growable: false),
      );
}

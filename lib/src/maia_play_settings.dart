part of '../main.dart';

/// Frozen per game. The opening override never writes back to preferences.
class MaiaPlaySettings {
  const MaiaPlaySettings({
    this.temperature = 1.0,
    this.topP = 1.0,
    this.maxOpeningVariety = false,
  });

  final double temperature;
  final double topP;
  final bool maxOpeningVariety;

  Map<String, Object> toJson() => {
    'version': 1,
    'temperature': temperature,
    'topP': topP,
    'maxOpeningVariety': maxOpeningVariety,
  };

  /// Old saves retain their previous fixed-setting behavior; never opt them in.
  static MaiaPlaySettings restore(
    Object? value, {
    required double fallbackTemperature,
    required double fallbackTopP,
  }) {
    bool valid(Object? n) => n is num && n.isFinite && n >= 0 && n <= 1;
    if (value is Map &&
        value['version'] == 1 &&
        valid(value['temperature']) &&
        valid(value['topP']) &&
        value['maxOpeningVariety'] is bool) {
      return MaiaPlaySettings(
        temperature: (value['temperature'] as num).toDouble(),
        topP: (value['topP'] as num).toDouble(),
        maxOpeningVariety: value['maxOpeningVariety'] == true,
      );
    }
    return MaiaPlaySettings(
      temperature: fallbackTemperature,
      topP: fallbackTopP,
    );
  }

  ({double temperature, double topP, bool opening, int moveNumber}) forFen(
    String fen,
  ) {
    // Game positions are validated FEN. Missing/invalid move numbers must not
    // accidentally enable the opening phase for a later position.
    final fields = fen.split(' ');
    final number = fields.length == 6 ? int.tryParse(fields.last) : null;
    final opening =
        maxOpeningVariety && number != null && number >= 1 && number <= 5;
    return (
      temperature: opening ? 1.0 : temperature,
      topP: opening ? 1.0 : topP,
      opening: opening,
      moveNumber: number ?? 0,
    );
  }
}

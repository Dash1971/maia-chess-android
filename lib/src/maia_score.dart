part of '../main.dart';

/// Maia-3 channels are Loss/Draw/Win for the side to move. Match the upstream
/// website's expected-score convention, not a centipawn conversion or P(win).
@immutable
class MaiaOutcome {
  const MaiaOutcome._(this.loss, this.draw, this.win);
  final double loss, draw, win;
  static MaiaOutcome? fromLogits(List<double> logits) {
    if (logits.length != 3 || logits.any((v) => !v.isFinite)) return null;
    final largest = logits.reduce(max);
    final values = logits.map((v) => exp(v - largest)).toList();
    final sum = values.reduce((a, b) => a + b);
    return MaiaOutcome._(values[0] / sum, values[1] / sum, values[2] / sum);
  }

  double whiteScore(String fen) {
    final fields = fen.split(RegExp(r'\s+'));
    if (fields.length < 2 || !['w', 'b'].contains(fields[1])) {
      throw const FormatException('Missing side to move');
    }
    final score = win + .5 * draw;
    return fields[1] == 'w' ? score : 1 - score;
  }
}

@immutable
class MaiaInferenceResult {
  const MaiaInferenceResult(this.moveLogits, {this.outcome});
  final Float32List moveLogits;
  final MaiaOutcome? outcome;
  static MaiaInferenceResult? decode(Object? value) {
    // Legacy/injected move-only responses remain usable, with no invented score.
    final moves = value is Map ? value['move_logits'] : value;
    if (moves is! Float32List ||
        moves.length != 4352 ||
        moves.any((v) => !v.isFinite)) {
      return null;
    }
    final outcome = value is Map ? value['value_logits'] : null;
    return MaiaInferenceResult(
      moves,
      outcome: outcome is Float32List ? MaiaOutcome.fromLogits(outcome) : null,
    );
  }
}

const maiaScorePreferenceKey = 'maiaScoreVisibleV1';

class MaiaScoreController extends ChangeNotifier {
  bool enabled = false, persistenceFailed = false, _disposed = false;
  int _revision = 0;
  Future<void> _tail = Future<void>.value();
  Future<void> initialize() async {
    final revision = _revision;
    try {
      final value = (await SharedPreferences.getInstance()).get(
        maiaScorePreferenceKey,
      );
      if (!_disposed && revision == _revision) {
        enabled = value == true;
        notifyListeners();
      }
    } catch (error, stack) {
      _failure(revision, error, stack);
    }
  }

  static Future<void> writePreference(bool value) async {
    if (!await (await SharedPreferences.getInstance()).setBool(
      maiaScorePreferenceKey,
      value,
    )) {
      throw StateError('Maia score preference write failed');
    }
  }

  Future<void> select(bool value) {
    if (_disposed) return Future<void>.value();
    final revision = ++_revision;
    enabled = value;
    persistenceFailed = false;
    notifyListeners();
    return _tail = _tail.then((_) async {
      try {
        await writePreference(value);
        if (!_disposed && revision == _revision) {
          persistenceFailed = false;
          notifyListeners();
        }
      } catch (error, stack) {
        _failure(revision, error, stack);
      }
    });
  }

  void _failure(int revision, Object error, StackTrace stack) {
    unawaited(AppDiagnostics.record('maia-score-preference', error, stack));
    if (!_disposed && revision == _revision) {
      persistenceFailed = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class MaiaScoreScope extends InheritedNotifier<MaiaScoreController> {
  const MaiaScoreScope({
    required MaiaScoreController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);
  static MaiaScoreController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MaiaScoreScope>()?.notifier;
}

class MaiaScoreSetting extends StatelessWidget {
  const MaiaScoreSetting({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = MaiaScoreScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsInfoSwitch(
          key: const ValueKey('show-maia-score'),
          title: l10n(context).showMaiaScore,
          value: controller.enabled,
          helpKey: const ValueKey('maia-score-help'),
          onChanged: (value) => unawaited(controller.select(value)),
          onHelp: () => showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              scrollable: true,
              title: Text(l10n(context).showMaiaScore),
              content: const MaiaScoreHelpContent(),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n(context).close),
                ),
              ],
            ),
          ),
        ),
        if (controller.persistenceFailed)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Semantics(
              liveRegion: true,
              child: Text(l10n(context).maiaScorePreferenceError),
            ),
          ),
      ],
    );
  }
}

const maiaScoreResearchUrl =
    'https://github.com/Dash1971/mobile-maia-research/blob/'
    'main/studies/score-reliability-2026-10-27/REPORT.md';

/// Shared by Settings and the analysis score details; opens research only on tap.
class MaiaScoreHelpContent extends StatelessWidget {
  const MaiaScoreHelpContent({this.scores, super.key});

  final String? scores;

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          [
            ?scores,
            strings.maiaScoreHelp,
            strings.maiaScoreExpectedHelp,
            strings.maiaScoreInputsHelp,
            strings.maiaScoreStockfishHelp,
          ].join('\n\n'),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          key: const ValueKey('maia-score-research-link'),
          onPressed: () => maiaEngineChannel.invokeMethod<void>('openUrl', {
            'url': maiaScoreResearchUrl,
          }),
          icon: const Icon(Icons.open_in_new),
          label: Text(strings.maiaScoreResearchLink),
        ),
      ],
    );
  }
}

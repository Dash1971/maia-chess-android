part of '../main.dart';

/// Informational guidance, not a strength guarantee. No inference is run here.
List<String> samplingSettingsNotices(
  AppLocalizations strings, {
  required double temperature,
  required double topP,
  required bool openingVariety,
}) => [
  if (temperature == 1.0 && topP == 1.0) strings.samplingFullVarietyNotice,
  if (temperature == 0.0 || topP == 0.0)
    strings.samplingArgmaxNotice
  else if (temperature < defaultMaiaTemperature || topP < defaultMaiaTopP)
    strings.samplingLowerNotice,
  if (!openingVariety && (temperature < 1.0 || topP < 1.0))
    strings.samplingRecommendationWarning,
];

const samplingGuideUrl =
    'https://github.com/Dash1971/mobile-maia-research/blob/'
    'main/guides/choosing-maia-settings/README.md';

/// A single scrollable explanation; opening help never changes preferences.
class SamplingHelpDialog extends StatelessWidget {
  const SamplingHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    final paragraphs = [
      strings.samplingHelpIntro,
      strings.samplingHelpVariety,
      strings.samplingHelpDefaults,
      strings.samplingHelpStrength,
      strings.samplingHelpArgmax,
      strings.samplingHelpTopP,
    ];
    return AlertDialog(
      scrollable: true,
      title: Text(strings.samplingTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final paragraph in paragraphs) ...[
              Text(paragraph),
              const SizedBox(height: 14),
            ],
            Text(strings.samplingHelpResearchIntro),
            TextButton.icon(
              key: const ValueKey('sampling-research-link'),
              onPressed: () => maiaEngineChannel.invokeMethod<void>('openUrl', {
                'url': samplingGuideUrl,
              }),
              icon: const Icon(Icons.open_in_new),
              label: Text(strings.samplingResearchLink),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.close),
        ),
      ],
    );
  }
}

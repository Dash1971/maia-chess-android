part of '../main.dart';

class SamplingCaptureSettings extends StatefulWidget {
  const SamplingCaptureSettings({super.key});
  @override
  State<SamplingCaptureSettings> createState() =>
      _SamplingCaptureSettingsState();
}

class _SamplingCaptureSettingsState extends State<SamplingCaptureSettings> {
  final capture = SamplingCapture.instance;
  bool _working = false;
  bool _choosing = false;

  @override
  void initState() {
    super.initState();
    unawaited(capture.loadStoredData());
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await operation();
      if (capture.failed) throw StateError('Capture storage failed');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n(context).samplingDataError)),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _action(String action) async {
    if (_working || _choosing || capture.busy) return;
    setState(() => _choosing = true);
    try {
      final share = action == 'share';
      final readable = await chooseSamplingFormat(context, share: share);
      if (!mounted || readable == null || capture.busy) return;
      final s = l10n(context);
      final text = samplingReportText(s);
      await _run(() async {
        final images = readable
            ? await samplingPieceImages()
            : <String, String>{};
        await capture.saveDocument(
          share: share,
          readable: readable,
          text: text,
          locale: s.localeName,
          pieceImages: images,
        );
      });
    } finally {
      if (mounted) setState(() => _choosing = false);
    }
  }

  Future<void> _confirmClear() async {
    if (_working || _choosing || capture.busy) return;
    setState(() => _choosing = true);
    try {
      final strings = l10n(context);
      var answered = false;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          void answer(bool value) {
            if (answered || ModalRoute.of(dialogContext)?.isCurrent != true) {
              return;
            }
            answered = true;
            Navigator.of(dialogContext).pop(value);
          }

          return ListenableBuilder(
            listenable: capture,
            builder: (context, _) => AlertDialog(
              title: Text(strings.clearSamplingData),
              scrollable: true,
              content: Text(strings.samplingClearConfirmation),
              actions: [
                TextButton(
                  onPressed: () => answer(false),
                  child: Text(strings.cancel),
                ),
                TextButton(
                  key: const ValueKey('confirm-clear-sampling-data'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: capture.busy ? null : () => answer(true),
                  child: Text(strings.samplingDeleteData),
                ),
              ],
            ),
          );
        },
      );
      // Another storage operation or navigation may have happened while open.
      if (!mounted || confirmed != true || capture.busy) return;
      await _run(capture.clear);
    } finally {
      if (mounted) setState(() => _choosing = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: capture,
    builder: (context, _) {
      final strings = l10n(context);
      final blocked = _working || _choosing || capture.busy;
      return Column(
        children: [
          SettingsInfoSwitch(
            key: const ValueKey('sampling-data-toggle'),
            title: strings.saveMaiaSamplingData,
            onHelp: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(strings.saveMaiaSamplingData),
                scrollable: true,
                content: Text(strings.samplingDataHelp),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(strings.close),
                  ),
                ],
              ),
            ),
            value: capture.enabled,
            onChanged: blocked
                ? null
                : (value) => _run(() => capture.setEnabled(value)),
          ),
          if (capture.enabled || capture.records > 0 || capture.failed) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.samplingData,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          capture.failed
                              ? strings.samplingDataError
                              : strings.samplingDataStatus(capture.records),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    key: const ValueKey('sampling-actions'),
                    enabled: !blocked && capture.records > 0,
                    position: PopupMenuPosition.under,
                    tooltip: strings.shareAndExport,
                    onSelected: _action,
                    icon: _working || capture.busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.more_vert),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'save',
                        child: Text(strings.samplingSave),
                      ),
                      PopupMenuItem(
                        value: 'share',
                        child: Text(strings.samplingShare),
                      ),
                    ],
                  ),
                  IconButton(
                    key: const ValueKey('clear-sampling-data'),
                    tooltip: strings.clearSamplingData,
                    icon: const Icon(Icons.delete_outline),
                    onPressed:
                        blocked || (capture.records == 0 && !capture.failed)
                        ? null
                        : _confirmClear,
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
}

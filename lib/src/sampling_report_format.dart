part of '../main.dart';

/// Save/Share format choice. Readable is always the initial choice.
Future<bool?> chooseSamplingFormat(
  BuildContext context, {
  required bool share,
}) {
  final s = l10n(context);
  var readable = true;
  return showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(share ? s.samplingShare : s.samplingSave),
        content: SingleChildScrollView(
          child: RadioGroup<bool>(
            groupValue: readable,
            onChanged: (value) => setState(() => readable = value!),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<bool>(
                  contentPadding: EdgeInsets.zero,
                  value: true,
                  title: Text(s.samplingReadable),
                  subtitle: Text(s.samplingReadableHint),
                ),
                RadioListTile<bool>(
                  contentPadding: EdgeInsets.zero,
                  value: false,
                  title: Text(s.samplingResearch),
                  subtitle: Text(s.samplingResearchHint),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, readable),
            child: Text(share ? s.samplingShare : s.samplingSave),
          ),
        ],
      ),
    ),
  );
}

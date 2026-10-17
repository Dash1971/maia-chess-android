part of '../main.dart';

/// Unlike SwitchListTile's merged semantics, help is an independent action.
class SettingsInfoSwitch extends StatelessWidget {
  const SettingsInfoSwitch({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.onHelp,
    this.helpKey,
  });

  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final VoidCallback onHelp;
  final Key? helpKey;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    child: Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 24, 4),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: ExcludeSemantics(
                    child: InkWell(
                      canRequestFocus: false,
                      onTap: onChanged == null
                          ? null
                          : () => onChanged!(!value),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          widthFactor: 1,
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: onChanged == null
                                      ? Theme.of(context).disabledColor
                                      : null,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Semantics(
                  sortKey: const OrdinalSortKey(1),
                  child: IconButton(
                    key: helpKey,
                    tooltip: title,
                    onPressed: onHelp,
                    icon: const Icon(Icons.info_outline),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Semantics(
            sortKey: const OrdinalSortKey(0),
            label: title,
            child: Switch(value: value, onChanged: onChanged),
          ),
        ],
      ),
    ),
  );
}

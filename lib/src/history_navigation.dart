part of '../main.dart';

/// A shared move-history navigator for live play and analysis.
///
/// The two large controls step through moves. Long-pressing them jumps to the
/// beginning or end without adding duplicate first/last buttons to the UI.
class MoveHistoryNavigator extends StatelessWidget {
  const MoveHistoryNavigator({
    required this.previousKey,
    required this.nextKey,
    required this.canGoBack,
    required this.canGoForward,
    required this.onFirst,
    required this.onPrevious,
    required this.onNext,
    required this.onLast,
    this.headerActions = const [],
    this.headerActionWidth = 48,
    this.previousTooltip,
    this.nextTooltip,
    this.startTooltip,
    this.endTooltip,
    super.key,
  });

  final Key previousKey;
  final Key nextKey;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onFirst;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onLast;
  final List<Widget> headerActions;
  final double headerActionWidth;
  final String? previousTooltip;
  final String? nextTooltip;
  final String? startTooltip;
  final String? endTooltip;

  Widget _button(
    BuildContext context, {
    required Key key,
    required String tooltip,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
    required String longPressDestination,
    required BorderRadius borderRadius,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: Tooltip(
        enableFeedback: false,
        message: tooltip,
        child: Semantics(
          button: true,
          enabled: enabled,
          label: tooltip,
          hint: l10n(context).holdForDestination(longPressDestination),
          onTap: enabled ? onTap : null,
          onLongPress: enabled ? onLongPress : null,
          child: ExcludeSemantics(
            child: InkWell(
              enableFeedback: false,
              key: key,
              borderRadius: borderRadius,
              onTap: enabled ? onTap : null,
              onLongPress: enabled ? onLongPress : null,
              child: SizedBox(
                height: 56,
                child: Icon(
                  icon,
                  size: 30,
                  color: enabled
                      ? colors.onSurfaceVariant
                      : colors.onSurface.withValues(alpha: 0.26),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navigationStrip(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const radius = Radius.circular(14);
    return Material(
      color: colors.surfaceContainer,
      borderRadius: const BorderRadius.all(radius),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            _button(
              context,
              key: previousKey,
              tooltip: previousTooltip ?? l10n(context).previousMove,
              icon: CupertinoIcons.chevron_back,
              enabled: canGoBack,
              onTap: onPrevious,
              onLongPress: onFirst,
              longPressDestination: startTooltip ?? l10n(context).beginning,
              borderRadius: const BorderRadius.horizontal(left: radius),
            ),
            SizedBox(
              width: 1,
              height: 28,
              child: ColoredBox(color: colors.outlineVariant),
            ),
            _button(
              context,
              key: nextKey,
              tooltip: nextTooltip ?? l10n(context).nextMove,
              icon: CupertinoIcons.chevron_forward,
              enabled: canGoForward,
              onTap: onNext,
              onLongPress: onLast,
              longPressDestination: endTooltip ?? l10n(context).latestPosition,
              borderRadius: const BorderRadius.horizontal(right: radius),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final navigation = _navigationStrip(context);
      if (headerActions.isEmpty) return navigation;

      const minimumNavigationWidth = 144.0;
      const gap = 8.0;
      final actionsWidth = headerActionWidth * headerActions.length;
      final canFitInline =
          constraints.maxWidth >= actionsWidth + minimumNavigationWidth + gap;
      if (canFitInline) {
        return SizedBox(
          height: 56,
          child: Row(
            children: [
              ...headerActions.map(
                (action) => SizedBox(
                  width: headerActionWidth,
                  child: Center(child: action),
                ),
              ),
              const SizedBox(width: gap),
              Expanded(child: navigation),
            ],
          ),
        );
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 48,
            child: Row(
              children: headerActions
                  .map((action) => Expanded(child: Center(child: action)))
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 4),
          navigation,
        ],
      );
    },
  );
}

part of '../main.dart';

bool _useAdaptiveColumns(Size size) =>
    size.width >= 1000 ||
    (size.width >= 720 && size.width >= size.height * 1.5);

double _sidebarMinimum(BuildContext context) =>
    260 +
    60 * (MediaQuery.textScalerOf(context).scale(16) / 16 - 1).clamp(0, 2);

bool _useBoardSidebar(BuildContext context) {
  final media = MediaQuery.of(context);
  final size = media.size;
  return size.width > size.height &&
      size.height - media.padding.vertical >= 160 &&
      size.width - media.padding.horizontal >= _sidebarMinimum(context) + 200;
}

/// Metadata for the existing settings sections. Portrait builds the same cards;
/// wide windows put their labels beside one independently scrollable section.
class AdaptiveSettingsSection extends StatelessWidget {
  const AdaptiveSettingsSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}

class AdaptiveSettingsView extends StatefulWidget {
  const AdaptiveSettingsView({super.key, required this.children});
  final List<Widget> children;
  @override
  State<AdaptiveSettingsView> createState() => _AdaptiveSettingsViewState();
}

class _AdaptiveSettingsViewState extends State<AdaptiveSettingsView> {
  IconData? _selected;
  final _detailScroll = ScrollController();

  @override
  void dispose() {
    _detailScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = _useAdaptiveColumns(MediaQuery.sizeOf(context));
      if (!wide || constraints.maxWidth < 650) {
        return SingleChildScrollView(
          key: const ValueKey('settings-scroll-view'),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.children,
              ),
            ),
          ),
        );
      }
      final sections = widget.children
          .whereType<AdaptiveSettingsSection>()
          .toList();
      final selected = sections.indexWhere((s) => s.icon == _selected);
      final initial = sections.indexWhere(
        (s) => s.icon == Icons.palette_outlined,
      );
      final index = selected >= 0 ? selected : (initial >= 0 ? initial : 0);
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              key: const ValueKey('adaptive-settings'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: (constraints.maxWidth * .25).clamp(180, 240),
                  child: ListView(
                    key: const ValueKey('settings-categories'),
                    children: [
                      for (var i = 0; i < sections.length; i++)
                        ListTile(
                          key: ValueKey(
                            'settings-category-${sections[i].icon.codePoint}',
                          ),
                          selected: i == index,
                          selectedTileColor: Theme.of(context)
                              .colorScheme
                              .secondaryContainer,
                          leading: Icon(sections[i].icon),
                          title: Text(sections[i].title),
                          onTap: () {
                            setState(() => _selected = sections[i].icon);
                            if (_detailScroll.hasClients) {
                              _detailScroll.jumpTo(0);
                            }
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    key: const ValueKey('settings-scroll-view'),
                    controller: _detailScroll,
                    child: KeyedSubtree(
                      key: ValueKey(sections[index].icon.codePoint),
                      child: sections[index].child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

part of '../main.dart';

const appAppearancePreferenceKey = 'appAppearanceV1';

typedef AppDynamicColors = ({ColorScheme light, ColorScheme dark});

@immutable
class AppAppearance {
  const AppAppearance({
    this.mode = ThemeMode.dark,
    this.systemColors = false,
    this.pureBlack = false,
  });

  final ThemeMode mode;
  final bool systemColors;
  final bool pureBlack;

  factory AppAppearance.decode(Object? value) {
    try {
      final data = value is String ? jsonDecode(value) : null;
      if (data is! Map) return const AppAppearance();
      return AppAppearance(
        mode:
            ThemeMode.values.where((m) => m.name == data['mode']).firstOrNull ??
            ThemeMode.dark,
        systemColors: data['systemColors'] == true,
        pureBlack: data['pureBlack'] == true,
      );
    } on FormatException {
      return const AppAppearance();
    }
  }

  String encode() => jsonEncode({
    'mode': mode.name,
    'systemColors': systemColors,
    'pureBlack': pureBlack,
  });

  AppAppearance copyWith({
    ThemeMode? mode,
    bool? systemColors,
    bool? pureBlack,
  }) => AppAppearance(
    mode: mode ?? this.mode,
    systemColors: systemColors ?? this.systemColors,
    pureBlack: pureBlack ?? this.pureBlack,
  );
}

/// One small preference, serialized writes, and no session/engine dependencies.
/// Stale disk or platform replies cannot replace a newer user choice/palette.
class AppAppearanceController extends ChangeNotifier {
  AppAppearanceController({
    Future<Object?> Function()? read,
    Future<void> Function(String)? write,
    Future<AppDynamicColors?> Function()? readColors,
  }) : _read = read ?? _readPreference,
       _write = write ?? _writePreference,
       _readColors = readColors ?? _readSystemColors;

  final Future<Object?> Function() _read;
  final Future<void> Function(String) _write;
  final Future<AppDynamicColors?> Function() _readColors;
  AppAppearance value = const AppAppearance();
  AppDynamicColors? dynamicColors;
  bool persistenceFailed = false;
  bool _disposed = false;
  int _revision = 0;
  int _paletteRevision = 0;
  Future<void> _pendingWrite = Future<void>.value();

  static Future<Object?> _readPreference() async =>
      (await SharedPreferences.getInstance()).get(appAppearancePreferenceKey);

  static Future<void> _writePreference(String value) async {
    if (!await (await SharedPreferences.getInstance()).setString(
      appAppearancePreferenceKey,
      value,
    )) {
      throw StateError('Appearance preference write failed');
    }
  }

  static Future<AppDynamicColors?> _readSystemColors() async {
    final palette = await DynamicColorPlugin.getCorePalette();
    return palette == null
        ? null
        : (
            light: palette.toColorScheme(),
            dark: palette.toColorScheme(brightness: Brightness.dark),
          );
  }

  Future<void> initialize() async {
    final revision = _revision;
    final colors = refreshColors();
    try {
      final stored = await _read();
      if (!_disposed && revision == _revision) {
        value = AppAppearance.decode(stored);
        _notify();
      }
    } catch (error, stack) {
      _failure(revision, error, stack);
    }
    await colors;
  }

  Future<void> refreshColors() async {
    if (_disposed) return;
    final revision = ++_paletteRevision;
    AppDynamicColors? colors;
    try {
      colors = await _readColors();
    } catch (_) {
      // Missing plugins, older Android versions and vendor failures all use
      // the fixed palette. No network, permission request or blocking dialog.
    }
    if (_disposed || revision != _paletteRevision) return;
    dynamicColors = colors;
    _notify();
  }

  Future<void> select(AppAppearance next) {
    if (_disposed) return Future<void>.value();
    final revision = ++_revision;
    value = next;
    persistenceFailed = false;
    _notify();
    return _pendingWrite = _pendingWrite.then((_) async {
      try {
        await _write(next.encode());
        if (!_disposed && revision == _revision) {
          persistenceFailed = false;
          _notify();
        }
      } catch (error, stack) {
        _failure(revision, error, stack);
      }
    });
  }

  void _failure(int revision, Object error, StackTrace stack) {
    unawaited(AppDiagnostics.record('appearance-preference', error, stack));
    if (!_disposed && revision == _revision) {
      persistenceFailed = true;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Defaults deliberately reproduce the pre-appearance-settings ThemeData.
ThemeData appTheme(
  AppAppearance appearance,
  Brightness brightness, {
  AppDynamicColors? dynamicColors,
}) {
  final dark = brightness == Brightness.dark;
  var colors = appearance.systemColors && dynamicColors != null
      ? (dark ? dynamicColors.dark : dynamicColors.light)
      : ColorScheme.fromSeed(
          seedColor: const Color(0xff5d735f),
          brightness: brightness,
        );
  final black = dark && appearance.pureBlack;
  if (black) {
    colors = colors.copyWith(
      surface: Colors.black,
      surfaceDim: Colors.black,
      surfaceContainerLowest: Colors.black,
      surfaceContainerLow: const Color(0xff080808),
      surfaceContainer: const Color(0xff101010),
      surfaceContainerHigh: const Color(0xff171717),
      surfaceContainerHighest: const Color(0xff202020),
    );
  }
  return ThemeData(
    useMaterial3: true,
    colorScheme: colors,
    scaffoldBackgroundColor: black
        ? Colors.black
        : dark && !(appearance.systemColors && dynamicColors != null)
        ? const Color(0xff171a18)
        : colors.surface,
    appBarTheme: black
        ? const AppBarTheme(
            backgroundColor: Colors.black,
            surfaceTintColor: Colors.transparent,
          )
        : null,
  );
}

class AppAppearanceSettings extends InheritedNotifier<AppAppearanceController> {
  const AppAppearanceSettings({
    required AppAppearanceController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppAppearanceController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<AppAppearanceSettings>()
      ?.notifier;
}

class AppearanceSettingsSection extends StatelessWidget {
  const AppearanceSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppAppearanceSettings.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();
    final value = controller.value;
    final strings = l10n(context);
    return Card(
      key: const ValueKey('appearance-settings-section'),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Semantics(
              header: true,
              child: Text(
                strings.appearance,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: DropdownButtonFormField<ThemeMode>(
              key: ValueKey('appearance-mode-${value.mode.name}'),
              initialValue: value.mode,
              isExpanded: true,
              itemHeight: null,
              isDense: false,
              decoration: InputDecoration(
                labelText: strings.appearanceTheme,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(strings.appearanceSystemDefault),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(strings.appearanceLight),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(strings.appearanceDark),
                ),
              ],
              onChanged: (mode) {
                if (mode != null) {
                  unawaited(controller.select(value.copyWith(mode: mode)));
                }
              },
            ),
          ),
          SwitchListTile(
            key: const ValueKey('appearance-system-colors'),
            title: Text(strings.appearanceSystemColors),
            subtitle: Text(
              controller.dynamicColors == null
                  ? strings.appearanceSystemColorsUnavailable
                  : strings.appearanceSystemColorsHelp,
            ),
            value: value.systemColors,
            onChanged: controller.dynamicColors == null
                ? null
                : (enabled) => unawaited(
                    controller.select(value.copyWith(systemColors: enabled)),
                  ),
          ),
          SwitchListTile(
            key: const ValueKey('appearance-pure-black'),
            title: Text(strings.appearancePureBlack),
            subtitle: Text(strings.appearancePureBlackHelp),
            value: value.pureBlack,
            onChanged: (enabled) => unawaited(
              controller.select(value.copyWith(pureBlack: enabled)),
            ),
          ),
          if (controller.persistenceFailed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Semantics(
                liveRegion: true,
                child: Text(strings.appearancePreferenceError),
              ),
            ),
        ],
      ),
    );
  }
}

/// Keep semantic hues independent of wallpaper colors. Darken light-theme
/// text just enough for readable small labels on light surfaces.
Color chessTextColor(BuildContext context, Color color) =>
    Theme.of(context).brightness == Brightness.dark
    ? color
    : Color.lerp(color, Colors.black, 0.48)!;

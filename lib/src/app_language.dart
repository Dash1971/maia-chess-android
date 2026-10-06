part of '../main.dart';

const appLanguagePreferenceKey = 'appLanguageV1';

/// Native names shown in the language picker. Keep the stored codes stable;
/// sort the display names at presentation time, as in Lichess.
const appLanguageNativeNames = <String, String>{
  'en': 'English',
  'de': 'Deutsch',
  'fr': 'Français',
  'ru': 'Русский',
  'pt': 'Português (Brasil)',
  'hi': 'हिन्दी',
  'ja': '日本語',
  'zh': '简体中文',
  'ko': '한국어',
  'es': 'Español',
};

List<MapEntry<String, String>> sortedAppLanguageChoices() =>
    appLanguageNativeNames.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

/// Catalog IDs are also the persisted choices. Never persist translated names.
bool isSupportedAppLanguage(Object? code) =>
    code is String &&
    AppLocalizations.supportedLocales.any(
      (locale) => locale.languageCode == code,
    );

/// Only Simplified Chinese is supplied. Do not silently substitute it for a
/// Traditional-Chinese system preference; try the next preferred language.
/// Explicitly selecting 简体中文 still works on every device.
Locale resolveAppLocale(List<Locale>? preferred, Iterable<Locale> supported) {
  for (final requested in preferred ?? const <Locale>[]) {
    if (requested.languageCode == 'zh') {
      final traditional =
          requested.scriptCode == 'Hant' ||
          (requested.scriptCode != 'Hans' &&
              const {'TW', 'HK', 'MO'}.contains(requested.countryCode));
      if (traditional) continue;
    }
    for (final available in supported) {
      if (available.languageCode == requested.languageCode) return available;
    }
  }
  return const Locale('en');
}

/// Tests and embedders may build a page without the app's delegates. Production
/// uses generated catalogs; this fallback never performs an English-text lookup.
AppLocalizations l10n(BuildContext context) =>
    AppLocalizations.of(context) ?? lookupAppLocalizations(const Locale('en'));

String displayNumber(BuildContext context, num value, {int? decimalDigits}) {
  final format = NumberFormat.decimalPattern(l10n(context).localeName);
  // Chess ratings, move numbers and clocks conventionally omit grouping.
  format.turnOffGrouping();
  if (decimalDigits != null) {
    format.minimumFractionDigits = decimalDigits;
    format.maximumFractionDigits = decimalDigits;
  }
  return format.format(value);
}

/// Serializes preference writes and prevents a slow initial read from replacing
/// a language the user has already selected. Storage failures never escape into
/// the UI error handler or touch saved games.
class AppLanguageController extends ChangeNotifier {
  AppLanguageController({
    Future<Object?> Function()? read,
    Future<void> Function(String?)? write,
  }) : _read = read ?? _readPreference,
       _write = write ?? _writePreference;

  final Future<Object?> Function() _read;
  final Future<void> Function(String?) _write;
  String? selectedCode;
  bool persistenceFailed = false;
  int _revision = 0;
  bool _disposed = false;
  Future<void> _pendingWrite = Future<void>.value();

  static Future<Object?> _readPreference() async =>
      (await SharedPreferences.getInstance()).get(appLanguagePreferenceKey);

  static Future<void> _writePreference(String? code) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = code == null
        ? await preferences.remove(appLanguagePreferenceKey)
        : await preferences.setString(appLanguagePreferenceKey, code);
    if (!saved) throw StateError('Language preference write failed');
  }

  Future<void> initialize() async {
    final revision = _revision;
    try {
      final stored = await _read();
      if (_disposed || revision != _revision) return;
      selectedCode = isSupportedAppLanguage(stored) ? stored as String : null;
      _notify();
      if (stored != null && selectedCode == null) {
        await _enqueueWrite(null, revision);
      }
    } catch (error, stack) {
      _failure(revision, error, stack);
    }
  }

  Future<void> select(String? code) {
    if (_disposed || (code != null && !isSupportedAppLanguage(code))) {
      return Future<void>.value();
    }
    final revision = ++_revision;
    selectedCode = code;
    persistenceFailed = false;
    _notify();
    return _enqueueWrite(code, revision);
  }

  Future<void> _enqueueWrite(String? code, int revision) {
    return _pendingWrite = _pendingWrite.then((_) async {
      try {
        await _write(code);
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
    unawaited(AppDiagnostics.record('language-preference', error, stack));
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

class AppLanguageSettings extends InheritedWidget {
  const AppLanguageSettings({
    required this.selectedCode,
    required this.onChanged,
    this.persistenceFailed = false,
    required super.child,
    super.key,
  });

  final String? selectedCode;
  final ValueChanged<String?> onChanged;
  final bool persistenceFailed;

  static AppLanguageSettings? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLanguageSettings>();

  @override
  bool updateShouldNotify(AppLanguageSettings oldWidget) =>
      selectedCode != oldWidget.selectedCode ||
      persistenceFailed != oldWidget.persistenceFailed ||
      onChanged != oldWidget.onChanged;
}

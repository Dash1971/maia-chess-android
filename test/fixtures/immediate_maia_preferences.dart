import 'package:shared_preferences/shared_preferences.dart';

/// Game/state regressions advance immediately after an injected Maia reply.
/// Give those scenarios an explicit timing choice, independent of app defaults.
/// Caller-specified values still win; default/timing tests seed prefs directly.
void setImmediateMaiaPreferences(Map<String, Object> values) {
  SharedPreferences.setMockInitialValues({'humanTiming': false, ...values});
}

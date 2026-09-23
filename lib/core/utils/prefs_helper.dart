import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

/// Persists the user's theme preference.
///
/// Deliberately the only thing stored locally: no user id, no tokens, no
/// credentials. Ownership is always derived from the authenticated Firebase
/// user, so a stale local copy can never be used to reach another account.
class PrefsHelper {
  const PrefsHelper(this._prefs);

  final SharedPreferences _prefs;

  AppThemeMode getThemeMode() {
    final stored = _prefs.getString(AppConstants.themeModeKey);
    if (stored == null) return AppThemeMode.system;
    return AppThemeMode.fromString(stored);
  }

  Future<void> setThemeMode(AppThemeMode mode) {
    return _prefs.setString(AppConstants.themeModeKey, mode.storageValue);
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/prefs_helper.dart';

/// Owns the selected [AppThemeMode] and persists it across launches.
///
/// Theme changes only ever touch this provider, so switching theme never
/// rebuilds the task stream and never disturbs authentication.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._prefsHelper) : _themeMode = _prefsHelper.getThemeMode();

  final PrefsHelper _prefsHelper;
  AppThemeMode _themeMode;

  AppThemeMode get themeMode => _themeMode;

  ThemeMode get flutterThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  void setThemeMode(AppThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    // Repaint immediately, then persist in the background — the UI must never
    // wait on disk for a theme change.
    notifyListeners();
    unawaited(
      _prefsHelper.setThemeMode(mode).catchError((Object error) {
        debugPrint('ThemeProvider: could not persist theme — $error');
      }),
    );
  }
}

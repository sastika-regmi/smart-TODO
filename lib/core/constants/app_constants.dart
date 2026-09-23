class AppConstants {
  const AppConstants._();

  static const String appName = 'Smart ToDo';
  static const String appTagline = 'Manage your tasks effortlessly';

  // Firebase collections
  static const String usersCollection = 'users';
  static const String tasksCollection = 'tasks';

  // SharedPreferences keys
  static const String themeModeKey = 'theme_mode';
  static const String firstLaunchKey = 'is_first_launch';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int maxNameLength = 60;
  static const int maxTaskTitleLength = 100;
  static const int maxTaskDescriptionLength = 500;

  // Responsive breakpoints (Material 3 window size classes)
  static const double compactBreakpoint = 600;
  static const double expandedBreakpoint = 1024;

  /// Upper bound for centred content on large screens. Without this, forms and
  /// lists stretch across a wide browser and become hard to read.
  static const double maxContentWidth = 1280;
  static const double maxFormWidth = 560;

  // Timing
  static const Duration searchDebounce = Duration(milliseconds: 250);
  static const Duration snackbarDuration = Duration(seconds: 3);
  static const Duration shortAnimation = Duration(milliseconds: 200);

  /// Minimum touch target, per the Material accessibility guidance.
  static const double minTouchTarget = 48;
}

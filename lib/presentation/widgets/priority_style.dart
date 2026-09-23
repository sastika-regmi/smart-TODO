import 'package:flutter/material.dart';

import '../../domain/entities/task.dart';

/// Presentation-only styling for [TaskPriority].
///
/// Kept out of the domain entity so the entity stays pure Dart and so colours
/// can adapt to the active [ColorScheme] instead of being hardcoded.
extension TaskPriorityStyle on TaskPriority {
  Color color(ColorScheme scheme) {
    switch (this) {
      case TaskPriority.low:
        // Tertiary keeps the palette inside the Material 3 scheme rather than
        // inventing a green that fails contrast in one of the themes.
        return scheme.tertiary;
      case TaskPriority.medium:
        return scheme.secondary;
      case TaskPriority.high:
        return scheme.error;
    }
  }

  IconData get icon {
    switch (this) {
      case TaskPriority.low:
        return Icons.arrow_downward;
      case TaskPriority.medium:
        return Icons.drag_handle;
      case TaskPriority.high:
        return Icons.arrow_upward;
    }
  }
}

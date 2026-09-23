import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Material 3 window size classes.
enum WindowSize { compact, medium, expanded }

/// Layout helpers.
///
/// Every method reads the size through `MediaQuery.sizeOf`, which subscribes
/// only to size changes. Using `MediaQuery.of(context)` instead would rebuild
/// callers whenever *any* MediaQuery field changed — including the keyboard
/// opening, which happens on every focus change.
class Responsive {
  const Responsive._();

  static WindowSize sizeOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < AppConstants.compactBreakpoint) return WindowSize.compact;
    if (width < AppConstants.expandedBreakpoint) return WindowSize.medium;
    return WindowSize.expanded;
  }

  static bool isCompact(BuildContext context) =>
      sizeOf(context) == WindowSize.compact;

  /// Medium and expanded share a layout, but only expanded gets a nav rail.
  static bool isExpanded(BuildContext context) =>
      sizeOf(context) == WindowSize.expanded;

  static bool isCompactOrMedium(BuildContext context) =>
      sizeOf(context) != WindowSize.expanded;

  /// Horizontal page padding, scaled to the window size.
  static EdgeInsets horizontalPadding(BuildContext context) {
    switch (sizeOf(context)) {
      case WindowSize.compact:
        return const EdgeInsets.symmetric(horizontal: 16);
      case WindowSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24);
      case WindowSize.expanded:
        return const EdgeInsets.symmetric(horizontal: 32);
    }
  }

  /// Content width cap so a wide browser does not stretch a phone layout.
  static double maxContentWidth(BuildContext context) {
    switch (sizeOf(context)) {
      case WindowSize.compact:
        return double.infinity;
      case WindowSize.medium:
        return 720;
      case WindowSize.expanded:
        return AppConstants.maxContentWidth;
    }
  }

  /// Forms stay narrower than the content column — a 1280px-wide text field is
  /// unusable.
  static double maxFormWidth(BuildContext context) =>
      AppConstants.maxFormWidth;

  /// Number of columns for the task grid. One on phones, so cards keep a
  /// comfortable reading width.
  static int taskGridColumns(BuildContext context, double availableWidth) {
    if (availableWidth < AppConstants.compactBreakpoint) return 1;
    if (availableWidth < AppConstants.expandedBreakpoint) return 2;
    return 3;
  }

  /// Whether the task statistics row fits horizontally without wrapping.
  static bool statsFitHorizontally(BuildContext context) =>
      sizeOf(context) != WindowSize.compact;
}

/// Centres its child and caps the width, with the responsive page padding.
class ContentContainer extends StatelessWidget {
  const ContentContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? Responsive.maxContentWidth(context),
        ),
        child: Padding(
          padding: padding ?? Responsive.horizontalPadding(context),
          child: child,
        ),
      ),
    );
  }
}

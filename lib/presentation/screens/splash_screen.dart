import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

/// Initialisation screen shown while Firebase resolves the auth state.
///
/// Purely presentational: no timer and no navigation. The old implementation
/// waited on a hardcoded 2.2-second delay before doing anything, which made
/// every launch slower for no reason. This version stays up exactly as long as
/// real work is happening.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.primary,
      body: Center(
        child: Semantics(
          label: '${AppConstants.appName} is starting',
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: scheme.onPrimary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.checklist_rounded,
                  size: 48,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppConstants.appName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppConstants.appTagline,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onPrimary.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(scheme.onPrimary),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 14),
                Text(
                  message!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimary.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ed_operador/app/tokens.dart';
import 'package:ed_operador/state/providers.dart';

/// The initial branded screen shown while the application initializes
/// (Requirement 1).
///
/// The screen continuously displays the application name "ED-Operador"
/// (Requirement 1.2) and reacts to [appInitProvider]:
///
/// - While initialization is in flight, a progress indicator is shown beneath
///   the branding (Requirement 1.2).
/// - On successful completion, the app navigates to `/login` (Requirement 1.3).
///   Navigation is performed as a side-effect via `ref.listen` and guarded with
///   a post-frame callback so it never runs during a build.
/// - On failure or timeout, the screen stays put, shows an error message, and
///   offers a retry control that restarts initialization by invalidating
///   [appInitProvider] (Requirement 1.5).
///
/// The screen applies the ambient Material 3 theme (Requirement 1.4).
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  void _goToLogin(BuildContext context) {
    // Guard navigation with a post-frame callback so we never navigate while a
    // build/listener is still running.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Navigate to the Login_Screen once initialization succeeds. Using
    // `ref.listen` keeps the navigation side-effect out of the build phase.
    ref.listen<AsyncValue<void>>(appInitProvider, (previous, next) {
      next.whenOrNull(
        data: (_) => _goToLogin(context),
      );
    });

    final theme = Theme.of(context);
    final initState = ref.watch(appInitProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Kigo logo from local assets.
                Image.asset(
                  'assets/logo.png',
                  width: 88,
                  height: 88,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: AppSpacing.xl),
                // Application name shown continuously (Requirement 1.2).
                Text(
                  'ED-Operador',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: AppColors.kigo500,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                initState.when(
                  loading: () => const _SplashProgress(),
                  data: (_) => const _SplashProgress(),
                  error: (error, stackTrace) => _SplashError(
                    onRetry: () => ref.invalidate(appInitProvider),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Progress indicator shown while initialization is in flight.
class _SplashProgress extends StatelessWidget {
  const _SplashProgress();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.kigo500),
      ),
    );
  }
}

/// Error message and retry control shown when initialization fails or times out
/// (Requirement 1.5).
class _SplashError extends StatelessWidget {
  const _SplashError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          color: theme.colorScheme.error,
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          'Initialization failed. Please try again.',
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}

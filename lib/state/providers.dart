import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ed_operador/data/session.dart';
import 'package:ed_operador/services/initialization_service.dart';
import 'package:ed_operador/services/session_storage.dart';

/// The maximum time application initialization is allowed to take before the
/// Splash_Screen surfaces a retryable error (Requirements 1.3, 1.5).
const Duration appInitTimeout = Duration(seconds: 10);

/// Provides the [SessionStorage] used to persist the session across restarts.
final sessionStorageProvider = Provider<SessionStorage>(
  (ref) => SessionStorage(),
);

/// Provides the [InitializationService] used to perform startup work.
///
/// Defaults to [DefaultInitializationService] for local runs and can be
/// overridden in tests via `ProviderScope` `overrides`, e.g.:
/// ```dart
/// ProviderScope(
///   overrides: [
///     initializationServiceProvider.overrideWithValue(FakeInitService()),
///   ],
///   child: const MyApp(),
/// );
/// ```
final initializationServiceProvider = Provider<InitializationService>(
  (ref) => const DefaultInitializationService(),
);

/// Runs application initialization under a 10-second budget and exposes the
/// result as an [AsyncValue] to the Splash_Screen (Requirements 1.3, 1.5).
///
/// On launch, attempts to restore a persisted session from local storage. If
/// found, the session is set in [sessionProvider] so the router redirects
/// directly to the Main_Screen.
final appInitProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(initializationServiceProvider);
  await service.initialize().timeout(appInitTimeout);

  // Restore persisted session (if any) so the Operator stays logged in across
  // app restarts.
  final storage = ref.read(sessionStorageProvider);
  final session = await storage.restore();
  if (session != null) {
    ref.read(sessionProvider.notifier).state = session;
  }
});

/// Holds the current authenticated [Session], or `null` when the Operator is
/// unauthenticated (Requirement 3.6).
///
/// The login controller sets a [Session] on successful authentication; clearing
/// it (setting `null`) logs the Operator out. Consumers such as the
/// `RouteGuard` read `isAuthenticated` from the held session to gate access to
/// the Main_Screen.
///
/// Set a session:
/// ```dart
/// ref.read(sessionProvider.notifier).state = session;
/// ```
/// Clear the session:
/// ```dart
/// ref.read(sessionProvider.notifier).state = null;
/// ```
final sessionProvider = StateProvider<Session?>((ref) => null);

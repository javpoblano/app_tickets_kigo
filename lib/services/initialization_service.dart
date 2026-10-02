/// Performs application startup work on launch.
///
/// The state layer wraps [initialize] with a 10-second budget and surfaces a
/// retryable error to the Splash_Screen on failure or timeout (Requirements
/// 1.3, 1.5).
abstract class InitializationService {
  /// Completes when startup work is done. Throws or times out on failure.
  Future<void> initialize();
}

/// A minimal [InitializationService] for local runs.
///
/// Performs no meaningful startup work and completes immediately, letting the
/// Splash_Screen transition to the Login_Screen without a backing service.
class DefaultInitializationService implements InitializationService {
  const DefaultInitializationService();

  @override
  Future<void> initialize() async {
    // No startup work required for local runs.
  }
}

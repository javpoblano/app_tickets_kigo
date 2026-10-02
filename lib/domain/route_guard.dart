/// Pure domain logic for the authentication route gate.
///
/// Encodes Requirement 3.6: unauthenticated requests to the Main route
/// resolve to the Login route so no ticket action can be reached without
/// authentication.
class RouteGuard {
  /// Route path constants matching the design's navigation flow.
  static const String splash = '/splash';
  static const String login = '/login';
  static const String main = '/main';

  const RouteGuard._();

  /// Given the current auth state and a requested route, returns the route
  /// that should be shown.
  ///
  /// - When not authenticated and the request targets [main], redirects to
  ///   [login].
  /// - When authenticated and the request targets [login] or [splash],
  ///   redirects to [main] (session was restored, skip login).
  /// - Otherwise the [requested] route is returned unchanged.
  static String resolve({
    required bool isAuthenticated,
    required String requested,
  }) {
    if (!isAuthenticated && requested == main) {
      return login;
    }
    if (isAuthenticated && (requested == login || requested == splash)) {
      return main;
    }
    return requested;
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ed_operador/domain/route_guard.dart';
import 'package:ed_operador/screens/login_screen.dart';
import 'package:ed_operador/screens/main_screen.dart';
import 'package:ed_operador/screens/splash_screen.dart';
import 'package:ed_operador/state/providers.dart';

/// A [Listenable] that notifies its listeners whenever [sessionProvider]
/// changes, so the [GoRouter] re-evaluates its `redirect` callback (and thus
/// the [RouteGuard]) on every authentication state transition.
///
/// This bridges Riverpod's reactive `sessionProvider` to go_router's
/// `refreshListenable`, ensuring the auth gate re-runs when the Operator logs
/// in or out (Requirements 2.6, 3.6).
class _SessionRefreshListenable extends ChangeNotifier {
  _SessionRefreshListenable(Ref ref) {
    _subscription = ref.listen(
      sessionProvider,
      (_, _) => notifyListeners(),
    );
  }

  late final ProviderSubscription _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

/// Builds the application [GoRouter].
///
/// Routes:
/// - `/splash` — the initial location, shows the [SplashScreen].
/// - `/login` — shows the [LoginScreen].
/// - `/main` — shows the [MainScreen]; only reachable when authenticated.
///
/// The `redirect` callback reads [sessionProvider] to determine whether the
/// Operator is authenticated and consults [RouteGuard.resolve] to block
/// unauthenticated access to `/main` (redirecting to `/login`). `/splash` and
/// `/login` always remain reachable. The router refreshes whenever
/// [sessionProvider] changes via [_SessionRefreshListenable]
/// (Requirements 1.3, 2.6, 3.6).
final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _SessionRefreshListenable(ref);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: RouteGuard.splash,
    refreshListenable: refreshListenable,
    routes: [
      GoRoute(
        path: RouteGuard.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteGuard.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteGuard.main,
        builder: (context, state) => const MainScreen(),
      ),
    ],
    redirect: (context, state) {
      final isAuthenticated =
          ref.read(sessionProvider)?.isAuthenticated ?? false;
      final requested = state.matchedLocation;
      final resolved = RouteGuard.resolve(
        isAuthenticated: isAuthenticated,
        requested: requested,
      );
      // Returning null keeps the current navigation when the guard allows the
      // requested route; otherwise redirect to the resolved (guarded) route.
      return resolved == requested ? null : resolved;
    },
  );
});

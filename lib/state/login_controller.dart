import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:ed_operador/app/app_config.dart';
import 'package:ed_operador/data/credentials.dart';
import 'package:ed_operador/domain/credential_validator.dart';
import 'package:ed_operador/services/authentication_service.dart';
import 'package:ed_operador/services/http_authentication_service.dart';
import 'package:ed_operador/state/login_state.dart';
import 'package:ed_operador/state/providers.dart';

/// The maximum time a single authentication attempt is allowed to take before
/// the login controller surfaces an authentication error (Requirements 2.3,
/// 2.7, 2.9).
const Duration loginTimeout = Duration(seconds: 10);

/// Provides the shared [http.Client] used by the Backend_API services.
///
/// Held as a provider so it can be overridden in tests (e.g. with a
/// `MockClient`) and disposed with the container.
final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// Provides the [AuthenticationService] used to authenticate an Operator.
///
/// Defaults to a [HttpAuthenticationService] built from [httpClientProvider]
/// and [appConfigProvider]. It can be overridden in tests via `ProviderScope`
/// `overrides`, e.g.:
/// ```dart
/// ProviderScope(
///   overrides: [
///     authenticationServiceProvider.overrideWithValue(FakeAuthService()),
///   ],
///   child: const MyApp(),
/// );
/// ```
final authenticationServiceProvider = Provider<AuthenticationService>((ref) {
  final client = ref.watch(httpClientProvider);
  final config = ref.watch(appConfigProvider);
  return HttpAuthenticationService(client, config);
});

/// Orchestrates the Login_Screen authentication flow, exposing an immutable
/// [LoginState] that starts at [LoginIdle].
///
/// See design.md — the controller runs [CredentialValidator] before any service
/// call, applies a 10-second budget to the [AuthenticationService.authenticate]
/// call, stores the resulting [Session] in [sessionProvider] on success, and
/// maps every other outcome to a non-success [LoginState] while retaining the
/// entered username (Requirements 2.3, 2.5, 2.6, 2.7, 2.8, 2.9, 2.10).
final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>((ref) {
  return LoginController(ref);
});

/// [StateNotifier] backing the [loginControllerProvider].
class LoginController extends StateNotifier<LoginState> {
  final Ref _ref;

  LoginController(this._ref) : super(const LoginIdle());

  /// Attempts to authenticate the Operator with the entered [username] and
  /// [password].
  ///
  /// Flow:
  /// 1. Runs [CredentialValidator.validate]; if the fields are invalid, sets
  ///    [LoginInvalidFields] (retaining the username) and returns without
  ///    calling the service (Requirement 2.10).
  /// 2. Sets [LoginSubmitting] to disable the login action, then calls
  ///    [AuthenticationService.authenticate] under a 10-second budget
  ///    (Requirements 2.3, 2.7).
  /// 3. On success, stores the [Session] in [sessionProvider] and sets
  ///    [LoginSuccess] (Requirements 2.5, 2.6).
  /// 4. On [InvalidCredentialsException], sets [LoginInvalidCredentials]
  ///    (Requirement 2.8).
  /// 5. On [AuthUnavailableException], timeout, or any other error, sets
  ///    [LoginError] (Requirement 2.9).
  ///
  /// The entered username is retained across [LoginInvalidFields],
  /// [LoginInvalidCredentials], and [LoginError] (Requirement 2.6).
  Future<void> submit(String username, String password) async {
    // 1. Local validation before any service call.
    final result = CredentialValidator.validate(username, password);
    if (!result.isValid) {
      state = LoginInvalidFields(result: result, username: username);
      return;
    }

    // 2. Submit under a 10-second budget; disable the login action.
    state = const LoginSubmitting();

    final service = _ref.read(authenticationServiceProvider);
    try {
      final session = await service
          .authenticate(Credentials(username: username, password: password))
          .timeout(loginTimeout);

      // 3. Success: store the session and persist it.
      _ref.read(sessionProvider.notifier).state = session;
      await _ref.read(sessionStorageProvider).save(session);
      state = LoginSuccess(session: session);
    } on InvalidCredentialsException {
      // 4. Rejected credentials.
      state = LoginInvalidCredentials(username: username);
    } on AuthUnavailableException {
      // 5a. Backend_API unavailable.
      state = LoginError(username: username);
    } on TimeoutException {
      // 5b. Exceeded the 10-second budget.
      state = LoginError(username: username);
    } catch (_) {
      // 5c. Any other unexpected failure.
      state = LoginError(username: username);
    }
  }

  /// Resets the controller to its initial [LoginIdle] state.
  void reset() {
    state = const LoginIdle();
  }
}

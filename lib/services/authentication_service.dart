import 'package:ed_operador/data/credentials.dart';
import 'package:ed_operador/data/session.dart';

/// Authenticates an Operator's [Credentials] against the Login_Endpoint and
/// returns an authenticated [Session] on success.
///
/// Implementations send a `POST` to the Login_Endpoint with a
/// `Content-Type: application/json` header and an `x-api-key` header containing
/// the Api_Key, and a `{username, password}` JSON body (Requirement 2.3), then
/// decode the `token`/`user`/`roles` response into a [Session].
abstract class AuthenticationService {
  /// Authenticates the given [credentials].
  ///
  /// Returns a [Session] (token + user + roles) on success.
  ///
  /// Throws [InvalidCredentialsException] when the Login_Endpoint rejects the
  /// submitted credentials, and [AuthUnavailableException] on timeout or when
  /// the Login_Endpoint is unavailable.
  Future<Session> authenticate(Credentials credentials);
}

/// Thrown when the Login_Endpoint rejects the submitted [Credentials].
class InvalidCredentialsException implements Exception {
  final String message;

  const InvalidCredentialsException([
    this.message = 'The submitted credentials are not valid.',
  ]);

  @override
  String toString() => 'InvalidCredentialsException: $message';
}

/// Thrown when authentication could not be completed because the
/// Login_Endpoint did not respond within the budget or is unavailable.
class AuthUnavailableException implements Exception {
  final String message;

  const AuthUnavailableException([
    this.message = 'Authentication could not be completed.',
  ]);

  @override
  String toString() => 'AuthUnavailableException: $message';
}

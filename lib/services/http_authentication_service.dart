import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:ed_operador/app/app_config.dart';
import 'package:ed_operador/data/credentials.dart';
import 'package:ed_operador/data/session.dart';
import 'package:ed_operador/services/authentication_service.dart';

/// Concrete [AuthenticationService] that authenticates an Operator against the
/// Backend_API Login_Endpoint (`POST /operator/login`) using the [http]
/// package.
///
/// The base URL and `Api_Key` are read from [AppConfig]; the request carries a
/// `Content-Type: application/json` header, an `x-api-key` header, and a
/// `{username, password}` JSON body (Requirement 2.3). A successful (2xx)
/// response is decoded into a [Session] via [Session.fromJson] (Requirement
/// 2.5). A response that rejects the credentials (401/403) surfaces as an
/// [InvalidCredentialsException], while a timeout, network error, or any other
/// non-2xx response surfaces as an [AuthUnavailableException] (Requirement 2.9).
class HttpAuthenticationService implements AuthenticationService {
  final http.Client _client;
  final AppConfig _config;

  const HttpAuthenticationService(this._client, this._config);

  @override
  Future<Session> authenticate(Credentials credentials) async {
    final uri = Uri.parse('${_config.backendBaseUrl}/operator/login');

    final http.Response response;
    try {
      response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _config.apiKey,
        },
        body: jsonEncode({
          'username': credentials.username,
          'password': credentials.password,
        }),
      );
    } catch (_) {
      // Network error / timeout / connection failure.
      throw const AuthUnavailableException();
    }

    final statusCode = response.statusCode;

    // Rejected credentials.
    if (statusCode == 401 || statusCode == 403) {
      throw const InvalidCredentialsException();
    }

    // Success: decode token/user/roles into a Session.
    if (statusCode >= 200 && statusCode < 300) {
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return Session.fromJson(decoded);
      } catch (error) {
        // Malformed/unexpected success payload. Preserve the underlying reason
        // so a schema/parse mismatch is diagnosable rather than looking like a
        // network failure.
        throw AuthUnavailableException(
          'Login succeeded ($statusCode) but the response could not be '
          'parsed: $error',
        );
      }
    }

    // Any other non-2xx response (5xx, other 4xx, etc.).
    throw const AuthUnavailableException();
  }
}

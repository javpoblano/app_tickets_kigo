import 'package:flutter/foundation.dart';

import 'package:ed_operador/data/session.dart';
import 'package:ed_operador/domain/validation_result.dart';

/// Immutable view state for the Login_Screen, produced by the login controller.
///
/// See design.md Data Models — LoginState. The controller preserves the entered
/// username across [LoginInvalidCredentials], [LoginError], and
/// [LoginInvalidFields] so the Login_Screen can retain it (Requirements 2.6,
/// 2.8).
@immutable
sealed class LoginState {
  const LoginState();
}

/// Initial state: no login attempt in progress.
@immutable
class LoginIdle extends LoginState {
  const LoginIdle();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoginIdle && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'LoginIdle()';
}

/// Credentials are being submitted; the login action is disabled
/// (Requirement 2.7).
@immutable
class LoginSubmitting extends LoginState {
  const LoginSubmitting();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoginSubmitting && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'LoginSubmitting()';
}

/// Submitted fields failed local validation (empty/invalid fields). Retains the
/// entered username and carries the [ValidationResult] describing the offending
/// fields (Requirements 2.8, 2.10).
@immutable
class LoginInvalidFields extends LoginState {
  final ValidationResult result;
  final String username;

  const LoginInvalidFields({required this.result, required this.username});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoginInvalidFields &&
          runtimeType == other.runtimeType &&
          result == other.result &&
          username == other.username;

  @override
  int get hashCode => Object.hash(runtimeType, result, username);

  @override
  String toString() =>
      'LoginInvalidFields(result: $result, username: $username)';
}

/// The Login_Endpoint rejected the submitted credentials. Retains the entered
/// username and remains on the Login_Screen (Requirement 2.8).
@immutable
class LoginInvalidCredentials extends LoginState {
  final String username;

  const LoginInvalidCredentials({required this.username});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoginInvalidCredentials &&
          runtimeType == other.runtimeType &&
          username == other.username;

  @override
  int get hashCode => Object.hash(runtimeType, username);

  @override
  String toString() => 'LoginInvalidCredentials(username: $username)';
}

/// Authentication could not be completed (timeout/unavailable). Retains the
/// entered username and remains on the Login_Screen (Requirement 2.8).
@immutable
class LoginError extends LoginState {
  final String username;

  const LoginError({required this.username});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoginError &&
          runtimeType == other.runtimeType &&
          username == other.username;

  @override
  int get hashCode => Object.hash(runtimeType, username);

  @override
  String toString() => 'LoginError(username: $username)';
}

/// Authentication succeeded; carries the authenticated [Session]
/// (Requirement 2.6).
@immutable
class LoginSuccess extends LoginState {
  final Session session;

  const LoginSuccess({required this.session});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoginSuccess &&
          runtimeType == other.runtimeType &&
          session == other.session;

  @override
  int get hashCode => Object.hash(runtimeType, session);

  @override
  String toString() => 'LoginSuccess(session: $session)';
}

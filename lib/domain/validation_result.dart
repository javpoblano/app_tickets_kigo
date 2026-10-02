import 'package:flutter/foundation.dart';

/// Reports, per credential field, whether it is missing (empty/whitespace-only)
/// or violates its maximum length bound.
///
/// See design.md Data Models — ValidationResult. A field is considered
/// "missing" when it is empty or contains only whitespace after trimming.
@immutable
class ValidationResult {
  final bool usernameMissing;
  final bool passwordMissing;
  final bool usernameTooLong;
  final bool passwordTooLong;

  const ValidationResult({
    this.usernameMissing = false,
    this.passwordMissing = false,
    this.usernameTooLong = false,
    this.passwordTooLong = false,
  });

  /// True when no field is missing or out of range.
  bool get isValid =>
      !usernameMissing &&
      !passwordMissing &&
      !usernameTooLong &&
      !passwordTooLong;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationResult &&
          runtimeType == other.runtimeType &&
          usernameMissing == other.usernameMissing &&
          passwordMissing == other.passwordMissing &&
          usernameTooLong == other.usernameTooLong &&
          passwordTooLong == other.passwordTooLong;

  @override
  int get hashCode => Object.hash(
        usernameMissing,
        passwordMissing,
        usernameTooLong,
        passwordTooLong,
      );

  @override
  String toString() =>
      'ValidationResult(usernameMissing: $usernameMissing, '
      'passwordMissing: $passwordMissing, '
      'usernameTooLong: $usernameTooLong, '
      'passwordTooLong: $passwordTooLong)';
}

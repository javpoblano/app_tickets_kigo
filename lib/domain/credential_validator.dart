import 'validation_result.dart';

/// Pure domain logic that validates operator credentials against the length
/// bounds defined in the design (username 1–254, password 1–128).
///
/// A field is treated as missing when it is empty or whitespace-only (checked
/// against the trimmed value); the upper bound is checked against the raw
/// length so leading/trailing whitespace still counts toward the maximum.
class CredentialValidator {
  const CredentialValidator._();

  static const int usernameMin = 1;
  static const int usernameMax = 254;
  static const int passwordMin = 1;
  static const int passwordMax = 128;

  /// Returns a [ValidationResult] listing which fields are missing or exceed
  /// their maximum length.
  static ValidationResult validate(String username, String password) {
    final usernameMissing = username.trim().isEmpty;
    final passwordMissing = password.trim().isEmpty;
    final usernameTooLong = username.length > usernameMax;
    final passwordTooLong = password.length > passwordMax;

    return ValidationResult(
      usernameMissing: usernameMissing,
      passwordMissing: passwordMissing,
      usernameTooLong: usernameTooLong,
      passwordTooLong: passwordTooLong,
    );
  }
}

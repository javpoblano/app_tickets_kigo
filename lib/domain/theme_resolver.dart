import 'package:flutter/material.dart';

/// The device's expressed system theme preference.
///
/// [unspecified] represents the absence of an explicit dark/light preference,
/// in which case the application defaults to a dark scheme (Requirement 4.5).
enum DevicePreference { light, dark, unspecified }

/// Pure domain logic that maps a [DevicePreference] to an effective
/// [Brightness] and builds a Material 3 [ColorScheme] from a single seed color.
///
/// Encodes Requirements 4.2–4.5.
class ThemeResolver {
  const ThemeResolver._();

  /// Resolves the effective [Brightness] for a device [preference].
  ///
  /// Returns [Brightness.light] for [DevicePreference.light]; returns
  /// [Brightness.dark] for [DevicePreference.dark] and, per Requirement 4.5,
  /// for [DevicePreference.unspecified] (dark default).
  static Brightness resolve(DevicePreference preference) {
    switch (preference) {
      case DevicePreference.light:
        return Brightness.light;
      case DevicePreference.dark:
      case DevicePreference.unspecified:
        return Brightness.dark;
    }
  }

  /// Builds a Material 3 [ColorScheme] for the given [brightness], derived from
  /// the single [seed] color via [ColorScheme.fromSeed] (Requirement 4.2).
  static ColorScheme scheme(Color seed, Brightness brightness) {
    return ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  }
}

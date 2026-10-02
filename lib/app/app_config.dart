import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable application configuration for the ED-Operador app.
///
/// Holds the Backend_API base URL and the `Api_Key` sent in the `x-api-key`
/// header on every Backend_API call. The concrete services (authentication and
/// ticket registration) read these values rather than hard-coding them at each
/// call site.
///
/// The [apiKey] (and optionally [backendBaseUrl]) are supplied via build-time
/// configuration (`--dart-define`) so the key is never committed to source.
class AppConfig {
  /// Base URL of the Backend_API, e.g.
  /// `https://api-stg.parkimovil.io/smartparking-mobile`.
  final String backendBaseUrl;

  /// Value sent in the `x-api-key` header on every Backend_API call.
  final String apiKey;

  /// Base URL of the NAP Smart Access API used by the ticket process endpoint,
  /// e.g. `https://api-stg.parkimovil.io/smartparking-hw`.
  final String napBaseUrl;

  /// Value sent in the `x-api-key` header on NAP Smart Access calls.
  final String napApiKey;

  const AppConfig({
    required this.backendBaseUrl,
    required this.apiKey,
    required this.napBaseUrl,
    required this.napApiKey,
  });

  /// The default Backend_API base URL used when no `--dart-define` override is
  /// provided.
  static const String defaultBackendBaseUrl =
      'https://api-stg.parkimovil.io/smartparking-mobile';

  /// The default NAP Smart Access base URL (staging).
  static const String defaultNapBaseUrl =
      'https://api-stg.parkimovil.io/smartparking-hw';

  /// The default NAP Smart Access API key (staging).
  static const String defaultNapApiKey = 'E8fgbV8X3gangFEjtTHqSBUqP08TiPQe';

  /// Builds an [AppConfig] from build-time environment values provided via
  /// `--dart-define`.
  ///
  /// - `BACKEND_BASE_URL` overrides [backendBaseUrl] (defaults to
  ///   [defaultBackendBaseUrl]).
  /// - `API_KEY` supplies [apiKey] (defaults to an empty string when not set).
  /// - `NAP_BASE_URL` overrides [napBaseUrl] (defaults to [defaultNapBaseUrl]).
  /// - `NAP_API_KEY` overrides [napApiKey] (defaults to [defaultNapApiKey]).
  ///
  /// Example:
  /// ```
  /// flutter run --dart-define=API_KEY=your-key \
  ///   --dart-define=BACKEND_BASE_URL=https://api.example.com/smartparking-mobile
  /// ```
  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      backendBaseUrl: String.fromEnvironment(
        'BACKEND_BASE_URL',
        defaultValue: defaultBackendBaseUrl,
      ),
      apiKey: String.fromEnvironment('API_KEY'),
      napBaseUrl: String.fromEnvironment(
        'NAP_BASE_URL',
        defaultValue: defaultNapBaseUrl,
      ),
      napApiKey: String.fromEnvironment(
        'NAP_API_KEY',
        defaultValue: defaultNapApiKey,
      ),
    );
  }

  AppConfig copyWith({
    String? backendBaseUrl,
    String? apiKey,
    String? napBaseUrl,
    String? napApiKey,
  }) {
    return AppConfig(
      backendBaseUrl: backendBaseUrl ?? this.backendBaseUrl,
      apiKey: apiKey ?? this.apiKey,
      napBaseUrl: napBaseUrl ?? this.napBaseUrl,
      napApiKey: napApiKey ?? this.napApiKey,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppConfig &&
          runtimeType == other.runtimeType &&
          backendBaseUrl == other.backendBaseUrl &&
          apiKey == other.apiKey &&
          napBaseUrl == other.napBaseUrl &&
          napApiKey == other.napApiKey;

  @override
  int get hashCode =>
      Object.hash(backendBaseUrl, apiKey, napBaseUrl, napApiKey);
}

/// Provides the application [AppConfig].
///
/// Reads configuration from build-time `--dart-define` values by default. It
/// can be overridden per environment or in tests via `ProviderScope`
/// `overrides`, e.g.:
/// ```dart
/// ProviderScope(
///   overrides: [
///     appConfigProvider.overrideWithValue(
///       const AppConfig(backendBaseUrl: '...', apiKey: 'test-key'),
///     ),
///   ],
///   child: const MyApp(),
/// );
/// ```
final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);

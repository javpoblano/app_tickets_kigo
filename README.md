# ed_operador

ED-Operador is a Flutter application that lets operators authenticate and issue
tickets (regular and promotion) against the Backend_API.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Configuration

The app reads its Backend_API configuration at build time via `--dart-define`,
so the API key is never committed to source. These values back the `AppConfig`
(`lib/app/app_config.dart`) exposed through `appConfigProvider`.

| Variable           | Required | Default                                          | Description                                              |
|--------------------|----------|--------------------------------------------------|----------------------------------------------------------|
| `API_KEY`          | Yes      | _(empty)_                                        | Value sent in the `x-api-key` header on every API call.  |
| `BACKEND_BASE_URL` | No       | `http://localhost:8080/smartparking-mobile`      | Base URL of the Backend_API.                             |

### Providing the API key

Pass the key with `--dart-define` when running or building:

```bash
# Run in development
flutter run --dart-define=API_KEY=your-api-key-here

# Override the backend base URL as well
flutter run \
  --dart-define=API_KEY=your-api-key-here \
  --dart-define=BACKEND_BASE_URL=https://api.example.com/smartparking-mobile

# Build a release APK
flutter build apk --release --dart-define=API_KEY=your-api-key-here
```

To avoid repeating the flags, you can keep them in a `--dart-define-from-file`
JSON file (for example `env.json`, which you should git-ignore):

```json
{
  "API_KEY": "your-api-key-here",
  "BACKEND_BASE_URL": "http://localhost:8080/smartparking-mobile"
}
```

```bash
flutter run --dart-define-from-file=env.json
```

In tests, `appConfigProvider` can be overridden directly via a `ProviderScope`
override rather than using `--dart-define`.

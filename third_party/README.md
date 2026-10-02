# Vendored third-party packages

## telpo_flutter_sdk

A locally-patched copy of [`telpo_flutter_sdk`](https://pub.dev/packages/telpo_flutter_sdk)
`0.1.1`, wired in via `dependency_overrides` in the root `pubspec.yaml`.

The published version does not build on current Flutter for two reasons:

1. Its `android/build.gradle` does not declare a `namespace`, which is required
   by Android Gradle Plugin 8+.
2. Its Android plugin still references the removed v1 embedding API
   (`PluginRegistry.Registrar`, `registrar.messenger()`), causing an
   `Unresolved reference 'Registrar'` compile error.

Patches applied to this copy:

- `android/build.gradle`: added `namespace 'me.aljan.telpo_flutter_sdk'` and
  bumped `compileSdkVersion` to 34.
- `android/src/main/AndroidManifest.xml`: removed the deprecated `package`
  attribute (the namespace now lives in `build.gradle`).
- `android/.../TelpoFlutterSdkPlugin.kt`: removed the obsolete
  `registerWith(Registrar)` companion and the unused `registrar` field plus the
  `PluginRegistry` import. The v2 embedding implementation
  (`onAttachedToEngine`, `ActivityAware`) is unchanged.
- `android/.../TelpoThermalPrinter.kt`: fixed multi-element printing. Upstream
  called `result.success(true)` inside every `printText`/`printByte`, so a sheet
  with more than one element completed the `MethodChannel.Result` on the first
  element and then invoked it again (crashing with "Reply already submitted")
  and left the buffer partially committed. The patched version accumulates all
  elements, calls `printString()` once after the loop, and reports success
  exactly once for the whole sheet.
- `android/.../TelpoFlutterSdkPlugin.kt` (`connect` handler): fixed
  "prints once, then nothing". The print flow calls `stop()` at the end of every
  job, but upstream only ran `start()`/`reset()` when `!_isConnected` — and
  never reset `_isConnected` — so the second `connect` was a no-op that also
  returned no result (hanging the Dart caller). The patched handler registers
  the battery receiver once but always re-runs `start()`/`reset()` and always
  returns a result, so each print reconnects reliably.

If a newer upstream release fixes these issues, drop this fork and depend on the
published package directly.

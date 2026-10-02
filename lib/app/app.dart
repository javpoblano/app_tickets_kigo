import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ed_operador/app/app_theme.dart';
import 'package:ed_operador/app/router.dart';
import 'package:ed_operador/domain/theme_resolver.dart';
import 'package:ed_operador/state/ticket_controller.dart';

/// The root application widget for ED-Operador.
///
/// Wires [MaterialApp.router] to the [routerProvider] and applies the Material 3
/// theming from a single seed color: [AppTheme.light] and [AppTheme.dark]
/// (Requirement 4.1).
///
/// Theming is driven reactively from the device system theme preference. On
/// every build the current `MediaQuery.platformBrightnessOf(context)` is read
/// and pushed into [devicePreferenceProvider]; the resolved [Brightness] from
/// [themeModeProvider] (which maps the preference via [ThemeResolver], defaulting
/// to dark when unspecified per Requirement 4.5) selects an explicit
/// [ThemeMode]. Because a device preference change re-triggers [build] via the
/// enclosing [MediaQuery], the rendered scheme updates within the requirement's
/// window (Requirement 4.6). An explicit [ThemeMode] is used instead of
/// [ThemeMode.system] so the dark default for an unspecified preference is
/// honored.
class EdOperadorApp extends ConsumerWidget {
  const EdOperadorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read the device's current platform brightness. `MediaQuery.platform
    // BrightnessOf` establishes a dependency so this widget rebuilds when the
    // OS theme preference changes at runtime (Requirement 4.6).
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final devicePreference = platformBrightness == Brightness.dark
        ? DevicePreference.dark
        : DevicePreference.light;

    // Push the observed preference into the shared provider so the rest of the
    // app resolves theming from a single source of truth. Deferred to after the
    // current build to avoid mutating provider state during build.
    Future.microtask(() {
      final notifier = ref.read(devicePreferenceProvider.notifier);
      if (notifier.state != devicePreference) {
        notifier.state = devicePreference;
      }
    });

    // Select an explicit ThemeMode from the resolved brightness so the dark
    // default (unspecified preference) is honored rather than ThemeMode.system.
    final resolvedBrightness = ThemeResolver.resolve(devicePreference);
    final themeMode =
        resolvedBrightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'ED-Operador',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

/// Native device identification for selecting the printing strategy.
///
/// Reads `Build.MANUFACTURER` and `Build.MODEL` from the native side to detect
/// whether the app is running on a Telpo M1 POS terminal (which has a built-in
/// thermal printer) versus a generic device that must use an external
/// Bluetooth printer.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/printer_strategy.dart';
import 'transport/printer_channel.dart';

/// Detects the device and resolves the appropriate [PrinterStrategy].
class DeviceInfo {
  const DeviceInfo();

  /// Reads the device manufacturer and model, returning a lowercase map with
  /// keys `manufacturer` and `model`. Returns empty strings on failure.
  Future<({String manufacturer, String model})> read() async {
    try {
      final result = await xprinterChannel
          .invokeMethod<Map<Object?, Object?>>('getDeviceInfo');
      final manufacturer =
          (result?['manufacturer'] as String?)?.toLowerCase().trim() ?? '';
      final model = (result?['model'] as String?)?.toLowerCase().trim() ?? '';
      return (manufacturer: manufacturer, model: model);
    } on PlatformException catch (e) {
      debugPrint('[DeviceInfo] getDeviceInfo failed: ${e.code}');
      return (manufacturer: '', model: '');
    }
  }

  /// Resolves the [PrinterStrategy] for the current device.
  ///
  /// Returns [PrinterStrategy.telpo] when the device is identified as a Telpo
  /// M1 (manufacturer contains "telpo", or the model matches the M1 family);
  /// otherwise [PrinterStrategy.standard].
  Future<PrinterStrategy> resolveStrategy() async {
    final info = await read();
    debugPrint(
      '[DeviceInfo] manufacturer="${info.manufacturer}", model="${info.model}"',
    );

    final isTelpo = info.manufacturer.contains('telpo') ||
        info.model.contains('telpo') ||
        info.model == 'm1' ||
        info.model.startsWith('m1 ') ||
        info.model.contains('tps');

    final strategy =
        isTelpo ? PrinterStrategy.telpo : PrinterStrategy.standard;
    debugPrint('[DeviceInfo] resolved strategy=$strategy');
    return strategy;
  }
}

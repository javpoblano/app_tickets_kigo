/// Bonded-device discovery for the Xprinter module.
///
/// Lists the OS-level bonded (paired) Bluetooth devices and locates one by MAC.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/printer_models.dart';
import 'printer_channel.dart';

/// Discovers bonded printers via the native platform channel.
class DeviceDiscovery {
  /// Returns the bonded devices as [PrinterDevice]s (empty if none).
  ///
  /// Throws a [PrinterException] if Bluetooth is unavailable/disabled or the
  /// required permission is missing.
  Future<List<PrinterDevice>> listBondedPrinters() async {
    try {
      final result =
          await xprinterChannel.invokeMethod<List<Object?>>('getBondedDevices');
      debugPrint('[Discovery] getBondedDevices raw count=${result?.length ?? 0}');
      if (result == null) return const <PrinterDevice>[];
      final devices = result
          .whereType<Map<Object?, Object?>>()
          .map(PrinterDevice.fromMap)
          .toList(growable: false);
      for (final d in devices) {
        debugPrint('[Discovery] bonded device: "${d.name}" / ${d.macAddress}');
      }
      return devices;
    } on PlatformException catch (e) {
      debugPrint('[Discovery] getBondedDevices FAILED — code=${e.code}, '
          'msg=${e.message}');
      throw PrinterException(
        e.code,
        e.code == 'bluetooth_unavailable'
            ? 'El Bluetooth está apagado. Actívalo e intenta de nuevo.'
            : 'No pudimos leer los dispositivos emparejados. Concede los permisos de Bluetooth e intenta de nuevo.',
      );
    }
  }

  /// Finds a bonded printer by [macAddress] (case-insensitive).
  ///
  /// Returns `null` when no bonded device matches.
  Future<PrinterDevice?> findByMac(String macAddress) async {
    final target = macAddress.toUpperCase();
    final devices = await listBondedPrinters();
    for (final device in devices) {
      if (device.macAddress.toUpperCase() == target) return device;
    }
    return null;
  }
}

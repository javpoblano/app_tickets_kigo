/// Runtime Bluetooth permission handling for the Xprinter module.
///
/// On Android API 31+ requests `BLUETOOTH_CONNECT` + `BLUETOOTH_SCAN`; on
/// API 30 and below requests location (required for classic Bluetooth access).
library;

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'transport/printer_channel.dart';

/// Result of a permission request.
enum PrinterPermissionResult {
  /// All required permissions are granted.
  granted,

  /// At least one permission was denied.
  denied,

  /// At least one permission is permanently denied; the operator must enable
  /// it from system settings.
  permanentlyDenied,
}

/// Requests and verifies the Bluetooth permissions needed to print.
class PrinterPermissions {
  /// Ensures the permissions required by the running Android version.
  ///
  /// To print to an already-bonded printer, only `BLUETOOTH_CONNECT` is needed
  /// on API 31+ (`BLUETOOTH_SCAN` is only for discovering new devices, which
  /// this app does not do). On API 30 and below classic Bluetooth needs
  /// location. We request the scan permission opportunistically but only the
  /// connect permission is required to consider the result granted.
  Future<PrinterPermissionResult> ensure() async {
    final sdkInt = await _androidSdkInt();

    if (sdkInt >= 31) {
      // Request both, but only require CONNECT.
      final statuses = await <Permission>[
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
      ].request();

      final connect = statuses[Permission.bluetoothConnect];
      if (connect != null && connect.isGranted) {
        return PrinterPermissionResult.granted;
      }
      if (connect != null && connect.isPermanentlyDenied) {
        return PrinterPermissionResult.permanentlyDenied;
      }
      return PrinterPermissionResult.denied;
    }

    // API 30 and below: classic Bluetooth requires location.
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) return PrinterPermissionResult.granted;
    if (status.isPermanentlyDenied) {
      return PrinterPermissionResult.permanentlyDenied;
    }
    return PrinterPermissionResult.denied;
  }

  Future<int> _androidSdkInt() async {
    try {
      final value = await xprinterChannel.invokeMethod<int>('getSdkInt');
      return value ?? 0;
    } on PlatformException {
      return 0;
    }
  }
}

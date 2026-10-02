import 'package:shared_preferences/shared_preferences.dart';

import 'package:ed_operador/printing/domain/printer_models.dart';

/// Persists the operator's selected Bluetooth printer (MAC + name) so the
/// choice is remembered across app restarts.
class PrinterPreferences {
  static const String _keyMac = 'selected_printer_mac';
  static const String _keyName = 'selected_printer_name';

  /// Saves the selected [device].
  Future<void> save(PrinterDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMac, device.macAddress);
    await prefs.setString(_keyName, device.name);
  }

  /// Returns the stored printer, or `null` if none has been selected.
  Future<PrinterDevice?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final mac = prefs.getString(_keyMac);
    if (mac == null || mac.isEmpty) return null;
    final name = prefs.getString(_keyName) ?? 'Impresora';
    return PrinterDevice(name: name, macAddress: mac);
  }

  /// Clears the stored printer selection.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyMac);
    await prefs.remove(_keyName);
  }
}

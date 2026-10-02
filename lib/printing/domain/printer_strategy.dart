/// The printing strategy to use, selected based on the running device.
///
/// - [standard] uses the external Bluetooth Classic (SPP) Xprinter via
///   [BluetoothPrinterService].
/// - [telpo] uses the built-in thermal printer of a Telpo M1 POS terminal via
///   the native Telpo SDK.
enum PrinterStrategy {
  /// External Bluetooth ESC/POS printer (Xprinter XP-P810).
  standard,

  /// Telpo M1 built-in thermal printer (native SDK).
  telpo;

  /// Human-readable label shown to the Operator (e.g. in the strategy toast).
  String get label => switch (this) {
        PrinterStrategy.standard => 'Estándar (Bluetooth)',
        PrinterStrategy.telpo => 'Telpo M1 (integrada)',
      };
}

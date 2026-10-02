/// Prints a parking ticket (including its QR code) on a Bluetooth thermal
/// printer.
///
/// Implementations target the XP-P810 (Xprinter) ESC/POS Bluetooth printer.
/// The flow first verifies the printer is connected ([isConnected]); if it is
/// not, the caller warns the Operator and does not attempt to print. When a
/// print fails, [printTicketQr] throws a [PrinterException] so the caller can
/// prompt the Operator to retry.
abstract class PrinterService {
  /// Returns `true` when a Bluetooth printer connection is currently
  /// established, `false` otherwise.
  Future<bool> isConnected();

  /// Prints a ticket receipt containing a QR code encoding [qrData].
  ///
  /// [title] is an optional human-readable heading printed above the QR code
  /// (for example the ticket type). Throws [PrinterNotConnectedException] when
  /// no printer is connected and [PrinterException] when the print operation
  /// fails for any other reason.
  Future<void> printTicketQr({required String qrData, String? title});
}

/// Base class for printer failures.
class PrinterException implements Exception {
  final String message;

  const PrinterException([this.message = 'The ticket could not be printed.']);

  @override
  String toString() => 'PrinterException: $message';
}

/// Thrown when a print is attempted but no Bluetooth printer is connected.
class PrinterNotConnectedException extends PrinterException {
  const PrinterNotConnectedException([
    super.message = 'No Bluetooth printer is connected.',
  ]);

  @override
  String toString() => 'PrinterNotConnectedException: $message';
}

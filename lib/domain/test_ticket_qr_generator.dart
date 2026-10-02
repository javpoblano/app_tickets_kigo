import 'package:ed_operador/domain/qr_code_generator.dart';

/// Generates a test ticket QR code locally without requiring a session or
/// backend registration.
///
/// Intended exclusively for debug builds so operators can verify the printer
/// connection and QR output without hitting the web service. Uses a fixed
/// parking-lot key code and pluma to produce a deterministic-format QR string
/// via [QrCodeGenerator].
class TestTicketQrGenerator {
  const TestTicketQrGenerator._();

  /// Default parking-lot key code used for test tickets.
  static const String _testParkingLotKeyCode = 'TEST';

  /// Default pluma/gate used for test tickets.
  static const String _testPlumaId = '0';

  /// Generates a test QR code string using a fixed parking-lot key and the
  /// current timestamp.
  ///
  /// The output follows the same format as production QR codes but is easily
  /// identifiable by the `TEST` parking-lot key and pluma `0`.
  static String generate({DateTime? now}) {
    return QrCodeGenerator.generate(
      parkingLotKeyCode: _testParkingLotKeyCode,
      plumaId: _testPlumaId,
      now: now,
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:telpo_flutter_sdk/telpo_flutter_sdk.dart';

import 'package:ed_operador/printing/data/protocol/qr_image_encoder.dart';
import 'package:ed_operador/printing/domain/ticket_receipt_content.dart';
import 'package:ed_operador/services/printer_service.dart';

/// [PrinterService] for the Telpo M1 built-in thermal printer.
///
/// Delegates to the `telpo_flutter_sdk` plugin ([TelpoFlutterChannel]). The
/// Telpo printer is integrated in the device (no Bluetooth pairing). The QR is
/// rasterized to a PNG via [QrImageEncoder] and printed through
/// `PrintData.byte`, since the plugin has no native QR primitive.
class TelpoPrinterService implements PrinterService {
  TelpoPrinterService({TelpoFlutterChannel? channel})
      : _telpo = channel ?? TelpoFlutterChannel();

  final TelpoFlutterChannel _telpo;

  @override
  Future<bool> isConnected() async {
    try {
      // On the M1 the printer is built in; connect() runs start()+reset() and
      // returns whether the device is ready to print.
      final connected = await _telpo.connect();
      debugPrint('[TelpoPrinterService] connect()=$connected');
      return connected;
    } catch (e) {
      debugPrint('[TelpoPrinterService] connect() failed: $e');
      return false;
    }
  }

  @override
  Future<void> printTicketQr({required String qrData, String? title}) async {
    debugPrint('[TelpoPrinterService] printTicketQr() — qrData=$qrData');

    // Reconnect before EVERY print. The native plugin calls stop() at the end
    // of each print job, which leaves the printer unusable until start() runs
    // again. connect() performs start()+reset(), so calling it here makes each
    // ticket print reliably (fixes "prints once, then nothing").
    final connected = await _telpo.connect();
    debugPrint('[TelpoPrinterService] connect()=$connected');
    if (!connected) {
      throw const PrinterNotConnectedException(
        'La impresora Telpo no está disponible en este dispositivo.',
      );
    }

    // Build the sheet: header text, QR image, then footer text, then bottom
    // padding.
    final sheet = TelpoPrintSheet();

    // 1. Header line(s) above the QR.
    for (final line in ticketHeaderLines) {
      sheet.addElement(
        PrintData.text(
          line,
          alignment: PrintAlignment.center,
          fontSize: PrintedFontSize.size24,
        ),
      );
    }
    sheet.addElement(PrintData.space(line: 1));

    // 2. QR code as a centered PNG image. Use a moderate module size so the
    // bitmap the native printLogo() renders is not excessively large (which
    // can stall the print head over the internal bus).
    debugPrint('[TelpoPrinterService] encoding QR image...');
    final qrPng = QrImageEncoder.encode(qrData, pixelsPerModule: 6);
    debugPrint('[TelpoPrinterService] QR image=${qrPng.length} bytes');
    sheet.addElement(
      PrintData.byte(
        bytesList: [qrPng],
        alignment: PrintAlignment.center,
      ),
    );
    sheet.addElement(PrintData.space(line: 1));

    // 3. Footer line(s) below the QR.
    for (final line in ticketFooterLines) {
      sheet.addElement(
        PrintData.text(
          line,
          alignment: PrintAlignment.center,
          fontSize: PrintedFontSize.size18,
        ),
      );
    }

    // Bottom padding so the ticket clears the tear bar (9 lines).
    sheet.addElement(PrintData.space(line: 9));

    debugPrint('[TelpoPrinterService] sending sheet to printer...');
    final PrintResult result = await _telpo.print(sheet);
    debugPrint('[TelpoPrinterService] print result=$result');

    switch (result) {
      case PrintResult.success:
        return;
      case PrintResult.noPaper:
        throw const PrinterException(
          'La impresora Telpo se quedó sin papel. Coloca un rollo e intenta de nuevo.',
        );
      case PrintResult.lowBattery:
        throw const PrinterException(
          'Batería insuficiente para imprimir. Conecta el dispositivo e intenta de nuevo.',
        );
      case PrintResult.overHeat:
        throw const PrinterException(
          'La impresora Telpo se sobrecalentó. Espera unos segundos e intenta de nuevo.',
        );
      case PrintResult.dataCanNotBeTransmitted:
        throw const PrinterException(
          'La impresora Telpo no estaba lista. Intenta de nuevo.',
        );
      case PrintResult.other:
        throw const PrinterException(
          'No se pudo imprimir el ticket en la impresora Telpo.',
        );
    }
  }
}

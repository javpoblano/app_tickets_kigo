/// Connect-then-print orchestration for the Xprinter module.
///
/// Reproduces the "connect, then print" flow: if not connected, it connects
/// first (10 s budget on the native side), writes the init command once, then
/// writes every printable's byte blocks in order.
///
/// If the connection appears live but the first write fails (stale socket), the
/// orchestrator reconnects and retries the entire job once.
library;

import 'package:flutter/foundation.dart';

import '../domain/printer_models.dart';
import 'protocol/esc_pos_encoder.dart';
import 'transport/bluetooth_spp_transport.dart';

/// Drives a full print job over a [BluetoothSppTransport].
class PrintOrchestrator {
  PrintOrchestrator({
    required BluetoothSppTransport transport,
    EscPosEncoder? encoder,
  })  : _transport = transport,
        _encoder = encoder ?? EscPosEncoder();

  final BluetoothSppTransport _transport;
  final EscPosEncoder _encoder;

  /// Prints [template] on [device], connecting first if needed.
  ///
  /// If a write fails due to a stale connection, reconnects and retries once.
  /// Throws a [PrinterException] if the connection cannot be established or is
  /// lost mid-print on the retry attempt.
  Future<void> printReceipt(
    PrinterDevice device,
    List<Printable> template,
  ) async {
    debugPrint('[Orchestrator] printReceipt() — device=${device.macAddress}, '
        'transport.state=${_transport.state}, template.length=${template.length}');
    try {
      await _doPrint(device, template);
    } on PrinterException catch (e) {
      debugPrint('[Orchestrator] first attempt failed: ${e.code} — ${e.message}');
      debugPrint('[Orchestrator] resetting state and retrying...');
      // The connection was likely stale. Reconnect and retry once.
      _transport.resetState();
      await _doPrint(device, template);
      debugPrint('[Orchestrator] retry succeeded');
    }
  }

  Future<void> _doPrint(
    PrinterDevice device,
    List<Printable> template,
  ) async {
    if (_transport.state != PrinterConnectionState.connected) {
      debugPrint('[Orchestrator] _doPrint: not connected, connecting to ${device.macAddress}...');
      await _transport.connect(device);
      debugPrint('[Orchestrator] _doPrint: connected successfully');
    } else {
      debugPrint('[Orchestrator] _doPrint: already connected, skipping connect');
    }

    // ESC @ exactly once, before any printable block.
    debugPrint('[Orchestrator] _doPrint: writing ESC @ init');
    await _transport.write(_encoder.init());

    var blockIndex = 0;
    for (final printable in template) {
      final blocks = _encoder.encode(printable);
      for (final block in blocks) {
        await _transport.write(block);
        blockIndex++;
      }
    }
    debugPrint('[Orchestrator] _doPrint: all $blockIndex blocks written successfully');
  }
}

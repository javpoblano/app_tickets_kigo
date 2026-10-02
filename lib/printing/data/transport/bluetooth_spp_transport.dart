/// Bluetooth Classic RFCOMM/SPP transport for the Xprinter module.
///
/// Wraps the native platform channel that opens an insecure RFCOMM socket to
/// the SPP UUID and writes raw bytes.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/printer_models.dart';
import 'printer_channel.dart';

/// Manages the SPP connection lifecycle and raw byte writes.
class BluetoothSppTransport {
  PrinterConnectionState _state = PrinterConnectionState.none;
  final StreamController<PrinterConnectionState> _stateController =
      StreamController<PrinterConnectionState>.broadcast();

  /// Current connection state.
  PrinterConnectionState get state => _state;

  /// Stream of connection-state transitions (one event per change).
  Stream<PrinterConnectionState> get stateStream => _stateController.stream;

  void _setState(PrinterConnectionState next) {
    if (_state == next) return;
    _state = next;
    _stateController.add(next);
  }

  /// Connects to a bonded [device] over insecure RFCOMM/SPP.
  ///
  /// Throws a [PrinterException] describing the failure.
  Future<void> connect(PrinterDevice device) async {
    debugPrint('[Transport] connect(${device.macAddress}) — current state=$_state');
    _setState(PrinterConnectionState.connecting);
    try {
      await xprinterChannel.invokeMethod<void>(
        'connect',
        <String, dynamic>{'address': device.macAddress},
      );
      _setState(PrinterConnectionState.connected);
      debugPrint('[Transport] connect SUCCESS — state=$_state');
    } on PlatformException catch (e) {
      _setState(PrinterConnectionState.none);
      debugPrint('[Transport] connect FAILED — code=${e.code}, msg=${e.message}');
      throw PrinterException(e.code, _messageForConnect(e.code));
    }
  }

  /// Maximum bytes sent per native write call. Larger payloads are split so a
  /// single oversized RFCOMM write cannot stall the socket.
  static const int _maxChunkBytes = 2048;

  /// Writes a raw byte [block] to the socket.
  ///
  /// Only has effect while `connected`. An empty block is a no-op. Payloads
  /// larger than [_maxChunkBytes] are split into standalone copies (never
  /// buffer views — a `Uint8List` view is unsafe to send over the platform
  /// channel) with a brief pause so the printer can drain its buffer.
  Future<void> write(Uint8List block) async {
    if (_state != PrinterConnectionState.connected) {
      debugPrint('[Transport] write SKIPPED — state=$_state (not connected)');
      return;
    }
    if (block.isEmpty) return;

    try {
      if (block.length <= _maxChunkBytes) {
        await xprinterChannel.invokeMethod<void>(
          'write',
          <String, dynamic>{'bytes': block},
        );
        return;
      }

      debugPrint('[Transport] chunking write of ${block.length} bytes '
          '(${_maxChunkBytes}B chunks)');
      for (var offset = 0; offset < block.length; offset += _maxChunkBytes) {
        final end = (offset + _maxChunkBytes < block.length)
            ? offset + _maxChunkBytes
            : block.length;
        // Copy into a fresh, zero-offset Uint8List so the platform channel
        // sends exactly these bytes (a sublistView can serialize its whole
        // backing buffer).
        final chunk = Uint8List.fromList(block.sublist(offset, end));
        await xprinterChannel.invokeMethod<void>(
          'write',
          <String, dynamic>{'bytes': chunk},
        );
        // Give the printer time to drain its buffer over the slow SPP link.
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    } on PlatformException catch (e) {
      debugPrint('[Transport] write FAILED — code=${e.code}, msg=${e.message}, '
          'block.length=${block.length}');
      _setState(PrinterConnectionState.none);
      throw PrinterException(
        e.code,
        'Se perdió la conexión con la impresora. Vuelve a conectarla e intenta de nuevo.',
      );
    }
  }

  /// Closes the socket and returns to `none`.
  Future<void> disconnect() async {
    debugPrint('[Transport] disconnect() — current state=$_state');
    try {
      await xprinterChannel.invokeMethod<void>('disconnect');
    } on PlatformException catch (e) {
      debugPrint('[Transport] disconnect platform error: ${e.code}');
      // Ignore: disconnect is best-effort.
    } finally {
      _setState(PrinterConnectionState.none);
    }
  }

  /// Resets the Dart-side connection state to `none` without calling the native
  /// disconnect. Use when the socket was already closed by the remote side or
  /// by a failed write.
  void resetState() {
    debugPrint('[Transport] resetState() — was=$_state, now=none');
    _setState(PrinterConnectionState.none);
  }

  /// Releases the state stream.
  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
  }

  String _messageForConnect(String code) {
    return switch (code) {
      'not_paired' =>
        'La impresora no está emparejada. Emparéjala en los ajustes de Bluetooth e intenta de nuevo.',
      'bluetooth_unavailable' =>
        'El Bluetooth está apagado. Actívalo e intenta de nuevo.',
      'timeout' =>
        'No pudimos conectar con la impresora. Verifica que esté encendida y cerca, e intenta de nuevo.',
      'permission_denied' =>
        'Faltan permisos de Bluetooth. Concédelos e intenta de nuevo.',
      _ =>
        'No pudimos conectar con la impresora. Verifica que esté encendida e intenta de nuevo.',
    };
  }
}

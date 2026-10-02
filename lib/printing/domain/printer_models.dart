/// Domain models for the Xprinter ESC/POS printing module.
///
/// Framework-agnostic value objects used by the encoder, template builder,
/// transport and orchestrator.
library;

import 'dart:typed_data';

/// Text alignment parameter for the `ESC a` command.
enum PrinterAlignment {
  /// Left aligned — byte `0x00`.
  left,

  /// Center aligned — byte `0x01`.
  center,

  /// Right aligned — byte `0x02`.
  right,
}

/// Font style parameter for the `ESC !` command.
enum PrinterTextStyle {
  /// Normal style — byte `0x00`.
  normal,

  /// Small style — byte `0x01`.
  small,

  /// Bold style — byte `0x08`.
  bold,

  /// Double width — byte `0x20`.
  doubleWidth,
}

/// Line-feed byte appended per text block.
enum FeedLine {
  /// New line — byte `0x0A`.
  newLine,

  /// Tab — byte `0x09`.
  tab,

  /// Carriage return — byte `0x0D`.
  carriageReturn,
}

/// A single printable operation of the receipt.
sealed class Printable {
  const Printable();
}

/// A line of text to print.
class TextPrintable extends Printable {
  const TextPrintable(
    this.text, {
    this.alignment = PrinterAlignment.left,
    this.feedLine = FeedLine.newLine,
    this.style = PrinterTextStyle.normal,
  });

  /// Raw text (sanitised at encode time).
  final String text;

  /// Alignment of the line.
  final PrinterAlignment alignment;

  /// Feed byte emitted before the text (reference behaviour).
  final FeedLine feedLine;

  /// Font style of the line.
  final PrinterTextStyle style;
}

/// An image to print as `GS v 0` raster data.
class ImagePrintable extends Printable {
  const ImagePrintable(
    this.rasterData, {
    this.alignment = PrinterAlignment.center,
    this.newLinesAfter = 0,
  });

  /// Fully encoded `GS v 0` block (header + packed bitmap).
  final Uint8List rasterData;

  /// Alignment of the image.
  final PrinterAlignment alignment;

  /// Number of blank lines to feed after the image (0..255).
  final int newLinesAfter;
}

/// A bonded printer selected by the operator.
class PrinterDevice {
  const PrinterDevice({required this.name, required this.macAddress});

  /// Builds a [PrinterDevice] from a platform-channel map.
  factory PrinterDevice.fromMap(Map<Object?, Object?> map) {
    return PrinterDevice(
      name: (map['name'] as String?)?.trim().isNotEmpty == true
          ? map['name'] as String
          : 'Impresora sin nombre',
      macAddress: map['address'] as String? ?? '',
    );
  }

  /// Human-readable device name (e.g. "XP-P323B").
  final String name;

  /// Bluetooth MAC address (e.g. "DC:0D:30:AA:BB:CC").
  final String macAddress;

  @override
  bool operator ==(Object other) =>
      other is PrinterDevice && other.macAddress == macAddress;

  @override
  int get hashCode => macAddress.hashCode;
}

/// Connection lifecycle state of the Bluetooth SPP transport.
enum PrinterConnectionState {
  /// No connection.
  none,

  /// Connection attempt in progress.
  connecting,

  /// Socket connected and ready to receive bytes.
  connected,
}

/// Error raised by the printer transport / orchestration layer.
class PrinterException implements Exception {
  const PrinterException(this.code, this.message);

  /// Machine-readable error code (e.g. `not_paired`, `timeout`).
  final String code;

  /// Operator-facing message.
  final String message;

  @override
  String toString() => 'PrinterException($code): $message';
}

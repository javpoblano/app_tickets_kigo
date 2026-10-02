/// QR code raster encoder for ESC/POS thermal printing.
///
/// Generates the `GS v 0` raster bit-image command block from a QR data string.
/// Each QR module is scaled by [pixelsPerModule] so the printed image is large
/// enough to be scanned reliably from a 58mm receipt.
library;

import 'dart:typed_data';

import 'package:qr/qr.dart';

/// Encodes a QR code string into a complete `GS v 0` ESC/POS raster block.
class QrRasterEncoder {
  const QrRasterEncoder._();

  /// Default pixels (dots) per QR module. 8 gives a good scannable size on
  /// 58mm (384-dot-wide) printers.
  static const int defaultPixelsPerModule = 8;

  /// Generates the full `GS v 0` raster byte block for [data].
  ///
  /// [pixelsPerModule] controls how many printer dots each QR module occupies.
  /// [errorCorrection] defaults to Level M (15% recovery).
  ///
  /// The returned [Uint8List] is ready to be written directly to the printer
  /// transport as an [ImagePrintable.rasterData].
  static Uint8List encode(
    String data, {
    int pixelsPerModule = defaultPixelsPerModule,
    int errorCorrection = QrErrorCorrectLevel.M,
  }) {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: errorCorrection,
    );
    final qrImage = QrImage(qrCode);
    final matrix = qrImage.moduleCount;

    // Total image dimensions in dots.
    final imageWidth = matrix * pixelsPerModule;
    final imageHeight = matrix * pixelsPerModule;

    // ESC/POS `GS v 0` expects width in *bytes* (8 dots per byte).
    final widthBytes = (imageWidth + 7) ~/ 8;

    // Build the 1-bpp raster row data: a dark module = bit 1, light = bit 0.
    final rasterRows = <int>[];
    for (var moduleY = 0; moduleY < matrix; moduleY++) {
      // Each module row repeats [pixelsPerModule] times vertically.
      final rowBytes = _encodeRow(qrImage, moduleY, matrix, pixelsPerModule, widthBytes);
      for (var repeat = 0; repeat < pixelsPerModule; repeat++) {
        rasterRows.addAll(rowBytes);
      }
    }

    // Assemble the GS v 0 command:
    // 0x1D 0x76 0x30 m xL xH yL yH [raster data]
    // m = 0 (normal density), xL xH = widthBytes, yL yH = imageHeight
    final header = <int>[
      0x1D, 0x76, 0x30, 0x00, // GS v 0, mode 0
      widthBytes & 0xFF, (widthBytes >> 8) & 0xFF, // xL, xH
      imageHeight & 0xFF, (imageHeight >> 8) & 0xFF, // yL, yH
    ];

    return Uint8List.fromList(<int>[...header, ...rasterRows]);
  }

  /// Encodes a single module-row into [widthBytes] bytes of 1-bpp raster data.
  static List<int> _encodeRow(
    QrImage qrImage,
    int moduleY,
    int moduleCount,
    int pixelsPerModule,
    int widthBytes,
  ) {
    final row = List<int>.filled(widthBytes, 0);

    for (var moduleX = 0; moduleX < moduleCount; moduleX++) {
      final isDark = qrImage.isDark(moduleY, moduleX);
      if (!isDark) continue;

      // Fill [pixelsPerModule] consecutive bits starting at
      // moduleX * pixelsPerModule.
      final startBit = moduleX * pixelsPerModule;
      for (var px = 0; px < pixelsPerModule; px++) {
        final bitIndex = startBit + px;
        final byteIndex = bitIndex ~/ 8;
        final bitPosition = 7 - (bitIndex % 8); // MSB first
        row[byteIndex] |= (1 << bitPosition);
      }
    }

    return row;
  }
}

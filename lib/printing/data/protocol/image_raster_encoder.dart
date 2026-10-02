/// Converts a decodable raster image (PNG/JPEG bytes) into ESC/POS `GS v 0`
/// raster blocks for the Bluetooth Xprinter path.
///
/// The image is decoded, scaled to fit the printer width, converted to 1-bpp
/// (black/white via luminance threshold), and emitted as a series of small
/// horizontal bands. Splitting into bands keeps each `GS v 0` command well
/// within the printer's per-command height limit and avoids a single oversized
/// RFCOMM write stalling the socket (a common cause of tall images not
/// printing).
library;

import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Encodes image bytes into concatenated ESC/POS `GS v 0` raster blocks.
class ImageRasterEncoder {
  const ImageRasterEncoder._();

  /// Default printer dot width for a 58mm head (many XP models are 384).
  static const int defaultMaxWidthDots = 384;

  /// Luminance threshold (0..255) below which a pixel is printed black.
  static const int defaultThreshold = 128;

  /// Number of dot-rows per `GS v 0` band. Small bands stay within the
  /// printer's per-command limit and keep each socket write small.
  static const int defaultBandHeight = 24;

  /// Decodes [bytes] (PNG/JPEG) and returns concatenated `GS v 0` bands.
  ///
  /// The image is scaled down to [maxWidthDots] (never scaled up) preserving
  /// aspect ratio. Pixels darker than [threshold] become black dots.
  static Uint8List encode(
    Uint8List bytes, {
    int maxWidthDots = defaultMaxWidthDots,
    int threshold = defaultThreshold,
    int bandHeight = defaultBandHeight,
  }) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw ArgumentError('No se pudo decodificar la imagen del boleto.');
    }

    // Scale to the printer width (only shrink, never enlarge).
    img.Image image = decoded;
    if (image.width > maxWidthDots) {
      image = img.copyResize(image, width: maxWidthDots);
    }

    final width = image.width;
    final height = image.height;
    final widthBytes = (width + 7) ~/ 8;

    final out = <int>[];

    for (var bandTop = 0; bandTop < height; bandTop += bandHeight) {
      final bandRows =
          (bandTop + bandHeight <= height) ? bandHeight : height - bandTop;

      // Pack this band's rows into 1-bpp raster (MSB first).
      final raster = List<int>.filled(widthBytes * bandRows, 0);
      for (var row = 0; row < bandRows; row++) {
        final y = bandTop + row;
        for (var x = 0; x < width; x++) {
          final pixel = image.getPixel(x, y);
          final luminance = img.getLuminance(pixel);
          final alpha = pixel.a;
          final isBlack = alpha > 16 && luminance < threshold;
          if (!isBlack) continue;
          final byteIndex = row * widthBytes + (x >> 3);
          final bitPosition = 7 - (x & 0x07);
          raster[byteIndex] |= (1 << bitPosition);
        }
      }

      // GS v 0 header for this band: 0x1D 0x76 0x30 m xL xH yL yH
      out.addAll(<int>[
        0x1D, 0x76, 0x30, 0x00,
        widthBytes & 0xFF, (widthBytes >> 8) & 0xFF,
        bandRows & 0xFF, (bandRows >> 8) & 0xFF,
      ]);
      out.addAll(raster);
    }

    return Uint8List.fromList(out);
  }
}

/// Renders a QR code string to PNG image bytes.
///
/// Used by the Telpo printing strategy: the telpo_flutter_sdk prints images via
/// `PrintData.byte`, so the QR is rasterized to a monochrome PNG rather than
/// emitted as ESC/POS raster (which is used by the Bluetooth Xprinter path).
library;

import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:qr/qr.dart';

/// Encodes QR data into PNG bytes suitable for `PrintData.byte`.
class QrImageEncoder {
  const QrImageEncoder._();

  /// Default pixels (dots) per QR module.
  static const int defaultPixelsPerModule = 8;

  /// Default white quiet-zone border, in modules.
  static const int quietZoneModules = 4;

  /// Renders [data] to a black-on-white PNG [Uint8List].
  ///
  /// [pixelsPerModule] controls the size of each QR module in pixels.
  /// [errorCorrection] defaults to Level M (15% recovery).
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
    final modules = qrImage.moduleCount;

    final sizeInModules = modules + quietZoneModules * 2;
    final dimension = sizeInModules * pixelsPerModule;

    // Start with an all-white image.
    final image = img.Image(width: dimension, height: dimension);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));

    final black = img.ColorRgb8(0, 0, 0);

    for (var moduleY = 0; moduleY < modules; moduleY++) {
      for (var moduleX = 0; moduleX < modules; moduleX++) {
        if (!qrImage.isDark(moduleY, moduleX)) continue;

        final x0 = (moduleX + quietZoneModules) * pixelsPerModule;
        final y0 = (moduleY + quietZoneModules) * pixelsPerModule;
        img.fillRect(
          image,
          x1: x0,
          y1: y0,
          x2: x0 + pixelsPerModule - 1,
          y2: y0 + pixelsPerModule - 1,
          color: black,
        );
      }
    }

    return Uint8List.fromList(img.encodePng(image));
  }
}

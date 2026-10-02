/// ESC/POS encoder for the Xprinter printing module.
///
/// Translates each [Printable] into the exact ESC/POS byte blocks.
library;

import 'dart:typed_data';

import '../../domain/printer_models.dart';
import 'text_sanitizer.dart';

/// Serialises [Printable]s into ordered ESC/POS byte blocks.
class EscPosEncoder {
  /// Printer initialisation command `ESC @` (`0x1B 0x40`).
  static final Uint8List cmdInit = Uint8List.fromList(<int>[0x1B, 0x40]);

  /// Justification command prefix `ESC a` (`0x1B 0x61`).
  static final Uint8List _cmdJustification =
      Uint8List.fromList(<int>[0x1B, 0x61]);

  /// Font-size / style command prefix `ESC !` (`0x1B 0x21`).
  static final Uint8List _cmdFontSize = Uint8List.fromList(<int>[0x1B, 0x21]);

  /// Byte value for a [PrinterAlignment].
  static int alignByte(PrinterAlignment a) => switch (a) {
        PrinterAlignment.left => 0x00,
        PrinterAlignment.center => 0x01,
        PrinterAlignment.right => 0x02,
      };

  /// Byte value for a [PrinterTextStyle].
  static int styleByte(PrinterTextStyle s) => switch (s) {
        PrinterTextStyle.normal => 0x00,
        PrinterTextStyle.small => 0x01,
        PrinterTextStyle.bold => 0x08,
        PrinterTextStyle.doubleWidth => 0x20,
      };

  /// Byte value for a [FeedLine].
  static int feedByte(FeedLine f) => switch (f) {
        FeedLine.newLine => 0x0A,
        FeedLine.tab => 0x09,
        FeedLine.carriageReturn => 0x0D,
      };

  /// The initialisation block, emitted exactly once before any printable.
  Uint8List init() => cmdInit;

  /// Encodes a [TextPrintable] into ordered blocks.
  List<Uint8List> encodeText(TextPrintable p) {
    return <Uint8List>[
      _concat(_cmdJustification, alignByte(p.alignment)),
      Uint8List.fromList(<int>[feedByte(p.feedLine)]),
      _concat(_cmdFontSize, styleByte(p.style)),
      TextSanitizer.toIso8859_1(p.text),
    ];
  }

  /// Encodes an [ImagePrintable]: alignment block, raster data, optional feed.
  List<Uint8List> encodeImage(ImagePrintable p) {
    if (p.newLinesAfter < 0 || p.newLinesAfter > 255) {
      throw ArgumentError.value(
        p.newLinesAfter,
        'newLinesAfter',
        'debe estar entre 0 y 255',
      );
    }
    final ops = <Uint8List>[
      _concat(_cmdJustification, alignByte(p.alignment)),
      p.rasterData,
    ];
    if (p.newLinesAfter > 0) {
      ops.add(Uint8List.fromList(<int>[p.newLinesAfter]));
    }
    return ops;
  }

  /// Encodes any [Printable] into its ordered byte blocks.
  List<Uint8List> encode(Printable printable) => switch (printable) {
        TextPrintable p => encodeText(p),
        ImagePrintable p => encodeImage(p),
      };

  static Uint8List _concat(Uint8List base, int b) =>
      Uint8List.fromList(<int>[...base, b]);
}

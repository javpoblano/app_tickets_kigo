/// Receipt template builder for the Xprinter printing module.
///
/// Builds the ordered list of [Printable]s that compose a receipt.
library;

import '../../domain/printer_models.dart';

/// Fluent builder that assembles an ordered list of [Printable]s.
class ReceiptTemplateBuilder {
  final List<Printable> _items = <Printable>[];

  /// Adds a text line.
  ReceiptTemplateBuilder printLine(
    String text, {
    PrinterTextStyle style = PrinterTextStyle.normal,
    PrinterAlignment alignment = PrinterAlignment.left,
    FeedLine feedLine = FeedLine.newLine,
  }) {
    _items.add(
      TextPrintable(
        text,
        alignment: alignment,
        feedLine: feedLine,
        style: style,
      ),
    );
    return this;
  }

  /// Adds a key/value row: key in bold, value with a tab feed.
  ReceiptTemplateBuilder row(String key, String value) {
    if (key.trim().isNotEmpty) {
      printLine(key, style: PrinterTextStyle.bold);
    }
    if (value.trim().isNotEmpty) {
      printLine(value, feedLine: FeedLine.tab);
    }
    return this;
  }

  /// Feeds [lines] blank lines (paper advance).
  ReceiptTemplateBuilder feed([int lines = 1]) {
    for (var i = 0; i < lines; i++) {
      printLine('');
    }
    return this;
  }

  /// Returns the assembled, unmodifiable template in insertion order.
  List<Printable> build() => List<Printable>.unmodifiable(_items);
}

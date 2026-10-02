/// Text sanitiser for ESC/POS printing.
///
/// Replicates the reference implementation: uppercase → strip accents →
/// ISO-8859-1.
library;

import 'dart:convert';
import 'dart:typed_data';

/// Normalises text before printing: uppercase → strip accents → ISO-8859-1.
abstract final class TextSanitizer {
  /// Accent / special-character replacements applied after uppercasing.
  static const Map<String, String> _replacements = <String, String>{
    'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U',
    'Ü': 'U', 'Ñ': 'NI',
    'á': 'A', 'é': 'E', 'í': 'I', 'ó': 'O', 'ú': 'U',
    'ü': 'U', 'ñ': 'NI',
  };

  /// Sanitises [input] and returns its ISO-8859-1 (Latin-1) byte sequence.
  static Uint8List toIso8859_1(String input) {
    var t = input.toUpperCase();
    _replacements.forEach((from, to) => t = t.replaceAll(from, to));

    // Map any character outside Latin-1 to '?' (0x3F) before encoding.
    final buffer = StringBuffer();
    for (final unit in t.codeUnits) {
      buffer.writeCharCode(unit <= 0xFF ? unit : 0x3F);
    }
    return Uint8List.fromList(latin1.encode(buffer.toString()));
  }
}

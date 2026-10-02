/// Shared text content for the parking ticket receipt.
///
/// Both print strategies (Bluetooth Xprinter and Telpo M1) render the same
/// receipt: header line(s), then the QR code (rendered by each strategy in its
/// native way), then footer line(s). Centralizing the copy here keeps the two
/// implementations in sync.
library;

/// The lines printed above the QR code.
const List<String> ticketHeaderLines = <String>[
  'Tu aportacion contribuye a la operacion de programas sociales '
      'del Sistema DIF Santiago. Gracias.',
];

/// The lines printed below the QR code.
const List<String> ticketFooterLines = <String>[
  'El cobro es solamente por la renta del espacio para estacionamiento. '
      'No asumimos ninguna responsabilidad por robo o danos a su vehiculo '
      'o contenido',
  '',
  'Santiago. vida y orden.',
];

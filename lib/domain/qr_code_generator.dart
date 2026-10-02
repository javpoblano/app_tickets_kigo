/// Pure domain logic that builds the `qrCode` value sent to the
/// Ticket_Register_Endpoint.
///
/// The format mirrors the reference shell script:
///
/// ```
/// ${TYPE}${PARKING_ID}${PLUMA_ID}${monthChar}${dayChar}${hourChar}${minute}${second}
/// ```
///
/// where:
/// - `TYPE` is a fixed single-character prefix (default `B`).
/// - `PARKING_ID` is the operator's `parkingLotKeyCode`.
/// - `PLUMA_ID` is the gate/pluma identifier.
/// - `monthChar`  = [_alphabet]`[month - 1]`      (Jan → `A` … Dec → `L`).
/// - `dayChar`    = [_fullAlphabet]`[day]`         (day 1 → `1`, 10 → `A`, 31 → `V`).
/// - `hourChar`   = [_alphabet]`[hour]`            (0 → `A` … 23 → `X`).
/// - `minute`/`second` are the raw two-digit, zero-padded values.
///
/// The generator is pure and side-effect free: the timestamp is passed in as
/// [now], which keeps it deterministic and unit-/property-testable.
class QrCodeGenerator {
  const QrCodeGenerator._();

  /// 26-letter alphabet indexed for the month and hour components.
  static const String _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  /// 36-character alphabet (digits + letters) indexed for the day component.
  static const String _fullAlphabet = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  /// Default `TYPE` prefix used by the reference script.
  static const String defaultType = 'B';

  /// Builds the ticket `qrCode` for the given [parkingLotKeyCode] and
  /// [plumaId], using [now] as the reference timestamp.
  ///
  /// [type] defaults to [defaultType] (`B`). [now] defaults to
  /// `DateTime.now()`; pass an explicit value in tests for deterministic
  /// output.
  static String generate({
    required String parkingLotKeyCode,
    required String plumaId,
    DateTime? now,
    String type = defaultType,
  }) {
    final timestamp = now ?? DateTime.now();

    // Month 1..12 → alphabet index 0..11 (Jan → 'A', Dec → 'L').
    final monthChar = _alphabet[timestamp.month - 1];
    // Day 1..31 → full-alphabet index (day 1 → '1', 10 → 'A', 31 → 'V').
    final dayChar = _fullAlphabet[timestamp.day];
    // Hour 0..23 → alphabet index (0 → 'A', 23 → 'X').
    final hourChar = _alphabet[timestamp.hour];

    final minute = timestamp.minute.toString().padLeft(2, '0');
    final second = timestamp.second.toString().padLeft(2, '0');

    return '$type$parkingLotKeyCode$plumaId'
        '$monthChar$dayChar$hourChar$minute$second';
  }
}

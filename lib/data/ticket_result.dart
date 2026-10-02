import 'package:flutter/foundation.dart';

/// Decoded from the Ticket_Register_Endpoint response. Confirmation requires
/// both `checkin.success` and `checkout.success` to be `true`.
@immutable
class TicketResult {
  final bool checkinSuccess;
  final String? externalId;
  final bool checkoutSuccess;

  const TicketResult({
    required this.checkinSuccess,
    required this.externalId,
    required this.checkoutSuccess,
  });

  bool get isConfirmed => checkinSuccess && checkoutSuccess;

  factory TicketResult.fromJson(Map<String, dynamic> json) {
    final checkin = json['checkin'] as Map<String, dynamic>? ?? const {};
    final checkout = json['checkout'] as Map<String, dynamic>? ?? const {};
    return TicketResult(
      checkinSuccess: checkin['success'] as bool? ?? false,
      externalId: checkin['externalId'] as String?,
      checkoutSuccess: checkout['success'] as bool? ?? false,
    );
  }

  /// Decodes the response from the NAP Smart Access process endpoint.
  ///
  /// The process endpoint returns a flat result rather than checkin/checkout
  /// sub-objects. A `2xx` reaching this parser already indicates the ticket was
  /// processed, so this treats the result as confirmed unless the body
  /// explicitly reports a failure via a boolean `success`/`processed` flag set
  /// to `false`.
  factory TicketResult.fromProcessJson(Map<String, dynamic> json) {
    final explicitSuccess = json['success'] as bool? ??
        json['processed'] as bool? ??
        true;
    final externalId =
        json['externalId']?.toString() ?? json['id']?.toString();
    return TicketResult(
      checkinSuccess: explicitSuccess,
      externalId: externalId,
      checkoutSuccess: explicitSuccess,
    );
  }
}

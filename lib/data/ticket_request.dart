import 'package:flutter/foundation.dart';

/// The JSON body sent to the NAP Smart Access process endpoint
/// (`/v1/napsmartaccess/process`).
///
/// Shape:
/// ```json
/// {
///   "qrCode": "BYJ2025...",
///   "parkingLotId": 5,
///   "charge": true,
///   "napUserId": 7,
///   "checkOut": true,
///   "openGate": false,
///   "gateQrCode": "",
///   "validate": false
/// }
/// ```
///
/// For the current flow `charge` is always `true`, `checkOut` is always
/// `true`, `openGate` is always `false`, and `gateQrCode` is always an empty
/// string. `validate` is `false` for a regular ticket and `true` for a
/// promotion ticket.
@immutable
class TicketRequest {
  final int parkingLotId;
  final String qrCode;

  /// The id of the logged-in NAP user (from `session.user.id`).
  final int napUserId;

  /// Whether the ticket applies a promotion. Drives the `validate` field:
  /// `false` for a regular ticket, `true` for a promotion ticket.
  final bool applyPromotion;

  const TicketRequest({
    required this.parkingLotId,
    required this.qrCode,
    required this.napUserId,
    this.applyPromotion = false,
  });

  Map<String, dynamic> toJson() => {
        'qrCode': qrCode,
        'parkingLotId': parkingLotId,
        'charge': true,
        'napUserId': napUserId,
        'checkOut': true,
        'openGate': false,
        'gateQrCode': '',
        'validate': applyPromotion,
      };
}

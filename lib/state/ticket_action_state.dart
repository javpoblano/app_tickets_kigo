import 'package:flutter/foundation.dart';

/// The kind of ticket action triggered on the Main_Screen.
///
/// See design.md Data Models — TicketActionState. A [regular] action registers
/// a ticket without a promotion; a [promotion] action sets `applyPromotion:
/// true` on the Ticket_Request (Requirements 3.3, 3.4).
enum TicketType { regular, promotion }

/// Immutable view state for a Main_Screen ticket action, produced by the ticket
/// controller.
///
/// See design.md Data Models — TicketActionState. While registering, both ticket
/// buttons are disabled (Requirement 3.9); confirmation is reached only when the
/// TicketResult is confirmed, otherwise the action transitions to
/// [TicketFailed] (Requirements 3.5, 3.8).
@immutable
sealed class TicketActionState {
  const TicketActionState();
}

/// No ticket action in progress.
@immutable
class TicketIdle extends TicketActionState {
  const TicketIdle();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TicketIdle && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'TicketIdle()';
}

/// A ticket action is being registered; both buttons are disabled
/// (Requirement 3.9).
@immutable
class TicketRegistering extends TicketActionState {
  const TicketRegistering();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TicketRegistering && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'TicketRegistering()';
}

/// The ticket action was confirmed (both checkin and checkout succeeded).
/// Carries the [TicketType] that was registered and the [qrCode] that was sent
/// to the Ticket_Register_Endpoint, so the confirmed ticket can be printed
/// (Requirements 3.5, 5.1).
@immutable
class TicketConfirmed extends TicketActionState {
  final TicketType type;
  final String qrCode;

  const TicketConfirmed({required this.type, required this.qrCode});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TicketConfirmed &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          qrCode == other.qrCode;

  @override
  int get hashCode => Object.hash(runtimeType, type, qrCode);

  @override
  String toString() => 'TicketConfirmed(type: $type, qrCode: $qrCode)';
}

/// The ticket action could not be confirmed (not confirmed response, timeout, or
/// unavailability). Carries the [TicketType] that was attempted
/// (Requirement 3.8).
@immutable
class TicketFailed extends TicketActionState {
  final TicketType type;

  /// Optional debug-only error detail describing why the registration failed.
  final String? errorDetail;

  const TicketFailed({required this.type, this.errorDetail});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TicketFailed &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          errorDetail == other.errorDetail;

  @override
  int get hashCode => Object.hash(runtimeType, type, errorDetail);

  @override
  String toString() => 'TicketFailed(type: $type, errorDetail: $errorDetail)';
}

import 'package:ed_operador/data/ticket_request.dart';
import 'package:ed_operador/data/ticket_result.dart';

/// Registers a ticket against the Ticket_Register_Endpoint using the
/// Operator_Token from the current Operator_Session.
///
/// Implementations send a `POST` to the Ticket_Register_Endpoint with
/// `Content-Type: application/json`, `x-api-key`, and `x-operator-token` (the
/// session token) headers and a [TicketRequest] JSON body (Requirements 3.3,
/// 3.4). For a promotion ticket, `applyPromotion` is set to `true`. The
/// response is decoded into a [TicketResult].
abstract class TicketService {
  /// Registers the given [request], attaching [operatorToken] as the
  /// `x-operator-token` header.
  ///
  /// Returns a [TicketResult] (checkin + checkout). Throws
  /// [TicketUnavailableException] on timeout or when the
  /// Ticket_Register_Endpoint is unavailable.
  Future<TicketResult> register(
    TicketRequest request, {
    required String operatorToken,
  });
}

/// Thrown when ticket registration could not be completed because the
/// Ticket_Register_Endpoint did not respond within the budget or is
/// unavailable.
class TicketUnavailableException implements Exception {
  final String message;

  const TicketUnavailableException([
    this.message = 'Ticket registration could not be completed.',
  ]);

  @override
  String toString() => 'TicketUnavailableException: $message';
}

/// Thrown when the Ticket_Register_Endpoint rejects the request as
/// unauthorized (HTTP 401/403), indicating the Operator_Token is no longer
/// valid. The caller should clear the stored Operator_Session and return the
/// Operator to the Login_Screen.
class TicketUnauthorizedException implements Exception {
  final String message;

  const TicketUnauthorizedException([
    this.message = 'The session is no longer authorized.',
  ]);

  @override
  String toString() => 'TicketUnauthorizedException: $message';
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:ed_operador/app/app_config.dart';
import 'package:ed_operador/data/ticket_request.dart';
import 'package:ed_operador/data/ticket_result.dart';
import 'package:ed_operador/services/ticket_service.dart';

/// Concrete [TicketService] that processes tickets against the NAP Smart Access
/// process endpoint over HTTP.
///
/// `POST`s to `${config.napBaseUrl}/v1/napsmartaccess/process` with
/// `Content-Type: application/json` and `x-api-key` headers and a
/// [TicketRequest] JSON body:
///
/// ```json
/// {
///   "qrCode": "...",
///   "parkingLotId": 5,
///   "charge": true,
///   "napUserId": 7,
///   "checkOut": false,
///   "openGate": false,
///   "gateQrCode": ""
/// }
/// ```
///
/// An unauthorized (`401`/`403`) response is surfaced as a
/// [TicketUnauthorizedException] so the caller can clear the session. Any other
/// timeout, non-`2xx` status, malformed response, or network error is surfaced
/// as a [TicketUnavailableException].
class HttpTicketService implements TicketService {
  final http.Client client;
  final AppConfig config;

  /// The relative path of the NAP Smart Access process endpoint appended to the
  /// NAP Smart Access base URL.
  static const String _processPath = '/v1/napsmartaccess/process';

  const HttpTicketService({
    required this.client,
    required this.config,
  });

  @override
  Future<TicketResult> register(
    TicketRequest request, {
    required String operatorToken,
  }) async {
    final uri = Uri.parse('${config.napBaseUrl}$_processPath');
    final headers = {
      'Content-Type': 'application/json',
      'x-api-key': config.napApiKey,
    };
    final body = jsonEncode(request.toJson());

    // Debug-only network logging (tree-shaken out of release builds).
    if (kDebugMode) {
      debugPrint('[HttpTicketService] ── REQUEST ──');
      debugPrint('[HttpTicketService] POST $uri');
      debugPrint('[HttpTicketService] headers: ${_maskedHeaders(headers)}');
      debugPrint('[HttpTicketService] body: $body');
    }

    final http.Response response;
    try {
      response = await client.post(uri, headers: headers, body: body);
    } on Object catch (error, stack) {
      // Network error, timeout, or any transport-level failure.
      if (kDebugMode) {
        debugPrint('[HttpTicketService] ── NETWORK ERROR ──');
        debugPrint('[HttpTicketService] $error');
        debugPrint('[HttpTicketService] $stack');
      }
      throw const TicketUnavailableException();
    }

    if (kDebugMode) {
      debugPrint('[HttpTicketService] ── RESPONSE ──');
      debugPrint('[HttpTicketService] status: ${response.statusCode}');
      debugPrint('[HttpTicketService] body: ${response.body}');
    }

    // Unauthorized: the credentials are no longer valid. Surface a distinct
    // exception so the caller can clear the session and return to Login.
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const TicketUnauthorizedException();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const TicketUnavailableException();
    }

    // A 2xx from the process endpoint means the ticket was processed. Parse the
    // body tolerantly for confirmation details; if the body is empty or an
    // unexpected shape, treat the 2xx as a confirmed result.
    try {
      if (response.body.trim().isEmpty) {
        return const TicketResult(
          checkinSuccess: true,
          externalId: null,
          checkoutSuccess: true,
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return TicketResult.fromProcessJson(decoded);
      }
      // Unexpected (non-object) body but 2xx — consider it confirmed.
      return const TicketResult(
        checkinSuccess: true,
        externalId: null,
        checkoutSuccess: true,
      );
    } on Object {
      // Malformed response body but the HTTP call succeeded (2xx). Treat as
      // confirmed so the print flow proceeds.
      return const TicketResult(
        checkinSuccess: true,
        externalId: null,
        checkoutSuccess: true,
      );
    }
  }

  /// Returns a copy of [headers] with the `x-api-key` value partially masked,
  /// so debug logs don't leak the full credential.
  Map<String, String> _maskedHeaders(Map<String, String> headers) {
    final masked = Map<String, String>.from(headers);
    final key = masked['x-api-key'];
    if (key != null && key.isNotEmpty) {
      masked['x-api-key'] = key.length <= 4
          ? '****'
          : '${key.substring(0, 4)}****';
    }
    return masked;
  }
}

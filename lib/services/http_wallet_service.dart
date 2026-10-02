import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:ed_operador/app/app_config.dart';
import 'package:ed_operador/data/wallet.dart';
import 'package:ed_operador/services/wallet_service.dart';

/// Concrete [WalletService] that fetches the operator wallet over HTTP.
///
/// `GET`s `${config.backendBaseUrl}/v1/operator/wallet` with the
/// `x-operator-token` header (the Operator_Token), decodes the `wallets` array,
/// and returns the first wallet.
class HttpWalletService implements WalletService {
  final http.Client client;
  final AppConfig config;

  /// The relative path of the wallet endpoint appended to the Backend_API base
  /// URL.
  static const String _walletPath = '/operator/wallet';

  const HttpWalletService({
    required this.client,
    required this.config,
  });

  @override
  Future<Wallet?> fetchPrimaryWallet({required String operatorToken}) async {
    final uri = Uri.parse('${config.backendBaseUrl}$_walletPath');
    final headers = {
      'x-api-key': config.apiKey,
      'x-operator-token': operatorToken,
    };

    if (kDebugMode) {
      debugPrint('[HttpWalletService] ── REQUEST ──');
      debugPrint('[HttpWalletService] GET $uri');
      debugPrint('[HttpWalletService] backendBaseUrl="${config.backendBaseUrl}"');
      debugPrint('[HttpWalletService] headers: ${_maskedHeaders(headers)}');
      debugPrint(
        '[HttpWalletService] apiKey.isEmpty=${config.apiKey.isEmpty}, '
        'apiKey.length=${config.apiKey.length}',
      );
      debugPrint(
        '[HttpWalletService] operatorToken.isEmpty=${operatorToken.isEmpty}, '
        'operatorToken.length=${operatorToken.length}',
      );
    }

    final http.Response response;
    try {
      response = await client.get(uri, headers: headers);
    } on Object catch (error, stack) {
      if (kDebugMode) {
        debugPrint('[HttpWalletService] ── NETWORK ERROR ──');
        debugPrint('[HttpWalletService] error type: ${error.runtimeType}');
        debugPrint('[HttpWalletService] error: $error');
        debugPrint('[HttpWalletService] stack: $stack');
      }
      throw const WalletUnavailableException();
    }

    if (kDebugMode) {
      debugPrint('[HttpWalletService] ── RESPONSE ──');
      debugPrint('[HttpWalletService] status=${response.statusCode}');
      debugPrint('[HttpWalletService] headers=${response.headers}');
      debugPrint('[HttpWalletService] body=${response.body}');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      if (kDebugMode) {
        debugPrint('[HttpWalletService] → unauthorized (${response.statusCode})');
      }
      throw const WalletUnauthorizedException();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (kDebugMode) {
        debugPrint('[HttpWalletService] → non-2xx (${response.statusCode})');
      }
      throw const WalletUnavailableException();
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final wallets = decoded['wallets'] as List<dynamic>? ?? const [];
      if (kDebugMode) {
        debugPrint('[HttpWalletService] parsed wallets count=${wallets.length}');
      }
      if (wallets.isEmpty) return null;
      final first = wallets.first as Map<String, dynamic>;
      final wallet = Wallet.fromJson(first);
      if (kDebugMode) {
        debugPrint(
          '[HttpWalletService] → wallet funds=${wallet.funds} '
          '${wallet.currency}',
        );
      }
      return wallet;
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint('[HttpWalletService] parse error: $error');
      }
      throw const WalletUnavailableException();
    }
  }

  /// Returns a copy of [headers] with the `x-api-key` value partially masked so
  /// debug logs don't leak the full credential.
  Map<String, String> _maskedHeaders(Map<String, String> headers) {
    final masked = Map<String, String>.from(headers);
    final key = masked['x-api-key'];
    if (key != null && key.isNotEmpty) {
      masked['x-api-key'] =
          key.length <= 4 ? '****' : '${key.substring(0, 4)}****';
    }
    final token = masked['x-operator-token'];
    if (token != null && token.isNotEmpty) {
      masked['x-operator-token'] =
          token.length <= 6 ? '****' : '${token.substring(0, 6)}****';
    }
    return masked;
  }
}

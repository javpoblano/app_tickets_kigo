import 'package:flutter/foundation.dart';

/// A single operator wallet returned by the wallet endpoint
/// (`GET /operator/wallet`).
///
/// Only the fields the app displays are modeled; the rest of the payload is
/// ignored. [funds] is the available balance and [currency] its currency code
/// (e.g. `mxn`).
@immutable
class Wallet {
  final int id;
  final int userId;
  final String accountNumber;
  final double funds;
  final String currency;

  const Wallet({
    required this.id,
    required this.userId,
    required this.accountNumber,
    required this.funds,
    required this.currency,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        id: _asInt(json['id']),
        userId: _asInt(json['userId']),
        accountNumber: _asString(json['accountNumber']),
        funds: _asDouble(json['funds']),
        currency: _asString(json['currency']),
      );
}

int _asInt(Object? value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? 0;
  return 0;
}

double _asDouble(Object? value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0;
  return 0;
}

String _asString(Object? value) => value?.toString() ?? '';

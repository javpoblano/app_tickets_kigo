import 'package:flutter/foundation.dart';

/// The Operator `user` object returned by the Login_Endpoint.
@immutable
class User {
  final int id;
  final String username;
  final String userType;
  final String status;
  final int parkingLotId;
  final String parkingLotKeyCode;

  const User({
    required this.id,
    required this.username,
    required this.userType,
    required this.status,
    required this.parkingLotId,
    required this.parkingLotKeyCode,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: _asInt(json['id']),
        username: _asString(json['username']),
        userType: _asString(json['userType']),
        status: _asString(json['status']),
        parkingLotId: _asInt(json['parkingLotId']),
        parkingLotKeyCode: _asString(json['parkingLotKeyCode']),
      );
}

/// Coerces a JSON value to an [int], tolerating numeric strings and doubles.
/// Returns `0` when the value is null or cannot be parsed.
int _asInt(Object? value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? 0;
  return 0;
}

/// Coerces a JSON value to a [String]. Returns an empty string when null.
String _asString(Object? value) => value?.toString() ?? '';

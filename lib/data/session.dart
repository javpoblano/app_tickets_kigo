import 'package:flutter/foundation.dart';

import 'user.dart';

/// The authenticated Operator_Session: the JWT token, the operator [User]
/// object, and the `roles` list from the Login_Endpoint response.
@immutable
class Session {
  final String token; // Operator_Token (JWT) from the `token` field
  final User user; // from the `user` field
  final List<String> roles; // from the `roles` field
  final DateTime issuedAt;

  const Session({
    required this.token,
    required this.user,
    required this.roles,
    required this.issuedAt,
  });

  bool get isAuthenticated => token.isNotEmpty;

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        token: json['token']?.toString() ?? '',
        user: User.fromJson((json['user'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{}),
        roles: (json['roles'] as List?)
                ?.map((role) => role.toString())
                .toList() ??
            const <String>[],
        issuedAt: DateTime.now(),
      );
}

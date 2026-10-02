import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:ed_operador/data/session.dart';
import 'package:ed_operador/data/user.dart';

/// Persists and restores the authenticated [Session] using SharedPreferences.
///
/// The session is stored as individual key-value pairs so it survives app
/// restarts. Clearing the storage logs the Operator out on next launch.
class SessionStorage {
  static const String _keyToken = 'session_token';
  static const String _keyUser = 'session_user';
  static const String _keyRoles = 'session_roles';
  static const String _keyIssuedAt = 'session_issued_at';

  /// Saves [session] to local storage.
  Future<void> save(Session session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, session.token);
    await prefs.setString(_keyUser, jsonEncode(_userToJson(session.user)));
    await prefs.setStringList(_keyRoles, session.roles);
    await prefs.setString(
      _keyIssuedAt,
      session.issuedAt.toIso8601String(),
    );
  }

  /// Restores the persisted [Session], or returns `null` if none is stored.
  Future<Session?> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    if (token == null || token.isEmpty) return null;

    final userJson = prefs.getString(_keyUser);
    if (userJson == null) return null;

    final rolesRaw = prefs.getStringList(_keyRoles) ?? const <String>[];
    final issuedAtRaw = prefs.getString(_keyIssuedAt);

    try {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      final user = User.fromJson(userMap);
      final issuedAt = issuedAtRaw != null
          ? DateTime.parse(issuedAtRaw)
          : DateTime.now();

      return Session(
        token: token,
        user: user,
        roles: rolesRaw,
        issuedAt: issuedAt,
      );
    } catch (_) {
      // Corrupted data — clear and return null.
      await clear();
      return null;
    }
  }

  /// Removes the persisted session.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
    await prefs.remove(_keyRoles);
    await prefs.remove(_keyIssuedAt);
  }

  Map<String, dynamic> _userToJson(User user) => {
        'id': user.id,
        'username': user.username,
        'userType': user.userType,
        'status': user.status,
        'parkingLotId': user.parkingLotId,
        'parkingLotKeyCode': user.parkingLotKeyCode,
      };
}

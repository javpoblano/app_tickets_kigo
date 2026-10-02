import 'package:flutter/foundation.dart';

/// The username and password supplied by an Operator on the Login_Screen.
@immutable
class Credentials {
  final String username; // raw operator input
  final String password; // raw operator input

  const Credentials({required this.username, required this.password});
}

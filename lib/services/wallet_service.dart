import 'package:ed_operador/data/wallet.dart';

/// Retrieves the operator's wallet(s) from the Backend_API wallet endpoint
/// using the Operator_Token from the current session.
///
/// Implementations send a `GET` to `/operator/wallet` with the
/// `x-operator-token` header and decode the `wallets` array. The first wallet
/// is the one displayed.
abstract class WalletService {
  /// Fetches the wallets, returning the first one, or `null` when the response
  /// contains no wallets.
  ///
  /// Throws [WalletUnavailableException] on timeout, network error, or a
  /// non-2xx / malformed response. Throws [WalletUnauthorizedException] when
  /// the token is rejected (401/403).
  Future<Wallet?> fetchPrimaryWallet({required String operatorToken});
}

/// Thrown when the wallet could not be retrieved (timeout, network error, or
/// non-2xx / malformed response).
class WalletUnavailableException implements Exception {
  final String message;

  const WalletUnavailableException([
    this.message = 'No se pudo obtener el saldo.',
  ]);

  @override
  String toString() => 'WalletUnavailableException: $message';
}

/// Thrown when the wallet endpoint rejects the request as unauthorized
/// (401/403), indicating the Operator_Token is no longer valid.
class WalletUnauthorizedException implements Exception {
  final String message;

  const WalletUnauthorizedException([
    this.message = 'La sesión ya no está autorizada.',
  ]);

  @override
  String toString() => 'WalletUnauthorizedException: $message';
}

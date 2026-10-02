import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ed_operador/app/app_config.dart';
import 'package:ed_operador/services/http_wallet_service.dart';
import 'package:ed_operador/services/wallet_service.dart';
import 'package:ed_operador/state/login_controller.dart' show httpClientProvider;
import 'package:ed_operador/state/providers.dart';
import 'package:ed_operador/state/wallet_state.dart';

/// The maximum time a wallet fetch is allowed to take.
const Duration walletTimeout = Duration(seconds: 10);

/// Provides the [WalletService] used to fetch the operator wallet.
///
/// Defaults to a [HttpWalletService] built from [httpClientProvider] and
/// [appConfigProvider]. Overridable in tests via `ProviderScope` `overrides`.
final walletServiceProvider = Provider<WalletService>((ref) {
  final client = ref.watch(httpClientProvider);
  final config = ref.watch(appConfigProvider);
  return HttpWalletService(client: client, config: config);
});

/// Orchestrates fetching the operator wallet, exposing an immutable
/// [WalletState] that starts at [WalletIdle].
final walletControllerProvider =
    StateNotifierProvider<WalletController, WalletState>((ref) {
  return WalletController(ref);
});

/// [StateNotifier] backing the [walletControllerProvider].
class WalletController extends StateNotifier<WalletState> {
  final Ref _ref;

  WalletController(this._ref) : super(const WalletIdle());

  /// Fetches the operator's primary wallet using the session token.
  ///
  /// Transitions `WalletLoading → WalletLoaded/WalletError`. On an unauthorized
  /// response the session is cleared so the router returns to Login.
  Future<void> refresh() async {
    final session = _ref.read(sessionProvider);
    if (session == null || !session.isAuthenticated) {
      state = const WalletError('Sesión no disponible.');
      return;
    }

    state = const WalletLoading();

    final service = _ref.read(walletServiceProvider);
    try {
      final wallet = await service
          .fetchPrimaryWallet(operatorToken: session.token)
          .timeout(walletTimeout);
      state = WalletLoaded(wallet);
    } on WalletUnauthorizedException {
      _ref.read(sessionProvider.notifier).state = null;
      state = const WalletError('La sesión ya no está autorizada.');
    } on WalletUnavailableException {
      state = const WalletError('No se pudo obtener el saldo.');
    } on TimeoutException {
      state = const WalletError('Tiempo de espera agotado al obtener el saldo.');
    } catch (_) {
      state = const WalletError('No se pudo obtener el saldo.');
    }
  }
}

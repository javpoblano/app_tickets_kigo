import 'package:flutter/foundation.dart';

import 'package:ed_operador/data/wallet.dart';

/// Immutable view state for the Saldo (wallet) card.
@immutable
sealed class WalletState {
  const WalletState();
}

/// No wallet loaded yet.
@immutable
class WalletIdle extends WalletState {
  const WalletIdle();
}

/// The wallet is being fetched.
@immutable
class WalletLoading extends WalletState {
  const WalletLoading();
}

/// The wallet was loaded successfully. [wallet] is `null` when the operator has
/// no wallet.
@immutable
class WalletLoaded extends WalletState {
  final Wallet? wallet;

  const WalletLoaded(this.wallet);
}

/// The wallet could not be loaded.
@immutable
class WalletError extends WalletState {
  final String message;

  const WalletError(this.message);
}

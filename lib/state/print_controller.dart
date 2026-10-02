import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ed_operador/printing/data/device_info.dart';
import 'package:ed_operador/printing/data/transport/device_discovery.dart';
import 'package:ed_operador/printing/domain/printer_models.dart'
    show PrinterDevice;
import 'package:ed_operador/printing/domain/printer_strategy.dart';
import 'package:ed_operador/services/bluetooth_printer_service.dart';
import 'package:ed_operador/services/printer_preferences.dart';
import 'package:ed_operador/services/printer_service.dart';
import 'package:ed_operador/services/telpo_printer_service.dart';
import 'package:ed_operador/state/print_state.dart';

/// Provides the [DeviceInfo] used to detect the running device.
final deviceInfoProvider = Provider<DeviceInfo>((ref) => const DeviceInfo());

/// Provides bonded-device discovery for the printer picker.
final deviceDiscoveryProvider =
    Provider<DeviceDiscovery>((ref) => DeviceDiscovery());

/// Persists the operator's selected printer.
final printerPreferencesProvider =
    Provider<PrinterPreferences>((ref) => PrinterPreferences());

/// A stable [BluetoothPrinterService] instance so the resolved-device cache and
/// connection persist across prints and can be reset when the operator picks a
/// new printer.
final bluetoothPrinterServiceProvider =
    Provider<BluetoothPrinterService>((ref) => BluetoothPrinterService());

/// Lists the OS-level bonded Bluetooth devices for the printer picker.
final bondedPrintersProvider = FutureProvider<List<PrinterDevice>>((ref) async {
  return ref.watch(deviceDiscoveryProvider).listBondedPrinters();
});

/// Resolves the [PrinterStrategy] for the current device.
///
/// Returns [PrinterStrategy.telpo] on a Telpo M1 (built-in printer), otherwise
/// [PrinterStrategy.standard] (external Bluetooth Xprinter). Consumers such as
/// the Main_Screen read this to select the printing service and to show a toast
/// signaling the active strategy.
final printerStrategyProvider = FutureProvider<PrinterStrategy>((ref) async {
  final deviceInfo = ref.watch(deviceInfoProvider);
  return deviceInfo.resolveStrategy();
});

/// Provides the [PrinterService] used to print ticket QR codes.
///
/// The concrete implementation is selected by the resolved [PrinterStrategy]:
/// - [PrinterStrategy.telpo] → [TelpoPrinterService] (built-in printer).
/// - [PrinterStrategy.standard] → [BluetoothPrinterService] (external
///   Bluetooth Xprinter).
///
/// While the strategy is still resolving (or on error), it falls back to the
/// standard Bluetooth service. It can be overridden in tests via `ProviderScope`
/// `overrides`, e.g.:
/// ```dart
/// ProviderScope(
///   overrides: [
///     printerServiceProvider.overrideWithValue(FakePrinterService()),
///   ],
///   child: const MyApp(),
/// );
/// ```
final printerServiceProvider = Provider<PrinterService>((ref) {
  final strategy = ref.watch(printerStrategyProvider).valueOrNull;
  return switch (strategy) {
    PrinterStrategy.telpo => TelpoPrinterService(),
    PrinterStrategy.standard || null =>
      ref.watch(bluetoothPrinterServiceProvider),
  };
});

/// Orchestrates printing a ticket QR code on the Bluetooth printer, exposing an
/// immutable [PrintState] that starts at [PrintIdle].
///
/// The flow (Requirements 5.1–5.5):
/// 1. Checks the printer connection. If disconnected, surfaces
///    [PrintNotConnected] (the UI warns the Operator) without attempting to
///    print.
/// 2. Otherwise transitions to [Printing] and sends the job.
/// 3. On success, surfaces [PrintSuccess].
/// 4. On [PrinterNotConnectedException], surfaces [PrintNotConnected].
/// 5. On any other [PrinterException] / error, surfaces [PrintError] carrying
///    the QR data so the UI can prompt the Operator to retry.
final printControllerProvider =
    StateNotifierProvider<PrintController, PrintState>((ref) {
  return PrintController(ref);
});

/// [StateNotifier] backing the [printControllerProvider].
class PrintController extends StateNotifier<PrintState> {
  final Ref _ref;

  PrintController(this._ref) : super(const PrintIdle());

  /// Prints the QR encoding [qrData] (with an optional [title]).
  ///
  /// Verifies the printer is connected first; warns via [PrintNotConnected]
  /// when it is not, and surfaces [PrintError] (retryable) on failure.
  Future<void> print({required String qrData, String? title}) async {
    debugPrint('[PrintController] print() called — qrData=$qrData, title=$title');
    debugPrint('[PrintController] current state=$state');
    final service = _ref.read(printerServiceProvider);

    // 1. Verify the printer is connected before attempting to print.
    debugPrint('[PrintController] checking isConnected...');
    final connected = await service.isConnected();
    debugPrint('[PrintController] isConnected=$connected');
    if (!connected) {
      state = PrintNotConnected(qrData: qrData, title: title);
      debugPrint('[PrintController] → PrintNotConnected (no printer available)');
      return;
    }

    // 2. Send the print job.
    state = const Printing();
    debugPrint('[PrintController] → Printing, calling printTicketQr...');
    try {
      await service.printTicketQr(qrData: qrData, title: title);
      state = const PrintSuccess();
      debugPrint('[PrintController] → PrintSuccess');
    } on PrinterNotConnectedException catch (e) {
      state = PrintNotConnected(qrData: qrData, title: title);
      debugPrint('[PrintController] → PrintNotConnected (exception: $e)');
    } on PrinterException catch (error) {
      state = PrintError(qrData: qrData, title: title, message: error.message);
      debugPrint('[PrintController] → PrintError: ${error.message}');
    } catch (error, stack) {
      state = PrintError(
        qrData: qrData,
        title: title,
        message: error.toString(),
      );
      debugPrint('[PrintController] → PrintError (unexpected): $error');
      debugPrint('[PrintController] stack: $stack');
    }
  }

  /// Retries printing the ticket described by the current retryable state
  /// ([PrintNotConnected] or [PrintError]). No-op otherwise.
  Future<void> retry() async {
    final current = state;
    switch (current) {
      case PrintNotConnected(:final qrData, :final title):
        await print(qrData: qrData, title: title);
      case PrintError(:final qrData, :final title):
        await print(qrData: qrData, title: title);
      case PrintIdle():
      case Printing():
      case PrintSuccess():
        // Nothing to retry.
        break;
    }
  }

  /// Resets the controller to its initial [PrintIdle] state.
  void reset() {
    state = const PrintIdle();
  }
}

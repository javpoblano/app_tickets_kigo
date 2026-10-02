import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ed_operador/domain/test_ticket_qr_generator.dart';
import 'package:ed_operador/printing/data/protocol/qr_image_encoder.dart';
import 'package:ed_operador/printing/domain/printer_models.dart';
import 'package:ed_operador/printing/domain/printer_strategy.dart';
import 'package:ed_operador/printing/domain/ticket_receipt_content.dart';
import 'package:ed_operador/state/print_controller.dart';
import 'package:ed_operador/state/print_state.dart';
import 'package:ed_operador/state/providers.dart';
import 'package:ed_operador/state/ticket_action_state.dart';
import 'package:ed_operador/state/ticket_controller.dart';
import 'package:ed_operador/state/wallet_controller.dart';
import 'package:ed_operador/state/wallet_state.dart';

/// The Main_Screen displayed to an authenticated Operator.
///
/// Organizes actions into titled card sections. Section visibility is
/// controlled via the "Secciones" menu in the app bar.
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  /// Section visibility flags.
  final Map<String, bool> _sections = {
    'prepago': true,
  };

  /// Ensures the printing-strategy toast is shown only once per screen open.
  bool _strategyToastShown = false;

  @override
  void initState() {
    super.initState();
    // Load the operator's funds when the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(walletControllerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ticketControllerProvider);
    final printState = ref.watch(printControllerProvider);
    final isRegistering = state is TicketRegistering;
    final isPrinting = printState is Printing;
    final busy = isRegistering || isPrinting;

    // Show a toast signaling the active printing strategy once it resolves.
    // Listen for future changes...
    ref.listen<AsyncValue<PrinterStrategy>>(printerStrategyProvider,
        (previous, next) {
      next.whenData(_maybeShowStrategyToast);
    });
    // ...and also handle the case where it is already resolved on this build.
    ref.watch(printerStrategyProvider).whenData(_maybeShowStrategyToast);

    // Side-effect listeners (ticket confirmation / error, print flow).
    ref.listen<TicketActionState>(ticketControllerProvider, (previous, next) {
      final messenger = ScaffoldMessenger.of(context);
      switch (next) {
        case TicketConfirmed(:final type, :final qrCode):
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('${_label(type)} registrado correctamente'),
              ),
            );
          ref.read(printControllerProvider.notifier).print(
                qrData: qrCode,
                title: _label(type),
              );
          ref.read(ticketControllerProvider.notifier).reset();
        case TicketFailed(:final errorDetail):
          _showApiErrorPrompt(context, errorDetail: errorDetail);
          ref.read(ticketControllerProvider.notifier).reset();
        case TicketIdle():
        case TicketRegistering():
          break;
      }
    });

    ref.listen<PrintState>(printControllerProvider, (previous, next) {
      switch (next) {
        case PrintNotConnected(:final qrData, :final title):
          _showRetryPrompt(
            context,
            ref,
            'No hay una impresora Bluetooth conectada.',
            qrData: qrData,
            ticketTitle: title,
          );
        case PrintError(:final message, :final qrData, :final title):
          _showRetryPrompt(
            context,
            ref,
            message,
            qrData: qrData,
            ticketTitle: title,
          );
        case PrintSuccess():
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('Ticket impreso')),
            );
          ref.read(printControllerProvider.notifier).reset();
          // Refresh the balance after a successful ticket print.
          ref.read(walletControllerProvider.notifier).refresh();
        case PrintIdle():
        case Printing():
          break;
      }
    });

    // Show a toast when the wallet fails to load (the card shows $0.00).
    ref.listen<WalletState>(walletControllerProvider, (previous, next) {
      if (next is WalletError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(next.message)),
          );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('ED-Operador'),
        actions: [
          // Sections visibility menu.
          PopupMenuButton<String>(
            icon: const Icon(Icons.view_module),
            tooltip: 'Secciones',
            onSelected: (key) {
              setState(() {
                _sections[key] = !(_sections[key] ?? true);
              });
            },
            itemBuilder: (context) => _sections.entries.map((entry) {
              return CheckedPopupMenuItem<String>(
                value: entry.key,
                checked: entry.value,
                child: Text(_sectionLabel(entry.key)),
              );
            }).toList(),
          ),
          // Account menu (test print + logout).
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'select_printer':
                  await _showPrinterPicker(context);
                case 'test_print':
                  final qrCode = TestTicketQrGenerator.generate();
                  ref.read(printControllerProvider.notifier).print(
                        qrData: qrCode,
                        title: 'Ticket de prueba',
                      );
                case 'logout':
                  await ref.read(sessionStorageProvider).clear();
                  ref.read(sessionProvider.notifier).state = null;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'select_printer',
                child: Text('Seleccionar impresora'),
              ),
              PopupMenuItem<String>(
                value: 'test_print',
                child: Text('Probar impresión'),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Text('Cerrar sesión'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo.
            Center(
              child: Image.asset(
                'assets/logo.png',
                width: 72,
                height: 72,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),

            // Progress indicator.
            SizedBox(
              height: 24,
              child: busy
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),

            // === Saldo section ===
            _SaldoCard(
              state: ref.watch(walletControllerProvider),
              onRefresh: () =>
                  ref.read(walletControllerProvider.notifier).refresh(),
            ),
            const SizedBox(height: 16),

            // === Prepago section ===
            if (_sections['prepago'] ?? true)
              _SectionCard(
                title: 'Impresión Prepago',
                children: [
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () => ref
                            .read(ticketControllerProvider.notifier)
                            .register(TicketType.regular),
                    child: const Text('Ticket regular'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: busy
                        ? null
                        : () => ref
                            .read(ticketControllerProvider.notifier)
                            .register(TicketType.promotion),
                    child: const Text('Ticket promoción'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ─── Helper methods ──────────────────────────────────────────────────────

  /// Shows the printing-strategy toast once, deferring to after the current
  /// frame so it never runs during build.
  void _maybeShowStrategyToast(PrinterStrategy strategy) {
    if (_strategyToastShown) return;
    _strategyToastShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Estrategia de impresión: ${strategy.label}'),
          ),
        );
    });
  }

  String _sectionLabel(String key) => switch (key) {
        'prepago' => 'Impresión Prepago',
        _ => key,
      };

  void _showApiErrorPrompt(BuildContext context, {String? errorDetail}) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Error de conexión'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No se pudo registrar el ticket. '
              'Verifica tu conexión a internet e inténtalo de nuevo.',
            ),
            if (kDebugMode && errorDetail != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SelectableText(
                  'DEBUG: $errorDetail',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRetryPrompt(
    BuildContext context,
    WidgetRef ref,
    String message, {
    required String qrData,
    String? ticketTitle,
  }) async {
    final choice = await showDialog<_RetryChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Error de impresión'),
        content: Text(
          'No se pudo imprimir el ticket.\n\n$message\n\n¿Deseas reintentar?',
        ),
        actionsOverflowButtonSpacing: 4,
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_RetryChoice.cancel),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_RetryChoice.show),
            child: const Text('Mostrar boleto'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_RetryChoice.retry),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );

    switch (choice) {
      case _RetryChoice.retry:
        await ref.read(printControllerProvider.notifier).retry();
      case _RetryChoice.show:
        if (context.mounted) {
          await _showTicketPreview(context, qrData: qrData, title: ticketTitle);
        }
        // Keep the print state so the operator can still retry afterward.
      case _RetryChoice.cancel:
      case null:
        ref.read(printControllerProvider.notifier).reset();
    }
  }

  /// Shows a dialog listing bonded Bluetooth devices, lets the operator pick
  /// the printer, persists the selection, and resets the printer service so the
  /// next print uses it.
  Future<void> _showPrinterPicker(BuildContext context) async {
    // Ensure permissions so bonded-device listing works on Android 12+.
    await ref.read(bluetoothPrinterServiceProvider).ensurePermissions();
    // Refresh the bonded list.
    ref.invalidate(bondedPrintersProvider);

    final saved = await ref.read(printerPreferencesProvider).load();

    if (!context.mounted) return;
    final selected = await showDialog<PrinterDevice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Seleccionar impresora'),
        content: SizedBox(
          width: double.maxFinite,
          child: Consumer(
            builder: (context, ref, _) {
              final devicesAsync = ref.watch(bondedPrintersProvider);
              return devicesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No se pudieron leer los dispositivos emparejados. '
                    'Verifica que el Bluetooth esté activo y los permisos '
                    'concedidos.',
                  ),
                ),
                data: (devices) {
                  if (devices.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No hay dispositivos Bluetooth emparejados. '
                        'Empareja la impresora en los ajustes de Bluetooth.',
                      ),
                    );
                  }
                  return ListView(
                    shrinkWrap: true,
                    children: [
                      for (final d in devices)
                        ListTile(
                          leading: const Icon(Icons.print),
                          title: Text(d.name),
                          subtitle: Text(d.macAddress),
                          trailing: d.macAddress == saved?.macAddress
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: () => Navigator.of(dialogContext).pop(d),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (selected == null) return;

    await ref.read(printerPreferencesProvider).save(selected);
    await ref.read(bluetoothPrinterServiceProvider).resetSelection();

    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Impresora seleccionada: ${selected.name}')),
        );
    }
  }

  /// Shows the ticket that would be printed (header, QR, footer) on screen.
  Future<void> _showTicketPreview(
    BuildContext context, {
    required String qrData,
    String? title,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Boleto'),
        content: SingleChildScrollView(
          child: _TicketPreview(qrData: qrData),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  String _label(TicketType type) => switch (type) {
        TicketType.regular => 'Ticket regular',
        TicketType.promotion => 'Ticket Promoción',
      };
}

/// The operator's choice in the print-failure dialog.
enum _RetryChoice { retry, show, cancel }

/// A titled card that groups related action buttons.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A titled card that displays the logged-in operator's balance (Saldo).
class _SaldoCard extends StatelessWidget {
  const _SaldoCard({required this.state, required this.onRefresh});

  final WalletState state;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saldo',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualizar saldo',
                  onPressed: state is WalletLoading ? null : onRefresh,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildContent(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    switch (state) {
      case WalletIdle():
      case WalletLoading():
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      case WalletLoaded(:final wallet):
        if (wallet == null) {
          return _amountText(theme, '0.00', '');
        }
        return _amountText(
          theme,
          wallet.funds.toStringAsFixed(2),
          wallet.currency.toUpperCase(),
        );
      case WalletError():
        // On failure show a zero balance; the error message is surfaced as a
        // toast by the screen's wallet listener.
        return _amountText(theme, '0.00', '');
    }
  }

  Widget _amountText(ThemeData theme, String amount, String currency) {
    final suffix = currency.isEmpty ? '' : ' $currency';
    return Text(
      '\$$amount$suffix',
      style: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

/// On-screen preview of the ticket that would be printed: the header line(s),
/// the QR code, and the footer line(s). Rendered on a white "paper" background
/// so it reads like the physical receipt.
class _TicketPreview extends StatelessWidget {
  const _TicketPreview({required this.qrData});

  final String qrData;

  @override
  Widget build(BuildContext context) {
    final qrPng = QrImageEncoder.encode(qrData, pixelsPerModule: 8);
    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final line in ticketHeaderLines)
            if (line.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  line,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black, fontSize: 12),
                ),
              ),
          const SizedBox(height: 8),
          Image.memory(qrPng, width: 180, height: 180, gaplessPlayback: true),
          const SizedBox(height: 4),
          Text(
            qrData,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black, fontSize: 11),
          ),
          const SizedBox(height: 8),
          for (final line in ticketFooterLines)
            if (line.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  line,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black, fontSize: 11),
                ),
              ),
        ],
      ),
    );
  }
}

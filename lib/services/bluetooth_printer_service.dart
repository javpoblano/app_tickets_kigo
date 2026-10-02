import 'package:flutter/foundation.dart';
import 'package:ed_operador/printing/data/print_orchestrator.dart';
import 'package:ed_operador/printing/data/printer_permissions.dart';
import 'package:ed_operador/printing/data/protocol/qr_raster_encoder.dart';
import 'package:ed_operador/printing/data/protocol/receipt_template_builder.dart';
import 'package:ed_operador/printing/data/transport/bluetooth_spp_transport.dart';
import 'package:ed_operador/printing/data/transport/device_discovery.dart';
import 'package:ed_operador/printing/domain/printer_models.dart' as printing;
import 'package:ed_operador/printing/domain/ticket_receipt_content.dart';
import 'package:ed_operador/services/printer_preferences.dart';
import 'package:ed_operador/services/printer_service.dart';

/// Concrete [PrinterService] for the XP-P810 (Xprinter) Bluetooth thermal
/// printer using the native SPP platform channel.
///
/// Uses [DeviceDiscovery] to locate the bonded printer by MAC address,
/// [BluetoothSppTransport] for the RFCOMM connection, [PrintOrchestrator] to
/// drive the print job, and [ReceiptTemplateBuilder] to construct the ESC/POS
/// receipt (title + QR text + feed).
class BluetoothPrinterService implements PrinterService {
  BluetoothPrinterService({
    String? printerMacAddress,
    BluetoothSppTransport? transport,
    DeviceDiscovery? discovery,
    PrinterPermissions? permissions,
    PrinterPreferences? preferences,
  })  : _printerMacAddress = printerMacAddress,
        _transport = transport ?? BluetoothSppTransport(),
        _discovery = discovery ?? DeviceDiscovery(),
        _permissions = permissions ?? PrinterPermissions(),
        _preferences = preferences ?? PrinterPreferences();

  /// An explicit MAC address to use (mainly for tests). When `null`, the
  /// service uses the operator's saved selection ([PrinterPreferences]).
  final String? _printerMacAddress;
  final BluetoothSppTransport _transport;
  final DeviceDiscovery _discovery;
  final PrinterPermissions _permissions;
  final PrinterPreferences _preferences;

  printing.PrinterDevice? _cachedDevice;

  /// Requests the runtime Bluetooth permissions required to talk to the
  /// printer. On Android 12+ this prompts for BLUETOOTH_CONNECT/SCAN; without
  /// it, bonded-device discovery and connect throw SecurityException and the
  /// print silently fails. Returns `true` when granted.
  Future<bool> _ensurePermissions() async {
    final result = await _permissions.ensure();
    debugPrint('[PrinterService] permissions=$result');
    return result == PrinterPermissionResult.granted;
  }

  /// Public entry point to request Bluetooth permissions (used by the printer
  /// picker before listing bonded devices). Returns `true` when granted.
  Future<bool> ensurePermissions() => _ensurePermissions();

  @override
  Future<bool> isConnected() async {
    debugPrint('[PrinterService] isConnected() — transport.state=${_transport.state}');
    // If the transport is already connected, we're good.
    if (_transport.state == printing.PrinterConnectionState.connected) {
      debugPrint('[PrinterService] → true (already connected)');
      return true;
    }
    // Request permissions (best-effort; do not block if misreported).
    final granted = await _ensurePermissions();
    debugPrint('[PrinterService] permissions granted=$granted');
    // Check if a bonded printer is available (the orchestrator will connect on
    // demand when printTicketQr is called).
    final device = await _resolvePrinter();
    debugPrint('[PrinterService] → ${device != null} (device=${device?.name}/${device?.macAddress})');
    return device != null;
  }

  @override
  Future<void> printTicketQr({required String qrData, String? title}) async {
    debugPrint('[PrinterService] printTicketQr() — qrData=$qrData');

    // Request runtime Bluetooth permissions (Android 12+ BLUETOOTH_CONNECT).
    // This is best-effort: some OEM ROMs (e.g. the Telpo) misreport the status
    // via permission_handler even when access is granted, so we do NOT hard
    // block here. If access is genuinely missing, the native connect() will
    // fail with `permission_denied`, which surfaces a clear message.
    final granted = await _ensurePermissions();
    debugPrint('[PrinterService] permissions granted=$granted (continuing)');

    final device = await _resolvePrinter();
    debugPrint('[PrinterService] resolved device=${device?.name}/${device?.macAddress}');
    if (device == null) {
      debugPrint('[PrinterService] ERROR: no device found');
      throw const PrinterNotConnectedException(
        'No se encontró una impresora emparejada. Emparéjala en los ajustes de Bluetooth.',
      );
    }

    final template = await _buildTemplate(qrData: qrData, title: title);
    debugPrint('[PrinterService] template built — ${template.length} printables');

    final orchestrator = PrintOrchestrator(transport: _transport);
    try {
      debugPrint('[PrinterService] calling orchestrator.printReceipt...');
      await orchestrator.printReceipt(device, template);
      debugPrint('[PrinterService] printReceipt completed successfully');
    } on printing.PrinterException catch (e) {
      debugPrint('[PrinterService] PrinterException: ${e.code} — ${e.message}');
      // On failure the native side already closed the socket; reset Dart state
      // so the next attempt reconnects.
      _transport.resetState();
      throw PrinterException(e.message);
    }
  }

  /// Clears the cached device and drops the current connection so the next
  /// print re-resolves the printer (used after the operator picks a new one).
  Future<void> resetSelection() async {
    _cachedDevice = null;
    await _transport.disconnect();
  }

  /// Resolves the target [printing.PrinterDevice], caching the result across
  /// prints.
  ///
  /// Preference order: explicit constructor MAC (tests) → operator's saved
  /// selection ([PrinterPreferences]) → printer-like bonded device → first
  /// bonded device.
  Future<printing.PrinterDevice?> _resolvePrinter() async {
    if (_cachedDevice != null) {
      debugPrint('[PrinterService] _resolvePrinter: cached '
          '${_cachedDevice!.name}/${_cachedDevice!.macAddress}');
      return _cachedDevice;
    }

    // 1. Explicit MAC (tests / manual override).
    if (_printerMacAddress != null) {
      debugPrint('[PrinterService] _resolvePrinter: findByMac($_printerMacAddress)');
      _cachedDevice = await _discovery.findByMac(_printerMacAddress);
      debugPrint('[PrinterService] _resolvePrinter: byMac → '
          '${_cachedDevice?.name}/${_cachedDevice?.macAddress}');
      return _cachedDevice;
    }

    // 2. Operator's saved selection.
    final saved = await _preferences.load();
    if (saved != null && saved.macAddress.isNotEmpty) {
      debugPrint('[PrinterService] _resolvePrinter: saved selection '
          '${saved.name}/${saved.macAddress}');
      // Prefer the live bonded entry (for a fresh name), but fall back to the
      // saved device so a valid MAC still connects even if listing fails.
      final live = await _discovery.findByMac(saved.macAddress);
      _cachedDevice = live ?? saved;
      return _cachedDevice;
    }

    // 3. No saved selection: pick a bonded device whose name looks like a
    // thermal printer. Common names include XP-xxx, MPT, MTP, POS, PT-xxx,
    // "Printer", "BlueTooth Printer", "58"/"80" etc.
    try {
      final devices = await _discovery.listBondedPrinters();
      debugPrint('[PrinterService] _resolvePrinter: ${devices.length} bonded devices');

      final match = devices.firstWhere(
        (d) => _looksLikePrinter(d.name),
        orElse: () => const printing.PrinterDevice(name: '', macAddress: ''),
      );
      if (match.macAddress.isNotEmpty) {
        debugPrint('[PrinterService] _resolvePrinter: matched printer-like → '
            '${match.name}/${match.macAddress}');
        _cachedDevice = match;
        return match;
      }

      // No printer-like name: fall back to the first bonded device (if any).
      if (devices.isNotEmpty) {
        debugPrint('[PrinterService] _resolvePrinter: no printer-like name, '
            'using first → ${devices.first.name}/${devices.first.macAddress}');
        _cachedDevice = devices.first;
        return _cachedDevice;
      }
      debugPrint('[PrinterService] _resolvePrinter: NO bonded devices found');
    } on printing.PrinterException catch (e) {
      // Bluetooth unavailable or permission denied — surface as not connected.
      debugPrint('[PrinterService] _resolvePrinter: discovery failed — '
          '${e.code}: ${e.message}');
    }
    return null;
  }

  /// Heuristic to detect a thermal-printer bonded device by name.
  static bool _looksLikePrinter(String name) {
    final n = name.toUpperCase();
    const needles = <String>[
      'XP', 'PRINT', 'POS', 'MPT', 'MTP', 'PT-', 'PT2', 'TP-', 'RPP',
      'BLUETOOTH PRINTER', '58', '80', 'THERMAL', 'IMPRES',
    ];
    return needles.any(n.contains);
  }

  /// Builds the ESC/POS receipt: the header line(s), the QR code image, then
  /// the footer line(s), and a bottom feed.
  Future<List<printing.Printable>> _buildTemplate({
    required String qrData,
    String? title,
  }) async {
    // 1. Header line(s) above the QR.
    final header = ReceiptTemplateBuilder();
    for (final line in ticketHeaderLines) {
      header.printLine(
        line,
        style: printing.PrinterTextStyle.normal,
        alignment: printing.PrinterAlignment.center,
      );
    }
    header.feed(1);
    final template = header.build().toList();

    // 2. The QR code (GS v 0 raster).
    template.add(
      printing.ImagePrintable(
        QrRasterEncoder.encode(qrData),
        alignment: printing.PrinterAlignment.center,
        newLinesAfter: 1,
      ),
    );

    // 3. Footer line(s) below the QR, then bottom padding so the ticket clears
    // the tear bar.
    final footer = ReceiptTemplateBuilder();
    for (final line in ticketFooterLines) {
      footer.printLine(
        line,
        style: printing.PrinterTextStyle.small,
        alignment: printing.PrinterAlignment.center,
      );
    }
    footer.feed(3);
    template.addAll(footer.build());

    return template;
  }
}

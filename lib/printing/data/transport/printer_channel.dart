/// Shared platform-channel handle for the Xprinter SPP native plugin.
///
/// The Kotlin side (`XPrinterSppPlugin`) is registered in `MainActivity` under
/// the same channel name.
library;

import 'package:flutter/services.dart';

/// Method channel bridging Dart to the native Bluetooth Classic SPP transport.
const MethodChannel xprinterChannel =
    MethodChannel('com.edoperador.ed_operador/xprinter');

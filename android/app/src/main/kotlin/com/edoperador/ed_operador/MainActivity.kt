package com.edoperador.ed_operador

import com.edoperador.ed_operador.printer.XPrinterSppPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            XPrinterSppPlugin.CHANNEL,
        ).setMethodCallHandler(XPrinterSppPlugin(applicationContext))
    }
}

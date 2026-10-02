package com.edoperador.ed_operador.printer

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.OutputStream
import java.util.UUID
import java.util.concurrent.Executors

/**
 * Native Bluetooth Classic RFCOMM/SPP transport for the Xprinter module.
 *
 * Opens an insecure RFCOMM socket to the SPP UUID and writes raw ESC/POS bytes.
 * All socket work runs on a single background executor; results are posted back
 * on the main thread as required by Flutter's method channel.
 */
class XPrinterSppPlugin(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.edoperador.ed_operador/xprinter"
        private val SPP_UUID: UUID =
            UUID.fromString("00001101-0000-1000-8000-00805f9b34fb")
        private const val CONNECT_TIMEOUT_MS = 10_000L
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private val io = Executors.newSingleThreadExecutor()

    private var socket: BluetoothSocket? = null
    private var output: OutputStream? = null

    private val adapter: BluetoothAdapter?
        get() {
            val manager =
                context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            return manager?.adapter
        }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getSdkInt" -> result.success(Build.VERSION.SDK_INT)
            "getDeviceInfo" -> getDeviceInfo(result)
            "getBondedDevices" -> getBondedDevices(result)
            "connect" -> connect(call.argument<String>("address"), result)
            "write" -> write(call.argument<ByteArray>("bytes"), result)
            "disconnect" -> disconnect(result)
            else -> result.notImplemented()
        }
    }

    private fun getDeviceInfo(result: MethodChannel.Result) {
        result.success(
            mapOf(
                "manufacturer" to (Build.MANUFACTURER ?: ""),
                "model" to (Build.MODEL ?: ""),
                "brand" to (Build.BRAND ?: ""),
                "device" to (Build.DEVICE ?: ""),
                "product" to (Build.PRODUCT ?: ""),
            ),
        )
    }

    private fun getBondedDevices(result: MethodChannel.Result) {
        val a = adapter
        if (a == null || !a.isEnabled) {
            result.error("bluetooth_unavailable", "Bluetooth no disponible o deshabilitado", null)
            return
        }
        try {
            val list = a.bondedDevices.map { d ->
                mapOf("name" to (d.name ?: ""), "address" to d.address)
            }
            result.success(list)
        } catch (e: SecurityException) {
            result.error("permission_denied", e.message, null)
        }
    }

    private fun connect(address: String?, result: MethodChannel.Result) {
        if (address.isNullOrBlank()) {
            result.error("invalid_address", "Direccion MAC vacia", null)
            return
        }
        val a = adapter
        if (a == null || !a.isEnabled) {
            result.error("bluetooth_unavailable", "Bluetooth no disponible", null)
            return
        }

        io.execute {
            try {
                val device: BluetoothDevice = a.getRemoteDevice(address)
                if (device.bondState != BluetoothDevice.BOND_BONDED) {
                    replyError(result, "not_paired", "Dispositivo no emparejado: $address")
                    return@execute
                }

                closeQuietly()
                try {
                    a.cancelDiscovery()
                } catch (_: SecurityException) {
                    // Ignore: discovery may not be running or permission missing.
                }

                val s = device.createInsecureRfcommSocketToServiceRecord(SPP_UUID)

                // socket.connect() blocks; enforce a 10 s budget with a watchdog.
                val errorHolder = arrayOfNulls<Exception>(1)
                val connectThread = Thread {
                    try {
                        s.connect()
                    } catch (e: Exception) {
                        errorHolder[0] = e
                    }
                }
                connectThread.start()
                connectThread.join(CONNECT_TIMEOUT_MS)

                if (connectThread.isAlive) {
                    closeQuietly(s)
                    replyError(result, "timeout", "Tiempo de conexion agotado")
                    return@execute
                }
                if (errorHolder[0] != null || !s.isConnected) {
                    closeQuietly(s)
                    replyError(result, "connection_failed", errorHolder[0]?.message ?: "Fallo de conexion")
                    return@execute
                }

                socket = s
                output = s.outputStream
                replySuccess(result, null)
            } catch (e: SecurityException) {
                closeQuietly()
                replyError(result, "permission_denied", e.message)
            } catch (e: Exception) {
                closeQuietly()
                replyError(result, "connection_failed", e.message)
            }
        }
    }

    private fun write(bytes: ByteArray?, result: MethodChannel.Result) {
        val out = output
        val s = socket
        if (out == null || s == null || !s.isConnected) {
            result.error("not_connected", "La impresora no esta conectada", null)
            return
        }
        if (bytes == null || bytes.isEmpty()) {
            result.success(null)
            return
        }
        io.execute {
            try {
                out.write(bytes)
                out.flush()
                replySuccess(result, null)
            } catch (e: Exception) {
                closeQuietly()
                replyError(result, "connection_lost", e.message)
            }
        }
    }

    private fun disconnect(result: MethodChannel.Result) {
        io.execute {
            closeQuietly()
            replySuccess(result, null)
        }
    }

    private fun closeQuietly(target: BluetoothSocket? = null) {
        try {
            output?.flush()
        } catch (_: Exception) {
        }
        try {
            output?.close()
        } catch (_: Exception) {
        }
        try {
            (target ?: socket)?.close()
        } catch (_: Exception) {
        }
        output = null
        socket = null
    }

    private fun replySuccess(result: MethodChannel.Result, value: Any?) {
        mainHandler.post { result.success(value) }
    }

    private fun replyError(result: MethodChannel.Result, code: String, message: String?) {
        mainHandler.post { result.error(code, message, null) }
    }
}

package com.dash1971.maia_chess

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.ArrayDeque
import java.util.UUID

class ChessnutBridge(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    companion object {
        private const val METHOD_CHANNEL = "maia_chess/chessnut"
        private const val EVENT_CHANNEL = "maia_chess/chessnut/events"
        private const val PERMISSION_REQUEST = 7103
        private const val SCAN_TIMEOUT_MS = 10_000L

        private val WRITE_UUID = UUID.fromString("1B7E8272-2877-41C3-B46E-CF057C562023")
        private val CONFIRM_UUID = UUID.fromString("1B7E8273-2877-41C3-B46E-CF057C562023")
        private val DATA_UUID = UUID.fromString("1B7E8262-2877-41C3-B46E-CF057C562023")
        private val CCCD_UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
        private val INIT_COMMAND = byteArrayOf(0x21, 0x01, 0x00)
        private val BATTERY_COMMAND = byteArrayOf(0x29, 0x01, 0x00)
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private val methodChannel = MethodChannel(messenger, METHOD_CHANNEL)
    private val eventChannel = EventChannel(messenger, EVENT_CHANNEL)
    private val bluetoothManager =
        activity.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
    private val adapter: BluetoothAdapter?
        get() = bluetoothManager?.adapter

    private var eventSink: EventChannel.EventSink? = null
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var scanCallback: ScanCallback? = null
    private var gatt: BluetoothGatt? = null
    private var writeCharacteristic: BluetoothGattCharacteristic? = null
    private var dataCharacteristic: BluetoothGattCharacteristic? = null
    private var confirmationCharacteristic: BluetoothGattCharacteristic? = null
    private var configuringDescriptor: UUID? = null
    private var serviceDiscoveryStarted = false
    private var ready = false
    private var state = "disconnected"
    private var stateMessage = "Chessnut Go is disconnected."
    private var deviceName: String? = null
    private data class PendingWrite(
        val command: ByteArray,
        val failureIsFatal: Boolean = true,
    )

    private val writeQueue = ArrayDeque<PendingWrite>()
    private var writeInProgress = false
    private var activeWrite: PendingWrite? = null

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "connect" -> connect(result)
            "disconnect" -> {
                disconnect("Chessnut Go disconnected.")
                result.success(null)
            }
            "setLeds" -> setLeds(call, result)
            "beep" -> beep(call, result)
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        emitStatus(state, stateMessage, deviceName)
        if (ready) {
            enqueueWrite(INIT_COMMAND)
            enqueueWrite(BATTERY_COMMAND)
        }
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST) return false
        val result = pendingPermissionResult
        pendingPermissionResult = null
        if (grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
            try {
                if (adapter?.isEnabled != true) {
                    val message = "Turn on Bluetooth, then try again."
                    result?.error("bluetooth_disabled", message, null)
                    emitError(message)
                    return true
                }
                startScan()
                result?.success(null)
            } catch (error: Throwable) {
                result?.error("connect_failed", error.message, null)
                emitError(error.message ?: "Could not start Chessnut scan.")
            }
        } else {
            val message = "Bluetooth permission is required to connect Chessnut Go."
            result?.error("permission_denied", message, null)
            emitError(message)
        }
        return true
    }

    private fun connect(result: MethodChannel.Result) {
        if (ready) {
            emitStatus("ready", "Chessnut Go is ready.", deviceName)
            result.success(null)
            return
        }
        if (scanCallback != null || state == "connecting") {
            result.success(null)
            return
        }
        val bluetoothAdapter = adapter
        if (bluetoothAdapter == null) {
            result.error("bluetooth_unavailable", "Bluetooth is not available on this device.", null)
            emitError("Bluetooth is not available on this device.")
            return
        }
        val missing = requiredPermissions().filter {
            ContextCompat.checkSelfPermission(activity, it) != PackageManager.PERMISSION_GRANTED
        }
        if (missing.isNotEmpty()) {
            if (pendingPermissionResult != null) {
                result.error("permission_pending", "A Bluetooth permission request is already open.", null)
                return
            }
            pendingPermissionResult = result
            ActivityCompat.requestPermissions(activity, missing.toTypedArray(), PERMISSION_REQUEST)
            return
        }
        if (!bluetoothAdapter.isEnabled) {
            result.error("bluetooth_disabled", "Turn on Bluetooth, then try again.", null)
            emitError("Turn on Bluetooth, then try again.")
            return
        }
        try {
            startScan()
            result.success(null)
        } catch (error: Throwable) {
            result.error("connect_failed", error.message, null)
            emitError(error.message ?: "Could not start Chessnut scan.")
        }
    }

    private fun requiredPermissions(): List<String> =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            listOf(Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT)
        } else {
            listOf(Manifest.permission.ACCESS_FINE_LOCATION)
        }

    private fun startScan() {
        disconnectGatt()
        val scanner = adapter?.bluetoothLeScanner
            ?: throw IllegalStateException("Bluetooth LE scanning is unavailable.")
        emitStatus("scanning", "Searching for Chessnut Go…")
        val callback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                val name = try {
                    result.device.name ?: result.scanRecord?.deviceName ?: ""
                } catch (_: SecurityException) {
                    ""
                }
                if (!looksLikeChessnut(name)) return
                stopScan()
                connectGatt(result.device, name.ifBlank { "Chessnut Go" })
            }

            override fun onScanFailed(errorCode: Int) {
                stopScan()
                emitError("Chessnut scan failed (code $errorCode).")
            }
        }
        scanCallback = callback
        scanner.startScan(callback)
        mainHandler.postDelayed({
            if (scanCallback === callback) {
                stopScan()
                emitError("No Chessnut Go found. Check that the board is on and nearby.")
            }
        }, SCAN_TIMEOUT_MS)
    }

    private fun looksLikeChessnut(name: String): Boolean =
        name.contains("Chessnut", ignoreCase = true) ||
            name.contains("Smart Chess", ignoreCase = true)

    private fun stopScan() {
        val callback = scanCallback ?: return
        scanCallback = null
        try {
            adapter?.bluetoothLeScanner?.stopScan(callback)
        } catch (_: SecurityException) {
            // Permission can be revoked while scanning; status handling continues.
        }
    }

    private fun connectGatt(device: BluetoothDevice, name: String) {
        deviceName = name
        emitStatus("connecting", "Connecting to $name…", name)
        serviceDiscoveryStarted = false
        ready = false
        try {
            gatt = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                device.connectGatt(activity, false, gattCallback, BluetoothDevice.TRANSPORT_LE)
            } else {
                @Suppress("DEPRECATION")
                device.connectGatt(activity, false, gattCallback)
            }
            if (gatt == null) failConnection("Could not open the Chessnut Go connection.")
        } catch (error: SecurityException) {
            failConnection(error.message ?: "Bluetooth permission was revoked.")
        }
    }

    private val gattCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            mainHandler.post {
                if (this@ChessnutBridge.gatt !== gatt) return@post
                if (status != BluetoothGatt.GATT_SUCCESS &&
                    newState != BluetoothProfile.STATE_DISCONNECTED
                ) {
                    failConnection("Chessnut connection failed (status $status).")
                    return@post
                }
                when (newState) {
                    BluetoothProfile.STATE_CONNECTED -> {
                        emitStatus("connected", "Connected; configuring Chessnut Go…", deviceName)
                        try {
                            if (!gatt.requestMtu(500)) discoverServicesOnce(gatt)
                        } catch (error: SecurityException) {
                            failConnection(error.message ?: "Bluetooth permission was revoked.")
                        }
                    }
                    BluetoothProfile.STATE_DISCONNECTED -> {
                        val unexpected = state != "disconnected"
                        disconnectGatt()
                        if (unexpected) {
                            emitStatus(
                                "disconnected",
                                "Chessnut Go connection was lost. Tap reconnect to continue.",
                                deviceName,
                            )
                        }
                    }
                }
            }
        }

        override fun onMtuChanged(gatt: BluetoothGatt, mtu: Int, status: Int) {
            mainHandler.post {
                if (this@ChessnutBridge.gatt === gatt) discoverServicesOnce(gatt)
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            mainHandler.post {
                if (this@ChessnutBridge.gatt !== gatt) return@post
                if (status != BluetoothGatt.GATT_SUCCESS) {
                    failConnection("Chessnut service discovery failed (status $status).")
                    return@post
                }
                configureServices(gatt.services)
            }
        }

        @Suppress("DEPRECATION")
        @Deprecated("Deprecated in Android 13")
        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
        ) {
            if (this@ChessnutBridge.gatt === gatt) {
                handleNotification(characteristic.uuid, characteristic.value ?: byteArrayOf())
            }
        }

        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray,
        ) {
            if (this@ChessnutBridge.gatt === gatt) {
                handleNotification(characteristic.uuid, value)
            }
        }

        override fun onDescriptorWrite(
            gatt: BluetoothGatt,
            descriptor: BluetoothGattDescriptor,
            status: Int,
        ) {
            mainHandler.post {
                if (this@ChessnutBridge.gatt !== gatt) return@post
                if (status != BluetoothGatt.GATT_SUCCESS) {
                    failConnection("Could not enable Chessnut notifications (status $status).")
                    return@post
                }
                when (configuringDescriptor) {
                    DATA_UUID -> enableNotifications(confirmationCharacteristic)
                    CONFIRM_UUID -> finishConfiguration()
                    else -> Unit
                }
            }
        }

        override fun onCharacteristicWrite(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            status: Int,
        ) {
            mainHandler.post {
                if (this@ChessnutBridge.gatt !== gatt) return@post
                writeInProgress = false
                val completedWrite = activeWrite
                activeWrite = null
                if (status != BluetoothGatt.GATT_SUCCESS) {
                    if (completedWrite?.failureIsFatal != false) {
                        failConnection("Chessnut command failed (status $status).")
                    } else {
                        writeNext()
                    }
                    return@post
                }
                writeNext()
            }
        }
    }

    private fun discoverServicesOnce(gatt: BluetoothGatt) {
        if (serviceDiscoveryStarted) return
        serviceDiscoveryStarted = true
        try {
            if (!gatt.discoverServices()) failConnection("Could not discover Chessnut services.")
        } catch (error: SecurityException) {
            failConnection(error.message ?: "Bluetooth permission was revoked.")
        }
    }

    private fun configureServices(services: List<BluetoothGattService>) {
        writeCharacteristic = findCharacteristic(services, WRITE_UUID)
        dataCharacteristic = findCharacteristic(services, DATA_UUID)
        confirmationCharacteristic = findCharacteristic(services, CONFIRM_UUID)
        if (writeCharacteristic == null || dataCharacteristic == null || confirmationCharacteristic == null) {
            failConnection("The connected board does not expose the expected Chessnut BLE service.")
            return
        }
        enableNotifications(dataCharacteristic)
    }

    private fun findCharacteristic(
        services: List<BluetoothGattService>,
        uuid: UUID,
    ): BluetoothGattCharacteristic? = services.firstNotNullOfOrNull { it.getCharacteristic(uuid) }

    private fun enableNotifications(characteristic: BluetoothGattCharacteristic?) {
        val currentGatt = gatt
        if (currentGatt == null || characteristic == null) {
            failConnection("Chessnut notification characteristic is unavailable.")
            return
        }
        try {
            if (!currentGatt.setCharacteristicNotification(characteristic, true)) {
                failConnection("Could not subscribe to Chessnut notifications.")
                return
            }
            val descriptor = characteristic.getDescriptor(CCCD_UUID)
            if (descriptor == null) {
                failConnection("Chessnut notification descriptor is unavailable.")
                return
            }
            configuringDescriptor = characteristic.uuid
            val started = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                currentGatt.writeDescriptor(
                    descriptor,
                    BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE,
                ) == android.bluetooth.BluetoothStatusCodes.SUCCESS
            } else {
                @Suppress("DEPRECATION")
                descriptor.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                @Suppress("DEPRECATION")
                currentGatt.writeDescriptor(descriptor)
            }
            if (!started) failConnection("Could not configure Chessnut notifications.")
        } catch (error: SecurityException) {
            failConnection(error.message ?: "Bluetooth permission was revoked.")
        }
    }

    private fun finishConfiguration() {
        ready = true
        emitStatus("ready", "Chessnut Go is ready.", deviceName)
        enqueueWrite(INIT_COMMAND)
        enqueueWrite(BATTERY_COMMAND)
    }

    private fun handleNotification(uuid: UUID, value: ByteArray) {
        mainHandler.post {
            if (uuid == DATA_UUID && value.size >= 32) {
                emit(mapOf("type" to "position", "data" to value.map { it.toInt() and 0xff }))
            } else if (uuid == CONFIRM_UUID &&
                value.size >= 4 && value[0] == 0x2a.toByte() && value[1] == 0x02.toByte()
            ) {
                val raw = value[2].toInt() and 0xff
                val percent = raw and 0x7f
                if (percent <= 100) {
                    emit(
                        mapOf(
                            "type" to "battery",
                            "percent" to percent,
                            "charging" to ((raw and 0x80) != 0),
                        )
                    )
                }
            }
        }
    }

    private fun setLeds(call: MethodCall, result: MethodChannel.Result) {
        if (!ready) {
            result.error("not_connected", "Chessnut Go is not ready.", null)
            return
        }
        val values = call.argument<List<Number>>("command")
        if (values == null || values.size != 10 || values[0].toInt() != 0x0a || values[1].toInt() != 0x08) {
            result.error("bad_arguments", "Expected a Chessnut LED command.", null)
            return
        }
        enqueueWrite(values.map { it.toInt().toByte() }.toByteArray())
        result.success(null)
    }

    private fun beep(call: MethodCall, result: MethodChannel.Result) {
        if (!ready) {
            result.error("not_connected", "Chessnut Go is not ready.", null)
            return
        }
        val values = call.argument<List<Number>>("command")
        if (values == null || values.size != 6 || values[0].toInt() != 0x0b || values[1].toInt() != 0x04) {
            result.error("bad_arguments", "Expected a Chessnut buzzer command.", null)
            return
        }
        enqueueWrite(
            values.map { it.toInt().toByte() }.toByteArray(),
            failureIsFatal = false,
        )
        result.success(null)
    }

    private fun enqueueWrite(command: ByteArray, failureIsFatal: Boolean = true) {
        writeQueue.add(PendingWrite(command.copyOf(), failureIsFatal))
        writeNext()
    }

    private fun writeNext() {
        if (writeInProgress || writeQueue.isEmpty()) return
        val currentGatt = gatt ?: return
        val characteristic = writeCharacteristic ?: return
        val pendingWrite = writeQueue.removeFirst()
        val command = pendingWrite.command
        activeWrite = pendingWrite
        writeInProgress = true
        try {
            val started = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                currentGatt.writeCharacteristic(
                    characteristic,
                    command,
                    BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT,
                ) == android.bluetooth.BluetoothStatusCodes.SUCCESS
            } else {
                @Suppress("DEPRECATION")
                characteristic.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
                @Suppress("DEPRECATION")
                characteristic.value = command
                @Suppress("DEPRECATION")
                currentGatt.writeCharacteristic(characteristic)
            }
            if (started) return
            writeInProgress = false
            activeWrite = null
            if (pendingWrite.failureIsFatal) {
                failConnection("Could not send a command to Chessnut Go.")
            } else {
                writeNext()
            }
        } catch (error: SecurityException) {
            writeInProgress = false
            activeWrite = null
            failConnection(error.message ?: "Bluetooth permission was revoked.")
        }
    }

    private fun disconnect(message: String) {
        stopScan()
        try {
            gatt?.disconnect()
        } catch (_: SecurityException) {
            disconnectGatt()
        }
        disconnectGatt()
        emitStatus("disconnected", message, deviceName)
    }

    private fun disconnectGatt() {
        ready = false
        serviceDiscoveryStarted = false
        writeCharacteristic = null
        dataCharacteristic = null
        confirmationCharacteristic = null
        configuringDescriptor = null
        writeQueue.clear()
        writeInProgress = false
        activeWrite = null
        try {
            gatt?.close()
        } catch (_: SecurityException) {
            // Nothing else can be released after permission revocation.
        }
        gatt = null
    }

    private fun emitStatus(newState: String, message: String, name: String? = null) {
        state = newState
        stateMessage = message
        emit(
            buildMap<String, Any> {
                put("type", "status")
                put("state", newState)
                put("message", message)
                if (name != null) put("deviceName", name)
            }
        )
    }

    private fun emitError(message: String) = emitStatus("error", message, deviceName)

    private fun failConnection(message: String) {
        disconnectGatt()
        emitError(message)
    }

    private fun emit(event: Map<String, Any>) {
        mainHandler.post { eventSink?.success(event) }
    }

    fun close() {
        pendingPermissionResult?.error("cancelled", "Chessnut connection was cancelled.", null)
        pendingPermissionResult = null
        disconnectGatt()
        stopScan()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }
}

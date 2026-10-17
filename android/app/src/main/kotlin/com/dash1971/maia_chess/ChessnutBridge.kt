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
import android.os.SystemClock
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
        private const val SCAN_TIMEOUT_MS = 3_000L
        private const val WRITE_GAP_MS = 100L

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

    // Connection safety and Chessnut behavior are shared by all channels.
    // BoardChannelPolicy alone decides which board families are permitted.
    private val preferences = activity.getSharedPreferences("verified_electronic_boards", Context.MODE_PRIVATE)
    private data class Candidate(val device: BluetoothDevice, val name: String, val kind: String)
    private val discovery = BoardDiscoveryWindow<Candidate>()
    private var connectMode = "remembered"
    private var requestedBoardId: String? = null
    private var boardId: String? = null
    private var boardKind = "chessnut"
    private var connectionSession = UUID.randomUUID().toString()
    private var selectedAddress: String? = null
    private var motorPending = false
    private val positionFrames = ChessnutNotificationFrames(false)
    private val confirmationFrames = ChessnutNotificationFrames(true)
    private val uartService = UUID.fromString("6e400001-b5a3-f393-e0a9-e50e24dcca9e")
    private val uartWrite = UUID.fromString("6e400002-b5a3-f393-e0a9-e50e24dcca9e")
    private val uartNotify = UUID.fromString("6e400003-b5a3-f393-e0a9-e50e24dcca9e")

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
    private var stateMessage = "Chessnut is disconnected."
    private var deviceName: String? = null
    private var lastGattStatus: Int? = null
    private var scanAttempts = 0
    private var unexpectedDisconnects = 0
    private data class PendingWrite(
        val command: ByteArray,
        val failureIsFatal: Boolean = true,
        val completion: MethodChannel.Result? = null,
    )

    private val writeQueue = ArrayDeque<PendingWrite>()
    private var writeInProgress = false
    private var writeGapInProgress = false
    private var activeWrite: PendingWrite? = null

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "connect" -> {
                if (pendingPermissionResult != null) {
                    result.error("permission_pending", "A Bluetooth permission request is already open.", null); return
                }
                connectMode = call.argument<String>("mode") ?: "remembered"
                requestedBoardId = call.argument<String>("boardId")
                connect(result)
            }
            "discover" -> {
                if (pendingPermissionResult != null) {
                    result.error("permission_pending", "A Bluetooth permission request is already open.", null); return
                }
                disconnect("Board disconnected.")
                connectMode = "discover"
                requestedBoardId = null
                connect(result)
            }
            "selectBoard" -> {
                val candidate = discovery.select(call.argument<String>("candidateId"))
                if (candidate == null || !BoardChannelPolicy.supports(BuildConfig.FLAVOR, candidate.kind)) result.error("stale_candidate", "Choose a board from a fresh search.", null)
                else {
                    discovery.clear()
                    boardKind = candidate.kind
                    boardId = null
                    selectedAddress = candidate.device.address
                    connectGatt(candidate.device, candidate.name)
                    result.success(null)
                }
            }
            "startBoardGame", "movePiece", "acknowledgeMove", "confirmPosition" -> squareOffCommand(call, result)
            "disconnect" -> {
                disconnect("Chessnut disconnected.")
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
        if (ready && boardKind == "chessnut") {
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
        if (result == null) return true
        if (grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
            try {
                if (adapter?.isEnabled != true) {
                    val message = "Turn on Bluetooth, then try again."
                    result?.error("bluetooth_disabled", message, null)
                    emitError(message)
                    return true
                }
                startConnection()
                result?.success(null)
            } catch (error: Throwable) {
                result?.error("connect_failed", error.message, null)
                emitError(error.message ?: "Could not start Chessnut scan.")
            }
        } else {
            val message = "Bluetooth permission is required to connect Chessnut."
            result?.error("permission_denied", message, null)
            emitError(message)
        }
        return true
    }

    private fun connect(result: MethodChannel.Result) {
        // Legacy saves have no identity: start a fresh Chessnut-only search,
        // never reuse an unrelated ready/in-flight connection.
        if (BoardReconnectPolicy.needsFreshConnection(connectMode, requestedBoardId, boardId)) {
            stopScan()
            disconnectGatt()
            state = "disconnected"
        }
        if (ready) {
            emitStatus("ready", "Chessnut is ready.", deviceName)
            if (boardKind == "pegasus") {
                // Dart resets occupancy history when reconnecting after a parser error.
                // Field updates cannot recover that history without a fresh complete dump.
                enqueueWrite(byteArrayOf(0x5a))
                enqueueWrite(byteArrayOf(0x42))
            }
            result.success(null)
            return
        }
        if (scanCallback != null || (gatt != null && (state == "connecting" || state == "connected"))) {
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
            startConnection()
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

    private fun startConnection() {
        if (BoardReconnectPolicy.needsLegacyDiscovery(connectMode, requestedBoardId)) {
            // Pre-promotion Chessnut saves have no board identity. Discover only
            // Chessnut, then establish an identity after physical-position sync.
            startScan()
            return
        }
        if (connectMode != "discover") {
            val targetId = requestedBoardId ?: boardId ?: preferences.getString("last_id", null)
            val address = targetId?.let { preferences.getString("address_$it", null) }
            if (address != null) {
                disconnectGatt()
                boardId = targetId
                selectedAddress = address
                boardKind = preferences.getString("kind_$targetId", "chessnut") ?: "chessnut"
                connectGatt(adapter!!.getRemoteDevice(address), preferences.getString("name_$targetId", "Board") ?: "Board")
                return
            }
            if (connectMode == "reconnect") throw IllegalStateException("The selected board is unavailable. Continue on the phone or explicitly choose another board.")
        }
        startScan()
    }

    private fun startScan() {
        connectionSession = UUID.randomUUID().toString()
        disconnectGatt()
        discovery.clear()
        boardId = null
        scanAttempts++
        val scanner = adapter?.bluetoothLeScanner
            ?: throw IllegalStateException("Bluetooth LE scanning is unavailable.")
        emitStatus("scanning", "Searching for Chessnut…")
        val callback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                val name = try {
                    result.device.name ?: result.scanRecord?.deviceName ?: ""
                } catch (_: SecurityException) {
                    ""
                }
                mainHandler.post {
                    if (scanCallback !== this) return@post
                    val kind = BoardChannelPolicy.discover(BuildConfig.FLAVOR, name) ?: return@post
                    if (BoardReconnectPolicy.needsLegacyDiscovery(connectMode, requestedBoardId) && kind != "chessnut") return@post
                    val address = result.device.address
                    discovery.add(address, Candidate(result.device, name, kind))
                }
            }

            override fun onScanFailed(errorCode: Int) {
                mainHandler.post {
                if (scanCallback !== this) return@post
                stopScan()
                emitStatus(
                    "error",
                    "Chessnut scan failed (code $errorCode).",
                    deviceName,
                    "scanErrorCode=$errorCode",
                )
                }
            }
        }
        scanCallback = callback
        scanner.startScan(callback)
        mainHandler.postDelayed({
            if (scanCallback === callback) {
                stopScan()
                val candidates = discovery.snapshot()
                when (candidates.size) {
                    0 -> emitError("No board found. Check that the board is on and nearby.")
                    1 -> {
                        val candidate = candidates.values.first()
                        discovery.clear()
                        boardKind = candidate.kind
                        selectedAddress = candidate.device.address
                        connectGatt(candidate.device, candidate.name)
                    }
                    else -> {
                        emitStatus("choosing", "Choose a board.")
                        emit(mapOf("type" to "candidates", "candidates" to candidates.map { (id, candidate) ->
                            mapOf("id" to id, "name" to candidate.name, "kind" to candidate.kind)
                        }))
                    }
                }
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
        check(BoardChannelPolicy.supports(BuildConfig.FLAVOR, boardKind)) {
            "This board is available only in the Dev build."
        }
        connectionSession = UUID.randomUUID().toString()
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
            if (gatt == null) failConnection("Could not open the Chessnut connection.")
            val source = gatt
            mainHandler.postDelayed({
                if (gatt === source && !ready) failConnection("Board connection timed out. Try reconnecting.")
            }, 15_000L)
        } catch (error: SecurityException) {
            failConnection(error.message ?: "Bluetooth permission was revoked.")
        }
    }

    private val gattCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            mainHandler.post {
                if (this@ChessnutBridge.gatt !== gatt) return@post
                lastGattStatus = status
                if (status != BluetoothGatt.GATT_SUCCESS &&
                    newState != BluetoothProfile.STATE_DISCONNECTED
                ) {
                    failConnection("Chessnut connection failed (status $status).")
                    return@post
                }
                when (newState) {
                    BluetoothProfile.STATE_CONNECTED -> {
                        emitStatus("connected", "Connected; configuring Chessnut…", deviceName)
                        try {
                            if (!gatt.requestMtu(500)) discoverServicesOnce(gatt)
                        } catch (error: SecurityException) {
                            failConnection(error.message ?: "Bluetooth permission was revoked.")
                        }
                    }
                    BluetoothProfile.STATE_DISCONNECTED -> {
                        val unexpected = state != "disconnected"
                        if (unexpected) unexpectedDisconnects++
                        disconnectGatt()
                        if (unexpected) {
                            emitStatus(
                                "disconnected",
                                "Chessnut connection was lost. Tap reconnect to continue.",
                                deviceName,
                                "gattStatus=$status newState=$newState",
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
                handleNotification(gatt, characteristic.uuid, characteristic.value ?: byteArrayOf())
            }
        }

        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray,
        ) {
            if (this@ChessnutBridge.gatt === gatt) {
                handleNotification(gatt, characteristic.uuid, value)
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
                if (descriptor.characteristic.uuid != configuringDescriptor) return@post
                when (configuringDescriptor) {
                    DATA_UUID -> enableNotifications(confirmationCharacteristic)
                    CONFIRM_UUID, uartNotify -> finishConfiguration()
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
                if (!writeInProgress || activeWrite == null || characteristic.uuid != writeCharacteristic?.uuid) return@post
                writeInProgress = false
                val completedWrite = activeWrite
                activeWrite = null
                if (status != BluetoothGatt.GATT_SUCCESS) {
                    completedWrite?.completion?.error(
                        "write_failed",
                        "Chessnut command failed (status $status).",
                        null,
                    )
                    if (completedWrite?.failureIsFatal != false) {
                        failConnection("Chessnut command failed (status $status).")
                    } else {
                        scheduleNextWrite()
                    }
                    return@post
                }
                completedWrite?.completion?.success(null)
                scheduleNextWrite()
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
        if (!BoardChannelPolicy.supports(BuildConfig.FLAVOR, boardKind)) {
            failConnection("This board is available only in the Dev build."); return
        }
        if (boardKind == "chessnut") {
            writeCharacteristic = findCharacteristic(services, WRITE_UUID)
            dataCharacteristic = findCharacteristic(services, DATA_UUID)
            confirmationCharacteristic = findCharacteristic(services, CONFIRM_UUID)
        } else {
            val service = services.firstOrNull { it.uuid == uartService }
            writeCharacteristic = service?.getCharacteristic(uartWrite)
            dataCharacteristic = service?.getCharacteristic(uartNotify)
            confirmationCharacteristic = null
        }
        val write = writeCharacteristic
        val data = dataCharacteristic
        if (write == null || data == null ||
            (boardKind == "chessnut" && confirmationCharacteristic == null) ||
            (write.properties and (BluetoothGattCharacteristic.PROPERTY_WRITE or BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE) == 0) ||
            (data.properties and BluetoothGattCharacteristic.PROPERTY_NOTIFY == 0)) {
            failConnection("The connected board does not expose the expected $boardKind BLE profile.")
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
        if (!BoardChannelPolicy.supports(BuildConfig.FLAVOR, boardKind)) {
            failConnection("This board is available only in the Dev build."); return
        }
        ready = true
        emitStatus("ready", "Chessnut is ready.", deviceName)
        if (selectedAddress != null) {
            val address = selectedAddress!!
            val existing = preferences.getString("id_$address", null)
            boardId = existing ?: UUID.randomUUID().toString()
            preferences.edit().putString("id_$address", boardId)
                .putString("address_$boardId", address).putString("kind_$boardId", boardKind)
                .putString("name_$boardId", deviceName).putString("last_id", boardId).apply()
            emitStatus("ready", "$deviceName is ready.", deviceName)
        }
        when (boardKind) {
            "chessnut" -> { enqueueWrite(INIT_COMMAND); enqueueWrite(BATTERY_COMMAND) }
            "pegasus" -> {
                // No manufacturer application key: compatibility requires an already unlocked profile.
                enqueueWrite(byteArrayOf(0x5a)); enqueueWrite(byteArrayOf(0x44)); enqueueWrite(byteArrayOf(0x42))
            }
            "squareOff" -> enqueueWrite("xCONNECTEDz".toByteArray(Charsets.US_ASCII))
        }
    }

    private fun handleNotification(source: BluetoothGatt, uuid: UUID, value: ByteArray) {
        val snapshot = value.copyOf()
        mainHandler.post {
            if (gatt !== source) return@post
            if (boardKind != "chessnut") {
                if (snapshot.size <= 1024) emit(mapOf("type" to "boardData", "boardKind" to boardKind,
                    "data" to snapshot.map { it.toInt() and 255 }, "connectionSession" to connectionSession), source)
                return@post
            }
            val frames = when (uuid) {
                DATA_UUID -> positionFrames.feed(snapshot, SystemClock.elapsedRealtime())
                CONFIRM_UUID -> confirmationFrames.feed(snapshot, SystemClock.elapsedRealtime())
                else -> emptyList()
            }
            for (frame in frames) {
                if (uuid == DATA_UUID) emit(mapOf("type" to "position", "data" to frame.map { it.toInt() and 255 },
                    "nativeReady" to ready, "gattPresent" to true), source)
                else if (frame.contentEquals(byteArrayOf(0x0f, 0x01, 0x02))) {
                    emit(mapOf("type" to "newGame", "connectionSession" to connectionSession), source)
                } else if (frame.size == 4 && frame[0] == 0x2a.toByte()) {
                    val raw = frame[2].toInt() and 255
                    if ((raw and 127) <= 100) emit(mapOf("type" to "battery", "percent" to (raw and 127),
                        "charging" to ((raw and 128) != 0)), source)
                }
            }
        }
    }

    private fun setLeds(call: MethodCall, result: MethodChannel.Result) {
        if (!ready) {
            result.error("not_connected", "Chessnut is not ready.", null)
            return
        }
        if (boardKind == "pegasus") {
            val squares = call.argument<List<Number>>("squares")?.map { it.toInt() }
            if (squares == null || squares.size > 64 || squares.any { it !in 0..63 }) {
                result.error("bad_arguments", "Expected DGT square indices.", null); return
            }
            val command = ElectronicBoardProtocol.pegasusLeds(squares)
            enqueueWrite(command, completion = result); return
        }
        if (boardKind != "chessnut") { result.error("unsupported", "This board has no LED guidance.", null); return }
        val values = call.argument<List<Number>>("command")
        if (values == null || values.size != 10 || values[0].toInt() != 0x0a || values[1].toInt() != 0x08) {
            result.error("bad_arguments", "Expected a Chessnut LED command.", null)
            return
        }
        enqueueWrite(
            values.map { it.toInt().toByte() }.toByteArray(),
            completion = result,
        )
    }

    private fun beep(call: MethodCall, result: MethodChannel.Result) {
        if (boardKind != "chessnut") { result.error("unsupported", "This board has no buzzer adapter.", null); return }
        if (!ready) {
            result.error("not_connected", "Chessnut is not ready.", null)
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
            completion = result,
        )
    }

    private fun squareOffCommand(call: MethodCall, result: MethodChannel.Result) {
        if (BuildConfig.FLAVOR != "dev" || !ready || boardKind != "squareOff" || call.argument<String>("connectionSession") != connectionSession) {
            result.error("invalid_session", "The selected board session is unavailable.", null); return
        }
        if (call.method == "confirmPosition") {
            // Explicit local reconciliation only; never send an unsupported physical command.
            motorPending = false
            result.success(null)
            return
        }
        if (motorPending && call.method == "startBoardGame") {
            result.error("motor_busy", "Confirm the prior board movement before starting a game.", null); return
        }
        val command = when (call.method) {
            "startBoardGame" -> when (call.argument<String>("player")) {
                "white" -> "GAMEWHITE"; "black" -> "GAMEBLACK"; "live" -> "LIVE"
                else -> { result.error("bad_arguments", "Expected player colour.", null); return }
            }
            "acknowledgeMove" -> if (call.argument<Boolean>("accepted") == true) {
                // Dart has verified a subsequent legal physical move in the current position.
                // GAMEWHITE/GAMEBLACK firmware need not report an explicit motor OK.
                motorPending = false
                "OK"
            } else "ERR"
            else -> {
                val uci = call.argument<String>("uci") ?: ""
                if (runCatching { ElectronicBoardProtocol.squareOffMove(uci, call.argument<String>("connectionSession"), connectionSession) }.isFailure) {
                    result.error("bad_arguments", "Expected a four-character board move.", null); return
                }
                if (motorPending || writeInProgress || writeQueue.isNotEmpty()) {
                    result.error("motor_busy", "Confirm the prior board movement before sending another.", null); return
                }
                motorPending = true
                uci
            }
        }
        if (call.method == "startBoardGame") enqueueWrite("xRSTVARz".toByteArray(Charsets.US_ASCII))
        enqueueWrite("x${command}z".toByteArray(Charsets.US_ASCII), completion = result)
    }

    private fun enqueueWrite(
        command: ByteArray,
        failureIsFatal: Boolean = true,
        completion: MethodChannel.Result? = null,
    ) {
        if (!BoardChannelPolicy.supports(BuildConfig.FLAVOR, boardKind)) {
            completion?.error("unsupported", "This board is available only in the Dev build.", null)
            return
        }
        if (isLedCommand(command)) {
            // LED state is absolute, not an event. Keep only the newest queued
            // state so rapid board notifications cannot replay stale guidance.
            val iterator = writeQueue.iterator()
            while (iterator.hasNext()) {
                val queued = iterator.next()
                if (isLedCommand(queued.command)) {
                    iterator.remove()
                    queued.completion?.success(null)
                }
            }
            if (activeWrite?.command?.contentEquals(command) == true) {
                completion?.success(null)
                return
            }
        }
        if (writeQueue.size >= 32) {
            completion?.error("queue_full", "Board command queue is full.", null)
            return
        }
        writeQueue.add(PendingWrite(command.copyOf(), failureIsFatal, completion))
        writeNext()
    }

    private fun writeNext() {
        if (writeInProgress || writeGapInProgress || writeQueue.isEmpty()) return
        val currentGatt = gatt ?: return
        val characteristic = writeCharacteristic ?: return
        val pendingWrite = writeQueue.removeFirst()
        val writeType = if (characteristic.properties and BluetoothGattCharacteristic.PROPERTY_WRITE != 0)
            BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT else BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
        val command = pendingWrite.command
        activeWrite = pendingWrite
        writeInProgress = true
        try {
            val started = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                currentGatt.writeCharacteristic(
                    characteristic,
                    command,
                    writeType,
                ) == android.bluetooth.BluetoothStatusCodes.SUCCESS
            } else {
                @Suppress("DEPRECATION")
                characteristic.writeType = writeType
                @Suppress("DEPRECATION")
                characteristic.value = command
                @Suppress("DEPRECATION")
                currentGatt.writeCharacteristic(characteristic)
            }
            if (started) {
                mainHandler.postDelayed({
                    if (gatt === currentGatt && activeWrite === pendingWrite) failConnection("Board command acknowledgement timed out. Reconnect before continuing.")
                }, 5_000L)
                return
            }
            writeInProgress = false
            activeWrite = null
            pendingWrite.completion?.error(
                "write_not_started",
                "Could not send a command to Chessnut.",
                null,
            )
            if (pendingWrite.failureIsFatal) {
                failConnection("Could not send a command to Chessnut.")
            } else {
                scheduleNextWrite()
            }
        } catch (error: SecurityException) {
            writeInProgress = false
            activeWrite = null
            pendingWrite.completion?.error(
                "permission_revoked",
                error.message ?: "Bluetooth permission was revoked.",
                null,
            )
            failConnection(error.message ?: "Bluetooth permission was revoked.")
        }
    }

    private fun scheduleNextWrite() {
        if (writeGapInProgress) return
        writeGapInProgress = true
        val source = gatt
        mainHandler.postDelayed({
            if (gatt !== source) return@postDelayed
            writeGapInProgress = false
            writeNext()
        }, WRITE_GAP_MS)
    }

    private fun isLedCommand(command: ByteArray): Boolean =
        command.size == 10 && command[0] == 0x0a.toByte() && command[1] == 0x08.toByte()

    private fun disconnect(message: String) {
        connectionSession = UUID.randomUUID().toString()
        pendingPermissionResult?.error("cancelled", "Board connection was cancelled.", null)
        pendingPermissionResult = null
        stopScan()
        discovery.clear()
        try {
            gatt?.disconnect()
        } catch (_: SecurityException) {
            disconnectGatt()
        }
        disconnectGatt()
        emitStatus("disconnected", message, deviceName)
    }

    private fun disconnectGatt() {
        activeWrite?.completion?.error(
            "connection_closed",
            "Chessnut connection closed before the command completed.",
            null,
        )
        writeQueue.forEach { pending ->
            pending.completion?.error(
                "connection_closed",
                "Chessnut connection closed before the command completed.",
                null,
            )
        }
        ready = false
        positionFrames.reset()
        confirmationFrames.reset()
        motorPending = false
        serviceDiscoveryStarted = false
        writeCharacteristic = null
        dataCharacteristic = null
        confirmationCharacteristic = null
        configuringDescriptor = null
        writeQueue.clear()
        writeInProgress = false
        writeGapInProgress = false
        activeWrite = null
        try {
            gatt?.close()
        } catch (_: SecurityException) {
            // Nothing else can be released after permission revocation.
        }
        gatt = null
    }

    private fun emitStatus(
        newState: String,
        message: String,
        name: String? = null,
        diagnostic: String? = null,
    ) {
        state = newState
        stateMessage = message
        val errorDiagnostic = if (newState == "error") {
            // Only fixed categories enter exported diagnostics; exception text
            // and Bluetooth device names remain in the UI event only.
            val reason = when {
                message.startsWith("Chessnut scan failed") -> "scan-failed"
                message.startsWith("Chessnut connection failed") -> "connection-failed"
                message.startsWith("Chessnut service discovery failed") -> "service-discovery-failed"
                message.startsWith("Chessnut command failed") -> "command-failed"
                message == "Could not send a command to Chessnut." -> "write-not-started"
                message.startsWith("Could not enable Chessnut notifications") -> "notification-setup-failed"
                else -> "other-native-error"
            }
            "errorSource=native reason=$reason nativeReady=$ready gattPresent=${gatt != null}"
        } else {
            null
        }
        emit(
            buildMap<String, Any> {
                put("type", "status")
                put("boardKind", boardKind)
                boardId?.let { put("boardId", it) }
                put("connectionSession", connectionSession)
                put("capabilities", mapOf("pieceIdentity" to (boardKind == "chessnut"),
                    "occupancy" to (boardKind == "pegasus"), "leds" to (boardKind != "squareOff"),
                    "sound" to (boardKind == "chessnut"), "battery" to (boardKind == "chessnut"),
                    "physicalButtons" to (boardKind == "chessnut"), "motors" to (boardKind == "squareOff")))
                put("state", newState)
                put("message", message)
                if (name != null) put("deviceName", name)
                val details = listOfNotNull(errorDiagnostic, diagnostic).joinToString(" ")
                if (details.isNotEmpty()) put("diagnostic", details)
            },
            expectedGatt = if (newState == "ready" || newState == "connected") gatt else null,
        )
    }

    private fun emitError(message: String) = emitStatus("error", message, deviceName)

    private fun failConnection(message: String) {
        disconnectGatt()
        emitError(message)
    }

    private fun emit(event: Map<String, Any>, expectedGatt: BluetoothGatt? = null) {
        val sessionSnapshot = connectionSession
        val decorated = buildMap<String, Any> {
            putAll(event)
            put("connectionSession", sessionSnapshot)
            put("boardKind", boardKind)
            boardId?.let { put("boardId", it) }
        }
        mainHandler.post {
            if (connectionSession != sessionSnapshot) return@post
            if (expectedGatt != null && gatt !== expectedGatt) return@post
            eventSink?.success(decorated)
        }
    }

    fun diagnosticsSnapshot(): Map<String, Any> {
        val available = adapter != null
        val enabled = try {
            adapter?.isEnabled ?: false
        } catch (_: SecurityException) {
            false
        }
        val permissions = requiredPermissions().joinToString(",") { permission ->
            val shortName = permission.substringAfterLast('.')
            val granted = ContextCompat.checkSelfPermission(activity, permission) ==
                PackageManager.PERMISSION_GRANTED
            "$shortName=$granted"
        }
        return buildMap {
            put("available", available)
            put("enabled", enabled)
            put("permissions", permissions)
            put("state", state)
            put("ready", ready)
            put("scanActive", scanCallback != null)
            put("gattPresent", gatt != null)
            put("lastGattStatus", lastGattStatus ?: -1)
            put("scanAttempts", scanAttempts)
            put("unexpectedDisconnects", unexpectedDisconnects)
            put("pendingWrites", writeQueue.size + if (activeWrite == null) 0 else 1)
        }
    }

    fun close() {
        connectionSession = UUID.randomUUID().toString()
        eventSink = null
        pendingPermissionResult?.error("cancelled", "Chessnut connection was cancelled.", null)
        pendingPermissionResult = null
        disconnectGatt()
        stopScan()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }
}

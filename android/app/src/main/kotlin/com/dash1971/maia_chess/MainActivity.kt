package com.dash1971.maia_chess

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.app.ActivityManager
import android.os.Build
import android.view.WindowManager
import android.system.Os
import android.system.OsConstants
import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.security.MessageDigest
import java.nio.FloatBuffer
import java.nio.LongBuffer
import java.util.concurrent.Executors

private object MaiaEngine {
    private const val MODEL_ASSET = "flutter_assets/assets/models/maia3-79m.onnx"
    private const val MODEL_FILE = "maia3-79m-3454b03a-sha256.onnx"
    private const val EXPECTED_MODEL_BYTES = 316_034_244L
    private val environment = OrtEnvironment.getEnvironment()
    private val executor = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "maia-inference").apply { isDaemon = true }
    }
    private var session: OrtSession? = null

    fun execute(block: () -> Unit) = executor.execute(block)

    fun release() = executor.execute {
        synchronized(this) {
            session?.close()
            session = null
        }
    }

    @Synchronized
    fun session(context: Context, onPhase: (String) -> Unit): OrtSession {
        session?.let {
            onPhase("maia-session-cached")
            return it
        }
        val model = cachedModel(context, onPhase)
        onPhase("maia-session-create")
        val created = OrtSession.SessionOptions().use { options ->
            // Keep peak memory and thread pressure predictable on 6 GB phones.
            options.setIntraOpNumThreads(2)
            options.setInterOpNumThreads(1)
            options.setExecutionMode(OrtSession.SessionOptions.ExecutionMode.SEQUENTIAL)
            options.setOptimizationLevel(OrtSession.SessionOptions.OptLevel.BASIC_OPT)
            options.setMemoryPatternOptimization(false)
            environment.createSession(model.absolutePath, options)
        }
        session = created
        return created
    }

    fun modelCacheBytes(context: Context): Long = File(context.cacheDir, MODEL_FILE).length()

    fun modelCacheValid(context: Context): Boolean = modelCacheBytes(context) == EXPECTED_MODEL_BYTES

    fun expectedModelBytes(): Long = EXPECTED_MODEL_BYTES

    private fun cachedModel(context: Context, onPhase: (String) -> Unit): File {
        val target = File(context.cacheDir, MODEL_FILE)
        if (target.length() == EXPECTED_MODEL_BYTES) {
            onPhase("maia-model-cache-hit")
            return target
        }

        onPhase("maia-model-copy")
        val temporary = File(context.cacheDir, "$MODEL_FILE.tmp")
        if (temporary.exists() && !temporary.delete()) {
            throw IOException("Could not clear an incomplete Maia model")
        }
        try {
            val digest = MessageDigest.getInstance("SHA-256")
            context.assets.open(MODEL_ASSET).use { input ->
                FileOutputStream(temporary).use { output ->
                    val buffer = ByteArray(1024 * 1024)
                    while (true) {
                        val count = input.read(buffer)
                        if (count < 0) break
                        digest.update(buffer, 0, count)
                        output.write(buffer, 0, count)
                    }
                    output.fd.sync()
                }
            }
            if (temporary.length() != EXPECTED_MODEL_BYTES) {
                throw IOException(
                    "Maia model copy has ${temporary.length()} bytes; expected $EXPECTED_MODEL_BYTES"
                )
            }
            onPhase("maia-model-checksum")
            val sha256 = digest.digest().joinToString("") { "%02x".format(it) }
            if (sha256 != "3454b03ae78baa64a87b345fdb1a457265d912caec531039b074f07eda0d8010") {
                throw IOException("Maia model checksum mismatch")
            }
            if (target.exists() && !target.delete()) {
                throw IOException("Could not replace an invalid Maia model")
            }
            if (!temporary.renameTo(target)) {
                throw IOException("Could not publish the verified Maia model")
            }
            // Remove older caches only after the SHA-256-verified copy is durable.
            File(context.cacheDir, "maia3-79m-3454b03a.onnx").delete()
            File(context.cacheDir, "maia3-79m.onnx").delete()
            return target
        } finally {
            if (temporary.exists()) temporary.delete()
        }
    }
}

class MainActivity : FlutterActivity() {
    private val channelName = "maia_chess/engine"
    private var methodChannel: MethodChannel? = null
    private var chessnutBridge: ChessnutBridge? = null
    private val documents by lazy { PgnDocuments(this) { methodChannel?.invokeMethod("pgnReceived", null) } }

    @Volatile
    private var engineAttached = false

    private fun setProcessPhase(phase: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return
        try {
            val value = phase.take(128).toByteArray(Charsets.UTF_8)
            (getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager)
                .setProcessStateSummary(value)
        } catch (_: RuntimeException) {
            // Process-state summaries are diagnostic hints and may be throttled.
        }
    }

    private fun exitReasonName(reason: Int): String = when (reason) {
        0 -> "unknown"
        1 -> "exit-self"
        2 -> "signaled"
        3 -> "low-memory"
        4 -> "crash"
        5 -> "native-crash"
        6 -> "anr"
        7 -> "initialization-failure"
        8 -> "permission-change"
        9 -> "excessive-resource-usage"
        10 -> "user-requested"
        11 -> "user-stopped"
        12 -> "dependency-died"
        13 -> "other"
        14 -> "freezer"
        15 -> "package-state-change"
        16 -> "package-updated"
        17 -> "anomaly"
        18 -> "memory-limiter"
        else -> "reason-$reason"
    }

    private fun previousExits(activityManager: ActivityManager): List<Map<String, Any>> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return emptyList()
        return try {
            activityManager.getHistoricalProcessExitReasons(packageName, 0, 3).map { info ->
                buildMap {
                    put("timestampMs", info.timestamp)
                    put("reason", info.reason)
                    put("reasonName", exitReasonName(info.reason))
                    put("status", info.status)
                    put("importance", info.importance)
                    put("pssKb", info.pss)
                    put("rssKb", info.rss)
                    put(
                        "description",
                        (info.description ?: "")
                            .replace('\n', ' ')
                            .replace('\r', ' ')
                            .take(300),
                    )
                    put(
                        "stateSummary",
                        info.processStateSummary
                            ?.toString(Charsets.UTF_8)
                            ?.replace('\n', ' ')
                            ?.replace('\r', ' ')
                            ?.take(128)
                            ?: "",
                    )
                }
            }
        } catch (_: RuntimeException) {
            emptyList()
        }
    }

    private fun systemDiagnostics(): Map<String, Any> {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memory = ActivityManager.MemoryInfo().also(activityManager::getMemoryInfo)
        val runtime = Runtime.getRuntime()
        val pageSize = try {
            Os.sysconf(OsConstants._SC_PAGESIZE)
        } catch (_: Exception) {
            -1L
        }
        return buildMap {
            put("manufacturer", Build.MANUFACTURER)
            put("model", Build.MODEL)
            put("device", Build.DEVICE)
            put("product", Build.PRODUCT)
            put("androidRelease", Build.VERSION.RELEASE)
            put("sdkInt", Build.VERSION.SDK_INT)
            put("securityPatch", Build.VERSION.SECURITY_PATCH)
            put("buildId", Build.ID)
            put("buildDisplay", Build.DISPLAY)
            put("supportedAbis", Build.SUPPORTED_ABIS.toList())
            put("pageSizeBytes", pageSize)
            put("processors", runtime.availableProcessors())
            put("ramTotalBytes", memory.totalMem)
            put("ramAvailableBytes", memory.availMem)
            put("ramLowThresholdBytes", memory.threshold)
            put("ramLow", memory.lowMemory)
            put("lowRamDevice", activityManager.isLowRamDevice)
            put("memoryClassMb", activityManager.memoryClass)
            put("largeMemoryClassMb", activityManager.largeMemoryClass)
            put("heapMaxBytes", runtime.maxMemory())
            put("heapTotalBytes", runtime.totalMemory())
            put("heapFreeBytes", runtime.freeMemory())
            put("storageFreeBytes", filesDir.freeSpace)
            put("storageTotalBytes", filesDir.totalSpace)
            put("modelCacheBytes", MaiaEngine.modelCacheBytes(applicationContext))
            put("modelCacheExpectedBytes", MaiaEngine.expectedModelBytes())
            put("modelCacheValid", MaiaEngine.modelCacheValid(applicationContext))
            put("bluetooth", chessnutBridge?.diagnosticsSnapshot() ?: emptyMap<String, Any>())
            put("previousExits", previousExits(activityManager))
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                put(
                    "lowMemoryKillReportSupported",
                    ActivityManager.isLowMemoryKillReportSupported(),
                )
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        engineAttached = true
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).also {
            it.setMethodCallHandler { call, result ->
                when (call.method) {
                    "dataDirectory" -> result.success(filesDir.absolutePath)
                    "systemDiagnostics" -> result.success(systemDiagnostics())
                    "getPendingPgn" -> documents.takePending(result)
                    "openPgnFile" -> documents.open(result)
                    "savePgnFile" -> documents.save(call.argument<String>("pgn") ?: "", result)
                    "sharePgn" -> documents.share(call.argument<String>("pgn") ?: "", result)
                    "openUrl" -> {
                        val uri = call.argument<String>("url")?.let(Uri::parse)
                        if (uri == null || uri.scheme?.lowercase() !in setOf("http", "https")) {
                            result.error("bad_arguments", "Expected an HTTP or HTTPS URL", null)
                            return@setMethodCallHandler
                        }
                        try {
                            startActivity(
                                Intent(Intent.ACTION_VIEW, uri).addCategory(Intent.CATEGORY_BROWSABLE)
                            )
                            result.success(null)
                        } catch (error: ActivityNotFoundException) {
                            result.error("url_unavailable", "No app can open this URL", null)
                        } catch (error: SecurityException) {
                            result.error("url_blocked", error.message, null)
                        }
                    }

                    "setKeepScreenOn" -> {
                        val enabled = call.argument<Boolean>("enabled")
                        if (enabled == null) {
                            result.error("bad_arguments", "Expected enabled", null)
                        } else {
                            if (enabled) {
                                window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                            } else {
                                window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                            }
                            result.success(null)
                        }
                    }

                    "release" -> {
                        MaiaEngine.release()
                        result.success(null)
                    }

                    "predict" -> predict(call.argument("tokens"), call.argument("selfElo"), call.argument("opponentElo"), result)
                    else -> result.notImplemented()
                }
            }
        }
        chessnutBridge = ChessnutBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        setProcessPhase("app-ready")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        documents.consumeIntent(intent)
    }

    override fun onStart() {
        super.onStart()
        documents.consumeIntent(intent)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (!documents.onResult(requestCode, resultCode, data)) super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        if (chessnutBridge?.onRequestPermissionsResult(requestCode, permissions, grantResults) == true) {
            return
        }
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    override fun onDestroy() {
        documents.close()
        super.onDestroy()
    }

    private fun predict(
        tokens: FloatArray?,
        selfElo: Int?,
        opponentElo: Int?,
        result: MethodChannel.Result,
    ) {
        if (tokens == null || tokens.size != 64 * 97 || selfElo == null || opponentElo == null) {
            result.error("bad_arguments", "Expected 6208 float tokens and two Elo values", null)
            return
        }
        val appContext = applicationContext
        setProcessPhase("maia-queued")
        MaiaEngine.execute {
            try {
                setProcessPhase("maia-input-tensors")
                OnnxTensor.createTensor(
                    OrtEnvironment.getEnvironment(),
                    FloatBuffer.wrap(tokens),
                    longArrayOf(1, 64, 97),
                ).use { tokenTensor ->
                    OnnxTensor.createTensor(
                        OrtEnvironment.getEnvironment(),
                        LongBuffer.wrap(longArrayOf(selfElo.toLong())),
                        longArrayOf(1),
                    ).use { selfTensor ->
                        OnnxTensor.createTensor(
                            OrtEnvironment.getEnvironment(),
                            LongBuffer.wrap(longArrayOf(opponentElo.toLong())),
                            longArrayOf(1),
                        ).use { opponentTensor ->
                            val session = MaiaEngine.session(appContext, ::setProcessPhase)
                            setProcessPhase("maia-inference")
                            session.run(
                                mapOf(
                                    "tokens" to tokenTensor,
                                    "self_elo" to selfTensor,
                                    "opponent_elo" to opponentTensor,
                                )
                            ).use { outputs ->
                                @Suppress("UNCHECKED_CAST")
                                val logits = outputs.get("move_logits").get().value as Array<FloatArray>
                                val payload = logits[0].copyOf()
                                setProcessPhase("app-ready")
                                runOnUiThread {
                                    if (engineAttached) result.success(payload)
                                }
                            }
                        }
                    }
                }
            } catch (error: Throwable) {
                setProcessPhase("maia-error")
                runOnUiThread {
                    if (engineAttached) {
                        result.error("inference_failed", error.message, error.stackTraceToString())
                    }
                }
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        engineAttached = false
        chessnutBridge?.close()
        chessnutBridge = null
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}

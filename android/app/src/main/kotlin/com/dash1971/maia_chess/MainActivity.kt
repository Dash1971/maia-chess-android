package com.dash1971.maia_chess

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.WindowManager
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
    fun session(context: Context): OrtSession {
        session?.let { return it }
        val model = cachedModel(context)
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

    private fun cachedModel(context: Context): File {
        val target = File(context.cacheDir, MODEL_FILE)
        if (target.length() == EXPECTED_MODEL_BYTES) return target

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
    private val documents by lazy { PgnDocuments(this) { methodChannel?.invokeMethod("pgnReceived", null) } }

    @Volatile
    private var engineAttached = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        engineAttached = true
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).also {
            it.setMethodCallHandler { call, result ->
                when (call.method) {
                    "dataDirectory" -> result.success(filesDir.absolutePath)
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
        MaiaEngine.execute {
            try {
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
                            MaiaEngine.session(appContext).run(
                                mapOf(
                                    "tokens" to tokenTensor,
                                    "self_elo" to selfTensor,
                                    "opponent_elo" to opponentTensor,
                                )
                            ).use { outputs ->
                                @Suppress("UNCHECKED_CAST")
                                val logits = outputs.get("move_logits").get().value as Array<FloatArray>
                                val payload = logits[0].copyOf()
                                runOnUiThread {
                                    if (engineAttached) result.success(payload)
                                }
                            }
                        }
                    }
                }
            } catch (error: Throwable) {
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
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}

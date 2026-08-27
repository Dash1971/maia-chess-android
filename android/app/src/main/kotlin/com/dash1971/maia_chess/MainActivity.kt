package com.dash1971.maia_chess

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.nio.FloatBuffer
import java.nio.LongBuffer
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val channelName = "maia_chess/engine"
    private val environment by lazy { OrtEnvironment.getEnvironment() }
    private val session: OrtSession by lazy {
        val model = File(cacheDir, "maia3-79m.onnx")
        if (!model.exists() || model.length() == 0L) {
            assets.open("flutter_assets/assets/models/maia3-79m.onnx").use { input ->
                FileOutputStream(model).use { output -> input.copyTo(output) }
            }
        }
        environment.createSession(model.absolutePath, OrtSession.SessionOptions())
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "predict") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val tokens = call.argument<List<Double>>("tokens")
                val selfElo = call.argument<Int>("selfElo")
                val opponentElo = call.argument<Int>("opponentElo")
                if (tokens == null || tokens.size != 64 * 97 || selfElo == null || opponentElo == null) {
                    result.error("bad_arguments", "Expected 6208 tokens and two Elo values", null)
                    return@setMethodCallHandler
                }
                thread(name = "maia-inference") {
                    try {
                        val tokenFloats = FloatArray(tokens.size) { tokens[it].toFloat() }
                        OnnxTensor.createTensor(
                            environment,
                            FloatBuffer.wrap(tokenFloats),
                            longArrayOf(1, 64, 97),
                        ).use { tokenTensor ->
                            OnnxTensor.createTensor(
                                environment,
                                LongBuffer.wrap(longArrayOf(selfElo.toLong())),
                                longArrayOf(1),
                            ).use { selfTensor ->
                                OnnxTensor.createTensor(
                                    environment,
                                    LongBuffer.wrap(longArrayOf(opponentElo.toLong())),
                                    longArrayOf(1),
                                ).use { opponentTensor ->
                                    session.run(
                                        mapOf(
                                            "tokens" to tokenTensor,
                                            "self_elo" to selfTensor,
                                            "opponent_elo" to opponentTensor,
                                        )
                                    ).use { outputs ->
                                        @Suppress("UNCHECKED_CAST")
                                        val logits = outputs.get("move_logits").get().value as Array<FloatArray>
                                        val payload = logits[0].map { it.toDouble() }
                                        runOnUiThread { result.success(payload) }
                                    }
                                }
                            }
                        }
                    } catch (error: Throwable) {
                        runOnUiThread {
                            result.error("inference_failed", error.message, error.stackTraceToString())
                        }
                    }
                }
            }
    }
}

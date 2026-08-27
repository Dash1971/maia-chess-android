package com.dash1971.maia_chess

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import java.io.FileOutputStream
import java.nio.FloatBuffer
import java.nio.LongBuffer
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class MaiaInferenceTest {
    @Test
    fun packagedModelReturnsPolicyVector() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val model = File(context.cacheDir, "instrumentation-maia3-5m.onnx")
        context.assets.open("flutter_assets/assets/models/maia3-5m.onnx").use { input ->
            FileOutputStream(model).use { output -> input.copyTo(output) }
        }
        assertTrue(model.length() > 20_000_000)

        val environment = OrtEnvironment.getEnvironment()
        environment.createSession(model.absolutePath).use { session ->
            OnnxTensor.createTensor(
                environment,
                FloatBuffer.wrap(FloatArray(64 * 97)),
                longArrayOf(1, 64, 97),
            ).use { tokens ->
                OnnxTensor.createTensor(
                    environment,
                    LongBuffer.wrap(longArrayOf(1500)),
                    longArrayOf(1),
                ).use { elo ->
                    session.run(
                        mapOf("tokens" to tokens, "self_elo" to elo, "opponent_elo" to elo)
                    ).use { output ->
                        @Suppress("UNCHECKED_CAST")
                        val logits = output.get("move_logits").get().value as Array<FloatArray>
                        assertEquals(1, logits.size)
                        assertEquals(4352, logits[0].size)
                        assertTrue(logits[0].all { it.isFinite() })
                    }
                }
            }
        }
    }
}

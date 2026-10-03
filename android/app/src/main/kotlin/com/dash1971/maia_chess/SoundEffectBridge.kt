package com.dash1971.maia_chess

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool
import io.flutter.FlutterInjector
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec

/** App-owned SoundPool bridge with no plugin-specific Gradle or Kotlin toolchain. */
class SoundEffectBridge(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, SoundPool.OnLoadCompleteListener {
    companion object {
        private const val CHANNEL = "maia_chess/sound_effect"
    }

    private val lock = Any()
    private val channel = MethodChannel(
        messenger,
        CHANNEL,
        StandardMethodCodec.INSTANCE,
        messenger.makeBackgroundTaskQueue(),
    )
    private var soundPool: SoundPool? = null
    private val samplesById = HashMap<String, Int>()
    private val idsBySample = HashMap<Int, String>()

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> initialize(call.argument<Int>("maxStreams"), result)
            "load" -> load(call.argument<String>("soundId"), call.argument<String>("path"), result)
            "play" -> play(call.argument<String>("soundId"), call.argument<Double>("volume"), result)
            "release" -> {
                release()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun initialize(maxStreams: Int?, result: MethodChannel.Result) {
        if (maxStreams == null || maxStreams !in 1..32) {
            result.error("bad_arguments", "maxStreams must be between 1 and 32", null)
            return
        }
        synchronized(lock) {
            soundPool?.release()
            samplesById.clear()
            idsBySample.clear()
            soundPool = SoundPool.Builder()
                .setMaxStreams(maxStreams)
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_GAME)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                .build()
                .also { it.setOnLoadCompleteListener(this) }
        }
        result.success(null)
    }

    private fun load(soundId: String?, path: String?, result: MethodChannel.Result) {
        if (soundId.isNullOrBlank() || path.isNullOrBlank()) {
            result.error("bad_arguments", "soundId and path are required", null)
            return
        }
        try {
            synchronized(lock) {
                val pool = soundPool
                    ?: throw IllegalStateException("Sound player is not initialized")
                val assetPath = FlutterInjector.instance()
                    .flutterLoader()
                    .getLookupKeyForAsset(path)
                val sample = context.assets.openFd(assetPath).use { descriptor ->
                    pool.load(descriptor, 1)
                }
                if (sample == 0) throw IllegalStateException("SoundPool rejected $soundId")
                // A short clip can finish decoding before load returns. Keep
                // registration under the same lock so its callback cannot
                // observe an unregistered sample and silently discard it.
                samplesById[soundId] = sample
                idsBySample[sample] = soundId
            }
            result.success(null)
        } catch (error: Exception) {
            result.error("sound_load_failed", error.message, null)
        }
    }

    private fun play(soundId: String?, volume: Double?, result: MethodChannel.Result) {
        if (soundId.isNullOrBlank()) {
            result.error("bad_arguments", "soundId is required", null)
            return
        }
        val played = synchronized(lock) {
            val pool = soundPool ?: return@synchronized false
            val sample = samplesById[soundId] ?: return@synchronized false
            val level = (volume ?: 1.0).coerceIn(0.0, 1.0).toFloat()
            pool.play(sample, level, level, 1, 0, 1f) != 0
        }
        if (played) result.success(null)
        else result.error("sound_unavailable", "Sound is not ready: $soundId", null)
    }

    override fun onLoadComplete(pool: SoundPool, sampleId: Int, status: Int) {
        val soundId = synchronized(lock) {
            if (pool !== soundPool) return
            idsBySample.remove(sampleId)
        } ?: return
        if (status == 0) {
            channel.invokeMethod("onLoadComplete", mapOf("soundId" to soundId))
        } else {
            synchronized(lock) { samplesById.remove(soundId) }
            channel.invokeMethod(
                "onLoadError",
                mapOf("soundId" to soundId, "status" to status),
            )
        }
    }

    fun pause() = synchronized(lock) { soundPool?.autoPause() }

    fun resume() = synchronized(lock) { soundPool?.autoResume() }

    fun release() {
        synchronized(lock) {
            soundPool?.setOnLoadCompleteListener(null)
            soundPool?.release()
            soundPool = null
            samplesById.clear()
            idsBySample.clear()
        }
    }

    fun close() {
        channel.setMethodCallHandler(null)
        release()
    }
}

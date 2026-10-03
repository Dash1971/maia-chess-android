import android.content.Context
import android.media.SoundPool
import com.dash1971.maia_chess.SoundEffectBridge
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Compile and exercise the production bridge; no copied implementation. */
fun main() {
    val bridge = SoundEffectBridge(Context(), BinaryMessenger())
    val result = object : MethodChannel.Result {
        override fun success(value: Any?) {}
        override fun error(code: String, message: String?, details: Any?) {
            error("$code $message")
        }
        override fun notImplemented() { error("Unexpected method") }
    }
    bridge.onMethodCall(MethodCall("initialize", mapOf("maxStreams" to 2)), result)
    val count = 10_000
    repeat(count) { index ->
        bridge.onMethodCall(
            MethodCall("load", mapOf("soundId" to "sound$index", "path" to "asset.mp3")),
            result,
        )
        val callback = checkNotNull(SoundPool.callbackThread)
        callback.join(2_000)
        check(!callback.isAlive) { "Sound callback did not finish" }
    }
    val received = MethodChannel.callbacks.get()
    println("SoundPool callbacks delivered=$count; Dart callbacks forwarded=$received; lost=${count - received}")
    check(received == count) { "Native completion was lost between lock sections" }
    bridge.close()
}

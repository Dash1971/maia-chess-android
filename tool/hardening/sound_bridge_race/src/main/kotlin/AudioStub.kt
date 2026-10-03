@file:Suppress("UNUSED_PARAMETER")
package android.media

class AudioAttributes {
    companion object {
        const val USAGE_GAME = 1
        const val CONTENT_TYPE_SONIFICATION = 1
    }
    class Builder {
        fun setUsage(value: Int) = this
        fun setContentType(value: Int) = this
        fun build() = AudioAttributes()
    }
}

/** Model the callback threading contract, not Android decoding or playback. */
class SoundPool {
    companion object { var callbackThread: Thread? = null }
    fun interface OnLoadCompleteListener {
        fun onLoadComplete(pool: SoundPool, sampleId: Int, status: Int)
    }
    private var listener: OnLoadCompleteListener? = null
    private var nextId = 0

    fun setOnLoadCompleteListener(value: OnLoadCompleteListener?) { listener = value }

    fun load(descriptor: android.content.Descriptor, priority: Int): Int {
        val sample = ++nextId
        val callback = Thread { checkNotNull(listener).onLoadComplete(this, sample, 0) }
        callback.isDaemon = true
        callbackThread = callback
        callback.start()
        // A short clip can already be decoded while load holds the bridge lock.
        // Arrange for its completion to contend for that same lock.
        val deadline = System.nanoTime() + 2_000_000_000L
        while (callback.state != Thread.State.BLOCKED && callback.isAlive) {
            check(System.nanoTime() < deadline) { "Callback did not reach bridge lock" }
            Thread.yield()
        }
        return sample
    }

    fun play(sample: Int, left: Float, right: Float, priority: Int, loop: Int, rate: Float) = 1
    fun release() {}
    fun autoPause() {}
    fun autoResume() {}

    class Builder {
        fun setMaxStreams(value: Int) = this
        fun setAudioAttributes(value: AudioAttributes) = this
        fun build() = SoundPool()
    }
}

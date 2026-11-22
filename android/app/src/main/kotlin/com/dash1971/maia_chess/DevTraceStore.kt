package com.dash1971.maia_chess

import java.io.File

/** Worker-thread-only rolling local trace. No filesystem access outside Dev. */
class DevTraceStore(private val directory: File, private val flavor: String,
                    private val limit: Int = 256 * 1024,
                    private val now: () -> Long = System::currentTimeMillis) {
    companion object { const val MAX_AGE_MS = 7 * 24 * 60 * 60 * 1000L }
    private val current get() = File(directory, "current.jsonl")
    private val previous get() = File(directory, "previous.jsonl")
    var failed = false
        private set

    private fun prune() {
        for (file in listOf(previous, current)) {
            if (file.exists() && (file.length() > limit || now() - file.lastModified() > MAX_AGE_MS)) {
                check(file.delete())
            }
        }
    }

    fun append(line: String) {
        if (flavor != "dev") return
        try {
            val bytes = (line + "\n").toByteArray(Charsets.UTF_8)
            if (bytes.size > minOf(limit, 24 * 1024)) return
            directory.mkdirs()
            prune()
            if (current.length() + bytes.size > limit) {
                if (previous.exists()) check(previous.delete())
                check(current.renameTo(previous))
            }
            val oldest = if (current.exists()) current.lastModified() else now()
            current.appendBytes(bytes)
            check(current.setLastModified(oldest)) // Expire the whole segment by its oldest event.
        } catch (_: Exception) { failed = true }
    }

    fun snapshot(): String {
        if (flavor != "dev") return ""
        return try {
            prune()
            listOf(previous, current).filter { it.isFile }.joinToString("") { it.readText(Charsets.UTF_8) }
        } catch (_: Exception) { failed = true; "" }
    }
}

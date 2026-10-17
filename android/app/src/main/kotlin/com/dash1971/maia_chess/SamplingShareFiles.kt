package com.dash1971.maia_chess

import java.io.File
import java.io.IOException

/** Bounded temporary sharing; never evict a recent file a recipient may still be reading. */
internal object SamplingShareFiles {
    const val MAX_FILE_BYTES = 70L * 1024 * 1024
    const val MAX_TOTAL_BYTES = 140L * 1024 * 1024
    const val MAX_FILES = 32
    const val RETAIN_MILLIS = 24L * 60 * 60 * 1000

    fun pruneExpired(folder: File, now: Long) {
        folder.listFiles()?.filter { it.isFile && now - it.lastModified() > RETAIN_MILLIS }
            ?.forEach { it.delete() }
    }

    fun retain(source: File, folder: File, suffix: String, now: Long): File {
        require(suffix == ".html" || suffix == ".jsonl")
        if (!source.isFile || source.length() > MAX_FILE_BYTES) throw IOException("Invalid export")
        folder.mkdirs()
        pruneExpired(folder, now)
        val files = folder.listFiles()?.filter { it.isFile } ?: emptyList()
        // Reuse identical exports without consuming more cache or invalidating existing URIs.
        val same = files.firstOrNull { it.extension == suffix.drop(1) && it.length() == source.length() && equalBytes(it, source) }
        if (same != null) {
            same.setLastModified(now)
            return same
        }
        if (files.size >= MAX_FILES || files.sumOf { it.length() } + source.length() > MAX_TOTAL_BYTES) {
            throw IOException("Recent share cache full; save to file instead")
        }
        val target = File.createTempFile("mobile-maia-sampling-", suffix, folder)
        try {
            source.inputStream().use { input -> target.outputStream().use { input.copyTo(it) } }
            target.setLastModified(now)
            return target
        } catch (error: Exception) { target.delete(); throw error }
    }

    private fun equalBytes(a: File, b: File): Boolean = a.inputStream().buffered().use { x ->
        b.inputStream().buffered().use inner@ { y ->
            val first = ByteArray(8192)
            val second = ByteArray(8192)
            while (true) {
                val n = x.read(first)
                val m = y.read(second)
                if (n != m) return@inner false
                if (n == -1) return@inner true
                for (i in 0 until n) if (first[i] != second[i]) return@inner false
            }
            @Suppress("UNREACHABLE_CODE") false
        }
    }
}

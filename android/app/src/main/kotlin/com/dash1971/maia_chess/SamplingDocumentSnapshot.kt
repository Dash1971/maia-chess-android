package com.dash1971.maia_chess

import java.io.File
import java.util.UUID

/** The private export snapshot outlives a recreated Activity while its picker is open. */
internal class SamplingDocumentSnapshot(cache: File, restoredName: String? = null) {
    private val restored = restoredName?.takeIf {
        Regex("sampling-export-[a-f0-9-]{36}\\.tmp").matches(it)
    }?.let { File(cache, it) }?.takeIf {
        it.isFile && it.length() in 1..SamplingShareFiles.MAX_FILE_BYTES
    }
    val file = restored ?: File(cache, "sampling-export-${UUID.randomUUID()}.tmp")
    var awaitingResult = restored != null
        private set
    private var savedForRecreation = false

    fun awaitResult() { awaitingResult = true }

    fun saveState(): String? {
        if (!awaitingResult) return null
        savedForRecreation = true
        return file.name
    }

    fun finish() {
        awaitingResult = false
        savedForRecreation = false
        file.delete()
    }

    fun close(finishing: Boolean) {
        if (finishing || !awaitingResult || !savedForRecreation) file.delete()
    }
}

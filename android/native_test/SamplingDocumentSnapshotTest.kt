package com.dash1971.maia_chess

import java.io.File
import java.nio.file.Files

fun samplingDocumentSnapshotChecks() {
    val root = Files.createTempDirectory("maia-document-test").toFile()
    try {
        val original = SamplingDocumentSnapshot(root)
        original.file.writeText("complete report")
        original.awaitResult()
        val saved = original.saveState()!!
        original.close(finishing = false)
        val recreated = SamplingDocumentSnapshot(root, saved)
        check(recreated.awaitingResult && recreated.file.readText() == "complete report")
        recreated.finish()
        check(!recreated.awaitingResult && !original.file.exists())
        // Process death skips close entirely: the saved snapshot is still usable.
        val killed = SamplingDocumentSnapshot(root)
        killed.file.writeText("process restart report")
        killed.awaitResult()
        val afterKill = SamplingDocumentSnapshot(root, killed.saveState())
        check(afterKill.awaitingResult && afterKill.file.readText() == "process restart report")
        afterKill.finish() // Cancel and successful delivery both clear the snapshot.
        check(!killed.file.exists())
        val finishing = SamplingDocumentSnapshot(root)
        finishing.file.writeText("cancelled")
        finishing.awaitResult(); finishing.saveState(); finishing.close(finishing = true)
        check(!finishing.file.exists())
        val ordinary = SamplingDocumentSnapshot(root)
        ordinary.file.writeText("not in a picker")
        check(ordinary.saveState() == null)
        ordinary.close(finishing = false)
        check(!ordinary.file.exists())
        for (name in listOf("../secret", "/tmp/secret", "sampling-export-missing.tmp", saved)) {
            val invalid = SamplingDocumentSnapshot(root, name)
            check(!invalid.awaitingResult)
            check(invalid.file.parentFile == root)
        }
        val empty = SamplingDocumentSnapshot(root)
        empty.file.createNewFile()
        check(!SamplingDocumentSnapshot(root, empty.file.name).awaitingResult)
        java.io.RandomAccessFile(empty.file, "rw").use { it.setLength(SamplingShareFiles.MAX_FILE_BYTES + 1) }
        check(!SamplingDocumentSnapshot(root, empty.file.name).awaitingResult)
    } finally { root.deleteRecursively() }
    println("Sampling document recreation, process-death, cancellation and path validation checks passed")
}

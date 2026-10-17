package com.dash1971.maia_chess

import java.io.File
import java.nio.file.Files

fun samplingShareFilesChecks() {
    samplingDocumentSnapshotChecks()
    val root = Files.createTempDirectory("maia-share-test").toFile()
    try {
        val folder = File(root, "shares")
        val source = File(root, "source").apply { writeText("first report") }
        val now = System.currentTimeMillis()
        val first = SamplingShareFiles.retain(source, folder, ".html", now)
        check(first.readText() == "first report")
        check(SamplingShareFiles.retain(source, folder, ".html", now + 1000) == first)
        check(first.lastModified() >= now)
        check(folder.listFiles()!!.size == 1)
        source.writeText("second report")
        val second = SamplingShareFiles.retain(source, folder, ".html", now + 1000)
        check(second != first && first.readText() == "first report")
        check(runCatching { SamplingShareFiles.retain(source, folder, ".apk", now) }.isFailure)
        first.setLastModified(now - SamplingShareFiles.RETAIN_MILLIS - 1)
        SamplingShareFiles.pruneExpired(folder, now)
        check(!first.exists() && second.exists())
        // No eviction of a recent recipient's file when the bounded cache fills.
        repeat(SamplingShareFiles.MAX_FILES - 1) { index ->
            source.writeText("different report $index")
            SamplingShareFiles.retain(source, folder, ".jsonl", now)
        }
        val before = folder.listFiles()!!.map { it.name }.toSet()
        source.writeText("too many")
        check(runCatching { SamplingShareFiles.retain(source, folder, ".html", now) }.isFailure)
        check(folder.listFiles()!!.map { it.name }.toSet() == before)
        // Byte cap without allocating a giant buffer (sparse files).
        folder.deleteRecursively(); folder.mkdirs()
        java.io.RandomAccessFile(source, "rw").use { it.setLength(SamplingShareFiles.MAX_FILE_BYTES + 1) }
        check(runCatching { SamplingShareFiles.retain(source, folder, ".html", now) }.isFailure)
        java.io.RandomAccessFile(source, "rw").use { it.setLength(10) }
        java.io.RandomAccessFile(File(folder, "recent.jsonl"), "rw").use { it.setLength(SamplingShareFiles.MAX_TOTAL_BYTES) }
        check(runCatching { SamplingShareFiles.retain(source, folder, ".html", now) }.isFailure)
        check(source.exists())
    } finally { root.deleteRecursively() }
    println("Sampling share retention checks passed")
}

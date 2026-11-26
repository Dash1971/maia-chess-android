package com.dash1971.maia_chess

import java.io.File
import java.nio.file.Files

fun testDevTraceStore() {
    val root = Files.createTempDirectory("maia-dev-trace-test").toFile()
    try {
        for (flavor in listOf("", "stable", "preview")) {
            val directory = File(root, "disabled-$flavor")
            val store = DevTraceStore(directory, flavor)
            store.append("secret")
            check(store.snapshot().isEmpty() && !directory.exists())
        }
        var now = System.currentTimeMillis()
        val directory = File(root, "dev")
        val store = DevTraceStore(directory, "dev", 100) { now }
        repeat(100) { store.append("$it " + "x".repeat(32)) }
        check(directory.listFiles()!!.sumOf { it.length() } <= 200)
        check(store.snapshot().contains("99 ") && !store.snapshot().contains("0 "))
        check(DevTraceStore(directory, "dev", 100) { now }.snapshot() == store.snapshot())
        now += DevTraceStore.MAX_AGE_MS + 1
        check(store.snapshot().isEmpty())
        store.append("x".repeat(101))
        check(store.snapshot().isEmpty())
        val blocked = File(root, "file").apply { writeText("keep") }
        val failure = DevTraceStore(blocked, "dev")
        failure.append("event")
        check(failure.failed && blocked.readText() == "keep")
        println("Dev trace: channel gates, rolling byte cap, restart persistence, age expiry and I/O failure isolation passed")
    } finally { root.deleteRecursively() }
}

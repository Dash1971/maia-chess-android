package com.dash1971.maia_chess

import android.app.Activity
import android.content.Intent
import android.os.SystemClock
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File
import java.util.UUID
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.RejectedExecutionException
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicLong

/** Automatic Dev-only recording. No telemetry, permissions, retries or board commands. */
class DevDiagnostics(private val activity: Activity) {
    init { check(BuildConfig.FLAVOR == "dev") }
    private val store = DevTraceStore(File(activity.noBackupFilesDir, "dev-diagnostics"), BuildConfig.FLAVOR)
    private val worker = ThreadPoolExecutor(1, 1, 0, TimeUnit.MILLISECONDS, ArrayBlockingQueue<Runnable>(256))
    private val dropped = AtomicLong()
    private val process = UUID.randomUUID().toString()
    private var sequence = 0L
    private var pending: MethodChannel.Result? = null
    private var exportText: String? = null
    @Volatile private var closed = false

    init {
        record("app.instance", mapOf("version" to BuildConfig.VERSION_NAME, "build" to BuildConfig.VERSION_CODE,
            "package" to activity.packageName, "model" to BuildConfig.MAIA_MODEL_FILE,
            "androidSdk" to android.os.Build.VERSION.SDK_INT))
    }

    private fun submit(block: () -> Unit): Boolean {
        if (closed) return false
        return try { worker.execute(block); true }
        catch (_: RejectedExecutionException) { dropped.incrementAndGet(); false }
    }

    fun record(event: String, values: Map<String, Any> = emptyMap()) {
        val utc = System.currentTimeMillis()
        val elapsed = SystemClock.elapsedRealtime()
        submit {
            try {
                store.append(JSONObject(values).put("event", event).put("utcMs", utc)
                    .put("elapsedMs", elapsed).put("process", process).put("seq", ++sequence).toString())
            } catch (_: Exception) { dropped.incrementAndGet() }
        }
    }

    fun board(event: String, kind: String, session: String, values: Map<String, Any> = emptyMap()) {
        if (kind == "squareOff") record("grand-kingdom.$event", values + mapOf("session" to session))
    }

    private fun report(maxTraceCharacters: Int = Int.MAX_VALUE): String {
        val trace = store.snapshot()
        return "Dev local trace: rolling 2 x 256 KiB, 7 days; oldest events may be absent.\n" +
            "droppedTasks=${dropped.get()} storageFailed=${store.failed}\n" +
            "GATT write success is not motor completion. Firmware is not queried.\n" +
            (if (trace.length > maxTraceCharacters) "Recent trace tail (first line may be partial):\n" else "") + trace.takeLast(maxTraceCharacters)
    }

    fun handle(call: MethodCall, reply: MethodChannel.Result) {
        when (call.method) {
            "devTraceContext" -> {
                val event = call.argument<String>("event") ?: ""
                if (!event.matches(Regex("[a-zA-Z0-9_.-]{1,64}"))) {
                    reply.error("bad_arguments", "Invalid event", null); return
                }
                val values = mutableMapOf<String, Any>()
                for ((key, limit) in mapOf("fen" to 160, "beforeFen" to 160, "uci" to 5, "pgn" to 16000,
                    "pending" to 5, "state" to 32)) {
                    call.argument<String>(key)?.let { values[key] = it.take(limit) }
                }
                record(event, values)
                reply.success(null)
            }
            "devTraceReport" -> {
                if (!submit {
                    val text = report(64 * 1024)
                    activity.runOnUiThread { if (!closed) reply.success(text) }
                }) reply.error("diagnostics_busy", "Diagnostics unavailable", null)
            }
            "saveDevDiagnostics" -> {
                if (pending != null) { reply.error("diagnostics_busy", "Export already open", null); return }
                val baseReport = call.argument<String>("report")
                if (baseReport == null || baseReport.length > 200000) { reply.error("bad_arguments", "Invalid report", null); return }
                pending = reply
                if (!submit {
                    val snapshot = baseReport + "\n\n" + report()
                    activity.runOnUiThread {
                        if (!closed) {
                            exportText = snapshot
                            try {
                                activity.startActivityForResult(Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                                    addCategory(Intent.CATEGORY_OPENABLE)
                                    type = "text/plain"
                                    putExtra(Intent.EXTRA_TITLE, "mobile-maia-dev-diagnostics.txt")
                                }, 2401)
                            } catch (_: Exception) { finish(false) }
                        }
                    }
                }) finish(false)
            }
            else -> reply.notImplemented()
        }
    }

    fun onResult(request: Int, code: Int, intent: Intent?): Boolean {
        if (request != 2401) return false
        if (pending == null) return true
        val text = exportText ?: return true
        exportText = null // Consume once; ignore duplicate Android callbacks.
        val uri = intent?.data
        if (code != Activity.RESULT_OK || uri == null) { finish(null); return true }
        if (!submit {
            val success = try {
                check(uri.scheme == "content")
                activity.contentResolver.openOutputStream(uri, "wt")?.use {
                    it.write(text.toByteArray(Charsets.UTF_8)); it.flush()
                } ?: error("No output")
                true
            } catch (_: Exception) { false }
            activity.runOnUiThread { if (!closed) finish(success) }
        }) finish(false)
        return true
    }

    private fun finish(success: Boolean?) {
        val reply = pending
        pending = null; exportText = null
        if (success == false) reply?.error("diagnostics_export_failed", "Could not export diagnostics", null)
        else reply?.success(success)
    }

    fun close() {
        closed = true
        pending?.error("diagnostics_closed", "Activity closed during export", null)
        pending = null; exportText = null
        worker.shutdown()
    }
}

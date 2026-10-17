package com.dash1971.maia_chess

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.util.concurrent.Executors

/** Explicit, streaming export. Sources are fixed private paths, never caller-supplied. */
class SamplingDocuments(private val activity: Activity, restoredName: String? = null) {
    private val io = Executors.newSingleThreadExecutor()
    private var pending: MethodChannel.Result? = null
    private val snapshotState = SamplingDocumentSnapshot(activity.cacheDir, restoredName)
    private val snapshot get() = snapshotState.file
    private val shares = File(activity.cacheDir, "sampling-share")
    @Volatile private var closed = false

    init {
        io.execute {
            activity.cacheDir.listFiles()?.filter {
                it != snapshot && it.isFile && it.name.startsWith("sampling-export-") && it.name.endsWith(".tmp") &&
                    System.currentTimeMillis() - it.lastModified() > SamplingShareFiles.RETAIN_MILLIS
            }?.forEach { it.delete() }
            SamplingShareFiles.pruneExpired(shares, System.currentTimeMillis())
        }
    }

    fun save(reply: MethodChannel.Result, readable: Boolean = false, share: Boolean = false,
             chooserTitle: String = "") {
        if (pending != null || snapshotState.awaitingResult || closed) {
            reply.error("sampling_busy", "Sampling export unavailable", null)
            return
        }
        pending = reply
        val suffix = if (readable) ".html" else ".jsonl"
        val mime = if (readable) "text/html" else "application/x-ndjson"
        io.execute {
            try {
                val source = File(activity.filesDir,
                    if (readable) "sampling-data/report.html" else "sampling-data/export.jsonl")
                if (!source.isFile || source.length() > SamplingShareFiles.MAX_FILE_BYTES) {
                    throw IOException("Invalid export")
                }
                source.inputStream().use { input -> snapshot.outputStream().use { input.copyTo(it) } }
                if (share) {
                    val shared = SamplingShareFiles.retain(snapshot, shares, suffix, System.currentTimeMillis())
                    activity.runOnUiThread {
                        if (closed) return@runOnUiThread
                        try {
                            val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.files", shared)
                            val send = Intent(Intent.ACTION_SEND).apply {
                                type = mime
                                putExtra(Intent.EXTRA_STREAM, uri)
                                clipData = ClipData.newRawUri("Mobile Maia", uri)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            activity.startActivity(Intent.createChooser(send, chooserTitle).apply {
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            })
                            // Do not delete the shared file here: recipients read asynchronously.
                            finish(true)
                        } catch (_: Exception) { finish(false) }
                    }
                } else {
                    activity.runOnUiThread {
                        if (closed) return@runOnUiThread
                        try {
                            snapshotState.awaitResult()
                            activity.startActivityForResult(Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE)
                                type = mime
                                putExtra(Intent.EXTRA_TITLE, "mobile-maia-sampling$suffix")
                            }, 2201)
                        } catch (_: Exception) { finish(false) }
                    }
                }
            } catch (_: Exception) { activity.runOnUiThread { finish(false) } }
        }
    }

    fun onResult(request: Int, code: Int, intent: Intent?): Boolean {
        if (request != 2201) return false
        if (!snapshotState.awaitingResult) return true
        val uri = intent?.data
        if (code != Activity.RESULT_OK || uri == null) { finish(null); return true }
        io.execute {
            val success = try {
                if (uri.scheme != "content") throw IOException("Expected document URI")
                activity.contentResolver.openOutputStream(uri, "wt")?.use { output ->
                    snapshot.inputStream().use { it.copyTo(output) }
                    output.flush()
                } ?: throw IOException("Could not open document")
                true
            } catch (_: Exception) { false }
            activity.runOnUiThread { finish(success) }
        }
        return true
    }

    private fun finish(success: Boolean?) {
        val reply = pending
        pending = null
        snapshotState.finish()
        if (success == false) reply?.error("sampling_export_failed", "Could not export sampling data", null)
        else reply?.success(success)
    }

    fun saveState(): String? = snapshotState.saveState()

    fun close() {
        closed = true
        pending?.error("sampling_closed", "Activity closed during export", null)
        pending = null
        io.execute { snapshotState.close(activity.isFinishing) }
        io.shutdown()
    }
}

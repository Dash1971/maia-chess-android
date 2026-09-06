package com.dash1971.maia_chess

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.IOException
import java.util.concurrent.Executors

/** Uses Android's document picker and temporary URI grants; no storage permission. */
class PgnDocuments(private val activity: Activity, private val received: () -> Unit) {
    companion object {
        private const val OPEN = 2101
        private const val SAVE = 2102
        private const val MAX_BYTES = 2 * 1024 * 1024
        private const val MIME = "application/x-chess-pgn"
    }
    private val io = Executors.newSingleThreadExecutor()
    private var result: MethodChannel.Result? = null
    private var exportText: String? = null
    private data class PendingPgn(val text: String? = null, val error: String? = null)
    private val pending = ArrayDeque<PendingPgn>()

    fun takePending(reply: MethodChannel.Result) {
        val item = pending.removeFirstOrNull()
        if (item?.error != null) reply.error("pgn_read_failed", item.error, null)
        else reply.success(item?.text)
    }

    fun open(reply: MethodChannel.Result) = pick(OPEN, null, reply)
    fun save(text: String, reply: MethodChannel.Result) = pick(SAVE, text, reply)

    private fun pick(request: Int, text: String?, reply: MethodChannel.Result) {
        if (result != null) { reply.error("document_busy", "A document picker is already open", null); return }
        if (text != null && text.toByteArray(Charsets.UTF_8).size > MAX_BYTES) {
            reply.error("pgn_too_large", "PGN exceeds 2 MB", null); return
        }
        val intent = Intent(if (request == OPEN) Intent.ACTION_OPEN_DOCUMENT else Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = if (request == OPEN) "*/*" else MIME
            if (request == OPEN) putExtra(Intent.EXTRA_MIME_TYPES, arrayOf(MIME, "application/vnd.chess-pgn", "text/plain", "application/octet-stream"))
            else putExtra(Intent.EXTRA_TITLE, "mobile-maia.pgn")
        }
        result = reply
        exportText = text
        try { activity.startActivityForResult(intent, request) }
        catch (error: Exception) {
            result = null; exportText = null
            reply.error("document_unavailable", error.message, null)
        }
    }

    fun onResult(request: Int, code: Int, intent: Intent?): Boolean {
        if (request != OPEN && request != SAVE) return false
        val reply = result ?: return true
        val text = exportText
        result = null; exportText = null
        val uri = intent?.data
        if (code != Activity.RESULT_OK || uri == null) { reply.success(null); return true }
        io.execute {
            try {
                val value: Any? = if (request == OPEN) read(uri) else {
                    activity.contentResolver.openOutputStream(uri, "wt")?.use { stream ->
                        stream.write((text ?: "").toByteArray(Charsets.UTF_8))
                        stream.flush()
                    } ?: throw IOException("Could not open the selected file")
                    true
                }
                activity.runOnUiThread { reply.success(value) }
            } catch (error: Exception) {
                activity.runOnUiThread { reply.error("document_failed", error.message, null) }
            }
        }
        return true
    }

    private fun read(uri: Uri): String {
        if (uri.scheme != "content") throw IOException("Expected a document URI")
        return activity.contentResolver.openInputStream(uri)?.use { stream ->
            val output = ByteArrayOutputStream()
            val buffer = ByteArray(8192)
            while (true) {
                val count = stream.read(buffer)
                if (count < 0) break
                if (output.size() + count > MAX_BYTES) throw IOException("PGN exceeds 2 MB")
                output.write(buffer, 0, count)
            }
            output.toString("UTF-8").removePrefix("\uFEFF")
        } ?: throw IOException("Could not read the selected file")
    }

    @Suppress("DEPRECATION")
    fun consumeIntent(intent: Intent?) {
        if (intent?.action !in setOf(Intent.ACTION_VIEW, Intent.ACTION_SEND)) return
        val uri = if (intent?.action == Intent.ACTION_VIEW) intent.data
            else intent?.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                ?: intent?.clipData?.takeIf { it.itemCount > 0 }?.getItemAt(0)?.uri
        val text = if (uri == null) intent?.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString() else null
        if (uri == null && text == null) return
        // Clear the consumed payload so reopening the activity does not import twice.
        intent?.action = Intent.ACTION_MAIN
        io.execute {
            try {
                val pgn = (uri?.let(::read) ?: text!!).removePrefix("\uFEFF")
                if (pgn.toByteArray(Charsets.UTF_8).size > MAX_BYTES) throw IOException("PGN exceeds 2 MB")
                activity.runOnUiThread { pending.addLast(PendingPgn(text = pgn)); received() }
            } catch (error: Exception) {
                activity.runOnUiThread {
                    pending.addLast(PendingPgn(error = error.message ?: error.javaClass.simpleName))
                    received()
                }
            }
        }
    }

    fun share(text: String, reply: MethodChannel.Result) {
        if (text.toByteArray(Charsets.UTF_8).size > MAX_BYTES) {
            reply.error("pgn_too_large", "PGN exceeds 2 MB", null)
            return
        }
        io.execute {
            try {
                val folder = File(activity.cacheDir, "pgn-share").apply { mkdirs() }
                // Keep recent shares valid while another app reads them.
                folder.listFiles()?.filter { System.currentTimeMillis() - it.lastModified() > 24 * 60 * 60 * 1000L }?.forEach { it.delete() }
                val file = File.createTempFile("mobile-maia-", ".pgn", folder)
                file.writeText(text, Charsets.UTF_8)
                val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.files", file)
                val intent = Intent(Intent.ACTION_SEND).apply {
                    type = MIME
                    putExtra(Intent.EXTRA_STREAM, uri)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    clipData = android.content.ClipData.newRawUri("PGN", uri)
                }
                activity.runOnUiThread {
                    try { activity.startActivity(Intent.createChooser(intent, "Share PGN")); reply.success(null) }
                    catch (error: Exception) { reply.error("share_failed", error.message, null) }
                }
            } catch (error: Exception) {
                activity.runOnUiThread { reply.error("share_failed", error.message, null) }
            }
        }
    }

    fun close() { io.shutdown() }
}

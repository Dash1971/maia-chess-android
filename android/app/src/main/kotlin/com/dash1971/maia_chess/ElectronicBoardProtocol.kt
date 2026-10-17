package com.dash1971.maia_chess

import java.util.UUID

/** All channels permit Chessnut; only Dev may discover or command prototype boards. */
internal object BoardChannelPolicy {
    fun supports(flavor: String, kind: String): Boolean =
        kind == "chessnut" || (flavor == "dev" && kind in setOf("pegasus", "squareOff"))
    fun discover(flavor: String, name: String): String? = when {
        name.contains("Chessnut", true) || name.contains("Smart Chess", true) -> "chessnut"
        supports(flavor, "pegasus") && name.contains("Pegasus", true) -> "pegasus"
        supports(flavor, "squareOff") && name.equals("Square Off", true) -> "squareOff"
        else -> null
    }
}

/** Old Chessnut saves lack an identity; never silently reuse another board. */
internal object BoardReconnectPolicy {
    fun needsLegacyDiscovery(mode: String, requestedId: String?): Boolean =
        mode == "reconnect" && requestedId == null
    fun needsFreshConnection(mode: String, requestedId: String?, currentId: String?): Boolean =
        mode == "reconnect" && (requestedId == null || requestedId != currentId)
}

/** Pure transport policy: no platform dependencies and no public device addresses. */
internal class BoardDiscoveryWindow<T>(private val capacity: Int = 32) {
    private val tokens = linkedMapOf<String, T>()
    private val identities = mutableSetOf<String>()
    fun clear() { tokens.clear(); identities.clear() }
    fun add(identity: String, value: T) {
        if (tokens.size < capacity && identities.add(identity)) tokens[UUID.randomUUID().toString()] = value
    }
    fun snapshot(): Map<String, T> = tokens.toMap()
    fun select(token: String?): T? {
        val selected = tokens[token] ?: return null
        clear()
        return selected
    }
}

internal object ElectronicBoardProtocol {
    /** NUS frame remains within the default ATT payload. Show remaining guidance after changes. */
    fun pegasusLeds(squares: List<Int>): ByteArray {
        require(squares.size <= 64 && squares.all { it in 0..63 })
        val selected = squares.distinct().take(13)
        return if (selected.isEmpty()) byteArrayOf(0x60, 0x02, 0, 0) else
            (listOf(0x60, 5 + selected.size, 0x05, 0x02, 0, 0x05) + selected + 0)
                .map { it.toByte() }.toByteArray()
    }
    fun squareOffMove(uci: String, providedSession: String?, currentSession: String): ByteArray {
        require(providedSession == currentSession)
        require(Regex("[a-h][1-8][a-h][1-8]").matches(uci))
        require(uci.substring(0, 2) != uci.substring(2, 4))
        return "x${uci}z".toByteArray(Charsets.US_ASCII)
    }
}

/** Known Chessnut frames only. A timeout prevents abandoned fragments merging with later input. */
internal class ChessnutNotificationFrames(private val confirmation: Boolean) {
    private var pending = byteArrayOf()
    private var lastFragmentAt = 0L
    fun reset() { pending = byteArrayOf(); lastFragmentAt = 0L }
    fun feed(chunk: ByteArray, nowMs: Long): List<ByteArray> {
        if (chunk.isEmpty()) return emptyList()
        if (chunk.size > 256) { reset(); return emptyList() }
        if (pending.isNotEmpty() && nowMs - lastFragmentAt > 1500L) reset()
        // Historical payload-only reports must retain exactly their existing bytes.
        if (!confirmation && pending.isEmpty() && chunk.size == 32 && !(chunk[0] == 1.toByte() && chunk[1] == 36.toByte())) return listOf(chunk.copyOf())
        if (pending.size + chunk.size > 256) { reset(); return emptyList() }
        pending += chunk
        lastFragmentAt = nowMs
        val frames = mutableListOf<ByteArray>()
        while (pending.isNotEmpty()) {
            val kind = pending[0].toInt() and 255
            val payloadLength = when {
                confirmation && kind == 0x0f -> 1
                confirmation && kind == 0x2a -> 2
                !confirmation && kind == 0x01 -> 36
                else -> { reset(); return frames }
            }
            if (pending.size < 2) break
            if ((pending[1].toInt() and 255) != payloadLength) { reset(); return frames }
            val total = payloadLength + 2
            if (pending.size < total) break
            frames.add(pending.copyOfRange(0, total))
            pending = pending.copyOfRange(total, pending.size)
        }
        return frames
    }
}

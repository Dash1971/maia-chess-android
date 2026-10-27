package com.dash1971.maia_chess

private fun bytes(vararg values: Int) = values.map { it.toByte() }.toByteArray()
private fun rejects(block: () -> Unit) { check(runCatching(block).isFailure) }

fun main() {
    sessionRecoveryPolicyTests()
    samplingShareFilesChecks()
    for (flavor in listOf("preview", "", "stable", "production")) {
        check(BoardChannelPolicy.supports(flavor, "chessnut"))
        check(!BoardChannelPolicy.supports(flavor, "pegasus"))
        check(!BoardChannelPolicy.supports(flavor, "squareOff"))
        check(BoardChannelPolicy.discover(flavor, "DGT Pegasus") == null)
        check(BoardChannelPolicy.discover(flavor, "Square Off") == null)
        check(BoardChannelPolicy.discover(flavor, "Chessnut Go") == "chessnut")
        check(BoardChannelPolicy.discover(flavor, "Smart Chess") == "chessnut")
    }
    check(BoardChannelPolicy.discover("dev", "DGT Pegasus") == "pegasus")
    check(BoardChannelPolicy.discover("dev", "Square Off") == "squareOff")
    check(!BoardChannelPolicy.supports("dev", "unknown"))

    // Legacy saves must scan even if another board is already ready or connecting.
    for (current in listOf(null, "old-chessnut", "prototype-board")) {
        check(BoardReconnectPolicy.needsFreshConnection("reconnect", null, current))
        check(BoardReconnectPolicy.needsLegacyDiscovery("reconnect", null))
    }
    check(!BoardReconnectPolicy.needsFreshConnection("reconnect", "saved", "saved"))
    check(BoardReconnectPolicy.needsFreshConnection("reconnect", "saved", "other"))
    check(BoardReconnectPolicy.needsFreshConnection("reconnect", "saved", null))
    check(!BoardReconnectPolicy.needsLegacyDiscovery("reconnect", "saved"))
    for (mode in listOf("remembered", "discover")) {
        check(!BoardReconnectPolicy.needsFreshConnection(mode, null, "ready"))
        check(!BoardReconnectPolicy.needsLegacyDiscovery(mode, null))
    }

    val discovery = BoardDiscoveryWindow<String>(2)
    discovery.add("private-address-1", "first")
    discovery.add("private-address-1", "duplicate")
    discovery.add("private-address-2", "second")
    discovery.add("private-address-3", "over-capacity")
    val candidates = discovery.snapshot()
    check(candidates.values.toList() == listOf("first", "second"))
    check(candidates.keys.none { it.contains("private-address") })
    val old = candidates.keys.first()
    check(discovery.select(old) == "first")
    check(discovery.select(candidates.keys.last()) == null)
    discovery.add("private-address-1", "fresh")
    check(discovery.select(old) == null)
    check(discovery.snapshot().size == 1)
    discovery.clear()
    check(discovery.snapshot().isEmpty())

    val allGuidance = ElectronicBoardProtocol.pegasusLeds((0..63).toList())
    check(allGuidance.size == 20)
    check(allGuidance[1].toInt() == 18)
    check(allGuidance.copyOfRange(6, 19).contentEquals((0..12).map { it.toByte() }.toByteArray()))
    check(allGuidance.last() == 0.toByte())
    check(ElectronicBoardProtocol.pegasusLeds(listOf(63, 63)).size == 8)
    check(ElectronicBoardProtocol.pegasusLeds(emptyList()).contentEquals(bytes(0x60, 2, 0, 0)))
    rejects { ElectronicBoardProtocol.pegasusLeds(listOf(-1)) }
    rejects { ElectronicBoardProtocol.pegasusLeds(listOf(64)) }
    check(String(ElectronicBoardProtocol.squareOffMove("e2e4", "live", "live")) == "xe2e4z")
    rejects { ElectronicBoardProtocol.squareOffMove("e2e4", "old", "live") }
    rejects { ElectronicBoardProtocol.squareOffMove("e2e4", null, "live") }
    rejects { ElectronicBoardProtocol.squareOffMove("e7e8q", "live", "live") }
    rejects { ElectronicBoardProtocol.squareOffMove("e2e2", "live", "live") }

    val report = bytes(1, 36) + ByteArray(36) { it.toByte() }
    for (split in 1 until report.size) {
        val parser = ChessnutNotificationFrames(false)
        check(parser.feed(report.copyOfRange(0, split), 0).isEmpty())
        check(parser.feed(report.copyOfRange(split, report.size), 1).single().contentEquals(report))
    }
    val parser = ChessnutNotificationFrames(false)
    val combined = parser.feed(report + report + report, 10)
    check(combined.size == 3 && combined.all { it.contentEquals(report) })
    check(parser.feed(report.copyOfRange(0, 20), 11).isEmpty())
    parser.reset()
    check(parser.feed(report, 12).single().contentEquals(report))
    check(parser.feed(report.copyOfRange(0, 20), 20).isEmpty())
    check(parser.feed(report, 1600).single().contentEquals(report))
    check(parser.feed(bytes(1, 35) + ByteArray(35), 1700).isEmpty())
    check(parser.feed(ByteArray(257), 1800).isEmpty())
    check(parser.feed(report, 1900).single().contentEquals(report))
    val payload = ByteArray(32) { 1 }
    check(parser.feed(payload, 2000).single().contentEquals(payload))

    val confirmation = ChessnutNotificationFrames(true)
    check(confirmation.feed(bytes(0x0f), 1).isEmpty())
    check(confirmation.feed(bytes(1), 2).isEmpty())
    check(confirmation.feed(bytes(2), 3).single().contentEquals(bytes(0x0f, 1, 2)))
    val confirmMany = confirmation.feed(bytes(0x2a, 2, 99, 0, 0x0f, 1, 2), 4)
    check(confirmMany.size == 2)
    check(confirmation.feed(bytes(0x0f, 64), 5).isEmpty())
    check(confirmation.feed(bytes(0x0f, 1, 2), 6).size == 1)
    println("ElectronicBoardProtocol host checks passed: discovery, session binding, ATT LED bounds, every Chessnut split, coalescing, expiration, reset and corruption recovery.")
}

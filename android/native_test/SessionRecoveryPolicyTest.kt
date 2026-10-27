package com.dash1971.maia_chess

fun sessionRecoveryPolicyTests() {
    // Signal, Java/native crash, ANR and initialization failure.
    for (reason in listOf(2, 4, 5, 6, 7)) {
        check(SessionRecoveryPolicy.failed(reason, 0))
    }
    // Stockfish's fatal FEN rejection calls exit(1), not necessarily SIGABRT.
    check(SessionRecoveryPolicy.failed(1, 1))
    check(!SessionRecoveryPolicy.failed(1, 0))
    check(!SessionRecoveryPolicy.failed(null, null))
    // Low memory, user stop, app update, permission change: ordinary restore.
    for (reason in listOf(0, 3, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18)) {
        check(!SessionRecoveryPolicy.failed(reason, 0))
    }
}

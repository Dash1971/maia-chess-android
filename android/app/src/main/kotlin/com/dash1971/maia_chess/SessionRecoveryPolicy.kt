package com.dash1971.maia_chess

/** Android ApplicationExitInfo reasons; no permissions or telemetry required. */
internal object SessionRecoveryPolicy {
    fun failed(reason: Int?, status: Int?): Boolean =
        reason in setOf(2, 4, 5, 6, 7) ||
            (reason == 1 && status != null && status != 0)
}

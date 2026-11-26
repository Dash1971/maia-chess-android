# Electronic-board support decision — 22 November 2026

> **Status update, 26 November 2026:** this policy ships in Stable 2.6.0.
> [Qualification and publication](https://github.com/Dash1971/maia-chess-android/blob/main/docs/release-notes/v2.6.0-verification.md)
> record the separate release checks. The dated decision below is preserved.

## Decision

DGT Pegasus is not supported in Mobile Maia. Remove its prototype implementation
from the Stable 2.6 promotion and every Preview/Dev build flavor. Do not keep a
Dev-only switch, initialization path, occupancy decoder or LED-command adapter.

Chessnut Air, Go and Pro remain supported. Air and Go are fully tested; Pro is
not fully tested. Grand Kingdom is supported across Stable, Preview and Dev and
has passed user acceptance testing. Its standard-position/untimed and
assisted-promotion operating limits are recorded in its acceptance notes. The
README support table is the user-facing summary. Board owners and manufacturers are welcome to help expand coverage.

## Reason and source

The [initialization-permission inquiry](https://github.com/egdels/moveapiece/issues/2)
has not established that the permission given for MoveAPiece also covers Mobile
Maia, public source, F-Droid builds and unrestricted downstream redistribution.
Without initialization, the documented Pegasus behavior does not provide usable
board data. Mobile Maia will not ship a feature dependent on that unresolved
permission. The inquiry was closed as not planned after this decision.

This is an integration/scope decision, not a claim that MoveAPiece's GPL-licensed
protocol code is non-free or that Pegasus cannot work technically. The concern
is the separate initialization permission. No manufacturer key is bundled.

## Implementation and compatibility

Remove Pegasus discovery/selection, framing, occupancy inference, native
initialization/LED commands, board capabilities and the dedicated lock message.
Keep tests proving Pegasus advertisements and explicit retired/unknown native
kinds cannot connect or fall back to Chessnut in any flavor, including Dev.

An old Dev save tagged Pegasus can still recover its chess game on the phone,
with no board reconnection, motor command or inherited running board clock.
This read-only save migration is not a retained Pegasus adapter.

Dev uses the canonical Preview source. Its separate repository is a release
feed with no application source, so the Preview removal covers future Dev
builds too. Published APKs/tags and dated historical evidence remain unchanged.
Stable 2.6 and the next Preview candidate still require their normal release
qualification; this decision does not authorize builds or publication.

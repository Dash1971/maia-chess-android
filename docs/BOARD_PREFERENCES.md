# Board preferences

Preview #178 adds the approved inline Board card immediately after Appearance.
`boardPreferencesV1` stores named JSON fields and drag target identifiers, never
indices. Missing or invalid fields fall back independently to the existing defaults:
coordinates, destination dots, last-move highlighting, animation and magnification
on; circular target. Interactive animation remains 150 ms; the editor retains its
previous 200 ms animation when enabled. Magnification is 2× when enabled and 1×
when disabled; the lifted drag offset remains independent.

Play and Review (including imported-PGN analysis) derive settings from the same
inherited controller. The editor takes coordinates and animation only. Preference
updates retain board widget/controller identity, the game/session and engine state.
The last-move switch uses Chessground's `showLastMove`, preserving check, selected
square, premove and engine/drawn overlays. Destination visibility uses
`showValidMoves`, which also controls available premove destination dots in the
pinned library; already committed premove indicators remain independent.

Writes are serialized; a late initialization reply cannot replace a user choice.
A failed write keeps the visible choice and reports a localized retryable error.
The existing confirmed Settings reset includes this preference and preserves saved
games/captures. Cancelling either reset or the target chooser changes nothing.

Verification covers malformed/legacy storage, restart-style controller recreation,
serialized writes, failure recovery, independent mappings, target cancellation,
retained Review selection and all ten languages at 200% text in 320×640 and
640×320 layouts. Actual Android restart/input checks must also pass before the
Stable release is considered ready; prior Preview checks do not qualify the
Stable APK. See [promotion preparation](stable-2.5-preparation.md).

This is Preview feature work. No shared build, CI, release or cleanup helper changes
are part of #178, so no Stable tooling port applies. Stable has not been promoted.

## Board and piece designs (#177)

The approved inline card adds separate Board and Piece set rows. Each opens a
scrollable visual grid with selected-state text/checkmark/semantics and a larger
preview using the current combination. Selection saves immediately; Done/Back
returns to Settings. The grid reflows with viewport width and text scale.

Existing users keep Brown/Cburnett. Unknown and excluded stable enum names fall
back to those defaults without resetting valid aid fields. Confirmed reset
restores both designs as well as the aids. All 25 fixed Lichess boards and 16
verified piece sets are available offline. The System-colored board option is
deferred: dynamic board/highlight contrast and a readable fallback need a distinct
review, so the draft exposes no placeholder System choice.

Play, Review/imported-PGN analysis, the board editor, editor piece icons and the
library's promotion chooser use the same chosen assets. Non-board SAN notation
and textual material-difference symbols intentionally retain standard notation.
The editor's selected color and piece, position, turn and castling rights remain
independent. Library raw-image caches retain the selected piece set only; old
piece images are evicted after boards have repainted with the new settings.
Flutter's bounded image cache handles selector samples and board textures.

### Asset audit and packaging

`docs/board-style-assets.json` records exact upstream files, pinned renderer and
Lila notice revisions, authors, per-design licenses, preferred artwork paths/Git
blobs, conversions, checksums and every excluded set. The vendored renderer is
unchanged at 10.1.1. Its asset declarations include approved sets only, so hidden
noncommercial/unclear sets are absent from APKs as well as the selector.
Full notices and license texts are bundled in the app's license information.

Run `python3 tool/check_board_style_assets.py --apk <candidate.apk> --output <report.json>`
to compare every packaged Chessground asset against that exact allowlist and its
hashes and record actual compressed/uncompressed asset size. A selector-only
check does not establish packaging. Compare qualified release APK sizes before
marking the draft ready; a debug integration APK does not establish release size.

The source allowlist check runs automatically in every GitHub Checks test job.
The existing release APK verifier also checks packaged artwork and bundled licence
notices, before Android SDK checks. Both fail closed on added, removed or changed
assets/notices; Python optimization cannot disable the checks. Unit tests use tiny
synthetic ZIPs, not Android builds. Build wrappers do not duplicate these gates.
On the review Mac, the source check took 0.039 seconds and its 14 regression tests
0.23 seconds. These are development checks: no app code or runtime cost is added.

Stable main `5f6743eed5491d2e8413fe0dfd1f8ef612d0aa84` was rechecked during this
review. It still uses hosted Chessground and has neither this feature manifest nor
the filtered local package. This feature-specific CI/APK gate cannot run there
without promoting the artwork feature, so no standalone Stable port applies.
Carry the checker, its tests and both gate integrations together when promoting
this feature; do not port it conditionally with a silent missing-manifest bypass.
Shared workspace/toolchain helpers and channel release requirements are unchanged.

### Draft measurement

The first ARM64 Android integration APK contains exactly 792 approved asset files,
6,622,164 bytes, all stored without further ZIP compression. The original hosted
package declares 13,236,470 asset bytes; filtering removes 6,614,306 bytes before
added notices/app code. This is an asset payload comparison, not a qualified net
release-APK size claim. A sequential 16-set widget loading check at DPR 1 retained
at most 786,432 RGBA bytes after repaint/eviction (81 ms measured on the build Mac);
device timing and higher-DPR memory are separate measurements. The controller also
retains the current board's texture highlight images so aid switches cannot evict
Horsey's selected/last-move artwork.

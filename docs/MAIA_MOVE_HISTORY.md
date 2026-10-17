# Maia move-history input (Preview and Dev)

This opt-in setting changes the positions supplied to Maia. It does not change
model weights, Temperature/Top-P, rating preferences, clocks or Stockfish review.
It is **off by default**, including Reset engine defaults. It is not a promised
strength improvement. The [79M study](https://github.com/Dash1971/mobile-maia-research/blob/main/studies/move-history-2026-10-09/REPORT.md)
found better human-move prediction and increased repeated copying in a specific
low-rated opening. That result is not a general strength claim or certification
of the smaller Dev model.

The Settings label is **Use move history**, with its own scrollable information
popup and research link. UI status labels no longer append “experimental”; the
recommendation to leave it off and the research caveats remain unchanged.

## Behavior contract

- Off repeats the current position in eight input slots, byte-compatible with
  earlier versions. On uses up to eight available positions, oldest first,
  padding on the left with the earliest available position. Each board uses
  its own side-to-move orientation, matching the pinned upstream encoder.
- The setting applies to played moves and both Maia analysis engines. Maia's
  displayed probabilities are still raw legal probabilities. Full-game move
  classification remains Stockfish-based and does not change.
- New games, imported games and new Analysis Boards use the current preference.
  Active games, reviews and saved Analysis Boards retain their stored mode,
  including when opened from Recent games. Legacy/missing/unknown modes are off.
  The probability detail sheet and engine-label tooltip identify the mode.
- Continue from here retains the selected branch's mode and up to seven
  preceding positions. These are model context only: the new game's moves,
  PGN, clocks and takeback boundary still start at the selected position.
- A standalone FEN has no earlier positions. Loading a different PGN/FEN,
  editing the board, or clearing moves discards old continuation context.
  Ordinary takebacks and variation selection reconstruct only the selected
  path; future or sibling positions must not enter the model input.
- The preference is the additive boolean `maiaUseMoveHistoryV1`. Snapshots use
  the additive boolean `maiaUseMoveHistory` and bounded `historyPrefix` list.
  No schema/version migration or rewrite of existing saved games is required.
  Invalid optional context is discarded after FEN and legal-adjacency checks;
  it must not make an otherwise valid game unreadable.
- Variation cache keys distinguish rating, mode and the effective eight-position
  window. Mainline results are per-ply and cleared on input/rating changes.
  Both models are fixed by the installed build; these caches are in memory,
  never reused across app/model upgrades. Obsolete asynchronous responses are
  rejected after context changes.

## Verification

Automated coverage lives in:

- `test/maia_history_encoding_test.dart`: parity with 38 pinned upstream tensor
  cases, short padding, both colors, window bounds, Stonewall context and
  same-FEN/different-history identity. Fixture provenance is recorded alongside
  `test/fixtures/maia_history_upstream.json`.
- `test/maia_history_review_test.dart`: both engines, stale mode/branch results,
  transposed variations and the selected Continue-from-here history.
- `test/maia_history_session_test.dart`: preference and snapshot behavior,
  restore, invalid optional context and the actual native predict arguments.
- `test/maia_settings_help_layout_test.dart`: all ten languages at 320×568 and
  200% text, including reachable research links and close action.

The regular Flutter suite covers existing play, storage, variations, sampling,
analysis, clocks and electronic-board flows. These tests run without changing
app model assets or downloading research data during CI.

Before promoting this experiment, qualify the exact Dev APK and check the 5M
model on a device: fresh game, resume, takeback, both Maia rows, variation
switching, Continue from here, and history-on/off latency and memory. Repeat
model/device qualification with the 79M build before Preview promotion. Host
encoding parity alone does not establish mobile performance or playing behavior.
Do not generalize the published 79M research findings to the 5M model.

# Opt-in Maia sampling data

This feature implements Preview issue #122. It is off by default, entirely
local, and separate from Copy diagnostics. It observes actual Maia **play**
requests; analysis-board probability displays and Stockfish are not captured.
Turning it off stops new captures and retains existing data. Requests already
started while enabled may finish recording their outcome.

## Storage and user controls

Engine settings offers Save Maia sampling data, its information button, Export
sampling data and Clear sampling data. The preference survives restart. Export
uses Android's document picker and streams JSON Lines to the location the user
chooses. Clear asks for explicit confirmation before deleting app-local captures;
Cancel, Back and dismissal leave them intact. Separately saved/shared exports
and the recording preference are unchanged. No Internet/storage permissions or automatic uploads are added.

Capture files live under the app's private `sampling-data/` directory, never in
Recent Games. **The latest ten recorded games are retained, including unfinished
games, with a 64 MiB safety ceiling. Older captures are deleted as whole groups.** Saved games/PGNs are unaffected. The active game and requests still in
flight are protected. If an exceptionally long active game fills the entire
allowance, further records are dropped and the export reports the loss; the
limit is not exceeded. Individual records are limited to 512 KiB. Export early
if you want to retain an older capture.

There is no guarantee of a complete game: enabling midway, turning capture off,
clearing data, a process kill, storage failure, or backpressure can leave gaps.
Every record and the manifest say `captured-decisions-only`. `pending` is an
incomplete checkpoint, **not** evidence that the move was played. Clear invalidates
in-flight capture tickets before deleting files, so a late result cannot restore
cleared data.

Pending input and final outcome are written atomically on worker isolates.
There are at most eight in-flight tickets, and new capture stops accepting work
at 16 queued writes (terminal writes for accepted tickets may still enqueue).
Gameplay never awaits a capture write or an export. The actual sampler consumes
exactly its existing random draw; identifiers do not use its RNG. Raw probability
calculation, float encoding, hashing and file I/O happen off the UI isolate.
Input/output snapshots and the small sampling trace are copied synchronously.

An export is a coherent cutoff in the write queue. Captures can continue after
that cutoff. Two temporary export copies can use approximately another 128 MiB
while the document picker is open, in addition to the 64 MiB store and the file
at the chosen destination. The Dart and native temporary files are removed when
the picker finishes; Clear also removes the internal export. Android may reclaim
the cache copy. A process kill may leave a temporary file until the next export
or Clear. There is no automatic expiry of the captured games.

## JSON Lines schema 1

UTF-8, one JSON object per line, newline terminated:

1. `type: manifest`: schema/algorithm versions, coverage, creation time,
   `prunedGames`, `droppedRecords`, `storageErrorObserved`, and interpretation of
   pending records. Dropped counts cover missed writes/requests, not necessarily
   distinct moves. Storage errors are known errors in the current process; a
   process kill cannot reliably record its own failure.
2. Decision envelopes: `record` is a JSON **string** containing the payload;
   `sha256` hashes the UTF-8 bytes of that exact string. Parse and verify it
   before interpreting the nested JSON. This avoids cross-language JSON
   canonicalization assumptions.
3. `type: footer`: record count and `contentSha256`, SHA-256 of **all preceding
   bytes**, including the manifest and every terminating newline. The footer
   itself is excluded. A missing footer means the export is incomplete.

Each payload contains:

- `requestId`, `gameId`, generation, zero-based ply within this played segment,
  FEN, side, FEN full-move number and timestamps. Game ID persists with the
  session; takebacks retain it, new games/Continue from here receive a new ID.
  Request ID distinguishes retries and revisiting the same position.
- App version/code/flavor, configured model identity and verified-model hash,
  ONNX Runtime version and CPU provider. `sourceRevision` is empty if the
  build did not supply `--dart-define=MAIA_SOURCE_REVISION=<commit>`; do not infer
  a commit from it. Injected evaluators are identified separately in tests.
- Actual ratings, history flag, ordered position history, continuation prefix,
  effective padded eight-FEN window, exact input tensor and returned logits.
  Tensor/logit objects contain `encoding: float32-le-base64`, float count,
  base64 bytes and SHA-256 of those decoded bytes. The layout is `[64, 97]`,
  eight 12-piece planes per square plus the zero ponder channel. Each FEN is
  oriented for its own side to move. Non-finite output remains representable
  in the binary encoding and is rejected before sampling.
- `cache: no-play-policy-cache`; queue stage; the actual legal UCI move order
  and model indices; raw legal probabilities; sampling trace below.
- `outcome`: `pending`, `committed`, `cancelled-or-stale`, `clock-expired`,
  `invalid-output`, `timeout`, or `error`. Only committed records contain the
  actual move and resulting FEN. Input/result FEN hashes permit identity checks.
  Errors record the exception type rather than an unbounded exception dump.

The game grouping is an optional additive session field, `samplingGameId`.
Legacy sessions without it get a fresh local ID; there is no migration or saved
chess-data rewrite requirement.

## Sampler `mobile-maia-sampler-v1`

The trace records requested and effective Temperature/Top-P, selected UCI,
legal move order, and `mode`. Ratings/history are frozen at inference submission;
New games freeze their configured Temperature/Top-P and opening-variety choice
in their saved play settings. With opening variety enabled, effective values are
1.0/1.0 through full move 5 (for each color), then the configured values from
move 6, using the current FEN full-move counter. Takebacks and continuations
therefore use the position’s move number, not a request count. Older saved games
never silently opt in. The capture records configured and effective settings
and whether the opening override applied; the selection trace and HTML report
use the actual effective sampling distribution.

- Temperature <= 0: first highest legal logit in the original legal move order.
  Mode is `argmax`, `random` is null, and no draw occurs.
- Otherwise temperature is clamped to [0.001, 1], Top-P to [0, 1]. Divide legal
  logits by temperature, subtract their maximum, and exponentiate. Sort weights
  descending. The trace stores the **actual resulting order**, including ties.
- Retain the smallest prefix reaching Top-P, including the crossing move. Top-P
  1 retains every candidate; Top-P 0 retains the first. The latter still draws
  once, preserving existing behavior.
- Multiply the recorded `draw` by retained weight `total`. In order, subtract
  each weight and select the first where the remainder is <= 0; fall back to
  the final candidate on floating-point remainder. Do not replace this with a
  different summation order when checking exact boundary cases. `lower`/`upper`
  describe the selected weight interval; `target`, `nucleusCount`, and every
  sorted candidate weight are recorded.
- Raw legal probabilities use unscaled logits: `exp(logit - max)` divided by
  their total in original legal order. These are separate from the distribution
  after temperature/nucleus filtering.

`test/support/sampling_replay.dart` independently checks exported checksums,
input planes, vocabulary indices, legal policy, nucleus and selected draw,
and the resulting board, with stage-specific assertion messages. This is app
regression code, not a research data collection tool. Research reports, datasets
and standalone analysis tools belong in
[mobile-maia-research](https://github.com/Dash1971/mobile-maia-research).

## Release qualification

Automated coverage is in `test/sampling_capture*_test.dart`. The small Qf5
fixture is explicitly a **reconstructed desktop** output, not a recovered phone
trace. Neither unit tests nor widget tests with a mocked native channel prove
real ONNX inference, Android document-provider behavior, or phone performance.

For changes to this feature, verify an actual Android build through normal play and
export/replay (including the Qf5 position), document-provider save/cancel,
process restart, and capture-on/off overhead in 1+0. Exercise takeback/branch,
resume and Continue from here, settings changes and interrupted inference.
Do not label this feature release-qualified solely because host CI is green.

### Initial host evidence

The initial full Flutter run passed 934 tests with one existing flavor-gated
skip; the additional takeback/branch capture regression passed separately.
Static analysis and both localization checks passed. All ten locale settings
and help dialogs were exercised at 320 × 568 with 150% text scaling.

On this Mac, a debug host microbenchmark measured roughly 6–7 µs per plain
sample, 18 µs with the trace callback, and 0.13–0.18 ms of synchronous capture
work per decision. Two asynchronous checkpoint writes averaged about 5 ms
including worker startup and disk I/O in a small store. These are observations,
not timing guarantees or phone/bullet/full-store qualification.

### Preview 2.4.0-beta.6 Android qualification

The publication record in [BUILD_CHANNELS.md](BUILD_CHANNELS.md) and release
`verification.zip` provide source/artifact hashes and exact test scope. Actual
79M Android play at the opening and Qf5 position, document-provider export and
independent replay, save cancellation, interruption/restart and near-capacity
64 MiB retention passed on the ARM64 emulator. Clear preserved existing archived
game hashes. The actual Preview-signed beta.5 upgrade preserved game data.
Small interleaved 1+0 measurements showed no observable recording slowdown in
that emulator; this is not a guarantee for physical phones. The maintainer
reviewed the setting and help screenshots before authorizing publication.

## Readable reports (proposed in #128)

The settings export row opens **Save…** or **Share…**. Both initially select a
self-contained **Readable report (HTML)**. **Full research data (JSONL)** keeps
the existing schema and replay data. No in-app summary or clipboard export is offered.

HTML groups recorded attempts by game ID, preserves their order and repeated
move numbers, and uses standard algebraic notation. Only committed records are
described as played; other outcomes say they were not recorded as played.
Each decision includes its own rating, color, effective Temperature and Top-P,
history mode, selection probabilities and up to three possible *other* moves.
These are the **actual selection probabilities after the recorded settings**,
not raw model probabilities, winning chances or move-quality scores:

- Random mode: divide each retained weight from `sampling.random.weightedOrder`
  (first `nucleusCount` entries) by their sum. Temperature is already applied
  to these weights. Validate their legal coverage/order, the Top-P crossing count,
  the recorded total and the selected/committed move before displaying anything.
- Moves outside that retained set or with zero weight have zero probability and
  are omitted from possible alternatives. Never substitute `rawLegalPolicy`.
- Deterministic `argmax` mode: the recorded selected move has probability 100%.
  Ties follow the sampler's recorded choice; do not sort raw probabilities to
  invent a new deterministic winner.
- A request that stopped before sampling has no selection percentages or arrows.
  A malformed committed trace is rejected, not silently shown with raw values.
- Positive probabilities below 0.01% display as `<0.01%`. “About a 1 in X chance”
  uses the reciprocal of the unrounded probability, with one decimal and locale
  formatting. Near-certainty has its own wording, so rounding never implies
  certainty; only exactly 100% is described as certain. Very large reciprocals
  use scientific notation without floating-point overflow.

The board is always visible: right of the text on wide screens, stacked below
on phones. It shows the position before the move, White at the bottom, with
coordinates outside. A solid charcoal arrow marks the committed move; a thin open
gray arrow marks the most probable choice. If the played move is a tied maximum,
show one charcoal arrow and label it as the most probable move. Percentages remain
in the text, never over the board. The original raw model policy remains in JSONL.

A report is explicitly a partial capture, not a complete game/PGN; capture loss
or pruning adds a coverage notice. Changes to rating/history/settings midgame
are never replaced with a single inferred game-wide value. Game numbering is
local to that snapshot, not an ID stored in Recent Games. The report does not
attempt to infer a result or time control not recorded in the source schema.

Report generation holds the existing snapshot lease and runs on a worker
isolate. It verifies exact-byte record/footer checksums, schema and legal move
sampling weights, and reads one bounded line at a time. Tensors/logits are
discarded from the compact report. HTML is written incrementally. Limits: 70 MiB input, 1 MiB per encoded line,
8,192 compact decisions. These bounds accommodate the existing 64 MiB store.
No new dependencies or persistent-data schema are introduced.

Save uses the native document picker. Share sends a read-only content URI through
Android's chooser; opening a menu does not share anything.
The native provider exposes only the dedicated `sampling-share/` cache folder.
Each handoff gets an immutable file (identical content can reuse a file), so
another export or Clear does not invalidate a recipient's in-progress read.
Shared copies are eligible for removal after 24 hours, on a later activity start
or share; Android may also reclaim cache. The cache is capped at 140 MiB and 32
files. It refuses further distinct shares when full instead of deleting recent
files; Save to file is still available. Closing the chooser cannot prove when a
receiving app has finished reading, so it must not immediately delete that copy.
Temporary generation/picker snapshots are removed on completion/cancellation;
activity-specific filenames avoid collisions across activity recreation.

This adds at most the bounded 140 MiB share cache to the existing capture and
transient export storage. Files explicitly saved to a user-selected destination
or received by another app are outside Clear sampling data's scope.

Checks: `test/sampling_report*_test.dart`, capture/export lease tests,
`test/sampling_capture_settings_test.dart`, and the native share-retention checks
run by `tool/test_board_native.sh`. Optional widget screenshots use
`MAIA_REPORT_MOCKUP_DIR` and `MAIA_REPORT_FONT`; optional production HTML samples
use `MAIA_REPORT_EXPORT_SOURCE` and `MAIA_REPORT_EXPORT_OUTPUT`. These are review artifacts,
not APK/device evidence. Before release, still qualify Save/Share/cancellation,
receiver access after returning to the app, and activity recreation on Android.

### Android Save recovery

The system Save picker uses a private snapshot. Its filename is included in Android
Activity state so completing or cancelling the picker after Activity recreation or
process death can finish the same export. The original captures are never moved.
Unreferenced interrupted snapshots expire after 24 hours; recent shared reports
retain their separate bounded cache policy. Native regression checks exercise
recreation, process death, cancellation and invalid restored filenames.

## Game navigation and metadata (Preview beta.8)

Both exports group games newest first, using their immutable capture game IDs;
requests within each game remain chronological, including retries/takebacks.
Reopening a retained game does not reorder it. Resuming an evicted game does not
recreate a misleading tail-only capture or evict newer games. Clear resets the
retention watermark. The count cap is also enforced when opening an older store.

The manifest includes `gameOrder: newest-first` and a `games` map keyed by game
ID. Each small summary contains `startedAt` (UTC, original start),
`playerIsWhite`, `elo`, PGN `result`, `timeControl` (minutes+increment, `-` for
unlimited), and the known Lichess opening name. Summaries are stored separately
from decisions, updated on gameplay saves including final human moves and forced
results, and survive deletion from Recent Games. A stale inference completion
cannot overwrite a newer game result. Unknown fields remain unknown; no data
migration or replay-based result guessing is performed.

HTML adds a linked game index and compact headings. Only result text receives
the same win/loss/draw/unfinished color as Recent Games, from the same palette.
Results describe the player's perspective. Dates display the exporting device's
time zone explicitly. All ten languages have localized labels. The report remains
self-contained and script-free; metadata is escaped. Raw decisions and sampling
probabilities are unchanged. No extra inference or network access is performed.

### Settings actions

The Sampling data row shows the saved-decision count (or storage error). Its
three-dot menu offers Save/Share and the existing HTML/JSONL picker; the adjacent
delete icon opens the confirmation from #134. Both buttons retain 48-pixel touch
targets, localized accessible tooltips and the existing busy-state guards.
The recording switch and its help remain separate. These layout changes do not
change capture files, limits, preference keys or the sampler.

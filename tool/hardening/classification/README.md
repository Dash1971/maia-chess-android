# Move-classification qualification

This directory separates three questions: are the annotation rules translated
correctly, are engine scores collected correctly, and are live searches in every mode
reliable enough to support a standout label? Matching rules does not make two
engines or two search limits produce identical scores.

## Pinned independent reference

The functions in `reference/src/main.rs` are copied verbatim from En Croissant
v0.15.0 `src-tauri/src/chess.rs` (`count_material`, `piece_value`, `qsearch`,
`naive_eval`). `reference/score.ts` contains its unchanged scoring and annotation
functions, excluding the unrelated formatting function/imports. The external
clamp is supplied locally. `annotate.mjs` runs that TypeScript with Node's native
type stripping. UCI strings replace SAN strings consistently on both sides of
the move-equality comparison; neither side tries to compare SAN with UCI.
These are GPL-3.0 sources; see the repository's LICENSE and THIRD_PARTY_NOTICES.

Checked on 2026-10-01:

- v0.15.0: `6f2d2628f0fbe11cb62a7dd2f9c102bb52907d53`.
- Latest release v0.15.1: `a5105d8dcb742e8924cedaac324010a0c6ec683c`.
- Current master: `23f83142fcbd4d3af60a524855defe8c9a5703fe`.
- Annotation rules, material/capture search and `analyze_game` are identical
  across these revisions. The newer report UI changes concern dialog state and
  shortcuts, not classification. This was checked against source, not just
  release notes: https://github.com/franciscoBSalgueiro/en-croissant/compare/v0.15.0...23f83142fcbd4d3af60a524855defe8c9a5703fe

Rust uses shakmaty 0.27.1 and the relevant transitive versions in the upstream
lockfile. Commit the small Cargo.lock; never commit Cargo's target directory or
a toolchain. Rust, Node and Python are optional developer tools, not app
runtime or routine CI dependencies.

## Production behaviour

- A MultiPV comparison uses one complete, exact, same-depth snapshot, including
  its scalar graph score. A newer incomplete iteration cannot overwrite one
  half. Bounds, missing scores/PVs, duplicate roots and illegal root moves do
  not form a comparison. A single exact PV remains useful without invented
  alternatives. Missing usable scores fail instead of inventing a draw.
- Full-game runs use one search thread and a fresh `ucinewgame`/`isready`
  boundary. Hash stays warm between positions in that run. Foreground browsing
  retains two threads; crossing between foreground and batch ownership resets
  engine state inside the existing serial queue. Preemption drains before reset.
  One thread reduces scheduling variation; time limits can still cause variation
  on slower or busy hardware.
- All three modes corroborate the **whole annotation decision**, not only the
  best-vs-second gap. Brilliant depends on the before/after loss as well as the
  unique-best and sacrifice tests; Good additionally depends on the preceding
  position. The same upstream standout label must follow from the previous
  completed iteration of every required position, or from a separate complete
  verification window. An explicit contradictory window overrides apparent
  iterative stability. Quality metadata must agree; an independent window
  cannot be shallower than its original positions.
- An owned worker first identifies provisional `!`/`!!` awards. Only unstable
  awards consume a **six-search budget**: Brilliant costs two searches; Good
  costs three except on the first ply. A window starts with a fresh session.
  Verification targets two plies beyond the selected mode, with that mode's
  original time cap:

  | Mode | Normal search | Verification search | Maximum extra requested search time |
  | --- | --- | --- | --- |
  | Fast | depth 12 / 500ms | depth 14 / 500ms | 3 seconds |
  | Balanced | depth 14 / 1000ms | depth 16 / 1000ms | 6 seconds |
  | Thorough | depth 16 / 1500ms | depth 18 / 1500ms | 9 seconds |

  These are requested engine-search budgets, excluding queue waits, retries
  after foreground preemption, scheduling/stop overhead and material
  classification. Stable awards need no extra searches. Unconfirmed awards
  beyond the budget are withheld. **Verification evidence never replaces
  baseline evaluations/PVs:** the graph, accuracy and neighboring move labels
  keep their original inputs. Failed/cancelled windows attach nothing.
  This conservative confidence policy deliberately adds to EC's annotation
  rules in every mode; exact oracle parity is checked separately with it off.
- Sacrifice search now accounts for mate inside capture sequences as upstream
  does. Mobile Maia retains final terminal positions on the graph and uses
  finite terminal material values instead of Rust's `i32::MIN` root sentinel.
  Terminal moves cannot earn a sacrifice award. EC omits terminal positions
  from this part of its report; the reference adapter records that distinction.
- The expensive material search remains in an owned, cancellable isolate. It
  is not capped at an arbitrary node count. Complex capture trees can still
  take seconds; cancellation must terminate the worker, not merely its Future.
  The provisional worker returns its deterministic material values for reuse
  by the final worker. This cache belongs to one analysis run; it contains no
  engine scores and does not survive into another run. Cancelling either pass
  terminates its worker and cannot publish partial classifications.
- No FENs, PVs, new telemetry or files are logged by this feature in production.
  Search provenance lives in memory. Full traces are explicitly generated by
  the optional test harness from the checked-in public/synthetic games.

## Routine checks (no native engine, downloads or Rust compilation)

```sh
flutter test test/stockfish_snapshot_test.dart test/stockfish_session_test.dart \
  test/annotation_confirmation_test.dart test/annotation_window_queue_test.dart \
  test/classification_all_modes_review_test.dart test/review_annotation_pipeline_test.dart \
  test/classification_boundary_reference_test.dart test/classification_reference_test.dart
flutter test --reporter expanded
flutter analyze
```

The four committed game corpora contain 821 moves / 838 positions across
17 runs: the complete Byrne–Fischer game with SF18 and Stockfish Light, the
Opera game, a quiet Ruy Lopez line, seeded legal play, promotion and en-passant
starting positions. Every nonterminal material value, complete PV and annotation
is checked against the independent Rust/TypeScript outputs. Fixture tests check
unmodified upstream annotation semantics, then exercise production provenance,
provisional selection and the confidence policy on the same scores. Separate
tests exercise the real analyzer/confirmation path. The engine
fixtures retain the last two depths and any incomplete final iteration, not
just hand-picked final labels. Routine CI replays these fixtures without
running a live engine search or building Android. A separate 34 KB fixture
adds 3,075 independent numeric cases around all annotation thresholds, both
colours, mate signs, score clamps, first-ply handling and differing PV counts.
Regenerate it with `node tool/hardening/classification/generate_boundaries.mjs`.
Actual Review-screen tests inject the engine boundary, leaving both classification
workers and the normal full-game orchestration active in each mode.

## Regenerate / expand on Mac or Linux

Install the pinned Flutter SDK, Python dependencies from
`tool/hardening/requirements.txt`, Rust (tested with 1.90.0) and Node >=22.18.
Supply an explicit Stockfish executable; use SF18 for comparison with the user's
En Croissant installation and the app's pinned Light sources for app qualification.

```sh
cargo build --locked --release --manifest-path tool/hardening/classification/reference/Cargo.toml
python tool/hardening/classification/collect.py \
  --stockfish /path/to/stockfish \
  --reference tool/hardening/classification/reference/target/release/en-croissant-material-reference \
  --output /tmp/classification.json
MAIA_CLASSIFICATION_CORPUS=/tmp/classification.json \
  flutter test test/classification_reference_test.dart --reporter expanded
```

Use `--game byrne-fischer-1956 --sequence fast,balanced,thorough,fast` for run-order
comparisons, `--warm` to reproduce legacy hash reuse, `--threads 2` for the old
thread setting, and `--reverse` to reverse game order. `--fresh-process` restarts the engine
between runs as well as clearing its hash. No corpus is downloaded.
Do not overwrite golden fixtures merely to make a mismatch pass: retain the
failing inputs and determine whether the engine, collector, or classifier differs.

To qualify the actual Dart analyzer, queue, search settings and confidence policy
against a local CLI engine (rather than the Python collector):

```sh
MAIA_STOCKFISH=/path/to/stockfish MAIA_LIVE_REPORT=/tmp/live.json \
  flutter test tool/hardening/classification/live_test.dart --reporter expanded
flutter test tool/hardening/classification/worker_lifecycle_test.dart \
  --enable-vmservice --reporter expanded
```

`MAIA_SEQUENCE=fast,balanced,thorough,fast,balanced,thorough` repeats all modes.
`MAIA_SCENARIO=fresh-process` restarts the CLI engine between runs; `warm` is a
legacy-control experiment, not the production policy. Set `MAIA_GAME=opera-1858`
to select a different corpus game, and `MAIA_NODE=/path/to/node` when Node is not
on PATH. The live harness executes the independent EC oracle on **every label**
and on every awarded decision window, including earlier iterations. Only the documented
withholding of an unsupported `!`/`!!` may differ from the baseline oracle.
The JSON report can also be verified after the engine has exited:

```sh
python tool/hardening/classification/verify_live.py \
  --report /tmp/live.json --node /path/to/node
python tool/hardening/classification/verify_live_selftest.py \
  --report /tmp/live.json --node /path/to/node
```

The second command checks that deliberately corrupted evidence is rejected.
The JSON report contains per-position achieved depth, time, nodes, reset state,
candidates, scores, material decisions and labels. Worker tests inspect actual VM isolates
across 25 spawn/cancel races, six Review lifecycle paths and 300 completion races.
Keep these optional checks outside routine CI; run them for changes to this code
and before releasing a new classification implementation.

For the actual Android library and Flutter isolate/runtime:

```sh
flutter drive --profile --flavor dev -d emulator-5554 --keep-app-running \
  --driver test_driver/integration_test.dart \
  --target integration_test/classification_android_test.dart \
  --dart-define=MAIA_SEQUENCE=fast,balanced,thorough,fast,balanced,thorough
```

After the driver finishes, stop the known Dev package explicitly:

```sh
adb -s emulator-5554 shell am force-stop com.dash1971.maia_chess.preview.dev
```

`--keep-app-running` avoids a Flutter driver cleanup bug that tries to uninstall
the unflavoured package name. This does not change the tests or engine settings.

Dev and Preview use the same Stockfish library. This supplementary Dev test is
not a substitute for the official Preview release APK/79M qualification in
`../RELEASE_CHECKS.md`. The existing model verification task requires both
model files materialized, even for a Dev build.

Use profile for native performance qualification. Flutter's default plugin
profile variant inherited Debug and produced the same unoptimized Stockfish
library as Debug. The root Gradle override now selects CMake Release for the
Stockfish profile variants while retaining the Dart profile test connection.
The release build configuration is unchanged. Debug remains useful for logic
tests, but its much slower native searches can hit Fast's time cap before
reaching the evidence required for the expected labels.

Capture the Android output, then independently replay every label and every
awarded confidence window with the pinned EC TypeScript:

```sh
python tool/hardening/classification/verify_android.py \
  --log /tmp/android-all-modes.log --node /path/to/node
```

The Android test records all positions/PVs/labels, not just selected brilliancies.
`--dart-define=MAIA_FRESH_PROCESS=true` adds native engine restarts between runs.

See [the all-mode follow-up results](RESULTS-2026-10-01-ALL-MODES.md) for the
current qualification and limits. [The original results](RESULTS-2026-10-01.md)
are historical evidence for #62; they did not qualify the complete feature.

## Release acceptance

Require the full ordinary suite, all-mode native repeated/reordered runs,
independent Android replay, and owned worker checks. In this reported game the
app engine in every mode must retain Black's three brilliancies
(plies 22, 34, 38) and never award White's 12.Qa3 (ply 23) a Brilliant label.
Compare all other labels too and retain the scores when they differ. Expected
labels from a fixed input fixture are exact; live cross-engine labels are not.

On a real phone, repeat all three modes, then reverse their order; browse during
a batch; stop and restart; background/return; test a long game on slower hardware. Check elapsed
time, scrolling and battery/heat. Desktop or emulator timing is not a phone
performance claim. Preserve evidence, then remove temporary APKs, native build
output, toolchain downloads and emulator snapshots created for the audit.

# Top-P 0.95 follow-up: evidence and reproduction

This archive contains the completed 2026-10-03 comparison of Temperature 1 / Top-P 0.95 with Temperature 1 / Top-P 1 at 1600 conditioning, using the same pinned Maia3 79M model and Mobile Maia policy implementation as the original study. See the [full report](../REPORT.md) for interpretation.

The fixed primary experiment contains 1,200 new games in six independently seeded shards of 200, with 600 games per color. Games start from the standard position, without books, forced openings, search or resignation. The primary endpoint follows the app's actual draw rules; the paired claim-draw sensitivity uses the earliest standard claim endpoint from the same sampled prefixes. Primary p95 W/D/L is 671/100/429: score 60.08%, relative match Elo +71.0 (95% interval +52.2 to +90.3). This is a relative match measurement, not a calibrated human rating. Opening evidence contains 2,000 new 16-ply sequences plus conditional policy calculations and independent checks.

## Evidence layout

- `strength/`: pre-outcome protocol, executed code, dependency/model pins, six complete JSONL/PGN/manifest sets, paired claim sensitivity, analysis and integrity receipts, official-fixture/app-draw parity checks and seeded replay checks.
- `openings/`: pre-outcome protocol, raw generated sequences, cached conditional policies, opening/family diversity results, labels and seed validation, and book-free reproduction receipt.
- `audit/`: independent complete-game and claim-prefix audit, independent cached diagnostics, code and input provenance.
- `first-move-check.json` and `conditional-check.json`: additional independent checks and their scripts.

`archive-provenance.json` and `RAW-SHA256SUMS` record 101 files copied byte for byte from the finalized local study. They exclude temporary progress files, routine runtime logs, Python caches and an aborted scheduling diagnostic. The meaningful native-shutdown failure log is retained with its documented postprocessing fix. Its replacement hashing utility changes no sampled moves or statistics; the original executed analysis and first-attempt verifier remain available.

The executed Dart helper is preserved as `strength/check_dart_rules.original.dart.txt`. The runnable `strength/check_dart_rules.dart` differs only by adding braces around an `if` body to satisfy the repository lint rule; it has the same behavior. The original remains in the raw-file manifest, and the runnable copy is covered by the publication manifest.

Historical absolute paths and “local only” wording in original protocols and receipts are preserved because their hashes were frozen before outcomes. Publication was authorized later. Use the current commands below rather than those historical machine paths. The wrapper and this README are publication conveniences, outside the immutable raw-file list. The complete publication's manifest covers them separately.

## Offline match-statistics reproduction

From this `followup` directory, with Python 3.12:

```sh
python3.12 -m venv /tmp/maia-p95-venv
/tmp/maia-p95-venv/bin/python -m pip install -r requirements-cached.txt
/tmp/maia-p95-venv/bin/python reproduce.py --check-only
/tmp/maia-p95-venv/bin/python reproduce.py --output /tmp/maia-p95-recomputed
```

Choose a new output directory. This verifies all raw evidence hashes and runs the unchanged `strength/analyze_results.py` on the archived primary and sensitivity outcomes, with the predeclared 200,000-replicate color-stratified bootstrap and seed. It compares every numerical result except runtime fields to the archived values (tolerance 1e-12), also checking profile, method and termination labels. `cached-reproduction.json` records zero inference calls. The publication check reproduced all 150 numerical fields exactly; its receipt is [cached-statistics-reproduction.json](cached-statistics-reproduction.json). No model, opening book, network access or ONNX Runtime is required.

For independent complete-game, legal-move, PGN, app-rule and earliest-claim-prefix verification, copy `strength/` and `audit/` together to a scratch directory before running the audit, which writes its result beside its script:

```sh
mkdir /tmp/maia-p95-audit
cp -R strength audit /tmp/maia-p95-audit/
/tmp/maia-p95-venv/bin/python /tmp/maia-p95-audit/audit/audit_final_games.py
```

The existing [final audit](audit/final-audit.json) checks all 1,200 games, 107,794 plies and paired claim endpoints independently. Seeded model replay and Dart parity evidence require their recorded model/Dart dependencies to rerun; their preserved receipts are distinct from offline outcome verification.

## Offline opening calculations

The original study fixtures are already included one directory above this archive. Copy `openings/` to a new scratch directory so generated outputs cannot overwrite the evidence. Run from this `followup` directory:

```sh
study_root="$(cd .. && pwd)"
cp -R openings /tmp/maia-p95-opening-recomputed
/tmp/maia-p95-venv/bin/python reproduce.py --hash-only-script /tmp/maia-p95-opening-recomputed/conditional.py --source-study "$study_root"
/tmp/maia-p95-venv/bin/python reproduce.py --hash-only-script /tmp/maia-p95-opening-recomputed/analyze.py --source-study "$study_root"
/tmp/maia-p95-venv/bin/python reproduce.py --hash-only-script /tmp/maia-p95-opening-recomputed/diversity.py --source-study "$study_root"
/tmp/maia-p95-venv/bin/python reproduce.py --hash-only-script /tmp/maia-p95-opening-recomputed/validate_labels.py --source-study "$study_root"
```

These unchanged scripts import only `sha256` from the inference helper. The wrapper supplies the identical standard-library SHA-256 operation through a hash-only module, avoiding an unnecessary native ONNX Runtime import; it exposes no model or inference functions. Conditional probabilities, cutoffs, metrics and bootstraps run in the original scripts. Calculations use cached legal probabilities and stored rollouts; the published TSV is needed for label verification, while no book or raw Parquet is needed. [bookfree-reproduction95.json](openings/bookfree-reproduction95.json) records four byte-identical conditional outputs and 9,832 exactly reproduced numerical fields from the final opening analyses, excluding a runtime field.

## Optional new match generation

This is computationally expensive and is separate from offline reproduction. Install `strength/requirements.lock` in a Python 3.12 environment. Obtain the pinned export from [the audited app commit](https://media.githubusercontent.com/media/Dash1971/maia-chess-android/f659956d1c35206600cda515f462277c63e58205/assets/models/maia3-79m.onnx): 316,034,244 bytes, SHA-256 `3454b03ae78baa64a87b345fdb1a457265d912caec531039b074f07eda0d8010`. The portable helper rejects a different model hash. Model and upstream checkpoint provenance are in [source-pins.json](strength/source-pins.json); the model is not bundled in this archive.

```sh
export MAIA79_MODEL='/absolute/path/to/maia3-79m.onnx'
for shard in 0 1 2 3 4 5; do
  /path/to/full-runtime/bin/python strength/run_matches.py --shard "$shard" --output "/tmp/maia-p95-new/shard$shard"
done
```

Each shard has a fixed 200-game budget, fixed seed schedule and one ONNX Runtime thread. They may run concurrently if resources permit. Keep all six shards and do not stop based on results. Analyze the six new JSONL files with `strength/analyze_results.py`; run `strength/verify_results.py` on the six new shard directories and derive claim sensitivity using `strength/claim_sensitivity.py`. Historical manifests include machine paths and timing, so a fresh run's manifests need not be byte-identical. Numerical replay depends on the pinned runtime/model and platform behavior.

The opening rollout runner also preserves its original code and provenance, but fresh coverage annotations require the separately described source-study book fixture. The book did not choose or force any sampled moves. Offline opening reproduction above is complete with the published cached fixtures.

The synthetic match data contains model profile names, not human account identities. Public human reference data is the same previously published Lichess sample from the original study, with its original source metadata. This archive adds no model binaries, credentials or private HTTP caches. Repository code licensing and upstream attribution remain in the [repository license](../../../../LICENSE) and original study source documentation.

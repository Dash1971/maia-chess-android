# Reproduce the history research

Use Python 3.12. Work from this directory (`docs/research/maia3-history`) in a
clone or downloaded source archive. GitHub may require **Download raw file**
for the compressed evidence. No model, Stockfish or network access is needed
to audit recorded results after obtaining the publication bundle.

## Audit recorded results

```sh
python3.12 -m venv .venv
.venv/bin/python -m pip install chess==1.11.2 numpy==2.5.3
.venv/bin/python prepare.py
.venv/bin/python verify_publication.py
```

`prepare.py` checks archive hashes before unpacking and refuses to overwrite a
changed file. `verify_publication.py` verifies all published checksums and all
original measurement bytes, recalculates legal-policy metrics and broad
averages, replays every Stonewall trial and random draw, recomputes its paired
bootstrap intervals, and checks the fixed-path probability products. It is
read-only. The original inference, engine and data-validation evidence is
also retained in `broad-study/results` and `stonewall/verification.json`.

The large broad archive contains selected input histories, all legal-policy
vectors, both main-result shards and their merged counterpart, tactical
candidate records, and the PyTorch reference fixture. Shards and merged files
are the same observations; do not pool them as independent data. The 2,400
equal-rating positions and 48 deeper tactical positions are sensitivity
subsets, not additional independent samples. The 1,000-position pilot remains
separate.

## Recompute inference

```sh
.venv/bin/python -m pip install onnxruntime==1.30.0
.venv/bin/python prepare.py --model
.venv/bin/python broad-study/check_parity.py
.venv/bin/python broad-study/verify_results.py
```

The model download is about 316 MB and is checked against the published
SHA-256. Alternatively, set `MAIA_MODEL` to an existing file with that exact
hash. `check_parity.py` compares ONNX output with the archived official
PyTorch fixture. `verify_results.py` checks every broad result and directly
re-infers 21 fixed positions; it writes a fresh verification record, so use a
working copy if retaining the publication checksums. Its original same-runtime
tolerance is strict; report numerical differences on another backend rather
than silently loosening it.

For a fresh Stonewall run, copy `stonewall` and `broad-study` into a separate
working directory with the same sibling layout, set `MAIA_MODEL` to the
downloaded model's absolute path, and run:

```sh
python stonewall/run.py
```

This overwrites the working copy's Stonewall policies, fixed-prefix results,
sampled games and summary. It retains the original sample sizes and seeds.
Different inference backends can change sampled trajectories even when their
probabilities agree closely. The portable script changes the encoder import
path only; probabilities and sampling logic are unchanged.

## Rebuild the broad summaries or measurements

In a working copy with the records unpacked and `onnxruntime` installed:

```sh
python broad-study/analyze.py
```

This regenerates the merged main result, tactical metrics and the full
cluster-bootstrap summary from saved policies. It performs no new inference.
The summary's script-hash field changes because the portable module paths
differ; numerical results should agree on the recorded runtime.

For fresh model inference, retain the selected `*.jsonl` input files and the
registered protocol, but create an empty `broad-study/results` directory in
the working copy. Then run:

```sh
python broad-study/study.py pilot
python broad-study/study.py main --offset 0 --shards 2
python broad-study/study.py main --offset 1 --shards 2
python broad-study/study.py opening
python broad-study/study.py equal --equal
python broad-study/study.py challenge
python broad-study/study.py cases
```

The inference workers append and skip completed IDs; an existing results
directory would resume instead of repeating the experiment. Preserve archived
parity evidence for summary generation, or regenerate it as described below.

To reconstruct selection or the human-context counts, download the 44.7 MB
pinned Allie source with `prepare.py --human`. In the working copy,
`broad-study/select_data.py` recreates selection and
`broad-study/validate_data.py` checks source histories. The two user-example
case fixtures are already included; private local PGN paths are not required.

## Stockfish diagnostics

Install **Stockfish 18** and set `STOCKFISH_BIN` to its executable path, or place
it on `PATH`. The original version, binary hashes and budgets are in the
tactical run metadata. These tests used a host engine, not the app's bundled
Stockfish version. In a working copy with the selected inputs:

```sh
python broad-study/tactical.py --offset 0 --shards 2
python broad-study/tactical.py --offset 1 --shards 2
python broad-study/tactical.py --deep
python broad-study/tactical_cases.py
python stonewall/context.py
```

The Stonewall context command also needs the downloaded Allie source.
Broad tactical workers resume completed rows. Clear their output files in the
working copy for a fresh run. Engine scores can differ across binaries or
platforms; preserve exact terminal flags separately from finite-search scores.
The metadata-only repair during the original run is documented in
[METADATA_REPAIR.txt](broad-study/METADATA_REPAIR.txt).

## Regenerate the upstream reference

Use a separate environment matching the recorded
[reference dependency snapshot](broad-study/source/reference-requirements.txt).
Clone [CSSLab/maia3](https://github.com/CSSLab/maia3) at
`1e13597c42d4858b7cfd7cfdae01e297263364b2`, and obtain the official
[Maia3-79M checkpoint](https://huggingface.co/UofTCSSLab/Maia3-79M).
Set `MAIA_SOURCE` to the clone directory and `MAIA_CHECKPOINT` to the checkpoint
file. The script verifies checkpoint SHA-256
`3fc6181d5db789b45a15305732148757ae74efa3e0028e81ba335b462dac45c2`.

Run `broad-study/verify_upstream.py` using that environment, with the Allie
source available, then `broad-study/check_parity.py` using the ONNX environment.
The original scripts and runtime snapshots underpin the recorded provenance;
[publication-integrity.json](publication-integrity.json) identifies portable
path adaptations. Original measurements and registered protocols are unchanged.

# Reproduce the Mobile Maia sampling study

These portable copies change only model location and add pinned-file hash verification; the measured runs used the separately preserved original scripts, whose SHA-256 values are in their manifests. Encoder, move mapping, distributions, game rules and seeds are identical. Portable inference passes the same official 75-logit reference check (`portable-parity.json` in the parent study directory).

Use Python 3.12 and a CPU ONNX provider. In this directory:

```sh
python3.12 -m venv .venv
.venv/bin/python -m pip install -r requirements.lock
mkdir -p models
curl -L 'https://media.githubusercontent.com/media/Dash1971/maia-chess-android/f659956d1c35206600cda515f462277c63e58205/assets/models/maia3-79m.onnx' -o models/maia3-79m.onnx
.venv/bin/python verify_policy.py
.venv/bin/python run_strength.py --model 79m --games-per-pair 600 --pair-index 0 --output results/79m-pair0
.venv/bin/python run_strength.py --model 79m --games-per-pair 600 --pair-index 1 --output results/79m-pair1
.venv/bin/python run_strength.py --model 79m --games-per-pair 600 --pair-index 2 --output results/79m-pair2
.venv/bin/python analyze_strength.py results/79m-pair0/games.jsonl results/79m-pair1/games.jsonl results/79m-pair2/games.jsonl --output results/summary-79m.json
.venv/bin/python verify_games.py results/79m-pair0 results/79m-pair1 results/79m-pair2 --output results/integrity-79m.json
```

The exact 79M download URL was checked with an HTTP HEAD request: 200, 316,034,244 bytes. Its SHA-256 must equal `3454b03ae78baa64a87b345fdb1a457265d912caec531039b074f07eda0d8010`. The script rejects a mismatched model rather than silently running a different checkpoint or export. For a model located elsewhere, set `MAIA79_MODEL` to its absolute path. `MAIA5_MODEL` similarly overrides the default `models/maia3-5m.onnx` path.

The three matchup commands may run concurrently, each with one CPU thread, or sequentially. Resume with exactly the same command and output directory; completed game IDs are skipped after manifest validation. A fresh study with different source code, runtime, settings or game count needs a fresh output directory.

The 5M sensitivity requires the exact 21,346,652-byte ONNX file with SHA-256 `ddae2aa893b5ca7ec94d24178871f1c337d09fd72ff38abe8d76b8ecf08cb942`. Its local app LFS pin was verified, but historical public GitHub URLs for that binary returned 404 at publication preparation time. Download the [immutable archived study asset](https://github.com/Dash1971/maia-chess-android/raw/e5c2392c4d979a47e458ba6f571c72ca60ae817b/docs/research/maia3-sampling/assets/mobile-maia-5m-reproduction-asset.zip) (archive SHA-256 `aaadbc907664aaccec9c5a1c534b91fbce273ed3fa04df68d692b046c8806110`) or export the official `UofTCSSLab/Maia3-5M` checkpoint with the app's `tool/export_maia3_onnx.py` at the pinned source revision. Export environments can change ONNX bytes, so compare hashes: another export is a new sensitivity run, not an exact byte-identical reproduction. Then run:

```sh
.venv/bin/python run_strength.py --model 5m --games-per-pair 200 --output results/5m
.venv/bin/python analyze_strength.py results/5m/games.jsonl --output results/summary-5m.json
```

Secondary single-knob comparisons preserve full sampling as their reference:

```sh
.venv/bin/python run_supplement.py --model 79m --games-per-pair 300 --pair-index 1 --seed 2026100300 --output results/79m-temp-only
.venv/bin/python run_supplement.py --model 79m --games-per-pair 300 --pair-index 2 --seed 2026100300 --output results/79m-topp-only
.venv/bin/python analyze_strength.py results/79m-temp-only/games.jsonl results/79m-topp-only/games.jsonl --output results/summary-single-knob.json
```

App draw timing sensitivity continues only prospective repetition or fifty-move claim stops; it preserves every primary prefix, samples future moves from new recorded seeds, and uses actual raw-FEN threefold repetition or 100 halfmoves. For example:

```sh
.venv/bin/python app_draw_sensitivity.py results/79m-pair0/games.jsonl results/79m-pair1/games.jsonl results/79m-pair2/games.jsonl --model 79m --continuation-seed 3000000000 --output results/79m-app-draw
.venv/bin/python analyze_strength.py results/79m-app-draw/games.jsonl --output results/summary-79m-app-draw.json
.venv/bin/python verify_sensitivity.py --primary results/79m-pair0/games.jsonl results/79m-pair1/games.jsonl results/79m-pair2/games.jsonl --sensitivity results/79m-app-draw --output results/integrity-79m-app-draw.json
```

The original app's Elo number is an input describing the move population. These relative engine-game scores and logistic Elo differences do not calibrate human Elo. Different platforms, providers or arithmetic can change a near-tied choice and later game trajectory even with the same seeds; use the recorded runtime for exact local replay.

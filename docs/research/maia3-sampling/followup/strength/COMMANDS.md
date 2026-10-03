# Commands

Run from the workspace root. This follow-up reuses Python 3.12.13 and the pinned packages in `requirements.lock` from `sampling-research-20261002/strength/venv`. For another machine, create a Python 3.12 environment with `python3.12 -m venv .venv`, then `.venv/bin/python -m pip install -r requirements.lock`, and substitute its Python path below. Set `MAIA79_MODEL` to an existing pinned 79M export; the helper rejects a different hash.

```sh
export MAIA79_MODEL='/path/to/verified/maia3-79m.onnx'
sampling-research-20261002/strength/venv/bin/python sampling-followup-20261003/strength/check_preflight.py
```

The preflight Dart portion uses the existing Flutter SDK and the app's installed Dart dependency for verification only. Its exact command and dependency hash are saved in `preflight.json`. No app source is edited. The primary runner itself needs only the pinned Python dependencies and model.

Launch each shard with this command, substituting `0` through `5`. All six were run independently at once, each with one ORT intra-op and one inter-op thread. Their RNG streams are independent; manifests enforce unchanged code/configuration for durable resume.

```sh
sampling-research-20261002/strength/venv/bin/python sampling-followup-20261003/strength/run_matches.py --shard 0 --output sampling-followup-20261003/strength/shard0 > sampling-followup-20261003/strength/shard0-progress.log 2>&1
```

After all six reach exactly 200 games:

```sh
sampling-research-20261002/strength/venv/bin/python sampling-followup-20261003/strength/verify_results.py sampling-followup-20261003/strength/shard{0,1,2,3,4,5} --output sampling-followup-20261003/strength/integrity.json
sampling-research-20261002/strength/venv/bin/python sampling-followup-20261003/strength/analyze_results.py sampling-followup-20261003/strength/shard{0,1,2,3,4,5}/games.jsonl --output sampling-followup-20261003/strength/results-primary.json
sampling-research-20261002/strength/venv/bin/python sampling-followup-20261003/strength/replay_selected.py sampling-followup-20261003/strength/shard{0,1,2,3,4,5} --output sampling-followup-20261003/strength/replay-check.json
sampling-research-20261002/strength/venv/bin/python sampling-followup-20261003/strength/claim_sensitivity.py sampling-followup-20261003/strength/shard{0,1,2,3,4,5}/games.jsonl --output sampling-followup-20261003/strength/claim-sensitivity
sampling-research-20261002/strength/venv/bin/python sampling-followup-20261003/strength/verify_claim_sensitivity.py --primary sampling-followup-20261003/strength/shard{0,1,2,3,4,5}/games.jsonl --sensitivity sampling-followup-20261003/strength/claim-sensitivity --output sampling-followup-20261003/strength/integrity-claim-sensitivity.json
sampling-research-20261002/strength/venv/bin/python sampling-followup-20261003/strength/analyze_results.py sampling-followup-20261003/strength/claim-sensitivity/games.jsonl --output sampling-followup-20261003/strength/results-claim-sensitivity.json
```

All results and logs remain local. `PROTOCOL.md` is the pre-outcome design; per-shard manifests pin its hash, the exact executed runner/helper/draw rules, software versions and model. `preflight.json` confirms unchanged portable policy and reference parity.

After an observed host slowdown, the coordinator began recording a scheduling baseline. The user then reported that their own analysis workload had ended. The proposed scheduling experiment was cancelled during baseline, **before any worker was paused**. All six match workers remained running unchanged, with identical sources, seeds, sample size and numerical settings. The cancelled baseline record is `../scheduling-check.json`; it records baseline start and `cancelled_before_any_worker_pause`, with no timing experiment completed. Runtime measurements reflect shared-host wall time and changing host load, rather than an isolated CPU benchmark.

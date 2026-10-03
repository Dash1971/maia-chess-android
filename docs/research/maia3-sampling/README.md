# Mobile Maia sampling research

Start with [the visual overview and full research report](REPORT.md). [APP-NOTE.md](APP-NOTE.md) records the in-app explanation. The report supports the 1.0/1.0 default adopted in [PR #25](https://github.com/Dash1971/maia-chess-android/pull/25).

The report brings together the tests run on **2–3 October 2026**: **4,200 complete matches** and **6,001 opening sequences**. It compares **Temperature / Top-P 0/0, 0.5/0.9, 1/0.95 and 1/1** at the 1600 setting. The main model is Maia3-79M; separate tests change one control at a time and check the smaller 5M model.

The **[1/0.95 comparison](followup/README.md)** contains 1,200 new matches and 2,000 new opening sequences. Its human references and the 1/1 opening sample come from the first round. Draw-rule sensitivities reuse games and are not counted as additional matches.

## Browse or download

The final results and scripts from both rounds are in this directory. Download the repository ZIP from GitHub's **Code → Download ZIP**, or clone the repository, then work in `docs/research/maia3-sampling`. `SHA256SUMS` records the published research files; `MEASUREMENT-SHA256SUMS` preserves the original research archive manifest; [publication-integrity.json](publication-integrity.json) lists the editorial changes since that archive. Editorial updates and regenerated figure labels do not change the recorded measurements.

- **Game records:** [three 79M matchups](strength/79m-pair0/games.pgn), [second matchup](strength/79m-pair1/games.pgn), [third matchup](strength/79m-pair2/games.pgn); each directory also contains JSON, seeds and its run manifest.
- **Opening records:** [free-play sequences](openings/rollouts.json), [79M conditional probabilities](openings/conditional.json), [5M conditional probabilities](openings/conditional-5m.json), [parsed public human-game sample](openings/human-sample.json). Large JSON files may require GitHub's **Download raw file** button.
- **Summaries:** [79M strength](strength/results-79m.json), [app draw-rule sensitivity](strength/results-79m-app-draw.json), [conditional opening comparisons](openings/conditional-summary.json), [free-play comparisons](openings/summary.json).
- **Research-only model asset:** The exact 5M export and license are available from the [immutable 2.2.0 source snapshot](https://github.com/Dash1971/maia-chess-android/raw/e5c2392c4d979a47e458ba6f571c72ca60ae817b/docs/research/maia3-sampling/assets/mobile-maia-5m-reproduction-asset.zip). This is for the secondary sensitivity experiment and is not an app model asset. It is no longer carried in the current app source.
- **Figures:** [cover](figures/cover.svg), [first moves](figures/first-moves.svg), [opening variety](figures/opening-variety.svg), [match strength](figures/match-strength.svg), and [technical opening distance](figures/opening-distance.svg), with PNG/PDF counterparts in [figures](figures).
- **1/0.95 results and records:** [strength summary](followup/strength/SUMMARY.md), [opening report](followup/openings/openings95.md), [independent audit](followup/audit/final-audit.json) and [reproduction commands](followup/README.md).

## Read the evidence

- [Protocol](PROTOCOL.md): fixed sample sizes, comparisons and limitations.
- [Strength study](strength.md): full-game results, uncertainty, terminal rules and checks.
- [Opening study](openings.md): book provenance, conditional probabilities and free opening rollouts.
- [Source review](literature.md) and [Discord evidence](discord-evidence.md): distinguish published methods, inspected code and operator testimony.
- [Matched-position diagnostic](diagnostics/README.md): separate effects of both controls on the same evaluated positions.
- [Implementation audit](diagnostics/AUDIT.md) and [statistical audit](diagnostics/statistical-audit.md).

## Reproduce the calculations

Use Python 3.12. The files under `strength/portable/` provide the documented, hash-checked model download and match commands. Original measured scripts are preserved separately with personal filesystem paths redacted for publication; their manifests identify the code actually run. The portable copies preserve the numerical methods and remove that location dependency.

```sh
python3.12 -m venv .venv
.venv/bin/python -m pip install -r strength/portable/requirements.lock
.venv/bin/python -m pip install -r openings/requirements-lock.txt
.venv/bin/python validate_openings.py
.venv/bin/python diagnostics/recompute_diagnostics.py --cached-only --output /tmp/maia-recomputed-diagnostics
.venv/bin/python diagnostics/verify_diagnostics.py
```

These checks use archived values; they do not need model weights, a chess engine, live Lichess access or the original book binaries. See the opening study for regenerating its summaries from the archived conditional fixture and parsed human sample. The opening inference fixture can also be recomputed against the pinned model with `openings/recompute_fixture.py`.

To reconstruct the primary match statistics from recorded outcomes:

```sh
.venv/bin/python strength/portable/analyze_strength.py \
  strength/79m-pair0/games.jsonl \
  strength/79m-pair1/games.jsonl \
  strength/79m-pair2/games.jsonl \
  --output /tmp/maia-recomputed-strength.json
.venv/bin/python strength/portable/verify_games.py \
  strength/79m-pair0 strength/79m-pair1 strength/79m-pair2 \
  --output /tmp/maia-recomputed-integrity.json
```

The match analyzer requires only its recorded data and dependencies. Game verification checks legal play, final states, recorded results and PGN agreement. Fresh model runs take substantially longer and may diverge in game trajectories on different inference backends despite agreeing closely on logits.

The complete-game draw-rule sensitivity preserves primary prefixes and continues only early claimable draws using new independent future streams. It is a paired sensitivity analysis, not additional independent games to pool with the primary sample. Likewise, do not pool 79M and 5M outcomes or conditional book-position observations as independent games.

## Figures and publication bundle

Figures are available as PNG, SVG and PDF in `figures/`. To regenerate them from final saved results, install `matplotlib==3.11.2` and run `make_figures.py` and `make_cover.py`.

`build_publication.py` creates an optional allowlisted research ZIP with reports, code, pinned source metadata, reference fixtures, raw study games, final summaries and figures. It excludes virtual environments, Git checkouts, model weights, large source book/Parquet caches, progress logs, discarded pilot games and superseded interim diagnostic summaries. `SHA256SUMS` inside the archive identifies every included file. The builder checks fixed final sample counts before packaging.

The archived conditional fixture contains the human move distributions needed to recompute the book comparisons without rebuilding the multi-million-game books. The parsed human sample preserves public game links and first-16-ply records from the pinned official Lichess dataset. Source metadata and filtering rules are retained. These fixtures support audit of this study; they are not claimed to be the entire live Lichess opening explorer.

The exact 79M model has a verified public download URL in the portable instructions. The exact historical 5M ONNX asset was available locally but its historical public URLs returned 404. Its [immutable archived copy](https://github.com/Dash1971/maia-chess-android/raw/e5c2392c4d979a47e458ba6f571c72ca60ae817b/docs/research/maia3-sampling/assets/mobile-maia-5m-reproduction-asset.zip) includes upstream attribution, license, model card, exporter and hashes; its SHA-256 is `aaadbc907664aaccec9c5a1c534b91fbce273ed3fa04df68d692b046c8806110`. Extract it and set `MAIA5_MODEL` to its `maia3-5m.onnx` file. The archive is excluded from the current app source and the optional research ZIP. Re-exporting 5M with different bytes is a new sensitivity run rather than an exact reproduction.

## Reading historical data labels

Raw fields named `app_default`, `current_default` and `baseline` identify **Temperature 0.5 / Top-P 0.9**. They preserve the names used when the first tests ran. The report uses numerical setting labels so it can be read without knowing the app's history. Original protocols and technical notes remain dated records of their experiments; the main report is the combined interpretation.

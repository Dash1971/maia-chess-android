# Cached diagnostic and independent audit

These local follow-up artifacts compare **Temperature 1 / TopP 0.95** with **Temperature 1 / TopP 1**, using the app's inclusive threshold-crossing convention. No app, PR, or published research files were changed. The diagnostic and cutoff calculations reuse frozen evidence from the previous study; they require no model or engine inference.

## Evaluation diagnostic

The primary cached cohort is the same 453 nonopening positions (227 White to move, 226 Black), selected from the first 30 games per previous-study matchup at plies 24/25, 40/41 and 60/61. Metrics equally weight the 18 matchup/ply strata. Both samplers use the same legal logits and Stockfish 18 depth-10 evaluations of every legal move. Intervals resample source games within matchup, pairing both sampler measurements and preserving their positions; 10,000 replicates, seed 2026100301.

| Metric | T1/P1 | T1/P.95 | Paired change, P.95 minus P1 (95% CI) |
|---|---:|---:|---:|
| Expected evaluation loss, each move capped at 1,000 cp | 80.32 cp | 74.51 cp | −5.81 cp [−6.51, −5.14] |
| Probability of evaluation loss >100 cp | 18.527% | 17.016% | −1.511 percentage points [−1.639, −1.383] |
| Probability of evaluation loss >200 cp | 8.680% | 7.628% | −1.052 percentage points [−1.174, −0.932] |
| Entropy | 1.914 bits | 1.670 bits | −0.244 bits [−0.252, −0.235] |
| Number of retained legal moves | 30.67 | 6.31 | −24.36 [−25.29, −23.45] |

P.95 removes a mean **3.409%** of full model probability mass [3.277%, 3.539%]. The removed probability mass associated with >100 cp and >200 cp evaluation loss is respectively 2.155 and 1.323 percentage points. Their ratios to all removed mass are 63.23% and 38.81%; **36.77% of removed mass has loss ≤100 cp**. These are ratios of weighted means, not means of each position's ratio. Expected capped loss improves in 419 positions, worsens in 15 and is unchanged in 19. The tail therefore cannot be described as exclusively bad moves.

The depth-14 refinement on 36 positions also favors P.95 for capped loss: −5.44 cp [−8.42, −2.80]; >100 cp probability falls by 1.242 percentage points [0.639, 1.880]. Raw uncapped loss has a CI spanning zero. This sparse subset accepts only 6,703 of 10,000 bootstrap draws because an empty stratum cannot be averaged; treat its intervals as secondary conditional checks. The full depth-10 cohort accepted all draws.

These are evaluation gaps from Stockfish's best evaluated move, not measured Elo or observed game blunder rates. Mate scores use the previous study's ±10,000 cp mapping; capped loss is a sensitivity to that mapping. The cohort comes from prior-policy games, not a representative human-position or new-policy population. Finite engine depth, same-game clustering, deduplication and sparse strata limit generalization. All means, intervals, removed-mass decompositions and position-level direction counts are in [diagnostic-summary.json](diagnostic-summary.json); exact rows are in [position-metrics.jsonl](position-metrics.jsonl).

## Cutoff semantics on cached human opening paths

The 4,581 conditional observations come from three independent 150-trajectory human opening cohorts. Metrics average observed positions, with uncertainty from whole-trajectory bootstrap. They compare population move-frequency distributions at fixed human positions, not self-play book coverage.

| Human book cohort | T1/P1 mean TV | Inclusive T1/P.95 mean TV | Upstream exclusive T1/P.95 mean TV |
|---|---:|---:|---:|
| May blitz | 0.11873 | 0.12867 | 0.13896 |
| May rapid | 0.12550 | 0.13312 | 0.14371 |
| July rapid | 0.12340 | 0.13151 | 0.14172 |

Inclusive P.95 increases TV by 0.00994, 0.00762 and 0.00811 relative to P1; all paired 95% intervals are positive. The two P.95 cutoff conventions differ at 97.9–98.5% of these positions. Switching from inclusive to upstream exclusive adds approximately 0.0102–0.0106 TV, also with positive paired intervals. Mean model mass excluded is about 4.1% inclusive and 6.6–6.7% exclusive. This is the Issue 14 ambiguity reintroduced at P.95; P1 bypasses the cutoff and preserves the same distribution semantics across these implementations, without promising bit-identical floating point execution.

At the initial position, the first four full-policy moves have cumulative mass 0.936433; adding e3 reaches 0.950528. Inclusive P.95 therefore retains e4/d4/c4/Nf3/e3, with normalized probabilities 67.065%, 26.420%, 2.716%, 2.315%, 1.483%. Upstream exclusive P.95 omits e3 and retains only the first four: 68.075%, 26.818%, 2.757%, 2.350%.

The independent opening study's approximately **94–96% retention** describes the fraction of the **previous-default-to-P1 improvement in conditional TV** retained by P.95. It does **not** describe the fraction of all possible openings, repertoire support or variety retained. P.95 removes many individually rare moves while retaining most probability mass.

Exact distributions, bootstrap intervals and input hashes are in [opening-cutoff-summary.json](opening-cutoff-summary.json), [opening-cutoff-rows.jsonl](opening-cutoff-rows.jsonl) and [manifest.json](manifest.json). Recompute locally with the existing NumPy environment:

```sh
sampling-research-20261002/strength/venv/bin/python sampling-followup-20261003/audit/cached_diagnostics.py
```

## Independent match audit

[source-audit.md](source-audit.md) records the runner, draw-rule, seed, protocol and statistics review. [first100-audit.json](first100-audit.json) confirms an inference-free independent replay of 100 durable games and 8,630 plies, using a direct translation of Dart's insufficient-material branches. The frozen audit snapshot uses game number then shard ordering, independent of results; it is not an interim strength estimate.

The full primary replay and independent statistical reconstruction also passed: **1,200 games / 107,794 plies**, 2,400 unique seeds, 600 games per policy color, zero caps and 1,200 distinct complete sequences. T1/P.95 achieved 671 wins, 100 draws and 429 losses, a 60.0833% score. The independently reconstructed 200,000-replicate color-stratified CI is [57.4583%, 62.7083%], yielding relative match Elo **+71.04 [52.22, 90.29]**. This establishes a strength advantage within this match protocol, not an absolute human Elo. See [final-audit.json](final-audit.json) and [audit_final_games.py](audit_final_games.py).

The optional claim-sensitive prefix audit also passed all 1,200 games and PGNs. Independent earliest-standard-claim replay confirms 69 truncated games, 29 changed results and 1,556 removed plies. Its score is 59.875% (654 wins / 129 draws / 417 losses), relative match Elo **+69.53 [50.74, 88.43]**, with zero caps. These sensitivity games share sampled prefixes with the primary games and must not be pooled as independent observations.

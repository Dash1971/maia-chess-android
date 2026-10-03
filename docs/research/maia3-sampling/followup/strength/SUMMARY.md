# Strength follow-up: Temperature 1.00, Top-P 0.95 versus 1.00

**Top-P 0.95 was stronger than Top-P 1.00 in this fixed 1,200-game comparison at the 1600 conditioning setting.** With Temperature 1.00 for both, Top-P 0.95 scored **60.08%**, corresponding to **+71.0 relative match Elo**, with a **95% interval of +52.2 to +90.3**. This measures performance against full sampling using the same 79M model; it does not establish an absolute human Elo rating or whole-game human likeness. Opening variety is assessed separately by the opening follow-up.

| Draw endpoint | p95 wins | Draws | p95 losses | p95 score (95% CI) | Relative Elo (95% CI) |
|---|---:|---:|---:|---|---|
| Actual app rules, primary | 671 | 100 | 429 | 60.08% (57.46–62.71%) | +71.0 (+52.2–+90.3) |
| Standard prospective claims, paired sensitivity | 654 | 129 | 417 | 59.88% (57.25–62.46%) | +69.5 (+50.7–+88.4) |

The draw endpoint convention barely changes the estimated advantage. The sensitivity uses the same independently sampled primary games, truncated at their earliest standard `claim_draw=True` endpoint; its correlated games are not pooled with primary. It truncates 69 games, changes 29 results, and removes 1,556 plies without any new inference.

| p95 color | Games | Wins | Draws | Losses | Score |
|---|---:|---:|---:|---:|---:|
| White | 600 | 361 | 44 | 195 | 63.83% |
| Black | 600 | 310 | 56 | 234 | 56.33% |

All six 200-game shards finished at the fixed target and exited successfully. Each had 100 games of each color and a distinct seed range. The primary confidence interval uses 200,000 bootstrap replicates within each color, equally weights White and Black, and transforms score using `400*log10(s/(1-s))`; the predeclared analysis seed is 7,000,000,000. Every shard's observed score favored p95, from 54.5% to 63.5%; the complete dataset is the basis of the primary inference.

All games started from the standard initial position, with no book, forced opening, search, resignation, or evaluation adjudication. Both self/opponent conditioning inputs were 1600. The current board was repeated in eight history slots, with legal-move filtering, inclusive Top-P crossing move and renormalization, using the unchanged prior portable policy. The 400-ply cap affected **zero** games; observed primary lengths ranged from 15 to 269 plies (mean 89.83). Primary endings were 1,100 checkmates, 46 stalemates, 19 insufficient-material draws, 34 actual repetition draws and one actual fifty-move draw.

Validation passed: 1,200 unique IDs, complete move sequences and PGNs; 2,400 unique game/color seeds with no overlap against prior primary, pilot or continuation seeds; exact 600/600 color balance; no illegal moves, moves after terminal, FEN/hash/result/score mismatches, PGN inconsistencies, manifest/source discrepancies, or caps. All 12 selected original-seed inference replays reproduced every move and result exactly. Preflight matched four official logits fixtures and 374 raw-FEN/outcome cases against the app's Dart `chess` 0.8.1 rules. The copied draw helper functions are AST-identical to the validated prior implementation.

For context, the previous Temperature 1.00/Top-P 0.90 study had +129.6 relative Elo under actual app draw rules (95% interval +90.0 to +171.3; 300 games), and +130.9 under standardized prospective claims. That separate smaller study is context only; these results do not establish a direct significance comparison between 0.90 and 0.95.

Compute took roughly 33 minutes for all six shards, with one ORT thread per worker. Shared-host load changed during the run: the user later ended another analysis workload, and throughput recovered. A proposed scheduling experiment was cancelled during baseline before any SIGSTOP; no match worker was paused or altered. Runtime data are wall-time measurements on a shared host, not an isolated inference benchmark.

A postprocessing-only native shutdown issue occurred after the first claim verifier had already written its passed integrity JSON: an unnecessary ONNX Runtime import for artifact hashing triggered a native `recursive_mutex` exception at interpreter shutdown. The repair replaced only the hashing-helper import in the claim verifier and analysis script with standard-library hashing. Verification and both analyses then exited cleanly. Statistical function ASTs and every numerical primary result stayed identical; originals, failed log and the repair receipt remain available. Game runner, model, policy, seeds and sample size were unchanged, and the repair required no inference.

The main artifacts are [results-primary.json](results-primary.json), [results-claim-sensitivity.json](results-claim-sensitivity.json), [integrity.json](integrity.json), [integrity-claim-sensitivity.json](integrity-claim-sensitivity.json), [replay-check.json](replay-check.json), [preflight.json](preflight.json), [postprocessing-runtime-fix.json](postprocessing-runtime-fix.json), [PROTOCOL.md](PROTOCOL.md), and [COMMANDS.md](COMMANDS.md). Raw games and per-shard manifests are in `shard0` through `shard5`; paired truncated games are in `claim-sensitivity`.

This follow-up remains **local only**. No app, repository, PR or published research was changed.

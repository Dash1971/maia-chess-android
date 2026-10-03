# Mobile Maia sampling study protocol — 2 October 2026

> Historical study protocol: “current default” below means 0.5/0.9 at the pinned application revision. The published recommendation is now 1.0/1.0; the comparisons and sample sizes are unchanged.

This folder is research material intended for the Mobile Maia repository. It does not change app defaults. The research question is whether preserving Maia3's learned move distribution improves bookless opening fidelity enough to justify a strength tradeoff.

## Named conditions

| Name | Temperature | TopP | Interpretation |
| --- | ---: | ---: | --- |
| Argmax | 0 | 0 | Most likely legal move; temperature zero bypasses TopP |
| Current default | 0.5 | 0.9 | Actual current application default |
| Full policy | 1 | 1 | Unmodified learned legal-move probabilities |

The application code confirms the baseline: **Temperature 0.5, TopP 0.9**. All results use named fields. Other parameter combinations are sensitivity analyses only.

## Pinned application and inference

Application source: `Dash1971/maia-chess-android`, commit `f659956d1c35206600cda515f462277c63e58205`, local checkout `stable25-review`. The main experiment uses the 79M model; the 5M model is a sensitivity check. Both SelfElo and OppoElo are fixed to 1600, matching actual app play. Current-board tokens repeat eight times with no reconstructed history. Black-to-move boards are vertically mirrored with colors swapped. Legal moves are masked before softmax. TopP includes the threshold-crossing move, as in the app; this differs from the upstream Python UCI implementation.

Before primary match play, compare model outputs with the app's pinned official PyTorch fixtures and test zero-temperature, zero-TopP and threshold-crossing behavior. Preserve hash, dependency versions and runtime configuration. Python RNG need not duplicate Dart's RNG sequence; it must sample the same probability distribution.

## Strength experiment

Primary fixed design: 600 games for each of the three distinct pairs, 300 of each color assignment; total 1,800 games. Each game begins from the standard position, with no book, forced opening, search, resignation or evaluation-based adjudication. Independent seeded random streams belong to each game and color. Save full move lists, PGNs, seed, terminal reason and final FEN. Terminal chess rules include claimable draws; cap 400 plies and explicitly identify cap draws. A 5M round robin of 200 games per pair (600 total) is supplementary. Two additional 79M comparisons each play 300 games, balanced by color, against full policy: Temperature 0.5 / TopP 1 and Temperature 1 / TopP 0.9. These isolate one control at a time relative to full policy and were specified before viewing their outcomes. Each study uses distinct per-game/color streams internally. The 79M single-control arms use a separate seed range from the primary study. The 5M sensitivity deliberately reuses primary seed numbers across model sizes; the model results are not pooled.

Report wins/draws/losses, scores by color, direct pairwise Elo differences `400 log10(score/(1-score))`, and color-stratified bootstrap uncertainty. Direct matchup differences need not fit one transitive Elo scale. Count exact duplicate games and document deterministic behavior. No claim that a conditioning label of 1600 is an achieved Lichess rating, and no translation from engine-only results to an absolute human rating.

Do not stop at a favorable result. Intermediate observations are progress diagnostics; conclusions use the prespecified fixed final sample. If cap draws or draw rules materially affect the estimate, report sensitivity rather than silently treating them as ordinary decisive information. A separate app-rule sensitivity continues games stopped only because a draw could be claimed by announcing the next move. It preserves each played prefix and uses fresh independent seeded continuation streams until the app-style actual repetition or halfmove condition is met. This tests whether the legal-claim convention changes the recommendation.

## Opening experiment

Compare conditional move distributions, not only top-move match accuracy: total variation, Jensen–Shannon divergence, support coverage and entropy. TopP can assign zero probability to human moves, so unsmoothed cross-entropy can be infinite; do not hide this with arbitrary smoothing. Include reach-weighted and equally weighted views where appropriate, and analyze first-move and multi-ply repertoire diversity.

The live Lichess opening explorer required authentication on retrieval. Existing user-generated Lichess full-month Polyglot books provide a directly relevant comparator, with builder and sidecar metadata audited. The May 2026 blitz and rapid books and July 2026 rapid book are compared separately. These are snapshots and filtered cohorts, not a claim to have downloaded the entire live explorer. A separately sampled official Lichess game dataset provides robustness against book construction effects.

Generate bookless Maia opening rollouts for each condition; compare their distributions and coverage with the book distributions. Archive source hashes, filtering rules, dates, sample sizes, weights, seeds and per-position probabilities. Opening familiarity and strength are separate outcomes.

## Secondary diagnostics

Use the same nonopening positions for different Temperature/TopP values, with a fixed-budget Stockfish evaluation of every legal move. Report expected evaluation loss, severe-error probability and entropy. This isolates mechanical changes in risk and concentration without claiming that centipawn loss converts into Elo. These diagnostics are secondary to the actual match results.

## Sources and conclusions

Read the Chessformer paper, official and Dash Maia3 repositories, both local stacks, the prior benchmark, Maia website and public discussion. Discord and bot-operator claims are testimony, not measured calibration. Cite message links and dates; do not publish unrelated chat content. Public source code defaults are not proof of a deployed bot's configuration.

The recommendation must follow the observed strength/fidelity tradeoff, including uncertainty and limitations. Produce a repository-ready report and a concise proposed app note. Publishing the report and changing app settings remain separate from this research deliverable.

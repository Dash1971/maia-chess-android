# Final independent opening-section audit

Audited 2 October 2026, against `REPORT.md`, `openings.md`, `openings/summary.json`, `actual-two-ply.json`, `exact-two-ply.json`, the cached first-move probabilities, cutoff results and archived builder/analyzer source. No inference or new experiment was run. Primary strength and recommendation placeholders were still present in the audited report.

No substantive numerical or interpretive defect was found. One small wording refinement is justified by the builder: the book threshold is **25 distinct games visiting a position**, rather than 25 move observations. `collect_game` deduplicates positions within each game for the position threshold, although it counts repeated move observations for move frequencies. In REPORT's coverage paragraph, replace "fewer than 25 recorded observations" with "fewer than 25 recorded games" (or "positions visited in fewer than 25 games"). This does not change any results.

Checked facts:

- The 450 human-book trajectories yield 4581 covered-position observations. Every reported retained-depth TV rounds correctly; the 58–60% relative reduction and May blitz paired interval are correct. Full policy is closest in all 12 listed book/depth-band comparisons, with low late coverage explicitly acknowledged.
- Exact two-ply support is 1/6/400 sequences for argmax/current/full. The six current-default sequences and the three replies after 1.e4 are correct. The report distinguishes this exhaustive support from finite-sample diversity.
- Actual ordered-prefix comparisons have 4087 blitz, 1355 rapid and 2704 September games, with the reported TV values rounding correctly. The independent sample includes 20763 games overall. September is a post-training-date sensitivity; the other 2025 sampled months overlap the reported training window, so these should remain "separately sampled" data rather than a universally held-out test.
- Free-play samples contain 2000 sequences per stochastic setting and one deterministic line. The four reported repertoire-TV rows round correctly. Full policy is closest in all 28 stored prefix/family/ECO comparisons across the four cohorts, among the three requested settings. Prefix diversity 43/711 at 4 plies and 1631/1996 at 16 plies is correct. At 16 plies, 1999 baseline and 1996 full sequences survive; the report already states that late comparisons condition on reaching the depth.
- Book membership at ply 15 is 63.7% current/default and 5.4% full, with denominator 2000 generated sequences. Conditional human-book path coverage at that ply is 6.7%, 2.7%, 5.3% across the three references. These are different sampling schemes. The report correctly separates membership from frequency fidelity and does not interpret book departure as weak or inhuman play.
- Rollout TV uses the same human-defined partition for every policy, pooling categories below 0.5% observed frequency into OTHER. It is a coarsened empirical distance, not the complete population or line-by-line repertoire distance. The preserved analyzer independently resamples source row groups and model games. Finite-sample TV bias is documented in `openings.md`; bootstrap intervals do not remove it.
- Self-play uses the same setting for both colors. The report explicitly explains that varied human opponents add variation and that conditional human-path tests separately check replies to varied positions. It avoids claiming that one deterministic self-play line means one line against people, or that population-frequency similarity proves an individual human style.
- The new initial-position issue 14 example is correct. From the saved full probabilities, T=0.5 gives e4 mass 0.862483 and d4 mass 0.133853, with cumulative top-two mass 0.996336. At P=0.9 the upstream exclusion rule retains only e4; the app includes d4 and renormalizes to 86.5655%/13.4345%. TopP 1 eliminates this boundary disagreement independently of temperature.

Scope remains sound: 1/1 preserves the learned legal-move policy and is the closest of the requested settings in the reported opening comparisons, not a guaranteed Elo 1600 calibration or a global temperature optimum. T=0.9/P=1 has slightly smaller conditional TV on the rapid references; the report acknowledges the nearby-cohort qualification. The single-control match Elo differences should stay separate and must not be added into a universal Elo formula.

Audited input hashes:

- `REPORT.md`: `6b24c91533e6db931c71728dfa641440ce7d18877ef21b2689924ceab7379e06`
- `openings.md`: `05e912c476a64feef6a59f3f75b7a521ee0e9f9b5ae52ebe9bb03e8769916fcf`
- `openings/summary.json`: `151003e8e224be97bb0ebeebbc56f1b3566a2b184e9938d024c23a9fdd825ec4`
- `openings/actual-two-ply.json`: `3083c72b26863b574978875b4a2f298be3292f3427f07394f2963132b8444f15`
- `openings/exact-two-ply.json`: `c9e1d2d96397450388a6b7cb30b7f2e67d568078efea803b1809fedff69c794e`


## Subsequent publication reconciliation

After all runs completed, the publication assembly independently recounted wins, draws and losses from the raw JSONL for all six final study/sensitivity datasets, checked unique IDs and balanced colors within each study, and recalculated scores and direct logistic Elo differences. Every value matched the saved summaries. See `../publication-validation.json`. The three sensitivity datasets preserve primary prefixes and are not pooled as additional independent games.

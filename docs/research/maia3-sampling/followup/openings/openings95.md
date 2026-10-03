# Temperature 1 / TopP 0.95 versus full sampling — openings follow-up

This is a local-only follow-up at Maia3-79M rating inputs **1600/1600**. It reuses the original fixed human references and historical full-policy/default samples; **no new human data were collected**. The requested comparison is inclusive **TopP 0.95 versus TopP 1.0**, both at Temperature 1.0. The previous Temperature 0.5 / TopP 0.9 setting is a reference for the improvement retained, rather than a new tested condition.

## Paired fixed-position comparison

Across the same 450 human-book paths and 4,581 covered-position observations, 0.95 modestly worsens average conditional fit. It retains about **94–96% of the previous-default-to-full mean-TV improvement**. This ratio describes a distance improvement on fixed covered positions; it is **not a percentage of repertoire breadth retained**.

| Fixed reference | Full TV | P0.95 TV | Paired P0.95 minus full [95% CI] | Prior improvement retained [95% CI] |
|---|---:|---:|---:|---:|
| lichess_1600_blitz_2026-05 | 0.1187 | 0.1287 | +0.0099 [0.0093, 0.0106] | 94.44% [94.14, 94.76] |
| lichess_1600_rapid_2026-05 | 0.1255 | 0.1331 | +0.0076 [0.0069, 0.0083] | 95.52% [95.14, 95.88] |
| lichess_1600_rapid_2026-07 | 0.1234 | 0.1315 | +0.0081 [0.0073, 0.0089] | 95.16% [94.80, 95.55] |

The cutoff removes approximately 4.09–4.11% of the model probability mass on average, while excluding 3.80–3.96% of the recorded human move mass. It reduces average legal-move support from approximately 29 moves to 7. TV, JSD, entropy, excluded mass, support and paired intervals are preserved in [conditional-summary95.json](conditional-summary95.json), including planned all-covered 0–15-ply results and depth subsets. The high-coverage 0–7 subset is a sensitivity; late coverage stays low because references are unchanged. Human-book paths stop on the first missing book position.

## Exact first moves and replies

The 0.95 initial policy permits exactly **e4, d4, c4, Nf3 and e3**. Their probabilities are 67.065%, 26.420%, 2.716%, 2.315% and 1.483%, respectively. Full sampling supports all 20 legal first moves. The exact two-ply support shrinks from **400 to 45 sequences**, whereas the previous default supported six. These support counts include sequences with very small probability and must not be confused with observed diversity in 2,000 samples.

| Reference | Full first-move TV | P0.95 first-move TV | Full two-ply TV | P0.95 two-ply TV |
|---|---:|---:|---:|---:|
| lichess_1600_blitz_2026-05 | 0.0226 | 0.0637 | 0.1054 | 0.1510 |
| lichess_1600_rapid_2026-05 | 0.0208 | 0.0414 | 0.1106 | 0.1196 |
| lichess_1600_rapid_2026-07 | 0.0207 | 0.0448 | 0.1078 | 0.1192 |

Black has eight supported replies after e4 and nine after d4 under 0.95, versus 20 in each position under full sampling. [exact-policy95.json](exact-policy95.json) preserves complete move distributions, human references and TV/JSD for both reply positions. Two-ply probabilities were derived by truncating the first-move policy and each conditional reply policy separately, then multiplying; they were not obtained by truncating the already joint sequence distribution. The book transitions aggregate transpositions, so this exact induced reference is distinct from actual ordered game frequencies.

## Actual human ordered sequences

| Original public human cohort | Games | Full two-ply TV | P0.95 two-ply TV | P0.95 minus full [95% CI] |
|---|---:|---:|---:|---:|
| mean1550-1650_blitz | 4087 | 0.1284 | 0.1620 | +0.0336 [+0.0241, +0.0362] |
| mean1550-1650_rapid | 1355 | 0.1481 | 0.1287 | -0.0193 [-0.0336, +0.0005] |
| september2025_mean1500-1700 | 2704 | 0.1265 | 0.1552 | +0.0287 [+0.0176, +0.0346] |

Full sampling fits blitz and the September sensitivity better. The matched rapid sample gives a point improvement for 0.95, but its paired interval includes zero. These are exact model probabilities against the unchanged public-game sample, with 2,000 human source-row-group bootstrap replicates and no model Monte Carlo. The January/April/July 2025 data overlap the reported training period; September is a post-training sensitivity. [actual-two-ply95.json](actual-two-ply95.json) preserves all frequencies and intervals.

## New 16-ply self-play sequences

The fixed run completed **2,000 new self-play openings**, with both colors using Temperature 1 / TopP 0.95 and no book choosing or forcing a model move. The old full/default samples each contain exactly 2,000 sequences; hashes and model provenance match the launch manifest and historical run. They are **historical, unpaired game samples**, rather than new human data or paired trajectories.

A shared human source-block resample and independent model-sample resamples estimate TV0.95−TV1.0. The table uses the original human-defined ≥0.5% bins plus OTHER. These are **marginal, uncorrected 95% intervals across multiple secondary cohorts and observables**; isolated interval exclusions do not establish one universal significant repertoire ranking. Plug-in TV has positive finite-sample bias, pooling makes it a lower bound on complete empirical TV, and the bootstrap does not remove that bias.

| Original human cohort | Observable | Full TV | P0.95 TV | P0.95 minus full [95% CI] |
|---|---|---:|---:|---:|
| Blitz 1550–1650 | 4-ply prefix | 0.1577 | 0.1268 | -0.0309 [-0.0540, -0.0073] |
| Blitz 1550–1650 | 8-ply family | 0.2042 | 0.2422 | +0.0380 [+0.0114, +0.0678] |
| Blitz 1550–1650 | 12-ply family | 0.1950 | 0.2228 | +0.0278 [+0.0021, +0.0610] |
| Blitz 1550–1650 | 16-ply family | 0.1943 | 0.2230 | +0.0287 [+0.0041, +0.0618] |
| Rapid 1550–1650 | 4-ply prefix | 0.2058 | 0.1717 | -0.0341 [-0.0567, -0.0076] |
| Rapid 1550–1650 | 8-ply family | 0.2225 | 0.2378 | +0.0153 [-0.0167, +0.0462] |
| Rapid 1550–1650 | 12-ply family | 0.2198 | 0.2256 | +0.0058 [-0.0327, +0.0374] |
| Rapid 1550–1650 | 16-ply family | 0.2173 | 0.2240 | +0.0067 [-0.0274, +0.0353] |
| September, both speeds | 4-ply prefix | 0.1675 | 0.1432 | -0.0244 [-0.0478, -0.0002] |
| September, both speeds | 8-ply family | 0.1964 | 0.2468 | +0.0503 [+0.0173, +0.0751] |
| September, both speeds | 12-ply family | 0.1895 | 0.2292 | +0.0397 [+0.0045, +0.0658] |
| September, both speeds | 16-ply family | 0.1888 | 0.2288 | +0.0399 [+0.0069, +0.0670] |

In plain language, 0.95 better matches the shares of these **common four-ply bins**, while full sampling generates more families and better matches their distribution in blitz and September. This does not contradict the exact two-ply result: the four-ply common bins plus OTHER are **not a refinement** of the complete two-ply categories. They discard different information, and the four-ply estimate also uses finite model samples. TV contraction under a common partition does not imply a common ranking across these different measurements.

| Setting | Observed prefixes at 2 / 4 / 8 / 12 / 16 plies | Families at 16 plies | Effective families at 16 plies | 16-ply survivors |
|---|---:|---:|---:|---:|
| Previous T0.5/P0.9 | 6 / 43 / 460 / 1166 / 1631 | 28 | 8.34 | 1999 / 2000 |
| T1/P0.95 | 42 / 470 / 1800 / 1987 / 1995 | 67 | 27.17 | 1995 / 2000 |
| T1/P1 | 98 / 711 / 1889 / 1995 / 1996 | 85 | 34.28 | 1996 / 2000 |

Effective family count is 2 raised to the entropy of the observed label distribution, accounting for how unevenly families occur. At 16 plies, 0.95 produces 67 observed families and 27.17 effective families, versus full sampling’s 85 and 34.28. Its common labels include Queen’s Pawn Game (13.0%), Scandinavian Defense (9.2%) and Sicilian Defense (8.4%); the corresponding full-sampling shares are 12.2%, 8.3% and 8.3%. Labels carry forward the latest recognized opening position and do not measure move quality. Top-label counts at 8/12/16 plies are in [family-diversity95.json](family-diversity95.json).

Per-ply book membership after 7 / 15 plies is 90.1% / 10.0% for 0.95 versus 75.9% / 5.4% for full sampling. This records the position present at each ply, allows later re-entry, and counts games ended earlier as absent. It measures common-position membership, not repertoire fidelity. Human-book path coverage uses a different stop-at-first-missing rule.

The run used 18,402 inference calls and 13,577 cache hits over 27.19 minutes on one inference thread. All **31,979 new plies** were legally replayed and their stored label positions checked. [run.json](run.json), [summary95.json](summary95.json), [rollout-validation95.json](rollout-validation95.json) and [input-validation95.json](input-validation95.json) preserve completion, counts, seeds, source/model hashes, metrics and intervals.

## Reproduction

Use the original strength-study Python environment or install [requirements.txt](requirements.txt). All commands accept explicit original-study and model paths and write only to this directory. Keep the original fixture data unchanged. The new seed range is 7,000,000,000 + game index.

```sh
python conditional.py --source-study /path/to/original-study
python rollout.py --model /path/to/maia3-79m.onnx --source-study /path/to/original-study
python analyze.py --source-study /path/to/original-study
python validate_policy.py --model /path/to/maia3-79m.onnx
python diversity.py --source-study /path/to/original-study
python validate_labels.py --source-study /path/to/original-study
```

[PROTOCOL.md](PROTOCOL.md) records the fixed sample size, cutoff, reference reuse, cohorts, bootstrap method and completion checks. [run-start.json](run-start.json) records source/model/helper hashes before rollout sampling. The final run metadata and legality checks confirm completion. [policy-validation95.json](policy-validation95.json) also verifies all conditional distributions and six fresh inference inputs, agreeing with reconstructed first/two-ply probabilities within 1.12×10⁻¹⁶.

All 95,959 stored labels across the three final 2,000-game model samples were rederived from the pinned TSV with the same carry-forward semantics; all 2,000 new seeds and five-move initial support checks passed. See [label-seed-validation95.json](label-seed-validation95.json). Reduced-fixture reanalysis without model, books, opening TSV, raw Parquet or HTTP cache reproduced 9,832 numerical values exactly (excluding runtime), as well as four byte-identical conditional outputs; see [bookfree-reproduction95.json](bookfree-reproduction95.json). [source-hashes.json](source-hashes.json) preserves the final script fingerprints.

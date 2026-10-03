# Maia3 opening distribution experiment — 2 October 2026

The 79M model at self/opponent rating inputs **1600/1600** produces opening distributions much closer to the selected Lichess reference distributions with **Temperature=1, TopP=1** than with the app's previous **Temperature=0.5, TopP=0.9** or deterministic **0/0**. This is a distribution comparison, not an estimate of playing strength. Full sampling preserves the model's probability distribution; sharpened or truncated sampling changes that distribution substantially.

## Primary references and inference

The user's completed full-month books provide the primary population references:

| Reference | Accepted games | Rating filter | Additional filters |
|---|---:|---|---|
| May 2026 blitz | 4,034,736 | floored mean of the two ratings 1550–1650 inclusive | rating difference ≤200; at least 6 plies |
| May 2026 rapid | 1,427,623 | floored mean 1550–1650 inclusive | same |
| July 2026 rapid | 2,912,431 | floored mean 1500–1700 inclusive | same |

Book sidecars declare complete monthly builds from 90,887,615 May and 89,288,421 July source games. That provenance is preserved; the original monthly compressed PGNs were not reprocessed in this study. The archived builder at commit `8776f3639a549d7becab232a6c8cd47ac0c982f3` retains every observed move at a position visited by at least 25 games, using `max(1, round(move_count / largest_move_count_at_position * 65535))`. Normalizing these weights recovers the conditional empirical distribution approximately, with small integer quantization. The books aggregate by position, including transpositions and repeated visits; they do not preserve complete game paths or raw per-position sample counts. The builder does not explicitly exclude BOT titles; the independent game sample does.

No book probabilities influence a model move. Inference uses the app's repeated-current-board encoding, Black's vertical board/move mirror, legal-move masking, fixed 1600/1600 inputs, and the app's inclusive crossing-move nucleus rule. The exact ONNX SHA-256 is `3454b03ae78baa64a87b345fdb1a457265d912caec531039b074f07eda0d8010`. ONNX Runtime CPU inference uses one intra-op and one inter-op thread. Python/chess/runtime package versions are locked in [requirements-lock.txt](openings/requirements-lock.txt).

## Distribution fidelity on human opening positions

We sampled 150 independent trajectories from each human book using seed `20261002 + book_index`, up to 16 plies, stopping when a book had no position entry. Every covered position contributes its complete human and model move distributions. This produced **4,581 position observations**, **2,341 distinct full FENs**, and **2,298 distinct model inference inputs**. FENs can differ in clocks, rights or other state absent from the model encoder. Common positions recur naturally because trajectories follow human reference probabilities; the evaluation is not an unweighted list of favorite opening positions.

Total variation (TV) is half the sum of absolute differences between move probabilities; 0 is identical and 1 means disjoint distributions. Jensen–Shannon divergence (JSD) is reported in bits. Intervals resample whole sampled trajectories, preserving repeated positions within a trajectory, with 2,000 bootstrap replicates. They describe uncertainty from our sampled reference trajectories, not uncertainty in the latent population policy, model training or game-strength Elo.

The planned conditional comparison covers all retained observations at **0–15 plies**. The early **0–7 ply** subset below is a sensitivity analysis with the highest coverage; it has the same ranking:

| Human reference | Deterministic TV | Previous default TV | Full sampling TV |
|---|---:|---:|---:|
| May blitz | 0.5044 [0.4934, 0.5157] | 0.3064 [0.3006, 0.3121] | **0.1162 [0.1125, 0.1198]** |
| May rapid | 0.4987 [0.4872, 0.5107] | 0.2950 [0.2885, 0.3013] | **0.1234 [0.1193, 0.1275]** |
| July rapid | 0.4933 [0.4802, 0.5056] | 0.2929 [0.2855, 0.2996] | **0.1199 [0.1155, 0.1238]** |

Across all retained depths, May blitz TV/JSD are 0.4986/0.3290 for deterministic, 0.2975/0.1551 for the default, and 0.1187/0.0281 for full sampling. The default gives zero probability to about 23% of the human move mass on average; deterministic play excludes about 50%. Full sampling excludes no legal human move from support, although its probabilities are still imperfect. The paired full-minus-default TV difference is −0.1788 [−0.1846, −0.1732] in May blitz, −0.1701 [−0.1759, −0.1644] in May rapid, and −0.1677 [−0.1735, −0.1615] in July rapid.

**Deep coverage is limited.** At position ply 7, 85.3%, 75.3% and 80.0% of sampled trajectories remain covered in the three references; at ply 15 those fractions fall to 6.7%, 2.7% and 5.3%. The overall retained-depth means therefore emphasize earlier and more popular positions. The late covered subset must not be interpreted as all human opening positions or all generated model positions. [conditional-summary.json](openings/conditional-summary.json) records coverage and depth-specific results; [conditional.json](openings/conditional.json) preserves every full distribution.

## Exact first-two-ply repertoire

We also enumerate the model's entire two-ply sequence distribution from the initial position and compare it with the distribution induced by the human book's transitions. All 20 legal first moves and their Black replies are evaluated. These results are exact for those normalized book transitions and model probabilities, without Monte Carlo noise. Book counts aggregate positions, so this is an induced repertoire reference; the independent game sample below directly checks ordered sequence frequencies.

| Reference | Deterministic TV / JSD | Previous default TV / JSD | Full sampling TV / JSD |
|---|---:|---:|---:|
| May blitz | 0.7505 / 0.5494 | 0.5008 / 0.3073 | **0.1054 / 0.0115** |
| May rapid | 0.6744 / 0.4669 | 0.4404 / 0.2488 | **0.1106 / 0.0159** |
| July rapid | 0.6752 / 0.4678 | 0.4401 / 0.2497 | **0.1079 / 0.0148** |

[exact-two-ply.json](openings/exact-two-ply.json) preserves all sequence probabilities. Deterministic self-play repeats one line. The previous default has exactly **six** positive-probability two-ply sequences, while full sampling has **400**. These are exhaustive supports of the enumerated model distribution, rather than finite-sample diversity estimates. The previous default's sharpened probabilities strongly overrepresent its favorite lines.

## Cutoff and model-size sensitivity

The pinned upstream Maia3 UCI implementation keeps sorted probabilities whose cumulative mass is **at most** TopP, always retaining the first move. The app includes the move that **crosses** TopP. Reconstructing upstream's exclusive cutoff at Temperature=0.5, TopP=0.9 changes 82.3–84.5% of the sampled position observations. The average TV between inclusive and exclusive sampler distributions is 0.109–0.113. Against the same human references, the exclusive rule **increases** TV by 0.096–0.100 and JSD by 0.086–0.088 bits on average. Thus the app's crossing-move rule materially softens the cutoff; it does not remove the distribution distortion of the previous settings. Temperature=1, TopP=1 bypasses this cutoff ambiguity. See [cutoff-summary.json](openings/cutoff-summary.json), [raw sensitivity](openings/cutoff-sensitivity.json), and [pinned upstream code](https://github.com/CSSLab/maia3/blob/1e13597c42d4858b7cfd7cfdae01e297263364b2/maia3/uci.py#L163-L184). The upstream discussion is [CSSLab/maia3 issue 14](https://github.com/CSSLab/maia3/issues/14).

Changing one parameter at a time helps explain the difference. For May blitz, TV is 0.2975 at Temperature=0.5/TopP=0.9, 0.2594 at Temperature=0.5/TopP=1, 0.1456 at Temperature=1/TopP=0.9, and 0.1187 at 1/1. Temperature sharpening is the larger contribution in this sample; truncation adds further distortion. The cached 4×4 grid does not establish a universally optimal temperature: Temperature=0.9/TopP=1 slightly improves TV on the rapid references, while 1/1 wins on blitz. See [grid-sensitivity.json](openings/grid-sensitivity.json).

On precisely the same positions, the smaller 5M model also favors full sampling. Retained-depth TV for deterministic/default/full is 0.5012/0.2913/**0.1368** on May blitz, 0.5057/0.2859/**0.1483** on May rapid, and 0.5059/0.2861/**0.1480** on July rapid. This supports the main ranking across model sizes, while absolute fit and the size effect depend on sampling. See [summary-5m.json](openings/summary-5m.json) and [conditional-5m.json](openings/conditional-5m.json).

## Independent game sample and free rollouts

The live explorer returned HTTP 401. Authentication was not bypassed. The fallback uses the [official public Lichess standard-games dataset](https://huggingface.co/datasets/Lichess/standard-chess-games), pinned to revision `de4e636eddf568a9394cc01fb0b9e1da04a6babf`. We deterministically selected one shard per January, April, July and September 2025, then 20 seeded random row groups plus the three initially sampled groups per shard: **92 distinct row groups**. Footer and contiguous row-group byte ranges, HTTP response headers, SHA-256 hashes and the precise selection manifest are archived. Only about 86 MB of ranges were downloaded from the four approximately 1 GB shards.

After rated blitz/rapid, valid rating, mean 1400–1799, rating difference ≤200, non-BOT-title and ≥6-ply filters, the independent sample contains **20,763 games**, with zero opening-prefix parse errors. Within the book-matched floored mean 1550–1650 cohort there are **4,087 blitz** and **1,355 rapid** games; mean 1500–1700 gives 10,698 games combined. This is independently sampled data, **not a general held-out test**: the January/April/July months overlap the reported training window. September is reported separately as a post-training sensitivity.

Actual ordered first-two-ply frequencies independently confirm the main ranking when compared with the **exact model sequence probabilities**, avoiding model Monte Carlo noise:

| Game sample | Games | Deterministic TV | Previous default TV | Full sampling TV |
|---|---:|---:|---:|---:|
| 2025 blitz, mean 1550–1650 | 4,087 | 0.7345 | 0.4957 | **0.1284** |
| 2025 rapid, mean 1550–1650 | 1,355 | 0.6753 | 0.4398 | **0.1481** |
| September 2025, mean 1500–1700, both speeds | 2,704 | 0.7319 | 0.4930 | **0.1265** |

For September, the paired full-minus-default TV difference is −0.3665 [−0.3700, −0.3412], resampling the human source row groups with 2,000 replicates. These complete two-ply distributions do not pool rare categories. [actual-two-ply.json](openings/actual-two-ply.json) preserves probabilities, metrics and intervals.

The free rollout experiment uses no opening book and samples both colors from Maia3 at 1600/1600 with the **same tested setting on both sides** (self-play opening sequences), 2,000 openings per stochastic primary setting to 16 plies, with one exact deterministic line. Lichess opening labels are assigned by the latest recognized opening position, using the pinned local TSV. Ordered-prefix comparisons at plies 1, 2 and 4 and opening-family comparisons at plies 8, 12 and 16 use the same observed human bins with probability ≥0.5%, pooling the remaining categories into OTHER. These coarsened TV values are lower bounds on complete **empirical** repertoire TV. Confidence intervals resample human source row groups and independently resample model rollout games, with 1,000 bootstrap replicates. The artificial `1e-12` floor in the archived optional surprisal field is not used for the main results.

Plug-in repertoire TV has positive finite-sample bias, especially with sparse categories. Equal model sample sizes and pooling rare categories reduce that problem; the bootstrap intervals do not themselves remove it. Prefix diversity also depends on sample size. Later-depth comparisons condition on reaching that depth; survivor counts are preserved. Opening-family labels describe the last recognized opening and do not measure move quality. Model book coverage measures **per-ply membership**: the proportion whose position after that many plies is present in the filtered book, counting games that ended earlier as absent. A model trajectory may leave and later re-enter the book. Human-book path collection instead stops at its first position absent from the book. High membership is neither distribution fidelity nor evidence of greater human likeness; most sampled human-book paths stop before 16 plies.

The completed self-play rollout comparisons preserve the same ranking. The table gives coarsened TV, with 95% bootstrap intervals for the stochastic settings. Conditional next-move comparisons above are the more direct test of responses along varied human openings; the one-line deterministic self-play result does not imply one line against varied human opponents.

| Human cohort | Observable | Deterministic | Previous default [95% CI] | Full sampling [95% CI] |
|---|---|---:|---:|---:|
| Blitz 1550–1650 | 4-ply prefix | 0.8938 | 0.5043 [0.4823, 0.5286] | **0.1577 [0.1393, 0.1859]** |
| Blitz 1550–1650 | 8-ply family | 0.9564 | 0.6081 [0.5870, 0.6281] | **0.2042 [0.1887, 0.2370]** |
| Blitz 1550–1650 | 12-ply family | 0.9520 | 0.5972 [0.5763, 0.6185] | **0.1950 [0.1795, 0.2290]** |
| Blitz 1550–1650 | 16-ply family | 0.9523 | 0.5966 [0.5767, 0.6176] | **0.1943 [0.1790, 0.2273]** |
| Rapid 1550–1650 | 4-ply prefix | 0.8620 | 0.5985 [0.5711, 0.6264] | **0.2058 [0.1838, 0.2438]** |
| Rapid 1550–1650 | 8-ply family | 0.9349 | 0.5582 [0.5372, 0.5867] | **0.2225 [0.2085, 0.2643]** |
| Rapid 1550–1650 | 12-ply family | 0.9262 | 0.5508 [0.5301, 0.5818] | **0.2198 [0.2028, 0.2604]** |
| Rapid 1550–1650 | 16-ply family | 0.9261 | 0.5493 [0.5325, 0.5795] | **0.2173 [0.2007, 0.2579]** |

The September post-training sensitivity also favors full sampling: four-ply-prefix TV is 0.8894/0.6015/**0.1675** for deterministic/default/full; 16-ply-family TV is 0.9456/0.5885/**0.1888**. The full-sampling intervals are [0.1492, 0.1931] and [0.1793, 0.2272], respectively.

| Self-play setting | Distinct sampled prefixes at 2 / 4 / 8 / 12 / 16 plies | Effective families at 12 plies | Games reaching 16 plies | Positions present in book after 7 / 15 plies |
|---|---:|---:|---:|---:|
| Deterministic | 1 / 1 / 1 / 1 / 1 | 1.00 | 1 / 1 | 100.0% / 100.0% |
| Previous default | 6 / 43 / 460 / 1166 / 1631 | 8.33 | 1999 / 2000 | 100.0% / 63.7% |
| Full sampling | 98 / 711 / 1889 / 1995 / 1996 | 34.33 | 1996 / 2000 | 75.8% / 5.4% |

The default still produces substantial deeper sequence diversity, while concentrating its first two plies onto six possible sequences. Full sampling observed 98 two-ply sequences out of its 400-sequence positive support. The much lower full-sampling book membership at 15 plies should not be interpreted as poorer fidelity. The sampled human-book paths also have low late coverage, although their stop-at-first-missing rule differs from model per-ply membership. Full sampling improves the measured human repertoire distributions while visiting more rare positions.

The run used 25,142 unique inference calls and 38,854 cache hits over 46.0 minutes on one CPU thread. [run.json](openings/run.json), [rollouts.json](openings/rollouts.json), and the complete [summary.json](openings/summary.json) preserve seeds, model hash, survivor counts, frequencies, metrics and intervals. All 63,996 recorded rollout plies were legally replayed and their stored label positions checked; see [rollout-validation.json](openings/rollout-validation.json).

## Reproduction

The scripts are in [openings/](openings/). Create a Python 3.12 virtual environment and install [requirements-lock.txt](openings/requirements-lock.txt). The small publication bundle can reproduce inference and metrics from the archived FEN/human-frequency fixtures **without** the full source books:

```sh
python openings/recompute_fixture.py --model /path/to/maia3-79m.onnx --expected-sha256 3454b03ae78baa64a87b345fdb1a457265d912caec531039b074f07eda0d8010
```

The fixture verifier was smoke-checked on 25 conditional observations and all two-ply model inputs: 40 model calls, zero probability difference from the archived fixture. Omit `--limit` to recompute the complete selection. Human reference construction remains an independently auditable upstream step; the fixture verifier holds that reference fixed. The complete analysis was also regenerated in a reduced directory without book binaries, Parquet groups, HTTP range cache or the opening TSV: 6,871 numeric leaves agreed within 2.14×10⁻¹⁴. See [bookless-reproduction.json](openings/bookless-reproduction.json). The executed analysis/generator source hashes are preserved in [executed-source-hashes.json](openings/executed-source-hashes.json).

Full reconstruction of sampled positions from the source books additionally requires the three `.bin` files matching the hashes in [conditional-run.json](openings/conditional-run.json), or rebuilding them from the corresponding official monthly PGNs with the preserved builder and sidecar parameters. The publication bundle need not include those books or full monthly PGNs. The preserved book sidecars, builder source and dataset manifest document the reference construction.

```sh
python openings/collect.py
python openings/experiment.py --model /path/to/maia3-79m.onnx --rollouts 2000 --plies 16
python openings/exact_two_ply.py --model /path/to/maia3-79m.onnx
python openings/model_sensitivity.py --model /path/to/maia3-5m.onnx
python openings/grid_sensitivity.py
python openings/analyze.py
python openings/sample_two_ply.py
```

`grid_sensitivity.py` requires only `conditional.json`: it transforms the archived full-sampling probabilities and performs no model inference, so no model path is needed. Although it imports shared constants through `experiment.py`, it never opens `MODEL79`. `collect.py` reuses the shipped source selection manifest and any available range cache. `analyze.py` uses the filtered Parquet games when present and otherwise reuses the archived `human-sample.json`, so the publication bundle can reproduce the analysis without the range cache or another inference run. [sample_two_ply.py](openings/sample_two_ply.py) also runs directly from `human-sample.json` and `exact-two-ply.json`. The scripts use the audited inference helper [mobile_policy.py](strength/mobile_policy.py). The model sampler, references and seed assignments are preserved in the output files; no production app source was changed.

# Maia-3 sampling: literature and implementation evidence

Research date: 2 October 2026 (Asia/Tokyo). This is a source review supporting the accompanying experiments, not a match-strength result. Throughout this document pairs are **(Temperature, TopP)**. The confirmed comparison is `(0, 0)`, the current Mobile Maia baseline `(0.5, 0.9)`, and `(1, 1)`.

## What the evidence establishes

`Temperature=1, TopP=1` preserves Maia-3's learned legal-move distribution. This gives a principled starting point when the purpose is to reproduce a population's choices, including its opening variety. It does not establish that the model exactly matches the Lichess opening explorer, or that its realized playing strength equals its 1600 conditioning input. Those questions require empirical measurements.

There is first-person public evidence that the operator of the community `maia3-79m_*` Lichess bots uses Temperature 1. The accessible Reddit statement does not specify TopP. An authenticated Discord review may provide stronger configuration evidence; this document does not claim to have independently accessed Discord.

## 1. Pinned implementation sources

| Repository | Inspected revision | Important finding |
|---|---|---|
| [Dash1971/maia3](https://github.com/Dash1971/maia3/tree/1e13597c42d4858b7cfd7cfdae01e297263364b2) | `1e13597c42d4858b7cfd7cfdae01e297263364b2` | Temperature precedes top-p; threshold-crossing move is excluded. |
| [CSSLab/maia3](https://github.com/CSSLab/maia3/tree/1e13597c42d4858b7cfd7cfdae01e297263364b2) | Same revision | User fork and official repository were identical at the inspected heads. |
| [Dash1971/maia3-local-stack](https://github.com/Dash1971/maia3-local-stack/tree/0925e2245e37edf090f57fccca9666ba0ca315f5) | `0925e2245e37edf090f57fccca9666ba0ca315f5` | Wrapper chooses weighted Polyglot book moves before asking Maia. |
| [Dash1971/maia2-local-stack](https://github.com/Dash1971/maia2-local-stack/tree/309c2dc7e6ac3f555295a5953b97f3641d9b3f4d) | `309c2dc7e6ac3f555295a5953b97f3641d9b3f4d` | Book-first wrapper; out of book, selects maximum-probability Maia-2 move. |
| [CSSLab/maia-platform-frontend](https://github.com/CSSLab/maia-platform-frontend/tree/a6e52f5c811ee18863cb2f0e81f2433a5b9905de) | `a6e52f5c811ee18863cb2f0e81f2433a5b9905de` | Web play sends `sample_moves` boolean to backend; no numeric Temperature/TopP is established by that request. |
| [lichess-org/lila-openingexplorer](https://github.com/lichess-org/lila-openingexplorer/tree/e8aae1f903931aebc9bf821982b6c098b312c1e7) | `e8aae1f903931aebc9bf821982b6c098b312c1e7` | Rating filter uses the average of both players and broad buckets. |

Local read-only source clones are in `sources/literature/`. These snapshots support inspection; publication only needs the pinned links and selected provenance, not complete cloned repositories.

### Exact Maia-3 sampling behavior

The [official sampler](https://github.com/CSSLab/maia3/blob/1e13597c42d4858b7cfd7cfdae01e297263364b2/maia3/uci.py#L163-L184) returns argmax immediately when Temperature is zero or negative. Otherwise it applies softmax to logits divided by Temperature. If TopP is below 1, it sorts probabilities, retains entries whose cumulative probability is **at most** TopP, always retains top-1, renormalizes, and samples. Thus `(0, 0)` is deterministic; TopP is bypassed.

This implementation excludes the move that takes cumulative mass above the threshold. Conventional nucleus sampling retains the smallest prefix whose mass reaches the threshold. That boundary difference matters in tests and documentation: for probabilities `[0.45, 0.30, 0.15, 0.10]` and TopP `0.9`, the code retains the first three; at TopP `0.8`, it retains only the first two, whereas conventional nucleus sampling retains three. Always record the actual sampler under test. [Nucleus sampling's original paper](https://arxiv.org/abs/1904.09751) motivates truncating an unreliable tail in text generation; it does not calibrate a chess-strength benefit.

There is also a launcher distinction. [Bare UCI argument defaults](https://github.com/CSSLab/maia3/blob/1e13597c42d4858b7cfd7cfdae01e297263364b2/maia3/uci.py#L70-L79) are `(1, 1)`, but [preset executables](https://github.com/CSSLab/maia3/blob/1e13597c42d4858b7cfd7cfdae01e297263364b2/maia3/presets.py#L38-L41) insert Temperature 0. An explicit later CLI option or UCI setoption can override it. Describing `(1,1)` as the universal upstream default would therefore be inaccurate.

### Why the local-stack evidence does not settle bookless openings

The [Maia-3 wrapper](https://github.com/Dash1971/maia3-local-stack/blob/0925e2245e37edf090f57fccca9666ba0ca315f5/maia3_wrapper.py#L197-L220) samples book entries according to their weights. Its [move picker](https://github.com/Dash1971/maia3-local-stack/blob/0925e2245e37edf090f57fccca9666ba0ca315f5/maia3_wrapper.py#L241-L245) uses a book move when available, and only otherwise calls Maia. Consequently Temperature and TopP cannot explain the opening distribution of positions answered by that book. The [README](https://github.com/Dash1971/maia3-local-stack/blob/0925e2245e37edf090f57fccca9666ba0ca315f5/README.md#L101-L129) suggests `(0.5,0.9)` for variety but supplies no controlled Elo comparison supporting that recommendation.

The [Maia-2 wrapper](https://github.com/Dash1971/maia2-local-stack/blob/309c2dc7e6ac3f555295a5953b97f3641d9b3f4d/maia2_uci.py#L55-L70) chooses its maximum-probability move outside the book. Its [compute_move](https://github.com/Dash1971/maia2-local-stack/blob/309c2dc7e6ac3f555295a5953b97f3641d9b3f4d/maia2_uci.py#L95-L102) also gives the book priority. This is a different decision policy from sampled Maia-3, and cannot directly establish Maia-3's setting effects.

## 2. What the Chessformer paper actually measures

The supplied paper is [Chessformer: A Unified Architecture for Chess Modeling, arXiv v1](https://arxiv.org/html/2605.19091v1), submitted 18 May 2026. Section 4 describes Maia-3's human-move prediction task, trained on Lichess blitz games from January 2023 through July 2025 with skill-balanced resampling. Inputs include both players' ratings and current plus seven prior board states. The 79M model achieves 57.1% move-matching accuracy on the Allie test set; that is a prediction result, not an achieved Elo at every rating setting.

Section 5 and the paper's engine-tournament Elo gains concern the separately trained Leela-CF model and its integration into Leela Chess Zero. Those gains cannot be applied to Maia-3's Temperature or TopP. The paper contains no controlled `(0,0)` versus `(0.5,0.9)` versus `(1,1)` Maia-3 match series or numerical strength conversion. Appendix E also reports that real history improves move prediction. Experiments must therefore hold history handling fixed and reproduce Mobile Maia's input construction. [Paper sections 4–5 and Appendix E](https://arxiv.org/html/2605.19091v1#S4).

The [official release announcement](https://lichess.org/@/ashtonanderson/blog/introducing-maia-3-free-and-open-source/vCPPRtX3) explicitly identifies the modeled range as 600–2600 **Lichess blitz** ratings and the model's goal as predicting human moves. It links to weights, source, paper, maiachess.com, and Discord. It provides no exact sampling-to-Elo calibration.

## 3. Sampling theory and implications

Let `z_i` be a legal move's logit and `p_i = softmax(z)_i` the model probability. With positive Temperature `T`, before filtering:

`q_i(T) = exp(z_i/T) / sum_j exp(z_j/T) = p_i^(1/T) / sum_j p_j^(1/T)`.

This is a mathematical consequence of softmax, not an empirical chess result. Temperature 1 leaves `p` unchanged. Temperature 0.5 squares and renormalizes probabilities; the odds between two moves become the square of the original odds. Temperature below 1 concentrates probability on leading moves. Temperature above 1 makes the distribution flatter. TopP then removes low-ranked moves and renormalizes the retained ones. Reducing either setting favors popular moves, not necessarily objectively best moves.

The specific Mobile Maia stable25 sampler clamps positive Temperature to the range 0.001–1.0. The above description of temperatures above 1 is general theory; it does not imply that this app supports temperatures above 1. Experiments use the app's actual implementation, including its crossing-inclusive top-p cutoff.

If a model were perfectly calibrated to an observed population distribution, `(1,1)` would reproduce that distribution in repeated independent decisions. Argmax would collapse each decision to one move. That does not imply `(1,1)` must be closest to any particular explorer dataset: model error, date range, player-rating filters, time controls, and input history can all differ.

Top-1 human-move accuracy and distribution fidelity are different objectives. If the true distribution is `p`, argmax matches an independently observed human move with probability `max(p)`, while sampling from `p` matches with probability `sum(p_i^2)`. Thus a decrease in single-move matching under sampling can coexist with improved repertoire realism. Evaluating only whether Maia selects the explorer's most popular move rewards deterministic play by construction.

A hypothetical distribution `[0.50, 0.25, 0.15, 0.10]` becomes approximately `[0.725, 0.181, 0.065, 0.029]` at Temperature 0.5 before top-p. The `(0.5,0.9)` profile can therefore suppress a normal second or third human opening choice even before its tail is cut. This example illustrates the transformation; it is not measured Maia output.

There is no universal Elo formula for these controls. A low-probability move may be a plausible sideline, a strong but unpopular move, or a serious mistake. Full-game strength depends on where those moves occur, opponents' replies, tactical failures, repetitions, draw adjudication, and time controls. Sharper sampling may improve average practical strength, but its sign and magnitude at 1600 must be tested.

## 4. Public discussion and bot-setting evidence

### Operator testimony on Reddit

In [“Maia 3 bots are now on Lichess”](https://www.reddit.com/r/chess/comments/1tqi6ko/maia_3_bots_are_now_on_lichess/), author `ramen2581` says they added 11 bots from 600 to 2600 using `maia3-79m.pt`, and explains that they use the network output without search. This establishes first-person operator context for that account.

The same account comments in [the Mobile Maia thread](https://www.reddit.com/r/chess/comments/1w61u0z/mobile_maia_play_maia3_and_review_your_games/) that [the 1600 bot](https://lichess.org/@/maia3-79m_1600) is at Temperature 1 and that its opening variation matches Lichess players. [Direct comment permalink](https://www.reddit.com/r/chess/comments/1w61u0z/comment/p7qgzxk/). The thread text was accessible, while opening this permalink separately returned a cache miss.

**Evidence assessment:** Temperature 1 is first-person operational testimony, supported by the earlier announcement. The opening resemblance is an operator's observation with no supplied dataset or metric. TopP 1, opening-book absence, exact history configuration, and source-code equivalence were not established by the accessible Reddit text. Do not silently convert this into a verified deployment configuration or a quantitative opening-match result.

### Developer testimony

In [the official Maia-3 Reddit announcement](https://www.reddit.com/r/chess/comments/1tmk5du/introducing_maia3_free_and_open_source/), Ashton Anderson explains that Temperature lets users choose distribution sampling or repeatable moves. He also distinguishes human-move prediction accuracy from engine-move correctness. [Sampling reply permalink](https://www.reddit.com/r/chess/comments/1tmk5du/comment/ons8fvz/). This supports the meaning of the control, not a preferred default or calibrated strength.

### Existing Discord summary in the local stack

The user repository already contains [a pinned Discord evidence review](https://github.com/Dash1971/maia3-local-stack/blob/0925e2245e37edf090f57fccca9666ba0ca315f5/docs/maia3-elo-discord-evidence.md). Its main claim is that population averaging and limited calculation compress realized strength toward the middle. It links developer statements and community rating snapshots. This is a secondary summary; original messages require authenticated inspection. The root research task is reviewing Discord separately.

Its nominal-1600 bot observation rests on approximately 26 rapid/classical games and cannot determine the difference between sampling settings. Other observations mix model generations, implementations, and time controls. They are useful context for separating conditioning Elo from playing strength, but should not anchor a precise 1600 calibration.

### Official platform frontend

The [public play API client](https://github.com/CSSLab/maia-platform-frontend/blob/a6e52f5c811ee18863cb2f0e81f2433a5b9905de/src/api/play.ts#L12-L35) passes `sample_moves` to the server. The [setup component](https://github.com/CSSLab/maia-platform-frontend/blob/a6e52f5c811ee18863cb2f0e81f2433a5b9905de/src/components/Common/PlaySetupModal.tsx#L130-L133) initializes sampling to true. Backend numerical settings cannot be inferred from this boolean. Opening-drill code uses weighted book choices for its first few plies; that special training flow is not evidence of what ordinary Maia games or community Lichess bots do.

## 5. Defining “closest to Lichess' book”

Lichess has several distinct datasets: masters games, rated user games, and curated opening names. The [opening-explorer repository](https://github.com/lichess-org/lila-openingexplorer#lila-openingexplorer) identifies them separately. For 1600 human repertoire, the relevant target is rating-filtered **Lichess user-game move frequencies**. The opening-name TSV bundled in Mobile Maia is not a move-frequency book.

The [rating-bucket implementation](https://github.com/lichess-org/lila-openingexplorer/blob/e8aae1f903931aebc9bf821982b6c098b312c1e7/src/model/lichess.rs#L51-L78) maps the **average of both players' ratings** to buckets. `ratings=1600` covers averages 1600–1799. `ratings=1400,1600` brackets a 1600 target broadly; neither is an exact pair of 1600 players. Report filters verbatim. A raw PGN cohort can impose tighter mover and opponent bands if needed.

Compare full conditional distributions at a fixed, independent set of opening positions using total variation distance or Jensen–Shannon divergence, with move frequencies weighted by game count. Also inspect starting-move shares, opening-family shares after several plies, repertoire entropy, and common-line coverage. These answer different questions and should be reported together. Rare unexplored positions require sample thresholds and an explicit uncovered category.

Position-level probabilities can be compared exactly without sampling thousands of decisions: transform the cached logits according to each profile and calculate distances to observed frequencies. Game-level sampled rollouts are still necessary for opening-family frequencies and realized strength. Hold history, checkpoint, player/opponent Elo, input encoding, and sampler boundary rule constant.

Book-assisted tests hide the setting's effect during the covered opening. For Mobile Maia's actual use case, play from startpos without injected opening-book moves. A separate balanced-position tournament can isolate later-game strength, but must be labeled as a supplementary condition.

## 6. Access limitations and publication wording

Both `www.mobilemaia.com` and the bare `mobilemaia.com` URL were unavailable through web retrieval. A direct HTTPS fetch failed DNS resolution for `www.mobilemaia.com`. No content from that domain is attributed here. The linked Maia source and release announcement instead expose **maiachess.com**, which was inspected; it is a distinct address and should not be silently substituted.

No publicly indexed bot deployment source or complete numeric configuration was located in the reviewed links. This is a bounded search result, not proof that none exists. Reddit display ages were inconsistent with search-index dates, so this review cites the exact threads and retrieval date rather than inventing calendar publication dates.

Defensible wording before experiments: “Temperature 1 and TopP 1 preserve Maia's learned move probabilities and their natural variety. Lower settings favor its most common choices. We are measuring how much that changes practical strength and opening frequencies at the 1600 setting.”

Wording to avoid without matching evidence: “It plays at exactly 1600,” “Temperature 0 adds N Elo,” “all Lichess Maia-3 bots use 1/1,” or “1/1 reproduces the Lichess opening book exactly.”

## 7. Explicit upstream cutoff issue and portability

[CSSLab issue #14](https://github.com/CSSLab/maia3/issues/14), opened by Dash1971 on 9 September 2026, documents the threshold-crossing discrepancy at the same inspected revision. [PR #13](https://github.com/CSSLab/maia3/pull/13) proposes retaining the crossing move, clarifying the README, and adding deterministic tests. Both were open at retrieval on 2 October; no maintainer endorsement of either cutoff was visible. API snapshots are archived as `sources/literature/issue14.json` and `pr13.json`.

This supplies an additional practical reason to prefer TopP 1: it bypasses the disputed cutoff entirely. Mobile Maia's stable25 sampler already includes the crossing move, so a smaller TopP need not mean the same categorical distribution as the inspected upstream implementation. Temperature 1 is not needed to remove that cutoff disagreement; its separate benefit is preserving the untempered model probabilities.

Together `(1,1)` remove both the nucleus-boundary decision and temperature rescaling. Given the same legal logits and normalization, this makes the intended sampling semantics portable across implementations. It does **not** guarantee bit-identical probabilities, identical random streams or games, identical token/history encoding, identical Elo inputs, or identical model weights across backends. Float precision and inference differences can remain. The strong claim is shared full-distribution semantics, not arbitrary backend numerical identity.

# Independent audit: draw continuation and statistical analysis

Audited on 2 October 2026. This was a read-only audit of the running strength harness; no strength scripts were changed. The earlier policy/input audit is in `AUDIT.md`.

## App draw rules and continuation

The app's game state is `chess.Chess` from **package chess 0.8.1**, imported as `chess` in `lib/main.dart`; the separately imported `dartchess` package is used for other board-position operations and timeout material checks. In `lib/src/session_types.dart`, `naturalGameResult` returns a checkmate win before a natural draw.

Inspected installed source `<pub-cache>/hosted/pub.dev/chess-0.8.1/lib/chess.dart`:

- `in_draw` tests actual halfmove clock >=100, stalemate, insufficient material, or actual threefold history.
- `in_threefold_repetition` replays the entire history and counts the first four **raw** FEN fields. Any historical position reaching three counts triggers the draw, rather than only the current position. Its en-passant field remains the raw double-push target even when no capture is legal.
- Its insufficient-material cases are two kings; two kings plus one bishop or knight; or kings plus bishops exclusively on the same square color. For legal standard positions these match Python chess's combined insufficient-material test.

`app_draw_sensitivity.py` reproduces these natural outcomes. `key(board)` explicitly asks Python chess for raw en-passant FEN. It preserves every primary move, continues a primary threefold/fifty-move draw only if the app has not already ended, checks terminal conditions before selecting another move, and uses the same 400-ply cap. Checkmate takes precedence. A primary prospective fifty-move claim at clock 99 can be escaped by the subsequently sampled pawn move or capture, as it can in the app.

The continuation white/black seeds are separately recorded, unique across games within a study, and disjoint from the primary seed range. Fresh RNGs draw valid independent **future** samples conditional on each saved prefix. They are deliberately not the unused future of the primary game's original RNG. Because prefixes are shared, primary and continuation results are paired sensitivity analyses and must not be pooled as independent games. Identical continuation seed formulas in different model/study sets do not invalidate a separately analyzed set, but these sets should not be treated as independent replications through seed identity alone.

## Verification and limits

`verify_sensitivity.py` reconstructs every move, requires the original move list as an exact prefix, checks legality and absence of an earlier app terminal outcome, rederives the final outcome/score/FEN/ply count, and cross-checks PGN moves and results. Its checks are strong, but use the same `app_outcome` helper as the runner, so the source audit above is needed to assess that helper independently.

There are minor generic guardrail limitations, with no observed artifact failure: the verifier compares total row count but does not itself assert unique sensitivity IDs or exact coverage of the primary ID set; it does not verify continuation seed uniqueness or replay random draws; and the runner trusts the chosen model and input manifests and assumes inputs belong to one compatible study. Mixing main and supplement inputs with overlapping IDs is unsafe. They are separate analyses. Resume output should remain dedicated to its recorded inputs.

We independently checked ID coverage, seed formulas/disjointness, per-pair color counts, and app-vs-Python material outcomes across all replayed positions in the completed 600-game 5M sensitivity set. Results are archived in `5m-independent-statistical-checks.json`. We also ran the full provided sensitivity verifier on that complete set, saving `5m-draw-independent-verification.json`: zero illegal moves, prefix mismatches, draw mismatches or PGN/JSON discrepancies; 12 primary draws became decisive after 890 additional plies. These checks apply to the completed 5M set inspected, not to unfinished 79M runs.

## Score and Elo statistics

`analyze_strength.py` resamples win/draw/loss counts with a multinomial within each first-profile color assignment, then equally weights the two colors. This is exactly the nonparametric bootstrap of game scores within fixed color strata. With a complete, balanced sample the observed overall mean equals the equal-color mean used for its bootstrap, so the point estimate and interval target agree. Interim samples with an odd number of games have unequal color counts; their printed overall mean differs slightly from the equally weighted bootstrap target. Final claims should use completed balanced samples.

The Elo transformation `400*log10(score/(1-score))` is monotone, and transforming the bootstrap score endpoints is correct for the reported descriptive logistic match-performance difference. It is not an absolute human rating, a calibration of the nominal 1600 conditioning value, or proof of transitivity among three settings. Independent recorded game streams support game-level resampling even when some games share opening prefixes; there are no shared random streams within the recorded final matchup.

The score/Elo confidence intervals are **marginal** 95% intervals. They do not have familywise 95% coverage over every pair or supplemental study. Holm correction is applied correctly to the decisive-game p-values over the number of input pairs, although the report's static method string says "across 3" and should only be read literally for three-pair input. The pooled decisive-game binomial test is descriptive: it is not a separately color-stratified hypothesis test and assumes exchangeable decisive outcomes for its exact binomial interpretation. The color-stratified bootstrap is the more directly applicable uncertainty analysis here.

Cap sensitivity correctly reports the score bounds obtained by assigning every capped draw to a first-profile win or loss. These are worst-case outcome bounds conditional on the completed games, not confidence limits. Excluding capped games is a descriptive conditional estimate and can disturb color balance or select for particular policies' game lengths. Transforming the all-win/all-loss score bounds into Elo preserves their ordering; a ranking is cap-robust only if its score bounds stay on the same side of 0.5. Supplementary comparisons isolate a control conditional on the other control's setting; the effects can interact and should not be added as universal Elo penalties.

## Portable helper parity

Diffing `strength/portable/` against the original scripts showed `app_draw_sensitivity.py`, `verify_sensitivity.py`, `analyze_strength.py`, and the runner copies to be byte-identical where compared. `portable/mobile_policy.py` changes only model-file defaults, environment variable overrides, and pre-inference file/hash validation. Input encoding, move mapping, probability transformation, cutoff semantics, RNG sampling and inference settings are unchanged. It accepts either pinned model hash, so users should still use the appropriate 79M/5M model environment variable for the declared study. The portable `verify_policy.py` changes only its fixture path, and the bundled fixture is byte-identical to the original. The saved official-reference parity check also matches 75 legal logits, including Black/promotion fixtures. `portable-file-comparison.json` records the script comparisons.

## Report observations

The report's diagnostic table and uncertainty statements match `summary_balanced.json`. "Nonopening positions" is more precise than calling all 453 fixed-ply positions "middlegame positions", because some games may already be in an endgame. Calling the close-position restriction exploratory is correct. Retain the depth 14 mate-score caveat and distinguish move-level evaluation gaps from observed game blunders.

At this audit stage the strength runs were still in progress. The final report must distinguish the primary prospective-claim protocol from the app natural-draw sensitivity, display completed sample sizes and both color counts, and state marginal interval and cap limitations. Continuation games are not fresh independent simulations. The completed strength results and their integrity reports are now supplied in the publication bundle.

## Audited file hashes

- `strength/app_draw_sensitivity.py`: `2bdc8da4644e973f551f2b9576218e3bdf7e93abffcd4d0ce3e000cac4dd41fd`
- `strength/verify_sensitivity.py`: `65c8c90ac4d6bd53bb42b0f415b1042296f752c5103c5a2b4158c8e7a164f992`
- `strength/analyze_strength.py`: `44573aeea08d1704de75cb47963f32885f0cbd637e0fd44b5098b7b7766a66f5`
- `strength/mobile_policy.py`: `8e3f203b9f26b3ce0a7b01b8cf22101a23cb4339306c4f4d3d8df8794cb0bc98`
- `strength/portable/mobile_policy.py`: `766ef7263fb4a7b487eb850e1a07995a8b62b25f8f16f5e8b68e4665fb9b4131`

## Final amendment: continuation seed separation and portable source diff

The earlier byte-identical comparison applied before the 79M future-stream refinement. The original completed 5M `strength/app_draw_sensitivity.py` is preserved byte-for-byte and still uses continuation base 2026100202. The new `strength/app_draw_sensitivity_79m.py`, identical to the current portable continuation copy, adds only `--continuation-seed` (default 3000000000), records that argument in the manifest, and derives the recorded color seeds from it. Primary 79M continuation uses 3000000000; the separate 600-game single-knob continuation uses 4000000000. Both future ranges are wholly disjoint from the primary/one-knob original streams and each other. Draw predicates, sampling, move selection, prefix continuation, stopping rules, cap and verification are unchanged. The exact small source diff is archived in `strength/portable-continuation-seed.diff`; the refreshed `portable-file-comparison.json` correctly marks the original 5M continuation versus portable copy as different and the new 79M variant versus portable copy as identical.

The analyzer's method string now prints the actual number of input pairs in its Holm-family description, rather than a static “across 3”. This is only metadata formatting; all calculations, bootstrap seeds and intervals are unchanged. The earlier executed 5M analyzer is preserved in `strength/analyze_strength_5m_executed.py`; `strength/analysis-method-label.diff` records the change. No game runner or executed original5M continuation file was modified.

Updated/retained source SHA-256 values:

- `strength/app_draw_sensitivity.py`: `2bdc8da4644e973f551f2b9576218e3bdf7e93abffcd4d0ce3e000cac4dd41fd`
- `strength/app_draw_sensitivity_79m.py`: `87de948d7a9122c9d2b621d07b182132cfcb42d724bf5ba3ef343a6dae9ca15e`
- `strength/analyze_strength.py`: `afbd5734b6dca95fdae81fa1a60600c9a71fdca97f3aa8fbb1628a58ac44cd34`
- `strength/analyze_strength_5m_executed.py`: `44573aeea08d1704de75cb47963f32885f0cbd637e0fd44b5098b7b7766a66f5`

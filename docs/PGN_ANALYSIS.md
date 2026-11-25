# Saved analysis in PGN

Prepared for [Stable 2.6 promotion #82](https://github.com/Dash1971/maia-chess-android/pull/82).
This feature ships in [Preview beta.13](https://github.com/Dash1971/maia-chess-android-preview/releases/tag/v2.6.0-beta.13)
and is included in this unmerged Stable candidate. Published Stable 2.5.1 is
unchanged. Scope and implementation originated in [Preview #61](https://github.com/Dash1971/maia-chess-android-preview/issues/61)
and [#267](https://github.com/Dash1971/maia-chess-android-preview/pull/267).

Run Computer analysis as usual. Once every position has been evaluated, Mobile
Maia saves those evaluations in the existing game's PGN. When move classification
finishes, it saves the move-quality symbols too. Reopening the saved game restores
the graph and markings without another full-game run. The ordinary live engine
lines still analyze the selected position.

Running analysis again replaces the previous evaluations and quality symbols on
the analyzed line, including imported ones. Existing prose comments, clock tags,
variations and other positional annotations are preserved. Saved scores are
opinions from the analysis that produced them; changing engines or settings does
not automatically discard them. Stop before evaluation finishes retains the
previous saved analysis. Stop during classification retains the newly completed
evaluations without publishing a late classification result.

## Save, share or copy

The existing export menu has an **Include analysis** checkbox, checked by default.
It applies to **Save PGN file**, **Share PGN** and **Copy PGN**, with no additional
dialog. Recent games offers the same checkbox above Save/Share for selected-game
collections. The choice lasts while that screen is open; it is not an app setting.
Analysis stripping for Save, Share and Copy PGN runs in a background worker.

Uncheck it to remove evaluation tags and the six move-quality symbols from the
exported copy. Prose comments, clocks, variations and other positional annotations
remain. This does not erase analysis from the saved game. Collection export strips
each selected game's analysis before checking the combined 5 MiB limit.

## Portable representation

Scores use the common PGN comment extension `[%eval 0.35]`, from White's point of
view, with `[%eval #3]` for mate and `[%eval #0]` at actual checkmate. The initial
position's score is a comment before the first move; later scores follow their
moves. A complete graph uses a score for the initial position and every move on
the analyzed line. Some imports, including Lichess game exports, omit only the
initial evaluation. When every move has a readable score and the initial tag is
absent, Mobile Maia reuses its initial-position evaluation or evaluates just that
position in the background, then restores the graph. Imported move scores and
markings stay unchanged; this does not rerun the game or classification, or
rewrite the imported annotations. Lifecycle/engine changes can retry this work;
line edits, disposal and explicit reanalysis prevent stale results from appearing.
Missing scores elsewhere, or explicitly malformed evaluations, are not filled.
They do not prevent the underlying game or readable move symbols from opening.

Move-quality symbols use standard numeric annotation glyphs:

| PGN | Symbol | Mobile Maia classification |
| --- | --- | --- |
| `$1` | ! | Good move |
| `$2` | ? | Mistake |
| `$3` | !! | Brilliant move |
| `$4` | ?? | Blunder |
| `$5` | !? | Interesting move |
| `$6` | ?! | Dubious move |

These remain PGN games usable by other readers. Readers may display or ignore the
evaluation extension and may interpret the standard symbols differently. Mobile
Maia does not export the full engine report, candidate lines, model probabilities,
engine internals, provenance records or a resumable partial-analysis cache.
Annotations add a small amount of text; the existing 5 MiB limits still apply.

Storage uses the existing game/session record and identity. There is no new
analysis database, file attachment, dependency, permission or network service.
If an annotated PGN exceeds the limit or saving fails, a localized error is shown.
The existing stored game is retained; the visible analysis can still be exported.

## Verification

`test/pgn_saved_analysis_test.dart` covers evaluation/NAG round trips, replacement
on reanalysis, mates and custom starting positions, incomplete/malformed tags,
played prefixes, size limits, reopen without a full rerun, cancellation,
existing-record persistence, Save/Share and collection export with and without
analysis, storage failure and all ten locales at 320 pixels with 200% text.
`test/pgn_analysis_review_regressions_test.dart` covers imports missing only the
initial score, custom Black-to-move positions, incomplete/malformed tags,
selected-position cancellation, background/resume, engine toggling, late results
after reanalysis/disposal and responsive Copy PGN on both screens with a PGN over
2 MiB. The Copy tests detect the original synchronous stripping behavior.

Host checks do not replace installed Android save/share and upgrade testing before
publication. This preparation update runs no application builds or GitHub Actions.

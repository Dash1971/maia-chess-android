# Optional Maia score (#186)

The requester replaced the original left-hand bar with text and then requested
that the text use the existing Analysis Board / Game Review title area. Each Maia
has a compact line beside the title: rating, white/black disc and the favoured
side's rounded expected score. Engine colours match the move-probability rows;
accessible labels name the rating and side. Equal rounded scores show `= 50%`,
loading an ellipsis, and missing/failed outcomes a dash. Terminal positions show
the actual result instead of a model estimate.

The display adds no row, board gutter or toolbar height. On narrow screens or
large text, ratings are omitted visually; tapping the 48 dp score target opens
scrollable details with full rating/side labels and help. The page title can wrap
within the existing toolbar; long translations use an ellipsis and full tooltip.
Board, Stockfish, engine rows, move list and navigation retain their bounds when
the preference changes. Rating, side-marker and score columns reserve space for
all loading, unavailable, percentage, equal-score and terminal states. The rating
visibility breakpoint uses this reserved width, never the current score, so async
results cannot move the labels or make them flicker into/out of view. Discs stay
vertically aligned in their own column; percentages start 4 dp after the disc,
with an 8 dp gap after the rating. The value column is start-aligned, so 100%
does not move a disc or widen the gap before shorter percentages. No evaluation
is added to ordinary play.

Settings → Analysis → **Show Maia win (score) %** is off by default. The boolean
`maiaScoreVisibleV1` persists, participates in the existing confirmed Settings
reset and reports save failures. The existing SettingsInfoSwitch places an ⓘ
button beside the label; its scrollable explanation follows the other Settings
items. Help is translated in all ten languages. The existing analysis-quality
dropdown, descriptions and engine behavior are unchanged.

## Meaning and inputs

For the side to move, apply a stable softmax to the loss/draw/win logits and
compute `P(win) + 0.5 × P(draw)`. Convert Black-to-move results with `1 − score`
to get White's expected score, then label the favoured side. Draws count as half
a point, so this is not a literal probability of winning. Flipping only changes
orientation and cannot change the labelled side.

Each engine uses its own selected **analysis rating for both players**. M1500
assumes 1500 versus 1500; M2600 assumes 2600 versus 2600. The engines are not
assigned White and Black, and their scores are not averaged. Current position,
variation, history prefix and the saved session's history mode match that Maia's
existing move-probability inputs. Rating/context changes invalidate policy and
outcome caches together. Late results cannot populate a different context.
Temperature, Top-P, human timing and Stockfish quality do not set the percentage.

## Verified model and references

- Preview ONNX: 316,034,244 bytes, SHA-256
  `3454b03ae78baa64a87b345fdb1a457265d912caec531039b074f07eda0d8010`.
- `tool/export_maia3_onnx.py` names the model's second returned tensor
  `value_logits`, alongside `move_logits` and `ponder`.
- The pinned official Maia-3 source used by the numerical reference fixtures,
  [1e13597, maia3/uci.py](https://github.com/CSSLab/maia3/blob/1e13597c42d4858b7cfd7cfdae01e297263364b2/maia3/uci.py),
  documents value channels as loss, draw, win for the side to move in
  `wdl_from_value_logits`. Checkpoint provenance remains in
  `integration_test/fixtures/maia3_reference.dart`.
- The website's [processing at a6e52f5](https://github.com/CSSLab/maia-platform-frontend/blob/a6e52f5c811ee18863cb2f0e81f2433a5b9905de/src/lib/engine/maia.ts)
  uses the same channel order, normalization, half draws and Black-to-move
  inversion. This implements that definition, without claiming exact numerical
  website parity across model, encoding, history or rating versions.

Android copies the requested heads before closing the existing ONNX result.
There is one inference per existing Maia request and no extra model pass for the
score. Gameplay's typed move-only response remains compatible. A missing or
malformed head never becomes a placeholder percentage. Computation uses the
bundled model offline, with no Stockfish-to-percentage conversion.

Unit/widget tests cover normalization, perspective, corrupt responses, persistence,
reset, rating/position invalidation and unchanged geometry in all ten languages
at 200% text. `integration_test/maia_score_android_test.dart` checks the actual
Preview 79M bridge, both ratings, typed gameplay compatibility, header details and
native preference reload. These checks do not replace full exact-source Preview
release qualification.

No shared build, CI, verification or cleanup helper changes. This Preview feature
has no Stable companion tooling port and does not promote or publish a channel.

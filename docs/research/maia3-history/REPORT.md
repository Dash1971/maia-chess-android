# Why Mobile Maia keeps move-history input off

Research and decision record · **9 October 2026** · Maia-3 79M

## Decision

Mobile Maia continues to repeat the **current position** in the model's eight
board-input slots instead of supplying the preceding positions. We prioritize
reducing repetitive opponent behavior in low-Elo play, accepting the loss in
average human-move prediction measured here. This concerns input to Maia's
model: the app still retains game history, PGNs, variations and the information
needed to enforce chess rules.

Two findings inform the decision:

1. Actual history **improved human-move prediction** across a broad sample.
2. In the remembered low-Elo Stonewall setup, history **strongly reinforced
   continued copying** once a mirrored opening had started.

These findings address different objectives. Better prediction on positions
from human games does not guarantee a more varied opponent when the model
generates its own continuation. We have not established that history makes
Maia tactically weaker or changes its full-game playing strength.

## What changed originally, and what upstream says

The [5 September implementation change](https://github.com/Dash1971/maia-chess-android-preview/commit/49da564dff6896725176d1ba5e6c0d8f1fefecf0)
replaced the last eight positions with eight copies of the current position.
Its code comment cited the released upstream default and a concern about
copying when Maia plays Black. The relevant patch is preserved in
[original-decision.json](original-decision.json). That comment records our
rationale, not a quotation from the Maia authors.

The [upstream README](https://github.com/CSSLab/maia3/blob/1e13597c42d4858b7cfd7cfdae01e297263364b2/README.md)
documents `--use-uci-history` as an optional mode. The pinned
[UCI implementation](https://github.com/CSSLab/maia3/blob/1e13597c42d4858b7cfd7cfdae01e297263364b2/maia3/uci.py)
defaults to history off. Our review of that source, README and the available
GitHub discussion found **no explicit author recommendation against history**.
That bounded search cannot establish that no such advice exists elsewhere.

The optional upstream history encoder orients each position by that position's
own side to move, as the old app did. The alternating orientation is therefore
not, by itself, evidence of an app encoding bug. The
[Chessformer paper's history ablation](https://arxiv.org/html/2605.19091v1#A5)
reports human-move accuracy of 54.0% without previous positions and 55.4% with
seven previous positions in the 5M experiment, with larger gains at lower
ratings. It also describes history masking during training. That training
ablation is not the same experiment as toggling input on a released 79M model.

## Comparison and implementation checks

All primary comparisons use the same hash-pinned **Maia-3 79M ONNX export**, a
full legal-move softmax, **temperature 1 / top-p 1**, and zero ponder input:

- **History off (R):** encode the current board and repeat it eight times.
- **History on (H):** encode the current board and up to seven previous boards,
  oldest first; pad a short history on the left with its earliest board.

Each historical board uses its own side-to-move orientation. The comparison
does not change weights, move indexing, legality or sampling. The Stonewall
cache keys the complete last-eight-position history and Elo, not just the
current FEN.

The [upstream parity check](broad-study/results/parity.json) compared 38
history/mode cases with official PyTorch inference: all input tensors and top
moves agreed; the largest legal-probability difference was approximately
0.000595 percentage points. Saved-result checks covered legal move sets,
probabilities, metrics and terminal flags. The Stonewall follow-up replayed
every generated trial and random draw and directly recomputed 12 policies
without the cache, with zero difference on the original runtime.

Model, checkpoint and source pins are in [source-pins.json](source-pins.json).

## Broad study: history helps predict human moves

We used the pinned
[Allie 2022 Lichess blitz test source](https://huggingface.co/datasets/yimingzhang/allie-data/tree/990f79105b1f08a8fd367fcb10c5e18c69436e30/lichess-2022-blitz-test),
which predates the published Maia training period. Both players had to be
rated 600–2600. Selection conservatively excluded positions after either
reconstructed clock fell below 30 seconds. Games were legally replayed;
duplicates and invalid records were excluded. A separate 1,000-position pilot
was not pooled with the main results.

The main sample contains **20,160 positions from 9,153 games**, balanced across
four rating bands, both colors and three game stages after move 10. Intervals
use 2,000 paired whole-game bootstrap resamples. This balanced sample is not a
population-frequency estimate or a reproduction of the paper's benchmark.

| Main measure | History off | History on | Change, with 95% interval |
| --- | ---: | ---: | ---: |
| Top predicted move matches the human | 57.00% | 59.36% | +2.36 pp [1.92, 2.79] |
| Mean probability assigned to the human move | 44.18% | 47.17% | +2.99 pp [2.84, 3.13] |
| Negative log likelihood, lower is better | 1.2809 | 1.2000 | −0.0809 [−0.0867, −0.0751] |

Prediction improved in every rating band, both colors and every sampled game
stage. An app-like equal-rating sensitivity on 2,400 of these positions also
favored history: top-move accuracy rose from 57.54% to 59.79%.

On **4,000 opening positions from 3,608 games**, top-move accuracy rose from
50.93% to 52.48%. Mean mirrored-reply probability changed only from 5.21% to
5.28%, with an interval spanning zero. For Black at 600–1199 it rose from 7.64%
to 8.16%, close to the observed human copying frequency of 8.2%. An ordinary
symmetrical reply is not automatically an error. These broad averages did not
resolve the specific Stonewall concern.

### Tactical findings remain uncertain

For 384 prespecified positions, Stockfish 18 evaluated every legal child at
20,000 nodes; 48 positions were repeated at 80,000 nodes. Among 265 positions
whose best candidate was not already more than two pawns worse, probability
mass on moves at least two pawns behind the best candidate changed from
**13.23% to 13.73%**: +0.50 percentage points, with a 95% interval of
**−0.22 to +1.24**. This supports neither a reliable improvement nor a reliable
regression, and does not establish equivalence. A secondary top-p 0.95
analysis showed an adverse expected-loss signal; it is retained in the
[complete summary](broad-study/results/summary.json), not used to select a
different primary result.

These are finite-search diagnostics, with limited rare-mate/stalemate coverage,
not complete matches. Tactical engine roots used FENs without the full
repetition history. The two triggering examples also moved in opposite
directions: history raised the probability of stalemating `…Qf1` from 0.258%
to 0.408%, while lowering the probability of the losing `Qc2` from 0.419%
to 0.283%. Neither example alone determines the policy.

## Focused follow-up: the Stonewall copying effect

The remembered incident involved Maia as Black at approximately **600 or 700**:

```pgn
1. d4 d5 2. e3 e6 3. Bd3 Bd6
```

We reconstructed that start and chose this diagnostic continuation:

```pgn
4. f4 f5 5. Nf3 Nf6 6. c3 c6 7. Nbd2 Nbd7
8. O-O O-O 9. Qe2 Qe7 10. Ne5 Ne4
```

The continuation was chosen for this follow-up; it is not a recovered original
game. The focused protocol was written before its model inference, after the
broader study and the user's clarification of the opening. Both Elo inputs
equal the selected rating. The fixed-prefix diagnostic also includes 800,
1000 and 1200 in the [raw results](stonewall/fixed.jsonl).

### Conditional probability of the mirrored reply

**Each row assumes all preceding moves followed the mirrored line above.**
These are model probabilities at the same position with different history
input, not frequencies over arbitrary Stonewall games.

| Black reply | 600: off | 600: on | 700: off | 700: on |
| --- | ---: | ---: | ---: | ---: |
| `1…d5` | 41.45% | 52.31% | 43.71% | 52.90% |
| `2…e6` | 18.52% | 19.38% | 18.70% | 17.56% |
| `3…Bd6` | 5.31% | 15.05% | 5.53% | 11.78% |
| `4…f5` | 6.64% | 55.70% | 7.08% | 45.12% |
| `5…Nf6` | 42.95% | 87.17% | 47.58% | 84.49% |
| `6…c6` | 6.15% | 83.94% | 5.85% | 79.17% |
| `7…Nbd7` | 9.98% | 90.61% | 11.31% | 89.70% |
| `8…O-O` | 48.08% | 92.66% | 49.09% | 93.36% |
| `9…Qe7` | 4.94% | 88.86% | 4.92% | 87.12% |
| `10…Ne4` | 26.93% | 72.28% | 36.79% | 70.31% |

Once the first three pairs of moves have happened, the probability that Black
copies **all five following moves through castling** is:

| Rating | History off | History on |
| --- | ---: | ---: |
| 600 | 0.0084% | **34.22%** |
| 700 | 0.0109% | **25.28%** |

These products describe one exact continuation. Reaching it from the starting
position is much rarer: the first three mirrored replies have probability
0.408% off versus 1.526% on at 600, and 0.452% versus 1.095% at 700. The entire
eight-reply mirrored line has probability **0.0000343% versus 0.5223%** at 600
and **0.0000494% versus 0.2767%** at 700. Do not interpret the conditional 34%
figure as applying to all new games.

### Sampled continuations

We also generated **1,000 opening trials**: 250 per rating per mode. White
attempted `d4, e3, Bd3, f4, Nf3, c3, Nbd2, O-O`; Black sampled freely. Trials
stopped if Black's reply made the next scripted White move illegal, including
checks. Stopped trials stayed in the denominator. These are opening trials,
not 1,000 complete chess games.

| Rating and measure | History off | History on |
| --- | ---: | ---: |
| 600: first three replies all mirrored | 2/250 | 7/250 |
| 600: all eight replies mirrored | 0/250 | 2/250 |
| 700: first three replies all mirrored | 2/250 | 4/250 |
| 700: all eight replies mirrored | 0/250 | 0/250 |

The rare-event counts are noisy; the exact conditional probabilities above
are more informative about this specific path. No observed event at 700
does not mean zero probability. The paired bootstrap becomes degenerate when
both samples contain zero events. Respectively, 119/114 trials at 600 and
124/114 at 700 stopped before completing the script (off/on). Mean copied
reply counts increased from 0.620 to 0.864 at 600 and 0.676 to 0.872 at 700;
completion lengths limit interpretation of those counts. Seeds, moves and
policy references are retained in [games.jsonl](stonewall/games.jsonl).

### Copying versus bad chess

[Stockfish checks](stonewall/engine-context.json), using 100,000 nodes per
unrestricted/forced-move search, found **no major tactical blunder** on this
ten-move mirror path. The clearest estimated costs were about half a pawn for
`…f5` and `…c6`. These positions remained playable. This supports a concern
about repetitive behavior, not a claim that every copied move is weak.

The human reference is too sparse to determine whether this conditional
copying is excessive relative to real 600–700 players. Among 773 source games
with Black rated 600–799, none had White's exact `d4/e3/Bd3` first-three-move
sequence. Across Black ratings 600–2600, only four games followed the exact
five-ply prefix before `3…Bd6`. See [counts](stonewall/human-context.json).

## Interpretation and limits

The targeted result supports the practical motivation for disabling history.
The earlier broad average missed a large effect on this particular path.
It does not demonstrate that the upstream encoder is wrong, identify a causal
training mechanism, prove worse tactics, or establish a full-game Elo change.
The original incident's full PGN and exact historical settings were not
recovered. These tests apply to 79M at 1/1, not every checkpoint or sampling
configuration.

Our choice remains **history off**, with the human-prediction cost acknowledged.
If revisiting the decision, retain this Stonewall sequence as a regression
fixture and evaluate multiple openings and complete generated games alongside
human-position prediction. An arbitrary hybrid history cutoff is not justified
by this one test.

For raw evidence, protocols, provenance and verification, see the
[research index](README.md) and [reproduction guide](REPRODUCING.md).

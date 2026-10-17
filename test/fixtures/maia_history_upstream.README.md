# Maia move-history encoder parity fixture

`maia_history_upstream.json` contains all 38 input cases from
[mobile-maia-research](https://github.com/Dash1971/mobile-maia-research/tree/e757896b561007476a6c20d8cacbe64c851132ea/studies/move-history-2026-10-09/broad-study/results),
commit `e757896b561007476a6c20d8cacbe64c851132ea`:

- `upstream-reference.json`: case identifier, chronological FEN history and mode.
- `upstream-tensors.json`: the input tensor produced by the official upstream
  parity run, stored here as flattened indices of its nonzero values (all one).

The research repository publishes these artifacts under AGPL-3.0. The fixture
is a sparse transcription of input data, with no upstream model weights,
inference output logits, or implementation source copied. It covers both
side-to-move orientations, short-history padding, full windows and current-only
mode. The eight board slots are chronological, ending with the current position;
each FEN is encoded from its own side-to-move perspective. The zero
ponder channel remains part of the expected tensor.

This fixture validates encoding parity. It does not measure model strength,
5M/79M prediction behavior, device latency or memory use.

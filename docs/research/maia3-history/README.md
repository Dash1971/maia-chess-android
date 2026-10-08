# Maia-3 move-history research

**9 October 2026.** Read the [research report and decision](REPORT.md) for why
Mobile Maia keeps model move-history input disabled.

History improved average human-move prediction, but substantially reinforced
copying in a focused low-Elo Stonewall test. We retain the current-position
input to reduce that repetitive behavior. This is our product decision; we
found an upstream history-off default, not an explicit upstream recommendation
against history.

- [Combined report](REPORT.md): source review, broad evaluation, Stonewall
  follow-up, limitations and recommendation.
- [Reproduction guide](REPRODUCING.md): dependencies, downloads and commands.
- [Broad-study protocol](broad-study/PROTOCOL.txt) and
  [summary](broad-study/results/summary.json): 20,160 main positions, 4,000
  opening positions and 384 tactical diagnostics.
- [Stonewall protocol](stonewall/PROTOCOL.txt),
  [conditional probabilities](stonewall/fixed.jsonl),
  [1,000 sampled opening trials](stonewall/games.jsonl) and
  [summary](stonewall/summary.json).
- [Broad records archive](broad-study/records.tar.gz) and
  [Stonewall policies archive](stonewall/policies.tar.gz): selected input
  histories, full legal-move probabilities and engine records. Use GitHub's
  **Download raw file** button for large files.
- [Publication integrity](publication-integrity.json),
  [measurement hashes](measurement-hashes.json) and [file checksums](SHA256SUMS).

This is independent Mobile Maia research, not an official Maia-team study.
The experiments use the 79M model; they do not establish the same behavior in
the smaller 5M Dev model. Chess records are factual data derived from the
attributed public source or generated experiments. Original research code and
documentation follow the repository's [AGPL-3.0-only licence](../../../LICENSE).
Third-party models, datasets and software retain their upstream terms and
attributions; their full source datasets and model weights are not republished
in this bundle.

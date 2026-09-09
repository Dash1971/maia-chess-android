# Preview beta.13 verification

Date: 2026-09-09. Reviewed source:
`5e5e413c24b070197b9ca29a13fd700a56b62e7d` (`v2.1.0-beta.13`).
The merged beta.12 hardening patch was intact; only the version had changed.

**Recommendation: merge this follow-up before promoting beta.13 to the stable
app.** This round reproduced additional defects, including loss of a variation's
continuation and comments. Passing results below describe the patched source;
the published beta.13 APK still contains these defects.

## Confirmed findings and fixes

| Priority | Finding | Reproduction and correction |
| --- | --- | --- |
| P1 | Replaying an existing variation could replace it and lose its continuation/comments. | Import `1. e4 e5 (1... c5 {Keep this note} 2. Nf3)`, select the position after e4, and play c5. The old export became `1. e4 e5 (1... c5)`. Two chess libraries encode non-capturable en-passant targets differently, so the existing branch was not recognised. New moves now use consistent stored FENs; branch matching also accepts semantically equivalent legacy FENs. |
| P2 | Restarting could lose the selected analysis position after a pawn double move. | On the actual published APK, play e4/e5, return to the start, create d4, flip the board, force-stop, and reopen. The tree and orientation survived, but selection returned to the start. Restoring a saved position now normalizes equivalent FEN representations while preserving legal en-passant rights, castling rights, and counters. |
| P2 | Opening lookup could miss positions after pawn double moves. | The bundled Lichess EPDs omit non-capturable en-passant targets, while chess-generated FENs include them. Lookup now normalizes those targets as well; e4 and d4 tests cover both formats. This also prevents the consistent-FEN fix above from suppressing opening labels. |
| P2 | Failed Stockfish readiness could make later analysis fail repeatedly. | After native start succeeds, fail the `isready` write or omit `readyok`. The old listener remained attached and the live engine was not quit. The native library rejects another start while already running. The handshake now always cancels its subscription and resets failed startup before retrying. |
| P2 | Flag fall always awarded a loss, even against a bare king. | Both White and Black timeout fixtures reproduced the wrong decisive result. The result now uses dartchess's side-specific insufficient-material test. The saved PGN and result message reflect a timeout draw. Tests also protect positions where a minor piece can still mate with help from opposing material. |

The timeout correction follows the principle in
[FIDE Article 6.9](https://handbook.fide.com/chapter/e012023) and
[Lichess's timeout explanation](https://lichess.org/faq#timeout). The library's
material test is not a complete solver for every possible unwinnable fortress.

## Checks

- Unmodified merged source: all 178 existing host tests passed. The new
  readiness, flag-fall, restoration, and variation-preservation regressions
  failed before their corresponding fixes.
- Patched source: **192 host tests passed**, with no static-analysis issues.
  Python model-verification tooling: **2 tests passed**.
- **43,200 deterministic sampling comparisons** against a probability-space
  reference: both colours, promotion positions, Temperature 0/0.05/0.5/1,
  Top-P 0/0.01/0.5/0.8/0.9/1, multiple quantiles, and logits shifted by
  -1000/0/+1000. All passed.
- **10,000 independently generated chess positions**, seed `20260910`: legal
  moves, mate/stalemate, selected transitions, board-frame inference, PGN
  round-trip, and Maia board tokenization all passed. The complete **4,352-move
  vocabulary and its Black-perspective mapping** also passed. The 256-position
  default fixture is included in normal CI.
- **1,000 archived games**: listing, sorting, reopening, bulk deletion, and
  restart passed. Listing took 257 ms in the focused host run. This is not a
  phone benchmark. A simulated filesystem write failure preserved the last
  save, and the next write succeeded using the same repository instance.
- **4 Android integration tests passed** with the patched source on the AOSP
  API 36 ARM64 emulator, including real Maia inference and real Stockfish
  navigation and graph analysis.
- The actual published beta.13 APK was downloaded, its signature verified, and
  both engines exercised. Its bundled model matches the pinned SHA-256, and
  its release manifest has no Internet permission. The published artifact's
  process-restart failure supplied the additional restoration regression above.

- Final clean ARM64 release build succeeded (393,503,463 bytes), with the
  verified model and no Internet permission. A copy signed with the local
  Android test key was installed only on the emulator. After force-stop and
  relaunch, it retained the d4 selection, e4/e5/d4 tree, flipped orientation,
  and A40 opening label; both engines resumed. Screenshots and the smoke script
  are retained with the local report. Official signing credentials were not used.

CI results are recorded with the pull request and local verification report.

## Sampling context

The current upstream Maia-3 CLI at
[`1e13597`](https://github.com/CSSLab/maia3/blob/1e13597c42d4858b7cfd7cfdae01e297263364b2/maia3/uci.py#L163)
also uses the former below-threshold sampling rule. Mobile Maia's merged fix
intentionally includes the move that first reaches/crosses P, matching its
documented nucleus definition. Therefore nontrivial Top-P settings are not
guaranteed to reproduce the upstream CLI's sampling. Top-P 1 and Temperature 0
are unaffected by that distinction. This round made no further sampling change.
The upstream vocabulary, board mirroring, current-position history default, and
zero ponder channel were also inspected for consistency with the app.

## Scope

No runtime dependencies, network permissions, model weights, or app settings
were added or changed. Physical hardware tests remain outside this work as
requested. This is targeted evidence, not an exhaustive proof of correctness or
a validation of Maia's Elo calibration. Native GATT setup timeouts, every
possible process-kill timing, stable-package data migration, and signed stable
publishing are not established by these tests.

See [the test guide](../tool/hardening/README.md) for reproduction commands.

# Preview beta.12 release hardening

Audit date: 2026-09-09. Base: `c83cd5ca7f3033391e5ba0e080f42cd2505f49d1`
(`v2.1.0-beta.12`). Scope: source review, deterministic fault injection,
differential chess testing, host stress tests, and Android emulator integration.
No phone or physical Chessnut board was used.

## Fixes

| Area | Trigger and previous behavior | Change |
| --- | --- | --- |
| Maia sampling | With probabilities 0.6/0.3/0.1 and Top-P 0.8, the sampler retained only the 0.6 move. This made play less varied than the documented nucleus rule. | Include the move that first reaches or crosses the threshold. Add seeded regression coverage. |
| Saved games | A valid JSON checkpoint with an integer timestamp passed envelope validation and then crashed Recent games despite a usable backup. | Validate identifier, timestamp type, and top-level PGN type before accepting a checkpoint; reuse existing backup recovery. |
| PGN input | Thousands of nested variations bypassed the intended depth limit. A character-count limit also admitted UTF-8 text larger than the byte budget. | Reject lexical nesting over 64 before tree construction; enforce the 2 MiB limit in UTF-8 bytes for pasted PGN too. |
| Delayed board alerts | A checking move could finish its Bluetooth beep after the game page was disposed and call `setState`. Pausing during Maia's check alert could checkpoint the move without its pending physical guidance. | Guard post-await work with mounted/generation checks; record guidance with the move, and resume LED refresh for pending guidance. |
| Stockfish failures | A native `go` write exception leaked an output subscription. A timeout followed by a failed `stop` left startup state cached for the next request. | Put command writes inside cleanup; discard failed engine startup state and reset the process before retrying. |
| Bluetooth completion loss | A missing native LED/beep completion could leave the caller waiting indefinitely. | Apply a 10-second command deadline and disconnect the affected connection, with a bounded disconnect wait. Generation checks protect a newer connection from an older timeout. |
| Explicit disconnect | A failed LED-clear request skipped the following disconnect call. | Run disconnect in `finally`, with a one-second deadline for the optional LED clear. |

The original code failed targeted regressions for sampling, checkpoint metadata,
PGN nesting, delayed alert disposal, native Stockfish recovery, and lost native
Bluetooth completions. Additional tests cover the related pause/resume,
disconnect, and Unicode boundary cases. These changes preserve the offline app
architecture and add no runtime dependencies.

## Validation

- Original host suite: 163 passing tests before changes.
- Hardened host suite: 178 passing tests, including 24 Chessnut widget/protocol
  tests, three transport timeout tests, and two Stockfish failure tests.
- Independent python-chess corpus: 3,000 positions, seed `20260909`, all passed.
  Comparisons include legal moves, terminal status, selected transition FEN,
  inferred physical-board moves, and PGN round-trip. A 256-position fixture is
  included in ordinary CI.
- Engine queue stress: 1,000 seeded operations; every request settled and peak
  concurrent native work was one.
- 1,000-ply PGN import plus round-trip: 324 ms in the focused host run and 573 ms
  during the parallel full suite. These are development-host observations, not
  mobile latency measurements or a claimed speedup.
- Python model-verification tooling: two passing tests.
- Static analysis: no issues.
- Android integration: four passing tests on an AOSP API 36 ARM64 emulator,
  including real Maia inference and real Stockfish navigation/graph analysis.
  The final integration run completed its test phase in 83 seconds.
- Clean release build via `tool/build_android_release.sh`: successful unsigned
  ARM64 APK, 393,437,927 bytes. Packaged Maia model SHA-256 matches the pinned
  digest. The release manifest has no `android.permission.INTERNET`.

The existing Android integration tests required current navigation keys and
scrolling the graph into view before coordinate taps. The corrected graph test
also verifies the selected ply so a tap on an unrelated control cannot pass.

## Boundaries and follow-up

This is evidence of improved failure recovery, not a guarantee of exhaustive
correctness. In particular:

- The Bluetooth watchdog bounds LED/beep command completion. It does not add
  an overall deadline to native scanning, MTU negotiation, or service discovery.
  A separately instrumented native connection-state test would be useful.
- Checkpoint validation covers the reviewed envelope fields; it is not a full
  schema validator for every nested saved-game value.
- Seeded tests cover many legal positions and queue interleavings, but cannot
  reproduce every native scheduling or memory-pressure condition. An ONNX call
  that never returns is not preempted by a Dart future timeout.
- The emulator exercises native engine bridges, not real BLE radio behavior,
  battery use, or phone thermal performance. Physical testing remains with the
  app owner as agreed.
- Stable-app promotion, stable-data migration, release signing, and publishing
  were not performed. Review this patch in Preview before promotion.

Reproduction commands and environment requirements are in
[`tool/hardening/README.md`](../tool/hardening/README.md).

# Invalid edited position and repeated startup failure — 2026-10-27

## Reproduction and evidence

Reported on Stable 2.5.0/code 82, source
`aeea49817c34f48397e910894414c1d8b0352124`. The reporter recreated this board:

```text
r1bqk1nr/ppppbppp/2n5/4R3/4R3/4RN2/PPPP1PPP/RNBQKB1R w KQkq - 0 1
```

It has 33 pieces: White has 18, including five rooks and seven pawns. Both
White-to-move and Black-to-move versions passed the two existing Dart validators.
The editor saved the analysis checkpoint before engine evaluation. Startup then
automatically reopened that checkpoint, making an engine failure repeat.

An isolated CLI built from the exact cached `multistockfish_light` 0.1.0 source,
with AddressSanitizer/UndefinedBehaviorSanitizer enabled and assertions disabled,
accepted the standard initial position (exit 0). The reported position produced:

```text
CRITICAL ERROR: Command `position fen ...` failed.
Reason: Invalid FEN. More than 32 pieces on the board.
```

and exit status 1. `Position::set` rejects excessive material;
`UCIEngine::terminate_on_critical_error` calls `std::exit(1)`. The app loads this
engine through FFI inside its own process: a Dart catch cannot contain that exit.
This is a confirmed fatal-input path, **not** an observed sanitizer overflow.
The supplied phone logs also contain Skia Unicode assertions, SIGSEGV and a
destroyed-mutex abort, but no usable native backtrace connecting each symptom.
Do not claim the isolated CLI reproduced every phone-log stack.

The standalone reproduction used the package's cached network
`nn-61e7af4bb97d.nnue`, SHA-256
`61e7af4bb97d51eeeb25d322916f86513b5cd3a827ce189c98c6e31946f99e5b`,
and a console-stream adapter in place of the package's app-facing I/O pipes.
No APK, model upgrade, new dependency or release is part of this fix.

## Protection

- Validate standard-chess material, promotion budget, FEN structure and engine
  counter bounds before import/editor completion and again at the Stockfish
  command boundary. Validate each effective Maia input board before encoding.
  Existing king/check/pawn/notation validation remains in place.
- Allow valid promoted material (including five rooks); do not simply prohibit
  extra rooks or queens. This is engine-input validation, not a full retrograde
  proof that a position can arise from the initial board.
- Validate restored selections and variation roots as well as the PGN.
- On Android 11+, consult the latest process-exit reason before automatic
  restoration. Native/Java crashes, signals, failed initialization, ANR and
  nonzero self-exit open Home instead. Low-memory eviction, app updates and
  ordinary user stops do not count as crashes.
- Persist a process-specific restore marker before automatic restoration. An
  unfinished marker from another process provides a fallback when exit reports
  are unavailable. Normal backgrounding clears it; rebuilding a widget in the
  same process is not an interruption. A foreground process kill can therefore
  conservatively open Home on older Android versions.
- Recovery blocks automatic reopening without rewriting/deleting the checkpoint,
  recent-game archive, preferences or sampling files. Explicitly opening a saved
  game or starting a new session clears the block. Invalid saved positions still
  fail validation when opened manually. A short notice is localized in all ten
  languages; it is app-specific wording, with no direct Lichess equivalent.

## Regression coverage and release boundary

`test/unsafe_position_test.dart` checks the screenshot for both sides, malformed
input, impossible material, counter bounds, valid promotions and terminal
positions. It checks rejection before the native factory starts, queue recovery,
and the editor's Analyze/Continue actions. The first regression fails against the
unfixed validator (it returns an `AnalysisSession` instead of throwing).

`test/crash_recovery_test.dart` exercises interrupted restores, Android-reported
failure, unsafe PGN/selection/variation/review/game data, repeated launches,
real-file archive/checkpoint preservation, settings preservation and subsequent
opening of an unaffected game. `SessionRecoveryPolicyTest.kt` covers Android exit
reason classification in the ordinary native host-check job.

The ordinary Flutter suite, chess oracle, analyzer, localization and native host
checks must pass in both Stable and Preview. This does not prove that arbitrary
native failures are impossible. Before publishing a fix, qualify the exact
Android APK, repeat the edited-position scenario, and test an upgrade with a
persisted unsafe checkpoint on a device/emulator. Confirm Home is reachable and
existing games/settings remain available. Do not ask users to clear app data.

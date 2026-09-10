# Preview beta.14 / Mobile Maia 2.1 preparation

Date: 2026-09-10. Base: `c9df37d5e25ac431cb5bbdf90a2e9dc084b61b3c`
(`v2.1.0-beta.14`). This base includes the previous two hardening PRs; its only
change after the previous verification was the version bump.

Implementation commit: `3dbbd56` (`Fix variation Back navigation and shared PGN parsing`).

## Findings and corrections

### Back navigation stopped inside a variation and lost the move highlight

The supplied PGN reproduces the issue at `16. Qc3 Qf6`. Previously, Back moved
from Qf6 to Qc3 and then to an unselected index-zero position within that
variation. The button became disabled even though earlier main-line moves
existed.

Back now selects the actual parent node at the branch point. The sequence is
`16... Qf6 → 16. Qc3 → 15... Nc6 → 15. f4`. Nc6 is highlighted on returning to
the main line, including its board squares. Forward follows the selected
parent line (`16. f5`), and nested variations return through their own parent
before reaching the main line. Root alternatives return to the initial
position. Navigation does not edit, delete, or promote any variation.

Five initial widget regressions failed before the navigation fix and passed
afterward. The expanded nine-test suite also checks custom black-to-move FENs,
save/reopen with orientation, all 131 main-line plies forward and backward,
40 repeated branch exits with comments, and a late engine reply after leaving
its variation. Highlight assertions check that exactly one move is selected
at each non-initial position.

### Shared PGN import could fail by capturing UI state in an isolate closure

The first release APK built during this pass reproduced a separate failure
when the supplied PGN was delivered via Android `ACTION_SEND` / `text/plain`.
The app displayed an `Illegal argument in isolate message: object is unsendable`
error. The captured object graph led from `_checkIncomingPgn`'s parser closure
back to `_GamePageState` and Flutter binding/animation state. Another callback
in that method captures the screen; Dart closures can share their captured
context.

`AnalysisSession.fromPgnAsync` now creates the isolate in a static helper whose
only input is the PGN string. Shared, pasted, and file-picker imports all use
that helper. Pasted import also checks that its screen is still mounted before
starting a new saved session after parsing. Parsing remains off the UI thread.

The mounted-screen shared-import regression failed before this correction.
All three import-route tests pass afterward, using the real background parser
and mocking only the native document bridge on the host.

## Completed host checks

- **204 Flutter tests passed** on the final implementation, including all prior
  regression tests and the 12 new navigation/import tests.
- **Static analysis: no issues.**
- **2 Python model-verification tests passed.**
- **10,000 fresh independent chess positions**, seed `20260911`, passed legal
  move, transition, mate/stalemate, PGN, board-frame, tokenization, and complete
  4,352-entry move-vocabulary comparisons against python-chess.
- Existing **43,200 sampling comparisons**, **1,000-operation engine queue
  stress**, saved-state failure recovery, **1,000-game archive**, and simulated
  BLE failure tests all passed in the full suite.
- python-chess independently accepted all **146 move nodes and four side
  branches** of the user-supplied PGN, with checkmate at the main-line endpoint.

## Android checks

**Six Android integration tests passed** on the API 36 ARM64 emulator with the
real bundled Maia model and Stockfish. These cover policy-vector inference,
the reported move-16 variation and highlighted main-line return, the paste-PGN
dialog crossing the real isolate boundary, Stockfish navigation/graph analysis,
a full reported-game replay, and checkmate UI handling.

The initial release-mode Android sharing failure was retained as a local
screenshot and reproduced in the host shared-import test before the correction.
Final release artifact and smoke-test evidence is recorded with the PR.

## Scope

The code changes are confined to analysis navigation and background PGN import.
No dependency, model, strength-setting, signing, or package-identity changes
are part of this patch. These are software checks on the Mac and Android
emulator; physical phone and Chessnut behavior remain the user's hardware test
scope. This report is evidence for the tested preview source, not a guarantee
that every edge case is covered or a replacement for stable-package release
signing and publication.

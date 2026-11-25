# Grand Kingdom support and testing

Current policy: Grand Kingdom is supported in Stable 2.6, Preview and Dev,
with identical Dart/native support policy in both source repositories.
**Passed user acceptance testing.** Pegasus has been withdrawn from all channels; see the
[support decision](decisions/2026-11-22-electronic-board-support.md). Dated
historical channel descriptions below do not override that decision.

Preview testing started in [Preview 2.6.0-beta.1](https://github.com/Dash1971/maia-chess-android-preview/releases/tag/v2.6.0-beta.1), updated 15 November 2026.
Tracks [Preview #27](https://github.com/Dash1971/maia-chess-android-preview/issues/27).

## Stable 2.6 promotion — 22 November 2026

Grand Kingdom support is included in the Stable 2.6 promotion draft, following
successful Preview testing. Both Dart and native policies permit Stable and
unflavored Stable builds, alongside Preview/Dev. DGT Pegasus is withdrawn from every channel;
automatic diagnostics and their local export remain Dev-only.

This changes the shipping scope, not the motor protocol or recovery rules.
The full legal promotion move, explicit replacement confirmation, current-session
motor guards, standard-position setup and phone-continuation fallback are
preserved. Stable release qualification has not run for this draft; no APK or
store update has been published. Historical Preview decisions and scenario
records below remain evidence, not a reason to omit the authorized promotion.

## User acceptance — passed, recorded 22 November 2026

Grand Kingdom has passed user acceptance testing and is accepted for Stable 2.6.
Physical testing and subsequent successful Preview play are recorded in
[Stable issue #15](https://github.com/Dash1971/maia-chess-android/issues/15),
including the [capture/calibration follow-up](https://github.com/Dash1971/maia-chess-android/issues/15#issuecomment-6863134393)
and [79M Preview feedback](https://github.com/Dash1971/maia-chess-android/issues/15#issuecomment-6875973632).

This status supersedes the earlier pending-acceptance checklists and experimental
classification. The dated reports below remain historical evidence; an older
“not tested yet” entry is not the current acceptance status. The feedback is not
an exhaustive scenario-by-scenario certification of every firmware or promotion
variant. Further regression coverage is welcome and does not reopen user acceptance.
Normal exact-source release qualification remains required before publication.

## Current owner feedback — 14 November 2026

[The owner’s follow-up](https://github.com/Dash1971/maia-chess-android/issues/15#issuecomment-6863134393) reports many games with Mobile Maia and the
referenced Python implementation. They checked the vendor app and confirmed
firmware **36v5**. They attribute the earlier wrong/missed capture removals to
**hardware drift/calibration and an uneven surface**: after many moves without
calibration at game start, pieces gradually leave their square centers. They
report that it works well overall. This supersedes the earlier unexplained
capture-failure status; those symptoms are not current known app capture defects.

The owner then [switched to the yellow-icon 79M Preview and reported a successful
game](https://github.com/Dash1971/maia-chess-android/issues/15#issuecomment-6875973632).

The two October PGNs remain regression/reference material. No software capture
fix is being claimed, and the owner’s report does not establish every board or
firmware. The overall user acceptance status is passed; the replies are not an
itemized record of every edge case. Firmware is now known; the exact
app build for the hardware-drift follow-up and a specific phone model were not
supplied and must not be inferred from the earlier Dev report.

## Preview 2.6 testing decision — historical, 13 November 2026

The requester authorized experimental Preview publication while the capture
reports were still unexplained. The 14 November hardware attribution above
supersedes that problem status. Full automated Preview release gates still
apply. Stable/Dev APKs are unchanged; DGT remains Dev-only. Preview 2.5 artifacts
exclude Grand Kingdom. That historical designation is superseded by the supported-device decision
above. Additional physical scenarios track coverage, not a channel restriction.

## Historical physical evidence — 28 October 2026

The results in this dated table describe that initial report only. They do not
override the passed user acceptance status above.

[Tester report, 2026-10-28](https://github.com/Dash1971/maia-chess-android/issues/15#issuecomment-6468925765):
Square Off Grand Kingdom, Android 17 / SDK 37, app `2.4.0-alpha.2-dev`.
The supplied diagnostic says `build=240` (published alpha.2 records 2402); retain
this discrepancy rather than inferring the installed APK identity. Device field
was `ZZZ`; specific phone model and firmware were not supplied in that initial report.
The later firmware confirmation is 36v5, as recorded above.

| Scenario | Reported result |
| --- | --- |
| Discovery, connection and standard setup confirmation | OK |
| Ordinary play as White and Black, Maia opening/motor replies | OK for the grouped instructions |
| Captures | Initially OK, then two failures reported; owner later attributed them to hardware drift/calibration (current feedback above) |
| Castling | Initially OK; no isolated castling failure reported |
| Human promotion | OK |
| Screen and physical position agreement | Initial positive report, then capture symptoms; owner later explained hardware drift and reported good overall operation |
| En passant | Not tested yet |
| Background/resume, connection loss, phone continuation without repeat movement | Not tested yet |
| Reset, multiple-board discovery, denied permission, Bluetooth/power interruption | Not established |

This initial report concerns one Grand Kingdom on an older Dev build. Later
79M Preview feedback is recorded above. It does not establish support for other
Square Off products or every firmware.
Protocol provenance remains in
[ELECTRONIC_BOARD_NATIVE_PROTOCOL.md](ELECTRONIC_BOARD_NATIVE_PROTOCOL.md).

### Historical capture reports — hardware explanation supersedes earlier blocker

[Follow-up, posted 2026-10-28 at 18:29 UTC](https://github.com/Dash1971/maia-chess-android/issues/15#issuecomment-6477270546):
after more than ten games, the same owner reported two failures while playing
White. The first game's final `19...Bxf8` should remove White's knight on f8;
instead the board removed the pawn on f6. In the second game `7...Nxb4`
left White's pawn on b4. The owner is trying to reproduce the first failure.
At the time, these reports superseded the initial blanket positive summary.
The owner’s 14 November follow-up above now attributes the symptoms to hardware
drift/calibration. Keep the histories for regression/reference; do not treat
them as an unresolved software-capture blocker.

Reported game A (`Result "*"`):

```pgn
1. e4 e5 2. Nf3 d6 3. g3 Bg4 4. Bg2 Bxf3 5. Bxf3 Qe7 6. O-O Qd8 7. Nc3 Nc6 8. b3 Nd4 9. Bb2 Nxf3+ 10. Qxf3 f6 11. Rfe1 Ne7 12. a4 Nc6 13. Nd5 Nd4 14. Bxd4 exd4 15. Qd3 c6 16. Nf4 Be7 17. Qxd4 O-O 18. Ne6 Qe8 19. Nxf8 Bxf8 *
```

Reported game B (`Result "0-1"`, player resigned):

```pgn
1. e4 e6 2. d4 c5 3. dxc5 Bxc5 4. Nf3 Qb6 5. Qe2 Nc6 6. c3 d6 7. b4 Nxb4 0-1
```

Expected final engine coordinates are `e7f8` and `c6b4`, respectively. Neither
history contains a promotion; game B also contains no castling. Assisted
promotion therefore does not address these ordinary capture failures. Both PGN
headers label Black `Maia-3 79M (1300)`. The current PGN exporter in
`lib/src/play.dart` uses a fixed `Maia-3 79M` label, so this does not establish
the APK/model identity or contradict use of the smaller Dev model. Record the
actual version/source and model diagnostics for each reproduction.

Source review: the current adapter follows the pinned reference's standard-start
`RSTVAR` → `GAMEWHITE/GAMEBLACK`, legal-human-input `OK`, and four-coordinate
engine move flow. There is no established separate capture command. The PGNs do
not show actual BLE frames, motor timing or the first physical divergence, so
they cannot distinguish app ordering/state, firmware bookkeeping and mechanical
failure. Do not add a guessed capture opcode, delay, reset or command retry.
Local position confirmation does not resynchronize firmware piece bookkeeping.
A legal following move is also insufficient to prove the entire physical board
matches the game after a missed/wrong capture.

If a mismatch recurs on a level, calibrated board:

- Replay each complete history from confirmed standard setup; do not jump to a
  manually arranged midgame position. Game B is the shorter first case. A normal
  Maia game need not select the same replies; exact replay may require a later
  controlled Dev scenario using the normal human/engine command path.
- Compare screen and physical board after every move, especially `7...Nxb4`
  and `19.Nxf8` / `19...Bxf8`. Record the first divergence, which piece moved,
  which piece was removed, and whether motors had stopped before the next input.
- Record firmware, phone/Android, actual APK version/source/model, fresh-start
  versus successive-game behavior, and any intervening background/disconnection.
  If practical, provide a short video and reviewed app diagnostics. The existing
  `tool/board_capture` recorder is Chessnut-only, not a Grand Kingdom trace tool.
- After a mismatch, wait for stopped motors and continue on the phone. Do not
  retry the move, send a midgame reset or assume physical rearrangement repairs
  firmware state. Start any later board test with explicit standard setup.

## Current channel behavior

| Board | Preview 2.6 | Dev | Stable / unflavored / unknown |
| --- | --- | --- | --- |
| Chessnut | Allowed | Allowed | Allowed |
| Grand Kingdom | Supported | Supported | Supported in Stable 2.6; unknown packaging channels blocked |
| DGT Pegasus | Withdrawn | Withdrawn | Withdrawn |

Dart event/candidate handling and native discovery, remembered-device connection,
configuration, writes and motor methods enforce this boundary. Native motor
methods require the current ready Grand Kingdom session. Legacy Chessnut saves
continue to select only Chessnut boards.

Enable Electronic board, connect and explicitly confirm the standard physical
position. Games use Unlimited time. Engine movement is sent once; a successful
write or uncorrelated `OK` never proves physical completion. For ordinary moves, a legal subsequent physical move or explicit full-position
reconciliation can acknowledge completion. Promotions always require explicit
piece-replacement confirmation.
Starting a new game still requires physical setup. Interrupted movement,
midgame motor-board restoration and takebacks require phone continuation.
Maia promotions use the assisted flow below.
There is no verified stop/cancel opcode, automatic replay or arbitrary-position
motor restoration.

## Assisted Maia promotion (29 October)

The app keeps the full legal UCI move, including `q/r/b/n`, in the game, PGN and
pending physical-move checkpoint. Before any motor command the checkpoint is
saved. Only the four square coordinates are sent to the unchanged native motor
method, matching `make_move()` in the pinned square-off-remote reference. No
new promotion-piece opcode, motor-completion response or cancellation command
is assumed.

Once the write callback succeeds in the same foreground session, the banner
names the destination and Maia's selected piece. Its confirmation action opens
instructions to wait for stopped motors, replace the pawn and inspect the entire
position. The dialog includes a frozen full-board diagram of the actual promoted
position, independent of move-history selection; confirmation returns the main
board to the live position. Continue stays disabled until the user checks the explicit replacement
confirmation. Cancel leaves the promotion pending; Play in app preserves the
logical game and exits board control. An `OK`, a subsequent legal human move or
a synthetic position event cannot confirm a promotion. Human input stays blocked
until explicit confirmation; the stored promotion suffix never gets discarded.

A successful write is only a transport milestone. If delivery is interrupted or
fails, the pending move is retained and phone recovery is offered without retry.
If the same connection survives a background/resume after delivery, the user
must reopen and explicitly confirm the physical position; an old dialog or late
confirmation cannot advance the game. Confirmation calls are serialized. Restart
and disconnection keep the full pending move and never replay it; live motor-board
restoration remains unavailable. Even a game-ending promotion retains its
physical checkpoint across restart, and its automatic result dialog waits for
confirmation or explicit phone continuation.

Automated policies test the logical/transport state machine. They do not prove
that the firmware handles physical replacement or subsequent underpromotion
moves correctly. User acceptance has passed based on physical testing; automated
checks remain separate evidence and do not certify every firmware or variant.

## Optional extended regression checks

User acceptance has passed. These checks are suggestions for additional coverage,
not outstanding release-acceptance requirements. The older Dev-only advice is
historical. Use a level surface and fresh game-start calibration, then record
the exact app build, firmware, phone/Android and scenario actually exercised.

1. Retain ordinary play/captures as regression checks on a level, calibrated
   board. The earlier symptoms have an owner-reported hardware explanation;
   reproducing and fixing an assumed app defect is not a prerequisite. Record
   en passant separately in any further scenario-specific reports.
2. Try a Maia queen promotion first. Verify one pawn movement, the correct
   destination/piece instruction, disabled continuation before the checkbox,
   manual replacement, full-position confirmation and normal subsequent play.
3. Repeat non-capturing and capturing promotions for Maia as White and Black.
   Then test rook, bishop and knight underpromotion. Verify the firmware does not
   silently impose queen behavior or lose synchronization on subsequent moves.
4. Cancel/reopen the prompt; try background/resume while waiting for replacement,
   disconnect when motors are idle, restart with a pending promotion and choose
   phone continuation. Verify the same full promotion/game remains and there is
   no repeated motor movement. Report physical position versus screen separately.

Start from the standard setup. Arbitrary-FEN motor initialization is not verified;
do not use manual board rearrangement as a shortcut. A complete, repeatable
underpromotion matrix may need a separately labelled maintainer-controlled Dev
scenario build from the standard position. The deterministic automated test
scripts are not a claim that normal Maia play will quickly produce every case.

## Future development and release qualification

User acceptance is complete. Retain the two historical PGNs as regression cases;
investigate any new mismatch on a level, calibrated board by recording the first
physical divergence before assigning a cause or changing the protocol.

Full midgame reconnection and motor-board takebacks remain outside the supported
workflow. Any future implementation needs a reliable reconciliation/firmware
protocol. Never infer motor cancellation or reset completion from `RSTVAR` or
automatically replay movement commands.

[Preview #27](https://github.com/Dash1971/maia-chess-android-preview/issues/27) is
closed as delivered. [Stable #15](https://github.com/Dash1971/maia-chess-android/issues/15)
tracks delivery to Stable, not an outstanding physical user-acceptance gate.
Before publishing, follow the applicable channel's [release procedure](RELEASING.md),
including exact-source Linux reproduction, real 79M native checks and signed
upgrade/data retention. Dev publication, if requested later, uses its separate
procedure. Passing user acceptance does not substitute for these release checks.

## Earlier Stable counterpart review (historical)

Stable main was inspected at `0957d87` on 2026-10-28. Its Dart policy excludes
Grand Kingdom/DGT outside Dev and its native bridge retains the Dev-only motor
guard. No companion Stable feature PR applies: this request is for the Preview
2.6 development cycle. No shared build, CI or cleanup helpers change. Stable
promotion and publication require their own acceptance and release task.

## New message terminology

The four assisted-promotion messages are Mobile Maia motor/reconciliation
instructions, with no direct Lichess equivalent. They use the existing pinned
localized piece names and algebraic square identifiers. All ten catalogs have
native-language prose; catalog/terminology and 320px/200% dialog checks apply.
Native-speaker/hardware acceptance is still separate from automated layout checks.

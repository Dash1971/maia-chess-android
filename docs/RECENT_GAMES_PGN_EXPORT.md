# PGN import and export

Stable 2.6 draft: this behavior is promoted from Preview. The recorded tests,
renders and APK qualification below describe Preview, not a newly qualified
Stable build. Stable checks and changed screenshots remain pending.

Implementation for [#225](https://github.com/Dash1971/maia-chess-android-preview/issues/225),
published in [Preview 2.6.0-beta.3](https://github.com/Dash1971/maia-chess-android-preview/releases/tag/v2.6.0-beta.3). Stable promotion remains separate.

Long-press a game, or choose Select games from the Recent Games menu. Select one
or more games, or use Select all. **Export games** opens the existing **Save PGN
file** and **Share PGN** choices. Each produces a single multi-game `.pgn` file.

## Import or transfer games

In the Analysis Board menu, use **Open PGN file** to choose a `.pgn` document,
or **Load PGN** to paste its text. Android **Open with** and sharing a PGN
attachment to Mobile Maia use the same importer. To transfer a collection to
another installation, export selected games from Recent games, move/share the
file yourself, and open it in the receiving installation.

- A single-game document opens in Analysis Board, as before.
- A collection adds new games to Recent games. The current game and recovery
  settings remain intact; imported unfinished games open paused.
- Identical saved PGNs and repeats within the incoming file are skipped. Only
  line endings and outer whitespace are ignored. Different metadata,
  comments, clocks or variations produce separate records.
- A progress bar accompanies the operation. Completion reports new games and
  duplicates skipped; an entirely duplicate collection adds zero records.
- The complete collection must validate and save successfully. An invalid game,
  oversized file or storage failure does not expose a partial import.

Both import and export allow **5 MiB / 5,242,880 UTF-8 bytes**. The app labels
this as **5 MB**. The count that fits depends on game length and annotations.
PGN transfers games and annotations, not app settings or live clock/motor
checkpoints. Everything stays offline, with no automatic upload.

## Ordering and content

Export follows the current Recent Games display order, regardless of selection
tap order. The repository orders by original played day, newest first; known
start times and then record IDs resolve ties. Unknown historical dates remain
unknown. Export does not sort by save/update time or fabricate PGN metadata.

Each selected record is read again through a read-only repository method.
Export never calls `open()`, which would archive/replace the active game. It
does not write snapshots, update history, delete games or change restoration
preferences. The current PGN snapshot already contains the individual game's
supported export data. The existing single-game parser/serializer validates
each game's tokens, starting FEN and all variations and preserves its available
headers, result, comments, NAGs and clock annotations. A record containing more
than one game is rejected rather than silently dropping the later game.

Games are separated by a blank line, including a final blank line. No default
historical player names, dates or time controls are invented. Completed games,
unfinished `*` games and supported custom starting positions use the same path.

## Limits and failures

- The complete file is validated before opening Android's save/share UI. A
  missing, unreadable, unsupported or invalid selected record fails the entire
  operation; no selected game is silently omitted.
- Assembly reads/validates one game at a time, with parsing in a background
  isolate. Only the combined bounded PGN is retained by the export builder.
  Recent games retains its file format and sorting; reading/decoding now runs in a background worker.
- Save/share exports allow **5 MiB (5,242,880 UTF-8 bytes)**, including inter-game
  separators. This is a byte limit, not a game-count limit. The UI calls it
  **5 MB**. Imports, including Open with/shared attachments, and the individual
  game parser now use the same **5 MiB** limit. Importing a collection adds each new
  game to Recent games and skips identical PGNs, so exports can transfer games between installations.
  Importing a single game keeps the existing open-in-analysis behavior.
- A selected game over the individual 5 MiB parser limit fails with its own
  localized message, distinct from the combined 5 MiB collection error. Save and
  Share both stop before opening Android UI, retain selection and allow retry.
- Preparation stops as soon as adding a game would exceed the export limit,
  before opening Android's save/share UI. No partial file is saved/shared and
  there is no silent omission or automatic splitting. The message is:
  **Selected games exceed the 5 MB export limit. Select fewer games and try again.**
  Selection is retained so the user can deselect games and retry. A 10,000-game
  selection follows this same byte-based check; there is no fixed promise of
  how many games fit. Games with clocks, comments and variations take more space.
- The 5 MiB export cap replaces the inherited 2 MiB export cap as a bounded,
  small change. Export still assembles a string in memory and creates temporary
  encoding/channel copies, so peak memory exceeds the file size. Streaming and
  automatic multi-file batches are outside this change.
- An empty selection disables the action. Repeated/stale callbacks cannot start
  a second export or alter the selection while it is running. Other actions and
  navigation are blocked while preparing the file or awaiting the picker.
- Success, picker cancellation and failure preserve the selection. Cancellation
  shows no success message. A failed export leaves the screen usable for retry.

The outgoing share chooser excludes Maia’s own receiving activity, so Android
cannot automatically re-import a selected game and replace the active session
when Maia is the only installed PGN receiver. Users can still import files
explicitly through the existing import actions.

Android continues to use the existing document picker and FileProvider chooser,
temporary URI grants and MIME type. Native import/export guards share one
5 MiB byte limit. There is no new permission, network dependency,
model or automatic upload.

## Verification

`test/recent_games_pgn_export_test.dart` covers one/multiple/all selection,
display ordering, round-trip metadata/annotations/variations, custom FEN,
unfinished games, missing/invalid/multiple-game records, UTF-8 and aggregate byte
limits (including exactly 5 MiB and one byte over), a 200-game collection,
an oversized 10,000-game selection, matching 5 MiB import rejection,
read-only repository files, save/share method
dispatch, cancellation, native failure/retry and stale callbacks. All ten
languages exercise the selection/export menu and size-error message at 320 px
with 200% text.

Existing Recent Games failure/recovery, repository and PGN import tests remain
in place. Host method-channel tests cover the Dart save/share/cancel contract;
they do not certify an OEM document provider or third-party PGN application.
Android device smoke testing remains a release check. The feature PR is merged;
exact-source release checks and Android smoke results are recorded below.

Historical beta.3 signed-APK qualification covered small Select all, cancel/retry, 5 MiB overflow, a 3.66 MB UTF-8 save and separate-UID share, unchanged source hashes, the native 2 MiB import guard and sole-target self-share regression. [Release evidence](https://github.com/Dash1971/maia-chess-android-preview/blob/e162a61e995452b748e5f85d710c6f7dab2ab24a/docs/releases/preview-2.6.0-beta.3.md).

## Collection import follow-up — 22 November 2026

File picker, pasted PGN, Android Open with and shared attachments use the same
validated collection parser. It recognizes game boundaries outside comments,
headers and variations, validates every game off the UI thread, and rejects
invalid later games instead of silently importing only the first one.

New records are staged privately, then published by one directory rename into
Recent games. A failed write does not expose a partial collection. Existing
records, the active checkpoint and crash-recovery preferences stay unchanged.
Imported records retain PGN names, dates, results, comments, clocks, variations
and starting positions. Equal-date imported records retain their source order.
A progress bar covers validation (indeterminate), duplicate scanning and staged writes (determinate). The completion message reports imported and skipped counts. Work runs off the UI isolate. Back cannot dismiss an in-progress import; success or failure closes the progress dialog.

Import skips identical PGN content already present in saved games or earlier in the same collection. Only line endings and surrounding whitespace are normalized for comparison. Headers, comments, variations and clocks remain part of the comparison: differently annotated or identified copies are kept. Re-importing the same collection adds no extra copies. Completion reports imported and skipped counts. Single-game opening is unchanged.
PGN transfers games and annotations, not app settings or live clock/motor session
checkpoints. This is not a complete app-data backup. Imported unfinished games
open paused; no physical board connection or movement is restored from PGN.

The 5 MiB limit is measured on actual UTF-8 file bytes. Export includes serialized
headers and separators; source text just under the cap can grow during export
normalization and must still pass the final combined-byte check. There is no
additional game-count cap. The former 2 MiB import cap and first-game-only
collection behavior are historical, superseded by this follow-up.

Host regression coverage includes a collection over 2 MiB, the 5 MiB boundary,
UTF-8, fake boundaries inside comments/variations, invalid later games, atomic
failure, active-game preservation and imported-record open/delete after restart.
Android document-provider checks remain pending the beta.11 build phase.

## Interrupted imports and large collections

On first repository access after startup, abandoned `.import-<timestamp>-<random>.pending` directories are removed. Cleanup ignores links, unrelated directories and normal save checkpoints. The coordinating UI isolate tracks live imports, protecting them from cleanup by another repository instance there. Committed imports remain untouched.

Import file work and Recent games reading/decoding run in background workers. Recent games still uses the existing files and sort order; this change adds no database, persistent index or cache. The collection scale regression exercises 10,000 distinct games near 5 MiB, a repeat import, progress updates, Recent games and event-loop responsiveness. Host measurements are recorded separately from required installed Android checks.

See the [10,000-game host measurements and device-test limits](verification/pgn-collection-import-2026-11-22.md).

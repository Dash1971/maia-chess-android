# PGN import and export

Released in Stable 2.6.0 and Preview 2.6. Recent games imports and exports
collections; Analysis Board opens the first game. Both directions allow 5 MiB.
See [saved analysis](PGN_ANALYSIS.md) for optional evaluation/quality annotations
and [Stable qualification](https://github.com/Dash1971/maia-chess-android/blob/main/docs/release-notes/v2.6.0-verification.md) for the released APK checks.

Long-press a game, or choose Select games from the Recent Games menu. Select one
or more games, or use Select all. **Export games** opens the existing **Save PGN
file** and **Share PGN** choices. Each produces a single multi-game `.pgn` file.

## Import or transfer games

In **Recent games → ⋮ → Import PGN**, choose a `.pgn` document. The action is
available even when the list is empty. It imports every game, including a
single-game file, into Recent games without opening or replacing the current
game. To transfer games between installations, export from Recent games,
move/share the file yourself, and use Import PGN in the receiving installation.

In **Analysis Board → ☰ → Open PGN file**, only the first game opens for
analysis. **Load PGN** behaves the same way for pasted text. If there are more
games, a notice explains: “Only the first game was opened. To import all games,
use Recent games → Import PGN.” Later games are not imported or validated by
this analysis-only action; a malformed later game does not prevent the first
valid game opening. The 5 MiB limit still applies to the entire document.

Android **Open with** and sharing a PGN attachment to Mobile Maia retain their
existing routing: one game opens for analysis; a collection imports into Recent
games using full-file validation and duplicate checking.

- A collection adds new games to Recent games. The current game and recovery
  settings remain intact; imported unfinished games open paused.
- Identical saved PGNs and repeats within the incoming file are skipped. Formatting changes made by the exporter are normalized for comparison. Different metadata,
  comments, clocks or variations produce separate records.
- Imports lasting more than 300 ms show a progress bar from validation through saving; quick imports finish without a dialog or dimming flash. Completion reports new games and
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
  Recent games imports single games as saved records too; Analysis Board opens
  only the first game, with collection guidance when appropriate.
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

Recent games file import, Android Open with and shared collection attachments
use the validated collection parser. Analysis Board uses its first-game-only
parser instead. It recognizes game boundaries outside comments,
headers and variations, validates every game off the UI thread, and rejects
invalid later games instead of silently importing only the first one.

New records are staged privately, then published by one directory rename into
Recent games. A failed write does not expose a partial collection. Existing
records, the active checkpoint and crash-recovery preferences stay unchanged.
Imported records retain PGN names, dates, results, comments, clocks, variations
and starting positions. Equal-date imported records retain their source order.
A delayed progress bar covers validation, duplicate scanning and staged writes without resetting between phases. The completion message reports imported and skipped counts. Work runs off the UI isolate. Back cannot dismiss an in-progress import; success or failure closes the progress dialog.

Import skips identical PGN content already present in saved games or earlier in the same collection. The same PGN serializer used by export normalizes formatting before comparison. Headers, comments, variations and clocks remain part of the comparison: differently annotated or identified copies are kept. Re-importing the same collection adds no extra copies. Completion reports imported and skipped counts. Single-game analysis opening is unchanged; explicit Recent games import stores
a single game in the list instead.
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
Preview beta.11 production-signed APK checks passed for Android document save/open,
content-URI import, paste/share, cancellation, export/re-import duplicate checking,
invalid/oversized input, retained selection, interrupted-import recovery and a
10,000-game near-5-MiB import with progress and Recent games after restart.
See [Preview qualification](https://github.com/Dash1971/maia-chess-android-preview/blob/main/docs/releases/preview-2.6.0-beta.11.md).
These are ARM64 emulator results, not universal provider/OEM coverage or Stable
APK qualification. [Stable 2.6.0 qualification](https://github.com/Dash1971/maia-chess-android/blob/main/docs/release-notes/v2.6.0-verification.md) records
the separate Stable checks.

## Interrupted imports and large collections

On first repository access after startup, abandoned `.import-<timestamp>-<random>.pending` directories are removed. Cleanup ignores links, unrelated directories and normal save checkpoints. The coordinating UI isolate tracks live imports, protecting them from cleanup by another repository instance there. Committed imports remain untouched.

Import file work and Recent games reading/decoding run in background workers. Recent games still uses the existing files and sort order; this change adds no database, persistent index or cache. The collection scale regression exercises 10,000 distinct games near 5 MiB, a repeat import, progress updates, Recent games and event-loop responsiveness. Host measurements are recorded separately from required installed Android checks.

See the [10,000-game host measurements and device-test limits](verification/pgn-collection-import-2026-11-22.md).

## Export/re-import duplicate comparison

Duplicate detection compares supported PGN content in the same format used by export. An exported collection can be re-imported on the same installation without adding another copy because of spacing, move-number formatting or comment padding. Original saved PGNs and checkpoints are not rewritten for comparison.

Different header values, comments, clock annotations and variation trees remain separate. The check conservatively compares original text when serialization would discard information, such as semicolon comments, escape lines, repeated headers or conflicting declared results. An exported copy that lost such information is considered different; importing an identical original still skips it. Malformed legacy records cannot hide valid incoming games. Single-game opening and the shared 5 MiB limits are unchanged.

## Parsing progress and quick imports

A longer import displays progress after **300 ms**. Quick single-game and collection imports finish without showing or dimming a dialog. The existing input and Back guard applies from the start; successful completion or failure removes it. The progress display remains safe if the source screen is disposed.

Validation runs in its worker and reports the input position after each complete game, including variations, has validated. Reports are throttled to avoid flooding the UI. One continuous bar reserves its first half for validation and its second half for duplicate checking and staged writes; it does not jump back to zero at the handoff. The percentage describes work phases, not remaining time. A failed later game never reports successful validation or publishes a partial collection. The worker progress stream is drained and closed before the next phase. Limits and duplicate matching are unchanged. Explicit Recent games import saves
every game, while Analysis Board opens only the first game.

## Save-transition duplicate regression — 23 November 2026

A host regression reproduced a duplicate without any PGN import: backgrounding
while returning Home could autosave a finished game after the active checkpoint
was cleared, assigning a second saved-game ID to identical content. Autosaves
are now suspended while that transition commits the final snapshot and releases
the game. The guard resets on success or failure so retries remain possible.
Existing saved games are not silently merged or deleted.

The supplied 119-entry export contains 114 unique PGNs and five exact repeated
entries. Four pairs include identical millisecond clock annotations; the fifth
is untimed. This supports duplicate saved copies, not merely repeated opening
moves. The file alone cannot establish which historical action created them.
The reproduced save race is a concrete possible cause, rather than proof of the
origin of those five records. Dates and annotations remain part of import
identity; otherwise identical games with different dates are kept.

See the [host verification record](verification/pgn-import-entry-points-2026-11-23.md).

<a id="optional-saved-analysis--stable-26-candidate"></a>
<a id="optional-analysis-annotations--preview-beta13"></a>

## Optional saved analysis

The [saved-analysis feature](PGN_ANALYSIS.md) ships in Stable 2.6.0 and Preview
beta.13. **Include analysis**, checked
by default above Save/Share in the selected-games export menu, controls saved
evaluations and move-quality symbols in the exported copy. Unchecking removes
those from each selected game before the combined 5 MiB check. Prose, clocks,
variations and other positional annotations remain; stored games are unchanged.
The single-game Save/Share/Copy menu offers the same option, with stripping in a
background worker. Different annotations remain part of duplicate identity.
Older Stable versions do not gain this behavior without updating to 2.6.0 or later.

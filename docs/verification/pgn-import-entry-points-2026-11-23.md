# PGN import entry points and duplicate-save investigation — 23 November 2026

## Supplied export

Read-only input: 178,733 bytes; SHA-256
`b36fe1f2820ef1e537ef71875e447201acf43680200fd73b704b36f1540deae4`.
The private PGN and its moves are not included in this repository.

The production parser found 119 entries and 114 unique PGNs. There are five
exact duplicate copies, including headers, result, annotations and clock values.

| Entries in file (one-based) | Original played date | Main-line half-moves | Identical clock annotations |
| --- | --- | --- | --- |
| 44 / 47 | 2026/10/14 | 83 | 83 |
| 45 / 48 | 2026/10/14 | 67 | 67 |
| 53 / 56 | 2026/10/13 | 171 | 171 |
| 54 / 57 | 2026/10/13 | 17 | 17 |
| 89 / 90 | 2026/10/02 | 120 | 0 (untimed) |

Four pairs match down to millisecond clock values, supporting copies of the
same saved games rather than independent tests of the same opening. Dates are
part of the PGN identity; playing on another day should produce another date.
An exact saved copy retains the original game's date. The PGN does not contain
record IDs or write history, so it cannot establish the historical cause.

With the real importer in temporary storage:

- Empty repository → 114 imported, 5 duplicates skipped.
- Delete all → repository empty → restore the original file → 114 imported,
  5 duplicates skipped.
- Export the cleaned 114-game collection → re-import → 0 imported, 114 skipped.

## Reproduced save bug

`session_home_duplicate_test.dart` holds the real Home transition just after
its active-session tombstone is committed, then sends an Android inactive
lifecycle event while the old game is still mounted. Before the fix the same
finished game is autosaved under a newly generated ID, yielding two Recent
games records with matching PGNs. No import is involved.

The fix suspends routine game autosaves for the duration of the Home
save/clear transition. The final game snapshot is still explicitly saved once,
and the guard is released in `finally` so a failed save can be retried. After
the fix the regression retains one original record and no active game.
This is a demonstrated possible cause of historical duplicate copies, not proof
that it produced all five pairs in the supplied file. Existing records are not
automatically merged or deleted.

## Import behavior

- Recent games → ⋮ → Import PGN is available even on an empty list. It saves
  every validated game, including a single game, skips duplicates, reports
  counts and refreshes the list. Current play/recovery state is preserved.
- Analysis Board → Open PGN file or Load PGN opens only the first game and,
  for a collection, explains where to import all games. An invalid later game
  cannot block the first valid game opening; the whole file still has a 5 MiB cap.
- Android Open with/shared attachments retain their existing routing.

Regressions cover the first-game file and paste paths, annotations/variations,
invalid later games, collection cancellation/failure, single-game Recent import,
current-game preservation, duplicate/date identity, the Home autosave race,
large collections and navigation. The new menu and notice are exercised in
all ten locales at 320 px and 200% text size.

Host checks are separate from installed Android document-provider and lifecycle
verification. No Android builds, Actions, LFS downloads or publication are part
of this change. Exact-source release qualification remains pending.

## Host validation result

Both Stable and Preview passed 150 focused committed host regressions plus a
separate supplied-file reproduction. The first combined run had 148 passes and
three test expectation/timing failures while adapting the old collection UI
tests. After updating those expectations and awaiting the Analysis replacement,
the 39-check affected set passed in each repository, including all three.
The 10,000-game near-limit import/re-import and list responsiveness check passed
in both. Dart analysis reports no issues; all 472 messages in ten catalogs pass
localization contracts and pinned terminology checks. The private-file harness
and its temporary storage were removed; no private game collection is committed.

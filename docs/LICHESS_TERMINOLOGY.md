# Lichess terminology baseline — 2026-10-06

Mobile Maia follows Lichess as its baseline for clear, uncluttered chess UI/UX
and free/open-source design philosophy. Consistent terminology is part of that
approach. Lichess is authoritative for direct equivalents in **all ten supported languages**.
This applies to chess terms and matching UI actions, not to Mobile Maia's engine
behavior or analysis algorithms. Maia-specific text still needs its own translation.

## Source and scope

The reviewed source is [Lichess Mobile commit
99dd3e0e4859afc7de37290b3f1905045af92004](https://github.com/lichess-org/mobile/tree/99dd3e0e4859afc7de37290b3f1905045af92004/lib/l10n).
Use its `app_en`, `app_ja`, `app_zh`, `app_ko`, `app_es`, `app_de`, `app_fr`,
`app_ru`, `app_hi`, and `app_pt_BR` ARB catalogs. Our single `pt` catalog is
Brazilian Portuguese; `zh` is Simplified Chinese. Spanish uses Lichess's single
Spanish catalog, without inventing a separate Latin American translation.

All 302 message IDs in each catalog were considered for direct equivalents.
The checked-in [reference](lichess-terminology.json) records shared concepts,
including unchanged terms, their exact upstream strings, and reasoned adaptations.
The rest are app-specific messages or context-dependent descriptions, not copied
wholesale from superficially similar Lichess text. This is an editorial terminology
review, **not native-speaker certification** or a promise that all prose is perfect.

## High-level changes

- Aligned settings, navigation, analysis, time-control and board-editor wording.
- Aligned results, draw offers, takebacks, and familiar game actions.
- Adopted Lichess's study annotation terms for the six existing move classifications.
  The En Croissant-based classifier and its thresholds are unchanged.
- Aligned premove terminology, including related help and accessibility text.
- Kept references to renamed screens consistent in saved-game messages.
- Reviewed English and piece names; their existing concise wording was retained.

All nine non-English catalogs changed. No locales were added, no settings or saved
formats changed, and no engine behavior changed.

## Context adaptations

The reference records every adaptation rather than silently overriding upstream:

- About means this app, not Lichess or a website (Japanese, Korean, Russian).
- Japanese promote-variation must describe promotion by one level; Mobile Maia
  exposes make-main-line as a separate action.
- Hindi collapse-variations must not say erase: folding a line does not delete it.
- Castling **rights** stays explicit in the board editor. Piece-picker names omit
  lesson-title articles. Premove headings omit the upstream parenthetical because
  their explanatory text is already separate.
- English keeps concise category headings and existing capitalization/context.
- Missing upstream translations keep the existing native-language wording.
- Hindi annotation labels omit stray punctuation/zero-width formatting, and the
  clear-board label corrects an upstream spelling error.
- Hindi variation actions describe alternative chess lines, rather than the
  upstream literal wording about diversity; continue-from-here corrects a spelling
  error. Game-phase labels use upstream `opening` / `middlegame` / `endgame`, rather
  than the puzzle-theme keys (which include a Hindi adjective for opening).

Do not copy Lichess wording when it would make a different action sound equivalent.
Conversely, stylistic preference alone is not a reason to depart from its vocabulary.
Match the action and grammar, not just the English text: our initial-position
`START` label is not the study-start command, and our Moves tab is not a Puzzle
Storm move count. Similarly, completed-game labels need the gender/number of a
single game, not a list of completed tournaments.

## Follow-up review after Preview beta.8

Reviewed all 302 messages in each of the ten catalogs again, including app-specific
sampling help, Chessnut recovery, saved-game messages and accessibility text. This
is an editorial review, not native-speaker approval. The follow-up makes 51 small
message corrections across the ten catalogs, including six English labels/statuses.

- Added missing direct equivalents for White/Black running out of time and the
  PGN-copied confirmation to the pinned reference (now 70 concepts). Missing
  upstream translations retain documented fallbacks.
- Matched Portuguese draw/resignation confirmations and Russian increment
  accessibility text to the terminology already used by their controls.
- Clarified Spanish board-sound help: the illegal-move beep follows a completed
  move, not a piece still being moved. Improved Japanese instructions for finishing
  a physical-board move and Korean analysis progress wording for completed positions.
- Corrected the Hindi grammar and chess-variation meanings described above; the
  game-phase labels now use the more directly applicable upstream keys.

The final pre-publication pass also aligned English Touch feedback and Takeback,
and English/French turn announcements. Existing punctuation, screen titles,
piece-picker articles and compact category headings have explicit context reasons
in the reference. Chinese turn messages retain the app’s consistent 你 form, and
Korean status messages address the player rather than copying a first-person label.

The Temperature/Top-P explanations were reviewed and retained. No gameplay,
engine behavior, saved-data formats, language selection or analysis logic changed.

## Maintenance and verification

`lib/l10n/app_*.arb` remains the translation source. The reference is a small offline
regression baseline, not a second localization system. Updating Lichess terminology
is a deliberate source change: pin a new commit, review matching keys and meanings,
update the reference and ARBs together, and explain any adaptation. Add newly
introduced direct equivalents to the reference; its checker cannot discover them.
Do not fetch upstream translations at build time or on a user's device.

Run:

```sh
flutter gen-l10n
python3 tool/check_localization.py --write-review
python3 tool/check_lichess_terminology.py
flutter analyze
flutter test
python3 -m unittest discover -s tool -p '*_test.py'
```

CI checks both the terminology baseline and the existing catalog/placeholder/CSV/
generated-code contracts. Localization widget tests cover all languages, compact
layouts and 200% text, including the longer classification labels. Real-device
fonts and native-language acceptance still require human review.

Lichess translation attribution is included in `THIRD_PARTY_NOTICES.md`, which is
bundled in the app's license information.

## Experimental electronic-board Dev messages

Added 28 electronic-board messages in all ten catalogs for device selection,
connection recovery, physical setup, ambiguous moves and hardware-button
confirmation. These are app-specific device operations; the pinned Lichess
reference has no direct equivalent for the complete messages. They reuse the
existing chess vocabulary for moves, positions, pieces and unlimited time where
the meaning applies. The standard physical starting arrangement is described
explicitly rather than copying a board-editor action label. Japanese uses the
established physical-setup term 初期配置; Hindi uses a natural sentence form
for the starting arrangement, rather than the upstream standalone label with
a trailing colon. Unlimited-time prose describes the absence of a clock; it
does not mechanically insert a standalone adjective into an instruction.

`NEW GAME` remains unchanged in every language because it names the physical
button printed on supported hardware. The surrounding instructions are translated,
including the two-press confirmation window. Bluetooth likewise retains its
protocol name. No new placeholders or English prose fallbacks were introduced.
The translations and review CSV remain provisional pending native-speaker review.

## Plain-language sampling guidance (Dev review)

Temperature, Top-P and Maia's human-move predictions are app-specific concepts.
The revised help uses examples rather than new preset controls, and distinguishes
likely human moves from objectively best moves. All ten catalogs retain the same
meaning. Decimal commas are used in the European-language examples where customary.
The Spanish temperature paragraph follows the native-speaker suggestion in
Stable #23; timed-premove help restores the missing clock condition while retaining
Lichess's existing “movimiento anticipado” terminology.

The source of truth for the evidence remains the sampling study (1600 setting),
not a claim of guaranteed strength at every rating. No sampling defaults, saved
settings or algorithms change with this copy update.

The experimental move-history setting adds six messages in every language.
“History” here means previous board positions supplied to Maia, not the move-list
navigation action; languages may explicitly say previous positions to avoid that
ambiguity. The help limits its research claim to the 79M tests, keeps the option
experimental and off by default, and explains saved-session behavior. This is
app-specific prose, not an upstream Lichess translation. Both Maia probability
sheets and accessible engine-label tooltips identify the effective input mode.

## Named electronic-board connection status

Connection/disconnection confirmations name the recognized product (for example,
Chessnut Go or DGT Pegasus), falling back to the brand or a localized chessboard
label when identification is unavailable. These hardware connection messages have
no direct equivalent in the pinned Lichess terminology baseline. Product names
remain unchanged; all ten languages translate the surrounding status. Languages
where product-name gender is ambiguous use a compact device-status label. Setup
and recovery instructions still take priority over a connection confirmation.

## Sampling data export (#122)

The opt-in sampling capture label, help, counts and export/clear actions are
Maia-specific features with no direct equivalent in the pinned Lichess catalog.
They have dedicated wording in all ten languages. The dialog retains the
existing Lichess-aligned Close action. No shared chess terminology is redefined.
As with other app-specific prose, these are editorial translations, not a claim
of native-speaker certification.

## Readable sampling reports (#128)

Report explanations, partial-capture notices, effective selection probabilities and research
format descriptions are Maia-specific and translated in all ten catalogs.
Save follows the pinned Lichess `save` label, adding an ellipsis because another
choice follows. Share follows the meaning of `mobileShareGamePGN`, omitting PGN
because these exports are HTML/JSONL; both adaptations are recorded in the
terminology reference. White/Black, Temperature, Top-P, history input status,
Cancel and chess notation reuse existing app concepts. Report SAN remains
standard international algebraic notation, as in the existing move list.
These translations require the normal native-speaker review; automated checks
verify consistency, placeholders and layout, not linguistic certification.

The report uses probabilities after the recorded Temperature/Top-P settings.
The localized reciprocal (“about a 1 in X chance”), certainty wording and
most-probable labels are Maia-specific explanatory prose. “View summary” and
its screen were removed; Save/Share remain the only export actions.

## Sampling report game metadata

The report keeps the latest ten captured games and lists them newest first;
its retention notice explains that storage limits can remove older games sooner.
The setting help gives the same policy in every language. Existing White, Black
and You labels are reused. Game results use the pinned Lichess `victory`, `defeat`
and `draw` translations, recorded as three additional reference entries. Missing
results, openings and timestamps, incomplete captures, and report navigation are
app-specific contextual descriptions translated in every catalog. They do not
claim that incomplete captures are complete game records.

## Sampling deletion confirmation

The confirmation reuses the pinned Cancel translations. “Delete data” adapts
Lichess’s Delete verb with an explicit object in each language; the reference
records this context adaptation. The concise warning is app-specific prose
explaining that deleting sampling data cannot be undone. Separately saved/shared
files remain unaffected. All ten translations receive layout and terminology checks; this is not native-speaker
certification.

## Settings organisation (#137)

Analysis settings uses pinned Lichess `preferencesAnalysisSettings` in nine
languages; Hindi has no upstream value and uses a documented native fallback.
Sampling data and the reset-scope explanation are Maia-specific prose translated
in all ten languages. The move-history setting and on-status drop only their
experimental suffix; the substantive help, off recommendation and saved-session
behaviour remain unchanged. Experimental electronic-board wording is untouched.
The now-unused inline history subtitle and export-row title were removed.

## Research-link language and settings help

Research report links have a dedicated label separate from the JSONL export
format. Both report links identify English as the document language in all
non-English catalogs (Japanese: 英文). These are Maia-specific research labels,
not direct Lichess equivalents. Sampling help omits the automatic-upload sentence
in every language; file-content and retention explanations remain unchanged.
Reset settings to default sits above Diagnostics and restores every preference
shown on Settings, including language (system default), sounds/haptics, board
sounds and sampling recording (off). Its scope note and failure message are
app-specific, translated in all ten languages. Stored games, sampling captures
and home game-setup selections are preserved. Sampling retention wording now
explicitly says the last ten recorded games are saved and shown newest first.

The settings reset requires explicit confirmation. The dialog keeps the pinned
Lichess Cancel label and uses app-specific reset/preserved-data wording in all
ten languages. Cancel, Back and outside dismissal do not change preferences.

## Expanded sampling explanation — Preview beta.13

The Temperature/Top-P dialog follows the maintainer-approved seven-paragraph
English copy, translated into all nine other languages. These explanations are
Maia-specific, with no direct Lichess equivalent; shared chess terms retain the
existing Lichess baseline. The new paragraph IDs replace the former example-list
messages rather than keeping unused translations. Research links still identify
English in non-English locales.

Translations preserve the distinction between low probability and poor move
quality, the roughly 300 Elo equivalent result in direct matches at the 1600
setting, and a Top-P cutoff covering at least 95% of probability after Temperature.
Decimal commas follow the established European-language conventions. These are
editorially reviewed translations, not native-speaker certification. Existing
all-language tests check the expanded dialog at 320px and 200% text, its paragraph
order, accessible research link and dismissal, with unchanged engine settings.

## Move-history and capture help refresh

The two information dialogs follow the maintainer's shorter move-history copy
and research-oriented capture explanation in all ten languages. These are
Maia-specific explanations; existing Lichess terminology, setting titles and
research-link labels are retained.

The [move-history study](https://github.com/Dash1971/mobile-maia-research/blob/main/studies/move-history-2026-10-09/REPORT.md)
measured top-move prediction accuracy of 57.00% without history and 59.36% with
history. The help rounds this to about two **percentage points**, not a relative
two percent. It says a strength increase was not established, rather than
implying that a complete-game strength trial found no improvement.

Capture help distinguishes the readable HTML subset from all **recorded** data
in JSONL; neither promises an uninterrupted recording of every move. It retains
the ten-game/storage-limit explanation and separation from Recent Games, and
recommends keeping capture off unless researching Maia. Only help text changes;
capture, retention, saved-session choices and engine defaults are unchanged.

## Maximum opening variety

The maximum-opening-variety setting and its help are Maia-specific sampling
controls with no direct equivalent in the pinned Lichess catalog. All ten
languages explain that each side's first five moves use Temperature/Top-P
1.0 / 1.0, with the configured values restored from move 6. The help identifies
the default values as making this option unnecessary and describes potentially
stronger later play without promising a strength increase. It preserves the
distinction between low move probability and poor move quality. Existing chess
vocabulary and localized Temperature labels are retained; European-language
translations follow the established decimal-comma convention. These are
editorial translations, subject to the usual native-speaker review.

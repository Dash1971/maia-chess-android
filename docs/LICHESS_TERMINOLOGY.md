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

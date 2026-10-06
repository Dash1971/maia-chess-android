# Localization and translation review

Mobile Maia supplies English, German, French, Russian, Hindi, Brazilian Portuguese, Japanese, Simplified Chinese, Korean and Spanish UI catalogs. The catalogs currently contain **302 messages each** and cover game setup and play, settings and help, Chessnut connection/recovery, saved games, PGN import/export, analysis and move classifications, the board editor, and diagnostic recovery.

The translations have received an editorial and automated review, but **have not been approved by native-speaking chess players**. Catalog completeness is not a claim of linguistic certification. The preferred human-review handoff is the language ARB plus the [short reviewer guide](NATIVE_REVIEW.md). The existing `l10n_review.csv` remains a synchronized maintenance aid. Do not publish reviewer identities or private game/device screenshots without permission.

For the chess terminology evidence and unresolved editorial choices, see [the original chess-language review](CHESS_LANGUAGE_REVIEW.md) and [German, French, Russian, Hindi and Brazilian Portuguese research](LANGUAGE_EXPANSION_REVIEW.md).

## Direct ARB review

Flutter ARB files are the authoritative translation format, including for human review. A reviewer comfortable editing JSON can edit only the string values in their language's `lib/l10n/app_<language>.arb`, consulting `app_en.arb` for the English text, `@message` translator descriptions and placeholder definitions. The [reviewer guide](NATIVE_REVIEW.md) links every catalog. Keep message IDs, `@@locale`, placeholders, ICU branches and valid JSON intact. Submit the changed ARB or a pull request; a maintainer runs `flutter gen-l10n` and the localization checks. Do not edit generated Dart files or use Android XML for Flutter UI translations.

An ARB-aware translation editor can be used if it preserves these contracts. Plain ARB editing is sufficient; a spreadsheet or translation service is not required.

## Source of truth and contributor workflow

The source of truth is `lib/l10n/app_{en,de,fr,ru,hi,pt,ja,zh,ko,es}.arb`. The CSV is a review aid, not another translation source. Generated Dart files are checked in so the app's typed localization API is available to all tools.

For every UI text change:

1. Add or update a stable message ID in all ten ARBs. Describe the screen, chess meaning and placeholder purpose in the English `@message` metadata. Do not use English sentences as lookup keys.
2. Use generated getters/methods through `l10n(context)` at the point of rendering. Translate complete messages, with placeholders and ICU plurals/selects where appropriate. Do not concatenate translated sentence fragments or persist translated status text.
3. Run `flutter gen-l10n`, then `python3 tool/check_localization.py --write-review` and `python3 tool/check_lichess_terminology.py`. This refreshes the CSV and source-location hints, preserves reviewer notes, and marks changed messages as needing review.
4. Run `flutter analyze`, `flutter test`, and `python3 -m unittest discover -s tool -p '*_test.py'` in a Python environment with `tool/hardening/requirements.txt` installed. Commit ARBs, generated Dart, the updated CSV, and relevant regression tests together.
5. Inspect changed screens in the Dev app, including a compact screen and 200% text. Host widget tests use test fonts; they cannot establish real CJK glyph quality. Request native-speaker review before describing a translation as approved.

CI checks catalog parity, nonempty messages, duplicate JSON keys, placeholder preservation, translator descriptions, unexpected identical English text, CSV synchronization, generated-file drift, and removal of the old English-string lookup. It also runs the regression suite. These checks catch structural errors, not incorrect grammar or every possible untranslated runtime message. Review new UI call sites as part of code review.

## Language selection and state

- English is the fallback. The language menu lists languages in their own names so users can recover from an accidental selection.
- The system setting follows the first supported language in the device preference list. Regional variants share the corresponding base-language catalog, including German (`de-DE`, `de-AT`, `de-CH`), French (`fr-FR`, `fr-CA`), Russian, Hindi (`hi-IN`) and Spanish. Separate regional catalogs are not advertised.
- Portuguese (`pt`, including `pt-BR` and `pt-PT` device settings) uses the single Brazilian catalog, labelled **Português (Brasil)**. A separate European Portuguese translation is not supplied.
- Only **Simplified Chinese** is supplied. Traditional Chinese system preferences (`zh-Hant`, or Taiwan/Hong Kong/Macao without explicit `Hans`) are skipped in favor of the next supported preference, or English. Users may explicitly select 简体中文 on any device. Add a separate Traditional catalog before advertising that support.
- Language changes apply immediately, including open result and About dialogs, and persist independently of game data. Preference writes are serialized; a slow initial read cannot overwrite a newer choice. Unsupported/corrupt preferences are cleared without deleting other settings. Storage failures leave the app usable and show a localized warning.
- Saved game statuses use stable codes with backward-compatible canonical English legacy fields. Display text is translated when rendered. Switching language must not change a position, clock, engine strength, saved game, or PGN.

## Deliberately untranslated content

Keep SAN/UCI moves, PGN/FEN data and headers, result tokens (`1-0`, `0-1`, `1/2-1/2`), engine protocols, URLs, product/model names, and diagnostic logs canonical. Opening names currently come from the existing English opening dataset; translating that dataset is separate from UI localization. Original third-party license texts remain intact. Android system permission/file-picker UI follows the system's own localization; the app supplies localized share-sheet titles.

Format displayed numbers and dates for the chosen locale, including German, French, Russian and Spanish decimal commas. Chess ratings and move numbers omit thousands separators. Never send locale-formatted numbers to engines or serialize them into game data.

## Terminology and review guidance

- Human timing adds an optional pause; it does not change Maia's strength or predict human thinking time.
- Increment is time added after a move. Korean uses **추가 시간** rather than the abstract numeric term 증분.
- A completed illegal board move differs from a piece still in transit. Retain that distinction in the translator description even when the UI wording is concise.
- Takeback can undo different numbers of plies depending on turn and board mode. Do not promise exactly one ply.
- Castling controls enable castling rights; kingside means short castling, queenside means long castling.
- Classification names are chess annotations, not praise for the user. Keep them consistent between the move list, summaries and tooltips.
- Lichess is authoritative for direct equivalents in every supported language. Follow [the pinned terminology baseline](LICHESS_TERMINOLOGY.md), including its documented context adaptations. Use Lichess study annotations for `!?` and `?!`; do not change Mobile Maia's classification algorithms.
- Use Lichess's single Spanish catalog and conventional international-chess vocabulary in CJK languages. Chinese here means international chess, not xiangqi; Japanese labels must not imply shogi rules.

## Regression coverage

`test/localization_regression_test.dart` checks catalog/rendering contracts and constrained layouts. `test/language_selection_test.dart` and `test/app_language_controller_test.dart` cover selection, restart, malformed preferences, system/script fallback, slow initialization, rapid changes, failures and disposal. `test/play_localization_test.dart` covers status changes, saved-game continuity, result/About dialogs, help/recovery and localized clock decimals. `test/analysis_localization_test.dart` covers the board editor at 200% text and classification labels in all nine translations. `test/storage_localization_test.dart` covers recent games, delete confirmation/plurals, diagnostics and PGN export/share behavior. `test/locale_expansion_test.dart` checks Russian plural boundaries and German/French/Russian/Hindi/Brazilian Portuguese number formatting. `tool/check_localization_test.py` verifies the CI guard itself.

Native-speaker review, TalkBack behavior and physical-device font/layout acceptance remain release acceptance tasks. Hardware Chessnut behavior is covered separately; localization must not alter its protocol or game rules.

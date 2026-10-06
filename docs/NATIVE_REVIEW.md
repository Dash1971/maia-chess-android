# Native chess-player review

Please review the wording in your language while using the Mobile Maia Preview app. All nine translations are provisional. We need natural chess language as well as ordinary grammatical correctness.

## Files to edit

| Language | Edit this file |
| --- | --- |
| German | [app_de.arb](../lib/l10n/app_de.arb) |
| French | [app_fr.arb](../lib/l10n/app_fr.arb) |
| Russian | [app_ru.arb](../lib/l10n/app_ru.arb) |
| Hindi | [app_hi.arb](../lib/l10n/app_hi.arb) |
| Brazilian Portuguese | [app_pt.arb](../lib/l10n/app_pt.arb) |
| Japanese | [app_ja.arb](../lib/l10n/app_ja.arb) |
| Simplified Chinese | [app_zh.arb](../lib/l10n/app_zh.arb) |
| Korean | [app_ko.arb](../lib/l10n/app_ko.arb) |
| Spanish | [app_es.arb](../lib/l10n/app_es.arb) |

Use [app_en.arb](../lib/l10n/app_en.arb) for the English meaning and `@message` translator notes. Each language has 296 messages. ARB is JSON: change text on the right of the colon, keep the IDs on the left, and retain quotation marks and commas. An ARB-aware editor or any UTF-8 text editor is fine.

Keep placeholders such as `{rating}`, `{count}` and `{side}` unchanged, including capitalization. Preserve ICU plural/select expressions and their branch names. Translate the wording inside branches; ask the maintainer if the syntax is unclear. Keep PGN/FEN/SAN/UCI, URLs, product names and move notation intact. Edit ARB, not generated Dart or Android XML.

## What to check

1. Play a game, offer a draw, resign, take back moves, and reopen a saved game. Check that actions sound natural and describe what happens.
2. Open analysis and review. Check piece names, material differences, annotations (`!!`, `!`, `!?`, `?!`, `?`, `??`), variations and main-line actions.
3. Open the board editor. Check side to move, castling rights and en passant. Castling rights do not promise castling is legal in the current position.
4. Read clock increment, premove and sampling explanations. Maia's move probabilities are not winning chances; its rating describes modeled players, not a guaranteed engine strength. Takeback may undo more than one half-move.
5. Check the changed wording on a phone with enlarged text. Report clipping, unclear buttons and unnatural screen-reader phrases. Mark Chessnut hardware messages as untested if you cannot try the board.

Return your edited ARB plus a short note stating your language/region, the Preview build tested, screens reviewed, uncertain terms and any screenshot references. A GitHub pull request is welcome but not required. Keep personal information out of public screenshots. If several wordings are acceptable, explain your preference rather than changing terminology simply for variety.

The maintainer will compare your file with the revision you reviewed, reconcile conflicting suggestions, run Flutter generation and checks, then ask you to verify disputed wording in context. An unchanged file alone is not approval; say explicitly what you reviewed.

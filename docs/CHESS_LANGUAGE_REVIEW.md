# Chess language review — 2026-10-04

> Historical review: terminology choices are superseded where applicable by the
> [2026-10-06 Lichess baseline](LICHESS_TERMINOLOGY.md).

Reviewed all 296 messages in each of Japanese, Simplified Chinese, Korean and Spanish against the English ARB and their UI context. Lichess is the preferred terminology reference for equivalent features. Native-language chess teaching, federation material and published annotation conventions provide an independent check. These are evidence-informed editorial translations; native-player acceptance is still pending.

Language knowledge helped identify awkward or ambiguous wording, but model training data is not an inspectable or attributable source. The references below are the auditable evidence. ARB remains authoritative; there is no new spreadsheet review workflow. See the [short reviewer guide](NATIVE_REVIEW.md) and [maintenance guide](L10N_REVIEW.md).

## Reference policy

- Prefer Lichess's established chess vocabulary when the meaning matches. Compare the actual translation catalogs, not a page that may redirect to English.
- Confirm terminology in native chess content. A general dictionary or vocabulary borrowed solely from shogi, xiangqi, janggi or go is insufficient.
- Preserve Mobile Maia's behavior. Its six move annotations are `!!`, `!`, `!?`, `?!`, `?`, `??`; do not substitute Lichess's automated analysis categories for this taxonomy.
- Use clear wording where the app needs a distinction: a FEN castling right does not guarantee an immediately legal castle; promoting a variation one level differs from making it the main line; material summaries show differences, not a complete inventory.
- Treat country/script and register as review questions. Chinese is Simplified Chinese only. Spanish aims to work across regions and still needs reviewers from Spain and Latin America.

## Japanese

**Keep 対局.** The [Japan Chess Federation results database](https://results.japanchess.org/results) uses it for games; it is established Japanese chess usage. [Federation chess analysis](https://japanchess.org/wp-content/uploads/2022/01/NCS_035.pdf) also supports vocabulary such as キャスリング, アンパッサン and 疑問手.

Compared Lichess's pinned [Japanese site catalog](https://github.com/lichess-org/lila/blob/392aaf4df8c0d72740735e43e5b2d93fa15cc123/translation/dest/site/ja-JP.xml), [preferences](https://github.com/lichess-org/lila/blob/392aaf4df8c0d72740735e43e5b2d93fa15cc123/translation/dest/preferences/ja-JP.xml), [study](https://github.com/lichess-org/lila/blob/392aaf4df8c0d72740735e43e5b2d93fa15cc123/translation/dest/study/ja-JP.xml) and [learn](https://github.com/lichess-org/lila/blob/392aaf4df8c0d72740735e43e5b2d93fa15cc123/translation/dest/learn/ja-JP.xml). Adopted プリムーブ, 正確度, 主手順 and 変化手順, and the game counter 局. Retained Lichess-compatible 投了, 悪手/大悪手, and 序盤/中盤/終盤. [Chess.com's Japanese introduction](https://www.chess.com/ja/terms/chess-ja) independently corroborates the clock and piece vocabulary.

Deliberate differences: keep a consistent 引き分け where Lichess also uses ドロー; qualify its 追加時間 with the per-move meaning; describe variation promotion as moving to a higher line so it remains distinct from selecting the main line. Lichess's 待った is a multiplayer request; Maia's existing undo wording describes an immediate app action. All six annotations now match Lichess study, including 面白い手 for `!?`; variation visibility and board rotation also follow its labels. Castling wording now says 権利, and spoken material wording explicitly says 駒の差.

Native review priorities: nested-variation actions, spoken material differences, accuracy terminology, and compact sampling explanations.

## Simplified Chinese

Compared six pinned Lichess catalogs: [site](https://github.com/lichess-org/lila/blob/567c73aba47ed1db44f986a88cca22e6f2c4d6d3/translation/dest/site/zh-CN.xml), [preferences](https://github.com/lichess-org/lila/blob/567c73aba47ed1db44f986a88cca22e6f2c4d6d3/translation/dest/preferences/zh-CN.xml), [study](https://github.com/lichess-org/lila/blob/567c73aba47ed1db44f986a88cca22e6f2c4d6d3/translation/dest/study/zh-CN.xml), [learn](https://github.com/lichess-org/lila/blob/567c73aba47ed1db44f986a88cca22e6f2c4d6d3/translation/dest/learn/zh-CN.xml), [accessible notation](https://github.com/lichess-org/lila/blob/567c73aba47ed1db44f986a88cca22e6f2c4d6d3/translation/dest/nvui/zh-CN.xml) and [puzzle themes](https://github.com/lichess-org/lila/blob/567c73aba47ed1db44f986a88cca22e6f2c4d6d3/translation/dest/puzzleTheme/zh-CN.xml).

Aligned premoves, variations, mate, mistake/blunder and material differences with Lichess: 预走棋, 变着, 将杀, 错着/败着 and 子力差距. Retained its compatible 等级分, 每步加秒 and 王车易位. [Chinese chess lessons](https://www.chess.com/zh/lessons/qi-zi-de-zou-fa) corroborate international-chess piece and special-move names. [Federation co-organized competition regulations](https://www.sport.gov.cn/n4/n27886102/n27886104/c28138588/content.html) corroborate clock increment language.

Deliberate differences: `!?` uses 值得注意的着法 rather than Lichess's 趣味着法. The Chinese explanation on printed page 5 of this [Chess Informant publisher sample](https://www.newinchess.com/media/wysiwyg/product_pdf/8485.pdf), visually inspected, describes a move deserving attention. Retain 和棋 consistently for a completed draw and explicit short/long castling labels. 无时限 follows Lichess preferences. Explain the timing feature as random pauses, without implying a learned human-thinking-time model. Spacing around Latin names and numeric units is made consistent.

Native review priorities: the `!?` choice, familiar 将杀 versus alternative 将死, annotation-label length, castling-right controls and spoken piece counts. Traditional Chinese needs a separate catalog and regional review. An indexed Chinese FIDE rules PDF was unavailable on direct retrieval; it is not relied on as a fully inspected source.

## Korean

Compared Lichess's pinned [site](https://github.com/lichess-org/lila/blob/392aaf4df8c0d72740735e43e5b2d93fa15cc123/translation/dest/site/ko-KR.xml), [preferences](https://github.com/lichess-org/lila/blob/392aaf4df8c0d72740735e43e5b2d93fa15cc123/translation/dest/preferences/ko-KR.xml), [study](https://github.com/lichess-org/lila/blob/392aaf4df8c0d72740735e43e5b2d93fa15cc123/translation/dest/study/ko-KR.xml), [accessible notation](https://github.com/lichess-org/lila/blob/392aaf4df8c0d72740735e43e5b2d93fa15cc123/translation/dest/nvui/ko-KR.xml), [learn](https://github.com/lichess-org/lila/blob/392aaf4df8c0d72740735e43e5b2d93fa15cc123/translation/dest/learn/ko-KR.xml), [app](https://github.com/lichess-org/lila/blob/392aaf4df8c0d72740735e43e5b2d93fa15cc123/translation/dest/app/ko-KR.xml) and [settings](https://github.com/lichess-org/lila/blob/392aaf4df8c0d72740735e43e5b2d93fa15cc123/translation/dest/settings/ko-KR.xml) catalogs, including the English counterparts for ambiguous keys.

Aligned premoves to 미리두기, variation controls to Lichess's line terminology, and all six annotations to its study labels, including 매우 좋은 수, 애매한 수 and 블런더. Spoken material now explicitly identifies a difference. Native chess explanations of [premoves](https://www.chess.com/ko/terms/premove-chess-ko), [blunders](https://www.chess.com/ko/terms/chess-blunder-ko), [FEN](https://www.chess.com/ko/terms/fen-chess-ko) and [post-game review](https://www.chess.com/ko/terms/chess-post-mortem-ko) corroborate the concepts. Where Chess.com uses another valid label for Brilliant, Lichess's matching study label takes precedence.

Deliberate differences: en passant remains a target-square field, not a rights checkbox; the timeout draw keeps its complete explanation; premove costs, queue limits and physical-board messages describe Mobile Maia's behavior. The main-line action uses Lichess's noun with the app's concise setting verb. Keep the correct existing piece names, castling, resignation, takeback and review vocabulary even where other Korean board games share a word.

Native review priorities: the two line actions, politeness of result messages, premove wording and physical-board instructions. The federation homepage could not be retrieved; no unseen federation text is claimed as evidence.

## Spanish

Compared pinned Lichess [site](https://github.com/lichess-org/lila/blob/392aaf4df8c0d72740735e43e5b2d93fa15cc123/translation/dest/site/es-ES.xml), [preferences](https://github.com/lichess-org/lila/blob/392aaf4df8c0d72740735e43e5b2d93fa15cc123/translation/dest/preferences/es-ES.xml) and [study](https://github.com/lichess-org/lila/blob/392aaf4df8c0d72740735e43e5b2d93fa15cc123/translation/dest/study/es-ES.xml) catalogs. Adopted Abandonar and Lichess's variation, rotation and deletion actions. Material accessibility now identifies the difference. Retained established draw, increment, accuracy and piece terminology, including dama.

[FEDA's Spanish laws](https://feda.org/feda2k16/wp-content/uploads/Leyes-2023.pdf), linked from its [rules index](https://feda.org/feda2k16/reglamentacion-feda-y-leyes-del-ajedrez/), corroborate abandonment, draw offers and castling vocabulary. [Spanish chess teaching](https://www.chess.com/es/terms/ajedrez-es) and a [La Casa del Ajedrez strategy-book sample](https://www.lacasadelajedrez.com/media/pdf/ejemplo_estrategiamediojuegoI.pdf) corroborate pieces, phases and variation terminology; medio juego remains two words.

Deliberate differences: use a count-neutral undo action and completion messages because the app may undo one or two half-moves. Retain Análisis del motor for a phone-based local engine and consistent Jugadas anticipadas; Lichess's explanatory premove wording also uses jugadas. Preserve the six annotation meanings and grammatical agreement with jugada. Probability explanations now distinguish predicted human move choice from frequency, evaluation and guaranteed strength.

Native review priorities: terminology across Spain and Latin America, variation promotion, premoves, spoken material differences and long sampling help. The rules PDF has inconsistent year headers and is used here as terminology evidence, not as a certification of the app's rules implementation.

## Recruiting human reviewers

Ask for two independent reviewers per language if possible: a native-speaking club player, coach or arbiter for chess terminology, and a regular mobile-chess user for clarity and screen fit. Offer a small paid review if budget permits. Begin with a short trial covering the disputed chess terms, then agree on the full 296-string review and in-app pass. For Spanish, include Spain and Latin America; for Chinese, explicitly request Simplified Chinese international-chess experience.

Start with the [Lichess translation community](https://crowdin.com/project/lichess), following its community channels and asking whether someone would be interested in this separate project. Lichess's [translation README](https://github.com/lichess-org/lila/blob/392aaf4df8c0d72740735e43e5b2d93fa15cc123/translation/dest/README.md) identifies its translation workflow. A contributor's feedback is personal review, not Lichess endorsement. Do not put Mobile Maia strings into Lichess's project.

Additional routes include the [Japan Chess Federation club directory](https://japanchess.org/en/registered-clubs/), [WizChess Academy](https://www.wizchessacademy.com/program/coaching.php), and [Spanish Chess Federation contact](https://feda.org/feda2k16/contacto-con-la-federacion/) for referrals to clubs or coaches. The [FIDE federation directory](https://directory.fide.com/list/member_federations/main) is a route to current federation contacts, including China and South Korea. These are recruitment leads, not commitments; nobody has been contacted.

Suggested invitation:

> I maintain Mobile Maia, an open-source Android chess app. Could you review its [language] wording as a native-speaking chess player? We have 296 Flutter ARB messages, English context notes and a Dev build. Lichess is our terminology reference. We especially need feedback on move annotations, variations, clocks and game actions, followed by an in-app clarity check. You can return an edited ARB file without using GitHub. Please let me know your fee or volunteer availability, region and chess experience.

Send the language ARB, English ARB and [reviewer guide](NATIVE_REVIEW.md), together with the exact source revision/build. Ask for explicit reviewed coverage, unresolved terms and screenshots where context matters. Reconcile conflicting suggestions before applying them, rerun localization checks, and have the reviewer confirm the resulting screens. Neither automated checks nor this research constitutes native-speaker approval.

## Patch and validation

Updated 174 translated values: Japanese 36, Simplified Chinese 90 (44 spacing-only), Korean 23, Spanish 25. Expanded ten English ARB translator descriptions for annotation categories, material differences, castling rights and variation actions. Generated Dart and the existing CI-checked CSV remain synchronized. Settings language-dropdown top padding increases from 8 to 16 logical pixels.

Pinned Flutter 3.47.5: localization generation and five-catalog/placeholder checks pass; `flutter analyze --no-pub` reports no issues; all 614 Flutter tests pass, including compact/200% language menus and localized board-editor tests. All 40 Python tool tests and `git diff --check` pass. This pass does not claim a new APK build, Android real-font inspection, physical-board testing or native-speaker sign-off; the earlier PR's device verification is recorded separately in [its verification record](verification-localization.md).

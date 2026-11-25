# Translation quality review — 2026-10-20

Reviewed Preview `857cbe1`, all **409 existing messages in each of ten catalogs**
(4,090 localized/source messages). Read labels, accessibility announcements,
help, saved-game/recovery messages, electronic-board instructions and sampling
reports against the English meaning. Rechecked all entries in the pinned Lichess
reference against the actual upstream catalogs and searched for missing direct
equivalents. This change adds one separate theme-default message: **410 per
catalog**. The synchronized CSV records every changed message for further review.

This is an editorial, source-based review. It does not establish native-speaker
approval of all prose. Automated catalog and layout checks cannot do that either.

| Catalog | Existing messages reviewed | Existing messages corrected | New theme-default message |
| --- | ---: | ---: | ---: |
| English | 409 | 0 (translator metadata clarified) | 1 |
| Japanese | 409 | 7 | 1 |
| Simplified Chinese | 409 | 5 | 1 |
| Korean | 409 | 4 | 1 |
| Spanish | 409 | 13 | 1 |
| German | 409 | 12 | 1 |
| French | 409 | 14 | 1 |
| Russian | 409 | 12 | 1 |
| Hindi | 409 | 24 | 1 |
| Brazilian Portuguese | 409 | 18 | 1 |

## Sources and precedence

1. Use the [pinned Lichess mobile catalogs](https://github.com/lichess-org/mobile/tree/99dd3e0e4859afc7de37290b3f1905045af92004/lib/l10n)
   first for equivalent chess concepts and UI actions in the correct context.
   Preserve upstream wording in `lichess-terminology.json`; record justified
   adaptations instead of rewriting that source evidence.
2. For platform concepts without a suitable Lichess translation, use official
   localized Google/Android documentation. If a generic upstream adjective is
   unsuitable as a platform mode name, document the context and the platform
   evidence. Such exceptions do not replace chess vocabulary with Google's.
3. For AI terminology, use official localized AI documentation and primary
   research, rather than expecting a chess application to define it. The
   [Google Cloud generative-AI glossary](https://docs.cloud.google.com/docs/generative-ai/glossary)
   supplies Temperature/Top-P terminology; the
   [GenerationConfig API reference](https://cloud.google.com/vertex-ai/generative-ai/docs/reference/rest/v1beta1/GenerationConfig)
   describes cumulative-probability sampling. Holtzman et al.,
   [The Curious Case of Neural Text Degeneration, v2](https://arxiv.org/abs/1904.09751v2),
   is the primary nucleus-sampling research reference.
4. Maia's code and research determine Maia-specific behavior. Translate its
   meaning using the established terms; do not import another model's defaults,
   accepted ranges, order of operations, zero-temperature guarantees or strength
   claims. Research links remain labeled English in non-English UI.

Check the returned page's language and the relevant passage, not merely its `hl`
query parameter. Google's localized pages can contain machine translations and
partly English passages. They are terminology evidence, not linguistic sign-off.
In this review the Cloud glossary returned English for Russian and Hindi. We used
the actually localized sources below instead and did not count those fallbacks
as localized evidence. No sources are fetched during builds or on user devices.

## Platform settings

The theme selector originally reused `systemDefault` from the language menu.
French **Langue du système** and Hindi **सिस्टम की भाषा** explicitly mean system
language, so they were wrong in that selector. The dedicated
`appearanceSystemDefault` now follows Lichess `deviceTheme` in nine languages.
English retains System default as a context adaptation; Hindi has no pinned
upstream value and uses Google's **सिस्टम डिफ़ॉल्ट**. Language, system light/dark
mode and Android accent colors remain three independent settings.

The links below are official Google Chrome theme-selector documentation, fetched
and inspected on 2026-10-20. Google Android's companion
[dark-mode and color-scheme help](https://support.google.com/android/answer/9730472)
was also inspected in all ten locales to distinguish brightness from wallpaper
colors. These sources do not determine Mobile Maia's platform/version support.

| Locale | Theme-mode decision | Localized Google reference |
| --- | --- | --- |
| en | Keep Light / Dark | [English](https://support.google.com/chrome/answer/9275525?hl=en&co=GENIE.Platform%3DAndroid) |
| ja | 明るい / 暗い → **ライト / ダーク**; established mode names in katakana | [日本語](https://support.google.com/chrome/answer/9275525?hl=ja&co=GENIE.Platform%3DAndroid) |
| zh | Keep 浅色 / 深色; a brightness choice, separate from 使用系统颜色 | [简体中文](https://support.google.com/chrome/answer/9275525?hl=zh-CN&co=GENIE.Platform%3DAndroid) |
| ko | Keep 밝게 / 어둡게; these agree with Google's selector | [한국어](https://support.google.com/chrome/answer/9275525?hl=ko&co=GENIE.Platform%3DAndroid) |
| es | Keep Claro / Oscuro | [Español](https://support.google.com/chrome/answer/9275525?hl=es&co=GENIE.Platform%3DAndroid) |
| de | Keep Hell / Dunkel | [Deutsch](https://support.google.com/chrome/answer/9275525?hl=de&co=GENIE.Platform%3DAndroid) |
| fr | Lumineux → **Clair**, matching thème clair; keep Sombre | [Français](https://support.google.com/chrome/answer/9275525?hl=fr&co=GENIE.Platform%3DAndroid) |
| ru | Keep Светлая / Тёмная | [Русский](https://support.google.com/chrome/answer/9275525?hl=ru&co=GENIE.Platform%3DAndroid) |
| hi | हल्का / काला → **हल्के रंग वाली थीम / गहरे रंग वाली थीम**; literal black belongs to the separate pure-black setting | [हिन्दी](https://support.google.com/chrome/answer/9275525?hl=hi&co=GENIE.Platform%3DAndroid) |
| pt | Keep Claro / Escuro, Brazilian Portuguese | [Português (Brasil)](https://support.google.com/chrome/answer/9275525?hl=pt-BR&co=GENIE.Platform%3DAndroid) |

These deliberate adaptations retain the original Lichess values and source
links in the offline terminology reference. A literal translation is not
automatically an error: Korean's existing labels match the platform usage.

## AI sampling terminology

Temperature changes the concentration of the model's selection distribution.
Top-P is a cumulative probability threshold, conventionally also called nucleus
sampling. It does not mean taking the top P percent of candidates or dropping
every candidate whose individual probability is below a cutoff. Keep **Top-P**
as the recognizable parameter name in every locale, with translated explanations.

| Locale | Temperature label | Official localized AI terminology evidence |
| --- | --- | --- |
| en | Temperature | [Google Cloud glossary](https://docs.cloud.google.com/docs/generative-ai/glossary?hl=en) |
| ja | 温度 | [Google Cloud glossary](https://docs.cloud.google.com/docs/generative-ai/glossary?hl=ja) |
| zh | 温度 | [Google Cloud glossary, Simplified Chinese](https://docs.cloud.google.com/docs/generative-ai/glossary?hl=zh-CN) |
| ko | 온도 | [Google Cloud glossary](https://docs.cloud.google.com/docs/generative-ai/glossary?hl=ko) |
| es | Temperatura | [Google Cloud glossary](https://docs.cloud.google.com/docs/generative-ai/glossary?hl=es) |
| de | Temperatur | [Google Cloud glossary](https://docs.cloud.google.com/docs/generative-ai/glossary?hl=de) |
| fr | Température | [Google Cloud glossary](https://docs.cloud.google.com/docs/generative-ai/glossary?hl=fr) |
| ru | Температура | [Anthropic's Russian glossary](https://platform.claude.com/docs/ru/about-claude/glossary); [Google ML glossary heading](https://developers.google.com/machine-learning/glossary/generative?hl=ru#temperature) is translated but its definition returned English |
| hi | तापमान | [Google ML glossary](https://developers.google.com/machine-learning/glossary/generative?hl=hi#temperature); align the former transliteration टेम्परेचर throughout Settings/help/announcements/reports |
| pt | Temperatura | [Google Cloud glossary, Brazilian Portuguese](https://docs.cloud.google.com/docs/generative-ai/glossary?hl=pt-BR) |

Japanese, Chinese, Korean and Hindi report introductions previously embedded the
English word Temperature although Settings translated it. They now use the same
localized term. The catalog guard catches that mixed-prose regression as well as
whole untranslated messages. Top-P and mathematical/API identifiers stay canonical.

Checked the explanations against `MaiaEncoding.sampleLegalMove` and
`MaiaPlaySettings.forFen`: temperature acts on legal-move logits before softmax;
zero temperature chooses an argmax and ignores Top-P; positive-temperature Top-P
keeps the crossing move and renormalizes; P=0 keeps one highest-probability move;
P=1 keeps all. Opening variety applies 1.0 / 1.0 at full moves 1–5 for either
color, then restores configured values. These details and Maia's measured match
results come from this app, not from generic AI documentation. No algorithm,
defaults, saved data or approved English sampling explanation changes here.

## Other findings across the catalogs

- All nine translations: use the existing sampling-data feature name in reset
  scope/confirmation copy. Japanese's section heading also names move-selection
  data explicitly. Previously eight reset warnings introduced a second term
  (for example German Sampling-Daten versus Zugauswahldaten).
- German, French, Russian, Spanish and Brazilian Portuguese: translated prose
  now uses decimal commas, matching existing localized controls and the project's
  number-formatting policy. Examples: 0,95 and 60,7%. Only displayed strings
  change; FEN, JSON, JSONL and algorithm inputs remain canonical.
- Japanese, Chinese, German and French: sampling prose reuses the established
  blunder terminology. Japanese also uses the existing 中盤 label. Classification
  meanings and thresholds are unchanged.
- Japanese/Korean: technical evidence names the previous-position input setting
  consistently with its control, rather than suggesting the ordinary move list.
- Spanish/French: deselection actions now say Deseleccionar todo / Tout
  désélectionner, avoiding wording that can sound like deleting selected games.
  Lichess's pinned catalogs have no matching deselect-all action.
- Hindi/Brazilian Portuguese: new help and reports now use the same grammatical
  gender for Maia as the existing engine/game statuses.
- Existing chess actions, piece names, castling rights, premoves, draw/timeout
  text, recovery instructions, placeholders, plural branches, research-language
  labels and deliberately canonical notation were reviewed and retained except
  for the consistency changes above. Ordinary synonyms are not all mistakes.

## Maintenance and validation

Give translator descriptions the actual concept and screen. Separate message IDs
when the English wording matches but the meaning differs. Cross-check related
labels, help, accessibility text, reports and reset dialogs together. Record a
source and context reason for new shared terminology and platform exceptions.

Run localization generation, both offline catalog/terminology checks, static
analysis, localization/report/appearance widgets and Python tool tests. The
appearance widgets exercise all three options in the open selector in every
locale at 320px/200% text in light and dark contexts. Review native device fonts
and seek native-speaking chess/AI reviewers before calling translations approved.
Validation results for this change are recorded in the draft PR.

## Continue from here with an electronic board (#182)

The six continuation connection/setup messages are app-specific hardware guidance
with no direct equivalent in the pinned Lichess catalogs. All ten languages reuse
the existing vocabulary for boards, positions, pieces and unlimited time. “Set up
board” means arranging physical pieces to match the selected position displayed
in the app, rather than opening the board editor. Setup help explains that play
starts only when those pieces match; the supported-hardware notice explicitly
limits position continuation to Chessnut. Restriction copy now describes the
absence of a clock without incorrectly requiring the standard starting position.
These are editorial translations, subject to native-speaker review.

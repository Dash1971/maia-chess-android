# All-mode classification qualification — 2026-10-01

This follow-up supersedes the readiness recommendation for #62. It is based on
preview main `df65a95296fe32bf82c6aabb30238c39b55bcb03` (including beta.7's Fast
preference default). The original tests did not qualify the entire feature.
Reproduction commands and pinned sources are in [README.md](README.md).

## Defects corrected

- Balanced and Thorough bypassed the additional evidence check. The same
  confidence policy now applies to every full-game analysis mode.
- The original gate checked only the best-vs-second gap. Brilliant also depends
  on before/after loss; Good additionally depends on the preceding evaluation.
  The complete upstream decision must now agree over all required positions.
- Verification replaced baseline scores, so inspecting one move could alter
  graph accuracy and adjacent labels. Verification now attaches a separate
  evidence window. Original evaluations, mate scores and PVs are unchanged.
- Evidence from another quality or from an independently searched shallower
  position cannot validate an award. Contradictory independent evidence
  overrides apparent agreement between earlier iterations. Cancellation or a
  failed search cannot attach a partial window.

The normal search budgets are unchanged. Verification targets two additional
plies using the selected mode's existing time limit. The total allowance is six
searches: two per Brilliant candidate, three per Good candidate (two on the first
ply). Extra requested search time is therefore capped at 3s/6s/9s for
Fast/Balanced/Thorough. Stable decisions require no extra searches. This is not a
cap on scheduling, preemption, material-search or total analysis wall time.

## What “matching En Croissant” means

The original annotation order, thresholds, colour/mate normalization and
nonterminal material-search rules match the pinned independent En Croissant
implementation on the same inputs. v0.15.1 and master
`23f83142fcbd4d3af60a524855defe8c9a5703fe` have no changes to these algorithms
relative to v0.15.0. The reference runs the actual TypeScript functions and Rust
material search, with upstream dependency versions pinned.

The confidence layer can withhold an unsupported `!`/`!!`; it cannot manufacture
another label or change unrelated baseline classifications. This is a deliberate
app policy beyond upstream, now consistent across modes. Agreement is evidence,
not a mathematical guarantee about chess truth at arbitrary search depth.
Terminal material/report handling remains the documented app difference.

Different engines/search budgets can legitimately supply different inputs. In
this audit SF18 Balanced rated Na4 `!?`: at depth 14 the played move was absent
from its top two roots (`b6d7`, `h7h6`). The independent EC function produced the
same label. SF18 Fast/Thorough and the app's Light engine in every mode produced
`!!`. We retained this difference rather than changing rules to force labels.

## Regression and independent evidence

| Check | Result |
| --- | --- |
| Full Flutter suite | 522 tests passed, approximately 43s on this host |
| Static analysis | No issues |
| Python release-tool suite | 31 passed |
| Committed game corpora | 821 moves / 838 positions / 17 runs, covering all modes and both engines |
| Independent numeric boundaries | 3,075 cases in five legal position contexts passed |
| Expanded external SF18 corpus | 24 runs, 1,060 moves / 1,084 positions; every move/material/PV replay passed |
| Native Light reference collection | Four runs, 328 moves / 332 positions; all modes plus repeated Fast |
| Actual Review UI | Six tests passed: each mode's full queue/worker/verification path, cancellation during verification and engine reuse |
| Actual VM worker lifecycle | 25 startup/cancel cycles, six lifecycle paths, 300 completion/cancel/exit races passed; no worker remained |

The new mode/window tests first exposed failures before the fix. They cover an
unstable successor despite a stable best-move gap, Good's unstable predecessor,
adjacent independent windows, contradictory verification, insufficient depth,
wrong quality, failed searches at every window position, and actual scope
cancellation. The UI tests leave the real classification workers active and
wait for the final classification summary, not merely the initial graph.

The numeric oracle covers integer neighbours around the 5/10/20 loss thresholds,
10-point best-move gap, 5-point Good gain, the -200 Interesting boundary, mate
signs/zero, score clamps, both colours, first-ply handling and zero/one/two PVs.
Expected symbols come from the upstream TypeScript, not the Dart implementation.

## Real engine qualification

Both engines completed Fast→Balanced→Thorough twice through the actual Dart
analyzer and classification workers. Every displayed label matched the
independent EC oracle on its baseline scores; every Good/Brilliant decision was
also independently checked against its entire earlier-iteration or verification
window. Each mode's repeated annotation vector was identical.

Additional Light runs restarted the native CLI engine between modes in reverse
order (Thorough→Balanced→Fast), and analysed the complete Opera game in all modes.
Across these 18 desktop runs, **1,329 moves and 69 standout confidence windows**
passed independent replay, with no withheld labels in these examples. The
optional verifier's negative self-tests reject corrupted scalar/PV scores,
wrong quality, missing iteration evidence and an unstable successor.

Byrne–Fischer desktop Light totals were 1.6–1.7s Fast, 7.5–9.0s Balanced and
23.7s Thorough, including classification. SF18 totals were 3.9–5.7s, 10.5–11.0s
and 37.4–38.5s respectively. These are observed host timings under varying load,
not controlled phone benchmarks. SF18 Fast needed one independent window; the
Light Byrne–Fischer decisions were already stable without extra searches.

## Android qualification

The actual pinned Stockfish Light Android library passed nine runs on the API 36
ARM64 emulator (2 cores, 3 GB): Fast→Balanced→Thorough twice, then
Thorough→Balanced→Fast with a fresh native engine between modes. An independent
Node/Python replay checked **all 738 labels and all 36 standout decision
windows**, including earlier-iteration evidence, directly against EC. No label
was withheld in this game. Every same-mode repeat and reordered run matched;
all modes retained Black's three brilliancies and never awarded Qa3 Brilliant.

Observed complete-run times, including classification and trace output:

| Mode | First run | Repeat | Reverse order, fresh native engine |
| --- | --- | --- | --- |
| Fast | 3.766s | 2.296s | 2.155s |
| Balanced | 10.634s | 10.930s | 10.024s |
| Thorough | 30.185s | 29.332s | 28.729s |

The profile build uses Release-optimized native code and the Dart profile test
runtime. The packaged ARM64 Light SHA-256 was
`850aa1f54cfa507c28e14d2931a0b2875818455959e2080771bceabfd98ff4d2`.
This is the actual app library, not the desktop SF18 executable.

There were two tooling failures to account for: the first driver invocation
started before the emulator finished booting; the next completed all six tests
but failed during cleanup because Flutter tried to uninstall the unflavoured
package. The reverse-order run used `--keep-app-running`, completed with exit 0,
and explicit cleanup of the known Dev package. The documented command now uses
that approach. Neither failure was treated as a failed or successful chess
assertion; the complete native traces were independently verified afterward.

The final proof-recording harness was also rerun on the Opera game in all three
modes, then independently replayed. Its verifier accepted the valid report and
rejected all four deliberately corrupted variants. The compact
[qualification summary](qualification-2026-10-01.json) retains the run matrix,
all label vectors and proof counts without committing large native build logs.

## Scope and handoff

The automated checks support reviewing and merging this follow-up. They do not
qualify a signed Preview/79M release APK, physical-phone responsiveness, thermal
behaviour or Chessnut hardware. Those remain the previously agreed release
checks. No changes to En Croissant thresholds were made to force a particular
engine's results, and no merge/signing/publication was performed by this audit.

Temporary build output, materialized model copies and isolated audit toolchains
were removed after qualification. The Dev package was stopped explicitly and
the emulator shut down without saving a snapshot. Source fixtures, reproduction
tools and compact results were retained. Shared SDKs and other worktrees were
left intact. No writes were made to macmini-new for this follow-up.

# Stable 2.4 preparation — 2026-10-17

This records preparation, not permission to merge or publish. The public Stable
release remains 2.3.0 (80); this candidate is 2.4.0 (81).

## Source and dependency decisions

App behavior is promoted from Preview beta.15, source
`48a4d0a57f501923d43cc14248ef291a05e915f0`. Shared Dart/native source is retained;
Stable keeps its title, repository URL, unflavored package, blue icon, 79M model,
legacy upgrade verification and existing release gates. Native BuildConfig adds
`FLAVOR = stable` for the shared board gate and the existing ONNX version for
capture provenance. These do not change the canonical F-Droid build command.

The Gradle fix from Stable PR #53 is included: 9.8.1 with the official checksum
and CI/build guard. Do not separately merge that same change after this PR.
The companion PR's independent recipe qualification is useful evidence, but does
not qualify this different source commit.

The [dated upstream review](dependency-audit-2026-10-17.md) is retained with its
original findings clearly labeled. Rechecked on October 17:

- Gradle's latest release is [9.8.1](https://github.com/gradle/gradle/releases/tag/v9.8.1); the required fix is included.
- [Flutter's stable changelog](https://github.com/flutter/flutter/blob/stable/CHANGELOG.md) has 3.47.7. The changes since our 3.47.5 concern iOS accessibility and Windows hangs. Keep the tested Android/F-Droid SDK pin for this promotion.
- Kotlin 2.4.21, AGP 9.4.1 and ONNX Runtime 1.31.0 are available. Keep the qualified 2.4.20 / 9.1.0 / 1.24.3 combination; native/toolchain upgrades need separate compatibility, performance and reproducibility testing. No new security blocker was identified in the reviewed upstream information; this is not proof of absence of vulnerabilities.
- Stockfish's latest release is 19; the app retains Stockfish 19 Light. Maia3 upstream HEAD remains `1e13597c42d4858b7cfd7cfdae01e297263364b2`; the app's model and intentional sampler correction remain unchanged.
- The PR's `dependencies` job resolves the actual Stable release graph and queries OSV. Its current result and run are recorded on the PR. The same job must pass again for the final frozen release source; an older audit cannot replace it.

The full test suite runs with Stable’s actual unflavored Dart policy. Dev-only
prototype connection tests have an explicit Dev run; Stable rejection/restore
regressions run both unflavored and with the explicit Stable test flavor. One
Home test is updated to expect the shared connection-flow wording already used
by the promoted app. These are test adaptations, not changes to board support.

## F-Droid and Zapstore

Canonical metadata was read at fdroiddata commit
`f3a30f2f4fa3afe23f8e76206ec6094b02a5352f`. Its latest recipe is 2.3.0 (80),
source `b03017a1e549992f620a41fdb29a292083e68723`. The proposed local entry for
2.4.0 (81) preserves that recipe exactly except version, code and commit. It
retains the signing certificate, binary URL, Tags detection and automatic
version update. `v2.4.0` is only a review placeholder: resolve the final full SHA
for qualification before creating any tag. This repository copy is not an
upstream F-Droid submission.

The public F-Droid catalog and website show 2.3.0. The website still has the
older description. The approved mission/University of Toronto copy is preserved
and updated for the two new optional features. Compact list markup avoids
newlines inside lists being converted into stray line breaks. The revised copy
and screenshot are included before source freeze. A local browser rendering of
the proposed copy was inspected with newlines converted to line breaks: headings,
bullets and paragraph spacing are clean. This is not an F-Droid client check. The post-ingestion website
and Android-client presentation check for #47 transfers to this promotion's
publication checklist; closing the source issue does not claim store ingestion.
The request lookup returned no open matching build requests at preparation time;
recheck canonical metadata, requests and pipelines before publishing.

The unchanged Zapstore configuration matches `v2.4.0` and
`Mobile-Maia-v2.4.0.apk`, excludes Preview tags/assets, and retains the project
identity. It does not automatically publish. Follow RELEASING.md for local
signing, proof validity, relay events, CDN bytes and the visible listing after
GitHub publication. No store submission has been made during preparation.

## Research and documentation

[Research migration evidence](research-migration-2026-10-17.json) compares all
299 original files against the published dedicated repository: 296 exact matches
and three documented README/manifest changes. All relative Markdown destinations
were checked. The app help, README and current docs use the dedicated report;
small `REPORT.md` and `README.md` notices preserve older app entry points. No
published tag or Git history is rewritten. The removed duplicate tree occupied
approximately 129 MiB in the checkout; historical Git objects remain.

The README and release notes credit outusuke's Maia3-tauri for the opening-variety
idea, without claiming shared implementation. New Settings images are actual
widget renders of this source; [provenance](release-notes/v2.4.0.md#screenshots)
distinguishes them from signed-device qualification.

## Publication gates still required

Follow [RELEASING.md](RELEASING.md) and the [release checklist](release-notes/v2.4.0.md#required-before-publication).
After review/merge, freeze one source SHA and qualify that exact SHA: full CI,
independent Linux canonical-recipe build and source/binary scans, byte comparison,
actual Stable upgrade/native inference/export checks, signature preservation and
`qualify_release.py`. Then obtain publication approval. PR checks alone are not a
release greenlight. Keep GitHub, Zapstore and F-Droid distribution states separate.

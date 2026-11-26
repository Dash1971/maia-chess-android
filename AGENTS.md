# Mobile Maia Stable repository

Read the workspace AGENTS.md as well as this file. This checkout is the Stable,
blue-icon, unflavored `com.dash1971.maia_chess` app. Preview/Dev have separate
identities and release procedures; tooling work does not authorize promotion.

## Required references

- [Contributing](CONTRIBUTING.md): setup, tests, translations and PR expectations.
- [Documentation index](docs/README.md): user, architecture, design and records.
- [Shared process](docs/SHARED_BUILD_PROCESS.md): ownership and counterpart review.
  Read this before changing build, CI, verification or cleanup mechanics. Port
  applicable changes with a linked companion, keep shared helpers identical,
  test both and report merge states separately; explain intentional differences.
- [Release procedure](docs/RELEASING.md): authoritative Stable gates, including
  metadata-only releases. Read it before preparing, building, signing, tagging
  or publishing a release. Do not waive missing or failed evidence. Preparation
  and build requests do not authorize publication; never replace published
  tags/APKs. Preserve canonical Linux and independent F-Droid reproduction,
  exact-source security/model/native/upgrade checks and the established signer.
- [Zapstore publication](docs/ZAPSTORE_PUBLISHING.md): the mandatory store step
  when Stable publication is requested, unless explicitly excluded. Verify its
  actual listing, media and advertised download; distinguish GitHub publication,
  Zapstore verification, F-Droid detection/request/build and catalog publication.
- [Operator setup](docs/RELEASE_TEST_SETUP.md): use the pinned complete Python
  environment and existing bounded UI helpers; distinguish driver/environment
  failures from app defects without turning unavailable evidence into a pass.
- [Build workspace](docs/BUILD_WORKSPACE.md): authoritative disk budgets,
  task-owned scratch, safe cleanup and evidence. Read it before builds or large
  downloads. Reuse shared tools/caches; clean only task-owned bulk on every host
  promptly, including on failure/cancellation, before task completion. Preserve
  source, keys and others' active work; record removed paths and disk changes.

## Product and translation rules

Grand Kingdom is supported across Stable, Preview and Dev and has **passed user
acceptance testing**. Do not reintroduce experimental labels, channel gates or
superseded physical-test blockers. Preserve standard setup, assisted promotion,
current-session motor guards and phone recovery. Pegasus remains withdrawn.
Automatic detailed diagnostics are Dev-only; preserve channel-specific features.

Lichess is the terminology baseline in every supported language for equivalent
chess concepts. Read [the terminology guide](docs/l10n/LICHESS_TERMINOLOGY.md) and use
its pinned reference. Preserve Maia-specific meaning, document adaptations,
update help/accessibility and edit ARBs rather than generated Dart. Run the
localization, terminology and relevant widget checks from Contributing. New
equivalent terms need references; missing upstream terms need a reasoned native
fallback rather than English. Do not change algorithms to match translated labels.

## Documentation and research

Keep living docs aligned with actual channel/version status. After a feature
merges, replace stale proposal/PR narration with current behavior; a merge is not
a publication. Keep real pending approvals explicit. Put dated verification,
proposals and decisions in the history indexes and preserve their meaning and
source/artifact limits. Do not rewrite an unperformed historical check as passed.
Preserve public paths and anchors or leave forwarding links when moving detail.

Publish research reports, datasets and reproduction tools in
[Mobile Maia research](https://github.com/Dash1971/mobile-maia-research), keeping
brief decisions/links in app docs. Do not add research bundles, private files,
credentials or release archives to application source. Complete affected feature,
README, release/store and screenshot documentation before source freeze; follow
the release guide's final status and post-publication pass.

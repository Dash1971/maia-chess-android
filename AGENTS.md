# Mobile Maia release work

Before preparing, signing, tagging, or publishing a Stable release, read
[`docs/RELEASING.md`](docs/RELEASING.md). That is the authoritative release
procedure; follow its gates even for metadata-only releases.

- Review upstream releases and security advisories at each Stable promotion;
  the exact-source `dependencies` CI job must pass before publication. See
  release-guide section 0 for coverage limits and upgrade decisions.
- Freeze one full source commit, including accurate Fastlane metadata. A later
  commit on `main` cannot repair an existing release tag.
- Qualify that exact commit using GitHub CI and an independent Linux build with
  the recipe inherited from **canonical F-Droid metadata**. The local `fdroid/`
  directory is a review copy, not authority for the bot's recipe.
- Run `tool/qualify_release.py` before publication. Do not turn missing evidence
  into a pass, reuse evidence for another commit, or waive failed checks to
  save time. Resolve failures or report the blocker to the user.
- Never replace a published tag or APK. Fixes require a new version/code.
- Keep signing secrets on the signing host. Preserve APK alignment when signing.
- Report GitHub publication, F-Droid update detection, request/pipeline status,
  and actual store publication separately. Never promise that a new tag alone
  repairs an older failed F-Droid request.
- A request to publish a Stable release includes the Zapstore update unless the
  user explicitly limits the channels. Complete and verify the Zapstore step in
  `docs/RELEASING.md` without waiting for a separate reminder or approval. A
  build-only or PR-only request does not authorize publication.
- Zapstore descriptions must use the explicit Markdown in `zapstore.yaml`, not
  F-Droid's HTML. Run `tool/check_zapstore_metadata.py` with the release Python
  environment. Verify Android-compatible formatting; the website rendering
  HTML successfully is not evidence that the Android listing will look right.
- Keep a per-channel release status record on GitHub. Do not call distribution
  complete while Zapstore is unverified or F-Droid publication is pending. Own
  the follow-up, record blockers and the next action, and report any user action
  actually needed; do not make the user discover missing store updates.
- Retain sanitized evidence on GitHub and clean up only this task's temporary
  builds/containers. Preserve shared SDKs, caches, keys, and unrelated services.

For the incident behind these rules, see
[`docs/incidents/2026-10-03-fdroid-release.md`](docs/incidents/2026-10-03-fdroid-release.md).
Ordinary app changes still use the tests documented in `tool/hardening/README.md`.

## Translation terminology

Mobile Maia follows Lichess as its baseline for clear, uncluttered chess UI/UX
and free/open-source design philosophy. Shared terminology is part of that
approach; Maia-specific capabilities retain their own meaning.

Lichess is authoritative in **every supported language** where the chess concept
or UI action has a direct equivalent. Read `docs/LICHESS_TERMINOLOGY.md` and use
the pinned reference in `docs/lichess-terminology.json`. Preserve app-specific
meaning and document context adaptations; do not blindly copy Lichess branding
or change Mobile Maia's classification algorithms to match a translated label.
Update related help/accessibility text as well as the visible label. Run
`python3 tool/check_lichess_terminology.py`, the existing localization checks,
and the localization widget tests after editing catalogs. New equivalent terms
need a reference entry; unsupported upstream translations need a reasoned
native-language fallback, not English.

## Research publication

Publish research reports, datasets and reproduction tools in the separate
[Mobile Maia research repository](https://github.com/Dash1971/mobile-maia-research).
Keep only brief decision summaries and links in app documentation. Do not add
research bundles or datasets to application source or release distributions.

## Shared build process

Read `docs/SHARED_BUILD_PROCESS.md` when changing build, CI, verification or
cleanup tooling. Assess the counterpart in Stable or Preview in the same task.
Port applicable improvements with a linked companion PR; document a concrete
reason for any intentional difference. Preserve channel-specific behavior and
Stable's authoritative release gates. Shared tooling changes do not authorize
an app promotion or publication.

## Release and workspace cleanup

Read `docs/BUILD_WORKSPACE.md` before building or qualifying a release. Preserve
the existing canonical Linux build and independent Linux reproduction process.
Mac builds and ARM64 emulator checks remain supported without an additional
authorization gate. Choose the host appropriate to the check and preserve all
required qualification checks. The build wrappers enforce a minimum free-space
check on both platforms.

Keep bulk output in one task-owned scratch directory, outside the source
checkout, created with `tool/build_workspace.py init`. Keep compact evidence
separate. Reuse configured shared SDK/JDK/Flutter/Gradle/pub caches; do not
clone toolchains or caches per release. Record the host, checkout, scratch,
container and emulator ownership, disk budget and cleanup command before work.
Check free space before large downloads and emulator creation as well as builds;
reserve at least 10 GiB beyond expected growth and stop before that reserve is
consumed. Mac builds require at least 25 GiB free at build start.

Cleanup is part of release completion: immediately after verifying the actual
published download and saving compact evidence, stop task-owned processes and
run the documented cleanup command on every build/signing/test host. Do not
defer bulk cleanup until a documentation PR merges. On failure or cancellation,
retain diagnostics and clean abandoned bulk output before handoff; active work
must have an explicit retention reason, owner and expiry. Never delete another
chat's current build. Include before/after disk space, removed paths and any
retained output with its reason/expiry in the release PR. Do not report a release
task complete until cleanup is recorded or a concrete blocker is reported.

Do not archive full model binaries per release. Remove model copies in generated
output, APKs and scratch with that output. Preserve pinned Git LFS references
and model checksums. Materialized models in a completed task-owned checkout can
go when that checkout is safely retired; an active checkout or useful shared
LFS cache is not disposable bulk output. The generic cleanup command protects
tracked source assets rather than deleting them individually.

After a verified publication, delete merged PR branches and temporary release-build
branches once their source is preserved by a release tag and they have no unique
unmerged commits. Do not delete active work, release tags or releases. Keep
automatic deletion of merged branches enabled.

Remove only task-owned build containers/checkouts, downloaded or reconstructed
APKs, test virtual environments and emulator test data after retaining compact
verification evidence and checking the published download. Stop task-owned
emulators. Preserve shared SDK/Gradle caches, signing keys and other people's
work. Record cleanup in the release PR, including anything intentionally retained.

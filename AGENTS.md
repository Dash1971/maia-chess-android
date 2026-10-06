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
- Retain sanitized evidence on GitHub and clean up only this task's temporary
  builds/containers. Preserve shared SDKs, caches, keys, and unrelated services.

For the incident behind these rules, see
[`docs/incidents/2026-10-03-fdroid-release.md`](docs/incidents/2026-10-03-fdroid-release.md).
Ordinary app changes still use the tests documented in `tool/hardening/README.md`.

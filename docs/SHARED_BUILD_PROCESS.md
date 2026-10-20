# Shared Stable and Preview build process

Stable ([repository](https://github.com/Dash1971/maia-chess-android)) and Preview
([repository](https://github.com/Dash1971/maia-chess-android-preview)) share build
mechanics and safeguards where their requirements match. An improvement in
either repository must be assessed for the other during the same task.

For build wrappers, toolchain/security pins, reproducibility patches, CI,
artifact/model verification and cleanup changes:

1. Inspect the counterpart at its current default branch before editing.
2. Port applicable changes with a linked companion PR. Keep identical shared
   helpers identical. Run the relevant checks in each repository.
3. In both PRs, record the counterpart PR and any intentionally different
   behavior with a concrete reason. If no port applies, state why. Do not
   silently leave the other channel behind or assume a later app promotion
   will carry the change.
4. Report each PR's CI and merge status separately. A companion PR does not
   imply that its changes have landed. Merge or publication authorization
   remains scoped to the user's request.

The following files are shared verbatim:

- `tool/build_workspace.py`
- `tool/build_workspace_test.py`
- `docs/BUILD_WORKSPACE.md`
- `docs/SHARED_BUILD_PROCESS.md`

Compare these files across the two checkouts before submitting a change.
Release wrappers may differ in flavor, package identity and source checks;
apply the common safeguards to the existing wrapper rather than replacing it.
Each repository's CI discovers the shared Python tests through `*_test.py`.

Keep channel-specific requirements: Preview/Dev flavor and board restrictions,
Stable source/metadata and dependency gates, canonical F-Droid qualification,
Zapstore publication and each channel's release authority. These differences
do not justify diverging common disk or cleanup safeguards. Do not copy app
features, version numbers, signing identities, release tags or publication
actions as part of synchronizing build tooling. Stable publication remains
governed by `docs/RELEASING.md` in the Stable repository.

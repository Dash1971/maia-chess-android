# Shared Stable and Preview build process

Build, CI, verification and cleanup improvements must be assessed in both
repositories in the same task. This is not authorization to promote app features
or publish another channel.

## Ownership

| Documentation | Authority | Other repository |
| --- | --- | --- |
| Stable releases and distribution status | Stable `docs/RELEASING.md`, Stable release pages and their distribution evidence | Link to Stable; do not claim that Preview publication updates Stable, F-Droid or Zapstore. |
| Preview/Dev releases and planned work | Preview `docs/RELEASING.md`, release pages and roadmap | Link to Preview; keep published Stable behavior distinct. |
| Build storage, operator setup and counterpart rules | Shared files below, maintained together | Keep complete synchronized local copies so a checked-out release remains usable. |
| Feature behavior | The checked-out channel/version | Share equivalent detail; document Preview-only differences until promoted and published. |
| Historical qualification, proposals and decisions | The dated source record | Link to its immutable source or retained record; do not rewrite it as current acceptance. |

## Counterpart review

1. Inspect the counterpart's current branch before changing shared mechanics.
2. Port applicable changes in a linked companion PR, keeping shared helpers
   identical. Run relevant checks in both repositories.
3. Record each companion and a concrete reason for any intentional difference.
   A pending app promotion does not replace a tooling port that already applies.
4. Report each PR's CI and merge status separately. Preserve channel-specific
   source, signing, model and publication requirements.

The following operator files are shared verbatim:

- `tool/requirements-release-test.txt`
- `tool/setup_release_tests.py`
- `tool/release_test_preflight.py`
- `tool/release_test_setup_test.py`
- `tool/android_release_ui.py`
- `tool/hardening/android_release/FastDump.java`
- `docs/RELEASE_TEST_SETUP.md`
- `tool/build_workspace.py`
- `tool/build_workspace_test.py`
- `docs/BUILD_WORKSPACE.md`
- `docs/SHARED_BUILD_PROCESS.md`

Compare these files before submitting a change. Apply common safeguards to the
existing wrappers; do not replace a channel's wrapper with another channel's.
Both CI suites discover the shared Python tests through `*_test.py`.

The feature-specific `tool/pgn_android_manifest_test.py` belongs with the 2.6
PGN document-routing behavior. Preview and the Stable 2.6 candidate include it;
the Stable 2.5 line does not. Carry it with that promotion, not as a standalone
change to Stable 2.5's intent policy.

Stable retains its dependency/security, canonical F-Droid and Zapstore gates.
Preview retains full exact-source qualification; Dev retains its lighter
procedure and separate identity. For the 2.6 board policy, Chessnut and Grand
Kingdom are supported while Pegasus is withdrawn; this does not retroactively
change older published APKs. Automatic diagnostics remain Dev-only. Preserve
channel identities and fail-closed packaging checks when synchronizing tooling.

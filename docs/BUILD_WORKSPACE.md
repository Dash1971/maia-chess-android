# Build storage and cleanup

Canonical releases build on GitHub Linux; independent reproduction uses the
configured Mac mini Linux machine. Mac builds and tests remain supported
without an additional authorization gate. Apple Silicon is useful for
hardware-accelerated ARM64 Android emulator checks
([Android documentation](https://developer.android.com/studio/run/emulator-acceleration)).
Choose the host appropriate
to each check and preserve the existing reproducibility requirements.

The build wrappers call
`python3 tool/build_workspace.py preflight` before Flutter or Gradle. Mac builds
require at least 25 GiB free; Linux requires at least 10 GiB free. No host opt-in
environment variable is required.
These are starting thresholds, not estimates of the space a build will use.
Before large downloads, builds or emulator creation, check the actual target
volume and allow expected growth plus a 10 GiB reserve. Monitor long jobs and
stop them before that reserve is consumed. Do not bypass the wrapper with a
direct Flutter/Gradle invocation to avoid these rules.

## Before starting

Record the build host, exact source SHA, checkout, shared toolchain paths,
expected disk use, task-owned container/emulator names and cleanup command in
the task evidence. Reuse installed SDKs and caches. Do not create per-release
Flutter SDK, Gradle home or pub cache copies on the Mac. Check for an active
build from another chat before starting or cleaning anything.

Create one **new** bulk directory outside the source checkout. Keep compact
evidence in a sibling directory. For example, from the application checkout:

```sh
python3 tool/build_workspace.py init --scratch ../release-results/bulk
mkdir -p ../release-results/evidence
```

Put downloaded, signed, reconstructed and test APKs, artifact archives, test
virtual environments, full logs and task-owned emulator data under `bulk`.
Point `ANDROID_AVD_HOME` there for a task-owned emulator. Keep signing keys in
their existing secure storage outside it. Keep bulk output ignored by the
enclosing workspace's Git/snapshot rules too; the application's ignore rules
cannot control a separate parent Git repository.

The ownership marker binds the new directory to this checkout and absolute
path. An existing directory cannot be adopted. A moved directory needs manual
review; do not rewrite its marker. Shared SDKs, caches, source and signing keys
must never be placed in this disposable directory.

## Finish a publication or abandon a build

1. Verify the actual published download against the qualified signed APK and
   source, including the bundled model checksum. Save the release URL/tag,
   source SHA, APK/model hashes, provenance and compact test results outside
   bulk output. The cleanup tool records the evidence hash; it does not perform
   publication verification itself.
2. Stop task-owned builds, Gradle daemons, containers and emulators. Check for
   open files/processes on all intended paths. Do not stop shared processes or
   another chat's work. Never clean an active checkout.
3. Preview, inspect and apply cleanup on **each** build/signing/test host:

```sh
python3 tool/build_workspace.py clean --scratch ../release-results/bulk
python3 tool/build_workspace.py clean --scratch ../release-results/bulk \
  --apply --builds-stopped --publication-verified \
  --evidence ../release-results/evidence/verification.json \
  --report ../release-results/evidence/cleanup.json
```

The default is a dry run. Apply requires the stopped-process declaration,
publication verification declaration and nonempty retained evidence. For a
failed/cancelled build, save diagnostics and replace `--publication-verified`
with `--abandoned`. Omit `--scratch` when cleaning only checkout intermediates.

Only `build/`, `.dart_tool/`, `.flutter-plugins-dependencies`, `android/.gradle/`,
`android/.cxx/`, `android/app/.cxx/`, `android/build/` and the explicitly owned
scratch directory are eligible. The tool rejects tracked files in generated
paths, symlinked cleanup roots, nested Git checkouts and possible signing
keys/secrets. Internal virtualenv links are unlinked without following them. It
keeps tracked source assets, Git history, shared toolchains/caches and evidence.
It writes a cleanup plan before deletion, updates removed paths after each
removal and records disk space. If it refuses a path, inspect it; do not widen
the deletion scope to bypass the check.

Model binaries do not need a separate archive for each release. Delete copied
models in bulk output and APKs with those artifacts. Keep pinned Git LFS
references, expected hashes and verification results so the exact models can
be retrieved and checked again. A completed task-owned checkout's materialized
models can be removed by safely retiring that checkout after its source is
preserved. Keep models needed by active work; a useful shared LFS cache may be
retained to avoid repeated downloads. The generic cleanup command does not
individually delete tracked files from a working checkout.

Remove task-owned remote containers/checkouts and AVD registrations separately,
using their recorded identities after stopping them. Delete merged temporary
branches only after the release tag preserves their source and no unique
unmerged commits remain. Keep automatic merged-branch deletion enabled.

Cleanup follows public-download verification immediately, including on the Mac;
it must not wait for a follow-up documentation PR. Record the cleanup report
and intentionally retained paths in the release PR. Any bulk output kept for
active investigation needs a reason, owner and expiry; clean it at handoff when
the work is abandoned. Shared cache eviction is separate maintenance and
requires checking for other users. GitHub-hosted runners are ephemeral and CI
artifacts retain their configured expiry.

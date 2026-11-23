# Release test setup

Use this shared operator setup before expensive Stable/Preview qualification.
It does not change channel release gates, signing identities, APK builders or
Dev's lighter procedure. Start from the channel's authoritative release guide.

## Prepare once, then check before each device stage

Reuse the installed SDK/JDK/Flutter and caches. Set both `ANDROID_HOME` and
`ANDROID_SDK_ROOT` to that same existing SDK. For a task AVD, verify that its
`image.sysdir.1` resolves to the cached image beneath that SDK; a nonstandard
command-line-tools layout must not silently select the SDK parent directory. Create one owned scratch with
`tool/build_workspace.py init` as described in [BUILD_WORKSPACE.md](BUILD_WORKSPACE.md).
Keep reports in a sibling evidence directory. From the application checkout:

```sh
python3 tool/setup_release_tests.py --scratch /absolute/task/bulk \
  --output /absolute/task/evidence/environment.json
/absolute/task/bulk/release-test-venv/bin/python \
  tool/release_test_preflight.py --scratch /absolute/task/bulk \
  --output /absolute/task/evidence/native-preflight.json \
  --expected-growth-gib 20 --adb "$ANDROID_HOME/platform-tools/adb" \
  --serial emulator-5554 --expected-avd TASK_OWNED_AVD
```

The setup installs the complete pinned operator requirements: chess fixtures,
YAML, signature reconstruction (including Click) and screenshot decoding. It
checks imports and `apksigcopier.do_copy` immediately. Existing host pip installs
into a pip-free task virtualenv using `pip --python`; it does not copy pip's CA
bundle into scratch. This avoids the previous public-certificate cleanup block
without weakening key/secret detection. Run the checked cleanup dry run before
starting lengthy qualification; do not move unidentified PEM/key files aside.
Do not replace an existing environment or create another SDK/cache per task.

The preflight retains disk budget/reserve, CPU count and one-minute load. High
load is a warning, not authorization to kill another task or waive tests.
Coordinate contention before long timing-sensitive tests, or choose another
suitable host. Keep required ARM64 checks and supported Mac workflows.

With emulator arguments, it verifies the exact task AVD, boot, awake state and
window focus, and fails explicitly on an ANR dialog. After launching the app,
repeat with `--foreground-package PACKAGE` before clipboard/UI assertions.
Inspect/dismiss ordinary system-error dialogs through normal controls, then
recheck; the helper never dismisses them, resets data, grants URIs or changes
OS security. This is a point-in-time check: capture focus again on failure.

## Reuse a bounded UI driver

`tool/hardening/android_release/FastDump.java` is the shell-only snapshot helper
for analysis/progress screens that do not become idle. Build it once in owned
scratch using the existing JDK/Android tools (no app rebuild):

```sh
mkdir -p /absolute/task/bulk/ui/classes /absolute/task/bulk/ui/dex
"$JAVA_HOME/bin/javac" -cp "$ANDROID_HOME/platforms/android-36/android.jar" \
  -d /absolute/task/bulk/ui/classes tool/hardening/android_release/FastDump.java
"$ANDROID_HOME/build-tools/36.0.0/d8" \
  --lib "$ANDROID_HOME/platforms/android-36/android.jar" \
  --output /absolute/task/bulk/ui/dex /absolute/task/bulk/ui/classes/*.class
```

Package `classes.dex` into a task-local ZIP/JAR, then push it only to the
verified task emulator's `/data/local/tmp`. Invoke it with `CLASSPATH=...`
and `app_process /system/bin FastDump`. Retire that device data during cleanup.
Use one UI driver per emulator; do not run concurrent snapshot sessions.

The helper includes editable/focused semantics and retains child subtrees even
when a Flutter container reports itself invisible. Use
`android_release_ui.text_field` rather than assuming every field has the Android
EditText class. Missing/ambiguous fields are failures requiring a screenshot;
do not silently guess fixed coordinates. `wait_snapshot` retries at most three
consecutive malformed snapshots, retains raw diagnostics through its callback,
uses a bounded wait and defaults to one-second polling. Transport errors remain
errors. Do not continuously spawn snapshots at 100 ms while measuring import
performance. Save screenshots only at milestones/failure.

Test PGN VIEW/Open-with through real Files/document-provider actions and their
actual URI grants. An invented content URI sent from adb has no provider grant;
its permission denial is a negative test, not evidence that valid import failed.
Clear only task-owned synthetic output before a round trip so a save assertion
cannot accidentally read an older file with the same name.

## Schedule checks and retain failures accurately

- Freeze source once after review. Run independent Linux reproduction and CI in
  parallel; download the prior APK and sign the verified matching Linux artifact
  while native checks run. Signing alone is not publication approval. Serialize
  tests that mutate the same emulator. Publish only after every channel gate passes.
- Retain stage, source/APK/model hashes, command, start/end time, result and host
  diagnostics. Record failed runs separately; never relabel them as passing or
  reuse a pass from another source. A driver/dependency repair on unchanged code
  requires rerunning affected checks, not rebuilding both release APKs. App changes
  require refreezing and complete exact-source qualification.
- Do not automatically rerun a whole native suite after any failure. Inspect the
  first failure and focus/load diagnostics. One justified unchanged-source rerun
  may establish a clean full result; if it fails again, report the blocker before
  expanding investigation. Never increase app timeouts or skip failed assertions
  to meet a delivery estimate.
- Exercise the near-limit large collection once. Use a separate smaller fixture
  for interruption, provided the process is demonstrably stopped during staging
  and unchanged committed data plus abandoned-staging cleanup are verified. Do
  not repeat the entire extreme-size validation merely to reach that interruption.
- Prepare the complete README, feature-guide, channel and roadmap update before
  one documentation push. Search affected guides for stale "draft", "pending"
  and old-version claims and distinguish historical measurements from current
  delivery. Review the final diff before CI to avoid a second documentation run.

Immediately after public-download verification, stop owned processes and apply
checked cleanup on every host **before** documentation CI. Retain compact evidence
and archive it under the owner's workspace policy; preserve shared tools/keys.
Report release availability/cleanup separately from documentation CI completion.

## Operator contracts that prevent repeated driver failures

The same tested helpers/fixtures are mirrored in Stable and Preview. Use them
rather than copying a prior release's scripts and assumptions:

- `android_release_ui.normal_background_stop` accepts a fresh installation only
  when preferences, checkpoint and app PID are all absent. Otherwise it waits
  for normal lifecycle completion, fails on malformed preferences/blocked restore
  or timeout, and never clears recovery guards. The adapter returns `None` only
  after an explicit file-existence check; a missing-file error is not XML.
- `persisted_snapshot(..., phase='current'|'archive')` makes the persistence phase
  explicit. `SessionRepository.save()` writes the active checkpoint; `clear()`/
  `startNew()` update the archive. Check completed analysis in the checkpoint,
  then verify its archive after leaving/reopening the game.
- `FastDump.java` includes actual checked/checkable/scrollable metadata. Use
  `checkbox_state` and `visible_label`; missing state or a label below the window
  is a failure, not an unchecked box or a valid tap coordinate. Check the visible
  graph plus persisted scores/glyphs; an offscreen refresh button is not proof
  that graph restoration failed.
- `receive_share` accepts actual delivery to the sole receiver without demanding
  a chooser. With multiple handlers it selects an observed destination and then
  requires receiver/package receipt evidence. A receiver title is not a chooser.
- `fresh_document_name` uses a unique task-owned name and rejects existing output
  before Save. Read that exact newly created document; never validate a previous
  run's file with the same name. Preserve original source hashes separately.

The reusable Android 30+ test receiver lives in
`tool/hardening/android_release/ProbeActivity.java` / `ProbeManifest.xml`. It uses
system-bar insets, an explicit readable theme and mixed-case button labels; the
same receiver handles real content-URI shares and foreground clipboard reads.
Build only this tiny fixture, outside source, with existing SDK/JDK/debug key:

```sh
python3 tool/build_pgn_transfer_probe.py --sdk-root "$ANDROID_HOME" \
  --debug-keystore "$HOME/.android/debug.keystore" \
  --output /absolute/task/bulk/probe
```

The output directory must be fresh. The debug key stays in shared secure storage;
no production key signs the fixture. Install it only on the verified task AVD.
`shared.pgn`, `grant.txt` and `clipboard.pgn` belong to its separate app UID. Use an
independent PGN reader on actual received bytes; this fixture alone does not
certify universal OEM/third-party-reader behavior. Retire its APK/data with the
owned emulator during the normal immediate cleanup.

For the optional VM-service classification audit, use the checked command:

```sh
tool/run_classification_vm_audit.sh --flavor preview --reporter expanded
```

Stable uses its applicable flavor arguments. The wrapper always adds the required
`--enable-vmservice`; calling this fixture as an ordinary Flutter test cannot
observe VM workers. Driver fixes require the affected checks again on unchanged
app bytes, with failed diagnostics retained. They do not waive release gates or
justify rebuilding/repeating already-qualified app/native checks.

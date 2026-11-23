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

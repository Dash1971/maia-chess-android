#!/usr/bin/env bash
set -euo pipefail

# Official JetBrains release asset; digest independently recorded from its release API:
# https://api.github.com/repos/JetBrains/kotlin/releases/tags/v2.2.0
readonly compiler_version=2.2.0
readonly compiler_sha256=1adb6f1a5845ba0aa5a59e412e44c8e405236b957de1a9683619f1dca3b16932
readonly compiler_url="https://github.com/JetBrains/kotlin/releases/download/v${compiler_version}/kotlin-compiler-${compiler_version}.zip"
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
task_dir=$(mktemp -d "${TMPDIR:-/tmp}/maia-native-checks.XXXXXX")
trap 'rm -rf "$task_dir"' EXIT

command -v java >/dev/null
command -v unzip >/dev/null
curl --fail --location --silent --show-error --proto '=https' --tlsv1.2 \
  --connect-timeout 15 --max-time 120 --retry 2 --max-filesize 83886080 \
  --output "$task_dir/compiler.zip" "$compiler_url"
if command -v sha256sum >/dev/null; then
  actual_sha256=$(sha256sum "$task_dir/compiler.zip" | awk '{print $1}')
else
  actual_sha256=$(shasum -a 256 "$task_dir/compiler.zip" | awk '{print $1}')
fi
if [[ "$actual_sha256" != "$compiler_sha256" ]]; then
  printf 'Kotlin compiler digest mismatch: %s\n' "$actual_sha256" >&2
  exit 1
fi
printf 'Verified official Kotlin %s compiler SHA256 %s\n' "$compiler_version" "$actual_sha256"
unzip -q "$task_dir/compiler.zip" -d "$task_dir/compiler"
"$task_dir/compiler/kotlinc/bin/kotlinc" \
  "$repo_root/android/app/src/main/kotlin/com/dash1971/maia_chess/ElectronicBoardProtocol.kt" \
  "$repo_root/android/native_test/ElectronicBoardProtocolTest.kt" \
  "$repo_root/android/app/src/main/kotlin/com/dash1971/maia_chess/SamplingShareFiles.kt" \
  "$repo_root/android/native_test/SamplingShareFilesTest.kt" \
  "$repo_root/android/app/src/main/kotlin/com/dash1971/maia_chess/SamplingDocumentSnapshot.kt" \
  "$repo_root/android/native_test/SamplingDocumentSnapshotTest.kt" \
  "$repo_root/android/app/src/main/kotlin/com/dash1971/maia_chess/SessionRecoveryPolicy.kt" \
  "$repo_root/android/native_test/SessionRecoveryPolicyTest.kt" \
  -include-runtime -d "$task_dir/native-checks.jar"
java -jar "$task_dir/native-checks.jar"

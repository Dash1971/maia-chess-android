#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
flutter_bin=${FLUTTER_BIN:-flutter}
flutter_path=$(command -v "$flutter_bin")
dart_bin=${DART_BIN:-$(dirname -- "$flutter_path")/dart}

cd "$repo_root"

# A fixed source timestamp and locked dependencies keep independent release
# builds reproducible. Dart obfuscation is deliberately not enabled: its
# randomized symbol mapping prevents reproducible builds and provides no
# meaningful secrecy for an open-source application.
SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-$(git log -1 --format=%ct)}
export SOURCE_DATE_EPOCH

"$flutter_bin" clean
"$flutter_bin" pub get --enforce-lockfile
# Run Flutter's release configuration pass before changing package_config.json.
# This filters test-only native plugins from the generated release registrant.
"$flutter_bin" build apk --release --config-only
# Flutter 3.47.1 otherwise embeds the absolute path to its generated Dart
# plugin registrant in libapp.so. Give that generated source a stable package
# URI before compiling so release artifacts remain private and reproducible
# across different checkout paths. --no-pub preserves the prepared config.
"$dart_bin" tool/prepare_reproducible_package_config.dart \
  .dart_tool/package_config.json
"$flutter_bin" build apk --release --no-pub \
  --android-project-arg="mobileMaiaSourceDateEpoch=$SOURCE_DATE_EPOCH"

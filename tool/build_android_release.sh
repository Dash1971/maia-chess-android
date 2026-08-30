#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
flutter_bin=${FLUTTER_BIN:-flutter}

cd "$repo_root"

# A fixed source timestamp and locked dependencies keep independent release
# builds reproducible. Dart obfuscation is deliberately not enabled: its
# randomized symbol mapping prevents reproducible builds and provides no
# meaningful secrecy for an open-source application.
SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-$(git log -1 --format=%ct)}
export SOURCE_DATE_EPOCH

"$flutter_bin" clean
"$flutter_bin" pub get --enforce-lockfile
"$flutter_bin" build apk --release

#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"
exec "${FLUTTER_BIN:-flutter}" test tool/hardening/classification/worker_lifecycle_test.dart --enable-vmservice "$@"

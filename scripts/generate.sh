#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export PUB_CACHE="${PUB_CACHE:-$PWD/.tooling/pub-cache}"
export PATH="$PWD/.tooling/flutter/bin:$PATH"
cd apps/mobile
dart run build_runner build

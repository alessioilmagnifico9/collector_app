#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export PUB_CACHE="${PUB_CACHE:-$PWD/.tooling/pub-cache}"
if [[ -d .tooling/flutter/bin ]]; then export PATH="$PWD/.tooling/flutter/bin:$PATH"; fi
export CI=true
export XDG_CONFIG_HOME="$PWD/.tooling/config"
python3 scripts/check_secrets.py
if [[ "${COLLECTOR_OFFLINE:-false}" == "true" ]]; then
  flutter --suppress-analytics pub get --offline
else
  flutter --suppress-analytics pub get
fi
targets=("$@")
if [[ ${#targets[@]} -eq 0 ]]; then
  targets=(packages/experiment_models packages/dataset_schema packages/protocol_engine apps/mobile apps/admin)
fi
for target in "${targets[@]}"; do
  (
    cd "$target"
    dart --suppress-analytics format lib test
    dart --suppress-analytics analyze
    flutter --suppress-analytics test --no-pub
  )
done

#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
compiler="${KOTLIN_COMPILER:-$PWD/.tooling/kotlinc/bin/kotlinc}"
test_jar=$(mktemp /tmp/collector-writer-XXXXXX.jar)
trap 'rm -f "$test_jar"' EXIT
"$compiler" apps/mobile/android/app/src/main/kotlin/org/research/collector/collector_mobile/RawCsvWriter.kt scripts/RawCsvWriterTest.kt -include-runtime -d "$test_jar"
java -jar "$test_jar"

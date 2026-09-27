# Testing

Run `./scripts/check.sh` from the repository root with the pinned Flutter SDK on PATH.
It resolves packages, formats source, analyzes every package/application, and runs
all tests. A nonzero result must be addressed before proceeding to the next phase.

Widget tests exercise application startup without a connected device. Android and
iOS build/device checks additionally need platform SDKs. Host tests are not evidence
of physical sensor correctness. Hardware scenarios are in
[the pilot checklist](hardware-pilot.md).

## Full host validation

```sh
./scripts/check.sh
npm ci --prefix scripts/backend
npm --prefix scripts/backend run format
npm --prefix scripts/backend run check
npm --prefix scripts/backend test
python3 -m py_compile scripts/verify_dataset.py scripts/test_verify_dataset.py scripts/check_secrets.py scripts/test_check_secrets.py
python3 -m unittest discover -s scripts -p 'test_*.py'
./scripts/check_android_writer.sh
```

For an already-resolved workspace without network, use
`COLLECTOR_OFFLINE=true ./scripts/check.sh`; it resolves only from the local Pub
cache. Flutter tests require localhost socket access. The script suppresses tool
analytics but does not bypass the operating system's socket restrictions.

Native formatting (with the downloaded tooling locations used in this workspace):

```sh
java -jar .tooling/ktfmt.jar apps/mobile/android/app/src/main/kotlin/org/research/collector/collector_mobile/*.kt
.tooling/swiftformat/swiftformat_linux --lint apps/mobile/ios/Runner apps/mobile/ios/RunnerTests --indent 2 --swift-version 5
```

Backend tests apply every migration from scratch in PGlite, exercise RLS and
server handlers/storage using fakes. Flutter tests use real local SQLite/files for
recording, retry and restart scenarios. Python tests independently validate exported
raw data. None imply live sensor/cloud verification. See
[robustness review](robustness-review.md), [hardware pilot](hardware-pilot.md),
[release gates](release-checklist.md) and [export](export.md).

## Readable dataset regression checks

The admin suite covers automatic export loading/refresh/errors, pinned labels,
legacy metadata, safe generated paths, device/practice/retry collisions, frozen
manifests, bounded archive selection, authorization/expiry, cancellation and
partial downloads. A Python ZIP reader independently checks the Dart archive
bytes and CRCs. Python downloader tests cover resume, hash/size mismatch, denial,
path traversal, duplicate mappings, conflicting snapshots and symlinks.

PGlite tests apply the number migration to both empty and populated schemas,
including existing enrollment grants and R2 manifests. Run the additional real
PostgreSQL concurrency check with Docker available:

```sh
python3 scripts/test_participant_concurrency.py
```

It pulls `postgres:17` if needed, creates a disposable container with **no network
and no published ports**, applies all migrations, inserts through eight concurrent
connections, checks rollback safety and removes the container in `finally`.
It does not connect to a configured Supabase project or read environment secrets.
Live R2 CORS, researcher access revocation, URL expiry and browser save/extract
behavior still require the staging checks in `docs/export.md`.

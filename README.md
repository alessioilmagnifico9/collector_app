# Dataset Collector

A local-first Flutter motion-research application for Android/iOS, with a Flutter
Web researcher console. Kotlin/Swift record native monotonic samples to local files;
Drift/SQLite preserves session progress and upload jobs. Supabase holds pseudonymous
metadata and Auth; a private Cloudflare R2 bucket holds compressed raw files.

Implemented: versioned protocol forms/publishing, participant code/QR enrollment,
offline pinned sessions, native acquisition adapters, local quality/checksum saves,
durable signed uploads/retries, researcher progress and deterministic metadata/raw
export. **Production readiness is not yet certified:** native framework builds,
physical device testing, signing and live Supabase/R2 validation remain required.
See [progress](docs/PROGRESS.md) and [release gates](docs/release-checklist.md).

## Fresh development setup

Use Flutter **3.47.5** / Dart **3.13.4**, pinned in `.fvmrc`, Node.js 22 or later and
Python 3.10 or later. Install Flutter from the
[official archive](https://docs.flutter.dev/install/archive). The optional local
SDK/cache directories under `.tooling` are ignored. From the repository root:

```sh
# If Flutter is installed under .tooling; otherwise use your matching SDK on PATH.
export PATH="$PWD/.tooling/flutter/bin:$PATH"
export PUB_CACHE="$PWD/.tooling/pub-cache"
cp -n .env.example .env
cp -n supabase/functions/.env.example supabase/functions/.env
./scripts/check.sh
npm ci --prefix scripts/backend
npm --prefix scripts/backend run check
npm --prefix scripts/backend test
python3 -m unittest discover -s scripts -p 'test_*.py'
```

The workspace lockfile resolves all five apps/packages together. The check script
formats/analyzes/tests each target and checks secret boundaries. With a populated
cache, `COLLECTOR_OFFLINE=true ./scripts/check.sh` avoids network resolution. Tests
need permission to bind localhost. Backend tests recreate all migrations in PGlite;
no live credentials are needed. See [testing](docs/testing.md) for native checks.

From `apps/admin`, run `flutter run -d web-server`. From `apps/mobile`, run
`flutter run` with an Android/iOS device; iOS requires macOS/Xcode. To connect live
services, pass `--dart-define-from-file=/private/client-config.json` containing only
the five public root `.env.example` keys. Dotenv files are not automatically bundled
or read by Flutter. Never pass the server secrets file to either client.

For the explicit memory-only participant demonstration, run from `apps/mobile`:

```sh
flutter run --dart-define=COLLECTOR_DEMO=true
```

Enter `DEMO2026`. This mode does not collect research data. Normal builds never fall
back to fake acquisition; without configuration they can only continue previously
cached enrollment. Release builds must use `lib/main.dart` without demo flags.

## Study workflow

1. Provision an approved researcher account and configure staging as described in
   [deployment](docs/deployment.md). Sign in, create a study and edit a protocol draft.
2. Validate/preview the protocol, publish it, then create pseudonymous participants.
   Deliver the one-time code/QR privately. Enrollment on two phones preserves the
   participant UUID and study-scoped display number while each installation keeps its own physical device UUID.
3. Open the study on each phone and cache instructions. Sessions remain pinned to
   their starting protocol version. Recording and safely saved files work offline.
4. Foreground synchronization uploads closed files, verifies remote bytes and retries
   failures. Local copies are retained. Monitor the Progress tab; offline-only data
   is not visible remotely until the phone communicates.
5. Open Export for automatically loaded file context. Download readable ZIP parts
   or use the streaming plan for large datasets; UUID R2 keys remain unchanged. Run
   `python3 scripts/verify_dataset.py metadata.json /path/to/raw-root --manifest manifest.json`
   before analysis (see the export guide for multiple parts).

Read [architecture](docs/architecture.md), [protocol format](docs/protocol-format.md),
[dataset schema](docs/dataset-schema.md), [synchronization](docs/synchronization.md),
[export](docs/export.md), and the [hardware pilot checklist](docs/hardware-pilot.md).

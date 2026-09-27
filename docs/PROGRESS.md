# Implementation progress

## Arch Linux deployment tooling — 2026-09-26

Configured the existing Flutter 3.47.5/Dart 3.13.4 SDK and Java 21, installed
Supabase CLI 2.118.0 under the user's local bin directory, and installed Android
command-line tools, SDK platforms 35/36, build-tools 36.0.0, platform-tools 37.0.1,
NDK 28.2.13676358 and CMake 3.22.1 under `~/Android/Sdk`. User shell configuration
exposes the tools and uses the existing Brave browser for Flutter web debugging.
The user installed Docker and Android USB rules and enabled Docker; Docker group
access and a disposable hello-world container were verified. Existing login
sessions need logout/login to pick up the new group membership.

Validation: Flutter doctor passed, the workspace format/analyze/test checks passed,
backend TypeScript checks and all 17 backend tests passed, seven Python tests and
Kotlin writer tests passed. The admin release web build and the first Android
framework debug APK build both passed. The Android build emitted a nonfatal SDK XML
version warning. This closes the previously missing Android SDK/debug compilation
gate only; Android lint, release signing, physical-device validation, iOS/Xcode,
live Supabase/R2 verification and the Git-history scan remain open. No cloud
deployment or credential configuration was performed.

Current status (2026-09-25): code/documentation implementation has progressed
through Phase 19; Phase 20 host verification passed. Production acceptance remains
open pending native SDK builds, the device matrix, signing, live services and a
Git-history scan in a usable checkout. See docs/release-checklist.md.

Latest resume verification repaired native status integration (Phases 5–6),
closed-file sample-count validation (Phase 7), and enrollment/refresh request
cancellation (Phases 11/13); see the dated audit entries below. Host results do
not close the remaining native build/device gates.

## Repository inspection — 2026-09-23

Only AGENTS.md and IMPLEMENTATION_PLAN.md existed. There was no application code,
SDK, or usable Git metadata (the provided `.git` directory is empty/read-only).
The earliest incomplete phase is **Phase 0**. Original instructions are preserved.

## Phase status

- Phase 0: implemented and host-validated; native device launch remains an external gate.
- Phase 1: implemented and validated.
- Phase 2: implemented and validated.
- Phase 3: implemented and host-validated; QR entry integrated in Phase 11; camera hardware verification pending.
- Phase 4: implemented and validated.
- Phase 5: implemented; host checks passed, Android integration/device gates pending.
- Phase 6: implemented; shared host checks passed, Xcode/XCTest/device gates pending.
- Phase 7: implemented and validated.
- Phase 8: implemented and host-validated.
- Phase 9: implemented and host-validated; native device verification pending.
- Phase 10: implemented and host-validated; live Supabase verification pending.
- Phase 11: implemented and host-validated; live enrollment/camera verification pending.
- Phase 12: implemented and host-validated.
- Phase 13: implemented and host-validated.
- Phase 14: implemented and host-validated; live R2 verification pending.
- Phase 15: implemented and host-validated; live transfer validation pending.
- Phase 16: implemented and host-validated; offline-only progress is explicitly unknown remotely.
- Phase 17: implemented and host-validated; admin release web build passed.
- Phase 18: host robustness/privacy review passed; physical/live scenarios pending.
- Phase 19: pilot tooling/checklists implemented and validated; hardware matrix NOT TESTED.
- Phase 20: host checks passed; production sign-off remains open for external gates.

## Phase 0 — Bootstrap

Created Flutter mobile (Android/iOS runners), Flutter web admin, three shared Dart
packages, one Pub workspace/lockfile, pinned SDK, public/server environment examples
and local ignored placeholders, documentation and a repeatable check script.
Original instruction files were not changed. Installed official Flutter 3.47.5 in
ignored `.tooling/`; verified its release SHA-256 before extraction.

Validation: formatting and static analysis passed in all five packages/apps; eight
tests passed (including both application startup widget tests); admin release web
build passed. Added the template's Cupertino icon dependency to address its font
warning. Secret ignore checks passed. Removed generated Android debug signing from
the release build type. Android SDK, Xcode, and physical devices are absent, so
native launch/build acceptance is not yet verified. The source is not a usable Git
checkout, so history scanning/commits cannot be performed here.

## Phase 1 — Shared domain and dataset model

Added immutable typed records for all planned entities, sensor capabilities and
quality summaries; enum codecs; UUID generation/validation; UTC metadata codecs;
defensive protocol-document freezing; and exact-nanosecond sample JSON/CSV codecs.
Expanded dataset documentation and recorded serialization decisions in ADR 002.

Validation: all-package formatting/static analysis and 15 tests passed. Tests cover
every entity round trip, invalid identity/metadata/checksum/object paths, nested
immutability and timestamps above JavaScript's exact integer range. A bootstrap
rerun encountered a shell read error while the running check script was being
edited; the subsequent complete run passed. No failed validation was skipped.

## Phase 2 — Protocol engine

Added typed protocol/session/task definitions, JSON schema and demonstration data,
path-aware validation, ordered practice/main trial expansion, actual-hand resolution,
validated publishing/draft duplication, and serializable version-pinned sessions.
Publishing or editing an already published object is rejected. Session start checks
study ownership, and cache restoration checks trial identities/content/order.

Validation: formatting, analysis and all eight protocol package tests passed,
including malformed input, queue order, immutability, study boundaries and version
pinning after a newer publication. The example is explicitly demonstration data;
no study-specific protocol was provided or inferred from session numbers.

## Phase 3 — Mobile UX shell

Added injectable enrollment/capture ports, an explicit memory-only demo adapter,
code/enrollment-link entry, session selection, hand/posture/device instructions,
countdown, timed/manual stop, save/error/completion screens and hidden diagnostics
entrypoint. Normal mode does not silently fall back to fake data. Interrupted
recordings fail with a repeat instruction. QR payloads can be entered as links;
physical camera scanning is deferred to enrollment integration (Phase 11).

Validation: formatting/analysis and all five mobile widget/integration tests passed.
A full five-trial fake session runs without backend access; duplicate taps issue
one start/stop; save failure cannot display Saved; small-screen layout and Android
tap-target accessibility checks pass. Native recording and durable saves are not
claimed by the explicit demo adapter.

## Phase 4 — Recording state machine

Added a widget-independent recording state machine with all eight specified states.
The mobile controller now separates raw file closure from validation/persistence.
Only the successful persistence path can enter Saved. Restart restoration rejects
transient acquisition states and requires local verification to restore Saved.

Validation: formatting, analysis, ten domain tests and five mobile tests passed.
The transition test covers every state pair, including all duplicate/invalid moves;
restoration tests cover process death and unverified local saves.

## Phase 5 — Android native recorder

Added SensorManager acquisition for all five streams, capability/device metadata,
native HandlerThread processing, 128-sample file batches, UUID-bound start/stop,
flush/fsync and atomic closure, partial-attempt retention, and lifecycle safeguards.
Flutter uses a typed MethodChannel adapter for control/capability/result messages.
Raw files remain in Android no-backup private storage. Added ADR 003 and native
contract documentation.

Validation: Kotlin formatted with ktfmt 0.58; standalone Kotlin 2.2.20 compilation
and native writer tests passed (300 samples across batches, exact timestamps,
closure, empty streams, partial retention and overwrite prevention). Dart formatting,
analysis and seven mobile tests passed, including channel identity checks. Full
Android framework compilation/lint and physical sensor acquisition are **unverified**
because the Android SDK and devices are unavailable. Those acceptance gates remain
open; implementation continues without claiming hardware readiness.

## Phase 6 — iOS native recorder

Added Core Motion accelerometer/gyro/magnetometer and deviceMotion gravity/quaternion
acquisition, the same Dart channel contract, a serial native writer with 128-sample
batches, flush/synchronize/atomic closure, motion permission text and Xcode source
registration. Core Motion seconds are converted to nanosecond integer text without
substituting Flutter delivery time. Missing hardware metadata remains null.
Interrupted attempts retain partial files; application support is excluded from
backup. Generation tokens reject callbacks from previous attempts.

Validation: SwiftFormat 0.62.1 parsed/formatted the Swift sources; Dart formatting,
analysis and all seven mobile tests passed. Added real XCTest writer coverage for
batching, closure, empty/corrupt attempts and partial retention. **Xcode compilation,
Swift type checking/XCTest execution, and physical iOS validation are unavailable
on this Linux host**, so those tests are explicitly pending rather than passed.

## Phase 7 — Local finalization and quality

Added streaming, bounded-memory CSV validation and per-sensor quality calculation,
gzip finalization with durable flushing, compressed-byte SHA-256/size, and repeatable
finalization. The pipeline rejects partial/empty/corrupt or nonmonotonic streams,
retains all original raw files and detects conflicting existing compressed output.

Validation: formatting, analysis and nine dataset tests passed. Deterministic tests
cover sample counts, mean rates, rate/interval population standard deviations,
estimated gaps, unavailable streams, one-sample metrics, gzip round trips, repeat
finalization and a known SHA-256 vector. No network calls exist in this pipeline.

## External verification requirements

Physical Android/iOS sensor tests, macOS/Xcode builds, signing, and live Supabase/R2
deployment require the corresponding hardware/tools or account configuration.
Missing credentials do not block local implementation.

## Resume verification — 2026-09-24

Verified existing files against the plan. The initial check hit Flutter telemetry
writes outside the sandbox; the authorized rerun passed all existing 36 tests.
Git history/diffs remain unavailable because this is not a usable Git checkout.

## Phase 8 — Durable local persistence

Finished Drift storage, session resume and the native-recording-to-local-commit
adapter. Added atomic trial/progress/queue commits, metadata/hand/checksum guards,
immutable version snapshots, expired-upload recovery and attempt fencing. Removed
the demo recorder from the unconfigured normal app path. Documented migration,
orphan-attempt and restart behavior in `docs/local-persistence.md`.

Validation: mobile formatting and analysis passed; all 13 mobile tests passed,
including six new real SQLite/file integration tests for restart, lease recovery,
failed commit rollback, idempotent saves, immutable cache and populated v1 upgrade.
The first analyzer run caught a generated Drift/domain name collision and missing
awaits; these were fixed before rerunning. No failed test was skipped.

## Phase 9 — Physical device registration

Normal app startup now opens backup-excluded native storage, registers a random
installation UUID and refreshes device/OS/app/sensor metadata without changing that
identity. Added native storage-directory channel support and the durable capture
bootstrap. Startup failure cannot fall back to fake collection. Reinstall behavior
and database-copy restrictions are documented.

Validation: mobile formatting, analysis and all 14 tests passed, including stable
identity across SQLite reopen/metadata refresh and a new identity on fresh install.
Kotlin formatting and standalone writer tests passed. SwiftFormat passed after
correcting the executable path; Xcode/Android framework builds remain external gates.

## Phase 10 — Supabase schema and researcher Auth

Added all core relational tables plus study/device associations, composite foreign
keys for tenant/version integrity, useful indexes, default-deny RLS, explicit
client grants, owner/editor/viewer policies, atomic study creation and immutable
published-version/session guards. The Flutter admin now provides Supabase Auth
sign-in/sign-out, study listing and creation; unconfigured access remains disabled.
Documented approved-researcher provisioning, public client configuration and local
versus live authorization checks.

Validation: all four PostgreSQL/PGlite migration/RLS scenarios passed from empty
schemas; admin formatting, analysis and three widget tests passed. Initial SDK
analyzer findings (generic RPC return type and the renamed initialization key)
were fixed. The npm download required network escalation after DNS failure.
Live Supabase JWT/Data API verification remains a deployment gate.

## Phase 11 — Participant enrollment across devices

Implemented server-generated participant codes/QR payloads, hashed enrollment and
per-device grants, shared durable rate limits, researcher permission checks and
revocation. Added the researcher enrollment form/QR display, mobile camera scanner,
HTTP enrollment adapter and schema v3 enrollment cache/grants. Codes are not stored
locally or in server plaintext. Grants for prior participants remain available for
later uploads when the active participant changes. Cached enrollment can reopen
offline; session lookup also checks protocol identity. Researcher sign-out disposes
study screens. Native capture now reads its requested rate from the pinned protocol.

Validation: backend TypeScript checking and eight tests passed (five real SQL and
three handler/service tests). Mobile formatting/analysis and 15 tests passed; admin
formatting/analysis and four tests passed. Fixed a generated duplicate-primary-key
failure and Drift constraint API errors; reruns passed. Physical camera scanning,
live Edge Function/Auth requests and native platform builds remain unverified.

## Phase 12 — Protocol administration

Added protocol/version history, creation and duplication of drafts, form editing for
sessions and all task settings, session/task reordering, task duplication, validation,
participant queue preview and publishing. Published forms are read-only. Database
publication validates the full nested schema and updates the active pointer atomically;
optimistic document comparison rejects stale concurrent saves. Draft numbering locks
the parent protocol to avoid duplicate version numbers.

Validation: admin formatting/analysis and six tests passed; backend TypeScript
checking and nine tests passed (six SQL, three service/handler). Tests cover form
editing/duplication/preview/publication, invalid nested data, stale edits, publication
immutability and unauthorized draft creation. No architecture deviation.

## Phase 13 — Mobile protocol synchronization

Added authenticated active-version refresh, atomic validated cache replacement and
explicit offline continuation. Existing session snapshots remain pinned. Session
selection merges unfinished cached definitions with the current published protocol,
so removing a definition in a newer version cannot strand an unfinished session.
A failed refresh preserves the previous cache and offers participant-safe guidance.

Validation: mobile formatting/analysis and all 16 tests passed, including refresh
to a new version, removal of the in-progress definition, SQLite reopen, exact trial
UUID/version restoration and offline refresh failure without cache loss.

## Phase 14 — R2 upload authorization

Added participant/device-scoped upload preparation, pinned-task/tenant checks,
idempotent immutable trial/file manifests and server-derived UUID object keys.
Implemented short-lived SigV4 PUT authorization with signed size/type and conditional
creation, plus streaming remote SHA-256 verification before finalization. Missing
R2 configuration affects upload actions only; enrollment still works. Documented
R2 setup, large-file runtime limits and integrity-conflict handling.

Validation: backend formatting/TypeScript checking and 13 tests passed (seven SQL,
six service/handler/storage). Tests cover ownership, duplicate preparation, manifest
conflicts, forbidden finalization, URL/header constraints, corrupt/oversize objects
and refusing finalization after failed verification. Live R2 signature acceptance,
expiration and Edge-runtime performance remain external gates.

## Resume verification — 2026-09-25

Inspected source and reran all existing format/analyze/tests: 50 Dart/Flutter tests
and 13 backend tests passed. Git metadata is still unavailable. Found partial,
unwired Phase 15 files beyond the recorded Phase 14 state. Flutter checks require
access to its home-directory telemetry cache; the sandbox-only attempt failed,
then the authorized run passed. Hardware/live deployment gates remain open.

## Phase 15 — Sync engine

Connected the existing upload adapter and durable worker to normal startup, local
save, foreground return and periodic scheduling. Added acquisition/lifecycle guards,
shutdown draining, client/DB cleanup and remote content-type verification. Local
files remain intact; every retry requests fresh authorization and verifies the
remote manifest before marking synced. See `docs/synchronization.md`.

Validation: mobile formatting and analysis passed; all 20 tests passed. Four new
integration cases cover persisted failure/backoff/restart, corrupt local data,
remote manifest mismatch, scheduler/duplicate-call fencing, streamed bytes, expired
URLs and conditional PUT retries. Corrected the nullable offline configuration
analyzer failure before the successful rerun. Live R2/device checks remain manual.

## Phase 16 — Researcher dashboard

Added an RLS-preserving, consistent study snapshot and the Progress tab for participant,
session and trial counts, pinned versions, incomplete sessions, upload status,
device capabilities and explicit quality warnings. Failed remote verification now
records failed status without downgrading verified files. The UI explains offline
visibility and retains the existing one-time QR/code display in Participants.

Validation: admin formatting/analysis and all eight tests passed; backend formatting,
TypeScript checking and 14 tests passed. Tests verify viewer/owner/outsider boundaries,
credential exclusion, deterministic snapshots, failure status, quality warnings
and clearing stale dashboard data after denied refresh. Fixed an ambiguous Auth/domain
Session import and fixture import. An npm check was initially invoked from the root
without a package.json; rerunning from scripts/backend passed.

## Phase 17 — Dataset export

Added canonical JSON metadata export with explicit reviewed field/table allowlists,
UUID ordering, schema/protocol versions and immutable raw-file references. The web
console downloads snapshots and requests individual short-lived raw downloads.
Server download authorization verifies the current researcher and study membership,
requires a verified file and signs only its canonical server key. Export semantics,
visibility and scaling limits are in `docs/export.md`.

Validation: admin formatting/analysis and all ten tests passed; backend formatting,
TypeScript checking and 15 tests passed. Covered deterministic export, credential
exclusion, browser-flow callbacks, unauthorized actor rejection and server-derived
keys. Automatic approval review timed out on a combined edit/test command; splitting
workspace edits from the cache-access test command succeeded. Release web compilation
is pending a separate tooling invocation and is not claimed as passed here.

## Phase 18 — Robustness and privacy review

Added completed-session/study navigation, participant switching and credential-field
clearing. Guarded delayed native starts and storage shutdown during local saves.
Added serialized SQL repetition quotas and dominant/non-dominant hand enforcement
so duplicate task UUIDs cannot falsely complete a session. Added the evidence matrix
and privacy/storage review in `docs/robustness-review.md`.

Validation: mobile formatting/analysis and all 22 tests passed; backend formatting,
TypeScript checking and 15 tests passed. Kotlin writer tests passed. Native source
formatting and Swift lint passed with the established two-space indentation. The
initial Swift lint used the default four-space style and failed; the explicit style
rerun passed. A test-edit placement error was corrected and the backend rerun passed.
The no-network Pub advisory lookup and sandbox-blocked Flutter test sockets failed;
offline resolution and the authorized test-server run resolved these tooling issues.
The check script now supports offline dependency resolution and suppresses analytics.
The admin release web build (including Wasm compatibility dry run) passed inside
the sandbox, resolving Phase 17's pending compilation check. Real native/live tests
remain unexecuted and are not replaced by these host results.

## Phase 19 — Hardware pilot preparation

Added a four-device test matrix, interruption/offline/low-storage/restart scenarios,
5–10 participant pilot procedure, release/signing/permission/deployment checklists,
and a privacy-conscious defect template. Added an independent standard-library
Python verifier for UUID relationships, pinned task quotas, gzip/hash/size, exact
native timestamps, sample counts and session completeness. Signing properties and
Python cache files are ignored. No real credentials or signing identities fabricated.

Validation: Python syntax checks and five integrity tests passed (valid large
nanoseconds, tampering/missing/path escape, malformed streams, metadata mismatch,
and pending-versus-complete sessions). Native formatting checks and Kotlin writer
tests passed; the preceding 22 mobile tests include the lifecycle fixes required
for the pilot. Source has been formatted; physical matrix entries remain explicitly
NOT TESTED. Platform SDKs, phones, signing accounts and live services are external
release requirements, not silently completed acceptance items.


## Phase 20 — Host readiness verification and remaining release gates

Updated root/app setup guides, deployment/testing/export references, phase statuses
and release documentation. Strengthened current-source and available-history secret
checks for private keys, privileged Supabase JWTs and secret API keys; verified ignore
rules for local environments and signing properties. Release admin JavaScript passed
the same recognizable-secret scan. No actual Git history exists in this workspace.
Added a real SQL-export-to-Python integrity test and verified clean temporary Pub/npm
installation from the lockfiles and local caches. Kept the explicitly labelled demo
for tests/development; normal builds never use it without the compile-time flag.

Final review fixed HTTP timeout resource leakage: requests now carry abort signals,
streaming PUT/finalization share bounded deadlines, and timeout cancels the underlying
request. A regression test confirms the durable job and local bytes survive.

Validation: all-package formatting/static analysis passed; 61 Dart/Flutter tests
(11 models, 9 dataset, 8 protocol, 23 mobile, 10 admin), 16 backend tests (9 SQL,
7 handler/storage), and 7 Python tests passed. Backend TypeScript checking, Python
syntax compilation, shell syntax checks, Kotlin writer compilation/tests, native
formatting/Swift lint, fresh dependency setup, migration recreation, export integrity
and admin release web compilation passed. The SQL export test first hit a sandbox
Node synchronous-child-process EPERM despite valid child output; using an asynchronous
child process fixed the test harness and the full backend rerun passed. No failed
check is silently skipped. Unchanged packages retain their final full-suite results;
the HTTP cancellation change was followed by a fresh mobile format/analyze/test run.

Remaining release gates: configure Android SDK and run framework build/lint; run
Xcode build/XCTest on macOS; execute at least two Android manufacturer families and
two iPhone generations where possible; provide signing identities and public/server
configuration; verify live Auth/RLS, R2 signatures/expiry/integrity and runtime limits;
scan history in a real checkout; execute and approve the supervised hardware pilot.
Exact checklists are in `docs/release-checklist.md` and `docs/hardware-pilot.md`.
The production-ready milestone is **not declared complete** without that evidence.

## Resume audit and Phases 5–6 corrections — 2026-09-25

Re-read the plan and inspected source instead of relying on phase labels. The
unchanged baseline passed formatting/analysis and all 61 Dart/Flutter tests,
16 backend tests, seven Python tests and the Kotlin writer tests. Backend format
and TypeScript checks passed. The sandbox Flutter run failed to open localhost
sockets; the authorized rerun passed. An initial backend command used the missing
`typecheck` script after tests passed; the documented `npm run check` passed.
Git metadata and native platform SDKs remain unavailable.

Found that native sensor/I/O failure and timeout could leave the UI saying
Recording until manual stop: native status existed but was never read by Dart.
Added trial-specific start/status validation, a serialized one-second health poll
with a five-second deadline, and attempt fencing across stop/retry/disposal.
Both native platforms now report the active trial identity. Failures abort the
attempt and retain the same planned trial for retry; samples remain native.

Validation: mobile formatting and analysis passed; all 28 mobile tests passed,
including five new cases for native status/identity, failure, stalled status,
late failure after save, and late failure during a new attempt. Kotlin formatting
and writer compilation/tests passed; Swift formatting passed. Android framework
and Xcode execution still require the external platform environments. This
completes the host-testable correction, not hardware acceptance.

## Phase 7 correction — native closure count — 2026-09-25

Finalization previously accepted a syntactically valid CSV even when its sample
count differed from the native stop result. The collection pipeline now supplies
the expected count and rejects any mismatch before compression or persistence.
Independent finalization callers may omit the count when no native manifest exists.
Raw bytes remain available for investigation and session progress cannot advance.

Validation: dataset/mobile formatting and analysis passed, with all ten dataset
tests and 29 mobile tests passing. New tests cover whole-row truncation, unexpected
extra rows, invalid expected counts, repeated finalization, and the actual
SQLite capture path leaving trials, upload jobs and session progress unchanged.
No schema or architectural change was required.

## Phases 11/13 correction — bounded enrollment requests — 2026-09-25

Continued through persistence, device registration, enrollment and protocol-cache
paths. Enrollment and refresh used Future timeout without cancelling the HTTP
request, unlike the upload adapter. Both now send abortable requests with a shared
30-second header/body deadline and disabled redirects. Failure preserves the
cached enrollment, device grant and pinned sessions for offline use; the client
remains usable for a later refresh. No credentials or live service were required.

Validation: mobile formatting and analysis passed and all 31 mobile tests passed.
Two new HTTP tests stall response headers and response bodies, verify cancellation
for enrollment and refresh, verify persisted/cache identity survives, and complete
a later successful refresh. The existing protocol refresh/restart test still passes.

## Phases 18–20 follow-through — 2026-09-25

Updated the robustness evidence matrix, native contract, local durability notes and
physical pilot checklist for the new failure paths. Removed stale documentation
that described already-implemented pilot and synchronization work as future phases.
The existing architecture, protocol schema and migration history remain unchanged.

Latest host validation across the baseline and affected-package reruns: 70
Dart/Flutter tests (11 models, ten dataset, eight protocol, 31 mobile, ten admin),
16 backend tests and seven Python tests passed. Formatting and static analysis
passed for all Dart targets; backend format/TypeScript checking, Kotlin writer
compilation/tests and Swift formatting/lint passed. Admin release web compilation
and Wasm compatibility dry run passed again; ten generated JavaScript files passed
the recognizable-secret scan. Current-source secret and ignore checks passed.
Nine regression tests were added during this resume.

An actual Android debug build attempt stopped with `No Android SDK found` before
compilation. This is an unresolved environment gate, not a passed build. Xcode,
physical devices, signing identities, real Supabase/R2 configuration and usable Git
history remain unavailable. Follow the existing deployment/release/pilot checklists
to supply those inputs and collect the missing evidence. No live deployment was
performed and the production-ready milestone remains open.

## Configuration review and Android testing APK — 2026-09-26

Checked local credentials without logging their values. Derived the functions
base URL from the Supabase project URL, moved privileged configuration out of the
root dotenv into the ignored server dotenv, and restored credential-free example
templates after finding private material in the root example. Created an ignored
public-only `.env.client.json` and documented builds in `android-apk.md`.

Supabase Auth settings returned HTTP 200 using the configured anon key. The
collector function returned HTTP 404; its deployment remains required. All R2
settings remain missing/placeholders. Migrations and live enrollment/upload were
not verified. No remote state was changed.

Android debug APK compilation passed on the available SDK. Mobile static analysis
passed and all 33 mobile tests passed. Initial attempts failed because dependency
resolution lacked network access, Gradle caches were read-only, and Flutter test
sockets were blocked. Cached dependencies and approved execution resolved these
environment failures. Source secret checks passed; the APK scan found none of the
configured private credentials. Git history was unavailable for scanning.

The APK is debug-signed for testing, not production release approval. Release
signing, live deployment, R2 and physical hardware checks remain open.

## Collector browser preflight diagnosis — 2026-09-26

The live OPTIONS request from the Vercel origin returned HTTP 404 with
`NOT_FOUND: Requested function was not found`. The local collector already handles
unauthenticated preflight with HTTP 204 and CORS headers; no handler change was
needed. Added a regression test ensuring preflight does not authenticate or access
the database, and documented the project-specific deploy and preflight commands
in `docs/deployment.md`.

Validation: test formatting and backend TypeScript analysis passed; all 18 backend
tests passed (ten database, eight function tests). No remote deployment was made.
Deploying collector to the configured Supabase project remains the immediate fix;
its migrations and R2 configuration still require live verification.

## Participant enrollment recovery — 2026-09-26

Added **Show code / QR** to participant rows, with a selectable code and QR
in a dialog after refresh. Added an authenticated collector action and migration
for server-only code recovery, gated to study owners/editors. Legacy hash-only
records receive a replacement typed code once; original QR tokens, device grants,
participant UUIDs, and collected data remain intact. Subsequent retrieval reuses
the persisted code. Updated deployment and architecture documentation.

Validation: formatting, admin analysis, backend TypeScript analysis and secret
checks passed; all 10 admin tests and 18 backend tests passed. Database regression
covers unauthorized retrieval, stable repeated recovery, and preserved grants.
Initial Flutter runs were blocked by sandbox sockets; approved runs exposed QR
dialog layout and loading-animation issues, both fixed before passing tests.
Online dependency resolution stalled; offline cached dependencies succeeded.
Live migration, collector redeployment and admin deployment remain required.

## Phases 11, 16 and 17 — Readable dataset names — 2026-09-27

Read the plan, architecture and existing enrollment/dashboard/export contracts,
then extended the implemented phases in order. Added migration
`202609270001_participant_numbers.sql`: transactional deterministic backfill,
private per-study counter, concurrent allocation trigger, uniqueness and identity
immutability. Existing participant UUIDs, enrollment credentials, device grants,
trial identities and R2 object keys are preserved. Shared participant models accept
both new numbered and legacy JSON; enrollment on multiple phones returns the same
number and UUID.

Added shared pinned-protocol naming in `packages/protocol_engine`, readable
participant/dashboard/file-list context and UUID diagnostics. Export files load
on opening the page independently of metadata export, with loading/empty/error
and refresh states. Frozen plans create deterministic generated folder paths with
full recording UUID collision suffixes. Free-text titles/prompts are excluded from
paths to prevent identifier leakage, while remaining readable in the console and
metadata (ADR 010).

Admin ZIP STORE parts preserve gzip bytes, verify size/SHA-256, include the exact
metadata snapshot and identity/path manifest, and report every failed selection
in a visibly partial download. Browser parts cap raw bytes at 32 MiB and 200 files;
large files are flagged for `scripts/download_dataset.py`, which streams all
verified files with fresh per-file authorization, atomic local writes, integrity
checks, resume and explicit partial reports. GET authorization, membership checks,
server-derived R2 keys and 15-minute expiry are unchanged. Added readable-path
support to the independent dataset verifier. Updated implementation plan, README,
export/setup/testing/schema docs and ADR 010.

Validation: affected Dart packages/apps formatted and analyzed without findings;
74 tests passed (11 models, eight protocol, 33 mobile, 22 admin). Backend formatting
and TypeScript checks passed, with all 21 tests (13 SQL, eight handler/storage)
passing. Twelve Python tests and Python compilation passed. An isolated PostgreSQL
17 container applied all migrations and passed 24 allocations through eight
concurrent connections plus rollback safety; the container was removed. Populated
backfill tests prove original enrollment credentials, device grants and R2 file
manifests survive. Independent Python ZIP parsing validates Dart-generated archive
CRCs, contents and partial manifests. Current-source secret/ignore checks passed.

Initial Flutter execution failed on sandbox socket restrictions; approved local
socket execution resolved that environment failure. New test fixture type errors
were corrected before the final passing runs. No failed test was skipped. Admin
release web compilation and Wasm compatibility dry run passed; no production
operation or remote object mutation was performed.

Remaining rollout/manual gates: apply the migration and updated admin in a reviewed
staging/deployment window; configure exact-origin R2 GET CORS; verify real researcher
Auth/RLS, revoked access, signed GET expiry, browser save/extraction, interrupted
transfers and realistic dataset sizes. The snapshot RPC still requires metadata
in memory and can explicitly fail at service limits; streaming avoids study-sized
raw buffering, not database snapshot limits. Existing hardware/signing/production
readiness gates remain open. Git-history validation is unavailable because this
workspace has no usable Git metadata.

## Phase 17 — Study-name export roots — 2026-09-27

Browser ZIPs and frozen streaming plans now use the sanitized study name as their
root folder (data_test stays data_test). Shared raw naming beneath the root, UUID
identities, manifests and R2 keys are unchanged. The streaming downloader accepts
portable readable roots and legacy UUID plans, rejecting reserved names and unsafe
paths. Updated export documentation, implementation plan and ADR 011.

Validation: Dart formatting and admin static analysis passed; 12 admin export tests
and 11 Python downloader/verifier tests passed. Initial Flutter dependency fetching
was cancelled; cached dependencies were used. Sandbox telemetry access initially
failed; approved local execution passed analysis and tests. No production changes
were performed. Deploy a rebuilt admin website and use the updated Python tool for
new plans; no database migration or Edge Function deployment is required.

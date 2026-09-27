# Production-readiness review — 2026-09-26

**Decision: not production-ready.** The repository implements the intended stack,
but native build/hardware, live authorization/storage, signing and history checks
remain open. Five high-severity correctness findings were repaired in this review;
their host-test evidence does not replace the external release gates below.

Reviewed the actual sources, migrations and tests against AGENTS.md and all phases
of IMPLEMENTATION_PLAN.md. Git metadata is unusable, so this is a current-source
review rather than a commit/history review. No architecture rewrite or deployment
was performed. Local files and existing migration files were preserved.

Severity: **blocker** prevents release validation or operation; **high** risks
incorrect acquisition, persistence, authorization or completion; **medium** has a
bounded workflow/data-interpretation impact with a documented workaround;
**low** is a minor usability/documentation issue.

## Findings and disposition

| ID | Severity | Finding and relevant code | Disposition/evidence |
| --- | --- | --- | --- |
| B01 | Blocker | Android SensorManager and iOS Core Motion integration have not been built/run on their required SDKs or the four-device matrix. [Native recorders](native-recording.md), [device matrix](hardware-pilot.md). | Open, external. Android build previously stopped at missing SDK; this Linux host cannot run Xcode/XCTest. Run framework builds/lint/XCTest and hardware scenarios, including the new 600-second boundary case. Kotlin writer tests and Swift formatting are insufficient substitutes. |
| B02 | Blocker | Auth/JWT/RLS through real Supabase HTTP, R2 signature/header/expiry enforcement, conditional retries and Edge runtime limits lack live evidence. [collector](../supabase/functions/collector/index.ts), [R2 adapter](../supabase/functions/_shared/r2.ts), [release gates](release-checklist.md). | Open, external credentials. Provision disposable staging and test owner/viewer/nonmember/anonymous actors, two-device enrollment, revoked grants, corrupted files, dropped responses and concurrent finalization. Apply the new migration before testing. |
| B03 | Blocker | Distribution signing and approved application identifiers are not configured. [Android release build](../apps/mobile/android/app/build.gradle.kts), [iOS project](../apps/mobile/ios/Runner.xcodeproj/project.pbxproj). | Open, account-specific. Supply organization identifiers, Android keystore and Apple team/profiles, then verify signed artifacts and permissions. Do not place signing secrets in source. |
| H01 | High | `LocalTrialCapture.start` captured its cancellation generation only **after** awaiting SQLite. An abort during that read could still start native sensors. [local_capture.dart](../apps/mobile/lib/collection/local_capture.dart), `start`. | Fixed. Reserve start and capture the generation before the first await; reject a cancelled read before native acquisition. A controlled real-SQLite regression failed before the fix and now passes, with zero native starts. |
| H02 | High | A failed native start acknowledgement cleared Dart's plan without aborting a potentially active native attempt. Same [start method](../apps/mobile/lib/collection/local_capture.dart). | Fixed. Native cleanup runs before the start fence is released. Regression reproduces a recorder that opens then throws; acquisition is aborted and a later retry succeeds. |
| H03 | High | `finalize_trial_upload` updated each file and counted completed trials without serializing the session first. Concurrent finalizers could both observe an incomplete count and leave every file synced but the session incomplete. [original RPC](../supabase/migrations/202609240004_uploads.sql). | Fixed in [new migration](../supabase/migrations/202609250004_finalize_serialization.sql). Acquire the session row lock before mutating the file, matching preparation's session→file lock order. A trigger-based regression asserts the lock exists at the mutation boundary. Real multi-connection execution remains part of B02. |
| H04 | High | A phone clock ahead of the server made the final session update violate `completed_at >= started_at`, rolling back verified finalization. Same original RPC and the [sessions constraint](../supabase/migrations/202609240001_core.sql). | Fixed in the new migration. Effective completion is clamped to the phone start time when necessary; file `uploaded_at` retains server time. Regression uses a start in 2099, verifies success and retry stability. These wall clocks must not be used to calculate gesture duration. |
| H05 | High | Protocols accepted 600-second timed tasks, but both native watchdogs failed at 600 seconds, before Flutter's timer (started after acknowledgement) could stop them. [Android recorder](../apps/mobile/android/app/src/main/kotlin/org/research/collector/collector_mobile/NativeSensorRecorder.kt), [iOS recorder](../apps/mobile/ios/Runner/NativeSensorRecorder.swift). | Fixed in source. Native watchdogs now allow one second for stop delivery, matching the existing 601-second finalization ceiling. Protocol maximum stays 600. Kotlin and Dart boundary checks pass; Swift boundary XCTest was added but awaits B01. Scheduler delays beyond that margin still fail safely. |
| H06 | High | Repository-history secret review cannot run because `.git` is unusable. [secret checker](../scripts/check_secrets.py). | Open, external checkout. Current-source/ignore checks pass; recognizable-secret scanning cannot prove that arbitrary unlabelled keys never existed. Scan full history and signed release artifacts in the real checkout; rotate any real exposed credentials. |
| M01 | Medium | Server protocol text validation checks nonempty text but lacks Dart's 4096-character bound; UUID acceptance also differs (server versions 1–5 vs Dart 1–8). A direct API publication can produce a version the mobile parser rejects. [SQL validation](../supabase/migrations/202609240003_protocol_editor.sql), [Dart validation](../packages/experiment_models/lib/src/validation.dart). | Open. Routine form publication uses the shared Dart validator and generated UUID v4. Restrict publication to that workflow for the pilot; align all server/client/schema bounds before supporting other publishers/import tools. Do not mutate an already published version to repair it. |
| M02 | Medium | Remote `physical_devices` retains first-enrollment metadata (`ON CONFLICT DO NOTHING`), although local registration refreshes OS/app/sensors. [enrollment SQL](../supabase/migrations/202609240002_enrollment.sql), [device registration](../apps/mobile/lib/storage/device_registration.dart). | Open. Per-trial app version and quality remain available, and requested Hz is in the pinned protocol, but remote device details can be stale. Record pilot device builds separately; implement authorized metadata refresh/versioned snapshots before using device-table values as historical acquisition metadata. |
| M03 | Medium | Switching versions or leaving the study replaces the editor without a dirty-state guard, discarding unsaved form changes. [protocol manager](../apps/admin/lib/protocols/manager.dart), [study navigation](../apps/admin/lib/study_home.dart). | Open. Save drafts before navigation. Add explicit unsaved-change protection; published versions and already saved drafts remain immutable/persisted. |
| M04 | Medium | Participant creation works, but correction of participant metadata, credential rotation/revocation and study membership management still require a trusted operator. [participant UI](../apps/admin/lib/participants.dart), [deployment instructions](deployment.md). | Open. Follow the documented operator process for the pilot; add role-checked management forms/RPCs to meet the full researcher-management mission. Never create a second participant merely to replace a lost code. |
| L01 | Low | For an ambidextrous participant, hand selection is shown even for a task requiring a fixed left/right hand; changing the selection has no effect on the resolved/stored hand. [participant instructions](../apps/mobile/lib/main.dart), [hand resolution](../packages/protocol_engine/lib/src/engine.dart). | Open. Stored hand still obeys the protocol and the instruction states that hand. Hide the selector for fixed-hand tasks in a future UI correction. |

## Coverage of the requested areas

| # | Area | Implementation and review evidence | Qualification |
| --- | --- | --- | --- |
| 1 | Local-first recording | [Local capture](../apps/mobile/lib/collection/local_capture.dart) only closes, finalizes and commits locally. No network call gates acquisition or Saved. | H01/H02 repaired; hardware B01 remains. An already-running transfer can finish during acquisition, documented in synchronization.md. |
| 2 | Native timestamps | Android writes `SensorEvent.timestamp` as integer nanoseconds. Swift passes Core Motion timestamps to [its writer](../apps/mobile/ios/Runner/RawCsvWriter.swift), converting seconds to integer nanoseconds. Dart uses BigInt and decimal strings for raw JSON. | No Flutter receipt-time substitution. Core Motion Double precision is retained, not improved by conversion. Cross-boot/device timestamps cannot be compared directly. |
| 3 | Normalized schema | Both writers emit the same seven-column header, quaternion x/y/z/w, SI acceleration/angular velocity and µT magnetic field. [Schema/units](dataset-schema.md), writer and sample-codec tests. | Native axes/reference frames are deliberately retained. Android rotation vector and iOS arbitrary-horizontal reference are not interchangeable world orientations; see frame note below and B01. |
| 4 | Recording state machine | [RecordingMachine](../packages/experiment_models/lib/recording.dart) guards transitions; [controller](../apps/mobile/lib/collection/controller.dart) guards taps, countdown, interruption, status checks and save ordering. | State-pair, delayed-start, timeout and late-reply regressions pass. H05 repaired in native sources, awaiting physical boundary verification. |
| 5 | Local persistence | [Drift database](../apps/mobile/lib/storage/local_database.dart) uses foreign keys, WAL/FULL sync, populated migration tests, checksum verification, and one trial/job/progress transaction. | Files survive failures; partial/orphan attempts are not promoted. Process-death recovery is tested by reopen, not actual OS/storage failure. |
| 6 | Sync/crash recovery | [Worker](../apps/mobile/lib/sync/sync_worker.dart), durable leases, attempt fencing, bounded backoff, abortable transfers, conditional PUT and immutable retry IDs. | Retry/restart/corrupt-file/manifest tests pass. H03/H04 repaired. Pending uploads need app execution/foreground return; there is no OS background-service guarantee. |
| 7 | Version pinning | [PinnedSession](../packages/protocol_engine/lib/src/engine.dart), immutable local version cache, [session store](../apps/mobile/lib/storage/session_store.dart) and SQL triggers. | Refresh/removal/reopen retains version and exact trial UUIDs. Protocol/server validation discrepancy M01 remains. |
| 8 | Participant identity | [Enrollment service](../supabase/functions/_shared/service.ts) resolves hashed code/QR to a participant; each phone gets a separate scoped grant and installation UUID. | Two simulated devices resolve the same participant in SQL tests. Live camera/enrollment/grant renewal belongs to B02. |
| 9 | Supabase/RLS | All migrations replay from empty PGlite; composite FKs, RLS, restricted grants, security-definer permission checks and invoker snapshot are exercised by [database tests](../scripts/backend/database.test.mjs). | Auth schema is a test substitute; actual JWT/Data API and concurrency remain B02. New migration preserves function grants. |
| 10 | Client secrets | Current Dart/native/client sources and environment plumbing were inspected; the [secret scan](../scripts/check_secrets.py) passed. Privileged keys are read only by the Edge bootstrap. | No privileged credential found in current client code. Detection is limited to recognizable formats/names; H06 remains. |
| 11 | Ignore rules | [.gitignore](../.gitignore) covers root/nested real env files, signing keys/properties, generated tooling and dependencies. Example env files remain versionable. | Actual Git ignore behavior is tested in a temporary checkout. The current workspace cannot establish whether a file was historically tracked. |
| 12 | R2 authorization | Server-scoped participant/device RPC derives object keys; [signer](../supabase/functions/_shared/r2.ts) signs TTL, type, length and conditional creation. Researcher downloads recheck membership. | No client-selected storage key is trusted. SigV4 acceptance and expiry/header enforcement require B02. |
| 13 | File integrity | [Finalization](../packages/dataset_schema/lib/finalization.dart) validates native count, CSV, ordering and gzip; SHA-256/size checked before commit and transfer. Server rehashes actual R2 bytes. | Known digest, truncation, extra-row, corrupt gzip/object and manifest-conflict regressions pass. Local copies are never automatically deleted. |
| 14 | Quality metrics | [Streaming accumulator](../packages/dataset_schema/lib/quality.dart) calculates per-sensor counts, sample-span duration, observed rate, instantaneous-rate population deviation, interval stats and estimated missing samples. | Estimates use requested rate and do not prove hardware loss. Insufficient samples and unknown values stay explicit. H04 avoids deriving durations from wall clocks. |
| 15 | Protocol editor | [Forms](../apps/admin/lib/protocols/editor.dart) support sessions/tasks, ordering/duplication, hand/posture/device/type, repetition, preview, validation, drafts/publication/history. | Routine editing needs no JSON. Published versions are guarded in UI/domain/SQL. M01/M03/M04 remain; large-protocol usability is not yet physically/browser benchmarked. |
| 16 | Participant UI | [Collection screens](../apps/mobile/lib/main.dart) expose code/QR, one task, instructions, countdown, recording, safe-save confirmation and retry without IDs/storage/backend details. | Offline full-session, double-tap and basic small-screen accessibility tests pass. L01 remains; real participant pilot is B01. |
| 17 | Export | [Canonical export](../apps/admin/lib/export/metadata.dart), consistent RLS snapshot, individual authorized raw downloads and [independent verifier](../scripts/verify_dataset.py). | Metadata is deterministic for unchanged data and excludes credential tables/signed links. Large-study response limits and real browser/R2 downloads require B02; raw bundle download is intentionally not implemented. |
| 18 | Tests/hardware plan | Unit/widget/SQLite/PGlite/HTTP/Python/Kotlin tests plus [hardware-pilot.md](hardware-pilot.md) cover interruptions, offline work, low storage, sensors, sampling, process death and pilot integrity. | The physical matrix remains NOT TESTED. Passing fakes/host tests does not close B01–B03. |

## Native frame interpretation

Normalization means matching columns, units and timestamp encoding, while keeping
native sensor observations. It does not align orientation reference frames. The
checked-in Android path uses `TYPE_ROTATION_VECTOR`; the Swift path explicitly uses
`.xArbitraryZVertical`. Apple's [reference-frame documentation](https://developer.apple.com/documentation/coremotion/cmattitudereferenceframe/xarbitraryzvertical)
defines an initially arbitrary horizontal X direction, while Android's
[motion-sensor documentation](https://developer.android.com/develop/sensors-and-location/sensors/sensors_motion)
describes its rotation-vector frame. Dataset consumers must account for the platform
and validate transforms/sign conventions with known static poses and rotations;
do not pool raw quaternions as if they share a heading. No unverified sign/axis
conversion was introduced during this review.

## Validation performed

- Full Flutter workspace formatting/analyzers and 73 tests pass: 11 models,
  11 dataset, eight protocol, 33 mobile, ten admin.
- Backend formatting, TypeScript checking and 17 tests pass: ten SQL tests from
  fresh migrations and seven handler/storage tests. Lock-order regression observes
  actual `pg_locks` at the file update, but PGlite cannot simulate independent
  database connections. Its single-backend PID is 0 with null lock PIDs; the test
  explicitly accounts for that representation.
- Seven Python integrity/secret-scanner tests and current-source/ignore checks pass.
- Kotlin sources/tests formatted and writer tests compiled/executed successfully.
  Swift sources/XCTest formatted and linted; XCTest execution is not available here.
- Two new mobile regressions were first run against the original implementation
  and failed as expected. The first SQL lock assertion assumed a normal backend PID
  and still failed after the fix; inspecting PGlite locks identified the harness
  mismatch, which was corrected before the successful full rerun. No failure was
  silently excluded. The initial isolated Node `--test` invocation did not produce
  detailed failures here; the project's normal Node runner provided the failure
  and was used for the subsequent full runs.

## Required manual steps before reconsidering release

1. Apply **all eight migrations**, including
   `202609250004_finalize_serialization.sql`, to disposable staging. Preserve old
   migrations and data. Repeat live role/tenant/revocation tests from
   [supabase/tests/README.md](../supabase/tests/README.md).
2. Prepare a two-trial test session and finalize its two verified files using
   independent PostgreSQL connections concurrently. Hold the first transaction
   open before commit; the second finalizer must wait, then observe both synced
   files and complete the session. Repeat finalization and confirm unchanged IDs
   and timestamps. Also test preparation racing with finalization for deadlocks.
3. Supply the public values in root `.env.example` and the server-only values in
   `supabase/functions/.env.example` using private deployment configuration.
   Verify real Supabase Auth/RLS and R2 signed headers, URL expiry, 412 retries,
   checksums, largest-trial runtime and export downloads. No real secret is needed
   in a client build, test fixture or report.
4. Install/configure Android SDK and a supported macOS/Xcode/CocoaPods environment;
   build both runners and execute native tests. Supply signing/account identifiers
   privately and inspect signed release artifacts for secrets and permissions.
5. Execute every [hardware scenario](hardware-pilot.md) on two Android manufacturer
   families and two iPhone generations where possible. Include 600-second timed
   tasks, a stopped/unresponsive native recorder, interrupted SQLite preparation,
   low storage, process death and known-pose/quaternion comparisons. Obtain the
   supervised 5–10 participant pilot approvals.
6. Scan full history in a usable checkout and record source revision, build hashes,
   migration list, protocol versions and signed evidence. Resolve or explicitly
   accept the medium/low workflow limitations with the study owner. Production
   readiness must not be asserted while B01–B03 or H06 remain open.

# IMPLEMENTATION_PLAN.md

This plan is meant to be executed autonomously by Codex. Complete phases in order. Do not skip validation/tests at the end of each phase.

## Phase 0 — Inspect and bootstrap

Goals:
- inspect existing repository before changing anything;
- preserve useful existing work;
- create missing monorepo structure;
- add `AGENTS.md`, `.gitignore`, `.env.example`, docs skeleton, and `docs/PROGRESS.md`;
- ensure Flutter/Dart tooling is configured consistently.

Acceptance:
- mobile app starts;
- admin web app starts;
- shared packages can be imported;
- `.env` and secret files are ignored;
- analysis/test commands are documented and pass.

## Phase 1 — Shared domain and dataset model

Implement typed shared models for:
- Study
- Participant
- PhysicalDevice
- Protocol
- ProtocolVersion
- Session
- Trial
- TrialFile
- sensor/quality summaries

Include:
- UUID identifiers;
- schema/protocol/app versions;
- serializers;
- enums for posture, hand, task type, sync status, device role;
- validation rules.

Acceptance:
- unit tests cover serialization and validation;
- dataset schema is documented.

## Phase 2 — Protocol engine

Implement:
- JSON protocol schema;
- parser/serializer;
- validation;
- protocol version model;
- session/task ordering;
- trial queue generation;
- cacheable protocol representation;
- example protocol representing the current study needs.

Support:
- sessions;
- prompts;
- gestures/tasks;
- repetitions;
- posture;
- hand;
- device role;
- practice/genuine/impostor;
- optional instructions.

Acceptance:
- invalid protocols return actionable errors;
- published version model is immutable in domain logic;
- unit tests cover queue generation and version pinning.

## Phase 3 — Mobile UX shell

Implement participant/researcher collection flows with mock data first:
- participant code/QR entry;
- session overview;
- task instruction;
- countdown;
- recording screen;
- saved confirmation;
- next-trial navigation;
- diagnostic/researcher screen hidden from normal participant flow.

Use the protocol engine rather than hard-coded sequences.

Acceptance:
- a complete fake session can be executed with no backend;
- double-start/double-stop are impossible at UI/state level;
- accessibility/basic responsive layout is acceptable.

## Phase 4 — Recording state machine

Implement an explicit, testable state machine:
- idle
- ready
- countdown
- recording
- stopping
- validating
- saved
- failed

Keep it independent from Flutter widgets.

Acceptance:
- invalid transitions are rejected;
- state restoration behavior is defined;
- comprehensive unit tests pass.

## Phase 5 — Android native sensor recorder

Use Kotlin `SensorManager`.

Support when available:
- accelerometer;
- gyroscope;
- gravity;
- rotation vector;
- magnetic field.

Requirements:
- native monotonic timestamps;
- sensor metadata;
- native buffering;
- batched raw-file writes;
- start/stop boundaries tied to trial ID;
- no per-sample Flutter/SQLite round trip.

Acceptance:
- native recorder can record a test trial;
- Flutter receives capability/status/result messages;
- file is well-formed;
- unavailable sensors are reported, not fatal.

## Phase 6 — iOS native sensor recorder

Use Swift/Core Motion.

Support when available:
- accelerometer;
- gyroscope;
- magnetometer;
- deviceMotion gravity;
- attitude/quaternion.

Apply the same normalized data contract used by Android.

Acceptance:
- iOS recorder implements the same Dart-facing interface;
- monotonic timestamps are preserved;
- unavailable sensors are reported;
- output format matches shared schema.

## Phase 7 — Local file finalization and quality metrics

After stop:
- flush/close raw file;
- compute duration;
- compute per-sensor sample counts;
- mean sampling rates;
- sampling-rate standard deviation;
- inter-sample interval statistics;
- estimate dropped samples where meaningful;
- gzip file;
- calculate SHA-256 and file size;
- generate trial metadata.

Acceptance:
- deterministic tests for metrics;
- checksum tests;
- corrupt/incomplete trial handling documented.

## Phase 8 — Drift/SQLite local persistence

Implement local tables for:
- cached participants;
- cached protocols;
- sessions;
- trials;
- physical device record;
- sync queue.

Implement durable sync statuses:
- local
- queued
- uploading
- synced
- failed

Acceptance:
- app restart preserves unsynced trials;
- sync queue is idempotent;
- DB migration strategy exists and is tested.

## Phase 9 — Physical device registration

On first app run:
- generate stable local `physical_device_id`;
- store safely;
- collect device/OS/app version;
- collect sensor capabilities/metadata where available.

Do not use unstable advertising/device tracking identifiers as the research device ID.

Acceptance:
- same app installation keeps same physical device UUID across restarts;
- reinstall behavior is documented.

## Phase 10 — Supabase database and Auth

Create migrations for:
- studies
- researcher_profiles
- study_members
- participants
- physical_devices
- protocols
- protocol_versions
- sessions
- trials
- trial_files

Add:
- foreign keys;
- indexes;
- timestamps;
- RLS;
- role/permission rules.

Implement researcher/admin authentication.

Acceptance:
- migrations can recreate schema from scratch;
- RLS tests or documented verification queries exist;
- service role key never appears in client code.

## Phase 11 — Participant enrollment across devices

Implement backend flow:
- create pseudonymous participant;
- generate short human-friendly participant code;
- create QR enrollment payload/token;
- resolve participant on another phone;
- return the same participant UUID;
- do not expose direct identifiers.

Acceptance:
- two simulated devices resolve one participant to the same UUID;
- collisions are handled;
- rate-limiting/security considerations documented.

## Phase 12 — Protocol admin console

Implement admin UI for:
- list protocols and versions;
- create draft;
- edit sessions/tasks in forms;
- reorder tasks;
- duplicate tasks;
- set repetitions/posture/hand/device role/type;
- validate;
- preview participant flow;
- publish immutable version;
- duplicate a published version into a new draft.

Raw JSON import/export may be an advanced feature.

Acceptance:
- routine protocol changes require no source-code changes;
- already-published protocol version cannot be edited.

## Phase 13 — Mobile protocol synchronization

Implement:
- fetch active/assigned protocol version;
- local cache;
- pin session to exact protocol version;
- offline reuse;
- refresh without breaking in-progress session.

Acceptance:
- app can start a cached session offline;
- new protocol publication does not alter an existing session.

## Phase 14 — Cloudflare R2 upload authorization

Create Supabase Edge Function(s) for:
- validating authenticated caller;
- validating trial/study ownership/permission;
- generating short-lived signed R2 upload URLs;
- safe object-key construction;
- finalization/verification.

Create server-only environment configuration.

Acceptance:
- no R2 secret exists in Flutter build;
- signed URLs expire;
- object keys cannot be arbitrarily overridden by the client.

## Phase 15 — Sync engine

Implement:
- background/foreground sync worker;
- request signed upload URL;
- upload `.csv.gz`;
- retry with bounded backoff;
- finalize Supabase metadata;
- verify server state;
- mark local trial `synced`.

Handle:
- network loss;
- app kill;
- duplicate retry;
- expired signed URL;
- R2 unavailable;
- Supabase unavailable.

Acceptance:
- synchronization is idempotent;
- trial data remains locally safe until remote verification;
- restart resumes pending work.

## Phase 16 — Researcher dashboard

Implement:
- participant counts/progress;
- session completion;
- per-participant trial progress;
- device list;
- unsynced/failed uploads;
- quality warnings;
- protocol version used;
- participant QR/code display.

Acceptance:
- researchers can identify incomplete/bad sessions without opening raw files.

## Phase 17 — Dataset export

Implement an admin/server export flow producing metadata tables and raw-file references/download bundle as appropriate.

Minimum metadata exports:
- participants
- devices
- sessions
- trials
- trial files
- protocol versions

Keep canonical raw files organized by UUID hierarchy.

2026-09-27 refinement: readable admin labels and exported copies extend Phases
11/16/17. Allocate study-scoped participant numbers centrally; preserve UUIDs and
R2 keys; resolve labels from pinned versions; provide automatic file-list loading,
bounded browser ZIP parts, a streaming export tool, and frozen path manifests.
See ADR 010/011 and docs/export.md. Export roots now use sanitized study names.

Acceptance:
- export is reproducible;
- it records schema/protocol versions;
- no secrets are included.

## Phase 18 — Robustness and privacy review

Test/document:
- offline recording;
- network loss;
- app background;
- call/interruption;
- double taps;
- process death;
- low storage;
- unavailable sensor;
- slow/irregular sensor rate;
- protocol update during session;
- partial upload;
- duplicate upload.

Review:
- logs for sensitive data;
- RLS;
- object paths;
- secret handling;
- accidental participant-code exposure.

## Phase 19 — Hardware pilot readiness

Create:
- manual test checklist;
- release build instructions;
- Android/iOS permissions documentation;
- signing/deployment steps;
- first-pilot checklist for 5–10 participants;
- bug-report template;
- data integrity verification script.

Do not require live production credentials to finish code/documentation.

## Phase 20 — Production readiness

Before declaring done:
- run format/analyze/tests;
- remove dead debug paths;
- verify `.env` and secret files are ignored;
- verify no service/R2 secret in repository history/current files;
- verify fresh setup instructions;
- verify migrations from empty DB;
- verify export;
- update `README.md`;
- update `docs/PROGRESS.md`;
- list remaining manual deployment steps.

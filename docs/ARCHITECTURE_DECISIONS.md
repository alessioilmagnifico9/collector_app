# Architecture decisions

## ADR 001 — Required stack and workspace tooling

Accepted 2026-09-23. Use Flutter for both clients, independent Dart domain packages,
Kotlin/Swift native acquisition, Drift/SQLite metadata, Supabase metadata/Auth and
Edge Functions, and R2 raw objects. No architecture deviation.

Pin Flutter 3.47.5 for reproducible development; keep downloaded SDKs/caches outside
versioned source. Package lockfiles are retained. Native build/signing and device
verification remain explicit release gates, even when host tests pass.

## ADR 002 — Nanosecond serialization and immutable snapshots

Accepted 2026-09-23. Preserve monotonic nanoseconds as decimal strings in JSON and
integer text in CSV. Dart domain samples use BigInt so Flutter Web cannot silently
round values above 2^53. Metadata UUIDs remain strings validated at the boundary.
Protocol documents and nested collections are defensively copied and frozen;
publication and session pinning operate on exact version identities. Undefined
quality/hardware values remain null. This refines the required stack without a
technology deviation.

## ADR 003 — Foreground trials and interruption policy

Accepted 2026-09-23. Research trials require the app in the foreground and keep the
screen awake during acquisition. Backgrounding, incoming-call interruptions,
native errors and the safety watchdog invalidate the active attempt;
native writers retain `.partial` files for review. They never label an interrupted
attempt Saved. Users repeat the same planned trial with a new attempt filename.
Completed files are atomically renamed after flush/fsync. This avoids falsely
claiming uninterrupted iOS background collection; it does not change offline use.

Refined 2026-09-26: protocols still allow at most 600 seconds. The native watchdog
is 601 seconds to allow a bounded stop-delivery margin, matching finalization's
existing duration ceiling. A maximum-duration task no longer races an equal native
timeout. Delays beyond the margin still invalidate the attempt; hardware validation
must exercise this boundary.

## ADR 004 — Atomic save and upload attempt fencing

Accepted 2026-09-24. Keep raw/gzip files separate from SQLite, then atomically commit
trial metadata, the upload job and session progress after checksum verification.
An orphan file is recoverable evidence, not a completed trial. Preserve the original
file manifest and use the durable queue as the authoritative local sync status.
Fifteen-minute upload leases and monotonic attempt counters reject stale completions.
This refines the required local-first architecture without changing the stack.

## ADR 005 — Researcher database access and local SQL verification

Accepted 2026-09-24. Use Supabase Auth researcher sessions with study membership
roles enforced by RLS. Participant clients have no direct database grants; their
operations will go through scoped Edge Function authorization. Extra composite
foreign keys prevent cross-study identities even on service writes. PGlite is a
development-only PostgreSQL test engine for migrations/RLS on this host, which has
no Docker/Postgres server. It does not replace Supabase or live API verification.

## ADR 006 — Participant credentials without user accounts

Accepted 2026-09-24. Enrollment resolves a stable participant through a random
10-character code or 256-bit QR token, stored as server-side hashes. Each phone
receives a separate random bearer grant scoped to participant/device; the server
stores its hash and expiry. Backup-excluded local SQLite retains grants per
participant so changing the active enrollment does not strand pending uploads.
Grant expiry/revocation affects network operations, never recording durability.
No participant Supabase Auth account or privileged client key is introduced.

## ADR 007 — Conditional raw object creation and remote hashing

Accepted 2026-09-24. Sign conditional R2 PUTs for canonical UUID keys so retry URLs
cannot overwrite existing research data. Finalization streams and hashes the actual
compressed object, rather than trusting client-provided checksum metadata or an ETag.
Remote conflicts are retained for investigation. The server keeps metadata pending
until verification succeeds; local data is never deleted by this pipeline.

## ADR 008 — Consistent snapshots and separate download authorization

Accepted 2026-09-25. Use a security-invoker PostgreSQL snapshot function for dashboard
and metadata export, preserving existing RLS. Canonical JSON tables are stable for
unchanged records; signed raw download links are authorized separately and never
embedded in the export. The initial console offers individual verified-file downloads;
it does not buffer an entire study archive in an Edge Function. Offline-only records
remain explicitly unknown to the remote dashboard. This refines the existing stack.

## ADR 009 — Serialized completion and independent wall clocks

Accepted 2026-09-26. Finalization locks the session before changing file status,
using the same lock order as upload preparation. Concurrent finalizers must count
committed verified files after obtaining that lock so that the last upload marks
the session complete. Retries preserve the original uploaded/completed timestamps.

A phone may start a session offline with its clock ahead of the server. Store
`completed_at` as an effective completion time no earlier than `started_at`, using
`greatest(started_at, clock_timestamp())` for the initial completion. This prevents
clock skew from rolling back verified uploads under the existing chronology
constraint. The actual server upload time remains in `trial_files.uploaded_at`.
Do not infer gesture duration by subtracting these independent wall-clock fields;
quality duration uses native monotonic samples. No schema/stack change is required.

## Recoverable admin enrollment codes — 2026-09-26

Store the human-readable enrollment code in the existing service-role-only
credential table to allow authorized study owners/editors to reopen enrollment
after refresh. Continue using hashes for enrollment lookup and QR token storage.
A recovered QR encodes the same human-readable code accepted by enrollment.
Legacy hash-only codes cannot be reversed; first retrieval replaces only that
code, preserving original QR tokens, participant identity, and device grants.
No client table access is granted; retrieval checks membership server-side.

## ADR 010 — Central display numbers and readable export copies

Accepted 2026-09-27. Extend Phases 11, 16 and 17 without changing the required
stack, primary/foreign keys, local recording, protocol pinning or R2 objects.
Participant numbers are immutable study-scoped integers allocated by a private
counter and insert trigger. Atomic UPSERT serializes concurrent registration;
the transactional migration locks participants while backfilling by created_at
and UUID and initializing counters. Deleted numbers are never reused. Legacy
JSON remains parseable and is labelled explicitly rather than assigned a number
by a phone/browser.

Refine ADR 008's initial individual download UI: construct bounded ZIP STORE
parts in the browser and provide a Python standard-library streaming workflow
for larger files/datasets. Both use the same frozen metadata/path manifest and
existing per-file authorization. No raw study archive is built in Edge memory,
no privileged client credential is added, and no R2 key is renamed. SHA-256/size
verification precedes inclusion; partial reports include every failed selection.

The Phase 17 plan's UUID raw hierarchy continues to describe canonical storage.
Downloaded copies use generated ordinal folders and UUID collision suffixes.
Free-text titles/prompts do not enter paths because they cannot reliably be
sanitized for privacy (a syntactically safe string may still contain a real
name). Readable titles remain in the console and pinned metadata. Ordinals are
snapshot-relative, and manifests bind paths to exact UUIDs and metadata bytes.
This is a presentation/export refinement, not an acquisition or storage deviation.

## ADR 011 — Study names in exported root folders

At the user's request, exported copies use a portable sanitized study name as the
root (for example `data_test/`), rather than the UUID-only root in ADR 010.
This applies to browser ZIPs and streaming plans; canonical R2 keys and internal
identities are unchanged. Names are frozen with the snapshot; manifests retain
study UUIDs. Separate destinations prevent collisions between identically named
studies. Legacy UUID-root streaming plans remain accepted. Task prompts and other
free-text fields remain excluded from paths.

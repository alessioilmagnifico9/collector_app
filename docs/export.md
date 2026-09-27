# Dataset export

Open a study's **Export** tab. The file list loads automatically; **Refresh files**
replaces the displayed snapshot. The list shows participant numbers, pinned protocol
session/task names, session attempts, task type, repetition, recording number and
distinct device labels. Expand a row for UUIDs, original R2 key and SHA-256.
Loading, empty and failed-load states do not require exporting metadata first.

**Export metadata JSON** saves the displayed database snapshot, with schema version 1
and UUID-keyed participants, devices, protocols, protocol_versions, sessions, trials
and trial_files. **Download ZIP part** downloads up to 32 MiB of compressed raw
bytes and 200 files per part. The row download control creates a one-file ZIP.
Extracting a ZIP actually creates its readable folders; a browser download does
not claim to create a folder hierarchy on its own. Each archive contains:

- unchanged `*.csv.gz` bytes, checked against the snapshot size and SHA-256;
- `metadata.json`, identical across all parts of this snapshot;
- `manifest.json`, mapping every selected path (including failed files) to study,
  participant, session, trial, physical-device and protocol-version UUIDs, protocol
  version number, schema version, original R2 key, compressed size and SHA-256;
- `export-report.json`, recording whether this part is complete and all failed paths.

Download **every** ZIP part for the complete browser-sized selection. A failed
transfer produces a prominently marked `-PARTIAL.zip`, a UI count and a report;
failed files are never silently excluded from the manifest. Retry the same part
without refreshing to retain the same snapshot. Save/extract each part separately
first so its manifest/report is not overwritten, then combine the raw directories.
The browser can confirm archive preparation, not whether the user accepted its
save dialog. Pending/failed uploads and data still only on offline phones are not
selected; their metadata remains in the snapshot.

## Naming and identity

Example (UUID placeholders abbreviated only for documentation):

```text
data_test/
  participant-000123/
    session-01-attempt-01/
      task-001/
        genuine-repetition-001-recording-<trial_uuid>.csv.gz
        practice-repetition-001-recording-<trial_uuid>.csv.gz
```

Participant numbers are centrally allocated within a study, positive integers,
padded to at least six digits. They are immutable and independent of enrollment
codes. A participant's UUID and number are identical on every phone. Old clients
may ignore the added JSON field. Unmigrated snapshots are explicitly labelled
legacy and use `participant-legacy-<participant_uuid>`; numbers are never invented
locally. UUIDs remain in metadata and diagnostics.

Session/task ordinals are one-based positions in the **pinned** protocol document,
never the currently active version. Session attempts are ranked by `(started_at,
session UUID)` within participant and session ordinal across protocol versions.
The UI always shows the pinned version and title. Recording numbers are ranked by
`(created_at, trial UUID)` within session/task/type/repetition. Device labels are
ranked by device UUID and include the model, so identical models remain distinct.
Local interrupted attempts that never uploaded are unavailable to the admin; the
console does not invent retry counts for them.

The root folder uses the study name, lowercased and sanitized to ASCII letters,
digits, underscores and hyphens (maximum 80 characters). For example, `data_test`
stays `data_test`; `Data Test` becomes `data-test`. Empty sanitized names fall back
to `study-<study_uuid>`, and reserved Windows names receive a `study-` prefix.
Study names are now included in exported paths; use pseudonymous study titles.
Keep different study snapshots in separate destinations, since titles can match.
Other path segments use generated tokens and UUIDs. Prompts, session titles,
device names and enrollment codes do not enter paths. This avoids leaking identifiers from a prompt
and handles Unicode, separators, reserved Windows names, punctuation and empty
slugs without ambiguous sanitization. Names remain readable in the UI and metadata;
`task-001` resolves to its pinned prompt there. Every filename carries the full
trial UUID, so practice/main trials, repeated sessions, devices and legacy retries
cannot overwrite one another even if all human labels match. R2 keys remain
`study/<study>/<participant>/<session>/<trial>/sensors.csv.gz`; no objects are moved.

Attempt and device ordinals are snapshot-relative. A later offline upload can
change ranks in a **new** snapshot; an existing plan/archive is frozen and remains
reproducible. Do not mix files/manifests from different snapshots. Metadata arrays
sort by UUID and JSON keys sort recursively, giving identical bytes for unchanged
records. Manifest `metadata_sha256` binds each part to the exact UTF-8 metadata.

## Large datasets: streaming download

Browser parts bound raw payload memory, but ZIP assembly, Blob creation and the
metadata snapshot require additional memory. Files above 32 MiB are explicitly
excluded from browser parts and require the streaming tool. **Save streaming
download plan** includes *all* verified files and the same frozen snapshot. Use
Python 3.10+ (standard library only):

```sh
python3 scripts/download_dataset.py study-<uuid>-download-plan.json ./dataset \
  --collector-url https://<project>.supabase.co/functions/v1/collector
```

The tool prompts without echo for a current **researcher Supabase Auth access
token**, obtained from your authenticated researcher session. It also accepts
`COLLECTOR_RESEARCHER_TOKEN` from a protected process environment. Never use a
participant code or a service-role key. Do not paste tokens into command arguments,
plans, source files or reports. A token may expire during a long export; rerun with
a fresh researcher token. Every missing file obtains a fresh server-authorized
15-minute URL immediately before transfer. Existing locally verified bytes are
reused on resume; conflicting local files are reported, not overwritten.

Raw transfers stream in 1 MiB chunks into temporary files and atomically rename
only after size/hash verification, without decompressing or changing gzip bytes.
No study-sized raw archive is buffered. Metadata and manifests still need memory;
the current database snapshot RPC is a single result. If database/API snapshot
limits are exceeded, loading fails explicitly. Partitioned server export jobs
remain a future scaling option; test the expected study size before a pilot.

The tool writes `metadata.json`, `manifest.json` and `export-report.json`; exit 1
means partial. A failed file does not stop subsequent files. Retry the same plan
and destination. Paths, mappings and metadata digest are validated; symlinks and
conflicting snapshots are refused. Authorization errors and signed URLs are not
written to reports. The plan contains no reusable credentials or signed URLs.

## Authorization and setup

Every remote file still uses `download_trial`: researcher Auth verification,
study membership check, synced-file check, then server-derived R2 key and a
15-minute signed GET. No permission comes from the manifest or display number.
Membership revocation prevents future URL issuance; already issued URLs retain
their existing expiry. Clients never receive privileged R2/Supabase credentials.
Enrollment credentials and grants are excluded from exported metadata.

Browser ZIP downloads fetch R2 bytes, so the private bucket must allow **GET CORS**
from your exact admin origin. Add that origin/method to the bucket's CORS rules;
keep the bucket private. Validate browser GET, URL expiry, access revocation,
corrupted/interrupted downloads and realistic dataset sizes against staging R2.
CLI downloads do not need browser CORS. No live configuration is changed by this
implementation.

## Independent verification

For a complete streaming export:

```sh
python3 scripts/verify_dataset.py ./dataset/metadata.json ./dataset \
  --manifest ./dataset/manifest.json
```

For combined ZIP parts, repeat `--manifest` for every part's retained manifest.
Without `--manifest`, the verifier continues to accept the original UUID raw
hierarchy. It checks identities, pinned tasks, file sizes, gzip hashes, CSV shape,
monotonic sensor timestamps and sample counts. Missing verified files fail;
pending uploads are counted separately. A single part of a multi-part study will
correctly fail full-study verification until the other files/manifests are supplied.

Session `started_at` is a phone wall clock; `completed_at` is effective server
completion clamped to the start if needed. Use monotonic quality duration for
gesture timing, not subtraction of independent wall clocks (ADR 009). Treat all
exports as research datasets even though identities are pseudonymous.

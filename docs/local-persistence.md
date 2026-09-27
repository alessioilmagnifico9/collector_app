# Local durability and recovery

Drift schema version 3 stores cached participants and immutable published versions,
pinned session queues/progress, the installation device record, saved trial/file
metadata and upload jobs. Foreign keys are enabled, with WAL and FULL synchronous
writes. The v1-to-v2 migration adds the nullable upload error code; v3 adds the active
enrollment cache and per-participant device credentials without dropping records. Future releases must add an explicit incremental migration and a populated
upgrade test; unknown upgrades fail closed.

A recording closes natively before Dart validates/compresses it. The number of
parsed CSV samples must match the native closure count before compression; this
also rejects truncation at a complete row boundary. A mismatch retains the raw
file and leaves session progress and the sync queue unchanged. The compressed
checksum is verified before a single SQLite transaction saves the trial, creates
its `local` sync job and advances session progress. Only that commit permits Saved.
Files are never deleted by this layer. A failed commit leaves raw/compressed bytes
for inspection and leaves the planned trial unfinished. A process death before the
commit requires repeating that trial; orphan/partial attempts are not labeled saved.
A process death after commit restores the next task, even before Continue was tapped.

Opening a participant's session resumes its most recent local snapshot, including
its exact version and trial UUIDs. A completed session remains completed; explicit
researcher-authorized repeat-session workflows are not yet implemented.
Enrollment and refresh abort stalled HTTP transfers after 30 seconds, including
response-body reads. A failed request leaves the previous cached enrollment and
device credential available for offline use and a later retry.

Recovery queues local jobs and expires abandoned upload leases. Claims increment
an attempt counter, which acts as a fencing token: an older or expired attempt
cannot finalize a newer claim. Failures use bounded exponential retry delay. Only
verified finalization can mark a job synced. The queue is the authoritative local
sync state; the original trial-file payload is the immutable local-save manifest.
The upload worker and remote verification adapter are described in
[synchronization](synchronization.md).

Host integration tests use real file-backed SQLite and actual gzip/checksum files,
including restart, rollback, upload lease expiry, duplicate saves and populated v1
migration. They do not prove filesystem durability on physical phones.

## Installation identity

Normal mobile startup asks the native channel for a private storage directory,
opens `collector.sqlite`, registers the device and recovers queued jobs. Android
uses `Context.noBackupFilesDir`; iOS uses Application Support with backup exclusion.
The database lives alongside the native trials directory. The installation UUID is
random, stored in SQLite, and preserved when capability/OS/app metadata refreshes.
No advertising ID, phone identifier, participant code or platform tracking ID is
used. Reinstall/clearing app data creates a new UUID; enrollment still resolves the
same participant centrally. Do not restore/copy a research database to another
phone: that would copy its installation identity. Startup storage failures block
collection with a participant-safe message.

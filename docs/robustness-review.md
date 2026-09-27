# Robustness and privacy review

Review date: 2026-09-25. This records source/host-test evidence, not hardware approval.

| Scenario | Automated evidence | Remaining physical/live check |
| --- | --- | --- |
| Offline recording and reopening | Real SQLite/file capture and session-cache tests | Airplane-mode native acquisition on every pilot device |
| Network loss / partial or duplicate upload | HTTP and durable retry tests; conditional creation; server byte hashing | Drop Wi-Fi during real R2 PUT and finalization |
| Process death | SQLite reopen, upload lease recovery and pinned trial UUID tests | Force-kill after Saved and during transfer |
| Background / call / delayed start | Explicit interruption state; delayed-start regression | Real incoming call, lock, app switch, permission interruptions |
| Double start / stop | State-pair and widget tests; native attempt guards | Rapid taps on phones |
| Save failure / low storage | Failed SQLite insert rolls back progress; save cannot display Saved | Fill sandbox storage, fail native write/fsync and gzip |
| Native failure / stalled status | Trial-specific health checks, bounded polling and late-reply fencing | Inject native sensor/I/O errors during a physical recording |
| Whole-row raw truncation | Native closure count checked before compression; no trial/job/progress commit | Kill or exhaust storage during native closure |
| Unavailable / irregular sensors | Writer tests and deterministic gap/rate quality tests | Phones with missing magnetometer and throttled sampling |
| Protocol publication during session | Refresh/removal/restart preserve pinned snapshot | Two live devices and admin console |
| Local disposal during commit | Storage close waits for pending capture/save futures | OS termination is abrupt; reopen and inspect |
| Duplicate planned repetitions | SQL quota under session lock; retries retain UUID | Concurrent live requests |
| Export consistency / access | Canonical metadata, RLS snapshot, raw-download authorization tests | Browser downloads plus independent integrity verification |

Source review found no participant codes, tokens, signed URLs or sensor payloads
logged by collection/enrollment/sync/Edge code. Errors exposed to participants are
coarse; queue errors contain a fixed code. Enrollment text is cleared on successful
entry. Server credential/grant tables have RLS and no client grants. UUID-only raw
paths are derived server-side. Published versions and session identities are guarded
by database triggers. The source has no usable Git history; historical secret scans
remain an explicit gate in a real checkout.

Storage uses private backup-excluded application directories, with Android backup
disabled. Participant grants are stored in that local database, not exported. The
app relies on OS application storage isolation and device protection; it does not
claim application-level database encryption. Define study retention/access rules
and institutional device-management requirements before deployment. There is no
automatic local data deletion and no unsupervised remote deletion workflow.

Completion review fixed: completed-session navigation; a delayed start could release
retry too early; disposal could close storage during a commit; extra trial UUIDs
could inflate completion by repeating the same task slot; dominant-hand validation
was absent server-side. Quotas respect both main and optional practice multiplicity.

Pending verification: Android framework compilation/lint, iOS compilation/XCTest,
physical acquisition, actual Supabase JWT/RLS and R2 signature/timeout performance.
Host passing results alone do not establish production readiness.

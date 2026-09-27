# Hardware pilot checklist

Do not call the application production-ready until this checklist has recorded
results. Use test participants first, then a supervised pilot of 5–10 consenting
participants under the study's approved procedures. Never record direct identities
in app identifiers, screenshots, object keys or defect reports.

## Device matrix

Record model, OS/build, app version/build, installation UUID, protocol UUID/version,
requested rate, available sensors and observed rate for each row. A blank row is
**not tested**, not passed.

| Platform/family | Device | OS/build | Result/evidence |
| --- | --- | --- | --- |
| Android manufacturer A | pending | pending | NOT TESTED |
| Android manufacturer B | pending | pending | NOT TESTED |
| iPhone generation A | pending | pending | NOT TESTED |
| iPhone generation B | pending | pending | NOT TESTED |

Use at least two Android manufacturer families and two iPhone generations where
available. Document any missing device coverage as a release limitation.

## Execute on every device

1. Install the release candidate, enroll by code and camera QR, then relaunch.
   Participant UUID must match the admin record; installation UUID stays stable.
   Enroll that same participant on a second phone: participant UUID stays the same,
   installation UUID differs. Reinstall only a disposable test installation and
   confirm a new device UUID; never uninstall the only copy of research data.
2. Cache a published protocol, disable all connectivity and finish a session.
   Check instructions, hand choice, practice/genuine/impostor labels, countdown,
   manual/timed stop, Saved confirmation, next trial and return to study.
3. Tap start/stop repeatedly. Exactly one file manifest and one progression step
   may result. Cancel/background during countdown; no saved trial may appear.
4. Record each available sensor. Compare raw native timestamps, units, quaternion
   order and rate against a trusted native diagnostic/reference device where
   available. Missing sensors must be reported, not represented by fabricated data.
5. Switch apps, lock/unlock, accept/decline an incoming call, trigger a system
   permission interruption and return. Active attempts must be invalidated and
   repeated; closed/safely saved trials must remain intact. No claim of background
   acquisition is made. Confirm the screen stays awake during active recording.
6. Exercise 1 Hz, usual study rate and 200 Hz, long/manual trials and timed trials.
   Inspect counts, rates, jitter and estimated gaps. Run a 600-second timed task:
   it must close before the 601-second native watchdog. A manual task left running
   must fail at the watchdog; delays beyond the one-second stop margin must not
   produce a false Saved confirmation.
   Raw per-sensor monotonic timestamps must strictly increase.
   A native timeout or sensor/write failure must leave the Recording screen on
   the next health check (normally within one second). An unresponsive status
   request must leave Recording after its five-second deadline. Late replies must
   not interrupt a retried attempt or change a Saved confirmation.
7. Force-terminate after Saved, during upload and after R2 PUT before finalization.
   Relaunch. Verify same pinned trial UUIDs, no duplicate task slots, pending upload
   recovery after the 15-minute lease, and byte-identical files.
8. Drop the network during/after recording, PUT and finalize; expire a signed URL;
   make R2/Supabase unavailable. Local recording/save stays usable. Restore access
   and wait for bounded retry (up to one hour). An existing matching object can be
   finalized; a conflicting object must never be overwritten or marked synced.
9. Fill storage in a disposable test installation. Exercise native file writing,
   file closure, gzip and SQLite commit failures. Saved must never appear after a
   failed commit, and existing saved files must not change. Restore storage and
   repeat the failed task; partial/orphan attempts remain available for investigation.
   In a test harness, remove a complete CSV row after native closure; the closure
   count mismatch must prevent compression, Saved, progress and upload queueing.
10. Publish a changed protocol during an active session. Refresh on the phone.
    The current session keeps its original version/task order even if its definition
    was removed in the new version. A new session uses the current cached version.
11. Enroll a different participant on the same installation. Pending uploads must
    retain the original participant's grant and metadata. No previous code remains
    in the entry field. Sign out of the console and verify study screens disappear.
12. Export metadata and verified raw files. Preserve the UUID directory hierarchy.
    Run `scripts/verify_dataset.py`; investigate any mismatch before collecting more
    data. Compare dashboard counts to the independent export and every phone.

## Pilot sequence and decision

- Prepare production-like staging Supabase/R2, reviewed protocol, approved researcher
  accounts and signed builds. Complete the matrix above before inviting participants.
- Collect one supervised participant first on two phones; inspect every file, then
  proceed to 5–10 participants including offline sessions and expected device roles.
- After each participant, compare planned/local/remote counts, per-sensor quality,
  actual hand/posture and pinned versions. Retain the app/build and protocol snapshots.
- Record battery, temperature, storage growth, task completion time and any confusing
  instructions. Never infer data correctness solely from a green UI indicator.
- Stop the pilot for data loss, false Saved/synced, identity mix-ups, unauthorized
  access or unrecoverable queue errors. Preserve files; do not clear app storage.
- A named researcher signs off on sensor quality, a maintainer on integrity/security,
  and the deployment owner on backup/recovery and signing. Record evidence and dates
  in the release checklist. Unexecuted tests remain open.

# Researcher progress

Open a study's Progress tab to inspect participant sessions, verified trial counts,
protocol versions, file status, device capabilities and per-trial quality warnings.
Refresh requests a consistent database snapshot under the researcher's RLS policy.
Owners, editors and viewers can inspect study data; outsiders cannot retrieve it.

Counts describe records received by the server. A fully offline session or a file
whose first authorization request failed has no server record yet. An incomplete
session may therefore be awaiting synchronization. A failed R2 verification records
`failed`; connection loss can leave `uploading` until the phone retries. A later
failure cannot downgrade an already verified file.

Warnings are review aids, not automatic exclusion rules: fewer than two samples,
an absent sensor, estimated gaps, a mean rate below 80% of the pinned requested
rate, and native/finalizer warnings are displayed. Unavailable hardware is expected
on some phones. Researchers must interpret it against their study requirements.

Codes and QR credentials are shown only during participant creation in the
Participants tab. They cannot be retrieved from the hashed server records.

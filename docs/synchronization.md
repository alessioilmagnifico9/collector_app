# Synchronization

The normal mobile bootstrap starts a durable queue worker when public server
configuration is present. Startup, foreground return, successful local save and a
30-second timer request work. New transfers pause during countdown, recording,
saving and OS suspension. An in-flight transfer may finish while recording begins;
recording never awaits the network. No OS background execution guarantee is made.

Each attempt verifies local compressed bytes, obtains a fresh signed authorization,
streams the gzip file directly to R2 and asks the server to hash the stored object.
Only a matching verified manifest marks the local queue synced. Conditional PUT
HTTP 412 means an object already exists: server verification must still succeed.
Expired URLs and lost responses retry the same immutable trial/file identities.
HTTP operations carry cancellation signals and a three-minute total deadline each;
a timeout aborts the underlying request instead of leaving orphan network activity.

Retries use persisted exponential delays from 10 seconds to one hour. Upload leases
expire after 15 minutes; attempt counters reject stale completions. Process death
leaves the local files and pending job intact. Foreground restart resumes eligible
jobs, including expired leases. Shutdown waits for the bounded in-flight operation
before closing SQLite. Tokens, signed URLs and raw errors are never logged or saved
as queue errors. Grant expiry requires re-enrollment by the researcher; raw data
remains on the phone and retries resume once that participant's grant is renewed.

No local raw or compressed file is deleted by synchronization, even after success.
Live R2 signature acceptance and realistic file transfer performance must be checked
with the deployment's bucket and physical phones before a pilot.

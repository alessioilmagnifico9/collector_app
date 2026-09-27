# Database authorization checks

Run `npm ci --prefix scripts/backend` followed by `npm --prefix scripts/backend test`.
The pinned PGlite development dependency executes the real PostgreSQL migrations
from an empty database and tests RLS with `SET ROLE` and separate researcher UUIDs.
The harness provides a minimal `auth.users` / `auth.uid()` contract, because Supabase
Auth itself is external. It is not a substitute for testing JWT validation through
Supabase's HTTP API. Tests exercise anonymous denial, owner/editor/viewer study
boundaries, cross-study reads, published-version immutability, active-version
ownership and device visibility. Failures propagate a nonzero exit status.

Before deployment, replay migrations with the Supabase CLI in a disposable local
project (`supabase db reset`), then repeat permission checks via the Data API using
three real test accounts: an owner, a viewer and a nonmember. A nonmember's selects
must return no study data; forbidden inserts must fail. Anonymous requests have no
table access. Inspect every public table for `relrowsecurity = true`. Never test a
researcher policy using the service role, which intentionally bypasses RLS.

Finalization regression tests inspect `pg_locks` at the file-mutation boundary
and verify a future phone start time cannot roll back a verified upload. PGlite
has only one backend; it does not establish real concurrent execution. In disposable
staging, prepare a two-trial session, then finalize its files from two independent
connections. Keep the first transaction open before commit; the second must block
on the session lock, then count both synced files and mark completion. Retry both
and verify IDs/timestamps remain unchanged. Also race upload preparation against
finalization to check the session-before-file lock order. Use test data and the
server role for these service-only RPCs; test user-facing authorization separately.

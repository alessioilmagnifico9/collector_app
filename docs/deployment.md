# Deployment

Local development uses placeholders and fakes. Copy `.env.example` to `.env`;
copy `supabase/functions/.env.example` to `supabase/functions/.env`. Both real files
are ignored. Blank values must never be substituted with invented credentials.

Client deployment will require SUPABASE_URL, SUPABASE_ANON_KEY and
SUPABASE_EDGE_FUNCTIONS_URL. Server deployment separately requires SUPABASE_URL,
SUPABASE_SERVICE_ROLE_KEY, R2_ACCOUNT_ID, R2_BUCKET_NAME, R2_ACCESS_KEY_ID,
R2_SECRET_ACCESS_KEY and R2_ENDPOINT. Do not pass server environment files to Flutter.

Android/iOS release signing and live infrastructure verification are manual release
gates. Follow [the release checklist](release-checklist.md) for required evidence.

## Researcher authentication and database

Apply version-controlled files under `supabase/migrations` in filename order to a
new Supabase project. The schema relies on Supabase's `auth.users`, `auth.uid()` and
`anon`/`authenticated`/`service_role` roles. Do not expose the `private` schema in the
Data API. Disable public researcher sign-ups and provision approved researchers
through Supabase Auth. Participants do not get Auth accounts.

The admin client uses Supabase Auth email/password and automatic SDK token refresh.
Its saved session uses the SDK's platform storage; use a trusted browser profile,
sign out on shared machines and deploy the console over HTTPS. Configure public
client values with `--dart-define-from-file=/path/to/client-config.json`, containing
only the five root `.env.example` keys; Flutter does not parse dotenv files here.
Do not pass the server environment file. Empty/invalid configuration disables login.

A signed-in researcher creates a study through `create_study`, which creates its
owner membership atomically. Additional members must currently be provisioned by
a trusted operator into `study_members` with `owner`, `editor`, or `viewer` role.
The RLS policies independently enforce those roles. See `supabase/tests/README.md`
for local and deployment authorization checks.

Official SDK/security references:
- [Flutter password sign-in](https://supabase.com/docs/reference/dart/auth-signinwithpassword)
- [Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)

## Enrollment Edge Function

Deploy `supabase/functions/collector` with the supplied `supabase/config.toml`.
Gateway JWT verification is disabled only for this endpoint so unauthenticated
participant enrollment can reach its handler. Researcher operations validate the
bearer JWT against Supabase Auth; participant operations validate a hashed,
device-scoped grant. Never add a privileged action without one of those checks.
Only server environment variables configure the service client.

From the repository root, authenticate the Supabase CLI with an account that can
deploy to the target project, then deploy the existing function:

```sh
supabase login
supabase functions deploy collector --project-ref cunlkbbhwnwwknwemafw --no-verify-jwt
```

Use your own project reference if deploying elsewhere. Supabase supplies
`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` to deployed functions; configure
the R2 secrets separately before testing uploads or raw downloads. Apply the
database migrations before testing participant creation/enrollment.

To diagnose browser CORS failures, check the preflight response directly:

```sh
curl -i -X OPTIONS 'https://cunlkbbhwnwwknwemafw.supabase.co/functions/v1/collector' \
  -H 'Origin: https://dataapp-inky.vercel.app' \
  -H 'Access-Control-Request-Method: POST' \
  -H 'Access-Control-Request-Headers: authorization,apikey,content-type'
```

Expect HTTP 204 with `access-control-allow-origin: *` and POST/OPTIONS allowed.
A 404 `NOT_FOUND` response means the function is absent from the target project;
deploy it or correct the client's project/function URL. Changing frontend CORS
settings does not fix a missing function. A successful preflight only confirms
routing/CORS; authenticated operations and database/R2 access need separate tests.
See [Supabase CORS documentation](https://supabase.com/docs/guides/functions/cors).

Create a participant from the study's Participants page after publishing a protocol.
The generated 10-character random code and 256-bit QR token are shown once, never
persisted in plaintext on the server. The database stores only SHA-256 digests.
Participant codes are credentials: deliver privately and do not place them in logs,
URLs to third-party services, exports or object paths. Rotate/revoke through a trusted
operator until the credential-management UI is added. Setting
`enrollment_credentials.revoked_at` revokes enrollment and every device grant for
that participant. Individual grants can be revoked independently; they expire after
180 days. Re-enrollment issues a new grant without changing the participant UUID.

The public enrollment route enforces an atomic global limit of 300 attempts/minute
and 20/minute per hash-prefix bucket (256 bounded buckets), even when an attacker
changes device identifiers or forwarded-IP headers. Also apply infrastructure/WAF
IP limits to reduce denial-of-service against the shared quota. Tune limits for the
pilot; never rely on an in-process counter or a caller-supplied IP for security.
There are no real credentials or participant records in the seed.

## R2 authorization and verification

Create a private R2 bucket and a bucket-scoped read/write API token, then set the
server-only R2 values in `supabase/functions/.env`. The adapter validates the HTTPS
R2 endpoint and constructs UUID object paths from authorized database records.
PUT URLs last 10 minutes and sign content type, size and `If-None-Match: *`; the
client must send those exact headers. This prevents a retry URL from replacing an
already stored object. A 412 response means an object exists; finalize still must
verify its contents. An existing object with the wrong checksum is an integrity
conflict requiring researcher/operator investigation, never an automatic overwrite.

Finalization streams the R2 object back through the Edge Function and computes
SHA-256 and size before committing synced metadata. Client metadata headers alone
are not integrity evidence. This uses bounded memory; large-trial verification
must be load-tested against Edge Function CPU/wall-time limits. The single-trial
limit is 512 MiB; protocols allow 600 seconds and native acquisition uses a
601-second watchdog, including one second for stop delivery.
Failed verification leaves local files intact and remote metadata unsynced.

Live pre-pilot tests must verify expiration, modified signed headers, conditional
PUT replay, corrupted objects, network interruption and actual R2 byte hashes.
See [R2 presigned URLs](https://developers.cloudflare.com/r2/api/s3/presigned-urls/)
and [S3 compatibility](https://developers.cloudflare.com/r2/api/s3/api/).

## Export and release preparation

Apply every migration, including dashboard, export, trial integrity and
`202609250004_finalize_serialization.sql`, as well as the initial four migrations.
The Progress/Export tabs use a security-invoker snapshot RPC;
verified raw downloads use researcher Auth plus a membership-checked server RPC.
No R2 credentials are exposed to the console. Downloads use short-lived GET URLs.
See `docs/export.md` for reproducibility and the independent verifier.

Complete `docs/release-checklist.md` and `docs/hardware-pilot.md` before distribution.
This workspace does not supply production credentials, app signing identities,
Android SDK/Xcode or physical test devices. The source and fakes remain usable
without those inputs; production readiness is conditional on the listed evidence.

Participant code recovery requires migration `202609260001_recoverable_enrollment.sql`
and redeployment of the `collector` Edge Function, followed by the admin web build.
Use **Show code / QR** in the participant list after refreshing. Owners and editors
can retrieve codes; viewers cannot. Codes are stored only in the service-role-only
enrollment table, excluded from dashboard/export data. QR tokens remain hashed.
For older hash-only records, first retrieval replaces the typed code; the original
QR and existing device grants remain valid, and the participant UUID is unchanged.

## Readable dataset names rollout

Apply `202609270001_participant_numbers.sql` before the updated admin build.
It takes an exclusive participant-table lock during deterministic backfill;
schedule migration time appropriate to study size. It never rewrites trial/R2
keys or enrollment credentials. Existing inserts omit the number and continue
working through the allocation trigger. Existing clients can ignore the additive
field; updated clients also accept legacy snapshots without it. No collector
API change is required for this feature.

The admin now fetches signed R2 GET bytes to build ZIP parts. Configure bucket
CORS to permit GET from the exact admin origins while keeping the bucket private.
No additional secrets are needed. See `docs/export.md` for bounded browser parts,
the streaming tool, partial reports, privacy-preserving paths and staging checks.

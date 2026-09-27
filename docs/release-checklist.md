# Release and deployment gates

Current status: host implementation and tests are available; native hardware and
live infrastructure gates below are NOT executed on this Linux workspace.

## Build inputs

- Flutter 3.47.5 / Dart 3.13.4 and committed Pub lockfile.
- Android SDK/Java compatible with the checked-in Flutter Gradle template.
- macOS/Xcode for iOS, the Runner workspace and CocoaPods/plugin dependencies.
- Approved package/bundle identifiers, Android upload keystore, Apple team and
  provisioning profiles. Never commit these credentials or reuse debug signing.
- Public JSON configuration containing APP_ENV=production, ENABLE_DEBUG_TOOLS=false,
  SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_EDGE_FUNCTIONS_URL. Use the public project
  key only. Root dotenv files are examples, not automatically loaded runtime inputs.

## Release build commands

From the respective application directory, with Flutter on PATH:

```sh
# Admin: deploy build/web on a trusted HTTPS host.
flutter build web --release --dart-define-from-file=/private/client-config.json
# Mobile: do not enable COLLECTOR_DEMO and do not choose lib/diagnostics.dart.
flutter build appbundle --release --dart-define-from-file=/private/client-config.json
# On macOS, select signing/provisioning in Runner.xcworkspace first.
flutter build ipa --release --dart-define-from-file=/private/client-config.json
```

The Android release build currently has no signing configuration. Configure
`apps/mobile/android/app/build.gradle.kts` with the organization's upload keystore
using a private local properties file or CI secrets; reference a release signing
configuration from the release build type. Put the properties outside the repository
or use the ignored `key.properties` filename. Verify the resulting bundle's signature
and application ID before uploading to the distribution account. An unsigned bundle
is not release approval. Configure signing in Xcode for the approved Apple team;
confirm the bundle ID, provisioning profile, entitlements and distribution channel.
No account-specific values can be supplied by this workspace.

## Permissions and native tests

Android declares INTERNET for enrollment/sync and CAMERA for optional QR scanning.
Camera hardware is optional; code entry remains available. No external storage or
location permission is used. Recording uses private native sensor acquisition at
1–200 Hz; do not increase the protocol limit without reviewing platform constraints.
Android backup is disabled and native files use no-backup storage.

iOS declares NSCameraUsageDescription and NSMotionUsageDescription with research
purpose text. Test denial/retry and unavailable sensors. Application-support data
is excluded from backup. No background acquisition entitlement is requested;
interruptions invalidate active attempts as described in ADR 003.

Run an Android framework build/lint on a configured SDK. On macOS, build for the
simulator, then execute RunnerTests through the Runner Xcode scheme. Those checks
must run in addition to the standalone Kotlin writer tests and SwiftFormat parsing.
Execute the device matrix in `hardware-pilot.md` on physical devices.

## Deployment owner sign-off

- [ ] Review study protocol/instructions and publish the intended immutable version.
- [ ] Apply all migrations to disposable staging first; then provision the intended
  Supabase project using the documented deployment process.
- [ ] Supply real server secrets securely; deploy collector with JWT gateway checks
  disabled only for this explicitly authorized handler (`supabase/config.toml`).
- [ ] Disable public researcher sign-up; provision owner/viewer/nonmember test users.
- [ ] Verify actual Auth tokens, cross-study RLS, anonymous denial, grant revocation,
  immutable versions and researcher-only raw downloads via HTTP.
- [ ] Configure a private R2 bucket, narrowly scoped server token and retention/backup
  policy. Verify signed header enforcement, expiry, conditional writes and hashes.
- [ ] Confirm Edge runtime performance for the largest expected trial and export.
- [ ] Deploy admin HTTPS host and configure Auth redirect/site URL where applicable.
- [ ] Run all host checks and inspect release artifacts for embedded private secrets.
- [ ] Scan Git history in the real source checkout; this workspace has no history.
- [ ] Validate signing, permissions and four-device matrix; complete supervised pilot.
- [ ] Independently verify exported metadata/raw files and approve quality thresholds.
- [ ] Record build hashes, source revision, migration list, protocol versions,
  deployment identifiers, results, approvers and date. Never record private keys.

Do not uninstall research phones or delete their local files as a deployment step.
For rollback, retain the prior signed app and immutable protocol versions; publish
a new corrected version, preserving already-started sessions. Database changes need
an explicit forward migration or a reviewed backup restore, never ad-hoc deletion.

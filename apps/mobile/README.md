# Participant collector

Flutter Android/iOS client with native Kotlin/Swift sensor acquisition, local
Drift/SQLite progress, gzip/checksum finalization and durable background queue work
while the process is scheduled. Recording is a foreground, offline-capable operation.

Run `flutter run` on a physical device with public client configuration passed via
`--dart-define-from-file=/private/client-config.json`. The explicit
`--dart-define=COLLECTOR_DEMO=true` flow uses memory-only fake data and code DEMO2026.
Never enable that flag for research collection.

See [root setup](../../README.md), [native recording](../../docs/native-recording.md),
[local persistence](../../docs/local-persistence.md),
[synchronization](../../docs/synchronization.md) and [release gates](../../docs/release-checklist.md).

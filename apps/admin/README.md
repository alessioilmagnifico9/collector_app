# Researcher console

Flutter Web application for approved researcher Auth, studies, participant enrollment,
protocol draft/publish workflows, progress/quality inspection and dataset export.

Run `flutter run -d web-server` from this directory. Live configuration uses
`--dart-define-from-file=/private/client-config.json` with public values only.
Build with `flutter build web --release` plus that same configuration flag.

See the [root setup](../../README.md), [deployment](../../docs/deployment.md),
[dashboard](../../docs/dashboard.md) and [export](../../docs/export.md). Authorization
is enforced by RLS/Edge Functions independently of visible controls.

# Build an Android testing APK

The ignored root `.env.client.json` contains only the five public client settings
from `.env.example`. Keep it synchronized with public configuration; Flutter
reads JSON at build time and does not load `.env` automatically. Never add server
secrets to this file.

From the repository root:

```sh
cd apps/mobile
flutter build apk --debug --dart-define-from-file=../../.env.client.json
```

Add `--no-pub` if dependencies have already been resolved locally. Output:
`apps/mobile/build/app/outputs/flutter-apk/app-debug.apk` relative to the repository
root. Copy it to a physical Android phone, open it, and allow installation from
the app used to open the file. Alternatively, authorize the phone for USB debugging:

```sh
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

This APK uses debug signing and is for testing. Production distribution requires
[release signing and checks](release-checklist.md). Do not uninstall an existing
research installation to resolve errors: this can destroy its local recordings.

Real enrollment requires migrations, the deployed `collector` Edge Function,
a study, a published protocol and a participant code. Uploads additionally need
server-side R2 credentials. Follow [deployment.md](deployment.md). Do not enable
COLLECTOR_DEMO for research collection.

# Native recording contract

Flutter channel `collector/sensors` supports `capabilities`, `start`, `stop`,
`abort`, and `status`. Arguments use UUID `trial_id` and
`requested_hz` (1–200). A successful stop returns matching trial ID, `raw_path`,
and `sample_count`. No sample event stream crosses Flutter or SQLite.

Both `start` and `status` confirm `status: recording` and the active `trial_id`.
During acquisition Flutter checks status once per second, with only one request
in flight and a five-second response deadline. A failed, idle, mismatched or
unresponsive native attempt leaves the recording screen and asks the participant
to repeat the same trial. Checks stop before file closure, interruption or disposal;
late replies from a previous attempt cannot invalidate a save or a new attempt.

Protocol-controlled automatic stops allow at most 600 seconds. Both native
watchdogs use 601 seconds, leaving one bounded second for delivery of the stop
command. The finalizer rejects a sample span beyond 601 seconds. A delayed or
unresponsive app still fails the attempt rather than reporting a partial save.

Android uses SensorManager callbacks on a HandlerThread. Sample timestamps come
from SensorEvent.timestamp; writes batch at most 128 samples. A successful native
stop means callbacks were unregistered, the file flushed/fsynced, and `.partial`
renamed to `.csv`. The later Dart pipeline must still validate, compress, checksum
and commit metadata before the UI confirms Saved. Files are in no-backup private
storage. Empty streams and I/O failures cannot produce a successful stop result.

References: [SensorEvent](https://developer.android.com/reference/android/hardware/SensorEvent),
[SensorManager](https://developer.android.com/reference/android/hardware/SensorManager),
[Core Motion](https://developer.apple.com/documentation/coremotion/cmmotionmanager).

Native writer checks: `./scripts/check_android_writer.sh` with Kotlin 2.2.20 and a
JDK. Set KOTLIN_COMPILER if the compiler is outside `.tooling/kotlinc`. Full Android
compilation, SensorManager behaviour, sampling and interruption tests additionally
require Android SDK/devices. Writer tests are not substitutes for those checks.

iOS uses Core Motion callbacks and a serial native writer, with callback-generation
tokens to prevent cross-trial writes. Sensor timestamps are Core Motion seconds
converted to integer nanoseconds; source Double precision remains the physical
limit. Acceleration/gravity multiply native g units by 9.80665. Sensor vendor/range
and resolution remain null because Core Motion does not expose them. Files live
under application support excluded from backup. NSMotionUsageDescription explains
participant-triggered collection. No background motion service is claimed.

On macOS run SwiftFormat and `flutter build ios --simulator`, then execute the
RunnerTests Xcode scheme on a simulator. Sensor availability and timing must be
tested on physical iPhones. SwiftFormat on Linux only checks formatting/parsing;
it does not type-check Core Motion/UIKit APIs.

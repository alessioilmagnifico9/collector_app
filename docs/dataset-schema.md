# Dataset schema

Schema version: 1. Participant, physical device, session, trial and task identifiers
are distinct UUIDs. Participant records never require direct identifiers.

Normalized UTF-8 CSV header:

```text
timestamp_monotonic_ns,sensor_type,x,y,z,w,accuracy
```

Timestamp values preserve native monotonic time; they are not wall-clock time.
Quaternion `w` and sensor accuracy can be absent. Raw samples are never PostgreSQL rows.

## Metadata contracts

`packages/experiment_models` supplies immutable records and snake_case JSON codecs:

| Record | Required research metadata |
|---|---|
| Study | UUID, study label, creation time |
| Participant | UUID, study UUID, sex, dominant hand, creation time |
| PhysicalDevice | installation UUID, model, manufacturer, OS/version, app version, sensor list |
| Protocol / ProtocolVersion | study/protocol UUIDs, version UUID/number, schema, draft/published status, document, timestamps |
| Session | UUID, study/participant UUIDs, pinned protocol version UUID, session definition UUID, start/completion |
| Trial | UUID, study/participant/session/task/device UUIDs, prompt, repetition, actual hand, posture, task type, device role, app/protocol/schema versions, quality |
| TrialFile | UUID, trial UUID, UUID object key, compressed size, SHA-256, content type, sync status, timestamps |

UUIDs are canonical lowercase strings; generated identifiers are random UUID v4.
Times in metadata are UTC ISO-8601; raw sample times are monotonic and cannot be
compared between boots or phones. In JSON, raw nanoseconds are **decimal strings**
to preserve precision in browser consumers. CSV uses exact decimal integer text.

Sex: `female`, `male`, `intersex`, `not_reported`. Dominant hand supports `left`,
`right`, `either`; actual trial hand must be `left` or `right`. Protocol hand rules
add `dominant` and `non_dominant`. Posture: `seated`, `standing`, `supine`,
`unspecified`. Task type: `practice`, `genuine`, `impostor`. Device role: `personal`,
`phone_a`, `phone_b`. These values describe research conditions, not identities.

Sensor names: `accelerometer`, `gyroscope`, `gravity`, `rotation`, `magnetometer`.
Acceleration and gravity use m/s²; angular velocity rad/s; magnetic field µT;
rotation is a quaternion in x,y,z,w order. Coordinate frames retain native device
axes; platform/OS metadata must accompany interpretation. Accuracy is -1 (unknown)
or 0–3 (unreliable/low/medium/high), or empty when unavailable.

Sensor metadata holds requested and observed Hz, name/vendor, resolution/range
where available. Missing metadata is null, never an invented hardware value.
Quality summaries contain duration, sample count, mean/standard-deviation rate,
interval mean/standard deviation/min/max and estimated missing samples by sensor.
Undefined metrics (for example a rate from one sample) are null.

Files use `application/gzip` and SHA-256 of compressed bytes, with keys
`study/<study_uuid>/<participant_uuid>/<session_uuid>/<trial_uuid>/sensors.csv.gz`.
Only `synced` files have an uploaded timestamp. Schema version 1 is required;
unsupported versions fail explicitly. Constructors reject invalid UUIDs, nonfinite
metrics, invalid repetitions, malformed checksums and unsafe object paths.

## Quality calculations and interrupted files

For n>1 samples of a sensor, observed mean Hz is `(n-1)/(last-first)` in seconds.
Rate standard deviation is the population standard deviation of instantaneous
`1e9/delta_ns`. Inter-sample mean/stddev/min/max use strictly positive timestamp
differences. Estimated missing samples sum `max(0, round(delta*requested_hz/1e9)-1)`;
this is an estimate against the requested rate, not proof of hardware drops.
Without a requested rate, the estimate is null. Metrics use streaming Welford
accumulators. Trial duration spans the earliest to latest sample across sensors.

Warnings flag insufficient samples, observed rates below 80% of requested rate,
interval variation above 25% of mean interval, and nonunit quaternions. Missing
expected sensors have count zero and undefined rates. Warnings do not fabricate
samples or reject otherwise valid raw observations.

`.partial` files, missing final newlines, invalid headers, nonfinite values and
nonincreasing per-sensor timestamps cannot enter the normal upload pipeline.
Retain interrupted attempts for researcher review; repeat the planned trial with a
new attempt filename. Never silently trim rows or promote partial files to Saved.

Participant `display_number` is a centrally allocated positive 32-bit integer,
unique and immutable within its study. It is an additive metadata field, not a
primary key or enrollment credential. Legacy serializers accept its absence.
The shared label pads it to at least six digits (`Participant 000123`). The SQL
migration backfills ties by UUID after creation time and serializes new allocations.
Readable export copies and their manifest version 1 are documented in `export.md`;
raw dataset schema version 1 and canonical UUID R2 keys are unchanged.

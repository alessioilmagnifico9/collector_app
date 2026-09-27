# Architecture

`apps/mobile` is the participant client; `apps/admin` is the researcher Flutter web
client. Both consume typed `experiment_models`, `protocol_engine`, and
`dataset_schema` packages. Domain logic has no widget dependency.

Acquisition writes native monotonic samples to private local files. File closure,
quality calculation, compression, checksum, and SQLite commit precede any saved
confirmation or upload. Network availability never gates recording.

Supabase holds pseudonymous metadata and immutable protocol versions. R2 holds raw
files under UUID paths. Privileged credentials belong exclusively to server functions.

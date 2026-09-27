# Protocol format

The protocol is versioned data: ordered session definitions containing ordered task
definitions. Tasks specify prompts, repetitions, posture, hand, device role and type.
Sessions pin an exact published version; subsequent publications cannot change them.

`protocols/protocol.schema.json` describes the JSON shape. The Dart validator also
checks nonblank text, unique session/task IDs and a maximum of 10,000 trials per
session. Validation errors include array locations, such as
`sessions[0]: tasks[0]: repetitions must be 1–1000`.

The document contains `schema_version: 1`, `requested_hz` (1–200), `sessions`, and
optional descriptive `order_metadata`. Each session has a UUID `id`, `title`,
optional `instructions` and an ordered `tasks` array. Array position determines
execution order; descriptive ordering metadata does not silently randomize tasks.

Tasks contain UUID `id`, `prompt`, `repetitions` (1–1000), `posture`, `hand`,
`device_role`, `task_type`, optional `preparation`, `practice_repetitions` (0–100),
and optional `duration_seconds` (0.1–600). Absence/null duration means explicit stop.
Practice repetitions run before the task's primary repetitions and have task type
`practice`; both groups number repetitions starting at 1. Actual trial UUIDs remain
distinct. An ambidextrous/either-hand instruction requires an explicit actual hand.

`protocols/example_protocol.json` is a demonstration, not a claimed approved study
protocol: one session, a circle task with practice, and a timed lateral movement.
Researchers must review and publish their actual study protocol before collection.

The version envelope adds UUID `id`, `protocol_id`, positive version number,
schema version, draft/published status and timestamps. Publishing validates and
freezes the document; editing a published version is rejected. Duplication assigns
a new UUID and greater version number, leaving the prior document unchanged.

`PinnedSession` caches the exact published envelope, session record, and generated
trial queue with stable trial UUIDs. Restoration validates queue contents against
the pinned document. A newly active version never changes the cached queue.

## Admin workflow

Open a study, choose Protocols, enter a protocol name and create a draft. Edit
sessions and tasks using forms; add/reorder/duplicate tasks as required. Task IDs
remain stable across versions, while duplicating a task generates a new UUID.
Validate and preview the generated participant queue, save the draft, then publish.
Publishing activates that immutable version for future enrollment/refresh. Select
“New draft from this version” to revise a published version. Concurrent edits are
checked against the document originally opened; reload the version if another
researcher saved first. The database independently validates publication even when
a caller bypasses the Flutter UI.

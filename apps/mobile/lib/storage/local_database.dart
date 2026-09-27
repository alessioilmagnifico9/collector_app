import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:experiment_models/experiment_models.dart' as model;
import 'package:protocol_engine/protocol_engine.dart';
import 'package:dataset_schema/finalization.dart';

part 'local_database.g.dart';

class CachedParticipants extends Table {
  TextColumn get id => text()();
  TextColumn get payload => text()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedProtocols extends Table {
  TextColumn get id => text()();
  TextColumn get payload => text()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class StoredSessions extends Table {
  TextColumn get id => text()();
  TextColumn get participantId => text().references(CachedParticipants, #id)();
  TextColumn get protocolVersionId => text().references(CachedProtocols, #id)();
  TextColumn get snapshot => text()();
  IntColumn get nextIndex => integer().withDefault(const Constant(0))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PhysicalDevices extends Table {
  TextColumn get id => text()();
  TextColumn get payload => text()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class StoredTrials extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(StoredSessions, #id)();
  TextColumn get deviceId => text().references(PhysicalDevices, #id)();
  TextColumn get payload => text()();
  TextColumn get filePayload => text()();
  TextColumn get rawPath => text()();
  TextColumn get compressedPath => text()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SyncQueue extends Table {
  TextColumn get trialId => text().references(StoredTrials, #id)();
  TextColumn get status => text()
      .withDefault(const Constant('local'))
      .check(
        status.isIn(['local', 'queued', 'uploading', 'synced', 'failed']),
      )();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime()();
  DateTimeColumn get leaseExpiresAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {trialId};
}

class SavedEnrollment extends Table {
  IntColumn get slot => integer().check(slot.equals(1))();
  TextColumn get payload => text()();
  TextColumn get deviceToken => text()();
  @override
  Set<Column<Object>> get primaryKey => {slot};
}

class EnrollmentGrants extends Table {
  TextColumn get participantId => text().references(CachedParticipants, #id)();
  TextColumn get deviceToken => text()();
  @override
  Set<Column<Object>> get primaryKey => {participantId};
}

@DriftDatabase(
  tables: [
    CachedParticipants,
    CachedProtocols,
    StoredSessions,
    PhysicalDevices,
    StoredTrials,
    SyncQueue,
    SavedEnrollment,
    EnrollmentGrants,
  ],
)
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase(super.executor);
  factory LocalDatabase.file(File file) =>
      LocalDatabase(NativeDatabase.createInBackground(file));
  @override
  int get schemaVersion => 3;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 1 || from > 2 || to != 3) {
        throw StateError('Unsupported local database migration $from → $to');
      }
      if (from == 1) {
        await m.addColumn(syncQueue, syncQueue.lastError);
      }
      if (from < 3) {
        await m.createTable(savedEnrollment);
        await m.createTable(enrollmentGrants);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA synchronous = FULL');
      await customStatement(
        'CREATE INDEX IF NOT EXISTS sync_due ON sync_queue(status, next_attempt_at)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS trial_session ON stored_trials(session_id)',
      );
    },
  );

  Future<void> cacheParticipant(model.Participant participant) =>
      into(cachedParticipants).insertOnConflictUpdate(
        CachedParticipantsCompanion.insert(
          id: participant.id,
          payload: jsonEncode(participant.toJson()),
        ),
      );
  Future<void> cacheProtocol(model.ProtocolVersion version) async {
    if (version.status != model.ProtocolStatus.published)
      throw StateError('Only published versions can be cached for collection.');
    ProtocolDefinition.fromJson(version.document);
    final payload = jsonEncode(version.toJson());
    await transaction(() async {
      final old = await (select(
        cachedProtocols,
      )..where((t) => t.id.equals(version.id))).getSingleOrNull();
      if (old != null && old.payload != payload)
        throw StateError(
          'Published protocol content changed under the same UUID.',
        );
      await into(cachedProtocols).insert(
        CachedProtocolsCompanion.insert(id: version.id, payload: payload),
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  Future<model.ProtocolVersion?> protocol(String id) async {
    final row = await (select(
      cachedProtocols,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null
        ? null
        : model.ProtocolVersion.fromJson(model.asJson(jsonDecode(row.payload)));
  }

  Future<void> persistSession(PinnedSession pinned) async {
    await cacheProtocol(pinned.version);
    final payload = jsonEncode(pinned.toJson());
    await transaction(() async {
      final participant = await (select(
        cachedParticipants,
      )..where((t) => t.id.equals(pinned.session.participantId))).getSingle();
      if (model.Participant.fromJson(
            model.asJson(jsonDecode(participant.payload)),
          ).studyId !=
          pinned.session.studyId) {
        throw StateError(
          'Session and participant must belong to the same study.',
        );
      }
      final old = await (select(
        storedSessions,
      )..where((t) => t.id.equals(pinned.session.id))).getSingleOrNull();
      if (old != null && old.snapshot != payload)
        throw StateError('A session snapshot is immutable.');
      await into(storedSessions).insert(
        StoredSessionsCompanion.insert(
          id: pinned.session.id,
          participantId: pinned.session.participantId,
          protocolVersionId: pinned.version.id,
          snapshot: payload,
        ),
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  Future<(PinnedSession, int)> loadSession(String id) async {
    final row = await (select(
      storedSessions,
    )..where((t) => t.id.equals(id))).getSingle();
    return (
      PinnedSession.fromJson(model.asJson(jsonDecode(row.snapshot))),
      row.nextIndex,
    );
  }

  Future<(PinnedSession, int)?> latestSession(
    String participantId,
    String definitionId,
    String protocolId,
  ) async {
    final rows = await (select(
      storedSessions,
    )..where((t) => t.participantId.equals(participantId))).get();
    final sessions =
        rows
            .map(
              (row) => (
                PinnedSession.fromJson(model.asJson(jsonDecode(row.snapshot))),
                row.nextIndex,
              ),
            )
            .where(
              (entry) =>
                  entry.$1.session.sessionDefinitionId == definitionId &&
                  entry.$1.version.protocolId == protocolId,
            )
            .toList()
          ..sort(
            (a, b) => b.$1.session.startedAt.compareTo(a.$1.session.startedAt),
          );
    return sessions.isEmpty ? null : sessions.first;
  }

  Future<model.PhysicalDevice> getOrCreateDevice(
    model.PhysicalDevice Function() create,
  ) => transaction(() async {
    final existing = await select(physicalDevices).getSingleOrNull();
    if (existing != null)
      return model.PhysicalDevice.fromJson(
        model.asJson(jsonDecode(existing.payload)),
      );
    final device = create();
    await into(physicalDevices).insert(
      PhysicalDevicesCompanion.insert(
        id: device.id,
        payload: jsonEncode(device.toJson()),
      ),
    );
    return device;
  });

  Future<void> updateDevice(model.PhysicalDevice device) async {
    final changed =
        await (update(
          physicalDevices,
        )..where((t) => t.id.equals(device.id))).write(
          PhysicalDevicesCompanion(payload: Value(jsonEncode(device.toJson()))),
        );
    if (changed != 1)
      throw StateError('Device must be registered before refreshing metadata.');
  }

  Future<void> saveTrial({
    required model.Trial trial,
    required model.TrialFile file,
    required FinalizedFile finalized,
    required String rawPath,
  }) async {
    if (file.trialId != trial.id ||
        file.syncStatus != model.SyncStatus.local ||
        file.sha256 != finalized.sha256 ||
        file.sizeBytes != finalized.sizeBytes ||
        jsonEncode(trial.quality.toJson()) !=
            jsonEncode(finalized.quality.toJson()))
      throw StateError('Trial/file finalization identity mismatch.');
    final compressed = File(finalized.path);
    if (await compressed.length() != file.sizeBytes ||
        await checksumFile(compressed) != file.sha256)
      throw StateError(
        'Compressed file verification failed before local commit.',
      );
    await transaction(() async {
      final old = await (select(
        storedTrials,
      )..where((t) => t.id.equals(trial.id))).getSingleOrNull();
      if (old != null) {
        if (old.payload != jsonEncode(trial.toJson()) ||
            old.filePayload != jsonEncode(file.toJson()) ||
            old.compressedPath != finalized.path ||
            old.rawPath != rawPath)
          throw StateError('Cannot replace a safely saved trial.');
        return;
      }
      final (pinned, index) = await loadSession(trial.sessionId);
      if (index >= pinned.queue.length ||
          pinned.queue[index].id != trial.id ||
          trial.participantId != pinned.session.participantId ||
          trial.studyId != pinned.session.studyId ||
          trial.protocolVersionId != pinned.version.id)
        throw StateError(
          'Trial does not match the next task in the pinned session.',
        );
      final planned = pinned.queue[index];
      final participantRow = await (select(
        cachedParticipants,
      )..where((t) => t.id.equals(trial.participantId))).getSingle();
      final participant = model.Participant.fromJson(
        model.asJson(jsonDecode(participantRow.payload)),
      );
      if (trial.taskId != planned.task.id ||
          trial.handUsed !=
              planned.resolveHand(
                participant.dominantHand,
                selected: trial.handUsed,
              ) ||
          trial.prompt != planned.task.prompt ||
          trial.repetition != planned.repetition ||
          trial.taskType != planned.taskType ||
          trial.posture != planned.task.posture ||
          trial.deviceRole != planned.task.deviceRole)
        throw StateError('Trial metadata differs from the pinned plan.');
      final expectedKey =
          'study/${trial.studyId}/${trial.participantId}/${trial.sessionId}/${trial.id}/sensors.csv.gz';
      if (file.objectKey != expectedKey)
        throw StateError('Trial object hierarchy mismatch.');
      await into(storedTrials).insert(
        StoredTrialsCompanion.insert(
          id: trial.id,
          sessionId: trial.sessionId,
          deviceId: trial.physicalDeviceId,
          payload: jsonEncode(trial.toJson()),
          filePayload: jsonEncode(file.toJson()),
          rawPath: rawPath,
          compressedPath: finalized.path,
        ),
      );
      await into(syncQueue).insert(
        SyncQueueCompanion.insert(
          trialId: trial.id,
          status: const Value('local'),
          nextAttemptAt: DateTime.now().toUtc(),
        ),
      );
      await (update(storedSessions)..where((t) => t.id.equals(trial.sessionId)))
          .write(StoredSessionsCompanion(nextIndex: Value(index + 1)));
    });
  }

  Future<void> recoverPending(DateTime now) async {
    await customStatement(
      "UPDATE sync_queue SET status='queued', lease_expires_at=NULL WHERE status='local' OR (status='uploading' AND (lease_expires_at IS NULL OR lease_expires_at <= ?))",
      [now.millisecondsSinceEpoch ~/ 1000],
    );
  }

  Future<SyncQueueData?> claimUpload(DateTime now) => transaction(() async {
    await recoverPending(now);
    final row =
        await (select(syncQueue)
              ..where(
                (t) =>
                    (t.status.equals('queued') | t.status.equals('failed')) &
                    t.nextAttemptAt.isSmallerOrEqualValue(now),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.nextAttemptAt)])
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return null;
    final lease = now.add(const Duration(minutes: 15));
    await (update(
      syncQueue,
    )..where((t) => t.trialId.equals(row.trialId))).write(
      SyncQueueCompanion(
        status: const Value('uploading'),
        attempts: Value(row.attempts + 1),
        leaseExpiresAt: Value(lease),
        lastError: const Value(null),
      ),
    );
    return (select(
      syncQueue,
    )..where((t) => t.trialId.equals(row.trialId))).getSingle();
  });
  Future<void> finishUpload(
    String id, {
    required int attempt,
    required DateTime now,
    required bool verified,
    String? errorCode,
  }) async {
    await transaction(() async {
      final query = select(syncQueue)..where((t) => t.trialId.equals(id));
      final job = await query.getSingle();
      if (job.status != 'uploading' ||
          job.attempts != attempt ||
          job.leaseExpiresAt == null ||
          !now.isBefore(job.leaseExpiresAt!))
        throw StateError('Upload lease is no longer owned by this attempt.');
      final backoff = Duration(
        seconds: (5 * (1 << (job.attempts > 10 ? 10 : job.attempts))).clamp(
          10,
          3600,
        ),
      );
      await (update(syncQueue)..where((t) => t.trialId.equals(id))).write(
        SyncQueueCompanion(
          status: Value(verified ? 'synced' : 'failed'),
          leaseExpiresAt: const Value(null),
          nextAttemptAt: Value(verified ? now : now.add(backoff)),
          lastError: Value(verified ? null : errorCode ?? 'upload_failed'),
        ),
      );
    });
  }
}

import 'package:protocol_engine/protocol_engine.dart';

import '../collection/services.dart';
import 'local_database.dart';

final class LocalSessionStore implements CollectionSessionStore {
  final LocalDatabase database;
  LocalSessionStore(this.database);

  @override
  Future<List<SessionDefinition>> definitions(Enrollment enrollment) async {
    final result = {
      for (final definition in ProtocolDefinition.fromJson(
        enrollment.version.document,
      ).sessions)
        definition.id: definition,
    };
    final rows =
        await (database.select(database.storedSessions)..where(
              (row) => row.participantId.equals(enrollment.participant.id),
            ))
            .get();
    for (final row in rows) {
      final (pinned, index) = await database.loadSession(row.id);
      if (pinned.version.protocolId != enrollment.protocol.id ||
          index >= pinned.queue.length)
        continue;
      final definition = ProtocolDefinition.fromJson(pinned.version.document)
          .sessions
          .firstWhere((s) => s.id == pinned.session.sessionDefinitionId);
      result[definition.id] = definition;
    }
    return result.values.toList();
  }

  @override
  Future<(PinnedSession, int)> open(
    Enrollment enrollment,
    SessionDefinition definition,
  ) async {
    await database.cacheParticipant(enrollment.participant);
    final previous = await database.latestSession(
      enrollment.participant.id,
      definition.id,
      enrollment.protocol.id,
    );
    if (previous != null) return previous;
    final session = startSession(
      version: enrollment.version,
      protocol: enrollment.protocol,
      participant: enrollment.participant,
      sessionDefinitionId: definition.id,
      now: DateTime.now().toUtc(),
    );
    await database.persistSession(session);
    return (session, 0);
  }
}

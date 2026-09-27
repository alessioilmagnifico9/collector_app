import 'dart:convert';

import 'package:experiment_models/experiment_models.dart';

import 'definition.dart';

ProtocolVersion publishVersion(ProtocolVersion draft, DateTime now) {
  if (draft.status != ProtocolStatus.draft)
    throw StateError('Published versions cannot be republished or edited.');
  final document = ProtocolDefinition.fromJson(draft.document).toJson();
  return ProtocolVersion(
    id: draft.id,
    protocolId: draft.protocolId,
    version: draft.version,
    schemaVersion: draft.schemaVersion,
    status: ProtocolStatus.published,
    document: document,
    createdAt: draft.createdAt,
    publishedAt: now,
  );
}

ProtocolVersion editDraft(ProtocolVersion draft, Json document) {
  if (draft.status != ProtocolStatus.draft)
    throw StateError('Duplicate the published version into a new draft first.');
  return ProtocolVersion(
    id: draft.id,
    protocolId: draft.protocolId,
    version: draft.version,
    schemaVersion: draft.schemaVersion,
    status: ProtocolStatus.draft,
    document: document,
    createdAt: draft.createdAt,
  );
}

ProtocolVersion duplicateVersion(
  ProtocolVersion source, {
  required int nextVersion,
  required DateTime now,
}) {
  if (nextVersion <= source.version)
    throw ArgumentError('nextVersion must increase.');
  return ProtocolVersion(
    id: newUuid(),
    protocolId: source.protocolId,
    version: nextVersion,
    schemaVersion: source.schemaVersion,
    status: ProtocolStatus.draft,
    document: source.document,
    createdAt: now,
  );
}

final class TrialPlan {
  final String id;
  final TaskDefinition task;
  final int repetition;
  final TaskType taskType;
  TrialPlan({
    required this.id,
    required this.task,
    required this.repetition,
    required this.taskType,
  }) {
    requireUuid(id, 'trial_id');
    requirePositive(repetition, 'repetition');
  }
  Json toJson() => {
    'id': id,
    'task': task.toJson(),
    'repetition': repetition,
    'task_type': wireName(taskType),
  };
  factory TrialPlan.fromJson(Json json) => TrialPlan(
    id: stringField(json, 'id'),
    task: TaskDefinition.fromJson(asJson(json['task'])),
    repetition: intField(json, 'repetition'),
    taskType: enumField(json, 'task_type', TaskType.values),
  );
  Hand resolveHand(Hand dominant, {Hand? selected}) {
    final requested = task.hand;
    final result = switch (requested) {
      Hand.left => Hand.left,
      Hand.right => Hand.right,
      Hand.either => selected,
      Hand.dominant => dominant == Hand.either ? selected : dominant,
      Hand.nonDominant =>
        dominant == Hand.left
            ? Hand.right
            : dominant == Hand.right
            ? Hand.left
            : selected,
    };
    if (result != Hand.left && result != Hand.right)
      throw StateError('Choose the hand actually used before recording.');
    return result!;
  }
}

List<TrialPlan> generateTrialQueue(
  SessionDefinition definition, {
  String Function()? createId,
}) {
  final id = createId ?? newUuid;
  return List.unmodifiable([
    for (final task in definition.tasks) ...[
      for (var r = 1; r <= task.practiceRepetitions; r++)
        TrialPlan(
          id: id(),
          task: task,
          repetition: r,
          taskType: TaskType.practice,
        ),
      for (var r = 1; r <= task.repetitions; r++)
        TrialPlan(id: id(), task: task, repetition: r, taskType: task.taskType),
    ],
  ]);
}

final class PinnedSession {
  final Session session;
  final ProtocolVersion version;
  final List<TrialPlan> queue;
  PinnedSession({
    required this.session,
    required this.version,
    required List<TrialPlan> queue,
  }) : queue = List.unmodifiable(queue) {
    if (version.status != ProtocolStatus.published ||
        session.protocolVersionId != version.id)
      throw StateError(
        'Session must pin its exact published protocol version.',
      );
    final definitions = ProtocolDefinition.fromJson(version.document).sessions
        .where((s) => s.id == session.sessionDefinitionId);
    if (definitions.length != 1)
      throw const FormatException(
        'Session definition is absent from pinned version.',
      );
    if (queue.map((t) => t.id).toSet().length != queue.length)
      throw const FormatException('Trial IDs must be unique.');
    final expected = generateTrialQueue(definitions.single);
    if (expected.length != queue.length)
      throw const FormatException(
        'Cached queue length differs from pinned protocol.',
      );
    for (var i = 0; i < queue.length; i++) {
      if (jsonEncode(expected[i].task.toJson()) !=
              jsonEncode(queue[i].task.toJson()) ||
          expected[i].repetition != queue[i].repetition ||
          expected[i].taskType != queue[i].taskType) {
        throw FormatException('Cached trial $i differs from pinned protocol.');
      }
    }
  }
  Json toJson() => {
    'session': session.toJson(),
    'version': version.toJson(),
    'queue': queue.map((t) => t.toJson()).toList(),
  };
  factory PinnedSession.fromJson(Json json) => PinnedSession(
    session: Session.fromJson(asJson(json['session'])),
    version: ProtocolVersion.fromJson(asJson(json['version'])),
    queue: listField(json, 'queue', (v) => TrialPlan.fromJson(asJson(v))),
  );
}

PinnedSession startSession({
  required ProtocolVersion version,
  required Protocol protocol,
  required Participant participant,
  required String sessionDefinitionId,
  required DateTime now,
}) {
  if (protocol.id != version.protocolId ||
      protocol.studyId != participant.studyId)
    throw StateError('Participant and protocol must belong to the same study.');
  if (version.status != ProtocolStatus.published)
    throw StateError('Only a published version can start a session.');
  final definitions = ProtocolDefinition.fromJson(version.document).sessions
      .where((s) => s.id == sessionDefinitionId);
  if (definitions.length != 1)
    throw const FormatException('Unknown session definition.');
  return PinnedSession(
    session: Session(
      id: newUuid(),
      studyId: participant.studyId,
      participantId: participant.id,
      protocolVersionId: version.id,
      sessionDefinitionId: sessionDefinitionId,
      startedAt: now,
    ),
    version: version,
    queue: generateTrialQueue(definitions.single),
  );
}

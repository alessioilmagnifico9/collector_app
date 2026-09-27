import 'package:experiment_models/experiment_models.dart';

import 'protocol_engine.dart';

/// Snapshot-scoped research labels. Never consult a protocol's active version.
final class DatasetNames {
  final List<Participant> participants;
  final List<Session> sessions;
  final List<Trial> trials;
  final List<ProtocolVersion> versions;
  final List<PhysicalDevice> devices;
  DatasetNames({
    required this.participants,
    required this.sessions,
    required this.trials,
    required this.versions,
    required this.devices,
  });

  late final _participants = {for (final p in participants) p.id: p};
  late final _sessions = {for (final s in sessions) s.id: s};
  late final _versions = {for (final v in versions) v.id: v};
  final _definitions = <String, ProtocolDefinition>{};
  late final _attempts = _numberAttempts();
  late final _recordings = _numberRecordings();
  late final _deviceLabels = _labelDevices();
  Participant participant(String id) => _participants[id]!;
  Session session(Trial trial) => _sessions[trial.sessionId]!;
  ProtocolVersion version(String id) => _versions[id]!;
  ProtocolDefinition definition(String id) => _definitions.putIfAbsent(
    id,
    () => ProtocolDefinition.fromJson(version(id).document),
  );
  SessionDefinition sessionDefinition(Session session) =>
      definition(session.protocolVersionId).sessions
          .firstWhere((s) => s.id == session.sessionDefinitionId);
  int sessionNumber(Session session) =>
      definition(session.protocolVersionId).sessions
          .indexWhere((s) => s.id == session.sessionDefinitionId) +
      1;
  Map<String, int> _numberAttempts() {
    final ordered = sessions.toList()
      ..sort((a, b) {
        final time = a.startedAt.compareTo(b.startedAt);
        return time == 0 ? a.id.compareTo(b.id) : time;
      });
    final counts = <(String, int), int>{};
    return {
      for (final s in ordered)
        s.id: counts.update(
          (s.participantId, sessionNumber(s)),
          (n) => n + 1,
          ifAbsent: () => 1,
        ),
    };
  }

  int attempt(Session session) => _attempts[session.id]!;

  String sessionLabel(Session session) =>
      '${sessionDefinition(session).title} · Session ${sessionNumber(session)} · attempt ${attempt(session)} · protocol v${version(session.protocolVersionId).version}';
  SessionDefinition trialDefinition(Trial trial) {
    final recorded = session(trial);
    return definition(trial.protocolVersionId).sessions
        .firstWhere((s) => s.id == recorded.sessionDefinitionId);
  }

  int taskNumber(Trial trial) =>
      trialDefinition(trial).tasks.indexWhere((t) => t.id == trial.taskId) + 1;
  String taskLabel(Trial trial) =>
      trialDefinition(trial).tasks
          .firstWhere((t) => t.id == trial.taskId)
          .prompt;
  Map<String, int> _numberRecordings() {
    final ordered = trials.toList()
      ..sort((a, b) {
        final time = a.createdAt.compareTo(b.createdAt);
        return time == 0 ? a.id.compareTo(b.id) : time;
      });
    final counts = <(String, String, TaskType, int), int>{};
    return {
      for (final t in ordered)
        t.id: counts.update(
          (t.sessionId, t.taskId, t.taskType, t.repetition),
          (n) => n + 1,
          ifAbsent: () => 1,
        ),
    };
  }

  int recording(Trial trial) => _recordings[trial.id]!;
  Map<String, String> _labelDevices() {
    final ordered = devices.toList()..sort((a, b) => a.id.compareTo(b.id));
    return {
      for (var i = 0; i < ordered.length; i++)
        ordered[i].id: 'Device ${i + 1} (${ordered[i].model})',
    };
  }

  String deviceLabel(Trial trial) =>
      _deviceLabels[trial.physicalDeviceId] ??
      'Device ${trial.physicalDeviceId}';

  String trialLabel(Trial trial) =>
      '${taskLabel(trial)} · ${trial.taskType.name} · repetition ${trial.repetition} · recording ${recording(trial)} · ${deviceLabel(trial)}';

  /// Paths deliberately exclude all free text (including prompts, which can ask
  /// for initials), enrollment credentials and hardware model strings.
  String exportPath(Trial trial) {
    final person = participant(trial.participantId);
    final participantPath = person.displayNumber == null
        ? 'participant-legacy-${person.id}'
        : 'participant-${digits(person.displayNumber!, 6)}';
    final recorded = session(trial);
    if (taskNumber(trial) < 1 || sessionNumber(recorded) < 1) {
      throw const FormatException('Pinned task or session is missing');
    }
    return 'study-${trial.studyId}/$participantPath/'
        'session-${digits(sessionNumber(recorded), 2)}-attempt-${digits(attempt(recorded), 2)}/'
        'task-${digits(taskNumber(trial), 3)}/'
        '${trial.taskType.name}-repetition-${digits(trial.repetition, 3)}-recording-${trial.id}.csv.gz';
  }
}

String digits(int value, int width) => value.toString().padLeft(width, '0');

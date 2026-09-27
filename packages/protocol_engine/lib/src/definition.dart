import 'package:experiment_models/experiment_models.dart';

T atPath<T>(String path, T Function() parse) {
  try {
    return parse();
  } on FormatException catch (e) {
    throw FormatException('$path: ${e.message}');
  }
}

void knownFields(Json json, Set<String> keys) {
  final extra = json.keys.where((k) => !keys.contains(k));
  if (extra.isNotEmpty)
    throw FormatException('Unknown fields: ${extra.join(', ')}');
}

final class TaskDefinition {
  final String id, prompt;
  final int repetitions, practiceRepetitions;
  final Posture posture;
  final Hand hand;
  final DeviceRole deviceRole;
  final TaskType taskType;
  final String? preparation;
  final double? durationSeconds;
  TaskDefinition({
    required this.id,
    required this.prompt,
    required this.repetitions,
    required this.posture,
    required this.hand,
    required this.deviceRole,
    required this.taskType,
    this.preparation,
    this.practiceRepetitions = 0,
    this.durationSeconds,
  }) {
    requireUuid(id, 'id');
    requireText(prompt, 'prompt');
    if (repetitions < 1 || repetitions > 1000)
      throw const FormatException('repetitions must be 1–1000.');
    if (practiceRepetitions < 0 || practiceRepetitions > 100)
      throw const FormatException('practice_repetitions must be 0–100.');
    if (preparation != null) requireText(preparation!, 'preparation');
    if (durationSeconds != null &&
        (!durationSeconds!.isFinite ||
            durationSeconds! < .1 ||
            durationSeconds! > 600)) {
      throw const FormatException(
        'duration_seconds must be 0.1–600 or absent for manual stop.',
      );
    }
  }
  factory TaskDefinition.fromJson(Json json) {
    knownFields(json, {
      'id',
      'prompt',
      'repetitions',
      'posture',
      'hand',
      'device_role',
      'task_type',
      'preparation',
      'practice_repetitions',
      'duration_seconds',
    });
    return TaskDefinition(
      id: stringField(json, 'id'),
      prompt: stringField(json, 'prompt'),
      repetitions: intField(json, 'repetitions'),
      posture: enumField(json, 'posture', Posture.values),
      hand: enumField(json, 'hand', Hand.values),
      deviceRole: enumField(json, 'device_role', DeviceRole.values),
      taskType: enumField(json, 'task_type', TaskType.values),
      preparation: json['preparation'] == null
          ? null
          : stringField(json, 'preparation'),
      practiceRepetitions: json['practice_repetitions'] == null
          ? 0
          : intField(json, 'practice_repetitions'),
      durationSeconds: json['duration_seconds'] == null
          ? null
          : doubleField(json, 'duration_seconds'),
    );
  }
  Json toJson() => {
    'id': id,
    'prompt': prompt,
    'repetitions': repetitions,
    'posture': wireName(posture),
    'hand': wireName(hand),
    'device_role': wireName(deviceRole),
    'task_type': wireName(taskType),
    'preparation': preparation,
    'practice_repetitions': practiceRepetitions,
    'duration_seconds': durationSeconds,
  };
}

final class SessionDefinition {
  final String id, title;
  final String? instructions;
  final List<TaskDefinition> tasks;
  SessionDefinition({
    required this.id,
    required this.title,
    this.instructions,
    required List<TaskDefinition> tasks,
  }) : tasks = List.unmodifiable(tasks) {
    requireUuid(id, 'id');
    requireText(title, 'title');
    if (instructions != null) requireText(instructions!, 'instructions');
    if (tasks.isEmpty)
      throw const FormatException('tasks must contain at least one task.');
    if (tasks.map((t) => t.id).toSet().length != tasks.length)
      throw const FormatException('Task IDs must be unique within a session.');
    if (tasks.fold<int>(
          0,
          (n, t) => n + t.repetitions + t.practiceRepetitions,
        ) >
        10000)
      throw const FormatException('A session cannot exceed 10000 trials.');
  }
  factory SessionDefinition.fromJson(Json json) {
    knownFields(json, {'id', 'title', 'instructions', 'tasks'});
    var index = 0;
    return SessionDefinition(
      id: stringField(json, 'id'),
      title: stringField(json, 'title'),
      instructions: json['instructions'] == null
          ? null
          : stringField(json, 'instructions'),
      tasks: listField(
        json,
        'tasks',
        (v) => atPath(
          'tasks[${index++}]',
          () => TaskDefinition.fromJson(asJson(v)),
        ),
      ),
    );
  }
  Json toJson() => {
    'id': id,
    'title': title,
    'instructions': instructions,
    'tasks': tasks.map((t) => t.toJson()).toList(),
  };
}

final class ProtocolDefinition {
  final int schemaVersion;
  final double requestedHz;
  final List<SessionDefinition> sessions;
  final Json orderMetadata;
  ProtocolDefinition({
    this.schemaVersion = 1,
    required this.requestedHz,
    required List<SessionDefinition> sessions,
    Json orderMetadata = const {},
  }) : sessions = List.unmodifiable(sessions),
       orderMetadata = asJson(freezeJson(orderMetadata)) {
    if (schemaVersion != 1)
      throw const FormatException('schema_version must be 1.');
    if (!requestedHz.isFinite || requestedHz < 1 || requestedHz > 200)
      throw const FormatException('requested_hz must be 1–200.');
    if (sessions.isEmpty || sessions.length > 100)
      throw const FormatException('sessions must contain 1–100 sessions.');
    if (sessions.map((s) => s.id).toSet().length != sessions.length)
      throw const FormatException('Session definition IDs must be unique.');
  }
  factory ProtocolDefinition.fromJson(Json json) {
    knownFields(json, {
      'schema_version',
      'requested_hz',
      'sessions',
      'order_metadata',
    });
    var index = 0;
    return ProtocolDefinition(
      schemaVersion: intField(json, 'schema_version'),
      requestedHz: doubleField(json, 'requested_hz'),
      sessions: listField(
        json,
        'sessions',
        (v) => atPath(
          'sessions[${index++}]',
          () => SessionDefinition.fromJson(asJson(v)),
        ),
      ),
      orderMetadata: json['order_metadata'] == null
          ? {}
          : asJson(json['order_metadata']),
    );
  }
  Json toJson() => {
    'schema_version': schemaVersion,
    'requested_hz': requestedHz,
    'sessions': sessions.map((s) => s.toJson()).toList(),
    'order_metadata': orderMetadata,
  };
}

List<String> validateProtocol(Json json) {
  try {
    ProtocolDefinition.fromJson(json);
    return const [];
  } on FormatException catch (e) {
    return [e.message.toString()];
  }
}

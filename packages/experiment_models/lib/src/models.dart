import 'validation.dart';

enum Sex { female, male, intersex, notReported }

enum Hand { left, right, either, dominant, nonDominant }

enum Posture { seated, standing, supine, unspecified }

enum TaskType { practice, genuine, impostor }

enum DeviceRole { personal, phoneA, phoneB }

enum SyncStatus { local, queued, uploading, synced, failed }

enum ProtocolStatus { draft, published }

enum SensorType { accelerometer, gyroscope, gravity, rotation, magnetometer }

final class Study {
  final String id;
  final String name;
  final DateTime createdAt;
  Study({required this.id, required this.name, required this.createdAt}) {
    requireUuid(id, 'id');
    requireText(name, 'name');
  }
  factory Study.fromJson(Json json) => Study(
    id: stringField(json, 'id'),
    name: stringField(json, 'name'),
    createdAt: dateField(json, 'created_at'),
  );
  Json toJson() => {
    'id': id,
    'name': name,
    'created_at': createdAt.toUtc().toIso8601String(),
  };
}

final class Participant {
  final String id;
  final String studyId;
  final int? displayNumber;
  String get displayLabel => displayNumber == null
      ? 'Participant (legacy $id)'
      : 'Participant ${displayNumber.toString().padLeft(6, "0")}';
  final Sex sex;
  final Hand dominantHand;
  final DateTime createdAt;
  Participant({
    this.displayNumber,
    required this.id,
    required this.studyId,
    required this.sex,
    required this.dominantHand,
    required this.createdAt,
  }) {
    if (displayNumber != null &&
        (displayNumber! < 1 || displayNumber! > 2147483647)) {
      throw const FormatException('Invalid participant display number.');
    }
    requireUuid(id, 'id');
    requireUuid(studyId, 'study_id');
    if (!{Hand.left, Hand.right, Hand.either}.contains(dominantHand))
      throw const FormatException('Hand must resolve to an actual hand.');
  }
  factory Participant.fromJson(Json json) => Participant(
    displayNumber: json['display_number'] == null
        ? null
        : intField(json, 'display_number'),
    id: stringField(json, 'id'),
    studyId: stringField(json, 'study_id'),
    sex: enumField(json, 'sex', Sex.values),
    dominantHand: enumField(json, 'dominant_hand', Hand.values),
    createdAt: dateField(json, 'created_at'),
  );
  Json toJson() => {
    if (displayNumber != null) 'display_number': displayNumber,
    'id': id,
    'study_id': studyId,
    'sex': wireName(sex),
    'dominant_hand': wireName(dominantHand),
    'created_at': createdAt.toUtc().toIso8601String(),
  };
}

final class SensorMetadata {
  final SensorType sensorType;
  final String name;
  final String? vendor;
  final double requestedHz;
  final double? observedHz;
  final double? resolution;
  final double? maximumRange;
  SensorMetadata({
    required this.sensorType,
    required this.name,
    this.vendor,
    required this.requestedHz,
    this.observedHz,
    this.resolution,
    this.maximumRange,
  }) {
    requireText(name, 'name');
    requirePositive(requestedHz, 'requested_hz', zero: false);
    if (observedHz != null)
      requirePositive(observedHz!, 'observed_hz', zero: true);
    if (resolution != null)
      requirePositive(resolution!, 'resolution', zero: true);
    if (maximumRange != null)
      requirePositive(maximumRange!, 'maximum_range', zero: true);
  }
  factory SensorMetadata.fromJson(Json json) => SensorMetadata(
    sensorType: enumField(json, 'sensor_type', SensorType.values),
    name: stringField(json, 'name'),
    vendor: json['vendor'] == null ? null : stringField(json, 'vendor'),
    requestedHz: doubleField(json, 'requested_hz'),
    observedHz: json['observed_hz'] == null
        ? null
        : doubleField(json, 'observed_hz'),
    resolution: json['resolution'] == null
        ? null
        : doubleField(json, 'resolution'),
    maximumRange: json['maximum_range'] == null
        ? null
        : doubleField(json, 'maximum_range'),
  );
  Json toJson() => {
    'sensor_type': wireName(sensorType),
    'name': name,
    'vendor': vendor,
    'requested_hz': requestedHz,
    'observed_hz': observedHz,
    'resolution': resolution,
    'maximum_range': maximumRange,
  };
}

final class PhysicalDevice {
  final String id;
  final String model;
  final String manufacturer;
  final String os;
  final String osVersion;
  final String appVersion;
  final List<SensorMetadata> sensors;
  final DateTime createdAt;
  PhysicalDevice({
    required this.id,
    required this.model,
    required this.manufacturer,
    required this.os,
    required this.osVersion,
    required this.appVersion,
    required List<SensorMetadata> sensors,
    required this.createdAt,
  }) : sensors = List.unmodifiable(sensors) {
    requireUuid(id, 'id');
    requireText(model, 'model');
    requireText(manufacturer, 'manufacturer');
    requireText(os, 'os');
    requireText(osVersion, 'os_version');
    requireText(appVersion, 'app_version');
  }
  factory PhysicalDevice.fromJson(Json json) => PhysicalDevice(
    id: stringField(json, 'id'),
    model: stringField(json, 'model'),
    manufacturer: stringField(json, 'manufacturer'),
    os: stringField(json, 'os'),
    osVersion: stringField(json, 'os_version'),
    appVersion: stringField(json, 'app_version'),
    sensors: listField(
      json,
      'sensors',
      (v) => SensorMetadata.fromJson(asJson(v)),
    ),
    createdAt: dateField(json, 'created_at'),
  );
  Json toJson() => {
    'id': id,
    'model': model,
    'manufacturer': manufacturer,
    'os': os,
    'os_version': osVersion,
    'app_version': appVersion,
    'sensors': sensors.map((v) => v.toJson()).toList(),
    'created_at': createdAt.toUtc().toIso8601String(),
  };
}

final class Protocol {
  final String id;
  final String studyId;
  final String name;
  final DateTime createdAt;
  Protocol({
    required this.id,
    required this.studyId,
    required this.name,
    required this.createdAt,
  }) {
    requireUuid(id, 'id');
    requireUuid(studyId, 'study_id');
    requireText(name, 'name');
  }
  factory Protocol.fromJson(Json json) => Protocol(
    id: stringField(json, 'id'),
    studyId: stringField(json, 'study_id'),
    name: stringField(json, 'name'),
    createdAt: dateField(json, 'created_at'),
  );
  Json toJson() => {
    'id': id,
    'study_id': studyId,
    'name': name,
    'created_at': createdAt.toUtc().toIso8601String(),
  };
}

final class ProtocolVersion {
  final String id;
  final String protocolId;
  final int version;
  final int schemaVersion;
  final ProtocolStatus status;
  final Json document;
  final DateTime createdAt;
  final DateTime? publishedAt;
  ProtocolVersion({
    required this.id,
    required this.protocolId,
    required this.version,
    required this.schemaVersion,
    required this.status,
    required Json document,
    required this.createdAt,
    this.publishedAt,
  }) : document = asJson(freezeJson(document)) {
    requireUuid(id, 'id');
    requireUuid(protocolId, 'protocol_id');
    requirePositive(version, 'version', zero: false);
    requirePositive(schemaVersion, 'schema_version', zero: false);
    if (schemaVersion != 1)
      throw const FormatException('Unsupported schema_version. Expected 1.');
    if ((status == ProtocolStatus.published) != (publishedAt != null))
      throw const FormatException(
        'Published status and published_at must agree.',
      );
  }
  factory ProtocolVersion.fromJson(Json json) => ProtocolVersion(
    id: stringField(json, 'id'),
    protocolId: stringField(json, 'protocol_id'),
    version: intField(json, 'version'),
    schemaVersion: intField(json, 'schema_version'),
    status: enumField(json, 'status', ProtocolStatus.values),
    document: asJson(json['document'], 'document'),
    createdAt: dateField(json, 'created_at'),
    publishedAt: json['published_at'] == null
        ? null
        : dateField(json, 'published_at'),
  );
  Json toJson() => {
    'id': id,
    'protocol_id': protocolId,
    'version': version,
    'schema_version': schemaVersion,
    'status': wireName(status),
    'document': document,
    'created_at': createdAt.toUtc().toIso8601String(),
    'published_at': publishedAt?.toUtc().toIso8601String(),
  };
}

final class Session {
  final String id;
  final String studyId;
  final String participantId;
  final String protocolVersionId;
  final String sessionDefinitionId;
  final DateTime startedAt;
  final DateTime? completedAt;
  Session({
    required this.id,
    required this.studyId,
    required this.participantId,
    required this.protocolVersionId,
    required this.sessionDefinitionId,
    required this.startedAt,
    this.completedAt,
  }) {
    requireUuid(id, 'id');
    requireUuid(studyId, 'study_id');
    requireUuid(participantId, 'participant_id');
    requireUuid(protocolVersionId, 'protocol_version_id');
    requireUuid(sessionDefinitionId, 'session_definition_id');
    if (completedAt != null && completedAt!.isBefore(startedAt))
      throw const FormatException('completed_at precedes started_at.');
  }
  factory Session.fromJson(Json json) => Session(
    id: stringField(json, 'id'),
    studyId: stringField(json, 'study_id'),
    participantId: stringField(json, 'participant_id'),
    protocolVersionId: stringField(json, 'protocol_version_id'),
    sessionDefinitionId: stringField(json, 'session_definition_id'),
    startedAt: dateField(json, 'started_at'),
    completedAt: json['completed_at'] == null
        ? null
        : dateField(json, 'completed_at'),
  );
  Json toJson() => {
    'id': id,
    'study_id': studyId,
    'participant_id': participantId,
    'protocol_version_id': protocolVersionId,
    'session_definition_id': sessionDefinitionId,
    'started_at': startedAt.toUtc().toIso8601String(),
    'completed_at': completedAt?.toUtc().toIso8601String(),
  };
}

final class SensorSummary {
  final SensorType sensorType;
  final int sampleCount;
  final double durationSeconds;
  final double? meanHz;
  final double? stddevHz;
  final double? meanIntervalNs;
  final double? stddevIntervalNs;
  final int? minIntervalNs;
  final int? maxIntervalNs;
  final int? estimatedMissing;
  SensorSummary({
    required this.sensorType,
    required this.sampleCount,
    required this.durationSeconds,
    this.meanHz,
    this.stddevHz,
    this.meanIntervalNs,
    this.stddevIntervalNs,
    this.minIntervalNs,
    this.maxIntervalNs,
    this.estimatedMissing,
  }) {
    requirePositive(sampleCount, 'sample_count', zero: true);
    requirePositive(durationSeconds, 'duration_seconds', zero: true);
    if (meanHz != null) requirePositive(meanHz!, 'mean_hz', zero: true);
    if (stddevHz != null) requirePositive(stddevHz!, 'stddev_hz', zero: true);
    if (meanIntervalNs != null)
      requirePositive(meanIntervalNs!, 'mean_interval_ns', zero: true);
    if (stddevIntervalNs != null)
      requirePositive(stddevIntervalNs!, 'stddev_interval_ns', zero: true);
    if (minIntervalNs != null)
      requirePositive(minIntervalNs!, 'min_interval_ns', zero: true);
    if (maxIntervalNs != null)
      requirePositive(maxIntervalNs!, 'max_interval_ns', zero: true);
    if (estimatedMissing != null)
      requirePositive(estimatedMissing!, 'estimated_missing', zero: true);
  }
  factory SensorSummary.fromJson(Json json) => SensorSummary(
    sensorType: enumField(json, 'sensor_type', SensorType.values),
    sampleCount: intField(json, 'sample_count'),
    durationSeconds: doubleField(json, 'duration_seconds'),
    meanHz: json['mean_hz'] == null ? null : doubleField(json, 'mean_hz'),
    stddevHz: json['stddev_hz'] == null ? null : doubleField(json, 'stddev_hz'),
    meanIntervalNs: json['mean_interval_ns'] == null
        ? null
        : doubleField(json, 'mean_interval_ns'),
    stddevIntervalNs: json['stddev_interval_ns'] == null
        ? null
        : doubleField(json, 'stddev_interval_ns'),
    minIntervalNs: json['min_interval_ns'] == null
        ? null
        : intField(json, 'min_interval_ns'),
    maxIntervalNs: json['max_interval_ns'] == null
        ? null
        : intField(json, 'max_interval_ns'),
    estimatedMissing: json['estimated_missing'] == null
        ? null
        : intField(json, 'estimated_missing'),
  );
  Json toJson() => {
    'sensor_type': wireName(sensorType),
    'sample_count': sampleCount,
    'duration_seconds': durationSeconds,
    'mean_hz': meanHz,
    'stddev_hz': stddevHz,
    'mean_interval_ns': meanIntervalNs,
    'stddev_interval_ns': stddevIntervalNs,
    'min_interval_ns': minIntervalNs,
    'max_interval_ns': maxIntervalNs,
    'estimated_missing': estimatedMissing,
  };
}

final class QualitySummary {
  final double durationSeconds;
  final List<SensorSummary> sensors;
  final List<String> warnings;
  QualitySummary({
    required this.durationSeconds,
    required List<SensorSummary> sensors,
    required List<String> warnings,
  }) : sensors = List.unmodifiable(sensors),
       warnings = List.unmodifiable(warnings) {
    requirePositive(durationSeconds, 'duration_seconds', zero: true);
  }
  factory QualitySummary.fromJson(Json json) => QualitySummary(
    durationSeconds: doubleField(json, 'duration_seconds'),
    sensors: listField(
      json,
      'sensors',
      (v) => SensorSummary.fromJson(asJson(v)),
    ),
    warnings: listField(
      json,
      'warnings',
      (v) => stringField({'value': v}, 'value'),
    ),
  );
  Json toJson() => {
    'duration_seconds': durationSeconds,
    'sensors': sensors.map((v) => v.toJson()).toList(),
    'warnings': warnings,
  };
}

final class Trial {
  final String id;
  final String studyId;
  final String participantId;
  final String sessionId;
  final String taskId;
  final String prompt;
  final int repetition;
  final Hand handUsed;
  final Posture posture;
  final TaskType taskType;
  final DeviceRole deviceRole;
  final String physicalDeviceId;
  final String appVersion;
  final String protocolVersionId;
  final int schemaVersion;
  final DateTime createdAt;
  final QualitySummary quality;
  Trial({
    required this.id,
    required this.studyId,
    required this.participantId,
    required this.sessionId,
    required this.taskId,
    required this.prompt,
    required this.repetition,
    required this.handUsed,
    required this.posture,
    required this.taskType,
    required this.deviceRole,
    required this.physicalDeviceId,
    required this.appVersion,
    required this.protocolVersionId,
    required this.schemaVersion,
    required this.createdAt,
    required this.quality,
  }) {
    requireUuid(id, 'id');
    requireUuid(studyId, 'study_id');
    requireUuid(participantId, 'participant_id');
    requireUuid(sessionId, 'session_id');
    requireUuid(taskId, 'task_id');
    requireText(prompt, 'prompt');
    requirePositive(repetition, 'repetition', zero: false);
    requireUuid(physicalDeviceId, 'physical_device_id');
    requireText(appVersion, 'app_version');
    requireUuid(protocolVersionId, 'protocol_version_id');
    requirePositive(schemaVersion, 'schema_version', zero: false);
    if (!{Hand.left, Hand.right}.contains(handUsed))
      throw const FormatException('Hand must resolve to an actual hand.');
    if (schemaVersion != 1)
      throw const FormatException('Unsupported schema_version. Expected 1.');
  }
  factory Trial.fromJson(Json json) => Trial(
    id: stringField(json, 'id'),
    studyId: stringField(json, 'study_id'),
    participantId: stringField(json, 'participant_id'),
    sessionId: stringField(json, 'session_id'),
    taskId: stringField(json, 'task_id'),
    prompt: stringField(json, 'prompt'),
    repetition: intField(json, 'repetition'),
    handUsed: enumField(json, 'hand_used', Hand.values),
    posture: enumField(json, 'posture', Posture.values),
    taskType: enumField(json, 'task_type', TaskType.values),
    deviceRole: enumField(json, 'device_role', DeviceRole.values),
    physicalDeviceId: stringField(json, 'physical_device_id'),
    appVersion: stringField(json, 'app_version'),
    protocolVersionId: stringField(json, 'protocol_version_id'),
    schemaVersion: intField(json, 'schema_version'),
    createdAt: dateField(json, 'created_at'),
    quality: QualitySummary.fromJson(asJson(json['quality'], 'quality')),
  );
  Json toJson() => {
    'id': id,
    'study_id': studyId,
    'participant_id': participantId,
    'session_id': sessionId,
    'task_id': taskId,
    'prompt': prompt,
    'repetition': repetition,
    'hand_used': wireName(handUsed),
    'posture': wireName(posture),
    'task_type': wireName(taskType),
    'device_role': wireName(deviceRole),
    'physical_device_id': physicalDeviceId,
    'app_version': appVersion,
    'protocol_version_id': protocolVersionId,
    'schema_version': schemaVersion,
    'created_at': createdAt.toUtc().toIso8601String(),
    'quality': quality.toJson(),
  };
}

final class TrialFile {
  final String id;
  final String trialId;
  final String objectKey;
  final int sizeBytes;
  final String sha256;
  final String contentType;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime? uploadedAt;
  TrialFile({
    required this.id,
    required this.trialId,
    required this.objectKey,
    required this.sizeBytes,
    required this.sha256,
    required this.contentType,
    required this.syncStatus,
    required this.createdAt,
    this.uploadedAt,
  }) {
    requireUuid(id, 'id');
    requireUuid(trialId, 'trial_id');
    requireText(objectKey, 'object_key');
    requirePositive(sizeBytes, 'size_bytes', zero: false);
    requireText(sha256, 'sha256');
    requireText(contentType, 'content_type');
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(sha256))
      throw const FormatException(
        'sha256 must contain 64 lowercase hexadecimal characters.',
      );
    if (contentType != 'application/gzip')
      throw const FormatException('Raw trial files must be application/gzip.');
    final parts = objectKey.split('/');
    if (parts.length != 6 ||
        parts[0] != 'study' ||
        parts[4] != trialId ||
        parts[5] != 'sensors.csv.gz')
      throw const FormatException('Invalid UUID object hierarchy.');
    for (final part in parts.sublist(1, 5)) {
      requireUuid(part, 'object_key');
    }
    if ((syncStatus == SyncStatus.synced) != (uploadedAt != null))
      throw const FormatException('Synced status and uploaded_at must agree.');
  }
  factory TrialFile.fromJson(Json json) => TrialFile(
    id: stringField(json, 'id'),
    trialId: stringField(json, 'trial_id'),
    objectKey: stringField(json, 'object_key'),
    sizeBytes: intField(json, 'size_bytes'),
    sha256: stringField(json, 'sha256'),
    contentType: stringField(json, 'content_type'),
    syncStatus: enumField(json, 'sync_status', SyncStatus.values),
    createdAt: dateField(json, 'created_at'),
    uploadedAt: json['uploaded_at'] == null
        ? null
        : dateField(json, 'uploaded_at'),
  );
  Json toJson() => {
    'id': id,
    'trial_id': trialId,
    'object_key': objectKey,
    'size_bytes': sizeBytes,
    'sha256': sha256,
    'content_type': contentType,
    'sync_status': wireName(syncStatus),
    'created_at': createdAt.toUtc().toIso8601String(),
    'uploaded_at': uploadedAt?.toUtc().toIso8601String(),
  };
}

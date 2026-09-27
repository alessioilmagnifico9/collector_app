import 'dart:convert';

import 'package:experiment_models/experiment_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final studyId = newUuid(), personId = newUuid(), deviceId = newUuid();
  final protocolId = newUuid(), versionId = newUuid(), sessionId = newUuid();
  final taskId = newUuid(), trialId = newUuid();
  final now = DateTime.utc(2026, 9, 23);
  final sensor = SensorMetadata(
    sensorType: SensorType.accelerometer,
    name: 'Accelerometer',
    requestedHz: 100,
  );
  final summary = SensorSummary(
    sensorType: SensorType.accelerometer,
    sampleCount: 2,
    durationSeconds: .01,
    meanHz: 100,
    stddevHz: 0,
    meanIntervalNs: 10000000,
    stddevIntervalNs: 0,
    minIntervalNs: 10000000,
    maxIntervalNs: 10000000,
    estimatedMissing: 0,
  );
  final quality = QualitySummary(
    durationSeconds: .01,
    sensors: [summary],
    warnings: [],
  );
  final fixtures = <(Json, Json Function(Json))>[
    (
      Study(id: studyId, name: 'Motion study', createdAt: now).toJson(),
      (j) => Study.fromJson(j).toJson(),
    ),
    (
      Participant(
        id: personId,
        studyId: studyId,
        sex: Sex.notReported,
        dominantHand: Hand.left,
        createdAt: now,
      ).toJson(),
      (j) => Participant.fromJson(j).toJson(),
    ),
    (sensor.toJson(), (j) => SensorMetadata.fromJson(j).toJson()),
    (
      PhysicalDevice(
        id: deviceId,
        model: 'Test phone',
        manufacturer: 'Test vendor',
        os: 'Android',
        osVersion: '16',
        appVersion: '0.1.0',
        sensors: [sensor],
        createdAt: now,
      ).toJson(),
      (j) => PhysicalDevice.fromJson(j).toJson(),
    ),
    (
      Protocol(
        id: protocolId,
        studyId: studyId,
        name: 'Protocol',
        createdAt: now,
      ).toJson(),
      (j) => Protocol.fromJson(j).toJson(),
    ),
    (
      ProtocolVersion(
        id: versionId,
        protocolId: protocolId,
        version: 1,
        schemaVersion: 1,
        status: ProtocolStatus.draft,
        document: {'sessions': <Object?>[]},
        createdAt: now,
      ).toJson(),
      (j) => ProtocolVersion.fromJson(j).toJson(),
    ),
    (
      Session(
        id: sessionId,
        studyId: studyId,
        participantId: personId,
        protocolVersionId: versionId,
        sessionDefinitionId: newUuid(),
        startedAt: now,
      ).toJson(),
      (j) => Session.fromJson(j).toJson(),
    ),
    (summary.toJson(), (j) => SensorSummary.fromJson(j).toJson()),
    (quality.toJson(), (j) => QualitySummary.fromJson(j).toJson()),
    (
      Trial(
        id: trialId,
        studyId: studyId,
        participantId: personId,
        sessionId: sessionId,
        taskId: taskId,
        prompt: 'Draw a circle',
        repetition: 1,
        handUsed: Hand.left,
        posture: Posture.seated,
        taskType: TaskType.genuine,
        deviceRole: DeviceRole.personal,
        physicalDeviceId: deviceId,
        appVersion: '0.1.0',
        protocolVersionId: versionId,
        schemaVersion: 1,
        createdAt: now,
        quality: quality,
      ).toJson(),
      (j) => Trial.fromJson(j).toJson(),
    ),
    (
      TrialFile(
        id: newUuid(),
        trialId: trialId,
        objectKey:
            'study/$studyId/$personId/$sessionId/$trialId/sensors.csv.gz',
        sizeBytes: 32,
        sha256: 'a' * 64,
        contentType: 'application/gzip',
        syncStatus: SyncStatus.local,
        createdAt: now,
      ).toJson(),
      (j) => TrialFile.fromJson(j).toJson(),
    ),
  ];
  test('all domain records survive JSON serialization', () {
    for (final (json, decode) in fixtures) {
      expect(decode(asJson(jsonDecode(jsonEncode(json)))), json);
    }
  });
  test(
    'UUID generator creates valid distinct installation-independent values',
    () {
      final ids = List.generate(100, (_) => newUuid());
      for (final id in ids) {
        requireUuid(id, 'id');
      }
      expect(ids.toSet().length, 100);
      expect(
        () => requireUuid('participant-name', 'id'),
        throwsFormatException,
      );
    },
  );
  test('rejects invalid domain data with field-specific errors', () {
    expect(
      () => Study.fromJson({...fixtures[0].$1, 'name': ''}),
      throwsFormatException,
    );
    expect(
      () => Study.fromJson({...fixtures[0].$1, 'created_at': '2026-01-01'}),
      throwsFormatException,
    );
    expect(
      () => Participant.fromJson({
        ...fixtures[1].$1,
        'dominant_hand': 'dominant',
      }),
      throwsFormatException,
    );
    expect(
      () => SensorMetadata.fromJson({...sensor.toJson(), 'requested_hz': 0}),
      throwsFormatException,
    );
    expect(
      () => ProtocolVersion.fromJson({...fixtures[5].$1, 'schema_version': 2}),
      throwsFormatException,
    );
    expect(
      () =>
          ProtocolVersion.fromJson({...fixtures[5].$1, 'status': 'published'}),
      throwsFormatException,
    );
    expect(
      () => Trial.fromJson({...fixtures[9].$1, 'repetition': 0}),
      throwsFormatException,
    );
    expect(
      () => TrialFile.fromJson({...fixtures[10].$1, 'object_key': '../other'}),
      throwsFormatException,
    );
    expect(
      () => TrialFile.fromJson({...fixtures[10].$1, 'sha256': 'invalid'}),
      throwsFormatException,
    );
    expect(
      () => TrialFile.fromJson({...fixtures[10].$1, 'sync_status': 'synced'}),
      throwsFormatException,
    );
  });
  test(
    'protocol document and device lists defensively copy mutable inputs',
    () {
      final tasks = <Object?>[
        {'prompt': 'Original'},
      ];
      final version = ProtocolVersion(
        id: versionId,
        protocolId: protocolId,
        version: 1,
        schemaVersion: 1,
        status: ProtocolStatus.published,
        document: {'tasks': tasks},
        createdAt: now,
        publishedAt: now,
      );
      tasks.clear();
      expect(version.document['tasks'], hasLength(1));
      expect(
        () => (version.document['tasks'] as List<Object?>).clear(),
        throwsUnsupportedError,
      );
      expect(
        () => asJson(
          (version.document['tasks'] as List<Object?>).first,
        )['prompt'] = 'Changed',
        throwsUnsupportedError,
      );
    },
  );
}

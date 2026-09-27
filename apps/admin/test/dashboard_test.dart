import 'package:collector_admin/dashboard/dashboard.dart';
import 'package:collector_admin/dashboard/repository.dart';
import 'package:collector_admin/protocols/editor.dart';
import 'package:experiment_models/experiment_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol_engine/protocol_engine.dart';

StudyDataset datasetFixture() {
  final study = Study(
    id: newUuid(),
    name: 'Study',
    createdAt: DateTime.utc(2026),
  );
  final person = Participant(
    id: newUuid(),
    studyId: study.id,
    displayNumber: 123,
    sex: Sex.notReported,
    dominantHand: Hand.right,
    createdAt: DateTime.utc(2026),
  );
  final protocol = Protocol(
    id: newUuid(),
    studyId: study.id,
    name: 'Protocol',
    createdAt: DateTime.utc(2026),
  );
  final version = publishVersion(
    ProtocolVersion(
      id: newUuid(),
      protocolId: protocol.id,
      version: 1,
      schemaVersion: 1,
      status: ProtocolStatus.draft,
      document: newProtocolDocument(),
      createdAt: DateTime.utc(2026),
    ),
    DateTime.utc(2026),
  );
  final pinned = startSession(
    version: version,
    protocol: protocol,
    participant: person,
    sessionDefinitionId: ProtocolDefinition.fromJson(version.document)
        .sessions
        .first
        .id,
    now: DateTime.utc(2026),
  );
  final plan = pinned.queue.first;
  final device = PhysicalDevice(
    id: newUuid(),
    model: 'Test phone',
    manufacturer: 'Test vendor',
    os: 'Test OS',
    osVersion: '1',
    appVersion: '1',
    sensors: [],
    createdAt: DateTime.utc(2026),
  );
  final trial = Trial(
    id: plan.id,
    studyId: study.id,
    participantId: person.id,
    sessionId: pinned.session.id,
    taskId: plan.task.id,
    prompt: plan.task.prompt,
    repetition: plan.repetition,
    handUsed: Hand.right,
    posture: plan.task.posture,
    taskType: plan.taskType,
    deviceRole: plan.task.deviceRole,
    physicalDeviceId: device.id,
    appVersion: '1',
    protocolVersionId: version.id,
    schemaVersion: 1,
    quality: QualitySummary(
      durationSeconds: 1,
      sensors: [
        SensorSummary(
          sensorType: SensorType.accelerometer,
          sampleCount: 2,
          durationSeconds: 1,
          meanHz: 1,
          estimatedMissing: 99,
        ),
      ],
      warnings: [],
    ),
    createdAt: DateTime.utc(2026),
  );
  final file = TrialFile(
    id: newUuid(),
    trialId: trial.id,
    objectKey:
        'study/${study.id}/${person.id}/${pinned.session.id}/${trial.id}/sensors.csv.gz',
    sizeBytes: 3,
    sha256: 'a' * 64,
    contentType: 'application/gzip',
    syncStatus: SyncStatus.failed,
    createdAt: DateTime.utc(2026),
  );
  return StudyDataset({
    'export_schema_version': 1,
    'study': study.toJson(),
    'participants': [person.toJson()],
    'devices': [device.toJson()],
    'protocols': [protocol.toJson()],
    'protocol_versions': [version.toJson()],
    'sessions': [pinned.session.toJson()],
    'trials': [trial.toJson()],
    'trial_files': [file.toJson()],
  });
}

class FakeDashboard implements DashboardRepository {
  final StudyDataset dataset;
  bool fail = false;
  FakeDashboard(this.dataset);
  @override
  Future<StudyDataset> load(String studyId) async {
    if (fail) throw StateError('denied');
    return dataset;
  }
}

void main() {
  test('progress uses pinned protocol and warns on unavailable, slow and missing samples', () {
    final data = datasetFixture();
    expect(data.expected(data.sessions.single), greaterThan(0));
    expect(data.synced(data.sessions.single), 0);
    final warnings = data.warnings(data.trials.single);
    expect(warnings, contains('accelerometer: estimated sample gaps'));
    expect(warnings, contains('accelerometer: rate below 80% of requested'));
    expect(warnings, contains('gyroscope: insufficient samples'));
  });
  testWidgets(
    'dashboard exposes incomplete sessions and clears stale data on denied refresh',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = datasetFixture();
      final repository = FakeDashboard(data);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResearchDashboard(
              study: Study.fromJson(asJson(data.document['study'])),
              repository: repository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 pending or failed uploads'), findsOneWidget);
      await tester.tap(find.text('Participant 000123'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Incomplete'), findsOneWidget);
      await tester.tap(
        find.text(data.names.sessionLabel(data.sessions.single)),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('accelerometer: estimated sample gaps'),
        findsOneWidget,
      );
      repository.fail = true;
      await tester.tap(find.text('Refresh progress'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Progress could not be loaded'),
        findsOneWidget,
      );
      expect(find.text('1 pending or failed uploads'), findsNothing);
    },
  );
}

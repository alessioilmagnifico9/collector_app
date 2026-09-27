import 'dart:convert';
import 'dart:io';

import 'package:collector_admin/dashboard/repository.dart';
import 'package:collector_admin/export/bundle.dart';
import 'package:collector_admin/export/export_screen.dart';
import 'package:crypto/crypto.dart';
import 'package:experiment_models/experiment_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test.dart';
import 'export_test.dart' show FakeSource, Downloads;

StudyDataset verifiedFixture() {
  final data = StudyDataset(
    asJson(jsonDecode(jsonEncode(datasetFixture().document))),
  );
  final file = (data.document['trial_files'] as List).first;
  file['sync_status'] = 'synced';
  file['uploaded_at'] = DateTime.utc(2026).toIso8601String();
  file['sha256'] = sha256.convert([1, 2, 3]).toString();
  return data;
}

void main() {
  test('export root uses portable study name and frozen snapshot', () {
    expect(studyExportFolder('data_test', 'id'), 'data_test');
    expect(studyExportFolder('../../Data Test\\', 'id'), 'data-test');
    expect(studyExportFolder('CON', 'id'), 'study-con');
    expect(studyExportFolder('你好', 'id'), 'study-id');
    final data = verifiedFixture();
    (data.document['study'] as Map)['name'] = 'data_test';
    final plan = ExportPlan(data);
    (data.document['study'] as Map)['name'] = 'renamed';
    expect(plan.entries.single.path, startsWith('data_test/'));
  });

  test(
    'numbered and legacy participants round trip without changing identity',
    () {
      final person = datasetFixture().participants.single;
      expect(person.displayLabel, 'Participant 000123');
      expect(Participant.fromJson(person.toJson()).displayNumber, 123);
      final legacy = person.toJson()..remove('display_number');
      expect(Participant.fromJson(legacy).id, person.id);
      expect(Participant.fromJson(legacy).displayLabel, contains('legacy'));
      for (final bad in [0, -1, 2147483648]) {
        expect(
          () => Participant.fromJson({...legacy, 'display_number': bad}),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'pinned labels ignore newer versions and paths exclude unsafe free text',
    () {
      final data = verifiedFixture();
      final versions = data.document['protocol_versions'] as List;
      final newer = asJson(jsonDecode(jsonEncode(versions.first)));
      newer['id'] = newUuid();
      newer['version'] = 2;
      (asJson(newer['document'])['sessions'] as List)[0]['title'] =
          'Changed session';
      (asJson(newer['document'])['sessions'] as List)[0]['tasks'][0]['prompt'] =
          'Changed task';
      versions.add(newer);
      final pinned = versions.first;
      pinned['document']['sessions'][0]['title'] = '../Alice@example.com';
      pinned['document']['sessions'][0]['tasks'][0]['prompt'] =
          'CON / \\ : Alice@example.com .. enrollment-code';
      (data.document['study'] as Map)['name'] = 'Alice@example.com';
      final trial = data.trials.single;
      expect(
        data.names.sessionLabel(data.sessions.single),
        contains('../Alice@example.com'),
      );
      expect(data.names.taskLabel(trial), contains('CON'));
      final path = data.names.exportPath(trial);
      expect(
        path,
        contains(
          'participant-000123/session-01-attempt-01/task-001/genuine-repetition-001',
        ),
      );
      expect(path, isNot(contains('Alice')));
      expect(path, isNot(contains('CON')));
      expect(path, matches(RegExp(r'^[a-z0-9/.-]+$')));
      expect(path, isNot(contains('..')));
    },
  );
  test('practice, retries, repeated sessions and identical device models stay distinct', () {
    final data = verifiedFixture();
    final trialRows = data.document['trials'] as List;
    final original = asJson(trialRows.first);
    final retry = {
      ...original,
      'id': newUuid(),
      'created_at': DateTime.utc(2027).toIso8601String(),
    };
    final practice = {...original, 'id': newUuid(), 'task_type': 'practice'};
    final sessionRows = data.document['sessions'] as List;
    final nextSession = {
      ...asJson(sessionRows.first),
      'id': newUuid(),
      'started_at': DateTime.utc(2027).toIso8601String(),
    };
    sessionRows.add(nextSession);
    final next = {
      ...original,
      'id': newUuid(),
      'session_id': nextSession['id'],
    };
    final devices = data.document['devices'] as List;
    final otherDevice = {...asJson(devices.first), 'id': newUuid()};
    devices.add(otherDevice);
    retry['physical_device_id'] = otherDevice['id'];
    trialRows.addAll([retry, practice, next]);
    final paths = data.trials.map(data.names.exportPath).toSet();
    expect(paths.length, 4);
    expect(paths.any((p) => p.contains('practice-repetition')), isTrue);
    expect(paths.any((p) => p.contains('attempt-02')), isTrue);
    expect(data.names.recording(Trial.fromJson(retry)), 2);
    expect(
      data.names.deviceLabel(data.trials.first),
      isNot(data.names.deviceLabel(Trial.fromJson(retry))),
    );
  });
  test(
    'frozen manifest maps identities, original keys, sizes, hashes and version',
    () {
      final data = verifiedFixture();
      final plan = ExportPlan(data);
      (data.document['study'] as Map)['name'] = 'Changed after selection';
      final entry = plan.entries.single;
      final manifest = jsonDecode(plan.manifest(plan.entries));
      expect(manifest['files'].single['study_id'], entry.trial.studyId);
      expect(
        manifest['files'].single['participant_id'],
        entry.trial.participantId,
      );
      expect(manifest['files'].single['session_id'], entry.trial.sessionId);
      expect(
        manifest['files'].single['physical_device_id'],
        entry.trial.physicalDeviceId,
      );
      expect(manifest['files'].single['protocol_version'], 1);
      expect(manifest['files'].single['object_key'], entry.file.objectKey);
      expect(manifest['files'].single['sha256'], entry.file.sha256);
      expect(plan.metadata, isNot(contains('Changed after selection')));
      expect(
        manifest['metadata_sha256'],
        sha256.convert(utf8.encode(plan.metadata)).toString(),
      );
    },
  );
  test(
    'ZIP is independently readable and partial archives retain failed mappings',
    () async {
      final plan = ExportPlan(verifiedFixture());
      final source = FakeSource();
      final good = await buildBundle(plan, plan.entries, source);
      expect(good.saved, 1);
      source.fail = true;
      final partial = await buildBundle(plan, plan.entries, source);
      expect(partial.saved, 0);
      expect(partial.failed, [plan.entries.single.path]);
      final dir = await Directory.systemTemp.createTemp('readable-zip-');
      try {
        await File('${dir.path}/good.zip').writeAsBytes(good.bytes);
        await File('${dir.path}/partial.zip').writeAsBytes(partial.bytes);
        final result = await Process.run('python3', [
          '-c',
          '''
import sys,zipfile,json
with zipfile.ZipFile(sys.argv[1]) as z:
 assert z.testzip() is None
 m=json.loads(z.read('manifest.json'))
 assert z.read(m['files'][0]['path']) == bytes([1,2,3])
 assert json.loads(z.read('export-report.json'))['complete']
with zipfile.ZipFile(sys.argv[2]) as z:
 assert z.testzip() is None
 m=json.loads(z.read('manifest.json'))
 assert len(m['files']) == 1
 assert m['files'][0]['path'] not in z.namelist()
 assert not json.loads(z.read('export-report.json'))['complete']
''',
          '${dir.path}/good.zip',
          '${dir.path}/partial.zip',
        ]);
        expect(result.exitCode, 0, reason: '${result.stderr}');
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );
  test('checksum mismatch is an explicit failure; oversized entries require streaming', () async {
    final data = verifiedFixture();
    (data.document['trial_files'] as List).first['sha256'] = 'a' * 64;
    var plan = ExportPlan(data);
    expect(
      (await buildBundle(plan, plan.entries, FakeSource())).failed,
      hasLength(1),
    );
    (data.document['trial_files'] as List).first['size_bytes'] =
        maxArchiveBytes + 1;
    plan = ExportPlan(data);
    expect(plan.parts, isEmpty);
    expect(jsonDecode(plan.streamingPlan)['manifest']['files'], hasLength(1));
    expect(
      () => buildBundle(plan, plan.entries, FakeSource()),
      throwsStateError,
    );
  });
  test('archive parts bound byte totals and file counts with deterministic order', () {
    final data = verifiedFixture();
    final trials = data.document['trials'] as List;
    final files = data.document['trial_files'] as List;
    final templateTrial = asJson(trials.single);
    final templateFile = asJson(files.single);
    for (var i = 0; i < 200; i++) {
      final trialId = newUuid();
      trials.add({...templateTrial, 'id': trialId});
      files.add({
        ...templateFile,
        'id': newUuid(),
        'trial_id': trialId,
        'object_key':
            'study/${templateTrial['study_id']}/${templateTrial['participant_id']}/${templateTrial['session_id']}/$trialId/sensors.csv.gz',
      });
    }
    final plan = ExportPlan(data);
    expect(plan.parts.map((p) => p.length), [200, 1]);
    final reordered = {
      ...data.document,
      'trials': trials.reversed.toList(),
      'trial_files': files.reversed.toList(),
    };
    expect(
      ExportPlan(StudyDataset(reordered)).streamingPlan,
      plan.streamingPlan,
    );
    for (final file in files) {
      file['size_bytes'] = maxArchiveBytes ~/ 2 + 1;
    }
    final large = ExportPlan(
      StudyDataset({...data.document, 'trial_files': files}),
    );
    expect(large.parts, hasLength(201));
    expect(
      large.parts.every(
        (p) =>
            p.fold<int>(0, (n, e) => n + e.file.sizeBytes) <= maxArchiveBytes,
      ),
      isTrue,
    );
  });
  testWidgets(
    'failed raw transfer produces visible partial status and partial ZIP',
    (tester) async {
      final data = verifiedFixture();
      String? filename;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatasetExportScreen(
              study: Study.fromJson(asJson(data.document['study'])),
              repository: FakeDashboard(data),
              downloads: Downloads(),
              source: FakeSource()..fail = true,
              saveBundle: (_, name) => filename = name,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Download verified raw file'));
      await tester.pumpAndSettle();
      expect(filename, endsWith('-PARTIAL.zip'));
      expect(
        find.textContaining('PARTIAL export: 0 files saved, 1 failed'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'automatic list load has loading, empty, failure and refresh states',
    (tester) async {
      final data = datasetFixture();
      (data.document['trial_files'] as List).clear();
      final repository = FakeDashboard(data)..fail = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatasetExportScreen(
              study: Study.fromJson(asJson(data.document['study'])),
              repository: repository,
              downloads: Downloads(),
            ),
          ),
        ),
      );
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.textContaining('Files could not be loaded'), findsOneWidget);
      repository.fail = false;
      await tester.tap(find.text('Refresh files'));
      await tester.pumpAndSettle();
      expect(find.text('No files received yet.'), findsOneWidget);
      expect(find.textContaining('Files could not be loaded'), findsNothing);
    },
  );
}

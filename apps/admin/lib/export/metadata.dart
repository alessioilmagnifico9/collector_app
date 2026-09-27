import 'dart:convert';

import 'package:experiment_models/experiment_models.dart';

import '../dashboard/repository.dart';

// Export only reviewed research fields, even if the server later adds columns.
const exportColumns = <String, List<String>>{
  'participants': [
    'id',
    'study_id',
    'display_number',
    'sex',
    'dominant_hand',
    'created_at',
  ],
  'devices': [
    'id',
    'model',
    'manufacturer',
    'os',
    'os_version',
    'app_version',
    'sensors',
    'created_at',
  ],
  'protocols': ['id', 'study_id', 'name', 'active_version_id', 'created_at'],
  'protocol_versions': [
    'id',
    'protocol_id',
    'version',
    'schema_version',
    'status',
    'document',
    'created_at',
    'published_at',
  ],
  'sessions': [
    'id',
    'study_id',
    'participant_id',
    'protocol_id',
    'protocol_version_id',
    'session_definition_id',
    'started_at',
    'completed_at',
  ],
  'trials': [
    'id',
    'study_id',
    'participant_id',
    'session_id',
    'task_id',
    'prompt',
    'repetition',
    'hand_used',
    'posture',
    'task_type',
    'device_role',
    'physical_device_id',
    'app_version',
    'protocol_version_id',
    'schema_version',
    'quality',
    'created_at',
  ],
  'trial_files': [
    'id',
    'trial_id',
    'object_key',
    'size_bytes',
    'sha256',
    'content_type',
    'sync_status',
    'created_at',
    'uploaded_at',
  ],
};
Object? canonical(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return {for (final key in keys) key: canonical(value[key])};
  }
  if (value is List) return value.map(canonical).toList();
  return value;
}

String exportMetadata(StudyDataset snapshot) {
  final study = asJson(snapshot.document['study']);
  final document = <String, Object?>{
    'export_schema_version': 1,
    'study': {
      for (final key in ['id', 'name', 'created_at']) key: study[key],
    },
    for (final entry in exportColumns.entries)
      entry.key:
          (snapshot
              .rows(entry.key)
              .map(
                (row) => <String, Object?>{
                  for (final key in entry.value) key: row[key],
                },
              )
              .toList()
            ..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String))),
  };
  return '${const JsonEncoder.withIndent('  ').convert(canonical(document))}\n';
}

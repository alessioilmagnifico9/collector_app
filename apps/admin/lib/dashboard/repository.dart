import 'package:experiment_models/experiment_models.dart';
import 'package:protocol_engine/protocol_engine.dart';
import 'package:protocol_engine/dataset_names.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

final class StudyDataset {
  final Json document;
  late final List<Participant> participants = rows('participants')
      .map(Participant.fromJson)
      .toList();
  late final List<PhysicalDevice> devices = rows('devices')
      .map(PhysicalDevice.fromJson)
      .toList();
  late final List<Session> sessions = rows('sessions')
      .map(Session.fromJson)
      .toList();
  late final List<Trial> trials = rows('trials').map(Trial.fromJson).toList();
  late final List<TrialFile> files = rows('trial_files')
      .map(TrialFile.fromJson)
      .toList();
  late final List<ProtocolVersion> versions = rows('protocol_versions')
      .map(ProtocolVersion.fromJson)
      .toList();
  late final DatasetNames names = DatasetNames(
    participants: participants,
    sessions: sessions,
    trials: trials,
    versions: versions,
    devices: devices,
  );
  StudyDataset(this.document);
  List<Json> rows(String table) =>
      (document[table] as List).map(asJson).toList();
  ProtocolVersion version(Session session) =>
      versions.firstWhere((v) => v.id == session.protocolVersionId);
  int expected(Session session) =>
      ProtocolDefinition.fromJson(version(session).document).sessions
          .firstWhere((s) => s.id == session.sessionDefinitionId)
          .tasks
          .fold(0, (n, t) => n + t.repetitions + t.practiceRepetitions);
  List<Trial> sessionTrials(Session session) =>
      trials.where((t) => t.sessionId == session.id).toList();
  TrialFile? trialFile(Trial trial) =>
      files.where((f) => f.trialId == trial.id).firstOrNull;
  int synced(Session session) =>
      sessionTrials(session)
          .where((t) => trialFile(t)?.syncStatus == SyncStatus.synced)
          .length;
  List<String> warnings(Trial trial) {
    final result = <String>[...trial.quality.warnings];
    final version = versions.firstWhere((v) => v.id == trial.protocolVersionId);
    final hz = ProtocolDefinition.fromJson(version.document).requestedHz;
    for (final type in SensorType.values) {
      final sensor = trial.quality.sensors
          .where((s) => s.sensorType == type)
          .firstOrNull;
      if (sensor == null || sensor.sampleCount < 2) {
        result.add('${type.name}: insufficient samples');
        continue;
      }
      if ((sensor.estimatedMissing ?? 0) > 0)
        result.add('${type.name}: estimated sample gaps');
      if (sensor.meanHz != null && sensor.meanHz! < hz * .8)
        result.add('${type.name}: rate below 80% of requested');
    }
    return result;
  }
}

abstract interface class DashboardRepository {
  Future<StudyDataset> load(String studyId);
}

final class SupabaseDashboardRepository implements DashboardRepository {
  final SupabaseClient client;
  SupabaseDashboardRepository(this.client);
  @override
  Future<StudyDataset> load(String studyId) async => StudyDataset(
    asJson(
      await client.rpc<dynamic>(
        'study_dataset',
        params: {'study_uuid': studyId},
      ),
    ),
  );
}

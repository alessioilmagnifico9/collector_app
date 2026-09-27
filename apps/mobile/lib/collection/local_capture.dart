import 'dart:io';

import 'package:dataset_schema/finalization.dart';
import 'package:experiment_models/experiment_models.dart';
import 'package:protocol_engine/protocol_engine.dart';

import '../sensors/native_recorder.dart';
import '../storage/local_database.dart' show LocalDatabase;
import 'services.dart';

/// Owns one native attempt. No upload is allowed on this acquisition path.
final class LocalTrialCapture implements SessionTrialCapture {
  final SensorRecorder recorder;
  final LocalDatabase database;
  final PhysicalDevice device;
  double get requestedHz => _session == null
      ? 100
      : ProtocolDefinition.fromJson(_session!.version.document).requestedHz;
  PinnedSession? _session;
  TrialPlan? _plan;
  Hand? _hand;
  DateTime? _startedAt;
  ClosedRecording? _closed;
  bool _starting = false, _stopping = false, _saving = false;
  int _generation = 0;
  LocalTrialCapture({
    required this.recorder,
    required this.database,
    required this.device,
  });

  @override
  void prepareSession(PinnedSession session) {
    if (_plan != null || _starting) throw StateError('A recording is active.');
    _session = session;
  }

  @override
  Future<void> start(TrialPlan plan, Hand hand) async {
    final session = _session;
    if (session == null || _plan != null || _starting)
      throw StateError('Recorder is not ready.');
    _starting = true;
    final generation = _generation;
    try {
      final (stored, index) = await database.loadSession(session.session.id);
      if (generation != _generation) throw StateError('Start was interrupted.');
      if (index >= stored.queue.length || stored.queue[index].id != plan.id)
        throw StateError('Trial is not the next unsaved task.');
      _plan = plan;
      _hand = hand;
      _startedAt = DateTime.now().toUtc();
      await recorder.start(plan.id, requestedHz);
      if (generation != _generation) {
        throw StateError('Start was interrupted.');
      }
    } catch (_) {
      // A failed acknowledgement does not prove native acquisition never began.
      // Keep start fenced until cleanup settles, including cancellation during DB IO.
      try {
        await recorder.abort();
      } finally {
        _plan = null;
        _closed = null;
      }
      rethrow;
    } finally {
      _starting = false;
    }
  }

  @override
  Future<void> checkRecording() async {
    final plan = _plan;
    if (plan == null || _starting || _stopping || _closed != null)
      throw StateError('No active recording to check.');
    await recorder.checkRecording(plan.id);
  }

  @override
  Future<void> stop() async {
    final plan = _plan;
    if (plan == null || _starting || _stopping || _closed != null)
      throw StateError('Recorder cannot stop in this state.');
    _stopping = true;
    try {
      final closed = await recorder.stop(plan.id);
      if (closed.trialId != plan.id)
        throw StateError('Closed trial identity mismatch.');
      _closed = closed;
    } finally {
      _stopping = false;
    }
  }

  @override
  Future<void> save() async {
    final closed = _closed;
    final plan = _plan;
    if (closed == null || plan == null || _saving)
      throw StateError('No closed trial to save.');
    _saving = true;
    try {
      final finalized = await finalizeRawFile(
        File(closed.rawPath),
        expectedSampleCount: closed.sampleCount,
        requestedRates: {
          for (final sensor in device.sensors) sensor.sensorType: requestedHz,
        },
      );
      final session = _session!.session;
      final trial = Trial(
        id: plan.id,
        studyId: session.studyId,
        participantId: session.participantId,
        sessionId: session.id,
        taskId: plan.task.id,
        prompt: plan.task.prompt,
        repetition: plan.repetition,
        handUsed: _hand!,
        posture: plan.task.posture,
        taskType: plan.taskType,
        deviceRole: plan.task.deviceRole,
        physicalDeviceId: device.id,
        appVersion: device.appVersion,
        protocolVersionId: session.protocolVersionId,
        schemaVersion: _session!.version.schemaVersion,
        createdAt: _startedAt!,
        quality: finalized.quality,
      );
      final file = TrialFile(
        id: newUuid(),
        trialId: plan.id,
        objectKey:
            'study/${session.studyId}/${session.participantId}/${session.id}/${plan.id}/sensors.csv.gz',
        sizeBytes: finalized.sizeBytes,
        sha256: finalized.sha256,
        contentType: 'application/gzip',
        syncStatus: SyncStatus.local,
        createdAt: _startedAt!,
      );
      await database.saveTrial(
        trial: trial,
        file: file,
        finalized: finalized,
        rawPath: closed.rawPath,
      );
      _plan = null;
      _closed = null;
    } finally {
      _saving = false;
    }
  }

  @override
  Future<void> abort() async {
    // A local commit must finish even when the widget is disposed.
    if (_saving) return;
    _generation++;
    await recorder.abort();
    _plan = null;
    _closed = null;
  }
}

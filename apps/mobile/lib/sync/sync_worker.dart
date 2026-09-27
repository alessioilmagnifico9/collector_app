import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dataset_schema/finalization.dart';
import 'package:experiment_models/experiment_models.dart';

import '../storage/local_database.dart' show LocalDatabase;
import 'upload_gateway.dart';

final class SyncWorker {
  final LocalDatabase database;
  final UploadGateway gateway;
  final DateTime Function() now;
  bool _running = false;
  SyncWorker({
    required this.database,
    required this.gateway,
    DateTime Function()? now,
  }) : now = now ?? (() => DateTime.now().toUtc());
  Future<bool> runOnce() async {
    if (_running) return false;
    _running = true;
    try {
      final job = await database.claimUpload(now());
      if (job == null) return false;
      try {
        final row = await (database.select(
          database.storedTrials,
        )..where((t) => t.id.equals(job.trialId))).getSingle();
        final trial = Trial.fromJson(asJson(jsonDecode(row.payload)));
        final file = TrialFile.fromJson(asJson(jsonDecode(row.filePayload)));
        final bytes = File(row.compressedPath);
        if (await bytes.length() != file.sizeBytes ||
            await checksumFile(bytes) != file.sha256)
          throw StateError('Local file verification failed.');
        final grant =
            await (database.select(database.enrollmentGrants)
                  ..where((g) => g.participantId.equals(trial.participantId)))
                .getSingle();
        final session = (await database.loadSession(trial.sessionId)).$1;
        final bundle = UploadBundle(
          session: session.session.toJson(),
          trial: trial,
          file: file,
          compressedPath: row.compressedPath,
          deviceToken: grant.deviceToken,
        );
        final authorization = await gateway.authorize(bundle);
        await gateway.upload(authorization, bytes);
        final verified = await gateway.finalize(bundle);
        if (verified.id != file.id ||
            verified.trialId != trial.id ||
            verified.sha256 != file.sha256 ||
            verified.sizeBytes != file.sizeBytes ||
            verified.objectKey != file.objectKey ||
            verified.contentType != file.contentType ||
            verified.syncStatus != SyncStatus.synced ||
            verified.uploadedAt == null)
          throw StateError('Remote verification differs from local manifest.');
        await database.finishUpload(
          job.trialId,
          attempt: job.attempts,
          now: now(),
          verified: true,
        );
      } catch (_) {
        // Error classes are intentionally coarse; tokens/URLs never enter logs or DB.
        try {
          await database.finishUpload(
            job.trialId,
            attempt: job.attempts,
            now: now(),
            verified: false,
            errorCode: 'upload_failed',
          );
        } on StateError {
          /* A newer attempt owns the expired lease. */
        }
      }
      return true;
    } finally {
      _running = false;
    }
  }
}

/// Runs while the process is scheduled. OS suspension is recovered on foreground.
final class SyncScheduler {
  final SyncWorker worker;
  final bool Function() canRun;
  Timer? _timer;
  bool _stopped = false;
  Future<void>? _draining;
  SyncScheduler(this.worker, {required this.canRun});
  void start() {
    if (_stopped) return;
    _timer ??= Timer.periodic(const Duration(seconds: 30), (_) => kick());
    kick();
  }

  void kick() {
    if (!_stopped && canRun() && _draining == null) {
      _draining = _drain().whenComplete(() => _draining = null);
    }
  }

  Future<void> _drain() async {
    try {
      while (!_stopped && canRun() && await worker.runOnce()) {}
    } catch (_) {
      /* Next foreground/timer tick retries durable work. */
    }
  }

  Future<void> stop() async {
    _stopped = true;
    _timer?.cancel();
    _timer = null;
    await _draining;
  }
}

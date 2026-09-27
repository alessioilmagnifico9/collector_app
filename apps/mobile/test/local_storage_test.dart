import 'dart:convert';
import 'dart:async';

import 'package:collector_mobile/sync/sync_worker.dart';
import 'package:collector_mobile/sync/upload_gateway.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'dart:io';

import 'package:collector_mobile/collection/local_capture.dart';
import 'package:collector_mobile/collection/services.dart';
import 'package:collector_mobile/sensors/native_recorder.dart';
import 'package:collector_mobile/storage/device_registration.dart';
import 'package:collector_mobile/storage/local_database.dart'
    show LocalDatabase;
import 'package:collector_mobile/storage/session_store.dart';
import 'package:dataset_schema/dataset_schema.dart';
import 'package:dataset_schema/finalization.dart';
import 'package:drift/native.dart';
import 'package:experiment_models/experiment_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol_engine/protocol_engine.dart';

final class FileRecorder implements SensorRecorder {
  final Directory directory;
  FileRecorder(this.directory);
  String? active;
  int starts = 0;
  bool failStart = false;
  @override
  Future<void> checkRecording(String trialId) async {
    if (active != trialId) throw StateError('Wrong trial');
  }

  @override
  Future<void> start(String trialId, double requestedHz) async {
    starts++;
    active = trialId;
    if (failStart) throw StateError('Start acknowledgement failed');
  }

  @override
  Future<ClosedRecording> stop(String trialId) async {
    if (active != trialId) throw StateError('Wrong trial');
    final file = File('${directory.path}/$trialId.csv');
    await file.writeAsString(
      '$rawCsvHeader\n1000000000,accelerometer,1,2,3,,3\n1010000000,accelerometer,2,3,4,,3\n',
      flush: true,
    );
    active = null;
    return ClosedRecording({
      'trial_id': trialId,
      'raw_path': file.path,
      'sample_count': 2,
    });
  }

  @override
  Future<void> abort() async {
    active = null;
  }

  @override
  Future<SensorCapabilities> capabilities(double requestedHz) async =>
      SensorCapabilities({
        'sensors': [
          {
            'sensor_type': 'accelerometer',
            'name': 'test accelerometer',
            'requested_hz': requestedHz,
          },
        ],
        'unavailable': ['gyroscope', 'gravity', 'rotation', 'magnetometer'],
        'model': 'Test phone',
        'manufacturer': 'Test vendor',
        'os': 'test',
        'os_version': '1',
        'app_version': '1.0',
      });
}

class PausingSessionDatabase extends LocalDatabase {
  PausingSessionDatabase(super.executor);
  Completer<void>? sessionRead, releaseRead;
  @override
  Future<(PinnedSession, int)> loadSession(String id) async {
    final value = await super.loadSession(id);
    sessionRead?.complete();
    await releaseRead?.future;
    return value;
  }
}

PhysicalDevice testDevice() => PhysicalDevice(
  id: newUuid(),
  model: 'Test',
  manufacturer: 'Test',
  os: 'test',
  osVersion: '1',
  appVersion: '1',
  sensors: [
    SensorMetadata(
      sensorType: SensorType.accelerometer,
      name: 'Test accelerometer',
      requestedHz: 100,
    ),
  ],
  createdAt: DateTime.now().toUtc(),
);

final class StalledUploadClient extends http.BaseClient {
  bool aborted = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final abort = (request as http.Abortable).abortTrigger!;
    await abort;
    aborted = true;
    throw http.RequestAbortedException(request.url);
  }
}

final class FakeUploads implements UploadGateway {
  int authorizations = 0, transfers = 0, finalizations = 0;
  bool failTransfer = false, corruptManifest = false;
  Completer<void>? hold;
  @override
  Future<UploadAuthorization> authorize(UploadBundle bundle) async {
    authorizations++;
    expect(bundle.deviceToken, 'test-device-grant');
    await hold?.future;
    return const UploadAuthorization();
  }

  @override
  Future<void> upload(UploadAuthorization authorization, File file) async {
    transfers++;
    if (failTransfer) throw StateError('offline');
  }

  @override
  Future<TrialFile> finalize(UploadBundle bundle) async {
    finalizations++;
    return TrialFile.fromJson({
      ...bundle.file.toJson(),
      'sync_status': 'synced',
      'uploaded_at': DateTime.now().toUtc().toIso8601String(),
      if (corruptManifest) 'sha256': '0' * 64,
    });
  }
}

void main() {
  late Directory directory;
  late LocalDatabase db;
  late Enrollment enrollment;
  late PinnedSession session;
  late PhysicalDevice device;
  late LocalTrialCapture capture;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('collector-db-');
    db = PausingSessionDatabase(
      NativeDatabase(File('${directory.path}/state.sqlite')),
    );
    enrollment = DemoEnrollmentGateway(
      asJson(
        jsonDecode(
          File('../../protocols/example_protocol.json').readAsStringSync(),
        ),
      ),
    ).enrollment;
    final definition = ProtocolDefinition.fromJson(enrollment.version.document)
        .sessions
        .single;
    session = (await LocalSessionStore(db).open(enrollment, definition)).$1;
    device = await db.getOrCreateDevice(testDevice);
    capture = LocalTrialCapture(
      recorder: FileRecorder(directory),
      database: db,
      device: device,
    )..prepareSession(session);
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  Future<void> record() async {
    await capture.start(session.queue.first, Hand.right);
    await capture.stop();
    await capture.save();
  }

  Future<void> grant() => db.customStatement(
    'INSERT INTO enrollment_grants (participant_id, device_token) VALUES (?, ?)',
    [enrollment.participant.id, 'test-device-grant'],
  );

  test('abort during session lookup prevents a later native start', () async {
    final paused = db as PausingSessionDatabase;
    paused.sessionRead = Completer<void>();
    paused.releaseRead = Completer<void>();
    final recorder = capture.recorder as FileRecorder;
    final starting = capture.start(session.queue.first, Hand.right);
    final rejected = expectLater(starting, throwsStateError);
    await paused.sessionRead!.future;
    await capture.abort();
    paused.releaseRead!.complete();
    await rejected;
    expect(recorder.starts, 0);
    expect(recorder.active, isNull);
  });

  test(
    'failed native start acknowledgement aborts any opened attempt',
    () async {
      final recorder = capture.recorder as FileRecorder;
      recorder.failStart = true;
      await expectLater(
        capture.start(session.queue.first, Hand.right),
        throwsStateError,
      );
      expect(recorder.active, isNull);
      recorder.failStart = false;
      await capture.start(session.queue.first, Hand.right);
      expect(recorder.active, session.queue.first.id);
      await capture.abort();
    },
  );

  test(
    'truncated closed file cannot advance a session or enter sync queue',
    () async {
      final id = session.queue.first.id;
      await capture.start(session.queue.first, Hand.right);
      await capture.checkRecording();
      await capture.stop();
      final raw = File('${directory.path}/$id.csv');
      final lines = await raw.readAsLines();
      await raw.writeAsString('${lines.take(2).join('\n')}\n', flush: true);
      await expectLater(capture.save(), throwsFormatException);
      expect((await db.loadSession(session.session.id)).$2, 0);
      expect(await db.select(db.storedTrials).get(), isEmpty);
      expect(await db.select(db.syncQueue).get(), isEmpty);
      expect(await raw.exists(), isTrue);
      expect(await File('${raw.path}.gz').exists(), isFalse);
      await capture.abort();
    },
  );

  test(
    'sync verifies bytes and remote manifest, persists retry across restart',
    () async {
      await record();
      await grant();
      var now = DateTime.now().toUtc().add(const Duration(seconds: 1));
      final uploads = FakeUploads()..failTransfer = true;
      var worker = SyncWorker(database: db, gateway: uploads, now: () => now);
      expect(await worker.runOnce(), isTrue);
      expect(uploads.finalizations, 0);
      expect((await db.select(db.syncQueue).get()).single.status, 'failed');
      expect(await worker.runOnce(), isFalse);
      await db.close();
      db = LocalDatabase(
        NativeDatabase(File('${directory.path}/state.sqlite')),
      );
      worker = SyncWorker(database: db, gateway: uploads, now: () => now);
      now = now.add(const Duration(seconds: 11));
      uploads.failTransfer = false;
      uploads.corruptManifest = true;
      await worker.runOnce();
      expect((await db.select(db.syncQueue).get()).single.status, 'failed');
      now = now.add(const Duration(seconds: 21));
      uploads.corruptManifest = false;
      await worker.runOnce();
      expect((await db.select(db.syncQueue).get()).single.status, 'synced');
      expect(await worker.runOnce(), isFalse);
      final row = (await db.select(db.storedTrials).get()).single;
      expect(await File(row.rawPath).exists(), isTrue);
      expect(await File(row.compressedPath).exists(), isTrue);
      expect(uploads.authorizations, 3);
    },
  );

  test(
    'sync timeout cancels the underlying HTTP request and retains the job',
    () async {
      await record();
      await grant();
      final client = StalledUploadClient();
      final gateway = RemoteUploadGateway(
        endpoint: Uri.parse('https://example.test/collector'),
        publicKey: 'public',
        client: client,
        requestTimeout: const Duration(milliseconds: 10),
      );
      await SyncWorker(
        database: db,
        gateway: gateway,
        now: () => DateTime.now().toUtc().add(const Duration(seconds: 1)),
      ).runOnce();
      expect(client.aborted, isTrue);
      expect((await db.select(db.syncQueue).get()).single.status, 'failed');
      expect(
        await File(
          (await db.select(db.storedTrials).get()).single.compressedPath,
        ).exists(),
        isTrue,
      );
      client.close();
    },
  );

  test('corrupt local bytes never reach the network', () async {
    await record();
    await grant();
    final row = (await db.select(db.storedTrials).get()).single;
    await File(row.compressedPath).writeAsBytes([0]);
    final uploads = FakeUploads();
    await SyncWorker(
      database: db,
      gateway: uploads,
      now: () => DateTime.now().toUtc().add(const Duration(seconds: 1)),
    ).runOnce();
    expect(uploads.authorizations, 0);
    expect((await db.select(db.syncQueue).get()).single.status, 'failed');
  });

  test(
    'scheduler pauses claims, avoids duplicate workers and drains before close',
    () async {
      await record();
      await grant();
      final uploads = FakeUploads()..hold = Completer<void>();
      var allowed = false;
      final scheduler = SyncScheduler(
        SyncWorker(
          database: db,
          gateway: uploads,
          now: () => DateTime.now().toUtc().add(const Duration(seconds: 1)),
        ),
        canRun: () => allowed,
      )..start();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(uploads.authorizations, 0);
      allowed = true;
      scheduler.kick();
      for (var i = 0; i < 100 && uploads.authorizations == 0; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(uploads.authorizations, 1);
      scheduler.kick();
      var stopped = false;
      final stopping = scheduler.stop().then((_) => stopped = true);
      await Future<void>.delayed(Duration.zero);
      expect(stopped, isFalse);
      uploads.hold!.complete();
      await stopping;
      expect(uploads.authorizations, 1);
      expect((await db.select(db.syncQueue).get()).single.status, 'synced');
    },
  );

  test('HTTP sync renews expired authorization and verifies conditional retry', () async {
    await record();
    await grant();
    final row = (await db.select(db.storedTrials).get()).single;
    final manifest = asJson(jsonDecode(row.filePayload));
    var puts = 0, prepares = 0, finalizes = 0;
    var now = DateTime.now().toUtc().add(const Duration(seconds: 1));
    final client = MockClient((request) async {
      if (request.method == 'PUT') {
        puts++;
        expect(request.followRedirects, isFalse);
        expect(request.headers['authorization'], isNull);
        expect(request.headers['if-none-match'], '*');
        expect(request.bodyBytes, await File(row.compressedPath).readAsBytes());
        return http.Response('', puts == 1 ? 403 : 412);
      }
      expect(request.headers['authorization'], 'Bearer test-device-grant');
      final body = asJson(jsonDecode(request.body));
      if (body['action'] == 'prepare_upload') {
        prepares++;
        return http.Response(
          jsonEncode({
            'manifest': {...manifest, 'sync_status': 'uploading'},
            'upload_required': true,
            'url':
                'https://account.r2.cloudflarestorage.com/bucket/${manifest['object_key']}?attempt=$prepares',
            'headers': {
              'content-type': 'application/gzip',
              'content-length': '${manifest['size_bytes']}',
              'if-none-match': '*',
            },
          }),
          200,
        );
      }
      finalizes++;
      return http.Response(
        jsonEncode({
          'verified': true,
          'manifest': {
            ...manifest,
            'sync_status': 'synced',
            'uploaded_at': now.toIso8601String(),
          },
        }),
        200,
      );
    });
    final worker = SyncWorker(
      database: db,
      now: () => now,
      gateway: RemoteUploadGateway(
        endpoint: Uri.parse('https://example.test/collector'),
        publicKey: 'public',
        client: client,
      ),
    );
    await worker.runOnce();
    expect(finalizes, 0);
    now = now.add(const Duration(seconds: 11));
    await worker.runOnce();
    expect(prepares, 2);
    expect(finalizes, 1);
    expect((await db.select(db.syncQueue).get()).single.status, 'synced');
    client.close();
  });

  test(
    'closed trial and files survive restart with pinned progress and queue',
    () async {
      await record();
      final row = (await db.select(db.storedTrials).get()).single;
      expect((await db.loadSession(session.session.id)).$2, 1);
      expect((await db.select(db.syncQueue).get()).single.status, 'local');
      await db.close();
      db = LocalDatabase(
        NativeDatabase(File('${directory.path}/state.sqlite')),
      );
      final restored = await LocalSessionStore(db).open(
        enrollment,
        ProtocolDefinition.fromJson(enrollment.version.document)
            .sessions
            .single,
      );
      expect(restored.$1.toJson(), session.toJson());
      expect(restored.$2, 1);
      expect((await db.getOrCreateDevice(testDevice)).id, device.id);
      expect(
        await checksumFile(File(row.compressedPath)),
        TrialFile.fromJson(asJson(jsonDecode(row.filePayload))).sha256,
      );
      await db.recoverPending(DateTime.now().toUtc());
      expect((await db.select(db.syncQueue).get()).single.status, 'queued');
      expect(await File(row.rawPath).exists(), isTrue);
    },
  );

  test(
    'durable leases retry after expiry and reject stale finalization',
    () async {
      await record();
      final now = DateTime.now().toUtc().add(const Duration(seconds: 1));
      final first = (await db.claimUpload(now))!;
      expect(await db.claimUpload(now), isNull);
      final later = now.add(const Duration(minutes: 16));
      final second = (await db.claimUpload(later))!;
      expect(second.attempts, 2);
      await expectLater(
        db.finishUpload(
          first.trialId,
          attempt: first.attempts,
          now: later,
          verified: true,
        ),
        throwsStateError,
      );
      await db.finishUpload(
        second.trialId,
        attempt: second.attempts,
        now: later,
        verified: false,
        errorCode: 'network_unavailable',
      );
      expect(await db.claimUpload(later), isNull);
      final third = (await db.claimUpload(
        later.add(const Duration(seconds: 30)),
      ))!;
      await db.finishUpload(
        third.trialId,
        attempt: third.attempts,
        now: later.add(const Duration(seconds: 31)),
        verified: true,
      );
      expect(await db.claimUpload(later.add(const Duration(days: 1))), isNull);
      expect((await db.select(db.syncQueue).get()).single.status, 'synced');
      expect(
        await File(
          (await db.select(db.storedTrials).get()).single.compressedPath,
        ).exists(),
        isTrue,
      );
    },
  );

  test('failed local commit never advances session or queues data', () async {
    await capture.start(session.queue.first, Hand.right);
    await capture.stop();
    await db.customStatement(
      "CREATE TRIGGER fail_trial BEFORE INSERT ON stored_trials BEGIN SELECT RAISE(ABORT, 'simulated full disk'); END",
    );
    await expectLater(capture.save(), throwsA(anything));
    expect((await db.loadSession(session.session.id)).$2, 0);
    expect(await db.select(db.syncQueue).get(), isEmpty);
    expect(await db.select(db.storedTrials).get(), isEmpty);
    expect(
      directory.listSync().whereType<File>().where(
        (f) => f.path.endsWith('.csv.gz'),
      ),
      hasLength(1),
    );
  });

  test('safe save is idempotent and rejects altered bytes', () async {
    await record();
    final row = (await db.select(db.storedTrials).get()).single;
    final trial = Trial.fromJson(asJson(jsonDecode(row.payload)));
    final file = TrialFile.fromJson(asJson(jsonDecode(row.filePayload)));
    final finalized = await finalizeRawFile(
      File(row.rawPath),
      requestedRates: {SensorType.accelerometer: 100},
    );
    await db.saveTrial(
      trial: trial,
      file: file,
      finalized: finalized,
      rawPath: row.rawPath,
    );
    expect(await db.select(db.syncQueue).get(), hasLength(1));
    await File(row.compressedPath).writeAsBytes([0]);
    await expectLater(
      db.saveTrial(
        trial: trial,
        file: file,
        finalized: finalized,
        rawPath: row.rawPath,
      ),
      throwsStateError,
    );
    expect((await db.loadSession(session.session.id)).$2, 1);
  });

  test('device refresh and restart keep installation identity', () async {
    final initial = await DeviceRegistration(
      db,
      FileRecorder(directory),
    ).register(requestedHz: 50);
    expect(initial.id, device.id);
    expect(initial.model, 'Test phone');
    expect(initial.sensors.single.requestedHz, 50);
    await db.close();
    db = LocalDatabase(NativeDatabase(File('${directory.path}/state.sqlite')));
    final updated = await DeviceRegistration(
      db,
      FileRecorder(directory),
    ).register(requestedHz: 100);
    expect(updated.id, initial.id);
    expect(updated.createdAt, initial.createdAt);
    expect(updated.sensors.single.requestedHz, 100);
    await db.close();
    db = LocalDatabase(NativeDatabase.memory());
    final reinstalled = await DeviceRegistration(
      db,
      FileRecorder(directory),
    ).register();
    expect(reinstalled.id, isNot(initial.id));
  });

  test('published cache refuses mutation under one UUID', () async {
    final changed = enrollment.version.toJson()..['version'] = 2;
    await expectLater(
      db.cacheProtocol(ProtocolVersion.fromJson(changed)),
      throwsStateError,
    );
    expect((await db.protocol(enrollment.version.id))!.version, 1);
  });

  test('schema v1 upgrade preserves saved records and pending jobs', () async {
    await record();
    // Exact v1 difference: sync_queue did not yet contain last_error.
    await db.customStatement('ALTER TABLE sync_queue DROP COLUMN last_error');
    await db.customStatement('DROP TABLE saved_enrollment');
    await db.customStatement('DROP TABLE enrollment_grants');
    await db.customStatement('PRAGMA user_version = 1');
    await db.close();
    db = LocalDatabase(NativeDatabase(File('${directory.path}/state.sqlite')));
    expect((await db.loadSession(session.session.id)).$2, 1);
    final job = (await db.claimUpload(
      DateTime.now().toUtc().add(const Duration(seconds: 1)),
    ))!;
    expect(job.lastError, isNull);
    expect(job.attempts, 1);
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
  });
}

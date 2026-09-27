import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collector_mobile/collection/services.dart';
import 'package:collector_mobile/storage/session_store.dart';
import 'package:protocol_engine/protocol_engine.dart';
import 'package:collector_mobile/enrollment/remote_enrollment.dart';
import 'package:collector_mobile/storage/local_database.dart'
    show LocalDatabase;
import 'package:drift/native.dart';
import 'package:experiment_models/experiment_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'local_storage_test.dart' show testDevice;

final class EnrollmentDeadlineClient extends http.BaseClient {
  final Enrollment enrollment;
  final bool stallBody;
  bool stall = false;
  int aborted = 0;
  EnrollmentDeadlineClient(this.enrollment, {required this.stallBody});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    expect(request.followRedirects, isFalse);
    final body = asJson(jsonDecode(await request.finalize().bytesToString()));
    if (body['action'] == 'refresh')
      expect(request.headers['authorization'], 'Bearer ${'a' * 64}');
    if (stall) {
      final abort = (request as http.Abortable).abortTrigger!;
      final response = abort.then<List<int>>((_) {
        aborted++;
        throw http.RequestAbortedException(request.url);
      });
      if (stallBody)
        return http.StreamedResponse(Stream.fromFuture(response), 200);
      await response;
      throw StateError('Unreachable');
    }
    return http.StreamedResponse(
      Stream.value(
        utf8.encode(
          jsonEncode({
            ...enrollment.toJson(),
            if (body['action'] == 'enroll') 'device_token': 'a' * 64,
          }),
        ),
      ),
      200,
    );
  }
}

void main() {
  for (final stallBody in [false, true]) {
    test(
      'enrollment and refresh cancel stalled ${stallBody ? 'bodies' : 'headers'} without losing offline state',
      () async {
        final db = LocalDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final enrollment = DemoEnrollmentGateway(
          asJson(
            jsonDecode(
              File('../../protocols/example_protocol.json').readAsStringSync(),
            ),
          ),
        ).enrollment;
        final client = EnrollmentDeadlineClient(
          enrollment,
          stallBody: stallBody,
        );
        addTearDown(client.close);
        final gateway = RemoteEnrollmentGateway(
          database: db,
          device: testDevice(),
          endpoint: Uri.parse('https://example.invalid/collector'),
          publicKey: 'public',
          client: client,
          requestTimeout: const Duration(milliseconds: 50),
        );
        await gateway.enroll('ABCD234567');
        final saved = (await db.select(db.savedEnrollment).get()).single;
        client.stall = true;
        final timeout = throwsA(
          anyOf(isA<TimeoutException>(), isA<http.RequestAbortedException>()),
        );
        await expectLater(gateway.enroll('ANOTHER'), timeout);
        await expectLater(gateway.refresh(), timeout);
        expect(client.aborted, 2);
        expect((await gateway.resume()).toJson(), enrollment.toJson());
        expect(gateway.deviceToken, 'a' * 64);
        expect((await db.select(db.savedEnrollment).get()).single, saved);
        expect(
          (await db.select(db.enrollmentGrants).get()).single.deviceToken,
          'a' * 64,
        );
        client.stall = false;
        expect((await gateway.refresh()).version.id, enrollment.version.id);
      },
    );
  }
  test('central enrollment identity is cached for offline restart without storing the code', () async {
    final directory = await Directory.systemTemp.createTemp('enrollment-');
    var db = LocalDatabase(
      NativeDatabase(File('${directory.path}/state.sqlite')),
    );
    final enrollment = DemoEnrollmentGateway(
      asJson(
        jsonDecode(
          File('../../protocols/example_protocol.json').readAsStringSync(),
        ),
      ),
    ).enrollment;
    final device = testDevice();
    final online = MockClient((request) async {
      final body = asJson(jsonDecode(request.body));
      expect(body['credential'], 'ABCD234567');
      expect(asJson(body['device'])['id'], device.id);
      return http.Response(
        jsonEncode({...enrollment.toJson(), 'device_token': 'a' * 64}),
        200,
      );
    });
    final gateway = RemoteEnrollmentGateway(
      database: db,
      device: device,
      endpoint: Uri.parse('https://example.invalid/collector'),
      publicKey: 'public',
      client: online,
    );
    try {
      await gateway.initialize();
      expect(gateway.hasSavedEnrollment, isFalse);
      expect(
        (await gateway.enroll('ABCD234567')).participant.id,
        enrollment.participant.id,
      );
      final stored = (await db.select(db.savedEnrollment).get()).single;
      expect(stored.payload.contains('ABCD234567'), isFalse);
      await db.close();
      db = LocalDatabase(
        NativeDatabase(File('${directory.path}/state.sqlite')),
      );
      final restored = RemoteEnrollmentGateway(
        database: db,
        device: device,
        endpoint: null,
        publicKey: null,
        client: MockClient((_) async => throw StateError('offline')),
      );
      await restored.initialize();
      expect(
        (await restored.resume()).participant.id,
        enrollment.participant.id,
      );
      expect(restored.deviceToken, 'a' * 64);
      await expectLater(restored.enroll('WRONG'), throwsStateError);
      expect(
        (await restored.resume()).participant.id,
        enrollment.participant.id,
      );
    } finally {
      await db.close();
      await directory.delete(recursive: true);
    }
  });
  test('refresh preserves removed in-progress session definitions and version after restart', () async {
    final directory = await Directory.systemTemp.createTemp('protocol-cache-');
    var db = LocalDatabase(
      NativeDatabase(File('${directory.path}/state.sqlite')),
    );
    final old = DemoEnrollmentGateway(
      asJson(
        jsonDecode(
          File('../../protocols/example_protocol.json').readAsStringSync(),
        ),
      ),
    ).enrollment;
    final document = asJson(jsonDecode(jsonEncode(old.version.document)));
    asJson((document['sessions'] as List).single)['id'] = newUuid();
    final updated = Enrollment(
      old.study,
      old.participant,
      old.protocol,
      publishVersion(
        duplicateVersion(
          old.version,
          nextVersion: 2,
          now: DateTime.now().toUtc(),
        ),
        DateTime.now().toUtc(),
      ),
    );
    final removed = Enrollment(
      updated.study,
      updated.participant,
      updated.protocol,
      publishVersion(
        editDraft(
          duplicateVersion(
            old.version,
            nextVersion: 2,
            now: DateTime.now().toUtc(),
          ),
          document,
        ),
        DateTime.now().toUtc(),
      ),
    );
    final client = MockClient(
      (request) async => http.Response(
        jsonEncode(
          asJson(jsonDecode(request.body))['action'] == 'enroll'
              ? {...old.toJson(), 'device_token': 'a' * 64}
              : removed.toJson(),
        ),
        200,
      ),
    );
    final gateway = RemoteEnrollmentGateway(
      database: db,
      device: testDevice(),
      endpoint: Uri.parse('https://example.invalid/collector'),
      publicKey: 'public',
      client: client,
    );
    try {
      await gateway.enroll('ABCD234567');
      final originalDefinition = ProtocolDefinition.fromJson(
        old.version.document,
      ).sessions.single;
      final pinned = (await LocalSessionStore(
        db,
      ).open(old, originalDefinition)).$1;
      final refreshed = await gateway.refresh();
      expect(refreshed.version.version, 2);
      final definitions = await LocalSessionStore(db).definitions(refreshed);
      expect(definitions.map((s) => s.id), contains(originalDefinition.id));
      expect(
        (await LocalSessionStore(
          db,
        ).open(refreshed, originalDefinition)).$1.version.id,
        pinned.version.id,
      );
      await db.close();
      db = LocalDatabase(
        NativeDatabase(File('${directory.path}/state.sqlite')),
      );
      final offline = RemoteEnrollmentGateway(
        database: db,
        device: testDevice(),
        endpoint: null,
        publicKey: null,
      );
      await offline.initialize();
      expect((await offline.resume()).version.id, removed.version.id);
      expect(
        (await LocalSessionStore(
          db,
        ).open(await offline.resume(), originalDefinition)).$1.queue.first.id,
        pinned.queue.first.id,
      );
      await expectLater(offline.refresh(), throwsStateError);
      expect((await offline.resume()).version.id, removed.version.id);
    } finally {
      await db.close();
      await directory.delete(recursive: true);
    }
  });
}

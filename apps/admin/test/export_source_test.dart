import 'dart:async';

import 'package:collector_admin/export/bundle.dart';
import 'package:collector_admin/export/source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'readable_export_test.dart' show verifiedFixture;

class StreamClient extends http.BaseClient {
  final Stream<List<int>> body;
  bool closed = false;
  StreamClient(this.body);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(body, 200);
  @override
  void close() {
    closed = true;
  }
}

class StalledClient extends http.BaseClient {
  bool aborted = false, closed = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    await (request as http.AbortableRequest).abortTrigger;
    aborted = true;
    throw http.RequestAbortedException(request.url);
  }

  @override
  void close() {
    closed = true;
  }
}

void main() {
  test(
    'stalled download times out and cancels its underlying request',
    () async {
      final client = StalledClient();
      final source = AuthorizedExportSource(
        (_) async => 'https://example.test/file',
        clientFactory: () => client,
        timeout: const Duration(milliseconds: 10),
      );
      await expectLater(
        source.read(ExportPlan(verifiedFixture()).entries.single),
        throwsA(isA<TimeoutException>()),
      );
      await Future<void>.delayed(Duration.zero);
      expect(client.closed, isTrue);
      expect(client.aborted, isTrue);
    },
  );
  test(
    'authorization happens per file and denial prevents raw request',
    () async {
      final entry = ExportPlan(verifiedFixture()).entries.single;
      var auths = 0, reads = 0;
      final source = AuthorizedExportSource(
        (trial) async {
          expect(trial, entry.trial.id);
          auths++;
          return 'https://example.test/file';
        },
        clientFactory: () => MockClient((request) async {
          reads++;
          expect(request.followRedirects, isFalse);
          return http.Response.bytes([1, 2, 3], 200);
        }),
      );
      await source.read(entry);
      await source.read(entry);
      expect(auths, 2);
      expect(reads, 2);
      final denied = AuthorizedExportSource(
        (_) async => throw StateError('denied'),
        clientFactory: () {
          fail('Must not fetch before authorization');
        },
      );
      await expectLater(denied.read(entry), throwsStateError);
    },
  );
  test('expired URLs and oversized response bodies fail closed', () async {
    final entry = ExportPlan(verifiedFixture()).entries.single;
    final expired = AuthorizedExportSource(
      (_) async => 'https://example.test/file',
      clientFactory: () =>
          MockClient((_) async => http.Response('expired', 403)),
    );
    await expectLater(expired.read(entry), throwsStateError);
    final client = StreamClient(Stream.value([1, 2, 3, 4]));
    final oversize = AuthorizedExportSource(
      (_) async => 'https://example.test/file',
      clientFactory: () => client,
    );
    await expectLater(oversize.read(entry), throwsStateError);
    expect(client.closed, isTrue);
  });
}

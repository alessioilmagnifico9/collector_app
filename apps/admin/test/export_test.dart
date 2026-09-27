import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:collector_admin/export/bundle.dart';

import 'package:collector_admin/dashboard/repository.dart';
import 'package:collector_admin/export/metadata.dart';
import 'package:collector_admin/export/export_screen.dart';
import 'package:experiment_models/experiment_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test.dart' show datasetFixture, FakeDashboard;

class Downloads implements RawDownloadRepository {
  @override
  Future<String> authorize(String trialId) async => 'https://example.test/raw';
}

void main() {
  test(
    'metadata is deterministic, contains versions and excludes credentials',
    () {
      final data = datasetFixture();
      final expected = exportMetadata(data);
      final changed = asJson(jsonDecode(jsonEncode(data.document)));
      (changed['participants'] as List).first['device_token'] = 'do-not-export';
      changed['enrollment_credentials'] = [
        {'code': 'do-not-export'},
      ];
      final reordered = <String, Object?>{
        for (final key in changed.keys.toList().reversed) key: changed[key],
      };
      expect(exportMetadata(StudyDataset(reordered)), expected);
      final result = asJson(jsonDecode(expected));
      expect(result['export_schema_version'], 1);
      expect((result['protocol_versions'] as List), hasLength(1));
      expect((result['trials'] as List).first['schema_version'], 1);
      expect(expected, isNot(contains('do-not-export')));
      expect(expected, isNot(contains('download_url')));
    },
  );
  testWidgets('export saves a snapshot and enables verified raw downloads', (
    tester,
  ) async {
    final data = datasetFixture();
    final files = data.document['trial_files'] as List;
    files.first['sync_status'] = 'synced';
    files.first['uploaded_at'] = DateTime.utc(2026).toIso8601String();
    String? saved;
    Uint8List? archive;
    files.first['sha256'] = sha256.convert([1, 2, 3]).toString();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DatasetExportScreen(
            study: Study.fromJson(asJson(data.document['study'])),
            repository: FakeDashboard(data),
            downloads: Downloads(),
            save: (text, name) {
              saved = text;
              expect(name, endsWith('-metadata.json'));
            },
            source: FakeSource(),
            saveBundle: (bytes, name) => archive = bytes,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 verified raw files'), findsOneWidget);
    expect(saved, isNull);
    await tester.tap(find.text('Export metadata JSON'));
    await tester.pumpAndSettle();
    expect(saved, exportMetadata(data));
    expect(find.text('1 verified raw files'), findsOneWidget);
    await tester.tap(find.byTooltip('Download verified raw file'));
    await tester.pumpAndSettle();
    expect(archive, isNotNull);
    expect(archive!.take(2), [0x50, 0x4b]);
  });
}

class FakeSource implements ExportSource {
  bool fail = false;
  @override
  Future<Uint8List> read(ExportEntry entry) async {
    if (fail) throw StateError('denied');
    return Uint8List.fromList([1, 2, 3]);
  }
}

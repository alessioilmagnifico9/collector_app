import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:experiment_models/experiment_models.dart';

import '../dashboard/repository.dart';
import 'metadata.dart';

const maxArchiveBytes = 32 * 1024 * 1024;
const maxArchiveFiles = 200;

/// Portable folder label; the manifest retains the stable study identity.
String studyExportFolder(String name, String id) {
  var label = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]+'), '-');
  label = label.replaceAll(RegExp(r'^[-_]+|[-_]+$'), '');
  if (label.length > 80) label = label.substring(0, 80);
  if (label.isEmpty) return 'study-$id';
  if (RegExp(r'^(con|prn|aux|nul|com[0-9]|lpt[0-9])$').hasMatch(label)) {
    label = 'study-$label';
  }
  return label;
}

final class ExportEntry {
  final TrialFile file;
  final Trial trial;
  final String path;
  final int protocolVersion;
  ExportEntry(this.file, this.trial, this.path, this.protocolVersion);
  Json toJson() => {
    'path': path,
    'study_id': trial.studyId,
    'participant_id': trial.participantId,
    'session_id': trial.sessionId,
    'trial_id': trial.id,
    'physical_device_id': trial.physicalDeviceId,
    'protocol_version_id': trial.protocolVersionId,
    'protocol_version': protocolVersion,
    'schema_version': trial.schemaVersion,
    'object_key': file.objectKey,
    'size_bytes': file.sizeBytes,
    'sha256': file.sha256,
  };
}

final class ExportPlan {
  final StudyDataset snapshot;
  late final Map<String, Trial> _trials = {
    for (final t in snapshot.trials) t.id: t,
  };
  late final String metadata = exportMetadata(snapshot);
  late final List<ExportEntry> entries = List.unmodifiable(
    (snapshot.files.where((f) => f.syncStatus == SyncStatus.synced).map((file) {
      final trial = _trials[file.trialId]!;
      return ExportEntry(
        file,
        trial,
        '${studyExportFolder(stringField(asJson(snapshot.document['study']), 'name'), trial.studyId)}/${snapshot.names.exportPath(trial).split('/').skip(1).join('/')}',
        snapshot.names.version(trial.protocolVersionId).version,
      );
    }).toList()..sort((a, b) => a.path.compareTo(b.path))),
  );
  ExportPlan(StudyDataset data)
    : snapshot = StudyDataset(asJson(freezeJson(data.document)));
  String manifest(List<ExportEntry> selected) => jsonEncode(
    canonical({
      'manifest_version': 1,
      'metadata_sha256': sha256.convert(utf8.encode(metadata)).toString(),
      'files': selected.map((e) => e.toJson()).toList(),
    }),
  );
  String get streamingPlan => jsonEncode({
    'metadata_json': metadata,
    'manifest': jsonDecode(manifest(entries)),
  });
  late final List<List<ExportEntry>> parts = _parts();
  List<List<ExportEntry>> _parts() {
    final result = <List<ExportEntry>>[];
    var current = <ExportEntry>[];
    var size = 0;
    for (final entry in entries.where(
      (e) => e.file.sizeBytes <= maxArchiveBytes,
    )) {
      if (current.isNotEmpty &&
          (size + entry.file.sizeBytes > maxArchiveBytes ||
              current.length >= maxArchiveFiles)) {
        result.add(List.unmodifiable(current));
        current = [];
        size = 0;
      }
      current.add(entry);
      size += entry.file.sizeBytes;
    }
    if (current.isNotEmpty) result.add(List.unmodifiable(current));
    return List.unmodifiable(result);
  }
}

abstract interface class ExportSource {
  /// Must authorize at time of download, enforce the supplied byte limit,
  /// and cancel requests on timeout. Signed links must never enter the manifest.
  Future<Uint8List> read(ExportEntry entry);
}

final class BundleResult {
  final Uint8List bytes;
  final int saved;
  final List<String> failed;
  BundleResult(this.bytes, this.saved, this.failed);
}

Future<BundleResult> buildBundle(
  ExportPlan plan,
  List<ExportEntry> selected,
  ExportSource source,
) async {
  if (selected.map((e) => e.path).toSet().length != selected.length ||
      selected.length > maxArchiveFiles ||
      selected.fold<int>(0, (n, e) => n + e.file.sizeBytes) > maxArchiveBytes ||
      selected.any((e) => !plan.entries.contains(e))) {
    throw StateError('Selection exceeds browser archive limits');
  }
  final output = <String, Uint8List>{};
  final failed = <String>[];
  for (final entry in selected) {
    try {
      final bytes = await source.read(entry);
      if (bytes.length != entry.file.sizeBytes ||
          sha256.convert(bytes).toString() != entry.file.sha256) {
        throw StateError('File integrity check failed');
      }
      output[entry.path] = bytes;
    } catch (_) {
      failed.add(entry.path);
    }
  }
  final saved = output.length;
  output['metadata.json'] = Uint8List.fromList(utf8.encode(plan.metadata));
  output['manifest.json'] = Uint8List.fromList(
    utf8.encode(plan.manifest(selected)),
  );
  output['export-report.json'] = Uint8List.fromList(
    utf8.encode(
      jsonEncode({
        'complete': failed.isEmpty,
        'saved': saved,
        'selected': selected.length,
        'failed_paths': failed,
        'scope': 'This archive part only. The manifest lists every selected file, including failures.',
      }),
    ),
  );
  return BundleResult(storedZip(output), saved, List.unmodifiable(failed));
}

/// ZIP STORE preserves the exact compressed sensor bytes. Bounded archive parts
/// keep offsets well below ZIP32 limits. Names are ASCII generated paths only.
Uint8List storedZip(Map<String, Uint8List> files) {
  final output = BytesBuilder(copy: false);
  final directory = BytesBuilder(copy: false);
  final crcTable = List<int>.generate(256, (value) {
    var crc = value;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc >>> 1) ^ ((crc & 1) != 0 ? 0xedb88320 : 0);
    }
    return crc;
  });
  void u16(BytesBuilder b, int v) =>
      b.add((ByteData(2)..setUint16(0, v, Endian.little)).buffer.asUint8List());
  void u32(BytesBuilder b, int v) =>
      b.add((ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List());
  for (final entry in files.entries) {
    final name = utf8.encode(entry.key);
    final data = entry.value;
    final offset = output.length;
    var crc = 0xffffffff;
    for (final byte in data) {
      crc = crcTable[(crc ^ byte) & 0xff] ^ (crc >>> 8);
    }
    crc = (crc ^ 0xffffffff) & 0xffffffff;
    u32(output, 0x04034b50);
    u16(output, 20);
    u16(output, 0);
    u16(output, 0);
    u16(output, 0);
    u16(output, 33);
    u32(output, crc);
    u32(output, data.length);
    u32(output, data.length);
    u16(output, name.length);
    u16(output, 0);
    output.add(name);
    output.add(data);
    u32(directory, 0x02014b50);
    u16(directory, 20);
    u16(directory, 20);
    u16(directory, 0);
    u16(directory, 0);
    u16(directory, 0);
    u16(directory, 33);
    u32(directory, crc);
    u32(directory, data.length);
    u32(directory, data.length);
    u16(directory, name.length);
    u16(directory, 0);
    u16(directory, 0);
    u16(directory, 0);
    u16(directory, 0);
    u32(directory, 0);
    u32(directory, offset);
    directory.add(name);
  }
  final offset = output.length;
  final length = directory.length;
  output.add(directory.takeBytes());
  u32(output, 0x06054b50);
  u16(output, 0);
  u16(output, 0);
  u16(output, files.length);
  u16(output, files.length);
  u32(output, length);
  u32(output, offset);
  u16(output, 0);
  return output.takeBytes();
}

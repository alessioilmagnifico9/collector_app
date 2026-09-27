import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:experiment_models/experiment_models.dart';

import 'dataset_schema.dart';
import 'quality.dart';

Future<String> checksumFile(File file) async =>
    (await sha256.bind(file.openRead()).first).toString();

final class FinalizedFile {
  final String path, sha256;
  final int sizeBytes;
  final QualitySummary quality;
  const FinalizedFile({
    required this.path,
    required this.sha256,
    required this.sizeBytes,
    required this.quality,
  });
}

/// Native file closure is a prerequisite. This has no network dependencies.
Future<FinalizedFile> finalizeRawFile(
  File raw, {
  Map<SensorType, double> requestedRates = const {},
  int? expectedSampleCount,
}) async {
  if (expectedSampleCount != null)
    requirePositive(expectedSampleCount, 'expected_sample_count');
  if (!raw.path.endsWith('.csv'))
    throw const FormatException(
      'Only safely closed .csv files can be finalized.',
    );
  final size = await raw.length();
  if (size == 0 || size > 512 * 1024 * 1024)
    throw const FormatException('Invalid raw file size.');
  final handle = await raw.open();
  try {
    await handle.setPosition(size - 1);
    if (await handle.readByte() != 10)
      throw const FormatException('Raw file has an incomplete final row.');
  } finally {
    await handle.close();
  }
  final metrics = QualityAccumulator(requestedRates: requestedRates);
  var lineNumber = 0;
  await for (final line
      in raw
          .openRead()
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
    lineNumber++;
    if (lineNumber == 1) {
      if (line != rawCsvHeader)
        throw const FormatException('Unsupported raw CSV header.');
      continue;
    }
    if (line.length > 4096)
      throw FormatException('Oversized sample at line $lineNumber.');
    try {
      metrics.add(SensorSample.fromCsv(line));
    } on FormatException catch (e) {
      throw FormatException('Raw line $lineNumber: ${e.message}');
    }
  }
  if (expectedSampleCount != null && lineNumber - 1 != expectedSampleCount)
    throw const FormatException(
      'Raw sample count differs from the native closed recording.',
    );
  final quality = metrics.finish();
  if (quality.durationSeconds > 601)
    throw const FormatException(
      'Trial exceeds the native recording safety limit.',
    );
  final compressed = File('${raw.path}.gz');
  if (await compressed.exists()) {
    final decompressedHash =
        (await sha256.bind(compressed.openRead().transform(gzip.decoder)).first)
            .toString();
    if (decompressedHash != await checksumFile(raw))
      throw const FormatException(
        'Existing compressed file differs from raw data.',
      );
  } else {
    final temporary = File('${compressed.path}.${newUuid()}.partial');
    final sink = temporary.openWrite();
    try {
      await raw.openRead().transform(gzip.encoder).pipe(sink);
      final output = await temporary.open(mode: FileMode.append);
      try {
        await output.flush();
      } finally {
        await output.close();
      }
      await temporary.rename(compressed.path);
    } catch (_) {
      await sink.close();
      // Preserve raw and temporary bytes for recovery after I/O failure.
      rethrow;
    }
  }
  return FinalizedFile(
    path: compressed.path,
    sha256: await checksumFile(compressed),
    sizeBytes: await compressed.length(),
    quality: quality,
  );
}

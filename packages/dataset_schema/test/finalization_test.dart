import 'dart:convert';
import 'dart:io';

import 'package:dataset_schema/dataset_schema.dart';
import 'package:dataset_schema/finalization.dart';
import 'package:dataset_schema/quality.dart';
import 'package:experiment_models/experiment_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('streaming metrics distinguish mean rate, interval jitter and estimated loss', () {
    final metrics = QualityAccumulator(
      requestedRates: {
        SensorType.accelerometer: 100,
        SensorType.gyroscope: 100,
      },
    );
    for (final timestamp in [0, 10000000, 30000000]) {
      metrics.add(
        SensorSample(
          timestampNs: BigInt.from(timestamp),
          sensorType: SensorType.accelerometer,
          x: 0,
          y: 0,
          z: 0,
        ),
      );
    }
    final quality = metrics.finish();
    final sensor = quality.sensors.first;
    expect(quality.durationSeconds, .03);
    expect(sensor.sampleCount, 3);
    expect(sensor.meanHz, closeTo(200 / 3, 1e-10));
    expect(sensor.stddevHz, 25);
    expect(sensor.meanIntervalNs, 15000000);
    expect(sensor.stddevIntervalNs, 5000000);
    expect(sensor.minIntervalNs, 10000000);
    expect(sensor.maxIntervalNs, 20000000);
    expect(sensor.estimatedMissing, 1);
    expect(quality.sensors[1].sampleCount, 0);
    expect(quality.sensors[1].meanHz, isNull);
    expect(quality.warnings, contains('gyroscope_insufficient_samples'));
  });
  test('single samples have undefined rates and duplicate timestamps fail', () {
    final metrics = QualityAccumulator();
    final sample = SensorSample.fromCsv('9007199254740993,gravity,0,0,1,,');
    metrics.add(sample);
    expect(metrics.finish().sensors.single.meanHz, isNull);
    expect(() => metrics.add(sample), throwsFormatException);
    expect(() => QualityAccumulator().finish(), throwsFormatException);
  });
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('collector-finalize-');
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });
  test('checksum matches known SHA-256 test vector', () async {
    final file = await File('${directory.path}/abc').writeAsString('abc');
    expect(
      await checksumFile(file),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });
  test('closed raw file compresses, verifies, and can finalize idempotently', () async {
    final text =
        '$rawCsvHeader\n1,accelerometer,0,1,2,,\n10000001,accelerometer,0,1,2,,\n';
    final raw = await File('${directory.path}/trial.csv')
        .writeAsString(text, flush: true);
    final result = await finalizeRawFile(
      raw,
      requestedRates: {SensorType.accelerometer: 100},
    );
    final bytes = await File(result.path).readAsBytes();
    expect(utf8.decode(gzip.decode(bytes)), text);
    expect(result.sizeBytes, bytes.length);
    expect(result.sha256, await checksumFile(File(result.path)));
    expect(result.quality.sensors.single.meanHz, 100);
    final repeat = await finalizeRawFile(raw);
    expect(repeat.sha256, result.sha256);
    expect(await raw.exists(), isTrue);
  });
  test(
    'maximum timed trial allows stop delivery grace but rejects overruns',
    () async {
      for (final durationNs in [600000000000, 601000000000, 601000000001]) {
        final raw = await File('${directory.path}/$durationNs.csv')
            .writeAsString(
              '$rawCsvHeader\n0,gravity,0,0,1,,\n$durationNs,gravity,0,0,1,,\n',
            );
        if (durationNs <= 601000000000) {
          final result = await finalizeRawFile(raw, expectedSampleCount: 2);
          expect(result.quality.durationSeconds, durationNs / 1e9);
        } else {
          await expectLater(finalizeRawFile(raw), throwsFormatException);
          expect(await File('${raw.path}.gz').exists(), isFalse);
        }
      }
    },
  );
  test(
    'native count detects whole-row truncation and unexpected extra samples',
    () async {
      final text = '$rawCsvHeader\n1,gravity,0,0,1,,\n2,gravity,0,0,1,,\n';
      final raw = await File('${directory.path}/count.csv').writeAsString(text);
      for (final count in [0, -1, 1, 3]) {
        await expectLater(
          finalizeRawFile(raw, expectedSampleCount: count),
          throwsFormatException,
        );
        expect(await raw.readAsString(), text);
        expect(await File('${raw.path}.gz').exists(), isFalse);
      }
      final result = await finalizeRawFile(raw, expectedSampleCount: 2);
      expect(result.quality.sensors.single.sampleCount, 2);
      // Existing gzip files do not bypass closure-count validation on retry.
      await expectLater(
        finalizeRawFile(raw, expectedSampleCount: 3),
        throwsFormatException,
      );
      expect(await File(result.path).exists(), isTrue);
    },
  );
  test(
    'corrupt, empty and incomplete attempts retain raw bytes without success',
    () async {
      for (final text in [
        '$rawCsvHeader\n',
        '$rawCsvHeader\n1,gravity,0,0,0,,',
        '$rawCsvHeader\n1,gravity,0,0,0,,\n1,gravity,0,0,0,,\n',
        'wrong\n',
      ]) {
        final file = await File('${directory.path}/${newUuid()}.csv')
            .writeAsString(text);
        await expectLater(finalizeRawFile(file), throwsFormatException);
        expect(await file.exists(), isTrue);
        expect(await File('${file.path}.gz').exists(), isFalse);
      }
      final partial = await File('${directory.path}/trial.csv.partial')
          .writeAsString('$rawCsvHeader\n');
      await expectLater(finalizeRawFile(partial), throwsFormatException);
    },
  );
}

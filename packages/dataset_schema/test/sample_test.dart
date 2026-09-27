import 'dart:convert';

import 'package:dataset_schema/dataset_schema.dart';
import 'package:experiment_models/experiment_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'CSV and JSON preserve nanoseconds above JavaScript integer precision',
    () {
      final sample = SensorSample(
        timestampNs: BigInt.parse('9007199254740993'),
        sensorType: SensorType.rotation,
        x: 0,
        y: 0,
        z: 0,
        w: 1,
        accuracy: 3,
      );
      expect(SensorSample.fromCsv(sample.toCsv()).toJson(), sample.toJson());
      final json = asJson(jsonDecode(jsonEncode(sample.toJson())));
      expect(json['timestamp_monotonic_ns'], '9007199254740993');
      expect(SensorSample.fromJson(json).timestampNs, sample.timestampNs);
    },
  );
  test('optional accuracy and w use empty CSV columns', () {
    final sample = SensorSample.fromCsv('1,accelerometer,0,1,2,,');
    expect(sample.w, isNull);
    expect(sample.accuracy, isNull);
  });
  test('rejects corrupt samples and invalid coordinates', () {
    for (final line in [
      '1,gravity,NaN,0,0,,',
      '-1,gravity,0,0,0,,',
      '1,rotation,0,0,0,,',
      '1,unknown,0,0,0,,',
      '1,gravity,0,0,0,,4',
      '1,gravity,0',
    ]) {
      expect(
        () => SensorSample.fromCsv(line),
        throwsFormatException,
        reason: line,
      );
    }
  });
}

library;

import 'package:experiment_models/experiment_models.dart';

const packageSchemaVersion = 1;
const rawCsvHeader = 'timestamp_monotonic_ns,sensor_type,x,y,z,w,accuracy';

/// Decimal strings in JSON preserve nanoseconds when consumed by web clients.
final class SensorSample {
  final BigInt timestampNs;
  final SensorType sensorType;
  final double x, y, z;
  final double? w;
  final int? accuracy;

  SensorSample({
    required this.timestampNs,
    required this.sensorType,
    required this.x,
    required this.y,
    required this.z,
    this.w,
    this.accuracy,
  }) {
    if (timestampNs < BigInt.zero ||
        timestampNs > BigInt.parse('9223372036854775807')) {
      throw const FormatException(
        'Timestamp must be a nonnegative signed 64-bit nanosecond value.',
      );
    }
    if (![x, y, z, if (w != null) w!].every((v) => v.isFinite)) {
      throw const FormatException('Sensor coordinates must be finite.');
    }
    if ((sensorType == SensorType.rotation) != (w != null)) {
      throw const FormatException(
        'Only rotation samples require quaternion w.',
      );
    }
    if (accuracy != null && (accuracy! < -1 || accuracy! > 3)) {
      throw const FormatException('Accuracy must be -1 (unknown) or 0–3.');
    }
  }

  factory SensorSample.fromJson(Json json) => SensorSample(
    timestampNs: BigInt.parse(stringField(json, 'timestamp_monotonic_ns')),
    sensorType: enumField(json, 'sensor_type', SensorType.values),
    x: doubleField(json, 'x'),
    y: doubleField(json, 'y'),
    z: doubleField(json, 'z'),
    w: json['w'] == null ? null : doubleField(json, 'w'),
    accuracy: json['accuracy'] == null ? null : intField(json, 'accuracy'),
  );

  Json toJson() => {
    'timestamp_monotonic_ns': timestampNs.toString(),
    'sensor_type': wireName(sensorType),
    'x': x,
    'y': y,
    'z': z,
    'w': w,
    'accuracy': accuracy,
  };

  String toCsv() =>
      '$timestampNs,${wireName(sensorType)},$x,$y,$z,${w ?? ''},${accuracy ?? ''}';

  factory SensorSample.fromCsv(String line) {
    final fields = line.split(',');
    if (fields.length != 7)
      throw const FormatException('A sample must have exactly seven columns.');
    return SensorSample.fromJson({
      'timestamp_monotonic_ns': fields[0],
      'sensor_type': fields[1],
      'x': double.parse(fields[2]),
      'y': double.parse(fields[3]),
      'z': double.parse(fields[4]),
      'w': fields[5].isEmpty ? null : double.parse(fields[5]),
      'accuracy': fields[6].isEmpty ? null : int.parse(fields[6]),
    });
  }
}

import 'dart:math' as math;

import 'package:experiment_models/experiment_models.dart';

import 'dataset_schema.dart';

final class _Moments {
  int count = 0;
  double mean = 0, m2 = 0;
  void add(double value) {
    count++;
    final delta = value - mean;
    mean += delta / count;
    m2 += delta * (value - mean);
  }

  double get stddev => math.sqrt(math.max(0, m2 / count));
}

final class _SensorMetrics {
  int count = 0, missing = 0;
  BigInt? first, last;
  int? minInterval, maxInterval;
  final intervals = _Moments(), rates = _Moments();
  void add(BigInt timestamp, double? requestedHz) {
    if (last != null) {
      final delta = timestamp - last!;
      if (delta <= BigInt.zero)
        throw const FormatException(
          'Per-sensor timestamps must increase strictly.',
        );
      final ns = delta.toInt();
      intervals.add(ns.toDouble());
      rates.add(1e9 / ns);
      minInterval = minInterval == null ? ns : math.min(minInterval!, ns);
      maxInterval = maxInterval == null ? ns : math.max(maxInterval!, ns);
      if (requestedHz != null)
        missing += math.max(0, (ns * requestedHz / 1e9).round() - 1);
    }
    count++;
    first ??= timestamp;
    last = timestamp;
  }

  SensorSummary summary(SensorType type, double? requestedHz) {
    final duration = count > 1 ? (last! - first!).toDouble() / 1e9 : 0.0;
    return SensorSummary(
      sensorType: type,
      sampleCount: count,
      durationSeconds: duration,
      meanHz: count > 1 ? (count - 1) / duration : null,
      stddevHz: count > 1 ? rates.stddev : null,
      meanIntervalNs: count > 1 ? intervals.mean : null,
      stddevIntervalNs: count > 1 ? intervals.stddev : null,
      minIntervalNs: minInterval,
      maxIntervalNs: maxInterval,
      estimatedMissing: count > 1 && requestedHz != null ? missing : null,
    );
  }
}

/// Streaming O(number of sensors) memory accumulator.
final class QualityAccumulator {
  final Map<SensorType, double> requestedRates;
  final Map<SensorType, _SensorMetrics> _sensors = {};
  final Set<String> _warnings = {};
  BigInt? _first, _last;
  int count = 0;
  QualityAccumulator({Map<SensorType, double> requestedRates = const {}})
    : requestedRates = Map.unmodifiable(requestedRates) {
    for (final entry in requestedRates.entries) {
      requirePositive(entry.value, 'requested_hz');
      _sensors[entry.key] = _SensorMetrics();
    }
  }
  void add(SensorSample sample) {
    _sensors
        .putIfAbsent(sample.sensorType, _SensorMetrics.new)
        .add(sample.timestampNs, requestedRates[sample.sensorType]);
    _first = _first == null || sample.timestampNs < _first!
        ? sample.timestampNs
        : _first;
    _last = _last == null || sample.timestampNs > _last!
        ? sample.timestampNs
        : _last;
    count++;
    if (sample.w != null) {
      final norm =
          sample.x * sample.x +
          sample.y * sample.y +
          sample.z * sample.z +
          sample.w! * sample.w!;
      if ((norm - 1).abs() > .05) _warnings.add('rotation_nonunit_quaternion');
    }
  }

  QualitySummary finish() {
    if (count == 0)
      throw const FormatException('A trial must contain sensor samples.');
    final summaries = <SensorSummary>[];
    for (final type in SensorType.values) {
      final metrics = _sensors[type];
      if (metrics == null) continue;
      final summary = metrics.summary(type, requestedRates[type]);
      summaries.add(summary);
      if (summary.sampleCount < 2)
        _warnings.add('${wireName(type)}_insufficient_samples');
      if (summary.meanHz != null &&
          requestedRates[type] != null &&
          summary.meanHz! < requestedRates[type]! * .8)
        _warnings.add('${wireName(type)}_low_rate');
      if (summary.meanIntervalNs != null &&
          summary.stddevIntervalNs! > summary.meanIntervalNs! * .25)
        _warnings.add('${wireName(type)}_irregular_rate');
    }
    return QualitySummary(
      durationSeconds: (_last! - _first!).toDouble() / 1e9,
      sensors: summaries,
      warnings: _warnings.toList()..sort(),
    );
  }
}

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:experiment_models/experiment_models.dart';

final class SensorCapabilities {
  final List<SensorMetadata> sensors;
  final List<SensorType> unavailable;
  final String model, manufacturer, os, osVersion, appVersion;
  SensorCapabilities(Json json)
    : sensors = List.unmodifiable(
        listField(json, 'sensors', (v) => SensorMetadata.fromJson(asJson(v))),
      ),
      unavailable = List.unmodifiable(
        listField(
          json,
          'unavailable',
          (v) => enumField({'sensor': v}, 'sensor', SensorType.values),
        ),
      ),
      model = stringField(json, 'model'),
      manufacturer = stringField(json, 'manufacturer'),
      os = stringField(json, 'os'),
      osVersion = stringField(json, 'os_version'),
      appVersion = stringField(json, 'app_version');
}

final class ClosedRecording {
  final String trialId, rawPath;
  final int sampleCount;
  ClosedRecording(Json json)
    : trialId = stringField(json, 'trial_id'),
      rawPath = stringField(json, 'raw_path'),
      sampleCount = intField(json, 'sample_count') {
    requireUuid(trialId, 'trial_id');
    requireText(rawPath, 'raw_path');
    requirePositive(sampleCount, 'sample_count');
  }
}

abstract interface class SensorRecorder {
  Future<SensorCapabilities> capabilities(double requestedHz);
  Future<void> start(String trialId, double requestedHz);
  Future<void> checkRecording(String trialId);
  Future<ClosedRecording> stop(String trialId);
  Future<void> abort();
}

final class NativeSensorRecorder implements SensorRecorder {
  final MethodChannel channel;
  NativeSensorRecorder({
    this.channel = const MethodChannel('collector/sensors'),
  });
  Future<Json> _call(String method, [Json? arguments]) async {
    final result = await channel.invokeMethod<Object?>(method, arguments);
    return asJson(jsonDecode(jsonEncode(result)));
  }

  Future<String> storageDirectory() async =>
      stringField(await _call('storageDirectory'), 'path');

  @override
  Future<SensorCapabilities> capabilities(double requestedHz) async =>
      SensorCapabilities(
        await _call('capabilities', {'requested_hz': requestedHz}),
      );
  @override
  Future<void> start(String trialId, double requestedHz) async {
    requireUuid(trialId, 'trial_id');
    if (!requestedHz.isFinite || requestedHz < 1 || requestedHz > 200)
      throw ArgumentError('Sampling rate must be 1–200 Hz.');
    final response = await _call('start', {
      'trial_id': trialId,
      'requested_hz': requestedHz,
    });
    _requireRecording(response, trialId);
  }

  void _requireRecording(Json response, String trialId) {
    if (response['status'] != 'recording' || response['trial_id'] != trialId)
      throw StateError('Native recording is not active for this trial.');
  }

  @override
  Future<void> checkRecording(String trialId) async {
    requireUuid(trialId, 'trial_id');
    _requireRecording(await _call('status'), trialId);
  }

  @override
  Future<ClosedRecording> stop(String trialId) async {
    final closed = ClosedRecording(await _call('stop', {'trial_id': trialId}));
    if (closed.trialId != trialId)
      throw StateError('Native trial identity mismatch.');
    return closed;
  }

  @override
  Future<void> abort() async {
    await _call('abort');
  }
}

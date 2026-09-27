import 'package:collector_mobile/sensors/native_recorder.dart';
import 'package:experiment_models/experiment_models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('collector/sensors');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));
  test(
    'native contract exchanges capabilities and trial results, never samples',
    () async {
      final calls = <String>[];
      final id = newUuid();
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        return switch (call.method) {
          'capabilities' => {
            'model': 'phone',
            'manufacturer': 'vendor',
            'os': 'Android',
            'os_version': '16',
            'app_version': '0.1.0',
            'sensors': [
              {
                'sensor_type': 'accelerometer',
                'name': 'accelerometer',
                'requested_hz': 100.0,
              },
            ],
            'unavailable': ['gyroscope', 'gravity', 'rotation', 'magnetometer'],
          },
          'start' => {'status': 'recording', 'trial_id': id},
          'status' => {'status': 'recording', 'trial_id': id},
          'stop' => {
            'trial_id': id,
            'raw_path': '/private/$id.csv',
            'sample_count': 128,
          },
          _ => {'status': 'idle'},
        };
      });
      final recorder = NativeSensorRecorder();
      final capability = await recorder.capabilities(100);
      expect(capability.unavailable, hasLength(4));
      await recorder.start(id, 100);
      await recorder.checkRecording(id);
      final file = await recorder.stop(id);
      expect(file.sampleCount, 128);
      expect(calls, ['capabilities', 'start', 'status', 'stop']);
    },
  );
  test('status and start must confirm the exact active native trial', () async {
    final id = newUuid();
    final recorder = NativeSensorRecorder();
    for (final response in [
      {'status': 'failed', 'trial_id': id},
      {'status': 'idle', 'trial_id': null},
      {'status': 'recording', 'trial_id': newUuid()},
      {'status': 'recording'},
    ]) {
      messenger.setMockMethodCallHandler(channel, (_) async => response);
      await expectLater(recorder.checkRecording(id), throwsStateError);
      await expectLater(recorder.start(id, 100), throwsStateError);
    }
  });
  test(
    'mismatched trial ID or empty closed files cannot be accepted',
    () async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => {
          'trial_id': newUuid(),
          'raw_path': '/private/trial.csv',
          'sample_count': 1,
        },
      );
      await expectLater(
        NativeSensorRecorder().stop(newUuid()),
        throwsStateError,
      );
      expect(
        () => ClosedRecording({
          'trial_id': newUuid(),
          'raw_path': 'file',
          'sample_count': 0,
        }),
        throwsFormatException,
      );
      await expectLater(
        NativeSensorRecorder().start('../escape', 100),
        throwsFormatException,
      );
    },
  );
}

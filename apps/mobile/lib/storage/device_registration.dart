import 'package:experiment_models/experiment_models.dart';

import '../sensors/native_recorder.dart';
import 'local_database.dart' show LocalDatabase;

final class DeviceRegistration {
  final LocalDatabase database;
  final SensorRecorder recorder;
  DeviceRegistration(this.database, this.recorder);

  Future<PhysicalDevice> register({double requestedHz = 100}) async {
    final capabilities = await recorder.capabilities(requestedHz);
    return database.transaction(() async {
      final existing = await database.getOrCreateDevice(
        () => PhysicalDevice(
          id: newUuid(),
          model: capabilities.model,
          manufacturer: capabilities.manufacturer,
          os: capabilities.os,
          osVersion: capabilities.osVersion,
          appVersion: capabilities.appVersion,
          sensors: capabilities.sensors,
          createdAt: DateTime.now().toUtc(),
        ),
      );
      final refreshed = PhysicalDevice(
        id: existing.id,
        model: capabilities.model,
        manufacturer: capabilities.manufacturer,
        os: capabilities.os,
        osVersion: capabilities.osVersion,
        appVersion: capabilities.appVersion,
        sensors: capabilities.sensors,
        createdAt: existing.createdAt,
      );
      await database.updateDevice(refreshed);
      return refreshed;
    });
  }
}

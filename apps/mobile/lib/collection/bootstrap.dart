import 'dart:io';

import '../sync/sync_worker.dart';
import '../sync/upload_gateway.dart';

import '../sensors/native_recorder.dart';
import '../storage/device_registration.dart';
import '../storage/local_database.dart' show LocalDatabase;
import '../storage/session_store.dart';
import 'controller.dart';
import 'local_capture.dart';
import '../enrollment/remote_enrollment.dart';

import 'package:experiment_models/client_config.dart';

/// Initialize native private storage before participant collection can begin.
Future<CollectionController> createLocalCollector() async {
  final recorder = NativeSensorRecorder();
  final directory = Directory(await recorder.storageDirectory());
  await directory.create(recursive: true);
  final database = LocalDatabase.file(
    File('${directory.path}/collector.sqlite'),
  );
  try {
    final device = await DeviceRegistration(database, recorder).register();
    await database.recoverPending(DateTime.now().toUtc());
    final config = ClientConfig.fromEnvironment(const {
      'APP_ENV': String.fromEnvironment('APP_ENV', defaultValue: 'production'),
      'SUPABASE_URL': String.fromEnvironment('SUPABASE_URL'),
      'SUPABASE_ANON_KEY': String.fromEnvironment('SUPABASE_ANON_KEY'),
      'SUPABASE_EDGE_FUNCTIONS_URL': String.fromEnvironment(
        'SUPABASE_EDGE_FUNCTIONS_URL',
      ),
      'ENABLE_DEBUG_TOOLS': String.fromEnvironment(
        'ENABLE_DEBUG_TOOLS',
        defaultValue: 'false',
      ),
    }, allowOffline: true);
    final gateway = RemoteEnrollmentGateway(
      database: database,
      device: device,
      endpoint: config.functionsUrl == null
          ? null
          : Uri.parse(
              '${config.functionsUrl.toString().replaceFirst(RegExp(r'/+$'), '')}/collector',
            ),
      publicKey: config.anonKey,
    );
    await gateway.initialize();
    SyncScheduler? scheduler;
    final uploadGateway =
        gateway.endpoint == null ||
            config.anonKey == null ||
            config.anonKey!.isEmpty
        ? null
        : RemoteUploadGateway(
            endpoint: gateway.endpoint!,
            publicKey: config.anonKey!,
          );
    final controller = CollectionController(
      enrollmentGateway: gateway,
      capture: LocalTrialCapture(
        recorder: recorder,
        database: database,
        device: device,
      ),
      sessionStore: LocalSessionStore(database),
      onSyncRequested: () => scheduler?.kick(),
      onClose: () async {
        await scheduler?.stop();
        uploadGateway?.client.close();
        gateway.client.close();
        await database.close();
      },
    );
    if (uploadGateway != null) {
      scheduler = SyncScheduler(
        SyncWorker(database: database, gateway: uploadGateway),
        canRun: () => controller.allowsSync,
      )..start();
    }
    return controller;
  } catch (_) {
    await database.close();
    rethrow;
  }
}

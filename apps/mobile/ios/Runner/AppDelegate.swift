import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var sensorRecorder: NativeSensorRecorder?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CollectorSensors")!
    do {
      let recorder = try NativeSensorRecorder()
      sensorRecorder = recorder
      FlutterMethodChannel(name: "collector/sensors", binaryMessenger: registrar.messenger())
        .setMethodCallHandler { call, result in recorder.handle(call, result: result) }
    } catch {
      FlutterMethodChannel(name: "collector/sensors", binaryMessenger: registrar.messenger())
        .setMethodCallHandler { _, result in
          result(FlutterError(code: "storage_unavailable", message: "Local recording storage is unavailable.", details: nil))
        }
    }
  }
}

import CoreMotion
import Flutter
import Foundation
import UIKit

final class NativeSensorRecorder {
  private let motion = CMMotionManager()
  private let callbacks = OperationQueue()
  private let writerQueue = DispatchQueue(label: "collector.sensor-writer")
  private var writer: RawCsvWriter?
  private var trialID: String?
  private var epoch = UUID()
  private var startedAt: TimeInterval = 0
  private var failed = false
  private var timeout: DispatchWorkItem?
  private let directory: URL
  private let deviceInfo: [String: Any]
  private var observers: [NSObjectProtocol] = []

  init() throws {
    callbacks.maxConcurrentOperationCount = 1
    callbacks.qualityOfService = .userInitiated
    var root = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                           appropriateFor: nil, create: true)
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try root.setResourceValues(values)
    directory = root.appendingPathComponent("trials", isDirectory: true)
    var system = utsname()
    uname(&system)
    let model = withUnsafePointer(to: &system.machine) {
      $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
    }
    deviceInfo = ["model": model, "manufacturer": "Apple", "os": "iOS",
                  "os_version": UIDevice.current.systemVersion,
                  "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"]
    for name in [UIApplication.willResignActiveNotification, UIApplication.didEnterBackgroundNotification] {
      observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
        self?.writerQueue.async { [weak self] in
          guard let self = self, self.trialID != nil else { return }
          self.fail()
        }
        UIApplication.shared.isIdleTimerDisabled = false
      })
    }
  }

  deinit {
    observers.forEach { NotificationCenter.default.removeObserver($0) }
    stopSensors()
    try? writer?.abort()
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    writerQueue.async { [self] in
      do {
        let args = call.arguments as? [String: Any] ?? [:]
        let rate = (args["requested_hz"] as? NSNumber)?.doubleValue ?? 100
        guard rate.isFinite, (1 ... 200).contains(rate) else { throw RecorderError.invalidInput }
        let response: [String: Any]
        switch call.method {
        case "capabilities": response = capabilities(rate: rate)
        case "storageDirectory": response = ["path": directory.deletingLastPathComponent().path]
        case "start":
          guard let id = args["trial_id"] as? String else { throw RecorderError.invalidInput }
          try start(id: id, rate: rate)
          response = ["status": "recording", "trial_id": id]
        case "stop":
          guard let id = args["trial_id"] as? String, id == trialID else { throw RecorderError.invalidInput }
          stopSensors()
          guard !failed, let active = writer else { throw RecorderError.interrupted }
          let path = try active.finish()
          response = ["trial_id": id, "raw_path": path.path, "sample_count": active.sampleCount]
          writer = nil
          trialID = nil
          epoch = UUID()
        case "abort":
          stopSensors()
          try writer?.abort()
          writer = nil
          trialID = nil
          failed = false
          epoch = UUID()
          response = ["status": "idle"]
        case "status":
          response = ["status": failed ? "failed" : (writer == nil ? "idle" : "recording"),
                      "trial_id": trialID as Any? ?? NSNull()]
        default:
          DispatchQueue.main.async { result(FlutterMethodNotImplemented) }
          return
        }
        DispatchQueue.main.async {
          if call.method == "start" {
            UIApplication.shared.isIdleTimerDisabled = true
          }
          if call.method == "stop" || call.method == "abort" {
            UIApplication.shared.isIdleTimerDisabled = false
          }
          result(response)
        }
      } catch {
        if call.method == "start" || call.method == "stop" {
          fail()
        }
        DispatchQueue.main.async {
          UIApplication.shared.isIdleTimerDisabled = false
          result(FlutterError(code: "recording_failed", message: "The sensor operation could not complete safely.", details: nil))
        }
      }
    }
  }

  private func capabilities(rate: Double) -> [String: Any] {
    let available = [("accelerometer", motion.isAccelerometerAvailable),
                     ("gyroscope", motion.isGyroAvailable),
                     ("magnetometer", motion.isMagnetometerAvailable),
                     ("gravity", motion.isDeviceMotionAvailable),
                     ("rotation", motion.isDeviceMotionAvailable)]
    var info = deviceInfo
    info["sensors"] = available.filter { $0.1 }.map { item -> [String: Any] in
      ["sensor_type": item.0, "name": "Core Motion \(item.0)", "requested_hz": rate,
       "vendor": NSNull(), "observed_hz": NSNull(), "resolution": NSNull(), "maximum_range": NSNull()]
    }
    info["unavailable"] = available.filter { !$0.1 }.map { $0.0 }
    return info
  }

  private func start(id: String, rate: Double) throws {
    guard writer == nil, trialID == nil else { throw RecorderError.busy }
    guard motion.isAccelerometerAvailable || motion.isGyroAvailable || motion.isMagnetometerAvailable || motion.isDeviceMotionAvailable else {
      throw RecorderError.unavailable
    }
    writer = try RawCsvWriter(directory: directory, trialID: id)
    trialID = id
    failed = false
    startedAt = ProcessInfo.processInfo.systemUptime
    epoch = UUID()
    let token = epoch
    motion.accelerometerUpdateInterval = 1 / rate
    motion.gyroUpdateInterval = 1 / rate
    motion.magnetometerUpdateInterval = 1 / rate
    motion.deviceMotionUpdateInterval = 1 / rate
    if motion.isAccelerometerAvailable {
      motion.startAccelerometerUpdates(to: callbacks) { [weak self] data, error in
        self?.receive(token: token, timestamp: data?.timestamp, error: error) { writer in
          guard let d = data else { throw RecorderError.unavailable }
          try writer.append(timestamp: d.timestamp, sensor: "accelerometer", x: d.acceleration.x * 9.80665,
                            y: d.acceleration.y * 9.80665, z: d.acceleration.z * 9.80665)
        }
      }
    }
    if motion.isGyroAvailable {
      motion.startGyroUpdates(to: callbacks) { [weak self] data, error in
        self?.receive(token: token, timestamp: data?.timestamp, error: error) { writer in
          guard let d = data else { throw RecorderError.unavailable }
          try writer.append(timestamp: d.timestamp, sensor: "gyroscope", x: d.rotationRate.x, y: d.rotationRate.y, z: d.rotationRate.z)
        }
      }
    }
    if motion.isMagnetometerAvailable {
      motion.startMagnetometerUpdates(to: callbacks) { [weak self] data, error in
        self?.receive(token: token, timestamp: data?.timestamp, error: error) { writer in
          guard let d = data else { throw RecorderError.unavailable }
          try writer.append(timestamp: d.timestamp, sensor: "magnetometer", x: d.magneticField.x, y: d.magneticField.y, z: d.magneticField.z)
        }
      }
    }
    if motion.isDeviceMotionAvailable {
      motion.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: callbacks) { [weak self] data, error in
        self?.receive(token: token, timestamp: data?.timestamp, error: error) { writer in
          guard let d = data else { throw RecorderError.unavailable }
          try writer.append(timestamp: d.timestamp, sensor: "gravity", x: d.gravity.x * 9.80665, y: d.gravity.y * 9.80665, z: d.gravity.z * 9.80665)
          let q = d.attitude.quaternion
          try writer.append(timestamp: d.timestamp, sensor: "rotation", x: q.x, y: q.y, z: q.z, w: q.w)
        }
      }
    }
    let deadline = DispatchWorkItem { [weak self] in self?.fail() }
    timeout = deadline
    writerQueue.asyncAfter(deadline: .now() + recordingSafetyTimeout, execute: deadline)
  }

  private func receive(token: UUID, timestamp: TimeInterval?, error: Error?, write: @escaping (RawCsvWriter) throws -> Void) {
    writerQueue.async { [weak self] in
      guard let self = self, self.epoch == token, !self.failed, let active = self.writer else { return }
      do {
        if error != nil || timestamp == nil {
          throw RecorderError.unavailable
        }
        if timestamp! < self.startedAt {
          return
        }
        try write(active)
      } catch { self.fail() }
    }
  }

  private func stopSensors() {
    timeout?.cancel()
    timeout = nil
    motion.stopAccelerometerUpdates()
    motion.stopGyroUpdates()
    motion.stopMagnetometerUpdates()
    motion.stopDeviceMotionUpdates()
  }

  private func fail() {
    failed = true
    stopSensors()
    try? writer?.abort()
    writer = nil
    epoch = UUID()
  }
}

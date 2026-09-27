import Foundation

/// Protocols allow 600 seconds. Leave a bounded second for the stop command.
let recordingSafetyTimeout: TimeInterval = 601

final class RawCsvWriter {
  private let partial: URL
  private let handle: FileHandle
  private var buffer = Data()
  private var buffered = 0
  private var closed = false
  private(set) var sampleCount = 0

  init(directory: URL, trialID: String) throws {
    guard UUID(uuidString: trialID)?.uuidString.lowercased() == trialID else {
      throw RecorderError.invalidInput
    }
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    partial = directory.appendingPathComponent("\(trialID)-\(UUID().uuidString.lowercased()).csv.partial")
    let descriptor = open(partial.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, S_IRUSR | S_IWUSR)
    guard descriptor >= 0 else { throw RecorderError.storage }
    handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
    try handle.write(contentsOf: Data("timestamp_monotonic_ns,sensor_type,x,y,z,w,accuracy\n".utf8))
  }

  func append(timestamp: TimeInterval, sensor: String, x: Double, y: Double, z: Double,
              w: Double? = nil, accuracy: Int? = nil) throws
  {
    guard !closed, timestamp.isFinite, timestamp >= 0,
          timestamp < Double(Int64.max) / 1_000_000_000,
          [x, y, z, w ?? 0].allSatisfy({ $0.isFinite }),
          (sensor == "rotation") == (w != nil)
    else { throw RecorderError.invalidInput }
    let ns = Int64((timestamp * 1_000_000_000).rounded())
    let row = "\(ns),\(sensor),\(x),\(y),\(z),\(w.map { String($0) } ?? ""),\(accuracy.map { String($0) } ?? "")\n"
    buffer.append(contentsOf: row.utf8)
    buffered += 1
    sampleCount += 1
    if buffered >= 128 {
      try flushBatch()
    }
  }

  private func flushBatch() throws {
    if !buffer.isEmpty {
      try handle.write(contentsOf: buffer)
    }
    buffer.removeAll(keepingCapacity: true)
    buffered = 0
  }

  func finish() throws -> URL {
    guard !closed, sampleCount > 0 else { throw RecorderError.empty }
    try flushBatch()
    try handle.synchronize()
    try handle.close()
    closed = true
    let complete = partial.deletingPathExtension()
    try FileManager.default.moveItem(at: partial, to: complete)
    return complete
  }

  func abort() throws {
    guard !closed else { return }
    defer { closed = true; try? handle.close() }
    try flushBatch()
    try handle.synchronize()
    // Keep partial attempts for explicit recovery; they are never uploadable.
  }
}

enum RecorderError: Error { case invalidInput, storage, empty, busy, unavailable, interrupted }

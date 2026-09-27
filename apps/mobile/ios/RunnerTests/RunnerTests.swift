import Foundation
@testable import Runner
import XCTest

final class RunnerTests: XCTestCase {
  func testSafetyDeadlineAllowsMaximumProtocolDuration() {
    XCTAssertGreaterThan(recordingSafetyTimeout, 600)
    XCTAssertLessThanOrEqual(recordingSafetyTimeout, 601)
  }

  func testNativeWriterBatchesAndRetainsInterruptedAttempts() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let id = UUID().uuidString.lowercased()
    let writer = try RawCsvWriter(directory: directory, trialID: id)
    for index in 0 ..< 300 {
      try writer.append(timestamp: 1.25 + Double(index) * 0.01, sensor: "accelerometer", x: 1, y: 2, z: 3)
    }
    let complete = try writer.finish()
    let contents = try String(contentsOf: complete, encoding: .utf8)
    XCTAssertEqual(contents.split(separator: "\n").count, 301)
    XCTAssertTrue(contents.contains("1250000000,accelerometer,1.0,2.0,3.0,,"))
    XCTAssertFalse(complete.path.hasSuffix(".partial"))
    XCTAssertThrowsError(try writer.finish())
    let interrupted = try RawCsvWriter(directory: directory, trialID: id)
    try interrupted.append(timestamp: 1, sensor: "rotation", x: 0, y: 0, z: 0, w: 1)
    try interrupted.abort()
    let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
    XCTAssertEqual(files.filter { $0.path.hasSuffix(".partial") }.count, 1)
    XCTAssertEqual(try String(contentsOf: complete, encoding: .utf8), contents)
  }

  func testEmptyAndInvalidSamplesCannotBeReportedSaved() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let writer = try RawCsvWriter(directory: directory, trialID: UUID().uuidString.lowercased())
    XCTAssertThrowsError(try writer.finish())
    XCTAssertThrowsError(try writer.append(timestamp: -1, sensor: "gravity", x: 0, y: 0, z: 0))
    try writer.abort()
  }
}

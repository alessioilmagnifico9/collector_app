package org.research.collector.collector_mobile

import java.io.File
import java.io.FileOutputStream
import java.util.UUID

// Protocols allow 600 seconds. Leave a bounded second for the stop command.
const val RECORDING_SAFETY_TIMEOUT_MS = 601_000L

/** Single-writer native buffer. A .partial file is never reported as saved. */
class RawCsvWriter(directory: File, trialId: String) {
  private val partial: File
  private val output: FileOutputStream
  private val buffer = StringBuilder()
  private var buffered = 0
  private var closed = false
  var sampleCount = 0
    private set

  init {
    require(UUID.fromString(trialId).toString() == trialId)
    check(directory.exists() || directory.mkdirs()) { "Cannot create recording directory" }
    partial = File(directory, "$trialId-${UUID.randomUUID()}.csv.partial")
    check(partial.createNewFile()) { "Recording already exists" }
    output = FileOutputStream(partial, false)
    output.write(
        "timestamp_monotonic_ns,sensor_type,x,y,z,w,accuracy\n".toByteArray(Charsets.UTF_8)
    )
  }

  fun append(
      timestamp: Long,
      sensor: String,
      x: Double,
      y: Double,
      z: Double,
      w: Double?,
      accuracy: Int?,
  ) {
    check(!closed)
    require(timestamp >= 0 && listOfNotNull(x, y, z, w).all { it.isFinite() })
    require(sensor in setOf("accelerometer", "gyroscope", "gravity", "rotation", "magnetometer"))
    require((sensor == "rotation") == (w != null))
    buffer
        .append(timestamp)
        .append(',')
        .append(sensor)
        .append(',')
        .append(x)
        .append(',')
        .append(y)
        .append(',')
        .append(z)
        .append(',')
        .append(w ?: "")
        .append(',')
        .append(accuracy ?: "")
        .append('\n')
    buffered++
    sampleCount++
    if (buffered >= 128) flushBatch()
  }

  private fun flushBatch() {
    if (buffer.isNotEmpty()) output.write(buffer.toString().toByteArray(Charsets.UTF_8))
    buffer.setLength(0)
    buffered = 0
  }

  fun finish(): File {
    check(!closed)
    check(sampleCount > 0) { "No sensor samples were received" }
    flushBatch()
    output.fd.sync()
    output.close()
    closed = true
    val complete = File(partial.path.removeSuffix(".partial"))
    check(partial.renameTo(complete)) { "Unable to close recording atomically" }
    return complete
  }

  fun abort() {
    if (closed) return
    try {
      flushBatch()
      output.fd.sync()
    } finally {
      closed = true
      output.close()
    }
    // Retain .partial for explicit recovery; never overwrite or upload it.
  }
}

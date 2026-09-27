package org.research.collector.collector_mobile

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.os.SystemClock
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.UUID

class NativeSensorRecorder(private val context: Context) : SensorEventListener {
  private val manager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
  private val thread = HandlerThread("collector-sensors").apply { start() }
  private val worker = Handler(thread.looper)
  private val main = Handler(Looper.getMainLooper())
  private val types =
      linkedMapOf(
          Sensor.TYPE_ACCELEROMETER to "accelerometer",
          Sensor.TYPE_GYROSCOPE to "gyroscope",
          Sensor.TYPE_GRAVITY to "gravity",
          Sensor.TYPE_ROTATION_VECTOR to "rotation",
          Sensor.TYPE_MAGNETIC_FIELD to "magnetometer",
      )
  private var writer: RawCsvWriter? = null
  private var trialId: String? = null
  private var startedNs = 0L
  private var failure: String? = null
  private val timeout = Runnable { fail("Recording exceeded the maximum duration") }

  fun handle(call: MethodCall, result: MethodChannel.Result) {
    val stopBoundary = SystemClock.elapsedRealtimeNanos()
    worker.post {
      try {
        val response: Map<String, Any?> =
            when (call.method) {
              "capabilities" -> capabilities(rate(call))
              "storageDirectory" -> mapOf("path" to context.noBackupFilesDir.absolutePath)
              "start" ->
                  start(
                      call.argument<String>("trial_id") ?: error("Missing trial ID"),
                      rate(call),
                  )
              "stop" ->
                  stop(
                      call.argument<String>("trial_id") ?: error("Missing trial ID"),
                      stopBoundary,
                  )
              "abort" -> {
                abort()
                mapOf("status" to "idle")
              }
              "status" ->
                  mapOf(
                      "trial_id" to trialId,
                      "status" to
                          if (failure != null) "failed"
                          else if (writer != null) "recording" else "idle",
                  )
              else -> {
                main.post { result.notImplemented() }
                return@post
              }
            }
        main.post { result.success(response) }
      } catch (_: Exception) {
        main.post {
          result.error(
              "recording_failed",
              "The sensor operation could not complete safely.",
              null,
          )
        }
      }
    }
  }

  private fun rate(call: MethodCall): Double {
    val hz = call.argument<Number>("requested_hz")?.toDouble() ?: 100.0
    require(hz.isFinite() && hz in 1.0..200.0)
    return hz
  }

  private fun capabilities(hz: Double): Map<String, Any?> =
      mapOf(
          "model" to Build.MODEL,
          "manufacturer" to Build.MANUFACTURER,
          "os" to "Android",
          "os_version" to Build.VERSION.RELEASE,
          "app_version" to
              context.packageManager.getPackageInfo(context.packageName, 0).versionName,
          "sensors" to
              types.mapNotNull { (type, name) ->
                manager.getDefaultSensor(type)?.let { sensor ->
                  mapOf(
                      "sensor_type" to name,
                      "name" to sensor.name,
                      "vendor" to sensor.vendor,
                      "requested_hz" to hz,
                      "observed_hz" to null,
                      "resolution" to sensor.resolution.toDouble(),
                      "maximum_range" to sensor.maximumRange.toDouble(),
                  )
                }
              },
          "unavailable" to
              types.filter { manager.getDefaultSensor(it.key) == null }.values.toList(),
      )

  private fun start(id: String, hz: Double): Map<String, Any?> {
    require(UUID.fromString(id).toString() == id)
    check(writer == null && trialId == null) { "Already recording" }
    failure = null
    val file = RawCsvWriter(File(context.noBackupFilesDir, "trials"), id)
    writer = file
    trialId = id
    startedNs = SystemClock.elapsedRealtimeNanos()
    try {
      var registered = 0
      for (type in types.keys) {
        val sensor = manager.getDefaultSensor(type) ?: continue
        if (manager.registerListener(this, sensor, (1_000_000 / hz).toInt(), 0, worker))
            registered++
      }
      check(registered > 0) { "No available sensors" }
      worker.postDelayed(timeout, RECORDING_SAFETY_TIMEOUT_MS)
      return mapOf("status" to "recording", "trial_id" to id)
    } catch (error: Exception) {
      abort()
      throw error
    }
  }

  override fun onSensorChanged(event: SensorEvent) {
    val active = writer ?: return
    if (failure != null || event.timestamp < startedNs) return
    val type = types[event.sensor.type] ?: return
    try {
      val values = event.values
      if (type == "rotation") {
        val q = FloatArray(4)
        SensorManager.getQuaternionFromVector(q, values)
        active.append(
            event.timestamp,
            type,
            q[1].toDouble(),
            q[2].toDouble(),
            q[3].toDouble(),
            q[0].toDouble(),
            event.accuracy,
        )
      } else {
        active.append(
            event.timestamp,
            type,
            values[0].toDouble(),
            values[1].toDouble(),
            values[2].toDouble(),
            null,
            event.accuracy,
        )
      }
    } catch (_: Exception) {
      fail("Sensor write failed")
    }
  }

  override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

  private fun stop(id: String, boundary: Long): Map<String, Any?> {
    check(id == trialId) { "Trial mismatch" }
    manager.unregisterListener(this)
    worker.removeCallbacks(timeout)
    check(failure == null) { "Recording failed" }
    check(boundary >= startedNs)
    val active = writer ?: error("No active recording")
    try {
      val file = active.finish()
      writer = null
      trialId = null
      return mapOf(
          "trial_id" to id,
          "raw_path" to file.path,
          "sample_count" to active.sampleCount,
      )
    } catch (error: Exception) {
      fail("File closure failed")
      throw error
    }
  }

  private fun fail(message: String) {
    failure = message
    manager.unregisterListener(this)
    worker.removeCallbacks(timeout)
    try {
      writer?.abort()
    } catch (_: Exception) {
      /* Preserve partial bytes. */
    }
    writer = null
  }

  private fun abort() {
    manager.unregisterListener(this)
    worker.removeCallbacks(timeout)
    try {
      writer?.abort()
    } finally {
      writer = null
      trialId = null
      failure = null
    }
  }

  fun interrupt() {
    worker.post { if (trialId != null) fail("Recording interrupted") }
  }

  fun dispose() {
    worker.post {
      try {
        abort()
      } finally {
        thread.quitSafely()
      }
    }
  }
}

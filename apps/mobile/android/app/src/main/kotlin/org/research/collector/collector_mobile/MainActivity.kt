package org.research.collector.collector_mobile

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private var recorder: NativeSensorRecorder? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    val sensors = NativeSensorRecorder(applicationContext)
    recorder = sensors
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "collector/sensors")
        .setMethodCallHandler { call, result ->
          if (call.method == "start")
              window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
          if (call.method == "stop" || call.method == "abort")
              window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
          sensors.handle(call, result)
        }
  }

  override fun onPause() {
    recorder?.interrupt()
    window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    super.onPause()
  }

  override fun onDestroy() {
    recorder?.dispose()
    recorder = null
    super.onDestroy()
  }
}

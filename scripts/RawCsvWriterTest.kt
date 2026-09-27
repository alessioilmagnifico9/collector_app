import java.nio.file.Files
import java.util.UUID
import org.research.collector.collector_mobile.RECORDING_SAFETY_TIMEOUT_MS
import org.research.collector.collector_mobile.RawCsvWriter

fun main() {
  check(RECORDING_SAFETY_TIMEOUT_MS > 600_000 && RECORDING_SAFETY_TIMEOUT_MS <= 601_000)
  val directory = Files.createTempDirectory("collector-writer-test").toFile()
  try {
    val id = UUID.randomUUID().toString()
    val writer = RawCsvWriter(directory, id)
    repeat(300) { index ->
      writer.append(9007199254740993L + index, "accelerometer", 1.0, 2.0, 3.0, null, 3)
    }
    val complete = writer.finish()
    val lines = complete.readLines()
    check(lines.size == 301)
    check(lines[0] == "timestamp_monotonic_ns,sensor_type,x,y,z,w,accuracy")
    check(lines[1] == "9007199254740993,accelerometer,1.0,2.0,3.0,,3")
    check(!complete.name.endsWith(".partial"))
    check(runCatching { writer.finish() }.isFailure)
    val interrupted = RawCsvWriter(directory, id)
    interrupted.append(1L, "rotation", 0.0, 0.0, 0.0, 1.0, null)
    interrupted.abort()
    check(directory.listFiles()!!.count { it.name.endsWith(".partial") } == 1)
    check(complete.readLines() == lines)
    val empty = RawCsvWriter(directory, UUID.randomUUID().toString())
    check(runCatching { empty.finish() }.isFailure)
    empty.abort()
    println(
        "Native writer tests passed: batches, exact timestamps, closure, empty files, retained partials, no overwrites."
    )
  } finally {
    directory.deleteRecursively()
  }
}

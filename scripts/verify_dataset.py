#!/usr/bin/env python3
"""Offline, read-only verification of an exported research dataset (stdlib only)."""

import argparse
from collections import Counter
import gzip
import hashlib
import json
import math
from pathlib import Path
import uuid

HEADER = "timestamp_monotonic_ns,sensor_type,x,y,z,w,accuracy"
SENSORS = {"accelerometer", "gyroscope", "gravity", "rotation", "magnetometer"}
MAX_RAW_BYTES = 512 * 1024 * 1024
TABLES = ("participants", "devices", "protocols", "protocol_versions", "sessions", "trials", "trial_files")


def require(condition, message):
    if not condition:
        raise ValueError(message)


def identifier(value):
    require(isinstance(value, str) and str(uuid.UUID(value)) == value, "Invalid UUID")
    return value


def rows_by_id(document, table):
    rows = document[table]
    require(isinstance(rows, list), f"Invalid table: {table}")
    result = {}
    for row in rows:
        key = identifier(row["id"])
        require(key not in result, f"Duplicate UUID in {table}")
        result[key] = row
    return result


def verify_raw(path, manifest, trial):
    require(path.stat().st_size == manifest["size_bytes"], "Compressed size mismatch")
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    require(digest.hexdigest() == manifest["sha256"], "Compressed SHA-256 mismatch")
    counts, last = Counter(), {}
    total = 0
    with gzip.open(path, "rt", encoding="utf-8", newline="") as stream:
        require(stream.readline(4097) == HEADER + "\n", "Invalid raw header")
        while True:
            line = stream.readline(4097)
            if not line:
                break
            total += len(line.encode("utf-8"))
            require(total <= MAX_RAW_BYTES and len(line) <= 4096 and line.endswith("\n"), "Oversize or incomplete raw file")
            fields = line.rstrip("\n").split(",")
            require(len(fields) == 7, "Invalid raw column count")
            stamp, sensor = int(fields[0]), fields[1]
            require(0 <= stamp <= 9223372036854775807 and sensor in SENSORS, "Invalid sensor or timestamp")
            require(sensor not in last or stamp > last[sensor], "Nonmonotonic sensor timestamps")
            require((sensor == "rotation") == bool(fields[5]), "Invalid quaternion component")
            require(all(math.isfinite(float(value)) for value in fields[2:6] if value != ""), "Nonfinite coordinate")
            require(all(value != "" for value in fields[2:5]), "Missing coordinate")
            require(fields[6] == "" or -1 <= int(fields[6]) <= 3, "Invalid accuracy")
            last[sensor] = stamp
            counts[sensor] += 1
    require(bool(counts), "Empty raw recording")
    expected = {}
    for summary in trial["quality"]["sensors"]:
        sensor = summary["sensor_type"]
        require(sensor in SENSORS and sensor not in expected, "Invalid sensor summary")
        expected[sensor] = summary["sample_count"]
    require(dict(counts) == {k: v for k, v in expected.items() if v != 0}, "Sensor sample counts differ from metadata")


def verify_dataset(document, raw_root, export_paths=None):
    require(document["export_schema_version"] == 1, "Unsupported export schema")
    study = identifier(document["study"]["id"])
    tables = {table: rows_by_id(document, table) for table in TABLES}
    people, devices, protocols, versions, sessions, trials, files = (tables[t] for t in TABLES)
    for person in people.values():
        require(person["study_id"] == study, "Participant study mismatch")
    for protocol in protocols.values():
        require(protocol["study_id"] == study, "Protocol study mismatch")
    for version in versions.values():
        require(version["protocol_id"] in protocols and version["schema_version"] == 1, "Invalid protocol version")
    plans = {}
    for session in sessions.values():
        version = versions[session["protocol_version_id"]]
        require(session["study_id"] == study and session["participant_id"] in people, "Session ownership mismatch")
        require(version["status"] == "published", "Session uses unpublished version")
        if session.get("protocol_id") is not None:
            require(session["protocol_id"] == version["protocol_id"], "Session protocol mismatch")
        definition = next(s for s in version["document"]["sessions"] if s["id"] == session["session_definition_id"])
        quota = Counter()
        tasks = {}
        for task in definition["tasks"]:
            tasks[task["id"]] = task
            for kind, repetitions in [(task["task_type"], task["repetitions"]), ("practice", task.get("practice_repetitions", 0))]:
                for repetition in range(1, repetitions + 1):
                    quota[(task["id"], kind, repetition)] += 1
        plans[session["id"]] = (tasks, quota, Counter())
    for trial in trials.values():
        session = sessions[trial["session_id"]]
        require(trial["schema_version"] == 1 and trial["physical_device_id"] in devices, "Invalid trial schema/device")
        for field in ("study_id", "participant_id", "protocol_version_id"):
            require(trial[field] == session[field], "Trial ownership/version mismatch")
        tasks, quota, observed = plans[session["id"]]
        task = tasks[trial["task_id"]]
        for field in ("prompt", "posture", "device_role"):
            require(trial[field] == task[field], "Trial differs from pinned task")
        slot = (trial["task_id"], trial["task_type"], trial["repetition"])
        observed[slot] += 1
        require(observed[slot] <= quota[slot], "Trial repetition quota exceeded")
    root = Path(raw_root).resolve()
    seen_trials = set()
    verified = pending = 0
    synced_trials = set()
    for manifest in files.values():
        trial = trials[manifest["trial_id"]]
        require(trial["id"] not in seen_trials, "Duplicate file for trial")
        seen_trials.add(trial["id"])
        expected = f"study/{study}/{trial['participant_id']}/{trial['session_id']}/{trial['id']}/sensors.csv.gz"
        require(manifest["object_key"] == expected, "Raw path differs from UUID hierarchy")
        require(manifest["content_type"] == "application/gzip", "Invalid file content type")
        require(manifest["sync_status"] in {"local", "queued", "uploading", "failed", "synced"}, "Invalid sync status")
        if manifest["sync_status"] != "synced":
            pending += 1
            continue
        require(manifest["uploaded_at"] is not None, "Verified file lacks upload time")
        if export_paths is not None:
            require(trial['id'] in export_paths, 'Verified file missing from export manifests')
            entry = export_paths[trial['id']]
            for field in ('study_id', 'participant_id', 'session_id', 'physical_device_id', 'protocol_version_id', 'schema_version'):
                require(entry[field] == trial[field], 'Export manifest identity mismatch')
            for field in ('object_key', 'size_bytes', 'sha256'):
                require(entry[field] == manifest[field], 'Export manifest file mismatch')
            expected = entry['path']
            require(not Path(expected).is_absolute() and '..' not in Path(expected).parts, 'Unsafe readable path')
        path = (root / expected).resolve()
        require(path.is_relative_to(root), "Raw file escapes dataset directory")
        require(path.is_file(), "Missing verified raw file")
        verify_raw(path, manifest, trial)
        synced_trials.add(trial["id"])
        verified += 1
    require(seen_trials == set(trials), "Trial lacks a file manifest")
    for session in sessions.values():
        if session["completed_at"] is not None:
            _, quota, observed = plans[session["id"]]
            require(quota == observed, "Completed session has missing tasks")
            require(all(t["id"] in synced_trials for t in trials.values() if t["session_id"] == session["id"]), "Completed session has unverified files")
    return {"verified_files": verified, "pending_files": pending, "trials": len(trials), "sessions": len(sessions)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("metadata", type=Path)
    parser.add_argument("raw_root", type=Path)
    parser.add_argument("--manifest", type=Path, action="append", default=[], help="Readable path manifest; repeat for multiple ZIP parts")
    args = parser.parse_args()
    try:
        text = args.metadata.read_text(encoding="utf-8")
        document = json.loads(text)
        paths = None
        if args.manifest:
            paths = {}
            for filename in args.manifest:
                manifest = json.loads(filename.read_text(encoding="utf-8"))
                require(manifest['manifest_version'] == 1, 'Unsupported path manifest')
                require(manifest['metadata_sha256'] == hashlib.sha256(text.encode()).hexdigest(), 'Manifest snapshot mismatch')
                for entry in manifest['files']:
                    previous = paths.get(entry['trial_id'])
                    require(previous is None or previous == entry, 'Conflicting path manifests')
                    paths[entry['trial_id']] = entry
        print(json.dumps(verify_dataset(document, args.raw_root, paths), sort_keys=True))
    except (ValueError, KeyError, TypeError, OSError, StopIteration, EOFError) as error:
        parser.exit(1, f"Dataset verification failed: {type(error).__name__}: {error}\n")


if __name__ == "__main__":
    main()

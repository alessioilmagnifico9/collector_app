import copy
import gzip
import hashlib
from pathlib import Path
import tempfile
import unittest

from verify_dataset import HEADER, verify_dataset


def uid(n):
    return f"00000000-0000-4000-8000-{n:012d}"


class IntegrityTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.task = {"id": uid(7), "prompt": "Move", "posture": "seated", "device_role": "personal", "task_type": "genuine", "repetitions": 1}
        self.document = {
            "export_schema_version": 1, "study": {"id": uid(1)},
            "participants": [{"id": uid(2), "study_id": uid(1)}],
            "devices": [{"id": uid(3)}],
            "protocols": [{"id": uid(4), "study_id": uid(1)}],
            "protocol_versions": [{"id": uid(5), "protocol_id": uid(4), "schema_version": 1, "status": "published", "document": {"sessions": [{"id": uid(6), "tasks": [self.task]}]}}],
            "sessions": [{"id": uid(8), "study_id": uid(1), "participant_id": uid(2), "protocol_version_id": uid(5), "session_definition_id": uid(6), "completed_at": "2026-09-25T10:00:00Z"}],
            "trials": [{"id": uid(9), "study_id": uid(1), "participant_id": uid(2), "session_id": uid(8), "protocol_version_id": uid(5), "physical_device_id": uid(3), "schema_version": 1, "task_id": uid(7), "prompt": "Move", "posture": "seated", "device_role": "personal", "task_type": "genuine", "repetition": 1, "quality": {"sensors": [{"sensor_type": "accelerometer", "sample_count": 2}]}}],
            "trial_files": [{"id": uid(10), "trial_id": uid(9), "object_key": f"study/{uid(1)}/{uid(2)}/{uid(8)}/{uid(9)}/sensors.csv.gz", "content_type": "application/gzip", "sync_status": "synced", "uploaded_at": "2026-09-25T10:00:00Z"}],
        }
        self.raw = HEADER + "\n9007199254740993,accelerometer,1,2,3,,3\n9007199264740993,accelerometer,1,2,3,,3\n"
        self.write_raw(self.raw)

    def write_raw(self, raw):
        manifest = self.document["trial_files"][0]
        self.path = self.root / manifest["object_key"]
        self.path.parent.mkdir(parents=True, exist_ok=True)
        data = gzip.compress(raw.encode(), mtime=0)
        self.path.write_bytes(data)
        manifest.update(size_bytes=len(data), sha256=hashlib.sha256(data).hexdigest())

    def test_valid_large_timestamps_and_repeatable_verification(self):
        first = verify_dataset(self.document, self.root)
        self.assertEqual(first["verified_files"], 1)
        self.assertEqual(first, verify_dataset(self.document, self.root))

    def test_readable_paths_verify_original_bytes_and_reject_mismatched_manifest(self):
        trial = self.document['trials'][0]
        file = self.document['trial_files'][0]
        readable = 'study-test/participant-000001/session-01-attempt-01/task-001/genuine-repetition-001.csv.gz'
        entry = {**trial, **file, 'path': readable}
        target = self.root / readable
        target.parent.mkdir(parents=True)
        self.path.rename(target)
        self.assertEqual(verify_dataset(self.document, self.root, {trial['id']: entry})['verified_files'], 1)
        with self.assertRaisesRegex(ValueError, 'missing from export manifests'):
            verify_dataset(self.document, self.root, {})
        for field in ('participant_id', 'physical_device_id', 'sha256', 'object_key'):
            bad = {**entry, field: 'invalid'}
            with self.assertRaisesRegex(ValueError, 'manifest .* mismatch'):
                verify_dataset(self.document, self.root, {trial['id']: bad})
        with self.assertRaisesRegex(ValueError, 'Unsafe readable path'):
            verify_dataset(self.document, self.root, {trial['id']: {**entry, 'path': '../outside'}})

    def test_tamper_missing_and_traversal_fail(self):
        self.path.write_bytes(b"bad")
        with self.assertRaisesRegex(ValueError, "size mismatch"):
            verify_dataset(self.document, self.root)
        self.path.unlink()
        with self.assertRaisesRegex(ValueError, "Missing verified"):
            verify_dataset(self.document, self.root)
        self.document["trial_files"][0]["object_key"] = "../../outside"
        with self.assertRaisesRegex(ValueError, "UUID hierarchy"):
            verify_dataset(self.document, self.root)

    def test_nonmonotonic_nan_and_incomplete_raw_fail(self):
        for bad in [self.raw.replace("9007199264740993", "9007199254740993"), self.raw.replace(",1,2,3,", ",NaN,2,3,"), self.raw.rstrip("\n")]:
            self.write_raw(bad)
            with self.assertRaises(ValueError):
                verify_dataset(self.document, self.root)

    def test_counts_relations_and_duplicate_trials_fail(self):
        baseline = copy.deepcopy(self.document)
        for mutate in [lambda d: d["trials"][0]["quality"]["sensors"][0].update(sample_count=4), lambda d: d["trials"][0].update(participant_id=uid(99)), lambda d: d["trials"].append(d["trials"][0])]:
            document = copy.deepcopy(baseline)
            mutate(document)
            with self.assertRaises(ValueError):
                verify_dataset(document, self.root)

    def test_pending_files_are_explicit_and_cannot_complete_session(self):
        self.path.unlink()
        self.document["trial_files"][0]["sync_status"] = "failed"
        with self.assertRaisesRegex(ValueError, "unverified"):
            verify_dataset(self.document, self.root)
        self.document["sessions"][0]["completed_at"] = None
        self.assertEqual(verify_dataset(self.document, self.root)["pending_files"], 1)


if __name__ == "__main__":
    unittest.main()

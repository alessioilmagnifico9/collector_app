import copy
import hashlib
import io
import json
from pathlib import Path
import tempfile
import unittest
from download_dataset import download, validate_plan

ID = '00000000-0000-4000-8000-000000000001'
PATH = f'study-{ID}/participant-000001/session-01-attempt-01/task-001/genuine-repetition-001-recording-{ID}.csv.gz'


def plan_fixture():
    entry = {'path': PATH, 'trial_id': ID, 'study_id': ID, 'participant_id': ID,
             'session_id': ID, 'physical_device_id': ID, 'protocol_version_id': ID,
             'protocol_version': 1, 'schema_version': 1,
             'object_key': f'study/{ID}/{ID}/{ID}/{ID}/sensors.csv.gz',
             'size_bytes': 3, 'sha256': hashlib.sha256(b'raw').hexdigest()}
    metadata = json.dumps({'study': {'id': ID}, 'trials': [{**entry, 'id': ID}],
                          'trial_files': [{**entry, 'sync_status': 'synced'}]})
    return {'metadata_json': metadata,
            'manifest': {'manifest_version': 1, 'metadata_sha256': hashlib.sha256(metadata.encode()).hexdigest(), 'files': [entry]}}


class DownloadTests(unittest.TestCase):
    def test_readable_root_and_legacy_plans(self):
        plan = plan_fixture()
        validate_plan(plan)
        plan['manifest']['files'][0]['path'] = PATH.replace(f'study-{ID}', 'data_test')
        validate_plan(plan)
        for root in ['CON', 'con', '..', 'a.b', 'a' * 81]:
            plan['manifest']['files'][0]['path'] = PATH.replace(f'study-{ID}', root)
            with self.assertRaises(ValueError):
                validate_plan(plan)

    def test_streamed_bytes_resume_and_mapping(self):
        plan = plan_fixture()
        authorizations = []
        with tempfile.TemporaryDirectory() as directory:
            def authorize(trial):
                authorizations.append(trial)
                return 'signed-url'
            report = download(plan, directory, authorize, lambda _: io.BytesIO(b'raw'))
            self.assertTrue(report['complete'])
            self.assertEqual((Path(directory) / PATH).read_bytes(), b'raw')
            self.assertEqual(authorizations, [ID])
            report = download(plan, directory, authorize, lambda _: self.fail('already downloaded'))
            self.assertTrue(report['complete'])
            self.assertEqual(authorizations, [ID])
            self.assertEqual((Path(directory) / 'metadata.json').read_text(), plan['metadata_json'])

    def test_failures_are_partial_and_retryable_and_do_not_leak_signed_urls(self):
        plan = plan_fixture()
        for response in [b'bad', b'raw-too-big', b'']:
            with tempfile.TemporaryDirectory() as directory:
                report = download(plan, directory, lambda _: 'SECRET', lambda _: io.BytesIO(response))
                self.assertFalse(report['complete'])
                self.assertEqual(report['failed_paths'], [PATH])
                self.assertFalse((Path(directory) / PATH).exists())
                self.assertEqual(list(Path(directory).rglob('*.partial')), [])
                self.assertNotIn('SECRET', (Path(directory) / 'export-report.json').read_text())
                self.assertTrue(download(plan, directory, lambda _: '', lambda _: io.BytesIO(b'raw'))['complete'])
        with tempfile.TemporaryDirectory() as directory:
            def denied(_):
                raise PermissionError('SECRET')
            report = download(plan, directory, denied, lambda _: self.fail('must authorize first'))
            self.assertFalse(report['complete'])

    def test_tampered_manifest_traversal_duplicates_and_snapshot_mismatch(self):
        plan = plan_fixture()
        for path in ['../outside', '/absolute', 'CON', PATH + '/../other', PATH.replace('participant-000001', 'Alice@example.com')]:
            bad = copy.deepcopy(plan)
            bad['manifest']['files'][0]['path'] = path
            with self.assertRaises(ValueError):
                validate_plan(bad)
        bad = copy.deepcopy(plan)
        bad['manifest']['files'] *= 2
        with self.assertRaises(ValueError):
            validate_plan(bad)
        bad = copy.deepcopy(plan)
        bad['manifest']['files'][0]['sha256'] = 'a' * 64
        with self.assertRaises(ValueError):
            validate_plan(bad)
        bad = copy.deepcopy(plan)
        bad['manifest']['files'] = []
        with self.assertRaises(ValueError):
            validate_plan(bad)
        with tempfile.TemporaryDirectory() as directory:
            (Path(directory) / 'metadata.json').write_text('other snapshot')
            with self.assertRaises(ValueError):
                download(plan, directory, lambda _: '', lambda _: io.BytesIO(b'raw'))

    def test_symlink_escape_does_not_write_outside_destination(self):
        with tempfile.TemporaryDirectory() as directory, tempfile.TemporaryDirectory() as outside:
            (Path(directory) / f'study-{ID}').symlink_to(outside, target_is_directory=True)
            report = download(plan_fixture(), directory, lambda _: '', lambda _: io.BytesIO(b'raw'))
            self.assertFalse(report['complete'])
            self.assertEqual(list(Path(outside).iterdir()), [])


if __name__ == '__main__':
    unittest.main()

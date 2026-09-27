#!/usr/bin/env python3
"""Stream a frozen admin export plan to readable paths, authorizing each file."""
import argparse
import getpass
import hashlib
import json
import os
from pathlib import Path
import re
import tempfile
import urllib.request
import urllib.parse


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def validate_plan(plan):
    metadata_text = plan['metadata_json']
    metadata = json.loads(metadata_text)
    manifest = plan['manifest']
    if manifest['manifest_version'] != 1 or hashlib.sha256(metadata_text.encode()).hexdigest() != manifest['metadata_sha256']:
        raise ValueError('Invalid manifest or metadata digest')
    files = {f['trial_id']: f for f in metadata['trial_files'] if f['sync_status'] == 'synced'}
    trials = {t['id']: t for t in metadata['trials']}
    seen, paths = set(), set()
    for entry in manifest['files']:
        path = entry['path']
        # Portable study label (or legacy UUID root); remaining segments are generated.
        if not re.fullmatch(r'[a-z0-9][a-z0-9_-]{0,79}/participant-(?:[0-9]+|legacy-[0-9a-f-]{36})/session-[0-9]+-attempt-[0-9]+/task-[0-9]+/(?:practice|genuine|impostor)-repetition-[0-9]+-recording-[0-9a-f-]{36}\.csv\.gz', path):
            raise ValueError('Unsafe export path')
        root_label = path.split('/')[0]
        if re.fullmatch(r'(con|prn|aux|nul|com[0-9]|lpt[0-9])', root_label):
            raise ValueError('Reserved export folder')
        trial_id = entry['trial_id']
        trial, file = trials[trial_id], files[trial_id]
        if trial_id in seen or path in paths:
            raise ValueError('Duplicate export entry')
        seen.add(trial_id)
        paths.add(path)
        for key in ('study_id', 'participant_id', 'session_id', 'physical_device_id', 'protocol_version_id', 'schema_version'):
            if entry[key] != trial[key]:
                raise ValueError('Manifest trial mismatch')
        for key in ('object_key', 'size_bytes', 'sha256'):
            if entry[key] != file[key]:
                raise ValueError('Manifest file mismatch')
        if entry['study_id'] != metadata['study']['id'] or entry['size_bytes'] <= 0:
            raise ValueError('Invalid study or file size')
    if seen != set(files):
        raise ValueError('Plan must include every verified file in its snapshot')
    return metadata_text, manifest


def safe_target(root, path):
    target = root / path
    for parent in (target, *target.parents):
        if parent == root.parent:
            break
        if parent.is_symlink():
            raise ValueError('Symlinks are not allowed in export paths')
    if not target.resolve().is_relative_to(root.resolve()):
        raise ValueError('Export path escapes destination')
    return target


def digest_file(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def download(plan, destination, authorize, fetch):
    metadata_text, manifest = validate_plan(plan)
    root = Path(destination).absolute()
    if root.is_symlink():
        raise ValueError('Destination must not be a symlink')
    root.mkdir(parents=True, exist_ok=True)
    for name, text in [('metadata.json', metadata_text), ('manifest.json', json.dumps(manifest, indent=2))]:
        target = safe_target(root, name)
        if target.exists():
            if target.read_text() != text:
                raise ValueError('Destination belongs to another snapshot')
        else:
            target.write_text(text, encoding='utf-8')
    saved, failed = [], []
    for entry in manifest['files']:
        temporary = None
        try:
            target = safe_target(root, entry['path'])
            if target.exists():
                if target.stat().st_size != entry['size_bytes'] or digest_file(target) != entry['sha256']:
                    raise ValueError('Existing file conflicts with snapshot')
            else:
                url = authorize(entry['trial_id'])
                target.parent.mkdir(parents=True, exist_ok=True)
                digest, size = hashlib.sha256(), 0
                with fetch(url) as response, tempfile.NamedTemporaryFile(dir=target.parent, suffix='.partial', delete=False) as output:
                    temporary = Path(output.name)
                    for chunk in iter(lambda: response.read(1024 * 1024), b''):
                        size += len(chunk)
                        if size > entry['size_bytes']:
                            raise ValueError('Oversize response')
                        digest.update(chunk)
                        output.write(chunk)
                    output.flush()
                    os.fsync(output.fileno())
                if size != entry['size_bytes'] or digest.hexdigest() != entry['sha256']:
                    raise ValueError('Downloaded bytes do not match snapshot')
                temporary.replace(target)
                temporary = None
            saved.append(entry['path'])
        except Exception:
            # Never persist tokens, signed URLs, response bodies or credential-bearing exceptions.
            failed.append(entry['path'])
        finally:
            if temporary is not None:
                temporary.unlink(missing_ok=True)
    report = {'complete': not failed, 'saved_paths': saved, 'failed_paths': failed}
    safe_target(root, 'export-report.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('plan', type=Path)
    parser.add_argument('destination', type=Path)
    parser.add_argument('--collector-url', required=True, help='HTTPS Supabase functions/v1/collector URL')
    args = parser.parse_args()
    endpoint = urllib.parse.urlsplit(args.collector_url)
    if endpoint.scheme != 'https' or not endpoint.hostname or endpoint.username or endpoint.query or endpoint.fragment:
        parser.error('Use an HTTPS collector URL without credentials or query parameters')
    token = os.environ.get('COLLECTOR_RESEARCHER_TOKEN') or getpass.getpass('Researcher access token (not enrollment code): ')
    opener = urllib.request.build_opener(NoRedirect())

    def authorize(trial_id):
        request = urllib.request.Request(args.collector_url,
            data=json.dumps({'action': 'download_trial', 'trial_id': trial_id}).encode(),
            headers={'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'})
        with opener.open(request, timeout=30) as response:
            result = json.loads(response.read(65536))
        url = result['download_url']
        parsed = urllib.parse.urlsplit(url)
        if parsed.scheme != 'https' or not (parsed.hostname or '').endswith('.r2.cloudflarestorage.com') or parsed.username:
            raise ValueError('Untrusted raw download URL')
        return url

    report = download(json.loads(args.plan.read_text()), args.destination, authorize,
                      lambda url: opener.open(url, timeout=60))
    print(f"{'Complete' if report['complete'] else 'PARTIAL'}: {len(report['saved_paths'])} saved, {len(report['failed_paths'])} failed. See export-report.json.")
    return 0 if report['complete'] else 1


if __name__ == '__main__':
    raise SystemExit(main())

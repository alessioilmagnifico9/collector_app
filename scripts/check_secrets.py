#!/usr/bin/env python3
"""Check ignore rules, privileged client configuration and recognizable secrets."""

import base64
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SKIP = {".git", ".tooling", ".dart_tool", "build", "node_modules", "Pods", ".symlinks", "__pycache__"}


def has_private_material(contents):
    if re.search(rb"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----", contents):
        return True
    if re.search(rb"sb_secret_[A-Za-z0-9_-]{20,}", contents):
        return True
    for match in re.finditer(rb"eyJ[A-Za-z0-9_-]+\.([A-Za-z0-9_-]+)\.[A-Za-z0-9_-]+", contents):
        try:
            payload = match.group(1)
            decoded = json.loads(base64.urlsafe_b64decode(payload + b"=" * (-len(payload) % 4)))
            if isinstance(decoded, dict) and decoded.get("role") == "service_role":
                return True
        except (ValueError, UnicodeDecodeError):
            continue
    return False


def main():
    with tempfile.TemporaryDirectory(prefix="collector-ignore-") as directory:
        subprocess.run(["git", "init", "-q", directory], check=True)
        shutil.copyfile(ROOT / ".gitignore", Path(directory) / ".gitignore")
        for filename in [
            ".env", "supabase/functions/.env", "apps/mobile/.env.production",
            "release.jks", "signing.p12", "apps/mobile/android/key.properties",
        ]:
            subprocess.run(["git", "-C", directory, "check-ignore", "-q", filename], check=True)
        for filename in [".env.example", "supabase/functions/.env.example"]:
            result = subprocess.run(["git", "-C", directory, "check-ignore", "-q", filename])
            if result.returncode != 1:
                raise SystemExit(f"Example must remain versionable: {filename}")

    for base in [ROOT / "apps", ROOT / "packages"]:
        for source in base.rglob("*.dart"):
            if SKIP.intersection(source.relative_to(ROOT).parts):
                continue
            contents = source.read_text()
            for forbidden in ["SUPABASE_SERVICE_ROLE_KEY", "R2_ACCESS_KEY_ID", "R2_SECRET_ACCESS_KEY"]:
                if forbidden in contents:
                    raise SystemExit(f"Privileged configuration in client source: {source.relative_to(ROOT)}")

    # Never print matching values, and do not read private local environment files.
    for directory, folders, filenames in os.walk(ROOT):
        folders[:] = [name for name in folders if name not in SKIP]
        for filename in filenames:
            source = Path(directory) / filename
            relative = source.relative_to(ROOT)
            if source.name.startswith(".env") and source.name != ".env.example":
                continue
            if source.name == "key.properties" or source.suffix in {".jks", ".p12", ".keystore", ".mobileprovision"}:
                continue
            if has_private_material(source.read_bytes()):
                raise SystemExit(f"Recognizable private material in source: {relative}")

    history = subprocess.run(["git", "-C", str(ROOT), "rev-parse", "--is-inside-work-tree"], capture_output=True)
    if history.returncode == 0:
        objects = subprocess.check_output(["git", "-C", str(ROOT), "rev-list", "--objects", "--all"]).splitlines()
        for item in objects:
            oid = item.split(b" ", 1)[0].decode("ascii")
            kind = subprocess.check_output(["git", "-C", str(ROOT), "cat-file", "-t", oid]).strip()
            if kind == b"blob" and has_private_material(subprocess.check_output(["git", "-C", str(ROOT), "cat-file", "blob", oid])):
                raise SystemExit(f"Recognizable private material in history blob {oid}")
        print("Recognizable-secret history scan passed.")
    else:
        print("Git history scan unavailable: no usable checkout metadata.")
    print("Secret ignore rules, client boundaries and recognizable-secret source scan passed.")


if __name__ == "__main__":
    main()

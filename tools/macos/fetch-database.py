import hashlib
import json
import shutil
import urllib.request
import zipfile
from pathlib import Path


def download(url, target):
    request = urllib.request.Request(url, headers={'User-Agent': 'HordesOfAzeroth-macOS-dev'})
    temporary = target.with_suffix(target.suffix + '.download')
    with urllib.request.urlopen(request, timeout=60) as response, temporary.open('wb') as output:
        shutil.copyfileobj(response, output)
    temporary.replace(target)


def main():
    root = Path(__file__).resolve().parents[2]
    downloads = root / 'server/downloads'
    downloads.mkdir(parents=True, exist_ok=True)
    manifest_path = root / 'server/manifest-linux.json'
    if not manifest_path.exists():
        download('https://github.com/jonhaldors/hordes-of-azeroth/releases/latest/download/manifest-linux.json',
                 manifest_path)
    manifest = json.loads(manifest_path.read_text())
    print(f"Using database packages from {manifest['version']}", flush=True)
    for package in manifest['packages']:
        if package['name'] not in ('base-db', 'world-db'):
            continue
        archive = downloads / (package['name'] + '.zip')
        if not archive.exists() or hashlib.sha256(archive.read_bytes()).hexdigest() != package['sha256']:
            print(f"Downloading {package['name']}", flush=True)
            download(package['url'], archive)
        if hashlib.sha256(archive.read_bytes()).hexdigest() != package['sha256']:
            raise RuntimeError(f'Checksum mismatch: {archive}')
        with zipfile.ZipFile(archive) as contents:
            for entry in package['files']:
                target = (root / entry['path']).resolve()
                if not target.is_relative_to(root / 'server/sql'):
                    raise RuntimeError(f"Unexpected SQL destination: {entry['path']}")
                data = contents.read(entry['path'])
                if hashlib.sha256(data).hexdigest() != entry['sha256']:
                    raise RuntimeError(f"Checksum mismatch: {entry['path']}")
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(data)
                print(f"Verified {entry['path']}", flush=True)


if __name__ == '__main__':
    main()

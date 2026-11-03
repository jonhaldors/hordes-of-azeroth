import argparse
import json
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('client', type=Path)
    args = parser.parse_args()
    source = args.client.resolve()
    if source.name.lower() == 'data':
        source = source.parent
    if not (source / 'Data/dbc.MPQ').is_file():
        parser.error('Expected a 1.12.1 game folder or its Data folder.')
    root = Path(__file__).resolve().parents[2]
    data = root / 'Data'
    if data.is_symlink():
        parser.error('The project Data folder must be local so generated patches cannot change the source client.')
    data.mkdir(exist_ok=True)
    for archive in (source / 'Data').iterdir():
        if archive.suffix.lower() != '.mpq' or archive.name.lower() in ('patch-z.mpq', 'patch-3.mpq'):
            continue
        target = data / archive.name
        if target.exists() or target.is_symlink():
            if not target.is_symlink() or target.resolve() != archive.resolve():
                parser.error(f'Existing data file has a different source: {target}')
        else:
            target.symlink_to(archive)
    executable = root / 'WoW.exe'
    if not executable.exists() and (source / 'WoW.exe').is_file():
        executable.symlink_to(source / 'WoW.exe')
    local = root / '.devtools'
    local.mkdir(exist_ok=True)
    (local / 'macos-client.json').write_text(json.dumps({'source': str(source)}, indent=2) + '\n')
    print(f'Local client data: {data}; original archives remain at {source}')


if __name__ == '__main__':
    main()

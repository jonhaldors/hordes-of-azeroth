import argparse
import concurrent.futures
import json
import subprocess
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--threads', type=int, default=6)
    args = parser.parse_args()
    if args.threads < 1:
        parser.error('--threads must be positive')

    root = Path(__file__).resolve().parents[2]
    data = root / 'server/data'
    tools = root / 'server/run/Extractors'
    generator = tools / 'MoveMapGenerator'
    if not generator.is_file() or not (data / 'vmaps/001.vmtree').is_file():
        parser.error('Build the server and extract the client data first.')
    (data / 'mmaps').mkdir(exist_ok=True)
    options = ['--silent', '--offMeshInput', str(tools / 'offmesh.txt'),
               '--configInputPath', str(tools / 'config.json')]

    def generate(job):
        map_id, tile = job
        arguments = [str(generator), map_id]
        if tile is not None:
            arguments += ['--tile', tile]
        arguments += ['--threads', '1' if tile is not None else str(args.threads)] + options
        result = subprocess.run(arguments, cwd=data, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, text=True)
        if result.returncode:
            raise RuntimeError(f'Map {map_id}, tile {tile}: {result.stdout[-4000:]}')

    groups = json.loads((root / 'config/navtiles.json').read_text())['groups']
    for group in groups:
        tiles = []
        whole_maps = []
        for map_id, entries in group['maps'].items():
            if isinstance(entries, str):
                if not list((data / 'mmaps').glob(f'{int(map_id):03}*.mmtile')):
                    whole_maps.append((map_id, None))
            else:
                for tile in entries:
                    x, y = map(int, tile.split(','))
                    output = data / 'mmaps' / f'{int(map_id):03}{y:02}{x:02}.mmtile'
                    if not output.is_file() or output.stat().st_size == 0:
                        tiles.append((map_id, tile))
        print(f"{group['name']}: {len(tiles)} tiles, {len(whole_maps)} whole maps", flush=True)
        for job in whole_maps:
            generate(job)
        with concurrent.futures.ThreadPoolExecutor(max_workers=args.threads) as pool:
            futures = [pool.submit(generate, job) for job in tiles]
            for count, future in enumerate(concurrent.futures.as_completed(futures), 1):
                future.result()
                if count % 10 == 0 or count == len(tiles):
                    print(f"{group['name']}: {count}/{len(tiles)} tiles complete", flush=True)
    print('Navigation mesh generation finished.', flush=True)


if __name__ == '__main__':
    main()

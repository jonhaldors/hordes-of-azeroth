#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
source_folder="${1:-${WOW_DATA:-}}"
data="$root/server/data"
extractors="$root/server/run/Extractors"

if [ "$#" -gt 1 ] || [ -z "$source_folder" ]; then
    echo "Usage: bash tools/macos/extract-client-data.sh '/path/to/World of Warcraft'" >&2
    echo "You can also pass the Data folder directly, or set WOW_DATA." >&2
    exit 1
fi

if [ "$(basename "$source_folder")" = Data ]; then
    source_folder="$(dirname "$source_folder")"
fi

if [ ! -f "$source_folder/Data/dbc.MPQ" ] || [ ! -f "$source_folder/Data/terrain.MPQ" ]; then
    echo "Expected a 1.12.1 client with Data/dbc.MPQ and Data/terrain.MPQ: $source_folder" >&2
    exit 1
fi
source_folder="$(cd "$source_folder" && pwd)"

for tool in MapExtractor VMapExtractor VMapAssembler; do
    if [ ! -x "$extractors/$tool" ]; then
        echo "Build the server tools first: bash tools/macos/build-server.sh" >&2
        exit 1
    fi
done

if [ -f "$data/Buildings/dir" ] || [ -f "$data/Buildings/dir_bin" ]; then
    echo "VMap extraction has already written $data/Buildings. Inspect the existing extraction before rerunning." >&2
    exit 1
fi

mkdir -p "$data/5875/dbc" "$data/vmaps"
cd "$data"

"$extractors/MapExtractor" -i "$source_folder" --silent
if [ ! -s dbc/Spell.dbc ] || [ ! -s dbc/Map.dbc ]; then
    echo "Extraction did not produce the required DBC files." >&2
    exit 1
fi
mv dbc/*.dbc 5875/dbc/
rmdir dbc

"$extractors/VMapExtractor" -d "$source_folder/Data" --silent
"$extractors/VMapAssembler" Buildings vmaps --silent

echo "DBC, maps and vmaps extracted into $data"
echo "Navigation meshes and the project's generated spell effects still need to be built."

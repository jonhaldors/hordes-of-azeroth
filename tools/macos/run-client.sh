#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
binary="$root/client/target/release/HordesOfAzeroth"
data="${1:-${WOW_DATA:-$root/Data}}"

if [ "$#" -gt 1 ] || [ -z "$data" ]; then
    echo "Usage: bash tools/macos/run-client.sh '/path/to/World of Warcraft'" >&2
    echo "You can also pass the Data folder directly, or set WOW_DATA." >&2
    exit 1
fi

if [ -d "$data/Data" ]; then
    data="$data/Data"
fi

if [ ! -d "$data" ]; then
    echo "Game data folder does not exist: $data" >&2
    exit 1
fi

if [ ! -x "$binary" ]; then
    echo "Build the client first: bash tools/macos/build-client.sh" >&2
    exit 1
fi

export WOW_DATA="$(cd "$data" && pwd)"
export WGPU_BACKEND=metal
export BENILLA_HOME="${BENILLA_HOME:-$root/client/benilla-config}"
export WOW_HOST="${WOW_HOST:-127.0.0.1}"

if [ "${WOW_UNATTENDED:-0}" = 1 ]; then
    : "${WOW_USER:?Set a dedicated test account for an unattended run.}"
    : "${WOW_PASS:?Set the test account password for an unattended run.}"
else
    export WOW_USER="${WOW_USER:-player}"
    export WOW_PASS="${WOW_PASS:-player}"
fi

mkdir -p "$BENILLA_HOME/AddOns"
addon="$BENILLA_HOME/AddOns/HordesOfAzeroth"
if [ ! -e "$addon" ] && [ ! -L "$addon" ]; then
    ln -s "$root/Interface/AddOns/HordesOfAzeroth" "$addon"
fi

python3 - "$root" <<'PY'
import json
import os
import sys
from pathlib import Path

root = Path(sys.argv[1])
glue = root / 'Interface/GlueXML'
values = {'BONK_ACCOUNT': os.environ['WOW_USER'], 'BONK_PASSWORD': os.environ['WOW_PASS'], 'HOA_LANGUAGE': 'enUS'}
(glue / 'BonkAccount.lua').write_text(''.join(f'{key} = {json.dumps(value, ensure_ascii=False)};\n' for key, value in values.items()))
stats = glue / 'BonkStats.lua'
if not stats.exists():
    stats.write_text('BONK_STATS = nil;\n')
config = Path(os.environ['BENILLA_HOME']) / 'config.toml'
if not config.exists():
    config.write_text('[cvars]\nreadEULA = "1"\nreadTOS = "1"\nmovie = "0"\nrealmList = "127.0.0.1"\nrealmName = "Hordes of Azeroth"\nshowTutorials = "0"\n')
PY

cd "$root/client"
exec "$binary"

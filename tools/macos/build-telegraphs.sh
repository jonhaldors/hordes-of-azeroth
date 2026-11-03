#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
if [ "$#" -ne 1 ]; then
    echo "Usage: bash tools/macos/build-telegraphs.sh '/path/to/World of Warcraft'" >&2
    exit 1
fi
python3 "$root/tools/macos/prepare-client.py" "$1"

if [ -n "${DOTNET:-}" ]; then
    dotnet="$DOTNET"
elif [ -x "$root/.devtools/dotnet/dotnet" ]; then
    dotnet="$root/.devtools/dotnet/dotnet"
else
    dotnet=dotnet
fi
export DOTNET_CLI_HOME="$root/.devtools/dotnet-home"
export NUGET_PACKAGES="$root/.devtools/nuget"
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1

"$dotnet" build "$root/tools/telegraphs/TelegraphKit.csproj" -c Release --ignore-failed-sources
"$dotnet" "$root/tools/telegraphs/bin/TelegraphKit.dll" build "$root"
"$dotnet" "$root/tools/telegraphs/bin/TelegraphKit.dll" check "$root"

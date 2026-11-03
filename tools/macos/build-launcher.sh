#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"

if [ "$(uname -s)" != Darwin ] || [ "$(uname -m)" != arm64 ]; then
    echo "Build the macOS launcher from a native Apple Silicon terminal." >&2
    exit 1
fi

if [ -n "${DOTNET:-}" ]; then
    dotnet="$DOTNET"
elif [ -x "$root/.devtools/dotnet/dotnet" ]; then
    dotnet="$root/.devtools/dotnet/dotnet"
elif command -v dotnet >/dev/null 2>&1; then
    dotnet="$(command -v dotnet)"
else
    echo "Install the .NET 10 SDK, or set DOTNET to its dotnet executable." >&2
    exit 1
fi

cd "$root"
export DOTNET_CLI_HOME="$root/.devtools/dotnet-home"
export NUGET_PACKAGES="$root/.devtools/nuget"
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export AVALONIA_TELEMETRY_OPTOUT=1
"$dotnet" publish tools/launcher/HordesOfAzerothLauncher.csproj -c Release -r osx-arm64 -o release/macos/launcher "$@"

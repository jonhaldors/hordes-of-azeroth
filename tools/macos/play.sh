#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
python3 "$root/tools/macos/server.py" start
exec bash "$root/tools/macos/run-client.sh" "$@"

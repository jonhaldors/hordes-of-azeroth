#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"

if [ "$(uname -s)" != Darwin ] || [ "$(uname -m)" != arm64 ]; then
    echo "Build the macOS client from a native Apple Silicon terminal." >&2
    exit 1
fi

if ! command -v cargo >/dev/null 2>&1; then
    echo "Install Rust from https://rustup.rs and the Xcode command line tools first." >&2
    exit 1
fi

if [ ! -f "$root/client/crates/hoa/Cargo.toml" ]; then
    echo "Get the client source first: git submodule update --init client" >&2
    exit 1
fi

cd "$root/client"
cargo build --locked --release -p hoa

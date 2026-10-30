#!/bin/bash
set -euo pipefail

part="${1:-all}"
client_source="$2"
server_source="$3"
out="$4"
work=/root/hoa-build
packages="build-essential cmake git curl ca-certificates pkg-config patchelf rsync \
    libmariadb-dev libmariadb-dev-compat libssl-dev zlib1g-dev \
    libasound2-dev libudev-dev libwayland-dev libxkbcommon-dev clang"

install_packages() {
    local stamp="$work/packages.txt"
    if [ -f "$stamp" ] && [ "$(cat "$stamp")" = "$packages" ]; then return; fi
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq >/dev/null
    apt-get install -y -qq --no-install-recommends $packages >/dev/null 2>&1
    echo "$packages" > "$stamp"
}

sync_source() {
    mkdir -p "$2"
    rsync -a --delete --exclude=.git --exclude=/target "$1/" "$2/"
}

build_server() {
    sync_source "$server_source" "$work/src/server"
    cmake -S "$work/src/server" -B "$work/cache/server" -DCMAKE_BUILD_TYPE=Release -DBUILD_EXTRACTORS=1 -DBUILD_FOR_HOST_CPU=OFF \
        -DCMAKE_INSTALL_PREFIX="$work/install/server" >/dev/null
    if ! cmake --build "$work/cache/server" -j"$(nproc)" -- -k > "$work/server-build.log" 2>&1; then
        grep -E ': error:|undefined reference' "$work/server-build.log" | sort -u
        echo 'Linux server build failed' >&2
        exit 1
    fi
    rm -rf "$work/install/server"
    cmake --install "$work/cache/server" >/dev/null
    local bin="$work/install/server/bin"
    cp -L "$(ldconfig -p | awk '/libmariadb\.so\.3 /{print $NF; exit}')" "$bin/"
    for binary in "$bin/mangosd" "$bin/realmd"; do patchelf --set-rpath '$ORIGIN' "$binary"; done
    strip "$bin/mangosd" "$bin/realmd" "$bin"/Extractors/*Extractor "$bin/Extractors/VMapAssembler" "$bin/Extractors/MoveMapGenerator"
    rm -rf "$out/server"
    mkdir -p "$out/server"
    cp -a "$work/install/server/." "$out/server/"
}

build_client() {
    if [ ! -x "$HOME/.cargo/bin/cargo" ]; then
        curl -sSf https://sh.rustup.rs | sh -s -- -y -q --default-toolchain none >/dev/null
    fi
    . "$HOME/.cargo/env"
    sync_source "$client_source" "$work/src/client"
    cd "$work/src/client"
    rustup toolchain install --profile minimal >/dev/null 2>&1
    if ! CARGO_TARGET_DIR="$work/cache/client" cargo build --profile ship --locked -p hoa --no-default-features > "$work/client-build.log" 2>&1; then
        grep -E -A5 '^error' "$work/client-build.log"
        echo 'Linux client build failed' >&2
        exit 1
    fi
    grep -E 'Finished' "$work/client-build.log"
    mkdir -p "$out/client"
    cp "$work/cache/client/ship/HordesOfAzeroth" "$out/client/"
    strip "$out/client/HordesOfAzeroth"
}

mkdir -p "$work"
install_packages

case "$part" in
    server) build_server ;;
    client) build_client ;;
    all) build_server; build_client ;;
esac

echo "glibc floor: $(ldd --version | head -1 | awk '{print $NF}')"
find "$out" -maxdepth 3 -type f \( -name HordesOfAzeroth -o -name mangosd -o -name realmd -o -name 'libmariadb*' \) -printf '%P %s\n'

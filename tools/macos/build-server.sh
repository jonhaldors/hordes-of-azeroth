#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"

if [ "$(uname -s)" != Darwin ] || [ "$(uname -m)" != arm64 ]; then
    echo "Build the macOS server from a native Apple Silicon terminal." >&2
    exit 1
fi

for tool in brew cmake ninja; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Install Homebrew and the server dependencies: brew install cmake ninja openssl@3 mariadb@11.4" >&2
        exit 1
    fi
done

if [ ! -f "$root/server/core/CMakeLists.txt" ]; then
    echo "Get the server source first: git submodule update --init server/core" >&2
    exit 1
fi

mariadb="${MARIADB_ROOT:-$(brew --prefix mariadb@11.4)}"
openssl="${OPENSSL_ROOT_DIR:-$(brew --prefix openssl@3)}"
stage="$root/server/install-macos"
run="$root/server/run"

if [ ! -x "$mariadb/bin/mysql_config" ] || [ ! -f "$openssl/include/openssl/ssl.h" ]; then
    echo "Install the server dependencies: brew install openssl@3 mariadb@11.4" >&2
    exit 1
fi

cmake -S "$root/server/core" -B "$root/server/build-macos" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DBUILD_EXTRACTORS=ON \
    -DBUILD_FOR_HOST_CPU=OFF \
    -DCMAKE_INSTALL_PREFIX="$stage" \
    -DCONF_DIR="$stage/etc" \
    -DCMAKE_PREFIX_PATH="$openssl;$mariadb" \
    -DMYSQL_CONFIG="$mariadb/bin/mysql_config" \
    -DCPPTRACE_GET_SYMBOLS_WITH_ADDR2LINE=ON
cmake --build "$root/server/build-macos" --parallel "${BUILD_JOBS:-6}"
cmake --install "$root/server/build-macos"

mkdir -p "$run"
cp -R "$stage/bin/." "$run/"
cp "$stage/etc/mangosd.conf.dist" "$stage/etc/realmd.conf.dist" "$run/"

"$run/realmd" --version
"$run/mangosd" --version
echo "Server and extractors installed in $run"

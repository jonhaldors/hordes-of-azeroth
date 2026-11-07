#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
component="${1:-all}"

build_server() {
    cmake -S "$root/server" -B "$root/server/build" \
        -DSUPPORTED_CLIENT_BUILD=CLIENT_BUILD_1_12_1 \
        -DBUILD_EXTRACTORS=OFF -DENABLE_MAILSENDER=OFF
    cmake --build "$root/server/build" --config Release --target mangosd -j
}

build_client() {
    cargo build --release -p hoa --manifest-path "$root/client/Cargo.toml"
}

build_launcher() {
    dotnet build "$root/launcher/HordesOfAzerothLauncher.csproj" -c Release
}

check_addon() {
    command -v luajit >/dev/null || { echo "luajit not found" >&2; exit 1; }
    find "$root/addon" "$root/glue" -name '*.lua' -print0 | while IFS= read -r -d '' file; do
        luajit -bl "$file" >/dev/null
    done
    echo "addon+glue: Lua syntax ok"
}

check_content() {
    python "$root/tools/content/compile.py" --check
}

check_i18n() {
    python "$root/tools/i18n/check.py"
    python "$root/tools/i18n/build.py" --check
    python "$root/tools/i18n/gen_server_strings.py" --check
    python "$root/tools/i18n/gen_addon_locale.py" --check
    python "$root/tools/i18n/gen_client_pack.py" --check
    python "$root/tools/i18n/gen_launcher_strings.py" --check
    python "$root/tools/i18n/check_ui_xml.py"
    python "$root/tools/i18n/check_code_text.py"
    python -m unittest discover -s "$root/tools/i18n" -p "test_*.py"
}

case "$component" in
    server) build_server ;;
    client) build_client ;;
    launcher) build_launcher ;;
    addon) check_addon ;;
    i18n) check_i18n ;;
    content) check_content ;;
    check)
        cargo metadata --no-deps --format-version 1 --manifest-path "$root/client/Cargo.toml" >/dev/null
        check_addon
        check_i18n
        check_content
        ;;
    all) build_server; build_client; build_launcher; check_addon; check_i18n; check_content ;;
    *) echo "usage: $0 [all|server|client|launcher|addon|i18n|check]" >&2; exit 2 ;;
esac

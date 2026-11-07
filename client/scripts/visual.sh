#!/usr/bin/env bash
# Visual A/B harness: capture deterministic screenshots and diff them against a baseline.
#
# One client process per scenario: server-less, clutter off, a pinned camera, a fixed game clock and
# frame step (the `capture` module); `benilla-visual` diffs the PNGs. Opens a real window. Captures
# hold Blizzard-derived imagery, so they stay under the gitignored target/visual/.
#
#   scripts/visual.sh list                  # print scenario names
#   scripts/visual.sh capture <dir>         # capture every scenario into <dir>/
#   scripts/visual.sh baseline              # capture into target/visual/baseline/
#   scripts/visual.sh diff [--fail <mae>]   # capture target/visual/candidate/, diff vs baseline/
#   scripts/visual.sh selfcheck [<mae>]     # capture twice from one build; demand identical
set -euo pipefail
cd "$(dirname "$0")/.."

VIS=target/visual

build() { cargo build -q -p benilla -p benilla-visual; }

# The binary owns the scenario list (`capture/mod.rs`) and prints it under WOW_CAPTURE=list.
scenarios() { WOW_CAPTURE=list cargo run -q -p benilla; }

capture_into() {
  local dir="$1"
  mkdir -p "$dir"
  local s
  for s in $(scenarios); do
    echo "capture $s -> $dir/$s.png"
    WOW_CAPTURE="$s" WOW_CAPTURE_OUT="$dir/$s.png" cargo run -q -p benilla
  done
}

cmd="${1:-}"
case "$cmd" in
  list)
    build
    scenarios
    ;;
  capture)
    build
    capture_into "${2:?usage: visual.sh capture <dir>}"
    ;;
  baseline)
    build
    capture_into "$VIS/baseline"
    echo "baseline written to $VIS/baseline"
    ;;
  diff)
    shift
    build
    capture_into "$VIS/candidate"
    echo "--- diff candidate vs baseline ---"
    ./target/debug/benilla-visual diff-dir "$VIS/baseline" "$VIS/candidate" --out "$VIS/diff" "$@"
    ;;
  selfcheck) # selfcheck [<mae>] — the tolerance defaults to 0 (bit-identical)
    # A diff is evidence only if capture is deterministic: two sweeps from one build must match bit
    # for bit. Run it after touching anything the capture clock feeds.
    build
    capture_into "$VIS/self-a"
    capture_into "$VIS/self-b"
    echo "--- selfcheck: self-a vs self-b, one build, two runs ---"
    # Keep the bar at 0 and add no waits: a nonzero result is a harness regression or a renderer
    # defect, such as draw order following spawn order, which varies with thread-pool asset loads.
    ./target/debug/benilla-visual diff-dir "$VIS/self-a" "$VIS/self-b" --out "$VIS/self-diff" \
      --fail "${2:-0}"
    echo "selfcheck OK — the harness clock is a pure function of the build"
    ;;
  *)
    echo "usage: visual.sh {list | capture <dir> | baseline | diff [--fail <mae>] | selfcheck}" >&2
    exit 1
    ;;
esac

#!/usr/bin/env python3
"""Read a `vpl`/`bub` overlay trace and say where the motion came from: projection, solve or snap.

    # walk a town with friendly plates on, tracing one line per plate per frame
    WOW_WIN=1440x810 WOW_NOSOUND=1 WOW_GM=off \
      WOW_UNATTENDED=1 WOW_USER=probeN WOW_PASS=pprobeN WOW_CHAR=Probe<n> \
      WOW_PROBE_CHAT=".go xyz -9465 74 58 0" WOW_PROBE_CHAT_AT=10 \
      WOW_PROBE_KEY="Shift@20:3;V@20.5:0.2;W@24:8" \
      WOW_MOVE_TRACE=/tmp/vpl.trace WOW_MOVE_TRACE_TAGS=vpl \
      WOW_PROBE_EXIT_AT=34 cargo run -q -p benilla
    python3 scripts/vplsum.py /tmp/vpl.trace --from 24 --to 32     # the walk leg only

Jitter in a moving overlay has four causes the eye cannot tell apart: a noisy camera, a stale
anchor, the anti-overlap solve relocating a plate, or the pixel snap quantizing its glide. Every
`vpl` line carries the world anchor, the camera pose, the raw projected point, the solved rect and
the snapped rect, so telling them apart is arithmetic.

Read it in this order:

* projection smoothness: the raw projected point's frame-to-frame acceleration, per unit; small
  (~0.05 px at 60 fps) clears the camera and the anchor.
* off-screen: plates drawn for a unit that is not on screen. Must be 0.
* solve jumps: a plate moving further than its own projection did; some is the reference's own
  anti-overlap bounce, hundreds of pixels in a frame is a defect.
* snap: the pixel snap's extra per-frame displacement, at most half a device pixel; more means
  the snap is on the wrong grid.

Pick one leg with `--from`/`--to`: a run is a login, a teleport, a stand and a walk, and their
average describes none of them.

It reads the chat bubble's `bub` lines too, detected from the file: same projector and
`overhead_anchor` as the plate but no anti-overlap solver, so there is no `solved=` stage and the
SOLVE section is skipped. The ANCHOR section matters most for it, because the bubble rides the
posed head attachment, which bobs with the run cycle:

    WOW_MOVE_TRACE=/tmp/bub.trace WOW_MOVE_TRACE_TAGS=bub \
      WOW_PROBE_CHAT="hello" WOW_PROBE_CHAT_AT=20 WOW_PROBE_KEY="W@20:6" ... cargo run -q -p benilla
    python3 scripts/vplsum.py /tmp/bub.trace --from 20 --to 26
"""

import argparse
import re
import sys
from collections import defaultdict

# One regex for both overlays: `solved=` (the plate's anti-overlap solve) is optional, and the
# final rect is `plate=` or `frame=`.
LINE = re.compile(
    r"t=\s*([\d.]+) (vpl|bub)\s+e=(\d+) vp=\((\d+),(\d+)\) anchor=\[([-\d.,e]+)\] "
    r"cam=\[([-\d.,e]+)\] fwd=\[([-\d.,e]+)\] scr=\(([-\d.e]+),([-\d.e]+)\) "
    r"(?:solved=\(([-\d.e]+),([-\d.e]+)\) )?(?:plate|frame)=\(([-\d.e]+),([-\d.e]+)\)"
)

# A step this far past the plate's own projected motion is a jump, not a glide: about a quarter of
# the plate's height, the smallest relocation a viewer reads as the plate moving by itself.
JUMP_PX = 4.0
# Frames further apart than this are a gap (the plate blinked out), never differenced.
GAP_S = 0.1


def vec3(s):
    return [float(v) for v in s.split(",")]


def load(path, lo, hi):
    """-> (tag, viewport, {entity: [(t, anchor, cam, scr, solved, rect)]}, {t: overlay count})

    A bubble line has no solver stage, so its `solved` slot mirrors the raw point.
    """
    rows, frames, vp, tag = defaultdict(list), defaultdict(int), None, None
    for line in open(path):
        m = LINE.match(line)
        if not m:
            continue
        t = float(m.group(1))
        if not (lo <= t <= hi):
            continue
        tag = m.group(2)
        vp = (float(m.group(4)), float(m.group(5)))
        frames[t] += 1
        scr = (float(m.group(9)), float(m.group(10)))
        solved = (
            (float(m.group(11)), float(m.group(12)))
            if m.group(11) is not None
            else scr
        )
        rows[int(m.group(3))].append(
            (
                t,
                vec3(m.group(6)),
                vec3(m.group(7)),
                scr,
                solved,
                (float(m.group(13)), float(m.group(14))),
            )
        )
    for s in rows.values():
        s.sort()
    return tag, vp, rows, frames


def stat(vals, fmt="{:6.3f}"):
    if not vals:
        return "     —"
    v = sorted(abs(x) for x in vals)
    return " ".join(
        fmt.format(x) for x in (v[len(v) // 2], v[int(0.9 * (len(v) - 1))], v[-1])
    )


def on_screen(p, vp):
    return 0.0 <= p[0] <= vp[0] and 0.0 <= p[1] <= vp[1]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("trace")
    ap.add_argument("--from", dest="lo", type=float, default=0.0)
    ap.add_argument("--to", dest="hi", type=float, default=1e9)
    ap.add_argument("--worst", type=int, default=10, help="how many jumps to name")
    a = ap.parse_args()

    tag, vp, rows, frames = load(a.trace, a.lo, a.hi)
    if not rows:
        sys.exit(
            f"{a.trace}: no `vpl`/`bub` lines in [{a.lo}, {a.hi}] — "
            "was WOW_MOVE_TRACE_TAGS=vpl (or =bub) set?"
        )
    what = "plates" if tag == "vpl" else "bubbles"

    ts = sorted(frames)
    dts = sorted(b - a_ for a_, b in zip(ts, ts[1:]) if b - a_ < GAP_S)
    drawn = sum(len(s) for s in rows.values())
    off = sum(1 for s in rows.values() for r in s if not on_screen(r[3], vp))
    print(
        f"viewport {vp[0]:.0f}x{vp[1]:.0f}   frames {len(ts)} in [{ts[0]:.2f},{ts[-1]:.2f}]   "
        f"dt med {1000 * dts[len(dts) // 2]:.1f} ms   {what}/frame {drawn / len(ts):.2f}"
    )
    print(f"OFF-SCREEN {what} drawn: {off}/{drawn} ({100 * off / drawn:.1f}%)   [must be 0]")

    snap, jumps, steps = [], [], 0
    for e, s in rows.items():
        for p, q in zip(s, s[1:]):
            if q[0] - p[0] > GAP_S:
                continue
            steps += 1
            d_scr = [q[3][i] - p[3][i] for i in (0, 1)]
            d_sol = [q[4][i] - p[4][i] for i in (0, 1)]
            d_pl = [q[5][i] - p[5][i] for i in (0, 1)]
            snap.append(max(abs(d_pl[i] - d_sol[i]) for i in (0, 1)))
            solve = max(abs(d_sol[i] - d_scr[i]) for i in (0, 1))
            if solve >= JUMP_PX:
                jumps.append((solve, q[0], e, p[5], q[5], p[3], q[3]))
    print(f"SNAP  extra px/frame (med p90 max): {stat(snap)}   [≤ half a device pixel]")
    if tag == "vpl":
        print(
            f"SOLVE jumps ≥ {JUMP_PX:.0f} px: {len(jumps)}/{steps} steps "
            f"({100 * len(jumps) / max(steps, 1):.2f}%)"
        )
    for j in sorted(jumps, reverse=True)[: a.worst]:
        print(
            f"   t={j[1]:8.3f} e={j[2]:<5d} {j[0]:7.1f} px   "
            f"plate ({j[3][0]:7.1f},{j[3][1]:6.1f}) -> ({j[4][0]:7.1f},{j[4][1]:6.1f})   "
            f"scr ({j[5][0]:8.1f},{j[5][1]:7.1f}) -> ({j[6][0]:8.1f},{j[6][1]:7.1f})"
        )

    # The world anchor's own motion by axis: horizontal is the unit gliding, vertical is the run
    # cycle moving the posed head attachment (plus terrain). A standing unit reads 0 in both.
    print("\nANCHOR motion — the world point's own Δ per frame, yd (med p90 max):")
    for e, s in sorted(rows.items(), key=lambda kv: -len(kv[1]))[:8]:
        pairs = [(a_, b) for a_, b in zip(s, s[1:]) if b[0] - a_[0] < GAP_S]
        if len(pairs) < 10:
            continue
        horiz = [
            ((b[1][0] - a_[1][0]) ** 2 + (b[1][2] - a_[1][2]) ** 2) ** 0.5 for a_, b in pairs
        ]
        vert = [b[1][1] - a_[1][1] for a_, b in pairs]
        ys = [r[1][1] for r in s]
        print(
            f"   e={e:<5d} n={len(pairs):<5d} horiz {stat(horiz, '{:7.4f}')}   "
            f"vert {stat(vert, '{:7.4f}')}   vert span {max(ys) - min(ys):.4f} yd"
        )

    print("\nPROJECTION smoothness — |Δ| and |ΔΔ| of the raw point, per unit (med p90 max):")
    for e, s in sorted(rows.items(), key=lambda kv: -len(kv[1]))[:8]:
        vis = [r for r in s if on_screen(r[3], vp)]
        if len(vis) < 30:
            continue
        d = [
            [b[3][i] - a_[3][i] for i in (0, 1)]
            for a_, b in zip(vis, vis[1:])
            if b[0] - a_[0] < GAP_S
        ]
        dd = [[b[i] - a_[i] for i in (0, 1)] for a_, b in zip(d, d[1:])]
        anchor = max(
            (abs(b[1][i] - a_[1][i]) for a_, b in zip(s, s[1:]) for i in (0, 1)), default=0.0
        )
        print(
            f"   e={e:<5d} n={len(vis):<5d} anchor {anchor:6.4f} yd/frame   "
            f"|Δx| {stat([v[0] for v in d])}   |ΔΔx| {stat([v[0] for v in dd])}   "
            f"|ΔΔy| {stat([v[1] for v in dd])}"
        )


if __name__ == "__main__":
    main()

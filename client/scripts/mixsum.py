#!/usr/bin/env python3
"""Read a `$WOW_MIX_TAP` capture and say, in numbers, what the mix was doing when.

The tap records the final mix to a stereo float-32 WAV. This prints a windowed RMS/peak envelope
with a bar, and a `spans` report naming every silent stretch and every onset/offset edge: a hole
is a silent span with a start and an end, and a linear fade-to-zero is a straight line in dBFS, a
cut a cliff, a crossfade an overlap. `--json` for a machine, the default for a session log.

    scripts/mixsum.py entry.wav                  # 250 ms windows, the envelope + the spans
    scripts/mixsum.py entry.wav --window 0.1     # finer, for a click or a declick ramp
    scripts/mixsum.py entry.wav --from 2 --to 12 # just the covered window
    scripts/mixsum.py entry.wav --quiet          # the spans only, no per-window rows

Pure stdlib, so it runs without installing anything. Python's `wave` module refuses format 3
(IEEE float), so the tap's 44-byte header is parsed directly; it must match
`sound::mix_tap::wav_header`.
"""

import argparse
import json
import math
import struct
import sys
from array import array

# Below this a window is silence: the tap is pre-clamp and dither-free, so true silence reads
# -inf, and -80 dBFS still counts an audible fade tail as sound.
SILENCE_DBFS = -80.0


def read_tap(path):
    """(sample_rate, interleaved float32 array). Tolerates the tap's crash-safe truncated tail."""
    with open(path, "rb") as f:
        head = f.read(44)
        if len(head) < 44 or head[0:4] != b"RIFF" or head[8:12] != b"WAVE":
            sys.exit(f"mixsum: {path} is not a RIFF/WAVE file")
        fmt, channels, rate, _brate, _align, bits = struct.unpack("<HHIIHH", head[20:36])
        if (fmt, channels, bits) != (3, 2, 32):
            sys.exit(
                f"mixsum: expected stereo float-32 (fmt 3), got fmt={fmt} ch={channels} bits={bits}"
            )
        if head[36:40] != b"data":
            sys.exit("mixsum: no `data` chunk where the tap header puts it")
        raw = f.read()
    # The declared size is patched per flush and a hard kill can leave the file shorter: trust the
    # bytes present, floored to whole frames.
    usable = len(raw) - (len(raw) % 8)
    samples = array("f")
    samples.frombytes(raw[:usable])
    if sys.byteorder == "big":
        samples.byteswap()
    return rate, samples


def db(x):
    return -math.inf if x <= 1e-12 else 20.0 * math.log10(x)


def envelope(rate, samples, window_s, t_from, t_to):
    """Per-window (t, rms_dbfs, peak_dbfs) over the requested slice."""
    per_win = max(1, int(rate * window_s)) * 2  # interleaved: 2 samples per frame
    lo = min(len(samples), int(t_from * rate) * 2)
    hi = len(samples) if t_to is None else min(len(samples), int(t_to * rate) * 2)
    out = []
    for start in range(lo, hi, per_win):
        chunk = samples[start : min(start + per_win, hi)]
        if not chunk:
            break
        acc = 0.0
        peak = 0.0
        for v in chunk:
            acc += v * v
            a = abs(v)
            if a > peak:
                peak = a
        out.append((start / 2 / rate, db(math.sqrt(acc / len(chunk))), db(peak)))
    return out


def spans(env, window_s, floor):
    """Contiguous runs of silence and of sound, as (kind, start, end, duration)."""
    runs = []
    for t, rms, _peak in env:
        kind = "silence" if rms < floor else "sound"
        if runs and runs[-1][0] == kind:
            runs[-1][2] = t + window_s
        else:
            runs.append([kind, t, t + window_s])
    return [(k, a, b, b - a) for k, a, b in runs]


def bar(rms_dbfs, floor=-72.0, width=40):
    if rms_dbfs == -math.inf:
        return ""
    filled = int(round(max(0.0, (rms_dbfs - floor) / -floor) * width))
    return "#" * max(0, min(width, filled))


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("wav", help="a $WOW_MIX_TAP capture")
    ap.add_argument("--window", type=float, default=0.25, help="window seconds (default 0.25)")
    ap.add_argument("--from", dest="t_from", type=float, default=0.0)
    ap.add_argument("--to", dest="t_to", type=float, default=None)
    ap.add_argument("--floor", type=float, default=SILENCE_DBFS, help="silence threshold, dBFS")
    ap.add_argument("--quiet", action="store_true", help="spans only")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()

    rate, samples = read_tap(a.wav)
    total = len(samples) / 2 / rate
    env = envelope(rate, samples, a.window, a.t_from, a.t_to)
    runs = spans(env, a.window, a.floor)

    if a.json:
        json.dump(
            {
                "path": a.wav,
                "sample_rate": rate,
                "duration_s": total,
                "window_s": a.window,
                "floor_dbfs": a.floor,
                "windows": [
                    {"t": t, "rms_dbfs": None if r == -math.inf else r,
                     "peak_dbfs": None if p == -math.inf else p}
                    for t, r, p in env
                ],
                "spans": [{"kind": k, "from": s, "to": e, "secs": d} for k, s, e, d in runs],
            },
            sys.stdout,
            indent=2,
        )
        print()
        return

    print(f"mixsum: {a.wav} — {total:.1f}s stereo float-32 @ {rate} Hz, {a.window*1000:.0f} ms windows")
    if not a.quiet:
        for t, rms, peak in env:
            r = "  -inf" if rms == -math.inf else f"{rms:6.1f}"
            p = "  -inf" if peak == -math.inf else f"{peak:6.1f}"
            print(f"  {t:7.2f}s  rms {r}  peak {p}  {bar(rms)}")
    print(f"\nspans (silence = rms < {a.floor:.0f} dBFS):")
    for kind, start, end, dur in runs:
        print(f"  {kind:8}  {start:7.2f}s → {end:7.2f}s   {dur:6.2f}s")
    holes = [r for r in runs if r[0] == "silence" and r[1] > 0.0]
    if holes:
        longest = max(holes, key=lambda r: r[3])
        print(f"\nlongest interior silence: {longest[3]:.2f}s at {longest[1]:.2f}s")


if __name__ == "__main__":
    main()

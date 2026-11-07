#!/usr/bin/env python3
"""Refuse a second open `pass_span` on the same render pass (a wgpu validation error on Vulkan).

bevy's `DiagnosticsRecorder::pass_span` is a timestamp pair plus a pipeline-statistics query, and
wgpu allows one statistics query active at a time: a second `pass_span` on a pass whose span is
still open is a validation error on backends with `PIPELINE_STATISTICS_QUERY`, which in wgpu 27 is
Vulkan alone (Metal lacks it; wgpu-hal's DX12 arm has the line commented out). On Metal and DX12
the nesting is a silent no-op, so no macOS build, test or run sees it.

The shape it refuses, per function: `let g = <recorder>.pass_span(&mut P, …)` followed by another
`.pass_span(&mut P, …)` before `g.end(&mut P)`. Timestamp-only spans (`time_span`) nest fine and
are not looked at. Lexical, per file, reset at every `fn`: a span never outlives its function.

Usage:  scripts/pass-span-lint.py [path …]      (default: every crates/**/*.rs)
Exit:   0 clean, 1 findings.
"""

from __future__ import annotations

import pathlib
import re
import sys

OPEN = re.compile(r"\blet\s+(?:mut\s+)?(\w+)\s*=\s*[\w.]+\.pass_span\(\s*&mut\s+(\w+)\s*,")
ANY_OPEN = re.compile(r"\.pass_span\(\s*&mut\s+(\w+)\s*,")
END = re.compile(r"\b(\w+)\.end\(\s*&mut\s+(\w+)\s*\)")
FN = re.compile(r"^\s*(?:pub(?:\([^)]*\))?\s+)?(?:async\s+)?(?:unsafe\s+)?fn\s+\w+")


def lint(path: pathlib.Path) -> list[str]:
    findings: list[str] = []
    open_spans: list[tuple[str, str, int]] = []  # (guard, pass, line)
    for lineno, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.split("//", 1)[0]
        if FN.match(line):
            open_spans.clear()
        m = OPEN.search(line)
        if m:
            guard, pass_name = m.group(1), m.group(2)
        else:
            m = ANY_OPEN.search(line)
            guard, pass_name = (None, m.group(1)) if m else (None, None)
        if pass_name is not None:
            for outer_guard, outer_pass, outer_line in open_spans:
                if outer_pass == pass_name:
                    findings.append(
                        f"{path}:{lineno}: a second pass_span on `{pass_name}` while "
                        f"`{outer_guard}` (line {outer_line}) is still open — one "
                        f"pipeline-statistics query at a time"
                    )
            if guard is not None:
                open_spans.append((guard, pass_name, lineno))
        e = END.search(line)
        if e:
            open_spans = [s for s in open_spans if s[0] != e.group(1)]
    return findings


def main() -> int:
    args = [pathlib.Path(a) for a in sys.argv[1:]] or [pathlib.Path("crates")]
    files: list[pathlib.Path] = []
    for a in args:
        files.extend(sorted(a.rglob("*.rs")) if a.is_dir() else [a])
    findings = [f for p in files for f in lint(p)]
    for f in findings:
        print(f)
    print(f"pass-span-lint: {'clean' if not findings else f'{len(findings)} finding(s)'} — "
          f"{len(files)} file(s)")
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())

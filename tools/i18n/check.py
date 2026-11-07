#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Validate the shared i18n catalogue."""

from __future__ import annotations

import re
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from catalogue import load


def main() -> int:
    result = load()
    print(
        f"{len(result.entries)} messages; "
        f"languages: {', '.join(result.languages)}; "
        f"required: {', '.join(result.required)}"
    )
    optional_missing = Counter()
    other_warnings = []
    for item in result.warnings:
        match = re.search(r"missing optional language (\w+)", item)
        if match:
            optional_missing[match.group(1)] += 1
        else:
            other_warnings.append(item)
    for language, count in sorted(optional_missing.items()):
        print(f"WARNING: {count} messages missing optional language {language}")
    for item in other_warnings[:20]:
        print(f"WARNING: {item}")
    if len(other_warnings) > 20:
        print(f"... and {len(other_warnings) - 20} more warning(s)")
    for item in result.errors:
        print(f"ERROR: {item}")
    if result.errors:
        print(f"{len(result.errors)} i18n error(s), {len(result.warnings)} warning(s)")
        return 1
    print(f"i18n: ok ({len(result.warnings)} warning(s))")
    return 0


if __name__ == "__main__":
    sys.exit(main())

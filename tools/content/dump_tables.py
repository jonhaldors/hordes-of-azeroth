#!/usr/bin/env python3
"""One-time import of the design-content tables into shared/content/tables."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from tables import dump_tables


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--maria", required=True, help="path to the mariadb client")
    parser.add_argument("--database", default="mangos_052")
    parser.add_argument("tables", nargs="*", help="optional table names (default: all design tables)")
    args = parser.parse_args()
    written = dump_tables(args.maria, args.database, args.tables or None)
    print(f"wrote {len(written)} table sources")
    return 0


if __name__ == "__main__":
    sys.exit(main())

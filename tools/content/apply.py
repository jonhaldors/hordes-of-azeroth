#!/usr/bin/env python3
"""Apply the generated content SQL to a world database."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SQL_DIR = ROOT / "server" / "sql" / "content"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--maria", required=True, help="path to the mariadb client")
    parser.add_argument("--database", required=True)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", default="3306")
    parser.add_argument("--user", default="root")
    parser.add_argument("--password", default="root")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    files = sorted(SQL_DIR.glob("*.sql"))
    if args.dry_run:
        for path in files:
            print(path.relative_to(ROOT))
        return 0

    for path in files:
        with path.open("rb") as sql:
            result = subprocess.run(
                [
                    args.maria,
                    "--skip-ssl",
                    "-h",
                    args.host,
                    "-P",
                    args.port,
                    "-u",
                    args.user,
                    f"-p{args.password}",
                    "--default-character-set=utf8mb4",
                    args.database,
                ],
                stdin=sql,
                capture_output=True,
            )
        if result.returncode != 0:
            print(result.stderr.decode("utf-8", "replace"), file=sys.stderr)
            return result.returncode
        print(f"applied {path.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

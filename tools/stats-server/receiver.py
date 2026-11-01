import collections
import datetime
import gzip
import io
import json
import os
import re
import secrets
import shutil
import threading
import time
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

STATE = os.environ.get("STATE_DIRECTORY", "/var/lib/hoa-stats")
PORT = int(os.environ.get("PORT", "8090"))
MAX_RUN_BYTES = 64 * 1024
MAX_RUN_JSON_BYTES = 2 * 1024 * 1024
MAX_REPORT_BYTES = 25 * 1024 * 1024
MIN_FREE_BYTES = 5 * 1024 ** 3
RUN_FORMAT = 1
LIMITS = {"/run": (60, 3600), "/report": (5, 3600)}
BOARD_SEASON = 1
BOARD_FILE = os.path.join(STATE, "board-s%d.json" % BOARD_SEASON)
BOARD_ROWS = 50
GROUP_SIZES = (2, 3, 4)
INSTALL_ID = re.compile(r"^[A-Za-z0-9-]{1,64}$")
FIRST_MYTHIC_LEVEL = 10
MYTHIC_STAGES = 3
MIN_STAGE_MS = 60 * 1000
MAX_BONUS_STATS = 2
NAME_LENGTH = (2, 12)
CLEAR_LINE = re.compile(r"^\d+ clear: hero clears level (\d+) at run minute [\d.]+ in (\d+) ms \(.*class (\d+)\): coop (\d+), gm (\d+), board (-?\d+), gear (\d+)(?:, party (\S+))?$")
FOUND_GEAR = re.compile(r"; found \[([^\]]*)\]")
RUN_LEVEL = re.compile(r"; difficulty level (\d+)$")


class RateLimiter:
    def __init__(self):
        self.lock = threading.Lock()
        self.hits = collections.defaultdict(collections.deque)

    def allow(self, path, client):
        count, window = LIMITS[path]
        now = time.monotonic()
        with self.lock:
            stamps = self.hits[(path, client)]
            while stamps and now - stamps[0] > window:
                stamps.popleft()
            if len(stamps) >= count:
                return False
            stamps.append(now)
            return True


limiter = RateLimiter()


def day_folder(kind):
    folder = os.path.join(STATE, kind, datetime.date.today().isoformat())
    os.makedirs(folder, exist_ok=True)
    return folder


def disk_has_room():
    return shutil.disk_usage(STATE).free > MIN_FREE_BYTES


def read_run(body):
    try:
        with gzip.GzipFile(fileobj=io.BytesIO(body)) as unpacked:
            text = unpacked.read(MAX_RUN_JSON_BYTES + 1)
        if len(text) > MAX_RUN_JSON_BYTES:
            return None
        record = json.loads(text)
    except (OSError, EOFError, ValueError):
        return None
    valid = (isinstance(record, dict) and record.get("format") == RUN_FORMAT and isinstance(record.get("install"), str)
             and isinstance(record.get("lines"), list) and all(isinstance(line, str) for line in record["lines"]))
    return record if valid else None


def board_name(record):
    name = record.get("name")
    if not isinstance(name, str) or not NAME_LENGTH[0] <= len(name) <= NAME_LENGTH[1] or not name.isalpha():
        return None
    return name


def gear_fits_level(lines):
    for line in lines:
        if " loadout: " not in line:
            continue
        level = RUN_LEVEL.search(line)
        if not level:
            return False
        found = FOUND_GEAR.search(line)
        for piece in (found.group(1).split(",") if found and found.group(1) else []):
            parts = piece.split(":")
            if len(parts) != 4 or not all(part.isdigit() for part in parts):
                return False
            if int(parts[1]) > int(level.group(1)) or int(parts[2]) > MAX_BONUS_STATS or int(parts[3]) != BOARD_SEASON:
                return False
    return True


def read_party(text):
    members = []
    for piece in (text or "").split(";"):
        parts = piece.split(":")
        if len(parts) != 6 or not all(parts[i].isdigit() for i in (0, 2, 3, 4, 5)):
            return None
        guid, name, class_id, shown, gear, gm = parts
        if gear != "1" or gm != "0":
            return None
        if shown == "1" and not (NAME_LENGTH[0] <= len(name) <= NAME_LENGTH[1] and name.isalpha()):
            return None
        members.append({"guid": int(guid), "name": name if shown == "1" else "", "class": int(class_id)})
    return members if len(members) in GROUP_SIZES else None


def better(a, b):
    return b is None or (a["level"], -a["ms"]) > (b["level"], -b["ms"])


def board_results(record):
    lines = record["lines"]
    name = board_name(record)
    date = str(record.get("started", ""))[:10]
    solo = group = None
    for line in lines:
        match = CLEAR_LINE.match(line)
        if not match:
            continue
        level, ms, class_id = int(match.group(1)), int(match.group(2)), int(match.group(3))
        coop, gm, gear = match.group(4), match.group(5), match.group(7)
        if level < FIRST_MYTHIC_LEVEL or gm != "0" or gear != "1" or ms < MYTHIC_STAGES * MIN_STAGE_MS:
            continue
        result = {"level": level, "ms": ms, "date": date}
        if coop == "0":
            if name and gear_fits_level(lines):
                result.update({"name": name, "class": class_id})
                if better(result, solo):
                    solo = result
        else:
            members = read_party(match.group(8))
            if members:
                result["members"] = members
                if better(result, group):
                    group = result
    return solo, group


def rank_key(entry):
    return (-entry["level"], entry["ms"])


def members_text(members):
    return ",".join("%s:%d" % (member["name"], member["class"]) for member in members)


class Board:
    def __init__(self):
        self.lock = threading.Lock()
        self.solo = {}
        self.groups = {}
        self.updated = ""
        if os.path.exists(BOARD_FILE):
            with open(BOARD_FILE, encoding="utf-8") as handle:
                saved = json.load(handle)
            self.solo = saved.get("solo", {})
            self.groups = saved.get("groups", {})
            self.updated = saved.get("updated", "")

    def add(self, record):
        solo, group = board_results(record)
        if solo is None and group is None:
            return
        install = record["install"]
        with self.lock:
            if solo:
                key = "%s:%s" % (install, record.get("character", 0))
                if better(solo, self.solo.get(key)):
                    self.solo[key] = solo
                else:
                    self.solo[key]["name"] = solo["name"]
            if group:
                key = "%s|%s" % (install, ",".join(str(guid) for guid in sorted(member["guid"] for member in group["members"])))
                group["size"] = len(group["members"])
                if better(group, self.groups.get(key)):
                    self.groups[key] = group
            self.updated = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
            partial = BOARD_FILE + ".part"
            with open(partial, "w", encoding="utf-8") as handle:
                json.dump({"updated": self.updated, "solo": self.solo, "groups": self.groups}, handle)
            os.replace(partial, BOARD_FILE)

    def text(self, install=None):
        with self.lock:
            solo = dict(self.solo)
            groups = dict(self.groups)
            updated = self.updated
        lines = ["season~%d" % BOARD_SEASON]
        if updated:
            lines.append("updated~" + updated)
        everyone = sorted(solo.items(), key=lambda item: rank_key(item[1]))
        overall = {key: rank for rank, (key, _) in enumerate(everyone, 1)}
        class_rank = {}
        by_class = collections.defaultdict(list)
        for key, entry in everyone:
            by_class[entry["class"]].append(key)
            class_rank[key] = len(by_class[entry["class"]])
        for class_id in sorted(by_class):
            for rank, key in enumerate(by_class[class_id][:BOARD_ROWS], 1):
                entry = solo[key]
                lines.append("solo~%d~%d~%s~%d~%d~%s" % (class_id, rank, entry["name"], entry["level"], entry["ms"], entry["date"]))
        group_rank = {}
        by_size = collections.defaultdict(list)
        for key, entry in sorted(groups.items(), key=lambda item: rank_key(item[1])):
            by_size[entry["size"]].append(key)
            group_rank[key] = len(by_size[entry["size"]])
        for size in sorted(by_size):
            for rank, key in enumerate(by_size[size][:BOARD_ROWS], 1):
                entry = groups[key]
                lines.append("group~%d~%d~%d~%d~%s~%s" % (size, rank, entry["level"], entry["ms"], entry["date"], members_text(entry["members"])))
        if install:
            for key, entry in everyone:
                if key.startswith(install + ":"):
                    lines.append("mine~solo~%d~%d~%d~%s~%d~%d~%s" % (entry["class"], class_rank[key], overall[key], entry["name"], entry["level"], entry["ms"], entry["date"]))
            for key, entry in groups.items():
                if key.startswith(install + "|"):
                    lines.append("mine~group~%d~%d~%d~%d~%s~%s" % (entry["size"], group_rank[key], entry["level"], entry["ms"], entry["date"], members_text(entry["members"])))
        return "\n".join(lines) + "\n"


board = Board()


def save(kind, name, body):
    path = os.path.join(day_folder(kind), name)
    partial = path + ".part"
    with open(partial, "wb") as handle:
        handle.write(body)
    os.replace(partial, path)


class Handler(BaseHTTPRequestHandler):
    server_version = "hoa-stats"
    sys_version = ""
    timeout = 30

    def log_message(self, format, *args):
        pass

    def answer(self, status, text=""):
        payload = text.encode()
        self.send_response(status)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def client(self):
        return self.headers.get("CF-Connecting-IP") or self.client_address[0]

    def read_body(self, limit):
        try:
            length = int(self.headers.get("Content-Length", ""))
        except ValueError:
            return None
        if length <= 0 or length > limit:
            return None
        return self.rfile.read(length)

    def do_GET(self):
        if self.path == "/health":
            self.answer(200, "ok")
        elif self.path.split("?", 1)[0] == "/board":
            query = urllib.parse.parse_qs(urllib.parse.urlsplit(self.path).query)
            install = (query.get("install") or [""])[0]
            self.answer(200, board.text(install if INSTALL_ID.match(install) else None))
        else:
            self.answer(404)

    def do_POST(self):
        if self.path not in LIMITS:
            self.answer(404)
            return
        if not limiter.allow(self.path, self.client()):
            self.answer(429, "slow down")
            return
        if not disk_has_room():
            self.answer(503, "full")
            return
        if self.path == "/run":
            self.receive_run()
        else:
            self.receive_report()

    def receive_run(self):
        body = self.read_body(MAX_RUN_BYTES)
        if body is None:
            self.answer(413, "too large")
            return
        record = read_run(body)
        if record is None:
            self.answer(400, "not a run record")
            return
        save("runs", secrets.token_hex(8) + ".json.gz", body)
        board.add(record)
        self.answer(204)

    def receive_report(self):
        body = self.read_body(MAX_REPORT_BYTES)
        if body is None:
            self.answer(413, "too large")
            return
        if not body.startswith(b"PK\x03\x04"):
            self.answer(400, "not a zip")
            return
        reference = secrets.token_hex(4).upper()
        save("reports", reference + ".zip", body)
        self.answer(200, reference)


def main():
    os.makedirs(STATE, exist_ok=True)
    server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    server.daemon_threads = True
    server.serve_forever()


if __name__ == "__main__":
    main()

import collections
import datetime
import gzip
import io
import json
import os
import secrets
import shutil
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

STATE = os.environ.get("STATE_DIRECTORY", "/var/lib/hoa-stats")
PORT = int(os.environ.get("PORT", "8090"))
MAX_RUN_BYTES = 64 * 1024
MAX_RUN_JSON_BYTES = 2 * 1024 * 1024
MAX_REPORT_BYTES = 25 * 1024 * 1024
MIN_FREE_BYTES = 5 * 1024 ** 3
RUN_FORMAT = 1
LIMITS = {"/run": (60, 3600), "/report": (5, 3600)}


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


def valid_run(body):
    try:
        with gzip.GzipFile(fileobj=io.BytesIO(body)) as unpacked:
            text = unpacked.read(MAX_RUN_JSON_BYTES + 1)
        if len(text) > MAX_RUN_JSON_BYTES:
            return False
        record = json.loads(text)
    except (OSError, EOFError, ValueError):
        return False
    return (isinstance(record, dict) and record.get("format") == RUN_FORMAT and isinstance(record.get("install"), str)
            and isinstance(record.get("lines"), list) and all(isinstance(line, str) for line in record["lines"]))


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
        if not valid_run(body):
            self.answer(400, "not a run record")
            return
        save("runs", secrets.token_hex(8) + ".json.gz", body)
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

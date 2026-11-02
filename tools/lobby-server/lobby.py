import collections
import ipaddress
import json
import os
import secrets
import socket
import string
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = int(os.environ.get("PORT", "8091"))
BIND = os.environ.get("BIND", "127.0.0.1")
TRUST_CLOUDFLARE = os.environ.get("TRUST_CLOUDFLARE", "1") == "1"
PUNCH_HOST = os.environ.get("PUNCH_HOST", "")
PUNCH_PORT = int(os.environ.get("PUNCH_PORT", "0"))
PUNCH_MIN_REQUEST = 48
MAX_BODY_BYTES = 8 * 1024
HOST_TIMEOUT_SECONDS = 90
ASK_SECONDS = 30
MYTHIC_START = 9
DECLINE_WAIT_SECONDS = 30
ANSWER_KEEP_SECONDS = 120
REACH_TIMEOUT_SECONDS = 2.5
CODE_LETTERS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
CODE_LENGTH = 6
MAX_LOBBIES_PER_ADDRESS = 2
MAX_OPEN_ASKS_PER_ADDRESS = 3
LIMITS = {"host": (10, 600), "ask": (30, 600), "list": (120, 60), "poll": (600, 60)}
TEXT_LIMITS = {"name": 40, "host_name": 12, "password": 32, "difficulty": 24, "race": 16, "class": 12, "version": 24, "playing": 48}
CLASSES = {"warrior", "paladin", "hunter", "rogue", "priest", "shaman", "mage", "warlock", "druid"}


class RateLimiter:
    def __init__(self):
        self.lock = threading.Lock()
        self.hits = collections.defaultdict(collections.deque)

    def allow(self, kind, client):
        count, window = LIMITS[kind]
        now = time.monotonic()
        with self.lock:
            stamps = self.hits[(kind, client)]
            while stamps and now - stamps[0] > window:
                stamps.popleft()
            if len(stamps) >= count:
                return False
            stamps.append(now)
            return True


class Lobbies:
    def __init__(self):
        self.lock = threading.Lock()
        self.lobbies = {}
        self.asks = {}
        self.declined = {}

    def new_code(self):
        taken = {lobby["code"] for lobby in self.lobbies.values()}
        while True:
            code = "".join(secrets.choice(CODE_LETTERS) for _ in range(CODE_LENGTH))
            if code not in taken:
                return code

    def expire(self):
        now = time.monotonic()
        for lobby_id in [key for key, lobby in self.lobbies.items() if now - lobby["seen"] > HOST_TIMEOUT_SECONDS]:
            self.close(lobby_id, "expired")
        for ask_id in [key for key, ask in self.asks.items() if ask["state"] != "waiting" and now - ask["answered"] > ANSWER_KEEP_SECONDS]:
            del self.asks[ask_id]
        for key in [key for key, at in self.declined.items() if now - at > DECLINE_WAIT_SECONDS]:
            del self.declined[key]
        for ask in self.asks.values():
            if ask["state"] == "waiting" and now - ask["created"] > ASK_SECONDS:
                ask["state"] = "expired"
                ask["answered"] = now

    def close(self, lobby_id, reason="closed"):
        lobby = self.lobbies.pop(lobby_id, None)
        if lobby:
            log_event(reason, lobby=lobby_id, mode=lobby.get("mode"), players=lobby.get("players"), minutes=int((time.monotonic() - lobby["created"]) / 60))
        for ask in self.asks.values():
            if ask["lobby"] == lobby_id and ask["state"] == "waiting":
                ask["state"] = "gone"
                ask["answered"] = time.monotonic()

    def find(self, lobby_id, code):
        if lobby_id:
            return self.lobbies.get(lobby_id)
        if code:
            code = code.strip().upper()
            return next((lobby for lobby in self.lobbies.values() if lobby["code"] == code), None)
        return None


LOBBIES = Lobbies()
LIMITER = RateLimiter()


def log_event(event, **fields):
    print(" ".join([event] + ["%s=%s" % (key, value) for key, value in fields.items()]), flush=True)


def clip(value, key):
    return str(value or "")[:TEXT_LIMITS[key]].strip()


def whole(value, low, high, fallback):
    try:
        return max(low, min(high, int(value)))
    except (TypeError, ValueError):
        return fallback


def reachable(address, port):
    try:
        with socket.create_connection((address, port), timeout=REACH_TIMEOUT_SECONDS) as probe:
            probe.settimeout(REACH_TIMEOUT_SECONDS)
            probe.sendall(b"HOA1 PING\n")
            return probe.recv(16).startswith(b"HOA1 PONG")
    except OSError:
        return False


def parse_address(text, default_port):
    text = str(text or "").strip()[:120]
    if not text:
        return None
    if text.startswith("["):
        host, _, rest = text[1:].partition("]")
        port_text = rest[1:] if rest.startswith(":") else ""
    elif text.count(":") == 1:
        host, _, port_text = text.partition(":")
    else:
        host, port_text = text, ""
    port = whole(port_text, 1, 65535, 0) if port_text else default_port
    if not host or not port or any(letter.isspace() for letter in host):
        return None
    return host, port


def resolve(host):
    try:
        return {info[4][0] for info in socket.getaddrinfo(host, None, type=socket.SOCK_STREAM)}
    except (OSError, UnicodeError):
        return set()


VPN_NETWORKS = [ipaddress.ip_network("25.0.0.0/8"), ipaddress.ip_network("26.0.0.0/8")]
MAX_VPN_ADDRESSES = 4


def is_vpn(address):
    return any(address in network for network in VPN_NETWORKS) or address in ipaddress.ip_network("100.64.0.0/10")


def is_public(ip):
    try:
        address = ipaddress.ip_address(ip.split("%")[0])
    except ValueError:
        return False
    return address.is_global and not (address.version == 4 and is_vpn(address))


def vpn_addresses(values):
    found = []
    for value in values if isinstance(values, list) else []:
        try:
            address = ipaddress.IPv4Address(str(value).strip())
        except ValueError:
            continue
        if not address.is_loopback and not address.is_multicast and str(address) not in found:
            found.append(str(address))
    return found[:MAX_VPN_ADDRESSES]


def local_address(text):
    try:
        address = ipaddress.IPv4Address(str(text or "").strip())
    except ValueError:
        return ""
    return str(address) if address.is_private and not address.is_loopback else ""


def public_view(lobby, now):
    return {
        "id": lobby["id"],
        "name": lobby["name"],
        "host": lobby["host_name"],
        "host_class": lobby["host_class"],
        "classes": lobby["classes"],
        "difficulty": lobby["difficulty"],
        "players": lobby["players"],
        "max": lobby["max"],
        "locked": bool(lobby["password"]),
        "mastery_limit": lobby["mastery_limit"],
        "same_class": lobby.get("same_class", False),
        "min_mythic": lobby.get("min_mythic", 0),
        "pause": lobby.get("pause", True),
        "xp": lobby.get("xp", True),
        "playing": lobby.get("playing", ""),
        "lan": lobby.get("mode") == "lan",
        "members": lobby["members"],
        "age": int(now - lobby["created"]),
    }


def punch_address(text, client):
    target = parse_address(text, 0)
    if not target or target[0] != client or not is_public(target[0]):
        return ""
    return "%s:%d" % target


def session_id(text):
    text = str(text or "")[:16]
    return text if len(text) == 16 and all(letter in string.hexdigits for letter in text) else ""


def reflect_forever():
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(("0.0.0.0", PUNCH_PORT))
    while True:
        try:
            data, (address, port) = sock.recvfrom(256)
            parts = data.decode("ascii", "replace").split()
            if len(data) >= PUNCH_MIN_REQUEST and len(parts) == 3 and parts[:2] == ["HOA1", "WHOAMI"] and len(parts[2]) <= 16:
                sock.sendto(("HOA1 YOU %s %d %s" % (address, port, parts[2])).encode(), (address, port))
        except OSError:
            pass


def visible_to(lobby, client):
    return lobby.get("mode") != "lan" or lobby["address"] == client


class Handler(BaseHTTPRequestHandler):
    server_version = "hoa-lobby"
    sys_version = ""

    def log_message(self, fmt, *args):
        pass

    def client(self):
        if TRUST_CLOUDFLARE and self.headers.get("CF-Connecting-IP"):
            return self.headers.get("CF-Connecting-IP")
        return self.client_address[0]

    def send(self, status, payload):
        data = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        try:
            self.wfile.write(data)
        except (BrokenPipeError, ConnectionResetError):
            log_event("client-left", path=self.path.partition("?")[0], status=status)

    def body(self):
        length = int(self.headers.get("Content-Length") or 0)
        if length <= 0 or length > MAX_BODY_BYTES:
            return None
        try:
            return json.loads(self.rfile.read(length))
        except ValueError:
            return None

    def do_GET(self):
        path, _, query = self.path.partition("?")
        params = dict(part.split("=", 1) for part in query.split("&") if "=" in part)
        if path == "/lobbies":
            if not LIMITER.allow("list", self.client()):
                return self.send(429, {"error": "Too many requests. Try again in a minute."})
            version = params.get("version", "")
            now = time.monotonic()
            with LOBBIES.lock:
                LOBBIES.expire()
                shown = [public_view(lobby, now) for lobby in LOBBIES.lobbies.values() if lobby["listed"] and lobby["version"] == version and visible_to(lobby, self.client())]
            return self.send(200, {"lobbies": shown})
        if path == "/punch":
            return self.send(200, {"address": "%s:%d" % (PUNCH_HOST, PUNCH_PORT) if PUNCH_HOST and PUNCH_PORT else ""})
        if path == "/health":
            return self.send(200, {"ok": True})
        self.send(404, {"error": "Not found."})

    def do_POST(self):
        data = self.body()
        if not isinstance(data, dict):
            return self.send(400, {"error": "Invalid request."})
        routes = {"/host": self.host, "/heartbeat": self.heartbeat, "/close": self.close, "/requests": self.requests,
                  "/answer": self.answer, "/ask": self.ask, "/ask/state": self.ask_state, "/ask/cancel": self.ask_cancel}
        route = routes.get(self.path)
        if not route:
            return self.send(404, {"error": "Not found."})
        route(data)

    def owned(self, data):
        lobby = LOBBIES.lobbies.get(data.get("id"))
        if not lobby or not secrets.compare_digest(lobby["secret"], str(data.get("secret", ""))):
            return None
        lobby["seen"] = time.monotonic()
        return lobby

    def host(self, data):
        client = self.client()
        if not LIMITER.allow("host", client):
            return self.send(429, {"error": "Too many lobbies created. Try again in a few minutes."})
        port = whole(data.get("port"), 1024, 65535, 0)
        if not port:
            return self.send(400, {"error": "Invalid request."})
        local = local_address(data.get("local"))
        vpn = vpn_addresses(data.get("vpn"))
        punch = punch_address(data.get("punch"), client)
        listed = bool(data.get("listed", True))
        if data.get("address"):
            target = parse_address(data.get("address"), port)
            if not target:
                return self.send(400, {"error": "That public address isn't valid. Enter it as address:port, for example example.com:3725."})
            resolved = resolve(target[0])
            if not resolved:
                return self.send(409, {"error": "That public address can't be found."})
            public = any(is_public(ip) for ip in resolved)
            if public and not reachable(target[0], target[1]):
                return self.send(409, {"error": "Other players can't reach %s:%d. Check that it forwards TCP to port %d on this PC." % (target[0], target[1], port)})
            join_host, join_port, mode = target[0], target[1], "address"
            listed = listed and public
            punch = ""
        elif reachable(client, port):
            join_host, join_port, mode = client, port, "direct"
            punch = ""
        elif punch:
            join_host, join_port, mode = client, port, "punch"
        elif local:
            join_host, join_port, mode = client, port, "lan"
        elif vpn:
            join_host, join_port, mode = client, port, "vpn"
        else:
            log_event("host-unreachable", version=clip(data.get("version"), "version"))
            return self.send(409, {"error": "unreachable", "address": client})
        now = time.monotonic()
        host_class = clip(data.get("host_class"), "class").lower()
        with LOBBIES.lock:
            LOBBIES.expire()
            for stale in [key for key, lobby in LOBBIES.lobbies.items() if lobby["address"] == client and lobby["port"] == port]:
                LOBBIES.close(stale, "replaced")
            if sum(1 for lobby in LOBBIES.lobbies.values() if lobby["address"] == client) >= MAX_LOBBIES_PER_ADDRESS:
                return self.send(429, {"error": "You're already hosting a game."})
            lobby = {
                "id": secrets.token_hex(8),
                "secret": secrets.token_hex(16),
                "code": LOBBIES.new_code(),
                "address": client,
                "port": port,
                "join_host": join_host,
                "join_port": join_port,
                "local": local,
                "vpn": vpn,
                "mode": mode,
                "punch": punch,
                "name": clip(data.get("name"), "name") or "Co-op Game",
                "host_name": clip(data.get("host_name"), "host_name"),
                "host_class": host_class if host_class in CLASSES else "",
                "password": clip(data.get("password"), "password"),
                "listed": listed,
                "difficulty": clip(data.get("difficulty"), "difficulty") or "Normal",
                "max": whole(data.get("max"), 2, 4, 4),
                "mastery_limit": whole(data.get("mastery_limit"), 0, 999, 0),
                "same_class": bool(data.get("same_class", False)),
                "min_mythic": whole(data.get("min_mythic"), 0, 999, 0),
                "pause": bool(data.get("pause", True)),
                "xp": bool(data.get("xp", True)),
                "playing": "",
                "version": clip(data.get("version"), "version"),
                "classes": [host_class] if host_class in CLASSES else [],
                "members": [],
                "players": 1,
                "created": now,
                "seen": now,
            }
            LOBBIES.lobbies[lobby["id"]] = lobby
            log_event("hosted", lobby=lobby["id"], mode=mode, listed=listed, version=lobby["version"], open=len(LOBBIES.lobbies))
        self.send(200, {"id": lobby["id"], "secret": lobby["secret"], "code": lobby["code"], "address": client, "mode": mode, "listed": listed})

    def heartbeat(self, data):
        with LOBBIES.lock:
            lobby = self.owned(data)
            if not lobby:
                return self.send(404, {"error": "gone"})
            members = data.get("members") if isinstance(data.get("members"), list) else []
            lobby["members"] = [{"name": clip(m.get("name"), "host_name"), "class": clip(m.get("class"), "class").lower(),
                                 "mastery": whole(m.get("mastery"), 0, 999, 0)} for m in members[:4] if isinstance(m, dict)]
            lobby["classes"] = [m["class"] for m in lobby["members"] if m["class"] in CLASSES] or lobby["classes"]
            lobby["players"] = max(1, len(lobby["members"]))
            if "pause" in data:
                lobby["pause"] = bool(data.get("pause"))
            if "xp" in data:
                lobby["xp"] = bool(data.get("xp"))
            if "playing" in data:
                lobby["playing"] = clip(data.get("playing"), "playing")
            if lobby.get("mode") == "punch" and punch_address(data.get("punch"), self.client()):
                lobby["punch"] = punch_address(data.get("punch"), self.client())
        self.send(200, {"ok": True})

    def close(self, data):
        with LOBBIES.lock:
            lobby = self.owned(data)
            if lobby:
                LOBBIES.close(lobby["id"])
        self.send(200, {"ok": True})

    def requests(self, data):
        with LOBBIES.lock:
            LOBBIES.expire()
            lobby = self.owned(data)
            if not lobby:
                return self.send(404, {"error": "gone"})
            now = time.monotonic()
            waiting = [{"ask": ask["id"], "punch": ask.get("punch", ""), "name": ask["name"], "class": ask["class"], "race": ask["race"], "mastery": ask["mastery"],
                        "best": ask["best"], "seconds": max(0, int(ASK_SECONDS - (now - ask["created"])))}
                       for ask in LOBBIES.asks.values() if ask["lobby"] == lobby["id"] and ask["state"] == "waiting"]
        self.send(200, {"requests": waiting, "code": lobby["code"]})

    def answer(self, data):
        with LOBBIES.lock:
            lobby = self.owned(data)
            if not lobby:
                return self.send(404, {"error": "gone"})
            ask = LOBBIES.asks.get(data.get("ask"))
            if not ask or ask["lobby"] != lobby["id"] or ask["state"] != "waiting":
                return self.send(404, {"error": "Join request expired."})
            ask["answered"] = time.monotonic()
            if data.get("accept"):
                ask["state"] = "accepted"
                log_event("join-accepted", lobby=lobby["id"], players=lobby["players"])
                same_network = ask["address"] == lobby["address"] and lobby.get("local")
                join_host, join_port = (lobby["local"], lobby["port"]) if same_network else (lobby["join_host"], lobby["join_port"])
                session = session_id(data.get("session"))
                use_punch = not same_network and lobby.get("mode") == "punch" and session and ask.get("punch")
                ask["join"] = {"punch": lobby["punch"] if use_punch else "", "session": session if use_punch else "",
                               "address": join_host, "port": join_port, "vpn": lobby.get("vpn", []), "vpn_port": lobby["port"],
                               "vpn_only": lobby.get("mode") == "vpn",
                               "token": str(data.get("token", ""))[:64],
                               "user": str(data.get("user", ""))[:16], "password": str(data.get("password", ""))[:16]}
            else:
                ask["state"] = "declined"
                log_event("join-declined", lobby=lobby["id"])
                ask["reason"] = str(data.get("reason", ""))[:120]
                LOBBIES.declined[(lobby["id"], ask["address"], ask["name"])] = time.monotonic()
        self.send(200, {"ok": True})

    def ask(self, data):
        client = self.client()
        if not LIMITER.allow("ask", client):
            return self.send(429, {"error": "Too many requests. Try again in a few minutes."})
        with LOBBIES.lock:
            LOBBIES.expire()
            lobby = LOBBIES.find(data.get("id"), data.get("code"))
            if not lobby:
                return self.send(404, {"error": "No game found with that code." if data.get("code") else "That game has ended."})
            if not visible_to(lobby, client):
                return self.send(403, {"error": "That game only takes players on the host's network."})
            if lobby["version"] != clip(data.get("version"), "version"):
                return self.send(409, {"error": "Version mismatch: that game runs a different version of Hordes of Azeroth."})
            declined_at = LOBBIES.declined.get((lobby["id"], client, clip(data.get("name"), "host_name")))
            if declined_at is not None:
                wait = int(DECLINE_WAIT_SECONDS - (time.monotonic() - declined_at) + 0.999)
                if wait > 0:
                    return self.send(429, {"error": "The host declined your request. You can ask again in %d seconds." % wait})
            if lobby["password"] and not secrets.compare_digest(lobby["password"], clip(data.get("password"), "password")):
                return self.send(403, {"error": "Incorrect password."})
            if lobby["players"] >= lobby["max"]:
                return self.send(409, {"error": "Game is full."})
            pending = sum(1 for ask in LOBBIES.asks.values() if ask["lobby"] == lobby["id"] and ask["state"] == "waiting")
            if lobby["players"] + pending >= lobby["max"]:
                return self.send(409, {"error": "Every open slot has a pending join request. Try again shortly."})
            wanted = clip(data.get("class"), "class").lower()
            if wanted in lobby["classes"] and not lobby.get("same_class"):
                return self.send(409, {"error": "Party already has that class."})
            best = whole(data.get("best"), 0, 9999, 0)
            if lobby.get("min_mythic") and best < MYTHIC_START + lobby["min_mythic"]:
                return self.send(409, {"error": "Requires Mythic %d cleared." % lobby["min_mythic"]})
            mastery = whole(data.get("mastery"), 0, 999, 0)
            if lobby["mastery_limit"] and mastery > lobby["mastery_limit"]:
                return self.send(409, {"error": "Requires Mastery %d or lower." % lobby["mastery_limit"]})
            if sum(1 for ask in LOBBIES.asks.values() if ask["address"] == client and ask["state"] == "waiting") >= MAX_OPEN_ASKS_PER_ADDRESS:
                return self.send(429, {"error": "You already have a pending join request."})
            ask = {"id": secrets.token_hex(12), "lobby": lobby["id"], "address": client, "state": "waiting", "created": time.monotonic(),
                   "answered": 0.0, "name": clip(data.get("name"), "host_name"), "class": wanted, "race": clip(data.get("race"), "race"),
                   "mastery": mastery, "best": best, "punch": punch_address(data.get("punch"), client)}
            LOBBIES.asks[ask["id"]] = ask
            log_event("join-asked", lobby=lobby["id"], code=bool(data.get("code")))
            view = public_view(lobby, time.monotonic())
        self.send(200, {"ask": ask["id"], "lobby": view, "seconds": ASK_SECONDS})

    def ask_state(self, data):
        if not LIMITER.allow("poll", self.client()):
            return self.send(429, {"error": "Too many requests."})
        with LOBBIES.lock:
            LOBBIES.expire()
            ask = LOBBIES.asks.get(data.get("ask"))
            if not ask:
                return self.send(404, {"state": "gone"})
            answer = {"state": ask["state"]}
            if ask["state"] == "accepted":
                answer["join"] = ask["join"]
            if ask["state"] == "declined":
                answer["reason"] = ask.get("reason", "")
        self.send(200, answer)

    def ask_cancel(self, data):
        with LOBBIES.lock:
            ask = LOBBIES.asks.get(data.get("ask"))
            if ask and ask["state"] == "waiting":
                ask["state"] = "cancelled"
                ask["answered"] = time.monotonic()
        self.send(200, {"ok": True})


def main():
    if PUNCH_PORT:
        threading.Thread(target=reflect_forever, daemon=True).start()
    server = ThreadingHTTPServer((BIND, PORT), Handler)
    server.daemon_threads = True
    server.serve_forever()


if __name__ == "__main__":
    main()

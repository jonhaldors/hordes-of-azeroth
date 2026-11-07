using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json.Nodes;
using System.Threading;
using System.Threading.Tasks;

namespace HordesOfAzeroth.Launcher
{
    sealed class CoopAgent : IDisposable
    {
        const int DefaultAgentPort = 3727;
        const int DefaultGatePort = 3725;
        const int RequestLimit = 16 * 1024;
        static readonly TimeSpan PollInterval = TimeSpan.FromSeconds(2);
        static readonly TimeSpan HeartbeatInterval = TimeSpan.FromSeconds(30);
        static readonly TimeSpan ListMaxAge = TimeSpan.FromSeconds(3);
        static readonly TimeSpan LobbyTimeout = TimeSpan.FromSeconds(8);
        static readonly string LobbyUrl = ResolveLobbyUrl();
        static readonly HttpClient LobbyClient = CreateLobbyClient();

        readonly GameFolder m_folder;
        readonly CoopAccounts m_accounts;
        readonly CoopTransfer m_transfer;
        static readonly TimeSpan LedgerInterval = TimeSpan.FromSeconds(1);
        static readonly TimeSpan GuestSilenceLimit = TimeSpan.FromMinutes(2);
        static readonly TimeSpan LeaveWait = TimeSpan.FromSeconds(25);
        static readonly TimeSpan HostSilenceLimit = TimeSpan.FromMinutes(3);
        static readonly TimeSpan AdmissionLimit = TimeSpan.FromSeconds(90);
        static readonly TimeSpan FinalPullWait = TimeSpan.FromSeconds(30);
        static readonly TimeSpan DrainCap = TimeSpan.FromSeconds(30);
        static readonly TimeSpan AskGrace = TimeSpan.FromSeconds(30);
        static readonly TimeSpan LobbyQuietLimit = TimeSpan.FromSeconds(60);
        static readonly TimeSpan SpoolRetry = TimeSpan.FromSeconds(15);
        const int RefusalsBeforeEnd = 5;
        const int CoopProtocol = 2;
        static readonly TimeSpan VpnPingWait = TimeSpan.FromSeconds(3);
        readonly CancellationTokenSource m_stop = new CancellationTokenSource();
        readonly ConcurrentDictionary<string, JoinState> m_joins = new ConcurrentDictionary<string, JoinState>();
        readonly object m_lock = new object();
        TcpListener m_listener;
        Task m_closing = Task.CompletedTask;
        HostState m_host;
        List<Dictionary<string, string>> m_list = new List<Dictionary<string, string>>();
        DateTime m_listAt = DateTime.MinValue;
        string m_listError = "";
        bool m_listing;

        sealed class Member
        {
            public string Name;
            public string Class;
            public string Mastery;
            public string Token;
            public string GuestUser;
            public string CharacterName;
            public DateTime AcceptedAt = DateTime.UtcNow;
            public bool Uploaded;
        }

        sealed class Request
        {
            public string Ask;
            public string Name;
            public string Class;
            public string Race;
            public string Mastery;
            public string Best;
            public string Seconds;
            public string Punch;
        }

        sealed class HostState
        {
            public string State = "starting";
            public string Message = "";
            public string Warning = "";
            public string Notice = "";
            public string Id;
            public string Secret;
            public string Code = "";
            public string SentSettings = "";
            public Dictionary<string, string> Settings;
            public CoopGate Gate;
            public CoopPorts Ports;
            public CoopPunch Punch;
            public string Mode = "";
            public List<Member> Members = new List<Member>();
            public List<Request> Requests = new List<Request>();
            public HashSet<string> Answered = new HashSet<string>();
            public CancellationTokenSource Stop = new CancellationTokenSource();
            public Task Opening = Task.CompletedTask;
        }

        sealed class JoinState
        {
            public string Who = "";
            public string State = "asking";
            public string Message = "";
            public DateTime AskedAt = DateTime.UtcNow;
            public DateTime LastContact = DateTime.UtcNow;
            public DateTime RejoinSince = DateTime.UtcNow;
            public bool Direct;
            public int Refusals;
            public int Ending;
            public string Ask;
            public string Seconds = "";
            public string Lobby = "";
            public string Address = "";
            public string Token = "";
            public string User = "";
            public string Password = "";
            public string OwnAccount = "";
            public string OwnName = "";
            public string OwnGuid;
            public CancellationTokenSource Sync;
            public bool EnterOnLogin;
            public long LedgerSeq;
            public string LedgerProblem;
            public int RejoinTries;
            public bool Removed;
            public bool Cancelled;
            public CoopPunch Punch;
            public CoopTunnel Tunnel;

            public void EndNetwork()
            {
                Tunnel?.Dispose();
                Punch?.Dispose();
                Tunnel = null;
                Punch = null;
            }
        }

        static GameFolder s_logFolder;

        static void Log(string text)
        {
            Console.Error.WriteLine(text);
            if (s_logFolder != null)
                LauncherLog.Write(s_logFolder, text);
        }

        public CoopAgent(GameFolder folder)
        {
            m_folder = folder;
            s_logFolder = folder;
            m_accounts = new CoopAccounts(folder);
            m_transfer = new CoopTransfer(folder);
        }

        public bool IsHosting
        {
            get
            {
                lock (m_lock)
                    return m_host != null && m_host.State == "hosting";
            }
        }

        public string Describe()
        {
            lock (m_lock)
            {
                if (m_host == null || m_host.State != "hosting")
                    return "";
                return $"Hosting \"{m_host.Settings.GetValueOrDefault("name")}\": {m_host.Members.Count} of {m_host.Settings.GetValueOrDefault("max", "4")} players, code {m_host.Code}";
            }
        }

        public void Start()
        {
            m_listener = new TcpListener(IPAddress.Loopback, Port("HOA_COOP_PORT", DefaultAgentPort));
            m_listener.Start();
            ResumeSavedJoins();
            _ = AcceptLoopAsync();
            _ = SpoolLoopAsync();
        }

        public void Dispose()
        {
            m_stop.Cancel();
            m_listener?.Stop();
            try
            {
                CloseCurrentHost().Wait(TimeSpan.FromSeconds(40));
            }
            catch (Exception)
            {
            }
        }

        static string ResolveLobbyUrl()
        {
            string fromEnvironment = Environment.GetEnvironmentVariable("HOA_LOBBY_URL");
            if (!string.IsNullOrEmpty(fromEnvironment))
                return fromEnvironment.TrimEnd('/');
            return (typeof(CoopAgent).Assembly
                .GetCustomAttributes(typeof(System.Reflection.AssemblyMetadataAttribute), false)
                .Cast<System.Reflection.AssemblyMetadataAttribute>()
                .FirstOrDefault(a => a.Key == "LobbyUrl")?.Value ?? "").TrimEnd('/');
        }

        static int Port(string variable, int fallback) =>
            int.TryParse(Environment.GetEnvironmentVariable(variable), out int port) ? port : fallback;

        string Version => File.Exists(m_folder.VersionFile) ? File.ReadAllText(m_folder.VersionFile).Trim() : "dev";

        async Task AcceptLoopAsync()
        {
            while (!m_stop.IsCancellationRequested)
            {
                TcpClient client;
                try
                {
                    client = await m_listener.AcceptTcpClientAsync(m_stop.Token);
                }
                catch (Exception)
                {
                    if (m_stop.IsCancellationRequested)
                        return;
                    continue;
                }
                _ = ServeAsync(client);
            }
        }

        async Task ServeAsync(TcpClient client)
        {
            using (client)
            {
                NetworkStream stream = client.GetStream();
                (string method, string path, Dictionary<string, string> query, Dictionary<string, string> form) = await ReadRequestAsync(stream);
                string answer;
                int status = 200;
                try
                {
                    answer = method == null ? throw new CoopError("Invalid request.") : await RouteAsync(method, path, query, form);
                }
                catch (CoopError error)
                {
                    status = 400;
                    answer = CoopText.Localize(error.Message);
                }
                catch (Exception error)
                {
                    status = 500;
                    answer = CoopText.Localize(error.Message);
                }
                byte[] body = Encoding.UTF8.GetBytes(answer);
                byte[] head = Encoding.ASCII.GetBytes($"HTTP/1.0 {status} {(status == 200 ? "OK" : "Error")}\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: {body.Length}\r\n\r\n");
                try
                {
                    await stream.WriteAsync(head);
                    await stream.WriteAsync(body);
                }
                catch (Exception)
                {
                }
            }
        }

        sealed class CoopError : Exception
        {
            public CoopError(string message) : base(message)
            {
            }
        }

        static async Task<(string, string, Dictionary<string, string>, Dictionary<string, string>)> ReadRequestAsync(NetworkStream stream)
        {
            using CancellationTokenSource timeout = new CancellationTokenSource(TimeSpan.FromSeconds(3));
            List<byte> raw = new List<byte>();
            byte[] buffer = new byte[4096];
            int headEnd = -1;
            try
            {
                while (raw.Count < RequestLimit)
                {
                    int read = await stream.ReadAsync(buffer, timeout.Token);
                    if (read == 0)
                        break;
                    raw.AddRange(buffer.Take(read));
                    if (headEnd < 0)
                        headEnd = IndexOfBlankLine(raw);
                    if (headEnd >= 0)
                    {
                        int length = ContentLength(Encoding.ASCII.GetString(raw.ToArray(), 0, headEnd));
                        if (raw.Count >= headEnd + 4 + length)
                            break;
                    }
                }
            }
            catch (Exception)
            {
                return (null, null, null, null);
            }
            if (headEnd < 0)
                return (null, null, null, null);
            string head = Encoding.ASCII.GetString(raw.ToArray(), 0, headEnd);
            string body = Encoding.UTF8.GetString(raw.ToArray(), headEnd + 4, raw.Count - headEnd - 4);
            string[] request = head.Split("\r\n")[0].Split(' ');
            if (request.Length < 2)
                return (null, null, null, null);
            string[] target = request[1].Split('?', 2);
            return (request[0], target[0], ParseForm(target.Length > 1 ? target[1] : ""), ParseForm(body));
        }

        static int IndexOfBlankLine(List<byte> raw)
        {
            for (int i = 0; i + 3 < raw.Count; i++)
                if (raw[i] == '\r' && raw[i + 1] == '\n' && raw[i + 2] == '\r' && raw[i + 3] == '\n')
                    return i;
            return -1;
        }

        static int ContentLength(string head)
        {
            foreach (string line in head.Split("\r\n"))
                if (line.StartsWith("Content-Length:", StringComparison.OrdinalIgnoreCase) && int.TryParse(line.Substring(15).Trim(), out int length))
                    return Math.Min(length, RequestLimit);
            return 0;
        }

        static Dictionary<string, string> ParseForm(string text)
        {
            Dictionary<string, string> form = new Dictionary<string, string>();
            foreach (string pair in text.Split('&', StringSplitOptions.RemoveEmptyEntries))
            {
                string[] parts = pair.Split('=', 2);
                form[Uri.UnescapeDataString(parts[0].Replace('+', ' '))] = parts.Length > 1 ? Uri.UnescapeDataString(parts[1].Replace('+', ' ')) : "";
            }
            return form;
        }

        static string Clean(string value) => (value ?? "").Replace('\t', ' ').Replace('\n', ' ').Replace('\r', ' ');

        static string Line(params string[] fields) => string.Join('\t', fields.Select(Clean)) + "\n";

        Task<string> RouteAsync(string method, string path, Dictionary<string, string> query, Dictionary<string, string> form)
        {
            string who = query.GetValueOrDefault("who", "");
            return (method, path) switch
            {
                ("GET", "/lobbies") => Task.FromResult(Lobbies()),
                ("POST", "/ask") => AskAsync(who, form),
                ("GET", "/join") => Task.FromResult(JoinStatus(who)),
                ("POST", "/join/cancel") => Task.FromResult(CancelAsk(who)),
                ("POST", "/join/done") => Task.FromResult(MarkJoined(who)),
                ("POST", "/join/leave") => Task.FromResult(Leave(who)),
                ("POST", "/join/removed") => Task.FromResult(Removed()),
                ("POST", "/join/rejoin") => Task.FromResult(Rejoin(who)),
                ("POST", "/join/entered") => Task.FromResult(Entered(who)),
                ("POST", "/host") => Task.FromResult(StartHosting(form)),
                ("GET", "/host") => Task.FromResult(HostStatus()),
                ("POST", "/host/answer") => Task.FromResult(Answer(form.GetValueOrDefault("ask", ""), form.GetValueOrDefault("accept") == "1")),
                ("POST", "/host/stop") => Task.FromResult(StopHosting()),
                _ => throw new CoopError("Unknown request."),
            };
        }

        void RequireLobby()
        {
            if (LobbyUrl.Length == 0)
                throw new CoopError("Co-op isn't available in this build.");
        }

        async Task<JsonNode> LobbyAsync(HttpMethod method, string path, JsonObject body = null)
        {
            RequireLobby();
            using CancellationTokenSource timeout = new CancellationTokenSource(LobbyTimeout);
            using HttpRequestMessage request = new HttpRequestMessage(method, LobbyUrl + path);
            if (body != null)
                request.Content = new StringContent(body.ToJsonString(), Encoding.UTF8, "application/json");
            HttpResponseMessage response;
            try
            {
                response = await LobbyClient.SendAsync(request, timeout.Token);
            }
            catch (Exception)
            {
                throw new CoopError("Can't connect to the co-op service. Try again later.");
            }
            using (response)
            {
                string text = await response.Content.ReadAsStringAsync();
                JsonNode node;
                try
                {
                    node = JsonNode.Parse(text);
                }
                catch (Exception)
                {
                    throw new CoopError("The co-op service sent an invalid response.");
                }
                if (!response.IsSuccessStatusCode)
                    throw new LobbyRefusal((int)response.StatusCode, node?["error"]?.GetValue<string>() ?? "The co-op service refused the request.", node);
                return node;
            }
        }

        static HttpClient CreateLobbyClient()
        {
            HttpClient client = new HttpClient(new SocketsHttpHandler { ConnectCallback = ConnectPreferringIPv4Async }) { Timeout = Timeout.InfiniteTimeSpan };
            client.DefaultRequestHeaders.UserAgent.ParseAdd("HordesOfAzerothLauncher");
            return client;
        }

        internal static async ValueTask<Stream> ConnectPreferringIPv4Async(SocketsHttpConnectionContext context, CancellationToken cancel)
        {
            IPAddress[] addresses = await Dns.GetHostAddressesAsync(context.DnsEndPoint.Host, cancel);
            Exception last = new SocketException((int)SocketError.HostNotFound);
            foreach (IPAddress address in addresses.OrderBy(a => a.AddressFamily == AddressFamily.InterNetwork ? 0 : 1))
            {
                Socket socket = new Socket(address.AddressFamily, SocketType.Stream, ProtocolType.Tcp) { NoDelay = true };
                try
                {
                    await socket.ConnectAsync(address, context.DnsEndPoint.Port, cancel);
                    return new NetworkStream(socket, true);
                }
                catch (Exception error)
                {
                    socket.Dispose();
                    last = error;
                    if (cancel.IsCancellationRequested)
                        break;
                }
            }
            throw last;
        }

        async Task<CoopPunch> StartPunchAsync()
        {
            try
            {
                JsonNode answer = await LobbyAsync(HttpMethod.Get, "/punch");
                return await CoopPunch.StartAsync(answer["address"]?.ToString());
            }
            catch (Exception)
            {
                return null;
            }
        }

        static readonly string[] VpnAdapterWords = { "Radmin", "Hamachi", "ZeroTier", "Tailscale", "WireGuard", "OpenVPN", "TAP-Windows", "Wintun" };

        static bool IsVpnRange(IPAddress address)
        {
            byte[] bytes = address.GetAddressBytes();
            return bytes[0] == 25 || bytes[0] == 26 || (bytes[0] == 100 && (bytes[1] & 0xC0) == 64);
        }

        static List<string> VpnAddresses()
        {
            List<string> found = new List<string>();
            try
            {
                foreach (NetworkInterface adapter in NetworkInterface.GetAllNetworkInterfaces())
                {
                    if (adapter.OperationalStatus != OperationalStatus.Up)
                        continue;
                    bool named = VpnAdapterWords.Any(word => adapter.Description.Contains(word, StringComparison.OrdinalIgnoreCase) ||
                        adapter.Name.Contains(word, StringComparison.OrdinalIgnoreCase));
                    foreach (UnicastIPAddressInformation info in adapter.GetIPProperties().UnicastAddresses)
                        if (info.Address.AddressFamily == AddressFamily.InterNetwork && !IPAddress.IsLoopback(info.Address) && (named || IsVpnRange(info.Address)))
                            found.Add(info.Address.ToString());
                }
            }
            catch (NetworkInformationException)
            {
            }
            return found.Distinct().Take(4).ToList();
        }

        static async Task<string> FirstVpnGateAsync(JsonNode details)
        {
            if (details?["vpn"] is not JsonArray addresses || addresses.Count == 0 || VpnAddresses().Count == 0)
                return null;
            int port = int.TryParse(details?["vpn_port"]?.ToString(), out int value) ? value : 0;
            if (port <= 0)
                return null;
            List<Task<string>> tries = addresses.Select(node => node?.ToString()).Where(text => IPAddress.TryParse(text, out _))
                .Select(text => PingGateAsync(text, port)).ToList();
            while (tries.Count > 0)
            {
                Task<string> done = await Task.WhenAny(tries);
                tries.Remove(done);
                if (done.Result != null)
                    return done.Result;
            }
            return null;
        }

        static async Task<string> PingGateAsync(string address, int port)
        {
            try
            {
                using TcpClient client = new TcpClient(AddressFamily.InterNetwork);
                using CancellationTokenSource timeout = new CancellationTokenSource(VpnPingWait);
                await client.ConnectAsync(address, port, timeout.Token);
                NetworkStream stream = client.GetStream();
                await stream.WriteAsync(Encoding.ASCII.GetBytes("HOA1 PING\n"), timeout.Token);
                return await CoopGate.ReadLineAsync(stream, VpnPingWait) == "HOA1 PONG" ? address + ":" + port : null;
            }
            catch (Exception)
            {
                return null;
            }
        }

        static string LocalAddress()
        {
            try
            {
                using Socket probe = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, ProtocolType.Udp);
                probe.Connect("1.1.1.1", 53);
                return ((IPEndPoint)probe.LocalEndPoint).Address.ToString();
            }
            catch (SocketException)
            {
                return "";
            }
        }

        sealed class LobbyRefusal : Exception
        {
            public int Status { get; }
            public JsonNode Body { get; }

            public LobbyRefusal(int status, string message, JsonNode body) : base(message)
            {
                Status = status;
                Body = body;
            }
        }

        string Lobbies()
        {
            bool refresh;
            lock (m_lock)
            {
                refresh = !m_listing && DateTime.UtcNow - m_listAt > ListMaxAge;
                if (refresh)
                    m_listing = true;
            }
            if (refresh)
                _ = RefreshListAsync();
            StringBuilder text = new StringBuilder();
            lock (m_lock)
            {
                if (m_listAt == DateTime.MinValue && m_listError.Length == 0)
                    text.Append(Line("loading"));
                if (m_listError.Length > 0)
                    text.Append(Line("error", m_listError));
                foreach (Dictionary<string, string> lobby in m_list)
                    text.Append(Line("lobby", lobby["id"], lobby["name"], lobby["host"], lobby["host_class"], lobby["classes"], lobby["difficulty"],
                        lobby["players"], lobby["max"], lobby["locked"], lobby["mastery_limit"], lobby["members"], lobby["same_class"], lobby["min_mythic"], lobby["pause"], lobby["xp"], lobby["playing"], lobby["lan"]));
            }
            return text.ToString();
        }

        async Task RefreshListAsync()
        {
            try
            {
                JsonNode answer = await LobbyAsync(HttpMethod.Get, "/lobbies?version=" + Uri.EscapeDataString(Version));
                List<Dictionary<string, string>> list = new List<Dictionary<string, string>>();
                foreach (JsonNode lobby in answer["lobbies"]?.AsArray() ?? new JsonArray())
                {
                    string members = string.Join(";", (lobby["members"]?.AsArray() ?? new JsonArray())
                        .Select(m => $"{m?["name"]}:{m?["class"]}:{m?["mastery"]}"));
                    list.Add(new Dictionary<string, string>
                    {
                        ["id"] = lobby["id"]?.ToString() ?? "",
                        ["name"] = lobby["name"]?.ToString() ?? "",
                        ["host"] = lobby["host"]?.ToString() ?? "",
                        ["host_class"] = lobby["host_class"]?.ToString() ?? "",
                        ["classes"] = string.Join(",", (lobby["classes"]?.AsArray() ?? new JsonArray()).Select(c => c?.ToString())),
                        ["difficulty"] = lobby["difficulty"]?.ToString() ?? "",
                        ["players"] = lobby["players"]?.ToString() ?? "1",
                        ["max"] = lobby["max"]?.ToString() ?? "4",
                        ["locked"] = lobby["locked"]?.GetValue<bool>() == true ? "1" : "0",
                        ["mastery_limit"] = lobby["mastery_limit"]?.ToString() ?? "0",
                        ["members"] = members,
                        ["same_class"] = lobby["same_class"]?.GetValue<bool>() == true ? "1" : "0",
                        ["min_mythic"] = lobby["min_mythic"]?.ToString() ?? "0",
                        ["pause"] = lobby["pause"]?.GetValue<bool>() == false ? "0" : "1",
                        ["xp"] = lobby["xp"]?.GetValue<bool>() == false ? "0" : "1",
                        ["playing"] = lobby["playing"]?.ToString() ?? "",
                        ["lan"] = lobby["lan"]?.GetValue<bool>() == true ? "1" : "0",
                    });
                }
                lock (m_lock)
                {
                    m_list = list;
                    m_listError = "";
                    m_listAt = DateTime.UtcNow;
                }
            }
            catch (Exception error)
            {
                lock (m_lock)
                {
                    m_listError = error.Message;
                    m_listAt = DateTime.UtcNow;
                }
            }
            finally
            {
                lock (m_lock)
                    m_listing = false;
            }
        }

        async Task RequireRegularAccountAsync(Dictionary<string, string> form, string doing)
        {
            if (Environment.GetEnvironmentVariable("HOA_COOP_ALLOW_GM") == "1")
                return;
            if (await m_accounts.IsGameMasterAsync(form.GetValueOrDefault("account", "")))
                throw new CoopError($"{doing} only works on a regular account. This account is a game master account.");
        }

        Task<string> AskAsync(string who, Dictionary<string, string> form)
        {
            if (m_joins.TryGetValue(who, out JoinState old))
            {
                if (old.State == "accepted" || old.State == "joined" || old.State == "returning" || old.State == "transferring")
                    throw new CoopError("You're still in a co-op game. Leave it first.");
                if (old.State == "home" && m_transfer.ReadSpool(who).Length > 0)
                    throw new CoopError("Your last co-op rewards are still being saved. Try again in a moment.");
                CancelAsk(who);
            }
            JoinState join = new JoinState { Who = who, OwnAccount = form.GetValueOrDefault("account", ""), OwnName = form.GetValueOrDefault("name", "") };
            m_joins[who] = join;
            _ = SendAskAsync(join, form);
            return Task.FromResult(JoinStatus(who));
        }

        async Task SendAskAsync(JoinState join, Dictionary<string, string> form)
        {
            JsonObject body = new JsonObject
            {
                ["id"] = form.GetValueOrDefault("id", ""),
                ["code"] = form.GetValueOrDefault("code", ""),
                ["password"] = form.GetValueOrDefault("password", ""),
                ["name"] = form.GetValueOrDefault("name", ""),
                ["class"] = form.GetValueOrDefault("class", ""),
                ["race"] = form.GetValueOrDefault("race", ""),
                ["mastery"] = form.GetValueOrDefault("mastery", "0"),
                ["best"] = form.GetValueOrDefault("best", "0"),
                ["version"] = Version,
                ["protocol"] = CoopProtocol,
            };
            try
            {
                await RequireRegularAccountAsync(form, "Joining a co-op game");
                CoopPunch punch = await StartPunchAsync();
                if (join.Cancelled)
                {
                    punch?.Dispose();
                    return;
                }
                join.Punch = punch;
                body["punch"] = punch?.PublicEndPoint?.ToString() ?? "";
                JsonNode answer = await LobbyAsync(HttpMethod.Post, "/ask", body);
                join.Ask = answer["ask"]?.ToString();
                if (join.Cancelled)
                {
                    join.EndNetwork();
                    await CancelAtLobbyAsync(join);
                    return;
                }
                join.Seconds = answer["seconds"]?.ToString() ?? "30";
                join.Lobby = answer["lobby"]?["name"]?.ToString() ?? "";
                join.AskedAt = DateTime.UtcNow;
                join.State = "waiting";
                _ = PollAskAsync(join);
            }
            catch (Exception error)
            {
                FailJoin(join, JoinFailureText(error));
            }
        }

        async Task CancelAtLobbyAsync(JoinState join)
        {
            if (join.Ask == null)
                return;
            try
            {
                await LobbyAsync(HttpMethod.Post, "/ask/cancel", new JsonObject { ["ask"] = join.Ask });
            }
            catch (Exception)
            {
            }
        }

        const string HostUnreachable = "Couldn't connect to the host. Their router doesn't accept direct connections, and the backup connection between your two networks failed too. The host can forward TCP port 3725, you can host the game yourself if your port is forwarded, or you can both join the same VPN, such as Radmin VPN, ZeroTier or Hamachi.";

        static string JoinFailureText(Exception error) => error switch
        {
            OperationCanceledException => "Couldn't reach the host. Try again.",
            IOException or SocketException => "Lost connection to the host. Try again.",
            _ => error.Message,
        };

        static void FailJoin(JoinState join, string message, string state = "error")
        {
            Log("Co-op: joining ended (" + state + "): " + message);
            join.EndNetwork();
            join.Message = message;
            join.State = state;
        }

        async Task PollAskAsync(JoinState join)
        {
            DateTime lastHeard = DateTime.UtcNow;
            TimeSpan answerWait = TimeSpan.FromSeconds(int.TryParse(join.Seconds, out int seconds) ? seconds : 30) + AskGrace;
            while (join.State == "waiting" && !join.Cancelled && !m_stop.IsCancellationRequested)
            {
                await Task.Delay(TimeSpan.FromSeconds(1.5));
                if (join.State != "waiting" || join.Cancelled)
                    return;
                if (DateTime.UtcNow - lastHeard > LobbyQuietLimit)
                {
                    FailJoin(join, "Can't connect to the co-op service. Try again later.");
                    return;
                }
                if (DateTime.UtcNow - join.AskedAt > answerWait)
                {
                    FailJoin(join, "The host didn't respond.", "ended");
                    _ = CancelAtLobbyAsync(join);
                    return;
                }
                JsonNode answer;
                try
                {
                    answer = await LobbyAsync(HttpMethod.Post, "/ask/state", new JsonObject { ["ask"] = join.Ask });
                    lastHeard = DateTime.UtcNow;
                }
                catch (LobbyRefusal refusal) when (refusal.Status == 404)
                {
                    FailJoin(join, "The join request expired. Ask again.", "ended");
                    return;
                }
                catch (Exception)
                {
                    continue;
                }
                string state = answer["state"]?.ToString() ?? "gone";
                if (state == "accepted")
                {
                    await AcceptedAsync(join, answer["join"]);
                    return;
                }
                if (state != "waiting")
                {
                    FailJoin(join, state switch
                    {
                        "declined" => answer["reason"]?.ToString() ?? "",
                        "expired" => "The host didn't respond.",
                        "gone" => "The host closed the lobby.",
                        _ => "",
                    }, state == "declined" ? "declined" : "ended");
                    return;
                }
            }
        }

        async Task AcceptedAsync(JoinState join, JsonNode details)
        {
            if (join.Cancelled)
            {
                join.EndNetwork();
                return;
            }
            try
            {
                string address = details?["address"]?.ToString() ?? "";
                if (address.Contains(':'))
                    address = "[" + address + "]";
                join.Address = address + ":" + details?["port"];
                join.Token = details?["token"]?.ToString() ?? "";
                join.User = details?["user"]?.ToString() ?? "";
                join.Password = details?["password"]?.ToString() ?? "";
                join.State = "transferring";
                string vpnGate = await FirstVpnGateAsync(details);
                if (vpnGate != null)
                {
                    join.Address = vpnGate;
                    join.EndNetwork();
                }
                else if (details?["vpn_only"]?.ToString() == "true")
                {
                    FailJoin(join, "Couldn't connect to the host: they can only be reached over their VPN. Join the same VPN network as the host, such as Radmin VPN, ZeroTier or Hamachi, and try again.");
                    return;
                }
                else if (!await OpenTunnelAsync(join, details))
                {
                    FailJoin(join, HostUnreachable);
                    return;
                }
                await BringCharacterAsync(join);
            }
            catch (Exception error)
            {
                FailJoin(join, JoinFailureText(error));
            }
        }

        static async Task<bool> OpenTunnelAsync(JoinState join, JsonNode details)
        {
            string session = details?["session"]?.ToString() ?? "";
            if (join.Punch == null || !CoopPunch.TryParseEndPoint(details?["punch"]?.ToString(), out IPEndPoint host) ||
                !ulong.TryParse(session, System.Globalization.NumberStyles.HexNumber, null, out ulong id))
            {
                join.EndNetwork();
                return true;
            }
            CoopLink link = join.Punch.Open(id, host);
            if (await Task.WhenAny(link.Connected, Task.Delay(TimeSpan.FromSeconds(15))) != link.Connected || !link.Connected.Result)
            {
                link.Close();
                return false;
            }
            join.Tunnel = new CoopTunnel(link);
            join.Address = join.Tunnel.Address;
            return true;
        }

        string JoinStatus(string who)
        {
            if (!m_joins.TryGetValue(who, out JoinState join))
                return Line("state", "none");
            return join.State switch
            {
                "asking" => Line("state", "asking"),
                "accepted" => Line("state", "accepted", join.Address, join.Token, join.User, join.Password, join.OwnName),
                "waiting" => Line("state", "waiting", join.Lobby, join.Seconds),
                "transferring" => Line("state", "transferring", join.Lobby),
                "returning" => Line("state", "returning"),
                "joined" => Line("state", "joined", join.Address, join.Token, join.User, join.Password, join.EnterOnLogin ? "1" : "0", join.OwnName),
                _ => Line("state", join.State, CoopText.Localize(join.Message)),
            };
        }

        string CancelAsk(string who)
        {
            if (!m_joins.TryGetValue(who, out JoinState join))
                return Line("state", "none");
            join.Cancelled = true;
            if (join.State == "accepted" || join.State == "joined")
                return Leave(who);
            if (join.State == "returning" || join.State == "transferring")
                return JoinStatus(who);
            m_joins.TryRemove(who, out _);
            join.EndNetwork();
            if (join.State == "waiting")
            {
                join.State = "cancelled";
                _ = CancelAtLobbyAsync(join);
            }
            return Line("state", "none");
        }

        string Rejoin(string who)
        {
            if (!m_joins.TryGetValue(who, out JoinState join) || (join.State != "joined" && join.State != "accepted"))
                return Line("state", "none");
            if (join.RejoinTries == 0)
                join.RejoinSince = DateTime.UtcNow;
            join.EnterOnLogin = true;
            join.RejoinTries++;
            return Line("state", "rejoin", join.RejoinTries.ToString(), ((int)(DateTime.UtcNow - join.RejoinSince).TotalSeconds).ToString());
        }

        string Entered(string who)
        {
            if (m_joins.TryGetValue(who, out JoinState join))
            {
                join.EnterOnLogin = false;
                join.RejoinTries = 0;
            }
            return JoinStatus(who);
        }

        string MarkJoined(string who)
        {
            if (m_joins.TryGetValue(who, out JoinState join) && join.State == "accepted")
            {
                join.State = "joined";
                SaveJoin(join);
            }
            return JoinStatus(who);
        }

        async Task BringCharacterAsync(JoinState join)
        {
            try
            {
                (string guid, CoopCharacter original) = await m_transfer.ExportAsync(join.OwnName);
                join.OwnGuid = guid;
                using (TcpClient client = await DialHostAsync(join, "UPLOAD"))
                {
                    NetworkStream stream = client.GetStream();
                    using CancellationTokenSource timeout = new CancellationTokenSource(CoopWire.TransferTimeout);
                    await CoopWire.WriteBlobAsync(stream, Encoding.UTF8.GetBytes(original.Name), timeout.Token);
                    await CoopWire.WriteBlobAsync(stream, original.Dump, timeout.Token);
                    await CoopWire.WriteBlobAsync(stream, original.Account, timeout.Token);
                    string answer = await CoopGate.ReadLineAsync(stream, CoopWire.TransferTimeout) ?? "";
                    if (!answer.StartsWith("HOA1 DONE"))
                        throw new InvalidOperationException(answer.StartsWith("HOA1 FAIL ") ? answer.Substring(10) : "The host couldn't take your character.");
                }
                join.Direct = join.Tunnel == null;
                join.LastContact = DateTime.UtcNow;
                join.State = "accepted";
                SaveJoin(join);
                if (join.Cancelled)
                {
                    join.State = "returning";
                    await ReturnCharacterAsync(join);
                    return;
                }
                StartLedgerLoop(join);
            }
            catch (Exception error)
            {
                try
                {
                    if (join.Token.Length > 0)
                        await TellHostLeavingAsync(join);
                }
                catch (Exception)
                {
                }
                FailJoin(join, JoinFailureText(error));
            }
        }

        static async Task<TcpClient> DialHostAsync(JoinState join, string leg)
        {
            int split = join.Address.LastIndexOf(':');
            string host = join.Address.Substring(0, split).Trim('[', ']');
            int port = int.Parse(join.Address.Substring(split + 1));
            TcpClient client = new TcpClient(host.Contains(':') ? AddressFamily.InterNetworkV6 : AddressFamily.InterNetwork);
            try
            {
                using CancellationTokenSource timeout = new CancellationTokenSource(TimeSpan.FromSeconds(10));
                await client.ConnectAsync(host, port, timeout.Token);
                NetworkStream stream = client.GetStream();
                await stream.WriteAsync(Encoding.ASCII.GetBytes($"HOA1 {join.Token} {leg}\n"), timeout.Token);
                return client;
            }
            catch (Exception error) when (error is OperationCanceledException or SocketException or IOException)
            {
                client.Dispose();
                throw new CoopError(HostUnreachable);
            }
            catch (Exception)
            {
                client.Dispose();
                throw;
            }
        }

        void StartLedgerLoop(JoinState join)
        {
            join.Sync = new CancellationTokenSource();
            _ = LedgerLoopAsync(join, join.Sync.Token);
        }

        async Task LedgerLoopAsync(JoinState join, CancellationToken cancel)
        {
            while (!cancel.IsCancellationRequested)
            {
                try
                {
                    await Task.Delay(LedgerInterval, cancel);
                    if (join.Tunnel?.IsClosed == true || DateTime.UtcNow - join.LastContact > HostSilenceLimit)
                    {
                        await EndJoinAsync(join, "silent");
                        return;
                    }
                    m_transfer.MarkAway(join.OwnAccount);
                    string ended = await CarryLedgerAsync(join);
                    if (ended != null)
                    {
                        await EndJoinAsync(join, ended);
                        return;
                    }
                    join.LedgerProblem = null;
                }
                catch (OperationCanceledException) when (cancel.IsCancellationRequested)
                {
                    return;
                }
                catch (Exception error)
                {
                    if (error.Message != join.LedgerProblem)
                        Log("Co-op ledger: " + error.Message);
                    join.LedgerProblem = error.Message;
                }
            }
        }

        static string LedgerGame(JoinState join) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(join.Token))).Substring(0, 32);

        static long SeqOf(string line)
        {
            int tab = line.IndexOf('\t');
            return tab > 0 && long.TryParse(line.Substring(0, tab), out long seq) ? seq : -1;
        }

        async Task<string> CarryLedgerAsync(JoinState join)
        {
            string entries;
            using (TcpClient client = await DialHostAsync(join, "LEDGER"))
            {
                NetworkStream stream = client.GetStream();
                await stream.WriteAsync(Encoding.ASCII.GetBytes(join.LedgerSeq + "\n"));
                string answer = await CoopGate.ReadLineAsync(stream) ?? "";
                if (answer.StartsWith("HOA1 END"))
                {
                    join.LastContact = DateTime.UtcNow;
                    return answer.Length > 9 ? answer.Substring(9).Trim() : "ended";
                }
                if (answer == "HOA1 NO")
                {
                    if (++join.Refusals >= RefusalsBeforeEnd)
                        return "gone";
                    throw new InvalidOperationException("the host's gate doesn't know this game any more");
                }
                if (answer != "HOA1 DATA")
                    throw new InvalidOperationException("the host's gate answered \"" + answer + "\"");
                using CancellationTokenSource timeout = new CancellationTokenSource(CoopWire.TransferTimeout);
                entries = Encoding.UTF8.GetString(await CoopWire.ReadBlobAsync(stream, timeout.Token));
            }
            join.Refusals = 0;
            join.LastContact = DateTime.UtcNow;
            if (entries.Length == 0)
                return null;
            m_transfer.SaveSpool(join.Who, entries);
            string answers = await ApplySpoolAsync(join);
            try
            {
                using TcpClient client = await DialHostAsync(join, "ANSWERS");
                NetworkStream stream = client.GetStream();
                using CancellationTokenSource timeout = new CancellationTokenSource(CoopWire.TransferTimeout);
                await CoopWire.WriteBlobAsync(stream, Encoding.UTF8.GetBytes(answers), timeout.Token);
                await CoopGate.ReadLineAsync(stream);
            }
            catch (Exception error)
            {
                Log("Co-op ledger: answers didn't reach the host: " + error.Message);
            }
            return null;
        }

        async Task<string> ApplySpoolAsync(JoinState join)
        {
            string spool = m_transfer.ReadSpool(join.Who);
            if (spool.Length == 0)
                return "";
            string answers = await m_transfer.ApplyLedgerAsync(join.OwnAccount, LedgerGame(join), join.OwnName, spool);
            foreach (string line in answers.Split('\n'))
            {
                string[] fields = line.Split('\t');
                if (fields.Length < 2 || !long.TryParse(fields[0], out long seq))
                    continue;
                if (fields[1] == "retry")
                    break;
                join.LedgerSeq = Math.Max(join.LedgerSeq, seq);
            }
            string rest = string.Concat(spool.Split('\n').Where(line => SeqOf(line) > join.LedgerSeq).Select(line => line + "\n"));
            if (rest.Length == 0)
                m_transfer.ClearSpool(join.Who);
            else
                m_transfer.SaveSpool(join.Who, rest);
            if (join.State != "home")
                SaveJoin(join);
            return answers;
        }

        static async Task<bool> TellHostLeavingAsync(JoinState join)
        {
            using TcpClient client = await DialHostAsync(join, "LEAVE");
            string answer = await CoopGate.ReadLineAsync(client.GetStream(), LeaveWait) ?? "";
            if (answer != "HOA1 DONE")
                Log("Co-op: the host didn't confirm the leave: " + answer);
            return answer.StartsWith("HOA1 ");
        }

        static string ReasonText(string reason) => reason switch
        {
            "left" => "",
            "removed" => "You were removed from the party.",
            "ended" => "The host ended the game. Your progress is saved.",
            "failed" => "The host couldn't take your character.",
            _ => "Lost the connection to the host. Your progress up to the last few seconds is saved.",
        };

        async Task EndJoinAsync(JoinState join, string reason)
        {
            if (Interlocked.Exchange(ref join.Ending, 1) == 1)
                return;
            join.Sync?.Cancel();
            try
            {
                await ApplySpoolAsync(join);
            }
            catch (Exception error)
            {
                Log("Co-op ledger: rewards wait for your game's server: " + error.Message);
            }
            FinishHome(join, ReasonText(reason));
        }

        void FinishHome(JoinState join, string message)
        {
            Log("Co-op: back home from the host's game" + (message.Length > 0 ? ": " + message : ""));
            m_transfer.ClearAway(join.OwnAccount);
            join.EndNetwork();
            join.Message = join.Removed ? ReasonText("removed") : message;
            join.State = "home";
            if (m_transfer.ReadSpool(join.Who).Length == 0)
                m_transfer.DeleteJoin(join.Who);
            else
                WriteJoin(join);
        }

        void SaveJoin(JoinState join)
        {
            if (join.Ending == 0 && join.State != "home")
                WriteJoin(join);
        }

        void WriteJoin(JoinState join)
        {
            try
            {
                m_transfer.SaveJoin(join.Who, new JsonObject
                {
                    ["who"] = join.Who,
                    ["state"] = join.State,
                    ["address"] = join.Address,
                    ["token"] = join.Token,
                    ["user"] = join.User,
                    ["password"] = join.Password,
                    ["account"] = join.OwnAccount,
                    ["name"] = join.OwnName,
                    ["guid"] = join.OwnGuid,
                    ["seq"] = join.LedgerSeq,
                    ["direct"] = join.Direct,
                    ["removed"] = join.Removed,
                    ["message"] = join.Message,
                }.ToJsonString());
            }
            catch (Exception error)
            {
                Log("Co-op: couldn't save the join: " + error.Message);
            }
        }

        void ResumeSavedJoins()
        {
            foreach (string text in m_transfer.SavedJoins())
            {
                JsonNode node;
                try
                {
                    node = JsonNode.Parse(text);
                }
                catch (Exception)
                {
                    continue;
                }
                JoinState join = new JoinState
                {
                    Who = node?["who"]?.ToString() ?? "",
                    State = node?["state"]?.ToString() ?? "home",
                    Address = node?["address"]?.ToString() ?? "",
                    Token = node?["token"]?.ToString() ?? "",
                    User = node?["user"]?.ToString() ?? "",
                    Password = node?["password"]?.ToString() ?? "",
                    OwnAccount = node?["account"]?.ToString() ?? "",
                    OwnName = node?["name"]?.ToString() ?? "",
                    OwnGuid = node?["guid"]?.ToString(),
                    LedgerSeq = long.TryParse(node?["seq"]?.ToString(), out long seq) ? seq : 0,
                    Direct = node?["direct"]?.ToString() == "true",
                    Removed = node?["removed"]?.ToString() == "true",
                    Message = node?["message"]?.ToString() ?? "",
                };
                if (join.Who.Length == 0 || join.Token.Length == 0)
                    continue;
                m_joins[join.Who] = join;
                if (join.State == "home")
                    continue;
                if ((join.State == "joined" || join.State == "accepted") && join.Direct)
                {
                    join.State = "joined";
                    join.LastContact = DateTime.UtcNow;
                    StartLedgerLoop(join);
                    continue;
                }
                join.State = "returning";
                _ = ReturnCharacterAsync(join);
            }
        }

        async Task SpoolLoopAsync()
        {
            while (!m_stop.IsCancellationRequested)
            {
                try
                {
                    await Task.Delay(SpoolRetry, m_stop.Token);
                }
                catch (OperationCanceledException)
                {
                    return;
                }
                foreach (JoinState join in m_joins.Values.Where(j => j.State == "home").ToList())
                {
                    if (m_transfer.ReadSpool(join.Who).Length == 0)
                        continue;
                    try
                    {
                        await ApplySpoolAsync(join);
                        if (m_transfer.ReadSpool(join.Who).Length == 0)
                            m_transfer.DeleteJoin(join.Who);
                    }
                    catch (Exception)
                    {
                    }
                }
            }
        }

        async Task GuestLeftAsync(HostState host, string token)
        {
            Member member;
            lock (m_lock)
            {
                member = host.Members.FirstOrDefault(m => m.Token == token);
                if (member != null)
                    host.Members.Remove(member);
            }
            if (member == null)
                return;
            host.Gate.Retire(token, "left");
            m_transfer.ForgetJoining(member.GuestUser);
            await m_transfer.LogOutGuestAsync(member.GuestUser);
            host.Gate.CutLinks(token);
            _ = HeartbeatQuietlyAsync(host);
        }

        void DismissGuest(HostState host, Member member, string reason)
        {
            host.Gate?.Retire(member.Token, reason);
            m_transfer.ForgetJoining(member.GuestUser);
            _ = LogOutThenCutAsync(host, member);
        }

        async Task LogOutThenCutAsync(HostState host, Member member)
        {
            await m_transfer.LogOutGuestAsync(member.GuestUser);
            host.Gate?.CutLinks(member.Token);
        }

        async Task LetGuestsCollectAsync(HostState host)
        {
            List<Member> guests;
            lock (m_lock)
                guests = host.Members.Where(m => m.Token != null).ToList();
            if (guests.Count == 0 || host.Gate == null)
                return;
            foreach (Member guest in guests)
            {
                host.Gate.Retire(guest.Token, "ended");
                m_transfer.ForgetJoining(guest.GuestUser);
            }
            await Task.WhenAll(guests.Select(guest => LogOutThenCutAsync(host, guest)));
            await host.Gate.WaitDrainedAsync(guests.Select(guest => guest.Token), DrainCap);
        }

        bool DropSilentGuests(HostState host)
        {
            List<Member> silent;
            DateTime now = DateTime.UtcNow;
            lock (m_lock)
            {
                if (host.Gate == null)
                    return false;
                silent = host.Members.Where(m => m.Token != null &&
                    ((!m.Uploaded && now - m.AcceptedAt > AdmissionLimit) || (m.Uploaded && host.Gate.SinceSeen(m.Token) > GuestSilenceLimit))).ToList();
                host.Members.RemoveAll(silent.Contains);
            }
            foreach (Member member in silent)
                DismissGuest(host, member, "silent");
            return silent.Count > 0;
        }

        bool DropRemovedGuests(HostState host)
        {
            List<string> removed = m_transfer.TakeRemovedGuests();
            if (removed.Count == 0)
                return false;
            List<Member> gone;
            lock (m_lock)
            {
                gone = host.Members.Where(m => m.GuestUser != null && removed.Contains(m.GuestUser)).ToList();
                host.Members.RemoveAll(gone.Contains);
            }
            foreach (Member member in gone)
                DismissGuest(host, member, "removed");
            return gone.Count > 0;
        }

        string Removed()
        {
            foreach (KeyValuePair<string, JoinState> entry in m_joins.ToArray())
            {
                if (entry.Value.State != "joined" && entry.Value.State != "accepted")
                    continue;
                entry.Value.Removed = true;
                Leave(entry.Key);
            }
            return Line("state", "removed");
        }

        string Leave(string who)
        {
            if (!m_joins.TryGetValue(who, out JoinState join) || join.OwnGuid == null)
            {
                m_joins.TryRemove(who, out _);
                return Line("state", "home", "");
            }
            if (join.State != "returning" && join.State != "home")
            {
                join.State = "returning";
                SaveJoin(join);
                _ = ReturnCharacterAsync(join);
            }
            return JoinStatus(who);
        }

        public async Task LeaveAllAsync()
        {
            List<Task> returns = new List<Task>();
            foreach (KeyValuePair<string, JoinState> entry in m_joins.ToArray())
            {
                JoinState join = entry.Value;
                if (join.OwnGuid == null)
                {
                    CancelAsk(entry.Key);
                    continue;
                }
                if (join.State == "returning" || join.State == "home")
                    continue;
                join.State = "returning";
                SaveJoin(join);
                returns.Add(ReturnCharacterAsync(join));
            }
            await Task.WhenAll(returns);
            foreach (KeyValuePair<string, JoinState> entry in m_joins.ToArray())
                if (entry.Value.State == "home")
                    m_joins.TryRemove(entry.Key, out _);
        }

        public async Task EndAllAsync()
        {
            Task leaving = LeaveAllAsync();
            await CloseCurrentHost();
            await leaving;
        }

        Task CloseCurrentHost()
        {
            lock (m_lock)
            {
                if (m_host != null)
                    m_closing = CloseHostAsync(m_host);
                m_host = null;
                return m_closing;
            }
        }

        async Task ReturnCharacterAsync(JoinState join)
        {
            join.Sync?.Cancel();
            bool told = false;
            try
            {
                told = await TellHostLeavingAsync(join);
            }
            catch (Exception error)
            {
                Log("Co-op: couldn't tell the host about the leave: " + error.Message);
            }
            string ended = null;
            DateTime until = DateTime.UtcNow + (told ? FinalPullWait : TimeSpan.Zero);
            Interlocked.Exchange(ref join.Ending, 1);
            do
            {
                try
                {
                    ended = await CarryLedgerAsync(join);
                }
                catch (Exception error)
                {
                    Log("Co-op ledger: last carry failed: " + error.Message);
                    if (!told)
                        break;
                }
                if (ended != null || DateTime.UtcNow >= until)
                    break;
                await Task.Delay(LedgerInterval);
            }
            while (true);
            try
            {
                await ApplySpoolAsync(join);
            }
            catch (Exception error)
            {
                Log("Co-op ledger: rewards wait for your game's server: " + error.Message);
            }
            FinishHome(join, ReasonText(ended ?? "silent"));
        }

        async Task<string> ReceiveGuestAsync(HostState host, string token, CoopCharacter character)
        {
            Member member;
            lock (m_lock)
                member = host.Members.FirstOrDefault(m => m.Token == token);
            if (member == null)
                throw new InvalidOperationException("That join has ended.");
            try
            {
                string name = await m_transfer.ImportAsync(member.GuestUser, character, null);
                lock (m_lock)
                {
                    member.CharacterName = name;
                    member.Name = name;
                    member.Uploaded = true;
                }
                return name;
            }
            catch (Exception)
            {
                lock (m_lock)
                    host.Members.Remove(member);
                DismissGuest(host, member, "failed");
                _ = HeartbeatQuietlyAsync(host);
                throw;
            }
        }

        string StartHosting(Dictionary<string, string> form)
        {
            RequireLobby();
            HostState host = new HostState { Settings = form };
            host.Members.Add(new Member { Name = form.GetValueOrDefault("host_name", ""), Class = form.GetValueOrDefault("host_class", ""), Mastery = form.GetValueOrDefault("mastery", "0") });
            Task closing;
            lock (m_lock)
            {
                if (m_host != null)
                    m_closing = CloseHostAsync(m_host);
                closing = m_closing;
                m_host = host;
            }
            host.Opening = OpenHostAsync(host, closing);
            return HostStatus();
        }

        async Task OpenHostAsync(HostState host, Task closing)
        {
            try
            {
                await closing;
            }
            catch (Exception)
            {
            }
            try
            {
                await OpenHostStepsAsync(host);
            }
            catch (Exception error)
            {
                Fail(host, error.Message);
            }
        }

        async Task OpenHostStepsAsync(HostState host)
        {
            try
            {
                await RequireRegularAccountAsync(host.Settings, "Hosting");
            }
            catch (Exception error)
            {
                Fail(host, error.Message);
                return;
            }
            if (host.Stop.IsCancellationRequested)
                return;
            m_transfer.ClearGuestLedgers();
            m_transfer.TakeRemovedGuests();
            await m_transfer.RemoveAllGuestsAsync();
            m_transfer.ClearJoining();
            m_transfer.NoteSameClass(host.Settings.GetValueOrDefault("same_class", "0") == "1");
            m_transfer.NoteHostSettings(host.Settings.GetValueOrDefault("pause", "1") != "0", host.Settings.GetValueOrDefault("xp", "1") != "0");
            int port = Port("HOA_COOP_GATE_PORT", DefaultGatePort);
            try
            {
                host.Gate = new CoopGate
                {
                    Upload = (token, character) => ReceiveGuestAsync(host, token, character),
                    Ledger = m_transfer.ReadLedger,
                    Answers = m_transfer.AppendAnswers,
                    Leave = token => GuestLeftAsync(host, token),
                    IsOffline = user => !m_transfer.IsGuestOnline(user),
                };
                host.Gate.Start(port);
            }
            catch (SocketException)
            {
                Fail(host, $"Port {port} is already in use, so you can't host.");
                return;
            }
            if (Environment.GetEnvironmentVariable("HOA_COOP_SKIP_UPNP") != "1")
            {
                host.Ports = new CoopPorts();
                await host.Ports.OpenAsync(port);
            }
            host.Punch = await StartPunchAsync();
            if (host.Stop.IsCancellationRequested)
                return;
            try
            {
                await RegisterAsync(host);
                if (host.Stop.IsCancellationRequested)
                    return;
                host.State = "hosting";
                await HeartbeatAsync(host);
                _ = HostLoopAsync(host);
            }
            catch (LobbyRefusal refusal) when (refusal.Status == 409 && refusal.Message == "unreachable")
            {
                Fail(host, $"Other players can't reach you on TCP port {port}. Forward that port on your router to this PC and allow the launcher through Windows Firewall, then host again. If your internet provider shares your address, hosting won't work. You can still join other games.");
            }
            catch (Exception error)
            {
                Fail(host, error.Message);
            }
        }

        async Task RegisterAsync(HostState host)
        {
            Dictionary<string, string> s = host.Settings;
            int port = host.Gate.Port;
            JsonObject body = new JsonObject
            {
                ["port"] = port,
                ["address"] = s.GetValueOrDefault("address", "").Trim(),
                ["local"] = LocalAddress(),
                ["vpn"] = new JsonArray(VpnAddresses().Select(address => (JsonNode)address).ToArray()),
                ["punch"] = host.Punch?.PublicEndPoint?.ToString() ?? "",
                ["name"] = s.GetValueOrDefault("name", ""),
                ["host_name"] = s.GetValueOrDefault("host_name", ""),
                ["host_class"] = s.GetValueOrDefault("host_class", ""),
                ["password"] = s.GetValueOrDefault("password", ""),
                ["listed"] = s.GetValueOrDefault("listed", "1") == "1",
                ["difficulty"] = s.GetValueOrDefault("difficulty", "Normal"),
                ["max"] = int.TryParse(s.GetValueOrDefault("max"), out int max) ? max : 4,
                ["mastery_limit"] = int.TryParse(s.GetValueOrDefault("mastery_limit"), out int limit) ? limit : 0,
                ["same_class"] = s.GetValueOrDefault("same_class", "0") == "1",
                ["pause"] = s.GetValueOrDefault("pause", "1") != "0",
                ["xp"] = s.GetValueOrDefault("xp", "1") != "0",
                ["min_mythic"] = int.TryParse(s.GetValueOrDefault("min_mythic"), out int minMythic) ? minMythic : 0,
                ["version"] = Version,
                ["protocol"] = CoopProtocol,
            };
            if (host.Id != null)
            {
                body["resume_id"] = host.Id;
                body["resume_secret"] = host.Secret;
                body["resume_code"] = host.Code;
            }
            JsonNode answer = await LobbyAsync(HttpMethod.Post, "/host", body);
            host.Id = answer["id"]?.ToString();
            host.Secret = answer["secret"]?.ToString();
            host.Code = answer["code"]?.ToString() ?? "";
            host.Mode = answer["mode"]?.ToString() ?? "";
            if (host.Mode != "punch" && host.State != "hosting")
            {
                host.Punch?.Dispose();
                host.Punch = null;
            }
            host.Message = host.Mode switch
            {
                "lan" => $"Only players on your own network can join. To let others join, forward TCP port {port} on your router to this PC, or enter a public address when you host.",
                "vpn" => $"Only players on your VPN can join. To let others join, forward TCP port {port} on your router to this PC.",
                _ => "",
            };
        }

        void Fail(HostState host, string message)
        {
            Log("Co-op: hosting failed: " + message);
            host.State = "error";
            host.Message = message;
            host.Gate?.Dispose();
            host.Punch?.Dispose();
            _ = host.Ports?.CloseAsync();
        }

        async Task HostLoopAsync(HostState host)
        {
            DateTime lastBeat = DateTime.UtcNow;
            DateTime lastHeard = DateTime.UtcNow;
            while (!host.Stop.IsCancellationRequested && !m_stop.IsCancellationRequested)
            {
                try
                {
                    await Task.Delay(PollInterval, host.Stop.Token);
                }
                catch (TaskCanceledException)
                {
                    return;
                }
                bool changed = DropSilentGuests(host) | DropRemovedGuests(host);
                try
                {
                    JsonNode answer = await LobbyAsync(HttpMethod.Post, "/requests", new JsonObject { ["id"] = host.Id, ["secret"] = host.Secret });
                    lastHeard = DateTime.UtcNow;
                    host.Warning = "";
                    List<Request> requests = (answer["requests"]?.AsArray() ?? new JsonArray()).Select(r => new Request
                    {
                        Ask = r?["ask"]?.ToString(),
                        Name = r?["name"]?.ToString(),
                        Class = r?["class"]?.ToString(),
                        Race = r?["race"]?.ToString(),
                        Mastery = r?["mastery"]?.ToString(),
                        Best = r?["best"]?.ToString(),
                        Seconds = r?["seconds"]?.ToString(),
                        Punch = r?["punch"]?.ToString() ?? "",
                    }).Where(r => !host.Answered.Contains(r.Ask)).ToList();
                    lock (m_lock)
                        host.Requests = requests;
                    if (host.Settings.GetValueOrDefault("auto") == "1")
                        foreach (Request request in requests)
                            Answer(request.Ask, true);
                    if (changed || DateTime.UtcNow - lastBeat > HeartbeatInterval || SettingsText() != host.SentSettings)
                    {
                        await HeartbeatAsync(host);
                        lastBeat = DateTime.UtcNow;
                    }
                }
                catch (LobbyRefusal refusal) when (refusal.Status == 404)
                {
                    try
                    {
                        await RegisterAsync(host);
                        await HeartbeatAsync(host);
                        lastBeat = lastHeard = DateTime.UtcNow;
                        host.Warning = "";
                        Log("Co-op: the lobby forgot this game; listed it again");
                    }
                    catch (Exception error)
                    {
                        Log("Co-op: listing the game again failed: " + error.Message);
                    }
                }
                catch (Exception)
                {
                }
                if (DateTime.UtcNow - lastHeard > LobbyQuietLimit)
                    host.Warning = "Can't reach the co-op service. Players in your game keep playing, but new players can't find or join it until it's back.";
            }
        }

        string SettingsText() => string.Join("|", m_transfer.ReadHostSettings().OrderBy(pair => pair.Key).Select(pair => pair.Key + "=" + pair.Value));

        async Task HeartbeatQuietlyAsync(HostState host)
        {
            try
            {
                await HeartbeatAsync(host);
            }
            catch (Exception)
            {
            }
        }

        Task HeartbeatAsync(HostState host)
        {
            JsonArray members = new JsonArray();
            lock (m_lock)
                foreach (Member member in host.Members)
                    members.Add(new JsonObject { ["name"] = member.Name, ["class"] = member.Class, ["mastery"] = int.TryParse(member.Mastery, out int m) ? m : 0 });
            Dictionary<string, string> settings = m_transfer.ReadHostSettings();
            host.SentSettings = SettingsText();
            return LobbyAsync(HttpMethod.Post, "/heartbeat", new JsonObject
            {
                ["id"] = host.Id,
                ["secret"] = host.Secret,
                ["members"] = members,
                ["pause"] = settings.GetValueOrDefault("pause", "1") != "0",
                ["xp"] = settings.GetValueOrDefault("xp", "1") != "0",
                ["playing"] = settings.GetValueOrDefault("playing", ""),
                ["punch"] = host.Punch?.PublicEndPoint?.ToString() ?? "",
            });
        }

        string Answer(string ask, bool accept)
        {
            HostState host;
            Request request;
            lock (m_lock)
            {
                host = m_host;
                request = host?.Requests.FirstOrDefault(r => r.Ask == ask);
                if (host == null || host.State != "hosting" || request == null || !host.Answered.Add(ask))
                    throw new CoopError("Join request expired.");
                host.Requests.Remove(request);
            }
            _ = AnswerInBackgroundAsync(host, request, accept);
            return HostStatus();
        }

        async Task AnswerInBackgroundAsync(HostState host, Request request, bool accept)
        {
            try
            {
                await AnswerAsync(host, request, accept);
                host.Notice = "";
            }
            catch (Exception error)
            {
                host.Notice = error.Message;
                Log("Co-op: answering " + request.Name + " failed: " + error.Message);
            }
        }

        async Task AnswerAsync(HostState host, Request request, bool accept)
        {
            JsonObject body = new JsonObject { ["id"] = host.Id, ["secret"] = host.Secret, ["ask"] = request.Ask, ["accept"] = accept };
            Member member = null;
            if (accept)
            {
                CoopLogin login = await m_accounts.CreateAsync();
                string token = Convert.ToHexString(RandomNumberGenerator.GetBytes(16));
                host.Gate.Allow(token, login.User);
                body["token"] = token;
                body["user"] = login.User;
                body["password"] = login.Password;
                if (host.Punch != null && CoopPunch.TryParseEndPoint(request.Punch, out IPEndPoint guest))
                {
                    ulong session = CoopPunch.NewSession();
                    CoopLink link = host.Punch.Open(session, guest);
                    int gatePort = host.Gate.Port;
                    link.StreamOpened = id => CoopLinkStream.ToGate(link, id, gatePort);
                    body["session"] = session.ToString("X16");
                }
                member = new Member { Name = request.Name, Class = request.Class, Mastery = request.Mastery, Token = token, GuestUser = login.User };
                lock (m_lock)
                    host.Members.Add(member);
                m_transfer.NoteJoining(login.User, request.Name);
            }
            try
            {
                await LobbyAsync(HttpMethod.Post, "/answer", body);
            }
            catch (Exception) when (member != null)
            {
                lock (m_lock)
                    host.Members.Remove(member);
                DismissGuest(host, member, "failed");
                throw;
            }
            if (accept)
                await HeartbeatQuietlyAsync(host);
        }

        string HostStatus()
        {
            lock (m_lock)
            {
                if (m_host == null)
                    return Line("state", "off");
                StringBuilder text = new StringBuilder();
                string message = m_host.Warning.Length > 0 ? m_host.Warning : m_host.Notice.Length > 0 ? m_host.Notice : m_host.Message;
                text.Append(Line("state", m_host.State, CoopText.Localize(message)));
                text.Append(Line("game", m_host.Settings.GetValueOrDefault("name", ""), m_host.Code, m_host.Settings.GetValueOrDefault("max", "4"),
                    m_host.Settings.GetValueOrDefault("difficulty", "Normal")));
                foreach (Member member in m_host.Members)
                    text.Append(Line("member", member.Name, member.Class, member.Mastery));
                foreach (Request request in m_host.Requests)
                    text.Append(Line("request", request.Ask, request.Name, request.Class, request.Race, request.Mastery, request.Best, request.Seconds));
                return text.ToString();
            }
        }

        string StopHosting()
        {
            _ = CloseCurrentHost();
            return Line("state", "off");
        }

        async Task CloseHostAsync(HostState host)
        {
            host.Stop.Cancel();
            try
            {
                await host.Opening;
            }
            catch (Exception)
            {
            }
            m_transfer.NoteSameClass(false);
            m_transfer.ClearHostSettings();
            try
            {
                await LetGuestsCollectAsync(host);
            }
            catch (Exception error)
            {
                Log("Co-op: letting guests collect failed: " + error.Message);
            }
            host.Gate?.Dispose();
            host.Punch?.Dispose();
            try
            {
                if (host.Ports != null)
                    await host.Ports.CloseAsync();
            }
            catch (Exception)
            {
            }
            if (host.Id != null)
            {
                try
                {
                    await LobbyAsync(HttpMethod.Post, "/close", new JsonObject { ["id"] = host.Id, ["secret"] = host.Secret });
                }
                catch (Exception)
                {
                }
            }
        }
    }
}

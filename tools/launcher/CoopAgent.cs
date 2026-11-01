using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
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

        readonly GameFolder m_folder;
        readonly CoopAccounts m_accounts;
        readonly CoopTransfer m_transfer;
        static readonly TimeSpan LedgerInterval = TimeSpan.FromSeconds(1);
        readonly CancellationTokenSource m_stop = new CancellationTokenSource();
        readonly ConcurrentDictionary<string, JoinState> m_joins = new ConcurrentDictionary<string, JoinState>();
        readonly object m_lock = new object();
        TcpListener m_listener;
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
        }

        sealed class HostState
        {
            public string State = "starting";
            public string Message = "";
            public string Id;
            public string Secret;
            public string Code = "";
            public string SentSettings = "";
            public Dictionary<string, string> Settings;
            public CoopGate Gate;
            public CoopPorts Ports;
            public List<Member> Members = new List<Member>();
            public List<Request> Requests = new List<Request>();
            public HashSet<string> Answered = new HashSet<string>();
            public CancellationTokenSource Stop = new CancellationTokenSource();
        }

        sealed class JoinState
        {
            public string State = "asking";
            public string Message = "";
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
        }

        public CoopAgent(GameFolder folder)
        {
            m_folder = folder;
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
            _ = AcceptLoopAsync();
        }

        public void Dispose()
        {
            m_stop.Cancel();
            m_listener?.Stop();
            StopHostingAsync().Wait(TimeSpan.FromSeconds(5));
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
                    answer = error.Message;
                }
                catch (Exception error)
                {
                    status = 500;
                    answer = error.Message;
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
                ("POST", "/join/cancel") => CancelAskAsync(who),
                ("POST", "/join/done") => Task.FromResult(MarkJoined(who)),
                ("POST", "/join/leave") => Task.FromResult(Leave(who)),
                ("POST", "/join/removed") => Task.FromResult(Removed()),
                ("POST", "/join/rejoin") => Task.FromResult(Rejoin(who)),
                ("POST", "/join/entered") => Task.FromResult(Entered(who)),
                ("POST", "/host") => StartHostingAsync(form),
                ("GET", "/host") => Task.FromResult(HostStatus()),
                ("POST", "/host/answer") => AnswerAsync(form.GetValueOrDefault("ask", ""), form.GetValueOrDefault("accept") == "1"),
                ("POST", "/host/stop") => StopHostingAsync(),
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
                response = await Web.Client.SendAsync(request, timeout.Token);
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
                        lobby["players"], lobby["max"], lobby["locked"], lobby["mastery_limit"], lobby["members"], lobby["same_class"], lobby["min_mythic"], lobby["pause"], lobby["xp"], lobby["playing"]));
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

        async Task<string> AskAsync(string who, Dictionary<string, string> form)
        {
            await RequireRegularAccountAsync(form, "Joining a co-op game");
            JoinState join = new JoinState { OwnAccount = form.GetValueOrDefault("account", ""), OwnName = form.GetValueOrDefault("name", "") };
            m_joins[who] = join;
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
            };
            try
            {
                JsonNode answer = await LobbyAsync(HttpMethod.Post, "/ask", body);
                join.Ask = answer["ask"]?.ToString();
                join.Seconds = answer["seconds"]?.ToString() ?? "30";
                join.Lobby = answer["lobby"]?["name"]?.ToString() ?? "";
                join.State = "waiting";
                _ = PollAskAsync(join);
            }
            catch (Exception error)
            {
                join.State = "error";
                join.Message = error.Message;
            }
            return JoinStatus(who);
        }

        async Task PollAskAsync(JoinState join)
        {
            while (join.State == "waiting" && !m_stop.IsCancellationRequested)
            {
                await Task.Delay(TimeSpan.FromSeconds(1.5));
                try
                {
                    JsonNode answer = await LobbyAsync(HttpMethod.Post, "/ask/state", new JsonObject { ["ask"] = join.Ask });
                    string state = answer["state"]?.ToString() ?? "gone";
                    if (state == "accepted")
                    {
                        JsonNode details = answer["join"];
                        string address = details?["address"]?.ToString() ?? "";
                        if (address.Contains(':'))
                            address = "[" + address + "]";
                        join.Address = address + ":" + details?["port"];
                        join.Token = details?["token"]?.ToString() ?? "";
                        join.User = details?["user"]?.ToString() ?? "";
                        join.Password = details?["password"]?.ToString() ?? "";
                        join.State = "transferring";
                        await BringCharacterAsync(join);
                    }
                    else if (state != "waiting")
                    {
                        join.State = state == "declined" ? "declined" : "ended";
                        join.Message = state switch
                        {
                            "declined" => answer["reason"]?.ToString() ?? "",
                            "expired" => "The host didn't respond.",
                            "gone" => "The host closed the lobby.",
                            _ => "",
                        };
                    }
                }
                catch (LobbyRefusal refusal) when (refusal.Status == 404)
                {
                    join.State = "ended";
                    join.Message = "The host closed the lobby.";
                }
                catch (Exception)
                {
                }
            }
        }

        string JoinStatus(string who)
        {
            if (!m_joins.TryGetValue(who, out JoinState join))
                return Line("state", "none");
            return join.State switch
            {
                "accepted" => Line("state", "accepted", join.Address, join.Token, join.User, join.Password, join.OwnName),
                "waiting" => Line("state", "waiting", join.Lobby, join.Seconds),
                "transferring" => Line("state", "transferring", join.Lobby),
                "returning" => Line("state", "returning"),
                "joined" => Line("state", "joined", join.Address, join.Token, join.User, join.Password, join.EnterOnLogin ? "1" : "0", join.OwnName),
                _ => Line("state", join.State, join.Message),
            };
        }

        async Task<string> CancelAskAsync(string who)
        {
            if (m_joins.TryRemove(who, out JoinState join) && join.Ask != null && join.State == "waiting")
            {
                join.State = "cancelled";
                try
                {
                    await LobbyAsync(HttpMethod.Post, "/ask/cancel", new JsonObject { ["ask"] = join.Ask });
                }
                catch (Exception)
                {
                }
            }
            return Line("state", "none");
        }

        string Rejoin(string who)
        {
            if (!m_joins.TryGetValue(who, out JoinState join) || (join.State != "joined" && join.State != "accepted"))
                return Line("state", "none");
            join.EnterOnLogin = true;
            join.RejoinTries++;
            return Line("state", "rejoin", join.RejoinTries.ToString());
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
                join.State = "joined";
            return JoinStatus(who);
        }

        async Task BringCharacterAsync(JoinState join)
        {
            try
            {
                (string guid, CoopCharacter original) = await m_transfer.ExportAsync(join.OwnName);
                join.OwnGuid = guid;
                using TcpClient client = await DialHostAsync(join, "UPLOAD");
                NetworkStream stream = client.GetStream();
                using CancellationTokenSource timeout = new CancellationTokenSource(CoopWire.TransferTimeout);
                await CoopWire.WriteBlobAsync(stream, Encoding.UTF8.GetBytes(original.Name), timeout.Token);
                await CoopWire.WriteBlobAsync(stream, original.Dump, timeout.Token);
                await CoopWire.WriteBlobAsync(stream, original.Account, timeout.Token);
                string answer = await CoopGate.ReadLineAsync(stream) ?? "";
                if (!answer.StartsWith("HOA1 DONE"))
                    throw new InvalidOperationException(answer.StartsWith("HOA1 FAIL ") ? answer.Substring(10) : "The host couldn't take your character.");
                join.State = "accepted";
                join.Sync = new CancellationTokenSource();
                _ = LedgerLoopAsync(join, join.Sync.Token);
            }
            catch (Exception error)
            {
                join.State = "error";
                join.Message = error.Message;
            }
        }

        static async Task<TcpClient> DialHostAsync(JoinState join, string leg)
        {
            int split = join.Address.LastIndexOf(':');
            string host = join.Address.Substring(0, split).Trim('[', ']');
            int port = int.Parse(join.Address.Substring(split + 1));
            TcpClient client = new TcpClient(host.Contains(':') ? AddressFamily.InterNetworkV6 : AddressFamily.InterNetwork);
            using CancellationTokenSource timeout = new CancellationTokenSource(TimeSpan.FromSeconds(10));
            await client.ConnectAsync(host, port, timeout.Token);
            NetworkStream stream = client.GetStream();
            await stream.WriteAsync(Encoding.ASCII.GetBytes($"HOA1 {join.Token} {leg}\n"), timeout.Token);
            return client;
        }

        async Task LedgerLoopAsync(JoinState join, CancellationToken cancel)
        {
            while (!cancel.IsCancellationRequested)
            {
                try
                {
                    await Task.Delay(LedgerInterval, cancel);
                    m_transfer.MarkAway(join.OwnAccount);
                    await CarryLedgerAsync(join);
                    join.LedgerProblem = null;
                }
                catch (OperationCanceledException) when (cancel.IsCancellationRequested)
                {
                    return;
                }
                catch (Exception error)
                {
                    if (error.Message != join.LedgerProblem)
                        Console.Error.WriteLine("Co-op ledger: " + error.Message);
                    join.LedgerProblem = error.Message;
                }
            }
        }

        static string LedgerGame(JoinState join) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(join.Token))).Substring(0, 32);

        async Task CarryLedgerAsync(JoinState join)
        {
            string entries;
            using (TcpClient client = await DialHostAsync(join, "LEDGER"))
            {
                NetworkStream stream = client.GetStream();
                await stream.WriteAsync(Encoding.ASCII.GetBytes(join.LedgerSeq + "\n"));
                string answer = await CoopGate.ReadLineAsync(stream) ?? "";
                if (answer != "HOA1 DATA")
                    throw new InvalidOperationException("the host's gate answered \"" + answer + "\"");
                using CancellationTokenSource timeout = new CancellationTokenSource(CoopWire.TransferTimeout);
                entries = Encoding.UTF8.GetString(await CoopWire.ReadBlobAsync(stream, timeout.Token));
            }
            if (entries.Length == 0)
                return;
            string answers = await m_transfer.ApplyLedgerAsync(join.OwnAccount, LedgerGame(join), join.OwnName, entries);
            using (TcpClient client = await DialHostAsync(join, "ANSWERS"))
            {
                NetworkStream stream = client.GetStream();
                using CancellationTokenSource timeout = new CancellationTokenSource(CoopWire.TransferTimeout);
                await CoopWire.WriteBlobAsync(stream, Encoding.UTF8.GetBytes(answers), timeout.Token);
                await CoopGate.ReadLineAsync(stream);
            }
            foreach (string line in answers.Split('\n'))
            {
                string[] fields = line.Split('\t');
                if (fields.Length < 2 || !long.TryParse(fields[0], out long seq))
                    continue;
                if (fields[1] == "retry")
                    break;
                join.LedgerSeq = Math.Max(join.LedgerSeq, seq);
            }
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
                join.Sync?.Cancel();
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
                    m_joins.TryRemove(entry.Key, out _);
                    continue;
                }
                if (join.State == "returning" || join.State == "home")
                    continue;
                join.State = "returning";
                join.Sync?.Cancel();
                returns.Add(ReturnCharacterAsync(join));
            }
            await Task.WhenAll(returns);
            foreach (KeyValuePair<string, JoinState> entry in m_joins.ToArray())
                if (entry.Value.State == "home")
                    m_joins.TryRemove(entry.Key, out _);
        }

        async Task ReturnCharacterAsync(JoinState join)
        {
            string note = "";
            try
            {
                await CarryLedgerAsync(join);
            }
            catch (Exception error)
            {
                Console.Error.WriteLine("Co-op ledger: last carry failed: " + error.Message);
                note = "Lost connection to the host. Your progress up to the last few seconds is saved.";
            }
            m_transfer.ClearAway(join.OwnAccount);
            join.Message = join.Removed ? "You were removed from the party." : note;
            join.State = "home";
        }

        async Task<string> ReceiveGuestAsync(HostState host, string token, CoopCharacter character)
        {
            Member member;
            lock (m_lock)
                member = host.Members.FirstOrDefault(m => m.Token == token);
            if (member == null)
                throw new InvalidOperationException("That join has ended.");
            string name = await m_transfer.ImportAsync(member.GuestUser, character, null);
            lock (m_lock)
            {
                member.CharacterName = name;
                member.Name = name;
            }
            return name;
        }

        async Task<string> StartHostingAsync(Dictionary<string, string> form)
        {
            await RequireRegularAccountAsync(form, "Hosting");
            await StopHostingAsync();
            RequireLobby();
            HostState host = new HostState { Settings = form };
            host.Members.Add(new Member { Name = form.GetValueOrDefault("host_name", ""), Class = form.GetValueOrDefault("host_class", ""), Mastery = form.GetValueOrDefault("mastery", "0") });
            lock (m_lock)
                m_host = host;
            m_transfer.NoteSameClass(form.GetValueOrDefault("same_class", "0") == "1");
            m_transfer.NoteHostSettings(form.GetValueOrDefault("pause", "1") != "0", form.GetValueOrDefault("xp", "1") != "0");
            _ = OpenHostAsync(host);
            return HostStatus();
        }

        async Task OpenHostAsync(HostState host)
        {
            int port = Port("HOA_COOP_GATE_PORT", DefaultGatePort);
            try
            {
                host.Gate = new CoopGate { Upload = (token, character) => ReceiveGuestAsync(host, token, character), Ledger = m_transfer.ReadLedger, Answers = m_transfer.AppendAnswers };
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
            try
            {
                Dictionary<string, string> s = host.Settings;
                JsonNode answer = await LobbyAsync(HttpMethod.Post, "/host", new JsonObject
                {
                    ["port"] = port,
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
                });
                host.Id = answer["id"]?.ToString();
                host.Secret = answer["secret"]?.ToString();
                host.Code = answer["code"]?.ToString() ?? "";
                host.State = "hosting";
                await HeartbeatAsync(host);
                _ = HostLoopAsync(host);
            }
            catch (LobbyRefusal refusal) when (refusal.Status == 409 && refusal.Message == "unreachable")
            {
                Fail(host, "Other players can't connect to you: your router blocks automatic port forwarding, or your internet provider shares your address. You can still join other games.");
            }
            catch (Exception error)
            {
                Fail(host, error.Message);
            }
        }

        void Fail(HostState host, string message)
        {
            host.State = "error";
            host.Message = message;
            host.Gate?.Dispose();
            _ = host.Ports?.CloseAsync();
        }

        async Task HostLoopAsync(HostState host)
        {
            DateTime lastBeat = DateTime.UtcNow;
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
                try
                {
                    JsonNode answer = await LobbyAsync(HttpMethod.Post, "/requests", new JsonObject { ["id"] = host.Id, ["secret"] = host.Secret });
                    List<Request> requests = (answer["requests"]?.AsArray() ?? new JsonArray()).Select(r => new Request
                    {
                        Ask = r?["ask"]?.ToString(),
                        Name = r?["name"]?.ToString(),
                        Class = r?["class"]?.ToString(),
                        Race = r?["race"]?.ToString(),
                        Mastery = r?["mastery"]?.ToString(),
                        Best = r?["best"]?.ToString(),
                        Seconds = r?["seconds"]?.ToString(),
                    }).Where(r => !host.Answered.Contains(r.Ask)).ToList();
                    lock (m_lock)
                        host.Requests = requests;
                    if (host.Settings.GetValueOrDefault("auto") == "1")
                        foreach (Request request in requests)
                            await AnswerAsync(request.Ask, true);
                    if (DateTime.UtcNow - lastBeat > HeartbeatInterval || SettingsText() != host.SentSettings)
                    {
                        await HeartbeatAsync(host);
                        lastBeat = DateTime.UtcNow;
                    }
                }
                catch (LobbyRefusal refusal) when (refusal.Status == 404)
                {
                    Fail(host, "Your lobby expired. Host again to list it.");
                    return;
                }
                catch (Exception)
                {
                }
            }
        }

        string SettingsText() => string.Join("|", m_transfer.ReadHostSettings().OrderBy(pair => pair.Key).Select(pair => pair.Key + "=" + pair.Value));

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
            });
        }

        async Task<string> AnswerAsync(string ask, bool accept)
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
            JsonObject body = new JsonObject { ["id"] = host.Id, ["secret"] = host.Secret, ["ask"] = ask, ["accept"] = accept };
            if (accept)
            {
                CoopLogin login = await m_accounts.CreateAsync();
                string token = Convert.ToHexString(RandomNumberGenerator.GetBytes(16));
                host.Gate.Allow(token, login.User);
                body["token"] = token;
                body["user"] = login.User;
                body["password"] = login.Password;
                lock (m_lock)
                    host.Members.Add(new Member { Name = request.Name, Class = request.Class, Mastery = request.Mastery, Token = token, GuestUser = login.User });
                m_transfer.NoteJoining(login.User, request.Name);
            }
            await LobbyAsync(HttpMethod.Post, "/answer", body);
            if (accept)
                _ = HeartbeatAsync(host);
            return HostStatus();
        }

        string HostStatus()
        {
            lock (m_lock)
            {
                if (m_host == null)
                    return Line("state", "off");
                StringBuilder text = new StringBuilder();
                text.Append(Line("state", m_host.State, m_host.Message));
                text.Append(Line("game", m_host.Settings.GetValueOrDefault("name", ""), m_host.Code, m_host.Settings.GetValueOrDefault("max", "4"),
                    m_host.Settings.GetValueOrDefault("difficulty", "Normal")));
                foreach (Member member in m_host.Members)
                    text.Append(Line("member", member.Name, member.Class, member.Mastery));
                foreach (Request request in m_host.Requests)
                    text.Append(Line("request", request.Ask, request.Name, request.Class, request.Race, request.Mastery, request.Best, request.Seconds));
                return text.ToString();
            }
        }

        async Task<string> StopHostingAsync()
        {
            HostState host;
            lock (m_lock)
            {
                host = m_host;
                m_host = null;
            }
            if (host == null)
                return Line("state", "off");
            m_transfer.NoteSameClass(false);
            m_transfer.ClearHostSettings();
            host.Stop.Cancel();
            host.Gate?.Dispose();
            if (host.Ports != null)
                await host.Ports.CloseAsync();
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
            return Line("state", "off");
        }
    }
}

using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace HordesOfAzeroth.Launcher
{
    sealed class CoopGate : IDisposable
    {
        const int LoginPort = 3724;
        const int WorldPort = 8085;
        const int LineLimit = 128;
        const int MaxFailures = 10;
        static readonly TimeSpan LineTimeout = TimeSpan.FromSeconds(5);
        static readonly TimeSpan BlockTime = TimeSpan.FromMinutes(1);
        public static readonly TimeSpan CollectWindow = TimeSpan.FromMinutes(5);
        static readonly TimeSpan DrainPoll = TimeSpan.FromMilliseconds(250);
        static readonly TimeSpan DrainWait = TimeSpan.FromSeconds(1);

        sealed class Pass
        {
            public string User;
            public DateTime Seen = DateTime.UtcNow;
            public DateTime RetiredAt;
            public string Reason;
            public bool Drained;
            public CancellationTokenSource Links = new CancellationTokenSource();
            public bool Retired => Reason != null;
        }

        readonly ConcurrentDictionary<string, Pass> m_passes = new ConcurrentDictionary<string, Pass>();
        readonly ConcurrentDictionary<IPAddress, (int Count, DateTime Since)> m_failures = new ConcurrentDictionary<IPAddress, (int, DateTime)>();
        readonly CancellationTokenSource m_stop = new CancellationTokenSource();
        TcpListener m_listener;

        public int Port { get; private set; }

        public Func<string, CoopCharacter, Task<string>> Upload { get; set; }

        public Func<string, long, string> Ledger { get; set; }

        public Action<string, string> Answers { get; set; }

        public Func<string, Task> Leave { get; set; }

        public Func<string, bool> IsOffline { get; set; }

        public void Start(int port)
        {
            m_listener = new TcpListener(IPAddress.IPv6Any, port);
            m_listener.Server.DualMode = true;
            m_listener.Start();
            Port = port;
            _ = AcceptLoopAsync();
        }

        public void Allow(string token, string user)
        {
            m_passes[token] = new Pass { User = user };
        }

        public void Retire(string token, string reason)
        {
            if (!m_passes.TryGetValue(token, out Pass pass) || pass.Retired)
                return;
            pass.RetiredAt = DateTime.UtcNow;
            pass.Reason = reason;
        }

        public void CutLinks(string token)
        {
            if (m_passes.TryGetValue(token, out Pass pass) && pass.Retired)
                pass.Links.Cancel();
        }

        public TimeSpan SinceSeen(string token) => m_passes.TryGetValue(token, out Pass pass) && !pass.Retired ? DateTime.UtcNow - pass.Seen : TimeSpan.MaxValue;

        public async Task WaitDrainedAsync(IEnumerable<string> tokens, TimeSpan cap)
        {
            List<string> waiting = tokens.ToList();
            DateTime until = DateTime.UtcNow + cap;
            while (DateTime.UtcNow < until && waiting.Any(token => m_passes.TryGetValue(token, out Pass pass) && !pass.Drained))
                await Task.Delay(DrainPoll);
        }

        public void Dispose()
        {
            m_stop.Cancel();
            m_listener?.Stop();
            foreach (Pass pass in m_passes.Values)
                pass.Links.Cancel();
        }

        Pass Find(string token)
        {
            if (!m_passes.TryGetValue(token, out Pass pass))
                return null;
            if (pass.Retired && DateTime.UtcNow - pass.RetiredAt > CollectWindow)
            {
                m_passes.TryRemove(token, out _);
                return null;
            }
            return pass;
        }

        static bool LooksLikeToken(string text) => text.Length == 32 && text.All(Uri.IsHexDigit);

        async Task AcceptLoopAsync()
        {
            while (!m_stop.IsCancellationRequested)
            {
                TcpClient client;
                try
                {
                    client = await m_listener.AcceptTcpClientAsync(m_stop.Token);
                }
                catch (Exception) when (m_stop.IsCancellationRequested)
                {
                    return;
                }
                catch (SocketException)
                {
                    continue;
                }
                _ = HandleAsync(client);
            }
        }

        async Task HandleAsync(TcpClient client)
        {
            using (client)
            {
                IPAddress from = ((IPEndPoint)client.Client.RemoteEndPoint).Address;
                if (IsBlocked(from))
                    return;
                NetworkStream stream = client.GetStream();
                string line = await ReadGateLineAsync(stream);
                if (line == "HOA1 PING")
                {
                    await WriteAsync(stream, "HOA1 PONG\n");
                    return;
                }
                string[] parts = line?.Split(' ') ?? Array.Empty<string>();
                bool wellFormed = parts.Length == 3 && parts[0] == "HOA1" && LooksLikeToken(parts[1]);
                Pass pass = wellFormed ? Find(parts[1]) : null;
                if (pass == null)
                {
                    if (!wellFormed)
                        NoteFailure(from);
                    await WriteAsync(stream, "HOA1 NO\n");
                    await CloseGentlyAsync(client);
                    return;
                }
                string leg = parts[2];
                if (!pass.Retired)
                    pass.Seen = DateTime.UtcNow;
                if (leg == "UPLOAD" && !pass.Retired)
                {
                    await ServeUploadAsync(stream, parts[1]);
                    return;
                }
                if (leg == "LEAVE")
                {
                    await ServeLeaveAsync(stream, parts[1]);
                    return;
                }
                if (leg == "LEDGER")
                {
                    await ServeLedgerAsync(stream, pass);
                    return;
                }
                if (leg == "ANSWERS")
                {
                    await ServeAnswersAsync(stream, pass.User);
                    return;
                }
                int target = pass.Retired ? 0 : leg switch { "LOGIN" => LoginPort, "WORLD" => WorldPort, _ => 0 };
                if (target == 0)
                {
                    await WriteAsync(stream, "HOA1 NO\n");
                    return;
                }
                using TcpClient server = new TcpClient();
                try
                {
                    await server.ConnectAsync(IPAddress.Loopback, target);
                }
                catch (SocketException)
                {
                    await WriteAsync(stream, "HOA1 DOWN\n");
                    return;
                }
                await WriteAsync(stream, "HOA1 OK\n");
                NetworkStream inner = server.GetStream();
                using CancellationTokenSource done = CancellationTokenSource.CreateLinkedTokenSource(m_stop.Token, pass.Links.Token);
                Task up = PumpAsync(stream, inner, done.Token);
                Task down = PumpAsync(inner, stream, done.Token);
                await Task.WhenAny(up, down);
                done.Cancel();
            }
        }

        async Task ServeUploadAsync(NetworkStream stream, string token)
        {
            try
            {
                using CancellationTokenSource timeout = new CancellationTokenSource(CoopWire.TransferTimeout);
                CoopCharacter character = new CoopCharacter
                {
                    Name = Encoding.UTF8.GetString(await CoopWire.ReadBlobAsync(stream, timeout.Token)),
                    Dump = await CoopWire.ReadBlobAsync(stream, timeout.Token),
                    Account = await CoopWire.ReadBlobAsync(stream, timeout.Token),
                };
                string name = await Upload(token, character);
                await WriteAsync(stream, $"HOA1 DONE {name}\n");
            }
            catch (Exception error)
            {
                await WriteAsync(stream, $"HOA1 FAIL {error.Message.Replace('\n', ' ')}\n");
            }
        }

        async Task ServeLedgerAsync(NetworkStream stream, Pass pass)
        {
            try
            {
                long since = long.TryParse(await ReadGateLineAsync(stream), out long value) ? value : 0;
                bool finished = pass.Retired && (IsOffline?.Invoke(pass.User) ?? true);
                string lines = Ledger(pass.User, since);
                if (lines.Length == 0 && finished)
                {
                    pass.Drained = true;
                    await WriteAsync(stream, $"HOA1 END {pass.Reason}\n");
                    return;
                }
                await WriteAsync(stream, "HOA1 DATA\n");
                using CancellationTokenSource timeout = new CancellationTokenSource(CoopWire.TransferTimeout);
                await CoopWire.WriteBlobAsync(stream, Encoding.UTF8.GetBytes(lines), timeout.Token);
            }
            catch (Exception error)
            {
                await WriteAsync(stream, $"HOA1 FAIL {error.Message.Replace('\n', ' ')}\n");
            }
        }

        async Task ServeLeaveAsync(NetworkStream stream, string token)
        {
            try
            {
                await Leave(token);
                await WriteAsync(stream, "HOA1 DONE\n");
            }
            catch (Exception error)
            {
                await WriteAsync(stream, $"HOA1 FAIL {error.Message.Replace('\n', ' ')}\n");
            }
        }

        async Task ServeAnswersAsync(NetworkStream stream, string user)
        {
            try
            {
                using CancellationTokenSource timeout = new CancellationTokenSource(CoopWire.TransferTimeout);
                Answers(user, Encoding.UTF8.GetString(await CoopWire.ReadBlobAsync(stream, timeout.Token)));
                await WriteAsync(stream, "HOA1 DONE\n");
            }
            catch (Exception error)
            {
                await WriteAsync(stream, $"HOA1 FAIL {error.Message.Replace('\n', ' ')}\n");
            }
        }

        public static async Task<string> ReadLineAsync(NetworkStream stream) => await ReadGateLineAsync(stream);

        public static async Task<string> ReadLineAsync(NetworkStream stream, TimeSpan wait) => await ReadGateLineAsync(stream, wait);

        static async Task PumpAsync(NetworkStream from, NetworkStream to, CancellationToken cancel)
        {
            byte[] buffer = new byte[16384];
            try
            {
                while (true)
                {
                    int read = await from.ReadAsync(buffer, cancel);
                    if (read == 0)
                        return;
                    await to.WriteAsync(buffer.AsMemory(0, read), cancel);
                }
            }
            catch (Exception)
            {
            }
        }

        static async Task<string> ReadGateLineAsync(NetworkStream stream, TimeSpan? wait = null)
        {
            using CancellationTokenSource timeout = new CancellationTokenSource(wait ?? LineTimeout);
            StringBuilder line = new StringBuilder();
            byte[] one = new byte[1];
            try
            {
                while (line.Length < LineLimit)
                {
                    int read = await stream.ReadAsync(one, timeout.Token);
                    if (read == 0 || one[0] == (byte)'\n')
                        return line.ToString().TrimEnd('\r');
                    line.Append((char)one[0]);
                }
            }
            catch (Exception)
            {
            }
            return null;
        }

        static async Task CloseGentlyAsync(TcpClient client)
        {
            try
            {
                client.Client.Shutdown(SocketShutdown.Send);
                using CancellationTokenSource drain = new CancellationTokenSource(DrainWait);
                byte[] rest = new byte[256];
                while (await client.GetStream().ReadAsync(rest, drain.Token) > 0)
                {
                }
            }
            catch (Exception)
            {
            }
        }

        static async Task WriteAsync(NetworkStream stream, string text)
        {
            try
            {
                await stream.WriteAsync(Encoding.ASCII.GetBytes(text));
            }
            catch (Exception)
            {
            }
        }

        static bool IsTunnel(IPAddress from) => IPAddress.IsLoopback(from.IsIPv4MappedToIPv6 ? from.MapToIPv4() : from);

        bool IsBlocked(IPAddress from) =>
            !IsTunnel(from) && m_failures.TryGetValue(from, out var failures) && failures.Count >= MaxFailures && DateTime.UtcNow - failures.Since < BlockTime;

        void NoteFailure(IPAddress from)
        {
            if (IsTunnel(from))
                return;
            foreach (KeyValuePair<IPAddress, (int Count, DateTime Since)> old in m_failures.Where(entry => DateTime.UtcNow - entry.Value.Since > BlockTime).ToList())
                m_failures.TryRemove(old.Key, out _);
            m_failures.AddOrUpdate(from, _ => (1, DateTime.UtcNow),
                (_, old) => DateTime.UtcNow - old.Since > BlockTime ? (1, DateTime.UtcNow) : (old.Count + 1, old.Since));
        }
    }

    static class CoopWire
    {
        public const int BlobLimit = 8 * 1024 * 1024;
        public static readonly TimeSpan TransferTimeout = TimeSpan.FromSeconds(60);

        public static async Task WriteBlobAsync(NetworkStream stream, byte[] data, CancellationToken cancel)
        {
            await stream.WriteAsync(BitConverter.GetBytes(data.Length), cancel);
            await stream.WriteAsync(data, cancel);
        }

        public static async Task<byte[]> ReadBlobAsync(NetworkStream stream, CancellationToken cancel)
        {
            byte[] size = await ReadExactlyAsync(stream, 4, cancel);
            int length = BitConverter.ToInt32(size, 0);
            if (length < 0 || length > BlobLimit)
                throw new InvalidOperationException("The transfer was too large.");
            return await ReadExactlyAsync(stream, length, cancel);
        }

        static async Task<byte[]> ReadExactlyAsync(NetworkStream stream, int count, CancellationToken cancel)
        {
            byte[] buffer = new byte[count];
            int read = 0;
            while (read < count)
            {
                int got = await stream.ReadAsync(buffer.AsMemory(read, count - read), cancel);
                if (got == 0)
                    throw new InvalidOperationException("The connection closed during the transfer.");
                read += got;
            }
            return buffer;
        }
    }
}

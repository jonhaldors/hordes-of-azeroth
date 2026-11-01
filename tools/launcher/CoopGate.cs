using System;
using System.Collections.Concurrent;
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

        readonly ConcurrentDictionary<string, string> m_tokens = new ConcurrentDictionary<string, string>();
        readonly ConcurrentDictionary<IPAddress, (int Count, DateTime Since)> m_failures = new ConcurrentDictionary<IPAddress, (int, DateTime)>();
        readonly CancellationTokenSource m_stop = new CancellationTokenSource();
        TcpListener m_listener;

        public int Port { get; private set; }

        public Func<string, CoopCharacter, Task<string>> Upload { get; set; }

        public Func<string, long, string> Ledger { get; set; }

        public Action<string, string> Answers { get; set; }

        public void Start(int port)
        {
            m_listener = new TcpListener(IPAddress.IPv6Any, port);
            m_listener.Server.DualMode = true;
            m_listener.Start();
            Port = port;
            _ = AcceptLoopAsync();
        }

        public void Allow(string token, string user) => m_tokens[token] = user;

        public void Revoke(string token) => m_tokens.TryRemove(token, out _);

        public void Dispose()
        {
            m_stop.Cancel();
            m_listener?.Stop();
        }

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
                bool known = parts.Length == 3 && parts[0] == "HOA1" && m_tokens.ContainsKey(parts[1]);
                if (known && parts[2] == "UPLOAD")
                {
                    await ServeUploadAsync(stream, parts[1]);
                    return;
                }
                if (known && parts[2] == "LEDGER")
                {
                    await ServeLedgerAsync(stream, m_tokens[parts[1]]);
                    return;
                }
                if (known && parts[2] == "ANSWERS")
                {
                    await ServeAnswersAsync(stream, m_tokens[parts[1]]);
                    return;
                }
                int target = known ? parts[2] switch { "LOGIN" => LoginPort, "WORLD" => WorldPort, _ => 0 } : 0;
                if (target == 0)
                {
                    NoteFailure(from);
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
                using CancellationTokenSource done = CancellationTokenSource.CreateLinkedTokenSource(m_stop.Token);
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

        async Task ServeLedgerAsync(NetworkStream stream, string user)
        {
            try
            {
                long since = long.TryParse(await ReadGateLineAsync(stream), out long value) ? value : 0;
                await WriteAsync(stream, "HOA1 DATA\n");
                using CancellationTokenSource timeout = new CancellationTokenSource(CoopWire.TransferTimeout);
                await CoopWire.WriteBlobAsync(stream, Encoding.UTF8.GetBytes(Ledger(user, since)), timeout.Token);
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

        static async Task<string> ReadGateLineAsync(NetworkStream stream)
        {
            using CancellationTokenSource timeout = new CancellationTokenSource(LineTimeout);
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

        bool IsBlocked(IPAddress from) =>
            m_failures.TryGetValue(from, out var failures) && failures.Count >= MaxFailures && DateTime.UtcNow - failures.Since < BlockTime;

        void NoteFailure(IPAddress from) =>
            m_failures.AddOrUpdate(from, _ => (1, DateTime.UtcNow),
                (_, old) => DateTime.UtcNow - old.Since > BlockTime ? (1, DateTime.UtcNow) : (old.Count + 1, old.Since));
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

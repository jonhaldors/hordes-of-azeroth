using System;
using System.Buffers.Binary;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Threading.Channels;
using System.Threading.Tasks;

namespace HordesOfAzeroth.Launcher
{
    sealed class CoopPunch : IDisposable
    {
        const int DiscoverTries = 6;
        static readonly TimeSpan DiscoverWait = TimeSpan.FromMilliseconds(500);
        static readonly TimeSpan ReflectorKeepAlive = TimeSpan.FromSeconds(15);

        readonly Socket m_udp = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, ProtocolType.Udp);
        readonly IPEndPoint m_reflector;
        readonly ConcurrentDictionary<ulong, CoopLink> m_links = new ConcurrentDictionary<ulong, CoopLink>();
        readonly CancellationTokenSource m_stop = new CancellationTokenSource();
        TaskCompletionSource<IPEndPoint> m_discovery;
        string m_nonce = "";

        public IPEndPoint PublicEndPoint { get; private set; }

        CoopPunch(IPEndPoint reflector)
        {
            m_reflector = reflector;
            m_udp.Bind(new IPEndPoint(IPAddress.Any, 0));
            if (OperatingSystem.IsWindows())
                m_udp.IOControl(unchecked((int)0x9800000C), new byte[4], null);
            _ = ReceiveLoopAsync();
        }

        public static async Task<CoopPunch> StartAsync(string reflector)
        {
            if (!TryParseEndPoint(reflector, out IPEndPoint endPoint))
                return null;
            CoopPunch punch = new CoopPunch(endPoint);
            if (await punch.DiscoverAsync() == null)
            {
                punch.Dispose();
                return null;
            }
            _ = punch.KeepReflectorAsync();
            return punch;
        }

        public static bool TryParseEndPoint(string text, out IPEndPoint endPoint)
        {
            endPoint = null;
            return !string.IsNullOrEmpty(text) && IPEndPoint.TryParse(text, out endPoint) && endPoint.AddressFamily == AddressFamily.InterNetwork && endPoint.Port > 0;
        }

        public static ulong NewSession() => BinaryPrimitives.ReadUInt64LittleEndian(RandomNumberGenerator.GetBytes(8));

        public CoopLink Open(ulong session, IPEndPoint peer)
        {
            CoopLink link = new CoopLink(this, session, peer);
            m_links[session] = link;
            link.Closed += () => m_links.TryRemove(new KeyValuePair<ulong, CoopLink>(session, link));
            link.Start(m_stop.Token);
            return link;
        }

        async Task<IPEndPoint> DiscoverAsync()
        {
            for (int attempt = 0; attempt < DiscoverTries && !m_stop.IsCancellationRequested; attempt++)
            {
                TaskCompletionSource<IPEndPoint> discovery = new TaskCompletionSource<IPEndPoint>(TaskCreationOptions.RunContinuationsAsynchronously);
                m_nonce = Convert.ToHexString(RandomNumberGenerator.GetBytes(8));
                m_discovery = discovery;
                Send(Encoding.ASCII.GetBytes(("HOA1 WHOAMI " + m_nonce).PadRight(64)), m_reflector);
                if (await Task.WhenAny(discovery.Task, Task.Delay(DiscoverWait)) == discovery.Task)
                {
                    PublicEndPoint = discovery.Task.Result;
                    return PublicEndPoint;
                }
            }
            return null;
        }

        async Task KeepReflectorAsync()
        {
            while (!m_stop.IsCancellationRequested)
            {
                try
                {
                    await Task.Delay(ReflectorKeepAlive, m_stop.Token);
                }
                catch (OperationCanceledException)
                {
                    return;
                }
                await DiscoverAsync();
            }
        }

        internal void Send(byte[] packet, IPEndPoint to)
        {
            try
            {
                m_udp.SendTo(packet, to);
            }
            catch (SocketException)
            {
            }
            catch (ObjectDisposedException)
            {
            }
        }

        async Task ReceiveLoopAsync()
        {
            byte[] buffer = new byte[2048];
            EndPoint any = new IPEndPoint(IPAddress.Any, 0);
            while (!m_stop.IsCancellationRequested)
            {
                SocketReceiveFromResult received;
                try
                {
                    received = await m_udp.ReceiveFromAsync(buffer, SocketFlags.None, any, m_stop.Token);
                }
                catch (OperationCanceledException)
                {
                    return;
                }
                catch (ObjectDisposedException)
                {
                    return;
                }
                catch (SocketException)
                {
                    continue;
                }
                IPEndPoint from = (IPEndPoint)received.RemoteEndPoint;
                ReadOnlySpan<byte> packet = buffer.AsSpan(0, received.ReceivedBytes);
                if (from.Equals(m_reflector))
                    ReadReflector(packet);
                else if (CoopLink.TryReadSession(packet, out ulong session) && m_links.TryGetValue(session, out CoopLink link))
                    link.Receive(packet, from);
            }
        }

        void ReadReflector(ReadOnlySpan<byte> packet)
        {
            string[] parts = Encoding.ASCII.GetString(packet).Trim().Split(' ');
            if (parts.Length == 5 && parts[0] == "HOA1" && parts[1] == "YOU" && parts[4] == m_nonce &&
                IPAddress.TryParse(parts[2], out IPAddress address) && int.TryParse(parts[3], out int port))
                m_discovery?.TrySetResult(new IPEndPoint(address, port));
        }

        public void Dispose()
        {
            m_stop.Cancel();
            foreach (CoopLink link in m_links.Values.ToArray())
                link.Close();
            m_udp.Dispose();
        }
    }

    sealed class CoopLink
    {
        const byte Magic1 = (byte)'H';
        const byte Magic2 = (byte)'P';
        const byte Version = 1;
        const int HeaderSize = 12;
        const byte TypePunch = 1;
        const byte TypeData = 2;
        const byte TypeAck = 3;
        const byte TypePing = 4;
        const byte TypeBye = 5;
        const byte FrameOpen = 1;
        const byte FrameData = 2;
        const byte FrameClose = 3;
        public const int FramePayload = 1150;
        const int Window = 256;
        const int ReceiveAhead = 1024;
        const int MaxSends = 60;
        static readonly TimeSpan PunchInterval = TimeSpan.FromMilliseconds(200);
        static readonly TimeSpan PunchTime = TimeSpan.FromSeconds(20);
        static readonly TimeSpan PingInterval = TimeSpan.FromSeconds(3);
        static readonly TimeSpan SilenceLimit = TimeSpan.FromSeconds(45);
        static readonly TimeSpan TickInterval = TimeSpan.FromMilliseconds(20);

        sealed class Pending
        {
            public byte[] Packet;
            public DateTime FirstSent;
            public DateTime LastSent;
            public int Sends;
        }

        readonly CoopPunch m_owner;
        readonly ulong m_session;
        readonly object m_lock = new object();
        readonly SortedDictionary<uint, Pending> m_unacked = new SortedDictionary<uint, Pending>();
        readonly Dictionary<uint, byte[]> m_early = new Dictionary<uint, byte[]>();
        readonly SemaphoreSlim m_window = new SemaphoreSlim(Window, Window);
        readonly ConcurrentDictionary<uint, CoopLinkStream> m_streams = new ConcurrentDictionary<uint, CoopLinkStream>();
        readonly TaskCompletionSource<bool> m_heard = new TaskCompletionSource<bool>(TaskCreationOptions.RunContinuationsAsynchronously);
        readonly CancellationTokenSource m_stop = new CancellationTokenSource();
        IPEndPoint m_peer;
        uint m_nextSend;
        uint m_nextReceive;
        int m_nextStream;
        DateTime m_started;
        DateTime m_lastHeard;
        DateTime m_lastSent;
        double m_smoothedRtt = 200;
        double m_rttVariance = 100;
        int m_closed;

        public event Action Closed;
        public Func<uint, CoopLinkStream> StreamOpened;

        public Task<bool> Connected => m_heard.Task;
        public bool IsClosed => m_closed != 0;

        internal CoopLink(CoopPunch owner, ulong session, IPEndPoint peer)
        {
            m_owner = owner;
            m_session = session;
            m_peer = peer;
        }

        internal static bool TryReadSession(ReadOnlySpan<byte> packet, out ulong session)
        {
            session = 0;
            if (packet.Length < HeaderSize || packet[0] != Magic1 || packet[1] != Magic2 || packet[2] != Version)
                return false;
            session = BinaryPrimitives.ReadUInt64LittleEndian(packet.Slice(4));
            return true;
        }

        internal void Start(CancellationToken stop)
        {
            m_started = DateTime.UtcNow;
            stop.Register(Close);
            _ = TickLoopAsync();
        }

        public async Task<CoopLinkStream> OpenStreamAsync()
        {
            uint id = (uint)Interlocked.Increment(ref m_nextStream);
            CoopLinkStream stream = new CoopLinkStream(this, id);
            m_streams[id] = stream;
            await SendFrameAsync(FrameOpen, id, ReadOnlyMemory<byte>.Empty);
            return stream;
        }

        internal Task SendDataAsync(uint stream, ReadOnlyMemory<byte> data) => SendFrameAsync(FrameData, stream, data);

        internal void CloseStream(uint stream)
        {
            if (m_streams.TryRemove(stream, out _))
                _ = SendFrameAsync(FrameClose, stream, ReadOnlyMemory<byte>.Empty);
        }

        async Task SendFrameAsync(byte frame, uint stream, ReadOnlyMemory<byte> data)
        {
            try
            {
                await m_window.WaitAsync(m_stop.Token);
            }
            catch (OperationCanceledException)
            {
                return;
            }
            byte[] packet = new byte[HeaderSize + 4 + 5 + data.Length];
            WriteHeader(packet, TypeData);
            packet[HeaderSize + 4] = frame;
            BinaryPrimitives.WriteUInt32LittleEndian(packet.AsSpan(HeaderSize + 5), stream);
            data.Span.CopyTo(packet.AsSpan(HeaderSize + 9));
            lock (m_lock)
            {
                if (IsClosed)
                    return;
                uint seq = m_nextSend++;
                BinaryPrimitives.WriteUInt32LittleEndian(packet.AsSpan(HeaderSize), seq);
                DateTime now = DateTime.UtcNow;
                m_unacked[seq] = new Pending { Packet = packet, FirstSent = now, LastSent = now, Sends = 1 };
            }
            Transmit(packet);
        }

        void WriteHeader(byte[] packet, byte type)
        {
            packet[0] = Magic1;
            packet[1] = Magic2;
            packet[2] = Version;
            packet[3] = type;
            BinaryPrimitives.WriteUInt64LittleEndian(packet.AsSpan(4), m_session);
        }

        void Transmit(byte[] packet)
        {
            m_lastSent = DateTime.UtcNow;
            m_owner.Send(packet, m_peer);
        }

        void SendControl(byte type)
        {
            byte[] packet = new byte[HeaderSize];
            WriteHeader(packet, type);
            Transmit(packet);
        }

        internal void Receive(ReadOnlySpan<byte> packet, IPEndPoint from)
        {
            if (IsClosed)
                return;
            m_peer = from;
            m_lastHeard = DateTime.UtcNow;
            if (!m_heard.Task.IsCompleted)
            {
                m_heard.TrySetResult(true);
                SendControl(TypePunch);
            }
            byte type = packet[3];
            ReadOnlySpan<byte> body = packet.Slice(HeaderSize);
            if (type == TypeData && body.Length >= 9)
                ReceiveData(BinaryPrimitives.ReadUInt32LittleEndian(body), body.Slice(4).ToArray());
            else if (type == TypeAck && body.Length >= 8)
                ReceiveAck(BinaryPrimitives.ReadUInt32LittleEndian(body), BinaryPrimitives.ReadUInt32LittleEndian(body.Slice(4)));
            else if (type == TypeBye)
                Close();
        }

        void ReceiveData(uint seq, byte[] frame)
        {
            List<byte[]> ready = new List<byte[]>();
            uint next;
            uint bitmap = 0;
            lock (m_lock)
            {
                if (seq >= m_nextReceive && seq - m_nextReceive < ReceiveAhead)
                    m_early.TryAdd(seq, frame);
                while (m_early.Remove(m_nextReceive, out byte[] inOrder))
                {
                    ready.Add(inOrder);
                    m_nextReceive++;
                }
                next = m_nextReceive;
                for (int bit = 0; bit < 32; bit++)
                    if (m_early.ContainsKey(next + 1 + (uint)bit))
                        bitmap |= 1u << bit;
            }
            byte[] ack = new byte[HeaderSize + 8];
            WriteHeader(ack, TypeAck);
            BinaryPrimitives.WriteUInt32LittleEndian(ack.AsSpan(HeaderSize), next);
            BinaryPrimitives.WriteUInt32LittleEndian(ack.AsSpan(HeaderSize + 4), bitmap);
            Transmit(ack);
            foreach (byte[] inOrder in ready)
                Deliver(inOrder);
        }

        void Deliver(byte[] frame)
        {
            byte kind = frame[0];
            uint id = BinaryPrimitives.ReadUInt32LittleEndian(frame.AsSpan(1));
            if (kind == FrameOpen)
            {
                CoopLinkStream stream = StreamOpened?.Invoke(id);
                if (stream != null)
                    m_streams[id] = stream;
                else
                    _ = SendFrameAsync(FrameClose, id, ReadOnlyMemory<byte>.Empty);
            }
            else if (kind == FrameData && m_streams.TryGetValue(id, out CoopLinkStream target))
                target.Incoming(frame.AsMemory(5));
            else if (kind == FrameClose && m_streams.TryRemove(id, out CoopLinkStream closing))
                closing.RemoteClosed();
        }

        void ReceiveAck(uint next, uint bitmap)
        {
            DateTime now = DateTime.UtcNow;
            byte[] resend = null;
            int released = 0;
            lock (m_lock)
            {
                while (m_unacked.Count > 0)
                {
                    KeyValuePair<uint, Pending> oldest = m_unacked.First();
                    if (oldest.Key >= next)
                        break;
                    if (oldest.Value.Sends == 1)
                        SampleRtt((now - oldest.Value.FirstSent).TotalMilliseconds);
                    m_unacked.Remove(oldest.Key);
                    released++;
                }
                for (int bit = 0; bit < 32; bit++)
                    if ((bitmap & (1u << bit)) != 0 && m_unacked.Remove(next + 1 + (uint)bit))
                        released++;
                if (bitmap != 0 && m_unacked.TryGetValue(next, out Pending missing) && (now - missing.LastSent).TotalMilliseconds > Math.Max(20, m_smoothedRtt))
                {
                    missing.LastSent = now;
                    missing.Sends++;
                    resend = missing.Packet;
                }
            }
            if (released > 0)
                m_window.Release(released);
            if (resend != null)
                Transmit(resend);
        }

        void SampleRtt(double sample)
        {
            m_rttVariance = 0.75 * m_rttVariance + 0.25 * Math.Abs(m_smoothedRtt - sample);
            m_smoothedRtt = 0.875 * m_smoothedRtt + 0.125 * sample;
        }

        double RetransmitAfterMs => Math.Clamp(m_smoothedRtt + 4 * m_rttVariance, 100, 1000);

        async Task TickLoopAsync()
        {
            while (!IsClosed)
            {
                try
                {
                    await Task.Delay(TickInterval, m_stop.Token);
                }
                catch (OperationCanceledException)
                {
                    return;
                }
                DateTime now = DateTime.UtcNow;
                if (!m_heard.Task.IsCompleted)
                {
                    if (now - m_started > PunchTime)
                    {
                        Close();
                        return;
                    }
                    if (now - m_lastSent >= PunchInterval)
                        SendControl(TypePunch);
                    continue;
                }
                if (now - m_lastHeard > SilenceLimit)
                {
                    Close();
                    return;
                }
                List<byte[]> resend = new List<byte[]>();
                bool gaveUp = false;
                lock (m_lock)
                {
                    foreach (Pending pending in m_unacked.Values)
                    {
                        if ((now - pending.LastSent).TotalMilliseconds < RetransmitAfterMs * Math.Min(8, 1 << Math.Min(pending.Sends - 1, 3)))
                            continue;
                        if (pending.Sends >= MaxSends)
                        {
                            gaveUp = true;
                            break;
                        }
                        pending.LastSent = now;
                        pending.Sends++;
                        resend.Add(pending.Packet);
                        if (resend.Count >= 32)
                            break;
                    }
                }
                if (gaveUp)
                {
                    Close();
                    return;
                }
                foreach (byte[] packet in resend)
                    Transmit(packet);
                if (now - m_lastSent >= PingInterval)
                    SendControl(TypePing);
            }
        }

        public void Close()
        {
            if (Interlocked.Exchange(ref m_closed, 1) != 0)
                return;
            if (m_heard.Task.IsCompleted)
                SendControl(TypeBye);
            m_heard.TrySetResult(false);
            m_stop.Cancel();
            foreach (CoopLinkStream stream in m_streams.Values.ToArray())
                stream.RemoteClosed();
            m_streams.Clear();
            Closed?.Invoke();
        }
    }

    sealed class CoopLinkStream
    {
        readonly CoopLink m_link;
        readonly uint m_id;
        readonly Channel<ReadOnlyMemory<byte>> m_incoming = Channel.CreateUnbounded<ReadOnlyMemory<byte>>(new UnboundedChannelOptions { SingleReader = true });

        internal CoopLinkStream(CoopLink link, uint id)
        {
            m_link = link;
            m_id = id;
        }

        public static CoopLinkStream ToGate(CoopLink link, uint id, int gatePort)
        {
            CoopLinkStream stream = new CoopLinkStream(link, id);
            _ = stream.ConnectGateAsync(gatePort);
            return stream;
        }

        async Task ConnectGateAsync(int gatePort)
        {
            TcpClient client = new TcpClient(AddressFamily.InterNetwork);
            try
            {
                await client.ConnectAsync(IPAddress.Loopback, gatePort);
            }
            catch (SocketException)
            {
                client.Dispose();
                m_link.CloseStream(m_id);
                return;
            }
            await PumpAsync(client);
        }

        internal void Incoming(ReadOnlyMemory<byte> data) => m_incoming.Writer.TryWrite(data.ToArray());

        internal void RemoteClosed() => m_incoming.Writer.TryComplete();

        public async Task PumpAsync(TcpClient client)
        {
            using (client)
            {
                NetworkStream stream = client.GetStream();
                Task down = WriteIncomingAsync(stream);
                Task up = ReadOutgoingAsync(stream);
                await Task.WhenAny(down, up);
                m_link.CloseStream(m_id);
                m_incoming.Writer.TryComplete();
                client.Close();
                await Task.WhenAll(down.ContinueWith(_ => { }), up.ContinueWith(_ => { }));
            }
        }

        async Task WriteIncomingAsync(NetworkStream stream)
        {
            await foreach (ReadOnlyMemory<byte> data in m_incoming.Reader.ReadAllAsync())
                await stream.WriteAsync(data);
        }

        async Task ReadOutgoingAsync(NetworkStream stream)
        {
            byte[] buffer = new byte[CoopLink.FramePayload];
            while (!m_link.IsClosed)
            {
                int read = await stream.ReadAsync(buffer);
                if (read <= 0)
                    return;
                await m_link.SendDataAsync(m_id, buffer.AsMemory(0, read).ToArray());
            }
        }
    }

    sealed class CoopTunnel : IDisposable
    {
        readonly CoopLink m_link;
        readonly TcpListener m_listener = new TcpListener(IPAddress.Loopback, 0);
        readonly CancellationTokenSource m_stop = new CancellationTokenSource();

        public string Address => "127.0.0.1:" + ((IPEndPoint)m_listener.LocalEndpoint).Port;

        public CoopTunnel(CoopLink link)
        {
            m_link = link;
            m_listener.Start();
            _ = AcceptLoopAsync();
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
                catch (Exception)
                {
                    return;
                }
                if (m_link.IsClosed)
                {
                    client.Dispose();
                    continue;
                }
                _ = TunnelAsync(client);
            }
        }

        async Task TunnelAsync(TcpClient client)
        {
            CoopLinkStream stream = await m_link.OpenStreamAsync();
            await stream.PumpAsync(client);
        }

        public void Dispose()
        {
            m_stop.Cancel();
            m_listener.Stop();
            m_link.Close();
        }
    }
}

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;

namespace HordesOfAzeroth.Launcher
{
    static class PortOwners
    {
        const int IPv4 = 2;
        const int IPv6 = 23;
        const int ListenersWithOwner = 3;
        const uint NoError = 0;
        const uint QueryLimitedInformation = 0x1000;
        const int IPv4RowSize = 24;
        const int IPv4PortOffset = 8;
        const int IPv4PidOffset = 20;
        const int IPv6RowSize = 56;
        const int IPv6PortOffset = 20;
        const int IPv6PidOffset = 52;
        const int SystemProcessId = 4;

        [DllImport("iphlpapi.dll", SetLastError = true)]
        static extern uint GetExtendedTcpTable(IntPtr table, ref int size, bool sorted, int family, int tableClass, uint reserved);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern IntPtr OpenProcess(uint access, bool inherit, int processId);

        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        static extern bool QueryFullProcessImageName(IntPtr process, int flags, StringBuilder path, ref int size);

        [DllImport("kernel32.dll")]
        static extern bool CloseHandle(IntPtr handle);

        public sealed class Owner
        {
            public int ProcessId { get; set; }
            public string Name { get; set; }
            public string Path { get; set; }

            public string Describe()
            {
                if (Platform.IsWindows && ProcessId == SystemProcessId)
                    return Loc.T("Windows itself (System)");
                if (Path != null)
                    return $"{System.IO.Path.GetFileName(Path)} ({System.IO.Path.GetDirectoryName(Path)})";
                return Name ?? Loc.T("process {0}", ProcessId);
            }
        }

        public static List<Owner> Listening(int port)
        {
            HashSet<int> ids = new HashSet<int>();
            if (Platform.IsWindows)
            {
                ids.UnionWith(ListenerIds(IPv4, IPv4RowSize, IPv4PortOffset, IPv4PidOffset, port));
                ids.UnionWith(ListenerIds(IPv6, IPv6RowSize, IPv6PortOffset, IPv6PidOffset, port));
            }
            else
            {
                ids.UnionWith(LinuxListenerIds(port));
            }
            List<Owner> owners = new List<Owner>();
            foreach (int id in ids)
                owners.Add(Describe(id));
            return owners;
        }

        static IEnumerable<int> ListenerIds(int family, int rowSize, int portOffset, int pidOffset, int port)
        {
            List<int> ids = new List<int>();
            int size = 0;
            GetExtendedTcpTable(IntPtr.Zero, ref size, false, family, ListenersWithOwner, 0);
            if (size <= 0)
                return ids;
            IntPtr table = Marshal.AllocHGlobal(size);
            try
            {
                if (GetExtendedTcpTable(table, ref size, false, family, ListenersWithOwner, 0) != NoError)
                    return ids;
                int rows = Marshal.ReadInt32(table);
                for (int row = 0; row < rows; row++)
                {
                    IntPtr entry = table + sizeof(int) + row * rowSize;
                    if (HostOrderPort(Marshal.ReadInt32(entry + portOffset)) == port)
                        ids.Add(Marshal.ReadInt32(entry + pidOffset));
                }
            }
            finally
            {
                Marshal.FreeHGlobal(table);
            }
            return ids;
        }

        const string LinuxListenState = "0A";

        static IEnumerable<int> LinuxListenerIds(int port)
        {
            HashSet<string> sockets = new HashSet<string>();
            foreach (string table in new[] { "/proc/net/tcp", "/proc/net/tcp6" })
            {
                if (!File.Exists(table))
                    continue;
                foreach (string line in File.ReadLines(table))
                {
                    string[] fields = line.Split((char[])null, StringSplitOptions.RemoveEmptyEntries);
                    if (fields.Length < 10 || fields[3] != LinuxListenState)
                        continue;
                    string local = fields[1];
                    int colon = local.LastIndexOf(':');
                    if (colon < 0 || !int.TryParse(local.Substring(colon + 1), NumberStyles.HexNumber, CultureInfo.InvariantCulture, out int localPort))
                        continue;
                    if (localPort == port)
                        sockets.Add("socket:[" + fields[9] + "]");
                }
            }
            List<int> ids = new List<int>();
            if (sockets.Count == 0)
                return ids;
            foreach (string process in Directory.EnumerateDirectories("/proc"))
            {
                if (!int.TryParse(Path.GetFileName(process), out int id))
                    continue;
                try
                {
                    foreach (string descriptor in Directory.EnumerateFileSystemEntries(Path.Combine(process, "fd")))
                    {
                        string target = new FileInfo(descriptor).LinkTarget;
                        if (target != null && sockets.Contains(target))
                        {
                            ids.Add(id);
                            break;
                        }
                    }
                }
                catch (Exception e) when (e is UnauthorizedAccessException || e is IOException)
                {
                }
            }
            return ids;
        }

        static int HostOrderPort(int networkOrder) => ((networkOrder & 0xFF) << 8) | ((networkOrder >> 8) & 0xFF);

        static Owner Describe(int processId)
        {
            Owner owner = new Owner { ProcessId = processId, Path = ImagePath(processId) };
            try
            {
                using (Process process = Process.GetProcessById(processId))
                    owner.Name = process.ProcessName;
            }
            catch (ArgumentException)
            {
            }
            catch (InvalidOperationException)
            {
            }
            return owner;
        }

        static string ImagePath(int processId)
        {
            if (!Platform.IsWindows)
            {
                try
                {
                    return new FileInfo($"/proc/{processId}/exe").LinkTarget;
                }
                catch (Exception e) when (e is UnauthorizedAccessException || e is IOException)
                {
                    return null;
                }
            }
            IntPtr handle = OpenProcess(QueryLimitedInformation, false, processId);
            if (handle == IntPtr.Zero)
                return null;
            try
            {
                StringBuilder path = new StringBuilder(1024);
                int size = path.Capacity;
                return QueryFullProcessImageName(handle, 0, path, ref size) ? path.ToString(0, size) : null;
            }
            finally
            {
                CloseHandle(handle);
            }
        }

        public static bool IsInside(this Owner owner, string folder)
        {
            if (owner.Path == null)
                return false;
            string root = System.IO.Path.GetFullPath(folder).TrimEnd(System.IO.Path.DirectorySeparatorChar) + System.IO.Path.DirectorySeparatorChar;
            return owner.Path.StartsWith(root, Platform.IsWindows ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal);
        }
    }
}

using System;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Sockets;

namespace HordesOfAzeroth.Launcher
{
    static class DatabasePorts
    {
        public const int Preferred = 3306;
        static readonly int[] Fallbacks = { 13306, 23306, 33306, 43306, 53306 };

        static string SavedFile(GameFolder folder) => Path.Combine(folder.LauncherData, "database-port.txt");

        public static int Saved(GameFolder folder)
        {
            string file = SavedFile(folder);
            if (File.Exists(file) && int.TryParse(File.ReadAllText(file).Trim(), out int port) && port > 0 && port < 65536)
                return port;
            return Preferred;
        }

        public static int Pick(GameFolder folder, Func<int, bool> usable)
        {
            int port = new[] { Preferred }.Concat(Fallbacks).FirstOrDefault(usable);
            if (port == 0)
                port = AnyFreePort();
            Save(folder, port);
            return port;
        }

        public static void Save(GameFolder folder, int port)
        {
            Directory.CreateDirectory(folder.LauncherData);
            File.WriteAllText(SavedFile(folder), port.ToString());
        }

        public static bool CanListen(int port)
        {
            TcpListener listener = new TcpListener(IPAddress.Loopback, port);
            try
            {
                listener.Start();
                return true;
            }
            catch (SocketException)
            {
                return false;
            }
            finally
            {
                listener.Stop();
            }
        }

        static int AnyFreePort()
        {
            TcpListener listener = new TcpListener(IPAddress.Loopback, 0);
            listener.Start();
            int port = ((IPEndPoint)listener.LocalEndpoint).Port;
            listener.Stop();
            return port;
        }
    }
}

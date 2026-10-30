using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace HordesOfAzeroth.Launcher
{
    sealed class GameClient
    {
        const string OwnAddon = "HordesOfAzeroth";
        const string OldBindingsFile = "bindings-cache.wtf";

        readonly GameFolder m_folder;
        StreamWriter m_log;

        public GameClient(GameFolder folder)
        {
            m_folder = folder;
        }

        string RealmName => new UpdateCheck(m_folder).LoadCached()?.RealmName ?? "Hordes of Azeroth";

        public string ProcessName => Platform.IsWindows ? Path.GetFileNameWithoutExtension(m_folder.GameExeName) : m_folder.GameExeName;

        public bool IsRunning => Process.GetProcessesByName(ProcessName).Length > 0;

        public DateTime LaunchedAt { get; private set; }

        public void Prepare(Account account)
        {
            if (!File.Exists(m_folder.GameExe))
                throw new FileNotFoundException($"{m_folder.GameExeName} is missing. {LocalServer.RepairAdvice}");

            Directory.CreateDirectory(m_folder.GlueXml);
            File.WriteAllLines(Path.Combine(m_folder.GlueXml, "BonkAccount.lua"), new[]
            {
                $"BONK_ACCOUNT = {LuaString(account.Login)};",
                $"BONK_PASSWORD = {LuaString(account.Password)};",
            }, new UTF8Encoding(false));
            string stats = Path.Combine(m_folder.GlueXml, "BonkStats.lua");
            if (!File.Exists(stats))
                File.WriteAllLines(stats, new[] { "BONK_STATS = nil;" }, new UTF8Encoding(false));

            ClearObjectCache();
            InstallAddon();
            CarryOverSavedVariables();
            CarryOverBindings();
            GameConfig.EnsureDefaults(m_folder, RealmName);
        }

        void ClearObjectCache()
        {
            if (!Directory.Exists(m_folder.ClientCache))
                return;
            foreach (string cached in Directory.GetFiles(m_folder.ClientCache, "*.bin", SearchOption.AllDirectories))
                File.Delete(cached);
        }

        void InstallAddon()
        {
            string source = Path.Combine(m_folder.AddOns, OwnAddon);
            string target = Path.Combine(m_folder.ClientAddOns, OwnAddon);
            if (!Directory.Exists(source) || IsLink(target))
                return;
            if (Directory.Exists(target) && !Folders.TryDelete(target))
                Folders.ClearReadOnly(target);
            CopyTree(source, target);
        }

        void CarryOverSavedVariables()
        {
            string saved = OwnAddon + ".lua";
            string old = Path.Combine(m_folder.OldSavedVariables, saved);
            string target = Path.Combine(m_folder.ClientSaved, saved);
            if (!File.Exists(old) || File.Exists(target))
                return;
            Directory.CreateDirectory(m_folder.ClientSaved);
            File.Copy(old, target);
        }

        void CarryOverBindings()
        {
            CarryOverBindingFile(Path.Combine(m_folder.OldAccount, OldBindingsFile), Path.Combine(m_folder.ClientBindings, "account.txt"));
            string realm = Path.Combine(m_folder.OldAccount, RealmName);
            if (!Directory.Exists(realm))
                return;
            foreach (string character in Directory.GetDirectories(realm))
            {
                string name = $"{FileToken(RealmName)}-{FileToken(Path.GetFileName(character))}.txt";
                CarryOverBindingFile(Path.Combine(character, OldBindingsFile), Path.Combine(m_folder.ClientBindings, name));
            }
        }

        static void CarryOverBindingFile(string old, string target)
        {
            if (!File.Exists(old))
                return;
            List<(string Command, List<string> Keys)> oldBindings = ReadOldBindings(old);
            if (oldBindings.Count > 0)
            {
                List<string> newer = File.Exists(target)
                    ? File.ReadAllLines(target).Where(line => line.StartsWith("bind ")).ToList()
                    : new List<string>();
                HashSet<string> newerCommands = new HashSet<string>(
                    newer.Select(line => line.Split(' ', StringSplitOptions.RemoveEmptyEntries)).Where(parts => parts.Length > 1).Select(parts => parts[1]),
                    StringComparer.OrdinalIgnoreCase);
                List<string> lines = new List<string> { "# benilla key bindings" };
                lines.AddRange(oldBindings
                    .Where(binding => !newerCommands.Contains(binding.Command))
                    .Select(binding => "bind " + binding.Command + " " + string.Join(" ", binding.Keys)));
                lines.AddRange(newer);
                Directory.CreateDirectory(Path.GetDirectoryName(target));
                File.WriteAllLines(target, lines, new UTF8Encoding(false));
            }
            File.Move(old, old + ".imported", true);
        }

        static List<(string Command, List<string> Keys)> ReadOldBindings(string path)
        {
            List<(string Command, List<string> Keys)> bindings = new List<(string, List<string>)>();
            foreach (string line in File.ReadAllLines(path))
            {
                string[] parts = line.Split(' ', StringSplitOptions.RemoveEmptyEntries);
                if (parts.Length != 3 || parts[0] != "bind")
                    continue;
                string key = parts[1].ToUpperInvariant();
                string command = parts[2].ToUpperInvariant();
                int index = bindings.FindIndex(binding => binding.Command == command);
                if (index < 0)
                    bindings.Add((command, new List<string> { key }));
                else
                    bindings[index].Keys.Add(key);
            }
            return bindings;
        }

        static string FileToken(string name)
        {
            string token = new string(name.Select(c => char.IsLetterOrDigit(c) ? c : '_').ToArray());
            return token.Length == 0 ? "unknown" : token;
        }

        static bool IsLink(string path) =>
            Directory.Exists(path) && new DirectoryInfo(path).Attributes.HasFlag(FileAttributes.ReparsePoint);

        static void CopyTree(string from, string to)
        {
            Directory.CreateDirectory(to);
            foreach (string file in Directory.GetFiles(from))
                File.Copy(file, Path.Combine(to, Path.GetFileName(file)), true);
            foreach (string folder in Directory.GetDirectories(from))
                CopyTree(folder, Path.Combine(to, Path.GetFileName(folder)));
        }

        public async Task<Process> StartAsync(CancellationToken cancel)
        {
            ProcessStartInfo info = new ProcessStartInfo(m_folder.GameExe)
            {
                WorkingDirectory = m_folder.Root,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true,
            };
            info.EnvironmentVariables["WOW_DATA"] = m_folder.Data;
            Directory.CreateDirectory(Path.GetDirectoryName(m_folder.ClientLog));
            m_log?.Dispose();
            m_log = new StreamWriter(m_folder.ClientLog, false, new UTF8Encoding(false)) { AutoFlush = true };
            LaunchedAt = DateTime.UtcNow;
            Process game = new Process { StartInfo = info, EnableRaisingEvents = true };
            game.OutputDataReceived += (_, line) => WriteLog(line.Data);
            game.ErrorDataReceived += (_, line) => WriteLog(line.Data);
            game.Exited += (_, __) => CloseLog();
            game.Start();
            game.BeginOutputReadLine();
            game.BeginErrorReadLine();

            Stopwatch clock = Stopwatch.StartNew();
            while (clock.Elapsed < TimeSpan.FromSeconds(30))
            {
                if (game.HasExited)
                    throw new InvalidOperationException($"The game closed while starting. Its log is {m_folder.ClientLog}.");
                if (game.MainWindowHandle != IntPtr.Zero || clock.Elapsed > TimeSpan.FromSeconds(2))
                    return game;
                await Task.Delay(250, cancel);
                game.Refresh();
            }
            return game;
        }

        void WriteLog(string line)
        {
            if (line == null)
                return;
            lock (this)
                m_log?.WriteLine(line);
        }

        void CloseLog()
        {
            lock (this)
            {
                m_log?.Dispose();
                m_log = null;
            }
        }

        public async Task WaitForAllToCloseAsync(CancellationToken cancel)
        {
            while (IsRunning)
                await Task.Delay(1000, cancel);
        }

        static string LuaString(string text) => "\"" + text.Replace("\\", "\\\\").Replace("\"", "\\\"") + "\"";
    }
}

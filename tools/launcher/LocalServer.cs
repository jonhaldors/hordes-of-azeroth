using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net.Sockets;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;

namespace HordesOfAzeroth.Launcher
{
    sealed class WorldDatabaseException : InvalidOperationException
    {
        public WorldDatabaseException(string message) : base(message)
        {
        }
    }

    sealed class LocalServer
    {
        public static string RepairAdvice => Loc.T("Choose Repair the game in the ••• menu next to Play.");
        static readonly string[] OutdatedWorldLines = { "database structure is not up to date", "Database `mangos` is missing the following migrations" };
        const string Host = "127.0.0.1";
        const int LoginPort = 3724;
        const int WorldPort = 8085;
        static readonly Regex DatabaseInfo = new Regex(@"^(\s*\w*Database\.?Info\s*=\s*""[^;]*;)\d+;");
        static readonly TimeSpan DatabaseCreationLimit = TimeSpan.FromMinutes(3);
        static readonly TimeSpan OwnershipCheckLimit = TimeSpan.FromSeconds(15);
        const string RootPasswordSql = "UPDATE mysql.global_priv SET priv = JSON_SET(priv, '$.plugin', 'mysql_native_password', '$.authentication_string', PASSWORD('root')) WHERE User = 'root';";

        readonly GameFolder m_folder;
        Process m_world;
        Process m_login;
        Process m_database;
        int m_databasePort;

        public LocalServer(GameFolder folder)
        {
            m_folder = folder;
            m_databasePort = DatabasePorts.Saved(folder);
        }

        string[] DatabaseLogin => LoginTo(m_databasePort);

        static string[] LoginTo(int port) => new[] { "-h", Host, "-P", port.ToString(), "-u", "root", "-proot", "--skip-ssl" };

        async Task ChooseDatabasePortAsync()
        {
            foreach (int port in new[] { m_databasePort, DatabasePorts.Preferred }.Distinct())
                if (IsPortOpen(port) && await IsOurDatabaseAsync(port))
                {
                    m_databasePort = port;
                    DatabasePorts.Save(m_folder, port);
                    return;
                }
            await StopStrayDatabasesAsync();
            m_databasePort = DatabasePorts.Pick(m_folder, port => !IsPortOpen(port) && DatabasePorts.CanListen(port));
        }

        async Task<bool> IsOurDatabaseAsync(int port)
        {
            List<string> arguments = LoginTo(port).ToList();
            arguments.AddRange(new[] { "-N", "-B", "-r", "-e", "\"SELECT @@datadir\"" });
            try
            {
                string dataDir = await RunToEndAsync(MariaDbProgram("mariadb"), m_folder.MariaDb, OwnershipCheckLimit, arguments.ToArray());
                return SameFolder(dataDir.Trim(), m_folder.MariaDbData);
            }
            catch (InvalidOperationException)
            {
                return false;
            }
        }

        static bool SameFolder(string first, string second)
        {
            if (first.Length == 0)
                return false;
            string Normal(string path) => Path.GetFullPath(path).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
            return string.Equals(Normal(first), Normal(second), Platform.IsWindows ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal);
        }

        async Task StopStrayDatabasesAsync()
        {
            foreach (Process stray in OwnProcesses("mariadbd"))
            {
                KillQuietly(stray);
                await WaitForExitAsync(stray, TimeSpan.FromSeconds(30));
            }
        }

        Process StartDatabase() => StartHidden(MariaDbProgram("mariadbd"), m_folder.MariaDb,
            $"\"--defaults-file={Path.Combine(m_folder.Config, "mariadb.ini")}\"",
            $"\"--basedir={m_folder.MariaDb}\"",
            $"\"--datadir={m_folder.MariaDbData}\"",
            $"--port={m_databasePort}");

        public bool StartedByUs => m_world != null || m_login != null || m_database != null;

        public async Task StartAsync(IProgress<string> progress, CancellationToken cancel)
        {
            await ChooseDatabasePortAsync();
            ThrowIfPortTaken(LoginPort, Loc.Key("its login server"));
            ThrowIfPortTaken(WorldPort, Loc.Key("its world server"));
            Directory.CreateDirectory(m_folder.ServerLogs);
            WriteServerConfig("mangosd");
            WriteServerConfig("realmd");

            if (!IsPortOpen(m_databasePort))
            {
                progress.Report(Loc.T("Starting the database"));
                m_database = StartDatabase();
                await WaitForPortAsync(m_databasePort, m_database, TimeSpan.FromSeconds(60), Loc.Key("the database"), cancel);
            }

            if (!IsPortOpen(LoginPort))
            {
                progress.Report(Loc.T("Starting the login server"));
                m_login = StartHidden(Path.Combine(m_folder.ServerRun, Platform.Exe("realmd")), m_folder.ServerRun, "-c", "realmd.conf");
                await WaitForPortAsync(LoginPort, m_login, TimeSpan.FromSeconds(30), Loc.Key("the login server"), cancel);
            }

            if (!IsPortOpen(WorldPort))
            {
                progress.Report(Loc.T("Loading the world"));
                DateTime started = DateTime.UtcNow;
                m_world = StartHidden(Path.Combine(m_folder.ServerRun, Platform.Exe("mangosd")), m_folder.ServerRun, true, "-c", "mangosd.conf");
                try
                {
                    await WaitForPortAsync(WorldPort, m_world, TimeSpan.FromMinutes(5), Loc.Key("the world server"), cancel);
                }
                catch (InvalidOperationException) when (m_world.HasExited && WorldLogsMention(OutdatedWorldLines, started))
                {
                    throw new WorldDatabaseException(Loc.T("The world database doesn't match the server. {0}", RepairAdvice));
                }
            }
        }

        bool WorldLogsMention(string[] texts, DateTime sinceUtc)
        {
            foreach (string name in new[] { "Server.log", "DBErrors.log" })
            {
                string log = Path.Combine(m_folder.ServerLogs, name);
                if (!File.Exists(log) || File.GetLastWriteTimeUtc(log) < sinceUtc.AddSeconds(-2))
                    continue;
                using (FileStream stream = new FileStream(log, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
                using (StreamReader reader = new StreamReader(stream))
                {
                    string written = reader.ReadToEnd();
                    if (texts.Any(t => written.IndexOf(t, StringComparison.OrdinalIgnoreCase) >= 0))
                        return true;
                }
            }
            return false;
        }

        public async Task StopAsync()
        {
            if (m_world != null && !m_world.HasExited)
            {
                try
                {
                    m_world.StandardInput.WriteLine("server shutdown 0");
                    m_world.StandardInput.Flush();
                    m_world.StandardInput.Close();
                }
                catch (IOException)
                {
                }
                await WaitForExitAsync(m_world, TimeSpan.FromSeconds(30));
            }
            if (m_login != null && !m_login.HasExited)
                KillQuietly(m_login);
            if (m_database != null && !m_database.HasExited)
            {
                string admin = MariaDbProgram("mariadb-admin");
                Process shutdown = StartHidden(admin, m_folder.MariaDb, DatabaseLogin.Concat(new[] { "shutdown" }).ToArray());
                await WaitForExitAsync(shutdown, TimeSpan.FromSeconds(30));
                await WaitForExitAsync(m_database, TimeSpan.FromSeconds(30));
            }
            m_world = m_login = m_database = null;
            await StopLeftoversAsync();
        }

        async Task StopLeftoversAsync()
        {
            foreach (Process world in OwnProcesses("mangosd"))
                KillQuietly(world);
            foreach (Process login in OwnProcesses("realmd"))
                KillQuietly(login);
            if (OwnProcesses("mariadbd").Any())
            {
                string admin = MariaDbProgram("mariadb-admin");
                if (File.Exists(admin))
                {
                    Process shutdown = StartHidden(admin, m_folder.MariaDb, DatabaseLogin.Concat(new[] { "shutdown" }).ToArray());
                    await WaitForExitAsync(shutdown, TimeSpan.FromSeconds(30));
                }
                foreach (Process database in OwnProcesses("mariadbd"))
                    await WaitForExitAsync(database, TimeSpan.FromSeconds(30));
            }
        }

        string MariaDbProgram(string name) => Path.Combine(m_folder.MariaDb, "bin", Platform.Exe(name));

        IEnumerable<Process> OwnProcesses(string name)
        {
            string root = Path.GetFullPath(m_folder.Root).TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
            foreach (Process process in Process.GetProcessesByName(name))
            {
                string path = null;
                try
                {
                    path = process.MainModule.FileName;
                }
                catch (System.ComponentModel.Win32Exception)
                {
                }
                catch (InvalidOperationException)
                {
                }
                if (path != null && path.StartsWith(root, Platform.IsWindows ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal))
                    yield return process;
            }
        }

        void ThrowIfPortTaken(int port, string use)
        {
            foreach (PortOwners.Owner owner in PortOwners.Listening(port))
                if (!owner.IsInside(m_folder.Root))
                    throw new InvalidOperationException(
                        Loc.T("Port {0} is in use by {1}. Hordes of Azeroth needs it for {2}. Close that program (or stop its service) and try again.", port, owner.Describe(), Loc.T(use)));
        }

        public bool DatabaseExists => Directory.Exists(Path.Combine(m_folder.MariaDbData, "mysql"));

        public async Task CreateDatabaseFilesAsync()
        {
            if (Directory.Exists(m_folder.MariaDbData))
                Directory.Delete(m_folder.MariaDbData, true);
            Directory.CreateDirectory(m_folder.MariaDbData);
            try
            {
                if (Platform.IsWindows)
                    await RunToEndAsync(MariaDbProgram("mariadb-install-db"), m_folder.MariaDb, DatabaseCreationLimit,
                        $"\"--datadir={m_folder.MariaDbData}\"", "--password=root",
                        $"\"--config={Path.Combine(m_folder.Config, "mariadb.ini")}\"", "--verbose-bootstrap");
                else
                    await CreateLinuxDatabaseFilesAsync();
            }
            catch (InvalidOperationException failure)
            {
                string serverLog = DatabaseErrorLogLine();
                try
                {
                    Directory.Delete(m_folder.MariaDbData, true);
                }
                catch (IOException)
                {
                }
                catch (UnauthorizedAccessException)
                {
                }
                throw serverLog == null ? failure : new InvalidOperationException(Loc.T("{0} Database log: {1}", failure.Message, serverLog), failure);
            }
        }

        async Task CreateLinuxDatabaseFilesAsync()
        {
            string rootPassword = Path.Combine(m_folder.LauncherData, "root-password.sql");
            Directory.CreateDirectory(m_folder.LauncherData);
            File.WriteAllText(rootPassword, RootPasswordSql);
            try
            {
                string FromMariaDb(string path) => Path.GetRelativePath(m_folder.MariaDb, path);
                await RunToEndAsync(Path.Combine(m_folder.MariaDb, "scripts", "mariadb-install-db"), m_folder.MariaDb, DatabaseCreationLimit,
                    $"\"--defaults-file={FromMariaDb(Path.Combine(m_folder.Config, "mariadb.ini"))}\"",
                    "--basedir=.", $"\"--datadir={FromMariaDb(m_folder.MariaDbData)}\"",
                    "--auth-root-authentication-method=normal", $"\"--extra-file={FromMariaDb(rootPassword)}\"");
            }
            finally
            {
                File.Delete(rootPassword);
            }
        }

        string DatabaseErrorLogLine()
        {
            if (!Directory.Exists(m_folder.MariaDbData))
                return null;
            foreach (string log in Directory.GetFiles(m_folder.MariaDbData, "*.err"))
            {
                string[] lines = File.ReadAllLines(log);
                int lastStart = Array.FindLastIndex(lines, l => l.Contains("Starting MariaDB"));
                string line = lines.Skip(Math.Max(0, lastStart)).Select(l => l.Trim()).FirstOrDefault(l => l.IndexOf("[ERROR]", StringComparison.OrdinalIgnoreCase) >= 0);
                if (line != null)
                    return line;
            }
            return null;
        }

        public async Task StartDatabaseOnlyAsync(CancellationToken cancel)
        {
            await ChooseDatabasePortAsync();
            if (IsPortOpen(m_databasePort))
                return;
            m_database = StartDatabase();
            await WaitForPortAsync(m_databasePort, m_database, TimeSpan.FromSeconds(60), Loc.Key("the database"), cancel);
        }

        public Task RunSqlFileAsync(string database, string file)
        {
            string source = "source " + file.Replace('\\', '/');
            List<string> arguments = DatabaseLogin.ToList();
            if (database != null)
                arguments.Add(database);
            arguments.Add("-e");
            arguments.Add("\"" + source + "\"");
            return RunToEndAsync(MariaDbProgram("mariadb"), m_folder.MariaDb, arguments.ToArray());
        }

        public async Task<string> QueryAsync(string database, string sql)
        {
            List<string> arguments = DatabaseLogin.ToList();
            arguments.AddRange(new[] { "-N", "-B", database, "-e", "\"" + sql.Replace("\"", "\\\"") + "\"" });
            return await RunToEndAsync(MariaDbProgram("mariadb"), m_folder.MariaDb, arguments.ToArray());
        }

        public Task BackUpAsync(string file, params string[] databases)
        {
            List<string> arguments = DatabaseLogin.ToList();
            arguments.AddRange(new[] { "--single-transaction", $"\"--result-file={file}\"", "--databases" });
            arguments.AddRange(databases);
            return RunToEndAsync(MariaDbProgram("mariadb-dump"), m_folder.MariaDb, arguments.ToArray());
        }

        public async Task RunConsoleAsync(string command)
        {
            if (m_world == null || m_world.HasExited)
                throw new InvalidOperationException(Loc.T("The world server isn't running."));
            m_world.StandardInput.WriteLine(command);
            m_world.StandardInput.Flush();
            await Task.Delay(1500);
        }

        Task<string> RunToEndAsync(string exe, string workingDirectory, params string[] arguments) =>
            RunToEndAsync(exe, workingDirectory, Timeout.InfiniteTimeSpan, arguments);

        async Task<string> RunToEndAsync(string exe, string workingDirectory, TimeSpan limit, params string[] arguments)
        {
            ProcessStartInfo info = new ProcessStartInfo(exe, string.Join(" ", arguments))
            {
                WorkingDirectory = workingDirectory,
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
            };
            using (Process process = Process.Start(info))
            {
                Task<string> output = process.StandardOutput.ReadToEndAsync();
                Task<string> error = process.StandardError.ReadToEndAsync();
                Stopwatch clock = Stopwatch.StartNew();
                while (!process.HasExited)
                {
                    if (limit != Timeout.InfiniteTimeSpan && clock.Elapsed > limit)
                    {
                        process.Kill();
                        process.WaitForExit(5000);
                        string stuck = $"{Path.GetFileName(exe)} did not finish within {limit.TotalMinutes:0} minutes";
                        LogOutput(stuck, await error, await output);
                        throw new InvalidOperationException(Loc.T("{0} did not finish within {1:0} minutes. Its output is in the launcher log.", Path.GetFileName(exe), limit.TotalMinutes));
                    }
                    await Task.Delay(100);
                }
                string text = await output;
                string problem = await error;
                if (process.ExitCode != 0)
                {
                    string failure = $"{Path.GetFileName(exe)} failed (exit code 0x{process.ExitCode:X})";
                    LogOutput(failure, problem, text);
                    throw new InvalidOperationException(Loc.T("{0} failed (exit code 0x{1:X}): {2}", Path.GetFileName(exe), process.ExitCode, Details(problem, text)));
                }
                return text;
            }
        }

        void LogOutput(string what, string problem, string text) =>
            LauncherLog.Write(m_folder, $"{what}{Environment.NewLine}stderr:{Environment.NewLine}{problem}{Environment.NewLine}stdout (end):{Environment.NewLine}{string.Join(Environment.NewLine, Lines(text).Reverse().Take(20).Reverse())}");

        static string Details(string error, string output)
        {
            List<string> errorLines = Lines(error).ToList();
            string line = errorLines.FirstOrDefault(l => l.StartsWith("ERROR"))
                ?? errorLines.FirstOrDefault(l => !l.StartsWith("WARNING") && l.Trim('-').Length > 0)
                ?? Lines(output).LastOrDefault(l => l.Trim('-').Length > 0);
            return line ?? Loc.T("no details");
        }

        static IEnumerable<string> Lines(string text)
        {
            return (text ?? "").Split('\n').Select(l => l.Trim()).Where(l => l.Length > 0);
        }

        void WriteServerConfig(string name)
        {
            string dist = Path.Combine(m_folder.ServerRun, name + ".conf.dist");
            string overrides = Path.Combine(m_folder.Config, name + ".overrides.conf");
            string target = Path.Combine(m_folder.ServerRun, name + ".conf");
            if (!File.Exists(dist) || !File.Exists(overrides))
                return;

            List<string> lines = File.ReadAllLines(dist).ToList();
            Regex setting = new Regex(@"^\s*([\w.]+)\s*=");
            foreach (string line in File.ReadAllLines(overrides))
            {
                Match match = setting.Match(line);
                if (!match.Success)
                    continue;
                Regex key = new Regex(@"^\s*" + Regex.Escape(match.Groups[1].Value) + @"\s*=");
                int index = lines.FindIndex(l => key.IsMatch(l));
                if (index < 0)
                    throw new InvalidDataException($"{overrides} sets {match.Groups[1].Value}, which {dist} does not define.");
                lines[index] = line.Trim();
            }
            File.WriteAllLines(target, lines.Select(l => DatabaseInfo.Replace(l, "${1}" + m_databasePort + ";")));
        }

        static Process StartHidden(string exe, string workingDirectory, params string[] arguments)
        {
            return StartHidden(exe, workingDirectory, false, arguments);
        }

        static Process StartHidden(string exe, string workingDirectory, bool redirectInput, params string[] arguments)
        {
            if (!File.Exists(exe))
                throw new FileNotFoundException(Loc.T("{0} is missing. {1}", Path.GetFileName(exe), RepairAdvice), exe);
            ProcessStartInfo info = new ProcessStartInfo(exe, string.Join(" ", arguments))
            {
                WorkingDirectory = workingDirectory,
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardInput = redirectInput,
                RedirectStandardOutput = redirectInput,
                RedirectStandardError = redirectInput,
            };
            Process process = Process.Start(info);
            if (redirectInput)
            {
                process.OutputDataReceived += (s, e) => { };
                process.ErrorDataReceived += (s, e) => { };
                process.BeginOutputReadLine();
                process.BeginErrorReadLine();
            }
            return process;
        }

        static bool IsPortOpen(int port)
        {
            using (TcpClient client = new TcpClient())
            {
                try
                {
                    return client.ConnectAsync(Host, port).Wait(500) && client.Connected;
                }
                catch (AggregateException)
                {
                    return false;
                }
            }
        }

        async Task WaitForPortAsync(int port, Process process, TimeSpan timeout, string what, CancellationToken cancel)
        {
            Stopwatch clock = Stopwatch.StartNew();
            while (!IsPortOpen(port))
            {
                cancel.ThrowIfCancellationRequested();
                if (process.HasExited)
                {
                    string databaseError = process == m_database ? DatabaseErrorLogLine() : null;
                    if (databaseError != null)
                        throw new InvalidOperationException(Loc.T("{0} stopped with code {1}: {2}", CapitalFirst(Loc.T(what)), process.ExitCode, databaseError));
                    throw new InvalidOperationException(Loc.T("{0} stopped with code {1}. See {2}.", CapitalFirst(Loc.T(what)), process.ExitCode, Path.Combine(m_folder.ServerLogs, "Server.log")));
                }
                if (clock.Elapsed > timeout)
                    throw new TimeoutException(Loc.T("{0} did not start within {1:0} seconds.", CapitalFirst(Loc.T(what)), timeout.TotalSeconds));
                await Task.Delay(500, cancel);
            }
        }

        static async Task WaitForExitAsync(Process process, TimeSpan timeout)
        {
            Stopwatch clock = Stopwatch.StartNew();
            while (!process.HasExited && clock.Elapsed < timeout)
                await Task.Delay(250);
            if (!process.HasExited)
                KillQuietly(process);
        }

        static void KillQuietly(Process process)
        {
            try
            {
                process.Kill();
                process.WaitForExit(5000);
            }
            catch (InvalidOperationException)
            {
            }
            catch (System.ComponentModel.Win32Exception)
            {
            }
        }

        static string CapitalFirst(string text) => char.ToUpperInvariant(text[0]) + text.Substring(1);
    }
}

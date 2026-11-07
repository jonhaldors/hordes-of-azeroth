using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Text;

namespace HordesOfAzeroth.Launcher
{
    static class LogBundle
    {
        const long MaxBytesPerFile = 2 * 1024 * 1024;
        const int NewestCrashes = 3;
        static readonly string[] SkippedLogs = { "Chat.log", "WoWChatLog.txt" };
        static readonly string[] GamePrograms = { "mangosd.exe", "realmd.exe", "mariadbd.exe", "HordesOfAzeroth.exe", "HoALauncher.exe", "WoW.exe" };
        static readonly string[] PrivateEventLines = { "User:", "User Name:", "Computer:" };
        const int NewestCrashEvents = 10;

        public static string Save(GameFolder folder)
        {
            string desktop = Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory);
            if (string.IsNullOrEmpty(desktop) || !Directory.Exists(desktop))
                desktop = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            return SaveTo(folder, Path.Combine(desktop, $"Hordes of Azeroth logs {DateTime.Now:yyyy-MM-dd HH.mm}.zip"), "bug report");
        }

        public static string SaveTo(GameFolder folder, string zip, string reason)
        {
            if (File.Exists(zip))
                File.Delete(zip);
            using (ZipArchive archive = ZipFile.Open(zip, ZipArchiveMode.Create))
            {
                AddText(archive, "about.txt", About(folder, reason));
                foreach (string file in Logs(folder.ServerLogs, "*.log"))
                    AddTail(archive, "server/" + Path.GetFileName(file), file);
                foreach (string file in Logs(folder.ServerLogs, "*.dmp").Where(dump => new FileInfo(dump).Length <= MaxBytesPerFile))
                    AddTail(archive, "server/" + Path.GetFileName(file), file);
                foreach (string file in Logs(folder.MariaDbData, "*.err"))
                    AddTail(archive, "server/mariadb/" + Path.GetFileName(file), file);
                foreach (string file in Logs(Path.Combine(folder.Root, "Logs"), "*.*"))
                    AddTail(archive, "client/" + Path.GetFileName(file), file);
                foreach (string file in NewestCrashFiles(folder))
                    AddTail(archive, "crashes/" + Path.GetFileName(file), file);
                string crashEvents = WindowsCrashEvents();
                if (!string.IsNullOrEmpty(crashEvents))
                    AddText(archive, "crashes/windows-events.txt", crashEvents);
                foreach (string file in Logs(folder.LauncherData, "*.txt"))
                    AddTail(archive, "launcher/" + Path.GetFileName(file), file);
                AddTail(archive, "client/config.toml", folder.ClientConfig);
            }
            return zip;
        }

        static IEnumerable<string> Logs(string directory, string pattern)
        {
            if (!Directory.Exists(directory))
                return Enumerable.Empty<string>();
            return Directory.GetFiles(directory, pattern)
                .Where(file => !SkippedLogs.Contains(Path.GetFileName(file), StringComparer.OrdinalIgnoreCase))
                .Where(file => new FileInfo(file).Length > 0);
        }

        static IEnumerable<string> NewestCrashFiles(GameFolder folder)
        {
            string errors = Path.Combine(folder.Root, "Errors");
            if (!Directory.Exists(errors))
                return Enumerable.Empty<string>();
            List<string> reports = Directory.GetFiles(errors, "*.txt")
                .OrderByDescending(File.GetLastWriteTimeUtc)
                .Take(NewestCrashes)
                .ToList();
            string newestDump = Path.ChangeExtension(reports.FirstOrDefault() ?? "", ".dmp");
            if (File.Exists(newestDump))
                reports.Add(newestDump);
            return reports;
        }

        static string WindowsCrashEvents()
        {
            if (!Platform.IsWindows)
                return null;
            string text;
            try
            {
                ProcessStartInfo info = new ProcessStartInfo("wevtutil",
                    "qe Application \"/q:*[System[Provider[@Name='Application Error'] and (EventID=1000)]]\" /c:200 /rd:true /f:text")
                {
                    UseShellExecute = false,
                    CreateNoWindow = true,
                    RedirectStandardOutput = true,
                };
                using (Process process = Process.Start(info))
                {
                    text = process.StandardOutput.ReadToEnd();
                    process.WaitForExit(10000);
                }
            }
            catch (Exception error) when (error is System.ComponentModel.Win32Exception || error is InvalidOperationException || error is IOException)
            {
                return null;
            }

            IEnumerable<string> events = System.Text.RegularExpressions.Regex.Split(text, @"(?m)^Event\[\d+\]")
                .Where(IsGameCrashEvent)
                .Take(NewestCrashEvents)
                .Select(PublicEventText);
            return HideUserNameInText(string.Join(Environment.NewLine, events));
        }

        static bool IsGameCrashEvent(string crashEvent) =>
            GamePrograms.Any(program => crashEvent.IndexOf("Faulting application name: " + program, StringComparison.OrdinalIgnoreCase) >= 0);

        static string PublicEventText(string crashEvent) =>
            string.Join(Environment.NewLine, crashEvent.Split('\n')
                .Select(line => line.TrimEnd('\r'))
                .Where(line => !PrivateEventLines.Any(hidden => line.TrimStart().StartsWith(hidden, StringComparison.Ordinal))));

        static string About(GameFolder folder, string reason)
        {
            StringBuilder text = new StringBuilder();
            text.AppendLine($"Sent for: {reason}");
            text.AppendLine($"Launcher: {typeof(LogBundle).Assembly.GetName().Version}");
            text.AppendLine($"Installed: {folder.InstalledVersion?.ToString() ?? "unknown"}");
            text.AppendLine($"{Platform.SystemName}: {Environment.OSVersion.VersionString}, {(Environment.Is64BitOperatingSystem ? "64" : "32")}-bit");
            text.AppendLine($"Processors: {Environment.ProcessorCount}");
            text.AppendLine($"Game folder: {HideUserName(folder.Root)}");
            text.AppendLine($"Saved: {DateTime.Now:yyyy-MM-dd HH:mm:ss zzz}");
            return text.ToString();
        }

        static string HideUserName(string path)
        {
            string profile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            return profile.Length > 0 && path.StartsWith(profile, StringComparison.OrdinalIgnoreCase)
                ? (Platform.IsWindows ? "%USERPROFILE%" : "~") + path.Substring(profile.Length)
                : path;
        }

        static string HideUserNameInText(string text)
        {
            string profile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            return profile.Length > 0
                ? System.Text.RegularExpressions.Regex.Replace(text, System.Text.RegularExpressions.Regex.Escape(profile), "%USERPROFILE%",
                    System.Text.RegularExpressions.RegexOptions.IgnoreCase)
                : text;
        }

        static void AddText(ZipArchive archive, string name, string text)
        {
            using (StreamWriter writer = new StreamWriter(archive.CreateEntry(name).Open(), new UTF8Encoding(false)))
                writer.Write(text);
        }

        static void AddTail(ZipArchive archive, string name, string file)
        {
            if (!File.Exists(file))
                return;
            try
            {
                using (FileStream source = new FileStream(file, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
                using (Stream target = archive.CreateEntry(name).Open())
                {
                    if (source.Length > MaxBytesPerFile)
                        source.Seek(-MaxBytesPerFile, SeekOrigin.End);
                    source.CopyTo(target);
                }
            }
            catch (IOException)
            {
            }
            catch (UnauthorizedAccessException)
            {
            }
        }
    }
}

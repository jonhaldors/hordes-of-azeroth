using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace HordesOfAzeroth.Launcher
{
    static class CrashReports
    {
        const string LauncherCrashFile = "Launcher crash.txt";
        const string ServerCrashFile = "Crash.log";
        const long MaxLauncherCrashBytes = 256 * 1024;
        static readonly string[] VulkanDriverModules = { "amdvlk64.dll", "amdvlk32.dll", "nvoglv64.dll", "nvoglv32.dll", "igvk64.dll", "igvk32.dll", "vulkan-1.dll" };

        public static void RecordLauncherCrash(Exception error)
        {
            try
            {
                GameFolder folder = GameFolder.Find();
                Directory.CreateDirectory(folder.LauncherData);
                string file = Path.Combine(folder.LauncherData, LauncherCrashFile);
                if (File.Exists(file) && new FileInfo(file).Length > MaxLauncherCrashBytes)
                    File.Delete(file);
                File.AppendAllText(file, $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] {error}{Environment.NewLine}{Environment.NewLine}", new UTF8Encoding(false));
            }
            catch (Exception)
            {
            }
        }

        public static List<string> CrashedSince(GameFolder folder, DateTime sinceUtc)
        {
            List<string> crashed = new List<string>();
            if (NewerFiles(Path.Combine(folder.Root, "Errors"), "*.txt", sinceUtc))
                crashed.Add("the game");
            if (NewerFiles(folder.ServerLogs, ServerCrashFile, sinceUtc) || NewerFiles(folder.ServerLogs, "*.dmp", sinceUtc))
                crashed.Add("the game's server");
            if (NewerFiles(folder.LauncherData, LauncherCrashFile, sinceUtc))
                crashed.Add("the launcher");
            return crashed;
        }

        public static async Task<string> SendAsync(GameFolder folder, IEnumerable<string> crashed)
        {
            Directory.CreateDirectory(folder.LauncherData);
            string zip = Path.Combine(folder.LauncherData, "crash-report.zip");
            try
            {
                await Task.Run(() => LogBundle.SaveTo(folder, zip, "crash: " + string.Join(", ", crashed)));
                return await RunUpload.SendReportAsync(zip);
            }
            finally
            {
                if (File.Exists(zip))
                    File.Delete(zip);
            }
        }

        public static bool GameCrashedInVulkanDriver(GameFolder folder, DateTime sinceUtc)
        {
            if (!Platform.IsWindows)
                return false;
            string since = sinceUtc.ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:ss'.000Z'");
            string text;
            try
            {
                ProcessStartInfo info = new ProcessStartInfo("wevtutil",
                    $"qe Application \"/q:*[System[Provider[@Name='Application Error'] and (EventID=1000) and TimeCreated[@SystemTime>='{since}']]]\" /c:20 /rd:true /f:text")
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
                return false;
            }
            return Regex.Split(text, @"(?m)^Event\[\d+\]").Any(crashEvent =>
                crashEvent.IndexOf("Faulting application name: " + folder.GameExeName, StringComparison.OrdinalIgnoreCase) >= 0 &&
                VulkanDriverModules.Any(module => crashEvent.IndexOf("Faulting module name: " + module, StringComparison.OrdinalIgnoreCase) >= 0));
        }

        static bool NewerFiles(string directory, string pattern, DateTime sinceUtc) =>
            Directory.Exists(directory) && Directory.GetFiles(directory, pattern).Any(file => File.GetLastWriteTimeUtc(file) > sinceUtc);
    }
}

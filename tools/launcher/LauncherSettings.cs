using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace HordesOfAzeroth.Launcher
{
    enum CoreShare { All, Half }

    sealed class LauncherSettings
    {
        readonly string m_path;

        public bool KeepInTray = true;
        public bool BuildWhilePlaying = true;
        public bool BuildSpeedChosen;
        public CoreShare InstallCores = CoreShare.All;
        public CoreShare BackgroundCores = CoreShare.Half;
        public bool SendRunData = true;
        public bool RunDataAsked;
        public bool AskToSendCrashes = true;
        public long CrashCheckedAt;
        public string InstallId = Guid.NewGuid().ToString("N");
        public long RunLogOffset;

        public static int Workers(CoreShare share) => share == CoreShare.All ? Environment.ProcessorCount : HalfOfCores;

        public static int HalfOfCores => Math.Max(1, Environment.ProcessorCount / 2);

        LauncherSettings(string path)
        {
            m_path = path;
        }

        public static LauncherSettings Load(GameFolder folder)
        {
            LauncherSettings settings = new LauncherSettings(Path.Combine(folder.LauncherData, "launcher.ini"));
            if (!File.Exists(settings.m_path))
                return settings;
            Dictionary<string, string> values = File.ReadAllLines(settings.m_path)
                .Select(l => l.Split(new[] { '=' }, 2))
                .Where(p => p.Length == 2)
                .ToDictionary(p => p[0].Trim(), p => p[1].Trim(), StringComparer.OrdinalIgnoreCase);
            if (values.TryGetValue("KeepInTray", out string tray))
                settings.KeepInTray = tray != "0";
            if (values.TryGetValue("BuildWhilePlaying", out string build))
                settings.BuildWhilePlaying = build != "0";
            if (values.TryGetValue("BuildSpeedChosen", out string chosen))
                settings.BuildSpeedChosen = chosen == "1";
            if (values.TryGetValue("InstallCores", out string install) && Enum.TryParse(install, true, out CoreShare installShare))
                settings.InstallCores = installShare;
            if (values.TryGetValue("BackgroundCores", out string background) && Enum.TryParse(background, true, out CoreShare backgroundShare))
                settings.BackgroundCores = backgroundShare;
            if (values.TryGetValue("SendRunData", out string send))
                settings.SendRunData = send != "0";
            if (values.TryGetValue("RunDataAsked", out string asked))
                settings.RunDataAsked = asked == "1";
            if (values.TryGetValue("AskToSendCrashes", out string crashes))
                settings.AskToSendCrashes = crashes != "0";
            if (values.TryGetValue("CrashCheckedAt", out string checkedAt) && long.TryParse(checkedAt, out long crashCheckedAt))
                settings.CrashCheckedAt = crashCheckedAt;
            if (values.TryGetValue("InstallId", out string id) && id.Length > 0)
                settings.InstallId = id;
            if (values.TryGetValue("RunLogOffset", out string offset) && long.TryParse(offset, out long runLogOffset))
                settings.RunLogOffset = runLogOffset;
            return settings;
        }

        public void Save()
        {
            Directory.CreateDirectory(Path.GetDirectoryName(m_path));
            File.WriteAllLines(m_path, new[]
            {
                "KeepInTray=" + (KeepInTray ? "1" : "0"),
                "BuildWhilePlaying=" + (BuildWhilePlaying ? "1" : "0"),
                "BuildSpeedChosen=" + (BuildSpeedChosen ? "1" : "0"),
                "InstallCores=" + InstallCores,
                "BackgroundCores=" + BackgroundCores,
                "SendRunData=" + (SendRunData ? "1" : "0"),
                "RunDataAsked=" + (RunDataAsked ? "1" : "0"),
                "AskToSendCrashes=" + (AskToSendCrashes ? "1" : "0"),
                "CrashCheckedAt=" + CrashCheckedAt,
                "InstallId=" + InstallId,
                "RunLogOffset=" + RunLogOffset,
            });
        }
    }
}

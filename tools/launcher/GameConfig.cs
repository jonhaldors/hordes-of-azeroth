using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace HordesOfAzeroth.Launcher
{
    static class GameConfig
    {
        const string CvarSection = "[cvars]";
        static readonly Regex OldSetting = new Regex(@"^\s*SET\s+(\w+)\s+""([^""]*)""", RegexOptions.IgnoreCase);
        static readonly Regex Setting = new Regex(@"^\s*(\w+)\s*=\s*""((?:[^""\\]|\\.)*)""");
        static readonly Regex Section = new Regex(@"^\s*\[");

        const string LanguageSetting = "hoaLanguage";
        const string DefaultLanguage = "enUS";

        public static readonly (string Code, string Name)[] Languages =
        {
            ("enUS", "English"),
            ("zhCN", "简体中文"),
        };

        static readonly string[] CarriedOver =
        {
            "MasterVolume", "SoundVolume", "MusicVolume", "AmbienceVolume", "EnableSound", "EnableMusic", "EnableAmbience",
            "gamma", "cameraDistanceMaxFactor", "cameraSmoothStyle", "UnitNameNPC",
        };

        public static void EnsureDefaults(GameFolder folder, string realmName)
        {
            bool fresh = !File.Exists(folder.ClientConfig);
            if (fresh)
                CarryOverOldSettings(folder);
            Dictionary<string, string> values = Read(folder);
            Dictionary<string, string> missing = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            Dictionary<string, string> required = new Dictionary<string, string>
            {
                ["readEULA"] = "1",
                ["readTOS"] = "1",
                ["realmName"] = realmName,
                ["accountName"] = "player",
                ["movie"] = "0",
                ["showTutorials"] = "0",
            };
            Dictionary<string, string> firstRun = new Dictionary<string, string>
            {
                ["MasterVolume"] = "0.2",
                ["cameraDistanceMaxFactor"] = "2",
                ["UnitNameNPC"] = "1",
                ["cameraSmoothStyle"] = "0",
            };
            foreach (KeyValuePair<string, string> setting in fresh ? required.Concat(firstRun) : required)
                if (!values.ContainsKey(setting.Key))
                    missing[setting.Key] = setting.Value;
            if (!values.TryGetValue("realmList", out string realmList) || realmList != "127.0.0.1")
                missing["realmList"] = "127.0.0.1";
            if (missing.Count > 0)
                Write(folder, missing);
        }

        public static string ReadLanguage(GameFolder folder)
        {
            string code = Read(folder).TryGetValue(LanguageSetting, out string value) ? value : DefaultLanguage;
            return Languages.Any(language => language.Code == code) ? code : DefaultLanguage;
        }

        public static void WriteLanguage(GameFolder folder, string code) =>
            Write(folder, new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase) { [LanguageSetting] = code });

        public static string LanguageName(string code) =>
            Languages.FirstOrDefault(language => language.Code == code).Name ?? Languages[0].Name;

        static void CarryOverOldSettings(GameFolder folder)
        {
            if (!File.Exists(folder.ConfigWtf))
                return;
            Dictionary<string, string> old = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (string line in File.ReadAllLines(folder.ConfigWtf))
            {
                Match match = OldSetting.Match(line);
                if (match.Success)
                    old[match.Groups[1].Value] = match.Groups[2].Value;
            }
            Dictionary<string, string> carried = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (string name in CarriedOver)
                if (old.TryGetValue(name, out string value))
                    carried[name] = value;
            if (carried.Count > 0)
                Write(folder, carried);
        }

        static Dictionary<string, string> Read(GameFolder folder)
        {
            Dictionary<string, string> values = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            if (!File.Exists(folder.ClientConfig))
                return values;
            bool inCvars = false;
            foreach (string line in File.ReadAllLines(folder.ClientConfig))
            {
                if (Section.IsMatch(line))
                {
                    inCvars = line.Trim() == CvarSection;
                    continue;
                }
                Match match = Setting.Match(line);
                if (inCvars && match.Success)
                    values[match.Groups[1].Value] = Unescape(match.Groups[2].Value);
            }
            return values;
        }

        static void Write(GameFolder folder, Dictionary<string, string> changes)
        {
            Directory.CreateDirectory(folder.ClientState);
            List<string> lines = File.Exists(folder.ClientConfig) ? File.ReadAllLines(folder.ClientConfig).ToList() : new List<string>();
            int sectionAt = lines.FindIndex(line => line.Trim() == CvarSection);
            if (sectionAt < 0)
            {
                lines.Add(CvarSection);
                sectionAt = lines.Count - 1;
            }
            int sectionEnd = lines.FindIndex(sectionAt + 1, line => Section.IsMatch(line));
            if (sectionEnd < 0)
                sectionEnd = lines.Count;
            HashSet<string> done = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            for (int i = sectionAt + 1; i < sectionEnd; i++)
            {
                Match match = Setting.Match(lines[i]);
                if (match.Success && changes.TryGetValue(match.Groups[1].Value, out string value))
                {
                    lines[i] = Line(match.Groups[1].Value, value);
                    done.Add(match.Groups[1].Value);
                }
            }
            List<string> added = changes.Where(change => !done.Contains(change.Key)).Select(change => Line(change.Key, change.Value)).ToList();
            lines.InsertRange(sectionEnd, added);
            File.WriteAllLines(folder.ClientConfig, lines, new UTF8Encoding(false));
        }

        static string Line(string name, string value) => $"{name} = \"{value.Replace("\\", "\\\\").Replace("\"", "\\\"")}\"";

        static string Unescape(string value) => Regex.Replace(value, @"\\(.)", "$1");
    }
}

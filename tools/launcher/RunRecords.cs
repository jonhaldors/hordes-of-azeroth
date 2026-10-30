using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;

namespace HordesOfAzeroth.Launcher
{
    static class RunRecords
    {
        public const int FormatVersion = 1;
        const int MaxOutboxFiles = 100;
        const double MinRunMinutes = 1.0;
        static readonly TimeSpan AbandonedAfter = TimeSpan.FromHours(6);
        const string TimestampFormat = "yyyy-MM-dd HH:mm:ss";
        static readonly Regex BonkLine = new Regex(@"^(\S+ \S+) \[LevelUp\] \(acc (\d+), .*?guid (\d+), name ([^,]+),.*?\) Bonk (\w+): (.*)$");
        static readonly Regex EndMinute = new Regex(@" at run minute ([\d.]+) ");
        static readonly Regex RunClass = new Regex(@", class (\d+)\)");

        sealed class OpenRun
        {
            public long StartOffset;
            public DateTime Started;
            public string Name;
            public uint Character;
            public int LastSecond;
            public readonly List<string> Lines = new List<string>();
        }

        public static string Outbox(GameFolder folder) => Path.Combine(folder.LauncherData, "run-outbox");

        public static string LevelUpLog(GameFolder folder) => Path.Combine(folder.ServerLogs, "LevelUp.log");

        public static long SkipTo(GameFolder folder)
        {
            string log = LevelUpLog(folder);
            return File.Exists(log) ? new FileInfo(log).Length : 0;
        }

        public static long Collect(GameFolder folder, LauncherSettings settings, long offset)
        {
            string log = LevelUpLog(folder);
            if (!File.Exists(log))
                return 0;
            byte[] tail;
            using (FileStream stream = new FileStream(log, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
            {
                if (stream.Length < offset)
                    offset = 0;
                stream.Seek(offset, SeekOrigin.Begin);
                tail = new byte[stream.Length - offset];
                int read = 0;
                while (read < tail.Length)
                {
                    int got = stream.Read(tail, read, tail.Length - read);
                    if (got == 0)
                        break;
                    read += got;
                }
                if (read < tail.Length)
                    Array.Resize(ref tail, read);
            }

            Dictionary<uint, OpenRun> open = new Dictionary<uint, OpenRun>();
            int lineStart = 0;
            for (int i = 0; i < tail.Length; ++i)
            {
                if (tail[i] != '\n')
                    continue;
                string line = Encoding.UTF8.GetString(tail, lineStart, i - lineStart).TrimEnd('\r');
                ReadLine(folder, settings, open, line, offset + lineStart);
                lineStart = i + 1;
            }
            long consumed = offset + lineStart;
            foreach (OpenRun abandoned in open.Values.Where(run => DateTime.Now - run.Started >= AbandonedAfter))
                SaveInterrupted(folder, settings, abandoned);
            List<OpenRun> unfinished = open.Values.Where(run => DateTime.Now - run.Started < AbandonedAfter).ToList();
            return unfinished.Count == 0 ? consumed : Math.Min(consumed, unfinished.Min(run => run.StartOffset));
        }

        static void ReadLine(GameFolder folder, LauncherSettings settings, Dictionary<uint, OpenRun> open, string line, long lineOffset)
        {
            Match match = BonkLine.Match(line);
            if (!match.Success)
                return;
            if (!DateTime.TryParseExact(match.Groups[1].Value, TimestampFormat, CultureInfo.InvariantCulture, DateTimeStyles.None, out DateTime stamp))
                return;
            uint character = uint.Parse(match.Groups[3].Value, CultureInfo.InvariantCulture);
            string name = match.Groups[4].Value;
            string kind = match.Groups[5].Value;
            string body = match.Groups[6].Value;

            if (kind == "loadout")
            {
                if (open.TryGetValue(character, out OpenRun interrupted))
                    SaveInterrupted(folder, settings, interrupted);
                open[character] = new OpenRun { StartOffset = lineOffset, Started = stamp, Name = name, Character = character };
            }
            if (!open.TryGetValue(character, out OpenRun run))
                return;
            int seconds = (int)(stamp - run.Started).TotalSeconds;
            run.LastSecond = seconds;
            run.Lines.Add(seconds.ToString(CultureInfo.InvariantCulture) + " " + kind + ": " + Anonymize(body, run.Name));
            if (kind != "end")
                return;
            open.Remove(character);
            if (RunMinutes(body) >= MinRunMinutes)
                Save(folder, settings, run, body, true);
        }

        static void SaveInterrupted(GameFolder folder, LauncherSettings settings, OpenRun run)
        {
            if (run.LastSecond >= MinRunMinutes * 60 && run.Lines.Count > 0)
                Save(folder, settings, run, run.Lines[0], false);
        }

        static string Anonymize(string body, string name) => body.StartsWith(name + " ", StringComparison.Ordinal) ? "hero" + body.Substring(name.Length) : body;

        static double RunMinutes(string endBody)
        {
            Match match = EndMinute.Match(endBody);
            return match.Success && double.TryParse(match.Groups[1].Value, NumberStyles.Float, CultureInfo.InvariantCulture, out double minutes) ? minutes : 0;
        }

        static void Save(GameFolder folder, LauncherSettings settings, OpenRun run, string endBody, bool finished)
        {
            Match classMatch = RunClass.Match(endBody);
            string outbox = Outbox(folder);
            Directory.CreateDirectory(outbox);
            string file = Path.Combine(outbox, $"{run.Started:yyyyMMdd-HHmmss}-{run.Character}.json.gz");
            if (File.Exists(file))
                return;
            using (FileStream output = File.Create(file))
            using (GZipStream gzip = new GZipStream(output, CompressionLevel.SmallestSize))
            using (Utf8JsonWriter json = new Utf8JsonWriter(gzip))
            {
                json.WriteStartObject();
                json.WriteNumber("format", FormatVersion);
                json.WriteString("install", settings.InstallId);
                json.WriteString("game", folder.InstalledVersion?.Full ?? "");
                json.WriteString("launcher", typeof(RunRecords).Assembly.GetName().Version?.ToString() ?? "");
                json.WriteString("os", Platform.SystemName);
                json.WriteString("started", run.Started.ToString("yyyy-MM-dd HH:mm", CultureInfo.InvariantCulture));
                json.WriteNumber("character", run.Character);
                json.WriteBoolean("finished", finished);
                json.WriteNumber("class", classMatch.Success ? int.Parse(classMatch.Groups[1].Value, CultureInfo.InvariantCulture) : 0);
                json.WriteStartArray("lines");
                foreach (string line in run.Lines)
                    json.WriteStringValue(line);
                json.WriteEndArray();
                json.WriteEndObject();
            }
            TrimOutbox(outbox);
        }

        static void TrimOutbox(string outbox)
        {
            foreach (string old in Pending(outbox).Skip(MaxOutboxFiles).ToList())
                File.Delete(old);
        }

        public static IEnumerable<string> Pending(string outbox)
        {
            if (!Directory.Exists(outbox))
                return Enumerable.Empty<string>();
            return Directory.GetFiles(outbox, "*.json.gz").OrderByDescending(Path.GetFileName, StringComparer.Ordinal);
        }
    }
}

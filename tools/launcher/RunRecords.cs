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
        const long MaxCollectBytes = 64L * 1024 * 1024;
        static readonly TimeSpan AbandonedAfter = TimeSpan.FromHours(6);
        const string TimestampFormat = "yyyy-MM-dd HH:mm:ss";
        static readonly Regex BonkLine = new Regex(@"^(\S+ \S+) \[LevelUp\] \(acc (\d+), .*?guid (\d+), name ([^,]+),.*?\) Bonk (\w+): (.*)$");
        static readonly Regex EndMinute = new Regex(@" at run minute ([\d.]+) ");
        static readonly Regex RunClass = new Regex(@", class (\d+)\)");
        static readonly Regex BoardChoice = new Regex(@", board (-?\d+), gear ");
        static readonly Regex Clear = new Regex(@"clears level (\d+) at run minute [\d.]+ in (\d+) ms \(.*class (\d+)\): coop (\d+), gm (\d+), board (-?\d+), gear (\d+)(?:, party (\S+))?$");
        const int FirstMythicLevel = 10;
        const int MinClearMs = 3 * 60 * 1000;
        const int MaxSentKeys = 5000;

        sealed class OpenRun
        {
            public long StartOffset;
            public DateTime Started;
            public string Name;
            public uint Character;
            public int LastSecond;
            public readonly List<string> Lines = new List<string>();
            public int SoloClass;
            public BoardScore Solo;
            public int GroupSize;
            public BoardScore Group;
        }

        static string SentPath(GameFolder folder) => Path.Combine(folder.LauncherData, "run-sent.txt");

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
                if (stream.Length - offset > MaxCollectBytes)
                    offset = stream.Length - MaxCollectBytes;
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
            if (kind == "clear")
                NoteClear(folder, run, body);
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

        static void NoteClear(GameFolder folder, OpenRun run, string body)
        {
            Match match = Clear.Match(body);
            if (!match.Success)
                return;
            int level = int.Parse(match.Groups[1].Value, CultureInfo.InvariantCulture);
            int ms = int.Parse(match.Groups[2].Value, CultureInfo.InvariantCulture);
            int classId = int.Parse(match.Groups[3].Value, CultureInfo.InvariantCulture);
            if (level < FirstMythicLevel || ms < MinClearMs || match.Groups[5].Value != "0" || match.Groups[7].Value != "1")
                return;
            BoardScore score = new BoardScore { Level = level, Ms = ms };
            string date = run.Started.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
            if (match.Groups[4].Value == "0")
            {
                if (score.Beats(run.Solo))
                {
                    run.Solo = score;
                    run.SoloClass = classId;
                }
                Leaderboard.NoteLocalBest(folder, "solo:" + run.Character, $"local~solo~{classId}~{run.Name}~{level}~{ms}~{date}", 4, 5);
                return;
            }
            List<string[]> members = match.Groups[8].Value.Split(';').Select(piece => piece.Split(':')).Where(parts => parts.Length == 6).ToList();
            if (members.Count < 2)
                return;
            if (score.Beats(run.Group))
            {
                run.Group = score;
                run.GroupSize = members.Count;
            }
            string key = "group:" + members.Count + ":" + string.Join(",", members.Select(parts => parts[0]).OrderBy(guid => guid, StringComparer.Ordinal));
            string names = string.Join(",", members.Select(parts => parts[1] + ":" + parts[2]));
            Leaderboard.NoteLocalBest(folder, key, $"local~group~{members.Count}~{level}~{ms}~{date}~{names}", 3, 4);
        }

        static bool WasSent(GameFolder folder, string key) => File.Exists(SentPath(folder)) && File.ReadLines(SentPath(folder)).Contains(key);

        static void NoteSent(GameFolder folder, string key)
        {
            string path = SentPath(folder);
            List<string> keys = File.Exists(path) ? File.ReadAllLines(path).ToList() : new List<string>();
            keys.Add(key);
            File.WriteAllLines(path, keys.Skip(Math.Max(0, keys.Count - MaxSentKeys)));
        }

        static bool Places(GameFolder folder, OpenRun run)
        {
            if (run.Solo == null && run.Group == null)
                return false;
            BoardCutoffs cutoffs = Leaderboard.Cutoffs(folder);
            return (run.Solo != null && cutoffs.SoloPlaces(run.SoloClass, run.Solo)) || (run.Group != null && cutoffs.GroupPlaces(run.GroupSize, run.Group));
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
            int board = ReadBoardChoice(run);
            bool places = Places(folder, run);
            if (!settings.SendRunData && !places)
                return;
            string key = $"{run.Started:yyyyMMdd-HHmmss}-{run.Character}";
            string file = Path.Combine(outbox, key + ".json.gz");
            if (File.Exists(file) || WasSent(folder, key))
                return;
            NoteSent(folder, key);
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
                if (places && (board == 1 || (board < 0 && settings.ShowOnLeaderboard)))
                    json.WriteString("name", run.Name);
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

        static int ReadBoardChoice(OpenRun run)
        {
            int board = -1;
            foreach (string line in run.Lines)
            {
                Match match = BoardChoice.Match(line);
                if (match.Success)
                    board = int.Parse(match.Groups[1].Value, CultureInfo.InvariantCulture);
            }
            return board;
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

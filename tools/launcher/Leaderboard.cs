using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;

namespace HordesOfAzeroth.Launcher
{
    sealed class BoardScore
    {
        public int Level;
        public int Ms;

        public bool Beats(BoardScore other) => other == null || Level > other.Level || (Level == other.Level && Ms < other.Ms);
    }

    sealed class BoardCutoffs
    {
        public readonly Dictionary<int, BoardScore> Solo = new Dictionary<int, BoardScore>();
        public readonly Dictionary<int, BoardScore> Group = new Dictionary<int, BoardScore>();

        public bool SoloPlaces(int classId, BoardScore score) => !Solo.TryGetValue(classId, out BoardScore cutoff) || score.Beats(cutoff);

        public bool GroupPlaces(int size, BoardScore score) => !Group.TryGetValue(size, out BoardScore cutoff) || score.Beats(cutoff);
    }

    static class Leaderboard
    {
        public const int MaxBytes = 2 * 1024 * 1024;
        const int MaxLocalBests = 200;
        const string SyncTimeFormat = "yyyy-MM-dd HH:mm";

        public static string File(GameFolder folder) => Path.Combine(folder.ServerRun, "leaderboard.txt");

        static string CachePath(GameFolder folder) => Path.Combine(folder.LauncherData, "board-cache.txt");

        static string LocalBestsPath(GameFolder folder) => Path.Combine(folder.LauncherData, "local-bests.txt");

        public static void SaveServerBoard(GameFolder folder, string text)
        {
            Directory.CreateDirectory(folder.LauncherData);
            WriteWhole(CachePath(folder), text);
        }

        static string ServerBoard(GameFolder folder)
        {
            string path = CachePath(folder);
            return System.IO.File.Exists(path) ? System.IO.File.ReadAllText(path) : "";
        }

        public static BoardCutoffs Cutoffs(GameFolder folder)
        {
            BoardCutoffs cutoffs = new BoardCutoffs();
            foreach (string line in ServerBoard(folder).Split('\n'))
            {
                string[] fields = line.Trim().Split('~');
                if (fields.Length != 5 || fields[0] != "cutoff" || !int.TryParse(fields[2], out int list) ||
                    !int.TryParse(fields[3], out int level) || !int.TryParse(fields[4], out int ms))
                    continue;
                BoardScore score = new BoardScore { Level = level, Ms = ms };
                if (fields[1] == "solo")
                    cutoffs.Solo[list] = score;
                else if (fields[1] == "group")
                    cutoffs.Group[list] = score;
            }
            return cutoffs;
        }

        static Dictionary<string, string> ReadLocalBests(GameFolder folder)
        {
            Dictionary<string, string> bests = new Dictionary<string, string>();
            string path = LocalBestsPath(folder);
            if (!System.IO.File.Exists(path))
                return bests;
            foreach (string line in System.IO.File.ReadAllLines(path))
            {
                int tab = line.IndexOf('\t');
                if (tab > 0)
                    bests[line.Substring(0, tab)] = line.Substring(tab + 1);
            }
            return bests;
        }

        static BoardScore ScoreOf(string boardLine, int levelField, int msField)
        {
            string[] fields = boardLine.Split('~');
            return fields.Length > msField && int.TryParse(fields[levelField], out int level) && int.TryParse(fields[msField], out int ms)
                ? new BoardScore { Level = level, Ms = ms }
                : null;
        }

        public static void NoteLocalBest(GameFolder folder, string key, string boardLine, int levelField, int msField)
        {
            Dictionary<string, string> bests = ReadLocalBests(folder);
            BoardScore score = ScoreOf(boardLine, levelField, msField);
            if (score == null || (bests.TryGetValue(key, out string old) && !score.Beats(ScoreOf(old, levelField, msField))))
                return;
            bests[key] = boardLine;
            Directory.CreateDirectory(folder.LauncherData);
            WriteWhole(LocalBestsPath(folder), string.Concat(bests.Take(MaxLocalBests).Select(pair => pair.Key + "\t" + pair.Value + "\n")));
        }

        public static void Write(GameFolder folder, LauncherSettings settings, bool reached, int pending)
        {
            StringBuilder text = new StringBuilder(ServerBoard(folder));
            if (text.Length > 0 && text[text.Length - 1] != '\n')
                text.Append('\n');
            foreach (string line in ReadLocalBests(folder).Values)
                text.Append(line).Append('\n');
            text.Append("sync~").Append(reached ? "ok" : "failed").Append('~').Append(SyncedText(settings.BoardSyncedAt)).Append('~').Append(pending).Append('\n');
            if (text.Length <= MaxBytes && Directory.Exists(folder.ServerRun))
                WriteWhole(File(folder), text.ToString());
        }

        public static string SyncStamp() => DateTime.Now.ToString(SyncTimeFormat, CultureInfo.InvariantCulture);

        static string SyncedText(string stamp)
        {
            if (!DateTime.TryParseExact(stamp, SyncTimeFormat, CultureInfo.InvariantCulture, DateTimeStyles.None, out DateTime synced))
                return "";
            return synced.ToString(synced.Date == DateTime.Today ? "HH:mm" : "MMM d HH:mm", CultureInfo.InvariantCulture);
        }

        static void WriteWhole(string path, string text)
        {
            System.IO.File.WriteAllText(path + ".tmp", text);
            System.IO.File.Move(path + ".tmp", path, true);
        }
    }
}

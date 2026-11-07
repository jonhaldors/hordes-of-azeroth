using System;
using System.IO;

namespace HordesOfAzeroth.Launcher
{
    static class ServerLogTrim
    {
        const long TrimAboveBytes = 32L * 1024 * 1024;
        const long KeepBytes = 8L * 1024 * 1024;

        public static long Trim(GameFolder folder, long runLogOffset)
        {
            if (!Directory.Exists(folder.ServerLogs))
                return runLogOffset;
            string runLog = RunRecords.LevelUpLog(folder);
            foreach (string log in Directory.GetFiles(folder.ServerLogs, "*.log"))
            {
                bool holdsRuns = string.Equals(Path.GetFullPath(log), Path.GetFullPath(runLog), StringComparison.OrdinalIgnoreCase);
                long removed = TrimFile(log, holdsRuns ? runLogOffset : long.MaxValue);
                if (holdsRuns)
                    runLogOffset = Math.Max(0, runLogOffset - removed);
            }
            return runLogOffset;
        }

        static long TrimFile(string path, long unreadFrom)
        {
            try
            {
                using FileStream stream = new FileStream(path, FileMode.Open, FileAccess.ReadWrite, FileShare.None);
                long length = stream.Length;
                if (length <= TrimAboveBytes)
                    return 0;
                bool keepUnread = unreadFrom < length - KeepBytes && length - unreadFrom <= TrimAboveBytes;
                long cut = keepUnread ? unreadFrom : length - KeepBytes;
                byte[] kept = new byte[length - cut];
                stream.Seek(cut, SeekOrigin.Begin);
                stream.ReadExactly(kept);
                int start = keepUnread ? 0 : Array.IndexOf(kept, (byte)'\n') + 1;
                stream.SetLength(0);
                stream.Write(kept, start, kept.Length - start);
                return cut + start;
            }
            catch (Exception e) when (e is IOException || e is UnauthorizedAccessException)
            {
                return 0;
            }
        }
    }
}

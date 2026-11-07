using System;
using System.IO;
using System.Text;

namespace HordesOfAzeroth.Launcher
{
    static class LauncherLog
    {
        const long MaxBytes = 1024 * 1024;
        const string FileName = "Launcher log.txt";

        public static void Write(GameFolder folder, string text)
        {
            try
            {
                Directory.CreateDirectory(folder.LauncherData);
                string file = Path.Combine(folder.LauncherData, FileName);
                if (File.Exists(file) && new FileInfo(file).Length > MaxBytes)
                    File.Delete(file);
                File.AppendAllText(file, $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] {text.TrimEnd()}{Environment.NewLine}{Environment.NewLine}", new UTF8Encoding(false));
            }
            catch (Exception e) when (e is IOException || e is UnauthorizedAccessException)
            {
            }
        }
    }
}

using System.IO;

namespace HordesOfAzeroth.Launcher
{
    static class Leaderboard
    {
        public const int MaxBytes = 256 * 1024;

        public static string File(GameFolder folder) => Path.Combine(folder.ServerRun, "leaderboard.txt");
    }
}

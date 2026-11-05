using System;
using System.Diagnostics;
using System.IO;
using System.Linq;

namespace HordesOfAzeroth.Launcher
{
    static class ClientBuild
    {
        static readonly int[] Expected = { 1, 12, 1, 5875 };

        public static bool Is1_12_1(string exe)
        {
            if (!File.Exists(exe))
                return false;
            try
            {
                string text = FileVersionInfo.GetVersionInfo(exe).FileVersion ?? "";
                int[] parts = text
                    .Split(new[] { ',', '.', ' ' }, StringSplitOptions.RemoveEmptyEntries)
                    .Select(part => int.TryParse(part, out int number) ? number : -1)
                    .ToArray();
                if (parts.Length < Expected.Length)
                    return false;
                for (int i = 0; i < Expected.Length; i++)
                    if (parts[i] != Expected[i])
                        return false;
                return true;
            }
            catch (Exception)
            {
                return false;
            }
        }
    }
}

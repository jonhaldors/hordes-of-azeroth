using System;
using System.IO;
using System.IO.Compression;
using System.Runtime.InteropServices;

namespace HordesOfAzeroth.Launcher
{
    static class WineIcu
    {
        public static void EnsureAvailable(string mariaDb)
        {
            if (!IsWine() || (HasSystemLibrary("icuuc.dll") && HasSystemLibrary("icuin.dll")))
                return;

            string bin = Path.Combine(mariaDb, "bin");
            if (!Directory.Exists(bin))
                return;

            using Stream resource = typeof(WineIcu).Assembly.GetManifestResourceStream("WineIcu.zip");
            if (resource == null)
                return;

            using ZipArchive archive = new ZipArchive(resource);
            foreach (ZipArchiveEntry entry in archive.Entries)
                InstallIfMissing(entry, Path.Combine(bin, entry.Name));
        }

        static bool IsWine()
        {
            if (!Platform.IsWindows || !NativeLibrary.TryLoad("ntdll.dll", out IntPtr module))
                return false;

            try { return NativeLibrary.TryGetExport(module, "wine_get_version", out _); }
            finally { NativeLibrary.Free(module); }
        }

        static bool HasSystemLibrary(string name)
        {
            if (!NativeLibrary.TryLoad(Path.Combine(Environment.SystemDirectory, name), out IntPtr module))
                return false;

            NativeLibrary.Free(module);
            return true;
        }

        static void InstallIfMissing(ZipArchiveEntry entry, string target)
        {
            if (File.Exists(target))
                return;

            string temporary = target + "." + Guid.NewGuid().ToString("N") + ".tmp";
            try
            {
                entry.ExtractToFile(temporary);
                File.Move(temporary, target);
            }
            catch (IOException) when (File.Exists(target))
            {
            }
            finally
            {
                File.Delete(temporary);
            }
        }
    }
}

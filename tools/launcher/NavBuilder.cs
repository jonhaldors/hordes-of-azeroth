using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace HordesOfAzeroth.Launcher
{
    sealed class NavProgress
    {
        public string Group;
        public int Done;
        public int Total;
        public bool Downloading;
    }

    sealed class NavBuilder
    {
        readonly GameFolder m_folder;

        public NavBuilder(GameFolder folder)
        {
            m_folder = folder;
        }

        public Func<bool> Paused = () => false;
        public ProcessPriorityClass Priority = ProcessPriorityClass.Normal;
        public Func<int> Workers = () => Environment.ProcessorCount;

        readonly object m_recordLock = new object();
        HashSet<string> m_built;

        string RecordFile => Path.Combine(m_folder.LauncherData, "navtiles-built.txt");
        string DataDir => Path.Combine(m_folder.Server, "data");
        string MmapsDir => Path.Combine(DataDir, "mmaps");
        string Extractors => Path.Combine(m_folder.ServerRun, "Extractors");

        public bool IsGroupBuilt(NavGroup group) => Missing(group).Count == 0 && MissingWholeMaps(group).Count == 0;

        public async Task BuildGroupAsync(NavGroup group, IProgress<NavProgress> progress, CancellationToken cancel)
        {
            Directory.CreateDirectory(MmapsDir);
            List<string> wholeMaps = MissingWholeMaps(group);
            List<KeyValuePair<string, string>> tiles = Missing(group);
            int total = group.Tiles.Count + group.WholeMaps.Count;
            int done = total - tiles.Count - wholeMaps.Count;
            progress.Report(new NavProgress { Group = group.Name, Done = done, Total = total });

            foreach (string map in wholeMaps)
            {
                await WaitWhilePausedAsync(cancel);
                await RunAsync(new[] { map, "--threads", Workers().ToString() }, cancel);
                Record(map + ":all");
                progress.Report(new NavProgress { Group = group.Name, Done = ++done, Total = total });
            }

            List<Task> running = new List<Task>();
            foreach (KeyValuePair<string, string> tile in tiles)
            {
                await WaitWhilePausedAsync(cancel);
                while (running.Count >= Workers())
                {
                    Task finished = await Task.WhenAny(running);
                    running.Remove(finished);
                    await finished;
                }
                running.Add(RunAsync(new[] { tile.Key, "--tile", tile.Value, "--threads", "1" }, cancel)
                    .ContinueWith(t =>
                    {
                        t.GetAwaiter().GetResult();
                        Record(tile.Key + ":" + tile.Value);
                        progress.Report(new NavProgress { Group = group.Name, Done = Interlocked.Increment(ref done), Total = total });
                    }, cancel, TaskContinuationOptions.None, TaskScheduler.Default));
            }
            await Task.WhenAll(running);
        }

        public void InstallDownloaded(NavGroup group, string zip)
        {
            Directory.CreateDirectory(MmapsDir);
            using (ZipArchive archive = ZipFile.OpenRead(zip))
                foreach (ZipArchiveEntry entry in archive.Entries)
                {
                    if (entry.FullName != Path.GetFileName(entry.FullName))
                        throw new InvalidDataException(Loc.T("{0} contains a file outside the monster path folder.", Path.GetFileName(zip)));
                    entry.ExtractToFile(Path.Combine(MmapsDir, entry.FullName), true);
                }
            foreach (string map in group.WholeMaps)
                Record(map + ":all");
            foreach (KeyValuePair<string, string> tile in group.Tiles)
                Record(tile.Key + ":" + tile.Value);
        }

        async Task WaitWhilePausedAsync(CancellationToken cancel)
        {
            while (Paused())
                await Task.Delay(2000, cancel);
        }

        List<KeyValuePair<string, string>> Missing(NavGroup group)
        {
            return group.Tiles.Where(t => !IsBuilt(t.Key + ":" + t.Value) && !File.Exists(Path.Combine(MmapsDir, TileFile(t.Key, t.Value)))).ToList();
        }

        List<string> MissingWholeMaps(NavGroup group)
        {
            return group.WholeMaps.Where(m => !IsBuilt(m + ":all")).ToList();
        }

        bool IsBuilt(string key)
        {
            lock (m_recordLock)
            {
                if (m_built == null)
                    m_built = new HashSet<string>(File.Exists(RecordFile) ? File.ReadAllLines(RecordFile) : new string[0]);
                return m_built.Contains(key);
            }
        }

        void Record(string key)
        {
            lock (m_recordLock)
            {
                IsBuilt(key);
                if (m_built.Add(key))
                {
                    Directory.CreateDirectory(m_folder.LauncherData);
                    File.AppendAllLines(RecordFile, new[] { key });
                }
            }
        }

        static string TileFile(string map, string tile)
        {
            string[] xy = tile.Split(',');
            return $"{int.Parse(map):D3}{int.Parse(xy[1]):D2}{int.Parse(xy[0]):D2}.mmtile";
        }

        async Task RunAsync(string[] arguments, CancellationToken cancel)
        {
            string[] options =
            {
                "--silent",
                "--offMeshInput", Quote(Path.Combine(Extractors, "offmesh.txt")),
                "--configInputPath", Quote(Path.Combine(Extractors, "config.json")),
            };
            ProcessStartInfo info = new ProcessStartInfo(Path.Combine(Extractors, Platform.Exe("MoveMapGenerator")), string.Join(" ", arguments.Concat(options)))
            {
                WorkingDirectory = DataDir,
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardInput = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
            };
            using (Process process = Process.Start(info))
            {
                process.OutputDataReceived += (s, e) => { };
                process.ErrorDataReceived += (s, e) => { };
                process.BeginOutputReadLine();
                process.BeginErrorReadLine();
                process.StandardInput.Close();
                try
                {
                    process.PriorityClass = Priority;
                }
                catch (InvalidOperationException)
                {
                }
                using (cancel.Register(() => { try { process.Kill(); } catch (InvalidOperationException) { } }))
                    while (!process.HasExited)
                        await Task.Delay(200);
                cancel.ThrowIfCancellationRequested();
                if (process.ExitCode != 0)
                    throw new InvalidOperationException(Loc.T("Building monster paths failed (MoveMapGenerator {0}, code {1}).", string.Join(" ", arguments), process.ExitCode));
            }
        }

        static string Quote(string text) => "\"" + text + "\"";
    }
}

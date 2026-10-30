using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Net.Http;
using BonkTelegraphs;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace HordesOfAzeroth.Launcher
{
    sealed class InstallProgress
    {
        public string Step;
        public string Detail;
        public double Fraction = -1;
        public bool Fixing;
    }

    sealed class FixTracker : IProgress<InstallProgress>
    {
        readonly IProgress<InstallProgress> m_progress;

        public FixTracker(IProgress<InstallProgress> progress)
        {
            m_progress = progress;
        }

        public bool FixedSomething { get; private set; }

        public void Report(InstallProgress value)
        {
            FixedSomething |= value.Fixing;
            m_progress.Report(value);
        }
    }

    sealed class Installer
    {
        public const string StockClientMd5 = "CCF83146DBB3D10EF826AA4DE178A5BE";
        const string LauncherPackage = "launcher";
        const string WorldPackage = "world-db";
        const string SpellEffectsPackage = "telegraphkit";
        const string SpellEffectsApplied = "spell-effects";
        const string RetiredPatchApplied = "retired-patch";
        const string VersionEntry = "VERSION";

        static readonly string[] SpellEffectFiles =
        {
            Path.Combine("Interface", "AddOns", "HordesOfAzeroth", "Textures", "ClassCrests.tga"),
            Path.Combine("Interface", "AddOns", "HordesOfAzeroth", "Textures", "PlayerFrameNoPower.tga"),
        };

        static readonly Dictionary<string, string> MigrationDatabases = new Dictionary<string, string>
        {
            ["characters"] = "characters",
            ["logon"] = "realmd",
            ["logs"] = "logs",
        };

        public static readonly string[] Steps =
        {
            "Download the game files",
            "Set up the game",
            "Read the maps",
            "Build the spell effects",
            "Set up the database",
        };

        readonly GameFolder m_folder;
        readonly LocalServer m_server;

        public Installer(GameFolder folder, LocalServer server)
        {
            m_folder = folder;
            m_server = server;
        }

        string StateFile => Path.Combine(m_folder.LauncherData, "install-steps.txt");
        string PackagesFile => Path.Combine(m_folder.LauncherData, "packages.txt");
        string AppliedFile => Path.Combine(m_folder.LauncherData, "packages-applied.txt");
        string Downloads => Path.Combine(m_folder.LauncherData, "downloads");
        string DataDir => Path.Combine(m_folder.Server, "data");
        string SqlDir => Path.Combine(m_folder.Server, "sql");
        string WorldSql => Path.Combine(SqlDir, "world.sql");
        string PendingVersion => Path.Combine(m_folder.LauncherData, "VERSION.pending");

        void FinishVersion()
        {
            if (!File.Exists(PendingVersion))
                return;
            File.Copy(PendingVersion, m_folder.VersionFile, true);
            File.Delete(PendingVersion);
        }

        public HashSet<string> CompletedSteps =>
            new HashSet<string>((File.Exists(StateFile) ? File.ReadAllLines(StateFile) : new string[0]).Select(CurrentStepName));

        static readonly Dictionary<string, string> RenamedSteps = new Dictionary<string, string>
        {
            { "Patch the game", "Set up the game" },
        };

        static string CurrentStepName(string step) => RenamedSteps.TryGetValue(step, out string renamed) ? renamed : step;

        public bool IsComplete => Steps.All(CompletedSteps.Contains);

        public static bool IsStockClient(GameFolder folder)
        {
            string exe = folder.WowExe;
            if (!File.Exists(exe))
                return false;
            using (MD5 md5 = MD5.Create())
            using (FileStream stream = File.OpenRead(exe))
                return BitConverter.ToString(md5.ComputeHash(stream)).Replace("-", "") == StockClientMd5;
        }

        public static readonly string[] UpdateSteps =
        {
            "Back up your characters",
            "Download the update",
            "Set up the game",
            "Rebuild the spell effects",
            "Update the database",
        };

        public static readonly string[] RepairSteps =
        {
            "Check the game files",
            "Download the missing files",
            "Set up the game",
            "Read the maps",
            "Rebuild the spell effects",
            "Check the database",
        };

        static readonly Dictionary<string, string> StepsInProgress = new Dictionary<string, string>
        {
            { "Check the game files", "Checking the game files" },
            { "Download the missing files", "Downloading the missing files" },
            { "Check the database", "Checking the database" },
            { "Download the game files", "Downloading the game files" },
            { "Set up the game", "Setting up the game" },
            { "Read the maps", "Reading the maps" },
            { "Build the spell effects", "Building the spell effects" },
            { "Set up the database", "Setting up the database" },
            { "Back up your characters", "Backing up your characters" },
            { "Download the update", "Downloading the update" },
            { "Rebuild the spell effects", "Rebuilding the spell effects" },
            { "Update the database", "Updating the database" },
        };

        public static string InProgress(string step) =>
            step != null && StepsInProgress.TryGetValue(step, out string doing) ? doing : step;

        const int BackupsKept = 3;

        string Backups => Path.Combine(m_folder.LauncherData, "backups");

        public HashSet<string> ChangedPackages(Manifest manifest)
        {
            Dictionary<string, string> installed = InstalledPackages();
            return new HashSet<string>(manifest.Packages
                .Where(p => !installed.TryGetValue(p.Name, out string hash) || hash != p.ContentHash)
                .Select(p => p.Name));
        }

        public async Task<bool> UpdateAsync(Manifest manifest, IProgress<InstallProgress> progress, CancellationToken cancel)
        {
            RefuseDevelopmentTree();
            bool launcherChanged = LauncherOutdated(manifest);
            string from = "Patch " + (m_folder.InstalledVersion?.Display ?? "unknown");
            try
            {
                progress.Report(new InstallProgress { Step = UpdateSteps[0] });
                await BackUpAsync(from, cancel);

                progress.Report(new InstallProgress { Step = UpdateSteps[1] });
                await DownloadAsync(await PackagesToFetchAsync(manifest, true, false, _ => { }), MissingThirdParty(manifest), progress, UpdateSteps[1], cancel);

                progress.Report(new InstallProgress { Step = UpdateSteps[2] });
                SetUpGame(manifest);

                progress.Report(new InstallProgress { Step = UpdateSteps[3] });
                if (!SpellEffectsBuilt())
                    await BuildSpellEffectsAsync(cancel);

                progress.Report(new InstallProgress { Step = UpdateSteps[4] });
                await EnsureDatabaseAsync(manifest, false, progress, UpdateSteps[4], cancel);
                FinishVersion();
            }
            finally
            {
                await m_server.StopAsync();
            }
            return launcherChanged;
        }

        public async Task<bool> RepairAsync(Manifest manifest, bool thorough, IProgress<InstallProgress> reporter, CancellationToken cancel)
        {
            if (m_folder.IsDevelopmentTree)
                return false;
            Directory.CreateDirectory(m_folder.LauncherData);
            FixTracker progress = new FixTracker(reporter);

            progress.Report(new InstallProgress { Step = RepairSteps[0] });
            Action<double> reportChecked = thorough
                ? fraction => progress.Report(new InstallProgress { Step = RepairSteps[0], Fraction = fraction })
                : (Action<double>)(_ => { });
            List<PackageEntry> packages = await PackagesToFetchAsync(manifest, false, thorough, reportChecked);
            List<ThirdPartyEntry> thirdParty = MissingThirdParty(manifest);
            if (packages.Count > 0 || thirdParty.Count > 0)
            {
                progress.Report(new InstallProgress { Step = RepairSteps[1], Fixing = true });
                await DownloadAsync(packages, thirdParty, progress, RepairSteps[1], cancel);
            }

            progress.Report(new InstallProgress { Step = RepairSteps[2] });
            SetUpGame(manifest);

            bool mapsMissing = !MapsRead;
            if (mapsMissing)
            {
                progress.Report(new InstallProgress { Step = RepairSteps[3], Fixing = true });
                await ReadMapsAsync(progress, RepairSteps[3], cancel);
            }

            if (thorough || mapsMissing || !SpellEffectsBuilt())
            {
                progress.Report(new InstallProgress { Step = RepairSteps[4], Fixing = true });
                await BuildSpellEffectsAsync(cancel);
            }

            progress.Report(new InstallProgress { Step = RepairSteps[5] });
            if (thorough && m_server.DatabaseExists)
            {
                progress.Report(new InstallProgress { Step = RepairSteps[5], Detail = "backing up your characters" });
                await BackUpAsync("Repair", cancel);
            }
            await EnsureDatabaseAsync(manifest, thorough, progress, RepairSteps[5], cancel);
            FinishVersion();
            return progress.FixedSomething;
        }

        public async Task ReloadWorldAsync(IProgress<InstallProgress> progress, CancellationToken cancel)
        {
            progress.Report(new InstallProgress { Step = RepairSteps[5], Fixing = true });
            await m_server.StartDatabaseOnlyAsync(cancel);
            await LoadWorldAsync(progress, RepairSteps[5]);
        }

        async Task BackUpAsync(string label, CancellationToken cancel)
        {
            await m_server.StartDatabaseOnlyAsync(cancel);
            HashSet<string> present = new HashSet<string>(Lines(await m_server.QueryAsync("mysql", "SHOW DATABASES")), StringComparer.OrdinalIgnoreCase);
            string[] databases = new[] { "characters", "realmd" }.Where(present.Contains).ToArray();
            if (databases.Length == 0)
                return;
            string folder = Path.Combine(Backups, $"{DateTime.Now:yyyy-MM-dd HHmmss} {label}");
            Directory.CreateDirectory(folder);
            await m_server.BackUpAsync(Path.Combine(folder, "characters and accounts.sql"), databases);
            foreach (DirectoryInfo old in new DirectoryInfo(Backups).GetDirectories().OrderByDescending(d => d.Name).Skip(BackupsKept))
                old.Delete(true);
        }

        async Task ClearWorldDatabaseAsync()
        {
            string Listed(string type) => $"SELECT CONCAT('`', table_name, '`') FROM information_schema.tables WHERE table_schema = 'mangos' AND table_type = '{type}'";
            List<string> views = Lines(await m_server.QueryAsync("mysql", Listed("VIEW"))).ToList();
            if (views.Count > 0)
                await m_server.QueryAsync("mangos", "DROP VIEW IF EXISTS " + string.Join(", ", views));
            List<string> tables = Lines(await m_server.QueryAsync("mysql", Listed("BASE TABLE"))).ToList();
            if (tables.Count > 0)
                await m_server.QueryAsync("mangos", "SET FOREIGN_KEY_CHECKS = 0; DROP TABLE IF EXISTS " + string.Join(", ", tables));
        }

        void RefuseDevelopmentTree()
        {
            if (m_folder.IsDevelopmentTree)
                throw new InvalidOperationException("This folder is a Hordes of Azeroth source checkout. Install the game into a separate copy of World of Warcraft 1.12.1 instead.");
        }

        public async Task InstallAsync(Manifest manifest, IProgress<InstallProgress> progress, CancellationToken cancel)
        {
            RefuseDevelopmentTree();
            Directory.CreateDirectory(m_folder.LauncherData);
            HashSet<string> done = CompletedSteps;
            try
            {
                foreach (string step in Steps)
                {
                    if (done.Contains(step))
                        continue;
                    progress.Report(new InstallProgress { Step = step });
                    switch (Array.IndexOf(Steps, step))
                    {
                        case 0: await DownloadAsync(await PackagesToFetchAsync(manifest, true, false, _ => { }), MissingThirdParty(manifest), progress, step, cancel); break;
                        case 1: SetUpGame(manifest); break;
                        case 2: await ReadMapsAsync(progress, step, cancel); break;
                        case 3: await BuildSpellEffectsAsync(cancel); break;
                        case 4: await EnsureDatabaseAsync(manifest, false, progress, step, cancel); break;
                    }
                    File.AppendAllLines(StateFile, new[] { step });
                }
            }
            finally
            {
                await m_server.StopAsync();
            }
            FinishVersion();
        }

        public async Task<bool> RefreshLauncherBeforeResumingAsync(Manifest manifest, CancellationToken cancel)
        {
            if (!CompletedSteps.Contains(Steps[0]) || !LauncherOutdated(manifest))
                return false;
            await RefreshLauncherAsync(manifest, cancel);
            return true;
        }

        public bool LauncherOutdated(Manifest manifest)
        {
            PackageEntry launcher = manifest.Packages.FirstOrDefault(p => p.Name == "launcher");
            return launcher != null && !(InstalledPackages().TryGetValue(launcher.Name, out string hash) && hash == launcher.ContentHash);
        }

        public async Task RefreshLauncherAsync(Manifest manifest, CancellationToken cancel)
        {
            PackageEntry launcher = manifest.Packages.First(p => p.Name == "launcher");
            Dictionary<string, string> installed = InstalledPackages();
            string file = await FetchAsync(launcher.Url, launcher.Sha256, _ => { }, cancel);
            Unzip(file, m_folder.Root, false, PendingVersion);
            installed[launcher.Name] = launcher.ContentHash;
            WritePairs(PackagesFile, installed);
            File.Delete(file);
        }

        Task<List<PackageEntry>> PackagesToFetchAsync(Manifest manifest, bool includeLauncher, bool compareContents, Action<double> reportChecked)
        {
            Dictionary<string, string> installed = InstalledPackages();
            List<PackageEntry> packages = manifest.Packages.Where(p => includeLauncher || p.Name != LauncherPackage).ToList();
            return Task.Run(() =>
            {
                long total = Math.Max(1, packages.Sum(p => p.Files.Sum(f => f.Size)));
                long checkedBytes = 0;
                List<PackageEntry> fetch = new List<PackageEntry>();
                foreach (PackageEntry package in packages)
                {
                    bool current = installed.TryGetValue(package.Name, out string hash) && hash == package.ContentHash;
                    if (!current || (package.Name != LauncherPackage && package.Files.Any(f => !IsIntact(f, compareContents))))
                        fetch.Add(package);
                    checkedBytes += package.Files.Sum(f => f.Size);
                    reportChecked((double)checkedBytes / total);
                }
                return fetch;
            });
        }

        bool IsIntact(PackageFile file, bool compareContents)
        {
            string path = file.Path == VersionEntry && File.Exists(PendingVersion)
                ? PendingVersion
                : Path.Combine(m_folder.Root, file.Path.Replace('/', Path.DirectorySeparatorChar));
            FileInfo info = new FileInfo(path);
            return info.Exists && info.Length == file.Size && (!compareContents || Sha256(path) == file.Sha256);
        }

        List<ThirdPartyEntry> MissingThirdParty(Manifest manifest) => manifest.ThirdParty.Where(t => !ThirdPartyInstalled(t)).ToList();

        async Task DownloadAsync(List<PackageEntry> packages, List<ThirdPartyEntry> thirdParty, IProgress<InstallProgress> progress, string step, CancellationToken cancel)
        {
            Dictionary<string, string> installed = InstalledPackages();
            long total = packages.Sum(p => p.Size) + thirdParty.Sum(t => t.Size);
            long finished = 0;
            Action<long> report = bytes => progress.Report(new InstallProgress
            {
                Step = step,
                Detail = $"{(finished + bytes) / 1048576.0:0.0} of {total / 1048576.0:0.0} MB",
                Fraction = total > 0 ? (double)(finished + bytes) / total : 0,
            });

            foreach (ThirdPartyEntry item in thirdParty)
            {
                string file = await FetchAsync(item.Url, item.Sha256, report, cancel);
                if (item.CopyTo != null)
                    File.Copy(file, Path.Combine(m_folder.Root, item.CopyTo), true);
                else if (Platform.IsTarball(file))
                    await Task.Run(() => Platform.ExtractTarball(file, Path.Combine(m_folder.Root, item.UnzipTo ?? "."), item.StripTopFolder), cancel);
                else
                    Unzip(file, Path.Combine(m_folder.Root, item.UnzipTo ?? "."), item.StripTopFolder, null);
                File.Delete(file);
                finished += item.Size;
            }
            foreach (PackageEntry package in packages)
            {
                string file = await FetchAsync(package.Url, package.Sha256, report, cancel);
                Unzip(file, m_folder.Root, false, PendingVersion);
                installed[package.Name] = package.ContentHash;
                WritePairs(PackagesFile, installed);
                finished += package.Size;
                File.Delete(file);
            }
        }

        public Dictionary<string, string> InstalledPackages() => ReadPairs(PackagesFile);

        string InstalledHash(string package) => InstalledPackages().TryGetValue(package, out string hash) ? hash : "";

        Dictionary<string, string> AppliedPackages() => ReadPairs(AppliedFile);

        void MarkApplied(string package)
        {
            Dictionary<string, string> applied = AppliedPackages();
            applied[package] = InstalledHash(package);
            WritePairs(AppliedFile, applied);
        }

        void ForgetApplied(string package)
        {
            Dictionary<string, string> applied = AppliedPackages();
            if (applied.Remove(package))
                WritePairs(AppliedFile, applied);
        }

        static Dictionary<string, string> ReadPairs(string file)
        {
            Dictionary<string, string> pairs = new Dictionary<string, string>();
            if (File.Exists(file))
                foreach (string[] pair in File.ReadAllLines(file).Select(l => l.Split(new[] { '=' }, 2)).Where(p => p.Length == 2))
                    pairs[pair[0]] = pair[1];
            return pairs;
        }

        static void WritePairs(string file, Dictionary<string, string> pairs)
        {
            Directory.CreateDirectory(Path.GetDirectoryName(file));
            File.WriteAllLines(file, pairs.Select(p => p.Key + "=" + p.Value));
        }

        bool ThirdPartyInstalled(ThirdPartyEntry item)
        {
            if (item.CopyTo != null)
                return File.Exists(Path.Combine(m_folder.Root, item.CopyTo));
            if (item.Name == "MariaDB")
                return File.Exists(Path.Combine(m_folder.MariaDb, "bin", Platform.Exe("mariadbd")));
            return false;
        }

        public async Task<string> FetchAsync(string url, string sha256, Action<long> report, CancellationToken cancel)
        {
            Directory.CreateDirectory(Downloads);
            string name = Path.GetFileName(new Uri(url).AbsolutePath);
            string target = Path.Combine(Downloads, name);
            if (File.Exists(target) && Sha256(target) == sha256)
                return target;

            string local = UpdateCheck.LocalSource == null ? null : Path.Combine(UpdateCheck.LocalSource, name);
            if (local != null && File.Exists(local))
            {
                File.Copy(local, target, true);
            }
            else
            {
                try
                {
                    await Web.DownloadAsync(url, target, report, cancel);
                }
                catch (Exception e) when (Web.IsProblem(e) && !cancel.IsCancellationRequested)
                {
                    if (File.Exists(target))
                        File.Delete(target);
                    throw new InvalidOperationException($"Couldn't download {name} ({e.Message.TrimEnd('.')}). Check your connection and try again.");
                }
            }
            if (Sha256(target) != sha256)
            {
                File.Delete(target);
                throw new InvalidDataException($"{name} didn't download correctly. Try again.");
            }
            return target;
        }

        static string Sha256(string path)
        {
            using (SHA256 sha = SHA256.Create())
            using (FileStream stream = File.OpenRead(path))
                return BitConverter.ToString(sha.ComputeHash(stream)).Replace("-", "").ToLowerInvariant();
        }

        static readonly string RunningExe = Path.GetFullPath(Environment.ProcessPath);

        public static readonly string LauncherFileName = Platform.Exe("HoALauncher");
        static readonly string[] RetiredLauncherNames = Platform.IsWindows ? new[] { "HordesOfAzerothLauncher.exe" } : new string[0];

        public static void RemoveOldLauncher()
        {
            string folder = Path.GetDirectoryName(RunningExe);
            List<string> leftovers = new List<string> { RunningExe + ".old" };
            if (string.Equals(Path.GetFileName(RunningExe), LauncherFileName, StringComparison.OrdinalIgnoreCase))
                foreach (string retired in RetiredLauncherNames)
                {
                    leftovers.Add(Path.Combine(folder, retired));
                    leftovers.Add(Path.Combine(folder, retired + ".old"));
                }
            foreach (string leftover in leftovers)
                try
                {
                    if (File.Exists(leftover))
                        File.Delete(leftover);
                }
                catch (Exception e) when (e is IOException || e is UnauthorizedAccessException)
                {
                }
        }

        static void Unzip(string zip, string targetDir, bool stripTopFolder, string versionTarget)
        {
            string root = Path.GetFullPath(targetDir).TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
            using (ZipArchive archive = ZipFile.OpenRead(zip))
                foreach (ZipArchiveEntry entry in archive.Entries)
                {
                    string relative = entry.FullName.Replace('/', Path.DirectorySeparatorChar);
                    if (stripTopFolder)
                    {
                        int slash = relative.IndexOf(Path.DirectorySeparatorChar);
                        if (slash < 0)
                            continue;
                        relative = relative.Substring(slash + 1);
                    }
                    if (relative.Length == 0)
                        continue;
                    string target = versionTarget != null && relative == "VERSION" ? versionTarget : Path.GetFullPath(Path.Combine(root, relative));
                    if (target != versionTarget && !target.StartsWith(root, StringComparison.OrdinalIgnoreCase))
                        throw new InvalidDataException($"{Path.GetFileName(zip)} contains a path outside the game folder.");
                    if (relative.EndsWith(Path.DirectorySeparatorChar.ToString()))
                    {
                        Directory.CreateDirectory(target);
                        continue;
                    }
                    Directory.CreateDirectory(Path.GetDirectoryName(target));
                    if (string.Equals(target, RunningExe, StringComparison.OrdinalIgnoreCase) && File.Exists(target))
                    {
                        string old = target + ".old";
                        if (File.Exists(old))
                            File.Delete(old);
                        File.Move(target, old);
                    }
                    entry.ExtractToFile(target, true);
                    Platform.MarkExecutableIfProgram(target);
                }
        }

        void SetUpGame(Manifest manifest)
        {
            GameConfig.EnsureDefaults(m_folder, manifest.RealmName);
            RemoveRetiredClientFiles();
            RemoveRetiredPatch();
        }

        void RemoveRetiredPatch()
        {
            Dictionary<string, string> applied = AppliedPackages();
            if (m_folder.IsDevelopmentTree || !Directory.Exists(m_folder.Data) || applied.ContainsKey(RetiredPatchApplied))
                return;
            string retired = GameFiles.Child(m_folder.Data, Kit.RetiredPatchName);
            if (File.Exists(retired))
                TryDelete(() => File.Delete(retired));
            applied[RetiredPatchApplied] = Kit.RetiredPatchName;
            WritePairs(AppliedFile, applied);
        }

        static readonly string[] RetiredClientFiles =
        {
            "VanillaFixes.exe", "VfPatcher.dll", "dlls.txt", "dlls.txt.cache", "d3d9.dll", "dxvk.conf",
            "HordesOfAzeroth.dxvk-cache", "HordesOfAzeroth_d3d9.log", "VanillaFixes_d3d9.log",
            "ClassicAPI.dll", "HordesOfAzerothClientFix.dll", "HordesOfAzerothClientFix.dll.old", "vcruntime140.dll",
            "config/client-patches.json", "Logs/HordesOfAzerothClientFix.log",
        };
        static readonly string[] RetiredClientFolders = { "mods/wow_turbo" };
        static readonly string[] RetiredPackages = { "client-fix", "client-runtime", "wow-turbo" };

        void RemoveRetiredClientFiles()
        {
            if (m_folder.IsDevelopmentTree || !Platform.IsWindows)
                return;
            foreach (string file in RetiredClientFiles)
                TryDelete(() => File.Delete(Path.Combine(m_folder.Root, file.Replace('/', Path.DirectorySeparatorChar))));
            foreach (string folder in RetiredClientFolders)
            {
                string path = Path.Combine(m_folder.Root, folder.Replace('/', Path.DirectorySeparatorChar));
                if (Directory.Exists(path))
                    TryDelete(() => Directory.Delete(path, true));
            }
            string mods = Path.Combine(m_folder.Root, "mods");
            if (Directory.Exists(mods) && !Directory.EnumerateFileSystemEntries(mods).Any())
                TryDelete(() => Directory.Delete(mods));

            Dictionary<string, string> installed = InstalledPackages();
            if (RetiredPackages.Count(installed.Remove) > 0)
                WritePairs(PackagesFile, installed);
            foreach (string package in RetiredPackages)
                ForgetApplied(package);
        }

        static void TryDelete(Action delete)
        {
            try
            {
                delete();
            }
            catch (Exception e) when (e is IOException || e is UnauthorizedAccessException)
            {
            }
        }

        void GiveExtractorsTheirDataFolder()
        {
            string expected = Path.Combine(m_folder.Root, "Data");
            if (Platform.IsWindows || Directory.Exists(expected) || !Directory.Exists(m_folder.Data))
                return;
            Directory.CreateSymbolicLink(expected, Path.GetFileName(m_folder.Data));
        }

        async Task ReadMapsAsync(IProgress<InstallProgress> progress, string step, CancellationToken cancel)
        {
            GiveExtractorsTheirDataFolder();
            string extractors = Path.Combine(m_folder.ServerRun, "Extractors");
            Directory.CreateDirectory(Path.Combine(DataDir, "vmaps"));

            progress.Report(new InstallProgress { Step = step, Detail = "terrain and areas", Fraction = 0.05 });
            await RunToolAsync(Path.Combine(extractors, Platform.Exe("MapExtractor")), DataDir, cancel, "-i", Quote(m_folder.Root), "--silent");
            string dbcTarget = Path.Combine(DataDir, "5875", "dbc");
            Directory.CreateDirectory(Path.GetDirectoryName(dbcTarget));
            await Folders.MoveAsync(Path.Combine(DataDir, "dbc"), dbcTarget, cancel);

            progress.Report(new InstallProgress { Step = step, Detail = "buildings and trees", Fraction = 0.4 });
            await Folders.DeleteAsync(Path.Combine(DataDir, "Buildings"), cancel);
            await RunToolAsync(Path.Combine(extractors, Platform.Exe("VMapExtractor")), DataDir, cancel, "-d", Quote(m_folder.Data), "--silent");
            progress.Report(new InstallProgress { Step = step, Detail = "line of sight", Fraction = 0.8 });
            await RunToolAsync(Path.Combine(extractors, Platform.Exe("VMapAssembler")), DataDir, cancel, "Buildings", "vmaps", "--silent");
            await Folders.DeleteAsync(Path.Combine(DataDir, "Buildings"), cancel);
        }

        async Task BuildSpellEffectsAsync(CancellationToken cancel)
        {
            string root = m_folder.Root;
            await Task.Run(() => Kit.Build(root), cancel);
            MarkSpellEffectsBuilt();
        }

        string SpellEffectsKey => InstalledHash(LauncherPackage) + "+" + InstalledHash(SpellEffectsPackage) + "+" + PlayerPatchesKey();

        string PlayerPatchesKey()
        {
            if (!Directory.Exists(m_folder.Data))
                return "";
            return string.Join(",", ClientData.NumberedPatches(m_folder.Data)
                .Where(name => !Kit.OwnPatches.Contains(name, StringComparer.OrdinalIgnoreCase))
                .Select(name => name.ToLowerInvariant() + ":" + new FileInfo(Path.Combine(m_folder.Data, name)).Length));
        }

        void MarkSpellEffectsBuilt()
        {
            Dictionary<string, string> applied = AppliedPackages();
            applied[SpellEffectsApplied] = SpellEffectsKey;
            WritePairs(AppliedFile, applied);
        }

        bool SpellEffectsBuilt()
        {
            if (!File.Exists(Path.Combine(m_folder.Data, Kit.PatchName)) || !SpellEffectFiles.All(f => File.Exists(Path.Combine(m_folder.Root, f))))
                return false;
            if (AppliedPackages().TryGetValue(SpellEffectsApplied, out string built))
                return built == SpellEffectsKey;
            return false;
        }

        bool MapsRead =>
            HasFiles(Path.Combine(DataDir, "maps"), "*.map")
            && HasFiles(Path.Combine(DataDir, "vmaps"), "*.vmtree")
            && HasFiles(Path.Combine(DataDir, "5875", "dbc"), "*.dbc");

        static bool HasFiles(string folder, string pattern) => Directory.Exists(folder) && Directory.EnumerateFiles(folder, pattern).Any();

        async Task EnsureDatabaseAsync(Manifest manifest, bool reloadWorld, IProgress<InstallProgress> progress, string step, CancellationToken cancel)
        {
            if (!m_server.DatabaseExists)
            {
                ForgetApplied(WorldPackage);
                progress.Report(new InstallProgress { Step = step, Detail = "creating the database", Fraction = 0.05, Fixing = true });
                await m_server.CreateDatabaseFilesAsync();
            }
            await m_server.StartDatabaseOnlyAsync(cancel);
            await m_server.RunSqlFileAsync(null, Path.Combine(m_folder.Config, "create-databases.sql"));
            HashSet<string> tables = await TablesAsync();

            string[,] imports =
            {
                { "realmd", "logon.sql", "account" },
                { "logs", "logs.sql", "logs_characters" },
                { "characters", "characters.sql", "characters" },
            };
            for (int i = 0; i < imports.GetLength(0); i++)
            {
                string database = imports[i, 0];
                if (tables.Contains(database + "." + imports[i, 2]))
                    continue;
                progress.Report(new InstallProgress { Step = step, Detail = "creating " + database, Fraction = 0.1 + 0.15 * i, Fixing = true });
                await m_server.RunSqlFileAsync(database, Path.Combine(SqlDir, imports[i, 1]));
            }

            if (reloadWorld || !await WorldLoadedAsync(tables))
                await LoadWorldAsync(progress, step);

            await ApplyMigrationsAsync(progress, step);
            await EnsureRealmAndAccountAsync(manifest, progress, step, cancel);
        }

        async Task<HashSet<string>> TablesAsync()
        {
            string tables = await m_server.QueryAsync("information_schema", "SELECT CONCAT(TABLE_SCHEMA, '.', TABLE_NAME) FROM TABLES WHERE TABLE_SCHEMA IN ('realmd', 'logs', 'characters', 'mangos')");
            return new HashSet<string>(Lines(tables), StringComparer.OrdinalIgnoreCase);
        }

        async Task<bool> WorldLoadedAsync(HashSet<string> tables)
        {
            if (!tables.Contains("mangos.migrations"))
                return false;
            if (AppliedPackages().TryGetValue(WorldPackage, out string loaded))
                return loaded == InstalledHash(WorldPackage);
            if (File.Exists(PendingVersion) || !File.Exists(WorldSql))
                return false;
            WorldDump dump = await Task.Run(() => WorldDump.Read(WorldSql));
            if (dump.LastTable == null || !tables.Contains("mangos." + dump.LastTable))
                return false;
            HashSet<string> applied = new HashSet<string>(Lines(await m_server.QueryAsync("mangos", "SELECT id FROM migrations")));
            if (!dump.Migrations.All(applied.Contains))
                return false;
            MarkApplied(WorldPackage);
            return true;
        }

        async Task LoadWorldAsync(IProgress<InstallProgress> progress, string step)
        {
            if (!File.Exists(WorldSql))
                throw new FileNotFoundException("The world database file (server/sql/world.sql) is missing. " + LocalServer.RepairAdvice, WorldSql);
            progress.Report(new InstallProgress { Step = step, Detail = "loading the world (about a minute)", Fraction = 0.55, Fixing = true });
            ForgetApplied(WorldPackage);
            await m_server.RunSqlFileAsync(null, Path.Combine(m_folder.Config, "create-databases.sql"));
            await ClearWorldDatabaseAsync();
            await m_server.RunSqlFileAsync("mangos", WorldSql);
            MarkApplied(WorldPackage);
        }

        async Task ApplyMigrationsAsync(IProgress<InstallProgress> progress, string step)
        {
            string folder = Path.Combine(SqlDir, "migrations");
            if (!Directory.Exists(folder))
                return;
            string query = string.Join(" UNION ALL ", MigrationDatabases.Values.Select(d => $"SELECT CONCAT('{d}.', id) FROM {d}.migrations"));
            HashSet<string> applied = new HashSet<string>(Lines(await m_server.QueryAsync("realmd", query)));
            foreach (string file in Directory.GetFiles(folder, "*.sql").OrderBy(f => Path.GetFileName(f), StringComparer.Ordinal))
            {
                string[] parts = Path.GetFileNameWithoutExtension(file).Split('_');
                if (parts.Length != 2 || !MigrationDatabases.TryGetValue(parts[1], out string database) || applied.Contains(database + "." + parts[0]))
                    continue;
                progress.Report(new InstallProgress { Step = step, Detail = "applying updates to your characters", Fraction = 0.75, Fixing = true });
                await m_server.RunSqlFileAsync(database, file);
            }
        }

        async Task EnsureRealmAndAccountAsync(Manifest manifest, IProgress<InstallProgress> progress, string step, CancellationToken cancel)
        {
            string realm = manifest.RealmName.Replace("'", "''");
            await m_server.QueryAsync("realmd", $"INSERT INTO realmlist (id, name, address, port) VALUES (1, '{realm}', '127.0.0.1', 8085) ON DUPLICATE KEY UPDATE name = '{realm}', address = '127.0.0.1', port = 8085");
            if (await PlayerAccountExistsAsync())
                return;
            progress.Report(new InstallProgress { Step = step, Detail = "creating your account", Fraction = 0.85, Fixing = true });
            await m_server.StartAsync(new Progress<string>(_ => { }), cancel);
            await m_server.RunConsoleAsync("account create player player");
            bool created = await PlayerAccountExistsAsync();
            await m_server.StopAsync();
            if (!created)
                throw new InvalidOperationException("The account couldn't be created. See server/logs/Server.log.");
        }

        async Task<bool> PlayerAccountExistsAsync() =>
            (await m_server.QueryAsync("realmd", "SELECT COUNT(*) FROM account WHERE username = 'PLAYER'")).Trim() != "0";

        static IEnumerable<string> Lines(string text) => text.Split('\n').Select(l => l.Trim()).Where(l => l.Length > 0);

        static async Task RunToolAsync(string exe, string workingDirectory, CancellationToken cancel, params string[] arguments)
        {
            if (!File.Exists(exe))
                throw new FileNotFoundException($"{Path.GetFileName(exe)} is missing from the download.");
            ProcessStartInfo info = new ProcessStartInfo(exe, string.Join(" ", arguments))
            {
                WorkingDirectory = workingDirectory,
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardInput = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
            };
            Queue<string> lastLines = new Queue<string>();
            DataReceivedEventHandler remember = (s, e) =>
            {
                if (string.IsNullOrWhiteSpace(e.Data) || e.Data.StartsWith("Processing"))
                    return;
                lock (lastLines)
                {
                    lastLines.Enqueue(e.Data.Trim());
                    while (lastLines.Count > 3)
                        lastLines.Dequeue();
                }
            };
            using (Process process = Process.Start(info))
            {
                process.OutputDataReceived += remember;
                process.ErrorDataReceived += remember;
                process.BeginOutputReadLine();
                process.BeginErrorReadLine();
                process.StandardInput.Close();
                using (cancel.Register(() => { try { process.Kill(); } catch (InvalidOperationException) { } }))
                    while (!process.HasExited)
                        await Task.Delay(200);
                process.WaitForExit();
                cancel.ThrowIfCancellationRequested();
                if (process.ExitCode != 0)
                {
                    string said;
                    lock (lastLines)
                        said = string.Join(" / ", lastLines);
                    throw new InvalidOperationException($"{Path.GetFileName(exe)} stopped with code {process.ExitCode}: {said}");
                }
            }
        }

        static string Quote(string text) => "\"" + text + "\"";
    }
}

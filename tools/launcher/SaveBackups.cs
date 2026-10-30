using System;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace HordesOfAzeroth.Launcher
{
    sealed class SaveBackups
    {
        const string DatabaseFile = "characters and accounts.sql";
        const string SavedFolder = "saved";
        const string BindingsFolder = "bindings";

        readonly GameFolder m_folder;
        readonly LocalServer m_server;
        readonly Installer m_installer;

        public SaveBackups(GameFolder folder, LocalServer server, Installer installer)
        {
            m_folder = folder;
            m_server = server;
            m_installer = installer;
        }

        public string Folder => Path.Combine(m_folder.LauncherData, "save backups");

        public DateTime? LastBackupTime =>
            Directory.Exists(Folder)
                ? new DirectoryInfo(Folder).GetFiles("*.zip").Select(f => (DateTime?)f.LastWriteTime).OrderByDescending(t => t).FirstOrDefault()
                : null;

        public async Task<string> BackUpAsync(string label, CancellationToken cancel)
        {
            await m_server.StartDatabaseOnlyAsync(cancel);
            string work = NewWorkFolder();
            try
            {
                await m_server.BackUpAsync(Path.Combine(work, DatabaseFile), "characters", "realmd");
                CopyIfPresent(Path.Combine(m_folder.LauncherData, Accounts.FileName), Path.Combine(work, Accounts.FileName));
                CopyFolderIfPresent(m_folder.ClientSaved, Path.Combine(work, SavedFolder));
                CopyFolderIfPresent(m_folder.ClientBindings, Path.Combine(work, BindingsFolder));
                Directory.CreateDirectory(Folder);
                string zip = Path.Combine(Folder, $"Hordes of Azeroth save {DateTime.Now:yyyy-MM-dd HHmmss}{label}.zip");
                ZipFile.CreateFromDirectory(work, zip);
                return zip;
            }
            finally
            {
                Folders.TryDelete(work);
            }
        }

        public async Task RestoreAsync(string zip, CancellationToken cancel)
        {
            string work = NewWorkFolder();
            try
            {
                ZipFile.ExtractToDirectory(zip, work);
                string database = Path.Combine(work, DatabaseFile);
                if (!File.Exists(database))
                    throw new InvalidDataException("This file isn't a Hordes of Azeroth save backup.");
                await BackUpAsync(" before restore", cancel);
                await m_server.QueryAsync("mysql", "DROP DATABASE IF EXISTS characters; DROP DATABASE IF EXISTS realmd");
                await m_server.RunSqlFileAsync(null, database);
                await m_installer.ApplyMigrationsAsync(new Progress<InstallProgress>(_ => { }), null);
                CopyIfPresent(Path.Combine(work, Accounts.FileName), Path.Combine(m_folder.LauncherData, Accounts.FileName));
                ReplaceFolderIfPresent(Path.Combine(work, SavedFolder), m_folder.ClientSaved);
                ReplaceFolderIfPresent(Path.Combine(work, BindingsFolder), m_folder.ClientBindings);
            }
            finally
            {
                Folders.TryDelete(work);
            }
        }

        string NewWorkFolder()
        {
            string work = Path.Combine(Path.GetTempPath(), "HordesOfAzeroth-save-" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(work);
            return work;
        }

        static void CopyIfPresent(string from, string to)
        {
            if (!File.Exists(from))
                return;
            Directory.CreateDirectory(Path.GetDirectoryName(to));
            File.Copy(from, to, true);
        }

        static void CopyFolderIfPresent(string from, string to)
        {
            if (!Directory.Exists(from))
                return;
            Directory.CreateDirectory(to);
            foreach (string file in Directory.GetFiles(from))
                File.Copy(file, Path.Combine(to, Path.GetFileName(file)), true);
            foreach (string folder in Directory.GetDirectories(from))
                CopyFolderIfPresent(folder, Path.Combine(to, Path.GetFileName(folder)));
        }

        static void ReplaceFolderIfPresent(string from, string to)
        {
            if (!Directory.Exists(from))
                return;
            if (Directory.Exists(to) && !Folders.TryDelete(to))
                Folders.ClearReadOnly(to);
            CopyFolderIfPresent(from, to);
        }
    }
}

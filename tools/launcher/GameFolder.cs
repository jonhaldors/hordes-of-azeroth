using System;
using System.IO;
using BonkTelegraphs;

namespace HordesOfAzeroth.Launcher
{
    sealed class GameFolder
    {
        public string Root { get; }
        public string Data => GameFiles.Child(Root, "Data");
        public string WowExe => GameFiles.Child(Root, "WoW.exe");
        public string Config => Path.Combine(Root, "config");
        public string Server => Path.Combine(Root, "server");
        public string ServerRun => Path.Combine(Server, "run");
        public string ServerLogs => Path.Combine(Server, "logs");
        public string MariaDb => Path.Combine(Server, "mariadb");
        public string MariaDbData => Path.Combine(Server, "mariadb-data");
        public string LauncherData => Path.Combine(Root, "HordesOfAzeroth");
        public string VersionFile => Path.Combine(Root, "VERSION");
        public string LatestVersionFile => Path.Combine(ServerRun, "latest-version.txt");
        public string ConfigWtf => Path.Combine(Root, "WTF", "Config.wtf");
        public string OldAccount => Path.Combine(Root, "WTF", "Account", "PLAYER");
        public string OldSavedVariables => Path.Combine(OldAccount, "SavedVariables");
        public string GlueXml => Path.Combine(Root, "Interface", "GlueXML");
        public string AddOns => Path.Combine(Root, "Interface", "AddOns");
        public string ClientState => Path.Combine(Root, "benilla-config");
        public string ClientConfig => Path.Combine(ClientState, "config.toml");
        public string ClientAddOns => Path.Combine(ClientState, "AddOns");
        public string ClientSaved => Path.Combine(ClientState, "saved");
        public string ClientBindings => Path.Combine(ClientState, "bindings");
        public string ClientCache => Path.Combine(ClientState, "cache");
        public string ClientLog => Path.Combine(Root, "Logs", "client.log");

        GameFolder(string root)
        {
            Root = root;
        }

        public static GameFolder Find()
        {
            string start = AppDomain.CurrentDomain.BaseDirectory;
            for (DirectoryInfo dir = new DirectoryInfo(start); dir != null; dir = dir.Parent)
                if (File.Exists(GameFiles.Child(dir.FullName, "WoW.exe")))
                    return new GameFolder(dir.FullName.TrimEnd(Path.DirectorySeparatorChar));
            return new GameFolder(start.TrimEnd(Path.DirectorySeparatorChar));
        }

        public bool IsDevelopmentTree => Directory.Exists(Path.Combine(Root, ".git"));
        public bool HasClient => File.Exists(WowExe) && Directory.Exists(Data);

        public string GameExeName => Platform.IsWindows ? "HordesOfAzeroth.exe" : "HordesOfAzeroth.x86_64";

        public string GameExe => Path.Combine(Root, GameExeName);

        public GameVersion InstalledVersion => GameVersion.ReadFile(VersionFile);
    }
}

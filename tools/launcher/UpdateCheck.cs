using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace HordesOfAzeroth.Launcher
{
    sealed class ReleaseNote
    {
        public GameVersion Version;
        public string Text;
    }

    sealed class PackageFile
    {
        public string Path;
        public long Size;
        public string Sha256;
    }

    sealed class PackageEntry
    {
        public string Name;
        public string Url;
        public string Sha256;
        public long Size;
        public string ContentHash;
        public List<PackageFile> Files = new List<PackageFile>();
    }

    sealed class ThirdPartyEntry
    {
        public string Name;
        public string Url;
        public string Sha256;
        public long Size;
        public string UnzipTo;
        public bool StripTopFolder;
        public string CopyTo;
    }

    sealed class NavGroup
    {
        public string Name;
        public PackageEntry Download;
        public List<string> WholeMaps = new List<string>();
        public List<KeyValuePair<string, string>> Tiles = new List<KeyValuePair<string, string>>();
    }

    sealed class Manifest
    {
        public GameVersion Version;
        public long DownloadSize;
        public string RealmName = "Hordes of Azeroth";
        public List<string> ClientDlls = new List<string>();
        public List<ReleaseNote> Notes = new List<ReleaseNote>();
        public List<PackageEntry> Packages = new List<PackageEntry>();
        public List<ThirdPartyEntry> ThirdParty = new List<ThirdPartyEntry>();
        public List<NavGroup> NavGroups = new List<NavGroup>();
    }

    sealed class UpdateCheck
    {
        public static readonly string Repository = typeof(UpdateCheck).Assembly
            .GetCustomAttributes(typeof(System.Reflection.AssemblyMetadataAttribute), false)
            .OfType<System.Reflection.AssemblyMetadataAttribute>()
            .FirstOrDefault(a => a.Key == "Repository")?.Value ?? "jonhaldors/hordes-of-azeroth";

        static string ManifestUrl => $"https://github.com/{Repository}/releases/latest/download/{Platform.ManifestName}";

        readonly GameFolder m_folder;

        public UpdateCheck(GameFolder folder)
        {
            m_folder = folder;
        }

        string CachedManifest => Path.Combine(m_folder.LauncherData, "manifest.json");

        public static string LocalSource;

        public async Task<Manifest> FetchAsync()
        {
            if (LocalSource != null)
            {
                string json = File.ReadAllText(Path.Combine(LocalSource, Platform.ManifestName));
                Directory.CreateDirectory(m_folder.LauncherData);
                File.WriteAllText(CachedManifest, json, new UTF8Encoding(false));
                return Parse(json);
            }
            string text = await Mirror.TryEachAsync(ManifestUrl, CancellationToken.None, source => Web.Client.GetStringAsync(source));
            Manifest manifest = Parse(text);
            Directory.CreateDirectory(m_folder.LauncherData);
            File.WriteAllText(CachedManifest, text, new UTF8Encoding(false));
            return manifest;
        }

        public Manifest LoadCached()
        {
            try
            {
                return File.Exists(CachedManifest) ? Parse(File.ReadAllText(CachedManifest)) : null;
            }
            catch (Exception e) when (e is IOException || e is ArgumentException || e is InvalidOperationException || e is System.Text.Json.JsonException)
            {
                return null;
            }
        }

        public void PublishLatestVersion(Manifest manifest)
        {
            GameVersion installed = m_folder.InstalledVersion;
            if (manifest?.Version != null && manifest.Version.IsNewerThan(installed))
            {
                Directory.CreateDirectory(m_folder.ServerRun);
                File.WriteAllText(m_folder.LatestVersionFile, manifest.Version.Full + "\n");
            }
            else if (File.Exists(m_folder.LatestVersionFile))
            {
                File.Delete(m_folder.LatestVersionFile);
            }
        }

        public List<ReleaseNote> LocalNotes()
        {
            string changelog = Path.Combine(m_folder.Root, "CHANGELOG.md");
            return File.Exists(changelog) ? ParseChangelog(File.ReadAllLines(changelog)) : new List<ReleaseNote>();
        }

        public static Manifest Parse(string json)
        {
            Dictionary<string, object> root = (Dictionary<string, object>)Json.Parse(json);
            Manifest manifest = new Manifest { Version = GameVersion.Parse(root["version"] as string) };
            if (root.TryGetValue("releaseNotes", out object notes) && notes is object[] list)
                foreach (Dictionary<string, object> note in list.OfType<Dictionary<string, object>>())
                    manifest.Notes.Add(new ReleaseNote { Version = GameVersion.Parse(note["version"] as string), Text = note["notes"] as string ?? "" });
            if (root.TryGetValue("packages", out object packages) && packages is object[] packageList)
            {
                foreach (Dictionary<string, object> package in packageList.OfType<Dictionary<string, object>>())
                    manifest.Packages.Add(new PackageEntry
                    {
                        Name = package["name"] as string,
                        Url = package["url"] as string,
                        Sha256 = package["sha256"] as string,
                        Size = Convert.ToInt64(package["size"]),
                        ContentHash = package["contentHash"] as string,
                        Files = ParseFiles(package),
                    });
                manifest.DownloadSize = packageList.OfType<Dictionary<string, object>>()
                    .Where(p => p.TryGetValue("release", out object release) && (release as string) == "v" + manifest.Version?.Full)
                    .Sum(p => Convert.ToInt64(p["size"]));
            }
            if (root.TryGetValue("thirdParty", out object thirdParty) && thirdParty is object[] thirdPartyList)
                foreach (Dictionary<string, object> item in thirdPartyList.OfType<Dictionary<string, object>>())
                {
                    Dictionary<string, object> install = item.TryGetValue("install", out object i) ? i as Dictionary<string, object> : null;
                    manifest.ThirdParty.Add(new ThirdPartyEntry
                    {
                        Name = item["name"] as string,
                        Url = item["url"] as string,
                        Sha256 = item["sha256"] as string,
                        Size = Convert.ToInt64(item["size"]),
                        UnzipTo = install != null && install.TryGetValue("unzipTo", out object unzip) ? unzip as string : null,
                        StripTopFolder = install != null && install.TryGetValue("stripTopFolder", out object strip) && strip is bool b && b,
                        CopyTo = install != null && install.TryGetValue("copyTo", out object copy) ? copy as string : null,
                    });
                }
            if (root.TryGetValue("navTiles", out object navTiles) && navTiles is object[] groups)
                foreach (Dictionary<string, object> group in groups.OfType<Dictionary<string, object>>())
                {
                    NavGroup navGroup = new NavGroup { Name = group["name"] as string };
                    if (group.TryGetValue("download", out object download) && download is Dictionary<string, object> pack)
                        navGroup.Download = new PackageEntry
                        {
                            Name = navGroup.Name,
                            Url = pack["url"] as string,
                            Sha256 = pack["sha256"] as string,
                            Size = Convert.ToInt64(pack["size"]),
                            ContentHash = pack["contentHash"] as string,
                        };
                    if (group["maps"] is Dictionary<string, object> maps)
                        foreach (KeyValuePair<string, object> map in maps)
                        {
                            if (map.Value is string)
                                navGroup.WholeMaps.Add(map.Key);
                            else if (map.Value is object[] tiles)
                                navGroup.Tiles.AddRange(tiles.OfType<string>().Select(t => new KeyValuePair<string, string>(map.Key, t)));
                        }
                    manifest.NavGroups.Add(navGroup);
                }
            if (root.TryGetValue("clientDlls", out object dlls) && dlls is object[] dllList)
                manifest.ClientDlls.AddRange(dllList.OfType<string>());
            if (root.TryGetValue("realmName", out object realm) && realm is string realmName)
                manifest.RealmName = realmName;
            return manifest;
        }

        static List<PackageFile> ParseFiles(Dictionary<string, object> package)
        {
            if (!package.TryGetValue("files", out object files) || !(files is object[] list))
                return new List<PackageFile>();
            return list.OfType<Dictionary<string, object>>().Select(f => new PackageFile
            {
                Path = f["path"] as string,
                Size = Convert.ToInt64(f["size"]),
                Sha256 = f["sha256"] as string,
            }).ToList();
        }

        static List<ReleaseNote> ParseChangelog(string[] lines)
        {
            List<ReleaseNote> notes = new List<ReleaseNote>();
            ReleaseNote current = null;
            StringBuilder text = new StringBuilder();
            foreach (string line in lines)
            {
                if (line.StartsWith("## "))
                {
                    if (current != null)
                        current.Text = text.ToString().Trim();
                    current = new ReleaseNote { Version = GameVersion.Parse(line.Substring(3)) };
                    notes.Add(current);
                    text.Clear();
                }
                else if (current != null)
                {
                    text.AppendLine(line);
                }
            }
            if (current != null)
                current.Text = text.ToString().Trim();
            return notes.Where(n => n.Version != null).ToList();
        }
    }
}

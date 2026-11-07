using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;

namespace HordesOfAzeroth.Launcher
{
    static class Mirror
    {
        static string Metadata(string key) => (typeof(Mirror).Assembly
            .GetCustomAttributes(typeof(AssemblyMetadataAttribute), false)
            .OfType<AssemblyMetadataAttribute>()
            .FirstOrDefault(a => a.Key == key)?.Value ?? "").Trim();

        static readonly string BaseUrl = Metadata("MirrorUrl").TrimEnd('/');

        // A Gitee mirror of the GitHub repository: same release tags and asset names. Gitee has no
        // stable /releases/latest/download path, so the latest tag comes from its API.
        static readonly string GiteeRepository = Metadata("GiteeRepository").Trim('/');

        static readonly string[] ChinaTimeZones = { "China Standard Time", "Asia/Shanghai", "Asia/Urumqi", "Asia/Chongqing", "Asia/Harbin", "PRC" };

        static readonly bool InChina = ChinaTimeZones.Contains(TimeZoneInfo.Local.Id);

        static bool PrimaryFailed;

        static bool PreferMirror => InChina || PrimaryFailed;

        static string ReleasesUrl => $"https://github.com/{UpdateCheck.Repository}/releases/";

        public static string BoardUrl => BaseUrl.Length > 0 ? BaseUrl + "/board/board.txt" : "";

        public static string KeyFor(string url)
        {
            string latest = ReleasesUrl + "latest/download/";
            string tagged = ReleasesUrl + "download/";
            if (url.StartsWith(latest, StringComparison.Ordinal))
                return "latest/" + url.Substring(latest.Length);
            if (url.StartsWith(tagged, StringComparison.Ordinal))
                return url.Substring(tagged.Length);
            return "third-party/" + Path.GetFileName(new Uri(url).AbsolutePath);
        }

        static string GiteeTagged(string url)
        {
            if (GiteeRepository.Length == 0)
                return null;
            string tagged = ReleasesUrl + "download/";
            return url.StartsWith(tagged, StringComparison.Ordinal)
                ? $"https://gitee.com/{GiteeRepository}/releases/download/" + url.Substring(tagged.Length)
                : null;
        }

        static async Task<string> GiteeUrlAsync(string url)
        {
            string tagged = GiteeTagged(url);
            if (tagged != null)
                return tagged;
            string latest = ReleasesUrl + "latest/download/";
            if (GiteeRepository.Length == 0 || !url.StartsWith(latest, StringComparison.Ordinal))
                return null;
            string tag = await LatestGiteeTagAsync();
            return tag == null
                ? null
                : $"https://gitee.com/{GiteeRepository}/releases/download/{tag}/" + url.Substring(latest.Length);
        }

        static async Task<string> LatestGiteeTagAsync()
        {
            try
            {
                using CancellationTokenSource timeout = new CancellationTokenSource(TimeSpan.FromSeconds(15));
                string json = await Web.Client.GetStringAsync($"https://gitee.com/api/v5/repos/{GiteeRepository}/releases/latest", timeout.Token);
                using JsonDocument document = JsonDocument.Parse(json);
                return document.RootElement.TryGetProperty("tag_name", out JsonElement tag) ? tag.GetString() : null;
            }
            catch (Exception e) when (Web.IsProblem(e) || e is JsonException)
            {
                return null;
            }
        }

        static async Task<List<string>> SourcesAsync(string url, IEnumerable<string> alternates)
        {
            string gitee = await GiteeUrlAsync(url);
            List<string> sources = new List<string>();
            if (PreferMirror)
            {
                if (alternates != null)
                    sources.AddRange(alternates);
                if (gitee != null)
                    sources.Add(gitee);
                if (BaseUrl.Length > 0)
                    sources.Add(BaseUrl + "/" + KeyFor(url));
                sources.Add(url);
            }
            else
            {
                sources.Add(url);
                if (alternates != null)
                    sources.AddRange(alternates);
                if (gitee != null)
                    sources.Add(gitee);
                if (BaseUrl.Length > 0)
                    sources.Add(BaseUrl + "/" + KeyFor(url));
            }
            HashSet<string> seen = new HashSet<string>(StringComparer.Ordinal);
            return sources.Where(source => !string.IsNullOrEmpty(source) && seen.Add(source)).ToList();
        }

        public static Task<T> TryEachAsync<T>(string url, CancellationToken cancel, Func<string, Task<T>> fetch) =>
            TryEachAsync(url, null, cancel, fetch);

        public static async Task<T> TryEachAsync<T>(string url, IEnumerable<string> alternates, CancellationToken cancel, Func<string, Task<T>> fetch)
        {
            Exception firstProblem = null;
            foreach (string source in await SourcesAsync(url, alternates))
            {
                try
                {
                    return await fetch(source);
                }
                catch (Exception e) when (Web.IsProblem(e) && !cancel.IsCancellationRequested)
                {
                    firstProblem ??= e;
                    if (source == url)
                        PrimaryFailed = true;
                }
            }
            throw firstProblem;
        }

        public static Task TryEachAsync(string url, CancellationToken cancel, Func<string, Task> fetch) =>
            TryEachAsync(url, cancel, async source =>
            {
                await fetch(source);
                return true;
            });

        public static Task TryEachAsync(string url, IEnumerable<string> alternates, CancellationToken cancel, Func<string, Task> fetch) =>
            TryEachAsync(url, alternates, cancel, async source =>
            {
                await fetch(source);
                return true;
            });
    }
}

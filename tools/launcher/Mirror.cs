using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Threading;
using System.Threading.Tasks;

namespace HordesOfAzeroth.Launcher
{
    static class Mirror
    {
        static readonly string BaseUrl = (typeof(Mirror).Assembly
            .GetCustomAttributes(typeof(AssemblyMetadataAttribute), false)
            .OfType<AssemblyMetadataAttribute>()
            .FirstOrDefault(a => a.Key == "MirrorUrl")?.Value ?? "").TrimEnd('/');

        static readonly string[] ChinaTimeZones = { "China Standard Time", "Asia/Shanghai", "Asia/Urumqi", "Asia/Chongqing", "Asia/Harbin", "PRC" };

        static readonly bool InChina = ChinaTimeZones.Contains(TimeZoneInfo.Local.Id);

        static bool PrimaryFailed;

        static bool PreferMirror => InChina || PrimaryFailed;

        static string ReleasesUrl => $"https://github.com/{UpdateCheck.Repository}/releases/";

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

        static IEnumerable<string> Sources(string url)
        {
            if (BaseUrl.Length == 0)
                return new[] { url };
            string mirrored = BaseUrl + "/" + KeyFor(url);
            return PreferMirror ? new[] { mirrored, url } : new[] { url, mirrored };
        }

        public static async Task<T> TryEachAsync<T>(string url, CancellationToken cancel, Func<string, Task<T>> fetch)
        {
            Exception firstProblem = null;
            foreach (string source in Sources(url))
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
    }
}

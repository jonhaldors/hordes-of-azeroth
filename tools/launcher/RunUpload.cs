using System;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Reflection;
using System.Threading;
using System.Threading.Tasks;

namespace HordesOfAzeroth.Launcher
{
    static class RunUpload
    {
        static readonly string StatsUrl = (typeof(RunUpload).Assembly
            .GetCustomAttributes(typeof(AssemblyMetadataAttribute), false)
            .OfType<AssemblyMetadataAttribute>()
            .FirstOrDefault(a => a.Key == "StatsUrl")?.Value ?? "").TrimEnd('/');
        static readonly TimeSpan RunTimeout = TimeSpan.FromSeconds(20);
        static readonly TimeSpan BoardTimeout = TimeSpan.FromSeconds(30);
        static readonly HttpClient Client = CreateClient();
        static readonly TimeSpan ReportTimeout = TimeSpan.FromMinutes(3);

        public static bool IsConfigured => StatsUrl.Length > 0;

        static HttpClient CreateClient()
        {
            HttpClient client = new HttpClient(new SocketsHttpHandler
            {
                ConnectCallback = CoopAgent.ConnectPreferringIPv4Async,
                AutomaticDecompression = System.Net.DecompressionMethods.GZip,
            }) { Timeout = Timeout.InfiniteTimeSpan };
            client.DefaultRequestHeaders.UserAgent.ParseAdd("HordesOfAzerothLauncher");
            return client;
        }

        public static async Task<int> SendRunsAsync(GameFolder folder)
        {
            if (!IsConfigured)
                return 0;
            int sent = 0;
            foreach (string file in RunRecords.Pending(RunRecords.Outbox(folder)))
            {
                ByteArrayContent body = new ByteArrayContent(await File.ReadAllBytesAsync(file));
                body.Headers.ContentType = new MediaTypeHeaderValue("application/json");
                body.Headers.ContentEncoding.Add("gzip");
                (Delivery delivery, string problem) = await PostAsync("/run", body, RunTimeout);
                if (delivery == Delivery.TryLater)
                {
                    LauncherLog.Write(folder, "Run upload: " + problem);
                    break;
                }
                File.Delete(file);
                if (delivery == Delivery.Accepted)
                    ++sent;
            }
            return sent;
        }

        public static async Task<string> GetBoardAsync(string installId)
        {
            string own = StatsUrl + "/board?install=" + Uri.EscapeDataString(installId);
            string mirrored = Mirror.BoardUrl;
            Exception firstProblem = null;
            foreach (string source in mirrored.Length > 0 ? new[] { own, mirrored } : new[] { own })
            {
                try
                {
                    return await FetchBoardAsync(source);
                }
                catch (Exception e) when (Web.IsProblem(e))
                {
                    firstProblem ??= e;
                }
            }
            throw firstProblem;
        }

        static async Task<string> FetchBoardAsync(string url)
        {
            using (CancellationTokenSource timeout = new CancellationTokenSource(BoardTimeout))
            using (HttpResponseMessage response = await Client.GetAsync(url, timeout.Token))
            {
                response.EnsureSuccessStatusCode();
                return await response.Content.ReadAsStringAsync(timeout.Token);
            }
        }

        public static async Task<string> SendReportAsync(string zip)
        {
            ByteArrayContent body = new ByteArrayContent(await File.ReadAllBytesAsync(zip));
            body.Headers.ContentType = new MediaTypeHeaderValue("application/zip");
            using (CancellationTokenSource timeout = new CancellationTokenSource(ReportTimeout))
            using (HttpResponseMessage response = await Client.PostAsync(StatsUrl + "/report", body, timeout.Token))
            {
                response.EnsureSuccessStatusCode();
                return (await response.Content.ReadAsStringAsync(timeout.Token)).Trim();
            }
        }

        enum Delivery { Accepted, Refused, TryLater }

        static async Task<(Delivery, string)> PostAsync(string path, HttpContent body, TimeSpan limit)
        {
            try
            {
                using (CancellationTokenSource timeout = new CancellationTokenSource(limit))
                using (HttpResponseMessage response = await Client.PostAsync(StatsUrl + path, body, timeout.Token))
                    return (Judge((int)response.StatusCode), "the stats server answered " + (int)response.StatusCode);
            }
            catch (Exception e) when (Web.IsProblem(e))
            {
                return (Delivery.TryLater, e.InnerException != null ? e.Message + " (" + e.InnerException.Message + ")" : e.Message);
            }
        }

        static Delivery Judge(int status)
        {
            if (status >= 200 && status < 300)
                return Delivery.Accepted;
            if (status >= 400 && status < 500 && status != 408 && status != 429)
                return Delivery.Refused;
            return Delivery.TryLater;
        }
    }
}

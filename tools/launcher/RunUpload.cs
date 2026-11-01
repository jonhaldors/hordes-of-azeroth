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
        static readonly TimeSpan ReportTimeout = TimeSpan.FromMinutes(3);

        public static bool IsConfigured => StatsUrl.Length > 0;

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
                Delivery delivery = await PostAsync("/run", body, RunTimeout);
                if (delivery == Delivery.TryLater)
                    break;
                File.Delete(file);
                if (delivery == Delivery.Accepted)
                    ++sent;
            }
            return sent;
        }

        public static async Task<string> GetBoardAsync(string installId)
        {
            using (CancellationTokenSource timeout = new CancellationTokenSource(RunTimeout))
            using (HttpResponseMessage response = await Web.Client.GetAsync(StatsUrl + "/board?install=" + Uri.EscapeDataString(installId), timeout.Token))
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
            using (HttpResponseMessage response = await Web.Client.PostAsync(StatsUrl + "/report", body, timeout.Token))
            {
                response.EnsureSuccessStatusCode();
                return (await response.Content.ReadAsStringAsync(timeout.Token)).Trim();
            }
        }

        enum Delivery { Accepted, Refused, TryLater }

        static async Task<Delivery> PostAsync(string path, HttpContent body, TimeSpan limit)
        {
            try
            {
                using (CancellationTokenSource timeout = new CancellationTokenSource(limit))
                using (HttpResponseMessage response = await Web.Client.PostAsync(StatsUrl + path, body, timeout.Token))
                    return Judge((int)response.StatusCode);
            }
            catch (Exception e) when (Web.IsProblem(e))
            {
                return Delivery.TryLater;
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

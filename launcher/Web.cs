using System;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading;
using System.Threading.Tasks;

namespace HordesOfAzeroth.Launcher
{
    static class Web
    {
        const int BufferSize = 81920;
        static readonly TimeSpan ProgressInterval = TimeSpan.FromMilliseconds(100);

        public static readonly HttpClient Client = CreateClient();

        static HttpClient CreateClient()
        {
            HttpClient client = new HttpClient { Timeout = Timeout.InfiniteTimeSpan };
            client.DefaultRequestHeaders.UserAgent.ParseAdd("HordesOfAzerothLauncher");
            return client;
        }

        public static async Task DownloadAsync(string url, string partial, Action<long> report, CancellationToken cancel)
        {
            for (int attempt = 1; ; attempt++)
            {
                try
                {
                    await DownloadOnceAsync(url, partial, report, cancel);
                    return;
                }
                catch (Exception e) when (IsDropped(e, cancel))
                {
                    if (attempt >= AttemptsPerSource)
                        throw AsDownloadProblem(e);
                    await Task.Delay(TimeSpan.FromSeconds(2 * attempt), cancel);
                }
            }
        }

        const int AttemptsPerSource = 3;
        static readonly TimeSpan StallLimit = TimeSpan.FromSeconds(30);

        static bool IsDropped(Exception e, CancellationToken cancel)
        {
            if (cancel.IsCancellationRequested || e is LocalFileException)
                return false;
            if (e is HttpRequestException http)
                return IsPassingStatus(http.StatusCode);
            return e is IOException || e is OperationCanceledException || e is TimeoutException;
        }

        static bool IsPassingStatus(HttpStatusCode? status) =>
            status == null || (int)status >= 500 || status == HttpStatusCode.RequestTimeout || status == HttpStatusCode.TooManyRequests;

        static HttpRequestException AsDownloadProblem(Exception e)
        {
            if (e is HttpRequestException http)
                return http;
            if (e is OperationCanceledException)
                return new HttpRequestException(Loc.T("hoa.launcher.no_data_arrived_for_0_0_seconds", StallLimit.TotalSeconds), e);
            return new HttpRequestException(e.Message, e);
        }

        sealed class LocalFileException : InvalidOperationException
        {
            public LocalFileException(string path, Exception cause)
                : base(Loc.T("hoa.launcher.couldn_t_write_0_1", Path.GetFileName(path), cause.Message.TrimEnd('.')), cause)
            {
            }
        }

        static async Task<T> OnDisk<T>(string path, Func<Task<T>> work)
        {
            try
            {
                return await work();
            }
            catch (Exception e) when (e is IOException || e is UnauthorizedAccessException)
            {
                throw new LocalFileException(path, e);
            }
        }

        static Task OnDisk(string path, Func<Task> work) =>
            OnDisk(path, async () =>
            {
                await work();
                return true;
            });

        static void DeleteMismatchedPartial(string partial)
        {
            try
            {
                File.Delete(partial);
            }
            catch (Exception e) when (e is IOException || e is UnauthorizedAccessException)
            {
                throw new LocalFileException(partial, e);
            }
        }

        static async Task DownloadOnceAsync(string url, string partial, Action<long> report, CancellationToken cancel)
        {
            long have = File.Exists(partial) ? new FileInfo(partial).Length : 0;
            using (CancellationTokenSource stall = CancellationTokenSource.CreateLinkedTokenSource(cancel))
            using (HttpRequestMessage request = new HttpRequestMessage(HttpMethod.Get, url))
            {
                if (have > 0)
                    request.Headers.Range = new RangeHeaderValue(have, null);
                stall.CancelAfter(StallLimit);
                using (HttpResponseMessage response = await Client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, stall.Token))
                {
                    if (have > 0 && response.StatusCode == HttpStatusCode.RequestedRangeNotSatisfiable)
                    {
                        long? total = response.Content.Headers.ContentRange?.Length;
                        if (total == null || total == have)
                        {
                            report(have);
                            return;
                        }
                        DeleteMismatchedPartial(partial);
                        throw new HttpRequestException(Loc.T("hoa.launcher.the_partly_downloaded_file_didn_t_match_and_was_started_over"));
                    }
                    response.EnsureSuccessStatusCode();
                    bool resumed = have > 0 && response.StatusCode == HttpStatusCode.PartialContent;
                    long received = resumed ? have : 0;
                    using (Stream source = await response.Content.ReadAsStreamAsync(stall.Token))
                    using (FileStream file = await OnDisk(partial, () => Task.FromResult(new FileStream(partial, resumed ? FileMode.Append : FileMode.Create, FileAccess.Write, FileShare.None, BufferSize, true))))
                    {
                        byte[] buffer = new byte[BufferSize];
                        DateTime lastReport = DateTime.MinValue;
                        report(received);
                        int read;
                        while ((read = await source.ReadAsync(buffer, 0, buffer.Length, stall.Token)) > 0)
                        {
                            stall.CancelAfter(StallLimit);
                            await OnDisk(partial, () => file.WriteAsync(buffer, 0, read, cancel));
                            received += read;
                            if (DateTime.UtcNow - lastReport >= ProgressInterval)
                            {
                                lastReport = DateTime.UtcNow;
                                report(received);
                            }
                        }
                        await OnDisk(partial, () => file.FlushAsync(cancel));
                        report(received);
                    }
                }
            }
        }

        public static string Describe(Exception e)
        {
            if (e is HttpRequestException http && http.StatusCode != null)
            {
                if (http.StatusCode == HttpStatusCode.NotFound)
                    return Loc.T("hoa.launcher.no_release_is_published_yet");
                return Loc.T("hoa.launcher.github_answered_with_an_error_0_try_again_in_a_moment", (int)http.StatusCode);
            }
            if (e is HttpRequestException || e is TaskCanceledException)
                return Loc.T("hoa.launcher.couldn_t_reach_github_check_your_connection_and_try_again");
            return Loc.T("hoa.launcher.the_release_information_couldn_t_be_read_try_again_in_a_mome");
        }

        public static bool IsProblem(Exception e) => e is HttpRequestException || e is TaskCanceledException;
    }
}

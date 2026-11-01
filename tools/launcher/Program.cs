using System;
using System.IO;
using System.IO.Pipes;
using System.Threading;
using System.Threading.Tasks;
using Avalonia;

namespace HordesOfAzeroth.Launcher
{
    static class Program
    {
        const string InstanceName = "HordesOfAzerothLauncher";
        const string ShowPipe = InstanceName + ".Show";
        const int RestartWaitMs = 3000;
        const int ShowConnectMs = 1000;

        static Mutex s_single;

        public static event Action ShowRequested;

        [STAThread]
        static int Main(string[] args)
        {
            if (Array.IndexOf(args, "--coop-agent") >= 0)
                return RunCoopAgent();
            int source = Array.IndexOf(args, "--source");
            if (source >= 0 && source + 1 < args.Length)
                UpdateCheck.LocalSource = args[source + 1];
            s_single = new Mutex(true, InstanceName, out bool first);
            if (!first && !OwnAfterRestart())
            {
                AskRunningLauncherToShow();
                return 0;
            }
            AppDomain.CurrentDomain.UnhandledException += (_, e) => CrashReports.RecordLauncherCrash(e.ExceptionObject as Exception ?? new Exception(e.ExceptionObject?.ToString()));
            ListenForShowRequests();
            try
            {
                return BuildAvaloniaApp().StartWithClassicDesktopLifetime(args, Avalonia.Controls.ShutdownMode.OnExplicitShutdown);
            }
            finally
            {
                s_single.Dispose();
            }
        }

        static int RunCoopAgent()
        {
            using CoopAgent agent = new CoopAgent(GameFolder.Find());
            agent.Start();
            Console.WriteLine("Co-op agent running.");
            Thread.Sleep(Timeout.Infinite);
            return 0;
        }

        public static AppBuilder BuildAvaloniaApp() =>
            AppBuilder.Configure<App>().UsePlatformDetect().WithInterFont();

        static bool OwnAfterRestart()
        {
            try
            {
                return s_single.WaitOne(RestartWaitMs);
            }
            catch (AbandonedMutexException)
            {
                return true;
            }
        }

        static void AskRunningLauncherToShow()
        {
            try
            {
                using (NamedPipeClientStream pipe = new NamedPipeClientStream(".", ShowPipe, PipeDirection.Out))
                    pipe.Connect(ShowConnectMs);
            }
            catch (Exception e) when (e is TimeoutException || e is IOException)
            {
            }
        }

        static void ListenForShowRequests()
        {
            Task.Run(async () =>
            {
                while (true)
                {
                    try
                    {
                        using (NamedPipeServerStream pipe = new NamedPipeServerStream(ShowPipe, PipeDirection.In, 1))
                        {
                            await pipe.WaitForConnectionAsync();
                            ShowRequested?.Invoke();
                        }
                    }
                    catch (IOException)
                    {
                        await Task.Delay(1000);
                    }
                }
            });
        }
    }
}

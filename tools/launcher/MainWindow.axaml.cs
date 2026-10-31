using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Avalonia;
using Avalonia.Controls;
using Avalonia.Controls.Documents;
using Avalonia.Interactivity;
using Avalonia.Layout;
using Avalonia.Media;
using Avalonia.Media.Imaging;
using Avalonia.Platform;
using Avalonia.Platform.Storage;
using Avalonia.Threading;

namespace HordesOfAzeroth.Launcher
{
    public partial class MainWindow : Window
    {
        const string NewIssueUrl = "https://github.com/jonhaldors/hordes-of-azeroth/issues/new";
        const string DiscordUrl = "https://discord.gg/zpYfsqh6Dn";
        const string CoffeeUrl = "https://buymeacoffee.com/jonhaldors";
        static readonly TimeSpan UpdateInterval = TimeSpan.FromMinutes(15);
        const string FullRepairText = "The launcher checks every game file, puts back the ones that are missing or damaged and reloads the world. Your characters and unlocks are backed up first and stay as they are.";
        const string QuickRepairText = "Some game files were missing or damaged, so the launcher puts them back. Your characters and unlocks stay as they are.";

        enum LauncherState { Missing, NotInstalled, Installing, Ready, UpdateAvailable, Starting, Playing, Stopping }

        readonly GameFolder m_folder = GameFolder.Find();
        readonly LocalServer m_server;
        readonly GameClient m_game;
        readonly UpdateCheck m_updates;
        readonly LauncherSettings m_settings;
        readonly Installer m_installer;
        readonly NavBuilder m_nav;
        readonly AccountSync m_accountSync;
        readonly SaveBackups m_saves;
        Accounts m_accounts;
        string m_busyButton;
        static readonly TimeSpan MenuReclickWindow = TimeSpan.FromMilliseconds(300);
        readonly Dictionary<ContextMenu, DateTime> m_menuClosedAt = new Dictionary<ContextMenu, DateTime>();
        CancellationTokenSource m_background;
        NavProgress m_backgroundProgress;
        readonly DispatcherTimer m_updateTimer = new DispatcherTimer();
        TrayIcon m_tray;
        LauncherState m_state;
        Manifest m_latest;
        List<ReleaseNote> m_notes = new List<ReleaseNote>();
        int m_notePage;
        bool m_quitting;
        bool m_askingToClose;
        CancellationTokenSource m_installCancel;
        bool m_updating;
        bool m_repairing;

        public MainWindow()
        {
            InitializeComponent();
            m_server = new LocalServer(m_folder);
            m_game = new GameClient(m_folder);
            m_updates = new UpdateCheck(m_folder);
            m_settings = LauncherSettings.Load(m_folder);
            m_installer = new Installer(m_folder, m_server);
            m_nav = new NavBuilder(m_folder);
            m_accounts = Accounts.Load(m_folder);
            m_accountSync = new AccountSync(m_server, m_folder);
            m_saves = new SaveBackups(m_folder, m_server, m_installer);
            WatchMenuClosing(AccountMenu, LanguageMenu, OptionsMenu);
            Opened += OnOpened;
            Closing += OnClosing;
            Program.ShowRequested += () => Dispatcher.UIThread.Post(ShowFromTray);
        }

        IBrush Brush(string key) => (IBrush)Application.Current.FindResource(key);

        async void OnOpened(object sender, EventArgs e)
        {
            Installer.RemoveOldLauncher();
            ClientFonts.Load(m_folder);
            TitleText.FontFamily = ClientFonts.Title;
            Tagline.FontFamily = ClientFonts.Body;
            LoadArt();
            ShowLanguage();
            ShowAccount();
            CreateTray();

            m_latest = m_updates.LoadCached();
            ShowNotes(m_latest?.Notes);
            RefreshState();

            m_updateTimer.Interval = UpdateInterval;
            m_updateTimer.Tick += async (s, a) => await CheckForUpdatesAsync(false);
            m_updateTimer.Start();
            await CheckForUpdatesAsync(false);

            await AskAboutRunDataAsync();
            await ShareRunsAsync();
            await OfferCrashReportAsync();

            if (m_game.IsRunning)
                await WatchRunningGameAsync();
            else
                StartBackgroundBuild();
        }

        async Task AskAboutRunDataAsync()
        {
            if (m_settings.RunDataAsked)
                return;
            string question = "Hordes of Azeroth is in early access. Can the launcher send data about your runs to help balance the game?\n\n"
                + "After each run it sends your build, picks, boss times and how the run ended, with a random id for this install. No names, chat or files. "
                + "You can turn it off any time in the … menu.";
            m_settings.SendRunData = await Dialog.AskAsync(this, question);
            m_settings.RunDataAsked = true;
            m_settings.Save();
        }

        async Task OfferCrashReportAsync()
        {
            DateTime since = new DateTime(m_settings.CrashCheckedAt, DateTimeKind.Utc);
            bool firstCheck = m_settings.CrashCheckedAt == 0;
            m_settings.CrashCheckedAt = DateTime.UtcNow.Ticks;
            m_settings.Save();
            if (firstCheck || !m_settings.AskToSendCrashes || !RunUpload.IsConfigured)
                return;
            List<string> crashed = CrashReports.CrashedSince(m_folder, since);
            if (crashed.Count == 0)
                return;
            string what = string.Join(" and ", crashed);
            string question = $"{char.ToUpperInvariant(what[0])}{what.Substring(1)} crashed last time. Send a crash report to the developer?\n\n"
                + "It holds the game's server and client logs, your character names and your game settings. You'll get a reference to put in your bug report.";
            if (!await Dialog.AskAsync(this, question))
                return;
            try
            {
                string reference = await CrashReports.SendAsync(m_folder, crashed);
                await Dialog.TellAsync(this, $"Your crash report was sent. Reference: {reference}\n\nPut this reference in your bug report on GitHub or Discord.");
            }
            catch (Exception e) when (e is IOException || e is UnauthorizedAccessException || Web.IsProblem(e))
            {
                LauncherLog.Write(m_folder, "Crash report: " + e.Message);
                ShowProblem("The crash report couldn't be sent", "Use Report a bug to save your logs and attach them to your bug report.");
            }
        }

        async Task ShareRunsAsync()
        {
            try
            {
                long offset = m_settings.RunLogOffset;
                bool send = m_settings.SendRunData;
                long next = await Task.Run(() => ServerLogTrim.Trim(m_folder, send ? RunRecords.Collect(m_folder, m_settings, offset) : RunRecords.SkipTo(m_folder)));
                m_settings.RunLogOffset = next;
                m_settings.Save();
                if (send)
                    await RunUpload.SendRunsAsync(m_folder);
            }
            catch (Exception e) when (e is IOException || e is UnauthorizedAccessException || Web.IsProblem(e))
            {
                LauncherLog.Write(m_folder, "Run data: " + e.Message);
            }
        }

        void LoadArt()
        {
            foreach (string candidate in new[] { Path.Combine(m_folder.LauncherData, "launcher-art.jpg"), Path.Combine(m_folder.LauncherData, "launcher-art.png") })
            {
                if (!File.Exists(candidate))
                    continue;
                try
                {
                    Art.Source = new Bitmap(candidate);
                    return;
                }
                catch (Exception e) when (e is IOException || e is ArgumentException || e is InvalidOperationException)
                {
                }
            }
            using (Stream art = AssetLoader.Open(new Uri("avares://HoALauncher/art/background.jpg")))
                Art.Source = new Bitmap(art);
        }

        void CreateTray()
        {
            if (!Platform.HasTray)
                return;
            NativeMenu menu = new NativeMenu();
            NativeMenuItem open = new NativeMenuItem("Open launcher");
            open.Click += (s, e) => ShowFromTray();
            NativeMenuItem quit = new NativeMenuItem("Quit");
            quit.Click += (s, e) => QuitFromTray();
            menu.Items.Add(open);
            menu.Items.Add(quit);
            m_tray = new TrayIcon
            {
                Icon = new WindowIcon(AssetLoader.Open(new Uri("avares://HoALauncher/art/icon.ico"))),
                ToolTipText = "Hordes of Azeroth",
                Menu = menu,
                IsVisible = true,
            };
            m_tray.Clicked += (s, e) => ShowFromTray();
            TrayIcon.SetIcons(Application.Current, new TrayIcons { m_tray });
        }

        public void ShowFromTray()
        {
            Show();
            if (WindowState == WindowState.Minimized)
                WindowState = WindowState.Normal;
            Activate();
        }

        void TuckAway()
        {
            if (Platform.HasTray)
                Hide();
            else
                WindowState = WindowState.Minimized;
        }

        async void QuitFromTray()
        {
            if (m_state == LauncherState.Playing || m_state == LauncherState.Starting)
            {
                ShowFromTray();
                await Dialog.TellAsync(this, "Close the game first. The launcher keeps the game's server running until then.");
                return;
            }
            m_quitting = true;
            Close();
        }

        async void OnClosing(object sender, WindowClosingEventArgs e)
        {
            if (m_quitting)
            {
                Shutdown();
                return;
            }
            if (m_state == LauncherState.Starting || m_state == LauncherState.Playing || m_state == LauncherState.Stopping)
            {
                e.Cancel = true;
                TuckAway();
                return;
            }
            if (m_state == LauncherState.Installing)
            {
                e.Cancel = true;
                if (m_askingToClose)
                    return;
                m_askingToClose = true;
                bool stop = await Dialog.AskAsync(this, "Stop installing? The launcher carries on where it stopped next time.");
                m_askingToClose = false;
                if (!stop)
                    return;
                m_installCancel?.Cancel();
                m_quitting = true;
                Close();
                return;
            }
            Shutdown();
        }

        void Shutdown()
        {
            m_updateTimer.Stop();
            m_background?.Cancel();
            if (m_tray != null)
            {
                m_tray.IsVisible = false;
                m_tray.Dispose();
                m_tray = null;
            }
            if (Application.Current.ApplicationLifetime is Avalonia.Controls.ApplicationLifetimes.IClassicDesktopStyleApplicationLifetime desktop)
                desktop.Shutdown();
        }

        void RefreshState()
        {
            GameVersion installed = m_folder.InstalledVersion;
            InstalledText.Text = installed != null ? installed.PatchName + " installed" : "Not installed";

            if (m_state == LauncherState.Starting || m_state == LauncherState.Playing || m_state == LauncherState.Stopping || m_state == LauncherState.Installing)
                return;

            if (!m_folder.HasClient)
            {
                SetState(LauncherState.Missing, "Can't find World of Warcraft", "Put the launcher in your World of Warcraft 1.12.1 folder, next to WoW.exe.");
                return;
            }
            if (!IsInstalled())
            {
                if (!Installer.IsStockClient(m_folder))
                    SetState(LauncherState.Missing, "This client can't be used", "Hordes of Azeroth needs the English World of Warcraft 1.12.1 (build 5875) WoW.exe.");
                else if (m_installer.IsComplete)
                    SetState(LauncherState.NotInstalled, "Some game files are missing", "press Repair to put them back");
                else if (m_installer.CompletedSteps.Count > 0)
                    SetState(LauncherState.NotInstalled, "The install isn't finished", "press Continue to carry on where it stopped");
                else
                    SetState(LauncherState.NotInstalled, "Ready to install", "the first install takes a few minutes");
                return;
            }
            if (m_latest?.Version != null && (m_latest.Version.IsNewerThan(installed) || m_installer.ChangedPackages(m_latest).Count > 0))
            {
                string size = m_latest.DownloadSize > 0 ? $"{m_latest.DownloadSize / 1048576.0:0.0} MB · " : "";
                SetState(LauncherState.UpdateAvailable, m_latest.Version.PatchName + " is ready", size + "your characters and unlocks stay");
                return;
            }
            SetState(LauncherState.Ready, "Ready to play", "");
            ShowBackgroundProgress();
        }

        bool IsInstalled()
        {
            if (m_folder.InstalledVersion == null || !File.Exists(m_folder.GameExe) || !File.Exists(Path.Combine(m_folder.ServerRun, Platform.Exe("mangosd"))))
                return false;
            bool installedByLauncher = File.Exists(Path.Combine(m_folder.LauncherData, "install-steps.txt"));
            if (installedByLauncher && !m_installer.IsComplete)
                return false;
            NavGroup first = m_latest?.NavGroups.FirstOrDefault();
            return first == null || m_nav.IsGroupBuilt(first);
        }

        void ShowProgress(bool visible) => Progress.Opacity = visible ? 1 : 0;

        void SetState(LauncherState state, string status, string detail)
        {
            m_state = state;
            StatusText.Text = status;
            StatusText.Foreground = Brush(state == LauncherState.Missing ? "Problem" : "Text");
            StatusDetail.Text = string.IsNullOrEmpty(detail) ? "" : "   " + detail;
            StatusDot.IsVisible = state == LauncherState.Ready || state == LauncherState.Playing;
            bool busy = state == LauncherState.Starting || state == LauncherState.Stopping || state == LauncherState.Installing;
            Progress.IsIndeterminate = busy;
            Progress.Value = 0;
            ShowProgress(busy);
            switch (state)
            {
                case LauncherState.Missing:
                    PrimaryButton.Content = "Install";
                    PrimaryButton.IsEnabled = false;
                    break;
                case LauncherState.NotInstalled:
                    PrimaryButton.Content = m_installer.IsComplete ? "Repair" : m_installer.CompletedSteps.Count > 0 ? "Continue" : "Install";
                    PrimaryButton.IsEnabled = true;
                    break;
                case LauncherState.Installing:
                    PrimaryButton.Content = m_busyButton ?? (m_repairing ? "Repairing…" : m_updating ? "Updating…" : "Installing…");
                    PrimaryButton.IsEnabled = false;
                    break;
                case LauncherState.UpdateAvailable:
                    PrimaryButton.Content = "Update";
                    PrimaryButton.IsEnabled = true;
                    break;
                case LauncherState.Starting:
                    PrimaryButton.Content = "Starting…";
                    PrimaryButton.IsEnabled = false;
                    break;
                case LauncherState.Playing:
                    PrimaryButton.Content = "Playing";
                    PrimaryButton.IsEnabled = false;
                    break;
                case LauncherState.Stopping:
                    PrimaryButton.Content = "Closing…";
                    PrimaryButton.IsEnabled = false;
                    break;
                default:
                    PrimaryButton.Content = "Play";
                    PrimaryButton.IsEnabled = true;
                    break;
            }
            AccountButton.IsEnabled = !busy && state != LauncherState.Playing;
        }

        void ShowProblem(string status, string detail)
        {
            LauncherLog.Write(m_folder, $"{status}: {detail}");
            StatusText.Text = status;
            StatusText.Foreground = Brush("Problem");
            StatusDetail.Text = "   " + detail;
            StatusDot.IsVisible = false;
            Progress.IsIndeterminate = false;
            Progress.Value = 0;
            ShowProgress(false);
        }

        async Task CheckForUpdatesAsync(bool userAsked)
        {
            try
            {
                m_latest = await m_updates.FetchAsync();
                if (await RefreshLauncherFirstAsync(m_latest))
                    return;
                m_updates.PublishLatestVersion(m_latest);
                ShowNotes(m_latest.Notes);
                RefreshState();
                if (userAsked && m_state == LauncherState.Ready)
                    StatusDetail.Text = "   up to date";
            }
            catch (Exception e) when (Web.IsProblem(e) || e is IOException || e is InvalidOperationException || e is ArgumentException || e is KeyNotFoundException || e is InvalidCastException || e is System.Text.Json.JsonException)
            {
                if (m_latest == null)
                    ShowNotes(null);
                if (userAsked)
                    ShowProblem("Couldn't check for updates", Web.Describe(e));
            }
        }

        async Task<bool> RefreshLauncherFirstAsync(Manifest manifest)
        {
            if (!IsInstalled() || (m_state != LauncherState.Ready && m_state != LauncherState.UpdateAvailable) || m_game.IsRunning || !m_installer.LauncherOutdated(manifest))
                return false;
            StatusText.Text = "Updating the launcher";
            StatusDetail.Text = "";
            await m_installer.RefreshLauncherAsync(manifest, CancellationToken.None);
            RestartLauncher();
            return true;
        }

        void ShowNotes(List<ReleaseNote> notes)
        {
            if (notes == null || notes.Count == 0)
                notes = m_updates.LocalNotes();
            m_notes = notes.OrderByDescending(n => n.Version).ToList();
            m_notePage = 0;
            ShowNotePage();
        }

        void ShowNotePage()
        {
            NotesPanel.Children.Clear();
            NotesScroll.Offset = default;
            NotesPanel.Children.Add(new TextBlock
            {
                Text = "PATCH NOTES",
                FontSize = 11,
                FontWeight = FontWeight.Bold,
                Foreground = Brush("Accent"),
            });
            if (m_notes.Count == 0)
            {
                NotesPager.IsVisible = false;
                NotesPanel.Children.Add(Paragraph("Patch notes appear here once the launcher can reach GitHub.", Brush("Muted")));
                return;
            }
            ReleaseNote note = m_notes[m_notePage];
            NotesPanel.Children.Add(new TextBlock
            {
                Text = note.Version.PatchName,
                FontSize = 20,
                FontWeight = FontWeight.Bold,
                Foreground = Brush("Text"),
                Margin = new Thickness(0, 4, 0, 8),
            });
            foreach (string line in note.Text.Split('\n').Select(l => l.TrimEnd('\r')).Where(l => l.Trim().Length > 0))
                NotesPanel.Children.Add(NoteLine(line));
            ShowNotePager();
        }

        void ShowNotePager()
        {
            NotesPager.IsVisible = m_notes.Count > 1;
            OlderNotes.IsEnabled = m_notePage < m_notes.Count - 1;
            NewerNotes.IsEnabled = m_notePage > 0;
            NotePageText.Text = $"{m_notePage + 1} of {m_notes.Count}";
        }

        void OlderNotes_Click(object sender, RoutedEventArgs e)
        {
            if (m_notePage >= m_notes.Count - 1)
                return;
            m_notePage++;
            ShowNotePage();
        }

        void NewerNotes_Click(object sender, RoutedEventArgs e)
        {
            if (m_notePage <= 0)
                return;
            m_notePage--;
            ShowNotePage();
        }

        Control NoteLine(string line)
        {
            IBrush colour = Brush("Text");
            string trimmed = line.TrimStart();
            if (trimmed.StartsWith("#### "))
                return NoteSubheading(trimmed.Substring(5).Trim());
            if (trimmed.StartsWith("### "))
                return NoteHeading(trimmed.Substring(4).Trim());
            if (!trimmed.StartsWith("- "))
                return NoteText(trimmed, colour);
            Grid row = new Grid { Margin = new Thickness(0, 0, 0, 6), ColumnDefinitions = new ColumnDefinitions("16,*") };
            row.Children.Add(new TextBlock { Text = "•", Foreground = colour, FontSize = 13 });
            TextBlock text = NoteText(trimmed.Substring(2), colour);
            text.Margin = new Thickness(0);
            Grid.SetColumn(text, 1);
            row.Children.Add(text);
            return row;
        }

        TextBlock NoteText(string text, IBrush colour)
        {
            TextBlock block = Paragraph("", colour);
            block.Inlines = new InlineCollection();
            bool afterOldValue = false;
            int at = 0;
            while (at < text.Length)
            {
                int strike = text.IndexOf("~~", at, StringComparison.Ordinal);
                int bold = text.IndexOf("**", at, StringComparison.Ordinal);
                int next = strike < 0 ? bold : bold < 0 ? strike : Math.Min(strike, bold);
                int close = next < 0 ? -1 : text.IndexOf(text.Substring(next, 2), next + 2, StringComparison.Ordinal);
                if (close < 0)
                {
                    block.Inlines.Add(new Run(text.Substring(at)));
                    break;
                }
                string between = text.Substring(at, next - at);
                if (between.Length > 0)
                    block.Inlines.Add(new Run(between));
                string inner = text.Substring(next + 2, close - next - 2);
                if (next == strike)
                {
                    block.Inlines.Add(new Run(inner) { Foreground = Brush("NoteOldValue") });
                    afterOldValue = true;
                }
                else
                {
                    bool isNewValue = afterOldValue && between.Trim().Length <= 2;
                    block.Inlines.Add(new Run(inner) { FontWeight = FontWeight.SemiBold, Foreground = isNewValue ? Brush("NoteNewValue") : colour });
                    afterOldValue = false;
                }
                at = close + 2;
            }
            return block;
        }

        TextBlock NoteHeading(string text)
        {
            return new TextBlock
            {
                Text = text.ToUpperInvariant(),
                FontSize = 14,
                FontWeight = FontWeight.Bold,
                Foreground = Brush("Accent"),
                Margin = new Thickness(0, 12, 0, 6),
            };
        }

        TextBlock NoteSubheading(string text)
        {
            return new TextBlock
            {
                Text = text.ToUpperInvariant(),
                FontSize = 11,
                FontWeight = FontWeight.Bold,
                Foreground = Brush("Text"),
                Margin = new Thickness(0, 6, 0, 4),
            };
        }

        static TextBlock Paragraph(string text, IBrush colour)
        {
            return new TextBlock { Text = text, Foreground = colour, FontSize = 13, LineHeight = 19, TextWrapping = TextWrapping.Wrap, Margin = new Thickness(0, 0, 0, 8) };
        }

        async void PrimaryButton_Click(object sender, RoutedEventArgs e)
        {
            if (m_state == LauncherState.UpdateAvailable)
            {
                await UpdateAsync();
                return;
            }
            if (m_state == LauncherState.Ready)
                await PlayAsync();
            else if (m_state == LauncherState.NotInstalled && m_installer.IsComplete)
                await RepairAsync(false);
            else if (m_state == LauncherState.NotInstalled)
                await InstallAsync();
        }

        async Task InstallAsync()
        {
            m_background?.Cancel();
            m_installCancel = new CancellationTokenSource();
            SetState(LauncherState.Installing, "Getting ready", "");
            ShowInstallCard(0);
            IProgress<InstallProgress> progress = new Progress<InstallProgress>(p =>
            {
                if (m_state != LauncherState.Installing)
                    return;
                ShowInstallCard(Array.IndexOf(Installer.Steps, p.Step));
                ShowStepProgress(p);
            });
            try
            {
                m_latest = await m_updates.FetchAsync();
                if (await m_installer.RefreshLauncherBeforeResumingAsync(m_latest, m_installCancel.Token))
                {
                    RestartLauncher();
                    return;
                }
                await m_installer.InstallAsync(m_latest, progress, m_installCancel.Token);
                if (m_latest.NavGroups.Count > 0)
                {
                    ShowInstallCard(Installer.Steps.Length);
                    await GetInstallPathsAsync(m_latest, m_installCancel.Token);
                }
                m_updates.PublishLatestVersion(m_latest);
                m_state = LauncherState.Ready;
                ShowNotes(m_latest.Notes);
                RefreshState();
                StartBackgroundBuild();
            }
            catch (OperationCanceledException)
            {
                await m_server.StopAsync();
            }
            catch (Exception e) when (!(e is OutOfMemoryException))
            {
                await m_server.StopAsync();
                m_state = LauncherState.NotInstalled;
                RefreshState();
                ShowProblem("The install stopped", e.Message);
            }
        }

        async Task UpdateAsync()
        {
            if (m_game.IsRunning)
            {
                ShowProblem("Close the game first", "the update replaces files the game has open");
                return;
            }
            Manifest manifest = m_latest;
            m_background?.Cancel();
            m_installCancel = new CancellationTokenSource();
            m_updating = true;
            string title = "Updating to " + manifest.Version.PatchName;
            const string explanation = "Your characters and unlocks are backed up first and stay as they are. You can close the launcher and come back; it carries on where it stopped.";
            SetState(LauncherState.Installing, "Getting ready", "");
            ShowStepsCard("UPDATE", title, explanation, Installer.UpdateSteps, 0);
            IProgress<InstallProgress> progress = new Progress<InstallProgress>(p =>
            {
                if (m_state != LauncherState.Installing)
                    return;
                ShowStepsCard("UPDATE", title, explanation, Installer.UpdateSteps, Array.IndexOf(Installer.UpdateSteps, p.Step));
                ShowStepProgress(p);
            });
            try
            {
                bool launcherChanged = await m_installer.UpdateAsync(manifest, progress, m_installCancel.Token);
                await GetInstallPathsAsync(manifest, m_installCancel.Token);
                m_updates.PublishLatestVersion(manifest);
                if (launcherChanged)
                {
                    RestartLauncher();
                    return;
                }
                m_updating = false;
                m_state = LauncherState.Ready;
                ShowNotes(manifest.Notes);
                RefreshState();
                StatusDetail.Text = $"   updated to {manifest.Version.PatchName}";
                StartBackgroundBuild();
            }
            catch (OperationCanceledException)
            {
                m_updating = false;
            }
            catch (Exception e) when (!(e is OutOfMemoryException))
            {
                m_updating = false;
                m_state = LauncherState.Ready;
                RefreshState();
                ShowProblem("The update stopped", e.Message);
            }
        }

        async Task RepairAsync(bool thorough)
        {
            if (m_game.IsRunning)
            {
                ShowProblem("Close the game first", "the repair replaces files the game has open");
                return;
            }
            m_background?.Cancel();
            m_installCancel = new CancellationTokenSource();
            m_repairing = true;
            string explanation = thorough ? FullRepairText : QuickRepairText;
            SetState(LauncherState.Installing, "Getting ready", "");
            ShowRepairCard(0, explanation);
            IProgress<InstallProgress> progress = new Progress<InstallProgress>(p =>
            {
                if (m_state != LauncherState.Installing)
                    return;
                ShowRepairCard(Array.IndexOf(Installer.RepairSteps, p.Step), explanation);
                ShowStepProgress(p);
            });
            try
            {
                await m_server.StopAsync();
                Manifest manifest = await LatestManifestAsync();
                await m_installer.RepairAsync(manifest, thorough, progress, m_installCancel.Token);
                await m_server.StopAsync();
                await GetInstallPathsAsync(manifest, m_installCancel.Token);
                m_updates.PublishLatestVersion(manifest);
                m_repairing = false;
                m_state = LauncherState.Ready;
                ShowNotes(manifest.Notes);
                RefreshState();
                if (m_state == LauncherState.Ready)
                    StatusDetail.Text = "   the game is repaired";
                StartBackgroundBuild();
            }
            catch (OperationCanceledException)
            {
                m_repairing = false;
                await m_server.StopAsync();
            }
            catch (Exception e) when (!(e is OutOfMemoryException))
            {
                m_repairing = false;
                await m_server.StopAsync();
                m_state = LauncherState.Ready;
                RefreshState();
                ShowProblem("The repair stopped", e.Message);
            }
        }

        async Task<Manifest> LatestManifestAsync()
        {
            try
            {
                return m_latest = await m_updates.FetchAsync();
            }
            catch (Exception e) when (m_latest != null && (Web.IsProblem(e) || e is IOException))
            {
                return m_latest;
            }
        }

        void ShowRepairCard(int current, string explanation) =>
            ShowStepsCard("REPAIR", "Repairing Hordes of Azeroth", explanation, Installer.RepairSteps, current);

        void ShowStepProgress(InstallProgress p)
        {
            StatusText.Text = Installer.InProgress(p.Step);
            StatusDetail.Text = string.IsNullOrEmpty(p.Detail) ? "" : "   " + p.Detail;
            Progress.IsIndeterminate = p.Fraction < 0;
            if (p.Fraction >= 0)
                Progress.Value = p.Fraction;
        }

        void RestartLauncher()
        {
            string exe = Environment.ProcessPath;
            string current = Path.Combine(Path.GetDirectoryName(exe), Installer.LauncherFileName);
            if (File.Exists(current))
                exe = current;
            ProcessStartInfo restart = new ProcessStartInfo(exe) { UseShellExecute = false, WorkingDirectory = Path.GetDirectoryName(exe) };
            if (UpdateCheck.LocalSource != null)
            {
                restart.ArgumentList.Add("--source");
                restart.ArgumentList.Add(UpdateCheck.LocalSource);
            }
            m_quitting = true;
            if (m_tray != null)
                m_tray.IsVisible = false;
            Process.Start(restart);
            Shutdown();
        }

        TextBlock Kicker(string text) => new TextBlock { Text = text, FontSize = 11, FontWeight = FontWeight.Bold, Foreground = Brush("Accent") };

        TextBlock CardTitle(string text) => new TextBlock
        {
            Text = text,
            FontSize = 18,
            FontWeight = FontWeight.Bold,
            Foreground = Brush("Text"),
            TextWrapping = TextWrapping.Wrap,
            Margin = new Thickness(0, 4, 0, 8),
        };

        void AddChecklist(string[] steps, int current)
        {
            for (int i = 0; i < steps.Length; i++)
            {
                bool done = i < current;
                bool now = i == current;
                NotesPanel.Children.Add(new TextBlock
                {
                    Text = (done ? "✓  " : now ? "▸  " : "·  ") + steps[i],
                    FontSize = 12.5,
                    FontWeight = now ? FontWeight.SemiBold : FontWeight.Normal,
                    Foreground = Brush(now ? "Text" : "Muted"),
                    Opacity = done || now ? 1 : 0.6,
                    Margin = new Thickness(0, i == 0 ? 6 : 2, 0, 2),
                });
            }
        }

        void ShowInstallCard(int current)
        {
            NotesPanel.Children.Clear();
            NotesPager.IsVisible = false;
            NotesPanel.Children.Add(Kicker("FIRST INSTALL"));
            bool paths = current >= Installer.Steps.Length;
            NotesPanel.Children.Add(CardTitle(paths ? "Teaching monsters to find their way" : "Setting up Hordes of Azeroth"));
            IBrush text = Brush("Text");
            if (paths)
            {
                NotesPanel.Children.Add(Paragraph("Every zone gets a map of where creatures can walk, climb and fit. Monsters use it to chase you around trees, up ramps and through doorways instead of running into walls, and the horde uses it to spawn only where it can reach you, never inside a rock or on a rooftop.", text));
                if (m_latest != null && m_latest.NavGroups.All(g => g.Download != null))
                {
                    NotesPanel.Children.Add(Paragraph($"They come ready-made, a {m_latest.NavGroups.Sum(g => g.Download.Size) / 1048576} MB download for every zone.", text));
                }
                else
                {
                    NotesPanel.Children.Add(Paragraph("It's worked out from your own game files, one 533-yard square at a time. Westfall, The Barrens and Duskwood come first; the harder zones finish in the background while you play.", text));
                    NotesPanel.Children.Add(Paragraph("This is heavy work and only happens once. Your processor can sit at 100% and your fans may spin up until it's done. To use fewer cores, open the ••• menu next to Play and choose Monster path build speed.", text));
                }
            }
            else
            {
                NotesPanel.Children.Add(Paragraph("The launcher builds everything from your own World of Warcraft files. You can close it and come back; it carries on where it stopped.", text));
            }
            AddChecklist(Installer.Steps.Concat(new[] { "Monster paths" }).ToArray(), current);
        }

        void ShowStepsCard(string kicker, string title, string explanation, string[] steps, int current)
        {
            NotesPanel.Children.Clear();
            NotesPager.IsVisible = false;
            NotesPanel.Children.Add(Kicker(kicker));
            NotesPanel.Children.Add(CardTitle(title));
            NotesPanel.Children.Add(Paragraph(explanation, Brush("Text")));
            AddChecklist(steps, current);
        }

        async Task AskBuildSpeedOnceAsync()
        {
            if (!m_settings.BuildSpeedChosen)
                await BuildSpeedWindow.AskAsync(this, m_settings);
        }

        async Task GetInstallPathsAsync(Manifest manifest, CancellationToken cancel)
        {
            List<NavGroup> downloads = manifest.NavGroups.Where(g => g.Download != null && !m_nav.IsGroupBuilt(g)).ToList();
            long total = downloads.Sum(g => g.Download.Size);
            long finished = 0;
            foreach (NavGroup group in downloads)
            {
                StatusText.Text = "Downloading monster paths";
                long before = finished;
                try
                {
                    await DownloadPathsAsync(group, new Progress<long>(bytes =>
                    {
                        if (m_state == LauncherState.Installing)
                            ShowPathDownloadProgress(before + bytes, total);
                    }), cancel);
                }
                catch (Exception e) when (IsDownloadProblem(e))
                {
                }
                finished += group.Download.Size;
            }
            NavGroup first = manifest.NavGroups.FirstOrDefault();
            if (first == null || m_nav.IsGroupBuilt(first))
                return;
            await AskBuildSpeedOnceAsync();
            StatusText.Text = first.Download != null
                ? "The download didn't work, so the launcher builds the monster paths for " + first.Name
                : "Building monster paths: " + first.Name;
            UseInstallBuildSpeed();
            await m_nav.BuildGroupAsync(first, new Progress<NavProgress>(n =>
            {
                if (m_state == LauncherState.Installing)
                    ShowInstallBuildProgress(n);
            }), cancel);
        }

        async Task DownloadPathsAsync(NavGroup group, IProgress<long> progress, CancellationToken cancel)
        {
            string zip = await m_installer.FetchAsync(group.Download.Url, group.Download.Sha256, progress.Report, cancel);
            await Task.Run(() => m_nav.InstallDownloaded(group, zip), cancel);
            File.Delete(zip);
        }

        static bool IsDownloadProblem(Exception e) => e is InvalidOperationException || e is InvalidDataException || e is IOException || e is UnauthorizedAccessException;

        void ShowPathDownloadProgress(long bytes, long total)
        {
            Progress.IsIndeterminate = false;
            Progress.Value = total > 0 ? (double)bytes / total : 0;
            StatusDetail.Text = $"   {bytes / 1048576.0:0.0} of {total / 1048576.0:0.0} MB";
        }

        void UseInstallBuildSpeed()
        {
            m_nav.Priority = ProcessPriorityClass.BelowNormal;
            m_nav.Workers = () => LauncherSettings.Workers(m_settings.InstallCores);
            m_nav.Paused = () => false;
        }

        void ShowInstallBuildProgress(NavProgress n)
        {
            Progress.IsIndeterminate = false;
            Progress.Value = n.Total > 0 ? (double)n.Done / n.Total : 0;
            StatusDetail.Text = $"   {n.Done} of {n.Total} areas on {CoresText(m_settings.InstallCores)}. High CPU use is expected and only happens once.";
        }

        static string CoresText(CoreShare share)
        {
            int cores = LauncherSettings.Workers(share);
            return cores == 1 ? "1 core" : cores + " cores";
        }

        async void StartBackgroundBuild()
        {
            if (m_latest == null || !IsInstalled() || (m_background != null && !m_background.IsCancellationRequested))
                return;
            List<NavGroup> pending = m_latest.NavGroups.Skip(1).Where(g => !m_nav.IsGroupBuilt(g)).ToList();
            if (pending.Count == 0)
                return;
            m_background = new CancellationTokenSource();
            CancellationToken cancel = m_background.Token;
            if (IsVisible && pending.Any(g => g.Download == null))
                await AskBuildSpeedOnceAsync();
            m_nav.Priority = ProcessPriorityClass.BelowNormal;
            m_nav.Workers = () => LauncherSettings.Workers(m_settings.BackgroundCores);
            m_nav.Paused = () => !m_settings.BuildWhilePlaying && m_game.IsRunning;
            IProgress<NavProgress> progress = new Progress<NavProgress>(n =>
            {
                m_backgroundProgress = n;
                ShowBackgroundProgress();
            });
            _ = Task.Run(async () =>
            {
                try
                {
                    foreach (NavGroup group in pending)
                        await GetBackgroundPathsAsync(group, progress, cancel);
                }
                catch (OperationCanceledException)
                {
                }
                catch (InvalidOperationException)
                {
                }
                Dispatcher.UIThread.Post(() =>
                {
                    m_backgroundProgress = null;
                    ShowBackgroundProgress();
                });
            });
        }

        async Task GetBackgroundPathsAsync(NavGroup group, IProgress<NavProgress> progress, CancellationToken cancel)
        {
            if (group.Download != null)
            {
                int total = (int)Math.Max(1, group.Download.Size / 1048576);
                try
                {
                    await DownloadPathsAsync(group, new Progress<long>(bytes => progress.Report(new NavProgress
                    {
                        Group = group.Name,
                        Done = (int)Math.Min(total - 1, bytes / 1048576),
                        Total = total,
                        Downloading = true,
                    })), cancel);
                    return;
                }
                catch (Exception e) when (IsDownloadProblem(e))
                {
                }
            }
            await m_nav.BuildGroupAsync(group, progress, cancel);
        }

        void ShowBackgroundProgress()
        {
            if (m_state != LauncherState.Ready && m_state != LauncherState.Playing)
                return;
            NavProgress n = m_backgroundProgress;
            if (n == null || n.Done >= n.Total)
            {
                if (m_state == LauncherState.Ready)
                {
                    StatusDetail.Text = "";
                    Progress.Value = 0;
                    ShowProgress(false);
                }
                return;
            }
            StatusDetail.Text = n.Downloading
                ? $"   {n.Group}: downloading monster paths in the background, {n.Done} of {n.Total} MB"
                : $"   {n.Group}: building monster paths in the background, {n.Done} of {n.Total} areas on {CoresText(m_settings.BackgroundCores)}";
            Progress.IsIndeterminate = false;
            Progress.Value = (double)n.Done / n.Total;
            ShowProgress(true);
        }

        async Task PlayAsync()
        {
            SetState(LauncherState.Starting, "Starting", "");
            Progress<string> progress = new Progress<string>(step => StatusDetail.Text = "   " + step);
            try
            {
                await RepairBeforePlayAsync();
                m_game.Prepare(m_accounts.Selected);
                await StartServerAsync(progress);
                await m_accountSync.PrepareAsync(m_accounts);
                StatusDetail.Text = "   Starting the game";
                await m_game.StartAsync(CancellationToken.None);
            }
            catch (Exception e) when (!(e is OutOfMemoryException))
            {
                await m_server.StopAsync();
                m_state = LauncherState.Ready;
                RefreshState();
                ShowProblem("The game couldn't start", e.Message);
                return;
            }
            await WatchRunningGameAsync();
        }

        async Task RepairBeforePlayAsync()
        {
            if (m_latest == null)
                return;
            bool checking = true;
            bool repairing = false;
            IProgress<InstallProgress> progress = new Progress<InstallProgress>(p =>
            {
                if (!checking || m_state != LauncherState.Starting)
                    return;
                repairing |= p.Fixing;
                if (!repairing)
                {
                    StatusDetail.Text = "   " + Installer.InProgress(p.Step);
                    return;
                }
                ShowRepairCard(Array.IndexOf(Installer.RepairSteps, p.Step), QuickRepairText);
                ShowStepProgress(p);
            });
            bool repaired = await m_installer.RepairAsync(m_latest, false, progress, CancellationToken.None);
            checking = false;
            if (!repaired)
                return;
            ShowNotes(m_latest.Notes);
            SetState(LauncherState.Starting, "Starting", "");
        }

        async Task StartServerAsync(IProgress<string> progress)
        {
            try
            {
                await m_server.StartAsync(progress, CancellationToken.None);
            }
            catch (WorldDatabaseException) when (!m_folder.IsDevelopmentTree)
            {
                StatusText.Text = "Reloading the world";
                StatusDetail.Text = "   the world database didn't match the server (about a minute)";
                ShowRepairCard(Installer.RepairSteps.Length - 1, QuickRepairText);
                await m_installer.ReloadWorldAsync(new Progress<InstallProgress>(_ => { }), CancellationToken.None);
                ShowNotes(m_latest?.Notes);
                SetState(LauncherState.Starting, "Starting", "");
                await m_server.StartAsync(progress, CancellationToken.None);
            }
        }

        async Task WatchRunningGameAsync()
        {
            SetState(LauncherState.Playing, "Playing", "the game's server stops when you close the game");
            if (m_settings.KeepInTray)
                TuckAway();
            await m_game.WaitForAllToCloseAsync(CancellationToken.None);
            ShowFromTray();
            SetState(LauncherState.Stopping, "Closing", "saving and stopping the game's server");
            await CountCharactersAsync();
            try
            {
                await m_server.StopAsync();
            }
            finally
            {
                m_state = LauncherState.Ready;
                RefreshState();
            }
            await ShareRunsAsync();
            await OfferCrashReportAsync();
        }

        async void CheckForUpdates_Click(object sender, RoutedEventArgs e)
        {
            if (m_state == LauncherState.Ready || m_state == LauncherState.UpdateAvailable || m_state == LauncherState.Missing)
                StatusDetail.Text = "   checking…";
            await CheckForUpdatesAsync(true);
        }

        void OpenGameFolder_Click(object sender, RoutedEventArgs e) => Platform.OpenFolder(m_folder.Root);

        void OpenAddOns_Click(object sender, RoutedEventArgs e)
        {
            Directory.CreateDirectory(m_folder.ClientAddOns);
            Platform.OpenFolder(m_folder.ClientAddOns);
        }

        void OpenLogs_Click(object sender, RoutedEventArgs e)
        {
            Directory.CreateDirectory(m_folder.ServerLogs);
            Platform.OpenFolder(m_folder.ServerLogs);
        }

        async void ReportBug_Click(object sender, RoutedEventArgs e)
        {
            if (RunUpload.IsConfigured && await Dialog.AskAsync(this, "Send your logs to the developer with this bug report?\n\nThey hold the game's server and client logs, your character names and your game settings. You'll get a reference to put in your report."))
            {
                await SendLogsAsync();
                return;
            }
            if (SaveLogs())
                Platform.OpenUrl(NewIssueUrl);
        }

        async Task SendLogsAsync()
        {
            string zip = null;
            try
            {
                zip = LogBundle.Save(m_folder);
                string reference = await RunUpload.SendReportAsync(zip);
                await Dialog.TellAsync(this, $"Your logs were sent. Reference: {reference}\n\nPut this reference in your bug report on GitHub or Discord.");
                Platform.OpenUrl(NewIssueUrl);
            }
            catch (Exception e) when (e is IOException || e is UnauthorizedAccessException || Web.IsProblem(e))
            {
                ShowProblem("The logs couldn't be sent", zip == null ? e.Message : "They were saved on your desktop instead. Attach that file to your bug report.");
                if (zip != null)
                    Platform.ShowFile(zip);
            }
        }

        void SaveLogs_Click(object sender, RoutedEventArgs e) => SaveLogs();

        bool SaveLogs()
        {
            try
            {
                Platform.ShowFile(LogBundle.Save(m_folder));
                return true;
            }
            catch (Exception e) when (e is IOException || e is UnauthorizedAccessException)
            {
                ShowProblem("The logs couldn't be saved", e.Message);
                return false;
            }
        }

        void Discord_Click(object sender, RoutedEventArgs e) => Platform.OpenUrl(DiscordUrl);

        void Coffee_Click(object sender, RoutedEventArgs e) => Platform.OpenUrl(CoffeeUrl);

        void ShowLanguage() => LanguageButton.Content = GameConfig.LanguageName(GameConfig.ReadLanguage(m_folder));

        void ToggleMenu(ContextMenu menu, Control target, Action fill)
        {
            if (menu.IsOpen)
            {
                menu.Close();
                return;
            }
            if (m_menuClosedAt.TryGetValue(menu, out DateTime closed) && DateTime.UtcNow - closed < MenuReclickWindow)
                return;
            fill?.Invoke();
            menu.Open(target);
        }

        void WatchMenuClosing(params ContextMenu[] menus)
        {
            foreach (ContextMenu menu in menus)
                menu.Closed += (sender, e) => m_menuClosedAt[menu] = DateTime.UtcNow;
        }

        void LanguageButton_Click(object sender, RoutedEventArgs e) => ToggleMenu(LanguageMenu, LanguageButton, () =>
        {
            string current = GameConfig.ReadLanguage(m_folder);
            LanguageMenu.ItemsSource = GameConfig.Languages.Select(language => LanguageItem(language.Code, language.Name, current)).ToList();
        });

        MenuItem LanguageItem(string code, string name, string current)
        {
            MenuItem item = new MenuItem { Header = name, ToggleType = MenuItemToggleType.Radio, IsChecked = code == current };
            item.Click += (sender, e) =>
            {
                GameConfig.WriteLanguage(m_folder, code);
                ShowLanguage();
            };
            return item;
        }

        void MoreButton_Click(object sender, RoutedEventArgs e) => ToggleMenu(OptionsMenu, MoreButton, null);

        void OptionsMenu_Opened(object sender, RoutedEventArgs e)
        {
            TrayItem.IsVisible = Platform.HasTray;
            TrayItem.IsChecked = m_settings.KeepInTray;
            BuildItem.IsChecked = m_settings.BuildWhilePlaying;
            RunDataItem.IsChecked = m_settings.SendRunData;
            CrashReportItem.IsChecked = m_settings.AskToSendCrashes;
            bool idle = m_state == LauncherState.Ready || m_state == LauncherState.UpdateAvailable || (m_state == LauncherState.NotInstalled && m_installer.IsComplete);
            BackupItem.IsEnabled = idle && m_server.DatabaseExists;
            RestoreItem.IsEnabled = idle && m_server.DatabaseExists;
            DateTime? last = m_saves.LastBackupTime;
            ToolTip.SetTip(RestoreItem, last == null ? "Puts back the save data from a backup file." : $"Puts back the save data from a backup file. Last backup: {last:d MMMM, HH:mm}.");
            RepairItem.IsVisible = !m_folder.IsDevelopmentTree;
            RepairItem.IsEnabled = m_state == LauncherState.Ready || m_state == LauncherState.UpdateAvailable || (m_state == LauncherState.NotInstalled && m_installer.IsComplete);
        }

        async void RepairItem_Click(object sender, RoutedEventArgs e)
        {
            string question = "Repair checks every game file, downloads the ones that are missing or damaged and reloads the world. It takes a minute or two. Your characters and unlocks are backed up first and stay as they are.\n\nRepair the game now?";
            if (await Dialog.AskAsync(this, question))
                await RepairAsync(true);
        }

        void BuildItem_Click(object sender, RoutedEventArgs e)
        {
            m_settings.BuildWhilePlaying = BuildItem.IsChecked;
            m_settings.Save();
        }

        async void BuildSpeedItem_Click(object sender, RoutedEventArgs e) => await BuildSpeedWindow.AskAsync(this, m_settings);

        void TrayItem_Click(object sender, RoutedEventArgs e)
        {
            m_settings.KeepInTray = TrayItem.IsChecked;
            m_settings.Save();
        }

        void RunDataItem_Click(object sender, RoutedEventArgs e)
        {
            m_settings.SendRunData = RunDataItem.IsChecked;
            m_settings.RunDataAsked = true;
            m_settings.Save();
        }

        void CrashReportItem_Click(object sender, RoutedEventArgs e)
        {
            m_settings.AskToSendCrashes = CrashReportItem.IsChecked;
            m_settings.Save();
        }

        static readonly string[] BadgeColours = { "#F0C060", "#7CCF5A", "#8FB8F0", "#E58FB4", "#C79BF2", "#F29A6B" };

        IBrush BadgeBrush(Account account)
        {
            int index = Math.Max(0, m_accounts.All.ToList().IndexOf(account));
            return new SolidColorBrush(Color.Parse(BadgeColours[index % BadgeColours.Length]));
        }

        void ShowAccount()
        {
            Account account = m_accounts.Selected;
            AccountName.Text = account.Name;
            AccountInitial.Text = account.Initial;
            AccountBadge.Background = BadgeBrush(account);
        }

        void AccountButton_Click(object sender, RoutedEventArgs e) => ToggleMenu(AccountMenu, AccountButton, FillAccountMenu);

        void FillAccountMenu()
        {
            List<Control> items = new List<Control>
            {
                new MenuItem { Header = new TextBlock { Text = "PLAY AS", FontSize = 11, FontWeight = FontWeight.Bold, Foreground = Brush("Accent") }, IsHitTestVisible = false },
            };
            items.AddRange(m_accounts.All.Select(AccountItem));
            items.Add(new Separator());
            items.Add(MenuAction("Add an account…", AddAccountAsync));
            items.Add(MenuAction($"Rename {m_accounts.Selected.Name}…", RenameAccountAsync));
            MenuItem delete = MenuAction($"Delete {m_accounts.Selected.Name}…", DeleteAccountAsync);
            delete.IsEnabled = m_accounts.All.Count > 1;
            items.Add(delete);
            AccountMenu.ItemsSource = items;
        }

        MenuItem AccountItem(Account account)
        {
            string detail = account.Characters < 0 ? null : account.Characters == 0 ? "no characters yet" : account.Characters == 1 ? "1 character" : $"{account.Characters} characters";
            Border badge = new Border
            {
                Width = 20,
                Height = 20,
                CornerRadius = new CornerRadius(10),
                Background = BadgeBrush(account),
                VerticalAlignment = VerticalAlignment.Center,
                Child = new TextBlock
                {
                    Text = account.Initial,
                    FontSize = 10,
                    FontWeight = FontWeight.Bold,
                    Foreground = new SolidColorBrush(Color.Parse("#1A0F0D")),
                    HorizontalAlignment = HorizontalAlignment.Center,
                    VerticalAlignment = VerticalAlignment.Center,
                },
            };
            StackPanel text = new StackPanel
            {
                Children =
                {
                    new TextBlock { Text = account.Name, FontSize = 13 },
                    new TextBlock { Text = detail, FontSize = 11, Foreground = Brush("Muted"), IsVisible = detail != null },
                },
            };
            MenuItem item = new MenuItem
            {
                Header = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 9, Children = { badge, text } },
                ToggleType = MenuItemToggleType.Radio,
                IsChecked = account == m_accounts.Selected,
            };
            item.Click += (sender, e) =>
            {
                m_accounts.Select(account);
                ShowAccount();
            };
            return item;
        }

        static MenuItem MenuAction(string header, Func<Task> action)
        {
            MenuItem item = new MenuItem { Header = header };
            item.Click += async (sender, e) => await action();
            return item;
        }

        async Task<string> AskAccountNameAsync(string question, string initial, string confirm, Account renaming)
        {
            while (true)
            {
                string answer = await Dialog.AskTextAsync(this, question, initial, confirm, 20);
                if (answer == null)
                    return null;
                string name = Accounts.CleanName(answer);
                if (name.Length > 0 && !m_accounts.NameTaken(name, renaming))
                    return name;
                await Dialog.TellAsync(this, name.Length == 0 ? "Give the account a name." : $"There is already an account called {name}.");
                initial = name;
            }
        }

        async Task AddAccountAsync()
        {
            string name = await AskAccountNameAsync("Name the new account. It starts with no characters, gold or unlocks.", "", "Add", null);
            if (name == null)
                return;
            m_accounts.Add(name);
            ShowAccount();
        }

        async Task RenameAccountAsync()
        {
            Account account = m_accounts.Selected;
            string name = await AskAccountNameAsync("Rename this account. Only its name in the launcher changes.", account.Name, "Rename", account);
            if (name == null)
                return;
            m_accounts.Rename(account, name);
            ShowAccount();
        }

        async Task DeleteAccountAsync()
        {
            Account account = m_accounts.Selected;
            string question = $"Delete the account {account.Name}?\n\nIts characters, gold and unlocks are deleted the next time you press Play. Back up your save data first if you might want them back.";
            if (!await Dialog.ConfirmAsync(this, question, "Delete"))
                return;
            m_accounts.Delete(account);
            ShowAccount();
        }

        async Task CountCharactersAsync()
        {
            try
            {
                await m_accountSync.CountCharactersAsync(m_accounts);
            }
            catch (Exception e) when (!(e is OutOfMemoryException))
            {
                LauncherLog.Write(m_folder, "The character counts couldn't be read: " + e.Message);
            }
        }

        async void BackupItem_Click(object sender, RoutedEventArgs e)
        {
            string zip = await RunSaveTaskAsync("Backing up…", "Backing up your save data", "The backup couldn't be saved",
                () => m_saves.BackUpAsync("", CancellationToken.None));
            if (zip == null)
                return;
            StatusDetail.Text = "   saved " + Path.GetFileName(zip);
            Platform.ShowFile(zip);
        }

        async void RestoreItem_Click(object sender, RoutedEventArgs e)
        {
            string zip = await PickBackupAsync();
            if (zip == null)
                return;
            string question = $"Restore {Path.GetFileName(zip)}?\n\nEvery account's characters, gold, unlocks and settings go back to how they were in that backup. The launcher backs up how things are now first.";
            if (!await Dialog.ConfirmAsync(this, question, "Restore"))
                return;
            string restored = await RunSaveTaskAsync("Restoring…", "Restoring your save data", "The backup couldn't be restored", async () =>
            {
                await m_saves.RestoreAsync(zip, CancellationToken.None);
                return zip;
            });
            if (restored == null)
                return;
            m_accounts = Accounts.Load(m_folder);
            ShowAccount();
            StatusDetail.Text = "   restored " + Path.GetFileName(zip);
        }

        async Task<string> PickBackupAsync()
        {
            Directory.CreateDirectory(m_saves.Folder);
            IReadOnlyList<IStorageFile> files = await StorageProvider.OpenFilePickerAsync(new FilePickerOpenOptions
            {
                Title = "Choose a save backup",
                AllowMultiple = false,
                SuggestedStartLocation = await StorageProvider.TryGetFolderFromPathAsync(m_saves.Folder),
                FileTypeFilter = new[] { new FilePickerFileType("Save backups") { Patterns = new[] { "*.zip" } } },
            });
            return files.Count > 0 ? files[0].TryGetLocalPath() : null;
        }

        async Task<string> RunSaveTaskAsync(string button, string status, string problem, Func<Task<string>> work)
        {
            m_busyButton = button;
            SetState(LauncherState.Installing, status, "");
            string result = null;
            string failure = null;
            try
            {
                result = await work();
            }
            catch (Exception e) when (!(e is OutOfMemoryException))
            {
                failure = e.Message;
            }
            await m_server.StopAsync();
            m_busyButton = null;
            m_state = LauncherState.Ready;
            RefreshState();
            if (failure != null)
                ShowProblem(problem, failure);
            return result;
        }
    }
}

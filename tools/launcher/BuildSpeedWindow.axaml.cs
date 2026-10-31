using System;
using System.Threading.Tasks;
using Avalonia;
using Avalonia.Controls;
using Avalonia.Interactivity;
using Avalonia.Media;

namespace HordesOfAzeroth.Launcher
{
    public partial class BuildSpeedWindow : Window
    {
        readonly LauncherSettings m_settings;

        public BuildSpeedWindow()
        {
            InitializeComponent();
            Loc.Apply(this);
        }

        BuildSpeedWindow(LauncherSettings settings) : this()
        {
            m_settings = settings;
            DescribeChoices(InstallAll, InstallHalf, Loc.T("Done sooner, but the PC may feel slow until then."));
            DescribeChoices(BackgroundAll, BackgroundHalf, Loc.T("Finishes sooner while the launcher is open."));
            Select(InstallAll, InstallHalf, settings.InstallCores);
            Select(BackgroundAll, BackgroundHalf, settings.BackgroundCores);
        }

        internal static Task AskAsync(Window owner, LauncherSettings settings)
        {
            BuildSpeedWindow window = new BuildSpeedWindow(settings);
            if (owner != null && owner.IsVisible && owner.WindowState != WindowState.Minimized)
                return window.ShowDialog(owner);
            window.WindowStartupLocation = WindowStartupLocation.CenterScreen;
            TaskCompletionSource<bool> closed = new TaskCompletionSource<bool>();
            window.Closed += (s, e) => closed.TrySetResult(true);
            window.Show();
            return closed.Task;
        }

        static void DescribeChoices(RadioButton all, RadioButton half, string allDetail)
        {
            all.Content = Choice(Loc.T("All {0} cores", Environment.ProcessorCount), Loc.T("Fastest. {0}", allDetail));
            half.Content = Choice(Loc.T("Half: {0} cores", LauncherSettings.HalfOfCores), Loc.T("Slower, and the PC stays easy to use."));
        }

        static StackPanel Choice(string title, string detail)
        {
            StackPanel panel = new StackPanel();
            panel.Children.Add(new TextBlock { Text = title, FontSize = 13.5, FontWeight = FontWeight.SemiBold });
            panel.Children.Add(new TextBlock { Text = detail, FontSize = 12, TextWrapping = TextWrapping.Wrap, Opacity = 0.75, Margin = new Thickness(0, 3, 0, 0) });
            return panel;
        }

        static void Select(RadioButton all, RadioButton half, CoreShare share)
        {
            all.IsChecked = share == CoreShare.All;
            half.IsChecked = share == CoreShare.Half;
        }

        static CoreShare Chosen(RadioButton all) => all.IsChecked == true ? CoreShare.All : CoreShare.Half;

        void Continue_Click(object sender, RoutedEventArgs e)
        {
            m_settings.InstallCores = Chosen(InstallAll);
            m_settings.BackgroundCores = Chosen(BackgroundAll);
            m_settings.BuildSpeedChosen = true;
            m_settings.Save();
            Close();
        }
    }
}

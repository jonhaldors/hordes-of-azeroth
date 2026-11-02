using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace HordesOfAzeroth.Launcher
{
    sealed class CoopCharacter
    {
        public string Name { get; init; }
        public byte[] Dump { get; init; }
        public byte[] Account { get; init; }
    }

    sealed class CoopTransfer
    {
        static readonly TimeSpan AnswerTimeout = TimeSpan.FromSeconds(30);
        static readonly TimeSpan PollDelay = TimeSpan.FromMilliseconds(250);
        static readonly TimeSpan LogoutTimeout = TimeSpan.FromSeconds(15);

        readonly string m_dir;
        readonly SemaphoreSlim m_one = new SemaphoreSlim(1, 1);
        readonly object m_leaveLock = new object();

        public CoopTransfer(GameFolder folder)
        {
            string overrideDir = Environment.GetEnvironmentVariable("HOA_SERVER_RUN");
            m_dir = Path.Combine(string.IsNullOrEmpty(overrideDir) ? folder.ServerRun : overrideDir, "coop");
        }

        string FilePath(string extension) => Path.Combine(m_dir, "transfer" + extension);

        public async Task<(string Guid, CoopCharacter Character)> ExportAsync(string name)
        {
            await m_one.WaitAsync();
            try
            {
                string[] answer = await RunAsync($"export {name}");
                return (answer[1], new CoopCharacter
                {
                    Name = name,
                    Dump = await File.ReadAllBytesAsync(FilePath(".dump")),
                    Account = await File.ReadAllBytesAsync(FilePath(".account")),
                });
            }
            finally
            {
                m_one.Release();
            }
        }

        public async Task<string> ImportAsync(string username, CoopCharacter character, string replaceGuid)
        {
            await m_one.WaitAsync();
            try
            {
                await File.WriteAllBytesAsync(FilePath(".dump"), character.Dump);
                await File.WriteAllBytesAsync(FilePath(".account"), character.Account);
                string[] answer = await RunAsync($"import {username} {character.Name} {replaceGuid ?? "0"}");
                return answer.Length > 2 ? answer[2] : character.Name;
            }
            finally
            {
                m_one.Release();
            }
        }

        public string ReadLedger(string user, long since)
        {
            string path = Path.Combine(m_dir, "ledger-" + user + ".out");
            if (!File.Exists(path))
                return "";
            string text;
            using (FileStream stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
            using (StreamReader reader = new StreamReader(stream))
                text = reader.ReadToEnd();
            int complete = text.LastIndexOf('\n');
            System.Text.StringBuilder lines = new System.Text.StringBuilder();
            foreach (string line in (complete < 0 ? "" : text.Substring(0, complete)).Split('\n'))
            {
                int tab = line.IndexOf('\t');
                if (tab > 0 && long.TryParse(line.Substring(0, tab), out long seq) && seq > since)
                    lines.Append(line).Append('\n');
            }
            return lines.ToString();
        }

        public void NoteJoining(string user, string name)
        {
            Directory.CreateDirectory(m_dir);
            string path = Path.Combine(m_dir, "joining.txt");
            long now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
            List<string> lines = File.Exists(path)
                ? File.ReadAllLines(path).Where(line => line.Split('\t') is { Length: 3 } fields && long.TryParse(fields[2], out long at) && now - at < 3600).ToList()
                : new List<string>();
            lines.Add($"{user}\t{name}\t{now}");
            File.WriteAllLines(path, lines);
        }

        public void ForgetJoining(string user)
        {
            string path = Path.Combine(m_dir, "joining.txt");
            try
            {
                if (File.Exists(path))
                    File.WriteAllLines(path, File.ReadAllLines(path).Where(line => line.Split('\t')[0] != user));
            }
            catch (IOException)
            {
            }
        }

        public void ClearJoining() => File.Delete(Path.Combine(m_dir, "joining.txt"));

        string JoinPath(string who) => Path.Combine(m_dir, "join-" + who.ToUpperInvariant() + ".json");

        string SpoolPath(string who) => Path.Combine(m_dir, "spool-" + who.ToUpperInvariant() + ".txt");

        public void SaveJoin(string who, string json)
        {
            Directory.CreateDirectory(m_dir);
            string path = JoinPath(who);
            File.WriteAllText(path + ".tmp", json);
            File.Move(path + ".tmp", path, true);
        }

        public void DeleteJoin(string who)
        {
            File.Delete(JoinPath(who));
            File.Delete(SpoolPath(who));
        }

        public IEnumerable<string> SavedJoins() =>
            Directory.Exists(m_dir) ? Directory.GetFiles(m_dir, "join-*.json").Select(File.ReadAllText).ToList() : new List<string>();

        public void SaveSpool(string who, string entries)
        {
            Directory.CreateDirectory(m_dir);
            string path = SpoolPath(who);
            File.WriteAllText(path + ".tmp", entries);
            File.Move(path + ".tmp", path, true);
        }

        public string ReadSpool(string who) => File.Exists(SpoolPath(who)) ? File.ReadAllText(SpoolPath(who)) : "";

        public void ClearSpool(string who) => File.Delete(SpoolPath(who));

        public bool IsGuestOnline(string user)
        {
            try
            {
                using FileStream stream = new FileStream(Path.Combine(m_dir, "guests-online.txt"), FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete);
                using StreamReader reader = new StreamReader(stream);
                return reader.ReadToEnd().Split('\n').Any(line => line.Trim() == user);
            }
            catch (IOException)
            {
                return true;
            }
        }

        public List<string> TakeRemovedGuests()
        {
            string path = Path.Combine(m_dir, "removed.txt");
            string work = path + ".work";
            try
            {
                if (!File.Exists(path))
                    return new List<string>();
                File.Move(path, work, true);
                List<string> users = File.ReadAllLines(work).Select(line => line.Trim()).Where(line => line.Length > 0).Distinct().ToList();
                File.Delete(work);
                return users;
            }
            catch (IOException)
            {
                return new List<string>();
            }
        }

        public Task RemoveAllGuestsAsync()
        {
            Directory.CreateDirectory(m_dir);
            return AskToRemoveAsync("*");
        }

        string AwayPath(string account) => Path.Combine(m_dir, "away-" + account.ToUpperInvariant() + ".txt");

        string HostSettingsPath => Path.Combine(m_dir, "host-settings.txt");

        public void NoteHostSettings(bool pause, bool xp)
        {
            Directory.CreateDirectory(m_dir);
            File.WriteAllText(HostSettingsPath, $"pause\t{(pause ? 1 : 0)}\nxp\t{(xp ? 1 : 0)}\nplaying\t\n");
        }

        public void ClearHostSettings() => File.Delete(HostSettingsPath);

        public Dictionary<string, string> ReadHostSettings()
        {
            Dictionary<string, string> settings = new Dictionary<string, string>();
            try
            {
                foreach (string line in File.ReadAllLines(HostSettingsPath))
                {
                    int tab = line.IndexOf('\t');
                    if (tab > 0)
                        settings[line.Substring(0, tab)] = line.Substring(tab + 1);
                }
            }
            catch (IOException)
            {
            }
            return settings;
        }

        public void NoteSameClass(bool allowed)
        {
            Directory.CreateDirectory(m_dir);
            string path = Path.Combine(m_dir, "same-class.txt");
            if (allowed)
                File.WriteAllText(path, "1");
            else
                File.Delete(path);
        }

        public void MarkAway(string account)
        {
            Directory.CreateDirectory(m_dir);
            File.WriteAllText(AwayPath(account), DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString());
        }

        public void ClearAway(string account) => File.Delete(AwayPath(account));

        public async Task<bool> LogOutGuestAsync(string user)
        {
            Directory.CreateDirectory(m_dir);
            string online = Path.Combine(m_dir, "guests-online.txt");
            DateTime asked = DateTime.UtcNow;
            await AskToRemoveAsync(user);
            DateTime until = asked + LogoutTimeout;
            while (DateTime.UtcNow < until)
            {
                await Task.Delay(PollDelay);
                try
                {
                    if (File.GetLastWriteTimeUtc(online) > asked.AddSeconds(1) && !IsGuestOnline(user))
                        return true;
                }
                catch (IOException)
                {
                }
            }
            return false;
        }

        async Task AskToRemoveAsync(string user)
        {
            string request = Path.Combine(m_dir, "leave.req");
            for (int attempt = 0; ; ++attempt)
            {
                try
                {
                    lock (m_leaveLock)
                        File.AppendAllText(request, user + "\n");
                    return;
                }
                catch (IOException) when (attempt < 20)
                {
                    await Task.Delay(PollDelay);
                }
            }
        }

        public void ClearGuestLedgers()
        {
            if (!Directory.Exists(m_dir))
                return;
            foreach (string pattern in new[] { "ledger-HOAC*.out", "ledger-HOAC*.answers" })
                foreach (string file in Directory.GetFiles(m_dir, pattern))
                    try
                    {
                        File.Delete(file);
                    }
                    catch (IOException)
                    {
                    }
        }

        public void AppendAnswers(string user, string answers)
        {
            Directory.CreateDirectory(m_dir);
            File.AppendAllText(Path.Combine(m_dir, "ledger-" + user + ".answers"), answers);
        }

        public async Task<string> ApplyLedgerAsync(string ownAccount, string game, string character, string entries)
        {
            await m_one.WaitAsync();
            try
            {
                Directory.CreateDirectory(m_dir);
                string answer = Path.Combine(m_dir, "ledger.answer");
                File.Delete(answer);
                string inbox = Path.Combine(m_dir, "ledger.in");
                await File.WriteAllTextAsync(inbox + ".tmp", $"from\t{ownAccount}\t{game}\t{character}\n{entries}");
                File.Move(inbox + ".tmp", inbox, true);
                DateTime until = DateTime.UtcNow + AnswerTimeout;
                while (!File.Exists(answer))
                {
                    if (DateTime.UtcNow > until)
                    {
                        File.Delete(inbox);
                        throw new InvalidOperationException("The game server didn't answer. Is it running?");
                    }
                    await Task.Delay(PollDelay);
                }
                string text = await File.ReadAllTextAsync(answer);
                File.Delete(answer);
                if (text.StartsWith("error "))
                    throw new InvalidOperationException(text.Substring(6).Trim());
                return text;
            }
            finally
            {
                m_one.Release();
            }
        }

        async Task<string[]> RunAsync(string request)
        {
            Directory.CreateDirectory(m_dir);
            string done = FilePath(".done");
            File.Delete(done);
            string temporary = FilePath(".req.tmp");
            await File.WriteAllTextAsync(temporary, request);
            File.Move(temporary, FilePath(".req"), true);
            DateTime until = DateTime.UtcNow + AnswerTimeout;
            while (!File.Exists(done))
            {
                if (DateTime.UtcNow > until)
                {
                    File.Delete(FilePath(".req"));
                    throw new InvalidOperationException("The game server didn't answer. Is it running?");
                }
                await Task.Delay(PollDelay);
            }
            string answer = (await File.ReadAllTextAsync(done)).Trim();
            File.Delete(done);
            if (!answer.StartsWith("ok "))
                throw new InvalidOperationException(answer.StartsWith("error ") ? answer.Substring(6) : answer);
            return answer.Split(' ');
        }
    }
}

using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace HordesOfAzeroth.Launcher
{
    sealed class AccountSync
    {
        readonly LocalServer m_server;
        readonly GameFolder m_folder;

        public AccountSync(LocalServer server, GameFolder folder)
        {
            m_server = server;
            m_folder = folder;
        }

        public async Task PrepareAsync(Accounts accounts)
        {
            foreach (string login in accounts.Deleted.ToList())
                await DeleteAsync(accounts, login);
            Account selected = accounts.Selected;
            if (await IdOfAsync(selected.Login) != null)
                return;
            await m_server.RunConsoleAsync($"account create {selected.Login} {selected.Password}");
            if (await IdOfAsync(selected.Login) == null)
                throw new InvalidOperationException($"The account {selected.Name} couldn't be created. See server/logs/Server.log.");
        }

        async Task DeleteAsync(Accounts accounts, string login)
        {
            string id = await IdOfAsync(login);
            if (id != null)
            {
                foreach (string table in await AccountTablesAsync())
                    await m_server.QueryAsync("characters", $"DELETE FROM `{table}` WHERE account = {id}");
                await m_server.RunConsoleAsync($"account delete {login}");
                if (await IdOfAsync(login) != null)
                {
                    LauncherLog.Write(m_folder, $"The account {login} couldn't be deleted yet; the launcher tries again next time.");
                    return;
                }
            }
            accounts.ForgetDeleted(login);
        }

        public async Task CountCharactersAsync(Accounts accounts)
        {
            string rows = await m_server.QueryAsync("realmd",
                "SELECT a.username, COUNT(c.guid) FROM realmd.account a LEFT JOIN characters.characters c ON c.account = a.id GROUP BY a.id, a.username");
            Dictionary<string, int> counts = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
            foreach (string[] row in Lines(rows).Select(line => line.Split('\t')).Where(row => row.Length == 2))
                if (int.TryParse(row[1], out int count))
                    counts[row[0]] = count;
            foreach (Account account in accounts.All)
                if (counts.TryGetValue(account.Login, out int count))
                    account.Characters = count;
            accounts.Save();
        }

        async Task<string> IdOfAsync(string login)
        {
            string id = (await m_server.QueryAsync("realmd", $"SELECT id FROM account WHERE username = '{login}'")).Trim();
            return id.Length > 0 ? id : null;
        }

        async Task<List<string>> AccountTablesAsync() =>
            Lines(await m_server.QueryAsync("information_schema",
                "SELECT table_name FROM columns WHERE table_schema = 'characters' AND column_name = 'account' AND table_name LIKE 'bonk%'")).ToList();

        static IEnumerable<string> Lines(string text) => text.Split('\n').Select(l => l.Trim()).Where(l => l.Length > 0);
    }
}

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography;

namespace HordesOfAzeroth.Launcher
{
    sealed class Account
    {
        public string Login;
        public string Password;
        public string Name;
        public int Characters = -1;

        public string Initial => Name.Length > 0 ? Name.Substring(0, 1).ToUpperInvariant() : "?";
    }

    sealed class Accounts
    {
        public const string FirstLogin = "PLAYER";
        const string FirstPassword = "player";
        const string FirstName = "Main";
        const int MaxNameLength = 20;
        const int PasswordLength = 12;
        const string PasswordLetters = "abcdefghijkmnpqrstuvwxyz23456789";

        readonly string m_path;
        readonly List<Account> m_accounts = new List<Account>();
        readonly List<string> m_deleted = new List<string>();
        string m_selected = FirstLogin;

        public IReadOnlyList<Account> All => m_accounts;

        public IReadOnlyList<string> Deleted => m_deleted;

        public Account Selected => m_accounts.FirstOrDefault(a => a.Login == m_selected) ?? m_accounts[0];

        Accounts(string path)
        {
            m_path = path;
        }

        public static string FileName => "accounts.ini";

        public static Accounts Load(GameFolder folder)
        {
            Accounts accounts = new Accounts(Path.Combine(folder.LauncherData, FileName));
            if (File.Exists(accounts.m_path))
                accounts.Read(File.ReadAllLines(accounts.m_path));
            if (accounts.m_accounts.Count == 0)
                accounts.m_accounts.Add(new Account { Login = FirstLogin, Password = FirstPassword, Name = FirstName });
            return accounts;
        }

        void Read(string[] lines)
        {
            foreach (string line in lines)
            {
                string[] pair = line.Split(new[] { '=' }, 2);
                if (pair.Length != 2)
                    continue;
                string key = pair[0].Trim();
                string value = pair[1].Trim();
                if (key == "Selected")
                    m_selected = value;
                else if (key == "Deleted" && value.Length > 0)
                    m_deleted.Add(value);
                else if (key == "Account")
                    ReadAccount(value);
            }
        }

        void ReadAccount(string value)
        {
            string[] parts = value.Split('|');
            if (parts.Length < 3 || parts[0].Length == 0 || m_accounts.Any(a => a.Login == parts[0]))
                return;
            Account account = new Account { Login = parts[0], Password = parts[1], Name = parts[2] };
            if (parts.Length > 3 && int.TryParse(parts[3], out int characters))
                account.Characters = characters;
            m_accounts.Add(account);
        }

        public void Save()
        {
            Directory.CreateDirectory(Path.GetDirectoryName(m_path));
            List<string> lines = new List<string> { "Selected=" + Selected.Login };
            lines.AddRange(m_accounts.Select(a => $"Account={a.Login}|{a.Password}|{a.Name}|{a.Characters}"));
            lines.AddRange(m_deleted.Select(login => "Deleted=" + login));
            File.WriteAllLines(m_path, lines);
        }

        public static string CleanName(string name)
        {
            string clean = new string((name ?? "").Where(c => !char.IsControl(c) && c != '|').ToArray()).Trim();
            return clean.Length > MaxNameLength ? clean.Substring(0, MaxNameLength).Trim() : clean;
        }

        public bool NameTaken(string name, Account except = null) =>
            m_accounts.Any(a => a != except && string.Equals(a.Name, name, StringComparison.OrdinalIgnoreCase));

        public Account Add(string name)
        {
            Account account = new Account { Login = NextLogin(), Password = NewPassword(), Name = name, Characters = 0 };
            m_accounts.Add(account);
            m_selected = account.Login;
            Save();
            return account;
        }

        public void Select(Account account)
        {
            m_selected = account.Login;
            Save();
        }

        public void Rename(Account account, string name)
        {
            account.Name = name;
            Save();
        }

        public void Delete(Account account)
        {
            if (m_accounts.Count < 2)
                return;
            m_accounts.Remove(account);
            m_deleted.Add(account.Login);
            if (m_selected == account.Login)
                m_selected = m_accounts[0].Login;
            Save();
        }

        public void ForgetDeleted(string login)
        {
            m_deleted.Remove(login);
            Save();
        }

        string NextLogin()
        {
            for (int number = 2; ; ++number)
            {
                string login = FirstLogin + number;
                if (!m_accounts.Any(a => a.Login == login) && !m_deleted.Contains(login))
                    return login;
            }
        }

        static string NewPassword()
        {
            char[] letters = new char[PasswordLength];
            for (int i = 0; i < letters.Length; ++i)
                letters[i] = PasswordLetters[RandomNumberGenerator.GetInt32(PasswordLetters.Length)];
            return new string(letters);
        }
    }
}

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Numerics;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace HordesOfAzeroth.Launcher
{
    sealed class CoopLogin
    {
        public string User { get; init; }
        public string Password { get; init; }
    }

    sealed class CoopAccounts
    {
        const string NamePrefix = "HOAC";
        const int NameLetters = 8;
        const int PasswordLength = 12;
        const string Letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        const string PasswordCharacters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        const string PrimeHex = "894B645E89E1535BBDAD5B8B290650530801B18EBFBF5E8FAB3C82872A3E9BB7";
        const int Generator = 7;
        const int SaltBytes = 32;
        readonly string m_mariaDb;
        readonly GameFolder m_folder;

        public CoopAccounts(GameFolder folder)
        {
            string overrideDir = Environment.GetEnvironmentVariable("HOA_MARIADB_DIR");
            m_mariaDb = string.IsNullOrEmpty(overrideDir) ? folder.MariaDb : overrideDir;
            m_folder = folder;
        }

        public async Task<CoopLogin> CreateAsync()
        {
            while (true)
            {
                string user = NamePrefix + Random(Letters, NameLetters);
                string password = Random(PasswordCharacters, PasswordLength);
                byte[] passHash = SHA1.HashData(Encoding.ASCII.GetBytes(user + ":" + password));
                if (passHash[0] == 0)
                    continue;
                byte[] salt = RandomNumberGenerator.GetBytes(SaltBytes);
                if (salt[0] == 0)
                    continue;
                string verifierHex = Verifier(salt, passHash);
                string saltHex = Convert.ToHexString(salt);
                await QueryAsync("realmd",
                    $"INSERT INTO account (username, v, s, joindate) VALUES ('{user}', '{verifierHex}', '{saltHex}', NOW()); " +
                    "REPLACE INTO realmcharacters (realmid, acctid, numchars) SELECT realmlist.id, account.id, 0 FROM realmlist, account " +
                    $"WHERE account.username = '{user}'");
                string id = (await QueryAsync("realmd", $"SELECT id FROM account WHERE username = '{user}'")).Trim();
                if (id.Length == 0)
                    throw new InvalidOperationException("The joining player's account couldn't be created.");
                return new CoopLogin { User = user, Password = password };
            }
        }

        public async Task<bool> IsGameMasterAsync(string username)
        {
            string clean = new string((username ?? "").Where(char.IsLetterOrDigit).ToArray()).ToUpperInvariant();
            if (clean.Length == 0)
                return false;
            string level = (await QueryAsync("realmd",
                $"SELECT GREATEST(a.gmlevel, COALESCE(MAX(aa.gmlevel), 0)) FROM account a LEFT JOIN account_access aa ON aa.id = a.id WHERE a.username = '{clean}' GROUP BY a.id")).Trim();
            return int.TryParse(level, out int gm) && gm > 0;
        }

        static string Verifier(byte[] saltBigEndian, byte[] passHash)
        {
            byte[] saltLittleEndian = saltBigEndian.Reverse().ToArray();
            byte[] x = SHA1.HashData(saltLittleEndian.Concat(passHash).ToArray());
            BigInteger exponent = new BigInteger(x, isUnsigned: true, isBigEndian: false);
            BigInteger prime = BigInteger.Parse("0" + PrimeHex, System.Globalization.NumberStyles.HexNumber);
            BigInteger verifier = BigInteger.ModPow(Generator, exponent, prime);
            return Convert.ToHexString(verifier.ToByteArray(isUnsigned: true, isBigEndian: true));
        }

        static string Random(string alphabet, int length) =>
            new string(Enumerable.Range(0, length).Select(_ => alphabet[RandomNumberGenerator.GetInt32(alphabet.Length)]).ToArray());

        async Task<string> QueryAsync(string database, string sql)
        {
            List<string> arguments = new List<string> { "-h", "127.0.0.1", "-P", DatabasePorts.Saved(m_folder).ToString(), "-u", "root", "-proot", "--skip-ssl" };
            arguments.AddRange(new[] { "-N", "-B", database, "-e", "\"" + sql.Replace("\"", "\\\"") + "\"" });
            ProcessStartInfo info = new ProcessStartInfo(Path.Combine(m_mariaDb, "bin", Platform.Exe("mariadb")), string.Join(" ", arguments))
            {
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true,
            };
            using Process process = Process.Start(info);
            Task<string> output = process.StandardOutput.ReadToEndAsync();
            Task<string> error = process.StandardError.ReadToEndAsync();
            await process.WaitForExitAsync();
            if (process.ExitCode != 0)
                throw new InvalidOperationException("Database error: " + (await error).Trim());
            return await output;
        }
    }
}

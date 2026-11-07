using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;

namespace HordesOfAzeroth.Launcher
{
    sealed class WorldDump
    {
        const string CreateTable = "CREATE TABLE `";
        const string MigrationRows = "INSERT INTO `migrations` VALUES";
        static readonly Regex MigrationId = new Regex(@"'(\d+)'");

        public string LastTable { get; private set; }
        public HashSet<string> Migrations { get; } = new HashSet<string>();

        public static WorldDump Read(string file)
        {
            WorldDump dump = new WorldDump();
            bool readingMigrations = false;
            foreach (string line in File.ReadLines(file))
            {
                if (line.StartsWith(CreateTable, StringComparison.Ordinal))
                {
                    int end = line.IndexOf('`', CreateTable.Length);
                    if (end > CreateTable.Length)
                        dump.LastTable = line.Substring(CreateTable.Length, end - CreateTable.Length);
                    continue;
                }
                if (line.StartsWith(MigrationRows, StringComparison.Ordinal))
                    readingMigrations = true;
                if (!readingMigrations)
                    continue;
                foreach (Match id in MigrationId.Matches(line))
                    dump.Migrations.Add(id.Groups[1].Value);
                if (line.TrimEnd().EndsWith(";"))
                    readingMigrations = false;
            }
            return dump;
        }
    }
}

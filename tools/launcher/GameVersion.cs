using System;
using System.IO;

namespace HordesOfAzeroth.Launcher
{
    sealed class GameVersion : IComparable<GameVersion>
    {
        readonly int[] m_parts;

        GameVersion(int[] parts)
        {
            m_parts = parts;
        }

        public static GameVersion Parse(string text)
        {
            if (string.IsNullOrWhiteSpace(text))
                return null;
            string[] pieces = text.Trim().TrimStart('v', 'V').Split('.');
            if (pieces.Length < 2 || pieces.Length > 3)
                return null;
            int[] parts = new int[3];
            for (int i = 0; i < pieces.Length; i++)
                if (!int.TryParse(pieces[i], out parts[i]) || parts[i] < 0)
                    return null;
            return new GameVersion(parts);
        }

        public static GameVersion ReadFile(string path)
        {
            try
            {
                return File.Exists(path) ? Parse(File.ReadAllText(path)) : null;
            }
            catch (IOException)
            {
                return null;
            }
        }

        public int CompareTo(GameVersion other)
        {
            if (other == null)
                return 1;
            for (int i = 0; i < 3; i++)
                if (m_parts[i] != other.m_parts[i])
                    return m_parts[i].CompareTo(other.m_parts[i]);
            return 0;
        }

        public bool IsNewerThan(GameVersion other) => CompareTo(other) > 0;

        public string Full => string.Join(".", m_parts);

        public string Display => m_parts[2] == 0 ? $"{m_parts[0]}.{m_parts[1]}" : Full;

        public string PatchName => Loc.T("Patch {0}", Display);

        public override string ToString() => Full;
    }
}

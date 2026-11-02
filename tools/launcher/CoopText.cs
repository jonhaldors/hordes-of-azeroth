using System;
using System.Globalization;
using System.Text.RegularExpressions;

namespace HordesOfAzeroth.Launcher
{
    static class CoopText
    {
        static readonly string[] Templates =
        {
            "Port {0} is already in use, so you can't host.",
            "The host declined your request. You can ask again in {0} seconds.",
            "Requires Mythic {0} cleared.",
            "Requires Mastery {0} or lower.",
            "{0} only works on a regular account. This account is a game master account.",
            "Database error: {0}",
        };

        static readonly Regex[] Patterns = Array.ConvertAll(Templates, template =>
            new Regex("^" + Regex.Escape(template).Replace("\\{0}", "(.+?)") + "$", RegexOptions.Singleline));

        public static string Localize(string message)
        {
            if (string.IsNullOrEmpty(message))
                return message;
            string text = Loc.T(message);
            if (text != message)
                return text;
            for (int i = 0; i < Templates.Length; i++)
            {
                Match match = Patterns[i].Match(message);
                if (match.Success)
                    return string.Format(CultureInfo.InvariantCulture, Loc.T(Templates[i]), Loc.T(match.Groups[1].Value));
            }
            return message;
        }
    }
}

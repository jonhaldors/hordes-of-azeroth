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
            "Other players can't reach you on TCP port {0}. Forward that port on your router to this PC and allow the launcher through Windows Firewall, then host again. If your internet provider shares your address, hosting won't work. You can still join other games.",
            "Only players on your own network can join. To let others join, forward TCP port {0} on your router to this PC, or enter a public address when you host.",
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

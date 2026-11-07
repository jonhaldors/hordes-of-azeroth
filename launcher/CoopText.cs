using System;
using System.Globalization;
using System.Text.RegularExpressions;

namespace HordesOfAzeroth.Launcher
{
    static class CoopText
    {
                static readonly string[] TemplateIds =
        {
            "hoa.launcher.port_0_is_already_in_use_so_you_can_t_host",
            "hoa.launcher.the_host_declined_your_request_you_can_ask_again_in_0_second",
            "hoa.launcher.requires_mythic_0_cleared",
            "hoa.launcher.requires_mastery_0_or_lower",
            "hoa.launcher.0_only_works_on_a_regular_account_this_account_is_a_game_mas",
            "hoa.launcher.database_error_0",
            "hoa.launcher.other_players_can_t_reach_you_on_tcp_port_0_forward_that_por",
            "hoa.launcher.only_players_on_your_own_network_can_join_to_let_others_join",
            "hoa.launcher.only_players_on_your_vpn_can_join_to_let_others_join_forward",
            "hoa.launcher.other_players_can_t_reach_0_1_check_that_it_forwards_tcp_to_",
        };

        static readonly string[] Templates = Array.ConvertAll(TemplateIds, id => LauncherStrings.EnUs[id]);


        static readonly Regex[] Patterns = Array.ConvertAll(Templates, template =>
            new Regex("^" + Regex.Replace(Regex.Escape(template), @"\\\{\d+\}", "(.+?)") + "$", RegexOptions.Singleline));

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
                {
                    object[] values = new object[match.Groups.Count - 1];
                    for (int g = 1; g < match.Groups.Count; g++)
                        values[g - 1] = Loc.T(match.Groups[g].Value);
                    return string.Format(CultureInfo.InvariantCulture, Loc.T(TemplateIds[i]), values);
                }
            }
            return message;
        }
    }
}

#include "BonkVersion.h"
#include "BonkPlayer.h"
#include "BonkStrings.h"
#include "Chat.h"
#include "Player.h"
#include "World.h"
#include "WorldSession.h"

#include <cctype>
#include <fstream>
#include <vector>

namespace
{
    char const* const INSTALLED_VERSION_FILE = "../../VERSION";
    char const* const LATEST_VERSION_FILE = "latest-version.txt";
    uint32 const LATEST_VERSION_CHECK_MS = 2 * MINUTE * IN_MILLISECONDS;

    std::string g_welcome;
    std::string g_installed;
    std::string g_announced;
    uint32 g_checkTimer = 0;

    bool ParseVersion(std::string const& text, std::vector<uint32>& parts)
    {
        parts.clear();
        uint32 part = 0;
        bool digits = false;
        for (char c : text)
        {
            if (std::isdigit(static_cast<unsigned char>(c)))
            {
                part = part * 10 + uint32(c - '0');
                digits = true;
            }
            else if (c == '.' && digits)
            {
                parts.push_back(part);
                part = 0;
                digits = false;
            }
            else
                return false;
        }
        if (!digits)
            return false;
        parts.push_back(part);
        return parts.size() >= 2 && parts.size() <= 3;
    }

    std::string ReadVersionFile(char const* path)
    {
        std::ifstream file(path);
        std::string line;
        if (!file || !std::getline(file, line))
            return "";
        size_t const start = line.find_first_not_of(" \t\r\n");
        size_t const end = line.find_last_not_of(" \t\r\n");
        if (start == std::string::npos)
            return "";
        line = line.substr(start, end - start + 1);
        std::vector<uint32> parts;
        return ParseVersion(line, parts) ? line : "";
    }

    bool IsNewer(std::string const& candidate, std::string const& current)
    {
        std::vector<uint32> a, b;
        if (!ParseVersion(candidate, a) || !ParseVersion(current, b))
            return false;
        a.resize(3, 0);
        b.resize(3, 0);
        return a > b;
    }

    std::string DisplayVersion(std::string const& version)
    {
        std::vector<uint32> parts;
        ParseVersion(version, parts);
        if (parts.size() == 3 && parts[2] == 0)
            parts.pop_back();
        std::string shown;
        for (uint32 part : parts)
            shown += (shown.empty() ? "" : ".") + std::to_string(part);
        return shown;
    }

    std::string AvailableLine(BonkPlayer const* bonk, std::string const& version)
    {
        return bonk->GetString(BONK_STRING_PATCH_AVAILABLE, { DisplayVersion(version) });
    }

    void SendAvailableToEveryone(std::string const& version)
    {
        for (auto const& entry : sWorld.GetAllSessions())
        {
            Player* player = entry.second ? entry.second->GetPlayer() : nullptr;
            if (player && player->IsInWorld())
                ChatHandler(player).SendSysMessage(AvailableLine(player->GetBonkPlayer(), version).c_str());
        }
    }

    void CheckLatestVersion()
    {
        std::string const latest = ReadVersionFile(LATEST_VERSION_FILE);
        std::string const pending = IsNewer(latest, g_installed) ? latest : "";
        if (pending == g_announced)
            return;

        g_announced = pending;
        if (!pending.empty())
            SendAvailableToEveryone(pending);
    }
}

std::string BonkVersion::BuildMotd(std::string const& welcome)
{
    g_welcome = welcome;
    g_installed = ReadVersionFile(INSTALLED_VERSION_FILE);
    g_checkTimer = 0;
    return g_welcome;
}

void BonkVersion::SendPatchLines(Player* player)
{
    BonkPlayer const* bonk = player->GetBonkPlayer();
    ChatHandler chat(player);
    if (!g_installed.empty())
        chat.SendSysMessage(bonk->GetString(BONK_STRING_PATCH_INSTALLED, { DisplayVersion(g_installed) }).c_str());
    if (!g_announced.empty())
        chat.SendSysMessage(AvailableLine(bonk, g_announced).c_str());
}

void BonkVersion::Update(uint32 diff)
{
    if (g_checkTimer > diff)
    {
        g_checkTimer -= diff;
        return;
    }
    g_checkTimer = LATEST_VERSION_CHECK_MS;
    CheckLatestVersion();
}

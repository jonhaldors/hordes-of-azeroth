#include "BonkCoop.h"

#include "AccountMgr.h"
#include "BonkFoundGear.h"
#include "BonkMgr.h"
#include "BonkPlayer.h"
#include "BonkQuests.h"
#include "Bag.h"
#include "Item.h"
#include "Mail.h"
#include "ObjectMgr.h"
#include "Database/DatabaseEnv.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "WorldSession.h"

#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <ctime>
#include <fstream>
#include <map>
#include <mutex>
#include <set>
#include <sstream>
#include <string>
#include <vector>

namespace
{
    char const* const INBOX_FILE = "coop/ledger.in";
    char const* const INBOX_ANSWER_FILE = "coop/ledger.answer";
    char const* const ONLINE_GUESTS_FILE = "coop/guests-online.txt";
    char const* const LEAVE_FILE = "coop/leave.req";
    char const* const LEAVE_WORK_FILE = "coop/leave.work";
    time_t const GUEST_REMOVE_SECONDS = 10;
    time_t const LEDGER_KEEP_SECONDS = 300;
    size_t const MAX_GAME_LENGTH = 64;
    uint32 const GUEST_SYNC_MS = 5000;
    uint32 const HOME_MAIL_SENDER = 900009;
    time_t const AWAY_FRESH_SECONDS = 30;

    enum MirrorOwner
    {
        MIRROR_POOL,
        MIRROR_CHARACTER_PROGRESS,
        MIRROR_CHARACTER_GUID,
    };

    struct MirroredTable
    {
        char const* name;
        MirrorOwner owner;
        uint32 columns;
    };

    MirroredTable const MIRRORED_TABLES[] = {
        { "bonk_account_upgrade", MIRROR_POOL, 3 },
        { "bonk_account_talent", MIRROR_POOL, 4 },
        { "bonk_account_mastery_node", MIRROR_CHARACTER_PROGRESS, 3 },
        { "bonk_account_mastery_preset", MIRROR_CHARACTER_PROGRESS, 5 },
        { "bonk_account_mastery_preset_active", MIRROR_CHARACTER_PROGRESS, 3 },
        { "bonk_account_starter", MIRROR_CHARACTER_PROGRESS, 3 },
        { "bonk_account_disabled", MIRROR_POOL, 3 },
        { "bonk_account_epic_luck", MIRROR_POOL, 2 },
        { "bonk_account_board", MIRROR_POOL, 2 },
        { "bonk_character_title", MIRROR_CHARACTER_GUID, 2 },
    };

    struct GuestTotals
    {
        uint32 gold = 0;
        uint32 shards = 0;
        uint32 scrap = 0;
        uint32 determination = 0;
        uint32 masteryXp = 0;
        uint32 runs = 0;
        uint32 bestLevel = 0;
        uint32 bestSeconds = 0;
        uint32 kills = 0;
        uint32 goldEarned = 0;
        std::map<uint32, std::pair<uint32, bool>> quests;
        std::map<std::string, std::string> tables;
        std::string inventory;
        bool inRun = false;
    };

    struct HomeTarget
    {
        uint32 accountId = 0;
        uint32 characterGuid = 0;
        uint32 characterAccount = 0;
        std::string game;
    };

    struct Allowance
    {
        int64 base;
        int64 perMinute;
    };

    Allowance const GOLD_ALLOWANCE = { 20000000, 2000000 };
    Allowance const SHARDS_ALLOWANCE = { 500, 100 };
    Allowance const SCRAP_ALLOWANCE = { 20000, 2000 };
    Allowance const MASTERY_ALLOWANCE = { 5000, 1000 };
    Allowance const KILLS_ALLOWANCE = { 2000, 10000 };
    Allowance const RUNS_ALLOWANCE = { 3, 1 };
    Allowance const MAIL_ALLOWANCE = { 10, 2 };

    struct GameBudget
    {
        time_t started = 0;
        std::map<std::string, int64> used;
    };

    std::mutex s_budgetLock;
    std::map<std::string, GameBudget> s_budgets;

    bool Spend(HomeTarget const& home, std::string const& kind, Allowance const& allowance, int64 amount)
    {
        if (amount <= 0)
            return true;
        std::lock_guard<std::mutex> guard(s_budgetLock);
        GameBudget& budget = s_budgets[std::to_string(home.accountId) + ":" + home.game];
        time_t const now = time(nullptr);
        if (!budget.started)
            budget.started = now;
        int64 const minutes = int64(now - budget.started) / 60 + 1;
        int64& used = budget.used[kind];
        if (used + amount > allowance.base + allowance.perMinute * minutes)
            return false;
        used += amount;
        return true;
    }

    GameBudget BudgetOf(HomeTarget const& home)
    {
        std::lock_guard<std::mutex> guard(s_budgetLock);
        return s_budgets[std::to_string(home.accountId) + ":" + home.game];
    }

    void RestoreBudget(HomeTarget const& home, GameBudget const& budget)
    {
        std::lock_guard<std::mutex> guard(s_budgetLock);
        s_budgets[std::to_string(home.accountId) + ":" + home.game] = budget;
    }

    void Credit(HomeTarget const& home, std::string const& kind, int64 amount)
    {
        std::lock_guard<std::mutex> guard(s_budgetLock);
        int64& used = s_budgets[std::to_string(home.accountId) + ":" + home.game].used[kind];
        used = std::max<int64>(0, used - amount);
    }

    std::string OverLimit(std::string const& kind)
    {
        return "more " + kind + " than a session can earn";
    }

    uint32 TierCap(HomeTarget const& home)
    {
        std::unique_ptr<QueryResult> result(CharacterDatabase.PQuery("SELECT MAX(`best_level`) FROM `bonk_account_level` WHERE `account` IN (%u, %u)",
            home.accountId, home.characterAccount));
        return std::max(1u, result ? result->Fetch()[0].GetUInt32() : 0u);
    }

    std::mutex s_guestLock;
    std::map<ObjectGuid, GuestTotals> s_guests;
    uint32 s_guestTimer = 0;

    std::mutex s_outboxLock;
    std::map<std::string, uint32> s_lastSeq;

    std::map<std::string, std::string> s_unwritten;

    std::string OutboxPath(std::string const& username)
    {
        return "coop/ledger-" + username + ".out";
    }

    void FlushOutbox(std::string const& username)
    {
        auto found = s_unwritten.find(username);
        if (found == s_unwritten.end())
            return;
        std::ofstream out(OutboxPath(username), std::ios::binary | std::ios::app);
        if (!out)
            return;
        out << found->second;
        out.flush();
        if (out)
            s_unwritten.erase(found);
    }

    std::string AnswersPath(std::string const& username)
    {
        return "coop/ledger-" + username + ".answers";
    }

    std::vector<std::string> SplitTabs(std::string const& line)
    {
        std::vector<std::string> fields;
        std::string field;
        for (char c : line)
        {
            if (c == '\t')
            {
                fields.push_back(field);
                field.clear();
            }
            else if (c != '\r')
                field += c;
        }
        fields.push_back(field);
        return fields;
    }

    uint32 LastSeqInFile(std::string const& path)
    {
        std::ifstream in(path, std::ios::binary);
        std::string line;
        uint32 last = 0;
        while (std::getline(in, line))
            last = std::max(last, uint32(std::strtoul(line.c_str(), nullptr, 10)));
        return last;
    }

    bool ReadCount(std::vector<std::string> const& fields, size_t index, uint32& count)
    {
        if (fields.size() <= index || fields[index].empty() || fields[index].find_first_not_of("0123456789") != std::string::npos)
            return false;
        count = uint32(std::strtoul(fields[index].c_str(), nullptr, 10));
        return true;
    }

    bool ReadSigned(std::vector<std::string> const& fields, size_t index, int64& value)
    {
        if (fields.size() <= index || fields[index].empty())
            return false;
        std::string const& text = fields[index];
        size_t const start = text[0] == '-' ? 1 : 0;
        if (start == text.size() || text.find_first_not_of("0123456789", start) != std::string::npos)
            return false;
        value = std::strtoll(text.c_str(), nullptr, 10);
        return true;
    }

    std::string Escape(std::string const& value)
    {
        std::string out;
        for (char c : value)
        {
            if (c == '\\')
                out += "\\\\";
            else if (c == '\t')
                out += "\\t";
            else if (c == '\n')
                out += "\\n";
            else if (c != '\r')
                out += c;
        }
        return out;
    }

    std::string Unescape(std::string const& value)
    {
        std::string out;
        for (size_t i = 0; i < value.size(); ++i)
        {
            if (value[i] == '\\' && i + 1 < value.size())
            {
                char const next = value[++i];
                out += next == 't' ? '\t' : next == 'n' ? '\n' : next;
            }
            else
                out += value[i];
        }
        return out;
    }

    std::string ApplyAccountColumn(HomeTarget const& home, std::vector<std::string> const& fields, char const* column, int64 cap, Allowance const* allowance)
    {
        int64 delta = 0;
        if (!ReadSigned(fields, 2, delta))
            return std::string("broken ") + column + " entry";
        if (allowance && !Spend(home, column, *allowance, delta))
            return OverLimit(column);
        CharacterDatabase.PExecute("INSERT INTO `bonk_account` (`account`, `%s`) VALUES (%u, %u) "
            "ON DUPLICATE KEY UPDATE `%s` = LEAST(%lld, GREATEST(0, CAST(`%s` AS SIGNED) + %lld))",
            column, home.accountId, uint32(std::max<int64>(0, std::min<int64>(cap, delta))), column, (long long)cap, column, (long long)delta);
        return "";
    }

    std::string ApplyMastery(HomeTarget const& home, std::vector<std::string> const& fields)
    {
        uint32 classId = 0;
        int64 delta = 0;
        if (!ReadCount(fields, 2, classId) || !ReadSigned(fields, 3, delta))
            return "broken mastery entry";
        if (!home.characterAccount)
            return "no home character";
        if (!Spend(home, "mastery", MASTERY_ALLOWANCE, delta))
            return OverLimit("mastery");
        CharacterDatabase.PExecute("INSERT INTO `bonk_account_mastery` (`account`, `class`, `xp`) VALUES (%u, %u, %u) "
            "ON DUPLICATE KEY UPDATE `xp` = GREATEST(0, CAST(`xp` AS SIGNED) + %lld)",
            home.characterAccount, classId, uint32(std::max<int64>(0, delta)), (long long)delta);
        return "";
    }

    std::string ApplyQuest(HomeTarget const& home, std::vector<std::string> const& fields)
    {
        uint32 quest = 0;
        uint32 progress = 0;
        uint32 completed = 0;
        if (!ReadCount(fields, 2, quest) || !ReadCount(fields, 3, progress) || !ReadCount(fields, 4, completed))
            return "broken quest entry";
        BonkQuest const* known = sBonkQuests.FindQuest(quest);
        if (!known)
            return "unknown quest " + std::to_string(quest);
        if (!known->CountsBits())
            progress = std::min(progress, known->amount);
        CharacterDatabase.PExecute("INSERT INTO `bonk_account_quest` (`account`, `quest`, `progress`, `completed`) VALUES (%u, %u, %u, %u) "
            "ON DUPLICATE KEY UPDATE `progress` = GREATEST(`progress`, VALUES(`progress`)), `completed` = GREATEST(`completed`, VALUES(`completed`))",
            home.accountId, quest, progress, completed ? 1u : 0u);
        return "";
    }

    std::string ApplyLevel(HomeTarget const& home, std::vector<std::string> const& fields)
    {
        uint32 classId = 0;
        uint32 bestLevel = 0;
        uint32 bestMs = 0;
        uint32 finale = 0;
        if (!ReadCount(fields, 2, classId) || !ReadCount(fields, 3, bestLevel) || !ReadCount(fields, 4, bestMs) || !ReadCount(fields, 5, finale))
            return "broken level entry";
        if (!classId || classId >= MAX_CLASSES)
            return "unknown class " + std::to_string(classId);
        if (!home.characterAccount)
            return "no home character";
        BonkPlayer::RaisePoolBestLevel(home.accountId, bestLevel);
        CharacterDatabase.PExecute("INSERT INTO `bonk_account_level` (`account`, `class`, `best_level`, `best_ms`, `best_finale`) VALUES (%u, %u, %u, %u, %u) "
            "ON DUPLICATE KEY UPDATE "
            "`best_ms` = CASE WHEN VALUES(`best_level`) > `best_level` THEN VALUES(`best_ms`) "
            "WHEN VALUES(`best_level`) = `best_level` AND VALUES(`best_ms`) > 0 AND (`best_ms` = 0 OR VALUES(`best_ms`) < `best_ms`) THEN VALUES(`best_ms`) ELSE `best_ms` END, "
            "`best_level` = GREATEST(`best_level`, VALUES(`best_level`)), `best_finale` = GREATEST(`best_finale`, VALUES(`best_finale`))",
            home.characterAccount, classId, bestLevel, bestMs, finale);
        return "";
    }

    std::string HomeCharacterName(HomeTarget const& home)
    {
        std::unique_ptr<QueryResult> result(CharacterDatabase.PQuery("SELECT `name` FROM `characters` WHERE `guid` = %u", home.characterGuid));
        return result ? result->Fetch()[0].GetCppString() : std::string();
    }

    std::string ApplyLevelBest(HomeTarget const& home, std::vector<std::string> const& fields)
    {
        uint32 classId = 0;
        BonkPlayer::LevelRun run;
        if (fields.size() < 9 || !ReadCount(fields, 2, classId) || !ReadCount(fields, 3, run.level) || !ReadCount(fields, 4, run.ms) ||
            !ReadCount(fields, 5, run.kills) || !ReadCount(fields, 7, run.gold) || !ReadCount(fields, 8, run.valor))
            return "broken levelbest entry";
        run.damage = std::strtoull(fields[6].c_str(), nullptr, 10);
        if (!classId || classId >= MAX_CLASSES)
            return "unknown class " + std::to_string(classId);
        if (!home.characterGuid)
            return "no home character";
        run.name = HomeCharacterName(home);
        BonkPlayer::ApplyLevelBest(home.characterAccount, uint8(classId), run);
        return "";
    }

    std::string ApplyFinaleBest(HomeTarget const& home, std::vector<std::string> const& fields)
    {
        uint32 classId = 0;
        uint32 level = 0;
        uint32 score = 0;
        uint32 seconds = 0;
        if (!ReadCount(fields, 2, classId) || !ReadCount(fields, 3, level) || !ReadCount(fields, 4, score) || !ReadCount(fields, 5, seconds))
            return "broken finalebest entry";
        if (!classId || classId >= MAX_CLASSES)
            return "unknown class " + std::to_string(classId);
        if (!home.characterAccount)
            return "no home character";
        BonkPlayer::ApplyFinaleBest(home.characterAccount, uint8(classId), level, score, seconds);
        return "";
    }

    std::string ApplyRunStats(HomeTarget const& home, std::vector<std::string> const& fields)
    {
        uint32 values[5] = {};
        for (size_t i = 0; i < 5; ++i)
            if (!ReadCount(fields, 2 + i, values[i]))
                return "broken runstats entry";
        if (!home.characterGuid)
            return "no home character";
        if (!Spend(home, "runs", RUNS_ALLOWANCE, values[0]) || !Spend(home, "kills", KILLS_ALLOWANCE, values[3]) ||
            !Spend(home, "gold earned", GOLD_ALLOWANCE, values[4]))
            return OverLimit("run stats");
        CharacterDatabase.PExecute("INSERT INTO `bonk_character_stats` (`guid`, `runs`, `best_level`, `best_time_sec`, `kills`, `gold_earned`) "
            "VALUES (%u, %u, %u, %u, %u, %u) ON DUPLICATE KEY UPDATE `runs` = `runs` + VALUES(`runs`), `best_level` = GREATEST(`best_level`, VALUES(`best_level`)), "
            "`best_time_sec` = GREATEST(`best_time_sec`, VALUES(`best_time_sec`)), `kills` = `kills` + VALUES(`kills`), `gold_earned` = `gold_earned` + VALUES(`gold_earned`)",
            home.characterGuid, values[0], values[1], values[2], values[3], values[4]);
        return "";
    }

    bool ReadFound(std::string const& text, BonkFoundGear& found)
    {
        std::vector<std::string> parts;
        std::string part;
        for (char c : text)
        {
            if (c == ',')
            {
                parts.push_back(part);
                part.clear();
            }
            else
                part += c;
        }
        parts.push_back(part);
        if (parts.size() > 3 && !parts.back().empty() && parts.back()[0] == 'u')
        {
            found.upgrades = std::min(uint32(std::strtoul(parts.back().c_str() + 1, nullptr, 10)), BONK_FOUND_MAX_UPGRADES);
            parts.pop_back();
        }
        if (parts.size() < 3)
            return false;
        found.tier = uint32(std::strtoul(parts[0].c_str(), nullptr, 10));
        found.rerolls = uint32(std::strtoul(parts[1].c_str(), nullptr, 10));
        found.rerollLine = uint8(std::strtoul(parts[2].c_str(), nullptr, 10));
        for (size_t i = 3; i + 1 < parts.size() && found.lines.size() < BONK_FOUND_MAX_LINES; i += 2)
        {
            BonkFoundLine line;
            line.effect = uint8(std::strtoul(parts[i].c_str(), nullptr, 10));
            line.roll = float(std::strtod(parts[i + 1].c_str(), nullptr));
            found.lines.push_back(line);
        }
        return found.tier > 0;
    }

    std::string WriteFound(BonkFoundGear const& found)
    {
        std::ostringstream out;
        out << found.tier << ',' << found.rerolls << ',' << uint32(found.rerollLine);
        for (BonkFoundLine const& line : found.lines)
            out << ',' << uint32(line.effect) << ',' << line.roll;
        out << ",u" << found.upgrades;
        return out.str();
    }

    bool IsMailToken(std::string const& text)
    {
        return !text.empty() && text.size() <= 48 && text.find_first_not_of("0123456789-") == std::string::npos;
    }

    std::string ApplyMailItemTaken(HomeTarget const& home, std::vector<std::string> const& fields)
    {
        uint32 mailId = 0, itemGuid = 0, entry = 0;
        if (!ReadCount(fields, 2, mailId) || !ReadCount(fields, 3, itemGuid) || !ReadCount(fields, 4, entry))
            return "broken mail item entry";
        if (!home.characterGuid)
            return "no home character";
        std::unique_ptr<QueryResult> found(CharacterDatabase.PQuery(
            "SELECT 1 FROM `mail_items` mi JOIN `mail` m ON m.`id` = mi.`mail_id` WHERE mi.`mail_id` = %u AND mi.`item_guid` = %u AND mi.`item_id` = %u AND m.`receiver_guid` = %u",
            mailId, itemGuid, entry, home.characterGuid));
        if (!found)
            return "that mail item is no longer in the home mailbox";
        CharacterDatabase.PExecute("DELETE FROM `mail_items` WHERE `item_guid` = %u", itemGuid);
        CharacterDatabase.PExecute("DELETE FROM `item_instance` WHERE `guid` = %u", itemGuid);
        CharacterDatabase.PExecute("DELETE FROM `bonk_item_found` WHERE `item_guid` = %u", itemGuid);
        CharacterDatabase.PExecute("UPDATE `mail` SET `has_items` = (SELECT COUNT(*) > 0 FROM `mail_items` WHERE `mail_id` = %u) WHERE `id` = %u", mailId, mailId);
        CharacterDatabase.PExecute("INSERT INTO `bonk_coop_mail_taken` (`character_guid`, `item_id`) VALUES (%u, %u)", home.characterGuid, entry);
        return "";
    }

    std::string ApplyMailTokenTaken(HomeTarget const& home, std::vector<std::string> const& fields)
    {
        if (fields.size() < 3 || !IsMailToken(fields[2]))
            return "broken mail token entry";
        if (!home.characterGuid)
            return "no home character";
        std::unique_ptr<QueryResult> found(CharacterDatabase.PQuery(
            "SELECT `item_guid` FROM `bonk_coop_mail_token` WHERE `token` = '%s' AND `character_guid` = %u", fields[2].c_str(), home.characterGuid));
        if (!found)
            return "that extracted piece never reached the home mailbox";
        uint32 const itemGuid = found->Fetch()[0].GetUInt32();
        std::unique_ptr<QueryResult> taken(CharacterDatabase.PQuery("SELECT 1 FROM `character_inventory` WHERE `item_guid` = %u", itemGuid));
        if (taken)
            return "that extracted piece was already taken from the home mailbox";
        CharacterDatabase.PExecute("DELETE `m` FROM `mail` `m` JOIN `mail_items` `mi` ON `mi`.`mail_id` = `m`.`id` WHERE `mi`.`item_guid` = %u AND `m`.`receiver_guid` = %u",
            itemGuid, home.characterGuid);
        CharacterDatabase.PExecute("DELETE FROM `mail_items` WHERE `item_guid` = %u", itemGuid);
        CharacterDatabase.PExecute("DELETE FROM `item_instance` WHERE `guid` = %u", itemGuid);
        CharacterDatabase.PExecute("DELETE FROM `bonk_item_found` WHERE `item_guid` = %u", itemGuid);
        CharacterDatabase.PExecute("DELETE FROM `bonk_coop_mail_token` WHERE `token` = '%s' AND `character_guid` = %u", fields[2].c_str(), home.characterGuid);
        return "";
    }

    std::string ApplyMailMoneyTaken(HomeTarget const& home, std::vector<std::string> const& fields)
    {
        uint32 mailId = 0, money = 0;
        if (!ReadCount(fields, 2, mailId) || !ReadCount(fields, 3, money) || !money)
            return "broken mail money entry";
        if (!home.characterGuid)
            return "no home character";
        std::unique_ptr<QueryResult> found(CharacterDatabase.PQuery(
            "SELECT `money` FROM `mail` WHERE `id` = %u AND `receiver_guid` = %u", mailId, home.characterGuid));
        if (!found || found->Fetch()[0].GetUInt32() < money)
            return "that mail's gold is no longer in the home mailbox";
        CharacterDatabase.PExecute("UPDATE `mail` SET `money` = `money` - %u WHERE `id` = %u", money, mailId);
        Credit(home, "gold", money);
        return "";
    }

    std::multiset<uint32> TakenFromMail(uint32 characterGuid)
    {
        std::multiset<uint32> entries;
        std::unique_ptr<QueryResult> result(CharacterDatabase.PQuery(
            "SELECT `item_id` FROM `bonk_coop_mail_taken` WHERE `character_guid` = %u", characterGuid));
        if (result)
        {
            do
                entries.insert(result->Fetch()[0].GetUInt32());
            while (result->NextRow());
        }
        return entries;
    }

    std::string ApplyMail(HomeTarget const& home, std::vector<std::string> const& fields)
    {
        uint32 entry = 0;
        if (!ReadCount(fields, 2, entry) || fields.size() < 6)
            return "broken mail entry";
        if (!home.characterGuid)
            return "no home character";
        if (!sObjectMgr.GetItemPrototype(entry))
            return "unknown item " + std::to_string(entry);
        if (!BonkMgr::GetGearTier(entry))
            return "item " + std::to_string(entry) + " isn't run gear";
        if (!Spend(home, "mail", MAIL_ALLOWANCE, 1))
            return OverLimit("mail");
        ObjectGuid const receiver(HIGHGUID_PLAYER, home.characterGuid);
        Item* item = Item::CreateItem(entry, 1, receiver);
        if (!item)
            return "item not created";
        item->SaveToDB();
        BonkFoundGear found;
        if (fields[5] != "-" && ReadFound(fields[5], found))
        {
            found.tier = std::min(found.tier, TierCap(home));
            BonkFound::Remember(item, found);
        }
        if (fields.size() > 6 && IsMailToken(fields[6]))
            CharacterDatabase.DirectPExecute("INSERT IGNORE INTO `bonk_coop_mail_token` (`token`, `character_guid`, `item_guid`) VALUES ('%s', %u, %u)",
                fields[6].c_str(), home.characterGuid, item->GetGUIDLow());
        MailDraft(Unescape(fields[3]), Unescape(fields[4]))
            .AddItem(item)
            .SendMailTo(MailReceiver(receiver), MailSender(MAIL_CREATURE, HOME_MAIL_SENDER));
        return "";
    }

    MirroredTable const* FindMirroredTable(std::string const& name)
    {
        for (MirroredTable const& table : MIRRORED_TABLES)
            if (name == table.name)
                return &table;
        return nullptr;
    }

    std::vector<std::string> SplitOn(std::string const& text, char separator)
    {
        std::vector<std::string> parts;
        std::string part;
        for (char c : text)
        {
            if (c == separator)
            {
                parts.push_back(part);
                part.clear();
            }
            else
                part += c;
        }
        parts.push_back(part);
        return parts;
    }

    bool RowRankAllowed(std::string const& table, std::vector<std::string> const& values)
    {
        if (table != "bonk_account_upgrade" && table != "bonk_account_talent")
            return true;
        if (values.size() < 2)
            return false;
        uint32 const id = uint32(std::strtoul(values[0].c_str(), nullptr, 10));
        uint32 const rank = uint32(std::strtoul(values[1].c_str(), nullptr, 10));
        if (table == "bonk_account_upgrade")
        {
            BonkUpgrade const* upgrade = sBonkMgr.GetUpgrade(id);
            return upgrade && rank <= upgrade->maxRank;
        }
        if (table == "bonk_account_talent")
        {
            BonkTalent const* talent = sBonkMgr.GetTalent(id);
            return talent && rank <= talent->maxRank;
        }
        return true;
    }

    std::string ApplyRows(HomeTarget const& home, std::vector<std::string> const& fields)
    {
        if (fields.size() < 4)
            return "broken rows entry";
        MirroredTable const* table = FindMirroredTable(fields[2]);
        if (!table)
            return "unknown table " + fields[2];
        uint32 const owner = table->owner == MIRROR_CHARACTER_GUID ? home.characterGuid : table->owner == MIRROR_CHARACTER_PROGRESS ? home.characterAccount : home.accountId;
        if (!owner)
            return "no home character";
        std::vector<std::string> statements;
        if (!fields[3].empty())
        {
            for (std::string const& row : SplitOn(fields[3], ';'))
            {
                std::vector<std::string> const values = SplitOn(row, ',');
                if (values.size() + 1 != table->columns)
                    return std::string("broken row for ") + table->name;
                std::string list = std::to_string(owner);
                for (std::string const& value : values)
                {
                    if (value.empty() || value.find_first_not_of("0123456789") != std::string::npos)
                        return std::string("broken value for ") + table->name;
                    list += "," + value;
                }
                if (!RowRankAllowed(table->name, values))
                    return std::string("a rank above the maximum in ") + table->name;
                statements.push_back(std::string("INSERT INTO `") + table->name + "` VALUES (" + list + ")");
            }
        }
        CharacterDatabase.PExecute("DELETE FROM `%s` WHERE `%s` = %u", table->name, table->owner == MIRROR_CHARACTER_GUID ? "guid" : "account", owner);
        for (std::string const& statement : statements)
            CharacterDatabase.Execute(statement.c_str());
        return "";
    }

    std::string ReadTableRows(MirroredTable const& table, uint32 owner)
    {
        std::unique_ptr<QueryResult> result(CharacterDatabase.PQuery("SELECT * FROM `%s` WHERE `%s` = %u",
            table.name, table.owner == MIRROR_CHARACTER_GUID ? "guid" : "account", owner));
        std::vector<std::string> rows;
        if (result)
        {
            do
            {
                Field* values = result->Fetch();
                std::string row;
                for (uint32 i = 1; i < result->GetFieldCount(); ++i)
                    row += (i > 1 ? "," : "") + std::to_string(values[i].GetUInt32());
                rows.push_back(row);
            } while (result->NextRow());
        }
        std::sort(rows.begin(), rows.end());
        std::string text;
        for (size_t i = 0; i < rows.size(); ++i)
            text += (i ? ";" : "") + rows[i];
        return text;
    }

    std::string DescribeItem(Item const* item, uint32 parent, uint32 slot)
    {
        std::ostringstream charges;
        for (uint8 i = 0; i < MAX_ITEM_PROTO_SPELLS; ++i)
            charges << item->GetSpellCharges(i) << ' ';
        std::ostringstream enchants;
        for (uint8 i = 0; i < MAX_ENCHANTMENT_SLOT; ++i)
            enchants << item->GetEnchantmentId(EnchantmentSlot(i)) << ' ' << item->GetEnchantmentDuration(EnchantmentSlot(i)) << ' '
                << item->GetEnchantmentCharges(EnchantmentSlot(i)) << ' ';
        BonkFoundGear found;
        bool const isFound = sBonkFound.Get(item->GetGUIDLow(), found);
        std::ostringstream out;
        out << item->GetGUIDLow() << '|' << parent << '|' << slot << '|' << item->GetEntry() << '|' << item->GetCount() << '|'
            << item->GetUInt32Value(ITEM_FIELD_DURABILITY) << '|' << item->GetUInt32Value(ITEM_FIELD_FLAGS) << '|' << charges.str() << '|'
            << enchants.str() << '|' << item->GetItemRandomPropertyId() << '|' << (isFound ? WriteFound(found) : std::string("-"));
        return out.str();
    }

    std::string DescribeInventory(Player const* player)
    {
        std::vector<std::string> items;
        auto add = [&](uint8 slot)
        {
            Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
            if (!item)
                return;
            items.push_back(DescribeItem(item, 0, slot));
            if (Bag const* bag = item->IsBag() ? static_cast<Bag const*>(item) : nullptr)
                for (uint32 inside = 0; inside < bag->GetBagSize(); ++inside)
                    if (Item* content = bag->GetItemByPos(uint8(inside)))
                        items.push_back(DescribeItem(content, item->GetGUIDLow(), inside));
        };
        for (uint8 slot = EQUIPMENT_SLOT_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
            add(slot);
        for (uint8 slot = KEYRING_SLOT_START; slot < KEYRING_SLOT_END; ++slot)
            add(slot);
        std::string text;
        for (size_t i = 0; i < items.size(); ++i)
            text += (i ? ";" : "") + items[i];
        return text;
    }

    std::vector<uint32> HomeCarriedItems(uint32 characterGuid)
    {
        std::vector<uint32> items;
        std::unique_ptr<QueryResult> result(CharacterDatabase.PQuery(
            "SELECT ci.`item_guid` FROM `character_inventory` ci WHERE ci.`guid` = %u "
            "AND NOT (ci.`bag` = 0 AND ci.`slot` >= %u AND ci.`slot` < %u) "
            "AND ci.`bag` NOT IN (SELECT b.`item_guid` FROM `character_inventory` b WHERE b.`guid` = %u AND b.`bag` = 0 AND b.`slot` >= %u AND b.`slot` < %u)",
            characterGuid, uint32(BANK_SLOT_ITEM_START), uint32(BANK_SLOT_BAG_END), characterGuid, uint32(BANK_SLOT_BAG_START), uint32(BANK_SLOT_BAG_END)));
        if (result)
        {
            do
                items.push_back(result->Fetch()[0].GetUInt32());
            while (result->NextRow());
        }
        return items;
    }

    std::set<uint32> HomeCarriedEntries(uint32 characterGuid)
    {
        std::set<uint32> entries;
        std::unique_ptr<QueryResult> result(CharacterDatabase.PQuery(
            "SELECT DISTINCT `item_id` FROM `character_inventory` WHERE `guid` = %u", characterGuid));
        if (result)
        {
            do
                entries.insert(result->Fetch()[0].GetUInt32());
            while (result->NextRow());
        }
        return entries;
    }

    struct CarriedItem
    {
        uint32 local = 0;
        uint32 parent = 0;
        uint32 slot = 0;
        uint32 entry = 0;
        uint32 count = 1;
        uint32 durability = 0;
        uint32 flags = 0;
        std::string charges;
        std::string enchants;
        int32 randomProperty = 0;
        std::string found;
    };

    bool ReadCarriedItem(std::string const& text, CarriedItem& item)
    {
        std::vector<std::string> const parts = SplitOn(text, '|');
        if (parts.size() != 11)
            return false;
        for (size_t i : { 0, 1, 2, 3, 4, 5, 6 })
            if (parts[i].empty() || parts[i].find_first_not_of("0123456789") != std::string::npos)
                return false;
        item.local = uint32(std::strtoul(parts[0].c_str(), nullptr, 10));
        item.parent = uint32(std::strtoul(parts[1].c_str(), nullptr, 10));
        item.slot = uint32(std::strtoul(parts[2].c_str(), nullptr, 10));
        item.entry = uint32(std::strtoul(parts[3].c_str(), nullptr, 10));
        item.count = uint32(std::strtoul(parts[4].c_str(), nullptr, 10));
        item.durability = uint32(std::strtoul(parts[5].c_str(), nullptr, 10));
        item.flags = uint32(std::strtoul(parts[6].c_str(), nullptr, 10));
        item.charges = parts[7];
        item.enchants = parts[8];
        item.randomProperty = int32(std::strtol(parts[9].c_str(), nullptr, 10));
        item.found = parts[10];
        return sObjectMgr.GetItemPrototype(item.entry) != nullptr;
    }

    void FillCarriedItem(Item* made, CarriedItem const& carried)
    {
        made->SetCount(std::max(1u, carried.count));
        made->SetUInt32Value(ITEM_FIELD_DURABILITY, carried.durability);
        made->SetUInt32Value(ITEM_FIELD_FLAGS, carried.flags);
        std::istringstream charges(carried.charges);
        for (uint8 i = 0; i < MAX_ITEM_PROTO_SPELLS; ++i)
        {
            int32 value = 0;
            if (charges >> value)
                made->SetSpellCharges(i, value);
        }
        std::istringstream enchants(carried.enchants);
        for (uint8 i = 0; i < MAX_ENCHANTMENT_SLOT; ++i)
        {
            uint32 id = 0, duration = 0, count = 0;
            if (enchants >> id >> duration >> count)
                made->SetEnchantment(EnchantmentSlot(i), id, duration, count);
        }
        if (carried.randomProperty)
            made->SetItemRandomProperties(carried.randomProperty);
    }

    std::string ApplyInventory(HomeTarget const& home, std::vector<std::string> const& fields)
    {
        if (fields.size() < 3)
            return "broken inventory entry";
        if (!home.characterGuid)
            return "no home character";
        std::vector<CarriedItem> carried;
        if (!fields[2].empty())
        {
            for (std::string const& text : SplitOn(fields[2], ';'))
            {
                CarriedItem item;
                if (!ReadCarriedItem(text, item))
                    return "broken item " + text.substr(0, 40);
                carried.push_back(item);
            }
        }
        std::set<uint32> const owned = HomeCarriedEntries(home.characterGuid);
        std::multiset<uint32> fromMail = TakenFromMail(home.characterGuid);
        uint32 const tierCap = TierCap(home);
        std::vector<CarriedItem> allowed;
        for (CarriedItem const& item : carried)
        {
            ItemPrototype const* proto = sObjectMgr.GetItemPrototype(item.entry);
            BonkFoundGear found;
            bool familiar = owned.count(item.entry) || BonkMgr::GetGearTier(item.entry) || proto->Class == ITEM_CLASS_CONTAINER;
            auto const mailed = fromMail.find(item.entry);
            if (!familiar && mailed != fromMail.end())
            {
                familiar = true;
                fromMail.erase(mailed);
                CharacterDatabase.PExecute("DELETE FROM `bonk_coop_mail_taken` WHERE `character_guid` = %u AND `item_id` = %u LIMIT 1", home.characterGuid, item.entry);
            }
            bool const tooMany = item.count > std::max(1u, proto->Stackable);
            bool const tooHigh = item.found != "-" && ReadFound(item.found, found) && found.tier > tierCap;
            if (familiar && !tooMany && !tooHigh)
                allowed.push_back(item);
            else
                sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op ledger: account %u left out item %u (%s)", home.accountId, item.entry,
                    !familiar ? "can't come from a co-op game" : tooMany ? "too many" : "above the tier cap");
        }
        carried.swap(allowed);
        std::vector<uint32> const old = HomeCarriedItems(home.characterGuid);
        if (!old.empty())
        {
            std::string list;
            for (uint32 guid : old)
            {
                list += (list.empty() ? "" : ",") + std::to_string(guid);
                sBonkFound.Forget(guid);
            }
            CharacterDatabase.PExecute("DELETE FROM `item_instance` WHERE `guid` IN (%s)", list.c_str());
            CharacterDatabase.PExecute("DELETE FROM `character_inventory` WHERE `item_guid` IN (%s)", list.c_str());
        }
        ObjectGuid const owner(HIGHGUID_PLAYER, home.characterGuid);
        std::map<uint32, uint32> made;
        for (CarriedItem const& item : carried)
        {
            Item* created = Item::CreateItem(item.entry, 1, owner);
            if (!created)
                continue;
            FillCarriedItem(created, item);
            created->SaveToDB();
            made[item.local] = created->GetGUIDLow();
            BonkFoundGear found;
            if (item.found != "-" && ReadFound(item.found, found))
                sBonkFound.Set(created->GetGUIDLow(), found);
            delete created;
        }
        for (CarriedItem const& item : carried)
        {
            auto const self = made.find(item.local);
            if (self == made.end())
                continue;
            uint32 bag = 0;
            if (item.parent)
            {
                auto const parent = made.find(item.parent);
                if (parent == made.end())
                    continue;
                bag = parent->second;
            }
            CharacterDatabase.PExecute("INSERT INTO `character_inventory` (`guid`, `bag`, `slot`, `item_guid`, `item_id`) VALUES (%u, %u, %u, %u, %u)",
                home.characterGuid, bag, item.slot, self->second, item.entry);
        }
        return "";
    }

    std::string ApplyAppearance(HomeTarget const& home, std::vector<std::string> const& fields)
    {
        if (fields.size() < 3 || !home.characterGuid)
            return "appearance without a character";
        std::unique_ptr<QueryResult> owner(CharacterDatabase.PQuery("SELECT `account` FROM `characters` WHERE `guid` = %u", home.characterGuid));
        if (!owner)
            return "appearance for a missing character";
        CharacterDatabase.PExecute("INSERT IGNORE INTO `bonk_account_appearance` (`account`, `entry`) VALUES (%u, %u)",
            owner->Fetch()[0].GetUInt32(), uint32(atoi(fields[2].c_str())));
        return "";
    }

    std::string ApplyEntry(HomeTarget const& home, std::vector<std::string> const& fields)
    {
        std::string const& kind = fields[1];
        if (kind == "inventory")
            return ApplyInventory(home, fields);
        if (kind == "mailitem")
            return ApplyMailItemTaken(home, fields);
        if (kind == "mailmoney")
            return ApplyMailMoneyTaken(home, fields);
        if (kind == "mailtoken")
            return ApplyMailTokenTaken(home, fields);
        if (kind == "rows")
            return ApplyRows(home, fields);
        if (kind == "gold")
            return ApplyAccountColumn(home, fields, "gold", 0xFFFFFFFFll, &GOLD_ALLOWANCE);
        if (kind == "shards")
            return ApplyAccountColumn(home, fields, "shards", 0xFFFFFFFFll, &SHARDS_ALLOWANCE);
        if (kind == "scrap")
            return ApplyAccountColumn(home, fields, "scrap", 0xFFFFFFFFll, &SCRAP_ALLOWANCE);
        if (kind == "determination")
            return ApplyAccountColumn(home, fields, "determination", BONK_DETERMINATION_MAX_STACKS, nullptr);
        if (kind == "mastery")
            return ApplyMastery(home, fields);
        if (kind == "quest")
            return ApplyQuest(home, fields);
        if (kind == "runstats")
            return ApplyRunStats(home, fields);
        if (kind == "level")
            return ApplyLevel(home, fields);
        if (kind == "levelbest")
            return ApplyLevelBest(home, fields);
        if (kind == "finalebest")
            return ApplyFinaleBest(home, fields);
        if (kind == "appearance")
            return ApplyAppearance(home, fields);
        return "unknown entry " + kind;
    }

    GuestTotals ReadTotals(Player const* guest)
    {
        BonkPlayer const* bonk = guest->GetBonkPlayer();
        GuestTotals totals;
        totals.gold = guest->GetMoney();
        totals.shards = bonk->GetShards();
        totals.scrap = bonk->GetScrap();
        totals.determination = bonk->GetDeterminationStacks();
        totals.masteryXp = bonk->GetMasteryXp();
        bonk->GetRunRecord(totals.runs, totals.bestLevel, totals.bestSeconds, totals.kills, totals.goldEarned);
        totals.quests = sBonkQuests.GetAllProgress(bonk->GetProgressAccount());
        for (MirroredTable const& table : MIRRORED_TABLES)
            totals.tables[table.name] = ReadTableRows(table, table.owner == MIRROR_CHARACTER_GUID ? guest->GetGUIDLow() :
                table.owner == MIRROR_CHARACTER_PROGRESS ? bonk->GetCharacterAccount() : bonk->GetProgressAccount());
        totals.inRun = bonk->GetRun() != nullptr;
        if (!totals.inRun)
            totals.inventory = DescribeInventory(guest);
        return totals;
    }

    void RecordDelta(Player const* guest, char const* kind, uint32 before, uint32 now)
    {
        if (before != now)
            BonkCoop::Record(guest, std::string(kind) + "\t" + std::to_string(int64(now) - int64(before)));
    }

    void RecordChanges(Player const* guest, GuestTotals const& before, GuestTotals const& now)
    {
        RecordDelta(guest, "gold", before.gold, now.gold);
        RecordDelta(guest, "shards", before.shards, now.shards);
        RecordDelta(guest, "scrap", before.scrap, now.scrap);
        RecordDelta(guest, "determination", before.determination, now.determination);
        if (before.masteryXp != now.masteryXp)
            BonkCoop::Record(guest, "mastery\t" + std::to_string(uint32(guest->GetClass())) + "\t" + std::to_string(int64(now.masteryXp) - int64(before.masteryXp)));
        if (now.runs != before.runs || now.kills != before.kills || now.goldEarned != before.goldEarned || now.bestLevel != before.bestLevel || now.bestSeconds != before.bestSeconds)
            BonkCoop::Record(guest, "runstats\t" + std::to_string(now.runs - std::min(now.runs, before.runs)) + "\t" + std::to_string(now.bestLevel) + "\t" +
                std::to_string(now.bestSeconds) + "\t" + std::to_string(now.kills - std::min(now.kills, before.kills)) + "\t" +
                std::to_string(now.goldEarned - std::min(now.goldEarned, before.goldEarned)));
        if (!now.inRun && now.inventory != before.inventory)
            BonkCoop::Record(guest, "inventory\t" + now.inventory);
        for (auto const& table : now.tables)
        {
            auto const old = before.tables.find(table.first);
            if (old == before.tables.end() || old->second != table.second)
                BonkCoop::Record(guest, "rows\t" + table.first + "\t" + table.second);
        }
        for (auto const& quest : now.quests)
        {
            auto const old = before.quests.find(quest.first);
            if (old != before.quests.end() && old->second == quest.second)
                continue;
            BonkCoop::Record(guest, "quest\t" + std::to_string(quest.first) + "\t" + std::to_string(quest.second.first) + "\t" + (quest.second.second ? "1" : "0"));
        }
    }

    HomeTarget FindHome(std::string const& username, std::string const& character)
    {
        HomeTarget home;
        home.accountId = sAccountMgr.GetId(username);
        if (!home.accountId || character.empty())
            return home;
        std::string name = character;
        CharacterDatabase.escape_string(name);
        std::unique_ptr<QueryResult> result(CharacterDatabase.PQuery("SELECT `guid` FROM `characters` WHERE `name` = '%s' AND `account` = %u", name.c_str(), home.accountId));
        if (!result)
            return home;
        home.characterGuid = result->Fetch()[0].GetUInt32();
        home.characterAccount = BonkPlayer::GetCharacterAccountOf(home.characterGuid);
        home.accountId = BonkPlayer::GetProgressAccountOf(home.characterGuid, home.accountId);
        return home;
    }

    bool AlreadyApplied(uint32 accountId, std::string const& game, uint32 seq)
    {
        std::unique_ptr<QueryResult> result(CharacterDatabase.PQuery(
            "SELECT 1 FROM `bonk_coop_applied` WHERE `account` = %u AND `game` = '%s' AND `seq` = %u", accountId, game.c_str(), seq));
        return result != nullptr;
    }

    std::string ApplyLine(HomeTarget const& home, std::string const& game, std::string const& line)
    {
        uint32 const accountId = home.accountId;
        std::vector<std::string> const fields = SplitTabs(line);
        uint32 seq = 0;
        if (fields.size() < 2 || !ReadCount(fields, 0, seq) || seq == 0)
            return "";
        std::string const prefix = std::to_string(seq) + "\t";
        if (AlreadyApplied(accountId, game, seq))
            return prefix + "ok\n";
        if (fields[1] == "mail")
        {
            if (!CharacterDatabase.DirectPExecute("INSERT INTO `bonk_coop_applied` (`account`, `game`, `seq`) VALUES (%u, '%s', %u)", accountId, game.c_str(), seq))
                return prefix + "retry\n";
            std::string const problem = ApplyMail(home, fields);
            if (problem.empty())
                return prefix + "ok\n";
            sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op ledger: account %u refused entry %u (%s)", accountId, seq, problem.c_str());
            return prefix + "refused\t" + problem + "\n";
        }
        GameBudget const budgetBefore = BudgetOf(home);
        CharacterDatabase.BeginTransaction();
        std::string const problem = ApplyEntry(home, fields);
        if (!problem.empty())
        {
            CharacterDatabase.RollbackTransaction();
            RestoreBudget(home, budgetBefore);
            sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op ledger: account %u refused entry %u (%s)", accountId, seq, problem.c_str());
            return prefix + "refused\t" + problem + "\n";
        }
        CharacterDatabase.PExecute("INSERT INTO `bonk_coop_applied` (`account`, `game`, `seq`) VALUES (%u, '%s', %u)", accountId, game.c_str(), seq);
        if (!CharacterDatabase.CommitTransactionDirect())
        {
            RestoreBudget(home, budgetBefore);
            return prefix + "retry\n";
        }
        return prefix + "ok\n";
    }

    void WriteWhole(std::string const& path, std::string const& text)
    {
        std::string const temporary = path + ".tmp";
        {
            std::ofstream out(temporary, std::ios::binary | std::ios::trunc);
            out << text;
        }
#if PLATFORM == PLATFORM_WINDOWS
        MoveFileExA(temporary.c_str(), path.c_str(), MOVEFILE_REPLACE_EXISTING);
#else
        std::rename(temporary.c_str(), path.c_str());
#endif
    }

    std::string ReadWhole(std::string const& path)
    {
        std::ifstream in(path, std::ios::binary);
        std::ostringstream text;
        text << in.rdbuf();
        return text.str();
    }

    bool IsSafeGame(std::string const& game)
    {
        return !game.empty() && game.size() <= MAX_GAME_LENGTH && game.find_first_not_of("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_") == std::string::npos;
    }

    std::string ApplyInbox(std::string const& text)
    {
        std::istringstream in(text);
        std::string header;
        std::getline(in, header);
        std::vector<std::string> const from = SplitTabs(header);
        if (from.size() < 3 || from[0] != "from" || !IsSafeGame(from[2]))
            return "error broken ledger\n";
        HomeTarget home = FindHome(from[1], from.size() >= 4 ? from[3] : "");
        home.game = from[2];
        if (!home.accountId)
            return "error There is no account called " + from[1] + ".\n";
        std::string answers;
        std::string line;
        while (std::getline(in, line))
            if (!line.empty())
                answers += ApplyLine(home, from[2], line);
        return answers;
    }

    struct Leaving
    {
        time_t offlineSince = 0;
        bool loggingOut = false;
        bool removed = false;
    };

    std::map<std::string, Leaving> s_leaving;

    bool IsGuestName(std::string const& username)
    {
        return username.compare(0, 4, "HOAC") == 0 && username.size() <= 32 &&
            username.find_first_not_of("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") == std::string::npos;
    }

    void LeaveAllGuests()
    {
        std::unique_ptr<QueryResult> result(LoginDatabase.Query("SELECT `username` FROM `account` WHERE `username` LIKE 'HOAC%'"));
        uint32 count = 0;
        if (result)
        {
            do
            {
                std::string const username = result->Fetch()[0].GetCppString();
                if (IsGuestName(username) && s_leaving.emplace(username, Leaving()).second)
                    ++count;
            }
            while (result->NextRow());
        }
        if (count)
            sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op: a new hosting session removes %u guest accounts left from before", count);
    }

    void ReadLeaveRequests()
    {
        std::remove(LEAVE_WORK_FILE);
        if (std::rename(LEAVE_FILE, LEAVE_WORK_FILE) != 0)
            return;
        std::istringstream in(ReadWhole(LEAVE_WORK_FILE));
        std::remove(LEAVE_WORK_FILE);
        std::string username;
        while (in >> username)
        {
            if (username == "*")
                LeaveAllGuests();
            else if (IsGuestName(username))
                s_leaving.emplace(username, Leaving());
        }
    }

    void LogOutIfLeaving(Player* guest, std::string const& username)
    {
        auto found = s_leaving.find(username);
        if (found == s_leaving.end())
            return;
        found->second.offlineSince = 0;
        if (found->second.loggingOut)
            return;
        found->second.loggingOut = true;
        WorldSession* session = guest->GetSession();
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op: %s left the party, logging out now", guest->GetName());
        if (!session->IsConnected())
            session->KickDisconnectedFromWorld();
        else if (!session->IsLogingOut())
            session->LogoutRequest(time(nullptr) - 20);
    }

    void ReadAnswers(std::string const& username)
    {
        std::string const path = AnswersPath(username);
        std::ifstream probe(path, std::ios::binary);
        if (!probe.good())
            return;
        probe.close();
        std::istringstream in(ReadWhole(path));
        std::remove(path.c_str());
        std::string line;
        while (std::getline(in, line))
        {
            std::vector<std::string> const fields = SplitTabs(line);
            if (fields.size() >= 2 && fields[1] == "refused")
                sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op ledger: %s's home refused entry %s (%s)", username.c_str(), fields[0].c_str(),
                    fields.size() >= 3 ? fields[2].c_str() : "");
        }
    }
}

void BonkCoop::Record(Player const* guest, std::string const& entry)
{
    if (!IsGuestAccount(guest))
        return;
    std::string const username = guest->GetSession()->GetUsername();
    std::string const path = OutboxPath(username);
    std::lock_guard<std::mutex> guard(s_outboxLock);
    auto found = s_lastSeq.find(username);
    uint32 const seq = (found == s_lastSeq.end() ? LastSeqInFile(path) : found->second) + 1;
    s_lastSeq[username] = seq;
    s_unwritten[username] += std::to_string(seq) + "\t" + entry + "\n";
    FlushOutbox(username);
}

void BonkCoop::SyncGuest(Player* guest)
{
    if (!IsGuestAccount(guest) || !guest->GetBonkPlayer() || !guest->GetBonkPlayer()->IsGoldLoaded())
        return;
    GuestTotals const now = ReadTotals(guest);
    GuestTotals before;
    {
        std::lock_guard<std::mutex> guard(s_guestLock);
        auto found = s_guests.find(guest->GetObjectGuid());
        if (found == s_guests.end())
        {
            s_guests[guest->GetObjectGuid()] = now;
            return;
        }
        before = found->second;
        found->second = now;
        if (now.inRun)
            found->second.inventory = before.inventory;
    }
    RecordChanges(guest, before, now);
}

void BonkCoop::ForgetGuest(Player const* guest)
{
    std::lock_guard<std::mutex> guard(s_guestLock);
    s_guests.erase(guest->GetObjectGuid());
}

namespace
{
    struct HomeMailItemLink
    {
        uint32 mail = 0;
        uint32 item = 0;
    };

    std::mutex s_homeMailLock;
    std::map<uint32, uint32> s_homeMails;
    std::map<uint32, HomeMailItemLink> s_homeMailItems;
    std::map<uint32, std::string> s_sentHomeTokens;
}

void BonkCoop::RecordMail(Player const* guest, uint32 hostItem, uint32 entry, std::string const& subject, std::string const& body, BonkFoundGear const* found)
{
    if (!IsGuestAccount(guest))
        return;
    std::string const token = std::to_string(guest->GetGUIDLow()) + "-" + std::to_string(hostItem) + "-" + std::to_string(uint64(time(nullptr)));
    {
        std::lock_guard<std::mutex> guard(s_homeMailLock);
        s_sentHomeTokens[hostItem] = token;
    }
    Record(guest, "mail\t" + std::to_string(entry) + "\t" + Escape(subject) + "\t" + Escape(body) + "\t" + (found ? WriteFound(*found) : std::string("-")) +
        "\t" + token);
}

void BonkCoop::RememberHomeMail(uint32 hostMail, uint32 homeMail)
{
    std::lock_guard<std::mutex> guard(s_homeMailLock);
    s_homeMails[hostMail] = homeMail;
}

void BonkCoop::RememberHomeMailItem(uint32 hostItem, uint32 homeMail, uint32 homeItem)
{
    std::lock_guard<std::mutex> guard(s_homeMailLock);
    s_homeMailItems[hostItem] = HomeMailItemLink{ homeMail, homeItem };
}

void BonkCoop::OnMailItemTaken(Player const* guest, uint32 hostMail, uint32 hostItem, uint32 entry)
{
    if (!IsGuestAccount(guest))
        return;
    HomeMailItemLink link;
    std::string token;
    {
        std::lock_guard<std::mutex> guard(s_homeMailLock);
        auto found = s_homeMailItems.find(hostItem);
        if (found != s_homeMailItems.end())
        {
            link = found->second;
            s_homeMailItems.erase(found);
        }
        else
        {
            auto sent = s_sentHomeTokens.find(hostItem);
            if (sent == s_sentHomeTokens.end())
                return;
            token = sent->second;
            s_sentHomeTokens.erase(sent);
        }
    }
    if (!token.empty())
    {
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op: %s took extracted item %u on the host (%s)", guest->GetName(), entry, token.c_str());
        Record(guest, "mailtoken\t" + token);
        return;
    }
    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op: %s took item %u from home mail %u", guest->GetName(), entry, link.mail);
    Record(guest, "mailitem\t" + std::to_string(link.mail) + "\t" + std::to_string(link.item) + "\t" + std::to_string(entry));
}

void BonkCoop::OnMailMoneyTaken(Player const* guest, uint32 hostMail, uint32 money)
{
    if (!IsGuestAccount(guest) || !money)
        return;
    uint32 homeMail = 0;
    {
        std::lock_guard<std::mutex> guard(s_homeMailLock);
        auto found = s_homeMails.find(hostMail);
        if (found == s_homeMails.end())
            return;
        homeMail = found->second;
    }
    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op: %s took %u copper from home mail %u", guest->GetName(), money, homeMail);
    Record(guest, "mailmoney\t" + std::to_string(homeMail) + "\t" + std::to_string(money));
}

void BonkCoop::RecordLevel(Player const* guest, uint32 classId, uint32 bestLevel, uint32 bestMs, uint32 finale)
{
    Record(guest, "level	" + std::to_string(classId) + "	" + std::to_string(bestLevel) + "	" + std::to_string(bestMs) + "	" + std::to_string(finale));
}

void BonkCoop::RecordLevelBest(Player const* guest, uint32 classId, BonkPlayer::LevelRun const& run)
{
    Record(guest, "levelbest	" + std::to_string(classId) + "	" + std::to_string(run.level) + "	" + std::to_string(run.ms) + "	" +
        std::to_string(run.kills) + "	" + std::to_string(run.damage) + "	" + std::to_string(run.gold) + "	" + std::to_string(run.valor));
}

void BonkCoop::RecordFinaleBest(Player const* guest, uint32 classId, uint32 level, uint32 score, uint32 seconds)
{
    Record(guest, "finalebest	" + std::to_string(classId) + "	" + std::to_string(level) + "	" + std::to_string(score) + "	" + std::to_string(seconds));
}

bool BonkCoop::IsPlayingElsewhere(std::string const& username)
{
    std::ifstream in("coop/away-" + username + ".txt", std::ios::binary);
    long long stamp = 0;
    if (!(in >> stamp))
        return false;
    return time(nullptr) - time_t(stamp) < AWAY_FRESH_SECONDS;
}

namespace
{
    void RemoveLedgerFiles(std::string const& username)
    {
        std::remove(OutboxPath(username).c_str());
        std::remove(AnswersPath(username).c_str());
        s_lastSeq.erase(username);
    }

    void RemoveLeftGuests(std::set<std::string> const& present)
    {
        time_t const now = time(nullptr);
        for (auto itr = s_leaving.begin(); itr != s_leaving.end();)
        {
            Leaving& leaving = itr->second;
            if (present.count(itr->first))
            {
                ++itr;
                continue;
            }
            if (!leaving.offlineSince)
                leaving.offlineSince = now;
            if (!leaving.removed && now - leaving.offlineSince >= GUEST_REMOVE_SECONDS)
            {
                BonkCoop::DeleteGuestAccount(itr->first);
                leaving.removed = true;
            }
            std::lock_guard<std::mutex> guard(s_outboxLock);
            if (leaving.removed && now - leaving.offlineSince >= LEDGER_KEEP_SECONDS && !s_unwritten.count(itr->first))
            {
                RemoveLedgerFiles(itr->first);
                itr = s_leaving.erase(itr);
                continue;
            }
            ++itr;
        }
    }
}

void BonkCoop::UpdateLedger()
{
    std::ifstream probe(INBOX_FILE, std::ios::binary);
    if (probe.good())
    {
        probe.close();
        std::string const text = ReadWhole(INBOX_FILE);
        std::remove(INBOX_FILE);
        WriteWhole(INBOX_ANSWER_FILE, ApplyInbox(text));
    }
    s_guestTimer += 1000;
    bool const syncGuests = s_guestTimer >= GUEST_SYNC_MS;
    if (syncGuests)
        s_guestTimer = 0;
    ReadLeaveRequests();
    std::set<std::string> present;
    std::string online;
    {
        std::lock_guard<std::mutex> guard(s_outboxLock);
        std::vector<std::string> waiting;
        for (auto const& unwritten : s_unwritten)
            waiting.push_back(unwritten.first);
        for (std::string const& username : waiting)
            FlushOutbox(username);
        for (auto const& unwritten : s_unwritten)
            online += unwritten.first + "\n";
    }
    for (auto const& entry : sObjectAccessor.GetPlayers())
    {
        Player* player = entry.second;
        if (!player || !IsGuestAccount(player))
            continue;
        std::string const username = player->GetSession()->GetUsername();
        online += username + "\n";
        if (syncGuests && player->IsInWorld())
            SyncGuest(player);
        ReadAnswers(username);
        present.insert(username);
        LogOutIfLeaving(player, username);
    }
    WriteWhole(ONLINE_GUESTS_FILE, online);
    RemoveLeftGuests(present);
}

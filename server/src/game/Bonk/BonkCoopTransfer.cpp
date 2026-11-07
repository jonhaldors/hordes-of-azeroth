#include "BonkCoop.h"
#include "BonkLocale.h"
#include "BonkPlayer.h"

#include "AccountMgr.h"
#include "Database/DatabaseEnv.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerDump.h"

#include <cstdio>
#include <cstring>
#include <set>
#include <fstream>
#include <map>
#include <mutex>
#include <sstream>
#include <string>
#include <vector>

namespace
{
    char const* const REQUEST_FILE = "coop/transfer.req";
    char const* const ANSWER_FILE = "coop/transfer.done";
    char const* const DUMP_FILE = "coop/transfer.dump";
    char const* const ACCOUNT_FILE = "coop/transfer.account";
    uint32 const SCAN_INTERVAL_MS = 1000;
    size_t const MAX_NAME_LENGTH = 12;

    char const* const ACCOUNT_TABLES[] = {
        "bonk_account", "bonk_account_disabled", "bonk_account_board", "bonk_account_epic_luck", "bonk_account_kept_talents", "bonk_account_level", "bonk_account_level_best", "bonk_account_mastery",
        "bonk_account_mastery_node", "bonk_account_mastery_preset", "bonk_account_mastery_preset_active", "bonk_account_quest",
        "bonk_account_starter", "bonk_account_talent", "bonk_account_unlock", "bonk_account_upgrade",
    };

    uint32 const SAVE_SETTLE_MS = 2000;
    uint32 const DELETE_WAIT_MS = 20000;

    uint32 s_scanTimer = 0;

    struct Pending
    {
        bool active = false;
        bool import = false;
        std::string username;
        std::string name;
        uint32 accountId = 0;
        uint32 guid = 0;
        uint32 waitedMs = 0;
    };

    Pending s_pending;

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
            else
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

    std::vector<std::string> SplitTabs(std::string const& line)
    {
        std::vector<std::string> fields;
        std::string field;
        for (size_t i = 0; i < line.size(); ++i)
        {
            if (line[i] == '\\' && i + 1 < line.size())
            {
                field += line[i];
                field += line[++i];
            }
            else if (line[i] == '\t')
            {
                fields.push_back(field);
                field.clear();
            }
            else
                field += line[i];
        }
        fields.push_back(field);
        return fields;
    }

    bool IsAccountTable(std::string const& table)
    {
        for (char const* name : ACCOUNT_TABLES)
            if (table == name)
                return true;
        return false;
    }

    char const* const CHARACTER_ROW_PREFIX = "character:";

    bool IsCharacterRow(std::string const& table, Field* fields)
    {
        if (table == "bonk_account_mastery_node")
            return true;
        if (table == "bonk_account_level")
            return fields[1].GetUInt32() != 0;
        for (char const* classTable : { "bonk_account_mastery", "bonk_account_mastery_preset", "bonk_account_mastery_preset_active", "bonk_account_starter",
            "bonk_account_level_best", "bonk_account_kept_talents" })
            if (table == classTable)
                return true;
        return false;
    }

    void ExportRows(std::ostringstream& out, char const* table, uint32 account, bool characterRows)
    {
        std::unique_ptr<QueryResult> result(CharacterDatabase.PQuery("SELECT * FROM `%s` WHERE `account` = %u", table, account));
        if (!result)
            return;
        uint32 const columns = result->GetFieldCount();
        do
        {
            Field* fields = result->Fetch();
            if (IsCharacterRow(table, fields) != characterRows)
                continue;
            out << (characterRows ? CHARACTER_ROW_PREFIX : "") << table;
            for (uint32 i = 1; i < columns; ++i)
                out << '\t' << (fields[i].IsNULL() ? std::string("\\N") : Escape(fields[i].GetCppString()));
            out << '\n';
        } while (result->NextRow());
    }

    std::string ExportAccountRows(uint32 accountId, uint32 characterAccount)
    {
        std::ostringstream out;
        for (char const* table : ACCOUNT_TABLES)
        {
            ExportRows(out, table, accountId, false);
            ExportRows(out, table, characterAccount, true);
        }
        return out.str();
    }

    bool ImportAccountRows(std::string const& text, uint32 accountId, uint32 characterAccount)
    {
        std::istringstream in(text);
        std::string line;
        std::vector<std::string> statements;
        while (std::getline(in, line))
        {
            if (line.empty())
                continue;
            std::vector<std::string> fields = SplitTabs(line);
            bool const characterRow = fields[0].compare(0, strlen(CHARACTER_ROW_PREFIX), CHARACTER_ROW_PREFIX) == 0;
            if (characterRow)
                fields[0] = fields[0].substr(strlen(CHARACTER_ROW_PREFIX));
            if (!IsAccountTable(fields[0]))
                return false;
            std::string values = std::to_string(characterRow ? characterAccount : accountId);
            for (size_t i = 1; i < fields.size(); ++i)
            {
                if (fields[i] == "\\N")
                {
                    values += ",NULL";
                    continue;
                }
                std::string value = Unescape(fields[i]);
                CharacterDatabase.escape_string(value);
                values += ",'" + value + "'";
            }
            statements.push_back("INSERT INTO `" + fields[0] + "` VALUES (" + values + ")");
        }
        CharacterDatabase.BeginTransaction();
        for (char const* table : ACCOUNT_TABLES)
            CharacterDatabase.PExecute("DELETE FROM `%s` WHERE `account` IN (%u, %u)", table, accountId, characterAccount);
        for (std::string const& statement : statements)
            CharacterDatabase.Execute(statement.c_str());
        return CharacterDatabase.CommitTransaction();
    }

    std::string ReadFile(std::string const& path)
    {
        std::ifstream in(path, std::ios::binary);
        std::ostringstream text;
        text << in.rdbuf();
        return text.str();
    }

    void WriteFile(std::string const& path, std::string const& text)
    {
        std::string const temporary = path + ".tmp";
        {
            std::ofstream out(temporary, std::ios::binary | std::ios::trunc);
            out << text;
        }
        std::remove(path.c_str());
        std::rename(temporary.c_str(), path.c_str());
    }

    uint32 AccountOfCharacter(uint32 guid)
    {
        std::unique_ptr<QueryResult> result(CharacterDatabase.PQuery("SELECT `account` FROM `characters` WHERE `guid` = %u", guid));
        return result ? result->Fetch()[0].GetUInt32() : 0;
    }

    uint32 GuidOfName(std::string name)
    {
        CharacterDatabase.escape_string(name);
        std::unique_ptr<QueryResult> result(CharacterDatabase.PQuery("SELECT `guid` FROM `characters` WHERE `name` = '%s'", name.c_str()));
        return result ? result->Fetch()[0].GetUInt32() : 0;
    }

    std::string FreeName(std::string const& wanted)
    {
        if (!GuidOfName(wanted))
            return wanted;
        std::string base = wanted.substr(0, MAX_NAME_LENGTH - 1);
        for (char suffix = 'a'; suffix <= 'z'; ++suffix)
        {
            std::string candidate = base + suffix;
            if (!GuidOfName(candidate))
                return candidate;
        }
        return "";
    }

    void DiscardHeldBank(uint32 guid)
    {
        std::string bagList;
        std::unique_ptr<QueryResult> result(CharacterDatabase.PQuery(
            "SELECT `item_guid` FROM `character_inventory` WHERE `guid` = %u AND `bag` = 0 AND `slot` >= %u AND `slot` < %u",
            guid, uint32(BANK_SLOT_BAG_START), uint32(BANK_SLOT_BAG_END)));
        if (result)
        {
            do
                bagList += (bagList.empty() ? "" : ",") + std::to_string(result->Fetch()[0].GetUInt32());
            while (result->NextRow());
        }
        std::string itemList;
        result = CharacterDatabase.PQuery(
            "SELECT `item_guid` FROM `character_inventory` WHERE `guid` = %u AND ((`bag` = 0 AND `slot` >= %u AND `slot` < %u)%s%s%s)",
            guid, uint32(BANK_SLOT_ITEM_START), uint32(BANK_SLOT_BAG_END),
            bagList.empty() ? "" : " OR `bag` IN (", bagList.c_str(), bagList.empty() ? "" : ")");
        if (result)
        {
            do
                itemList += (itemList.empty() ? "" : ",") + std::to_string(result->Fetch()[0].GetUInt32());
            while (result->NextRow());
        }
        if (itemList.empty())
            return;
        CharacterDatabase.DirectPExecute("DELETE FROM `item_instance` WHERE `guid` IN (%s)", itemList.c_str());
        CharacterDatabase.DirectPExecute("DELETE FROM `character_inventory` WHERE `item_guid` IN (%s)", itemList.c_str());
    }

    std::vector<std::string> DumpValues(std::string const& line)
    {
        std::vector<std::string> values;
        size_t start = line.find("VALUES (");
        if (start == std::string::npos)
            return values;
        start += 8;
        while (start < line.size() && line[start] == '\'')
        {
            size_t const end = line.find('\'', start + 1);
            if (end == std::string::npos)
                break;
            values.push_back(line.substr(start + 1, end - start - 1));
            start = end + 3;
        }
        return values;
    }

    bool IsDumpOf(std::string const& line, char const* table)
    {
        return line.compare(0, 13 + strlen(table) + 1, std::string("INSERT INTO `") + table + "`") == 0;
    }

    std::string StripHomeOnly(std::string const& dump)
    {
        std::set<std::string> bankBags;
        std::set<std::string> bankItems;
        std::istringstream first(dump);
        std::string line;
        while (std::getline(first, line))
        {
            if (!IsDumpOf(line, "character_inventory"))
                continue;
            std::vector<std::string> const values = DumpValues(line);
            if (values.size() < 4 || values[1] != "0")
                continue;
            uint32 const slot = uint32(std::strtoul(values[2].c_str(), nullptr, 10));
            if (slot >= BANK_SLOT_ITEM_START && slot < BANK_SLOT_BAG_END)
                bankItems.insert(values[3]);
            if (slot >= BANK_SLOT_BAG_START && slot < BANK_SLOT_BAG_END)
                bankBags.insert(values[3]);
        }
        std::istringstream second(dump);
        while (std::getline(second, line))
        {
            if (!IsDumpOf(line, "character_inventory"))
                continue;
            std::vector<std::string> const values = DumpValues(line);
            if (values.size() >= 4 && bankBags.count(values[1]))
                bankItems.insert(values[3]);
        }
        std::ostringstream kept;
        std::istringstream third(dump);
        while (std::getline(third, line))
        {
            std::vector<std::string> const values = DumpValues(line);
            bool drop = IsDumpOf(line, "bonk_ironman");
            if (IsDumpOf(line, "character_inventory"))
                drop = values.size() >= 4 && bankItems.count(values[3]);
            else if (IsDumpOf(line, "item_instance") || IsDumpOf(line, "bonk_item_found"))
                drop = !values.empty() && bankItems.count(values[0]);
            if (!drop)
                kept << line << '\n';
        }
        return kept.str();
    }

    std::vector<std::string> DumpFields(std::string const& line)
    {
        std::vector<std::string> fields;
        size_t at = line.find("VALUES (");
        if (at == std::string::npos)
            return fields;
        at += 8;
        while (at < line.size())
        {
            while (at < line.size() && (line[at] == ' ' || line[at] == ','))
                ++at;
            if (at >= line.size() || line[at] == ')')
                break;
            if (line.compare(at, 4, "NULL") == 0)
            {
                fields.push_back("");
                at += 4;
                continue;
            }
            if (line[at] != '\'')
                break;
            std::string value;
            for (++at; at < line.size() && line[at] != '\''; ++at)
            {
                if (line[at] == '\\' && at + 1 < line.size())
                    ++at;
                value += line[at];
            }
            fields.push_back(value);
            ++at;
        }
        return fields;
    }

    struct HomeMailItem
    {
        uint32 guid = 0;
        uint32 entry = 0;
    };

    struct HomeMail
    {
        uint32 id = 0;
        std::string expires;
        std::string delivers;
        std::string money;
        std::vector<HomeMailItem> items;
    };

    size_t const MAIL_ID = 0;
    size_t const MAIL_EXPIRE = 9;
    size_t const MAIL_DELIVER = 10;
    size_t const MAIL_MONEY = 11;
    size_t const MAIL_ITEM_MAIL = 0;
    size_t const MAIL_ITEM_GUID = 1;
    size_t const MAIL_ITEM_ENTRY = 2;

    std::vector<HomeMail> ReadHomeMail(std::string const& dump)
    {
        std::vector<HomeMail> mails;
        std::istringstream in(dump);
        std::string line;
        while (std::getline(in, line))
        {
            if (IsDumpOf(line, "mail"))
            {
                std::vector<std::string> const fields = DumpFields(line);
                if (fields.size() <= MAIL_MONEY)
                    continue;
                HomeMail mail;
                mail.id = uint32(std::strtoul(fields[MAIL_ID].c_str(), nullptr, 10));
                mail.expires = fields[MAIL_EXPIRE];
                mail.delivers = fields[MAIL_DELIVER];
                mail.money = fields[MAIL_MONEY];
                mails.push_back(mail);
            }
            else if (IsDumpOf(line, "mail_items"))
            {
                std::vector<std::string> const fields = DumpFields(line);
                if (fields.size() <= MAIL_ITEM_ENTRY)
                    continue;
                uint32 const mailId = uint32(std::strtoul(fields[MAIL_ITEM_MAIL].c_str(), nullptr, 10));
                for (HomeMail& mail : mails)
                    if (mail.id == mailId)
                        mail.items.push_back(HomeMailItem{ uint32(std::strtoul(fields[MAIL_ITEM_GUID].c_str(), nullptr, 10)),
                            uint32(std::strtoul(fields[MAIL_ITEM_ENTRY].c_str(), nullptr, 10)) });
            }
        }
        return mails;
    }

    std::mutex s_pendingMailLock;
    std::map<std::string, std::vector<HomeMail>> s_pendingMail;

    void RememberHomeMail(std::vector<HomeMail> const& homeMails, uint32 hostCharacter)
    {
        std::unique_ptr<QueryResult> result(CharacterDatabase.PQuery(
            "SELECT `id`, `expire_time`, `deliver_time`, `money` FROM `mail` WHERE `receiver_guid` = %u ORDER BY `id`", hostCharacter));
        if (!result)
            return;
        size_t index = 0;
        uint32 linked = 0;
        do
        {
            Field* fields = result->Fetch();
            if (index >= homeMails.size())
                break;
            HomeMail const& home = homeMails[index++];
            if (fields[1].GetCppString() != home.expires || fields[2].GetCppString() != home.delivers || fields[3].GetCppString() != home.money)
                continue;
            uint32 const hostMail = fields[0].GetUInt32();
            BonkCoop::RememberHomeMail(hostMail, home.id);
            ++linked;
            std::vector<HomeMailItem> unmatched = home.items;
            std::unique_ptr<QueryResult> items(CharacterDatabase.PQuery(
                "SELECT `item_guid`, `item_id` FROM `mail_items` WHERE `mail_id` = %u ORDER BY `item_guid`", hostMail));
            if (!items)
                continue;
            do
            {
                uint32 const hostItem = items->Fetch()[0].GetUInt32();
                uint32 const entry = items->Fetch()[1].GetUInt32();
                for (auto itr = unmatched.begin(); itr != unmatched.end(); ++itr)
                {
                    if (itr->entry != entry)
                        continue;
                    BonkCoop::RememberHomeMailItem(hostItem, home.id, itr->guid);
                    unmatched.erase(itr);
                    break;
                }
            }
            while (items->NextRow());
        }
        while (result->NextRow());
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op transfer: %u of %u home mails linked for character %u", linked, uint32(homeMails.size()), hostCharacter);
    }

    bool CharacterRowExists(uint32 guid)
    {
        std::unique_ptr<QueryResult> result(CharacterDatabase.PQuery("SELECT 1 FROM `characters` WHERE `guid` = %u", guid));
        return result != nullptr;
    }

    uint32 ProgressAccountOf(uint32 guid, uint32 accountId)
    {
        return BonkPlayer::GetProgressAccountOf(guid, accountId);
    }

    LocaleConstant AccountLocale(uint32 accountId)
    {
        if (accountId)
            if (std::unique_ptr<QueryResult> result{ CharacterDatabase.PQuery("SELECT `locale` FROM `bonk_account` WHERE `account` = %u", accountId) })
            {
                uint8 const locale = result->Fetch()[0].GetUInt8();
                if (locale < MAX_LOCALE)
                    return LocaleConstant(locale);
            }
        return LOCALE_enUS;
    }

    std::string Error(uint32 accountId, BonkString id, std::vector<std::string> const& args = {})
    {
        return "error " + sBonkLocale.GetString(id, AccountLocale(accountId), args);
    }

    std::string WriteExport(uint32 low)
    {
        uint32 const accountId = AccountOfCharacter(low);
        PlayerDumpWriter writer;
        WriteFile(DUMP_FILE, writer.GetDump(low));
        WriteFile(ACCOUNT_FILE, ExportAccountRows(ProgressAccountOf(low, accountId), BonkPlayer::GetCharacterAccountOf(low)));
        return "ok " + std::to_string(low) + " " + std::to_string(accountId);
    }

    std::string Export(std::string const& name)
    {
        uint32 const low = GuidOfName(name);
        if (!low)
            return Error(0, BONK_STRING_COOP_TRANSFER_NO_CHARACTER, { name });
        if (Player* online = sObjectMgr.GetPlayer(ObjectGuid(HIGHGUID_PLAYER, low)))
        {
            online->SaveToDB();
            s_pending = Pending();
            s_pending.active = true;
            s_pending.guid = low;
            return "";
        }
        return WriteExport(low);
    }

    std::string Load(uint32 accountId, std::string const& name, uint32 guid)
    {
        std::string const dump = StripHomeOnly(ReadFile(DUMP_FILE));
        WriteFile(DUMP_FILE, dump);
        PlayerDumpReader reader;
        DumpReturn const loaded = reader.LoadDump(DUMP_FILE, accountId, name, guid);
        if (loaded != DUMP_SUCCESS)
            return Error(accountId, BONK_STRING_COOP_TRANSFER_LOAD_FAILED, { std::to_string(uint32(loaded)) });
        {
            std::lock_guard<std::mutex> guard(s_pendingMailLock);
            s_pendingMail[name] = ReadHomeMail(dump);
        }
        if (!ImportAccountRows(ReadFile(ACCOUNT_FILE), accountId, BonkPlayer::GetStagedCharacterAccount(accountId)))
            return Error(accountId, BONK_STRING_COOP_TRANSFER_PROGRESS_FAILED);
        return "ok 0 " + name;
    }

    std::string Import(std::string const& username, std::string const& name, uint32 replaceGuid)
    {
        uint32 const accountId = sAccountMgr.GetId(username);
        if (!accountId)
            return Error(0, BONK_STRING_COOP_TRANSFER_NO_ACCOUNT, { username });
        if (!replaceGuid)
        {
            std::string const useName = FreeName(name);
            if (useName.empty())
                return Error(accountId, BONK_STRING_COOP_TRANSFER_NO_FREE_NAME, { name });
            return Load(accountId, useName, 0);
        }
        ObjectGuid const old = ObjectGuid(HIGHGUID_PLAYER, replaceGuid);
        if (sObjectMgr.GetPlayer(old))
            return Error(accountId, BONK_STRING_COOP_TRANSFER_CHARACTER_ONLINE);
        if (CharacterRowExists(replaceGuid))
        {
            if (AccountOfCharacter(replaceGuid) != accountId)
                return Error(accountId, BONK_STRING_COOP_TRANSFER_OTHER_ACCOUNT);
            DiscardHeldBank(replaceGuid);
            Player::DeleteFromDB(old, accountId, true, true);
        }
        s_pending = Pending();
        s_pending.active = true;
        s_pending.import = true;
        s_pending.accountId = accountId;
        s_pending.name = name;
        s_pending.guid = replaceGuid;
        return "";
    }

    std::string ContinuePending(uint32 diff)
    {
        s_pending.waitedMs += diff;
        if (!s_pending.import)
        {
            if (s_pending.waitedMs < SAVE_SETTLE_MS)
                return "";
            s_pending.active = false;
            return WriteExport(s_pending.guid);
        }
        if (CharacterRowExists(s_pending.guid) || GuidOfName(s_pending.name))
        {
            if (s_pending.waitedMs < DELETE_WAIT_MS)
                return "";
            s_pending.active = false;
            return Error(s_pending.accountId, BONK_STRING_COOP_TRANSFER_OLD_COPY);
        }
        s_pending.active = false;
        return Load(s_pending.accountId, s_pending.name, 0);
    }

    std::string Handle(std::string const& request)
    {
        std::istringstream in(request);
        std::string verb;
        in >> verb;
        if (verb == "export")
        {
            std::string name;
            in >> name;
            return Export(name);
        }
        if (verb == "import")
        {
            std::string username, name;
            uint32 replaceGuid = 0;
            in >> username >> name >> replaceGuid;
            return Import(username, name, replaceGuid);
        }
        return Error(0, BONK_STRING_COOP_TRANSFER_UNKNOWN_REQUEST);
    }
}

void BonkCoop::Update(uint32 diff)
{
    UpdateReadyChecks(diff);
    UpdateLeash(diff);
    UpdateDowned(diff);
    UpdateSharedPause(diff);
    s_scanTimer += diff;
    if (s_scanTimer < SCAN_INTERVAL_MS)
        return;
    uint32 const elapsed = s_scanTimer;
    s_scanTimer = 0;
    UpdateLedger();

    if (s_pending.active)
    {
        std::string const answer = ContinuePending(elapsed);
        if (!answer.empty())
        {
            sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op transfer: %s", answer.c_str());
            WriteFile(ANSWER_FILE, answer);
        }
        return;
    }

    std::ifstream probe(REQUEST_FILE, std::ios::binary);
    if (!probe.good())
        return;
    probe.close();
    std::string const request = ReadFile(REQUEST_FILE);
    std::remove(REQUEST_FILE);
    std::string const answer = Handle(request);
    if (answer.empty())
        return;
    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op transfer: %s", answer.c_str());
    WriteFile(ANSWER_FILE, answer);
}

void BonkCoop::LinkHomeMail(Player const* guest)
{
    std::vector<HomeMail> mails;
    {
        std::lock_guard<std::mutex> guard(s_pendingMailLock);
        auto found = s_pendingMail.find(guest->GetName());
        if (found == s_pendingMail.end())
            return;
        mails.swap(found->second);
        s_pendingMail.erase(found);
    }
    RememberHomeMail(mails, guest->GetGUIDLow());
}

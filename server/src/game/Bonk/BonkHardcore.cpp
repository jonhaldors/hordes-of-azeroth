#include "BonkHardcore.h"
#include "BonkPlayer.h"
#include "BonkRun.h"
#include "Config/Config.h"
#include "Database/DatabaseEnv.h"
#include "HoaProtocol.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "WorldSession.h"

#include <sys/stat.h>

#include <atomic>
#include <cstdio>
#include <ctime>
#include <mutex>
#include <set>
#include <sstream>

namespace
{
    uint32 const BONK_HARDCORE_ACCOUNT_BIT = 0x40000000;
    uint32 const FALLEN_LIST_SIZE = 50;
    uint32 const HARDCORE_HOLD_MS = 15 * IN_MILLISECONDS;
    uint32 const HARDCORE_SHUTDOWN_HOLD_SECONDS = 15;

    std::atomic<uint32> s_openHardcoreRuns{ 0 };

    std::string CrashNotePath()
    {
        std::string folder = sConfig.GetStringDefault("LogsDir", "");
        if (!folder.empty() && folder.back() != '/' && folder.back() != '\\')
            folder += '/';
        return folder + "Crash.log";
    }

    bool CrashedSince(uint32 startedAt)
    {
        struct stat info;
        return stat(CrashNotePath().c_str(), &info) == 0 && info.st_mtime >= time_t(startedAt);
    }

    std::mutex s_hardcoreRequestsLock;
    std::set<uint32> s_hardcoreRequests;
    std::set<uint32> s_restRequests;

    std::string GlueString(std::string text)
    {
        for (char& c : text)
            if (c == '\\' || c == '"' || c == '\n' || c == '\r')
                c = ' ';
        return "\"" + text + "\"";
    }

    std::string AddonField(std::string text)
    {
        for (char& c : text)
            if (c == '~' || c == '\n' || c == '\r')
                c = ' ';
        return text;
    }

    std::string EscapedForDatabase(std::string text, size_t maxLength)
    {
        if (text.size() > maxLength)
            text.resize(maxLength);
        CharacterDatabase.escape_string(text);
        return text;
    }

    std::string BankRowsOf(uint32 guidLow)
    {
        char text[512];
        snprintf(text, sizeof(text), "i.`guid` = %u AND ((i.`bag` = 0 AND i.`slot` >= %u AND i.`slot` < %u) OR i.`bag` IN "
            "(SELECT b.`item_guid` FROM `character_inventory` b WHERE b.`guid` = %u AND b.`bag` = 0 AND b.`slot` >= %u AND b.`slot` < %u))",
            guidLow, uint32(BANK_SLOT_ITEM_START), uint32(BANK_SLOT_BAG_END), guidLow, uint32(BANK_SLOT_BAG_START), uint32(BANK_SLOT_BAG_END));
        return text;
    }
}

std::vector<std::string> BonkParkBankStatements(uint32 guidLow, uint32 poolAccount, bool takeFromCharacter)
{
    std::vector<std::string> statements;
    std::ostringstream park;
    park << "INSERT IGNORE INTO `bonk_account_bank` (`account`, `bag`, `slot`, `item_guid`, `item_id`) "
        << "SELECT " << poolAccount << ", i.`bag`, i.`slot`, i.`item_guid`, i.`item_id` FROM `character_inventory` i WHERE " << BankRowsOf(guidLow);
    statements.push_back(park.str());

    std::ostringstream owner;
    owner << "UPDATE `item_instance` i JOIN `bonk_account_bank` b ON b.`item_guid` = i.`guid` SET i.`owner_guid` = 0 "
        << "WHERE i.`owner_guid` = " << guidLow << " AND b.`account` = " << poolAccount;
    statements.push_back(owner.str());

    if (takeFromCharacter)
    {
        std::ostringstream take;
        take << "DELETE i FROM `character_inventory` i JOIN `bonk_account_bank` b ON b.`item_guid` = i.`item_guid` "
            << "WHERE i.`guid` = " << guidLow << " AND b.`account` = " << poolAccount;
        statements.push_back(take.str());
    }
    return statements;
}

std::vector<BonkFallenRecord> LoadBonkFallenRecords(uint32 accountId)
{
    std::vector<BonkFallenRecord> records;
    std::unique_ptr<QueryResult> result(CharacterDatabase.PQuery("SELECT `guid`, `name`, `class`, `level`, `best_level`, `mastery`, `played`, `runs`, `kills`, "
        "`killer`, `map`, `died_at`, `ironman`, `crashes`, `rested` FROM `bonk_hardcore_fallen` WHERE `account` = %u ORDER BY `died_at` DESC, `id` DESC LIMIT %u",
        accountId, FALLEN_LIST_SIZE));
    if (!result)
        return records;
    do
    {
        Field* fields = result->Fetch();
        BonkFallenRecord record;
        record.guid = fields[0].GetUInt32();
        record.name = fields[1].GetCppString();
        record.classId = fields[2].GetUInt8();
        record.level = fields[3].GetUInt32();
        record.bestLevel = fields[4].GetUInt32();
        record.mastery = fields[5].GetUInt32();
        record.played = fields[6].GetUInt32();
        record.runs = fields[7].GetUInt32();
        record.kills = fields[8].GetUInt32();
        record.killer = fields[9].GetCppString();
        record.map = fields[10].GetCppString();
        record.diedAt = fields[11].GetUInt32();
        record.ironman = fields[12].GetUInt8() != 0;
        record.crashes = fields[13].GetUInt32();
        record.rested = fields[14].GetUInt8() != 0;
        records.push_back(record);
    } while (result->NextRow());
    return records;
}

std::string DescribeBonkFallenForGlue(BonkFallenRecord const& record)
{
    std::ostringstream lua;
    lua << "{ name = " << GlueString(record.name)
        << ", class = " << uint32(record.classId)
        << ", level = " << record.level
        << ", bestLevel = " << record.bestLevel
        << ", mastery = " << record.mastery
        << ", played = " << record.played
        << ", runs = " << record.runs
        << ", kills = " << record.kills
        << ", killer = " << GlueString(record.killer)
        << ", map = " << GlueString(record.map)
        << ", diedAt = " << record.diedAt
        << ", crashes = " << record.crashes;
    if (record.ironman)
        lua << ", ironman = true";
    if (record.rested)
        lua << ", rested = true";
    lua << " }";
    return lua.str();
}

bool BonkPlayer::IsHardcoreName(std::string const& name)
{
    return name == "Hardcoremode";
}

void BonkPlayer::RequestHardcore(uint32 accountId)
{
    std::lock_guard<std::mutex> guard(s_hardcoreRequestsLock);
    s_hardcoreRequests.insert(accountId);
}

bool BonkPlayer::TakeHardcoreRequest(uint32 accountId)
{
    std::lock_guard<std::mutex> guard(s_hardcoreRequestsLock);
    return s_hardcoreRequests.erase(accountId) > 0;
}

void BonkPlayer::MarkHardcore(uint32 guidLow)
{
    CharacterDatabase.DirectPExecute("INSERT IGNORE INTO `bonk_hardcore` (`guid`) VALUES (%u)", guidLow);
}

bool BonkPlayer::IsHardcoreCharacter(uint32 guidLow)
{
    std::unique_ptr<QueryResult> result(CharacterDatabase.PQuery("SELECT 1 FROM `bonk_hardcore` WHERE `guid` = %u", guidLow));
    return result != nullptr;
}

uint32 BonkPlayer::GetHardcoreAccount(uint32 accountId)
{
    return BONK_HARDCORE_ACCOUNT_BIT | accountId;
}

uint32 BonkPlayer::GetProgressAccountOf(uint32 guidLow, uint32 accountId)
{
    if (CharacterDatabase.PQuery("SELECT 1 FROM `bonk_ironman` WHERE `guid` = %u", guidLow))
        return GetIronmanAccount(guidLow);
    return IsHardcoreCharacter(guidLow) ? GetHardcoreAccount(accountId) : accountId;
}

void BonkPlayer::ParkFallenBanks(uint32 accountId)
{
    std::vector<std::pair<uint32, uint32>> unparked;
    std::unique_ptr<QueryResult> result(CharacterDatabase.PQuery("SELECT f.`id`, f.`guid` FROM `bonk_hardcore_fallen` f JOIN `characters` c ON c.`guid` = f.`guid` "
        "WHERE f.`account` = %u AND f.`bank_parked` = 0", accountId));
    if (!result)
        return;
    do
    {
        Field* fields = result->Fetch();
        unparked.emplace_back(fields[0].GetUInt32(), fields[1].GetUInt32());
    } while (result->NextRow());

    for (auto const& fall : unparked)
    {
        if (sObjectAccessor.FindPlayer(ObjectGuid(HIGHGUID_PLAYER, fall.second)))
            continue;
        for (std::string const& statement : BonkParkBankStatements(fall.second, GetHardcoreAccount(accountId), true))
            CharacterDatabase.DirectExecute(statement.c_str());
        CharacterDatabase.DirectPExecute("UPDATE `bonk_hardcore_fallen` SET `bank_parked` = 1 WHERE `id` = %u", fall.first);
    }
}

bool BonkPlayer::IsHardcore() const
{
    if (m_hardcore < 0)
        m_hardcore = IsHardcoreCharacter(m_player->GetGUIDLow()) ? 1 : 0;
    return m_hardcore > 0;
}

bool BonkPlayer::UsesHardcorePool() const
{
    return !IsIronman() && (IsHardcore() || m_fellInHardcore);
}

void BonkPlayer::OnHardcoreDeath(std::string const& killer, std::string const& mapName, uint32 level, uint32 kills)
{
    if (!IsHardcore())
        return;

    uint32 const guidLow = m_player->GetGUIDLow();
    uint32 const accountId = m_player->GetSession()->GetAccountId();
    uint32 const bestLevel = GetBestLevel();
    uint32 const mastery = GetMasteryLevel();
    uint32 const runs = m_record.runs + 1;
    uint32 const totalKills = m_record.kills + kills;
    uint32 const played = m_player->GetTotalPlayedTime();
    bool const ironman = IsIronman();
    bool const shown = IsAddonReady() && m_player->GetSession()->IsConnected();

    uint32 crashes = m_hardcoreCrashes;
    std::unique_ptr<QueryResult> counts(CharacterDatabase.PQuery("SELECT `crashes` FROM `bonk_hardcore` WHERE `guid` = %u", guidLow));
    if (counts)
        crashes = counts->Fetch()[0].GetUInt32();

    if (m_hardcoreRun)
        sLog.Player(m_player->GetSession(), LOG_LEVELUP, LOG_LVL_BASIC, "Bonk hardcore: %s falls in hardcore run %u (level %u, killed by %s on %s)",
            m_player->GetName(), m_hardcoreRun, level, killer.c_str(), mapName.c_str());

    CharacterDatabase.BeginTransaction();
    CharacterDatabase.PExecute("INSERT INTO `bonk_hardcore_fallen` (`account`, `guid`, `name`, `class`, `level`, `best_level`, `mastery`, `played`, `runs`, `kills`, "
        "`killer`, `map`, `died_at`, `ironman`, `crashes`, `bank_parked`, `announced`) VALUES (%u, %u, '%s', %u, %u, %u, %u, %u, %u, %u, '%s', '%s', %u, %u, %u, %u, %u)",
        accountId, guidLow, EscapedForDatabase(m_player->GetName(), 32).c_str(), uint32(m_player->GetClass()), level, bestLevel, mastery,
        played, runs, totalKills, EscapedForDatabase(killer, 128).c_str(), EscapedForDatabase(mapName, 128).c_str(),
        uint32(time(nullptr)), ironman ? 1u : 0u, crashes, ironman ? 1u : 0u, shown ? 1u : 0u);
    CharacterDatabase.PExecute("DELETE FROM `bonk_hardcore` WHERE `guid` = %u", guidLow);
    CharacterDatabase.PExecute("DELETE FROM `bonk_hardcore_run_open` WHERE `guid` = %u", guidLow);
    CharacterDatabase.CommitTransaction();

    if (m_hardcoreRun)
    {
        m_hardcoreRun = 0;
        --s_openHardcoreRuns;
    }
    m_hardcore = 0;
    m_fellInHardcore = true;
    if (!ironman)
        RaisePoolBestLevel(accountId, bestLevel);
    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Bonk: %s fell in Hardcore (level %u, best level %u, killed by %s on %s)",
        m_player->GetName(), level, bestLevel, killer.c_str(), mapName.c_str());
    if (shown)
        SendFallenRecord(level, bestLevel, mastery, played, runs, totalKills, killer, mapName, ironman);
}

uint32 BonkPlayer::BeginHardcoreRun(std::string const& mapName)
{
    if (m_hardcoreRun || !IsHardcore())
        return m_hardcoreRun;

    uint32 const guidLow = m_player->GetGUIDLow();
    uint32 run = 1;
    std::unique_ptr<QueryResult> result(CharacterDatabase.PQuery("SELECT `runs`, `crashes` FROM `bonk_hardcore` WHERE `guid` = %u", guidLow));
    if (result)
    {
        Field* fields = result->Fetch();
        run = fields[0].GetUInt32() + 1;
        m_hardcoreCrashes = fields[1].GetUInt32();
    }
    CharacterDatabase.DirectPExecute("UPDATE `bonk_hardcore` SET `runs` = %u WHERE `guid` = %u", run, guidLow);
    CharacterDatabase.DirectPExecute("REPLACE INTO `bonk_hardcore_run_open` (`guid`, `run`, `map`, `started_at`, `settled`) VALUES (%u, %u, '%s', %u, 0)",
        guidLow, run, EscapedForDatabase(mapName, 128).c_str(), uint32(time(nullptr)));
    m_hardcoreRun = run;
    ++s_openHardcoreRuns;
    return run;
}

void BonkPlayer::EndHardcoreRun()
{
    if (!m_hardcoreRun)
        return;
    CharacterDatabase.DirectPExecute("DELETE FROM `bonk_hardcore_run_open` WHERE `guid` = %u", m_player->GetGUIDLow());
    m_hardcoreRun = 0;
    --s_openHardcoreRuns;
}

bool BonkPlayer::HoldsAfterDisconnect() const
{
    return m_hardcoreRun && m_run && !m_run->IsOver();
}

void BonkPlayer::OnHardcoreDisconnected()
{
    if (HoldsAfterDisconnect())
        m_run->SetConnectionLost(true);
}

void BonkPlayer::OnHardcoreReconnected()
{
    if (m_run)
        m_run->SetConnectionLost(false);
}

uint32 BonkPlayer::HardcoreHoldMs()
{
    return HARDCORE_HOLD_MS;
}

uint32 BonkPlayer::HardcoreShutdownHoldSeconds()
{
    return HARDCORE_SHUTDOWN_HOLD_SECONDS;
}

uint32 BonkPlayer::OpenHardcoreRuns()
{
    return s_openHardcoreRuns.load();
}

void BonkPlayer::SettleLeftHardcoreRun()
{
    if (!IsHardcore())
        return;
    std::unique_ptr<QueryResult> result(CharacterDatabase.PQuery("SELECT `map` FROM `bonk_hardcore_run_open` WHERE `guid` = %u AND `settled` = 1",
        m_player->GetGUIDLow()));
    if (!result)
        return;
    OnHardcoreDeath("", result->Fetch()[0].GetCppString(), m_player->GetLevel(), 0);
}

void BonkPlayer::SendUnannouncedFall()
{
    std::unique_ptr<QueryResult> result(CharacterDatabase.PQuery("SELECT `id`, `level`, `best_level`, `mastery`, `played`, `runs`, `kills`, `killer`, `map`, `ironman` "
        "FROM `bonk_hardcore_fallen` WHERE `guid` = %u AND `announced` = 0 AND `rested` = 0 ORDER BY `id` DESC LIMIT 1", m_player->GetGUIDLow()));
    if (!result)
        return;
    Field* fields = result->Fetch();
    CharacterDatabase.PExecute("UPDATE `bonk_hardcore_fallen` SET `announced` = 1 WHERE `id` = %u", fields[0].GetUInt32());
    m_mayRest = true;
    SendFallenRecord(fields[1].GetUInt32(), fields[2].GetUInt32(), fields[3].GetUInt32(), fields[4].GetUInt32(), fields[5].GetUInt32(),
        fields[6].GetUInt32(), fields[7].GetCppString(), fields[8].GetCppString(), fields[9].GetUInt8() != 0);
}

bool BonkPlayer::RequestRest()
{
    if (!m_fellInHardcore && !m_mayRest)
        return false;
    uint32 const guidLow = m_player->GetGUIDLow();
    CharacterDatabase.DirectPExecute("UPDATE `bonk_hardcore_fallen` SET `rested` = 1 WHERE `guid` = %u ORDER BY `id` DESC LIMIT 1", guidLow);
    {
        std::lock_guard<std::mutex> guard(s_hardcoreRequestsLock);
        s_restRequests.insert(guidLow);
    }
    WorldPacket rested(SMSG_HOA_MESSAGE);
    HoAWriteHardcoreRested(rested);
    m_player->GetSession()->SendPacket(&rested);
    return true;
}

bool BonkPlayer::TakeRestRequest(uint32 guidLow)
{
    std::lock_guard<std::mutex> guard(s_hardcoreRequestsLock);
    return s_restRequests.erase(guidLow) > 0;
}

void BonkPlayer::SendFallenRecord(uint32 level, uint32 bestLevel, uint32 mastery, uint32 played, uint32 runs, uint32 kills, std::string const& killer,
    std::string const& mapName, bool ironman)
{
    if (!IsAddonReady())
        return;
    WorldPacket data(SMSG_HOA_MESSAGE);
    HoAWriteHardcoreFell(data, m_player->GetName(), uint8(m_player->GetClass()), level, bestLevel, mastery, played, runs, kills, killer, mapName, ironman);
    m_player->GetSession()->SendPacket(&data);
}

void SettleBonkHardcoreRuns()
{
    std::unique_ptr<QueryResult> result(CharacterDatabase.Query("SELECT o.`guid`, o.`run`, o.`started_at`, c.`account`, c.`name` FROM `bonk_hardcore_run_open` o "
        "LEFT JOIN `characters` c ON c.`guid` = o.`guid` WHERE o.`settled` = 0"));
    if (!result)
        return;
    do
    {
        Field* fields = result->Fetch();
        uint32 const guidLow = fields[0].GetUInt32();
        uint32 const run = fields[1].GetUInt32();
        uint32 const startedAt = fields[2].GetUInt32();
        uint32 const accountId = fields[3].GetUInt32();
        std::string const name = fields[4].GetCppString();
        if (name.empty())
        {
            CharacterDatabase.DirectPExecute("DELETE FROM `bonk_hardcore_run_open` WHERE `guid` = %u", guidLow);
            continue;
        }
        bool const crashed = CrashedSince(startedAt);
        if (crashed)
        {
            CharacterDatabase.DirectPExecute("UPDATE `bonk_hardcore` SET `crashes` = `crashes` + 1 WHERE `guid` = %u", guidLow);
            CharacterDatabase.DirectPExecute("DELETE FROM `bonk_hardcore_run_open` WHERE `guid` = %u", guidLow);
        }
        else
            CharacterDatabase.DirectPExecute("UPDATE `bonk_hardcore_run_open` SET `settled` = 1 WHERE `guid` = %u", guidLow);
        sLog.Player(accountId, LOG_LEVELUP, LOG_LVL_BASIC, "Bonk hardcore: guid %u, name %s, %s left hardcore run %u: %s",
            guidLow, name.c_str(), name.c_str(), run, crashed ? "crash" : "fell");
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Bonk: %s left hardcore run %u mid-run (%s)", name.c_str(), run,
            crashed ? "server crash, forgiven" : "no crash note, counts as a death");
    } while (result->NextRow());
}

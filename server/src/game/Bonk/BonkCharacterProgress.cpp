#include "BonkCharacterProgress.h"
#include "BonkMastery.h"
#include "BonkPlayer.h"
#include "Database/DatabaseEnv.h"
#include "Log.h"

#include <map>
#include <set>
#include <sstream>
#include <vector>

namespace
{
    uint32 const BONK_CHARACTER_ACCOUNT_BIT = 0x20000000;
    uint32 const BONK_POOL_ACCOUNT_LIMIT = 0x20000000;
    uint32 const BONK_HARDCORE_POOL_BIT = 0x40000000;
    uint32 const BONK_STAGED_CHARACTER_BIT = 0x10000000;
    char const* const CHARACTER_ONLY_TABLES[] = { "bonk_account_mastery_node" };

    char const* const CLASS_COLUMN_TABLES[] = { "bonk_account_mastery", "bonk_account_mastery_preset", "bonk_account_mastery_preset_active",
        "bonk_account_starter", "bonk_account_level", "bonk_account_level_best", "bonk_account_kept_talents" };

    struct ClassOwner
    {
        uint32 pool = 0;
        uint8 classId = 0;
        bool operator<(ClassOwner const& other) const { return pool != other.pool ? pool < other.pool : classId < other.classId; }
    };

    bool IsPoolAccount(uint32 account)
    {
        return (account < BONK_POOL_ACCOUNT_LIMIT && !(account & BONK_STAGED_CHARACTER_BIT)) || (account & 0xE0000000) == BONK_HARDCORE_POOL_BIT;
    }

    std::string JoinIds(std::vector<uint32> const& ids)
    {
        std::ostringstream list;
        for (size_t i = 0; i < ids.size(); ++i)
            list << (i ? "," : "") << ids[i];
        return list.str();
    }

    uint8 NodeClass(uint32 nodeId)
    {
        BonkMasteryNode const* node = sBonkMastery.GetNode(nodeId);
        return node ? node->classId : 0;
    }

    void MoveClassRows(uint32 pool, uint8 classId, uint32 characterAccount)
    {
        for (char const* table : CLASS_COLUMN_TABLES)
            CharacterDatabase.DirectPExecute("UPDATE IGNORE `%s` SET `account` = %u WHERE `account` = %u AND `class` = %u", table, characterAccount, pool, uint32(classId));

        std::vector<uint32> nodes;
        std::unique_ptr<QueryResult> result(CharacterDatabase.PQuery("SELECT `node` FROM `bonk_account_mastery_node` WHERE `account` = %u", pool));
        if (result)
        {
            do
            {
                uint32 const node = result->Fetch()[0].GetUInt32();
                if (NodeClass(node) == classId)
                    nodes.push_back(node);
            } while (result->NextRow());
        }
        if (!nodes.empty())
            CharacterDatabase.DirectPExecute("UPDATE IGNORE `bonk_account_mastery_node` SET `account` = %u WHERE `account` = %u AND `node` IN (%s)",
                characterAccount, pool, JoinIds(nodes).c_str());
    }

    void SeedPoolBestLevels()
    {
        CharacterDatabase.DirectPExecute("INSERT INTO `bonk_account_level` (`account`, `class`, `best_level`, `best_ms`, `best_finale`) "
            "SELECT `account`, 0, MAX(`best_level`), 0, 0 FROM `bonk_account_level` WHERE `class` <> 0 AND (`account` < %u OR (`account` & 3758096384) = %u) "
            "GROUP BY `account` ON DUPLICATE KEY UPDATE `best_level` = GREATEST(`best_level`, VALUES(`best_level`))",
            BONK_POOL_ACCOUNT_LIMIT, BONK_HARDCORE_POOL_BIT);
    }
}

void BonkCharacterProgress::MoveClassProgressToCharacters()
{
    if (CharacterDatabase.PQuery("SELECT 1 FROM `bonk_character_progress_moved` LIMIT 1"))
        return;

    SeedPoolBestLevels();

    std::map<ClassOwner, uint32> owners;
    std::unique_ptr<QueryResult> result(CharacterDatabase.PQuery("SELECT c.`guid`, c.`account`, c.`class`, "
        "EXISTS (SELECT 1 FROM `bonk_hardcore` h WHERE h.`guid` = c.`guid`) FROM `characters` c "
        "WHERE c.`account` <> 0 AND NOT EXISTS (SELECT 1 FROM `bonk_ironman` i WHERE i.`guid` = c.`guid`) ORDER BY c.`guid`"));
    if (result)
    {
        do
        {
            Field* fields = result->Fetch();
            uint32 const guid = fields[0].GetUInt32();
            uint32 const account = fields[1].GetUInt32();
            ClassOwner owner{ fields[3].GetUInt32() ? BonkPlayer::GetHardcoreAccount(account) : account, fields[2].GetUInt8() };
            owners.emplace(owner, guid);
        } while (result->NextRow());
    }

    for (auto const& itr : owners)
        MoveClassRows(itr.first.pool, itr.first.classId, BonkPlayer::GetPlainCharacterAccount(itr.second));

    CharacterDatabase.DirectExecute("INSERT INTO `bonk_character_progress_moved` (`done`) VALUES (1)");
    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Moved class progress to %u characters", uint32(owners.size()));
}

uint32 BonkPlayer::GetPlainCharacterAccount(uint32 guidLow)
{
    return BONK_CHARACTER_ACCOUNT_BIT | guidLow;
}

uint32 BonkPlayer::GetStagedCharacterAccount(uint32 accountId)
{
    return BONK_STAGED_CHARACTER_BIT | accountId;
}

void BonkPlayer::ClaimStagedCharacterRows()
{
    uint32 const staged = GetStagedCharacterAccount(m_player->GetSession()->GetAccountId());
    if (!CharacterDatabase.PQuery("SELECT 1 FROM `bonk_account_mastery` WHERE `account` = %u UNION ALL SELECT 1 FROM `bonk_account_level` WHERE `account` = %u "
        "UNION ALL SELECT 1 FROM `bonk_account_mastery_node` WHERE `account` = %u LIMIT 1", staged, staged, staged))
        return;
    uint32 const characterAccount = GetCharacterAccount();
    for (char const* table : CLASS_COLUMN_TABLES)
    {
        CharacterDatabase.DirectPExecute("DELETE FROM `%s` WHERE `account` = %u", table, characterAccount);
        CharacterDatabase.DirectPExecute("UPDATE `%s` SET `account` = %u WHERE `account` = %u", table, characterAccount, staged);
    }
    for (char const* table : CHARACTER_ONLY_TABLES)
    {
        CharacterDatabase.DirectPExecute("DELETE FROM `%s` WHERE `account` = %u", table, characterAccount);
        CharacterDatabase.DirectPExecute("UPDATE `%s` SET `account` = %u WHERE `account` = %u", table, characterAccount, staged);
    }
}

uint32 BonkPlayer::GetCharacterAccountOf(uint32 guidLow)
{
    if (CharacterDatabase.PQuery("SELECT 1 FROM `bonk_ironman` WHERE `guid` = %u", guidLow))
        return GetIronmanAccount(guidLow);
    return GetPlainCharacterAccount(guidLow);
}

uint32 BonkPlayer::GetCharacterAccount() const
{
    return IsIronman() ? GetIronmanAccount(m_player->GetGUIDLow()) : GetPlainCharacterAccount(m_player->GetGUIDLow());
}

void BonkPlayer::AdoptClassProgress(uint32 guidLow)
{
    std::unique_ptr<QueryResult> result(CharacterDatabase.PQuery("SELECT `account`, `class` FROM `characters` WHERE `guid` = %u", guidLow));
    if (!result || CharacterDatabase.PQuery("SELECT 1 FROM `bonk_ironman` WHERE `guid` = %u", guidLow))
        return;
    uint32 const account = result->Fetch()[0].GetUInt32();
    uint8 const classId = result->Fetch()[1].GetUInt8();
    uint32 const pool = IsHardcoreCharacter(guidLow) ? GetHardcoreAccount(account) : account;
    if (IsPoolAccount(pool))
        MoveClassRows(pool, classId, GetPlainCharacterAccount(guidLow));
}

void BonkPlayer::DeleteCharacterProgress(uint32 guidLow)
{
    uint32 const characterAccount = GetPlainCharacterAccount(guidLow);
    for (char const* table : CLASS_COLUMN_TABLES)
        CharacterDatabase.PExecute("DELETE FROM `%s` WHERE `account` = %u", table, characterAccount);
    CharacterDatabase.PExecute("DELETE FROM `bonk_account_mastery_node` WHERE `account` = %u", characterAccount);
}

void BonkPlayer::RaisePoolBestLevel(uint32 poolAccount, uint32 level)
{
    if (!level)
        return;
    CharacterDatabase.PExecute("INSERT INTO `bonk_account_level` (`account`, `class`, `best_level`, `best_ms`, `best_finale`) VALUES (%u, 0, %u, 0, 0) "
        "ON DUPLICATE KEY UPDATE `best_level` = GREATEST(`best_level`, VALUES(`best_level`))", poolAccount, level);
}

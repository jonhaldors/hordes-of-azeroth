#include "BonkQuests.h"
#include "BonkLocale.h"
#include "BonkMastery.h"
#include "BonkPlayer.h"
#include "BonkTransmog.h"
#include "ObjectMgr.h"
#include "Creature.h"
#include "Database/DatabaseEnv.h"
#include "HoaProtocol.h"
#include "Log.h"
#include "Player.h"
#include "Policies/SingletonImp.h"
#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include "SpellMgr.h"
#include "WorldSession.h"

#include <ctime>
#include <bitset>
#include <vector>

INSTANTIATE_SINGLETON_1(BonkQuests);

namespace
{
    uint32 const BONK_TEXT_QUEST_BOARD = 900005;


    char const* const CATEGORY_KEYS[MAX_BONK_QUEST_CATEGORY] = { "slayer", "victory", "mastery", "challenge", "discovery", "collection" };

    struct ClassLook
    {
        char const* icon;
    };
    ClassLook const CLASS_LOOKS[] = {
        { "" },
        { "Ability_Warrior_BattleShout" },
        { "Spell_Holy_SealOfMight" },
        { "Ability_Hunter_SniperShot" },
        { "Ability_Stealth" },
        { "Spell_Holy_PowerWordShield" },
        { "" },
        { "Spell_Nature_BloodLust" },
        { "Spell_Frost_FrostBolt02" },
        { "Spell_Shadow_SummonImp" },
        { "" },
        { "Ability_Druid_CatForm" },
    };

    ClassLook const* GetClassLook(uint32 classId)
    {
        if (classId >= sizeof(CLASS_LOOKS) / sizeof(CLASS_LOOKS[0]) || !*CLASS_LOOKS[classId].icon)
            return nullptr;
        return &CLASS_LOOKS[classId];
    }

    uint32 CountBits(uint32 value)
    {
        return uint32(std::bitset<32>(value).count());
    }
}

char const* BonkQuests::GetCategoryKey(BonkQuestCategory category)
{
    return category < MAX_BONK_QUEST_CATEGORY ? CATEGORY_KEYS[category] : "";
}

void BonkQuests::Load()
{
    m_quests.clear();
    m_titles.clear();

    if (std::unique_ptr<QueryResult> titles{ WorldDatabase.Query("SELECT `id`, `name`, `pattern`, `class`, `stat`, `value` FROM `bonk_title`") })
    {
        do
        {
            Field* fields = titles->Fetch();
            BonkTitle& title = m_titles[fields[0].GetUInt32()];
            title.id = fields[0].GetUInt32();
            title.name = fields[1].GetCppString();
            title.pattern = fields[2].GetCppString();
            title.classId = fields[3].GetUInt8();
            title.stat = fields[4].GetUInt8();
            title.value = fields[5].GetFloat();
        } while (titles->NextRow());
    }

    std::unique_ptr<QueryResult> result(WorldDatabase.Query(
        "SELECT `id`, `name`, `description`, `icon`, `type`, `target`, `amount`, `reward_type`, `reward_value`, `class`, `param`, `category` FROM `bonk_quest`"));
    if (!result)
    {
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded 0 Bonk quests.");
        return;
    }

    do
    {
        Field* fields = result->Fetch();

        BonkQuest quest;
        quest.id = fields[0].GetUInt32();
        quest.name = fields[1].GetCppString();
        quest.description = fields[2].GetCppString();
        quest.icon = fields[3].GetCppString();
        uint8 const type = fields[4].GetUInt8();
        quest.target = fields[5].GetUInt32();
        quest.amount = std::max(1u, fields[6].GetUInt32());
        uint8 const rewardType = fields[7].GetUInt8();
        quest.rewardValue = fields[8].GetUInt32();
        quest.classId = fields[9].GetUInt8();
        quest.param = fields[10].GetUInt32();
        uint8 const category = fields[11].GetUInt8();

        if (type >= MAX_BONK_QUEST_TYPE || rewardType >= MAX_BONK_REWARD)
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_quest`: quest %u has unknown type %u or reward type %u, skipped.", quest.id, type, rewardType);
            continue;
        }
        quest.type = BonkQuestType(type);
        quest.rewardType = BonkQuestReward(rewardType);
        if (category >= MAX_BONK_QUEST_CATEGORY)
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_quest`: quest %u has unknown category %u; shown under Slayer.", quest.id, category);
        else
            quest.category = BonkQuestCategory(category);

        bool rewardExists = true;
        switch (quest.rewardType)
        {
            case BONK_REWARD_WEAPON:
            case BONK_REWARD_EPIC_RANK: rewardExists = sBonkMgr.GetWeapon(quest.rewardValue) != nullptr; break;
            case BONK_REWARD_PASSIVE:   rewardExists = sBonkMgr.GetPassive(quest.rewardValue) != nullptr; break;
            case BONK_REWARD_TALENT:    rewardExists = sBonkMgr.GetTalent(quest.rewardValue) != nullptr; break;
            case BONK_REWARD_UPGRADE:   rewardExists = sBonkMgr.GetUpgrade(quest.rewardValue) != nullptr; break;
            case BONK_REWARD_MASTERY:   rewardExists = quest.classId != 0; break;
            case BONK_REWARD_CLASS:     rewardExists = GetClassLook(quest.rewardValue) != nullptr; break;
            case BONK_REWARD_CAPSTONE:  rewardExists = sBonkMastery.GetNode(quest.rewardValue) != nullptr; break;
            case BONK_REWARD_TITLE:     rewardExists = m_titles.count(quest.rewardValue) != 0; break;
            case BONK_REWARD_CARD:      rewardExists = sBonkMgr.GetCard(quest.rewardValue) != nullptr; break;
            case BONK_REWARD_GLYPH:     rewardExists = sBonkMgr.GetGlyph(quest.rewardValue) != nullptr; break;
            case BONK_REWARD_CARD_BAN:
            case BONK_REWARD_GLYPH_BAN: rewardExists = quest.rewardValue != 0; break;
            case BONK_REWARD_APPEARANCE:      rewardExists = sObjectMgr.GetItemPrototype(quest.rewardValue) != nullptr; break;
            default: break;
        }
        if (!rewardExists)
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_quest`: quest %u unlocks %u, which does not exist; skipped.", quest.id, quest.rewardValue);
            continue;
        }

        m_quests[quest.id] = std::move(quest);
    } while (result->NextRow());

    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk quests and %u titles", uint32(m_quests.size()), uint32(m_titles.size()));
}

void BonkQuests::OnLogin(Player* player)
{
    uint32 const account = player->GetBonkPlayer()->GetProgressAccount();

    AccountProgress loaded;
    std::unique_ptr<QueryResult> result(CharacterDatabase.PQuery("SELECT `quest`, `progress`, `completed` FROM `bonk_account_quest` WHERE `account` = %u", account));
    if (result)
    {
        do
        {
            Field* fields = result->Fetch();
            Progress& progress = loaded[fields[0].GetUInt32()];
            progress.value = fields[1].GetUInt32();
            progress.completed = fields[2].GetUInt8() != 0;
        } while (result->NextRow());
    }

    std::set<uint64> disabled;
    result = CharacterDatabase.PQuery("SELECT `type`, `id` FROM `bonk_account_disabled` WHERE `account` = %u", account);
    if (result)
    {
        do
        {
            Field* fields = result->Fetch();
            disabled.insert(UnlockKey(BonkQuestReward(fields[0].GetUInt8()), fields[1].GetUInt32()));
        } while (result->NextRow());
    }

    {
        std::lock_guard<std::mutex> guard(m_lock);
        m_accounts[account] = std::move(loaded);
        m_disabled[account] = std::move(disabled);
    }

    OnLevelCleared(player, player->GetBonkPlayer()->GetBestLevel(), player->GetBonkPlayer()->GetAccountBestLevel());
    OnProgress(player, BONK_QUEST_MASTERY_LEVEL, player->GetClass(), player->GetBonkPlayer()->GetMasteryLevel(), true);
    OnProgress(player, BONK_QUEST_QUESTS_DONE, 0, CountCompleted(account), true);
}

std::map<uint32, std::pair<uint32, bool>> BonkQuests::GetAllProgress(uint32 account) const
{
    std::map<uint32, std::pair<uint32, bool>> all;
    std::lock_guard<std::mutex> guard(m_lock);
    auto itr = m_accounts.find(account);
    if (itr == m_accounts.end())
        return all;
    for (auto const& progress : itr->second)
        all[progress.first] = { progress.second.value, progress.second.completed };
    return all;
}

void BonkQuests::Save(uint32 account)
{
    std::vector<std::pair<uint32, uint32>> rows;
    {
        std::lock_guard<std::mutex> guard(m_lock);
        auto itr = m_accounts.find(account);
        if (itr == m_accounts.end())
            return;
        for (auto& progress : itr->second)
        {
            if (!progress.second.dirty || progress.second.completed)
                continue;
            progress.second.dirty = false;
            rows.emplace_back(progress.first, progress.second.value);
        }
    }

    for (auto const& row : rows)
        CharacterDatabase.PExecute("REPLACE INTO `bonk_account_quest` (`account`, `quest`, `progress`, `completed`) VALUES (%u, %u, %u, 0)",
            account, row.first, row.second);
}

bool BonkQuests::IsDisabled(uint32 account, BonkQuestReward type, uint32 id) const
{
    std::lock_guard<std::mutex> guard(m_lock);
    auto itr = m_disabled.find(account);
    return itr != m_disabled.end() && itr->second.count(UnlockKey(type, id)) != 0;
}

bool BonkQuests::SetDisabled(uint32 account, BonkQuestReward type, uint32 id, bool disabled, uint32 slots, std::string& error,
    LocaleConstant locale)
{
    if (disabled && !IsTogglable(type))
    {
        error = sBonkLocale.GetString(BONK_STRING_ONLY_CARDS_AND_GLYPHS_BANNED, locale, {});
        return false;
    }
    if (disabled && IsLocked(account, type, id))
    {
        error = sBonkLocale.GetString(BONK_STRING_BAN_ONLY_UNLOCKED, locale, {});
        return false;
    }
    if (disabled && CountDisabled(account, type) >= slots)
    {
        bool const card = type == BONK_REWARD_CARD;
        error = sBonkLocale.GetString(slots ? (card ? BONK_STRING_CARD_BAN_SLOTS_IN_USE : BONK_STRING_GLYPH_BAN_SLOTS_IN_USE) :
            (card ? BONK_STRING_NO_CARD_BAN_SLOTS : BONK_STRING_NO_GLYPH_BAN_SLOTS), locale, {});
        return false;
    }
    {
        std::lock_guard<std::mutex> guard(m_lock);
        if (disabled)
            m_disabled[account].insert(UnlockKey(type, id));
        else
            m_disabled[account].erase(UnlockKey(type, id));
    }
    if (disabled)
        CharacterDatabase.PExecute("REPLACE INTO `bonk_account_disabled` (`account`, `type`, `id`) VALUES (%u, %u, %u)", account, uint32(type), id);
    else
        CharacterDatabase.PExecute("DELETE FROM `bonk_account_disabled` WHERE `account` = %u AND `type` = %u AND `id` = %u", account, uint32(type), id);
    return true;
}

void BonkQuests::TrimDisabled(uint32 account, BonkQuestReward type, uint32 slots)
{
    std::vector<std::pair<BonkQuestReward, uint32>> kept;
    for (auto const& off : GetDisabled(account))
        if (off.first == type)
            kept.push_back(off);
    std::string error;
    for (size_t i = slots; i < kept.size(); ++i)
        SetDisabled(account, kept[i].first, kept[i].second, false, slots, error);
}

uint32 BonkQuests::CountDisabled(uint32 account, BonkQuestReward type) const
{
    uint32 count = 0;
    for (auto const& off : GetDisabled(account))
        if (off.first == type)
            ++count;
    return count;
}

std::vector<BonkQuest const*> BonkQuests::GetRewardQuests(BonkQuestReward type) const
{
    std::vector<BonkQuest const*> quests;
    for (auto const& itr : m_quests)
        if (itr.second.rewardType == type)
            quests.push_back(&itr.second);
    return quests;
}

bool BonkQuests::IsCompleted(uint32 account, uint32 questId) const
{
    std::lock_guard<std::mutex> guard(m_lock);
    auto itr = m_accounts.find(account);
    if (itr == m_accounts.end())
        return false;
    auto progress = itr->second.find(questId);
    return progress != itr->second.end() && progress->second.completed;
}

std::vector<std::pair<BonkQuestReward, uint32>> BonkQuests::GetDisabled(uint32 account) const
{
    std::vector<std::pair<BonkQuestReward, uint32>> list;
    std::lock_guard<std::mutex> guard(m_lock);
    auto itr = m_disabled.find(account);
    if (itr != m_disabled.end())
        for (uint64 key : itr->second)
            list.emplace_back(BonkQuestReward(key >> 32), uint32(key & 0xFFFFFFFF));
    return list;
}

bool BonkQuests::IsLocked(uint32 account, BonkQuestReward type, uint32 id) const
{
    if (type == BONK_REWARD_GLYPH)
        if (BonkGlyph const* glyph = sBonkMgr.GetGlyph(id))
            if (glyph->starter)
                return false;
    BonkQuest const* quest = GetUnlockingQuest(type, id);
    if (!quest)
        return false;

    {
        std::lock_guard<std::mutex> guard(m_lock);
        auto itr = m_accounts.find(account);
        if (itr == m_accounts.end())
            return true;
        auto progress = itr->second.find(quest->id);
        if (progress == itr->second.end() || !progress->second.completed)
            return true;
    }
    return false;
}

BonkQuest const* BonkQuests::GetUnlockingQuest(BonkQuestReward type, uint32 id) const
{
    for (auto const& itr : m_quests)
        if (itr.second.rewardType == type && itr.second.rewardValue == id)
            return &itr.second;
    return nullptr;
}

bool BonkQuests::Counts(Player const* player, BonkQuest const& quest)
{
    return !quest.classId || player->GetClass() == quest.classId;
}

BonkTitle const* BonkQuests::GetTitle(uint32 id) const
{
    auto const itr = m_titles.find(id);
    return itr != m_titles.end() ? &itr->second : nullptr;
}

std::vector<BonkTitle const*> BonkQuests::GetEarnedTitles(uint32 account) const
{
    std::vector<BonkTitle const*> earned;
    std::lock_guard<std::mutex> guard(m_lock);
    auto const progress = m_accounts.find(account);
    if (progress == m_accounts.end())
        return earned;

    for (auto const& itr : m_titles)
    {
        BonkTitle const& title = itr.second;
        for (auto const& quest : m_quests)
        {
            BonkQuest const& q = quest.second;
            if (q.rewardType != BONK_REWARD_TITLE || q.rewardValue != title.id)
                continue;
            auto const entry = progress->second.find(q.id);
            if (entry != progress->second.end() && entry->second.completed)
            {
                earned.push_back(&title);
                break;
            }
        }
    }
    return earned;
}

bool BonkQuests::HasTitle(uint32 account, uint32 titleId) const
{
    for (BonkTitle const* title : GetEarnedTitles(account))
        if (title->id == titleId)
            return true;
    return false;
}

uint32 BonkQuests::GetMasteryPoints(uint32 account, uint8 classId) const
{
    std::lock_guard<std::mutex> guard(m_lock);
    auto itr = m_accounts.find(account);
    if (itr == m_accounts.end())
        return 0;

    uint32 points = 0;
    for (auto const& quest : m_quests)
    {
        BonkQuest const& q = quest.second;
        if (q.rewardType != BONK_REWARD_MASTERY || q.classId != classId)
            continue;
        auto progress = itr->second.find(q.id);
        if (progress != itr->second.end() && progress->second.completed)
            points += q.rewardValue;
    }
    return points;
}

uint32 BonkQuests::GetRootWeapon(uint32 spellId, uint32 classMask) const
{
    if (!spellId)
        return 0;

    for (auto const& itr : sBonkMgr.GetWeapons())
    {
        if (itr.second.spellId != spellId || (itr.second.classMask && !(itr.second.classMask & classMask)))
            continue;

        BonkWeapon const* weapon = &itr.second;
        for (uint32 steps = 0; weapon->evolvesFrom && steps < 8; ++steps)
            if (BonkWeapon const* from = sBonkMgr.GetWeapon(weapon->evolvesFrom))
                weapon = from;
            else
                break;
        return weapon->id;
    }
    return 0;
}

void BonkQuests::Track(Player* player, std::function<void(BonkQuest const&, AccountProgress&)> const& step)
{
    if (player->GetBonkPlayer()->IsInSandbox())
        return;
    uint32 const account = player->GetBonkPlayer()->GetProgressAccount();
    std::vector<BonkQuest const*> done;
    {
        std::lock_guard<std::mutex> guard(m_lock);
        auto itr = m_accounts.find(account);
        if (itr == m_accounts.end())
            return;
        AccountProgress& progress = itr->second;

        for (auto const& quest : m_quests)
        {
            BonkQuest const& q = quest.second;
            if (!Counts(player, q))
                continue;
            auto const entry = progress.find(q.id);
            if (entry != progress.end() && entry->second.completed)
                continue;
            step(q, progress);
            auto const after = progress.find(q.id);
            if (after != progress.end() && after->second.completed)
                done.push_back(&q);
        }
    }

    for (BonkQuest const* quest : done)
        Complete(player, *quest);
}

void BonkQuests::Advance(Player* , AccountProgress& progress, BonkQuest const& quest, uint32 value, bool absolute)
{
    Progress& entry = progress[quest.id];
    if (entry.completed)
        return;

    uint32 const next = std::min(quest.amount, absolute ? std::max(entry.value, value) : entry.value + value);
    if (next == entry.value)
        return;

    entry.value = next;
    entry.dirty = true;
    if (entry.value >= quest.amount)
        entry.completed = true;
}

void BonkQuests::AdvanceBit(AccountProgress& progress, BonkQuest const& quest, uint32 bit)
{
    if (bit >= 32)
        return;

    Progress& entry = progress[quest.id];
    if (entry.completed || (entry.value & (1u << bit)))
        return;

    entry.value |= 1u << bit;
    entry.dirty = true;
    if (CountBits(entry.value) >= quest.amount)
        entry.completed = true;
}

uint32 BonkQuests::GetProgress(uint32 account, BonkQuest const& quest) const
{
    std::lock_guard<std::mutex> guard(m_lock);
    auto accountItr = m_accounts.find(account);
    if (accountItr == m_accounts.end())
        return 0;
    auto entryItr = accountItr->second.find(quest.id);
    return entryItr == accountItr->second.end() ? 0 : GetShownProgress(quest, entryItr->second);
}

uint32 BonkQuests::GetShownProgress(BonkQuest const& quest, Progress const& entry)
{
    if (entry.completed)
        return quest.amount;
    return quest.CountsBits() ? CountBits(entry.value) : entry.value;
}

void BonkQuests::OnKill(Player* player, BonkSpawnKind kind, uint32 killingSpell, uint32 creatureType, uint32 entry, bool standing)
{
    if (player->GetBonkPlayer()->IsInSandbox())
        return;

    uint32 const weapon = GetRootWeapon(killingSpell, player->GetClassMask());
    uint32 const level = player->GetLevel();
    SpellEntry const* spellInfo = killingSpell ? sSpellMgr.GetSpellEntry(killingSpell) : nullptr;
    uint32 const school = spellInfo ? spellInfo->School + 1 : 0;

    Track(player, [&](BonkQuest const& q, AccountProgress& progress)
    {
        switch (q.type)
        {
            case BONK_QUEST_KILLS:
                Advance(player, progress, q, 1, false);
                break;
            case BONK_QUEST_KILL_KIND:
                if (q.target == uint32(kind))
                    Advance(player, progress, q, 1, false);
                break;
            case BONK_QUEST_KILL_WEAPON:
                if (weapon && q.target == weapon)
                    Advance(player, progress, q, 1, false);
                break;
            case BONK_QUEST_KILL_TYPE:
                if (q.target == creatureType)
                    Advance(player, progress, q, 1, false);
                break;
            case BONK_QUEST_KILL_SCHOOL:
                if (school && q.target == school)
                    Advance(player, progress, q, 1, false);
                break;
            case BONK_QUEST_KILLS_STANDING:
                if (standing)
                    Advance(player, progress, q, 1, false);
                break;
            case BONK_QUEST_KILL_CREATURE:
                if (q.target == entry)
                    Advance(player, progress, q, 1, false);
                break;
            case BONK_QUEST_REACH_LEVEL:
                Advance(player, progress, q, level, true);
                break;
            default:
                break;
        }
    });
}

void BonkQuests::OnLevelCleared(Player* player, uint32 classLevel, uint32 accountLevel)
{
    if (!accountLevel)
        return;

    Track(player, [&](BonkQuest const& q, AccountProgress& progress)
    {
        if (q.type == BONK_QUEST_CLEAR_LEVEL)
            Advance(player, progress, q, q.classId ? classLevel : accountLevel, true);
    });
}

void BonkQuests::OnDungeonCleared(Player* player, uint32 mapId)
{
    Track(player, [&](BonkQuest const& q, AccountProgress& progress)
    {
        if (q.type == BONK_QUEST_CLEAR_DUNGEON && q.target == mapId)
            Advance(player, progress, q, 1, false);
    });
}

void BonkQuests::OnBossKilled(Player* player, uint32 tierId, uint32 stage, uint32 second)
{
    Track(player, [&](BonkQuest const& q, AccountProgress& progress)
    {
        switch (q.type)
        {
            case BONK_QUEST_BOSS_BEFORE:
                if ((!q.target || q.target == tierId) && second < q.param)
                    Advance(player, progress, q, 1, false);
                break;
            case BONK_QUEST_CLEAR_CLASSES:
                if (q.param == stage && (q.target & player->GetClassMask()))
                    AdvanceBit(progress, q, player->GetClass() - 1);
                break;
            default:
                break;
        }
    });
}

void BonkQuests::OnBossFight(Player* player, BonkSpawnKind kind, uint32 seconds, bool unhurt, uint32 healthPercent)
{
    Track(player, [&](BonkQuest const& q, AccountProgress& progress)
    {
        if (q.target != uint32(kind))
            return;
        switch (q.type)
        {
            case BONK_QUEST_BOSS_FAST:
                if (seconds <= q.param)
                    Advance(player, progress, q, 1, false);
                break;
            case BONK_QUEST_BOSS_UNHURT:
                if (unhurt)
                    Advance(player, progress, q, 1, false);
                break;
            case BONK_QUEST_BOSS_LOW_HEALTH:
                if (healthPercent < q.param)
                    Advance(player, progress, q, 1, false);
                break;
            default:
                break;
        }
    });
}

void BonkQuests::OnShards(Player* player, uint32 count)
{
    OnProgress(player, BONK_QUEST_SHARDS, 0, count);
}

void BonkQuests::OnProgress(Player* player, BonkQuestType type, uint32 target, uint32 value, bool absolute)
{
    Track(player, [&](BonkQuest const& q, AccountProgress& progress)
    {
        if (q.type != type || (q.target && q.target != target))
            return;
        if (q.CountsBits())
            AdvanceBit(progress, q, value);
        else
            Advance(player, progress, q, value, absolute);
    });
}

void BonkQuests::Complete(Player* player, BonkQuest const& quest)
{
    uint32 const account = player->GetBonkPlayer()->GetProgressAccount();
    CharacterDatabase.PExecute("REPLACE INTO `bonk_account_quest` (`account`, `quest`, `progress`, `completed`) VALUES (%u, %u, %u, 1)",
        account, quest.id, quest.amount);
    {
        std::lock_guard<std::mutex> guard(m_lock);
        m_accounts[account][quest.id].dirty = false;
    }

    BonkPlayer* bonk = player->GetBonkPlayer();
    switch (quest.rewardType)
    {
        case BONK_REWARD_GOLD:
            player->ModifyMoney(int32(quest.rewardValue));
            break;
        case BONK_REWARD_SHARDS:
            bonk->AddShards(quest.rewardValue);
            break;
        case BONK_REWARD_MASTERY:
            bonk->SendMasteryState();
            break;
        case BONK_REWARD_TITLE:
            bonk->SendTitles();
            break;
        case BONK_REWARD_APPEARANCE:
            BonkTransmog::UnlockAppearance(player, quest.rewardValue);
            break;
        default:
            break;
    }

    std::string icon;
    std::string const reward = DescribeReward(quest, &icon, bonk->GetLocale());
    std::string const name = bonk->Localize(BONK_FIELD_QUEST_NAME, quest.id, quest.name);
    if (bonk->IsAddonReady())
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteQuestDone(data, quest.id, name, reward, icon);
        bonk->GetPlayer()->GetSession()->SendPacket(&data);
    }
    else
        bonk->Notify(BONK_STRING_QUEST_COMPLETE, { name, reward });

    OnProgress(player, BONK_QUEST_QUESTS_DONE, 0, CountCompleted(account), true);
}

uint32 BonkQuests::CountCompleted(uint32 account) const
{
    std::lock_guard<std::mutex> guard(m_lock);
    auto itr = m_accounts.find(account);
    if (itr == m_accounts.end())
        return 0;
    uint32 count = 0;
    for (auto const& progress : itr->second)
        if (progress.second.completed && m_quests.count(progress.first))
            ++count;
    return count;
}

std::string BonkQuests::DescribeReward(BonkQuest const& quest, std::string* icon, LocaleConstant locale) const
{
    switch (quest.rewardType)
    {
        case BONK_REWARD_GOLD:
            *icon = "INV_Misc_Coin_02";
            return FormatBonkMoney(quest.rewardValue, locale);
        case BONK_REWARD_SHARDS:
            *icon = "INV_Misc_Ticket_Darkmoon_01";
            return FormatBonkShards(quest.rewardValue, locale);
        case BONK_REWARD_WEAPON:
            if (BonkWeapon const* weapon = sBonkMgr.GetWeapon(quest.rewardValue))
            {
                *icon = weapon->icon;
                return sBonkLocale.GetString(BONK_STRING_REWARD_UNLOCKS, locale, { sBonkLocale.Localize(BONK_FIELD_WEAPON_NAME, weapon->id, weapon->name, locale) });
            }
            break;
        case BONK_REWARD_PASSIVE:
            if (BonkPassive const* passive = sBonkMgr.GetPassive(quest.rewardValue))
            {
                *icon = passive->icon;
                return sBonkLocale.GetString(BONK_STRING_REWARD_UNLOCKS, locale, { sBonkLocale.Localize(BONK_FIELD_PASSIVE_NAME, passive->id, passive->name, locale) });
            }
            break;
        case BONK_REWARD_TALENT:
            if (BonkTalent const* talent = sBonkMgr.GetTalent(quest.rewardValue))
            {
                *icon = talent->layout.icon;
                return sBonkLocale.GetString(BONK_STRING_REWARD_UNLOCKS_FORTUNE, locale, { sBonkLocale.Localize(BONK_FIELD_TALENT_NAME, talent->id, talent->name, locale) });
            }
            break;
        case BONK_REWARD_UPGRADE:
            if (BonkUpgrade const* upgrade = sBonkMgr.GetUpgrade(quest.rewardValue))
            {
                *icon = upgrade->layout.icon;
                return sBonkLocale.GetString(BONK_STRING_REWARD_UNLOCKS_UPGRADE, locale, { sBonkLocale.Localize(BONK_FIELD_UPGRADE_NAME, upgrade->id, upgrade->name, locale) });
            }
            break;
        case BONK_REWARD_MASTERY:
            *icon = "Spell_Holy_SealOfWisdom";
            return sBonkLocale.GetString(quest.rewardValue == 1 ? BONK_STRING_REWARD_TALENT_POINTS_ONE : BONK_STRING_REWARD_TALENT_POINTS, locale,
                { std::to_string(quest.rewardValue) });
        case BONK_REWARD_CLASS:
            if (ClassLook const* look = GetClassLook(quest.rewardValue))
            {
                *icon = look->icon;
                return sBonkLocale.GetString(BONK_STRING_REWARD_UNLOCKS_CLASS, locale, { sBonkLocale.GetString(GetBonkClassName(quest.rewardValue), locale) });
            }
            break;
        case BONK_REWARD_EPIC_RANK:
            if (BonkWeapon const* weapon = sBonkMgr.GetWeapon(quest.rewardValue))
            {
                *icon = weapon->icon;
                return sBonkLocale.GetString(BONK_STRING_REWARD_EPIC_RANK, locale, { sBonkLocale.Localize(BONK_FIELD_WEAPON_NAME, weapon->id, weapon->name, locale) });
            }
            break;
        case BONK_REWARD_CAPSTONE:
            if (BonkMasteryNode const* node = sBonkMastery.GetNode(quest.rewardValue))
            {
                *icon = node->icon;
                return sBonkLocale.GetString(BONK_STRING_REWARD_UNLOCKS_CAPSTONE, locale, { sBonkLocale.Localize(BONK_FIELD_MASTERY_NAME, node->id, node->name, locale) });
            }
            break;
        case BONK_REWARD_CARD:
            if (BonkCard const* card = sBonkMgr.GetCard(quest.rewardValue))
            {
                *icon = card->icon;
                std::string const name = sBonkLocale.Localize(BONK_FIELD_CARD_NAME, card->id, card->name, locale);
                return sBonkLocale.GetString(card->name.compare(0, 13, "Darkmoon Card") == 0 ? BONK_STRING_REWARD_UNLOCKS : BONK_STRING_REWARD_UNLOCKS_CARD, locale, { name });
            }
            break;
        case BONK_REWARD_GLYPH:
            if (BonkGlyph const* glyph = sBonkMgr.GetGlyph(quest.rewardValue))
            {
                *icon = glyph->icon;
                return sBonkLocale.GetString(BONK_STRING_REWARD_UNLOCKS, locale, { sBonkLocale.Localize(BONK_FIELD_GLYPH_NAME, glyph->id, glyph->name, locale) });
            }
            break;
        case BONK_REWARD_CARD_BAN:
            *icon = "INV_Misc_Ticket_Tarot_Stack_01";
            return sBonkLocale.GetString(quest.rewardValue == 1 ? BONK_STRING_REWARD_CARD_BAN_ONE : BONK_STRING_REWARD_CARD_BANS, locale, { std::to_string(quest.rewardValue) });
        case BONK_REWARD_GLYPH_BAN:
            *icon = "INV_Misc_Ticket_Tarot_Stack_01";
            return sBonkLocale.GetString(quest.rewardValue == 1 ? BONK_STRING_REWARD_GLYPH_BAN_ONE : BONK_STRING_REWARD_GLYPH_BANS, locale, { std::to_string(quest.rewardValue) });
        case BONK_REWARD_APPEARANCE:
            if (ItemPrototype const* proto = sObjectMgr.GetItemPrototype(quest.rewardValue))
            {
                *icon = quest.icon;
                return sBonkLocale.GetString(BONK_STRING_REWARD_APPEARANCE, locale, { proto->Name1 });
            }
            break;
        case BONK_REWARD_TITLE:
        {
            auto const title = m_titles.find(quest.rewardValue);
            if (title != m_titles.end())
            {
                *icon = "INV_Misc_Note_02";
                return sBonkLocale.GetString(BONK_STRING_REWARD_TITLE, locale, { sBonkLocale.Localize(BONK_FIELD_TITLE_NAME, title->first, title->second.name, locale) });
            }
            break;
        }
        default:
            break;
    }
    *icon = "INV_Misc_QuestionMark";
    return "";
}

void BonkQuests::SendLog(Player* player, std::string const& npc)
{
    BonkPlayer* bonk = player->GetBonkPlayer();
    if (!bonk->IsAddonReady())
        return;

    AccountProgress progress;
    {
        std::lock_guard<std::mutex> guard(m_lock);
        auto itr = m_accounts.find(player->GetBonkPlayer()->GetProgressAccount());
        if (itr != m_accounts.end())
            progress = itr->second;
    }

    if (bonk->IsAddonReady())
    {
        WorldPacket open(SMSG_HOA_MESSAGE);
        HoAWriteQuestLogOpen(open, npc);
        bonk->GetPlayer()->GetSession()->SendPacket(&open);
    }
    for (auto const& itr : m_quests)
    {
        BonkQuest const& quest = itr.second;
        if (!Counts(player, quest))
            continue;
        Progress const& entry = progress[quest.id];
        if (IsHiddenUntilDone(quest) && !entry.completed)
            continue;
        std::string rewardIcon;
        std::string const reward = DescribeReward(quest, &rewardIcon, bonk->GetLocale());
        if (!bonk->IsAddonReady())
            continue;
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteQuestEntry(data, quest.id, bonk->Localize(BONK_FIELD_QUEST_NAME, quest.id, quest.name),
            bonk->Localize(BONK_FIELD_QUEST_DESCRIPTION, quest.id, quest.description), quest.icon,
            GetShownProgress(quest, entry), quest.amount, entry.completed, reward, rewardIcon, quest.classId != 0,
            GetCategoryKey(quest.category));
        bonk->GetPlayer()->GetSession()->SendPacket(&data);
    }
    if (bonk->IsAddonReady())
    {
        WorldPacket end(SMSG_HOA_MESSAGE);
        HoAWriteQuestLogEnd(end);
        bonk->GetPlayer()->GetSession()->SendPacket(&end);
    }
}

std::vector<std::string> BonkQuests::DescribeAll(Player* player) const
{
    AccountProgress progress;
    {
        std::lock_guard<std::mutex> guard(m_lock);
        auto itr = m_accounts.find(player->GetBonkPlayer()->GetProgressAccount());
        if (itr != m_accounts.end())
            progress = itr->second;
    }

    std::vector<std::string> lines;
    for (auto const& itr : m_quests)
    {
        BonkQuest const& quest = itr.second;
        if (!Counts(player, quest))
            continue;
        Progress const& entry = progress[quest.id];
        if (IsHiddenUntilDone(quest) && !entry.completed)
            continue;
        std::string icon;
        BonkPlayer const* bonk = player->GetBonkPlayer();
        std::string const reward = DescribeReward(quest, &icon, bonk->GetLocale());
        std::string const name = bonk->Localize(BONK_FIELD_QUEST_NAME, quest.id, quest.name);
        std::string const description = bonk->Localize(BONK_FIELD_QUEST_DESCRIPTION, quest.id, quest.description);
        std::string line = entry.completed ? bonk->GetString(BONK_STRING_QUEST_GOSSIP_DONE, { name, description }) :
            bonk->GetString(BONK_STRING_QUEST_GOSSIP_PROGRESS, { name, std::to_string(GetShownProgress(quest, entry)), std::to_string(quest.amount), description });
        if (!reward.empty())
            line += " " + bonk->GetString(BONK_STRING_QUEST_GOSSIP_REWARD, { reward });
        lines.push_back(line);
    }
    return lines;
}

bool GossipHello_npc_bonk_quests(Player* player, Creature* creature)
{
    if (player->GetBonkPlayer()->IsAddonReady())
    {
        player->GetBonkPlayer()->SendNpcName(creature);
        sBonkQuests.SendLog(player, player->GetBonkPlayer()->GetLocalName(creature));
        player->SEND_GOSSIP_MENU(BONK_TEXT_QUEST_BOARD, creature->GetObjectGuid());
        return true;
    }

    for (std::string const& line : sBonkQuests.DescribeAll(player))
    {
        if (player->PlayerTalkClass->GetGossipMenu().MenuItemCount() >= GOSSIP_MAX_MENU_ITEMS)
            break;
        player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, line.c_str(), GOSSIP_SENDER_MAIN, GOSSIP_ACTION_INFO_DEF);
    }
    player->SEND_GOSSIP_MENU(BONK_TEXT_QUEST_BOARD, creature->GetObjectGuid());
    return true;
}

bool GossipSelect_npc_bonk_quests(Player* player, Creature* creature, uint32 , uint32 )
{
    return GossipHello_npc_bonk_quests(player, creature);
}

uint32 DialogStatus_npc_bonk_quests(Player* , Creature*)
{
    return DIALOG_STATUS_AVAILABLE;
}

void AddSC_bonk_quests()
{
    Script* newscript = new Script;
    newscript->Name = "npc_bonk_quests";
    newscript->pGossipHello = &GossipHello_npc_bonk_quests;
    newscript->pGossipSelect = &GossipSelect_npc_bonk_quests;
    newscript->pNPCDialogStatus = &DialogStatus_npc_bonk_quests;
    newscript->RegisterSelf();
}

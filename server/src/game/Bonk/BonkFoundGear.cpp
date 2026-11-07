#include "BonkFoundGear.h"
#include "BonkLocale.h"
#include "BonkPlayer.h"
#include "BonkStrings.h"
#include "Database/DatabaseEnv.h"
#include "Item.h"
#include "Log.h"
#include "Player.h"
#include "Policies/SingletonImp.h"
#include "Utilities/Random.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <iterator>

INSTANTIATE_SINGLETON_1(BonkFoundStore);

float BonkGearTierScale(uint32 tier)
{
    return 1.0f + BONK_GEAR_TIER_STEP * float(std::max(1u, tier) - 1);
}

namespace
{
    float const BONK_FOUND_BLUE_SECOND_LINE_CHANCE = 25.0f;
    float const BONK_FOUND_EPIC_SECOND_LINE_CHANCE = 50.0f;
    uint32 const BONK_FOUND_UPGRADE_BASE_SCRAP = 20;
    uint32 const BONK_SCRAP_PER_PLAIN_FIND = 1;
    uint32 const BONK_SCRAP_PER_FIND = 2;
    uint32 const BONK_SCRAP_TIERS_PER_POINT = 2;
    uint32 const BONK_FOUND_UPGRADE_SCRAP_PER_TIER = 5;
    uint32 const BONK_FOUND_REROLL_OFFERS = 2;
    float const BONK_FOUND_REROLL_FIRST_GOLD = 50.0f;
    float const BONK_FOUND_REROLL_GROWTH = 1.5f;
    uint32 const BONK_FOUND_REROLL_MAX_GOLD = 1000;
    uint32 const BONK_FOUND_REROLL_GOLD_STEP = 5;
    uint32 const BONK_COPPER_PER_GOLD = 10000;
    float const BONK_ITEM_LEVEL_PER_SCALE = 10.0f;
    float const BONK_ITEM_LEVEL_BLUE = 1.1f;
    float const BONK_ITEM_LEVEL_EPIC = 1.45f;

    struct BonkFoundLineRange
    {
        BonkPassiveEffect effect;
        float low;
        float high;
        bool grows;
    };

    BonkFoundLineRange const BONK_FOUND_LINE_RANGES[] =
    {
        { BONK_PASSIVE_POWER,       1.8f,  3.6f, true },
        { BONK_PASSIVE_MAX_HEALTH,  2.1f,  4.2f, true },
        { BONK_PASSIVE_CRIT,        1.0f,  2.0f, false },
        { BONK_PASSIVE_CRIT_DAMAGE, 2.0f,  4.0f, false },
        { BONK_PASSIVE_DODGE,       0.75f, 1.5f, false },
        { BONK_PASSIVE_SHIELD,      2.0f,  3.5f, false },
    };

    BonkFoundLineRange const* FindRange(uint8 effect)
    {
        for (BonkFoundLineRange const& range : BONK_FOUND_LINE_RANGES)
            if (range.effect == effect)
                return &range;
        return nullptr;
    }

    bool IsGrowingStat(uint8 effect)
    {
        return effect == BONK_PASSIVE_POWER || effect == BONK_PASSIVE_MAX_HEALTH || effect == BONK_PASSIVE_ARMOR;
    }

    uint32 RollLineCount(uint8 quality)
    {
        switch (quality)
        {
            case ITEM_QUALITY_NORMAL:   return 0;
            case ITEM_QUALITY_UNCOMMON: return 1;
            case ITEM_QUALITY_RARE:     return roll_chance_f(BONK_FOUND_BLUE_SECOND_LINE_CHANCE) ? 2 : 1;
            default:                    return roll_chance_f(BONK_FOUND_EPIC_SECOND_LINE_CHANCE) ? 2 : 1;
        }
    }

    std::vector<BonkFoundLine> RollLines(uint32 count, float minRoll)
    {
        std::vector<uint8> effects;
        for (BonkFoundLineRange const& range : BONK_FOUND_LINE_RANGES)
            effects.push_back(range.effect);
        std::vector<BonkFoundLine> lines;
        while (lines.size() < count && !effects.empty())
        {
            uint32 const pick = urand(0, uint32(effects.size() - 1));
            BonkFoundLine line;
            line.effect = effects[pick];
            line.roll = frand(minRoll, 1.0f);
            lines.push_back(line);
            effects.erase(effects.begin() + pick);
        }
        return lines;
    }

    void SaveFound(uint32 itemGuid, BonkFoundGear const& found)
    {
        uint8 effects[BONK_FOUND_MAX_LINES] = { BONK_FOUND_NO_LINE, BONK_FOUND_NO_LINE };
        float rolls[BONK_FOUND_MAX_LINES] = { 0.0f, 0.0f };
        for (size_t i = 0; i < found.lines.size() && i < BONK_FOUND_MAX_LINES; ++i)
        {
            effects[i] = found.lines[i].effect;
            rolls[i] = found.lines[i].roll;
        }
        CharacterDatabase.PExecute("REPLACE INTO `bonk_item_found` (`item_guid`, `tier`, `line1_effect`, `line1_roll`, `line2_effect`, `line2_roll`, "
            "`rerolls`, `reroll_line`, `upgrades`, `season`) VALUES (%u, %u, %u, %f, %u, %f, %u, %u, %u, %u)", itemGuid, found.tier, effects[0], rolls[0], effects[1], rolls[1],
            found.rerolls, uint32(found.rerollLine), found.upgrades, found.season);
    }
}

void BonkFoundStore::Load()
{
    {
        std::lock_guard<std::mutex> guard(m_lock);
        m_items.clear();
    }
    CharacterDatabase.DirectExecute("DELETE `f` FROM `bonk_item_found` `f` LEFT JOIN `item_instance` `i` ON `i`.`guid` = `f`.`item_guid` WHERE `i`.`guid` IS NULL");
    std::unique_ptr<QueryResult> result(CharacterDatabase.Query(
        "SELECT `item_guid`, `tier`, `line1_effect`, `line1_roll`, `line2_effect`, `line2_roll`, `rerolls`, `reroll_line`, `upgrades`, `season` FROM `bonk_item_found`"));
    uint32 const loaded = ReadRows(result.get(), false);
    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk found gear pieces", loaded);
}

void BonkFoundStore::LoadCharacter(uint32 characterGuid)
{
    std::unique_ptr<QueryResult> result(CharacterDatabase.PQuery(
        "SELECT `f`.`item_guid`, `f`.`tier`, `f`.`line1_effect`, `f`.`line1_roll`, `f`.`line2_effect`, `f`.`line2_roll`, `f`.`rerolls`, `f`.`reroll_line`, "
        "`f`.`upgrades`, `f`.`season` FROM `bonk_item_found` `f` WHERE `f`.`item_guid` IN "
        "(SELECT `item_guid` FROM `character_inventory` WHERE `guid` = %u UNION SELECT `item_guid` FROM `mail_items` WHERE `receiver_guid` = %u)",
        characterGuid, characterGuid));
    ReadRows(result.get(), true);
}

uint32 BonkFoundStore::ReadRows(QueryResult* result, bool keepKnown)
{
    std::lock_guard<std::mutex> guard(m_lock);
    uint32 count = 0;
    if (result)
    {
        do
        {
            Field* fields = result->Fetch();
            if (keepKnown && m_items.count(fields[0].GetUInt32()))
                continue;
            BonkFoundGear found;
            found.tier = fields[1].GetUInt32();
            for (uint32 i = 0; i < BONK_FOUND_MAX_LINES; ++i)
            {
                uint8 const effect = fields[2 + i * 2].GetUInt8();
                if (!FindRange(effect))
                    continue;
                BonkFoundLine line;
                line.effect = effect;
                line.roll = fields[3 + i * 2].GetFloat();
                found.lines.push_back(line);
            }
            found.rerolls = fields[6].GetUInt32();
            uint8 const rerollLine = fields[7].GetUInt8();
            found.rerollLine = rerollLine < found.lines.size() ? rerollLine : BONK_FOUND_NO_LINE;
            found.upgrades = fields[8].GetUInt32();
            found.season = fields[9].GetUInt32();
            m_items[fields[0].GetUInt32()] = found;
            ++count;
        } while (result->NextRow());
    }
    return count;
}

bool BonkFoundStore::Get(uint32 itemGuid, BonkFoundGear& found) const
{
    std::lock_guard<std::mutex> guard(m_lock);
    auto itr = m_items.find(itemGuid);
    if (itr == m_items.end())
        return false;
    found = itr->second;
    return true;
}

bool BonkFoundStore::IsFound(uint32 itemGuid) const
{
    std::lock_guard<std::mutex> guard(m_lock);
    return m_items.count(itemGuid) != 0;
}

void BonkFoundStore::Set(uint32 itemGuid, BonkFoundGear const& found)
{
    {
        std::lock_guard<std::mutex> guard(m_lock);
        m_items[itemGuid] = found;
    }
    SaveFound(itemGuid, found);
}

void BonkFoundStore::Forget(uint32 itemGuid)
{
    {
        std::lock_guard<std::mutex> guard(m_lock);
        if (!m_items.erase(itemGuid))
            return;
    }
    CharacterDatabase.PExecute("DELETE FROM `bonk_item_found` WHERE `item_guid` = %u", itemGuid);
}

BonkFoundGear BonkFound::Roll(uint32 tier, uint8 quality, float minRoll)
{
    BonkFoundGear found;
    found.tier = std::max(1u, tier);
    found.lines = RollLines(RollLineCount(quality), minRoll);
    return found;
}

BonkFoundGear BonkFound::Make(uint32 tier, uint32 lineCount)
{
    BonkFoundGear found;
    found.tier = std::max(1u, tier);
    found.lines = RollLines(std::min<uint32>(lineCount, BONK_FOUND_MAX_LINES), 0.0f);
    return found;
}

float BonkFound::LineValue(BonkFoundLine const& line, uint32 tier)
{
    BonkFoundLineRange const* range = FindRange(line.effect);
    if (!range)
        return 0.0f;
    float const value = range->low + (range->high - range->low) * line.roll;
    float const grown = range->grows ? value * BonkGearTierScale(tier) : value;
    return std::round(grown * 10.0f) / 10.0f;
}

uint32 BonkFound::GetScrapValue(Item const* item)
{
    uint32 const tier = GetItemTier(item);
    if (!tier)
        return BONK_SCRAP_PER_PLAIN_FIND;
    BonkFoundGear found;
    sBonkFound.Get(item->GetGUIDLow(), found);
    uint32 const points = BONK_SCRAP_PER_FIND + tier / BONK_SCRAP_TIERS_PER_POINT;
    return points + points * uint32(found.lines.size()) / 2;
}

uint32 BonkFound::GetItemTier(Item const* item)
{
    if (!item)
        return 0;
    BonkFoundGear found;
    return sBonkFound.Get(item->GetGUIDLow(), found) && found.tier ? found.tier : BonkMgr::GetGearTier(item->GetEntry());
}

uint32 BonkFound::GetUpgradeCost(uint32 tier)
{
    return BONK_FOUND_UPGRADE_BASE_SCRAP + BONK_FOUND_UPGRADE_SCRAP_PER_TIER * tier;
}

uint32 BonkFound::GetRerollCost(uint32 rerolls)
{
    float const gold = BONK_FOUND_REROLL_FIRST_GOLD * std::pow(BONK_FOUND_REROLL_GROWTH, float(std::min<uint32>(rerolls, 20)));
    uint32 const rounded = uint32(std::round(gold / BONK_FOUND_REROLL_GOLD_STEP)) * BONK_FOUND_REROLL_GOLD_STEP;
    return std::min(rounded, BONK_FOUND_REROLL_MAX_GOLD) * BONK_COPPER_PER_GOLD;
}

std::vector<BonkFoundLine> BonkFound::RollRerollOffers(BonkFoundGear const& found, uint8 lineIndex)
{
    std::vector<uint8> effects;
    for (BonkFoundLineRange const& range : BONK_FOUND_LINE_RANGES)
    {
        bool takenByOtherLine = false;
        for (size_t i = 0; i < found.lines.size(); ++i)
            if (i != lineIndex && found.lines[i].effect == range.effect)
                takenByOtherLine = true;
        if (!takenByOtherLine)
            effects.push_back(range.effect);
    }
    std::vector<BonkFoundLine> offers;
    while (offers.size() < BONK_FOUND_REROLL_OFFERS && !effects.empty())
    {
        uint32 const pick = urand(0, uint32(effects.size() - 1));
        BonkFoundLine offer;
        offer.effect = effects[pick];
        offer.roll = frand(0.0f, 1.0f);
        offers.push_back(offer);
        effects.erase(effects.begin() + pick);
    }
    return offers;
}

std::string BonkFound::DescribeOffers(std::vector<BonkFoundLine> const& offers, uint32 tier)
{
    BonkFoundGear shown;
    shown.lines = offers;
    return DescribeLines(shown, tier);
}

std::string BonkFound::DescribeRanges(uint32 tier)
{
    std::string text;
    for (BonkFoundLineRange const& range : BONK_FOUND_LINE_RANGES)
    {
        BonkFoundLine lowest;
        lowest.effect = range.effect;
        lowest.roll = 0.0f;
        BonkFoundLine highest = lowest;
        highest.roll = 1.0f;
        char value[48];
        snprintf(value, sizeof(value), "%u:%.1f:%.1f", uint32(range.effect), LineValue(lowest, tier), LineValue(highest, tier));
        text += (text.empty() ? "" : ",") + std::string(value);
    }
    return text;
}

uint32 BonkFound::GetItemLevel(uint32 tier, uint8 quality)
{
    float const qualityScale = quality >= ITEM_QUALITY_EPIC ? BONK_ITEM_LEVEL_EPIC : quality == ITEM_QUALITY_RARE ? BONK_ITEM_LEVEL_BLUE : 1.0f;
    return uint32(std::lround(BONK_ITEM_LEVEL_PER_SCALE * BonkGearTierScale(tier) * qualityScale));
}

std::string BonkFound::DescribeItemLevel(uint32 tier, uint8 quality, LocaleConstant locale)
{
    return sBonkLocale.GetString(BONK_STRING_FOUND_ITEM_LEVEL, locale, { std::to_string(GetItemLevel(tier, quality)) });
}

void BonkFound::AddWornStats(Item const* item, float* passives)
{
    BonkFoundGear found;
    if (!item || !sBonkFound.Get(item->GetGUIDLow(), found))
        return;
    uint32 const entryTier = BonkMgr::GetGearTier(item->GetEntry());
    uint32 const tier = GetItemTier(item);
    if (tier > entryTier && entryTier)
        if (BonkItemStat const* stat = sBonkMgr.GetItemStat(item->GetEntry()))
        {
            float const extra = BonkGearTierScale(tier) / BonkGearTierScale(entryTier) - 1.0f;
            for (uint8 effect = 0; effect < MAX_BONK_PASSIVE_EFFECT; ++effect)
                if (IsGrowingStat(effect))
                    passives[effect] += stat->stats[effect] * extra;
        }
    for (BonkFoundLine const& line : found.lines)
        passives[line.effect] += LineValue(line, tier);
}

std::string BonkFound::DescribeLines(BonkFoundGear const& found, uint32 tier)
{
    std::string text;
    for (BonkFoundLine const& line : found.lines)
    {
        char value[32];
        snprintf(value, sizeof(value), "%u:%.1f", uint32(line.effect), LineValue(line, tier));
        text += (text.empty() ? "" : ",") + std::string(value);
    }
    return text;
}

std::string BonkFound::DescribeExtra(Item const* item, uint32 tier)
{
    return item ? DescribeExtra(item->GetEntry(), tier) : std::string();
}

std::string BonkFound::DescribeExtra(uint32 entry, uint32 tier)
{
    uint32 const entryTier = BonkMgr::GetGearTier(entry);
    BonkItemStat const* stat = sBonkMgr.GetItemStat(entry);
    if (!stat || !entryTier || tier <= entryTier)
        return std::string();
    float const extra = BonkGearTierScale(tier) / BonkGearTierScale(entryTier) - 1.0f;
    std::string text;
    for (uint8 effect = 0; effect < MAX_BONK_PASSIVE_EFFECT; ++effect)
        if (IsGrowingStat(effect) && stat->stats[effect] != 0.0f)
        {
            char value[32];
            snprintf(value, sizeof(value), "%u:%.1f", uint32(effect), stat->stats[effect] * extra);
            text += (text.empty() ? "" : ",") + std::string(value);
        }
    return text;
}

void BonkFound::Remember(Item const* item, BonkFoundGear const& found)
{
    if (item)
        sBonkFound.Set(item->GetGUIDLow(), found);
}

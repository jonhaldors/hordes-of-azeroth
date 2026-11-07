#include "BonkMgr.h"
#include "BonkContentHash.h"
#include "BonkAura.h"
#include "BonkCoop.h"
#include "BonkEnchant.h"
#include "BonkFoundGear.h"
#include "BonkLocale.h"
#include "BonkRun.h"
#include "BonkCharacterProgress.h"
#include "BonkMastery.h"
#include "BonkQuests.h"
#include "Database/DatabaseEnv.h"
#include "DBCStores.h"
#include "Database/DBCFileLoader.h"
#include "World.h"
#include "Log.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Policies/SingletonImp.h"
#include "SpellMgr.h"
#include "Utilities/Random.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdlib>
#include <map>
#include <tuple>

INSTANTIATE_SINGLETON_1(BonkMgr);

namespace
{
    float const BONK_PASSIVE_RANK_DECAY = 0.85f;
    float const BONK_PASSIVE_RANK_FLOOR = 0.1f;

    struct RaidLooks
    {
        uint32 firstLook;
        uint32 lastLook;
        uint32 openLevel;
    };

    RaidLooks const BONK_EPIC_RAID_LOOKS[] =
    {
        { 1, 4, 10 },
        { 5, 7, 19 },
        { 8, 9, 29 },
        { 10, 10, 39 },
    };

    float const BONK_NEWEST_RAID_CHANCE = 60.0f;
    uint32 const BONK_MYTHIC_LEVEL_OFFSET = 9;
    char const* const BONK_ZUL_GURUB_KEY = "zulgurub";
    char const* const BONK_RUINS_OF_AHNQIRAJ_KEY = "ruinsaq";

    uint32 PickLookUpTo(uint32 firstLook, uint32 lastLook, uint32 tier)
    {
        uint32 const last = std::min(lastLook, std::max(firstLook, tier));
        return urand(firstLook, last);
    }

    uint32 PickEpicLook(uint32 tier)
    {
        std::vector<RaidLooks const*> open;
        for (RaidLooks const& raid : BONK_EPIC_RAID_LOOKS)
            if (tier >= raid.openLevel || open.empty())
                open.push_back(&raid);
        RaidLooks const* raid = open.back();
        if (open.size() > 1 && !roll_chance_f(BONK_NEWEST_RAID_CHANCE))
            raid = open[urand(0, uint32(open.size() - 2))];
        return PickLookUpTo(raid->firstLook, raid->lastLook, tier);
    }

    struct GearColumn
    {
        char const* name;
        BonkPassiveEffect effect;
    };
    GearColumn const BONK_GEAR_COLUMNS[] =
    {
        { "power",        BONK_PASSIVE_POWER },
        { "max_health",   BONK_PASSIVE_MAX_HEALTH },
        { "armor",        BONK_PASSIVE_ARMOR },
        { "dodge",        BONK_PASSIVE_DODGE },
        { "crit",         BONK_PASSIVE_CRIT },
        { "crit_damage",  BONK_PASSIVE_CRIT_DAMAGE },
        { "shield",       BONK_PASSIVE_SHIELD },
        { "haste",        BONK_PASSIVE_HASTE },
        { "area",         BONK_PASSIVE_AREA },
        { "pickup_range", BONK_PASSIVE_PICKUP },
        { "luck",         BONK_PASSIVE_LUCK },
    };
    size_t const BONK_GEAR_COLUMN_COUNT = sizeof(BONK_GEAR_COLUMNS) / sizeof(BONK_GEAR_COLUMNS[0]);

    int32 FindDamageEffect(SpellEntry const* spellInfo)
    {
        for (uint32 i = 0; i < MAX_EFFECT_INDEX; ++i)
            if (spellInfo->Effect[i] == SPELL_EFFECT_SCHOOL_DAMAGE)
                return int32(i);

        for (uint32 i = 0; i < MAX_EFFECT_INDEX; ++i)
            if ((spellInfo->Effect[i] == SPELL_EFFECT_APPLY_AURA || spellInfo->Effect[i] == SPELL_EFFECT_PERSISTENT_AREA_AURA) &&
                spellInfo->EffectApplyAuraName[i] == SPELL_AURA_PERIODIC_DAMAGE)
                return int32(i);

        return -1;
    }

    bool HasWeaponDamage(SpellEntry const* spellInfo)
    {
        for (uint32 i = 0; i < MAX_EFFECT_INDEX; ++i)
            switch (spellInfo->Effect[i])
            {
                case SPELL_EFFECT_WEAPON_DAMAGE:
                case SPELL_EFFECT_WEAPON_DAMAGE_NOSCHOOL:
                case SPELL_EFFECT_NORMALIZED_WEAPON_DMG:
                case SPELL_EFFECT_WEAPON_PERCENT_DAMAGE:
                    return true;
                default:
                    break;
            }
        return false;
    }

    int32 FindTickEffect(SpellEntry const* spellInfo, int32 except)
    {
        for (uint32 i = 0; i < MAX_EFFECT_INDEX; ++i)
            if (int32(i) != except && (spellInfo->Effect[i] == SPELL_EFFECT_APPLY_AURA || spellInfo->Effect[i] == SPELL_EFFECT_PERSISTENT_AREA_AURA) &&
                spellInfo->EffectApplyAuraName[i] == SPELL_AURA_PERIODIC_DAMAGE)
                return int32(i);
        return -1;
    }

    float GetLargestSpellRadius(SpellEntry const* spellInfo)
    {
        float radius = 0.0f;
        for (uint32 i = 0; i < MAX_EFFECT_INDEX; ++i)
            if (spellInfo->EffectRadiusIndex[i])
                radius = std::max(radius, Spells::GetSpellRadius(sSpellRadiusStore.LookupEntry(spellInfo->EffectRadiusIndex[i])));
        return radius;
    }

    void SettleWeaponRadius(BonkWeapon& weapon, SpellEntry const* spellInfo)
    {
        bool const ground = weapon.target == BONK_TARGET_GROUND;
        if (weapon.behavior != BONK_BEHAVIOR_TRAP)
            weapon.spellRadius = ground ? weapon.groundRadius : GetLargestSpellRadius(spellInfo);
        bool const needsRadius = ground || weapon.target == BONK_TARGET_SELF_AREA || weapon.target == BONK_TARGET_CONE;
        if (needsRadius && weapon.radius <= 0.0f)
        {
            weapon.radius = ground ? weapon.groundRadius : weapon.range;
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_weapon`: area weapon %u has no radius; it uses %g yards.", weapon.id, weapon.radius);
        }
        if (ground)
            weapon.groundRadius = weapon.radius;
    }

    std::string FormatScaled(float value)
    {
        char buffer[32];
        snprintf(buffer, sizeof(buffer), "%.2f", value);
        std::string text = buffer;
        while (text.back() == '0')
            text.pop_back();
        if (text.back() == '.')
            text.pop_back();
        return text;
    }

    std::string DescribeScaledValue(std::string const& text, size_t open, size_t close, std::string const& number)
    {
        std::string value = (open > 0 && text[open - 1] == '+' ? "+" : "") + number;
        size_t const after = close + 1;
        if (after < text.size() && text[after] == '%')
            return value + "%";
        if (after + 1 < text.size() && text[after] == ' ' && std::isupper(static_cast<unsigned char>(text[after + 1])))
        {
            size_t const wordEnd = text.find_first_of(" .,", after + 1);
            value += " " + text.substr(after + 1, wordEnd == std::string::npos ? std::string::npos : wordEnd - after - 1);
        }
        return value;
    }

    std::string ScalePassiveText(std::string const& text, float scale, std::vector<std::string>* values = nullptr)
    {
        std::string scaled;
        size_t pos = 0;
        while (pos < text.size())
        {
            size_t const open = text.find('{', pos);
            size_t const close = open == std::string::npos ? std::string::npos : text.find('}', open);
            if (close == std::string::npos)
            {
                scaled += text.substr(pos);
                break;
            }
            scaled += text.substr(pos, open - pos);
            std::string const inner = text.substr(open + 1, close - open - 1);
            char* end = nullptr;
            float const perRank = std::strtof(inner.c_str(), &end);
            if (inner.empty() || *end)
                scaled += text.substr(open, close - open + 1);
            else
            {
                std::string const number = FormatScaled(perRank * scale);
                scaled += number;
                if (values)
                    values->push_back(DescribeScaledValue(text, open, close, number));
            }
            pos = close + 1;
        }
        return scaled;
    }

    std::vector<std::string> GetScaledNumbers(std::string const& text, float scale)
    {
        std::vector<std::string> numbers;
        for (size_t open = text.find('{'); open != std::string::npos; open = text.find('{', open + 1))
        {
            size_t const close = text.find('}', open);
            if (close == std::string::npos)
                break;
            std::string const inner = text.substr(open + 1, close - open - 1);
            char* end = nullptr;
            float const perRank = std::strtof(inner.c_str(), &end);
            if (inner.empty() || *end)
                continue;
            std::string value = (open > 0 && text[open - 1] == '+' ? "+" : "") + FormatScaled(perRank * scale);
            if (close + 1 < text.size() && text[close + 1] == '%')
                value += "%";
            numbers.push_back(value);
        }
        return numbers;
    }

    BonkString GetPassiveStatLabel(BonkPassiveEffect effect, size_t index)
    {
        if (index > 0)
            return effect == BONK_PASSIVE_LEECH && index == 1 ? BONK_STRING_PASSIVE_LABEL_MOST_HEALING : BonkString(0);
        switch (effect)
        {
            case BONK_PASSIVE_POWER:         return BONK_STRING_STAT_POWER;
            case BONK_PASSIVE_HASTE:         return BONK_STRING_STAT_HASTE;
            case BONK_PASSIVE_AMOUNT:        return BONK_STRING_STAT_COUNT;
            case BONK_PASSIVE_MOVE_SPEED:    return BONK_STRING_PASSIVE_LABEL_MOVE_SPEED;
            case BONK_PASSIVE_MAX_HEALTH:    return BONK_STRING_PASSIVE_LABEL_MAX_HEALTH;
            case BONK_PASSIVE_RECOVERY:      return BONK_STRING_PASSIVE_LABEL_RECOVERY;
            case BONK_PASSIVE_GREED:         return BONK_STRING_PASSIVE_LABEL_GOLD;
            case BONK_PASSIVE_GROWTH:        return BONK_STRING_PASSIVE_LABEL_EXPERIENCE;
            case BONK_PASSIVE_PICKUP:        return BONK_STRING_PASSIVE_LABEL_PICKUP;
            case BONK_PASSIVE_LEECH:         return BONK_STRING_PASSIVE_LABEL_LEECH;
            case BONK_PASSIVE_AREA:          return BONK_STRING_STAT_AREA;
            case BONK_PASSIVE_DURATION:      return BONK_STRING_PASSIVE_LABEL_DURATION;
            case BONK_PASSIVE_ARMOR:         return BONK_STRING_STAT_ARMOR;
            case BONK_PASSIVE_DODGE:         return BONK_STRING_PASSIVE_LABEL_DODGE;
            case BONK_PASSIVE_CRIT:          return BONK_STRING_STAT_CRIT_CHANCE;
            case BONK_PASSIVE_CRIT_DAMAGE:   return BONK_STRING_STAT_CRIT_DAMAGE;
            case BONK_PASSIVE_SHIELD:        return BONK_STRING_STRENGTH_SHIELD_LABEL;
            case BONK_PASSIVE_LUCK:          return BONK_STRING_STAT_LUCK;
            case BONK_PASSIVE_POISON_DAMAGE: return BONK_STRING_PASSIVE_LABEL_POISON_DAMAGE;
            case BONK_PASSIVE_BURNING_DAMAGE: return BONK_STRING_PASSIVE_LABEL_BURNING_DAMAGE;
            case BONK_PASSIVE_BLEED_DAMAGE: return BONK_STRING_PASSIVE_LABEL_BLEED_DAMAGE;
            default:                         return BonkString(0);
        }
    }
}

void BonkMgr::CheckContentHash()
{
    std::unique_ptr<QueryResult> result(WorldDatabase.Query("SELECT `hash` FROM `hoa_content` WHERE `id` = 1"));
    if (!result)
    {
        sLog.Out(LOG_BASIC, LOG_LVL_ERROR,
            "HoA content: table `hoa_content` is missing; apply server/sql/content/*.sql (expected %s)",
            HOA_CONTENT_HASH);
        return;
    }
    std::string const hash = result->Fetch()[0].GetCppString();
    if (hash != HOA_CONTENT_HASH)
    {
        sLog.Out(LOG_BASIC, LOG_LVL_ERROR,
            "HoA content: database hash %s does not match this build's %s; apply server/sql/content/*.sql",
            hash.c_str(), HOA_CONTENT_HASH);
    }
    else
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> HoA content hash %s", HOA_CONTENT_HASH);

    std::unique_ptr<QueryResult> sections(WorldDatabase.Query("SELECT `name`, `hash` FROM `hoa_content_section`"));
    if (!sections)
    {
        sLog.Out(LOG_BASIC, LOG_LVL_ERROR,
            "HoA content: table `hoa_content_section` is missing; apply server/sql/content/*.sql");
        return;
    }
    std::map<std::string, std::string> actual;
    do
    {
        Field* fields = sections->Fetch();
        actual[fields[0].GetCppString()] = fields[1].GetCppString();
    } while (sections->NextRow());
    for (HoaContentSection const& expected : HOA_CONTENT_SECTIONS)
    {
        auto itr = actual.find(expected.name);
        if (itr == actual.end())
            sLog.Out(LOG_BASIC, LOG_LVL_ERROR, "HoA content: section %s is missing from the database", expected.name);
        else if (itr->second != expected.hash)
            sLog.Out(LOG_BASIC, LOG_LVL_ERROR, "HoA content: section %s has database hash %s, this build expects %s",
                expected.name, itr->second.c_str(), expected.hash);
    }
    for (auto const& row : actual)
    {
        bool known = false;
        for (HoaContentSection const& expected : HOA_CONTENT_SECTIONS)
            known = known || row.first == expected.name;
        if (!known)
            sLog.Out(LOG_BASIC, LOG_LVL_ERROR, "HoA content: database has unknown section %s", row.first.c_str());
    }
}

void BonkMgr::Load()
{
    CheckContentHash();
    LoadTiers();
    LoadArchetypes();
    LoadWaves();
    LoadScaling();
    LoadMaps();
    LoadZoneArt();

    {
        std::lock_guard<std::mutex> guard(m_mapStartLock);
        m_mapStarts.clear();
        if (std::unique_ptr<QueryResult> starts{ WorldDatabase.Query("SELECT `map`, `x`, `y`, `z` FROM `bonk_map_start`") })
        {
            do
            {
                Field* fields = starts->Fetch();
                BonkMapStart start;
                start.x = fields[1].GetFloat();
                start.y = fields[2].GetFloat();
                start.z = fields[3].GetFloat();
                m_mapStarts[fields[0].GetUInt32()].push_back(start);
            } while (starts->NextRow());
        }
    }
    LoadMapCreatures();
    LoadMapEvents();
    LoadKeywords();
    LoadProjectiles();
    LoadWeapons();
    LoadPassives();
    LoadPowerups();
    LoadCards();
    LoadItemCards();
    LoadGlyphs();
    LoadHiddenEncounters();
    LoadBossLines();
    LoadShopTrees();
    LoadUpgrades();
    LoadTalents();
    LoadItemStats();
    LoadMobs();
    LoadBoltLooks();
    sBonkQuests.Load();
    sBonkMastery.Load();
    BonkCharacterProgress::MoveClassProgressToCharacters();
    LoadPetFamilies();
    sBonkLocale.Load();
    sBonkAura.Load();

    for (uint32 entry : { BONK_GO_CHEST, BONK_GO_CHEST_FREE, BONK_GO_PORTAL, BONK_GO_SHARD, BONK_GO_VAULT })
        if (!sObjectMgr.GetGameObjectTemplate(entry))
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Vanilla Bonk: gameobject template %u is missing; runs will lack chests or portals, and give shards without a drop.", entry);

    for (uint32 entry : { BONK_ORB_SMALL, BONK_ORB_LARGE, BONK_ORB_HUGE, BONK_ORB_GRAND })
        if (!sObjectMgr.GetCreatureTemplate(entry))
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Vanilla Bonk: creature template %u is missing; kills will give experience directly.", entry);

    if (!sObjectMgr.GetCreatureTemplate(BONK_SANGUINE_POOL))
        sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Vanilla Bonk: creature template %u is missing; Sanguine pools will heal without a look.", BONK_SANGUINE_POOL);

    BonkCoop::DeleteGuestAccounts();
}

void BonkMgr::LoadTiers()
{
    m_tiers.clear();

    std::unique_ptr<QueryResult> result(WorldDatabase.Query(
        "SELECT `id`, `key`, `name`, `health_multiplier`, `damage_multiplier`, `stage_health_growth`, `stage_damage_growth`, "
        "`stage_health_accel`, `chest_cost`, `chest_cost_growth`, `unlock_tier`, "
        "`shard_chance_normal`, `shard_chance_elite`, `shards_miniboss`, `shards_boss`, `description`, `art`, "
        "`mastery_xp_minute`, `mastery_xp_miniboss`, `mastery_xp_boss`, `elite_affixes`, "
        "`stage_damage_accel`, `min_alive_multiplier`, `max_alive`, `max_bruisers`, `first_elite_sec`, `charge_interval_ms`, `stages`, `finale`, `veteran_chance`, `chest_cost_minute_growth`, `details`, `opening_crowd`, `opening_sec`, "
        "`levels`, `level_health_growth`, `level_damage_growth`, `boss_health_multiplier`, `miniboss_health_multiplier`, `miniboss_damage_multiplier`, `all_zones` FROM `bonk_tier`"));

    if (!result)
    {
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded 0 Bonk tiers. Table `bonk_tier` is empty or missing.");
        return;
    }

    do
    {
        Field* fields = result->Fetch();

        BonkTier tier;
        tier.id = fields[0].GetUInt32();
        tier.key = fields[1].GetCppString();
        tier.name = fields[2].GetCppString();
        tier.healthMultiplier = fields[3].GetFloat();
        tier.damageMultiplier = fields[4].GetFloat();
        tier.stageHealthGrowth = fields[5].GetFloat();
        tier.stageDamageGrowth = fields[6].GetFloat();
        tier.stageHealthAccel = fields[7].GetFloat();
        tier.chestCost = fields[8].GetUInt32();
        tier.chestCostGrowth = fields[9].GetFloat();
        tier.unlockTierId = fields[10].GetUInt32();
        tier.shardChanceNormal = fields[11].GetFloat();
        tier.shardChanceElite = fields[12].GetFloat();
        tier.shardsMiniboss = fields[13].GetUInt32();
        tier.shardsBoss = fields[14].GetUInt32();
        tier.description = fields[15].GetCppString();
        tier.art = fields[16].GetCppString();
        tier.masteryXpMinute = fields[17].GetUInt32();
        tier.masteryXpMiniboss = fields[18].GetUInt32();
        tier.masteryXpBoss = fields[19].GetUInt32();
        tier.eliteAffixes = fields[20].GetUInt8();
        tier.stageDamageAccel = fields[21].GetFloat();
        tier.minAliveMultiplier = fields[22].GetFloat();
        tier.maxAlive = std::max(1u, fields[23].GetUInt32());
        tier.maxBruisers = fields[24].GetUInt32();
        tier.firstEliteSecond = fields[25].GetUInt32();
        tier.chargeIntervalMs = fields[26].GetUInt32();
        tier.stages = std::max(1u, fields[27].GetUInt32());
        tier.finale = fields[28].GetUInt8() != 0;
        tier.veteranChance = fields[29].GetFloat();
        tier.chestCostMinuteGrowth = fields[30].GetFloat();
        tier.details = fields[31].GetCppString();
        tier.openingCrowd = std::min(1.0f, std::max(0.0f, fields[32].GetFloat()));
        tier.openingMs = fields[33].GetUInt32() * IN_MILLISECONDS;
        tier.levels = fields[34].GetUInt32();
        tier.levelHealthGrowth = std::max(1.0f, fields[35].GetFloat());
        tier.levelDamageGrowth = std::max(1.0f, fields[36].GetFloat());
        tier.bossHealthMultiplier = std::max(1.0f, fields[37].GetFloat());
        tier.minibossHealthMultiplier = std::max(1.0f, fields[38].GetFloat());
        tier.minibossDamageMultiplier = std::max(0.1f, fields[39].GetFloat());
        tier.allZones = fields[40].GetUInt8() != 0;

        m_tiers[tier.id] = std::move(tier);
    } while (result->NextRow());

    for (auto& itr : m_tiers)
    {
        BonkTier& tier = itr.second;
        if (tier.unlockTierId && !m_tiers.count(tier.unlockTierId))
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_tier`: tier %u is unlocked by unknown tier %u; it is always open.", tier.id, tier.unlockTierId);
            tier.unlockTierId = 0;
        }
    }

    LoadLevels();
    OrderTiers();

    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk tiers", uint32(m_tiers.size()));
}

void BonkMgr::LoadLevels()
{
    std::unique_ptr<QueryResult> result(WorldDatabase.Query(
        "SELECT `tier`, `level`, `health`, `damage`, `extra_affixes`, `veteran_chance`, `reward`, `green_chance`, `blue_chance`, `epic_chance`, "
        "`legendary_chance`, `roll_floor`, `boss_health`, `boss_damage` FROM `bonk_level` ORDER BY `tier`, `level`"));
    if (!result)
    {
        sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_level` is empty or missing; every level plays as level 1.");
        return;
    }

    do
    {
        Field* fields = result->Fetch();
        auto tier = m_tiers.find(fields[0].GetUInt32());
        if (tier == m_tiers.end())
            continue;

        BonkLevel level;
        level.level = std::max(1u, fields[1].GetUInt32());
        level.health = std::max(0.01f, fields[2].GetFloat());
        level.damage = std::max(0.01f, fields[3].GetFloat());
        level.extraAffixes = fields[4].GetUInt8();
        level.veteranChance = fields[5].GetFloat();
        level.reward = std::max(0.0f, fields[6].GetFloat());
        level.greenChance = fields[7].GetFloat();
        level.blueChance = fields[8].GetFloat();
        level.epicChance = fields[9].GetFloat();
        level.legendaryChance = fields[10].GetFloat();
        level.rollFloor = std::min(1.0f, std::max(0.0f, fields[11].GetFloat()));
        level.bossHealth = std::max(0.1f, fields[12].GetFloat());
        level.bossDamage = std::max(0.1f, fields[13].GetFloat());
        tier->second.levelRows.push_back(level);
    } while (result->NextRow());
}

void BonkMgr::OrderTiers()
{
    m_tiersInOrder.clear();
    std::set<uint32> placed;
    for (bool added = true; added;)
    {
        added = false;
        for (auto const& itr : m_tiers)
        {
            BonkTier const& tier = itr.second;
            if (placed.count(tier.id) || (tier.unlockTierId && !placed.count(tier.unlockTierId)))
                continue;
            m_tiersInOrder.push_back(&tier);
            placed.insert(tier.id);
            added = true;
        }
    }
    for (auto const& itr : m_tiers)
        if (!placed.count(itr.first))
            m_tiersInOrder.push_back(&itr.second);

    uint32 next = 1;
    for (BonkTier const* ordered : m_tiersInOrder)
    {
        BonkTier& tier = m_tiers[ordered->id];
        tier.firstLevel = next;
        if (tier.IsEndlessLevels())
            break;
        next += tier.levels;
    }
}

BonkTier const* BonkMgr::GetLevelTier(uint32 level) const
{
    for (BonkTier const* tier : m_tiersInOrder)
        if (tier->HasLevel(level))
            return tier;
    return nullptr;
}

void BonkMgr::AddDropMilestones(BonkLevel& level, uint32 milestones)
{
    if (!milestones)
        return;
    level.epicChance = std::min(BONK_DROP_MAX_EPIC, level.epicChance + BONK_DROP_MILESTONE_EPIC * float(milestones));
    level.blueChance = std::max(0.0f, 100.0f - level.epicChance - level.greenChance);
    level.legendaryChance = std::min(BONK_DROP_MAX_LEGENDARY, level.legendaryChance + BONK_DROP_MILESTONE_LEGENDARY * float(milestones));
    level.reward += BONK_DROP_MILESTONE_REWARD * float(milestones);
}

BonkLevel BonkMgr::GetLevel(BonkTier const& tier, uint32 bandLevel) const
{
    BonkLevel scaled;
    for (BonkLevel const& row : tier.levelRows)
        if (row.level <= bandLevel)
            scaled = row;
    uint32 const past = bandLevel > scaled.level ? bandLevel - scaled.level : 0;
    scaled.health *= std::pow(tier.levelHealthGrowth, float(past));
    scaled.damage *= std::pow(tier.levelDamageGrowth, float(past));
    AddDropMilestones(scaled, bandLevel / BONK_DROP_MILESTONE_LEVELS - scaled.level / BONK_DROP_MILESTONE_LEVELS);
    scaled.level = bandLevel;
    return scaled;
}

void BonkMgr::LoadMaps()
{
    m_maps.clear();
    m_arenaZonesByMap.clear();

    std::unique_ptr<QueryResult> result(WorldDatabase.Query(
        "SELECT `id`, `key`, `name`, `tier`, `map_id`, `zone_id`, `position_x`, `position_y`, `position_z`, `orientation`, "
        "`duration_sec`, `level_offset`, `health_multiplier`, `damage_multiplier`, `health_growth_per_min`, "
        "`gold_per_kill`, `stage_gold`, `coins_per_kill`, `powerup_interval_sec`, `powerup_max`, "
        "`spawn_min_distance`, `spawn_max_distance`, `icon`, `damage_growth_per_min`, `map_type`, `summary`, `description` FROM `bonk_map`"));

    if (!result)
    {
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded 0 Bonk maps. Table `bonk_map` is empty or missing.");
        return;
    }

    do
    {
        Field* fields = result->Fetch();

        BonkMap map;
        map.id = fields[0].GetUInt32();
        map.key = fields[1].GetCppString();
        map.name = fields[2].GetCppString();
        map.tierId = fields[3].GetUInt32();
        map.mapId = fields[4].GetUInt32();
        map.zoneId = fields[5].GetUInt32();
        map.x = fields[6].GetFloat();
        map.y = fields[7].GetFloat();
        map.z = fields[8].GetFloat();
        map.o = fields[9].GetFloat();
        map.durationSeconds = fields[10].GetUInt32();
        map.levelOffset = fields[11].GetInt32();
        map.healthMultiplier = fields[12].GetFloat();
        map.damageMultiplier = fields[13].GetFloat();
        map.healthGrowthPerMinute = fields[14].GetFloat();
        map.goldPerKill = fields[15].GetUInt32();
        map.stageGold = fields[16].GetUInt32();
        map.coinsPerKill = fields[17].GetUInt32();
        map.powerupIntervalSeconds = fields[18].GetUInt32();
        map.powerupMax = fields[19].GetUInt32();
        map.spawnMinDistance = std::max(5.0f, fields[20].GetFloat());
        map.spawnMaxDistance = std::max(map.spawnMinDistance, fields[21].GetFloat());
        map.icon = fields[22].GetCppString();
        map.damageGrowthPerMinute = fields[23].GetFloat();
        map.type = BonkMapType(std::min<uint8>(fields[24].GetUInt8(), MAX_BONK_MAP_TYPE - 1));
        map.summary = fields[25].GetCppString();
        map.description = fields[26].GetCppString();

        if (!sMapStorage.LookupEntry<MapEntry>(map.mapId))
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_map`: map %u (%s) does not exist, skipped.", map.mapId, map.name.c_str());
            continue;
        }

        auto tier = m_tiers.find(map.tierId);
        if (tier != m_tiers.end())
            tier->second.mapIds.push_back(map.id);
        else if (map.tierId)
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_map`: map %u (%s) belongs to unknown tier %u; no run will use it.", map.id, map.name.c_str(), map.tierId);

        m_arenaZonesByMap[map.mapId].insert(map.zoneId);
        m_maps[map.id] = std::move(map);
    } while (result->NextRow());

    for (auto& itr : m_tiers)
        if (itr.second.allZones)
            AddOtherTierZones(itr.second);

    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk maps", uint32(m_maps.size()));
}

void BonkMgr::AddOtherTierZones(BonkTier& tier)
{
    for (BonkTier const* other : m_tiersInOrder)
    {
        if (other->id == tier.id)
            continue;
        for (auto const& itr : m_maps)
            if (itr.second.tierId == other->id)
                tier.mapIds.push_back(itr.first);
    }
}

void BonkMgr::LoadArchetypes()
{
    for (BonkArchetypeInfo& archetype : m_archetypes)
        archetype = BonkArchetypeInfo();

    std::unique_ptr<QueryResult> result(WorldDatabase.Query(
        "SELECT `id`, `name`, `health_multiplier`, `damage_multiplier`, `experience`, `first_sec`, `first_sec_later`, `orb`, `threat` FROM `bonk_archetype`"));
    uint32 count = 0;
    if (result)
    {
        do
        {
            Field* fields = result->Fetch();
            uint8 const id = fields[0].GetUInt8();
            if (id >= MAX_BONK_ARCHETYPE)
            {
                sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_archetype`: unknown archetype %u, skipped.", id);
                continue;
            }

            BonkArchetypeInfo& archetype = m_archetypes[id];
            archetype.name = fields[1].GetCppString();
            archetype.healthMultiplier = fields[2].GetFloat();
            archetype.damageMultiplier = fields[3].GetFloat();
            archetype.experience = fields[4].GetFloat();
            archetype.firstSecond = fields[5].GetUInt32();
            archetype.firstSecondLater = fields[6].GetUInt32();
            archetype.orb = BonkOrb(std::min<uint8>(fields[7].GetUInt8(), BONK_ORB_RED));
            archetype.threat = std::max(0.1f, fields[8].GetFloat());
            ++count;
        } while (result->NextRow());
    }

    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk enemy archetypes", count);
}

void BonkMgr::LoadWaves()
{
    m_waves.clear();

    std::unique_ptr<QueryResult> result(WorldDatabase.Query(
        "SELECT `start_sec`, `name`, `beat`, `swarmer`, `grunt`, `bruiser`, `caster`, `charger`, `crowd_start`, `crowd_end`, "
        "`spawn_per_tick`, `max_bruisers`, `elite_interval_sec`, `elites`, `minibosses`, `mini_events` FROM `bonk_wave` ORDER BY `start_sec`"));
    if (result)
    {
        do
        {
            Field* fields = result->Fetch();
            BonkWave wave;
            wave.startSecond = fields[0].GetUInt32();
            wave.name = fields[1].GetCppString();
            uint8 const beat = fields[2].GetUInt8();
            wave.beat = beat < MAX_BONK_WAVE_BEAT ? BonkWaveBeat(beat) : BONK_BEAT_BUILD;
            for (uint8 archetype = 0; archetype < MAX_BONK_ARCHETYPE; ++archetype)
                wave.roster[archetype] = fields[3 + archetype].GetUInt32();
            wave.crowdStart = std::max(0.0f, fields[8].GetFloat());
            wave.crowdEnd = std::max(0.0f, fields[9].GetFloat());
            wave.spawnPerTick = fields[10].GetUInt32();
            wave.maxBruisers = fields[11].GetUInt32();
            wave.eliteIntervalSeconds = fields[12].GetUInt32();
            wave.elites = fields[13].GetUInt32();
            wave.minibosses = fields[14].GetUInt32();
            wave.miniEvents = fields[15].GetUInt32();
            if (std::all_of(std::begin(wave.roster), std::end(wave.roster), [](uint32 weight) { return weight == 0; }))
            {
                sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_wave`: block at %u s has an empty roster; grunts it is.", wave.startSecond);
                wave.roster[BONK_ARCHETYPE_GRUNT] = 1;
            }
            m_waves.push_back(wave);
        } while (result->NextRow());
    }

    if (m_waves.empty() || m_waves.front().startSecond != 0)
    {
        sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_wave` has no block at 0 s; runs start on a small crowd of grunts.");
        BonkWave wave;
        wave.name = "Grunts";
        wave.roster[BONK_ARCHETYPE_GRUNT] = 1;
        wave.crowdStart = wave.crowdEnd = 20.0f;
        wave.eliteIntervalSeconds = 90;
        m_waves.insert(m_waves.begin(), wave);
    }

    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk timeline blocks", uint32(m_waves.size()));
}

void BonkMgr::LoadScaling()
{
    m_scaling.clear();

    std::unique_ptr<QueryResult> result(WorldDatabase.Query("SELECT `minute`, `hit_share`, `health`, `health_normal` FROM `bonk_scaling` ORDER BY `minute`"));
    if (result)
    {
        do
        {
            Field* fields = result->Fetch();
            BonkScalingPoint point;
            point.minute = std::max(0.0f, fields[0].GetFloat());
            point.hitShare = std::max(0.0f, fields[1].GetFloat() / 100.0f);
            point.health = std::max(0.01f, fields[2].GetFloat());
            point.healthNormal = std::max(0.01f, fields[3].GetFloat());
            m_scaling.push_back(point);
        } while (result->NextRow());
    }

    if (m_scaling.empty())
    {
        sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_scaling` is empty; enemies hit for 5%% of the hero's health and never toughen.");
        BonkScalingPoint point;
        point.hitShare = 0.05f;
        m_scaling.push_back(point);
    }

    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk scaling points", uint32(m_scaling.size()));
}

void BonkMgr::LoadMapCreatures()
{
    std::unique_ptr<QueryResult> result(WorldDatabase.Query(
        "SELECT `bonk_map_id`, `entry`, `kind`, `min_sec`, `max_sec`, `weight`, `health_multiplier`, `damage_multiplier`, `speed`, `scale`, `max_alive`, "
        "`archetype`, `flyer` FROM `bonk_map_creature`"));

    if (!result)
    {
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded 0 Bonk map creatures.");
        return;
    }

    uint32 count = 0;
    do
    {
        Field* fields = result->Fetch();

        uint32 const bonkMapId = fields[0].GetUInt32();
        auto map = m_maps.find(bonkMapId);
        if (map == m_maps.end())
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_map_creature`: unknown bonk map %u, skipped.", bonkMapId);
            continue;
        }

        BonkMapCreature creature;
        creature.entry = fields[1].GetUInt32();
        uint8 const kind = fields[2].GetUInt8();
        creature.minSecond = fields[3].GetUInt32();
        creature.maxSecond = fields[4].GetUInt32();
        creature.weight = std::max(1u, fields[5].GetUInt32());
        creature.healthMultiplier = fields[6].GetFloat();
        creature.damageMultiplier = fields[7].GetFloat();
        creature.speed = fields[8].GetFloat();
        creature.scale = fields[9].GetFloat();
        creature.maxAlive = fields[10].GetUInt32();
        creature.flyer = fields[12].GetBool();
        uint8 const archetype = fields[11].GetUInt8();
        if (archetype < MAX_BONK_ARCHETYPE)
            creature.archetype = BonkArchetype(archetype);
        else
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_map_creature`: creature %u has unknown archetype %u; it is a grunt.", creature.entry, archetype);

        if (kind >= MAX_BONK_SPAWN_KIND)
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_map_creature`: creature %u has unknown kind %u, skipped.", creature.entry, kind);
            continue;
        }
        creature.kind = BonkSpawnKind(kind);

        if (!sObjectMgr.GetCreatureTemplate(creature.entry))
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_map_creature`: creature %u does not exist, skipped.", creature.entry);
            continue;
        }

        map->second.creatures.push_back(creature);
        ++count;
    } while (result->NextRow());

    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk map creatures", count);
}

void BonkMgr::LoadMapEvents()
{
    std::unique_ptr<QueryResult> result(WorldDatabase.Query(
        "SELECT `bonk_map_id`, `second`, `event`, `count` FROM `bonk_map_event` ORDER BY `second`"));

    if (!result)
    {
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded 0 Bonk map events.");
        return;
    }

    uint32 count = 0;
    do
    {
        Field* fields = result->Fetch();

        uint32 const bonkMapId = fields[0].GetUInt32();
        auto map = m_maps.find(bonkMapId);
        if (map == m_maps.end())
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_map_event`: unknown bonk map %u, skipped.", bonkMapId);
            continue;
        }

        BonkMapEvent event;
        event.second = fields[1].GetUInt32();
        uint8 const type = fields[2].GetUInt8();
        event.count = std::max(1u, fields[3].GetUInt32());

        if (type >= MAX_BONK_EVENT)
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_map_event`: map %u has unknown event %u, skipped.", bonkMapId, type);
            continue;
        }
        event.type = BonkEventType(type);
        if (event.type == BONK_EVENT_MINIBOSS && !map->second.minibossSecond)
            map->second.minibossSecond = event.second;

        map->second.events.push_back(event);
        ++count;
    } while (result->NextRow());

    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk map events", count);
}

void BonkMgr::LoadKeywords()
{
    m_keywords.clear();

    std::unique_ptr<QueryResult> result(WorldDatabase.Query(
        "SELECT `id`, `name`, `icon`, `spell_id`, `max_stacks`, `value_per_stack`, `tick_ms`, `duration_ms`, `spreads_on_death`, `description` FROM `bonk_keyword`"));
    if (!result)
    {
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded 0 Bonk keywords.");
        return;
    }

    do
    {
        Field* fields = result->Fetch();

        BonkKeywordInfo keyword;
        uint8 const id = fields[0].GetUInt8();
        keyword.id = BonkKeyword(id);
        keyword.name = fields[1].GetCppString();
        keyword.icon = fields[2].GetCppString();
        keyword.spellId = fields[3].GetUInt32();
        keyword.maxStacks = std::max<uint8>(1, fields[4].GetUInt8());
        keyword.valuePerStack = fields[5].GetFloat();
        keyword.tickMs = fields[6].GetUInt32();
        keyword.durationMs = fields[7].GetUInt32();
        keyword.spreadsOnDeath = fields[8].GetUInt8() != 0;
        keyword.description = fields[9].GetCppString();

        if (id == BONK_KEYWORD_NONE || id >= MAX_BONK_KEYWORD)
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_keyword`: unknown keyword %u, skipped.", uint32(id));
            continue;
        }
        SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(keyword.spellId);
        if (!spellInfo || !spellInfo->IsSpellAppliesAura((1 << EFFECT_INDEX_0) | (1 << EFFECT_INDEX_1) | (1 << EFFECT_INDEX_2)))
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_keyword`: keyword %u uses spell %u, which is missing or applies no aura; skipped.", uint32(id), keyword.spellId);
            continue;
        }
        if (keyword.IsDamageOverTime() && !keyword.tickMs)
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_keyword`: damage over time keyword %u has no tick_ms; it ticks every second.", uint32(id));
            keyword.tickMs = IN_MILLISECONDS;
        }
        m_keywords[id] = std::move(keyword);
    } while (result->NextRow());

    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk keywords", uint32(m_keywords.size()));
}

void BonkMgr::LoadProjectiles()
{
    m_projectiles.clear();

    std::unique_ptr<QueryResult> result(WorldDatabase.Query("SELECT `spell_id`, `display_id`, `speed`, `radius`, `scale` FROM `bonk_projectile`"));
    if (!result)
    {
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded 0 Bonk projectiles.");
        return;
    }

    do
    {
        Field* fields = result->Fetch();

        BonkProjectileInfo projectile;
        projectile.spellId = fields[0].GetUInt32();
        projectile.displayId = fields[1].GetUInt32();
        projectile.speed = fields[2].GetFloat();
        projectile.radius = std::max(0.1f, fields[3].GetFloat());
        projectile.scale = fields[4].GetFloat() > 0.0f ? fields[4].GetFloat() : 1.0f;

        if (!sSpellMgr.GetSpellEntry(projectile.spellId) || projectile.speed <= 0.0f)
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_projectile`: spell %u is missing or has no speed; skipped.", projectile.spellId);
            continue;
        }
        if (!sCreatureDisplayInfoStore.LookupEntry(projectile.displayId) ||
            !sCreatureDisplayInfoAddonStorage.LookupEntry<CreatureDisplayInfoAddon>(projectile.displayId))
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_projectile`: spell %u uses display %u, which the server's tables lack (build the client patch, tools/build-telegraphs.ps1); skipped.",
                projectile.spellId, projectile.displayId);
            continue;
        }
        m_projectiles[projectile.spellId] = projectile;
    } while (result->NextRow());

    if (!sObjectMgr.GetCreatureTemplate(BONK_PROJECTILE))
    {
        sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Vanilla Bonk: creature template %u is missing; spells land on their targets instead of flying.", BONK_PROJECTILE);
        m_projectiles.clear();
    }

    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk projectiles", uint32(m_projectiles.size()));
}

BonkProjectileInfo const* BonkMgr::GetProjectile(uint32 spellId) const
{
    auto itr = m_projectiles.find(spellId);
    return itr != m_projectiles.end() ? &itr->second : nullptr;
}

BonkKeywordInfo const* BonkMgr::GetKeyword(BonkKeyword id) const
{
    auto itr = m_keywords.find(uint8(id));
    return itr != m_keywords.end() ? &itr->second : nullptr;
}

BonkKeywordInfo const* BonkMgr::GetKeywordBySpell(uint32 spellId) const
{
    for (auto const& itr : m_keywords)
        if (itr.second.spellId == spellId)
            return &itr.second;
    return nullptr;
}

void BonkMgr::LoadWeapons()
{
    m_weapons.clear();

    std::unique_ptr<QueryResult> result(WorldDatabase.Query(
        "SELECT `id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`, "
        "`class_mask`, `starter_class_mask`, `evolves_from`, `heal_pct`, `duration_ms`, "
        "`chains`, `behavior`, `behavior_value`, `tick_ms`, `base_targets`, `alt_spell_id`, `alt_every`, `alt_damage`, `base_jumps`, `kill_below_pct`, `flags`, "
        "`applies`, `apply_stacks`, `uses`, `uses_pct`, `starter_option_mask`, `spec`, `radius` "
        "FROM `bonk_weapon`"));

    if (!result)
    {
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded 0 Bonk weapons.");
        return;
    }

    do
    {
        Field* fields = result->Fetch();

        BonkWeapon weapon;
        weapon.id = fields[0].GetUInt32();
        weapon.name = fields[1].GetCppString();
        weapon.icon = fields[2].GetCppString();
        weapon.description = fields[3].GetCppString();
        weapon.spellId = fields[4].GetUInt32();
        weapon.target = BonkWeaponTarget(std::min<uint8>(fields[5].GetUInt8(), MAX_BONK_TARGET - 1));
        weapon.cooldownMs = std::max(200u, fields[6].GetUInt32());
        weapon.range = fields[7].GetFloat();
        weapon.damageFraction = fields[8].GetFloat();
        weapon.classMask = fields[9].GetUInt32();
        weapon.starterClassMask = fields[10].GetUInt32();
        weapon.evolvesFrom = fields[11].GetUInt32();
        weapon.healPct = fields[12].GetFloat();
        weapon.durationMs = fields[13].GetUInt32();
        weapon.chains = fields[14].GetUInt8() != 0;
        weapon.behavior = BonkWeaponBehavior(std::min<uint8>(fields[15].GetUInt8(), MAX_BONK_BEHAVIOR - 1));
        weapon.behaviorValue = fields[16].GetFloat();
        weapon.tickMs = fields[17].GetUInt32();
        weapon.baseTargets = std::max<uint8>(1, fields[18].GetUInt8());
        weapon.altSpellId = fields[19].GetUInt32();
        weapon.altEvery = fields[20].GetUInt8();
        weapon.altDamage = fields[21].GetFloat();
        weapon.baseJumps = fields[22].GetUInt8();
        weapon.killBelowPct = fields[23].GetFloat();
        weapon.flags = fields[24].GetUInt32();
        weapon.applies = BonkKeyword(fields[25].GetUInt8());
        weapon.applyStacks = fields[26].GetUInt8();
        weapon.uses = BonkKeyword(fields[27].GetUInt8());
        weapon.usesPct = fields[28].GetFloat();
        weapon.starterOptionMask = fields[29].GetUInt32();
        weapon.spec = fields[30].GetUInt32();
        weapon.radius = std::max(0.0f, fields[31].GetFloat());

        if (weapon.applies != BONK_KEYWORD_NONE && !GetKeyword(weapon.applies))
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_weapon`: weapon %u applies unknown keyword %u; it applies none.", weapon.id, uint32(weapon.applies));
            weapon.applies = BONK_KEYWORD_NONE;
        }
        if (weapon.uses != BONK_KEYWORD_NONE && weapon.uses != BONK_KEYWORD_VARIETY && !GetKeyword(weapon.uses))
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_weapon`: weapon %u pays off unknown keyword %u; it pays off none.", weapon.id, uint32(weapon.uses));
            weapon.uses = BONK_KEYWORD_NONE;
        }
        if (weapon.HasFlag(BONK_WEAPON_FLAG_CONSUME))
        {
            BonkKeywordInfo const* consumed = GetKeyword(weapon.uses);
            if (!consumed || !consumed->IsDamageOverTime())
            {
                sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_weapon`: weapon %u consumes keyword %u, which deals no damage over time; it consumes nothing.",
                    weapon.id, uint32(weapon.uses));
                weapon.flags &= ~uint32(BONK_WEAPON_FLAG_CONSUME);
            }
        }

        if (weapon.altSpellId && !sSpellMgr.GetSpellEntry(weapon.altSpellId))
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_weapon`: weapon %u has unknown alt spell %u; it is left out.", weapon.id, weapon.altSpellId);
            weapon.altSpellId = 0;
        }

        SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(weapon.spellId);
        if (!spellInfo)
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_weapon`: weapon %u uses unknown spell %u, skipped.", weapon.id, weapon.spellId);
            continue;
        }

        weapon.damageEffectIndex = FindDamageEffect(spellInfo);
        weapon.weaponDamage = weapon.damageEffectIndex < 0 && HasWeaponDamage(spellInfo);
        bool damageless = false;
        switch (weapon.behavior)
        {
            case BONK_BEHAVIOR_SHIELD:
            case BONK_BEHAVIOR_AEGIS:
            case BONK_BEHAVIOR_SPIKED_SHIELD:
            case BONK_BEHAVIOR_WARD:
            case BONK_BEHAVIOR_DEMORALIZE:
            case BONK_BEHAVIOR_BUFF:
            case BONK_BEHAVIOR_PET:
            case BONK_BEHAVIOR_WRATH:
                damageless = true;
                break;
            default:
                break;
        }
        if (weapon.applies != BONK_KEYWORD_NONE && weapon.damageEffectIndex < 0 && !weapon.weaponDamage)
            damageless = true;
        if (weapon.HasFlag(BONK_WEAPON_FLAG_NORMAL_ONLY) && weapon.damageEffectIndex < 0 && !weapon.weaponDamage)
            damageless = true;
        if (weapon.damageEffectIndex < 0 && !weapon.weaponDamage && !damageless)
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_weapon`: spell %u of weapon %u has no damage effect; it will use its own values.", weapon.spellId, weapon.id);

        weapon.tickEffectIndex = FindTickEffect(spellInfo, weapon.damageEffectIndex);
        if (weapon.HasFlag(BONK_WEAPON_FLAG_LOOK_ONLY))
        {
            weapon.damageEffectIndex = -1;
            weapon.tickEffectIndex = -1;
            weapon.weaponDamage = false;
        }
        for (uint32 i = 0; i < MAX_EFFECT_INDEX; ++i)
            if (spellInfo->Effect[i] == SPELL_EFFECT_PERSISTENT_AREA_AURA && spellInfo->EffectApplyAuraName[i] == SPELL_AURA_PERIODIC_DAMAGE)
            {
                weapon.groundRadius = Spells::GetSpellRadius(sSpellRadiusStore.LookupEntry(spellInfo->EffectRadiusIndex[i]));
                break;
            }
        if (weapon.behavior == BONK_BEHAVIOR_TRAP)
        {
            if (weapon.radius <= 0.0f)
            {
                sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_weapon`: trap %u has no radius; it uses its range.", weapon.id);
                weapon.radius = weapon.range;
            }
            weapon.groundRadius = weapon.radius;
            if (!sObjectMgr.GetGameObjectTemplate(uint32(weapon.behaviorValue)))
            {
                sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_weapon`: trap %u uses unknown gameobject %u; skipped.", weapon.id, uint32(weapon.behaviorValue));
                continue;
            }
        }
        if (weapon.target == BONK_TARGET_GROUND && weapon.groundRadius <= 0.0f && damageless)
            for (uint32 i = 0; i < MAX_EFFECT_INDEX; ++i)
                if (spellInfo->EffectRadiusIndex[i])
                {
                    weapon.groundRadius = Spells::GetSpellRadius(sSpellRadiusStore.LookupEntry(spellInfo->EffectRadiusIndex[i]));
                    break;
                }
        if (weapon.target == BONK_TARGET_GROUND && weapon.groundRadius <= 0.0f)
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_weapon`: ground weapon %u uses spell %u, which has no damaging ground effect; skipped.", weapon.id, weapon.spellId);
            continue;
        }
        SettleWeaponRadius(weapon, spellInfo);

        weapon.lasting = weapon.target == BONK_TARGET_GROUND || weapon.tickEffectIndex >= 0 || weapon.durationMs ||
            (weapon.damageEffectIndex >= 0 && spellInfo->EffectApplyAuraName[weapon.damageEffectIndex] == SPELL_AURA_PERIODIC_DAMAGE);

        m_weapons[weapon.id] = std::move(weapon);
    } while (result->NextRow());

    for (auto const& itr : m_weapons)
        if (itr.second.evolvesFrom && !m_weapons.count(itr.second.evolvesFrom))
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_weapon`: weapon %u evolves from unknown weapon %u.", itr.first, itr.second.evolvesFrom);

    uint32 upgrades = 0;
    std::unique_ptr<QueryResult> rows(WorldDatabase.Query("SELECT `weapon_id`, `upgrade`, `step` FROM `bonk_weapon_upgrade`"));
    if (rows)
    {
        do
        {
            Field* fields = rows->Fetch();
            uint32 const weaponId = fields[0].GetUInt32();
            uint8 const upgrade = fields[1].GetUInt8();
            float const step = fields[2].GetFloat();
            auto weapon = m_weapons.find(weaponId);
            if (weapon == m_weapons.end() || upgrade == BONK_SPELL_UPGRADE_NONE || upgrade == BONK_SPELL_UPGRADE_RETIRED || upgrade >= MAX_BONK_SPELL_UPGRADE || step <= 0.0f)
            {
                sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_weapon_upgrade`: weapon %u, upgrade %u, step %g is not valid; skipped.", weaponId, upgrade, step);
                continue;
            }
            if (upgrade == BONK_SPELL_UPGRADE_STACKS && weapon->second.applies == BONK_KEYWORD_NONE)
            {
                sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_weapon_upgrade`: weapon %u applies no keyword, so more stacks would do nothing; skipped.", weaponId);
                continue;
            }
            if ((upgrade == BONK_SPELL_UPGRADE_SLOWED && !weapon->second.HasFlag(BONK_WEAPON_FLAG_NORMAL_ONLY)) ||
                (upgrade == BONK_SPELL_UPGRADE_FRENZY && weapon->second.behavior != BONK_BEHAVIOR_WRATH) ||
                (upgrade == BONK_SPELL_UPGRADE_DEPLOY && (weapon->second.behavior != BONK_BEHAVIOR_TRAP || weapon->second.target != BONK_TARGET_SELF)) ||
                (upgrade == BONK_SPELL_UPGRADE_TRAP_AREA && (weapon->second.behavior != BONK_BEHAVIOR_TRAP || weapon->second.HasFlag(BONK_WEAPON_FLAG_SNAKES))))
            {
                sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_weapon_upgrade`: weapon %u neither slows, howls nor places traps, so upgrade %u would do nothing; skipped.", weaponId, upgrade);
                continue;
            }
            if (upgrade == BONK_SPELL_UPGRADE_ECHO && !weapon->second.HasFlag(BONK_WEAPON_FLAG_AOE))
            {
                sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_weapon_upgrade`: weapon %u is not an AoE spell, so Echo would do nothing (Count covers it); skipped.", weaponId);
                continue;
            }
            if (upgrade == BONK_SPELL_UPGRADE_REACH && !weapon->second.IsMeleeStrike())
            {
                sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_weapon_upgrade`: weapon %u is not a melee strike, so Reach would do nothing (Area covers AoE spells); skipped.", weaponId);
                continue;
            }
            if (upgrade == BONK_SPELL_UPGRADE_CLEAVE && weapon->second.target == BONK_TARGET_CONE)
            {
                sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_weapon_upgrade`: weapon %u fires a cone, which has no cleave splash, so upgrade %u would do nothing; skipped.", weaponId, upgrade);
                continue;
            }
            if ((upgrade == BONK_SPELL_UPGRADE_SHIELD_SIZE && !weapon->second.IsShieldBlock() && weapon->second.behavior != BONK_BEHAVIOR_WARD &&
                    weapon->second.behavior != BONK_BEHAVIOR_BULWARK && weapon->second.behavior != BONK_BEHAVIOR_ICE_BARRIER &&
                    weapon->second.behavior != BONK_BEHAVIOR_POWER_WORD_SHIELD) ||
                (upgrade == BONK_SPELL_UPGRADE_TRIGGER_COOLDOWN && !weapon->second.IsTrigger()))
            {
                sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_weapon_upgrade`: weapon %u neither shields you nor triggers, so upgrade %u would do nothing; skipped.", weaponId, upgrade);
                continue;
            }
            BonkWeaponUpgrade entry;
            entry.upgrade = BonkSpellUpgrade(upgrade);
            entry.step = step;
            weapon->second.upgrades.push_back(entry);
            ++upgrades;
        } while (rows->NextRow());
    }
    for (auto const& itr : m_weapons)
        if (itr.second.upgrades.empty())
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_weapon_upgrade`: weapon %u has no upgrades; its Rare and Epic ranks add damage only.", itr.first);

    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk weapons with %u upgrades", uint32(m_weapons.size()), upgrades);
}

std::string GetBonkMagicSchoolName(uint32 spellId, LocaleConstant locale)
{
    SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(spellId);
    switch (spellInfo ? spellInfo->School : SPELL_SCHOOL_NORMAL)
    {
        case SPELL_SCHOOL_HOLY:   return sBonkLocale.GetString(BONK_STRING_SCHOOL_HOLY, locale);
        case SPELL_SCHOOL_FIRE:   return sBonkLocale.GetString(BONK_STRING_SCHOOL_FIRE, locale);
        case SPELL_SCHOOL_NATURE: return sBonkLocale.GetString(BONK_STRING_SCHOOL_NATURE, locale);
        case SPELL_SCHOOL_FROST:  return sBonkLocale.GetString(BONK_STRING_SCHOOL_FROST, locale);
        case SPELL_SCHOOL_SHADOW: return sBonkLocale.GetString(BONK_STRING_SCHOOL_SHADOW, locale);
        case SPELL_SCHOOL_ARCANE: return sBonkLocale.GetString(BONK_STRING_SCHOOL_ARCANE, locale);
        default:                  return "";
    }
}

BonkString GetBonkClassName(uint32 classId)
{
    switch (classId)
    {
        case CLASS_WARRIOR: return BONK_STRING_CLASS_WARRIOR;
        case CLASS_PALADIN: return BONK_STRING_CLASS_PALADIN;
        case CLASS_HUNTER:  return BONK_STRING_CLASS_HUNTER;
        case CLASS_ROGUE:   return BONK_STRING_CLASS_ROGUE;
        case CLASS_PRIEST:  return BONK_STRING_CLASS_PRIEST;
        case CLASS_SHAMAN:  return BONK_STRING_CLASS_SHAMAN;
        case CLASS_MAGE:    return BONK_STRING_CLASS_MAGE;
        case CLASS_WARLOCK: return BONK_STRING_CLASS_WARLOCK;
        case CLASS_DRUID:   return BONK_STRING_CLASS_DRUID;
        default:            return BONK_STRING_CLASS_HERO;
    }
}

std::string DescribeBonkWeaponTags(BonkWeapon const& weapon, std::string const& school, LocaleConstant locale)
{
    BonkMasteryTree const* tree = sBonkMastery.GetTree(BonkMastery::GetSpec(weapon.id));
    std::string spec = tree ? sBonkLocale.Localize(BONK_FIELD_MASTERY_TREE_NAME, tree->id, tree->name, locale) : "";
    if (spec.empty() && weapon.behavior == BONK_BEHAVIOR_PET)
        spec = "Pet";
    bool const aimed = weapon.target == BONK_TARGET_NEAREST || weapon.target == BONK_TARGET_RANDOM ||
        weapon.target == BONK_TARGET_STRONGEST || weapon.target == BONK_TARGET_FARTHEST;
    return school + "~" + spec + "~" + (weapon.HasFlag(BONK_WEAPON_FLAG_AOE) ? "1" : "0") + "~" + FormatScaled(weapon.radius) + "~" +
        FormatScaled(aimed ? weapon.range : 0.0f);
}

BonkString BonkWeapon::GetPetNoun(bool plural) const
{
    if (HasFlag(BONK_WEAPON_FLAG_TOTEM))
        return plural ? BONK_STRING_NOUN_TOTEMS : BONK_STRING_NOUN_TOTEM;
    if (classMask & (1 << (CLASS_SHAMAN - 1)))
        return plural ? BONK_STRING_NOUN_SPIRIT_WOLVES : BONK_STRING_NOUN_SPIRIT_WOLF;
    if (classMask & (1 << (CLASS_PRIEST - 1)))
        return plural ? BONK_STRING_NOUN_SHADOWFIENDS : BONK_STRING_NOUN_SHADOWFIEND;
    if (classMask & (1 << (CLASS_MAGE - 1)))
        return plural ? BONK_STRING_NOUN_ELEMENTALS : BONK_STRING_NOUN_ELEMENTAL;
    return plural ? BONK_STRING_NOUN_BEASTS : BONK_STRING_NOUN_BEAST;
}

BonkString BonkWeapon::GetTargetNoun(bool plural) const
{
    if (behavior == BONK_BEHAVIOR_TRAP)
        return plural ? BONK_STRING_NOUN_TRAPS : BONK_STRING_NOUN_TRAP;
    if (behavior == BONK_BEHAVIOR_PET)
        return GetPetNoun(plural);
    if (behavior == BONK_BEHAVIOR_WRATH)
        return BONK_STRING_NOUN_WOLF;
    if (target == BONK_TARGET_GROUND)
        return plural ? BONK_STRING_NOUN_PACKS : BONK_STRING_NOUN_PACK;
    return plural ? BONK_STRING_NOUN_TARGETS : BONK_STRING_NOUN_TARGET;
}

std::string BonkWeapon::DescribeTargets(uint32 count, LocaleConstant locale) const
{
    std::string const number = std::to_string(count);
    bool const one = count == 1;
    if (behavior == BONK_BEHAVIOR_TRAP)
    {
        if (target == BONK_TARGET_GROUND)
            return sBonkLocale.GetString(one ? BONK_STRING_TARGETS_THROWS_TRAP : BONK_STRING_TARGETS_THROWS_TRAPS, locale, { number });
        return sBonkLocale.GetString(one ? BONK_STRING_TARGETS_PLACES_TRAP : BONK_STRING_TARGETS_PLACES_TRAPS, locale, { number });
    }
    if (behavior == BONK_BEHAVIOR_PET)
        return sBonkLocale.GetString(BONK_STRING_TARGETS_CALLS_UP_TO, locale, { number, sBonkLocale.GetString(GetPetNoun(!one), locale) });
    if (target == BONK_TARGET_GROUND)
        return sBonkLocale.GetString(one ? BONK_STRING_TARGETS_LANDS_ON_PACK : BONK_STRING_TARGETS_LANDS_ON_PACKS, locale, { number });
    return sBonkLocale.GetString(one ? BONK_STRING_TARGETS_UP_TO_ENEMY : BONK_STRING_TARGETS_UP_TO_ENEMIES, locale, { number });
}

std::string DescribeBonkSpellUpgrade(BonkWeapon const& weapon, BonkSpellUpgrade upgrade, float amount, LocaleConstant locale)
{
    char number[32];
    snprintf(number, sizeof(number), "%g", amount);
    std::string const percent = std::string("+") + number + "%";
    bool const one = amount == 1.0f;
    auto text = [locale](BonkString id, std::vector<std::string> const& args) { return sBonkLocale.GetString(id, locale, args); };
    switch (upgrade)
    {
        case BONK_SPELL_UPGRADE_CLEAVE:
            return percent + " " + text(BONK_STRING_UPGRADE_CLEAVE, { std::to_string(BONK_SPELL_CLEAVE_TARGETS) });
        case BONK_SPELL_UPGRADE_HIT_TWICE:  return percent + " " + text(BONK_STRING_UPGRADE_HIT_TWICE, {});
        case BONK_SPELL_UPGRADE_HASTE:      return percent + " " + text(BONK_STRING_UPGRADE_HASTE, {});
        case BONK_SPELL_UPGRADE_DURATION:
        {
            if (weapon.behavior == BONK_BEHAVIOR_ICE_PATH)
                return percent + " " + text(BONK_STRING_UPGRADE_ICE_DURATION, {});
            if (weapon.behavior == BONK_BEHAVIOR_TRAP && weapon.HasFlag(BONK_WEAPON_FLAG_SNAKES))
                return percent + " " + text(BONK_STRING_UPGRADE_SNAKE_DURATION, {});
            if (weapon.behavior == BONK_BEHAVIOR_TRAP)
            {
                SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(weapon.spellId);
                bool const frost = spellInfo && spellInfo->School == SPELL_SCHOOL_FROST;
                return percent + " " + text(frost ? BONK_STRING_UPGRADE_ICE_DURATION : BONK_STRING_UPGRADE_BURN_DURATION, {});
            }
            return percent + " " + text(BONK_STRING_UPGRADE_DURATION, {});
        }
        case BONK_SPELL_UPGRADE_DEPLOY:     return text(BONK_STRING_UPGRADE_DEPLOY, { number });
        case BONK_SPELL_UPGRADE_TRAP_AREA:  return percent + " " + text(BONK_STRING_UPGRADE_TRAP_AREA, {});
        case BONK_SPELL_UPGRADE_REACH:      return percent + " " + text(BONK_STRING_UPGRADE_REACH, {});
        case BONK_SPELL_UPGRADE_TARGETS:
            return text(one ? BONK_STRING_UPGRADE_TARGETS_ONE : BONK_STRING_UPGRADE_TARGETS, { number });
        case BONK_SPELL_UPGRADE_SHIELD_SIZE: return percent + " " + text(BONK_STRING_UPGRADE_SHIELD_SIZE, {});
        case BONK_SPELL_UPGRADE_TRIGGER_COOLDOWN: return std::string("-") + number + "% " + text(BONK_STRING_UPGRADE_TRIGGER_COOLDOWN, {});
        case BONK_SPELL_UPGRADE_ECHO:
            if (weapon.target == BONK_TARGET_GROUND)
                return text(one ? BONK_STRING_UPGRADE_ECHO_GROUPS_ONE : BONK_STRING_UPGRADE_ECHO_GROUPS, { number });
            return text(one ? BONK_STRING_UPGRADE_ECHO_ONE : BONK_STRING_UPGRADE_ECHO, { number });
        case BONK_SPELL_UPGRADE_MARK:       return percent + " " + text(BONK_STRING_UPGRADE_MARK, {});
        case BONK_SPELL_UPGRADE_PET_DAMAGE:
            return percent + " " + text(BONK_STRING_UPGRADE_PET_DAMAGE, { text(weapon.GetTargetNoun(true), {}) });
        case BONK_SPELL_UPGRADE_PET_SIZE:   return percent + " " + text(BONK_STRING_UPGRADE_PET_SIZE, { text(weapon.GetTargetNoun(false), {}) });
        case BONK_SPELL_UPGRADE_SLOWED:     return percent + " " + text(BONK_STRING_UPGRADE_SLOWED, {});
        case BONK_SPELL_UPGRADE_FRENZY:     return percent + " " + text(BONK_STRING_UPGRADE_FRENZY, {});
        case BONK_SPELL_UPGRADE_STACKS:
        {
            BonkKeywordInfo const* keyword = sBonkMgr.GetKeyword(weapon.applies);
            std::string const effect = keyword ? sBonkLocale.Localize(BONK_FIELD_KEYWORD_NAME, uint32(keyword->id), keyword->name, locale) :
                text(BONK_STRING_UPGRADE_ITS_EFFECT, {});
            return text(one ? BONK_STRING_UPGRADE_STACKS_ONE : BONK_STRING_UPGRADE_STACKS, { number, effect });
        }
        default:                      return "";
    }
}

void BonkMgr::LoadMobs()
{
    m_mobs.clear();

    std::unique_ptr<QueryResult> result(WorldDatabase.Query("SELECT `entry`, `role`, `range` FROM `bonk_mob`"));
    if (result)
    {
        do
        {
            Field* fields = result->Fetch();
            BonkMob& mob = m_mobs[fields[0].GetUInt32()];
            mob.role = BonkMobRole(std::min<uint8>(fields[1].GetUInt8(), MAX_BONK_MOB_ROLE - 1));
            mob.range = fields[2].GetFloat();
        } while (result->NextRow());
    }

    uint32 abilities = 0;
    result = WorldDatabase.Query("SELECT `entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, "
        "`shape`, `count`, `size`, `below_health`, `comment`, `cast_kit`, `impact_kit` FROM `bonk_mob_ability` ORDER BY `entry`, `spell_id`");
    if (result)
    {
        do
        {
            Field* fields = result->Fetch();

            BonkMobAbility ability;
            uint32 const entry = fields[0].GetUInt32();
            ability.spellId = fields[1].GetUInt32();
            ability.target = fields[2].GetUInt8() ? BONK_ABILITY_SELF : BONK_ABILITY_PLAYER;
            ability.cooldownMs = std::max(500u, fields[3].GetUInt32());
            ability.firstMs = fields[4].GetUInt32();
            ability.minRange = fields[5].GetFloat();
            ability.maxRange = fields[6].GetFloat();
            ability.damage = fields[7].GetFloat();
            ability.shape = BonkAbilityShape(std::min<uint8>(fields[8].GetUInt8(), MAX_BONK_ABILITY_SHAPE - 1));
            ability.count = fields[9].GetUInt32();
            ability.size = fields[10].GetFloat();
            ability.belowHealth = fields[11].GetFloat();
            ability.label = fields[12].GetCppString();
            ability.castKit = fields[13].GetUInt32();
            ability.impactKit = fields[14].GetUInt32();

            SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(ability.spellId);
            if (!spellInfo)
            {
                sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_mob_ability`: creature %u uses unknown spell %u, skipped.", entry, ability.spellId);
                continue;
            }
            ability.damageEffectIndex = FindDamageEffect(spellInfo);

            m_mobs[entry].abilities.push_back(ability);
            ++abilities;
        } while (result->NextRow());
    }

    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk enemy types with %u abilities", uint32(m_mobs.size()), abilities);
}

void BonkMgr::LoadPassives()
{
    m_passives.clear();

    std::unique_ptr<QueryResult> result(WorldDatabase.Query(
        "SELECT `id`, `name`, `icon`, `description`, `effect`, `value_per_rank`, `max_rank`, `rare` FROM `bonk_passive`"));

    if (!result)
    {
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded 0 Bonk passives.");
        return;
    }

    do
    {
        Field* fields = result->Fetch();

        BonkPassive passive;
        passive.id = fields[0].GetUInt32();
        passive.name = fields[1].GetCppString();
        passive.icon = fields[2].GetCppString();
        passive.description = fields[3].GetCppString();
        uint8 const effect = fields[4].GetUInt8();
        passive.valuePerRank = fields[5].GetFloat();
        passive.maxRank = fields[6].GetUInt8();
        passive.rare = fields[7].GetBool();

        if (effect >= MAX_BONK_PASSIVE_EFFECT)
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_passive`: passive %u has unknown effect %u, skipped.", passive.id, effect);
            continue;
        }
        passive.effect = BonkPassiveEffect(effect);

        m_passives[passive.id] = std::move(passive);
    } while (result->NextRow());

    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk passives", uint32(m_passives.size()));
}

void BonkMgr::LoadPowerups()
{
    m_powerups.clear();

    std::unique_ptr<QueryResult> result(WorldDatabase.Query("SELECT `entry`, `spell_id`, `weight`, `effect`, `value` FROM `bonk_powerup`"));
    if (!result)
    {
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded 0 Bonk power-ups.");
        return;
    }

    do
    {
        Field* fields = result->Fetch();

        BonkPowerup powerup;
        powerup.entry = fields[0].GetUInt32();
        powerup.spellId = fields[1].GetUInt32();
        powerup.weight = std::max(1u, fields[2].GetUInt32());
        uint32 const effect = fields[3].GetUInt32();
        powerup.value = fields[4].GetFloat();
        if (effect >= MAX_BONK_POWERUP_EFFECT)
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_powerup`: power-up %u has unknown effect %u, skipped.", powerup.entry, effect);
            continue;
        }
        powerup.effect = BonkPowerupEffect(effect);

        if (!sObjectMgr.GetGameObjectTemplate(powerup.entry))
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_powerup`: gameobject %u does not exist, skipped.", powerup.entry);
            continue;
        }

        if ((powerup.spellId || powerup.effect == BONK_POWERUP_SPELL || powerup.effect == BONK_POWERUP_HOLY_NOVA) &&
            !sSpellMgr.GetSpellEntry(powerup.spellId))
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_powerup`: power-up %u uses unknown spell %u, skipped.", powerup.entry, powerup.spellId);
            continue;
        }

        m_powerups.push_back(powerup);
    } while (result->NextRow());

    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk power-ups", uint32(m_powerups.size()));
}

void BonkMgr::LoadCards()
{
    m_cards.clear();

    std::unique_ptr<QueryResult> result(WorldDatabase.Query(
        "SELECT `id`, `name`, `icon`, `description`, `rarity`, `stat1`, `stat1_value`, `stat2`, `stat2_value`, "
        "`effect`, `value1`, `value2`, `value3`, `cooldown_ms`, `max_copies`, `in_chests` FROM `bonk_card`"));
    if (!result)
    {
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded 0 Bonk cards.");
        return;
    }

    do
    {
        Field* fields = result->Fetch();

        BonkCard card;
        card.id = fields[0].GetUInt32();
        card.name = fields[1].GetCppString();
        card.icon = fields[2].GetCppString();
        card.description = fields[3].GetCppString();
        uint8 const rarity = fields[4].GetUInt8();
        uint8 const effect = fields[9].GetUInt8();
        if (rarity >= MAX_BONK_RARITY || effect >= MAX_BONK_CARD_EFFECT)
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_card`: card %u has rarity %u or effect %u out of range, skipped.", card.id, rarity, effect);
            continue;
        }
        card.rarity = BonkRarity(rarity);
        card.effect = BonkCardEffect(effect);
        for (uint8 i = 0; i < 2; ++i)
        {
            uint8 const stat = fields[5 + 2 * i].GetUInt8();
            card.stats[i] = stat < MAX_BONK_PASSIVE_EFFECT ? BonkPassiveEffect(stat) : MAX_BONK_PASSIVE_EFFECT;
            card.statValues[i] = fields[6 + 2 * i].GetFloat();
        }
        for (uint8 i = 0; i < 3; ++i)
            card.values[i] = fields[10 + i].GetFloat();
        card.cooldownMs = fields[13].GetUInt32();
        card.maxCopies = fields[14].GetUInt8();
        card.inChests = fields[15].GetUInt8() != 0;

        m_cards[card.id] = card;
    } while (result->NextRow());

    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk cards", uint32(m_cards.size()));
}

std::string FormatBonkMoney(uint32 copper, LocaleConstant locale)
{
    std::string text;
    if (uint32 const gold = copper / 10000)
        text += sBonkLocale.GetString(BONK_STRING_MONEY_GOLD, locale, { std::to_string(gold) });
    if (uint32 const silver = (copper / 100) % 100)
        text += (text.empty() ? "" : " ") + sBonkLocale.GetString(BONK_STRING_MONEY_SILVER, locale, { std::to_string(silver) });
    if (uint32 const rest = copper % 100)
        text += (text.empty() ? "" : " ") + sBonkLocale.GetString(BONK_STRING_MONEY_COPPER, locale, { std::to_string(rest) });
    return text.empty() ? sBonkLocale.GetString(BONK_STRING_MONEY_COPPER, locale, { "0" }) : text;
}

uint32 GetBonkMapRewardPercent(BonkMapType type)
{
    switch (type)
    {
        case BONK_MAP_ENCLOSED: return 125;
        case BONK_MAP_ARENA:    return 150;
        default:                return 100;
    }
}

std::string FormatBonkShards(uint32 count, LocaleConstant locale)
{
    return sBonkLocale.GetString(count == 1 ? BONK_STRING_TICKETS_ONE : BONK_STRING_TICKETS, locale, { std::to_string(count) });
}

std::string FormatBonkNumber(float value)
{
    char text[32];
    std::snprintf(text, sizeof(text), "%g", value);
    return text;
}

char const* GetBonkRarityName(BonkRarity rarity)
{
    switch (rarity)
    {
        case BONK_RARITY_UNCOMMON:  return "Uncommon";
        case BONK_RARITY_RARE:      return "Rare";
        case BONK_RARITY_EPIC:      return "Epic";
        case BONK_RARITY_LEGENDARY: return "Legendary";
        default:                    return "Common";
    }
}

BonkString GetBonkRarityString(BonkRarity rarity)
{
    switch (rarity)
    {
        case BONK_RARITY_UNCOMMON:  return BONK_STRING_RARITY_UNCOMMON;
        case BONK_RARITY_RARE:      return BONK_STRING_RARITY_RARE;
        case BONK_RARITY_EPIC:      return BONK_STRING_RARITY_EPIC;
        case BONK_RARITY_LEGENDARY: return BONK_STRING_RARITY_LEGENDARY;
        default:                    return BONK_STRING_RARITY_COMMON;
    }
}

uint32 BonkUpgrade::GetCost(uint8 ownedRanks) const
{
    uint32 const copper = uint32(cost * std::pow(costGrowth, float(ownedRanks)) + 0.5f);
    return copper >= 100 ? (copper + 50) / 100 * 100 : copper;
}

uint32 BonkTalent::GetCost(uint8 ownedRanks) const
{
    return uint32(cost * (1.0f + costGrowth * ownedRanks) + 0.5f);
}

void BonkMgr::LoadShopTrees()
{
    m_shopTrees.clear();

    std::unique_ptr<QueryResult> result(WorldDatabase.Query("SELECT `id`, `shop`, `name`, `background` FROM `bonk_shop_tree`"));
    if (!result)
    {
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded 0 Bonk shop trees.");
        return;
    }

    do
    {
        Field* fields = result->Fetch();

        BonkShopTree tree;
        tree.id = fields[0].GetUInt32();
        uint8 const shop = fields[1].GetUInt8();
        tree.name = fields[2].GetCppString();
        tree.background = fields[3].GetCppString();

        if (shop != BONK_SHOP_UPGRADES && shop != BONK_SHOP_TALENTS)
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_shop_tree`: tree %u has unknown shop %u, skipped.", tree.id, shop);
            continue;
        }
        tree.shop = BonkShop(shop);

        m_shopTrees[tree.id] = std::move(tree);
    } while (result->NextRow());

    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk shop trees", uint32(m_shopTrees.size()));
}

template <class Entry>
void BonkMgr::CheckShopLayout(char const* table, BonkShop shop, std::map<uint32, Entry>& entries) const
{
    std::set<std::tuple<uint32, uint8, uint8>> taken;
    for (auto& itr : entries)
    {
        Entry& entry = itr.second;
        BonkShopNode& node = entry.layout;
        if (!node.tree)
            continue;

        auto tree = m_shopTrees.find(node.tree);
        if (tree == m_shopTrees.end() || tree->second.shop != shop)
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `%s`: %u is in tree %u, which this shop doesn't have; it won't show in the trees.",
                table, entry.id, node.tree);
            node.tree = 0;
        }
        else if (node.row < 1 || node.row > BONK_SHOP_ROWS || node.column < 1 || node.column > BONK_SHOP_COLUMNS)
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `%s`: %u sits at row %u, column %u, outside the %ux%u tree; it won't show in the trees.",
                table, entry.id, node.row, node.column, BONK_SHOP_ROWS, BONK_SHOP_COLUMNS);
            node.tree = 0;
        }
        else if (!taken.insert(std::make_tuple(node.tree, node.row, node.column)).second)
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `%s`: %u shares row %u, column %u of tree %u with another entry.",
                table, entry.id, node.row, node.column, node.tree);

        if (!node.requiredId)
        {
            node.requiredRank = 0;
            continue;
        }

        auto required = entries.find(node.requiredId);
        if (required == entries.end() || node.requiredId == entry.id)
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `%s`: %u requires %u, which doesn't exist; requirement dropped.",
                table, entry.id, node.requiredId);
            node.requiredId = 0;
            node.requiredRank = 0;
            continue;
        }
        node.requiredRank = std::min(std::max<uint8>(1, node.requiredRank), required->second.maxRank);
    }
}

void BonkMgr::LoadUpgrades()
{
    m_upgrades.clear();

    std::unique_ptr<QueryResult> result(WorldDatabase.Query(
        "SELECT `id`, `name`, `description`, `effect`, `value_per_rank`, `max_rank`, `cost`, `cost_growth`, "
        "`icon`, `tree`, `tree_row`, `tree_column`, `required_id`, `required_rank`, `required_level` FROM `bonk_upgrade`"));
    if (!result)
    {
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded 0 Bonk upgrades.");
        return;
    }

    do
    {
        Field* fields = result->Fetch();

        BonkUpgrade upgrade;
        upgrade.id = fields[0].GetUInt32();
        upgrade.name = fields[1].GetCppString();
        upgrade.description = fields[2].GetCppString();
        uint8 const effect = fields[3].GetUInt8();
        upgrade.valuePerRank = fields[4].GetFloat();
        upgrade.maxRank = std::max<uint8>(1, fields[5].GetUInt8());
        upgrade.cost = fields[6].GetUInt32();
        upgrade.costGrowth = fields[7].GetFloat();
        upgrade.layout.icon = fields[8].GetCppString();
        upgrade.layout.tree = fields[9].GetUInt32();
        upgrade.layout.row = fields[10].GetUInt8();
        upgrade.layout.column = fields[11].GetUInt8();
        upgrade.layout.requiredId = fields[12].GetUInt32();
        upgrade.layout.requiredRank = fields[13].GetUInt8();
        upgrade.requiredLevel = fields[14].GetUInt32();

        if (effect >= BONK_UPGRADE_UTILITY_BASE && effect < BONK_UPGRADE_UTILITY_BASE + MAX_BONK_UPGRADE_UTILITY)
            upgrade.utility = int8(effect - BONK_UPGRADE_UTILITY_BASE);
        else if (effect < MAX_BONK_PASSIVE_EFFECT)
            upgrade.effect = BonkPassiveEffect(effect);
        else
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_upgrade`: upgrade %u has unknown effect %u, skipped.", upgrade.id, effect);
            continue;
        }

        m_upgrades[upgrade.id] = std::move(upgrade);
    } while (result->NextRow());

    CheckShopLayout("bonk_upgrade", BONK_SHOP_UPGRADES, m_upgrades);
    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk upgrades", uint32(m_upgrades.size()));
}

void BonkMgr::LoadTalents()
{
    m_talents.clear();

    std::unique_ptr<QueryResult> result(WorldDatabase.Query(
        "SELECT `id`, `name`, `description`, `effect`, `value_per_rank`, `gold_bonus`, `max_rank`, `cost`, `cost_growth`, "
        "`icon`, `tree`, `tree_row`, `tree_column`, `required_id`, `required_rank`, `rank_quests`, `rank_levels` FROM `bonk_talent`"));
    if (!result)
    {
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded 0 Bonk talents.");
        return;
    }

    do
    {
        Field* fields = result->Fetch();

        BonkTalent talent;
        talent.id = fields[0].GetUInt32();
        talent.name = fields[1].GetCppString();
        talent.description = fields[2].GetCppString();
        uint8 const effect = fields[3].GetUInt8();
        talent.valuePerRank = fields[4].GetFloat();
        talent.goldBonus = fields[5].GetFloat();
        talent.maxRank = std::max<uint8>(1, fields[6].GetUInt8());
        talent.cost = fields[7].GetUInt32();
        talent.costGrowth = fields[8].GetFloat();
        talent.layout.icon = fields[9].GetCppString();
        talent.layout.tree = fields[10].GetUInt32();
        talent.layout.row = fields[11].GetUInt8();
        talent.layout.column = fields[12].GetUInt8();
        talent.layout.requiredId = fields[13].GetUInt32();
        talent.layout.requiredRank = fields[14].GetUInt8();
        auto readGates = [](std::string const& gates, std::vector<uint32>& out)
        {
            for (size_t start = 0; start < gates.size();)
            {
                size_t const comma = gates.find(',', start);
                out.push_back(uint32(std::strtoul(gates.substr(start, comma - start).c_str(), nullptr, 10)));
                start = comma == std::string::npos ? gates.size() : comma + 1;
            }
        };
        readGates(fields[15].GetCppString(), talent.rankQuests);
        readGates(fields[16].GetCppString(), talent.rankLevels);

        if (effect >= MAX_BONK_TALENT_EFFECT)
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_talent`: talent %u has unknown effect %u, skipped.", talent.id, effect);
            continue;
        }
        talent.effect = BonkTalentEffect(effect);

        if (talent.IsToggle())
            talent.maxRank = 1;

        m_talents[talent.id] = std::move(talent);
    } while (result->NextRow());

    CheckShopLayout("bonk_talent", BONK_SHOP_TALENTS, m_talents);
    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk talents", uint32(m_talents.size()));
}

void BonkMgr::LoadItemStats()
{
    m_itemStats.clear();

    std::string columns;
    for (auto const& column : BONK_GEAR_COLUMNS)
        columns += ", `" + std::string(column.name) + "`";
    std::unique_ptr<QueryResult> result(WorldDatabase.Query(("SELECT `entry`" + columns + " FROM `bonk_item_stat` ORDER BY `entry`").c_str()));
    if (result)
    {
        do
        {
            Field* fields = result->Fetch();
            uint32 const entry = fields[0].GetUInt32();
            if (!sObjectMgr.GetItemPrototype(entry))
            {
                sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_item_stat`: item %u does not exist, skipped.", entry);
                continue;
            }

            BonkItemStat stat;
            for (size_t i = 0; i < BONK_GEAR_COLUMN_COUNT; ++i)
                stat.stats[BONK_GEAR_COLUMNS[i].effect] = fields[1 + i].GetFloat();
            m_itemStats[entry] = stat;
        } while (result->NextRow());
    }

    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk gear items", uint32(m_itemStats.size()));
}

BonkUpgrade const* BonkMgr::GetUpgrade(uint32 id) const
{
    auto itr = m_upgrades.find(id);
    return itr != m_upgrades.end() ? &itr->second : nullptr;
}

BonkTalent const* BonkMgr::GetTalent(uint32 id) const
{
    auto itr = m_talents.find(id);
    return itr != m_talents.end() ? &itr->second : nullptr;
}

BonkItemStat const* BonkMgr::GetItemStat(uint32 itemEntry) const
{
    auto itr = m_itemStats.find(itemEntry);
    return itr != m_itemStats.end() ? &itr->second : nullptr;
}

BonkGearTotals BonkMgr::EvaluateGear(Player const* player) const
{
    std::vector<uint32> worn;
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
        if (Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            worn.push_back(item->GetEntry());
    BonkGearTotals totals = EvaluateItems(worn);
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
        BonkFound::AddWornStats(player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot), totals.passives);
    return totals;
}

BonkGearTotals BonkMgr::EvaluateItems(std::vector<uint32> const& entries) const
{
    BonkGearTotals totals;
    for (uint32 entry : entries)
        if (BonkItemStat const* stat = GetItemStat(entry))
            for (uint8 effect = 0; effect < MAX_BONK_PASSIVE_EFFECT; ++effect)
                totals.passives[effect] += stat->stats[effect];
    return totals;
}

BonkTier const* BonkMgr::GetTier(uint32 id) const
{
    auto itr = m_tiers.find(id);
    return itr != m_tiers.end() ? &itr->second : nullptr;
}

BonkTier const* BonkMgr::FindTier(std::string const& keyOrId) const
{
    for (auto const& itr : m_tiers)
        if (itr.second.key == keyOrId || std::to_string(itr.first) == keyOrId)
            return &itr.second;
    return nullptr;
}

void BonkMgr::LoadZoneArt()
{
    m_zoneArt.clear();
    std::set<uint32> zones;
    for (auto const& itr : m_maps)
        if (itr.second.type == BONK_MAP_OPEN && itr.second.zoneId)
            zones.insert(itr.second.zoneId);

    std::string const dbcPath = sWorld.GetDataPath() + std::to_string(uint32(SUPPORTED_CLIENT_BUILD)) + "/dbc/";
    DBCFileLoader areas;
    if (!areas.Load((dbcPath + "WorldMapArea.dbc").c_str(), "niisffff"))
    {
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Bonk zone art skipped: WorldMapArea.dbc not found.");
        return;
    }

    std::map<uint32, uint32> zoneByArea;
    for (uint32 i = 0; i < areas.GetNumRows(); ++i)
    {
        DBCFileLoader::Record row = areas.getRecord(i);
        uint32 const zoneId = row.getUInt(2);
        if (!zones.count(zoneId))
            continue;
        BonkZoneArt& art = m_zoneArt[zoneId];
        art.file = row.getString(3);
        art.left = row.getFloat(4);
        art.right = row.getFloat(5);
        art.top = row.getFloat(6);
        art.bottom = row.getFloat(7);
        zoneByArea[row.getUInt(0)] = zoneId;
    }

    DBCFileLoader overlays;
    if (overlays.Load((dbcPath + "WorldMapOverlay.dbc").c_str(), "niiiiiiisiiiiiiii"))
        for (uint32 i = 0; i < overlays.GetNumRows(); ++i)
        {
            DBCFileLoader::Record row = overlays.getRecord(i);
            auto const zone = zoneByArea.find(row.getUInt(1));
            char const* texture = row.getString(8);
            if (zone == zoneByArea.end() || !texture || !*texture)
                continue;
            BonkZoneOverlay overlay;
            overlay.texture = texture;
            overlay.width = row.getUInt(9);
            overlay.height = row.getUInt(10);
            overlay.x = row.getUInt(11);
            overlay.y = row.getUInt(12);
            m_zoneArt[zone->second].overlays.push_back(overlay);
        }

    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded world map art for %u Bonk zones", uint32(m_zoneArt.size()));
}

BonkZoneArt const* BonkMgr::GetZoneArt(uint32 zoneId) const
{
    auto const itr = m_zoneArt.find(zoneId);
    return itr != m_zoneArt.end() ? &itr->second : nullptr;
}

std::vector<BonkMapStart> BonkMgr::GetMapStarts(uint32 bonkMapId) const
{
    std::lock_guard<std::mutex> guard(m_mapStartLock);
    auto itr = m_mapStarts.find(bonkMapId);
    return itr != m_mapStarts.end() ? itr->second : std::vector<BonkMapStart>();
}

bool BonkMgr::AddMapStart(uint32 bonkMapId, BonkMapStart const& start, float spread, size_t max)
{
    {
        std::lock_guard<std::mutex> guard(m_mapStartLock);
        std::vector<BonkMapStart>& starts = m_mapStarts[bonkMapId];
        if (starts.size() >= max)
            return false;
        for (BonkMapStart const& other : starts)
            if ((other.x - start.x) * (other.x - start.x) + (other.y - start.y) * (other.y - start.y) < spread * spread)
                return false;
        starts.push_back(start);
    }
    WorldDatabase.PExecute("INSERT INTO `bonk_map_start` (`map`, `x`, `y`, `z`) VALUES (%u, %f, %f, %f)", bonkMapId, start.x, start.y, start.z);
    return true;
}

BonkMap const* BonkMgr::FindDungeon(std::string const& key) const
{
    for (auto const& itr : m_maps)
        if (itr.second.type == BONK_MAP_ENCLOSED && itr.second.key == key && !itr.second.creatures.empty())
            return &itr.second;
    return nullptr;
}

BonkMap const* BonkMgr::FindTierMap(BonkTier const& tier, std::string const& key) const
{
    for (uint32 id : tier.mapIds)
        if (BonkMap const* map = GetMap(id))
            if (map->key == key && !map->creatures.empty())
                return map;
    return nullptr;
}

std::vector<BonkMap const*> BonkMgr::GetDungeons() const
{
    std::vector<BonkMap const*> dungeons;
    for (auto const& itr : m_maps)
        if (itr.second.type == BONK_MAP_ENCLOSED && !itr.second.creatures.empty())
            dungeons.push_back(&itr.second);
    return dungeons;
}

BonkMap const* BonkMgr::GetMap(uint32 id) const
{
    auto itr = m_maps.find(id);
    return itr != m_maps.end() ? &itr->second : nullptr;
}

BonkWeapon const* BonkMgr::GetWeapon(uint32 id) const
{
    auto itr = m_weapons.find(id);
    return itr != m_weapons.end() ? &itr->second : nullptr;
}

std::vector<BonkWeapon const*> BonkMgr::GetEvolutions(uint32 weaponId) const
{
    std::vector<BonkWeapon const*> evolutions;
    if (!weaponId)
        return evolutions;
    for (auto const& itr : m_weapons)
        if (itr.second.evolvesFrom == weaponId)
            evolutions.push_back(&itr.second);
    return evolutions;
}

bool BonkMgr::HasStarterSpell(uint32 classMask) const
{
    return std::any_of(m_weapons.begin(), m_weapons.end(), [classMask](std::pair<uint32 const, BonkWeapon> const& itr)
    {
        BonkWeapon const& weapon = itr.second;
        return (weapon.starterClassMask & classMask) || (!weapon.evolvesFrom && (!weapon.classMask || (weapon.classMask & classMask)));
    });
}

bool BonkMgr::HasPoisonSpell(uint32 classMask) const
{
    return std::any_of(m_weapons.begin(), m_weapons.end(), [classMask](std::pair<uint32 const, BonkWeapon> const& itr)
    {
        BonkWeapon const& weapon = itr.second;
        return (!weapon.classMask || (weapon.classMask & classMask)) && weapon.AppliesPoison();
    });
}

bool BonkMgr::HasKeywordSpell(uint32 classMask, BonkKeyword keyword) const
{
    if (keyword == BONK_KEYWORD_POISON)
        return HasPoisonSpell(classMask);
    return std::any_of(m_weapons.begin(), m_weapons.end(), [classMask, keyword](std::pair<uint32 const, BonkWeapon> const& itr)
    {
        BonkWeapon const& weapon = itr.second;
        return (!weapon.classMask || (weapon.classMask & classMask)) && weapon.applies == keyword;
    });
}

std::string BonkMgr::DescribeEvolutionAdds(BonkWeapon const& evolved, LocaleConstant locale) const
{
    std::string const description = sBonkLocale.Localize(BONK_FIELD_WEAPON_DESCRIPTION, evolved.id, evolved.description, locale);
    BonkWeapon const* base = GetWeapon(evolved.evolvesFrom);
    if (!base)
        return description;

    std::vector<std::string> const baseSentences = BonkLocale::SplitSentences(sBonkLocale.Localize(BONK_FIELD_WEAPON_DESCRIPTION, base->id, base->description, locale));
    std::vector<std::string> const sentences = BonkLocale::SplitSentences(description);
    size_t shared = 0;
    while (shared < baseSentences.size() && shared < sentences.size() && baseSentences[shared] == sentences[shared])
        ++shared;
    if (!shared || shared == sentences.size())
        return description;

    std::string adds;
    for (size_t i = shared; i < sentences.size(); ++i)
        adds += (adds.empty() ? "" : " ") + sentences[i];
    return adds;
}

std::string BonkMgr::DescribeEvolutionNames(uint32 weaponId, LocaleConstant locale) const
{
    std::vector<BonkWeapon const*> const evolutions = GetEvolutions(weaponId);
    std::vector<std::string> names;
    for (BonkWeapon const* evolved : evolutions)
        names.push_back(sBonkLocale.Localize(BONK_FIELD_WEAPON_NAME, evolved->id, evolved->name, locale));
    return sBonkLocale.JoinList(names, BONK_STRING_LIST_OR, locale);
}

BonkMob const* BonkMgr::GetMob(uint32 entry) const
{
    auto itr = m_mobs.find(entry);
    return itr != m_mobs.end() ? &itr->second : nullptr;
}

void BonkMgr::LoadBoltLooks()
{
    m_boltLooks.clear();

    std::unique_ptr<QueryResult> result(WorldDatabase.Query(
        "SELECT `spell_id`, `display_id`, `scale`, `impact_kit`, `cast_near` FROM `bonk_bolt_look`"));
    if (result)
    {
        do
        {
            Field* fields = result->Fetch();
            BonkBoltLook& look = m_boltLooks[fields[0].GetUInt32()];
            look.displayId = fields[1].GetUInt32();
            look.scale = fields[2].GetFloat();
            look.impactKit = fields[3].GetUInt32();
            look.castNear = fields[4].GetBool();
        } while (result->NextRow());
    }

    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk bolt looks", uint32(m_boltLooks.size()));
}

BonkBoltLook const* BonkMgr::GetBoltLook(uint32 spellId) const
{
    auto itr = m_boltLooks.find(spellId);
    return itr != m_boltLooks.end() ? &itr->second : nullptr;
}

BonkPassive const* BonkMgr::GetPassive(uint32 id) const
{
    auto itr = m_passives.find(id);
    return itr != m_passives.end() ? &itr->second : nullptr;
}

BonkCard const* BonkMgr::GetCard(uint32 id) const
{
    auto itr = m_cards.find(id);
    return itr != m_cards.end() ? &itr->second : nullptr;
}

void BonkMgr::LoadHiddenEncounters()
{
    m_hiddenEncounters.clear();

    std::unique_ptr<QueryResult> result(WorldDatabase.Query(
        "SELECT `id`, `name`, `map_id`, `chance`, `trigger`, `object_entry`, `boss_entry`, `boss_scale`, `add_entry`, `add_count`, "
        "`chest_choices`, `yell`, `found_text` FROM `bonk_hidden`"));
    if (!result)
    {
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded 0 Bonk hidden encounters");
        return;
    }

    do
    {
        Field* fields = result->Fetch();
        BonkHidden hidden;
        hidden.id = fields[0].GetUInt32();
        hidden.name = fields[1].GetCppString();
        hidden.mapId = fields[2].GetUInt32();
        hidden.chance = fields[3].GetFloat();
        hidden.trigger = fields[4].GetUInt8() ? BONK_HIDDEN_NEAR_TRIGGER : BONK_HIDDEN_USE_TRIGGER;
        hidden.objectEntry = fields[5].GetUInt32();
        hidden.bossEntry = fields[6].GetUInt32();
        hidden.bossScale = std::max(1.0f, fields[7].GetFloat());
        hidden.addEntry = fields[8].GetUInt32();
        hidden.addCount = fields[9].GetUInt32();
        hidden.chestChoices = std::max(1u, fields[10].GetUInt32());
        hidden.yell = fields[11].GetCppString();
        hidden.foundText = fields[12].GetCppString();
        if (!sObjectMgr.GetGameObjectTemplate(hidden.objectEntry) || !sObjectMgr.GetCreatureTemplate(hidden.bossEntry) ||
            (hidden.addEntry && !sObjectMgr.GetCreatureTemplate(hidden.addEntry)))
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_hidden`: encounter %u names a missing object or creature, skipped.", hidden.id);
            continue;
        }
        m_hiddenEncounters.push_back(hidden);
    } while (result->NextRow());

    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk hidden encounters", uint32(m_hiddenEncounters.size()));
}

void BonkMgr::LoadBossLines()
{
    m_bossLines.clear();

    std::unique_ptr<QueryResult> result(WorldDatabase.Query("SELECT `entry`, `line`, `sound_id` FROM `bonk_boss_line`"));
    if (!result)
    {
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded 0 Bonk boss lines");
        return;
    }

    uint32 count = 0;
    do
    {
        Field* fields = result->Fetch();
        uint32 const entry = fields[0].GetUInt32();
        uint8 const line = fields[1].GetUInt8();
        uint32 const soundId = fields[2].GetUInt32();
        if (line >= MAX_BONK_BOSS_LINE || !sObjectMgr.GetSoundEntry(soundId))
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_boss_line`: creature %u has line %u with sound %u that does not exist, skipped.", entry, line, soundId);
            continue;
        }
        m_bossLines[entry][line].push_back(soundId);
        ++count;
    } while (result->NextRow());

    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk boss lines", count);
}

uint32 BonkMgr::PickBossLineSound(uint32 entry, BonkBossLine line) const
{
    auto const itr = m_bossLines.find(entry);
    if (itr == m_bossLines.end() || itr->second[line].empty())
        return 0;
    std::vector<uint32> const& sounds = itr->second[line];
    return sounds[urand(0, uint32(sounds.size()) - 1)];
}

BonkGlyph const* BonkMgr::GetGlyph(uint32 id) const
{
    auto itr = m_glyphs.find(id);
    return itr != m_glyphs.end() ? &itr->second : nullptr;
}

void BonkMgr::LoadGlyphs()
{
    m_glyphs.clear();

    std::unique_ptr<QueryResult> result(WorldDatabase.Query(
        "SELECT `id`, `name`, `icon`, `description`, `drawback`, `rarity`, `effect`, `value1`, `value2`, `value3`, `card_id`, `starter` FROM `bonk_glyph`"));
    if (!result)
    {
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded 0 Bonk glyphs");
        return;
    }

    do
    {
        Field* fields = result->Fetch();
        BonkGlyph glyph;
        glyph.id = fields[0].GetUInt32();
        glyph.name = fields[1].GetCppString();
        glyph.icon = fields[2].GetCppString();
        glyph.description = fields[3].GetCppString();
        glyph.drawback = fields[4].GetCppString();
        uint32 const rarity = fields[5].GetUInt32();
        uint32 const effect = fields[6].GetUInt32();
        for (uint8 i = 0; i < 3; ++i)
            glyph.values[i] = fields[7 + i].GetFloat();
        glyph.cardId = fields[10].GetUInt32();
        glyph.starter = fields[11].GetBool();
        if (rarity >= MAX_BONK_RARITY || effect >= MAX_BONK_GLYPH_EFFECT)
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_glyph`: glyph %u has unknown rarity %u or effect %u, skipped.", glyph.id, rarity, effect);
            continue;
        }
        if (glyph.cardId && !GetCard(glyph.cardId))
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_glyph`: glyph %u gives missing card %u, skipped.", glyph.id, glyph.cardId);
            continue;
        }
        glyph.rarity = BonkRarity(rarity);
        glyph.effect = BonkGlyphEffect(effect);
        m_glyphs[glyph.id] = glyph;
    } while (result->NextRow());

    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk glyphs", uint32(m_glyphs.size()));
}

uint32 BonkMgr::GetItemCard(uint32 itemEntry) const
{
    auto itr = m_itemCards.find(itemEntry);
    return itr != m_itemCards.end() ? itr->second : 0;
}

void BonkMgr::LoadItemCards()
{
    m_itemCards.clear();

    std::unique_ptr<QueryResult> result(WorldDatabase.Query("SELECT `entry`, `card_id` FROM `bonk_item_card`"));
    if (!result)
    {
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded 0 Bonk item cards.");
        return;
    }

    do
    {
        Field* fields = result->Fetch();
        uint32 const entry = fields[0].GetUInt32();
        uint32 const cardId = fields[1].GetUInt32();
        if (!sObjectMgr.GetItemPrototype(entry) || !GetCard(cardId))
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_item_card`: item %u or card %u does not exist, skipped.", entry, cardId);
            continue;
        }
        m_itemCards[entry] = cardId;
    } while (result->NextRow());

    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk item cards", uint32(m_itemCards.size()));
}

uint32 BonkMgr::GetGearEntry(uint32 kind, uint8 quality, uint32 tier)
{
    if (kind >= BONK_GEAR_KINDS || quality < BONK_GEAR_LOWEST_QUALITY || quality >= BONK_GEAR_LOWEST_QUALITY + BONK_GEAR_QUALITIES ||
        !tier || tier > BONK_GEAR_TIERS)
        return 0;
    uint32 const entry = BONK_GEAR_FIRST + ((kind * BONK_GEAR_QUALITIES) + quality - BONK_GEAR_LOWEST_QUALITY) * BONK_GEAR_TIERS + tier - 1;
    return sObjectMgr.GetItemPrototype(entry) ? entry : 0;
}

bool BonkMgr::ReadGearEntry(uint32 entry, uint32& kind, uint8& quality, uint32& tier)
{
    if (entry < BONK_GEAR_FIRST || entry >= BONK_GEAR_FIRST + BONK_GEAR_KINDS * BONK_GEAR_QUALITIES * BONK_GEAR_TIERS)
        return false;
    uint32 const index = entry - BONK_GEAR_FIRST;
    tier = index % BONK_GEAR_TIERS + 1;
    quality = uint8(BONK_GEAR_LOWEST_QUALITY + (index / BONK_GEAR_TIERS) % BONK_GEAR_QUALITIES);
    kind = index / (BONK_GEAR_TIERS * BONK_GEAR_QUALITIES);
    return true;
}

std::vector<uint32> BonkMgr::GetGearKindsFor(uint32 classMask)
{
    std::vector<uint32> kinds;
    for (uint32 kind = 0; kind < BONK_GEAR_KINDS; ++kind)
        if (ItemPrototype const* proto = sObjectMgr.GetItemPrototype(GetGearEntry(kind, BONK_GEAR_LOWEST_QUALITY, 1)))
            if (proto->AllowableClass & classMask)
                kinds.push_back(kind);
    return kinds;
}

bool BonkMgr::ReadTrinketEffect(uint32 entry, BonkTrinketEffect& effect)
{
    uint32 kind, tier;
    uint8 quality;
    if (!ReadGearEntry(entry, kind, quality, tier) || kind < BONK_GEAR_FIRST_TRINKET)
        return false;
    effect = BonkTrinketEffect(kind - BONK_GEAR_FIRST_TRINKET);
    return effect < MAX_BONK_TRINKET_EFFECT;
}

uint32 BonkMgr::GetLegendaryEntry(uint32 kind, uint32 tier)
{
    if (kind >= BONK_LEGENDARY_KINDS || !tier || tier > BONK_GEAR_TIERS)
        return 0;
    uint32 const entry = BONK_LEGENDARY_FIRST + kind * BONK_GEAR_TIERS + tier - 1;
    return sObjectMgr.GetItemPrototype(entry) ? entry : 0;
}

bool BonkMgr::ReadLegendaryEntry(uint32 entry, uint32& kind, uint32& tier)
{
    if (entry < BONK_LEGENDARY_FIRST || entry >= BONK_LEGENDARY_FIRST + BONK_LEGENDARY_KINDS * BONK_GEAR_TIERS)
        return false;
    kind = (entry - BONK_LEGENDARY_FIRST) / BONK_GEAR_TIERS;
    tier = (entry - BONK_LEGENDARY_FIRST) % BONK_GEAR_TIERS + 1;
    return true;
}

std::vector<uint32> BonkMgr::GetLegendariesFor(uint32 classMask, uint32 tier)
{
    std::vector<uint32> legendaries;
    for (uint32 kind = 0; kind < BONK_LEGENDARY_KINDS; ++kind)
        if (uint32 const entry = GetLegendaryEntry(kind, tier))
            if (ItemPrototype const* proto = sObjectMgr.GetItemPrototype(entry))
                if (proto->AllowableClass & classMask)
                    legendaries.push_back(entry);
    return legendaries;
}

uint32 BonkMgr::GetGearTier(uint32 entry)
{
    uint32 kind, tier, band;
    uint8 quality;
    if (ReadGearEntry(entry, kind, quality, tier) || ReadLegendaryEntry(entry, kind, tier))
        return tier;
    if (ReadDungeonLookEntry(entry, band, kind, tier))
        return 1;
    return 0;
}

uint32 BonkMgr::PickMoltenCoreLook()
{
    RaidLooks const& moltenCore = BONK_EPIC_RAID_LOOKS[0];
    return urand(moltenCore.firstLook, moltenCore.lastLook);
}

int32 BonkMgr::GetDungeonLookBand(std::string const& mapKey)
{
    if (mapKey == BONK_ZUL_GURUB_KEY)
        return 0;
    if (mapKey == BONK_RUINS_OF_AHNQIRAJ_KEY)
        return 1;
    return -1;
}

uint32 BonkMgr::PickDungeonLookEntry(uint32 band, uint32 kind)
{
    std::vector<uint32> looks;
    for (uint32 look = 1; look <= BONK_DUNGEON_LOOKS; ++look)
    {
        uint32 const entry = BONK_DUNGEON_LOOK_FIRST + (band * BONK_GEAR_KINDS + kind) * BONK_DUNGEON_LOOKS + look - 1;
        if (sObjectMgr.GetItemPrototype(entry))
            looks.push_back(entry);
    }
    return looks.empty() ? 0 : looks[urand(0, uint32(looks.size() - 1))];
}

bool BonkMgr::ReadDungeonLookEntry(uint32 entry, uint32& band, uint32& kind, uint32& look)
{
    if (entry < BONK_DUNGEON_LOOK_FIRST || entry >= BONK_DUNGEON_LOOK_FIRST + BONK_DUNGEON_LOOK_BANDS * BONK_GEAR_KINDS * BONK_DUNGEON_LOOKS)
        return false;
    uint32 const index = entry - BONK_DUNGEON_LOOK_FIRST;
    look = index % BONK_DUNGEON_LOOKS + 1;
    kind = (index / BONK_DUNGEON_LOOKS) % BONK_GEAR_KINDS;
    band = index / (BONK_DUNGEON_LOOKS * BONK_GEAR_KINDS);
    return true;
}

uint32 BonkMgr::GetEpicLookMythic(uint32 look)
{
    for (RaidLooks const& raid : BONK_EPIC_RAID_LOOKS)
        if (look >= raid.firstLook && look <= raid.lastLook)
            return raid.openLevel - BONK_MYTHIC_LEVEL_OFFSET;
    return 1;
}

uint32 BonkMgr::PickGearLook(uint8 quality, uint32 tier)
{
    if (quality == ITEM_QUALITY_EPIC)
        return PickEpicLook(tier);
    return PickLookUpTo(1, BONK_GEAR_TIERS, tier);
}

float BonkPassive::RankWeight(uint32 rank) const
{
    if (!rank)
        return 0.0f;
    if (effect == BONK_PASSIVE_AMOUNT)
        return 1.0f;
    float const weight = std::pow(BONK_PASSIVE_RANK_DECAY, float(rank - 1));
    if (effect == BONK_PASSIVE_GROWTH)
        return weight;
    return std::max(BONK_PASSIVE_RANK_FLOOR, weight);
}

float BonkPassive::RankScale(uint32 rank) const
{
    float scale = 0.0f;
    for (uint32 step = 1; step <= rank; ++step)
        scale += RankWeight(step);
    return scale;
}

std::string BonkMgr::DescribePassive(BonkPassive const& passive, uint32 rank, LocaleConstant locale) const
{
    return ScalePassiveText(sBonkLocale.Localize(BONK_FIELD_PASSIVE_DESCRIPTION, passive.id, passive.description, locale), passive.RankScale(std::max(1u, rank)));
}

std::string BonkMgr::DescribePassiveRankUp(BonkPassive const& passive, uint32 rank, LocaleConstant locale) const
{
    if (rank <= 1)
        return DescribePassive(passive, 1, locale);
    return ScalePassiveText(sBonkLocale.Localize(BONK_FIELD_PASSIVE_DESCRIPTION, passive.id, passive.description, locale), passive.RankWeight(rank));
}

void BonkMgr::DescribePassiveStats(BonkPassive const& passive, uint32 rank, std::vector<BonkStatChange>& stats, LocaleConstant locale) const
{
    stats.clear();
    if (rank <= 1)
        return;
    std::vector<std::string> const before = GetScaledNumbers(passive.description, passive.RankScale(rank - 1));
    std::vector<std::string> const after = GetScaledNumbers(passive.description, passive.RankScale(rank));
    std::vector<std::string> shown;
    for (size_t i = 0; i < after.size() && i < before.size(); ++i)
    {
        if (std::find(shown.begin(), shown.end(), after[i]) != shown.end())
            continue;
        shown.push_back(after[i]);
        BonkString const label = GetPassiveStatLabel(BonkPassiveEffect(passive.effect), stats.size());
        if (!label)
            continue;
        stats.push_back({ sBonkLocale.GetString(label, locale), before[i], after[i] });
    }
}

std::string BonkMgr::DescribePassiveNow(BonkPassive const& passive, uint32 rank, LocaleConstant locale) const
{
    float scale = passive.RankScale(std::max(1u, rank));
    float const cap = BonkRun::GetPassiveCap(passive.effect);
    if (cap > 0.0f && passive.valuePerRank > 0.0f)
        scale = std::min(scale, cap / passive.valuePerRank);
    return ScalePassiveText(sBonkLocale.Localize(BONK_FIELD_PASSIVE_DESCRIPTION, passive.id, passive.description, locale), scale);
}

bool BonkMgr::IsStaticCreatureSuppressed(Map const* map, uint32 dbGuid) const
{
    auto itr = m_arenaZonesByMap.find(map->GetId());
    if (itr == m_arenaZonesByMap.end())
        return false;

    if (itr->second.count(0))
        return true;

    CreatureData const* data = sObjectMgr.GetCreatureData(dbGuid);
    if (!data)
        return false;

    uint32 const zoneId = map->GetTerrain()->GetZoneId(data->position.x, data->position.y, data->position.z);
    return itr->second.count(zoneId) != 0;
}

void BonkMgr::LoadPetFamilies()
{
    m_petFamilies.clear();

    std::unique_ptr<QueryResult> result(WorldDatabase.Query(
        "SELECT `id`, `name`, `entry`, `scale`, `attack_ms`, `applies`, `apply_stacks`, `description` FROM `bonk_pet_family`"));
    if (!result)
    {
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded 0 Bonk pet families. Table `bonk_pet_family` is empty or missing; Call Pet summons nothing.");
        return;
    }

    do
    {
        Field* fields = result->Fetch();

        BonkPetFamily family;
        family.id = fields[0].GetUInt32();
        family.name = fields[1].GetCppString();
        family.entry = fields[2].GetUInt32();
        family.scale = fields[3].GetFloat();
        family.attackMs = std::max(500u, fields[4].GetUInt32());
        uint8 const applies = fields[5].GetUInt8();
        family.applyStacks = fields[6].GetUInt8();
        family.description = fields[7].GetCppString();

        if (!sObjectMgr.GetCreatureTemplate(family.entry))
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_pet_family`: family %u uses creature %u, which is missing; skipped.", family.id, family.entry);
            continue;
        }
        if (family.scale <= 0.0f)
            family.scale = 1.0f;
        if (applies != BONK_KEYWORD_NONE && !GetKeyword(BonkKeyword(applies)))
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_pet_family`: family %u applies unknown keyword %u; it applies nothing.", family.id, uint32(applies));
            family.applyStacks = 0;
        }
        else
            family.applies = BonkKeyword(applies);
        m_petFamilies[family.id] = std::move(family);
    } while (result->NextRow());

    if (!m_petFamilies.count(BONK_PET_FAMILY_CAT))
        sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_pet_family`: the default family %u (Cat) is missing; Call Pet summons nothing.", BONK_PET_FAMILY_CAT);
    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk pet families", uint32(m_petFamilies.size()));

    LoadPetAbilities();
}

void BonkMgr::LoadPetAbilities()
{
    std::unique_ptr<QueryResult> result(WorldDatabase.Query(
        "SELECT `family`, `spell_id`, `kind`, `cooldown_ms`, `damage`, `stacks`, `value`, `kit` FROM `bonk_pet_ability`"));
    if (!result)
    {
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded 0 Bonk pet abilities: pets only bite.");
        return;
    }

    uint32 count = 0;
    do
    {
        Field* fields = result->Fetch();
        uint32 const familyId = fields[0].GetUInt32();
        BonkPetAbility ability;
        ability.spellId = fields[1].GetUInt32();
        uint8 const kind = fields[2].GetUInt8();
        ability.cooldownMs = fields[3].GetUInt32();
        ability.damage = std::max(0.0f, fields[4].GetFloat());
        ability.stacks = fields[5].GetUInt8();
        ability.value = fields[6].GetFloat();
        ability.kit = fields[7].GetUInt32();

        auto family = m_petFamilies.find(familyId);
        if (family == m_petFamilies.end() || kind >= MAX_BONK_PET_ABILITY_KIND || !sSpellMgr.GetSpellEntry(ability.spellId) || ability.cooldownMs < 500 ||
            ((kind == BONK_PET_ABILITY_PULSE || kind == BONK_PET_ABILITY_CONE) && ability.value <= 0.0f))
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_pet_ability`: family %u, spell %u, kind %u is not valid (unknown family, kind or spell, a cooldown under 500 ms, or a pulse without a radius); skipped.",
                familyId, ability.spellId, uint32(kind));
            continue;
        }
        ability.kind = BonkPetAbilityKind(kind);
        family->second.abilities.push_back(ability);
        ++count;
    } while (result->NextRow());

    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk pet abilities", count);
}

BonkPetFamily const* BonkMgr::GetPetFamily(uint32 id) const
{
    auto itr = m_petFamilies.find(id);
    return itr != m_petFamilies.end() ? &itr->second : nullptr;
}

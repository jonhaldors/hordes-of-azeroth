#include "BonkMastery.h"
#include "Database/DatabaseEnv.h"
#include "Log.h"
#include "Policies/SingletonImp.h"
#include "Util.h"

#include <algorithm>
#include <cstdlib>

INSTANTIATE_SINGLETON_1(BonkMastery);

namespace
{
    float const BONK_GLASS_CANNON_CRIT_DAMAGE  = 100.0f;
    float const BONK_GLASS_CANNON_HEALTH_COST  = 35.0f;
    float const BONK_SHADOWFORM_DECAY_DAMAGE   = 30.0f;
}

void BonkMastery::Load()
{
    m_trees.clear();
    m_nodes.clear();

    std::unique_ptr<QueryResult> result(WorldDatabase.Query("SELECT `id`, `class`, `name`, `background`, `order`, `layout` FROM `bonk_mastery_tree`"));
    if (result)
    {
        do
        {
            Field* fields = result->Fetch();
            BonkMasteryTree tree;
            tree.id = fields[0].GetUInt32();
            tree.classId = fields[1].GetUInt8();
            tree.name = fields[2].GetCppString();
            tree.background = fields[3].GetCppString();
            tree.order = fields[4].GetUInt8();
            tree.layout = fields[5].GetUInt8();
            m_trees[tree.id] = std::move(tree);
        } while (result->NextRow());
    }

    result = WorldDatabase.Query("SELECT `id`, `class`, `tree`, `row`, `column`, `icon`, `name`, `description`, `max_rank`, "
        "`required_id`, `required_rank`, `effect`, `target`, `value_per_rank`, `param`, `excludes`, `shape`, `position`, `parents` FROM `bonk_mastery`");
    if (result)
    {
        do
        {
            Field* fields = result->Fetch();
            BonkMasteryNode node;
            node.id = fields[0].GetUInt32();
            node.classId = fields[1].GetUInt8();
            node.tree = fields[2].GetUInt32();
            node.row = fields[3].GetUInt8();
            node.column = fields[4].GetUInt8();
            node.icon = fields[5].GetCppString();
            node.name = fields[6].GetCppString();
            node.description = fields[7].GetCppString();
            node.maxRank = std::max<uint8>(1, fields[8].GetUInt8());
            node.requiredId = fields[9].GetUInt32();
            node.requiredRank = fields[10].GetUInt8();
            uint8 const effect = fields[11].GetUInt8();
            node.target = fields[12].GetUInt32();
            node.valuePerRank = fields[13].GetFloat();
            node.param = fields[14].GetUInt32();
            node.excludes = fields[15].GetUInt32();
            node.shape = BonkMasteryShape(std::min<uint8>(fields[16].GetUInt8(), MAX_BONK_MASTERY_SHAPE - 1));
            node.position = fields[17].GetFloat();
            for (std::string const& parent : StrSplit(fields[18].GetCppString(), ","))
                if (uint32 parentId = uint32(std::strtoul(parent.c_str(), nullptr, 10)))
                    node.parents.push_back(parentId);

            auto tree = m_trees.find(node.tree);
            if (tree == m_trees.end() || tree->second.classId != node.classId)
            {
                sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_mastery`: node %u is in tree %u, which is missing or of another class; skipped.", node.id, node.tree);
                continue;
            }
            if (effect >= MAX_BONK_MASTERY_EFFECT)
            {
                sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_mastery`: node %u has unknown effect %u, skipped.", node.id, effect);
                continue;
            }
            node.effect = BonkMasteryEffect(effect);

            bool targetOk = true;
            switch (node.effect)
            {
                case BONK_MASTERY_PASSIVE:
                    targetOk = node.target < MAX_BONK_PASSIVE_EFFECT;
                    break;
                case BONK_MASTERY_SPELL_DAMAGE:
                case BONK_MASTERY_SPELL_COOLDOWN:
                case BONK_MASTERY_SPELL_TARGETS:
                case BONK_MASTERY_STARTER_UNLOCK:
                case BONK_MASTERY_SPELL_SLOW:
                case BONK_MASTERY_USES_BONUS:
                case BONK_MASTERY_SPELL_HEAL:
                case BONK_MASTERY_RESET_ON_KILL:
                case BONK_MASTERY_EXECUTE_THRESHOLD:
                case BONK_MASTERY_SPELL_STUN:
                case BONK_MASTERY_STRUCK_CAST:
                case BONK_MASTERY_ENTRAPMENT:
                case BONK_MASTERY_SPELL_STACKS:
                case BONK_MASTERY_SPELL_DURATION:
                case BONK_MASTERY_SPELL_REACH:
                case BONK_MASTERY_SPELL_BEHAVIOR:
                    targetOk = sBonkMgr.GetWeapon(node.target) != nullptr;
                    break;
                case BONK_MASTERY_SPELL_APPLIES:
                    targetOk = sBonkMgr.GetWeapon(node.target) != nullptr && sBonkMgr.GetKeyword(BonkKeyword(node.param)) != nullptr;
                    break;
                case BONK_MASTERY_SPEC_DAMAGE:
                case BONK_MASTERY_CAST_HASTE:
                    targetOk = m_trees.count(node.target) != 0;
                    break;
                case BONK_MASTERY_SPECIAL:
                    targetOk = node.target > BONK_SPECIAL_NONE && node.target < MAX_BONK_SPECIAL;
                    break;
                case BONK_MASTERY_KEYWORD_DAMAGE:
                case BONK_MASTERY_CRIT_VS_KEYWORD:
                case BONK_MASTERY_KEYWORD_CRIT:
                case BONK_MASTERY_SPREAD_TARGETS:
                case BONK_MASTERY_KEYWORD_DURATION:
                case BONK_MASTERY_KEYWORD_CAP:
                    targetOk = sBonkMgr.GetKeyword(BonkKeyword(node.target)) != nullptr;
                    break;
                case BONK_MASTERY_CAPSTONE:
                    targetOk = node.target > BONK_CAPSTONE_NONE && node.target < MAX_BONK_CAPSTONE;
                    break;
                default:
                    break;
            }
            if (!targetOk)
            {
                sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_mastery`: node %u has unknown target %u, skipped.", node.id, node.target);
                continue;
            }

            BonkMasteryTree const& owner = m_trees[node.tree];
            bool const outside = owner.IsFree() ? node.row >= BONK_MASTERY_FREE_ROWS || node.position < -1.5f || node.position > 5.5f :
                node.row < 1 || node.row > BONK_SHOP_ROWS || node.column < 1 || node.column > BONK_SHOP_COLUMNS;
            if (outside)
            {
                sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_mastery`: node %u sits outside its tree (row %u, column %u), skipped.",
                    node.id, uint32(node.row), uint32(node.column));
                continue;
            }

            m_nodes[node.id] = std::move(node);
        } while (result->NextRow());
    }

    for (auto& itr : m_nodes)
    {
        BonkMasteryNode& node = itr.second;
        if (!node.requiredId)
            continue;
        auto required = m_nodes.find(node.requiredId);
        if (required == m_nodes.end() || required->second.classId != node.classId)
        {
            sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_mastery`: node %u requires %u, which is missing or of another class; no requirement.",
                node.id, node.requiredId);
            node.requiredId = 0;
            node.requiredRank = 0;
        }
        else
            node.requiredRank = std::min(std::max<uint8>(1, node.requiredRank), required->second.maxRank);
    }

    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk mastery nodes in %u trees", uint32(m_nodes.size()), uint32(m_trees.size()));
}

std::vector<BonkMasteryTree const*> BonkMastery::GetTrees(uint8 classId) const
{
    std::vector<BonkMasteryTree const*> trees;
    for (auto const& itr : m_trees)
        if (itr.second.classId == classId)
            trees.push_back(&itr.second);
    std::sort(trees.begin(), trees.end(), [](BonkMasteryTree const* a, BonkMasteryTree const* b)
    {
        return a->order != b->order ? a->order < b->order : a->id < b->id;
    });
    return trees;
}

uint32 BonkMastery::GetRowGate(BonkMasteryNode const& node) const
{
    BonkMasteryTree const* tree = GetTree(node.tree);
    if (tree && tree->IsFree())
        return node.row < BONK_MASTERY_FREE_ROWS ? BONK_MASTERY_FREE_GATES[node.row] : BONK_MASTERY_FREE_GATES[BONK_MASTERY_FREE_ROWS - 1];
    return uint32(std::max<uint8>(node.row, 1) - 1) * BONK_MASTERY_POINTS_PER_ROW;
}

bool BonkMastery::HasTrees(uint8 classId) const
{
    for (auto const& itr : m_trees)
        if (itr.second.classId == classId)
            return true;
    return false;
}

BonkMasteryNode const* BonkMastery::GetNode(uint32 id) const
{
    auto itr = m_nodes.find(id);
    return itr != m_nodes.end() ? &itr->second : nullptr;
}

BonkMasteryTree const* BonkMastery::GetTree(uint32 id) const
{
    auto itr = m_trees.find(id);
    return itr != m_trees.end() ? &itr->second : nullptr;
}

BonkMasteryNode const* BonkMastery::FindStarterUnlock(uint8 classId, uint32 weaponId) const
{
    for (auto const& itr : m_nodes)
        if (itr.second.classId == classId && itr.second.effect == BONK_MASTERY_STARTER_UNLOCK && itr.second.target == weaponId)
            return &itr.second;
    return nullptr;
}

uint32 BonkMastery::GetXpForLevel(uint32 level)
{
    uint32 const steps = std::max(1u, level) - 1;
    uint32 const baseXp = BONK_MASTERY_XP_BASE + BONK_MASTERY_XP_STEP * steps + BONK_MASTERY_XP_CURVE * steps * steps / 2;
    uint32 const slowLevels = level > BONK_MASTERY_XP_SLOW_FROM_LEVEL ? level - BONK_MASTERY_XP_SLOW_FROM_LEVEL : 0;
    return baseXp * (100 + BONK_MASTERY_XP_SLOW_PERCENT_PER_LEVEL * slowLevels) / 100;
}

uint32 BonkMastery::GetLevel(uint32 xp)
{
    uint32 level = 0;
    while (level < BONK_MASTERY_MAX_LEVEL && xp >= GetXpForLevel(level + 1))
    {
        xp -= GetXpForLevel(level + 1);
        ++level;
    }
    return level;
}

uint32 BonkMastery::GetXpIntoLevel(uint32 xp)
{
    uint32 level = 0;
    while (level < BONK_MASTERY_MAX_LEVEL && xp >= GetXpForLevel(level + 1))
    {
        xp -= GetXpForLevel(level + 1);
        ++level;
    }
    return level < BONK_MASTERY_MAX_LEVEL ? xp : 0;
}

uint32 BonkMastery::GetRootWeapon(uint32 weaponId)
{
    BonkWeapon const* weapon = sBonkMgr.GetWeapon(weaponId);
    for (uint32 steps = 0; weapon && weapon->evolvesFrom && steps < 8; ++steps)
    {
        BonkWeapon const* from = sBonkMgr.GetWeapon(weapon->evolvesFrom);
        if (!from)
            break;
        weapon = from;
    }
    return weapon ? weapon->id : weaponId;
}

BonkMasteryBonuses BonkMastery::Evaluate(std::map<uint32, uint8> const& ranks) const
{
    BonkMasteryBonuses bonuses;
    for (auto const& itr : ranks)
    {
        BonkMasteryNode const* node = GetNode(itr.first);
        if (!node || !itr.second)
            continue;

        float const value = node->valuePerRank * std::min(itr.second, node->maxRank);
        switch (node->effect)
        {
            case BONK_MASTERY_PASSIVE:        bonuses.passives[node->target] += value; break;
            case BONK_MASTERY_SPELL_DAMAGE:   bonuses.spellDamage[node->target] += value; break;
            case BONK_MASTERY_SCHOOL_DAMAGE:  bonuses.schoolDamage.emplace_back(node->target, value); break;
            case BONK_MASTERY_SPELL_COOLDOWN: bonuses.spellCooldown[node->target] += value; break;
            case BONK_MASTERY_SPELL_TARGETS:  bonuses.spellTargets[node->target] += uint32(value); break;
            case BONK_MASTERY_SHATTER:        bonuses.shatter += value; break;
            case BONK_MASTERY_OPENER:         bonuses.opener.emplace_back(node->target, value); break;
            case BONK_MASTERY_EXECUTE:        bonuses.execute.emplace_back(node->target, value); break;
            case BONK_MASTERY_CLEARCASTING:   bonuses.clearcasting += value; break;
            case BONK_MASTERY_SOUL_SIPHON:    bonuses.soulSiphon.emplace_back(node->target, value); break;
            case BONK_MASTERY_SPELL_SLOW:     bonuses.spellSlow[node->target] += value; break;
            case BONK_MASTERY_SPEC_DAMAGE:    bonuses.specDamage[node->target] += value; break;
            case BONK_MASTERY_KEYWORD_DAMAGE: bonuses.keywordDamage[node->target] += value; break;
            case BONK_MASTERY_CRIT_VS_KEYWORD: bonuses.critVsKeyword[node->target] += value; break;
            case BONK_MASTERY_KEYWORD_CRIT:
                bonuses.keywordCrit.insert(node->target);
                if (node->param)
                    bonuses.keywordCrit.insert(node->param);
                break;
            case BONK_MASTERY_USES_BONUS:     bonuses.usesBonus[node->target] += value; break;
            case BONK_MASTERY_SPELL_STACKS:   bonuses.spellStacks[node->target] += value; break;
            case BONK_MASTERY_SPELL_DURATION: bonuses.spellDuration[node->target] += value; break;
            case BONK_MASTERY_SPELL_REACH:    bonuses.spellReach[node->target] += value; break;
            case BONK_MASTERY_SPELL_BEHAVIOR: bonuses.spellBehavior[node->target] += value; break;
            case BONK_MASTERY_KEYWORD_DURATION: bonuses.keywordDuration[node->target] += value; break;
            case BONK_MASTERY_KEYWORD_CAP:    bonuses.keywordCap[node->target] += value; break;
            case BONK_MASTERY_CAST_HASTE:
                bonuses.castHaste[node->target] += value;
                bonuses.castHasteStacks[node->target] = std::max(bonuses.castHasteStacks[node->target], node->param);
                break;
            case BONK_MASTERY_SPECIAL:        bonuses.specials[node->target] += value; break;
            case BONK_MASTERY_SPELL_APPLIES:
            {
                BonkMasteryApply& apply = bonuses.spellApplies[node->target];
                apply.keyword = BonkKeyword(node->param);
                apply.stacks = uint8(std::max(1.0f, value));
                break;
            }
            case BONK_MASTERY_SPELL_HEAL:     bonuses.spellHeal[node->target] += value; break;
            case BONK_MASTERY_RESET_ON_KILL:  bonuses.resetOnKill.insert(node->target); break;
            case BONK_MASTERY_EXECUTE_THRESHOLD:
                bonuses.executeThreshold[node->target] = std::max(bonuses.executeThreshold[node->target], value);
                break;
            case BONK_MASTERY_SPELL_STUN:     bonuses.spellStun[node->target] = std::max(bonuses.spellStun[node->target], value); break;
            case BONK_MASTERY_STRUCK_CAST:    bonuses.struckCast[node->target] = value; break;
            case BONK_MASTERY_SPREAD_TARGETS: bonuses.spreadTargets[node->target] += uint32(value); break;
            case BONK_MASTERY_ENTRAPMENT:     bonuses.entrapment.insert(node->target); break;
            case BONK_MASTERY_ENRAGE_DURATION: bonuses.enrageDuration += value; break;
            case BONK_MASTERY_ENRAGE_HASTE:   bonuses.enrageHaste += value; break;
            case BONK_MASTERY_ENRAGE_DAMAGE:  bonuses.enrageDamage += value; break;
            case BONK_MASTERY_SHIELD_BLOCK:   bonuses.shieldBlock += value; break;
            case BONK_MASTERY_DASH_RECHARGE:  bonuses.dashRecharge += value; break;
            case BONK_MASTERY_CHILL_DURATION: bonuses.chillDuration += value; break;
            case BONK_MASTERY_MARK_BONUS:     bonuses.markBonus += value; break;
            case BONK_MASTERY_SUMMON_CRIT:    bonuses.summonCrit += value; break;
            case BONK_MASTERY_PACK_POWER:     bonuses.packPower += value; break;
            case BONK_MASTERY_FRENZY_DAMAGE:  bonuses.frenzyDamage += value; break;
            case BONK_MASTERY_LAST_STAND:     bonuses.lastStand = std::max(bonuses.lastStand, value); break;
            case BONK_MASTERY_ICE_BLOCK:      bonuses.iceBlock = std::max(bonuses.iceBlock, value); break;
            case BONK_MASTERY_BLINK_SHIELD:   bonuses.blinkShield += value; break;
            case BONK_MASTERY_TRAP_DURATION:  bonuses.trapDuration += value; break;
            case BONK_MASTERY_CAPSTONE:       bonuses.capstone = BonkCapstone(node->target); break;
            default: break;
        }
    }
    ApplyCapstoneCost(bonuses);
    return bonuses;
}

void BonkMastery::ApplyCapstoneCost(BonkMasteryBonuses& bonuses)
{
    switch (bonuses.capstone)
    {
        case BONK_CAPSTONE_GLASS_CANNON:
            bonuses.passives[BONK_PASSIVE_CRIT_DAMAGE] += BONK_GLASS_CANNON_CRIT_DAMAGE;
            bonuses.passives[BONK_PASSIVE_MAX_HEALTH] -= BONK_GLASS_CANNON_HEALTH_COST;
            break;
        case BONK_CAPSTONE_SHADOWFORM:
            bonuses.keywordDamage[BONK_KEYWORD_DECAY] += BONK_SHADOWFORM_DECAY_DAMAGE;
            break;
        default:
            break;
    }
}

uint32 BonkMastery::GetSpec(uint32 weaponId)
{
    BonkWeapon const* root = sBonkMgr.GetWeapon(GetRootWeapon(weaponId));
    return root ? root->spec : 0;
}

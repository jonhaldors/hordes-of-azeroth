#include "BonkRun.h"
#include "BonkLocale.h"
#include "BonkMgr.h"
#include "BonkPlayer.h"
#include "BonkTelegraph.h"
#include "Creature.h"
#include "Item.h"
#include "Map.h"
#include "Player.h"
#include "SpellMgr.h"
#include "Utilities/Random.h"

#include <algorithm>
#include <cmath>

namespace
{
    uint32 const BONK_TRINKET_TICK_MS = 250;

    float const BONK_SKULL_DAMAGE       = 30.0f;
    float const BONK_SKULL_DAMAGE_TAKEN = 30.0f;
    float const BONK_GOGGLES_MAX_DAMAGE = 50.0f;

    uint32 const BONK_LAND_MINE_DROP_MS     = 6000;
    uint32 const BONK_LAND_MINE_CHECK_MS    = 100;
    int32 const BONK_LAND_MINE_ARM_MS       = 500;
    int32 const BONK_LAND_MINE_LIFE_MS      = 30000;
    size_t const BONK_LAND_MINE_MAX         = 5;
    float const BONK_LAND_MINE_TRIGGER      = 2.0f;
    float const BONK_LAND_MINE_RADIUS       = 6.0f;
    float const BONK_LAND_MINE_HEALTH_SHARE = 0.6f;
    uint32 const BONK_LAND_MINE_DISPLAY     = 6271;
    uint32 const BONK_SPELL_LAND_MINE       = 4043;
    uint32 const BONK_KIT_LAND_MINE         = 728;

    float const BONK_STOPWATCH_MAX_DODGE  = 5.0f;
    float const BONK_STOPWATCH_GAIN       = 1.0f;
    float const BONK_STOPWATCH_LOSS       = 2.0f;

    float const BONK_ROCKET_BOOTS_RANGE    = 50.0f;
    float const BONK_ROCKET_BOOTS_BACKFIRE = 5.0f;
    uint32 const BONK_KIT_ROCKET_BACKFIRE  = 728;

    float const BONK_DEMONIC_RUNE_POWER      = 25.0f;
    float const BONK_DEMONIC_RUNE_DRAIN      = 1.0f;
    float const BONK_DEMONIC_RUNE_FLOOR      = 30.0f;

    float const BONK_RUMSEY_RUM_GAIN    = 0.5f;
    float const BONK_RUMSEY_RUM_MAX     = 10.0f;

    uint32 const BONK_POCKET_GOLD_STEP  = 5000;
    float const BONK_POCKET_GOLD_MAX    = 8.0f;
    float const BONK_POCKET_GOLD_SLOW   = 5.0f;

    BonkTrinket const BONK_TRINKETS[MAX_BONK_TRINKET_EFFECT] =
    {
        { BONK_STRING_TRINKET_GNOMISH_BATTLE_GOGGLES, "inv_helmet_47", BONK_STRING_TRINKET_GNOMISH_BATTLE_GOGGLES_TEXT },
        { BONK_STRING_TRINKET_GOBLIN_LAND_MINE, "inv_misc_bomb_05", BONK_STRING_TRINKET_GOBLIN_LAND_MINE_TEXT },
        { BONK_STRING_TRINKET_NIFTY_STOPWATCH, "inv_misc_pocketwatch_01", BONK_STRING_TRINKET_NIFTY_STOPWATCH_TEXT },
        { BONK_STRING_TRINKET_GOBLIN_ROCKET_BOOTS, "inv_gizmo_rocketboot_01", BONK_STRING_TRINKET_GOBLIN_ROCKET_BOOTS_TEXT },
        { BONK_STRING_TRINKET_DEMONIC_RUNE, "inv_misc_rune_04", BONK_STRING_TRINKET_DEMONIC_RUNE_TEXT },
        { BONK_STRING_TRINKET_RUMSEY_RUM, "inv_drink_03", BONK_STRING_TRINKET_RUMSEY_RUM_TEXT },
        { BONK_STRING_TRINKET_GRINNING_SKULL_OF_WRATH, "inv_misc_bone_elfskull_01", BONK_STRING_TRINKET_GRINNING_SKULL_OF_WRATH_TEXT },
        { BONK_STRING_TRINKET_GOBLIN_POCKET_GOLD, "inv_misc_coin_03", BONK_STRING_TRINKET_GOBLIN_POCKET_GOLD_TEXT },
    };
}

BonkTrinket const& BonkMgr::GetTrinket(BonkTrinketEffect effect)
{
    return BONK_TRINKETS[effect < MAX_BONK_TRINKET_EFFECT ? effect : 0];
}

void BonkRun::UpdateWornTrinkets()
{
    uint32 worn = 0;
    BonkTrinketEffect effect;
    if (m_sandboxBench)
    {
        for (uint32 entry : m_sandboxBenchItems)
            if (BonkMgr::ReadTrinketEffect(entry, effect))
                worn |= 1u << effect;
    }
    else
        for (uint8 slot : { EQUIPMENT_SLOT_TRINKET1, EQUIPMENT_SLOT_TRINKET2 })
            if (Item const* item = m_player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
                if (BonkMgr::ReadTrinketEffect(item->GetEntry(), effect))
                    worn |= 1u << effect;
    if (worn == m_wornTrinkets)
        return;
    m_wornTrinkets = worn;
    if (!WearsTrinket(BONK_TRINKET_STOPWATCH))
        m_stopwatchDodge = 0.0f;
    if (!WearsTrinket(BONK_TRINKET_RUMSEY_RUM))
        m_rumseyCrit = 0.0f;
    if (!WearsTrinket(BONK_TRINKET_LAND_MINE))
        DespawnLandMines();
    ApplyPassives();
}

void BonkRun::UpdateTrinkets(uint32 diff)
{
    UpdateLandMines(diff);
    m_trinketTickMs += diff;
    if (m_trinketTickMs < BONK_TRINKET_TICK_MS)
        return;
    uint32 const elapsed = m_trinketTickMs;
    m_trinketTickMs = 0;
    if (!m_wornTrinkets || !m_player->IsAlive())
        return;
    UpdateStopwatch(elapsed);
    UpdateRumseyRum(elapsed);
    DrainDemonicRune(elapsed);
}

void BonkRun::UpdateStopwatch(uint32 elapsed)
{
    if (!WearsTrinket(BONK_TRINKET_STOPWATCH))
        return;
    float const seconds = float(elapsed) / IN_MILLISECONDS;
    float const change = m_player->IsMoving() ? BONK_STOPWATCH_GAIN * seconds : -BONK_STOPWATCH_LOSS * seconds;
    int32 const shownBefore = int32(m_stopwatchDodge + 0.5f);
    m_stopwatchDodge = std::max(0.0f, std::min(BONK_STOPWATCH_MAX_DODGE, m_stopwatchDodge + change));
    if (int32(m_stopwatchDodge + 0.5f) == shownBefore)
        return;
    ApplyPassives();
    if (m_sandbox)
        LogStopwatch();
}

void BonkRun::LogStopwatch() const
{
    char text[128];
    snprintf(text, sizeof(text), "Nifty Stopwatch: %s, trinket dodge %.0f%%, total dodge %.1f%%, actual %.1f%%",
        m_player->IsMoving() ? "moving" : "standing", m_stopwatchDodge, GetStat(BONK_PASSIVE_DODGE), m_player->GetUnitDodgeChance());
    sLog.Player(m_player->GetSession(), LOG_LEVELUP, LOG_LVL_BASIC, "Bonk stopwatch: %s %s", m_player->GetName(), text);
    m_player->GetBonkPlayer()->Notify(text);
}

void BonkRun::UpdateRumseyRum(uint32 elapsed)
{
    if (WearsTrinket(BONK_TRINKET_RUMSEY_RUM))
        m_rumseyCrit = std::min(BONK_RUMSEY_RUM_MAX, m_rumseyCrit + BONK_RUMSEY_RUM_GAIN * elapsed / IN_MILLISECONDS);
}

void BonkRun::DrainDemonicRune(uint32 elapsed)
{
    if (!WearsTrinket(BONK_TRINKET_DEMONIC_RUNE))
        return;
    uint32 const maxHealth = m_player->GetMaxHealth();
    uint32 const floor = uint32(maxHealth * BONK_DEMONIC_RUNE_FLOOR / 100.0f);
    uint32 const health = m_player->GetHealth();
    if (health <= floor)
        return;
    uint32 const drain = std::max(1u, uint32(maxHealth * BONK_DEMONIC_RUNE_DRAIN / 100.0f * elapsed / IN_MILLISECONDS));
    m_player->SetHealth(std::max(floor, health - std::min(health, drain)));
}

void BonkRun::OnTrinketHitTaken()
{
    m_rumseyCrit *= 0.5f;
}

void BonkRun::UpdateLandMines(uint32 diff)
{
    if (WearsTrinket(BONK_TRINKET_LAND_MINE) && m_player->IsAlive())
    {
        m_landMineDropMs += diff;
        if (m_landMineDropMs >= BONK_LAND_MINE_DROP_MS)
        {
            m_landMineDropMs = 0;
            DropLandMine();
        }
    }

    m_landMineCheckMs += diff;
    if (m_landMineCheckMs < BONK_LAND_MINE_CHECK_MS || m_landMines.empty())
        return;
    int32 const elapsed = int32(m_landMineCheckMs);
    m_landMineCheckMs = 0;

    Map* map = m_player->GetMap();
    std::vector<LandMine> sprung;
    for (auto itr = m_landMines.begin(); itr != m_landMines.end();)
    {
        itr->armMs -= elapsed;
        itr->leftMs -= elapsed;
        bool springs = false;
        if (itr->armMs <= 0 && itr->leftMs > 0)
            for (ObjectGuid const& guid : GetEnemyGuids())
                if (Creature* mob = map->GetCreature(guid))
                    if (mob->IsAlive() && mob->GetDistance2d(itr->x, itr->y) <= BONK_LAND_MINE_TRIGGER)
                    {
                        springs = true;
                        break;
                    }
        if (!springs && itr->leftMs > 0)
        {
            ++itr;
            continue;
        }
        SendBonkPropGone(m_player, itr->prop);
        if (springs)
            sprung.push_back(*itr);
        itr = m_landMines.erase(itr);
    }

    for (LandMine const& mine : sprung)
        DetonateLandMine(mine.x, mine.y, mine.z);
}

void BonkRun::DropLandMine()
{
    if (m_landMines.size() >= BONK_LAND_MINE_MAX)
    {
        SendBonkPropGone(m_player, m_landMines.front().prop);
        m_landMines.erase(m_landMines.begin());
    }
    LandMine mine;
    mine.x = m_player->GetPositionX();
    mine.y = m_player->GetPositionY();
    mine.z = m_player->GetPositionZ();
    mine.armMs = BONK_LAND_MINE_ARM_MS;
    mine.leftMs = BONK_LAND_MINE_LIFE_MS;
    mine.prop = NextBonkAuraKey();
    SendBonkProp(m_player, mine.prop, BONK_LAND_MINE_DISPLAY, mine.x, mine.y, mine.z, m_player->GetOrientation());
    m_landMines.push_back(mine);
}

void BonkRun::DetonateLandMine(float x, float y, float z)
{
    SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(BONK_SPELL_LAND_MINE);
    if (!spellInfo || !m_player->IsAlive())
        return;
    PlayKitAt(ObjectGuid(), x, y, z, BONK_KIT_LAND_MINE, true);
    BonkTrinket const& trinket = BonkMgr::GetTrinket(BONK_TRINKET_LAND_MINE);
    SupportScope scope(*this, { trinket.icon, GetString(trinket.name) });
    float const damage = GetProcBaseHealth() * BONK_LAND_MINE_HEALTH_SHARE;
    Map* map = m_player->GetMap();
    std::vector<Creature*> targets;
    for (ObjectGuid const& guid : GetEnemyGuids())
        if (Creature* mob = map->GetCreature(guid))
            if (mob->IsAlive() && mob->GetDistance2d(x, y) <= BONK_LAND_MINE_RADIUS)
                targets.push_back(mob);
    bool const wasProc = m_cardProc;
    m_cardProc = true;
    for (Creature* mob : targets)
        DealSpellHit(spellInfo, mob, damage);
    m_cardProc = wasProc;
}

void BonkRun::DespawnLandMines()
{
    for (LandMine const& mine : m_landMines)
        SendBonkPropGone(m_player, mine.prop);
    m_landMines.clear();
    m_landMineDropMs = 0;
}

float BonkRun::GetTrinketDamageMultiplier() const
{
    float multiplier = 1.0f;
    if (WearsTrinket(BONK_TRINKET_SKULL))
        multiplier *= 1.0f + BONK_SKULL_DAMAGE / 100.0f;
    if (WearsTrinket(BONK_TRINKET_GOGGLES) && m_player->GetMaxHealth())
        multiplier *= 1.0f + BONK_GOGGLES_MAX_DAMAGE / 100.0f * std::max(0.0f, 1.0f - m_player->GetHealthPercent() / 100.0f);
    return multiplier;
}

float BonkRun::GetTrinketDamageTaken() const
{
    return WearsTrinket(BONK_TRINKET_SKULL) ? 1.0f + BONK_SKULL_DAMAGE_TAKEN / 100.0f : 1.0f;
}

float BonkRun::GetTrinketPower() const
{
    float power = 0.0f;
    if (WearsTrinket(BONK_TRINKET_DEMONIC_RUNE))
        power += BONK_DEMONIC_RUNE_POWER;
    if (WearsTrinket(BONK_TRINKET_POCKET_GOLD))
        power += std::min(BONK_POCKET_GOLD_MAX, float(m_goldEarned / BONK_POCKET_GOLD_STEP));
    return power;
}

float BonkRun::GetTrinketMoveSpeed() const
{
    return WearsTrinket(BONK_TRINKET_POCKET_GOLD) ? -BONK_POCKET_GOLD_SLOW : 0.0f;
}

float BonkRun::GetTrinketStat(BonkPassiveEffect effect) const
{
    switch (effect)
    {
        case BONK_PASSIVE_DODGE: return m_stopwatchDodge;
        case BONK_PASSIVE_CRIT:  return m_rumseyCrit;
        default:                 return 0.0f;
    }
}

float BonkRun::GetTrinketDashScale() const
{
    return WearsTrinket(BONK_TRINKET_ROCKET_BOOTS) ? 1.0f + BONK_ROCKET_BOOTS_RANGE / 100.0f : 1.0f;
}

void BonkRun::ReportSandboxTrinkets()
{
    char text[320];
    snprintf(text, sizeof(text), "trinkets moving %u worn %u hp %.0f dodge %.2f crit %.2f power %.1f speed %.1f damage x%.3f taken x%.2f dash x%.2f mines %u gold %u dodge total %.2f actual %.2f",
        uint32(m_player->IsMoving()), m_wornTrinkets, m_player->GetHealthPercent(), m_stopwatchDodge, m_rumseyCrit, GetTrinketPower(), GetStat(BONK_PASSIVE_MOVE_SPEED),
        GetTrinketDamageMultiplier(), GetTrinketDamageTaken(), GetTrinketDashScale(), uint32(m_landMines.size()), m_goldEarned, GetStat(BONK_PASSIVE_DODGE), m_player->GetUnitDodgeChance());
    m_player->GetBonkPlayer()->Notify(text);
}

bool BonkRun::RollDashBackfire()
{
    if (!WearsTrinket(BONK_TRINKET_ROCKET_BOOTS) || !roll_chance_f(BONK_ROCKET_BOOTS_BACKFIRE))
        return false;
    m_player->SendPlaySpellVisualKit(BONK_KIT_ROCKET_BACKFIRE);
    return true;
}

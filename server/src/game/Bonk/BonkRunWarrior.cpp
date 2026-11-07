#include "BonkRun.h"
#include "Log.h"
#include "BonkAura.h"
#include "BonkLocale.h"
#include "BonkPlayer.h"
#include "Creature.h"
#include "Item.h"
#include "Map.h"
#include "Player.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "Utilities/Random.h"

#include <algorithm>
#include <cmath>

namespace
{
    float const BONK_ENRAGE_HASTE             = 25.0f;
    uint32 const BONK_ENRAGE_MS               = 4000;
    uint32 const BONK_ENRAGE_REFRESH_GAP_MS   = 250;
    uint32 const BONK_SPELL_ENRAGE_LOOK       = 33462;
    uint32 const BONK_KIT_WHIRLWIND_SPIN      = 369;
    uint32 const BONK_KIT_BLADESTORM_SPIN     = 7352;
    uint32 const BONK_REVENGE_WINDOW_MS       = 500;
    float const BONK_REVENGE_SHIELD_PER_HIT   = 2.0f;
    float const BONK_REVENGE_SHIELD_MAX       = 6.0f;
    size_t const BONK_MAX_PENDING_CRITS       = 200;
    size_t const BONK_MAX_DEEP_WOUNDS_PER_SEC = 20;
    size_t const BONK_DEEP_WOUNDS_PRUNE_SIZE  = 256;
    float const BONK_DEEP_WOUNDS_CRIT_PER_STACK = 1.0f;
    uint32 const BONK_REND_SWING_BLEED        = 1;
    uint32 const BONK_MORTAL_TEAR_MS          = 2000;
    uint32 const BONK_WEAPON_CLEAVE           = 300;
    uint32 const BONK_WEAPON_REND             = 301;
    uint32 const BONK_WEAPON_WHIRLWIND        = 306;
    uint32 const BONK_DEEP_WOUNDS_CRIT_STACKS = 20;
    uint32 const BONK_KIT_DEEP_WOUND          = 220;
    float const BONK_SHIELD_SLAM_MAX_BONUS    = 200.0f;

    uint32 const BONK_WARRIOR_CLASS_MASK      = 1 << (CLASS_WARRIOR - 1);
    uint32 const BONK_SHAMAN_CLASS_MASK       = 1 << (CLASS_SHAMAN - 1);
    uint32 const BONK_SWING_ANIMATION_GAP_MS  = 400;

    int32 const BONK_WAKE_DELAY_MS            = 1000;
    size_t const BONK_MAX_WAKE_ECHOES         = 6;
    uint32 const BONK_KIT_WAKE_ECHO           = 366;

    uint32 const BONK_FOURTH_SWING_EVERY      = 4;
    float const BONK_FOURTH_SWING_WIDTH       = 1.5f;
    uint32 const BONK_KIT_FOURTH_SWING        = 5649;

    uint32 const BONK_KIT_BLOOD_AURA          = 3051;

    uint32 const BONK_BLOOD_POOL_MS           = 4000;
    int32 const BONK_BLOOD_POOL_PULSE_MS      = 1000;
    uint32 const BONK_BLOOD_POOL_STACKS       = 1;
    size_t const BONK_MAX_BLOOD_POOLS         = 12;
    size_t const BONK_MAX_NEW_BLOOD_POOLS     = 6;
    uint32 const BONK_KIT_BLOOD_POOL          = 809;

    size_t const BONK_MAX_SPLATTERED          = 8;
    uint32 const BONK_KIT_BLOODSPLATTER       = 903;

    float const BONK_HEMORRHAGE_GROWTH        = 0.1f;
    float const BONK_HEMORRHAGE_MAX_GROWTH    = 2.0f;
    float const BONK_MIN_DOT_TICK_MS          = 100.0f;

    uint32 const BONK_BLOODLUST_CUT_MS        = 500;
    uint32 const BONK_BLOODLUST_MAX_CUT_MS    = 1000;
    int32 const BONK_BLOODLUST_FLOOR_MS       = 3000;

    int32 const BONK_AFTERSHOCK_DELAY_MS      = 1500;
    float const BONK_AFTERSHOCK_SHARE         = 0.3f;
    uint32 const BONK_AFTERSHOCK_STACKS       = 1;
    uint32 const BONK_KIT_AFTERSHOCK          = 7400;
    uint32 const BONK_KIT_AFTERSHOCK_QUAKE    = 7401;

    float const BONK_BLOODBATH_HEALTH         = 50.0f;
    uint32 const BONK_KIT_BLOODBATH           = 902;

    uint32 const BONK_KIT_BLOOD_SHIELD_BURST  = 903;

    int32 const BONK_CHAIN_EXECUTION_DELAY_MS = 100;
    float const BONK_CHAIN_EXECUTION_RADIUS   = 5.0f;
    float const BONK_CHAIN_EXECUTION_SHARE    = 0.5f;
    uint32 const BONK_MAX_CHAIN_EXECUTIONS    = 30;
    size_t const BONK_MAX_CHAIN_EXECUTIONS_PER_SEC = 30;
    uint32 const BONK_KIT_CHAIN_EXECUTION     = 5009;

    float const BONK_SWEEP_RANGE              = 40.0f;
    uint32 const BONK_KIT_SWEEP               = 3909;

    uint32 const BONK_BLADESTORM_MS           = 3000;
    float const BONK_BLADESTORM_ENRAGED       = 1.5f;
    int32 const BONK_BLADESTORM_PULSE_MS      = 500;
    int32 const BONK_MIN_BLADESTORM_PULSE_MS  = 150;
    uint32 const BONK_BLADESTORM_KIT_GAP_MS   = 450;

    uint32 const BONK_STEEL_CYCLONE_MS        = 3000;
    int32 const BONK_STEEL_CYCLONE_TICK_MS    = 500;
    float const BONK_STEEL_CYCLONE_SHARE      = 0.2f;
    size_t const BONK_MAX_STEEL_CYCLONES      = 4;

    uint32 const BONK_AEGIS_COOLDOWN_MS       = 500;
    uint32 const BONK_KIT_AEGIS               = 509;

    int32 const BONK_SPIKED_SHIELD_PULSE_MS   = 1000;
    int32 const BONK_MIN_SPIKED_SHIELD_PULSE_MS = 250;
    uint32 const BONK_KIT_SPIKED_SHIELD       = 895;

    float const BONK_ROLLING_THUNDER_HITS     = 8.0f;
    uint32 const BONK_MIN_ROLLING_THUNDER_HITS = 4;
    uint32 const BONK_MAX_BANKED_CLAPS        = 2;
    int32 const BONK_ROLLING_THUNDER_GAP_MS   = 250;

    float const BONK_DEMORALIZING_MAX_HEAL    = 2.0f;
    float const BONK_BLOODTHIRST_MAX_HEAL     = 2.5f;
    float const BONK_BLOODBATH_MAX_HEAL       = 4.0f;
    size_t const BONK_MAX_DEMORALIZED_LOOKS   = 8;
    uint32 const BONK_KIT_DEMORALIZING_SHOUT  = 351;
    uint32 const BONK_KIT_DEMORALIZED         = 693;

    float const BONK_VENGEANCE_MAX_STORE      = 0.5f;
    float const BONK_VENGEANCE_FULL_BONUS     = 2.0f;
    float const BONK_VENGEANCE_SHOWN_FILL     = 0.1f;
    float const BONK_VENGEANCE_NOVA_FILL      = 0.5f;
    uint32 const BONK_KIT_VENGEANCE           = 810;
    uint32 const BONK_KIT_VENGEANCE_NOVA      = 3349;

    uint32 const BONK_SPELL_AVENGERS_SHIELD_LOOK = 16075;
    uint32 const BONK_KIT_SHIELD_THROW        = 1184;
    uint32 const BONK_AVENGERS_SHIELD_BOUNCES = 5;
    float const BONK_AVENGERS_SHIELD_BOUNCE_RANGE = 10.0f;
    int32 const BONK_AVENGERS_SHIELD_GAP_MS   = 60;

    float const BONK_BULWARK_SHIELD_PER_HIT   = 1.0f;
    float const BONK_BULWARK_MAX_SHIELD       = 10.0f;
    uint32 const BONK_KIT_BULWARK             = 481;

    uint32 const BONK_STRIKE_IMPACT_GAP_MS    = 250;

    struct BonkStrikeImpact
    {
        uint32 spellId;
        uint32 kitId;
    };
    BonkStrikeImpact const BONK_STRIKE_IMPACTS[] = {
        { 15613, 507 },
        { 19632, 507 },
        { 13446, 437 },
        { 20240, 437 },
        { 24316, 220 },
        { 23881, 220 },
        { 15576, 507 },
    };

    uint32 GetStrikeImpactKit(uint32 spellId)
    {
        for (BonkStrikeImpact const& impact : BONK_STRIKE_IMPACTS)
            if (impact.spellId == spellId)
                return impact.kitId;
        return 0;
    }

    thread_local bool t_periodicHit = false;

    float const BONK_AGONY_GROWTH             = 0.25f;
    float const BONK_AGONY_MAX_GROWTH         = 2.0f;

    float GetStackGrowth(uint32 elapsedMs, float tickMs, bool agony)
    {
        float const step = agony ? BONK_AGONY_GROWTH : BONK_HEMORRHAGE_GROWTH;
        return std::min(agony ? BONK_AGONY_MAX_GROWTH : BONK_HEMORRHAGE_MAX_GROWTH, step * std::floor(elapsedMs / tickMs));
    }
}

float BonkRun::GetAgonyPeakScale()
{
    return 1.0f + BONK_AGONY_MAX_GROWTH;
}

uint32 BonkRun::GetAgonyPeakTicks()
{
    return uint32(std::ceil(BONK_AGONY_MAX_GROWTH / BONK_AGONY_GROWTH));
}

void BonkRun::SetPeriodicHit(bool periodic)
{
    t_periodicHit = periodic;
}

bool BonkRun::IsPeriodicHit()
{
    return t_periodicHit;
}

bool BonkRun::IsEnraged() const
{
    return m_player->HasAura(BONK_SPELL_ENRAGE_LOOK);
}

float BonkRun::GetEnrageHaste() const
{
    return IsEnraged() ? (BONK_ENRAGE_HASTE + m_mastery.enrageHaste) * m_mastery.EnrageBoost() : 0.0f;
}

void BonkRun::Enrage()
{
    if (m_state != STATE_RUNNING || !m_player->IsAlive())
        return;
    uint32 const length = BONK_ENRAGE_MS + uint32(m_mastery.enrageDuration * IN_MILLISECONDS);
    SpellAuraHolder* current = m_player->GetSpellAuraHolder(BONK_SPELL_ENRAGE_LOOK, m_player->GetObjectGuid());
    if (current && current->GetAuraDuration() + int32(BONK_ENRAGE_REFRESH_GAP_MS) > int32(length))
        return;

    if (SpellAuraHolder* holder = current)
    {
        holder->SetAuraMaxDuration(int32(length));
        holder->RefreshHolder();
        SendEnrageText();
        return;
    }
    BonkPlayer::SpellTweak& tweak = m_player->GetBonkPlayer()->TweakSpell(BONK_SPELL_ENRAGE_LOOK);
    tweak.durationMs = length;
    tweak.durationScale = 1.0f;
    m_player->CastCustomSpell(m_player, BONK_SPELL_ENRAGE_LOOK, 0, 0, {}, true);
    SendEnrageText();
}

// The Enrage haste and duration scale with the Flurry and Berserker masteries, so the aura text is
// formatted from the live values rather than the catalog's fixed wording.
void BonkRun::SendEnrageText() const
{
    BonkAuraEntry const* entry = sBonkAura.Get(BONK_SPELL_ENRAGE_LOOK);
    if (!entry || !m_player->GetBonkPlayer()->IsAddonReady())
        return;
    m_player->GetBonkPlayer()->SendAuraText(BONK_SPELL_ENRAGE_LOOK,
        sBonkAura.Format(*entry, GetLocale(), { FormatBonkNumber(GetEnrageHaste()) }));
}

void BonkRun::EnrageOnKill(uint32 killingSpell)
{
    OwnedWeapon const* owned = killingSpell ? FindOwnedBySpell(killingSpell) : nullptr;
    if (owned && owned->weapon.behavior == BONK_BEHAVIOR_EXECUTE)
        Enrage();
}

void BonkRun::OnCriticalStrike(SpellCaster const* caster, SpellEntry const* spell, Unit const* victim)
{
    if (m_state != STATE_RUNNING || caster != m_player || !spell || !victim || m_criticalStrikes.size() >= BONK_MAX_PENDING_CRITS)
        return;
    if (!HasBehavior(BONK_BEHAVIOR_DEEP_WOUNDS) && !HasBehavior(BONK_BEHAVIOR_BLOODTHIRST) && !HasBehavior(BONK_BEHAVIOR_HOT_STREAK) &&
        !GetGlyph(BONK_GLYPH_IGNITE))
        return;
    m_criticalStrikes.emplace_back(victim->GetObjectGuid(), spell->Id);
}

void BonkRun::ResolveCriticalStrikes()
{
    if (m_criticalStrikes.empty())
        return;
    std::vector<std::pair<ObjectGuid, uint32>> crits;
    crits.swap(m_criticalStrikes);

    OwnedWeapon const* deepWounds = FindOwnedByBehavior(BONK_BEHAVIOR_DEEP_WOUNDS);
    if (m_deepWoundsReadyMs.size() > BONK_DEEP_WOUNDS_PRUNE_SIZE)
        PruneDeepWounds();

    Map* map = m_player->GetMap();
    for (auto const& crit : crits)
    {
        OwnedWeapon const* striker = FindOwnedBySpell(crit.second);
        if (striker && striker->weapon.behavior == BONK_BEHAVIOR_BLOODTHIRST)
            Enrage();
        Creature* mob = map->GetCreature(crit.first);
        if (deepWounds && mob)
            OpenDeepWound(*deepWounds, mob);
        if (striker && striker->weapon.behavior == BONK_BEHAVIOR_HOT_STREAK && mob)
            TriggerHotStreak(*striker, mob);
        if (mob)
            IgniteFromCrit(mob, crit.second);
    }
}

void BonkRun::OpenDeepWound(OwnedWeapon const& owned, Creature* mob)
{
    if (!mob->IsAlive())
        return;
    auto ready = m_deepWoundsReadyMs.find(mob->GetObjectGuid());
    if (ready != m_deepWoundsReadyMs.end() && ready->second > m_totalMs)
        return;

    PendingKeyword keyword;
    if (!GetWeaponKeyword(owned, keyword) || !TakeRateSlot(m_deepWoundTimes, BONK_MAX_DEEP_WOUNDS_PER_SEC))
        return;

    m_deepWoundsReadyMs[mob->GetObjectGuid()] = m_totalMs + GetWeaponCooldown(owned);
    uint32 const applications = 1 + std::min(GetSpellCount(owned), BONK_MAX_COUNT_PULSES);
    uint32 const stacks = keyword.stacks * applications;
    if (!ApplyKeyword(mob, keyword.keyword, stacks, keyword.durationMs, keyword.damageScale, keyword.spellId))
        return;
    if (owned.weapon.HasFlag(BONK_WEAPON_FLAG_BLOODSPLATTER))
        SplatterBlood(owned, mob, stacks);
    else
        mob->SendPlaySpellVisualKit(BONK_KIT_DEEP_WOUND);
}

void BonkRun::TearBleed(OwnedWeapon const& owned, Creature* mob)
{
    float const torn = GetDotDamageLeft(mob, BONK_KEYWORD_BLEED, BONK_MORTAL_TEAR_MS);
    SpellEntry const* look = sSpellMgr.GetSpellEntry(owned.weapon.spellId);
    if (torn > 0.0f && look && mob->IsAlive())
        DealShamanHit(look, owned.weapon.spellId, mob, torn);
}

float BonkRun::GetDeepWoundsCritChance(Unit const* victim) const
{
    if (!victim || !HasBehavior(BONK_BEHAVIOR_DEEP_WOUNDS))
        return 0.0f;
    return std::min(GetKeywordStacks(victim, BONK_KEYWORD_BLEED), BONK_DEEP_WOUNDS_CRIT_STACKS) * BONK_DEEP_WOUNDS_CRIT_PER_STACK;
}

void BonkRun::SplatterBlood(OwnedWeapon const& owned, Creature* struck, uint32 stacks)
{
    struck->SendPlaySpellVisualKit(BONK_KIT_BLOODSPLATTER);
    PendingKeyword keyword;
    if (!GetWeaponKeyword(owned, keyword))
        return;

    size_t splattered = 0;
    for (Creature* mob : GetMobsNear(struck->GetPositionX(), struck->GetPositionY(), GetWeaponRadius(owned)))
    {
        if (splattered >= BONK_MAX_SPLATTERED)
            break;
        if (mob != struck && ApplyKeyword(mob, keyword.keyword, stacks, keyword.durationMs, keyword.damageScale, keyword.spellId))
            ++splattered;
    }
}

bool BonkRun::IsGrowingDotSpell(uint32 spellId) const
{
    OwnedWeapon const* owned = spellId ? FindOwnedBySpell(spellId) : nullptr;
    return owned && owned->weapon.HasFlag(BONK_WEAPON_FLAG_HEMORRHAGE);
}

float BonkRun::GetDotGrowth(Unit const* victim, uint32 spellId) const
{
    if (!victim)
        return 1.0f;
    BonkKeywordInfo const* info = sBonkMgr.GetKeywordBySpell(spellId);
    if (!info || !info->IsDamageOverTime())
        return 1.0f;
    bool const agony = info->id == BONK_KEYWORD_AGONY;
    if (!agony && !FindOwnedByFlag(BONK_WEAPON_FLAG_HEMORRHAGE))
        return 1.0f;
    auto mob = m_dotStacks.find(victim->GetObjectGuid());
    if (mob == m_dotStacks.end())
        return 1.0f;
    auto stacks = mob->second.find(info->id);
    if (stacks == mob->second.end())
        return 1.0f;

    uint32 const now = WorldTimer::getMSTime();
    float const tickMs = std::max(BONK_MIN_DOT_TICK_MS, info->tickMs / GetHasteRate());
    double total = 0.0;
    double grown = 0.0;
    for (DotStack const& stack : stacks->second)
    {
        total += stack.points;
        grown += stack.points * (stack.grows ? 1.0f + GetStackGrowth(now - stack.appliedMs, tickMs, agony) : 1.0f);
    }
    return total > 0.0 ? float(grown / total) : 1.0f;
}

void BonkRun::PruneDeepWounds()
{
    for (auto itr = m_deepWoundsReadyMs.begin(); itr != m_deepWoundsReadyMs.end();)
    {
        if (itr->second <= m_totalMs)
            itr = m_deepWoundsReadyMs.erase(itr);
        else
            ++itr;
    }
}

BonkRun::OwnedWeapon const* BonkRun::FindOwnedByBehavior(BonkWeaponBehavior behavior) const
{
    auto itr = std::find_if(m_weapons.begin(), m_weapons.end(), [behavior](OwnedWeapon const& owned) { return owned.weapon.behavior == behavior; });
    return itr != m_weapons.end() ? &*itr : nullptr;
}

bool BonkRun::WasStruckRecently() const
{
    return m_struck && m_totalMs - m_struckAtMs <= BONK_REVENGE_WINDOW_MS;
}

uint32 BonkRun::GetShieldGain(OwnedWeapon const& owned) const
{
    float const percent = GetShieldPercent(owned.weapon, owned.damageBonus, GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_SHIELD_SIZE));
    return uint32(m_player->GetMaxHealth() * percent / 100.0f) + (owned.weapon.IsShieldBlock() ? GetShieldBlockTalent() : 0);
}

float BonkRun::GetShieldPercent(BonkWeapon const& weapon, float damageBonus, float sizeUpgrade)
{
    return weapon.behaviorValue * (1.0f + damageBonus / 100.0f) * (1.0f + sizeUpgrade / 100.0f);
}

float BonkRun::GetShieldSlamMultiplier(OwnedWeapon const& owned) const
{
    float const shieldPercent = 100.0f * float(m_spellShield) / float(std::max(1u, m_player->GetMaxHealth()));
    return 1.0f + std::min(owned.weapon.behaviorValue * shieldPercent, BONK_SHIELD_SLAM_MAX_BONUS) / 100.0f;
}

void BonkRun::SpinWhirlwind(OwnedWeapon const& owned, SpellEntry const* spellInfo)
{
    if (owned.weapon.behavior == BONK_BEHAVIOR_BLADESTORM)
    {
        StartBladestorm(owned);
        return;
    }
    if (!IsEnraged())
        return;

    PendingCast spin;
    spin.weaponId = owned.weapon.id;
    spin.spellId = spellInfo->Id;
    spin.leftMs = int32(owned.weapon.behaviorValue);
    spin.selfArea = true;
    m_pendingCasts.push_back(spin);
    if (m_mastery.Special(BONK_SPECIAL_RAMPAGE) > 0.0f)
    {
        spin.leftMs = int32(owned.weapon.behaviorValue * 2.0f);
        m_pendingCasts.push_back(spin);
    }
}

void BonkRun::ShowWhirlwindSpin()
{
    m_player->SendPlaySpellVisualKit(BONK_KIT_WHIRLWIND_SPIN);
}

void BonkRun::HealFromStrikes(OwnedWeapon const& owned, SpellEntry const* spellInfo, uint32 hits)
{
    SupportScope scope(*this, WeaponSupport(owned));
    if (!hits || owned.weapon.healPct <= 0.0f || !m_player->IsAlive())
        return;
    float const cap = owned.weapon.HasFlag(BONK_WEAPON_FLAG_BLOODBATH) ? BONK_BLOODBATH_MAX_HEAL : BONK_BLOODTHIRST_MAX_HEAL;
    float const percent = std::min(cap, owned.weapon.healPct * hits);
    uint32 const amount = ReduceHealing(std::max(1u, uint32(m_player->GetMaxHealth() * percent / 100.0f)));
    uint32 const missing = m_player->GetMaxHealth() - std::min(m_player->GetMaxHealth(), m_player->GetHealth());
    HealHero(amount, spellInfo->Id);
    if (owned.weapon.HasFlag(BONK_WEAPON_FLAG_BLOOD_SHIELD) && amount > missing)
        FormBloodShield(amount - missing);
}

void BonkRun::ResetWarriorState()
{
    m_player->RemoveAurasDueToSpell(BONK_SPELL_ENRAGE_LOOK);
    RemoveHeroLooks();
    m_struck = false;
    m_struckAtMs = 0;
    m_criticalStrikes.clear();
    m_deepWoundsReadyMs.clear();
    m_deepWoundTimes.clear();
    m_swingKnocksBack = false;
    m_bloodlustCutMs = 0;
    m_bloodShieldHeld = false;
    m_bloodShieldBurst = false;
    m_bloodPoolTimes.clear();
    m_chainExecutionTimes.clear();
    m_chainExecutionCast = 0;
    m_chainExecutionsLeft = 0;
    m_bladestorm = Bladestorm();
    m_bladestormKitMs = 0;
    m_steelCyclones.clear();
    m_aegisPending = false;
    m_aegisReadyMs = 0;
    m_spikedShieldMs = 0;
    m_thunderHits = 0;
    m_thunderCountedMs.clear();
    m_vengeanceStored = 0;
    m_vengeanceShare = 1.0f;
    m_strikeImpactMs.clear();
}

// Stock spells the warrior's kit triggers but HoA does not want shown, stripped every tick because
// they apply asynchronously (a strip right after the cast misses them):
//  - the Bloodthirst weapon casts stock Bloodthirst (23881), whose heal-on-melee proc sub-spells
//    (the 23885-23894 family, aura type 42) leave a meaningless "heals 0 health" buff; HoA computes
//    the Bloodthirst heal directly, so none of that family is a wanted aura.
//  - 7069 "Enraging Aura" is a stock party aura dragged in around the enrage window; HoA's Enrage is
//    the 33462 window aura alone, so 7069 is noise.
void BonkRun::StripStockWarriorAuras()
{
    static uint32 const STOCK_LOOK_AURAS[] = { 23881, 23885, 23886, 23887, 23888, 23889, 23890, 23891, 23892, 23893, 23894, 7069 };
    for (uint32 spellId : STOCK_LOOK_AURAS)
        if (m_player->HasAura(spellId))
            m_player->RemoveAurasDueToSpell(spellId);
}

void BonkRun::UpdateWarrior(uint32 diff)
{
    StripStockWarriorAuras();
    ApplyBloodlust();
    BurstBloodShield();
    UpdateBladestorm(diff);
    UpdateSteelCyclones(diff);
    ReleaseAegis();
    PulseSpikedShield(diff);
    UpdateBloodAuraRing();
    UpdateVengeanceLook();
}

BonkRun::OwnedWeapon const* BonkRun::FindOwnedByFlag(BonkWeaponFlags flag) const
{
    auto itr = std::find_if(m_weapons.begin(), m_weapons.end(), [flag](OwnedWeapon const& owned) { return owned.weapon.HasFlag(flag); });
    return itr != m_weapons.end() ? &*itr : nullptr;
}

bool BonkRun::SwingsWeapon(BonkWeapon const& weapon)
{
    if (weapon.classMask & BONK_SHAMAN_CLASS_MASK)
        return weapon.behavior == BONK_BEHAVIOR_WINDFURY || weapon.behavior == BONK_BEHAVIOR_STORMSTRIKE;
    if (!(weapon.classMask & BONK_WARRIOR_CLASS_MASK) || weapon.IsKeywordOnly() || weapon.HasFlag(BONK_WEAPON_FLAG_LOOK_ONLY))
        return false;
    if (weapon.IsWhirlwind() || weapon.IsWeaken() || weapon.behavior == BONK_BEHAVIOR_AVENGERS_SHIELD)
        return false;
    return weapon.target == BONK_TARGET_SELF_AREA || weapon.IsAimed();
}

void BonkRun::SwingWeapon(OwnedWeapon const& owned)
{
    if (!SwingsWeapon(owned.weapon) || !m_player->IsAlive())
        return;
    uint32 const now = WorldTimer::getMSTime();
    if (WorldTimer::getMSTimeDiff(m_swingAnimationMs, now) < BONK_SWING_ANIMATION_GAP_MS)
        return;
    m_swingAnimationMs = now;
    m_player->HandleEmote(GetSwingEmote());
}

uint32 BonkRun::GetSwingEmote() const
{
    Item const* weapon = m_player->GetWeaponForAttack(BASE_ATTACK, true, true);
    if (!weapon)
        return EMOTE_ONESHOT_ATTACKUNARMED;
    return weapon->GetProto()->InventoryType == INVTYPE_2HWEAPON ? EMOTE_ONESHOT_ATTACK2HTIGHT : EMOTE_ONESHOT_ATTACK1H;
}

BonkRun::OwnedWeapon const* BonkRun::FindRendSpreadBy(OwnedWeapon const& owned)
{
    uint32 const root = GetRootWeapon(owned.weapon);
    if (root != BONK_WEAPON_CLEAVE && root != BONK_WEAPON_WHIRLWIND && root != BONK_WEAPON_THUNDER_CLAP)
        return nullptr;
    return FindOwnedByRoot(BONK_WEAPON_REND);
}

void BonkRun::QueueRendSwingBleed(OwnedWeapon const& rend, Unit* mob)
{
    BonkKeywordInfo const* info = sBonkMgr.GetKeyword(BONK_KEYWORD_BLEED);
    if (!info)
        return;
    PendingKeyword bleed;
    bleed.mob = mob->GetObjectGuid();
    bleed.keyword = BONK_KEYWORD_BLEED;
    bleed.stacks = BONK_REND_SWING_BLEED;
    bleed.durationMs = uint32(info->durationMs * GetWeaponDurationScale(rend));
    bleed.damageScale = 1.0f + rend.damageBonus / 100.0f;
    bleed.spellId = rend.weapon.spellId;
    m_pendingKeywords.push_back(bleed);
}

void BonkRun::OnAroundStrike(OwnedWeapon const& owned, Creature* mob)
{
    uint32 const root = GetRootWeapon(owned.weapon);
    if (root == BONK_WEAPON_MORTAL_STRIKE)
        TearBleed(owned, mob);
    if (owned.weapon.behavior == BONK_BEHAVIOR_BLOODLUST && GetKeywordStacks(mob, BONK_KEYWORD_BLEED))
        m_bloodlustCutMs = std::min(m_bloodlustCutMs + BONK_BLOODLUST_CUT_MS, BONK_BLOODLUST_MAX_CUT_MS);
    if (m_swingKnocksBack)
        KnockBack(mob);
}

void BonkRun::OnAroundCast(OwnedWeapon const& owned, SpellEntry const* spellInfo, uint32 struck)
{
    if (struck)
        SwingWeapon(owned);
    if (owned.weapon.behavior == BONK_BEHAVIOR_WAKE_OF_BLADES)
        QueueWakeEcho(owned, spellInfo);
    if (owned.weapon.behavior == BONK_BEHAVIOR_AFTERSHOCK)
        QueueAftershock(owned, spellInfo);
    GainBulwark(owned, struck);
}

BonkRun::PendingCast BonkRun::MakeHeroSpotCast(OwnedWeapon const& owned, SpellEntry const* spellInfo, int32 delayMs) const
{
    PendingCast cast;
    cast.weaponId = owned.weapon.id;
    cast.spellId = spellInfo->Id;
    cast.leftMs = delayMs;
    m_player->GetPosition(cast.x, cast.y, cast.z);
    return cast;
}

void BonkRun::QueueWakeEcho(OwnedWeapon const& owned, SpellEntry const* spellInfo)
{
    auto const echoes = std::count_if(m_pendingCasts.begin(), m_pendingCasts.end(), [](PendingCast const& cast) { return cast.wakeOfBlades; });
    if (size_t(echoes) >= BONK_MAX_WAKE_ECHOES)
        return;
    PendingCast echo = MakeHeroSpotCast(owned, spellInfo, BONK_WAKE_DELAY_MS);
    echo.wakeOfBlades = true;
    m_pendingCasts.push_back(std::move(echo));
}

void BonkRun::QueueAftershock(OwnedWeapon const& owned, SpellEntry const* spellInfo)
{
    PendingCast quake = MakeHeroSpotCast(owned, spellInfo, BONK_AFTERSHOCK_DELAY_MS);
    quake.aftershock = true;
    m_pendingCasts.push_back(std::move(quake));
}

void BonkRun::ResolveWarriorCast(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    if (cast.wakeOfBlades)
        EchoBlades(owned, spellInfo, cast);
    else if (cast.aftershock)
        EruptAftershock(owned, spellInfo, cast);
    else if (cast.chainExecution)
        ExplodeExecuted(owned, spellInfo, cast);
    else if (cast.shieldThrow)
        LandShield(owned, spellInfo, cast);
}

void BonkRun::EchoBlades(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    PlayKitAt(ObjectGuid(), cast.x, cast.y, cast.z, BONK_KIT_WAKE_ECHO, true);
    float const damage = GetWeaponDamage(owned);
    for (Creature* mob : GetMobsNear(cast.x, cast.y, GetWeaponRadius(owned)))
        DealSpellHit(spellInfo, mob, damage);
}

bool BonkRun::SwingWide(OwnedWeapon& owned, SpellEntry const* spellInfo, float areaScale)
{
    if (owned.weapon.behavior != BONK_BEHAVIOR_FOURTH_SWING || owned.casts % BONK_FOURTH_SWING_EVERY != 0)
        return false;

    float x, y, z;
    m_player->GetPosition(x, y, z);
    PlayKitAt(ObjectGuid(), x, y, z, BONK_KIT_FOURTH_SWING, true);
    m_swingKnocksBack = true;
    CastSelfArea(owned, spellInfo, areaScale * BONK_FOURTH_SWING_WIDTH);
    m_swingKnocksBack = false;
    return true;
}

void BonkRun::PulseBloodAura(OwnedWeapon const& owned)
{
    PendingKeyword bleed;
    if (!m_player->IsAlive() || !GetWeaponKeyword(owned, bleed))
        return;

    ShowHeroRing(BonkHeroRing::BloodAura, GetBloodAuraReach(owned));

    bool bled = false;
    for (Creature* mob : GetMobsInRange(GetWeaponRadius(owned)))
        bled = ApplyKeyword(mob, bleed.keyword, bleed.stacks, bleed.durationMs, bleed.damageScale, bleed.spellId) || bled;
    if (bled)
        m_player->SendPlaySpellVisualKit(BONK_KIT_BLOOD_AURA);
}

float BonkRun::GetBloodAuraReach(OwnedWeapon const& owned) const
{
    return GetWeaponRadius(owned) + m_player->GetObjectBoundingRadius();
}

void BonkRun::UpdateBloodAuraRing()
{
    if (OwnedWeapon const* aura = FindOwnedByBehavior(BONK_BEHAVIOR_BLOOD_AURA))
        ShowHeroRing(BonkHeroRing::BloodAura, GetBloodAuraReach(*aura));
    else
        HideHeroRing(BonkHeroRing::BloodAura);
}

void BonkRun::OnBleedingDeath(Creature const* dead)
{
    OnTalentBleedingDeath();
    OwnedWeapon const* pool = FindOwnedByBehavior(BONK_BEHAVIOR_BLOOD_POOL);
    if (!pool || !TakeRateSlot(m_bloodPoolTimes, BONK_MAX_NEW_BLOOD_POOLS))
        return;

    PendingCast spill;
    spill.weaponId = pool->weapon.id;
    spill.spellId = pool->weapon.spellId;
    spill.keywordCloud = true;
    dead->GetPosition(spill.x, spill.y, spill.z);
    m_pendingCasts.push_back(std::move(spill));
}

BonkRun::KeywordCloudKind BonkRun::GetBloodPoolKind() const
{
    KeywordCloudKind pool;
    pool.lifeMs = BONK_BLOOD_POOL_MS;
    pool.pulseEveryMs = BONK_BLOOD_POOL_PULSE_MS;
    pool.stacks = BONK_BLOOD_POOL_STACKS;
    pool.maxAlive = BONK_MAX_BLOOD_POOLS;
    pool.bloodRing = true;
    pool.burstKit = BONK_KIT_BLOOD_POOL;
    return pool;
}

void BonkRun::ApplyBloodlust()
{
    if (!m_bloodlustCutMs)
        return;
    int32 const cut = int32(m_bloodlustCutMs);
    m_bloodlustCutMs = 0;
    for (OwnedWeapon& owned : m_weapons)
        if (owned.weapon.behavior == BONK_BEHAVIOR_BLOODLUST)
        {
            owned.timer = std::max(std::min(owned.timer, BONK_BLOODLUST_FLOOR_MS), owned.timer - cut);
            owned.pieResync = true;
        }
}

void BonkRun::EruptAftershock(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    PlayKitAt(ObjectGuid(), cast.x, cast.y, cast.z, BONK_KIT_AFTERSHOCK, true);
    PlayKitAt(ObjectGuid(), cast.x, cast.y, cast.z, BONK_KIT_AFTERSHOCK_QUAKE, true);

    BonkKeywordInfo const* bleed = sBonkMgr.GetKeyword(BONK_KEYWORD_BLEED);
    uint32 const bleedMs = bleed ? uint32(bleed->durationMs * GetWeaponDurationScale(owned)) : 0;
    float const bleedScale = 1.0f + owned.damageBonus / 100.0f;
    float const damage = GetWeaponDamage(owned) * BONK_AFTERSHOCK_SHARE;
    for (Creature* mob : GetMobsNear(cast.x, cast.y, GetWeaponRadius(owned)))
    {
        DealSpellHit(spellInfo, mob, damage);
        ApplyKeyword(mob, BONK_KEYWORD_BLEED, BONK_AFTERSHOCK_STACKS, bleedMs, bleedScale, owned.weapon.spellId);
    }
}

bool BonkRun::IsBloodbathing(OwnedWeapon const& owned) const
{
    return owned.weapon.HasFlag(BONK_WEAPON_FLAG_BLOODBATH) && m_player->GetHealthPercent() < BONK_BLOODBATH_HEALTH;
}

void BonkRun::ShowBloodbath()
{
    m_player->SendPlaySpellVisualKit(BONK_KIT_BLOODBATH);
}

void BonkRun::FormBloodShield(uint32 amount)
{
    uint32 const before = m_spellShield;
    AddSpellShield(amount);
    if (m_spellShield > before)
        m_bloodShieldHeld = true;
}

void BonkRun::BreakBloodShield()
{
    if (!m_bloodShieldHeld)
        return;
    m_bloodShieldHeld = false;
    m_bloodShieldBurst = true;
}

void BonkRun::BurstBloodShield()
{
    if (!m_bloodShieldBurst)
        return;
    m_bloodShieldBurst = false;

    OwnedWeapon const* owned = FindOwnedByFlag(BONK_WEAPON_FLAG_BLOOD_SHIELD);
    SpellEntry const* spellInfo = owned ? sSpellMgr.GetSpellEntry(owned->weapon.spellId) : nullptr;
    if (!spellInfo || !m_player->IsAlive())
        return;

    m_player->SendPlaySpellVisualKit(BONK_KIT_BLOOD_SHIELD_BURST);
    float const damage = GetWeaponDamage(*owned) * std::max(1.0f, owned->weapon.behaviorValue);
    for (Creature* mob : GetMobsInRange(GetWeaponRadius(*owned)))
        DealSpellHit(spellInfo, mob, damage);
}

void BonkRun::QueueChainExecution(Creature const* dead, uint32 killingSpell)
{
    OwnedWeapon const* owned = killingSpell ? FindOwnedBySpell(killingSpell) : nullptr;
    if (!owned || !owned->weapon.HasFlag(BONK_WEAPON_FLAG_CHAIN_EXECUTION) || !TakeChainExecutionSlot(*owned))
        return;

    PendingCast blast;
    blast.weaponId = owned->weapon.id;
    blast.spellId = owned->weapon.spellId;
    blast.leftMs = BONK_CHAIN_EXECUTION_DELAY_MS;
    blast.chainExecution = true;
    dead->GetPosition(blast.x, blast.y, blast.z);
    m_pendingCasts.push_back(std::move(blast));
}

bool BonkRun::TakeChainExecutionSlot(OwnedWeapon const& owned)
{
    if (m_chainExecutionCast != owned.casts)
    {
        m_chainExecutionCast = owned.casts;
        m_chainExecutionsLeft = BONK_MAX_CHAIN_EXECUTIONS;
    }
    if (!m_chainExecutionsLeft || !TakeRateSlot(m_chainExecutionTimes, BONK_MAX_CHAIN_EXECUTIONS_PER_SEC))
        return false;
    --m_chainExecutionsLeft;
    return true;
}

void BonkRun::ExplodeExecuted(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    PlayKitAt(ObjectGuid(), cast.x, cast.y, cast.z, BONK_KIT_CHAIN_EXECUTION, true);
    std::vector<Creature*> const caught = GetMobsNear(cast.x, cast.y, BONK_CHAIN_EXECUTION_RADIUS * GetWeaponArea(owned));
    float const damage = GetWeaponDamage(owned) * BONK_CHAIN_EXECUTION_SHARE;
    for (Creature* mob : caught)
        DealSpellHit(spellInfo, mob, damage);

    FiringWeapon firing(m_player->GetBonkPlayer());
    for (Creature* mob : caught)
        if (CanKill(owned.weapon, mob))
            StrikeWith(owned, spellInfo, mob, 1.0f, true);
}

uint32 BonkRun::SweepExecute(OwnedWeapon& owned, SpellEntry const* spellInfo, float nearRange)
{
    std::vector<Creature*> doomed;
    for (Creature* mob : GetMobsInRange(BONK_SWEEP_RANGE))
        if (m_player->GetDistance(mob) > nearRange && CanKill(owned.weapon, mob) && m_player->IsWithinLOSInMap(mob))
            doomed.push_back(mob);

    FiringWeapon firing(m_player->GetBonkPlayer());
    for (Creature* mob : doomed)
    {
        mob->SendPlaySpellVisualKit(BONK_KIT_SWEEP);
        StrikeWith(owned, spellInfo, mob, 1.0f);
    }
    return uint32(doomed.size());
}

void BonkRun::OnWhirlwindSpin(OwnedWeapon const& owned)
{
    if (owned.weapon.behavior == BONK_BEHAVIOR_STEEL_CYCLONE)
        StartSteelCyclone(owned);
    if (owned.weapon.behavior == BONK_BEHAVIOR_BLADESTORM)
    {
        if (m_totalMs < m_bladestormKitMs)
            return;
        m_bladestormKitMs = m_totalMs + BONK_BLADESTORM_KIT_GAP_MS;
        m_player->SendPlaySpellVisualKit(BONK_KIT_BLADESTORM_SPIN);
        return;
    }
    ShowWhirlwindSpin();
}

int32 BonkRun::GetBladestormPulseMs(OwnedWeapon const& owned) const
{
    return std::max(BONK_MIN_BLADESTORM_PULSE_MS, int32(BONK_BLADESTORM_PULSE_MS / GetWeaponHasteRate(owned)));
}

void BonkRun::StartBladestorm(OwnedWeapon const& owned)
{
    float const enraged = IsEnraged() ? BONK_BLADESTORM_ENRAGED : 1.0f;
    int32 const length = int32(BONK_BLADESTORM_MS * enraged * GetWeaponDurationScale(owned));
    if (m_bladestorm.weaponId != owned.weapon.id || m_bladestorm.leftMs <= 0)
    {
        m_bladestorm = Bladestorm();
        m_bladestorm.weaponId = owned.weapon.id;
        m_bladestorm.pulseMs = GetBladestormPulseMs(owned);
    }
    m_bladestorm.leftMs = std::max(m_bladestorm.leftMs, length);

    // The spin window's aura states the remaining time and the pulse rate, so the player
    // sees how long the storm lasts (Enraged makes it 50% longer).
    if (m_player->IsAlive())
    {
        if (SpellAuraHolder* holder = m_player->AddAura(BONK_SPELL_BLADESTORM_AURA, ADD_AURA_POSITIVE))
        {
            holder->SetAuraMaxDuration(int32(length));
            holder->SetAuraDuration(int32(m_bladestorm.leftMs));
            holder->UpdateAuraDuration();
        }
        SendBladestormText(owned);
    }
}

// The Bladestorm's aura text states the remaining spin time and the pulse rate.
void BonkRun::SendBladestormText(OwnedWeapon const& owned) const
{
    BonkAuraEntry const* entry = sBonkAura.Get(BONK_SPELL_BLADESTORM_AURA);
    if (!entry || !m_player->GetBonkPlayer()->IsAddonReady())
        return;
    m_player->GetBonkPlayer()->SendAuraText(BONK_SPELL_BLADESTORM_AURA,
        sBonkAura.Format(*entry, GetLocale(),
            { FormatBonkNumber(m_bladestorm.leftMs / 1000.0f),
              FormatBonkNumber(GetBladestormPulseMs(owned) / 1000.0f) }));
}

void BonkRun::UpdateBladestorm(uint32 diff)
{
    PulseBladestorm(diff);
    ShowHeroLook(BonkHeroLook::Bladestorm, m_bladestorm.weaponId != 0);
}

void BonkRun::PulseBladestorm(uint32 diff)
{
    if (!m_bladestorm.weaponId)
        return;

    OwnedWeapon* owned = FindOwned(m_bladestorm.weaponId);
    SpellEntry const* spellInfo = owned ? sSpellMgr.GetSpellEntry(owned->weapon.spellId) : nullptr;
    m_bladestorm.leftMs -= int32(diff);
    m_bladestorm.pulseMs -= int32(diff);
    if (!spellInfo || m_bladestorm.leftMs <= 0 || !m_player->IsAlive())
    {
        m_bladestorm = Bladestorm();
        m_player->RemoveAurasDueToSpell(BONK_SPELL_BLADESTORM_AURA);
        return;
    }
    if (m_bladestorm.pulseMs > 0)
        return;

    m_bladestorm.pulseMs += GetBladestormPulseMs(*owned);
    CastSelfArea(*owned, spellInfo, GetWeaponArea(*owned));
    // The stock Whirlwind Effect spell leaves a meaningless permanent aura; strip it.
    m_player->RemoveAurasDueToSpell(15576);
}

void BonkRun::StartSteelCyclone(OwnedWeapon const& owned)
{
    if (m_steelCyclones.size() >= BONK_MAX_STEEL_CYCLONES)
        m_steelCyclones.erase(m_steelCyclones.begin());

    SteelCyclone storm;
    storm.weaponId = owned.weapon.id;
    m_player->GetPosition(storm.x, storm.y, storm.z);
    storm.leftMs = int32(BONK_STEEL_CYCLONE_MS * GetWeaponDurationScale(owned));
    storm.tickMs = BONK_STEEL_CYCLONE_TICK_MS;
    m_steelCyclones.push_back(storm);
}

void BonkRun::UpdateSteelCyclones(uint32 diff)
{
    for (size_t i = 0; i < m_steelCyclones.size();)
    {
        SteelCyclone& storm = m_steelCyclones[i];
        OwnedWeapon* owned = FindOwned(storm.weaponId);
        SpellEntry const* spellInfo = owned ? sSpellMgr.GetSpellEntry(owned->weapon.spellId) : nullptr;
        storm.leftMs -= int32(diff);
        storm.tickMs -= int32(diff);
        bool const strikes = storm.tickMs <= 0;
        if (strikes)
            storm.tickMs += BONK_STEEL_CYCLONE_TICK_MS;

        SteelCyclone const striking = storm;
        if (!spellInfo || storm.leftMs <= 0)
            m_steelCyclones.erase(m_steelCyclones.begin() + i);
        else
            ++i;
        if (strikes && spellInfo && m_player->IsAlive())
            StrikeSteelCyclone(*owned, spellInfo, striking);
    }
}

void BonkRun::StrikeSteelCyclone(OwnedWeapon& owned, SpellEntry const* spellInfo, SteelCyclone const& storm)
{
    PlayKitAt(ObjectGuid(), storm.x, storm.y, storm.z, BONK_KIT_WHIRLWIND_SPIN, true);
    float const damage = GetWeaponDamage(owned) * BONK_STEEL_CYCLONE_SHARE;
    float const twice = GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_HIT_TWICE);
    for (Creature* mob : GetMobsNear(storm.x, storm.y, GetWeaponRadius(owned)))
    {
        DealSpellHit(spellInfo, mob, damage);
        if (twice > 0.0f && roll_chance_f(twice))
            DealSpellHit(spellInfo, mob, damage);
    }
}

void BonkRun::NoteHeroHit(uint32 unshielded, uint32 taken)
{
    if (m_state != STATE_RUNNING || !unshielded)
        return;
    bool const absorbed = taken < unshielded;
    for (OwnedWeapon const& owned : m_weapons)
    {
        if (owned.weapon.behavior == BONK_BEHAVIOR_VENGEANCE)
            m_vengeanceStored = std::min(m_vengeanceStored + taken, uint32(m_player->GetMaxHealth() * BONK_VENGEANCE_MAX_STORE));
        else if (owned.weapon.behavior == BONK_BEHAVIOR_AEGIS && absorbed && m_totalMs >= m_aegisReadyMs)
            m_aegisPending = true;
    }
}

void BonkRun::StrikeAroundHero(OwnedWeapon const& owned, uint32 kit)
{
    SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(owned.weapon.spellId);
    if (!spellInfo || !m_player->IsAlive())
        return;
    std::vector<Creature*> const mobs = GetMobsInRange(GetWeaponRadius(owned));
    if (mobs.empty())
        return;

    m_player->SendPlaySpellVisualKit(kit);
    float const damage = GetWeaponDamage(owned);
    for (Creature* mob : mobs)
        DealSpellHit(spellInfo, mob, damage);
}

void BonkRun::ReleaseAegis()
{
    if (!m_aegisPending)
        return;
    m_aegisPending = false;
    OwnedWeapon const* owned = FindOwnedByBehavior(BONK_BEHAVIOR_AEGIS);
    if (!owned)
        return;
    m_aegisReadyMs = m_totalMs + BONK_AEGIS_COOLDOWN_MS;
    StrikeAroundHero(*owned, BONK_KIT_AEGIS);
}

void BonkRun::PulseSpikedShield(uint32 diff)
{
    OwnedWeapon const* owned = FindOwnedByBehavior(BONK_BEHAVIOR_SPIKED_SHIELD);
    ShowHeroLook(BonkHeroLook::SpikedShield, owned && m_spellShield);
    if (!owned)
    {
        m_spikedShieldMs = 0;
        return;
    }
    m_spikedShieldMs -= int32(diff);
    if (m_spikedShieldMs > 0)
        return;

    m_spikedShieldMs = std::max(BONK_MIN_SPIKED_SHIELD_PULSE_MS, int32(BONK_SPIKED_SHIELD_PULSE_MS / GetWeaponHasteRate(*owned)));
    if (m_spellShield)
        StrikeAroundHero(*owned, BONK_KIT_SPIKED_SHIELD);
}

uint32 BonkRun::GetThunderHitsNeeded(OwnedWeapon const& owned) const
{
    return std::max(BONK_MIN_ROLLING_THUNDER_HITS, uint32(std::lround(BONK_ROLLING_THUNDER_HITS / GetWeaponHasteRate(owned))));
}

bool BonkRun::IsThunderReady(OwnedWeapon const& owned) const
{
    return m_thunderHits >= GetThunderHitsNeeded(owned);
}

void BonkRun::SpendThunder(OwnedWeapon& owned)
{
    m_thunderHits -= std::min(m_thunderHits, GetThunderHitsNeeded(owned));
    owned.timer = BONK_ROLLING_THUNDER_GAP_MS;
}

void BonkRun::CountThunderHit(SpellEntry const* spell)
{
    if (!spell || m_state != STATE_RUNNING || IsPeriodicHit())
        return;
    OwnedWeapon const* owned = FindOwnedByBehavior(BONK_BEHAVIOR_ROLLING_THUNDER);
    if (!owned || owned->weapon.spellId == spell->Id || !TakeThunderCount(spell->Id))
        return;
    m_thunderHits = std::min(m_thunderHits + 1, GetThunderHitsNeeded(*owned) * BONK_MAX_BANKED_CLAPS);
}

bool BonkRun::TakeThunderCount(uint32 spellId)
{
    auto const counted = m_thunderCountedMs.find(spellId);
    if (counted != m_thunderCountedMs.end() && counted->second == m_totalMs)
        return false;
    m_thunderCountedMs[spellId] = m_totalMs;
    return true;
}

std::string BonkRun::DescribeThunderCount(OwnedWeapon const& owned) const
{
    return GetString(BONK_STRING_THUNDER_CLAPS_AFTER, { std::to_string(GetThunderHitsNeeded(owned)) });
}

void BonkRun::DemoralizingShout(OwnedWeapon const& owned, SpellEntry const* spellInfo, std::vector<Creature*> const& hit)
{
    SupportScope scope(*this, WeaponSupport(owned));
    m_player->SendPlaySpellVisualKit(BONK_KIT_DEMORALIZING_SHOUT);
    size_t shown = 0;
    for (Creature* mob : hit)
    {
        if (shown >= BONK_MAX_DEMORALIZED_LOOKS)
            break;
        if (mob->IsAlive())
        {
            mob->SendPlaySpellVisualKit(BONK_KIT_DEMORALIZED);
            ++shown;
        }
    }

    if (hit.empty() || owned.weapon.healPct <= 0.0f || !m_player->IsAlive())
        return;
    float const percent = std::min(BONK_DEMORALIZING_MAX_HEAL, owned.weapon.healPct * hit.size());
    HealHero(ReduceHealing(std::max(1u, uint32(m_player->GetMaxHealth() * percent / 100.0f))), spellInfo->Id);
}

float BonkRun::TakeVengeanceShare(OwnedWeapon const& owned)
{
    if (owned.weapon.behavior != BONK_BEHAVIOR_VENGEANCE)
        return 1.0f;

    float const store = std::max(1.0f, m_player->GetMaxHealth() * BONK_VENGEANCE_MAX_STORE);
    float const fill = std::min(1.0f, m_vengeanceStored / store);
    m_vengeanceStored = 0;
    if (fill >= BONK_VENGEANCE_NOVA_FILL)
        m_player->SendPlaySpellVisualKit(BONK_KIT_VENGEANCE_NOVA);
    else if (fill >= BONK_VENGEANCE_SHOWN_FILL)
        m_player->SendPlaySpellVisualKit(BONK_KIT_VENGEANCE);
    return 1.0f + BONK_VENGEANCE_FULL_BONUS * fill;
}

void BonkRun::UpdateVengeanceLook()
{
    float fill = 0.0f;
    if (FindOwnedByBehavior(BONK_BEHAVIOR_VENGEANCE))
        fill = m_vengeanceStored / std::max(1.0f, m_player->GetMaxHealth() * BONK_VENGEANCE_MAX_STORE);
    bool const charged = fill >= BONK_VENGEANCE_NOVA_FILL;
    ShowHeroLook(BonkHeroLook::VengeanceCharged, charged);
    ShowHeroLook(BonkHeroLook::Vengeance, !charged && fill >= BONK_VENGEANCE_SHOWN_FILL);
}

void BonkRun::OnRevenge(OwnedWeapon const& owned)
{
    if (owned.weapon.behavior == BONK_BEHAVIOR_BERSERKER_RAGE)
        Enrage();
    size_t const hits = GetMobsInRange(GetWeaponRadius(owned)).size();
    if (!hits || !m_player->IsAlive())
        return;
    float const percent = std::min(BONK_REVENGE_SHIELD_MAX, BONK_REVENGE_SHIELD_PER_HIT * hits);
    SupportScope scope(*this, WeaponSupport(owned));
    AddSpellShield(uint32(m_player->GetMaxHealth() * percent / 100.0f));
}

void BonkRun::ThrowShield(OwnedWeapon const& owned, SpellEntry const* spellInfo, Creature* target, float share)
{
    m_player->SendPlaySpellVisualKit(BONK_KIT_SHIELD_THROW);
    LaunchShield(owned, spellInfo, m_player, target, share, {}, BONK_AVENGERS_SHIELD_BOUNCES);
}

void BonkRun::LaunchShield(OwnedWeapon const& owned, SpellEntry const* spellInfo, Unit* from, Creature* target, float share,
    std::vector<ObjectGuid> struck, uint32 hops)
{
    SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_AVENGERS_SHIELD_LOOK);
    float const speed = look ? look->speed : 0.0f;
    uint32 const flightMs = from == m_player || speed <= 0.0f ? GetMissileDelay(from, target, speed) :
        uint32(target->GetDistance3dToCenter(from->GetPositionX(), from->GetPositionY(), from->GetPositionZ()) / speed * IN_MILLISECONDS);
    float x, y, z, o;
    if (!target->ExtrapolateMovement(target->m_movementInfo, flightMs, x, y, z, o))
        target->GetPosition(x, y, z);
    if (look)
        ShowMissileFrom(from, look, x, y, z + target->GetCollisionHeight() / 2.0f);

    struck.push_back(target->GetObjectGuid());
    PendingCast flight;
    flight.weaponId = owned.weapon.id;
    flight.spellId = spellInfo->Id;
    flight.leftMs = int32(flightMs) + BONK_AVENGERS_SHIELD_GAP_MS;
    flight.shieldThrow = true;
    flight.hops = hops;
    flight.share = share;
    flight.target = target->GetObjectGuid();
    flight.x = x;
    flight.y = y;
    flight.z = z;
    flight.struck = std::move(struck);
    m_pendingCasts.push_back(std::move(flight));
}

void BonkRun::LandShield(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    Creature* target = m_player->GetMap()->GetCreature(cast.target);
    bool const alive = target && target->IsInWorld() && target->IsAlive();
    if (cast.hops)
    {
        Creature* source = alive ? target : TakeShotSource(cast.x, cast.y, cast.z);
        Creature* next = source ? PickShieldBounce(source, source->GetPositionX(), source->GetPositionY(), cast.struck) : nullptr;
        if (next)
            LaunchShield(owned, spellInfo, source, next, cast.share, cast.struck, cast.hops - 1);
    }
    if (alive && owned.weapon.behavior == BONK_BEHAVIOR_PALADIN_SHIELD)
        StrikeWithAvengersShield(owned, target);
    else if (alive)
    {
        FiringWeapon firing(m_player->GetBonkPlayer());
        StrikeWith(owned, spellInfo, target, cast.share, true);
        ShowStrikeImpact(spellInfo, target);
    }
}

Creature* BonkRun::PickShieldBounce(WorldObject const* from, float x, float y, std::vector<ObjectGuid> const& struck) const
{
    for (Creature* mob : GetMobsNear(x, y, BONK_AVENGERS_SHIELD_BOUNCE_RANGE))
        if (std::find(struck.begin(), struck.end(), mob->GetObjectGuid()) == struck.end() && from->IsWithinLOSInMap(mob))
            return mob;
    return nullptr;
}

void BonkRun::GainBulwark(OwnedWeapon const& owned, uint32 struck)
{
    SupportScope scope(*this, WeaponSupport(owned));
    if (owned.weapon.behavior != BONK_BEHAVIOR_BULWARK || !struck || !m_player->IsAlive())
        return;
    float const size = 1.0f + GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_SHIELD_SIZE) / 100.0f;
    float const percent = std::min(BONK_BULWARK_MAX_SHIELD, BONK_BULWARK_SHIELD_PER_HIT * struck) * size;
    AddSpellShield(uint32(m_player->GetMaxHealth() * percent / 100.0f));
    m_player->SendPlaySpellVisualKit(BONK_KIT_BULWARK);
}

void BonkRun::ShowStrikeImpact(SpellEntry const* spellInfo, Creature* target)
{
    uint32 const kit = spellInfo && target ? GetStrikeImpactKit(spellInfo->Id) : 0;
    if (!kit)
        return;
    uint32& readyMs = m_strikeImpactMs[spellInfo->Id];
    if (m_totalMs < readyMs)
        return;
    readyMs = m_totalMs + BONK_STRIKE_IMPACT_GAP_MS;
    target->SendPlaySpellVisualKit(kit);
}

void BonkRun::ShowAreaImpact(SpellEntry const* spellInfo, float radius)
{
    if (!GetStrikeImpactKit(spellInfo->Id))
        return;
    std::vector<Creature*> const mobs = GetMobsInRange(radius);
    if (!mobs.empty())
        ShowStrikeImpact(spellInfo, mobs.front());
}

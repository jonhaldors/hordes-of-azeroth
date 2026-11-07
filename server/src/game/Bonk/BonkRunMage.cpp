#include "BonkRun.h"
#include "BonkMobAI.h"
#include "BonkPlayer.h"
#include "Creature.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "Utilities/Random.h"

#include <algorithm>
#include <cmath>

namespace
{
    uint32 const BONK_BLINK_CHILL             = 2;
    int32 const BONK_BLINK_NOVA_RESET_MS      = 60000;
    uint32 const BONK_WEAPON_FROST_NOVA       = 402;
    uint32 const BONK_WEAPON_ARCANE_MISSILES  = 409;
    float const BONK_MISSILES_CHAMPION_BONUS  = 1.5f;
    float const BONK_DEEP_FREEZE_FROST_BONUS  = 1.3f;
    uint32 const BONK_BLINK_CHARGES           = 1;
    uint32 const BONK_SHIMMER_CHARGES         = 2;
    float const BONK_BLINK_RECHARGE_RATE      = 1.0f / 0.7f;
    int32 const BONK_BLINK_LAND_MS            = 200;
    int32 const BONK_BLINK_RECAST_MS          = 300;
    int32 const BONK_SHIMMER_RECAST_MS        = 500;
    uint32 const BONK_MISSILE_INTERVAL_MS     = 250;
    float const BONK_PYROBLAST_SPLASH_RADIUS  = 6.0f;

    uint32 const BONK_SPELL_FROSTBOLT         = 116;
    uint32 const BONK_SPELL_ARCANE_EXPLOSION  = 1449;
    uint32 const BONK_SPELL_PYROBLAST         = 11366;

    uint32 const BONK_ICE_SHARD_HOPS          = 6;
    float const BONK_ICE_SHARD_RANGE          = 12.0f;
    uint32 const BONK_KIT_FROST_NOVA          = 160;
    size_t const BONK_MAX_FROSTBOLT_TARGETS   = 8;
    float const BONK_ICE_NOVA_REACH           = 30.0f;

    size_t const BONK_MAX_FROST_STORMS        = 6;
    uint32 const BONK_DEEP_FREEZE_MAX_MS      = 4000;
    uint32 const BONK_FREEZE_IMMUNE_MS        = 6000;
    uint32 const BONK_KIT_DEEP_FREEZE         = 216;
    float const BONK_FROSTBITE_NORMAL         = 15.0f;
    float const BONK_FROSTBITE_ELITE          = 5.0f;
    float const BONK_FROSTBITE_BOSS           = 1.0f;
    uint32 const BONK_KIT_FROSTBITE           = 4991;

    float const BONK_ICE_BARRIER_PER_FREEZE   = 1.0f;
    float const BONK_ICE_BARRIER_MAX          = 15.0f;
    uint32 const BONK_KIT_ICE_BARRIER         = 207;

    uint32 const BONK_WILDFIRE_MS             = 6000;
    int32 const BONK_WILDFIRE_PULSE_MS        = 1000;
    int32 const BONK_MIN_WILDFIRE_PULSE_MS    = 400;
    size_t const BONK_MAX_WILDFIRES           = 12;
    uint32 const BONK_SPELL_WILDFIRE_LOOK     = 133;

    int32 const BONK_LIVING_BOMB_MS           = 2000;
    float const BONK_LIVING_BOMB_SHARE        = 0.5f;
    size_t const BONK_MAX_LIVING_BOMBS        = 10;
    uint32 const BONK_KIT_LIVING_BOMB_PLANT   = 76;
    uint32 const BONK_KIT_LIVING_BOMB_BLAST   = 286;

    uint32 const BONK_FIREWALK_PILLARS        = 3;
    int32 const BONK_FIREWALK_GAP_MS          = 350;
    float const BONK_FIREWALK_STEP            = 1.2f;

    uint32 const BONK_SPELL_BURNING_GROUND_LOOK = 22191;
    uint32 const BONK_BURNING_GROUND_MS       = 6000;
    uint32 const BONK_CRATER_MS               = 4000;
    int32 const BONK_FIRE_CLOUD_PULSE_MS      = 1000;
    uint32 const BONK_FIRE_CLOUD_STACKS       = 1;
    size_t const BONK_MAX_BURNING_GROUNDS     = 6;
    size_t const BONK_MAX_CRATERS             = 4;

    uint32 const BONK_SPELL_METEOR_LOOK       = 26558;
    int32 const BONK_METEOR_FALL_MS           = 1000;
    float const BONK_METEOR_SHARE             = 0.6f;
    uint32 const BONK_METEOR_SHOWER_COUNT     = 7;
    float const BONK_METEOR_SHOWER_SPREAD     = 10.0f;
    float const BONK_METEOR_SHOWER_SHARE      = 0.3f;
    float const BONK_METEOR_SHOWER_PER_BURN   = 10.0f;
    uint32 const BONK_MAX_BURNING_COUNTED     = 30;

    float const BONK_ERUPTION_RADIUS          = 5.0f;
    float const BONK_ERUPTION_SHARE           = 0.4f;
    size_t const BONK_MAX_ERUPTIONS           = 12;
    size_t const BONK_ERUPTION_TARGETS        = 3;
    uint32 const BONK_KIT_BLAST_WAVE          = 984;
    uint32 const BONK_KIT_ERUPTION            = 286;

    float const BONK_HOT_STREAK_SHARE         = 5.0f;
    uint32 const BONK_KIT_HOT_STREAK          = 60;

    uint32 const BONK_PHASE_RUSH_INVULNERABLE_MS = 1000;
    float const BONK_PHASE_RUSH_WIDTH         = 3.0f;
    uint32 const BONK_KIT_PHASE_RUSH_HIT      = 1005;

    uint32 const BONK_SPELL_TIME_SLOW         = 246;
    uint32 const BONK_TIME_BUBBLE_MS          = 10000;
    int32 const BONK_TIME_BUBBLE_PULSE_MS     = 500;
    int32 const BONK_TIME_BUBBLE_SLOW         = -60;
    int32 const BONK_TIME_BUBBLE_SLOW_MS      = 1000;
    float const BONK_TIME_BUBBLE_DAMAGE       = 1.15f;

    uint32 const BONK_PRESENCE_OF_MIND_GAP_MS = 500;

    uint32 const BONK_MAX_BANKED_MISSILES     = 40;

    uint32 const BONK_ARCANE_POWER_MS         = 4000;
    float const BONK_ARCANE_POWER_DAMAGE      = 1.3f;

    uint32 const BONK_ELEMENTAL_SHIFT_MS      = 5000;
    float const BONK_HYDRA_REPLANT_RANGE      = 25.0f;
    uint32 const BONK_KIT_ELEMENTAL_SHIFT     = 3394;

    enum class MageSchool
    {
        Frost,
        Fire,
        Arcane,
        Count,
    };

    bool GetMageSchool(SpellEntry const* spellInfo, MageSchool& school)
    {
        if (!spellInfo)
            return false;
        uint32 const mask = spellInfo->GetSpellSchoolMask();
        if (mask & SPELL_SCHOOL_MASK_FROST)
            school = MageSchool::Frost;
        else if (mask & SPELL_SCHOOL_MASK_FIRE)
            school = MageSchool::Fire;
        else if (mask & SPELL_SCHOOL_MASK_ARCANE)
            school = MageSchool::Arcane;
        else
            return false;
        return true;
    }

    uint32 GetElementalFamilyOf(MageSchool school)
    {
        switch (school)
        {
            case MageSchool::Fire:
                return BONK_PET_FAMILY_FIRE_ELEMENTAL;
            case MageSchool::Arcane:
                return BONK_PET_FAMILY_ARCANE_ELEMENTAL;
            default:
                return BONK_PET_FAMILY_WATER_ELEMENTAL;
        }
    }

    BonkSpawnKind GetSpawnKind(Creature const* mob)
    {
        BonkMobAI const* ai = dynamic_cast<BonkMobAI const*>(mob->AI());
        return ai ? ai->GetKind() : BONK_SPAWN_NORMAL;
    }

    bool IsBigEnemy(Creature const* mob)
    {
        return GetSpawnKind(mob) != BONK_SPAWN_NORMAL;
    }

    float GetFrostbitePercent(Creature const* mob)
    {
        switch (GetSpawnKind(mob))
        {
            case BONK_SPAWN_NORMAL:
                return BONK_FROSTBITE_NORMAL;
            case BONK_SPAWN_ELITE:
                return BONK_FROSTBITE_ELITE;
            default:
                return BONK_FROSTBITE_BOSS;
        }
    }

    float DistanceToSegment(float x, float y, float fromX, float fromY, float toX, float toY)
    {
        float const dx = toX - fromX, dy = toY - fromY;
        float const lengthSquared = dx * dx + dy * dy;
        float t = lengthSquared > 0.0f ? ((x - fromX) * dx + (y - fromY) * dy) / lengthSquared : 0.0f;
        t = std::max(0.0f, std::min(1.0f, t));
        float const px = fromX + t * dx - x, py = fromY + t * dy - y;
        return std::sqrt(px * px + py * py);
    }

    void KeepInSight(Player const* hero, std::vector<Creature*>& mobs)
    {
        mobs.erase(std::remove_if(mobs.begin(), mobs.end(), [hero](Creature* mob) { return !hero->IsWithinLOSInMap(mob); }), mobs.end());
    }
}

bool BonkRun::IsFrostSpellOnFrozen(SpellEntry const* spell, Unit const* victim) const
{
    if (!spell || !victim || !(spell->GetSpellSchoolMask() & SPELL_SCHOOL_MASK_FROST))
        return false;
    OwnedWeapon const* owned = FindOwnedBySpell(spell->Id);
    return owned && (IsFrozen(victim) || (m_fingersReady && GetRootWeapon(owned->weapon) == BONK_WEAPON_FROSTBOLT));
}

BonkRun::OwnedWeapon const* BonkRun::FindOwnedWhere(bool (BonkWeapon::*test)() const) const
{
    auto itr = std::find_if(m_weapons.begin(), m_weapons.end(), [test](OwnedWeapon const& owned) { return (owned.weapon.*test)(); });
    return itr != m_weapons.end() ? &*itr : nullptr;
}

uint32 BonkRun::GetBlinkCharges() const
{
    OwnedWeapon const* blink = FindOwnedWhere(&BonkWeapon::IsBlink);
    if (!blink)
        return 0;
    return BONK_BLINK_CHARGES + (blink->weapon.behavior == BONK_BEHAVIOR_SHIMMER ? BONK_SHIMMER_CHARGES : 0);
}

float BonkRun::GetBlinkRechargeRate() const
{
    OwnedWeapon const* blink = FindOwnedWhere(&BonkWeapon::IsBlink);
    return blink ? BONK_BLINK_RECHARGE_RATE * GetWeaponHasteRate(*blink) : 1.0f;
}

uint32 BonkRun::GetBlinkInvulnerableMs() const
{
    return HasBehavior(BONK_BEHAVIOR_PHASE_RUSH) ? BONK_PHASE_RUSH_INVULNERABLE_MS : 0;
}

bool BonkRun::IsBlinkDash() const
{
    return FindOwnedWhere(&BonkWeapon::IsBlink) || IsTalentBlinkDash();
}

void BonkRun::OnDash()
{
    if (m_state != STATE_RUNNING || !m_player->IsAlive())
        return;
    OnTalentDash();
    OnGlyphDash();
    if (!IsBlinkDash())
        return;
    OnTalentBlink();

    float x, y, z;
    m_player->GetPosition(x, y, z);
    OwnedWeapon const* found = FindOwnedWhere(&BonkWeapon::IsBlink);
    OwnedWeapon* blink = found ? FindOwned(found->weapon.id) : nullptr;
    if (SpellEntry const* spellInfo = blink ? sSpellMgr.GetSpellEntry(blink->weapon.spellId) : nullptr)
    {
        CastSelfArea(*blink, spellInfo, GetWeaponArea(*blink));
        uint32 const pulses = std::min(GetSpellCount(*blink), BONK_MAX_COUNT_PULSES);
        for (uint32 i = 1; i <= pulses; ++i)
        {
            PendingCast again;
            again.weaponId = blink->weapon.id;
            again.spellId = spellInfo->Id;
            again.leftMs = int32(i) * BONK_BLINK_RECAST_MS;
            again.recast = true;
            m_pendingCasts.push_back(again);
        }

        if (blink->weapon.behavior == BONK_BEHAVIOR_PHASE_RUSH)
        {
            PendingCast rush;
            rush.weaponId = blink->weapon.id;
            rush.spellId = spellInfo->Id;
            rush.leftMs = BONK_BLINK_LAND_MS;
            rush.phaseRush = true;
            rush.x = x;
            rush.y = y;
            rush.z = z;
            m_pendingCasts.push_back(rush);
        }

        if (blink->weapon.behavior == BONK_BEHAVIOR_SHIMMER)
            for (OwnedWeapon& explosion : m_weapons)
                if (explosion.weapon.spellId == BONK_SPELL_ARCANE_EXPLOSION)
                {
                    explosion.timer = std::min(explosion.timer, BONK_BLINK_LAND_MS + BONK_SHIMMER_RECAST_MS);
                    explosion.pieResync = true;
                }
    }

    if (IsTalentBlinkDash())
        for (OwnedWeapon& explosion : m_weapons)
            if (explosion.weapon.spellId == BONK_SPELL_ARCANE_EXPLOSION)
            {
                explosion.timer = std::min(explosion.timer, BONK_BLINK_LAND_MS);
                explosion.pieResync = true;
            }

    if (HasBehavior(BONK_BEHAVIOR_ARCANE_POWER))
    {
        if (SpellAuraHolder* holder = m_player->AddAura(BONK_SPELL_ARCANE_POWER_AURA, ADD_AURA_POSITIVE))
        {
            holder->SetAuraDuration(BONK_ARCANE_POWER_MS);
            holder->SetAuraMaxDuration(BONK_ARCANE_POWER_MS);
            holder->UpdateAuraDuration();
        }
    }

    if (blink)
    {
        PendingCast chill;
        chill.weaponId = blink->weapon.id;
        chill.spellId = blink->weapon.spellId;
        chill.leftMs = BONK_BLINK_LAND_MS;
        chill.blinkChill = true;
        m_pendingCasts.push_back(chill);
    }

    for (OwnedWeapon const& owned : m_weapons)
        if (owned.weapon.HasFlag(BONK_WEAPON_FLAG_ON_BLINK))
        {
            PendingCast landing;
            landing.weaponId = owned.weapon.id;
            landing.spellId = owned.weapon.spellId;
            landing.leftMs = BONK_BLINK_LAND_MS;
            landing.blinkLanding = true;
            m_pendingCasts.push_back(landing);
        }
}

void BonkRun::ChillBlinkLanding(OwnedWeapon const& blink)
{
    for (Creature* mob : GetMobsInRange(GetWeaponRadius(blink)))
        if (mob->IsAlive())
            ApplyWeaponKeyword(blink, mob, BONK_KEYWORD_CHILL, BONK_BLINK_CHILL);
    ReduceTimer(BONK_WEAPON_FROST_NOVA, BONK_BLINK_NOVA_RESET_MS);
}

void BonkRun::LandBlink(OwnedWeapon& owned)
{
    if (owned.weapon.IsArcaneMissiles())
    {
        uint32 banked = 0;
        if (owned.weapon.behavior == BONK_BEHAVIOR_ARCANE_BARRAGE)
            std::swap(banked, m_bankedMissiles);
        FireMissileVolley(owned, banked);
    }
    else if (owned.weapon.target == BONK_TARGET_SELF_AREA)
        if (SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(owned.weapon.spellId))
            CastSelfArea(owned, spellInfo, GetWeaponArea(owned));
}

void BonkRun::ResolveMageCast(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    if (cast.blinkLanding)
        LandBlink(owned);
    else if (cast.blinkChill)
        ChillBlinkLanding(owned);
    else if (cast.pyroblastSplash)
        SplashPyroblast(owned, spellInfo, cast);
    else if (cast.iceShard)
        BounceIceShard(owned, spellInfo, cast);
    else if (cast.frostShatter)
        ShatterFrozen(owned, spellInfo, cast);
    else if (cast.livingBomb)
        ExplodeLivingBomb(owned, spellInfo, cast);
    else if (cast.meteor)
        LandMeteor(owned, spellInfo, cast);
    else if (cast.phaseRush)
        RushThrough(owned, spellInfo, cast);
    else if (cast.presenceOfMind)
        CastPresenceOfMind(owned);
}

void BonkRun::QueueMissiles(OwnedWeapon const& owned, SpellEntry const* spellInfo, Creature* target, float share)
{
    uint32 const missiles = uint32(std::max(1.0f, owned.weapon.behaviorValue));
    for (uint32 missile = 1; missile < missiles; ++missile)
    {
        PendingCast follow;
        follow.weaponId = owned.weapon.id;
        follow.spellId = spellInfo->Id;
        follow.leftMs = int32(missile * BONK_MISSILE_INTERVAL_MS);
        follow.target = target->GetObjectGuid();
        follow.strike = true;
        follow.share = share;
        follow.arcaneEcho = missile + 1 == missiles && m_mastery.Special(BONK_SPECIAL_ARCANE_ECHO) > 0.0f;
        m_pendingCasts.push_back(follow);
    }
}

void BonkRun::FireMissileVolley(OwnedWeapon& owned, uint32 extraMissiles)
{
    SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(owned.weapon.spellId);
    if (!spellInfo)
        return;
    std::vector<Creature*> mobs = GetMobsInRange(GetStrikeRange(owned));
    KeepInSight(m_player, mobs);
    if (mobs.empty())
        return;

    uint32 const missiles = uint32(std::max(1.0f, owned.weapon.behaviorValue)) + extraMissiles;
    FiringWeapon firing(m_player->GetBonkPlayer());
    for (uint32 missile = 0; missile < missiles; ++missile)
    {
        Creature* target = mobs[missile % mobs.size()];
        if (target->IsAlive())
            StrikeWith(owned, spellInfo, target, 1.0f, true);
    }
}

void BonkRun::BankMissiles(OwnedWeapon const& owned)
{
    uint32 const missiles = uint32(std::max(1.0f, owned.weapon.behaviorValue)) * GetWeaponTargets(owned);
    m_bankedMissiles = std::min(m_bankedMissiles + missiles, BONK_MAX_BANKED_MISSILES);
}

void BonkRun::SortMostBurningFirst(std::vector<Creature*>& mobs) const
{
    std::vector<std::pair<uint32, Creature*>> ranked;
    ranked.reserve(mobs.size());
    for (Creature* mob : mobs)
        ranked.emplace_back(GetKeywordStacks(mob, BONK_KEYWORD_BURNING), mob);
    std::stable_sort(ranked.begin(), ranked.end(), [](auto const& a, auto const& b) { return a.first > b.first; });
    for (size_t i = 0; i < ranked.size(); ++i)
        mobs[i] = ranked[i].second;
}

bool BonkRun::HurlPyroblasts(OwnedWeapon& owned, SpellEntry const* spellInfo, std::vector<Creature*> mobs)
{
    KeepInSight(m_player, mobs);
    if (mobs.empty())
        return false;
    if (owned.weapon.behavior == BONK_BEHAVIOR_METEOR)
        return DropMeteors(owned, spellInfo, mobs);
    if (owned.weapon.behavior == BONK_BEHAVIOR_METEOR_SHOWER)
        return RainMeteors(owned, spellInfo, mobs);

    uint32 const shots = GetWeaponTargets(owned);
    std::vector<Creature*> aims;
    for (Creature* mob : mobs)
        if (IsBigEnemy(mob))
            aims.push_back(mob);
    SortStrongestFirst(aims);
    if (aims.size() > shots)
        aims.resize(shots);
    if (aims.size() < shots)
        for (Creature* center : PickGroupCenters(mobs, BONK_PYROBLAST_SPLASH_RADIUS, shots))
            if (aims.size() < shots && std::find(aims.begin(), aims.end(), center) == aims.end())
                aims.push_back(center);

    FiringWeapon firing(m_player->GetBonkPlayer());
    for (Creature* aim : aims)
    {
        StrikeWith(owned, spellInfo, aim, 1.0f);

        PendingCast splash;
        splash.weaponId = owned.weapon.id;
        splash.spellId = spellInfo->Id;
        splash.leftMs = int32(std::max(1u, GetMissileDelay(m_player, aim, spellInfo->speed)));
        splash.target = aim->GetObjectGuid();
        aim->GetPosition(splash.x, splash.y, splash.z);
        splash.share = owned.weapon.altDamage;
        splash.pyroblastSplash = true;
        m_pendingCasts.push_back(splash);
    }
    return true;
}

void BonkRun::SplashPyroblast(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    float x = cast.x, y = cast.y;
    if (Creature* aim = m_player->GetMap()->GetCreature(cast.target))
        if (aim->IsAlive())
        {
            x = aim->GetPositionX();
            y = aim->GetPositionY();
        }

    float const damage = GetWeaponDamage(owned) * cast.share;
    float const radius = GetWeaponRadius(owned);
    FiringWeapon firing(m_player->GetBonkPlayer());
    uint32 const burning = uint32(m_mastery.Special(BONK_SPECIAL_PYROCLASM_BURNING));
    for (Creature* mob : GetMobsNear(x, y, radius))
        if (mob->GetObjectGuid() != cast.target)
        {
            DealSpellHit(spellInfo, mob, damage);
            if (burning)
                ApplyKeyword(mob, BONK_KEYWORD_BURNING, burning, 0, 1.0f, spellInfo->Id);
        }
}

Creature* BonkRun::PickHydraHeadTarget(BonkPetFamily const& family, Creature* pet, Creature* prey, size_t head, float range) const
{
    if (family.id != BONK_PET_FAMILY_HYDRA || head == 0)
        return prey;
    std::vector<Creature*> others = GetMobsNear(prey->GetPositionX(), prey->GetPositionY(), range);
    others.erase(std::remove_if(others.begin(), others.end(), [pet, prey, range](Creature* mob)
    {
        return mob == prey || !pet->IsWithinDistInMap(mob, range) || !pet->IsWithinLOSInMap(mob);
    }), others.end());
    if (others.empty())
        return prey;
    return others[(head - 1) % others.size()];
}

uint32 BonkRun::GetElementalFamily() const
{
    for (OwnedWeapon const& owned : m_weapons)
        if (owned.weapon.behavior == BONK_BEHAVIOR_PET)
        {
            if (owned.weapon.HasFlag(BONK_WEAPON_FLAG_HYDRA))
                return BONK_PET_FAMILY_HYDRA;
            if (owned.weapon.HasFlag(BONK_WEAPON_FLAG_ELEMENTAL_SHIFT))
                return GetElementalFamilyOf(MageSchool((m_totalMs / BONK_ELEMENTAL_SHIFT_MS) % uint32(MageSchool::Count)));
        }

    uint32 counts[size_t(MageSchool::Count)] = {};
    MageSchool order[size_t(MageSchool::Count)] = {};
    size_t seen = 0;
    for (OwnedWeapon const& owned : m_weapons)
    {
        MageSchool school;
        if (owned.weapon.behavior == BONK_BEHAVIOR_PET || !GetMageSchool(sSpellMgr.GetSpellEntry(owned.weapon.spellId), school))
            continue;
        if (!counts[size_t(school)]++)
            order[seen++] = school;
    }
    if (!seen)
        return BONK_PET_FAMILY_WATER_ELEMENTAL;

    MageSchool best = order[0];
    for (size_t i = 1; i < seen; ++i)
        if (counts[size_t(order[i])] > counts[size_t(best)])
            best = order[i];
    return GetElementalFamilyOf(best);
}

void BonkRun::ResetMageState()
{
    m_frostStorms.clear();
    m_frostboltTargets.clear();
    m_iceBarrierCast = 0;
    m_iceBarrierGiven = 0.0f;
    m_wildfires.clear();
    m_wildfireMs = 0;
    m_hotStreakCast = 0;
    ClearTimeBubbles();
    m_timeBubbleSlowMs = 0;
    m_presenceOfMindMs = 0;
    m_bankedMissiles = 0;
    m_player->RemoveAurasDueToSpell(BONK_SPELL_ARCANE_POWER_AURA);
    m_shiftFamily = 0;
}

void BonkRun::UpdateMage(uint32 diff)
{
    SpreadWildfire(diff);
    UpdateTimeBubbles(diff);
    UpdateElementalShift();
    ReplantHydras();
    ShowHeroLook(BonkHeroLook::ArcanePower, GetArcanePowerMultiplier() > 1.0f);
    ShowHeroLook(BonkHeroLook::PhaseRush, HasBehavior(BONK_BEHAVIOR_PHASE_RUSH) && m_player->GetBonkPlayer()->IsDashInvulnerable());
}

void BonkRun::OnMageStrike(OwnedWeapon& owned, SpellEntry const* spellInfo, Creature* target, float share, Unit const* from)
{
    if (owned.weapon.spellId == BONK_SPELL_FROSTBOLT)
        NoteFrostboltTarget(target);

    switch (owned.weapon.behavior)
    {
        case BONK_BEHAVIOR_ICE_SHARDS:
            QueueIceShard(owned, spellInfo, target, from, share, {}, BONK_ICE_SHARD_HOPS);
            break;
        case BONK_BEHAVIOR_FROST_SHATTER:
            if (IsFrozen(target))
            {
                PendingCast shatter;
                shatter.weaponId = owned.weapon.id;
                shatter.spellId = spellInfo->Id;
                shatter.leftMs = int32(std::max(1u, GetMissileDelay(from, target, spellInfo->speed)));
                shatter.frostShatter = true;
                shatter.share = share;
                shatter.target = target->GetObjectGuid();
                target->GetPosition(shatter.x, shatter.y, shatter.z);
                m_pendingCasts.push_back(shatter);
            }
            break;
        case BONK_BEHAVIOR_WILDFIRE:
            KindleWildfire(owned, target);
            break;
        case BONK_BEHAVIOR_LIVING_BOMB:
            PlantLivingBomb(owned, spellInfo, target, from);
            break;
        default:
            break;
    }
}

void BonkRun::OnMageSelfArea(OwnedWeapon& owned)
{
    switch (owned.weapon.behavior)
    {
        case BONK_BEHAVIOR_BLAST_WAVE:
            if (SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(owned.weapon.spellId))
                EruptBurning(owned, spellInfo);
            break;
        case BONK_BEHAVIOR_SLOW_TIME:
            LeaveTimeBubble(owned);
            break;
        case BONK_BEHAVIOR_PRESENCE_OF_MIND:
            QueuePresenceOfMind(owned);
            break;
        default:
            break;
    }
}

void BonkRun::OnMageGroundDrop(OwnedWeapon const& owned, float x, float y, float z)
{
    switch (owned.weapon.behavior)
    {
        case BONK_BEHAVIOR_DEEP_FREEZE:
        case BONK_BEHAVIOR_FROSTBITE:
            AddFrostStorm(owned, x, y);
            break;
        case BONK_BEHAVIOR_BURNING_GROUND:
            StartKeywordCloud(owned, x, y, z);
            break;
        default:
            break;
    }
}

bool BonkRun::GetMageCloudKind(OwnedWeapon const& owned, KeywordCloudKind& kind) const
{
    switch (owned.weapon.behavior)
    {
        case BONK_BEHAVIOR_BURNING_GROUND:
            kind.lifeMs = BONK_BURNING_GROUND_MS;
            kind.maxAlive = BONK_MAX_BURNING_GROUNDS;
            break;
        case BONK_BEHAVIOR_METEOR:
            kind.lifeMs = BONK_CRATER_MS;
            kind.maxAlive = BONK_MAX_CRATERS;
            break;
        default:
            return false;
    }
    kind.pulseEveryMs = BONK_FIRE_CLOUD_PULSE_MS;
    kind.stacks = BONK_FIRE_CLOUD_STACKS;
    kind.lookSpellId = owned.weapon.behavior == BONK_BEHAVIOR_METEOR ? 0 : BONK_SPELL_BURNING_GROUND_LOOK;
    return true;
}

void BonkRun::NoteFrostboltTarget(Creature* target)
{
    ObjectGuid const guid = target->GetObjectGuid();
    m_frostboltTargets.erase(std::remove(m_frostboltTargets.begin(), m_frostboltTargets.end(), guid), m_frostboltTargets.end());
    m_frostboltTargets.push_back(guid);
    if (m_frostboltTargets.size() > BONK_MAX_FROSTBOLT_TARGETS)
        m_frostboltTargets.erase(m_frostboltTargets.begin());
}

void BonkRun::QueueIceShard(OwnedWeapon const& owned, SpellEntry const* spellInfo, Creature* target, Unit const* from, float share,
    std::vector<ObjectGuid> struck, uint32 hops)
{
    if (!hops)
        return;

    struck.push_back(target->GetObjectGuid());
    PendingCast hop;
    hop.weaponId = owned.weapon.id;
    hop.spellId = spellInfo->Id;
    hop.leftMs = GetBounceDelay(from, target, spellInfo->speed);
    hop.iceShard = true;
    hop.hops = hops;
    hop.share = share;
    hop.target = target->GetObjectGuid();
    target->GetPosition(hop.x, hop.y, hop.z);
    hop.source = HoldShotSource(hop.x, hop.y, hop.z);
    hop.struck = std::move(struck);
    m_pendingCasts.push_back(std::move(hop));
}

void BonkRun::BounceIceShard(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    float x = cast.x, y = cast.y, z = cast.z;
    Creature* last = m_player->GetMap()->GetCreature(cast.target);
    if (last)
        last->GetPosition(x, y, z);

    Creature* source = ReleaseShotSource(cast.source, x, y, z);
    Creature* next = source ? PickFrozenBounce(source, cast.struck) : nullptr;
    if (!next)
        return;

    StrikeFromMob(owned, spellInfo, next, cast.share, source, last);
    NoteFrostboltTarget(next);
    QueueIceShard(owned, spellInfo, next, source, cast.share, cast.struck, cast.hops - 1);
}

Creature* BonkRun::PickFrozenBounce(WorldObject const* from, std::vector<ObjectGuid> const& struck) const
{
    for (Creature* mob : GetMobsInRange(BONK_ICE_SHARD_RANGE, from))
        if (IsFrozen(mob) && std::find(struck.begin(), struck.end(), mob->GetObjectGuid()) == struck.end() && from->IsWithinLOSInMap(mob))
            return mob;
    return nullptr;
}

void BonkRun::ShatterFrozen(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    float x = cast.x, y = cast.y, z = cast.z;
    if (Creature* target = m_player->GetMap()->GetCreature(cast.target))
        if (target->IsAlive())
            target->GetPosition(x, y, z);

    PlayKitAt(ObjectGuid(), x, y, z, BONK_KIT_FROST_NOVA, true);
    float const damage = GetWeaponDamage(owned) * cast.share;
    FiringWeapon firing(m_player->GetBonkPlayer());
    for (Creature* mob : GetMobsNear(x, y, GetWeaponRadius(owned)))
        if (mob->GetObjectGuid() != cast.target)
            DealSpellHit(spellInfo, mob, damage);
}

void BonkRun::AddFrostStorm(OwnedWeapon const& owned, float x, float y)
{
    if (m_frostStorms.size() >= BONK_MAX_FROST_STORMS)
        m_frostStorms.erase(m_frostStorms.begin());

    FrostStorm storm;
    storm.weaponId = owned.weapon.id;
    storm.x = x;
    storm.y = y;
    storm.radius = owned.weapon.groundRadius * GetWeaponArea(owned);
    storm.untilMs = WorldTimer::getMSTime() + uint32(owned.weapon.durationMs * GetWeaponDurationScale(owned));
    m_frostStorms.push_back(storm);
}

void BonkRun::OnFrozen(Creature* mob, uint32 sourceSpellId)
{
    if (m_state != STATE_RUNNING || !mob->IsAlive())
        return;

    if (OwnedWeapon const* source = sourceSpellId ? FindOwnedBySpell(sourceSpellId) : nullptr)
        if (source->weapon.behavior == BONK_BEHAVIOR_ICE_BARRIER)
            GainIceBarrier(*source);

    if (m_frostStorms.empty())
        return;
    uint32 const now = WorldTimer::getMSTime();
    m_frostStorms.erase(std::remove_if(m_frostStorms.begin(), m_frostStorms.end(), [now](FrostStorm const& storm)
    {
        return int32(storm.untilMs - now) <= 0;
    }), m_frostStorms.end());

    for (FrostStorm const& storm : m_frostStorms)
    {
        OwnedWeapon const* owned = FindOwned(storm.weaponId);
        if (!owned || mob->GetDistance2d(storm.x, storm.y) > storm.radius)
            continue;
        if (owned->weapon.behavior == BONK_BEHAVIOR_DEEP_FREEZE)
            DeepFreeze(mob, storm);
        else
            Frostbite(mob, *owned);
        return;
    }
}

void BonkRun::DeepFreeze(Creature* mob, FrostStorm const& storm)
{
    uint32 const now = WorldTimer::getMSTime();
    uint32 const hold = std::min(storm.untilMs - now, BONK_DEEP_FREEZE_MAX_MS);
    CrowdControl& control = m_crowdControl[mob->GetObjectGuid()];
    if (int32(now + hold - control.shatterUntil) <= 0)
        return;

    control.shatterUntil = now + hold;
    control.frozenImmuneUntil = control.shatterUntil + BONK_FREEZE_IMMUNE_MS;
    if (BonkKeywordInfo const* frozen = sBonkMgr.GetKeyword(BONK_KEYWORD_FROZEN))
        if (SpellAuraHolder* holder = mob->GetSpellAuraHolder(frozen->spellId, m_player->GetObjectGuid()))
        {
            holder->SetAuraMaxDuration(int32(hold));
            holder->RefreshHolder();
        }
    mob->SendPlaySpellVisualKit(BONK_KIT_DEEP_FREEZE);
}

void BonkRun::Frostbite(Creature* mob, OwnedWeapon const& owned)
{
    SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(owned.weapon.spellId);
    if (!spellInfo)
        return;
    mob->SendPlaySpellVisualKit(BONK_KIT_FROSTBITE);
    DealExactHit(spellInfo, mob, std::max(1u, uint32(mob->GetMaxHealth() * GetFrostbitePercent(mob) / 100.0f)));
}

void BonkRun::GainIceBarrier(OwnedWeapon const& owned)
{
    SupportScope scope(*this, WeaponSupport(owned));
    if (!m_player->IsAlive())
        return;
    if (m_iceBarrierCast != owned.casts)
    {
        m_iceBarrierCast = owned.casts;
        m_iceBarrierGiven = 0.0f;
    }

    float const size = 1.0f + GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_SHIELD_SIZE) / 100.0f;
    float const gain = std::min(BONK_ICE_BARRIER_PER_FREEZE * size, BONK_ICE_BARRIER_MAX * size - m_iceBarrierGiven);
    if (gain <= 0.0f)
        return;
    if (m_iceBarrierGiven <= 0.0f)
        m_player->SendPlaySpellVisualKit(BONK_KIT_ICE_BARRIER);
    m_iceBarrierGiven += gain;
    AddSpellShield(uint32(m_player->GetMaxHealth() * gain / 100.0f));
}

bool BonkRun::BurstIceNovas(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    uint32 const novas = 1 + std::min(GetSpellCount(owned), BONK_MAX_COUNT_PULSES);
    std::vector<Creature*> centers;
    Map* map = m_player->GetMap();
    for (auto itr = m_frostboltTargets.rbegin(); itr != m_frostboltTargets.rend() && centers.size() < novas; ++itr)
        if (Creature* mob = map->GetCreature(*itr))
            if (mob->IsAlive() && m_player->IsWithinDistInMap(mob, BONK_ICE_NOVA_REACH))
                centers.push_back(mob);
    if (centers.size() < novas)
        for (Creature* mob : GetMobsInRange(BONK_ICE_NOVA_REACH))
            if (centers.size() < novas && std::find(centers.begin(), centers.end(), mob) == centers.end() && m_player->IsWithinLOSInMap(mob))
                centers.push_back(mob);
    if (centers.empty())
        return false;

    ++owned.casts;
    for (Creature* center : centers)
        BurstIceNova(owned, spellInfo, center);
    return true;
}

void BonkRun::BurstIceNova(OwnedWeapon& owned, SpellEntry const* spellInfo, Creature* center)
{
    float x, y, z;
    center->GetPosition(x, y, z);
    PlayKitAt(ObjectGuid(), x, y, z, BONK_KIT_FROST_NOVA, true);

    float const damage = GetWeaponDamage(owned);
    float const twice = GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_HIT_TWICE);
    std::vector<Creature*> caught = GetMobsNear(x, y, GetWeaponRadius(owned));
    FiringWeapon firing(m_player->GetBonkPlayer());
    for (Creature* mob : caught)
    {
        DealSpellHit(spellInfo, mob, damage);
        if (twice > 0.0f && roll_chance_f(twice))
            DealSpellHit(spellInfo, mob, damage);
    }
}

void BonkRun::KindleWildfire(OwnedWeapon const& owned, Creature* target)
{
    uint32 const until = m_totalMs + BONK_WILDFIRE_MS;
    for (Wildfire& fire : m_wildfires)
        if (fire.guid == target->GetObjectGuid())
        {
            fire.weaponId = owned.weapon.id;
            fire.untilMs = until;
            return;
        }
    if (m_wildfires.size() >= BONK_MAX_WILDFIRES)
        m_wildfires.erase(m_wildfires.begin());

    Wildfire fire;
    fire.guid = target->GetObjectGuid();
    fire.weaponId = owned.weapon.id;
    fire.untilMs = until;
    m_wildfires.push_back(fire);
}

void BonkRun::SpreadWildfire(uint32 diff)
{
    if (m_wildfires.empty())
        return;
    m_wildfireMs -= int32(diff);
    if (m_wildfireMs > 0)
        return;

    OwnedWeapon const* owned = FindOwnedByBehavior(BONK_BEHAVIOR_WILDFIRE);
    PendingKeyword burning;
    if (!owned || !GetWeaponKeyword(*owned, burning))
    {
        m_wildfires.clear();
        return;
    }
    m_wildfireMs = std::max(BONK_MIN_WILDFIRE_PULSE_MS, int32(BONK_WILDFIRE_PULSE_MS / GetWeaponHasteRate(*owned)));

    SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_WILDFIRE_LOOK);
    float const reach = GetWeaponRadius(*owned);
    Map* map = m_player->GetMap();
    std::vector<Creature*> sources;
    m_wildfires.erase(std::remove_if(m_wildfires.begin(), m_wildfires.end(), [&](Wildfire const& fire)
    {
        Creature* source = map->GetCreature(fire.guid);
        if (!source || !source->IsAlive() || int32(fire.untilMs - m_totalMs) <= 0)
            return true;
        sources.push_back(source);
        return false;
    }), m_wildfires.end());

    for (Creature* source : sources)
    {
        if (!GetKeywordStacks(source, BONK_KEYWORD_BURNING))
            continue;
        for (Creature* mob : GetMobsInRange(reach, source))
            if (!GetKeywordStacks(mob, BONK_KEYWORD_BURNING))
            {
                if (look)
                    ShowStrike(source, look, mob);
                ApplyKeyword(mob, burning.keyword, burning.stacks, burning.durationMs, burning.damageScale, burning.spellId);
                break;
            }
    }
}

void BonkRun::PlantLivingBomb(OwnedWeapon const& owned, SpellEntry const* spellInfo, Creature* target, Unit const* from)
{
    auto const bombs = std::count_if(m_pendingCasts.begin(), m_pendingCasts.end(), [](PendingCast const& cast) { return cast.livingBomb; });
    if (size_t(bombs) >= BONK_MAX_LIVING_BOMBS)
        return;

    int32 const flight = int32(std::max(1u, GetMissileDelay(from, target, spellInfo->speed)));
    PendingCast plant;
    plant.kit = BONK_KIT_LIVING_BOMB_PLANT;
    plant.leftMs = flight;
    plant.target = target->GetObjectGuid();
    target->GetPosition(plant.x, plant.y, plant.z);
    m_pendingCasts.push_back(plant);

    PendingCast bomb = plant;
    bomb.kit = 0;
    bomb.weaponId = owned.weapon.id;
    bomb.spellId = spellInfo->Id;
    bomb.leftMs = flight + BONK_LIVING_BOMB_MS;
    bomb.livingBomb = true;
    m_pendingCasts.push_back(std::move(bomb));
}

void BonkRun::ExplodeLivingBomb(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    float x = cast.x, y = cast.y, z = cast.z;
    if (Creature* target = m_player->GetMap()->GetCreature(cast.target))
        if (target->IsAlive())
            target->GetPosition(x, y, z);

    PlayKitAt(cast.target, x, y, z, BONK_KIT_LIVING_BOMB_BLAST, true);
    float const damage = GetWeaponDamage(owned) * BONK_LIVING_BOMB_SHARE;
    FiringWeapon firing(m_player->GetBonkPlayer());
    for (Creature* mob : GetMobsNear(x, y, GetWeaponRadius(owned)))
        DealSpellHit(spellInfo, mob, damage);
}

void BonkRun::WalkFire(OwnedWeapon const& owned, SpellEntry const* spellInfo, float x, float y, float z, float radius)
{
    float const angle = m_player->GetAngle(x, y);
    float const step = radius * BONK_FIREWALK_STEP;
    Map* map = m_player->GetMap();
    for (uint32 i = 0; i < BONK_FIREWALK_PILLARS; ++i)
    {
        float const offset = (float(i) - float(BONK_FIREWALK_PILLARS - 1) / 2.0f) * step;
        PendingCast pillar;
        pillar.weaponId = owned.weapon.id;
        pillar.spellId = spellInfo->Id;
        pillar.leftMs = int32(i) * BONK_FIREWALK_GAP_MS;
        pillar.x = x + offset * std::cos(angle);
        pillar.y = y + offset * std::sin(angle);
        pillar.z = z;
        map->GetWalkHitPosition(nullptr, x, y, z, pillar.x, pillar.y, pillar.z);
        m_pendingCasts.push_back(pillar);
    }
}

bool BonkRun::DropMeteors(OwnedWeapon& owned, SpellEntry const* spellInfo, std::vector<Creature*> const& mobs)
{
    float const radius = GetWeaponRadius(owned);
    std::vector<Creature*> const aims = PickGroupCenters(mobs, radius, GetWeaponTargets(owned));
    for (Creature* aim : aims)
        QueueMeteor(owned, spellInfo, aim, BONK_METEOR_SHARE, radius, false);
    return !aims.empty();
}

bool BonkRun::RainMeteors(OwnedWeapon& owned, SpellEntry const* spellInfo, std::vector<Creature*> const& mobs)
{
    std::vector<Creature*> const centers = PickGroupCenters(mobs, BONK_METEOR_SHOWER_SPREAD, 1);
    if (centers.empty())
        return false;

    float const area = GetWeaponArea(owned);
    std::vector<Creature*> spots = GetMobsInRange(BONK_METEOR_SHOWER_SPREAD * area, centers.front());
    spots.insert(spots.begin(), centers.front());
    SortMostBurningFirst(spots);
    uint32 const meteors = BONK_METEOR_SHOWER_COUNT + std::min(GetSpellCount(owned), BONK_MAX_COUNT_PULSES);
    if (spots.size() > meteors)
        spots.resize(meteors);
    for (Creature* spot : spots)
        QueueMeteor(owned, spellInfo, spot, BONK_METEOR_SHOWER_SHARE, GetWeaponRadius(owned), true);
    return true;
}

void BonkRun::QueueMeteor(OwnedWeapon const& owned, SpellEntry const* spellInfo, Creature* aim, float share, float radius, bool shower)
{
    PendingCast meteor;
    meteor.weaponId = owned.weapon.id;
    meteor.spellId = spellInfo->Id;
    meteor.leftMs = BONK_METEOR_FALL_MS;
    meteor.meteor = true;
    meteor.meteorShower = shower;
    meteor.share = share;
    meteor.radius = radius;
    aim->GetPosition(meteor.x, meteor.y, meteor.z);
    if (SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_METEOR_LOOK))
        ShowFallingAt(look, meteor.x, meteor.y, meteor.z);
    m_pendingCasts.push_back(meteor);
}

void BonkRun::LandMeteor(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    float const damage = GetWeaponDamage(owned) * cast.share;
    FiringWeapon firing(m_player->GetBonkPlayer());
    for (Creature* mob : GetMobsNear(cast.x, cast.y, cast.radius))
    {
        float scale = 1.0f;
        if (cast.meteorShower)
            scale += BONK_METEOR_SHOWER_PER_BURN * std::min(GetKeywordStacks(mob, BONK_KEYWORD_BURNING), BONK_MAX_BURNING_COUNTED) / 100.0f;
        DealSpellHit(spellInfo, mob, damage * scale);
    }
    if (!cast.meteorShower)
        StartKeywordCloud(owned, cast.x, cast.y, cast.z);
}

void BonkRun::EruptBurning(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    m_player->SendPlaySpellVisualKit(BONK_KIT_BLAST_WAVE);
    float const area = GetWeaponArea(owned);
    std::vector<Creature*> burning;
    for (Creature* mob : GetMobsInRange(owned.weapon.radius * area))
        if (GetKeywordStacks(mob, BONK_KEYWORD_BURNING))
            burning.push_back(mob);
    if (burning.size() > BONK_MAX_ERUPTIONS)
        burning.resize(BONK_MAX_ERUPTIONS);

    float const damage = GetWeaponDamage(owned) * BONK_ERUPTION_SHARE;
    FiringWeapon firing(m_player->GetBonkPlayer());
    for (Creature* source : burning)
    {
        if (!source->IsAlive())
            continue;
        source->SendPlaySpellVisualKit(BONK_KIT_ERUPTION);
        std::vector<Creature*> struck = GetMobsInRange(BONK_ERUPTION_RADIUS * area, source);
        if (struck.size() > BONK_ERUPTION_TARGETS)
            struck.resize(BONK_ERUPTION_TARGETS);
        for (Creature* mob : struck)
            DealSpellHit(spellInfo, mob, damage);
    }
}

void BonkRun::TriggerHotStreak(OwnedWeapon const& hotStreak, Creature* target)
{
    if (m_hotStreakCast == hotStreak.casts || !m_player->IsAlive())
        return;
    m_hotStreakCast = hotStreak.casts;
    m_player->SendPlaySpellVisualKit(BONK_KIT_HOT_STREAK);

    for (OwnedWeapon& owned : m_weapons)
        if (owned.weapon.IsPyroblast())
        {
            owned.timer = 0;
            owned.pieResync = true;
            return;
        }

    OwnedWeapon* owned = FindOwned(hotStreak.weapon.id);
    SpellEntry const* pyroblast = sSpellMgr.GetSpellEntry(BONK_SPELL_PYROBLAST);
    if (!owned || !pyroblast || !target->IsAlive())
        return;
    FiringWeapon firing(m_player->GetBonkPlayer());
    StrikeWith(*owned, pyroblast, target, BONK_HOT_STREAK_SHARE, true);
}

void BonkRun::RushThrough(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    float x, y, z;
    m_player->GetPosition(x, y, z);
    float const width = BONK_PHASE_RUSH_WIDTH * GetWeaponArea(owned);
    float const halfLength = std::sqrt((x - cast.x) * (x - cast.x) + (y - cast.y) * (y - cast.y)) / 2.0f;
    float const damage = GetWeaponDamage(owned);
    FiringWeapon firing(m_player->GetBonkPlayer());
    for (Creature* mob : GetMobsNear((x + cast.x) / 2.0f, (y + cast.y) / 2.0f, halfLength + width + BONK_PHASE_RUSH_WIDTH))
        if (DistanceToSegment(mob->GetPositionX(), mob->GetPositionY(), cast.x, cast.y, x, y) <= width + mob->GetObjectBoundingRadius())
        {
            mob->SendPlaySpellVisualKit(BONK_KIT_PHASE_RUSH_HIT);
            DealSpellHit(spellInfo, mob, damage);
        }
}

void BonkRun::LeaveTimeBubble(OwnedWeapon const& owned)
{
    if (!m_timeBubbles.empty())
        return;

    float x, y, z;
    m_player->GetPosition(x, y, z);
    float const radius = GetWeaponRadius(owned);
    uint32 const untilMs = m_totalMs + uint32(BONK_TIME_BUBBLE_MS * GetWeaponDurationScale(owned));

    TimeBubble bubble;
    bubble.x = x;
    bubble.y = y;
    bubble.radius = radius;
    bubble.untilMs = untilMs;
    bubble.markKey = NextBonkAuraKey();
    SendBonkMark(m_player, "bubble" + std::to_string(bubble.markKey), BONK_TELEGRAPH_CIRCLE, x, y, z, 0.0f, radius, 0, true,
        GetRingStyle(BonkHeroRing::TimeBubble));
    m_timeBubbles.push_back(bubble);
}

void BonkRun::EndTimeBubble(TimeBubble const& bubble)
{
    if (bubble.markKey)
        SendBonkUnmark(m_player, "bubble" + std::to_string(bubble.markKey));
}

void BonkRun::ClearTimeBubbles()
{
    for (TimeBubble const& bubble : m_timeBubbles)
        EndTimeBubble(bubble);
    m_timeBubbles.clear();
}

void BonkRun::UpdateTimeBubbles(uint32 diff)
{
    if (m_timeBubbles.empty())
        return;
    m_timeBubbles.erase(std::remove_if(m_timeBubbles.begin(), m_timeBubbles.end(), [this](TimeBubble const& bubble)
    {
        if (int32(bubble.untilMs - m_totalMs) > 0)
            return false;
        EndTimeBubble(bubble);
        return true;
    }), m_timeBubbles.end());

    m_timeBubbleSlowMs -= int32(diff);
    if (m_timeBubbleSlowMs > 0 || m_timeBubbles.empty())
        return;
    m_timeBubbleSlowMs = BONK_TIME_BUBBLE_PULSE_MS;

    SpellEntry const* slow = sSpellMgr.GetSpellEntry(BONK_SPELL_TIME_SLOW);
    if (!slow)
        return;
    int32 const points = BONK_TIME_BUBBLE_SLOW;
    for (TimeBubble const& bubble : m_timeBubbles)
        for (Creature* mob : GetMobsNear(bubble.x, bubble.y, bubble.radius))
            SlowNormalMob(mob, slow, &points, BONK_TIME_BUBBLE_SLOW_MS);
}

float BonkRun::GetTimeBubbleMultiplier(Unit const* victim) const
{
    if (!victim)
        return 1.0f;
    for (TimeBubble const& bubble : m_timeBubbles)
        if (int32(bubble.untilMs - m_totalMs) > 0 && victim->GetDistance2d(bubble.x, bubble.y) <= bubble.radius)
            return BONK_TIME_BUBBLE_DAMAGE;
    return 1.0f;
}

float BonkRun::GetArcanePowerMultiplier() const
{
    return m_player->HasAura(BONK_SPELL_ARCANE_POWER_AURA) ? BONK_ARCANE_POWER_DAMAGE : 1.0f;
}

float BonkRun::GetMageDamageMultiplier(Unit const* victim) const
{
    return GetArcanePowerMultiplier() * GetTimeBubbleMultiplier(victim);
}

float BonkRun::GetMageSpellDamageMultiplier(SpellEntry const* spell, Unit const* victim) const
{
    if (!spell || !victim)
        return 1.0f;
    auto root = m_spellRoots.find(spell->Id);
    if (root != m_spellRoots.end() && root->second == BONK_WEAPON_ARCANE_MISSILES && IsChampion(victim))
        return BONK_MISSILES_CHAMPION_BONUS;
    if (spell->School == SPELL_SCHOOL_FROST && IsFrozen(victim) && IsInDeepFreeze(victim))
        return BONK_DEEP_FREEZE_FROST_BONUS;
    return 1.0f;
}

bool BonkRun::IsChampion(Unit const* victim) const
{
    Creature const* mob = victim->ToCreature();
    BonkMobAI const* ai = mob ? dynamic_cast<BonkMobAI const*>(mob->AI()) : nullptr;
    return ai && ai->GetKind() != BONK_SPAWN_NORMAL;
}

bool BonkRun::IsInDeepFreeze(Unit const* victim) const
{
    uint32 const now = WorldTimer::getMSTime();
    return std::any_of(m_frostStorms.begin(), m_frostStorms.end(), [&](FrostStorm const& storm)
    {
        OwnedWeapon const* owned = FindOwned(storm.weaponId);
        return owned && owned->weapon.behavior == BONK_BEHAVIOR_DEEP_FREEZE && int32(storm.untilMs - now) > 0 &&
            victim->GetDistance2d(storm.x, storm.y) <= storm.radius;
    });
}

void BonkRun::QueuePresenceOfMind(OwnedWeapon const& owned)
{
    if (int32(m_presenceOfMindMs - m_totalMs) > 0)
        return;
    m_presenceOfMindMs = m_totalMs + BONK_PRESENCE_OF_MIND_GAP_MS;

    PendingCast cast;
    cast.weaponId = owned.weapon.id;
    cast.spellId = owned.weapon.spellId;
    cast.presenceOfMind = true;
    m_pendingCasts.push_back(cast);
}

void BonkRun::CastPresenceOfMind(OwnedWeapon const& source)
{
    std::vector<OwnedWeapon*> choices;
    for (OwnedWeapon& other : m_weapons)
    {
        BonkWeapon const& weapon = other.weapon;
        if (&other == &source || weapon.behavior == BONK_BEHAVIOR_PET || weapon.behavior == BONK_BEHAVIOR_WRATH || weapon.IsTrigger() ||
            weapon.IsBlink() || weapon.IsShieldBlock() || weapon.behavior == BONK_BEHAVIOR_WARD || weapon.behavior == BONK_BEHAVIOR_BLOOD_AURA)
            continue;
        choices.push_back(&other);
    }
    if (choices.empty())
        return;

    OwnedWeapon& picked = *choices[urand(0, uint32(choices.size() - 1))];
    int32 const timer = picked.timer;
    FireWeapon(picked);
    picked.timer = timer;
}

bool BonkRun::GetPetAbilityKeyword(OwnedWeapon const& owned, BonkPetAbility const& ability, PendingKeyword& keyword) const
{
    MageSchool school;
    if (!GetMageSchool(sSpellMgr.GetSpellEntry(ability.spellId), school) || school == MageSchool::Arcane)
        return false;
    keyword.keyword = school == MageSchool::Frost ? BONK_KEYWORD_CHILL : BONK_KEYWORD_BURNING;
    BonkKeywordInfo const* info = sBonkMgr.GetKeyword(keyword.keyword);
    if (!info)
        return false;
    keyword.spellId = owned.weapon.spellId;
    keyword.stacks = ability.stacks;
    keyword.durationMs = uint32(info->durationMs * GetWeaponDurationScale(owned));
    keyword.damageScale = 1.0f + (owned.damageBonus + GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_PET_DAMAGE)) / 100.0f;
    return true;
}

void BonkRun::ReplantHydras()
{
    OwnedWeapon const* owned = FindOwnedByFlag(BONK_WEAPON_FLAG_HYDRA);
    if (!owned || !m_player->IsAlive())
        return;
    Map* map = m_player->GetMap();
    for (ObjectGuid const& guid : owned->pets)
        if (Creature* hydra = map->GetCreature(guid))
            if (hydra->IsAlive() && !hydra->IsWithinDistInMap(m_player, BONK_HYDRA_REPLANT_RANGE))
            {
                hydra->NearTeleportTo(m_player->GetPositionX(), m_player->GetPositionY(), m_player->GetPositionZ(), m_player->GetOrientation());
                hydra->SendPlaySpellVisualKit(BONK_KIT_ELEMENTAL_SHIFT);
            }
}

void BonkRun::PlantHydra(Creature* pet)
{
    if (pet->HasUnitState(UNIT_STATE_ROOT))
        return;
    pet->AddUnitState(UNIT_STATE_ROOT);
    pet->SetRooted(true);
}

void BonkRun::ShiftElemental(Creature* pet, uint32 entry)
{
    CreatureInfo const* info = sObjectMgr.GetCreatureTemplate(entry);
    uint32 const display = info ? info->display_id[0] : 0;
    if (!display || pet->GetDisplayId() == display)
        return;
    pet->SetDisplayId(display);
    pet->SetNativeDisplayId(display);
    pet->SendPlaySpellVisualKit(BONK_KIT_ELEMENTAL_SHIFT);
}

void BonkRun::UpdateElementalShift()
{
    OwnedWeapon const* found = FindOwnedByFlag(BONK_WEAPON_FLAG_ELEMENTAL_SHIFT);
    if (!found)
    {
        m_shiftFamily = 0;
        return;
    }
    uint32 const family = GetElementalFamily();
    if (family == m_shiftFamily)
        return;
    m_shiftFamily = family;
    if (OwnedWeapon* owned = FindOwned(found->weapon.id))
        UpdatePets(*owned);
}

void BonkRun::DealExactHit(SpellEntry const* spellInfo, Unit* target, uint32 damage, Unit* attacker)
{
    Unit* const dealer = attacker ? attacker : m_player;
    if (!spellInfo || !target || !target->IsAlive() || !damage || !dealer->IsAlive())
        return;
    SpellNonMeleeDamage hit(dealer, target, spellInfo->Id, SpellSchools(spellInfo->School));
    hit.damage = damage;
    dealer->DealDamageMods(target, hit.damage, &hit.absorb);
    dealer->SendSpellNonMeleeDamageLog(&hit);
    dealer->DealSpellDamage(&hit, true);
}

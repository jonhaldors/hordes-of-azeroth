#include "BonkRun.h"
#include "BonkMgr.h"
#include "BonkMobAI.h"
#include "Creature.h"
#include "Map.h"
#include "NullCreatureAI.h"
#include "Player.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "Utilities/Random.h"

#include <algorithm>
#include <iterator>
#include <set>

namespace
{
    uint32 const BONK_WEAPON_STARBURST           = 1014;
    uint32 const BONK_WEAPON_SHOOTING_STARS      = 1015;
    uint32 const BONK_WEAPON_SUNFIRE             = 1016;
    uint32 const BONK_WEAPON_FULL_MOON           = 1017;
    uint32 const BONK_WEAPON_TYPHOON             = 1018;
    uint32 const BONK_WEAPON_MOONSTORM           = 1019;
    uint32 const BONK_WEAPON_THRASH              = 1020;
    uint32 const BONK_WEAPON_TIGERS_FURY         = 1021;
    uint32 const BONK_WEAPON_MANGLE              = 1022;
    uint32 const BONK_WEAPON_FEROCIOUS_BITE      = 1023;
    uint32 const BONK_WEAPON_LACERATE            = 1024;
    uint32 const BONK_WEAPON_URSOLS_VORTEX       = 1025;
    uint32 const BONK_WEAPON_BLOODY_FRENZY       = 1026;
    uint32 const BONK_WEAPON_BARKSKIN            = 1027;
    uint32 const BONK_WEAPON_LIFEBLOOM           = 1028;
    uint32 const BONK_WEAPON_EFFLORESCENCE       = 1029;
    uint32 const BONK_WEAPON_ANCIENT_OF_WAR      = 1030;
    uint32 const BONK_WEAPON_FUNGAL_GROWTH       = 1031;
    uint32 const BONK_WEAPON_MASS_ENTANGLEMENT   = 1032;
    uint32 const BONK_WEAPON_STRANGLING_VINES    = 1033;
    uint32 const BONK_WEAPON_WIDENING_CALM       = 1034;
    uint32 const BONK_WEAPON_OVERGROWTH          = 1035;
    uint32 const BONK_WEAPON_BRAMBLES            = 1036;
    uint32 const BONK_WEAPON_NATURES_GRASP       = 1037;
    uint32 const BONK_WEAPON_SHIFTING_SURGE      = 1038;
    uint32 const BONK_WEAPON_SPIRIT_FORMS        = 1039;
    uint32 const BONK_WEAPON_MOONFIRE_SPELL      = 1002;

    uint32 const BONK_SPELL_MOONFIRE_LOOK        = 8921;
    uint32 const BONK_SPELL_STARFIRE_LOOK        = 2912;
    uint32 const BONK_SPELL_TIGERS_FURY_LOOK     = 5217;
    uint32 const BONK_SPELL_BARKSKIN_LOOK        = 22812;
    uint32 const BONK_SPELL_LASH_LOOK            = 5570;
    uint32 const BONK_SPELL_MAUL_LOOK            = 6807;
    uint32 const BONK_SPELL_ROOTS                = 339;
    uint32 const BONK_SPELL_SPIRIT_GLOW          = 25039;
    uint32 const BONK_KIT_STAR_BURST             = 3381;
    uint32 const BONK_KIT_TYPHOON                = 356;
    uint32 const BONK_KIT_BLOOM                  = 101;
    uint32 const BONK_KIT_GRASP                  = 542;
    uint32 const BONK_KIT_SPORE_BURST            = 6377;
    uint32 const BONK_KIT_SURGE_ROOTS            = 542;
    uint32 const BONK_DISPLAY_MUSHROOM           = 11686;

    float const BONK_STARBURST_SHARE             = 0.15f;
    uint32 const BONK_SHOOTING_STARS_POLL_MS     = 1000;
    float const BONK_SHOOTING_STARS_CHANCE       = 3.0f;
    uint32 const BONK_SHOOTING_STARS_MAX         = 2;
    float const BONK_SHOOTING_STARS_SHARE        = 0.5f;
    float const BONK_SHOOTING_STARS_RANGE        = 30.0f;
    size_t const BONK_SUNFIRE_SPREAD             = 3;
    uint32 const BONK_FULL_MOON_POLL_MS          = 250;
    uint32 const BONK_FULL_MOON_EVERY            = 10;
    float const BONK_FULL_MOON_SHARE             = 0.3f;
    float const BONK_FULL_MOON_RANGE             = 40.0f;
    int32 const BONK_VORTEX_PULSE_MS             = 1000;
    uint32 const BONK_VORTEX_MS                  = 3000;
    size_t const BONK_VORTEX_ALIVE               = 2;
    float const BONK_VORTEX_SHARE                = 0.5f;
    uint32 const BONK_SPELL_VORTEX_LOOK          = 16914;
    float const BONK_TYPHOON_SHARE               = 2.0f;
    float const BONK_TIGERS_FURY_PER_ENEMY       = 5.0f;
    float const BONK_TIGERS_FURY_MAX             = 25.0f;
    uint32 const BONK_TIGERS_FURY_MS             = 4000;
    float const BONK_MANGLE_SHARE                = 0.25f;
    size_t const BONK_MANGLE_TARGETS             = 4;
    uint32 const BONK_FEROCIOUS_BITE_CHAIN       = 3;
    size_t const BONK_FRENZY_MAX_ENEMIES         = 5;
    float const BONK_BARKSKIN_MAX_PCT            = 10.0f;
    uint32 const BONK_LIFEBLOOM_EVERY            = 4;
    float const BONK_LIFEBLOOM_HEAL              = 1.0f;
    float const BONK_LIFEBLOOM_SHARE             = 0.8f;
    size_t const BONK_LIFEBLOOM_LOOKS            = 6;
    uint32 const BONK_EFFLORESCENCE_MS           = 4000;
    int32 const BONK_EFFLORESCENCE_PULSE_MS      = 1000;
    float const BONK_EFFLORESCENCE_SHARE         = 0.6f;
    uint32 const BONK_ROOT_MS                    = 2000;
    uint32 const BONK_STRANGLE_TICK_MS           = 1000;
    float const BONK_STRANGLE_SHARE              = 0.5f;
    float const BONK_STRANGLE_HEAL_PER_ENEMY     = 0.05f;
    float const BONK_STRANGLE_HEAL_MAX           = 0.5f;
    float const BONK_WIDENING_CALM_STEP          = 3.0f;
    float const BONK_OVERGROWTH_SHARE            = 0.6f;
    float const BONK_BRAMBLES_SHARE              = 0.5f;
    int32 const BONK_NATURES_GRASP_MS            = 1000;
    uint32 const BONK_MUSHROOM_MS                = 3000;
    float const BONK_MUSHROOM_RADIUS             = 8.0f;
    float const BONK_MUSHROOM_SHARE              = 0.4f;
    float const BONK_MUSHROOM_SCALE              = 0.6f;
    size_t const BONK_MAX_MUSHROOMS              = 8;
    uint32 const BONK_SURGE_EVERY_MS             = 6000;
    size_t const BONK_SURGE_STARS                = 5;
    uint32 const BONK_SURGE_BLEED                = 2;
    int32 const BONK_SURGE_ROOT_MS               = 1000;
    float const BONK_SURGE_HEAL                  = 2.0f;
    uint32 const BONK_SPIRIT_MS                  = 6000;
    uint32 const BONK_SPIRIT_EVERY_MS            = 6000;

    bool IsNormalMob(Creature const* mob)
    {
        BonkMobAI const* ai = mob ? dynamic_cast<BonkMobAI const*>(mob->AI()) : nullptr;
        return ai && ai->GetKind() == BONK_SPAWN_NORMAL;
    }

    void InstallDruidLookAI(Creature* creature)
    {
        creature->GetMotionMaster()->Initialize();
        creature->SetAI(new NullCreatureAI(creature));
        creature->SetFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_PLAYER_CONTROLLED | UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_IMMUNE_TO_PLAYER | UNIT_FLAG_IMMUNE_TO_NPC);
    }
}

void BonkRun::ResetDruidEvolutions()
{
    if (Map* map = m_player->FindMap())
    {
        for (DruidSpirit const& spirit : m_druidSpirits)
            if (Creature* creature = map->GetCreature(spirit.guid))
                creature->DespawnOrUnsummon();
        for (DruidMushroom const& mushroom : m_druidMushrooms)
            if (Creature* creature = map->GetCreature(mushroom.guid))
                creature->DespawnOrUnsummon();
    }
    m_druidSpirits.clear();
    m_druidMushrooms.clear();
    m_fullMoonNext.clear();
    m_strangledUntilMs.clear();
    m_strangleTickMs = m_shootingStarsMs = m_fullMoonPollMs = 0;
    m_player->RemoveAurasDueToSpell(BONK_SPELL_TIGERS_FURY_AURA);
    m_tigersFuryHaste = 0.0f;
    m_lifebloomTicks = 0;
    std::fill(std::begin(m_surgeReadyMs), std::end(m_surgeReadyMs), 0u);
    std::fill(std::begin(m_spiritReadyMs), std::end(m_spiritReadyMs), 0u);
}

void BonkRun::UpdateDruidEvolutions()
{
    FallShootingStars();
    EruptFullMoons();
    StrangleRooted();
    BurstMushrooms();
    FightAsSpirits();
}

Creature* BonkRun::SummonDruidLook(uint32 displayId, float scale, float x, float y, float z, uint32 lifeMs)
{
    Creature* look = m_player->SummonCreature(BONK_PROJECTILE, x, y, z, m_player->GetOrientation(), TEMPSUMMON_TIMED_DESPAWN,
        lifeMs + 2000, false, 0, &InstallDruidLookAI);
    if (!look)
        return nullptr;
    look->SetFactionTemplateId(m_player->GetFactionTemplateId());
    look->SetDisplayId(displayId);
    look->SetNativeDisplayId(displayId);
    look->SetObjectScale(scale);
    look->UpdateModelData();
    return look;
}

void BonkRun::ApplyDruidMoonfire(OwnedWeapon const& source, Creature* mob, uint32 stacks)
{
    BonkKeywordInfo const* info = sBonkMgr.GetKeyword(BONK_KEYWORD_MOONFIRE);
    if (!info || !mob || !mob->IsAlive() || !stacks)
        return;
    OwnedWeapon const* moonfire = nullptr;
    for (OwnedWeapon const& owned : m_weapons)
        if (GetRootWeapon(owned.weapon) == BONK_WEAPON_MOONFIRE_SPELL)
            moonfire = &owned;
    if (!moonfire)
    {
        ApplyWeaponKeyword(ScaleForForm(source), mob, BONK_KEYWORD_MOONFIRE, stacks);
        return;
    }
    OwnedWeapon const scaled = ScaleForForm(*moonfire);
    uint32 const durationMs = uint32(info->durationMs * GetWeaponDurationScale(scaled));
    float const strength = (1.0f + scaled.damageBonus / 100.0f) * std::max(1.0f, scaled.weapon.damageFraction);
    ApplyKeyword(mob, BONK_KEYWORD_MOONFIRE, stacks, durationMs, strength, scaled.weapon.spellId);
}

void BonkRun::OnDruidShift(BonkDruidForm from, BonkDruidForm to)
{
    OwnedWeapon const* surge = FindOwned(BONK_WEAPON_SHIFTING_SURGE);
    if (surge && int32(m_surgeReadyMs[size_t(to)] - m_totalMs) <= 0)
    {
        m_surgeReadyMs[size_t(to)] = m_totalMs + BONK_SURGE_EVERY_MS;
        SurgeIntoForm(*surge, to);
    }
    OwnedWeapon const* spirits = FindOwned(BONK_WEAPON_SPIRIT_FORMS);
    if (spirits && from != BonkDruidForm::None && int32(m_spiritReadyMs[size_t(from)] - m_totalMs) <= 0)
    {
        m_spiritReadyMs[size_t(from)] = m_totalMs + BONK_SPIRIT_EVERY_MS;
        LeaveSpirit(*spirits, from);
    }
}

void BonkRun::SurgeIntoForm(OwnedWeapon const& shapeshift, BonkDruidForm form)
{
    float const radius = GetWeaponRadius(shapeshift);
    switch (form)
    {
        case BonkDruidForm::Moonkin:
            CallStarfall(shapeshift, BONK_SURGE_STARS);
            break;
        case BonkDruidForm::Cat:
            for (Creature* mob : GetMobsInRange(radius))
                ApplyWeaponKeyword(shapeshift, mob, BONK_KEYWORD_BLEED, BONK_SURGE_BLEED);
            m_player->SendPlaySpellVisualKit(BONK_KIT_TYPHOON);
            break;
        case BonkDruidForm::Bear:
            m_roarReadyMs = 0;
            RoarAsBear();
            break;
        case BonkDruidForm::Tree:
        {
            SpellEntry const* roots = sSpellMgr.GetSpellEntry(BONK_SPELL_ROOTS);
            for (Creature* mob : GetMobsInRange(radius))
            {
                int32 durationMs = BONK_SURGE_ROOT_MS;
                if (roots && IsNormalMob(mob) && LimitRoot(mob, durationMs))
                    HoldMob(mob, roots, SPELL_AURA_MOD_ROOT, durationMs);
            }
            m_player->SendPlaySpellVisualKit(BONK_KIT_SURGE_ROOTS);
            HealDruid(shapeshift, BONK_SURGE_HEAL);
            break;
        }
        default:
            break;
    }
}

void BonkRun::LeaveSpirit(OwnedWeapon const& shapeshift, BonkDruidForm form)
{
    Creature* spirit = SummonDruidLook(GetDruidFormDisplay(form), m_player->GetObjectScale(),
        m_player->GetPositionX(), m_player->GetPositionY(), m_player->GetPositionZ(), BONK_SPIRIT_MS);
    if (!spirit)
        return;
    spirit->AddAura(BONK_SPELL_SPIRIT_GLOW, ADD_AURA_PERMANENT);
    DruidSpirit left;
    left.guid = spirit->GetObjectGuid();
    left.form = form;
    left.untilMs = m_totalMs + BONK_SPIRIT_MS;
    left.attackAtMs = m_totalMs + GetSpiritAttackMs(shapeshift, form);
    m_druidSpirits.push_back(left);
}

void BonkRun::FightAsSpirits()
{
    if (m_druidSpirits.empty())
        return;
    OwnedWeapon const* shapeshift = FindOwned(BONK_WEAPON_SPIRIT_FORMS);
    Map* map = m_player->GetMap();
    for (auto itr = m_druidSpirits.begin(); itr != m_druidSpirits.end();)
    {
        Creature* spirit = map->GetCreature(itr->guid);
        if (!shapeshift || !spirit || int32(itr->untilMs - m_totalMs) <= 0)
        {
            if (spirit)
                spirit->DespawnOrUnsummon();
            itr = m_druidSpirits.erase(itr);
            continue;
        }
        if (int32(itr->attackAtMs - m_totalMs) <= 0)
        {
            itr->attackAtMs = m_totalMs + GetSpiritAttackMs(*shapeshift, itr->form);
            StrikeAsSpirit(*shapeshift, spirit, itr->form);
        }
        ++itr;
    }
}

void BonkRun::OnStarfireStrike(OwnedWeapon const& owned, SpellEntry const* spellInfo, Creature* target)
{
    if (owned.weapon.id != BONK_WEAPON_STARBURST || !target)
        return;
    target->SendPlaySpellVisualKit(BONK_KIT_STAR_BURST);
    float const damage = GetWeaponDamage(owned) * BONK_STARBURST_SHARE;
    std::vector<Creature*> struck = GetMobsInRange(GetWeaponRadius(owned), target);
    for (Creature* mob : struck)
        DealShamanHit(spellInfo, owned.weapon.spellId, mob, damage);
    struck.push_back(target);
    for (Creature* mob : struck)
        ApplyDruidMoonfire(owned, mob, 1);
}

void BonkRun::FallShootingStars()
{
    OwnedWeapon const* owned = FindOwned(BONK_WEAPON_SHOOTING_STARS);
    if (!owned || int32(m_shootingStarsMs - m_totalMs) > 0)
        return;
    m_shootingStarsMs = m_totalMs + BONK_SHOOTING_STARS_POLL_MS;
    SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_STARFIRE_LOOK);
    uint32 fallen = 0;
    float const damage = GetWeaponDamage(*owned) * BONK_SHOOTING_STARS_SHARE;
    for (Creature* mob : GetDruidTargets(BONK_SHOOTING_STARS_RANGE))
    {
        if (fallen >= BONK_SHOOTING_STARS_MAX)
            break;
        if (!GetKeywordStacks(mob, BONK_KEYWORD_MOONFIRE) || !roll_chance_f(BONK_SHOOTING_STARS_CHANCE))
            continue;
        ++fallen;
        ShowStrike(m_player, look, mob);
        DealShamanHit(look, owned->weapon.spellId, mob, damage);
    }
}

void BonkRun::OnMoonfireStrikes(OwnedWeapon const& owned, std::vector<Creature*> const& struck)
{
    if (owned.weapon.id != BONK_WEAPON_SUNFIRE)
        return;
    std::set<ObjectGuid> burned;
    for (Creature* mob : struck)
        burned.insert(mob->GetObjectGuid());
    for (Creature* mob : struck)
    {
        size_t spread = 0;
        for (Creature* neighbor : GetMobsInRange(GetWeaponRadius(owned), mob))
            if (spread < BONK_SUNFIRE_SPREAD && burned.insert(neighbor->GetObjectGuid()).second)
            {
                ++spread;
                ApplyDruidMoonfire(owned, neighbor, 1);
            }
    }
}

void BonkRun::EruptFullMoons()
{
    OwnedWeapon const* owned = FindOwned(BONK_WEAPON_FULL_MOON);
    if (!owned || int32(m_fullMoonPollMs - m_totalMs) > 0)
        return;
    m_fullMoonPollMs = m_totalMs + BONK_FULL_MOON_POLL_MS;
    SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_MOONFIRE_LOOK);
    float const damage = GetWeaponDamage(*owned) * BONK_FULL_MOON_SHARE;
    for (Creature* mob : GetMobsInRange(BONK_FULL_MOON_RANGE))
    {
        uint32 const stacks = GetKeywordStacks(mob, BONK_KEYWORD_MOONFIRE);
        auto itr = m_fullMoonNext.find(mob->GetObjectGuid());
        uint32& next = itr != m_fullMoonNext.end() ? itr->second : m_fullMoonNext[mob->GetObjectGuid()];
        if (!next || stacks + BONK_FULL_MOON_EVERY < next)
            next = (stacks / BONK_FULL_MOON_EVERY + 1) * BONK_FULL_MOON_EVERY;
        if (stacks < next)
            continue;
        next += BONK_FULL_MOON_EVERY;
        ShowStrike(m_player, look, mob);
        std::vector<Creature*> struck = GetMobsInRange(GetWeaponRadius(*owned), mob);
        struck.push_back(mob);
        for (Creature* hit : struck)
            DealShamanHit(look, owned->weapon.spellId, hit, damage);
    }
    for (auto itr = m_fullMoonNext.begin(); itr != m_fullMoonNext.end();)
    {
        Creature* mob = m_player->GetMap()->GetCreature(itr->first);
        itr = mob && mob->IsAlive() ? std::next(itr) : m_fullMoonNext.erase(itr);
    }
}

bool BonkRun::GetDruidEvolvedCloudKind(OwnedWeapon const& owned, KeywordCloudKind& kind) const
{
    if (owned.weapon.id == BONK_WEAPON_URSOLS_VORTEX)
    {
        kind.lifeMs = BONK_VORTEX_MS;
        kind.pulseEveryMs = BONK_VORTEX_PULSE_MS;
        kind.maxAlive = BONK_VORTEX_ALIVE;
        kind.lookSpellId = BONK_SPELL_VORTEX_LOOK;
        return true;
    }
    if (owned.weapon.id == BONK_WEAPON_EFFLORESCENCE)
    {
        kind.lifeMs = BONK_EFFLORESCENCE_MS;
        kind.pulseEveryMs = BONK_EFFLORESCENCE_PULSE_MS;
        kind.maxAlive = 1;
        kind.natureRing = true;
        return true;
    }
    return false;
}

void BonkRun::OnDruidEvolvedCloudPulse(OwnedWeapon const& owned, KeywordCloud const& cloud)
{
    uint32 const id = owned.weapon.id;
    if (id == BONK_WEAPON_MOONSTORM && (cloud.leftMs / cloud.pulseEveryMs) % 2 == 0)
        for (Creature* mob : GetMobsNear(cloud.x, cloud.y, cloud.radius))
            ApplyDruidMoonfire(owned, mob, 1);
    if (id == BONK_WEAPON_URSOLS_VORTEX)
    {
        SpellEntry const* look = sSpellMgr.GetSpellEntry(owned.weapon.spellId);
        float const damage = GetWeaponDamage(owned) * BONK_VORTEX_SHARE;
        for (Creature* mob : GetMobsNear(cloud.x, cloud.y, cloud.radius))
        {
            DealShamanHit(look, owned.weapon.spellId, mob, damage);
            ApplyWeaponKeyword(owned, mob, BONK_KEYWORD_DAZED, 1);
        }
    }
    if (id == BONK_WEAPON_EFFLORESCENCE)
    {
        SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_LASH_LOOK);
        float const damage = GetWeaponDamage(owned) * BONK_EFFLORESCENCE_SHARE;
        size_t shown = 0;
        for (Creature* mob : GetMobsNear(cloud.x, cloud.y, cloud.radius))
        {
            if (shown++ < BONK_LIFEBLOOM_LOOKS)
                ShowStrike(m_player, look, mob);
            HitAsDruid(owned, look, mob, damage);
        }
    }
}

void BonkRun::OnDruidCloudEnd(OwnedWeapon const& owned, KeywordCloud const& cloud)
{
    if (owned.weapon.id != BONK_WEAPON_TYPHOON)
        return;
    PlayKitAt(ObjectGuid(), cloud.x, cloud.y, m_player->GetPositionZ(), BONK_KIT_TYPHOON, true);
    SpellEntry const* look = sSpellMgr.GetSpellEntry(owned.weapon.spellId);
    float const damage = GetWeaponDamage(owned) * BONK_TYPHOON_SHARE;
    for (Creature* mob : GetMobsNear(cloud.x, cloud.y, cloud.radius))
    {
        DealShamanHit(look, owned.weapon.spellId, mob, damage);
        if (mob->IsAlive() && IsNormalMob(mob))
            KnockBack(mob);
    }
}

void BonkRun::PickRakeTargets(OwnedWeapon const& owned, std::vector<Creature*>& mobs) const
{
    if (owned.weapon.id != BONK_WEAPON_THRASH)
    {
        mobs.resize(std::min<size_t>(mobs.size(), GetWeaponTargets(owned)));
        return;
    }
    float const radius = GetWeaponRadius(owned);
    mobs.erase(std::remove_if(mobs.begin(), mobs.end(), [this, radius](Creature* mob) { return !m_player->IsWithinDistInMap(mob, radius); }), mobs.end());
}

void BonkRun::OnRakeDone(OwnedWeapon const& owned, size_t struck)
{
    if (owned.weapon.id != BONK_WEAPON_TIGERS_FURY || !struck)
        return;
    bool const fresh = !m_player->HasAura(BONK_SPELL_TIGERS_FURY_AURA);
    m_tigersFuryHaste = std::min(BONK_TIGERS_FURY_MAX, BONK_TIGERS_FURY_PER_ENEMY * float(struck));
    if (fresh)
        if (SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_TIGERS_FURY_LOOK))
            ShowStrike(m_player, look, m_player);
    if (SpellAuraHolder* holder = m_player->AddAura(BONK_SPELL_TIGERS_FURY_AURA, ADD_AURA_POSITIVE))
    {
        holder->SetAuraDuration(BONK_TIGERS_FURY_MS);
        holder->SetAuraMaxDuration(BONK_TIGERS_FURY_MS);
        holder->UpdateAuraDuration();
    }
}

float BonkRun::GetDruidHaste() const
{
    return m_player->HasAura(BONK_SPELL_TIGERS_FURY_AURA) ? m_tigersFuryHaste : 0.0f;
}

void BonkRun::OnShredHit(OwnedWeapon const& owned, SpellEntry const* spellInfo, Creature* target, std::vector<Creature*>& queue)
{
    uint32 const id = owned.weapon.id;
    if (id == BONK_WEAPON_MANGLE)
    {
        std::vector<Creature*> mangled = GetMobsInRange(GetWeaponRadius(owned), target);
        mangled.resize(std::min(mangled.size(), BONK_MANGLE_TARGETS));
        for (Creature* mob : mangled)
            HitAsDruid(owned, spellInfo, mob, GetShredDamage(owned, mob) * BONK_MANGLE_SHARE);
    }
    if (id != BONK_WEAPON_FEROCIOUS_BITE)
        return;
    uint32 bites = 0;
    Creature* last = target;
    while (!last->IsAlive() && bites < BONK_FEROCIOUS_BITE_CHAIN)
    {
        queue.erase(std::remove_if(queue.begin(), queue.end(), [](Creature* mob) { return !mob->IsAlive(); }), queue.end());
        if (queue.empty())
            return;
        Creature* next = queue.front();
        queue.erase(queue.begin());
        ++bites;
        ShowDruidStrike(spellInfo, next);
        HitAsDruid(owned, spellInfo, next, GetShredDamage(owned, next));
        last = next;
    }
}

void BonkRun::OnSwipe(OwnedWeapon const& owned, std::vector<Creature*> const& struck)
{
    if (owned.weapon.id == BONK_WEAPON_LACERATE)
        for (Creature* mob : struck)
            if (mob->IsAlive())
                ApplyWeaponKeyword(ScaleForForm(owned), mob, BONK_KEYWORD_BLEED, 1);
    if (owned.weapon.id == BONK_WEAPON_URSOLS_VORTEX)
        StartKeywordCloud(owned, m_player->GetPositionX(), m_player->GetPositionY(), m_player->GetPositionZ());
}

void BonkRun::OnFrenziedTick(OwnedWeapon const& owned, float healPct)
{
    uint32 const id = owned.weapon.id;
    if (id == BONK_WEAPON_BLOODY_FRENZY)
    {
        std::vector<Creature*> mobs = GetMobsInRange(GetWeaponRadius(owned));
        mobs.resize(std::min(mobs.size(), BONK_FRENZY_MAX_ENEMIES));
        SpellEntry const* look = sSpellMgr.GetSpellEntry(owned.weapon.spellId);
        float const damage = GetWeaponDamage(owned);
        for (Creature* mob : mobs)
        {
            ShowDruidStrike(sSpellMgr.GetSpellEntry(BONK_SPELL_MAUL_LOOK), mob);
            HitAsDruid(owned, look, mob, damage);
        }
    }
    if (id == BONK_WEAPON_BARKSKIN)
    {
        uint32 const cap = uint32(m_player->GetMaxHealth() * BONK_BARKSKIN_MAX_PCT / 100.0f);
        if (m_spellShield >= cap)
            return;
        SupportScope scope(*this, WeaponSupport(owned));
        uint32 const amount = uint32(m_player->GetMaxHealth() * healPct * GetDruidFormScale(owned) / 100.0f);
        AddSpellShield(std::min(std::max(1u, amount), cap - m_spellShield));
        if (TakeDruidLookSlot(BONK_WEAPON_BARKSKIN))
            if (SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_BARKSKIN_LOOK))
                ShowStrike(m_player, look, m_player);
    }
}

bool BonkRun::BloomEfflorescence(OwnedWeapon& owned)
{
    if (owned.weapon.id != BONK_WEAPON_EFFLORESCENCE)
        return false;
    auto const fromWeapon = [&owned](KeywordCloud const& cloud) { return cloud.weaponId == owned.weapon.id; };
    auto ring = std::find_if(m_keywordClouds.begin(), m_keywordClouds.end(), fromWeapon);
    if (ring == m_keywordClouds.end())
    {
        StartKeywordCloud(owned, m_player->GetPositionX(), m_player->GetPositionY(), m_player->GetPositionZ());
        ring = std::find_if(m_keywordClouds.begin(), m_keywordClouds.end(), fromWeapon);
    }
    if (ring == m_keywordClouds.end())
        return true;
    float const dx = m_player->GetPositionX() - ring->x;
    float const dy = m_player->GetPositionY() - ring->y;
    if (dx * dx + dy * dy <= ring->radius * ring->radius)
        HealDruid(owned, owned.weapon.healPct);
    return true;
}

void BonkRun::OnRejuvenationTick(OwnedWeapon const& owned, SpellEntry const* spellInfo)
{
    if (owned.weapon.id != BONK_WEAPON_LIFEBLOOM || ++m_lifebloomTicks % BONK_LIFEBLOOM_EVERY)
        return;
    m_player->SendPlaySpellVisualKit(BONK_KIT_BLOOM);
    HealDruid(owned, BONK_LIFEBLOOM_HEAL);
    SpellEntry const* lash = sSpellMgr.GetSpellEntry(BONK_SPELL_LASH_LOOK);
    float const damage = GetWeaponDamage(owned) * BONK_LIFEBLOOM_SHARE;
    size_t shown = 0;
    for (Creature* mob : GetMobsInRange(GetWeaponRadius(owned)))
    {
        if (shown++ < BONK_LIFEBLOOM_LOOKS)
            ShowStrike(m_player, lash, mob);
        HitAsDruid(owned, spellInfo, mob, damage);
    }
}

void BonkRun::OnDruidRooted(OwnedWeapon const& owned, SpellEntry const* spellInfo, Creature* mob, bool spreads)
{
    uint32 const id = owned.weapon.id;
    if (id == BONK_WEAPON_STRANGLING_VINES)
    {
        m_strangledUntilMs[mob->GetObjectGuid()] = m_totalMs + BONK_ROOT_MS;
        ApplyTimedAuraTo(mob, BONK_SPELL_STRANGLING_VINES, BONK_ROOT_MS, ADD_AURA_NEGATIVE);
    }
    if (id != BONK_WEAPON_MASS_ENTANGLEMENT || !spreads)
        return;
    for (Creature* neighbor : GetMobsInRange(GetWeaponRadius(owned), mob))
    {
        int32 durationMs = int32(BONK_ROOT_MS);
        if (!neighbor->IsAlive() || !IsNormalMob(neighbor) || !LimitRoot(neighbor, durationMs))
            continue;
        ShowStrike(m_player, spellInfo, neighbor);
        HoldMob(neighbor, spellInfo, SPELL_AURA_MOD_ROOT, durationMs);
        OnDruidRooted(owned, spellInfo, neighbor, false);
    }
}

void BonkRun::StrangleRooted()
{
    if (m_strangledUntilMs.empty() || int32(m_strangleTickMs - m_totalMs) > 0)
        return;
    m_strangleTickMs = m_totalMs + BONK_STRANGLE_TICK_MS;
    OwnedWeapon const* owned = FindOwned(BONK_WEAPON_STRANGLING_VINES);
    if (!owned)
    {
        m_strangledUntilMs.clear();
        return;
    }
    SpellEntry const* look = sSpellMgr.GetSpellEntry(owned->weapon.spellId);
    float const damage = GetWeaponDamage(*owned) * BONK_STRANGLE_SHARE;
    uint32 drained = 0;
    for (auto itr = m_strangledUntilMs.begin(); itr != m_strangledUntilMs.end();)
    {
        Creature* mob = m_player->GetMap()->GetCreature(itr->first);
        if (!mob || !mob->IsAlive() || int32(itr->second - m_totalMs) < 0)
        {
            itr = m_strangledUntilMs.erase(itr);
            continue;
        }
        HitAsDruid(*owned, look, mob, damage);
        ++drained;
        ++itr;
    }
    if (drained)
        HealDruid(*owned, std::min(BONK_STRANGLE_HEAL_MAX, BONK_STRANGLE_HEAL_PER_ENEMY * float(drained)));
}

float BonkRun::GetTranquilityReach(OwnedWeapon const& owned) const
{
    float reach = owned.weapon.radius;
    if (owned.weapon.id == BONK_WEAPON_WIDENING_CALM && m_tranquilityPulse)
        reach += BONK_WIDENING_CALM_STEP * float(m_tranquilityPulse);
    return reach * GetWeaponArea(owned);
}

void BonkRun::OnTranquilityHeal(OwnedWeapon const& owned, float overhealShare)
{
    if (owned.weapon.id != BONK_WEAPON_OVERGROWTH || overhealShare <= 0.0f)
        return;
    SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_LASH_LOOK);
    float const damage = GetWeaponDamage(owned) * BONK_OVERGROWTH_SHARE * overhealShare;
    size_t shown = 0;
    for (Creature* mob : GetMobsInRange(GetTranquilityReach(owned)))
    {
        if (shown++ < BONK_LIFEBLOOM_LOOKS)
            ShowStrike(m_player, look, mob);
        HitAsDruid(owned, look, mob, damage);
    }
}

void BonkRun::OnThornsStrike(OwnedWeapon const& thorns, SpellEntry const* look, Creature* attacker)
{
    uint32 const id = thorns.weapon.id;
    if (id == BONK_WEAPON_BRAMBLES)
        for (Creature* mob : GetMobsInRange(GetWeaponRadius(thorns)))
            if (mob != attacker)
                HitAsDruid(thorns, look, mob, GetWeaponDamage(thorns) * BONK_BRAMBLES_SHARE);
    if (id != BONK_WEAPON_NATURES_GRASP || !attacker->IsAlive() || !IsNormalMob(attacker))
        return;
    int32 durationMs = BONK_NATURES_GRASP_MS;
    SpellEntry const* roots = sSpellMgr.GetSpellEntry(BONK_SPELL_ROOTS);
    if (roots && LimitRoot(attacker, durationMs))
    {
        attacker->SendPlaySpellVisualKit(BONK_KIT_GRASP);
        HoldMob(attacker, roots, SPELL_AURA_MOD_ROOT, durationMs);
    }
}

bool BonkRun::IsAncientOfWar(OwnedWeapon const& owned) const
{
    return owned.weapon.id == BONK_WEAPON_ANCIENT_OF_WAR;
}

void BonkRun::PlantMushroom(OwnedWeapon const& owned, Creature* prey)
{
    if (owned.weapon.id != BONK_WEAPON_FUNGAL_GROWTH || !prey)
        return;
    if (m_druidMushrooms.size() >= BONK_MAX_MUSHROOMS)
        return;
    DruidMushroom mushroom;
    mushroom.weaponId = owned.weapon.id;
    mushroom.x = prey->GetPositionX();
    mushroom.y = prey->GetPositionY();
    mushroom.z = prey->GetPositionZ();
    mushroom.burstAtMs = m_totalMs + BONK_MUSHROOM_MS;
    if (Creature* look = SummonDruidLook(BONK_DISPLAY_MUSHROOM, BONK_MUSHROOM_SCALE, mushroom.x, mushroom.y, mushroom.z, BONK_MUSHROOM_MS))
        mushroom.guid = look->GetObjectGuid();
    m_druidMushrooms.push_back(mushroom);
}

void BonkRun::BurstMushrooms()
{
    for (auto itr = m_druidMushrooms.begin(); itr != m_druidMushrooms.end();)
    {
        if (int32(itr->burstAtMs - m_totalMs) > 0)
        {
            ++itr;
            continue;
        }
        DruidMushroom const mushroom = *itr;
        itr = m_druidMushrooms.erase(itr);
        if (Creature* look = m_player->GetMap()->GetCreature(mushroom.guid))
            look->DespawnOrUnsummon();
        OwnedWeapon const* owned = FindOwned(mushroom.weaponId);
        if (!owned)
            continue;
        PlayKitAt(ObjectGuid(), mushroom.x, mushroom.y, mushroom.z, BONK_KIT_SPORE_BURST, true);
        SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_LASH_LOOK);
        float const damage = GetWeaponDamage(*owned) * BONK_MUSHROOM_SHARE;
        for (Creature* mob : GetMobsNear(mushroom.x, mushroom.y, BONK_MUSHROOM_RADIUS * GetSummonReach(*owned)))
            DealShamanHit(look, owned->weapon.spellId, mob, damage);
    }
}

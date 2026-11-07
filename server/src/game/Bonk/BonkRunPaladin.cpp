#include "BonkRun.h"
#include "BonkAura.h"
#include "BonkLocale.h"
#include "BonkMobAI.h"
#include "BonkPlayer.h"
#include "Creature.h"
#include "Map.h"
#include "Player.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "Utilities/Random.h"

#include <algorithm>
#include <cmath>

namespace
{
    uint32 const BONK_WEAPON_SEAL_OF_COMMAND  = 802;
    uint32 const BONK_WEAPON_SEAL_OF_RIGHTEOUSNESS = 803;
    uint32 const BONK_WEAPON_CONSECRATION     = 804;
    uint32 const BONK_WEAPON_SEAL_OF_LIGHT    = 807;
    uint32 const BONK_WEAPON_CRUSADERS_ZEAL   = 815;
    uint32 const BONK_WEAPON_AVENGING_CRUSADER = 816;
    uint32 const BONK_WEAPON_JUDGEMENT_OF_LIGHT = 817;
    uint32 const BONK_WEAPON_JUDGEMENT_OF_THE_CRUSADER = 818;
    uint32 const BONK_WEAPON_SEAL_OF_THE_CRUSADER = 819;
    uint32 const BONK_WEAPON_SEAL_OF_JUSTICE  = 820;
    uint32 const BONK_WEAPON_SEAL_OF_THE_TEMPLAR = 821;
    uint32 const BONK_WEAPON_SEAL_OF_VENGEANCE = 822;
    uint32 const BONK_WEAPON_HALLOWED_GROUND  = 823;
    uint32 const BONK_WEAPON_BLESSED_GROUND   = 824;
    uint32 const BONK_WEAPON_ART_OF_WAR       = 826;
    uint32 const BONK_WEAPON_DIVINE_TEMPEST   = 827;
    uint32 const BONK_WEAPON_WAKE_OF_ASHES    = 828;
    uint32 const BONK_WEAPON_LAY_ON_HANDS     = 829;
    uint32 const BONK_WEAPON_ILLUMINATION     = 830;
    uint32 const BONK_WEAPON_ARDENT_DEFENDER  = 831;
    uint32 const BONK_WEAPON_HOLY_SHIELD      = 832;
    uint32 const BONK_WEAPON_DEVOTION_AURA    = 834;
    uint32 const BONK_WEAPON_HAMMER_OF_THE_RIGHTEOUS = 835;
    uint32 const BONK_WEAPON_HAMMER_OF_LIGHT  = 838;
    uint32 const BONK_WEAPON_SHIELD_OF_THE_RIGHTEOUS = 840;

    uint32 const BONK_SPELL_RIGHTEOUS_HIT     = 20187;
    uint32 const BONK_SPELL_HOLY_NOVA         = 15237;
    uint32 const BONK_SPELL_FALLING_HAMMER    = 17286;
    uint32 const BONK_SPELL_JUSTICE_HAMMER    = 20685;
    uint32 const BONK_SPELL_DIVINE_SHIELD     = 33463;
    uint32 const BONK_SPELL_HAMMER_OF_WRATH   = 24239;
    uint32 const BONK_SPELL_LAY_ON_HANDS      = 633;
    uint32 const BONK_SPELL_JUDGED_LOOK       = 21183;
    uint32 const BONK_SPELL_SEAL_OF_LIGHT     = 20165;
    uint32 const BONK_SPELL_CONSECRATION_LOOK = 26573;
    uint32 const BONK_KIT_HOLY_WRATH_CAST     = 329;
    uint32 const BONK_KIT_HOLY_WRATH_IMPACT   = 211;
    uint32 const BONK_KIT_JUDGEMENT_IMPACT    = 212;
    uint32 const BONK_KIT_JUDGEMENT_CAST      = 119;
    uint32 const BONK_SOUND_THROWN_IMPACT     = 3642;
    uint32 const BONK_KIT_HOLY_BURST          = 7455;
    uint32 const BONK_KIT_CRUSADER_IMPACT     = 437;
    int32 const BONK_CRUSADER_LAND_MS         = 300;

    float const BONK_CRUSADER_SPLASH_SHARE    = 0.3f;
    float const BONK_ZEAL_SPLASH_SHARE        = 0.5f;
    float const BONK_AVENGING_HAMMER_CHANCE   = 15.0f;
    uint32 const BONK_VERDICT_EVERY           = 4;
    float const BONK_VERDICT_DAMAGE           = 3.0f;
    uint32 const BONK_COMMAND_EVERY           = 2;
    uint32 const BONK_CRUSADER_COMMAND_EVERY  = 1;
    uint32 const BONK_STORM_COMMAND_BURSTS    = 4;
    int32 const BONK_SEAL_OF_JUSTICE_STUN_MS  = 1000;
    float const BONK_TEMPLAR_SHARE_FACTOR     = 1.8f;
    float const BONK_VENGEANCE_SHARE_FACTOR   = 0.9f;
    uint32 const BONK_VENGEANCE_MAX_STACKS    = 5;
    float const BONK_VENGEANCE_PER_STACK      = 0.2f;
    uint32 const BONK_JUDGED_MS               = 6000;
    float const BONK_JUDGED_BONUS             = 1.2f;
    float const BONK_JUDGEMENT_RIGHTEOUS      = 1.5f;
    float const BONK_RIGHTEOUS_SHARE          = 30.0f;
    float const BONK_MAX_RIGHTEOUS_SHARE      = 90.0f;
    float const BONK_JUDGEMENT_COMMAND_RADIUS = 5.0f;
    float const BONK_JUDGEMENT_COMMAND_SHARE  = 0.5f;
    float const BONK_JUDGEMENT_LIGHT_HEAL     = 1.0f;
    float const BONK_JUDGEMENT_LIGHT_CAP      = 5.0f;
    float const BONK_LIGHT_HEAL               = 0.5f;
    float const BONK_MAX_LIGHT_HEAL           = 1.5f;
    float const BONK_ILLUMINATION_CRIT_HEAL   = 3.0f;
    size_t const BONK_LIGHT_HEALS_PER_SEC     = 6;
    float const BONK_WRATH_HEALTH             = 20.0f;
    float const BONK_WRATH_SPEED              = 35.0f;
    float const BONK_JUSTICE_SPEED            = 40.0f;
    float const BONK_RIGHTEOUS_SHIELD_SHARE   = 0.5f;
    int32 const BONK_LIGHTS_HAMMER_LIFT_MS    = 200;
    int32 const BONK_LIGHTS_HAMMER_FALL_MS    = 350;
    float const BONK_LIGHTS_HAMMER_HEIGHT     = 12.0f;
    size_t const BONK_LIGHTS_HAMMER_LOOKS     = 3;
    uint32 const BONK_EXPLODING_HAMMER_EVERY  = 3;
    float const BONK_EXPLODING_HAMMER_RADIUS  = 10.0f;
    float const BONK_EXPLODING_HAMMER_SHARE   = 3.0f;
    float const BONK_EXPLODING_HAMMER_SEEK    = 30.0f;
    float const BONK_CONSECRATION_BONUS       = 1.15f;
    float const BONK_HALLOWED_GROUND_BONUS    = 1.25f;
    uint32 const BONK_CONSECRATION_MS         = 12000;
    uint32 const BONK_HALLOWED_GROUND_MS      = 18000;
    size_t const BONK_CONSECRATION_ALIVE      = 4;
    size_t const BONK_HALLOWED_GROUND_ALIVE   = 5;
    float const BONK_CONSECRATION_HEAL        = 0.25f;
    float const BONK_BLESSED_GROUND_HEAL      = 0.75f;
    float const BONK_CONSECRATED_RETRIBUTION  = 2.0f;
    int32 const BONK_CONSECRATION_PULSE_MS    = 1000;
    float const BONK_EXORCISM_UNHOLY          = 3.0f;
    float const BONK_EXORCISM_ELITE           = 2.0f;
    uint32 const BONK_ART_OF_WAR_EVERY_MS     = 1000;
    uint32 const BONK_FAST_ART_OF_WAR_MS      = 500;
    float const BONK_ART_OF_WAR_SPLASH_SHARE  = 0.5f;
    uint32 const BONK_ILLUMINATED_EXORCISMS   = 2;
    float const BONK_JUDGEMENT_CRIT_FACTOR    = 2.0f;
    size_t const BONK_DIVINE_STORM_LOOKS      = 10;
    float const BONK_DIVINE_STORM_HEAL        = 0.5f;
    float const BONK_DIVINE_STORM_HEAL_CAP    = 3.0f;
    float const BONK_DIVINE_TEMPEST_HEAL_CAP  = 5.0f;
    float const BONK_WAKE_OF_ASHES_SLOW       = 50.0f;
    int32 const BONK_WAKE_OF_ASHES_STUN_MS    = 1000;
    float const BONK_RETRIBUTION_STRUCK_SHARE = 2.0f;
    size_t const BONK_RETRIBUTION_PER_SEC     = 5;
    int32 const BONK_JUSTICE_STUN_MS          = 2000;
    float const BONK_DIVINE_BLOCK_HIT         = 5.0f;
    int32 const BONK_DIVINE_FLASH_MS          = 600;
    int32 const BONK_ARDENT_DEFENDER_MS       = 2000;
    uint32 const BONK_ARDENT_DEFENDER_EVERY_MS = 30000;
    float const BONK_LAY_ON_HANDS_HEALTH      = 30.0f;
    uint32 const BONK_LAY_ON_HANDS_EVERY_MS   = 90000;
    float const BONK_ARDENT_DEFENDER_HEALTH   = 30.0f;
    float const BONK_DEVOTION_TAKEN           = 0.9f;
    float const BONK_GUARDIAN_TAKEN           = 0.8f;
    float const BONK_PALADIN_AWARE_RANGE      = 15.0f;
    int32 const BONK_PALADIN_IDLE_MS          = 1000;
    int32 const BONK_PALADIN_RETRY_MS         = 250;

    BonkSpawnKind GetPaladinMobKind(Creature const* mob)
    {
        BonkMobAI const* ai = mob ? dynamic_cast<BonkMobAI const*>(mob->AI()) : nullptr;
        return ai ? ai->GetKind() : BONK_SPAWN_NORMAL;
    }

    bool CanBeStunned(Creature const* mob)
    {
        BonkSpawnKind const kind = GetPaladinMobKind(mob);
        return kind == BONK_SPAWN_NORMAL || kind == BONK_SPAWN_ELITE;
    }

    bool IsUnholy(Creature const* mob)
    {
        uint32 const type = mob->GetCreatureType();
        return type == CREATURE_TYPE_UNDEAD || type == CREATURE_TYPE_DEMON;
    }
}

void BonkRun::ResetPaladinState()
{
    m_sealOfLightTimes.clear();
    m_retributionTimes.clear();
    m_paladinStrikes = 0;
    m_divineShieldCharged = false;
    m_artOfWarReadyMs = 0;
    m_layOnHandsReadyMs = 0;
    m_ardentDefenderReadyMs = 0;
    m_crusaderStrikes = 0;
    m_lightsHammerVolleys = 0;
    m_vengeanceStacks.clear();
    if (m_player->HasAura(BONK_SPELL_DIVINE_SHIELD))
        m_player->RemoveAurasDueToSpell(BONK_SPELL_DIVINE_SHIELD);
}

bool BonkRun::FirePaladinSpell(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    switch (owned.weapon.behavior)
    {
        case BONK_BEHAVIOR_CRUSADER_STRIKE:  StrikeAsCrusader(owned, spellInfo); break;
        case BONK_BEHAVIOR_JUDGEMENT:        PassJudgement(owned, spellInfo); break;
        case BONK_BEHAVIOR_SEAL:             owned.timer = BONK_PALADIN_IDLE_MS; break;
        case BONK_BEHAVIOR_CONSECRATION:     Consecrate(owned); break;
        case BONK_BEHAVIOR_EXORCISM:         CastExorcism(owned, spellInfo); break;
        case BONK_BEHAVIOR_DIVINE_STORM:     SpinDivineStorm(owned, spellInfo); break;
        case BONK_BEHAVIOR_RETRIBUTION_AURA: PulseRetributionAura(owned, spellInfo); break;
        case BONK_BEHAVIOR_JUSTICE_HAMMER:   HammerOfJustice(owned, spellInfo); break;
        case BONK_BEHAVIOR_DIVINE_SHIELD:    ChargeDivineShield(owned); break;
        case BONK_BEHAVIOR_PALADIN_SHIELD:   ThrowAvengersShield(owned, spellInfo); break;
        case BONK_BEHAVIOR_LIGHTS_HAMMER:    DropLightsHammers(owned, spellInfo); break;
        default:                             return false;
    }
    return true;
}

BonkRun::OwnedWeapon const* BonkRun::FindOwnedSeal(uint32 rootId) const
{
    for (OwnedWeapon const& owned : m_weapons)
        if (GetRootWeapon(owned.weapon) == rootId)
            return &owned;
    return nullptr;
}

bool BonkRun::StrikeAsPaladin(SpellEntry const* look, uint32 creditSpellId, Creature* target, float damage, float twice)
{
    if (!look || !target || !target->IsAlive())
        return false;
    bool crit = HitAsPaladin(look, creditSpellId, target, damage);
    if (twice > 0.0f && roll_chance_f(twice))
        crit |= HitAsPaladin(look, creditSpellId, target, damage);
    ResolvePaladinStrike(target, crit);
    if (crit)
        TriggerArtOfWar();
    return crit;
}

bool BonkRun::HitAsPaladin(SpellEntry const* look, uint32 creditSpellId, Creature* target, float damage)
{
    OwnedWeapon const* righteousness = FindOwnedSeal(BONK_WEAPON_SEAL_OF_RIGHTEOUSNESS);
    if (righteousness)
    {
        float const scale = righteousness->weapon.id == BONK_WEAPON_SEAL_OF_VENGEANCE ? GetVengeanceScale(target) : 1.0f;
        DealShamanHit(sSpellMgr.GetSpellEntry(BONK_SPELL_RIGHTEOUS_HIT), righteousness->weapon.spellId, target,
            damage * GetRighteousShare(righteousness->weapon, righteousness->damageBonus) / 100.0f * scale);
    }
    return target->IsAlive() && DealShamanHit(look, creditSpellId, target, damage);
}

float BonkRun::GetVengeanceScale(Creature* target)
{
    uint32& stacks = m_vengeanceStacks[target->GetObjectGuid()];
    stacks = std::min(stacks + 1, BONK_VENGEANCE_MAX_STACKS);
    return 1.0f + BONK_VENGEANCE_PER_STACK * stacks;
}

void BonkRun::TriggerArtOfWar()
{
    if (m_totalMs < m_artOfWarReadyMs)
        return;
    for (OwnedWeapon& owned : m_weapons)
        if (owned.weapon.behavior == BONK_BEHAVIOR_EXORCISM && owned.timer > 0)
        {
            bool const fast = owned.weapon.id == BONK_WEAPON_ART_OF_WAR || m_mastery.Has(BONK_CAPSTONE_DIVINE_ILLUMINATION);
            owned.timer = 0;
            m_artOfWarReadyMs = m_totalMs + (fast ? BONK_FAST_ART_OF_WAR_MS : BONK_ART_OF_WAR_EVERY_MS);
            return;
        }
}

float BonkRun::GetPaladinCritChance(SpellEntry const* spell, float chance) const
{
    if (!spell || m_player->GetClass() != CLASS_PALADIN)
        return chance;
    OwnedWeapon const* judgement = FindOwnedByBehavior(BONK_BEHAVIOR_JUDGEMENT);
    return judgement && judgement->weapon.spellId == spell->Id ? chance * BONK_JUDGEMENT_CRIT_FACTOR : chance;
}

void BonkRun::ResolvePaladinStrike(Creature* target, bool crit)
{
    OwnedWeapon const* command = FindOwnedSeal(BONK_WEAPON_SEAL_OF_COMMAND);
    uint32 const every = command && command->weapon.id == BONK_WEAPON_SEAL_OF_THE_CRUSADER ? BONK_CRUSADER_COMMAND_EVERY : BONK_COMMAND_EVERY;
    if (command && ++m_paladinStrikes % every == 0)
        BurstSealOfCommand(target);
    HealFromSealOfLight(crit);
}

void BonkRun::ChargeCommandFromStorm(std::vector<Creature*> const& struck)
{
    OwnedWeapon const* command = FindOwnedSeal(BONK_WEAPON_SEAL_OF_COMMAND);
    if (!command)
        return;
    uint32 const every = command->weapon.id == BONK_WEAPON_SEAL_OF_THE_CRUSADER ? BONK_CRUSADER_COMMAND_EVERY : BONK_COMMAND_EVERY;
    uint32 bursts = 0;
    for (size_t i = 1; i < struck.size() && bursts < BONK_STORM_COMMAND_BURSTS; ++i)
        if (++m_paladinStrikes % every == 0)
        {
            BurstSealOfCommand(struck[i]);
            ++bursts;
        }
}

void BonkRun::BurstSealOfCommand(Creature* target)
{
    OwnedWeapon const* command = FindOwnedSeal(BONK_WEAPON_SEAL_OF_COMMAND);
    SpellEntry const* nova = sSpellMgr.GetSpellEntry(BONK_SPELL_HOLY_NOVA);
    if (!command || !nova || !target)
        return;
    target->SendPlaySpellVisualKit(BONK_KIT_HOLY_BURST);
    float const damage = GetWeaponDamage(*command);
    std::vector<Creature*> struck = GetMobsInRange(GetWeaponRadius(*command), target);
    if (target->IsAlive())
        struck.push_back(target);
    bool const stuns = command->weapon.id == BONK_WEAPON_SEAL_OF_JUSTICE;
    for (Creature* mob : struck)
    {
        DealShamanHit(nova, command->weapon.spellId, mob, damage);
        int32 durationMs = BONK_SEAL_OF_JUSTICE_STUN_MS;
        if (stuns && mob->IsAlive() && CanBeStunned(mob) && LimitStun(mob, durationMs))
            HoldMob(mob, nova, SPELL_AURA_MOD_STUN, durationMs);
    }
}

void BonkRun::HealPaladin(float percent, uint32 textSpellId)
{
    if (!m_player->IsAlive() || percent <= 0.0f)
        return;
    HealHero(ReduceHealing(std::max(1u, uint32(m_player->GetMaxHealth() * percent / 100.0f))), textSpellId);
}

void BonkRun::HealFromSealOfLight(bool crit)
{
    OwnedWeapon const* light = FindOwnedSeal(BONK_WEAPON_SEAL_OF_LIGHT);
    if (!light || m_player->GetHealth() >= m_player->GetMaxHealth() || !TakeRateSlot(m_sealOfLightTimes, BONK_LIGHT_HEALS_PER_SEC))
        return;
    float const scale = crit && light->weapon.id == BONK_WEAPON_ILLUMINATION ? BONK_ILLUMINATION_CRIT_HEAL : 1.0f;
    SupportScope scope(*this, WeaponSupport(*light));
    HealPaladin(GetSealOfLightHeal(light->damageBonus) * scale, BONK_SPELL_SEAL_OF_LIGHT);
}

std::vector<Creature*> BonkRun::GetPaladinTargets(float range) const
{
    std::vector<Creature*> mobs;
    for (Creature* mob : GetMobsInRange(range))
        if (m_player->IsWithinLOSInMap(mob))
            mobs.push_back(mob);
    return mobs;
}

void BonkRun::StrikeAsCrusader(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    std::vector<Creature*> mobs = GetPaladinTargets(owned.weapon.range * GetWeaponArea(owned));
    if (mobs.empty())
    {
        owned.timer = BONK_PALADIN_RETRY_MS;
        return;
    }
    owned.timer = GetWeaponCooldown(owned);
    mobs.resize(std::min<size_t>(mobs.size(), GetWeaponTargets(owned)));
    bool const verdict = m_mastery.Has(BONK_CAPSTONE_TEMPLARS_VERDICT) && ++m_crusaderStrikes % BONK_VERDICT_EVERY == 0;
    float const damage = GetWeaponDamage(owned) * (verdict ? BONK_VERDICT_DAMAGE : 1.0f);
    float const splash = verdict ? 1.0f : owned.weapon.id == BONK_WEAPON_CRUSADERS_ZEAL ? BONK_ZEAL_SPLASH_SHARE : BONK_CRUSADER_SPLASH_SHARE;
    PendingCast land;
    land.weaponId = owned.weapon.id;
    land.spellId = spellInfo->Id;
    land.leftMs = BONK_CRUSADER_LAND_MS;
    land.crusaderStrike = true;
    land.damage = damage;
    land.splash = splash;
    for (Creature* target : mobs)
    {
        ShowSwing(spellInfo, target);
        land.struck.push_back(target->GetObjectGuid());
    }
    m_pendingCasts.push_back(land);
    SwingRogueBlades();
}

void BonkRun::LandCrusaderStrike(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    float const twice = GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_HIT_TWICE);
    std::set<ObjectGuid> splashed;
    for (ObjectGuid const& guid : cast.struck)
    {
        Creature* target = m_player->GetMap()->GetCreature(guid);
        if (!target || !target->IsAlive())
            continue;
        target->SendPlaySpellVisualKit(BONK_KIT_CRUSADER_IMPACT);
        for (Creature* mob : GetMobsInRange(GetWeaponRadius(owned), target))
            if (splashed.insert(mob->GetObjectGuid()).second)
                HitAsPaladin(spellInfo, owned.weapon.spellId, mob, cast.damage * cast.splash);
        StrikeAsPaladin(spellInfo, owned.weapon.spellId, target, cast.damage, twice);
        if (owned.weapon.id == BONK_WEAPON_AVENGING_CRUSADER && target->IsAlive() && roll_chance_f(BONK_AVENGING_HAMMER_CHANCE))
            CallAvengingHammer(owned, target);
    }
}

void BonkRun::CallAvengingHammer(OwnedWeapon const& owned, Creature* target)
{
    if (SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_HAMMER_OF_WRATH))
        ShowStrike(m_player, look, target);
    PendingCast hammer;
    hammer.weaponId = owned.weapon.id;
    hammer.spellId = owned.weapon.spellId;
    hammer.target = target->GetObjectGuid();
    hammer.leftMs = int32(m_player->GetDistance(target) / BONK_WRATH_SPEED * IN_MILLISECONDS);
    hammer.hammerOfWrath = true;
    m_pendingCasts.push_back(hammer);
}

void BonkRun::JudgeTarget(Creature* target)
{
    ShowJudgedDebuff(target);
}

void BonkRun::ShowJudgedDebuff(Creature* target)
{
    SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(BONK_SPELL_JUDGED_LOOK);
    if (!spellInfo || !target->IsAlive())
        return;
    if (SpellAuraHolder* held = target->GetSpellAuraHolder(BONK_SPELL_JUDGED_LOOK, m_player->GetObjectGuid()))
    {
        held->SetAuraDuration(int32(BONK_JUDGED_MS));
        held->UpdateAuraDuration();
        return;
    }
    int32 noEffect = 0;
    SpellAuraHolder* holder = CreateSpellAuraHolder(spellInfo, target, m_player, m_player);
    Aura* aura = CreateAura(spellInfo, EFFECT_INDEX_0, &noEffect, holder, target, m_player);
    aura->SetPositive(false);
    holder->AddAura(aura, EFFECT_INDEX_0);
    holder->SetPermanent(false);
    holder->SetAuraMaxDuration(int32(BONK_JUDGED_MS));
    holder->SetAuraDuration(int32(BONK_JUDGED_MS));
    target->AddSpellAuraHolder(holder);
}

bool BonkRun::IsJudged(Unit const* victim) const
{
    if (!victim)
        return false;
    return victim->GetSpellAuraHolder(BONK_SPELL_JUDGED_LOOK, m_player->GetObjectGuid()) != nullptr;
}

void BonkRun::PassJudgement(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    std::vector<Creature*> mobs = GetPaladinTargets(owned.weapon.range * GetWeaponArea(owned));
    if (mobs.empty())
    {
        owned.timer = BONK_PALADIN_RETRY_MS;
        return;
    }
    owned.timer = GetWeaponCooldown(owned);
    SortStrongestFirst(mobs);
    mobs.resize(std::min<size_t>(mobs.size(), GetWeaponTargets(owned)));
    OwnedWeapon const* command = FindOwnedSeal(BONK_WEAPON_SEAL_OF_COMMAND);
    float const damage = GetWeaponDamage(owned) * (FindOwnedSeal(BONK_WEAPON_SEAL_OF_RIGHTEOUSNESS) ? BONK_JUDGEMENT_RIGHTEOUS : 1.0f);
    float const twice = GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_HIT_TWICE);
    m_player->SendPlaySpellVisualKit(BONK_KIT_JUDGEMENT_CAST);
    size_t struck = 0;
    for (Creature* target : mobs)
    {
        ShowStrike(m_player, spellInfo, target);
        target->SendPlaySpellVisualKit(BONK_KIT_JUDGEMENT_IMPACT);
        if (owned.weapon.id == BONK_WEAPON_JUDGEMENT_OF_THE_CRUSADER)
            JudgeTarget(target);
        if (command)
            for (Creature* mob : GetMobsInRange(BONK_JUDGEMENT_COMMAND_RADIUS * GetWeaponArea(owned), target))
            {
                DealShamanHit(spellInfo, owned.weapon.spellId, mob, damage * BONK_JUDGEMENT_COMMAND_SHARE);
                ++struck;
            }
        bool crit = DealShamanHit(spellInfo, owned.weapon.spellId, target, damage);
        if (twice > 0.0f && roll_chance_f(twice))
            crit |= DealShamanHit(spellInfo, owned.weapon.spellId, target, damage);
        if (crit)
            TriggerArtOfWar();
        ++struck;
    }
    if (FindOwnedSeal(BONK_WEAPON_SEAL_OF_LIGHT) || owned.weapon.id == BONK_WEAPON_JUDGEMENT_OF_LIGHT)
    {
        OwnedWeapon const* seal = FindOwnedSeal(BONK_WEAPON_SEAL_OF_LIGHT);
        SupportScope scope(*this, WeaponSupport(seal ? *seal : owned));
        HealPaladin(std::min(BONK_JUDGEMENT_LIGHT_HEAL * struck, BONK_JUDGEMENT_LIGHT_CAP), BONK_SPELL_SEAL_OF_LIGHT);
    }
}

void BonkRun::ThrowAvengersShield(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    std::vector<Creature*> mobs = GetPaladinTargets(owned.weapon.range * GetWeaponArea(owned));
    if (mobs.empty())
    {
        owned.timer = BONK_PALADIN_RETRY_MS;
        return;
    }
    owned.timer = GetWeaponCooldown(owned);
    mobs.resize(std::min<size_t>(mobs.size(), GetWeaponTargets(owned)));
    m_player->SendPlaySpellVisualKit(BONK_KIT_HOLY_WRATH_CAST);
    for (Creature* target : mobs)
        LaunchShield(owned, spellInfo, m_player, target, 1.0f, {}, owned.weapon.baseJumps);
}

void BonkRun::StrikeWithAvengersShield(OwnedWeapon const& owned, Creature* target)
{
    SpellEntry const* look = sSpellMgr.GetSpellEntry(owned.weapon.spellId);
    float const damage = GetWeaponDamage(owned);
    target->SendPlaySpellVisualKit(BONK_KIT_HOLY_WRATH_IMPACT);
    if (owned.weapon.id == BONK_WEAPON_SHIELD_OF_THE_RIGHTEOUS)
        for (Creature* mob : GetMobsInRange(GetWeaponRadius(owned), target))
            HitAsPaladin(look, owned.weapon.spellId, mob, damage * BONK_RIGHTEOUS_SHIELD_SHARE);
    StrikeAsPaladin(look, owned.weapon.spellId, target, damage, GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_HIT_TWICE));
}

void BonkRun::LandHammerOfWrath(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    Creature* target = m_player->GetMap()->GetCreature(cast.target);
    if (!target || !target->IsAlive())
        return;
    float damage = GetWeaponDamage(owned);
    if (GetPaladinMobKind(target) == BONK_SPAWN_NORMAL && target->GetHealthPercent() < BONK_WRATH_HEALTH)
        damage = std::max(damage, float(target->GetHealth()) * 2.0f);
    StrikeAsPaladin(spellInfo, owned.weapon.spellId, target, damage, GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_HIT_TWICE));
}

void BonkRun::DropLightsHammers(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    std::vector<Creature*> mobs = GetPaladinTargets(owned.weapon.range * GetWeaponArea(owned));
    if (mobs.empty())
    {
        owned.timer = BONK_PALADIN_RETRY_MS;
        return;
    }
    owned.timer = GetWeaponCooldown(owned);
    size_t const count = std::min<size_t>(mobs.size(), GetWeaponTargets(owned));
    for (size_t i = 0; i < count; ++i)
    {
        std::swap(mobs[i], mobs[i + urand(0, uint32(mobs.size() - i - 1))]);
        Creature* target = mobs[i];
        PendingCast hammer;
        hammer.weaponId = owned.weapon.id;
        hammer.spellId = owned.weapon.spellId;
        hammer.target = target->GetObjectGuid();
        hammer.x = target->GetPositionX();
        hammer.y = target->GetPositionY();
        hammer.z = target->GetPositionZ();
        hammer.leftMs = BONK_LIGHTS_HAMMER_LIFT_MS;
        hammer.lightsHammerLaunch = true;
        m_pendingCasts.push_back(hammer);
    }
    if (owned.weapon.id == BONK_WEAPON_HAMMER_OF_LIGHT && ++m_lightsHammerVolleys % BONK_EXPLODING_HAMMER_EVERY == 0)
        DropExplodingHammer(owned);
}

void BonkRun::DropExplodingHammer(OwnedWeapon const& owned)
{
    PendingCast hammer;
    if (!FindLargestGroup(BONK_EXPLODING_HAMMER_SEEK, hammer.x, hammer.y, hammer.z))
        return;
    hammer.weaponId = owned.weapon.id;
    hammer.spellId = owned.weapon.spellId;
    hammer.leftMs = BONK_LIGHTS_HAMMER_LIFT_MS;
    hammer.lightsHammerLaunch = true;
    hammer.radius = BONK_EXPLODING_HAMMER_RADIUS;
    hammer.share = BONK_EXPLODING_HAMMER_SHARE;
    m_pendingCasts.push_back(hammer);
}

void BonkRun::LaunchLightsHammer(OwnedWeapon const& owned, PendingCast const& cast)
{
    if (SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_FALLING_HAMMER))
        ShowMissileBetween(look, cast.x, cast.y, cast.z + BONK_LIGHTS_HAMMER_HEIGHT, cast.x, cast.y, cast.z);
    PendingCast landing = cast;
    landing.lightsHammerLaunch = false;
    landing.lightsHammer = true;
    landing.leftMs = BONK_LIGHTS_HAMMER_FALL_MS;
    m_pendingCasts.push_back(landing);
}

void BonkRun::LandLightsHammer(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    bool const explodes = cast.radius > 0.0f;
    float const radius = explodes ? cast.radius * GetWeaponArea(owned) : GetWeaponRadius(owned);
    std::vector<Creature*> mobs = GetMobsNear(cast.x, cast.y, radius);
    if (mobs.empty())
        return;
    if (explodes)
    {
        Creature* nearest = *std::min_element(mobs.begin(), mobs.end(), [&cast](Creature const* a, Creature const* b)
        {
            return a->GetDistance2d(cast.x, cast.y) < b->GetDistance2d(cast.x, cast.y);
        });
        nearest->SendPlaySpellVisualKit(BONK_KIT_HOLY_BURST);
    }
    float const damage = GetWeaponDamage(owned) * cast.share;
    bool crit = false;
    size_t shown = explodes ? BONK_LIGHTS_HAMMER_LOOKS : 0;
    for (Creature* mob : mobs)
    {
        if (shown < BONK_LIGHTS_HAMMER_LOOKS)
        {
            mob->SendPlaySpellVisualKit(BONK_KIT_HOLY_WRATH_IMPACT);
            ++shown;
        }
        crit |= HitAsPaladin(spellInfo, owned.weapon.spellId, mob, damage);
    }
    Creature* center = m_player->GetMap()->GetCreature(cast.target);
    ResolvePaladinStrike(center && center->IsAlive() ? center : mobs.front());
    HealPaladin(owned.weapon.healPct, owned.weapon.spellId);
    if (crit)
        TriggerArtOfWar();
}

void BonkRun::Consecrate(OwnedWeapon& owned)
{
    if (!IsPaladinNear() || !m_player->IsAlive())
    {
        owned.timer = BONK_PALADIN_RETRY_MS;
        return;
    }
    owned.timer = GetWeaponCooldown(owned);
    StartKeywordCloud(owned, m_player->GetPositionX(), m_player->GetPositionY(), m_player->GetPositionZ());
}

bool BonkRun::GetPaladinCloudKind(OwnedWeapon const& owned, KeywordCloudKind& kind) const
{
    if (GetRootWeapon(owned.weapon) != BONK_WEAPON_CONSECRATION)
        return false;
    bool const hallowed = owned.weapon.id == BONK_WEAPON_HALLOWED_GROUND;
    kind.lifeMs = hallowed ? BONK_HALLOWED_GROUND_MS : BONK_CONSECRATION_MS;
    kind.pulseEveryMs = BONK_CONSECRATION_PULSE_MS;
    kind.stacks = 0;
    kind.maxAlive = hallowed ? BONK_HALLOWED_GROUND_ALIVE : BONK_CONSECRATION_ALIVE;
    kind.lookSpellId = BONK_SPELL_CONSECRATION_LOOK;
    return true;
}

void BonkRun::OnPaladinCloudPulse(OwnedWeapon const& owned, KeywordCloud const& cloud)
{
    if (GetRootWeapon(owned.weapon) != BONK_WEAPON_CONSECRATION)
        return;
    SpellEntry const* look = sSpellMgr.GetSpellEntry(owned.weapon.spellId);
    float const damage = GetWeaponDamage(owned);
    for (Creature* mob : GetMobsNear(cloud.x, cloud.y, cloud.radius))
        DealShamanHit(look, owned.weapon.spellId, mob, damage);
    PulseConsecratedRetribution(cloud);
    if (m_player->GetDistance2d(cloud.x, cloud.y) > cloud.radius)
        return;
    float const heal = owned.weapon.id == BONK_WEAPON_BLESSED_GROUND ? BONK_BLESSED_GROUND_HEAL : BONK_CONSECRATION_HEAL;
    HealPaladin(heal / std::max<size_t>(1, CountConsecrationsAround(m_player)), owned.weapon.spellId);
}

size_t BonkRun::CountConsecrationsAround(Unit const* unit) const
{
    size_t count = 0;
    for (KeywordCloud const& cloud : m_keywordClouds)
    {
        OwnedWeapon const* owned = FindOwned(cloud.weaponId);
        if (owned && GetRootWeapon(owned->weapon) == BONK_WEAPON_CONSECRATION && unit->GetDistance2d(cloud.x, cloud.y) <= cloud.radius)
            ++count;
    }
    return count;
}

bool BonkRun::IsStandingInConsecration() const
{
    return IsInConsecration(m_player);
}

bool BonkRun::IsInConsecration(Unit const* unit) const
{
    return CountConsecrationsAround(unit) > 0;
}

bool BonkRun::IsPaladinNear() const
{
    return !GetMobsInRange(BONK_PALADIN_AWARE_RANGE).empty();
}

void BonkRun::CastExorcism(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    std::vector<Creature*> mobs = GetPaladinTargets(owned.weapon.range * GetWeaponArea(owned));
    if (mobs.empty())
    {
        owned.timer = BONK_PALADIN_RETRY_MS;
        return;
    }
    SortStrongestFirst(mobs);
    uint32 const extra = m_mastery.Has(BONK_CAPSTONE_DIVINE_ILLUMINATION) ? BONK_ILLUMINATED_EXORCISMS : 0;
    mobs.resize(std::min<size_t>(mobs.size(), GetWeaponTargets(owned) + extra));
    float const twice = GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_HIT_TWICE);
    for (Creature* target : mobs)
    {
        float damage = GetWeaponDamage(owned);
        if (IsUnholy(target))
            damage *= BONK_EXORCISM_UNHOLY;
        else if (GetPaladinMobKind(target) != BONK_SPAWN_NORMAL)
            damage *= BONK_EXORCISM_ELITE;
        ShowStrike(m_player, spellInfo, target);
        if (owned.weapon.id == BONK_WEAPON_ART_OF_WAR)
            for (Creature* mob : GetMobsInRange(GetWeaponRadius(owned), target))
                HitAsPaladin(spellInfo, owned.weapon.spellId, mob, damage * BONK_ART_OF_WAR_SPLASH_SHARE);
        StrikeAsPaladin(spellInfo, owned.weapon.spellId, target, damage, twice);
    }
    owned.timer = GetWeaponCooldown(owned);
}

void BonkRun::SpinDivineStorm(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    std::vector<Creature*> mobs = GetMobsInRange(GetWeaponRadius(owned));
    if (mobs.empty())
    {
        owned.timer = BONK_PALADIN_RETRY_MS;
        return;
    }
    owned.timer = GetWeaponCooldown(owned);
    m_player->SendPlaySpellVisualKit(BONK_KIT_HOLY_WRATH_CAST);
    float const damage = GetWeaponDamage(owned);
    bool crit = false;
    size_t shown = 0;
    for (Creature* mob : mobs)
    {
        if (shown < BONK_DIVINE_STORM_LOOKS)
        {
            mob->SendPlaySpellVisualKit(BONK_KIT_HOLY_WRATH_IMPACT);
            ++shown;
        }
        crit |= HitAsPaladin(spellInfo, owned.weapon.spellId, mob, damage);
        if (owned.weapon.id == BONK_WEAPON_WAKE_OF_ASHES && mob->IsAlive())
        {
            ApplyMasterySlow(mob, BONK_WAKE_OF_ASHES_SLOW);
            int32 durationMs = BONK_WAKE_OF_ASHES_STUN_MS;
            if (IsUnholy(mob) && CanBeStunned(mob) && LimitStun(mob, durationMs))
                HoldMob(mob, spellInfo, SPELL_AURA_MOD_STUN, durationMs);
        }
    }
    ResolvePaladinStrike(mobs.front(), crit);
    ChargeCommandFromStorm(mobs);
    if (crit)
        TriggerArtOfWar();
    float const cap = owned.weapon.id == BONK_WEAPON_DIVINE_TEMPEST ? BONK_DIVINE_TEMPEST_HEAL_CAP : BONK_DIVINE_STORM_HEAL_CAP;
    HealPaladin(std::min(BONK_DIVINE_STORM_HEAL * mobs.size(), cap), owned.weapon.spellId);
}

void BonkRun::PulseRetributionAura(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    std::vector<Creature*> mobs = GetMobsInRange(GetWeaponRadius(owned));
    if (mobs.empty())
    {
        owned.timer = BONK_PALADIN_RETRY_MS;
        return;
    }
    owned.timer = GetWeaponCooldown(owned);
    float const damage = GetWeaponDamage(owned);
    for (Creature* mob : mobs)
        DealShamanHit(spellInfo, owned.weapon.spellId, mob, IsInConsecration(mob) ? damage * BONK_CONSECRATED_RETRIBUTION : damage);
}

void BonkRun::PulseConsecratedRetribution(KeywordCloud const& cloud)
{
    float const share = m_mastery.Special(BONK_SPECIAL_CONSECRATED_RETRIBUTION);
    OwnedWeapon const* aura = share > 0.0f ? FindOwnedByBehavior(BONK_BEHAVIOR_RETRIBUTION_AURA) : nullptr;
    if (!aura)
        return;
    SpellEntry const* look = sSpellMgr.GetSpellEntry(aura->weapon.spellId);
    float const damage = GetWeaponDamage(*aura) * BONK_RETRIBUTION_STRUCK_SHARE * share / 100.0f;
    for (Creature* mob : GetMobsNear(cloud.x, cloud.y, cloud.radius))
        DealShamanHit(look, aura->weapon.spellId, mob, damage);
}

void BonkRun::OnPaladinStruck(Creature* attacker)
{
    if (m_player->GetClass() != CLASS_PALADIN || !attacker || !attacker->IsAlive() || IsPeriodicHit())
        return;
    OwnedWeapon const* aura = FindOwnedByBehavior(BONK_BEHAVIOR_RETRIBUTION_AURA);
    if (!aura || !attacker->IsAlive() || !TakeRateSlot(m_retributionTimes, BONK_RETRIBUTION_PER_SEC))
        return;
    DealShamanHit(sSpellMgr.GetSpellEntry(aura->weapon.spellId), aura->weapon.spellId, attacker, GetWeaponDamage(*aura) * BONK_RETRIBUTION_STRUCK_SHARE);
}

void BonkRun::TryPaladinLastStands()
{
    if (!m_player->IsAlive())
        return;
    float const health = m_player->GetHealthPercent();
    if (FindOwned(BONK_WEAPON_ARDENT_DEFENDER) && health < BONK_ARDENT_DEFENDER_HEALTH && m_totalMs >= m_ardentDefenderReadyMs)
    {
        m_ardentDefenderReadyMs = m_totalMs + BONK_ARDENT_DEFENDER_EVERY_MS;
        ShowDivineBubble(BONK_ARDENT_DEFENDER_MS);
    }
    if (FindOwned(BONK_WEAPON_LAY_ON_HANDS) && health < BONK_LAY_ON_HANDS_HEALTH && m_totalMs >= m_layOnHandsReadyMs)
    {
        m_layOnHandsReadyMs = m_totalMs + BONK_LAY_ON_HANDS_EVERY_MS;
        if (SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_LAY_ON_HANDS))
            ShowStrike(m_player, look, m_player);
        SupportScope scope(*this, WeaponSupport(*FindOwned(BONK_WEAPON_LAY_ON_HANDS)));
        HealHero(m_player->GetMaxHealth(), BONK_SPELL_LAY_ON_HANDS);
    }
}

uint32 BonkRun::ApplyPaladinDamageTaken(uint32 damage) const
{
    if (m_player->GetClass() != CLASS_PALADIN)
        return damage;
    float scale = 1.0f;
    if (FindOwned(BONK_WEAPON_DEVOTION_AURA))
        scale *= BONK_DEVOTION_TAKEN;
    if (m_mastery.Has(BONK_CAPSTONE_GUARDIAN_OF_THE_LIGHT) && IsStandingInConsecration())
        scale *= BONK_GUARDIAN_TAKEN;
    return std::max(1u, uint32(damage * scale));
}

void BonkRun::HammerOfJustice(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    std::vector<Creature*> mobs = GetPaladinTargets(owned.weapon.range * GetWeaponArea(owned));
    if (mobs.empty())
    {
        owned.timer = BONK_PALADIN_RETRY_MS;
        return;
    }
    owned.timer = GetWeaponCooldown(owned);
    SortStrongestFirst(mobs);
    mobs.resize(std::min<size_t>(mobs.size(), GetWeaponTargets(owned)));
    SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_JUSTICE_HAMMER);
    for (Creature* target : mobs)
    {
        int32 stunMs = BONK_JUSTICE_STUN_MS;
        bool const stuns = CanBeStunned(target) && LimitStun(target, stunMs);
        if (stuns)
            ShowStrike(m_player, look ? look : spellInfo, target);
        else
            ShowThrowAtSpot(m_player, look ? look : spellInfo, target);
        PendingCast hammer;
        hammer.weaponId = owned.weapon.id;
        hammer.spellId = owned.weapon.spellId;
        hammer.target = target->GetObjectGuid();
        hammer.leftMs = int32(m_player->GetDistance(target) / BONK_JUSTICE_SPEED * IN_MILLISECONDS);
        hammer.justiceHammer = true;
        hammer.stunMs = stuns ? stunMs : 0;
        m_pendingCasts.push_back(hammer);
    }
}

void BonkRun::LandJusticeHammer(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    Creature* target = m_player->GetMap()->GetCreature(cast.target);
    if (!target || !target->IsAlive())
        return;
    float const damage = GetWeaponDamage(owned);
    if (owned.weapon.id == BONK_WEAPON_HAMMER_OF_THE_RIGHTEOUS)
        for (Creature* mob : GetMobsInRange(GetWeaponRadius(owned), target))
            HitAsPaladin(spellInfo, owned.weapon.spellId, mob, damage);
    StrikeAsPaladin(spellInfo, owned.weapon.spellId, target, damage, GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_HIT_TWICE));
    if (!cast.stunMs)
        target->PlayDistanceSound(BONK_SOUND_THROWN_IMPACT);
    else if (target->IsAlive())
        HoldMob(target, spellInfo, SPELL_AURA_MOD_STUN, cast.stunMs);
}

void BonkRun::ChargeDivineShield(OwnedWeapon& owned)
{
    owned.timer = BONK_PALADIN_IDLE_MS;
    m_divineShieldCharged = true;
}

bool BonkRun::BlockWithDivineShield(uint32 damage)
{
    if (!m_divineShieldCharged || m_player->GetClass() != CLASS_PALADIN || damage <= m_player->GetMaxHealth() * BONK_DIVINE_BLOCK_HIT / 100.0f)
        return false;
    auto itr = std::find_if(m_weapons.begin(), m_weapons.end(), [](OwnedWeapon const& owned) { return owned.weapon.behavior == BONK_BEHAVIOR_DIVINE_SHIELD; });
    if (itr == m_weapons.end())
        return false;
    OwnedWeapon* shield = &*itr;
    m_divineShieldCharged = false;
    shield->timer = GetWeaponCooldown(*shield);
    ShowDivineBubble(BONK_DIVINE_FLASH_MS);
    if (shield->weapon.id == BONK_WEAPON_HOLY_SHIELD)
        if (SpellEntry const* look = sSpellMgr.GetSpellEntry(shield->weapon.spellId))
        {
            m_player->SendPlaySpellVisualKit(BONK_KIT_HOLY_WRATH_CAST);
            for (Creature* mob : GetMobsInRange(GetWeaponRadius(*shield)))
                DealShamanHit(look, shield->weapon.spellId, mob, GetWeaponDamage(*shield));
        }
    return true;
}

void BonkRun::ShowDivineBubble(int32 lengthMs)
{
    m_player->AddAura(BONK_SPELL_DIVINE_SHIELD);
    if (SpellAuraHolder* holder = m_player->GetSpellAuraHolder(BONK_SPELL_DIVINE_SHIELD))
    {
        holder->SetAuraMaxDuration(lengthMs);
        holder->SetAuraDuration(lengthMs);
        holder->RefreshHolder();
    }
}

bool BonkRun::IsDivinelyShielded() const
{
    return m_player->HasAura(BONK_SPELL_DIVINE_SHIELD);
}

float BonkRun::GetSealOfLightHeal(float damageBonus) const
{
    return std::min(BONK_LIGHT_HEAL * (1.0f + damageBonus / 100.0f), BONK_MAX_LIGHT_HEAL);
}

float BonkRun::GetRighteousShare(BonkWeapon const& weapon, float damageBonus) const
{
    float const factor = weapon.id == BONK_WEAPON_SEAL_OF_THE_TEMPLAR ? BONK_TEMPLAR_SHARE_FACTOR :
        weapon.id == BONK_WEAPON_SEAL_OF_VENGEANCE ? BONK_VENGEANCE_SHARE_FACTOR : 1.0f;
    return std::min(BONK_RIGHTEOUS_SHARE * (1.0f + damageBonus / 100.0f), BONK_MAX_RIGHTEOUS_SHARE) * factor;
}

bool BonkRun::GetPaladinStrength(BonkWeapon const& weapon, float damageBonus, WeaponStrength& strength) const
{
    if (weapon.behavior != BONK_BEHAVIOR_SEAL)
        return false;
    if (GetRootWeapon(weapon) == BONK_WEAPON_SEAL_OF_RIGHTEOUSNESS)
    {
        strength.sentence = BONK_STRING_STRENGTH_HOLY_HIT;
        strength.label = BONK_STRING_STRENGTH_HOLY_HIT_LABEL;
        strength.value = GetRighteousShare(weapon, damageBonus);
        return true;
    }
    if (GetRootWeapon(weapon) != BONK_WEAPON_SEAL_OF_LIGHT)
        return false;
    strength.sentence = BONK_STRING_STRENGTH_STRIKE_HEAL;
    strength.label = BONK_STRING_STRENGTH_STRIKE_HEAL_LABEL;
    strength.value = GetSealOfLightHeal(damageBonus);
    return true;
}

float BonkRun::GetPaladinDamageMultiplier(Unit const* victim) const
{
    if (m_player->GetClass() != CLASS_PALADIN)
        return 1.0f;
    float scale = IsJudged(victim) ? BONK_JUDGED_BONUS : 1.0f;
    if (IsExposedToHammer(victim))
        scale *= 1.0f + m_mastery.Special(BONK_SPECIAL_HAMMER_EXPOSE) / 100.0f;
    if (IsStandingInConsecration())
        scale *= FindOwned(BONK_WEAPON_HALLOWED_GROUND) ? BONK_HALLOWED_GROUND_BONUS : BONK_CONSECRATION_BONUS;
    return scale;
}

// The two invisible numbers a paladin gets for standing in their own Consecration, made visible:
// the damage bonus (which tracks the Consecration / Hallowed Ground evolution) and, when the
// Guardian of the Light capstone is learned, the damage reduction. Both persist while the paladin
// stands in the cloud and drop when they leave, so UpdateOwnCombat refreshes them every tick.
void BonkRun::UpdateConsecrationAura()
{
    if (m_player->GetClass() != CLASS_PALADIN || !m_player->IsAlive() || !IsStandingInConsecration())
    {
        m_player->RemoveAurasDueToSpell(BONK_SPELL_CONSECRATION_MIGHT);
        m_player->RemoveAurasDueToSpell(BONK_SPELL_CONSECRATION_GUARD);
        return;
    }

    float const bonus = FindOwned(BONK_WEAPON_HALLOWED_GROUND) ? BONK_HALLOWED_GROUND_BONUS : BONK_CONSECRATION_BONUS;
    ApplyConsecrationAura(BONK_SPELL_CONSECRATION_MIGHT, uint32(std::lround((bonus - 1.0f) * 100.0f)));

    if (m_mastery.Has(BONK_CAPSTONE_GUARDIAN_OF_THE_LIGHT))
        ApplyConsecrationAura(BONK_SPELL_CONSECRATION_GUARD, uint32(std::lround((1.0f - BONK_GUARDIAN_TAKEN) * 100.0f)));
    else
        m_player->RemoveAurasDueToSpell(BONK_SPELL_CONSECRATION_GUARD);
}

// A Consecration state has no countdown of its own - it lasts as long as the paladin stands in the
// cloud - so the aura is applied permanently and the live percent is pushed into its tooltip text.
void BonkRun::ApplyConsecrationAura(uint32 spellId, uint32 percent)
{
    if (!m_player->HasAura(spellId))
        m_player->AddAura(spellId, ADD_AURA_PERMANENT);
    BonkAuraEntry const* entry = sBonkAura.Get(spellId);
    if (!entry || !m_player->GetBonkPlayer()->IsAddonReady())
        return;
    m_player->GetBonkPlayer()->SendAuraText(spellId,
        sBonkAura.Format(*entry, GetLocale(), { std::to_string(percent) }));
}

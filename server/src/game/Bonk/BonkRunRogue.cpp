#include "BonkRun.h"
#include "BonkMobAI.h"
#include "BonkPlayer.h"
#include "Creature.h"
#include "Map.h"
#include "Player.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "Utilities/Random.h"

#include <algorithm>

namespace
{
    uint32 const BONK_WEAPON_MAIN_GAUCHE      = 612;
    uint32 const BONK_WEAPON_SABER_SLASH      = 613;
    uint32 const BONK_WEAPON_ENDLESS_FLURRY   = 614;
    uint32 const BONK_WEAPON_SHADOW_BLADES    = 615;
    uint32 const BONK_WEAPON_DEADLY_THROW     = 617;
    uint32 const BONK_WEAPON_MURDEROUS_INTENT = 618;
    uint32 const BONK_WEAPON_GRAND_FINALE     = 619;
    uint32 const BONK_WEAPON_TOXIC_BLADE      = 620;
    uint32 const BONK_WEAPON_BLINDSIDE        = 621;
    uint32 const BONK_WEAPON_CRIPPLING_POISON = 622;
    uint32 const BONK_WEAPON_INSTANT_POISON   = 623;
    uint32 const BONK_WEAPON_CALTROPS         = 624;
    uint32 const BONK_WEAPON_DEADLY_FAN       = 625;
    uint32 const BONK_WEAPON_VENOM_SPLASH     = 626;
    uint32 const BONK_WEAPON_EXSANGUINATE     = 627;
    uint32 const BONK_WEAPON_SHURIKEN_STORM   = 628;
    uint32 const BONK_WEAPON_SHADOWY_SHURIKEN = 629;
    uint32 const BONK_WEAPON_CHEAP_SHOT       = 630;
    uint32 const BONK_WEAPON_FIND_WEAKNESS    = 631;
    uint32 const BONK_WEAPON_VANISH           = 632;
    uint32 const BONK_WEAPON_SYMBOLS_OF_DEATH = 633;
    uint32 const BONK_WEAPON_RIPOSTE          = 634;
    uint32 const BONK_WEAPON_SMOKE_BOMB       = 635;

    uint32 const BONK_SPELL_SINISTER_STRIKE   = 1752;
    uint32 const BONK_KIT_SPREE_SLASH         = 6351;
    uint32 const BONK_SPELL_EVISCERATE        = 2098;
    uint32 const BONK_SPELL_AMBUSH            = 8676;
    uint32 const BONK_SPELL_BLADE_FLURRY      = 33466;
    uint32 const BONK_SPELL_EVASION           = 5277;
    uint32 const BONK_SPELL_SHADOW_DANCE_LOOK = 11327;
    uint32 const BONK_SPELL_SHADOW_STRIKE     = 26048;
    uint32 const BONK_SPELL_INSTANT_POISON    = 8680;
    uint32 const BONK_SPELL_CRIPPLING_POISON  = 3409;
    uint32 const BONK_SPELL_CHEAP_SHOT        = 1833;
    uint32 const BONK_SPELL_SAP               = 2070;
    uint32 const BONK_SPELL_RIPOSTE           = 14251;
    uint32 const BONK_SPELL_CALTROPS_LOOK     = 21070;
    uint32 const BONK_SPELL_SMOKE_BOMB_LOOK   = 8817;
    uint32 const BONK_SPELL_SHURIKEN_LOOK     = 4165;
    uint32 const BONK_KIT_THROW               = 1184;
    uint32 const BONK_THROW_ANIMATION_GAP_MS  = 400;
    uint32 const BONK_KIT_SHURIKEN_IMPACT     = 1946;
    uint32 const BONK_KIT_SMOKE_BOMB_SOUND    = 7500;
    uint32 const BONK_KIT_CALTROPS_SOUND      = 7501;
    uint32 const BONK_KIT_CHEAP_SHOT_SOUND    = 7502;
    float const BONK_SHURIKEN_SPEED           = 20.0f;

    float const BONK_FLURRY_RADIUS            = 8.0f;
    float const BONK_FLURRY_DAMAGE_SHARE      = 0.5f;
    uint32 const BONK_SPREE_STRIKES_PER_COUNT = 2;
    int32 const BONK_SPREE_GAP_MS             = 200;
    uint32 const BONK_MUTILATE_STABS          = 2;
    uint32 const BONK_BLINDSIDE_STABS         = 3;
    float const BONK_BLINDSIDE_HEALTH         = 35.0f;
    float const BONK_SECRET_TECHNIQUE_RADIUS  = 8.0f;
    float const BONK_VENDETTA_CAP             = 15.0f;
    float const BONK_MUTILATE_POISONED        = 1.3f;
    uint32 const BONK_TOXIC_BLADE_STACKS      = 2;
    uint32 const BONK_ENVENOM_EXTRA_POISON    = 2;
    float const BONK_ROGUE_CRIT_SCALE         = 2.0f;
    float const BONK_SHADOW_DANCE_BONUS       = 1.3f;
    int32 const BONK_EVASION_DODGE            = 50;
    float const BONK_EVASION_MAX_DODGE        = 85.0f;
    float const BONK_ROGUE_AWARE_RANGE        = 15.0f;
    uint32 const BONK_ROGUE_PRUNE_MS          = 5000;
    int32 const BONK_FAN_ECHO_MS              = 300;
    int32 const BONK_ROGUE_IDLE_MS            = 1000;
    int32 const BONK_ROGUE_RETRY_MS           = 250;
    uint32 const BONK_FAN_KNIVES              = 12;
    uint32 const BONK_ROGUE_SWING_GAP_MS      = 400;

    float const BONK_MAIN_GAUCHE_REACH        = 8.0f;
    uint32 const BONK_SABER_SLASH_CHAIN       = 3;
    int32 const BONK_DEADLY_THROW_SLOW        = -50;
    int32 const BONK_DEADLY_THROW_SLOW_MS     = 3000;
    uint32 const BONK_MURDEROUS_STRIKES       = 2;
    uint32 const BONK_MURDEROUS_CAP           = 20;
    int32 const BONK_CRIPPLING_SLOW           = -30;
    int32 const BONK_CRIPPLING_SLOW_MS        = 3000;
    float const BONK_CRIPPLING_BONUS          = 1.15f;
    float const BONK_INSTANT_POISON_SHARE     = 0.3f;
    uint32 const BONK_CALTROPS_MS             = 4000;
    int32 const BONK_CALTROPS_PULSE_MS        = 1000;
    size_t const BONK_CALTROPS_ALIVE          = 3;
    int32 const BONK_CALTROPS_SLOW_MS         = 1500;
    uint32 const BONK_EXSANGUINATE_SECONDS    = 4;
    uint32 const BONK_SPELL_POISON_VIAL       = 14897;
    uint32 const BONK_KIT_POISON_BOMB         = 6377;
    float const BONK_POISON_BOMB_REACH        = 20.0f;
    float const BONK_POISON_BOMB_SPEED        = 25.0f;
    uint32 const BONK_POISON_BOMB_STACKS      = 4;
    uint32 const BONK_MUTILATE_STACKS_PER     = 5;
    uint32 const BONK_MUTILATE_ENVENOM_POISON = 10;
    int32 const BONK_MUTILATE_ENVENOM_CUT_MS  = 500;
    uint32 const BONK_EVISCERATE_CHAIN        = 3;
    int32 const BONK_SPREE_EVISCERATE_MS      = 500;
    float const BONK_EVISCERATE_REACH         = 8.0f;
    uint32 const BONK_SHURIKEN_STORM_JUMPS    = 2;
    float const BONK_SHURIKEN_STORM_REACH     = 10.0f;
    int32 const BONK_SHADOWY_SHURIKEN_MS      = 1500;
    int32 const BONK_CHEAP_SHOT_MS            = 1000;
    uint32 const BONK_FIND_WEAKNESS_MS        = 6000;
    float const BONK_FIND_WEAKNESS_BONUS      = 1.2f;
    uint32 const BONK_AMBUSH_REPEAT_MS        = 1000;
    int32 const BONK_VANISH_MS                = 2000;
    size_t const BONK_SYMBOLS_TARGETS         = 5;
    size_t const BONK_RIPOSTE_PER_SEC         = 5;
    uint32 const BONK_SMOKE_BOMB_MS           = 5000;
    float const BONK_SMOKE_BOMB_MISS          = 50.0f;
    float const BONK_SUBTLETY_SPLASH_RADIUS   = 8.0f;
    float const BONK_SUBTLETY_SPLASH_SHARE    = 0.5f;
    uint32 const BONK_BLADE_DANCER_EXTRA      = 1;
    float const BONK_BLADE_DANCER_SHARE       = 0.6f;

    void SetAuraLength(Player* player, uint32 spellId, int32 durationMs)
    {
        SpellAuraHolder* holder = player->GetSpellAuraHolder(spellId);
        if (!holder)
            return;
        holder->SetAuraMaxDuration(durationMs);
        holder->SetAuraDuration(durationMs);
        holder->RefreshHolder();
    }

    bool IsRogueNormalMob(Creature const* mob)
    {
        BonkMobAI const* ai = mob ? dynamic_cast<BonkMobAI const*>(mob->AI()) : nullptr;
        return ai && ai->GetKind() == BONK_SPAWN_NORMAL;
    }
}

void BonkRun::ResetRogueState()
{
    m_rogueTouched.clear();
    m_findWeakness.clear();
    m_ambushReadyMs.clear();
    m_riposteTimes.clear();
    m_roguePruneMs = 0;
    m_player->RemoveAurasDueToSpell(BONK_SPELL_ENVENOM_AURA);
    m_player->RemoveAurasDueToSpell(BONK_SPELL_SHADOW_DANCE_AURA);
    m_smokeUntilMs = 0;
    m_spreeBonus = 0;
    for (uint32 spellId : { BONK_SPELL_BLADE_FLURRY, BONK_SPELL_EVASION })
        if (m_player->HasAura(spellId))
            m_player->RemoveAurasDueToSpell(spellId);
}

void BonkRun::UpdateRogue(uint32 diff)
{
    if (m_player->GetClass() != CLASS_ROGUE)
        return;
    m_roguePruneMs += diff;
    if (m_roguePruneMs < BONK_ROGUE_PRUNE_MS)
        return;
    m_roguePruneMs = 0;
    Map* map = m_player->GetMap();
    for (auto itr = m_rogueTouched.begin(); itr != m_rogueTouched.end();)
    {
        Creature* mob = map->GetCreature(*itr);
        if (!mob || !mob->IsAlive())
            itr = m_rogueTouched.erase(itr);
        else
            ++itr;
    }
    for (auto itr = m_findWeakness.begin(); itr != m_findWeakness.end();)
    {
        if (itr->second <= m_totalMs)
            itr = m_findWeakness.erase(itr);
        else
            ++itr;
    }
    for (auto itr = m_ambushReadyMs.begin(); itr != m_ambushReadyMs.end();)
    {
        if (itr->second <= m_totalMs)
            itr = m_ambushReadyMs.erase(itr);
        else
            ++itr;
    }
}

bool BonkRun::FireRogueSpell(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    switch (owned.weapon.behavior)
    {
        case BONK_BEHAVIOR_SINISTER_STRIKE:
        case BONK_BEHAVIOR_EVISCERATE:
        case BONK_BEHAVIOR_MUTILATE:        StabNearest(owned, spellInfo); break;
        case BONK_BEHAVIOR_BLADE_FLURRY:    StartBladeFlurry(owned); break;
        case BONK_BEHAVIOR_KILLING_SPREE:   StartKillingSpree(owned); break;
        case BONK_BEHAVIOR_DEADLY_POISON:   ThrowPoisonBomb(owned); break;
        case BONK_BEHAVIOR_AMBUSH:          owned.timer = BONK_ROGUE_IDLE_MS; break;
        case BONK_BEHAVIOR_FAN_OF_KNIVES:   ThrowFanOfKnives(owned, spellInfo, true); break;
        case BONK_BEHAVIOR_ENVENOM:         CastEnvenom(owned, spellInfo); break;
        case BONK_BEHAVIOR_SHURIKEN_TOSS:   TossShurikens(owned, spellInfo); break;
        case BONK_BEHAVIOR_SHADOW_DANCE:    StartShadowDance(owned); break;
        case BONK_BEHAVIOR_EVASION:         Evade(owned); break;
        default:                            return false;
    }
    return true;
}

void BonkRun::ResolveRogueCast(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    if (cast.killingSpree)
        StrikeSpree(owned, spellInfo, cast.hops != 0);
    else if (cast.fanOfKnives)
        ThrowFanOfKnives(owned, spellInfo, false);
    else if (cast.shadowyShuriken)
        BurstShadowyShuriken(owned, cast);
    else if (cast.poisonBomb)
        LandPoisonBomb(owned, cast);
}

bool BonkRun::IsRogueNear() const
{
    return !GetMobsInRange(BONK_ROGUE_AWARE_RANGE).empty();
}

void BonkRun::SwingRogueBlades()
{
    if (!m_player->IsAlive())
        return;
    uint32 const now = WorldTimer::getMSTime();
    if (WorldTimer::getMSTimeDiff(m_swingAnimationMs, now) < BONK_ROGUE_SWING_GAP_MS)
        return;
    m_swingAnimationMs = now;
    m_player->HandleEmote(GetSwingEmote());
}

void BonkRun::StabRogue(OwnedWeapon& owned, SpellEntry const* look, Creature* target, float share, bool flurries)
{
    if (!look || !target || !target->IsAlive())
        return;
    uint32 const credit = owned.weapon.spellId;
    float const damage = GetWeaponDamage(owned) * share;
    ShowStrike(m_player, look, target);
    DealRogueDamage(credit, look, target, damage);

    float const twice = GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_HIT_TWICE);
    if (twice > 0.0f && roll_chance_f(twice))
        DealRogueDamage(credit, look, target, damage);

    float const cleave = GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_CLEAVE) / 100.0f;
    if (cleave > 0.0f)
    {
        uint32 hit = 0;
        for (Creature* mob : GetMobsInRange(BONK_CLEAVE_RADIUS, target))
        {
            if (hit >= BONK_SPELL_CLEAVE_TARGETS)
                break;
            if (mob == target)
                continue;
            DealRogueDamage(credit, look, mob, damage * cleave);
            ++hit;
        }
    }

    OnRogueHit(target, damage, flurries, credit);
}

void BonkRun::DealRogueDamage(uint32 creditSpellId, SpellEntry const* fallback, Unit* target, float damage)
{
    SpellEntry const* credit = sSpellMgr.GetSpellEntry(creditSpellId);
    DealShamanHit(credit && credit->CanCrit() ? credit : fallback, creditSpellId, target, damage);
}

void BonkRun::OnRogueHit(Creature* target, float damage, bool flurries, uint32 creditSpellId)
{
    StingWithInstantPoison(target, damage, flurries);
    PoisonFromCoatings(target);
    OpenOnRogueTarget(target, false);
    if (flurries)
        FlurryFrom(target, damage, creditSpellId);
}

void BonkRun::StingWithInstantPoison(Creature* target, float damage, bool showLook)
{
    OwnedWeapon const* deadly = FindOwnedByBehavior(BONK_BEHAVIOR_DEADLY_POISON);
    if (!deadly || deadly->weapon.id != BONK_WEAPON_INSTANT_POISON || !target || !target->IsAlive())
        return;
    SpellEntry const* sting = sSpellMgr.GetSpellEntry(BONK_SPELL_INSTANT_POISON);
    if (!sting)
        return;
    if (showLook)
        ShowStrike(m_player, sting, target);
    DealRogueDamage(deadly->weapon.spellId, sting, target, damage * BONK_INSTANT_POISON_SHARE);
}

void BonkRun::PoisonWithRogue(OwnedWeapon const& owned, Creature* mob, uint32 stacks)
{
    stacks += uint32(GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_STACKS));
    ApplyWeaponKeyword(owned, mob, BONK_KEYWORD_POISON, stacks);
}

void BonkRun::PoisonFromCoatings(Creature* target)
{
    if (!target || !target->IsAlive())
        return;
    OwnedWeapon const* deadly = FindOwnedByBehavior(BONK_BEHAVIOR_DEADLY_POISON);
    OwnedWeapon const* envenom = m_player->HasAura(BONK_SPELL_ENVENOM_AURA) ? FindOwnedByBehavior(BONK_BEHAVIOR_ENVENOM) : nullptr;
    OwnedWeapon const* source = deadly ? deadly : envenom;
    bool const masterPoisoner = m_mastery.Has(BONK_CAPSTONE_MASTER_POISONER);
    if (!source)
    {
        if (masterPoisoner)
            ApplyKeyword(target, BONK_KEYWORD_POISON, 1);
        return;
    }
    uint32 stacks = envenom ? BONK_ENVENOM_EXTRA_POISON + uint32(m_mastery.Special(BONK_SPECIAL_VENOMOUS_WOUNDS)) : 0;
    if (deadly)
        stacks += deadly->weapon.applyStacks + uint32(GetSpellUpgrade(*deadly, BONK_SPELL_UPGRADE_STACKS));
    if (masterPoisoner)
        ++stacks;
    ApplyWeaponKeyword(*source, target, BONK_KEYWORD_POISON, stacks);
    if (deadly && deadly->weapon.id == BONK_WEAPON_CRIPPLING_POISON)
        if (SpellEntry const* crippling = sSpellMgr.GetSpellEntry(BONK_SPELL_CRIPPLING_POISON))
            SlowNormalMob(target, crippling, &BONK_CRIPPLING_SLOW, BONK_CRIPPLING_SLOW_MS);
}

void BonkRun::OpenOnRogueTarget(Creature* target, bool forced)
{
    if (!target)
        return;
    bool const fresh = m_rogueTouched.insert(target->GetObjectGuid()).second;
    bool const dancing = m_player->HasAura(BONK_SPELL_SHADOW_DANCE_AURA);
    if (!fresh && !dancing && !forced)
        return;
    OwnedWeapon const* ambush = FindOwnedByBehavior(BONK_BEHAVIOR_AMBUSH);
    SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_AMBUSH);
    if (!ambush || !look || !target->IsAlive())
        return;
    uint32& readyMs = m_ambushReadyMs[target->GetObjectGuid()];
    if (!fresh && readyMs > m_totalMs)
        return;
    readyMs = m_totalMs + BONK_AMBUSH_REPEAT_MS;
    float const damage = GetWeaponDamage(*ambush);
    ShowStrike(m_player, look, target);
    DealShamanHit(look, ambush->weapon.spellId, target, damage);
    if (fresh && !IsRogueNormalMob(target))
        for (uint32 extra = uint32(m_mastery.Special(BONK_SPECIAL_PREMEDITATION)); extra && target->IsAlive(); --extra)
            DealShamanHit(look, ambush->weapon.spellId, target, damage);
    OnDanseMacabre();
    float const twice = GetSpellUpgrade(*ambush, BONK_SPELL_UPGRADE_HIT_TWICE);
    if (twice > 0.0f && roll_chance_f(twice))
        DealShamanHit(look, ambush->weapon.spellId, target, damage);
    PoisonFromCoatings(target);
    if (m_mastery.Has(BONK_CAPSTONE_MASTER_OF_SUBTLETY))
        for (Creature* mob : GetMobsInRange(BONK_SUBTLETY_SPLASH_RADIUS * GetWeaponArea(*ambush), target))
            if (mob != target)
                DealShamanHit(look, ambush->weapon.spellId, mob, damage * BONK_SUBTLETY_SPLASH_SHARE);

    if (ambush->weapon.id == BONK_WEAPON_FIND_WEAKNESS)
        m_findWeakness[target->GetObjectGuid()] = m_totalMs + BONK_FIND_WEAKNESS_MS;
    if (ambush->weapon.id == BONK_WEAPON_CHEAP_SHOT && target->IsAlive() && IsRogueNormalMob(target))
    {
        int32 durationMs = BONK_CHEAP_SHOT_MS;
        if (LimitStun(target, durationMs))
        {
            HoldMob(target, sSpellMgr.GetSpellEntry(BONK_SPELL_CHEAP_SHOT), SPELL_AURA_MOD_STUN, durationMs);
            target->SendPlaySpellVisualKit(BONK_KIT_CHEAP_SHOT_SOUND);
        }
    }
}

bool BonkRun::IsBladeFlurryActive(OwnedWeapon const& flurry) const
{
    return flurry.weapon.id == BONK_WEAPON_ENDLESS_FLURRY || m_player->HasAura(BONK_SPELL_BLADE_FLURRY);
}

void BonkRun::FlurryFrom(Creature* target, float damage, uint32 creditSpellId)
{
    OwnedWeapon const* flurry = FindOwnedByBehavior(BONK_BEHAVIOR_BLADE_FLURRY);
    bool const active = flurry && IsBladeFlurryActive(*flurry);
    uint32 extra = active ? uint32(std::max(0.0f, flurry->weapon.behaviorValue)) : 0;
    bool const dancer = m_mastery.Has(BONK_CAPSTONE_BLADE_DANCER);
    if (dancer)
        extra += BONK_BLADE_DANCER_EXTRA;
    if (!target || !extra)
        return;
    bool const shadow = active && flurry->weapon.id == BONK_WEAPON_SHADOW_BLADES;
    uint32 const credit = active ? flurry->weapon.spellId : creditSpellId;
    SpellEntry const* look = sSpellMgr.GetSpellEntry(shadow ? BONK_SPELL_SHADOW_STRIKE : BONK_SPELL_SINISTER_STRIKE);
    if (!look)
        return;
    float const share = damage * (dancer ? BONK_BLADE_DANCER_SHARE : BONK_FLURRY_DAMAGE_SHARE);
    uint32 hit = 0;
    for (Creature* mob : GetMobsInRange(BONK_FLURRY_RADIUS, target))
    {
        if (hit >= extra)
            break;
        if (mob == target || !m_player->IsWithinLOSInMap(mob))
            continue;
        ShowStrike(m_player, look, mob);
        if (shadow)
            DealShamanHit(look, credit, mob, share);
        else
            DealRogueDamage(credit, look, mob, share);
        OnRogueHit(mob, share, false);
        if (shadow)
            OpenOnRogueTarget(mob, true);
        ++hit;
    }
}

void BonkRun::StartBladeFlurry(OwnedWeapon& owned)
{
    if (owned.weapon.id != BONK_WEAPON_ENDLESS_FLURRY)
    {
        uint32 bladeFlurryUntilMs = 0;
        OpenRogueWindow(owned, bladeFlurryUntilMs, BONK_SPELL_BLADE_FLURRY);
        return;
    }
    owned.timer = BONK_ROGUE_IDLE_MS;
    if (m_player->IsAlive() && !m_player->HasAura(BONK_SPELL_BLADE_FLURRY))
        m_player->AddAura(BONK_SPELL_BLADE_FLURRY, ADD_AURA_PERMANENT);
}

void BonkRun::StabNearest(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    uint32 const wanted = GetWeaponTargets(owned);
    std::vector<Creature*> mobs = GetMobsInRange(GetStrikeRange(owned));
    if (owned.weapon.target == BONK_TARGET_STRONGEST)
        SortStrongestFirst(mobs);
    std::vector<Creature*> targets;
    for (Creature* mob : mobs)
    {
        if (targets.size() >= wanted)
            break;
        if (m_player->IsWithinLOSInMap(mob))
            targets.push_back(mob);
    }
    if (targets.empty())
    {
        owned.timer = BONK_ROGUE_RETRY_MS;
        return;
    }
    owned.timer = GetWeaponCooldown(owned);
    bool hastensEnvenom = false;
    for (Creature* mob : targets)
    {
        if (owned.weapon.behavior == BONK_BEHAVIOR_MUTILATE)
        {
            hastensEnvenom |= GetKeywordStacks(mob, BONK_KEYWORD_POISON) >= BONK_MUTILATE_ENVENOM_POISON;
            Mutilate(owned, spellInfo, mob);
            continue;
        }
        StabRogue(owned, spellInfo, mob, 1.0f, true);
        if (GetRootWeapon(owned.weapon) == BONK_WEAPON_SINISTER_STRIKE && mob->IsAlive() && roll_chance_f(m_mastery.Special(BONK_SPECIAL_DREADBLADES)))
            StabRogue(owned, spellInfo, mob, 1.0f, true);
        if (owned.weapon.id == BONK_WEAPON_MAIN_GAUCHE)
            StabOffHand(owned, spellInfo, mob, targets);
        else if (owned.weapon.id == BONK_WEAPON_SABER_SLASH)
            SlashOnward(owned, spellInfo, mob);
        else if (owned.weapon.id == BONK_WEAPON_DEADLY_THROW)
            if (SpellEntry const* crippling = sSpellMgr.GetSpellEntry(BONK_SPELL_CRIPPLING_POISON))
                SlowNormalMob(mob, crippling, &BONK_DEADLY_THROW_SLOW, BONK_DEADLY_THROW_SLOW_MS);
        if (owned.weapon.behavior == BONK_BEHAVIOR_EVISCERATE && !mob->IsAlive())
            EviscerateOnward(owned, spellInfo, mob, targets);
    }
    SwingRogueBlades();
    if (owned.weapon.behavior == BONK_BEHAVIOR_EVISCERATE)
        ThrowDeadlyFan();
    if (hastensEnvenom)
        ShortenEnvenom();
}

void BonkRun::ShortenEnvenom()
{
    for (OwnedWeapon& owned : m_weapons)
        if (owned.weapon.behavior == BONK_BEHAVIOR_ENVENOM)
            owned.timer = std::max<int32>(0, owned.timer - BONK_MUTILATE_ENVENOM_CUT_MS);
}

void BonkRun::EviscerateOnward(OwnedWeapon& owned, SpellEntry const* spellInfo, Creature* slain, std::vector<Creature*> taken)
{
    Creature* from = slain;
    for (uint32 chain = 0; chain < BONK_EVISCERATE_CHAIN; ++chain)
    {
        Creature* next = nullptr;
        for (Creature* mob : GetMobsInRange(BONK_EVISCERATE_REACH, from))
            if (mob->IsAlive() && std::find(taken.begin(), taken.end(), mob) == taken.end() && m_player->IsWithinLOSInMap(mob))
            {
                next = mob;
                break;
            }
        if (!next)
            return;
        taken.push_back(next);
        StabRogue(owned, spellInfo, next, 1.0f, true);
        if (next->IsAlive())
            return;
        from = next;
    }
}

void BonkRun::StabOffHand(OwnedWeapon& owned, SpellEntry const* spellInfo, Creature* target, std::vector<Creature*> const& taken)
{
    for (Creature* mob : GetMobsInRange(BONK_MAIN_GAUCHE_REACH, target))
    {
        if (mob == target || std::find(taken.begin(), taken.end(), mob) != taken.end() || !m_player->IsWithinLOSInMap(mob))
            continue;
        StabRogue(owned, spellInfo, mob, 1.0f, true);
        return;
    }
}

void BonkRun::SlashOnward(OwnedWeapon& owned, SpellEntry const* spellInfo, Creature* target)
{
    Creature* victim = target;
    for (uint32 chain = 0; chain < BONK_SABER_SLASH_CHAIN && victim && !victim->IsAlive(); ++chain)
    {
        Creature* next = nullptr;
        for (Creature* mob : GetMobsInRange(GetStrikeRange(owned)))
            if (mob != victim && mob->IsAlive() && m_player->IsWithinLOSInMap(mob))
            {
                next = mob;
                break;
            }
        if (!next)
            return;
        StabRogue(owned, spellInfo, next, 1.0f, true);
        victim = next;
    }
}

void BonkRun::Mutilate(OwnedWeapon& owned, SpellEntry const* spellInfo, Creature* target)
{
    float const share = GetKeywordStacks(target, BONK_KEYWORD_POISON) ? BONK_MUTILATE_POISONED : 1.0f;
    bool const blindside = owned.weapon.id == BONK_WEAPON_BLINDSIDE && target->GetHealthPercent() < BONK_BLINDSIDE_HEALTH;
    uint32 const stabs = blindside ? BONK_BLINDSIDE_STABS : BONK_MUTILATE_STABS;
    for (uint32 stab = 0; stab < stabs && target->IsAlive(); ++stab)
    {
        PoisonWithRogue(owned, target, owned.weapon.applyStacks + GetKeywordStacks(target, BONK_KEYWORD_POISON) / BONK_MUTILATE_STACKS_PER);
        if (owned.weapon.id == BONK_WEAPON_TOXIC_BLADE)
            ApplyWeaponKeyword(owned, target, BONK_KEYWORD_NATURE_VULNERABILITY, BONK_TOXIC_BLADE_STACKS);
        StabRogue(owned, spellInfo, target, share, true);
    }
}

bool BonkRun::OpenRogueWindow(OwnedWeapon& owned, uint32& untilMs, uint32 auraSpellId)
{
    if (!IsRogueNear())
    {
        owned.timer = BONK_ROGUE_RETRY_MS;
        return false;
    }
    owned.timer = GetWeaponCooldown(owned);
    int32 const lengthMs = int32(GetWindowLengthMs(owned));
    untilMs = m_totalMs + uint32(lengthMs);
    if (auraSpellId)
    {
        m_player->AddAura(auraSpellId);
        SetAuraLength(m_player, auraSpellId, lengthMs);
    }
    else if (SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_SHADOW_DANCE_LOOK))
        ShowStrike(m_player, look, m_player);
    return true;
}

void BonkRun::StartShadowDance(OwnedWeapon& owned)
{
    uint32 shadowDanceUntilMs = 0;
    if (!OpenRogueWindow(owned, shadowDanceUntilMs, BONK_SPELL_SHADOW_DANCE_AURA))
        return;
    if (m_mastery.Special(BONK_SPECIAL_SECRET_TECHNIQUE) > 0.0f)
        for (Creature* mob : GetMobsInRange(BONK_SECRET_TECHNIQUE_RADIUS))
            OpenOnRogueTarget(mob, true);
    if (owned.weapon.id == BONK_WEAPON_VANISH)
    {
        SpellEntry const* sap = sSpellMgr.GetSpellEntry(BONK_SPELL_SAP);
        for (Creature* mob : GetMobsInRange(GetWeaponRadius(owned)))
        {
            int32 durationMs = BONK_VANISH_MS;
            if (IsRogueNormalMob(mob) && LimitStun(mob, durationMs))
                HoldMob(mob, sap, SPELL_AURA_MOD_STUN, durationMs);
        }
        return;
    }
    if (owned.weapon.id != BONK_WEAPON_SYMBOLS_OF_DEATH)
        return;
    SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_SHADOW_STRIKE);
    if (!look)
        return;
    std::vector<Creature*> mobs = GetMobsInRange(GetWeaponRadius(owned));
    SortStrongestFirst(mobs);
    float const damage = GetWeaponDamage(owned);
    size_t struck = 0;
    for (Creature* mob : mobs)
    {
        if (struck >= BONK_SYMBOLS_TARGETS)
            break;
        if (!m_player->IsWithinLOSInMap(mob))
            continue;
        ShowStrike(m_player, look, mob);
        DealShamanHit(look, owned.weapon.spellId, mob, damage);
        OnRogueHit(mob, damage, false);
        ++struck;
    }
}

void BonkRun::StartKillingSpree(OwnedWeapon& owned)
{
    if (GetMobsInRange(GetWeaponRadius(owned)).empty())
    {
        owned.timer = BONK_ROGUE_RETRY_MS;
        return;
    }
    owned.timer = GetWeaponCooldown(owned);
    m_spreeBonus = 0;
    uint32 const strikes = uint32(std::max(0.0f, owned.weapon.behaviorValue)) + BONK_SPREE_STRIKES_PER_COUNT * GetSpellCount(owned);
    for (uint32 strike = 0; strike < strikes; ++strike)
        QueueSpreeStrike(owned, int32(strike) * BONK_SPREE_GAP_MS, strike + 1 == strikes);
}

void BonkRun::QueueSpreeStrike(OwnedWeapon const& owned, int32 delayMs, bool last)
{
    PendingCast blade;
    blade.weaponId = owned.weapon.id;
    blade.spellId = owned.weapon.spellId;
    blade.leftMs = delayMs;
    blade.killingSpree = true;
    blade.hops = last ? 1 : 0;
    m_pendingCasts.push_back(blade);
}

void BonkRun::StrikeSpree(OwnedWeapon& owned, SpellEntry const* spellInfo, bool last)
{
    std::vector<Creature*> mobs;
    for (Creature* mob : GetMobsInRange(GetWeaponRadius(owned)))
        if (m_player->IsWithinLOSInMap(mob))
            mobs.push_back(mob);
    if (!mobs.empty())
    {
        Creature* target = mobs[urand(0, uint32(mobs.size() - 1))];
        SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_SINISTER_STRIKE);
        float x, y, z;
        target->GetPosition(x, y, z);
        m_spreeStriking = true;
        StabRogue(owned, look ? look : spellInfo, target, 1.0f, true);
        m_spreeStriking = false;
        ReduceTimer(BONK_WEAPON_EVISCERATE, BONK_SPREE_EVISCERATE_MS);
        PlayKitAt(ObjectGuid(), x, y, z, BONK_KIT_SPREE_SLASH, false);
        SwingRogueBlades();
        if (owned.weapon.id == BONK_WEAPON_MURDEROUS_INTENT && !target->IsAlive() && m_spreeBonus < BONK_MURDEROUS_CAP)
            for (uint32 extra = 1; extra <= BONK_MURDEROUS_STRIKES; ++extra)
            {
                ++m_spreeBonus;
                QueueSpreeStrike(owned, int32(extra) * BONK_SPREE_GAP_MS, false);
            }
    }
    if (last && owned.weapon.id == BONK_WEAPON_GRAND_FINALE)
        FireRogueFinishers();
}

void BonkRun::FireRogueFinishers()
{
    for (OwnedWeapon& other : m_weapons)
    {
        if (other.weapon.behavior != BONK_BEHAVIOR_EVISCERATE && other.weapon.behavior != BONK_BEHAVIOR_ENVENOM)
            continue;
        SpellEntry const* info = sSpellMgr.GetSpellEntry(other.weapon.spellId);
        if (!info)
            continue;
        int32 const timer = other.timer;
        FireRogueSpell(other, info);
        other.timer = timer;
    }
}

void BonkRun::ThrowFanOfKnives(OwnedWeapon& owned, SpellEntry const* spellInfo, bool fresh)
{
    std::vector<Creature*> mobs;
    for (Creature* mob : GetMobsInRange(GetWeaponRadius(owned)))
        if (m_player->IsWithinLOSInMap(mob))
            mobs.push_back(mob);

    if (fresh)
    {
        if (mobs.empty())
        {
            owned.timer = BONK_ROGUE_RETRY_MS;
            return;
        }
        owned.timer = GetWeaponCooldown(owned);
        uint32 const echoes = std::min(GetSpellCount(owned), BONK_MAX_COUNT_PULSES);
        for (uint32 echo = 1; echo <= echoes; ++echo)
        {
            PendingCast again;
            again.weaponId = owned.weapon.id;
            again.spellId = owned.weapon.spellId;
            again.leftMs = int32(echo) * BONK_FAN_ECHO_MS;
            again.fanOfKnives = true;
            m_pendingCasts.push_back(again);
        }
        if (owned.weapon.id == BONK_WEAPON_CALTROPS)
            StartKeywordCloud(owned, m_player->GetPositionX(), m_player->GetPositionY(), m_player->GetPositionZ());
    }

    ShowMissilesAround(spellInfo, GetWeaponRadius(owned), BONK_FAN_KNIVES);
    float const damage = GetWeaponDamage(owned);
    for (Creature* mob : mobs)
    {
        if (!mob->IsAlive())
            continue;
        DealShamanHit(spellInfo, owned.weapon.spellId, mob, damage);
        PoisonWithRogue(owned, mob, owned.weapon.applyStacks);
        OnRogueHit(mob, damage, false);
    }
}

void BonkRun::ThrowDeadlyFan()
{
    OwnedWeapon* fan = FindOwned(BONK_WEAPON_DEADLY_FAN);
    if (!fan)
        return;
    if (SpellEntry const* info = sSpellMgr.GetSpellEntry(fan->weapon.spellId))
        ThrowFanOfKnives(*fan, info, false);
}

bool BonkRun::GetRogueCloudKind(OwnedWeapon const& owned, KeywordCloudKind& kind) const
{
    if (owned.weapon.id == BONK_WEAPON_CALTROPS)
    {
        kind.lifeMs = BONK_CALTROPS_MS;
        kind.pulseEveryMs = BONK_CALTROPS_PULSE_MS;
        kind.stacks = 1;
        kind.maxAlive = BONK_CALTROPS_ALIVE;
        kind.lookSpellId = BONK_SPELL_CALTROPS_LOOK;
        kind.burstKit = BONK_KIT_CALTROPS_SOUND;
        return true;
    }
    if (owned.weapon.id == BONK_WEAPON_SMOKE_BOMB)
    {
        kind.lifeMs = BONK_SMOKE_BOMB_MS;
        kind.pulseEveryMs = int32(BONK_SMOKE_BOMB_MS);
        kind.stacks = 0;
        kind.maxAlive = 1;
        kind.lookSpellId = BONK_SPELL_SMOKE_BOMB_LOOK;
        kind.burstKit = BONK_KIT_SMOKE_BOMB_SOUND;
        return true;
    }
    return false;
}

void BonkRun::OnRogueCloudPulse(OwnedWeapon const& owned, KeywordCloud const& cloud)
{
    if (owned.weapon.id != BONK_WEAPON_CALTROPS)
        return;
    SpellEntry const* crippling = sSpellMgr.GetSpellEntry(BONK_SPELL_CRIPPLING_POISON);
    if (!crippling)
        return;
    for (Creature* mob : GetMobsNear(cloud.x, cloud.y, cloud.radius))
        SlowNormalMob(mob, crippling, &BONK_CRIPPLING_SLOW, BONK_CALTROPS_SLOW_MS);
}

void BonkRun::SortMostPoisonFirst(std::vector<Creature*>& mobs) const
{
    std::stable_sort(mobs.begin(), mobs.end(), [this](Creature const* a, Creature const* b)
    {
        return GetKeywordStacks(a, BONK_KEYWORD_POISON) > GetKeywordStacks(b, BONK_KEYWORD_POISON);
    });
}

void BonkRun::CastEnvenom(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    std::vector<Creature*> mobs;
    for (Creature* mob : GetMobsInRange(GetStrikeRange(owned)))
        if (m_player->IsWithinLOSInMap(mob))
            mobs.push_back(mob);
    if (mobs.empty())
    {
        owned.timer = BONK_ROGUE_RETRY_MS;
        return;
    }
    owned.timer = GetWeaponCooldown(owned);
    SortMostPoisonFirst(mobs);
    uint32 const wanted = GetWeaponTargets(owned);
    for (size_t i = 0; i < mobs.size() && i < wanted; ++i)
    {
        Creature* target = mobs[i];
        float const venom = GetDotDamageLeft(target, BONK_KEYWORD_POISON);
        StabRogue(owned, spellInfo, target, 1.0f, true);
        if (venom > 0.0f && target->IsAlive())
            DealShamanHit(spellInfo, owned.weapon.spellId, target, venom);
        if (m_mastery.Special(BONK_SPECIAL_DEATHMARK) > 0.0f && target->IsAlive())
            StabRogue(owned, spellInfo, target, 1.0f, true);
        if (owned.weapon.id == BONK_WEAPON_VENOM_SPLASH)
            SplashVenom(owned, spellInfo, target);
        else if (owned.weapon.id == BONK_WEAPON_EXSANGUINATE)
            Exsanguinate(owned, spellInfo, target);
    }
    int32 const envenomDuration = int32(owned.weapon.durationMs * GetWeaponDurationScale(owned));
    if (SpellAuraHolder* holder = m_player->AddAura(BONK_SPELL_ENVENOM_AURA, ADD_AURA_POSITIVE))
    {
        int32 const duration = envenomDuration;
        holder->SetAuraDuration(duration);
        holder->SetAuraMaxDuration(duration);
        holder->UpdateAuraDuration();
    }
    ThrowDeadlyFan();
}

void BonkRun::ThrowPoisonBomb(OwnedWeapon& owned)
{
    float x, y, z;
    if (!FindLargestGroup(BONK_POISON_BOMB_REACH * GetWeaponArea(owned), x, y, z))
    {
        owned.timer = BONK_ROGUE_RETRY_MS;
        return;
    }
    owned.timer = GetWeaponCooldown(owned);
    if (SpellEntry const* vial = sSpellMgr.GetSpellEntry(BONK_SPELL_POISON_VIAL))
        ShowMissileFrom(m_player, vial, x, y, z);
    m_player->SendPlaySpellVisualKit(BONK_KIT_THROW);
    PendingCast bomb;
    bomb.weaponId = owned.weapon.id;
    bomb.spellId = owned.weapon.spellId;
    bomb.leftMs = int32(m_player->GetDistance(x, y, z) / BONK_POISON_BOMB_SPEED * IN_MILLISECONDS);
    bomb.poisonBomb = true;
    bomb.x = x;
    bomb.y = y;
    bomb.z = z;
    m_pendingCasts.push_back(bomb);
}

void BonkRun::LandPoisonBomb(OwnedWeapon& owned, PendingCast const& cast)
{
    ShowKitAt(BONK_KIT_POISON_BOMB, cast.x, cast.y, cast.z);
    SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_POISON_VIAL);
    float const damage = GetWeaponDamage(owned);
    for (Creature* mob : GetMobsNear(cast.x, cast.y, GetWeaponRadius(owned)))
    {
        if (!mob->IsAlive())
            continue;
        PoisonWithRogue(owned, mob, BONK_POISON_BOMB_STACKS);
        if (look)
            DealShamanHit(look, owned.weapon.spellId, mob, damage);
    }
}

void BonkRun::SplashVenom(OwnedWeapon& owned, SpellEntry const* spellInfo, Creature* target)
{
    float const damage = GetWeaponDamage(owned);
    for (Creature* mob : GetMobsInRange(GetWeaponRadius(owned), target))
    {
        if (mob == target || !GetKeywordStacks(mob, BONK_KEYWORD_POISON))
            continue;
        ShowStrike(m_player, spellInfo, mob);
        DealShamanHit(spellInfo, owned.weapon.spellId, mob, damage);
        OnRogueHit(mob, damage, false);
    }
}

void BonkRun::Exsanguinate(OwnedWeapon& owned, SpellEntry const* spellInfo, Creature* target)
{
    BonkKeywordInfo const* poison = sBonkMgr.GetKeyword(BONK_KEYWORD_POISON);
    if (!poison || !poison->tickMs)
        return;
    float const perStack = GetDotTickDamage(*poison) * BONK_EXSANGUINATE_SECONDS * IN_MILLISECONDS / poison->tickMs;
    std::vector<Creature*> mobs = GetMobsInRange(GetWeaponRadius(owned), target);
    mobs.push_back(target);
    for (Creature* mob : mobs)
        if (uint32 const stacks = GetKeywordStacks(mob, BONK_KEYWORD_POISON))
            DealShamanHit(spellInfo, owned.weapon.spellId, mob, perStack * stacks);
}

void BonkRun::TossShurikens(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    std::vector<Creature*> mobs;
    for (Creature* mob : GetMobsInRange(GetStrikeRange(owned)))
        if (m_player->IsWithinLOSInMap(mob))
            mobs.push_back(mob);
    if (mobs.empty())
    {
        owned.timer = BONK_ROGUE_RETRY_MS;
        return;
    }
    owned.timer = GetWeaponCooldown(owned);
    uint32 const now = WorldTimer::getMSTime();
    if (WorldTimer::getMSTimeDiff(m_castAnimationMs, now) >= BONK_THROW_ANIMATION_GAP_MS)
    {
        m_castAnimationMs = now;
        m_player->SendPlaySpellVisualKit(BONK_KIT_THROW);
    }
    if (SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_SHURIKEN_LOOK))
        spellInfo = look;
    std::stable_partition(mobs.begin(), mobs.end(), [this](Creature const* mob)
    {
        return !m_rogueTouched.count(mob->GetObjectGuid());
    });
    uint32 const wanted = GetWeaponTargets(owned);
    std::vector<Creature*> struck;
    for (size_t i = 0; i < mobs.size() && i < wanted; ++i)
    {
        Creature* target = mobs[i];
        float const x = target->GetPositionX(), y = target->GetPositionY(), z = target->GetPositionZ();
        struck.push_back(target);
        if (owned.weapon.id == BONK_WEAPON_SHURIKEN_STORM)
            BounceShuriken(owned, spellInfo, target, struck);
        StabRogue(owned, spellInfo, target, 1.0f, true);
        QueueShurikenImpact(m_player, target);
        if (owned.weapon.id == BONK_WEAPON_SHADOWY_SHURIKEN)
            QueueShadowyShuriken(owned, x, y, z);
    }
}

void BonkRun::BounceShuriken(OwnedWeapon& owned, SpellEntry const* spellInfo, Creature* from, std::vector<Creature*>& struck)
{
    float const damage = GetWeaponDamage(owned);
    std::vector<Creature*> chain;
    for (uint32 jump = 0; jump < BONK_SHURIKEN_STORM_JUMPS; ++jump)
    {
        std::vector<Creature*> nearby = GetMobsInRange(BONK_SHURIKEN_STORM_REACH, from);
        std::stable_partition(nearby.begin(), nearby.end(), [this](Creature const* mob)
        {
            return !m_rogueTouched.count(mob->GetObjectGuid());
        });
        Creature* next = nullptr;
        for (Creature* mob : nearby)
            if (mob != from && mob->IsAlive() && std::find(struck.begin(), struck.end(), mob) == struck.end())
            {
                next = mob;
                break;
            }
        if (!next)
            break;
        ShowStrike(from, spellInfo, next);
        QueueShurikenImpact(from, next);
        struck.push_back(next);
        chain.push_back(next);
        from = next;
    }
    for (Creature* mob : chain)
    {
        DealRogueDamage(owned.weapon.spellId, spellInfo, mob, damage);
        OnRogueHit(mob, damage, false);
    }
}

void BonkRun::QueueShurikenImpact(Unit const* from, Creature* target)
{
    PendingCast impact;
    impact.kit = BONK_KIT_SHURIKEN_IMPACT;
    impact.target = target->GetObjectGuid();
    impact.x = target->GetPositionX();
    impact.y = target->GetPositionY();
    impact.z = target->GetPositionZ();
    impact.leftMs = int32(from->GetDistance(target) / BONK_SHURIKEN_SPEED * IN_MILLISECONDS);
    m_pendingCasts.push_back(impact);
}

void BonkRun::QueueShadowyShuriken(OwnedWeapon const& owned, float x, float y, float z)
{
    PendingCast shadow;
    shadow.weaponId = owned.weapon.id;
    shadow.spellId = owned.weapon.spellId;
    shadow.leftMs = BONK_SHADOWY_SHURIKEN_MS;
    shadow.shadowyShuriken = true;
    shadow.x = x;
    shadow.y = y;
    shadow.z = z;
    m_pendingCasts.push_back(shadow);
}

void BonkRun::BurstShadowyShuriken(OwnedWeapon& owned, PendingCast const& cast)
{
    SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_SHADOW_STRIKE);
    if (!look)
        return;
    float const damage = GetWeaponDamage(owned);
    for (Creature* mob : GetMobsNear(cast.x, cast.y, GetWeaponRadius(owned)))
    {
        ShowStrike(m_player, look, mob);
        DealShamanHit(look, owned.weapon.spellId, mob, damage);
    }
}

void BonkRun::Evade(OwnedWeapon& owned)
{
    if (!IsRogueNear() || !m_player->IsAlive())
    {
        owned.timer = BONK_ROGUE_RETRY_MS;
        return;
    }
    owned.timer = GetWeaponCooldown(owned);
    if (owned.weapon.id == BONK_WEAPON_SMOKE_BOMB)
    {
        m_smokeX = m_player->GetPositionX();
        m_smokeY = m_player->GetPositionY();
        m_smokeRadius = GetWeaponRadius(owned);
        m_smokeUntilMs = m_totalMs + uint32(BONK_SMOKE_BOMB_MS * GetWeaponDurationScale(owned));
        StartKeywordCloud(owned, m_smokeX, m_smokeY, m_player->GetPositionZ());
    }
    int32 const room = int32(BONK_EVASION_MAX_DODGE - GetStat(BONK_PASSIVE_DODGE));
    int32 const dodge = std::min(BONK_EVASION_DODGE, room);
    if (dodge <= 0)
        return;
    m_player->RemoveAurasDueToSpell(BONK_SPELL_EVASION);
    m_player->CastCustomSpell(m_player, BONK_SPELL_EVASION, dodge, {}, {}, true);
    SetAuraLength(m_player, BONK_SPELL_EVASION, int32(GetWindowLengthMs(owned)));
}

bool BonkRun::IsHiddenInSmoke() const
{
    return m_smokeUntilMs > m_totalMs && m_player->GetDistance2d(m_smokeX, m_smokeY) <= m_smokeRadius && roll_chance_f(BONK_SMOKE_BOMB_MISS);
}

void BonkRun::OnRogueDodge(Unit* attacker)
{
    Creature* mob = attacker ? attacker->ToCreature() : nullptr;
    if (mob && mob->IsAlive() && m_mastery.Special(BONK_SPECIAL_MASTER_OF_SHADOWS) > 0.0f)
        OpenOnRogueTarget(mob, true);
    OwnedWeapon* riposte = FindOwned(BONK_WEAPON_RIPOSTE);
    if (!riposte || !mob || !mob->IsAlive() || !TakeRateSlot(m_riposteTimes, BONK_RIPOSTE_PER_SEC))
        return;
    SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_RIPOSTE);
    if (!look)
        return;
    float const damage = GetWeaponDamage(*riposte);
    ShowStrike(m_player, look, mob);
    DealShamanHit(look, riposte->weapon.spellId, mob, damage);
    OnRogueHit(mob, damage, false);
}

float BonkRun::GetRogueDamageMultiplier(Unit const* victim) const
{
    float multiplier = m_player->HasAura(BONK_SPELL_SHADOW_DANCE_AURA) ? BONK_SHADOW_DANCE_BONUS : 1.0f;
    if (!victim)
        return multiplier;
    auto weak = m_findWeakness.find(victim->GetObjectGuid());
    if (weak != m_findWeakness.end() && weak->second > m_totalMs)
        multiplier *= BONK_FIND_WEAKNESS_BONUS;
    OwnedWeapon const* deadly = FindOwnedByBehavior(BONK_BEHAVIOR_DEADLY_POISON);
    if (deadly && deadly->weapon.id == BONK_WEAPON_CRIPPLING_POISON && GetKeywordStacks(victim, BONK_KEYWORD_POISON))
        multiplier *= BONK_CRIPPLING_BONUS;
    float const vendetta = m_mastery.Special(BONK_SPECIAL_VENDETTA);
    if (vendetta > 0.0f)
        multiplier *= 1.0f + std::min(BONK_VENDETTA_CAP, vendetta * float(GetKeywordStacks(victim, BONK_KEYWORD_POISON))) / 100.0f;
    return multiplier;
}

float BonkRun::GetRogueCritChance(SpellEntry const* spell, float chance) const
{
    if (m_spreeStriking && m_mastery.Special(BONK_SPECIAL_SPREE_CRIT) > 0.0f)
        return std::max(100.0f, chance);
    if (spell && (spell->Id == BONK_SPELL_EVISCERATE || spell->Id == BONK_SPELL_AMBUSH))
        return chance * BONK_ROGUE_CRIT_SCALE;
    return chance;
}

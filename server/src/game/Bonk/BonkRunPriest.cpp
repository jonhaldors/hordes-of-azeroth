#include "BonkRun.h"
#include "BonkMobAI.h"
#include "BonkPlayer.h"
#include "Creature.h"
#include "Map.h"
#include "Player.h"
#include "SpellAuras.h"
#include "SpellMgr.h"

#include <algorithm>

namespace
{
    uint32 const BONK_WEAPON_SHADOWFIEND      = 511;

    uint32 const BONK_WEAPON_SEARING_LIGHT    = 513;
    uint32 const BONK_WEAPON_ECHO_OF_LIGHT    = 514;
    uint32 const BONK_WEAPON_PRAYER_OF_MENDING = 515;
    uint32 const BONK_WEAPON_DIVINE_HYMN      = 516;
    uint32 const BONK_WEAPON_LIGHTS_EDGE      = 517;
    uint32 const BONK_WEAPON_SANCTIFY         = 518;
    uint32 const BONK_WEAPON_APOTHEOSIS       = 519;
    uint32 const BONK_WEAPON_REFLECTIVE_SHIELD = 520;
    uint32 const BONK_WEAPON_BARRIER          = 521;
    uint32 const BONK_WEAPON_RAPTURE          = 522;
    uint32 const BONK_WEAPON_CONTRITION       = 523;
    uint32 const BONK_WEAPON_PSYCHIC_HORROR   = 524;
    uint32 const BONK_WEAPON_SHADOW_TERROR    = 525;
    uint32 const BONK_WEAPON_CHAINS_OF_LIGHT  = 526;
    uint32 const BONK_WEAPON_MASS_SHACKLE     = 527;
    uint32 const BONK_WEAPON_VAMPIRIC_TOUCH   = 528;
    uint32 const BONK_WEAPON_MISERY           = 529;
    uint32 const BONK_WEAPON_MIND_SEAR        = 530;
    uint32 const BONK_WEAPON_INSANITY         = 531;
    uint32 const BONK_WEAPON_MIND_SPIKE       = 532;
    uint32 const BONK_WEAPON_VOID_ERUPTION    = 533;
    uint32 const BONK_WEAPON_MINDBENDER       = 534;
    uint32 const BONK_WEAPON_VOID_TENDRILS    = 535;

    uint32 const BONK_SPELL_SMITE             = 585;
    uint32 const BONK_SPELL_RENEW             = 139;
    uint32 const BONK_SPELL_RENEW_LOOK        = 33464;
    uint32 const BONK_SPELL_POWER_WORD_SHIELD = 17;
    uint32 const BONK_SPELL_PENANCE_BOLT      = 591;
    uint32 const BONK_SPELL_RAPTURE_BOLT      = 598;
    uint32 const BONK_KIT_PENANCE_CAST        = 119;
    uint32 const BONK_SPELL_HOLY_NOVA         = 15237;
    uint32 const BONK_SPELL_HOLY_STUN         = 7922;
    uint32 const BONK_SPELL_SHADOW_HIT        = 8092;
    uint32 const BONK_SPELL_DECAY_CARRIER     = 594;
    uint32 const BONK_SPELL_SHACKLE           = 9484;
    uint32 const BONK_SPELL_VOID_TENDRILS     = 23414;
    uint32 const BONK_SPELL_BARRIER_LOOK      = 26573;

    float const BONK_RENEW_SMITE_RANGE        = 30.0f;
    float const BONK_HALO_INNER               = 0.0f;
    float const BONK_HALO_HEAL_PER_HIT        = 0.5f;
    float const BONK_HALO_HEAL_CAP            = 2.0f;
    int32 const BONK_HALO_ECHO_MS             = 300;
    uint32 const BONK_HOLY_WORD_STEP_MS       = 1000;
    float const BONK_BODY_AND_SOUL_SPEED      = 10.0f;
    uint32 const BONK_PENANCE_BOLTS           = 3;
    uint32 const BONK_PENANCE_MEMORY_MS       = 5000;
    size_t const BONK_PENANCE_ATTACKERS       = 8;
    float const BONK_PENANCE_HEAL             = 0.5f;
    float const BONK_PENANCE_BOLT_SPEED       = 30.0f;
    int32 const BONK_PENANCE_BOLT_GAP_MS      = 250;
    float const BONK_ATONEMENT_CAP            = 6.0f;
    int32 const BONK_FEAR_MS                  = 2000;
    int32 const BONK_SHACKLE_MS               = 2000;
    uint32 const BONK_SHACKLE_IMMUNE_MS       = 6000;
    uint32 const BONK_HOLD_TICK_MS            = 1000;
    float const BONK_FEAR_TICK_SHARE          = 1.0f;
    float const BONK_SHACKLE_TICK_SHARE       = 0.5f;
    int32 const BONK_MIND_FLAY_SLOW           = -30;
    int32 const BONK_MIND_FLAY_SLOW_MS        = 1000;
    uint32 const BONK_MIND_FLAY_HEAL_DECAY    = 10;
    float const BONK_MIND_FLAY_HEAL           = 0.2f;
    uint32 const BONK_MIND_BLAST_MAX_COPY     = 10;
    int32 const BONK_SURGE_OF_DARKNESS_MS     = 600000;

    uint32 const BONK_SEARING_LIGHT_EVERY     = 4;
    int32 const BONK_SEARING_LIGHT_STUN_MS    = 1000;
    size_t const BONK_ECHO_OF_LIGHT_PER_SEC   = 2;
    uint32 const BONK_PRAYER_OF_MENDING_JUMPS = 2;
    float const BONK_PRAYER_OF_MENDING_REACH  = 10.0f;
    int32 const BONK_DIVINE_HYMN_GAP_MS       = 1000;
    uint32 const BONK_DIVINE_HYMN_RINGS       = 3;
    float const BONK_LIGHTS_EDGE_BONUS        = 1.0f;
    float const BONK_SANCTIFY_SHARE           = 0.5f;
    float const BONK_SANCTIFY_HEAL            = 3.0f;
    uint32 const BONK_BARRIER_MS              = 5000;
    float const BONK_BARRIER_TAKEN            = 0.75f;
    uint32 const BONK_RAPTURE_BOLTS           = 2;
    float const BONK_CONTRITION_SHARE         = 0.5f;
    float const BONK_PSYCHIC_HORROR_BONUS     = 1.2f;
    uint32 const BONK_SHADOW_TERROR_STACKS    = 3;
    float const BONK_CHAINS_OF_LIGHT_BONUS    = 1.3f;
    uint32 const BONK_MASS_SHACKLE_CHAINS     = 3;
    float const BONK_VAMPIRIC_TOUCH_SHARE     = 0.02f;
    float const BONK_VAMPIRIC_TOUCH_CAP       = 1.0f;
    float const BONK_MIND_SEAR_SHARE          = 0.5f;
    float const BONK_VOID_ERUPTION_SHARE      = 0.5f;
    float const BONK_MINDBENDER_SHARE         = 0.5f;
    uint32 const BONK_VOID_TENDRILS_EVERY_MS  = 6000;
    int32 const BONK_VOID_TENDRILS_MS         = 2000;
    uint32 const BONK_PRIEST_TICK_MS          = 1000;
    float const BONK_ARCHANGEL_SMITE_HEALTH   = 0.8f;
    uint32 const BONK_ARCHANGEL_WORD_SCALE    = 2;
    float const BONK_PAIN_SUPPRESSION_TAKEN   = 0.8f;

    BonkMobAI const* GetPriestAI(Unit const* unit)
    {
        Creature const* creature = unit ? unit->ToCreature() : nullptr;
        return creature ? dynamic_cast<BonkMobAI const*>(creature->AI()) : nullptr;
    }

    bool IsNormalMob(Creature const* mob)
    {
        BonkMobAI const* ai = GetPriestAI(mob);
        return ai && ai->GetKind() == BONK_SPAWN_NORMAL;
    }

    bool CanBeBound(Creature const* mob)
    {
        BonkMobAI const* ai = GetPriestAI(mob);
        return ai && (ai->GetKind() == BONK_SPAWN_NORMAL || ai->GetKind() == BONK_SPAWN_ELITE);
    }
}

void BonkRun::ResetPriestState()
{
    m_recentAttackers.clear();
    m_mindFlayTarget.Clear();
    m_priestHolds.clear();
    m_bodyAndSoul = false;
    m_flayCarried = 0;
    m_searingLightCast = 0;
    m_echoOfLightTimes.clear();
    m_vampiricHeal = 0.0f;
    m_reflectStored = 0;
    m_barrierUntilMs = 0;
    m_priestTickMs = 0;
    m_voidTendrilsMs = 0;
    if (m_player->HasAura(BONK_SPELL_POWER_WORD_SHIELD))
        m_player->RemoveAurasDueToSpell(BONK_SPELL_POWER_WORD_SHIELD);
    if (m_player->HasAura(BONK_SPELL_RENEW_LOOK))
        m_player->RemoveAurasDueToSpell(BONK_SPELL_RENEW_LOOK);
}

void BonkRun::UpdatePriest(uint32 diff)
{
    if (m_player->GetClass() != CLASS_PRIEST)
        return;
    m_priestTickMs += diff;
    if (m_priestTickMs >= BONK_PRIEST_TICK_MS)
    {
        m_priestTickMs = 0;
        DrainVampiricTouch();
    }
    m_voidTendrilsMs += diff;
    if (m_voidTendrilsMs >= BONK_VOID_TENDRILS_EVERY_MS)
    {
        m_voidTendrilsMs = 0;
        GraspWithVoidTendrils();
    }
    TickPriestHolds();
    UpdateBodyAndSoul();
}

void BonkRun::TrackPriestHold(OwnedWeapon const& owned, Creature* mob, uint32 spellId, int32 durationMs, float share)
{
    ObjectGuid const guid = mob->GetObjectGuid();
    m_priestHolds.erase(std::remove_if(m_priestHolds.begin(), m_priestHolds.end(), [&guid, spellId](PriestHold const& hold)
    {
        return hold.mob == guid && hold.spellId == spellId;
    }), m_priestHolds.end());
    PriestHold hold;
    hold.mob = guid;
    hold.weaponId = owned.weapon.id;
    hold.spellId = spellId;
    hold.untilMs = m_totalMs + uint32(std::max(0, durationMs));
    hold.nextTickMs = m_totalMs + BONK_HOLD_TICK_MS;
    hold.share = share;
    m_priestHolds.push_back(hold);
}

void BonkRun::TickPriestHolds()
{
    if (m_priestHolds.empty())
        return;
    Map* map = m_player->GetMap();
    for (auto itr = m_priestHolds.begin(); itr != m_priestHolds.end();)
    {
        Creature* mob = map->GetCreature(itr->mob);
        bool const held = mob && mob->IsAlive() && (itr->spellId == BONK_SPELL_SHACKLE ? mob->HasAura(BONK_SPELL_SHACKLE) :
            mob->HasUnitState(UNIT_STATE_FLEEING));
        if (!held || itr->nextTickMs > itr->untilMs)
        {
            itr = m_priestHolds.erase(itr);
            continue;
        }
        if (m_totalMs >= itr->nextTickMs)
        {
            itr->nextTickMs += BONK_HOLD_TICK_MS;
            OwnedWeapon const* owned = FindOwned(itr->weaponId);
            SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(itr->spellId);
            if (owned && spellInfo)
                DealShamanHit(spellInfo, owned->weapon.spellId, mob, GetWeaponDamage(*owned) * itr->share);
        }
        ++itr;
    }
}

bool BonkRun::LimitShackle(Creature* mob, int32 durationMs)
{
    uint32 const now = WorldTimer::getMSTime();
    CrowdControl& control = m_crowdControl[mob->GetObjectGuid()];
    if (int32(control.stunImmuneUntil - now) > 0)
        return false;
    control.stunImmuneUntil = now + uint32(std::max(0, durationMs)) + BONK_SHACKLE_IMMUNE_MS;
    return true;
}

void BonkRun::UpdateBodyAndSoul()
{
    bool const shielded = m_player->IsAlive() && m_spellShield > 0 && FindOwnedByBehavior(BONK_BEHAVIOR_POWER_WORD_SHIELD);
    if (shielded == m_bodyAndSoul)
        return;
    m_bodyAndSoul = shielded;
    if (shielded)
        m_player->AddAura(BONK_SPELL_POWER_WORD_SHIELD, ADD_AURA_PERMANENT);
    else
        m_player->RemoveAurasDueToSpell(BONK_SPELL_POWER_WORD_SHIELD);
    ApplyPassives();
}

float BonkRun::GetPriestMoveSpeed() const
{
    return m_bodyAndSoul ? BONK_BODY_AND_SOUL_SPEED : 0.0f;
}

uint32 BonkRun::GetPriestPetFamily(OwnedWeapon const& owned) const
{
    return GetRootWeapon(owned.weapon) == BONK_WEAPON_SHADOWFIEND ? BONK_PET_FAMILY_SHADOWFIEND : 0;
}

bool BonkRun::ApplyWeaponKeyword(OwnedWeapon const& owned, Creature* mob, BonkKeyword keyword, uint32 stacks)
{
    BonkKeywordInfo const* info = sBonkMgr.GetKeyword(keyword);
    if (!info || !mob || !mob->IsAlive() || !stacks)
        return false;
    uint32 const durationMs = uint32(info->durationMs * GetWeaponDurationScale(owned));
    return ApplyKeyword(mob, keyword, stacks, durationMs, 1.0f + owned.damageBonus / 100.0f, owned.weapon.spellId);
}

bool BonkRun::FirePriestSpell(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    switch (owned.weapon.behavior)
    {
        case BONK_BEHAVIOR_RENEW:             PulseRenew(owned); break;
        case BONK_BEHAVIOR_HALO:              RingHalo(owned, spellInfo, true); break;
        case BONK_BEHAVIOR_POWER_WORD_SHIELD: RaisePowerWordShield(owned); break;
        case BONK_BEHAVIOR_PENANCE:           FirePenance(owned); break;
        case BONK_BEHAVIOR_PSYCHIC_SCREAM:    ScreamPsychic(owned, spellInfo); break;
        case BONK_BEHAVIOR_SHACKLE:           BindShackle(owned, spellInfo); break;
        case BONK_BEHAVIOR_MIND_FLAY:         FlayMind(owned, spellInfo); break;
        case BONK_BEHAVIOR_MIND_BLAST:        BlastMind(owned, spellInfo); break;
        default:                              return false;
    }
    return true;
}

void BonkRun::OnPriestCast(OwnedWeapon const& owned)
{
    if (GetRootWeapon(owned.weapon) == BONK_WEAPON_SMITE)
        ShortenHolyWord(BONK_HOLY_WORD_STEP_MS);
    if (owned.weapon.id != BONK_WEAPON_APOTHEOSIS)
        return;
    for (OwnedWeapon& other : m_weapons)
    {
        uint32 const root = GetRootWeapon(other.weapon);
        if (root == BONK_WEAPON_SMITE || root == BONK_WEAPON_HALO)
            other.timer = 0;
    }
}

void BonkRun::OnPriestStrike(OwnedWeapon& owned, SpellEntry const* spellInfo, Creature* target, float share)
{
    uint32 const id = owned.weapon.id;
    if (id == BONK_WEAPON_MISERY)
        ApplyWeaponKeyword(owned, target, BONK_KEYWORD_SHADOW_VULNERABILITY, 1);

    if (id == BONK_WEAPON_SANCTIFY)
    {
        for (Creature* mob : GetMobsInRange(GetWeaponRadius(owned), target))
            DealShamanHit(spellInfo, owned.weapon.spellId, mob, GetWeaponDamage(owned) * share * BONK_SANCTIFY_SHARE);
        HealPriest(BONK_SANCTIFY_HEAL, owned.weapon.spellId, false);
    }

    if (id != BONK_WEAPON_SEARING_LIGHT || owned.casts % BONK_SEARING_LIGHT_EVERY != 0 || m_searingLightCast == owned.casts)
        return;
    m_searingLightCast = owned.casts;
    SpellEntry const* nova = sSpellMgr.GetSpellEntry(BONK_SPELL_HOLY_NOVA);
    SpellEntry const* stun = sSpellMgr.GetSpellEntry(BONK_SPELL_HOLY_STUN);
    if (nova)
        ShowStrike(m_player, nova, target);
    std::vector<Creature*> struck = GetMobsInRange(GetWeaponRadius(owned), target);
    for (Creature* mob : struck)
        DealShamanHit(spellInfo, owned.weapon.spellId, mob, GetWeaponDamage(owned) * share);
    struck.push_back(target);
    for (Creature* mob : struck)
    {
        int32 durationMs = BONK_SEARING_LIGHT_STUN_MS;
        if (mob->IsAlive() && IsNormalMob(mob) && LimitStun(mob, durationMs))
            HoldMob(mob, stun, SPELL_AURA_MOD_STUN, durationMs);
    }
}

void BonkRun::ShortenHolyWord(uint32 ms)
{
    if (m_mastery.Has(BONK_CAPSTONE_ARCHANGEL))
        ms *= BONK_ARCHANGEL_WORD_SCALE;
    for (OwnedWeapon& owned : m_weapons)
        if (owned.weapon.behavior == BONK_BEHAVIOR_HOLY_WORD)
        {
            owned.timer = std::max<int32>(0, owned.timer - int32(ms));
            owned.pieResync = true;
        }
}

Creature* BonkRun::FindPriestTarget(float range) const
{
    for (Creature* mob : GetMobsInRange(range))
        if (m_player->IsWithinLOSInMap(mob))
            return mob;
    return nullptr;
}

void BonkRun::HealPriest(float percent, uint32 textSpellId, bool atonement)
{
    if (!m_player->IsAlive() || percent <= 0.0f)
        return;
    SupportScope scope(*this, m_supportSource.name.empty() ? SpellSupport(textSpellId) : m_supportSource);
    uint32 const maxHealth = m_player->GetMaxHealth();
    uint32 const amount = ReduceHealing(std::max(1u, uint32(maxHealth * percent / 100.0f)));
    uint32 const missing = maxHealth - std::min(maxHealth, m_player->GetHealth());
    HealHero(amount, textSpellId);
    if (textSpellId == BONK_SPELL_RENEW && amount > missing)
        ShieldFromRenew(amount - missing);
    if (!atonement || amount <= missing)
        return;
    uint32 const cap = uint32(maxHealth * BONK_ATONEMENT_CAP / 100.0f);
    if (m_spellShield < cap)
        AddSpellShield(std::min(amount - missing, cap - m_spellShield));
}

void BonkRun::ShieldFromRenew(uint32 overheal)
{
    OwnedWeapon const* ward = FindOwnedByRoot(BONK_WEAPON_POWER_WORD_SHIELD);
    float const wardPercent = ward ? GetShieldPercent(ward->weapon, ward->damageBonus, GetSpellUpgrade(*ward, BONK_SPELL_UPGRADE_SHIELD_SIZE)) : 0.0f;
    uint32 const cap = uint32(m_player->GetMaxHealth() * std::max(wardPercent, m_mastery.Special(BONK_SPECIAL_RENEW_SHIELD)) / 100.0f);
    if (m_spellShield < cap)
        AddSpellShield(std::min(overheal, cap - m_spellShield));
}

void BonkRun::PulseRenew(OwnedWeapon& owned)
{
    SupportScope scope(*this, WeaponSupport(owned));
    owned.timer = GetWeaponCooldown(owned);
    if (!m_player->IsAlive())
        return;
    if (!m_player->HasAura(BONK_SPELL_RENEW_LOOK))
        m_player->AddAura(BONK_SPELL_RENEW_LOOK, ADD_AURA_PERMANENT);
    uint32 const smiteFrom = m_mastery.Has(BONK_CAPSTONE_ARCHANGEL) ? uint32(m_player->GetMaxHealth() * BONK_ARCHANGEL_SMITE_HEALTH) : m_player->GetMaxHealth();
    uint32 const naaruMs = uint32(m_mastery.Special(BONK_SPECIAL_LIGHT_OF_THE_NAARU) * IN_MILLISECONDS);
    if (m_player->GetHealth() < smiteFrom)
    {
        HealPriest(GetHealPercent(owned.weapon, owned.damageBonus), BONK_SPELL_RENEW, false);
        if (naaruMs && m_mastery.Special(BONK_SPECIAL_BENEDICTION) > 0.0f)
            ShortenHolyWord(naaruMs);
        return;
    }
    SpellEntry const* smite = sSpellMgr.GetSpellEntry(BONK_SPELL_SMITE);
    Creature* target = FindPriestTarget(BONK_RENEW_SMITE_RANGE);
    if (!smite || !target)
        return;
    ShowStrike(m_player, smite, target);
    DealShamanHit(smite, owned.weapon.spellId, target, GetWeaponDamage(owned));
    if (naaruMs)
        ShortenHolyWord(naaruMs);
    if (owned.weapon.id != BONK_WEAPON_PRAYER_OF_MENDING)
        return;
    uint32 jumped = 0;
    Unit* from = target;
    for (Creature* mob : GetMobsInRange(BONK_PRAYER_OF_MENDING_REACH, target))
    {
        if (jumped >= BONK_PRAYER_OF_MENDING_JUMPS)
            break;
        ShowStrike(from, smite, mob);
        DealShamanHit(smite, owned.weapon.spellId, mob, GetWeaponDamage(owned));
        from = mob;
        ++jumped;
    }
}

void BonkRun::OnPriestOverheal()
{
    OwnedWeapon const* echo = FindOwned(BONK_WEAPON_ECHO_OF_LIGHT);
    if (!echo || m_inEchoOfLight || !TakeRateSlot(m_echoOfLightTimes, BONK_ECHO_OF_LIGHT_PER_SEC))
        return;
    SpellEntry const* smite = sSpellMgr.GetSpellEntry(BONK_SPELL_SMITE);
    Creature* target = FindPriestTarget(BONK_RENEW_SMITE_RANGE);
    if (!smite || !target)
        return;
    m_inEchoOfLight = true;
    ShowStrike(m_player, smite, target);
    DealShamanHit(smite, echo->weapon.spellId, target, GetWeaponDamage(*echo));
    m_inEchoOfLight = false;
}

void BonkRun::RingHalo(OwnedWeapon& owned, SpellEntry const* spellInfo, bool fresh)
{
    float const outer = GetWeaponRadius(owned);
    std::vector<Creature*> ring;
    for (Creature* mob : GetMobsInRange(outer))
        if (m_player->GetDistance(mob) >= BONK_HALO_INNER && m_player->IsWithinLOSInMap(mob))
            ring.push_back(mob);

    if (fresh)
    {
        if (ring.empty())
        {
            owned.timer = 250;
            return;
        }
        owned.timer = GetWeaponCooldown(owned);
        ShortenHolyWord(BONK_HOLY_WORD_STEP_MS);
        uint32 const echoes = std::min(GetSpellCount(owned), BONK_MAX_COUNT_PULSES);
        uint32 const rings = owned.weapon.id == BONK_WEAPON_DIVINE_HYMN ? BONK_DIVINE_HYMN_RINGS : 1;
        for (uint32 hymn = 0; hymn < rings; ++hymn)
            for (uint32 i = hymn ? 0 : 1; i <= echoes; ++i)
            {
                PendingCast echo;
                echo.weaponId = owned.weapon.id;
                echo.spellId = owned.weapon.spellId;
                echo.leftMs = int32(hymn) * BONK_DIVINE_HYMN_GAP_MS + int32(i) * BONK_HALO_ECHO_MS;
                echo.halo = true;
                m_pendingCasts.push_back(echo);
            }
    }

    ShowStrike(m_player, spellInfo, m_player);
    float const span = std::max(1.0f, outer - BONK_HALO_INNER);
    for (Creature* mob : ring)
    {
        float edge = 1.0f;
        if (owned.weapon.id == BONK_WEAPON_LIGHTS_EDGE)
            edge += BONK_LIGHTS_EDGE_BONUS * std::min(1.0f, (m_player->GetDistance(mob) - BONK_HALO_INNER) / span);
        DealShamanHit(spellInfo, owned.weapon.spellId, mob, GetWeaponDamage(owned) * edge);
    }
    HealPriest(std::min(BONK_HALO_HEAL_PER_HIT * ring.size(), BONK_HALO_HEAL_CAP), owned.weapon.spellId, false);
}

void BonkRun::ResolvePriestCast(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    if (cast.halo)
        RingHalo(owned, spellInfo, false);
    else if (cast.penanceLaunch)
        LaunchPenanceBolt(owned, spellInfo, cast);
    else if (cast.penanceHit)
        LandPenanceBolt(owned, spellInfo, cast);
}

void BonkRun::RaisePowerWordShield(OwnedWeapon& owned)
{
    SupportScope scope(*this, WeaponSupport(owned));
    owned.timer = GetWeaponCooldown(owned);
    if (!m_player->IsAlive())
        return;
    uint32 const amount = GetShieldGain(owned);
    if (m_spellShield < amount)
        AddSpellShield(amount - m_spellShield);
    UpdateBodyAndSoul();
    if (owned.weapon.id != BONK_WEAPON_BARRIER)
        return;
    m_barrierX = m_player->GetPositionX();
    m_barrierY = m_player->GetPositionY();
    m_barrierRadius = GetWeaponRadius(owned);
    m_barrierUntilMs = m_totalMs + uint32(BONK_BARRIER_MS * GetWeaponDurationScale(owned));
    StartKeywordCloud(owned, m_barrierX, m_barrierY, m_player->GetPositionZ());
}

bool BonkRun::GetPriestCloudKind(OwnedWeapon const& owned, KeywordCloudKind& kind) const
{
    if (owned.weapon.id != BONK_WEAPON_BARRIER)
        return false;
    kind.lifeMs = BONK_BARRIER_MS;
    kind.pulseEveryMs = BONK_BARRIER_MS;
    kind.stacks = 0;
    kind.maxAlive = 1;
    kind.lookSpellId = BONK_SPELL_BARRIER_LOOK;
    return true;
}

uint32 BonkRun::ApplyPriestDamageTaken(uint32 damage) const
{
    if (m_spellShield && m_mastery.Has(BONK_CAPSTONE_PAIN_SUPPRESSION))
        damage = std::max(1u, uint32(damage * BONK_PAIN_SUPPRESSION_TAKEN));
    if (m_barrierUntilMs > m_totalMs && m_player->GetDistance2d(m_barrierX, m_barrierY) <= m_barrierRadius)
        return std::max(1u, uint32(damage * BONK_BARRIER_TAKEN));
    return damage;
}

void BonkRun::OnPriestShieldAbsorbed(uint32 absorbed)
{
    if (absorbed && FindOwned(BONK_WEAPON_REFLECTIVE_SHIELD))
        m_reflectStored += absorbed;
}

void BonkRun::ReflectShieldDamage(Creature* attacker)
{
    OwnedWeapon const* reflect = FindOwned(BONK_WEAPON_REFLECTIVE_SHIELD);
    uint32 const stored = m_reflectStored;
    m_reflectStored = 0;
    SpellEntry const* smite = sSpellMgr.GetSpellEntry(BONK_SPELL_SMITE);
    if (!reflect || !stored || !smite || !attacker->IsAlive())
        return;
    ShowStrike(m_player, smite, attacker);
    DealShamanHit(smite, reflect->weapon.spellId, attacker, float(stored));
}

void BonkRun::OnPriestStruck(Creature* attacker)
{
    if (m_player->GetClass() != CLASS_PRIEST || !attacker || IsPeriodicHit())
        return;
    ObjectGuid const guid = attacker->GetObjectGuid();
    m_recentAttackers.erase(std::remove_if(m_recentAttackers.begin(), m_recentAttackers.end(), [&guid](auto const& entry)
    {
        return entry.first == guid;
    }), m_recentAttackers.end());
    m_recentAttackers.emplace_back(guid, m_totalMs);
    if (m_recentAttackers.size() > BONK_PENANCE_ATTACKERS)
        m_recentAttackers.erase(m_recentAttackers.begin());
    ReflectShieldDamage(attacker);
}

void BonkRun::FirePenance(OwnedWeapon& owned)
{
    float const range = owned.weapon.range;
    Map* map = m_player->GetMap();
    std::vector<Creature*> targets;
    for (auto itr = m_recentAttackers.rbegin(); itr != m_recentAttackers.rend(); ++itr)
    {
        if (m_totalMs - itr->second > BONK_PENANCE_MEMORY_MS)
            continue;
        Creature* mob = map->GetCreature(itr->first);
        if (mob && mob->IsAlive() && m_player->IsWithinDistInMap(mob, range) && m_player->IsWithinLOSInMap(mob))
            targets.push_back(mob);
    }
    uint32 const rapture = owned.weapon.id == BONK_WEAPON_RAPTURE && m_spellShield ? BONK_RAPTURE_BOLTS : 0;
    uint32 const bolts = BONK_PENANCE_BOLTS + rapture + GetSpellCount(owned) + uint32(m_mastery.Special(BONK_SPECIAL_CASTIGATION));
    for (Creature* mob : GetMobsInRange(range))
    {
        if (targets.size() >= bolts)
            break;
        if (std::find(targets.begin(), targets.end(), mob) == targets.end() && m_player->IsWithinLOSInMap(mob))
            targets.push_back(mob);
    }

    SpellEntry const* bolt = sSpellMgr.GetSpellEntry(owned.weapon.id == BONK_WEAPON_RAPTURE ? BONK_SPELL_RAPTURE_BOLT : BONK_SPELL_PENANCE_BOLT);
    if (targets.empty() || !bolt)
    {
        owned.timer = 250;
        return;
    }
    owned.timer = GetWeaponCooldown(owned);
    for (auto itr = m_penanceIncoming.begin(); itr != m_penanceIncoming.end();)
    {
        Creature const* mob = map->GetCreature(itr->first);
        itr = mob && mob->IsAlive() ? std::next(itr) : m_penanceIncoming.erase(itr);
    }
    m_player->SendPlaySpellVisualKit(BONK_KIT_PENANCE_CAST);
    for (uint32 i = 0; i < bolts; ++i)
    {
        PendingCast launch;
        launch.weaponId = owned.weapon.id;
        launch.spellId = bolt->Id;
        launch.leftMs = int32(i) * BONK_PENANCE_BOLT_GAP_MS;
        launch.penanceLaunch = true;
        launch.target = targets[i % targets.size()]->GetObjectGuid();
        if (i == 0)
            LaunchPenanceBolt(owned, bolt, launch);
        else
            m_pendingCasts.push_back(launch);
    }
}

Creature* BonkRun::PickPenanceTarget(OwnedWeapon const& owned, ObjectGuid const& wanted) const
{
    auto survivesBoltsInFlight = [this](Creature* mob)
    {
        auto const incoming = m_penanceIncoming.find(mob->GetObjectGuid());
        return incoming == m_penanceIncoming.end() || incoming->second < float(mob->GetHealth());
    };

    Creature* fallback = nullptr;
    Creature* target = m_player->GetMap()->GetCreature(wanted);
    if (target && target->IsAlive() && m_player->IsWithinDistInMap(target, GetStrikeRange(owned)))
    {
        if (survivesBoltsInFlight(target))
            return target;
        fallback = target;
    }
    for (Creature* mob : GetMobsInRange(GetStrikeRange(owned)))
    {
        if (!m_player->IsWithinLOSInMap(mob))
            continue;
        if (survivesBoltsInFlight(mob))
            return mob;
        if (!fallback)
            fallback = mob;
    }
    return fallback;
}

void BonkRun::LaunchPenanceBolt(OwnedWeapon& owned, SpellEntry const* bolt, PendingCast const& cast)
{
    Creature* target = PickPenanceTarget(owned, cast.target);
    if (!target)
        return;

    ShowStrike(m_player, bolt, target);
    PendingCast hit = cast;
    hit.penanceLaunch = false;
    hit.penanceHit = true;
    hit.target = target->GetObjectGuid();
    hit.leftMs = int32(GetMissileDelay(m_player, target, BONK_PENANCE_BOLT_SPEED));
    hit.incoming = GetWeaponDamage(owned) * GetDamageMultiplier(bolt, target) * GetHealthScale(target);
    target->GetPosition(hit.x, hit.y, hit.z);
    m_penanceIncoming[hit.target] += hit.incoming;
    m_pendingCasts.push_back(hit);
}

void BonkRun::LandPenanceBolt(OwnedWeapon& owned, SpellEntry const* bolt, PendingCast const& cast)
{
    auto const incoming = m_penanceIncoming.find(cast.target);
    if (incoming != m_penanceIncoming.end() && (incoming->second -= cast.incoming) <= 0.5f)
        m_penanceIncoming.erase(incoming);

    Creature* target = m_player->GetMap()->GetCreature(cast.target);
    if (!target || !target->IsAlive())
        return;
    if (owned.weapon.id == BONK_WEAPON_CONTRITION)
        for (Creature* mob : GetMobsInRange(GetWeaponRadius(owned), target))
            DealShamanHit(bolt, owned.weapon.spellId, mob, GetWeaponDamage(owned) * BONK_CONTRITION_SHARE);
    DealShamanHit(bolt, owned.weapon.spellId, target, GetWeaponDamage(owned));
    HealPriest(BONK_PENANCE_HEAL * (1.0f + owned.damageBonus / 100.0f), owned.weapon.spellId, true);
}

void BonkRun::HoldMob(Creature* mob, SpellEntry const* spellInfo, AuraType type, int32 durationMs)
{
    if (!mob || !mob->IsAlive() || !spellInfo)
        return;
    if (SpellAuraHolder* holder = mob->GetSpellAuraHolder(spellInfo->Id, m_player->GetObjectGuid()))
    {
        holder->SetAuraMaxDuration(durationMs);
        holder->SetAuraDuration(durationMs);
        holder->RefreshHolder();
        return;
    }
    SpellAuraHolder* holder = CreateSpellAuraHolder(spellInfo, mob, m_player, m_player);
    for (uint32 i = 0; i < MAX_EFFECT_INDEX; ++i)
        if (spellInfo->EffectApplyAuraName[i] == type)
        {
            Aura* aura = CreateAura(spellInfo, SpellEffectIndex(i), nullptr, holder, mob, m_player);
            aura->SetPositive(false);
            holder->AddAura(aura, SpellEffectIndex(i));
        }
    if (holder->IsEmptyHolder())
    {
        delete holder;
        return;
    }
    holder->SetPermanent(false);
    holder->SetAuraMaxDuration(durationMs);
    holder->SetAuraDuration(durationMs);
    mob->AddSpellAuraHolder(holder);
}

void BonkRun::ScreamPsychic(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    std::vector<Creature*> scared;
    for (Creature* mob : GetMobsInRange(GetWeaponRadius(owned)))
        if (IsNormalMob(mob) && m_player->IsWithinLOSInMap(mob))
            scared.push_back(mob);
    if (scared.empty())
    {
        owned.timer = 250;
        return;
    }
    owned.timer = GetWeaponCooldown(owned);
    ShowStrike(m_player, spellInfo, m_player);
    int32 const durationMs = int32(BONK_FEAR_MS * GetWeaponDurationScale(owned) + m_mastery.Special(BONK_SPECIAL_SHEER_TERROR) * IN_MILLISECONDS);
    for (Creature* mob : scared)
    {
        HoldMob(mob, spellInfo, SPELL_AURA_MOD_FEAR, durationMs);
        TrackPriestHold(owned, mob, spellInfo->Id, durationMs, BONK_FEAR_TICK_SHARE);
        if (owned.weapon.id == BONK_WEAPON_SHADOW_TERROR)
            ApplyWeaponKeyword(owned, mob, BONK_KEYWORD_DECAY, BONK_SHADOW_TERROR_STACKS);
    }
}

void BonkRun::BindShackle(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    std::vector<Creature*> mobs = GetMobsInRange(GetStrikeRange(owned));
    SortStrongestFirst(mobs);
    uint32 const chains = (owned.weapon.id == BONK_WEAPON_MASS_SHACKLE ? BONK_MASS_SHACKLE_CHAINS : 1) + GetSpellCount(owned);
    uint32 bound = 0;
    for (Creature* mob : mobs)
    {
        if (bound >= chains)
            break;
        if (!m_player->IsWithinLOSInMap(mob))
            continue;
        ++bound;
        ShowStrike(m_player, spellInfo, mob);
        DealShamanHit(spellInfo, owned.weapon.spellId, mob, GetWeaponDamage(owned));
        int32 const durationMs = int32(BONK_SHACKLE_MS * GetWeaponDurationScale(owned));
        if (mob->IsAlive() && CanBeBound(mob) && LimitShackle(mob, durationMs))
        {
            HoldMob(mob, spellInfo, SPELL_AURA_MOD_STUN, durationMs);
            TrackPriestHold(owned, mob, spellInfo->Id, durationMs, BONK_SHACKLE_TICK_SHARE);
        }
    }
    owned.timer = bound ? GetWeaponCooldown(owned) : 250;
}

void BonkRun::FlayMind(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    float const range = owned.weapon.range;
    Creature* target = m_player->GetMap()->GetCreature(m_mindFlayTarget);
    if (!target || !target->IsAlive() || !m_player->IsWithinDistInMap(target, range) || !m_player->IsWithinLOSInMap(target))
        target = FindPriestTarget(range);
    if (!target)
    {
        m_mindFlayTarget.Clear();
        owned.timer = 250;
        return;
    }
    bool const switched = target->GetObjectGuid() != m_mindFlayTarget;
    m_mindFlayTarget = target->GetObjectGuid();
    owned.timer = GetWeaponCooldown(owned);
    ShowStrike(m_player, spellInfo, target);
    bool const feedsOnDecay = GetKeywordStacks(target, BONK_KEYWORD_DECAY) >= BONK_MIND_FLAY_HEAL_DECAY;
    DealShamanHit(spellInfo, owned.weapon.spellId, target, GetWeaponDamage(owned));
    if (feedsOnDecay)
        HealPriest(BONK_MIND_FLAY_HEAL, owned.weapon.spellId, false);
    if (owned.weapon.id == BONK_WEAPON_MIND_SEAR)
        for (Creature* mob : GetMobsInRange(GetWeaponRadius(owned), target))
            DealShamanHit(spellInfo, owned.weapon.spellId, mob, GetWeaponDamage(owned) * BONK_MIND_SEAR_SHARE);
    if (!target->IsAlive())
    {
        if (m_mastery.Special(BONK_SPECIAL_SURGE_OF_DARKNESS) > 0.0f)
            ReduceTimer(BONK_WEAPON_MIND_BLAST, BONK_SURGE_OF_DARKNESS_MS);
        return;
    }
    uint32 stacks = owned.weapon.applyStacks;
    if (switched && owned.weapon.id == BONK_WEAPON_INSANITY)
        stacks += m_flayCarried;
    ApplyWeaponKeyword(owned, target, BONK_KEYWORD_DECAY, stacks);
    m_flayCarried = GetKeywordStacks(target, BONK_KEYWORD_DECAY);
    SlowNormalMob(target, spellInfo, &BONK_MIND_FLAY_SLOW, BONK_MIND_FLAY_SLOW_MS);
}

void BonkRun::SortMostDecayFirst(std::vector<Creature*>& mobs) const
{
    std::vector<std::pair<uint32, Creature*>> ranked;
    ranked.reserve(mobs.size());
    for (Creature* mob : mobs)
        ranked.emplace_back(GetKeywordStacks(mob, BONK_KEYWORD_DECAY), mob);
    std::stable_sort(ranked.begin(), ranked.end(), [](auto const& a, auto const& b) { return a.first > b.first; });
    for (size_t i = 0; i < ranked.size(); ++i)
        mobs[i] = ranked[i].second;
}

void BonkRun::BlastMind(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    std::vector<Creature*> mobs = GetMobsInRange(GetStrikeRange(owned));
    SortMostDecayFirst(mobs);
    uint32 const blasts = 1 + GetSpellCount(owned);
    float const reach = GetWeaponRadius(owned);
    uint32 fired = 0;
    for (Creature* target : mobs)
    {
        if (fired >= blasts)
            break;
        if (!target->IsAlive() || !m_player->IsWithinLOSInMap(target))
            continue;
        ++fired;
        uint32 const copied = std::min(GetKeywordStacks(target, BONK_KEYWORD_DECAY), BONK_MIND_BLAST_MAX_COPY + uint32(m_mastery.Special(BONK_SPECIAL_PSYCHIC_LINK)));
        std::vector<Creature*> const minds = GetMobsInRange(reach, target);
        ShowStrike(m_player, spellInfo, target);
        DealShamanHit(spellInfo, owned.weapon.spellId, target, GetWeaponDamage(owned));
        for (Creature* mind : minds)
        {
            if (owned.weapon.id == BONK_WEAPON_VOID_ERUPTION)
                DealShamanHit(spellInfo, owned.weapon.spellId, mind, GetWeaponDamage(owned) * BONK_VOID_ERUPTION_SHARE);
            ApplyWeaponKeyword(owned, mind, BONK_KEYWORD_DECAY, copied);
        }
        if (owned.weapon.id == BONK_WEAPON_MIND_SPIKE)
            SpikeDecay(owned, target);
    }
    owned.timer = fired ? GetWeaponCooldown(owned) : 250;
}

void BonkRun::OnPriestPetBite(Creature* pet, Unit* victim)
{
    if (m_player->GetClass() != CLASS_PRIEST || !victim)
        return;
    for (OwnedWeapon const& owned : m_weapons)
    {
        if (GetPriestPetFamily(owned) != BONK_PET_FAMILY_SHADOWFIEND ||
            std::find(owned.pets.begin(), owned.pets.end(), pet->GetObjectGuid()) == owned.pets.end())
            continue;
        HealPriest(GetHealPercent(owned.weapon, owned.damageBonus), owned.weapon.spellId, false);
        if (owned.weapon.id == BONK_WEAPON_MINDBENDER)
            if (SpellEntry const* shadow = sSpellMgr.GetSpellEntry(BONK_SPELL_SHADOW_HIT))
                for (Creature* mob : GetMobsInRange(GetWeaponRadius(owned), victim))
                    DealSpellHit(shadow, mob, GetWeaponDamage(owned) * BONK_MINDBENDER_SHARE, pet);
        return;
    }
}

void BonkRun::SpikeDecay(OwnedWeapon const& owned, Creature* target)
{
    BonkKeywordInfo const* info = sBonkMgr.GetKeyword(BONK_KEYWORD_DECAY);
    SpellAuraHolder const* holder = target->IsAlive() ? target->GetSpellAuraHolder(BONK_SPELL_DECAY_CARRIER, m_player->GetObjectGuid()) : nullptr;
    SpellEntry const* shadow = sSpellMgr.GetSpellEntry(BONK_SPELL_SHADOW_HIT);
    uint32 const stacks = GetKeywordStacks(target, BONK_KEYWORD_DECAY);
    if (!info || !holder || !shadow || !stacks || !info->tickMs)
        return;
    float const ticksLeft = float(std::max(0, holder->GetAuraDuration())) / float(info->tickMs);
    float const damage = GetDotTickDamage(*info) * stacks * ticksLeft * (1.0f + owned.damageBonus / 100.0f);
    target->RemoveAurasByCasterSpell(BONK_SPELL_DECAY_CARRIER, m_player->GetObjectGuid());
    DealShamanHit(shadow, owned.weapon.spellId, target, damage);
}

void BonkRun::OnPriestPeriodic(uint32 spellId, uint32 damage)
{
    if (spellId == BONK_SPELL_DECAY_CARRIER && FindOwned(BONK_WEAPON_VAMPIRIC_TOUCH))
        m_vampiricHeal += damage * BONK_VAMPIRIC_TOUCH_SHARE;
}

void BonkRun::DrainVampiricTouch()
{
    float const cap = m_player->GetMaxHealth() * BONK_VAMPIRIC_TOUCH_CAP / 100.0f;
    uint32 const heal = uint32(std::min(m_vampiricHeal, cap));
    m_vampiricHeal = 0.0f;
    if (heal && m_player->IsAlive())
    {
        OwnedWeapon const* vampiric = FindOwned(BONK_WEAPON_VAMPIRIC_TOUCH);
        SupportScope scope(*this, vampiric ? WeaponSupport(*vampiric) : BonkSupportSource());
        HealHero(ReduceHealing(heal), BONK_SPELL_DECAY_CARRIER);
    }
}

void BonkRun::GraspWithVoidTendrils()
{
    OwnedWeapon const* tendrils = FindOwned(BONK_WEAPON_VOID_TENDRILS);
    SpellEntry const* grasp = sSpellMgr.GetSpellEntry(BONK_SPELL_VOID_TENDRILS);
    if (!tendrils || !grasp || !m_player->IsAlive())
        return;
    Map* map = m_player->GetMap();
    float const radius = GetWeaponRadius(*tendrils);
    for (ObjectGuid const& guid : tendrils->pets)
    {
        Creature* fiend = map->GetCreature(guid);
        if (!fiend || !fiend->IsAlive())
            continue;
        for (Creature* mob : GetMobsInRange(radius, fiend))
        {
            int32 durationMs = BONK_VOID_TENDRILS_MS;
            if (IsNormalMob(mob) && LimitRoot(mob, durationMs))
            {
                ShowStrike(fiend, grasp, mob);
                HoldMob(mob, grasp, SPELL_AURA_MOD_ROOT, durationMs);
            }
        }
    }
}

float BonkRun::GetPriestDamageMultiplier(Unit const* victim) const
{
    if (!victim || m_player->GetClass() != CLASS_PRIEST)
        return 1.0f;
    float multiplier = 1.0f;
    if (FindOwned(BONK_WEAPON_PSYCHIC_HORROR) && victim->HasUnitState(UNIT_STATE_FLEEING))
        multiplier *= BONK_PSYCHIC_HORROR_BONUS;
    if (FindOwned(BONK_WEAPON_CHAINS_OF_LIGHT) && victim->HasAura(BONK_SPELL_SHACKLE))
        multiplier *= BONK_CHAINS_OF_LIGHT_BONUS;
    if (victim->GetSpellAuraHolder(BONK_SPELL_SCHISM, m_player->GetObjectGuid()))
        multiplier *= 1.0f + m_mastery.Special(BONK_SPECIAL_SCHISM) / 100.0f;
    return multiplier;
}

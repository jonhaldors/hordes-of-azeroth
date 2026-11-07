#include "BonkRun.h"
#include "BonkAura.h"
#include "BonkMobAI.h"
#include "BonkPlayer.h"
#include "Creature.h"
#include "Map.h"
#include "Player.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "Util.h"
#include "Utilities/Random.h"

#include <algorithm>

namespace
{
    uint32 const BONK_CAST_HASTE_MS             = 6000;
    int32 const BONK_SPLINTER_DELAY_MS          = 150;
    int32 const BONK_CLEARCAST_FLOOR_MS         = 300;
    int32 const BONK_INSTANT_RECHARGE_MS        = 600000;
    float const BONK_CONFLAGRATION_RADIUS       = 8.0f;
    uint32 const BONK_SPELL_GLACIAL_FRAGMENTS   = 122;
    float const BONK_GLACIAL_FRAGMENTS_RADIUS   = 5.0f;
    float const BONK_ARCANE_ECHO_RADIUS         = 8.0f;
    uint32 const BONK_ARCANE_POTENCY_CASTS      = 3;
    uint32 const BONK_BLOODSURGE_MS             = 8000;
    size_t const BONK_BLOODSURGE_STACKS         = 10;
    float const BONK_UNBREAKABLE_SHIELD         = 0.3f;
    uint32 const BONK_OVERPOWER_BLEED           = 10;
    int32 const BONK_THUNDERLORD_DELAY_MS       = 400;
    float const BONK_BEAST_CLEAVE_RADIUS        = 3.0f;
    float const BONK_INTIMIDATING_ROAR_RADIUS   = 10.0f;
    uint32 const BONK_RAPID_FIRE_MS             = 5000;
    int32 const BONK_MONGOOSE_REFRESH_MS        = 500;
    float const BONK_MONGOOSE_RADIUS            = 10.0f;
    uint32 const BONK_MONGOOSE_MAX_STACKS       = 10;
    uint32 const BONK_BULWARK_MAX_STACKS        = 10;
    uint32 const BONK_SLICE_AND_DICE_MS         = 5000;
    uint32 const BONK_DANSE_MACABRE_MS          = 8000;
    size_t const BONK_DANSE_MACABRE_STACKS      = 10;
    uint32 const BONK_BORROWED_TIME_MS          = 4000;
    uint32 const BONK_SCHISM_MS                 = 6000;
    float const BONK_SHINING_FORCE_RADIUS       = 6.0f;
    uint32 const BONK_ANSWERED_PRAYERS_EVERY    = 8;
    float const BONK_ANCIENT_MADNESS_RADIUS     = 20.0f;
    uint32 const BONK_ANCIENT_MADNESS_MAX_STACKS = 10;
    uint32 const BONK_UNRELENTING_STORM_MS      = 6000;
    size_t const BONK_UNRELENTING_STORM_STACKS  = 10;
    uint32 const BONK_FLURRY_MS                 = 4000;
    uint32 const BONK_FORCEFUL_WINDS_MS         = 8000;
    size_t const BONK_FORCEFUL_WINDS_STACKS     = 5;
    float const BONK_CALL_OF_THE_ELEMENTS_RANGE = 15.0f;
    uint32 const BONK_HARVESTER_MS              = 8000;
    size_t const BONK_HARVESTER_STACKS          = 10;
    uint32 const BONK_SOUL_FIRE_EVERY           = 5;
    uint32 const BONK_SOUL_FIRE_BURNING         = 3;
    uint32 const BONK_STARLORD_MS               = 8000;
    size_t const BONK_STARLORD_STACKS           = 3;
    uint32 const BONK_SOUL_OF_THE_FOREST_MS     = 8000;
    size_t const BONK_SOUL_OF_THE_FOREST_STACKS = 10;
    uint32 const BONK_BLOODTALONS_MAX_STACKS    = 10;

    // Spec ids as `bonk_weapon.spec` stores them, shared by every weapon in the spec.
    uint32 CastHasteAura(uint32 spec)
    {
        switch (spec)
        {
            case 201: return BONK_SPELL_AVENGING_WRATH;
            case 203: return BONK_SPELL_ZEALOTRY;
            case 801: return BONK_SPELL_ARCANE_TEMPO;
            default: return 0;
        }
    }

    void PushTimedStack(std::vector<uint32>& stacks, uint32 now, uint32 lengthMs, size_t cap)
    {
        stacks.erase(std::remove_if(stacks.begin(), stacks.end(), [now](uint32 until) { return until <= now; }), stacks.end());
        stacks.push_back(now + lengthMs);
        if (stacks.size() > cap)
            stacks.erase(stacks.begin());
    }

    float CountTimedStacks(std::vector<uint32> const& stacks, uint32 now)
    {
        return float(std::count_if(stacks.begin(), stacks.end(), [now](uint32 until) { return until > now; }));
    }
    float const BONK_BESTIAL_WRATH_FRENZY       = 1.5f;
    float const BONK_BESTIAL_WRATH_OWN_DAMAGE   = 0.75f;
    float const BONK_BESTIAL_WRATH_HOWL         = 1.25f;
    float const BONK_TRUESHOT_MARKED            = 1.3f;
    float const BONK_CAPSTONE_EMPOWERED         = 1.2f;
    uint32 const BONK_SHATTERLORD_FREEZE_STACKS = 4;
    float const BONK_BERSERKER_DAMAGE_TAKEN     = 1.15f;
    float const BONK_SPELL_SHIELD_CAP           = 0.5f;
    float const BONK_JUGGERNAUT_SHIELD_CAP      = 1.0f;
    float const BONK_JUGGERNAUT_REGEN_PER_SEC   = 0.1f;
    uint32 const BONK_WEAPON_MASTER_EVERY       = 3;
    float const BONK_WEAPON_MASTER_CRIT_DAMAGE  = 0.25f;
    float const BONK_PRIMAL_FURY_CAT_CRIT_DAMAGE = 0.25f;
    float const BONK_TRAPMASTER_DASH_RECHARGE   = 1.3f;
    float const BONK_ARCANE_SURGE_RECHARGE      = 2.0f;
    float const BONK_LOW_HEALTH_GUARD           = 20.0f;
    float const BONK_ICE_BLOCK_RADIUS           = 10.0f;
    uint32 const BONK_ICE_BLOCK_CHILL           = 10;
    uint32 const BONK_KIT_ICE_BLOCK             = 160;
    uint32 const BONK_SPELL_TALENT_STUN         = 7922;

    BonkMobAI const* GetRunAI(Unit const* unit)
    {
        Creature const* creature = unit ? unit->ToCreature() : nullptr;
        return creature ? dynamic_cast<BonkMobAI const*>(creature->AI()) : nullptr;
    }
}

void BonkRun::ApplyMasteryTo(BonkWeapon& weapon) const
{
    uint32 const root = BonkMastery::GetRootWeapon(weapon.id);

    auto applies = m_mastery.spellApplies.find(root);
    if (applies != m_mastery.spellApplies.end() && weapon.applies == BONK_KEYWORD_NONE)
    {
        weapon.applies = applies->second.keyword;
        weapon.applyStacks = applies->second.stacks;
    }

    auto uses = m_mastery.usesBonus.find(root);
    if (uses != m_mastery.usesBonus.end() && weapon.uses != BONK_KEYWORD_NONE)
        weapon.usesPct += uses->second;

    auto stacks = m_mastery.spellStacks.find(root);
    if (stacks != m_mastery.spellStacks.end() && weapon.applies != BONK_KEYWORD_NONE)
        weapon.applyStacks += uint8(stacks->second);
    if (m_mastery.Has(BONK_CAPSTONE_SHADOWFORM) && weapon.applies == BONK_KEYWORD_DECAY && weapon.applyStacks)
        ++weapon.applyStacks;

    auto duration = m_mastery.spellDuration.find(root);
    if (duration != m_mastery.spellDuration.end() && weapon.durationMs)
        weapon.durationMs += uint32(duration->second * IN_MILLISECONDS);

    auto behavior = m_mastery.spellBehavior.find(root);
    if (behavior != m_mastery.spellBehavior.end())
        weapon.behaviorValue += behavior->second;

    auto heal = m_mastery.spellHeal.find(root);
    if (heal != m_mastery.spellHeal.end())
        weapon.healPct += heal->second;

    if (m_mastery.resetOnKill.count(root))
        weapon.flags |= BONK_WEAPON_FLAG_RESET_ON_KILL;

    auto execute = m_mastery.executeThreshold.find(root);
    if (execute != m_mastery.executeThreshold.end())
    {
        if (weapon.killBelowPct > 0.0f)
            weapon.killBelowPct = std::max(weapon.killBelowPct, execute->second);
        if (weapon.behavior == BONK_BEHAVIOR_EXECUTE)
            weapon.behaviorValue = std::max(weapon.behaviorValue, execute->second);
    }
}

float BonkRun::GetSpecDamage(uint32 weaponId) const
{
    if (m_mastery.specDamage.empty())
        return 0.0f;
    auto itr = m_mastery.specDamage.find(BonkMastery::GetSpec(weaponId));
    return itr != m_mastery.specDamage.end() ? itr->second : 0.0f;
}

float BonkRun::GetTalentDamagePercent() const
{
    float percent = m_castDamageBonus;
    float const surge = m_mastery.Special(BONK_SPECIAL_BLOODSURGE);
    if (surge > 0.0f)
    {
        uint32 const now = m_totalMs;
        percent += surge * float(std::count_if(m_bloodsurgeUntil.begin(), m_bloodsurgeUntil.end(), [now](uint32 until) { return until > now; }));
    }
    percent += m_mastery.Special(BONK_SPECIAL_PACK_HUNTER) * float(CountLivingPets());
    percent += m_mastery.Special(BONK_SPECIAL_BULWARK) * float(m_bulwarkStacks);
    percent += m_mastery.Special(BONK_SPECIAL_ANCIENT_MADNESS) * float(m_madnessStacks);
    percent += m_mastery.Special(BONK_SPECIAL_BLOODTALONS) * float(m_bloodtalonsStacks);
    percent += m_mastery.Special(BONK_SPECIAL_FORCEFUL_WINDS) * CountTimedStacks(m_forcefulUntil, m_totalMs);
    if (m_mastery.Special(BONK_SPECIAL_DEMONIC_PACT) > 0.0f)
        percent += m_mastery.Special(BONK_SPECIAL_DEMONIC_PACT) * float(CountDemonFamilies());
    if (m_mastery.Special(BONK_SPECIAL_CALL_OF_THE_ELEMENTS) > 0.0f && IsNearOwnTotem())
        percent += m_mastery.Special(BONK_SPECIAL_CALL_OF_THE_ELEMENTS);
    if (m_spellShield)
        percent += m_mastery.Special(BONK_SPECIAL_POWER_INFUSION);
    if (m_player->GetHealth() >= m_player->GetMaxHealth())
        percent += m_mastery.Special(BONK_SPECIAL_DIVINE_PROVIDENCE);
    float const danse = m_mastery.Special(BONK_SPECIAL_DANSE_MACABRE);
    if (danse > 0.0f)
    {
        uint32 const now = m_totalMs;
        percent += danse * float(std::count_if(m_danseUntil.begin(), m_danseUntil.end(), [now](uint32 until) { return until > now; }));
    }
    float const unbreakable = m_mastery.Special(BONK_SPECIAL_UNBREAKABLE);
    if (unbreakable > 0.0f && m_spellShield >= uint32(m_player->GetMaxHealth() * BONK_UNBREAKABLE_SHIELD))
        percent += unbreakable;
    if (IsEnraged())
        percent += m_mastery.enrageDamage * m_mastery.EnrageBoost();
    if (IsHowlFrenzied())
        percent += m_mastery.frenzyDamage;
    return percent;
}

float BonkRun::GetCapstoneDamageMultiplier(bool ownSpell, Unit const* victim) const
{
    float multiplier = 1.0f;
    if (ownSpell && m_mastery.Has(BONK_CAPSTONE_BESTIAL_WRATH))
        multiplier *= BONK_BESTIAL_WRATH_OWN_DAMAGE;
    if (IsCapstoneEmpowered())
        multiplier *= BONK_CAPSTONE_EMPOWERED;
    if (!victim || !GetRunAI(victim))
        return multiplier;
    if (m_mastery.Has(BONK_CAPSTONE_TRUESHOT) && GetKeywordStacks(victim, BONK_KEYWORD_HUNTERS_MARK))
        multiplier *= BONK_TRUESHOT_MARKED;
    return multiplier;
}

bool BonkRun::IsCapstoneEmpowered() const
{
    if (m_mastery.Has(BONK_CAPSTONE_JUGGERNAUT))
        return m_spellShield * 2 > GetSpellShieldCap();
    if (m_mastery.Has(BONK_CAPSTONE_PAIN_SUPPRESSION))
        return m_spellShield > 0;
    if (m_mastery.Has(BONK_CAPSTONE_GUARDIAN_OF_THE_LIGHT))
        return IsStandingInConsecration();
    return false;
}

float BonkRun::GetCapstoneCritDamage(SpellEntry const* spell) const
{
    if (m_mastery.Has(BONK_CAPSTONE_PRIMAL_FURY) && m_druidForm == BonkDruidForm::Cat)
        return BONK_PRIMAL_FURY_CAT_CRIT_DAMAGE;
    return IsWeaponMasterStrike(spell) ? BONK_WEAPON_MASTER_CRIT_DAMAGE : 0.0f;
}

BonkRun::OwnedWeapon const* BonkRun::FindSummonOwner(Unit const* unit) const
{
    if (!unit || !unit->IsCreature())
        return nullptr;
    ObjectGuid const guid = unit->GetObjectGuid();
    for (OwnedWeapon const& owned : m_weapons)
        if (std::find(owned.pets.begin(), owned.pets.end(), guid) != owned.pets.end())
            return &owned;
    for (Snake const& snake : m_snakes)
        if (snake.guid == guid)
            return FindOwned(snake.weaponId);
    for (Beast const& beast : m_beasts)
        if (beast.guid == guid)
            return FindOwned(beast.weaponId);
    for (WarlockMinion const& minion : m_warlockMinions)
        if (minion.guid == guid)
            return FindOwned(minion.weaponId);
    return nullptr;
}

float BonkRun::GetSummonDamageMultiplier(Unit const* attacker) const
{
    OwnedWeapon const* owner = FindSummonOwner(attacker);
    return owner ? 1.0f + GetSpecDamage(owner->weapon.id) / 100.0f : 1.0f;
}

float BonkRun::GetTalentCritChance(Unit const* victim, Unit const* attacker) const
{
    float chance = m_castCritBonus;
    if (victim)
        for (auto const& itr : m_mastery.critVsKeyword)
            if (GetKeywordStacks(victim, BonkKeyword(itr.first)))
                chance += itr.second;
    if (attacker && m_mastery.summonCrit > 0.0f && IsSummon(attacker))
        chance += m_mastery.summonCrit;
    return chance;
}

bool BonkRun::IsWeaponMasterStrike(SpellEntry const* spell) const
{
    if (!spell || !m_mastery.Has(BONK_CAPSTONE_WEAPON_MASTER))
        return false;
    OwnedWeapon const* owned = FindOwnedBySpell(spell->Id);
    return owned && owned->casts && owned->casts % BONK_WEAPON_MASTER_EVERY == 0;
}

float BonkRun::GetKeywordTalentDamage(uint32 keyword) const
{
    auto itr = m_mastery.keywordDamage.find(keyword);
    return itr != m_mastery.keywordDamage.end() ? itr->second : 0.0f;
}

uint32 BonkRun::GetExtraSpreadTargets(uint32 keyword) const
{
    auto itr = m_mastery.spreadTargets.find(keyword);
    return itr != m_mastery.spreadTargets.end() ? itr->second : 0;
}

uint32 BonkRun::GetChillFreezeStacks(BonkKeywordInfo const& chill) const
{
    if (m_mastery.Has(BONK_CAPSTONE_SHATTERLORD))
        return std::min<uint32>(BONK_SHATTERLORD_FREEZE_STACKS, chill.maxStacks);
    return chill.maxStacks;
}

uint32 BonkRun::GetChillTalentMs() const
{
    return uint32(m_mastery.chillDuration * IN_MILLISECONDS);
}

void BonkRun::QueueTalentStun(OwnedWeapon const& owned, Unit* victim)
{
    if (m_mastery.spellStun.count(GetRootWeapon(owned.weapon)))
        m_pendingStuns.push_back(victim->GetObjectGuid());
}

void BonkRun::ApplyPendingStuns()
{
    if (m_pendingStuns.empty())
        return;
    std::vector<ObjectGuid> stuns;
    stuns.swap(m_pendingStuns);
    Map* map = m_player->GetMap();
    for (ObjectGuid const& guid : stuns)
    {
        Creature* mob = map->GetCreature(guid);
        BonkMobAI const* ai = mob ? GetRunAI(mob) : nullptr;
        if (ai && ai->GetKind() == BONK_SPAWN_NORMAL && mob->IsAlive())
            m_player->CastSpell(mob, BONK_SPELL_TALENT_STUN, true);
    }
}

uint32 BonkRun::GetSpellShieldCap() const
{
    float const cap = m_mastery.Has(BONK_CAPSTONE_JUGGERNAUT) ? BONK_JUGGERNAUT_SHIELD_CAP : BONK_SPELL_SHIELD_CAP;
    return uint32(m_player->GetMaxHealth() * cap);
}

uint32 BonkRun::GetShieldBlockTalent() const
{
    return uint32(m_player->GetMaxHealth() * m_mastery.shieldBlock / 100.0f);
}

void BonkRun::RechargeJuggernautShield(uint32 diff, uint32 max)
{
    if (!m_mastery.Has(BONK_CAPSTONE_JUGGERNAUT) || m_spellShield >= max)
        return;
    m_juggernautCarry += max * BONK_JUGGERNAUT_REGEN_PER_SEC * diff / IN_MILLISECONDS;
    uint32 const gained = uint32(m_juggernautCarry);
    m_juggernautCarry -= gained;
    RefillShield(std::min(max, m_spellShield + gained));
}

uint32 BonkRun::GetKeywordTalentMs(BonkKeyword keyword) const
{
    auto itr = m_mastery.keywordDuration.find(keyword);
    return itr != m_mastery.keywordDuration.end() ? uint32(itr->second * IN_MILLISECONDS) : 0;
}

uint32 BonkRun::GetKeywordTalentCap(uint32 keyword) const
{
    auto itr = m_mastery.keywordCap.find(keyword);
    return itr != m_mastery.keywordCap.end() ? uint32(itr->second) : 0;
}

float BonkRun::GetTalentReach(OwnedWeapon const& owned) const
{
    auto itr = m_mastery.spellReach.find(GetRootWeapon(owned.weapon));
    return itr != m_mastery.spellReach.end() ? itr->second : 0.0f;
}

uint32 BonkRun::ApplyTalentDamageTaken(uint32 damage) const
{
    if (m_mastery.Has(BONK_CAPSTONE_BERSERKER))
        damage = uint32(damage * BONK_BERSERKER_DAMAGE_TAKEN);
    if (m_bonuses.damageTakenCut > 0.0f)
        damage = uint32(damage * std::max(0.0f, 1.0f - m_bonuses.damageTakenCut / 100.0f));
    return damage;
}

bool BonkRun::IsIceBlocked() const
{
    return m_player->HasAura(BONK_SPELL_ICE_BLOCK_AURA);
}

uint32 BonkRun::GuardLowHealth(uint32 damage)
{
    if (!damage || m_lowHealthGuardStage == m_stage || (m_mastery.lastStand <= 0.0f && m_mastery.iceBlock <= 0.0f))
        return damage;

    uint32 const health = m_player->GetHealth();
    uint32 const floor = uint32(m_player->GetMaxHealth() * BONK_LOW_HEALTH_GUARD / 100.0f);
    if (health > damage && health - damage >= floor)
        return damage;

    m_lowHealthGuardStage = m_stage;
    if (m_mastery.iceBlock > 0.0f)
    {
        if (SpellAuraHolder* holder = m_player->AddAura(BONK_SPELL_ICE_BLOCK_AURA, ADD_AURA_POSITIVE))
        {
            int32 const duration = int32(m_mastery.iceBlock * IN_MILLISECONDS);
            holder->SetAuraDuration(duration);
            holder->SetAuraMaxDuration(duration);
            holder->UpdateAuraDuration();
        }
        m_iceBlockBurstPending = true;
        return 0;
    }

    SupportScope scope(*this, TalentSupport(BONK_MASTERY_LAST_STAND));
    AddSpellShield(uint32(m_player->GetMaxHealth() * m_mastery.lastStand / 100.0f));
    return damage - AbsorbSpellShield(damage);
}

void BonkRun::BurstIceBlock()
{
    if (!m_iceBlockBurstPending)
        return;
    m_iceBlockBurstPending = false;
    if (!m_player->IsAlive())
        return;
    m_player->SendPlaySpellVisualKit(BONK_KIT_ICE_BLOCK);
    for (Creature* mob : GetMobsInRange(BONK_ICE_BLOCK_RADIUS))
        ApplyKeyword(mob, BONK_KEYWORD_CHILL, BONK_ICE_BLOCK_CHILL, 0, 1.0f, 0);
}

void BonkRun::CastOnStruck()
{
    if (m_mastery.struckCast.empty() || m_struckAtMs == m_talentStruckSeenMs)
        return;
    m_talentStruckSeenMs = m_struckAtMs;
    if (!m_player->IsAlive())
        return;

    for (auto const& itr : m_mastery.struckCast)
    {
        uint32& readyMs = m_struckCastReadyMs[itr.first];
        if (readyMs > m_totalMs)
            continue;
        OwnedWeapon* owned = nullptr;
        for (OwnedWeapon& candidate : m_weapons)
            if (GetRootWeapon(candidate.weapon) == itr.first)
                owned = &candidate;
        if (!owned)
            continue;

        readyMs = m_totalMs + uint32(itr.second * IN_MILLISECONDS);
        ApplyStruckCastCooldown(itr.first, uint32(itr.second));
        if (owned->weapon.behavior == BONK_BEHAVIOR_TRAP)
        {
            DropTraps(*owned, true);
            continue;
        }

        PendingCast nova;
        nova.weaponId = owned->weapon.id;
        nova.spellId = owned->weapon.spellId;
        nova.leftMs = 0;
        nova.selfArea = true;
        m_pendingCasts.push_back(nova);
    }
}

// The four "when struck" masteries (hunter Counterattack, priest Shadow Weaving, shaman
// Shamanistic Rage, mage Improved Frost Nova) each carry a player-side internal cooldown of five
// or six seconds - long enough to be worth watching. Show it as a debuff whose native countdown
// sweeps out the seconds until the next free cast can trigger; the text states the cooldown length
// once and the icon counts it down, exactly like the Bladestorm window aura.
void BonkRun::ApplyStruckCastCooldown(uint32 weaponRoot, uint32 icdSeconds)
{
    struct CooldownAura { uint32 const weaponRoot; uint32 const spellId; };
    static CooldownAura const cooldownAuras[] = {
        { 202, BONK_SPELL_COUNTERATTACK_CD },     // Explosive Trap: Counterattack
        { 510, BONK_SPELL_SHADOW_WEAVING_CD },    // Mind Blast: Shadow Weaving
        { 705, BONK_SPELL_SHAMANISTIC_RAGE_CD },  // Stormstrike: Shamanistic Rage
        { 402, BONK_SPELL_FROST_NOVA_CD },        // Frost Nova: Improved Frost Nova
    };
    uint32 spellId = 0;
    for (CooldownAura const& aura : cooldownAuras)
        if (aura.weaponRoot == weaponRoot)
            spellId = aura.spellId;
    if (!spellId || !m_player->IsAlive())
        return;
    uint32 const durationMs = icdSeconds * IN_MILLISECONDS;
    if (SpellAuraHolder* holder = m_player->AddAura(spellId, ADD_AURA_NEGATIVE))
    {
        holder->SetAuraDuration(int32(durationMs));
        holder->SetAuraMaxDuration(int32(durationMs));
        holder->UpdateAuraDuration();
    }
    BonkAuraEntry const* entry = sBonkAura.Get(spellId);
    if (entry && m_player->GetBonkPlayer()->IsAddonReady())
        m_player->GetBonkPlayer()->SendAuraText(spellId,
            sBonkAura.Format(*entry, GetLocale(), { std::to_string(icdSeconds) }));
}

void BonkRun::ApplyTimedAura(uint32 spellId, uint32 durationMs, float percent) const
{
    if (!m_player || !m_player->IsAlive())
        return;
    if (SpellAuraHolder* holder = m_player->AddAura(spellId, ADD_AURA_POSITIVE))
    {
        holder->SetAuraDuration(int32(durationMs));
        holder->SetAuraMaxDuration(int32(durationMs));
        holder->UpdateAuraDuration();
    }
    // A flat-percent window (Rapid Fire, Slice and Dice, Borrowed Time, Flurry): the bonus does not
    // stack, so state it once when the aura is applied.
    if (percent > 0.0f)
        if (BonkAuraEntry const* entry = sBonkAura.Get(spellId))
            if (m_player->GetBonkPlayer()->IsAddonReady())
                m_player->GetBonkPlayer()->SendAuraText(spellId,
                    sBonkAura.Format(*entry, GetLocale(), { FormatBonkNumber(percent) }));
}

void BonkRun::ApplyTimedAuraTo(Unit* target, uint32 spellId, uint32 durationMs, uint32 flags) const
{
    if (!target || !target->IsAlive())
        return;
    if (SpellAuraHolder* holder = target->AddAura(spellId, flags, m_player))
    {
        holder->SetAuraDuration(int32(durationMs));
        holder->SetAuraMaxDuration(int32(durationMs));
        holder->UpdateAuraDuration();
    }
}

uint32 BonkRun::RemainingAuraMs(uint32 spellId) const
{
    SpellAuraHolder const* holder = m_player->GetSpellAuraHolder(spellId);
    if (!holder)
        return 0;
    return holder->GetAuraDuration() > 0 ? uint32(holder->GetAuraDuration()) : 0;
}

void BonkRun::SyncTimedStackAura(uint32 spellId, std::vector<uint32> const& untils, float percentPerStack) const
{
    uint32 stacks = 0;
    uint32 longest = 0;
    for (uint32 until : untils)
    {
        int32 const left = int32(until - m_totalMs);
        if (left <= 0)
            continue;
        ++stacks;
        longest = std::max(longest, uint32(left));
    }
    SpellAuraHolder* holder = m_player->GetSpellAuraHolder(spellId);
    if (!stacks)
    {
        if (holder)
            m_player->RemoveAurasDueToSpell(spellId);
        return;
    }
    if (holder)
    {
        int32 delta = holder->GetAuraDuration() - int32(longest);
        if (delta < 0)
            delta = -delta;
        if (holder->GetStackAmount() == stacks && delta <= 600)
            return;
    }
    holder = m_player->AddAura(spellId, ADD_AURA_POSITIVE);
    if (!holder)
        return;
    holder->SetStackAmount(stacks);
    holder->SetAuraDuration(int32(longest));
    holder->SetAuraMaxDuration(int32(longest));
    holder->UpdateAuraDuration();
    // State the live bonus in the tooltip: stacks x the per-stack value the mastery grants. Sent
    // only here (the early return above skips an unchanged stack/duration), so the text moves just
    // when the number it shows does; the client skips a re-send of an identical string.
    if (percentPerStack > 0.0f)
        if (BonkAuraEntry const* entry = sBonkAura.Get(spellId))
            if (m_player->GetBonkPlayer()->IsAddonReady())
                m_player->GetBonkPlayer()->SendAuraText(spellId,
                    sBonkAura.Format(*entry, GetLocale(), { FormatBonkNumber(float(stacks) * percentPerStack) }));
}

bool BonkRun::SyncStackAura(uint32 spellId, uint32 stacks) const
{
    SpellAuraHolder* holder = m_player->GetSpellAuraHolder(spellId);
    if (!stacks)
    {
        if (holder)
            m_player->RemoveAurasDueToSpell(spellId);
        return holder != nullptr;
    }
    if (holder && holder->GetStackAmount() == stacks)
        return false;
    if (!holder)
        holder = m_player->AddAura(spellId, ADD_AURA_POSITIVE | ADD_AURA_PERMANENT);
    if (holder)
    {
        uint8 const slot = holder->GetAuraSlot();
        holder->SetStackAmount(stacks);
        m_player->ForceValuesUpdateAtIndex(UNIT_FIELD_AURAAPPLICATIONS + (slot >> 2));
        m_player->ExecuteDelayedActions();
        m_player->SendForcedObjectUpdate();
    }
    return true;
}

void BonkRun::UpdateTalentAuras()
{
    if (m_totalMs < m_nextTalentAuraSyncMs)
        return;
    m_nextTalentAuraSyncMs = m_totalMs + 400;
    SyncTimedStackAura(BONK_SPELL_BLOODSURGE, m_bloodsurgeUntil, m_mastery.Special(BONK_SPECIAL_BLOODSURGE));
    SyncTimedStackAura(BONK_SPELL_FORCEFUL_WINDS, m_forcefulUntil, m_mastery.Special(BONK_SPECIAL_FORCEFUL_WINDS));
    SyncTimedStackAura(BONK_SPELL_DANSE_MACABRE, m_danseUntil, m_mastery.Special(BONK_SPECIAL_DANSE_MACABRE));
    SyncTimedStackAura(BONK_SPELL_STARLORD, m_starlordUntil, m_mastery.Special(BONK_SPECIAL_STARLORD));
    SyncTimedStackAura(BONK_SPELL_SOUL_OF_THE_FOREST, m_forestUntil, m_mastery.Special(BONK_SPECIAL_SOUL_OF_THE_FOREST));
    SyncTimedStackAura(BONK_SPELL_HARVESTER_OF_SOULS, m_harvestUntil, m_mastery.Special(BONK_SPECIAL_HARVESTER_OF_SOULS));
    SyncTimedStackAura(BONK_SPELL_UNRELENTING_STORM, m_unrelentingUntil, m_mastery.Special(BONK_SPECIAL_UNRELENTING_STORM));
    for (auto const& itr : m_castHasteUntil)
        if (uint32 const spellId = CastHasteAura(itr.first))
        {
            auto perStack = m_mastery.castHaste.find(itr.first);
            SyncTimedStackAura(spellId, itr.second, perStack != m_mastery.castHaste.end() ? perStack->second : 0.0f);
        }
    SyncStackAura(BONK_SPELL_MONGOOSE_FURY, m_mongooseStacks);
    SyncStackAura(BONK_SPELL_BULWARK, m_bulwarkStacks);
    SyncStackAura(BONK_SPELL_ANCIENT_MADNESS, m_madnessStacks);
    SyncStackAura(BONK_SPELL_BLOODTALONS, m_bloodtalonsStacks);
    SyncStackAura(BONK_SPELL_CLEARCASTING, m_clearcastBoostReady ? 1 : 0);
    SyncStackAura(BONK_SPELL_FINGERS_OF_FROST, m_fingersReady ? 1 : 0);
    SyncStackAura(BONK_SPELL_ARCANE_POTENCY, m_potencyCasts);
    SyncStackAura(BONK_SPELL_AEGIS, m_aegisPending ? 1 : 0);
    SyncStackAura(BONK_SPELL_VANISH_CRIT, m_vanishCritPending ? 1 : 0);
}

void BonkRun::UpdateTalents()
{
    BurstIceBlock();
    CastOnStruck();
    if (m_mastery.Has(BONK_CAPSTONE_BERSERKER) && m_player->IsAlive())
        Enrage();
}

void BonkRun::OnTalentDash()
{
    if (!m_mastery.Has(BONK_CAPSTONE_TRAPMASTER))
        return;
    for (OwnedWeapon& owned : m_weapons)
        if (owned.weapon.behavior == BONK_BEHAVIOR_TRAP && owned.weapon.target == BONK_TARGET_SELF)
            DropTraps(owned, true);
}

void BonkRun::BeginTalentCast(OwnedWeapon const& owned)
{
    m_castDamageBonus = m_clearcastBoostReady ? m_mastery.Special(BONK_SPECIAL_CLEARCASTING_BOOST) : 0.0f;
    m_castCritBonus = m_potencyCasts ? m_mastery.Special(BONK_SPECIAL_ARCANE_POTENCY) : 0.0f;
    m_searingBurstArmed = m_mastery.Special(BONK_SPECIAL_SEARING_BURST) > 0.0f && GetRootWeapon(owned.weapon) == BONK_WEAPON_FIRE_BLAST;
}

void BonkRun::EndTalentCast()
{
    m_castDamageBonus = 0.0f;
    m_castCritBonus = 0.0f;
    m_searingBurstArmed = false;
}

void BonkRun::OnTalentCastDone(OwnedWeapon& owned)
{
    uint32 const root = GetRootWeapon(owned.weapon);
    if (m_castDamageBonus > 0.0f)
        m_clearcastBoostReady = false;
    if (m_castCritBonus > 0.0f && m_potencyCasts)
    {
        --m_potencyCasts;
        SyncStackAura(BONK_SPELL_ARCANE_POTENCY, m_potencyCasts);
    }

    uint32 const spec = BonkMastery::GetSpec(owned.weapon.id);
    auto haste = m_mastery.castHaste.find(spec);
    if (haste != m_mastery.castHaste.end() && haste->second > 0.0f)
    {
        uint32 const now = m_totalMs;
        std::vector<uint32>& stacks = m_castHasteUntil[spec];
        stacks.erase(std::remove_if(stacks.begin(), stacks.end(), [now](uint32 until) { return until <= now; }), stacks.end());
        stacks.push_back(now + BONK_CAST_HASTE_MS);
        auto cap = m_mastery.castHasteStacks.find(spec);
        if (stacks.size() > std::max(1u, cap != m_mastery.castHasteStacks.end() ? cap->second : 1u))
            stacks.erase(stacks.begin());
    }

    if (root == BONK_WEAPON_EXORCISM && m_mastery.Special(BONK_SPECIAL_AWAKENING) > 0.0f)
        ReduceTimer(BONK_WEAPON_LIGHTS_HAMMER, int32(m_mastery.Special(BONK_SPECIAL_AWAKENING) * IN_MILLISECONDS));
    if (root == BONK_WEAPON_HAMMER_OF_JUSTICE && m_mastery.Special(BONK_SPECIAL_RIGHTEOUS_PROTECTOR) > 0.0f)
        ReduceTimer(BONK_WEAPON_DIVINE_SHIELD, int32(m_mastery.Special(BONK_SPECIAL_RIGHTEOUS_PROTECTOR) * IN_MILLISECONDS));
    if (root == BONK_WEAPON_LIGHTS_HAMMER && roll_chance_f(m_mastery.Special(BONK_SPECIAL_DIVINE_PURPOSE)))
        owned.timer = std::min<int32>(owned.timer, BONK_CLEARCAST_FLOOR_MS);

    if (root == BONK_WEAPON_STARFIRE && m_mastery.Special(BONK_SPECIAL_STARLORD) > 0.0f)
        PushTimedStack(m_starlordUntil, m_totalMs, BONK_STARLORD_MS, BONK_STARLORD_STACKS);

    if (root == BONK_WEAPON_POWER_WORD_SHIELD)
    {
        if (m_mastery.Special(BONK_SPECIAL_BORROWED_TIME) > 0.0f)
            ApplyTimedAura(BONK_SPELL_BORROWED_TIME, BONK_BORROWED_TIME_MS, m_mastery.Special(BONK_SPECIAL_BORROWED_TIME));
        if (m_mastery.Special(BONK_SPECIAL_SHINING_FORCE) > 0.0f)
            for (Creature* mob : GetMobsInRange(BONK_SHINING_FORCE_RADIUS))
                m_pendingStuns.push_back(mob->GetObjectGuid());
    }

    if (root == BONK_WEAPON_SMITE && m_mastery.Special(BONK_SPECIAL_ANSWERED_PRAYERS) > 0.0f && ++m_smiteCount % BONK_ANSWERED_PRAYERS_EVERY == 0)
        ReduceTimer(BONK_WEAPON_HALO, BONK_INSTANT_RECHARGE_MS);

    if (root == BONK_WEAPON_EVISCERATE)
    {
        float const restless = m_mastery.Special(BONK_SPECIAL_RESTLESS_BLADES);
        if (restless > 0.0f)
            ReduceTimer(BONK_WEAPON_KILLING_SPREE, int32(restless * IN_MILLISECONDS));
        float const adrenaline = m_mastery.Special(BONK_SPECIAL_ADRENALINE_RUSH);
        if (adrenaline > 0.0f)
            ReduceTimer(BONK_WEAPON_BLADE_FLURRY, int32(adrenaline * IN_MILLISECONDS));
        if (m_mastery.Special(BONK_SPECIAL_SLICE_AND_DICE) > 0.0f)
            ApplyTimedAura(BONK_SPELL_SLICE_AND_DICE, BONK_SLICE_AND_DICE_MS, m_mastery.Special(BONK_SPECIAL_SLICE_AND_DICE));
    }

    if (root == BONK_WEAPON_HUNTERS_MARK && m_mastery.Special(BONK_SPECIAL_RAPID_FIRE) > 0.0f)
        ApplyTimedAura(BONK_SPELL_RAPID_FIRE, BONK_RAPID_FIRE_MS, m_mastery.Special(BONK_SPECIAL_RAPID_FIRE));

    if (root == BONK_WEAPON_THUNDER_CLAP && m_mastery.Special(BONK_SPECIAL_THUNDERLORD) > 0.0f)
    {
        PendingCast again;
        again.weaponId = owned.weapon.id;
        again.spellId = owned.weapon.spellId;
        again.leftMs = BONK_THUNDERLORD_DELAY_MS;
        again.selfArea = true;
        m_pendingCasts.push_back(again);
    }

    if (root == BONK_WEAPON_FROSTBOLT)
    {
        m_fingersReady = roll_chance_f(m_mastery.Special(BONK_SPECIAL_FINGERS_OF_FROST));
        if (roll_chance_f(m_mastery.Special(BONK_SPECIAL_SPLINTERING_COLD)))
            owned.timer = std::min<int32>(owned.timer, BONK_SPLINTER_DELAY_MS);
    }
}

float BonkRun::GetTalentHaste() const
{
    uint32 const now = m_totalMs;
    float haste = m_mastery.Special(BONK_SPECIAL_MONGOOSE_FURY) * float(m_mongooseStacks);
    if (m_player->HasAura(BONK_SPELL_RAPID_FIRE))
        haste += m_mastery.Special(BONK_SPECIAL_RAPID_FIRE);
    if (m_player->HasAura(BONK_SPELL_SLICE_AND_DICE))
        haste += m_mastery.Special(BONK_SPECIAL_SLICE_AND_DICE);
    if (m_player->HasAura(BONK_SPELL_BORROWED_TIME))
        haste += m_mastery.Special(BONK_SPECIAL_BORROWED_TIME);
    if (m_player->HasAura(BONK_SPELL_FLURRY))
        haste += m_mastery.Special(BONK_SPECIAL_FLURRY);
    if (m_player->HasAura(BONK_SPELL_LIFEBLOOM_HASTE))
        haste += BONK_BLOOM_HASTE;
    haste += m_mastery.Special(BONK_SPECIAL_UNRELENTING_STORM) * CountTimedStacks(m_unrelentingUntil, now);
    haste += m_mastery.Special(BONK_SPECIAL_HARVESTER_OF_SOULS) * CountTimedStacks(m_harvestUntil, now);
    haste += m_mastery.Special(BONK_SPECIAL_STARLORD) * CountTimedStacks(m_starlordUntil, now);
    haste += m_mastery.Special(BONK_SPECIAL_SOUL_OF_THE_FOREST) * CountTimedStacks(m_forestUntil, now);
    for (auto const& itr : m_castHasteUntil)
    {
        auto value = m_mastery.castHaste.find(itr.first);
        if (value != m_mastery.castHaste.end())
            haste += value->second * float(std::count_if(itr.second.begin(), itr.second.end(), [now](uint32 until) { return until > now; }));
    }
    return haste;
}

void BonkRun::OnTalentPetStrike(OwnedWeapon const& owned, Creature* pet, Creature* prey, SpellEntry const* abilityInfo, int32 damage)
{
    if (GetRootWeapon(owned.weapon) != BONK_WEAPON_CALL_PET || !prey->IsAlive())
        return;
    if (m_mastery.Special(BONK_SPECIAL_INTIMIDATION) > 0.0f)
        m_pendingStuns.push_back(prey->GetObjectGuid());
    float const cleave = m_mastery.Special(BONK_SPECIAL_BEAST_CLEAVE);
    if (cleave > 0.0f && abilityInfo)
        for (Creature* mob : GetMobsNear(prey->GetPositionX(), prey->GetPositionY(), BONK_BEAST_CLEAVE_RADIUS))
            if (mob != prey)
                DealSpellHit(abilityInfo, mob, damage * cleave / 100.0f, pet);
}

float BonkRun::GetClawRate(OwnedWeapon const& owned) const
{
    if (GetRootWeapon(owned.weapon) != BONK_WEAPON_CALL_PET)
        return 1.0f;
    return 1.0f / (1.0f + m_mastery.Special(BONK_SPECIAL_CLAW_HASTE) / 100.0f);
}

uint32 BonkRun::CountLivingPets() const
{
    uint32 count = 0;
    Map* map = m_player->GetMap();
    for (OwnedWeapon const& owned : m_weapons)
        for (ObjectGuid const& guid : owned.pets)
            if (Creature* pet = map->GetCreature(guid))
                if (pet->IsAlive())
                    ++count;
    return count;
}

void BonkRun::OnTalentHowl(Creature* wolf)
{
    float const slow = m_mastery.Special(BONK_SPECIAL_INTIMIDATING_ROAR);
    if (slow <= 0.0f)
        return;
    for (Creature* mob : GetMobsNear(wolf->GetPositionX(), wolf->GetPositionY(), BONK_INTIMIDATING_ROAR_RADIUS))
        if (BonkMobAI const* ai = GetRunAI(mob))
            if (ai->GetKind() == BONK_SPAWN_NORMAL)
                m_pendingSlows.emplace_back(mob->GetObjectGuid(), slow);
}

void BonkRun::UpdateTalents(uint32 diff)
{
    ReleaseGlacialShatters();
    bool const mongoose = m_mastery.Special(BONK_SPECIAL_MONGOOSE_FURY) > 0.0f;
    bool const bulwark = m_mastery.Special(BONK_SPECIAL_BULWARK) > 0.0f;
    bool const madness = m_mastery.Special(BONK_SPECIAL_ANCIENT_MADNESS) > 0.0f;
    bool const bloodtalons = m_mastery.Special(BONK_SPECIAL_BLOODTALONS) > 0.0f;
    if (!mongoose && !bulwark && !madness && !bloodtalons)
        return;
    m_mongooseTimer -= int32(diff);
    if (m_mongooseTimer > 0)
        return;
    m_mongooseTimer = BONK_MONGOOSE_REFRESH_MS;
    std::vector<Creature*> const around = GetMobsInRange(BONK_MONGOOSE_RADIUS);
    uint32 poisoned = 0;
    uint32 bleeding = 0;
    for (Creature* mob : around)
    {
        if (GetKeywordStacks(mob, BONK_KEYWORD_POISON))
            ++poisoned;
        if (GetKeywordStacks(mob, BONK_KEYWORD_BLEED))
            ++bleeding;
    }
    m_bloodtalonsStacks = bloodtalons ? std::min(bleeding, BONK_BLOODTALONS_MAX_STACKS) : 0;
    m_mongooseStacks = mongoose ? std::min(poisoned, BONK_MONGOOSE_MAX_STACKS) : 0;
    m_bulwarkStacks = bulwark ? std::min(uint32(around.size()), BONK_BULWARK_MAX_STACKS) : 0;
    uint32 decaying = 0;
    if (madness)
        for (Creature* mob : GetMobsInRange(BONK_ANCIENT_MADNESS_RADIUS))
            if (GetKeywordStacks(mob, BONK_KEYWORD_DECAY))
                ++decaying;
    m_madnessStacks = std::min(decaying, BONK_ANCIENT_MADNESS_MAX_STACKS);
}

bool BonkRun::IsFreshMeat(SpellEntry const* spell, Unit const* victim) const
{
    float const threshold = m_mastery.Special(BONK_SPECIAL_FRESH_MEAT);
    if (threshold <= 0.0f || !spell || !victim || victim->GetHealthPercent() <= threshold)
        return false;
    auto root = m_spellRoots.find(spell->Id);
    return root != m_spellRoots.end() && root->second == BONK_WEAPON_BLOODTHIRST;
}

void BonkRun::OnTalentBleedingDeath()
{
    if (m_mastery.Special(BONK_SPECIAL_BLOODSURGE) <= 0.0f)
        return;
    uint32 const now = m_totalMs;
    m_bloodsurgeUntil.erase(std::remove_if(m_bloodsurgeUntil.begin(), m_bloodsurgeUntil.end(), [now](uint32 until) { return until <= now; }),
        m_bloodsurgeUntil.end());
    m_bloodsurgeUntil.push_back(now + BONK_BLOODSURGE_MS);
    if (m_bloodsurgeUntil.size() > BONK_BLOODSURGE_STACKS)
        m_bloodsurgeUntil.erase(m_bloodsurgeUntil.begin());
}

float BonkRun::GetTalentMoveSpeed() const
{
    return IsEnraged() ? m_mastery.Special(BONK_SPECIAL_FRENZY) * m_mastery.EnrageBoost() : 0.0f;
}

float BonkRun::GetTormentBonus(uint32 rootWeapon, Unit const* victim) const
{
    float const overpower = m_mastery.Special(BONK_SPECIAL_OVERPOWER);
    if (overpower > 0.0f && victim && rootWeapon == BONK_WEAPON_MORTAL_STRIKE && GetKeywordStacks(victim, BONK_KEYWORD_BLEED) >= BONK_OVERPOWER_BLEED)
        return overpower;
    float const bonus = m_mastery.Special(BONK_SPECIAL_TORMENT_THE_WEAK);
    if (bonus <= 0.0f || !victim || BonkMastery::GetSpec(rootWeapon) != BONK_TREE_ARCANE)
        return 0.0f;
    return victim->HasAuraType(SPELL_AURA_MOD_DECREASE_SPEED) || GetKeywordStacks(victim, BONK_KEYWORD_CHILL) ? bonus : 0.0f;
}

void BonkRun::ReduceTimer(uint32 rootWeapon, int32 ms)
{
    for (OwnedWeapon& owned : m_weapons)
        if (GetRootWeapon(owned.weapon) == rootWeapon)
        {
            owned.timer = std::max<int32>(std::min<int32>(owned.timer, BONK_CLEARCAST_FLOOR_MS), owned.timer - ms);
            owned.pieResync = true;
        }
}

void BonkRun::OnTalentDamage(Unit* victim, SpellEntry const* spell)
{
    bool const crit = m_crits != m_talentCritsSeen;
    m_talentCritsSeen = m_crits;
    if (!spell || !victim || m_state != STATE_RUNNING)
        return;
    auto rootItr = m_spellRoots.find(spell->Id);
    if (rootItr == m_spellRoots.end())
        return;
    uint32 const root = rootItr->second;
    OnSpecNodeDamage(root, crit, victim, spell);
    OnHunterDamage(root, victim);

    if (crit && BonkMastery::GetSpec(root) == BONK_TREE_FIRE)
    {
        int32 const kindling = int32(m_mastery.Special(BONK_SPECIAL_KINDLING) * IN_MILLISECONDS);
        if (kindling > 0)
            ReduceTimer(BONK_WEAPON_PYROBLAST, kindling);
        int32 const flamestrike = int32(m_mastery.Special(BONK_SPECIAL_KINDLING_FLAMESTRIKE) * IN_MILLISECONDS);
        if (flamestrike > 0)
            ReduceTimer(BONK_WEAPON_FLAMESTRIKE, flamestrike);
    }

    float const backlash = m_mastery.Special(BONK_SPECIAL_BACKLASH);
    if (crit && backlash > 0.0f)
        ReduceTimer(BONK_WEAPON_RAIN_OF_FIRE, int32(backlash * IN_MILLISECONDS));
    if (root == BONK_WEAPON_SHADOW_BOLT)
    {
        Creature* mob = victim->ToCreature();
        if (mob && mob->IsAlive() && crit && m_mastery.Special(BONK_SPECIAL_IMPROVED_SHADOW_BOLT) > 0.0f)
            ApplyKeyword(mob, BONK_KEYWORD_SHADOW_VULNERABILITY, 1, 0, 1.0f, spell->Id);
        if (mob && mob->IsAlive() && m_mastery.Special(BONK_SPECIAL_SOUL_FIRE) > 0.0f && ++m_shadowBoltHits % BONK_SOUL_FIRE_EVERY == 0)
            ApplyKeyword(mob, BONK_KEYWORD_BURNING, BONK_SOUL_FIRE_BURNING, 0, 1.0f, spell->Id);
    }

    if (root == BONK_WEAPON_PENANCE && m_mastery.Special(BONK_SPECIAL_SCHISM) > 0.0f)
        ApplyTimedAuraTo(victim, BONK_SPELL_SCHISM, BONK_SCHISM_MS, ADD_AURA_NEGATIVE);

    if (root == BONK_WEAPON_FIRE_BLAST)
    {
        if (crit && m_searingBurstArmed)
        {
            m_searingBurstArmed = false;
            ReduceTimer(BONK_WEAPON_PYROBLAST, BONK_INSTANT_RECHARGE_MS);
        }
        uint32 const spread = uint32(m_mastery.Special(BONK_SPECIAL_CONFLAGRATION));
        Creature* source = victim->ToCreature();
        uint32 const burning = source ? GetKeywordStacks(source, BONK_KEYWORD_BURNING) : 0;
        if (spread && burning)
        {
            uint32 given = 0;
            for (Creature* mob : GetMobsNear(source->GetPositionX(), source->GetPositionY(), BONK_CONFLAGRATION_RADIUS))
                if (mob != source && given < spread && ApplyKeyword(mob, BONK_KEYWORD_BURNING, burning, 0, 1.0f, spell->Id))
                    ++given;
        }
    }

    if (root == BONK_WEAPON_FROSTBOLT)
        m_fingersReady = false;

    if (crit && ((root == BONK_WEAPON_JUDGEMENT && m_mastery.Special(BONK_SPECIAL_RIGHTEOUS_VERDICT) > 0.0f) ||
        (root == BONK_WEAPON_DIVINE_STORM && m_mastery.Special(BONK_SPECIAL_FINAL_RECKONING) > 0.0f)))
        ReduceTimer(BONK_WEAPON_AVENGERS_SHIELD_PALADIN, BONK_INSTANT_RECHARGE_MS);
    if (root == BONK_WEAPON_SEAL_COMMAND && roll_chance_f(m_mastery.Special(BONK_SPECIAL_EMPYREAN_POWER)))
        ReduceTimer(BONK_WEAPON_DIVINE_STORM, BONK_INSTANT_RECHARGE_MS);
}

void BonkRun::OnTalentWindfury()
{
    if (m_mastery.Special(BONK_SPECIAL_FLURRY) > 0.0f)
        ApplyTimedAura(BONK_SPELL_FLURRY, BONK_FLURRY_MS, m_mastery.Special(BONK_SPECIAL_FLURRY));
    if (m_mastery.Special(BONK_SPECIAL_FORCEFUL_WINDS) > 0.0f)
        PushTimedStack(m_forcefulUntil, m_totalMs, BONK_FORCEFUL_WINDS_MS, BONK_FORCEFUL_WINDS_STACKS);
}

void BonkRun::OnTalentHarvestSoul()
{
    if (m_mastery.Special(BONK_SPECIAL_HARVESTER_OF_SOULS) > 0.0f)
        PushTimedStack(m_harvestUntil, m_totalMs, BONK_HARVESTER_MS, BONK_HARVESTER_STACKS);
}

void BonkRun::OnTalentStaticDischarge()
{
    if (m_mastery.Special(BONK_SPECIAL_UNRELENTING_STORM) > 0.0f)
        PushTimedStack(m_unrelentingUntil, m_totalMs, BONK_UNRELENTING_STORM_MS, BONK_UNRELENTING_STORM_STACKS);
}

bool BonkRun::IsNearOwnTotem() const
{
    Map* map = m_player->GetMap();
    for (OwnedWeapon const& owned : m_weapons)
        if (owned.weapon.HasFlag(BONK_WEAPON_FLAG_TOTEM))
            for (ObjectGuid const& guid : owned.pets)
                if (Creature* totem = map->GetCreature(guid))
                    if (totem->IsAlive() && m_player->IsWithinDistInMap(totem, BONK_CALL_OF_THE_ELEMENTS_RANGE))
                        return true;
    return false;
}

void BonkRun::OnDanseMacabre()
{
    if (m_mastery.Special(BONK_SPECIAL_DANSE_MACABRE) <= 0.0f)
        return;
    uint32 const now = m_totalMs;
    m_danseUntil.erase(std::remove_if(m_danseUntil.begin(), m_danseUntil.end(), [now](uint32 until) { return until <= now; }), m_danseUntil.end());
    m_danseUntil.push_back(now + BONK_DANSE_MACABRE_MS);
    if (m_danseUntil.size() > BONK_DANSE_MACABRE_STACKS)
        m_danseUntil.erase(m_danseUntil.begin());
}

void BonkRun::OnTalentKill(Unit* victim)
{
    float const share = m_mastery.Special(BONK_SPECIAL_GLACIAL_FRAGMENTS);
    Creature* dead = victim ? victim->ToCreature() : nullptr;
    OnSpecNodeKill(dead);
    float const venomRush = m_mastery.Special(BONK_SPECIAL_VENOM_RUSH);
    if (venomRush > 0.0f && dead && GetKeywordStacks(dead, BONK_KEYWORD_POISON))
        ReduceTimer(BONK_WEAPON_ENVENOM, int32(venomRush * IN_MILLISECONDS));
    if (dead && m_mastery.Special(BONK_SPECIAL_SOUL_OF_THE_FOREST) > 0.0f && dead->HasAuraType(SPELL_AURA_MOD_ROOT))
        PushTimedStack(m_forestUntil, m_totalMs, BONK_SOUL_OF_THE_FOREST_MS, BONK_SOUL_OF_THE_FOREST_STACKS);
    float const deepening = m_mastery.Special(BONK_SPECIAL_DEEPENING_SHADOWS);
    if (deepening > 0.0f && m_player->HasAura(BONK_SPELL_SHADOW_DANCE_AURA))
        ReduceTimer(BONK_WEAPON_SHADOW_DANCE, int32(deepening * IN_MILLISECONDS));
    if (share <= 0.0f || !dead || !IsFrozen(dead))
        return;
    GlacialShatter shatter;
    shatter.dead = dead->GetObjectGuid();
    shatter.x = dead->GetPositionX();
    shatter.y = dead->GetPositionY();
    shatter.damage = GetTrueAmount(dead, dead->GetMaxHealth()) * share / 100.0f;
    m_glacialShatters.push_back(shatter);
}

void BonkRun::ReleaseGlacialShatters()
{
    if (m_glacialShatters.empty())
        return;
    std::vector<GlacialShatter> shatters;
    shatters.swap(m_glacialShatters);
    SpellEntry const* shards = sSpellMgr.GetSpellEntry(BONK_SPELL_GLACIAL_FRAGMENTS);
    if (!shards || m_state != STATE_RUNNING)
        return;
    uint32 const chill = uint32(m_mastery.Special(BONK_SPECIAL_GLACIAL_FRAGMENTS_CHILL));
    FiringWeapon firing(m_player->GetBonkPlayer());
    for (GlacialShatter const& shatter : shatters)
        for (Creature* mob : GetMobsNear(shatter.x, shatter.y, BONK_GLACIAL_FRAGMENTS_RADIUS))
            if (mob->GetObjectGuid() != shatter.dead && mob->IsAlive())
            {
                DealSpellHit(shards, mob, shatter.damage);
                if (chill && mob->IsAlive())
                    ApplyKeyword(mob, BONK_KEYWORD_CHILL, chill, 0, 1.0f, shards->Id);
            }
}

void BonkRun::BlowFreezingWinds(PendingCast const& cast)
{
    OwnedWeapon const* owned = FindOwned(cast.weaponId);
    if (!owned)
        return;
    float const radius = owned->weapon.groundRadius * GetWeaponArea(*owned);
    for (Creature* mob : GetMobsNear(cast.x, cast.y, radius))
        if (BonkMobAI const* ai = GetRunAI(mob))
            if (ai->GetKind() == BONK_SPAWN_NORMAL)
                ApplyKeyword(mob, BONK_KEYWORD_FROZEN, 1, 0, 1.0f, cast.spellId);
}

void BonkRun::EchoMissile(OwnedWeapon& owned, SpellEntry const* spellInfo, Creature* target, float share)
{
    uint32 const extra = uint32(m_mastery.Special(BONK_SPECIAL_ARCANE_ECHO));
    uint32 struck = 0;
    for (Creature* mob : GetMobsNear(target->GetPositionX(), target->GetPositionY(), BONK_ARCANE_ECHO_RADIUS))
        if (mob != target && struck < extra)
        {
            StrikeWith(owned, spellInfo, mob, share, true);
            ++struck;
        }
}

void BonkRun::OnTalentBlink()
{
    float const potency = m_mastery.Special(BONK_SPECIAL_ARCANE_POTENCY);
    if (potency > 0.0f)
    {
        m_potencyCasts = BONK_ARCANE_POTENCY_CASTS + uint32(m_mastery.Special(BONK_SPECIAL_ARCANE_POTENCY_LONG));
        SyncStackAura(BONK_SPELL_ARCANE_POTENCY, m_potencyCasts);
    }

    int32 const flux = int32(m_mastery.Special(BONK_SPECIAL_TEMPORAL_FLUX) * IN_MILLISECONDS);
    if (flux > 0)
        for (OwnedWeapon& owned : m_weapons)
        {
            owned.timer = std::max<int32>(std::min<int32>(owned.timer, BONK_CLEARCAST_FLOOR_MS), owned.timer - flux);
            owned.pieResync = true;
        }

    if (m_mastery.blinkShield > 0.0f)
    {
        SupportScope scope(*this, TalentSupport(BONK_MASTERY_BLINK_SHIELD));
        AddSpellShield(uint32(m_player->GetMaxHealth() * m_mastery.blinkShield / 100.0f));
    }

}

bool BonkRun::IsTalentBlinkDash() const
{
    return m_mastery.Has(BONK_CAPSTONE_ARCANE_SURGE);
}

float BonkRun::GetDashRechargeRate() const
{
    float rate = GetBlinkRechargeRate() * (1.0f + m_mastery.dashRecharge / 100.0f);
    if (m_mastery.Has(BONK_CAPSTONE_ARCANE_SURGE))
        rate *= BONK_ARCANE_SURGE_RECHARGE;
    if (m_mastery.Has(BONK_CAPSTONE_TRAPMASTER))
        rate *= BONK_TRAPMASTER_DASH_RECHARGE;
    return rate;
}

float BonkRun::GetTrapTalentDuration(OwnedWeapon const& owned) const
{
    return owned.weapon.behavior == BONK_BEHAVIOR_TRAP ? m_mastery.trapDuration : 0.0f;
}

void BonkRun::SpringEntrapment(OwnedWeapon const& owned, float x, float y, float radius)
{
    if (!m_mastery.entrapment.count(GetRootWeapon(owned.weapon)))
        return;
    Map* map = m_player->GetMap();
    for (ObjectGuid const& guid : GetEnemyGuids())
        if (Creature* mob = map->GetCreature(guid))
        {
            BonkMobAI const* ai = GetRunAI(mob);
            if (ai && ai->GetKind() == BONK_SPAWN_NORMAL && mob->IsAlive() && mob->GetDistance2d(x, y) <= radius)
                ApplyKeyword(mob, BONK_KEYWORD_FROZEN, 1, 0, 1.0f, owned.weapon.spellId);
        }
}

void BonkRun::PreferMarked(std::vector<Creature*>& mobs) const
{
    if (!m_mastery.Has(BONK_CAPSTONE_TRUESHOT))
        return;
    std::stable_partition(mobs.begin(), mobs.end(), [this](Creature* mob) { return GetKeywordStacks(mob, BONK_KEYWORD_HUNTERS_MARK) != 0; });
}

float BonkRun::GetPackPowerShare() const
{
    if (HasBehavior(BONK_BEHAVIOR_WRATH))
        return m_mastery.packPower / 100.0f;
    return m_mastery.packPower * m_mastery.Special(BONK_SPECIAL_KINDRED_SPIRITS) / 10000.0f;
}

bool BonkRun::IsPetFrenzied() const
{
    return IsHowlFrenzied() || m_mastery.Has(BONK_CAPSTONE_BESTIAL_WRATH);
}

float BonkRun::GetBestialWrathFrenzy() const
{
    return BONK_BESTIAL_WRATH_FRENZY;
}

float BonkRun::GetBestialWrathHowl() const
{
    return BONK_BESTIAL_WRATH_HOWL;
}

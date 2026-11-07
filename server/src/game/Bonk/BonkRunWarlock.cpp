#include "BonkRun.h"
#include "Creature.h"
#include "Map.h"
#include "Player.h"
#include "SpellAuras.h"
#include "SpellMgr.h"

#include <algorithm>

namespace
{
    uint32 const BONK_DRAIN_HEALED_BEAMS      = 2;
    float const BONK_DRAINED_DOT_SCALE        = 1.2f;
    uint32 const BONK_SHADOW_BOLT_AGONY       = 1;
    uint32 const BONK_WEAPON_CURSE_OF_AGONY   = 905;
    uint32 const BONK_WEAPON_IMP              = 900;
    uint32 const BONK_WEAPON_VOIDWALKER       = 901;
    uint32 const BONK_WEAPON_SUCCUBUS         = 902;
    uint32 const BONK_WEAPON_FELHUNTER        = 903;

    uint32 const BONK_SPELL_DRAIN_BEAM        = 755;
    uint32 const BONK_SPELL_IMP_FIREBOLT      = 11763;
    uint32 const BONK_SPELL_FEL_FIREBOLT      = 33500;
    uint32 const BONK_FEL_IMP_DISPLAY         = 18900;
    uint32 const BONK_SPELL_CONSUME_SHADOWS   = 1112;
    uint32 const BONK_SPELL_SPELL_LOCK        = 19244;
    uint32 const BONK_SPELL_DEVOUR_MAGIC      = 17012;

    uint32 const BONK_NIGHTFALL_PER_SEC       = 1;
    uint32 const BONK_RUIN_NIGHTFALL_PER_SEC  = 3;
    float const BONK_RUIN_NIGHTFALL_DAMAGE    = 1.5f;
    uint32 const BONK_WARLOCK_OPENING_STACKS  = 1;
    uint32 const BONK_NIGHTFALL_WINDOW_MS     = 1000;
    float const BONK_CONSUME_RADIUS           = 10.0f;
    uint32 const BONK_CONSUME_STACKS          = 8;
    float const BONK_CONSUME_GROWTH           = 0.05f;
    float const BONK_CONSUME_BURST_RADIUS     = 10.0f;
    float const BONK_CONSUME_BURST_BITES      = 1.2f;
    uint32 const BONK_DEVOUR_EVERY_MS         = 10000;
    uint32 const BONK_SPELL_LOCK_EVERY_MS     = 6000;
    uint32 const BONK_IMP_VOLLEY_BOLTS        = 2;
    uint32 const BONK_IMP_VOLLEY_GAP_MS       = 300;
    float const BONK_SHADOW_BITE_PER_AFFLICTION = 0.1f;
    int32 const BONK_WARLOCK_POLL_MS          = 250;
    int32 const BONK_EXHAUSTION_SLOW          = -30;
    int32 const BONK_EXHAUSTION_SLOW_MS       = 2000;

    BonkKeyword const BONK_WARLOCK_AFFLICTIONS[] = { BONK_KEYWORD_DECAY, BONK_KEYWORD_AGONY, BONK_KEYWORD_BURNING };
}

uint32 BonkRun::GetWarlockPetFamily(OwnedWeapon const& owned) const
{
    switch (GetRootWeapon(owned.weapon))
    {
        case BONK_WEAPON_IMP:        return BONK_PET_FAMILY_IMP;
        case BONK_WEAPON_VOIDWALKER: return BONK_PET_FAMILY_VOIDWALKER;
        case BONK_WEAPON_SUCCUBUS:   return BONK_PET_FAMILY_SUCCUBUS;
        case BONK_WEAPON_FELHUNTER:  return BONK_PET_FAMILY_FELHUNTER;
        default:                     return 0;
    }
}

bool BonkRun::IsCasterPetFamily(BonkPetFamily const& family) const
{
    return family.id == BONK_PET_FAMILY_IMP;
}

bool BonkRun::FireWarlockSpell(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    switch (owned.weapon.behavior)
    {
        case BONK_BEHAVIOR_CORRUPTION:     SpreadCorruption(owned, spellInfo); break;
        case BONK_BEHAVIOR_CURSE_OF_AGONY: CurseWithAgony(owned, spellInfo); break;
        case BONK_BEHAVIOR_DRAIN_LIFE:     DrainLife(owned, spellInfo); break;
        case BONK_BEHAVIOR_HELLFIRE:       BurnHellfire(owned, spellInfo); break;
        default:                           return false;
    }
    return true;
}

uint32 BonkRun::GetWarlockAbilitySpell(OwnedWeapon const& owned, uint32 spellId) const
{
    bool const felImp = spellId == BONK_SPELL_IMP_FIREBOLT && owned.weapon.evolvesFrom && GetWarlockPetFamily(owned) == BONK_PET_FAMILY_IMP;
    return felImp ? BONK_SPELL_FEL_FIREBOLT : spellId;
}

void BonkRun::DressWarlockPet(OwnedWeapon const& owned, Creature* pet) const
{
    if (!owned.weapon.evolvesFrom || GetWarlockPetFamily(owned) != BONK_PET_FAMILY_IMP)
        return;
    pet->SetDisplayId(BONK_FEL_IMP_DISPLAY);
    pet->SetNativeDisplayId(BONK_FEL_IMP_DISPLAY);
}

void BonkRun::AddWarlockStacks(OwnedWeapon const& owned, SpellEntry const* spellInfo, std::vector<Creature*> mobs, BonkKeyword keyword, bool openingStacks)
{
    uint32 const wanted = GetWeaponTargets(owned);
    std::stable_partition(mobs.begin(), mobs.end(), [this, keyword](Creature* mob) { return !GetKeywordStacks(mob, keyword); });
    if (mobs.size() > wanted)
        mobs.resize(wanted);
    BonkKeywordInfo const* info = sBonkMgr.GetKeyword(keyword);
    if (!info)
        return;
    uint32 const stacks = owned.weapon.applyStacks + uint32(GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_STACKS));
    uint32 const durationMs = uint32(info->durationMs * GetWeaponDurationScale(owned));
    float const strength = (1.0f + owned.damageBonus / 100.0f) * std::max(1.0f, owned.weapon.damageFraction);
    for (Creature* mob : mobs)
    {
        ShowStrike(m_player, spellInfo, mob);
        uint32 const opening = openingStacks && !GetKeywordStacks(mob, keyword) ? BONK_WARLOCK_OPENING_STACKS : 0;
        ApplyKeyword(mob, keyword, stacks + opening, durationMs, strength, owned.weapon.spellId);
        if (keyword == BONK_KEYWORD_DECAY && m_mastery.Special(BONK_SPECIAL_CONTAGION) > 0.0f)
            ApplyKeyword(mob, BONK_KEYWORD_AGONY, uint32(m_mastery.Special(BONK_SPECIAL_CONTAGION)), 0, strength, owned.weapon.spellId);
        if (keyword == BONK_KEYWORD_AGONY)
        {
            OnAgonyCurse(owned, mob);
            if (m_mastery.Special(BONK_SPECIAL_CURSE_OF_EXHAUSTION) > 0.0f)
                SlowNormalMob(mob, spellInfo, &BONK_EXHAUSTION_SLOW, BONK_EXHAUSTION_SLOW_MS);
        }
    }
}

void BonkRun::SpreadCorruption(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    std::vector<Creature*> const mobs = GetMobsInRange(GetStrikeRange(owned));
    if (mobs.empty())
    {
        owned.timer = BONK_WARLOCK_POLL_MS;
        return;
    }
    owned.timer = GetWeaponCooldown(owned);
    AddWarlockStacks(owned, spellInfo, mobs, BONK_KEYWORD_DECAY);
}

void BonkRun::CurseWithAgony(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    std::vector<Creature*> mobs = GetMobsInRange(GetStrikeRange(owned));
    if (mobs.empty())
    {
        owned.timer = BONK_WARLOCK_POLL_MS;
        return;
    }
    std::stable_sort(mobs.begin(), mobs.end(), [](Creature* a, Creature* b) { return a->GetHealth() > b->GetHealth(); });
    owned.timer = GetWeaponCooldown(owned);
    AddWarlockStacks(owned, spellInfo, mobs, BONK_KEYWORD_AGONY);
}

void BonkRun::LatchDrainBeam(Creature* mob)
{
    mob->SetChannelObjectGuid(m_player->GetObjectGuid());
    mob->SetUInt32Value(UNIT_CHANNEL_SPELL, BONK_SPELL_DRAIN_BEAM);
    m_drainBeams.push_back(mob->GetObjectGuid());
}

void BonkRun::ReleaseDrainBeam(ObjectGuid const& guid)
{
    if (Creature* mob = m_player->GetMap()->GetCreature(guid))
        if (mob->GetUInt32Value(UNIT_CHANNEL_SPELL) == BONK_SPELL_DRAIN_BEAM)
            mob->CancelSpellChannelingAnimationInstantly();
}

void BonkRun::ReleaseDrainBeams()
{
    if (!m_player->IsInWorld())
    {
        m_drainBeams.clear();
        return;
    }
    for (ObjectGuid const& guid : m_drainBeams)
        ReleaseDrainBeam(guid);
    m_drainBeams.clear();
}

void BonkRun::DrainLife(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    SupportScope scope(*this, WeaponSupport(owned));
    Map* map = m_player->GetMap();
    uint32 const wanted = owned.weapon.baseTargets + GetSpellCount(owned);
    std::vector<ObjectGuid> closest;
    for (Creature* mob : GetMobsInRange(GetStrikeRange(owned)))
    {
        if (closest.size() >= wanted)
            break;
        if (m_player->IsWithinLOSInMap(mob))
            closest.push_back(mob->GetObjectGuid());
    }
    m_drainBeams.erase(std::remove_if(m_drainBeams.begin(), m_drainBeams.end(), [this, &closest](ObjectGuid const& guid)
    {
        if (std::find(closest.begin(), closest.end(), guid) != closest.end())
            return false;
        ReleaseDrainBeam(guid);
        return true;
    }), m_drainBeams.end());
    for (ObjectGuid const& guid : closest)
        if (std::find(m_drainBeams.begin(), m_drainBeams.end(), guid) == m_drainBeams.end())
            if (Creature* mob = map->GetCreature(guid))
                LatchDrainBeam(mob);
    if (m_drainBeams.empty())
    {
        owned.timer = BONK_WARLOCK_POLL_MS;
        return;
    }

    owned.timer = GetWeaponCooldown(owned);
    uint32 drained = 0;
    for (ObjectGuid const& guid : m_drainBeams)
        if (Creature* mob = map->GetCreature(guid))
        {
            DealShamanHit(spellInfo, owned.weapon.spellId, mob, GetWeaponDamage(owned));
            ++drained;
        }
    if (drained && owned.weapon.healPct > 0.0f && m_player->IsAlive())
    {
        uint32 const heal = std::max(1u, uint32(m_player->GetMaxHealth() * owned.weapon.healPct * std::min(drained, BONK_DRAIN_HEALED_BEAMS) / 100.0f));
        OnDrainOverheal(heal);
        HealHero(heal, owned.weapon.spellId);
    }
}

float BonkRun::GetDrainedDotScale(Unit const* victim, uint32 spellId) const
{
    BonkKeywordInfo const* info = sBonkMgr.GetKeywordBySpell(spellId);
    if (!info || (info->id != BONK_KEYWORD_DECAY && info->id != BONK_KEYWORD_AGONY))
        return 1.0f;
    return std::find(m_drainBeams.begin(), m_drainBeams.end(), victim->GetObjectGuid()) != m_drainBeams.end() ? BONK_DRAINED_DOT_SCALE : 1.0f;
}

void BonkRun::CurseFromShadowBolt(OwnedWeapon const& owned, Unit* victim)
{
    Creature* mob = victim->ToCreature();
    if (!mob || GetRootWeapon(owned.weapon) != BONK_WEAPON_SHADOW_BOLT || !GetKeywordStacks(mob, BONK_KEYWORD_AGONY))
        return;
    if (OwnedWeapon* curse = FindOwnedByRoot(BONK_WEAPON_CURSE_OF_AGONY))
        ApplyWeaponKeyword(*curse, mob, BONK_KEYWORD_AGONY, BONK_SHADOW_BOLT_AGONY);
}

void BonkRun::BurnHellfire(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    std::vector<Creature*> const mobs = GetMobsInRange(GetWeaponRadius(owned) * GetHellfireReach(owned));
    if (mobs.empty())
    {
        owned.timer = BONK_WARLOCK_POLL_MS;
        return;
    }
    owned.timer = GetWeaponCooldown(owned);
    ShowMissileFrom(m_player, spellInfo, m_player->GetPositionX(), m_player->GetPositionY(), m_player->GetPositionZ());
    ImmolateDemons(owned, spellInfo);
    for (Creature* mob : mobs)
    {
        DealShamanHit(spellInfo, owned.weapon.spellId, mob, GetWeaponDamage(owned));
        if (mob->IsAlive() && owned.weapon.applyStacks)
            ApplyWeaponKeyword(owned, mob, BonkKeyword(owned.weapon.applies), owned.weapon.applyStacks);
    }
}

void BonkRun::OnWarlockKill(Unit* victim)
{
    OnWarlockEvolvedKill(victim);
    bool const afflicted = std::any_of(std::begin(BONK_WARLOCK_AFFLICTIONS), std::end(BONK_WARLOCK_AFFLICTIONS),
        [this, victim](BonkKeyword keyword) { return GetKeywordStacks(victim, keyword) > 0; });
    if (afflicted && FindOwnedByRoot(BONK_WEAPON_SHADOW_BOLT))
        m_nightfallQueue.push_back(victim->GetObjectGuid());
    if (afflicted)
        OnTalentHarvestSoul();

    Creature* nearest = nullptr;
    for (OwnedWeapon& owned : m_weapons)
    {
        if (GetWarlockPetFamily(owned) != BONK_PET_FAMILY_VOIDWALKER)
            continue;
        for (ObjectGuid const& guid : owned.pets)
        {
            Creature* pet = m_player->GetMap()->GetCreature(guid);
            if (!pet || !pet->IsAlive() || !pet->IsWithinDistInMap(victim, BONK_CONSUME_RADIUS * GetSummonReach(owned)))
                continue;
            if (!nearest || pet->GetDistance(victim) < nearest->GetDistance(victim))
                nearest = pet;
        }
    }
    if (nearest)
    {
        uint32& stacks = m_consumedShadows[nearest->GetObjectGuid()];
        stacks = std::min(stacks + 1, GetConsumeStacks());
    }
}

BonkRun::OwnedWeapon* BonkRun::FindOwnedByRoot(uint32 rootId)
{
    for (OwnedWeapon& owned : m_weapons)
        if (GetRootWeapon(owned.weapon) == rootId)
            return &owned;
    return nullptr;
}

float BonkRun::GetConsumedGrowth(ObjectGuid const& pet) const
{
    auto itr = m_consumedShadows.find(pet);
    return itr == m_consumedShadows.end() ? 1.0f : 1.0f + BONK_CONSUME_GROWTH * itr->second;
}

void BonkRun::FireNightfall()
{
    if (m_nightfallQueue.empty())
        return;
    uint32 const now = WorldTimer::getMSTime();
    m_nightfallMs.erase(std::remove_if(m_nightfallMs.begin(), m_nightfallMs.end(),
        [now](uint32 at) { return now - at >= BONK_NIGHTFALL_WINDOW_MS; }), m_nightfallMs.end());

    OwnedWeapon* owned = FindOwnedByRoot(BONK_WEAPON_SHADOW_BOLT);
    SpellEntry const* spellInfo = owned ? sSpellMgr.GetSpellEntry(owned->weapon.spellId) : nullptr;
    bool const ruin = m_mastery.Has(BONK_CAPSTONE_RUIN);
    size_t const perSec = ruin ? BONK_RUIN_NIGHTFALL_PER_SEC : BONK_NIGHTFALL_PER_SEC;
    float const share = ruin ? BONK_RUIN_NIGHTFALL_DAMAGE : 1.0f;
    while (!m_nightfallQueue.empty() && spellInfo && m_nightfallMs.size() < perSec)
    {
        m_nightfallQueue.pop_front();
        std::vector<Creature*> const mobs = GetMobsInRange(GetStrikeRange(*owned));
        if (mobs.empty())
            break;
        StrikeWith(*owned, spellInfo, mobs.front(), share, true);
        OnNightfallBolt(*owned, spellInfo, mobs.front());
        m_nightfallMs.push_back(now);
    }
    m_nightfallQueue.clear();
}

void BonkRun::BurstConsumedShadows()
{
    SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(BONK_SPELL_CONSUME_SHADOWS);
    if (!spellInfo)
        return;
    for (OwnedWeapon& owned : m_weapons)
    {
        BonkPetFamily const* family = GetPetFamily(owned);
        if (!family || family->id != BONK_PET_FAMILY_VOIDWALKER)
            continue;
        for (ObjectGuid const& guid : owned.pets)
        {
            auto stacks = m_consumedShadows.find(guid);
            Creature* pet = m_player->GetMap()->GetCreature(guid);
            if (stacks == m_consumedShadows.end() || stacks->second < GetConsumeStacks() || !pet || !pet->IsAlive())
                continue;
            m_consumedShadows.erase(stacks);
            ShowStrike(pet, spellInfo, pet);
            OnConsumedBurst(owned);
            float const hit = GetPetBiteDamage(owned, *family) * BONK_CONSUME_BURST_BITES * (1.0f + m_mastery.Special(BONK_SPECIAL_FEL_SUNDER) / 100.0f);
            bool const stuns = m_mastery.Special(BONK_SPECIAL_SHADOWFURY) > 0.0f;
            for (Creature* mob : GetMobsNear(pet->GetPositionX(), pet->GetPositionY(), BONK_CONSUME_BURST_RADIUS * GetSummonReach(owned)))
                if (pet->IsWithinLOSInMap(mob))
                {
                    DealSpellHit(spellInfo, mob, std::max(1.0f, hit), pet);
                    if (stuns && mob->IsAlive())
                        m_pendingStuns.push_back(mob->GetObjectGuid());
                }
        }
    }
}

uint32 BonkRun::GetConsumeStacks() const
{
    uint32 const fewer = std::min(BONK_CONSUME_STACKS - 1, uint32(m_mastery.Special(BONK_SPECIAL_IMPROVED_VOIDWALKER)));
    return BONK_CONSUME_STACKS - fewer;
}

float BonkRun::GetWarlockPetStrikeScale(OwnedWeapon const& owned, Creature const* prey) const
{
    if (GetWarlockPetFamily(owned) != BONK_PET_FAMILY_FELHUNTER)
        return 1.0f;
    uint32 const afflictions = uint32(std::count_if(std::begin(BONK_WARLOCK_AFFLICTIONS), std::end(BONK_WARLOCK_AFFLICTIONS),
        [this, prey](BonkKeyword keyword) { return GetKeywordStacks(prey, keyword) > 0; }));
    return 1.0f + BONK_SHADOW_BITE_PER_AFFLICTION * afflictions;
}

void BonkRun::QueueImpVolley(OwnedWeapon const& owned, Creature* pet, Creature* prey, uint32 abilityIndex)
{
    BonkPetFamily const* family = GetPetFamily(owned);
    if (!family || abilityIndex >= family->abilities.size())
        return;
    std::vector<Creature*> others = GetMobsNear(pet->GetPositionX(), pet->GetPositionY(), family->abilities[abilityIndex].value);
    others.erase(std::remove(others.begin(), others.end(), prey), others.end());

    uint32 const now = WorldTimer::getMSTime();
    uint32 const bolts = BONK_IMP_VOLLEY_BOLTS + uint32(m_mastery.Special(BONK_SPECIAL_IMPROVED_IMP));
    for (uint32 bolt = 1; bolt < bolts; ++bolt)
    {
        Creature* target = bolt - 1 < others.size() ? others[bolt - 1] : prey;
        m_impVolleys.push_back({ pet->GetObjectGuid(), target->GetObjectGuid(), owned.weapon.id, abilityIndex, now + bolt * BONK_IMP_VOLLEY_GAP_MS });
    }
}

void BonkRun::FireImpVolleys()
{
    uint32 const now = WorldTimer::getMSTime();
    Map* map = m_player->GetMap();
    std::vector<ImpVolley> due;
    m_impVolleys.erase(std::remove_if(m_impVolleys.begin(), m_impVolleys.end(), [&due, now](ImpVolley const& volley)
    {
        if (int32(now - volley.atMs) < 0)
            return false;
        due.push_back(volley);
        return true;
    }), m_impVolleys.end());
    for (ImpVolley const& volley : due)
    {
        OwnedWeapon* owned = FindOwned(volley.weaponId);
        Creature* pet = map->GetCreature(volley.pet);
        Creature* prey = map->GetCreature(volley.prey);
        BonkPetFamily const* family = owned ? GetPetFamily(*owned) : nullptr;
        if (!family || volley.ability >= family->abilities.size() || !pet || !pet->IsAlive())
            continue;
        if (!prey || !prey->IsAlive())
        {
            std::vector<Creature*> const mobs = GetMobsNear(pet->GetPositionX(), pet->GetPositionY(), family->abilities[volley.ability].value);
            prey = mobs.empty() ? nullptr : mobs.front();
        }
        if (!prey)
            continue;
        PetStrike(*owned, pet, prey, family->abilities[volley.ability]);
        OnWarlockEvolvedPetStrike(*owned, pet, prey);
    }
}

void BonkRun::OnWarlockPetStrike(OwnedWeapon& owned, Creature* pet, Creature* prey, uint32 abilityIndex)
{
    OnWarlockEvolvedPetStrike(owned, pet, prey);
    if (GetWarlockPetFamily(owned) == BONK_PET_FAMILY_IMP)
    {
        QueueImpVolley(owned, pet, prey, abilityIndex);
        return;
    }
    if (GetWarlockPetFamily(owned) != BONK_PET_FAMILY_FELHUNTER || !prey->IsAlive() || !prey->IsNonMeleeSpellCasted(false))
        return;
    uint32 const now = WorldTimer::getMSTime();
    uint32& readyMs = m_spellLockReadyMs[pet->GetObjectGuid()];
    if (int32(now - readyMs) < 0)
        return;
    readyMs = now + BONK_SPELL_LOCK_EVERY_MS;
    prey->InterruptNonMeleeSpells(false);
    if (SpellEntry const* lock = sSpellMgr.GetSpellEntry(BONK_SPELL_SPELL_LOCK))
        ShowStrike(pet, lock, prey);
}

void BonkRun::DevourHarmfulEffect()
{
    Creature* felhunter = nullptr;
    for (OwnedWeapon& owned : m_weapons)
        if (GetWarlockPetFamily(owned) == BONK_PET_FAMILY_FELHUNTER)
            for (ObjectGuid const& guid : owned.pets)
                if (Creature* pet = m_player->GetMap()->GetCreature(guid))
                    if (pet->IsAlive())
                        felhunter = pet;
    if (!felhunter)
        return;

    for (auto const& itr : m_player->GetSpellAuraHolderMap())
    {
        SpellAuraHolder const* holder = itr.second;
        if (holder->IsPositive() || holder->IsPassive() || holder->GetCasterGuid() == m_player->GetObjectGuid())
            continue;
        m_player->RemoveAurasDueToSpell(holder->GetId());
        if (SpellEntry const* devour = sSpellMgr.GetSpellEntry(BONK_SPELL_DEVOUR_MAGIC))
            ShowStrike(felhunter, devour, m_player);
        return;
    }
}

void BonkRun::UpdateWarlock(uint32 diff)
{
    FireNightfall();
    BurstConsumedShadows();
    FireImpVolleys();
    UpdateWarlockEvolutions();

    if (!m_drainBeams.empty() && !std::any_of(m_weapons.begin(), m_weapons.end(),
        [](OwnedWeapon const& owned) { return owned.weapon.behavior == BONK_BEHAVIOR_DRAIN_LIFE; }))
        ReleaseDrainBeams();

    m_devourTimer += diff;
    if (m_devourTimer >= BONK_DEVOUR_EVERY_MS)
    {
        m_devourTimer = 0;
        DevourHarmfulEffect();
    }
}

#include "BonkRun.h"
#include "BonkMobAI.h"
#include "Creature.h"
#include "Map.h"
#include "Player.h"
#include "SpellAuras.h"
#include "SpellMgr.h"

#include <algorithm>

namespace
{
    uint32 const BONK_EMPOWERMENT_EVERY_MS     = 10000;
    uint32 const BONK_EMPOWERMENT_MS           = 4000;
    uint32 const BONK_WEAPON_FEL_IMPS            = 911;
    uint32 const BONK_WEAPON_IMP_SWARM           = 912;
    uint32 const BONK_WEAPON_SACRIFICE           = 913;
    uint32 const BONK_WEAPON_VOID_SLAM           = 914;
    uint32 const BONK_WEAPON_PAINFUL_LASH        = 915;
    uint32 const BONK_WEAPON_SEDUCTION           = 916;
    uint32 const BONK_WEAPON_SPELL_LOCK          = 917;
    uint32 const BONK_WEAPON_DEVOUR_AFFIX        = 918;
    uint32 const BONK_WEAPON_SEED_OF_CORRUPTION  = 919;
    uint32 const BONK_WEAPON_DARK_HARVEST        = 920;
    uint32 const BONK_WEAPON_CURSE_OF_DOOM       = 921;
    uint32 const BONK_WEAPON_AGONYS_ECHO         = 922;
    uint32 const BONK_WEAPON_DRAIN_SOUL          = 923;
    uint32 const BONK_WEAPON_DARK_PACT           = 924;
    uint32 const BONK_WEAPON_CHAOS_BOLT          = 925;
    uint32 const BONK_WEAPON_SHADOW_BARRAGE      = 926;
    uint32 const BONK_WEAPON_CONFLAGRATE         = 927;
    uint32 const BONK_WEAPON_SHADOWFLAME         = 928;
    uint32 const BONK_WEAPON_INFERNO             = 929;
    uint32 const BONK_WEAPON_DEMONIC_IMMOLATION  = 930;
    uint32 const BONK_WEAPON_SUMMON_INFERNAL     = 931;
    uint32 const BONK_WEAPON_RAIN_OF_CHAOS       = 932;

    uint32 const BONK_LESSER_IMP                 = 900141;
    uint32 const BONK_DOOMGUARD                  = 900145;
    uint32 const BONK_INFERNAL                   = 900146;

    uint32 const BONK_SPELL_CORRUPTION_LOOK      = 172;
    uint32 const BONK_SPELL_DOOM_LOOK            = 603;
    uint32 const BONK_SPELL_INFERNO_LOOK         = 22703;
    uint32 const BONK_SPELL_SOUL_LOOK            = 33461;
    uint32 const BONK_SPELL_VOID_SLAM_LOOK       = 1112;
    uint32 const BONK_SPELL_SEDUCTION_LOOK       = 6358;
    uint32 const BONK_SPELL_CHAOS_LOOK           = 33502;
    uint32 const BONK_SPELL_DEVOUR_LOOK          = 17012;

    float const BONK_FEL_IMPS_RADIUS             = 8.0f;
    uint32 const BONK_FEL_IMPS_JUMPS             = 2;
    float const BONK_FEL_IMPS_SHARE              = 0.6f;
    uint32 const BONK_IMP_PREY_MEMORY_MS         = 1500;
    uint32 const BONK_LESSER_IMP_LIFE_MS         = 6000;
    float const BONK_LESSER_IMP_SCALE            = 0.6f;
    float const BONK_LESSER_IMP_BITE             = 0.5f;
    uint32 const BONK_MAX_LESSER_IMPS            = 6;
    float const BONK_SACRIFICE_SHIELD_PCT        = 5.0f;
    uint32 const BONK_VOID_SLAM_EVERY_MS         = 6000;
    float const BONK_VOID_SLAM_RADIUS            = 8.0f;
    float const BONK_VOID_SLAM_BITES             = 1.2f;
    uint32 const BONK_SEDUCTION_EVERY_MS         = 8000;
    float const BONK_SEDUCTION_RANGE             = 20.0f;
    uint32 const BONK_SEDUCED_MS                 = 2000;
    float const BONK_SEDUCED_DAMAGE              = 2.0f;
    float const BONK_SPELL_LOCK_RADIUS           = 8.0f;
    uint32 const BONK_DEVOUR_AFFIX_MS            = 6000;
    uint32 const BONK_DEVOUR_AFFIX_EVERY_MS      = 10000;
    float const BONK_SEED_SHARE                  = 0.15f;
    uint32 const BONK_SEED_MAX_DEPTH             = 2;
    uint32 const BONK_SEED_HIT_GAP_MS            = 1000;
    uint32 const BONK_DARK_HARVEST_EVERY_MS      = 6000;
    float const BONK_DARK_HARVEST_TICKS          = 3.0f;
    uint32 const BONK_DOOM_DELAY_MS              = 10000;
    float const BONK_DOOM_MOB_HEALTHS            = 1.5f;
    uint32 const BONK_DOOMGUARD_LIFE_MS          = 15000;
    float const BONK_DOOMGUARD_SWING_HEALTHS     = 0.3f;
    uint32 const BONK_MINION_ATTACK_MS           = 1500;
    uint32 const BONK_MINION_MIN_ATTACK_MS       = 300;
    uint32 const BONK_SOUL_MS                    = 10000;
    uint32 const BONK_MAX_SOULS                  = 10;
    float const BONK_SOUL_DAMAGE                 = 0.05f;
    uint32 const BONK_DARK_PACT_MS               = 4000;
    float const BONK_DARK_PACT_DAMAGE            = 1.3f;
    float const BONK_DEMONOLOGIST_PER_DEMON      = 0.1f;
    uint32 const BONK_CHAOS_BOLT_EVERY           = 4;
    float const BONK_CHAOS_BOLT_SHARE            = 1.5f;
    uint32 const BONK_SHADOW_BARRAGE_JUMPS       = 2;
    float const BONK_SHADOW_BARRAGE_SHARE        = 0.5f;
    float const BONK_CONFLAGRATE_SHARE           = 0.5f;
    float const BONK_INFERNO_GROWTH              = 0.6f;
    float const BONK_DEMONIC_IMMOLATION_RADIUS   = 6.0f;
    float const BONK_DEMONIC_IMMOLATION_SHARE    = 0.5f;
    uint32 const BONK_INFERNAL_LIFE_MS           = 8000;
    float const BONK_INFERNAL_RADIUS             = 6.0f;
    float const BONK_INFERNAL_SHARE              = 2.0f;
    int32 const BONK_INFERNAL_STUN_MS            = 1000;
    float const BONK_INFERNAL_BITE               = 1.5f;
    uint32 const BONK_RAIN_OF_CHAOS_EXTRA        = 2;

    bool IsNormalMob(Creature const* mob)
    {
        BonkMobAI const* ai = mob ? dynamic_cast<BonkMobAI const*>(mob->AI()) : nullptr;
        return ai && ai->GetKind() == BONK_SPAWN_NORMAL;
    }
}

void BonkRun::SummonWarlockMinion(OwnedWeapon const& owned, uint32 entry, float x, float y, float z, uint32 lifeMs, float bite, float scale)
{
    Creature* minion = SummonPet(owned, entry, x, y, z, m_player->GetOrientation());
    if (!minion)
        return;
    minion->SetObjectScale(scale);
    minion->UpdateModelData();
    minion->SetHealth(minion->GetMaxHealth());
    minion->SetInvincibilityHpThreshold(minion->GetMaxHealth());
    m_warlockMinions.push_back({ minion->GetObjectGuid(), owned.weapon.id, m_totalMs + uint32(lifeMs * GetWeaponDurationScale(owned)), bite });
    DressWarlockMinions();
}

void BonkRun::DressWarlockMinions()
{
    Map* map = m_player->GetMap();
    for (WarlockMinion const& held : m_warlockMinions)
    {
        OwnedWeapon const* owned = FindOwned(held.weaponId);
        Creature* minion = owned ? map->GetCreature(held.guid) : nullptr;
        if (!minion || !minion->IsAlive())
            continue;
        float const damage = GetMinionSwingDamage(*owned, held) * GetDemonDamageScale();
        float const pace = GetWeaponCooldown(*owned) / float(std::max(1u, owned->weapon.cooldownMs));
        float const speed = GetPetRunSpeed();
        if (minion->GetBaseRunSpeedRate() != speed)
            minion->SetBaseSpeedRate(MOVE_RUN, speed);
        minion->SetBaseWeaponDamage(BASE_ATTACK, MINDAMAGE, damage * 0.9f);
        minion->SetBaseWeaponDamage(BASE_ATTACK, MAXDAMAGE, damage * 1.1f);
        minion->UpdateDamagePhysical(BASE_ATTACK);
        minion->SetAttackTime(BASE_ATTACK, std::max(BONK_MINION_MIN_ATTACK_MS, uint32(BONK_MINION_ATTACK_MS * pace)));
    }
}

float BonkRun::GetMinionSwingDamage(OwnedWeapon const& owned, WarlockMinion const& held) const
{
    if (held.weaponId == BONK_WEAPON_CURSE_OF_DOOM)
        return GetMobHealth(GetMobLevel()) * BONK_DOOMGUARD_SWING_HEALTHS * (1.0f + owned.damageBonus / 100.0f) * GetSummonTalentScale(owned);
    return std::max(1.0f, GetWeaponDamage(owned)) * held.bite * GetSummonTalentScale(owned);
}

bool BonkRun::IsWarlockMinion(ObjectGuid const& guid) const
{
    return std::any_of(m_warlockMinions.begin(), m_warlockMinions.end(), [&guid](WarlockMinion const& held) { return held.guid == guid; });
}

void BonkRun::UpdateWarlockMinions()
{
    if (m_warlockMinions.empty())
        return;
    Map* map = m_player->GetMap();
    m_warlockMinions.erase(std::remove_if(m_warlockMinions.begin(), m_warlockMinions.end(), [this, map](WarlockMinion const& held)
    {
        Creature* minion = map->GetCreature(held.guid);
        if (minion && minion->IsAlive() && FindOwned(held.weaponId) && int32(held.untilMs - m_totalMs) > 0)
            return false;
        if (minion)
            minion->DespawnOrUnsummon();
        return true;
    }), m_warlockMinions.end());
    DressWarlockMinions();
}

void BonkRun::DespawnWarlockMinions()
{
    if (Map* map = m_player->FindMap())
        for (WarlockMinion const& held : m_warlockMinions)
            if (Creature* minion = map->GetCreature(held.guid))
                minion->DespawnOrUnsummon();
    m_warlockMinions.clear();
    m_pendingInfernals.clear();
    m_pendingSeeds.clear();
    m_seedDepth.clear();
    m_seedHitReadyMs.clear();
    m_impPrey.clear();
    m_doomAt.clear();
    m_devourAffixReadyMs.clear();
    if (!m_souls.empty() && m_player->IsInWorld())
        m_player->RemoveAurasDueToSpell(BONK_SPELL_SOUL_LOOK);
    m_souls.clear();
    m_player->RemoveAurasDueToSpell(BONK_SPELL_DARK_PACT_AURA);
    m_darkHarvestReadyMs = m_voidSlamReadyMs = m_seductionReadyMs = 0;
}

std::vector<ObjectGuid> BonkRun::GetWarlockMinionGuids() const
{
    std::vector<ObjectGuid> guids;
    for (WarlockMinion const& held : m_warlockMinions)
        guids.push_back(held.guid);
    return guids;
}

uint32 BonkRun::GetWarlockMinionWeapon(ObjectGuid const& guid) const
{
    for (WarlockMinion const& held : m_warlockMinions)
        if (held.guid == guid)
            return held.weaponId;
    return 0;
}

bool BonkRun::HasWarlockSpell(uint32 weaponId) const
{
    return std::any_of(m_weapons.begin(), m_weapons.end(), [weaponId](OwnedWeapon const& owned) { return owned.weapon.id == weaponId; });
}

float BonkRun::GetDemonDamageScale() const
{
    float const pact = m_player->HasAura(BONK_SPELL_DARK_PACT_AURA) ? BONK_DARK_PACT_DAMAGE : 1.0f;
    float empowered = 1.0f;
    float const empowerment = m_mastery.Special(BONK_SPECIAL_DEMONIC_EMPOWERMENT);
    uint32 const empoweredMs = BONK_EMPOWERMENT_MS + uint32(m_mastery.Special(BONK_SPECIAL_IMPROVED_EMPOWERMENT) * IN_MILLISECONDS);
    if (empowerment > 0.0f && m_totalMs % BONK_EMPOWERMENT_EVERY_MS < empoweredMs)
        empowered += empowerment / 100.0f;
    return pact * empowered * (1.0f + BONK_DEMONOLOGIST_PER_DEMON * CountDemonTypes());
}

uint32 BonkRun::CountDemonTypes() const
{
    return m_mastery.Has(BONK_CAPSTONE_MASTER_DEMONOLOGIST) ? CountDemonFamilies() : 0;
}

uint32 BonkRun::CountDemonFamilies() const
{
    std::set<uint32> families;
    for (OwnedWeapon const& owned : m_weapons)
        if (uint32 const family = GetWarlockPetFamily(owned))
            families.insert(family);
    return uint32(families.size());
}

float BonkRun::GetWarlockDamageTakenScale(Unit const* victim) const
{
    float scale = 1.0f + BONK_SOUL_DAMAGE * m_souls.size();
    auto seduced = victim ? victim->GetSpellAuraHolder(BONK_SPELL_SEDUCED, m_player->GetObjectGuid()) : nullptr;
    if (seduced)
        scale *= BONK_SEDUCED_DAMAGE;
    return scale;
}

bool BonkRun::IsWarlockFullLash(OwnedWeapon const& owned) const
{
    return owned.weapon.id == BONK_WEAPON_PAINFUL_LASH;
}

uint32 BonkRun::GetWarlockExtraDrops(OwnedWeapon const& owned) const
{
    return owned.weapon.id == BONK_WEAPON_RAIN_OF_CHAOS ? BONK_RAIN_OF_CHAOS_EXTRA : 0;
}

float BonkRun::GetHellfireReach(OwnedWeapon const& owned) const
{
    if (owned.weapon.id != BONK_WEAPON_INFERNO || !m_player->GetMaxHealth())
        return 1.0f;
    float const missing = 1.0f - float(m_player->GetHealth()) / float(m_player->GetMaxHealth());
    return 1.0f + BONK_INFERNO_GROWTH * std::max(0.0f, missing);
}

void BonkRun::OnWarlockStrike(OwnedWeapon& owned, SpellEntry const* spellInfo, Creature* target, float share)
{
    uint32 const id = owned.weapon.id;
    if (id == BONK_WEAPON_CHAOS_BOLT && owned.casts % BONK_CHAOS_BOLT_EVERY == 0)
    {
        if (SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_CHAOS_LOOK))
            ShowStrike(m_player, look, target);
        std::vector<Creature*> struck = GetMobsInRange(GetWeaponRadius(owned), target);
        struck.push_back(target);
        for (Creature* mob : struck)
            if (mob->IsAlive())
                DealSpellHit(spellInfo, mob, GetWeaponDamage(owned) * share * BONK_CHAOS_BOLT_SHARE, nullptr, true);
    }
    if (id == BONK_WEAPON_CONFLAGRATE)
        for (Creature* mob : GetMobsInRange(GetWeaponRadius(owned), target))
        {
            DealShamanHit(spellInfo, owned.weapon.spellId, mob, GetWeaponDamage(owned) * share * BONK_CONFLAGRATE_SHARE);
            if (mob->IsAlive())
                ApplyWeaponKeyword(owned, mob, BONK_KEYWORD_BURNING, 1);
        }
    if (id == BONK_WEAPON_SHADOWFLAME && target->IsAlive())
        ApplyWeaponKeyword(owned, target, BONK_KEYWORD_DECAY, 1);
}

void BonkRun::OnNightfallBolt(OwnedWeapon& owned, SpellEntry const* spellInfo, Creature* target)
{
    if (owned.weapon.id != BONK_WEAPON_SHADOW_BARRAGE)
        return;
    uint32 jumps = 0;
    for (Creature* mob : GetMobsInRange(owned.weapon.range, target))
    {
        if (jumps++ >= BONK_SHADOW_BARRAGE_JUMPS)
            break;
        StrikeWith(owned, spellInfo, mob, BONK_SHADOW_BARRAGE_SHARE, true);
    }
}

void BonkRun::OnWarlockGroundDrop(OwnedWeapon const& owned, float x, float y, float z)
{
    if (owned.weapon.id == BONK_WEAPON_SUMMON_INFERNAL)
        m_pendingInfernals.push_back({ owned.weapon.id, x, y, z, m_totalMs + uint32(owned.weapon.durationMs * GetWeaponDurationScale(owned)) });
}

void BonkRun::CrashInfernals()
{
    for (auto itr = m_pendingInfernals.begin(); itr != m_pendingInfernals.end();)
    {
        if (int32(itr->atMs - m_totalMs) > 0)
        {
            ++itr;
            continue;
        }
        PendingInfernal const crash = *itr;
        itr = m_pendingInfernals.erase(itr);
        OwnedWeapon* owned = FindOwned(crash.weaponId);
        SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_INFERNO_LOOK);
        if (!owned || !look)
            continue;
        SummonWarlockMinion(*owned, BONK_INFERNAL, crash.x, crash.y, crash.z, BONK_INFERNAL_LIFE_MS, BONK_INFERNAL_BITE, 1.0f);
        ShowMissileFrom(m_player, look, crash.x, crash.y, crash.z);
        for (Creature* mob : GetMobsNear(crash.x, crash.y, BONK_INFERNAL_RADIUS * GetWeaponArea(*owned)))
        {
            DealShamanHit(look, owned->weapon.spellId, mob, GetWeaponDamage(*owned) * BONK_INFERNAL_SHARE);
            int32 durationMs = BONK_INFERNAL_STUN_MS;
            if (mob->IsAlive() && IsNormalMob(mob) && LimitStun(mob, durationMs))
                HoldMob(mob, look, SPELL_AURA_MOD_STUN, durationMs);
        }
    }
}

void BonkRun::OnWarlockEvolvedPetStrike(OwnedWeapon& owned, Creature* pet, Creature* prey)
{
    uint32 const id = owned.weapon.id;
    if (id == BONK_WEAPON_FEL_IMPS)
    {
        BonkPetFamily const* family = GetPetFamily(owned);
        SpellEntry const* bolt = family && !family->abilities.empty() ?
            sSpellMgr.GetSpellEntry(GetWarlockAbilitySpell(owned, family->abilities.front().spellId)) : nullptr;
        if (bolt)
        {
            float const hit = GetPetBiteDamage(owned, *family) * family->abilities.front().damage * BONK_FEL_IMPS_SHARE;
            uint32 jumps = 0;
            for (Creature* mob : GetMobsInRange(BONK_FEL_IMPS_RADIUS, prey))
            {
                if (jumps++ >= BONK_FEL_IMPS_JUMPS)
                    break;
                ShowStrike(prey, bolt, mob);
                DealSpellHit(bolt, mob, std::max(1.0f, hit), pet);
            }
        }
    }
    if (id == BONK_WEAPON_IMP_SWARM)
        m_impPrey[prey->GetObjectGuid()] = m_totalMs + BONK_IMP_PREY_MEMORY_MS;

    if (id == BONK_WEAPON_SPELL_LOCK && prey->IsAlive())
        for (Creature* mob : GetMobsInRange(BONK_SPELL_LOCK_RADIUS, prey))
            if (mob->IsNonMeleeSpellCasted(false))
                mob->InterruptNonMeleeSpells(false);

    if (id == BONK_WEAPON_DEVOUR_AFFIX && prey->IsAlive() && !IsNormalMob(prey))
    {
        uint32& readyMs = m_devourAffixReadyMs[pet->GetObjectGuid()];
        BonkMobAI* ai = dynamic_cast<BonkMobAI*>(prey->AI());
        if (ai && ai->GetAffixCount() && int32(readyMs - m_totalMs) <= 0)
        {
            readyMs = m_totalMs + BONK_DEVOUR_AFFIX_EVERY_MS;
            ai->QuietAffixes(BONK_DEVOUR_AFFIX_MS);
            if (SpellEntry const* devour = sSpellMgr.GetSpellEntry(BONK_SPELL_DEVOUR_LOOK))
                ShowStrike(pet, devour, prey);
        }
    }
}

void BonkRun::OnWarlockEvolvedKill(Unit* victim)
{
    Creature* dead = victim->ToCreature();
    if (!dead)
        return;
    ObjectGuid const guid = victim->GetObjectGuid();

    auto prey = m_impPrey.find(guid);
    if (prey != m_impPrey.end())
    {
        bool const fresh = int32(prey->second - m_totalMs) > 0;
        m_impPrey.erase(prey);
        OwnedWeapon* swarm = FindOwned(BONK_WEAPON_IMP_SWARM);
        uint32 const lesser = uint32(std::count_if(m_warlockMinions.begin(), m_warlockMinions.end(),
            [](WarlockMinion const& held) { return held.weaponId == BONK_WEAPON_IMP_SWARM; }));
        if (fresh && swarm && lesser < BONK_MAX_LESSER_IMPS)
            SummonWarlockMinion(*swarm, BONK_LESSER_IMP, victim->GetPositionX(), victim->GetPositionY(), victim->GetPositionZ(),
                BONK_LESSER_IMP_LIFE_MS, BONK_LESSER_IMP_BITE, BONK_LESSER_IMP_SCALE);
    }

    if (OwnedWeapon* seed = FindOwned(BONK_WEAPON_SEED_OF_CORRUPTION))
    {
        m_seedHitReadyMs.erase(guid);
        uint32 depth = 0;
        auto seeded = m_seedDepth.find(guid);
        if (seeded != m_seedDepth.end())
        {
            depth = seeded->second;
            m_seedDepth.erase(seeded);
        }
        if (GetKeywordStacks(victim, BONK_KEYWORD_DECAY) && depth < BONK_SEED_MAX_DEPTH)
            m_pendingSeeds.push_back({ guid, victim->GetPositionX(), victim->GetPositionY(), victim->GetPositionZ(), depth + 1, seed->weapon.id });
    }

    bool const pandemic = m_mastery.Has(BONK_CAPSTONE_PANDEMIC);
    if ((pandemic || FindOwned(BONK_WEAPON_AGONYS_ECHO)) && GetKeywordStacks(victim, BONK_KEYWORD_AGONY))
        PassAffliction(dead, BONK_KEYWORD_AGONY, !FindOwned(BONK_WEAPON_AGONYS_ECHO));
    if (pandemic && GetKeywordStacks(victim, BONK_KEYWORD_DECAY))
        PassAffliction(dead, BONK_KEYWORD_DECAY, true);

    if (FindOwned(BONK_WEAPON_DRAIN_SOUL) && std::find(m_drainBeams.begin(), m_drainBeams.end(), guid) != m_drainBeams.end())
        AddSoul();

    m_doomAt.erase(guid);
}

void BonkRun::PassAffliction(Creature* dead, BonkKeyword keyword, bool halve)
{
    BonkKeywordInfo const* info = sBonkMgr.GetKeyword(keyword);
    auto mob = m_dotStacks.find(dead->GetObjectGuid());
    if (!info || mob == m_dotStacks.end())
        return;
    auto stacks = mob->second.find(keyword);
    if (stacks == mob->second.end() || stacks->second.empty())
        return;
    std::vector<DotStack> carried = stacks->second;
    if (halve)
        carried.resize((carried.size() + 1) / 2);
    for (Creature* next : GetMobsInRange(BONK_SPREAD_RADIUS, dead))
    {
        if (GetKeywordStacks(next, keyword))
            continue;
        std::vector<DotStack>& list = m_dotStacks[next->GetObjectGuid()][keyword];
        list = carried;
        SyncDotAura(next, *info, list);
        if (SpellEntry const* look = sSpellMgr.GetSpellEntry(info->spellId))
            ShowStrike(dead, look, next);
        return;
    }
}

void BonkRun::AddSoul()
{
    while (m_souls.size() >= BONK_MAX_SOULS)
        m_souls.pop_front();
    m_souls.push_back(m_totalMs + BONK_SOUL_MS);
    ShowSouls();
}

void BonkRun::ShowSouls()
{
    if (m_souls.empty())
    {
        m_player->RemoveAurasDueToSpell(BONK_SPELL_SOUL_LOOK);
        return;
    }
    SpellAuraHolder* holder = m_player->GetSpellAuraHolder(BONK_SPELL_SOUL_LOOK);
    if (!holder)
        holder = m_player->AddAura(BONK_SPELL_SOUL_LOOK);
    if (!holder)
        return;
    int32 const left = int32(m_souls.back() - m_totalMs);
    holder->SetAuraMaxDuration(std::max(1, left));
    holder->SetAuraDuration(std::max(1, left));
    holder->SetStackAmount(uint32(m_souls.size()));
    holder->RefreshHolder();
}

void BonkRun::ExpireSouls()
{
    if (m_souls.empty())
        return;
    size_t const before = m_souls.size();
    while (!m_souls.empty() && int32(m_souls.front() - m_totalMs) <= 0)
        m_souls.pop_front();
    if (m_souls.size() != before)
        ShowSouls();
}

void BonkRun::BurstSeeds()
{
    SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_CORRUPTION_LOOK);
    std::vector<PendingSeed> due;
    due.swap(m_pendingSeeds);
    for (PendingSeed const& seed : due)
    {
        OwnedWeapon* owned = FindOwned(seed.weaponId);
        if (!owned || !look)
            continue;
        for (Creature* mob : GetMobsNear(seed.x, seed.y, GetWeaponRadius(*owned)))
        {
            uint32& readyMs = m_seedHitReadyMs[mob->GetObjectGuid()];
            if (int32(readyMs - m_totalMs) > 0)
                continue;
            readyMs = m_totalMs + BONK_SEED_HIT_GAP_MS;
            ShowStrike(m_player, look, mob);
            m_seedDepth[mob->GetObjectGuid()] = seed.depth;
            DealShamanHit(look, owned->weapon.spellId, mob, std::max(1.0f, GetWeaponDamage(*owned)) * BONK_SEED_SHARE);
            if (mob->IsAlive())
                ApplyWeaponKeyword(*owned, mob, BONK_KEYWORD_DECAY, owned->weapon.applyStacks);
        }
    }
}

void BonkRun::HarvestDecay()
{
    OwnedWeapon* owned = FindOwned(BONK_WEAPON_DARK_HARVEST);
    if (!owned || int32(m_darkHarvestReadyMs - m_totalMs) > 0)
        return;
    BonkKeywordInfo const* info = sBonkMgr.GetKeyword(BONK_KEYWORD_DECAY);
    SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_CORRUPTION_LOOK);
    if (!info || !look)
        return;
    m_darkHarvestReadyMs = m_totalMs + uint32(BONK_DARK_HARVEST_EVERY_MS / GetWeaponHasteRate(*owned));
    Map* map = m_player->GetMap();
    std::vector<std::pair<ObjectGuid, int64>> harvest;
    for (auto const& mob : m_dotStacks)
    {
        auto stacks = mob.second.find(BONK_KEYWORD_DECAY);
        if (stacks == mob.second.end())
            continue;
        int64 points = 0;
        for (DotStack const& stack : stacks->second)
            points += stack.points;
        if (points > 0)
            harvest.emplace_back(mob.first, points);
    }
    for (auto const& itr : harvest)
        if (Creature* mob = map->GetCreature(itr.first))
            if (mob->IsAlive() && m_player->IsWithinDistInMap(mob, owned->weapon.range))
            {
                ShowStrike(m_player, look, mob);
                DealExactHit(look, mob, std::max(1u, ToDamage(double(itr.second) / BONK_DOT_POINT_SCALE * BONK_DARK_HARVEST_TICKS * GetDamageMultiplier(look, mob) * GetHealthScale(mob))));
            }
}

void BonkRun::OnAgonyCurse(OwnedWeapon const& owned, Creature* mob)
{
    if (owned.weapon.id == BONK_WEAPON_CURSE_OF_DOOM && !m_doomAt.count(mob->GetObjectGuid()))
        m_doomAt[mob->GetObjectGuid()] = m_totalMs + BONK_DOOM_DELAY_MS;
}

void BonkRun::FallDoom()
{
    OwnedWeapon* owned = FindOwned(BONK_WEAPON_CURSE_OF_DOOM);
    if (!owned)
    {
        m_doomAt.clear();
        return;
    }
    SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_DOOM_LOOK);
    Map* map = m_player->GetMap();
    for (auto itr = m_doomAt.begin(); itr != m_doomAt.end();)
    {
        if (int32(itr->second - m_totalMs) > 0)
        {
            ++itr;
            continue;
        }
        Creature* mob = map->GetCreature(itr->first);
        itr = m_doomAt.erase(itr);
        if (!mob || !mob->IsAlive() || !look)
            continue;
        ShowStrike(m_player, look, mob);
        float const x = mob->GetPositionX(), y = mob->GetPositionY(), z = mob->GetPositionZ();
        DealShamanHit(look, owned->weapon.spellId, mob, GetMobHealth(GetMobLevel()) * BONK_DOOM_MOB_HEALTHS * (1.0f + owned->damageBonus / 100.0f));
        if (!mob->IsAlive())
            SummonWarlockMinion(*owned, BONK_DOOMGUARD, x, y, z, BONK_DOOMGUARD_LIFE_MS, 1.0f, 1.0f);
    }
}

void BonkRun::SlamVoid()
{
    SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_VOID_SLAM_LOOK);
    OwnedWeapon* owned = FindOwned(BONK_WEAPON_VOID_SLAM);
    BonkPetFamily const* family = owned ? GetPetFamily(*owned) : nullptr;
    if (!family || !look || int32(m_voidSlamReadyMs - m_totalMs) > 0)
        return;
    m_voidSlamReadyMs = m_totalMs + uint32(BONK_VOID_SLAM_EVERY_MS / GetWeaponHasteRate(*owned));
    for (ObjectGuid const& guid : owned->pets)
    {
        Creature* pet = m_player->GetMap()->GetCreature(guid);
        if (!pet || !pet->IsAlive())
            continue;
        std::vector<Creature*> const mobs = GetMobsNear(pet->GetPositionX(), pet->GetPositionY(), BONK_VOID_SLAM_RADIUS * GetSummonReach(*owned));
        if (mobs.empty())
            continue;
        ShowStrike(pet, look, pet);
        float const hit = GetPetBiteDamage(*owned, *family) * BONK_VOID_SLAM_BITES;
        for (Creature* mob : mobs)
        {
            DealSpellHit(look, mob, std::max(1.0f, hit), pet);
            if (mob->IsAlive() && IsNormalMob(mob))
                KnockBack(mob);
        }
    }
}

void BonkRun::SeduceStrongest()
{
    SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_SEDUCTION_LOOK);
    OwnedWeapon* owned = FindOwned(BONK_WEAPON_SEDUCTION);
    if (!owned || !look || int32(m_seductionReadyMs - m_totalMs) > 0)
        return;
    m_seductionReadyMs = m_totalMs + uint32(BONK_SEDUCTION_EVERY_MS / GetWeaponHasteRate(*owned));
    for (ObjectGuid const& guid : owned->pets)
    {
        Creature* pet = m_player->GetMap()->GetCreature(guid);
        if (!pet || !pet->IsAlive())
            continue;
        Creature* strongest = nullptr;
        for (Creature* mob : GetMobsNear(pet->GetPositionX(), pet->GetPositionY(), BONK_SEDUCTION_RANGE))
            if (IsNormalMob(mob) && (!strongest || mob->GetHealth() > strongest->GetHealth()))
                strongest = mob;
        if (!strongest)
            continue;
        ShowStrike(pet, look, strongest);
        PullMob(strongest, pet->GetPositionX(), pet->GetPositionY(), pet->GetPositionZ());
        ApplyTimedAuraTo(strongest, BONK_SPELL_SEDUCED, BONK_SEDUCED_MS, ADD_AURA_NEGATIVE);
    }
}

void BonkRun::OnConsumedBurst(OwnedWeapon const& owned)
{
    SupportScope scope(*this, WeaponSupport(owned));
    if (owned.weapon.id == BONK_WEAPON_SACRIFICE && m_player->IsAlive())
        AddSpellShield(uint32(m_player->GetMaxHealth() * BONK_SACRIFICE_SHIELD_PCT / 100.0f));
}

void BonkRun::OnDrainOverheal(uint32 heal)
{
    if (!heal || !HasWarlockSpell(BONK_WEAPON_DARK_PACT))
        return;
    uint32 const missing = m_player->GetMaxHealth() - m_player->GetHealth();
    if (heal > missing)
    {
        if (SpellAuraHolder* holder = m_player->AddAura(BONK_SPELL_DARK_PACT_AURA, ADD_AURA_POSITIVE))
        {
            holder->SetAuraDuration(BONK_DARK_PACT_MS);
            holder->SetAuraMaxDuration(BONK_DARK_PACT_MS);
            holder->UpdateAuraDuration();
        }
    }
}

void BonkRun::ImmolateDemons(OwnedWeapon const& owned, SpellEntry const* spellInfo)
{
    if (owned.weapon.id != BONK_WEAPON_DEMONIC_IMMOLATION)
        return;
    Map* map = m_player->GetMap();
    for (OwnedWeapon const& demon : m_weapons)
    {
        if (!GetWarlockPetFamily(demon))
            continue;
        for (ObjectGuid const& guid : demon.pets)
        {
            Creature* pet = map->GetCreature(guid);
            if (!pet || !pet->IsAlive())
                continue;
            std::vector<Creature*> const mobs = GetMobsNear(pet->GetPositionX(), pet->GetPositionY(), BONK_DEMONIC_IMMOLATION_RADIUS * GetWeaponArea(owned));
            if (mobs.empty())
                continue;
            ShowStrike(pet, spellInfo, pet);
            for (Creature* mob : mobs)
                DealShamanHit(spellInfo, owned.weapon.spellId, mob, GetWeaponDamage(owned) * BONK_DEMONIC_IMMOLATION_SHARE);
        }
    }
}

void BonkRun::UpdateWarlockEvolutions()
{
    BurstSeeds();
    HarvestDecay();
    FallDoom();
    SlamVoid();
    SeduceStrongest();
    CrashInfernals();
    ExpireSouls();
    UpdateWarlockMinions();
    for (auto itr = m_impPrey.begin(); itr != m_impPrey.end();)
        itr = int32(itr->second - m_totalMs) > 0 ? std::next(itr) : m_impPrey.erase(itr);
}

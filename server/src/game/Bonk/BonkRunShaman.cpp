#include "BonkRun.h"
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
    uint32 const BONK_WEAPON_LIGHTNING_BOLT   = 700;
    uint32 const BONK_WEAPON_CHAIN_LIGHTNING  = 701;
    uint32 const BONK_WEAPON_FERAL_SPIRIT     = 707;
    uint32 const BONK_WEAPON_SEARING_TOTEM    = 708;
    uint32 const BONK_WEAPON_MAGMA_TOTEM      = 709;
    uint32 const BONK_WEAPON_HEALING_STREAM   = 710;

    uint32 const BONK_WEAPON_LIGHTNING_OVERLOAD = 712;
    uint32 const BONK_WEAPON_LAVA_SURGE       = 717;
    uint32 const BONK_WEAPON_EARTHQUAKE       = 718;
    uint32 const BONK_WEAPON_EYE_OF_THE_STORM = 719;
    uint32 const BONK_WEAPON_FLAMETONGUE      = 720;
    uint32 const BONK_WEAPON_DOOM_WINDS       = 721;
    uint32 const BONK_WEAPON_LAVA_LASH        = 722;
    uint32 const BONK_WEAPON_CRASH_LIGHTNING  = 723;
    uint32 const BONK_WEAPON_OVERCHARGE       = 724;
    uint32 const BONK_WEAPON_STATIC_SURGE     = 725;
    uint32 const BONK_WEAPON_ELEMENTAL_SPIRITS = 726;
    uint32 const BONK_WEAPON_SPIRIT_PACK      = 727;
    uint32 const BONK_WEAPON_FIRE_NOVA_TOTEM  = 728;
    uint32 const BONK_WEAPON_TOTEM_OF_WRATH   = 729;
    uint32 const BONK_WEAPON_LIQUID_MAGMA     = 730;
    uint32 const BONK_WEAPON_EARTHBIND        = 731;
    uint32 const BONK_WEAPON_HEALING_RAIN     = 733;
    uint32 const BONK_WEAPON_EARTH_SHIELD     = 734;
    uint32 const BONK_WEAPON_STATIC_SHOCK     = 735;

    uint32 const BONK_SPELL_STATIC_DISCHARGE  = 16614;
    uint32 const BONK_SPELL_LIGHTNING_ZAP     = 26364;
    uint32 const BONK_SPELL_LIGHTNING_LOOK    = 403;
    uint32 const BONK_KIT_STORMSTRIKE_IMPACT  = 317;
    uint32 const BONK_KIT_FLAMETONGUE_IMPACT  = 145;
    uint32 const BONK_SPELL_LIGHTNING_SHIELD  = 33465;
    uint32 const BONK_SPELL_HEALING_STREAM    = 5672;
    uint32 const BONK_SPELL_FLAMETONGUE       = 10444;
    uint32 const BONK_SPELL_FIRE_NOVA         = 8349;
    uint32 const BONK_SPELL_MAGMA_GLOB        = 3606;
    uint32 const BONK_SPELL_THUNDERCLAP_LOOK  = 8078;
    uint32 const BONK_SPELL_EARTHQUAKE_LOOK   = 19798;
    uint32 const BONK_SPELL_DOOM_WINDS_LOOK   = 8233;
    uint32 const BONK_SPELL_FIRE_SPIRIT_LOOK  = 134;
    uint32 const BONK_SPELL_FROST_SPIRIT_LOOK = 168;
    uint32 const BONK_KIT_TOTEM_DROP          = 352;
    uint32 const BONK_KIT_FIRE_NOVA           = 6310;

    uint32 const BONK_WINDFURY_EVERY          = 3;
    uint32 const BONK_WINDFURY_SWINGS         = 2;
    int32 const BONK_WINDFURY_GAP_MS          = 120;
    int32 const BONK_WINDFURY_LOOK_LINGER_MS  = 600;
    float const BONK_FLAMETONGUE_SHARE        = 0.3f;
    uint32 const BONK_DOOM_WINDS_EVERY_MS     = 15000;
    uint32 const BONK_DOOM_WINDS_LASTS_MS     = 4000;
    float const BONK_LAVA_LASH_BURNING        = 1.5f;
    uint32 const BONK_LAVA_LASH_STACKS        = 2;
    float const BONK_CRASH_SHARE              = 0.5f;
    uint32 const BONK_STORMSTRIKE_STATIC      = 2;

    uint32 const BONK_MAELSTROM_HITS          = 3;
    int32 const BONK_MAELSTROM_DELAY_MS       = 50;
    float const BONK_MAELSTROM_RANGE          = 30.0f;
    uint32 const BONK_OVERCHARGE_TARGETS      = 3;
    uint32 const BONK_MAELSTROM_CHAIN_TARGETS = 2;
    uint32 const BONK_STORMSTRIKE_MAELSTROM_HITS = 2;
    uint32 const BONK_STATIC_SURGE_STACKS     = 5;

    uint32 const BONK_LIGHTNING_SHIELD_CHARGES = 3;
    float const BONK_LIGHTNING_SHIELD_REACH   = 10.0f;
    float const BONK_LIGHTNING_SHIELD_STEP    = 0.5f;
    float const BONK_LIGHTNING_SHIELD_CAP     = 5.0f;
    float const BONK_EARTH_SHIELD_STEP        = 1.5f;
    float const BONK_EARTH_SHIELD_CAP         = 15.0f;

    float const BONK_STATIC_RADIUS            = 6.0f;
    uint32 const BONK_STATIC_VICTIMS          = 3;
    int32 const BONK_STATIC_DELAY_MS          = 150;
    size_t const BONK_MAX_STATIC_PER_SEC      = 30;
    int32 const BONK_OVERLOAD_DELAY_MS        = 200;
    float const BONK_EYE_OF_THE_STORM_REACH   = 10.0f;
    float const BONK_EYE_OF_THE_STORM_SHARE   = 0.5f;

    uint32 const BONK_LAVA_SURGE_GAP_MS       = 500;

    uint32 const BONK_EARTHQUAKE_MS           = 4000;
    int32 const BONK_EARTHQUAKE_PULSE_MS      = 1000;
    size_t const BONK_MAX_EARTHQUAKES         = 3;
    float const BONK_EARTHQUAKE_SHARE         = 0.3f;

    uint32 const BONK_SPIRIT_PACK_MS          = 6000;

    uint32 const BONK_SHAMAN_TICK_MS          = 1000;
    uint32 const BONK_ASCENDANCE_STACKS       = 3;
    uint32 const BONK_DOOMHAMMER_WINDFURY_EVERY = 2;
    uint32 const BONK_DOOMHAMMER_MAELSTROM_HITS = 2;
    uint32 const BONK_TOTEMIC_MASTERY_TOTEMS  = 1;
    float const BONK_TOTEM_REPLANT_RANGE      = 20.0f;
    float const BONK_TOTEM_SLOT_DISTANCE      = 2.5f;
    uint32 const BONK_TOTEM_SLOTS             = 6;
    float const BONK_MAGMA_THROW_RANGE        = 25.0f;
    float const BONK_MAGMA_LEASH              = 30.0f;
    uint32 const BONK_MAGMA_IDLE_MS           = 2000;
    float const BONK_HEALING_STREAM_RANGE     = 15.0f;
    uint32 const BONK_FIRE_NOVA_EVERY_TICKS   = 4;
    float const BONK_FIRE_NOVA_SHARE          = 1.0f;
    uint32 const BONK_FIRE_NOVA_STACKS        = 3;
    float const BONK_TOTEM_OF_WRATH_REACH     = 15.0f;
    float const BONK_TOTEM_OF_WRATH_BONUS     = 1.15f;
    float const BONK_LIQUID_MAGMA_REACH       = 12.0f;
    uint32 const BONK_LIQUID_MAGMA_GLOBS      = 2;
    float const BONK_LIQUID_MAGMA_SHARE       = 0.5f;
    uint32 const BONK_HEALING_RAIN_EVERY_TICKS = 3;
    int32 const BONK_STORMFLURRY_RECHARGE_MS  = 600000;
}

void BonkRun::ResetShamanState()
{
    m_maelstromHits = 0;
    m_lightningCharges = 0;
    m_magmaIdleMs.clear();
    m_shamanTickMs = 0;
    m_shamanTicks = 0;
    m_doomWindsReadyMs = 0;
    m_lavaSurgeReadyMs = 0;
    m_spiritPackUntil.clear();
    m_staticDischargeTimes.clear();
    if (m_player->HasAura(BONK_SPELL_LIGHTNING_SHIELD))
        m_player->RemoveAurasDueToSpell(BONK_SPELL_LIGHTNING_SHIELD);
}

void BonkRun::UpdateShaman(uint32 diff)
{
    if (m_player->GetClass() != CLASS_SHAMAN)
        return;
    m_shamanTickMs += diff;
    if (m_shamanTickMs < BONK_SHAMAN_TICK_MS)
        return;
    m_shamanTickMs = 0;
    ++m_shamanTicks;
    ReplantTotems();
    FlowHealingStreams();
    DressElementalSpirits();
    if (m_shamanTicks % BONK_FIRE_NOVA_EVERY_TICKS == 0)
        BurstFireNovaTotems();
    if (m_shamanTicks % BONK_HEALING_RAIN_EVERY_TICKS == 0)
        RainFromHealingTotems();
}

bool BonkRun::OwnsShamanSpell(uint32 weaponId) const
{
    return std::any_of(m_weapons.begin(), m_weapons.end(), [weaponId](OwnedWeapon const& owned) { return owned.weapon.id == weaponId; });
}

uint32 BonkRun::GetShamanPetFamily(OwnedWeapon const& owned) const
{
    if (owned.weapon.id == BONK_WEAPON_ELEMENTAL_SPIRITS)
        return BONK_PET_FAMILY_ELEMENTAL_SPIRIT;
    switch (GetRootWeapon(owned.weapon))
    {
        case BONK_WEAPON_FERAL_SPIRIT:   return BONK_PET_FAMILY_SPIRIT_WOLF;
        case BONK_WEAPON_SEARING_TOTEM:  return BONK_PET_FAMILY_SEARING_TOTEM;
        case BONK_WEAPON_MAGMA_TOTEM:    return BONK_PET_FAMILY_MAGMA_TOTEM;
        case BONK_WEAPON_HEALING_STREAM: return BONK_PET_FAMILY_HEALING_STREAM_TOTEM;
        default:                         return 0;
    }
}

void BonkRun::StrikeSearingTotemSecondTarget(OwnedWeapon& owned, BonkPetFamily const& family, Creature* pet, Creature* prey, BonkPetAbility const& ability)
{
    if (family.id != BONK_PET_FAMILY_SEARING_TOTEM)
        return;
    for (Creature* mob : GetMobsNear(pet->GetPositionX(), pet->GetPositionY(), ability.value))
    {
        if (mob == prey || !SurvivesBoltsInFlight(mob) || !pet->IsWithinLOSInMap(mob))
            continue;
        PetStrike(owned, pet, mob, ability);
        return;
    }
}

bool BonkRun::ApplyShamanKeyword(OwnedWeapon const& owned, Creature* mob, BonkKeyword keyword, uint32 stacks)
{
    BonkKeywordInfo const* info = sBonkMgr.GetKeyword(keyword);
    if (!info || !mob || !mob->IsAlive())
        return false;
    uint32 const durationMs = uint32(info->durationMs * GetWeaponDurationScale(owned));
    return ApplyKeyword(mob, keyword, stacks, durationMs, 1.0f + owned.damageBonus / 100.0f, owned.weapon.spellId);
}

bool BonkRun::DealShamanHit(SpellEntry const* spellInfo, uint32 creditSpellId, Unit* target, float damage)
{
    if (!spellInfo || !target || !target->IsAlive() || damage <= 0.0f || !m_player->IsAlive())
        return false;

    bool const keywordless = m_keywordlessHits;
    m_keywordlessHits = true;
    SpellNonMeleeDamage hit(m_player, target, spellInfo->Id, SpellSchools(spellInfo->School));
    bool const crit = spellInfo->CanCrit() && roll_chance_f(GetCritChance(spellInfo, target));
    m_player->CalculateSpellDamage(&hit, damage, spellInfo, EFFECT_INDEX_0, BASE_ATTACK, nullptr, crit);
    target->CalculateAbsorbResistBlock(m_player, &hit, spellInfo, BASE_ATTACK, nullptr);
    m_player->DealDamageMods(target, hit.damage, &hit.absorb);
    hit.spellId = creditSpellId;
    m_player->SendSpellNonMeleeDamageLog(&hit);
    m_player->DealSpellDamage(&hit, true);
    m_keywordlessHits = keywordless;
    OnClassSpellHit(creditSpellId, target);
    return crit;
}

void BonkRun::OnShamanStrike(OwnedWeapon& owned, SpellEntry const*, Creature* target, float share)
{
    BonkWeapon const& weapon = owned.weapon;
    if (weapon.behavior != BONK_BEHAVIOR_WINDFURY && weapon.behavior != BONK_BEHAVIOR_STORMSTRIKE && weapon.behavior != BONK_BEHAVIOR_MAELSTROM)
        CountMaelstromHit();
    if (weapon.behavior == BONK_BEHAVIOR_WINDFURY)
    {
        CountMaelstromHit();
        SpendStaticShock(target);
        if (weapon.id == BONK_WEAPON_FLAMETONGUE)
            BurnWithFlametongue(owned, target, 1);

        bool doomWinds = false;
        if (weapon.id == BONK_WEAPON_DOOM_WINDS)
        {
            uint32 const now = WorldTimer::getMSTime();
            if (int32(now - m_doomWindsReadyMs) >= 0)
            {
                m_doomWindsReadyMs = now + BONK_DOOM_WINDS_EVERY_MS;
                if (SpellAuraHolder* holder = m_player->AddAura(BONK_SPELL_DOOM_WINDS_LOOK))
                {
                    holder->SetAuraMaxDuration(int32(BONK_DOOM_WINDS_LASTS_MS));
                    holder->SetAuraDuration(int32(BONK_DOOM_WINDS_LASTS_MS));
                    holder->RefreshHolder();
                }
            }
            doomWinds = m_player->HasAura(BONK_SPELL_DOOM_WINDS_LOOK);
        }
        if (doomWinds || owned.casts % GetWindfuryEvery() == 0)
            QueueWindfury(owned, target, share);
        return;
    }

    if (weapon.behavior == BONK_BEHAVIOR_EARTH_SHOCK)
    {
        BonkKeywordInfo const* staticInfo = sBonkMgr.GetKeyword(BONK_KEYWORD_STATIC);
        uint32 const charge = GetKeywordStacks(target, BONK_KEYWORD_STATIC);
        if (staticInfo && charge && QueueStaticDischarge(target, weapon.spellId))
        {
            target->RemoveAurasByCasterSpell(staticInfo->spellId, m_player->GetObjectGuid());
            RestoreLightningCharges(charge);
        }
        if (weapon.id == BONK_WEAPON_EARTHQUAKE)
            StartKeywordCloud(owned, target->GetPositionX(), target->GetPositionY(), target->GetPositionZ());
        return;
    }

    if (weapon.behavior != BONK_BEHAVIOR_STORMSTRIKE)
        return;

    for (uint32 hit = 0; hit < BONK_STORMSTRIKE_MAELSTROM_HITS; ++hit)
        CountMaelstromHit();
    SpendStaticShock(target);
    if (!target->IsAlive())
        return;
    ApplyShamanKeyword(owned, target, BONK_KEYWORD_STATIC, BONK_STORMSTRIKE_STATIC);

    bool const lava = weapon.id == BONK_WEAPON_LAVA_LASH;
    SpellEntry const* hitInfo = sSpellMgr.GetSpellEntry(lava ? BONK_SPELL_FLAMETONGUE : BONK_SPELL_LIGHTNING_ZAP);
    if (!hitInfo)
        return;
    float damage = GetWeaponDamage(owned) * share;
    if (lava)
    {
        if (GetKeywordStacks(target, BONK_KEYWORD_BURNING))
            damage *= BONK_LAVA_LASH_BURNING;
        ApplyShamanKeyword(owned, target, BONK_KEYWORD_BURNING, BONK_LAVA_LASH_STACKS);
    }
    target->SendPlaySpellVisualKit(lava ? BONK_KIT_FLAMETONGUE_IMPACT : BONK_KIT_STORMSTRIKE_IMPACT);
    DealShamanHit(hitInfo, weapon.spellId, target, damage);

    if (weapon.id != BONK_WEAPON_CRASH_LIGHTNING)
        return;
    SpellEntry const* zap = sSpellMgr.GetSpellEntry(BONK_SPELL_LIGHTNING_ZAP);
    float const radius = GetWeaponRadius(owned);
    if (SpellEntry const* clap = sSpellMgr.GetSpellEntry(BONK_SPELL_THUNDERCLAP_LOOK))
        ShowAreaImpact(clap, radius);
    for (Creature* mob : GetMobsInRange(radius))
    {
        DealShamanHit(zap, weapon.spellId, mob, GetWeaponDamage(owned) * BONK_CRASH_SHARE);
        ApplyShamanKeyword(owned, mob, BONK_KEYWORD_STATIC, 1);
    }
}

void BonkRun::BurnWithFlametongue(OwnedWeapon& owned, Creature* target, uint32 stacks)
{
    SpellEntry const* flame = sSpellMgr.GetSpellEntry(BONK_SPELL_FLAMETONGUE);
    if (!flame || !target || !target->IsAlive())
        return;
    target->SendPlaySpellVisualKit(BONK_KIT_FLAMETONGUE_IMPACT);
    DealShamanHit(flame, owned.weapon.spellId, target, GetWeaponDamage(owned) * BONK_FLAMETONGUE_SHARE);
    ApplyShamanKeyword(owned, target, BONK_KEYWORD_BURNING, stacks);
}

void BonkRun::ShowWindfuryGust(int32 durationMs)
{
    if (m_player->HasAura(BONK_SPELL_DOOM_WINDS_LOOK))
        return;
    if (SpellAuraHolder* holder = m_player->AddAura(BONK_SPELL_DOOM_WINDS_LOOK))
    {
        holder->SetAuraMaxDuration(durationMs);
        holder->SetAuraDuration(durationMs);
        holder->RefreshHolder();
    }
}

void BonkRun::QueueWindfury(OwnedWeapon const& owned, Creature* target, float share)
{
    OnTalentWindfury();
    uint32 const swings = BONK_WINDFURY_SWINGS + uint32(m_mastery.Special(BONK_SPECIAL_IMPROVED_WINDFURY));
    ShowWindfuryGust(int32(swings) * BONK_WINDFURY_GAP_MS + BONK_WINDFURY_LOOK_LINGER_MS);
    for (uint32 swing = 1; swing <= swings; ++swing)
    {
        PendingCast gust;
        gust.weaponId = owned.weapon.id;
        gust.spellId = owned.weapon.spellId;
        gust.leftMs = int32(swing) * BONK_WINDFURY_GAP_MS;
        gust.target = target->GetObjectGuid();
        gust.share = share;
        gust.windfury = true;
        m_pendingCasts.push_back(gust);
    }

    OwnedWeapon* pack = FindOwned(BONK_WEAPON_SPIRIT_PACK);
    if (!pack)
        return;
    m_spiritPackUntil.push_back(WorldTimer::getMSTime() + uint32(BONK_SPIRIT_PACK_MS * GetWeaponDurationScale(*pack)));
    UpdatePets(*pack);
}

void BonkRun::SwingWindfury(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    Creature* target = m_player->GetMap()->GetCreature(cast.target);
    if (!target || !target->IsAlive())
    {
        std::vector<Creature*> const nearby = GetMobsInRange(GetStrikeRange(owned));
        target = nearby.empty() ? nullptr : nearby.front();
    }
    if (!target)
        return;

    StrikeWith(owned, spellInfo, target, cast.share, true);
    for (Creature* mob : GetMobsInRange(GetWeaponRadius(owned), target))
        if (mob != target && m_player->IsWithinLOSInMap(mob))
            StrikeWith(owned, spellInfo, mob, cast.share, true);
    CountMaelstromHit();
    SpendStaticShock(target);
    if (owned.weapon.id == BONK_WEAPON_FLAMETONGUE)
        BurnWithFlametongue(owned, target, 3);
    SwingWeapon(owned);
    ShowStrikeImpact(spellInfo, target);
}

uint32 BonkRun::GetStaticDischargeStacks(BonkKeywordInfo const& info) const
{
    if (m_mastery.Has(BONK_CAPSTONE_ASCENDANCE))
        return std::min<uint32>(BONK_ASCENDANCE_STACKS, info.maxStacks);
    return info.maxStacks;
}

uint32 BonkRun::GetWindfuryEvery() const
{
    return m_mastery.Has(BONK_CAPSTONE_DOOMHAMMER) ? BONK_DOOMHAMMER_WINDFURY_EVERY : BONK_WINDFURY_EVERY;
}

uint32 BonkRun::GetMaelstromHits() const
{
    return m_mastery.Has(BONK_CAPSTONE_DOOMHAMMER) ? BONK_DOOMHAMMER_MAELSTROM_HITS : BONK_MAELSTROM_HITS;
}

uint32 BonkRun::GetShamanExtraPets(OwnedWeapon const& owned)
{
    if (owned.weapon.HasFlag(BONK_WEAPON_FLAG_TOTEM) && m_mastery.Has(BONK_CAPSTONE_TOTEMIC_MASTERY))
        return BONK_TOTEMIC_MASTERY_TOTEMS;
    if (owned.weapon.id != BONK_WEAPON_SPIRIT_PACK)
        return 0;
    uint32 const now = WorldTimer::getMSTime();
    m_spiritPackUntil.erase(std::remove_if(m_spiritPackUntil.begin(), m_spiritPackUntil.end(), [now](uint32 until)
    {
        return int32(until - now) <= 0;
    }), m_spiritPackUntil.end());
    return uint32(m_spiritPackUntil.size());
}

void BonkRun::CountMaelstromHit()
{
    auto maelstrom = std::find_if(m_weapons.begin(), m_weapons.end(), [](OwnedWeapon const& owned)
    {
        return owned.weapon.behavior == BONK_BEHAVIOR_MAELSTROM;
    });
    if (maelstrom == m_weapons.end() || ++m_maelstromHits < GetMaelstromHits())
        return;
    m_maelstromHits = 0;

    PendingCast release;
    release.weaponId = maelstrom->weapon.id;
    release.spellId = maelstrom->weapon.spellId;
    release.leftMs = BONK_MAELSTROM_DELAY_MS;
    release.maelstrom = true;
    m_pendingCasts.push_back(release);
}

void BonkRun::ReleaseMaelstrom()
{
    auto maelstrom = std::find_if(m_weapons.begin(), m_weapons.end(), [](OwnedWeapon const& owned)
    {
        return owned.weapon.behavior == BONK_BEHAVIOR_MAELSTROM;
    });
    if (maelstrom == m_weapons.end())
        return;
    uint32 const maelstromId = maelstrom->weapon.id;
    SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(maelstrom->weapon.spellId);
    if (!spellInfo)
        return;
    bool const chained = std::any_of(m_weapons.begin(), m_weapons.end(), [this](OwnedWeapon const& owned)
    {
        return GetRootWeapon(owned.weapon) == BONK_WEAPON_CHAIN_LIGHTNING;
    });
    uint32 const targets = (maelstromId == BONK_WEAPON_OVERCHARGE ? BONK_OVERCHARGE_TARGETS : 1) + (chained ? BONK_MAELSTROM_CHAIN_TARGETS : 0);
    uint32 fired = 0;
    FiringWeapon firing(m_player->GetBonkPlayer());
    for (Creature* mob : GetMobsInRange(BONK_MAELSTROM_RANGE))
    {
        if (fired >= targets)
            break;
        if (!m_player->IsWithinLOSInMap(mob))
            continue;
        StrikeWith(*maelstrom, spellInfo, mob, 1.0f);
        if (maelstromId == BONK_WEAPON_STATIC_SURGE && mob->IsAlive())
            ApplyShamanKeyword(*maelstrom, mob, BONK_KEYWORD_STATIC, BONK_STATIC_SURGE_STACKS);
        ++fired;
    }
    if (fired && m_mastery.Special(BONK_SPECIAL_STORMFLURRY) > 0.0f)
        ReduceTimer(BONK_WEAPON_STORMSTRIKE, BONK_STORMFLURRY_RECHARGE_MS);
}

void BonkRun::OnShamanPetBite(Creature* pet, Unit* victim)
{
    for (OwnedWeapon const& owned : m_weapons)
    {
        uint32 const family = GetShamanPetFamily(owned);
        if ((family != BONK_PET_FAMILY_SPIRIT_WOLF && family != BONK_PET_FAMILY_ELEMENTAL_SPIRIT) ||
            std::find(owned.pets.begin(), owned.pets.end(), pet->GetObjectGuid()) == owned.pets.end())
            continue;

        CountMaelstromHit();
        Creature* prey = victim->ToCreature();
        uint32 const alphaWolf = uint32(m_mastery.Special(BONK_SPECIAL_ALPHA_WOLF));
        if (family == BONK_PET_FAMILY_SPIRIT_WOLF && prey && alphaWolf && prey->IsAlive())
            ApplyShamanKeyword(owned, prey, BONK_KEYWORD_STATIC, alphaWolf);
        if (family == BONK_PET_FAMILY_ELEMENTAL_SPIRIT && prey)
        {
            BonkKeyword const forms[] = { BONK_KEYWORD_BURNING, BONK_KEYWORD_CHILL, BONK_KEYWORD_STATIC };
            size_t const index = size_t(std::find(owned.pets.begin(), owned.pets.end(), pet->GetObjectGuid()) - owned.pets.begin());
            ApplyShamanKeyword(owned, prey, forms[index % 3], 1);
        }
        return;
    }
}

void BonkRun::DressElementalSpirits()
{
    OwnedWeapon const* spirits = FindOwned(BONK_WEAPON_ELEMENTAL_SPIRITS);
    if (!spirits)
        return;
    uint32 const looks[] = { BONK_SPELL_FIRE_SPIRIT_LOOK, BONK_SPELL_FROST_SPIRIT_LOOK, BONK_SPELL_LIGHTNING_SHIELD };
    Map* map = m_player->GetMap();
    for (size_t i = 0; i < spirits->pets.size(); ++i)
        if (Creature* wolf = map->GetCreature(spirits->pets[i]))
            if (wolf->IsAlive() && !wolf->HasAura(looks[i % 3]))
                wolf->AddAura(looks[i % 3], ADD_AURA_PERMANENT);
}

void BonkRun::ChargeLightningShield()
{
    if (!m_player->IsAlive())
        return;
    if (m_lightningCharges < BONK_LIGHTNING_SHIELD_CHARGES)
        ++m_lightningCharges;
    ShowLightningShield(m_lightningCharges);
}

void BonkRun::RestoreLightningCharges(uint32 charges)
{
    if (!m_player->IsAlive() || !HasBehavior(BONK_BEHAVIOR_LIGHTNING_SHIELD))
        return;
    m_lightningCharges = std::min(m_lightningCharges + charges, BONK_LIGHTNING_SHIELD_CHARGES);
    ShowLightningShield(m_lightningCharges);
}

void BonkRun::ShowLightningShield(uint32 charges)
{
    if (!charges)
    {
        m_player->RemoveAurasDueToSpell(BONK_SPELL_LIGHTNING_SHIELD);
        return;
    }
    SpellAuraHolder* holder = m_player->GetSpellAuraHolder(BONK_SPELL_LIGHTNING_SHIELD);
    if (!holder)
        holder = m_player->AddAura(BONK_SPELL_LIGHTNING_SHIELD, ADD_AURA_PERMANENT);
    if (holder)
        holder->SetStackAmount(charges);
}

void BonkRun::OnShamanStruck(Creature* attacker)
{
    if (m_state != STATE_RUNNING || IsPeriodicHit() || !m_lightningCharges || !attacker || !attacker->IsAlive())
        return;
    auto shield = std::find_if(m_weapons.begin(), m_weapons.end(), [](OwnedWeapon const& owned)
    {
        return owned.weapon.behavior == BONK_BEHAVIOR_LIGHTNING_SHIELD;
    });
    if (shield == m_weapons.end())
        return;

    --m_lightningCharges;
    ShowLightningShield(m_lightningCharges);
    ZapWithLightningShield(*shield, attacker);
}

void BonkRun::ZapNearestWithLightningShield(OwnedWeapon const& shield)
{
    if (!m_player->IsAlive())
        return;
    uint32 const zaps = std::max(1u, m_lightningCharges);
    uint32 zapped = 0;
    for (Creature* mob : GetMobsInRange(BONK_LIGHTNING_SHIELD_REACH * GetWeaponArea(shield)))
    {
        if (zapped >= zaps)
            return;
        if (!m_player->IsWithinLOSInMap(mob))
            continue;
        ZapWithLightningShield(shield, mob);
        ++zapped;
    }
}

void BonkRun::ZapWithLightningShield(OwnedWeapon const& shield, Creature* target)
{
    SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_LIGHTNING_LOOK);
    if (look)
        ShowStrike(m_player, look, target);
    std::vector<Creature*> victims = { target };
    if (shield.weapon.id == BONK_WEAPON_STATIC_SHOCK)
        victims = GetStaticShockVictims(shield, target);
    SpellEntry const* zap = sSpellMgr.GetSpellEntry(BONK_SPELL_LIGHTNING_ZAP);
    for (Creature* mob : victims)
    {
        DealShamanHit(zap, shield.weapon.spellId, mob, GetWeaponDamage(shield));
        ApplyShamanKeyword(shield, mob, BONK_KEYWORD_STATIC, shield.weapon.applyStacks);
    }

    if (!m_player->IsAlive())
        return;
    bool const earth = shield.weapon.id == BONK_WEAPON_EARTH_SHIELD;
    SupportScope scope(*this, WeaponSupport(shield));
    uint32 const cap = uint32(m_player->GetMaxHealth() * (earth ? BONK_EARTH_SHIELD_CAP : BONK_LIGHTNING_SHIELD_CAP) / 100.0f);
    uint32 const step = std::max(1u, uint32(m_player->GetMaxHealth() * (earth ? BONK_EARTH_SHIELD_STEP : BONK_LIGHTNING_SHIELD_STEP) / 100.0f));
    if (m_spellShield < cap)
        AddSpellShield(std::min(step, cap - m_spellShield));
}

void BonkRun::SpendStaticShock(Creature* target)
{
    OwnedWeapon const* shock = FindOwned(BONK_WEAPON_STATIC_SHOCK);
    if (!shock || !m_lightningCharges || !target || !target->IsAlive())
        return;

    --m_lightningCharges;
    ShowLightningShield(m_lightningCharges);
    SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_LIGHTNING_LOOK);
    SpellEntry const* zap = sSpellMgr.GetSpellEntry(BONK_SPELL_LIGHTNING_ZAP);
    if (look)
        ShowStrike(m_player, look, target);
    for (Creature* mob : GetStaticShockVictims(*shock, target))
    {
        DealShamanHit(zap, shock->weapon.spellId, mob, GetWeaponDamage(*shock));
        ApplyShamanKeyword(*shock, mob, BONK_KEYWORD_STATIC, shock->weapon.applyStacks);
    }
}

std::vector<Creature*> BonkRun::GetStaticShockVictims(OwnedWeapon const& shock, Creature* target) const
{
    std::vector<Creature*> victims = GetMobsInRange(GetWeaponRadius(shock), target);
    if (std::find(victims.begin(), victims.end(), target) == victims.end())
        victims.insert(victims.begin(), target);
    return victims;
}

bool BonkRun::QueueStaticDischarge(Creature* mob, uint32 sourceSpellId)
{
    if (!TakeRateSlot(m_staticDischargeTimes, BONK_MAX_STATIC_PER_SEC) || m_weapons.empty())
        return false;

    OwnedWeapon const* source = FindOwnedBySpell(sourceSpellId);
    PendingCast discharge;
    discharge.weaponId = source ? source->weapon.id : m_weapons.front().weapon.id;
    discharge.spellId = source ? sourceSpellId : BONK_SPELL_STATIC_DISCHARGE;
    discharge.leftMs = BONK_STATIC_DELAY_MS;
    discharge.target = mob->GetObjectGuid();
    discharge.x = mob->GetPositionX();
    discharge.y = mob->GetPositionY();
    discharge.z = mob->GetPositionZ();
    discharge.staticDischarge = true;
    m_pendingCasts.push_back(discharge);

    if (source && source->weapon.id == BONK_WEAPON_LIGHTNING_OVERLOAD)
        QueueOverload(*source, mob);
    return true;
}

void BonkRun::QueueOverload(OwnedWeapon const& owned, Creature* mob)
{
    if (!owned.weapon.altSpellId)
        return;
    PendingCast overload;
    overload.weaponId = owned.weapon.id;
    overload.spellId = owned.weapon.altSpellId;
    overload.leftMs = BONK_OVERLOAD_DELAY_MS;
    overload.target = mob->GetObjectGuid();
    overload.share = owned.weapon.altDamage;
    overload.overload = true;
    m_pendingCasts.push_back(overload);
}

void BonkRun::DischargeStatic(PendingCast const& cast)
{
    SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_STATIC_DISCHARGE);
    SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(cast.spellId);
    BonkKeywordInfo const* info = sBonkMgr.GetKeyword(BONK_KEYWORD_STATIC);
    if (!look || !spellInfo || !info)
        return;

    float const damage = GetMobHealth(GetMobLevel()) * info->valuePerStack * (1.0f + GetKeywordTalentDamage(BONK_KEYWORD_STATIC) / 100.0f);
    Creature* target = m_player->GetMap()->GetCreature(cast.target);
    std::vector<Creature*> victims;
    if (target && target->IsAlive())
        victims.push_back(target);
    for (Creature* mob : GetMobsNear(cast.x, cast.y, BONK_STATIC_RADIUS))
    {
        if (victims.size() >= BONK_STATIC_VICTIMS + 1 + uint32(m_mastery.Special(BONK_SPECIAL_AFTERSHOCK)))
            break;
        if (mob != target)
            victims.push_back(mob);
    }

    bool const stuns = m_mastery.Special(BONK_SPECIAL_STATIC_CHARGE) > 0.0f;
    for (Creature* mob : victims)
    {
        ShowStrike(m_player, look, mob);
        m_meterPartSpell = info->spellId;
        DealShamanHit(spellInfo, spellInfo->Id, mob, damage);
        m_meterPartSpell = 0;
        if (stuns && mob->IsAlive())
            m_pendingStuns.push_back(mob->GetObjectGuid());
    }
    OnTalentStaticDischarge();
    StormNearDischarge(cast);
}

void BonkRun::StormNearDischarge(PendingCast const& cast)
{
    OwnedWeapon const* eye = FindOwned(BONK_WEAPON_EYE_OF_THE_STORM);
    if (!eye || m_player->GetDistance2d(cast.x, cast.y) > BONK_EYE_OF_THE_STORM_REACH)
        return;
    SpellEntry const* zap = sSpellMgr.GetSpellEntry(BONK_SPELL_LIGHTNING_ZAP);
    SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_STATIC_DISCHARGE);
    for (Creature* mob : GetMobsNear(cast.x, cast.y, GetWeaponRadius(*eye)))
    {
        if (look)
            ShowStrike(m_player, look, mob);
        DealShamanHit(zap, eye->weapon.spellId, mob, GetWeaponDamage(*eye) * BONK_EYE_OF_THE_STORM_SHARE);
    }
}

void BonkRun::ResolveShamanCast(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    if (cast.windfury)
        SwingWindfury(owned, spellInfo, cast);
    else if (cast.maelstrom)
        ReleaseMaelstrom();
    else if (cast.staticDischarge)
        DischargeStatic(cast);
    else if (cast.overload)
    {
        Creature* target = m_player->GetMap()->GetCreature(cast.target);
        if (target && target->IsAlive())
        {
            FiringWeapon firing(m_player->GetBonkPlayer());
            StrikeWith(owned, spellInfo, target, cast.share, true);
        }
    }
}

void BonkRun::SortMostStaticFirst(std::vector<Creature*>& mobs) const
{
    std::vector<std::pair<uint32, Creature*>> ranked;
    ranked.reserve(mobs.size());
    for (Creature* mob : mobs)
        ranked.emplace_back(GetKeywordStacks(mob, BONK_KEYWORD_STATIC), mob);
    std::stable_sort(ranked.begin(), ranked.end(), [](auto const& a, auto const& b) { return a.first > b.first; });
    for (size_t i = 0; i < ranked.size(); ++i)
        mobs[i] = ranked[i].second;
}

bool BonkRun::GetShamanCloudKind(OwnedWeapon const& owned, KeywordCloudKind& kind) const
{
    if (owned.weapon.id != BONK_WEAPON_EARTHQUAKE)
        return false;
    kind.lifeMs = BONK_EARTHQUAKE_MS;
    kind.pulseEveryMs = BONK_EARTHQUAKE_PULSE_MS;
    kind.stacks = 0;
    kind.maxAlive = BONK_MAX_EARTHQUAKES;
    kind.lookSpellId = BONK_SPELL_EARTHQUAKE_LOOK;
    return true;
}

void BonkRun::OnShamanCloudPulse(OwnedWeapon const& owned, KeywordCloud const& cloud)
{
    if (owned.weapon.id != BONK_WEAPON_EARTHQUAKE)
        return;
    SpellEntry const* zap = sSpellMgr.GetSpellEntry(BONK_SPELL_LIGHTNING_ZAP);
    for (Creature* mob : GetMobsNear(cloud.x, cloud.y, cloud.radius))
    {
        DealShamanHit(zap, owned.weapon.spellId, mob, GetWeaponDamage(owned) * BONK_EARTHQUAKE_SHARE);
        ApplyShamanKeyword(owned, mob, BONK_KEYWORD_DAZED, 1);
    }
}

void BonkRun::OnShamanKill(Unit* victim)
{
    if (!OwnsShamanSpell(BONK_WEAPON_LAVA_SURGE) || !GetKeywordStacks(victim, BONK_KEYWORD_BURNING))
        return;
    uint32 const now = WorldTimer::getMSTime();
    if (int32(now - m_lavaSurgeReadyMs) < 0)
        return;
    m_lavaSurgeReadyMs = now + BONK_LAVA_SURGE_GAP_MS;
    for (OwnedWeapon& owned : m_weapons)
        if (GetRootWeapon(owned.weapon) == BONK_WEAPON_LIGHTNING_BOLT)
            owned.timer = 0;
}

void BonkRun::OnShamanPetPulse(OwnedWeapon& owned, Creature* pet, float radius)
{
    if (GetRootWeapon(owned.weapon) == BONK_WEAPON_MAGMA_TOTEM && m_mastery.Special(BONK_SPECIAL_EARTHGRAB) > 0.0f)
        for (Creature* mob : GetMobsNear(pet->GetPositionX(), pet->GetPositionY(), radius))
            ApplyShamanKeyword(owned, mob, BONK_KEYWORD_DAZED, 1);

    if (owned.weapon.id == BONK_WEAPON_EARTHBIND)
        for (Creature* mob : GetMobsNear(pet->GetPositionX(), pet->GetPositionY(), radius))
            ApplyShamanKeyword(owned, mob, BONK_KEYWORD_DAZED, 1);

    if (owned.weapon.id != BONK_WEAPON_LIQUID_MAGMA)
        return;
    SpellEntry const* glob = sSpellMgr.GetSpellEntry(BONK_SPELL_MAGMA_GLOB);
    std::vector<Creature*> mobs = GetMobsNear(pet->GetPositionX(), pet->GetPositionY(), BONK_LIQUID_MAGMA_REACH);
    for (uint32 thrown = 0; thrown < BONK_LIQUID_MAGMA_GLOBS && !mobs.empty(); ++thrown)
    {
        size_t const pick = urand(0, uint32(mobs.size() - 1));
        Creature* mob = mobs[pick];
        mobs.erase(mobs.begin() + pick);
        if (glob)
            ShowStrike(pet, glob, mob);
        DealSpellHit(glob, mob, GetWeaponDamage(owned) * BONK_LIQUID_MAGMA_SHARE, pet);
        ApplyShamanKeyword(owned, mob, BONK_KEYWORD_BURNING, 1);
    }
}

bool BonkRun::IsLavaBurstOnBurning(SpellEntry const* spell, Unit const* victim) const
{
    if (!spell || !victim)
        return false;
    for (OwnedWeapon const& owned : m_weapons)
        if (owned.weapon.behavior == BONK_BEHAVIOR_LAVA_BURST && owned.weapon.spellId == spell->Id)
            return GetKeywordStacks(victim, BONK_KEYWORD_BURNING) > 0;
    return false;
}

float BonkRun::GetShamanDamageMultiplier(SpellEntry const* spell, Unit const* victim) const
{
    if (!victim || !spell || spell->School != SPELL_SCHOOL_FIRE)
        return 1.0f;
    for (OwnedWeapon const& owned : m_weapons)
    {
        if (owned.weapon.id != BONK_WEAPON_TOTEM_OF_WRATH)
            continue;
        Map* map = m_player->GetMap();
        for (ObjectGuid const& guid : owned.pets)
            if (Creature* totem = map->GetCreature(guid))
                if (totem->IsAlive() && victim->IsWithinDistInMap(totem, BONK_TOTEM_OF_WRATH_REACH))
                    return BONK_TOTEM_OF_WRATH_BONUS;
    }
    return 1.0f;
}

void BonkRun::ReplantTotems()
{
    if (!m_player->IsAlive())
        return;
    Map* map = m_player->GetMap();
    uint32 slot = 0;
    for (OwnedWeapon& owned : m_weapons)
    {
        if (!owned.weapon.HasFlag(BONK_WEAPON_FLAG_TOTEM))
            continue;
        bool const magma = GetRootWeapon(owned.weapon) == BONK_WEAPON_MAGMA_TOTEM;
        for (ObjectGuid& guid : owned.pets)
        {
            uint32 const ownSlot = slot++;
            Creature* totem = map->GetCreature(guid);
            if (!totem || !totem->IsAlive())
                continue;
            if (magma)
            {
                bool const reached = !GetMobsNear(totem->GetPositionX(), totem->GetPositionY(), GetMagmaPulseRadius(owned)).empty();
                auto idle = m_magmaIdleMs.find(guid);
                uint32 const idleMs = reached ? 0 : (idle == m_magmaIdleMs.end() ? BONK_MAGMA_IDLE_MS : idle->second + BONK_SHAMAN_TICK_MS);
                m_magmaIdleMs[guid] = idleMs;
                if (idleMs >= BONK_MAGMA_IDLE_MS || !totem->IsWithinDistInMap(m_player, BONK_MAGMA_LEASH))
                    HurlMagmaTotem(owned, guid, totem);
                continue;
            }
            if (totem->IsWithinDistInMap(m_player, BONK_TOTEM_REPLANT_RANGE))
                continue;
            float x, y, z;
            GetTotemSlot(ownSlot, x, y, z);
            PlantTotemAt(owned, guid, totem, x, y, z);
        }
    }
}

uint32 BonkRun::CountOwnedTotems() const
{
    uint32 count = 0;
    for (OwnedWeapon const& owned : m_weapons)
        if (owned.weapon.HasFlag(BONK_WEAPON_FLAG_TOTEM))
            count += uint32(owned.pets.size());
    return count;
}

void BonkRun::GetTotemSlot(uint32 slot, float& x, float& y, float& z) const
{
    float const angle = m_player->GetOrientation() + float(slot % BONK_TOTEM_SLOTS) * 2.0f * M_PI_F / float(BONK_TOTEM_SLOTS) + M_PI_F / float(BONK_TOTEM_SLOTS);
    x = m_player->GetPositionX() + BONK_TOTEM_SLOT_DISTANCE * std::cos(angle);
    y = m_player->GetPositionY() + BONK_TOTEM_SLOT_DISTANCE * std::sin(angle);
    z = m_player->GetPositionZ();
    m_player->GetMap()->GetWalkHitPosition(nullptr, m_player->GetPositionX(), m_player->GetPositionY(), m_player->GetPositionZ(), x, y, z);
}

void BonkRun::PlantTotemAt(OwnedWeapon& owned, ObjectGuid& guid, Creature* totem, float x, float y, float z)
{
    Creature* planted = SummonPet(owned, totem->GetEntry(), x, y, z, m_player->GetOrientation());
    if (!planted)
        return;
    planted->SetObjectScale(totem->GetObjectScale());
    planted->UpdateModelData();
    m_petStates.erase(guid);
    m_magmaIdleMs.erase(guid);
    totem->DespawnOrUnsummon();
    guid = planted->GetObjectGuid();
    m_magmaIdleMs[guid] = 0;
    m_player->SendPlaySpellVisualKit(BONK_KIT_TOTEM_DROP);
}

float BonkRun::GetMagmaPulseRadius(OwnedWeapon const& owned) const
{
    BonkPetFamily const* family = GetPetFamily(owned);
    if (!family)
        return 0.0f;
    for (BonkPetAbility const& ability : family->abilities)
        if (ability.kind == BONK_PET_ABILITY_PULSE)
            return ability.value * GetSummonReach(owned);
    return 0.0f;
}

Creature* BonkRun::FindMagmaPack(float radius) const
{
    std::vector<Creature*> mobs = GetMobsInRange(BONK_MAGMA_THROW_RANGE);
    Creature* best = nullptr;
    size_t bestCount = 0;
    for (Creature* center : mobs)
    {
        if (!m_player->IsWithinLOSInMap(center))
            continue;
        size_t const count = size_t(std::count_if(mobs.begin(), mobs.end(), [center, radius](Creature const* mob)
        {
            return mob->IsWithinDist(center, radius);
        }));
        if (count > bestCount)
        {
            best = center;
            bestCount = count;
        }
    }
    return best;
}

void BonkRun::HurlMagmaTotem(OwnedWeapon& owned, ObjectGuid& guid, Creature* totem)
{
    m_magmaIdleMs[guid] = 0;
    float x, y, z;
    if (Creature* pack = FindMagmaPack(GetMagmaPulseRadius(owned)))
    {
        pack->GetPosition(x, y, z);
        m_player->GetMap()->GetWalkHitPosition(nullptr, m_player->GetPositionX(), m_player->GetPositionY(), m_player->GetPositionZ(), x, y, z);
    }
    else if (totem->IsWithinDistInMap(m_player, BONK_TOTEM_REPLANT_RANGE))
        return;
    else
        GetTotemSlot(0, x, y, z);
    PlantTotemAt(owned, guid, totem, x, y, z);
}

void BonkRun::BurstFireNovaTotems()
{
    OwnedWeapon* nova = FindOwned(BONK_WEAPON_FIRE_NOVA_TOTEM);
    SpellEntry const* fire = sSpellMgr.GetSpellEntry(BONK_SPELL_FIRE_NOVA);
    if (!nova || !fire || !m_player->IsAlive())
        return;
    Map* map = m_player->GetMap();
    float const radius = GetWeaponRadius(*nova);
    for (ObjectGuid& guid : nova->pets)
    {
        Creature* totem = map->GetCreature(guid);
        if (!totem || !totem->IsAlive())
            continue;
        totem->SendPlaySpellVisualKit(BONK_KIT_FIRE_NOVA);
        for (Creature* mob : GetMobsNear(totem->GetPositionX(), totem->GetPositionY(), radius))
        {
            DealSpellHit(fire, mob, GetWeaponDamage(*nova) * BONK_FIRE_NOVA_SHARE, totem);
            ApplyShamanKeyword(*nova, mob, BONK_KEYWORD_BURNING, BONK_FIRE_NOVA_STACKS);
        }
        PlantTotemAt(*nova, guid, totem, m_player->GetPositionX(), m_player->GetPositionY(), m_player->GetPositionZ());
    }
}

void BonkRun::RainFromHealingTotems()
{
    OwnedWeapon const* rain = FindOwned(BONK_WEAPON_HEALING_RAIN);
    SpellEntry const* zap = sSpellMgr.GetSpellEntry(BONK_SPELL_LIGHTNING_ZAP);
    SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_HEALING_STREAM);
    if (!rain || !zap || !m_player->IsAlive())
        return;
    Map* map = m_player->GetMap();
    float const radius = GetWeaponRadius(*rain);
    for (ObjectGuid const& guid : rain->pets)
    {
        Creature* totem = map->GetCreature(guid);
        if (!totem || !totem->IsAlive())
            continue;
        for (Creature* mob : GetMobsNear(totem->GetPositionX(), totem->GetPositionY(), radius))
        {
            if (look)
                ShowStrike(totem, look, mob);
            DealSpellHit(zap, mob, GetWeaponDamage(*rain), totem);
        }
    }
}

float BonkRun::GetHealPercent(BonkWeapon const& weapon, float damageBonus)
{
    return weapon.healPct * (1.0f + damageBonus / 100.0f);
}

void BonkRun::FlowHealingStreams()
{
    if (!m_player->IsAlive() || m_player->GetHealth() >= m_player->GetMaxHealth())
        return;
    Map* map = m_player->GetMap();
    for (OwnedWeapon const& owned : m_weapons)
    {
        if (GetShamanPetFamily(owned) != BONK_PET_FAMILY_HEALING_STREAM_TOTEM)
            continue;
        float percent = 0.0f;
        for (ObjectGuid const& guid : owned.pets)
            if (Creature* totem = map->GetCreature(guid))
                if (totem->IsAlive() && totem->IsWithinDistInMap(m_player, BONK_HEALING_STREAM_RANGE))
                    percent += GetHealPercent(owned.weapon, owned.damageBonus);
        if (percent <= 0.0f)
            continue;
        SupportScope scope(*this, WeaponSupport(owned));
        HealHero(std::max(1u, uint32(m_player->GetMaxHealth() * percent / 100.0f)), BONK_SPELL_HEALING_STREAM);
    }
}

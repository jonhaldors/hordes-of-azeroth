#include "BonkRun.h"
#include "BonkLocale.h"
#include "BonkMobAI.h"
#include "BonkPlayer.h"
#include "BonkQuests.h"
#include "BonkRunStats.h"
#include "Chat.h"
#include "Creature.h"
#include "HoaProtocol.h"
#include "Player.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "Utilities/Random.h"
#include "WorldSession.h"

#include <algorithm>
#include <cstdio>
#include <limits>

namespace
{
    uint32 const BONK_GLYPH_PICKS      = 2;
    uint32 const BONK_GLYPH_CHOICES    = 4;
    uint32 const BONK_GLYPH_STILL_MS   = 500;
    uint32 const BONK_GLYPH_MIN_CLEAN  = 2;
    float const BONK_GLYPH_ODDS[MAX_BONK_RARITY] = { 55.0f, 30.0f, 11.0f, 3.5f, 0.5f };
    float const BONK_GLYPH_LUCK[MAX_BONK_RARITY] = { 0.0f, 0.5f, 1.0f, 1.5f, 2.0f };

    float const BONK_GLYPH_STRIKE_RANGE  = 35.0f;
    uint32 const BONK_SPELL_GLYPH_STORM  = 26415;
    uint32 const BONK_SPELL_GLYPH_METEOR = 20476;
    uint32 const BONK_KIT_LIGHTNING      = 283;
    uint32 const BONK_KIT_EXPLOSION      = 286;
    uint32 const BONK_KIT_FIRE_HIT       = 728;
    uint32 const BONK_KIT_SOUL_HARVEST   = 219;
    uint32 const BONK_KIT_FROST_NOVA     = 160;
    uint32 const BONK_KIT_SHADOW_HIT     = 2350;
    uint32 const BONK_KIT_CLEAVE_HIT     = 220;
    uint32 const BONK_SPELL_GLYPH_CORPSE = 17616;
    uint32 const BONK_SPELL_GLYPH_CLEAVE = 20569;
    uint32 const BONK_SPELL_GLYPH_SOULS  = 28447;
    uint32 const BONK_SPELL_RAISE_DEAD   = 28353;
    uint32 const BONK_SKELETON_ATTACK_MS = 1500;
    float const BONK_SKELETON_HUNT_RANGE = 30.0f;
    float const BONK_SKELETON_LEASH_RANGE = 60.0f;

    struct GlyphDamageSpell
    {
        BonkGlyphEffect effect;
        uint32 spellId;
    };

    GlyphDamageSpell const BONK_GLYPH_DAMAGE_SPELLS[] =
    {
        { BONK_GLYPH_STORM, BONK_SPELL_GLYPH_STORM },
        { BONK_GLYPH_METEOR, BONK_SPELL_GLYPH_METEOR },
        { BONK_GLYPH_CORPSE_BLAST, BONK_SPELL_GLYPH_CORPSE },
        { BONK_GLYPH_CLEAVE, BONK_SPELL_GLYPH_CLEAVE },
        { BONK_GLYPH_SHADOWMOURNE, BONK_SPELL_GLYPH_SOULS },
        { BONK_GLYPH_RAISE_DEAD, BONK_SPELL_RAISE_DEAD },
    };
    uint32 const BONK_SHADOWMOURNE_SHOW_STEP = 5;
    size_t const BONK_MAX_GLYPH_BURSTS   = 64;
    size_t const BONK_GLYPH_BURST_KITS   = 6;

    BonkMobAI const* GetGlyphAI(Unit const* unit)
    {
        Creature const* creature = unit ? unit->ToCreature() : nullptr;
        return creature ? dynamic_cast<BonkMobAI const*>(creature->AI()) : nullptr;
    }


    std::string FormatTimes(float times, LocaleConstant locale)
    {
        uint32 const whole = uint32(times + 0.5f);
        if (whole == 2)
            return sBonkLocale.GetString(BONK_STRING_TIMES_DOUBLE, locale);
        if (whole == 3)
            return sBonkLocale.GetString(BONK_STRING_TIMES_TRIPLE, locale);
        return sBonkLocale.GetString(BONK_STRING_TIMES_NORMAL, locale, { std::to_string(whole) });
    }
}

bool BonkRun::CanGainGlyphPick() const
{
    uint32 const picks = BONK_GLYPH_PICKS + (GetUtility(BONK_UTILITY_START_GLYPH) > 0.0f ? 1 : 0);
    return m_glyphPicksGiven + m_pendingGlyphPicks + uint32(m_glyphDrops.size()) < picks && !sBonkMgr.GetGlyphs().empty();
}

void BonkRun::QueueGlyphPick()
{
    if (!CanGainGlyphPick())
        return;
    ++m_pendingGlyphPicks;
    UpdateOffers();
}

BonkRarity BonkRun::RollGlyphRarity() const
{
    float const luck = std::max(0.0f, GetPassiveTotal(BONK_PASSIVE_LUCK));
    float weights[MAX_BONK_RARITY];
    float total = 0.0f;
    for (uint8 rarity = 0; rarity < MAX_BONK_RARITY; ++rarity)
    {
        weights[rarity] = BONK_GLYPH_ODDS[rarity] * (1.0f + BONK_GLYPH_LUCK[rarity] * luck / 100.0f);
        total += weights[rarity];
    }
    uint8 const lift = GetGlyph(BONK_GLYPH_GAMBLER) ? 1 : 0;
    float roll = frand(0.0f, total);
    for (uint8 rarity = 0; rarity < MAX_BONK_RARITY; ++rarity)
    {
        if (roll < weights[rarity])
            return BonkRarity(std::min<uint8>(rarity + lift, MAX_BONK_RARITY - 1));
        roll -= weights[rarity];
    }
    return BonkRarity(lift);
}

void BonkRun::OfferGlyphs()
{
    --m_pendingGlyphPicks;
    FillGlyphOffer({});
    ++m_glyphPicksGiven;
    if (m_glyphOffer.empty())
        return;
    SetPaused(true);
    SendGlyphOffer();
}

void BonkRun::FillGlyphOffer(std::vector<uint32> const& avoid)
{
    uint32 const account = m_player->GetBonkPlayer()->GetProgressAccount();
    std::vector<BonkGlyph const*> pool;
    for (auto const& itr : sBonkMgr.GetGlyphs())
    {
        BonkGlyph const& glyph = itr.second;
        if (!sBonkQuests.IsInPool(account, BONK_REWARD_GLYPH, glyph.id) ||
            std::find(m_glyphs.begin(), m_glyphs.end(), &glyph) != m_glyphs.end())
            continue;
        pool.push_back(&glyph);
    }
    if (pool.size() >= avoid.size() + BONK_GLYPH_CHOICES)
        pool.erase(std::remove_if(pool.begin(), pool.end(), [&avoid](BonkGlyph const* glyph)
        {
            return std::find(avoid.begin(), avoid.end(), glyph->id) != avoid.end();
        }), pool.end());

    m_glyphOffer.clear();
    uint32 clean = 0;
    while (m_glyphOffer.size() < BONK_GLYPH_CHOICES && !pool.empty())
    {
        uint32 const slotsLeft = BONK_GLYPH_CHOICES - uint32(m_glyphOffer.size());
        bool const needClean = clean < BONK_GLYPH_MIN_CLEAN && slotsLeft <= BONK_GLYPH_MIN_CLEAN - clean &&
            std::any_of(pool.begin(), pool.end(), [](BonkGlyph const* glyph) { return glyph->drawback.empty(); });
        BonkRarity const rolled = RollGlyphRarity();
        std::vector<size_t> picks;
        for (int32 distance = 0; distance < MAX_BONK_RARITY && picks.empty(); ++distance)
            for (size_t i = 0; i < pool.size(); ++i)
                if (std::abs(int32(pool[i]->rarity) - int32(rolled)) == distance && (!needClean || pool[i]->drawback.empty()))
                    picks.push_back(i);
        if (picks.empty())
            break;
        size_t const chosen = picks[urand(0, uint32(picks.size()) - 1)];
        if (pool[chosen]->drawback.empty())
            ++clean;
        m_glyphOffer.push_back(pool[chosen]->id);
        pool.erase(pool.begin() + chosen);
    }
}

bool BonkRun::RerollGlyphs(std::string& error)
{
    if (m_glyphOffer.empty())
    {
        error = GetString(BONK_STRING_THERE_IS_NOTHING_TO_REROLL);
        return false;
    }
    if (!m_glyphRerolls)
    {
        error = GetString(BONK_STRING_NO_GLYPH_REROLLS_LEFT);
        SendGlyphOffer();
        return false;
    }
    --m_glyphRerolls;
    std::vector<uint32> const previous = m_glyphOffer;
    FillGlyphOffer(previous);
    if (m_glyphOffer.empty())
        m_glyphOffer = previous;
    SendGlyphOffer();
    return true;
}

void BonkRun::SendGlyphOffer() const
{
    BonkPlayer* bonk = m_player->GetBonkPlayer();
    if (bonk->IsAddonReady())
    {
        WorldPacket offer(SMSG_HOA_MESSAGE);
        HoAWriteGlyphOffer(offer, m_glyphPicksGiven, m_glyphOffer.size(), m_glyphRerolls);
        m_player->GetSession()->SendPacket(&offer);
        for (size_t i = 0; i < m_glyphOffer.size(); ++i)
        {
            WorldPacket option(SMSG_HOA_MESSAGE);
            HoAWriteGlyphOption(option, i + 1, m_glyphOffer[i]);
            m_player->GetSession()->SendPacket(&option);
        }
        WorldPacket end(SMSG_HOA_MESSAGE);
        HoAWriteGlyphOfferEnd(end);
        m_player->GetSession()->SendPacket(&end);
        return;
    }

    ChatHandler handler(m_player);
    handler.SendSysMessage(GetString(BONK_STRING_GLYPH_OFFER_CHAT).c_str());
    for (size_t i = 0; i < m_glyphOffer.size(); ++i)
    {
        BonkGlyph const* glyph = sBonkMgr.GetGlyph(m_glyphOffer[i]);
        if (!glyph)
            continue;
        std::string const drawback = glyph->drawback.empty() ? std::string() :
            " " + GetString(BONK_STRING_GLYPH_DRAWBACK, { Localize(BONK_FIELD_GLYPH_DRAWBACK, glyph->id, glyph->drawback) });
        handler.PSendSysMessage("  %u) %s (%s): %s%s", uint32(i + 1), Localize(BONK_FIELD_GLYPH_NAME, glyph->id, glyph->name).c_str(),
            GetString(GetBonkRarityString(BonkRarity(glyph->rarity))).c_str(), Localize(BONK_FIELD_GLYPH_DESCRIPTION, glyph->id, glyph->description).c_str(),
            drawback.c_str());
    }
}

bool BonkRun::ChooseGlyph(uint32 choice, std::string& error)
{
    if (m_glyphOffer.empty())
    {
        error = GetString(BONK_STRING_THERE_IS_NO_GLYPH_TO);
        return false;
    }
    if (!choice || choice > m_glyphOffer.size())
    {
        error = GetString(BONK_STRING_CHOOSE_GLYPH_FROM_1_TO, { std::to_string(m_glyphOffer.size()) });
        return false;
    }

    BonkGlyph const* glyph = sBonkMgr.GetGlyph(m_glyphOffer[choice - 1]);
    m_glyphOffer.clear();
    BonkPlayer* bonk = m_player->GetBonkPlayer();
    if (bonk->IsAddonReady())
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteGlyphClose(data);
        m_player->GetSession()->SendPacket(&data);
    }
    if (glyph)
    {
        TakeGlyph(*glyph);
        bonk->Notify(BONK_STRING_YOU_CHOSE, { Localize(BONK_FIELD_GLYPH_NAME, glyph->id, glyph->name) });
    }

    ResumeUnlessChoiceOpen();
    UpdateOffers();
    return true;
}

void BonkRun::TakeGlyph(BonkGlyph const& glyph)
{
    m_glyphs.push_back(&glyph);
    if (BonkCard const* card = glyph.cardId ? sBonkMgr.GetCard(glyph.cardId) : nullptr)
    {
        m_glyphCardIds.insert(card->id);
        AddCard(*card);
    }
    switch (glyph.effect)
    {
        case BONK_GLYPH_STORM:
            m_glyphStormTimer = int32(glyph.values[0]);
            break;
        case BONK_GLYPH_METEOR:
            m_glyphMeteorTimer = int32(glyph.values[0]);
            break;
        case BONK_GLYPH_FORESIGHT:
            m_rerolls += uint32(glyph.values[0]);
            break;
        case BONK_GLYPH_TREASURE:
            m_glyphNextChestMs = m_elapsedMs + uint32(glyph.values[0]);
            break;
        case BONK_GLYPH_PRODIGY:
            RankUpStarter(uint32(glyph.values[0]));
            break;
        case BONK_GLYPH_DASH:
            m_player->GetBonkPlayer()->SendDash();
            break;
        default:
            break;
    }
    ApplyPassives();
    SendGlyphs();
    SendState();
}

void BonkRun::SendGlyphs() const
{
    std::string ids;
    for (BonkGlyph const* glyph : m_glyphs)
        ids += (ids.empty() ? "" : ",") + std::to_string(glyph->id);
    if (m_player->GetBonkPlayer()->IsAddonReady())
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteGlyphTaken(data, ids);
        m_player->GetSession()->SendPacket(&data);
    }
}

BonkGlyph const* BonkRun::GetGlyph(BonkGlyphEffect effect) const
{
    for (BonkGlyph const* glyph : m_glyphs)
        if (glyph->effect == effect)
            return glyph;
    return nullptr;
}

float BonkRun::GetGlyphValue(BonkGlyphEffect effect, uint8 index) const
{
    BonkGlyph const* glyph = GetGlyph(effect);
    return glyph && index < 3 ? glyph->values[index] : 0.0f;
}

float BonkRun::GetGlyphPower() const
{
    float power = 0.0f;
    BonkGlyph const* vengeance = GetGlyph(BONK_GLYPH_VENGEANCE);
    if (vengeance && vengeance->values[0] > 0.0f && m_player->GetMaxHealth())
        power += std::max(0.0f, (100.0f - m_player->GetHealthPercent()) / vengeance->values[0]);
    if (BonkGlyph const* siphon = GetGlyph(BONK_GLYPH_SOUL_SIPHON))
        if (siphon->values[0] >= 1.0f)
            power += float(m_soulSiphonKills / uint32(siphon->values[0])) * siphon->values[1];
    if (BonkGlyph const* nomad = GetGlyph(BONK_GLYPH_NOMAD))
    {
        if (m_player->HasAura(BONK_SPELL_NOMAD_AURA))
            power -= nomad->values[1];
        else if (!m_glyphStill)
            power += nomad->values[0];
    }
    return power;
}

bool BonkRun::IsLastStand() const
{
    BonkGlyph const* stand = GetGlyph(BONK_GLYPH_LAST_STAND);
    return stand && m_player->IsAlive() && m_player->GetHealthPercent() < stand->values[0];
}

float BonkRun::GetAmbitionReward(BonkSpawnKind kind) const
{
    return kind == BONK_SPAWN_MINIBOSS ? 1.0f + GetGlyphValue(BONK_GLYPH_AMBITION, 1) / 100.0f : 1.0f;
}

void BonkRun::RankUpStarter(uint32 ranks)
{
    if (!m_weapons.empty())
        RankUpWeapon(m_weapons.front(), ranks);
}

void BonkRun::RankUpWeapon(OwnedWeapon& owned, uint32 ranks)
{
    for (uint32 i = 0; i < ranks; ++i)
    {
        Offer offer;
        offer.id = owned.weapon.id;
        offer.newLevel = owned.rank + 1;
        offer.rarity = RollRarity(BONK_RARITY_COMMON);
        offer.step = BONK_STEP_RANK;
        RollUpgrades(owned, offer);
        ApplyStep(owned, offer);
    }
    ApplyPassives();
    SendLoadout();
}

void BonkRun::EchoRankPick(OwnedWeapon& owned, Offer const& offer)
{
    BonkGlyph const* echoes = GetGlyph(BONK_GLYPH_ECHOES);
    if (!echoes || offer.step != BONK_STEP_RANK || !roll_chance_f(echoes->values[0]))
        return;
    RankUpWeapon(owned, 1);
    m_player->GetBonkPlayer()->Notify(BONK_STRING_YOUR_GLYPH_OF_ECHOES_GIVES, { Localize(BONK_FIELD_WEAPON_NAME, owned.weapon.id, owned.weapon.name) });
}

bool BonkRun::IsGlyphBossStage() const
{
    return m_stage < m_tier.stages;
}

bool BonkRun::IsDivineShieldReady() const
{
    BonkGlyph const* shield = GetGlyph(BONK_GLYPH_DIVINE_SHIELD);
    if (!shield)
        return false;
    if (!m_divineShieldStage)
        return true;
    return shield->values[1] >= 1.0f && m_stage >= m_divineShieldStage + uint32(shield->values[1]);
}

std::string BonkRun::DescribeDivineShieldRecharge(BonkGlyph const& shield) const
{
    uint32 const stages = uint32(shield.values[1]);
    if (!stages)
        return GetString(BONK_STRING_DIVINE_SHIELD_NEVER);
    if (stages == 1)
        return GetString(BONK_STRING_DIVINE_SHIELD_NEXT_STAGE);
    return GetString(BONK_STRING_DIVINE_SHIELD_STAGES, { std::to_string(stages) });
}

bool BonkRun::IsProdigySpell(SpellEntry const* spell) const
{
    if (!spell || m_weapons.empty())
        return false;
    auto root = m_spellRoots.find(spell->Id);
    return root != m_spellRoots.end() && root->second == GetRootWeapon(m_weapons.front().weapon);
}

float BonkRun::GetGlyphDamageMultiplier(SpellEntry const* spell) const
{
    float multiplier = 1.0f - GetGlyphValue(BONK_GLYPH_MULTI_SHOT, 1) / 100.0f;
    if (IsProdigySpell(spell))
        multiplier *= 1.0f + GetGlyphValue(BONK_GLYPH_PRODIGY, 1) / 100.0f;
    return multiplier;
}

uint32 BonkRun::GetGlyphLevelChoices() const
{
    return uint32(GetGlyphValue(BONK_GLYPH_DIVINATION, 0));
}

uint32 BonkRun::GetVanishMs() const
{
    return uint32(GetGlyphValue(BONK_GLYPH_VANISH, 0));
}

void BonkRun::OnGlyphDash()
{
    if (GetGlyph(BONK_GLYPH_VANISH))
        m_vanishCritPending = true;
}

void BonkRun::TriggerGlyphNova()
{
    BonkGlyph const* nova = GetGlyph(BONK_GLYPH_FROST_NOVA);
    if (!nova || m_state != STATE_RUNNING || m_totalMs < m_glyphNovaReadyMs)
        return;
    m_glyphNovaReadyMs = m_totalMs + uint32(nova->values[1]);
    m_player->SendPlaySpellVisualKit(BONK_KIT_FROST_NOVA);
    for (Creature* mob : GetMobsInRange(nova->values[0]))
        if (BonkMobAI const* ai = GetGlyphAI(mob))
            if (ai->GetKind() == BONK_SPAWN_NORMAL)
                ApplyKeyword(mob, BONK_KEYWORD_FROZEN, 1, 0, 1.0f, 0);
}

void BonkRun::IgniteFromCrit(Creature* mob, uint32 spellId)
{
    if (BonkGlyph const* ignite = GetGlyph(BONK_GLYPH_IGNITE))
        ApplyKeyword(mob, BONK_KEYWORD_BURNING, uint32(ignite->values[0]), 0, 1.0f, spellId);
}

void BonkRun::QueueGlyphBurst(BonkGlyph const& glyph, float x, float y, float z, float radius, float damage, bool nearestOnly)
{
    if (m_glyphBursts.size() >= BONK_MAX_GLYPH_BURSTS || damage <= 0.0f)
        return;
    GlyphBurst burst;
    burst.effect = glyph.effect;
    burst.x = x;
    burst.y = y;
    burst.z = z;
    burst.radius = radius;
    burst.damage = damage;
    burst.nearestOnly = nearestOnly;
    m_glyphBursts.push_back(burst);
}

void BonkRun::ReleaseGlyphBursts()
{
    if (m_glyphBursts.empty() || m_state != STATE_RUNNING)
        return;
    std::vector<GlyphBurst> bursts;
    bursts.swap(m_glyphBursts);
    for (GlyphBurst const& burst : bursts)
    {
        uint32 spellId = BONK_SPELL_GLYPH_CORPSE, kit = BONK_KIT_EXPLOSION;
        if (burst.effect == BONK_GLYPH_CLEAVE)
            spellId = BONK_SPELL_GLYPH_CLEAVE, kit = BONK_KIT_CLEAVE_HIT;
        else if (burst.effect == BONK_GLYPH_SHADOWMOURNE)
            spellId = BONK_SPELL_GLYPH_SOULS, kit = BONK_KIT_SHADOW_HIT;
        SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(spellId);
        std::vector<Creature*> mobs = GetMobsNear(burst.x, burst.y, burst.radius);
        if (!spellInfo || mobs.empty())
            continue;
        if (burst.nearestOnly)
            mobs.resize(1);
        for (size_t i = 0; i < mobs.size() && i < BONK_GLYPH_BURST_KITS; ++i)
            mobs[i]->SendPlaySpellVisualKit(kit);
        m_cardProc = true;
        for (Creature* mob : mobs)
        {
            if (burst.effect == BONK_GLYPH_CLEAVE || burst.effect == BONK_GLYPH_CORPSE_BLAST)
                DealCarriedDamage(spellInfo, mob, burst.damage * GetHealthScale(mob));
            else
                DealSpellHit(spellInfo, mob, burst.damage);
        }
        m_cardProc = false;
    }
}

void BonkRun::DealCarriedDamage(SpellEntry const* spellInfo, Unit* target, float damage)
{
    if (!target->IsAlive() || damage < 1.0f || !m_player->IsAlive())
        return;
    SpellNonMeleeDamage hit(m_player, target, spellInfo->Id, SpellSchools(spellInfo->School));
    hit.damage = uint32(std::min(damage, float(std::numeric_limits<int32>::max())));
    m_player->DealDamageMods(target, hit.damage, &hit.absorb);
    m_player->SendSpellNonMeleeDamageLog(&hit);
    m_player->DealSpellDamage(&hit, true);
}

void BonkRun::RaiseSkeleton(Creature const* corpse)
{
    BonkGlyph const* raise = GetGlyph(BONK_GLYPH_RAISE_DEAD);
    if (!raise || m_state != STATE_RUNNING)
        return;
    Map* map = m_player->GetMap();
    while (!m_skeletons.empty() && m_skeletons.size() >= std::max(1u, uint32(raise->values[1])))
    {
        if (Creature* oldest = map->GetCreature(m_skeletons.front().guid))
            oldest->DespawnOrUnsummon();
        m_skeletons.erase(m_skeletons.begin());
    }

    Creature* skeleton = SummonGlyphHelper(BONK_SKELETON, corpse->GetPositionX(), corpse->GetPositionY(), corpse->GetPositionZ(), corpse->GetOrientation());
    if (!skeleton)
        return;
    skeleton->SetUInt32Value(UNIT_CREATED_BY_SPELL, BONK_SPELL_RAISE_DEAD);
    skeleton->SetHealth(skeleton->GetMaxHealth());
    skeleton->SetInvincibilityHpThreshold(skeleton->GetMaxHealth());
    RisenSkeleton risen;
    risen.guid = skeleton->GetObjectGuid();
    risen.untilMs = m_totalMs + uint32(raise->values[0]);
    m_skeletons.push_back(risen);
    DressSkeletons();
}

void BonkRun::DressSkeletons()
{
    BonkGlyph const* raise = GetGlyph(BONK_GLYPH_RAISE_DEAD);
    if (!raise)
        return;
    Map* map = m_player->GetMap();
    float const bite = GetProcBaseHealth() * raise->values[2] / 100.0f;
    float const speed = GetPetRunSpeed();
    for (RisenSkeleton const& risen : m_skeletons)
    {
        Creature* skeleton = map->GetCreature(risen.guid);
        if (!skeleton || !skeleton->IsAlive())
            continue;
        if (skeleton->GetBaseRunSpeedRate() != speed)
            skeleton->SetBaseSpeedRate(MOVE_RUN, speed);
        skeleton->SetBaseWeaponDamage(BASE_ATTACK, MINDAMAGE, bite * 0.9f);
        skeleton->SetBaseWeaponDamage(BASE_ATTACK, MAXDAMAGE, bite * 1.1f);
        skeleton->UpdateDamagePhysical(BASE_ATTACK);
        skeleton->SetAttackTime(BASE_ATTACK, BONK_SKELETON_ATTACK_MS, false);
    }
}

void BonkRun::UpdateSkeletons()
{
    if (m_skeletons.empty())
        return;
    Map* map = m_player->GetMap();
    bool const kept = GetGlyph(BONK_GLYPH_RAISE_DEAD) != nullptr;
    m_skeletons.erase(std::remove_if(m_skeletons.begin(), m_skeletons.end(), [this, map, kept](RisenSkeleton const& risen)
    {
        Creature* skeleton = map->GetCreature(risen.guid);
        if (skeleton && skeleton->IsAlive() && kept && int32(risen.untilMs - m_totalMs) > 0)
            return false;
        if (skeleton)
            skeleton->DespawnOrUnsummon();
        return true;
    }), m_skeletons.end());
    if (m_paused)
        return;

    DressSkeletons();
    for (RisenSkeleton const& risen : m_skeletons)
    {
        Creature* skeleton = map->GetCreature(risen.guid);
        if (!skeleton)
            continue;
        if (!skeleton->IsWithinDistInMap(m_player, BONK_SKELETON_LEASH_RANGE))
        {
            skeleton->AttackStop();
            skeleton->NearTeleportTo(m_player->GetPositionX(), m_player->GetPositionY(), m_player->GetPositionZ(), m_player->GetOrientation());
            continue;
        }
        Unit* victim = skeleton->GetVictim();
        if (victim && victim->IsAlive())
            continue;
        Creature* target = nullptr;
        float best = 0.0f;
        for (Creature* mob : GetMobsInRange(BONK_SKELETON_HUNT_RANGE))
        {
            float const distance = skeleton->GetDistance(mob);
            if (!target || distance < best)
            {
                target = mob;
                best = distance;
            }
        }
        if (target)
            skeleton->AI()->AttackStart(target);
        else if (skeleton->GetMotionMaster()->GetCurrentMovementGeneratorType() != FOLLOW_MOTION_TYPE)
        {
            skeleton->AttackStop();
            skeleton->GetMotionMaster()->Clear(false);
            skeleton->GetMotionMaster()->MoveFollow(m_player, 2.0f, frand(0.0f, 2.0f * M_PI_F));
        }
    }
}

void BonkRun::DespawnSkeletons()
{
    if (Map* map = m_player->FindMap())
        for (RisenSkeleton const& risen : m_skeletons)
            if (Creature* skeleton = map->GetCreature(risen.guid))
                skeleton->DespawnOrUnsummon();
    m_skeletons.clear();
}

bool BonkRun::IsSkeleton(ObjectGuid const& guid) const
{
    return std::any_of(m_skeletons.begin(), m_skeletons.end(), [&guid](RisenSkeleton const& risen) { return risen.guid == guid; });
}

std::string BonkRun::DescribeGlyphStats() const
{
    std::string text;
    for (GlyphDamageSpell const& source : BONK_GLYPH_DAMAGE_SPELLS)
        if (BonkGlyph const* glyph = GetGlyph(source.effect))
        {
            BonkRunStats::Spell const totals = BonkStats::GetSpellStats(m_player->GetObjectGuid(), source.spellId);
            if (totals.damage)
                text += std::to_string(glyph->id) + ":" + std::to_string(totals.damage) + ":" + std::to_string(totals.kills) + ":" +
                    BonkStats::DescribeDamageTypes(m_player->GetObjectGuid(), source.spellId) + ",";
        }
    return text;
}

void BonkRun::AddGlyphMeterSpells(std::set<uint32>& shown) const
{
    for (GlyphDamageSpell const& source : BONK_GLYPH_DAMAGE_SPELLS)
        if (GetGlyph(source.effect))
            shown.insert(source.spellId);
}

std::string BonkRun::DescribeGlyphTotals(BonkGlyph const& glyph) const
{
    std::string text = std::to_string(glyph.id);
    for (GlyphDamageSpell const& source : BONK_GLYPH_DAMAGE_SPELLS)
        if (source.effect == glyph.effect)
        {
            BonkRunStats::Spell const totals = BonkStats::GetSpellStats(m_player->GetObjectGuid(), source.spellId);
            text += ":" + std::to_string(totals.damage) + ":" + std::to_string(totals.kills);
        }
    return text;
}

void BonkRun::UpdateShadowmourne()
{
    BonkGlyph const* mourne = GetGlyph(BONK_GLYPH_SHADOWMOURNE);
    if (!mourne || mourne->values[0] < 1.0f)
        return;
    ++m_shadowmourneSouls;
    if (m_shadowmourneSouls >= uint32(mourne->values[0]))
    {
        m_shadowmourneSouls = 0;
        m_player->SendPlaySpellVisualKit(BONK_KIT_SOUL_HARVEST);
        QueueGlyphBurst(*mourne, m_player->GetPositionX(), m_player->GetPositionY(), m_player->GetPositionZ(), mourne->values[2],
            GetProcBaseHealth() * mourne->values[1], false);
    }
    if (m_shadowmourneSouls / BONK_SHADOWMOURNE_SHOW_STEP != m_shadowmourneShown)
    {
        m_shadowmourneShown = m_shadowmourneSouls / BONK_SHADOWMOURNE_SHOW_STEP;
        if (m_player->GetBonkPlayer()->IsAddonReady())
        {
            WorldPacket data(SMSG_HOA_MESSAGE);
            HoAWriteGlyphCount(data, mourne->id, m_shadowmourneSouls);
            m_player->GetSession()->SendPacket(&data);
        }
    }
}

void BonkRun::UpdateGlyphStances()
{
    if (m_player->IsMoving())
        m_glyphMovedMs = m_totalMs;
    bool const still = m_totalMs - m_glyphMovedMs >= BONK_GLYPH_STILL_MS;
    bool const lastStand = IsLastStand();
    bool const penalty = m_player->HasAura(BONK_SPELL_NOMAD_AURA);
    if (still == m_glyphStill && lastStand == m_glyphLastStand && penalty == m_nomadPenalty)
        return;
    m_glyphStill = still;
    m_glyphLastStand = lastStand;
    m_nomadPenalty = penalty;
    if (GetGlyph(BONK_GLYPH_LAST_STAND))
        ApplyPassives();
}

void BonkRun::UpdateGlyphChest()
{
    BonkGlyph const* treasure = GetGlyph(BONK_GLYPH_TREASURE);
    if (!treasure || treasure->values[0] < 1.0f || m_state != STATE_RUNNING || m_elapsedMs < m_glyphNextChestMs)
        return;
    if (!SpawnChestNearby())
        return;
    m_glyphNextChestMs = m_elapsedMs + uint32(treasure->values[0]);
    m_player->GetBonkPlayer()->Notify(BONK_STRING_YOUR_GLYPH_OF_TREASURE_HUNTER);
}

void BonkRun::OnGlyphKill(Creature const* mob, BonkSpawnKind kind)
{
    if (m_glyphs.empty())
        return;
    BonkPlayer* bonk = m_player->GetBonkPlayer();

    if (BonkGlyph const* wind = GetGlyph(BONK_GLYPH_SECOND_WIND))
        if (kind != BONK_SPAWN_NORMAL && m_player->IsWithinDistInMap(mob, wind->values[1]))
        {
            SupportScope scope(*this, { wind->icon, Localize(BONK_FIELD_GLYPH_NAME, wind->id, wind->name) });
            HealHero(ReduceHealing(uint32(std::max(1.0f, m_player->GetMaxHealth() * wind->values[0] / 100.0f))));
        }

    ++m_glyphKills;
    if (GetGlyph(BONK_GLYPH_SOUL_SIPHON))
        ++m_soulSiphonKills;
    UpdateShadowmourne();
    if (kind == BONK_SPAWN_ELITE && GetGlyph(BONK_GLYPH_RAISE_DEAD))
        RaiseSkeleton(mob);
    if (BonkGlyph const* corpse = GetGlyph(BONK_GLYPH_CORPSE_BLAST))
        if (roll_chance_f(corpse->values[0]))
            QueueGlyphBurst(*corpse, mob->GetPositionX(), mob->GetPositionY(), mob->GetPositionZ(), corpse->values[2],
                GetTrueAmount(mob, mob->GetMaxHealth()) * corpse->values[1] / 100.0f, false);

    if (BonkGlyph const* lust = GetGlyph(BONK_GLYPH_KILL_HASTE))
        if (lust->values[0] >= 1.0f && m_glyphKills % uint32(lust->values[0]) == 0)
        {
            if (SpellAuraHolder* holder = m_player->AddAura(BONK_SPELL_GLYPH_HASTE_AURA, ADD_AURA_POSITIVE))
            {
                int32 const duration = int32(lust->values[2]);
                holder->SetAuraDuration(duration);
                holder->SetAuraMaxDuration(duration);
                holder->UpdateAuraDuration();
            }
            bonk->Notify(BONK_STRING_GLYPH_OF_BLOODLUST_AWAKENS, { FormatBonkNumber(lust->values[1]), FormatBonkNumber(lust->values[2] / 1000.0f) });
        }

    if (BonkGlyph const* harvest = GetGlyph(BONK_GLYPH_SOUL_HARVEST))
        if (harvest->values[0] >= 1.0f && m_glyphKills % uint32(harvest->values[0]) == 0)
        {
            if (SpellAuraHolder* holder = m_player->AddAura(BONK_SPELL_SOUL_HARVEST_AURA, ADD_AURA_POSITIVE))
            {
                int32 const duration = int32(harvest->values[2]);
                holder->SetAuraDuration(duration);
                holder->SetAuraMaxDuration(duration);
                holder->UpdateAuraDuration();
            }
            m_player->SendPlaySpellVisualKit(BONK_KIT_SOUL_HARVEST);
            bonk->Notify(BONK_STRING_YOUR_GLYPH_OF_SOUL_HARVEST, { FormatTimes(harvest->values[1], GetLocale()), std::to_string(uint32(harvest->values[2] / IN_MILLISECONDS + 0.5f)) });
        }
}

void BonkRun::ModifyGlyphHit(Unit* victim, uint32& damage)
{
    if (!damage)
        return;
    if (m_player->HasAura(BONK_SPELL_SOUL_HARVEST_AURA))
        if (BonkGlyph const* harvest = GetGlyph(BONK_GLYPH_SOUL_HARVEST))
            damage = uint32(damage * harvest->values[1]);

    BonkMobAI const* ai = GetGlyphAI(victim);
    if (!ai)
        return;
    float const health = float(victim->GetHealth());
    if (BonkGlyph const* execute = GetGlyph(BONK_GLYPH_EXECUTE))
    {
        if (ai->GetKind() == BONK_SPAWN_NORMAL)
        {
            if (health > damage && (health - damage) * 100.0f < victim->GetMaxHealth() * execute->values[0])
                damage = victim->GetHealth();
        }
        else if (victim->GetHealthPercent() < execute->values[1])
            damage = uint32(damage * (1.0f + execute->values[2] / 100.0f));
    }
    if (BonkGlyph const* cleave = GetGlyph(BONK_GLYPH_CLEAVE))
        if (damage > health)
            QueueGlyphBurst(*cleave, victim->GetPositionX(), victim->GetPositionY(), victim->GetPositionZ(), cleave->values[0],
                float(GetTrueAmount(victim, damage - health)), true);
}

void BonkRun::UpdateGlyphs(uint32 diff)
{
    UpdateGlyphStances();
    UpdateGlyphChest();
    ReleaseGlyphBursts();
    if (BonkGlyph const* storm = GetGlyph(BONK_GLYPH_STORM))
    {
        m_glyphStormTimer -= int32(diff);
        if (m_glyphStormTimer <= 0)
        {
            m_glyphStormTimer = int32(storm->values[0]);
            StrikeStorm(*storm);
        }
    }
    if (BonkGlyph const* meteor = GetGlyph(BONK_GLYPH_METEOR))
    {
        m_glyphMeteorTimer -= int32(diff);
        if (m_glyphMeteorTimer <= 0)
        {
            m_glyphMeteorTimer = int32(meteor->values[0]);
            DropMeteor(*meteor);
        }
    }
}

void BonkRun::StrikeStorm(BonkGlyph const& glyph)
{
    SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(BONK_SPELL_GLYPH_STORM);
    std::vector<Creature*> mobs = GetMobsInRange(BONK_GLYPH_STRIKE_RANGE);
    if (!spellInfo || mobs.empty())
        return;
    for (size_t i = mobs.size(); i > 1; --i)
        std::swap(mobs[i - 1], mobs[urand(0, uint32(i) - 1)]);
    float const damage = GetProcBaseHealth() * glyph.values[2];
    for (size_t i = 0; i < mobs.size() && i < size_t(glyph.values[1]); ++i)
    {
        mobs[i]->SendPlaySpellVisualKit(BONK_KIT_LIGHTNING);
        DealSpellHit(spellInfo, mobs[i], damage, nullptr, true);
    }
}

void BonkRun::DropMeteor(BonkGlyph const& glyph)
{
    SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(BONK_SPELL_GLYPH_METEOR);
    std::vector<Creature*> const mobs = GetMobsInRange(BONK_GLYPH_STRIKE_RANGE);
    if (!spellInfo || mobs.empty())
        return;
    float const radius = glyph.values[2];
    Creature* centre = nullptr;
    size_t best = 0;
    for (Creature* mob : mobs)
    {
        size_t const crowd = size_t(std::count_if(mobs.begin(), mobs.end(), [mob, radius](Creature const* other)
            { return other->GetDistance2d(mob) <= radius; }));
        if (!centre || crowd > best)
        {
            centre = mob;
            best = crowd;
        }
    }

    float const damage = GetProcBaseHealth() * glyph.values[1];
    centre->SendPlaySpellVisualKit(BONK_KIT_EXPLOSION);
    std::vector<Creature*> struck;
    for (Creature* mob : mobs)
        if (mob->GetDistance2d(centre) <= radius)
            struck.push_back(mob);
    for (Creature* mob : struck)
    {
        if (mob != centre)
            mob->SendPlaySpellVisualKit(BONK_KIT_FIRE_HIT);
        DealSpellHit(spellInfo, mob, damage);
    }
}

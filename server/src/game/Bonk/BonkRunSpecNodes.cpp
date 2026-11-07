#include "BonkRun.h"
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
    uint32 const BONK_WEAPON_EXECUTE           = 305;
    uint32 const BONK_WEAPON_ARCANE_MISSILES   = 409;
    uint32 const BONK_WEAPON_SHURIKEN_TOSS     = 608;
    uint32 const BONK_WEAPON_LIGHTNING_BOLT    = 700;
    uint32 const BONK_WEAPON_IMP               = 900;
    uint32 const BONK_WEAPON_FELHUNTER         = 903;
    float const BONK_DOT_CRIT_SHARE            = 0.5f;
    uint32 const BONK_THUNDER_SHIELD_HITS      = 5;
    uint32 const BONK_HAMMER_EXPOSE_MS         = 4000;
    uint32 const BONK_SHURIKEN_AMBUSH_EVERY_MS = 6000;
    float const BONK_MARK_PASS_RADIUS          = 20.0f;
    float const BONK_ROOT_SPREAD_RADIUS        = 8.0f;
    int32 const BONK_ROOT_SPREAD_MS            = 2000;
    float const BONK_MISSILE_SPLIT_RADIUS      = 8.0f;
    float const BONK_DEMON_CLEAVE_RADIUS       = 5.0f;
    uint32 const BONK_DEMON_CLEAVES_PER_SEC    = 4;
    size_t const BONK_SPEC_NODE_PRUNE_SIZE     = 256;

    template <typename Pick>
    Creature* NearestOther(std::vector<Creature*> const& mobs, Creature const* from, Pick pick)
    {
        Creature* nearest = nullptr;
        float best = 0.0f;
        for (Creature* mob : mobs)
        {
            if (mob == from || !mob->IsAlive() || !pick(mob))
                continue;
            float const distance = from->GetDistance(mob);
            if (!nearest || distance < best)
            {
                nearest = mob;
                best = distance;
            }
        }
        return nearest;
    }

    void PruneExpired(std::map<ObjectGuid, uint32>& untilByMob, uint32 now)
    {
        if (untilByMob.size() <= BONK_SPEC_NODE_PRUNE_SIZE)
            return;
        for (auto itr = untilByMob.begin(); itr != untilByMob.end();)
            itr = int32(itr->second - now) <= 0 ? untilByMob.erase(itr) : std::next(itr);
    }
}

float BonkRun::RollDotCrit(Unit const* victim, uint32 spellId) const
{
    if (m_mastery.keywordCrit.empty())
        return 1.0f;
    BonkKeywordInfo const* info = sBonkMgr.GetKeywordBySpell(spellId);
    if (!info || !info->IsDamageOverTime() || !m_mastery.keywordCrit.count(info->id))
        return 1.0f;
    if (!roll_chance_f(GetCritChance(nullptr, victim)))
        return 1.0f;
    float const full = (1.0f + GetCritBonus(false, victim)) * (1.0f + GetCapstoneCritDamage(nullptr));
    return 1.0f + (full - 1.0f) * BONK_DOT_CRIT_SHARE;
}

void BonkRun::OnSpellKill(uint32 spellId)
{
    auto root = m_spellRoots.find(spellId);
    if (m_state != STATE_RUNNING || root == m_spellRoots.end())
        return;
    if (root->second == BONK_WEAPON_EXECUTE && m_mastery.Special(BONK_SPECIAL_EXECUTE_ENRAGE) > 0.0f)
        Enrage();
    if (root->second == BONK_WEAPON_PENANCE)
        ShortenPenance(int32(m_mastery.Special(BONK_SPECIAL_PENANCE_KILL_COOLDOWN)));
}

void BonkRun::ShortenPenance(int32 ms)
{
    if (ms <= 0)
        return;
    for (OwnedWeapon& owned : m_weapons)
        if (owned.weapon.behavior == BONK_BEHAVIOR_PENANCE)
            owned.timer = std::max<int32>(0, owned.timer - ms);
}

void BonkRun::OnSummonKill(Unit* summon, Unit* victim)
{
    float const share = m_mastery.Special(BONK_SPECIAL_DEMON_CLEAVE);
    Creature* dead = victim ? victim->ToCreature() : nullptr;
    if (m_state != STATE_RUNNING || share <= 0.0f || !dead)
        return;
    OwnedWeapon const* owner = FindSummonOwner(summon);
    uint32 const root = owner ? GetRootWeapon(owner->weapon) : 0;
    if (root < BONK_WEAPON_IMP || root > BONK_WEAPON_FELHUNTER || !TakeRateSlot(m_demonCleaveTimes, BONK_DEMON_CLEAVES_PER_SEC))
        return;
    SpellEntry const* look = sSpellMgr.GetSpellEntry(owner->weapon.spellId);
    float const damage = GetWeaponDamage(*owner) * share / 100.0f;
    for (Creature* mob : GetMobsNear(dead->GetPositionX(), dead->GetPositionY(), BONK_DEMON_CLEAVE_RADIUS))
        if (mob != dead)
            DealShamanHit(look, owner->weapon.spellId, mob, damage);
}

void BonkRun::OnSpecNodeDamage(uint32 root, bool crit, Unit* victim, SpellEntry const* spell)
{
    if (IsPeriodicHit())
        return;
    if (root == BONK_WEAPON_THUNDER_CLAP && m_mastery.Special(BONK_SPECIAL_THUNDER_SHIELD) > 0.0f)
        GrantThunderShield();
    if (root == BONK_WEAPON_LIGHTS_HAMMER && m_mastery.Special(BONK_SPECIAL_HAMMER_EXPOSE) > 0.0f)
        ExposeToHammer(victim);

    Creature* mob = victim->ToCreature();
    if (!crit || !mob || !mob->IsAlive())
        return;
    switch (root)
    {
        case BONK_WEAPON_JUDGEMENT:
            if (m_mastery.Special(BONK_SPECIAL_JUDGEMENT_COMMAND) > 0.0f)
                BurstSealOfCommand(mob);
            break;
        case BONK_WEAPON_SHURIKEN_TOSS:
            if (m_mastery.Special(BONK_SPECIAL_SHURIKEN_AMBUSH) > 0.0f)
                AmbushFromShuriken(mob);
            break;
        case BONK_WEAPON_PENANCE:
            if (float const percent = m_mastery.Special(BONK_SPECIAL_PENANCE_SHIELD))
                AddSpellShield(uint32(m_player->GetMaxHealth() * percent / 100.0f));
            break;
        case BONK_WEAPON_LIGHTNING_BOLT:
            if (uint32 const stacks = uint32(m_mastery.Special(BONK_SPECIAL_BOLT_STATIC)))
            {
                PendingKeyword charge;
                charge.mob = mob->GetObjectGuid();
                charge.keyword = BONK_KEYWORD_STATIC;
                charge.stacks = uint8(stacks);
                charge.spellId = spell->Id;
                m_pendingKeywords.push_back(charge);
            }
            break;
        case BONK_WEAPON_STORMSTRIKE:
            if (m_mastery.Special(BONK_SPECIAL_STORMSTRIKE_WINDFURY) > 0.0f)
                StormstrikeWindfury(mob);
            break;
        default:
            break;
    }
}

void BonkRun::OnSpecNodeKill(Creature* dead)
{
    if (!dead)
        return;
    if (m_mastery.Special(BONK_SPECIAL_MARK_TRANSFER) > 0.0f)
        PassMarkOn(dead);
    if (m_mastery.Special(BONK_SPECIAL_ROOT_SPREAD) > 0.0f)
        SpreadRoots(dead);
}

void BonkRun::GrantThunderShield()
{
    if (m_thunderShieldAtMs != m_totalMs)
    {
        m_thunderShieldAtMs = m_totalMs;
        m_thunderShieldHits = 0;
    }
    if (m_thunderShieldHits >= BONK_THUNDER_SHIELD_HITS)
        return;
    ++m_thunderShieldHits;
    AddSpellShield(uint32(m_player->GetMaxHealth() * m_mastery.Special(BONK_SPECIAL_THUNDER_SHIELD) / 100.0f));
}

void BonkRun::ExposeToHammer(Unit* victim)
{
    ApplyTimedAuraTo(victim, BONK_SPELL_HAMMER_EXPOSED, BONK_HAMMER_EXPOSE_MS, ADD_AURA_NEGATIVE);
}

bool BonkRun::IsExposedToHammer(Unit const* victim) const
{
    return victim && victim->GetSpellAuraHolder(BONK_SPELL_HAMMER_EXPOSED, m_player->GetObjectGuid());
}

void BonkRun::AmbushFromShuriken(Creature* mob)
{
    PruneExpired(m_shurikenAmbushReady, m_totalMs);
    uint32& readyMs = m_shurikenAmbushReady[mob->GetObjectGuid()];
    if (int32(readyMs - m_totalMs) > 0)
        return;
    readyMs = m_totalMs + BONK_SHURIKEN_AMBUSH_EVERY_MS;
    OpenOnRogueTarget(mob, true);
}

void BonkRun::StormstrikeWindfury(Creature* mob)
{
    if (m_stormWindfuryAtMs == m_totalMs)
        return;
    m_stormWindfuryAtMs = m_totalMs;
    if (OwnedWeapon const* windfury = FindOwnedByBehavior(BONK_BEHAVIOR_WINDFURY))
        QueueWindfury(*windfury, mob, 1.0f);
}

void BonkRun::PassMarkOn(Creature const* dead)
{
    if (!GetKeywordStacks(dead, BONK_KEYWORD_HUNTERS_MARK))
        return;
    std::vector<Creature*> const mobs = GetMobsNear(dead->GetPositionX(), dead->GetPositionY(), BONK_MARK_PASS_RADIUS);
    Creature* next = NearestOther(mobs, dead, [this](Creature* mob) { return !GetKeywordStacks(mob, BONK_KEYWORD_HUNTERS_MARK); });
    if (!next)
        return;
    PendingKeyword mark;
    mark.mob = next->GetObjectGuid();
    mark.keyword = BONK_KEYWORD_HUNTERS_MARK;
    mark.stacks = 1;
    m_pendingKeywords.push_back(mark);
}

void BonkRun::SpreadRoots(Creature const* dead)
{
    Unit::AuraList const& roots = dead->GetAurasByType(SPELL_AURA_MOD_ROOT);
    if (roots.empty())
        return;
    SpellEntry const* rootInfo = roots.front()->GetSpellProto();
    std::vector<Creature*> const mobs = GetMobsNear(dead->GetPositionX(), dead->GetPositionY(), BONK_ROOT_SPREAD_RADIUS);
    Creature* next = NearestOther(mobs, dead, [](Creature* mob) { return !mob->HasAuraType(SPELL_AURA_MOD_ROOT); });
    int32 durationMs = BONK_ROOT_SPREAD_MS;
    if (next && rootInfo && LimitRoot(next, durationMs))
        HoldMob(next, rootInfo, SPELL_AURA_MOD_ROOT, durationMs);
}

void BonkRun::QueueThawChill(Creature const* mob, uint32 thawMs)
{
    if (m_mastery.Special(BONK_SPECIAL_THAW_CHILL) > 0.0f)
        m_thaws.emplace_back(mob->GetObjectGuid(), thawMs);
}

void BonkRun::UpdateThaws()
{
    if (m_thaws.empty())
        return;
    uint32 const now = WorldTimer::getMSTime();
    uint32 const stacks = uint32(m_mastery.Special(BONK_SPECIAL_THAW_CHILL));
    std::vector<std::pair<ObjectGuid, uint32>> thaws;
    thaws.swap(m_thaws);
    Map* map = m_player->GetMap();
    for (auto const& thaw : thaws)
    {
        if (int32(thaw.second - now) > 0)
        {
            m_thaws.push_back(thaw);
            continue;
        }
        Creature* mob = map->GetCreature(thaw.first);
        if (mob && mob->IsAlive() && stacks)
            ApplyKeyword(mob, BONK_KEYWORD_CHILL, stacks);
    }
}

void BonkRun::SplitCriticalMissile(OwnedWeapon& owned, SpellEntry const* spellInfo, Creature* target, float share)
{
    uint32 const splits = uint32(m_mastery.Special(BONK_SPECIAL_MISSILE_SPLIT));
    if (!splits || GetRootWeapon(owned.weapon) != BONK_WEAPON_ARCANE_MISSILES)
        return;
    uint32 struck = 0;
    for (Creature* mob : GetMobsNear(target->GetPositionX(), target->GetPositionY(), BONK_MISSILE_SPLIT_RADIUS))
        if (mob != target && mob->IsAlive() && struck < splits)
        {
            StrikeWith(owned, spellInfo, mob, share, true);
            ++struck;
        }
}

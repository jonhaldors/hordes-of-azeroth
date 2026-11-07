#include "BonkRun.h"
#include "BonkMobAI.h"
#include "BonkPlayer.h"
#include "BonkRunStats.h"
#include "Creature.h"
#include "HoaProtocol.h"
#include "Map.h"
#include "Player.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "WorldSession.h"

#include <algorithm>

namespace
{
    uint32 const BONK_MAX_HOLD_MS            = 2000;
    uint32 const BONK_HOLD_IMMUNE_MS         = 6000;
    uint32 const BONK_PULL_IMMUNE_MS         = 3000;
    float const BONK_KEYWORD_SPREAD_RANGE    = 8.0f;
    uint32 const BONK_KEYWORD_SPREAD_TARGETS = 2;
    uint32 const BONK_MAX_DOT_STACKS         = 30;
    uint32 const BONK_DOT_CHECK_MS           = 200;
    float const BONK_MAX_HUNTERS_MARK        = 30.0f;
    float const BONK_MARK_SPREAD_RANGE       = 10.0f;
    float const BONK_SLOWED_DAMAGE           = 5.0f;
    float const BONK_MAX_SLOWED_DAMAGE       = 30.0f;
    float const BONK_MIN_CONSUME_TICK_MS     = 100.0f;
    uint32 const BONK_KIT_CONSUME_BURST      = 6377;
    uint32 const BONK_MAX_PAYOFF_DOT_STACKS  = 30;
    uint32 const BONK_KEYWORD_TIMER_MS       = 200;
    size_t const BONK_KEYWORD_TIMER_LINE     = 900;
    float const BONK_DOT_BURST_RANGE         = 8.0f;
    size_t const BONK_DOT_BURST_TARGETS      = 4;
    float const BONK_DOT_BURST_SHARE         = 0.5f;
    size_t const BONK_DOT_BURSTS_PER_SEC     = 15;
    size_t const BONK_DOT_BURST_LOOKS_PER_SEC = 4;
    uint32 const BONK_KIT_POISON_BURST       = 6377;
    uint32 const BONK_KIT_BLOOD_BURST        = 903;
    uint32 const BONK_KIT_BURNING_BURST      = 728;

    thread_local int32 t_groundTickEffect = -1;

    BonkMobAI const* GetRunAI(Unit const* unit)
    {
        Creature const* creature = unit ? unit->ToCreature() : nullptr;
        return creature ? dynamic_cast<BonkMobAI const*>(creature->AI()) : nullptr;
    }

    bool TimeLeft(uint32 until, uint32 now)
    {
        return int32(until - now) > 0;
    }
}

void BonkRun::SetGroundTickEffect(int32 effectIndex)
{
    t_groundTickEffect = effectIndex;
}

void BonkRun::OnWeaponHit(Unit* victim, SpellEntry const* spell)
{
    if (m_state != STATE_RUNNING || !spell || !GetRunAI(victim) || m_keywordlessHits)
        return;

    OwnedWeapon const* owned = FindOwnedBySpell(spell->Id);
    if (!owned || owned->weapon.behavior == BONK_BEHAVIOR_PET)
        return;
    if (t_groundTickEffect >= 0 && t_groundTickEffect == owned->weapon.tickEffectIndex && HasLingeringGround(owned->weapon, spell))
        return;

    if (OwnedWeapon const* rend = FindRendSpreadBy(*owned))
        QueueRendSwingBleed(*rend, victim);
    QueueTalentSlowAndStun(*owned, victim);
    if (m_mastery.Has(BONK_CAPSTONE_TRUESHOT) && !GetKeywordStacks(victim, BONK_KEYWORD_HUNTERS_MARK))
    {
        PendingKeyword mark;
        mark.mob = victim->GetObjectGuid();
        mark.keyword = BONK_KEYWORD_HUNTERS_MARK;
        mark.stacks = 1;
        mark.spellId = spell->Id;
        m_pendingKeywords.push_back(mark);
    }

    if (owned->weapon.HasFlag(BONK_WEAPON_FLAG_CONSUME))
    {
        PendingKeyword consume;
        consume.mob = victim->GetObjectGuid();
        consume.keyword = owned->weapon.uses;
        m_pendingConsumes.push_back(consume);
    }

    PendingKeyword pending;
    if (!GetWeaponKeyword(*owned, pending))
        return;

    pending.mob = victim->GetObjectGuid();
    m_pendingKeywords.push_back(pending);
}

void BonkRun::QueueTalentSlowAndStun(OwnedWeapon const& owned, Unit* victim)
{
    auto slow = m_mastery.spellSlow.find(GetRootWeapon(owned.weapon));
    if (slow != m_mastery.spellSlow.end())
        m_pendingSlows.emplace_back(victim->GetObjectGuid(), slow->second);
    QueueTalentStun(owned, victim);
}

void BonkRun::QueueTalentKeyword(OwnedWeapon const& owned, Unit* victim)
{
    if (!m_mastery.spellApplies.count(GetRootWeapon(owned.weapon)))
        return;
    BonkWeapon const* base = sBonkMgr.GetWeapon(owned.weapon.id);
    if (!base || base->applies != BONK_KEYWORD_NONE)
        return;
    PendingKeyword pending;
    if (!GetWeaponKeyword(owned, pending))
        return;
    pending.mob = victim->GetObjectGuid();
    m_pendingKeywords.push_back(pending);
}

void BonkRun::OnClassSpellHit(uint32 creditSpellId, Unit* victim)
{
    if (m_state != STATE_RUNNING || !victim->IsAlive() || !GetRunAI(victim))
        return;
    OwnedWeapon const* owned = FindOwnedBySpell(creditSpellId);
    if (!owned || !owned->firedByClass || owned->weapon.behavior == BONK_BEHAVIOR_PET)
        return;
    QueueTalentSlowAndStun(*owned, victim);
    QueueTalentKeyword(*owned, victim);
    CurseFromShadowBolt(*owned, victim);
}

bool BonkRun::GetWeaponKeyword(OwnedWeapon const& owned, PendingKeyword& keyword) const
{
    BonkWeapon const& weapon = owned.weapon;
    keyword.keyword = weapon.applies;
    keyword.spellId = weapon.spellId;
    uint32 stacks = weapon.applyStacks;
    if (weapon.behavior == BONK_BEHAVIOR_PET && keyword.keyword == BONK_KEYWORD_NONE)
        if (BonkPetFamily const* family = GetPetFamily(owned))
        {
            keyword.keyword = family->applies;
            stacks = family->applyStacks;
        }
    BonkKeywordInfo const* info = sBonkMgr.GetKeyword(keyword.keyword);
    if (!info || !stacks)
        return false;

    stacks += uint32(GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_STACKS));
    keyword.stacks = uint8(std::min<uint32>(stacks, BONK_MAX_DOT_STACKS));
    keyword.durationMs = uint32(info->durationMs * GetWeaponDurationScale(owned));
    keyword.damageScale = 1.0f + (owned.damageBonus + GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_PET_DAMAGE)) / 100.0f;
    return true;
}

void BonkRun::OnKillingBlow(Unit* victim)
{
    if (m_state != STATE_RUNNING || !GetRunAI(victim))
        return;
    OnTalentKill(victim);
    OnShamanKill(victim);
    OnWarlockKill(victim);

    std::map<uint8, DyingKeyword> carried;
    for (auto const& itr : sBonkMgr.GetKeywords())
    {
        BonkKeywordInfo const& info = itr.second;
        if (info.id == BONK_KEYWORD_HUNTERS_MARK)
        {
            SpellAuraHolder const* holder = victim->GetSpellAuraHolder(info.spellId, m_player->GetObjectGuid());
            if (holder && holder->GetAuraDuration() > 0)
                carried[itr.first].leftMs = uint32(holder->GetAuraDuration());
            continue;
        }
        if (!info.spreadsOnDeath)
            continue;
        auto mob = m_dotStacks.find(victim->GetObjectGuid());
        if (mob == m_dotStacks.end())
            continue;
        auto stacks = mob->second.find(itr.first);
        if (stacks == mob->second.end() || stacks->second.empty())
            continue;
        int64 sum = 0;
        uint32 fullMs = 0;
        std::map<uint32, uint32> bySpell;
        uint32 const now = WorldTimer::getMSTime();
        float const tickMs = std::max(BONK_MIN_CONSUME_TICK_MS, info.tickMs / GetHasteRate());
        DyingKeyword& dying = carried[itr.first];
        for (DotStack const& stack : stacks->second)
        {
            sum += stack.points;
            fullMs = std::max(fullMs, stack.fullMs);
            ++bySpell[stack.spellId];
            if (BurstsOnDeath(itr.first) && TimeLeft(stack.untilMs, now))
                dying.leftDamage[stack.spellId] += stack.points / BONK_DOT_POINT_SCALE * float(stack.untilMs - now) / tickMs;
        }
        dying.fullMs = fullMs;
        dying.stacks = uint32(stacks->second.size());
        dying.points = int32(sum / int64(dying.stacks));
        dying.spellId = std::max_element(bySpell.begin(), bySpell.end(), [](auto const& a, auto const& b) { return a.second < b.second; })->first;
    }
    if (!carried.empty())
        m_dyingKeywords[victim->GetObjectGuid()] = std::move(carried);
}

void BonkRun::UpdateKeywords(uint32 diff)
{
    if (!m_pendingKeywords.empty())
    {
        std::vector<PendingKeyword> pending;
        pending.swap(m_pendingKeywords);
        Map* map = m_player->GetMap();
        for (PendingKeyword const& keyword : pending)
            if (Creature* mob = map->GetCreature(keyword.mob))
                ApplyKeyword(mob, keyword.keyword, keyword.stacks, keyword.durationMs, keyword.damageScale, keyword.spellId);
    }
    if (!m_pendingConsumes.empty())
        ConsumePendingKeywords();
    if (!m_pendingDotBursts.empty())
        ReleaseDotBursts();
    if (!m_pendingSlows.empty())
    {
        std::vector<std::pair<ObjectGuid, float>> slows;
        slows.swap(m_pendingSlows);
        Map* map = m_player->GetMap();
        for (auto const& slow : slows)
            if (Creature* mob = map->GetCreature(slow.first))
                ApplyMasterySlow(mob, slow.second);
    }
    ApplyPendingStuns();
    UpdateThaws();
    UpdateDotStacks(diff);
    SendKeywordTimers(diff);
}

void BonkRun::ConsumePendingKeywords()
{
    std::vector<PendingKeyword> pending;
    pending.swap(m_pendingConsumes);
    Map* map = m_player->GetMap();
    for (PendingKeyword const& consume : pending)
    {
        Creature* mob = map->GetCreature(consume.mob);
        BonkKeywordInfo const* info = sBonkMgr.GetKeyword(consume.keyword);
        SpellEntry const* spellInfo = info ? sSpellMgr.GetSpellEntry(info->spellId) : nullptr;
        if (!mob || !mob->IsAlive() || !spellInfo)
            continue;

        float const damage = ConsumeDotStacks(mob, *info);
        if (damage <= 0.0f)
            continue;
        mob->SendPlaySpellVisualKit(BONK_KIT_CONSUME_BURST);
        DealSpellHit(spellInfo, mob, damage);
    }
}

float BonkRun::ConsumeDotStacks(Creature* mob, BonkKeywordInfo const& info)
{
    auto victim = m_dotStacks.find(mob->GetObjectGuid());
    if (victim == m_dotStacks.end())
        return 0.0f;
    auto stacks = victim->second.find(info.id);
    if (stacks == victim->second.end())
        return 0.0f;

    uint32 const now = WorldTimer::getMSTime();
    float const tickMs = std::max(BONK_MIN_CONSUME_TICK_MS, info.tickMs / GetHasteRate());
    float damage = 0.0f;
    for (DotStack const& stack : stacks->second)
        if (TimeLeft(stack.untilMs, now))
            damage += stack.points / BONK_DOT_POINT_SCALE * float(stack.untilMs - now) / tickMs;

    victim->second.erase(stacks);
    if (victim->second.empty())
        m_dotStacks.erase(victim);
    mob->RemoveAurasByCasterSpell(info.spellId, m_player->GetObjectGuid());
    return damage;
}

float BonkRun::GetDotDamageLeft(Creature const* mob, BonkKeyword keyword, uint32 withinMs) const
{
    BonkKeywordInfo const* info = sBonkMgr.GetKeyword(keyword);
    auto victim = m_dotStacks.find(mob->GetObjectGuid());
    if (!info || victim == m_dotStacks.end())
        return 0.0f;
    auto stacks = victim->second.find(info->id);
    if (stacks == victim->second.end())
        return 0.0f;
    uint32 const now = WorldTimer::getMSTime();
    float const tickMs = std::max(BONK_MIN_CONSUME_TICK_MS, info->tickMs / GetHasteRate());
    float damage = 0.0f;
    for (DotStack const& stack : stacks->second)
        if (TimeLeft(stack.untilMs, now))
        {
            uint32 const leftMs = stack.untilMs - now;
            damage += stack.points / BONK_DOT_POINT_SCALE * float(withinMs ? std::min(leftMs, withinMs) : leftMs) / tickMs;
        }
    return damage;
}

bool BonkRun::ApplyKeyword(Creature* mob, BonkKeyword keyword, uint32 stacks, uint32 durationMs, float damageScale, uint32 sourceSpellId)
{
    BonkKeywordInfo const* info = sBonkMgr.GetKeyword(keyword);
    if (!info || !stacks || !mob || !mob->IsAlive() || !GetRunAI(mob) || !m_player->IsInWorld())
        return false;

    if (keyword == BONK_KEYWORD_FROZEN)
    {
        if (!Freeze(mob))
            return false;
        OnFrozen(mob, sourceSpellId);
        return true;
    }

    uint32 const length = (durationMs ? durationMs : info->durationMs) + (keyword == BONK_KEYWORD_CHILL ? GetChillTalentMs() : 0) +
        GetKeywordTalentMs(keyword);

    if (info->IsDamageOverTime())
    {
        AddDotStacks(mob, *info, stacks, length, std::max(1, int32(GetKeywordPoints(*info) * damageScale + 0.5f)), sourceSpellId);
        return true;
    }

    uint32 const total = std::min<uint32>(GetKeywordStacks(mob, keyword) + stacks, info->maxStacks);

    if (keyword == BONK_KEYWORD_CHILL && total >= GetChillFreezeStacks(*info) && Freeze(mob))
    {
        mob->RemoveAurasByCasterSpell(info->spellId, m_player->GetObjectGuid());
        OnFrozen(mob, sourceSpellId);
        return true;
    }

    if (keyword == BONK_KEYWORD_STATIC && total >= GetStaticDischargeStacks(*info) && QueueStaticDischarge(mob, sourceSpellId))
    {
        mob->RemoveAurasByCasterSpell(info->spellId, m_player->GetObjectGuid());
        return true;
    }

    return AddKeywordAura(mob, *info, total, length) != nullptr;
}

void BonkRun::AddDotStacks(Creature* mob, BonkKeywordInfo const& info, uint32 stacks, uint32 durationMs, int32 points, uint32 spellId)
{
    std::vector<DotStack>& list = m_dotStacks[mob->GetObjectGuid()][info.id];
    DotStack stack;
    stack.appliedMs = WorldTimer::getMSTime();
    stack.fullMs = std::max(1u, durationMs);
    stack.untilMs = stack.appliedMs + stack.fullMs;
    stack.points = points;
    stack.spellId = spellId;
    stack.grows = info.id == BONK_KEYWORD_AGONY || IsGrowingDotSpell(spellId);
    for (DotStack& held : list)
        if (int32(stack.untilMs - held.untilMs) > 0)
            held.untilMs = stack.untilMs;
    list.insert(list.end(), stacks, stack);

    size_t const cap = BONK_MAX_DOT_STACKS + GetKeywordTalentCap(info.id);
    if (list.size() > cap)
        list.erase(list.begin(), list.begin() + (list.size() - cap));
    SyncDotAura(mob, info, list);
}

void BonkRun::CreditDamageOverTime(Unit const* victim, uint32 spellId, uint32 damage, std::vector<std::pair<uint32, uint32>>& credits) const
{
    BonkKeywordInfo const* info = sBonkMgr.GetKeywordBySpell(spellId);
    if (!info || !info->IsDamageOverTime())
        return;
    auto mob = m_dotStacks.find(victim->GetObjectGuid());
    if (mob == m_dotStacks.end())
        return;
    auto stacks = mob->second.find(info->id);
    if (stacks == mob->second.end() || stacks->second.empty())
        return;

    std::map<uint32, int64> bySpell;
    int64 total = 0;
    for (DotStack const& stack : stacks->second)
    {
        bySpell[stack.spellId ? stack.spellId : spellId] += stack.points;
        total += stack.points;
    }
    if (total <= 0)
        return;
    uint32 given = 0;
    for (auto const& itr : bySpell)
    {
        uint32 const share = uint32(int64(damage) * itr.second / total);
        credits.emplace_back(itr.first, share);
        given += share;
    }
    std::sort(credits.begin(), credits.end(), [](auto const& a, auto const& b) { return a.second > b.second; });
    credits.front().second += damage - given;
}

void BonkRun::UpdateDotStacks(uint32 diff)
{
    m_dotTimer += diff;
    if (m_dotTimer < BONK_DOT_CHECK_MS || m_dotStacks.empty())
        return;
    m_dotTimer = 0;

    uint32 const now = WorldTimer::getMSTime();
    Map* map = m_player->GetMap();
    for (auto mob = m_dotStacks.begin(); mob != m_dotStacks.end();)
    {
        Creature* creature = map->GetCreature(mob->first);
        if (!creature || !creature->IsAlive())
        {
            mob = m_dotStacks.erase(mob);
            continue;
        }

        for (auto keyword = mob->second.begin(); keyword != mob->second.end();)
        {
            std::vector<DotStack>& stacks = keyword->second;
            size_t const before = stacks.size();
            stacks.erase(std::remove_if(stacks.begin(), stacks.end(), [now](DotStack const& stack) { return !TimeLeft(stack.untilMs, now); }), stacks.end());

            BonkKeywordInfo const* info = sBonkMgr.GetKeyword(BonkKeyword(keyword->first));
            bool const worn = info && creature->GetSpellAuraHolder(info->spellId, m_player->GetObjectGuid());
            if (!info || !worn || stacks.empty())
            {
                if (worn)
                    creature->RemoveAurasByCasterSpell(info->spellId, m_player->GetObjectGuid());
                keyword = mob->second.erase(keyword);
                continue;
            }
            if (stacks.size() != before)
                SyncDotAura(creature, *info, stacks);
            ++keyword;
        }
        if (mob->second.empty())
            mob = m_dotStacks.erase(mob);
        else
            ++mob;
    }
}

void BonkRun::SyncDotAura(Creature* mob, BonkKeywordInfo const& info, std::vector<DotStack> const& stacks)
{
    uint32 const now = WorldTimer::getMSTime();
    uint32 const count = uint32(stacks.size());
    int64 sum = 0;
    int32 leftMs = 1;
    for (DotStack const& stack : stacks)
    {
        sum += stack.points;
        leftMs = std::max(leftMs, int32(stack.untilMs - now));
    }
    int32 const average = std::max<int32>(1, int32((sum + count / 2) / count));

    SpellAuraHolder* holder = mob->GetSpellAuraHolder(info.spellId, m_player->GetObjectGuid());
    if (!holder)
    {
        AddKeywordAura(mob, info, count, uint32(leftMs), average);
        return;
    }

    for (uint32 i = 0; i < MAX_EFFECT_INDEX; ++i)
        if (Aura* aura = holder->GetAuraByEffectIndex(SpellEffectIndex(i)))
            aura->SetBasePoints(average);
    if (holder->GetStackAmount() != count)
        holder->SetStackAmount(count);
    else
        for (uint32 i = 0; i < MAX_EFFECT_INDEX; ++i)
            if (Aura* aura = holder->GetAuraByEffectIndex(SpellEffectIndex(i)))
            {
                int32 points = aura->GetBasePoints();
                float const amount = count * m_player->CalculateSpellEffectValue(mob, holder->GetSpellProto(), SpellEffectIndex(i), &points);
                aura->ApplyModifier(false, true);
                aura->GetModifier()->m_amount = amount;
                aura->ApplyModifier(true, true);
            }
    holder->SetAuraMaxDuration(leftMs);
    holder->RefreshHolder();
    MarkKeywordTimer(mob, info.id);
}

void BonkRun::ShiftDotStacks(uint32 ms)
{
    for (auto& mob : m_dotStacks)
        for (auto& keyword : mob.second)
            for (DotStack& stack : keyword.second)
            {
                stack.appliedMs += ms;
                stack.untilMs += ms;
            }
}

void BonkRun::MarkKeywordTimer(Creature const* mob, BonkKeyword keyword)
{
    BonkMobAI const* ai = GetRunAI(mob);
    if (ai && (ai->GetKind() == BONK_SPAWN_BOSS || ai->GetKind() == BONK_SPAWN_MINIBOSS))
        m_keywordTimers.insert(std::make_pair(mob->GetObjectGuid(), uint8(keyword)));
}

bool BonkRun::GetKeywordTimer(Creature* mob, BonkKeywordInfo const& info, uint32 now, uint32& leftMs, uint32& fullMs) const
{
    if (info.IsDamageOverTime())
    {
        auto victim = m_dotStacks.find(mob->GetObjectGuid());
        if (victim == m_dotStacks.end())
            return false;
        auto stacks = victim->second.find(info.id);
        if (stacks == victim->second.end() || stacks->second.empty())
            return false;
        int32 left = 0;
        for (DotStack const& stack : stacks->second)
            left = std::max(left, int32(stack.untilMs - now));
        DotStack const& newest = stacks->second.back();
        fullMs = std::max(1u, newest.untilMs - newest.appliedMs);
        leftMs = uint32(std::min(left, int32(fullMs)));
        return left > 0;
    }

    SpellAuraHolder const* holder = mob->GetSpellAuraHolder(info.spellId, m_player->GetObjectGuid());
    if (!holder || holder->IsPermanent() || holder->GetAuraMaxDuration() <= 0 || holder->GetAuraDuration() <= 0)
        return false;
    fullMs = uint32(holder->GetAuraMaxDuration());
    leftMs = uint32(std::min(holder->GetAuraDuration(), holder->GetAuraMaxDuration()));
    return true;
}

void BonkRun::SendKeywordTimers(uint32 diff)
{
    m_keywordTimerMs += diff;
    if (m_keywordTimerMs < BONK_KEYWORD_TIMER_MS || m_keywordTimers.empty())
        return;
    m_keywordTimerMs = 0;

    std::set<std::pair<ObjectGuid, uint8>> marked;
    marked.swap(m_keywordTimers);
    Map* map = m_player->GetMap();
    uint32 const now = WorldTimer::getMSTime();
    BonkPlayer* bonk = m_player->GetBonkPlayer();
    auto send = [bonk](std::string const& entries)
    {
        if (!bonk->IsAddonReady())
            return;
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteKeywordTimers(data, entries);
        bonk->GetPlayer()->GetSession()->SendPacket(&data);
    };
    std::string entries;
    for (auto const& itr : marked)
    {
        Creature* mob = map->GetCreature(itr.first);
        BonkKeywordInfo const* info = sBonkMgr.GetKeyword(BonkKeyword(itr.second));
        uint32 leftMs, fullMs;
        if (!mob || !mob->IsAlive() || !info || !GetKeywordTimer(mob, *info, now, leftMs, fullMs))
            continue;
        std::string const entry = BonkMobAI::GetUnitGuidText(mob) + ":" + std::to_string(uint32(itr.second)) + ":" +
            std::to_string(leftMs) + ":" + std::to_string(fullMs);
        if (!entries.empty() && entries.size() + entry.size() + 1 > BONK_KEYWORD_TIMER_LINE)
        {
            send(entries);
            entries.clear();
        }
        entries += (entries.empty() ? "" : ",") + entry;
    }
    if (!entries.empty())
        send(entries);
}

uint32 BonkRun::GetKeywordStacks(Unit const* victim, BonkKeyword keyword) const
{
    if (!victim)
        return 0;
    if (keyword == BONK_KEYWORD_FROZEN)
        return IsFrozen(victim) ? 1 : 0;

    BonkKeywordInfo const* info = sBonkMgr.GetKeyword(keyword);
    if (!info)
        return 0;
    SpellAuraHolder const* holder = victim->GetSpellAuraHolder(info->spellId, m_player->GetObjectGuid());
    return holder ? holder->GetStackAmount() : 0;
}

uint32 BonkRun::CountKeywords(Unit const* victim) const
{
    uint32 count = 0;
    for (auto const& itr : sBonkMgr.GetKeywords())
        if (GetKeywordStacks(victim, itr.second.id))
            ++count;
    return count;
}

bool BonkRun::Freeze(Creature* mob)
{
    BonkMobAI const* ai = GetRunAI(mob);
    BonkKeywordInfo const* info = sBonkMgr.GetKeyword(BONK_KEYWORD_FROZEN);
    if (!ai || !info || !mob->IsAlive())
        return false;

    uint32 const now = WorldTimer::getMSTime();
    CrowdControl& control = m_crowdControl[mob->GetObjectGuid()];
    if (TimeLeft(control.frozenImmuneUntil, now))
        return false;

    uint32 const length = std::min(info->durationMs ? info->durationMs : BONK_MAX_HOLD_MS, BONK_MAX_HOLD_MS);
    control.shatterUntil = now + length;
    control.frozenImmuneUntil = now + length + BONK_HOLD_IMMUNE_MS;

    if (ai->GetKind() == BONK_SPAWN_NORMAL)
        AddKeywordAura(mob, *info, 1, length);
    QueueThawChill(mob, now + length);
    return true;
}

bool BonkRun::IsFrozen(Unit const* victim) const
{
    auto itr = victim ? m_crowdControl.find(victim->GetObjectGuid()) : m_crowdControl.end();
    return itr != m_crowdControl.end() && TimeLeft(itr->second.shatterUntil, WorldTimer::getMSTime());
}

bool BonkRun::LimitStun(Creature* mob, int32& duration)
{
    if (!GetRunAI(mob))
        return true;

    uint32 const now = WorldTimer::getMSTime();
    CrowdControl& control = m_crowdControl[mob->GetObjectGuid()];
    if (TimeLeft(control.stunImmuneUntil, now))
        return false;

    if (duration <= 0 || duration > int32(BONK_MAX_HOLD_MS))
        duration = int32(BONK_MAX_HOLD_MS);
    control.stunImmuneUntil = now + uint32(duration) + BONK_HOLD_IMMUNE_MS;
    return true;
}

bool BonkRun::LimitRoot(Creature* mob, int32& duration)
{
    BonkMobAI const* ai = GetRunAI(mob);
    if (!ai)
        return true;
    if (ai->GetKind() != BONK_SPAWN_NORMAL)
        return false;

    uint32 const now = WorldTimer::getMSTime();
    CrowdControl& control = m_crowdControl[mob->GetObjectGuid()];
    if (TimeLeft(control.frozenImmuneUntil, now))
        return false;

    if (duration <= 0 || duration > int32(BONK_MAX_HOLD_MS))
        duration = int32(BONK_MAX_HOLD_MS);
    control.frozenImmuneUntil = now + uint32(duration) + BONK_HOLD_IMMUNE_MS;
    return true;
}

bool BonkRun::CanKnockBack(Creature const* mob)
{
    BonkMobAI const* ai = GetRunAI(mob);
    if (!ai || ai->GetKind() != BONK_SPAWN_NORMAL)
        return false;

    uint32 const now = WorldTimer::getMSTime();
    CrowdControl& control = m_crowdControl[mob->GetObjectGuid()];
    if (TimeLeft(control.knockImmuneUntil, now))
        return false;
    control.knockImmuneUntil = now + BONK_HOLD_IMMUNE_MS;
    return true;
}

bool BonkRun::CanPull(Creature const* mob)
{
    BonkMobAI const* ai = GetRunAI(mob);
    if (!ai || ai->GetKind() != BONK_SPAWN_NORMAL || !ai->CanBePulled())
        return false;

    uint32 const now = WorldTimer::getMSTime();
    CrowdControl& control = m_crowdControl[mob->GetObjectGuid()];
    if (TimeLeft(control.pullImmuneUntil, now))
        return false;
    control.pullImmuneUntil = now + BONK_PULL_IMMUNE_MS;
    return true;
}

float BonkRun::GetKeywordDamageMultiplier(SpellEntry const* spell, Unit const* victim) const
{
    if (!GetRunAI(victim))
        return 1.0f;

    float multiplier = 1.0f;
    if (GetKeywordStacks(victim, BONK_KEYWORD_HUNTERS_MARK))
        multiplier *= 1.0f + GetHuntersMarkBonus() / 100.0f;
    multiplier *= 1.0f + GetSlowedBonus(victim) / 100.0f;
    multiplier *= GetWarlockDamageTakenScale(victim);

    if (spell)
        if (OwnedWeapon const* owned = FindOwnedBySpell(spell->Id))
            if (owned->weapon.uses != BONK_KEYWORD_NONE && owned->weapon.usesPct > 0.0f)
            {
                uint32 count = 0;
                if (owned->weapon.uses == BONK_KEYWORD_VARIETY)
                    count = CountKeywords(victim);
                else if (BonkKeywordInfo const* used = sBonkMgr.GetKeyword(owned->weapon.uses))
                    count = used->IsDamageOverTime() ? std::min(GetKeywordStacks(victim, owned->weapon.uses), BONK_MAX_PAYOFF_DOT_STACKS) :
                        GetKeywordStacks(victim, owned->weapon.uses);
                if (GetRootWeapon(owned->weapon) == BONK_WEAPON_SHADOW_BOLT)
                    count = std::max(count, std::min(GetKeywordStacks(victim, BONK_KEYWORD_BURNING), BONK_MAX_PAYOFF_DOT_STACKS));
                multiplier *= 1.0f + owned->weapon.usesPct * count / 100.0f;
            }
    return multiplier;
}

float BonkRun::GetSlowedBonus(Unit const* victim) const
{
    float bonus = 0.0f;
    for (OwnedWeapon const& owned : m_weapons)
        if (owned.weapon.HasFlag(BONK_WEAPON_FLAG_NORMAL_ONLY) && owned.weapon.damageEffectIndex < 0 && !owned.weapon.weaponDamage &&
            victim->HasAura(owned.weapon.spellId))
            bonus = std::max(bonus, GetSlowedStrength(owned.damageBonus, GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_SLOWED)));
    return bonus;
}

float BonkRun::GetSlowedStrength(float damageBonus, float slowedUpgrade)
{
    return std::min(BONK_SLOWED_DAMAGE * (1.0f + damageBonus / 100.0f) + slowedUpgrade, BONK_MAX_SLOWED_DAMAGE);
}

float BonkRun::GetHuntersMarkBonus() const
{
    float bonus = GetMarkStrength(0.0f, 0.0f);
    for (OwnedWeapon const& owned : m_weapons)
    {
        BonkWeapon const* row = sBonkMgr.GetWeapon(owned.weapon.id);
        if (row && row->applies == BONK_KEYWORD_HUNTERS_MARK)
            bonus = std::max(bonus, GetMarkStrength(owned.damageBonus, GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_MARK)));
    }
    return bonus;
}

float BonkRun::GetMarkStrength(float damageBonus, float markUpgrade) const
{
    BonkKeywordInfo const* mark = sBonkMgr.GetKeyword(BONK_KEYWORD_HUNTERS_MARK);
    if (!mark)
        return 0.0f;
    return std::min(mark->valuePerStack * (1.0f + damageBonus / 100.0f) + markUpgrade, BONK_MAX_HUNTERS_MARK) + m_mastery.markBonus;
}

SpellAuraHolder* BonkRun::AddKeywordAura(Creature* mob, BonkKeywordInfo const& info, uint32 stacks, uint32 durationMs, int32 points)
{
    SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(info.spellId);
    if (!spellInfo)
        return nullptr;

    BonkPlayer::SpellTweak& tweak = m_player->GetBonkPlayer()->TweakSpell(info.spellId);
    tweak.tickMs = info.tickMs;
    tweak.tickScale = 1.0f / GetHasteRate();
    tweak.durationMs = 0;
    tweak.durationScale = 1.0f;

    if (SpellAuraHolder* holder = mob->GetSpellAuraHolder(info.spellId, m_player->GetObjectGuid()))
    {
        holder->SetStackAmount(stacks);
        MarkKeywordTimer(mob, info.id);
        return holder;
    }

    if (!points)
        points = GetKeywordPoints(info);
    SpellAuraHolder* holder = CreateSpellAuraHolder(spellInfo, mob, m_player, m_player);
    for (uint32 i = 0; i < MAX_EFFECT_INDEX; ++i)
        if (spellInfo->Effect[i] == SPELL_EFFECT_APPLY_AURA)
        {
            Aura* aura = CreateAura(spellInfo, SpellEffectIndex(i), &points, holder, mob, m_player);
            aura->SetPositive(false);
            holder->AddAura(aura, SpellEffectIndex(i));
        }
    if (holder->IsEmptyHolder())
    {
        delete holder;
        return nullptr;
    }

    if (durationMs)
    {
        holder->SetPermanent(false);
        holder->SetAuraMaxDuration(int32(durationMs));
        holder->SetAuraDuration(int32(durationMs));
    }
    if (!mob->AddSpellAuraHolder(holder))
        return nullptr;
    if (stacks > 1)
        holder->SetStackAmount(stacks);
    MarkKeywordTimer(mob, info.id);
    return holder;
}

int32 BonkRun::GetKeywordPoints(BonkKeywordInfo const& info) const
{
    switch (info.id)
    {
        case BONK_KEYWORD_CHILL:
        case BONK_KEYWORD_DAZED:
            return -int32(info.valuePerStack + 0.5f);
        case BONK_KEYWORD_FIRE_VULNERABILITY:
        case BONK_KEYWORD_SUNDER_ARMOR:
        case BONK_KEYWORD_SHADOW_VULNERABILITY:
        case BONK_KEYWORD_NATURE_VULNERABILITY:
            return int32(info.valuePerStack + 0.5f);
        case BONK_KEYWORD_BURNING:
        case BONK_KEYWORD_BLEED:
        case BONK_KEYWORD_POISON:
        case BONK_KEYWORD_DECAY:
        case BONK_KEYWORD_AGONY:
        case BONK_KEYWORD_MOONFIRE:
        {
            float const scale = (GetDotPassiveScale(BonkKeyword(info.id)) + GetKeywordTalentDamage(info.id) / 100.0f) * GetDotCardScale();
            return std::max(1, int32(GetMobHealth(GetMobLevel()) * info.valuePerStack * info.tickMs / IN_MILLISECONDS * scale * BONK_DOT_POINT_SCALE));
        }
        default:
            return 0;
    }
}

float BonkRun::GetDotTickDamage(BonkKeywordInfo const& info) const
{
    return GetKeywordPoints(info) / BONK_DOT_POINT_SCALE;
}

float BonkRun::GetDotPointShare(uint32 spellId)
{
    BonkKeywordInfo const* info = sBonkMgr.GetKeywordBySpell(spellId);
    return info && info->IsDamageOverTime() ? 1.0f / BONK_DOT_POINT_SCALE : 1.0f;
}

float BonkRun::GetPoisonDamageScale() const
{
    return std::max(0.0f, 1.0f + GetPassiveTotal(BONK_PASSIVE_POISON_DAMAGE) / 100.0f);
}

float BonkRun::GetDotPassiveScale(BonkKeyword keyword) const
{
    switch (keyword)
    {
        case BONK_KEYWORD_POISON:  return GetPoisonDamageScale();
        case BONK_KEYWORD_BURNING: return std::max(0.0f, 1.0f + GetPassiveTotal(BONK_PASSIVE_BURNING_DAMAGE) / 100.0f);
        case BONK_KEYWORD_BLEED:   return std::max(0.0f, 1.0f + GetPassiveTotal(BONK_PASSIVE_BLEED_DAMAGE) / 100.0f);
        default:                   return 1.0f;
    }
}

void BonkRun::SpreadKeywords(Creature const* dead)
{
    m_crowdControl.erase(dead->GetObjectGuid());

    m_dotStacks.erase(dead->GetObjectGuid());

    auto itr = m_dyingKeywords.find(dead->GetObjectGuid());
    if (itr == m_dyingKeywords.end())
        return;
    std::map<uint8, DyingKeyword> const carried = std::move(itr->second);
    m_dyingKeywords.erase(itr);

    for (auto const& keyword : carried)
    {
        BonkKeywordInfo const* info = sBonkMgr.GetKeyword(BonkKeyword(keyword.first));
        if (!info)
            continue;

        if (info->id == BONK_KEYWORD_HUNTERS_MARK)
        {
            uint32 passed = 0;
            for (Creature* next : GetMobsInRange(BONK_MARK_SPREAD_RANGE, dead))
            {
                if (passed >= BONK_KEYWORD_SPREAD_TARGETS)
                    break;
                if (!GetKeywordStacks(next, BONK_KEYWORD_HUNTERS_MARK) && ApplyKeyword(next, info->id, 1, keyword.second.leftMs))
                    ++passed;
            }
            QueueShardBurst(dead);
            continue;
        }

        if (info->id == BONK_KEYWORD_POISON)
            OnPoisonedDeath(dead);
        if (info->id == BONK_KEYWORD_BLEED)
            OnBleedingDeath(dead);
        if (BurstsOnDeath(info->id))
            QueueDotBurst(dead, info->id, keyword.second);

        uint32 const half = keyword.second.stacks / 2;
        if (!half)
            continue;
        uint32 spread = 0;
        for (Creature* next : GetMobsInRange(BONK_KEYWORD_SPREAD_RANGE, dead))
        {
            if (spread >= BONK_KEYWORD_SPREAD_TARGETS + GetExtraSpreadTargets(info->id))
                break;
            if (!next->IsAlive() || !GetRunAI(next))
                continue;
            AddDotStacks(next, *info, half, keyword.second.fullMs ? keyword.second.fullMs : info->durationMs, keyword.second.points, keyword.second.spellId);
            ++spread;
        }
    }
}

bool BonkRun::BurstsOnDeath(uint8 keyword)
{
    return keyword == BONK_KEYWORD_BURNING || keyword == BONK_KEYWORD_BLEED || keyword == BONK_KEYWORD_POISON;
}

void BonkRun::QueueDotBurst(Creature const* dead, uint8 keyword, DyingKeyword const& dying)
{
    if (dying.leftDamage.empty())
        return;
    PendingDotBurst burst;
    burst.dead = dead->GetObjectGuid();
    burst.x = dead->GetPositionX();
    burst.y = dead->GetPositionY();
    burst.keyword = keyword;
    burst.leftDamage = dying.leftDamage;
    m_pendingDotBursts.push_back(std::move(burst));
}

void BonkRun::ReleaseDotBursts()
{
    std::vector<PendingDotBurst> pending;
    pending.swap(m_pendingDotBursts);
    Map* map = m_player->GetMap();
    for (PendingDotBurst const& burst : pending)
    {
        BonkKeywordInfo const* info = sBonkMgr.GetKeyword(BonkKeyword(burst.keyword));
        SpellEntry const* look = info ? sSpellMgr.GetSpellEntry(info->spellId) : nullptr;
        if (!look || !TakeRateSlot(m_dotBurstTimes, BONK_DOT_BURSTS_PER_SEC))
            continue;
        std::vector<Creature*> struck;
        for (Creature* mob : GetMobsNear(burst.x, burst.y, BONK_DOT_BURST_RANGE))
        {
            if (struck.size() >= BONK_DOT_BURST_TARGETS)
                break;
            if (mob->IsAlive() && GetRunAI(mob))
                struck.push_back(mob);
        }
        if (struck.empty())
            continue;
        if (Creature* dead = map->GetCreature(burst.dead))
            ShowDotBurst(dead, burst.keyword);
        for (Creature* mob : struck)
            for (auto const& part : burst.leftDamage)
                DealShamanHit(look, part.first, mob, part.second * BONK_DOT_BURST_SHARE);
    }
}

void BonkRun::ShowDotBurst(Creature* dead, uint8 keyword)
{
    if (!TakeRateSlot(m_dotBurstLookTimes, BONK_DOT_BURST_LOOKS_PER_SEC))
        return;
    uint32 const kit = keyword == BONK_KEYWORD_POISON ? BONK_KIT_POISON_BURST : keyword == BONK_KEYWORD_BLEED ? BONK_KIT_BLOOD_BURST : BONK_KIT_BURNING_BURST;
    dead->SendPlaySpellVisualKit(kit);
}

void BonkRun::RebuildWeaponSpells()
{
    m_weaponSpells.clear();
    for (OwnedWeapon const& owned : m_weapons)
        for (uint32 spellId : BonkStats::GetWeaponSpells(owned.weapon))
            m_weaponSpells.emplace(spellId, owned.weapon.id);
}

BonkRun::OwnedWeapon const* BonkRun::FindOwnedBySpell(uint32 spellId) const
{
    auto itr = m_weaponSpells.find(spellId);
    return itr != m_weaponSpells.end() ? FindOwned(itr->second) : nullptr;
}

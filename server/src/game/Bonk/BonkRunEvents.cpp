#include "BonkRun.h"
#include "BonkLocale.h"
#include "BonkMobAI.h"
#include "BonkPlayer.h"
#include "BonkQuests.h"
#include "Creature.h"
#include "HoaProtocol.h"
#include "Map.h"
#include "Player.h"
#include "WorldSession.h"
#include "Utilities/Random.h"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace
{
    uint32 const BONK_MINI_EVENT_RETRY_MS    = 10 * IN_MILLISECONDS;

    float const BONK_HORDE_BASE              = 8.0f;
    float const BONK_HORDE_PER_MINUTE        = 2.2f;
    float const BONK_HORDE_DENSER            = 0.25f;
    float const BONK_HORDE_ELITE_DISTANCE    = 22.0f;

    uint32 const BONK_GOBLIN_ENTRY           = 900011;
    uint32 const BONK_GOBLIN_SECONDS         = 20;
    float const BONK_GOBLIN_MIN_DISTANCE     = 18.0f;
    float const BONK_GOBLIN_MAX_DISTANCE     = 28.0f;
    float const BONK_GOBLIN_HEALTH           = 0.15f;
    float const BONK_GOBLIN_SPEED[3]         = { 0.85f, 0.95f, 1.05f };
    float const BONK_GOBLIN_SCALE            = 1.2f;
    uint32 const BONK_GOBLIN_GUARDS          = 2;
    float const BONK_GOBLIN_GUARD_SPREAD     = 4.0f;
    uint32 const BONK_GOBLIN_HEAD_START_MS   = 2000;
    float const BONK_EVENT_HEAD_START_SHARE  = 0.2f;
    char const* const BONK_GOBLIN_ICON       = "INV_Misc_Bone_HumanSkull_01";

    uint32 const BONK_BOUNTY_SECONDS         = 60;
    float const BONK_BOUNTY_MIN_DISTANCE     = 35.0f;
    float const BONK_BOUNTY_MAX_DISTANCE     = 50.0f;
    float const BONK_BOUNTY_HEALTH           = 4.0f;
    float const BONK_BOUNTY_SCALE            = 1.25f;
    char const* const BONK_BOUNTY_ICON       = "INV_Misc_Bone_HumanSkull_01";

    uint32 const BONK_SPELL_SPAWN_SMOKE      = 10389;

    uint32 const BONK_KOBOLD_ENTRY           = 475;
    uint32 const BONK_KOBOLD_COUNT           = 3;
    uint32 const BONK_KOBOLD_SECONDS         = 20;
    float const BONK_KOBOLD_MIN_DISTANCE     = 12.0f;
    float const BONK_KOBOLD_MAX_DISTANCE     = 35.0f;
    float const BONK_KOBOLD_GRAB_RANGE       = 12.0f;
    float const BONK_KOBOLD_HEALTH           = 0.09f;
    float const BONK_KOBOLD_SPEED[3]         = { 0.8f, 0.9f, 1.0f };
    uint32 const BONK_KOBOLD_HEAD_START_MS   = 2500;
    float const BONK_KOBOLD_SPREAD           = 0.6f;
    float const BONK_KOBOLD_HEADING_SPREAD   = 0.3f;
    uint32 const BONK_KOBOLD_SPOT_TRIES      = 6;
    float const BONK_KOBOLD_BONUS            = 0.1f;

    uint32 const BONK_SHARD_ENTRY            = 16136;
    uint32 const BONK_SHARD_COUNT            = 3;
    uint32 const BONK_SHARD_SECONDS          = 90;
    float const BONK_SHARD_MIN_DISTANCE      = 45.0f;
    float const BONK_SHARD_MAX_DISTANCE      = 90.0f;
    float const BONK_SHARD_SPREAD            = 35.0f;
    float const BONK_SHARD_HEALTH            = 0.43f;
    int32 const BONK_SHARD_SPAWN_MS          = 5000;
    uint32 const BONK_SHARD_ADDS             = 2;
    float const BONK_SHARD_VALOR             = 0.5f;
    float const BONK_SHARD_EXPERIENCE        = 0.25f;
    char const* const BONK_SHARD_ICON        = "Spell_Shadow_AnimateDead";
    uint32 const BONK_SCOURGE_ADDS[3]        = { 16299, 16141, 16298 };

    uint32 const BONK_PORTAL_ENTRY           = 9707;
    uint32 const BONK_PORTAL_SECONDS         = 75;
    float const BONK_PORTAL_MIN_DISTANCE     = 40.0f;
    float const BONK_PORTAL_MAX_DISTANCE     = 70.0f;
    float const BONK_PORTAL_HEALTH[3]        = { 0.86f, 1.14f, 1.43f };
    int32 const BONK_PORTAL_SPAWN_MS         = 6000;
    uint32 const BONK_PORTAL_ADDS            = 3;
    uint32 const BONK_PORTAL_ELITE_WAVE      = 3;
    uint32 const BONK_PORTAL_CHEST_CHOICES   = 4;
    char const* const BONK_PORTAL_ICON       = "Spell_Shadow_SummonInfernal";
    uint32 const BONK_DEMON_ADDS[3]          = { 12922, 6010, 6011 };

    float const BONK_EVENT_ADD_MIN           = 3.0f;
    float const BONK_EVENT_ADD_MAX           = 7.0f;

    uint32 const BONK_STAMPEDE_BEAST         = 3236;
    uint32 const BONK_STAMPEDE_BEASTS        = 7;
    float const BONK_STAMPEDE_SPACING        = 3.5f;
    float const BONK_STAMPEDE_BEHIND         = 35.0f;
    float const BONK_STAMPEDE_LENGTH         = 70.0f;
    uint32 const BONK_STAMPEDE_WARN_MS       = 2000;
    uint32 const BONK_STAMPEDE_SECOND_MS     = 1200;
    float const BONK_STAMPEDE_DAMAGE         = 2.0f;

    uint32 const BONK_CARAVAN_ENTRY          = 11564;
    float const BONK_CARAVAN_START           = 25.0f;
    float const BONK_CARAVAN_LENGTH          = 160.0f;
    float const BONK_CARAVAN_LEG             = 8.0f;
    float const BONK_CARAVAN_HALF_WIDTH      = 2.5f;
    float const BONK_CARAVAN_SPEED           = 2.6f;
    uint32 const BONK_CARAVAN_SPARE_SECONDS  = 3;
    uint32 const BONK_CARAVAN_BLOWS[3]       = { 40, 32, 26 };
    float const BONK_CARAVAN_REACH           = 5.0f;
    int32 const BONK_CARAVAN_WAVE_MS         = 5000;
    uint32 const BONK_CARAVAN_RAIDERS        = 3;
    float const BONK_CARAVAN_RAID_DISTANCE   = 22.0f;
    uint32 const BONK_CARAVAN_CHEST_CHOICES  = 4;
    char const* const BONK_CARAVAN_ICON      = "Ability_Mount_Kodo_01";

    char const* const MINI_EVENT_NAMES[MAX_BONK_MINI_EVENT] = { "horde", "goblin", "bounty", "kobolds", "scourge", "portal", "stampede", "caravan" };

}

char const* GetBonkMiniEventName(BonkMiniEventType type)
{
    return type < MAX_BONK_MINI_EVENT ? MINI_EVENT_NAMES[type] : "";
}

bool ParseBonkMiniEvent(char const* name, BonkMiniEventType& type)
{
    for (uint8 i = 0; i < MAX_BONK_MINI_EVENT; ++i)
        if (!strcmp(name, MINI_EVENT_NAMES[i]))
        {
            type = BonkMiniEventType(i);
            return true;
        }
    return false;
}

void BonkRun::UpdateMiniEvents(uint32 diff)
{
    if (m_miniEventActive)
    {
        if (m_miniEvent.targets.empty())
            UpdateMiniEventTarget(diff);
        else
            UpdateMiniEventGroup(diff);
        return;
    }

    if (!m_miniEventSlots || m_elapsedMs < m_nextMiniEventMs || m_bossSpawned)
        return;

    if (StartMiniEvent(PickMiniEvent(m_miniEventSlots)))
        m_miniEventSlots = 0;
    else
        m_nextMiniEventMs = m_elapsedMs + BONK_MINI_EVENT_RETRY_MS;
}

BonkMiniEventType BonkRun::PickMiniEvent(uint32 allowed) const
{
    std::vector<BonkMiniEventType> choices, repeats;
    for (uint8 i = 0; i < MAX_BONK_MINI_EVENT; ++i)
        if (allowed & (1u << i))
            (BonkMiniEventType(i) != m_lastMiniEvent ? choices : repeats).push_back(BonkMiniEventType(i));
    if (choices.empty())
        choices = repeats;
    if (choices.empty())
        return BONK_MINI_EVENT_HORDE;
    return choices[urand(0, uint32(choices.size()) - 1)];
}

bool BonkRun::StartMiniEvent(BonkMiniEventType type)
{
    m_miniEvent = MiniEvent();
    m_miniEvent.type = type;
    bool started = false;
    switch (type)
    {
        case BONK_MINI_EVENT_HORDE:  started = SpawnHorde(); break;
        case BONK_MINI_EVENT_GOBLIN: started = SpawnTreasureGoblin(); break;
        case BONK_MINI_EVENT_BOUNTY: started = SpawnBounty(); break;
        case BONK_MINI_EVENT_KOBOLDS:  started = SpawnKoboldThieves(); break;
        case BONK_MINI_EVENT_SCOURGE:  started = SpawnScourgeInvasion(); break;
        case BONK_MINI_EVENT_PORTAL:   started = SpawnDemonPortal(); break;
        case BONK_MINI_EVENT_STAMPEDE: started = SpawnStampede(); break;
        case BONK_MINI_EVENT_CARAVAN:  started = SpawnCaravan(); break;
        default:                     break;
    }
    BonkMobAI::SetNextAffixCount(-1);
    BonkMobAI::SetNextPlateIcon(nullptr);
    if (started)
        m_lastMiniEvent = type;
    return started;
}

bool BonkRun::SpawnHorde()
{
    uint32 const step = GetDifficultyStep();
    float const minutes = m_elapsedMs / float(MINUTE * IN_MILLISECONDS);
    BonkMapEvent ring;
    ring.second = m_elapsedMs / IN_MILLISECONDS;
    ring.type = BONK_EVENT_RING;
    ring.count = uint32((BONK_HORDE_BASE + BONK_HORDE_PER_MINUTE * minutes) * m_tier.minAliveMultiplier * (1.0f + BONK_HORDE_DENSER * step));
    if (!SpawnFormation(ring))
        return false;

    for (uint32 i = 0; i < step; ++i)
        if (BonkMapCreature const* elite = PickCreature(BONK_SPAWN_ELITE))
        {
            float x, y, z;
            if (FindSpawnPositionAt(frand(0.0f, 2.0f * M_PI_F), BONK_HORDE_ELITE_DISTANCE, x, y, z))
                SpawnMobAt(*elite, x, y, z);
        }

    m_player->GetBonkPlayer()->Notify(BONK_STRING_YOU_ARE_SURROUNDED);
    return true;
}

bool BonkRun::SpawnTreasureGoblin()
{
    float x, y, z;
    if (!FindSpawnPosition(x, y, z, BONK_GOBLIN_MIN_DISTANCE, BONK_GOBLIN_MAX_DISTANCE))
        return false;

    uint32 const step = GetDifficultyStep();
    BonkMapCreature goblin;
    goblin.entry = BONK_GOBLIN_ENTRY;
    goblin.kind = BONK_SPAWN_ELITE;
    goblin.healthMultiplier = BONK_GOBLIN_HEALTH;
    goblin.speed = BONK_GOBLIN_SPEED[step];
    goblin.scale = BONK_GOBLIN_SCALE;
    BonkMobAI::SetNextAffixCount(0);
    BonkMobAI::SetNextPlateIcon(BONK_GOBLIN_ICON);
    Creature* mob = SpawnMobAt(goblin, x, y, z);
    if (!mob)
        return false;
    mob->SetAvoidsBonkHazards(true);
    float const extra = GetUtility(BONK_UTILITY_EVENT_TIME);
    uint32 const seconds = BONK_GOBLIN_SECONDS + uint32(extra);
    if (BonkMobAI* ai = dynamic_cast<BonkMobAI*>(mob->AI()))
        ai->SetFleeing(step >= 1, BONK_GOBLIN_HEAD_START_MS + uint32(extra * BONK_EVENT_HEAD_START_SHARE * IN_MILLISECONDS));

    if (step >= 2)
        for (uint32 i = 0; i < BONK_GOBLIN_GUARDS; ++i)
            if (BonkMapCreature const* guard = PickCreature(BONK_SPAWN_ELITE))
            {
                float const guardX = x + frand(-BONK_GOBLIN_GUARD_SPREAD, BONK_GOBLIN_GUARD_SPREAD);
                float const guardY = y + frand(-BONK_GOBLIN_GUARD_SPREAD, BONK_GOBLIN_GUARD_SPREAD);
                float const guardZ = m_player->GetMap()->GetHeight(guardX, guardY, z + 5.0f, true, 15.0f);
                if (guardZ > INVALID_HEIGHT)
                    SpawnMobAt(*guard, guardX, guardY, guardZ);
            }

    StartMiniEventTarget(mob, GetString(BONK_STRING_EVENT_TREASURE_GOBLIN), seconds);
    m_miniEvent.objectiveId = m_objectives.Follow(m_player, BONK_OBJECTIVE_EVENT, mob, GetString(BONK_STRING_EVENT_TREASURE_GOBLIN), seconds,
        BONK_GOBLIN_ICON, GetString(BONK_STRING_EVENT_TREASURE_GOBLIN_TEXT));
    m_player->GetBonkPlayer()->Notify(BONK_STRING_TREASURE_GOBLIN_APPEARED_CATCH_IT);
    return true;
}

bool BonkRun::SpawnBounty()
{
    BonkMapCreature const* pick = PickCreature(BONK_SPAWN_ELITE);
    float x, y, z;
    if (!pick || !FindSpawnPosition(x, y, z, BONK_BOUNTY_MIN_DISTANCE, BONK_BOUNTY_MAX_DISTANCE))
        return false;

    BonkMapCreature bounty = *pick;
    bounty.healthMultiplier *= BONK_BOUNTY_HEALTH;
    bounty.scale = (bounty.scale > 0.0f ? bounty.scale : 1.0f) * BONK_BOUNTY_SCALE;
    BonkMobAI::SetNextAffixCount(int32(GetDifficultyStep()));
    BonkMobAI::SetNextPlateIcon(BONK_BOUNTY_ICON);
    Creature* mob = SpawnMobAt(bounty, x, y, z);
    if (!mob)
        return false;

    std::string const name = m_player->GetBonkPlayer()->GetLocalName(mob);
    uint32 const seconds = BONK_BOUNTY_SECONDS + uint32(GetUtility(BONK_UTILITY_EVENT_TIME));
    StartMiniEventTarget(mob, GetString(BONK_STRING_EVENT_BOUNTY, { name }), seconds);
    m_player->GetBonkPlayer()->Notify(BONK_STRING_BOUNTY_IS_OUT_ON_KILL, { name, std::to_string(seconds) });
    return true;
}

void BonkRun::StartMiniEventTarget(Creature* target, std::string const& label, uint32 seconds)
{
    m_miniEvent.target = target->GetObjectGuid();
    m_miniEvent.label = label;
    m_miniEvent.leftMs = seconds * IN_MILLISECONDS;
    m_miniEvent.totalSeconds = seconds;
    m_miniEventActive = true;
    SendMiniEventTimer();
}

void BonkRun::UpdateMiniEventTarget(uint32 diff)
{
    Creature* target = m_player->GetMap()->GetCreature(m_miniEvent.target);
    if (!target || !target->IsAlive())
    {
        EndMiniEvent();
        return;
    }

    if (m_miniEvent.leftMs > diff)
    {
        m_miniEvent.leftMs -= diff;
        SendMiniEventTimer();
        return;
    }

    BonkPlayer* bonk = m_player->GetBonkPlayer();
    bonk->Notify(m_miniEvent.type == BONK_MINI_EVENT_GOBLIN ? BONK_STRING_TREASURE_GOBLIN_GOT_AWAY : BONK_STRING_SLIPPED_AWAY, { bonk->GetLocalName(target) });
    if (bonk->IsAddonReady())
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteMobDead(data, bonk->GetLocalName(target), target->GetPlateId(), BonkMobAI::GetUnitGuidText(target));
        m_player->GetSession()->SendPacket(&data);
    }
    target->CastSpell(target, BONK_SPELL_SPAWN_SMOKE, true);
    target->DespawnOrUnsummon(500);
    EndMiniEvent();
}

void BonkRun::OnMiniEventTargetKilled(Creature* mob)
{
    if (m_miniEventActive && !m_miniEvent.targets.empty())
    {
        OnMiniEventGroupKilled(mob);
        return;
    }
    if (!m_miniEventActive || mob->GetObjectGuid() != m_miniEvent.target)
        return;

    BonkPlayer* bonk = m_player->GetBonkPlayer();
    sBonkQuests.OnProgress(m_player, BONK_QUEST_MINI_EVENTS, m_miniEvent.type, 1);
    float const x = mob->GetPositionX(), y = mob->GetPositionY(), z = mob->GetPositionZ();
    if (m_miniEvent.type == BONK_MINI_EVENT_GOBLIN)
    {
        uint32 const valor = GetChestCost();
        GainValor(valor);
        SpawnChest(true, x, y, z);
        bonk->Notify(BONK_STRING_YOU_CAUGHT_TREASURE_GOBLIN_IT, { std::to_string(valor) });
    }
    else
    {
        BonkMobAI const* ai = dynamic_cast<BonkMobAI const*>(mob->AI());
        SpawnChest(true, x, y, z, 3 + (ai ? ai->GetAffixCount() : 0));
        bonk->Notify(BONK_STRING_YOU_CLAIMED_BOUNTY_ON_AND, { bonk->GetLocalName(mob) });
    }
    EndMiniEvent();
    SendState();
}

void BonkRun::SendMiniEventTimer(bool force) const
{
    uint32 const seconds = m_miniEventActive ? (m_miniEvent.leftMs + IN_MILLISECONDS - 1) / IN_MILLISECONDS : 0;
    if (!force && seconds == m_miniEvent.shownSeconds)
        return;
    m_miniEvent.shownSeconds = seconds;
    if (m_player->GetBonkPlayer()->IsAddonReady())
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteEventTimer(data, m_miniEvent.label, seconds, m_miniEvent.totalSeconds);
        m_player->GetSession()->SendPacket(&data);
    }
}

void BonkRun::DespawnMiniEvent()
{
    if (!m_miniEventActive)
        return;
    if (Map* map = m_player->FindMap())
    {
        auto const despawnUntracked = [this, map](ObjectGuid const& guid)
        {
            if (std::find(m_mobs.begin(), m_mobs.end(), guid) != m_mobs.end())
                return;
            if (Creature* target = map->GetCreature(guid))
                target->DespawnOrUnsummon();
        };
        despawnUntracked(m_miniEvent.target);
        for (ObjectGuid const& guid : m_miniEvent.targets)
            despawnUntracked(guid);
    }
    EndMiniEvent();
}

void BonkRun::EndMiniEvent()
{
    bool const timed = !m_miniEvent.target.IsEmpty() || m_miniEvent.total;
    for (auto const& itr : m_miniEvent.objectives)
        RemoveObjective(itr.second);
    if (m_miniEvent.objectiveId)
        RemoveObjective(m_miniEvent.objectiveId);
    else
        m_spawnPoints.Release(m_miniEvent.spot.x, m_miniEvent.spot.y);
    m_miniEvent = MiniEvent();
    m_miniEventActive = false;
    if (timed && m_player->GetBonkPlayer()->IsAddonReady())
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteEventTimer(data, "", 0, 0);
        m_player->GetSession()->SendPacket(&data);
    }
}

bool BonkRun::StartMiniEventNow(BonkMiniEventType type, std::string& error)
{
    if (m_state != STATE_RUNNING || m_paused)
    {
        error = GetString(BONK_STRING_ONLY_RUNNING_STAGE_MINI_EVENT);
        return false;
    }
    if (m_miniEventActive)
    {
        if (Creature* target = m_player->GetMap()->GetCreature(m_miniEvent.target))
            target->DespawnOrUnsummon();
        for (ObjectGuid const& guid : m_miniEvent.targets)
            if (Creature* target = m_player->GetMap()->GetCreature(guid))
                target->DespawnOrUnsummon();
        EndMiniEvent();
    }
    if (!StartMiniEvent(type))
    {
        error = GetString(BONK_STRING_MINI_EVENT_COULD_NOT_START);
        return false;
    }
    return true;
}

bool BonkRun::IsMiniEventTarget(ObjectGuid const& guid) const
{
    if (!m_miniEventActive)
        return false;
    return guid == m_miniEvent.target || std::find(m_miniEvent.targets.begin(), m_miniEvent.targets.end(), guid) != m_miniEvent.targets.end() ||
        std::find(m_miniEvent.raiders.begin(), m_miniEvent.raiders.end(), guid) != m_miniEvent.raiders.end();
}

bool BonkRun::SpawnKoboldThieves()
{
    uint32 const step = GetDifficultyStep();
    uint32 const count = BONK_KOBOLD_COUNT + step;
    uint32 const bonus = uint32(GetNextLevelXp() * BONK_KOBOLD_BONUS);
    float const extra = GetUtility(BONK_UTILITY_EVENT_TIME);
    uint32 const seconds = BONK_KOBOLD_SECONDS + uint32(extra);
    uint32 const headStart = BONK_KOBOLD_HEAD_START_MS + uint32(extra * BONK_EVENT_HEAD_START_SHARE * IN_MILLISECONDS);

    float heading = frand(0.0f, 2.0f * M_PI_F);
    float seedX, seedY, seedZ;
    if (FindLyingOrb(heading, M_PI_F, BONK_KOBOLD_MIN_DISTANCE, BONK_KOBOLD_MAX_DISTANCE, seedX, seedY, seedZ))
        heading = m_player->GetAngle(seedX, seedY);

    m_miniEvent.targets.clear();
    m_miniEvent.stolen.clear();
    for (uint32 i = 0; i < count; ++i)
    {
        float x, y, z;
        bool byOrb = FindLyingOrb(heading, BONK_KOBOLD_SPREAD, BONK_KOBOLD_MIN_DISTANCE, BONK_KOBOLD_MAX_DISTANCE, x, y, z);
        if (byOrb)
        {
            float const angle = frand(0.0f, 2.0f * M_PI_F);
            float const kx = x + 2.0f * std::cos(angle), ky = y + 2.0f * std::sin(angle);
            float const kz = m_player->GetMap()->GetHeight(kx, ky, z + 5.0f, true, 10.0f);
            if (kz > INVALID_HEIGHT && IsBonkDryGround(m_player->GetMap(), kx, ky, kz))
            {
                x = kx;
                y = ky;
                z = kz;
            }
        }
        else if (!FindKoboldSpot(heading, x, y, z))
            continue;

        BonkMapCreature kobold;
        kobold.entry = BONK_KOBOLD_ENTRY;
        kobold.kind = BONK_SPAWN_ELITE;
        kobold.healthMultiplier = BONK_KOBOLD_HEALTH;
        kobold.speed = BONK_KOBOLD_SPEED[step];
        BonkMobAI::SetNextAffixCount(0);
        BonkMobAI::SetNextPlateIcon(BONK_GOBLIN_ICON);
        Creature* mob = SpawnMobAt(kobold, x, y, z);
        if (!mob)
            continue;
        mob->SetAvoidsBonkHazards(true);
        if (BonkMobAI* ai = dynamic_cast<BonkMobAI*>(mob->AI()))
        {
            ai->SetFleeing(false, headStart);
            ai->SetFleeHeading(heading + frand(-BONK_KOBOLD_HEADING_SPREAD, BONK_KOBOLD_HEADING_SPREAD));
        }
        if (m_miniEvent.targets.empty())
            mob->MonsterSay(GetString(BONK_STRING_KOBOLD_SHOUT).c_str());
        m_miniEvent.stolen[mob->GetObjectGuid()] = StealOrbs(x, y, BONK_KOBOLD_GRAB_RANGE) + bonus;
        m_miniEvent.targets.push_back(mob->GetObjectGuid());
        m_miniEvent.objectives[mob->GetObjectGuid()] = m_objectives.Follow(m_player, BONK_OBJECTIVE_EVENT, mob, GetString(BONK_STRING_EVENT_KOBOLD_THIEF), seconds,
            BONK_GOBLIN_ICON, GetString(BONK_STRING_EVENT_KOBOLD_THIEF_TEXT));
    }
    if (m_miniEvent.targets.empty())
        return false;

    StartMiniEventGroup(GetString(BONK_STRING_EVENT_KOBOLD_THIEVES), seconds);
    m_player->GetBonkPlayer()->Notify(BONK_STRING_KOBOLD_THIEVES_STOLE_YOUR_EXPERIENCE);
    return true;
}

bool BonkRun::FindKoboldSpot(float heading, float& x, float& y, float& z) const
{
    for (uint32 attempt = 0; attempt < BONK_KOBOLD_SPOT_TRIES; ++attempt)
    {
        float const angle = heading + frand(-BONK_KOBOLD_SPREAD, BONK_KOBOLD_SPREAD);
        if (FindSpawnPositionAt(angle, frand(BONK_KOBOLD_MIN_DISTANCE, BONK_KOBOLD_MAX_DISTANCE), x, y, z))
            return true;
    }
    return FindSpawnPosition(x, y, z, BONK_KOBOLD_MIN_DISTANCE, BONK_KOBOLD_MAX_DISTANCE);
}

bool BonkRun::SpawnScourgeInvasion()
{
    uint32 const step = GetDifficultyStep();
    uint32 const count = BONK_SHARD_COUNT + (step >= 1 ? 1 : 0);
    uint32 const seconds = BONK_SHARD_SECONDS + uint32(GetUtility(BONK_UTILITY_EVENT_TIME));

    m_miniEvent.targets.clear();
    std::vector<std::pair<float, float>> placed;
    for (uint32 i = 0; i < count; ++i)
    {
        float x = 0.0f, y = 0.0f, z = 0.0f;
        bool found = false;
        for (uint32 attempt = 0; attempt < 8 && !found; ++attempt)
        {
            if (!FindSpawnPosition(x, y, z, BONK_SHARD_MIN_DISTANCE, BONK_SHARD_MAX_DISTANCE))
                break;
            found = std::none_of(placed.begin(), placed.end(), [x, y](std::pair<float, float> const& other)
                { return (other.first - x) * (other.first - x) + (other.second - y) * (other.second - y) < BONK_SHARD_SPREAD * BONK_SHARD_SPREAD; });
        }
        if (!found)
            continue;

        BonkMapCreature shard;
        shard.entry = BONK_SHARD_ENTRY;
        shard.kind = BONK_SPAWN_ELITE;
        shard.healthMultiplier = BONK_SHARD_HEALTH;
        BonkMobAI::SetNextAffixCount(0);
        BonkMobAI::SetNextPlateIcon(BONK_SHARD_ICON);
        Creature* mob = SpawnMobAt(shard, x, y, z);
        if (!mob)
            continue;
        if (BonkMobAI* ai = dynamic_cast<BonkMobAI*>(mob->AI()))
            ai->SetStationary();
        placed.emplace_back(x, y);
        m_miniEvent.targets.push_back(mob->GetObjectGuid());
        m_miniEvent.objectives[mob->GetObjectGuid()] = m_objectives.Follow(m_player, BONK_OBJECTIVE_EVENT, mob, GetString(BONK_STRING_EVENT_NECROTIC_SHARD), seconds,
            BONK_SHARD_ICON, GetString(BONK_STRING_EVENT_NECROTIC_SHARD_TEXT));
        if (step >= 2)
            SpawnEventAdds(mob, 0, 1);
    }
    if (m_miniEvent.targets.empty())
        return false;

    m_miniEvent.spawnMs = BONK_SHARD_SPAWN_MS / 2;
    StartMiniEventGroup(GetString(BONK_STRING_EVENT_SCOURGE_INVASION), seconds);
    m_player->GetBonkPlayer()->Notify(BONK_STRING_SCOURGE_INVADES_DESTROY_NECROTIC_SHARDS);
    return true;
}

bool BonkRun::SpawnDemonPortal()
{
    uint32 const step = GetDifficultyStep();
    float x, y, z;
    if (!FindSpawnPosition(x, y, z, BONK_PORTAL_MIN_DISTANCE, BONK_PORTAL_MAX_DISTANCE))
        return false;

    BonkMapCreature portal;
    portal.entry = BONK_PORTAL_ENTRY;
    portal.kind = BONK_SPAWN_ELITE;
    portal.healthMultiplier = BONK_PORTAL_HEALTH[step];
    BonkMobAI::SetNextAffixCount(0);
    BonkMobAI::SetNextPlateIcon(BONK_PORTAL_ICON);
    Creature* mob = SpawnMobAt(portal, x, y, z);
    if (!mob)
        return false;
    if (BonkMobAI* ai = dynamic_cast<BonkMobAI*>(mob->AI()))
        ai->SetStationary();

    uint32 const seconds = BONK_PORTAL_SECONDS + uint32(GetUtility(BONK_UTILITY_EVENT_TIME));
    m_miniEvent.targets.assign(1, mob->GetObjectGuid());
    m_miniEvent.objectives[mob->GetObjectGuid()] = m_objectives.Follow(m_player, BONK_OBJECTIVE_EVENT, mob, GetString(BONK_STRING_EVENT_DEMON_PORTAL), seconds,
        BONK_PORTAL_ICON, GetString(BONK_STRING_EVENT_DEMON_PORTAL_TEXT));
    m_miniEvent.spawnMs = 0;
    StartMiniEventGroup(GetString(BONK_STRING_EVENT_DEMON_PORTAL), seconds);
    m_player->GetBonkPlayer()->Notify(BONK_STRING_DEMON_PORTAL_OPENS_DESTROY_IT);
    return true;
}

bool BonkRun::SpawnStampede()
{
    BonkMapCreature beast;
    beast.entry = BONK_STAMPEDE_BEAST;
    for (BonkMapCreature const& creature : m_map.creatures)
        if (creature.kind == BONK_SPAWN_NORMAL && creature.archetype == BONK_ARCHETYPE_CHARGER)
        {
            beast = creature;
            break;
        }
    beast.kind = BONK_SPAWN_NORMAL;
    beast.archetype = BONK_ARCHETYPE_GRUNT;

    uint32 const step = GetDifficultyStep();
    uint32 const count = BONK_STAMPEDE_BEASTS + 2 * step;
    float heroX, heroY, heroZ;
    m_player->GetPosition(heroX, heroY, heroZ);
    float const first = frand(0.0f, 2.0f * M_PI_F);
    uint32 spawned = 0;
    for (uint32 wall = 0; wall < (step >= 2 ? 2u : 1u); ++wall)
    {
        float const angle = first + wall * M_PI_F / 2.0f;
        float const sideX = -std::sin(angle), sideY = std::cos(angle);
        uint32 const warnMs = BONK_STAMPEDE_WARN_MS + wall * BONK_STAMPEDE_SECOND_MS;
        for (uint32 i = 0; i < count; ++i)
        {
            float const offset = (float(i) - (count - 1) / 2.0f) * BONK_STAMPEDE_SPACING;
            float const x = heroX - BONK_STAMPEDE_BEHIND * std::cos(angle) + offset * sideX;
            float const y = heroY - BONK_STAMPEDE_BEHIND * std::sin(angle) + offset * sideY;
            float const z = m_player->GetMap()->GetHeight(x, y, heroZ + 10.0f, true, 30.0f);
            if (z <= INVALID_HEIGHT)
                continue;
            Creature* mob = SpawnMobAt(beast, x, y, z);
            if (!mob)
                continue;
            if (BonkMobAI* ai = dynamic_cast<BonkMobAI*>(mob->AI()))
                ai->StartStampede(m_player, angle, BONK_STAMPEDE_LENGTH, warnMs, BONK_STAMPEDE_DAMAGE);
            ++spawned;
        }
    }
    if (!spawned)
        return false;
    m_player->GetBonkPlayer()->Notify(BONK_STRING_STAMPEDE_IS_COMING_GET_OUT);
    return true;
}

void BonkRun::SpawnEventAdds(Creature const* source, uint32 count, uint32 eliteCount)
{
    bool const scourge = m_miniEvent.type == BONK_MINI_EVENT_SCOURGE;
    uint32 const* entries = scourge ? BONK_SCOURGE_ADDS : BONK_DEMON_ADDS;
    for (uint32 i = 0; i < count + eliteCount; ++i)
    {
        if (m_mobs.size() >= m_tier.maxAlive)
            return;
        float const angle = frand(0.0f, 2.0f * M_PI_F);
        float const distance = frand(BONK_EVENT_ADD_MIN, BONK_EVENT_ADD_MAX);
        float const x = source->GetPositionX() + distance * std::cos(angle);
        float const y = source->GetPositionY() + distance * std::sin(angle);
        float const z = m_player->GetMap()->GetHeight(x, y, source->GetPositionZ() + 5.0f, true, 15.0f);
        if (z <= INVALID_HEIGHT)
            continue;

        BonkMapCreature add;
        bool const elite = i >= count;
        if (elite)
        {
            BonkMapCreature const* pick = scourge ? PickCreature(BONK_SPAWN_ELITE) : nullptr;
            if (pick)
                add = *pick;
            else
            {
                add.entry = BONK_DEMON_ADDS[2];
                add.kind = BONK_SPAWN_ELITE;
            }
        }
        else
        {
            uint32 const roll = urand(0, 9);
            uint32 const which = roll < 6 ? 0 : roll < 9 ? 1 : 2;
            add.entry = entries[which];
            add.kind = BONK_SPAWN_NORMAL;
            add.archetype = which == 0 ? BONK_ARCHETYPE_SWARMER : which == 1 ? BONK_ARCHETYPE_GRUNT : BONK_ARCHETYPE_BRUISER;
        }
        if (elite)
            BonkMobAI::SetNextAffixCount(-1);
        SpawnMobAt(add, x, y, z);
    }
}

void BonkRun::StartMiniEventGroup(std::string const& label, uint32 seconds)
{
    m_miniEvent.label = label;
    m_miniEvent.leftMs = seconds * IN_MILLISECONDS;
    m_miniEvent.totalSeconds = seconds;
    m_miniEvent.total = uint32(m_miniEvent.targets.size());
    m_miniEventActive = true;
    SendMiniEventTimer(true);
}

void BonkRun::UpdateMiniEventGroup(uint32 diff)
{
    if (m_miniEvent.type == BONK_MINI_EVENT_CARAVAN)
    {
        if (UpdateCaravan(diff))
            return;
        if (m_miniEvent.leftMs > diff)
        {
            m_miniEvent.leftMs -= diff;
            SendMiniEventTimer();
        }
        else
            EndCaravan(false);
        return;
    }

    Map* map = m_player->GetMap();
    for (auto itr = m_miniEvent.targets.begin(); itr != m_miniEvent.targets.end();)
    {
        Creature* target = map->GetCreature(*itr);
        if (target && target->IsAlive())
        {
            ++itr;
            continue;
        }
        auto const objective = m_miniEvent.objectives.find(*itr);
        if (objective != m_miniEvent.objectives.end())
        {
            RemoveObjective(objective->second);
            m_miniEvent.objectives.erase(objective);
        }
        itr = m_miniEvent.targets.erase(itr);
    }
    if (m_miniEvent.targets.empty())
    {
        EndMiniEvent();
        return;
    }

    if (m_miniEvent.type == BONK_MINI_EVENT_SCOURGE || m_miniEvent.type == BONK_MINI_EVENT_PORTAL)
    {
        m_miniEvent.spawnMs -= int32(diff);
        if (m_miniEvent.spawnMs <= 0)
        {
            uint32 const step = GetDifficultyStep();
            bool const scourge = m_miniEvent.type == BONK_MINI_EVENT_SCOURGE;
            m_miniEvent.spawnMs += scourge ? BONK_SHARD_SPAWN_MS : BONK_PORTAL_SPAWN_MS;
            ++m_miniEvent.waves;
            uint32 const adds = (scourge ? BONK_SHARD_ADDS : BONK_PORTAL_ADDS) + step;
            uint32 const elites = !scourge && step >= 1 && m_miniEvent.waves % BONK_PORTAL_ELITE_WAVE == 0 ? 1 : 0;
            for (ObjectGuid const& guid : m_miniEvent.targets)
                if (Creature const* source = map->GetCreature(guid))
                    SpawnEventAdds(source, adds, elites);
        }
    }

    if (m_miniEvent.leftMs > diff)
    {
        m_miniEvent.leftMs -= diff;
        SendMiniEventTimer();
        return;
    }

    BonkPlayer* bonk = m_player->GetBonkPlayer();
    switch (m_miniEvent.type)
    {
        case BONK_MINI_EVENT_KOBOLDS: bonk->Notify(BONK_STRING_KOBOLDS_GOT_AWAY_WITH_YOUR); break;
        case BONK_MINI_EVENT_SCOURGE: bonk->Notify(BONK_STRING_SCOURGE_INVASION_MOVES_ON); break;
        case BONK_MINI_EVENT_PORTAL:  bonk->Notify(BONK_STRING_DEMON_PORTAL_CLOSES); break;
        default: break;
    }
    for (ObjectGuid const& guid : m_miniEvent.targets)
        if (Creature* target = map->GetCreature(guid))
        {
            if (bonk->IsAddonReady())
            {
                WorldPacket data(SMSG_HOA_MESSAGE);
                HoAWriteMobDead(data, bonk->GetLocalName(target), target->GetPlateId(), BonkMobAI::GetUnitGuidText(target));
                m_player->GetSession()->SendPacket(&data);
            }
            target->CastSpell(target, BONK_SPELL_SPAWN_SMOKE, true);
            target->DespawnOrUnsummon(500);
        }
    EndMiniEvent();
}

void BonkRun::OnMiniEventGroupKilled(Creature* mob)
{
    auto const itr = std::find(m_miniEvent.targets.begin(), m_miniEvent.targets.end(), mob->GetObjectGuid());
    if (itr == m_miniEvent.targets.end())
        return;
    m_miniEvent.targets.erase(itr);
    auto const objective = m_miniEvent.objectives.find(mob->GetObjectGuid());
    if (objective != m_miniEvent.objectives.end())
    {
        RemoveObjective(objective->second);
        m_miniEvent.objectives.erase(objective);
    }

    BonkPlayer* bonk = m_player->GetBonkPlayer();
    float const x = mob->GetPositionX(), y = mob->GetPositionY(), z = mob->GetPositionZ();
    uint32 const done = m_miniEvent.total - uint32(m_miniEvent.targets.size());
    switch (m_miniEvent.type)
    {
        case BONK_MINI_EVENT_KOBOLDS:
        {
            auto const loot = m_miniEvent.stolen.find(mob->GetObjectGuid());
            if (loot != m_miniEvent.stolen.end() && loot->second)
                SpawnOrb(x, y, z, loot->second, BONK_ORB_RED);
            bonk->Notify(BONK_STRING_YOU_CAUGHT_KOBOLD_THIEF, { std::to_string(done), std::to_string(m_miniEvent.total) });
            break;
        }
        case BONK_MINI_EVENT_SCOURGE:
        {
            uint32 const valor = std::max(1u, uint32(GetChestCost() * BONK_SHARD_VALOR + 0.5f));
            GainValor(valor);
            SpawnOrb(x, y, z, uint32(GetNextLevelXp() * BONK_SHARD_EXPERIENCE), BONK_ORB_RED);
            bonk->Notify(BONK_STRING_YOU_DESTROYED_NECROTIC_SHARD_AND, { std::to_string(done), std::to_string(m_miniEvent.total), std::to_string(valor) });
            SendState();
            break;
        }
        case BONK_MINI_EVENT_PORTAL:
            SpawnChest(true, x, y, z, BONK_PORTAL_CHEST_CHOICES);
            bonk->Notify(BONK_STRING_DEMON_PORTAL_IS_DESTROYED_LEAVING);
            break;
        default:
            break;
    }

    if (!m_miniEvent.targets.empty())
        return;
    sBonkQuests.OnProgress(m_player, BONK_QUEST_MINI_EVENTS, m_miniEvent.type, 1);
    if (m_miniEvent.type == BONK_MINI_EVENT_SCOURGE)
        bonk->Notify(BONK_STRING_YOU_TURNED_BACK_SCOURGE_INVASION);
    else if (m_miniEvent.type == BONK_MINI_EVENT_KOBOLDS)
        bonk->Notify(BONK_STRING_YOU_CAUGHT_EVERY_KOBOLD_THIEF);
    EndMiniEvent();
}

bool BonkRun::SpawnCaravan()
{
    uint32 const step = GetDifficultyStep();
    float const angle = frand(0.0f, 2.0f * M_PI_F);
    float x, y, z;
    if (!FindSpawnPositionAt(angle, BONK_CARAVAN_START, x, y, z))
        return false;
    float const heading = angle + M_PI_F + frand(-0.4f, 0.4f);
    Map* map = m_player->GetMap();

    auto legReach = [map, heading](float fromX, float fromY, float fromZ)
    {
        float reach = BONK_CARAVAN_LEG;
        for (float side : { 0.0f, -BONK_CARAVAN_HALF_WIDTH, BONK_CARAVAN_HALF_WIDTH })
        {
            float const sx = fromX + side * std::cos(heading + M_PI_F / 2.0f);
            float const sy = fromY + side * std::sin(heading + M_PI_F / 2.0f);
            float sz = map->GetHeight(sx, sy, fromZ + 5.0f, true, 15.0f);
            if (sz <= INVALID_HEIGHT)
                return 0.0f;
            float nx = sx + BONK_CARAVAN_LEG * std::cos(heading), ny = sy + BONK_CARAVAN_LEG * std::sin(heading), nz = sz;
            if (!map->GetWalkHitPosition(nullptr, sx, sy, sz, nx, ny, nz))
                return 0.0f;
            reach = std::min(reach, std::hypot(nx - sx, ny - sy));
        }
        return reach;
    };

    std::vector<BonkSpot> path;
    float px = x, py = y, pz = z;
    for (float walked = BONK_CARAVAN_LEG; walked <= BONK_CARAVAN_LENGTH; walked += BONK_CARAVAN_LEG)
    {
        if (legReach(px, py, pz) < BONK_CARAVAN_LEG - 0.5f)
            break;
        float const nx = px + BONK_CARAVAN_LEG * std::cos(heading), ny = py + BONK_CARAVAN_LEG * std::sin(heading);
        float const nz = map->GetHeight(nx, ny, pz + 5.0f, true, 15.0f);
        if (nz <= INVALID_HEIGHT || !IsBonkDryGround(map, nx, ny, nz))
            break;
        BonkSpot spot;
        spot.x = nx;
        spot.y = ny;
        spot.z = nz;
        path.push_back(spot);
        px = nx;
        py = ny;
        pz = nz;
    }
    if (path.size() * BONK_CARAVAN_LEG < BONK_CARAVAN_LENGTH / 2.0f)
        return false;

    Creature* caravan = SummonCaravan(BONK_CARAVAN_ENTRY, x, y, z, heading);
    if (!caravan)
        return false;
    caravan->SetAvoidsBonkHazards(true);

    m_miniEvent.targets.assign(1, caravan->GetObjectGuid());
    m_miniEvent.path = path;
    m_miniEvent.pathIndex = 0;
    m_miniEvent.raiders.clear();
    m_miniEvent.tickMs = 0;
    m_miniEvent.blows = 0;
    m_miniEvent.maxBlows = BONK_CARAVAN_BLOWS[step];
    m_miniEvent.warned = 0;
    m_miniEvent.spawnMs = BONK_CARAVAN_WAVE_MS / 2;
    m_miniEvent.waves = 0;
    caravan->GetMotionMaster()->MovePoint(1, path[0].x, path[0].y, path[0].z, MOVE_WALK_MODE, BONK_CARAVAN_SPEED);

    uint32 const seconds = uint32(BONK_CARAVAN_LEG * path.size() / BONK_CARAVAN_SPEED) + BONK_CARAVAN_SPARE_SECONDS;
    m_miniEvent.objectives[caravan->GetObjectGuid()] = m_objectives.Follow(m_player, BONK_OBJECTIVE_EVENT, caravan, GetString(BONK_STRING_EVENT_KODO_CARAVAN), seconds,
        BONK_CARAVAN_ICON, GetString(BONK_STRING_EVENT_KODO_CARAVAN_TEXT));
    StartMiniEventGroup(GetString(BONK_STRING_EVENT_KODO_CARAVAN), seconds);
    m_player->GetBonkPlayer()->Notify(BONK_STRING_KODO_CARAVAN_IS_PASSING_THROUGH);
    return true;
}

bool BonkRun::UpdateCaravan(uint32 diff)
{
    Map* map = m_player->GetMap();
    Creature* caravan = m_miniEvent.targets.empty() ? nullptr : map->GetCreature(m_miniEvent.targets.front());
    if (!caravan || !caravan->IsAlive())
    {
        EndCaravan(false);
        return true;
    }

    BonkSpot const& leg = m_miniEvent.path[m_miniEvent.pathIndex];
    if (caravan->GetDistance2d(leg.x, leg.y) < 2.0f)
    {
        if (++m_miniEvent.pathIndex >= m_miniEvent.path.size())
        {
            EndCaravan(true);
            return true;
        }
        BonkSpot const& next = m_miniEvent.path[m_miniEvent.pathIndex];
        caravan->GetMotionMaster()->MovePoint(1, next.x, next.y, next.z, MOVE_WALK_MODE, BONK_CARAVAN_SPEED);
    }
    else if (!caravan->IsMoving())
        caravan->GetMotionMaster()->MovePoint(1, leg.x, leg.y, leg.z, MOVE_PATHFINDING | MOVE_WALK_MODE, BONK_CARAVAN_SPEED);

    uint32 const step = GetDifficultyStep();
    m_miniEvent.spawnMs -= int32(diff);
    if (m_miniEvent.spawnMs <= 0)
    {
        m_miniEvent.spawnMs += BONK_CARAVAN_WAVE_MS;
        ++m_miniEvent.waves;
        uint32 const count = BONK_CARAVAN_RAIDERS + step;
        bool const elite = step >= 2 && m_miniEvent.waves % 2 == 0;
        for (uint32 i = 0; i < count + (elite ? 1 : 0); ++i)
        {
            if (m_mobs.size() >= m_tier.maxAlive)
                break;
            BonkMapCreature const* pick = PickCreature(i < count ? BONK_SPAWN_NORMAL : BONK_SPAWN_ELITE);
            if (!pick)
                continue;
            float const angle = frand(0.0f, 2.0f * M_PI_F);
            float const rx = caravan->GetPositionX() + BONK_CARAVAN_RAID_DISTANCE * std::cos(angle);
            float const ry = caravan->GetPositionY() + BONK_CARAVAN_RAID_DISTANCE * std::sin(angle);
            float const rz = map->GetHeight(rx, ry, caravan->GetPositionZ() + 10.0f, true, 30.0f);
            if (rz <= INVALID_HEIGHT)
                continue;
            if (Creature* raider = SpawnMobAt(*pick, rx, ry, rz))
                if (BonkMobAI* ai = dynamic_cast<BonkMobAI*>(raider->AI()))
                {
                    ai->SetRaidTarget(caravan->GetObjectGuid());
                    m_miniEvent.raiders.push_back(raider->GetObjectGuid());
                }
        }
    }

    m_miniEvent.tickMs += diff;
    if (m_miniEvent.tickMs < IN_MILLISECONDS)
        return false;
    m_miniEvent.tickMs -= IN_MILLISECONDS;
    uint32 blows = 0;
    for (auto itr = m_miniEvent.raiders.begin(); itr != m_miniEvent.raiders.end();)
    {
        Creature* raider = map->GetCreature(*itr);
        if (!raider || !raider->IsAlive())
        {
            itr = m_miniEvent.raiders.erase(itr);
            continue;
        }
        if (raider->IsWithinDistInMap(caravan, BONK_CARAVAN_REACH))
        {
            raider->SetFacingToObject(caravan);
            raider->HandleEmote(EMOTE_ONESHOT_ATTACK1H);
            ++blows;
        }
        ++itr;
    }
    if (!blows)
        return false;
    m_miniEvent.blows += blows;
    uint32 const left = m_miniEvent.blows >= m_miniEvent.maxBlows ? 0 : m_miniEvent.maxBlows - m_miniEvent.blows;
    caravan->SetHealth(std::max(1u, uint32(uint64(caravan->GetMaxHealth()) * left / m_miniEvent.maxBlows)));
    if (!left)
    {
        EndCaravan(false);
        return true;
    }
    uint8 const mark = left * 4 <= m_miniEvent.maxBlows ? 2 : left * 2 <= m_miniEvent.maxBlows ? 1 : 0;
    if (mark > m_miniEvent.warned)
    {
        m_miniEvent.warned = mark;
        m_player->GetBonkPlayer()->Notify(mark == 2 ? BONK_STRING_CARAVAN_ABOUT_TO_FALL : BONK_STRING_CARAVAN_UNDER_ATTACK);
    }
    return false;
}

void BonkRun::PauseCaravan(bool paused)
{
    Creature* caravan = m_miniEvent.targets.empty() ? nullptr : m_player->GetMap()->GetCreature(m_miniEvent.targets.front());
    if (!caravan)
        return;
    caravan->SetTimeFrozen(paused && caravan->IsAlive());
    if (paused)
    {
        caravan->StopMoving();
        caravan->GetMotionMaster()->Clear(false);
        caravan->GetMotionMaster()->MoveIdle();
        caravan->AddUnitState(UNIT_STATE_ROOT);
        caravan->SetRooted(true);
        return;
    }
    caravan->ClearUnitState(UNIT_STATE_ROOT);
    caravan->SetRooted(false);
}

void BonkRun::EndCaravan(bool arrived)
{
    Map* map = m_player->GetMap();
    Creature* caravan = m_miniEvent.targets.empty() ? nullptr : map->GetCreature(m_miniEvent.targets.front());
    BonkPlayer* bonk = m_player->GetBonkPlayer();
    for (ObjectGuid const& guid : m_miniEvent.raiders)
        if (Creature* raider = map->GetCreature(guid))
            if (BonkMobAI* ai = dynamic_cast<BonkMobAI*>(raider->AI()))
                ai->ClearRaidTarget();
    if (caravan)
    {
        if (bonk->IsAddonReady())
        {
            WorldPacket data(SMSG_HOA_MESSAGE);
            HoAWriteAllyDone(data, caravan->GetPlateId(), BonkMobAI::GetUnitGuidText(caravan));
            m_player->GetSession()->SendPacket(&data);
        }
        if (arrived)
        {
            float const x = caravan->GetPositionX(), y = caravan->GetPositionY();
            float z = map->GetHeight(x, y, caravan->GetPositionZ() + 10.0f, true, 40.0f);
            if (z <= INVALID_HEIGHT)
                z = m_miniEvent.path.empty() ? caravan->GetPositionZ() : m_miniEvent.path.back().z;
            SpawnChest(true, x, y, z, BONK_CARAVAN_CHEST_CHOICES + GetDifficultyStep());
            sBonkQuests.OnProgress(m_player, BONK_QUEST_MINI_EVENTS, BONK_MINI_EVENT_CARAVAN, 1);
            bonk->Notify(BONK_STRING_CARAVAN_MADE_IT_ACROSS_AND);
        }
        else
        {
            caravan->CastSpell(caravan, BONK_SPELL_SPAWN_SMOKE, true);
            bonk->Notify(BONK_STRING_CARAVAN_IS_LOST);
        }
        caravan->DespawnOrUnsummon(arrived ? 3000 : 500);
    }
    else
    {
        if (bonk->IsAddonReady())
        {
            WorldPacket data(SMSG_HOA_MESSAGE);
            HoAWriteAllyDone(data, 0, "");
            m_player->GetSession()->SendPacket(&data);
        }
        bonk->Notify(BONK_STRING_CARAVAN_IS_LOST);
    }
    EndMiniEvent();
}

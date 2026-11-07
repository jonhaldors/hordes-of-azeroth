#include "BonkObjectives.h"

#include "BonkPlayer.h"
#include "Creature.h"
#include "GameObject.h"
#include "HoaProtocol.h"
#include "Map.h"
#include "Player.h"
#include "WorldSession.h"

#include <algorithm>
#include <cstring>

namespace
{
    uint32 const BONK_GO_OBJECTIVE = 900020;
    uint32 const BONK_OBJECTIVE_PILLAR_SEC = 3600;
    float const BONK_OBJECTIVE_SIGHT = VISIBILITY_DISTANCE_GIGANTIC;
    float const BONK_PILLAR_LOWER = 25.0f;
    float const BONK_PILLAR_RAISE = 40.0f;
    uint32 const BONK_PILLAR_CHECK_MS = 500;
    float const BONK_FOLLOW_MOVE = 2.0f;
    uint32 const BONK_FOLLOW_PING_MS = 6000;

    float DistanceSq(Player const* hero, BonkObjective const& objective)
    {
        float const dx = hero->GetPositionX() - objective.x;
        float const dy = hero->GetPositionY() - objective.y;
        return dx * dx + dy * dy;
    }

    char const* const KIND_NAMES[MAX_BONK_OBJECTIVE_KIND] = { "shrine", "vendor", "event", "", "chest", "boss", "miniboss" };

    bool HasPillar(BonkObjective const& objective)
    {
        return objective.follows.IsEmpty() && objective.kind != BONK_OBJECTIVE_CHEST;
    }

    bool PingsWhileFollowed(BonkObjectiveKind kind)
    {
        return kind == BONK_OBJECTIVE_EVENT;
    }
}

char const* GetBonkObjectiveKindName(BonkObjectiveKind kind)
{
    return kind < MAX_BONK_OBJECTIVE_KIND ? KIND_NAMES[kind] : "";
}

bool ParseBonkObjectiveKind(char const* name, BonkObjectiveKind& kind)
{
    for (uint8 i = 0; i < MAX_BONK_OBJECTIVE_KIND; ++i)
        if (!strcmp(name, KIND_NAMES[i]))
        {
            kind = BonkObjectiveKind(i);
            return true;
        }
    return false;
}

uint32 BonkObjectives::Add(Player* hero, BonkObjectiveKind kind, float x, float y, float z, std::string const& label, uint32 seconds,
    std::string const& icon, std::string const& description)
{
    BonkObjective objective;
    objective.id = m_nextId++;
    objective.kind = kind;
    objective.x = x;
    objective.y = y;
    objective.z = z;
    objective.label = label;
    objective.icon = icon;
    objective.description = description;
    objective.leftMs = seconds * IN_MILLISECONDS;
    if (HasPillar(objective) && DistanceSq(hero, objective) > BONK_PILLAR_LOWER * BONK_PILLAR_LOWER)
        RaisePillar(hero, objective);

    m_objectives.push_back(objective);
    Send(hero, objective);
    return objective.id;
}

uint32 BonkObjectives::Follow(Player* hero, BonkObjectiveKind kind, Creature const* target, std::string const& label, uint32 seconds,
    std::string const& icon, std::string const& description)
{
    BonkObjective objective;
    objective.id = m_nextId++;
    objective.kind = kind;
    target->GetPosition(objective.x, objective.y, objective.z);
    objective.label = label;
    objective.icon = icon;
    objective.description = description;
    objective.leftMs = seconds * IN_MILLISECONDS;
    objective.follows = target->GetObjectGuid();
    objective.pingMs = BONK_FOLLOW_PING_MS;

    m_objectives.push_back(objective);
    Send(hero, objective);
    if (PingsWhileFollowed(kind))
        Ping(hero, objective);
    return objective.id;
}

void BonkObjectives::Remove(Player* hero, uint32 id)
{
    auto const itr = std::find_if(m_objectives.begin(), m_objectives.end(), [id](BonkObjective const& objective) { return objective.id == id; });
    if (itr == m_objectives.end())
        return;

    Despawn(hero, *itr);
    if (hero->GetBonkPlayer()->IsAddonReady())
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteObjectiveClear(data, id);
        hero->GetSession()->SendPacket(&data);
    }
    m_objectives.erase(itr);
}

void BonkObjectives::RemoveFollowing(Player* hero, ObjectGuid const& target)
{
    auto const itr = std::find_if(m_objectives.begin(), m_objectives.end(), [&target](BonkObjective const& objective) { return objective.follows == target; });
    if (itr != m_objectives.end())
        Remove(hero, itr->id);
}

void BonkObjectives::Clear(Player* hero)
{
    for (BonkObjective const& objective : m_objectives)
        Despawn(hero, objective);
    m_objectives.clear();
    if (hero->GetBonkPlayer()->IsAddonReady())
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteObjectiveClear(data, 0);
        hero->GetSession()->SendPacket(&data);
    }
}

std::vector<BonkObjective> BonkObjectives::Update(Player* hero, uint32 diff)
{
    for (BonkObjective& objective : m_objectives)
    {
        if (objective.follows.IsEmpty())
            continue;
        Creature const* target = hero->GetMap()->GetCreature(objective.follows);
        if (!target || !target->IsAlive())
            continue;
        float const dx = target->GetPositionX() - objective.x;
        float const dy = target->GetPositionY() - objective.y;
        bool const moved = dx * dx + dy * dy > BONK_FOLLOW_MOVE * BONK_FOLLOW_MOVE;
        if (moved)
        {
            target->GetPosition(objective.x, objective.y, objective.z);
            Send(hero, objective);
        }
        if (!PingsWhileFollowed(objective.kind))
            continue;
        if (objective.pingMs > diff)
            objective.pingMs -= diff;
        else
        {
            objective.pingMs = BONK_FOLLOW_PING_MS;
            Ping(hero, objective);
        }
    }

    m_pillarTimer += diff;
    if (m_pillarTimer >= BONK_PILLAR_CHECK_MS)
    {
        m_pillarTimer = 0;
        for (BonkObjective& objective : m_objectives)
        {
            if (!HasPillar(objective))
                continue;
            float const distanceSq = DistanceSq(hero, objective);
            if (!objective.pillar.IsEmpty() && distanceSq < BONK_PILLAR_LOWER * BONK_PILLAR_LOWER)
            {
                Despawn(hero, objective);
                objective.pillar.Clear();
            }
            else if (objective.pillar.IsEmpty() && distanceSq > BONK_PILLAR_RAISE * BONK_PILLAR_RAISE)
                RaisePillar(hero, objective);
        }
    }

    std::vector<BonkObjective> gone;
    for (BonkObjective& objective : m_objectives)
    {
        if (!objective.leftMs)
            continue;
        if (objective.leftMs > diff)
            objective.leftMs -= diff;
        else
            gone.push_back(objective);
    }
    for (BonkObjective const& objective : gone)
        Remove(hero, objective.id);
    return gone;
}

void BonkObjectives::Resend(Player* hero) const
{
    if (hero->GetBonkPlayer()->IsAddonReady())
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteObjectiveClear(data, 0);
        hero->GetSession()->SendPacket(&data);
    }
    for (BonkObjective const& objective : m_objectives)
        Send(hero, objective);
}

void BonkObjectives::ResendTimed(Player* hero) const
{
    for (BonkObjective const& objective : m_objectives)
        if (objective.leftMs)
            Send(hero, objective);
}

BonkObjective const* BonkObjectives::Get(uint32 id) const
{
    for (BonkObjective const& objective : m_objectives)
        if (objective.id == id)
            return &objective;
    return nullptr;
}

void BonkObjectives::Send(Player* hero, BonkObjective const& objective) const
{
    if (!hero->GetBonkPlayer()->IsAddonReady())
        return;
    uint32 const seconds = (objective.leftMs + IN_MILLISECONDS - 1) / IN_MILLISECONDS;
    WorldPacket data(SMSG_HOA_MESSAGE);
    HoAWriteObjective(data, objective.id, GetBonkObjectiveKindName(objective.kind), objective.x, objective.y, hero->GetMapId(),
        objective.label, seconds, objective.icon, objective.description);
    hero->GetSession()->SendPacket(&data);
}

void BonkObjectives::Ping(Player* hero, BonkObjective const& objective) const
{
    if (!hero->GetBonkPlayer()->IsAddonReady())
        return;
    WorldPacket data(SMSG_HOA_MESSAGE);
    HoAWriteObjectivePing(data, objective.id);
    hero->GetSession()->SendPacket(&data);
}

void BonkObjectives::RaisePillar(Player* hero, BonkObjective& objective) const
{
    GameObject* pillar = hero->SummonGameObject(BONK_GO_OBJECTIVE + objective.kind, objective.x, objective.y, objective.z, 0.0f,
        0.0f, 0.0f, 0.0f, 0.0f, BONK_OBJECTIVE_PILLAR_SEC, false);
    if (!pillar)
        return;
    pillar->SetVisibilityModifier(BONK_OBJECTIVE_SIGHT);
    pillar->SetActiveObjectState(true);
    objective.pillar = pillar->GetObjectGuid();
}

void BonkObjectives::Despawn(Player* hero, BonkObjective const& objective) const
{
    if (Map* map = hero->FindMap())
        if (GameObject* pillar = map->GetGameObject(objective.pillar))
            pillar->Delete();
}

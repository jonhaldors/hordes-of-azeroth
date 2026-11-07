#ifndef BONK_OBJECTIVES_H
#define BONK_OBJECTIVES_H

#include "Common.h"
#include "ObjectGuid.h"

#include <string>
#include <vector>

class Creature;
class Player;

enum BonkObjectiveKind : uint8
{
    BONK_OBJECTIVE_SHRINE  = 0,
    BONK_OBJECTIVE_VENDOR  = 1,
    BONK_OBJECTIVE_EVENT   = 2,
    BONK_OBJECTIVE_CHEST   = 4,
    BONK_OBJECTIVE_BOSS    = 5,
    BONK_OBJECTIVE_MINIBOSS = 6,
    MAX_BONK_OBJECTIVE_KIND
};

char const* GetBonkObjectiveKindName(BonkObjectiveKind kind);
bool ParseBonkObjectiveKind(char const* name, BonkObjectiveKind& kind);

struct BonkObjective
{
    uint32 id = 0;
    BonkObjectiveKind kind = BONK_OBJECTIVE_SHRINE;
    float x = 0.0f, y = 0.0f, z = 0.0f;
    std::string label;
    std::string icon;
    std::string description;
    uint32 leftMs = 0;
    ObjectGuid pillar;
    ObjectGuid follows;
    uint32 pingMs = 0;
};

class BonkObjectives
{
    public:
        uint32 Add(Player* hero, BonkObjectiveKind kind, float x, float y, float z, std::string const& label, uint32 seconds,
            std::string const& icon = "", std::string const& description = "");
        uint32 Follow(Player* hero, BonkObjectiveKind kind, Creature const* target, std::string const& label, uint32 seconds,
            std::string const& icon = "", std::string const& description = "");
        void Remove(Player* hero, uint32 id);
        void RemoveFollowing(Player* hero, ObjectGuid const& target);
        void Clear(Player* hero);
        std::vector<BonkObjective> Update(Player* hero, uint32 diff);
        void Resend(Player* hero) const;
        void ResendTimed(Player* hero) const;

        BonkObjective const* Get(uint32 id) const;
        std::vector<BonkObjective> const& GetAll() const { return m_objectives; }

    private:
        void Send(Player* hero, BonkObjective const& objective) const;
        void Despawn(Player* hero, BonkObjective const& objective) const;
        void RaisePillar(Player* hero, BonkObjective& objective) const;
        void Ping(Player* hero, BonkObjective const& objective) const;

        std::vector<BonkObjective> m_objectives;
        uint32 m_nextId = 1;
        uint32 m_pillarTimer = 0;
};

#endif

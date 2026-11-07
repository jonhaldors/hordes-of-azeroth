#ifndef BONK_SPAWN_POINTS_H
#define BONK_SPAWN_POINTS_H

#include "Common.h"

#include <functional>
#include <vector>

class Map;
class Player;

bool IsInBonkHazard(Map const* map, float x, float y, float z);
bool IsBonkDryGround(Map const* map, float x, float y, float z);
bool SnapBonkToSafeGround(Player* hero, float maxShift, float& x, float& y, float& z);

struct BonkSpot
{
    float x = 0.0f, y = 0.0f, z = 0.0f;
    bool taken = false;
};

class BonkSpawnPoints
{
    public:
        void Reset(float startX, float startY, float startZ);
        void Update(Player* hero, uint32 zoneId, uint32 diff);

        bool Take(Player const* hero, float minDistance, float maxDistance, BonkSpot& spot);
        bool Take(Player const* hero, float minDistance, float maxDistance, BonkSpot& spot, std::function<bool(BonkSpot const&)> const& fits);
        void Release(float x, float y);

        std::vector<BonkSpot> const& GetSpots() const { return m_spots; }
        std::vector<BonkSpot> TakeFresh();

    private:
        bool TryCandidate(Player* hero, uint32 zoneId);
        bool IsClear(float x, float y) const;

        std::vector<BonkSpot> m_spots;
        std::vector<BonkSpot> m_fresh;
        float m_startX = 0.0f, m_startY = 0.0f, m_startZ = 0.0f;
        uint32 m_timer = 0;
};

#endif

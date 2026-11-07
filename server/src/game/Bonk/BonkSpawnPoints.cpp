#include "BonkSpawnPoints.h"

#include "GridMap.h"
#include "Map.h"
#include "MoveMap.h"
#include "PathFinder.h"
#include "Player.h"
#include "Utilities/Random.h"

#include <algorithm>
#include <cmath>

namespace
{
    uint32 const BONK_SPOT_TRY_MS        = 150;
    uint32 const BONK_SPOT_MAX           = 40;
    float const BONK_SPOT_MIN_DISTANCE   = 80.0f;
    float const BONK_SPOT_MAX_DISTANCE   = 320.0f;
    float const BONK_SPOT_SPREAD         = 70.0f;
    float const BONK_SPOT_START_CLEAR    = 60.0f;
    float const BONK_SPOT_FORGET         = 450.0f;
    float const BONK_SPOT_GROUND_ABOVE   = 40.0f;
    float const BONK_SPOT_GROUND_DEPTH   = 120.0f;
    float const BONK_SPOT_WATER_DEPTH    = 1.0f;
    float const BONK_SPOT_HAZARD_PROBE   = 0.1f;
    float const BONK_SPOT_MAX_DETOUR     = 1.6f;
    float const BONK_SPOT_SNAP           = 3.0f;
    float const BONK_SPOT_FLAT_RADIUS    = 6.0f;
    float const BONK_SPOT_FLAT_RISE      = 2.5f;
    float const BONK_SPOT_HILL_RADIUS    = 30.0f;
    float const BONK_SPOT_HILL_RISE      = 8.0f;
    uint32 const BONK_SPOT_HILL_SIDES    = 5;

    float DistanceSq(float x1, float y1, float x2, float y2)
    {
        return (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2);
    }

    bool IsOpenGround(Map const* map, float x, float y, float z)
    {
        uint32 lowerSides = 0;
        for (uint32 i = 0; i < 8; ++i)
        {
            float const angle = i * M_PI_F / 4.0f;
            float const cosine = std::cos(angle), sine = std::sin(angle);
            float const nearZ = map->GetHeight(x + BONK_SPOT_FLAT_RADIUS * cosine, y + BONK_SPOT_FLAT_RADIUS * sine,
                z + BONK_SPOT_FLAT_RISE * 2.0f, true, BONK_SPOT_FLAT_RISE * 4.0f);
            if (nearZ <= INVALID_HEIGHT || std::fabs(nearZ - z) > BONK_SPOT_FLAT_RISE)
                return false;
            float const farZ = map->GetHeight(x + BONK_SPOT_HILL_RADIUS * cosine, y + BONK_SPOT_HILL_RADIUS * sine,
                z + BONK_SPOT_GROUND_ABOVE, true, BONK_SPOT_GROUND_DEPTH);
            if (farZ > INVALID_HEIGHT && farZ < z - BONK_SPOT_HILL_RISE)
                ++lowerSides;
        }
        return lowerSides < BONK_SPOT_HILL_SIDES;
    }
}

bool IsInBonkHazard(Map const* map, float x, float y, float z)
{
    GridMapLiquidStatus const status = map->GetTerrain()->getLiquidStatus(x, y, z + BONK_SPOT_HAZARD_PROBE, MAP_LIQUID_TYPE_MAGMA | MAP_LIQUID_TYPE_SLIME);
    return (status & (LIQUID_MAP_WATER_WALK | LIQUID_MAP_IN_WATER | LIQUID_MAP_UNDER_WATER)) != 0;
}

bool IsBonkDryGround(Map const* map, float x, float y, float z)
{
    return !IsInBonkHazard(map, x, y, z) && !map->GetTerrain()->IsInWater(x, y, z + BONK_SPOT_WATER_DEPTH);
}

bool SnapBonkToSafeGround(Player* hero, float maxShift, float& x, float& y, float& z)
{
    Map const* map = hero->GetMap();
    PathFinder path(hero);
    path.ExcludeSteepSlopes();
    path.calculate(x, y, z);
    uint32 const type = path.getPathType();
    if (type & PATHFIND_NOT_USING_PATH)
        return IsBonkDryGround(map, x, y, z);
    if (!(type & (PATHFIND_NORMAL | PATHFIND_INCOMPLETE)))
        return false;

    Vector3 const end = path.getActualEndPosition();
    if (DistanceSq(end.x, end.y, x, y) > maxShift * maxShift || !IsBonkDryGround(map, end.x, end.y, end.z))
        return false;
    x = end.x;
    y = end.y;
    z = end.z;
    return true;
}

void BonkSpawnPoints::Reset(float startX, float startY, float startZ)
{
    m_spots.clear();
    m_fresh.clear();
    m_startX = startX;
    m_startY = startY;
    m_startZ = startZ;
    m_timer = 0;
}

void BonkSpawnPoints::Update(Player* hero, uint32 zoneId, uint32 diff)
{
    m_timer += diff;
    if (m_timer < BONK_SPOT_TRY_MS)
        return;
    m_timer = 0;

    if (!hero->IsInWorld() || hero->IsBeingTeleported())
        return;

    if (m_spots.size() >= BONK_SPOT_MAX)
    {
        auto farthest = m_spots.end();
        float farthestSq = BONK_SPOT_FORGET * BONK_SPOT_FORGET;
        for (auto itr = m_spots.begin(); itr != m_spots.end(); ++itr)
        {
            float const distanceSq = DistanceSq(itr->x, itr->y, hero->GetPositionX(), hero->GetPositionY());
            if (!itr->taken && distanceSq > farthestSq)
            {
                farthest = itr;
                farthestSq = distanceSq;
            }
        }
        if (farthest == m_spots.end())
            return;
        m_spots.erase(farthest);
    }

    TryCandidate(hero, zoneId);
}

bool BonkSpawnPoints::TryCandidate(Player* hero, uint32 zoneId)
{
    float const angle = frand(0.0f, 2.0f * M_PI_F);
    float const distance = frand(BONK_SPOT_MIN_DISTANCE, BONK_SPOT_MAX_DISTANCE);
    float x = hero->GetPositionX() + distance * std::cos(angle);
    float y = hero->GetPositionY() + distance * std::sin(angle);
    if (!IsClear(x, y))
        return false;

    Map const* map = hero->GetMap();
    float z = map->GetHeight(x, y, hero->GetPositionZ() + BONK_SPOT_GROUND_ABOVE, true, BONK_SPOT_GROUND_DEPTH);
    if (z <= INVALID_HEIGHT)
        return false;
    if (zoneId && map->GetTerrain()->GetZoneId(x, y, z) != zoneId)
        return false;
    if (!IsBonkDryGround(map, x, y, z))
        return false;

    PathFinder path(hero);
    path.ExcludeSteepSlopes();
    path.calculate(x, y, z);
    if ((path.getPathType() & PATHFIND_NOT_USING_PATH) && MMAP::MMapFactory::createOrGetMMapManager()->GetNavMesh(hero->GetMapId()))
        return false;
    if (!(path.getPathType() & PATHFIND_NOT_USING_PATH))
    {
        if (!(path.getPathType() & PATHFIND_NORMAL) || (path.getPathType() & PATHFIND_INCOMPLETE) ||
            path.Length() > distance * BONK_SPOT_MAX_DETOUR)
            return false;
        Vector3 const end = path.getActualEndPosition();
        if (DistanceSq(end.x, end.y, x, y) > BONK_SPOT_SNAP * BONK_SPOT_SNAP)
            return false;
        x = end.x;
        y = end.y;
        z = end.z;
        if (!IsClear(x, y))
            return false;
    }
    if (!IsOpenGround(map, x, y, z) || !IsBonkDryGround(map, x, y, z))
        return false;

    BonkSpot spot;
    spot.x = x;
    spot.y = y;
    spot.z = z;
    m_spots.push_back(spot);
    m_fresh.push_back(spot);
    return true;
}

std::vector<BonkSpot> BonkSpawnPoints::TakeFresh()
{
    std::vector<BonkSpot> fresh;
    fresh.swap(m_fresh);
    return fresh;
}

bool BonkSpawnPoints::IsClear(float x, float y) const
{
    if (DistanceSq(x, y, m_startX, m_startY) < BONK_SPOT_START_CLEAR * BONK_SPOT_START_CLEAR)
        return false;
    return std::none_of(m_spots.begin(), m_spots.end(),
        [x, y](BonkSpot const& spot) { return DistanceSq(x, y, spot.x, spot.y) < BONK_SPOT_SPREAD * BONK_SPOT_SPREAD; });
}

bool BonkSpawnPoints::Take(Player const* hero, float minDistance, float maxDistance, BonkSpot& spot)
{
    return Take(hero, minDistance, maxDistance, spot, [](BonkSpot const&) { return true; });
}

bool BonkSpawnPoints::Take(Player const* hero, float minDistance, float maxDistance, BonkSpot& spot, std::function<bool(BonkSpot const&)> const& accepts)
{
    std::vector<BonkSpot*> fits;
    for (BonkSpot& candidate : m_spots)
    {
        if (candidate.taken || !accepts(candidate))
            continue;
        float const distanceSq = DistanceSq(candidate.x, candidate.y, hero->GetPositionX(), hero->GetPositionY());
        if (distanceSq >= minDistance * minDistance && distanceSq <= maxDistance * maxDistance)
            fits.push_back(&candidate);
    }
    if (fits.empty())
        return false;

    BonkSpot* chosen = fits[urand(0, uint32(fits.size()) - 1)];
    chosen->taken = true;
    spot = *chosen;
    return true;
}

void BonkSpawnPoints::Release(float x, float y)
{
    for (BonkSpot& spot : m_spots)
        if (DistanceSq(x, y, spot.x, spot.y) < 1.0f)
            spot.taken = false;
}

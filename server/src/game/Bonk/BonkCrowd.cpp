#include "BonkCrowd.h"
#include "BonkMobAI.h"
#include "Creature.h"
#include "Map.h"
#include "MoveMap.h"
#include "MoveMapSharedDefines.h"
#include "MoveSpline.h"
#include "MoveSplineInit.h"
#include "PathFinder.h"
#include "Player.h"
#include "Timer.h"

#include <algorithm>
#include <chrono>
#include <cmath>

namespace
{
    uint32 const BONK_CROWD_TICK_MS         = 200;
    float const BONK_CROWD_DEEP_SHARE       = 0.6f;
    uint32 const BONK_CROWD_HORIZON_MS      = 400;
    uint32 const BONK_CROWD_DRIVE_GRACE_MS  = 500;
    uint32 const BONK_CROWD_FORGET_MS       = 5000;
    uint32 const BONK_CROWD_DIRECT_CHECK_MS = 500;
    uint32 const BONK_CROWD_SIGHT_CHECK_MS  = 1000;
    uint32 const BONK_CROWD_PATH_MS         = 1000;
    uint32 const BONK_CROWD_WALL_STUCK_MS   = 3000;
    uint32 const BONK_CROWD_SOLVER_PASSES   = 4;
    float const BONK_CROWD_CELL             = 6.0f;
    float const BONK_CROWD_PAIR_SLACK       = 1.0f;
    float const BONK_CROWD_DIRECT_NEAR      = 8.0f;
    float const BONK_CROWD_DIRECT_REACH     = 2.5f;
    float const BONK_CROWD_PATH_DRIFT       = 4.0f;
    float const BONK_CROWD_CORNER_REACHED   = 1.5f;
    float const BONK_CROWD_RANGED_SHARE     = 0.85f;
    float const BONK_CROWD_HOLD_SLACK       = 0.3f;
    float const BONK_CROWD_RESEND_COS       = 0.99f;
    float const BONK_CROWD_RESEND_SPEED     = 0.1f;
    float const BONK_CROWD_WALK_SHARE       = 0.45f;
    float const BONK_CROWD_MIN_STEP         = 0.1f;
    uint32 const BONK_CROWD_ARC_STEPS       = 8;
    float const BONK_CROWD_ARC_SPACING      = 1.5f;
    float const BONK_CROWD_SHARP_TURN       = M_PI_F / 2.0f;
    float const BONK_CROWD_SHARP_TURN_PACE  = 0.35f;
    float const BONK_CROWD_STEADY_TURN      = 3.0f * M_PI_F / 180.0f;
    float const BONK_CROWD_WALL_MARGIN      = 0.5f;
    float const BONK_CROWD_SMALL_RADIUS     = 0.6f;
    float const BONK_CROWD_LARGE_RADIUS     = 2.0f;
    uint32 const BONK_CROWD_FLOW_HOLD_MS    = 1000;
    uint32 const BONK_CROWD_FLOW_MS         = 1500;
    uint32 const BONK_CROWD_FLOW_REST_MS    = 3000;
    float const BONK_CROWD_FLOW_REACHED     = 1.0f;
    float const BONK_CROWD_OVERLAP_SLOP     = 0.25f;
    uint32 const BONK_CROWD_KEEP_OUT_PASSES = 2;
    float const BONK_CROWD_FLOW_RANGE       = 14.0f;
    float const BONK_CROWD_MIN_SHOVE        = 0.15f;

    uint64 CrowdNowUs()
    {
        return uint64(std::chrono::duration_cast<std::chrono::microseconds>(
            std::chrono::steady_clock::now().time_since_epoch()).count());
    }

    bool WalkRay(uint32 mapId, float fromX, float fromY, float fromZ, float& x, float& y, float& z)
    {
        dtNavMeshQuery const* query = MMAP::MMapFactory::createOrGetMMapManager()->GetNavMeshQuery(mapId);
        if (!query)
            return false;

        dtQueryFilter filter;
        filter.setIncludeFlags(NAV_GROUND | NAV_WATER | NAV_MAGMA | NAV_SLIME | NAV_STEEP_SLOPES);
        float const start[3] = { fromY, fromZ, fromX };
        float closest[3] = { 0.0f, 0.0f, 0.0f };
        dtPolyRef const startRef = PathInfo::FindWalkPoly(query, start, filter, closest, 10.0f);
        if (!startRef)
            return false;

        float end[3] = { y, z, x };
        float hit = 0.0f;
        float normal[3] = { 0.0f, 0.0f, 0.0f };
        dtPolyRef visited[32];
        int visitedCount = 0;
        if (dtStatusFailed(query->raycast(startRef, closest, end, &filter, &hit, normal, visited, &visitedCount, 32)) || !visitedCount)
            return false;

        if (hit < 1.0f)
        {
            float const length = std::sqrt((end[0] - closest[0]) * (end[0] - closest[0]) + (end[2] - closest[2]) * (end[2] - closest[2]));
            float const share = length > 0.01f ? std::max(0.0f, hit - BONK_CROWD_WALL_MARGIN / length) : 0.0f;
            for (int i = 0; i < 3; ++i)
                end[i] = closest[i] + (end[i] - closest[i]) * share;
        }
        float height;
        if (dtStatusSucceed(query->getPolyHeight(visited[visitedCount - 1], end, &height)))
            end[1] = height;
        x = end[2];
        y = end[0];
        z = end[1];
        return true;
    }

    float AngleDiff(float to, float from)
    {
        return std::remainder(to - from, 2.0f * M_PI_F);
    }

    float TurnToward(float heading, float target, float maxTurn)
    {
        float const diff = AngleDiff(target, heading);
        return heading + std::max(-maxTurn, std::min(maxTurn, diff));
    }

    float TickSeconds()
    {
        return float(BONK_CROWD_TICK_MS) / float(IN_MILLISECONDS);
    }

    float Distance2d(float ax, float ay, float bx, float by)
    {
        return std::sqrt((ax - bx) * (ax - bx) + (ay - by) * (ay - by));
    }

    float GuidAngle(Creature const* mob)
    {
        return float((mob->GetObjectGuid().GetCounter() * 2654435761u) >> 8) / float(1u << 24) * 2.0f * M_PI_F;
    }

    int64 CellKey(float x, float y)
    {
        int32 const cellX = int32(std::floor(x / BONK_CROWD_CELL));
        int32 const cellY = int32(std::floor(y / BONK_CROWD_CELL));
        return (int64(cellX) << 32) ^ int64(uint32(cellY));
    }

    bool MillisecondsPassed(uint32 since, uint32 now, uint32 span)
    {
        return int32(now - since) >= int32(span);
    }
}

BonkCrowd::Settings BonkCrowd::m_settings;

std::vector<std::pair<char const*, float*>> BonkCrowd::GetTunables()
{
    return {
        { "heroRadius", &m_settings.heroRadius },
        { "bodyScale", &m_settings.bodyScale },
        { "minRadius", &m_settings.minRadius },
        { "maxRadius", &m_settings.maxRadius },
        { "touchSlack", &m_settings.touchSlack },
        { "touchSlackRunning", &m_settings.touchSlackRunning },
        { "moveShare", &m_settings.moveShare },
        { "startShare", &m_settings.startShare },
        { "overlapEase", &m_settings.overlapEase },
        { "holdMass", &m_settings.holdMass },
        { "turnRateSmall", &m_settings.turnRateSmall },
        { "turnRateLarge", &m_settings.turnRateLarge },
        { "flowAngle", &m_settings.flowAngle },
        { "shoveDistance", &m_settings.shoveDistance },
        { "shoveSpeed", &m_settings.shoveSpeed },
        { "shoveGapMs", &m_settings.shoveGapMs },
        { "veteranShoveDistance", &m_settings.veteranShoveDistance },
        { "haltMs", &m_settings.haltMs },
        { "haltGapMs", &m_settings.haltGapMs },
        { "levelPushRadius", &m_settings.levelPushRadius },
        { "levelPushDistance", &m_settings.levelPushDistance },
        { "levelPushSpeed", &m_settings.levelPushSpeed },
    };
}

void BonkCrowd::Cost::Add(Cost const& other)
{
    ticks += other.ticks;
    totalUs += other.totalUs;
    worstUs = std::max(worstUs, other.worstUs);
    gatherUs += other.gatherUs;
    goalUs += other.goalUs;
    solveUs += other.solveUs;
    steerUs += other.steerUs;
    bodies += other.bodies;
    driven += other.driven;
    walkRays += other.walkRays;
    paths += other.paths;
    pathUs += other.pathUs;
    sightChecks += other.sightChecks;
    sightUs += other.sightUs;
    launches += other.launches;
}

void BonkCrowd::Update(uint32 diff, Player* hero, std::vector<ObjectGuid> const& mobs, bool heroPerched, std::vector<Creature*>& stuck)
{
    m_clockMs += diff;
    m_tickTimer += diff;
    if (m_tickTimer < BONK_CROWD_TICK_MS)
        return;
    m_tickTimer = 0;
    uint64 const startUs = CrowdNowUs();

    Map* map = hero->GetMap();
    bool const hasNavMesh = MMAP::MMapFactory::createOrGetMMapManager()->GetNavMeshQuery(map->GetId()) != nullptr;

    float heroX = hero->GetPositionX(), heroY = hero->GetPositionY(), heroZ = hero->GetPositionZ();
    bool const heroMoving = hero->IsMoving();
    float aimX = heroX, aimY = heroY, aimZ = heroZ;
    if (heroMoving)
    {
        uint32 const age = std::min(WorldTimer::getMSTimeDiffToNow(hero->m_movementInfo.stime), 1000u);
        float o;
        if (!hero->ExtrapolateMovement(hero->m_movementInfo, age + BONK_CROWD_TICK_MS, aimX, aimY, aimZ, o))
        {
            aimX = heroX;
            aimY = heroY;
            aimZ = heroZ;
        }
    }

    uint32 const driveUntil = WorldTimer::getMSTime() + BONK_CROWD_DRIVE_GRACE_MS;
    std::vector<Body> bodies;
    bodies.reserve(mobs.size());
    m_drivenCount = 0;
    m_standingCount = 0;
    m_deepPairs = 0;
    m_touchingCount = 0;
    std::fill(std::begin(m_holdCounts), std::end(m_holdCounts), 0u);
    for (ObjectGuid const& guid : mobs)
    {
        Creature* mob = map->GetCreature(guid);
        if (!mob || !mob->IsAlive() || mob->HasCreatureState(CSTATE_DESPAWNING) || mob->IsBonkFlyer())
            continue;

        Body body;
        body.mob = mob;
        body.px = mob->GetPositionX();
        body.py = mob->GetPositionY();
        body.pz = mob->GetPositionZ();
        body.qx = body.px;
        body.qy = body.py;
        body.radius = std::min(m_settings.maxRadius, std::max(m_settings.minRadius, mob->GetObjectBoundingRadius() * m_settings.bodyScale));
        body.passThrough = mob->IsBonkEnemy() && !mob->IsBonkNormal();

        Hold const hold = hasNavMesh ? GetHold(mob, hero, heroPerched) : HOLD_NAVMESH;
        ++m_holdCounts[hold];
        if (hold == HOLD_NONE)
        {
            Mover& mover = m_movers[guid.GetRawValue()];
            mover.lastSeenMs = m_clockMs;
            body.mover = &mover;
            body.invMass = 1.0f;
            body.speed = mob->GetSpeed(MOVE_RUN);
            mob->SetBonkCrowdDriven(driveUntil);
            ++m_drivenCount;
        }
        else
        {
            auto const known = m_movers.find(guid.GetRawValue());
            if (known != m_movers.end())
            {
                known->second.sentMoving = false;
                known->second.standing = true;
                known->second.corners.clear();
            }
            mob->SetBonkCrowdDriven(0);
            mob->SetBonkCrowdTouching(true);
        }
        bodies.push_back(body);
    }

    uint64 const gatheredUs = CrowdNowUs();
    for (Body& body : bodies)
        if (body.mover)
            PickGoal(body, hero, aimX, aimY, aimZ);

    uint64 const goalsUs = CrowdNowUs();
    Solve(bodies, heroX, heroY);

    uint64 const solvedUs = CrowdNowUs();
    for (Body& body : bodies)
        if (body.mover)
            Steer(body, bodies, heroX, heroY, heroMoving, stuck);

    uint64 const steeredUs = CrowdNowUs();
    uint32 const tickUs = uint32(steeredUs - startUs);
    ++m_cost.ticks;
    m_cost.totalUs += tickUs;
    m_cost.worstUs = std::max(m_cost.worstUs, tickUs);
    m_cost.gatherUs += gatheredUs - startUs;
    m_cost.goalUs += goalsUs - gatheredUs;
    m_cost.solveUs += solvedUs - goalsUs;
    m_cost.steerUs += steeredUs - solvedUs;
    m_cost.bodies += bodies.size();
    m_cost.driven += m_drivenCount;

    for (auto itr = m_movers.begin(); itr != m_movers.end();)
    {
        if (MillisecondsPassed(itr->second.lastSeenMs, m_clockMs, BONK_CROWD_FORGET_MS))
            itr = m_movers.erase(itr);
        else
            ++itr;
    }
}

BonkCrowd::Hold BonkCrowd::GetHold(Creature* mob, Player* hero, bool heroPerched) const
{
    if (heroPerched)
        return HOLD_PERCHED;
    if (!mob->IsBonkEnemy() || mob->GetVictim() != hero)
        return HOLD_VICTIM;
    if (mob->HasUnitState(UNIT_STATE_CAN_NOT_MOVE | UNIT_STATE_POSSESSED))
        return HOLD_CANNOT_MOVE;
    if (mob->IsNonMeleeSpellCasted(false))
        return HOLD_CASTING;
    if (mob->GetMotionMaster()->GetCurrentMovementGeneratorType() != CHASE_MOTION_TYPE)
        return HOLD_MOTION;
    if (mob->movespline->IsUninterruptible() && !mob->movespline->Finalized())
        return HOLD_SPLINE;
    BonkMobAI const* ai = dynamic_cast<BonkMobAI const*>(mob->AI());
    return ai && ai->CanCrowdWalk() ? HOLD_NONE : HOLD_AI;
}

std::string BonkCrowd::Describe() const
{
    return std::to_string(m_drivenCount) + " enemies walk in the crowd: " + std::to_string(m_standingCount) + " standing, " +
        std::to_string(m_touchingCount) + " touching you, " + std::to_string(m_deepPairs) + " pairs deep inside each other; " + DescribeHolds() + ".";
}

std::string BonkCrowd::DescribeHolds() const
{
    static char const* const names[MAX_HOLD] = { "driven", "no navmesh", "hero perched", "other victim", "can't move", "casting",
        "other movement", "locked spline", "AI busy" };
    std::string text;
    for (uint32 i = 1; i < MAX_HOLD; ++i)
        if (m_holdCounts[i])
            text += std::string(text.empty() ? "" : ", ") + names[i] + " " + std::to_string(m_holdCounts[i]);
    return text.empty() ? "all driven" : "not driven: " + text;
}

void BonkCrowd::PickGoal(Body& body, Player* hero, float heroX, float heroY, float heroZ)
{
    Mover& mover = *body.mover;
    Creature* mob = body.mob;
    BonkMobAI const* ai = dynamic_cast<BonkMobAI const*>(mob->AI());
    float const holdRange = ai ? ai->GetHoldRange() : 0.0f;
    float const heroDistance = Distance2d(body.px, body.py, heroX, heroY);

    body.melee = holdRange <= 0.0f;
    body.stopDistance = m_settings.heroRadius + body.radius;
    if (!body.melee)
    {
        if (MillisecondsPassed(mover.sightCheckMs, m_clockMs, BONK_CROWD_SIGHT_CHECK_MS))
        {
            mover.sightCheckMs = m_clockMs;
            uint64 const sightStartUs = CrowdNowUs();
            mover.canSeeHero = mob->IsWithinLOSInMap(hero);
            ++m_cost.sightChecks;
            m_cost.sightUs += CrowdNowUs() - sightStartUs;
        }
        if (mover.canSeeHero)
            body.stopDistance = std::max(body.stopDistance, holdRange * BONK_CROWD_RANGED_SHARE);
    }

    if (heroDistance <= BONK_CROWD_DIRECT_NEAR)
        mover.direct = true;
    else if (MillisecondsPassed(mover.directCheckMs, m_clockMs, BONK_CROWD_DIRECT_CHECK_MS))
    {
        mover.directCheckMs = m_clockMs;
        float hitX = heroX, hitY = heroY, hitZ = heroZ;
        ++m_cost.walkRays;
        mover.direct = WalkRay(mob->GetMapId(), body.px, body.py, body.pz, hitX, hitY, hitZ) &&
            Distance2d(hitX, hitY, heroX, heroY) <= BONK_CROWD_DIRECT_REACH;
    }

    if (!mover.direct)
        UpdatePath(body, heroX, heroY, heroZ);

    bool const crowded = body.melee && mover.direct && heroDistance < BONK_CROWD_FLOW_RANGE &&
        heroDistance > body.stopDistance + BONK_CROWD_HOLD_SLACK;
    bool flowing = crowded && mover.flowUntilMs && int32(mover.flowUntilMs - m_clockMs) > 0;
    if (!flowing && crowded && mover.pressedMs && int32(mover.pressedMs - (mover.flowUntilMs + BONK_CROWD_FLOW_REST_MS)) > 0 &&
        !MillisecondsPassed(mover.pressedMs, m_clockMs, BONK_CROWD_FLOW_HOLD_MS))
    {
        float const side = (mob->GetObjectGuid().GetCounter() & 1) ? 1.0f : -1.0f;
        mover.flowAngle = std::atan2(body.py - heroY, body.px - heroX) + side * m_settings.flowAngle * M_PI_F / 180.0f;
        mover.flowUntilMs = m_clockMs + BONK_CROWD_FLOW_MS;
        flowing = true;
    }
    float const flowX = heroX + std::cos(mover.flowAngle) * body.stopDistance;
    float const flowY = heroY + std::sin(mover.flowAngle) * body.stopDistance;
    if (flowing && Distance2d(body.px, body.py, flowX, flowY) <= BONK_CROWD_FLOW_REACHED + body.radius)
    {
        mover.flowUntilMs = m_clockMs;
        flowing = false;
    }
    float distance;
    if (flowing)
    {
        body.goalX = flowX;
        body.goalY = flowY;
        body.goalZ = heroZ;
        distance = Distance2d(body.px, body.py, body.goalX, body.goalY);
        body.wanted = distance;
    }
    else if (mover.direct)
    {
        body.goalX = heroX;
        body.goalY = heroY;
        body.goalZ = heroZ;
        distance = Distance2d(body.px, body.py, heroX, heroY);
        body.wanted = std::max(0.0f, distance - body.stopDistance);
    }
    else
    {
        G3D::Vector3 const& corner = mover.corners.front();
        body.goalX = corner.x;
        body.goalY = corner.y;
        body.goalZ = corner.z;
        distance = Distance2d(body.px, body.py, corner.x, corner.y);
        body.wanted = distance;
    }

    body.wanted = std::min(body.wanted, body.speed * TickSeconds());
    if (distance > 0.01f)
    {
        body.dirX = (body.goalX - body.px) / distance;
        body.dirY = (body.goalY - body.py) / distance;
    }
    else
    {
        body.dirX = body.dirY = 0.0f;
        body.wanted = 0.0f;
    }
    body.qx = body.px + body.dirX * body.wanted;
    body.qy = body.py + body.dirY * body.wanted;

    if (body.melee && mover.direct && heroDistance <= body.stopDistance + BONK_CROWD_HOLD_SLACK)
        body.invMass = m_settings.holdMass;
}

void BonkCrowd::UpdatePath(Body& body, float heroX, float heroY, float heroZ)
{
    Mover& mover = *body.mover;
    bool const stale = mover.corners.empty() || MillisecondsPassed(mover.pathMs, m_clockMs, BONK_CROWD_PATH_MS) ||
        Distance2d(mover.pathGoalX, mover.pathGoalY, heroX, heroY) > BONK_CROWD_PATH_DRIFT;
    if (stale)
    {
        mover.pathMs = m_clockMs;
        mover.pathGoalX = heroX;
        mover.pathGoalY = heroY;
        mover.corners.clear();
        uint64 const pathStartUs = CrowdNowUs();
        PathFinder path(body.mob);
        path.calculate(heroX, heroY, heroZ, false);
        ++m_cost.paths;
        m_cost.pathUs += CrowdNowUs() - pathStartUs;
        if (path.getPathType() & (PATHFIND_NORMAL | PATHFIND_INCOMPLETE))
            for (size_t i = 1; i < path.getPath().size(); ++i)
                mover.corners.push_back(path.getPath()[i]);
    }

    while (mover.corners.size() > 1 && Distance2d(body.px, body.py, mover.corners.front().x, mover.corners.front().y) < BONK_CROWD_CORNER_REACHED)
        mover.corners.erase(mover.corners.begin());

    if (mover.corners.empty())
        mover.direct = true;
}

void BonkCrowd::Solve(std::vector<Body>& bodies, float heroX, float heroY)
{
    std::unordered_map<int64, std::vector<uint32>> cells;
    cells.reserve(bodies.size());
    for (uint32 i = 0; i < bodies.size(); ++i)
        cells[CellKey(bodies[i].qx, bodies[i].qy)].push_back(i);

    struct Pair
    {
        uint32 a, b;
        float minimum;
    };
    std::vector<Pair> pairs;
    for (uint32 i = 0; i < bodies.size(); ++i)
    {
        Body& a = bodies[i];
        for (int32 nearX = -1; nearX <= 1; ++nearX)
            for (int32 nearY = -1; nearY <= 1; ++nearY)
            {
                auto const cell = cells.find(CellKey(a.qx + nearX * BONK_CROWD_CELL, a.qy + nearY * BONK_CROWD_CELL));
                if (cell == cells.end())
                    continue;
                for (uint32 j : cell->second)
                {
                    if (j <= i)
                        continue;
                    Body& b = bodies[j];
                    if ((a.invMass <= 0.0f && b.invMass <= 0.0f) || a.passThrough != b.passThrough)
                        continue;
                    float const contact = a.radius + b.radius;
                    if (Distance2d(a.qx, a.qy, b.qx, b.qy) >= contact + BONK_CROWD_PAIR_SLACK)
                        continue;
                    float minimum = contact;
                    float const start = Distance2d(a.px, a.py, b.px, b.py);
                    if (start < contact * BONK_CROWD_DEEP_SHARE)
                        ++m_deepPairs;
                    if (start < contact - BONK_CROWD_OVERLAP_SLOP)
                    {
                        minimum = std::min(contact, start + m_settings.overlapEase);
                        a.overlapping = true;
                        b.overlapping = true;
                    }
                    pairs.push_back({ i, j, minimum });
                    a.neighbours.push_back(j);
                    b.neighbours.push_back(i);
                }
            }
    }

    for (uint32 pass = 0; pass < BONK_CROWD_SOLVER_PASSES; ++pass)
    {
        for (Pair const& pair : pairs)
        {
            Body& a = bodies[pair.a];
            Body& b = bodies[pair.b];
            float nx = a.qx - b.qx;
            float ny = a.qy - b.qy;
            float distance = std::sqrt(nx * nx + ny * ny);
            if (distance >= pair.minimum)
                continue;
            if (distance < 0.001f)
            {
                float const angle = GuidAngle(a.mob);
                nx = std::cos(angle);
                ny = std::sin(angle);
                distance = 0.0f;
            }
            else
            {
                nx /= distance;
                ny /= distance;
            }
            float const depth = pair.minimum - distance;
            float const weight = a.invMass + b.invMass;
            a.qx += nx * depth * a.invMass / weight;
            a.qy += ny * depth * a.invMass / weight;
            b.qx -= nx * depth * b.invMass / weight;
            b.qy -= ny * depth * b.invMass / weight;
            if (a.invMass > 0.0f)
                a.pressed = true;
            if (b.invMass > 0.0f)
                b.pressed = true;
        }

        for (Body& body : bodies)
        {
            if (!body.mover)
                continue;
            float const minimum = m_settings.heroRadius + body.radius;
            float dx = body.qx - heroX;
            float dy = body.qy - heroY;
            float const distance = std::sqrt(dx * dx + dy * dy);
            if (distance >= minimum)
                continue;
            if (distance < 0.001f)
            {
                dx = -body.dirX;
                dy = -body.dirY;
            }
            else
            {
                dx /= distance;
                dy /= distance;
            }
            body.qx = heroX + dx * minimum;
            body.qy = heroY + dy * minimum;
        }
    }
}

void BonkCrowd::KeepOut(Body const& body, float otherX, float otherY, float contact, float& stepX, float& stepY) const
{
    float const toX = body.px + stepX - otherX;
    float const toY = body.py + stepY - otherY;
    if (toX * toX + toY * toY >= contact * contact)
        return;
    float nx = body.px - otherX;
    float ny = body.py - otherY;
    float const length = std::sqrt(nx * nx + ny * ny);
    if (length < 0.001f)
        return;
    nx /= length;
    ny /= length;
    float const inward = stepX * nx + stepY * ny;
    if (inward < 0.0f)
    {
        stepX -= nx * inward;
        stepY -= ny * inward;
    }
}

void BonkCrowd::Steer(Body& body, std::vector<Body> const& bodies, float heroX, float heroY, bool heroMoving, std::vector<Creature*>& stuck)
{
    Mover& mover = *body.mover;
    if (int32(mover.haltUntilMs - m_clockMs) > 0)
        return;
    float stepX = body.qx - body.px;
    float stepY = body.qy - body.py;
    if (!body.overlapping)
    {
        float const along = stepX * body.dirX + stepY * body.dirY;
        if (along < 0.0f)
        {
            stepX -= body.dirX * along;
            stepY -= body.dirY * along;
        }
    }
    for (uint32 pass = 0; pass < BONK_CROWD_KEEP_OUT_PASSES; ++pass)
    {
        for (uint32 index : body.neighbours)
            KeepOut(body, bodies[index].px, bodies[index].py, body.radius + bodies[index].radius, stepX, stepY);
        KeepOut(body, heroX, heroY, m_settings.heroRadius + body.radius, stepX, stepY);
    }

    float const fullStep = body.speed * TickSeconds();
    float const maxStep = fullStep + (body.overlapping ? m_settings.overlapEase : 0.0f);
    float length = std::sqrt(stepX * stepX + stepY * stepY);
    if (length > maxStep)
    {
        stepX *= maxStep / length;
        stepY *= maxStep / length;
        length = maxStep;
    }

    float const before = Distance2d(body.px, body.py, body.goalX, body.goalY);
    float const after = Distance2d(body.px + stepX, body.py + stepY, body.goalX, body.goalY);
    float const need = fullStep * (mover.standing ? m_settings.startShare : m_settings.moveShare);
    bool const separating = body.overlapping && length >= BONK_CROWD_MIN_STEP;
    float endX = body.px, endY = body.py;
    bool moved = false;
    if ((before - after >= need || separating) && length >= BONK_CROWD_MIN_STEP)
        moved = Launch(body, std::atan2(stepY, stepX), length, heroX, heroY, endX, endY);

    if (!moved)
        Stand(body, heroX, heroY);

    if (!moved && body.wanted >= need && !body.pressed)
    {
        mover.wallStuckMs += BONK_CROWD_TICK_MS;
        if (mover.wallStuckMs >= BONK_CROWD_WALL_STUCK_MS)
        {
            mover.wallStuckMs = 0;
            mover.corners.clear();
            stuck.push_back(body.mob);
        }
    }
    else
        mover.wallStuckMs = 0;
    if (body.pressed)
        mover.pressedMs = m_clockMs;

    float const slack = heroMoving ? m_settings.touchSlackRunning : m_settings.touchSlack;
    float const reach = m_settings.heroRadius + body.radius + slack;
    bool const touching = Distance2d(endX, endY, heroX, heroY) <= reach;
    body.mob->SetBonkCrowdTouching(!body.melee || touching);
    if (touching)
        ++m_touchingCount;
    if (mover.standing)
        ++m_standingCount;
}

float BonkCrowd::GetTurnRate(float radius) const
{
    float const share = std::min(1.0f, std::max(0.0f, (radius - BONK_CROWD_SMALL_RADIUS) / (BONK_CROWD_LARGE_RADIUS - BONK_CROWD_SMALL_RADIUS)));
    float const degrees = m_settings.turnRateSmall + (m_settings.turnRateLarge - m_settings.turnRateSmall) * share;
    return degrees * M_PI_F / 180.0f;
}

bool BonkCrowd::Launch(Body& body, float heading, float length, float heroX, float heroY, float& endX, float& endY)
{
    Mover& mover = *body.mover;
    Creature* mob = body.mob;
    bool const walking = mover.sentMoving && !mob->movespline->Finalized();
    float const startHeading = walking ? mover.heading : mob->GetAngle(heroX, heroY);
    float const turnRate = GetTurnRate(body.radius);
    float const remaining = std::fabs(AngleDiff(heading, TurnToward(startHeading, heading, turnRate * TickSeconds())));
    float const pace = remaining >= BONK_CROWD_SHARP_TURN ? BONK_CROWD_SHARP_TURN_PACE :
        1.0f - (1.0f - BONK_CROWD_SHARP_TURN_PACE) * remaining / BONK_CROWD_SHARP_TURN;
    float const velocity = length * pace / TickSeconds();
    if (velocity * TickSeconds() < BONK_CROWD_MIN_STEP)
        return false;

    float const horizonSeconds = float(BONK_CROWD_HORIZON_MS) / float(IN_MILLISECONDS);
    uint32 const steps = std::max(1u, std::min(BONK_CROWD_ARC_STEPS, uint32(velocity * horizonSeconds / BONK_CROWD_ARC_SPACING)));
    float const stepSeconds = horizonSeconds / float(steps);
    Movement::PointsArray path;
    path.push_back(G3D::Vector3(body.px, body.py, body.pz));
    float x = body.px, y = body.py;
    for (uint32 i = 1; i <= steps; ++i)
    {
        float const pointHeading = TurnToward(startHeading, heading, turnRate * stepSeconds * float(i));
        x += std::cos(pointHeading) * velocity * stepSeconds;
        y += std::sin(pointHeading) * velocity * stepSeconds;
        path.push_back(G3D::Vector3(x, y, body.pz));
    }

    float hitX = x, hitY = y, hitZ = body.pz;
    ++m_cost.walkRays;
    if (!WalkRay(mob->GetMapId(), body.px, body.py, body.pz, hitX, hitY, hitZ))
        return false;
    float const chord = Distance2d(body.px, body.py, x, y);
    float const reached = Distance2d(body.px, body.py, hitX, hitY);
    if (reached < chord - 0.05f)
    {
        if (reached < BONK_CROWD_MIN_STEP)
            return false;
        path.resize(1);
        path.push_back(G3D::Vector3(hitX, hitY, hitZ));
    }
    for (size_t i = 1; i < path.size(); ++i)
        mob->UpdateAllowedPositionZ(path[i].x, path[i].y, path[i].z);

    float travel = 0.0f;
    for (size_t i = 1; i < path.size(); ++i)
        travel += Distance2d(path[i - 1].x, path[i - 1].y, path[i].x, path[i].y);
    float const tickShare = std::min(1.0f, velocity * TickSeconds() / std::max(travel, 0.01f));
    size_t const tickPoint = std::min(path.size() - 1, size_t(std::ceil(tickShare * float(path.size() - 1))));
    endX = path[tickPoint].x;
    endY = path[tickPoint].y;

    float const courseX = (path.back().x - body.px) / std::max(travel, 0.01f);
    float const courseY = (path.back().y - body.py) / std::max(travel, 0.01f);
    bool const steady = std::fabs(AngleDiff(heading, startHeading)) <= BONK_CROWD_STEADY_TURN;
    bool const sameCourse = steady && mover.sentMoving && !mob->movespline->Finalized() &&
        courseX * mover.sentDirX + courseY * mover.sentDirY >= BONK_CROWD_RESEND_COS &&
        std::fabs(velocity - mover.sentSpeed) <= mover.sentSpeed * BONK_CROWD_RESEND_SPEED &&
        int32(mover.sentEndMs - m_clockMs) > int32(BONK_CROWD_TICK_MS + 50);
    mover.standing = false;
    if (sameCourse)
        return true;

    Movement::MoveSplineInit init(*mob, "BonkCrowd");
    init.MovebyPath(path);
    init.SetWalk(velocity < body.speed * BONK_CROWD_WALK_SHARE);
    init.SetVelocity(velocity);
    init.Launch();
    ++m_cost.launches;

    mover.sentMoving = true;
    mover.heading = TurnToward(startHeading, heading, turnRate * TickSeconds());
    mover.sentDirX = courseX;
    mover.sentDirY = courseY;
    mover.sentSpeed = velocity;
    mover.sentEndMs = m_clockMs + uint32(travel / velocity * IN_MILLISECONDS);
    return true;
}

void BonkCrowd::Stand(Body& body, float heroX, float heroY)
{
    Mover& mover = *body.mover;
    Creature* mob = body.mob;
    if (mover.sentMoving || !mob->movespline->Finalized())
        mob->StopMoving();
    mover.sentMoving = false;
    mover.standing = true;

    mob->SetOrientation(mob->GetAngle(heroX, heroY));
}

bool BonkCrowd::Shove(Creature* mob, Player* hero, float fromX, float fromY, float distance, float speed, uint32 gapMs)
{
    if (distance <= 0.0f || speed <= 0.0f || GetHold(mob, hero, false) != HOLD_NONE)
        return false;
    Mover& mover = m_movers[mob->GetObjectGuid().GetRawValue()];
    if (mover.shoved && !MillisecondsPassed(mover.shovedMs, m_clockMs, gapMs))
        return false;

    float const angle = std::atan2(mob->GetPositionY() - fromY, mob->GetPositionX() - fromX);
    float x = mob->GetPositionX() + std::cos(angle) * distance;
    float y = mob->GetPositionY() + std::sin(angle) * distance;
    float z = mob->GetPositionZ();
    if (!WalkRay(mob->GetMapId(), mob->GetPositionX(), mob->GetPositionY(), mob->GetPositionZ(), x, y, z))
        return false;
    if (Distance2d(mob->GetPositionX(), mob->GetPositionY(), x, y) < BONK_CROWD_MIN_SHOVE)
        return false;
    mob->UpdateAllowedPositionZ(x, y, z);

    Movement::MoveSplineInit init(*mob, "BonkShove");
    init.MoveTo(x, y, z, MOVE_FORCE_DESTINATION);
    init.SetFacingGUID(hero->GetObjectGuid().GetRawValue());
    init.SetVelocity(speed);
    init.Launch();

    mover.shoved = true;
    mover.shovedMs = m_clockMs;
    mover.sentMoving = false;
    mover.standing = false;
    mover.lastSeenMs = m_clockMs;
    return true;
}

bool BonkCrowd::Halt(Creature* mob, Player* hero, uint32 haltMs, uint32 gapMs)
{
    if (!haltMs || GetHold(mob, hero, false) != HOLD_NONE)
        return false;
    Mover& mover = m_movers[mob->GetObjectGuid().GetRawValue()];
    if (mover.shoved && !MillisecondsPassed(mover.shovedMs, m_clockMs, gapMs))
        return false;

    if (!mob->movespline->Finalized())
        mob->StopMoving();
    mover.shoved = true;
    mover.shovedMs = m_clockMs;
    mover.haltUntilMs = m_clockMs + haltMs;
    mover.sentMoving = false;
    mover.standing = true;
    mover.lastSeenMs = m_clockMs;
    return true;
}

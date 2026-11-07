#ifndef BONK_CROWD_H
#define BONK_CROWD_H

#include "Common.h"
#include "ObjectGuid.h"

#include <G3D/Vector3.h>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

class Creature;
class Player;

class BonkCrowd
{
    public:
        struct Settings
        {
            float heroRadius = 0.5f;
            float bodyScale = 1.0f;
            float minRadius = 0.5f;
            float maxRadius = 3.0f;
            float touchSlack = 0.8f;
            float touchSlackRunning = 1.5f;
            float moveShare = 0.15f;
            float startShare = 0.4f;
            float overlapEase = 0.5f;
            float holdMass = 0.25f;
            float turnRateSmall = 240.0f;
            float turnRateLarge = 120.0f;
            float flowAngle = 50.0f;
            float shoveDistance = 0.5f;
            float shoveSpeed = 2.5f;
            float shoveGapMs = 450.0f;
            float veteranShoveDistance = 0.3f;
            float haltMs = 250.0f;
            float haltGapMs = 1000.0f;
            float levelPushRadius = 10.0f;
            float levelPushDistance = 4.0f;
            float levelPushSpeed = 10.0f;
        };

        struct Cost
        {
            uint32 ticks = 0;
            uint64 totalUs = 0;
            uint32 worstUs = 0;
            uint64 gatherUs = 0;
            uint64 goalUs = 0;
            uint64 solveUs = 0;
            uint64 steerUs = 0;
            uint64 bodies = 0;
            uint64 driven = 0;
            uint64 walkRays = 0;
            uint64 paths = 0;
            uint64 pathUs = 0;
            uint64 sightChecks = 0;
            uint64 sightUs = 0;
            uint64 launches = 0;
            void Add(Cost const& other);
        };

        void Update(uint32 diff, Player* hero, std::vector<ObjectGuid> const& mobs, bool heroPerched, std::vector<Creature*>& stuck);
        void Clear() { m_movers.clear(); m_tickTimer = 0; }
        Cost TakeCost() { Cost const cost = m_cost; m_cost = Cost(); return cost; }
        bool Shove(Creature* mob, Player* hero, float fromX, float fromY, float distance, float speed, uint32 gapMs);
        bool Halt(Creature* mob, Player* hero, uint32 haltMs, uint32 gapMs);
        static std::vector<std::pair<char const*, float*>> GetTunables();
        static Settings const& GetSettings() { return m_settings; }
        std::string Describe() const;

    private:
        struct Mover
        {
            bool standing = true;
            bool sentMoving = false;
            float sentDirX = 0.0f, sentDirY = 0.0f, sentSpeed = 0.0f;
            uint32 sentEndMs = 0;
            bool direct = true;
            uint32 directCheckMs = 0;
            std::vector<G3D::Vector3> corners;
            uint32 pathMs = 0;
            float pathGoalX = 0.0f, pathGoalY = 0.0f;
            bool canSeeHero = true;
            uint32 sightCheckMs = 0;
            uint32 wallStuckMs = 0;
            uint32 lastSeenMs = 0;
            uint32 pressedMs = 0;
            uint32 flowUntilMs = 0;
            float flowAngle = 0.0f;
            float heading = 0.0f;
            uint32 shovedMs = 0;
            uint32 haltUntilMs = 0;
            bool shoved = false;
        };

        struct Body
        {
            Creature* mob = nullptr;
            Mover* mover = nullptr;
            float px = 0.0f, py = 0.0f, pz = 0.0f;
            float qx = 0.0f, qy = 0.0f;
            float radius = 0.5f;
            float invMass = 0.0f;
            float speed = 0.0f;
            float dirX = 0.0f, dirY = 0.0f;
            float goalX = 0.0f, goalY = 0.0f, goalZ = 0.0f;
            float stopDistance = 0.0f;
            float wanted = 0.0f;
            bool melee = true;
            bool passThrough = false;
            bool overlapping = false;
            bool pressed = false;
            std::vector<uint32> neighbours;
        };

        enum Hold : uint8
        {
            HOLD_NONE,
            HOLD_NAVMESH,
            HOLD_PERCHED,
            HOLD_VICTIM,
            HOLD_CANNOT_MOVE,
            HOLD_CASTING,
            HOLD_MOTION,
            HOLD_SPLINE,
            HOLD_AI,
            MAX_HOLD
        };
        Hold GetHold(Creature* mob, Player* hero, bool heroPerched) const;
        void PickGoal(Body& body, Player* hero, float heroX, float heroY, float heroZ);
        void UpdatePath(Body& body, float heroX, float heroY, float heroZ);
        void Solve(std::vector<Body>& bodies, float heroX, float heroY);
        void KeepOut(Body const& body, float otherX, float otherY, float contact, float& stepX, float& stepY) const;
        void Steer(Body& body, std::vector<Body> const& bodies, float heroX, float heroY, bool heroMoving, std::vector<Creature*>& stuck);
        float GetTurnRate(float radius) const;
        std::string DescribeHolds() const;
        bool Launch(Body& body, float heading, float length, float heroX, float heroY, float& endX, float& endY);
        void Stand(Body& body, float heroX, float heroY);

        static Settings m_settings;
        std::unordered_map<uint64, Mover> m_movers;
        uint32 m_tickTimer = 0;
        uint32 m_clockMs = 0;
        uint32 m_drivenCount = 0;
        uint32 m_standingCount = 0;
        uint32 m_holdCounts[MAX_HOLD] = {};
        uint32 m_deepPairs = 0;
        uint32 m_touchingCount = 0;
        Cost m_cost;
};

#endif

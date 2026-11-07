#include "BonkRunInternal.h"

uint32 BonkRun::GetSpawnTarget() const
{
    if (m_stress.on)
        return m_tier.maxAlive;
    float target = std::min(GetCurveMinAlive(), float(m_tier.maxAlive));
    if (m_bossSpawned)
        target *= BONK_BOSS_CROWD;
    target *= GetCoopSpawnShare();
    return uint32(target + 0.5f);
}

float BonkRun::GetCrowdOverflow() const
{
    return std::max(1.0f, GetCurveMinAlive() / float(m_tier.maxAlive));
}

uint32 BonkRun::GetEliteIntervalMs() const
{
    uint32 const interval = GetWave().eliteIntervalSeconds;
    if (!interval)
        return 0;
    float const share = GetCoopSpawnShare();
    if (share <= 0.0f)
        return 0;
    return uint32(interval * IN_MILLISECONDS / GetEliteScale() / share);
}

float BonkRun::GetEliteScale() const
{
    return (1.0f + m_bonuses.eliteRate / 100.0f) * (1.0f + GetGlyphValue(BONK_GLYPH_HUNT, 0) / 100.0f);
}

BonkMapCreature const* BonkRun::PickTrash() const
{
    if (m_stress.on)
        return PickCreature(BONK_SPAWN_NORMAL);

    BonkWave const& wave = GetWave();
    uint32 weights[MAX_BONK_ARCHETYPE] = {};
    uint32 total = 0;
    bool const bruiserRoom = !m_bossSpawned && CountBruisers() < GetMaxBruisers();
    for (uint8 archetype = 0; archetype < MAX_BONK_ARCHETYPE; ++archetype)
    {
        uint32 weight = wave.roster[archetype];
        if (!weight && IsInRoster(BonkArchetype(archetype)))
            weight = 15;
        if (archetype == BONK_ARCHETYPE_BRUISER && !bruiserRoom)
            weight = 0;
        weights[archetype] = weight;
        total += weight;
    }

    for (uint32 attempt = 0; attempt < 3 && total; ++attempt)
    {
        uint32 roll = urand(1, total);
        for (uint8 archetype = 0; archetype < MAX_BONK_ARCHETYPE; ++archetype)
        {
            if (roll > weights[archetype])
            {
                roll -= weights[archetype];
                continue;
            }
            if (BonkMapCreature const* creature = PickCreature(BONK_SPAWN_NORMAL, archetype))
                return creature;
            total -= weights[archetype];
            weights[archetype] = 0;
            break;
        }
    }
    return nullptr;
}

uint32 BonkRun::GetMaxBruisers() const
{
    uint32 const wave = GetWave().maxBruisers;
    uint32 const cap = wave ? wave : m_tier.maxBruisers;
    return std::max(1u, uint32(cap * GetOpeningEase() + 0.5f));
}

uint32 BonkRun::CountTrash() const
{
    Map* map = m_player->GetMap();
    uint32 count = 0;
    for (ObjectGuid const& guid : m_mobs)
        if (Creature const* mob = map->GetCreature(guid))
            if (BonkMobAI const* ai = dynamic_cast<BonkMobAI const*>(mob->AI()))
                if (ai->GetKind() == BONK_SPAWN_NORMAL)
                    ++count;
    return count;
}

uint32 BonkRun::CountBruisers() const
{
    Map* map = m_player->GetMap();
    uint32 count = 0;
    for (ObjectGuid const& guid : m_mobs)
        if (Creature const* mob = map->GetCreature(guid))
            if (mob->IsAlive())
                if (BonkMobAI const* ai = dynamic_cast<BonkMobAI const*>(mob->AI()))
                    if (ai->GetKind() == BONK_SPAWN_NORMAL && ai->GetArchetype() == BONK_ARCHETYPE_BRUISER && !ai->IsFlyer())
                        ++count;
    return count;
}

BonkMapCreature const* BonkRun::PickCreature(BonkSpawnKind kind, int32 archetype) const
{
    uint32 const elapsedSeconds = m_elapsedMs / IN_MILLISECONDS;

    std::vector<BonkMapCreature const*> candidates;
    uint32 totalWeight = 0;
    for (bool windows : { true, false })
    {
        for (auto const& creature : m_map.creatures)
        {
            if (creature.kind != kind || creature.flyer)
                continue;
            if (windows && (elapsedSeconds < creature.minSecond || (creature.maxSecond && elapsedSeconds > creature.maxSecond)))
                continue;
            if (kind == BONK_SPAWN_NORMAL && archetype >= 0 && int32(creature.archetype) != archetype)
                continue;
            if (creature.maxAlive && CountAlive(creature.entry) >= creature.maxAlive)
                continue;
            candidates.push_back(&creature);
            totalWeight += creature.weight;
        }
        if (totalWeight || kind != BONK_SPAWN_NORMAL || archetype < 0)
            break;
    }

    if (!totalWeight)
        return nullptr;

    uint32 roll = urand(1, totalWeight);
    for (BonkMapCreature const* creature : candidates)
    {
        if (roll <= creature->weight)
            return creature;
        roll -= creature->weight;
    }
    return nullptr;
}

uint32 BonkRun::CountAlive(uint32 entry) const
{
    Map* map = m_player->GetMap();
    uint32 count = 0;
    for (ObjectGuid const& guid : m_mobs)
        if (guid.GetEntry() == entry)
            if (Creature const* mob = map->GetCreature(guid))
                if (mob->IsAlive() && !mob->HasCreatureState(CSTATE_DESPAWNING))
                    ++count;
    return count;
}

bool BonkRun::FindSpawnPosition(float& x, float& y, float& z, float minDistance, float maxDistance) const
{
    for (uint32 attempt = 0; attempt < 10; ++attempt)
        if (FindSpawnPositionAt(frand(0.0f, 2.0f * M_PI_F), frand(minDistance, maxDistance), x, y, z))
            return true;
    return false;
}

bool BonkRun::FindSpawnPositionAt(float angle, float distance, float& x, float& y, float& z) const
{
    Map const* map = m_player->GetMap();
    bool const fromGround = m_perched && m_hasGround;
    float const playerZ = fromGround ? m_groundZ : m_player->GetPositionZ();

    x = m_player->GetPositionX() + distance * std::cos(angle);
    y = m_player->GetPositionY() + distance * std::sin(angle);
    z = map->GetHeight(x, y, playerZ + BONK_SPAWN_MAX_HEIGHT_DIFF, true, 2.0f * BONK_SPAWN_MAX_HEIGHT_DIFF);

    if (z <= INVALID_HEIGHT || std::fabs(z - playerZ) > BONK_SPAWN_MAX_HEIGHT_DIFF)
        return false;

    if (m_map.zoneId && map->GetTerrain()->GetZoneId(x, y, z) != m_map.zoneId)
        return false;

    bool found = false;
    if (fromGround)
        found = FindSpawnPathFrom(m_groundX, m_groundY, m_groundZ, distance, x, y, z);
    else
        found = FindSpawnPathFrom(m_player->GetPositionX(), m_player->GetPositionY(), m_player->GetPositionZ(), distance, x, y, z) ||
            (m_hasGround && FindSpawnPathFrom(m_groundX, m_groundY, m_groundZ, distance, x, y, z));
    return found && IsBonkDryGround(map, x, y, z);
}

bool BonkRun::FindSpawnPathFrom(float fromX, float fromY, float fromZ, float distance, float& x, float& y, float& z) const
{
    PathFinder path(m_player);
    path.ExcludeSteepSlopes();
    path.calculate(Vector3(fromX, fromY, fromZ), Vector3(x, y, z));
    if (path.getPathType() & PATHFIND_NOT_USING_PATH)
        return true;
    if (!(path.getPathType() & PATHFIND_NORMAL) || path.Length() > distance * BONK_SPAWN_MAX_DETOUR)
        return false;

    Vector3 const end = path.getActualEndPosition();
    if ((end.x - x) * (end.x - x) + (end.y - y) * (end.y - y) > BONK_SPAWN_SNAP_DISTANCE * BONK_SPAWN_SNAP_DISTANCE)
        return false;

    x = end.x;
    y = end.y;
    z = end.z;
    return true;
}

void BonkRun::UpdateHeading(uint32 diff)
{
    m_headingTimer += diff;
    if (m_headingTimer < BONK_HEADING_SAMPLE_MS)
        return;
    float const seconds = m_headingTimer / float(IN_MILLISECONDS);
    m_headingTimer = 0;

    float const x = m_player->GetPositionX();
    float const y = m_player->GetPositionY();
    float const dx = x - m_lastX;
    float const dy = y - m_lastY;
    m_lastX = x;
    m_lastY = y;

    if (dx * dx + dy * dy > BONK_HEADING_MAX_STEP * BONK_HEADING_MAX_STEP)
    {
        m_moveX = m_moveY = 0.0f;
        return;
    }

    float const blend = std::min(1.0f, seconds / BONK_HEADING_SMOOTH_SEC);
    m_moveX += (dx / seconds - m_moveX) * blend;
    m_moveY += (dy / seconds - m_moveY) * blend;
}

bool BonkRun::GetHeading(float& angle) const
{
    if (m_moveX * m_moveX + m_moveY * m_moveY < BONK_HEADING_MIN_SPEED * BONK_HEADING_MIN_SPEED)
        return false;
    angle = std::atan2(m_moveY, m_moveX);
    return true;
}

float BonkRun::GetForwardAngle() const
{
    float angle;
    return GetHeading(angle) ? angle : m_player->GetOrientation();
}

bool BonkRun::IsAhead(float x, float y, float forward) const
{
    float const dx = x - m_player->GetPositionX();
    float const dy = y - m_player->GetPositionY();
    if (dx * dx + dy * dy > BONK_FRONT_RANGE * BONK_FRONT_RANGE)
        return false;
    return AngleBetween(std::atan2(dy, dx), forward) <= BONK_FRONT_ARC;
}

uint32 BonkRun::CountAhead(float forward) const
{
    Map* map = m_player->GetMap();
    uint32 count = 0;
    for (ObjectGuid const& guid : m_mobs)
        if (Creature const* mob = map->GetCreature(guid))
            if (mob->IsAlive() && !mob->HasCreatureState(CSTATE_DESPAWNING) && IsAhead(mob->GetPositionX(), mob->GetPositionY(), forward))
                ++count;
    return count;
}

uint32 BonkRun::GetFrontCap() const
{
    return std::max(BONK_FRONT_MIN, uint32(m_mobs.size() * BONK_FRONT_SHARE + 0.5f));
}

bool BonkRun::FindMobPosition(float& x, float& y, float& z, float minDistance, float maxDistance) const
{
    std::vector<float> const crowd = CountSectorCrowd();
    for (uint32 attempt = 0; attempt < BONK_SECTOR_TRIES; ++attempt)
    {
        int32 const sector = PickSector(crowd, false);
        if (sector < 0)
            break;
        if (FindSectorPosition(uint32(sector), minDistance, maxDistance, x, y, z))
            return true;
    }
    return FindSpawnPosition(x, y, z, minDistance, maxDistance);
}

void BonkRun::UpdatePerch(uint32 diff)
{
    if (!m_player->IsAlive())
    {
        m_perched = false;
        m_perchChecks = 0;
        m_reachChecks = 0;
        return;
    }
    if (m_perched)
        UpdateFlyers(diff);

    m_perchTimer += diff;
    if (m_perchTimer < BONK_PERCH_CHECK_MS || m_player->IsFalling() || m_player->IsBeingTeleported())
        return;
    m_perchTimer = 0;

    if (IsHeroReachable())
    {
        if (m_perched && ++m_reachChecks < BONK_PERCH_CLEAR_CHECKS)
            return;
        m_perched = false;
        m_perchChecks = 0;
        m_reachChecks = 0;
        m_hasGround = true;
        m_groundX = m_reachFound ? m_reachX : m_player->GetPositionX();
        m_groundY = m_reachFound ? m_reachY : m_player->GetPositionY();
        m_groundZ = m_reachFound ? m_reachZ : m_player->GetPositionZ();
        return;
    }

    m_reachChecks = 0;
    if (m_perched || ++m_perchChecks < BONK_PERCH_CONFIRM_CHECKS)
        return;
    m_perched = true;
    m_perchedMs = 0;
    m_flyerTimer = BONK_FLYER_FIRST_MS;
}

void BonkRun::UpdateDryGround(uint32 diff)
{
    m_dryGroundTimer += diff;
    if (m_dryGroundTimer < BONK_DRY_GROUND_CHECK_MS)
        return;
    uint32 const elapsed = m_dryGroundTimer;
    m_dryGroundTimer = 0;
    if (!m_player->IsAlive() || m_player->IsBeingTeleported())
    {
        m_hazardMs = 0;
        return;
    }

    Map const* map = m_player->GetMap();
    float const x = m_player->GetPositionX(), y = m_player->GetPositionY(), z = m_player->GetPositionZ();
    if (!IsInBonkHazard(map, x, y, z))
    {
        m_hazardMs = 0;
        if (!m_player->IsFalling() && IsBonkDryGround(map, x, y, z))
        {
            m_hasDryGround = true;
            m_dryX = x;
            m_dryY = y;
            m_dryZ = z;
        }
        return;
    }

    m_hazardMs += elapsed;
    if (m_hazardMs < BONK_HAZARD_RESCUE_MS || !m_hasDryGround)
        return;
    m_hazardMs = 0;
    m_player->NearTeleportTo(m_dryX, m_dryY, m_dryZ, m_player->GetOrientation());
}

void BonkRun::MoveToSafeGround(float& x, float& y, float& z) const
{
    if (SnapBonkToSafeGround(m_player, BONK_DROP_SAFE_SHIFT, x, y, z) || !m_hasDryGround)
        return;
    x = m_dryX;
    y = m_dryY;
    z = m_dryZ;
}

bool BonkRun::IsHeroReachable() const
{
    m_reachFound = false;
    if (HasStrandedMobs())
        return false;

    uint32 probes = 0;
    for (Creature* mob : GetMobsInRange(BONK_PERCH_SENSE_RANGE))
    {
        BonkMobAI const* ai = dynamic_cast<BonkMobAI const*>(mob->AI());
        if (!ai || ai->IsFlyer() || !ai->CanBePulled())
            continue;
        if (IsReachableFrom(mob->GetPositionX(), mob->GetPositionY(), mob->GetPositionZ(), mob))
            return true;
        if (++probes >= BONK_PERCH_PROBES)
            return false;
    }

    Map const* map = m_player->GetMap();
    float const heroZ = m_player->GetPositionZ();
    for (uint32 point = 0; point < BONK_PERCH_RING_POINTS; ++point)
    {
        float const angle = 2.0f * M_PI_F * point / BONK_PERCH_RING_POINTS;
        float const x = m_player->GetPositionX() + BONK_PERCH_RING_DISTANCE * std::cos(angle);
        float const y = m_player->GetPositionY() + BONK_PERCH_RING_DISTANCE * std::sin(angle);
        float const z = map->GetHeight(x, y, heroZ + BONK_SPAWN_MAX_HEIGHT_DIFF, true, 2.0f * BONK_SPAWN_MAX_HEIGHT_DIFF);
        if (z > INVALID_HEIGHT && IsReachableFrom(x, y, z, nullptr))
            return true;
    }
    return false;
}

bool BonkRun::HasStrandedMobs() const
{
    if (m_totalMs - m_lastStruckMs < BONK_PERCH_UNSTRUCK_MS)
        return false;
    uint32 stranded = 0;
    for (Creature* mob : GetMobsInRange(BONK_PERCH_STRANDED_RANGE))
    {
        BonkMobAI const* ai = dynamic_cast<BonkMobAI const*>(mob->AI());
        if (!ai || ai->IsFlyer() || !ai->CanBePulled() || mob->IsMoving() ||
            mob->HasUnitState(UNIT_STATE_STUNNED | UNIT_STATE_ROOT | UNIT_STATE_CONFUSED | UNIT_STATE_FLEEING))
            continue;
        if (mob->GetMotionMaster()->GetCurrentMovementGeneratorType() != CHASE_MOTION_TYPE || mob->GetVictim() != m_player)
            continue;
        ++stranded;
    }
    return stranded >= BONK_PERCH_STRANDED_MOBS;
}

bool BonkRun::IsReachableFrom(float x, float y, float z, Creature const* prober) const
{
    float const heroX = m_player->GetPositionX();
    float const heroY = m_player->GetPositionY();
    float const heroZ = m_player->GetPositionZ();

    PathFinder path(prober ? static_cast<Unit const*>(prober) : m_player);
    path.calculate(Vector3(x, y, z), Vector3(heroX, heroY, heroZ));
    if (path.getPathType() & PATHFIND_NOPATH)
        return false;

    Vector3 const end = path.getActualEndPosition();
    float const dx = end.x - heroX;
    float const dy = end.y - heroY;
    float const dz = end.z - heroZ;
    bool const reaches = prober ? prober->CanReachWithMeleeAutoAttackAtPosition(m_player, end.x, end.y, end.z) :
        dx * dx + dy * dy + dz * dz <= BONK_PERCH_REACH * BONK_PERCH_REACH;
    if (reaches)
    {
        m_reachFound = true;
        m_reachX = end.x;
        m_reachY = end.y;
        m_reachZ = end.z;
    }
    return reaches;
}

void BonkRun::UpdateFlyers(uint32 diff)
{
    m_perchedMs += diff;
    if (m_flyerTimer > diff)
    {
        m_flyerTimer -= diff;
        return;
    }
    m_flyerTimer = BONK_FLYER_INTERVAL_MS;

    uint32 const alive = CountFlyers();
    if (alive >= BONK_FLYER_MAX_ALIVE)
        return;
    uint32 const ramp = BONK_FLYER_PACK_MIN + m_perchedMs / BONK_FLYER_RAMP_MS;
    SpawnFlyerPack(std::min(std::min(ramp, BONK_FLYER_PACK_MAX), BONK_FLYER_MAX_ALIVE - alive));
}

void BonkRun::SpawnFlyerPack(uint32 count)
{
    float x, y, z;
    if (!FindFlyerPosition(x, y, z))
        return;

    for (uint32 index = 0; index < count; ++index)
    {
        BonkMapCreature const* picked = PickFlyer();
        if (!picked)
            return;
        BonkMapCreature creature = *picked;
        creature.kind = BONK_SPAWN_NORMAL;
        creature.archetype = BONK_ARCHETYPE_BRUISER;
        float const angle = frand(0.0f, 2.0f * M_PI_F);
        float const offset = frand(0.0f, BONK_FLYER_PACK_RADIUS);
        BonkMobAI::SetNextFlyer(true);
        if (!SpawnMobAt(creature, x + offset * std::cos(angle), y + offset * std::sin(angle), z + frand(-1.0f, 1.0f)))
            BonkMobAI::SetNextFlyer(false);
    }
}

bool BonkRun::FindFlyerPosition(float& x, float& y, float& z) const
{
    Map const* map = m_player->GetMap();
    float const heroX = m_player->GetPositionX();
    float const heroY = m_player->GetPositionY();
    float const heroZ = m_player->GetPositionZ();

    for (uint32 attempt = 0; attempt < BONK_FLYER_TRIES; ++attempt)
    {
        float const angle = frand(0.0f, 2.0f * M_PI_F);
        float const distance = frand(BONK_FLYER_MIN_DISTANCE, BONK_FLYER_MAX_DISTANCE);
        x = heroX + distance * std::cos(angle);
        y = heroY + distance * std::sin(angle);
        float const ground = map->GetHeight(x, y, heroZ + BONK_SPAWN_MAX_HEIGHT_DIFF, true, 2.0f * BONK_SPAWN_MAX_HEIGHT_DIFF);
        z = std::max(ground, heroZ) + BONK_FLYER_HEIGHT;
        if (m_map.zoneId && map->GetTerrain()->GetZoneId(x, y, z) != m_map.zoneId)
            continue;
        if (map->isInLineOfSight(x, y, z, heroX, heroY, heroZ + 2.0f))
            return true;
    }
    return false;
}

BonkMapCreature const* BonkRun::PickFlyer() const
{
    std::vector<BonkMapCreature const*> candidates;
    uint32 totalWeight = 0;
    for (auto const& creature : m_map.creatures)
    {
        if (!creature.flyer)
            continue;
        candidates.push_back(&creature);
        totalWeight += creature.weight;
    }
    if (!totalWeight)
        return nullptr;

    uint32 roll = urand(1, totalWeight);
    for (BonkMapCreature const* creature : candidates)
    {
        if (roll <= creature->weight)
            return creature;
        roll -= creature->weight;
    }
    return nullptr;
}

uint32 BonkRun::CountFlyers() const
{
    Map* map = m_player->GetMap();
    uint32 count = 0;
    for (ObjectGuid const& guid : m_mobs)
        if (Creature const* mob = map->GetCreature(guid))
            if (mob->IsAlive() && !mob->HasCreatureState(CSTATE_DESPAWNING) && mob->IsBonkFlyer())
                ++count;
    return count;
}

void BonkRun::UpdateLanes(uint32 diff)
{
    m_laneTimer += diff;
    if (m_lanes[0] >= 0 && m_laneTimer < BONK_LANE_SHIFT_MS)
        return;
    m_laneTimer = 0;

    int32 const sectors = int32(BONK_SPAWN_SECTORS);
    if (m_lanes[0] < 0)
    {
        m_lanes[0] = irand(0, sectors - 1);
        m_lanes[1] = (m_lanes[0] + sectors / 2 + irand(-1, 1) + sectors) % sectors;
        return;
    }
    for (uint32 i = 0; i < 2; ++i)
    {
        int32 const moved = (m_lanes[i] + irand(-1, 1) + sectors) % sectors;
        int32 const apart = std::abs(moved - m_lanes[1 - i]);
        if (std::min(apart, sectors - apart) >= int32(BONK_LANE_MIN_GAP))
            m_lanes[i] = moved;
    }
}

bool BonkRun::IsLane(uint32 sector) const
{
    return int32(sector) == m_lanes[0] || int32(sector) == m_lanes[1];
}

bool BonkRun::IsLaneEdge(uint32 sector) const
{
    return IsLane((sector + 1) % BONK_SPAWN_SECTORS) || IsLane((sector + BONK_SPAWN_SECTORS - 1) % BONK_SPAWN_SECTORS);
}

float BonkRun::GetSectorAngle(uint32 sector) const
{
    return (float(sector) + 0.5f) * 2.0f * M_PI_F / float(BONK_SPAWN_SECTORS);
}

uint32 BonkRun::GetSectorOf(float x, float y) const
{
    float angle = std::atan2(y - m_player->GetPositionY(), x - m_player->GetPositionX());
    if (angle < 0.0f)
        angle += 2.0f * M_PI_F;
    return std::min(BONK_SPAWN_SECTORS - 1, uint32(angle / (2.0f * M_PI_F) * float(BONK_SPAWN_SECTORS)));
}

std::vector<float> BonkRun::CountSectorCrowd() const
{
    std::vector<float> crowd(BONK_SPAWN_SECTORS, 0.0f);
    Map* map = m_player->GetMap();
    auto const countIn = [&](ObjectGuid const& guid)
    {
        if (Creature const* mob = map->GetCreature(guid))
            if (mob->IsAlive() && mob->IsWithinDistInMap(m_player, BONK_SECTOR_RANGE))
                crowd[GetSectorOf(mob->GetPositionX(), mob->GetPositionY())] += 1.0f;
    };
    for (ObjectGuid const& guid : m_mobs)
        countIn(guid);
    for (TimedMob const& emerging : m_emerging)
        countIn(emerging.guid);
    return crowd;
}

BonkRun::SpawnOpenness BonkRun::GetSpawnOpenness() const
{
    if (m_tier.key == "normal")
        return { -0.5f, true, 1 };
    if (m_tier.key == "heroic")
        return { 0.0f, true, 0 };
    return { 1.0f, false, 0 };
}

std::vector<uint32> BonkRun::CountNearSectors(float range) const
{
    std::vector<uint32> nearby(BONK_SPAWN_SECTORS, 0);
    Map* map = m_player->GetMap();
    for (ObjectGuid const& guid : m_mobs)
        if (Creature const* mob = map->GetCreature(guid))
            if (mob->IsAlive() && mob->IsWithinDistInMap(m_player, range))
                ++nearby[GetSectorOf(mob->GetPositionX(), mob->GetPositionY())];
    return nearby;
}

std::vector<bool> BonkRun::GetGuardedSectors() const
{
    std::vector<bool> guarded(BONK_SPAWN_SECTORS, false);
    SpawnOpenness const openness = GetSpawnOpenness();
    if (!openness.guardGap)
        return guarded;

    std::vector<uint32> const nearby = CountNearSectors(BONK_GAP_RANGE);
    auto const occupied = std::find_if(nearby.begin(), nearby.end(), [](uint32 count) { return count > 0; });
    if (occupied == nearby.end())
        return guarded;

    uint32 centre = uint32(std::min_element(nearby.begin(), nearby.end()) - nearby.begin());
    uint32 const first = uint32(occupied - nearby.begin());
    uint32 bestStart = 0, bestLength = 0, runStart = 0, runLength = 0;
    for (uint32 step = 1; step <= BONK_SPAWN_SECTORS; ++step)
    {
        uint32 const sector = (first + step) % BONK_SPAWN_SECTORS;
        if (nearby[sector])
        {
            runLength = 0;
            continue;
        }
        if (!runLength)
            runStart = sector;
        if (++runLength > bestLength)
        {
            bestLength = runLength;
            bestStart = runStart;
        }
    }
    if (bestLength)
        centre = (bestStart + (bestLength - 1) / 2) % BONK_SPAWN_SECTORS;

    for (int32 offset = -int32(openness.guardHalfWidth); offset <= int32(openness.guardHalfWidth); ++offset)
        guarded[(int32(centre) + offset + int32(BONK_SPAWN_SECTORS)) % int32(BONK_SPAWN_SECTORS)] = true;
    return guarded;
}

void BonkRun::UpdateRingSample(uint32 diff)
{
    m_ringTimer += diff;
    if (m_ringTimer < BONK_RING_SAMPLE_MS)
        return;
    m_ringTimer = 0;
    std::vector<uint32> const nearby = CountNearSectors(BONK_RING_RANGE);
    uint32 const blocked = uint32(std::count_if(nearby.begin(), nearby.end(), [](uint32 count) { return count > 0; }));
    ++m_ringSamples;
    m_ringBlocked += blocked;
    if (blocked + 1 >= BONK_SPAWN_SECTORS)
        ++m_ringClosed;
}

void BonkRun::LogRing()
{
    if (m_ringSamples)
        sLog.Player(m_player->GetSession(), LOG_LEVELUP, LOG_LVL_BASIC,
            "Bonk ring: %s at run minute %u (%s, %s): %.1f of %u directions blocked within %.0f yd, closed %u%% of the time",
            m_player->GetName(), m_nextLogMinute, m_map.key.c_str(), m_tier.key.c_str(), float(m_ringBlocked) / float(m_ringSamples),
            BONK_SPAWN_SECTORS, BONK_RING_RANGE, m_ringClosed * 100 / m_ringSamples);
    m_ringSamples = 0;
    m_ringBlocked = 0;
    m_ringClosed = 0;
}

int32 BonkRun::PickSector(std::vector<float> const& crowd, bool frontOnly) const
{
    std::vector<bool> const guarded = GetGuardedSectors();
    float const fill = GetSpawnOpenness().fill;
    float heading;
    bool const moving = GetHeading(heading);
    float const forward = moving ? heading : m_player->GetOrientation();
    bool const frontFull = CountAhead(forward) >= GetFrontCap();
    if (m_sectorBlockedUntil.size() != BONK_SPAWN_SECTORS)
        m_sectorBlockedUntil.assign(BONK_SPAWN_SECTORS, 0);

    std::vector<float> weights(BONK_SPAWN_SECTORS, 0.0f);
    float total = 0.0f;
    for (uint32 sector = 0; sector < BONK_SPAWN_SECTORS; ++sector)
    {
        if (IsLane(sector) || guarded[sector] || m_sectorBlockedUntil[sector] > m_elapsedMs)
            continue;
        float const offset = AngleBetween(GetSectorAngle(sector), forward);
        if (frontOnly && offset > M_PI_F / 2.0f)
            continue;
        float bias = 1.0f;
        if (moving && offset <= BONK_FRONT_ARC)
            bias = frontFull ? 0.0f : BONK_FORWARD_WEIGHT;
        else if (moving && offset >= M_PI_F - BONK_FRONT_ARC)
            bias = BONK_BEHIND_WEIGHT;
        if (IsLaneEdge(sector))
            bias *= BONK_LANE_EDGE_WEIGHT;
        weights[sector] = bias * std::pow(1.0f + crowd[sector], -fill);
        total += weights[sector];
    }
    if (total <= 0.0f)
        return -1;

    float roll = frand(0.0f, total);
    for (uint32 sector = 0; sector < BONK_SPAWN_SECTORS; ++sector)
    {
        if (weights[sector] <= 0.0f)
            continue;
        if (roll <= weights[sector])
            return int32(sector);
        roll -= weights[sector];
    }
    return -1;
}

bool BonkRun::FindSectorPosition(uint32 sector, float minDistance, float maxDistance, float& x, float& y, float& z) const
{
    float const half = M_PI_F / float(BONK_SPAWN_SECTORS);
    float heading;
    bool const ahead = GetHeading(heading) && AngleBetween(GetSectorAngle(sector), heading) <= BONK_FRONT_ARC;
    for (uint32 attempt = 0; attempt < BONK_SECTOR_ANGLE_TRIES; ++attempt)
    {
        float const angle = GetSectorAngle(sector) + frand(-half, half);
        float const distance = ahead ? frand(BONK_FAR_MIN_DISTANCE, BONK_FAR_MAX_DISTANCE) : frand(minDistance, maxDistance);
        if (FindSpawnPositionAt(angle, distance, x, y, z))
            return true;
    }
    if (m_sectorBlockedUntil.size() == BONK_SPAWN_SECTORS)
        m_sectorBlockedUntil[sector] = m_elapsedMs + BONK_SECTOR_BLOCK_MS;
    return false;
}

void BonkRun::SpawnTrashPacks(uint32 count)
{
    std::vector<float> crowd = CountSectorCrowd();
    float const playerX = m_player->GetPositionX(), playerY = m_player->GetPositionY();
    while (count > 0)
    {
        uint32 const size = std::min(count, RollSpawnGroupSize());
        count -= size;
        uint32 const groupDelayMs = urand(0, BONK_SPAWN_TICK_MS);

        int32 sector = -1;
        float centreX = 0.0f, centreY = 0.0f, centreZ = 0.0f;
        bool found = false;
        for (uint32 attempt = 0; attempt < BONK_SECTOR_TRIES && !found; ++attempt)
        {
            sector = PickSector(crowd, false);
            if (sector < 0)
                break;
            found = FindSectorPosition(uint32(sector), m_map.spawnMinDistance, m_map.spawnMaxDistance, centreX, centreY, centreZ);
        }
        if (!found && !FindSpawnPosition(centreX, centreY, centreZ, m_map.spawnMinDistance, m_map.spawnMaxDistance))
            continue;

        for (uint32 i = 0; i < size; ++i)
        {
            BonkMapCreature const* creature = PickTrash();
            if (!creature)
                continue;
            float x = centreX, y = centreY, z = centreZ;
            if (i)
            {
                float const offsetAngle = frand(0.0f, 2.0f * M_PI_F);
                float const offset = frand(BONK_SPAWN_GROUP_MIN_GAP, BONK_SPAWN_GROUP_RADIUS);
                float const memberX = centreX + offset * std::cos(offsetAngle);
                float const memberY = centreY + offset * std::sin(offsetAngle);
                float const angle = std::atan2(memberY - playerY, memberX - playerX);
                float const distance = std::sqrt((memberX - playerX) * (memberX - playerX) + (memberY - playerY) * (memberY - playerY));
                if (!FindSpawnPositionAt(angle, distance, x, y, z))
                {
                    x = centreX;
                    y = centreY;
                    z = centreZ;
                }
            }
            bool const veteran = RollVeteran(*creature);
            bool const spawned = m_stress.on ? SpawnMobAt(*creature, x, y, z, veteran) != nullptr :
                EmergeMobAt(*creature, x, y, z, veteran, groupDelayMs + urand(0, BONK_EMERGE_MEMBER_STAGGER_MS));
            if (spawned && found)
                crowd[uint32(sector)] += 1.0f;
        }
    }
}

uint32 BonkRun::GetSpawnKit()
{
    return s_spawnKit;
}

void BonkRun::SetSpawnKit(uint32 kit)
{
    s_spawnKit = kit;
}

uint32 BonkRun::GetSpawnLookLeadMs()
{
    return s_spawnLookLeadMs;
}

void BonkRun::SetSpawnLookLeadMs(uint32 leadMs)
{
    s_spawnLookLeadMs = std::min(leadMs, BONK_EMERGE_HIDDEN_MS);
}

std::string BonkRun::DescribeSpawnLook() const
{
    return "Spawned enemies turn hostile " + std::to_string(s_spawnLookLeadMs) + " ms after their spawn flash; emerging now " +
        std::to_string(m_emerging.size()) + ".";
}

void BonkRun::PreviewSpawnLook()
{
    float const angle = m_player->GetOrientation();
    float x = m_player->GetPositionX() + BONK_SPAWN_LOOK_PREVIEW_DISTANCE * std::cos(angle);
    float y = m_player->GetPositionY() + BONK_SPAWN_LOOK_PREVIEW_DISTANCE * std::sin(angle);
    float z = m_player->GetMap()->GetHeight(x, y, m_player->GetPositionZ() + 5.0f, true, 15.0f);
    if (z <= INVALID_HEIGHT)
        z = m_player->GetPositionZ();
    ShowKitAt(s_spawnKit, x, y, z);
}

uint32 BonkRun::RollSpawnGroupSize() const
{
    uint32 const roll = urand(0, 99);
    if (roll < BONK_SPAWN_SINGLE_CHANCE)
        return 1;
    if (roll < BONK_SPAWN_SINGLE_CHANCE + BONK_SPAWN_PAIR_CHANCE)
        return 2;
    return urand(BONK_SPAWN_GROUP_MIN, BONK_SPAWN_GROUP_MAX);
}

bool BonkRun::EmergeMobAt(BonkMapCreature const& creature, float x, float y, float z, bool veteran, uint32 delayMs)
{
    if (m_sandbox)
        return SpawnMobAt(creature, x, y, z, veteran) != nullptr;
    if (!delayMs)
    {
        EmergeNow(creature, x, y, z, veteran);
        return true;
    }
    PendingSpawn pending;
    pending.creature = creature;
    pending.x = x;
    pending.y = y;
    pending.z = z;
    pending.veteran = veteran;
    pending.leftMs = int32(delayMs);
    m_pendingSpawns.push_back(pending);
    return true;
}

void BonkRun::EmergeNow(BonkMapCreature const& creature, float x, float y, float z, bool veteran)
{
    Creature* mob = SpawnMobAt(creature, x, y, z, veteran);
    if (!mob)
        return;
    ObjectGuid const guid = mob->GetObjectGuid();
    m_mobs.erase(std::remove(m_mobs.begin(), m_mobs.end(), guid), m_mobs.end());
    mob->SetFactionTemplateId(BONK_EMERGE_FACTION);
    mob->SetFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_IMMUNE_TO_PLAYER | UNIT_FLAG_IMMUNE_TO_NPC);
    if (BonkMobAI* ai = dynamic_cast<BonkMobAI*>(mob->AI()))
        ai->Hold(s_spawnLookLeadMs + BONK_EMERGE_SETTLE_MS);
    if (s_spawnKit)
        SendBonkKitAt(m_player, s_spawnKit, x, y, mob->GetPositionZ(), mob->GetOrientation(), BONK_SPAWN_LOOK_HOLD_MS);
    m_emerging.push_back({ guid, int32(s_spawnLookLeadMs) });
}

void BonkRun::UpdateEmerging(uint32 diff)
{
    for (auto itr = m_pendingSpawns.begin(); itr != m_pendingSpawns.end();)
    {
        itr->leftMs -= int32(diff);
        if (itr->leftMs > 0)
        {
            ++itr;
            continue;
        }
        PendingSpawn const due = *itr;
        itr = m_pendingSpawns.erase(itr);
        EmergeNow(due.creature, due.x, due.y, due.z, due.veteran);
    }

    Map* map = m_player->GetMap();
    for (auto itr = m_emerging.begin(); itr != m_emerging.end();)
    {
        Creature* mob = map->GetCreature(itr->guid);
        if (!mob || !mob->IsAlive() || mob->HasCreatureState(CSTATE_DESPAWNING))
        {
            itr = m_emerging.erase(itr);
            continue;
        }
        if (!itr->shown)
        {
            ShowEmergingBody(mob);
            itr->shown = true;
        }
        itr->leftMs -= int32(diff);
        if (itr->leftMs > 0)
        {
            ++itr;
            continue;
        }
        ActivateEmerged(mob);
        itr = m_emerging.erase(itr);
    }
}

void BonkRun::ShowEmergingBody(Creature* mob)
{
    mob->SetFacingTo(std::atan2(m_player->GetPositionY() - mob->GetPositionY(), m_player->GetPositionX() - mob->GetPositionX()));
}

void BonkRun::ActivateEmerged(Creature* mob)
{
    mob->SetFactionTemplateId(BONK_ENEMY_FACTION);
    mob->RemoveFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_IMMUNE_TO_PLAYER | UNIT_FLAG_IMMUNE_TO_NPC);
    if (BonkMobAI* ai = dynamic_cast<BonkMobAI*>(mob->AI()))
        ai->Hold(BONK_EMERGE_SETTLE_MS);
    m_mobs.push_back(mob->GetObjectGuid());
}

void BonkRun::ShowTeleportFlash(Creature* mob, float x, float y, float z)
{
    if (!s_spawnKit)
        return;
    SendBonkKitAt(m_player, s_spawnKit, mob->GetPositionX(), mob->GetPositionY(), mob->GetPositionZ(), mob->GetOrientation(),
        BONK_SPAWN_LOOK_HOLD_MS);
    SendBonkKitAt(m_player, s_spawnKit, x, y, z, mob->GetOrientation(), BONK_SPAWN_LOOK_HOLD_MS);
}

void BonkRun::UpdateCrowd(uint32 diff)
{
    std::vector<Creature*> stuck;
    m_crowd.Update(diff, m_player, m_mobs, m_perched, stuck);
    for (Creature* mob : stuck)
        OnMobStuck(mob);
}

void BonkRun::UpdateStragglers(uint32 diff)
{
    m_stragglerTimer += diff;
    if (m_stragglerTimer < BONK_STRAGGLER_TICK_MS)
        return;
    m_stragglerTimer = 0;

    uint32 const now = m_elapsedMs;
    m_packSpots.erase(std::remove_if(m_packSpots.begin(), m_packSpots.end(), [now](PackSpot const& spot) { return spot.untilMs <= now; }), m_packSpots.end());

    Map* map = m_player->GetMap();
    float const forward = GetForwardAngle();
    std::map<ObjectGuid, uint32> farSince;
    std::vector<std::pair<Creature*, uint32>> bosses, waiting;
    for (ObjectGuid const& guid : m_mobs)
    {
        Creature* mob = map->GetCreature(guid);
        if (!mob || !mob->IsAlive() || mob->HasCreatureState(CSTATE_DESPAWNING) || mob->IsWithinDistInMap(m_player, BONK_STRAY_DISTANCE) ||
            IsAhead(mob->GetPositionX(), mob->GetPositionY(), forward))
            continue;
        if (IsMiniEventTarget(guid))
            continue;
        if (BonkMobAI const* ward = dynamic_cast<BonkMobAI const*>(mob->AI()))
            if (ward->IsWard())
                continue;
        auto const itr = m_farSince.find(guid);
        uint32 const since = itr != m_farSince.end() ? itr->second : now;
        farSince[guid] = since;
        if (now - since < BONK_STRAY_MS)
            continue;

        BonkMobAI const* ai = dynamic_cast<BonkMobAI const*>(mob->AI());
        if (ai && ai->GetKind() == BONK_SPAWN_NORMAL && !ai->IsFlyer() && !IsInRoster(ai->GetArchetype()))
        {
            farSince.erase(guid);
            mob->DespawnOrUnsummon();
            continue;
        }
        bool const boss = ai && (ai->GetKind() == BONK_SPAWN_BOSS || ai->GetKind() == BONK_SPAWN_MINIBOSS);
        (boss ? bosses : waiting).emplace_back(mob, since + BONK_STRAY_MS);
    }
    m_farSince = std::move(farSince);
    if (bosses.empty() && waiting.empty())
        return;

    float heading;
    if (!GetHeading(heading))
    {
        waiting.insert(waiting.end(), bosses.begin(), bosses.end());
        for (auto const& itr : waiting)
        {
            float x, y, z;
            if (now - itr.second >= BONK_STRAGGLER_SIDE_MS && FindMobPosition(x, y, z, m_map.spawnMinDistance, m_map.spawnMaxDistance))
                MoveMob(itr.first, x, y, z);
        }
        return;
    }

    uint32 ahead = CountAhead(heading);
    uint32 const cap = GetFrontCap();

    for (auto const& itr : bosses)
    {
        if (ahead < cap && PlacePack({ itr.first }, heading))
            ++ahead;
        else
            PlaceAside(itr.first, heading);
    }

    std::stable_sort(waiting.begin(), waiting.end(), [](auto const& a, auto const& b) { return a.second < b.second; });
    size_t next = 0;
    while (next < waiting.size())
    {
        uint32 const room = cap > ahead ? cap - ahead : 0;
        uint32 const left = uint32(waiting.size() - next);
        uint32 const size = std::min({ urand(BONK_PACK_MIN, BONK_PACK_MAX), left, room });
        bool const waitedLong = now - waiting[next].second >= BONK_PACK_WAIT_MS;
        if (!size || (size < BONK_PACK_MIN && !waitedLong))
            break;

        std::vector<Creature*> pack;
        for (uint32 i = 0; i < size; ++i)
            pack.push_back(waiting[next + i].first);
        if (!PlacePack(pack, heading))
            break;
        next += size;
        ahead += size;
    }

    for (size_t i = next; i < waiting.size(); ++i)
        if (now - waiting[i].second >= BONK_STRAGGLER_SIDE_MS)
            PlaceAside(waiting[i].first, heading);
}

bool BonkRun::PlacePack(std::vector<Creature*> const& pack, float heading)
{
    Map* map = m_player->GetMap();
    float const playerX = m_player->GetPositionX();
    float const playerY = m_player->GetPositionY();

    std::vector<float> const crowd = CountSectorCrowd();
    float const half = M_PI_F / float(BONK_SPAWN_SECTORS);
    for (uint32 attempt = 0; attempt < 8; ++attempt)
    {
        float const distance = attempt < BONK_FAR_TRIES ? frand(BONK_FAR_MIN_DISTANCE, BONK_FAR_MAX_DISTANCE) :
            frand(m_map.spawnMinDistance, m_map.spawnMaxDistance);
        int32 const sector = PickSector(crowd, true);
        float const angle = sector >= 0 ? GetSectorAngle(uint32(sector)) + frand(-half, half) : heading + frand(-BONK_FRONT_ARC, BONK_FRONT_ARC);
        float centreX, centreY, centreZ;
        if (!FindSpawnPositionAt(angle, distance, centreX, centreY, centreZ))
            continue;

        auto const within = [centreX, centreY](float x, float y, float range)
        {
            return (x - centreX) * (x - centreX) + (y - centreY) * (y - centreY) < range * range;
        };
        if (std::any_of(m_packSpots.begin(), m_packSpots.end(), [&within](PackSpot const& spot) { return within(spot.x, spot.y, BONK_PACK_SPACING); }))
            continue;
        bool crowded = false;
        for (ObjectGuid const& guid : m_mobs)
            if (Creature const* other = map->GetCreature(guid))
                if (other->IsAlive() && std::find(pack.begin(), pack.end(), other) == pack.end() &&
                    within(other->GetPositionX(), other->GetPositionY(), BONK_PACK_CLEARANCE))
                {
                    crowded = true;
                    break;
                }
        if (crowded)
            continue;

        for (size_t i = 0; i < pack.size(); ++i)
        {
            float x = centreX, y = centreY, z = centreZ;
            if (i)
            {
                float const offsetAngle = frand(0.0f, 2.0f * M_PI_F);
                float const offset = frand(1.0f, BONK_PACK_RADIUS);
                float const memberX = centreX + offset * std::cos(offsetAngle);
                float const memberY = centreY + offset * std::sin(offsetAngle);
                float const angle = std::atan2(memberY - playerY, memberX - playerX);
                float const distance = std::sqrt((memberX - playerX) * (memberX - playerX) + (memberY - playerY) * (memberY - playerY));
                if (!FindSpawnPositionAt(angle, distance, x, y, z))
                {
                    x = centreX;
                    y = centreY;
                    z = centreZ;
                }
            }
            MoveMob(pack[i], x, y, z);
        }

        m_packSpots.push_back({ centreX, centreY, m_elapsedMs + BONK_PACK_SPOT_MS });
        return true;
    }
    return false;
}

bool BonkRun::PlaceAside(Creature* mob, float heading)
{
    for (uint32 attempt = 0; attempt < 10; ++attempt)
    {
        float const side = urand(0, 1) ? 1.0f : -1.0f;
        float const angle = heading + side * frand(BONK_SIDE_MIN_ANGLE, BONK_SIDE_MAX_ANGLE);
        float x, y, z;
        if (FindSpawnPositionAt(angle, frand(m_map.spawnMinDistance, m_map.spawnMaxDistance), x, y, z))
        {
            MoveMob(mob, x, y, z);
            return true;
        }
    }
    return false;
}

void BonkRun::MoveMob(Creature* mob, float x, float y, float z)
{
    float const facing = std::atan2(m_player->GetPositionY() - y, m_player->GetPositionX() - x);
    ShowTeleportFlash(mob, x, y, z);
    mob->NearTeleportTo(x, y, z, facing);
    if (BonkMobAI* ai = dynamic_cast<BonkMobAI*>(mob->AI()))
        ai->Arrive(false);
}

float BonkRun::GetSpawnHealthUncapped(BonkSpawnKind kind, BonkArchetype archetype, float creatureMultiplier) const
{
    uint32 const level = std::min(GetMobLevel() + GetKindLevelBonus(kind), 63u);
    float const archetypeHealth = kind == BONK_SPAWN_NORMAL ? sBonkMgr.GetArchetype(archetype).healthMultiplier : 1.0f;
    return std::max(1.0f, GetMobHealth(level) * GetStageHealthMultiplier() * m_map.healthMultiplier * creatureMultiplier * archetypeHealth *
        GetCrowdOverflow() * GetKindHealth(kind) * GetTierKindHealth(kind) * GetScalingNow().health * GetCoopHealthScale(kind));
}

void BonkRun::NotifyArrived(Creature* mob) const
{
    for (Player* member : BonkCoop::RunGroupOf(m_player))
        if (BonkPlayer* bonk = member->GetBonkPlayer())
            bonk->Notify(BONK_STRING_ARRIVED, { bonk->GetLocalName(mob) });
}

uint32 BonkRun::GetCoopBossCount() const
{
    uint32 const counts[] = { 1, 1, 2, 2, 3 };
    return counts[std::min(m_coopPlayers, 4u)];
}

bool BonkRun::OnStageBossKilled(Creature* mob)
{
    auto const found = std::find(m_stageBosses.begin(), m_stageBosses.end(), mob->GetObjectGuid());
    if (found == m_stageBosses.end())
        return false;
    m_stageBosses.erase(found);
    for (ObjectGuid const& guid : m_stageBosses)
        if (Creature* other = m_player->GetMap()->GetCreature(guid))
            if (other->IsAlive())
            {
                m_bossGuid = guid;
                return false;
            }
    return true;
}

float BonkRun::GetCoopHealthScale(BonkSpawnKind kind) const
{
    if (kind == BONK_SPAWN_BOSS)
        return 1.0f + BONK_COOP_BOSS_HEALTH_PER_PLAYER * float(m_coopPlayers - 1);
    return float(m_coopPlayers) / GetCoopCrowd();
}

float BonkRun::GetCoopSpawnShare() const
{
    if (m_coopPlayers <= 1)
        return 1.0f;
    if (!BonkCoop::InGroupRun(m_player))
        return GetCoopCrowd() / float(m_coopPlayers);
    if (!m_player->IsAlive())
        return 0.0f;
    return GetCoopCrowd() / float(BonkCoop::StandingCount(m_player));
}

float BonkRun::GetCoopCrowd() const
{
    return BONK_COOP_CROWD[std::min(m_coopPlayers, 4u)];
}

void BonkRun::SetCoopPlayers(uint32 players, bool sharedPause, bool sharedXp)
{
    m_coopPlayers = std::max(1u, players);
    m_coopNoPause = !sharedPause;
    m_coopOwnXp = !sharedXp;
    ApplyPause(WantsPause());
    if (m_player->GetBonkPlayer()->IsAddonReady())
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteCoopNoPause(data, m_coopNoPause);
        m_player->GetSession()->SendPacket(&data);
    }
    sLog.Player(m_player->GetSession(), LOG_LEVELUP, LOG_LVL_BASIC,
        "Bonk coop: %s runs with %u players (stage %u, %s, %s, class %u, %s, pause %s, xp %s)", m_player->GetName(), m_coopPlayers, m_stage,
        m_map.key.c_str(), m_tier.key.c_str(), uint32(m_player->GetClass()), IsCoopGuest() ? "guest" : "host",
        sharedPause ? "shared" : "none", sharedXp ? "shared" : "individual");
}

uint32 BonkRun::GetSpawnHealth(BonkSpawnKind kind, BonkArchetype archetype, float creatureMultiplier) const
{
    return uint32(std::min(BONK_MAX_MOB_HEALTH, GetSpawnHealthUncapped(kind, archetype, creatureMultiplier)));
}

float BonkRun::GetTierKindHealth(BonkSpawnKind kind) const
{
    return kind == BONK_SPAWN_BOSS ? m_tier.bossHealthMultiplier * m_levelRow.bossHealth : kind == BONK_SPAWN_MINIBOSS ? m_tier.minibossHealthMultiplier : 1.0f;
}

float BonkRun::GetTierKindDamage(BonkSpawnKind kind) const
{
    return kind == BONK_SPAWN_BOSS ? m_levelRow.bossDamage : kind == BONK_SPAWN_MINIBOSS ? m_tier.minibossDamageMultiplier : 1.0f;
}

float BonkRun::GetProcBaseHealth() const
{
    return GetMobHealth(GetMobLevel()) * sBonkMgr.GetArchetype(BONK_ARCHETYPE_GRUNT).healthMultiplier * GetScalingNow().health;
}

std::vector<std::string> BonkRun::DescribeScaling() const
{
    std::vector<std::string> lines;
    char line[256];
    uint32 const grunt = GetSpawnHealth(BONK_SPAWN_NORMAL, BONK_ARCHETYPE_GRUNT, 1.0f);
    uint32 const bruiser = GetSpawnHealth(BONK_SPAWN_NORMAL, BONK_ARCHETYPE_BRUISER, 1.0f);
    uint32 const elite = GetSpawnHealth(BONK_SPAWN_ELITE, BONK_ARCHETYPE_GRUNT, 1.0f);
    snprintf(line, sizeof(line), "Minute %.1f, level %u, stage %u: grunt %u health (x%.2f its level's base), bruiser %u, elite %u; %u alive, %u wanted.",
        GetRunMinutes(), m_player->GetLevel(), m_stage, grunt, grunt / std::max(1.0f, GetMobHealth(GetMobLevel())), bruiser, elite,
        uint32(m_mobs.size()), GetSpawnTarget());
    lines.push_back(line);
    BonkScalingPoint const scaling = GetScalingNow();
    snprintf(line, sizeof(line), "Block \"%s\" (from %u s); a grunt hit takes %.1f%% of %.0f base health (%.0f before armor); toughness x%.2f.",
        GetWave().name.c_str(), GetWave().startSecond, scaling.hitShare * 100.0f * GetStageDamageMultiplier(), GetHeroBaseHealth(),
        GetHeroBaseHealth() * scaling.hitShare * GetStageDamageMultiplier(), scaling.health);
    lines.push_back(line);

    for (OwnedWeapon const& owned : m_weapons)
    {
        SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(owned.weapon.spellId);
        float const hit = std::max(1.0f, GetWeaponDamage(owned) * GetDamageMultiplier(spellInfo, nullptr));
        snprintf(line, sizeof(line), "%s rank %u: %.0f a hit (+%.0f%% from ranks) every %.1f s; grunt %.0f hits, bruiser %.0f, elite %.0f.",
            owned.weapon.name.c_str(), owned.rank, hit, owned.damageBonus, GetWeaponCooldown(owned) / float(IN_MILLISECONDS),
            std::ceil(grunt / hit), std::ceil(bruiser / hit), std::ceil(elite / hit));
        lines.push_back(line);
    }
    return lines;
}

uint32 BonkRun::GetMobLevel() const
{
    int32 const level = int32(m_player->GetLevel()) + m_map.levelOffset;
    return uint32(std::max(1, std::min(level, 63)));
}

float BonkRun::GetMobHealth(uint32 level) const
{
    uint32 const tableLevel = std::min(level, BONK_MOB_HEALTH_TABLE_LEVELS);
    CreatureClassLevelStats const* stats = sObjectMgr.GetCreatureClassLevelStats(CLASS_WARRIOR, tableLevel);
    float const tableHealth = stats ? float(stats->health) : 40.0f * tableLevel;
    uint32 const levelsPastTable = level - tableLevel;
    return tableHealth * (1.0f + BONK_MOB_HEALTH_LEVEL_GROWTH * float(levelsPastTable));
}

float BonkRun::StageHealthScale(BonkTier const& tier, BonkLevel const& level, uint32 stage)
{
    float const stages = float(stage - 1);
    return tier.healthMultiplier * level.health * (1.0f + tier.stageHealthGrowth * stages + tier.stageHealthAccel * stages * std::max(0.0f, stages - 1.0f));
}

float BonkRun::StageDamageScale(BonkTier const& tier, BonkLevel const& level, uint32 stage)
{
    float const stages = float(stage - 1);
    return tier.damageMultiplier * level.damage * (1.0f + tier.stageDamageGrowth * stages + tier.stageDamageAccel * stages * std::max(0.0f, stages - 1.0f));
}

float BonkRun::GetStageHealthMultiplier() const
{
    return StageHealthScale(m_tier, m_levelRow, std::min(m_stage, m_tier.stages)) * (1.0f + m_bonuses.enemyHealth / 100.0f) * (IsChallenge() ? BONK_DUNGEON_HEALTH : 1.0f);
}

float BonkRun::GetStageDamageMultiplier() const
{
    return StageDamageScale(m_tier, m_levelRow, std::min(m_stage, m_tier.stages)) * (1.0f + m_bonuses.enemyDamage / 100.0f) * (IsChallenge() ? BONK_DUNGEON_DAMAGE : 1.0f);
}


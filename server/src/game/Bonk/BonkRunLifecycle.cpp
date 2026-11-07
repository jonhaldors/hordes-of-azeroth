#include "BonkRunInternal.h"
#include "BonkIntegrity.h"

BonkRun::BonkRun(Player* player, BonkTier const& tier, BonkRunChoice const& choice) : m_player(player), m_tier(tier),
    m_bonuses(player->GetBonkPlayer()->GetRunBonuses()), m_mastery(player->GetBonkPlayer()->GetMasteryBonuses())
{
    BonkMap const* dungeon = choice.dungeon;
    m_dungeonId = dungeon && !choice.invade ? dungeon->id : 0;
    m_invaderId = dungeon && choice.invade ? dungeon->id : 0;
    m_startMapId = choice.startMap && !m_dungeonId ? choice.startMap->id : 0;
    m_difficultyLevel = tier.HasLevel(choice.level) ? choice.level : tier.firstLevel;
    m_coopNoPause = choice.noPause;
    m_levelRow = sBonkMgr.GetLevel(tier, GetBandLevel());
    uint32 const classMask = player->GetClassMask();
    for (bool const ownClass : { true, false })
        for (auto const& itr : sBonkMgr.GetWeapons())
            if (bool(itr.second.classMask & classMask) == ownClass)
                m_spellRoots.emplace(itr.second.spellId, BonkMastery::GetRootWeapon(itr.first));

    m_rerolls = m_bonuses.rerolls;
    m_glyphRerolls = m_bonuses.glyphRerolls;
    m_banishes = m_bonuses.banishes;
    m_skips = m_bonuses.skips;
    m_revives = m_bonuses.revives;
    m_coins = m_bonuses.startCoins;
    m_valorEarned = m_coins;
    m_levelBestAtStart = player->GetBonkPlayer()->GetBestLevel();
}

std::string BonkRun::GetString(BonkString id, std::vector<std::string> const& args) const
{
    return m_player->GetBonkPlayer()->GetString(id, args);
}

std::string BonkRun::Localize(BonkTextField field, uint32 id, std::string const& english) const
{
    return m_player->GetBonkPlayer()->Localize(field, id, english);
}

LocaleConstant BonkRun::GetLocale() const
{
    return m_player->GetBonkPlayer()->GetLocale();
}

bool BonkRun::Begin(std::string& error)
{
    BonkStats::Reset(m_player->GetObjectGuid());

    BonkMap const* first = nullptr;
    if (IsCoopGuest())
    {
        Player* host = ObjectAccessor::FindPlayerNotInWorld(m_coopHost);
        BonkRun const* hostRun = host ? host->GetBonkPlayer()->GetRun() : nullptr;
        if (!hostRun || hostRun->IsOver())
        {
            error = m_player->GetBonkPlayer()->GetString(BONK_STRING_COOP_HOST_RUN_ENDED);
            return false;
        }
        first = &hostRun->GetStageMap();
    }
    else
        first = ChooseNextMap();
    if (!first)
    {
        error = GetString(BONK_STRING_NO_MAPS_ARE_SET_UP, { Localize(BONK_FIELD_TIER_NAME, m_tier.id, m_tier.name) });
        return false;
    }
    m_map = *first;
    ApplyInvader();
    ApplyDifficultyGold();
    BringBossEarlier();
    if (!m_sandbox)
        LogLoadout();
    if (!m_sandbox && !IsCoopGuest())
        BonkCoop::NoteHostRun(m_player, DescribeForLobby());

    if (m_player->IsGameMaster())
        m_player->SetGameMaster(false);
    m_player->SetCheatGod(m_player->GetBonkPlayer()->IsTestGod());
    SetMovementImmunity(m_player, true);

    m_player->GetBonkPlayer()->ResetCharacter();
    m_player->RemoveAurasDueToSpell(BONK_SPELL_MOVE_SPEED);
    m_player->RemoveAurasDueToSpell(BONK_SPELL_MAX_HEALTH);
    m_player->RemoveAurasDueToSpell(BONK_SPELL_DODGE);
    m_player->RemoveAurasDueToSpell(BONK_SPELL_DARKMOON_SURGE);
    m_player->RemoveAurasDueToSpell(BONK_SPELL_CARD_HASTE);
    m_player->RemoveAurasDueToSpell(BONK_SPELL_CARD_SWIFT);
    m_player->RemoveAurasDueToSpell(BONK_SPELL_CARD_IMMUNE);
    m_player->RemoveAurasDueToSpell(BONK_SPELL_CARD_THORNS);
    m_player->RemoveAurasDueToSpell(BONK_SPELL_DARK_PACT_AURA);
    m_player->RemoveAurasDueToSpell(BONK_SPELL_SOUL_HARVEST_AURA);
    m_player->RemoveAurasDueToSpell(BONK_SPELL_GLYPH_HASTE_AURA);
    m_player->RemoveAurasDueToSpell(BONK_SPELL_ICE_BLOCK_AURA);
    m_player->RemoveAurasDueToSpell(BONK_SPELL_NOMAD_AURA);
    m_player->RemoveAurasDueToSpell(BONK_SPELL_KILL_POWER_AURA);
    m_player->RemoveAurasDueToSpell(BONK_SPELL_UNHIT_POWER_AURA);

    if (!(m_sandbox ? TeleportToSandbox(error) : TeleportToStage(m_map, error)))
        return false;
    BeginHardcoreRun();
    return true;
}

std::string BonkRun::DescribeForLobby() const
{
    std::string text = m_player->GetBonkPlayer()->GetLevelName(m_difficultyLevel);
    if (IsDungeon())
        if (BonkMap const* dungeon = sBonkMgr.GetMap(m_dungeonId))
            text += " \xC2\xB7 " + Localize(BONK_FIELD_MAP_NAME, dungeon->id, dungeon->name);
    if (IsInvasion())
        text += " \xC2\xB7 " + GetString(BONK_STRING_LOBBY_INVASION);
    return text;
}

BonkMap const* BonkRun::ChooseNextMap()
{
    if (m_sandbox)
        return GetSandboxMap();
    if (m_dungeonId)
        return sBonkMgr.GetMap(m_dungeonId);

    std::vector<BonkMap const*> pool;
    for (uint32 id : m_tier.mapIds)
        if (BonkMap const* map = sBonkMgr.GetMap(id))
            if (!map->creatures.empty())
                pool.push_back(map);

    if (pool.empty())
        return nullptr;

    if (m_startMapId && m_playedMaps.empty())
        if (BonkMap const* start = sBonkMgr.GetMap(m_startMapId))
        {
            m_playedMaps.insert(start->id);
            return start;
        }

    std::vector<BonkMap const*> candidates;
    for (BonkMap const* map : pool)
        if (!m_playedMaps.count(map->id))
            candidates.push_back(map);

    if (candidates.empty())
    {
        m_playedMaps.clear();
        for (BonkMap const* map : pool)
            if (pool.size() == 1 || map->id != m_map.id)
                candidates.push_back(map);
    }

    BonkMap const* map = candidates[urand(0, uint32(candidates.size() - 1))];
    m_playedMaps.insert(map->id);
    return map;
}

void BonkRun::ApplyDifficultyGold()
{
    bool const visiting = !IsDungeon() && m_map.tierId != m_tier.id;
    if (!IsDungeon() && !visiting)
        return;
    uint32 goldPerKill = 0;
    uint32 stageGold = 0;
    int32 levelOffset = 0;
    uint32 zones = 0;
    for (auto const& itr : sBonkMgr.GetMaps())
    {
        BonkMap const& zone = itr.second;
        if (zone.tierId != m_tier.id || zone.type != BONK_MAP_OPEN)
            continue;
        goldPerKill += zone.goldPerKill;
        stageGold += zone.stageGold;
        levelOffset += zone.levelOffset;
        ++zones;
    }
    if (!zones)
        return;
    m_map.goldPerKill = (goldPerKill + zones / 2) / zones;
    m_map.stageGold = (stageGold + zones / 2) / zones;
    if (visiting && !m_invaderId && !m_sandbox)
        m_map.levelOffset = levelOffset / int32(zones);
}

void BonkRun::ApplyInvader()
{
    BonkMap const* invader = m_invaderId ? sBonkMgr.GetMap(m_invaderId) : nullptr;
    if (!invader)
        return;
    m_map.creatures = invader->creatures;
    m_map.levelOffset = invader->levelOffset;
}

namespace
{
    bool CanWalkFromAnchor(BonkMap const& map, TerrainInfo* terrain, float x, float y, float z);
}

void BonkRun::LearnStarts(std::vector<BonkSpot> const& spots)
{
    if (spots.empty() || !m_player->IsInWorld())
        return;
    TerrainInfo* terrain = sTerrainMgr.LoadTerrain(m_map.mapId);
    float const edge = m_map.type == BONK_MAP_OPEN ? BONK_START_EDGE : BONK_START_EDGE_ENCLOSED;
    for (BonkSpot const& spot : spots)
    {
        if (m_map.type == BONK_MAP_OPEN && !terrain->IsOutdoors(spot.x, spot.y, spot.z + 1.0f))
            continue;
        bool inside = true;
        for (uint32 i = 0; i < 8 && inside; ++i)
        {
            float const angle = i * M_PI_F / 4.0f;
            float const x = spot.x + edge * std::cos(angle);
            float const y = spot.y + edge * std::sin(angle);
            float const z = m_player->GetMap()->GetHeight(x, y, spot.z + 20.0f, true, 60.0f);
            if (z <= INVALID_HEIGHT || (m_map.zoneId && terrain->GetZoneId(x, y, z) != m_map.zoneId) || terrain->IsInWater(x, y, z + 1.0f))
                inside = false;
        }
        if (!inside || (m_map.type == BONK_MAP_OPEN && !CanWalkFromAnchor(m_map, terrain, spot.x, spot.y, spot.z)))
            continue;
        BonkMapStart start;
        start.x = spot.x;
        start.y = spot.y;
        start.z = spot.z;
        sBonkMgr.AddMapStart(m_map.id, start, BONK_START_SPREAD, BONK_START_MAX_LEARNED);
    }
}

namespace
{
    bool IsOpenGround(TerrainInfo const* terrain, uint32 zoneId, float x, float y, float z)
    {
        if (terrain->GetZoneId(x, y, z) != zoneId || terrain->IsInWater(x, y, z + 1.0f) || !terrain->IsOutdoors(x, y, z + 1.0f))
            return false;
        float const top = terrain->GetHeightStatic(x, y, z + 50.0f, true, 60.0f);
        return top <= z + BONK_ZONE_START_CLEAR;
    }

    bool HasWorldSpawnsNear(uint32 mapId, float x, float y)
    {
        CellPair const center = MaNGOS::ComputeCellPair(x, y);
        int32 const last = int32(TOTAL_NUMBER_OF_CELLS_PER_MAP) - 1;
        size_t spawns = 0;
        std::shared_lock<std::shared_timed_mutex> lock(sObjectMgr.GetCellLoadingObjectsMutex());
        for (int32 cx = std::max(0, int32(center.x_coord) - BONK_ZONE_START_SPAWN_CELLS); cx <= std::min(last, int32(center.x_coord) + BONK_ZONE_START_SPAWN_CELLS); ++cx)
            for (int32 cy = std::max(0, int32(center.y_coord) - BONK_ZONE_START_SPAWN_CELLS); cy <= std::min(last, int32(center.y_coord) + BONK_ZONE_START_SPAWN_CELLS); ++cy)
                if (CellObjectGuids const* guids = sObjectMgr.GetCellObjectGuids(mapId, uint32(cy) * TOTAL_NUMBER_OF_CELLS_PER_MAP + uint32(cx)))
                    spawns += guids->creatures.size() + guids->gameobjects.size();
        return spawns >= BONK_ZONE_START_SPAWNS;
    }

    void LoadGridsBetween(TerrainInfo* terrain, float fromX, float fromY, float toX, float toY)
    {
        float const step = SIZE_OF_GRIDS / 2.0f;
        for (float gx = std::min(fromX, toX) - step; gx <= std::max(fromX, toX) + step; gx += step)
            for (float gy = std::min(fromY, toY) - step; gy <= std::max(fromY, toY) + step; gy += step)
                terrain->GetHeightStatic(gx, gy, MAX_HEIGHT, false);
    }

    struct StartQuery
    {
        dtNavMesh const* mesh = nullptr;
        dtNavMeshQuery* query = nullptr;
    };

    dtNavMeshQuery const* GetStartQuery(uint32 mapId)
    {
        dtNavMesh const* mesh = MMAP::MMapFactory::createOrGetMMapManager()->GetNavMesh(mapId);
        if (!mesh)
            return nullptr;
        thread_local std::map<uint32, StartQuery> queries;
        StartQuery& entry = queries[mapId];
        if (entry.mesh == mesh)
            return entry.query;
        if (!entry.query)
            entry.query = dtAllocNavMeshQuery();
        entry.mesh = nullptr;
        if (!entry.query || dtStatusFailed(entry.query->init(mesh, BONK_START_PATH_NODES)))
            return nullptr;
        entry.mesh = mesh;
        return entry.query;
    }

    bool CanWalkFromAnchor(BonkMap const& map, TerrainInfo* terrain, float x, float y, float z)
    {
        LoadGridsBetween(terrain, map.x, map.y, x, y);
        dtNavMeshQuery const* query = GetStartQuery(map.mapId);
        if (!query)
            return true;

        dtQueryFilter filter;
        filter.setIncludeFlags(NAV_GROUND | NAV_WATER);
        float const anchor[3] = { map.y, map.z, map.x };
        float const spot[3] = { y, z, x };
        float anchorNear[3] = { 0.0f, 0.0f, 0.0f };
        float spotNear[3] = { 0.0f, 0.0f, 0.0f };
        dtPolyRef const anchorRef = PathInfo::FindWalkPoly(query, anchor, filter, anchorNear, BONK_START_POLY_REACH);
        if (!anchorRef)
            return true;
        dtPolyRef const spotRef = PathInfo::FindWalkPoly(query, spot, filter, spotNear, BONK_START_POLY_REACH);
        if (!spotRef)
            return false;

        dtPolyRef path[BONK_START_PATH_POLYS];
        int count = 0;
        dtStatus const status = query->findPath(anchorRef, spotRef, anchorNear, spotNear, &filter, path, &count, BONK_START_PATH_POLYS);
        return dtStatusSucceed(status) && count > 0 && path[count - 1] == spotRef;
    }

    bool FindZoneStart(BonkMap const& map, float& x, float& y, float& z)
    {
        if (!map.zoneId || map.type != BONK_MAP_OPEN)
            return false;
        TerrainInfo* terrain = sTerrainMgr.LoadTerrain(map.mapId);
        for (uint32 attempt = 0; attempt < BONK_ZONE_START_TRIES; ++attempt)
        {
            float px = frand(BONK_ZONE_START_MARGIN, 100.0f - BONK_ZONE_START_MARGIN);
            float py = frand(BONK_ZONE_START_MARGIN, 100.0f - BONK_ZONE_START_MARGIN);
            if (!Zone2MapCoordinates(px, py, map.zoneId))
                return false;
            if (!HasWorldSpawnsNear(map.mapId, px, py))
                continue;
            float const pz = terrain->GetHeightStatic(px, py, MAX_HEIGHT, false);
            if (pz <= INVALID_HEIGHT || !IsOpenGround(terrain, map.zoneId, px, py, pz))
                continue;
            bool flat = true;
            for (uint32 i = 0; i < 8 && flat; ++i)
            {
                float const angle = i * M_PI_F / 4.0f;
                float const rx = px + BONK_START_EDGE * std::cos(angle);
                float const ry = py + BONK_START_EDGE * std::sin(angle);
                float const rz = terrain->GetHeightStatic(rx, ry, pz + 40.0f, false, 80.0f);
                flat = rz > INVALID_HEIGHT && std::fabs(rz - pz) <= BONK_ZONE_START_FLAT &&
                    terrain->GetZoneId(rx, ry, rz) == map.zoneId && !terrain->IsInWater(rx, ry, rz + 1.0f);
            }
            if (!flat || !CanWalkFromAnchor(map, terrain, px, py, pz))
                continue;
            x = px;
            y = py;
            z = pz;
            return true;
        }
        return false;
    }

    std::vector<BonkMapStart const*> GetReachableStarts(BonkMap const& map, std::vector<BonkMapStart> const& starts)
    {
        std::vector<BonkMapStart const*> reachable;
        TerrainInfo* terrain = sTerrainMgr.LoadTerrain(map.mapId);
        for (BonkMapStart const& start : starts)
            if (map.type != BONK_MAP_OPEN || (HasWorldSpawnsNear(map.mapId, start.x, start.y) && CanWalkFromAnchor(map, terrain, start.x, start.y, start.z)))
                reachable.push_back(&start);
        return reachable;
    }
}

bool BonkRun::PlaceNearHost(float& x, float& y, float& z, float& o) const
{
    Player* host = ObjectAccessor::FindPlayerNotInWorld(m_coopHost);
    BonkRun const* hostRun = host ? host->GetBonkPlayer()->GetRun() : nullptr;
    if (!hostRun)
        return false;
    float hostX, hostY, hostZ;
    hostRun->GetStageStart(hostX, hostY, hostZ);
    if (hostX == 0.0f && hostY == 0.0f)
        return false;
    float const angle = frand(0.0f, 2.0f * M_PI_F);
    float const distance = frand(BONK_COOP_FOLLOW_MIN, BONK_COOP_FOLLOW_MAX);
    x = hostX + std::cos(angle) * distance;
    y = hostY + std::sin(angle) * distance;
    bool const hostOnStage = host->GetMapId() == hostRun->m_map.mapId && !host->IsBeingTeleported();
    z = hostOnStage ? host->GetMap()->GetHeight(x, y, hostZ + BONK_COOP_PLACE_HEIGHT, true, 2.0f * BONK_COOP_PLACE_HEIGHT) : INVALID_HEIGHT;
    if (z <= INVALID_HEIGHT || std::fabs(z - hostZ) > BONK_COOP_PLACE_HEIGHT)
    {
        x = hostX;
        y = hostY;
        z = hostZ;
    }
    z += BONK_COOP_PLACE_LIFT;
    o = std::atan2(hostY - y, hostX - x);
    if (o < 0.0f)
        o += 2.0f * M_PI_F;
    return true;
}

bool BonkRun::TeleportToStage(BonkMap const& map, std::string& error)
{
    float x = map.x, y = map.y, z = map.z, o = map.o;
    std::vector<BonkMapStart> const starts = sBonkMgr.GetMapStarts(map.id);
    std::vector<BonkMapStart const*> const reachable = GetReachableStarts(map, starts);
    if (IsCoopGuest() && PlaceNearHost(x, y, z, o))
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op: %s placed near the host at %.1f %.1f", m_player->GetName(), x, y);
    else if (FindZoneStart(map, x, y, z))
    {
        z += 0.5f;
        o = std::atan2(map.y - y, map.x - x);
        if (o < 0.0f)
            o += 2.0f * M_PI_F;
    }
    else if (reachable.size() >= BONK_START_MIN_LEARNED)
    {
        std::vector<BonkMapStart const*> away;
        if (m_player->GetMapId() == map.mapId)
            for (BonkMapStart const* start : reachable)
                if (m_player->GetDistance2d(start->x, start->y) > BONK_START_SPREAD)
                    away.push_back(start);
        BonkMapStart const& start = away.empty() ? *reachable[urand(0, uint32(reachable.size()) - 1)] : *away[urand(0, uint32(away.size()) - 1)];
        x = start.x;
        y = start.y;
        z = start.z + 0.5f;
        o = std::atan2(map.y - y, map.x - x);
        if (o < 0.0f)
            o += 2.0f * M_PI_F;
    }

    if (!m_player->TeleportTo(map.mapId, x, y, z, o))
    {
        error = GetString(BONK_STRING_YOU_COULDNT_TRAVEL_TO, { Localize(BONK_FIELD_MAP_NAME, map.id, map.name) });
        return false;
    }

    m_stageX = x;
    m_stageY = y;
    m_stageZ = z;
    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op stage: %s goes to map %u at %.1f %.1f, guest %u", m_player->GetName(), map.mapId, x, y, uint32(IsCoopGuest()));
    m_state = STATE_ENTERING;
    m_enterTimer = 0;
    return true;
}

void BonkRun::Update(uint32 diff)
{
    StressTick const stressTick(*this, diff);
    RefreshGroupEnemies();
    UpdateSky();
    RefreshHeroPositionNow();
    if (m_runXpDirty)
        UpdateRunXp(false);

    if (m_paused)
        HoldAuraTimers(diff);
    RefreshWatchedStats(diff);
    if (m_state == STATE_RUNNING || m_state == STATE_PORTAL)
        UpdateDryGround(diff);

    switch (m_state)
    {
        case STATE_ENTERING:
        {
            if (m_player->GetMapId() == m_map.mapId && !m_player->IsBeingTeleported())
            {
                StartStage();
                return;
            }

            m_enterTimer += diff;
            if (m_enterTimer >= BONK_ENTER_TIMEOUT_MS)
            {
                m_player->GetBonkPlayer()->Notify(BONK_STRING_YOU_COULDNT_TRAVEL_TO, { Localize(BONK_FIELD_MAP_NAME, m_map.id, m_map.name) });
                Exit();
            }
            break;
        }
        case STATE_RUNNING:
            UpdateRunning(diff);
            break;
        case STATE_PORTAL:
        {
            if (!m_player->IsAlive() && !BonkCoop::IsDowned(m_player))
            {
                if (m_revives)
                    Revive();
                else if (!BonkCoop::Down(m_player))
                    Finish(false);
                return;
            }

            UpdateOffers();
            UpdateBoundary(diff);
            UpdateNatives(diff);
            UpdateShield(diff);
            UpdateNecrotic(diff);
            UpdatePools(diff);
            UpdatePowerups(diff, false);
            UpdateOrbs(diff);
            UpdateShards(diff);
            UpdateHeals(diff);

            m_stateTimer += diff;
            if (m_stateTimer >= BONK_STATE_INTERVAL_MS)
            {
                m_stateTimer = 0;
                SendState();

                if (!IsCoopGuest() && !m_player->GetMap()->GetGameObject(m_portalGuid) && !m_player->IsBeingTeleported())
                {
                    float const angle = m_player->GetOrientation();
                    PlacePortal(m_player->GetPositionX() + BONK_PORTAL_DISTANCE * std::cos(angle),
                        m_player->GetPositionY() + BONK_PORTAL_DISTANCE * std::sin(angle), m_player->GetPositionZ());
                }
            }
            break;
        }
        case STATE_ENDING:
            m_endTimer -= int32(diff);
            if (m_endTimer <= 0)
                Exit();
            break;
        case STATE_FINISHED:
            break;
    }
}

void BonkRun::StartStage()
{
    sLog.Player(m_player->GetSession(), LOG_LEVELUP, LOG_LVL_BASIC,
        "Bonk stage: %s starts stage %u at run minute %.2f (stage %u, %s, %s, class %u): level %u, %u kills, took %u damage so far",
        m_player->GetName(), m_stage, GetRunMinutes(), m_stage, m_map.key.c_str(), m_tier.key.c_str(), uint32(m_player->GetClass()),
        m_player->GetLevel() + m_overcapLevel, m_kills, m_damageTaken);
    m_state = STATE_RUNNING;
    m_missedBoss = false;
    if (!IsFinale())
        m_elapsedMs = 0;
    m_nextEvent = 0;
    m_menuOpen = false;
    m_miniEventActive = false;
    m_nextMiniEventMs = 0;
    m_lastMiniEvent = MAX_BONK_MINI_EVENT;
    m_spawnTimer = BONK_FIRST_WAVE_MS;
    m_eliteTimer = int32(BONK_ELITE_RETRY_MS);
    m_waveIndex = 0;
    m_waveEntered = false;
    m_waveWarned = 0;
    m_miniEventSlots = 0;
    m_overtimeWaves = 0;
    m_overtimeTimer = 0;
    m_spawnDamageScale = 1.0f;
    m_overtimeReported = 0;
    if (IsFinale())
        StartEndless();
    m_bossArrivals.clear();
    m_heldEvents.clear();
    RollHidden();
    m_gruntRadius = 0.0f;
    m_bossSpawned = false;
    m_stoneBoss = false;
    m_bossGuid.Clear();
    m_stageBosses.clear();
    m_powerupSpawnTimer = m_map.powerupIntervalSeconds * IN_MILLISECONDS / 2;
    m_nativeTimer = BONK_NATIVE_SWEEP_MS;
    if (m_stage > 1)
        m_rerolls += uint32(GetGlyphValue(BONK_GLYPH_FORESIGHT, 0));
    m_glyphNextChestMs = uint32(GetGlyphValue(BONK_GLYPH_TREASURE, 0));
    m_lastLevel = m_player->GetLevel();
    m_safeX = m_player->GetPositionX();
    m_safeY = m_player->GetPositionY();
    m_safeZ = m_player->GetPositionZ();
    m_lastX = m_safeX;
    m_lastY = m_safeY;
    m_moveX = m_moveY = 0.0f;
    m_headingTimer = 0;
    m_farSince.clear();
    m_crowd.Clear();
    m_packSpots.clear();
    m_sectorBlockedUntil.assign(BONK_SPAWN_SECTORS, 0);
    m_lanes[0] = m_lanes[1] = -1;
    m_ringTimer = m_ringSamples = m_ringBlocked = m_ringClosed = 0;
    m_laneTimer = 0;
    m_perched = false;
    m_perchTimer = 0;
    m_perchChecks = 0;
    m_reachChecks = 0;
    m_perchedMs = 0;
    m_flyerTimer = 0;
    m_hasGround = true;
    m_groundX = m_player->GetPositionX();
    m_groundY = m_player->GetPositionY();
    m_groundZ = m_player->GetPositionZ();
    m_hasDryGround = true;
    m_dryX = m_groundX;
    m_dryY = m_groundY;
    m_dryZ = m_groundZ;
    m_dryGroundTimer = 0;
    m_hazardMs = 0;

    m_player->SetCreatureSummonLimit(BONK_SUMMON_LIMIT);

    if (m_weapons.empty())
    {
        uint32 const classMask = m_player->GetClassMask();
        if (BonkWeapon const* starter = m_player->GetBonkPlayer()->GetStarterWeapon())
        {
            AddWeapon(*starter);
            m_runSpec = starter->spec;
        }

        if (m_weapons.empty())
            for (auto const& itr : sBonkMgr.GetWeapons())
                if (!itr.second.evolvesFrom && (!itr.second.classMask || (itr.second.classMask & classMask)))
                {
                    AddWeapon(itr.second);
                    break;
                }

        SnapshotBroughtGear();

        ApplyPassives();

        if (!m_sandbox)
        {
            GiveStartCard();
            GiveStartLevels();
            if (GetUtility(BONK_UTILITY_START_GLYPH) > 0.0f)
                QueueGlyphPick();
        }
    }
    else
    {
        m_player->SetHealth(m_player->GetMaxHealth());
        m_player->SetPower(POWER_MANA, m_player->GetMaxPower(POWER_MANA));
    }

    UpdateGear();

    RefillShield(GetMaxShield());
    m_shieldIdleMs = 0;
    m_shieldSent = 0;
    m_shieldMaxSent = 0;
    m_shieldSendTimer = 0;
    SetNecroticStacks(0);
    ClearBossPressure();
    DespawnPools();
    DespawnWeaponOrbs();
    DespawnProjectiles();
    DespawnShotSources();
    m_shotSourceTimer = BONK_SHOT_SOURCE_CHECK_MS;
    m_trickShotTimes.clear();
    ClearHunterEvolutions();
    ClearPendingTrapLooks();
    m_pendingCasts.clear();
    m_heldShotSources.clear();
    m_telegraphs.Dismiss(m_player);
    m_player->GetBonkPlayer()->ForgetShownReachRing();
    m_objectives.Clear(m_player);
    m_spawnPoints.Reset(m_player->GetPositionX(), m_player->GetPositionY(), m_player->GetPositionZ());
    ResetShrines();
    ResetVendor();
    DespawnTraps();
    DespawnLandMines();
    DespawnPets();
    m_pendingKeywords.clear();
    m_pendingConsumes.clear();
    m_dyingKeywords.clear();
    m_pendingDotBursts.clear();
    m_volleyHits = 0;
    m_explosiveArrows = 0;
    m_explosiveArrowReadyMs = 0;
    m_dotBurstTimes.clear();
    m_dotBurstLookTimes.clear();
    m_dotStacks.clear();
    m_crowdControl.clear();
    ResetWarriorState();
    ResetMageState();
    ResetShamanState();
    ResetPriestState();
    ResetRogueState();
    ResetPaladinState();
    ResetDruidState();
    m_bleedHeal = 0.0f;
    if (m_player->GetBonkPlayer()->IsAddonReady())
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteMobClear(data);
        m_player->GetSession()->SendPacket(&data);
    }

    if (m_sandbox)
    {
        StartSandbox();
        return;
    }

    SendFullState();
    if (IsFinale())
    {
        m_player->GetBonkPlayer()->Notify(BONK_STRING_FINALE_BEGINS);
        return;
    }
    uint32 const minutes = m_map.durationSeconds / 60;
    uint32 const seconds = m_map.durationSeconds % 60;
    std::string const minuteText = GetString(minutes == 1 ? BONK_STRING_DURATION_MINUTE : BONK_STRING_DURATION_MINUTES, { std::to_string(minutes) });
    std::string const secondText = GetString(seconds == 1 ? BONK_STRING_DURATION_SECOND : BONK_STRING_DURATION_SECONDS, { std::to_string(seconds) });
    std::string const bossIn = !minutes ? secondText : !seconds ? minuteText : GetString(BONK_STRING_DURATION_MINUTES_AND_SECONDS, { minuteText, secondText });
    m_player->GetBonkPlayer()->Notify(BONK_STRING_STAGE_BEGINS, { m_player->GetBonkPlayer()->GetLevelName(m_difficultyLevel), std::to_string(m_stage),
        std::to_string(m_tier.stages), Localize(BONK_FIELD_MAP_NAME, m_map.id, m_map.name), bossIn });
    if (m_stage == 1 && IsMythic() && !m_sandbox && BonkIntegrity::IsServerModified())
        m_player->GetBonkPlayer()->Notify(BONK_STRING_SERVER_CODE_MODIFIED);
}


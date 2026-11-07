#include "BonkRunInternal.h"

void BonkRun::DespawnPaidChests()
{
    Map* map = m_player->FindMap();
    for (auto itr = m_chests.begin(); itr != m_chests.end();)
    {
        GameObject* chest = map ? map->GetGameObject(*itr) : nullptr;
        if (chest && chest->GetEntry() == BONK_GO_CHEST_FREE)
        {
            ++itr;
            continue;
        }
        ForgetChestObjective(*itr);
        m_chestChoices.erase(*itr);
        m_chestOpenedBy.erase(*itr);
        BonkCoop::ForgetHiddenObject(*itr);
        if (chest)
            chest->Delete();
        itr = m_chests.erase(itr);
    }
}

void BonkRun::UpdateObjectives(uint32 diff)
{
    m_spawnPoints.Update(m_player, m_map.zoneId, diff);
    LearnStarts(m_spawnPoints.TakeFresh());
    for (BonkObjective const& gone : m_objectives.Update(m_player, diff))
        m_spawnPoints.Release(gone.x, gone.y);
}

uint32 BonkRun::AddObjective(BonkObjectiveKind kind, float x, float y, float z, std::string const& label, uint32 seconds)
{
    return m_objectives.Add(m_player, kind, x, y, z, label, seconds);
}

void BonkRun::RemoveObjective(uint32 id)
{
    if (BonkObjective const* objective = m_objectives.Get(id))
    {
        if (objective->follows.IsEmpty())
            m_spawnPoints.Release(objective->x, objective->y);
        m_objectives.Remove(m_player, id);
    }
}

bool BonkRun::OffersChest(ObjectGuid chest, Player* opener) const
{
    if (std::find(m_chests.begin(), m_chests.end(), chest) == m_chests.end())
        return false;
    auto opened = m_chestOpenedBy.find(chest);
    return opened == m_chestOpenedBy.end() || !opened->second.count(opener->GetObjectGuid());
}

void BonkRun::RemoveChest(ObjectGuid chest)
{
    ForgetChestObjective(chest);
    m_chests.erase(std::remove(m_chests.begin(), m_chests.end(), chest), m_chests.end());
    m_chestChoices.erase(chest);
    m_chestOpenedBy.erase(chest);
    BonkCoop::ForgetHiddenObject(chest);
}

uint32 BonkRun::OpenChestFor(GameObject* chest, Player* opener)
{
    ObjectGuid const guid = chest->GetObjectGuid();
    auto choices = m_chestChoices.find(guid);
    uint32 const offered = choices != m_chestChoices.end() ? choices->second : uint32(BONK_OFFER_SIZE);

    std::set<ObjectGuid>& opened = m_chestOpenedBy[guid];
    opened.insert(opener->GetObjectGuid());
    auto glow = m_chestGlows.find(guid);
    if (glow != m_chestGlows.end())
        SendBonkAuraGone(opener, glow->second.key);
    bool everyoneOpened = true;
    for (Player* member : BonkCoop::RunGroupOf(m_player))
    {
        BonkRun* run = member->GetBonkPlayer()->GetRun();
        if (run && !run->IsOver() && !opened.count(member->GetObjectGuid()))
            everyoneOpened = false;
    }
    if (everyoneOpened)
    {
        RemoveChest(guid);
        chest->Delete();
        return offered;
    }

    if (opener == m_player)
        ForgetChestObjective(guid);
    BonkCoop::HideObjectFor(guid, opener->GetObjectGuid());
    opener->UpdateVisibilityOf(opener, chest);
    return offered;
}

void BonkRun::UseChest(GameObject* chest)
{
    if (m_state != STATE_RUNNING && m_state != STATE_PORTAL)
        return;

    BonkRun* owner = nullptr;
    for (Player* member : BonkCoop::RunGroupOf(m_player))
        if (BonkRun* run = member->GetBonkPlayer()->GetRun())
            if (run->OffersChest(chest->GetObjectGuid(), m_player))
            {
                owner = run;
                break;
            }
    if (!owner)
        return;
    if (m_missedBoss)
    {
        m_player->GetBonkPlayer()->Notify(BONK_STRING_COOP_CHESTS_CLOSED_AFTER_DOWN);
        return;
    }

    BonkPlayer* bonk = m_player->GetBonkPlayer();
    if (chest->GetEntry() != BONK_GO_CHEST_FREE)
    {
        uint32 const cost = GetChestPrice();
        if (m_coins < cost)
        {
            bonk->Notify(BONK_STRING_THIS_CHEST_COSTS_VALOR_YOU, { std::to_string(cost), std::to_string(m_coins) });
            return;
        }
        if (RollFreeChest())
            bonk->Notify(BONK_STRING_YOUR_ARCANITE_SKELETON_KEY_OPENED);
        else
        {
            m_coins -= cost;
            m_valorOnChests += cost;
            ++m_chestsBought;
        }
        sBonkQuests.OnProgress(m_player, BONK_QUEST_CHESTS_BOUGHT, 0, 1);
    }

    m_pendingChestChoices.push_back(owner->OpenChestFor(chest, m_player));

    UpdateOffers();
    SendState();
}

bool BonkRun::IsOwnPortal(GameObject const* portal) const
{
    return m_state == STATE_PORTAL && portal->GetObjectGuid() == m_portalGuid;
}

void BonkRun::RewardLevelClear()
{
    BonkPlayer* bonk = m_player->GetBonkPlayer();
    uint8 const trainingCap = bonk->GetTrainingRankCap();
    LogLevelClear();
    NotifyBoardMiss();
    if (!m_sandbox)
    {
        BonkPlayer::LevelRun run;
        run.level = m_difficultyLevel;
        run.ms = m_totalMs;
        run.kills = m_kills;
        for (OwnedWeapon const& owned : m_weapons)
            run.damage += GetOwnedSpellTotals(owned).first;
        run.gold = m_goldEarned;
        run.valor = m_valorEarned;
        run.name = m_player->GetName();
        bonk->RecordLevelBest(run);
        BonkCoop::RecordLevelBest(m_player, m_player->GetClass(), run);
        if (IsChallenge())
            sBonkQuests.OnDungeonCleared(m_player, m_dungeonId ? m_dungeonId : m_invaderId);
    }
    if (!bonk->RecordLevelClear(m_difficultyLevel, m_totalMs))
        return;

    uint32 const tickets = GetLevelFirstClearTickets(m_difficultyLevel);
    bonk->AddShards(tickets);
    m_shardsEarned += tickets;
    bonk->Notify(BONK_STRING_FIRST_CLEAR_LEVEL, { bonk->GetLevelName(m_difficultyLevel), FormatBonkShards(tickets, GetLocale()) });

    if (bonk->GetTrainingRankCap() > trainingCap)
        bonk->Notify(BONK_STRING_ACCOUNT_TRAINING_CAN_NOW_GO, { std::to_string(bonk->GetTrainingRankCap()) });
}

void BonkRun::PayFinale()
{
    if (!IsFinale() || m_sandbox)
        return;

    float const minutes = GetEndlessMs() / float(MINUTE * IN_MILLISECONDS);
    uint32 const gold = uint32(m_map.stageGold * BONK_FINALE_GOLD_PER_MINUTE * minutes * m_levelRow.reward);
    uint32 const scrap = uint32(BONK_FINALE_SCRAP_PER_MINUTE * minutes * m_levelRow.reward);
    BonkPlayer* bonk = m_player->GetBonkPlayer();
    GiveGold(gold);
    bonk->AddScrap(scrap);
    bonk->Notify(BONK_STRING_FINALE_PAYS, { FormatTime(GetEndlessMs() / IN_MILLISECONDS), FormatBonkMoney(gold, GetLocale()), std::to_string(scrap) });
    if (!IsMythic())
        return;
    uint32 const score = uint32(GetBandLevel() * minutes);
    LogFinale(minutes, score);
    bonk->RecordFinale(score);
    bonk->RecordFinaleBest(m_difficultyLevel, score, GetEndlessMs() / IN_MILLISECONDS);
    BonkCoop::RecordFinaleBest(m_player, m_player->GetClass(), m_difficultyLevel, score, GetEndlessMs() / IN_MILLISECONDS);
}

BonkMap const* BonkRun::GetNextMap() const
{
    return sBonkMgr.GetMap(m_nextMapId);
}

bool BonkRun::CloseStage()
{
    m_state = STATE_PORTAL;
    m_bossGuid.Clear();
    m_stageBosses.clear();
    m_telegraphs.Clear(m_player);
    EndVoidZones();
    DespawnPools();
    ClearBossPressure();
    RemoveHeroLooks();
    GiveGold(m_map.stageGold * m_stage);
    sBonkQuests.OnProgress(m_player, BONK_QUEST_DARK_FORTUNES, 0, m_bonuses.darkFortunes, true);
    CollectAllOrbs();
    CollectAllGear();
    DespawnShrines();
    DespawnMiniEvent();
    DespawnPaidChests();
    ClearHidden();

    bool const last = m_stage >= m_tier.stages;
    if (last)
    {
        m_victory = true;
        if (!m_sandbox)
            RewardLevelClear();
    }
    return last;
}

void BonkRun::FollowToPortal()
{
    if (m_state != STATE_RUNNING)
        return;
    bool const last = CloseStage();
    BonkPlayer* bonk = m_player->GetBonkPlayer();
    if (!last)
        bonk->Notify(BONK_STRING_CLEARED_STAGE_TAKE_PORTAL, { std::to_string(m_stage) });
    else
        bonk->Notify(m_tier.finale ? BONK_STRING_VICTORY_YOU_CLEARED_TAKE_PORTAL_HOME : BONK_STRING_VICTORY_YOU_CLEARED_TAKE_PORTAL,
            { bonk->GetLevelName(m_difficultyLevel) });
    SendState();
}

void BonkRun::OpenPortal(Creature* boss)
{
    bool const last = CloseStage();
    BonkPlayer* bonk = m_player->GetBonkPlayer();
    BonkMap const* next = !last ? ChooseNextMap() : nullptr;
    m_nextMapId = next ? next->id : last && m_tier.finale ? m_map.id : 0;

    if (boss)
    {
        float const angle = m_player->GetAngle(boss);
        PlacePortal(boss->GetPositionX() + BONK_PORTAL_DISTANCE * std::cos(angle),
            boss->GetPositionY() + BONK_PORTAL_DISTANCE * std::sin(angle), boss->GetPositionZ());
    }
    else
    {
        float const angle = m_player->GetOrientation();
        PlacePortal(m_player->GetPositionX() + BONK_PORTAL_DISTANCE * std::cos(angle),
            m_player->GetPositionY() + BONK_PORTAL_DISTANCE * std::sin(angle), m_player->GetPositionZ());
    }

    if (GameObject const* portal = m_player->GetMap()->GetGameObject(m_portalGuid))
    {
        float const side = m_player->GetAngle(portal) + M_PI_F / 2.0f;
        if (BonkCoop::InGroupRun(m_player))
            BonkCoop::PlaceGroupVaults(m_player, portal, side);
        else
            PlaceVault(portal->GetPositionX() + BONK_VAULT_SIDE * std::cos(side), portal->GetPositionY() + BONK_VAULT_SIDE * std::sin(side),
                portal->GetPositionZ());
        if ((IsMythic() || m_tier.key == "heroic") && (!last || m_tier.finale))
        {
            PlaceEnchanter(portal->GetPositionX() - BONK_VAULT_SIDE * std::cos(side), portal->GetPositionY() - BONK_VAULT_SIDE * std::sin(side),
                portal->GetPositionZ(), m_player->GetAngle(portal) + M_PI_F);
            if (BonkCoop::InGroupRun(m_player))
                BonkCoop::ShareEnchanter(m_player, m_enchanterGuid);
        }
    }

    if (!last)
        bonk->Notify(BONK_STRING_CLEARED_STAGE_TAKE_PORTAL, { std::to_string(m_stage) });
    else
        bonk->Notify(m_tier.finale ? BONK_STRING_VICTORY_YOU_CLEARED_TAKE_PORTAL_HOME : BONK_STRING_VICTORY_YOU_CLEARED_TAKE_PORTAL,
            { bonk->GetLevelName(m_difficultyLevel) });
    SendState();
    if (!IsCoopGuest() && BonkCoop::InGroupRun(m_player))
        BonkCoop::OnHostPortal(m_player, last);
}

void BonkRun::PlacePortal(float x, float y, float baseZ)
{
    float const heroX = m_player->GetPositionX(), heroY = m_player->GetPositionY();
    float heroZ = m_player->GetMap()->GetHeight(heroX, heroY, m_player->GetPositionZ() + 2.0f, true, 2.0f * BONK_SPAWN_MAX_HEIGHT_DIFF);
    if (heroZ <= INVALID_HEIGHT)
        heroZ = m_player->GetPositionZ();
    bool const heroAboveTerrain = IsAboveTerrain(heroX, heroY, heroZ);

    auto walkable = [&](float& spotX, float& spotY, float& spotZ, float heightFrom)
    {
        float const ground = m_player->GetMap()->GetHeight(spotX, spotY, heightFrom + 5.0f, true, 2.0f * BONK_SPAWN_MAX_HEIGHT_DIFF);
        if (ground <= INVALID_HEIGHT || !m_player->IsWithinLOS(spotX, spotY, ground))
            return false;
        if (!HasPortalRoom(spotX, spotY, ground) || (IsAboveTerrain(spotX, spotY, ground) && !heroAboveTerrain))
            return false;
        PathFinder path(m_player);
        path.calculate(Vector3(heroX, heroY, heroZ), Vector3(spotX, spotY, ground));
        if (!(path.getPathType() & PATHFIND_NORMAL) || (path.getPathType() & PATHFIND_INCOMPLETE))
            return false;
        Vector3 const end = path.getActualEndPosition();
        float const dx = end.x - spotX;
        float const dy = end.y - spotY;
        if (dx * dx + dy * dy > 4.0f)
            return false;
        float walked = 0.0f;
        PointsArray const& points = path.getPath();
        for (size_t i = 1; i < points.size(); ++i)
            walked += (points[i] - points[i - 1]).length();
        float const straight = Vector3(end.x - heroX, end.y - heroY, end.z - heroZ).length();
        if (walked > straight * BONK_PORTAL_MAX_DETOUR + BONK_PORTAL_DETOUR_SLACK)
            return false;
        spotX = end.x;
        spotY = end.y;
        spotZ = end.z;
        return true;
    };

    float z = baseZ;
    bool placed = walkable(x, y, z, baseZ);
    for (uint32 step = 0; !placed && step < 16; ++step)
    {
        float const angle = m_player->GetOrientation() + (step % 8) * M_PI_F / 4.0f;
        float const distance = BONK_PORTAL_DISTANCE * (step < 8 ? 1.0f : 2.0f);
        x = heroX + distance * std::cos(angle);
        y = heroY + distance * std::sin(angle);
        placed = walkable(x, y, z, heroZ);
    }
    if (!placed)
    {
        x = heroX;
        y = heroY;
        z = heroZ;
    }

    if (GameObject* portal = PlaceObject(BONK_GO_PORTAL, x, y, z, BONK_OBJECT_LIFETIME_SEC))
        m_portalGuid = portal->GetObjectGuid();
}

bool BonkRun::IsAboveTerrain(float x, float y, float z) const
{
    float const terrain = m_player->GetMap()->GetTerrain()->GetHeightStatic(x, y, z, false);
    return terrain > INVALID_HEIGHT && z - terrain > BONK_PORTAL_ABOVE_TERRAIN;
}

bool BonkRun::HasPortalRoom(float x, float y, float z) const
{
    Map const* map = m_player->GetMap();
    if (!map->isInLineOfSight(x, y, z + 0.5f, x, y, z + BONK_PORTAL_ROOM_HEIGHT, true, false))
        return false;
    float const middle = z + BONK_PORTAL_ROOM_HEIGHT / 2.0f;
    for (uint32 spoke = 0; spoke < BONK_PORTAL_ROOM_SPOKES; ++spoke)
    {
        float const angle = spoke * 2.0f * M_PI_F / BONK_PORTAL_ROOM_SPOKES;
        float const edgeX = x + BONK_PORTAL_ROOM_RADIUS * std::cos(angle);
        float const edgeY = y + BONK_PORTAL_ROOM_RADIUS * std::sin(angle);
        float const ground = map->GetHeight(edgeX, edgeY, z + BONK_PORTAL_ROOM_STEP + 1.0f, true, 2.0f * BONK_PORTAL_ROOM_STEP + 1.0f);
        if (ground <= INVALID_HEIGHT || std::fabs(ground - z) > BONK_PORTAL_ROOM_STEP)
            return false;
        if (!map->isInLineOfSight(x, y, z + 1.0f, edgeX, edgeY, ground + 1.0f, true, false) ||
            !map->isInLineOfSight(x, y, middle, edgeX, edgeY, middle, true, false))
            return false;
    }
    return true;
}

void BonkRun::EnterNextStage()
{
    if (m_state != STATE_PORTAL)
        return;

    BonkPlayer* bonk = m_player->GetBonkPlayer();
    if (IsCoopGuest())
    {
        bonk->Notify(BONK_STRING_COOP_HOST_NEXT_STAGE);
        return;
    }
    if (!m_offer.empty())
    {
        bonk->Notify(BONK_STRING_MAKE_YOUR_CHOICE_FIRST);
        return;
    }

    if (m_stage >= m_tier.stages)
    {
        ContinueEndless();
        return;
    }

    BonkMap const* next = GetNextMap();
    if (!next)
        next = ChooseNextMap();
    if (!next)
    {
        bonk->Notify(BONK_STRING_PORTAL_HAS_NOWHERE_TO_TAKE);
        return;
    }

    ClearStageObjects();

    std::string error;
    if (!TeleportToStage(*next, error))
    {
        bonk->Notify(BONK_STRING_TRY_PORTAL_AGAIN, { error });
        BonkMap const* other = ChooseNextMap();
        m_nextMapId = other ? other->id : 0;
        return;
    }

    ++m_stage;
    m_map = *next;
    ApplyInvader();
    ApplyDifficultyGold();
    BringBossEarlier();
    m_nextMapId = 0;
    BonkCoop::OnHostEnteredStage(m_player, m_map, m_stage);
}

void BonkRun::ContinueEndless()
{
    ClearStageObjects();
    ++m_stage;
    m_nextMapId = 0;
    BonkCoop::OnHostEndless(m_player, m_stage);
    StartStage();
}

void BonkRun::FollowIntoEndless(uint32 stage)
{
    if (IsOver() || m_sandbox)
        return;
    if (m_away)
    {
        m_followPending = true;
        m_followMap = m_map;
        m_followStage = stage;
        return;
    }
    SetPaused(false);
    ClearStageObjects();
    m_stage = stage;
    StartStage();
}

void BonkRun::ClearStageObjects()
{
    CollectAllShards();
    CollectAllGlyphs();
    EndHearth();
    DespawnMiniEvent();
    DespawnObjects();
    DespawnMobs();
    DespawnOrbs();
    DespawnTraps();
    DespawnLandMines();
    DespawnPets();
    DespawnShotSources();
    DespawnPools();
    DespawnWeaponOrbs();
    DespawnProjectiles();
    ClearHunterEvolutions();
    m_telegraphs.Dismiss(m_player);
    m_player->GetBonkPlayer()->ForgetShownReachRing();
    m_objectives.Clear(m_player);
    DespawnShrines();
    DespawnVendor();
}

void BonkRun::FollowToStage(BonkMap const& map, uint32 stage)
{
    if (IsOver() || m_sandbox)
        return;
    if (m_away)
    {
        m_followPending = true;
        m_followMap = map;
        m_followStage = stage;
        return;
    }
    SetPaused(false);
    ClearStageObjects();
    std::string error;
    if (!TeleportToStage(map, error))
    {
        m_player->GetBonkPlayer()->Notify(error);
        return;
    }
    m_stage = stage;
    m_map = map;
    ApplyInvader();
    ApplyDifficultyGold();
    BringBossEarlier();
    m_nextMapId = 0;
}

void BonkRun::EndWithHost()
{
    if (m_state == STATE_ENTERING)
    {
        Exit();
        return;
    }
    m_player->GetBonkPlayer()->Notify(BONK_STRING_COOP_HOST_ENDED_RUN);
    Finish(true);
}

void BonkRun::EndInWipe()
{
    if (m_state == STATE_ENTERING)
    {
        Exit();
        return;
    }
    m_player->GetBonkPlayer()->Notify(BONK_STRING_COOP_GROUP_WIPED);
    Finish(false);
}

void BonkRun::ReviveFromGroup(float health)
{
    if (m_player->IsAlive())
        return;
    m_player->ResurrectPlayer(health);
    m_player->SpawnCorpseBones();
    m_player->CastSpell(m_player, BONK_SPELL_REVIVE_SHIELD, true);
    SmiteAroundRevive();
    SendState();
}

bool BonkRun::SkipTime(uint32 seconds, std::string& error)
{
    if (m_state != STATE_RUNNING)
    {
        error = GetString(BONK_STRING_ONLY_RUNNING_STAGE_SKIPPED);
        return false;
    }
    if (m_bossSpawned)
    {
        error = GetString(BONK_STRING_BOSS_IS_ALREADY_HERE);
        return false;
    }

    uint32 const bossMs = m_map.durationSeconds * IN_MILLISECONDS;
    uint32 const target = seconds ? std::min(m_elapsedMs + seconds * IN_MILLISECONDS, bossMs) : bossMs;
    if (target <= m_elapsedMs)
    {
        error = GetString(BONK_STRING_BOSS_IS_ALREADY_DUE);
        return false;
    }

    m_totalMs += target - m_elapsedMs;
    m_rewardMs += (target - m_elapsedMs) * GetBonkMapRewardPercent(m_map.type) / 100;
    m_elapsedMs = target;

    while (m_nextEvent < m_map.events.size() && m_map.events[m_nextEvent].second * IN_MILLISECONDS < target)
        ++m_nextEvent;

    SendState();
    return true;
}

void BonkRun::GoHome()
{
    if (m_state == STATE_PORTAL)
        Finish(true);
}


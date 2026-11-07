#include "BonkRunInternal.h"
#include "BonkIntegrity.h"

namespace BonkRunShared
{
    uint32 s_spawnKit = 92;
    uint32 s_spawnLookLeadMs = 400;
    thread_local uint32 s_nextHelperLevel = 0;
    thread_local ObjectGuid t_missileLookSource;
}

float BonkRun::GetRingGap() const
{
    if (m_tier.key == "normal")
        return BONK_RING_GAP_NORMAL;
    if (m_tier.key == "heroic")
        return BONK_RING_GAP_HEROIC;
    return BONK_RING_GAP_MYTHIC;
}

void BonkRun::PruneMobs()
{
    Map* map = m_player->GetMap();
    m_mobs.erase(std::remove_if(m_mobs.begin(), m_mobs.end(), [map](ObjectGuid const& guid)
    {
        Creature* mob = map->GetCreature(guid);
        return !mob || !mob->IsAlive() || mob->HasCreatureState(CSTATE_DESPAWNING);
    }), m_mobs.end());
}

void BonkRun::UpdateSpawns(uint32 diff)
{
    uint32 const elapsedSeconds = m_elapsedMs / IN_MILLISECONDS;

    if (m_bossSpawned && !IsCoopGuest())
    {
        m_stageBosses.erase(std::remove_if(m_stageBosses.begin(), m_stageBosses.end(), [this](ObjectGuid const& guid)
        {
            Creature* boss = m_player->GetMap()->GetCreature(guid);
            return !boss || (boss->IsAlive() && boss->HasCreatureState(CSTATE_DESPAWNING));
        }), m_stageBosses.end());
        if (m_stageBosses.empty())
        {
            m_bossSpawned = false;
            m_bossGuid.Clear();
            SendBossMusic(false);
        }
        else if (std::find(m_stageBosses.begin(), m_stageBosses.end(), m_bossGuid) == m_stageBosses.end())
            m_bossGuid = m_stageBosses.front();
    }

    UpdateWaves();
    if (m_state != STATE_RUNNING)
        return;
    UpdateBossVoices();
    UpdateOvertime(diff);
    UpdateLanes(diff);
    UpdateRingSample(diff);
    UpdatePerch(diff);

    bool const bossDue = !IsFinale() && !m_bossSpawned && elapsedSeconds >= m_map.durationSeconds;
    if (bossDue && IsCoopGuest())
        m_bossSpawned = true;
    else if (bossDue && !SpawnBosses())
    {
        OpenPortal(nullptr);
        return;
    }
    UpdateEndlessBosses();

    m_spawnTimer -= int32(diff);
    m_eliteTimer -= int32(diff);
    if (m_spawnTimer > 0 && m_eliteTimer > 0)
        return;

    PruneMobs();

    if (m_eliteTimer <= 0)
    {
        uint32 const interval = GetEliteIntervalMs();
        if (!interval || IsQuietTime() || m_bossSpawned || m_mobs.size() >= m_tier.maxAlive)
            m_eliteTimer = int32(BONK_ELITE_RETRY_MS);
        else
        {
            m_eliteTimer += int32(interval);
            float x, y, z;
            if (BonkMapCreature const* elite = PickCreature(BONK_SPAWN_ELITE))
                if (FindMobPosition(x, y, z, m_map.spawnMinDistance, m_map.spawnMaxDistance))
                    EmergeMobAt(*elite, x, y, z, false, urand(0, BONK_SPAWN_TICK_MS));
        }
    }

    if (m_spawnTimer <= 0)
    {
        m_spawnTimer += int32(BONK_SPAWN_TICK_MS);

        uint32 const target = GetSpawnTarget();
        uint32 const trash = (m_stress.on ? CountTrash() : uint32(std::ceil(CountRosterThreat()))) + m_emerging.size();
        uint32 const alive = m_mobs.size() + m_emerging.size();
        uint32 const fullPerTick = GetWave().spawnPerTick ? GetWave().spawnPerTick : BONK_SPAWN_PER_TICK;
        uint32 const perTick = fullPerTick > BONK_OPENING_REFILL_MIN ?
            BONK_OPENING_REFILL_MIN + uint32((fullPerTick - BONK_OPENING_REFILL_MIN) * GetOpeningProgress() + 0.5f) : fullPerTick;
        uint32 count = target > trash ? target - trash : 0;
        count = std::min(count, m_tier.maxAlive > alive ? m_tier.maxAlive - alive : 0u);
        count = std::min(count, m_stress.on ? BONK_STRESS_SPAWN_PER_TICK : perTick);
        SpawnTrashPacks(count);
    }
}

BonkWave const& BonkRun::GetWave() const
{
    std::vector<BonkWave> const& waves = sBonkMgr.GetWaves();
    return waves[std::min(m_waveIndex, waves.size() - 1)];
}

bool BonkRun::IsInRoster(BonkArchetype archetype) const
{
    if (m_stress.on)
        return true;
    if (archetype >= MAX_BONK_ARCHETYPE)
        return false;
    BonkWave const& wave = GetWave();
    if (m_stage > 1 && wave.beat == BONK_BEAT_BUILD && archetype != BONK_ARCHETYPE_SWARMER)
        return true;
    return wave.roster[archetype] > 0;
}

float BonkRun::CountRosterThreat() const
{
    Map* map = m_player->GetMap();
    float threat = 0.0f;
    for (ObjectGuid const& guid : m_mobs)
        if (Creature const* mob = map->GetCreature(guid))
            if (BonkMobAI const* ai = dynamic_cast<BonkMobAI const*>(mob->AI()))
                if (ai->GetKind() == BONK_SPAWN_NORMAL && !ai->IsFlyer() && IsInRoster(ai->GetArchetype()))
                    threat += sBonkMgr.GetArchetype(ai->GetArchetype()).threat;
    return threat;
}

float BonkRun::GetCurveMinAlive() const
{
    std::vector<BonkWave> const& waves = sBonkMgr.GetWaves();
    BonkWave const& wave = GetWave();
    float const second = m_elapsedMs / float(IN_MILLISECONDS);
    float const end = m_waveIndex + 1 < waves.size() ? float(waves[m_waveIndex + 1].startSecond) : float(m_map.durationSeconds);
    float const span = end - float(wave.startSecond);
    float minAlive = wave.crowdStart;
    if (span > 0.0f)
        minAlive += (wave.crowdEnd - wave.crowdStart) * std::min(1.0f, std::max(0.0f, (second - wave.startSecond) / span));
    minAlive = std::max(minAlive, GetStageCrowdFloor()) * GetStageCrowdScale();
    return minAlive * m_tier.minAliveMultiplier * (1.0f + m_bonuses.spawnRate / 100.0f) * (1.0f + GetGreedCrowdPercent() / 100.0f) *
        GetOpeningEase() * (m_invaderId ? BONK_INVASION_CROWD : 1.0f);
}

float BonkRun::GetStageCrowdFloor() const
{
    if (m_stage <= 1)
        return 0.0f;
    float peak = 0.0f;
    for (BonkWave const& wave : sBonkMgr.GetWaves())
        peak = std::max(peak, wave.crowdEnd);
    float const carry = peak * BONK_STAGE_CARRY_SHARE;
    switch (GetWave().beat)
    {
        case BONK_BEAT_BUILD:    return carry;
        case BONK_BEAT_LULL:
        case BONK_BEAT_MINIBOSS: return carry * BONK_STAGE_CALM_SHARE;
        default:                 return 0.0f;
    }
}

float BonkRun::GetStageCrowdScale() const
{
    if (IsMythic())
        return 1.0f;
    return 1.0f + BONK_STAGE_CROWD_GROWTH * float(std::min(m_stage > 1 ? m_stage - 1 : 0, BONK_STAGE_CROWD_GROWTH_STAGES));
}

float BonkRun::GetOpeningProgress() const
{
    if (m_stage != 1 || m_stress.on || m_elapsedMs >= m_tier.openingMs)
        return 1.0f;
    return m_elapsedMs / float(m_tier.openingMs);
}

float BonkRun::GetOpeningEase() const
{
    return m_tier.openingCrowd + (1.0f - m_tier.openingCrowd) * GetOpeningProgress();
}

void BonkRun::UpdateWaves()
{
    std::vector<BonkWave> const& waves = sBonkMgr.GetWaves();
    uint32 const second = m_elapsedMs / IN_MILLISECONDS;
    size_t index = m_waveIndex;
    while (index + 1 < waves.size() && waves[index + 1].startSecond <= second)
        ++index;
    if (!m_waveEntered || index != m_waveIndex)
    {
        m_waveEntered = true;
        EnterWave(index);
    }

    size_t const next = m_waveIndex + 1;
    if (next < waves.size() && m_waveWarned < next && second + BONK_BEAT_WARN_SECONDS >= waves[next].startSecond)
    {
        m_waveWarned = next;
        BonkWave const& coming = waves[next];
        if (coming.beat == BONK_BEAT_WALL || coming.beat == BONK_BEAT_MINIBOSS)
        {
            if (m_player->GetBonkPlayer()->IsAddonReady())
            {
                WorldPacket data(SMSG_HOA_MESSAGE);
                HoAWriteWaveBeat(data, Localize(BONK_FIELD_WAVE_NAME, coming.startSecond, coming.name), coming.beat,
                    coming.startSecond > second ? coming.startSecond - second : 0);
                m_player->GetSession()->SendPacket(&data);
            }
        }
    }
}

void BonkRun::EnterWave(size_t index)
{
    m_waveIndex = index;
    BonkWave const& wave = GetWave();
    BonkPlayer* bonk = m_player->GetBonkPlayer();

    m_miniEventSlots = wave.miniEvents;
    m_nextMiniEventMs = m_elapsedMs;
    if (wave.eliteIntervalSeconds)
        m_eliteTimer = int32(GetEliteIntervalMs());
    m_spawnTimer = std::min(m_spawnTimer, 0);

    if (m_bossSpawned || m_stress.on)
        return;

    SpawnMinibosses(wave.minibosses);

    bool elites = false;
    uint32 const eliteCount = uint32(wave.elites * GetEliteScale() + 0.5f);
    for (uint32 i = 0; i < eliteCount; ++i)
        if (BonkMapCreature const* creature = PickCreature(BONK_SPAWN_ELITE))
            elites |= SpawnMob(*creature) != nullptr;

    if (wave.beat == BONK_BEAT_WALL)
        bonk->Notify(BONK_STRING_EXCLAIM, { Localize(BONK_FIELD_WAVE_NAME, wave.startSecond, wave.name) });
    else if (elites)
        bonk->Notify(BONK_STRING_ELITES_ARE_CLOSING_IN);
    if (wave.beat == BONK_BEAT_WALL || wave.beat == BONK_BEAT_MINIBOSS)
    {
        if (bonk->IsAddonReady())
        {
            WorldPacket data(SMSG_HOA_MESSAGE);
            HoAWriteWaveBeat(data, Localize(BONK_FIELD_WAVE_NAME, wave.startSecond, wave.name), wave.beat, 0);
            m_player->GetSession()->SendPacket(&data);
        }
    }
}

bool BonkRun::SpawnBosses()
{
    BonkMapCreature const* boss = PickCreature(BONK_SPAWN_BOSS);
    if (!boss)
        return false;
    for (uint32 i = 0; i < GetCoopBossCount(); ++i)
    {
        BonkMapCreature const* pick = i == 0 ? boss : PickCreature(BONK_SPAWN_BOSS);
        if (!pick)
            pick = boss;
        if (Creature* mob = SpawnMob(*pick))
        {
            m_bossSpawned = true;
            NotifyArrived(mob);
        }
    }
    return true;
}

void BonkRun::SpawnMinibosses(uint32 count)
{
    if (IsCoopGuest() || !count)
        return;
    Creature* arrived = nullptr;
    uint32 const minibosses = (count + uint32(GetGlyphValue(BONK_GLYPH_AMBITION, 0))) * GetCoopBossCount();
    for (uint32 i = 0; i < minibosses; ++i)
    {
        BonkMapCreature const* creature = PickCreature(BONK_SPAWN_MINIBOSS);
        if (!creature)
            creature = PickCreature(BONK_SPAWN_ELITE);
        if (creature)
            if (Creature* mob = SpawnMob(*creature))
                arrived = mob;
    }
    if (arrived)
        NotifyArrived(arrived);
}

void BonkRun::StartEndless()
{
    m_endlessStartMs = m_elapsedMs;
    m_endlessStartTotalMs = m_totalMs;
    m_endlessBosses = 0;
    m_endlessMinibosses = 0;
    m_endlessBossDueMs = m_elapsedMs + BONK_ENDLESS_BOSS_MS;
    m_endlessMinibossDueMs = m_elapsedMs + BONK_ENDLESS_MINIBOSS_MS;
    m_waveWarned = sBonkMgr.GetWaves().size();
    while (m_nextEvent < m_map.events.size() && m_map.events[m_nextEvent].second * IN_MILLISECONDS < m_elapsedMs)
        ++m_nextEvent;
}

void BonkRun::UpdateEndlessBosses()
{
    if (!IsFinale() || IsCoopGuest() || m_stress.on)
        return;
    if (m_elapsedMs >= m_endlessBossDueMs)
    {
        SpawnBosses();
        m_endlessBossDueMs = m_elapsedMs + GetEndlessInterval(BONK_ENDLESS_BOSS_MS, BONK_ENDLESS_MIN_BOSS_MS, ++m_endlessBosses);
    }
    if (m_elapsedMs >= m_endlessMinibossDueMs)
    {
        SpawnMinibosses(1);
        m_endlessMinibossDueMs = m_elapsedMs + GetEndlessInterval(BONK_ENDLESS_MINIBOSS_MS, BONK_ENDLESS_MIN_MINIBOSS_MS, ++m_endlessMinibosses);
    }
}

uint32 BonkRun::GetEndlessInterval(uint32 firstMs, uint32 shortestMs, uint32 spawned)
{
    return std::max(shortestMs, uint32(firstMs * std::pow(BONK_ENDLESS_INTERVAL_SHRINK, float(spawned))));
}

std::string BonkRun::DescribeTimelineMarks() const
{
    std::string marks;
    for (BonkWave const& wave : sBonkMgr.GetWaves())
        if (wave.beat == BONK_BEAT_WALL || wave.beat == BONK_BEAT_MINIBOSS)
        {
            std::string name = Localize(BONK_FIELD_WAVE_NAME, wave.startSecond, wave.name);
            name.erase(std::remove_if(name.begin(), name.end(), [](char c) { return c == ':' || c == ',' || c == '~'; }), name.end());
            marks += (marks.empty() ? "" : ",") + std::to_string(wave.startSecond) + ":" + std::to_string(wave.beat) + ":" + name;
        }
    return marks;
}

void BonkRun::LogMinute()
{
    float const maxHealth = std::max(1.0f, float(m_player->GetMaxHealth()));
    sLog.Player(m_player->GetSession(), LOG_LEVELUP, LOG_LVL_BASIC,
        "Bonk minute: %s at run minute %u (stage %u, %s, %s, class %u): level %u, %u kills (+%u), took %u damage (%.0f%% of max health), "
        "healed %u (%.0f%%), lowest health %u%%, %u enemies alive, block \"%s\"; client objects peak %u, %s; packets %u/s (%u KB/s); gold earned %u; valor earned %u, on chests %u, in shops %u, on enchants %u, left %u, chests bought %u; %s",
        m_player->GetName(), m_nextLogMinute, m_stage, m_map.key.c_str(), m_tier.key.c_str(), uint32(m_player->GetClass()), m_player->GetLevel() + m_overcapLevel,
        m_kills, m_kills - m_minuteKills, m_minuteDamage, m_minuteDamage * 100.0f / maxHealth, m_minuteHealed, m_minuteHealed * 100.0f / maxHealth,
        m_minuteLowestHealth, uint32(m_mobs.size()), GetWave().name.c_str(), m_minuteClientObjectsPeak, DescribeClientObjects().c_str(),
        m_minutePackets / std::max(1u, m_minutePacketSeconds), m_minutePacketBytes / 1024 / std::max(1u, m_minutePacketSeconds), m_goldEarned,
        m_valorEarned, m_valorOnChests, m_valorInShops, m_valorOnEnchants, m_coins, m_chestsBought, DescribeDefense().c_str());
    m_minutePackets = 0;
    m_minutePacketBytes = 0;
    m_minutePacketSeconds = 0;
    LogBuild();
    LogRing();
    ++m_nextLogMinute;
    m_minuteClientObjectsPeak = 0;
    m_minuteDamage = 0;
    m_minuteHealed = 0;
    m_minuteKills = m_kills;
    m_minuteLowestHealth = m_player->IsAlive() ? uint32(m_player->GetHealthPercent()) : 0;
}

uint32 BonkRun::CountClientObjects() const
{
    std::shared_lock<std::shared_timed_mutex> lock(m_player->m_visibleGUIDs_lock);
    return uint32(m_player->m_visibleGUIDs.size());
}

void BonkRun::SamplePerfSecond()
{
    PerfSecond second;
    second.runSecond = m_totalMs / IN_MILLISECONDS;
    second.clientObjects = CountClientObjects();
    second.mobs = uint32(m_mobs.size());
    second.orbs = uint32(m_orbs.size());
    second.pulledOrbs = uint32(std::count_if(m_orbs.begin(), m_orbs.end(), [](Orb const& orb) { return orb.pulled; }));
    second.standIns = uint32(m_telegraphs.CountStandIns());
    second.busyStandIns = uint32(m_telegraphs.CountBusyStandIns());
    second.telegraphs = uint32(m_telegraphs.Count());
    second.hits = m_secondHits;
    second.casts = m_secondCasts;
    second.pendingCasts = uint32(m_pendingCasts.size());
    second.pets = uint32(GetAllPets(false).size());
    BonkPlayer::PacketCounts const packets = m_player->GetBonkPlayer()->TakePacketCounts();
    if (m_packetsPrimed)
    {
        second.packets = packets.packets;
        second.bytes = packets.bytes;
        for (auto const& kind : packets.top)
            second.topPackets += (second.topPackets.empty() ? "" : ", ") + std::string(LookupOpcodeName(kind.first)) + " x" + std::to_string(kind.second);
        m_minutePackets += packets.packets;
        m_minutePacketBytes += packets.bytes;
        ++m_minutePacketSeconds;
    }
    m_packetsPrimed = true;
    m_secondHits = 0;
    m_secondCasts = 0;
    m_perfSeconds.push_back(second);
    if (m_perfSeconds.size() > BONK_PERF_SECONDS_KEPT)
        m_perfSeconds.erase(m_perfSeconds.begin());
}

void BonkRun::LogPerfDip()
{
    if (m_perfDipLogged && m_totalMs - m_perfDipLoggedMs < BONK_PERF_DIP_GAP_MS)
        return;
    m_perfDipLogged = true;
    m_perfDipLoggedMs = m_totalMs;

    sLog.Out(LOG_PERFORMANCE, LOG_LVL_BASIC, "Client frame dip: %s at run minute %.2f (stage %u, %s, %s, class %u, level %u), newest second first:",
        m_player->GetName(), GetRunMinutes(), m_stage, m_map.key.c_str(), m_tier.key.c_str(), uint32(m_player->GetClass()),
        m_player->GetLevel() + m_overcapLevel);
    for (auto itr = m_perfSeconds.rbegin(); itr != m_perfSeconds.rend(); ++itr)
        sLog.Out(LOG_PERFORMANCE, LOG_LVL_BASIC, "  run %u:%02u: client objects %u, mobs %u, orbs %u (%u pulled), stand-ins %u (%u busy), "
            "telegraphs %u, hits %u, casts %u, pending casts %u, pets %u; packets %u (%u KB): %s",
            itr->runSecond / 60, itr->runSecond % 60, itr->clientObjects, itr->mobs, itr->orbs, itr->pulledOrbs, itr->standIns,
            itr->busyStandIns, itr->telegraphs, itr->hits, itr->casts, itr->pendingCasts, itr->pets, itr->packets, itr->bytes / 1024,
            itr->topPackets.c_str());
}

std::string BonkRun::DescribeClientObjects() const
{
    uint32 total = 0, enemies = 0, gameObjects = 0, dynamicObjects = 0, players = 0;
    std::map<uint32, uint32> helpers;
    {
        std::shared_lock<std::shared_timed_mutex> lock(m_player->m_visibleGUIDs_lock);
        total = uint32(m_player->m_visibleGUIDs.size());
        for (ObjectGuid const& guid : m_player->m_visibleGUIDs)
        {
            if (guid.IsCreatureOrPet())
            {
                if (std::find(m_mobs.begin(), m_mobs.end(), guid) != m_mobs.end())
                    ++enemies;
                else
                    ++helpers[guid.GetEntry()];
            }
            else if (guid.IsGameObject())
                ++gameObjects;
            else if (guid.IsDynamicObject())
                ++dynamicObjects;
            else if (guid.IsPlayer())
                ++players;
        }
    }

    std::vector<std::pair<uint32, uint32>> ranked(helpers.begin(), helpers.end());
    std::sort(ranked.begin(), ranked.end(), [](auto const& a, auto const& b) { return a.second > b.second; });
    uint32 helperCount = 0;
    for (auto const& helper : ranked)
        helperCount += helper.second;

    std::string top;
    for (size_t i = 0; i < ranked.size() && i < 5; ++i)
        top += (top.empty() ? "" : ", ") + std::to_string(ranked[i].first) + " x" + std::to_string(ranked[i].second);

    std::ostringstream text;
    text << "now " << total << " (" << enemies << " enemies, " << helperCount << " other creatures [" << top << "], "
        << gameObjects << " gameobjects, " << dynamicObjects << " dynamic objects, " << players << " players; "
        << m_telegraphs.CountStandIns() << " stand-ins, " << m_orbs.size() << " orbs, " << m_projectiles.size() << " projectiles)";
    return text.str();
}

void BonkRun::LogDeath()
{
    uint32 recent = 0;
    for (auto const& hit : m_recentHits)
        if (hit.first + 10 * IN_MILLISECONDS >= m_totalMs)
            recent += hit.second;
    sLog.Player(m_player->GetSession(), LOG_LEVELUP, LOG_LVL_BASIC,
        "Bonk death: %s at run minute %.2f (stage %u, %s, %s, class %u), level %u, %u kills: last hit by %s for %u; "
        "%u damage in the last 10 s from %u hits (%.0f%% of max health); %u enemies alive, block \"%s\"; %s",
        m_player->GetName(), GetRunMinutes(), m_stage, m_map.key.c_str(), m_tier.key.c_str(), uint32(m_player->GetClass()),
        m_player->GetLevel() + m_overcapLevel, m_kills, m_lastStriker.empty() ? "?" : m_lastStriker.c_str(), m_lastStrikeDamage, recent,
        uint32(m_recentHits.size()), recent * 100.0f / std::max(1.0f, float(m_player->GetMaxHealth())), uint32(m_mobs.size()), GetWave().name.c_str(), DescribeDefense().c_str());
}

std::string BonkRun::DescribeDefense() const
{
    float const maxHealth = std::max(1.0f, float(m_player->GetMaxHealth()));
    float const armor = std::max(0.0f, GetStat(BONK_PASSIVE_ARMOR));
    float const reduction = GetArmorReduction();
    float const damageScale = GetStageDamageMultiplier();
    float const gruntHit = GetScalingNow().hitShare * damageScale * GetHeroBaseHealth() * (1.0f - reduction);
    char text[256];
    snprintf(text, sizeof(text), "defense: max health %.0f, armor %.0f (%.1f%% reduction, +%.1f%% health), enemy damage x%.2f, grunt hit %.1f%% of max health",
        maxHealth, armor, reduction * 100.0f, GetArmorOverflowHealth(), damageScale, gruntHit * 100.0f / maxHealth);
    return text;
}

void BonkRun::LogLoadout() const
{
    sLog.Player(m_player->GetSession(), LOG_LEVELUP, LOG_LVL_BASIC,
        "Bonk loadout: %s starts a run at run minute 0 (stage %u, %s, %s, class %u): %s; difficulty level %u",
        m_player->GetName(), m_stage, m_map.key.c_str(), m_tier.key.c_str(), uint32(m_player->GetClass()),
        m_player->GetBonkPlayer()->DescribeLoadout().c_str(), m_difficultyLevel);
}

void BonkRun::BeginHardcoreRun()
{
    if (m_sandbox || IsCoopGuest())
        return;
    BonkPlayer* bonk = m_player->GetBonkPlayer();
    uint32 const run = bonk->BeginHardcoreRun(m_map.name);
    if (!run)
        return;
    sLog.Player(m_player->GetSession(), LOG_LEVELUP, LOG_LVL_BASIC,
        "Bonk hardcore: %s starts hardcore run %u (class %u, %s, crashes %u): %s",
        m_player->GetName(), run, uint32(m_player->GetClass()), bonk->IsIronman() ? "ironman" : "hardcore", bonk->GetHardcoreCrashes(),
        DescribeBoardEntry().c_str());
}

void BonkRun::EndHardcoreRunOnAbort()
{
    BonkPlayer* bonk = m_player->GetBonkPlayer();
    if (!bonk->GetHardcoreRun())
        return;
    bool const inFight = m_state == STATE_RUNNING || m_state == STATE_PORTAL;
    if (inFight && !m_player->IsAlive())
        bonk->OnHardcoreDeath(m_lastStriker, m_map.name, m_player->GetLevel() + m_overcapLevel, m_kills);
    if (inFight || m_state == STATE_ENTERING)
        LogRunEnd(false, DescribeBuildTotals());
    bonk->EndHardcoreRun();
}

void BonkRun::LogBuild() const
{
    sLog.Player(m_player->GetSession(), LOG_LEVELUP, LOG_LVL_BASIC,
        "Bonk build: %s at run minute %.2f (stage %u, %s, %s, class %u): level %u; %s; power %.0f%%, gear power %.0f%% (x%.2f)",
        m_player->GetName(), GetRunMinutes(), m_stage, m_map.key.c_str(), m_tier.key.c_str(), uint32(m_player->GetClass()),
        m_player->GetLevel() + m_overcapLevel, DescribeBuildTotals().c_str(), GetRunPower() + GetGlyphPower() + GetTalentDamagePercent(),
        GetGearTotal(BONK_PASSIVE_POWER), GetGearDamageScale());
}

void BonkRun::LogRunEnd(bool wentHome, std::string const& build) const
{
    char const* outcome = m_victory ? "victory" : wentHome ? "home" : m_player->IsAlive() ? "stopped" : "died";
    sLog.Player(m_player->GetSession(), LOG_LEVELUP, LOG_LVL_BASIC,
        "Bonk end: %s at run minute %.2f (stage %u, %s, %s, class %u): %s, level %u, %u kills, gold earned %u, tickets earned %u, scrap earned %u; %s; valor earned %u, on chests %u, in shops %u, on enchants %u, chests bought %u",
        m_player->GetName(), GetRunMinutes(), m_stage, m_map.key.c_str(), m_tier.key.c_str(), uint32(m_player->GetClass()), outcome,
        m_player->GetLevel() + m_overcapLevel, m_kills, m_goldEarned, m_shardsEarned, m_scrapEarned, build.c_str(),
        m_valorEarned, m_valorOnChests, m_valorInShops, m_valorOnEnchants, m_chestsBought);
}

std::string BonkRun::DescribeBoardEntry() const
{
    BonkPlayer const* bonk = m_player->GetBonkPlayer();
    bool const coop = BonkCoop::IsInCoopGroup(m_player);
    char text[96];
    snprintf(text, sizeof(text), "coop %u, gm %u, board %d, gear %u", coop ? 1u : 0u, bonk->IsBoardGameMaster() ? 1u : 0u,
        bonk->GetBoardChoice(), bonk->HasBoardGear(m_difficultyLevel) ? 1u : 0u);
    uint32 const hardcoreRun = bonk->GetHardcoreRun();
    std::string const entry = std::string(text) + (BonkIntegrity::IsServerModified() ? ", modified 1" : "") +
        (hardcoreRun ? ", hardcore " + std::to_string(hardcoreRun) : "");
    return coop ? entry + ", party " + DescribeBoardParty() : entry;
}

std::string BonkRun::DescribeBoardParty() const
{
    std::string party;
    for (Player* member : BonkCoop::RunGroupOf(m_player))
    {
        BonkPlayer const* bonk = member->GetBonkPlayer();
        bool const shown = bonk->GetBoardChoice() == 1;
        party += (party.empty() ? "" : ";") + std::to_string(member->GetGUIDLow()) + ":" + (shown ? std::string(member->GetName()) : "-") + ":" +
            std::to_string(uint32(member->GetClass())) + ":" + (shown ? "1" : "0") + ":" + (bonk->HasBoardGear(m_difficultyLevel) ? "1" : "0") + ":" +
            (bonk->IsBoardGameMaster() ? "1" : "0");
    }
    return party;
}

void BonkRun::LogLevelClear() const
{
    sLog.Player(m_player->GetSession(), LOG_LEVELUP, LOG_LVL_BASIC,
        "Bonk clear: %s clears level %u at run minute %.2f in %u ms (stage %u, %s, %s, class %u): %s",
        m_player->GetName(), m_difficultyLevel, GetRunMinutes(), m_totalMs, m_stage, m_map.key.c_str(), m_tier.key.c_str(),
        uint32(m_player->GetClass()), DescribeBoardEntry().c_str());
}

void BonkRun::NotifyBoardMiss() const
{
    if (m_sandbox || !IsMythic())
        return;
    BonkPlayer const* bonk = m_player->GetBonkPlayer();
    bool const coop = BonkCoop::IsInCoopGroup(m_player);
    if (!coop && bonk->GetBoardChoice() != 1)
        return;
    if (bonk->IsBoardGameMaster())
    {
        bonk->Notify(BONK_STRING_BOARD_MISS_GAME_MASTER);
        return;
    }
    if (BonkIntegrity::IsServerModified())
    {
        bonk->Notify(BONK_STRING_BOARD_MISS_MODIFIED_SERVER);
        return;
    }
    BonkPlayer::OffBoardGear const gear = bonk->FindOffBoardGear(m_difficultyLevel);
    if (gear.item)
    {
        std::string const name = bonk->GetItemName(gear.item->GetProto());
        if (gear.legacy)
            bonk->Notify(BONK_STRING_BOARD_MISS_LEGACY_GEAR, { name });
        else
            bonk->Notify(BONK_STRING_BOARD_MISS_GEAR_ABOVE_LEVEL, { name, bonk->GetLevelName(m_difficultyLevel) });
        return;
    }
    if (coop && NotifyBoardMissInParty())
        return;
    uint32 const climb = bonk->GetBoardClimb();
    if (climb && m_difficultyLevel > climb + 1)
        bonk->Notify(BONK_STRING_BOARD_MISS_CLIMB, { bonk->GetLevelName(climb + 1) });
}

bool BonkRun::NotifyBoardMissInParty() const
{
    BonkPlayer const* bonk = m_player->GetBonkPlayer();
    for (Player* member : BonkCoop::RunGroupOf(m_player))
    {
        if (member == m_player)
            continue;
        BonkPlayer const* other = member->GetBonkPlayer();
        if (other->IsBoardGameMaster())
        {
            bonk->Notify(BONK_STRING_BOARD_MISS_PARTY_GAME_MASTER, { member->GetName() });
            return true;
        }
        if (!other->HasBoardGear(m_difficultyLevel))
        {
            bonk->Notify(BONK_STRING_BOARD_MISS_PARTY_GEAR, { member->GetName() });
            return true;
        }
    }
    return false;
}

void BonkRun::LogFinale(float minutes, uint32 score) const
{
    sLog.Player(m_player->GetSession(), LOG_LEVELUP, LOG_LVL_BASIC,
        "Bonk finale: %s holds out %.2f minutes on level %u at run minute %.2f, score %u (stage %u, %s, %s, class %u): %s",
        m_player->GetName(), minutes, m_difficultyLevel, GetRunMinutes(), score, m_stage, m_map.key.c_str(), m_tier.key.c_str(),
        uint32(m_player->GetClass()), DescribeBoardEntry().c_str());
}

void BonkRun::LogBossFight(Creature const* mob, BonkSpawnKind kind, BossArrival const& arrival)
{
    uint32 const taken = m_damageTaken - arrival.damageTaken;
    sLog.Player(m_player->GetSession(), LOG_LEVELUP, LOG_LVL_BASIC,
        "Bonk boss: %s kills %s (%s) at run minute %.2f (stage %u, %s, %s, class %u), level %u: %.1f s after it arrived; "
        "took %u damage meanwhile (%.0f%% of max health), health now %u%%; client objects %s",
        m_player->GetName(), mob->GetName(), kind == BONK_SPAWN_BOSS ? "boss" : "mini-boss", GetRunMinutes(), m_stage, m_map.key.c_str(),
        m_tier.key.c_str(), uint32(m_player->GetClass()), m_player->GetLevel() + m_overcapLevel, (m_totalMs - arrival.ms) / 1000.0f, taken,
        taken * 100.0f / std::max(1.0f, float(m_player->GetMaxHealth())), uint32(m_player->GetHealthPercent()), DescribeClientObjects().c_str());
}

uint32 BonkRun::GetFirstMinibossSecond() const
{
    for (BonkWave const& wave : sBonkMgr.GetWaves())
        if (wave.minibosses)
            return wave.startSecond;
    return 0;
}

void BonkRun::HoldBigMoves(ObjectGuid const& mover, uint32 durationMs)
{
    m_bigMover = mover;
    m_bigMovesUntilMs = std::max(m_bigMovesUntilMs, m_totalMs + durationMs);
}

void BonkRun::UpdateOvertime(uint32 diff)
{
    uint32 const startSecond = IsFinale() ? m_map.durationSeconds : m_map.durationSeconds + BONK_OVERTIME_AFTER_SEC;
    if ((!m_bossSpawned && !IsFinale()) || m_stress.on || m_elapsedMs < startSecond * IN_MILLISECONDS || AreBigMovesHeld())
        return;
    m_overtimeTimer -= int32(diff);
    if (m_overtimeTimer > 0)
        return;
    m_overtimeTimer = int32(BONK_OVERTIME_INTERVAL_MS);

    BonkMapEvent ring;
    ring.second = m_elapsedMs / IN_MILLISECONDS;
    ring.type = BONK_EVENT_RING;
    ring.count = BONK_OVERTIME_RING + BONK_OVERTIME_RING_STEP * m_overtimeWaves;
    m_spawnDamageScale = IsFinale() ? 1.0f : 1.0f + BONK_OVERTIME_DAMAGE_STEP * (m_overtimeWaves + 1);
    uint32 const spawned = SpawnFormation(ring);
    m_spawnDamageScale = 1.0f;
    if (!spawned)
        return;
    if (!m_overtimeWaves)
        m_player->GetBonkPlayer()->Notify(BONK_STRING_OVERTIME_ENEMIES_KEEP_COMING_UNTIL);
    ++m_overtimeWaves;
}

BonkScalingPoint BonkRun::GetScalingNow() const
{
    if (IsFinale() && !m_sandbox && m_scalingMinuteOverride < 0.0f)
        return GetEndlessScaling();
    return GetScalingAt(m_scalingMinuteOverride >= 0.0f ? m_scalingMinuteOverride :
        m_sandbox && m_sandboxMinute >= 0.0f ? m_sandboxMinute : GetRunMinutes());
}

BonkScalingPoint BonkRun::GetEndlessScaling() const
{
    std::vector<BonkScalingPoint> const& points = sBonkMgr.GetScaling();
    BonkScalingPoint now = GetScalingAt(m_endlessStartTotalMs / float(MINUTE * IN_MILLISECONDS));
    BonkScalingPoint const& first = points.front();
    BonkScalingPoint const& last = points.back();
    float const span = last.minute - first.minute;
    if (span <= 0.0f)
        return now;
    float const cycles = (m_totalMs - m_endlessStartTotalMs) / float(MINUTE * IN_MILLISECONDS) / span;
    now.hitShare *= GetGrowthOver(first.hitShare, last.hitShare, cycles);
    now.health *= m_tier.key == "normal" ? GetGrowthOver(first.healthNormal, last.healthNormal, cycles) : GetGrowthOver(first.health, last.health, cycles);
    now.minute = GetRunMinutes();
    return now;
}

float BonkRun::GetGrowthOver(float from, float to, float cycles)
{
    return from > 0.0f ? std::pow(to / from, cycles) : 1.0f;
}

BonkScalingPoint BonkRun::GetScalingAt(float minute) const
{
    std::vector<BonkScalingPoint> const& points = sBonkMgr.GetScaling();
    size_t index = 0;
    while (index + 1 < points.size() && points[index + 1].minute <= minute)
        ++index;
    BonkScalingPoint const& from = points[index];
    BonkScalingPoint const* to = index + 1 < points.size() ? &points[index + 1] : nullptr;
    BonkScalingPoint now = from;
    now.minute = minute;
    if (!to && index > 0)
    {
        BonkScalingPoint const& before = points[index - 1];
        float const span = from.minute - before.minute;
        if (span > 0.0f)
        {
            float const t = (minute - from.minute) / span;
            now.hitShare += (from.hitShare - before.hitShare) * t;
            now.health += (from.health - before.health) * t;
            now.healthNormal += (from.healthNormal - before.healthNormal) * t;
        }
    }
    else if (to)
    {
        float const span = to->minute - from.minute;
        float const t = span > 0.0f ? std::min(1.0f, std::max(0.0f, (minute - from.minute) / span)) : 0.0f;
        now.hitShare = from.hitShare + (to->hitShare - from.hitShare) * t;
        now.health = from.health + (to->health - from.health) * t;
        now.healthNormal = from.healthNormal + (to->healthNormal - from.healthNormal) * t;
    }
    else
        now.minute = from.minute;
    if (m_tier.key == "normal")
        now.health = now.healthNormal;
    return now;
}

float BonkRun::GetHeroBaseHealth() const
{
    PlayerLevelInfo info;
    sObjectMgr.GetPlayerLevelInfo(m_player->GetRace(), m_player->GetClass(), m_player->GetLevel(), &info);
    float const stamina = float(info.stats[STAT_STAMINA]);
    float const fromStamina = std::min(stamina, 20.0f) + std::max(stamina - 20.0f, 0.0f) * 10.0f;
    return std::max(1.0f, float(m_player->GetCreateHealth()) + fromStamina);
}

float BonkRun::GetMagnetRange() const
{
    return std::min(BONK_MAX_MAGNET_RANGE, BONK_ORB_MAGNET_RANGE * (1.0f + std::max(0.0f, GetPassiveTotal(BONK_PASSIVE_PICKUP)) / 100.0f));
}

float BonkRun::GetRunPower() const
{
    return GetPassiveTotal(BONK_PASSIVE_POWER) - GetGearTotal(BONK_PASSIVE_POWER);
}

float BonkRun::GetGearDamageScale() const
{
    return 1.0f + std::max(0.0f, GetGearTotal(BONK_PASSIVE_POWER)) / (100.0f + BONK_GEAR_POWER_REFERENCE);
}

float BonkRun::GetGearTotal(BonkPassiveEffect effect) const
{
    float const total = m_gear.passives[effect];
    return effect == BONK_PASSIVE_HASTE ? std::min(total, BONK_MAX_GEAR_HASTE) : total;
}

float BonkRun::GetPassiveTotal(BonkPassiveEffect effect) const
{
    float total = m_bonuses.passives[effect] + GetGearTotal(effect);
    for (auto const& itr : m_passiveRanks)
        if (BonkPassive const* passive = sBonkMgr.GetPassive(itr.first))
            if (passive->effect == effect)
                total += passive->valuePerRank * passive->RankScale(itr.second);
    if (effect == BONK_PASSIVE_HASTE)
        total += GetEnrageHaste() + GetDruidHaste();
    if (effect == BONK_PASSIVE_MOVE_SPEED)
        total += GetTalentMoveSpeed() + (IsMythic() ? BONK_MYTHIC_BASE_MOVE_SPEED : BONK_BASE_MOVE_SPEED);
    total += m_stress.bonuses[effect];
    total += m_cardStats[effect];
    total += m_shrineBonuses[effect];
    total += GetTrinketStat(effect);
    return total;
}

float BonkRun::GetStatCap(BonkPassiveEffect effect)
{
    switch (effect)
    {
        case BONK_PASSIVE_DODGE:  return BONK_MAX_DODGE;
        case BONK_PASSIVE_AMOUNT: return BONK_MAX_COUNT;
        case BONK_PASSIVE_MOVE_SPEED: return BONK_MAX_MOVE_SPEED;
        case BONK_PASSIVE_PICKUP: return (BONK_MAX_MAGNET_RANGE / BONK_ORB_MAGNET_RANGE - 1.0f) * 100.0f;
        default:                  return 0.0f;
    }
}

float CurveStat(float raw, float ceiling)
{
    if (raw <= 0.0f)
        return raw;
    return ceiling * (1.0f - std::exp(-raw / ceiling));
}

float CurveHaste(float raw)
{
    return CurveStat(raw, BONK_MAX_HASTE);
}

float BonkRun::GetArmorReduction() const
{
    float const armor = std::max(0.0f, GetStat(BONK_PASSIVE_ARMOR));
    return std::min(BONK_ARMOR_MAX_REDUCTION, armor / (armor * BONK_ARMOR_SLOPE + BONK_ARMOR_BASE));
}

float BonkRun::GetArmorOverflowHealth() const
{
    return std::max(0.0f, GetStat(BONK_PASSIVE_ARMOR) - BONK_ARMOR_CAP_POINT) * BONK_ARMOR_OVERFLOW_HEALTH;
}

float BonkRun::GetStat(BonkPassiveEffect effect) const
{
    float const total = GetPassiveTotal(effect);
    if (effect == BONK_PASSIVE_HASTE)
        return CurveHaste(total) + GetBurstHaste();
    if (effect == BONK_PASSIVE_AREA)
        return CurveStat(total, BONK_MAX_AREA);
    float const cap = GetStatCap(effect);
    float const lasting = cap > 0.0f ? std::min(total, cap) : total;
    return effect == BONK_PASSIVE_MOVE_SPEED ? lasting + GetBoostMoveSpeed() + GetDruidMoveSpeed() : lasting;
}

float BonkRun::GetBoostMoveSpeed() const
{
    float boost = GetPriestMoveSpeed();
    if (IsLastStand())
        boost += GetGlyphValue(BONK_GLYPH_LAST_STAND, 2);
    if (BonkCard const* potion = m_cardByEffect[BONK_CARD_SWIFTNESS])
        if (m_player->HasAura(BONK_SPELL_CARD_SWIFT))
            boost += potion->values[1];
    boost += GetTrinketMoveSpeed();
    return boost;
}

float BonkRun::GetHasteRate() const
{
    return 1.0f + std::max(0.0f, GetStat(BONK_PASSIVE_HASTE)) / 100.0f;
}

float BonkRun::GetRawWeaponHaste(OwnedWeapon const& owned) const
{
    return std::max(0.0f, GetPassiveTotal(BONK_PASSIVE_HASTE)) + GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_HASTE) + GetTalentHaste();
}

void BonkRun::SendStats() const
{
    float totals[MAX_BONK_PASSIVE_EFFECT];
    for (uint8 effect = 0; effect < MAX_BONK_PASSIVE_EFFECT; ++effect)
        totals[effect] = GetPassiveTotal(BonkPassiveEffect(effect)) - GetGearTotal(BonkPassiveEffect(effect));
    totals[BONK_PASSIVE_POWER] += GetBuffPower() + GetCardPower(nullptr) + GetGlyphPower() + GetTalentDamagePercent();
    totals[BONK_PASSIVE_HASTE] += GetTalentHaste();

    float afterCaps[MAX_BONK_PASSIVE_EFFECT] = {};
    afterCaps[BONK_PASSIVE_HASTE] = GetBurstHaste();
    afterCaps[BONK_PASSIVE_MOVE_SPEED] = GetBoostMoveSpeed() + GetDruidMoveSpeed();
    afterCaps[BONK_PASSIVE_AMOUNT] = GetGlyphValue(BONK_GLYPH_MULTI_SHOT, 0);
    m_player->GetBonkPlayer()->SendStatTotals(totals, true, afterCaps);
}

void BonkRun::RefreshWatchedStats(uint32 diff)
{
    if (!m_player->GetBonkPlayer()->IsWatchingStats())
    {
        m_statsRefreshTimer = 0;
        return;
    }
    m_statsRefreshTimer += diff;
    if (m_statsRefreshTimer < BONK_STATS_REFRESH_MS)
        return;
    m_statsRefreshTimer = 0;
    SendStats();
}

float BonkRun::GetMobDamageMultiplier(Creature const* mob) const
{
    float reduction = 0.0f;
    for (OwnedWeapon const& owned : m_weapons)
        if (owned.weapon.behavior == BONK_BEHAVIOR_DEMORALIZE && mob->HasAura(owned.weapon.spellId))
            reduction = std::max(reduction, owned.weapon.behaviorValue * (1.0f + owned.damageBonus / 100.0f));
        else if (owned.weapon.behavior == BONK_BEHAVIOR_DEMORALIZING_SHOUT && mob->HasAura(owned.weapon.spellId))
            reduction = std::max(reduction, BONK_DEMORALIZING_SHOUT_REDUCTION);
    reduction = std::max(reduction, GetDruidRoarReduction(mob));
    return 1.0f - std::min(reduction, BONK_MAX_DEMORALIZE) / 100.0f;
}

void BonkRun::AddTelegraph(BonkTelegraphShape shape, float x, float y, float z, float orientation, float size, uint32 durationMs,
    std::function<void()> onFire, bool lingers)
{
    if (m_state != STATE_RUNNING || m_paused)
        return;
    m_telegraphs.Add(m_player, shape, x, y, z, orientation, size, durationMs, std::move(onFire), lingers);
}

void BonkRun::AddEnemyTelegraph(Creature const* caster, BonkTelegraphShape shape, float x, float y, float z, float orientation, float size,
    uint32 durationMs, std::function<void()> onFire, uint32 windId)
{
    if (m_state != STATE_RUNNING || m_paused)
        return;
    m_telegraphs.Add(m_player, shape, x, y, z, orientation, size, durationMs, std::move(onFire), false, caster->GetObjectGuid(), windId);
}

void BonkRun::CancelEnemyWindup(Creature const* caster, uint32 windId)
{
    if (windId)
        m_telegraphs.CancelFrom(m_player, caster->GetObjectGuid(), windId);
}

void BonkRun::ForgetEnemyAttacks(Creature const* caster)
{
    m_telegraphs.CancelFrom(m_player, caster->GetObjectGuid());
    DropEnemyMissilesFrom(caster->GetObjectGuid());
}

void BonkRun::ShowImpact(BonkEnemyHit const& hit, float x, float y, float z, float radius)
{
    uint32 const kit = hit.impactKit ? hit.impactKit : BONK_KIT_FIRE_BURST;
    if (radius > 0.0f)
        ShowAreaImpact(kit, x, y, z, radius);
    else
        ShowKitAt(kit, x, y, z);
}

void BonkRun::ShowAreaImpact(uint32 kit, float x, float y, float z, float radius)
{
    ShowKitAt(kit, x, y, z, std::min(BONK_IMPACT_MAX_STRETCH, std::max(1.0f, radius / BONK_IMPACT_KIT_RADIUS)));
    if (radius < BONK_IMPACT_RING_FROM)
        return;

    Map* map = m_player->GetMap();
    float const ring = radius * BONK_IMPACT_RING_SHARE;
    uint32 const count = std::max(BONK_IMPACT_RING_MIN, std::min(BONK_IMPACT_RING_MAX, uint32(2.0f * M_PI_F * ring / BONK_IMPACT_RING_SPACING)));
    float const turn = frand(0.0f, 2.0f * M_PI_F);
    for (uint32 i = 0; i < count; ++i)
    {
        float const angle = turn + 2.0f * M_PI_F * float(i) / float(count);
        float const px = x + ring * std::cos(angle), py = y + ring * std::sin(angle);
        float pz = map->GetHeight(px, py, z + 5.0f, true, 15.0f);
        if (pz <= INVALID_HEIGHT)
            pz = z;
        ShowKitAt(kit, px, py, pz);
    }
}

void BonkRun::ShowRingImpact(uint32 kit, float x, float y, float z, float inner, float outer)
{
    if (!kit)
        return;
    Map* map = m_player->GetMap();
    float const ring = (inner + outer) / 2.0f;
    uint32 const count = std::max(BONK_IMPACT_RING_MIN, std::min(BONK_IMPACT_DONUT_MAX, uint32(2.0f * M_PI_F * ring / BONK_IMPACT_DONUT_SPACING)));
    float const stretch = std::min(BONK_IMPACT_MAX_STRETCH, std::max(1.0f, (outer - inner) / 2.0f / BONK_IMPACT_KIT_RADIUS));
    float const turn = frand(0.0f, 2.0f * M_PI_F);
    for (uint32 i = 0; i < count; ++i)
    {
        float const angle = turn + 2.0f * M_PI_F * float(i) / float(count);
        float const px = x + ring * std::cos(angle), py = y + ring * std::sin(angle);
        float pz = map->GetHeight(px, py, z + 5.0f, true, 15.0f);
        if (pz <= INVALID_HEIGHT)
            pz = z;
        ShowKitAt(kit, px, py, pz, stretch);
    }
}

bool BonkRun::ShowKitOnStandIn(uint32 kit, float x, float y, float z, uint32 holdMs)
{
    SendBonkKitAt(m_player, kit, x, y, z, 0.0f, holdMs);
    return true;
}

void BonkRun::ShowKitAt(uint32 kit, float x, float y, float z, float)
{
    SendBonkKitAt(m_player, kit, x, y, z, 0.0f, BONK_ERUPTION_LOOK_MS);
}

void BonkRun::ShowLineImpacts(uint32 kit, float x, float y, float z, float orientation, float length)
{
    Map* map = m_player->GetMap();
    for (float along = BONK_LINE_IMPACT_SPACING / 2.0f; along < length; along += BONK_LINE_IMPACT_SPACING)
    {
        float const px = x + along * std::cos(orientation), py = y + along * std::sin(orientation);
        float pz = map->GetHeight(px, py, z + 5.0f, true, 15.0f);
        if (pz <= INVALID_HEIGHT)
            pz = z;
        ShowKitAt(kit, px, py, pz);
    }
}

void BonkRun::ShowAttackLook(BonkEnemyHit const& hit, BonkTelegraphShape shape, float x, float y, float z, float orientation, float size)
{
    if (hit.castKit)
        if (Creature* looker = m_player->GetMap()->GetCreature(hit.looker))
            if (looker->IsAlive())
            {
                if (hit.facesShape)
                    looker->SetFacingTo(orientation);
                looker->SendPlaySpellVisualKit(hit.castKit);
            }
    if (shape == BONK_TELEGRAPH_LINE && hit.impactKit)
        ShowLineImpacts(hit.impactKit, x, y, z, orientation, size);
}

Creature* BonkRun::SummonHazard(float x, float y, float z)
{
    return TakePooledMarker(m_hazardSources, x, y, z, BONK_HAZARD_MS, &InstallOrbAI);
}

Creature* BonkRun::TakePooledMarker(std::vector<PooledMarker>& pool, float x, float y, float z, uint32 busyMs, void (*install)(Creature*))
{
    Map* map = m_player->GetMap();
    for (PooledMarker& marker : pool)
    {
        if (marker.freeAtMs > m_totalMs)
            continue;
        Creature* creature = map->GetCreature(marker.guid);
        if (!creature || !creature->IsAlive())
        {
            creature = m_player->SummonCreature(BONK_PICKUP_MARKER, x, y, z, 0.0f, TEMPSUMMON_TIMED_DESPAWN, BONK_SHOT_SOURCE_LIFETIME_MS, false, 0,
                install);
            if (!creature)
                return nullptr;
            marker.guid = creature->GetObjectGuid();
        }
        else
            creature->NearTeleportTo(x, y, z, creature->GetOrientation());
        marker.freeAtMs = m_totalMs + busyMs;
        return creature;
    }
    if (pool.size() >= BONK_MARKER_POOL_MAX)
        return m_player->SummonCreature(BONK_PICKUP_MARKER, x, y, z, 0.0f, TEMPSUMMON_TIMED_DESPAWN, busyMs, false, 0, install);
    Creature* creature = m_player->SummonCreature(BONK_PICKUP_MARKER, x, y, z, 0.0f, TEMPSUMMON_TIMED_DESPAWN, BONK_SHOT_SOURCE_LIFETIME_MS, false, 0,
        install);
    if (creature)
        pool.push_back({ creature->GetObjectGuid(), m_totalMs + busyMs });
    return creature;
}

void BonkRun::FreePooledMarker(std::vector<PooledMarker>& pool, ObjectGuid const& guid, uint32 afterMs)
{
    for (PooledMarker& marker : pool)
        if (marker.guid == guid)
        {
            marker.freeAtMs = std::min(marker.freeAtMs, m_totalMs + afterMs);
            return;
        }
    if (Creature* creature = guid.IsEmpty() ? nullptr : m_player->GetMap()->GetCreature(guid))
        creature->DespawnOrUnsummon(afterMs);
}

void BonkRun::DespawnPooledMarkers(std::vector<PooledMarker>& pool)
{
    if (Map* map = m_player->FindMap())
        for (PooledMarker const& marker : pool)
            if (Creature* creature = map->GetCreature(marker.guid))
                creature->DespawnOrUnsummon();
    pool.clear();
}

void BonkRun::Erupt(BonkEnemyHit const& hit, float x, float y, float z, float radius, bool burst, bool showImpact)
{
    if (m_state != STATE_RUNNING)
        return;
    if (showImpact)
        ShowImpact(hit, x, y, z, burst ? radius : 0.0f);

    if (!hit.damage || !m_player->IsAlive() || !IsHeroWithin(m_player, x, y, radius))
        return;
    uint32 const hitSpell = hit.impactKit ? BONK_SPELL_PLAIN_HIT : BONK_SPELL_ERUPTION_HIT;
    Creature* mob = m_player->GetMap()->GetCreature(hit.caster);
    if (mob && mob->IsAlive())
        mob->CastCustomSpell(m_player, hitSpell, int32(hit.damage), {}, {}, true);
    else
        StrikeHero(hit, hitSpell, SummonHazard(x, y, z));
}

void BonkRun::StrikeHero(BonkEnemyHit const& hit, uint32 spellId, Unit* source)
{
    SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(spellId);
    if (m_state != STATE_RUNNING || !hit.damage || !spellInfo || !source || !source->IsInWorld() || !m_player->IsAlive() ||
        m_player->GetBonkPlayer()->IsDashInvulnerable())
        return;

    uint32 const raw = CapEnemyHit(std::max(1u, uint32(hit.damage * hit.scale)), hit.kind, hit.archetype);
    NoteStruck(hit.striker, hit.caster);
    SpellNonMeleeDamage strike(source, m_player, spellInfo->Id, SpellSchools(spellInfo->School));
    strike.damage = MitigateDamage(raw);
    strike.absorb = raw - strike.damage;
    source->DealDamageMods(m_player, strike.damage, &strike.absorb);
    source->SendSpellNonMeleeDamageLog(&strike);
    source->DealSpellDamage(&strike, false);
    if (Creature* striker = m_player->GetMap()->GetCreature(hit.looker))
        if (BonkMobAI* ai = dynamic_cast<BonkMobAI*>(striker->AI()))
            ai->OnHitHero(this);
}

void BonkRun::LandWarning(BonkEnemyHit const& hit, BonkTelegraphShape shape, float x, float y, float z, float orientation, float size)
{
    if (m_state != STATE_RUNNING)
        return;

    if (Creature* caster = m_player->GetMap()->GetCreature(hit.caster))
        if (BonkMobAI* ai = dynamic_cast<BonkMobAI*>(caster->AI()))
        {
            if (caster->IsAlive())
            {
                ai->LandWindup(hit.windId);
                return;
            }
            if (!ai->IsWindingUp(hit.windId))
                return;
        }

    ShowAttackLook(hit, shape, x, y, z, orientation, size);
    if (!hit.damage || !m_player->IsAlive() || m_player->GetBonkPlayer()->IsDashInvulnerable())
        return;
    float heroX, heroY, heroZ;
    GetHeroPositionNow(m_player, heroX, heroY, heroZ);
    if (!IsInBonkTelegraph(shape, x, y, orientation, size, heroX, heroY))
        return;

    if (shape != BONK_TELEGRAPH_CIRCLE && hit.impactKit)
        ShowKitAt(hit.impactKit, heroX, heroY, heroZ);
    if (shape == BONK_TELEGRAPH_CIRCLE)
        ShowImpact(hit, x, y, z, size);
    StrikeHero(hit, hit.spellId, SummonHazard(x, y, z));
    if (shape == BONK_TELEGRAPH_LINE && m_player->IsAlive())
        BonkMobAI::KnockBackHero(m_player, orientation);
}

std::vector<std::string> BonkRun::DescribeMob(Creature const* mob) const
{
    bool const tracked = std::find(m_mobs.begin(), m_mobs.end(), mob->GetObjectGuid()) != m_mobs.end();
    std::vector<Creature*> const around = GetMobsInRange(BONK_MOBINFO_STRIKE_RANGE);
    bool const struck = std::find(around.begin(), around.end(), mob) != around.end();
    auto yesNo = [](bool value) { return std::string(value ? "yes" : "no"); };
    return {
        "Run: tracked as a run enemy: " + yesNo(tracked) + ", hit by a " + std::to_string(int32(BONK_MOBINFO_STRIKE_RANGE)) +
            "-yard strike around you: " + yesNo(struck) +
            ", mini-event target: " + yesNo(IsMiniEventTarget(mob->GetObjectGuid())),
        "Run: stage running: " + yesNo(m_state == STATE_RUNNING) + ", paused: " + yesNo(m_paused) + ", enemies tracked: " +
            std::to_string(m_mobs.size()) + ", telegraphs up: " + std::to_string(m_telegraphs.Count())
    };
}

bool BonkRun::ReserveBolt(uint32 landMs)
{
    m_boltLandings.erase(std::remove_if(m_boltLandings.begin(), m_boltLandings.end(), [this](uint32 at) { return at <= m_totalMs; }),
        m_boltLandings.end());
    if (m_boltLandings.size() >= BONK_MAX_BOLTS)
        return false;
    m_boltLandings.push_back(m_totalMs + landMs);
    return true;
}

ObjectGuid BonkRun::PlaceBoltTarget(float x, float y, float z, uint32 lifetimeMs)
{
    Creature* target = TakePooledMarker(m_boltTargets, x, y, z, lifetimeMs, &InstallBoltTargetAI);
    if (!target)
        return ObjectGuid();

    target->SetFactionTemplateId(m_player->GetFactionTemplateId());
    target->SetMaxHealth(1000000);
    target->SetHealth(1000000);
    return target->GetObjectGuid();
}

void BonkRun::LandBolt(BonkEnemyHit const& hit, ObjectGuid targetGuid, float x, float y, float radius)
{
    Map* map = m_player->GetMap();
    Creature* target = map->GetCreature(targetGuid);
    if (target)
        FreePooledMarker(m_boltTargets, targetGuid, BONK_BOLT_TARGET_FREE_MS);
    if (hit.impactKit && m_state == STATE_RUNNING)
        ShowKitAt(hit.impactKit, x, y, target ? target->GetPositionZ() : m_player->GetPositionZ());

    SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(hit.spellId);
    if (m_state != STATE_RUNNING || !spellInfo || !m_player->IsAlive() || !IsHeroWithin(m_player, x, y, radius))
        return;

    Creature* mob = map->GetCreature(hit.caster);
    if (!mob || !mob->IsAlive())
    {
        StrikeHero(hit, hit.spellId, SummonHazard(x, y, target ? target->GetPositionZ() : m_player->GetPositionZ()));
        return;
    }

    SpellNonMeleeDamage strike(mob, m_player, hit.spellId, SpellSchools(spellInfo->School));
    strike.damage = std::max(1u, hit.damage);
    mob->DealDamageMods(m_player, strike.damage, &strike.absorb);
    mob->SendSpellNonMeleeDamageLog(&strike);
    mob->DealSpellDamage(&strike, false);
}

void BonkRun::HitAgain(SpellEntry const* spellInfo, Unit* target, float damage, SpellEffectIndex effectIndex, WeaponAttackType attackType)
{
    if (m_state != STATE_RUNNING || !spellInfo || !target || !target->IsAlive() || damage <= 0.0f || !m_player->IsAlive())
        return;

    OwnedWeapon const* owned = nullptr;
    for (OwnedWeapon const& itr : m_weapons)
        if (itr.weapon.spellId == spellInfo->Id || itr.weapon.altSpellId == spellInfo->Id)
        {
            owned = &itr;
            break;
        }
    if (!owned)
        return;
    float const chance = GetSpellUpgrade(*owned, BONK_SPELL_UPGRADE_HIT_TWICE);
    if (chance <= 0.0f || !roll_chance_f(chance))
        return;

    SpellNonMeleeDamage hit(m_player, target, spellInfo->Id, SpellSchools(spellInfo->School));
    bool const crit = spellInfo->CanCrit() && roll_chance_f(GetCritChance(spellInfo, target));
    m_player->CalculateSpellDamage(&hit, damage, spellInfo, effectIndex, attackType, nullptr, crit);
    target->CalculateAbsorbResistBlock(m_player, &hit, spellInfo, BASE_ATTACK, nullptr);
    m_player->DealDamageMods(target, hit.damage, &hit.absorb);
    m_player->SendSpellNonMeleeDamageLog(&hit);
    m_player->DealSpellDamage(&hit, true);
}

void BonkRun::OnHeroDodge(Unit* attacker)
{
    if (m_state != STATE_RUNNING)
        return;
    ++m_dodgesUnreported;
    OnRogueDodge(attacker);
}

void BonkRun::OnHeroDamaged()
{
    if (m_state == STATE_RUNNING)
        TryPaladinLastStands();
}

void BonkRun::OnHeroStruck(Creature* attacker)
{
    m_lastStruckMs = m_totalMs;
    NoteStruck(DescribeStriker(attacker), attacker->GetObjectGuid());
    OnShamanStruck(attacker);
    OnPriestStruck(attacker);
    OnPaladinStruck(attacker);
    OnDruidStruck(attacker);
}

std::string BonkRun::DescribeStriker(Creature const* attacker)
{
    BonkMobAI const* ai = dynamic_cast<BonkMobAI const*>(attacker->AI());
    if (!ai)
        return attacker->GetName();
    static char const* const kinds[MAX_BONK_SPAWN_KIND] = { "", "elite", "boss", "mini-boss" };
    std::string const what = ai->GetKind() == BONK_SPAWN_NORMAL ? sBonkMgr.GetArchetype(ai->GetArchetype()).name : kinds[ai->GetKind()];
    return std::string(attacker->GetName()) + " (" + what + ")";
}

void BonkRun::NoteStruck(std::string const& striker, ObjectGuid strikerGuid)
{
    m_lastStriker = striker;
    m_lastStrikerGuid = strikerGuid;
    if (m_state != STATE_RUNNING || IsPeriodicHit())
        return;
    m_struck = true;
    m_struckAtMs = m_totalMs;
}

void BonkRun::OnPeriodicDamage(uint32 spellId, uint32 damage)
{
    if (m_state != STATE_RUNNING)
        return;
    for (OwnedWeapon const& owned : m_weapons)
        if (owned.weapon.behavior == BONK_BEHAVIOR_LEECH && owned.weapon.spellId == spellId)
        {
            m_bleedHeal += damage * owned.weapon.behaviorValue / 100.0f;
            m_bleedHealSource = WeaponSupport(owned);
        }
    OnPriestPeriodic(spellId, damage);
}

void BonkRun::DropTraps(OwnedWeapon& owned, bool armed)
{
    BonkWeapon const& weapon = owned.weapon;
    uint32 const count = 1 + GetSpellCount(owned);
    int32 const lifetime = int32(BONK_TRAP_LIFETIME * GetWeaponCooldown(owned));
    TrapLook const* look = GetTrapLook(uint32(weapon.behaviorValue));
    Map* map = m_player->GetMap();

    float cx = m_player->GetPositionX();
    float cy = m_player->GetPositionY();
    float cz = m_player->GetPositionZ();
    float const ground = map->GetHeight(cx, cy, cz + 0.5f, true, BONK_TRAP_GROUND_SEARCH);
    if (ground > INVALID_HEIGHT)
        cz = ground;
    float const deploy = GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_DEPLOY);
    if (deploy > 0.0f)
    {
        std::vector<Creature*> const nearby = GetMobsInRange(BONK_TRAP_AWARE_RANGE);
        if (!nearby.empty())
        {
            float const reach = std::min(deploy, m_player->GetDistance2d(nearby.front()));
            float const angle = m_player->GetAngle(nearby.front());
            float dx = cx + reach * std::cos(angle);
            float dy = cy + reach * std::sin(angle);
            float dz = cz;
            map->GetWalkHitPosition(nullptr, cx, cy, cz, dx, dy, dz);
            cx = dx;
            cy = dy;
            cz = dz;
        }
    }

    float const startAngle = frand(0.0f, 2.0f * M_PI_F);
    for (uint32 i = 0; i < count; ++i)
    {
        float x = cx;
        float y = cy;
        float z = cz;
        if (i)
        {
            float const angle = startAngle + 2.0f * M_PI_F * i / count;
            float dx = x + BONK_TRAP_SPACING * std::cos(angle);
            float dy = y + BONK_TRAP_SPACING * std::sin(angle);
            float dz = z;
            map->GetWalkHitPosition(nullptr, x, y, z, dx, dy, dz);
            x = dx;
            y = dy;
            z = dz;
        }

        size_t out = 0;
        for (Trap const& trap : m_traps)
            if (trap.weaponId == weapon.id)
                ++out;
        if (out >= BONK_MAX_TRAPS)
            for (auto itr = m_traps.begin(); itr != m_traps.end(); ++itr)
                if (itr->weaponId == weapon.id)
                {
                    PutAwayTrap(*itr);
                    m_traps.erase(itr);
                    break;
                }

        Trap trap;
        trap.weaponId = weapon.id;
        trap.x = x;
        trap.y = y;
        trap.z = z;
        trap.armMs = armed ? 0 : BONK_TRAP_ARM_MS;
        trap.leftMs = lifetime;
        if (look)
            trap.prop = PlaceTrapProp(look->set, x, y, z);
        else if (GameObject* go = PlaceObject(uint32(weapon.behaviorValue), x, y, z, lifetime / IN_MILLISECONDS + 5))
            trap.object = go->GetObjectGuid();
        m_traps.push_back(trap);
    }
}

uint32 BonkRun::PlaceTrapProp(uint32 display, float x, float y, float z)
{
    uint32 const key = NextBonkAuraKey();
    SendBonkProp(m_player, key, display, x, y, z, 0.0f);
    return key;
}

void BonkRun::PutAwayTrap(Trap const& trap)
{
    if (trap.prop)
        SendBonkPropGone(m_player, trap.prop);
    else if (Map* map = m_player->FindMap())
        if (GameObject* go = map->GetGameObject(trap.object))
            go->Delete();
}

void BonkRun::ClearPendingTrapLooks()
{
    for (PendingCast const& cast : m_pendingCasts)
        if ((cast.releaseLook || cast.springTrap) && cast.prop)
            SendBonkPropGone(m_player, cast.prop);
    m_trapLookTimes.clear();
}

void BonkRun::ShowTrapSprung(OwnedWeapon const& owned, uint32 prop, float x, float y, float z)
{
    TrapLook const* look = GetTrapLook(uint32(owned.weapon.behaviorValue));
    if (prop)
        SendBonkPropGone(m_player, prop);
    if (!look || owned.weapon.HasFlag(BONK_WEAPON_FLAG_VIPERS) || !TakeRateSlot(m_trapLookTimes, BONK_TRAP_LOOKS_PER_SEC))
        return;
    PendingCast release;
    release.weaponId = owned.weapon.id;
    release.spellId = owned.weapon.spellId;
    release.releaseLook = true;
    release.prop = PlaceTrapProp(look->sprung, x, y, z);
    release.leftMs = int32(look->sprungMs);
    m_pendingCasts.push_back(release);
}

void BonkRun::UpdateTraps(uint32 diff)
{
    m_trapTimer += diff;
    if (m_trapTimer < BONK_TRAP_CHECK_MS)
        return;
    UpdateVipers();
    if (m_traps.empty())
    {
        m_trapTimer = 0;
        return;
    }
    int32 const elapsed = int32(m_trapTimer);
    m_trapTimer = 0;

    Map* map = m_player->GetMap();
    std::vector<Trap> sprung;
    for (auto itr = m_traps.begin(); itr != m_traps.end();)
    {
        itr->armMs -= elapsed;
        itr->leftMs -= elapsed;
        bool remove = itr->leftMs <= 0 || !FindOwned(itr->weaponId);
        bool springs = false;
        if (!remove && itr->armMs <= 0)
            for (ObjectGuid const& guid : GetEnemyGuids())
                if (Creature* mob = map->GetCreature(guid))
                    if (mob->IsAlive() && mob->GetDistance2d(itr->x, itr->y) <= BONK_TRAP_TRIGGER_RADIUS)
                    {
                        springs = remove = true;
                        break;
                    }
        if (!remove)
        {
            ++itr;
            continue;
        }
        if (springs)
            sprung.push_back(*itr);
        if (!springs || !itr->prop)
            PutAwayTrap(*itr);
        itr = m_traps.erase(itr);
    }

    for (Trap const& trap : sprung)
    {
        OwnedWeapon* owned = FindOwned(trap.weaponId);
        if (!owned)
        {
            PutAwayTrap(trap);
            continue;
        }
        if (trap.prop)
            ShowTrapSprung(*owned, trap.prop, trap.x, trap.y, trap.z);
        SpringTrap(*owned, trap.x, trap.y, trap.z);
    }
}

void BonkRun::SpringTrap(OwnedWeapon& owned, float x, float y, float z, float share, bool echo)
{
    BonkWeapon const& weapon = owned.weapon;
    SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(weapon.spellId);
    if (!spellInfo || !m_player->IsAlive())
        return;

    if (weapon.HasFlag(BONK_WEAPON_FLAG_SNAKES))
    {
        ReleaseSnakes(owned, x, y, z);
        return;
    }
    if (weapon.HasFlag(BONK_WEAPON_FLAG_VIPERS))
    {
        ReleaseVipers(owned, x, y, z);
        return;
    }

    FiringWeapon firing(m_player->GetBonkPlayer());
    float const radius = GetWeaponRadius(owned) * (1.0f + GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_TRAP_AREA) / 100.0f);
    ScaleRadius(spellInfo, radius);
    optional<int32> basePoints[MAX_EFFECT_INDEX];
    GetBasePoints(owned, spellInfo, share, basePoints);
    CastAtGround(m_player, spellInfo, basePoints, x, y, z);
    if (weapon.HasFlag(BONK_WEAPON_FLAG_VOLATILE) && !echo)
    {
        PendingCast blast;
        blast.weaponId = weapon.id;
        blast.spellId = weapon.spellId;
        blast.leftMs = BONK_VOLATILE_ECHO_MS;
        blast.volatileEcho = true;
        blast.x = x;
        blast.y = y;
        blast.z = z;
        m_pendingCasts.push_back(blast);
    }
    if (spellInfo->Id == BONK_SPELL_FROST_TRAP_AURA)
        PlayKitAt(ObjectGuid(), x, y, z, BONK_KIT_FROST_TRAP_SOUND, true);
    SpringEntrapment(owned, x, y, radius);
    if (m_mastery.Special(BONK_SPECIAL_FREEZING_WINDS) > 0.0f && GetRootWeapon(weapon) == BONK_WEAPON_BLIZZARD)
    {
        PendingCast winds;
        winds.weaponId = weapon.id;
        winds.spellId = weapon.spellId;
        winds.leftMs = int32(weapon.durationMs * GetWeaponDurationScale(owned));
        winds.freezingWinds = true;
        winds.x = x;
        winds.y = y;
        winds.z = z;
        m_pendingCasts.push_back(winds);
    }
    if (weapon.HasFlag(BONK_WEAPON_FLAG_CLUSTER_BOMBS))
        ScatterBomblets(owned, spellInfo, x, y, z);
    if (weapon.HasFlag(BONK_WEAPON_FLAG_SHATTER))
        QueueShatter(owned, x, y, z);

    if (weapon.damageEffectIndex < 0 && !weapon.weaponDamage && weapon.tickMs && weapon.durationMs)
    {
        uint32 const length = uint32(weapon.durationMs * GetWeaponDurationScale(owned));
        uint32 const every = std::max(200u, uint32(weapon.tickMs / GetWeaponHasteRate(owned)));
        for (uint32 at = 0; at < length; at += every)
        {
            PendingCast tick;
            tick.weaponId = weapon.id;
            tick.spellId = weapon.spellId;
            tick.leftMs = int32(at);
            tick.field = true;
            tick.x = x;
            tick.y = y;
            tick.z = z;
            m_pendingCasts.push_back(tick);
        }
    }

    SpellEntry const* altInfo = weapon.altSpellId ? sSpellMgr.GetSpellEntry(weapon.altSpellId) : nullptr;
    if (!altInfo)
        return;
    if (altInfo->EffectImplicitTargetA[EFFECT_INDEX_0] == TARGET_UNIT_ENEMY)
    {
        Map* map = m_player->GetMap();
        for (ObjectGuid const& guid : GetEnemyGuids())
            if (Creature* mob = map->GetCreature(guid))
                if (mob->IsAlive() && mob->GetDistance2d(x, y) <= radius)
                    m_player->CastSpell(mob, altInfo, true);
        return;
    }
    ScaleRadius(altInfo, radius);
    optional<int32> altPoints[MAX_EFFECT_INDEX];
    GetBasePoints(owned, altInfo, weapon.altDamage, altPoints);
    CastAtGround(m_player, altInfo, altPoints, x, y, z);
}

void BonkRun::DespawnTraps()
{
    for (Trap const& trap : m_traps)
        PutAwayTrap(trap);
    m_traps.clear();
}

void BonkRun::ThrowTrap(OwnedWeapon& owned, float x, float y, float z)
{
    TrapLook const* look = GetTrapLook(uint32(owned.weapon.behaviorValue));
    if (!look)
    {
        SpringTrap(owned, x, y, z);
        return;
    }

    PendingCast spring;
    spring.weaponId = owned.weapon.id;
    spring.spellId = owned.weapon.spellId;
    spring.leftMs = int32(BONK_THROWN_TRAP_ARM_MS);
    spring.springTrap = true;
    spring.prop = PlaceTrapProp(look->set, x, y, z);
    spring.x = x;
    spring.y = y;
    spring.z = z;
    m_pendingCasts.push_back(spring);
}

void BonkRun::DealSpellHit(SpellEntry const* spellInfo, Unit* target, float damage, Unit* caster, bool forceCrit)
{
    if (!caster)
        caster = m_player;
    if (!spellInfo || !target || !target->IsAlive() || damage <= 0.0f || !m_player->IsAlive() || !caster->IsInWorld())
        return;

    SpellNonMeleeDamage hit(caster, target, spellInfo->Id, SpellSchools(spellInfo->School));
    Unit const* summon = caster == m_player ? nullptr : caster;
    bool const crit = forceCrit || (spellInfo->CanCrit() && roll_chance_f(GetCritChance(spellInfo, target, summon)));
    caster->CalculateSpellDamage(&hit, damage, spellInfo, EFFECT_INDEX_0, BASE_ATTACK, nullptr, crit);
    target->CalculateAbsorbResistBlock(caster, &hit, spellInfo, BASE_ATTACK, nullptr);
    caster->DealDamageMods(target, hit.damage, &hit.absorb);
    caster->SendSpellNonMeleeDamageLog(&hit);
    caster->DealSpellDamage(&hit, true);
}

std::vector<Creature*> BonkRun::GetMobsInLine(OwnedWeapon const& owned, float range, float angle) const
{
    float const halfWidth = BONK_LINE_WIDTH * GetWeaponArea(owned) * GetSteadyWidth(owned) / 2.0f;
    float const dx = std::cos(angle), dy = std::sin(angle);
    std::vector<Creature*> mobs = GetMobsInRange(range);
    mobs.erase(std::remove_if(mobs.begin(), mobs.end(), [&](Creature* mob)
    {
        float const x = mob->GetPositionX() - m_player->GetPositionX();
        float const y = mob->GetPositionY() - m_player->GetPositionY();
        float const along = x * dx + y * dy;
        float const side = std::fabs(x * dy - y * dx);
        return along < 0.0f || side > halfWidth + mob->GetObjectBoundingRadius();
    }), mobs.end());
    return mobs;
}

bool BonkRun::Howl(OwnedWeapon& owned)
{
    Creature* wolf = owned.pets.empty() ? nullptr : m_player->GetMap()->GetCreature(owned.pets.front());
    if (!wolf || !wolf->IsAlive() || GetMobsInRange(BONK_PET_HUNT_RANGE).empty())
        return false;

    wolf->HandleEmote(EMOTE_ONESHOT_ROAR);
    OnTalentHowl(wolf);
    uint32 const duration = uint32(owned.weapon.durationMs * GetWeaponDurationScale(owned));
    if (duration > RemainingAuraMs(BONK_SPELL_HOWL_FRENZY))
        ApplyTimedAura(BONK_SPELL_HOWL_FRENZY, duration);
    for (OwnedWeapon& other : m_weapons)
        if (other.weapon.behavior == BONK_BEHAVIOR_PET)
            UpdatePets(other);
    DressSnakes();
    if (owned.weapon.HasFlag(BONK_WEAPON_FLAG_HOWL_BEASTS))
        CallHowlBeast(owned);
    DressBeasts();
    return true;
}

float BonkRun::GetFrenzyDamage() const
{
    float upgrades = 0.0f;
    for (OwnedWeapon const& owned : m_weapons)
        if (owned.weapon.behavior == BONK_BEHAVIOR_WRATH)
            upgrades += GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_FRENZY) / 100.0f;
    if (m_mastery.Has(BONK_CAPSTONE_BESTIAL_WRATH))
        return GetBestialWrathFrenzy() * (IsHowlFrenzied() ? GetBestialWrathHowl() + upgrades : 1.0f);
    return BONK_FRENZY_DAMAGE + upgrades;
}

bool BonkRun::IsHowlFrenzied() const
{
    return m_player->HasAura(BONK_SPELL_HOWL_FRENZY);
}

bool BonkRun::IsKeywordAbilityHit(OwnedWeapon const& owned, SpellEntry const* spell) const
{
    if (!spell)
        return false;
    if (spell->Id == BONK_SPELL_SWIPE)
        return true;
    BonkPetFamily const* family = owned.weapon.behavior == BONK_BEHAVIOR_PET ? GetPetFamily(owned) : nullptr;
    if (!family)
        return false;
    return std::any_of(family->abilities.begin(), family->abilities.end(), [this, &owned, spell](BonkPetAbility const& ability)
    {
        return ability.stacks > 0 && (ability.spellId == spell->Id || GetWarlockAbilitySpell(owned, ability.spellId) == spell->Id);
    });
}

bool BonkRun::HasStackingPetAbility(OwnedWeapon const& owned) const
{
    BonkPetFamily const* family = owned.weapon.behavior == BONK_BEHAVIOR_PET ? GetPetFamily(owned) : nullptr;
    return family && std::any_of(family->abilities.begin(), family->abilities.end(), [](BonkPetAbility const& ability) { return ability.stacks > 0; });
}

void BonkRun::ApplySummonHitKeyword(Unit* summon, Unit* victim, SpellEntry const* spell)
{
    OwnedWeapon const* owned = FindSummonOwner(summon);
    if (!owned || !victim->IsAlive() || IsKeywordAbilityHit(*owned, spell))
        return;
    PendingKeyword keyword;
    if (!GetWeaponKeyword(*owned, keyword))
        return;
    bool const plainBite = !spell && owned->weapon.behavior == BONK_BEHAVIOR_PET && !HasStackingPetAbility(*owned);
    if (!plainBite)
        keyword.stacks = BONK_SUMMON_HIT_KEYWORD_STACKS;
    keyword.mob = victim->GetObjectGuid();
    m_pendingKeywords.push_back(keyword);
}

void BonkRun::OnPetBite(Creature* pet, Unit* victim)
{
    if (m_state != STATE_RUNNING || !pet || !victim)
        return;
    OnShamanPetBite(pet, victim);
    OnPriestPetBite(pet, victim);
    MarkFromPack(pet, victim);
    if (!IsPetFrenzied() || !IsSummon(pet))
        return;

    for (OwnedWeapon const& owned : m_weapons)
        if (owned.weapon.behavior == BONK_BEHAVIOR_PET && std::find(owned.pets.begin(), owned.pets.end(), pet->GetObjectGuid()) != owned.pets.end())
        {
            QueuePetCleave(owned, pet, victim);
            return;
        }
    for (Snake const& released : m_snakes)
        if (released.guid == pet->GetObjectGuid())
        {
            if (OwnedWeapon const* owned = FindOwned(released.weaponId))
                QueuePetCleave(*owned, pet, victim);
            return;
        }
    for (Beast const& beast : m_beasts)
        if (beast.guid == pet->GetObjectGuid())
        {
            if (beast.kind != BEAST_SPECTRAL)
                if (OwnedWeapon const* owned = FindOwned(beast.weaponId))
                    QueuePetCleave(*owned, pet, victim);
            return;
        }
}

void BonkRun::MarkFromPack(Creature* pet, Unit* victim)
{
    Creature* prey = victim->ToCreature();
    if (!prey || !prey->IsAlive() || !IsSummon(pet) || !HasBehavior(BONK_BEHAVIOR_WRATH) || GetKeywordStacks(prey, BONK_KEYWORD_HUNTERS_MARK))
        return;
    ApplyKeyword(prey, BONK_KEYWORD_HUNTERS_MARK, 1);
}

void BonkRun::OnHunterDamage(uint32 root, Unit* victim)
{
    if (root == BONK_WEAPON_VOLLEY)
    {
        if (m_explosiveArrows < BONK_MAX_EXPLOSIVE_ARROWS && FindOwnedByRoot(BONK_WEAPON_AIMED_SHOT) && ++m_volleyHits >= BONK_VOLLEY_HITS_PER_ARROW)
        {
            m_volleyHits = 0;
            ++m_explosiveArrows;
        }
        return;
    }
    if (root != BONK_WEAPON_AIMED_SHOT || !m_explosiveArrows || m_totalMs < m_explosiveArrowReadyMs || !victim->IsCreature())
        return;
    OwnedWeapon const* aimed = FindOwnedByRoot(BONK_WEAPON_AIMED_SHOT);
    if (!aimed)
        return;
    --m_explosiveArrows;
    m_explosiveArrowReadyMs = m_totalMs + BONK_EXPLOSIVE_ARROW_GAP_MS;
    PendingCast arrow;
    arrow.weaponId = aimed->weapon.id;
    arrow.spellId = aimed->weapon.spellId;
    arrow.explosiveArrow = true;
    victim->GetPosition(arrow.x, arrow.y, arrow.z);
    m_pendingCasts.push_back(arrow);
}

void BonkRun::ExplodeArrow(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    ShowKitAt(BONK_KIT_EXPLOSIVE_ARROW, cast.x, cast.y, cast.z);
    float const damage = GetWeaponDamage(owned);
    for (Creature* mob : GetMobsNear(cast.x, cast.y, BONK_EXPLOSIVE_ARROW_RADIUS * GetWeaponArea(owned)))
        if (mob->IsAlive())
            DealShamanHit(spellInfo, owned.weapon.spellId, mob, damage);
}

void BonkRun::QueuePetCleave(OwnedWeapon const& owned, Creature* pet, Unit* victim)
{
    PendingCast cleave;
    cleave.weaponId = owned.weapon.id;
    cleave.spellId = owned.weapon.spellId;
    cleave.petCleave = true;
    cleave.source = pet->GetObjectGuid();
    cleave.target = victim->GetObjectGuid();
    m_pendingCasts.push_back(cleave);
}

float BonkRun::GetPetCleaveDamage(OwnedWeapon const& owned) const
{
    if (owned.weapon.HasFlag(BONK_WEAPON_FLAG_SNAKES))
        return GetWeaponDamage(owned) * GetFrenzyDamage();
    BonkPetFamily const* family = GetPetFamily(owned);
    if (!family)
        return 0.0f;
    return GetWeaponDamage(owned) * family->attackMs / float(std::max(500u, owned.weapon.tickMs)) * GetFrenzyDamage();
}

void BonkRun::UpdateDefensive(uint32 diff)
{
    m_defensiveTimer = std::max(0, m_defensiveTimer - int32(diff));
    if (m_defensiveTimer || m_player->GetClass() != CLASS_HUNTER || !m_player->IsAlive() || m_player->GetHealthPercent() >= BONK_DETERRENCE_HEALTH)
        return;

    BonkPlayer::SpellTweak& tweak = m_player->GetBonkPlayer()->TweakSpell(BONK_SPELL_DETERRENCE);
    tweak.durationMs = BONK_DETERRENCE_MS;
    tweak.durationScale = 1.0f;
    m_player->CastCustomSpell(m_player, BONK_SPELL_DETERRENCE, 0, BONK_DETERRENCE_DODGE, {}, true);
    m_defensiveTimer = BONK_DETERRENCE_COOLDOWN_MS;
}

void BonkRun::UpdatePets(OwnedWeapon& owned)
{
    BonkWeapon const& weapon = owned.weapon;
    bool const wolf = weapon.behavior == BONK_BEHAVIOR_WRATH;
    bool const plague = weapon.HasFlag(BONK_WEAPON_FLAG_PLAGUE);
    BonkPetFamily const* family = wolf ? nullptr : GetPetFamily(owned);
    uint32 const entry = wolf ? uint32(weapon.behaviorValue) : !family ? 0 : plague ? BONK_PLAGUE_BEAST : family->entry;
    uint32 const attackMs = wolf ? BONK_WOLF_ATTACK_MS : family ? family->attackMs : 0;
    bool const shifting = entry && weapon.HasFlag(BONK_WEAPON_FLAG_ELEMENTAL_SHIFT);
    uint32 const summonEntry = shifting ? BONK_HYBRID_ELEMENTAL : entry;
    Map* map = m_player->GetMap();
    owned.pets.erase(std::remove_if(owned.pets.begin(), owned.pets.end(), [this, map](ObjectGuid const& guid)
    {
        Creature* pet = map->GetCreature(guid);
        if (pet && pet->IsAlive())
            return false;
        if (pet)
            pet->DespawnOrUnsummon();
        m_petStates.erase(guid);
        return true;
    }), owned.pets.end());

    if (entry)
    {
        for (ObjectGuid& guid : owned.pets)
        {
            Creature* old = map->GetCreature(guid);
            if (old && shifting && old->GetEntry() == summonEntry)
                ShiftElemental(old, entry);
            if (!old || old->GetEntry() == summonEntry)
                continue;
            float x, y, z;
            old->GetPosition(x, y, z);
            m_petStates.erase(guid);
            Creature* risen = SummonPet(owned, summonEntry, x, y, z, old->GetOrientation());
            if (risen && shifting)
                ShiftElemental(risen, entry);
            old->DespawnOrUnsummon();
            guid = risen ? risen->GetObjectGuid() : ObjectGuid();
            if (!risen || !plague)
                continue;
            PendingCast rise;
            rise.kit = BONK_KIT_PLAGUE_RISE;
            rise.leftMs = BONK_PLAGUE_RISE_DELAY_MS;
            rise.target = guid;
            rise.x = x;
            rise.y = y;
            rise.z = z;
            m_pendingCasts.push_back(rise);
        }
        owned.pets.erase(std::remove(owned.pets.begin(), owned.pets.end(), ObjectGuid()), owned.pets.end());
    }

    uint32 const wanted = entry ? std::min(wolf ? 1u : GetWeaponTargets(owned) + GetShamanExtraPets(owned), GetSummonRoom(owned)) : 0;
    if (owned.pets.size() < wanted && m_player->IsAlive())
    {
        float const angle = frand(0.0f, 2.0f * M_PI_F);
        float x = m_player->GetPositionX() + 2.0f * std::cos(angle);
        float y = m_player->GetPositionY() + 2.0f * std::sin(angle);
        float z = m_player->GetPositionZ();
        if (weapon.HasFlag(BONK_WEAPON_FLAG_TOTEM))
            GetTotemSlot(CountOwnedTotems(), x, y, z);
        else
            m_player->GetMap()->GetWalkHitPosition(nullptr, m_player->GetPositionX(), m_player->GetPositionY(), m_player->GetPositionZ(), x, y, z);
        if (Creature* pet = SummonPet(owned, summonEntry, x, y, z, m_player->GetOrientation()))
        {
            if (shifting)
                ShiftElemental(pet, entry);
            if (!weapon.HasFlag(BONK_WEAPON_FLAG_TOTEM))
                pet->GetMotionMaster()->MoveFollow(m_player, 2.0f, angle);
            owned.pets.push_back(pet->GetObjectGuid());
            if (uint32 const kit = GetDruidSummonKit(owned))
                PlayKitAt(ObjectGuid(), x, y, z, kit, true);
        }
    }
    while (owned.pets.size() > wanted)
    {
        if (Creature* pet = map->GetCreature(owned.pets.back()))
            pet->DespawnOrUnsummon();
        owned.pets.pop_back();
    }
    if (!entry)
        return;

    uint32 const spellMs = std::max(500u, weapon.tickMs);
    bool const frenzied = !wolf && IsPetFrenzied();
    float const bite = wolf ? GetWeaponDamage(owned) * attackMs / float(spellMs) : GetPetBiteDamage(owned, *family);
    float const damage = bite * (frenzied ? GetFrenzyDamage() : 1.0f);
    float const pace = GetWeaponCooldown(owned) / float(std::max(1u, weapon.cooldownMs));
    uint32 const swing = std::max(300u, uint32(attackMs * pace));
    float const baseScale = wolf ? BONK_WOLF_SCALE : family->scale * (weapon.behaviorValue > 0.0f ? weapon.behaviorValue : 1.0f);
    float const scale = weapon.HasFlag(BONK_WEAPON_FLAG_TOTEM) ? baseScale * GetSummonReach(owned) : GetSummonLookScale(owned, baseScale);
    float const speed = GetSummonSpeedRate(GetStat(BONK_PASSIVE_MOVE_SPEED));
    for (ObjectGuid const& guid : owned.pets)
        if (Creature* pet = map->GetCreature(guid))
        {
            if (pet->GetBaseRunSpeedRate() != speed)
                pet->SetBaseSpeedRate(MOVE_RUN, speed);
            pet->SetBaseWeaponDamage(BASE_ATTACK, MINDAMAGE, damage * 0.9f);
            pet->SetBaseWeaponDamage(BASE_ATTACK, MAXDAMAGE, damage * 1.1f);
            pet->UpdateDamagePhysical(BASE_ATTACK);
            pet->SetAttackTime(BASE_ATTACK, swing);
            if (pet->GetInvincibilityHpThreshold() != pet->GetMaxHealth())
            {
                pet->SetHealth(pet->GetMaxHealth());
                pet->SetInvincibilityHpThreshold(pet->GetMaxHealth());
            }
            float const grown = scale * GetConsumedGrowth(guid);
            if (pet->GetObjectScale() != grown)
            {
                pet->SetObjectScale(grown);
                pet->UpdateModelData();
            }
            if (weapon.altSpellId && !pet->HasAura(weapon.altSpellId))
                pet->AddAura(weapon.altSpellId, ADD_AURA_PERMANENT);
            if (IsPlanted(weapon))
                PlantHydra(pet);
            if (plague && !pet->HasAura(BONK_SPELL_PLAGUE_LOOK))
                pet->AddAura(BONK_SPELL_PLAGUE_LOOK, ADD_AURA_PERMANENT);
            if (frenzied && !pet->HasAura(BONK_SPELL_BESTIAL_WRATH))
                pet->AddAura(BONK_SPELL_BESTIAL_WRATH);
            else if (!frenzied && pet->HasAura(BONK_SPELL_BESTIAL_WRATH))
                pet->RemoveAurasDueToSpell(BONK_SPELL_BESTIAL_WRATH);
        }
    ResendShownDamage(owned);
}

void BonkRun::ResendShownDamage(OwnedWeapon const& owned) const
{
    if (owned.shownDamage == DescribeShownDamage(owned))
        return;
    uint32 index = 0;
    for (OwnedWeapon const& held : m_weapons)
    {
        ++index;
        if (&held == &owned)
        {
            SendWeaponInfo(index, owned);
            return;
        }
    }
}

bool BonkRun::IsSummon(Unit const* unit) const
{
    if (!unit || !unit->IsCreature())
        return false;
    for (OwnedWeapon const& owned : m_weapons)
        if (std::find(owned.pets.begin(), owned.pets.end(), unit->GetObjectGuid()) != owned.pets.end())
            return true;
    return IsSnake(unit->GetObjectGuid()) || IsBeast(unit->GetObjectGuid()) || IsSkeleton(unit->GetObjectGuid()) || IsWarlockMinion(unit->GetObjectGuid());
}

Creature* BonkRun::SummonGlyphHelper(uint32 entry, float x, float y, float z, float orientation)
{
    s_nextHelperLevel = m_player->GetLevel();
    Creature* helper = m_player->SummonCreature(entry, x, y, z, orientation, TEMPSUMMON_TIMED_DESPAWN, BONK_OBJECT_LIFETIME_SEC * IN_MILLISECONDS,
        false, 0, &InstallPetAI);
    if (!helper)
        return nullptr;
    helper->SetOwnerGuid(m_player->GetObjectGuid());
    helper->SetFactionTemplateId(m_player->GetFactionTemplateId());
    helper->SetFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_IMMUNE_TO_PLAYER);
    return helper;
}

Creature* BonkRun::SummonPet(OwnedWeapon const& owned, uint32 entry, float x, float y, float z, float orientation)
{
    s_nextHelperLevel = m_player->GetLevel();
    Creature* pet = m_player->SummonCreature(entry, x, y, z, orientation, TEMPSUMMON_TIMED_DESPAWN, BONK_OBJECT_LIFETIME_SEC * IN_MILLISECONDS,
        false, 0, &InstallPetAI);
    if (!pet)
        return nullptr;
    pet->SetOwnerGuid(m_player->GetObjectGuid());
    pet->SetUInt32Value(UNIT_CREATED_BY_SPELL, owned.weapon.spellId);
    pet->SetFactionTemplateId(m_player->GetFactionTemplateId());
    pet->SetFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_IMMUNE_TO_PLAYER);
    DressWarlockPet(owned, pet);
    if (IsPlanted(owned.weapon))
        PlantHydra(pet);
    if (m_paused)
        HoldPet(pet, true, IsPlanted(owned.weapon));
    return pet;
}

float BonkRun::GetPetRunSpeed() const
{
    return GetSummonSpeedRate(GetStat(BONK_PASSIVE_MOVE_SPEED));
}

uint32 BonkRun::GetWantedSummons(OwnedWeapon const& owned)
{
    if (owned.weapon.behavior == BONK_BEHAVIOR_WRATH)
        return 1;
    if (owned.weapon.behavior != BONK_BEHAVIOR_PET)
        return 0;
    return GetWeaponTargets(owned) + GetShamanExtraPets(owned) + GetDruidExtraPets(owned);
}

uint32 BonkRun::GetSummonRoom(OwnedWeapon const& owned)
{
    std::vector<std::pair<OwnedWeapon const*, uint32>> wants;
    for (OwnedWeapon const& other : m_weapons)
        if (uint32 const wanted = GetWantedSummons(other))
            wants.emplace_back(&other, wanted);

    std::vector<uint32> given(wants.size(), 0);
    uint32 left = BONK_MAX_SUMMONS;
    for (bool handedOut = true; left && handedOut;)
    {
        handedOut = false;
        for (size_t i = 0; i < wants.size() && left; ++i)
            if (given[i] < wants[i].second)
            {
                ++given[i];
                --left;
                handedOut = true;
            }
    }
    for (size_t i = 0; i < wants.size(); ++i)
        if (wants[i].first == &owned)
            return given[i];
    return 0;
}

float BonkRun::GetSummonGrowth(OwnedWeapon const& owned) const
{
    float const growth = GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_PET_SIZE);
    return std::min(growth, BONK_MAX_AREA);
}

float BonkRun::GetSummonReach(OwnedWeapon const& owned) const
{
    return 1.0f + CurveStat(GetSummonGrowth(owned) + GetTalentReach(owned), BONK_MAX_AREA) / 100.0f;
}

float BonkRun::GetSummonLookScale(OwnedWeapon const& owned, float base) const
{
    float const growth = std::min(GetSummonGrowth(owned) * BONK_SUMMON_LOOK_GROWTH, BONK_MAX_SUMMON_LOOK_GROWTH);
    return base * (1.0f + growth / 100.0f);
}

BonkPetFamily const* BonkRun::GetPetFamily(OwnedWeapon const& owned) const
{
    if (uint32 const warlockFamily = GetWarlockPetFamily(owned))
        return sBonkMgr.GetPetFamily(warlockFamily);
    if (uint32 const druidFamily = GetDruidPetFamily(owned))
        return sBonkMgr.GetPetFamily(druidFamily);
    uint32 const classMask = owned.weapon.classMask;
    if (classMask & (1 << (CLASS_WARLOCK - 1)))
        return nullptr;
    if (classMask & (1 << (CLASS_SHAMAN - 1)))
        return sBonkMgr.GetPetFamily(GetShamanPetFamily(owned));
    if (classMask & (1 << (CLASS_PRIEST - 1)))
        return sBonkMgr.GetPetFamily(GetPriestPetFamily(owned));
    return sBonkMgr.GetPetFamily(classMask & (1 << (CLASS_MAGE - 1)) ? GetElementalFamily() : BONK_PET_FAMILY_CAT);
}

float BonkRun::GetPetBiteDamage(OwnedWeapon const& owned, BonkPetFamily const& family) const
{
    float rate = IN_MILLISECONDS / float(family.attackMs);
    for (BonkPetAbility const& ability : family.abilities)
        if (ability.kind != BONK_PET_ABILITY_DASH)
            rate += ability.damage * IN_MILLISECONDS / float(ability.cooldownMs);
    uint32 const spellMs = std::max(500u, owned.weapon.tickMs);
    return GetWeaponDamage(owned) * IN_MILLISECONDS / float(spellMs) / rate * GetDemonDamageScale() * GetSummonTalentScale(owned);
}

float BonkRun::GetSummonTalentScale(OwnedWeapon const& owned) const
{
    auto talentDamage = m_mastery.spellDamage.find(GetRootWeapon(owned.weapon));
    float const talentPercent = talentDamage != m_mastery.spellDamage.end() ? talentDamage->second : 0.0f;
    return 1.0f + talentPercent / 100.0f;
}

void BonkRun::StartPetAttack(OwnedWeapon const& owned, Creature* pet, Creature* target)
{
    BonkPetFamily const* family = GetPetFamily(owned);
    if (!family || !IsCasterPetFamily(*family))
    {
        pet->AI()->AttackStart(target);
        return;
    }
    if (!pet->Attack(target, false))
        return;
    pet->SetInCombatWith(target);
    pet->GetMotionMaster()->MoveChase(target, BONK_CASTER_PET_DISTANCE);
}

void BonkRun::UsePetAbilities(OwnedWeapon& owned, Creature* pet, Creature* prey)
{
    BonkPetFamily const* family = GetPetFamily(owned);
    if (!family || family->abilities.empty() || !prey->IsAlive())
        return;

    PetState& state = m_petStates[pet->GetObjectGuid()];
    state.readyAtMs.resize(family->abilities.size(), 0);
    uint32 const now = WorldTimer::getMSTime();
    float const pace = GetWeaponCooldown(owned) / float(std::max(1u, owned.weapon.cooldownMs));
    for (size_t i = 0; i < family->abilities.size(); ++i)
    {
        BonkPetAbility const& ability = family->abilities[i];
        if (ability.kind == BONK_PET_ABILITY_PULSE && int32(now - state.readyAtMs[i]) >= 0 && PetPulse(owned, pet, ability))
            state.readyAtMs[i] = now + uint32(ability.cooldownMs * pace);
    }
    if (!prey->IsAlive())
        return;

    bool const inReach = pet->CanReachWithMeleeAutoAttack(prey) || IsPetInRunningReach(pet, prey);
    for (size_t i = 0; i < family->abilities.size(); ++i)
    {
        BonkPetAbility const& ability = family->abilities[i];
        if (int32(now - state.readyAtMs[i]) < 0)
            continue;
        bool const strikeReach = ability.value > 0.0f ? pet->IsWithinDistInMap(prey, ability.value) && pet->IsWithinLOSInMap(prey) : inReach;
        if (ability.kind == BONK_PET_ABILITY_STRIKE && strikeReach)
        {
            Creature* struck = PickHydraHeadTarget(*family, pet, prey, i, ability.value);
            if (owned.weapon.HasFlag(BONK_WEAPON_FLAG_TOTEM))
                struck = PickBoltTarget(pet, struck, ability.value);
            if (!struck)
                return;
            PetStrike(owned, pet, struck, ability);
            StrikeSearingTotemSecondTarget(owned, *family, pet, prey, ability);
            state.readyAtMs[i] = now + uint32(ability.cooldownMs * pace * GetClawRate(owned));
            OnWarlockPetStrike(owned, pet, prey, uint32(i));
            OnDruidPetStrike(owned, pet, prey);
            return;
        }
        if (ability.kind == BONK_PET_ABILITY_CONE && strikeReach && PetPulse(owned, pet, ability, prey))
        {
            state.readyAtMs[i] = now + uint32(ability.cooldownMs * pace);
            return;
        }
        if (ability.kind == BONK_PET_ABILITY_DASH && !pet->IsWithinDistInMap(prey, BONK_PET_DASH_RANGE))
        {
            if (SpellAuraHolder* holder = pet->AddAura(ability.spellId))
            {
                int32 const lasts = std::max(500, int32(ability.value));
                holder->SetAuraMaxDuration(lasts);
                holder->SetAuraDuration(lasts);
                holder->RefreshHolder();
            }
            state.readyAtMs[i] = now + uint32(ability.cooldownMs * pace);
        }
    }
}

void BonkRun::PetStrike(OwnedWeapon& owned, Creature* pet, Creature* prey, BonkPetAbility const& ability)
{
    BonkPetFamily const* family = GetPetFamily(owned);
    if (!family)
        return;

    float const frenzy = IsPetFrenzied() ? GetFrenzyDamage() : 1.0f;
    int32 const damage = std::max(1, int32(std::min(MaxHitDamage, GetPetBiteDamage(owned, *family) * ability.damage * frenzy * GetWarlockPetStrikeScale(owned, prey))));
    pet->SetFacingToObject(prey);
    uint32 const abilitySpell = GetWarlockAbilitySpell(owned, ability.spellId);
    SpellEntry const* abilityInfo = sSpellMgr.GetSpellEntry(abilitySpell);
    if (owned.weapon.HasFlag(BONK_WEAPON_FLAG_TOTEM) && abilityInfo)
    {
        ObjectGuid const petGuid = pet->GetObjectGuid();
        LaunchBolt(pet, abilityInfo, prey, float(damage), [this, abilityInfo, damage, petGuid](Creature* struck)
        {
            Unit* source = struck->GetMap()->GetCreature(petGuid);
            DealSpellHit(abilityInfo, struck, float(damage), source ? source : static_cast<Unit*>(m_player));
        });
    }
    else
        pet->CastCustomSpell(prey, abilitySpell, damage, {}, {}, true);

    OnTalentPetStrike(owned, pet, prey, abilityInfo, damage);

    PendingKeyword keyword;
    uint32 stacks = owned.weapon.HasFlag(BONK_WEAPON_FLAG_PLAGUE) ? BONK_PLAGUE_CLAW_STACKS : ability.stacks;
    if (stacks && GetRootWeapon(owned.weapon) == BONK_WEAPON_CALL_PET)
        stacks += uint32(m_mastery.Special(BONK_SPECIAL_PACK_TACTICS));
    auto talentStacks = m_mastery.spellStacks.find(GetRootWeapon(owned.weapon));
    if (stacks && talentStacks != m_mastery.spellStacks.end())
        stacks += uint32(talentStacks->second);
    if (ability.stacks && prey->IsAlive() && (GetWeaponKeyword(owned, keyword) || GetPetAbilityKeyword(owned, ability, keyword)))
        ApplyKeyword(prey, keyword.keyword, stacks + uint32(GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_STACKS)), keyword.durationMs,
            keyword.damageScale, keyword.spellId);
}

bool BonkRun::PetPulse(OwnedWeapon& owned, Creature* pet, BonkPetAbility const& ability, Creature* coneTarget)
{
    BonkPetFamily const* family = GetPetFamily(owned);
    SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(ability.spellId);
    if (!family || !spellInfo)
        return false;

    float const radius = ability.value * GetSummonReach(owned);
    std::vector<Creature*> mobs = GetMobsNear(pet->GetPositionX(), pet->GetPositionY(), radius);
    if (coneTarget)
    {
        pet->SetFacingToObject(coneTarget);
        bool const allAround = IsWarlockFullLash(owned);
        mobs.erase(std::remove_if(mobs.begin(), mobs.end(), [pet, coneTarget, allAround](Creature* mob)
        {
            return mob != coneTarget && !allAround && !pet->HasInArc(mob, BONK_PET_CONE_ARC);
        }), mobs.end());
        ShowStrike(pet, spellInfo, coneTarget);
    }
    if (mobs.empty())
        return false;

    if (ability.kit)
        pet->SendPlaySpellVisualKit(ability.kit);

    float const frenzy = IsPetFrenzied() ? GetFrenzyDamage() : 1.0f;
    uint32 const root = GetRootWeapon(owned.weapon);
    float const hit = std::max(1.0f, GetPetBiteDamage(owned, *family) * ability.damage * frenzy);
    PendingKeyword keyword;
    bool const applies = ability.stacks && (GetWeaponKeyword(owned, keyword) || GetPetAbilityKeyword(owned, ability, keyword));
    auto talentStacks = m_mastery.spellStacks.find(root);
    uint32 const stacks = ability.stacks + uint32(GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_STACKS)) +
        (talentStacks != m_mastery.spellStacks.end() ? uint32(talentStacks->second) : 0);
    for (Creature* mob : mobs)
    {
        if (!pet->IsWithinLOSInMap(mob))
            continue;
        DealSpellHit(spellInfo, mob, hit, pet);
        if (applies && mob->IsAlive())
            ApplyKeyword(mob, keyword.keyword, stacks, keyword.durationMs, keyword.damageScale, keyword.spellId);
    }
    OnShamanPetPulse(owned, pet, radius);
    return true;
}

bool BonkRun::Pounce(OwnedWeapon& owned, Creature* pet, Creature* prey)
{
    BonkPetFamily const* family = GetPetFamily(owned);
    if (!family)
        return false;

    PetState& state = m_petStates[pet->GetObjectGuid()];
    state.readyAtMs.resize(family->abilities.size(), 0);
    uint32 const now = WorldTimer::getMSTime();
    for (size_t i = 0; i < family->abilities.size(); ++i)
    {
        BonkPetAbility const& ability = family->abilities[i];
        if (ability.kind != BONK_PET_ABILITY_POUNCE || int32(now - state.readyAtMs[i]) < 0 ||
            pet->IsWithinDistInMap(prey, ability.value) || !pet->IsWithinLOSInMap(prey))
            continue;

        float const flightMs = pet->GetDistance(prey) / BONK_POUNCE_SPEED * IN_MILLISECONDS;
        float x, y, z, o;
        if (!prey->ExtrapolateMovement(prey->m_movementInfo, uint32(flightMs), x, y, z, o))
            prey->GetPosition(x, y, z);
        float const reach = pet->GetCombatReachToTarget(prey, false, 0.0f, true) / 2.0f;
        float const dx = pet->GetPositionX() - x;
        float const dy = pet->GetPositionY() - y;
        float const length = std::sqrt(dx * dx + dy * dy);
        if (length > reach)
        {
            x += dx / length * reach;
            y += dy / length * reach;
        }
        pet->AttackStop();
        pet->GetMotionMaster()->Clear(false);
        pet->GetMotionMaster()->MovePoint(0, x, y, z, MOVE_PATHFINDING | MOVE_RUN_MODE | MOVE_FORCE_DESTINATION, BONK_POUNCE_SPEED);
        uint32 const landMs = (pet->movespline->Finalized() ? uint32(flightMs) : uint32(pet->movespline->Duration())) + 50;

        float const pace = GetWeaponCooldown(owned) / float(std::max(1u, owned.weapon.cooldownMs));
        state.busyUntilMs = now + landMs;
        state.readyAtMs[i] = now + uint32(ability.cooldownMs * pace);

        PendingCast land;
        land.weaponId = owned.weapon.id;
        land.spellId = owned.weapon.spellId;
        land.leftMs = int32(landMs);
        land.pounce = true;
        land.source = pet->GetObjectGuid();
        land.target = prey->GetObjectGuid();
        m_pendingCasts.push_back(land);
        return true;
    }
    return false;
}

uint32 BonkRun::GetPetPreyRank(Creature const* mob) const
{
    bool const isTreasureGoblin = m_miniEventActive && m_miniEvent.type == BONK_MINI_EVENT_GOBLIN && mob->GetObjectGuid() == m_miniEvent.target;
    return isTreasureGoblin ? 0 : GetKindRank(mob);
}

void BonkRun::UpdatePetTargets(uint32 diff)
{
    m_petTimer += diff;
    if (m_petTimer < BONK_PET_CHECK_MS)
        return;
    m_petTimer = 0;
    UpdateSkeletons();

    if (IsPetFrenzied() != m_petsFrenzied)
    {
        m_petsFrenzied = !m_petsFrenzied;
        for (OwnedWeapon& owned : m_weapons)
            if (owned.weapon.behavior == BONK_BEHAVIOR_PET)
                UpdatePets(owned);
        DressSnakes();
        DressBeasts();
    }
    UpdateSnakes();

    std::vector<Creature*> const prey = GetMobsInRange(BONK_PET_HUNT_RANGE);
    uint32 biggest = 0;
    for (Creature* mob : prey)
        biggest = std::max(biggest, GetPetPreyRank(mob));

    Map* map = m_player->GetMap();
    uint32 const now = WorldTimer::getMSTime();
    std::vector<ObjectGuid> hunted;
    std::vector<std::pair<OwnedWeapon*, Creature*>> seeking;
    auto consider = [&](OwnedWeapon& owned, ObjectGuid const& guid, bool minion)
    {
        Creature* pet = map->GetCreature(guid);
        if (!pet || !pet->IsAlive() || (owned.weapon.damageFraction <= 0.0f && !minion))
            return;
        auto state = m_petStates.find(guid);
        if (state != m_petStates.end() && int32(state->second.busyUntilMs - now) > 0)
            return;

        if (!pet->IsWithinDistInMap(m_player, BONK_PET_LEASH_RANGE))
        {
            pet->AttackStop();
            pet->NearTeleportTo(m_player->GetPositionX(), m_player->GetPositionY(), m_player->GetPositionZ(), m_player->GetOrientation());
            return;
        }

        Creature* victim = pet->GetVictim() ? pet->GetVictim()->ToCreature() : nullptr;
        if (victim && victim->IsAlive() && victim->IsWithinDistInMap(m_player, BONK_PET_HUNT_RANGE) && GetPetPreyRank(victim) >= biggest)
        {
            hunted.push_back(victim->GetObjectGuid());
            if (owned.weapon.behavior == BONK_BEHAVIOR_PET)
                UsePetAbilities(owned, pet, victim);
        }
        else
            seeking.emplace_back(&owned, pet);
    };
    for (OwnedWeapon& owned : m_weapons)
        for (ObjectGuid const& guid : owned.pets)
            consider(owned, guid, false);
    for (Snake const& released : m_snakes)
        if (OwnedWeapon* owned = FindOwned(released.weaponId))
            consider(*owned, released.guid, false);
    for (Beast const& beast : m_beasts)
        if (beast.kind != BEAST_SPECTRAL && !beast.charging)
            if (OwnedWeapon* owned = FindOwned(beast.weaponId))
                consider(*owned, beast.guid, false);
    for (ObjectGuid const& guid : GetWarlockMinionGuids())
        if (OwnedWeapon* owned = FindOwned(GetWarlockMinionWeapon(guid)))
            consider(*owned, guid, true);
    if (seeking.empty())
        return;

    auto isFree = [&hunted](Creature* mob)
    {
        return std::find(hunted.begin(), hunted.end(), mob->GetObjectGuid()) == hunted.end();
    };
    for (auto const& seeker : seeking)
    {
        Creature* pet = seeker.second;
        if (!prey.empty())
        {
            auto nearest = [pet, &prey](auto const& wanted)
            {
                Creature* found = nullptr;
                float best = 0.0f;
                for (Creature* mob : prey)
                {
                    float const distance = pet->GetDistance(mob);
                    if (wanted(mob) && (!found || distance < best))
                    {
                        found = mob;
                        best = distance;
                    }
                }
                return found;
            };
            Creature* target = nullptr;
            if (biggest > 0)
                target = nearest([this, biggest](Creature* mob) { return GetPetPreyRank(mob) == biggest; });
            else
            {
                for (Creature* mob : prey)
                    if (isFree(mob) && pet->IsWithinDistInMap(mob, BONK_PET_PICK_RANGE) && (!target || mob->GetHealth() > target->GetHealth()))
                        target = mob;
                if (!target)
                    target = nearest(isFree);
                if (!target)
                    target = nearest([](Creature*) { return true; });
            }
            hunted.push_back(target->GetObjectGuid());
            if (pet->GetVictim() != target &&
                !(seeker.first->weapon.behavior == BONK_BEHAVIOR_PET && Pounce(*seeker.first, pet, target)))
                StartPetAttack(*seeker.first, pet, target);
            continue;
        }
        if (pet->GetVictim() || pet->GetMotionMaster()->GetCurrentMovementGeneratorType() != FOLLOW_MOTION_TYPE)
        {
            pet->AttackStop();
            pet->GetMotionMaster()->Clear(false);
            pet->GetMotionMaster()->MoveFollow(m_player, 2.0f, frand(0.0f, 2.0f * M_PI_F));
        }
    }
}

void BonkRun::DespawnPets()
{
    ReleaseDrainBeams();
    DespawnWarlockMinions();
    Map* map = m_player->FindMap();
    for (OwnedWeapon& owned : m_weapons)
    {
        if (map)
            for (ObjectGuid const& guid : owned.pets)
                if (Creature* pet = map->GetCreature(guid))
                    pet->DespawnOrUnsummon();
        owned.pets.clear();
    }
    DespawnSnakes();
    DespawnVipers();
    DespawnBeasts();
    DespawnSkeletons();
    m_petStates.clear();
    m_player->RemoveAurasDueToSpell(BONK_SPELL_HOWL_FRENZY);
}

std::vector<Creature*> BonkRun::PickGroupCenters(std::vector<Creature*> const& mobs, float radius, uint32 count) const
{
    return PickGroundSpots(mobs, radius, count);
}

void BonkRun::ShowFallingAt(SpellEntry const* spellInfo, float x, float y, float z)
{
    ShowMissileBetween(spellInfo, x, y, z + BONK_PROJECTILE_HEIGHT, x, y, z);
}

void BonkRun::ShowMissileFrom(Unit* source, SpellEntry const* spellInfo, float x, float y, float z)
{
    ShowMissileAt(source, spellInfo, x, y, z);
}

void BonkRun::ShowMissileBetween(SpellEntry const* spellInfo, float fromX, float fromY, float fromZ, float toX, float toY, float toZ)
{
    float const distance = std::sqrt((toX - fromX) * (toX - fromX) + (toY - fromY) * (toY - fromY) + (toZ - fromZ) * (toZ - fromZ));
    uint32 const flightMs = spellInfo->speed > 0.0f ? uint32(distance / spellInfo->speed * IN_MILLISECONDS) : 0;
    SendBonkMissile(m_player, GetQuietStrikeLook(spellInfo->Id), fromX, fromY, fromZ, toX, toY, toZ, flightMs + BONK_ERUPTION_LOOK_MS);
}

void BonkRun::RefreshHeroPositionNow()
{
    if (m_player->IsInWorld())
        GetHeroPositionNow(m_player, m_heroNow.x, m_heroNow.y, m_heroNow.z);
}

void BonkRun::ShowThrowAtSpot(Unit* source, SpellEntry const* spellInfo, Unit const* target)
{
    ShowMissileAt(source, spellInfo, target->GetPositionX(), target->GetPositionY(),
        target->GetPositionZ() + target->GetCollisionHeight() / 2.0f);
}

void BonkRun::ShowMissilesAround(SpellEntry const* spellInfo, float radius, uint32 count)
{
    float const x = m_player->GetPositionX(), y = m_player->GetPositionY(), z = m_player->GetPositionZ();
    float const startAngle = frand(0.0f, 2.0f * M_PI_F);
    for (uint32 i = 0; i < count; ++i)
    {
        float const angle = startAngle + 2.0f * M_PI_F * i / count;
        float tx = x + radius * std::cos(angle), ty = y + radius * std::sin(angle), tz = z;
        m_player->GetMap()->GetWalkHitPosition(nullptr, x, y, z, tx, ty, tz);
        ShowMissileAt(m_player, spellInfo, tx, ty, tz);
    }
}

bool BonkRun::FindLargestGroup(float range, float& x, float& y, float& z) const
{
    std::vector<Creature*> mobs = GetMobsInRange(range);
    if (mobs.empty())
        return false;
    if (mobs.size() > BONK_GROUP_SEEK_MOBS)
        mobs.resize(BONK_GROUP_SEEK_MOBS);
    std::vector<Creature*> const groups = PickGroundSpots(mobs, BONK_LINE_GROUP_RADIUS, 1);
    (groups.empty() ? mobs.front() : groups.front())->GetPosition(x, y, z);
    return true;
}

void BonkRun::UpdateStampede(uint32 diff)
{
    auto stampede = std::find_if(m_weapons.begin(), m_weapons.end(), [](OwnedWeapon const& owned)
    {
        return owned.weapon.HasFlag(BONK_WEAPON_FLAG_STAMPEDE);
    });
    if (stampede == m_weapons.end())
        return;

    m_stampedeTimer -= int32(diff);
    if (m_stampedeTimer > 0)
        return;
    float const pace = GetWeaponCooldown(*stampede) / float(std::max(1u, stampede->weapon.cooldownMs));
    m_stampedeTimer = LaunchStampede(*stampede) ? int32(BONK_STAMPEDE_MS * pace) : BONK_STAMPEDE_RETRY_MS;
}

bool BonkRun::LaunchStampede(OwnedWeapon const& owned)
{
    float cx, cy, cz;
    if (!m_player->IsAlive() || !FindLargestGroup(BONK_PET_HUNT_RANGE, cx, cy, cz))
        return false;

    float hx, hy, hz;
    GetHeroPositionNow(m_player, hx, hy, hz);
    float const angle = std::fabs(cx - hx) + std::fabs(cy - hy) > 0.1f ? std::atan2(cy - hy, cx - hx) : m_player->GetOrientation();
    float const dx = std::cos(angle), dy = std::sin(angle);
    float const area = GetWeaponArea(owned);
    Map* map = m_player->GetMap();
    bool launched = false;
    for (uint32 i = 0; i < BONK_STAMPEDE_BEASTS; ++i)
    {
        float const side = (float(i) - (BONK_STAMPEDE_BEASTS - 1) / 2.0f) * BONK_STAMPEDE_LANE * area;
        float sx = cx - dx * BONK_STAMPEDE_LEAD - dy * side;
        float sy = cy - dy * BONK_STAMPEDE_LEAD + dx * side;
        float sz = cz;
        float ex = cx + dx * BONK_STAMPEDE_PAST - dy * side;
        float ey = cy + dy * BONK_STAMPEDE_PAST + dx * side;
        float ez = cz;
        map->GetWalkHitPosition(nullptr, cx, cy, cz, sx, sy, sz);
        map->GetWalkHitPosition(nullptr, cx, cy, cz, ex, ey, ez);
        if (!SummonBeast(owned, BEAST_SPECTRAL, sx, sy, sz, angle, uint32(BONK_STAMPEDE_LIFE_MS * GetWeaponDurationScale(owned))))
            continue;
        QueueCharge(m_beasts.back(), ex, ey, ez, BONK_STAMPEDE_SHARE, BONK_STAMPEDE_SPEED);
        launched = true;
    }
    return launched;
}

void BonkRun::CallHowlBeast(OwnedWeapon const& owned)
{
    BeastKind const kinds[] = { BEAST_BOAR, BEAST_BEAR, BEAST_WYVERN };
    BeastKind const kind = kinds[urand(0, 2)];
    Map* map = m_player->GetMap();
    float hx, hy, hz;
    GetHeroPositionNow(m_player, hx, hy, hz);
    float gx = hx, gy = hy, gz = hz;
    bool const group = FindLargestGroup(BONK_PET_HUNT_RANGE, gx, gy, gz);

    float const angle = frand(0.0f, 2.0f * M_PI_F);
    float x = hx + BONK_HOWL_BEAST_SPREAD * std::cos(angle);
    float y = hy + BONK_HOWL_BEAST_SPREAD * std::sin(angle);
    float z = hz;
    if (kind == BEAST_BEAR && group)
    {
        x = gx;
        y = gy;
        z = gz;
    }
    map->GetWalkHitPosition(nullptr, hx, hy, hz, x, y, z);

    float const facing = group && (std::fabs(gx - x) + std::fabs(gy - y) > 0.1f) ? std::atan2(gy - y, gx - x) : angle;
    if (!SummonBeast(owned, kind, x, y, z, facing, uint32(BONK_HOWL_BEAST_MS * GetWeaponDurationScale(owned))))
        return;

    Beast& beast = m_beasts.back();
    if (kind == BEAST_BEAR)
        beast.actMs = BONK_BEAR_FIRST_MAUL_MS;
    else if (kind == BEAST_WYVERN)
        beast.actMs = BONK_WYVERN_FIRST_SCREECH_MS;
    else if (group)
    {
        float ex = gx + std::cos(facing) * BONK_BOAR_CHARGE_PAST;
        float ey = gy + std::sin(facing) * BONK_BOAR_CHARGE_PAST;
        float ez = gz;
        map->GetWalkHitPosition(nullptr, gx, gy, gz, ex, ey, ez);
        QueueCharge(beast, ex, ey, ez, BONK_BOAR_CHARGE_SHARE, BONK_BOAR_CHARGE_SPEED);
    }
    DressBeasts();
    m_petTimer = BONK_PET_CHECK_MS;
}

Creature* BonkRun::SummonBeast(OwnedWeapon const& owned, BeastKind kind, float x, float y, float z, float orientation, uint32 lifeMs)
{
    bool const spectral = kind == BEAST_SPECTRAL;
    MakeRoomForBeast(spectral);

    uint32 entry = BONK_SPECTRAL_BEAST;
    switch (kind)
    {
        case BEAST_BOAR:   entry = BONK_HOWL_BOAR; break;
        case BEAST_BEAR:   entry = BONK_HOWL_BEAR; break;
        case BEAST_WYVERN: entry = BONK_HOWL_WYVERN; break;
        default:           break;
    }
    s_nextHelperLevel = m_player->GetLevel();
    Creature* creature = m_player->SummonCreature(entry, x, y, z, orientation, TEMPSUMMON_TIMED_DESPAWN, BONK_OBJECT_LIFETIME_SEC * IN_MILLISECONDS,
        false, 0, spectral ? &InstallChargerAI : &InstallPetAI);
    if (!creature)
        return nullptr;

    creature->SetOwnerGuid(m_player->GetObjectGuid());
    creature->SetUInt32Value(UNIT_CREATED_BY_SPELL, owned.weapon.spellId);
    creature->SetFactionTemplateId(m_player->GetFactionTemplateId());
    if (!spectral)
        creature->SetFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_IMMUNE_TO_PLAYER);
    creature->SetHealth(creature->GetMaxHealth());
    creature->SetInvincibilityHpThreshold(creature->GetMaxHealth());
    if (spectral)
    {
        creature->SetObjectScale(GetSummonLookScale(owned, BONK_SPECTRAL_SCALE));
        creature->UpdateModelData();
    }

    Beast beast;
    beast.guid = creature->GetObjectGuid();
    beast.weaponId = owned.weapon.id;
    beast.kind = kind;
    beast.untilMs = m_totalMs + lifeMs;
    beast.lastX = x;
    beast.lastY = y;
    m_beasts.push_back(std::move(beast));
    return creature;
}

void BonkRun::MakeRoomForBeast(bool spectral)
{
    auto alike = [spectral](Beast const& beast) { return (beast.kind == BEAST_SPECTRAL) == spectral; };
    size_t count = size_t(std::count_if(m_beasts.begin(), m_beasts.end(), alike));
    size_t const cap = spectral ? BONK_MAX_SPECTRAL_BEASTS : BONK_MAX_HOWL_BEASTS;
    std::vector<ObjectGuid> oldest;
    for (Beast const& beast : m_beasts)
    {
        if (count < cap)
            break;
        if (!alike(beast))
            continue;
        oldest.push_back(beast.guid);
        --count;
    }
    RemoveBeasts(oldest);
}

void BonkRun::RemoveBeasts(std::vector<ObjectGuid> const& gone)
{
    if (gone.empty())
        return;
    Map* map = m_player->GetMap();
    for (ObjectGuid const& guid : gone)
    {
        if (Creature* creature = map->GetCreature(guid))
            creature->DespawnOrUnsummon();
        m_petStates.erase(guid);
    }
    m_beasts.erase(std::remove_if(m_beasts.begin(), m_beasts.end(), [&gone](Beast const& beast)
    {
        return std::find(gone.begin(), gone.end(), beast.guid) != gone.end();
    }), m_beasts.end());
}

void BonkRun::QueueCharge(Beast& beast, float x, float y, float z, float share, float speed)
{
    beast.charging = true;
    beast.chargeDelayMs = BONK_CHARGE_DELAY_MS;
    beast.share = share;
    beast.speed = speed;
    beast.toX = x;
    beast.toY = y;
    beast.toZ = z;
    beast.struck.clear();
}

void BonkRun::BeginCharge(Beast& beast, Creature* creature)
{
    beast.lastX = creature->GetPositionX();
    beast.lastY = creature->GetPositionY();
    creature->AttackStop();
    creature->GetMotionMaster()->Clear(false);
    creature->GetMotionMaster()->MovePoint(0, beast.toX, beast.toY, beast.toZ, MOVE_PATHFINDING | MOVE_RUN_MODE | MOVE_FORCE_DESTINATION, beast.speed);
    float const travelMs = creature->movespline->Finalized() ? creature->GetDistance2d(beast.toX, beast.toY) / beast.speed * IN_MILLISECONDS :
        float(creature->movespline->Duration());
    beast.chargeLeftMs = int32(travelMs) + BONK_CHARGE_GRACE_MS;
    creature->SendPlaySpellVisualKit(BONK_KIT_CHARGE_TRAIL);
}

void BonkRun::UpdateCharge(Beast& beast, Creature* creature, uint32 diff, std::vector<BeastHit>& hits)
{
    if (beast.chargeDelayMs > 0)
    {
        beast.chargeDelayMs -= int32(diff);
        if (beast.chargeDelayMs <= 0)
            BeginCharge(beast, creature);
        return;
    }

    OwnedWeapon const* owned = FindOwned(beast.weaponId);
    float const reach = BONK_CHARGE_REACH * (owned ? GetWeaponArea(*owned) : 1.0f);
    float const x = creature->GetPositionX(), y = creature->GetPositionY();
    Map* map = m_player->GetMap();
    for (ObjectGuid const& guid : GetEnemyGuids())
    {
        Creature* mob = map->GetCreature(guid);
        if (!mob || !mob->IsAlive() || std::find(beast.struck.begin(), beast.struck.end(), guid) != beast.struck.end())
            continue;
        if (std::fabs(mob->GetPositionZ() - creature->GetPositionZ()) > BONK_PROJECTILE_Z_REACH ||
            GetSegmentDistance(mob->GetPositionX(), mob->GetPositionY(), beast.lastX, beast.lastY, x, y) > reach + mob->GetObjectBoundingRadius())
            continue;
        beast.struck.push_back(guid);
        BeastHit hit;
        hit.beast = beast.guid;
        hit.victim = guid;
        hit.weaponId = beast.weaponId;
        hit.share = beast.share;
        hits.push_back(hit);
    }
    beast.lastX = x;
    beast.lastY = y;

    beast.chargeLeftMs -= int32(diff);
    if (creature->movespline->Finalized() || beast.chargeLeftMs <= 0)
        EndCharge(beast, creature);
}

void BonkRun::EndCharge(Beast& beast, Creature* creature)
{
    beast.charging = false;
    if (beast.kind == BEAST_SPECTRAL)
        return;
    creature->StopMoving();
    creature->GetMotionMaster()->Clear(false);
    m_petTimer = BONK_PET_CHECK_MS;
}

void BonkRun::ResumeCharges()
{
    Map* map = m_player->FindMap();
    if (!map)
        return;
    for (Beast& beast : m_beasts)
        if (beast.charging && beast.chargeDelayMs <= 0)
            if (Creature* creature = map->GetCreature(beast.guid))
                BeginCharge(beast, creature);
}

bool BonkRun::ActBeast(Beast& beast, Creature* creature, uint32 diff, std::vector<ObjectGuid>& mauls)
{
    if (beast.kind != BEAST_BEAR && beast.kind != BEAST_WYVERN)
        return false;
    beast.actMs -= int32(diff);
    if (beast.actMs > 0)
        return false;

    if (beast.kind == BEAST_BEAR)
    {
        beast.actMs = BONK_BEAR_IDLE_MS;
        mauls.push_back(beast.guid);
        return false;
    }
    creature->HandleEmote(EMOTE_ONESHOT_ROAR);
    creature->SendPlaySpellVisualKit(BONK_KIT_SCREECH);
    beast.actMs = BONK_WYVERN_SCREECH_MS;
    bool const first = !beast.acted;
    beast.acted = true;
    return first;
}

bool BonkRun::Maul(Creature* bear, OwnedWeapon const& owned)
{
    SpellEntry const* swipe = sSpellMgr.GetSpellEntry(BONK_SPELL_SWIPE);
    std::vector<Creature*> const mobs = GetMobsNear(bear->GetPositionX(), bear->GetPositionY(), BONK_BEAR_MAUL_RADIUS * GetWeaponArea(owned));
    if (!swipe || mobs.empty())
        return false;

    bear->HandleEmote(EMOTE_ONESHOT_ATTACKUNARMED);
    bear->SendPlaySpellVisualKit(BONK_KIT_MAUL);
    BonkKeywordInfo const* bleed = sBonkMgr.GetKeyword(BONK_KEYWORD_BLEED);
    uint32 const bleedMs = bleed ? uint32(bleed->durationMs * GetWeaponDurationScale(owned)) : 0;
    float const bleedScale = 1.0f + (owned.damageBonus + GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_PET_DAMAGE)) / 100.0f;
    float const damage = GetBeastHitDamage(owned);
    for (Creature* mob : mobs)
    {
        DealSpellHit(swipe, mob, damage, bear);
        if (bleed && mob->IsAlive())
            ApplyKeyword(mob, BONK_KEYWORD_BLEED, BONK_BEAR_MAUL_STACKS, bleedMs, bleedScale, owned.weapon.spellId);
    }
    return true;
}

float BonkRun::GetBeastHitDamage(OwnedWeapon const& owned) const
{
    return GetWeaponDamage(owned) * (IsPetFrenzied() ? GetFrenzyDamage() : 1.0f);
}

void BonkRun::UpdateBeasts(uint32 diff)
{
    UpdateStampede(diff);
    PulsePlague(diff);
    if (m_beasts.empty())
    {
        UpdateScreech(diff, false);
        return;
    }

    Map* map = m_player->GetMap();
    std::vector<BeastHit> hits;
    std::vector<ObjectGuid> mauls;
    std::vector<ObjectGuid> gone;
    bool screeched = false;
    for (Beast& beast : m_beasts)
    {
        Creature* creature = map->GetCreature(beast.guid);
        if (!creature || !creature->IsAlive() || !FindOwned(beast.weaponId) || int32(beast.untilMs - m_totalMs) <= 0)
        {
            gone.push_back(beast.guid);
            continue;
        }
        if (beast.charging)
        {
            UpdateCharge(beast, creature, diff, hits);
            if (!beast.charging && beast.kind == BEAST_SPECTRAL)
                gone.push_back(beast.guid);
            continue;
        }
        screeched |= ActBeast(beast, creature, diff, mauls);
    }

    for (BeastHit const& hit : hits)
    {
        Creature* beast = map->GetCreature(hit.beast);
        Creature* victim = map->GetCreature(hit.victim);
        OwnedWeapon const* owned = FindOwned(hit.weaponId);
        SpellEntry const* spellInfo = owned ? sSpellMgr.GetSpellEntry(owned->weapon.spellId) : nullptr;
        if (spellInfo && beast && victim)
            DealSpellHit(spellInfo, victim, GetBeastHitDamage(*owned) * hit.share, beast);
    }

    for (ObjectGuid const& guid : mauls)
    {
        auto beast = std::find_if(m_beasts.begin(), m_beasts.end(), [&guid](Beast const& entry) { return entry.guid == guid; });
        Creature* bear = map->GetCreature(guid);
        OwnedWeapon const* owned = beast != m_beasts.end() ? FindOwned(beast->weaponId) : nullptr;
        if (!bear || !bear->IsAlive() || !owned)
            continue;
        float const pace = GetWeaponCooldown(*owned) / float(std::max(1u, owned->weapon.cooldownMs));
        int32 const next = Maul(bear, *owned) ? int32(BONK_BEAR_MAUL_MS * pace) : BONK_BEAR_IDLE_MS;
        beast = std::find_if(m_beasts.begin(), m_beasts.end(), [&guid](Beast const& entry) { return entry.guid == guid; });
        if (beast != m_beasts.end())
            beast->actMs = next;
    }

    RemoveBeasts(gone);
    UpdateScreech(diff, screeched || !gone.empty());
}

void BonkRun::DressBeasts()
{
    if (m_beasts.empty())
        return;

    Map* map = m_player->GetMap();
    bool const frenzied = IsPetFrenzied();
    float const speed = GetSummonSpeedRate(GetStat(BONK_PASSIVE_MOVE_SPEED));
    for (Beast const& beast : m_beasts)
    {
        if (beast.kind == BEAST_SPECTRAL)
            continue;
        OwnedWeapon const* owned = FindOwned(beast.weaponId);
        Creature* creature = owned ? map->GetCreature(beast.guid) : nullptr;
        if (!creature || !creature->IsAlive())
            continue;

        float const pace = GetWeaponCooldown(*owned) / float(std::max(1u, owned->weapon.cooldownMs));
        float const bite = GetBeastHitDamage(*owned) * BONK_WOLF_ATTACK_MS / float(std::max(500u, owned->weapon.tickMs));
        float const base = beast.kind == BEAST_BOAR ? BONK_BOAR_SCALE : beast.kind == BEAST_BEAR ? BONK_BEAR_SCALE : BONK_WYVERN_SCALE;
        float const scale = GetSummonLookScale(*owned, base);
        if (creature->GetBaseRunSpeedRate() != speed)
            creature->SetBaseSpeedRate(MOVE_RUN, speed);
        creature->SetBaseWeaponDamage(BASE_ATTACK, MINDAMAGE, bite * 0.9f);
        creature->SetBaseWeaponDamage(BASE_ATTACK, MAXDAMAGE, bite * 1.1f);
        creature->UpdateDamagePhysical(BASE_ATTACK);
        if (beast.kind == BEAST_BEAR)
        {
            creature->SetAttackTime(BASE_ATTACK, BONK_BEAST_NO_SWING_MS);
            creature->ResetAttackTimer(BASE_ATTACK);
        }
        else
            creature->SetAttackTime(BASE_ATTACK, std::max(300u, uint32(BONK_WOLF_ATTACK_MS * pace)));
        if (creature->GetObjectScale() != scale)
        {
            creature->SetObjectScale(scale);
            creature->UpdateModelData();
        }
        if (frenzied && !creature->HasAura(BONK_SPELL_BESTIAL_WRATH))
            creature->AddAura(BONK_SPELL_BESTIAL_WRATH);
        else if (!frenzied && creature->HasAura(BONK_SPELL_BESTIAL_WRATH))
            creature->RemoveAurasDueToSpell(BONK_SPELL_BESTIAL_WRATH);
    }
}

void BonkRun::DespawnBeasts()
{
    if (Map* map = m_player->FindMap())
        for (Beast const& beast : m_beasts)
            if (Creature* creature = map->GetCreature(beast.guid))
                creature->DespawnOrUnsummon();
    m_beasts.clear();
    m_screeching = false;
}

bool BonkRun::IsBeast(ObjectGuid const& guid) const
{
    return std::any_of(m_beasts.begin(), m_beasts.end(), [&guid](Beast const& beast) { return beast.guid == guid; });
}

std::vector<Creature*> BonkRun::GetAllPets(bool frenziedOnly) const
{
    std::vector<Creature*> pets;
    Map* map = m_player->FindMap();
    if (!map)
        return pets;

    auto add = [map, &pets](ObjectGuid const& guid)
    {
        Creature* pet = map->GetCreature(guid);
        if (pet && pet->IsAlive())
            pets.push_back(pet);
    };
    for (OwnedWeapon const& owned : m_weapons)
        if (!frenziedOnly || owned.weapon.behavior == BONK_BEHAVIOR_PET)
            for (ObjectGuid const& guid : owned.pets)
                add(guid);
    for (Snake const& released : m_snakes)
        add(released.guid);
    for (Beast const& beast : m_beasts)
        if (!frenziedOnly || beast.kind != BEAST_SPECTRAL)
            add(beast.guid);
    return pets;
}

bool BonkRun::IsScreeching() const
{
    return std::any_of(m_beasts.begin(), m_beasts.end(), [](Beast const& beast) { return beast.kind == BEAST_WYVERN && beast.acted; });
}

void BonkRun::UpdateScreech(uint32 diff, bool force)
{
    m_screechTimer += diff;
    if (!force && m_screechTimer < BONK_SCREECH_CHECK_MS)
        return;
    m_screechTimer = 0;

    bool const screeching = IsScreeching();
    SpellEntry const* buff = sSpellMgr.GetSpellEntry(BONK_SPELL_SCREECH_BUFF);
    if ((!screeching && !m_screeching) || !buff)
        return;
    m_screeching = screeching;

    for (Creature* pet : GetAllPets(false))
    {
        bool const buffed = pet->HasAura(BONK_SPELL_SCREECH_BUFF);
        if (!screeching && buffed)
            pet->RemoveAurasDueToSpell(BONK_SPELL_SCREECH_BUFF);
        if (!screeching || buffed)
            continue;

        SpellAuraHolder* holder = CreateSpellAuraHolder(buff, pet, m_player, m_player);
        Aura* aura = CreateAura(buff, EFFECT_INDEX_0, nullptr, holder, pet, m_player);
        aura->SetPositive(true);
        holder->AddAura(aura, EFFECT_INDEX_0);
        holder->SetPermanent(true);
        holder->SetAuraMaxDuration(-1);
        holder->SetAuraDuration(-1);
        pet->AddSpellAuraHolder(holder);
    }
}

void BonkRun::PulsePlague(uint32 diff)
{
    m_plagueTimer -= int32(diff);
    if (m_plagueTimer > 0)
        return;
    m_plagueTimer = BONK_PLAGUE_PULSE_MS;

    Map* map = m_player->GetMap();
    for (OwnedWeapon const& owned : m_weapons)
    {
        PendingKeyword poison;
        if (!owned.weapon.HasFlag(BONK_WEAPON_FLAG_PLAGUE) || owned.pets.empty() || !GetWeaponKeyword(owned, poison))
            continue;
        float const radius = GetWeaponRadius(owned);
        for (ObjectGuid const& guid : owned.pets)
        {
            Creature* pet = map->GetCreature(guid);
            if (!pet || !pet->IsAlive())
                continue;
            for (Creature* mob : GetMobsNear(pet->GetPositionX(), pet->GetPositionY(), radius))
                ApplyKeyword(mob, poison.keyword, poison.stacks, poison.durationMs, poison.damageScale, poison.spellId);
        }
    }
}

void BonkRun::FeedFrenzy()
{
    if (!IsPetFrenzied() || std::none_of(m_weapons.begin(), m_weapons.end(), [](OwnedWeapon const& owned)
        {
            return owned.weapon.HasFlag(BONK_WEAPON_FLAG_FEEDING_FRENZY);
        }))
        return;

    uint32 const now = WorldTimer::getMSTime();
    uint32 const remaining = RemainingAuraMs(BONK_SPELL_HOWL_FRENZY);
    uint32 const next = std::min(remaining + BONK_FEEDING_FRENZY_MS, BONK_FEEDING_FRENZY_MAX_MS);
    if (next <= remaining)
        return;
    ApplyTimedAura(BONK_SPELL_HOWL_FRENZY, next);

    if (WorldTimer::getMSTimeDiff(m_frenzyGlowMs, now) < BONK_FRENZY_GLOW_GAP_MS)
        return;
    m_frenzyGlowMs = now;
    GlowFrenzy();
}

void BonkRun::GlowFrenzy()
{
    for (Creature* pet : GetAllPets(true))
    {
        pet->SendPlaySpellVisualKit(BONK_KIT_FRENZY_GLOW);
        if (SpellAuraHolder* holder = pet->GetSpellAuraHolder(BONK_SPELL_BESTIAL_WRATH))
            holder->RefreshHolder();
    }
}

void BonkRun::OnWeaponDamage(uint32 damage)
{
    if (m_state != STATE_RUNNING || !m_player->IsAlive())
        return;

    float const chance = GetPassiveTotal(BONK_PASSIVE_LEECH);
    if (chance <= 0.0f || !damage || !roll_chance_f(chance))
        return;

    float const maxHealth = float(m_player->GetMaxHealth());
    float const capPercent = chance * BONK_LEECH_CAP_PER_CHANCE;
    m_leechCarry = std::min(maxHealth * capPercent / 100.0f, m_leechCarry + maxHealth * BONK_LEECH_HEAL / 100.0f);
}

void BonkRun::AddWeapon(BonkWeapon const& weapon)
{
    OwnedWeapon owned;
    owned.weapon = weapon;
    ApplyMasteryTo(owned.weapon);
    owned.timer = 500;
    m_weapons.push_back(owned);
    RebuildWeaponSpells();
    if (weapon.IsBlink() || weapon.IsArcaneMissiles())
        m_player->GetBonkPlayer()->SendDash();
}

void BonkRun::ApplyPassives()
{
    m_player->RemoveAurasDueToSpell(BONK_SPELL_MOVE_SPEED);
    if (int32 const speed = int32(GetStat(BONK_PASSIVE_MOVE_SPEED)))
        m_player->CastCustomSpell(m_player, BONK_SPELL_MOVE_SPEED, speed, {}, {}, true);

    m_player->RemoveAurasDueToSpell(BONK_SPELL_MAX_HEALTH);
    if (int32 const health = int32(GetPassiveTotal(BONK_PASSIVE_MAX_HEALTH) + GetArmorOverflowHealth()))
        m_player->CastCustomSpell(m_player, BONK_SPELL_MAX_HEALTH, health, {}, {}, true);

    m_player->RemoveAurasDueToSpell(BONK_SPELL_DODGE);
    m_player->UpdateDodgePercentage();

    SendStats();
}

void BonkRun::SendRunXp() const
{
    uint32 const maxLevel = sWorld.getConfig(CONFIG_UINT32_MAX_PLAYER_LEVEL);
    uint32 const xp = m_player->GetLevel() >= maxLevel ? m_overcapXp : m_player->GetUInt32Value(PLAYER_XP);
    if (m_player->GetBonkPlayer()->IsAddonReady())
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteRunXp(data, m_player->GetLevel() + m_overcapLevel, xp, GetNextLevelXp(), m_orbsSinceXpSent);
        m_player->GetSession()->SendPacket(&data);
    }
    m_orbsSinceXpSent = 0;
}

void BonkRun::UpdateRunXp(bool levelled)
{
    uint32 const now = WorldTimer::getMSTime();
    if (levelled || WorldTimer::getMSTimeDiff(m_runXpSentAt, now) >= BONK_RUN_XP_SEND_MS)
    {
        SendRunXp();
        m_runXpSentAt = now;
        m_runXpDirty = false;
    }
    else
        m_runXpDirty = true;
}

uint32 BonkRun::GetNextLevelXp() const
{
    uint32 const maxLevel = sWorld.getConfig(CONFIG_UINT32_MAX_PLAYER_LEVEL);
    if (m_player->GetLevel() < maxLevel)
        return m_player->GetUInt32Value(PLAYER_NEXT_LEVEL_XP);
    return sObjectMgr.GetXPForLevel(maxLevel - 1);
}

bool BonkRun::IsOwnedOffer(Offer const& offer) const
{
    if (offer.isCard)
        return std::any_of(m_cards.begin(), m_cards.end(), [&offer](OwnedCard const& held) { return held.card && held.card->id == offer.id; });
    if (offer.isWeapon)
        return FindOwned(offer.id) != nullptr;
    auto rank = m_passiveRanks.find(offer.id);
    return rank != m_passiveRanks.end() && rank->second > 0;
}

bool BonkRun::CanBanish(Offer const& offer) const
{
    return offer.step == BONK_STEP_EVOLVE || !IsOwnedOffer(offer);
}

void BonkRun::GiveStartLevels()
{
    uint32 const levels = uint32(GetUtility(BONK_UTILITY_START_LEVEL));
    for (uint32 i = 0; i < levels; ++i)
    {
        uint32 const next = GetNextLevelXp();
        uint32 const have = m_player->GetUInt32Value(PLAYER_XP);
        if (!next || next <= have)
            break;
        GiveExperience(next - have);
    }
}

void BonkRun::GiveCollectedExperience(uint32 xp)
{
    uint32 const next = GetNextLevelXp();
    bool const shared = BonkCoop::InGroupRun(m_player) && BonkCoop::SharesXp(m_player);
    uint32 const kept = shared ? uint32(std::ceil(float(xp) / GetCoopCrowd())) : xp;
    GiveExperience(kept);
    if (next)
        BonkCoop::ShareExperience(m_player, float(kept) / float(next));
}

void BonkRun::ShareExperience(float levelFraction)
{
    if (m_state != STATE_RUNNING && m_state != STATE_PORTAL)
        return;
    GiveExperience(uint32(std::ceil(GetNextLevelXp() * levelFraction)));
}

void BonkRun::GiveExperience(uint32 xp)
{
    uint32 const maxLevel = sWorld.getConfig(CONFIG_UINT32_MAX_PLAYER_LEVEL);
    uint32 level = m_player->GetLevel();
    if (!xp)
        return;

    uint32 const health = m_player->GetHealth();

    if (level >= maxLevel)
    {
        uint32 const next = GetNextLevelXp();
        if (!next)
            return;
        uint32 const startOvercap = m_overcapLevel;
        m_overcapXp += xp;
        while (m_overcapXp >= next)
        {
            m_overcapXp -= next;
            ++m_overcapLevel;
            ++m_pendingLevels;
            if (!m_sandbox)
                sLog.Player(m_player->GetSession(), LOG_LEVELUP, LOG_LVL_BASIC,
                    "Bonk level: %s reaches level %u at run minute %.2f (stage %u, %s, %s), %u kills, class %u, +%g%% experience",
                    m_player->GetName(), level + m_overcapLevel, GetRunMinutes(), m_stage, m_map.key.c_str(), m_tier.key.c_str(), m_kills,
                    uint32(m_player->GetClass()), GetPassiveTotal(BONK_PASSIVE_GROWTH));
        }
        if (m_overcapLevel != startOvercap && m_player->IsAlive())
        {
            uint32 const heal = ReduceHealing(uint32(m_player->GetMaxHealth() * BONK_LEVEL_UP_HEAL * (m_overcapLevel - startOvercap)));
            m_player->SetHealth(std::min(health + heal, m_player->GetMaxHealth()));
        }
        UpdateRunXp(m_overcapLevel != startOvercap);
        if (m_overcapLevel != startOvercap)
            OfferLevelsBeforeDing();
        return;
    }

    uint32 const startLevel = level;
    uint32 const startMaxHealth = m_player->GetMaxHealth();
    uint32 current = m_player->GetUInt32Value(PLAYER_XP) + xp;
    uint32 next = m_player->GetUInt32Value(PLAYER_NEXT_LEVEL_XP);
    while (current >= next && level < maxLevel)
    {
        current -= next;
        m_player->GiveLevel(level + 1);
        level = m_player->GetLevel();
        next = m_player->GetUInt32Value(PLAYER_NEXT_LEVEL_XP);
    }
    m_player->SetUInt32Value(PLAYER_XP, level >= maxLevel ? 0 : current);

    for (uint32 reached = startLevel + 1; !m_sandbox && reached <= level; ++reached)
        sLog.Player(m_player->GetSession(), LOG_LEVELUP, LOG_LVL_BASIC,
            "Bonk level: %s reaches level %u at run minute %.2f (stage %u, %s, %s), %u kills, class %u, +%g%% experience",
            m_player->GetName(), reached, GetRunMinutes(), m_stage, m_map.key.c_str(), m_tier.key.c_str(), m_kills,
            uint32(m_player->GetClass()), GetPassiveTotal(BONK_PASSIVE_GROWTH));

    if (level != startLevel && m_player->IsAlive())
    {
        uint32 const gained = m_player->GetMaxHealth() > startMaxHealth ? m_player->GetMaxHealth() - startMaxHealth : 0;
        uint32 const heal = ReduceHealing(uint32(m_player->GetMaxHealth() * BONK_LEVEL_UP_HEAL * (level - startLevel)));
        m_player->SetHealth(std::min(health + gained + heal, m_player->GetMaxHealth()));
    }
    UpdateRunXp(level != startLevel);
    if (level != startLevel)
        OfferLevelsBeforeDing();
}

void BonkRun::OfferLevelsBeforeDing()
{
    m_levelPushPending = true;
    if (m_state == STATE_RUNNING || m_state == STATE_PORTAL)
        UpdateOffers();
}

void BonkRun::DropOrb(Creature const* mob, uint32 experience, BonkOrb colour)
{
    if (!experience)
        return;

    Map* map = m_player->GetMap();
    while (m_orbs.size() >= BONK_MAX_ORBS)
    {
        auto victim = m_orbs.end();
        for (auto itr = m_orbs.begin(); itr != m_orbs.end(); ++itr)
            if (!itr->pulled && (victim == m_orbs.end() || itr->colour < victim->colour))
                victim = itr;
        if (victim == m_orbs.end())
            victim = m_orbs.begin();
        Orb const gone = *victim;
        m_orbs.erase(victim);
        if (Creature* creature = map->GetCreature(gone.guid))
            VanishOrb(creature);
    }

    SpawnOrb(mob->GetPositionX(), mob->GetPositionY(), mob->GetPositionZ(), experience, colour);
}

bool BonkRun::SpawnOrb(float x, float y, float z, uint32 experience, BonkOrb colour)
{
    float const ground = m_player->GetMap()->GetHeight(x, y, z + BONK_ORB_GROUND_SEARCH, true, 2.0f * BONK_ORB_GROUND_SEARCH);
    if (ground > INVALID_HEIGHT && ground > z)
        z = ground;
    Creature* orb = m_player->SummonCreature(GetOrbEntry(colour), x, y, z, 0.0f,
        TEMPSUMMON_TIMED_DESPAWN, BONK_ORB_LIFETIME_MS, false, 0, &InstallOrbAI);
    if (!orb)
    {
        GiveExperience(experience);
        return false;
    }

    orb->MonsterMoveWithSpeed(x, y, z + BONK_ORB_LIFT, -10.0f, BONK_ORB_RISE_SPEED, MOVE_FLY_MODE);

    Orb dropped;
    dropped.guid = orb->GetObjectGuid();
    dropped.experience = experience;
    dropped.colour = colour;
    dropped.droppedMs = WorldTimer::getMSTime();
    m_orbs.push_back(dropped);
    return true;
}

void BonkRun::UpdateOrbMerges(uint32 diff)
{
    for (size_t i = 0; i < m_orbMerges.size();)
    {
        m_orbMerges[i].leftMs -= int32(diff);
        if (m_orbMerges[i].leftMs > 0)
        {
            ++i;
            continue;
        }
        OrbMerge const merge = m_orbMerges[i];
        m_orbMerges.erase(m_orbMerges.begin() + i);
        FinishOrbMerge(merge);
    }

    m_orbMergeTimer += diff;
    if (m_orbMergeTimer < BONK_ORB_MERGE_CHECK_MS)
        return;
    m_orbMergeTimer = 0;
    MergeOrbs();
}

void BonkRun::MergeOrbs()
{
    Map* map = m_player->GetMap();
    uint32 const now = WorldTimer::getMSTime();
    for (uint8 colour = BONK_ORB_BLUE; colour <= BONK_ORB_PURPLE; ++colour)
    {
        struct Candidate
        {
            size_t index;
            Creature* creature;
            bool taken;
        };
        std::vector<Candidate> candidates;
        for (size_t i = 0; i < m_orbs.size(); ++i)
        {
            Orb const& orb = m_orbs[i];
            if (orb.colour != colour || orb.pulled || orb.mergeId || WorldTimer::getMSTimeDiff(orb.droppedMs, now) < BONK_ORB_MERGE_MIN_AGE_MS)
                continue;
            if (Creature* creature = map->GetCreature(orb.guid))
                candidates.push_back({ i, creature, false });
        }
        if (candidates.size() < BONK_ORB_MERGE_COUNT)
            continue;

        for (Candidate& anchor : candidates)
        {
            if (anchor.taken)
                continue;
            std::vector<std::pair<float, Candidate*>> nearby;
            for (Candidate& other : candidates)
                if (&other != &anchor && !other.taken)
                {
                    float const distance = anchor.creature->GetDistance2d(other.creature->GetPositionX(), other.creature->GetPositionY(), SizeFactor::None);
                    if (distance <= BONK_ORB_MERGE_RANGE)
                        nearby.push_back({ distance, &other });
                }
            if (nearby.size() + 1 < BONK_ORB_MERGE_COUNT)
                continue;
            std::sort(nearby.begin(), nearby.end(), [](std::pair<float, Candidate*> const& a, std::pair<float, Candidate*> const& b) { return a.first < b.first; });

            OrbMerge merge;
            merge.id = ++m_lastOrbMergeId;
            merge.anchor = m_orbs[anchor.index].guid;
            merge.colour = BonkOrb(std::min<uint8>(colour + 1, BONK_ORB_PURPLE));
            merge.leftMs = int32(BONK_ORB_MERGE_SLIDE_MS);
            anchor.taken = true;
            m_orbs[anchor.index].mergeId = merge.id;
            float const x = anchor.creature->GetPositionX(), y = anchor.creature->GetPositionY(), z = anchor.creature->GetPositionZ();
            for (size_t i = 0; i + 1 < BONK_ORB_MERGE_COUNT; ++i)
            {
                Candidate& other = *nearby[i].second;
                other.taken = true;
                m_orbs[other.index].mergeId = merge.id;
                other.creature->MonsterMoveWithSpeed(x, y, z, -10.0f, BONK_ORB_MERGE_SLIDE_SPEED, MOVE_FLY_MODE);
            }
            m_orbMerges.push_back(merge);
        }
    }
}

void BonkRun::FinishOrbMerge(OrbMerge const& merge)
{
    Map* map = m_player->GetMap();
    auto anchor = std::find_if(m_orbs.begin(), m_orbs.end(), [&](Orb const& orb) { return orb.guid == merge.anchor; });
    Creature* anchorCreature = anchor != m_orbs.end() ? map->GetCreature(anchor->guid) : nullptr;
    if (!anchorCreature || anchor->pulled || anchor->mergeId != merge.id)
    {
        for (Orb& orb : m_orbs)
            if (orb.mergeId == merge.id)
                orb.mergeId = 0;
        return;
    }

    uint32 experience = 0;
    for (auto itr = m_orbs.begin(); itr != m_orbs.end();)
    {
        if (itr->mergeId != merge.id || itr->guid == merge.anchor || itr->pulled)
        {
            if (itr->mergeId == merge.id && itr->guid != merge.anchor)
                itr->mergeId = 0;
            ++itr;
            continue;
        }
        experience += itr->experience;
        if (Creature* creature = map->GetCreature(itr->guid))
            VanishOrb(creature);
        itr = m_orbs.erase(itr);
    }

    anchor = std::find_if(m_orbs.begin(), m_orbs.end(), [&](Orb const& orb) { return orb.guid == merge.anchor; });
    anchor->experience += experience;
    anchor->colour = merge.colour;
    anchor->mergeId = 0;
    anchor->droppedMs = WorldTimer::getMSTime();
    if (CreatureInfo const* info = sObjectMgr.GetCreatureTemplate(GetOrbEntry(merge.colour)))
    {
        anchorCreature->SetDisplayId(info->display_id[0]);
        anchorCreature->SetObjectScale(info->display_scale[0]);
    }
}

void BonkRun::UpdateOrbs(uint32 diff)
{
    UpdateOrbMerges(diff);

    m_orbTimer += diff;
    if (m_orbTimer < BONK_ORB_CHECK_MS || m_orbs.empty())
        return;
    m_orbTimer = 0;

    Map* map = m_player->GetMap();
    float heroX, heroY, heroZ;
    GetHeroChestPositionNow(m_player, heroX, heroY, heroZ);
    uint32 const now = WorldTimer::getMSTime();
    if (!m_orbSweepAtMs || now - m_orbSweepAtMs > 2 * BONK_ORB_CHECK_MS)
        m_orbSweepFrom = Position(heroX, heroY, heroZ, 0.0f);
    std::vector<OrbCollector> const collectors = GetPickupPlayers(PickupSpot::Chest, false);
    uint32 collected = 0;
    std::map<BonkRun*, uint32> collectedByMates;
    for (auto itr = m_orbs.begin(); itr != m_orbs.end();)
    {
        Creature* orb = map->GetCreature(itr->guid);
        BonkRun* picker = orb ? nullptr : this;
        for (size_t i = 0; orb && !picker && i < collectors.size(); ++i)
        {
            OrbCollector const& collector = collectors[i];
            float const reach = collector.run == this ? GetHeroSweepDistance(m_player, m_orbSweepFrom, heroX, heroY, heroZ, orb) :
                GetHeroDistance(collector.player, collector.x, collector.y, collector.z, orb);
            if (reach <= BONK_ORB_PICKUP_RANGE)
                picker = collector.run;
        }
        if (picker)
        {
            if (picker == this)
            {
                collected += itr->experience;
                ++m_orbsSinceXpSent;
            }
            else
                collectedByMates[picker] += itr->experience;
            if (orb)
                VanishOrb(orb);
            itr = m_orbs.erase(itr);
            continue;
        }

        OrbCollector const* target = nullptr;
        for (OrbCollector const& collector : collectors)
            if (itr->pulled && collector.player->GetObjectGuid() == itr->puller)
                target = &collector;
        if (!target)
        {
            itr->pulled = false;
            float nearest = 0.0f;
            for (OrbCollector const& collector : collectors)
            {
                float const distance = GetHeroDistance(collector.player, collector.x, collector.y, collector.z, orb);
                if (distance <= collector.magnet && (!target || distance < nearest))
                {
                    target = &collector;
                    nearest = distance;
                }
            }
        }

        if (target && (!itr->pulled ||
            (target->x - itr->aimX) * (target->x - itr->aimX) + (target->y - itr->aimY) * (target->y - itr->aimY) +
                (target->z - itr->aimZ) * (target->z - itr->aimZ) > BONK_ORB_REAIM_DISTANCE * BONK_ORB_REAIM_DISTANCE))
        {
            itr->pulled = true;
            itr->puller = target->player->GetObjectGuid();
            itr->aimX = target->x;
            itr->aimY = target->y;
            itr->aimZ = target->z;
            orb->MonsterMoveWithSpeed(target->x, target->y, target->z, -10.0f, BONK_ORB_FLY_SPEED, MOVE_FLY_MODE);
        }
        ++itr;
    }
    m_orbSweepFrom = Position(heroX, heroY, heroZ, 0.0f);
    m_orbSweepAtMs = now;

    if (collected)
        GiveCollectedExperience(collected);
    for (auto const& mate : collectedByMates)
        mate.first->GiveCollectedExperience(mate.second);
}

std::vector<BonkRun::OrbCollector> BonkRun::GetPickupPlayers(PickupSpot spot, bool hurtOnly)
{
    std::vector<Player*> const members = BonkCoop::InGroupRun(m_player) ? BonkCoop::RunGroupOf(m_player) : std::vector<Player*>{ m_player };
    std::vector<OrbCollector> collectors;
    for (Player* member : members)
    {
        BonkRun* run = member == m_player ? this : member->GetBonkPlayer()->GetRun();
        if (!run || !member->IsAlive() || !member->IsInWorld() || member->GetMap() != m_player->GetMap() || run->IsAway())
            continue;
        if (hurtOnly && member->GetHealth() >= member->GetMaxHealth())
            continue;
        OrbCollector collector;
        collector.player = member;
        collector.run = run;
        if (spot == PickupSpot::Chest)
            GetHeroChestPositionNow(member, collector.x, collector.y, collector.z);
        else
            GetHeroPositionNow(member, collector.x, collector.y, collector.z);
        collector.magnet = run->GetMagnetRange();
        collectors.push_back(collector);
    }
    return collectors;
}

void BonkRun::EatHealDrop()
{
    float const amount = BONK_HEAL_AMOUNT * (1.0f + GetCardTotal(BONK_CARD_JERKY, 1) / 100.0f);
    SupportScope scope(*this, { "Spell_Holy_Heal", GetString(BONK_STRING_SUPPORT_HEALING_ORBS) });
    HealHero(ReduceHealing(std::max(1u, uint32(m_player->GetMaxHealth() * amount))), BONK_SPELL_HEAL_TEXT);
}

void BonkRun::PullAllOrbs()
{
    Map* map = m_player->GetMap();
    float heroX, heroY, heroZ;
    GetHeroChestPositionNow(m_player, heroX, heroY, heroZ);
    for (Orb& orb : m_orbs)
    {
        if (orb.pulled)
            continue;
        if (Creature* creature = map->GetCreature(orb.guid))
        {
            orb.pulled = true;
            orb.puller = m_player->GetObjectGuid();
            orb.aimX = heroX;
            orb.aimY = heroY;
            orb.aimZ = heroZ;
            creature->MonsterMoveWithSpeed(orb.aimX, orb.aimY, orb.aimZ, -10.0f, BONK_ORB_FLY_SPEED, MOVE_FLY_MODE);
        }
    }
}

void BonkRun::PullAllCurrency()
{
    PullAllOrbs();
    CollectAllShards();
    CollectAllValorPouches();
}

void BonkRun::CollectAllValorPouches()
{
    Map* map = m_player->GetMap();
    std::vector<BonkPowerup const*> pouches;
    for (auto itr = m_powerups.begin(); itr != m_powerups.end();)
    {
        GameObject* go = map->GetGameObject(*itr);
        auto powerup = go ? std::find_if(sBonkMgr.GetPowerups().begin(), sBonkMgr.GetPowerups().end(),
            [go](BonkPowerup const& p) { return p.entry == go->GetEntry(); }) : sBonkMgr.GetPowerups().end();
        if (powerup == sBonkMgr.GetPowerups().end() || powerup->effect != BONK_POWERUP_VALOR || !go->isSpawned())
        {
            ++itr;
            continue;
        }
        ForgetPowerupObjective(*itr);
        go->Delete();
        itr = m_powerups.erase(itr);
        pouches.push_back(&*powerup);
    }
    for (BonkPowerup const* pouch : pouches)
        UsePowerup(*pouch);
}

void BonkRun::CollectAllOrbs()
{
    uint32 collected = 0;
    for (Orb const& orb : m_orbs)
        collected += orb.experience;
    m_orbsSinceXpSent += uint32(m_orbs.size());
    DespawnOrbs();
    if (collected)
        GiveCollectedExperience(collected);
}

Creature* BonkRun::SummonCaravan(uint32 entry, float x, float y, float z, float orientation)
{
    Creature* caravan = m_player->SummonCreature(entry, x, y, z, orientation, TEMPSUMMON_TIMED_DESPAWN, 10 * MINUTE * IN_MILLISECONDS, false, 0,
        &InstallCaravanAI);
    if (!caravan)
        return nullptr;
    m_lastPlateId = m_lastPlateId % BONK_MAX_PLATE_ID + 1;
    caravan->SetPlateId(m_lastPlateId);
    caravan->ForceValuesUpdateAtIndex(UNIT_FIELD_HEALTH);
    caravan->ForceValuesUpdateAtIndex(UNIT_FIELD_MAXHEALTH);
    if (m_player->GetBonkPlayer()->IsAddonReady())
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteAlly(data, m_player->GetBonkPlayer()->GetLocalName(caravan), caravan->GetPlateId(), BonkMobAI::GetUnitGuidText(caravan));
        m_player->GetSession()->SendPacket(&data);
    }
    return caravan;
}

bool BonkRun::FindLyingOrb(float heading, float spread, float minDistance, float maxDistance, float& x, float& y, float& z) const
{
    std::vector<Creature const*> lying;
    Map* map = m_player->GetMap();
    for (Orb const& orb : m_orbs)
        if (!orb.pulled && !orb.mergeId)
            if (Creature const* creature = map->GetCreature(orb.guid))
            {
                float const distance = m_player->GetDistance2d(creature);
                float const offAngle = std::fabs(std::remainder(m_player->GetAngle(creature) - heading, 2.0f * M_PI_F));
                if (distance >= minDistance && distance <= maxDistance && offAngle <= spread)
                    lying.push_back(creature);
            }
    if (lying.empty())
        return false;
    Creature const* pick = lying[urand(0, uint32(lying.size()) - 1)];
    x = pick->GetPositionX();
    y = pick->GetPositionY();
    z = pick->GetPositionZ();
    return true;
}

uint32 BonkRun::StealOrbs(float x, float y, float range)
{
    std::set<ObjectGuid> anchors;
    for (OrbMerge const& merge : m_orbMerges)
        anchors.insert(merge.anchor);
    uint32 experience = 0;
    Map* map = m_player->GetMap();
    for (auto itr = m_orbs.begin(); itr != m_orbs.end();)
    {
        Creature* creature = map->GetCreature(itr->guid);
        if (!creature || itr->pulled || itr->mergeId || anchors.count(itr->guid) || creature->GetDistance2d(x, y) > range)
        {
            ++itr;
            continue;
        }
        experience += itr->experience;
        VanishOrb(creature);
        itr = m_orbs.erase(itr);
    }
    return experience;
}

void BonkRun::DespawnOrbs()
{
    if (Map* map = m_player->FindMap())
        for (Orb const& orb : m_orbs)
            if (Creature* creature = map->GetCreature(orb.guid))
                VanishOrb(creature);
    m_orbs.clear();
    m_orbMerges.clear();
}

void BonkRun::DropShards(Creature const* mob, BonkSpawnKind kind)
{
    uint32 count = 0;
    switch (kind)
    {
        case BONK_SPAWN_NORMAL:   count = roll_chance_f(m_tier.shardChanceNormal) ? 1 : 0; break;
        case BONK_SPAWN_ELITE:    count = roll_chance_f(m_tier.shardChanceElite) ? 1 : 0; break;
        case BONK_SPAWN_MINIBOSS: count = m_tier.shardsMiniboss; break;
        case BONK_SPAWN_BOSS:     count = m_tier.shardsBoss; break;
        default: break;
    }
    uint32 const scaled = uint32(count * (GetBonkMapRewardPercent(m_map.type) + GetGreedRewardPercent()) * GetAmbitionReward(kind) * m_levelRow.reward);
    count = scaled / 100 + (roll_chance_u(scaled % 100) ? 1 : 0);
    if (!count)
        return;

    float const angle = frand(0.0f, 2.0f * M_PI_F);
    float x = mob->GetPositionX() + BONK_SHARD_SCATTER * std::cos(angle);
    float y = mob->GetPositionY() + BONK_SHARD_SCATTER * std::sin(angle);
    float z = m_player->GetMap()->GetHeight(x, y, mob->GetPositionZ() + 2.0f, true, 10.0f);
    if (z <= INVALID_HEIGHT)
    {
        x = mob->GetPositionX();
        y = mob->GetPositionY();
        z = mob->GetPositionZ();
    }
    PlaceTicket(x, y, z, count);
}

void BonkRun::PlaceTicketsAhead()
{
    float const facing = m_player->GetOrientation();
    for (float distance : { 4.0f, 9.0f, 14.0f })
    {
        float const x = m_player->GetPositionX() + distance * std::cos(facing);
        float const y = m_player->GetPositionY() + distance * std::sin(facing);
        float const z = m_player->GetMap()->GetHeight(x, y, m_player->GetPositionZ() + 2.0f, true, 10.0f);
        if (z > INVALID_HEIGHT)
            PlaceTicket(x, y, z, 1);
    }
}

void BonkRun::PlaceTicket(float x, float y, float z, uint32 count)
{
    Creature* ticket = m_player->SummonCreature(BONK_TICKET_PICKUP, x, y, z, frand(0.0f, 2.0f * M_PI_F), TEMPSUMMON_TIMED_DESPAWN,
        BONK_OBJECT_LIFETIME_SEC * IN_MILLISECONDS, false, 0, &InstallOrbAI);
    if (!ticket)
    {
        GiveShards(count);
        return;
    }
    ShowFromFar(ticket);

    ShardDrop drop;
    drop.guid = ticket->GetObjectGuid();
    drop.count = count;
    drop.marker = PlaceMarkerAt(x, y, z, BONK_SPELL_TICKET_POOL, BONK_DROP_POOL_SCALE);
    drop.sparkle = PlaceMarkerAt(x, y, z, BONK_SPELL_FEET_SPARKLE, 1.0f);
    m_shardDrops.push_back(drop);
    m_player->GetBonkPlayer()->Notify(count == 1 ? BONK_STRING_DARKMOON_TICKET_DROPPED : BONK_STRING_TICKETS_DROPPED, { FormatBonkShards(count, GetLocale()) });
}

void BonkRun::UpdateShards(uint32 diff)
{
    m_shardTimer += diff;
    if (m_shardTimer < BONK_SHARD_CHECK_MS || (m_shardDrops.empty() && m_glyphDrops.empty()))
        return;
    m_shardTimer = 0;

    Map* map = m_player->GetMap();
    float heroX, heroY, heroZ;
    GetHeroPositionNow(m_player, heroX, heroY, heroZ);
    for (auto itr = m_glyphDrops.begin(); itr != m_glyphDrops.end();)
    {
        GameObject* go = map->GetGameObject(itr->guid);
        if (go && go->isSpawned() && GetHeroDistance(m_player, heroX, heroY, heroZ, go) > BONK_SHARD_PICKUP_RANGE)
        {
            ++itr;
            continue;
        }
        RemovePickup(itr->guid, itr->marker, itr->sparkle);
        itr = m_glyphDrops.erase(itr);
        QueueGlyphPick();
    }

    float chestX, chestY, chestZ;
    GetHeroChestPositionNow(m_player, chestX, chestY, chestZ);
    float const magnet = GetMagnetRange();
    uint32 taken = 0;
    for (auto itr = m_shardDrops.begin(); itr != m_shardDrops.end();)
    {
        Creature* ticket = map->GetCreature(itr->guid);
        if (!ticket)
        {
            RemoveTicket(*itr, false);
            itr = m_shardDrops.erase(itr);
            continue;
        }
        float const distance = GetHeroDistance(m_player, chestX, chestY, chestZ, ticket);
        if (distance <= BONK_ORB_PICKUP_RANGE || (!itr->pulled && distance <= BONK_SHARD_PICKUP_RANGE))
        {
            taken += itr->count;
            RemoveTicket(*itr, true);
            itr = m_shardDrops.erase(itr);
            continue;
        }
        if (itr->pulled || distance <= magnet)
            PullTicket(*itr, ticket, chestX, chestY, chestZ);
        ++itr;
    }

    if (taken)
        GiveShards(taken);
}

void BonkRun::DropGlyph(Creature const* mob)
{
    if (!CanGainGlyphPick())
        return;

    float const angle = frand(0.0f, 2.0f * M_PI_F);
    float x = mob->GetPositionX() + BONK_SHARD_SCATTER * std::cos(angle);
    float y = mob->GetPositionY() + BONK_SHARD_SCATTER * std::sin(angle);
    float z = m_player->GetMap()->GetHeight(x, y, mob->GetPositionZ() + 2.0f, true, 10.0f);
    if (z <= INVALID_HEIGHT)
    {
        x = mob->GetPositionX();
        y = mob->GetPositionY();
        z = mob->GetPositionZ();
    }

    GameObject* go = PlaceObject(BONK_GO_GLYPH, x, y, z, BONK_OBJECT_LIFETIME_SEC);
    if (!go)
    {
        QueueGlyphPick();
        return;
    }
    ShowFromFar(go);

    GlyphDrop drop;
    drop.guid = go->GetObjectGuid();
    drop.marker = PlaceMarker(go, BONK_SPELL_GLYPH_POOL, BONK_DROP_POOL_SCALE);
    drop.sparkle = PlaceMarker(go, BONK_SPELL_FEET_SPARKLE, 1.0f);
    m_glyphDrops.push_back(drop);
    m_player->GetBonkPlayer()->Notify(BONK_STRING_GLYPH_DROPPED_PICK_IT_UP);
}

void BonkRun::CollectAllGlyphs()
{
    for (GlyphDrop const& drop : m_glyphDrops)
        RemovePickup(drop.guid, drop.marker, drop.sparkle);
    uint32 const count = uint32(m_glyphDrops.size());
    m_glyphDrops.clear();
    for (uint32 i = 0; i < count; ++i)
        QueueGlyphPick();
}

void BonkRun::CollectAllShards()
{
    uint32 taken = 0;
    for (ShardDrop& drop : m_shardDrops)
    {
        taken += drop.count;
        RemoveTicket(drop, true);
    }
    m_shardDrops.clear();

    if (taken)
        GiveShards(taken);
}

void BonkRun::DropHeal(Creature const* mob, BonkSpawnKind kind)
{
    float chance = 100.0f;
    if (kind == BONK_SPAWN_NORMAL)
        chance = BONK_HEAL_CHANCE_NORMAL;
    else if (kind == BONK_SPAWN_ELITE)
        chance = BONK_HEAL_CHANCE_ELITE;
    chance *= 1.0f + GetCardTotal(BONK_CARD_JERKY, 0) / 100.0f;
    if (m_healDrops.size() >= BONK_MAX_HEAL_DROPS || !roll_chance_f(chance))
        return;

    float const angle = frand(0.0f, 2.0f * M_PI_F);
    float x = mob->GetPositionX() - BONK_SHARD_SCATTER * std::cos(angle);
    float y = mob->GetPositionY() - BONK_SHARD_SCATTER * std::sin(angle);
    float z = m_player->GetMap()->GetHeight(x, y, mob->GetPositionZ() + 2.0f, true, 10.0f);
    if (z <= INVALID_HEIGHT)
    {
        x = mob->GetPositionX();
        y = mob->GetPositionY();
        z = mob->GetPositionZ();
    }

    Creature* leg = m_player->SummonCreature(BONK_HEAL_PICKUP, x, y, z, frand(0.0f, 2.0f * M_PI_F),
        TEMPSUMMON_TIMED_DESPAWN, BONK_ORB_LIFETIME_MS, false, 0, &InstallOrbAI);
    if (!leg)
        return;
    HealDrop drop;
    drop.guid = leg->GetObjectGuid();
    if (Creature* sparkle = m_player->SummonCreature(BONK_HEAL_SPARKLE, x, y, z, 0.0f, TEMPSUMMON_TIMED_DESPAWN, BONK_ORB_LIFETIME_MS, false, 0,
        &InstallOrbAI))
        drop.sparkle = sparkle->GetObjectGuid();
    m_healDrops.push_back(drop);
}

void BonkRun::MoveHealDrop(HealDrop const& drop, Creature* leg, float x, float y, float z)
{
    leg->MonsterMoveWithSpeed(x, y, z, -10.0f, BONK_ORB_FLY_SPEED, MOVE_FLY_MODE);
    if (Creature* sparkle = m_player->GetMap()->GetCreature(drop.sparkle))
    {
        sparkle->NearTeleportTo(leg->GetPositionX(), leg->GetPositionY(), leg->GetPositionZ(), sparkle->GetOrientation());
        sparkle->MonsterMoveWithSpeed(x, y, z, -10.0f, BONK_ORB_FLY_SPEED, MOVE_FLY_MODE);
    }
}

void BonkRun::StopHealDrop(HealDrop const& drop, Creature* leg)
{
    leg->StopMoving();
    if (Creature* sparkle = m_player->GetMap()->GetCreature(drop.sparkle))
        sparkle->NearTeleportTo(leg->GetPositionX(), leg->GetPositionY(), leg->GetPositionZ(), sparkle->GetOrientation());
}

void BonkRun::RemoveHealDrop(HealDrop const& drop, Creature* leg, bool vanish)
{
    Map* map = m_player->FindMap();
    Creature* sparkle = map ? map->GetCreature(drop.sparkle) : nullptr;
    for (Creature* creature : { leg, sparkle })
    {
        if (!creature)
            continue;
        if (vanish)
            VanishOrb(creature);
        else
            creature->DespawnOrUnsummon();
    }
}

void BonkRun::UpdateHeals(uint32 diff)
{
    m_healTimer += diff;
    if (m_healTimer < BONK_HEAL_CHECK_MS || m_healDrops.empty())
        return;
    m_healTimer = 0;

    Map* map = m_player->GetMap();
    std::vector<OrbCollector> takers = GetPickupPlayers(PickupSpot::Body, true);
    for (auto itr = m_healDrops.begin(); itr != m_healDrops.end();)
    {
        Creature* leg = map->GetCreature(itr->guid);
        if (!leg)
        {
            RemoveHealDrop(*itr, nullptr, false);
            itr = m_healDrops.erase(itr);
            continue;
        }

        auto eater = std::find_if(takers.begin(), takers.end(), [leg](OrbCollector const& taker)
        {
            return GetHeroDistance(taker.player, taker.x, taker.y, taker.z, leg) <= BONK_ORB_PICKUP_RANGE;
        });
        if (eater != takers.end())
        {
            eater->run->EatHealDrop();
            RemoveHealDrop(*itr, leg, true);
            itr = m_healDrops.erase(itr);
            if (eater->player->GetHealth() >= eater->player->GetMaxHealth())
                takers.erase(eater);
            continue;
        }

        OrbCollector const* target = nullptr;
        for (OrbCollector const& taker : takers)
            if (itr->pulled && taker.player->GetObjectGuid() == itr->puller)
                target = &taker;
        if (!target)
        {
            float nearest = 0.0f;
            for (OrbCollector const& taker : takers)
            {
                float const distance = GetHeroDistance(taker.player, taker.x, taker.y, taker.z, leg);
                if (distance <= taker.magnet && (!target || distance < nearest))
                {
                    target = &taker;
                    nearest = distance;
                }
            }
        }
        if (!target)
        {
            if (itr->pulled)
            {
                itr->pulled = false;
                StopHealDrop(*itr, leg);
            }
            ++itr;
            continue;
        }

        float const x = target->x, y = target->y, z = target->z + 0.5f;
        if (!itr->pulled || itr->puller != target->player->GetObjectGuid() ||
            (x - itr->aimX) * (x - itr->aimX) + (y - itr->aimY) * (y - itr->aimY) + (z - itr->aimZ) * (z - itr->aimZ) >
                BONK_ORB_REAIM_DISTANCE * BONK_ORB_REAIM_DISTANCE)
        {
            itr->pulled = true;
            itr->puller = target->player->GetObjectGuid();
            itr->aimX = x;
            itr->aimY = y;
            itr->aimZ = z;
            MoveHealDrop(*itr, leg, x, y, z);
        }
        ++itr;
    }
}

void BonkRun::GiveShards(uint32 count)
{
    if (m_sandbox)
        return;
    BonkPlayer* bonk = m_player->GetBonkPlayer();
    bonk->AddShards(count);
    sBonkQuests.OnShards(m_player, count);
    m_shardsEarned += count;
    if (bonk->IsAddonReady())
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteShard(data, count, bonk->GetShards());
        m_player->GetSession()->SendPacket(&data);
    }
    bonk->Notify(BONK_STRING_YOU_COLLECTED, { FormatBonkShards(count, GetLocale()) });
    SendState();
}

uint32 BonkRun::PlaceMarkerAt(float x, float y, float z, uint32 spellId, float scale)
{
    uint32 const key = NextBonkAuraKey();
    SendBonkAuraAt(m_player, key, spellId, x, y, z, scale);
    return key;
}

void BonkRun::RemoveTicket(ShardDrop& drop, bool vanish)
{
    for (uint32* key : { &drop.marker, &drop.sparkle })
        if (*key)
        {
            SendBonkAuraGone(m_player, *key);
            *key = 0;
        }
    Map* map = m_player->FindMap();
    Creature* ticket = map ? map->GetCreature(drop.guid) : nullptr;
    if (!ticket)
        return;
    if (vanish)
        VanishOrb(ticket);
    else
        ticket->DespawnOrUnsummon();
}

void BonkRun::PullTicket(ShardDrop& drop, Creature* ticket, float heroX, float heroY, float heroZ)
{
    if (!drop.pulled)
    {
        for (uint32* key : { &drop.marker, &drop.sparkle })
            if (*key)
            {
                SendBonkAuraGone(m_player, *key);
                *key = 0;
            }
        drop.pulled = true;
    }
    else if ((heroX - drop.aimX) * (heroX - drop.aimX) + (heroY - drop.aimY) * (heroY - drop.aimY) + (heroZ - drop.aimZ) * (heroZ - drop.aimZ) <=
        BONK_ORB_REAIM_DISTANCE * BONK_ORB_REAIM_DISTANCE)
        return;
    drop.aimX = heroX;
    drop.aimY = heroY;
    drop.aimZ = heroZ;
    ticket->MonsterMoveWithSpeed(heroX, heroY, heroZ, -10.0f, BONK_ORB_FLY_SPEED, MOVE_FLY_MODE);
}

uint32 BonkRun::PlaceMarker(GameObject const* go, uint32 spellId, float scale)
{
    uint32 const key = NextBonkAuraKey();
    SendBonkAuraAt(m_player, key, spellId, go->GetPositionX(), go->GetPositionY(), go->GetPositionZ(), scale);
    return key;
}

void BonkRun::ShowFromFar(WorldObject* object)
{
    object->SetVisibilityModifier(BONK_DROP_SIGHT);
    object->SetActiveObjectState(true);
}

void BonkRun::RemovePickup(ObjectGuid const& goGuid, uint32 beamKey, uint32 sparkleKey, uint32 coreKey)
{
    for (uint32 key : { beamKey, sparkleKey, coreKey })
        if (key)
            SendBonkAuraGone(m_player, key);
    Map* map = m_player->FindMap();
    if (!map)
        return;
    if (GameObject* go = map->GetGameObject(goGuid))
        go->Delete();
}

float BonkRun::GetGoldMultiplier() const
{
    return (1.0f + (GetPassiveTotal(BONK_PASSIVE_GREED) + m_bonuses.goldBonus + GetGreedRewardPercent()) / 100.0f) *
        (IsChallenge() ? BONK_CHALLENGE_GOLD : 1.0f) * m_levelRow.reward;
}

void BonkRun::GiveGold(uint32 copper)
{
    copper = uint32(copper * GetGoldMultiplier());
    if (!copper || m_sandbox)
        return;
    m_player->ModifyMoney(int32(copper));
    m_goldEarned += copper;
}

void BonkRun::OnMobKilled(Creature* mob, BonkSpawnKind kind, Unit* killer)
{
    if (m_state != STATE_RUNNING)
        return;
    ShakeOnKill(kind);

    ForgetEnemyAttacks(mob);
    if (kind == BONK_SPAWN_BOSS || kind == BONK_SPAWN_MINIBOSS)
    {
        m_objectives.RemoveFollowing(m_player, mob->GetObjectGuid());
        SpeakBossLine(mob, BONK_BOSS_LINE_DEATH);
    }
    bool const stageBossDown = OnStageBossKilled(mob);
    if (stageBossDown)
        SendBossMusic(false);

    bool const eventGroup = m_miniEventActive &&
        std::find(m_miniEvent.targets.begin(), m_miniEvent.targets.end(), mob->GetObjectGuid()) != m_miniEvent.targets.end();
    bool const eventPaysChest = eventGroup || (m_miniEventActive && mob->GetObjectGuid() == m_miniEvent.target);
    OnMiniEventTargetKilled(mob);

    BonkRun* rewarded = GetKillRewardRun(killer);
    rewarded->RewardKill(mob, kind, killer, eventGroup);
    auto const arrival = m_bossArrivals.find(mob->GetObjectGuid());
    if (arrival != m_bossArrivals.end())
    {
        sBonkQuests.OnBossFight(m_player, kind, (m_totalMs - arrival->second.ms) / IN_MILLISECONDS, !m_hurt || m_lastHurtMs < arrival->second.ms,
            uint32(m_player->GetHealthPercent()));
        LogBossFight(mob, kind, arrival->second);
        m_bossArrivals.erase(arrival);
    }
    if (kind == BONK_SPAWN_BOSS)
        sBonkQuests.OnBossKilled(m_player, m_tier.id, m_stage, m_elapsedMs / IN_MILLISECONDS);

    if (kind != BONK_SPAWN_NORMAL)
    {
        if (!eventPaysChest && !m_sandbox)
        {
            DropChest(mob, kind);
            DropGear(mob, kind);
        }
        OnAffixedDeath(mob);
        rewarded->SendMobDead(mob, true);
        if (rewarded != this)
            SendMobDead(mob, true);
    }
    else if (IsPlatedMob(mob))
    {
        rewarded->SendMobDead(mob, false);
        if (rewarded != this)
            SendMobDead(mob, false);
    }

    OnHiddenKilled(mob);
    if (kind == BONK_SPAWN_MINIBOSS && !m_sandbox && ++m_glyphMiniBosses == 1)
        DropGlyph(mob);

    if (stageBossDown)
    {
        if (m_stoneBoss)
            GiveExperience(GetNextLevelXp());
        if (IsGlyphBossStage())
            DropGlyph(mob);
        if (!IsFinale())
            OpenPortal(mob);
    }
}

bool BonkRun::IsPlatedMob(Creature const* mob)
{
    BonkMobAI const* ai = dynamic_cast<BonkMobAI const*>(mob->AI());
    return ai && ai->GetPlateKind();
}

BonkRun* BonkRun::GetKillRewardRun(Unit* killer)
{
    Player* player = killer ? killer->GetCharmerOrOwnerPlayerOrPlayerItself() : nullptr;
    if (!player || player == m_player || player->GetMapId() != m_player->GetMapId())
        return this;
    if (!m_player->GetGroup() || !m_player->GetGroup()->IsMember(player->GetObjectGuid()))
        return this;
    BonkRun* run = player->GetBonkPlayer()->GetRun();
    return run && run->m_state == STATE_RUNNING ? run : this;
}

void BonkRun::SendMobDead(Creature const* mob, bool named) const
{
    if (!m_player->GetBonkPlayer()->IsAddonReady())
        return;
    WorldPacket data(SMSG_HOA_MESSAGE);
    HoAWriteMobDead(data, named ? m_player->GetBonkPlayer()->GetLocalName(mob) : "", mob->GetPlateId(),
        BonkMobAI::GetUnitGuidText(mob));
    m_player->GetSession()->SendPacket(&data);
}

void BonkRun::RewardKill(Creature* mob, BonkSpawnKind kind, Unit* killer, bool eventGroup)
{
    ++m_kills;
    SpreadFrom(mob);
    SpreadKeywords(mob);
    m_petTimer = BONK_PET_CHECK_MS;
    if (IsSummon(killer))
        FeedFrenzy();
    uint32 const killingSpell = BonkStats::CountKill(m_player->GetObjectGuid(), mob->GetObjectGuid(), kind);
    QueueTrickShot(mob, killingSpell);
    EnrageOnKill(killingSpell);
    QueueChainExecution(mob, killingSpell);
    float heading;
    sBonkQuests.OnKill(m_player, kind, killingSpell, mob->GetCreatureType(), mob->GetEntry(), !GetHeading(heading));
    SoulSiphon(killingSpell);
    if (kind == BONK_SPAWN_MINIBOSS)
        m_masteryXp += uint32(m_tier.masteryXpMiniboss * GetBonkMapRewardPercent(m_map.type) / 100 * GetAmbitionReward(kind));
    else if (kind == BONK_SPAWN_BOSS)
        m_masteryXp += m_tier.masteryXpBoss * GetBonkMapRewardPercent(m_map.type) / 100;
    BonkMobAI const* mobAI = dynamic_cast<BonkMobAI const*>(mob->AI());
    bool const veteran = mobAI && mobAI->IsVeteran();
    float const reward = GetKindReward(kind) * (veteran ? BONK_VETERAN_REWARD : 1.0f) * GetAmbitionReward(kind);
    GiveGold(uint32(m_map.goldPerKill * reward + 0.5f));
    m_cardValorCarry += m_map.coinsPerKill * reward * (1.0f + GetCardTotal(BONK_CARD_VALOR, 0) / 100.0f);
    GainValor(uint32(m_cardValorCarry));
    m_cardValorCarry -= float(uint32(m_cardValorCarry));
    if (HasCard(BONK_CARD_KILL_POWER))
        AddKillPowerStack();

    if (kind != BONK_SPAWN_BOSS)
    {
        uint32 const level = m_player->GetLevel() + m_overcapLevel;
        float const overcapSlowdown = 1.0f + float(std::max(0, int32(level) - BONK_OVERCAP_XP_START_LEVEL)) / BONK_OVERCAP_XP_DOUBLING_LEVELS;
        float const killsForLevel = (4.0f + 1.5f * level + 0.05f * level * level) * overcapSlowdown;
        float const growth = 1.0f + GetPassiveTotal(BONK_PASSIVE_GROWTH) / 100.0f;

        float experience = reward;
        if (kind == BONK_SPAWN_ELITE && GetGlyph(BONK_GLYPH_HUNT))
            experience *= GetGlyphValue(BONK_GLYPH_HUNT, 1);
        BonkOrb colour = BONK_ORB_RED;
        if (kind == BONK_SPAWN_NORMAL)
        {
            BonkArchetypeInfo const& archetype = sBonkMgr.GetArchetype(mobAI ? mobAI->GetArchetype() : BONK_ARCHETYPE_GRUNT);
            experience *= archetype.experience;
            colour = veteran ? BONK_ORB_GREEN : archetype.orb;
        }
        uint32 xp = uint32(std::ceil(GetNextLevelXp() / killsForLevel * experience * growth));
        if (IsInMoonwell(mob->GetPositionX(), mob->GetPositionY()))
            xp *= 2;
        DropOrb(mob, xp, colour);
    }
    if (!m_sandbox)
        DropShards(mob, kind);
    DropHeal(mob, kind);
    if (kind == BONK_SPAWN_ELITE && GetGlyph(BONK_GLYPH_SCAVENGER) && !eventGroup)
        SpawnPowerup(mob);
    OnGlyphKill(mob, kind);
}

void BonkRun::SpeakBossLine(Creature const* boss, BonkBossLine line) const
{
    if (!boss)
        return;
    BonkMobAI const* ai = dynamic_cast<BonkMobAI const*>(boss->AI());
    if (!ai || (ai->GetKind() != BONK_SPAWN_BOSS && ai->GetKind() != BONK_SPAWN_MINIBOSS))
        return;
    if (uint32 const soundId = sBonkMgr.PickBossLineSound(boss->GetEntry(), line))
        boss->PlayDirectSound(soundId, m_player);
}

void BonkRun::UpdateBossVoices()
{
    Map* map = m_player->GetMap();
    for (auto& arrival : m_bossArrivals)
    {
        if (arrival.second.spokeFightLine)
            continue;
        Creature* boss = map->GetCreature(arrival.first);
        if (!boss || !boss->IsAlive() || boss->GetHealthPercent() > BONK_BOSS_FIGHT_LINE_HEALTH_PCT)
            continue;
        arrival.second.spokeFightLine = true;
        SpeakBossLine(boss, BONK_BOSS_LINE_FIGHT);
    }
}

void BonkRun::SendBossMusic(bool playing) const
{
    if (!m_player->GetBonkPlayer()->IsAddonReady())
        return;
    WorldPacket data(SMSG_HOA_MESSAGE);
    HoAWriteMusic(data, playing ? "boss" : "stop");
    m_player->GetSession()->SendPacket(&data);
}

BonkRun::OwnedWeapon* BonkRun::FindOwned(uint32 weaponId)
{
    auto itr = std::find_if(m_weapons.begin(), m_weapons.end(), [weaponId](OwnedWeapon const& owned) { return owned.weapon.id == weaponId; });
    return itr != m_weapons.end() ? &*itr : nullptr;
}

BonkRun::OwnedWeapon const* BonkRun::FindOwned(uint32 weaponId) const
{
    auto itr = std::find_if(m_weapons.begin(), m_weapons.end(), [weaponId](OwnedWeapon const& owned) { return owned.weapon.id == weaponId; });
    return itr != m_weapons.end() ? &*itr : nullptr;
}

uint32 BonkRun::GetReachRingRoot(uint32 slot) const
{
    return slot >= 1 && slot <= m_weapons.size() ? GetRootWeapon(m_weapons[slot - 1].weapon) : 0;
}

uint32 BonkRun::GetReachRingSlot(uint32 rootId) const
{
    for (uint32 index = 0; rootId && index < m_weapons.size(); ++index)
        if (GetRootWeapon(m_weapons[index].weapon) == rootId)
            return index + 1;
    return 0;
}

float BonkRun::GetReachRingSize(uint32 rootId) const
{
    uint32 const slot = GetReachRingSlot(rootId);
    if (!slot)
        return 0.0f;
    OwnedWeapon const& owned = m_weapons[slot - 1];
    BonkWeapon const& weapon = owned.weapon;
    if (weapon.range <= weapon.radius)
        return GetWeaponRadius(owned);
    return weapon.range * (weapon.IsMeleeStrike() ? GetWeaponArea(owned) : 1.0f);
}

std::string BonkRun::GetReachRingName(uint32 slot) const
{
    if (slot < 1 || slot > m_weapons.size())
        return "";
    BonkWeapon const& weapon = m_weapons[slot - 1].weapon;
    return Localize(BONK_FIELD_WEAPON_NAME, weapon.id, weapon.name);
}

bool BonkRun::IsEvolutionBanished(uint32 evolvedId) const
{
    Offer probe;
    probe.step = BONK_STEP_EVOLVE;
    probe.evolveTo = evolvedId;
    return m_banished.count(GetBanishKey(probe)) != 0;
}

std::vector<BonkWeapon const*> BonkRun::GetOpenEvolutions(OwnedWeapon const& owned) const
{
    std::vector<BonkWeapon const*> open;
    if (owned.weapon.evolvesFrom || IsWildShapeshift(owned))
        return open;
    uint32 const account = m_player->GetBonkPlayer()->GetProgressAccount();
    for (BonkWeapon const* evolved : sBonkMgr.GetEvolutions(owned.weapon.id))
        if (!sBonkQuests.IsLocked(account, BONK_REWARD_WEAPON, evolved->id) && !IsEvolutionBanished(evolved->id))
            open.push_back(evolved);
    return open;
}

bool BonkRun::IsOpenEvolution(OwnedWeapon const& owned, uint32 evolvedId) const
{
    std::vector<BonkWeapon const*> const open = GetOpenEvolutions(owned);
    return std::any_of(open.begin(), open.end(), [evolvedId](BonkWeapon const* evolved) { return evolved->id == evolvedId; });
}

uint32 BonkRun::PickEvolution(OwnedWeapon const& owned) const
{
    std::vector<BonkWeapon const*> const open = GetOpenEvolutions(owned);
    return open.empty() ? 0 : open[urand(0, uint32(open.size() - 1))]->id;
}

bool BonkRun::CanEvolve(OwnedWeapon const& owned) const
{
    return !GetOpenEvolutions(owned).empty();
}

bool BonkRun::IsMaxAtPickup(BonkWeapon const& weapon)
{
    if (weapon.evolvesFrom)
        return false;
    return weapon.behavior == BONK_BEHAVIOR_BLADE_FLURRY || weapon.behavior == BONK_BEHAVIOR_SHADOW_DANCE ||
        weapon.behavior == BONK_BEHAVIOR_EVASION;
}

uint32 BonkRun::GetSpellRankTotal() const
{
    uint32 total = 0;
    for (OwnedWeapon const& owned : m_weapons)
        if (!IsMaxAtPickup(owned.weapon))
            total += owned.rank;
    return total;
}

uint32 BonkRun::GetWindowEvolveRanks() const
{
    return std::max(1u, BONK_WINDOW_EVOLVE_TOTAL_RANKS * GetEvolveRank() / BONK_EVOLVE_RANK);
}

bool BonkRun::HasEvolveRank(OwnedWeapon const& owned) const
{
    if (IsMaxAtPickup(owned.weapon))
        return GetSpellRankTotal() >= GetWindowEvolveRanks();
    return owned.rank >= GetEvolveRank();
}

uint32 BonkRun::GetRanksPastEvolveRank(OwnedWeapon const& owned) const
{
    if (!HasEvolveRank(owned))
        return 0;
    if (IsMaxAtPickup(owned.weapon))
        return GetSpellRankTotal() - GetWindowEvolveRanks();
    return owned.rank - GetEvolveRank();
}

float BonkRun::GetLegendaryChance(OwnedWeapon const& owned) const
{
    if (!HasEvolveRank(owned) || !CanEvolve(owned))
        return 0.0f;
    float const fromRank = std::min(BONK_LEGENDARY_MAX_RANK_CHANCE,
        BONK_LEGENDARY_BASE_CHANCE + BONK_LEGENDARY_CHANCE_PER_RANK * float(GetRanksPastEvolveRank(owned)));
    return fromRank + BONK_LEGENDARY_CHANCE_PER_LUCK * std::max(0.0f, GetPassiveTotal(BONK_PASSIVE_LUCK));
}

std::string BonkRun::DescribeEvolutionChance(OwnedWeapon const& owned, uint32& chance) const
{
    chance = 0;
    if (IsWildShapeshift(owned))
        return GetString(BONK_STRING_EVOLVE_HEART_OF_THE_WILD);
    uint32 const account = m_player->GetBonkPlayer()->GetProgressAccount();
    std::vector<BonkWeapon const*> const evolutions = sBonkMgr.GetEvolutions(owned.weapon.id);
    std::vector<std::string> sentences;
    std::vector<std::string> locks;
    for (BonkWeapon const* evolved : evolutions)
    {
        if (!sBonkQuests.IsLocked(account, BONK_REWARD_WEAPON, evolved->id))
            continue;
        BonkQuest const* quest = sBonkQuests.GetUnlockingQuest(BONK_REWARD_WEAPON, evolved->id);
        std::string const name = Localize(BONK_FIELD_WEAPON_NAME, evolved->id, evolved->name);
        locks.push_back(quest ? GetString(BONK_STRING_FINISH_QUEST_TO_UNLOCK, { Localize(BONK_FIELD_QUEST_NAME, quest->id, quest->name), name }) :
            GetString(BONK_STRING_EVOLVE_LOCKED, { name }));
    }

    if (!CanEvolve(owned))
    {
        if (locks.empty())
            sentences.push_back(GetString(evolutions.size() == 1 ? BONK_STRING_EVOLVE_BANISHED : BONK_STRING_EVOLVE_BANISHED_ALL));
    }
    else if (!HasEvolveRank(owned) && IsMaxAtPickup(owned.weapon))
        sentences.push_back(GetString(BONK_STRING_EVOLVE_AT_SPELL_RANK_TOTAL,
            { std::to_string(GetWindowEvolveRanks()), std::to_string(GetSpellRankTotal()) }));
    else if (!HasEvolveRank(owned))
        sentences.push_back(GetString(BONK_STRING_EVOLVE_FROM_RANK, { std::to_string(GetEvolveRank()) }));
    else if (FindAscensionWeapon() == &owned)
    {
        chance = 100;
        BonkCard const* ascension = m_cardByEffect[BONK_CARD_ASCENSION];
        sentences.push_back(GetString(BONK_STRING_EVOLVE_ASCENSION, { Localize(BONK_FIELD_CARD_NAME, ascension->id, ascension->name) }));
    }
    else
    {
        float const legendary = GetLegendaryChance(owned);
        chance = uint32(legendary + 0.5f);
        sentences.push_back(GetString(BONK_STRING_EVOLVE_CHANCE, { Percent(std::round(legendary * 10.0f) / 10.0f) }));
    }
    sentences.insert(sentences.end(), locks.begin(), locks.end());

    std::string text;
    for (std::string const& sentence : sentences)
        text += (text.empty() ? "" : " ") + sentence;
    return text;
}

bool BonkRun::HasEvolutionLeft() const
{
    if (m_weapons.size() < GetSpellSlots())
        return true;
    return std::any_of(m_weapons.begin(), m_weapons.end(), [this](OwnedWeapon const& owned) { return CanEvolve(owned); });
}

BonkRun::OwnedWeapon const* BonkRun::FindAscensionWeapon() const
{
    if (!HasCard(BONK_CARD_ASCENSION))
        return nullptr;
    for (OwnedWeapon const& owned : m_weapons)
        if (HasEvolveRank(owned) && CanEvolve(owned))
            return &owned;
    return nullptr;
}

void BonkRun::UseAscension(OwnedWeapon const& owned)
{
    BonkCard const* ascension = m_cardByEffect[BONK_CARD_ASCENSION];
    if (!ascension)
        return;
    std::string const name = Localize(BONK_FIELD_CARD_NAME, ascension->id, ascension->name);
    RemoveCard(*ascension);
    m_player->GetBonkPlayer()->Notify(BONK_STRING_ASCENSION_REVEALS_EVOLUTION, { name, Localize(BONK_FIELD_WEAPON_NAME, owned.weapon.id, owned.weapon.name) });
}

void BonkRun::ShowAllEvolutions(std::vector<Offer>& cards) const
{
    if (!m_bonuses.secondSight)
        return;

    auto hasEvolution = [](std::vector<Offer> const& list, uint32 evolvedId)
    {
        return std::any_of(list.begin(), list.end(), [evolvedId](Offer const& card)
        {
            return card.isWeapon && card.step == BONK_STEP_EVOLVE && card.evolveTo == evolvedId;
        });
    };

    std::vector<Offer> shown;
    for (Offer const& card : cards)
    {
        shown.push_back(card);
        if (!card.isWeapon || card.step != BONK_STEP_EVOLVE)
            continue;
        OwnedWeapon const* owned = FindOwned(card.id);
        if (!owned)
            continue;
        for (BonkWeapon const* evolved : GetOpenEvolutions(*owned))
            if (!hasEvolution(cards, evolved->id) && !hasEvolution(shown, evolved->id))
                shown.push_back(MakeEvolveOffer(*owned, evolved->id));
    }

    while (shown.size() > BONK_MAX_OFFER_SIZE)
    {
        auto spare = std::find_if(shown.rbegin(), shown.rend(), [](Offer const& card)
        {
            return !card.locked && card.step != BONK_STEP_EVOLVE;
        });
        if (spare == shown.rend())
            break;
        shown.erase(std::next(spare).base());
    }
    if (shown.size() > BONK_MAX_OFFER_SIZE)
        shown.resize(BONK_MAX_OFFER_SIZE);
    cards = shown;
}

float BonkRun::GetRarityWeight(uint8 rarity, BonkRarity minimum) const
{
    if (rarity >= BONK_RARITY_LEGENDARY || rarity < std::max(minimum, m_rarityFloor))
        return 0.0f;
    float const luck = std::max(0.0f, GetPassiveTotal(BONK_PASSIVE_LUCK));
    return BONK_RARITY_WEIGHT[rarity] * (1.0f + BONK_RARITY_LUCK[rarity] * luck / 100.0f);
}

BonkRarity BonkRun::RollRarity(BonkRarity minimum) const
{
    float weights[BONK_RARITY_LEGENDARY];
    float total = 0.0f;
    for (uint8 rarity = 0; rarity < BONK_RARITY_LEGENDARY; ++rarity)
    {
        weights[rarity] = GetRarityWeight(rarity, minimum);
        total += weights[rarity];
    }

    float roll = frand(0.0f, total);
    for (uint8 rarity = 0; rarity < BONK_RARITY_LEGENDARY; ++rarity)
    {
        if (weights[rarity] > 0.0f && roll < weights[rarity])
            return BonkRarity(rarity);
        roll -= weights[rarity];
    }
    return BONK_RARITY_EPIC;
}

void BonkRun::RollUpgrades(OwnedWeapon const& owned, Offer& offer) const
{
    for (BonkSpellUpgrade& upgrade : offer.upgrades)
        upgrade = BONK_SPELL_UPGRADE_NONE;
    if (offer.step != BONK_STEP_RANK || offer.rarity >= BONK_RARITY_LEGENDARY)
        return;

    float rolled[MAX_BONK_SPELL_UPGRADE] = {};
    uint8 const count = GetRankUpgradeCount(&owned, offer.rarity);
    for (uint8 i = 0; i < count; ++i)
    {
        std::vector<BonkWeaponUpgrade const*> const options = GetUpgradeOptions(owned, offer.rarity, rolled);
        if (options.empty())
            break;
        float totalWeight = 0.0f;
        for (BonkWeaponUpgrade const* option : options)
            totalWeight += GetUpgradeRollWeight(option->upgrade);
        float roll = frand(0.0f, totalWeight);
        BonkWeaponUpgrade const* pick = options.back();
        for (BonkWeaponUpgrade const* option : options)
        {
            roll -= GetUpgradeRollWeight(option->upgrade);
            if (roll <= 0.0f)
            {
                pick = option;
                break;
            }
        }
        offer.upgrades[i] = pick->upgrade;
        rolled[pick->upgrade] += pick->step;
    }
}

std::vector<BonkWeaponUpgrade const*> BonkRun::GetUpgradeOptions(OwnedWeapon const& owned, BonkRarity rarity, float const* rolled) const
{
    std::vector<BonkWeaponUpgrade const*> options;
    for (BonkWeaponUpgrade const& upgrade : owned.weapon.upgrades)
    {
        if ((upgrade.upgrade == BONK_SPELL_UPGRADE_HIT_TWICE || upgrade.upgrade == BONK_SPELL_UPGRADE_ECHO || upgrade.upgrade == BONK_SPELL_UPGRADE_TARGETS) &&
            rarity != BONK_RARITY_EPIC)
            continue;
        float const cap = BONK_SPELL_UPGRADE_CAP[upgrade.upgrade];
        if (cap > 0.0f && owned.upgrades[upgrade.upgrade] + rolled[upgrade.upgrade] + upgrade.step > cap + 0.001f)
            continue;
        if (upgrade.upgrade == BONK_SPELL_UPGRADE_HASTE && !HasteShortensCooldown(owned, rolled[upgrade.upgrade], upgrade.step))
            continue;
        if (!DurationGrowsWindow(owned, rolled, upgrade.upgrade, upgrade.step))
            continue;
        options.push_back(&upgrade);
    }
    return options;
}

bool BonkRun::OfferGainsAnything(OwnedWeapon const& owned, Offer const& offer) const
{
    if (offer.step != BONK_STEP_RANK || offer.rarity >= BONK_RARITY_LEGENDARY || RankDamageCounts(owned))
        return true;
    return owned.rank < BONK_DAMAGELESS_MAX_RANK || offer.upgrades[0] != BONK_SPELL_UPGRADE_NONE;
}

bool BonkRun::IsEmptyRankUp(Offer const& offer) const
{
    if (!offer.isWeapon || offer.isCard || offer.step != BONK_STEP_RANK)
        return false;
    OwnedWeapon const* owned = FindOwned(offer.id);
    return owned && (IsMaxAtPickup(owned->weapon) || !OfferGainsAnything(*owned, offer));
}

bool BonkRun::IsRankMaxed(OwnedWeapon const& owned) const
{
    if (IsMaxAtPickup(owned.weapon))
        return true;
    if (owned.rank < BONK_DAMAGELESS_MAX_RANK || RankDamageCounts(owned))
        return false;
    float const nothingRolled[MAX_BONK_SPELL_UPGRADE] = {};
    return GetUpgradeOptions(owned, BONK_RARITY_EPIC, nothingRolled).empty();
}

bool BonkRun::HasteShortensCooldown(OwnedWeapon const& owned, float alreadyRolled, float step) const
{
    OwnedWeapon before = owned;
    before.upgrades[BONK_SPELL_UPGRADE_HASTE] += alreadyRolled;
    OwnedWeapon after = before;
    after.upgrades[BONK_SPELL_UPGRADE_HASTE] += step;
    return GetWeaponCooldown(before) >= GetWeaponCooldown(after) + BONK_MIN_SHOWN_COOLDOWN_GAIN_MS;
}

BonkRun::Offer BonkRun::MakeRankOffer(OwnedWeapon const& owned, BonkRarity minimum) const
{
    float const legendary = GetLegendaryChance(owned);
    if (legendary > 0.0f && roll_chance_f(legendary))
        if (uint32 const evolveTo = PickEvolution(owned))
            return MakeEvolveOffer(owned, evolveTo);

    Offer offer;
    offer.id = owned.weapon.id;
    offer.newLevel = owned.rank + 1;
    offer.rarity = RollRarity(minimum);
    offer.step = BONK_STEP_RANK;
    RollUpgrades(owned, offer);
    return offer;
}

BonkRun::Offer BonkRun::MakeEvolveOffer(OwnedWeapon const& owned, uint32 evolveTo) const
{
    Offer offer;
    offer.id = owned.weapon.id;
    offer.newLevel = owned.rank + 1;
    offer.rarity = BONK_RARITY_LEGENDARY;
    offer.step = BONK_STEP_EVOLVE;
    offer.evolveTo = evolveTo;
    return offer;
}

void BonkRun::ApplyStep(OwnedWeapon& owned, Offer const& offer)
{
    ++owned.rank;
    owned.rarities += char('0' + int(offer.rarity));
    if (offer.step == BONK_STEP_EVOLVE)
    {
        BonkWeapon const* evolved = sBonkMgr.GetWeapon(offer.evolveTo);
        if (evolved && evolved->evolvesFrom == owned.weapon.id)
            EvolveWeapon(owned, *evolved);
        return;
    }
    if (offer.step != BONK_STEP_RANK || offer.rarity >= BONK_RARITY_LEGENDARY)
        return;

    AddRankGains(owned, offer);

    if (owned.weapon.behavior == BONK_BEHAVIOR_PET || owned.weapon.behavior == BONK_BEHAVIOR_WRATH)
        for (OwnedWeapon& other : m_weapons)
            if (other.weapon.behavior == BONK_BEHAVIOR_PET || other.weapon.behavior == BONK_BEHAVIOR_WRATH)
                UpdatePets(other);
    if (owned.weapon.behavior == BONK_BEHAVIOR_WRATH || owned.weapon.HasFlag(BONK_WEAPON_FLAG_SNAKES))
        DressSnakes();
    if (owned.weapon.behavior == BONK_BEHAVIOR_WRATH)
        DressBeasts();
}

void BonkRun::EvolveWeapon(OwnedWeapon& owned, BonkWeapon const& evolved)
{
    std::string const from = Localize(BONK_FIELD_WEAPON_NAME, owned.weapon.id, owned.weapon.name);
    owned.weapon = evolved;
    ApplyMasteryTo(owned.weapon);
    owned.timer = 500;
    RebuildWeaponSpells();
    if (UsesShotSources())
        WarmShotSources();
    if (evolved.IsBlink() || evolved.IsArcaneMissiles())
        m_player->GetBonkPlayer()->SendDash();
    m_player->GetBonkPlayer()->Notify(BONK_STRING_EVOLVED_INTO, { from, Localize(BONK_FIELD_WEAPON_NAME, evolved.id, evolved.name) });
}

bool BonkRun::ForceEvolve(uint32 weaponId, std::string& error)
{
    if (m_state != STATE_RUNNING && m_state != STATE_PORTAL)
    {
        error = GetString(BONK_STRING_YOU_ARE_NOT_IN_RUNNING);
        return false;
    }

    BonkWeapon const* evolved = sBonkMgr.GetWeapon(weaponId);
    if (!evolved)
    {
        error = GetString(BONK_STRING_THERE_IS_NO_SPELL, { std::to_string(weaponId) });
        return false;
    }

    std::string const name = Localize(BONK_FIELD_WEAPON_NAME, evolved->id, evolved->name);
    bool const held = std::any_of(m_weapons.begin(), m_weapons.end(), [weaponId](OwnedWeapon const& owned)
    {
        return owned.weapon.id == weaponId || owned.weapon.evolvesFrom == weaponId;
    });
    if (!evolved->evolvesFrom && !held)
    {
        if (m_weapons.size() >= GetSpellSlots())
        {
            error = GetString(BONK_STRING_NO_FREE_SPELL_SLOT_FOR, { name });
            return false;
        }
        AddWeapon(*evolved);
        SendLoadout();
        return true;
    }
    if (!evolved->evolvesFrom)
    {
        std::string choices;
        for (BonkWeapon const* evolution : sBonkMgr.GetEvolutions(weaponId))
            choices += (choices.empty() ? "" : ", ") + Localize(BONK_FIELD_WEAPON_NAME, evolution->id, evolution->name) + " (" + std::to_string(evolution->id) + ")";
        error = choices.empty() ? GetString(BONK_STRING_NOT_AN_EVOLUTION_NONE, { name }) : GetString(BONK_STRING_NOT_AN_EVOLUTION, { name, choices });
        return false;
    }

    OwnedWeapon* owned = FindOwned(evolved->evolvesFrom);
    if (!owned)
    {
        auto sibling = std::find_if(m_weapons.begin(), m_weapons.end(), [evolved](OwnedWeapon const& weapon)
        {
            return weapon.weapon.evolvesFrom == evolved->evolvesFrom;
        });
        owned = sibling != m_weapons.end() ? &*sibling : nullptr;
    }
    if (!owned)
    {
        BonkWeapon const* base = sBonkMgr.GetWeapon(evolved->evolvesFrom);
        if (!base || m_weapons.size() >= GetSpellSlots())
        {
            error = base ? GetString(BONK_STRING_NO_FREE_SPELL_SLOT_FOR, { Localize(BONK_FIELD_WEAPON_NAME, base->id, base->name) }) : GetString(BONK_STRING_NO_FREE_SPELL_SLOT_FOR_BASE);
            return false;
        }
        AddWeapon(*base);
        owned = FindOwned(base->id);
    }
    if (!owned || owned->weapon.id == evolved->id)
    {
        error = GetString(BONK_STRING_YOU_ALREADY_HAVE, { name });
        return false;
    }

    if (owned->weapon.id == evolved->evolvesFrom)
        ApplyStep(*owned, MakeEvolveOffer(*owned, evolved->id));
    else
        EvolveWeapon(*owned, *evolved);
    SendLoadout();
    return true;
}

bool BonkRun::GivePassive(uint32 passiveId, std::string& error)
{
    BonkPassive const* passive = sBonkMgr.GetPassive(passiveId);
    if (!passive)
    {
        error = GetString(BONK_STRING_THERE_IS_NO_PASSIVE, { std::to_string(passiveId) });
        return false;
    }

    std::string const name = Localize(BONK_FIELD_PASSIVE_NAME, passive->id, passive->name);

    auto rank = m_passiveRanks.find(passiveId);
    uint8 const current = rank != m_passiveRanks.end() ? rank->second : 0;
    size_t const ownedPassives = std::count_if(m_passiveRanks.begin(), m_passiveRanks.end(), [](auto const& itr) { return itr.second > 0; });
    if (passive->IsMaxed(current))
    {
        error = GetString(BONK_STRING_ALREADY_HIGHEST_RANK, { name });
        return false;
    }
    if (!current && ownedPassives >= GetPassiveSlots())
    {
        error = GetString(BONK_STRING_NO_FREE_PASSIVE_SLOT_FOR, { name });
        return false;
    }

    m_passiveRanks[passiveId] = uint8(current + 1);
    ApplyPassives();
    SendLoadout();
    m_player->GetBonkPlayer()->Notify(BONK_STRING_NOW_RANK, { name, std::to_string(current + 1) });
    return true;
}

bool BonkRun::IsPassiveAllowed(BonkPassive const& passive) const
{
    switch (passive.effect)
    {
        case BONK_PASSIVE_POISON_DAMAGE:  return sBonkMgr.HasKeywordSpell(m_player->GetClassMask(), BONK_KEYWORD_POISON);
        case BONK_PASSIVE_BURNING_DAMAGE: return sBonkMgr.HasKeywordSpell(m_player->GetClassMask(), BONK_KEYWORD_BURNING);
        case BONK_PASSIVE_BLEED_DAMAGE:   return sBonkMgr.HasKeywordSpell(m_player->GetClassMask(), BONK_KEYWORD_BLEED);
        default:                          return true;
    }
}

size_t BonkRun::GetSpellSlots() const
{
    if (m_sandboxBench)
        return BONK_BENCH_SPELL_SLOTS;
    return std::min(BONK_MAX_SPELL_SLOTS, BONK_START_SPELL_SLOTS + m_bonuses.spellSlots);
}

size_t BonkRun::GetPassiveSlots() const
{
    return std::min(BONK_MAX_PASSIVE_SLOTS, BONK_START_PASSIVE_SLOTS + m_bonuses.passiveSlots);
}

bool BonkRun::IsStatCapped(BonkPassiveEffect effect) const
{
    float const cap = GetStatCap(effect);
    return cap > 0.0f && GetPassiveTotal(effect) >= cap;
}

bool BonkRun::IsGainTooSmall(BonkPassiveEffect effect, float gain) const
{
    if (IsStatCapped(effect))
        return true;
    float const ceiling = effect == BONK_PASSIVE_HASTE ? BONK_MAX_HASTE : effect == BONK_PASSIVE_AREA ? BONK_MAX_AREA : 0.0f;
    if (ceiling <= 0.0f || gain <= 0.0f)
        return false;
    float const raw = GetPassiveTotal(effect);
    return CurveStat(raw + gain, ceiling) - CurveStat(raw, ceiling) < BONK_MIN_CURVED_GAIN;
}

bool BonkRun::IsPassiveCapped(BonkPassive const& passive) const
{
    auto rank = m_passiveRanks.find(passive.id);
    uint32 const next = (rank != m_passiveRanks.end() ? rank->second : 0) + 1;
    return IsGainTooSmall(passive.effect, passive.valuePerRank * passive.RankWeight(next));
}

bool BonkRun::RefreshKeptOffer(Offer& offer) const
{
    if (offer.isCard)
    {
        BonkCard const* card = sBonkMgr.GetCard(offer.id);
        if (!card || m_banished.count(GetBanishKey(offer)) || (card->maxCopies && GetCardCopies(offer.id) >= card->maxCopies) || IsCardCapped(*card))
            return false;
        offer.newLevel = GetCardCopies(offer.id) + 1;
        return true;
    }

    if (offer.isWeapon)
    {
        if (m_banished.count(GetBanishKey(offer)))
            return false;

        OwnedWeapon const* owned = FindOwned(offer.id);
        if (offer.step == BONK_STEP_NEW)
            return !owned && m_weapons.size() < GetSpellSlots() &&
                std::none_of(m_weapons.begin(), m_weapons.end(), [&](OwnedWeapon const& w) { return w.weapon.evolvesFrom == offer.id; });
        if (!owned)
            return false;
        if (IsMaxAtPickup(owned->weapon) && (offer.step != BONK_STEP_EVOLVE || !IsOpenEvolution(*owned, offer.evolveTo)))
            return false;

        offer.newLevel = owned->rank + 1;
        if (offer.step == BONK_STEP_EVOLVE && !IsOpenEvolution(*owned, offer.evolveTo))
        {
            offer.step = BONK_STEP_RANK;
            offer.rarity = BONK_RARITY_EPIC;
            offer.evolveTo = 0;
            if (m_banished.count(GetBanishKey(offer)))
                return false;
        }
        RollUpgrades(*owned, offer);
        return OfferGainsAnything(*owned, offer);
    }

    BonkPassive const* passive = sBonkMgr.GetPassive(offer.id);
    if (!passive || m_banished.count({ false, offer.id }) || !IsPassiveAllowed(*passive) || IsPassiveCapped(*passive))
        return false;
    auto rank = m_passiveRanks.find(offer.id);
    uint8 const current = rank != m_passiveRanks.end() ? rank->second : 0;
    size_t const ownedPassives = std::count_if(m_passiveRanks.begin(), m_passiveRanks.end(), [](auto const& itr) { return itr.second > 0; });
    if (passive->IsMaxed(current) || (!current && ownedPassives >= GetPassiveSlots()))
        return false;
    offer.newLevel = current + 1;
    return true;
}

bool BonkRun::OfferUpgrades(OfferSource source, std::vector<Offer> const* avoid, std::vector<Offer> const* kept, std::vector<Offer>* drawn)
{
    struct Candidate
    {
        Offer offer;
        uint32 weight;
    };
    std::vector<Candidate> candidates;
    BonkRarity const minimum = source == OFFER_CHEST ? BONK_CHEST_MIN_RARITY : BONK_LEVEL_MIN_RARITY;
    size_t offerSize = BONK_OFFER_SIZE;
    if (source == OFFER_CHEST)
        offerSize = (!m_pendingChestChoices.empty() ? m_pendingChestChoices.front() : BONK_OFFER_SIZE) +
            size_t(GetUtility(BONK_UTILITY_CARD_CHOICES));
    else
        offerSize += size_t(GetUtility(BONK_UTILITY_LEVEL_CHOICES));
    offerSize = std::min(offerSize, BONK_MAX_OFFER_SIZE);
    if (source == OFFER_LEVEL)
        offerSize = std::min(offerSize + GetGlyphLevelChoices(), BONK_MAX_OFFER_SIZE);
    if (source == OFFER_LEVEL)
        if (BonkGlyph const* gambler = GetGlyph(BONK_GLYPH_GAMBLER))
            offerSize = std::max<size_t>(1, std::min(offerSize, size_t(gambler->values[0])));

    if (source == OFFER_CHEST && !sBonkMgr.GetCards().empty())
        return OfferCards(offerSize, avoid, kept, drawn);

    std::vector<Offer> cards;
    std::vector<Offer> carried;
    if (kept)
        carried = *kept;
    else if (source == OFFER_CHEST)
    {
        carried = m_lockedOffers;
        m_lockedOffers.clear();
    }
    for (Offer offer : carried)
        if (cards.size() < offerSize && RefreshKeptOffer(offer))
        {
            offer.locked = true;
            cards.push_back(offer);
        }
    auto isCard = [&cards](bool isWeapon, uint32 id)
    {
        return std::any_of(cards.begin(), cards.end(), [&](Offer const& card) { return card.isWeapon == isWeapon && card.id == id; });
    };

    OwnedWeapon const* ascended = source == OFFER_LEVEL && !drawn ? FindAscensionWeapon() : nullptr;
    for (auto const& owned : m_weapons)
    {
        if (isCard(true, owned.weapon.id))
            continue;
        if (&owned == ascended && cards.size() < offerSize)
        {
            cards.push_back(MakeEvolveOffer(owned, PickEvolution(owned)));
            continue;
        }
        Offer const offer = MakeRankOffer(owned, BONK_RARITY_COMMON);
        if (IsMaxAtPickup(owned.weapon) && offer.step != BONK_STEP_EVOLVE)
            continue;
        if (!OfferGainsAnything(owned, offer))
            continue;
        if (!m_banished.count(GetBanishKey(offer)))
            candidates.push_back({ offer, 3 });
    }

    uint32 const classMask = m_player->GetClassMask();
    uint32 const account = m_player->GetBonkPlayer()->GetProgressAccount();
    if (m_weapons.size() < GetSpellSlots())
        for (auto const& itr : sBonkMgr.GetWeapons())
        {
            BonkWeapon const& weapon = itr.second;
            if (weapon.evolvesFrom || (weapon.classMask && !(weapon.classMask & classMask)))
                continue;
            if (weapon.IsBlink() && weapon.spec && weapon.spec != m_runSpec)
                continue;
            if (m_banished.count({ true, weapon.id }) || isCard(true, weapon.id) || sBonkQuests.IsLocked(account, BONK_REWARD_WEAPON, weapon.id))
                continue;
            if (std::any_of(m_weapons.begin(), m_weapons.end(), [&](OwnedWeapon const& owned)
                {
                    return owned.weapon.id == weapon.id || owned.weapon.evolvesFrom == weapon.id;
                }))
                continue;
            Offer offer;
            offer.id = weapon.id;
            candidates.push_back({ offer, 2 });
        }

    size_t const ownedPassives = std::count_if(m_passiveRanks.begin(), m_passiveRanks.end(), [](auto const& itr) { return itr.second > 0; });
    for (auto const& itr : sBonkMgr.GetPassives())
    {
        auto rank = m_passiveRanks.find(itr.first);
        uint8 const current = rank != m_passiveRanks.end() ? rank->second : 0;
        if (itr.second.IsMaxed(current) || (!current && ownedPassives >= GetPassiveSlots()))
            continue;
        if (m_banished.count({ false, itr.first }) || isCard(false, itr.first) || sBonkQuests.IsLocked(account, BONK_REWARD_PASSIVE, itr.first))
            continue;
        if (!IsPassiveAllowed(itr.second) || IsPassiveCapped(itr.second))
            continue;
        Offer offer;
        offer.isWeapon = false;
        offer.id = itr.first;
        offer.newLevel = current + 1;
        candidates.push_back({ offer, itr.second.rare ? 1u : 2u });
    }

    std::vector<Candidate> repeats;
    if (avoid)
    {
        auto shown = [avoid](Candidate const& candidate)
        {
            return std::any_of(avoid->begin(), avoid->end(), [&](Offer const& offer)
            {
                return offer.isWeapon == candidate.offer.isWeapon && offer.id == candidate.offer.id;
            });
        };
        for (auto itr = candidates.begin(); itr != candidates.end();)
        {
            if (shown(*itr))
            {
                repeats.push_back(*itr);
                itr = candidates.erase(itr);
            }
            else
                ++itr;
        }
    }

    for (std::vector<Candidate>* pool : { &candidates, &repeats })
    {
        while (cards.size() < offerSize && !pool->empty())
        {
            uint32 totalWeight = 0;
            for (auto const& candidate : *pool)
                totalWeight += candidate.weight;

            uint32 roll = urand(1, totalWeight);
            for (auto itr = pool->begin(); itr != pool->end(); ++itr)
            {
                if (roll > itr->weight)
                {
                    roll -= itr->weight;
                    continue;
                }
                cards.push_back(itr->offer);
                pool->erase(itr);
                break;
            }
        }
    }

    if (source == OFFER_LEVEL && std::none_of(cards.begin(), cards.end(), [](Offer const& card) { return !card.isWeapon; }))
    {
        std::vector<Offer> passives;
        std::vector<Offer> rarePassives;
        for (std::vector<Candidate> const* pool : { &candidates, &repeats })
            for (Candidate const& candidate : *pool)
                if (!candidate.offer.isWeapon)
                {
                    BonkPassive const* info = sBonkMgr.GetPassive(candidate.offer.id);
                    (info && info->rare ? rarePassives : passives).push_back(candidate.offer);
                }
        if (passives.empty())
            passives = rarePassives;
        if (!passives.empty())
        {
            Offer const& passive = passives[urand(0, uint32(passives.size() - 1))];
            auto replaced = std::find_if(cards.rbegin(), cards.rend(), [](Offer const& card)
            {
                return !card.locked && card.step != BONK_STEP_EVOLVE;
            });
            if (cards.size() < offerSize)
                cards.push_back(passive);
            else if (replaced != cards.rend())
                *replaced = passive;
        }
    }

    bool met = false;
    std::vector<size_t> raisable;
    for (size_t i = 0; i < cards.size(); ++i)
    {
        if (!cards[i].isWeapon || cards[i].step == BONK_STEP_NEW)
            continue;
        if (cards[i].rarity >= minimum)
            met = true;
        else if (!cards[i].locked)
            raisable.push_back(i);
    }
    if (!met && !raisable.empty())
    {
        Offer& card = cards[raisable[urand(0, uint32(raisable.size() - 1))]];
        if (OwnedWeapon const* owned = FindOwned(card.id))
        {
            card.rarity = RollRarity(minimum);
            card.step = BONK_STEP_RANK;
            RollUpgrades(*owned, card);
        }
    }

    if (source == OFFER_LEVEL && GetGlyph(BONK_GLYPH_GAMBLER))
        for (Offer& card : cards)
            if (card.isWeapon && card.step == BONK_STEP_RANK && !card.locked && card.rarity < BONK_RARITY_EPIC)
                if (OwnedWeapon const* owned = FindOwned(card.id))
                {
                    card.rarity = BonkRarity(card.rarity + 1);
                    RollUpgrades(*owned, card);
                }

    cards.erase(std::remove_if(cards.begin(), cards.end(), [this](Offer const& card) { return DescribeStep(card).empty() || IsEmptyRankUp(card); }), cards.end());

    if (drawn)
    {
        *drawn = cards;
        return !cards.empty();
    }

    ShowAllEvolutions(cards);
    bool const ascensionShown = ascended && std::any_of(cards.begin(), cards.end(), [ascended](Offer const& card)
    {
        return card.isWeapon && card.step == BONK_STEP_EVOLVE && card.id == ascended->weapon.id;
    });
    if (ascensionShown)
        UseAscension(*ascended);

    m_offer = cards;
    if (m_offer.empty())
    {
        if (source != OFFER_CHEST)
            --m_pendingLevels;
        else if (!m_pendingChestChoices.empty())
            m_pendingChestChoices.erase(m_pendingChestChoices.begin());
        uint32 const gold = m_map.goldPerKill * 25;
        uint32 const paid = uint32(gold * GetGoldMultiplier());
        GiveGold(gold);
        m_player->GetBonkPlayer()->Notify(paid ? BONK_STRING_NOTHING_LEFT_TO_LEARN_GOLD : BONK_STRING_NOTHING_LEFT_TO_LEARN, { FormatBonkMoney(paid, GetLocale()) });
        return false;
    }

    m_offerSource = source;
    SetPaused(true);
    SendOffer();
    return true;
}

std::string BonkRun::DescribeOffer(Offer const& offer, std::string* icon) const
{
    if (offer.isCard)
    {
        BonkCard const* card = sBonkMgr.GetCard(offer.id);
        if (icon)
            *icon = card ? card->icon : "";
        return card ? Localize(BONK_FIELD_CARD_NAME, card->id, card->name) : "?";
    }

    if (offer.isWeapon)
    {
        BonkWeapon const* weapon = sBonkMgr.GetWeapon(offer.step == BONK_STEP_EVOLVE ? offer.evolveTo : offer.id);
        if (!weapon)
            return "?";
        if (icon)
            *icon = weapon->icon;
        return Localize(BONK_FIELD_WEAPON_NAME, weapon->id, weapon->name);
    }

    BonkPassive const* passive = sBonkMgr.GetPassive(offer.id);
    if (!passive)
        return "?";
    if (icon)
        *icon = passive->icon;
    return Localize(BONK_FIELD_PASSIVE_NAME, passive->id, passive->name);
}

std::string BonkRun::DescribeStep(Offer const& offer) const
{
    if (offer.isCard)
    {
        BonkCard const* card = sBonkMgr.GetCard(offer.id);
        if (!card)
            return "";
        uint32 const owned = GetCardCopies(card->id);
        std::string const total = owned ? BonkCodex::DescribeCardTotal(*card, owned + 1, GetLocale()) : std::string();
        std::string const description = Localize(BONK_FIELD_CARD_DESCRIPTION, card->id, card->description);
        return total.empty() ? description : description + BONK_LINE_BREAK + GetString(BONK_STRING_WITH_THIS_COPY, { total });
    }

    if (!offer.isWeapon)
    {
        BonkPassive const* passive = sBonkMgr.GetPassive(offer.id);
        return passive ? sBonkMgr.DescribePassiveRankUp(*passive, offer.newLevel, GetLocale()) : "";
    }

    BonkWeapon const* weapon = sBonkMgr.GetWeapon(offer.id);
    if (!weapon)
        return "";

    if (offer.step == BONK_STEP_NEW)
    {
        std::string description = Localize(BONK_FIELD_WEAPON_DESCRIPTION, weapon->id, weapon->description);
        if (weapon->IsBlink() && IsBlinkDash())
            description = BonkLocale::AfterFirstSentence(description);
        if (IsMaxAtPickup(*weapon))
            description += " " + GetString(BONK_STRING_STARTS_AT_MAX_RANK, { std::to_string(GetWindowEvolveRanks()) });
        return description;
    }
    if (offer.step == BONK_STEP_EVOLVE)
    {
        BonkWeapon const* evolved = sBonkMgr.GetWeapon(offer.evolveTo);
        return evolved ? GetString(BONK_STRING_EVOLVES_INTO_OFFER, { Localize(BONK_FIELD_WEAPON_NAME, weapon->id, weapon->name),
            Localize(BONK_FIELD_WEAPON_NAME, evolved->id, evolved->name), sBonkMgr.DescribeEvolutionAdds(*evolved, GetLocale()) }) : "";
    }
    if (offer.rarity >= BONK_RARITY_LEGENDARY)
        return "";

    std::string text = DescribeRankUp(offer, *weapon);
    if (text.empty())
        text = DescribeBareRankUp(offer);
    if (weapon->behavior == BONK_BEHAVIOR_SPREAD && !weapon->evolvesFrom && offer.newLevel == BONK_SPREAD_RANK)
        text += " " + GetString(BONK_STRING_RANK_NOW_SPREADS);
    return text;
}

std::string BonkRun::DescribeBareRankUp(Offer const& offer) const
{
    OwnedWeapon const* owned = FindOwned(offer.id);
    if (owned && offer.newLevel < GetEvolveRank() && CanEvolve(*owned))
        return GetString(BONK_STRING_CAN_EVOLVE_FROM_RANK, { std::to_string(GetEvolveRank()) });
    if (offer.newLevel >= BONK_DAMAGELESS_MAX_RANK)
        return GetString(BONK_STRING_REACHES_MAX_RANK);
    return GetString(BONK_STRING_MAX_RANK_AT, { std::to_string(BONK_DAMAGELESS_MAX_RANK) });
}

std::string BonkRun::DescribeRankUp(Offer const& offer, BonkWeapon const& weapon) const
{
    OwnedWeapon const* owned = FindOwned(offer.id);
    BonkWeapon const& current = owned ? owned->weapon : weapon;
    bool const damageCounts = !owned || RankDamageCounts(*owned);
    float const rankScale = GetRankDamageScale(offer.newLevel);
    float damage = GetRankDamage(owned, offer.rarity) * rankScale;
    float amounts[MAX_BONK_SPELL_UPGRADE] = {};
    std::vector<BonkSpellUpgrade> order;
    uint8 const count = GetRankUpgradeCount(owned, offer.rarity);
    for (uint8 i = 0; i < count; ++i)
    {
        BonkSpellUpgrade const upgrade = offer.upgrades[i];
        float const step = current.GetUpgradeStep(upgrade);
        if (step <= 0.0f)
        {
            if (damageCounts)
                damage += BONK_RANK_SPARE_DAMAGE * rankScale;
            continue;
        }
        if (!amounts[upgrade])
            order.push_back(upgrade);
        amounts[upgrade] += step;
    }

    float now[MAX_BONK_SPELL_UPGRADE] = {};
    GetSpellUpgrades(owned, now);
    float after[MAX_BONK_SPELL_UPGRADE] = {};
    for (uint8 upgrade = 0; upgrade < MAX_BONK_SPELL_UPGRADE; ++upgrade)
        after[upgrade] = now[upgrade] + amounts[upgrade];
    float const damageNow = owned ? owned->damageBonus : 0.0f;
    WeaponStrength before, strength;
    bool const strengthens = GetWeaponStrength(current, damageNow, now, before) &&
        GetWeaponStrength(current, damageNow + damage, after, strength);

    BonkKeywordInfo const* keyword = sBonkMgr.GetKeyword(current.applies);
    bool const ticks = keyword && keyword->IsDamageOverTime();
    auto describeDamage = [&](float bonus) -> std::string
    {
        std::string const amount = "+" + Percent(std::round(bonus * 10.0f) / 10.0f);
        if (current.damageFraction <= 0.0f && current.healPct > 0.0f)
            return GetString(BONK_STRING_RANK_HEALING, { amount });
        if (current.damageFraction > 0.0f || (!ticks && !strengthens))
            return GetString(BONK_STRING_RANK_DAMAGE, { amount });
        if (ticks && keyword)
            return GetString(BONK_STRING_RANK_KEYWORD_DAMAGE, { amount, Localize(BONK_FIELD_KEYWORD_NAME, uint32(keyword->id), keyword->name) });
        return "";
    };
    auto join = [this](std::vector<std::string> const& parts)
    {
        std::string text;
        for (std::string const& part : parts)
            if (!part.empty())
                text = text.empty() ? part : GetString(BONK_STRING_LIST_ITEM, { text, part });
        return text;
    };

    std::vector<std::string> adds;
    if (damage > 0.0f)
        adds.push_back(describeDamage(damage));
    for (BonkSpellUpgrade upgrade : order)
        if (!strengthens || upgrade != strength.folded)
            adds.push_back(DescribeBonkSpellUpgrade(current, upgrade, amounts[upgrade], GetLocale()));
    if (strengthens)
    {
        float const gain = strength.folded == BONK_SPELL_UPGRADE_SHIELD_SIZE ?
            (before.value > 0.0f ? (strength.value / before.value - 1.0f) * 100.0f : 0.0f) : strength.value - before.value;
        if (gain >= 0.05f)
            adds.push_back(DescribeBonkSpellUpgrade(current, strength.folded, std::round(gain * 10.0f) / 10.0f, GetLocale()));
    }

    std::stable_partition(adds.begin(), adds.end(), [](std::string const& part)
    {
        return !part.empty() && (part[0] == '+' || part[0] == '-');
    });
    std::string text = join(adds);
    if (text.empty())
        return text;
    text[0] = char(toupper(static_cast<unsigned char>(text[0])));
    return GetString(BONK_STRING_SENTENCE, { text });
}

void BonkRun::GetSpellUpgrades(OwnedWeapon const* owned, float* upgrades) const
{
    for (uint8 upgrade = 0; upgrade < MAX_BONK_SPELL_UPGRADE; ++upgrade)
        upgrades[upgrade] = owned && upgrade != BONK_SPELL_UPGRADE_NONE ? GetSpellUpgrade(*owned, BonkSpellUpgrade(upgrade)) : 0.0f;
}

bool BonkRun::GetWeaponStrength(BonkWeapon const& weapon, float damageBonus, float const* upgrades, WeaponStrength& strength) const
{
    if (GetPaladinStrength(weapon, damageBonus, strength))
        return true;
    BonkWeapon const* row = sBonkMgr.GetWeapon(weapon.id);
    if (row && row->applies == BONK_KEYWORD_HUNTERS_MARK)
    {
        strength.sentence = BONK_STRING_STRENGTH_MARKED;
        strength.label = BONK_STRING_STRENGTH_MARKED_LABEL;
        strength.value = GetMarkStrength(damageBonus, upgrades[BONK_SPELL_UPGRADE_MARK]);
        strength.folded = BONK_SPELL_UPGRADE_MARK;
        return true;
    }
    if (weapon.IsShieldBlock() || weapon.behavior == BONK_BEHAVIOR_WARD || weapon.behavior == BONK_BEHAVIOR_POWER_WORD_SHIELD)
    {
        strength.sentence = BONK_STRING_STRENGTH_SHIELD;
        strength.label = BONK_STRING_STRENGTH_SHIELD_LABEL;
        strength.value = GetShieldPercent(weapon, damageBonus, upgrades[BONK_SPELL_UPGRADE_SHIELD_SIZE]);
        strength.folded = BONK_SPELL_UPGRADE_SHIELD_SIZE;
        return true;
    }
    if (weapon.damageFraction <= 0.0f && weapon.healPct > 0.0f)
    {
        strength.sentence = BONK_STRING_STRENGTH_HEAL;
        strength.label = BONK_STRING_STRENGTH_HEAL_LABEL;
        strength.value = GetHealPercent(weapon, damageBonus);
        return true;
    }
    if (weapon.HasFlag(BONK_WEAPON_FLAG_NORMAL_ONLY) && weapon.IsKeywordOnly())
    {
        strength.sentence = BONK_STRING_STRENGTH_SLOWED;
        strength.label = BONK_STRING_STRENGTH_SLOWED_LABEL;
        strength.value = GetSlowedStrength(damageBonus, upgrades[BONK_SPELL_UPGRADE_SLOWED]);
        strength.folded = BONK_SPELL_UPGRADE_SLOWED;
        return true;
    }
    return false;
}

bool BonkRun::Pick(uint32 choice, std::string& error)
{
    if ((m_state != STATE_RUNNING && m_state != STATE_PORTAL) || m_offer.empty())
    {
        error = GetString(BONK_STRING_THERE_IS_NOTHING_TO_CHOOSE);
        SendOfferClosed();
        return false;
    }

    if (choice < 1 || choice > m_offer.size())
    {
        error = GetString(BONK_STRING_CHOOSE_NUMBER_FROM_1_TO, { std::to_string(m_offer.size()) });
        SendOffer();
        return false;
    }

    Offer const offer = m_offer[choice - 1];

    {
        std::string const rarity = (offer.isWeapon && offer.step != BONK_STEP_NEW) || offer.isCard ? GetBonkRarityName(offer.rarity) : "new";
        sLog.Player(m_player->GetSession(), LOG_LEVELUP, LOG_LVL_BASIC,
            "Bonk pick: %s takes %s rank %u (%s, %s) at run minute %.2f, level %u: %s",
            m_player->GetName(), DescribeOffer(offer, nullptr).c_str(), offer.newLevel, rarity.c_str(),
            m_offerSource == OFFER_CHEST ? "chest" : "level", GetRunMinutes(), m_player->GetLevel(), JoinBonkLines(DescribeStep(offer)).c_str());
    }

    if (offer.isCard)
    {
        if (BonkCard const* card = sBonkMgr.GetCard(offer.id))
            AddCard(*card);
    }
    else if (offer.isWeapon)
    {
        if (OwnedWeapon* owned = FindOwned(offer.id))
        {
            ApplyStep(*owned, offer);
            EchoRankPick(*owned, offer);
        }
        else if (BonkWeapon const* weapon = sBonkMgr.GetWeapon(offer.id))
            AddWeapon(*weapon);
    }
    else
    {
        m_passiveRanks[offer.id] = uint8(offer.newLevel);
        ApplyPassives();
    }

    CloseOffer(choice - 1);
    return true;
}

void BonkRun::CloseOffer(uint32 pickedIndex)
{
    if (m_offerSource == OFFER_CHEST)
    {
        m_lockedOffers.clear();
        for (size_t i = 0; i < m_offer.size(); ++i)
            if (m_offer[i].locked && i != pickedIndex)
                m_lockedOffers.push_back(m_offer[i]);
    }

    m_offer.clear();
    if (m_offerSource == OFFER_CHEST)
    {
        if (!m_pendingChestChoices.empty())
            m_pendingChestChoices.erase(m_pendingChestChoices.begin());
    }
    else if (m_pendingLevels)
        --m_pendingLevels;

    BonkPlayer* bonk = m_player->GetBonkPlayer();
    SendOfferClosed();
    SendLoadout();

    ResumeUnlessChoiceOpen();
    UpdateOffers();
}

bool BonkRun::Reroll(std::string& error)
{
    if ((m_state != STATE_RUNNING && m_state != STATE_PORTAL) || m_offer.empty())
    {
        error = GetString(BONK_STRING_THERE_IS_NOTHING_TO_REROLL);
        SendOfferClosed();
        return false;
    }

    if (!m_rerolls)
    {
        error = GetString(BONK_STRING_NO_REROLLS_LEFT);
        SendOffer();
        return false;
    }

    --m_rerolls;
    std::vector<Offer> const previous = m_offer;
    std::vector<Offer> kept;
    for (Offer const& offer : previous)
        if (offer.locked)
            kept.push_back(offer);
    if (!OfferUpgrades(m_offerSource, &previous, &kept))
    {
        SetPaused(false);
        SendOfferClosed();
    }
    return true;
}

bool BonkRun::Banish(uint32 choice, std::string& error)
{
    if ((m_state != STATE_RUNNING && m_state != STATE_PORTAL) || m_offer.empty())
    {
        error = GetString(BONK_STRING_THERE_IS_NOTHING_TO_BANISH);
        SendOfferClosed();
        return false;
    }

    if (!m_banishes || choice < 1 || choice > m_offer.size())
    {
        error = m_banishes ? GetString(BONK_STRING_CHOOSE_NUMBER_FROM_1_TO, { std::to_string(m_offer.size()) }) : GetString(BONK_STRING_NO_BANISHES_LEFT);
        SendOffer();
        return false;
    }

    Offer const offer = m_offer[choice - 1];
    if (!CanBanish(offer))
    {
        error = GetString(BONK_STRING_CANT_BANISH_OWNED);
        SendOffer();
        return false;
    }
    m_banished.insert(GetBanishKey(offer));
    m_player->GetBonkPlayer()->Notify(BONK_STRING_YOU_BANISHED_FOR_REST_OF, { DescribeOffer(offer, nullptr) });
    --m_banishes;

    ReplaceBanishedOffer(choice - 1);
    if (!m_offer.empty())
    {
        SendOffer();
        return true;
    }
    std::vector<Offer> const none;
    if (!OfferUpgrades(m_offerSource, nullptr, &none))
    {
        SetPaused(false);
        SendOfferClosed();
    }
    return true;
}

void BonkRun::ReplaceBanishedOffer(size_t slot)
{
    std::vector<Offer> const none;
    std::vector<Offer> drawn;
    OfferUpgrades(m_offerSource, &m_offer, &none, &drawn);
    auto onBoard = [this](Offer const& card)
    {
        return std::any_of(m_offer.begin(), m_offer.end(), [&card](Offer const& shown)
        {
            return shown.isCard == card.isCard && shown.isWeapon == card.isWeapon && shown.id == card.id;
        });
    };
    auto replacement = std::find_if(drawn.begin(), drawn.end(), [&](Offer const& card)
    {
        return !onBoard(card) && !m_banished.count(GetBanishKey(card));
    });
    if (replacement != drawn.end())
        m_offer[slot] = *replacement;
    else
        m_offer.erase(m_offer.begin() + slot);
}

bool BonkRun::Skip(std::string& error)
{
    if ((m_state != STATE_RUNNING && m_state != STATE_PORTAL) || m_offer.empty())
    {
        error = GetString(BONK_STRING_THERE_IS_NOTHING_TO_SKIP);
        SendOfferClosed();
        return false;
    }

    if (!m_skips)
    {
        error = GetString(BONK_STRING_NO_SKIPS_LEFT);
        SendOffer();
        return false;
    }

    --m_skips;
    uint32 const coins = std::max(1u, uint32(GetChestPrice() * BONK_SKIP_COINS));
    GainValor(coins);
    m_player->GetBonkPlayer()->Notify(BONK_STRING_YOU_SKIPPED_THIS_CHOICE_AND, { std::to_string(coins) });
    CloseOffer(uint32(m_offer.size()));
    SendState();
    return true;
}

bool BonkRun::Lock(uint32 choice, std::string& error)
{
    if ((m_state != STATE_RUNNING && m_state != STATE_PORTAL) || m_offer.empty())
    {
        error = GetString(BONK_STRING_THERE_IS_NOTHING_TO_LOCK);
        return false;
    }

    if (m_offerSource != OFFER_CHEST)
    {
        error = GetString(BONK_STRING_ONLY_CHEST_CHOICES_CAN_BE);
        return false;
    }

    if (choice < 1 || choice > m_offer.size())
    {
        error = GetString(BONK_STRING_CHOOSE_NUMBER_FROM_1_TO, { std::to_string(m_offer.size()) });
        return false;
    }

    m_offer[choice - 1].locked = !m_offer[choice - 1].locked;
    SendOffer();
    return true;
}

void BonkRun::SendState() const
{
    std::string damageTypes;
    for (auto const& owned : m_weapons)
        damageTypes += (IsShapeshift(owned) ? DescribeShapeshiftDamage() : BonkStats::DescribeDamageTypes(m_player->GetObjectGuid(), owned.weapon.spellId)) + ",";
    uint32 const shownSeconds = (m_sandbox ? m_totalMs : m_elapsedMs) / IN_MILLISECONDS;
    BonkPlayer* bonk = m_player->GetBonkPlayer();
    if (bonk->IsAddonReady())
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteRunState(data, shownSeconds, m_sandbox ? 0 : m_map.durationSeconds, m_kills, m_goldEarned,
            uint8(m_player->GetLevel()), m_bossSpawned, m_coins, GetChestPrice(), m_stage, m_state == STATE_PORTAL,
            m_shardsEarned, DescribeWeaponStats(), m_totalMs / IN_MILLISECONDS, damageTypes);
        m_player->GetSession()->SendPacket(&data);
    }
    if (bonk->IsAddonReady())
    {
        WorldPacket support(SMSG_HOA_MESSAGE);
        HoAWriteRunSupport(support, DescribeSupport());
        m_player->GetSession()->SendPacket(&support);

        WorldPacket glyphMeter(SMSG_HOA_MESSAGE);
        HoAWriteRunGlyphMeter(glyphMeter, DescribeGlyphStats());
        m_player->GetSession()->SendPacket(&glyphMeter);

        WorldPacket otherMeter(SMSG_HOA_MESSAGE);
        HoAWriteRunOtherMeter(otherMeter, DescribeOtherDamage());
        m_player->GetSession()->SendPacket(&otherMeter);

        if (BonkCoop::InGroupRun(m_player))
        {
            std::vector<Player*> members = BonkCoop::RunGroupOf(m_player);
            if (std::find(members.begin(), members.end(), m_player) == members.end())
                members.push_back(m_player);
            std::string party;
            for (Player* member : members)
            {
                if (!member)
                    continue;
                party += std::string(member->GetName()) + "~" +
                    std::to_string(BonkStats::TotalDamage(member->GetObjectGuid())) + "~" + std::to_string(uint32(member->GetClass())) + "~";
            }
            WorldPacket partyMeter(SMSG_HOA_MESSAGE);
            HoAWriteRunPartyMeter(partyMeter, party);
            m_player->GetSession()->SendPacket(&partyMeter);
        }
    }
}

std::string BonkRun::DescribeWeaponStats() const
{
    std::string text;
    for (auto const& owned : m_weapons)
    {
        std::pair<uint64, uint32> const totals = GetOwnedSpellTotals(owned);
        text += std::to_string(totals.first) + ":" + std::to_string(totals.second) + ",";
    }
    return text;
}

std::pair<uint64, uint32> BonkRun::GetOwnedSpellTotals(OwnedWeapon const& owned) const
{
    std::pair<uint64, uint32> totals{ 0, 0 };
    for (uint32 spellId : BonkStats::GetWeaponSpells(owned.weapon))
    {
        BonkRunStats::Spell const part = BonkStats::GetSpellStats(m_player->GetObjectGuid(), spellId);
        totals.first += part.damage;
        totals.second += part.kills;
    }
    return totals;
}

std::string BonkRun::DescribeOtherDamage() const
{
    std::set<uint32> shown;
    for (OwnedWeapon const& owned : m_weapons)
        for (uint32 spellId : BonkStats::GetWeaponSpells(owned.weapon))
            shown.insert(spellId);
    AddGlyphMeterSpells(shown);
    std::string text;
    for (BonkOtherSource const& other : BonkStats::GetOtherSources(m_player, shown))
        text += other.icon + "~" + other.name + "~" + std::to_string(other.damage) + "~" + std::to_string(other.kills) + "~" + other.type + "~";
    return text;
}

std::string BonkRun::DescribeBuildTotals() const
{
    std::string spells;
    for (OwnedWeapon const& owned : m_weapons)
    {
        std::pair<uint64, uint32> const totals = GetOwnedSpellTotals(owned);
        spells += (spells.empty() ? "" : ",") + std::to_string(owned.weapon.id) + ":" + std::to_string(owned.rank) + ":" +
            std::to_string(totals.first) + ":" + std::to_string(totals.second);
    }
    std::string passives;
    for (auto const& itr : m_passiveRanks)
        passives += (passives.empty() ? "" : ",") + std::to_string(itr.first) + ":" + std::to_string(itr.second);
    std::string cards;
    for (OwnedCard const& owned : m_cards)
        if (owned.card)
            cards += (cards.empty() ? "" : ",") + std::to_string(owned.card->id) + ":" + std::to_string(owned.copies);
    std::string glyphs;
    for (BonkGlyph const* glyph : m_glyphs)
        glyphs += (glyphs.empty() ? "" : ",") + DescribeGlyphTotals(*glyph);
    std::string stats;
    for (uint8 effect = 0; effect < MAX_BONK_PASSIVE_EFFECT; ++effect)
    {
        float value = GetPassiveTotal(BonkPassiveEffect(effect));
        if (effect == BONK_PASSIVE_CRIT)
            value += BONK_BASE_CRIT;
        if (std::fabs(value) < 0.05f)
            continue;
        char entry[32];
        snprintf(entry, sizeof(entry), "%u:%.1f", uint32(effect), value);
        stats += (stats.empty() ? "" : ",") + std::string(entry);
    }
    return "spells [" + spells + "]; passives [" + passives + "]; cards [" + cards + "]; glyphs [" + glyphs + "]; gear [" +
        m_player->GetBonkPlayer()->DescribeGear() + "]; stats [" + stats + "]; found [" + m_player->GetBonkPlayer()->DescribeFoundGear() +
        "]; enchants [" + DescribeEnchants() + "]";
}

void BonkRun::SendLoadout() const
{
    std::string entries;
    for (auto const& owned : m_weapons)
        entries += std::string(owned.weapon.evolvesFrom ? "e:" : "w:") + owned.weapon.icon + ":" + std::to_string(owned.rank) + ":" +
            std::to_string(IsRankMaxed(owned) ? owned.rank : 0) + ",";
    for (auto const& itr : m_passiveRanks)
        if (BonkPassive const* passive = sBonkMgr.GetPassive(itr.first))
            entries += "p:" + passive->icon + ":" + std::to_string(itr.second) + ":" + std::to_string(passive->maxRank) + ",";
    BonkPlayer* bonk = m_player->GetBonkPlayer();
    if (bonk->IsAddonReady())
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteLoadout(data, entries, GetSpellSlots(), GetPassiveSlots());
        m_player->GetSession()->SendPacket(&data);
    }

    uint32 index = 0;
    for (auto const& owned : m_weapons)
    {
        ++index;
        BonkWeapon const& weapon = owned.weapon;
        SendWeaponInfo(index, owned);

        std::string evolution, evolutionText, evolvedFrom, chanceText;
        uint32 chance = 0;
        std::vector<BonkWeapon const*> const evolutions = sBonkMgr.GetEvolutions(weapon.id);
        if (weapon.evolvesFrom)
        {
            if (BonkWeapon const* base = sBonkMgr.GetWeapon(weapon.evolvesFrom))
                evolvedFrom = Localize(BONK_FIELD_WEAPON_NAME, base->id, base->name);
        }
        else if (!evolutions.empty())
        {
            evolution = sBonkMgr.DescribeEvolutionNames(weapon.id, GetLocale());
            if (evolutions.size() == 1)
                evolutionText = sBonkMgr.DescribeEvolutionAdds(*evolutions.front(), GetLocale());
            chanceText = DescribeEvolutionChance(owned, chance);
        }
        if (bonk->IsAddonReady())
        {
            WorldPacket data(SMSG_HOA_MESSAGE);
            HoAWriteWeaponEvolution(data, index, evolution, evolutionText, evolvedFrom, chanceText, chance);
            m_player->GetSession()->SendPacket(&data);
        }
        if (!weapon.evolvesFrom && evolutions.size() > 1)
            for (BonkWeapon const* evolved : evolutions)
            {
                if (!bonk->IsAddonReady())
                    continue;
                WorldPacket data(SMSG_HOA_MESSAGE);
                HoAWriteWeaponEvolutionOption(data, index, Localize(BONK_FIELD_WEAPON_NAME, evolved->id, evolved->name),
                    sBonkMgr.DescribeEvolutionAdds(*evolved, GetLocale()));
                m_player->GetSession()->SendPacket(&data);
            }
    }
    for (auto const& itr : m_passiveRanks)
    {
        BonkPassive const* passive = sBonkMgr.GetPassive(itr.first);
        if (!passive)
            continue;
        ++index;
        if (bonk->IsAddonReady())
        {
            WorldPacket data(SMSG_HOA_MESSAGE);
            HoAWriteWeaponInfo(data, index, Localize(BONK_FIELD_PASSIVE_NAME, passive->id, passive->name), "", 0, 0, "",
                sBonkMgr.DescribePassiveNow(*passive, itr.second, GetLocale()), "", "", false, "", "");
            m_player->GetSession()->SendPacket(&data);
        }
    }
}

void BonkRun::NoteWeaponFired(OwnedWeapon& owned)
{
    ++m_secondCasts;
    if (owned.weapon.IsTrigger() || owned.weapon.IsBlink())
        return;
    bool const waiting = owned.timer <= BONK_WEAPON_RETRY_MS;
    if (waiting && !owned.held)
        owned.pieResync = true;
    else if (!waiting)
    {
        float const interval = float(GetWeaponCooldown(owned));
        bool const drifted = std::fabs(interval - float(owned.shownIntervalMs)) > interval * BONK_PIE_DRIFT;
        bool const shortened = float(owned.timer) < interval * (1.0f - BONK_PIE_DRIFT);
        if (owned.held || drifted || shortened)
            owned.pieResync = true;
    }
    owned.held = waiting;
}

void BonkRun::SendCooldownPie(uint32 index, OwnedWeapon const& owned) const
{
    uint32 const interval = GetWeaponCooldown(owned);
    owned.shownIntervalMs = interval;
    uint32 const pieMs = owned.weapon.IsBlink() || owned.weapon.IsSeal() || owned.weapon.behavior == BONK_BEHAVIOR_PET ? 0u : interval;
    if (!m_player->GetBonkPlayer()->IsAddonReady())
        return;
    WorldPacket data(SMSG_HOA_MESSAGE);
    HoAWriteCooldownPie(data, index, pieMs, std::max<int32>(0, owned.timer), owned.held);
    m_player->GetSession()->SendPacket(&data);
}

void BonkRun::RefreshChangedWeaponInfo() const
{
    uint32 index = 0;
    for (OwnedWeapon const& owned : m_weapons)
        SendWeaponInfo(++index, owned, true);
}

bool BonkRun::IsUpgradeShownInNumbers(BonkSpellUpgrade upgrade)
{
    switch (upgrade)
    {
        case BONK_SPELL_UPGRADE_HASTE:
        case BONK_SPELL_UPGRADE_DURATION:
        case BONK_SPELL_UPGRADE_PET_DAMAGE:
        case BONK_SPELL_UPGRADE_STACKS:
        case BONK_SPELL_UPGRADE_REACH:
        case BONK_SPELL_UPGRADE_TARGETS:
        case BONK_SPELL_UPGRADE_ECHO:
            return true;
        default:
            return false;
    }
}

void BonkRun::SendWeaponInfo(uint32 index, OwnedWeapon const& owned, bool onlyIfChanged) const
{
    BonkWeapon const& weapon = owned.weapon;
    uint32 const interval = weapon.IsBlink() ? m_player->GetBonkPlayer()->GetDashCooldownMs() : GetWeaponCooldown(owned);
    owned.shownIntervalMs = interval;
    float upgrades[MAX_BONK_SPELL_UPGRADE] = {};
    GetSpellUpgrades(&owned, upgrades);
    WeaponStrength strength;
    bool const strengthens = GetWeaponStrength(weapon, owned.damageBonus, upgrades, strength);
    std::string picks;
    auto addPick = [&picks](std::string text)
    {
        text[0] = char(toupper(static_cast<unsigned char>(text[0])));
        picks += (picks.empty() ? "" : " \xC2\xB7 ") + text;
    };
    if (strengthens)
        addPick(GetString(strength.sentence, { Percent(std::round(strength.value * 10.0f) / 10.0f) }));
    for (uint8 upgrade = BONK_SPELL_UPGRADE_NONE + 1; upgrade < MAX_BONK_SPELL_UPGRADE; ++upgrade)
        if (float const amount = GetSpellUpgrade(owned, BonkSpellUpgrade(upgrade)))
        {
            if ((strengthens && upgrade == strength.folded) || IsUpgradeShownInNumbers(BonkSpellUpgrade(upgrade)))
                continue;
            std::string const added = DescribeBonkSpellUpgrade(weapon, BonkSpellUpgrade(upgrade), amount, GetLocale());
            if (!added.empty())
                addPick(added);
        }
    std::string description = Localize(BONK_FIELD_WEAPON_DESCRIPTION, weapon.id, weapon.description);
    if (weapon.behavior == BONK_BEHAVIOR_PET && !weapon.HasFlag(BONK_WEAPON_FLAG_HYDRA) && !weapon.HasFlag(BONK_WEAPON_FLAG_ELEMENTAL_SHIFT))
        if (BonkPetFamily const* family = GetPetFamily(owned))
            if (!family->description.empty())
                description += " " + Localize(BONK_FIELD_PET_FAMILY_DESCRIPTION, family->id, family->description);
    description = DescribeLiveSpell(owned, description);
    if (weapon.behavior == BONK_BEHAVIOR_ROLLING_THUNDER)
        description += " " + DescribeThunderCount(owned);
    bool faster = false;
    std::string const header = DescribeSpellHeader(owned, interval, faster);
    std::string const radius = std::to_string(std::round(GetWeaponRadius(owned) * 10.0f) / 10.0f) + "~" +
        std::to_string(std::round(weapon.range * (weapon.IsMeleeStrike() ? GetWeaponArea(owned) : 1.0f) * 10.0f) / 10.0f);
    std::string const shown = description + "~" + header + "~" + picks + "~" + DescribeShownDamage(owned) + "~" + radius;
    if (onlyIfChanged && shown == owned.shownTip)
        return;
    owned.shownTip = shown;
    owned.shownDamage = DescribeShownDamage(owned);
    if (m_player->GetBonkPlayer()->IsAddonReady())
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteWeaponInfo(data, index, Localize(BONK_FIELD_WEAPON_NAME, weapon.id, weapon.name), owned.rarities,
            weapon.IsTrigger() || weapon.IsBlink() || weapon.IsSeal() || weapon.behavior == BONK_BEHAVIOR_PET ? 0u : interval,
            std::max<int32>(0, owned.timer), picks, description, owned.shownDamage, header, faster,
            DescribeBonkWeaponTags(weapon, GetShownSchool(owned), GetLocale()), radius);
        m_player->GetSession()->SendPacket(&data);
    }
}

void BonkRun::SendOffer() const
{
    BonkPlayer* bonk = m_player->GetBonkPlayer();
    if (bonk->IsAddonReady())
    {
        WorldPacket open(SMSG_HOA_MESSAGE);
        HoAWriteOfferOpen(open, m_player->GetLevel() + m_overcapLevel, m_offer.size(), m_offerSource == OFFER_CHEST ? "chest" : "level",
            m_rerolls, m_banishes, m_skips);
        m_player->GetSession()->SendPacket(&open);
        for (size_t i = 0; i < m_offer.size(); ++i)
        {
            Offer const& offer = m_offer[i];
            std::string icon;
            std::string const name = DescribeOffer(offer, &icon);
            uint32 maxRank = 0;
            if (offer.isCard)
            {
                if (BonkCard const* card = sBonkMgr.GetCard(offer.id))
                    maxRank = card->maxCopies;
            }
            else if (!offer.isWeapon)
                if (BonkPassive const* passive = sBonkMgr.GetPassive(offer.id))
                    maxRank = passive->maxRank;
            bool const ranked = (offer.isWeapon && offer.step != BONK_STEP_NEW) || offer.isCard;
            std::string before, after, label;
            DescribeOfferDamage(offer, before, after, label);
            std::vector<BonkStatChange> stats;
            DescribeOfferStats(offer, stats);

            WorldPacket option(SMSG_HOA_MESSAGE);
            HoAWriteOfferOption(option, i + 1, offer.isCard ? "c" : offer.step == BONK_STEP_EVOLVE ? "e" : offer.isWeapon ? "w" : "p",
                offer.newLevel, maxRank, name, icon, DescribeStep(offer), ranked ? std::to_string(offer.rarity) : "",
                offer.locked, before, after, label, CanBanish(offer));
            m_player->GetSession()->SendPacket(&option);
            for (BonkStatChange const& stat : stats)
            {
                WorldPacket statPacket(SMSG_HOA_MESSAGE);
                HoAWriteOfferStat(statPacket, i + 1, stat.label, stat.before, stat.after);
                m_player->GetSession()->SendPacket(&statPacket);
            }
        }
        WorldPacket end(SMSG_HOA_MESSAGE);
        HoAWriteOfferEnd(end);
        m_player->GetSession()->SendPacket(&end);
        return;
    }

    ChatHandler handler(m_player);
    if (m_offerSource == OFFER_CHEST)
        handler.SendSysMessage(GetString(BONK_STRING_OFFER_CHAT_CHEST).c_str());
    else
        handler.SendSysMessage(GetString(BONK_STRING_OFFER_CHAT_LEVEL, { std::to_string(m_player->GetLevel()) }).c_str());
    for (size_t i = 0; i < m_offer.size(); ++i)
    {
        Offer const& offer = m_offer[i];
        std::string const name = DescribeOffer(offer, nullptr);
        std::string kind;
        std::string const rarity = GetString(GetBonkRarityString(offer.rarity));
        if (offer.isCard)
            kind = GetString(BONK_STRING_OFFER_KIND_CARD, { rarity });
        else if (offer.isWeapon && offer.step == BONK_STEP_NEW)
            kind = GetString(BONK_STRING_OFFER_KIND_NEW);
        else if (offer.isWeapon)
            kind = GetString(BONK_STRING_OFFER_KIND_RARITY_RANK, { rarity, std::to_string(offer.newLevel) });
        else
            kind = GetString(BONK_STRING_OFFER_KIND_RANK, { std::to_string(offer.newLevel) });
        handler.PSendSysMessage("  %u) %s (%s): %s", uint32(i + 1), name.c_str(), kind.c_str(), JoinBonkLines(DescribeStep(offer)).c_str());
    }
    if (m_rerolls)
        handler.PSendSysMessage("  %s", GetString(BONK_STRING_OFFER_CHAT_REROLL, { std::to_string(m_rerolls) }).c_str());
    if (m_banishes)
        handler.PSendSysMessage("  %s", GetString(BONK_STRING_OFFER_CHAT_BANISH, { std::to_string(m_banishes) }).c_str());
    if (m_skips)
        handler.PSendSysMessage("  %s", GetString(BONK_STRING_OFFER_CHAT_SKIP, { std::to_string(m_skips) }).c_str());
}

void BonkRun::SendOfferClosed() const
{
    if (!m_player->GetBonkPlayer()->IsAddonReady())
        return;
    WorldPacket data(SMSG_HOA_MESSAGE);
    HoAWriteOfferClosed(data);
    m_player->GetSession()->SendPacket(&data);
}

void BonkRun::Finish(bool wentHome)
{
    if (m_state != STATE_RUNNING && m_state != STATE_PORTAL)
        return;

    m_state = STATE_ENDING;
    if (IsCoopGuest())
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op: guest %s run ends, home %u alive %u", m_player->GetName(), uint32(wentHome), uint32(m_player->IsAlive()));
    if (!IsCoopGuest())
        BonkCoop::OnHostFinished(m_player);
    m_wentHome = wentHome;
    SetPaused(false);
    RemoveHeroLooks();
    if (!wentHome && !m_player->IsAlive())
    {
        sBonkQuests.OnProgress(m_player, BONK_QUEST_DEATHS, 0, 1);
        LogDeath();
        m_player->GetBonkPlayer()->AddDetermination();
        if (!m_sandbox && !IsCoopGuest())
            m_player->GetBonkPlayer()->OnHardcoreDeath(m_lastStriker, m_map.name, m_player->GetLevel() + m_overcapLevel, m_kills);
    }

    if (wentHome)
        CollectAllShards();
    PayFinale();

    std::string const build = DescribeBuildTotals();
    DropOffers();
    ResolveRunGear(wentHome);
    if (!m_sandbox)
        LogRunEnd(wentHome, build);

    m_player->GetBonkPlayer()->RecordRun(m_victory ? m_difficultyLevel : 0, m_totalMs / IN_MILLISECONDS, m_kills, m_goldEarned);
    m_player->GetBonkPlayer()->EndHardcoreRun();
    AwardMastery();
    m_endTimer = BONK_END_DELAY_MS;

    if (m_player->IsAlive())
        m_player->CombatStop(true);

    BonkPlayer* bonk = m_player->GetBonkPlayer();
    uint32 const seconds = m_totalMs / IN_MILLISECONDS;
    if (bonk->IsAddonReady())
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteRunEnd(data, wentHome, seconds, m_kills, m_goldEarned, uint8(m_player->GetLevel()), m_stage, m_shardsEarned,
            m_victory, IsMythic(), bonk->GetBestLevel(), m_levelBestAtStart, bonk->GetLevelName(m_difficultyLevel),
            IsFinale() ? GetEndlessMs() / IN_MILLISECONDS : 0);
        m_player->GetSession()->SendPacket(&data);
    }
    else
        ChatHandler(m_player).SendSysMessage(GetString(m_victory ? BONK_STRING_RUN_END_CHAT_VICTORY : wentHome ? BONK_STRING_RUN_END_CHAT_HOME : BONK_STRING_RUN_END_CHAT_DEFEAT,
            { std::to_string(m_stage), FormatTime(seconds), std::to_string(m_kills), std::to_string(m_player->GetLevel()),
            FormatBonkMoney(m_goldEarned, GetLocale()), FormatBonkShards(m_shardsEarned, GetLocale()) }).c_str());

    if (bonk->IsAddonReady())
    {
        std::vector<BonkSummaryWeapon> weapons;
        for (OwnedWeapon const& owned : m_weapons)
        {
            BonkSummaryWeapon weapon;
            weapon.spellId = owned.weapon.spellId;
            weapon.spellIds = BonkStats::GetWeaponSpells(owned.weapon);
            weapon.name = Localize(BONK_FIELD_WEAPON_NAME, owned.weapon.id, owned.weapon.name);
            weapon.icon = owned.weapon.icon;
            weapon.level = owned.rank;
            weapon.maxLevel = 0;
            weapon.evolved = owned.weapon.evolvesFrom != 0;
            weapons.push_back(weapon);
        }
        WorldPacket support(SMSG_HOA_MESSAGE);
        HoAWriteRunSupport(support, DescribeSupport());
        m_player->GetSession()->SendPacket(&support);
        BonkStats::SendSummary(m_player, weapons);
    }

    ReportQuestCounts();
    sBonkQuests.Save(m_player->GetBonkPlayer()->GetProgressAccount());
    sBonkQuests.SendLog(m_player, "");
}

void BonkRun::SetMenuOpen(bool open)
{
    if (m_menuOpen == open)
        return;
    m_menuOpen = open;
    if (open)
    {
        if (m_state == STATE_RUNNING)
            SetPaused(true);
        return;
    }
    ResumeUnlessChoiceOpen();
    UpdateOffers();
}

bool BonkRun::HasOpenChoice() const
{
    return !m_offer.empty() || !m_leyOffer.empty() || m_vendorOpen || m_vaultOpen || m_gearOfferEntry || !m_glyphOffer.empty();
}

void BonkRun::ResumeUnlessChoiceOpen()
{
    if (!HasOpenChoice())
        SetPaused(false);
}

void BonkRun::SetPaused(bool paused)
{
    if (!paused && m_menuOpen)
        return;
    m_ownPaused = paused;
    ApplyPause(WantsPause());
}

void BonkRun::RefreshGroupEnemies()
{
    m_groupEnemies.clear();
    if (!m_player->GetGroup())
        return;
    std::vector<Player*> const group = BonkCoop::RunGroupOf(m_player);
    if (group.size() < 2)
        return;
    m_groupEnemies = m_mobs;
    for (Player* member : group)
        if (member != m_player && member->GetMapId() == m_player->GetMapId())
            if (BonkRun const* run = member->GetBonkPlayer()->GetRun())
                m_groupEnemies.insert(m_groupEnemies.end(), run->GetMobGuids().begin(), run->GetMobGuids().end());
}

void BonkRun::SetGroupHeld(bool held)
{
    if (m_groupHeld == held)
        return;
    m_groupHeld = held;
    ApplyPause(WantsPause());
}

void BonkRun::SetAway(bool away)
{
    if (m_away == away)
        return;
    m_away = away;
    ApplyPause(WantsPause());
    if (!away && m_followPending)
    {
        m_followPending = false;
        FollowToStage(m_followMap, m_followStage);
    }
}

void BonkRun::SetConnectionLost(bool lost)
{
    if (m_connectionLost == lost)
        return;
    m_connectionLost = lost;
    ApplyPause(WantsPause());
}

void BonkRun::ResolveChoiceForGroup()
{
    std::string error;
    if (!m_glyphOffer.empty())
        ChooseGlyph(urand(1, uint32(m_glyphOffer.size())), error);
    else if (!m_leyOffer.empty())
        PickLeyBuff(urand(1, uint32(m_leyOffer.size())), error);
    else if (!m_offer.empty())
        Pick(urand(1, uint32(m_offer.size())), error);
    else
        return;
    m_player->GetBonkPlayer()->Notify(BONK_STRING_COOP_CHOICE_TIMED_OUT);
}

void BonkRun::ApplyPause(bool paused)
{
    if (m_paused == paused)
        return;
    m_paused = paused;
    if (paused)
        m_pausedAtMs = WorldTimer::getMSTime();
    else
        ShiftDotStacks(WorldTimer::getMSTime() - m_pausedAtMs);

    m_player->SetTimeFrozen(paused);
    PauseHearth(paused);
    if (m_player->IsInWorld())
    {
        for (UnitMoveType type : { MOVE_WALK, MOVE_RUN, MOVE_RUN_BACK, MOVE_SWIM })
            m_player->UpdateSpeed(type, false);
        m_player->SetSpeedRate(MOVE_SWIM_BACK, paused ? 0.0f : 1.0f);
    }

    if (Map* map = m_player->FindMap())
    {
        for (ObjectGuid const& guid : m_mobs)
            if (Creature* mob = map->GetCreature(guid))
                if (BonkMobAI* ai = dynamic_cast<BonkMobAI*>(mob->AI()))
                    ai->SetFrozen(paused);

        if (m_miniEventActive && m_miniEvent.type == BONK_MINI_EVENT_CARAVAN)
            PauseCaravan(paused);

        auto hold = [this, map, paused](ObjectGuid const& guid, bool planted)
        {
            if (Creature* pet = map->GetCreature(guid))
                HoldPet(pet, paused, planted);
        };
        for (OwnedWeapon const& owned : m_weapons)
            for (ObjectGuid const& guid : owned.pets)
                hold(guid, IsPlanted(owned.weapon));
        for (Snake const& released : m_snakes)
            hold(released.guid, false);
        for (Beast const& beast : m_beasts)
            hold(beast.guid, false);
        for (RisenSkeleton const& risen : m_skeletons)
            hold(risen.guid, false);
        for (WarlockMinion const& minion : m_warlockMinions)
            hold(minion.guid, false);
        if (!paused)
            ResumeCharges();
    }

    if (!paused && m_player->IsInWorld())
    {
        m_objectives.ResendTimed(m_player);
        SendCardCooldowns();
    }

    if (m_player->GetBonkPlayer()->IsAddonReady())
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteRunPaused(data, paused);
        m_player->GetSession()->SendPacket(&data);
    }
}

void BonkRun::ResyncPause()
{
    char const* resent = "nothing open, unpaused";
    bool const menuWasOpen = m_menuOpen;
    if (!m_paused)
        resent = "not paused";
    else if (!m_offer.empty())
    {
        resent = "offer";
        SendOffer();
    }
    else if (!m_leyOffer.empty())
    {
        resent = "ley line";
        SendLeyOffer();
    }
    else if (!m_glyphOffer.empty())
    {
        resent = "glyph";
        SendGlyphOffer();
    }
    else if (m_gearOfferEntry)
    {
        resent = "gear";
        SendGearOffer();
    }
    else if (m_vendorOpen)
    {
        resent = "vendor";
        SendVendor();
    }
    else if (m_vaultOpen)
    {
        resent = "vault";
        SendVault();
    }
    else
    {
        m_menuOpen = false;
        SetPaused(false);
        UpdateOffers();
    }

    sLog.Player(m_player->GetSession(), LOG_LEVELUP, LOG_LVL_BASIC, "Bonk resync: %s at run minute %.2f (stage %u, %s, %s): %s, menu flag %s",
        m_player->GetName(), GetRunMinutes(), m_stage, m_map.key.c_str(), m_tier.key.c_str(), resent, menuWasOpen ? "set" : "clear");
    if (!m_paused && m_player->GetBonkPlayer()->IsAddonReady())
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteRunPaused(data, false);
        m_player->GetSession()->SendPacket(&data);
    }
}

void BonkRun::HoldPet(Creature* pet, bool hold, bool planted)
{
    if (hold)
    {
        pet->AttackStop();
        pet->GetMotionMaster()->Clear(false);
        pet->GetMotionMaster()->MoveIdle();
        pet->StopMoving(true);
        pet->AddUnitState(UNIT_STATE_ROOT);
        pet->SetRooted(true);
    }
    else if (!planted)
    {
        pet->ClearUnitState(UNIT_STATE_ROOT);
        pet->SetRooted(false);
    }
    pet->SetTimeFrozen(hold && pet->IsAlive());
}

bool BonkRun::IsPlanted(BonkWeapon const& weapon)
{
    return weapon.HasFlag(BONK_WEAPON_FLAG_HYDRA) || weapon.HasFlag(BONK_WEAPON_FLAG_TOTEM);
}

void BonkRun::HoldAuraTimers(uint32 diff)
{
    m_pauseAuraMs += diff;
    if (m_pauseAuraMs < BONK_PAUSE_AURA_MS)
        return;
    m_pauseAuraMs = 0;
    for (auto const& itr : m_player->GetSpellAuraHolderMap())
        itr.second->UpdateAuraDuration();
}

void BonkRun::OnMobStuck(Creature* mob)
{
    if (m_state != STATE_RUNNING || m_paused)
        return;
    if (BonkMobAI* ai = dynamic_cast<BonkMobAI*>(mob->AI()))
        if (ai->IsFlyer())
        {
            ai->FlyIn(m_player);
            return;
        }
    if (m_perched || IsWaitingInCrowd(mob))
        return;

    float x, y, z;
    if (FindMobPosition(x, y, z, m_map.spawnMinDistance, m_map.spawnMaxDistance))
        MoveMob(mob, x, y, z);
}

bool BonkRun::IsWaitingInCrowd(Creature const* mob) const
{
    if (!mob->IsWithinDistInMap(m_player, BONK_CROWD_WAIT_RANGE))
        return false;
    for (Creature const* other : GetMobsInRange(mob->GetObjectBoundingRadius() + BONK_CROWD_TOUCH_SLACK + BONK_CROWD_MAX_BODY, mob))
        if (mob->GetDistance2dToCenter(other) <= mob->GetObjectBoundingRadius() + other->GetObjectBoundingRadius() + BONK_CROWD_TOUCH_SLACK)
            return true;
    return false;
}

void BonkRun::CleanUp()
{
    SetPaused(false);
    m_player->SetTimeFrozen(false);
    m_player->GetBonkPlayer()->ClearSpellTweaks();
    DropOffers();
    ResolveRunGear(false);
    DespawnMiniEvent();
    DespawnMobs();
    DespawnObjects();
    m_objectives.Clear(m_player);
    DespawnShrines();
    DespawnVendor();
    DespawnOrbs();
    m_player->SetCreatureSummonLimit(sWorld.getConfig(CONFIG_UINT32_CREATURE_SUMMON_LIMIT));
    m_player->RemoveAurasDueToSpell(BONK_SPELL_MOVE_SPEED);
    m_player->RemoveAurasDueToSpell(BONK_SPELL_MAX_HEALTH);
    m_player->RemoveAurasDueToSpell(BONK_SPELL_DODGE);
    m_player->RemoveAurasDueToSpell(BONK_SPELL_PLAYER_SHIELD);
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
    m_player->GetBonkPlayer()->SendAuraValue(BONK_SPELL_PLAYER_SHIELD, 0, 0);
    SetNecroticStacks(0);
    ClearBossPressure();
    DespawnPools();
    DespawnWeaponOrbs();
    DespawnProjectiles();
    DespawnShotSources();
    m_trickShotTimes.clear();
    ClearHunterEvolutions();
    ClearPendingTrapLooks();
    m_pendingCasts.clear();
    m_heldShotSources.clear();
    m_telegraphs.Dismiss(m_player);
    m_player->GetBonkPlayer()->ForgetShownReachRing();
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
    m_spellShield = 0;
    m_spellShieldParts.clear();
    m_chestChoices.clear();
    if (m_player->GetBonkPlayer()->IsAddonReady())
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteMobClear(data);
        m_player->GetSession()->SendPacket(&data);
    }
    SetMovementImmunity(m_player, false);
    if (m_sandbox)
        EndSandbox();
}

void BonkRun::Exit()
{
    if (IsCoopGuest())
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op: guest %s exits run, state %u", m_player->GetName(), uint32(m_state));
    CleanUp();
    m_state = STATE_FINISHED;

    BonkPlayer* bonk = m_player->GetBonkPlayer();
    bonk->ResetCharacter();
    ReturnBroughtGear();
    ClearSky();
    bonk->TeleportToCamp();
}

void BonkRun::Abort()
{
    if (m_state == STATE_FINISHED)
        return;

    if (!IsCoopGuest() && BonkCoop::InGroupRun(m_player))
        BonkCoop::OnHostFinished(m_player);

    EndHardcoreRunOnAbort();
    if (m_state == STATE_RUNNING || m_state == STATE_PORTAL || (m_state == STATE_ENTERING && m_stage > 1))
    {
        m_player->GetBonkPlayer()->RecordRun(0, m_totalMs / IN_MILLISECONDS, m_kills, m_goldEarned);
        AwardMastery();
    }

    CleanUp();
    m_state = STATE_FINISHED;
    m_player->GetBonkPlayer()->ResetCharacter();
    ReturnBroughtGear();
}

void BonkRun::Surrender()
{
    if (m_sandbox)
        LeaveSandbox();
    else if (m_state == STATE_RUNNING)
        Finish(IsFinale() && m_player->IsAlive());
    else if (m_state == STATE_PORTAL)
        Finish(true);
    else if (m_state == STATE_ENTERING)
        Exit();
}

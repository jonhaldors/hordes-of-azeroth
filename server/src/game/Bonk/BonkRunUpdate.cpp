#include "BonkRunInternal.h"

void BonkRun::SendFullState() const
{
    BonkPlayer* bonk = m_player->GetBonkPlayer();
    if (bonk->IsAddonReady())
    {
        std::string const mapName = Localize(BONK_FIELD_MAP_NAME, m_map.id, m_map.name);
        std::string const difficulty = m_sandbox ? GetString(BONK_STRING_SANDBOX) : Localize(BONK_FIELD_TIER_NAME, m_tier.id, m_tier.name);
        std::string const timeline = m_sandbox ? "" : DescribeTimelineMarks();
        std::string const levelName = m_sandbox ? "" : bonk->GetLevelName(m_difficultyLevel);
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteRunStart(data, mapName, difficulty, m_sandbox ? 0 : m_map.durationSeconds, m_stage,
            m_sandbox ? 0 : GetFirstMinibossSecond(), timeline, !m_sandbox && IsMythic(), m_sandbox ? 3 : m_tier.stages,
            levelName, !m_sandbox && IsFinale(), m_sandbox);
        m_player->GetSession()->SendPacket(&data);
    }
    if (m_coopNoPause && bonk->IsAddonReady())
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteCoopNoPause(data, true);
        m_player->GetSession()->SendPacket(&data);
    }
    SendLoadout();
    SendState();
    SendRunXp();
    SendCards();
    SendLeyBlessings();
    if (!m_offer.empty())
        SendOffer();
    m_objectives.Resend(m_player);
    for (Player* member : BonkCoop::RunGroupOf(m_player))
        if (BonkRun const* run = member->GetBonkPlayer()->GetRun())
            run->ShowSharedGlowsTo(m_player);
    if (m_greedStacks)
        SendGreed();
    if (!m_leyOffer.empty())
        SendLeyOffer();
    if (m_vendorOpen)
        SendVendor();
    SendGlyphs();
    if (!m_glyphOffer.empty())
        SendGlyphOffer();
    if (m_miniEventActive)
        SendMiniEventTimer(true);
    m_player->GetBonkPlayer()->SendDash();
    SendShieldState();
}

void BonkRun::UpdateOwnCombat(uint32 diff)
{
    UpdateSteadyAim();
    UpdateWeapons(diff);
    if (m_state != STATE_RUNNING)
        return;
    UpdatePendingCasts(diff);
    LandDueBolts();
    UpdateArrowStorms(diff);
    UpdateKeywordClouds(diff);
    UpdateWarrior(diff);
    UpdateMage(diff);
    UpdateTalents(diff);
    UpdateShaman(diff);
    UpdatePriest(diff);
    UpdateRogue(diff);
    UpdateWarlock(diff);
    UpdateDruid(diff);
    UpdateTalents();
    UpdateTalentAuras();
    UpdateIcePath(diff);
    UpdateWeaponOrbs(diff);
    UpdateProjectiles(diff);
    UpdateShotSources(diff);
    UpdateTraps(diff);
    UpdatePetTargets(diff);
    UpdateBeasts(diff);
    ResolveCriticalStrikes();
    UpdateKeywords(diff);
    UpdateDefensive(diff);
}

void BonkRun::UpdateRunning(uint32 diff)
{
    if (!m_player->IsAlive() && !BonkCoop::IsDowned(m_player))
    {
        SpeakBossLine(m_player->GetMap()->GetCreature(m_lastStrikerGuid), BONK_BOSS_LINE_KILL);
        if (m_sandbox)
        {
            ++m_sandboxDeaths;
            ReviveInSandbox();
            return;
        }
        if (IsDivineShieldReady())
            Revive(false, GetGlyph(BONK_GLYPH_DIVINE_SHIELD));
        else if (m_revives)
            Revive();
        else if (m_soulstones)
            Revive(true);
        else if (!BonkCoop::Down(m_player))
            Finish(false);
        return;
    }

    UpdateOffers();
    UpdateNatives(diff);
    if (m_paused)
        return;

    if (!m_sandbox)
        m_elapsedMs += diff;
    m_totalMs += diff;
    m_rewardMs += diff * GetBonkMapRewardPercent(m_map.type) / 100;

    UpdateHeading(diff);
    UpdateBoundary(diff);
    UpdateRecovery(diff);
    UpdateCards(diff);
    UpdateGlyphs(diff);
    UpdateFeel(diff);
    UpdateTrinkets(diff);
    UpdateShield(diff);
    UpdateNecrotic(diff);
    UpdatePools(diff);
    UpdateVoidZones(diff);
    UpdateHeroMark(diff);
    UpdateBossWounds(diff);
    UpdatePowerups(diff, !m_sandbox);
    UpdateObjectives(diff);
    UpdateOrbs(diff);
    UpdateShards(diff);
    UpdateHeals(diff);
    UpdateGearDrops(diff);
    UpdateHearth(diff);
    if (m_state != STATE_RUNNING)
        return;
    if (m_sandbox)
        UpdateSandbox(diff);
    else
    {
        UpdateEvents();
        if (m_state != STATE_RUNNING)
            return;
        UpdateMiniEvents(diff);
        UpdateShrines(diff);
        UpdateHidden(diff);
        UpdateVendor(diff);
        if (m_state != STATE_RUNNING)
            return;

        UpdateEmerging(diff);
        UpdateSpawns(diff);
        if (m_state != STATE_RUNNING)
            return;
        if (m_player->IsAlive())
            UpdateStragglers(diff);
    }
    if (m_state != STATE_RUNNING)
        return;

    UpdateCrowd(diff);
    if (m_player->IsAlive())
        UpdateOwnCombat(diff);
    if (m_state != STATE_RUNNING)
        return;
    UpdateEnemyMissiles(diff);
    m_telegraphs.Update(m_player, diff);
    if (m_state != STATE_RUNNING)
        return;

    m_stateTimer += diff;
    if (m_stateTimer >= BONK_STATE_INTERVAL_MS)
    {
        m_stateTimer = 0;
        UpdateGear();
        SendState();
        RefreshChangedWeaponInfo();
    }
}

void BonkRun::DropOffers()
{
    BonkPlayer* bonk = m_player->GetBonkPlayer();
    if (!m_offer.empty())
        SendOfferClosed();
    if (!m_glyphOffer.empty())
    {
        if (m_player->GetBonkPlayer()->IsAddonReady())
        {
            WorldPacket data(SMSG_HOA_MESSAGE);
            HoAWriteGlyphClose(data);
            m_player->GetSession()->SendPacket(&data);
        }
    }
    if (!m_leyOffer.empty())
    {
        if (m_player->GetBonkPlayer()->IsAddonReady())
        {
            WorldPacket data(SMSG_HOA_MESSAGE);
            HoAWriteLeyClosed(data);
            m_player->GetSession()->SendPacket(&data);
        }
    }
    CloseGearOffer();
    m_offer.clear();
    m_glyphOffer.clear();
    m_leyOffer.clear();
    m_pendingLevels = 0;
    m_pendingGlyphPicks = 0;
    m_pendingLeyOffers = 0;
    m_pendingGear.clear();
    m_pendingChestChoices.clear();
}

void BonkRun::UpdateOffers()
{
    if (m_state != STATE_RUNNING && m_state != STATE_PORTAL)
        return;

    uint32 const level = m_player->GetLevel();
    if (level > m_lastLevel)
    {
        m_pendingLevels += level - m_lastLevel;
        m_lastLevel = level;
    }

    if (!m_offer.empty() || !m_leyOffer.empty() || m_vendorOpen || m_vaultOpen || m_gearOfferEntry || !m_glyphOffer.empty())
        return;

    if (m_stress.on)
    {
        m_pendingLevels = 0;
        m_pendingGlyphPicks = 0;
        m_pendingGear.clear();
        m_pendingChestChoices.clear();
        m_pendingLeyOffers = 0;
        return;
    }

    if (m_pendingGlyphPicks)
        OfferGlyphs();
    else if (!m_pendingChestChoices.empty())
        OfferUpgrades(OFFER_CHEST);
    else if (!m_pendingGear.empty())
        OfferGear();
    else if (m_pendingLevels && m_sandbox && m_sandboxQuietLevels)
        m_pendingLevels = 0;
    else if (m_pendingLevels)
        OfferUpgrades(OFFER_LEVEL);
    else if (m_pendingLeyOffers)
        OfferLeyBuffs();
}

void BonkRun::UpdateBoundary(uint32 diff)
{
    m_boundaryTimer += diff;
    if (m_boundaryTimer < BONK_BOUNDARY_INTERVAL_MS)
        return;
    m_boundaryTimer = 0;

    if (!m_map.zoneId || m_player->IsBeingTeleported())
        return;

    if (m_player->GetZoneId() == m_map.zoneId)
    {
        m_safeX = m_player->GetPositionX();
        m_safeY = m_player->GetPositionY();
        m_safeZ = m_player->GetPositionZ();
        return;
    }

    m_player->NearTeleportTo(m_safeX, m_safeY, m_safeZ, m_player->GetOrientation());
    m_player->GetBonkPlayer()->Notify(BONK_STRING_YOU_CANT_LEAVE, { Localize(BONK_FIELD_MAP_NAME, m_map.id, m_map.name) });
}

void BonkRun::UpdateNatives(uint32 diff)
{
    m_nativeTimer += diff;
    if (m_nativeTimer < BONK_NATIVE_SWEEP_MS)
        return;
    m_nativeTimer = 0;

    if (m_player->IsBeingTeleported() || !m_player->IsInWorld())
        return;

    std::list<Creature*> creatures;
    MaNGOS::AnyUnitInObjectRangeCheck check(m_player, BONK_NATIVE_SWEEP_RANGE);
    MaNGOS::CreatureListSearcher<MaNGOS::AnyUnitInObjectRangeCheck> searcher(creatures, check);
    Cell::VisitGridObjects(m_player, searcher, BONK_NATIVE_SWEEP_RANGE);

    for (Creature* creature : creatures)
    {
        if (creature->IsTemporarySummon() && static_cast<TemporarySummon*>(creature)->GetSummonerGuid().IsPlayer())
            continue;
        if (creature->GetCharmerOrOwnerGuid().IsPlayer() || creature->IsFriendlyTo(m_player))
            continue;
        if (creature->HasCreatureState(CSTATE_DESPAWNING))
            continue;

        creature->DespawnOrUnsummon(0, BONK_NATIVE_RESPAWN_SEC);
    }
}

void BonkRun::UpdateRecovery(uint32 diff)
{
    m_recoveryTimer += diff;
    if (m_recoveryTimer < IN_MILLISECONDS)
        return;
    m_recoveryTimer -= IN_MILLISECONDS;
    ReportQuestCounts();
    SamplePerfSecond();

    uint32 const leech = uint32(m_leechCarry);
    m_leechCarry = 0.0f;
    m_leechUnreported += leech;
    if (leech && m_player->IsAlive())
    {
        SupportScope scope(*this, PassiveSupport(BONK_PASSIVE_LEECH));
        HealHero(ReduceHealing(leech));
    }

    float const percent = GetPassiveTotal(BONK_PASSIVE_RECOVERY);
    if (percent > 0.0f && m_player->IsAlive())
    {
        SupportScope scope(*this, PassiveSupport(BONK_PASSIVE_RECOVERY));
        RegenerateHero(ReduceHealing(std::max(1u, uint32(m_player->GetMaxHealth() * percent / 100.0f))));
    }

    uint32 const bleedHeal = uint32(m_bleedHeal);
    m_bleedHeal = 0.0f;
    if (bleedHeal && m_player->IsAlive() && m_player->GetHealth() < m_player->GetMaxHealth())
    {
        uint32 const amount = ReduceHealing(bleedHeal);
        SupportScope scope(*this, m_bleedHealSource);
        if (SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(BONK_SPELL_BLEED_HEAL))
            m_player->DealHeal(m_player, amount, spellInfo);
        else
            m_player->ModifyHealth(int32(amount));
    }
}

void BonkRun::ReportQuestCounts()
{
    if (m_crits != m_critsReported)
    {
        m_critsReported = m_crits;
        sBonkQuests.OnProgress(m_player, BONK_QUEST_CRITS, 0, m_crits, true);
    }
    if (m_healedUnreported)
    {
        sBonkQuests.OnProgress(m_player, BONK_QUEST_HEALED, 0, m_healedUnreported);
        m_healedUnreported = 0;
    }

    auto report = [this](BonkQuestType type, uint32& unreported)
    {
        if (unreported)
            sBonkQuests.OnProgress(m_player, type, 0, unreported);
        unreported = 0;
    };
    if (m_runXpDirty)
        UpdateRunXp(true);

    if (m_player->IsAlive())
        m_minuteLowestHealth = std::min(m_minuteLowestHealth, uint32(m_player->GetHealthPercent()));
    m_minuteClientObjectsPeak = std::max(m_minuteClientObjectsPeak, CountClientObjects());
    if (!m_sandbox && m_totalMs >= m_nextLogMinute * MINUTE * IN_MILLISECONDS)
        LogMinute();
    m_recentHits.erase(std::remove_if(m_recentHits.begin(), m_recentHits.end(),
        [this](std::pair<uint32, uint32> const& hit) { return hit.first + 10 * IN_MILLISECONDS < m_totalMs; }), m_recentHits.end());

    report(BONK_QUEST_LEECH_HEALED, m_leechUnreported);
    report(BONK_QUEST_DODGES, m_dodgesUnreported);
    report(BONK_QUEST_ARMOR_ABSORBED, m_armorUnreported);
    report(BONK_QUEST_PROJECTILES, m_projectilesUnreported);

    uint32 const maxHealth = m_player->GetMaxHealth();
    if (maxHealth > m_maxHealthReported)
    {
        m_maxHealthReported = maxHealth;
        sBonkQuests.OnProgress(m_player, BONK_QUEST_MAX_HEALTH, 0, maxHealth, true);
    }
    uint32 const unhurt = (m_totalMs - (m_hurt ? m_lastHurtMs : 0)) / IN_MILLISECONDS / 10 * 10;
    if (unhurt != m_unhurtReported)
    {
        m_unhurtReported = unhurt;
        if (unhurt)
            sBonkQuests.OnProgress(m_player, BONK_QUEST_UNHURT_TIME, 0, unhurt, true);
    }
    uint32 const overtimeStartMs = (m_map.durationSeconds + BONK_OVERTIME_AFTER_SEC) * IN_MILLISECONDS;
    uint32 const overtime = m_bossSpawned && !IsFinale() && m_elapsedMs > overtimeStartMs ? (m_elapsedMs - overtimeStartMs) / IN_MILLISECONDS / 10 * 10 : 0;
    if (overtime > m_overtimeReported)
    {
        m_overtimeReported = overtime;
        sBonkQuests.OnProgress(m_player, BONK_QUEST_OVERTIME, 0, overtime, true);
    }
    for (auto const& itr : m_passiveRanks)
    {
        uint32& reported = m_ranksReported[{ false, itr.first }];
        if (itr.second > reported)
        {
            reported = itr.second;
            sBonkQuests.OnProgress(m_player, BONK_QUEST_PASSIVE_RANK, itr.first, itr.second, true);
        }
    }
    for (OwnedWeapon const& owned : m_weapons)
    {
        uint32& reported = m_ranksReported[{ true, owned.weapon.id }];
        if (owned.rank > reported)
        {
            reported = owned.rank;
            sBonkQuests.OnProgress(m_player, BONK_QUEST_SPELL_RANK, owned.weapon.id, owned.rank, true);
        }
    }
}

void BonkRun::UpdateEvents()
{
    uint32 const elapsedSeconds = m_elapsedMs / IN_MILLISECONDS;
    bool const quiet = IsQuietTime();

    if (!quiet && !m_heldEvents.empty())
    {
        std::vector<BonkMapEvent> const held = std::move(m_heldEvents);
        m_heldEvents.clear();
        if (!m_bossSpawned)
            for (BonkMapEvent const& event : held)
            {
                RunEvent(event);
                if (m_state != STATE_RUNNING)
                    return;
            }
    }

    while (m_nextEvent < m_map.events.size() && m_map.events[m_nextEvent].second <= elapsedSeconds)
    {
        BonkMapEvent const& event = m_map.events[m_nextEvent++];
        if (quiet && IsQuietEvent(event.type))
        {
            m_heldEvents.push_back(event);
            continue;
        }
        RunEvent(event);
        if (m_state != STATE_RUNNING)
            return;
    }
}

bool BonkRun::IsQuietEvent(BonkEventType type)
{
    return type == BONK_EVENT_ELITES || type == BONK_EVENT_SWARM || type == BONK_EVENT_RING || type == BONK_EVENT_RUSH;
}

bool BonkRun::IsQuietTime() const
{
    uint32 const second = m_elapsedMs / IN_MILLISECONDS;
    BonkWaveBeat const beat = GetWave().beat;
    if (beat == BONK_BEAT_LULL || beat == BONK_BEAT_MINIBOSS)
        return true;
    return second + BONK_QUIET_SECONDS >= m_map.durationSeconds;
}

void BonkRun::RunEvent(BonkMapEvent const& event)
{
    BonkPlayer* bonk = m_player->GetBonkPlayer();

    switch (event.type)
    {
        case BONK_EVENT_MINIBOSS:
        {
            if (IsCoopGuest())
                break;
            Creature* arrived = nullptr;
            uint32 const count = (event.count + (event.count ? uint32(GetGlyphValue(BONK_GLYPH_AMBITION, 0)) : 0)) * GetCoopBossCount();
            for (uint32 i = 0; i < count; ++i)
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
            break;
        }
        case BONK_EVENT_ELITES:
        {
            bool spawned = false;
            uint32 const count = uint32(event.count * GetEliteScale() + 0.5f);
            for (uint32 i = 0; i < count; ++i)
                if (BonkMapCreature const* creature = PickCreature(BONK_SPAWN_ELITE))
                    spawned |= SpawnMob(*creature) != nullptr;
            if (spawned)
                bonk->Notify(BONK_STRING_ELITES_ARE_CLOSING_IN);
            break;
        }
        case BONK_EVENT_SWARM:
        {
            PruneMobs();
            uint32 const alive = m_mobs.size();
            uint32 const count = std::min(event.count, m_tier.maxAlive > alive ? m_tier.maxAlive - alive : 0u);
            for (uint32 i = 0; i < count; ++i)
                if (BonkMapCreature const* creature = PickTrash())
                    SpawnMob(*creature);
            if (count)
                bonk->Notify(BONK_STRING_SWARM_IS_COMING);
            break;
        }
        case BONK_EVENT_RING:
        case BONK_EVENT_RUSH:
        {
            if (SpawnFormation(event))
                bonk->Notify(event.type == BONK_EVENT_RING ? BONK_STRING_YOU_ARE_SURROUNDED : BONK_STRING_ENEMIES_ARE_CHARGING_IN);
            break;
        }
        case BONK_EVENT_CHESTS:
        {
            if (IsCoopGuest())
                break;
            uint32 placed = 0;
            for (uint32 i = 0; i < event.count; ++i)
                placed += SpawnChestNearby() ? 1 : 0;
            if (placed)
                bonk->Notify(placed == 1 ? BONK_STRING_CHEST_APPEARED_NEARBY : BONK_STRING_CHESTS_APPEARED_NEARBY);
            break;
        }
        default:
            break;
    }
}

uint32 BonkRun::SpawnFormation(BonkMapEvent const& event)
{
    PruneMobs();
    uint32 const alive = m_mobs.size();
    uint32 const count = std::min(event.count, m_tier.maxAlive > alive ? m_tier.maxAlive - alive : 0u);

    float heading;
    bool const ring = event.type == BONK_EVENT_RING;
    float const gap = ring ? GetRingGap() : 0.0f;
    float const side = ring ? (GetHeading(heading) ? heading : m_player->GetOrientation()) + gap / 2.0f : frand(0.0f, 2.0f * M_PI_F);
    uint32 spawned = 0;
    for (uint32 i = 0; i < count; ++i)
    {
        BonkMapCreature const* creature = PickTrash();
        if (!creature)
            break;

        float angle, distance;
        if (ring)
        {
            angle = side + (2.0f * M_PI_F - gap) * (i + 0.5f) / count;
            distance = BONK_RING_DISTANCE;
        }
        else
        {
            angle = side + frand(-BONK_RUSH_WIDTH, BONK_RUSH_WIDTH);
            distance = frand(m_map.spawnMinDistance, m_map.spawnMaxDistance);
        }

        float x, y, z;
        if (!FindSpawnPositionAt(angle, distance, x, y, z))
            continue;
        if (ring ? EmergeMobAt(*creature, x, y, z, false, 0) : SpawnMobAt(*creature, x, y, z) != nullptr)
            ++spawned;
    }
    return spawned;
}


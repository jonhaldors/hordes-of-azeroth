#include "BonkRunInternal.h"

Creature* BonkRun::SpawnMob(BonkMapCreature const& creature)
{
    float x, y, z;
    if (!FindMobPosition(x, y, z, m_map.spawnMinDistance, m_map.spawnMaxDistance))
        return nullptr;
    return SpawnMobAt(creature, x, y, z);
}

bool BonkRun::RollVeteran(BonkMapCreature const& creature) const
{
    if (m_stress.on || creature.kind != BONK_SPAWN_NORMAL || m_tier.veteranChance <= 0.0f)
        return false;
    if (creature.archetype != BONK_ARCHETYPE_GRUNT && creature.archetype != BONK_ARCHETYPE_CASTER && creature.archetype != BONK_ARCHETYPE_CHARGER)
        return false;
    return roll_chance_f(m_tier.veteranChance + m_levelRow.veteranChance);
}

Creature* BonkRun::SpawnMobAt(BonkMapCreature const& creature, float x, float y, float z, bool veteran)
{
    float const facing = std::atan2(m_player->GetPositionY() - y, m_player->GetPositionX() - x);
    m_lastPlateId = m_lastPlateId % BONK_MAX_PLATE_ID + 1;
    BonkMobAI::SetNextPlateId(m_lastPlateId);
    uint32 const level = std::min(GetMobLevel() + GetKindLevelBonus(creature.kind), 63u);
    BonkMobAI::SetNextLevel(level);
    Creature* mob = m_player->SummonCreature(creature.entry, x, y, z, facing, TEMPSUMMON_CORPSE_TIMED_DESPAWN, 2000, false, 0, &BonkMobAI::Install);
    if (!mob)
        return nullptr;

    mob->RemoveAllAuras();
    mob->ClearCreatureState(CSTATE_REGEN_HEALTH);
    mob->SetInvincibilityHpThreshold(0);
    mob->RemoveFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_IMMUNE_TO_PLAYER | UNIT_FLAG_IMMUNE_TO_NPC | UNIT_FLAG_NOT_SELECTABLE);

    mob->InitStatsForLevel();
    mob->SetModifierValue(UNIT_MOD_ARMOR, TOTAL_PCT, 0.0f);
    mob->UpdateArmor();

    BonkArchetypeInfo const* archetype = creature.kind == BONK_SPAWN_NORMAL ? &sBonkMgr.GetArchetype(creature.archetype) : nullptr;
    float const archetypeDamage = archetype ? archetype->damageMultiplier : 1.0f;
    float const veteranDamage = (veteran ? BONK_VETERAN_DAMAGE : 1.0f) *
        (creature.kind == BONK_SPAWN_MINIBOSS ? 1.0f + GetGlyphValue(BONK_GLYPH_AMBITION, 2) / 100.0f : 1.0f);
    float const fullHealth = GetSpawnHealthUncapped(creature.kind, creature.archetype, creature.healthMultiplier * (veteran ? BONK_VETERAN_HEALTH : 1.0f));
    uint32 const health = uint32(std::min(BONK_MAX_MOB_HEALTH, fullHealth));
    mob->SetModifierValue(UNIT_MOD_HEALTH, BASE_VALUE, float(health));
    mob->SetMaxHealth(health);
    mob->SetHealth(health);
    if (BonkMobAI* ai = dynamic_cast<BonkMobAI*>(mob->AI()))
        ai->SetHealthOverflow(fullHealth / float(health));

    {
        float const damage = std::max(1.0f, GetHeroBaseHealth() * GetScalingNow().hitShare * GetStageDamageMultiplier() *
            m_map.damageMultiplier * creature.damageMultiplier * archetypeDamage * veteranDamage * GetKindDamage(creature.kind) * GetTierKindDamage(creature.kind) * m_spawnDamageScale);
        mob->SetAttackTime(BASE_ATTACK, BONK_MOB_SWING_MS);
        mob->SetBaseWeaponDamage(BASE_ATTACK, MINDAMAGE, damage * 0.85f);
        mob->SetBaseWeaponDamage(BASE_ATTACK, MAXDAMAGE, damage * 1.15f);
        mob->UpdateDamagePhysical(BASE_ATTACK);
    }

    mob->SetFactionTemplateId(BONK_ENEMY_FACTION);
    mob->SetBaseSpeedRate(MOVE_WALK, creature.speed);
    mob->SetBaseSpeedRate(MOVE_RUN, creature.speed);
    if (creature.scale > 1.0f)
    {
        mob->SetObjectScale(mob->GetObjectScale() * creature.scale);
        mob->UpdateModelData();
    }

    if (archetype && creature.archetype == BONK_ARCHETYPE_GRUNT)
        m_gruntRadius = std::max(m_gruntRadius, mob->GetObjectBoundingRadius());
    else if (archetype && creature.archetype == BONK_ARCHETYPE_BRUISER && m_gruntRadius > 0.0f)
    {
        float const radius = mob->GetObjectBoundingRadius();
        float const wanted = BONK_BRUISER_SIZE * m_gruntRadius;
        if (radius > 0.0f && radius < wanted)
        {
            mob->SetObjectScale(mob->GetObjectScale() * std::min(wanted / radius, BONK_BRUISER_MAX_GROWTH));
            mob->UpdateModelData();
        }
    }
    if (veteran)
    {
        mob->SetObjectScale(mob->GetObjectScale() * BONK_VETERAN_SIZE);
        mob->UpdateModelData();
    }
    if (creature.kind == BONK_SPAWN_BOSS || creature.kind == BONK_SPAWN_MINIBOSS)
    {
        float const radius = mob->GetObjectBoundingRadius();
        float const wanted = creature.kind == BONK_SPAWN_BOSS ? BONK_BOSS_MIN_RADIUS : BONK_MINIBOSS_MIN_RADIUS;
        if (radius > 0.0f && radius < wanted)
        {
            mob->SetObjectScale(mob->GetObjectScale() * std::min(wanted / radius, BONK_BOSS_MAX_GROWTH));
            mob->UpdateModelData();
        }
    }
    mob->SetNoXP();

    if (BonkMobAI* ai = dynamic_cast<BonkMobAI*>(mob->AI()))
    {
        ai->SetArchetype(creature.archetype);
        ai->SetVeteran(veteran);
        ai->Setup(creature.kind);
    }

    m_mobs.push_back(mob->GetObjectGuid());
    if (m_sandbox)
    {
        PrepareSandboxMob(mob);
        return mob;
    }
    if (creature.kind == BONK_SPAWN_BOSS || creature.kind == BONK_SPAWN_MINIBOSS)
    {
        m_bossArrivals[mob->GetObjectGuid()] = { m_totalMs, m_damageTaken };
        SpeakBossLine(mob, BONK_BOSS_LINE_ARRIVE);
        bool const boss = creature.kind == BONK_SPAWN_BOSS;
        m_objectives.Follow(m_player, boss ? BONK_OBJECTIVE_BOSS : BONK_OBJECTIVE_MINIBOSS, mob, m_player->GetBonkPlayer()->GetLocalName(mob), 0,
            boss ? BONK_BOSS_PIN_ICON : BONK_MINIBOSS_PIN_ICON, GetString(boss ? BONK_STRING_OBJECTIVE_BOSS : BONK_STRING_OBJECTIVE_MINIBOSS));
    }
    if (creature.kind == BONK_SPAWN_BOSS)
    {
        if (m_stageBosses.empty())
            m_bossGuid = mob->GetObjectGuid();
        m_stageBosses.push_back(mob->GetObjectGuid());
        SendBossMusic(true);
    }
    return mob;
}

std::vector<Creature*> BonkRun::GetMobsInRange(float range, WorldObject const* center) const
{
    if (!center)
        center = m_player;

    Map* map = m_player->GetMap();
    std::vector<std::pair<float, Creature*>> found;
    for (ObjectGuid const& guid : GetEnemyGuids())
    {
        Creature* mob = map->GetCreature(guid);
        if (!mob || !mob->IsAlive() || mob->HasCreatureState(CSTATE_DESPAWNING))
            continue;

        if (mob == center)
            continue;
        float const distance = center->GetDistance(mob);
        if (distance <= range)
            found.emplace_back(distance, mob);
    }

    std::sort(found.begin(), found.end(), [](auto const& a, auto const& b) { return a.first < b.first; });

    std::vector<Creature*> mobs;
    mobs.reserve(found.size());
    for (auto const& itr : found)
        mobs.push_back(itr.second);
    return mobs;
}

void BonkRun::DespawnMobs()
{
    Map* map = m_player->FindMap();
    if (map)
        for (ObjectGuid const& guid : m_mobs)
            if (Creature* mob = map->GetCreature(guid))
            {
                mob->SetTimeFrozen(false);
                mob->DespawnOrUnsummon();
            }
    if (map)
        for (TimedMob const& emerging : m_emerging)
            if (Creature* mob = map->GetCreature(emerging.guid))
                mob->DespawnOrUnsummon();
    m_emerging.clear();
    m_pendingSpawns.clear();
    m_mobs.clear();
    m_farSince.clear();
    m_crowd.Clear();
    m_packSpots.clear();
}

GameObject* BonkRun::PlaceObject(uint32 entry, float x, float y, float z, uint32 lifetimeSeconds)
{
    return m_player->SummonGameObject(entry, x, y, z, frand(0.0f, 2.0f * M_PI_F), 0.0f, 0.0f, 0.0f, 0.0f, lifetimeSeconds, false);
}

bool BonkRun::SpawnChest(bool free, float x, float y, float z, uint32 choices)
{
    MoveToSafeGround(x, y, z);
    GameObject* chest = PlaceObject(free ? BONK_GO_CHEST_FREE : BONK_GO_CHEST, x, y, z, BONK_OBJECT_LIFETIME_SEC);
    if (!chest)
        return false;
    m_chests.push_back(chest->GetObjectGuid());
    m_chestChoices[chest->GetObjectGuid()] = choices;
    m_chestGlows[chest->GetObjectGuid()] = free ? PlaceSharedGlow(chest, BONK_SPELL_FREE_CHEST_GLOW, BONK_FREE_CHEST_GLOW_SCALE) : PlaceSharedGlow(chest, BONK_SPELL_VALOR_CHEST_GLOW, BONK_CHEST_GLOW_SCALE);
    m_chestObjectives[chest->GetObjectGuid()] = m_objectives.Add(m_player, BONK_OBJECTIVE_CHEST, x, y, z, m_player->GetBonkPlayer()->GetLocalName(chest), 0,
        free ? BONK_FREE_CHEST_PIN_ICON : BONK_CHEST_PIN_ICON, GetString(free ? BONK_STRING_OBJECTIVE_CHEST_FREE : BONK_STRING_OBJECTIVE_CHEST_VALOR));
    return true;
}

BonkRun::Glow BonkRun::PlaceSharedGlow(GameObject const* go, uint32 spellId, float scale) const
{
    Glow glow;
    glow.key = NextBonkAuraKey();
    glow.spellId = spellId;
    glow.scale = scale;
    for (Player* member : BonkCoop::RunGroupOf(m_player))
        ShowGlowTo(member, go->GetObjectGuid(), glow);
    return glow;
}

void BonkRun::ShowGlowTo(Player* viewer, ObjectGuid const& guid, Glow const& glow) const
{
    Map* map = m_player->FindMap();
    GameObject const* go = map ? map->GetGameObject(guid) : nullptr;
    if (go)
        SendBonkAuraAt(viewer, glow.key, glow.spellId, go->GetPositionX(), go->GetPositionY(), go->GetPositionZ(), glow.scale);
}

void BonkRun::ShowSharedGlowsTo(Player* viewer) const
{
    for (auto const& chest : m_chestGlows)
    {
        auto opened = m_chestOpenedBy.find(chest.first);
        if (opened == m_chestOpenedBy.end() || !opened->second.count(viewer->GetObjectGuid()))
            ShowGlowTo(viewer, chest.first, chest.second);
    }
    for (auto const& powerup : m_powerupGlows)
        ShowGlowTo(viewer, powerup.first, powerup.second);
}

void BonkRun::RemoveGlow(std::map<ObjectGuid, Glow>& glows, ObjectGuid const& guid)
{
    auto const itr = glows.find(guid);
    if (itr == glows.end())
        return;
    for (Player* member : BonkCoop::RunGroupOf(m_player))
        SendBonkAuraGone(member, itr->second.key);
    glows.erase(itr);
}

void BonkRun::ForgetChestObjective(ObjectGuid const& chest)
{
    RemoveGlow(m_chestGlows, chest);
    auto const itr = m_chestObjectives.find(chest);
    if (itr == m_chestObjectives.end())
        return;
    m_objectives.Remove(m_player, itr->second);
    m_chestObjectives.erase(itr);
}

void BonkRun::DropChest(Creature const* mob, BonkSpawnKind kind)
{
    BonkMobAI const* ai = dynamic_cast<BonkMobAI const*>(mob->AI());
    uint32 const affixes = ai ? ai->GetAffixCount() : 0;

    if (kind == BONK_SPAWN_ELITE)
    {
        float const chance = BONK_ELITE_CHEST_CHANCE + BONK_ELITE_CHEST_PER_AFFIX * affixes +
            BONK_ELITE_CHEST_PER_LUCK * std::max(0.0f, GetPassiveTotal(BONK_PASSIVE_LUCK));
        if (m_elitesWithoutChest < BONK_ELITE_CHEST_PITY && !roll_chance_f(chance))
        {
            ++m_elitesWithoutChest;
            return;
        }
        m_elitesWithoutChest = 0;
    }

    uint32 const choices = std::min(uint32(BONK_OFFER_SIZE) + affixes, uint32(BONK_MAX_OFFER_SIZE));
    SpawnChest(true, mob->GetPositionX(), mob->GetPositionY(), mob->GetPositionZ(), choices);
}

bool BonkRun::IsFarFromChests(float x, float y) const
{
    Map* map = m_player->FindMap();
    if (!map)
        return true;
    for (ObjectGuid const& guid : m_chests)
        if (GameObject const* chest = map->GetGameObject(guid))
            if (chest->GetDistance2d(x, y) < BONK_CHEST_MIN_SPACING)
                return false;
    return true;
}

bool BonkRun::SpawnChestNearby()
{
    for (uint32 attempt = 0; attempt < BONK_CHEST_PLACE_ATTEMPTS; ++attempt)
    {
        float x, y, z;
        if (!FindSpawnPosition(x, y, z, BONK_CHEST_MIN_DISTANCE, BONK_CHEST_MAX_DISTANCE))
            continue;
        if (!IsFarFromChests(x, y) || !m_player->IsWithinLOS(x, y, z))
            continue;
        return SpawnChest(false, x, y, z);
    }
    return false;
}

void BonkRun::GainValor(uint32 amount)
{
    m_coins += amount;
    m_valorEarned += amount;
}

uint32 BonkRun::GetChestCost() const
{
    return uint32(m_tier.chestCost * (1.0f + m_tier.chestCostGrowth * m_chestsBought) * (1.0f + m_tier.chestCostMinuteGrowth * GetRunMinutes()) + 0.5f);
}

uint32 BonkRun::GetChestPrice() const
{
    float const haggle = std::min(GetUtility(BONK_UTILITY_HAGGLE), BONK_MAX_HAGGLE);
    return std::max(1u, uint32(GetChestCost() * (1.0f - haggle / 100.0f) + 0.5f));
}

void BonkRun::SpawnPowerup(WorldObject const* at)
{
    bool const magnetBlocked = !m_powerupObjectives.empty() || m_coopOwnXp;
    auto allowed = [magnetBlocked](BonkPowerup const& powerup)
    {
        return !magnetBlocked || powerup.effect != BONK_POWERUP_MAGNET;
    };
    std::vector<BonkPowerup> const& powerups = sBonkMgr.GetPowerups();
    uint32 totalWeight = 0;
    for (BonkPowerup const& powerup : powerups)
        if (allowed(powerup))
            totalWeight += powerup.weight;
    if (!totalWeight)
        return;

    uint32 roll = urand(1, totalWeight);
    BonkPowerup const* chosen = nullptr;
    for (BonkPowerup const& powerup : powerups)
    {
        if (!allowed(powerup))
            continue;
        if (roll <= powerup.weight)
        {
            chosen = &powerup;
            break;
        }
        roll -= powerup.weight;
    }
    if (!chosen)
        return;

    uint32 const lifetime = uint32(BONK_POWERUP_LIFETIME_SEC * (1.0f + GetGlyphValue(BONK_GLYPH_PACKRAT, 0) / 100.0f));
    if (at)
    {
        PlacePowerup(*chosen, at->GetPositionX(), at->GetPositionY(), at->GetPositionZ(), lifetime);
        return;
    }
    for (uint32 attempt = 0; attempt < 5; ++attempt)
    {
        float x, y, z;
        if (!FindSpawnPosition(x, y, z, BONK_POWERUP_MIN_DISTANCE, BONK_POWERUP_MAX_DISTANCE))
            return;
        if (!m_player->IsWithinLOS(x, y, z))
            continue;
        PlacePowerup(*chosen, x, y, z, lifetime);
        return;
    }
}

GameObject* BonkRun::PlacePowerup(BonkPowerup const& powerup, float x, float y, float z, uint32 lifetimeSeconds)
{
    MoveToSafeGround(x, y, z);
    bool const lasting = powerup.effect == BONK_POWERUP_MAGNET;
    GameObject* go = PlaceObject(powerup.entry, x, y, z, lasting ? BONK_OBJECT_LIFETIME_SEC : lifetimeSeconds);
    if (!go)
        return nullptr;
    m_powerups.push_back(go->GetObjectGuid());
    if (powerup.effect == BONK_POWERUP_VALOR)
        m_powerupGlows[go->GetObjectGuid()] = PlaceSharedGlow(go, BONK_SPELL_VALOR_POUCH_GLOW, BONK_POUCH_GLOW_SCALE);
    if (lasting)
        m_powerupObjectives[go->GetObjectGuid()] = m_objectives.Add(m_player, BONK_OBJECTIVE_CHEST, x, y, z, m_player->GetBonkPlayer()->GetLocalName(go), 0,
            BONK_MAGNET_PIN_ICON, GetString(BONK_STRING_OBJECTIVE_MAGNET));
    return go;
}

void BonkRun::ForgetPowerupObjective(ObjectGuid const& powerup)
{
    RemoveGlow(m_powerupGlows, powerup);
    auto const itr = m_powerupObjectives.find(powerup);
    if (itr == m_powerupObjectives.end())
        return;
    m_objectives.Remove(m_player, itr->second);
    m_powerupObjectives.erase(itr);
}

bool BonkRun::TakePowerupNow(uint32 entry)
{
    std::vector<BonkPowerup> const& powerups = sBonkMgr.GetPowerups();
    auto const powerup = std::find_if(powerups.begin(), powerups.end(), [entry](BonkPowerup const& p) { return p.entry == entry; });
    if (powerup == powerups.end())
        return false;
    UsePowerup(*powerup);
    return true;
}

bool BonkRun::PlacePowerupNow(uint32 entry, std::string& error)
{
    std::vector<BonkPowerup> const& powerups = sBonkMgr.GetPowerups();
    auto const powerup = std::find_if(powerups.begin(), powerups.end(), [entry](BonkPowerup const& p) { return p.entry == entry; });
    if (powerup == powerups.end())
    {
        error = GetString(BONK_STRING_THAT_POWER_UP_IS_NOT);
        return false;
    }
    float x, y, z;
    if (!FindSpawnPositionAt(m_player->GetOrientation(), BONK_POWERUP_COMMAND_DISTANCE, x, y, z) || !m_player->IsWithinLOS(x, y, z))
    {
        error = GetString(BONK_STRING_NO_OPEN_GROUND_10_YARDS);
        return false;
    }
    if (!PlacePowerup(*powerup, x, y, z, BONK_POWERUP_LIFETIME_SEC))
    {
        error = GetString(BONK_STRING_POWER_UP_COULD_NOT_BE);
        return false;
    }
    return true;
}

void BonkRun::UpdatePowerups(uint32 diff, bool spawn)
{
    m_powerupCheckTimer += diff;
    if (m_powerupCheckTimer < BONK_POWERUP_CHECK_MS)
        return;
    uint32 const elapsed = m_powerupCheckTimer;
    m_powerupCheckTimer = 0;

    Map* map = m_player->GetMap();
    std::vector<OrbCollector> const takers = GetPickupPlayers(PickupSpot::Body, false);
    struct Picked
    {
        BonkPowerup const* powerup;
        std::string name;
        OrbCollector const* taker;
    };
    std::vector<Picked> picked;
    for (auto itr = m_powerups.begin(); itr != m_powerups.end();)
    {
        GameObject* go = map->GetGameObject(*itr);
        if (!go || !go->isSpawned())
        {
            ForgetPowerupObjective(*itr);
            itr = m_powerups.erase(itr);
            continue;
        }

        auto taker = std::find_if(takers.begin(), takers.end(), [go](OrbCollector const& candidate)
        {
            return GetHeroDistance(candidate.player, candidate.x, candidate.y, candidate.z, go) <= BONK_POWERUP_PICKUP_RANGE;
        });
        if (taker == takers.end())
        {
            ++itr;
            continue;
        }

        auto powerup = std::find_if(sBonkMgr.GetPowerups().begin(), sBonkMgr.GetPowerups().end(),
            [go](BonkPowerup const& p) { return p.entry == go->GetEntry(); });
        std::string const name = taker->player->GetBonkPlayer()->GetLocalName(go);
        ForgetPowerupObjective(go->GetObjectGuid());
        go->Delete();
        itr = m_powerups.erase(itr);
        if (powerup != sBonkMgr.GetPowerups().end())
            picked.push_back({ &*powerup, name, &*taker });
    }

    for (Picked const& pick : picked)
    {
        bool const thing = pick.powerup->effect == BONK_POWERUP_MAGNET || pick.powerup->effect == BONK_POWERUP_VALOR;
        pick.taker->player->GetBonkPlayer()->Notify(thing ? BONK_STRING_YOU_PICKED_UP_A : BONK_STRING_YOU_PICKED_UP, { pick.name });
        pick.taker->run->UsePowerup(*pick.powerup);
    }

    if (!spawn || !m_map.powerupIntervalSeconds)
        return;

    m_powerupSpawnTimer -= int32(elapsed);
    if (m_powerupSpawnTimer > 0)
        return;
    m_powerupSpawnTimer += m_map.powerupIntervalSeconds * IN_MILLISECONDS;

    if (m_powerups.size() - m_powerupObjectives.size() < m_map.powerupMax)
        SpawnPowerup();
}

void BonkRun::UsePowerup(BonkPowerup const& powerup)
{
    switch (powerup.effect)
    {
        case BONK_POWERUP_MAGNET:
            PullAllCurrency();
            break;
        case BONK_POWERUP_HOLY_NOVA:
        {
            SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(powerup.spellId);
            if (!spellInfo)
                break;
            m_player->SendPlaySpellVisualKit(BONK_KIT_HOLY_NOVA);
            for (Creature* mob : GetMobsInRange(powerup.value))
            {
                BonkMobAI const* ai = dynamic_cast<BonkMobAI const*>(mob->AI());
                if (ai && ai->GetKind() == BONK_SPAWN_NORMAL && mob->IsAlive())
                    DealSpellHit(spellInfo, mob, float(mob->GetMaxHealth()) * 2.0f);
            }
            break;
        }
        case BONK_POWERUP_FROST_NOVA:
            m_player->SendPlaySpellVisualKit(BONK_KIT_FROST_NOVA);
            for (Creature* mob : GetMobsInRange(powerup.value))
                ApplyKeyword(mob, BONK_KEYWORD_FROZEN, 1);
            break;
        case BONK_POWERUP_VALOR:
            GainValor(std::max(1u, uint32(GetChestCost() * powerup.value + 0.5f)));
            if (m_player->GetBonkPlayer()->IsAddonReady())
            {
                WorldPacket data(SMSG_HOA_MESSAGE);
                HoAWriteValor(data);
                m_player->GetSession()->SendPacket(&data);
            }
            SendState();
            break;
        default:
            ApplyHeroBuff(powerup.spellId);
            break;
    }
}

void BonkRun::ApplyHeroBuff(uint32 spellId)
{
    SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(spellId);
    if (!spellInfo || !m_player->IsAlive())
        return;
    m_player->RemoveAurasDueToSpell(spellId);
    SpellAuraHolder* holder = CreateSpellAuraHolder(spellInfo, m_player, m_player, m_player);
    for (uint32 i = 0; i < MAX_EFFECT_INDEX; ++i)
        if (spellInfo->Effect[i] == SPELL_EFFECT_APPLY_AURA)
        {
            Aura* aura = CreateAura(spellInfo, SpellEffectIndex(i), nullptr, holder, m_player, m_player);
            aura->SetPositive(true);
            holder->AddAura(aura, SpellEffectIndex(i));
        }
    if (holder->IsEmptyHolder())
    {
        delete holder;
        return;
    }
    m_player->AddSpellAuraHolder(holder);
}

void BonkRun::DespawnObjects()
{
    if (Map* map = m_player->FindMap())
    {
        for (ObjectGuid const& guid : m_chests)
        {
            ForgetChestObjective(guid);
            BonkCoop::ForgetHiddenObject(guid);
            if (GameObject* chest = map->GetGameObject(guid))
                chest->Delete();
        }
        for (ObjectGuid const& guid : m_powerups)
        {
            ForgetPowerupObjective(guid);
            if (GameObject* powerup = map->GetGameObject(guid))
                powerup->Delete();
        }
        for (ShardDrop& drop : m_shardDrops)
            RemoveTicket(drop, false);
        for (GlyphDrop const& drop : m_glyphDrops)
            RemovePickup(drop.guid, drop.marker, drop.sparkle);
        for (HealDrop const& drop : m_healDrops)
            RemoveHealDrop(drop, map->GetCreature(drop.guid), false);
        for (GearDrop const& drop : m_gearDrops)
            RemovePickup(drop.guid, drop.marker, drop.swirl, drop.core);
        if (GameObject* portal = map->GetGameObject(m_portalGuid))
            portal->Delete();
    }
    DespawnVault();
    DespawnEnchanter();
    ClearDropLooks();
    m_chests.clear();
    m_chestOpenedBy.clear();
    m_chestObjectives.clear();
    m_chestGlows.clear();
    m_powerups.clear();
    m_powerupObjectives.clear();
    m_powerupGlows.clear();
    EndVoidZones();
    ClearHidden();
    m_shardDrops.clear();
    m_glyphDrops.clear();
    m_healDrops.clear();
    m_gearDrops.clear();
    m_portalGuid.Clear();
}


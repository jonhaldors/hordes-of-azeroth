#include "BonkRunInternal.h"

void BonkRun::UpdateGear()
{
    BonkGearTotals gear = m_sandboxBench ? sBonkMgr.EvaluateItems(m_sandboxBenchItems) : sBonkMgr.EvaluateGear(m_player);
    if (!m_sandboxBench)
        AddEnchantStats(gear.passives);
    bool const passivesChanged = !std::equal(std::begin(gear.passives), std::end(gear.passives), std::begin(m_gear.passives));
    m_gear = gear;

    if (passivesChanged)
        ApplyPassives();
    UpdateWornTrinkets();

    SyncGearCards();
}

uint32 BonkRun::CapEnemyHit(uint32 damage, BonkSpawnKind kind, BonkArchetype archetype) const
{
    uint32 const cap = std::max(1u, uint32(m_player->GetMaxHealth() * GetHitCapShare(kind, archetype)));
    return std::min(damage, cap);
}

uint32 BonkRun::MitigateDamage(uint32 damage)
{
    if (!damage)
        return 0;

    if (m_away || IsCardImmune() || IsIceBlocked() || IsHiddenInSmoke() || IsDivinelyShielded() || BlockWithDivineShield(damage))
        return 0;

    damage = ApplyDruidDamageTaken(ApplyPaladinDamageTaken(ApplyPriestDamageTaken(ApplyTalentDamageTaken(damage))));
    damage = uint32(damage * GetTrinketDamageTaken());
    OnTrinketHitTaken();
    m_hurt = true;
    m_lastHurtMs = m_totalMs;
    RefreshUnhitPowerAura();

    if (float const reduction = GetArmorReduction())
    {
        uint32 const before = damage;
        damage = std::max(1u, uint32(damage * (1.0f - reduction)));
        m_armorUnreported += before - damage;
    }

    m_shieldIdleMs = 0;
    uint32 const unshielded = damage;

    if (m_spellShield)
    {
        uint32 const absorbed = AbsorbSpellShield(damage);
        damage -= absorbed;
        OnPriestShieldAbsorbed(absorbed);
        if (!m_spellShield && HasBehavior(BONK_BEHAVIOR_WARD))
            m_wardBurst = true;
        if (!m_spellShield)
        {
            BreakBloodShield();
            OnShieldBroken();
        }
    }
    m_damageAbsorbed += unshielded - damage;
    damage = PreventDeath(GuardLowHealth(damage));
    if (damage && GetGlyph(BONK_GLYPH_NOMAD))
    {
        if (SpellAuraHolder* holder = m_player->AddAura(BONK_SPELL_NOMAD_AURA, ADD_AURA_NEGATIVE))
        {
            int32 const duration = int32(GetGlyphValue(BONK_GLYPH_NOMAD, 2));
            holder->SetAuraDuration(duration);
            holder->SetAuraMaxDuration(duration);
            holder->UpdateAuraDuration();
        }
    }
    if (!m_spellShield)
        m_player->RemoveAurasDueToSpell(BONK_SPELL_PLAYER_SHIELD);
    NoteHeroHit(unshielded, damage);

    m_minuteDamage += damage;
    m_damageTaken += damage;
    m_lastStrikeDamage = damage;
    m_recentHits.emplace_back(m_totalMs, damage);
    OnCardHitTaken();
    return damage;
}

uint32 BonkRun::GetNecroticStacks() const
{
    SpellAuraHolder const* holder = m_player->GetSpellAuraHolder(BONK_SPELL_NECROTIC);
    return holder ? holder->GetStackAmount() : 0;
}

void BonkRun::AddNecroticStack()
{
    uint32 const stacks = GetNecroticStacks();
    if (stacks < BONK_NECROTIC_MAX_STACKS)
        SetNecroticStacks(stacks + 1);
}

void BonkRun::SetNecroticStacks(uint32 stacks)
{
    if (stacks == GetNecroticStacks())
        return;

    if (stacks && m_player->IsAlive())
    {
        if (!m_player->HasAura(BONK_SPELL_NECROTIC))
            m_player->AddAura(BONK_SPELL_NECROTIC, ADD_AURA_NEGATIVE);
        if (SpellAuraHolder* holder = m_player->GetSpellAuraHolder(BONK_SPELL_NECROTIC))
        {
            holder->SetStackAmount(stacks);
            holder->SetAuraDuration(BONK_NECROTIC_DURATION_MS);
            holder->SetAuraMaxDuration(BONK_NECROTIC_DURATION_MS);
            holder->UpdateAuraDuration();
        }
    }
    else if (!stacks)
        m_player->RemoveAurasDueToSpell(BONK_SPELL_NECROTIC);
    m_player->GetBonkPlayer()->SendAuraPercent(BONK_SPELL_NECROTIC, stacks * BONK_NECROTIC_PER_STACK);
    if (BonkAuraEntry const* entry = sBonkAura.Get(BONK_SPELL_NECROTIC))
        m_player->GetBonkPlayer()->SendAuraText(BONK_SPELL_NECROTIC,
            sBonkAura.Format(*entry, GetLocale(), { Percent(stacks * BONK_NECROTIC_PER_STACK) }));
}

void BonkRun::UpdateNecrotic(uint32 diff)
{
    if (!GetNecroticStacks() || IsSandbox())
        return;
    m_necroticCheckMs += diff;
    if (m_necroticCheckMs < BONK_NECROTIC_CHECK_MS)
        return;
    m_necroticCheckMs = 0;

    Map* map = m_player->GetMap();
    for (ObjectGuid const& guid : GetEnemyGuids())
        if (Creature const* mob = map->GetCreature(guid))
            if (mob->IsAlive())
                if (BonkMobAI const* ai = dynamic_cast<BonkMobAI const*>(mob->AI()))
                    if (float const range = ai->GetNecroticRange())
                        if (m_player->IsWithinDistInMap(mob, range))
                            return;
    SetNecroticStacks(0);
}

uint32 BonkRun::ReduceHealing(uint32 heal) const
{
    float const cut = GetNecroticStacks() * BONK_NECROTIC_PER_STACK + GetBossWoundStacks() * m_bossWoundCut + m_bonuses.healingCut;
    if (cut <= 0.0f)
        return heal;
    float const kept = 1.0f - std::min(100.0f, cut) / 100.0f;
    return uint32(heal * kept);
}

uint32 BonkRun::GetEvolveRank() const
{
    return BONK_EVOLVE_RANK > m_bonuses.earlierEvolutions ? BONK_EVOLVE_RANK - m_bonuses.earlierEvolutions : 1;
}

void BonkRun::BringBossEarlier()
{
    uint32 const earlier = std::min(m_bonuses.earlierBossSeconds, m_map.durationSeconds / 2);
    m_map.durationSeconds -= earlier;
}

void BonkRun::OnAffixedDeath(Creature* mob)
{
    BonkMobAI const* ai = dynamic_cast<BonkMobAI const*>(mob->AI());
    if (!ai)
        return;

    if (ai->IsBolstering())
        for (Creature* other : GetMobsInRange(BONK_BOLSTER_RANGE, mob))
            if (BonkMobAI* otherAi = dynamic_cast<BonkMobAI*>(other->AI()))
                if (otherAi->GetKind() == BONK_SPAWN_NORMAL || otherAi->GetKind() == BONK_SPAWN_ELITE)
                    otherAi->Bolster();

    if (ai->IsSanguine())
    {
        Pool pool;
        pool.x = mob->GetPositionX();
        pool.y = mob->GetPositionY();
        pool.z = mob->GetPositionZ();
        pool.leftMs = BONK_SANGUINE_DURATION_MS;
        pool.marker = NextBonkAuraKey();
        SendBonkMark(m_player, GetSanguineMarkKey(pool.marker), BONK_TELEGRAPH_CIRCLE, pool.x, pool.y, pool.z, 0.0f, BONK_SANGUINE_RADIUS, 0,
            true, BONK_TELEGRAPH_STYLE_BLOOD, ObjectGuid(), "", 0, true);
        m_pools.push_back(pool);
    }
}

void BonkRun::SpawnPhaseAdds(Creature const* boss, uint32 count, uint32 elites)
{
    for (uint32 i = 0; i < count + elites; ++i)
    {
        if (m_mobs.size() >= m_tier.maxAlive)
            return;
        BonkMapCreature const* pick = PickCreature(i < count ? BONK_SPAWN_NORMAL : BONK_SPAWN_ELITE);
        if (!pick)
            continue;
        float const angle = 2.0f * M_PI_F * i / float(count + elites) + frand(-0.3f, 0.3f);
        float const distance = frand(BONK_PHASE_ADD_MIN, BONK_PHASE_ADD_MAX);
        float const x = boss->GetPositionX() + distance * std::cos(angle);
        float const y = boss->GetPositionY() + distance * std::sin(angle);
        float const z = m_player->GetMap()->GetHeight(x, y, boss->GetPositionZ() + 5.0f, true, 15.0f);
        if (z <= INVALID_HEIGHT || !boss->IsWithinLOS(x, y, z + 2.0f))
            continue;
        if (Creature* mob = SpawnMobAt(*pick, x, y, z))
        {
            if (BonkMobAI* ai = dynamic_cast<BonkMobAI*>(mob->AI()))
                ai->Arrive(false);
            mob->CastSpell(mob, BONK_SPELL_BOSS_ADD_SMOKE, true);
        }
    }
}

void BonkRun::SpawnWards(Creature const* boss, uint32 count, float healthShare, float healPercent)
{
    BonkMapCreature ward;
    ward.entry = BONK_WARD_ENTRY;
    ward.scale = BONK_WARD_SCALE;
    float const turn = frand(0.0f, 2.0f * M_PI_F);
    for (uint32 i = 0; i < count; ++i)
    {
        float const angle = turn + 2.0f * M_PI_F * i / float(count);
        float const distance = frand(BONK_WARD_MIN_DISTANCE, BONK_WARD_MAX_DISTANCE);
        float const x = boss->GetPositionX() + distance * std::cos(angle);
        float const y = boss->GetPositionY() + distance * std::sin(angle);
        float const z = m_player->GetMap()->GetHeight(x, y, boss->GetPositionZ() + 5.0f, true, 15.0f);
        if (z <= INVALID_HEIGHT || !boss->IsWithinLOS(x, y, z + 2.0f))
            continue;
        Creature* mob = SpawnMobAt(ward, x, y, z);
        if (!mob)
            continue;
        uint32 const health = std::max(1u, uint32(boss->GetMaxHealth() * healthShare));
        mob->SetModifierValue(UNIT_MOD_HEALTH, BASE_VALUE, float(health));
        mob->SetMaxHealth(health);
        mob->SetHealth(health);
        if (BonkMobAI* ai = dynamic_cast<BonkMobAI*>(mob->AI()))
            ai->SetWard(boss->GetObjectGuid(), healPercent);
        mob->CastSpell(mob, BONK_SPELL_BOSS_ADD_SMOKE, true);
    }
}

void BonkRun::StartVoidZone(BonkEnemyHit const& hit, float x, float y, float z, float radius, uint32 durationMs)
{
    if (m_state != STATE_RUNNING || m_paused)
        return;
    bool const vortex = hit.impactKit == BONK_KIT_SAND_VORTEX && sSpellMgr.GetSpellEntry(BONK_SPELL_SAND_VORTEX_LOOK);
    if (vortex)
        durationMs = BONK_SAND_VORTEX_LIFE_MS;
    VoidZone zone;
    zone.hit = hit;
    zone.x = x;
    zone.y = y;
    zone.z = z;
    zone.radius = radius;
    zone.leftMs = durationMs;
    zone.tickMs = 0;
    zone.markKey = NextBonkAuraKey();
    SendBonkMark(m_player, "zone" + std::to_string(zone.markKey), BONK_TELEGRAPH_CIRCLE, x, y, z, 0.0f, radius, 0, true,
        BONK_TELEGRAPH_STYLE_DANGER, ObjectGuid(), "", 0, true);
    if (vortex)
    {
        zone.vortexKey = NextBonkAuraKey();
        SendBonkAuraAt(m_player, zone.vortexKey, BONK_SPELL_SAND_VORTEX_LOOK, x, y, z);
    }
    m_voidZones.push_back(zone);
}

void BonkRun::EndVoidZone(VoidZone const& zone)
{
    if (zone.markKey)
        SendBonkUnmark(m_player, "zone" + std::to_string(zone.markKey));
    if (zone.vortexKey)
        SendBonkAuraGone(m_player, zone.vortexKey);
}

void BonkRun::EndVoidZones()
{
    for (VoidZone const& zone : m_voidZones)
        EndVoidZone(zone);
    m_voidZones.clear();
}

void BonkRun::MarkHero(BonkEnemyHit const& burst, BonkEnemyHit const& pool, float radius, uint32 followMs, uint32 warnMs, uint32 poolMs)
{
    if (m_state != STATE_RUNNING || m_paused || IsHeroMarked() || !m_player->IsAlive())
        return;
    m_heroMark.burst = burst;
    m_heroMark.pool = pool;
    m_heroMark.radius = radius;
    m_heroMark.leftMs = std::max(1u, followMs);
    m_heroMark.warnMs = warnMs;
    m_heroMark.poolMs = poolMs;
    ShowHeroRing(BonkHeroRing::MarkOutline, radius);
    ShowHeroRing(BonkHeroRing::MarkFill, radius, m_heroMark.leftMs);
}

void BonkRun::UpdateHeroMark(uint32 diff)
{
    if (!IsHeroMarked())
        return;
    if (m_heroMark.leftMs > diff)
    {
        m_heroMark.leftMs -= diff;
        return;
    }
    m_heroMark.leftMs = 0;
    HideHeroMarkRings();
    if (!m_player->IsAlive())
        return;

    float x, y, z;
    GetHeroPositionNow(m_player, x, y, z);
    HeroMark const mark = m_heroMark;
    AddTelegraph(BONK_TELEGRAPH_CIRCLE, x, y, z, 0.0f, mark.radius, mark.warnMs, [this, mark, x, y, z]()
    {
        Erupt(mark.burst, x, y, z, mark.radius);
        if (mark.poolMs)
            StartVoidZone(mark.pool, x, y, z, mark.radius, mark.poolMs);
    });
}

void BonkRun::HideHeroMarkRings()
{
    HideHeroRing(BonkHeroRing::MarkOutline);
    HideHeroRing(BonkHeroRing::MarkFill);
}

uint32 BonkRun::GetBossWoundStacks() const
{
    SpellAuraHolder const* holder = m_player->GetSpellAuraHolder(BONK_SPELL_WOUNDS);
    return holder ? holder->GetStackAmount() : 0;
}

void BonkRun::AddBossWound(uint32 maxStacks, float cutPercent, uint32 durationMs)
{
    if (!maxStacks || cutPercent <= 0.0f || !m_player->IsAlive())
        return;
    m_bossWoundCut = cutPercent;
    SetBossWoundStacks(std::min(maxStacks, GetBossWoundStacks() + 1));
    if (SpellAuraHolder* holder = m_player->GetSpellAuraHolder(BONK_SPELL_WOUNDS))
    {
        holder->SetAuraDuration(int32(durationMs));
        holder->SetAuraMaxDuration(int32(durationMs));
        holder->UpdateAuraDuration();
    }
}

void BonkRun::SetBossWoundStacks(uint32 stacks)
{
    if (stacks == GetBossWoundStacks())
        return;
    if (!stacks)
        m_player->RemoveAurasDueToSpell(BONK_SPELL_WOUNDS);
    else if (SpellAuraHolder* holder = m_player->AddAura(BONK_SPELL_WOUNDS, ADD_AURA_NEGATIVE))
        holder->SetStackAmount(stacks);
    m_player->GetBonkPlayer()->SendAuraPercent(BONK_SPELL_WOUNDS, stacks * m_bossWoundCut);
    if (BonkAuraEntry const* entry = sBonkAura.Get(BONK_SPELL_WOUNDS))
        m_player->GetBonkPlayer()->SendAuraText(BONK_SPELL_WOUNDS,
            sBonkAura.Format(*entry, GetLocale(), { Percent(stacks * m_bossWoundCut) }));
}

void BonkRun::ResendAuraTexts() const
{
    BonkPlayer* bonk = m_player->GetBonkPlayer();

    SendShieldState();

    if (BonkAuraEntry const* entry = sBonkAura.Get(BONK_SPELL_WOUNDS))
        if (uint32 const stacks = GetBossWoundStacks())
            bonk->SendAuraText(BONK_SPELL_WOUNDS,
                sBonkAura.Format(*entry, GetLocale(), { Percent(stacks * m_bossWoundCut) }));

    bonk->SendDeterminationText();

    struct CardAura
    {
        BonkCardEffect effect;
        uint32 spell;
    };
    CardAura const cardAuras[] =
    {
        { BONK_CARD_POWER_SURGE, BONK_SPELL_DARKMOON_SURGE },
        { BONK_CARD_HASTE_BURST, BONK_SPELL_CARD_HASTE },
        { BONK_CARD_SWIFTNESS,  BONK_SPELL_CARD_SWIFT },
        { BONK_CARD_HIT_IMMUNE, BONK_SPELL_CARD_IMMUNE },
        { BONK_CARD_THORNS,     BONK_SPELL_CARD_THORNS },
        { BONK_CARD_KILL_POWER, BONK_SPELL_KILL_POWER_AURA },
        { BONK_CARD_UNHIT_POWER, BONK_SPELL_UNHIT_POWER_AURA },
        { BONK_CARD_BANDAGE,    BONK_SPELL_BANDAGE_AURA },
        { BONK_CARD_CAMPFIRE,   BONK_SPELL_CAMPFIRE_AURA },
    };
    for (CardAura const& aura : cardAuras)
        if (BonkCard const* card = m_cardByEffect[aura.effect])
            if (m_player->HasAura(aura.spell))
                SendCardAuraText(aura.spell, *card);
}

void BonkRun::UpdateBossWounds(uint32)
{
}

void BonkRun::ClearBossPressure()
{
    m_heroMark.leftMs = 0;
    HideHeroMarkRings();
    SetBossWoundStacks(0);
}

void BonkRun::UpdateVoidZones(uint32 diff)
{
    for (auto itr = m_voidZones.begin(); itr != m_voidZones.end();)
    {
        itr->tickMs += diff;
        if (itr->tickMs >= IN_MILLISECONDS)
        {
            itr->tickMs -= IN_MILLISECONDS;
            Erupt(itr->hit, itr->x, itr->y, itr->z, itr->radius, false, false);
        }
        itr->vortexMs -= int32(diff);
        uint32 const burstKit = itr->hit.impactKit ? itr->hit.impactKit : BONK_KIT_FIRE_BURST;
        uint32 const burstMs = GetPoolBurstMs(burstKit);
        if (!itr->vortexKey && itr->vortexMs <= 0 && itr->leftMs >= burstMs)
        {
            itr->vortexMs += BONK_VOID_LOOK_EVERY_MS;
            ShowKitOnStandIn(burstKit, itr->x, itr->y, itr->z, burstMs);
        }
        itr->leftMs = itr->leftMs > diff ? itr->leftMs - diff : 0;
        if (itr->leftMs)
        {
            ++itr;
            continue;
        }
        EndVoidZone(*itr);
        itr = m_voidZones.erase(itr);
    }
}

void BonkRun::UpdatePools(uint32 diff)
{
    if (m_pools.empty())
        return;

    m_poolTimer += diff;
    bool const tick = m_poolTimer >= IN_MILLISECONDS;
    if (tick)
        m_poolTimer -= IN_MILLISECONDS;

    Map* map = m_player->GetMap();
    for (auto itr = m_pools.begin(); itr != m_pools.end();)
    {
        if (tick)
            for (ObjectGuid const& guid : GetEnemyGuids())
                if (Creature* mob = map->GetCreature(guid))
                    if (mob->IsAlive() && mob->GetHealth() < mob->GetMaxHealth() &&
                        mob->GetDistance2d(itr->x, itr->y) <= BONK_SANGUINE_RADIUS)
                        mob->ModifyHealth(int32(std::max(1.0f, mob->GetMaxHealth() * BONK_SANGUINE_HEAL)));

        itr->leftMs = itr->leftMs > diff ? itr->leftMs - diff : 0;
        if (itr->leftMs)
        {
            ++itr;
            continue;
        }
        SendBonkUnmark(m_player, GetSanguineMarkKey(itr->marker));
        itr = m_pools.erase(itr);
    }
}

void BonkRun::DespawnPools()
{
    for (Pool const& pool : m_pools)
        SendBonkUnmark(m_player, GetSanguineMarkKey(pool.marker));
    m_pools.clear();
}

uint32 BonkRun::GetMaxShield() const
{
    float const shield = GetPassiveTotal(BONK_PASSIVE_SHIELD);
    return shield > 0.0f ? std::min(GetSpellShieldCap(), uint32(m_player->GetMaxHealth() * shield / 100.0f)) : 0;
}

BonkSupportSource BonkRun::ShieldStatSupport() const
{
    BonkSupportSource const passive = PassiveSupport(BONK_PASSIVE_SHIELD);
    return passive.name.empty() ? CapstoneSupport(BONK_CAPSTONE_JUGGERNAUT) : passive;
}

void BonkRun::RefillShield(uint32 target)
{
    if (m_spellShield >= target)
        return;
    SupportScope scope(*this, ShieldStatSupport());
    AddSpellShield(target - m_spellShield);
}

void BonkRun::SendShieldState() const
{
    uint32 const total = m_spellShield;
    uint32 const max = GetMaxShield();
    BonkPlayer* bonk = m_player->GetBonkPlayer();
    bonk->SendAuraValue(BONK_SPELL_PLAYER_SHIELD, total, max);
    if (total)
        if (BonkAuraEntry const* entry = sBonkAura.Get(BONK_SPELL_PLAYER_SHIELD))
            bonk->SendAuraText(BONK_SPELL_PLAYER_SHIELD,
                sBonkAura.Format(*entry, GetLocale(), { std::to_string(total) }));
}

void BonkRun::UpdateShield(uint32 diff)
{
    uint32 const max = GetMaxShield();
    if (m_spellShield < max)
    {
        m_shieldIdleMs += diff;
        if (m_shieldIdleMs >= BONK_SHIELD_REGEN_DELAY_MS)
            RefillShield(max);
    }
    RechargeJuggernautShield(diff, max);

    uint32 const total = m_spellShield;
    bool forceSend = false;
    if (m_player->IsAlive())
    {
        bool const shown = m_player->HasAura(BONK_SPELL_PLAYER_SHIELD);
        if (total && !shown)
        {
            m_player->AddAura(BONK_SPELL_PLAYER_SHIELD, ADD_AURA_PERMANENT);
            forceSend = true;
        }
        else if (!total && shown)
            m_player->RemoveAurasDueToSpell(BONK_SPELL_PLAYER_SHIELD);
    }

    m_shieldSendTimer += diff;
    if ((forceSend || total != m_shieldSent || max != m_shieldMaxSent) && m_shieldSendTimer >= BONK_SHIELD_SEND_MS)
    {
        m_shieldSendTimer = 0;
        m_shieldSent = total;
        m_shieldMaxSent = max;
        SendShieldState();
    }
}

BonkRun* BonkRun::FromAttack(SpellCaster const* attacker, Unit const* victim)
{
    Unit const* unit = attacker ? attacker->ToUnit() : nullptr;
    if (!unit || !victim || !victim->IsCreature())
        return nullptr;

    Player const* player = unit->GetCharmerOrOwnerPlayerOrPlayerItself();
    if (!player)
        return nullptr;

    BonkMobAI const* ai = dynamic_cast<BonkMobAI const*>(victim->AI());
    if (!ai)
        return nullptr;
    if (ai->GetOwnerGuid() != player->GetObjectGuid() && !(player->GetGroup() && player->GetGroup()->IsMember(ai->GetOwnerGuid())))
        return nullptr;
    return player->GetBonkPlayer()->GetRun();
}

float BonkRun::GetHealthScale(Unit const* victim)
{
    BonkMobAI const* ai = victim && victim->IsCreature() ? dynamic_cast<BonkMobAI const*>(victim->AI()) : nullptr;
    return ai ? 1.0f / ai->GetHealthOverflow() : 1.0f;
}

uint64 BonkRun::GetTrueAmount(Unit const* victim, uint32 amount)
{
    BonkMobAI const* ai = victim && victim->IsCreature() ? dynamic_cast<BonkMobAI const*>(victim->AI()) : nullptr;
    return ai ? ai->GetTrueHealth(amount) : amount;
}

uint32 BonkRun::ToDamage(double damage)
{
    return damage <= 0.0 ? 0 : uint32(std::min(damage, double(MaxHitDamage)));
}

uint32 BonkRun::GetMissileDelay(SpellCaster const* caster, Unit const* target, float speed)
{
    if (speed <= 0.0f || !caster || !FromAttack(caster, target))
        return 0;

    float x = caster->GetPositionX(), y = caster->GetPositionY(), z = caster->GetPositionZ();
    if (Player const* hero = caster->ToPlayer())
        GetHeroPositionNow(hero, x, y, z);
    float const t = target->GetDistance3dToCenter(x, y, z) / speed;
    return std::max(1u, uint32(t * IN_MILLISECONDS));
}

float BonkRun::GetCritChance(SpellEntry const* spell, Unit const* victim, Unit const* attacker) const
{
    float const chance = GetPaladinCritChance(spell, GetRogueCritChance(spell,
        BONK_BASE_CRIT + GetPassiveTotal(BONK_PASSIVE_CRIT) + GetTalentCritChance(victim, attacker) + GetDeepWoundsCritChance(victim)));
    return IsAlwaysCrit(spell, victim) ? 100.0f + chance : chance;
}

bool BonkRun::IsAlwaysCrit(SpellEntry const* spell, Unit const* victim) const
{
    if (IsReckless() || IsFrostSpellOnFrozen(spell, victim) || IsWeaponMasterStrike(spell) || IsLavaBurstOnBurning(spell, victim) ||
        IsFreshMeat(spell, victim))
        return true;
    if (!spell)
        return false;
    return std::any_of(m_weapons.begin(), m_weapons.end(), [spell](OwnedWeapon const& owned)
    {
        return owned.weapon.spellId == spell->Id && (owned.weapon.HasFlag(BONK_WEAPON_FLAG_ALWAYS_CRIT) || owned.forcedCrit);
    });
}

float BonkRun::GetCritBonus(bool weaponAttack, Unit const* victim) const
{
    float bonus = (weaponAttack ? 1.0f : 0.5f) + std::max(0.0f, GetPassiveTotal(BONK_PASSIVE_CRIT_DAMAGE)) / 100.0f;
    if (victim && (IsFrozen(victim) || (victim->HasAuraType(SPELL_AURA_MOD_ROOT) && HasBehavior(BONK_BEHAVIOR_FREEZE))))
        bonus += BONK_FROZEN_CRIT_BONUS + m_mastery.Special(BONK_SPECIAL_WINTERS_CHILL) / 100.0f;
    if (IsEnraged())
        bonus += m_mastery.Special(BONK_SPECIAL_RECKLESS_ABANDON) * m_mastery.EnrageBoost() / 100.0f;
    return bonus;
}

float BonkRun::RollCritMultiplier(bool weaponAttack, Unit const* victim, SpellEntry const* spell, Unit const* attacker) const
{
    float const bonus = GetCritBonus(weaponAttack, victim);
    float multiplier = (1.0f + bonus) * (1.0f + GetCapstoneCritDamage(spell));
    ++m_crits;

    float const overcrit = GetCritChance(spell, victim, attacker == m_player ? nullptr : attacker) - 100.0f;
    if (overcrit > 0.0f && roll_chance_f(overcrit))
        multiplier *= 1.0f + bonus;
    return multiplier;
}

float BonkRun::GetMinionScale(Unit const* attacker) const
{
    return IsSummon(attacker) ? 1.0f + GetPackPowerShare() : 1.0f;
}

float BonkRun::GetDamageMultiplier(SpellEntry const* spell, Unit const* victim, float minionScale, float extraPower) const
{
    float percent = (GetRunPower() + GetBuffPower() + GetCardPower(victim) + GetGlyphPower() + extraPower +
        GetCastChargePower(spell, victim));
    float const mark = GetKeywordDamageMultiplier(spell, victim) * GetMageDamageMultiplier(victim) *
        GetShamanDamageMultiplier(spell, victim) * GetPriestDamageMultiplier(victim) * GetRogueDamageMultiplier(victim) *
        GetPaladinDamageMultiplier(victim) * GetHunterDamageMultiplier(spell, victim) * GetMageSpellDamageMultiplier(spell, victim) *
        GetTrinketDamageMultiplier();
    if (!spell)
        return std::max(0.0f, 1.0f + percent / 100.0f) * GetGearDamageScale() * mark * GetCapstoneDamageMultiplier(false, victim) * minionScale;

    uint32 const school = spell->GetSpellSchoolMask();
    auto root = m_spellRoots.find(spell->Id);
    if (root != m_spellRoots.end())
    {
        auto bonus = m_mastery.spellDamage.find(root->second);
        if (bonus != m_mastery.spellDamage.end())
            percent += bonus->second;
        percent += GetSpecDamage(root->second) + GetTormentBonus(root->second, victim);
        if (root->second == BONK_WEAPON_AIMED_SHOT && victim && m_mastery.Special(BONK_SPECIAL_KILL_SHOT) > 0.0f &&
            victim->GetHealthPercent() < m_mastery.Special(BONK_SPECIAL_KILL_SHOT))
            if (BonkMobAI const* ai = dynamic_cast<BonkMobAI const*>(victim->ToCreature() ? victim->ToCreature()->AI() : nullptr))
                if (ai->GetKind() == BONK_SPAWN_NORMAL)
                    percent += BONK_KILL_SHOT_PERCENT;
    }
    percent += GetTalentDamagePercent();
    for (auto const& bonus : m_mastery.schoolDamage)
        if (bonus.first & school)
            percent += bonus.second;

    if (victim)
    {
        if (m_mastery.shatter > 0.0f && (victim->HasAuraType(SPELL_AURA_MOD_DECREASE_SPEED) || victim->HasAuraType(SPELL_AURA_MOD_ROOT)))
            percent += m_mastery.shatter;

        float const health = victim->GetHealthPercent();
        if (health > BONK_MASTERY_OPENER_HEALTH)
            for (auto const& bonus : m_mastery.opener)
                if (!bonus.first || (bonus.first & school))
                    percent += bonus.second;
        if (health < BONK_MASTERY_EXECUTE_HEALTH)
            for (auto const& bonus : m_mastery.execute)
                if (!bonus.first || (bonus.first & school))
                    percent += bonus.second;
    }

    float multiplier = std::max(0.0f, 1.0f + percent / 100.0f) * GetGearDamageScale() * mark * GetCapstoneDamageMultiplier(true, victim) * minionScale *
        GetGlyphDamageMultiplier(spell);

    if (victim)
        for (OwnedWeapon const& owned : m_weapons)
            if (owned.weapon.behavior == BONK_BEHAVIOR_EXECUTE && owned.weapon.spellId == spell->Id &&
                victim->GetHealthPercent() < owned.weapon.behaviorValue)
                multiplier *= owned.weapon.altDamage + m_mastery.Special(BONK_SPECIAL_ANNIHILATOR);
    return multiplier;
}

uint32 BonkRun::GetRootWeapon(BonkWeapon const& weapon) const
{
    auto itr = m_spellRoots.find(weapon.spellId);
    return itr != m_spellRoots.end() ? itr->second : weapon.id;
}

void BonkRun::SoulSiphon(uint32 killingSpell)
{
    if (m_mastery.soulSiphon.empty() || !killingSpell || !m_player->IsAlive())
        return;
    SpellEntry const* spell = sSpellMgr.GetSpellEntry(killingSpell);
    if (!spell)
        return;

    float percent = 0.0f;
    for (auto const& siphon : m_mastery.soulSiphon)
        if (siphon.first & spell->GetSpellSchoolMask())
            percent += siphon.second;

    uint32 const now = WorldTimer::getMSTime();
    if (WorldTimer::getMSTimeDiff(m_siphonWindow, now) >= IN_MILLISECONDS)
    {
        m_siphonWindow = now;
        m_siphonHealed = 0.0f;
    }
    percent = std::min(percent, BONK_MASTERY_SIPHON_CAP - m_siphonHealed);
    if (percent <= 0.0f)
        return;
    m_siphonHealed += percent;
    SupportScope scope(*this, TalentSupport(BONK_MASTERY_SOUL_SIPHON));
    m_player->ModifyHealth(int32(ReduceHealing(uint32(std::max(1.0f, m_player->GetMaxHealth() * percent / 100.0f)))));
}

void BonkRun::AwardMastery()
{
    if (m_masteryAwarded || m_sandbox)
        return;
    m_masteryAwarded = true;
    m_player->GetBonkPlayer()->AddMasteryXp(m_rewardMs / (MINUTE * IN_MILLISECONDS) * m_tier.masteryXpMinute + m_masteryXp);
}

uint32 BonkRun::PreventDeath(uint32 damage)
{
    if (!damage || damage < m_player->GetHealth() || !SaveFromDeath())
        return damage;
    return 0;
}

bool BonkRun::SaveFromDeath()
{
    if (m_sandbox || !m_player->IsAlive() || (m_state != STATE_RUNNING && m_state != STATE_PORTAL))
        return false;
    if (m_state == STATE_RUNNING && IsDivineShieldReady())
        Revive(false, GetGlyph(BONK_GLYPH_DIVINE_SHIELD), true);
    else if (m_revives)
        Revive(false, nullptr, true);
    else if (m_soulstones && m_state == STATE_RUNNING)
        Revive(true, nullptr, true);
    else
        return false;
    return true;
}

void BonkRun::Revive(bool soulstone, BonkGlyph const* glyph, bool stillAlive)
{
    if (glyph)
        m_divineShieldStage = m_stage;
    else if (soulstone)
        --m_soulstones;
    else
        --m_revives;
    BonkCard const* stone = m_cardByEffect[BONK_CARD_SOULSTONE];
    float const restore = glyph ? glyph->values[0] / 100.0f : soulstone && stone ? stone->values[0] / 100.0f : 0.5f;
    if (stillAlive)
        m_player->SetHealth(std::max(m_player->GetHealth(), std::max(1u, uint32(m_player->GetMaxHealth() * restore))));
    else
    {
        m_player->ResurrectPlayer(restore);
        m_player->SpawnCorpseBones();
    }
    m_player->CastSpell(m_player, BONK_SPELL_REVIVE_SHIELD, true);
    SmiteAroundRevive();

    if (glyph)
        m_player->GetBonkPlayer()->Notify(BONK_STRING_GLYPH_OF_DIVINE_SHIELD_SAVED, { DescribeDivineShieldRecharge(*glyph) });
    else if (soulstone)
        m_player->GetBonkPlayer()->Notify(!m_soulstones ? BONK_STRING_SOULSTONE_SAVED_YOU : m_soulstones == 1 ? BONK_STRING_SOULSTONE_SAVED_YOU_CHARGE_LEFT :
            BONK_STRING_SOULSTONE_SAVED_YOU_CHARGES_LEFT, { std::to_string(m_soulstones) });
    else
        m_player->GetBonkPlayer()->Notify(!m_revives ? BONK_STRING_YOU_GOT_BACK_UP : m_revives == 1 ? BONK_STRING_YOU_GOT_BACK_UP_REVIVE_LEFT :
            BONK_STRING_YOU_GOT_BACK_UP_REVIVES_LEFT, { std::to_string(m_revives) });
    SendState();
}

void BonkRun::SmiteAroundRevive()
{
    m_player->SendPlaySpellVisualKit(BONK_KIT_HOLY_NOVA);
    SpellEntry const* nova = sSpellMgr.GetSpellEntry(BONK_SPELL_REVIVE_NOVA);
    if (!nova)
        return;

    std::vector<Creature*> smitten;
    Map* map = m_player->GetMap();
    for (ObjectGuid const& guid : GetEnemyGuids())
        if (Creature* mob = map->GetCreature(guid))
            if (mob->IsAlive() && m_player->IsWithinDistInMap(mob, BONK_REVIVE_CLEAR_RADIUS))
                if (BonkMobAI* ai = dynamic_cast<BonkMobAI*>(mob->AI()))
                    if (ai->GetKind() == BONK_SPAWN_NORMAL)
                        smitten.push_back(mob);

    for (Creature* mob : smitten)
    {
        mob->SendPlaySpellVisualKit(BONK_KIT_REVIVE_SMITE);
        DealSpellHit(nova, mob, GetTrueAmount(mob, mob->GetMaxHealth()) * BONK_REVIVE_OVERKILL);
    }
}


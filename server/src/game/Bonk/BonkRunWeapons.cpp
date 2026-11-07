#include "BonkRunInternal.h"

float BonkRun::GetWeaponDamage(OwnedWeapon const& owned) const
{
    float const bonus = owned.damageBonus + GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_PET_DAMAGE);
    return GetMobHealth(GetMobLevel()) * owned.weapon.damageFraction * (1.0f + bonus / 100.0f) * GetDruidFormScale(owned);
}

float BonkRun::GetSpellUpgrade(OwnedWeapon const& owned, BonkSpellUpgrade upgrade) const
{
    if (upgrade == BONK_SPELL_UPGRADE_NONE || upgrade >= MAX_BONK_SPELL_UPGRADE || owned.weapon.GetUpgradeStep(upgrade) <= 0.0f)
        return 0.0f;
    float const cap = BONK_SPELL_UPGRADE_CAP[upgrade];
    return cap > 0.0f ? std::min(owned.upgrades[upgrade], cap) : owned.upgrades[upgrade];
}

uint32 BonkRun::GetSpellCount(OwnedWeapon const& owned) const
{
    uint32 const echoes = uint32(GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_ECHO));
    bool const aoe = owned.weapon.HasFlag(BONK_WEAPON_FLAG_AOE);
    if (aoe && !owned.weapon.HasFlag(BONK_WEAPON_FLAG_TOTEM))
        return echoes;
    return uint32(GetStat(BONK_PASSIVE_AMOUNT) + GetGlyphValue(BONK_GLYPH_MULTI_SHOT, 0)) + (aoe ? echoes : 0);
}

float BonkRun::GetWeaponDurationScale(OwnedWeapon const& owned) const
{
    return std::max(0.1f, 1.0f + (GetPassiveTotal(BONK_PASSIVE_DURATION) + GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_DURATION) +
        GetTrapTalentDuration(owned)) / 100.0f);
}

float BonkRun::GetWeaponHasteRate(OwnedWeapon const& owned) const
{
    return 1.0f + (CurveHaste(GetRawWeaponHaste(owned)) + GetBurstHaste()) / 100.0f;
}

uint32 BonkRun::GetWeaponCooldown(OwnedWeapon const& owned) const
{
    float mastery = 0.0f;
    auto itr = m_mastery.spellCooldown.find(GetRootWeapon(owned.weapon));
    if (itr != m_mastery.spellCooldown.end())
        mastery = itr->second;
    float const rate = 1.0f + (CurveHaste(GetRawWeaponHaste(owned) + mastery) + GetBurstHaste()) / 100.0f;
    float const steady = IsSteadyAiming(owned) ? BONK_STEADY_RATE : 1.0f;
    float const trigger = 1.0f - GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_TRIGGER_COOLDOWN) / 100.0f;
    return std::max(200u, uint32(owned.weapon.cooldownMs * trigger / (rate * steady)));
}

void BonkRun::UpdateWeapons(uint32 diff)
{
    uint32 index = 0;
    for (auto& owned : m_weapons)
    {
        ++index;
        owned.timer -= int32(diff);
        if (owned.timer <= 0)
        {
            SupportScope scope(*this, WeaponSupport(owned));
            FireWeapon(owned);
            if (m_state == STATE_RUNNING && HasCard(BONK_CARD_ECHO) && roll_chance_f(GetCardChance(BONK_CARD_ECHO)))
            {
                int32 const timer = owned.timer;
                FireWeapon(owned);
                owned.timer = timer;
            }
            NoteWeaponFired(owned);
        }
        if (owned.pieResync)
        {
            owned.pieResync = false;
            SendCooldownPie(index, owned);
        }

        if (m_state != STATE_RUNNING)
            return;
    }
}

float BonkRun::GetStrikeRange(OwnedWeapon const& owned) const
{
    return owned.weapon.range * (owned.weapon.IsMeleeStrike() ? GetWeaponArea(owned) : 1.0f);
}

float BonkRun::GetWeaponArea(OwnedWeapon const& owned) const
{
    if (owned.weapon.HasFlag(BONK_WEAPON_FLAG_AOE))
        return std::max(0.1f, 1.0f + CurveStat(GetPassiveTotal(BONK_PASSIVE_AREA) + GetTalentReach(owned), BONK_MAX_AREA) / 100.0f);
    return 1.0f + CurveStat(GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_REACH) + GetTalentReach(owned), BONK_MAX_AREA) / 100.0f;
}

float BonkRun::GetWeaponRadius(OwnedWeapon const& owned) const
{
    return owned.weapon.radius * GetWeaponArea(owned);
}

uint32 BonkRun::GetWeaponTargets(OwnedWeapon const& owned) const
{
    uint32 mastery = 0;
    auto itr = m_mastery.spellTargets.find(GetRootWeapon(owned.weapon));
    if (itr != m_mastery.spellTargets.end())
        mastery = itr->second;
    return owned.weapon.baseTargets + GetSpellCount(owned) + mastery + uint32(GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_TARGETS));
}

bool BonkRun::HasLingeringGround(BonkWeapon const& weapon, SpellEntry const* spellInfo)
{
    return weapon.damageEffectIndex >= 0 && weapon.tickEffectIndex >= 0 && weapon.behavior != BONK_BEHAVIOR_TRAP &&
        spellInfo->Effect[weapon.tickEffectIndex] == SPELL_EFFECT_PERSISTENT_AREA_AURA;
}

void BonkRun::GetBasePoints(OwnedWeapon const& owned, SpellEntry const* spellInfo, float damageShare, optional<int32>* basePoints) const
{
    BonkWeapon const& weapon = owned.weapon;
    float const damage = GetWeaponDamage(owned) * damageShare;

    if (spellInfo->Id != weapon.spellId)
    {
        int32 const index = FindDamageEffectOf(spellInfo);
        if (index >= 0)
            basePoints[index] = std::max(1, int32(damage));
        return;
    }

    if (weapon.damageEffectIndex >= 0)
    {
        float share = 1.0f;
        if (weapon.tickMs && spellInfo->EffectApplyAuraName[weapon.damageEffectIndex] == SPELL_AURA_PERIODIC_DAMAGE)
            share = weapon.tickMs / float(IN_MILLISECONDS);
        basePoints[weapon.damageEffectIndex] = std::max(1, int32(damage * share));
    }

    if (weapon.tickEffectIndex >= 0)
    {
        float share = 1.0f;
        if (spellInfo->Effect[weapon.tickEffectIndex] == SPELL_EFFECT_APPLY_AURA ||
            spellInfo->Effect[weapon.tickEffectIndex] == SPELL_EFFECT_PERSISTENT_AREA_AURA)
        {
            int32 const duration = m_player->GetBonkPlayer()->AdjustDuration(weapon.spellId, spellInfo->GetDuration());
            uint32 const amplitude = weapon.tickMs ? weapon.tickMs : spellInfo->EffectAmplitude[weapon.tickEffectIndex];
            if (duration > 0 && amplitude)
                share = std::min(1.0f, float(amplitude) / duration);
        }
        basePoints[weapon.tickEffectIndex] = std::max(1, int32(damage * share));
    }

    if (weapon.IsWeaken())
        for (uint32 i = 0; i < MAX_EFFECT_INDEX; ++i)
            if (spellInfo->EffectApplyAuraName[i] == SPELL_AURA_MOD_MELEE_HASTE)
                basePoints[i] = -int32(weapon.behaviorValue);
}

void BonkRun::StrikeWith(OwnedWeapon& owned, SpellEntry const* spellInfo, Creature* target, float damageShare, bool followUp, Creature* source)
{
    ++m_secondHits;
    BonkWeapon const& weapon = owned.weapon;
    SpellEntry const* const shotInfo = spellInfo;
    float const shotShare = damageShare;

    if (!followUp && shotInfo->speed > 0.0f && !weapon.HasFlag(BONK_WEAPON_FLAG_AOE))
        ++m_projectilesUnreported;

    if (CanKill(weapon, target))
    {
        if (weapon.HasFlag(BONK_WEAPON_FLAG_KILL_WITH_ALT) && weapon.altSpellId)
            if (SpellEntry const* killInfo = sSpellMgr.GetSpellEntry(weapon.altSpellId))
                spellInfo = killInfo;
        damageShare = std::max(damageShare, 2.0f * target->GetHealth() / std::max(1.0f, GetWeaponDamage(owned)));
        owned.killed = true;
    }
    if (weapon.IsShieldSlam())
        damageShare *= GetShieldSlamMultiplier(owned);
    if (weapon.behavior == BONK_BEHAVIOR_VENGEANCE)
        damageShare *= m_vengeanceShare;
    if (weapon.behavior == BONK_BEHAVIOR_BLOODTHIRST && IsEnraged())
        damageShare *= BONK_BLOODTHIRST_ENRAGED;

    optional<int32> basePoints[MAX_EFFECT_INDEX];
    GetBasePoints(owned, spellInfo, damageShare, basePoints);
    if (weapon.weaponDamage)
        m_player->GetBonkPlayer()->TweakSpell(weapon.spellId).weaponDamage = std::max(1, int32(GetWeaponDamage(owned) * damageShare));

    if (weapon.HasFlag(BONK_WEAPON_FLAG_LOOK_ONLY))
        ShowStrikeOn(source ? static_cast<Unit*>(source) : m_player, spellInfo, target);
    else if (source)
        source->CastCustomSpell(target, spellInfo, basePoints[0], basePoints[1], basePoints[2], true, nullptr, nullptr, m_player->GetObjectGuid());
    else
    {
        m_player->CastCustomSpell(target, spellInfo, basePoints[0], basePoints[1], basePoints[2], true);
        // The stock Bloodthirst heal buff (23881) shows a meaningless "heals for 0" aura; strip it.
        if (spellInfo->Id == 23881)
            m_player->RemoveAurasDueToSpell(23881);
        if (uint32 const kit = GetCastAnimationKit(spellInfo->Id))
        {
            uint32 const animationNow = WorldTimer::getMSTime();
            if (WorldTimer::getMSTimeDiff(m_castAnimationMs, animationNow) >= BONK_CAST_ANIMATION_GAP_MS)
            {
                m_castAnimationMs = animationNow;
                m_player->SendPlaySpellVisualKit(kit);
            }
        }
    }

    PendingKeyword keyword;
    if (weapon.IsKeywordOnly() && GetWeaponKeyword(owned, keyword))
        ApplyKeyword(target, keyword.keyword, keyword.stacks, keyword.durationMs, keyword.damageScale, keyword.spellId);

    if (followUp)
        return;

    QueueFlareSplit(owned, shotInfo, target, shotShare, source ? static_cast<SpellCaster const*>(source) : m_player);

    uint32 const now = WorldTimer::getMSTime();
    if (weapon.behavior == BONK_BEHAVIOR_SPREAD)
    {
        int32 const duration = m_player->GetBonkPlayer()->AdjustDuration(weapon.spellId, spellInfo->GetDuration());
        owned.carriers[target->GetObjectGuid()] = now + uint32(std::max(0, duration));
    }

    if (weapon.behavior == BONK_BEHAVIOR_VULNERABLE && weapon.altSpellId)
        m_player->CastSpell(target, weapon.altSpellId, true);

    if (weapon.behavior == BONK_BEHAVIOR_DELAYED && weapon.altSpellId)
    {
        PendingCast burst;
        burst.weaponId = weapon.id;
        burst.spellId = weapon.altSpellId;
        burst.leftMs = int32(weapon.behaviorValue);
        burst.target = target->GetObjectGuid();
        burst.x = target->GetPositionX();
        burst.y = target->GetPositionY();
        burst.z = target->GetPositionZ();
        m_pendingCasts.push_back(burst);
    }

    if (weapon.behavior == BONK_BEHAVIOR_BURST)
        for (uint32 shot = 1; shot <= uint32(weapon.behaviorValue); ++shot)
        {
            PendingCast follow;
            follow.weaponId = weapon.id;
            follow.spellId = spellInfo->Id;
            follow.leftMs = int32(shot * BONK_BURST_INTERVAL_MS);
            follow.target = target->GetObjectGuid();
            follow.strike = true;
            follow.share = damageShare;
            m_pendingCasts.push_back(follow);
        }

    if (weapon.IsArcaneMissiles())
        QueueMissiles(owned, spellInfo, target, damageShare);

    OnMageStrike(owned, shotInfo, target, shotShare, source ? static_cast<Unit const*>(source) : m_player);
    OnShamanStrike(owned, shotInfo, target, shotShare);
    CurseFromShadowBolt(owned, target);
    OnPriestStrike(owned, shotInfo, target, shotShare);
    OnWarlockStrike(owned, shotInfo, target, shotShare);
    OnDruidStrike(owned, shotInfo, target);

    if (weapon.HasFlag(BONK_WEAPON_FLAG_KNOCKBACK))
        KnockBack(target);

    if (weapon.HasFlag(BONK_WEAPON_FLAG_REFRESH_DOTS))
        for (OwnedWeapon& other : m_weapons)
            if (&other != &owned && other.weapon.lasting && other.weapon.IsAimed() && target->HasAura(other.weapon.spellId))
                if (SpellEntry const* otherInfo = sSpellMgr.GetSpellEntry(other.weapon.spellId))
                    StrikeWith(other, otherInfo, target, 1.0f, true);
}

bool BonkRun::CanKill(BonkWeapon const& weapon, Creature const* target) const
{
    if (weapon.killBelowPct <= 0.0f || !target->IsAlive() || target->GetHealthPercent() >= weapon.killBelowPct)
        return false;
    BonkMobAI const* ai = dynamic_cast<BonkMobAI const*>(target->AI());
    return ai && ai->GetKind() == BONK_SPAWN_NORMAL;
}

void BonkRun::SortStrongestFirst(std::vector<Creature*>& mobs) const
{
    std::stable_sort(mobs.begin(), mobs.end(), [](Creature const* a, Creature const* b)
    {
        uint32 const rankA = GetKindRank(a);
        uint32 const rankB = GetKindRank(b);
        if (rankA != rankB)
            return rankA > rankB;
        return a->GetHealth() > b->GetHealth();
    });
}

std::vector<Creature*> BonkRun::GetMobsInCone(OwnedWeapon const& owned, float range) const
{
    std::vector<Creature*> mobs = GetMobsInRange(range);
    mobs.erase(std::remove_if(mobs.begin(), mobs.end(), [&](Creature* mob) { return !m_player->IsWithinLOSInMap(mob); }), mobs.end());
    if (mobs.empty())
        return mobs;

    float const aim = m_player->GetAngle(mobs.front());
    float const halfArc = std::min(M_PI_F, BONK_CONE_ARC * GetWeaponArea(owned)) / 2.0f;
    mobs.erase(std::remove_if(mobs.begin(), mobs.end(), [&](Creature* mob)
    {
        float diff = std::fabs(m_player->GetAngle(mob) - aim);
        if (diff > M_PI_F)
            diff = 2.0f * M_PI_F - diff;
        return diff > halfArc;
    }), mobs.end());

    if (owned.weapon.baseTargets > 1 && mobs.size() > owned.weapon.baseTargets)
        mobs.resize(owned.weapon.baseTargets);
    return mobs;
}

void BonkRun::KnockBack(Creature* mob)
{
    BonkMobAI* ai = dynamic_cast<BonkMobAI*>(mob->AI());
    if (!ai || !ai->CanBePulled() || !mob->IsAlive() || mob->HasUnitState(UNIT_STATE_ROOT | UNIT_STATE_STUNNED) || !CanKnockBack(mob))
        return;

    float const angle = m_player->GetAngle(mob);
    float x = mob->GetPositionX() + BONK_KNOCKBACK_DISTANCE * std::cos(angle);
    float y = mob->GetPositionY() + BONK_KNOCKBACK_DISTANCE * std::sin(angle);
    float z = mob->GetPositionZ();
    mob->GetMap()->GetWalkHitPosition(nullptr, mob->GetPositionX(), mob->GetPositionY(), mob->GetPositionZ(), x, y, z);
    ai->Pull(x, y, z, BONK_KNOCKBACK_SPEED, BONK_KNOCKBACK_SETTLE_MS);
}

void BonkRun::QueueRicochet(OwnedWeapon const& owned, SpellEntry const* spellInfo, Creature* target, SpellCaster const* from, float share,
    std::vector<ObjectGuid> struck, uint32 hops)
{
    if (!hops)
        return;

    struck.push_back(target->GetObjectGuid());
    PendingCast hop;
    hop.weaponId = owned.weapon.id;
    hop.spellId = spellInfo->Id;
    hop.leftMs = GetBounceDelay(from, target, spellInfo->speed);
    hop.ricochet = true;
    hop.hops = hops;
    hop.share = share;
    hop.target = target->GetObjectGuid();
    float o;
    if (!target->ExtrapolateMovement(target->m_movementInfo, uint32(hop.leftMs), hop.x, hop.y, hop.z, o))
        target->GetPosition(hop.x, hop.y, hop.z);
    hop.source = HoldShotSource(hop.x, hop.y, hop.z);
    hop.struck = std::move(struck);
    m_pendingCasts.push_back(std::move(hop));
}

void BonkRun::Ricochet(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    float x = cast.x, y = cast.y, z = cast.z;
    Creature* last = m_player->GetMap()->GetCreature(cast.target);
    if (last)
        last->GetPosition(x, y, z);

    Creature* source = ReleaseShotSource(cast.source, x, y, z);
    if (source && last && source->GetObjectGuid() == cast.source)
        source->NearTeleportTo(x, y, z + BONK_PROJECTILE_HEIGHT, source->GetOrientation());
    Creature* next = source ? PickRicochetTarget(source, cast.struck) : nullptr;
    if (!next)
        return;

    float const share = cast.share * BONK_RICOCHET_GROWTH;
    StrikeFromMob(owned, spellInfo, next, share, source, last);
    QueueRicochet(owned, spellInfo, next, source, share, cast.struck, cast.hops - 1);
}

ObjectGuid BonkRun::GetMissileLookSource()
{
    return t_missileLookSource;
}

void BonkRun::LaunchBolt(Unit* caster, SpellEntry const* look, Creature* target, float damage, std::function<void(Creature*)> land)
{
    if (!look || !caster || !target)
        return;
    ShowStrike(caster, look, target);
    if (look->speed <= 0.0f || caster == target)
    {
        land(target);
        return;
    }
    float const incoming = damage * GetDamageMultiplier(look, target) * GetHealthScale(target);
    uint32 const flightMs = uint32(caster->GetDistance3dToCenter(target) / look->speed * IN_MILLISECONDS);
    m_flyingBolts.push_back({ target->GetObjectGuid(), m_totalMs + flightMs + BONK_BOLT_LANDING_LAG_MS, incoming, std::move(land) });
    m_boltIncoming[target->GetObjectGuid()] += incoming;
}

void BonkRun::LandDueBolts()
{
    std::vector<FlyingBolt> due;
    for (auto itr = m_flyingBolts.begin(); itr != m_flyingBolts.end();)
    {
        if (int32(m_totalMs - itr->dueMs) < 0)
        {
            ++itr;
            continue;
        }
        ReleaseBoltIncoming(itr->target, itr->incoming);
        due.push_back(std::move(*itr));
        itr = m_flyingBolts.erase(itr);
    }
    Map* map = m_player->GetMap();
    for (FlyingBolt& bolt : due)
        if (Creature* target = map->GetCreature(bolt.target))
            if (target->IsAlive())
                bolt.land(target);
}

void BonkRun::ReleaseBoltIncoming(ObjectGuid const& target, float incoming)
{
    auto itr = m_boltIncoming.find(target);
    if (itr != m_boltIncoming.end() && (itr->second -= incoming) <= 0.5f)
        m_boltIncoming.erase(itr);
}

bool BonkRun::SurvivesBoltsInFlight(Creature const* mob) const
{
    auto const itr = m_boltIncoming.find(mob->GetObjectGuid());
    return itr == m_boltIncoming.end() || itr->second < float(mob->GetHealth());
}

Creature* BonkRun::PickBoltTarget(Unit const* from, Creature* wanted, float range) const
{
    if (wanted && wanted->IsAlive() && SurvivesBoltsInFlight(wanted))
        return wanted;
    for (Creature* mob : GetMobsNear(from->GetPositionX(), from->GetPositionY(), range))
        if (mob != wanted && SurvivesBoltsInFlight(mob) && from->IsWithinLOSInMap(mob))
            return mob;
    return nullptr;
}

int32 BonkRun::GetBounceDelay(SpellCaster const* from, Unit const* target, float speed)
{
    return std::max(0, int32(GetMissileDelay(from, target, speed)) - BONK_RICOCHET_LEAD_MS);
}

void BonkRun::StrikeFromMob(OwnedWeapon& owned, SpellEntry const* spellInfo, Creature* target, float share, Creature* source,
    Creature const* lookFrom)
{
    FiringWeapon firing(m_player->GetBonkPlayer());
    t_missileLookSource = lookFrom && lookFrom->IsInWorld() && lookFrom->IsAlive() ? lookFrom->GetObjectGuid() : ObjectGuid();
    StrikeWith(owned, spellInfo, target, share, true, source);
    t_missileLookSource = ObjectGuid();
}

ObjectGuid BonkRun::HoldShotSource(float x, float y, float z)
{
    if (m_heldShotSources.size() >= BONK_SHOT_SOURCES_HELD_MAX)
        return ObjectGuid();
    Creature* source = TakeShotSource(x, y, z);
    if (!source)
        return ObjectGuid();
    m_heldShotSources.insert(source->GetObjectGuid());
    return source->GetObjectGuid();
}

Creature* BonkRun::ReleaseShotSource(ObjectGuid guid, float x, float y, float z)
{
    m_heldShotSources.erase(guid);
    Creature* source = guid.IsEmpty() ? nullptr : m_player->GetMap()->GetCreature(guid);
    return source && source->IsAlive() ? source : TakeShotSource(x, y, z);
}

Creature* BonkRun::PickRicochetTarget(WorldObject const* from, std::vector<ObjectGuid> const& struck) const
{
    std::vector<Creature*> const nearby = GetMobsInRange(BONK_RICOCHET_RANGE, from);
    auto isOpen = [&](Creature* mob)
    {
        return std::find(struck.begin(), struck.end(), mob->GetObjectGuid()) == struck.end() && from->IsWithinLOSInMap(mob);
    };
    for (Creature* mob : nearby)
        if (GetKeywordStacks(mob, BONK_KEYWORD_HUNTERS_MARK) && isOpen(mob))
            return mob;
    for (Creature* mob : nearby)
        if (!GetKeywordStacks(mob, BONK_KEYWORD_HUNTERS_MARK) && isOpen(mob))
            return mob;
    return nullptr;
}

void BonkRun::QueueTrickShot(Creature const* dead, uint32 killingSpell)
{
    OwnedWeapon const* owned = killingSpell ? FindOwnedBySpell(killingSpell) : nullptr;
    if (!owned || owned->weapon.behavior != BONK_BEHAVIOR_TRICK_SHOTS || !TakeRateSlot(m_trickShotTimes, BONK_MAX_TRICK_SHOTS))
        return;

    PendingCast volley;
    volley.weaponId = owned->weapon.id;
    volley.spellId = owned->weapon.spellId;
    volley.leftMs = BONK_TRICK_SHOT_DELAY_MS;
    volley.trickShot = true;
    dead->GetPosition(volley.x, volley.y, volley.z);
    volley.source = HoldShotSource(volley.x, volley.y, volley.z);
    m_pendingCasts.push_back(std::move(volley));
}

void BonkRun::FireTrickShot(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    Creature* source = ReleaseShotSource(cast.source, cast.x, cast.y, cast.z);
    if (!source)
        return;

    uint32 const arrows = std::max(1u, uint32(owned.weapon.behaviorValue));
    uint32 fired = 0;
    FiringWeapon firing(m_player->GetBonkPlayer());
    for (Creature* mob : GetMobsInRange(BONK_TRICK_SHOT_RANGE, source))
    {
        if (fired >= arrows)
            break;
        if (!source->IsWithinLOSInMap(mob))
            continue;
        StrikeWith(owned, spellInfo, mob, 1.0f, true, source);
        ++fired;
    }
}

bool BonkRun::UsesShotSources() const
{
    for (BonkWeaponBehavior behavior : { BONK_BEHAVIOR_RICOCHET, BONK_BEHAVIOR_TRICK_SHOTS, BONK_BEHAVIOR_CHAIN_DETONATION, BONK_BEHAVIOR_GRAVITY_PULL,
        BONK_BEHAVIOR_FLARE, BONK_BEHAVIOR_SHARD_BURST, BONK_BEHAVIOR_VENOM_BOLTS, BONK_BEHAVIOR_VENOM_CLOUD, BONK_BEHAVIOR_WAKE_OF_BLADES,
        BONK_BEHAVIOR_FOURTH_SWING, BONK_BEHAVIOR_BLOOD_POOL, BONK_BEHAVIOR_AFTERSHOCK, BONK_BEHAVIOR_STEEL_CYCLONE, BONK_BEHAVIOR_AVENGERS_SHIELD,
        BONK_BEHAVIOR_ICE_SHARDS, BONK_BEHAVIOR_FROST_SHATTER, BONK_BEHAVIOR_ICE_NOVA, BONK_BEHAVIOR_LIVING_BOMB, BONK_BEHAVIOR_METEOR,
        BONK_BEHAVIOR_METEOR_SHOWER })
        if (HasBehavior(behavior))
            return true;
    return std::any_of(m_weapons.begin(), m_weapons.end(), [](OwnedWeapon const& owned)
    {
        return owned.weapon.HasFlag(BONK_WEAPON_FLAG_CLUSTER_BOMBS) || owned.weapon.HasFlag(BONK_WEAPON_FLAG_SHATTER) ||
            owned.weapon.HasFlag(BONK_WEAPON_FLAG_CHAIN_EXECUTION);
    });
}

Creature* BonkRun::SummonShotSource()
{
    s_nextHelperLevel = sWorld.getConfig(CONFIG_UINT32_MAX_PLAYER_LEVEL);
    Creature* source = m_player->SummonCreature(BONK_PROJECTILE, m_player->GetPositionX(), m_player->GetPositionY(), m_player->GetPositionZ(), 0.0f,
        TEMPSUMMON_TIMED_DESPAWN, BONK_SHOT_SOURCE_LIFETIME_MS, false, 0, &InstallProjectileAI);
    if (!source)
        return nullptr;
    source->SetFactionTemplateId(m_player->GetFactionTemplateId());
    source->SetOwnerGuid(m_player->GetObjectGuid());
    source->SetVirtualItem(RANGED_ATTACK, BONK_SHOT_SOURCE_BOW);
    source->SetUInt32Value(UNIT_VIRTUAL_ITEM_SLOT_DISPLAY + RANGED_ATTACK, 0);
    return source;
}

void BonkRun::WarmShotSources()
{
    if (!m_player->IsInWorld())
        return;

    Map* map = m_player->GetMap();
    m_shotSources.resize(BONK_SHOT_SOURCES);
    for (ObjectGuid& guid : m_shotSources)
    {
        Creature* source = guid.IsEmpty() ? nullptr : map->GetCreature(guid);
        if (source && source->IsAlive())
            continue;
        if (source)
            source->DespawnOrUnsummon();
        source = SummonShotSource();
        guid = source ? source->GetObjectGuid() : ObjectGuid();
    }
}

Creature* BonkRun::TakeShotSource(float x, float y, float z)
{
    WarmShotSources();
    Map* map = m_player->GetMap();
    for (size_t tries = 0; tries < m_shotSources.size(); ++tries)
    {
        ObjectGuid const guid = m_shotSources[m_nextShotSource];
        m_nextShotSource = (m_nextShotSource + 1) % m_shotSources.size();
        Creature* source = guid.IsEmpty() ? nullptr : map->GetCreature(guid);
        if (!source || !source->IsAlive() || m_heldShotSources.count(guid))
            continue;
        source->NearTeleportTo(x, y, z + BONK_PROJECTILE_HEIGHT, source->GetOrientation());
        return source;
    }
    return nullptr;
}

void BonkRun::UpdateShotSources(uint32 diff)
{
    m_shotSourceTimer += diff;
    if (m_shotSourceTimer < BONK_SHOT_SOURCE_CHECK_MS)
        return;
    m_shotSourceTimer = 0;
    if (!UsesShotSources())
        return;

    WarmShotSources();
    Map* map = m_player->GetMap();
    for (ObjectGuid const& guid : m_shotSources)
        if (Creature* source = guid.IsEmpty() || m_heldShotSources.count(guid) ? nullptr : map->GetCreature(guid))
            if (!source->IsWithinDistInMap(m_player, BONK_SHOT_SOURCE_GATHER))
                source->NearTeleportTo(m_player->GetPositionX(), m_player->GetPositionY(), m_player->GetPositionZ() + BONK_PROJECTILE_HEIGHT,
                    source->GetOrientation());
}

void BonkRun::DespawnShotSources()
{
    DespawnPooledMarkers(m_boltTargets);
    DespawnPooledMarkers(m_hazardSources);
    m_heldShotSources.clear();
    if (Map* map = m_player->FindMap())
        for (ObjectGuid const& guid : m_shotSources)
            if (Creature* source = guid.IsEmpty() ? nullptr : map->GetCreature(guid))
                source->DespawnOrUnsummon();
    m_shotSources.clear();
    m_nextShotSource = 0;
}


bool BonkRun::TakeRateSlot(std::vector<uint32>& times, size_t cap)
{
    times.erase(std::remove_if(times.begin(), times.end(), [this](uint32 at) { return at + BONK_RATE_WINDOW_MS <= m_totalMs; }), times.end());
    if (times.size() >= cap)
        return false;
    times.push_back(m_totalMs);
    return true;
}

std::vector<Creature*> BonkRun::GetMobsNear(float x, float y, float radius) const
{
    Map* map = m_player->GetMap();
    std::vector<std::pair<float, Creature*>> found;
    for (ObjectGuid const& guid : GetEnemyGuids())
    {
        Creature* mob = map->GetCreature(guid);
        if (!mob || !mob->IsAlive() || mob->HasCreatureState(CSTATE_DESPAWNING))
            continue;
        float const distance = mob->GetDistance2d(x, y);
        if (distance <= radius)
            found.emplace_back(distance, mob);
    }
    std::sort(found.begin(), found.end(), [](auto const& a, auto const& b) { return a.first < b.first; });

    std::vector<Creature*> mobs;
    mobs.reserve(found.size());
    for (auto const& itr : found)
        mobs.push_back(itr.second);
    return mobs;
}

void BonkRun::PlayKitAt(ObjectGuid const& guid, float x, float y, float z, uint32 kit, bool atFeet)
{
    Creature* mob = guid.IsEmpty() ? nullptr : m_player->GetMap()->GetCreature(guid);
    if (mob && mob->IsAlive())
    {
        mob->SendPlaySpellVisualKit(kit);
        return;
    }
    SendBonkKitAt(m_player, kit, x, y, atFeet ? z : z + BONK_PROJECTILE_HEIGHT, 0.0f, BONK_ERUPTION_LOOK_MS, !atFeet);
}

void BonkRun::QueueDetonations(OwnedWeapon const& owned, SpellEntry const* spellInfo, float share, std::vector<Creature*> struck)
{
    std::vector<std::pair<float, Creature*>> line;
    line.reserve(struck.size());
    for (Creature* mob : struck)
        line.emplace_back(m_player->GetDistance2d(mob), mob);
    std::sort(line.begin(), line.end(), [](auto const& a, auto const& b) { return a.first < b.first; });
    if (line.size() > BONK_MAX_DETONATIONS)
        line.resize(BONK_MAX_DETONATIONS);

    int32 delay = BONK_DETONATION_FIRST_MS - BONK_DETONATION_GAP_MS;
    for (auto const& itr : line)
    {
        Creature* mob = itr.second;
        int32 const landed = int32(GetMissileDelay(m_player, mob, spellInfo->speed));
        delay = std::max(delay + BONK_DETONATION_GAP_MS, landed + BONK_DETONATION_FIRST_MS);

        PendingCast blast;
        blast.weaponId = owned.weapon.id;
        blast.spellId = spellInfo->Id;
        blast.leftMs = delay;
        blast.detonate = true;
        blast.share = share;
        blast.target = mob->GetObjectGuid();
        mob->GetPosition(blast.x, blast.y, blast.z);
        m_pendingCasts.push_back(std::move(blast));
    }
}

void BonkRun::Detonate(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    float x = cast.x, y = cast.y, z = cast.z;
    if (Creature* mob = m_player->GetMap()->GetCreature(cast.target))
        mob->GetPosition(x, y, z);
    PlayKitAt(cast.target, x, y, z, BONK_KIT_DETONATION, false);

    float const damage = GetWeaponDamage(owned) * cast.share;
    for (Creature* victim : GetMobsNear(x, y, GetWeaponRadius(owned)))
        DealSpellHit(spellInfo, victim, damage);
}

bool BonkRun::IsSteadyAiming(OwnedWeapon const& owned) const
{
    return m_steady && owned.weapon.behavior == BONK_BEHAVIOR_STEADY_AIM;
}

float BonkRun::GetSteadyWidth(OwnedWeapon const& owned) const
{
    if (!IsSteadyAiming(owned))
        return 1.0f;
    float const steps = float((m_totalMs - m_steadySinceMs) / BONK_STEADY_STEP_MS);
    return std::max(1.0f, std::min(owned.weapon.behaviorValue, 1.0f + steps));
}

void BonkRun::UpdateSteadyAim()
{
    auto steadyWeapon = std::find_if(m_weapons.begin(), m_weapons.end(), [](OwnedWeapon const& owned)
    {
        return owned.weapon.behavior == BONK_BEHAVIOR_STEADY_AIM;
    });
    if (steadyWeapon == m_weapons.end())
    {
        m_steady = false;
        ShowHeroLook(BonkHeroLook::SteadyAim, false);
        return;
    }

    float const x = m_player->GetPositionX(), y = m_player->GetPositionY();
    bool const moved = m_player->IsMoving() || std::fabs(x - m_steadyX) > BONK_STEADY_DRIFT || std::fabs(y - m_steadyY) > BONK_STEADY_DRIFT;
    m_steadyX = x;
    m_steadyY = y;
    bool const steady = !moved && m_player->IsAlive();
    if (steady != m_steady)
    {
        m_steady = steady;
        m_steadySinceMs = m_totalMs;
        m_steadyPulseMs = BONK_STEADY_FIRST_PULSE_MS;
        RetimeSteadyWeapons();
    }
    uint32 const stillMs = m_steady ? m_totalMs - m_steadySinceMs : 0;
    ShowHeroLook(BonkHeroLook::SteadyAim, m_steady && stillMs >= BONK_STEADY_FIRST_PULSE_MS);
    if (!m_steady || stillMs < m_steadyPulseMs)
        return;
    if (m_steadyPulseMs > BONK_STEADY_FIRST_PULSE_MS)
        m_player->SendPlaySpellVisualKit(BONK_KIT_STEADY_AIM_STEP);
    uint32 const widestMs = uint32(std::max(0.0f, steadyWeapon->weapon.behaviorValue - 1.0f)) * BONK_STEADY_STEP_MS;
    m_steadyPulseMs = stillMs < widestMs ? (stillMs / BONK_STEADY_STEP_MS + 1) * BONK_STEADY_STEP_MS : std::numeric_limits<uint32>::max();
}

void BonkRun::RetimeSteadyWeapons()
{
    uint32 index = 0;
    for (OwnedWeapon& owned : m_weapons)
    {
        ++index;
        if (owned.weapon.behavior != BONK_BEHAVIOR_STEADY_AIM)
            continue;
        if (m_steady)
            owned.timer = int32(owned.timer / BONK_STEADY_RATE);
        else
            owned.timer = std::min(int32(owned.timer * BONK_STEADY_RATE), int32(GetWeaponCooldown(owned)));
        SendWeaponInfo(index, owned);
    }
}

uint32 BonkRun::GetArrowStormTickMs(OwnedWeapon const& owned) const
{
    return std::max(200u, uint32(std::max(200u, owned.weapon.tickMs) / GetWeaponHasteRate(owned)));
}

void BonkRun::StartArrowStorm(OwnedWeapon const& owned, SpellEntry const* spellInfo, float x, float y, float z)
{
    ShowMissileAt(m_player, spellInfo, x, y, z);
    if (m_arrowStorms.size() >= BONK_MAX_ARROW_STORMS)
        m_arrowStorms.erase(m_arrowStorms.begin());

    ArrowStorm storm;
    storm.weaponId = owned.weapon.id;
    storm.x = storm.aimX = x;
    storm.y = storm.aimY = y;
    storm.z = storm.aimZ = z;
    storm.leftMs = int32(owned.weapon.durationMs * GetWeaponDurationScale(owned));
    storm.tickMs = int32(GetArrowStormTickMs(owned));
    m_arrowStorms.push_back(storm);
}

void BonkRun::UpdateArrowStorms(uint32 diff)
{
    for (size_t i = 0; i < m_arrowStorms.size();)
    {
        ArrowStorm& storm = m_arrowStorms[i];
        OwnedWeapon* owned = FindOwned(storm.weaponId);
        SpellEntry const* spellInfo = owned ? sSpellMgr.GetSpellEntry(owned->weapon.spellId) : nullptr;
        storm.leftMs -= int32(diff);
        if (!spellInfo || storm.leftMs <= 0 || !m_player->IsAlive())
        {
            m_arrowStorms.erase(m_arrowStorms.begin() + i);
            continue;
        }

        float const radius = owned->weapon.groundRadius * GetWeaponArea(*owned);
        storm.aimMs -= int32(diff);
        if (storm.aimMs <= 0)
        {
            storm.aimMs = BONK_STORM_AIM_MS;
            AimArrowStorm(storm, radius);
        }
        DriftArrowStorm(storm, owned->weapon.behaviorValue, diff);

        storm.rainMs -= int32(diff);
        if (storm.rainMs <= 0)
        {
            storm.rainMs = BONK_STORM_RAIN_MS;
            PlaceAreaVisual(m_player, spellInfo->Id, storm.x, storm.y, storm.z, radius, uint32(std::min(BONK_STORM_RAIN_LIFE_MS, storm.leftMs)));
        }

        storm.tickMs -= int32(diff);
        bool const rains = storm.tickMs <= 0;
        if (rains)
            storm.tickMs += int32(GetArrowStormTickMs(*owned));
        ArrowStorm const rained = storm;
        ++i;
        if (rains)
            RainArrowStorm(*owned, spellInfo, rained, radius);
    }
}

void BonkRun::AimArrowStorm(ArrowStorm& storm, float radius) const
{
    std::vector<Creature*> nearby = GetMobsNear(storm.x, storm.y, BONK_STORM_SEEK_RANGE);
    if (nearby.size() > BONK_STORM_SEEK_MOBS)
        nearby.resize(BONK_STORM_SEEK_MOBS);
    std::vector<Creature*> const groups = PickGroundSpots(nearby, radius, 1);
    if (groups.empty())
    {
        storm.aim.Clear();
        return;
    }
    storm.aim = groups.front()->GetObjectGuid();
    groups.front()->GetPosition(storm.aimX, storm.aimY, storm.aimZ);
}

void BonkRun::DriftArrowStorm(ArrowStorm& storm, float speed, uint32 diff) const
{
    if (!storm.aim.IsEmpty())
        if (Creature* aim = m_player->GetMap()->GetCreature(storm.aim))
            if (aim->IsAlive())
                aim->GetPosition(storm.aimX, storm.aimY, storm.aimZ);

    float const dx = storm.aimX - storm.x, dy = storm.aimY - storm.y;
    float const distance = std::sqrt(dx * dx + dy * dy);
    float const step = std::max(0.0f, speed) * diff / float(IN_MILLISECONDS);
    if (distance <= step)
    {
        storm.x = storm.aimX;
        storm.y = storm.aimY;
        storm.z = storm.aimZ;
        return;
    }
    float const part = step / distance;
    storm.x += dx * part;
    storm.y += dy * part;
    storm.z += (storm.aimZ - storm.z) * part;
}

void BonkRun::RainArrowStorm(OwnedWeapon& owned, SpellEntry const* spellInfo, ArrowStorm const& storm, float radius)
{
    float const damage = GetWeaponDamage(owned) * owned.weapon.tickMs / float(IN_MILLISECONDS);
    float const twice = GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_HIT_TWICE);
    for (Creature* mob : GetMobsNear(storm.x, storm.y, radius))
    {
        DealSpellHit(spellInfo, mob, damage);
        if (twice > 0.0f && roll_chance_f(twice))
            DealSpellHit(spellInfo, mob, damage);
    }
}

void BonkRun::GravityPull(OwnedWeapon const& owned, SpellEntry const* spellInfo, float x, float y, float z, float radius)
{
    PlayKitAt(ObjectGuid(), x, y, z, BONK_KIT_GRAVITY_PULL, true);
    for (Creature* mob : GetMobsNear(x, y, radius * std::max(1.0f, owned.weapon.behaviorValue)))
        PullMob(mob, x, y, z);

    PendingCast rain;
    rain.weaponId = owned.weapon.id;
    rain.spellId = spellInfo->Id;
    rain.leftMs = BONK_GRAVITY_RAIN_DELAY_MS;
    rain.x = x;
    rain.y = y;
    rain.z = z;
    m_pendingCasts.push_back(std::move(rain));
}

void BonkRun::PullMob(Creature* mob, float x, float y, float z)
{
    BonkMobAI* ai = dynamic_cast<BonkMobAI*>(mob->AI());
    if (!ai || mob->HasUnitState(UNIT_STATE_ROOT | UNIT_STATE_STUNNED) || mob->GetDistance2d(x, y) <= BONK_GRAVITY_PILE_RADIUS || !CanPull(mob))
        return;

    float const angle = std::atan2(mob->GetPositionY() - y, mob->GetPositionX() - x);
    float px = x + BONK_GRAVITY_PILE_RADIUS * std::cos(angle);
    float py = y + BONK_GRAVITY_PILE_RADIUS * std::sin(angle);
    float pz = z;
    mob->GetMap()->GetWalkHitPosition(nullptr, mob->GetPositionX(), mob->GetPositionY(), mob->GetPositionZ(), px, py, pz);
    ai->Pull(px, py, pz, BONK_GRAVITY_PULL_SPEED, BONK_GRAVITY_SETTLE_MS);
}

void BonkRun::LightFlare(OwnedWeapon const& owned, float x, float y, float z, float radius)
{
    uint32 const burnMs = uint32(std::max(0.0f, owned.weapon.behaviorValue) * GetWeaponDurationScale(owned));
    if (!burnMs)
        return;
    if (m_flares.size() >= BONK_MAX_FLARES)
        m_flares.erase(m_flares.begin());
    PlaceAreaVisual(m_player, owned.weapon.spellId, x, y, z, radius, burnMs);

    Flare flare;
    flare.x = x;
    flare.y = y;
    flare.radius = radius;
    flare.untilMs = m_totalMs + burnMs;
    m_flares.push_back(flare);
}

BonkRun::Flare const* BonkRun::FindFlareAt(float x, float y)
{
    m_flares.erase(std::remove_if(m_flares.begin(), m_flares.end(), [this](Flare const& flare) { return flare.untilMs <= m_totalMs; }), m_flares.end());
    for (Flare const& flare : m_flares)
    {
        float const dx = x - flare.x, dy = y - flare.y;
        if (dx * dx + dy * dy <= flare.radius * flare.radius)
            return &flare;
    }
    return nullptr;
}

void BonkRun::QueueFlareSplit(OwnedWeapon const& owned, SpellEntry const* spellInfo, Creature* target, float share, SpellCaster const* from)
{
    BonkWeapon const& weapon = owned.weapon;
    if (m_flares.empty() || weapon.behavior == BONK_BEHAVIOR_PET || weapon.behavior == BONK_BEHAVIOR_WRATH ||
        (weapon.damageEffectIndex < 0 && !weapon.weaponDamage))
        return;
    if (!FindFlareAt(target->GetPositionX(), target->GetPositionY()) || !TakeRateSlot(m_flareSplitTimes, BONK_MAX_FLARE_SPLITS))
        return;

    PendingCast split;
    split.weaponId = weapon.id;
    split.spellId = spellInfo->Id;
    split.leftMs = GetBounceDelay(from, target, spellInfo->speed);
    split.flareSplit = true;
    split.share = share;
    split.target = target->GetObjectGuid();
    target->GetPosition(split.x, split.y, split.z);
    split.source = HoldShotSource(split.x, split.y, split.z);
    m_pendingCasts.push_back(std::move(split));
}

void BonkRun::FireFlareSplit(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    float x = cast.x, y = cast.y, z = cast.z;
    Creature* struck = m_player->GetMap()->GetCreature(cast.target);
    if (struck)
        struck->GetPosition(x, y, z);
    Creature* source = ReleaseShotSource(cast.source, x, y, z);

    Flare const* flare = FindFlareAt(cast.x, cast.y);
    if (!flare || !source)
        return;
    float const flareX = flare->x, flareY = flare->y, flareRadius = flare->radius;

    for (Creature* mob : GetMobsNear(x, y, 2.0f * flareRadius))
    {
        if (mob->GetObjectGuid() == cast.target || mob->GetDistance2d(flareX, flareY) > flareRadius)
            continue;
        if (!source->IsWithinLOSInMap(mob))
            continue;
        StrikeFromMob(owned, spellInfo, mob, cast.share, source, struck);
        return;
    }
}

void BonkRun::QueueShardBurst(Creature const* dead)
{
    auto owned = std::find_if(m_weapons.begin(), m_weapons.end(), [](OwnedWeapon const& weapon)
    {
        return weapon.weapon.behavior == BONK_BEHAVIOR_SHARD_BURST;
    });
    if (owned == m_weapons.end() || !TakeRateSlot(m_shardBurstTimes, BONK_MAX_SHARD_BURSTS))
        return;

    PendingCast burst;
    burst.weaponId = owned->weapon.id;
    burst.spellId = owned->weapon.spellId;
    burst.leftMs = BONK_SHARD_BURST_DELAY_MS;
    burst.shardBurst = true;
    burst.target = dead->GetObjectGuid();
    dead->GetPosition(burst.x, burst.y, burst.z);
    m_pendingCasts.push_back(std::move(burst));
}

void BonkRun::ShardBurst(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    PlayKitAt(cast.target, cast.x, cast.y, cast.z, BONK_KIT_SHARD_BURST, true);
    float const damage = GetWeaponDamage(owned);
    float const radius = std::max(0.0f, owned.weapon.behaviorValue) * GetWeaponArea(owned);
    m_keywordlessHits = true;
    for (Creature* mob : GetMobsNear(cast.x, cast.y, radius))
        DealSpellHit(spellInfo, mob, damage);
    m_keywordlessHits = false;
}

void BonkRun::OnPoisonedDeath(Creature const* dead)
{
    for (OwnedWeapon const& owned : m_weapons)
    {
        BonkWeaponBehavior const behavior = owned.weapon.behavior;
        if ((behavior == BONK_BEHAVIOR_VENOM_BOLTS && TakeRateSlot(m_venomBoltTimes, BONK_MAX_VENOM_VOLLEYS)) ||
            (behavior == BONK_BEHAVIOR_VENOM_CLOUD && TakeRateSlot(m_venomCloudTimes, BONK_MAX_NEW_VENOM_CLOUDS)))
            QueueVenom(owned, dead);
    }
}

void BonkRun::QueueVenom(OwnedWeapon const& owned, Creature const* dead)
{
    bool const cloud = owned.weapon.behavior == BONK_BEHAVIOR_VENOM_CLOUD;
    PendingCast venom;
    venom.weaponId = owned.weapon.id;
    venom.spellId = owned.weapon.spellId;
    venom.leftMs = cloud ? 0 : BONK_VENOM_BOLT_DELAY_MS;
    venom.keywordCloud = cloud;
    venom.venomBolts = !cloud;
    dead->GetPosition(venom.x, venom.y, venom.z);
    if (!cloud)
        venom.source = HoldShotSource(venom.x, venom.y, venom.z);
    m_pendingCasts.push_back(std::move(venom));
}

void BonkRun::FireVenomBolts(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    PendingKeyword venom;
    if (!GetWeaponKeyword(owned, venom))
        return;
    uint32 const stacks = BONK_VENOM_BOLT_STACKS + uint32(GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_STACKS));
    uint32 const arrows = std::max(1u, uint32(owned.weapon.behaviorValue));

    Creature* source = ReleaseShotSource(cast.source, cast.x, cast.y, cast.z);
    uint32 fired = 0;
    FiringWeapon firing(m_player->GetBonkPlayer());
    for (Creature* mob : GetMobsNear(cast.x, cast.y, BONK_VENOM_BOLT_RANGE))
    {
        if (fired >= arrows)
            break;
        if (!source)
            return;
        if (!source->IsWithinLOSInMap(mob))
            continue;
        source->CastSpell(mob, spellInfo, true, nullptr, nullptr, m_player->GetObjectGuid());
        ApplyKeyword(mob, venom.keyword, stacks, venom.durationMs, venom.damageScale, venom.spellId);
        ++fired;
    }
}

BonkRun::KeywordCloudKind BonkRun::GetCloudKind(OwnedWeapon const& owned) const
{
    if (owned.weapon.behavior == BONK_BEHAVIOR_BLOOD_POOL)
        return GetBloodPoolKind();
    KeywordCloudKind mage;
    if (GetMageCloudKind(owned, mage))
        return mage;
    KeywordCloudKind shaman;
    if (GetShamanCloudKind(owned, shaman))
        return shaman;
    KeywordCloudKind priest;
    if (GetPriestCloudKind(owned, priest))
        return priest;
    KeywordCloudKind rogue;
    if (GetRogueCloudKind(owned, rogue))
        return rogue;
    KeywordCloudKind paladin;
    if (GetPaladinCloudKind(owned, paladin))
        return paladin;
    KeywordCloudKind druid;
    if (GetDruidCloudKind(owned, druid))
        return druid;
    KeywordCloudKind hunter;
    if (GetHunterCloudKind(owned, hunter))
        return hunter;

    KeywordCloudKind venom;
    venom.lifeMs = BONK_VENOM_CLOUD_MS;
    venom.pulseEveryMs = BONK_VENOM_CLOUD_PULSE_MS;
    venom.stacks = BONK_VENOM_CLOUD_STACKS;
    venom.maxAlive = BONK_MAX_VENOM_CLOUDS;
    venom.lookSpellId = BONK_SPELL_VENOM_CLOUD_LOOK;
    venom.burstKit = BONK_KIT_VENOM_BURST;
    return venom;
}

float BonkRun::GetCloudRadius(OwnedWeapon const& owned) const
{
    switch (owned.weapon.behavior)
    {
        case BONK_BEHAVIOR_METEOR:
        case BONK_BEHAVIOR_BURNING_GROUND:
        case BONK_BEHAVIOR_SWIPE:
        case BONK_BEHAVIOR_FAN_OF_KNIVES:
            return std::max(0.0f, owned.weapon.behaviorValue) * GetWeaponArea(owned);
        default:
            return GetWeaponRadius(owned);
    }
}

void BonkRun::StartKeywordCloud(OwnedWeapon const& owned, float x, float y, float z)
{
    KeywordCloudKind const kind = GetCloudKind(owned);
    auto const fromWeapon = [&owned](KeywordCloud const& cloud) { return cloud.weaponId == owned.weapon.id; };
    if (size_t(std::count_if(m_keywordClouds.begin(), m_keywordClouds.end(), fromWeapon)) >= kind.maxAlive)
    {
        auto const oldest = std::find_if(m_keywordClouds.begin(), m_keywordClouds.end(), fromWeapon);
        EndKeywordCloud(*oldest);
        m_keywordClouds.erase(oldest);
    }

    KeywordCloud cloud;
    cloud.weaponId = owned.weapon.id;
    cloud.x = x;
    cloud.y = y;
    cloud.radius = GetCloudRadius(owned);
    cloud.leftMs = int32(kind.lifeMs * GetWeaponDurationScale(owned));
    cloud.pulseEveryMs = kind.pulseEveryMs;
    cloud.stacks = kind.stacks;
    if (kind.bloodRing || kind.natureRing)
        ShowRingAt(cloud, z, kind.natureRing ? BonkHeroRing::Nature : BonkHeroRing::BloodAura);
    else if (kind.lookSpellId)
        cloud.area = PlaceAreaVisual(m_player, kind.lookSpellId, x, y, z, cloud.radius, uint32(cloud.leftMs));
    m_keywordClouds.push_back(cloud);
    if (kind.burstKit)
        PlayKitAt(ObjectGuid(), x, y, z, kind.burstKit, true);
}

void BonkRun::ShowRingAt(KeywordCloud& cloud, float z, BonkHeroRing ring)
{
    cloud.markKey = NextBonkAuraKey();
    SendBonkMark(m_player, "cloud" + std::to_string(cloud.markKey), BONK_TELEGRAPH_CIRCLE, cloud.x, cloud.y, z, 0.0f, cloud.radius, 0, true,
        GetRingStyle(ring), ObjectGuid(), "", 0, true);
}

void BonkRun::EndKeywordCloud(KeywordCloud const& cloud)
{
    RemoveAreaVisual(m_player, cloud.area);
    if (cloud.markKey)
        SendBonkUnmark(m_player, "cloud" + std::to_string(cloud.markKey));
}

void BonkRun::ClearKeywordClouds()
{
    for (KeywordCloud const& cloud : m_keywordClouds)
        EndKeywordCloud(cloud);
    m_keywordClouds.clear();
}

void BonkRun::UpdateKeywordClouds(uint32 diff)
{
    for (size_t i = 0; i < m_keywordClouds.size();)
    {
        KeywordCloud& cloud = m_keywordClouds[i];
        OwnedWeapon const* owned = FindOwned(cloud.weaponId);
        cloud.leftMs -= int32(diff);
        cloud.pulseMs -= int32(diff);
        if (!owned || cloud.leftMs <= 0)
        {
            if (owned)
                OnDruidCloudEnd(*owned, cloud);
            EndKeywordCloud(cloud);
            m_keywordClouds.erase(m_keywordClouds.begin() + i);
            continue;
        }

        bool const pulses = cloud.pulseMs <= 0;
        if (pulses)
            cloud.pulseMs += cloud.pulseEveryMs;
        KeywordCloud const pulsed = cloud;
        ++i;
        if (pulses)
            PulseKeywordCloud(*owned, pulsed);
    }
}

void BonkRun::PulseKeywordCloud(OwnedWeapon const& owned, KeywordCloud const& cloud)
{
    OnPaladinCloudPulse(owned, cloud);
    OnDruidCloudPulse(owned, cloud);
    PendingKeyword keyword;
    if (GetWeaponKeyword(owned, keyword))
    {
        uint32 const stacks = cloud.stacks + uint32(GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_STACKS));
        for (Creature* mob : GetMobsNear(cloud.x, cloud.y, cloud.radius))
            ApplyKeyword(mob, keyword.keyword, stacks, keyword.durationMs, keyword.damageScale, keyword.spellId);
    }
    OnShamanCloudPulse(owned, cloud);
    OnRogueCloudPulse(owned, cloud);
    OnHunterCloudPulse(owned, cloud);
}

void BonkRun::ScatterBomblets(OwnedWeapon const& owned, SpellEntry const* spellInfo, float x, float y, float z)
{
    struct Spot
    {
        float x = 0.0f, y = 0.0f, z = 0.0f;
        float distance = 0.0f;
    };
    std::vector<Spot> spots;
    Map* map = m_player->GetMap();
    float const area = GetWeaponArea(owned);
    float const startAngle = frand(0.0f, 2.0f * M_PI_F);
    for (uint32 i = 0; i < BONK_CLUSTER_BOMBLETS; ++i)
    {
        float const angle = startAngle + 2.0f * M_PI_F * (i + frand(-0.3f, 0.3f)) / BONK_CLUSTER_BOMBLETS;
        float const toss = frand(BONK_BOMBLET_MIN_TOSS, BONK_BOMBLET_MAX_TOSS) * area;
        Spot spot;
        spot.x = x + toss * std::cos(angle);
        spot.y = y + toss * std::sin(angle);
        spot.z = z;
        map->GetWalkHitPosition(nullptr, x, y, z, spot.x, spot.y, spot.z);
        spot.distance = std::sqrt((spot.x - x) * (spot.x - x) + (spot.y - y) * (spot.y - y));
        spots.push_back(spot);
    }
    std::sort(spots.begin(), spots.end(), [](Spot const& a, Spot const& b) { return a.distance < b.distance; });

    SpellEntry const* tossInfo = sSpellMgr.GetSpellEntry(BONK_SPELL_BOMBLET_TOSS);
    int32 delay = BONK_BOMBLET_FIRST_MS - BONK_BOMBLET_GAP_MS;
    for (Spot const& spot : spots)
    {
        int32 landed = 0;
        if (tossInfo)
        {
            ShowMissileBetween(tossInfo, x, y, z + BONK_PROJECTILE_HEIGHT, spot.x, spot.y, spot.z);
            if (tossInfo->speed > 0.0f)
                landed = int32(spot.distance / tossInfo->speed * IN_MILLISECONDS);
        }
        delay = std::max(delay + BONK_BOMBLET_GAP_MS, landed);

        PendingCast bomblet;
        bomblet.weaponId = owned.weapon.id;
        bomblet.spellId = spellInfo->Id;
        bomblet.leftMs = delay;
        bomblet.bomblet = true;
        bomblet.x = spot.x;
        bomblet.y = spot.y;
        bomblet.z = spot.z;
        m_pendingCasts.push_back(std::move(bomblet));
    }
}

void BonkRun::Bomblet(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    PlayKitAt(ObjectGuid(), cast.x, cast.y, cast.z, BONK_KIT_BOMBLET, true);
    float const damage = GetWeaponDamage(owned) * BONK_BOMBLET_SHARE;
    for (Creature* mob : GetMobsNear(cast.x, cast.y, BONK_BOMBLET_RADIUS * GetWeaponArea(owned)))
        DealSpellHit(spellInfo, mob, damage);
}

void BonkRun::ReleaseSnakes(OwnedWeapon const& owned, float x, float y, float z)
{
    Map* map = m_player->GetMap();
    uint32 const lifeMs = uint32(owned.weapon.durationMs * GetWeaponDurationScale(owned));
    float const startAngle = frand(0.0f, 2.0f * M_PI_F);
    for (uint32 i = 0; i < BONK_SNAKES_PER_TRAP; ++i)
    {
        if (m_snakes.size() >= BONK_MAX_SNAKES)
        {
            if (Creature* oldest = map->GetCreature(m_snakes.front().guid))
                oldest->DespawnOrUnsummon();
            m_snakes.erase(m_snakes.begin());
        }

        float const angle = startAngle + 2.0f * M_PI_F * i / BONK_SNAKES_PER_TRAP;
        float sx = x + BONK_SNAKE_SPREAD * std::cos(angle);
        float sy = y + BONK_SNAKE_SPREAD * std::sin(angle);
        float sz = z;
        map->GetWalkHitPosition(nullptr, x, y, z, sx, sy, sz);
        s_nextHelperLevel = m_player->GetLevel();
        Creature* snake = m_player->SummonCreature(BONK_SNAKE, sx, sy, sz, angle, TEMPSUMMON_TIMED_DESPAWN,
            BONK_OBJECT_LIFETIME_SEC * IN_MILLISECONDS, false, 0, &InstallPetAI);
        if (!snake)
            continue;
        snake->SetOwnerGuid(m_player->GetObjectGuid());
        snake->SetUInt32Value(UNIT_CREATED_BY_SPELL, owned.weapon.spellId);
        snake->SetFactionTemplateId(m_player->GetFactionTemplateId());
        snake->SetFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_IMMUNE_TO_PLAYER);
        snake->SetHealth(snake->GetMaxHealth());
        snake->SetInvincibilityHpThreshold(snake->GetMaxHealth());

        Snake released;
        released.guid = snake->GetObjectGuid();
        released.weaponId = owned.weapon.id;
        released.untilMs = m_totalMs + lifeMs;
        m_snakes.push_back(released);
    }
    DressSnakes();
    m_petTimer = BONK_PET_CHECK_MS;
}

void BonkRun::DressSnakes()
{
    Map* map = m_player->GetMap();
    bool const frenzied = IsPetFrenzied();
    float const speed = GetSummonSpeedRate(GetStat(BONK_PASSIVE_MOVE_SPEED));
    for (Snake const& released : m_snakes)
    {
        OwnedWeapon const* owned = FindOwned(released.weaponId);
        Creature* snake = owned ? map->GetCreature(released.guid) : nullptr;
        if (!snake || !snake->IsAlive())
            continue;

        float const bite = GetWeaponDamage(*owned) * (frenzied ? GetFrenzyDamage() : 1.0f);
        float const pace = GetWeaponCooldown(*owned) / float(std::max(1u, owned->weapon.cooldownMs));
        float const scale = GetSummonLookScale(*owned, BONK_SNAKE_SCALE);
        if (snake->GetBaseRunSpeedRate() != speed)
            snake->SetBaseSpeedRate(MOVE_RUN, speed);
        snake->SetBaseWeaponDamage(BASE_ATTACK, MINDAMAGE, bite * 0.9f);
        snake->SetBaseWeaponDamage(BASE_ATTACK, MAXDAMAGE, bite * 1.1f);
        snake->UpdateDamagePhysical(BASE_ATTACK);
        snake->SetAttackTime(BASE_ATTACK, std::max(300u, uint32(BONK_SNAKE_ATTACK_MS * pace)));
        if (snake->GetObjectScale() != scale)
        {
            snake->SetObjectScale(scale);
            snake->UpdateModelData();
        }
        if (frenzied && !snake->HasAura(BONK_SPELL_BESTIAL_WRATH))
            snake->AddAura(BONK_SPELL_BESTIAL_WRATH);
        else if (!frenzied && snake->HasAura(BONK_SPELL_BESTIAL_WRATH))
            snake->RemoveAurasDueToSpell(BONK_SPELL_BESTIAL_WRATH);
    }
}

void BonkRun::UpdateSnakes()
{
    if (m_snakes.empty())
        return;
    Map* map = m_player->GetMap();
    m_snakes.erase(std::remove_if(m_snakes.begin(), m_snakes.end(), [this, map](Snake const& released)
    {
        Creature* snake = map->GetCreature(released.guid);
        if (snake && snake->IsAlive() && FindOwned(released.weaponId) && int32(released.untilMs - m_totalMs) > 0)
            return false;
        if (snake)
            snake->DespawnOrUnsummon();
        return true;
    }), m_snakes.end());
}

void BonkRun::DespawnSnakes()
{
    if (Map* map = m_player->FindMap())
        for (Snake const& released : m_snakes)
            if (Creature* snake = map->GetCreature(released.guid))
                snake->DespawnOrUnsummon();
    m_snakes.clear();
}

void BonkRun::ReleaseVipers(OwnedWeapon const& owned, float x, float y, float z)
{
    std::vector<Creature*> prey = GetMobsNear(x, y, BONK_VIPER_REACH * GetWeaponArea(owned));
    std::sort(prey.begin(), prey.end(), [x, y](Creature const* a, Creature const* b) { return a->GetDistance2d(x, y) < b->GetDistance2d(x, y); });
    uint32 const count = BONK_VIPERS_PER_TRAP + GetSpellCount(owned);
    float const speed = BONK_VIPER_SPEED * GetSummonSpeedRate(GetStat(BONK_PASSIVE_MOVE_SPEED));
    for (uint32 i = 0; i < count && i < prey.size(); ++i)
    {
        if (m_vipers.size() >= BONK_MAX_VIPERS)
            break;
        Creature* target = prey[i];
        if (!target->IsAlive())
            continue;
        s_nextHelperLevel = m_player->GetLevel();
        Creature* viper = m_player->SummonCreature(BONK_SNAKE, x, y, z, m_player->GetAngle(target), TEMPSUMMON_TIMED_DESPAWN,
            BONK_OBJECT_LIFETIME_SEC * IN_MILLISECONDS, false, 0, nullptr);
        if (!viper)
            continue;
        viper->SetOwnerGuid(m_player->GetObjectGuid());
        viper->SetUInt32Value(UNIT_CREATED_BY_SPELL, owned.weapon.spellId);
        viper->SetFactionTemplateId(m_player->GetFactionTemplateId());
        viper->SetFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_IMMUNE_TO_PLAYER | UNIT_FLAG_NOT_SELECTABLE);
        viper->SetInvincibilityHpThreshold(viper->GetMaxHealth());
        viper->SetObjectScale(GetSummonLookScale(owned, BONK_SNAKE_SCALE));
        viper->GetMotionMaster()->MovePoint(0, target->GetPositionX(), target->GetPositionY(), target->GetPositionZ(),
            MOVE_PATHFINDING | MOVE_RUN_MODE | MOVE_FORCE_DESTINATION, speed);

        Viper released;
        released.guid = viper->GetObjectGuid();
        released.target = target->GetObjectGuid();
        released.weaponId = owned.weapon.id;
        released.untilMs = m_totalMs + BONK_VIPER_LIFE_MS;
        released.moveMs = m_totalMs + BONK_VIPER_REPATH_MS;
        m_vipers.push_back(released);
    }
}

void BonkRun::UpdateVipers()
{
    if (m_vipers.empty())
        return;
    Map* map = m_player->GetMap();
    float const speed = BONK_VIPER_SPEED * GetSummonSpeedRate(GetStat(BONK_PASSIVE_MOVE_SPEED));
    for (auto itr = m_vipers.begin(); itr != m_vipers.end();)
    {
        Creature* viper = map->GetCreature(itr->guid);
        OwnedWeapon const* owned = FindOwned(itr->weaponId);
        Creature* target = map->GetCreature(itr->target);
        if (!viper || !owned)
        {
            if (viper)
                viper->DespawnOrUnsummon();
            itr = m_vipers.erase(itr);
            continue;
        }
        bool const arrived = target && target->IsAlive() && viper->GetDistance2d(target) <= BONK_VIPER_BITE_RANGE;
        bool const lost = !target || !target->IsAlive() || int32(itr->untilMs - m_totalMs) <= 0;
        if (arrived || lost)
        {
            BurstViper(*owned, viper, arrived ? target : nullptr);
            viper->DespawnOrUnsummon();
            itr = m_vipers.erase(itr);
            continue;
        }
        if (int32(itr->moveMs - m_totalMs) <= 0)
        {
            itr->moveMs = m_totalMs + BONK_VIPER_REPATH_MS;
            viper->GetMotionMaster()->MovePoint(0, target->GetPositionX(), target->GetPositionY(), target->GetPositionZ(),
                MOVE_PATHFINDING | MOVE_RUN_MODE | MOVE_FORCE_DESTINATION, speed);
        }
        ++itr;
    }
}

void BonkRun::BurstViper(OwnedWeapon const& owned, Creature* viper, Creature* bitten)
{
    if (bitten && m_mastery.entrapment.count(GetRootWeapon(owned.weapon)))
        if (BonkMobAI const* ai = dynamic_cast<BonkMobAI const*>(bitten->AI()))
            if (ai->GetKind() == BONK_SPAWN_NORMAL)
                ApplyKeyword(bitten, BONK_KEYWORD_FROZEN, 1, 0, 1.0f, owned.weapon.spellId);
    float const x = viper->GetPositionX(), y = viper->GetPositionY(), z = viper->GetPositionZ();
    PlayKitAt(ObjectGuid(), x, y, z, BONK_KIT_VIPER_BURST, true);
    if (owned.weapon.id == BONK_WEAPON_VENOM_BURST)
    {
        SpellEntry const* look = sSpellMgr.GetSpellEntry(owned.weapon.spellId);
        float const damage = GetWeaponDamage(owned);
        for (Creature* mob : GetMobsNear(x, y, BONK_VENOM_BURST_RADIUS * GetWeaponArea(owned)))
        {
            if (!mob->IsAlive())
                continue;
            if (look)
                DealShamanHit(look, owned.weapon.spellId, mob, damage);
            if (mob->IsAlive())
                ApplyWeaponKeyword(owned, mob, BONK_KEYWORD_POISON, BONK_VENOM_BURST_STACKS);
        }
    }
    StartKeywordCloud(owned, x, y, z);
}

void BonkRun::DespawnVipers()
{
    if (Map* map = m_player->FindMap())
        for (Viper const& released : m_vipers)
            if (Creature* viper = map->GetCreature(released.guid))
                viper->DespawnOrUnsummon();
    m_vipers.clear();
}

float BonkRun::GetHunterDamageMultiplier(SpellEntry const* spell, Unit const* victim) const
{
    if (!spell || !victim)
        return 1.0f;
    auto root = m_spellRoots.find(spell->Id);
    if (root == m_spellRoots.end() || root->second != BONK_WEAPON_EXPLOSIVE_TRAP)
        return 1.0f;
    return 1.0f + BONK_TRAP_POISON_BONUS * GetKeywordStacks(victim, BONK_KEYWORD_POISON);
}

bool BonkRun::GetHunterCloudKind(OwnedWeapon const& owned, KeywordCloudKind& kind) const
{
    if (!owned.weapon.HasFlag(BONK_WEAPON_FLAG_VIPERS))
        return false;
    kind.lifeMs = owned.weapon.durationMs;
    kind.pulseEveryMs = BONK_VIPER_CLOUD_PULSE_MS;
    kind.stacks = owned.weapon.applyStacks;
    kind.maxAlive = BONK_MAX_VIPER_CLOUDS;
    kind.lookSpellId = BONK_SPELL_VENOM_CLOUD_LOOK;
    return true;
}

void BonkRun::OnHunterCloudPulse(OwnedWeapon const& owned, KeywordCloud const& cloud)
{
    if (owned.weapon.id != BONK_WEAPON_CORROSIVE_VIPERS)
        return;
    for (Creature* mob : GetMobsNear(cloud.x, cloud.y, cloud.radius))
        if (mob->IsAlive())
            ApplyWeaponKeyword(owned, mob, BONK_KEYWORD_NATURE_VULNERABILITY, 1);
}

bool BonkRun::IsSnake(ObjectGuid const& guid) const
{
    return std::any_of(m_snakes.begin(), m_snakes.end(), [&guid](Snake const& released) { return released.guid == guid; });
}

void BonkRun::QueueShatter(OwnedWeapon const& owned, float x, float y, float z)
{
    PendingCast shatter;
    shatter.weaponId = owned.weapon.id;
    shatter.spellId = owned.weapon.spellId;
    shatter.leftMs = int32(owned.weapon.durationMs * GetWeaponDurationScale(owned));
    shatter.shatter = true;
    shatter.x = x;
    shatter.y = y;
    shatter.z = z;
    m_pendingCasts.push_back(std::move(shatter));
}

void BonkRun::Shatter(OwnedWeapon& owned, SpellEntry const* spellInfo, PendingCast const& cast)
{
    PlayKitAt(ObjectGuid(), cast.x, cast.y, cast.z, BONK_KIT_FROST_NOVA, true);
    float const damage = GetWeaponDamage(owned);
    for (Creature* mob : GetMobsNear(cast.x, cast.y, GetWeaponRadius(owned) * (1.0f + GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_TRAP_AREA) / 100.0f)))
        DealSpellHit(spellInfo, mob, damage);
}

void BonkRun::FormIcePath(OwnedWeapon const& owned)
{
    if (m_icePath.weaponId != owned.weapon.id)
        m_icePath = IcePath();
    m_icePath.weaponId = owned.weapon.id;
    m_icePath.leftMs = std::max(m_icePath.leftMs, int32(owned.weapon.durationMs * GetWeaponDurationScale(owned)));
    m_icePath.slowMs = 0;
}

void BonkRun::UpdateIcePath(uint32 diff)
{
    if (!m_icePath.weaponId)
        return;

    OwnedWeapon const* owned = FindOwned(m_icePath.weaponId);
    SpellEntry const* spellInfo = owned ? sSpellMgr.GetSpellEntry(owned->weapon.spellId) : nullptr;
    m_icePath.leftMs -= int32(diff);
    if (!spellInfo || m_icePath.leftMs <= 0 || !m_player->IsAlive())
    {
        m_icePath = IcePath();
        HideHeroRing(BonkHeroRing::IcePath);
        return;
    }

    float x, y, z;
    GetHeroPositionNow(m_player, x, y, z);
    float const radius = GetWeaponRadius(*owned);
    ShowHeroRing(BonkHeroRing::IcePath, radius);

    m_icePath.slowMs -= int32(diff);
    if (m_icePath.slowMs > 0)
        return;
    m_icePath.slowMs = BONK_ICE_PATH_SLOW_PULSE_MS;
    for (Creature* mob : GetMobsNear(x, y, radius))
        SlowInIcePath(mob, spellInfo);
}

void BonkRun::SlowInIcePath(Creature* mob, SpellEntry const* spellInfo)
{
    SlowNormalMob(mob, spellInfo, nullptr, BONK_ICE_PATH_SLOW_MS);
}

void BonkRun::SlowNormalMob(Creature* mob, SpellEntry const* spellInfo, int32 const* points, int32 durationMs)
{
    BonkMobAI const* ai = dynamic_cast<BonkMobAI const*>(mob->AI());
    if (!ai || ai->GetKind() != BONK_SPAWN_NORMAL || !mob->IsAlive())
        return;

    if (SpellAuraHolder* holder = mob->GetSpellAuraHolder(spellInfo->Id, m_player->GetObjectGuid()))
    {
        holder->SetAuraMaxDuration(durationMs);
        holder->RefreshHolder();
        return;
    }

    SpellAuraHolder* holder = CreateSpellAuraHolder(spellInfo, mob, m_player, m_player);
    for (uint32 i = 0; i < MAX_EFFECT_INDEX; ++i)
        if (spellInfo->EffectApplyAuraName[i] == SPELL_AURA_MOD_DECREASE_SPEED)
        {
            int32 slow = points ? *points : 0;
            Aura* aura = CreateAura(spellInfo, SpellEffectIndex(i), points ? &slow : nullptr, holder, mob, m_player);
            aura->SetPositive(false);
            holder->AddAura(aura, SpellEffectIndex(i));
        }
    if (holder->IsEmptyHolder())
    {
        delete holder;
        return;
    }
    holder->SetPermanent(false);
    holder->SetAuraMaxDuration(durationMs);
    holder->SetAuraDuration(durationMs);
    mob->AddSpellAuraHolder(holder);
}

void BonkRun::ApplyMasterySlow(Creature* mob, float percent)
{
    SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(BONK_SPELL_ARCANE_SLOW);
    int32 const points = -int32(percent + 0.5f);
    if (spellInfo && points < 0)
        SlowNormalMob(mob, spellInfo, &points, BONK_ARCANE_SLOW_MS);
}

void BonkRun::ClearHunterEvolutions()
{
    m_arrowStorms.clear();
    m_flares.clear();
    m_flareSplitTimes.clear();
    m_shardBurstTimes.clear();
    m_steady = false;
    m_steadySinceMs = m_totalMs;
    m_venomBoltTimes.clear();
    ClearKeywordClouds();
    m_venomCloudTimes.clear();
    m_icePath = IcePath();
    HideHeroRing(BonkHeroRing::IcePath);
    m_pendingSlows.clear();
    m_stampedeTimer = BONK_STAMPEDE_FIRST_MS;
    m_plagueTimer = BONK_PLAGUE_PULSE_MS;
    m_screechTimer = 0;
    m_frenzyGlowMs = 0;
}

float BonkRun::GetBuffPower() const
{
    float power = 0.0f;
    for (OwnedWeapon const& owned : m_weapons)
        if (owned.weapon.behavior == BONK_BEHAVIOR_BUFF && m_player->HasAura(owned.weapon.spellId))
            power += owned.weapon.behaviorValue * (1.0f + owned.damageBonus / 100.0f);
    return power;
}

bool BonkRun::IsReckless() const
{
    for (OwnedWeapon const& owned : m_weapons)
        if (owned.weapon.behavior == BONK_BEHAVIOR_BUFF && owned.weapon.HasFlag(BONK_WEAPON_FLAG_ALWAYS_CRIT) &&
            m_player->HasAura(owned.weapon.spellId))
            return true;
    return false;
}

void BonkRun::SpreadFrom(Creature const* dead)
{
    uint32 const now = WorldTimer::getMSTime();
    FiringWeapon firing(m_player->GetBonkPlayer());
    for (auto& owned : m_weapons)
    {
        BonkWeapon const& weapon = owned.weapon;
        if (weapon.behavior != BONK_BEHAVIOR_SPREAD)
            continue;

        auto carrier = owned.carriers.find(dead->GetObjectGuid());
        if (carrier == owned.carriers.end())
            continue;
        bool const carried = int32(carrier->second - now) > 0;
        owned.carriers.erase(carrier);

        if (!carried || (owned.rank < BONK_SPREAD_RANK && !weapon.evolvesFrom))
            continue;
        SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(weapon.spellId);
        if (!spellInfo)
            continue;

        uint32 const jumps = uint32(weapon.behaviorValue) + GetSpellCount(owned);
        uint32 spread = 0;
        for (Creature* next : GetMobsInRange(BONK_SPREAD_RADIUS * GetWeaponArea(owned), dead))
        {
            if (spread >= jumps)
                break;
            auto itr = owned.carriers.find(next->GetObjectGuid());
            if (itr != owned.carriers.end() && int32(itr->second - now) > 0)
                continue;
            StrikeWith(owned, spellInfo, next, 1.0f);
            ++spread;
        }
    }
}

void BonkRun::FireWeapon(OwnedWeapon& owned)
{
    BonkWeapon const& weapon = owned.weapon;
    SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(weapon.spellId);
    if (!spellInfo)
        return;
    owned.killed = false;
    RollCastCharges(owned);
    TalentCastScope talentCast(*this, owned);

    owned.firedByClass = true;
    if (FirePriestSpell(owned, spellInfo) || FireRogueSpell(owned, spellInfo) || FirePaladinSpell(owned, spellInfo) || FireWarlockSpell(owned, spellInfo) ||
        FireDruidSpell(owned, spellInfo))
    {
        if (owned.timer == int32(GetWeaponCooldown(owned)))
            OnTalentCastDone(owned);
        if (owned.killed && weapon.HasFlag(BONK_WEAPON_FLAG_RESET_ON_KILL))
            owned.timer = std::min<int32>(owned.timer, BONK_CLEARCAST_DELAY_MS);
        return;
    }
    owned.firedByClass = false;

    if (weapon.IsShieldBlock() || weapon.behavior == BONK_BEHAVIOR_WARD)
    {
        if (m_player->IsAlive())
        {
            AddSpellShield(GetShieldGain(owned));
            if (weapon.IsShieldBlock())
                m_player->SendPlaySpellVisualKit(BONK_KIT_SHIELD_BLOCK);
        }
        owned.timer = GetWeaponCooldown(owned);
        return;
    }

    if (weapon.behavior == BONK_BEHAVIOR_DEEP_WOUNDS || weapon.behavior == BONK_BEHAVIOR_MAELSTROM || weapon.IsBlink())
    {
        owned.timer = BONK_PASSIVE_TRIGGER_IDLE_MS;
        return;
    }

    if (weapon.behavior == BONK_BEHAVIOR_LIGHTNING_SHIELD)
    {
        ChargeLightningShield();
        ZapNearestWithLightningShield(owned);
        owned.timer = GetWeaponCooldown(owned);
        return;
    }

    if (weapon.behavior == BONK_BEHAVIOR_BLOOD_AURA)
    {
        PulseBloodAura(owned);
        owned.timer = GetWeaponCooldown(owned);
        return;
    }

    if (weapon.behavior == BONK_BEHAVIOR_ROLLING_THUNDER && !IsThunderReady(owned))
    {
        owned.timer = BONK_PASSIVE_TRIGGER_POLL_MS;
        return;
    }

    float const areaScale = GetWeaponArea(owned);
    for (uint32 spellId : { weapon.spellId, weapon.altSpellId })
    {
        if (!spellId)
            continue;
        BonkPlayer::SpellTweak& tweak = m_player->GetBonkPlayer()->TweakSpell(spellId);
        tweak.areaScale = areaScale * (weapon.target == BONK_TARGET_GROUND && spellId == weapon.spellId ? weapon.SpellRadiusScale() : 1.0f);
        tweak.chainBonus = 0;
        tweak.jumpRadius = weapon.HasFlag(BONK_WEAPON_FLAG_LONG_JUMPS) ? BONK_LONG_JUMP_RADIUS : CHAIN_SPELL_JUMP_RADIUS;
        tweak.durationMs = weapon.durationMs;
        tweak.durationScale = GetWeaponDurationScale(owned);
        tweak.weaponDamage = weapon.weaponDamage ? std::max(1, int32(GetWeaponDamage(owned))) : 0;
        tweak.tickMs = weapon.tickMs;
        tweak.tickScale = 1.0f / GetWeaponHasteRate(owned);
        tweak.normalEnemiesOnly = weapon.HasFlag(BONK_WEAPON_FLAG_NORMAL_ONLY);
        tweak.oneTargetPerCast = weapon.target == BONK_TARGET_SELF_AREA;
    }
    BonkPlayer::SpellTweak& tweak = m_player->GetBonkPlayer()->TweakSpell(weapon.spellId);
    uint32 const now = WorldTimer::getMSTime();

    if (weapon.behavior == BONK_BEHAVIOR_ICE_NOVA)
    {
        owned.timer = BurstIceNovas(owned, spellInfo) ? GetWeaponCooldown(owned) : 250;
        return;
    }

    if (weapon.behavior == BONK_BEHAVIOR_ARCANE_BARRAGE && m_player->IsMoving() && IsBlinkDash())
    {
        BankMissiles(owned);
        owned.timer = GetWeaponCooldown(owned);
        return;
    }

    if (weapon.behavior == BONK_BEHAVIOR_BUFF)
    {
        if (m_player->IsAlive())
        {
            FiringWeapon firing(m_player->GetBonkPlayer());
            m_player->CastSpell(m_player, spellInfo, true);
        }
        owned.timer = GetWeaponCooldown(owned);
        return;
    }

    if (weapon.behavior == BONK_BEHAVIOR_PET)
    {
        UpdatePets(owned);
        owned.timer = GetWeaponCooldown(owned);
        return;
    }

    if (weapon.behavior == BONK_BEHAVIOR_WRATH)
    {
        UpdatePets(owned);
        bool const howled = Howl(owned);
        if (howled && weapon.healPct > 0.0f && m_player->IsAlive())
            m_player->DealHeal(m_player, ReduceHealing(std::max(1u, uint32(m_player->GetMaxHealth() * weapon.healPct / 100.0f))), spellInfo);
        owned.timer = howled ? GetWeaponCooldown(owned) : 250;
        return;
    }

    if ((weapon.behavior == BONK_BEHAVIOR_TRAP && weapon.target == BONK_TARGET_SELF) || weapon.behavior == BONK_BEHAVIOR_ICE_PATH)
    {
        if (GetMobsInRange(BONK_TRAP_AWARE_RANGE).empty())
        {
            owned.timer = 250;
            return;
        }
        if (weapon.behavior == BONK_BEHAVIOR_ICE_PATH)
            FormIcePath(owned);
        else
            DropTraps(owned);
        owned.timer = GetWeaponCooldown(owned);
        return;
    }

    if (weapon.IsRevenge() && !WasStruckRecently())
    {
        owned.timer = 100;
        return;
    }

    bool const reachGrows = weapon.target == BONK_TARGET_SELF_AREA || weapon.target == BONK_TARGET_CONE || weapon.behavior == BONK_BEHAVIOR_CLEAVE ||
        weapon.IsMeleeStrike();
    bool const thrown = weapon.behavior == BONK_BEHAVIOR_TRAP && weapon.target == BONK_TARGET_GROUND;
    bool const radial = weapon.target == BONK_TARGET_SELF_AREA || weapon.target == BONK_TARGET_CONE;
    float const range = thrown ? BONK_TRAP_THROW_RANGE : radial ? weapon.radius * areaScale : weapon.range * (reachGrows ? areaScale : 1.0f);
    std::vector<Creature*> mobs = GetMobsInRange(range);

    if (weapon.target == BONK_TARGET_RANDOM)
    {
        for (auto itr = owned.recentTargets.begin(); itr != owned.recentTargets.end();)
        {
            if (now - itr->second > BONK_DOT_RETARGET_MS)
                itr = owned.recentTargets.erase(itr);
            else
                ++itr;
        }
        mobs.erase(std::remove_if(mobs.begin(), mobs.end(), [&](Creature* mob)
        {
            return mob->HasAura(weapon.spellId) || owned.recentTargets.count(mob->GetObjectGuid());
        }), mobs.end());
    }
    else if (weapon.target == BONK_TARGET_STRONGEST)
        SortStrongestFirst(mobs);
    else if (weapon.target == BONK_TARGET_FARTHEST)
        std::reverse(mobs.begin(), mobs.end());
    else if (weapon.IsFireBlast() || weapon.behavior == BONK_BEHAVIOR_LAVA_BURST)
        SortMostBurningFirst(mobs);
    else if (weapon.behavior == BONK_BEHAVIOR_EARTH_SHOCK)
        SortMostStaticFirst(mobs);

    if (weapon.killBelowPct > 0.0f)
        std::stable_partition(mobs.begin(), mobs.end(), [&](Creature* mob) { return CanKill(weapon, mob); });

    uint32 const swept = weapon.HasFlag(BONK_WEAPON_FLAG_SWEEP) ? SweepExecute(owned, spellInfo, range) : 0;
    if (mobs.empty())
    {
        owned.timer = swept ? GetWeaponCooldown(owned) : 250;
        return;
    }
    if (weapon.IsRevenge())
        m_struck = false;

    if (weapon.behavior == BONK_BEHAVIOR_ORB)
    {
        LaunchOrb(owned);
        owned.timer = GetWeaponCooldown(owned);
        return;
    }

    if (weapon.IsPyroblast())
    {
        owned.timer = HurlPyroblasts(owned, spellInfo, std::move(mobs)) ? GetWeaponCooldown(owned) : 250;
        return;
    }

    ++owned.casts;
    SpellEntry const* castInfo = spellInfo;
    float castShare = 1.0f;
    if (weapon.altEvery && weapon.altSpellId && owned.casts % weapon.altEvery == 0)
        if (SpellEntry const* altInfo = sSpellMgr.GetSpellEntry(weapon.altSpellId))
        {
            castInfo = altInfo;
            castShare = weapon.altDamage;
        }

    optional<int32> basePoints[MAX_EFFECT_INDEX];
    GetBasePoints(owned, castInfo, castShare, basePoints);

    FiringWeapon firing(m_player->GetBonkPlayer());

    auto castAgain = [&]()
    {
        uint32 const pulses = std::min(GetSpellCount(owned), BONK_MAX_COUNT_PULSES);
        for (uint32 i = 1; i <= pulses; ++i)
        {
            PendingCast again;
            again.weaponId = weapon.id;
            again.spellId = castInfo->Id;
            again.leftMs = int32(i * BONK_COUNT_RECAST_MS);
            again.recast = true;
            m_pendingCasts.push_back(again);
        }
    };

    if (weapon.target == BONK_TARGET_SELF_AREA)
    {
        m_vengeanceShare = TakeVengeanceShare(owned);
        if (!SwingWide(owned, castInfo, areaScale))
            CastSelfArea(owned, castInfo, areaScale);
        m_vengeanceShare = 1.0f;
        castAgain();

        if (weapon.IsWhirlwind())
            SpinWhirlwind(owned, castInfo);
        if (weapon.IsRevenge())
            OnRevenge(owned);
        if (weapon.behavior == BONK_BEHAVIOR_DEMORALIZING_SHOUT)
            DemoralizingShout(owned, castInfo, mobs);

        if (weapon.behavior == BONK_BEHAVIOR_ECHO)
        {
            PendingCast echo;
            echo.weaponId = weapon.id;
            echo.spellId = castInfo->Id;
            echo.leftMs = int32(weapon.behaviorValue);
            echo.echo = true;
            m_pendingCasts.push_back(echo);
        }

        if (weapon.behavior == BONK_BEHAVIOR_SPIN && weapon.behaviorValue >= 100.0f)
        {
            uint32 const every = uint32(weapon.behaviorValue);
            uint32 const length = uint32(weapon.durationMs * tweak.durationScale);
            for (uint32 at = every; at <= length; at += every)
            {
                PendingCast pulse;
                pulse.weaponId = weapon.id;
                pulse.spellId = castInfo->Id;
                pulse.leftMs = int32(at);
                pulse.selfArea = true;
                m_pendingCasts.push_back(pulse);
            }
        }

        if (weapon.behavior == BONK_BEHAVIOR_DELAYED && weapon.altSpellId)
        {
            PendingCast wave;
            wave.weaponId = weapon.id;
            wave.spellId = weapon.altSpellId;
            wave.leftMs = int32(weapon.behaviorValue);
            wave.selfArea = true;
            m_pendingCasts.push_back(wave);
        }

        if (weapon.behavior == BONK_BEHAVIOR_SHIELD_PER_HIT && m_player->IsAlive())
            AddSpellShield(uint32(m_player->GetMaxHealth() * weapon.behaviorValue / 100.0f * mobs.size()));

        if (weapon.behavior == BONK_BEHAVIOR_FREEZE && weapon.altSpellId)
            for (Creature* mob : mobs)
                if (m_player->HasInArc(mob, BONK_FREEZE_ARC))
                    m_player->CastSpell(mob, weapon.altSpellId, true);
    }
    else if (weapon.target == BONK_TARGET_CONE)
    {
        std::vector<Creature*> const cone = GetMobsInCone(owned, range);
        for (Creature* mob : cone)
            StrikeWith(owned, castInfo, mob, castShare);
        if (cone.empty())
        {
            owned.timer = 250;
            return;
        }
        castAgain();
    }
    else if (weapon.target == BONK_TARGET_GROUND)
    {
        mobs.erase(std::remove_if(mobs.begin(), mobs.end(), [&](Creature* mob)
        {
            return !m_player->IsWithinLOSInMap(mob);
        }), mobs.end());

        if (weapon.applies == BONK_KEYWORD_HUNTERS_MARK)
        {
            std::vector<Creature*> unmarked;
            for (Creature* mob : mobs)
                if (!GetKeywordStacks(mob, BONK_KEYWORD_HUNTERS_MARK))
                    unmarked.push_back(mob);
            if (!unmarked.empty())
                mobs.swap(unmarked);
        }

        bool const keywordOnly = weapon.damageEffectIndex < 0 && !weapon.weaponDamage && weapon.applies != BONK_KEYWORD_NONE;
        float const radius = weapon.groundRadius * areaScale;

        uint32 const drops = 1 + GetSpellCount(owned) + GetWarlockExtraDrops(owned);
        std::vector<Creature*> const spots = PickGroundSpots(mobs, radius, drops);
        if (spots.empty())
        {
            owned.timer = 250;
            return;
        }
        for (Creature* spot : spots)
        {
            if (weapon.behavior == BONK_BEHAVIOR_TRAP)
            {
                ThrowTrap(owned, spot->GetPositionX(), spot->GetPositionY(), spot->GetPositionZ());
                continue;
            }

            float const x = spot->GetPositionX(), y = spot->GetPositionY(), z = spot->GetPositionZ();
            if (keywordOnly)
                ShowMissileAt(m_player, castInfo, x, y, z);
            else if (weapon.behavior == BONK_BEHAVIOR_ARROW_STORM)
                StartArrowStorm(owned, castInfo, x, y, z);
            else if (weapon.behavior == BONK_BEHAVIOR_GRAVITY_PULL)
                GravityPull(owned, castInfo, x, y, z, radius);
            else if (weapon.behavior == BONK_BEHAVIOR_FIREWALK)
                WalkFire(owned, castInfo, x, y, z, radius);
            else
                CastAtGround(m_player, castInfo, basePoints, x, y, z);
            if (weapon.behavior == BONK_BEHAVIOR_FLARE)
                LightFlare(owned, x, y, z, radius);
            OnMageGroundDrop(owned, x, y, z);
            OnWarlockGroundDrop(owned, x, y, z);

            PendingKeyword keyword;
            if (keywordOnly && GetWeaponKeyword(owned, keyword))
            {
                std::vector<Creature*> inside = GetMobsInRange(radius, spot);
                inside.push_back(spot);
                for (Creature* mob : inside)
                    ApplyKeyword(mob, keyword.keyword, keyword.stacks, keyword.durationMs, keyword.damageScale, keyword.spellId);
            }

            if (weapon.behavior == BONK_BEHAVIOR_DELAYED && weapon.altSpellId)
            {
                PendingCast burst;
                burst.weaponId = weapon.id;
                burst.spellId = weapon.altSpellId;
                burst.leftMs = int32(weapon.behaviorValue);
                burst.x = spot->GetPositionX();
                burst.y = spot->GetPositionY();
                burst.z = spot->GetPositionZ();
                m_pendingCasts.push_back(burst);
            }
        }
    }
    else if (weapon.target == BONK_TARGET_LINE)
    {
        mobs.erase(std::remove_if(mobs.begin(), mobs.end(), [&](Creature* mob) { return !m_player->IsWithinLOSInMap(mob); }), mobs.end());
        std::vector<Creature*> marked;
        for (Creature* mob : mobs)
            if (GetKeywordStacks(mob, BONK_KEYWORD_HUNTERS_MARK))
                marked.push_back(mob);
        uint32 const shots = 1 + GetSpellCount(owned);
        std::vector<Creature*> aims = PickGroundSpots(marked, BONK_LINE_GROUP_RADIUS, shots);
        if (aims.size() < shots)
            for (Creature* aim : PickGroundSpots(mobs, BONK_LINE_GROUP_RADIUS, shots))
                if (aims.size() < shots && std::find(aims.begin(), aims.end(), aim) == aims.end())
                    aims.push_back(aim);

        std::vector<Creature*> struck;
        for (Creature* aim : aims)
            for (Creature* mob : GetMobsInLine(owned, range, m_player->GetAngle(aim)))
                if (std::find(struck.begin(), struck.end(), mob) == struck.end() && m_player->IsWithinLOSInMap(mob))
                {
                    StrikeWith(owned, castInfo, mob, castShare);
                    struck.push_back(mob);
                }
        if (struck.empty())
        {
            owned.timer = 250;
            return;
        }
        if (weapon.behavior == BONK_BEHAVIOR_CHAIN_DETONATION)
            QueueDetonations(owned, castInfo, castShare * weapon.behaviorValue, std::move(struck));
    }
    else
    {
        if (weapon.target == BONK_TARGET_RANDOM)
            for (size_t i = mobs.size(); i > 1; --i)
                std::swap(mobs[i - 1], mobs[urand(0, uint32(i - 1))]);

        if (weapon.behavior == BONK_BEHAVIOR_SPREAD)
            for (auto itr = owned.carriers.begin(); itr != owned.carriers.end();)
            {
                if (int32(itr->second - now) <= 0)
                    itr = owned.carriers.erase(itr);
                else
                    ++itr;
            }

        PreferMarked(mobs);
        BonkProjectileInfo const* projectile = sBonkMgr.GetProjectile(castInfo->Id);
        bool const bloodbath = IsBloodbathing(owned);
        uint32 const targets = bloodbath ? uint32(mobs.size()) : GetWeaponTargets(owned);
        std::vector<Creature*> struck;
        for (Creature* mob : mobs)
        {
            if (struck.size() >= targets)
                break;
            if (!m_player->IsWithinLOSInMap(mob))
                continue;
            if (projectile)
                LaunchProjectiles(owned, *projectile, castInfo, castShare, m_player, mob);
            else if (weapon.behavior == BONK_BEHAVIOR_AVENGERS_SHIELD)
                ThrowShield(owned, castInfo, mob, castShare);
            else
            {
                StrikeWith(owned, castInfo, mob, castShare);
                if (weapon.behavior == BONK_BEHAVIOR_RICOCHET)
                    QueueRicochet(owned, castInfo, mob, m_player, castShare, {}, uint32(weapon.behaviorValue));
            }
            if (weapon.target == BONK_TARGET_RANDOM)
                owned.recentTargets[mob->GetObjectGuid()] = now;
            struck.push_back(mob);
        }
        uint32 const fired = uint32(struck.size());

        bool const cleave = weapon.behavior == BONK_BEHAVIOR_CLEAVE;
        bool const pierce = weapon.IsAimed() && !weapon.chains && weapon.behavior != BONK_BEHAVIOR_SPREAD && !projectile;
        auto strikeNear = [&](uint32 victims, float share, float radius)
        {
            for (size_t i = 0; i < fired; ++i)
            {
                uint32 hit = 0;
                for (Creature* next : GetMobsInRange(radius, struck[i]))
                {
                    if (hit >= victims)
                        break;
                    if (std::find(struck.begin(), struck.end(), next) != struck.end())
                        continue;
                    StrikeWith(owned, castInfo, next, share * castShare);
                    if (weapon.target == BONK_TARGET_RANDOM)
                        owned.recentTargets[next->GetObjectGuid()] = now;
                    struck.push_back(next);
                    ++hit;
                }
            }
        };
        uint32 const victims = cleave ? 1 + weapon.baseJumps : pierce ? weapon.baseJumps : 0;
        if (victims)
            strikeNear(victims, cleave ? weapon.behaviorValue : 1.0f, BONK_CLEAVE_RADIUS * (cleave ? areaScale : 1.0f));
        float const spellCleave = GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_CLEAVE) / 100.0f;
        if (spellCleave > 0.0f && !projectile)
            strikeNear(BONK_SPELL_CLEAVE_TARGETS, spellCleave, BONK_CLEAVE_RADIUS);
        if ((victims || spellCleave > 0.0f) && weapon.weaponDamage)
            tweak.weaponDamage = std::max(1, int32(GetWeaponDamage(owned)));

        if (!fired)
        {
            owned.timer = 250;
            return;
        }
        SwingWeapon(owned);
        if (weapon.behavior != BONK_BEHAVIOR_AVENGERS_SHIELD)
            ShowStrikeImpact(castInfo, struck.front());
        if (weapon.behavior == BONK_BEHAVIOR_BLOODTHIRST)
            HealFromStrikes(owned, spellInfo, fired);
        if (bloodbath)
            ShowBloodbath();
    }

    if (weapon.healPct > 0.0f && weapon.behavior != BONK_BEHAVIOR_BLOODTHIRST && weapon.behavior != BONK_BEHAVIOR_DEMORALIZING_SHOUT && m_player->IsAlive())
        m_player->DealHeal(m_player, ReduceHealing(std::max(1u, uint32(m_player->GetMaxHealth() * weapon.healPct / 100.0f))), spellInfo);

    owned.timer = GetWeaponCooldown(owned);
    OnPriestCast(owned);
    if (weapon.behavior == BONK_BEHAVIOR_ROLLING_THUNDER)
        SpendThunder(owned);

    OnTalentCastDone(owned);
    bool const clearcast = m_mastery.clearcasting > 0.0f && roll_chance_f(m_mastery.clearcasting);
    if (clearcast && m_mastery.Special(BONK_SPECIAL_CLEARCASTING_BOOST) > 0.0f)
        m_clearcastBoostReady = true;
    if (clearcast || (owned.killed && weapon.HasFlag(BONK_WEAPON_FLAG_RESET_ON_KILL)))
        owned.timer = std::min<int32>(owned.timer, BONK_CLEARCAST_DELAY_MS);
}

void BonkRun::ResetOnKill(uint32 spellId)
{
    for (OwnedWeapon& owned : m_weapons)
        if (owned.weapon.spellId == spellId && owned.weapon.HasFlag(BONK_WEAPON_FLAG_RESET_ON_KILL))
        {
            owned.timer = std::min<int32>(owned.timer, BONK_CLEARCAST_DELAY_MS);
            owned.killed = true;
        }
}

bool BonkRun::HasBehavior(BonkWeaponBehavior behavior) const
{
    return std::any_of(m_weapons.begin(), m_weapons.end(), [behavior](OwnedWeapon const& owned) { return owned.weapon.behavior == behavior; });
}

void BonkRun::CastSelfArea(OwnedWeapon& owned, SpellEntry const* spellInfo, float areaScale)
{
    float const share = spellInfo->Id == owned.weapon.spellId ? 1.0f : owned.weapon.altDamage;
    FiringWeapon firing(m_player->GetBonkPlayer());
    if (owned.weapon.IsWhirlwind())
        OnWhirlwindSpin(owned);

    if (spellInfo->EffectImplicitTargetA[EFFECT_INDEX_0] == TARGET_UNIT_ENEMY)
    {
        uint32 struck = 0;
        Creature* first = nullptr;
        for (Creature* mob : GetMobsInRange(owned.weapon.radius * areaScale))
            if (m_player->IsWithinLOSInMap(mob))
            {
                OnAroundStrike(owned, mob);
                StrikeWith(owned, spellInfo, mob, share);
                if (!first)
                    first = mob;
                ++struck;
            }
        if (first)
            ShowStrikeImpact(spellInfo, first);
        OnAroundCast(owned, spellInfo, struck);
        OnMageSelfArea(owned);
        return;
    }

    bool const own = spellInfo->Id == owned.weapon.spellId;
    m_player->GetBonkPlayer()->TweakSpell(spellInfo->Id).areaScale = areaScale * (own ? owned.weapon.SpellRadiusScale() : 1.0f);
    optional<int32> basePoints[MAX_EFFECT_INDEX];
    GetBasePoints(owned, spellInfo, share, basePoints);
    m_player->CastCustomSpell(m_player, spellInfo, basePoints[0], basePoints[1], basePoints[2], true);
    // The stock Whirlwind Effect spell (15576) leaves a meaningless permanent aura; strip it.
    if (spellInfo->Id == 15576)
        m_player->RemoveAurasDueToSpell(15576);
    ShowAreaImpact(spellInfo, owned.weapon.radius * areaScale);
    if (owned.weapon.HasFlag(BONK_WEAPON_FLAG_KNOCKBACK))
        for (Creature* mob : GetMobsInRange(owned.weapon.radius * areaScale))
            KnockBack(mob);
    OnMageSelfArea(owned);
}

void BonkRun::ShowStrike(Unit* caster, SpellEntry const* spellInfo, Unit* target) const
{
    ShowStrikeOn(caster, spellInfo, target);
}


void BonkRun::ShowSwing(SpellEntry const* look, Unit* target) const
{
    ShowSwingOn(m_player, look, target);
}

void BonkRun::ScaleRadius(SpellEntry const* spellInfo, float radius)
{
    float const own = GetSpellRadiusOf(spellInfo);
    m_player->GetBonkPlayer()->TweakSpell(spellInfo->Id).areaScale = own > 0.0f ? radius / own : 1.0f;
}

void BonkRun::UpdatePendingCasts(uint32 diff)
{
    if (m_wardBurst)
    {
        m_wardBurst = false;
        for (OwnedWeapon& owned : m_weapons)
            if (owned.weapon.behavior == BONK_BEHAVIOR_WARD && owned.weapon.altSpellId)
                if (SpellEntry const* info = sSpellMgr.GetSpellEntry(owned.weapon.altSpellId))
                    CastSelfArea(owned, info, GetWeaponArea(owned));
    }

    Map* map = m_player->GetMap();

    if (m_pendingCasts.empty())
        return;

    std::vector<PendingCast> due;
    for (auto itr = m_pendingCasts.begin(); itr != m_pendingCasts.end();)
    {
        itr->leftMs -= int32(diff);
        if (itr->leftMs > 0)
        {
            ++itr;
            continue;
        }
        due.push_back(*itr);
        itr = m_pendingCasts.erase(itr);
    }

    for (PendingCast const& cast : due)
    {
        if (cast.releaseLook)
        {
            SendBonkPropGone(m_player, cast.prop);
            continue;
        }

        if (cast.kit)
        {
            PlayKitAt(cast.target, cast.x, cast.y, cast.z, cast.kit, true);
            continue;
        }

        OwnedWeapon* owned = FindOwned(cast.weaponId);
        SpellEntry const* info = sSpellMgr.GetSpellEntry(cast.spellId);
        if (!owned || !info || !m_player->IsAlive())
        {
            if (cast.springTrap)
                SendBonkPropGone(m_player, cast.prop);
            m_heldShotSources.erase(cast.source);
            continue;
        }

        if (cast.springTrap)
        {
            ShowTrapSprung(*owned, cast.prop, cast.x, cast.y, cast.z);
            SpringTrap(*owned, cast.x, cast.y, cast.z);
            continue;
        }

        if (cast.volatileEcho)
        {
            ShowTrapSprung(*owned, 0, cast.x, cast.y, cast.z);
            SpringTrap(*owned, cast.x, cast.y, cast.z, BONK_VOLATILE_ECHO_SHARE, true);
            continue;
        }

        if (cast.recast)
        {
            float const area = GetWeaponArea(*owned);
            if (owned->weapon.target == BONK_TARGET_CONE)
            {
                float const share = info->Id == owned->weapon.spellId ? 1.0f : owned->weapon.altDamage;
                FiringWeapon firing(m_player->GetBonkPlayer());
                for (Creature* mob : GetMobsInCone(*owned, owned->weapon.radius * area))
                    StrikeWith(*owned, info, mob, share);
            }
            else
                CastSelfArea(*owned, info, area);
            continue;
        }

        if (cast.field)
        {
            float const radius = GetWeaponRadius(*owned) * (1.0f + GetSpellUpgrade(*owned, BONK_SPELL_UPGRADE_TRAP_AREA) / 100.0f);
            float const damage = GetWeaponDamage(*owned) * cast.share;
            for (ObjectGuid const& guid : GetEnemyGuids())
                if (Creature* mob = map->GetCreature(guid))
                    if (mob->IsAlive() && mob->GetDistance2d(cast.x, cast.y) <= radius)
                        DealSpellHit(info, mob, damage);
            continue;
        }

        if (cast.pounce)
        {
            Creature* pet = map->GetCreature(cast.source);
            Creature* prey = map->GetCreature(cast.target);
            BonkPetFamily const* family = GetPetFamily(*owned);
            if (!pet || !pet->IsAlive() || !family)
                continue;
            m_petStates[cast.source].busyUntilMs = 0;
            if (prey && prey->IsAlive())
            {
                for (BonkPetAbility const& ability : family->abilities)
                    if (ability.kind == BONK_PET_ABILITY_POUNCE)
                    {
                        if (pet->CanReachWithMeleeAutoAttack(prey, BONK_POUNCE_GIVE))
                            PetStrike(*owned, pet, prey, ability);
                        break;
                    }
                pet->AI()->AttackStart(prey);
            }
            continue;
        }

        if (cast.petCleave)
        {
            Creature* pet = map->GetCreature(cast.source);
            float const damage = GetPetCleaveDamage(*owned);
            if (!pet || !pet->IsAlive() || damage <= 0.0f)
                continue;
            for (Creature* mob : GetMobsInRange(BONK_FRENZY_REACH * GetSummonReach(*owned), pet))
                if (mob->GetObjectGuid() != cast.target && pet->HasInArc(mob, BONK_FRENZY_ARC))
                    DealSpellHit(info, mob, damage, pet);
            continue;
        }

        if (cast.echo)
        {
            CastSelfArea(*owned, info, GetWeaponArea(*owned) * BONK_ECHO_AREA);
            continue;
        }

        if (cast.selfArea)
        {
            float scale = GetWeaponArea(*owned);
            if (info->Id != owned->weapon.spellId)
                if (float const own = GetSpellRadiusOf(info))
                    scale *= owned->weapon.radius * BONK_ECHO_AREA / own;
            CastSelfArea(*owned, info, scale);
            continue;
        }

        if (cast.ricochet)
        {
            Ricochet(*owned, info, cast);
            continue;
        }

        if (cast.trickShot)
        {
            FireTrickShot(*owned, info, cast);
            continue;
        }

        if (cast.detonate)
        {
            Detonate(*owned, info, cast);
            continue;
        }

        if (cast.flareSplit)
        {
            FireFlareSplit(*owned, info, cast);
            continue;
        }

        if (cast.shardBurst)
        {
            ShardBurst(*owned, info, cast);
            continue;
        }

        if (cast.explosiveArrow)
        {
            ExplodeArrow(*owned, info, cast);
            continue;
        }

        if (cast.venomBolts)
        {
            FireVenomBolts(*owned, info, cast);
            continue;
        }

        if (cast.keywordCloud)
        {
            StartKeywordCloud(*owned, cast.x, cast.y, cast.z);
            continue;
        }

        if (cast.bomblet)
        {
            Bomblet(*owned, info, cast);
            continue;
        }

        if (cast.shatter)
        {
            Shatter(*owned, info, cast);
            continue;
        }

        if (cast.wakeOfBlades || cast.aftershock || cast.chainExecution || cast.shieldThrow)
        {
            ResolveWarriorCast(*owned, info, cast);
            continue;
        }

        if (cast.blinkLanding || cast.blinkChill || cast.pyroblastSplash || cast.iceShard || cast.frostShatter || cast.livingBomb || cast.meteor ||
            cast.phaseRush || cast.presenceOfMind)
        {
            ResolveMageCast(*owned, info, cast);
            continue;
        }

        if (cast.windfury || cast.staticDischarge || cast.maelstrom)
        {
            ResolveShamanCast(*owned, info, cast);
            continue;
        }

        if (cast.halo || cast.penanceLaunch || cast.penanceHit)
        {
            ResolvePriestCast(*owned, info, cast);
            continue;
        }

        if (cast.killingSpree || cast.fanOfKnives || cast.shadowyShuriken || cast.poisonBomb)
        {
            ResolveRogueCast(*owned, info, cast);
            continue;
        }

        if (cast.crusaderStrike)
        {
            LandCrusaderStrike(*owned, info, cast);
            continue;
        }

        if (cast.hammerOfWrath)
        {
            LandHammerOfWrath(*owned, info, cast);
            continue;
        }

        if (cast.justiceHammer)
        {
            LandJusticeHammer(*owned, info, cast);
            continue;
        }

        if (cast.lightsHammerLaunch)
        {
            LaunchLightsHammer(*owned, cast);
            continue;
        }

        if (cast.lightsHammer)
        {
            LandLightsHammer(*owned, info, cast);
            continue;
        }

        if (cast.strike)
        {
            Creature* target = map->GetCreature(cast.target);
            if (!target || !target->IsAlive())
            {
                std::vector<Creature*> const mobs = GetMobsInRange(GetStrikeRange(*owned));
                target = mobs.empty() ? nullptr : mobs.front();
            }
            if (target)
            {
                FiringWeapon firing(m_player->GetBonkPlayer());
                uint32 const critsBefore = m_crits;
                StrikeWith(*owned, info, target, cast.share, true);
                if (cast.arcaneEcho)
                    EchoMissile(*owned, info, target, cast.share);
                if (m_crits != critsBefore)
                    SplitCriticalMissile(*owned, info, target, cast.share);
            }
            continue;
        }

        if (cast.freezingWinds)
        {
            BlowFreezingWinds(cast);
            continue;
        }

        float x = cast.x, y = cast.y, z = cast.z;
        if (Creature* target = map->GetCreature(cast.target))
            if (target->IsAlive())
            {
                x = target->GetPositionX();
                y = target->GetPositionY();
                z = target->GetPositionZ();
            }

        FiringWeapon firing(m_player->GetBonkPlayer());
        if (info->EffectImplicitTargetA[EFFECT_INDEX_0] == TARGET_UNIT_ENEMY)
        {
            float const radius = std::max(BONK_CLEAVE_RADIUS, owned->weapon.groundRadius) * GetWeaponArea(*owned);
            for (ObjectGuid const& guid : GetEnemyGuids())
                if (Creature* mob = map->GetCreature(guid))
                    if (mob->IsAlive() && mob->GetDistance2d(x, y) <= radius)
                        m_player->CastSpell(mob, info, true);
        }
        else
        {
            optional<int32> basePoints[MAX_EFFECT_INDEX];
            GetBasePoints(*owned, info, owned->weapon.altDamage, basePoints);
            m_player->GetBonkPlayer()->TweakSpell(info->Id).areaScale = GetWeaponArea(*owned);
            CastAtGround(m_player, info, basePoints, x, y, z);
        }
    }
}

void BonkRun::LaunchOrb(OwnedWeapon& owned)
{
    BonkWeapon const& weapon = owned.weapon;
    float const angle = m_player->GetOrientation();
    float const x = m_player->GetPositionX();
    float const y = m_player->GetPositionY();
    float const z = m_player->GetPositionZ();
    uint32 const lifetime = std::max(1000u, weapon.durationMs);

    Creature* orb = m_player->SummonCreature(BONK_ORB_SMALL, x, y, z + 1.0f, angle, TEMPSUMMON_TIMED_DESPAWN, lifetime + 2000, false, 0, &InstallOrbAI);
    if (!orb)
        return;
    orb->SetDisplayId(BONK_DISPLAY_SPELL_ORB);
    orb->SetObjectScale(BONK_WEAPON_ORB_SCALE);
    orb->AddAura(BONK_SPELL_WEAPON_ORB);
    orb->SetSpeedRate(MOVE_RUN, BONK_WEAPON_ORB_SPEED);

    float const distance = BONK_WEAPON_ORB_SPEED * BONK_PLAYER_RUN_SPEED * lifetime / float(IN_MILLISECONDS);
    float dx = x + distance * std::cos(angle);
    float dy = y + distance * std::sin(angle);
    float dz = z;
    m_player->GetMap()->GetWalkHitPosition(nullptr, x, y, z, dx, dy, dz);
    orb->GetMotionMaster()->MovePoint(0, dx, dy, dz, MOVE_RUN_MODE);

    WeaponOrb launched;
    launched.creature = orb->GetObjectGuid();
    launched.weaponId = weapon.id;
    launched.leftMs = int32(lifetime);
    launched.tickMs = 0;
    m_weaponOrbs.push_back(launched);
}

void BonkRun::UpdateWeaponOrbs(uint32 diff)
{
    if (m_weaponOrbs.empty())
        return;

    Map* map = m_player->GetMap();
    for (auto itr = m_weaponOrbs.begin(); itr != m_weaponOrbs.end();)
    {
        itr->leftMs -= int32(diff);
        Creature* orb = map->GetCreature(itr->creature);
        OwnedWeapon* owned = FindOwned(itr->weaponId);
        if (!orb || !owned || itr->leftMs <= 0)
        {
            if (orb)
                orb->DespawnOrUnsummon();
            itr = m_weaponOrbs.erase(itr);
            continue;
        }

        itr->tickMs -= int32(diff);
        if (itr->tickMs <= 0)
        {
            BonkWeapon const& weapon = owned->weapon;
            itr->tickMs = int32(std::max(150.0f, std::max(200u, weapon.tickMs) / GetHasteRate()));
            if (SpellEntry const* info = sSpellMgr.GetSpellEntry(weapon.spellId))
            {
                BonkProjectileInfo const* projectile = sBonkMgr.GetProjectile(info->Id);
                uint32 const targets = GetWeaponTargets(*owned);
                uint32 struck = 0;
                FiringWeapon firing(m_player->GetBonkPlayer());
                for (Creature* mob : GetMobsInRange(weapon.range * GetWeaponArea(*owned), orb))
                {
                    if (struck >= targets)
                        break;
                    if (projectile)
                        LaunchProjectiles(*owned, *projectile, info, 1.0f, orb, mob);
                    else
                        StrikeWith(*owned, info, mob, 1.0f);
                    ++struck;
                }
            }
        }
        ++itr;
    }
}

void BonkRun::DespawnWeaponOrbs()
{
    if (Map* map = m_player->FindMap())
        for (WeaponOrb const& orb : m_weaponOrbs)
            if (Creature* creature = map->GetCreature(orb.creature))
                creature->DespawnOrUnsummon();
    m_weaponOrbs.clear();
}

float BonkRun::GetLeadAngle(WorldObject const* from, Unit const* target, float speed) const
{
    float x = target->GetPositionX();
    float y = target->GetPositionY();
    if (speed > 0.0f && target->IsMoving())
    {
        float const run = target->GetSpeed(target->IsWalking() ? MOVE_WALK : MOVE_RUN) * from->GetDistance2d(target) / speed;
        x += run * std::cos(target->GetOrientation());
        y += run * std::sin(target->GetOrientation());
    }
    return from->GetAngle(x, y);
}

void BonkRun::LaunchProjectiles(OwnedWeapon& owned, BonkProjectileInfo const& info, SpellEntry const* spellInfo, float damageShare,
    WorldObject const* from, Creature* target)
{
    BonkWeapon const& weapon = owned.weapon;
    float const aim = GetLeadAngle(from, target, info.speed);

    if (weapon.chains)
    {
        uint32 chain = 1;
        for (uint32 i = 0; i < MAX_EFFECT_INDEX; ++i)
            chain = std::max(chain, spellInfo->EffectChainTarget[i]);
        uint32 const count = chain;
        for (uint32 i = 0; i < count; ++i)
            LaunchProjectile(owned, info, spellInfo->Id, damageShare, from, aim + (float(i) - (count - 1) / 2.0f) * BONK_PROJECTILE_FAN,
                weapon.baseJumps);
        return;
    }

    uint32 const pierce = weapon.behavior == BONK_BEHAVIOR_SPREAD ? 0 : weapon.baseJumps;
    LaunchProjectile(owned, info, spellInfo->Id, damageShare, from, aim, pierce);
}

void BonkRun::LaunchProjectile(OwnedWeapon& owned, BonkProjectileInfo const& info, uint32 spellId, float damageShare,
    WorldObject const* from, float angle, uint32 pierce)
{
    ++m_projectilesUnreported;

    float const x = from->GetPositionX();
    float const y = from->GetPositionY();
    float const z = from->GetPositionZ() + (from == m_player ? BONK_PROJECTILE_HEIGHT : 0.0f);
    float const length = owned.weapon.range;
    float ex = x + length * std::cos(angle);
    float ey = y + length * std::sin(angle);
    float ez = z;
    m_player->GetMap()->GetLosHitPosition(x, y, z, ex, ey, ez, -0.5f);
    float const flight = std::sqrt((ex - x) * (ex - x) + (ey - y) * (ey - y));
    if (flight < 1.0f)
        return;

    uint32 const flightMs = uint32(flight / info.speed * IN_MILLISECONDS);
    Projectile projectile;
    projectile.flightId = NextBonkFlightId();
    SendBonkFlight(m_player, projectile.flightId, x, y, z, ex, ey, ez, flightMs, info.displayId, info.scale);
    projectile.weaponId = owned.weapon.id;
    projectile.spellId = spellId;
    projectile.damageShare = damageShare;
    projectile.x = x;
    projectile.y = y;
    projectile.z = z;
    projectile.dirX = std::cos(angle);
    projectile.dirY = std::sin(angle);
    projectile.speed = info.speed;
    projectile.length = flight;
    projectile.radius = info.radius;
    projectile.pierce = pierce;
    m_projectiles.push_back(projectile);
}

void BonkRun::UpdateProjectiles(uint32 diff)
{
    if (m_projectiles.empty())
        return;

    Map* map = m_player->GetMap();
    for (auto itr = m_projectiles.begin(); itr != m_projectiles.end();)
    {
        Projectile& projectile = *itr;
        OwnedWeapon* owned = FindOwned(projectile.weaponId);
        SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(projectile.spellId);
        bool done = !owned || !spellInfo;

        if (!done)
        {
            projectile.flownMs += diff;
            float const reached = std::min(projectile.length, projectile.speed * projectile.flownMs / IN_MILLISECONDS);

            std::vector<std::pair<float, Creature*>> touched;
            for (ObjectGuid const& guid : GetEnemyGuids())
            {
                Creature* mob = map->GetCreature(guid);
                if (!mob || !mob->IsAlive() || std::find(projectile.struck.begin(), projectile.struck.end(), guid) != projectile.struck.end())
                    continue;
                float const dx = mob->GetPositionX() - projectile.x;
                float const dy = mob->GetPositionY() - projectile.y;
                float const reach = projectile.radius + mob->GetObjectBoundingRadius();
                float const along = dx * projectile.dirX + dy * projectile.dirY;
                if (along < projectile.checked - reach || along > reached + reach)
                    continue;
                if (std::fabs(dx * projectile.dirY - dy * projectile.dirX) > reach ||
                    std::fabs(mob->GetPositionZ() + BONK_PROJECTILE_HEIGHT - projectile.z) > BONK_PROJECTILE_Z_REACH)
                    continue;
                touched.emplace_back(along, mob);
            }
            std::sort(touched.begin(), touched.end(), [](auto const& a, auto const& b) { return a.first < b.first; });
            projectile.checked = reached;

            FiringWeapon firing(m_player->GetBonkPlayer());
            for (auto const& hit : touched)
            {
                projectile.struck.push_back(hit.second->GetObjectGuid());
                owned->killed = false;
                float const along = hit.first;
                Creature* source = TakeShotSource(projectile.x + along * projectile.dirX, projectile.y + along * projectile.dirY,
                    projectile.z - BONK_PROJECTILE_HEIGHT);
                StrikeWith(*owned, spellInfo, hit.second, projectile.damageShare, false, source);
                if (owned->killed && owned->weapon.HasFlag(BONK_WEAPON_FLAG_RESET_ON_KILL))
                    owned->timer = std::min<int32>(owned->timer, BONK_CLEARCAST_DELAY_MS);
                if (!projectile.pierce)
                {
                    done = true;
                    break;
                }
                --projectile.pierce;
            }
            if (reached >= projectile.length)
                done = true;
        }

        if (!done)
        {
            ++itr;
            continue;
        }
        SendBonkLanding(m_player, projectile.flightId);
        itr = m_projectiles.erase(itr);
    }
}

void BonkRun::DespawnProjectiles()
{
    for (Projectile const& projectile : m_projectiles)
        SendBonkLanding(m_player, projectile.flightId);
    for (EnemyMissile const& missile : m_enemyMissiles)
        if (missile.flightId)
            SendBonkLanding(m_player, missile.flightId);
    m_projectiles.clear();
    m_enemyMissiles.clear();
}

void BonkRun::LaunchEnemyMissile(ObjectGuid caster, ObjectGuid target, uint32 spellId, uint32 delayMs, uint32 flightMs, float x, float y, float z)
{
    if (flightMs < BONK_ENEMY_MISSILE_MIN_MS || !sBonkMgr.GetBoltLook(spellId))
        return;

    EnemyMissile missile;
    missile.caster = caster;
    missile.target = target;
    missile.spellId = spellId;
    missile.delayMs = delayMs;
    missile.leftMs = flightMs;
    missile.x = x;
    missile.y = y;
    missile.z = z + BONK_ENEMY_MISSILE_AIM;
    m_enemyMissiles.push_back(missile);
}

void BonkRun::UpdateEnemyMissiles(uint32 diff)
{
    for (auto itr = m_enemyMissiles.begin(); itr != m_enemyMissiles.end();)
    {
        EnemyMissile& missile = *itr;
        if (!missile.launched)
        {
            if (missile.delayMs > diff)
                missile.delayMs -= diff;
            else
            {
                missile.launched = true;
                FlyEnemyMissile(missile);
            }
            ++itr;
            continue;
        }
        if (missile.leftMs > diff)
        {
            missile.leftMs -= diff;
            ++itr;
            continue;
        }
        LandEnemyMissile(missile);
        itr = m_enemyMissiles.erase(itr);
    }
}

void BonkRun::DropEnemyMissilesFrom(ObjectGuid const& caster)
{
    Map* map = m_player->FindMap();
    m_enemyMissiles.erase(std::remove_if(m_enemyMissiles.begin(), m_enemyMissiles.end(), [&](EnemyMissile const& missile)
    {
        if (missile.caster != caster)
            return false;
        if (missile.flightId)
            SendBonkLanding(m_player, missile.flightId);
        return true;
    }), m_enemyMissiles.end());
}

void BonkRun::FlyEnemyMissile(EnemyMissile& missile)
{
    Creature* caster = m_player->GetMap()->GetCreature(missile.caster);
    BonkBoltLook const* look = sBonkMgr.GetBoltLook(missile.spellId);
    if (!caster || !caster->IsAlive() || !look)
        return;

    float const angle = std::atan2(missile.y - caster->GetPositionY(), missile.x - caster->GetPositionX());
    float const x = caster->GetPositionX() + caster->GetObjectBoundingRadius() * std::cos(angle);
    float const y = caster->GetPositionY() + caster->GetObjectBoundingRadius() * std::sin(angle);
    float const z = caster->GetPositionZ() + BONK_ENEMY_MISSILE_HEIGHT;
    float const dx = missile.x - x, dy = missile.y - y, dz = missile.z - z;
    if (dx * dx + dy * dy + dz * dz < 1.0f)
        return;

    missile.flightId = NextBonkFlightId();
    SendBonkFlight(m_player, missile.flightId, x, y, z, missile.x, missile.y, missile.z, missile.leftMs, look->displayId, look->scale);
}

void BonkRun::LandEnemyMissile(EnemyMissile const& missile)
{
    if (!missile.flightId)
        return;
    BonkBoltLook const* look = sBonkMgr.GetBoltLook(missile.spellId);
    if (look && look->impactKit)
        SendBonkKitAt(m_player, look->impactKit, missile.x, missile.y, missile.z - BONK_ENEMY_MISSILE_AIM, 0.0f, BONK_ERUPTION_LOOK_MS);
}


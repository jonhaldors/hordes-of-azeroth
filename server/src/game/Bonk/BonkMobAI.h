#ifndef MANGOS_BONKMOBAI_H
#define MANGOS_BONKMOBAI_H

#include "CreatureAI.h"
#include "BonkMgr.h"
#include "ObjectGuid.h"

#include <string>
#include <vector>

class BonkPlayer;
class BonkRun;
class Player;
class SpellEntry;
struct BonkEnemyHit;

class BonkMobAI : public CreatureAI
{
    public:
        explicit BonkMobAI(Creature* creature);

        static void Install(Creature* creature);
        static bool UsesExactPoints(SpellCaster const* caster);
        static bool BlocksTriggeredSpell(SpellCaster const* caster, SpellEntry const* triggeredBy);
        void RemoveSlows(Player* owner, SpellEntry const* spellInfo);
        static void SetNextPlateId(uint32 id) { s_nextPlateId = id; }
        static void SetNextAffixCount(int32 count) { s_nextAffixCount = count; }
        static void SetNextPlateIcon(char const* icon) { s_nextPlateIcon = icon; }
        static void SetNextFlyer(bool flyer) { s_nextFlyer = flyer; }
        static void SetNextLevel(uint32 level) { s_nextLevel = level; }
        static std::string GetUnitGuidText(Creature const* creature);
        static bool MayCry(Creature* creature);

        void Setup(BonkSpawnKind kind);
        void SetHealthOverflow(float overflow) { m_healthOverflow = std::max(1.0f, overflow); }
        uint64 GetTrueHealth(uint32 health) const { return uint64(double(health) * m_healthOverflow); }
        float GetHealthOverflow() const { return m_healthOverflow; }
        void SetFrozen(bool frozen);
        void Arrive(bool flash = true);
        void ShowArrivalFlash();
        bool IsBusyWindingUp() const;
        void Hold(uint32 ms);
        bool CanBePulled() const { return !m_stampede && !m_stationary && !m_fleeing; }
        bool CanCrowdWalk() const;
        float GetHoldRange() const;
        void Pull(float x, float y, float z, float speed, uint32 settleMs);
        BonkSpawnKind GetKind() const { return m_kind; }
        bool IsFlyer() const { return m_creature->IsBonkFlyer(); }
        void FlyIn(Player* owner);
        ObjectGuid GetOwnerGuid() const { return m_ownerGuid; }
        void SetArchetype(BonkArchetype archetype) { m_archetype = archetype; }
        BonkArchetype GetArchetype() const { return m_archetype; }
        void SetVeteran(bool veteran) { m_veteran = veteran; }
        bool IsVeteran() const { return m_veteran; }
        static constexpr uint32 BONK_PLATE_BRUISER = 5;
        static constexpr uint32 BONK_PLATE_VETERAN = 6;
        uint32 GetPlateKind() const;

        uint32 GetAffixCount() const;
        void QuietAffixes(uint32 durationMs);
        bool AreAffixesQuiet() const;
        bool IsBolstering() const { return HasAffix(AFFIX_BOLSTERING); }
        float GetNecroticRange() const;
        bool IsSanguine() const { return HasAffix(AFFIX_SANGUINE); }
        std::string GetAffixNames(LocaleConstant locale) const;
        static void SendAffixInfo(BonkPlayer* bonk);
        void Bolster();
        void SetFleeing(bool blinks, uint32 headStartMs = 0);
        void SetFleeHeading(float heading);
        bool IsFleeing() const { return m_fleeing; }
        void SetStationary();
        void SetPassive(bool passive);
        void SetMovesOff(bool off);
        void SetRaidTarget(ObjectGuid target);
        void ClearRaidTarget() { m_raidTarget.Clear(); }
        void StartStampede(Player* owner, float angle, float length, uint32 windupMs, float damage);
        void LandWindup(uint32 windId);
        bool IsWindingUp(uint32 windId) const;
        bool ForceAbility(uint32 number);
        static void KnockBackHero(Player* hero, float angle);
        static bool SetBossTune(std::string const& key, float value);
        static std::vector<std::string> DescribeBossTune();
        void OnHitHero(BonkRun* run);
        void SetWard(ObjectGuid target, float healPercent);
        bool IsWard() const { return !m_wardTarget.IsEmpty(); }
        std::string Describe() const;

        using CreatureAI::JustSummoned;
        void JustSummoned(Creature* summoned) override;
        void MoveInLineOfSight(Unit*) override {}
        void AttackStart(Unit* victim) override;
        void EnterEvadeMode() override;
        void UpdateAI(uint32 const diff) override;
        void DamageDeal(Unit* victim, uint32& damage) override;
        void DamageTaken(Unit* attacker, uint32& damage) override;
        void JustDied(Unit* killer) override;
        void OnRemoveFromWorld() override;

    private:
        enum Affix : uint8
        {
            AFFIX_SWIFT,
            AFFIX_EXPLOSIVE,
            AFFIX_NECROTIC,
            AFFIX_VAMPIRIC,
            AFFIX_BOLSTERING,
            AFFIX_SANGUINE,
            AFFIX_BULWARK,
            AFFIX_FORTIFIED,
            AFFIX_FRENZIED,
            AFFIX_RAGING,
            AFFIX_VOLCANIC,
            MAX_AFFIX
        };

        Player* GetOwner() const;
        void Halt();
        void HoldStill();
        void KeepHolding();
        void ShowWindupLook(SpellEntry const* spellInfo);
        void ClearWindupLook();
        bool IsHeldByControl() const;
        void AbandonWindups();
        bool ResumeWindup();
        bool UpdateLanding(uint32 diff, Player* owner);
        bool HasAffix(Affix affix) const { return !AreAffixesQuiet() && (m_affixes & (1u << affix)) != 0; }
        void RollAffixes(uint32 count);
        void ScaleHealth(float factor);
        float GetMeleeHit() const;
        float GetHitScale(BonkRun const* run) const;
        BonkEnemyHit MakeHit(BonkRun const* run, uint32 spellId, uint32 damage, uint32 windId = 0) const;
        BonkEnemyHit MakeAbilityHit(BonkRun const* run, BonkMobAbility const& ability, uint32 spellId, uint32 damage, uint32 windId = 0) const;
        void StrikeOwner(Player* owner, BonkMobAbility const& ability, float x, float y, float z);
        uint32 GetAreaDamage(BonkMobAbility const& ability, SpellEntry const* spellInfo) const;
        uint32 GetShapeDamage(BonkMobAbility const& ability) const;
        void Cast(BonkMobAbility const& ability, Player* owner, bool triggered);
        void UseAbility(size_t index, Player* owner);
        void ReportTest(std::string const& text) const;
        void UpdateAbilities(uint32 diff, Player* owner);
        void KeepSummonsUntargeted(Player* owner, BonkRun const* run);
        void UpdateAffixes(uint32 diff, Player* owner);
        void UpdatePhases(uint32 diff, Player* owner);
        bool IsBossOrMini() const { return m_kind == BONK_SPAWN_BOSS || m_kind == BONK_SPAWN_MINIBOSS; }
        uint32 GetWarnMs(BonkRun const* run, uint32 baseMs) const;
        uint32 GetMoveGapMs(BonkRun const* run) const;
        void UpdateBossPressure(uint32 diff, Player* owner, BonkRun* run);
        void UpdateHeroMarks(uint32 diff, Player* owner, BonkRun* run);
        void UpdateFarBlast(uint32 diff, Player* owner, BonkRun* run);
        void UpdateLeash(uint32 diff, Player* owner);
        void UpdateWard(uint32 diff);
        void RaiseWards(BonkRun* run, uint32 step);
        bool IsDancing() const { return m_laneWave > 0; }
        void UpdateLanes(uint32 diff, Player* owner, BonkRun* run);
        void StartLanes(Player* owner);
        void EruptLaneWave(BonkRun* run);
        void UpdateBossBlink(uint32 diff, Player* owner, BonkRun* run);
        void StartBossBlink(Player* owner);
        void FinishBossBlink(Player* owner, BonkRun* run);
        bool BlinkToHero(Player* owner, BonkRun* run);
        void PlayCastKit(BonkMobAbility const& ability, Player* owner);
        void LaunchBarrage(Player* owner, BonkRun* run, BonkEnemyHit const& hit, uint32 count, float size, uint32 warnMs, uint32 missileSpell = 0);
        void StartArea(int32 abilityIndex, Player* owner);
        void StartShape(int32 abilityIndex, Player* owner);
        void WindUp(int32 abilityIndex, float orientation, uint32 durationMs);
        bool StartLeap(int32 abilityIndex, Player* owner, BonkRun* run, uint32 damage);
        void StartLines(int32 abilityIndex, Player* owner, BonkRun* run, uint32 damage);
        void StartPools(BonkMobAbility const& ability, Player* owner, BonkRun* run);
        void StartBreaths(int32 abilityIndex, Player* owner, BonkRun* run, uint32 damage);
        void StartFrontAndBack(int32 abilityIndex, Player* owner, BonkRun* run, uint32 damage);
        void StartWalls(int32 abilityIndex, Player* owner, BonkRun* run, uint32 damage);
        void StartWreath(int32 abilityIndex, Player* owner, BonkRun* run, uint32 damage);
        void StartMeteors(int32 abilityIndex, Player* owner, BonkRun* run, uint32 damage);
        void StartDonut(int32 abilityIndex, Player* owner, BonkRun* run, uint32 damage, float size);
        void StartSweep(int32 abilityIndex, Player* owner, BonkRun* run, uint32 damage);
        bool IsMoveTurnOpen(BonkMobAbility const& ability) const;
        float GetMovePace(BonkRun const* run) const;
        void StartMoveTurn(BonkMobAbility const& ability, BonkRun* run);
        float GetKindSize(BonkAbilityShape shape, float size) const;
        uint32 GetConeWarnMs(BonkRun const* run, Player const* hero, float size) const;
        uint32 GetHeldWarnMs(BonkAbilityShape shape, BonkRun const* run, Player const* hero, float size) const;
        std::vector<float> GetLineAngles() const;
        bool IsInLines(float x, float y) const;
        void LaunchLeap();
        bool UpdateArea(uint32 diff, Player* owner);
        void ResolveArea(Player* owner);
        void ResumeChase(Player* owner);
        void AimBolt(BonkMobAbility const& ability, SpellEntry const* spellInfo, Player* owner, BonkRun* run);
        void UpdateBolt(uint32 diff, Player* owner);
        void AimBoltNow(Player* owner);
        void LaunchBolt();
        void ReleaseDrawnBolt();
        bool IsHoldingForBolt() const;
        bool UpdateCharge(uint32 diff, Player* owner);
        void StartCharge(Player* owner, float damage);
        void WarnCharge(BonkRun* run, uint32 windupMs);
        void Dash(Player* owner);
        void UpdateDash(Player* owner);
        void EndCharge(Player* owner);
        void UpdateFlee(uint32 diff, Player* owner);
        void UpdateProgressWatch(uint32 diff, Player* owner, BonkRun* run);
        void ResetProgressWatch();
        void UpdatePerchChase(BonkRun const* run);
        Unit* GetCastTarget(Creature* target);
        float GetFleeAngle(Player* owner) const;
        bool FindFleePoint(Player* owner, float distance, float& x, float& y, float& z) const;

        ObjectGuid m_ownerGuid;
        ObjectGuid m_chaseGuid;
        uint32 m_chaseScanMs = 0;
        uint32 m_chaseHeldMs = 0;
        Player* GetSpawner() const;
        void UpdateChaseTarget(uint32 diff, Player* spawner);
        BonkSpawnKind m_kind = BONK_SPAWN_NORMAL;
        float m_healthOverflow = 1.0f;
        BonkArchetype m_archetype = BONK_ARCHETYPE_GRUNT;
        bool m_veteran = false;
        bool m_flyingIn = false;
        BonkMob const* m_mob = nullptr;
        std::vector<int32> m_abilityTimers;
        uint32 m_affixes = 0;
        uint32 m_affixesQuietUntilMs = 0;
        int32 m_shieldTimer = 0;
        int32 m_burnTimer = 0;
        int32 m_eruptionTimer = 3000;
        int32 m_affixWarnTimer = 0;
        uint32 m_bolsterStacks = 0;
        bool m_enraged = false;
        uint8 m_phase = 0;
        bool m_phaseEnraged = false;
        bool m_voidZones = false;
        int32 m_voidTimer = 0;
        int32 m_markTimer = -1;
        bool m_markAnnounced = false;
        uint32 m_farMs = 0;
        int32 m_farTimer = 0;
        bool m_farAnnounced = false;
        uint32 m_leashMs = 0;
        int32 m_leashTimer = 0;
        bool m_leashAnnounced = false;
        ObjectGuid m_wardTarget;
        float m_wardHeal = 0.0f;
        int32 m_wardTimer = 0;
        bool m_wardBeaming = false;
        bool m_wardsAnnounced = false;
        int32 m_laneTimer = -1;
        uint32 m_laneWave = 0;
        uint32 m_laneSide = 0;
        float m_laneX = 0.0f, m_laneY = 0.0f, m_laneZ = 0.0f;
        float m_laneAngle = 0.0f;
        bool m_lanesAnnounced = false;
        uint32 m_bossBlinkFarMs = 0;
        bool m_bossBlinkCharging = false;
        bool m_frozen = false;
        bool m_cried = false;
        bool m_areaWinding = false;
        int32 m_areaAbility = -1;
        int32 m_areaTimer = 0;
        float m_areaX = 0.0f, m_areaY = 0.0f;
        float m_areaOrientation = 0.0f;
        float m_areaSize = 0.0f;
        uint32 m_lineCount = 0;
        float m_lineSpread = 0.0f;
        float m_lineLength = 0.0f;
        float m_leapX = 0.0f, m_leapY = 0.0f, m_leapZ = 0.0f;
        int32 m_leapTravelMs = 0;
        bool m_leapLaunched = false;
        int32 m_landingTimer = 0;
        int32 m_abilityGapTimer = 0;
        int32 m_signatureTimer = 0;
        int32 m_fillerTimer = 0;
        bool m_meteorsAnnounced = false;
        bool m_donutAnnounced = false;
        float m_leapRadius = 0.0f;
        int32 m_forcedAbility = -1;
        bool m_areaSelfTimed = false;
        uint32 m_lastLandedWindId = 0;
        uint32 m_chargesLeft = 0;
        float m_watchX = 0.0f, m_watchY = 0.0f;
        uint32 m_watchTimer = 0;
        uint32 m_windCount = 0;
        uint32 m_areaWindId = 0;
        uint32 m_chargeWindId = 0;
        int32 m_arriveTimer = 0;
        enum ChargeState : uint8 { CHARGE_NONE, CHARGE_WINDUP, CHARGE_DASH };
        ChargeState m_chargeState = CHARGE_NONE;
        int32 m_chargeTimer = 2000;
        float m_chargeX = 0.0f, m_chargeY = 0.0f, m_chargeZ = 0.0f;
        float m_chargeAngle = 0.0f, m_chargeLength = 0.0f;
        float m_chargeDamage = 0.0f;
        float m_dashX = 0.0f, m_dashY = 0.0f, m_dashZ = 0.0f;
        float m_dashFromX = 0.0f, m_dashFromY = 0.0f;
        bool m_dashHit = false;
        ObjectGuid m_boltTarget;
        uint32 m_boltSpell = 0;
        uint32 m_boltDamage = 0;
        uint32 m_boltLead = 0;
        int32 m_boltStartTimer = 0;
        int32 m_boltAimTimer = 0;
        bool m_boltStarted = false;
        bool m_boltAimed = false;
        bool m_boltServerDrawn = false;
        uint32 m_boltCastKit = 0;
        uint32 m_boltImpactKit = 0;
        uint32 m_windupLook = 0;
        std::string m_plateIcon;
        bool m_fleeing = false;
        bool m_blinks = false;
        bool m_blinkPending = false;
        int32 m_fleeTimer = 0;
        bool m_fleeStanding = false;
        bool m_stationary = false;
        bool m_passive = false;
        bool m_movesOff = false;
        ObjectGuid m_raidTarget;
        float m_raidAngle = 0.0f;
        bool m_hasFleeHeading = false;
        float m_fleeHeading = 0.0f;
        bool m_stampede = false;
        int32 m_blinkTimer = 0;

        static thread_local uint32 s_nextPlateId;
        static thread_local int32 s_nextAffixCount;
        static thread_local char const* s_nextPlateIcon;
        static thread_local bool s_nextFlyer;
        static thread_local uint32 s_nextLevel;
};

#endif

#include "BonkMobAI.h"
#include "HoaProtocol.h"
#include "WorldSession.h"
#include "BonkCoop.h"
#include "BonkLocale.h"
#include "BonkPlayer.h"
#include "BonkRun.h"
#include "Chat.h"
#include "Creature.h"
#include "DBCStores.h"
#include "Map.h"
#include "MotionMaster.h"
#include "Player.h"
#include "SpellMgr.h"
#include "TemporarySummon.h"
#include "Utilities/Random.h"

#include <algorithm>
#include <cmath>
#include <cstdio>

namespace
{
    uint32 const BONK_ARRIVE_MS = 750;
    float const BONK_MAX_HEALTH = 2000000000.0f;
    uint32 const BONK_AGGRO_CRY_MS = 250;

    float const BONK_FLEE_STEP          = 12.0f;
    uint32 const BONK_FLEE_STEP_MS      = 700;
    float const BONK_FLEE_CLIMB         = 6.0f;
    float const BONK_FLEE_BLINK         = 15.0f;
    uint32 const BONK_FLEE_BLINK_MS     = 4000;
    float const BONK_FLEE_CUT_OFF       = 10.0f;
    float const BONK_RAID_FOLLOW_DISTANCE = 1.0f;

    uint32 const BONK_UNREACHABLE_MS = 1500;
    uint32 const BONK_CHASE_SCAN_MS = 500;
    uint32 const BONK_CHASE_GRACE_MS = 3000;
    float const BONK_CHASE_SWITCH_MARGIN = 5.0f;
    uint32 const BONK_STUCK_CHECK_MS = 3000;
    float const BONK_STUCK_MIN_MOVE  = 1.5f;
    float const BONK_STUCK_SLACK     = 6.0f;
    float const BONK_TOUCH_ABILITY_RANGE = 8.0f;
    float const BONK_CAST_NEAR_DISTANCE  = 5.5f;
    uint32 const BONK_CAST_NEAR_LIFETIME_MS = 3000;

    uint32 const BONK_CASTER_MANA = 1000000;

    float const BONK_SWIFT_SPEED        = 1.5f;
    uint32 const BONK_SPELL_SHIELD      = 17;
    float const BONK_SHIELD_HEALTH      = 0.15f;
    uint32 const BONK_SHIELD_INTERVAL   = 15000;
    float const BONK_BURN_RANGE         = 9.0f;
    float const BONK_BURN_RADIUS        = 8.0f;
    uint32 const BONK_BURN_WARN_MS      = 1500;
    float const BONK_BURN_DAMAGE        = 0.5f;
    uint32 const BONK_BURN_INTERVAL     = 3000;
    float const BONK_ERUPTION_RANGE     = 40.0f;
    float const BONK_ERUPTION_RADIUS    = 4.5f;
    uint32 const BONK_ERUPTION_WARN_MS  = 1500;
    uint32 const BONK_ERUPTION_INTERVAL = 6000;
    float const BONK_ERUPTION_DAMAGE    = 1.5f;

    uint32 const BONK_AREA_WARN_MS      = 1500;
    float const BONK_AREA_DRIFT         = 1.5f;
    float const BONK_AREA_MAX_SIZE      = 15.0f;
    uint32 const BONK_AREA_RETRY_MS     = 1500;
    uint32 const BONK_WINDUP_LOST_MS    = 1000;
    uint32 const BONK_DEAD_REMOVE_MS    = 2000;

    float GetAreaReach(SpellEntry const* spellInfo)
    {
        float reach = 0.0f;
        for (uint32 i = 0; i < MAX_EFFECT_INDEX; ++i)
        {
            uint32 const a = spellInfo->EffectImplicitTargetA[i];
            uint32 const b = spellInfo->EffectImplicitTargetB[i];
            if (!spellInfo->Effect[i] ||
                (a != TARGET_ENUM_UNITS_ENEMY_AOE_AT_SRC_LOC && a != TARGET_ENUM_UNITS_ENEMY_AOE_AT_DEST_LOC &&
                 b != TARGET_ENUM_UNITS_ENEMY_AOE_AT_SRC_LOC && b != TARGET_ENUM_UNITS_ENEMY_AOE_AT_DEST_LOC))
                continue;
            reach = std::max(reach, Spells::GetSpellRadius(sSpellRadiusStore.LookupEntry(spellInfo->EffectRadiusIndex[i])));
        }
        return reach;
    }

    float GetAreaSize(float reach, float heroBody)
    {
        float const hitReach = reach + heroBody;
        return hitReach >= 8.0f ? std::ceil(hitReach) : std::ceil(hitReach * 2.0f) / 2.0f;
    }

    float const BONK_CONE_GROWTH_PER_STEP = 0.2f;
    float const BONK_CONE_WORST_ESCAPE  = 0.4142f;
    uint32 const BONK_REACTION_MS       = 400;

    float GetConeSize(float normalSize, BonkRun const* run, Player const* hero, uint32 warnMs)
    {
        float const grown = normalSize * (1.0f + BONK_CONE_GROWTH_PER_STEP * float(run->GetDifficultyStep()));
        float const runway = hero->GetSpeed(MOVE_RUN) * float(warnMs > BONK_REACTION_MS ? warnMs - BONK_REACTION_MS : 0) / IN_MILLISECONDS;
        return std::max(1.0f, std::min(grown, runway / BONK_CONE_WORST_ESCAPE));
    }

    bool DealsDamage(SpellEntry const* spellInfo)
    {
        for (SpellEffects effect : { SPELL_EFFECT_SCHOOL_DAMAGE, SPELL_EFFECT_HEALTH_LEECH, SPELL_EFFECT_WEAPON_DAMAGE_NOSCHOOL,
            SPELL_EFFECT_WEAPON_PERCENT_DAMAGE, SPELL_EFFECT_WEAPON_DAMAGE, SPELL_EFFECT_NORMALIZED_WEAPON_DMG })
            if (spellInfo->HasEffect(effect))
                return true;
        return false;
    }

    float const BONK_CHARGE_MIN_RANGE   = 8.0f;
    float const BONK_CHARGE_MAX_RANGE   = 20.0f;
    float const BONK_CHARGE_AIM_RANGE   = 16.0f;
    float const BONK_CHARGE_MAX_LENGTH  = 30.0f;
    float const BONK_CHARGE_OVERSHOOT   = 5.0f;
    uint32 const BONK_CHARGE_WARN_MS    = 1200;
    uint32 const BONK_CHARGE_INTERVAL   = 8000;
    uint32 const BONK_CHARGE_RETRY_MS   = 500;
    float const BONK_CHARGE_SPEED       = 30.0f;
    float const BONK_CHARGE_DAMAGE      = 2.0f;
    float const BONK_CHARGE_CONTACT     = 1.5f;
    float const BONK_CHARGE_KNOCKBACK_SPEED = 8.0f;
    float const BONK_CHARGE_KNOCKBACK_LIFT  = 4.0f;
    uint32 const BONK_SPELL_CHARGE_HIT  = 24257;
    uint32 const BONK_SPELL_PLAIN_HIT   = 7482;
    uint32 const BONK_KIT_CLEAVE        = 366;
    uint32 const BONK_KIT_FIRE_BREATH   = 3449;
    uint32 const BONK_KIT_SMASH         = 2409;
    uint32 const BONK_KIT_DUST_NOVA     = 7456;
    uint32 const BONK_KIT_EARTH_BURST   = 7400;
    uint32 const BONK_KIT_CHARGE_TRAIL  = 44;
    uint32 const BONK_SPELL_HOLY_WINDUP   = 22011;
    uint32 const BONK_SPELL_FIRE_WINDUP   = 2120;
    uint32 const BONK_SPELL_NATURE_WINDUP = 2616;
    uint32 const BONK_SPELL_FROST_WINDUP  = 10;
    uint32 const BONK_SPELL_SHADOW_WINDUP = 17224;
    uint32 const BONK_SPELL_ARCANE_WINDUP = 10797;

    uint32 GetWindupLookSpell(SpellEntry const* spellInfo)
    {
        switch (spellInfo ? spellInfo->School : SPELL_SCHOOL_NORMAL)
        {
            case SPELL_SCHOOL_HOLY:   return BONK_SPELL_HOLY_WINDUP;
            case SPELL_SCHOOL_FIRE:   return BONK_SPELL_FIRE_WINDUP;
            case SPELL_SCHOOL_NATURE: return BONK_SPELL_NATURE_WINDUP;
            case SPELL_SCHOOL_FROST:  return BONK_SPELL_FROST_WINDUP;
            case SPELL_SCHOOL_SHADOW: return BONK_SPELL_SHADOW_WINDUP;
            case SPELL_SCHOOL_ARCANE: return BONK_SPELL_ARCANE_WINDUP;
            default:                  return 0;
        }
    }

    uint32 GetCastKit(BonkMobAbility const& ability)
    {
        if (ability.castKit)
            return ability.castKit;
        switch (ability.shape)
        {
            case BONK_SHAPE_CONE:
            case BONK_SHAPE_TAIL:
                return BONK_KIT_CLEAVE;
            case BONK_SHAPE_NOVA:
            case BONK_SHAPE_LEAP:
                return BONK_KIT_DUST_NOVA;
            case BONK_SHAPE_BREATHS:
                return BONK_KIT_FIRE_BREATH;
            case BONK_SHAPE_SHOCKWAVE:
            case BONK_SHAPE_SPOKES:
            case BONK_SHAPE_SWEEP:
            case BONK_SHAPE_WALLS:
            case BONK_SHAPE_DONUT:
                return BONK_KIT_SMASH;
            default:
                return 0;
        }
    }

    uint32 GetImpactKit(BonkMobAbility const& ability)
    {
        if (ability.impactKit)
            return ability.impactKit;
        switch (ability.shape)
        {
            case BONK_SHAPE_SHOCKWAVE:
            case BONK_SHAPE_SPOKES:
            case BONK_SHAPE_SWEEP:
            case BONK_SHAPE_WALLS:
            case BONK_SHAPE_DONUT:
                return BONK_KIT_EARTH_BURST;
            default:
                return 0;
        }
    }

    bool IsSignatureShape(BonkAbilityShape shape)
    {
        switch (shape)
        {
            case BONK_SHAPE_SHOCKWAVE:
            case BONK_SHAPE_SPOKES:
            case BONK_SHAPE_SWEEP:
            case BONK_SHAPE_NOVA:
            case BONK_SHAPE_BREATHS:
            case BONK_SHAPE_WALLS:
            case BONK_SHAPE_WREATH:
            case BONK_SHAPE_METEORS:
            case BONK_SHAPE_DONUT:
                return true;
            default:
                return false;
        }
    }
    float const BONK_BOLT_LEAD_BY_STEP[3] = { 0.0f, 0.5f, 1.0f };
    float const BONK_ABILITY_LEAD_BY_STEP[3] = { 0.5f, 0.75f, 1.0f };
    float const BONK_BARRAGE_SPREAD     = 10.0f;
    uint32 const BONK_BARRAGE_STAGGER_MS = 300;
    float const BONK_SHAPE_DAMAGE       = 1.5f;
    uint32 const BONK_SHAPE_RETRY_MS    = 1000;
    uint32 const BONK_ABILITY_GAP_MS    = 1500;
    uint32 const BONK_MECHANIC_REST_MS  = 750;
    float const BONK_LEAP_SPEED         = 35.0f;
    uint32 const BONK_LEAP_WINDUP_MS    = 1000;
    int32 const BONK_LEAP_MIN_TRAVEL_MS = 300;
    int32 const BONK_LEAP_LAUNCH_EARLY_MS = 100;
    int32 const BONK_LEAP_SETTLE_MS     = 300;
    float const BONK_LEAP_RADIUS        = 6.0f;
    uint32 const BONK_LINE_WARN_MS      = 1500;
    float const BONK_LINE_MAX_LENGTH    = 36.0f;
    float const BONK_SHOCKWAVE_SPREAD   = M_PI_F / 7.0f;
    uint32 const BONK_SPOKES_COUNT      = 6;
    float const BONK_POOL_RADIUS        = 5.0f;
    float const BONK_POOL_SPREAD        = 10.0f;
    uint32 const BONK_POOL_DURATION_MS  = 6000;
    uint32 const BONK_BREATH_COUNT      = 3;
    uint32 const BONK_BREATH_STAGGER_MS = 700;
    uint32 const BONK_WALL_COUNT        = 3;
    float const BONK_WALL_SPACING       = 6.0f;
    uint32 const BONK_WREATH_COUNT      = 8;
    float const BONK_WREATH_RADIUS      = 4.0f;
    float const BONK_WREATH_DISTANCE    = 9.0f;
    uint32 const BONK_SIGNATURE_WARN_MS = 2000;
    int32 const BONK_SIGNATURE_FIRST_MS = 6000;
    uint32 const BONK_SIGNATURE_HOLD_MS = 3000;
    float const BONK_BOSS_NOVA_SIZE     = 18.0f;
    float const BONK_BOSS_NOVA_BODY_GROWTH = 4.0f;
    float const BONK_MINI_NOVA_SIZE     = 13.0f;
    float const BONK_BOSS_CONE_SIZE     = 26.0f;
    float const BONK_MINI_CONE_SIZE     = 20.0f;
    float const BONK_BOSS_TAIL_SIZE     = 22.0f;
    float const BONK_MINI_TAIL_SIZE     = 17.0f;
    float const BONK_BOSS_LEAP_RADIUS   = 10.0f;
    float const BONK_MINI_LEAP_RADIUS   = 8.0f;
    uint32 const BONK_METEOR_COUNT      = 12;
    uint32 const BONK_MINI_METEOR_COUNT = 8;
    uint32 const BONK_METEORS_PER_STEP  = 4;
    float const BONK_METEOR_RADIUS      = 5.0f;
    float const BONK_MINI_METEOR_RADIUS = 4.0f;
    float const BONK_METEOR_SPREAD      = 36.0f;
    float const BONK_MINI_METEOR_SPREAD = 26.0f;
    float const BONK_METEOR_NEAREST     = 0.15f;
    uint32 const BONK_METEOR_SPAN_MS    = 3500;
    uint32 const BONK_METEOR_CAST_MS    = 1000;
    float const BONK_BOSS_DONUT_SIZE    = 30.0f;
    float const BONK_MINI_DONUT_SIZE    = 22.0f;
    uint32 const BONK_DONUT_WARN_MS     = 2500;
    uint32 const BONK_SWEEP_STEP_MS     = 1100;

    BonkTelegraphShape GetHeldShape(BonkAbilityShape shape)
    {
        return shape == BONK_SHAPE_CONE ? BONK_TELEGRAPH_CONE : BONK_TELEGRAPH_CIRCLE;
    }

    BonkEnemyHit Unbound(BonkEnemyHit hit)
    {
        hit.caster.Clear();
        hit.windId = 0;
        return hit;
    }
    float const BONK_POOL_DAMAGE        = 1.0f;

    float const BONK_BOLT_RADIUS        = 3.0f;
    uint32 const BONK_BOLT_MIN_WARN_MS  = 1500;
    uint32 const BONK_BOLT_AIM_BEFORE_MS = 150;
    uint32 const BONK_BOLT_TARGET_LINGER_MS = 3000;
    uint32 const BONK_PREDICT_MAX_AGE_MS = 1000;

    uint32 GetBoltFlightMs(SpellEntry const* spellInfo, float distance)
    {
        if (spellInfo->speed <= 0.0f)
            return 0;
        return uint32(std::max(5.0f, distance) / spellInfo->speed * IN_MILLISECONDS);
    }

    void PredictPlayer(Player const* player, uint32 aheadMs, float& x, float& y, float& z)
    {
        player->GetPosition(x, y, z);
        if (!player->IsMoving())
            return;
        uint32 const age = std::min(WorldTimer::getMSTimeDiffToNow(player->m_movementInfo.stime), BONK_PREDICT_MAX_AGE_MS);
        float px, py, pz, o;
        if (!player->ExtrapolateMovement(player->m_movementInfo, age + aheadMs, px, py, pz, o) || !player->IsWithinLOS(px, py, pz))
            return;
        player->UpdateAllowedPositionZ(px, py, pz);
        x = px;
        y = py;
        z = pz;
    }

    void AimAhead(Player const* player, BonkRun const* run, uint32 landsInMs, float& x, float& y, float& z)
    {
        float const lead = BONK_ABILITY_LEAD_BY_STEP[std::min(2u, run->GetDifficultyStep())];
        PredictPlayer(player, uint32(landsInMs * lead), x, y, z);
    }

    float AimAngle(Creature const* mob, Player const* player, BonkRun const* run, uint32 landsInMs)
    {
        float x, y, z;
        AimAhead(player, run, landsInMs, x, y, z);
        return mob->GetAngle(x, y);
    }

    uint32 GetChargeWindupMs()
    {
        return BONK_CHARGE_WARN_MS + GetBonkTelegraphLeadMs(BONK_TELEGRAPH_LINE);
    }

    float const BONK_VAMPIRIC_HEAL      = 0.5f;
    float const BONK_FRENZIED_SPEED     = 1.5f;
    float const BONK_FORTIFIED_HEALTH   = 1.5f;
    float const BONK_FORTIFIED_SCALE    = 1.15f;
    float const BONK_PHASE_BOSS[2]      = { 66.0f, 33.0f };
    float const BONK_PHASE_MINIBOSS     = 50.0f;
    uint32 const BONK_PHASE_ADDS        = 5;
    uint32 const BONK_PHASE_MINI_ADDS   = 3;
    float const BONK_PHASE_ENRAGE       = 1.25f;
    float const BONK_PHASE_SHIELD       = 0.25f;
    int32 const BONK_VOID_FIRST_MS      = 3000;
    int32 const BONK_VOID_INTERVAL      = 7000;
    float const BONK_VOID_RANGE         = 40.0f;
    float const BONK_VOID_RADIUS        = 6.0f;
    uint32 const BONK_VOID_WARN_MS      = 1500;
    uint32 const BONK_VOID_DURATION_MS  = 8000;
    float const BONK_VOID_DAMAGE        = 1.0f;
    float const BONK_MARK_RANGE         = 60.0f;
    uint32 const BONK_MARK_FILL_MS      = 4000;
    uint32 const BONK_SPELL_WARD_BEAM   = 755;
    float const BONK_WARD_REACH         = 40.0f;
    uint32 const BONK_LANE_COUNT        = 3;
    uint32 const BONK_LANE_CIRCLES      = 4;
    float const BONK_LANE_OVERLAP       = 0.55f;
    int32 const BONK_LANE_FIRST_MS      = 4000;
    float const BONK_BLINK_LANDING      = 6.0f;
    int32 const BONK_BLINK_RETRY_MS     = 1000;
    uint32 const BONK_BLINK_WINDUP_MS   = 500;
    uint32 const BONK_BLINK_KIT_HOLD_MS = 1000;
    uint32 const BONK_KIT_BLINK_LEAVE   = 267;
    uint32 const BONK_KIT_BLINK_ARRIVE  = 3394;

    enum BossTune : uint8
    {
        TUNE_GAP_HEROIC,
        TUNE_GAP_MYTHIC,
        TUNE_WARN_MYTHIC,
        TUNE_MARK_HEROIC,
        TUNE_MARK_MYTHIC,
        TUNE_MARK_WARN,
        TUNE_MARK_RADIUS,
        TUNE_MARK_POOL,
        TUNE_MARK_DAMAGE,
        TUNE_FAR_RANGE,
        TUNE_FAR_DELAY,
        TUNE_FAR_INTERVAL,
        TUNE_FAR_COUNT,
        TUNE_FAR_RADIUS,
        TUNE_FAR_DAMAGE,
        TUNE_WOUND_CUT,
        TUNE_WOUND_MAX,
        TUNE_WOUND_SECONDS,
        TUNE_LEASH_RANGE,
        TUNE_LEASH_DELAY,
        TUNE_LEASH_HEAL,
        TUNE_WARDS_HEROIC,
        TUNE_WARDS_MYTHIC,
        TUNE_WARD_HEALTH,
        TUNE_WARD_HEAL,
        TUNE_LANES_HEROIC,
        TUNE_LANES_MYTHIC,
        TUNE_LANE_WAVES,
        TUNE_LANE_GAP,
        TUNE_LANE_WARN,
        TUNE_LANE_WIDTH,
        TUNE_LANE_DAMAGE,
        TUNE_BLINK_DELAY,
        TUNE_BLINK_RADIUS,
        TUNE_BLINK_WARN,
        TUNE_BLINK_DAMAGE,
        TUNE_SIGNATURE,
        TUNE_FILLER,
        TUNE_SIGNATURE_GAP,
        TUNE_PACE_HEROIC,
        TUNE_PACE_MYTHIC,
        MAX_BOSS_TUNE
    };

    struct BossTuneEntry
    {
        char const* key;
        char const* meaning;
        float value;
    };

    BossTuneEntry s_bossTune[MAX_BOSS_TUNE] =
    {
        { "gapheroic",    "seconds between Heroic boss and mini-boss moves",              0.8f },
        { "gapmythic",    "seconds between Mythic boss and mini-boss moves",              0.5f },
        { "warnmythic",   "share of the usual warning time on Mythic boss moves",         0.75f },
        { "markheroic",   "seconds between Heroic boss marks (0 = off)",                  11.0f },
        { "markmythic",   "seconds between Mythic boss marks (0 = off)",                  9.0f },
        { "markwarn",     "seconds a dropped mark warns before it bursts",                1.0f },
        { "markradius",   "mark radius in yards",                                         6.0f },
        { "markpool",     "seconds of burning ground a mark leaves (0 = none)",           8.0f },
        { "markdamage",   "mark burst damage in boss melee hits",                         1.5f },
        { "farrange",     "yards from the boss before it bombards the hero (0 = off)",    25.0f },
        { "fardelay",     "seconds out of range before the bombardment starts",           3.0f },
        { "farinterval",  "seconds between bombardments",                                 2.0f },
        { "farcount",     "circles per Heroic bombardment (Mythic +1)",                   2.0f },
        { "farradius",    "bombardment circle radius in yards",                           4.0f },
        { "fardamage",    "bombardment damage in boss melee hits",                        1.0f },
        { "woundcut",     "Mythic healing cut per wound stack, percent (0 = off)",        15.0f },
        { "woundmax",     "most wound stacks",                                            4.0f },
        { "woundseconds", "seconds wounds last after the last boss hit",                  6.0f },
        { "leashrange",   "yards from the Mythic boss before it recovers (0 = off)",      35.0f },
        { "leashdelay",   "seconds out of range before it recovers",                      2.0f },
        { "leashheal",    "percent of its health the boss recovers each second",          1.0f },
        { "wardsheroic",  "healing wards a Heroic boss raises at 66% and 33%",            1.0f },
        { "wardsmythic",  "healing wards a Mythic boss raises at 66% and 33%",            2.0f },
        { "wardhealth",   "ward health, percent of the boss's health",                    3.0f },
        { "wardheal",     "percent of the boss's health each ward heals a second",        1.0f },
        { "laneheroic",   "seconds between Heroic eruption lanes below 66% (0 = off)",    0.0f },
        { "lanemythic",   "seconds between Mythic eruption lanes below 66% (0 = off)",    24.0f },
        { "lanewaves",    "eruption waves in one set of lanes",                           4.0f },
        { "lanegap",      "seconds between eruption waves",                               1.6f },
        { "lanewarn",     "seconds each eruption wave warns",                             1.4f },
        { "lanewidth",    "lane width in yards",                                          8.0f },
        { "lanedamage",   "eruption damage in boss melee hits",                           1.0f },
        { "blinkdelay",   "seconds out of range before a Mythic boss blinks to you (0 = off)", 7.0f },
        { "blinkradius",  "radius of the nova after a blink, in yards",                   8.0f },
        { "blinkwarn",    "seconds the nova warns after a blink",                         1.4f },
        { "blinkdamage",  "nova damage in boss melee hits",                               2.0f },
        { "signature",    "seconds between a boss's big moves on Normal",                 16.0f },
        { "filler",       "seconds between a boss's small moves on Normal",               6.0f },
        { "signaturegap", "seconds a boss rests after a big move",                        2.8f },
        { "paceheroic",   "share of the Normal move timers on Heroic",                    0.88f },
        { "pacemythic",   "share of the Normal move timers on Mythic",                    0.75f },
    };

    float Tune(BossTune tune)
    {
        return s_bossTune[tune].value;
    }

    uint32 TuneMs(BossTune tune)
    {
        return uint32(std::max(0.0f, s_bossTune[tune].value) * IN_MILLISECONDS);
    }

    float const BONK_RAGING_HEALTH      = 30.0f;
    float const BONK_RAGING_DAMAGE      = 1.5f;
    uint32 const BONK_SPELL_RAGING      = 20368;
    float const BONK_BOLSTER_BONUS      = 0.2f;
    float const BONK_BOLSTER_SCALE      = 1.05f;
    uint32 const BONK_BOLSTER_MAX       = 10;
    float const BONK_NECROTIC_RANGE     = 10.0f;

    enum AffixCategory : uint8
    {
        AFFIX_PRESSURE,
        AFFIX_SUSTAIN,
        AFFIX_BULK,
        AFFIX_ENRAGE,
        MAX_AFFIX_CATEGORY
    };

    struct AffixInfo
    {
        BonkString name;
        char const* icon;
        AffixCategory category;
        uint32 glow;
    };
    AffixInfo const BONK_AFFIXES[] =
    {
        { BONK_STRING_AFFIX_SWIFT,      "Ability_Rogue_Sprint",              AFFIX_PRESSURE, 22580 },
        { BONK_STRING_AFFIX_EXPLOSIVE,  "Spell_Fire_SelfDestruct",           AFFIX_PRESSURE, 22579 },
        { BONK_STRING_AFFIX_NECROTIC,   "Spell_Shadow_AbominationExplosion", AFFIX_PRESSURE, 22577 },
        { BONK_STRING_AFFIX_VAMPIRIC,   "Spell_Shadow_LifeDrain02",          AFFIX_SUSTAIN,  22578 },
        { BONK_STRING_AFFIX_BOLSTERING, "Ability_Warrior_BattleShout",       AFFIX_SUSTAIN,  22581 },
        { BONK_STRING_AFFIX_SANGUINE,   "Spell_Shadow_BloodBoil",            AFFIX_SUSTAIN,  22518 },
        { BONK_STRING_AFFIX_BULWARK,    "Spell_Holy_PowerWordShield",        AFFIX_BULK,     26388 },
        { BONK_STRING_AFFIX_FORTIFIED,  "Ability_Warrior_DefensiveStance",   AFFIX_BULK,     22576 },
        { BONK_STRING_AFFIX_FRENZIED,   "Ability_GhoulFrenzy",               AFFIX_ENRAGE,   28126 },
        { BONK_STRING_AFFIX_RAGING,     "Ability_Racial_BloodRage",          AFFIX_ENRAGE,   31309 },
        { BONK_STRING_AFFIX_VOLCANIC,   "Spell_Fire_Volcano",                AFFIX_PRESSURE, 22579 },
    };
}

BonkMobAI::BonkMobAI(Creature* creature) : CreatureAI(creature)
{
    if (creature->IsTemporarySummon())
        m_ownerGuid = static_cast<TemporarySummon*>(creature)->GetSummonerGuid();
}

thread_local uint32 BonkMobAI::s_nextPlateId = 0;
thread_local int32 BonkMobAI::s_nextAffixCount = -1;
thread_local char const* BonkMobAI::s_nextPlateIcon = nullptr;
thread_local bool BonkMobAI::s_nextFlyer = false;
thread_local uint32 BonkMobAI::s_nextLevel = 0;

void BonkMobAI::Install(Creature* creature)
{
    creature->SetPlateId(s_nextPlateId);
    s_nextPlateId = 0;
    if (s_nextLevel)
    {
        creature->SetLevel(s_nextLevel);
        s_nextLevel = 0;
    }
    creature->SetBonkEnemy(true);
    if (s_nextFlyer)
    {
        creature->SetBonkFlyer(true);
        creature->SetFly(true);
        s_nextFlyer = false;
    }

    creature->GetMotionMaster()->Initialize();
    creature->SetAI(new BonkMobAI(creature));
}

Player* BonkMobAI::GetOwner() const
{
    if (!m_chaseGuid.IsEmpty())
        if (Player* target = m_creature->GetMap()->GetPlayer(m_chaseGuid))
            if (target->IsAlive() && target->IsInWorld())
                return target;
    return GetSpawner();
}

Player* BonkMobAI::GetSpawner() const
{
    return m_creature->GetMap()->GetPlayer(m_ownerGuid);
}

void BonkMobAI::UpdateChaseTarget(uint32 diff, Player* spawner)
{
    m_chaseHeldMs += diff;
    m_chaseScanMs += diff;
    if (m_chaseScanMs < BONK_CHASE_SCAN_MS)
        return;
    m_chaseScanMs = 0;

    std::vector<Player*> const group = BonkCoop::RunGroupOf(spawner);
    if (group.size() < 2)
    {
        m_chaseGuid.Clear();
        return;
    }

    Player* current = GetOwner();
    bool const currentValid = current && current->IsAlive() && !BonkCoop::IsAway(current) && current->GetMapId() == m_creature->GetMapId();
    Player* nearest = nullptr;
    float nearestDistance = 0.0f;
    for (Player* member : group)
    {
        BonkRun* run = member->GetBonkPlayer()->GetRun();
        if (!run || !run->IsActive() || run->IsAway() || !member->IsAlive() || !member->IsInWorld() || member->GetMapId() != m_creature->GetMapId())
            continue;
        float const distance = m_creature->GetDistance2d(member);
        if (!nearest || distance < nearestDistance)
        {
            nearest = member;
            nearestDistance = distance;
        }
    }
    if (!nearest || nearest == current)
        return;
    if (currentValid && (m_chaseHeldMs < BONK_CHASE_GRACE_MS || nearestDistance + BONK_CHASE_SWITCH_MARGIN >= m_creature->GetDistance2d(current)))
        return;

    m_chaseGuid = nearest->GetObjectGuid();
    m_chaseHeldMs = 0;
}

void BonkMobAI::Setup(BonkSpawnKind kind)
{
    m_kind = kind;
    m_creature->SetBonkNormal(kind == BONK_SPAWN_NORMAL);
    m_mob = sBonkMgr.GetMob(m_creature->GetEntry());

    if (m_mob && !m_mob->abilities.empty())
    {
        for (BonkMobAbility const& ability : m_mob->abilities)
            m_abilityTimers.push_back(int32(ability.firstMs));
        m_signatureTimer = BONK_SIGNATURE_FIRST_MS;

        if (m_creature->GetPowerType() != POWER_MANA)
            m_creature->SetPowerType(POWER_MANA);
        m_creature->SetModifierValue(UNIT_MOD_MANA, BASE_VALUE, float(BONK_CASTER_MANA));
        m_creature->SetMaxPower(POWER_MANA, BONK_CASTER_MANA);
        m_creature->SetPower(POWER_MANA, BONK_CASTER_MANA);
    }

    for (DispelType dispel : { DISPEL_POISON, DISPEL_DISEASE, DISPEL_CURSE })
        m_creature->ApplySpellImmune(0, IMMUNITY_DISPEL, dispel, false);
    m_creature->ApplySpellImmune(0, IMMUNITY_STATE, SPELL_AURA_PERIODIC_LEECH, false);

    if (kind != BONK_SPAWN_NORMAL)
    {
        for (AuraType aura : { SPELL_AURA_MOD_STUN, SPELL_AURA_MOD_ROOT, SPELL_AURA_MOD_FEAR, SPELL_AURA_MOD_CONFUSE, SPELL_AURA_MOD_CHARM })
        {
            if (aura == SPELL_AURA_MOD_STUN && kind == BONK_SPAWN_ELITE)
                continue;
            m_creature->ApplySpellImmune(0, IMMUNITY_STATE, aura, true);
            m_creature->RemoveSpellsCausingAura(aura);
        }
        m_creature->ApplySpellImmune(0, IMMUNITY_EFFECT, SPELL_EFFECT_KNOCK_BACK, true);
    }

    Player* owner = GetOwner();
    BonkRun* run = owner ? owner->GetBonkPlayer()->GetRun() : nullptr;
    uint32 const affixes = s_nextAffixCount >= 0 ? uint32(s_nextAffixCount) : run ? run->GetEliteAffixes() : 1;
    s_nextAffixCount = -1;
    m_plateIcon = s_nextPlateIcon ? s_nextPlateIcon : "";
    s_nextPlateIcon = nullptr;
    if (kind == BONK_SPAWN_ELITE)
        RollAffixes(affixes);
    else if (kind == BONK_SPAWN_MINIBOSS)
        RollAffixes(affixes + 1);

    uint32 const plateKind = GetPlateKind();
    if (plateKind && owner && owner->GetBonkPlayer()->IsAddonReady())
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteMob(data, plateKind, owner->GetBonkPlayer()->GetLocalName(m_creature), m_plateIcon, m_creature->GetPlateId(),
            GetUnitGuidText(m_creature));
        owner->GetSession()->SendPacket(&data);
    }
}

uint32 BonkMobAI::GetPlateKind() const
{
    if (m_kind != BONK_SPAWN_NORMAL)
        return uint32(m_kind);
    if (m_veteran)
        return BONK_PLATE_VETERAN;
    if (m_archetype == BONK_ARCHETYPE_BRUISER)
        return BONK_PLATE_BRUISER;
    return 0;
}

bool BonkMobAI::MayCry(Creature* creature)
{
    BonkMobAI* ai = dynamic_cast<BonkMobAI*>(creature->AI());
    if (!ai)
        return true;
    if (ai->m_cried)
        return false;
    ai->m_cried = true;

    static thread_local uint32 s_lastCryMs = 0;
    uint32 const now = WorldTimer::getMSTime();
    if (s_lastCryMs && WorldTimer::getMSTimeDiff(s_lastCryMs, now) < BONK_AGGRO_CRY_MS)
        return false;
    s_lastCryMs = now;
    return true;
}

std::string BonkMobAI::GetUnitGuidText(Creature const* creature)
{
    uint64 const raw = creature->GetObjectGuid().GetRawValue();
    char text[19];
    snprintf(text, sizeof(text), "0x%08X%08X", uint32(raw >> 32), uint32(raw));
    return text;
}

void BonkMobAI::RollAffixes(uint32 count)
{
    std::vector<Affix> available;
    for (uint8 affix = 0; affix < MAX_AFFIX; ++affix)
        available.push_back(Affix(affix));

    std::vector<BonkString> names;
    for (uint32 i = 0; i < count && !available.empty(); ++i)
    {
        uint32 const pick = urand(0, uint32(available.size() - 1));
        Affix const affix = available[pick];
        AffixCategory const category = BONK_AFFIXES[affix].category;
        available.erase(std::remove_if(available.begin(), available.end(), [category](Affix other)
        {
            return BONK_AFFIXES[other].category == category;
        }), available.end());

        m_affixes |= 1u << affix;
        names.push_back(BONK_AFFIXES[affix].name);
        m_creature->AddAura(BONK_AFFIXES[affix].glow);
    }

    if (HasAffix(AFFIX_SWIFT))
    {
        m_creature->SetBaseSpeedRate(MOVE_WALK, m_creature->GetBaseWalkSpeedRate() * BONK_SWIFT_SPEED);
        m_creature->SetBaseSpeedRate(MOVE_RUN, m_creature->GetBaseRunSpeedRate() * BONK_SWIFT_SPEED);
    }

    if (HasAffix(AFFIX_FRENZIED))
        m_creature->SetAttackTime(BASE_ATTACK, uint32(m_creature->GetAttackTime(BASE_ATTACK) / BONK_FRENZIED_SPEED));

    if (HasAffix(AFFIX_FORTIFIED))
    {
        ScaleHealth(BONK_FORTIFIED_HEALTH);
        m_creature->SetObjectScale(m_creature->GetObjectScale() * BONK_FORTIFIED_SCALE);
        m_creature->UpdateModelData();
    }

    if (!names.empty())
        if (Player* owner = GetOwner())
        {
            BonkPlayer const* bonk = owner->GetBonkPlayer();
            std::vector<std::string> shown;
            for (BonkString name : names)
                shown.push_back(bonk->GetString(name));
            bonk->Notify(BONK_STRING_ENEMY_AFFIXES, { bonk->GetLocalName(m_creature), bonk->JoinList(shown, BONK_STRING_LIST_AND) });
        }
}

void BonkMobAI::ScaleHealth(float factor)
{
    float const scaled = m_creature->GetMaxHealth() * factor;
    float const maxHealth = std::min(BONK_MAX_HEALTH, scaled);
    m_healthOverflow *= scaled / maxHealth;
    uint32 const health = std::max(1u, uint32(std::min(maxHealth, m_creature->GetHealth() * factor)));
    m_creature->SetModifierValue(UNIT_MOD_HEALTH, BASE_VALUE, maxHealth);
    m_creature->SetMaxHealth(uint32(maxHealth));
    m_creature->SetHealth(std::min(health, m_creature->GetMaxHealth()));
}

float BonkMobAI::GetNecroticRange() const
{
    if (!HasAffix(AFFIX_NECROTIC))
        return 0.0f;
    if (m_mob && m_mob->role == BONK_ROLE_RANGED)
        return std::max(BONK_NECROTIC_RANGE, m_mob->range);
    return BONK_NECROTIC_RANGE;
}

uint32 BonkMobAI::GetAffixCount() const
{
    uint32 count = 0;
    for (uint8 affix = 0; affix < MAX_AFFIX; ++affix)
        if (HasAffix(Affix(affix)))
            ++count;
    return count;
}

std::string BonkMobAI::GetAffixNames(LocaleConstant locale) const
{
    std::string names;
    for (uint8 affix = 0; affix < MAX_AFFIX; ++affix)
        if (HasAffix(Affix(affix)))
            names += (names.empty() ? "" : ",") + sBonkLocale.GetString(BONK_AFFIXES[affix].name, locale);
    return names;
}

void BonkMobAI::SendAffixInfo(BonkPlayer* bonk)
{
    auto percent = [](float value)
    {
        char text[16];
        snprintf(text, sizeof(text), "%g%%", value);
        return std::string(text);
    };
    auto seconds = [bonk](uint32 ms)
    {
        return bonk->GetString(ms == 1000 ? BONK_STRING_DURATION_SECOND : BONK_STRING_DURATION_SECONDS, { FormatBonkNumber(ms / 1000.0f) });
    };

    for (uint8 affix = 0; affix < MAX_AFFIX; ++affix)
    {
        std::string text;
        switch (Affix(affix))
        {
            case AFFIX_SWIFT:      text = bonk->GetString(BONK_STRING_AFFIX_SWIFT_TEXT, { percent((BONK_SWIFT_SPEED - 1.0f) * 100.0f) }); break;
            case AFFIX_EXPLOSIVE:  text = bonk->GetString(BONK_STRING_AFFIX_EXPLOSIVE_TEXT, { seconds(BONK_BURN_INTERVAL) }); break;
            case AFFIX_NECROTIC:   text = bonk->GetString(BONK_STRING_AFFIX_NECROTIC_TEXT); break;
            case AFFIX_VAMPIRIC:   text = bonk->GetString(BONK_STRING_AFFIX_VAMPIRIC_TEXT, { percent(BONK_VAMPIRIC_HEAL * 100.0f) }); break;
            case AFFIX_BOLSTERING: text = bonk->GetString(BONK_STRING_AFFIX_BOLSTERING_TEXT, { percent(BONK_BOLSTER_BONUS * 100.0f) }); break;
            case AFFIX_SANGUINE:   text = bonk->GetString(BONK_STRING_AFFIX_SANGUINE_TEXT); break;
            case AFFIX_BULWARK:    text = bonk->GetString(BONK_STRING_AFFIX_BULWARK_TEXT, { percent(BONK_SHIELD_HEALTH * 100.0f), seconds(BONK_SHIELD_INTERVAL) }); break;
            case AFFIX_FORTIFIED:  text = bonk->GetString(BONK_STRING_AFFIX_FORTIFIED_TEXT, { percent((BONK_FORTIFIED_HEALTH - 1.0f) * 100.0f) }); break;
            case AFFIX_FRENZIED:   text = bonk->GetString(BONK_STRING_AFFIX_FRENZIED_TEXT, { percent((BONK_FRENZIED_SPEED - 1.0f) * 100.0f) }); break;
            case AFFIX_RAGING:     text = bonk->GetString(BONK_STRING_AFFIX_RAGING_TEXT, { percent((BONK_RAGING_DAMAGE - 1.0f) * 100.0f), percent(BONK_RAGING_HEALTH) }); break;
            case AFFIX_VOLCANIC:   text = bonk->GetString(BONK_STRING_AFFIX_VOLCANIC_TEXT); break;
            default: break;
        }
        if (bonk->IsAddonReady())
        {
            WorldPacket data(SMSG_HOA_MESSAGE);
            HoAWriteAffixInfo(data, bonk->GetString(BONK_AFFIXES[affix].name), BONK_AFFIXES[affix].icon, text);
            bonk->GetPlayer()->GetSession()->SendPacket(&data);
        }
    }
}

void BonkMobAI::Bolster()
{
    if (m_bolsterStacks >= BONK_BOLSTER_MAX || !m_creature->IsAlive())
        return;
    ++m_bolsterStacks;
    ScaleHealth(1.0f + BONK_BOLSTER_BONUS);
    m_creature->SetObjectScale(m_creature->GetObjectScale() * BONK_BOLSTER_SCALE);
    m_creature->UpdateModelData();
}

float BonkMobAI::GetMeleeHit() const
{
    return (m_creature->GetFloatValue(UNIT_FIELD_MINDAMAGE) + m_creature->GetFloatValue(UNIT_FIELD_MAXDAMAGE)) / 2.0f;
}

float BonkMobAI::GetHitScale(BonkRun const* run) const
{
    float scale = (1.0f + BONK_BOLSTER_BONUS * m_bolsterStacks) * run->GetMobDamageMultiplier(m_creature);
    if (m_enraged)
        scale *= BONK_RAGING_DAMAGE;
    if (m_phaseEnraged)
        scale *= BONK_PHASE_ENRAGE;
    return scale;
}

BonkEnemyHit BonkMobAI::MakeHit(BonkRun const* run, uint32 spellId, uint32 damage, uint32 windId) const
{
    BonkEnemyHit hit;
    hit.caster = m_creature->GetObjectGuid();
    hit.striker = BonkRun::DescribeStriker(m_creature);
    hit.windId = windId;
    hit.spellId = spellId;
    hit.damage = damage;
    hit.scale = GetHitScale(run);
    hit.kind = m_kind;
    hit.archetype = m_archetype;
    hit.looker = m_creature->GetObjectGuid();
    return hit;
}

BonkEnemyHit BonkMobAI::MakeAbilityHit(BonkRun const* run, BonkMobAbility const& ability, uint32 spellId, uint32 damage, uint32 windId) const
{
    BonkEnemyHit hit = MakeHit(run, spellId, damage, windId);
    hit.castKit = GetCastKit(ability);
    hit.impactKit = GetImpactKit(ability);
    return hit;
}

void BonkMobAI::StrikeOwner(Player* owner, BonkMobAbility const& ability, float x, float y, float z)
{
    int32 const damage = int32(GetShapeDamage(ability));
    uint32 const impact = GetImpactKit(ability);
    BonkRun* run = owner->GetBonkPlayer()->GetRun();
    if (!impact || !run)
    {
        m_creature->CastCustomSpell(owner, BONK_SPELL_CHARGE_HIT, damage, {}, {}, true);
        return;
    }
    run->ShowKitAt(impact, x, y, z);
    m_creature->CastCustomSpell(owner, BONK_SPELL_PLAIN_HIT, damage, {}, {}, true);
}

uint32 BonkMobAI::GetAreaDamage(BonkMobAbility const& ability, SpellEntry const* spellInfo) const
{
    if (ability.damage > 0.0f)
        return uint32(std::max(1.0f, GetMeleeHit() * ability.damage));
    return DealsDamage(spellInfo) ? uint32(std::max(1.0f, GetMeleeHit())) : 0;
}

uint32 BonkMobAI::GetShapeDamage(BonkMobAbility const& ability) const
{
    return uint32(std::max(1.0f, GetMeleeHit() * (ability.damage > 0.0f ? ability.damage : BONK_SHAPE_DAMAGE)));
}

void BonkMobAI::Arrive(bool flash)
{
    m_arriveTimer = BONK_ARRIVE_MS;
    Halt();
    m_creature->GetMotionMaster()->MoveIdle();
    if (flash)
        ShowArrivalFlash();
}

void BonkMobAI::ShowArrivalFlash()
{
    if (uint32 const kit = BonkRun::GetSpawnKit())
        m_creature->SendPlaySpellVisualKit(kit);
}

void BonkMobAI::Hold(uint32 ms)
{
    m_arriveTimer = int32(ms);
    Halt();
    m_creature->GetMotionMaster()->MoveIdle();
}

void BonkMobAI::Pull(float x, float y, float z, float speed, uint32 settleMs)
{
    m_arriveTimer = int32(m_creature->GetDistance2d(x, y) / std::max(1.0f, speed) * IN_MILLISECONDS + settleMs);
    Halt();
    m_creature->GetMotionMaster()->MovePoint(0, x, y, z, MOVE_RUN_MODE | MOVE_FORCE_DESTINATION, speed);
}

void BonkMobAI::Halt()
{
    m_creature->m_targetNotReachableTimer = 0;

    AbandonWindups();
    m_boltTarget.Clear();
    m_creature->InterruptNonMeleeSpells(false);
    m_creature->AttackStop();
    m_creature->StopMoving();
    m_creature->GetMotionMaster()->Clear(false);
}

void BonkMobAI::AttackStart(Unit* victim)
{
    Player* owner = GetOwner();
    if (!owner || victim != owner || m_arriveTimer > 0 || m_fleeing || m_stationary || m_passive || !m_raidTarget.IsEmpty() ||
        m_chargeState != CHARGE_NONE || m_areaWinding || m_landingTimer > 0 || IsHoldingForBolt())
        return;

    SetMeleeAttack(true);
    CreatureAI::AttackStart(victim);

    if (m_mob && m_mob->role == BONK_ROLE_RANGED && m_creature->GetVictim() == victim)
        m_creature->GetMotionMaster()->MoveChase(victim, m_mob->range);
}

void BonkMobAI::EnterEvadeMode()
{
    Player* owner = GetOwner();
    BonkRun* run = owner ? owner->GetBonkPlayer()->GetRun() : nullptr;
    if (run && run->IsActive() && owner->IsAlive() && m_creature->IsAlive())
    {
        AttackStart(owner);
        return;
    }

    CreatureAI::EnterEvadeMode();
}

void BonkMobAI::QuietAffixes(uint32 durationMs)
{
    m_affixesQuietUntilMs = WorldTimer::getMSTime() + durationMs;
}

bool BonkMobAI::AreAffixesQuiet() const
{
    return m_affixesQuietUntilMs && int32(m_affixesQuietUntilMs - WorldTimer::getMSTime()) > 0;
}

void BonkMobAI::KeepSummonsUntargeted(Player* owner, BonkRun const* run)
{
    Unit* victim = m_creature->GetVictim();
    if (victim && victim != owner && run->IsSummon(victim))
    {
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Bonk summon target: %s attacked summon %s; switching back to the hero", m_creature->GetName(), victim->GetName());
        m_creature->AttackStop();
        AttackStart(owner);
    }

    bool const casting = m_creature->m_castingTargetGuid != 0;
    ObjectGuid const shown = casting ? ObjectGuid(m_creature->m_castingTargetGuid) : m_creature->GetTargetGuid();
    if (shown.IsEmpty() || shown == owner->GetObjectGuid())
        return;
    Unit* unit = m_creature->GetMap()->GetUnit(shown);
    if (!unit || !run->IsSummon(unit))
        return;
    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Bonk summon target: %s showed summon %s as its %s", m_creature->GetName(), unit->GetName(), casting ? "cast target" : "target");
    if (casting)
        m_creature->ClearCastingTarget();
    else
        m_creature->SetTargetGuid(m_creature->GetVictim() == owner ? owner->GetObjectGuid() : ObjectGuid());
}

void BonkMobAI::UpdateAI(uint32 const diff)
{
    if (m_creature->HasCreatureState(CSTATE_DESPAWNING))
        return;

    Player* spawner = GetSpawner();
    BonkRun* run = spawner ? spawner->GetBonkPlayer()->GetRun() : nullptr;
    if (!run || !run->IsActive() || (!spawner->IsAlive() && !BonkCoop::IsDowned(spawner)))
    {
        m_creature->DespawnOrUnsummon();
        return;
    }

    UpdateChaseTarget(diff, spawner);
    Player* owner = GetOwner();
    if (!owner->IsAlive())
        return;

    if (run->IsPaused())
    {
        SetFrozen(true);
        return;
    }
    SetFrozen(false);
    KeepSummonsUntargeted(owner, run);

    m_creature->SetCombatStartPosition(m_creature->GetPositionX(), m_creature->GetPositionY(), m_creature->GetPositionZ());

    if (m_arriveTimer > 0)
    {
        m_arriveTimer -= int32(diff);
        if (m_arriveTimer > 0)
            return;
    }

    if (IsHeldByControl() && (m_chargeState == CHARGE_WINDUP || (m_areaWinding && !m_leapLaunched)))
    {
        ReportTest("was interrupted during a wind-up.");
        AbandonWindups();
        ResumeChase(owner);
    }
    if (IsHeldByControl() && IsHoldingForBolt())
    {
        ReportTest("was interrupted while casting.");
        m_boltTarget.Clear();
        ClearWindupLook();
    }

    if (m_fleeing)
    {
        UpdateFlee(diff, owner);
        return;
    }
    if (m_creature->HasUnitState(UNIT_STATE_FLEEING))
        return;
    if (IsWard())
    {
        UpdateWard(diff);
        return;
    }
    if (m_stationary || m_passive)
        return;

    if (!m_raidTarget.IsEmpty())
    {
        Creature* target = m_creature->GetMap()->GetCreature(m_raidTarget);
        if (target && target->IsAlive())
        {
            if (m_creature->GetMotionMaster()->GetCurrentMovementGeneratorType() != FOLLOW_MOTION_TYPE)
                m_creature->GetMotionMaster()->MoveFollow(target, BONK_RAID_FOLLOW_DISTANCE, m_raidAngle);
            return;
        }
        m_raidTarget.Clear();
        AttackStart(owner);
    }

    UpdateBossPressure(diff, owner, run);
    if (!m_movesOff && (UpdateCharge(diff, owner) || UpdateLanding(diff, owner) || UpdateArea(diff, owner)))
    {
        ResetProgressWatch();
        return;
    }

    if (m_creature->GetVictim() != owner)
        AttackStart(owner);

    UpdatePerchChase(run);
    if (m_flyingIn)
    {
        if (m_creature->GetMotionMaster()->GetCurrentMovementGeneratorType() == POINT_MOTION_TYPE)
            ResetProgressWatch();
        else
        {
            m_flyingIn = false;
            ResumeChase(owner);
        }
    }
    UpdateProgressWatch(diff, owner, run);
    if (m_creature->m_targetNotReachableTimer > BONK_UNREACHABLE_MS)
    {
        m_creature->m_targetNotReachableTimer = 0;
        ResetProgressWatch();
        run->OnMobStuck(m_creature);
    }

    UpdatePhases(diff, owner);
    UpdateAffixes(diff, owner);
    if (!m_movesOff)
        UpdateAbilities(diff, owner);
    if (m_creature->IsBonkCrowdTouching() && DoMeleeAttackIfReady())
        run->ReportSandboxSwing(m_creature);
}

bool BonkMobAI::CanCrowdWalk() const
{
    return m_kind != BONK_SPAWN_BOSS && m_kind != BONK_SPAWN_MINIBOSS && !IsFlyer() && !m_flyingIn && !m_frozen && !m_fleeing &&
        !m_stationary && !m_passive && !m_stampede && !m_movesOff && m_raidTarget.IsEmpty() && m_arriveTimer <= 0 &&
        m_chargeState == CHARGE_NONE && !m_areaWinding && m_landingTimer <= 0 && m_boltTarget.IsEmpty();
}

float BonkMobAI::GetHoldRange() const
{
    return m_mob && m_mob->role == BONK_ROLE_RANGED ? m_mob->range : 0.0f;
}

void BonkMobAI::ResetProgressWatch()
{
    m_watchTimer = 0;
    m_watchX = m_creature->GetPositionX();
    m_watchY = m_creature->GetPositionY();
}

void BonkMobAI::UpdatePerchChase(BonkRun const* run)
{
    bool const closeIn = run->IsHeroPerched() && !IsFlyer();
    if (closeIn == m_creature->HasUnitState(UNIT_STATE_ALLOW_INCOMPLETE_PATH))
        return;
    if (closeIn)
        m_creature->AddUnitState(UNIT_STATE_ALLOW_INCOMPLETE_PATH);
    else
        m_creature->ClearUnitState(UNIT_STATE_ALLOW_INCOMPLETE_PATH);
}

void BonkMobAI::UpdateProgressWatch(uint32 diff, Player* owner, BonkRun* run)
{
    if (m_creature->IsBonkCrowdDriven() || m_creature->IsNonMeleeSpellCasted(false) ||
        m_creature->HasUnitState(UNIT_STATE_ROOT | UNIT_STATE_STUNNED | UNIT_STATE_CONFUSED))
    {
        ResetProgressWatch();
        return;
    }
    m_watchTimer += diff;
    if (m_watchTimer < BONK_STUCK_CHECK_MS)
        return;

    float const dx = m_creature->GetPositionX() - m_watchX;
    float const dy = m_creature->GetPositionY() - m_watchY;
    float const reach = (m_mob && m_mob->role == BONK_ROLE_RANGED ? m_mob->range : 0.0f) + BONK_STUCK_SLACK;
    bool const stuck = dx * dx + dy * dy < BONK_STUCK_MIN_MOVE * BONK_STUCK_MIN_MOVE && !m_creature->IsWithinDistInMap(owner, reach);
    ResetProgressWatch();
    if (stuck)
        run->OnMobStuck(m_creature);
}

void BonkMobAI::SetFrozen(bool frozen)
{
    if (m_frozen == frozen)
        return;
    m_frozen = frozen;
    m_creature->SetTimeFrozen(frozen && m_creature->IsAlive());

    if (frozen)
    {
        if (m_stampede)
        {
            m_creature->DespawnOrUnsummon(1);
            return;
        }
        m_boltTarget.Clear();
        if (!m_areaWinding)
            ClearWindupLook();
        m_creature->InterruptNonMeleeSpells(false);
        m_creature->AttackStop();
        m_creature->GetMotionMaster()->Clear(false);
        m_creature->GetMotionMaster()->MoveIdle();
        m_creature->AddUnitState(UNIT_STATE_ROOT);
        m_creature->SetRooted(true);
        return;
    }

    if (m_stationary)
        return;
    m_creature->ClearUnitState(UNIT_STATE_ROOT);
    m_creature->SetRooted(false);
    if (m_fleeing && !m_fleeStanding)
        m_fleeTimer = 0;
    else if (ResumeWindup())
        return;
    else if (Player* owner = GetOwner())
        AttackStart(owner);
}

bool BonkMobAI::IsHeldByControl() const
{
    return m_creature->HasUnitState(UNIT_STATE_STUNNED | UNIT_STATE_CONFUSED | UNIT_STATE_FLEEING);
}

void BonkMobAI::AbandonWindups()
{
    Player* owner = GetOwner();
    BonkRun* run = owner ? owner->GetBonkPlayer()->GetRun() : nullptr;
    ClearWindupLook();
    if (m_areaWinding)
    {
        m_areaWinding = false;
        if (m_areaAbility >= 0 && m_areaAbility < int32(m_abilityTimers.size()))
            m_abilityTimers[m_areaAbility] = BONK_AREA_RETRY_MS;
        if (run)
            run->CancelEnemyWindup(m_creature, m_areaWindId);
    }
    if (m_chargeState != CHARGE_NONE)
    {
        if (m_chargeState == CHARGE_WINDUP && run)
            run->CancelEnemyWindup(m_creature, m_chargeWindId);
        m_chargeState = CHARGE_NONE;
        m_chargeTimer = BONK_CHARGE_INTERVAL / 2;
    }
    m_chargesLeft = 0;
    m_landingTimer = 0;
}

bool BonkMobAI::ResumeWindup()
{
    if (m_chargeState == CHARGE_DASH)
    {
        m_creature->GetMotionMaster()->MovePoint(0, m_dashX, m_dashY, m_dashZ, MOVE_RUN_MODE | MOVE_FORCE_DESTINATION, BONK_CHARGE_SPEED);
        return true;
    }
    if (m_chargeState == CHARGE_WINDUP)
    {
        HoldStill();
        m_creature->SetFacingTo(m_chargeAngle);
        return true;
    }
    if (m_areaWinding && m_leapLaunched)
    {
        m_leapTravelMs = std::max(BONK_LEAP_LAUNCH_EARLY_MS, m_areaTimer);
        LaunchLeap();
        return true;
    }
    if (m_landingTimer > 0)
    {
        if (m_creature->GetDistance2d(m_leapX, m_leapY) > 0.5f)
            m_creature->GetMotionMaster()->MovePoint(0, m_leapX, m_leapY, m_leapZ, MOVE_RUN_MODE | MOVE_FORCE_DESTINATION, BONK_LEAP_SPEED);
        return true;
    }
    if (!m_areaWinding)
        return false;
    HoldStill();
    m_creature->SetFacingTo(m_areaOrientation);
    return true;
}

bool BonkMobAI::UpdateLanding(uint32 diff, Player* owner)
{
    if (m_landingTimer <= 0)
        return false;
    m_landingTimer -= int32(diff);
    if (m_landingTimer <= 0)
        ResumeChase(owner);
    return true;
}

void BonkMobAI::Cast(BonkMobAbility const& ability, Player* owner, bool triggered)
{
    SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(ability.spellId);
    if (!spellInfo)
        return;

    if (ability.target == BONK_ABILITY_PLAYER && spellInfo->HasEffect(SPELL_EFFECT_CHARGE))
    {
        StartCharge(owner, ability.damage > 0.0f ? ability.damage : BONK_CHARGE_DAMAGE);
        return;
    }

    if (ability.target == BONK_ABILITY_PLAYER && ability.damageEffectIndex >= 0 &&
        spellInfo->Effect[ability.damageEffectIndex] == SPELL_EFFECT_SCHOOL_DAMAGE)
        if (BonkRun* run = owner->GetBonkPlayer()->GetRun())
        {
            AimBolt(ability, spellInfo, owner, run);
            return;
        }

    Unit* target = ability.target == BONK_ABILITY_SELF ? static_cast<Unit*>(m_creature) : owner;

    optional<int32> basePoints[MAX_EFFECT_INDEX];
    if (ability.damage > 0.0f && ability.damageEffectIndex >= 0)
        basePoints[ability.damageEffectIndex] = std::max(1, int32(GetMeleeHit() * ability.damage));

    if (target != m_creature)
        m_creature->SetFacingToObject(target);
    m_creature->CastCustomSpell(target, spellInfo, basePoints[0], basePoints[1], basePoints[2], triggered);
    RemoveSlows(owner, spellInfo);
}

void BonkMobAI::RemoveSlows(Player* owner, SpellEntry const* spellInfo)
{
    for (uint32 i = 0; i < MAX_EFFECT_INDEX; ++i)
        switch (spellInfo->EffectApplyAuraName[i])
        {
            case SPELL_AURA_MOD_DECREASE_SPEED:
            case SPELL_AURA_MOD_MELEE_HASTE:
            case SPELL_AURA_MOD_RANGED_HASTE:
            case SPELL_AURA_MOD_ATTACKSPEED:
                owner->RemoveSingleAuraFromSpellAuraHolder(spellInfo->Id, SpellEffectIndex(i), m_creature->GetObjectGuid());
                break;
            default:
                break;
        }
}

void BonkMobAI::AimBolt(BonkMobAbility const& ability, SpellEntry const* spellInfo, Player* owner, BonkRun* run)
{
    float const x = owner->GetPositionX(), y = owner->GetPositionY(), z = owner->GetPositionZ();
    uint32 const castTime = spellInfo->GetCastTime(m_creature);
    uint32 const flight = GetBoltFlightMs(spellInfo, m_creature->GetDistance(x, y, z));
    uint32 const lead = std::max(BONK_BOLT_AIM_BEFORE_MS, BONK_BOLT_MIN_WARN_MS > flight ? BONK_BOLT_MIN_WARN_MS - flight : 0);

    if (!run->ReserveBolt(std::max(castTime, lead) + flight))
        return;
    ObjectGuid const target = run->PlaceBoltTarget(x, y, z, std::max(castTime, lead) + 2 * flight + BONK_BOLT_TARGET_LINGER_MS);
    if (target.IsEmpty())
        return;

    m_boltTarget = target;
    m_boltSpell = spellInfo->Id;
    m_boltDamage = uint32(std::max(1.0f, GetMeleeHit() * ability.damage));
    m_boltLead = lead;
    m_boltServerDrawn = !sBonkMgr.GetBoltLook(spellInfo->Id);
    m_boltCastKit = ability.castKit;
    m_boltImpactKit = ability.impactKit;
    m_boltStartTimer = m_boltServerDrawn ? int32(std::max(castTime, lead)) : castTime < lead ? int32(lead - castTime) : 0;
    m_boltAimTimer = castTime > lead ? int32(castTime - lead) : 0;
    m_boltStarted = m_boltAimed = false;
    if (m_boltServerDrawn)
    {
        HoldStill();
        m_creature->SetFacingToObject(owner);
        ShowWindupLook(spellInfo);
    }
    UpdateBolt(0, owner);
}

void BonkMobAI::UpdateBolt(uint32 diff, Player* owner)
{
    m_boltStartTimer -= int32(diff);
    m_boltAimTimer -= int32(diff);

    if (!m_boltAimed && m_boltAimTimer <= 0)
        AimBoltNow(owner);
    if (!m_boltTarget.IsEmpty() && !m_boltStarted && m_boltStartTimer <= 0)
        LaunchBolt();
    if (m_boltStarted && m_boltAimed)
        m_boltTarget.Clear();
}

void BonkMobAI::AimBoltNow(Player* owner)
{
    m_boltAimed = true;
    Creature* target = m_creature->GetMap()->GetCreature(m_boltTarget);
    BonkRun* run = owner->GetBonkPlayer()->GetRun();
    SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(m_boltSpell);
    if (!target || !run || !spellInfo || (m_boltStarted && !m_creature->IsNonMeleeSpellCasted(false)))
    {
        if (target)
            target->DespawnOrUnsummon();
        m_boltTarget.Clear();
        ClearWindupLook();
        return;
    }

    float const lead = BONK_BOLT_LEAD_BY_STEP[std::min(2u, run->GetDifficultyStep())];
    float x, y, z;
    uint32 flight = GetBoltFlightMs(spellInfo, m_creature->GetDistance(owner));
    PredictPlayer(owner, uint32((m_boltLead + flight) * lead), x, y, z);
    flight = GetBoltFlightMs(spellInfo, m_creature->GetDistance(x, y, z));
    PredictPlayer(owner, uint32((m_boltLead + flight) * lead), x, y, z);
    target->NearTeleportTo(x, y, z, 0.0f);

    ObjectGuid const targetGuid = m_boltTarget;
    BonkEnemyHit hit = MakeHit(run, m_boltSpell, m_boltDamage);
    if (m_boltServerDrawn)
        hit.impactKit = m_boltImpactKit;
    run->AddEnemyTelegraph(m_creature, BONK_TELEGRAPH_CIRCLE, x, y, z, 0.0f, BONK_BOLT_RADIUS, m_boltLead + flight,
        [run, hit, targetGuid, x, y]() { run->LandBolt(hit, targetGuid, x, y, BONK_BOLT_RADIUS); });
    run->LaunchEnemyMissile(m_creature->GetObjectGuid(), targetGuid, m_boltSpell, m_boltLead, flight, x, y, z);
}

void BonkMobAI::LaunchBolt()
{
    m_boltStarted = true;
    if (m_boltServerDrawn)
    {
        ReleaseDrawnBolt();
        return;
    }
    Creature* target = m_creature->GetMap()->GetCreature(m_boltTarget);
    if (!target)
    {
        m_boltTarget.Clear();
        return;
    }
    m_creature->SetFacingToObject(target);
    m_creature->CastCustomSpell(GetCastTarget(target), m_boltSpell, 1, 1, 1, false);
}

void BonkMobAI::ReleaseDrawnBolt()
{
    ClearWindupLook();
    if (Creature* target = m_creature->GetMap()->GetCreature(m_boltTarget))
        m_creature->SetFacingToObject(target);
    if (m_boltCastKit)
        m_creature->SendPlaySpellVisualKit(m_boltCastKit);
    if (Player* owner = GetOwner())
        ResumeChase(owner);
}

bool BonkMobAI::IsHoldingForBolt() const
{
    return m_boltServerDrawn && !m_boltStarted && !m_boltTarget.IsEmpty();
}

Unit* BonkMobAI::GetCastTarget(Creature* target)
{
    BonkBoltLook const* look = sBonkMgr.GetBoltLook(m_boltSpell);
    Player* owner = GetOwner();
    BonkRun* run = owner ? owner->GetBonkPlayer()->GetRun() : nullptr;
    if (!look || !look->castNear || !run)
        return target;

    float const angle = m_creature->GetAngle(target);
    float const x = m_creature->GetPositionX() + BONK_CAST_NEAR_DISTANCE * std::cos(angle);
    float const y = m_creature->GetPositionY() + BONK_CAST_NEAR_DISTANCE * std::sin(angle);
    Creature* spot = m_creature->GetMap()->GetCreature(run->PlaceBoltTarget(x, y, target->GetPositionZ(), BONK_CAST_NEAR_LIFETIME_MS));
    return spot ? spot : target;
}

void BonkMobAI::UpdateAbilities(uint32 diff, Player* owner)
{
    if (!m_mob)
        return;

    for (int32& timer : m_abilityTimers)
        timer -= int32(diff);
    m_abilityGapTimer -= int32(diff);
    m_signatureTimer -= int32(diff);
    m_fillerTimer -= int32(diff);
    if (IsDancing())
        return;

    if (!m_boltTarget.IsEmpty())
    {
        UpdateBolt(diff, owner);
        return;
    }

    if (m_creature->IsNonMeleeSpellCasted(false))
        return;

    if (m_forcedAbility >= 0 && m_forcedAbility < int32(m_mob->abilities.size()))
    {
        size_t const forced = size_t(m_forcedAbility);
        m_forcedAbility = -1;
        UseAbility(forced, owner);
        return;
    }
    if (m_affixWarnTimer > 0)
    {
        m_abilityGapTimer = std::max(m_abilityGapTimer, int32(BONK_MECHANIC_REST_MS));
        return;
    }
    if (m_abilityGapTimer > 0)
        return;
    BonkRun const* run = owner->GetBonkPlayer()->GetRun();
    if (IsBossOrMini() && run && run->AreBigMovesHeld(m_creature->GetObjectGuid()))
        return;

    float const distance = m_creature->GetDistance(owner);
    int32 chosen = -1;
    for (size_t i = 0; i < m_mob->abilities.size(); ++i)
    {
        BonkMobAbility const& ability = m_mob->abilities[i];
        if (m_abilityTimers[i] > 0 || distance < ability.minRange || distance > ability.maxRange)
            continue;
        if (m_creature->GetHealthPercent() > ability.belowHealth)
            continue;
        if (ability.maxRange < BONK_TOUCH_ABILITY_RANGE && !m_creature->IsBonkCrowdTouching())
            continue;
        if (ability.target == BONK_ABILITY_PLAYER && !m_creature->IsWithinLOSInMap(owner))
            continue;
        if (IsBossOrMini() && !IsMoveTurnOpen(ability))
            continue;
        if (!IsBossOrMini())
        {
            UseAbility(i, owner);
            return;
        }
        if (chosen < 0 || m_abilityTimers[i] < m_abilityTimers[chosen])
            chosen = int32(i);
    }
    if (chosen >= 0)
        UseAbility(size_t(chosen), owner);
}

bool BonkMobAI::IsMoveTurnOpen(BonkMobAbility const& ability) const
{
    if (IsSignatureShape(ability.shape))
        return m_signatureTimer <= 0;
    return m_fillerTimer <= 0;
}

float BonkMobAI::GetMovePace(BonkRun const* run) const
{
    uint32 const step = run ? run->GetDifficultyStep() : 0;
    if (step >= 2)
        return Tune(TUNE_PACE_MYTHIC);
    if (step == 1)
        return Tune(TUNE_PACE_HEROIC);
    return 1.0f;
}

void BonkMobAI::StartMoveTurn(BonkMobAbility const& ability, BonkRun* run)
{
    float const pace = std::max(0.1f, GetMovePace(run));
    if (!IsSignatureShape(ability.shape))
    {
        m_fillerTimer = int32(TuneMs(TUNE_FILLER) * pace);
        m_abilityGapTimer = int32(GetMoveGapMs(run));
        return;
    }
    m_signatureTimer = int32(TuneMs(TUNE_SIGNATURE) * pace);
    m_fillerTimer = std::max(m_fillerTimer, int32(TuneMs(TUNE_SIGNATURE_GAP)));
    m_abilityGapTimer = int32(TuneMs(TUNE_SIGNATURE_GAP));
    if (run)
        run->HoldBigMoves(m_creature->GetObjectGuid(), BONK_SIGNATURE_HOLD_MS);
}

float BonkMobAI::GetKindSize(BonkAbilityShape shape, float size) const
{
    if (!IsBossOrMini())
        return size;
    bool const boss = m_kind == BONK_SPAWN_BOSS;
    switch (shape)
    {
        case BONK_SHAPE_NOVA:
            return std::max(size, boss ? BONK_BOSS_NOVA_SIZE + std::min(BONK_BOSS_NOVA_BODY_GROWTH, m_creature->GetObjectBoundingRadius()) :
                BONK_MINI_NOVA_SIZE);
        case BONK_SHAPE_CONE:
        case BONK_SHAPE_BREATHS:
            return std::max(size, boss ? BONK_BOSS_CONE_SIZE : BONK_MINI_CONE_SIZE);
        case BONK_SHAPE_TAIL:
            return std::max(size, boss ? BONK_BOSS_TAIL_SIZE : BONK_MINI_TAIL_SIZE);
        case BONK_SHAPE_LEAP:
            return std::max(size, boss ? BONK_BOSS_LEAP_RADIUS : BONK_MINI_LEAP_RADIUS);
        case BONK_SHAPE_DONUT:
            return std::max(size, boss ? BONK_BOSS_DONUT_SIZE : BONK_MINI_DONUT_SIZE);
        default:
            return size;
    }
}

uint32 BonkMobAI::GetConeWarnMs(BonkRun const* run, Player const* hero, float size) const
{
    uint32 const warnMs = GetWarnMs(run, BONK_AREA_WARN_MS);
    if (!IsBossOrMini())
        return warnMs;
    float const speed = std::max(1.0f, hero->GetSpeed(MOVE_RUN));
    uint32 const escapeMs = BONK_REACTION_MS + uint32(size * BONK_CONE_WORST_ESCAPE / speed * IN_MILLISECONDS);
    return std::max(warnMs, escapeMs);
}

void BonkMobAI::UseAbility(size_t index, Player* owner)
{
    BonkMobAbility const& ability = m_mob->abilities[index];
    m_abilityTimers[index] = int32(ability.cooldownMs * frand(0.85f, 1.15f));
    if (IsBossOrMini())
        StartMoveTurn(ability, owner->GetBonkPlayer()->GetRun());
    m_chargesLeft = ability.shape == BONK_SHAPE_SPELL && ability.count > 1 ? ability.count - 1 : 0;
    ReportTest("uses " + (ability.label.empty() ? "spell " + std::to_string(ability.spellId) : ability.label) + ".");
    if (ability.shape != BONK_SHAPE_SPELL)
    {
        StartShape(int32(index), owner);
        return;
    }
    SpellEntry const* spellInfo = ability.target == BONK_ABILITY_SELF ? sSpellMgr.GetSpellEntry(ability.spellId) : nullptr;
    if (spellInfo && GetAreaReach(spellInfo) > 0.0f)
        StartArea(int32(index), owner);
    else
        Cast(ability, owner, false);
}

bool BonkMobAI::IsBusyWindingUp() const
{
    return m_areaWinding || m_chargeState == CHARGE_WINDUP;
}

bool BonkMobAI::ForceAbility(uint32 number)
{
    if (!m_mob || !number || number > m_mob->abilities.size())
        return false;
    m_forcedAbility = int32(number - 1);
    return true;
}

bool BonkMobAI::UsesExactPoints(SpellCaster const* caster)
{
    Creature const* creature = caster ? caster->ToCreature() : nullptr;
    return creature && dynamic_cast<BonkMobAI const*>(creature->AI());
}

bool BonkMobAI::BlocksTriggeredSpell(SpellCaster const* caster, SpellEntry const* triggeredBy)
{
    Creature const* creature = caster && triggeredBy ? caster->ToCreature() : nullptr;
    BonkMobAI const* ai = creature ? dynamic_cast<BonkMobAI const*>(creature->AI()) : nullptr;
    if (!ai || !ai->m_mob)
        return false;
    for (BonkMobAbility const& ability : ai->m_mob->abilities)
        if (ability.spellId == triggeredBy->Id)
            return true;
    return false;
}

void BonkMobAI::ReportTest(std::string const& text) const
{
    if (m_kind != BONK_SPAWN_BOSS && m_kind != BONK_SPAWN_MINIBOSS)
        return;
    Player* owner = GetOwner();
    BonkRun const* run = owner ? owner->GetBonkPlayer()->GetRun() : nullptr;
    if (!run || !run->IsSandbox())
        return;
    ChatHandler(owner).SendSysMessage(("[Boss test] " + std::string(m_creature->GetName()) + " " + text).c_str());
}

void BonkMobAI::UpdateAffixes(uint32 diff, Player* owner)
{
    m_affixWarnTimer -= int32(diff);

    if (HasAffix(AFFIX_BULWARK))
    {
        if (m_creature->HasAura(BONK_SPELL_SHIELD))
            m_shieldTimer = BONK_SHIELD_INTERVAL;
        else
        {
            m_shieldTimer -= int32(diff);
            if (m_shieldTimer <= 0)
            {
                m_shieldTimer = BONK_SHIELD_INTERVAL;
                int32 const absorb = std::max(1, int32(m_creature->GetMaxHealth() * BONK_SHIELD_HEALTH));
                m_creature->CastCustomSpell(m_creature, BONK_SPELL_SHIELD, absorb, {}, {}, true);
            }
        }
    }

    if (HasAffix(AFFIX_EXPLOSIVE))
    {
        m_burnTimer -= int32(diff);
        if (m_burnTimer <= 0 && IsBusyWindingUp())
            m_burnTimer = int32(BONK_MECHANIC_REST_MS);
        else if (m_burnTimer <= 0 && m_creature->IsWithinDistInMap(owner, BONK_BURN_RANGE))
        {
            m_burnTimer = BONK_BURN_INTERVAL;
            m_affixWarnTimer = std::max(m_affixWarnTimer, int32(BONK_BURN_WARN_MS));
            if (BonkRun* run = owner->GetBonkPlayer()->GetRun())
            {
                float const x = m_creature->GetPositionX(), y = m_creature->GetPositionY(), z = m_creature->GetPositionZ();
                BonkEnemyHit const hit = MakeHit(run, 0, uint32(std::max(1.0f, GetMeleeHit() * BONK_BURN_DAMAGE)));
                run->AddEnemyTelegraph(m_creature, BONK_TELEGRAPH_CIRCLE, x, y, z, 0.0f, BONK_BURN_RADIUS, BONK_BURN_WARN_MS,
                    [run, hit, x, y, z]() { run->Erupt(hit, x, y, z, BONK_BURN_RADIUS); });
            }
        }
    }

    if (HasAffix(AFFIX_VOLCANIC))
    {
        m_eruptionTimer -= int32(diff);
        if (m_eruptionTimer <= 0 && IsBusyWindingUp())
            m_eruptionTimer = int32(BONK_MECHANIC_REST_MS);
        else if (m_eruptionTimer <= 0 && m_creature->IsWithinDistInMap(owner, BONK_ERUPTION_RANGE))
        {
            m_eruptionTimer = BONK_ERUPTION_INTERVAL;
            m_affixWarnTimer = std::max(m_affixWarnTimer, int32(BONK_ERUPTION_WARN_MS));
            if (BonkRun* run = owner->GetBonkPlayer()->GetRun())
            {
                float const x = owner->GetPositionX(), y = owner->GetPositionY(), z = owner->GetPositionZ();
                BonkEnemyHit const hit = MakeHit(run, 0, uint32(std::max(1.0f, GetMeleeHit() * BONK_ERUPTION_DAMAGE)));
                run->AddEnemyTelegraph(m_creature, BONK_TELEGRAPH_CIRCLE, x, y, z, 0.0f, BONK_ERUPTION_RADIUS, BONK_ERUPTION_WARN_MS,
                    [run, hit, x, y, z]() { run->Erupt(hit, x, y, z, BONK_ERUPTION_RADIUS); });
            }
        }
    }

    if (HasAffix(AFFIX_RAGING) && !m_enraged && m_creature->GetHealthPercent() < BONK_RAGING_HEALTH)
    {
        m_enraged = true;
        m_creature->AddAura(BONK_SPELL_RAGING);
        owner->GetBonkPlayer()->Notify(BONK_STRING_ENEMY_ENRAGED, { owner->GetBonkPlayer()->GetLocalName(m_creature) });
    }
}

void BonkMobAI::StartArea(int32 abilityIndex, Player* owner)
{
    if (!m_mob || abilityIndex < 0 || abilityIndex >= int32(m_mob->abilities.size()))
        return;

    BonkMobAbility const& ability = m_mob->abilities[abilityIndex];
    SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(ability.spellId);
    float const reach = spellInfo ? GetAreaReach(spellInfo) : 0.0f;
    uint32 const damage = spellInfo ? GetAreaDamage(ability, spellInfo) : 0;
    uint32 const spellId = ability.spellId;

    BonkRun* run = owner->GetBonkPlayer()->GetRun();
    if (!run || reach <= 0.0f)
    {
        Cast(ability, owner, false);
        return;
    }
    float const size = GetAreaSize(reach, owner->GetObjectBoundingRadius());
    if (size > BONK_AREA_MAX_SIZE)
    {
        ReportTest("skipped a move: its area is wider than " + std::to_string(int32(BONK_AREA_MAX_SIZE)) + " yd.");
        return;
    }

    m_areaWinding = true;
    m_areaWindId = ++m_windCount;
    m_areaAbility = abilityIndex;
    uint32 const warnMs = GetWarnMs(run, BONK_AREA_WARN_MS);
    m_areaTimer = int32(warnMs);
    m_areaSize = size;
    m_areaX = m_creature->GetPositionX();
    m_areaY = m_creature->GetPositionY();
    HoldStill();
    m_creature->SetFacingToObject(owner);
    ShowWindupLook(spellInfo);
    float const x = m_areaX, y = m_areaY, z = m_creature->GetPositionZ();
    BonkEnemyHit const hit = MakeHit(run, spellId, damage, m_areaWindId);
    run->AddEnemyTelegraph(m_creature, BONK_TELEGRAPH_CIRCLE, x, y, z, 0.0f, size, warnMs,
        [run, hit, x, y, z, size]() { run->LandWarning(hit, BONK_TELEGRAPH_CIRCLE, x, y, z, 0.0f, size); }, m_areaWindId);
}

void BonkMobAI::StartShape(int32 abilityIndex, Player* owner)
{
    BonkRun* run = owner->GetBonkPlayer()->GetRun();
    if (!run || !m_mob || abilityIndex < 0 || abilityIndex >= int32(m_mob->abilities.size()))
        return;
    BonkMobAbility const& ability = m_mob->abilities[abilityIndex];
    float const size = GetKindSize(ability.shape, std::max(1.0f, ability.size));
    uint32 const damage = GetShapeDamage(ability);

    switch (ability.shape)
    {
        case BONK_SHAPE_BARRAGE:
            PlayCastKit(ability, owner);
            LaunchBarrage(owner, run, MakeAbilityHit(run, ability, 0, damage), std::max(1u, ability.count), size,
                GetWarnMs(run, BONK_AREA_WARN_MS), ability.spellId);
            return;
        case BONK_SHAPE_TRAIL:
            run->SpawnPhaseAdds(m_creature, std::max(1u, ability.count), 0);
            return;
        case BONK_SHAPE_POOLS:
            PlayCastKit(ability, owner);
            StartPools(ability, owner, run);
            return;
        case BONK_SHAPE_LEAP:
            if (!StartLeap(abilityIndex, owner, run, damage))
                m_abilityTimers[abilityIndex] = int32(BONK_SHAPE_RETRY_MS);
            return;
        case BONK_SHAPE_SHOCKWAVE:
        case BONK_SHAPE_SPOKES:
            StartLines(abilityIndex, owner, run, damage);
            return;
        case BONK_SHAPE_BREATHS:
            StartBreaths(abilityIndex, owner, run, damage);
            return;
        case BONK_SHAPE_TAIL:
            StartFrontAndBack(abilityIndex, owner, run, damage);
            return;
        case BONK_SHAPE_WALLS:
            StartWalls(abilityIndex, owner, run, damage);
            return;
        case BONK_SHAPE_WREATH:
            StartWreath(abilityIndex, owner, run, damage);
            return;
        case BONK_SHAPE_METEORS:
            StartMeteors(abilityIndex, owner, run, damage);
            return;
        case BONK_SHAPE_DONUT:
            StartDonut(abilityIndex, owner, run, damage, size);
            return;
        case BONK_SHAPE_SWEEP:
            StartSweep(abilityIndex, owner, run, damage);
            return;
        default:
            break;
    }

    BonkTelegraphShape const shape = GetHeldShape(ability.shape);
    uint32 const warnMs = GetHeldWarnMs(ability.shape, run, owner, size) + GetBonkTelegraphLeadMs(shape);
    WindUp(abilityIndex, AimAngle(m_creature, owner, run, warnMs), warnMs);
    m_areaSize = shape == BONK_TELEGRAPH_CONE ? GetConeSize(size, run, owner, warnMs) : size;
    float const x = m_areaX, y = m_areaY, z = m_creature->GetPositionZ(), o = m_areaOrientation, heldSize = m_areaSize;
    BonkEnemyHit const hit = MakeAbilityHit(run, ability, BONK_SPELL_CHARGE_HIT, damage, m_areaWindId);
    run->AddEnemyTelegraph(m_creature, shape, x, y, z, o, heldSize, warnMs,
        [run, hit, shape, x, y, z, o, heldSize]() { run->LandWarning(hit, shape, x, y, z, o, heldSize); }, m_areaWindId);
}

void BonkMobAI::PlayCastKit(BonkMobAbility const& ability, Player* owner)
{
    if (!ability.castKit)
        return;
    m_creature->SetFacingToObject(owner);
    m_creature->SendPlaySpellVisualKit(ability.castKit);
}

void BonkMobAI::LaunchBarrage(Player* owner, BonkRun* run, BonkEnemyHit const& hit, uint32 count, float size, uint32 warnMs, uint32 missileSpell)
{
    SpellEntry const* missileInfo = missileSpell && sBonkMgr.GetBoltLook(missileSpell) ? sSpellMgr.GetSpellEntry(missileSpell) : nullptr;
    for (uint32 i = 0; i < count; ++i)
    {
        uint32 const landsInMs = warnMs + i * BONK_BARRAGE_STAGGER_MS;
        float x, y, z;
        if (i)
            AimAhead(owner, run, landsInMs, x, y, z);
        else
            PredictPlayer(owner, landsInMs, x, y, z);
        if (i)
        {
            float const angle = frand(0.0f, 2.0f * M_PI_F);
            float const distance = frand(size, BONK_BARRAGE_SPREAD);
            float const ax = x + distance * std::cos(angle), ay = y + distance * std::sin(angle);
            float const az = m_creature->GetMap()->GetHeight(ax, ay, z + 5.0f, true, 15.0f);
            if (az <= INVALID_HEIGHT)
                continue;
            x = ax;
            y = ay;
            z = az;
        }
        run->AddEnemyTelegraph(m_creature, BONK_TELEGRAPH_CIRCLE, x, y, z, 0.0f, size, landsInMs,
            [run, hit, x, y, z, size]() { run->Erupt(hit, x, y, z, size); });
        if (missileInfo)
        {
            uint32 const flight = std::min(GetBoltFlightMs(missileInfo, m_creature->GetDistance(x, y, z)), landsInMs);
            run->LaunchEnemyMissile(m_creature->GetObjectGuid(), ObjectGuid(), missileSpell, landsInMs - flight, flight, x, y, z);
        }
    }
}

void BonkMobAI::WindUp(int32 abilityIndex, float orientation, uint32 durationMs)
{
    m_areaWinding = true;
    m_areaWindId = ++m_windCount;
    m_areaAbility = abilityIndex;
    m_areaTimer = int32(durationMs);
    m_areaX = m_creature->GetPositionX();
    m_areaY = m_creature->GetPositionY();
    m_areaOrientation = orientation;
    m_leapLaunched = false;
    m_areaSelfTimed = false;
    HoldStill();
    m_creature->SetFacingTo(orientation);
    if (m_mob && abilityIndex >= 0 && abilityIndex < int32(m_mob->abilities.size()))
        ShowWindupLook(sSpellMgr.GetSpellEntry(m_mob->abilities[abilityIndex].spellId));
}

bool BonkMobAI::StartLeap(int32 abilityIndex, Player* owner, BonkRun* run, uint32 damage)
{
    if (m_creature->HasUnitState(UNIT_STATE_ROOT | UNIT_STATE_STUNNED | UNIT_STATE_CONFUSED))
        return false;
    float x, y, z;
    AimAhead(owner, run, GetWarnMs(run, BONK_LEAP_WINDUP_MS) + uint32(m_creature->GetDistance2d(owner) / BONK_LEAP_SPEED * IN_MILLISECONDS), x, y, z);
    if (!m_creature->IsWithinLOS(x, y, z + 2.0f))
        return false;

    BonkMobAbility const& ability = m_mob->abilities[abilityIndex];
    float const size = GetKindSize(BONK_SHAPE_LEAP, ability.size > 0.0f ? ability.size : BONK_LEAP_RADIUS);
    m_leapRadius = size;
    m_leapX = x;
    m_leapY = y;
    m_leapZ = z;
    m_leapTravelMs = std::max(BONK_LEAP_MIN_TRAVEL_MS, int32(m_creature->GetDistance2d(x, y) / BONK_LEAP_SPEED * IN_MILLISECONDS));
    uint32 const warnMs = GetWarnMs(run, BONK_LEAP_WINDUP_MS) + uint32(m_leapTravelMs);
    WindUp(abilityIndex, m_creature->GetAngle(x, y), warnMs);
    m_creature->HandleEmote(EMOTE_ONESHOT_BATTLEROAR);
    BonkEnemyHit const hit = MakeAbilityHit(run, ability, 0, damage, m_areaWindId);
    run->AddEnemyTelegraph(m_creature, BONK_TELEGRAPH_CIRCLE, x, y, z, 0.0f, size, warnMs,
        [run, hit, x, y, z, size]() { run->LandWarning(hit, BONK_TELEGRAPH_CIRCLE, x, y, z, 0.0f, size); }, m_areaWindId);
    return true;
}

void BonkMobAI::LaunchLeap()
{
    if (m_creature->HasUnitState(UNIT_STATE_ROOT | UNIT_STATE_STUNNED | UNIT_STATE_CONFUSED))
        return;
    m_leapLaunched = true;
    ClearWindupLook();
    float const distance = m_creature->GetDistance2d(m_leapX, m_leapY);
    float const speed = std::max(BONK_LEAP_SPEED, distance * IN_MILLISECONDS / float(std::max(1, m_leapTravelMs)));
    m_creature->GetMotionMaster()->MovePoint(0, m_leapX, m_leapY, m_leapZ, MOVE_RUN_MODE | MOVE_FORCE_DESTINATION, speed);
}

void BonkMobAI::StartLines(int32 abilityIndex, Player* owner, BonkRun* run, uint32 damage)
{
    BonkMobAbility const& ability = m_mob->abilities[abilityIndex];
    bool const spokes = ability.shape == BONK_SHAPE_SPOKES;
    uint32 const durationMs = GetWarnMs(run, BONK_LINE_WARN_MS) + GetBonkTelegraphLeadMs(BONK_TELEGRAPH_LINE);
    WindUp(abilityIndex, AimAngle(m_creature, owner, run, durationMs), durationMs);
    m_lineCount = spokes ? (ability.count ? ability.count : BONK_SPOKES_COUNT) + run->GetDifficultyStep() : std::max(1u, ability.count);
    m_lineSpread = spokes ? 2.0f * M_PI_F / float(m_lineCount) : BONK_SHOCKWAVE_SPREAD;
    m_lineLength = std::min(ability.size > 0.0f ? ability.size : BONK_LINE_MAX_LENGTH, BONK_LINE_MAX_LENGTH);

    float const x = m_areaX, y = m_areaY, z = m_creature->GetPositionZ(), length = m_lineLength;
    BonkEnemyHit const hit = MakeAbilityHit(run, ability, BONK_SPELL_CHARGE_HIT, damage, m_areaWindId);
    for (float const angle : GetLineAngles())
        run->AddEnemyTelegraph(m_creature, BONK_TELEGRAPH_LINE, x, y, z, angle, length, durationMs,
            [run, hit, x, y, z, angle, length]() { run->LandWarning(hit, BONK_TELEGRAPH_LINE, x, y, z, angle, length); }, m_areaWindId);
}

std::vector<float> BonkMobAI::GetLineAngles() const
{
    bool const spokes = m_mob && m_areaAbility >= 0 && m_mob->abilities[m_areaAbility].shape == BONK_SHAPE_SPOKES;
    float const first = spokes ? m_areaOrientation : m_areaOrientation - m_lineSpread * float(m_lineCount - 1) / 2.0f;
    std::vector<float> angles;
    for (uint32 i = 0; i < m_lineCount; ++i)
        angles.push_back(first + float(i) * m_lineSpread);
    return angles;
}

bool BonkMobAI::IsInLines(float x, float y) const
{
    for (float const angle : GetLineAngles())
        if (IsInBonkTelegraph(BONK_TELEGRAPH_LINE, m_areaX, m_areaY, angle, m_lineLength, x, y))
            return true;
    return false;
}

void BonkMobAI::StartPools(BonkMobAbility const& ability, Player* owner, BonkRun* run)
{
    float const size = ability.size > 0.0f ? ability.size : BONK_POOL_RADIUS;
    uint32 const count = std::max(1u, ability.count) + run->GetDifficultyStep();
    float const damage = GetMeleeHit() * (ability.damage > 0.0f ? ability.damage : BONK_POOL_DAMAGE);
    BonkEnemyHit const hit = MakeAbilityHit(run, ability, 0, uint32(std::max(1.0f, damage)));
    float heroX, heroY, heroZ;
    uint32 const warnMs = GetWarnMs(run, BONK_AREA_WARN_MS);
    AimAhead(owner, run, warnMs, heroX, heroY, heroZ);
    for (uint32 i = 0; i < count; ++i)
    {
        float x = heroX, y = heroY, z = heroZ;
        if (i)
        {
            float const angle = frand(0.0f, 2.0f * M_PI_F);
            float const distance = frand(size * 1.5f, size + BONK_POOL_SPREAD);
            x = heroX + distance * std::cos(angle);
            y = heroY + distance * std::sin(angle);
            z = m_creature->GetMap()->GetHeight(x, y, heroZ + 5.0f, true, 15.0f);
            if (z <= INVALID_HEIGHT)
                continue;
        }
        run->AddEnemyTelegraph(m_creature, BONK_TELEGRAPH_CIRCLE, x, y, z, 0.0f, size, warnMs,
            [run, hit, x, y, z, size]() { run->StartVoidZone(hit, x, y, z, size, BONK_POOL_DURATION_MS); });
    }
}

void BonkMobAI::HoldStill()
{
    m_creature->AttackStop();
    m_creature->StopMoving();
    m_creature->GetMotionMaster()->Clear(false);
    m_creature->GetMotionMaster()->MoveIdle();
}

void BonkMobAI::ShowWindupLook(SpellEntry const* spellInfo)
{
    uint32 const look = GetWindupLookSpell(spellInfo);
    if (!look || look == m_windupLook)
        return;
    m_windupLook = look;
    m_creature->SetUInt32Value(UNIT_CHANNEL_SPELL, look);
    m_creature->DirectSendPublicValueUpdate({ UNIT_CHANNEL_SPELL });
}

void BonkMobAI::ClearWindupLook()
{
    if (!m_windupLook)
        return;
    m_windupLook = 0;
    m_creature->CancelSpellChannelingAnimationInstantly();
}

void BonkMobAI::KeepHolding()
{
    if (m_creature->GetVictim() || m_creature->GetMotionMaster()->GetCurrentMovementGeneratorType() != IDLE_MOTION_TYPE)
        HoldStill();
}

void BonkMobAI::StartBreaths(int32 abilityIndex, Player* owner, BonkRun* run, uint32 damage)
{
    BonkMobAbility const& ability = m_mob->abilities[abilityIndex];
    uint32 const count = (ability.count ? ability.count : BONK_BREATH_COUNT) + run->GetDifficultyStep();
    float const reach = GetKindSize(ability.shape, std::max(1.0f, ability.size));
    uint32 const firstMs = GetConeWarnMs(run, owner, reach) + GetBonkTelegraphLeadMs(BONK_TELEGRAPH_CONE);
    float const size = GetConeSize(reach, run, owner, firstMs);
    WindUp(abilityIndex, AimAngle(m_creature, owner, run, firstMs), firstMs + (count - 1) * BONK_BREATH_STAGGER_MS);
    m_areaSelfTimed = true;
    float const x = m_areaX, y = m_areaY, z = m_creature->GetPositionZ();
    BonkEnemyHit hit = Unbound(MakeAbilityHit(run, ability, BONK_SPELL_CHARGE_HIT, damage));
    hit.facesShape = true;
    for (uint32 i = 0; i < count; ++i)
    {
        float const side = (i % 2 ? 1.0f : -1.0f) * float((i + 1) / 2);
        float const o = m_areaOrientation + side * M_PI_F / 3.0f;
        run->AddEnemyTelegraph(m_creature, BONK_TELEGRAPH_CONE, x, y, z, o, size, firstMs + i * BONK_BREATH_STAGGER_MS,
            [run, hit, x, y, z, o, size]() { run->LandWarning(hit, BONK_TELEGRAPH_CONE, x, y, z, o, size); }, m_areaWindId);
    }
}

void BonkMobAI::StartFrontAndBack(int32 abilityIndex, Player* owner, BonkRun* run, uint32 damage)
{
    BonkMobAbility const& ability = m_mob->abilities[abilityIndex];
    float const reach = GetKindSize(ability.shape, std::max(1.0f, ability.size));
    uint32 const warnMs = GetConeWarnMs(run, owner, reach) + GetBonkTelegraphLeadMs(BONK_TELEGRAPH_CONE);
    float const size = GetConeSize(reach, run, owner, warnMs);
    WindUp(abilityIndex, AimAngle(m_creature, owner, run, warnMs), warnMs);
    m_areaSelfTimed = true;
    float const x = m_areaX, y = m_areaY, z = m_creature->GetPositionZ();
    BonkEnemyHit const hit = Unbound(MakeAbilityHit(run, ability, BONK_SPELL_CHARGE_HIT, damage));
    for (float const o : { m_areaOrientation, m_areaOrientation + M_PI_F })
        run->AddEnemyTelegraph(m_creature, BONK_TELEGRAPH_CONE, x, y, z, o, size, warnMs,
            [run, hit, x, y, z, o, size]() { run->LandWarning(hit, BONK_TELEGRAPH_CONE, x, y, z, o, size); }, m_areaWindId);
}

void BonkMobAI::StartWalls(int32 abilityIndex, Player* owner, BonkRun* run, uint32 damage)
{
    BonkMobAbility const& ability = m_mob->abilities[abilityIndex];
    uint32 const count = (ability.count ? ability.count : BONK_WALL_COUNT) + run->GetDifficultyStep();
    uint32 const durationMs = GetWarnMs(run, BONK_LINE_WARN_MS) + GetBonkTelegraphLeadMs(BONK_TELEGRAPH_LINE);
    float const length = std::min(ability.size > 0.0f ? ability.size : BONK_LINE_MAX_LENGTH, BONK_LINE_MAX_LENGTH);
    WindUp(abilityIndex, AimAngle(m_creature, owner, run, durationMs), durationMs);
    m_areaSelfTimed = true;
    float const o = m_areaOrientation, z = m_creature->GetPositionZ();
    BonkEnemyHit const hit = Unbound(MakeAbilityHit(run, ability, BONK_SPELL_CHARGE_HIT, damage));
    for (uint32 i = 0; i < count; ++i)
    {
        float const offset = (float(i) - float(count - 1) / 2.0f) * BONK_WALL_SPACING;
        float const x = m_areaX - offset * std::sin(o), y = m_areaY + offset * std::cos(o);
        run->AddEnemyTelegraph(m_creature, BONK_TELEGRAPH_LINE, x, y, z, o, length, durationMs,
            [run, hit, x, y, z, o, length]() { run->LandWarning(hit, BONK_TELEGRAPH_LINE, x, y, z, o, length); }, m_areaWindId);
    }
}

void BonkMobAI::StartWreath(int32 abilityIndex, Player* owner, BonkRun* run, uint32 damage)
{
    BonkMobAbility const& ability = m_mob->abilities[abilityIndex];
    uint32 const count = (ability.count ? ability.count : BONK_WREATH_COUNT) + 2 * run->GetDifficultyStep();
    float const distance = ability.size > 0.0f ? ability.size : BONK_WREATH_DISTANCE;
    uint32 const warnMs = GetWarnMs(run, BONK_AREA_WARN_MS);
    WindUp(abilityIndex, m_creature->GetAngle(owner), warnMs);
    m_areaSelfTimed = true;
    BonkEnemyHit const hit = MakeAbilityHit(run, ability, 0, damage);
    float const turn = frand(0.0f, 2.0f * M_PI_F);
    for (uint32 i = 0; i < count; ++i)
    {
        float const angle = turn + 2.0f * M_PI_F * float(i) / float(count);
        float const x = m_areaX + distance * std::cos(angle), y = m_areaY + distance * std::sin(angle);
        float const z = m_creature->GetMap()->GetHeight(x, y, m_creature->GetPositionZ() + 5.0f, true, 15.0f);
        if (z <= INVALID_HEIGHT)
            continue;
        run->AddEnemyTelegraph(m_creature, BONK_TELEGRAPH_CIRCLE, x, y, z, 0.0f, BONK_WREATH_RADIUS, warnMs,
            [run, hit, x, y, z]() { run->Erupt(hit, x, y, z, BONK_WREATH_RADIUS); }, m_areaWindId);
    }
}

uint32 BonkMobAI::GetHeldWarnMs(BonkAbilityShape shape, BonkRun const* run, Player const* hero, float size) const
{
    if (GetHeldShape(shape) == BONK_TELEGRAPH_CONE)
        return GetConeWarnMs(run, hero, size);
    if (IsBossOrMini() && IsSignatureShape(shape))
        return GetWarnMs(run, BONK_SIGNATURE_WARN_MS);
    return GetWarnMs(run, BONK_AREA_WARN_MS);
}

void BonkMobAI::StartMeteors(int32 abilityIndex, Player* owner, BonkRun* run, uint32 damage)
{
    BonkMobAbility const& ability = m_mob->abilities[abilityIndex];
    bool const boss = m_kind == BONK_SPAWN_BOSS;
    uint32 const count = (ability.count ? ability.count : boss ? BONK_METEOR_COUNT : BONK_MINI_METEOR_COUNT) +
        BONK_METEORS_PER_STEP * run->GetDifficultyStep();
    float const radius = ability.size > 0.0f ? ability.size : boss ? BONK_METEOR_RADIUS : BONK_MINI_METEOR_RADIUS;
    float const spread = boss ? BONK_METEOR_SPREAD : BONK_MINI_METEOR_SPREAD;
    uint32 const warnMs = GetWarnMs(run, BONK_AREA_WARN_MS);
    WindUp(abilityIndex, m_creature->GetAngle(owner), BONK_METEOR_CAST_MS);
    m_areaSelfTimed = true;
    PlayCastKit(ability, owner);
    run->HoldBigMoves(m_creature->GetObjectGuid(), warnMs + BONK_METEOR_SPAN_MS);

    SpellEntry const* missileInfo = ability.spellId && sBonkMgr.GetBoltLook(ability.spellId) ? sSpellMgr.GetSpellEntry(ability.spellId) : nullptr;
    BonkEnemyHit const hit = MakeAbilityHit(run, ability, 0, damage);
    for (uint32 i = 0; i < count; ++i)
    {
        float const angle = frand(0.0f, 2.0f * M_PI_F);
        float const distance = spread * std::sqrt(frand(BONK_METEOR_NEAREST, 1.0f));
        float const x = m_areaX + distance * std::cos(angle), y = m_areaY + distance * std::sin(angle);
        float const z = m_creature->GetMap()->GetHeight(x, y, m_creature->GetPositionZ() + 5.0f, true, 15.0f);
        if (z <= INVALID_HEIGHT)
            continue;
        uint32 const landsInMs = warnMs + BONK_METEOR_SPAN_MS * i / count;
        run->AddEnemyTelegraph(m_creature, BONK_TELEGRAPH_CIRCLE, x, y, z, 0.0f, radius, landsInMs,
            [run, hit, x, y, z, radius]() { run->Erupt(hit, x, y, z, radius); });
        if (missileInfo)
        {
            uint32 const flight = std::min(GetBoltFlightMs(missileInfo, m_creature->GetDistance(x, y, z)), landsInMs);
            run->LaunchEnemyMissile(m_creature->GetObjectGuid(), ObjectGuid(), ability.spellId, landsInMs - flight, flight, x, y, z);
        }
    }
    if (!m_meteorsAnnounced)
    {
        m_meteorsAnnounced = true;
        owner->GetBonkPlayer()->Notify(BONK_STRING_ENEMY_METEOR_SHOWER, { owner->GetBonkPlayer()->GetLocalName(m_creature) });
    }
}

void BonkMobAI::StartDonut(int32 abilityIndex, Player* owner, BonkRun* run, uint32 damage, float size)
{
    BonkMobAbility const& ability = m_mob->abilities[abilityIndex];
    uint32 const warnMs = GetWarnMs(run, BONK_DONUT_WARN_MS);
    WindUp(abilityIndex, m_creature->GetAngle(owner), warnMs);
    m_areaSelfTimed = true;
    run->HoldBigMoves(m_creature->GetObjectGuid(), warnMs);
    float const x = m_areaX, y = m_areaY, z = m_creature->GetPositionZ();
    uint32 const impact = GetImpactKit(ability);
    BonkEnemyHit const hit = Unbound(MakeAbilityHit(run, ability, BONK_SPELL_CHARGE_HIT, damage));
    run->AddEnemyTelegraph(m_creature, BONK_TELEGRAPH_RING, x, y, z, 0.0f, size, warnMs,
        [run, hit, impact, x, y, z, size]()
        {
            run->ShowRingImpact(impact, x, y, z, GetBonkRingInnerRadius(size), size);
            run->LandWarning(hit, BONK_TELEGRAPH_RING, x, y, z, 0.0f, size);
        }, m_areaWindId);
    if (!m_donutAnnounced)
    {
        m_donutAnnounced = true;
        owner->GetBonkPlayer()->Notify(BONK_STRING_ENEMY_BURNS_OUTER_RING, { owner->GetBonkPlayer()->GetLocalName(m_creature) });
    }
}

void BonkMobAI::StartSweep(int32 abilityIndex, Player* owner, BonkRun* run, uint32 damage)
{
    BonkMobAbility const& ability = m_mob->abilities[abilityIndex];
    uint32 const firstMs = GetWarnMs(run, BONK_LINE_WARN_MS) + GetBonkTelegraphLeadMs(BONK_TELEGRAPH_LINE);
    WindUp(abilityIndex, AimAngle(m_creature, owner, run, firstMs), firstMs + BONK_SWEEP_STEP_MS);
    m_areaSelfTimed = true;
    uint32 const count = (ability.count ? ability.count : BONK_SPOKES_COUNT) + run->GetDifficultyStep();
    float const spread = 2.0f * M_PI_F / float(count);
    float const length = std::min(ability.size > 0.0f ? ability.size : BONK_LINE_MAX_LENGTH, BONK_LINE_MAX_LENGTH);
    float const x = m_areaX, y = m_areaY, z = m_creature->GetPositionZ();
    BonkEnemyHit const hit = Unbound(MakeAbilityHit(run, ability, BONK_SPELL_CHARGE_HIT, damage));
    for (uint32 wave = 0; wave < 2; ++wave)
        for (uint32 i = 0; i < count; ++i)
        {
            float const angle = m_areaOrientation + spread * (float(i) + 0.5f * float(wave));
            run->AddEnemyTelegraph(m_creature, BONK_TELEGRAPH_LINE, x, y, z, angle, length, firstMs + wave * BONK_SWEEP_STEP_MS,
                [run, hit, x, y, z, angle, length]() { run->LandWarning(hit, BONK_TELEGRAPH_LINE, x, y, z, angle, length); }, m_areaWindId);
        }
}

bool BonkMobAI::UpdateArea(uint32 diff, Player* owner)
{
    if (!m_areaWinding)
        return false;
    m_areaTimer -= int32(diff);
    if (!m_leapLaunched)
        KeepHolding();
    if (m_areaSelfTimed && m_areaTimer <= 0)
    {
        ResolveArea(owner);
        return true;
    }
    if (!m_leapLaunched && m_mob && m_areaAbility >= 0 && m_mob->abilities[m_areaAbility].shape == BONK_SHAPE_LEAP &&
        m_areaTimer <= m_leapTravelMs + BONK_LEAP_LAUNCH_EARLY_MS)
        LaunchLeap();
    if (m_areaTimer > -int32(BONK_WINDUP_LOST_MS))
        return true;
    ReportTest("gave up a wind-up that never landed.");
    AbandonWindups();
    ResumeChase(owner);
    return true;
}

bool BonkMobAI::IsWindingUp(uint32 windId) const
{
    return (m_areaWinding && m_areaWindId == windId) || (m_chargeState == CHARGE_WINDUP && m_chargeWindId == windId);
}

void BonkMobAI::LandWindup(uint32 windId)
{
    Player* owner = GetOwner();
    if (!owner || m_frozen || !IsWindingUp(windId))
    {
        if (windId != m_lastLandedWindId)
            ReportTest("lost a wind-up before it landed.");
        return;
    }
    m_lastLandedWindId = windId;
    if (m_areaWinding && m_areaWindId == windId)
        ResolveArea(owner);
    else
        Dash(owner);
}

void BonkMobAI::FlyIn(Player* owner)
{
    m_flyingIn = true;
    m_creature->GetMotionMaster()->MovePoint(0, owner->GetPositionX(), owner->GetPositionY(), owner->GetPositionZ() + 1.0f,
        MOVE_FLY_MODE | MOVE_FORCE_DESTINATION);
}

void BonkMobAI::ResumeChase(Player* owner)
{
    AttackStart(owner);
    if (m_creature->GetVictim() == owner && m_creature->GetMotionMaster()->GetCurrentMovementGeneratorType() != CHASE_MOTION_TYPE)
        m_creature->GetMotionMaster()->MoveChase(owner, m_mob && m_mob->role == BONK_ROLE_RANGED ? m_mob->range : 0.0f);
}

void BonkMobAI::ResolveArea(Player* owner)
{
    m_areaWinding = false;
    ClearWindupLook();

    BonkMobAbility const* ability = m_mob && m_areaAbility >= 0 ? &m_mob->abilities[m_areaAbility] : nullptr;
    if (m_areaSelfTimed)
    {
        m_areaSelfTimed = false;
        m_creature->HandleEmote(EMOTE_ONESHOT_ATTACK2HTIGHT);
        ResumeChase(owner);
        return;
    }
    bool const leap = ability && ability->shape == BONK_SHAPE_LEAP;
    float const dx = m_creature->GetPositionX() - m_areaX;
    float const dy = m_creature->GetPositionY() - m_areaY;
    bool const fizzles = (leap ? !m_leapLaunched : dx * dx + dy * dy > BONK_AREA_DRIFT * BONK_AREA_DRIFT) ||
        m_creature->HasUnitState(UNIT_STATE_STUNNED | UNIT_STATE_CONFUSED | UNIT_STATE_FLEEING);
    if (fizzles)
    {
        char reason[96];
        snprintf(reason, sizeof(reason), "fizzled: moved %.1f yd during the wind-up%s.", std::sqrt(dx * dx + dy * dy),
            m_creature->HasUnitState(UNIT_STATE_STUNNED | UNIT_STATE_CONFUSED | UNIT_STATE_FLEEING) ? ", while held" : "");
        ReportTest(reason);
    }
    if (!fizzles && ability)
    {
        float x, y, z;
        PredictPlayer(owner, 0, x, y, z);
        bool const reachable = owner->IsAlive() && !owner->GetBonkPlayer()->IsDashInvulnerable();
        BonkRun* run = owner->GetBonkPlayer()->GetRun();
        uint32 const castKit = GetCastKit(*ability);
        if (castKit && ability->shape != BONK_SHAPE_SPELL)
            m_creature->SendPlaySpellVisualKit(castKit);
        if (ability->shape == BONK_SHAPE_CONE || ability->shape == BONK_SHAPE_NOVA)
        {
            BonkTelegraphShape const shape = GetHeldShape(ability->shape);
            m_creature->HandleEmote(shape == BONK_TELEGRAPH_CONE ? EMOTE_ONESHOT_ATTACK1H : EMOTE_ONESHOT_BATTLEROAR);
            uint32 const areaKit = GetImpactKit(*ability) ? GetImpactKit(*ability) : castKit;
            if (run && shape == BONK_TELEGRAPH_CIRCLE && areaKit)
                run->ShowAreaImpact(areaKit, m_areaX, m_areaY, m_creature->GetPositionZ(), m_areaSize);
            if (reachable && IsInBonkTelegraph(shape, m_areaX, m_areaY, m_areaOrientation, m_areaSize, x, y))
                StrikeOwner(owner, *ability, x, y, z);
        }
        else if (ability->shape == BONK_SHAPE_SHOCKWAVE || ability->shape == BONK_SHAPE_SPOKES)
        {
            m_creature->HandleEmote(EMOTE_ONESHOT_ATTACK2HTIGHT);
            uint32 const impact = GetImpactKit(*ability);
            if (run && impact)
                for (float const angle : GetLineAngles())
                    run->ShowLineImpacts(impact, m_areaX, m_areaY, m_creature->GetPositionZ(), angle, m_lineLength);
            if (reachable && IsInLines(x, y))
            {
                StrikeOwner(owner, *ability, x, y, z);
                if (owner->IsAlive())
                    KnockBackHero(owner, std::atan2(y - m_areaY, x - m_areaX));
            }
        }
        else if (leap)
        {
            m_creature->HandleEmote(EMOTE_ONESHOT_ATTACK2HTIGHT);
            if (run)
                run->Erupt(MakeAbilityHit(run, *ability, 0, GetShapeDamage(*ability)), m_leapX, m_leapY, m_leapZ, m_leapRadius);
        }
        else if (reachable && IsInBonkTelegraph(BONK_TELEGRAPH_CIRCLE, m_areaX, m_areaY, 0.0f, m_areaSize, x, y))
            Cast(*ability, owner, true);
        else
        {
            m_creature->HandleEmote(EMOTE_ONESHOT_BATTLEROAR);
            m_creature->SendPlaySpellVisualKit(castKit ? castKit : BONK_KIT_DUST_NOVA);
        }
    }

    if (leap && m_leapLaunched)
    {
        float const left = m_creature->GetDistance2d(m_leapX, m_leapY);
        m_landingTimer = int32(left / BONK_LEAP_SPEED * IN_MILLISECONDS) + BONK_LEAP_SETTLE_MS;
        return;
    }
    ResumeChase(owner);
}

bool BonkMobAI::UpdateCharge(uint32 diff, Player* owner)
{
    bool const charger = m_archetype == BONK_ARCHETYPE_CHARGER && m_kind == BONK_SPAWN_NORMAL;
    if (!charger && m_chargeState == CHARGE_NONE)
        return false;

    m_chargeTimer -= int32(diff);
    switch (m_chargeState)
    {
        case CHARGE_WINDUP:
            KeepHolding();
            if (m_chargeTimer <= -int32(BONK_WINDUP_LOST_MS))
            {
                if (BonkRun* run = owner->GetBonkPlayer()->GetRun())
                    run->CancelEnemyWindup(m_creature, m_chargeWindId);
                EndCharge(owner);
            }
            return true;
        case CHARGE_DASH:
            UpdateDash(owner);
            if (m_chargeTimer <= 0)
                EndCharge(owner);
            return m_chargeState != CHARGE_NONE;
        default:
            break;
    }

    if (!charger || m_chargeTimer > 0)
        return false;
    float x, y, z;
    PredictPlayer(owner, GetChargeWindupMs(), x, y, z);
    float const aim = m_creature->GetDistance2d(x, y);
    if (aim < BONK_CHARGE_MIN_RANGE || aim > BONK_CHARGE_AIM_RANGE || m_creature->GetDistance(owner) > BONK_CHARGE_MAX_RANGE ||
        !m_creature->IsWithinLOSInMap(owner) || !m_creature->IsWithinLOS(x, y, z + 2.0f) ||
        m_creature->HasUnitState(UNIT_STATE_ROOT | UNIT_STATE_STUNNED | UNIT_STATE_CONFUSED))
    {
        m_chargeTimer = BONK_CHARGE_RETRY_MS;
        return false;
    }
    StartCharge(owner, BONK_CHARGE_DAMAGE);
    return m_chargeState != CHARGE_NONE;
}

void BonkMobAI::StartCharge(Player* owner, float damage)
{
    BonkRun* run = owner->GetBonkPlayer()->GetRun();
    if (!run)
        return;

    float x, y, z;
    PredictPlayer(owner, GetChargeWindupMs(), x, y, z);
    m_chargeX = m_creature->GetPositionX();
    m_chargeY = m_creature->GetPositionY();
    m_chargeZ = m_creature->GetPositionZ();
    m_chargeAngle = m_creature->GetAngle(x, y);
    float const length = std::min(BONK_CHARGE_MAX_LENGTH, m_creature->GetDistance2d(x, y) + BONK_CHARGE_OVERSHOOT);
    m_dashX = m_chargeX + length * std::cos(m_chargeAngle);
    m_dashY = m_chargeY + length * std::sin(m_chargeAngle);
    m_dashZ = m_chargeZ;
    m_creature->GetMap()->GetWalkHitPosition(nullptr, m_chargeX, m_chargeY, m_chargeZ, m_dashX, m_dashY, m_dashZ);
    m_chargeLength = m_creature->GetDistance2d(m_dashX, m_dashY);
    if (m_chargeLength < BONK_CHARGE_MIN_RANGE || m_chargeLength + 1.0f < std::min(length - BONK_CHARGE_OVERSHOOT, BONK_CHARGE_MAX_LENGTH))
    {
        m_chargeTimer = BONK_CHARGE_RETRY_MS;
        ReportTest("found no clear path to charge.");
        return;
    }

    m_chargeState = CHARGE_WINDUP;
    m_chargeTimer = GetChargeWindupMs();
    m_chargeDamage = damage;
    HoldStill();
    m_creature->SetFacingTo(m_chargeAngle);
    WarnCharge(run, GetChargeWindupMs());
}

void BonkMobAI::WarnCharge(BonkRun* run, uint32 windupMs)
{
    m_chargeWindId = ++m_windCount;
    float const x = m_chargeX, y = m_chargeY, z = m_chargeZ, o = m_chargeAngle, length = m_chargeLength;
    BonkEnemyHit const hit = MakeHit(run, BONK_SPELL_CHARGE_HIT, uint32(std::max(1.0f, GetMeleeHit() * m_chargeDamage)), m_chargeWindId);
    run->AddEnemyTelegraph(m_creature, BONK_TELEGRAPH_LINE, x, y, z, o, length, windupMs,
        [run, hit, x, y, z, o, length]() { run->LandWarning(hit, BONK_TELEGRAPH_LINE, x, y, z, o, length); }, m_chargeWindId);
}

void BonkMobAI::KnockBackHero(Player* hero, float angle)
{
    hero->KnockBack(angle, BONK_CHARGE_KNOCKBACK_SPEED, BONK_CHARGE_KNOCKBACK_LIFT);
}

void BonkMobAI::Dash(Player* owner)
{
    m_chargeState = CHARGE_DASH;
    m_chargeTimer = int32(m_chargeLength / BONK_CHARGE_SPEED * IN_MILLISECONDS) + 300;
    m_dashFromX = m_creature->GetPositionX();
    m_dashFromY = m_creature->GetPositionY();
    m_dashHit = false;
    m_creature->SendPlaySpellVisualKit(BONK_KIT_CHARGE_TRAIL);
    m_creature->GetMotionMaster()->MovePoint(0, m_dashX, m_dashY, m_dashZ, MOVE_RUN_MODE | MOVE_FORCE_DESTINATION, BONK_CHARGE_SPEED);
}

void BonkMobAI::UpdateDash(Player* owner)
{
    float const toX = m_creature->GetPositionX(), toY = m_creature->GetPositionY();
    if (!m_dashHit && owner->IsAlive() && !owner->GetBonkPlayer()->IsDashInvulnerable())
    {
        float x, y, z;
        PredictPlayer(owner, 0, x, y, z);
        float const segX = toX - m_dashFromX, segY = toY - m_dashFromY;
        float const segLength2 = segX * segX + segY * segY;
        float const along = segLength2 > 0.0f ? std::max(0.0f, std::min(1.0f, ((x - m_dashFromX) * segX + (y - m_dashFromY) * segY) / segLength2)) : 0.0f;
        float const dx = x - (m_dashFromX + along * segX), dy = y - (m_dashFromY + along * segY);
        if (dx * dx + dy * dy <= BONK_CHARGE_CONTACT * BONK_CHARGE_CONTACT && std::fabs(z - m_creature->GetPositionZ()) < 3.0f)
        {
            m_dashHit = true;
            int32 const damage = std::max(1, int32(GetMeleeHit() * m_chargeDamage));
            m_creature->CastCustomSpell(owner, BONK_SPELL_CHARGE_HIT, damage, {}, {}, true);
            if (owner->IsAlive())
                KnockBackHero(owner, m_chargeAngle);
        }
    }
    m_dashFromX = toX;
    m_dashFromY = toY;
}

void BonkMobAI::EndCharge(Player* owner)
{
    m_chargeState = CHARGE_NONE;
    if (m_stampede)
    {
        m_creature->DespawnOrUnsummon(1);
        return;
    }
    if (m_chargesLeft)
    {
        --m_chargesLeft;
        StartCharge(owner, m_chargeDamage);
        if (m_chargeState != CHARGE_NONE)
            return;
        m_chargesLeft = 0;
    }
    BonkRun* run = owner->GetBonkPlayer()->GetRun();
    m_chargeTimer = run && run->GetTier().chargeIntervalMs ? int32(run->GetTier().chargeIntervalMs) : BONK_CHARGE_INTERVAL;
    AttackStart(owner);
    if (m_creature->GetVictim() == owner && m_creature->GetMotionMaster()->GetCurrentMovementGeneratorType() != CHASE_MOTION_TYPE)
        m_creature->GetMotionMaster()->MoveChase(owner, m_mob && m_mob->role == BONK_ROLE_RANGED ? m_mob->range : 0.0f);
}

void BonkMobAI::DamageDeal(Unit* victim, uint32& damage)
{
    if (!damage || victim == m_creature)
        return;

    if (victim->GetTypeId() == TYPEID_PLAYER)
        if (BonkRun* run = static_cast<Player*>(victim)->GetBonkPlayer()->GetRun())
        {
            if (static_cast<Player*>(victim)->GetBonkPlayer()->IsDashInvulnerable())
            {
                damage = 0;
                return;
            }
            float const multiplier = GetHitScale(run);
            run->OnHeroStruck(m_creature);
            damage = run->CapEnemyHit(std::max(1u, uint32(damage * multiplier * run->GetChampionDamageTaken(m_kind))), m_kind, m_archetype);
            if (HasAffix(AFFIX_NECROTIC))
                run->AddNecroticStack();
            damage = run->MitigateDamage(damage);
            run->OnHeroHitBy(m_creature, damage);
            if (damage)
                OnHitHero(run);
        }

    if (HasAffix(AFFIX_VAMPIRIC))
        m_creature->ModifyHealth(int32(damage * BONK_VAMPIRIC_HEAL));
}

void BonkMobAI::DamageTaken(Unit* attacker, uint32& damage)
{
    if (m_fleeing && m_blinks && damage && damage < m_creature->GetHealth() && m_blinkTimer <= 0)
        m_blinkPending = true;

    if (!damage || !attacker || attacker->GetTypeId() != TYPEID_PLAYER)
        return;

    if (BonkRun* run = static_cast<Player*>(attacker)->GetBonkPlayer()->GetRun())
    {
        run->ModifyHeroHit(m_creature, damage);
        run->OnWeaponDamage(std::min(damage, m_creature->GetHealth()));
    }
}

void BonkMobAI::UpdatePhases(uint32 diff, Player* owner)
{
    if (m_kind != BONK_SPAWN_BOSS && m_kind != BONK_SPAWN_MINIBOSS)
        return;
    BonkRun* run = owner->GetBonkPlayer()->GetRun();
    if (!run)
        return;

    bool const boss = m_kind == BONK_SPAWN_BOSS;
    uint8 const phases = boss ? 2 : 1;
    uint32 const step = run->GetDifficultyStep();
    BonkPlayer* bonk = owner->GetBonkPlayer();
    std::string const name = bonk->GetLocalName(m_creature);
    if (m_phase < phases && m_creature->GetHealthPercent() < (boss ? BONK_PHASE_BOSS[m_phase] : BONK_PHASE_MINIBOSS))
    {
        ++m_phase;
        run->SpawnPhaseAdds(m_creature, boss ? BONK_PHASE_ADDS + 2 * step : BONK_PHASE_MINI_ADDS + step, boss ? step : 0);
        bonk->Notify(BONK_STRING_ENEMY_CALLS_FOR_AID, { name });
        if (boss)
            RaiseWards(run, step);

        if (boss && m_phase == 1 && step >= 2)
        {
            int32 const absorb = std::max(1, int32(m_creature->GetMaxHealth() * BONK_PHASE_SHIELD));
            m_creature->CastCustomSpell(m_creature, BONK_SPELL_SHIELD, absorb, {}, {}, true);
            bonk->Notify(BONK_STRING_ENEMY_RAISES_SHIELD, { name });
        }

        if (boss && m_phase == phases)
        {
            m_phaseEnraged = true;
            m_creature->AddAura(BONK_SPELL_RAGING);
            bonk->Notify(BONK_STRING_ENEMY_ENRAGED, { name });
            if (step >= 1)
            {
                m_voidZones = true;
                m_voidTimer = BONK_VOID_FIRST_MS;
            }
        }
    }

    if (!m_voidZones)
        return;
    m_voidTimer -= int32(diff);
    if (m_voidTimer > 0 || run->AreBigMovesHeld() || !m_creature->IsWithinDistInMap(owner, BONK_VOID_RANGE))
        return;
    m_voidTimer = BONK_VOID_INTERVAL;
    float const x = owner->GetPositionX(), y = owner->GetPositionY(), z = owner->GetPositionZ();
    BonkEnemyHit const hit = MakeHit(run, 0, uint32(std::max(1.0f, GetMeleeHit() * BONK_VOID_DAMAGE)));
    run->AddEnemyTelegraph(m_creature, BONK_TELEGRAPH_CIRCLE, x, y, z, 0.0f, BONK_VOID_RADIUS, BONK_VOID_WARN_MS,
        [run, hit, x, y, z]() { run->StartVoidZone(hit, x, y, z, BONK_VOID_RADIUS, BONK_VOID_DURATION_MS); });
}

uint32 BonkMobAI::GetWarnMs(BonkRun const* run, uint32 baseMs) const
{
    if (!run || !IsBossOrMini() || run->GetDifficultyStep() < 2)
        return baseMs;
    return uint32(baseMs * std::max(0.1f, Tune(TUNE_WARN_MYTHIC)));
}

uint32 BonkMobAI::GetMoveGapMs(BonkRun const* run) const
{
    uint32 const step = run ? run->GetDifficultyStep() : 0;
    if (step >= 2)
        return TuneMs(TUNE_GAP_MYTHIC);
    if (step == 1)
        return TuneMs(TUNE_GAP_HEROIC);
    return BONK_ABILITY_GAP_MS;
}

void BonkMobAI::OnHitHero(BonkRun* run)
{
    if (m_kind != BONK_SPAWN_BOSS || run->GetDifficultyStep() < 2)
        return;
    run->AddBossWound(uint32(std::max(0.0f, Tune(TUNE_WOUND_MAX))), Tune(TUNE_WOUND_CUT), TuneMs(TUNE_WOUND_SECONDS));
}

void BonkMobAI::UpdateBossPressure(uint32 diff, Player* owner, BonkRun* run)
{
    if (m_kind != BONK_SPAWN_BOSS || !run->GetDifficultyStep())
        return;
    bool const held = run->AreBigMovesHeld();
    if (IsDancing() || !held)
        UpdateLanes(diff, owner, run);
    if (!IsDancing() && !held)
    {
        UpdateHeroMarks(diff, owner, run);
        UpdateFarBlast(diff, owner, run);
    }
    if (run->GetDifficultyStep() < 2)
        return;
    UpdateLeash(diff, owner);
    if (!held || m_bossBlinkCharging)
        UpdateBossBlink(diff, owner, run);
}

void BonkMobAI::SetWard(ObjectGuid target, float healPercent)
{
    m_wardTarget = target;
    m_wardHeal = healPercent;
    m_wardTimer = int32(IN_MILLISECONDS);
    SetStationary();
}

void BonkMobAI::UpdateWard(uint32 diff)
{
    Creature* target = m_creature->GetMap()->GetCreature(m_wardTarget);
    if (!target || !target->IsAlive())
    {
        m_creature->DespawnOrUnsummon();
        return;
    }

    bool const inReach = m_creature->IsWithinDistInMap(target, BONK_WARD_REACH);
    if (inReach != m_wardBeaming)
    {
        m_wardBeaming = inReach;
        if (inReach)
        {
            m_creature->SetChannelObjectGuid(m_wardTarget);
            m_creature->SetUInt32Value(UNIT_CHANNEL_SPELL, BONK_SPELL_WARD_BEAM);
        }
        else
            m_creature->CancelSpellChannelingAnimationInstantly();
    }

    m_wardTimer -= int32(diff);
    if (m_wardTimer > 0)
        return;
    m_wardTimer = int32(IN_MILLISECONDS);
    if (inReach && target->GetHealth() < target->GetMaxHealth())
        target->ModifyHealth(int32(std::max(1.0f, target->GetMaxHealth() * m_wardHeal / 100.0f)));
}

void BonkMobAI::RaiseWards(BonkRun* run, uint32 step)
{
    if (!step)
        return;
    uint32 const count = uint32(std::max(0.0f, Tune(step >= 2 ? TUNE_WARDS_MYTHIC : TUNE_WARDS_HEROIC)));
    if (!count)
        return;
    run->SpawnWards(m_creature, count, Tune(TUNE_WARD_HEALTH) / 100.0f, Tune(TUNE_WARD_HEAL));
    if (!m_wardsAnnounced)
    {
        m_wardsAnnounced = true;
        if (Player* owner = GetOwner())
            owner->GetBonkPlayer()->Notify(BONK_STRING_ENEMY_RAISES_HEALING_WARDS, { owner->GetBonkPlayer()->GetLocalName(m_creature) });
    }
}

void BonkMobAI::UpdateLanes(uint32 diff, Player* owner, BonkRun* run)
{
    uint32 const intervalMs = TuneMs(run->GetDifficultyStep() >= 2 ? TUNE_LANES_MYTHIC : TUNE_LANES_HEROIC);
    if (!intervalMs || !m_phase)
        return;
    if (m_laneTimer < 0)
        m_laneTimer = BONK_LANE_FIRST_MS;
    m_laneTimer -= int32(diff);
    if (m_laneTimer > 0)
        return;

    if (!IsDancing())
    {
        if (!m_creature->IsWithinDistInMap(owner, BONK_MARK_RANGE))
        {
            m_laneTimer = BONK_BLINK_RETRY_MS;
            return;
        }
        StartLanes(owner);
    }
    EruptLaneWave(run);
    uint32 const waves = uint32(std::max(1.0f, Tune(TUNE_LANE_WAVES)));
    if (++m_laneWave > waves)
    {
        m_laneWave = 0;
        m_laneTimer = int32(intervalMs);
        return;
    }
    m_laneTimer = int32(std::max(250u, TuneMs(TUNE_LANE_GAP)));
}

void BonkMobAI::StartLanes(Player* owner)
{
    owner->GetPosition(m_laneX, m_laneY, m_laneZ);
    m_laneAngle = m_creature->GetAngle(owner);
    m_laneSide = urand(0, 1) ? 0 : BONK_LANE_COUNT - 1;
    m_laneWave = 1;
    if (BonkRun* run = owner->GetBonkPlayer()->GetRun())
        run->HoldBigMoves(m_creature->GetObjectGuid(),
            uint32(std::max(1.0f, Tune(TUNE_LANE_WAVES)) * TuneMs(TUNE_LANE_GAP)) + TuneMs(TUNE_LANE_WARN));
    if (!m_lanesAnnounced)
    {
        m_lanesAnnounced = true;
        owner->GetBonkPlayer()->Notify(BONK_STRING_ENEMY_GROUND_ERUPTS, { owner->GetBonkPlayer()->GetLocalName(m_creature) });
    }
}

void BonkMobAI::EruptLaneWave(BonkRun* run)
{
    uint32 const otherSide = BONK_LANE_COUNT - 1 - m_laneSide;
    uint32 const safe = m_laneWave % 2 == 0 ? BONK_LANE_COUNT / 2 : ((m_laneWave - 1) / 2 % 2 == 0 ? m_laneSide : otherSide);

    float const width = std::max(3.0f, Tune(TUNE_LANE_WIDTH));
    float const radius = width * BONK_LANE_OVERLAP;
    float const alongX = std::cos(m_laneAngle), alongY = std::sin(m_laneAngle);
    float const acrossX = -alongY, acrossY = alongX;
    uint32 const warnMs = std::max(250u, TuneMs(TUNE_LANE_WARN));
    BonkEnemyHit const hit = MakeHit(run, 0, uint32(std::max(1.0f, GetMeleeHit() * Tune(TUNE_LANE_DAMAGE))));
    Map* map = m_creature->GetMap();
    for (uint32 lane = 0; lane < BONK_LANE_COUNT; ++lane)
    {
        if (lane == safe)
            continue;
        float const across = (float(lane) - float(BONK_LANE_COUNT - 1) / 2.0f) * width;
        for (uint32 i = 0; i < BONK_LANE_CIRCLES; ++i)
        {
            float const along = (float(i) - float(BONK_LANE_CIRCLES - 1) / 2.0f) * width;
            float const x = m_laneX + along * alongX + across * acrossX;
            float const y = m_laneY + along * alongY + across * acrossY;
            float const z = map->GetHeight(x, y, m_laneZ + 5.0f, true, 15.0f);
            if (z <= INVALID_HEIGHT)
                continue;
            run->AddEnemyTelegraph(m_creature, BONK_TELEGRAPH_CIRCLE, x, y, z, 0.0f, radius, warnMs,
                [run, hit, x, y, z, radius]() { run->Erupt(hit, x, y, z, radius); });
        }
    }
}

void BonkMobAI::UpdateBossBlink(uint32 diff, Player* owner, BonkRun* run)
{
    if (m_bossBlinkCharging)
    {
        FinishBossBlink(owner, run);
        return;
    }
    uint32 const delayMs = TuneMs(TUNE_BLINK_DELAY);
    float const range = Tune(TUNE_FAR_RANGE);
    if (!delayMs || range <= 0.0f || m_creature->IsWithinDistInMap(owner, range))
    {
        m_bossBlinkFarMs = 0;
        return;
    }
    m_bossBlinkFarMs += diff;
    if (m_bossBlinkFarMs < delayMs || IsBusyWindingUp() || IsDancing() || m_chargeState != CHARGE_NONE || m_landingTimer > 0 ||
        m_creature->HasUnitState(UNIT_STATE_ROOT | UNIT_STATE_STUNNED | UNIT_STATE_CONFUSED))
        return;
    StartBossBlink(owner);
}

void BonkMobAI::StartBossBlink(Player* owner)
{
    m_bossBlinkCharging = true;
    m_creature->SetFacingToObject(owner);
    m_creature->SendPlaySpellVisualKit(BONK_KIT_BLINK_LEAVE);
    Hold(BONK_BLINK_WINDUP_MS);
    owner->GetBonkPlayer()->Notify(BONK_STRING_ENEMY_BLINKS_TO_YOU, { owner->GetBonkPlayer()->GetLocalName(m_creature) });
}

void BonkMobAI::FinishBossBlink(Player* owner, BonkRun* run)
{
    m_bossBlinkCharging = false;
    if (!BlinkToHero(owner, run))
    {
        m_bossBlinkFarMs = TuneMs(TUNE_BLINK_DELAY) - BONK_BLINK_RETRY_MS;
        return;
    }
    m_bossBlinkFarMs = 0;
    m_farMs = 0;
}

bool BonkMobAI::BlinkToHero(Player* owner, BonkRun* run)
{
    float const angle = owner->GetAngle(m_creature);
    float const x = owner->GetPositionX() + BONK_BLINK_LANDING * std::cos(angle);
    float const y = owner->GetPositionY() + BONK_BLINK_LANDING * std::sin(angle);
    float const z = m_creature->GetMap()->GetHeight(x, y, owner->GetPositionZ() + 5.0f, true, 15.0f);
    if (z <= INVALID_HEIGHT || !owner->IsWithinLOS(x, y, z + 2.0f))
        return false;

    uint32 const warnMs = std::max(250u, TuneMs(TUNE_BLINK_WARN));
    float const radius = std::max(1.0f, Tune(TUNE_BLINK_RADIUS));
    if (!run->ShowKitOnStandIn(BONK_KIT_BLINK_ARRIVE, x, y, z, BONK_BLINK_KIT_HOLD_MS))
        m_creature->SendPlaySpellVisualKit(BONK_KIT_BLINK_ARRIVE);
    m_creature->NearTeleportTo(x, y, z, m_creature->GetAngle(owner));
    Hold(warnMs);
    BonkEnemyHit const hit = MakeHit(run, 0, uint32(std::max(1.0f, GetMeleeHit() * Tune(TUNE_BLINK_DAMAGE))));
    run->AddEnemyTelegraph(m_creature, BONK_TELEGRAPH_CIRCLE, x, y, z, 0.0f, radius, warnMs,
        [run, hit, x, y, z, radius]() { run->Erupt(hit, x, y, z, radius); });
    return true;
}

void BonkMobAI::UpdateHeroMarks(uint32 diff, Player* owner, BonkRun* run)
{
    uint32 const intervalMs = TuneMs(run->GetDifficultyStep() >= 2 ? TUNE_MARK_MYTHIC : TUNE_MARK_HEROIC);
    if (!intervalMs)
        return;
    if (m_markTimer < 0)
        m_markTimer = int32(intervalMs / 2);
    m_markTimer -= int32(diff);
    if (m_markTimer > 0 || run->IsHeroMarked() || !m_creature->IsWithinDistInMap(owner, BONK_MARK_RANGE))
        return;
    m_markTimer = int32(intervalMs);

    float const melee = GetMeleeHit();
    BonkEnemyHit const burst = MakeHit(run, 0, uint32(std::max(1.0f, melee * Tune(TUNE_MARK_DAMAGE))));
    BonkEnemyHit const pool = MakeHit(run, 0, uint32(std::max(1.0f, melee * BONK_VOID_DAMAGE)));
    run->MarkHero(burst, pool, std::max(1.0f, Tune(TUNE_MARK_RADIUS)), BONK_MARK_FILL_MS, GetWarnMs(run, TuneMs(TUNE_MARK_WARN)),
        TuneMs(TUNE_MARK_POOL));
    if (!m_markAnnounced)
    {
        m_markAnnounced = true;
        owner->GetBonkPlayer()->Notify(BONK_STRING_ENEMY_MARKS_YOU, { owner->GetBonkPlayer()->GetLocalName(m_creature) });
    }
}

void BonkMobAI::UpdateFarBlast(uint32 diff, Player* owner, BonkRun* run)
{
    float const range = Tune(TUNE_FAR_RANGE);
    if (range <= 0.0f || m_creature->IsWithinDistInMap(owner, range))
    {
        m_farMs = 0;
        return;
    }
    m_farMs += diff;
    m_farTimer -= int32(diff);
    if (m_farMs < TuneMs(TUNE_FAR_DELAY) || m_farTimer > 0)
        return;
    m_farTimer = int32(std::max(250u, TuneMs(TUNE_FAR_INTERVAL)));

    uint32 const count = uint32(std::max(1.0f, Tune(TUNE_FAR_COUNT))) + (run->GetDifficultyStep() >= 2 ? 1 : 0);
    BonkEnemyHit const hit = MakeHit(run, 0, uint32(std::max(1.0f, GetMeleeHit() * Tune(TUNE_FAR_DAMAGE))));
    LaunchBarrage(owner, run, hit, count, std::max(1.0f, Tune(TUNE_FAR_RADIUS)), GetWarnMs(run, BONK_AREA_WARN_MS));
    if (!m_farAnnounced)
    {
        m_farAnnounced = true;
        owner->GetBonkPlayer()->Notify(BONK_STRING_ENEMY_BOMBARDS_YOU, { owner->GetBonkPlayer()->GetLocalName(m_creature) });
    }
}

void BonkMobAI::UpdateLeash(uint32 diff, Player* owner)
{
    float const range = Tune(TUNE_LEASH_RANGE);
    if (range <= 0.0f || m_creature->IsWithinDistInMap(owner, range))
    {
        m_leashMs = 0;
        return;
    }
    m_leashMs += diff;
    m_leashTimer -= int32(diff);
    if (m_leashMs < TuneMs(TUNE_LEASH_DELAY) || m_leashTimer > 0)
        return;
    m_leashTimer = int32(IN_MILLISECONDS);
    if (m_creature->GetHealth() >= m_creature->GetMaxHealth())
        return;

    m_creature->ModifyHealth(int32(std::max(1.0f, m_creature->GetMaxHealth() * Tune(TUNE_LEASH_HEAL) / 100.0f)));
    if (!m_leashAnnounced)
    {
        m_leashAnnounced = true;
        owner->GetBonkPlayer()->Notify(BONK_STRING_ENEMY_RECOVERS, { owner->GetBonkPlayer()->GetLocalName(m_creature) });
    }
}

bool BonkMobAI::SetBossTune(std::string const& key, float value)
{
    for (BossTuneEntry& entry : s_bossTune)
        if (key == entry.key)
        {
            entry.value = value;
            return true;
        }
    return false;
}

std::vector<std::string> BonkMobAI::DescribeBossTune()
{
    std::vector<std::string> lines;
    for (BossTuneEntry const& entry : s_bossTune)
    {
        char value[32];
        snprintf(value, sizeof(value), "%g", entry.value);
        lines.push_back(std::string(entry.key) + " " + value + ": " + entry.meaning);
    }
    return lines;
}

void BonkMobAI::SetRaidTarget(ObjectGuid target)
{
    m_raidTarget = target;
    m_raidAngle = frand(0.0f, 2.0f * M_PI_F);
    m_creature->AttackStop();
    m_creature->GetMotionMaster()->Clear(false);
    if (Creature* caravan = m_creature->GetMap()->GetCreature(target))
        m_creature->GetMotionMaster()->MoveFollow(caravan, BONK_RAID_FOLLOW_DISTANCE, m_raidAngle);
}

void BonkMobAI::SetStationary()
{
    m_stationary = true;
    m_creature->AttackStop();
    m_creature->StopMoving();
    m_creature->GetMotionMaster()->Clear(false);
    m_creature->GetMotionMaster()->MoveIdle();
    m_creature->AddUnitState(UNIT_STATE_ROOT);
    m_creature->SetRooted(true);
}

void BonkMobAI::SetPassive(bool passive)
{
    if (m_passive == passive)
        return;
    m_passive = passive;

    if (!passive)
    {
        if (Player* owner = GetOwner())
            AttackStart(owner);
        return;
    }

    Halt();
    m_creature->GetMotionMaster()->MoveIdle();
}

void BonkMobAI::SetMovesOff(bool off)
{
    m_movesOff = off;
    if (!off)
        return;
    AbandonWindups();
    m_boltTarget.Clear();
    m_creature->InterruptNonMeleeSpells(false);
    if (Player* owner = GetOwner())
        ResumeChase(owner);
}

void BonkMobAI::StartStampede(Player* owner, float angle, float length, uint32 windupMs, float damage)
{
    BonkRun* run = owner->GetBonkPlayer()->GetRun();
    if (!run)
        return;

    m_stampede = true;
    m_chargeX = m_creature->GetPositionX();
    m_chargeY = m_creature->GetPositionY();
    m_chargeZ = m_creature->GetPositionZ();
    m_chargeAngle = angle;
    m_dashX = m_chargeX + length * std::cos(angle);
    m_dashY = m_chargeY + length * std::sin(angle);
    m_dashZ = m_chargeZ;
    m_creature->GetMap()->GetWalkHitPosition(nullptr, m_chargeX, m_chargeY, m_chargeZ, m_dashX, m_dashY, m_dashZ);
    m_chargeLength = m_creature->GetDistance2d(m_dashX, m_dashY);
    if (m_chargeLength < BONK_CHARGE_MIN_RANGE)
    {
        m_creature->DespawnOrUnsummon(1);
        return;
    }

    m_chargeState = CHARGE_WINDUP;
    m_chargeTimer = int32(windupMs);
    m_chargeDamage = damage;
    m_creature->AttackStop();
    m_creature->StopMoving();
    m_creature->GetMotionMaster()->Clear(false);
    m_creature->GetMotionMaster()->MoveIdle();
    m_creature->SetFacingTo(angle);
    WarnCharge(run, windupMs);
}

void BonkMobAI::SetFleeing(bool blinks, uint32 headStartMs)
{
    m_fleeing = true;
    m_blinks = blinks;
    m_fleeTimer = int32(headStartMs);
    m_fleeStanding = headStartMs > 0;
    m_creature->AttackStop();
    m_creature->GetMotionMaster()->Clear(false);
    m_creature->GetMotionMaster()->MoveIdle();
    if (Player* owner = GetOwner())
        m_creature->SetFacingToObject(owner);
}

void BonkMobAI::UpdateFlee(uint32 diff, Player* owner)
{
    m_blinkTimer -= int32(diff);
    if (m_blinkPending)
    {
        m_blinkPending = false;
        float x, y, z;
        if (FindFleePoint(owner, BONK_FLEE_BLINK, x, y, z))
        {
            m_creature->GetMotionMaster()->Clear(false);
            m_creature->NearTeleportTo(x, y, z, owner->GetAngle(x, y));
            ShowArrivalFlash();
            m_blinkTimer = BONK_FLEE_BLINK_MS;
            m_fleeTimer = 0;
        }
    }

    m_fleeTimer -= int32(diff);
    if (m_fleeTimer > 0)
        return;
    m_fleeTimer = BONK_FLEE_STEP_MS;
    m_fleeStanding = false;

    float x, y, z;
    if (FindFleePoint(owner, BONK_FLEE_STEP, x, y, z))
        m_creature->GetMotionMaster()->MovePoint(1, x, y, z, MOVE_PATHFINDING | MOVE_RUN_MODE);
}

void BonkMobAI::SetFleeHeading(float heading)
{
    m_hasFleeHeading = true;
    m_fleeHeading = heading;
}

float BonkMobAI::GetFleeAngle(Player* owner) const
{
    float const away = owner->GetAngle(m_creature);
    if (!m_hasFleeHeading)
        return away;
    bool const heroAhead = std::fabs(std::remainder(m_creature->GetAngle(owner) - m_fleeHeading, 2.0f * M_PI_F)) < M_PI_F / 2.0f;
    return heroAhead && m_creature->IsWithinDistInMap(owner, BONK_FLEE_CUT_OFF) ? away : m_fleeHeading;
}

bool BonkMobAI::FindFleePoint(Player* owner, float distance, float& x, float& y, float& z) const
{
    Map* map = m_creature->GetMap();
    float const away = GetFleeAngle(owner);
    for (float swerve : { 0.0f, 0.5f, -0.5f, 1.0f, -1.0f, 1.6f, -1.6f, 2.2f, -2.2f })
    {
        float const angle = away + swerve + frand(-0.25f, 0.25f);
        x = m_creature->GetPositionX() + distance * std::cos(angle);
        y = m_creature->GetPositionY() + distance * std::sin(angle);
        z = map->GetHeight(x, y, m_creature->GetPositionZ() + BONK_FLEE_CLIMB, true, BONK_FLEE_CLIMB * 2.0f);
        if (z <= INVALID_HEIGHT || std::fabs(z - m_creature->GetPositionZ()) > BONK_FLEE_CLIMB)
            continue;
        if (map->GetTerrain()->GetZoneId(x, y, z) != owner->GetZoneId() || !IsBonkDryGround(map, x, y, z))
            continue;
        return true;
    }
    return false;
}

void BonkMobAI::JustSummoned(Creature* summoned)
{
    summoned->DespawnOrUnsummon(1);
}

std::string BonkMobAI::Describe() const
{
    static char const* const kinds[MAX_BONK_SPAWN_KIND] = { "normal", "elite", "boss", "mini-boss" };
    std::string text = std::string("kind ") + kinds[m_kind] + ", archetype " + sBonkMgr.GetArchetype(m_archetype).name;
    auto note = [&text](char const* name, bool on) { text += std::string(", ") + name + (on ? " yes" : " no"); };
    note("passive", m_passive);
    note("stationary", m_stationary);
    note("fleeing", m_fleeing);
    note("frozen", m_frozen);
    note("winding up", m_areaWinding);
    note("charging", m_chargeState != CHARGE_NONE);
    note("raiding", !m_raidTarget.IsEmpty());
    note("melee", IsMeleeAttackEnabled());
    return text;
}

void BonkMobAI::JustDied(Unit* killer)
{
    m_creature->SetTimeFrozen(false);
    ClearWindupLook();
    if (m_creature->HasStaticFlag(CREATURE_STATIC_FLAG_DESPAWN_INSTANTLY))
        m_creature->DespawnOrUnsummon(BONK_DEAD_REMOVE_MS);

    Player* spawner = GetSpawner();
    if (!spawner)
        return;

    if (BonkRun* run = spawner->GetBonkPlayer()->GetRun())
        run->OnMobKilled(m_creature, m_kind, killer);
}

void BonkMobAI::OnRemoveFromWorld()
{
    Player* spawner = GetSpawner();
    if (spawner)
        if (BonkRun* run = spawner->GetBonkPlayer()->GetRun())
            run->ForgetEnemyAttacks(m_creature);
    Player* target = GetOwner();
    if (target && target != spawner)
        if (BonkRun* run = target->GetBonkPlayer()->GetRun())
            run->ForgetEnemyAttacks(m_creature);
}

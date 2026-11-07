#ifndef MANGOS_BONKMASTERY_H
#define MANGOS_BONKMASTERY_H

#include "Common.h"
#include "BonkMgr.h"
#include "Policies/Singleton.h"

#include <map>
#include <set>
#include <string>
#include <utility>
#include <vector>

enum BonkMasteryEffect : uint8
{
    BONK_MASTERY_PASSIVE        = 0,
    BONK_MASTERY_SPELL_DAMAGE   = 1,
    BONK_MASTERY_SCHOOL_DAMAGE  = 2,
    BONK_MASTERY_SPELL_COOLDOWN = 3,
    BONK_MASTERY_SPELL_TARGETS  = 4,
    BONK_MASTERY_STARTER_UNLOCK = 5,
    BONK_MASTERY_SHATTER        = 6,
    BONK_MASTERY_OPENER         = 7,
    BONK_MASTERY_EXECUTE        = 8,
    BONK_MASTERY_CLEARCASTING   = 9,
    BONK_MASTERY_SOUL_SIPHON    = 10,
    BONK_MASTERY_SPELL_SLOW     = 11,
    BONK_MASTERY_SPEC_DAMAGE    = 12,
    BONK_MASTERY_KEYWORD_DAMAGE = 13,
    BONK_MASTERY_CRIT_VS_KEYWORD = 14,
    BONK_MASTERY_USES_BONUS     = 15,
    BONK_MASTERY_SPELL_APPLIES  = 16,
    BONK_MASTERY_SPELL_HEAL     = 17,
    BONK_MASTERY_RESET_ON_KILL  = 18,
    BONK_MASTERY_EXECUTE_THRESHOLD = 19,
    BONK_MASTERY_SPELL_STUN     = 20,
    BONK_MASTERY_STRUCK_CAST    = 21,
    BONK_MASTERY_ENRAGE_DURATION = 22,
    BONK_MASTERY_ENRAGE_HASTE   = 23,
    BONK_MASTERY_ENRAGE_DAMAGE  = 24,
    BONK_MASTERY_SHIELD_BLOCK   = 25,
    BONK_MASTERY_DASH_RECHARGE  = 26,
    BONK_MASTERY_CHILL_DURATION = 27,
    BONK_MASTERY_SPREAD_TARGETS = 28,
    BONK_MASTERY_MARK_BONUS     = 29,
    BONK_MASTERY_SUMMON_CRIT    = 30,
    BONK_MASTERY_PACK_POWER     = 31,
    BONK_MASTERY_FRENZY_DAMAGE  = 32,
    BONK_MASTERY_LAST_STAND     = 33,
    BONK_MASTERY_ICE_BLOCK      = 34,
    BONK_MASTERY_BLINK_SHIELD   = 35,
    BONK_MASTERY_ENTRAPMENT     = 36,
    BONK_MASTERY_TRAP_DURATION  = 37,
    BONK_MASTERY_CAPSTONE       = 38,
    BONK_MASTERY_SPELL_STACKS   = 39,
    BONK_MASTERY_SPELL_DURATION = 40,
    BONK_MASTERY_SPELL_REACH    = 41,
    BONK_MASTERY_KEYWORD_DURATION = 42,
    BONK_MASTERY_KEYWORD_CAP    = 43,
    BONK_MASTERY_CAST_HASTE     = 44,
    BONK_MASTERY_SPECIAL        = 45,
    BONK_MASTERY_SPELL_BEHAVIOR = 46,
    BONK_MASTERY_KEYWORD_CRIT   = 47,
    MAX_BONK_MASTERY_EFFECT
};

enum BonkTalentSpecial : uint8
{
    BONK_SPECIAL_NONE                    = 0,
    BONK_SPECIAL_CLEARCASTING_BOOST      = 1,
    BONK_SPECIAL_ARCANE_POTENCY          = 2,
    BONK_SPECIAL_ARCANE_POTENCY_LONG     = 3,
    BONK_SPECIAL_TORMENT_THE_WEAK        = 4,
    BONK_SPECIAL_ARCANE_ECHO             = 5,
    BONK_SPECIAL_TEMPORAL_FLUX           = 6,
    BONK_SPECIAL_KINDLING                = 7,
    BONK_SPECIAL_KINDLING_FLAMESTRIKE    = 8,
    BONK_SPECIAL_SEARING_BURST           = 9,
    BONK_SPECIAL_PYROCLASM_BURNING       = 10,
    BONK_SPECIAL_CONFLAGRATION           = 11,
    BONK_SPECIAL_WINTERS_CHILL           = 12,
    BONK_SPECIAL_FINGERS_OF_FROST        = 13,
    BONK_SPECIAL_GLACIAL_FRAGMENTS       = 14,
    BONK_SPECIAL_GLACIAL_FRAGMENTS_CHILL = 15,
    BONK_SPECIAL_FREEZING_WINDS          = 16,
    BONK_SPECIAL_SPLINTERING_COLD        = 17,
    BONK_SPECIAL_BLOODSURGE              = 18,
    BONK_SPECIAL_OVERPOWER               = 19,
    BONK_SPECIAL_FRENZY                  = 20,
    BONK_SPECIAL_FRESH_MEAT              = 21,
    BONK_SPECIAL_RAMPAGE                 = 22,
    BONK_SPECIAL_ANNIHILATOR             = 23,
    BONK_SPECIAL_RECKLESS_ABANDON        = 24,
    BONK_SPECIAL_UNBREAKABLE             = 25,
    BONK_SPECIAL_THUNDERLORD             = 26,
    BONK_SPECIAL_PACK_TACTICS            = 27,
    BONK_SPECIAL_INTIMIDATION            = 28,
    BONK_SPECIAL_CLAW_HASTE              = 29,
    BONK_SPECIAL_BEAST_CLEAVE            = 30,
    BONK_SPECIAL_PACK_HUNTER             = 31,
    BONK_SPECIAL_INTIMIDATING_ROAR       = 32,
    BONK_SPECIAL_KINDRED_SPIRITS         = 33,
    BONK_SPECIAL_RAPID_FIRE              = 34,
    BONK_SPECIAL_KILL_SHOT               = 35,
    BONK_SPECIAL_MONGOOSE_FURY           = 36,
    BONK_SPECIAL_AWAKENING               = 37,
    BONK_SPECIAL_DIVINE_PURPOSE          = 38,
    BONK_SPECIAL_RIGHTEOUS_PROTECTOR     = 39,
    BONK_SPECIAL_BULWARK                 = 40,
    BONK_SPECIAL_RIGHTEOUS_VERDICT       = 41,
    BONK_SPECIAL_FINAL_RECKONING         = 42,
    BONK_SPECIAL_EMPYREAN_POWER          = 43,
    BONK_SPECIAL_VENOMOUS_WOUNDS         = 44,
    BONK_SPECIAL_VENOM_RUSH              = 45,
    BONK_SPECIAL_DEATHMARK               = 46,
    BONK_SPECIAL_VENDETTA                = 47,
    BONK_SPECIAL_RESTLESS_BLADES         = 48,
    BONK_SPECIAL_ADRENALINE_RUSH         = 49,
    BONK_SPECIAL_SLICE_AND_DICE          = 50,
    BONK_SPECIAL_DREADBLADES             = 51,
    BONK_SPECIAL_PREMEDITATION           = 52,
    BONK_SPECIAL_DEEPENING_SHADOWS       = 53,
    BONK_SPECIAL_MASTER_OF_SHADOWS       = 54,
    BONK_SPECIAL_DANSE_MACABRE           = 55,
    BONK_SPECIAL_SECRET_TECHNIQUE        = 56,
    BONK_SPECIAL_CASTIGATION             = 57,
    BONK_SPECIAL_SHEER_TERROR            = 58,
    BONK_SPECIAL_BORROWED_TIME           = 59,
    BONK_SPECIAL_SCHISM                  = 60,
    BONK_SPECIAL_SHINING_FORCE           = 61,
    BONK_SPECIAL_POWER_INFUSION          = 62,
    BONK_SPECIAL_LIGHT_OF_THE_NAARU      = 63,
    BONK_SPECIAL_BENEDICTION             = 64,
    BONK_SPECIAL_ANSWERED_PRAYERS        = 65,
    BONK_SPECIAL_DIVINE_PROVIDENCE       = 66,
    BONK_SPECIAL_PSYCHIC_LINK            = 67,
    BONK_SPECIAL_SURGE_OF_DARKNESS       = 68,
    BONK_SPECIAL_ANCIENT_MADNESS         = 69,
    BONK_SPECIAL_AFTERSHOCK              = 70,
    BONK_SPECIAL_STATIC_CHARGE           = 71,
    BONK_SPECIAL_UNRELENTING_STORM       = 72,
    BONK_SPECIAL_IMPROVED_WINDFURY       = 73,
    BONK_SPECIAL_FLURRY                  = 74,
    BONK_SPECIAL_ALPHA_WOLF              = 75,
    BONK_SPECIAL_STORMFLURRY             = 76,
    BONK_SPECIAL_FORCEFUL_WINDS          = 77,
    BONK_SPECIAL_EARTHGRAB               = 78,
    BONK_SPECIAL_CALL_OF_THE_ELEMENTS    = 79,
    BONK_SPECIAL_CONTAGION               = 80,
    BONK_SPECIAL_CURSE_OF_EXHAUSTION     = 81,
    BONK_SPECIAL_HARVESTER_OF_SOULS      = 82,
    BONK_SPECIAL_IMPROVED_IMP            = 83,
    BONK_SPECIAL_IMPROVED_VOIDWALKER     = 84,
    BONK_SPECIAL_DEMONIC_PACT            = 85,
    BONK_SPECIAL_FEL_SUNDER              = 86,
    BONK_SPECIAL_SHADOWFURY              = 87,
    BONK_SPECIAL_IMPROVED_SHADOW_BOLT    = 88,
    BONK_SPECIAL_SOUL_FIRE               = 89,
    BONK_SPECIAL_BACKLASH                = 90,
    BONK_SPECIAL_DEMONIC_EMPOWERMENT     = 91,
    BONK_SPECIAL_IMPROVED_EMPOWERMENT    = 92,
    BONK_SPECIAL_IMPROVED_HURRICANE      = 93,
    BONK_SPECIAL_STARLORD                = 94,
    BONK_SPECIAL_IMPROVED_FRENZIED       = 95,
    BONK_SPECIAL_SURVIVAL_OF_THE_FITTEST = 96,
    BONK_SPECIAL_BLOODTALONS             = 97,
    BONK_SPECIAL_INNER_PEACE             = 98,
    BONK_SPECIAL_DEEP_ROOTS              = 99,
    BONK_SPECIAL_GROVE_GUARDIANS         = 100,
    BONK_SPECIAL_FLOURISH                = 101,
    BONK_SPECIAL_SOUL_OF_THE_FOREST      = 102,
    BONK_SPECIAL_EXECUTE_ENRAGE          = 103,
    BONK_SPECIAL_THUNDER_SHIELD          = 104,
    BONK_SPECIAL_HAMMER_EXPOSE           = 105,
    BONK_SPECIAL_CONSECRATED_RETRIBUTION = 106,
    BONK_SPECIAL_JUDGEMENT_COMMAND       = 107,
    BONK_SPECIAL_MARK_TRANSFER           = 108,
    BONK_SPECIAL_SPREE_CRIT              = 109,
    BONK_SPECIAL_SHURIKEN_AMBUSH         = 110,
    BONK_SPECIAL_PENANCE_SHIELD          = 111,
    BONK_SPECIAL_RENEW_SHIELD            = 112,
    BONK_SPECIAL_BOLT_STATIC             = 113,
    BONK_SPECIAL_STORMSTRIKE_WINDFURY    = 114,
    BONK_SPECIAL_MISSILE_SPLIT           = 115,
    BONK_SPECIAL_THAW_CHILL              = 116,
    BONK_SPECIAL_DEMON_CLEAVE            = 117,
    BONK_SPECIAL_ROOT_SPREAD             = 118,
    BONK_SPECIAL_PENANCE_KILL_COOLDOWN   = 119,
    MAX_BONK_SPECIAL
};

enum BonkCapstone : uint8
{
    BONK_CAPSTONE_NONE          = 0,
    BONK_CAPSTONE_BESTIAL_WRATH = 1,
    BONK_CAPSTONE_TRUESHOT      = 2,
    BONK_CAPSTONE_TRAPMASTER    = 3,
    BONK_CAPSTONE_WEAPON_MASTER = 4,
    BONK_CAPSTONE_BERSERKER     = 5,
    BONK_CAPSTONE_JUGGERNAUT    = 6,
    BONK_CAPSTONE_ARCANE_SURGE  = 7,
    BONK_CAPSTONE_GLASS_CANNON  = 8,
    BONK_CAPSTONE_SHATTERLORD   = 9,
    BONK_CAPSTONE_ASCENDANCE    = 10,
    BONK_CAPSTONE_DOOMHAMMER    = 11,
    BONK_CAPSTONE_TOTEMIC_MASTERY = 12,
    BONK_CAPSTONE_ARCHANGEL     = 13,
    BONK_CAPSTONE_PAIN_SUPPRESSION = 14,
    BONK_CAPSTONE_SHADOWFORM    = 15,
    BONK_CAPSTONE_MASTER_POISONER = 16,
    BONK_CAPSTONE_BLADE_DANCER  = 17,
    BONK_CAPSTONE_MASTER_OF_SUBTLETY = 18,
    BONK_CAPSTONE_DIVINE_ILLUMINATION = 19,
    BONK_CAPSTONE_GUARDIAN_OF_THE_LIGHT = 20,
    BONK_CAPSTONE_TEMPLARS_VERDICT = 21,
    BONK_CAPSTONE_PANDEMIC      = 22,
    BONK_CAPSTONE_MASTER_DEMONOLOGIST = 23,
    BONK_CAPSTONE_RUIN          = 24,
    BONK_CAPSTONE_CELESTIAL_ALIGNMENT = 25,
    BONK_CAPSTONE_PRIMAL_FURY   = 26,
    BONK_CAPSTONE_HEART_OF_THE_WILD = 27,
    MAX_BONK_CAPSTONE
};

uint32 const BONK_MASTERY_MAX_LEVEL = 30;
uint32 const BONK_MASTERY_XP_BASE   = 50;
uint32 const BONK_MASTERY_XP_STEP   = 8;
uint32 const BONK_MASTERY_XP_CURVE  = 1;
uint32 const BONK_MASTERY_XP_SLOW_FROM_LEVEL = 10;
uint32 const BONK_MASTERY_XP_SLOW_PERCENT_PER_LEVEL = 20;
uint32 const BONK_MASTERY_POINTS_PER_ROW = 5;
uint8 const BONK_MASTERY_LAYOUT_GRID = 0;
uint32 const BONK_TREE_ARCANE = 801;
uint32 const BONK_TREE_FIRE   = 802;
uint32 const BONK_WEAPON_FROSTBOLT  = 400;
uint32 const BONK_WEAPON_BLIZZARD   = 401;
uint32 const BONK_WEAPON_FLAMESTRIKE = 404;
uint32 const BONK_WEAPON_PYROBLAST  = 405;
uint32 const BONK_WEAPON_FIRE_BLAST = 406;
uint32 const BONK_WEAPON_MORTAL_STRIKE = 303;
uint32 const BONK_WEAPON_BLOODTHIRST   = 304;
uint32 const BONK_WEAPON_THUNDER_CLAP  = 308;
uint32 const BONK_WEAPON_CALL_PET      = 201;
uint32 const BONK_WEAPON_AIMED_SHOT    = 203;
uint32 const BONK_WEAPON_HUNTERS_MARK  = 205;
uint32 const BONK_WEAPON_JUDGEMENT     = 801;
uint32 const BONK_WEAPON_SEAL_COMMAND = 802;
uint32 const BONK_WEAPON_EXORCISM      = 805;
uint32 const BONK_WEAPON_DIVINE_STORM  = 806;
uint32 const BONK_WEAPON_DIVINE_SHIELD = 809;
uint32 const BONK_WEAPON_HAMMER_OF_JUSTICE = 811;
uint32 const BONK_WEAPON_LIGHTS_HAMMER = 812;
uint32 const BONK_WEAPON_AVENGERS_SHIELD_PALADIN = 813;
uint32 const BONK_WEAPON_SINISTER_STRIKE = 600;
uint32 const BONK_WEAPON_BLADE_FLURRY  = 601;
uint32 const BONK_WEAPON_EVISCERATE    = 602;
uint32 const BONK_WEAPON_KILLING_SPREE = 603;
uint32 const BONK_WEAPON_ENVENOM       = 607;
uint32 const BONK_WEAPON_SHADOW_DANCE  = 610;
uint32 const BONK_WEAPON_SMITE         = 500;
uint32 const BONK_WEAPON_HALO          = 502;
uint32 const BONK_WEAPON_POWER_WORD_SHIELD = 504;
uint32 const BONK_WEAPON_PENANCE       = 505;
uint32 const BONK_WEAPON_MIND_BLAST    = 510;
uint32 const BONK_WEAPON_STORMSTRIKE   = 705;
uint32 const BONK_WEAPON_SHADOW_BOLT   = 907;
uint32 const BONK_WEAPON_RAIN_OF_FIRE  = 910;
uint32 const BONK_WEAPON_STARFIRE      = 1001;
float const BONK_BLOOM_HASTE = 15.0f;
uint8 const BONK_MASTERY_LAYOUT_FREE = 1;
uint8 const BONK_MASTERY_FREE_ROWS = 9;
uint32 const BONK_MASTERY_FREE_GATES[BONK_MASTERY_FREE_ROWS] = { 0, 0, 0, 5, 10, 10, 15, 15, 21 };

enum BonkMasteryShape : uint8
{
    BONK_MASTERY_SHAPE_SQUARE   = 0,
    BONK_MASTERY_SHAPE_ROUND    = 1,
    BONK_MASTERY_SHAPE_CHOICE   = 2,
    BONK_MASTERY_SHAPE_CAPSTONE = 3,
    BONK_MASTERY_SHAPE_ONE_WAY  = 4,
    BONK_MASTERY_SHAPE_STARTER  = 5,
    MAX_BONK_MASTERY_SHAPE
};

struct BonkMasteryTree
{
    uint32 id = 0;
    uint8 classId = 0;
    std::string name;
    std::string background;
    uint8 order = 0;
    uint8 layout = BONK_MASTERY_LAYOUT_GRID;

    bool IsFree() const { return layout == BONK_MASTERY_LAYOUT_FREE; }
};

struct BonkMasteryNode
{
    uint32 id = 0;
    uint8 classId = 0;
    uint32 tree = 0;
    uint8 row = 1;
    uint8 column = 1;
    std::string icon;
    std::string name;
    std::string description;
    uint8 maxRank = 1;
    uint32 requiredId = 0;
    uint8 requiredRank = 0;
    uint32 excludes = 0;
    BonkMasteryShape shape = BONK_MASTERY_SHAPE_SQUARE;
    float position = 0.0f;
    std::vector<uint32> parents;
    BonkMasteryEffect effect = BONK_MASTERY_PASSIVE;
    uint32 target = 0;
    uint32 param = 0;
    float valuePerRank = 0.0f;
};

struct BonkMasteryApply
{
    BonkKeyword keyword = BONK_KEYWORD_NONE;
    uint8 stacks = 0;
};

struct BonkMasteryBonuses
{
    float passives[MAX_BONK_PASSIVE_EFFECT] = {};
    std::map<uint32, float> spellDamage;
    std::map<uint32, float> spellCooldown;
    std::map<uint32, uint32> spellTargets;
    std::vector<std::pair<uint32, float>> schoolDamage;
    float shatter = 0.0f;
    std::vector<std::pair<uint32, float>> opener;
    std::vector<std::pair<uint32, float>> execute;
    float clearcasting = 0.0f;
    std::vector<std::pair<uint32, float>> soulSiphon;
    std::map<uint32, float> spellSlow;
    std::map<uint32, float> specDamage;
    std::map<uint32, float> keywordDamage;
    std::map<uint32, float> critVsKeyword;
    std::set<uint32> keywordCrit;
    std::map<uint32, float> usesBonus;
    std::map<uint32, BonkMasteryApply> spellApplies;
    std::map<uint32, float> spellHeal;
    std::set<uint32> resetOnKill;
    std::map<uint32, float> executeThreshold;
    std::map<uint32, float> spellStun;
    std::map<uint32, float> struckCast;
    std::map<uint32, uint32> spreadTargets;
    std::set<uint32> entrapment;
    float enrageDuration = 0.0f;
    float enrageHaste = 0.0f;
    float enrageDamage = 0.0f;
    float shieldBlock = 0.0f;
    float dashRecharge = 0.0f;
    float chillDuration = 0.0f;
    float markBonus = 0.0f;
    float summonCrit = 0.0f;
    float packPower = 0.0f;
    float frenzyDamage = 0.0f;
    float lastStand = 0.0f;
    float iceBlock = 0.0f;
    float blinkShield = 0.0f;
    float trapDuration = 0.0f;
    std::map<uint32, float> spellStacks;
    std::map<uint32, float> spellDuration;
    std::map<uint32, float> spellReach;
    std::map<uint32, float> spellBehavior;
    std::map<uint32, float> keywordDuration;
    std::map<uint32, float> keywordCap;
    std::map<uint32, float> castHaste;
    std::map<uint32, uint32> castHasteStacks;
    float specials[MAX_BONK_SPECIAL] = {};
    BonkCapstone capstone = BONK_CAPSTONE_NONE;

    bool Has(BonkCapstone which) const { return capstone == which; }
    float Special(BonkTalentSpecial which) const { return specials[which]; }
    float EnrageBoost() const { return Has(BONK_CAPSTONE_BERSERKER) ? 1.5f : 1.0f; }
};

class BonkMastery
{
    public:
        void Load();

        std::vector<BonkMasteryTree const*> GetTrees(uint8 classId) const;
        BonkMasteryNode const* GetNode(uint32 id) const;
        BonkMasteryTree const* GetTree(uint32 id) const;
        BonkMasteryNode const* FindStarterUnlock(uint8 classId, uint32 weaponId) const;
        std::map<uint32, BonkMasteryNode> const& GetNodes() const { return m_nodes; }
        bool HasTrees(uint8 classId) const;
        uint32 GetRowGate(BonkMasteryNode const& node) const;
        bool IsFreeNode(BonkMasteryNode const& node) const { return node.shape == BONK_MASTERY_SHAPE_STARTER; }

        static uint32 GetLevel(uint32 xp);
        static uint32 GetXpIntoLevel(uint32 xp);
        static uint32 GetXpForLevel(uint32 level);

        BonkMasteryBonuses Evaluate(std::map<uint32, uint8> const& ranks) const;

        static uint32 GetRootWeapon(uint32 weaponId);
        static uint32 GetSpec(uint32 weaponId);

    private:
        static void ApplyCapstoneCost(BonkMasteryBonuses& bonuses);

        std::map<uint32, BonkMasteryTree> m_trees;
        std::map<uint32, BonkMasteryNode> m_nodes;
};

#define sBonkMastery MaNGOS::Singleton<BonkMastery>::Instance()

#endif

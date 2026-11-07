#include "BonkEnchant.h"
#include "BonkFoundGear.h"
#include "BonkMgr.h"
#include "Player.h"
#include "Utilities/Random.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <iterator>

namespace
{
    uint8 const BONK_ENCHANT_SLOTS[] = { EQUIPMENT_SLOT_HEAD, EQUIPMENT_SLOT_SHOULDERS, EQUIPMENT_SLOT_CHEST, EQUIPMENT_SLOT_WAIST,
        EQUIPMENT_SLOT_LEGS, EQUIPMENT_SLOT_FEET, EQUIPMENT_SLOT_WRISTS, EQUIPMENT_SLOT_HANDS };

    struct BonkEnchantGrade
    {
        BonkString name;
        uint32 weight;
        float multiplier;
        float piecePercent;
    };

    BonkEnchantGrade const BONK_ENCHANT_GRADES[] =
    {
        { BONK_STRING_ENCHANT_GRADE_MINOR,    40, 1.0f, 10.0f },
        { BONK_STRING_ENCHANT_GRADE_LESSER,   30, 1.5f, 20.0f },
        { BONK_STRING_ENCHANT_GRADE_GREATER,  20, 2.2f, 30.0f },
        { BONK_STRING_ENCHANT_GRADE_SUPERIOR,  8, 3.2f, 40.0f },
        { BONK_STRING_ENCHANT_GRADE_GODLY,     2, 5.0f, 50.0f },
    };
    uint8 const BONK_ENCHANT_GRADE_COUNT = uint8(sizeof(BONK_ENCHANT_GRADES) / sizeof(BONK_ENCHANT_GRADES[0]));

    struct BonkEnchantStat
    {
        BonkPassiveEffect effect;
        float base;
        bool ofPiece;
    };

    BonkEnchantStat const BONK_ENCHANT_STATS[] =
    {
        { BONK_PASSIVE_POWER,       1.0f,  true },
        { BONK_PASSIVE_MAX_HEALTH,  1.15f, true },
        { BONK_PASSIVE_CRIT,        0.5f,  false },
        { BONK_PASSIVE_CRIT_DAMAGE, 1.0f,  false },
        { BONK_PASSIVE_DODGE,       0.4f,  false },
        { BONK_PASSIVE_SHIELD,      0.9f,  false },
    };

    BonkEnchantStat const* FindStat(uint8 effect)
    {
        for (BonkEnchantStat const& stat : BONK_ENCHANT_STATS)
            if (stat.effect == effect)
                return &stat;
        return nullptr;
    }

    uint8 RollGrade()
    {
        uint32 total = 0;
        for (BonkEnchantGrade const& grade : BONK_ENCHANT_GRADES)
            total += grade.weight;
        uint32 roll = urand(1, total);
        for (uint8 index = 0; index < BONK_ENCHANT_GRADE_COUNT; ++index)
        {
            if (roll <= BONK_ENCHANT_GRADES[index].weight)
                return index;
            roll -= BONK_ENCHANT_GRADES[index].weight;
        }
        return 0;
    }
}

uint8 const* BonkEnchanting::GetSlots()
{
    return BONK_ENCHANT_SLOTS;
}

uint8 BonkEnchanting::GetSlotCount()
{
    return uint8(sizeof(BONK_ENCHANT_SLOTS) / sizeof(BONK_ENCHANT_SLOTS[0]));
}

bool BonkEnchanting::IsEnchantSlot(uint8 slot)
{
    return std::find(std::begin(BONK_ENCHANT_SLOTS), std::end(BONK_ENCHANT_SLOTS), slot) != std::end(BONK_ENCHANT_SLOTS);
}

BonkEnchant BonkEnchanting::Roll(float const* pieceStats)
{
    std::vector<BonkPassiveEffect> choices;
    for (BonkEnchantStat const& stat : BONK_ENCHANT_STATS)
        if (!stat.ofPiece || pieceStats[stat.effect] > 0.0f)
            choices.push_back(stat.effect);
    BonkEnchant enchant;
    enchant.effect = uint8(choices[urand(0, uint32(choices.size() - 1))]);
    enchant.grade = RollGrade();
    return enchant;
}

float BonkEnchanting::GetValue(BonkEnchant const& enchant, float const* pieceStats)
{
    BonkEnchantStat const* stat = FindStat(enchant.effect);
    if (!stat || enchant.grade >= BONK_ENCHANT_GRADE_COUNT)
        return 0.0f;
    BonkEnchantGrade const& grade = BONK_ENCHANT_GRADES[enchant.grade];
    float const value = stat->ofPiece ? std::max(0.0f, pieceStats[stat->effect]) * grade.piecePercent / 100.0f : stat->base * grade.multiplier;
    return std::round(value * 10.0f) / 10.0f;
}

BonkString BonkEnchanting::GetGradeName(uint8 grade)
{
    return grade < BONK_ENCHANT_GRADE_COUNT ? BONK_ENCHANT_GRADES[grade].name : BonkString(0);
}

BonkEnchantDisplay BonkEnchanting::DescribeDisplay(BonkEnchant const& enchant, float const* pieceStats)
{
    BonkEnchantDisplay display;
    if (!enchant.IsSet())
        return display;
    BonkEnchantStat const* stat = FindStat(enchant.effect);
    display.effect = enchant.effect;
    display.grade = enchant.grade;
    display.value = GetValue(enchant, pieceStats);
    display.percent = stat && stat->ofPiece && enchant.grade < BONK_ENCHANT_GRADE_COUNT ? BONK_ENCHANT_GRADES[enchant.grade].piecePercent : 0.0f;
    return display;
}

std::string BonkEnchanting::Describe(BonkEnchant const& enchant, float const* pieceStats)
{
    BonkEnchantDisplay const display = DescribeDisplay(enchant, pieceStats);
    char value[64];
    snprintf(value, sizeof(value), "%.1f~%.0f", display.value, display.percent);
    return std::to_string(display.effect) + "~" + std::to_string(display.grade) + "~" + value;
}

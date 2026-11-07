#ifndef BONK_ENCHANT_H
#define BONK_ENCHANT_H

#include "Common.h"
#include "BonkStrings.h"

#include <string>

uint32 const BONK_ENCHANTER_ENTRY = 900160;
uint8 const BONK_ENCHANT_NONE = 255;

struct BonkEnchant
{
    uint8 effect = BONK_ENCHANT_NONE;
    uint8 grade = 0;

    bool IsSet() const { return effect != BONK_ENCHANT_NONE; }
};

struct BonkEnchantDisplay
{
    uint32 effect = BONK_ENCHANT_NONE;
    uint32 grade = 0;
    float value = 0.0f;
    float percent = 0.0f;
};

namespace BonkEnchanting
{
    uint8 const OFFER_COUNT = 3;

    uint8 const* GetSlots();
    uint8 GetSlotCount();
    bool IsEnchantSlot(uint8 slot);
    BonkEnchant Roll(float const* pieceStats);
    float GetValue(BonkEnchant const& enchant, float const* pieceStats);
    BonkString GetGradeName(uint8 grade);
    BonkEnchantDisplay DescribeDisplay(BonkEnchant const& enchant, float const* pieceStats);
    std::string Describe(BonkEnchant const& enchant, float const* pieceStats);
}

#endif

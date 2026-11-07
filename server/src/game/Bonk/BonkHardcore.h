#pragma once

#include "Common.h"

#include <string>
#include <vector>

struct BonkFallenRecord
{
    uint32 guid = 0;
    std::string name;
    uint8 classId = 0;
    uint32 level = 0;
    uint32 bestLevel = 0;
    uint32 mastery = 0;
    uint32 played = 0;
    uint32 runs = 0;
    uint32 kills = 0;
    std::string killer;
    std::string map;
    uint32 diedAt = 0;
    bool ironman = false;
    uint32 crashes = 0;
    bool rested = false;
};

std::vector<BonkFallenRecord> LoadBonkFallenRecords(uint32 accountId);
std::string DescribeBonkFallenForGlue(BonkFallenRecord const& record);
std::vector<std::string> BonkParkBankStatements(uint32 guidLow, uint32 poolAccount, bool takeFromCharacter);
void SettleBonkHardcoreRuns();

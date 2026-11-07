#ifndef BONK_FOUND_GEAR_H
#define BONK_FOUND_GEAR_H

#include "Common.h"
#include "BonkMgr.h"
#include "Policies/Singleton.h"

#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

class Item;
class Player;

uint8 const BONK_FOUND_MAX_LINES = 2;
uint32 const BONK_FOUND_MAX_UPGRADES = 3;
uint8 const BONK_FOUND_NO_LINE = 255;
float const BONK_GEAR_TIER_STEP = 0.25f;
uint32 const BONK_LEADERBOARD_SEASON = 1;

float BonkGearTierScale(uint32 tier);

struct BonkFoundLine
{
    uint8 effect = 0;
    float roll = 0.0f;
};

struct BonkFoundGear
{
    uint32 tier = 0;
    std::vector<BonkFoundLine> lines;
    uint32 rerolls = 0;
    uint8 rerollLine = BONK_FOUND_NO_LINE;
    uint32 upgrades = 0;
    uint32 season = BONK_LEADERBOARD_SEASON;
};

class BonkFoundStore
{
    public:
        void Load();
        void LoadCharacter(uint32 characterGuid);
        bool Get(uint32 itemGuid, BonkFoundGear& found) const;
        bool IsFound(uint32 itemGuid) const;
        void Set(uint32 itemGuid, BonkFoundGear const& found);
        void Forget(uint32 itemGuid);

    private:
        mutable std::mutex m_lock;
        std::unordered_map<uint32, BonkFoundGear> m_items;
        uint32 ReadRows(QueryResult* result, bool keepKnown);
};

#define sBonkFound MaNGOS::Singleton<BonkFoundStore>::Instance()

namespace BonkFound
{
    BonkFoundGear Roll(uint32 tier, uint8 quality, float minRoll);
    BonkFoundGear Make(uint32 tier, uint32 lineCount);
    float LineValue(BonkFoundLine const& line, uint32 tier);
    uint32 GetItemTier(Item const* item);
    uint32 GetScrapValue(Item const* item);
    uint32 GetUpgradeCost(uint32 tier);
    uint32 GetRerollCost(uint32 rerolls);
    std::vector<BonkFoundLine> RollRerollOffers(BonkFoundGear const& found, uint8 lineIndex);
    std::string DescribeOffers(std::vector<BonkFoundLine> const& offers, uint32 tier);
    std::string DescribeRanges(uint32 tier);
    uint32 GetItemLevel(uint32 tier, uint8 quality);
    std::string DescribeItemLevel(uint32 tier, uint8 quality, LocaleConstant locale);
    void AddWornStats(Item const* item, float* passives);
    std::string DescribeLines(BonkFoundGear const& found, uint32 tier);
    std::string DescribeExtra(Item const* item, uint32 tier);
    std::string DescribeExtra(uint32 entry, uint32 tier);
    void Remember(Item const* item, BonkFoundGear const& found);
}

#endif

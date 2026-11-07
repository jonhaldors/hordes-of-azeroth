#ifndef BONK_TRANSMOG_H
#define BONK_TRANSMOG_H

#include "Common.h"
#include "Policies/Singleton.h"

#include <array>
#include <mutex>
#include <set>
#include <string>
#include <unordered_map>
#include <vector>

class Item;
class Player;
class BonkPlayer;
struct ItemPrototype;

uint32 const BONK_TRANSMOGRIFIER_ENTRY = 900170;
uint32 const BONK_BLANK_TABARD_ENTRY = 939000;
uint32 const BONK_LAST_TABARD_ENTRY = 939007;
uint8 const BONK_TRANSMOG_SLOTS = 19;
uint32 const BONK_HIDDEN_LOOK = 1;
uint8 const BONK_OUTFITS = 5;
size_t const BONK_OUTFIT_NAME_MAX = 24;

class BonkTransmogStore
{
    public:
        void LoadAccount(uint32 accountId);
        void LoadCharacter(uint32 characterGuid);
        void ForgetCharacter(uint32 characterGuid);

        void Collect(Player* player, uint32 entry, bool announce = true);
        void CollectOwned(Player* player);
        bool IsNewLook(Player const* player, uint32 entry) const;
        bool IsCollected(uint32 accountId, uint32 entry) const;
        uint32 GetVisibleEntry(Player const* player, uint8 slot, Item const* item) const;

        bool Apply(Player* player, uint8 slot, uint32 entry, std::string& error);
        void Clear(Player* player, uint8 slot);
        void SaveOutfit(Player* player, uint8 outfit, std::string const& name);
        void ApplyOutfit(Player* player, uint8 outfit, std::string& error);
        void DeleteOutfit(Player* player, uint8 outfit);
        void SendWindow(Player* player) const;
        static std::string DescribeSource(BonkPlayer const* bonk, std::string const& source);
        static std::string CleanOutfitName(std::string const& name);
        void SendOutfits(Player* player) const;

    private:
        mutable std::mutex m_lock;
        std::unordered_map<uint32, std::set<uint32>> m_collections;
        std::unordered_map<uint32, std::set<uint32>> m_looks;
        std::unordered_map<uint32, std::array<uint32, BONK_TRANSMOG_SLOTS>> m_choices;

        uint32 GetChoice(uint32 characterGuid, uint8 slot) const;
        void SetChoice(uint32 characterGuid, uint8 slot, uint32 entry);
        void RefreshSlot(Player* player, uint8 slot);
};

#define sBonkTransmog MaNGOS::Singleton<BonkTransmogStore>::Instance()

namespace BonkTransmog
{
    uint8 GetLookGroup(ItemPrototype const* proto);
    bool IsTransmogSlot(uint8 slot);
    bool CanHide(uint8 slot);
    bool Fits(ItemPrototype const* look, ItemPrototype const* worn);
    void UnlockAppearance(Player* player, uint32 entry);
    void RollTabardDrops(Player* player, std::string const& zoneKey);
}

#endif

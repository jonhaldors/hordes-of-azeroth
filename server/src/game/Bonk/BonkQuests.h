#ifndef MANGOS_BONKQUESTS_H
#define MANGOS_BONKQUESTS_H

#include "Common.h"
#include "BonkMgr.h"
#include "Policies/Singleton.h"

#include <functional>
#include <map>
#include <set>
#include <mutex>
#include <string>
#include <vector>

class Player;

enum BonkQuestType : uint8
{
    BONK_QUEST_KILLS          = 0,
    BONK_QUEST_KILL_KIND      = 1,
    BONK_QUEST_KILL_WEAPON    = 2,
    BONK_QUEST_CLEAR_LEVEL    = 3,
    BONK_QUEST_REACH_LEVEL    = 4,
    BONK_QUEST_SHARDS         = 5,
    BONK_QUEST_CRITS          = 6,
    BONK_QUEST_HEALED         = 7,
    BONK_QUEST_KILL_TYPE      = 8,
    BONK_QUEST_LEY_LINES      = 9,
    BONK_QUEST_GREED_CLEAR    = 10,
    BONK_QUEST_CLEAR_CLASSES  = 11,
    BONK_QUEST_BOSS_BEFORE    = 12,
    BONK_QUEST_DISCOVER       = 13,
    BONK_QUEST_SHRINE_TYPES   = 14,
    BONK_QUEST_HEIRLOOMS      = 15,
    BONK_QUEST_MASTERY_LEVEL  = 16,
    BONK_QUEST_QUESTS_DONE    = 17,
    BONK_QUEST_KILL_SCHOOL    = 18,
    BONK_QUEST_KILLS_STANDING = 19,
    BONK_QUEST_PASSIVE_RANK   = 20,
    BONK_QUEST_SPELL_RANK     = 21,
    BONK_QUEST_MAX_HEALTH     = 22,
    BONK_QUEST_BOSS_FAST      = 23,
    BONK_QUEST_BOSS_UNHURT    = 24,
    BONK_QUEST_BOSS_LOW_HEALTH = 25,
    BONK_QUEST_UNHURT_TIME    = 26,
    BONK_QUEST_OVERTIME       = 27,
    BONK_QUEST_LEECH_HEALED   = 28,
    BONK_QUEST_DODGES         = 29,
    BONK_QUEST_ARMOR_ABSORBED = 30,
    BONK_QUEST_CHESTS_BOUGHT  = 31,
    BONK_QUEST_VENDOR_BOUGHT  = 32,
    BONK_QUEST_MINI_EVENTS    = 33,
    BONK_QUEST_KILL_CREATURE  = 34,
    BONK_QUEST_DARK_FORTUNES  = 35,
    BONK_QUEST_PROJECTILES    = 36,
    BONK_QUEST_DEATHS         = 37,
    BONK_QUEST_DOT_KILLS      = 38,
    BONK_QUEST_DASHES         = 39,
    BONK_QUEST_VETERAN        = 40,
    BONK_QUEST_CLEAR_DUNGEON  = 41,
    MAX_BONK_QUEST_TYPE
};

enum BonkQuestReward : uint8
{
    BONK_REWARD_GOLD      = 0,
    BONK_REWARD_SHARDS    = 1,
    BONK_REWARD_WEAPON    = 2,
    BONK_REWARD_PASSIVE   = 3,
    BONK_REWARD_TALENT    = 4,
    BONK_REWARD_UPGRADE   = 5,
    BONK_REWARD_MASTERY   = 6,
    BONK_REWARD_CLASS     = 7,
    BONK_REWARD_EPIC_RANK = 8,
    BONK_REWARD_CAPSTONE  = 9,
    BONK_REWARD_TITLE     = 10,
    BONK_REWARD_CARD      = 11,
    BONK_REWARD_GLYPH     = 12,
    BONK_REWARD_CARD_BAN  = 13,
    BONK_REWARD_GLYPH_BAN = 14,
    BONK_REWARD_APPEARANCE = 15,
    MAX_BONK_REWARD
};

enum BonkQuestCategory : uint8
{
    BONK_QUEST_SLAYER     = 0,
    BONK_QUEST_VICTORY    = 1,
    BONK_QUEST_MASTERY    = 2,
    BONK_QUEST_CHALLENGE  = 3,
    BONK_QUEST_DISCOVERY  = 4,
    BONK_QUEST_COLLECTION = 5,
    MAX_BONK_QUEST_CATEGORY
};

struct BonkQuest
{
    uint32 id = 0;
    std::string name;
    std::string description;
    std::string icon;
    BonkQuestType type = BONK_QUEST_KILLS;
    uint32 target = 0;
    uint32 param = 0;
    uint32 amount = 1;
    BonkQuestReward rewardType = BONK_REWARD_GOLD;
    uint32 rewardValue = 0;
    uint8 classId = 0;
    BonkQuestCategory category = BONK_QUEST_SLAYER;

    bool CountsBits() const { return type == BONK_QUEST_CLEAR_CLASSES || type == BONK_QUEST_SHRINE_TYPES; }
};

struct BonkTitle
{
    uint32 id = 0;
    std::string name;
    std::string pattern;
    uint8 classId = 0;
    uint8 stat = 0;
    float value = 0.0f;
};

class BonkQuests
{
    public:
        void Load();

        void OnLogin(Player* player);
        void Save(uint32 account);

        bool IsLocked(uint32 account, BonkQuestReward type, uint32 id) const;
        bool IsDisabled(uint32 account, BonkQuestReward type, uint32 id) const;
        bool IsInPool(uint32 account, BonkQuestReward type, uint32 id) const { return !IsLocked(account, type, id) && !IsDisabled(account, type, id); }
        static bool IsHiddenUntilDone(BonkQuest const& quest) { return quest.type == BONK_QUEST_VETERAN; }
        static bool IsTogglable(BonkQuestReward type) { return type == BONK_REWARD_CARD || type == BONK_REWARD_GLYPH; }
        bool SetDisabled(uint32 account, BonkQuestReward type, uint32 id, bool disabled, uint32 slots, std::string& error,
            LocaleConstant locale = LOCALE_enUS);
        void TrimDisabled(uint32 account, BonkQuestReward type, uint32 slots);
        std::vector<std::pair<BonkQuestReward, uint32>> GetDisabled(uint32 account) const;
        uint32 CountDisabled(uint32 account, BonkQuestReward type) const;
        BonkQuest const* GetUnlockingQuest(BonkQuestReward type, uint32 id) const;
        std::vector<BonkQuest const*> GetRewardQuests(BonkQuestReward type) const;
        bool IsCompleted(uint32 account, uint32 questId) const;
        uint32 GetProgress(uint32 account, BonkQuest const& quest) const;
        uint32 GetCompletedCount(uint32 account) const { return CountCompleted(account); }
        std::map<uint32, std::pair<uint32, bool>> GetAllProgress(uint32 account) const;
        BonkQuest const* FindQuest(uint32 id) const
        {
            auto itr = m_quests.find(id);
            return itr != m_quests.end() ? &itr->second : nullptr;
        }

        void OnKill(Player* player, BonkSpawnKind kind, uint32 killingSpell, uint32 creatureType, uint32 entry, bool standing);
        void OnBossFight(Player* player, BonkSpawnKind kind, uint32 seconds, bool unhurt, uint32 healthPercent);
        void OnLevelCleared(Player* player, uint32 classLevel, uint32 accountLevel);
        void OnDungeonCleared(Player* player, uint32 mapId);
        void OnBossKilled(Player* player, uint32 tierId, uint32 stage, uint32 second);
        void OnShards(Player* player, uint32 count);
        void OnProgress(Player* player, BonkQuestType type, uint32 target, uint32 value, bool absolute = false);

        uint32 GetMasteryPoints(uint32 account, uint8 classId) const;
        BonkTitle const* GetTitle(uint32 id) const;
        std::vector<BonkTitle const*> GetEarnedTitles(uint32 account) const;
        bool HasTitle(uint32 account, uint32 titleId) const;

        void SendLog(Player* player, std::string const& npc);
        std::vector<std::string> DescribeAll(Player* player) const;

        static char const* GetCategoryKey(BonkQuestCategory category);

    private:
        struct Progress
        {
            uint32 value = 0;
            bool completed = false;
            bool dirty = false;
        };
        typedef std::map<uint32, Progress> AccountProgress;

        void Track(Player* player, std::function<void(BonkQuest const&, AccountProgress&)> const& step);
        void Advance(Player* player, AccountProgress& progress, BonkQuest const& quest, uint32 value, bool absolute);
        void AdvanceBit(AccountProgress& progress, BonkQuest const& quest, uint32 bit);
        void Complete(Player* player, BonkQuest const& quest);
        uint32 CountCompleted(uint32 account) const;
        static bool Counts(Player const* player, BonkQuest const& quest);
        static uint32 GetShownProgress(BonkQuest const& quest, Progress const& entry);
        std::string DescribeReward(BonkQuest const& quest, std::string* icon, LocaleConstant locale = LOCALE_enUS) const;
        uint32 GetRootWeapon(uint32 spellId, uint32 classMask) const;

        std::map<uint32, BonkQuest> m_quests;
        std::map<uint32, BonkTitle> m_titles;

        static uint64 UnlockKey(BonkQuestReward type, uint32 id) { return (uint64(type) << 32) | id; }

        mutable std::mutex m_lock;
        std::map<uint32, AccountProgress> m_accounts;
        std::map<uint32, std::set<uint64>> m_disabled;
};

#define sBonkQuests MaNGOS::Singleton<BonkQuests>::Instance()

#endif

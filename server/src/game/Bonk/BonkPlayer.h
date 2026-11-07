#ifndef MANGOS_BONKPLAYER_H
#define MANGOS_BONKPLAYER_H

#include "BonkTelegraph.h"
#include "Common.h"
#include "ObjectGuid.h"
#include "SharedDefines.h"

struct BonkTitle;

#include <algorithm>
#include <array>
#include <atomic>
#include <map>
#include <memory>
#include <set>
#include <string>
#include <vector>

class BonkRun;
class Creature;
class GameObject;
class Player;
class WorldObject;
struct ItemPrototype;
enum BonkShop : uint8;
enum BonkQuestReward : uint8;
enum BonkUpgradeUtility : uint8;
enum BonkString : uint32;
enum BonkTextField : uint8;

struct BonkMap;
struct BonkMasteryBonuses;
struct BonkMasteryNode;
struct BonkRunBonuses;
struct BonkRunChoice;
struct BonkTalent;
struct BonkTier;
struct BonkWeapon;

uint32 const BONK_PLAYER_FACTION = 1;

class BonkPlayer
{
    public:
        explicit BonkPlayer(Player* player);
        ~BonkPlayer();

        void OnLogin();
        void OnLogout();
        void OnSave();
        void Update(uint32 diff);

        BonkRun* GetRun() const { return m_run.get(); }
        float GetLeashFactor() const { return m_leashFactor; }
        void SetLeashFactor(float factor) { m_leashFactor = factor; }
        uint32 GetOtherEffects() const { return m_otherEffects; }
        void SetOtherEffects(uint32 percent) { m_otherEffects = std::min(percent, 100u); }
        void SetReachRing(uint32 rootId, uint32 style, bool filled, uint32 opacity);
        void ChooseReachRingSlot(uint32 slot);
        void SetReachRingPreview(bool previewing);
        void ForgetShownReachRing();
        float GetLeashDistance() const { return m_leashDistance; }
        void SetLeashDistance(float distance) { m_leashDistance = distance; }
        float GetRunDodge() const;
        time_t GetSkyTime() const;
        void PreviewTelegraph(BonkTelegraphShape shape, float x, float y, float z, float orientation, float size, uint32 durationMs);
        bool StartRun(BonkTier const& tier, std::string& error);
        bool StartRun(BonkTier const& tier, std::string& error, BonkRunChoice const& choice);
        bool StartGuestRun(BonkTier const& tier, BonkRunChoice const& choice, Player* host, std::string& error);
        void SendMapInfo() const;
        bool StartSandbox(std::string& error);
        bool IsInSandbox() const;
        void StopRun();

        uint32 GetBestLevel() const;
        uint32 GetAccountBestLevel() const;
        uint32 GetCarriedLevel() const;
        uint32 GetClearedLevel() const;
        uint32 GetOpenLevel(BonkTier const& tier) const;
        uint32 GetTierBest(BonkTier const& tier) const;
        static uint32 GetTierBand(BonkTier const& tier, uint32 level);
        bool IsLevelOpen(uint32 level) const;
        std::string GetLevelName(uint32 level) const;
        bool IsTierUnlocked(BonkTier const& tier) const;
        bool IsTierCleared(BonkTier const& tier) const;
        bool IsTierCleared(char const* tierKey) const;
        bool RecordLevelClear(uint32 level, uint32 clearMs);
        void RecordFinale(uint32 score);
        struct LevelRun
        {
            uint32 level = 0;
            uint32 ms = 0;
            uint32 kills = 0;
            uint64 damage = 0;
            uint32 gold = 0;
            uint32 valor = 0;
            std::string name;
        };
        struct LevelBest
        {
            uint32 clears = 0;
            uint32 firstClear = 0;
            uint32 bestMs = 0;
            std::string bestMsBy;
            uint32 damagePerSecond = 0;
            std::string damageBy;
            uint32 kills = 0;
            std::string killsBy;
            uint32 goldPerMinute = 0;
            std::string goldBy;
            uint32 valorPerMinute = 0;
            std::string valorBy;
            uint32 finale = 0;
            uint32 finaleSeconds = 0;
        };
        static void MergeLevelBest(LevelBest& best, LevelRun const& run);
        static bool MergeFinaleBest(LevelBest& best, uint32 score, uint32 seconds);
        static LevelBest LoadLevelBest(uint32 account, uint8 classId, uint32 level);
        static void SaveLevelBest(uint32 account, uint8 classId, uint32 level, LevelBest const& best);
        static void ApplyLevelBest(uint32 account, uint8 classId, LevelRun const& run);
        static void ApplyFinaleBest(uint32 account, uint8 classId, uint32 level, uint32 score, uint32 seconds);
        void RecordLevelBest(LevelRun const& run);
        void RecordFinaleBest(uint32 level, uint32 score, uint32 seconds);
        uint8 GetTrainingRankCap() const;
        std::string GetTrainingCapHint() const;
        uint8 GetDetermination() const;
        void AddDetermination();
        void SendDetermination() const;
        void SendDeterminationText() const;
        void RefreshDeterminationAura() const;
        bool IsShopVendor(Creature const* vendor) const;
        uint32 GetStockTier() const;
        std::vector<uint32> GetShopStock() const;
        static uint32 GetShopFirstTier(uint8 quality);
        uint32 GetScrap() const { return m_scrap; }
        uint8 GetDeterminationStacks() const { return m_determination; }
        bool IsGoldLoaded() const { return m_goldLoaded; }
        void GetRunRecord(uint32& runs, uint32& bestLevel, uint32& bestSeconds, uint32& kills, uint32& goldEarned) const
        {
            runs = m_record.runs;
            bestLevel = m_record.bestLevel;
            bestSeconds = m_record.bestSeconds;
            kills = m_record.kills;
            goldEarned = m_record.goldEarned;
        }
        void AddScrap(uint32 points);
        void SendQuartermaster() const;
        uint32 GetUpgradeCeiling() const;
        std::vector<Item*> GetUpgradableGear() const;
        void SendFoundUpgrades() const;
        bool UpgradeFoundGear(uint32 guidLow, std::string& error);
        bool RerollFoundGear(uint32 guidLow, uint8 lineIndex, std::string& error);
        bool PickFoundReroll(uint32 guidLow, uint8 choice, std::string& error);
        void SendFoundItems() const;
        bool GiveTestFoundGear(uint32 tier, uint32 lineCount, std::string& error);
        std::string GetUnlockHint(BonkTier const& tier) const;

        static bool IsWipeName(std::string const& name);
        static bool IsPlayableClass(uint8 classId);
        static void WipeAccount(uint32 accountId, std::string const& username);

        static bool IsIronmanName(std::string const& name);
        static void RequestIronman(uint32 accountId);
        static bool TakeIronmanRequest(uint32 accountId);
        static void MarkIronman(uint32 guidLow);
        static void DeleteIronmanProgress(uint32 guidLow);
        static uint32 GetIronmanAccount(uint32 guidLow);
        static void GatherAccountBank(uint32 accountId, uint32 guidLow);
        static void ParkAccountBank(uint32 guidLow);
        static bool IsHardcoreName(std::string const& name);
        static void RequestHardcore(uint32 accountId);
        static bool TakeHardcoreRequest(uint32 accountId);
        static void MarkHardcore(uint32 guidLow);
        static bool IsHardcoreCharacter(uint32 guidLow);
        static uint32 GetHardcoreAccount(uint32 accountId);
        static uint32 GetProgressAccountOf(uint32 guidLow, uint32 accountId);
        static void ParkFallenBanks(uint32 accountId);
        static uint32 GetCharacterAccountOf(uint32 guidLow);
        static uint32 GetPlainCharacterAccount(uint32 guidLow);
        static uint32 GetStagedCharacterAccount(uint32 accountId);
        void ClaimStagedCharacterRows();
        static void AdoptClassProgress(uint32 guidLow);
        static void DeleteCharacterProgress(uint32 guidLow);
        static void RaisePoolBestLevel(uint32 poolAccount, uint32 level);
        uint32 GetCharacterAccount() const;
        bool IsIronman() const;
        bool IsHardcore() const;
        bool HasFallenInHardcore() const { return m_fellInHardcore; }
        void OnHardcoreDeath(std::string const& killer, std::string const& mapName, uint32 level, uint32 kills);
        uint32 BeginHardcoreRun(std::string const& mapName);
        void EndHardcoreRun();
        uint32 GetHardcoreRun() const { return m_hardcoreRun; }
        uint32 GetHardcoreCrashes() const { return m_hardcoreCrashes; }
        bool HoldsAfterDisconnect() const;
        void OnHardcoreDisconnected();
        void OnHardcoreReconnected();
        void SendUnannouncedFall();
        static uint32 HardcoreHoldMs();
        static uint32 HardcoreShutdownHoldSeconds();
        static uint32 OpenHardcoreRuns();
        bool RequestRest();
        static bool TakeRestRequest(uint32 guidLow);
        uint32 GetProgressAccount() const;

        void RecordRun(uint32 level, uint32 seconds, uint32 kills, uint32 goldEarned);

        struct StarterOption
        {
            BonkWeapon const* weapon = nullptr;
            bool unlocked = false;
            std::string hint;
        };
        std::vector<StarterOption> GetStarterOptions() const;
        BonkWeapon const* GetStarterWeapon() const;
        bool ChooseStarter(uint32 weaponId, std::string& error);
        void SendStarters() const;

        uint32 GetShards() const { return m_shards; }
        void AddShards(uint32 count);
        uint8 GetUpgradeRank(uint32 upgradeId) const;
        float GetUpgradeUtility(BonkUpgradeUtility utility) const;
        uint8 GetTalentRank(uint32 talentId) const;
        uint32 GetFortuneSpentAbove(uint8 row, uint32 refundedId = 0) const;
        uint32 GetFortuneSpent(uint32 tree) const;
        bool IsTalentEnabled(uint32 talentId) const { return m_enabledTalents.count(talentId) != 0; }
        bool BuyUpgrade(uint32 upgradeId, std::string& message);
        bool BuyTalent(uint32 talentId, std::string& message);
        bool ResetUpgrades(std::string& message);
        bool ResetTalents(std::string& message);
        bool RefundUpgrade(uint32 upgradeId, std::string& message);
        bool RefundTalent(uint32 talentId, std::string& message);
        bool ToggleTalent(uint32 talentId, std::string& message);
        BonkRunBonuses GetRunBonuses() const;
        BonkPlayer const* GetFortuneOwner() const;
        bool RefusesGuestFortune(BonkTalent const& talent, std::string& message) const;
        void AddTalentBonuses(BonkRunBonuses& bonuses, bool fortunes) const;

        uint32 GetMasteryXp() const { return m_masteryXp; }
        uint32 GetMasteryLevel() const;
        uint32 GetMasteryPoints() const;
        BonkMasteryNode const* FindLearnedRival(BonkMasteryNode const& node) const;
        bool HasLearnedParent(BonkMasteryNode const& node, uint32 ignoredId) const;
        uint32 GetMasterySpentAbove(uint32 treeId, uint8 row) const;
        uint32 GetLevelTalentPoints() const;
        uint32 GetEpicLuckBonus() const;
        int32 GetBoardChoice() const { return m_boardChoice; }
        uint32 GetBoardClimb() const;
        void SetBoardChoice(bool show);
        void SendBoardChoice() const;
        struct OffBoardGear
        {
            Item const* item = nullptr;
            bool legacy = false;
        };
        bool HasBoardGear(uint32 level) const;
        OffBoardGear FindOffBoardGear(uint32 level) const;
        bool IsBoardGameMaster() const;
        void CountEpicLuck(bool epicDropped);
        void SendEpicLuck() const;
        void TakeTalentResetNotice();
        uint32 GetMasterySpent() const;
        std::string DescribeLoadout() const;
        std::string DescribeGear() const;
        std::string DescribeFoundGear() const;
        uint32 GetMasterySpentInTree(uint32 treeId) const;
        uint8 GetMasteryRank(uint32 nodeId) const;
        void AddMasteryXp(uint32 xp);
        bool LearnMastery(uint32 nodeId, std::string& message);
        bool ResetMastery(std::string& message);
        void FlushMasteryNotice();
        bool RefundMastery(uint32 nodeId, std::string& message);
        bool LoadMasteryPreset(uint8 slot, std::string& message);
        BonkMasteryBonuses GetMasteryBonuses() const;
        std::map<uint32, uint8> const& GetMasteryRanks() const { return m_masteryRanks; }
        void SendMasteryState() const;
        void SendTitles() const;
        bool SetTitle(uint32 titleId, std::string& error);
        BonkTitle const* GetActiveTitle() const;
        bool CanSeeTownObject(uint32 entry, bool gameObject) const;
        void SendWallet() const;

        void OpenShop(BonkShop shop, Creature const* npc);
        bool IsVisitingShop(BonkShop shop) const { return m_shop == shop && IsAtShop(); }
        void ShopLearn(uint32 id);
        void ShopUnlearn(uint32 id);
        void ShopToggle(uint32 id);
        void ShopPreset(uint8 slot);
        void ShopRespec();

        void SetFiringWeapon(bool firing) { m_firingWeapon = firing; }
        bool IsFiringWeapon() const { return m_firingWeapon; }
        void SetEquippingGear(bool equipping) { m_equippingGear = equipping; }
        bool IsEquippingGear() const { return m_equippingGear; }
        bool CanSwapGearInCombat() const;
        bool StowTwoHander();
        bool IsSlotUnusedByClass(uint8 slot) const;
        struct SpellTweak
        {
            float areaScale = 1.0f;
            uint32 chainBonus = 0;
            float jumpRadius = CHAIN_SPELL_JUMP_RADIUS;
            uint32 durationMs = 0;
            float durationScale = 1.0f;
            int32 weaponDamage = 0;
            uint32 tickMs = 0;
            float tickScale = 1.0f;
            bool normalEnemiesOnly = false;
            bool oneTargetPerCast = false;
        };
        SpellTweak& TweakSpell(uint32 spellId) { return m_spellTweaks[spellId]; }
        void ClearSpellTweaks() { m_spellTweaks.clear(); }
        float GetAreaScale(uint32 spellId) const
        {
            SpellTweak const* tweak = FindSpellTweak(spellId);
            return tweak ? tweak->areaScale : 1.0f;
        }
        uint32 GetChainBonus(uint32 spellId) const
        {
            SpellTweak const* tweak = FindSpellTweak(spellId);
            return tweak ? tweak->chainBonus : 0;
        }
        float GetChainJumpRadius(uint32 spellId) const
        {
            SpellTweak const* tweak = FindSpellTweak(spellId);
            return tweak ? tweak->jumpRadius : CHAIN_SPELL_JUMP_RADIUS;
        }
        bool StrikesOneTargetPerCast(uint32 spellId) const
        {
            SpellTweak const* tweak = FindSpellTweak(spellId);
            return tweak && tweak->oneTargetPerCast;
        }
        bool HoldsNormalEnemiesOnly(uint32 spellId) const
        {
            SpellTweak const* tweak = FindSpellTweak(spellId);
            return tweak && tweak->normalEnemiesOnly;
        }
        int32 AdjustDuration(uint32 spellId, int32 duration) const
        {
            SpellTweak const* tweak = FindSpellTweak(spellId);
            if (!tweak || duration <= 0)
                return duration;
            return int32((tweak->durationMs ? tweak->durationMs : duration) * tweak->durationScale);
        }
        uint32 GetTickInterval(uint32 spellId, uint32 amplitude) const
        {
            SpellTweak const* tweak = FindSpellTweak(spellId);
            if (!tweak)
                return 0;
            uint32 const tick = tweak->tickMs ? tweak->tickMs : amplitude;
            return std::max(100u, uint32(tick * tweak->tickScale));
        }
        int32 GetWeaponDamage(uint32 spellId) const
        {
            SpellTweak const* tweak = FindSpellTweak(spellId);
            return tweak ? tweak->weaponDamage : 0;
        }

        void SetTestGod(bool on) { m_testGod = on; }
        bool IsTestGod() const { return m_testGod; }

        void SetAddonReady();
        void SendProtocolHello() const;
        void SendAuraCatalog() const;
        void SendAuraValue(uint32 spellId, uint32 value, uint32 maxValue) const;
        void SendAuraText(uint32 spellId, std::string const& text) const;
        void SendAuraPercent(uint32 spellId, float percent) const;
        bool IsAddonReady() const { return m_addonReady; }
        Player* GetPlayer() const { return m_player; }
        void SetLocale(LocaleConstant locale);
        void ApplyLocale(LocaleConstant locale);
        LocaleConstant GetLocale() const { return m_locale; }
        std::string GetString(BonkString id, std::vector<std::string> const& args = {}) const;
        std::string Localize(BonkTextField field, uint32 id, std::string const& english) const;
        std::string JoinList(std::vector<std::string> const& items, BonkString last) const;
        std::string GetLocalName(WorldObject const* object) const;
        void SendNpcName(WorldObject const* npc) const;
        void RefreshCreatureNames() const;
        std::string GetItemName(ItemPrototype const* proto) const;
        std::string GetCreatureName(uint32 entry, std::string const& fallback) const;

        void Notify(std::string const& text) const;
        void ResetReworkedTrinkets();
        void NotifyFind(std::string const& text) const;
        void Notify(BonkString id, std::vector<std::string> const& args = {}) const { Notify(GetString(id, args)); }
        void NotifyFind(BonkString id, std::vector<std::string> const& args = {}) const { NotifyFind(GetString(id, args)); }
        void SendGlyphInfo() const;
        struct BanSource
        {
            std::string label;
            std::string detail;
            bool earned = false;
            uint32 tickets = 0;
        };
        std::vector<BanSource> GetBanSources(BonkQuestReward type) const;
        uint32 GetBanSlots(BonkQuestReward type) const;
        bool BuyBanSlot(BonkQuestReward type, std::string& message);
        void VisitDeck(GameObject const* table);
        bool IsAtDeck() const;
        void TrimPoolToggles() const;

        bool Dash();
        bool IsDashInvulnerable() const { return m_dashClockMs < m_dashInvulnerableUntilMs; }
        float GetDashBurstSpeed() const { return m_dashBursting ? GetDashSpeed() : 0.0f; }
        bool GetDashRunTravel(uint32 fromMs, uint32 toMs, float& travel) const;
        void SendDash() const;
        uint32 GetDashCooldownMs() const;
        void SendTierList() const;
        void SendGearInfo() const;
        void SendUpdateNotices();
        void SeeGearNotice();
        void SendStats() const;
        void SendNoEnchants() const;
        void SendMasteryShop(bool open, bool inspect) const;
        std::map<uint32, uint8> ReadMasteryPreset(uint8 slot) const;
        void LoadMasteryPresets();
        void WriteMasteryPreset(uint8 slot, std::map<uint32, uint8> const& ranks);
        void SendMasteryPresetRanks() const;
        void SendStatTotals(float const* totals, bool inRun, float const* afterCaps = nullptr) const;
        void WatchStats(bool watching);
        bool IsWatchingStats() const { return m_watchingStats; }
        void OpenArena(Creature const* npc) const;

        void ResetCharacter();
        bool IsAtCamp() const;
        static bool IsHiddenFrom(Creature const* creature, Player const* viewer);
        void TeleportToCamp();
        WorldLocation const& GetCampArrival() const;
        void AnnounceMailAtCamp() { m_campMailNoticeMs = BONK_CAMP_MAIL_NOTICE_DELAY_MS; }
        bool MoveToCampBeforeLogin(bool gameMaster);

        struct PacketCounts
        {
            uint32 packets = 0;
            uint32 bytes = 0;
            std::vector<std::pair<uint16, uint32>> top;
        };
        void NotePacket(uint16 opcode, size_t bytes);
        PacketCounts TakePacketCounts();

    private:
        Item* FindUpgradableGear(uint32 guidLow) const;
        void DiscardFoundReroll();
        void ClearAuras();

        struct Record
        {
            uint32 runs = 0;
            uint32 bestLevel = 0;
            uint32 bestSeconds = 0;
            uint32 kills = 0;
            uint32 goldEarned = 0;
        };

        void WriteHeroScreenStats() const;
        static void WriteHeroScreenFile(std::string const& username, std::string const& stats);

        void LoadPurchases();
        void LoadMastery();
        void ReconcileMastery();
        void LoadStarter();
        void GiveStarterBags();
        void ClearInterruptedRunItems();
        void GiveBankBag(uint8 slot);
        void TeachWeaponSkills();
        std::string GetClassName() const;
        bool Spend(uint32 copper, std::string& message);
        bool SpendShards(uint32 count, std::string& message);
        void SaveGold() const;
        void SaveShards() const;
        void SaveTalent(uint32 talentId) const;

        void SendShop(bool open) const;
        void SendShopClose() const;
        void SendArena(std::string const& npc) const;
        void SendLevelPreview(BonkTier const& tier, BonkRunBonuses const& bonuses) const;
        bool IsAtShop() const;

        Player* m_player;
        std::unique_ptr<BonkRun> m_run;
        BonkTelegraphs m_previewTelegraphs;
        bool m_addonReady = false;
        bool m_watchingStats = false;
        float m_leashFactor = 1.0f;
        uint32 m_otherEffects = 100;
        struct ReachRingLook
        {
            uint32 steps = 0;
            uint32 style = 0;
            bool filled = false;
            uint32 opacity = 0;
            bool operator==(ReachRingLook const& other) const
            {
                return steps == other.steps && style == other.style && filled == other.filled && opacity == other.opacity;
            }
        };
        uint32 m_reachRingRoot = 0;
        ReachRingLook m_reachRingChosen;
        ReachRingLook m_reachRingShown;
        uint32 m_reachRingSlotSent = 0;
        bool m_reachRingPreview = false;
        int32 m_reachRingRefreshMs = 0;
        void UpdateReachRing(uint32 diff);
        void RefreshReachRing();
        void SendReachRingSlot();
        float m_leashDistance = 0.0f;
        bool m_gearNoticePending = false;
        LocaleConstant m_locale = LOCALE_enUS;
        mutable bool m_zoneArtSent = false;
        void SendZoneArt() const;
        bool m_firingWeapon = false;
        bool m_equippingGear = false;
        std::map<uint32, SpellTweak> m_spellTweaks;
        SpellTweak const* FindSpellTweak(uint32 spellId) const
        {
            auto itr = m_spellTweaks.find(spellId);
            return itr != m_spellTweaks.end() ? &itr->second : nullptr;
        }
        bool m_testGod = false;
        bool m_campCheckPending = false;
        uint32 m_sitAtCampMs = 0;
        void UpdateCampSeat(uint32 diff);
        uint32 m_deadOutsideRunMs = 0;
        void UpdateReviveOutsideRun(uint32 diff);
        void SitAtCamp();
        uint32 m_mailboxRefreshMs = 0;
        void UpdateMailboxRefresh(uint32 diff);
        void RefreshMailboxBeacon();
        static constexpr uint32 BONK_CAMP_MAIL_NOTICE_DELAY_MS = 1500;
        uint32 m_campMailNoticeMs = 0;
        void UpdateCampMailNotice(uint32 diff);
        uint32 m_mailboxGlowMs = 0;
        bool m_mailboxGlowShown = false;
        static uint16 const PACKET_KINDS = 1024;
        std::array<std::atomic<uint32>, PACKET_KINDS> m_packetCounts{};
        std::atomic<uint32> m_packetBytes{ 0 };
        bool HasUnreadMail() const;
        void UpdateMailboxGlow(uint32 diff);
        bool m_goldLoaded = false;
        mutable int8 m_ironman = -1;
        mutable int8 m_hardcore = -1;
        uint32 m_poolBestLevel = 0;
        bool m_fellInHardcore = false;
        bool m_mayRest = false;
        uint32 m_hardcoreRun = 0;
        uint32 m_hardcoreCrashes = 0;
        bool UsesHardcorePool() const;
        void SettleLeftHardcoreRun();
        void SendFallenRecord(uint32 level, uint32 bestLevel, uint32 mastery, uint32 played, uint32 runs, uint32 kills, std::string const& killer,
            std::string const& mapName, bool ironman);
        struct LevelRecord
        {
            uint32 best = 0;
            uint32 bestMs = 0;
            uint32 finale = 0;
        };
        std::map<uint8, LevelRecord> m_levels;
        std::map<std::pair<uint8, uint32>, LevelBest> m_levelBests;
        std::map<uint8, uint32> m_keptTalentPoints;
        uint32 m_epicLuckMisses = 0;
        int32 m_boardChoice = -1;
        std::set<uint32> m_sessionClears;
        void LoadLevelBests(uint32 accountId);
        Record m_record;
        std::map<uint32, uint8> m_upgradeRanks;
        std::map<uint32, uint8> m_talentRanks;
        std::set<uint32> m_enabledTalents;
        uint32 m_shards = 0;
        uint8 m_determination = 0;
        uint32 m_scrap = 0;
        uint32 m_rerollItem = 0;
        uint8 m_rerollLine = 0;
        std::vector<std::pair<uint8, float>> m_rerollOffers;
        uint32 m_masteryXp = 0;
        uint32 m_titleId = 0;
        bool m_accountHasRun = false;
        std::map<uint32, uint8> m_masteryRanks;
        std::map<uint8, std::map<uint32, uint8>> m_masteryPresets;
        uint8 m_activeMasteryPreset = 1;
        uint32 m_starterChoice = 0;
        BonkShop m_shop{};
        ObjectGuid m_shopNpc;
        ObjectGuid m_deckTable;
        std::string m_shopNpcName;
        std::string m_masteryNotice;

        float GetDashDistance() const;
        uint32 GetDashMaxCharges() const;
        float GetDashSpeed() const;
        bool IsDashPaused() const;
        void UpdateDash(uint32 diff);
        void SetDashBurst(bool on);
        void ThrowHero(float angle, float speed);
        void BlinkHero(bool backfire);
        void TrackDashRun();
        float GetMoveAngle() const;
        uint32 m_dashClockMs = 0;
        uint32 m_dashSpent = 0;
        uint32 m_dashRechargeMs = 0;
        uint32 m_dashRechargeUntilMs = 0;
        uint32 m_dashInvulnerableUntilMs = 0;
        uint32 m_dashBurstUntilMs = 0;
        uint32 m_dashRunStartedAtMs = 0;
        float m_dashRunBaseSpeed = 0.0f;
        bool m_dashRunTracked = false;
        bool m_dashBursting = false;
};

struct FiringWeapon
{
    explicit FiringWeapon(BonkPlayer* bonk) : m_bonk(bonk), m_wasFiring(bonk->IsFiringWeapon()) { m_bonk->SetFiringWeapon(true); }
    ~FiringWeapon() { m_bonk->SetFiringWeapon(m_wasFiring); }
    BonkPlayer* m_bonk;
    bool m_wasFiring;
};

#endif

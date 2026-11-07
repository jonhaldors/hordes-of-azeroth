#ifndef BONK_COOP_H
#define BONK_COOP_H

#include "BonkPlayer.h"
#include "ObjectGuid.h"
#include "Common.h"

#include <string>
#include <vector>

class Player;
class GameObject;
struct BonkFoundGear;
class WorldObject;
struct BonkMap;
struct BonkTier;
struct BonkRunChoice;

namespace BonkCoop
{
    bool IsGuestAccount(Player const* player);
    uint32 CampSeat(Player const* player);
    void JoinHostGroup(Player* guest);
    void OnUninvited(ObjectGuid guid);
    uint8 GuestLoginRefusal(std::string const& username, uint32 accountId, ObjectGuid character);
    void OnLogout(Player* player);
    bool KeepsAfterDisconnect(Player const* player);
    uint32 RejoinWaitMs();
    void OnDisconnected(Player* player);
    void OnReconnected(Player* player);
    bool IsAway(Player const* player);
    bool IsInCoopGroup(Player const* player);
    bool SkipsEffectPacket(Player const* viewer, WorldObject const* source, uint16 opcode);
    bool HidesEffectObject(Player const* viewer, WorldObject const* object);
    bool IsGroupHost(Player const* player);
    Player* FortuneHostOf(Player const* player);
    bool SharesPause(Player const* player);
    bool SharesXp(Player const* player);
    void SetSharedPause(Player* host, bool shared);
    void SetSharedXp(Player* host, bool shared);
    void DeleteGuestAccounts();
    bool DeleteGuestAccount(std::string const& username);
    void Update(uint32 diff);
    bool RequestGroupStart(Player* host, BonkTier const& tier, BonkRunChoice const& choice);
    void AnswerReady(Player* player, bool ready);
    void UpdateReadyChecks(uint32 diff);
    void UpdateLeash(uint32 diff);
    void OnHostEnteredStage(Player* host, BonkMap const& map, uint32 stage);
    void OnHostFinished(Player* host);
    void OnHostPortal(Player* host, bool last);
    BonkRun* GroupPortalRun(Player* player, GameObject const* portal);
    void RequestNextStage(Player* player);
    void OnHostEndless(Player* host, uint32 stage);
    void NoteHostRun(Player const* host, std::string const& playing);
    void BeginGroupRun(Player* host, uint32 players);
    bool Down(Player* player);
    bool IsDowned(Player const* player);
    uint32 StandingCount(Player* player);
    void WatchNext(Player* player, bool forward);
    void UpdateDowned(uint32 diff);
    void UpdateSharedPause(uint32 diff);
    std::vector<Player*> RunGroupOf(Player* player);
    bool InGroupRun(Player const* player);
    void ShareExperience(Player* collector, float levelFraction);
    void HideObjectFor(ObjectGuid object, ObjectGuid player);
    bool IsObjectHiddenFor(ObjectGuid object, ObjectGuid player);
    void ForgetHiddenObject(ObjectGuid object);
    void ShowOnlyTo(ObjectGuid object, ObjectGuid player);
    void ForgetShownOnly(ObjectGuid object);
    bool IsShownOnlyToOther(ObjectGuid object, ObjectGuid viewer);
    void PlaceGroupVaults(Player* host, GameObject const* portal, float side);
    void ShareEnchanter(Player* host, ObjectGuid enchanter);
    Player* VaultOwner(Player* viewer, GameObject const* vault);
    void Record(Player const* guest, std::string const& entry);
    void UpdateLedger();
    bool IsPlayingElsewhere(std::string const& username);
    void SyncGuest(Player* guest);
    void ForgetGuest(Player const* guest);
    void RecordMail(Player const* guest, uint32 hostItem, uint32 entry, std::string const& subject, std::string const& body, BonkFoundGear const* found);
    void RememberHomeMail(uint32 hostMail, uint32 homeMail);
    void LinkHomeMail(Player const* guest);
    void RememberHomeMailItem(uint32 hostItem, uint32 homeMail, uint32 homeItem);
    void OnMailItemTaken(Player const* guest, uint32 hostMail, uint32 hostItem, uint32 entry);
    void OnMailMoneyTaken(Player const* guest, uint32 hostMail, uint32 money);
    void RecordLevel(Player const* guest, uint32 classId, uint32 bestLevel, uint32 bestMs, uint32 finale);
    void RecordLevelBest(Player const* guest, uint32 classId, BonkPlayer::LevelRun const& run);
    void RecordFinaleBest(Player const* guest, uint32 classId, uint32 level, uint32 score, uint32 seconds);
}

#endif

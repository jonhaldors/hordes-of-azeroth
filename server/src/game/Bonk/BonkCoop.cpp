#include "BonkCoop.h"

#include "AccountMgr.h"
#include "BonkMgr.h"
#include "BonkPlayer.h"
#include "BonkStrings.h"
#include "Chat.h"
#include "Database/DatabaseEnv.h"
#include "DynamicObject.h"
#include "HoaProtocol.h"
#include "Opcodes.h"
#include "Utilities/Random.h"
#include "Group.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "WorldSession.h"

#include <fstream>
#include <map>
#include <mutex>
#include <set>
#include <vector>

namespace
{
    char const* const GUEST_ACCOUNT_PREFIX = "HOAC";
    char const* const GUEST_ACCOUNT_TABLES[] = {
        "bonk_account", "bonk_account_bank", "bonk_account_disabled", "bonk_account_board", "bonk_account_epic_luck", "bonk_account_kept_talents", "bonk_account_level", "bonk_account_level_best", "bonk_account_mastery",
        "bonk_account_mastery_node", "bonk_account_mastery_preset", "bonk_account_mastery_preset_active", "bonk_account_quest",
        "bonk_account_starter", "bonk_account_talent", "bonk_account_unlock", "bonk_account_upgrade",
    };
    char const* const GUEST_CHARACTER_TABLES[] = { "bonk_character_title", "bonk_trinket_reset", "bonk_ironman" };
    uint32 const REMOVE_DELAY_MS = 3000;
    char const* const REMOVED_FILE = "coop/removed.txt";

    std::mutex s_removedLock;
    std::mutex s_seatsLock;
    std::map<ObjectGuid, uint32> s_seats;
    std::set<uint32> s_removedAccounts;

    bool HasGuestPrefix(std::string const& username)
    {
        return username.compare(0, strlen(GUEST_ACCOUNT_PREFIX), GUEST_ACCOUNT_PREFIX) == 0;
    }

    Player* FindHost()
    {
        for (auto const& entry : sObjectAccessor.GetPlayers())
        {
            Player* candidate = entry.second;
            if (candidate && candidate->IsInWorld() && candidate->GetSession() && !HasGuestPrefix(candidate->GetSession()->GetUsername()))
                return candidate;
        }
        return nullptr;
    }

    void NoteRemovedForLauncher(std::string const& username)
    {
        std::ofstream out(REMOVED_FILE, std::ios::binary | std::ios::app);
        out << username << '\n';
    }

    bool WasRemoved(uint32 accountId)
    {
        std::lock_guard<std::mutex> guard(s_removedLock);
        return s_removedAccounts.count(accountId) != 0;
    }

    void SendAway(Player* guest, BonkString reason)
    {
        ChatHandler(guest).SendSysMessage(guest->GetBonkPlayer()->GetString(reason).c_str());
        ObjectGuid const guid = guest->GetObjectGuid();
        guest->m_Events.AddLambdaEventAtOffset([guid]
        {
            if (Player* player = sObjectMgr.GetPlayer(guid))
                player->GetSession()->KickPlayer();
        }, REMOVE_DELAY_MS);
    }

    bool SameClassAllowed()
    {
        std::ifstream marker("coop/same-class.txt", std::ios::binary);
        return marker.good();
    }

    bool ClassTaken(Group const* group, Player const* guest)
    {
        if (SameClassAllowed())
            return false;
        for (Group::MemberSlot const& slot : group->GetMemberSlots())
        {
            if (slot.guid == guest->GetObjectGuid())
                continue;
            if (Player* member = sObjectMgr.GetPlayer(slot.guid))
                if (member->GetClass() == guest->GetClass() && !BonkCoop::IsAway(member))
                    return true;
        }
        return false;
    }
}

bool BonkCoop::IsGuestAccount(Player const* player)
{
    return player && player->GetSession() && HasGuestPrefix(player->GetSession()->GetUsername());
}

uint32 BonkCoop::CampSeat(Player const* player)
{
    if (!IsGuestAccount(player))
        return 0;
    std::lock_guard<std::mutex> guard(s_seatsLock);
    auto found = s_seats.find(player->GetObjectGuid());
    if (found != s_seats.end())
        return found->second;

    std::set<uint32> taken;
    for (auto itr = s_seats.begin(); itr != s_seats.end();)
    {
        if (ObjectAccessor::FindPlayerNotInWorld(itr->first))
        {
            taken.insert(itr->second);
            ++itr;
        }
        else
            itr = s_seats.erase(itr);
    }
    uint32 seat = 1;
    while (seat + 1 < BONK_CAMP_SEAT_COUNT && taken.count(seat))
        ++seat;
    s_seats[player->GetObjectGuid()] = seat;
    return seat;
}

namespace
{
    std::vector<ObjectGuid> MemberGuids(Group const* group)
    {
        std::vector<ObjectGuid> guids;
        for (Group::MemberSlot const& slot : group->GetMemberSlots())
            guids.push_back(slot.guid);
        return guids;
    }

    void RefreshCoopNpc(std::vector<ObjectGuid> const& members)
    {
        for (ObjectGuid const& guid : members)
            if (Player* member = sObjectMgr.GetPlayer(guid))
                if (member->IsInWorld())
                    if (Creature* npc = member->FindNearestCreature(BONK_COOP_NPC, BONK_COOP_NPC_RANGE, true))
                        member->UpdateVisibilityOf(member, npc);
    }
}

namespace
{
    Player const* EffectOwner(WorldObject const* source)
    {
        if (!source)
            return nullptr;
        if (source->GetTypeId() == TYPEID_DYNAMICOBJECT)
        {
            Unit const* caster = static_cast<DynamicObject const*>(source)->GetUnitCaster();
            return caster ? caster->GetCharmerOrOwnerPlayerOrPlayerItself() : nullptr;
        }
        if (Unit const* unit = source->ToUnit())
            return unit->GetCharmerOrOwnerPlayerOrPlayerItself();
        return nullptr;
    }

    uint32 OtherEffectsFor(Player const* viewer, WorldObject const* source)
    {
        BonkPlayer const* bonk = viewer ? viewer->GetBonkPlayer() : nullptr;
        if (!bonk || bonk->GetOtherEffects() >= 100)
            return 100;
        Player const* owner = EffectOwner(source);
        if (!owner || owner == viewer)
            return 100;
        return bonk->GetOtherEffects();
    }
}

bool BonkCoop::SkipsEffectPacket(Player const* viewer, WorldObject const* source, uint16 opcode)
{
    if (opcode != SMSG_SPELL_START && opcode != SMSG_SPELL_GO && opcode != SMSG_PLAY_SPELL_VISUAL && opcode != SMSG_PLAY_SPELL_IMPACT)
        return false;
    uint32 const shown = OtherEffectsFor(viewer, source);
    return shown < 100 && urand(0, 99) >= shown;
}

bool BonkCoop::HidesEffectObject(Player const* viewer, WorldObject const* object)
{
    uint32 const shown = OtherEffectsFor(viewer, object);
    if (shown >= 100)
        return false;
    uint32 const roll = (object->GetGUIDLow() * 2654435761u + viewer->GetGUIDLow() * 40503u) % 100;
    return roll >= shown;
}

void BonkCoop::JoinHostGroup(Player* guest)
{
    if (!IsGuestAccount(guest))
        return;
    LinkHomeMail(guest);
    if (WasRemoved(guest->GetSession()->GetAccountId()))
    {
        SendAway(guest, BONK_STRING_COOP_REMOVED);
        return;
    }
    if (guest->GetGroup())
        return;
    Player* host = FindHost();
    if (!host)
        return;
    Group* group = host->GetGroup();
    if (group)
    {
        std::vector<ObjectGuid> away;
        for (Group::MemberSlot const& slot : group->GetMemberSlots())
            if (slot.guid != host->GetObjectGuid() && !ObjectAccessor::FindPlayerNotInWorld(slot.guid))
                away.push_back(slot.guid);
        for (ObjectGuid const& guid : away)
            if (Group* current = host->GetGroup())
                Player::RemoveFromGroup(current, guid);
        group = host->GetGroup();
    }
    if (host->GetBonkPlayer()->IsHardcore())
    {
        SendAway(guest, BONK_STRING_COOP_HOST_HARDCORE);
        return;
    }
    if (group && ClassTaken(group, guest))
    {
        SendAway(guest, BONK_STRING_COOP_CLASS_TAKEN);
        return;
    }
    if (!group)
    {
        group = new Group;
        if (!group->Create(host->GetObjectGuid(), host->GetName()))
        {
            delete group;
            return;
        }
        sObjectMgr.AddGroup(group);
    }
    if (group->IsFull())
        return;
    group->AddMember(guest->GetObjectGuid(), guest->GetName());
    RefreshCoopNpc(MemberGuids(group));
}

void BonkCoop::OnLogout(Player* player)
{
    if (!IsGuestAccount(player))
        return;
    if (!player->GetSession()->IsConnected())
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op: %s didn't rejoin in time", player->GetName());
    SyncGuest(player);
    ForgetGuest(player);
    {
        std::lock_guard<std::mutex> guard(s_seatsLock);
        s_seats.erase(player->GetObjectGuid());
    }
    if (Group* group = player->GetGroup())
    {
        std::vector<ObjectGuid> const members = MemberGuids(group);
        Player::RemoveFromGroup(group, player->GetObjectGuid());
        RefreshCoopNpc(members);
    }
}

void BonkCoop::OnUninvited(ObjectGuid guid)
{
    Player* guest = sObjectMgr.GetPlayer(guid);
    if (!IsGuestAccount(guest))
        return;
    {
        std::lock_guard<std::mutex> guard(s_removedLock);
        s_removedAccounts.insert(guest->GetSession()->GetAccountId());
    }
    NoteRemovedForLauncher(guest->GetSession()->GetUsername());
    if (!guest->GetSession()->IsConnected())
    {
        guest->GetSession()->KickDisconnectedFromWorld();
        return;
    }
    if (guest->GetBonkPlayer()->IsAddonReady())
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteCoopRemoved(data);
        guest->GetSession()->SendPacket(&data);
    }
    guest->m_Events.AddLambdaEventAtOffset([guid]
    {
        if (Player* player = sObjectMgr.GetPlayer(guid))
            player->GetSession()->LogoutRequest(time(nullptr) - 20);
    }, REMOVE_DELAY_MS);
}

uint8 BonkCoop::GuestLoginRefusal(std::string const& username, uint32 accountId, ObjectGuid character)
{
    if (!HasGuestPrefix(username))
        return 0;
    if (WasRemoved(accountId))
        return CHAR_LOGIN_DISABLED;
    Player* host = FindHost();
    if (!host)
        return 0;
    Group const* group = host->GetGroup();
    if (!group || group->IsMember(character))
        return 0;
    uint8 const classId = sObjectMgr.GetPlayerClassByGUID(character);
    uint32 present = 0;
    for (Group::MemberSlot const& slot : group->GetMemberSlots())
    {
        Player* member = sObjectMgr.GetPlayer(slot.guid);
        if (!member)
            continue;
        ++present;
        if (!SameClassAllowed() && member->GetClass() == classId && !IsAway(member))
            return CHAR_LOGIN_DUPLICATE_CHARACTER;
    }
    return present >= MAX_GROUP_SIZE ? CHAR_LOGIN_NO_INSTANCES : 0;
}

namespace
{
    void RemoveGuestAccount(uint32 accountId)
    {
        CharacterDatabase.DirectPExecute("DELETE f FROM `bonk_item_found` f JOIN `mail_items` mi ON mi.`item_guid` = f.`item_guid` "
            "JOIN `characters` c ON c.`guid` = mi.`receiver_guid` WHERE c.`account` = %u", accountId);
        CharacterDatabase.DirectPExecute("DELETE f FROM `bonk_item_found` f JOIN `character_inventory` ci ON ci.`item_guid` = f.`item_guid` "
            "JOIN `characters` c ON c.`guid` = ci.`guid` WHERE c.`account` = %u", accountId);
        CharacterDatabase.DirectPExecute("DELETE i, ci FROM `character_inventory` ci JOIN `characters` c ON c.`guid` = ci.`guid` "
            "JOIN `item_instance` i ON i.`guid` = ci.`item_guid` WHERE c.`account` = %u", accountId);
        CharacterDatabase.DirectPExecute("DELETE i FROM `item_instance` i JOIN `bonk_run_item` r ON r.`item` = i.`guid` "
            "JOIN `characters` c ON c.`guid` = r.`owner` WHERE c.`account` = %u", accountId);
        CharacterDatabase.DirectPExecute("DELETE r FROM `bonk_run_item` r JOIN `characters` c ON c.`guid` = r.`owner` WHERE c.`account` = %u", accountId);
        for (char const* table : GUEST_CHARACTER_TABLES)
            CharacterDatabase.DirectPExecute("DELETE t FROM `%s` t JOIN `characters` c ON c.`guid` = t.`guid` WHERE c.`account` = %u", table, accountId);
        sAccountMgr.DeleteAccount(accountId);
        CharacterDatabase.DirectPExecute("DELETE i FROM `item_instance` i JOIN `bonk_account_bank` b ON b.`item_guid` = i.`guid` WHERE b.`account` = %u", accountId);
        for (char const* table : GUEST_ACCOUNT_TABLES)
            CharacterDatabase.DirectPExecute("DELETE FROM `%s` WHERE `account` IN (%u, %u)", table, accountId, BonkPlayer::GetStagedCharacterAccount(accountId));
    }
}

bool BonkCoop::DeleteGuestAccount(std::string const& username)
{
    if (!HasGuestPrefix(username))
        return false;
    uint32 const accountId = sAccountMgr.GetId(username);
    if (!accountId)
        return false;
    RemoveGuestAccount(accountId);
    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op: removed guest account %s after it left", username.c_str());
    return true;
}

void BonkCoop::DeleteGuestAccounts()
{
    std::vector<uint32> guests;
    std::unique_ptr<QueryResult> result(LoginDatabase.PQuery("SELECT `id` FROM `account` WHERE `username` LIKE '%s%%'", GUEST_ACCOUNT_PREFIX));
    if (result)
    {
        do
            guests.push_back(result->Fetch()[0].GetUInt32());
        while (result->NextRow());
    }
    for (uint32 accountId : guests)
        RemoveGuestAccount(accountId);
    if (!guests.empty())
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op: removed %u guest accounts from earlier games", uint32(guests.size()));
}

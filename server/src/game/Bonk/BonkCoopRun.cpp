#include "BonkCoop.h"

#include "BonkMgr.h"
#include "BonkPlayer.h"
#include "BonkRun.h"
#include "BonkTelegraph.h"
#include "Camera.h"
#include "Group.h"
#include "HoaProtocol.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Unit.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "WorldSession.h"

#include <algorithm>
#include <cmath>
#include <ctime>
#include <fstream>
#include <sstream>
#include <map>
#include <mutex>
#include <set>
#include <vector>

namespace
{
    uint32 const READY_CHECK_MS = 20000;
    uint32 const LEASH_TICK_MS = 250;
    uint32 const LEASH_WARN_MS = 1000;
    float const LEASH_RADIUS = 80.0f;
    float const LEASH_PAD = 6.0f;
    float const LEASH_MIN_FACTOR = 0.15f;
    float const LEASH_WARN_MARGIN = 10.0f;
    float const LEASH_FACTOR_STEP = 0.02f;

    uint32 s_leashTimer = 0;
    uint32 s_leashWarnTimer = 0;
    int const ANSWER_WAITING = 0;
    int const ANSWER_YES = 1;
    int const ANSWER_NO = -1;

    struct ReadyCheck
    {
        ObjectGuid host;
        ObjectGuid nextStageAsker;
        BonkTier const* tier = nullptr;
        BonkRunChoice choice;
        std::map<ObjectGuid, int> answers;
        uint32 leftMs = READY_CHECK_MS;
    };

    std::vector<ReadyCheck> s_checks;

    char const* const JOINING_FILE = "coop/joining.txt";
    time_t const JOIN_LOAD_SECONDS = 180;
    uint32 const LOAD_WAIT_MS = 120000;

    struct LoadingStart
    {
        ObjectGuid host;
        BonkTier const* tier = nullptr;
        BonkRunChoice choice;
        uint32 waitedMs = 0;
    };

    std::vector<LoadingStart> s_loadingStarts;

    uint32 const BLEEDOUT_MS = 30000;
    uint32 const REJOIN_WAIT_MS = 120000;
    uint32 const CHOICE_WAIT_MS = 20000;
    uint32 const WAIT_SEND_MS = 1000;
    uint32 const REVIVE_MS = 5000;
    uint32 const DOWNED_SEND_MS = 250;
    float const REVIVE_RADIUS = 5.0f;
    float const REVIVE_HEALTH = 0.3f;
    float const RAISED_AT_BOSS_HEALTH = 1.0f;
    uint32 const BONK_SPELL_DOWNED_LOOK = 33650;
    uint32 const HELD_FILL_SLOWDOWN = 1000;

    enum ReviveFill : uint8
    {
        REVIVE_FILL_NONE,
        REVIVE_FILL_GROWING,
        REVIVE_FILL_HELD
    };

    struct Downed
    {
        uint32 bleedMs = BLEEDOUT_MS;
        uint32 reviveMs = 0;
        bool spectator = false;
        ObjectGuid watching;
        uint32 lookKey = 0;
        bool ringShown = false;
        ReviveFill fill = REVIVE_FILL_NONE;
        size_t watchChoices = 0;
    };

    struct GroupRun
    {
        uint32 pool = 0;
        uint32 cap = 0;
        uint32 sendTimer = 0;
        bool wiped = false;
        bool arriving = false;
        bool sharedPause = true;
        bool sharedXp = true;
        uint32 waitSendMs = 0;
        std::string lastWait;
        std::map<ObjectGuid, Downed> downed;
        std::map<ObjectGuid, uint32> choosingMs;
    };

    std::map<ObjectGuid, GroupRun> s_groups;

    struct GroupSettings
    {
        bool sharedPause = true;
        bool sharedXp = true;
        time_t readAt = 0;
    };

    time_t const SETTINGS_REREAD_SECONDS = 2;

    std::map<ObjectGuid, GroupSettings> s_settings;

    char const* const HOST_SETTINGS_FILE = "coop/host-settings.txt";

    std::map<std::string, std::string> ReadHostSettingsFile()
    {
        std::map<std::string, std::string> values;
        std::ifstream in(HOST_SETTINGS_FILE, std::ios::binary);
        std::string line;
        while (std::getline(in, line))
        {
            if (!line.empty() && line.back() == '\r')
                line.pop_back();
            size_t const tab = line.find('\t');
            if (tab != std::string::npos)
                values[line.substr(0, tab)] = line.substr(tab + 1);
        }
        return values;
    }

    void WriteHostSetting(std::string const& key, std::string const& value)
    {
        std::ifstream probe(HOST_SETTINGS_FILE, std::ios::binary);
        if (!probe.good())
            return;
        probe.close();
        std::map<std::string, std::string> values = ReadHostSettingsFile();
        values[key] = value;
        std::ofstream out(HOST_SETTINGS_FILE, std::ios::binary | std::ios::trunc);
        for (auto const& pair : values)
            out << pair.first << '\t' << pair.second << '\n';
    }

    ObjectGuid SettingsHostOf(Player const* player)
    {
        Group const* group = player->GetGroup();
        return group ? group->GetLeaderGuid() : player->GetObjectGuid();
    }

    GroupSettings SettingsOf(Player const* player)
    {
        ObjectGuid const host = SettingsHostOf(player);
        time_t const now = time(nullptr);
        auto found = s_settings.find(host);
        if (found != s_settings.end() && now - found->second.readAt < SETTINGS_REREAD_SECONDS)
            return found->second;
        std::map<std::string, std::string> const file = ReadHostSettingsFile();
        GroupSettings settings;
        settings.readAt = now;
        auto pause = file.find("pause");
        auto xp = file.find("xp");
        settings.sharedPause = pause == file.end() || pause->second != "0";
        settings.sharedXp = xp == file.end() || xp->second != "0";
        s_settings[host] = settings;
        return settings;
    }
    std::map<ObjectGuid, std::set<ObjectGuid>> s_hiddenObjects;

    std::vector<Player*> OtherMembers(Player* player)
    {
        std::vector<Player*> members;
        Group* group = player->GetGroup();
        if (!group)
            return members;
        for (Group::MemberSlot const& slot : group->GetMemberSlots())
            if (slot.guid != player->GetObjectGuid())
                if (Player* member = ObjectAccessor::FindPlayerNotInWorld(slot.guid))
                    members.push_back(member);
        return members;
    }

    std::vector<BonkRun*> GuestRunsOf(Player* host)
    {
        std::vector<BonkRun*> runs;
        for (Player* member : OtherMembers(host))
            if (BonkRun* run = member->GetBonkPlayer()->GetRun())
                if (run->IsCoopGuest() && run->GetCoopHost() == host->GetObjectGuid())
                    runs.push_back(run);
        return runs;
    }

    ObjectGuid HostOf(Player const* player)
    {
        BonkRun* run = player->GetBonkPlayer() ? player->GetBonkPlayer()->GetRun() : nullptr;
        if (run && run->IsCoopGuest())
            return run->GetCoopHost();
        return player->GetObjectGuid();
    }

    std::vector<Player*> GroupMembers(Player* host)
    {
        std::vector<Player*> members = { host };
        for (Player* member : OtherMembers(host))
            if (BonkRun* run = member->GetBonkPlayer()->GetRun())
                if (run->IsCoopGuest() && run->GetCoopHost() == host->GetObjectGuid())
                    members.push_back(member);
        return members;
    }

    bool AnyoneStanding(Player* host)
    {
        for (Player* member : GroupMembers(host))
            if (member->IsAlive() && !BonkCoop::IsAway(member))
                return true;
        return false;
    }

    Player* FindReviver(Player* downed, std::vector<Player*> const& members)
    {
        for (Player* member : members)
            if (member != downed && member->IsAlive() && member->IsInWorld() && !BonkCoop::IsAway(member) && member->GetMapId() == downed->GetMapId() &&
                member->GetDistance2d(downed) <= REVIVE_RADIUS)
                return member;
        return nullptr;
    }

    std::string ReviveRingKey(ObjectGuid const& downed)
    {
        return "revive" + std::to_string(downed.GetCounter());
    }

    std::string ReviveFillKey(ObjectGuid const& downed)
    {
        return "revivefill" + std::to_string(downed.GetCounter());
    }

    void ShowDownedLook(Player* downedPlayer, Downed& downed, std::vector<Player*> const& members)
    {
        downed.lookKey = NextBonkAuraKey();
        for (Player* member : members)
            SendBonkAuraAt(member, downed.lookKey, BONK_SPELL_DOWNED_LOOK, downedPlayer->GetPositionX(), downedPlayer->GetPositionY(),
                downedPlayer->GetPositionZ());
    }

    void ShowReviveRing(Player* downedPlayer, Downed& downed, bool shown, std::vector<Player*> const& members)
    {
        if (downed.ringShown == shown)
            return;
        downed.ringShown = shown;
        std::string const key = ReviveRingKey(downedPlayer->GetObjectGuid());
        for (Player* member : members)
        {
            if (shown)
                SendBonkMark(member, key, BONK_TELEGRAPH_CIRCLE, downedPlayer->GetPositionX(), downedPlayer->GetPositionY(), downedPlayer->GetPositionZ(),
                    0.0f, REVIVE_RADIUS, 0, true, BONK_TELEGRAPH_STYLE_NATURE, ObjectGuid(), "", 0, true);
            else
                SendBonkUnmark(member, key);
        }
    }

    void ShowReviveFill(Player* downedPlayer, Downed& downed, bool growing, std::vector<Player*> const& members)
    {
        ReviveFill const wanted = growing ? REVIVE_FILL_GROWING : downed.reviveMs ? REVIVE_FILL_HELD : REVIVE_FILL_NONE;
        if (downed.fill == wanted)
            return;
        downed.fill = wanted;
        std::string const key = ReviveFillKey(downedPlayer->GetObjectGuid());
        uint32 const slowdown = wanted == REVIVE_FILL_HELD ? HELD_FILL_SLOWDOWN : 1;
        for (Player* member : members)
        {
            if (wanted == REVIVE_FILL_NONE)
                SendBonkUnmark(member, key);
            else
                SendBonkMark(member, key, BONK_TELEGRAPH_CIRCLE, downedPlayer->GetPositionX(), downedPlayer->GetPositionY(), downedPlayer->GetPositionZ(),
                    0.0f, REVIVE_RADIUS, REVIVE_MS * slowdown, false, BONK_TELEGRAPH_STYLE_NATURE, ObjectGuid(), "", downed.reviveMs * slowdown);
        }
    }

    void HideDownedLook(Downed& downed, std::vector<Player*> const& members)
    {
        if (!downed.lookKey)
            return;
        for (Player* member : members)
            SendBonkAuraGone(member, downed.lookKey);
        downed.lookKey = 0;
    }

    void ClearDownedLooks(ObjectGuid const& guid, Downed& downed, std::vector<Player*> const& members)
    {
        for (Player* member : members)
        {
            if (downed.lookKey)
                SendBonkAuraGone(member, downed.lookKey);
            if (downed.ringShown)
                SendBonkUnmark(member, ReviveRingKey(guid));
            if (downed.fill != REVIVE_FILL_NONE)
                SendBonkUnmark(member, ReviveFillKey(guid));
        }
        downed.lookKey = 0;
        downed.ringShown = false;
        downed.fill = REVIVE_FILL_NONE;
    }

    void SendWatching(Player* watcher, Player* watched, size_t choices)
    {
        if (!watcher->GetBonkPlayer()->IsAddonReady())
            return;
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteCoopWatch(data, watched ? watched->GetName() : "", choices);
        watcher->GetSession()->SendPacket(&data);
    }

    void StopWatching(Player* player)
    {
        if (player->IsInWorld() && player->GetCamera().GetBody() != player)
            player->GetCamera().ResetView();
        SendWatching(player, nullptr, 0);
    }

    bool CanBeWatched(Player* member, Player* watcher)
    {
        return member != watcher && member->IsAlive() && member->IsInWorld() && !BonkCoop::IsAway(member) && member->GetMapId() == watcher->GetMapId();
    }

    std::vector<Player*> WatchChoices(Player* watcher, std::vector<Player*> const& members)
    {
        std::vector<Player*> choices;
        for (Player* member : members)
            if (CanBeWatched(member, watcher))
                choices.push_back(member);
        return choices;
    }

    void Watch(Player* downedPlayer, Downed& downed, Player* watched, size_t choices)
    {
        downed.watching = watched->GetObjectGuid();
        downed.watchChoices = choices;
        downedPlayer->GetCamera().SetView(watched);
        downedPlayer->GetBonkPlayer()->Notify(BONK_STRING_COOP_WATCHING, { watched->GetName() });
        SendWatching(downedPlayer, watched, choices);
    }

    void WatchStanding(Player* downedPlayer, Downed& downed, std::vector<Player*> const& members)
    {
        if (!downed.spectator || !downedPlayer->IsInWorld() || BonkCoop::IsAway(downedPlayer))
            return;
        std::vector<Player*> const choices = WatchChoices(downedPlayer, members);
        Player* current = downed.watching.IsEmpty() ? nullptr : ObjectAccessor::FindPlayerNotInWorld(downed.watching);
        if (current && std::find(choices.begin(), choices.end(), current) != choices.end())
        {
            if (downedPlayer->GetCamera().GetBody() != current)
                downedPlayer->GetCamera().SetView(current);
            if (downed.watchChoices != choices.size())
            {
                downed.watchChoices = choices.size();
                SendWatching(downedPlayer, current, choices.size());
            }
            return;
        }
        Player* nearest = nullptr;
        float nearestDistance = 0.0f;
        for (Player* choice : choices)
        {
            float const distance = downedPlayer->GetDistance2d(choice);
            if (!nearest || distance < nearestDistance)
            {
                nearest = choice;
                nearestDistance = distance;
            }
        }
        if (!nearest)
        {
            if (!downed.watching.IsEmpty())
                StopWatching(downedPlayer);
            downed.watching.Clear();
            downed.watchChoices = 0;
            return;
        }
        Watch(downedPlayer, downed, nearest, choices.size());
    }

    void ReleaseDowned(ObjectGuid const& guid, Downed& downed, std::vector<Player*> const& members)
    {
        ClearDownedLooks(guid, downed, members);
        if (Player* player = ObjectAccessor::FindPlayerNotInWorld(guid))
            StopWatching(player);
    }

    void ReleaseAllDowned(GroupRun& group, std::vector<Player*> const& members)
    {
        for (auto& entry : group.downed)
            ReleaseDowned(entry.first, entry.second, members);
        group.downed.clear();
    }

    void CarryDowned(GroupRun& group, std::vector<Player*> const& members)
    {
        for (auto& entry : group.downed)
        {
            ClearDownedLooks(entry.first, entry.second, members);
            entry.second.reviveMs = 0;
        }
        group.arriving = !group.downed.empty();
        group.sendTimer = DOWNED_SEND_MS;
    }

    void GiveAnotherChance(GroupRun& group, std::vector<Player*> const& members)
    {
        bool given = false;
        for (auto& entry : group.downed)
        {
            Downed& downed = entry.second;
            if (!downed.spectator)
                continue;
            downed.spectator = false;
            downed.bleedMs = BLEEDOUT_MS;
            downed.watching.Clear();
            downed.watchChoices = 0;
            if (Player* player = ObjectAccessor::FindPlayerNotInWorld(entry.first))
                StopWatching(player);
            given = true;
        }
        if (!given)
            return;
        for (Player* member : members)
            member->GetBonkPlayer()->Notify(BONK_STRING_COOP_ANOTHER_CHANCE);
    }

    bool EveryoneArrived(std::vector<Player*> const& members)
    {
        for (Player* member : members)
            if (!BonkCoop::IsAway(member) && (!member->IsInWorld() || member->IsBeingTeleported()))
                return false;
        return true;
    }

    void RaiseAllDowned(GroupRun& group, std::vector<Player*> const& members, bool missedBoss)
    {
        std::vector<ObjectGuid> raised;
        for (auto const& entry : group.downed)
            raised.push_back(entry.first);
        ReleaseAllDowned(group, members);
        for (ObjectGuid const& guid : raised)
        {
            Player* player = ObjectAccessor::FindPlayerNotInWorld(guid);
            BonkRun* run = player ? player->GetBonkPlayer()->GetRun() : nullptr;
            if (!run || player->IsAlive())
                continue;
            run->ReviveFromGroup(RAISED_AT_BOSS_HEALTH);
            sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op: %s is raised at the end of the stage", player->GetName());
            if (missedBoss)
            {
                run->SetMissedBoss();
                player->GetBonkPlayer()->Notify(BONK_STRING_COOP_RAISED_AFTER_BOSS);
            }
        }
        group.sendTimer = DOWNED_SEND_MS;
    }

    void SendDowned(GroupRun const& group, std::vector<Player*> const& members)
    {
        std::string list;
        for (auto const& entry : group.downed)
        {
            Player* downed = ObjectAccessor::FindPlayerNotInWorld(entry.first);
            if (!downed)
                continue;
            if (!list.empty())
                list += ",";
            list += std::string(downed->GetName()) + ":" + std::to_string((entry.second.bleedMs + 999) / IN_MILLISECONDS) + ":" +
                std::to_string(entry.second.reviveMs * 100 / REVIVE_MS) + ":" + (entry.second.spectator ? "1" : "0") + ":" +
                (entry.second.fill == REVIVE_FILL_GROWING ? "1" : "0");
        }
        for (Player* member : members)
        {
            if (!member->GetBonkPlayer()->IsAddonReady())
                continue;
            WorldPacket data(SMSG_HOA_MESSAGE);
            HoAWriteCoopDown(data, group.pool, group.cap, list);
            member->GetSession()->SendPacket(&data);
        }
    }

    void Wipe(Player* host, GroupRun& group)
    {
        group.wiped = true;
    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op: %s's group is all down, run over", host->GetName());
        if (BonkRun* run = host->GetBonkPlayer()->GetRun())
            run->EndInWipe();
    }


    bool Done(ReadyCheck const& check)
    {
        if (check.leftMs == 0)
            return true;
        for (auto const& answer : check.answers)
            if (answer.second == ANSWER_WAITING)
                return false;
        return true;
    }

    void ConcludeNextStage(ReadyCheck const& check, Player* host)
    {
        BonkRun* run = host ? host->GetBonkPlayer()->GetRun() : nullptr;
        if (!run || !run->IsPortalOpen())
            return;
        for (auto const& answer : check.answers)
        {
            Player* member = answer.second == ANSWER_NO ? sObjectMgr.GetPlayer(answer.first) : nullptr;
            if (!member)
                continue;
            for (Player* told : GroupMembers(host))
                told->GetBonkPlayer()->Notify(BONK_STRING_COOP_NEXT_STAGE_NOT_READY, { member->GetName() });
            return;
        }
        run->EnterNextStage();
    }

    void Conclude(ReadyCheck const& check)
    {
        Player* host = sObjectMgr.GetPlayer(check.host);
        for (auto const& answer : check.answers)
            if (Player* guest = sObjectMgr.GetPlayer(answer.first))
            {
                if (!guest->GetBonkPlayer()->IsAddonReady())
                    continue;
                WorldPacket data(SMSG_HOA_MESSAGE);
                HoAWriteCoopReadyEnd(data);
                guest->GetSession()->SendPacket(&data);
            }
        if (!check.nextStageAsker.IsEmpty())
        {
            ConcludeNextStage(check, host);
            return;
        }
        if (!host || host->GetBonkPlayer()->GetRun())
            return;

        BonkRunChoice choice = check.choice;
        choice.groupReady = true;
        std::string error;
        if (!host->GetBonkPlayer()->StartRun(*check.tier, error, choice))
        {
            host->GetBonkPlayer()->Notify(error);
            return;
        }
        uint32 players = 1;
        for (auto const& answer : check.answers)
        {
            Player* guest = sObjectMgr.GetPlayer(answer.first);
            if (!guest)
                continue;
            if (answer.second != ANSWER_YES)
            {
                host->GetBonkPlayer()->Notify(BONK_STRING_COOP_NOT_READY, { guest->GetName() });
                continue;
            }
            std::string guestError;
            if (!guest->GetBonkPlayer()->StartGuestRun(*check.tier, choice, host, guestError))
            {
                guest->GetBonkPlayer()->Notify(guestError);
                host->GetBonkPlayer()->Notify(BONK_STRING_COOP_COULDNT_JOIN, { guest->GetName(), guestError });
                continue;
            }
            ++players;
        }
        if (players > 1)
            BonkCoop::BeginGroupRun(host, players);
    }
}

namespace
{
    bool InLeash(Player* player)
    {
        BonkRun* run = player->GetBonkPlayer()->GetRun();
        return run && (run->IsActive() || run->IsPortalOpen()) && !run->IsAway() && player->IsAlive() && player->IsInWorld();
    }

    void SetLeash(Player* player, float factor, float distance)
    {
        BonkPlayer* bonk = player->GetBonkPlayer();
        bonk->SetLeashDistance(distance);
        if (std::fabs(bonk->GetLeashFactor() - factor) < LEASH_FACTOR_STEP && (factor < 1.0f || bonk->GetLeashFactor() == 1.0f))
            return;
        bonk->SetLeashFactor(factor);
        for (UnitMoveType type : { MOVE_WALK, MOVE_RUN, MOVE_RUN_BACK, MOVE_SWIM })
            player->UpdateSpeed(type, false);
    }

    float LeashFactor(float distance, float previousDistance)
    {
        if (distance <= LEASH_RADIUS || distance < previousDistance)
            return 1.0f;
        float const into = std::min(1.0f, (distance - LEASH_RADIUS) / LEASH_PAD);
        return 1.0f - into * (1.0f - LEASH_MIN_FACTOR);
    }
}

void BonkCoop::UpdateLeash(uint32 diff)
{
    s_leashTimer += diff;
    if (s_leashTimer < LEASH_TICK_MS)
        return;
    s_leashWarnTimer += s_leashTimer;
    s_leashTimer = 0;
    bool const warn = s_leashWarnTimer >= LEASH_WARN_MS;
    if (warn)
        s_leashWarnTimer = 0;

    std::set<Player*> leashed;
    for (auto const& entry : sObjectAccessor.GetPlayers())
    {
        Player* host = entry.second;
        if (!host || !InLeash(host) || host->GetBonkPlayer()->GetRun()->IsCoopGuest())
            continue;
        std::vector<Player*> group = { host };
        for (Player* guest : OtherMembers(host))
        {
            BonkRun* run = guest->GetBonkPlayer()->GetRun();
            if (run && run->IsCoopGuest() && run->GetCoopHost() == host->GetObjectGuid() && InLeash(guest) && guest->GetMapId() == host->GetMapId())
                group.push_back(guest);
        }
        if (group.size() < 2)
            continue;

        float centreX = 0.0f, centreY = 0.0f;
        for (Player* member : group)
        {
            centreX += member->GetPositionX();
            centreY += member->GetPositionY();
        }
        centreX /= float(group.size());
        centreY /= float(group.size());

        for (Player* member : group)
        {
            leashed.insert(member);
            float const distance = member->GetDistance2d(centreX, centreY);
            float const previous = member->GetBonkPlayer()->GetLeashDistance();
            float const factor = LeashFactor(distance, previous);
            SetLeash(member, factor, distance);
            if (warn && distance > LEASH_RADIUS - LEASH_WARN_MARGIN)
            {
                if (!member->GetBonkPlayer()->IsAddonReady())
                    continue;
                WorldPacket data(SMSG_HOA_MESSAGE);
                HoAWriteLeash(data, int32(distance), int32(LEASH_RADIUS), int32(std::lround((1.0f - factor) * 100.0f)));
                member->GetSession()->SendPacket(&data);
            }
        }
    }

    for (auto const& entry : sObjectAccessor.GetPlayers())
    {
        Player* player = entry.second;
        if (player && !leashed.count(player) && player->GetBonkPlayer() && player->GetBonkPlayer()->GetLeashFactor() != 1.0f)
            SetLeash(player, 1.0f, 0.0f);
    }
}

namespace
{
    bool IsGuestInWorld(std::string const& username)
    {
        for (auto const& entry : sObjectAccessor.GetPlayers())
            if (Player* player = entry.second)
                if (player->IsInWorld() && player->GetSession() && player->GetSession()->GetUsername() == username)
                    return true;
        return false;
    }

    std::vector<std::string> LoadingMembers(Player* host)
    {
        std::vector<std::string> loading;
        for (Player* member : OtherMembers(host))
            if (!member->IsInWorld() || member->IsBeingTeleported())
                loading.push_back(member->GetName());
        std::ifstream in(JOINING_FILE, std::ios::binary);
        std::string line;
        time_t const now = time(nullptr);
        while (std::getline(in, line))
        {
            std::istringstream fields(line);
            std::string username, name;
            long long accepted = 0;
            if (!std::getline(fields, username, '\t') || !std::getline(fields, name, '\t') || !(fields >> accepted))
                continue;
            if (now - time_t(accepted) < JOIN_LOAD_SECONDS && !IsGuestInWorld(username) &&
                std::find(loading.begin(), loading.end(), name) == loading.end())
                loading.push_back(name);
        }
        return loading;
    }

    std::string JoinNames(std::vector<std::string> const& names)
    {
        std::string text;
        for (size_t i = 0; i < names.size(); ++i)
            text += (i ? ", " : "") + names[i];
        return text;
    }

    bool WaitsForLoading(Player* host, BonkTier const& tier, BonkRunChoice const& choice)
    {
        if (choice.loadWaited)
            return false;
        std::vector<std::string> const loading = LoadingMembers(host);
        if (loading.empty())
            return false;
        bool queued = false;
        for (LoadingStart const& start : s_loadingStarts)
            queued = queued || start.host == host->GetObjectGuid();
        if (!queued)
        {
            LoadingStart start;
            start.host = host->GetObjectGuid();
            start.tier = &tier;
            start.choice = choice;
            s_loadingStarts.push_back(start);
        }
        host->GetBonkPlayer()->Notify(BONK_STRING_COOP_WAITING_FOR_LOADING, { JoinNames(loading) });
        return true;
    }

    void UpdateLoadingStarts(uint32 diff)
    {
        for (size_t i = 0; i < s_loadingStarts.size();)
        {
            LoadingStart& start = s_loadingStarts[i];
            start.waitedMs += diff;
            Player* host = sObjectMgr.GetPlayer(start.host);
            if (!host || !host->IsInWorld() || host->GetBonkPlayer()->GetRun())
            {
                s_loadingStarts.erase(s_loadingStarts.begin() + i);
                continue;
            }
            std::vector<std::string> const loading = LoadingMembers(host);
            if (!loading.empty() && start.waitedMs < LOAD_WAIT_MS)
            {
                ++i;
                continue;
            }
            LoadingStart const ready = start;
            s_loadingStarts.erase(s_loadingStarts.begin() + i);
            if (!loading.empty())
                host->GetBonkPlayer()->Notify(BONK_STRING_COOP_STARTS_WITHOUT_LOADING, { JoinNames(loading) });
            BonkRunChoice choice = ready.choice;
            choice.loadWaited = true;
            std::string error;
            if (!host->GetBonkPlayer()->StartRun(*ready.tier, error, choice) && !error.empty())
                host->GetBonkPlayer()->Notify(error);
        }
    }
}

namespace
{
    float const GROUP_VAULT_RADIUS = 6.0f;
    float const GROUP_VAULT_STEP = 1.0f;

    std::mutex s_shownOnlyLock;
    std::map<ObjectGuid, ObjectGuid> s_shownOnly;
}

void BonkCoop::ShowOnlyTo(ObjectGuid object, ObjectGuid player)
{
    std::lock_guard<std::mutex> guard(s_shownOnlyLock);
    s_shownOnly[object] = player;
}

void BonkCoop::ForgetShownOnly(ObjectGuid object)
{
    std::lock_guard<std::mutex> guard(s_shownOnlyLock);
    s_shownOnly.erase(object);
}

bool BonkCoop::IsShownOnlyToOther(ObjectGuid object, ObjectGuid viewer)
{
    std::lock_guard<std::mutex> guard(s_shownOnlyLock);
    auto const found = s_shownOnly.find(object);
    return found != s_shownOnly.end() && found->second != viewer;
}

void BonkCoop::PlaceGroupVaults(Player* host, GameObject const* portal, float side)
{
    std::vector<BonkRun*> runs;
    runs.push_back(host->GetBonkPlayer()->GetRun());
    for (BonkRun* run : GuestRunsOf(host))
        runs.push_back(run);
    float const first = side - GROUP_VAULT_STEP * float(runs.size() - 1) / 2.0f;
    for (size_t i = 0; i < runs.size(); ++i)
    {
        float const angle = first + GROUP_VAULT_STEP * float(i);
        runs[i]->PlaceVault(portal->GetPositionX() + GROUP_VAULT_RADIUS * std::cos(angle),
            portal->GetPositionY() + GROUP_VAULT_RADIUS * std::sin(angle), portal->GetPositionZ());
    }
}

void BonkCoop::ShareEnchanter(Player* host, ObjectGuid enchanter)
{
    for (BonkRun* run : GuestRunsOf(host))
        run->UseHostEnchanter(enchanter);
}

Player* BonkCoop::VaultOwner(Player* viewer, GameObject const* vault)
{
    for (Player* member : RunGroupOf(viewer))
        if (BonkRun* run = member->GetBonkPlayer()->GetRun())
            if (run->IsOwnVault(vault))
                return member;
    return nullptr;
}

bool BonkCoop::RequestGroupStart(Player* host, BonkTier const& tier, BonkRunChoice const& choice)
{
    if (WaitsForLoading(host, tier, choice))
        return true;

    std::vector<Player*> guests;
    for (Player* member : OtherMembers(host))
        if (!member->GetBonkPlayer()->GetRun())
            guests.push_back(member);
    if (guests.empty())
        return false;

    for (ReadyCheck const& check : s_checks)
        if (check.host == host->GetObjectGuid())
        {
            host->GetBonkPlayer()->Notify(BONK_STRING_COOP_STILL_ANSWERING);
            return true;
        }

    ReadyCheck check;
    check.host = host->GetObjectGuid();
    check.tier = &tier;
    check.choice = choice;
    for (Player* guest : guests)
    {
        check.answers[guest->GetObjectGuid()] = ANSWER_WAITING;
        BonkPlayer* bonk = guest->GetBonkPlayer();
        std::string const text = bonk->GetString(BONK_STRING_COOP_HOST_WANTS_START, { bonk->GetLevelName(choice.level) });
        if (bonk->IsAddonReady())
        {
            WorldPacket data(SMSG_HOA_MESSAGE);
            HoAWriteCoopReady(data, text, READY_CHECK_MS / IN_MILLISECONDS);
            guest->GetSession()->SendPacket(&data);
        }
    }
    s_checks.push_back(check);
    host->GetBonkPlayer()->Notify(BONK_STRING_COOP_ASKING_READY);
    return true;
}

void BonkCoop::AnswerReady(Player* player, bool ready)
{
    for (ReadyCheck& check : s_checks)
    {
        auto answer = check.answers.find(player->GetObjectGuid());
        if (answer != check.answers.end())
            answer->second = ready ? ANSWER_YES : ANSWER_NO;
    }
}

void BonkCoop::UpdateReadyChecks(uint32 diff)
{
    UpdateLoadingStarts(diff);
    for (size_t i = 0; i < s_checks.size();)
    {
        ReadyCheck& check = s_checks[i];
        check.leftMs = check.leftMs > diff ? check.leftMs - diff : 0;
        if (!Done(check))
        {
            ++i;
            continue;
        }
        ReadyCheck const finished = check;
        s_checks.erase(s_checks.begin() + i);
        Conclude(finished);
    }
}

void BonkCoop::OnHostEnteredStage(Player* host, BonkMap const& map, uint32 stage)
{
    auto group = s_groups.find(host->GetObjectGuid());
    std::vector<Player*> const members = GroupMembers(host);
    if (group != s_groups.end())
        CarryDowned(group->second, members);
    for (BonkRun* run : GuestRunsOf(host))
        run->FollowToStage(map, stage);
    if (group != s_groups.end() && group->second.pool < group->second.cap)
    {
        ++group->second.pool;
        for (Player* member : members)
            member->GetBonkPlayer()->Notify(BONK_STRING_COOP_STAGE_REVIVE);
    }
    if (group != s_groups.end() && group->second.pool > 0)
        GiveAnotherChance(group->second, members);
}

void BonkCoop::OnHostPortal(Player* host, bool last)
{
    auto group = s_groups.find(host->GetObjectGuid());
    if (last && group != s_groups.end() && !group->second.wiped)
        RaiseAllDowned(group->second, GroupMembers(host), true);
    for (BonkRun* run : GuestRunsOf(host))
        run->FollowToPortal();
}

BonkRun* BonkCoop::GroupPortalRun(Player* player, GameObject const* portal)
{
    if (!InGroupRun(player) || !player->IsAlive())
        return nullptr;
    Player* host = ObjectAccessor::FindPlayerNotInWorld(HostOf(player));
    BonkRun* run = host ? host->GetBonkPlayer()->GetRun() : nullptr;
    return run && run->IsOwnPortal(portal) ? run : nullptr;
}

void BonkCoop::RequestNextStage(Player* player)
{
    Player* host = ObjectAccessor::FindPlayerNotInWorld(HostOf(player));
    BonkRun* run = host ? host->GetBonkPlayer()->GetRun() : nullptr;
    if (!run || !run->IsPortalOpen())
        return;
    for (ReadyCheck const& check : s_checks)
        if (check.host == host->GetObjectGuid())
        {
            player->GetBonkPlayer()->Notify(BONK_STRING_COOP_STILL_ANSWERING);
            return;
        }

    ReadyCheck check;
    check.host = host->GetObjectGuid();
    check.nextStageAsker = player->GetObjectGuid();
    for (Player* member : GroupMembers(host))
    {
        if (member == player || !member->IsAlive() || IsAway(member))
            continue;
        check.answers[member->GetObjectGuid()] = ANSWER_WAITING;
        BonkPlayer* bonk = member->GetBonkPlayer();
        std::string const text = bonk->GetString(BONK_STRING_COOP_WANTS_NEXT_STAGE, { player->GetName() });
        if (bonk->IsAddonReady())
        {
            WorldPacket data(SMSG_HOA_MESSAGE);
            HoAWriteCoopReady(data, text, READY_CHECK_MS / IN_MILLISECONDS);
            member->GetSession()->SendPacket(&data);
        }
    }
    if (check.answers.empty())
    {
        run->EnterNextStage();
        return;
    }
    s_checks.push_back(check);
    player->GetBonkPlayer()->Notify(BONK_STRING_COOP_ASKING_READY);
}

void BonkCoop::OnHostEndless(Player* host, uint32 stage)
{
    for (BonkRun* run : GuestRunsOf(host))
        run->FollowIntoEndless(stage);
}

void BonkCoop::NoteHostRun(Player const* host, std::string const& playing)
{
    if (IsGuestAccount(host))
        return;
    WriteHostSetting("playing", playing);
}

void BonkCoop::OnHostFinished(Player* host)
{
    NoteHostRun(host, "");
    auto group = s_groups.find(host->GetObjectGuid());
    bool const wiped = group != s_groups.end() && group->second.wiped;
    for (Player* member : GroupMembers(host))
    {
        if (!member->GetBonkPlayer()->IsAddonReady())
            continue;
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteCoopDown(data, 0, 0, "");
        member->GetSession()->SendPacket(&data);
    }
    if (group != s_groups.end())
    {
        ReleaseAllDowned(group->second, GroupMembers(host));
        s_groups.erase(group);
    }
    for (BonkRun* run : GuestRunsOf(host))
    {
        if (wiped)
            run->EndInWipe();
        else
            run->EndWithHost();
    }
}

std::vector<Player*> BonkCoop::RunGroupOf(Player* player)
{
    if (!player->GetGroup())
        return { player };
    Player* host = ObjectAccessor::FindPlayerNotInWorld(HostOf(player));
    if (!host)
        return { player };
    return GroupMembers(host);
}

bool BonkCoop::InGroupRun(Player const* player)
{
    return player->GetGroup() && s_groups.count(HostOf(player));
}

bool BonkCoop::KeepsAfterDisconnect(Player const* player)
{
    if (!player || !IsGuestAccount(player) || !InGroupRun(player))
        return false;
    BonkRun* run = player->GetBonkPlayer()->GetRun();
    return run && run->IsCoopGuest() && !run->IsOver();
}

uint32 BonkCoop::RejoinWaitMs()
{
    return REJOIN_WAIT_MS;
}

namespace
{
    void TellSettingChanged(Player* host, BonkString line)
    {
        for (Player* member : GroupMembers(host))
            member->GetBonkPlayer()->Notify(line);
    }
}

bool BonkCoop::IsInCoopGroup(Player const* player)
{
    if (IsGuestAccount(player))
        return true;
    Group const* group = player->GetGroup();
    if (!group)
        return false;
    for (Group::MemberSlot const& slot : group->GetMemberSlots())
        if (Player* member = ObjectAccessor::FindPlayerNotInWorld(slot.guid))
            if (IsGuestAccount(member))
                return true;
    return false;
}

bool BonkCoop::IsGroupHost(Player const* player)
{
    return !IsGuestAccount(player) && SettingsHostOf(player) == player->GetObjectGuid();
}

Player* BonkCoop::FortuneHostOf(Player const* player)
{
    if (!IsGuestAccount(player))
        return nullptr;
    Group const* group = player->GetGroup();
    Player* host = group ? ObjectAccessor::FindPlayerNotInWorld(group->GetLeaderGuid()) : nullptr;
    return host && !IsGuestAccount(host) ? host : nullptr;
}

bool BonkCoop::SharesPause(Player const* player)
{
    auto running = s_groups.find(HostOf(player));
    return running != s_groups.end() ? running->second.sharedPause : SettingsOf(player).sharedPause;
}

bool BonkCoop::SharesXp(Player const* player)
{
    auto running = s_groups.find(HostOf(player));
    return running != s_groups.end() ? running->second.sharedXp : SettingsOf(player).sharedXp;
}

void BonkCoop::SetSharedPause(Player* host, bool shared)
{
    s_settings[host->GetObjectGuid()] = SettingsOf(host);
    s_settings[host->GetObjectGuid()].sharedPause = shared;
    WriteHostSetting("pause", shared ? "1" : "0");
    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op: %s sets pausing to %s", host->GetName(), shared ? "shared" : "none");
    TellSettingChanged(host, shared ? BONK_STRING_COOP_PAUSE_TURNED_ON : BONK_STRING_COOP_PAUSE_TURNED_OFF);
}

void BonkCoop::SetSharedXp(Player* host, bool shared)
{
    s_settings[host->GetObjectGuid()] = SettingsOf(host);
    s_settings[host->GetObjectGuid()].sharedXp = shared;
    WriteHostSetting("xp", shared ? "1" : "0");
    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op: %s sets XP to %s", host->GetName(), shared ? "shared" : "individual");
    TellSettingChanged(host, shared ? BONK_STRING_COOP_XP_TURNED_SHARED : BONK_STRING_COOP_XP_TURNED_OWN);
}

bool BonkCoop::IsAway(Player const* player)
{
    BonkRun* run = player->GetBonkPlayer() ? player->GetBonkPlayer()->GetRun() : nullptr;
    return run && run->IsAway();
}

void BonkCoop::OnDisconnected(Player* player)
{
    BonkRun* run = player->GetBonkPlayer()->GetRun();
    if (!run)
        return;
    run->SetAway(true);
    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op: %s lost the connection, run held for %u s", player->GetName(), REJOIN_WAIT_MS / IN_MILLISECONDS);
    for (Player* member : OtherMembers(player))
        member->GetBonkPlayer()->Notify(BONK_STRING_COOP_LOST_CONNECTION, { player->GetName(), std::to_string(REJOIN_WAIT_MS / IN_MILLISECONDS / MINUTE) });
}

void BonkCoop::OnReconnected(Player* player)
{
    BonkRun* run = player->GetBonkPlayer()->GetRun();
    if (!run || !run->IsAway())
        return;
    run->SetAway(false);
    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op: %s rejoined the run", player->GetName());
    for (Player* member : OtherMembers(player))
        member->GetBonkPlayer()->Notify(BONK_STRING_COOP_IS_BACK, { player->GetName() });
}

void BonkCoop::ShareExperience(Player* collector, float levelFraction)
{
    if (levelFraction <= 0.0f || !collector->GetGroup())
        return;
    auto found = s_groups.find(HostOf(collector));
    if (found == s_groups.end() || !found->second.sharedXp)
        return;
    for (Player* member : RunGroupOf(collector))
        if (member != collector)
            if (BonkRun* run = member->GetBonkPlayer()->GetRun())
                run->ShareExperience(levelFraction);
}

void BonkCoop::HideObjectFor(ObjectGuid object, ObjectGuid player)
{
    s_hiddenObjects[object].insert(player);
}

bool BonkCoop::IsObjectHiddenFor(ObjectGuid object, ObjectGuid player)
{
    if (s_hiddenObjects.empty())
        return false;
    auto found = s_hiddenObjects.find(object);
    return found != s_hiddenObjects.end() && found->second.count(player);
}

void BonkCoop::ForgetHiddenObject(ObjectGuid object)
{
    s_hiddenObjects.erase(object);
}

void BonkCoop::UpdateSharedPause(uint32 diff)
{
    for (auto& entry : s_groups)
    {
        GroupRun& group = entry.second;
        Player* host = ObjectAccessor::FindPlayerNotInWorld(entry.first);
        if (!host || group.wiped || !group.sharedPause)
            continue;

        std::vector<std::pair<Player*, BonkRun*>> members;
        for (Player* member : GroupMembers(host))
            if (BonkRun* run = member->GetBonkPlayer()->GetRun())
                if (run->IsActive() || run->IsPortalOpen())
                    members.push_back({ member, run });

        std::vector<std::string> waitingOn;
        uint32 longestLeftMs = 0;
        for (auto const& member : members)
        {
            ObjectGuid const guid = member.first->GetObjectGuid();
            if (!member.second->IsChoosing())
            {
                group.choosingMs.erase(guid);
                continue;
            }
            uint32& choosing = group.choosingMs[guid];
            if (choosing >= CHOICE_WAIT_MS)
                continue;
            choosing += diff;
            if (choosing >= CHOICE_WAIT_MS)
            {
                member.second->ResolveChoiceForGroup();
                continue;
            }
            waitingOn.push_back(member.first->GetName());
            longestLeftMs = std::max(longestLeftMs, CHOICE_WAIT_MS - choosing);
        }

        bool const held = !waitingOn.empty();
        for (auto const& member : members)
            member.second->SetGroupHeld(held);

        group.waitSendMs += diff;
        std::string names;
        for (std::string const& name : waitingOn)
            names += (names.empty() ? "" : ",") + name;
        if (names == group.lastWait && (names.empty() || group.waitSendMs < WAIT_SEND_MS))
            continue;
        group.waitSendMs = 0;
        group.lastWait = names;
        uint32 const seconds = (longestLeftMs + 999) / IN_MILLISECONDS;
        for (auto const& member : members)
        {
            if (!member.first->GetBonkPlayer()->IsAddonReady())
                continue;
            WorldPacket data(SMSG_HOA_MESSAGE);
            HoAWriteCoopWait(data, names, seconds);
            member.first->GetSession()->SendPacket(&data);
        }
    }
}

void BonkCoop::BeginGroupRun(Player* host, uint32 players)
{
    GroupRun& group = s_groups[host->GetObjectGuid()];
    group = GroupRun();
    group.cap = players + 1;
    group.pool = group.cap;
    GroupSettings const settings = SettingsOf(host);
    group.sharedPause = settings.sharedPause;
    group.sharedXp = settings.sharedXp;
    for (Player* member : GroupMembers(host))
        if (BonkRun* run = member->GetBonkPlayer()->GetRun())
            run->SetCoopPlayers(players, group.sharedPause, group.sharedXp);
    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op: %s starts a group run, %u players, pool %u", host->GetName(), players, group.pool);
    SendDowned(group, GroupMembers(host));
}

bool BonkCoop::IsDowned(Player const* player)
{
    auto group = s_groups.find(HostOf(player));
    return group != s_groups.end() && group->second.downed.count(player->GetObjectGuid());
}

uint32 BonkCoop::StandingCount(Player* player)
{
    uint32 standing = 0;
    for (Player* member : RunGroupOf(player))
        if (member->IsAlive() && !IsAway(member))
            ++standing;
    return std::max(1u, standing);
}

bool BonkCoop::Down(Player* player)
{
    ObjectGuid const hostGuid = HostOf(player);
    auto found = s_groups.find(hostGuid);
    Player* host = ObjectAccessor::FindPlayerNotInWorld(hostGuid);
    if (found == s_groups.end() || !host)
        return false;
    GroupRun& group = found->second;
    if (player->GetClass() == CLASS_DRUID && player->GetDisplayId() != player->GetNativeDisplayId())
        player->SetDisplayId(player->GetNativeDisplayId());
    Downed& downed = group.downed[player->GetObjectGuid()];
    downed = Downed();
    downed.spectator = group.pool == 0;
    std::string const name = player->GetName();
    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op: %s is down, pool %u/%u", name.c_str(), group.pool, group.cap);
    for (Player* member : GroupMembers(host))
    {
        if (member == player)
            member->GetBonkPlayer()->Notify(downed.spectator ? BONK_STRING_COOP_YOU_DOWN_NO_REVIVES : BONK_STRING_COOP_YOU_DOWN);
        else
            member->GetBonkPlayer()->Notify(downed.spectator ? BONK_STRING_COOP_MEMBER_DOWN_NO_REVIVES : BONK_STRING_COOP_MEMBER_DOWN, { name });
    }
    group.sendTimer = DOWNED_SEND_MS;
    std::vector<Player*> const members = GroupMembers(host);
    if (!downed.spectator)
        ShowDownedLook(player, downed, members);
    if (!AnyoneStanding(host))
    {
        Wipe(host, group);
        return true;
    }
    ShowReviveRing(player, downed, !downed.spectator, members);
    WatchStanding(player, downed, members);
    return true;
}

void BonkCoop::WatchNext(Player* player, bool forward)
{
    auto found = s_groups.find(HostOf(player));
    Player* host = found != s_groups.end() ? ObjectAccessor::FindPlayerNotInWorld(found->first) : nullptr;
    if (!host)
        return;
    auto downed = found->second.downed.find(player->GetObjectGuid());
    if (downed == found->second.downed.end() || !downed->second.spectator)
        return;
    std::vector<Player*> const choices = WatchChoices(player, GroupMembers(host));
    if (choices.size() < 2)
        return;
    auto current = std::find_if(choices.begin(), choices.end(), [&downed](Player* choice) { return choice->GetObjectGuid() == downed->second.watching; });
    size_t const at = current == choices.end() ? 0 : size_t(current - choices.begin());
    Player* next = choices[(at + (forward ? 1 : choices.size() - 1)) % choices.size()];
    Watch(player, downed->second, next, choices.size());
}

void BonkCoop::UpdateDowned(uint32 diff)
{
    std::vector<ObjectGuid> hosts;
    for (auto const& entry : s_groups)
        hosts.push_back(entry.first);
    for (ObjectGuid const& hostGuid : hosts)
    {
        auto found = s_groups.find(hostGuid);
        if (found == s_groups.end())
            continue;
        GroupRun& group = found->second;
        Player* host = ObjectAccessor::FindPlayerNotInWorld(hostGuid);
        if (!host || !host->GetBonkPlayer()->GetRun())
        {
            ReleaseAllDowned(group, host ? GroupMembers(host) : std::vector<Player*>());
            s_groups.erase(found);
            continue;
        }
        if (group.wiped)
            continue;
        std::vector<Player*> const members = GroupMembers(host);
        if (group.arriving)
        {
            if (!EveryoneArrived(members))
                continue;
            group.arriving = false;
        }
        bool paused = false;
        for (Player* member : members)
            if (BonkRun* run = member->GetBonkPlayer()->GetRun())
                if (run->IsPaused() && !run->IsAway())
                    paused = true;
        for (auto it = group.downed.begin(); it != group.downed.end();)
        {
            Player* downedPlayer = ObjectAccessor::FindPlayerNotInWorld(it->first);
            if (!downedPlayer || downedPlayer->IsAlive() || !downedPlayer->GetBonkPlayer()->GetRun())
            {
                ReleaseDowned(it->first, it->second, members);
                it = group.downed.erase(it);
                continue;
            }
            Downed& downed = it->second;
            if (!downed.spectator && !downed.lookKey)
                ShowDownedLook(downedPlayer, downed, members);
            WatchStanding(downedPlayer, downed, members);
            ShowReviveRing(downedPlayer, downed, !downed.spectator && group.pool > 0, members);
            if (downed.spectator || paused)
            {
                ShowReviveFill(downedPlayer, downed, false, members);
                ++it;
                continue;
            }
            Player* reviver = group.pool ? FindReviver(downedPlayer, members) : nullptr;
            if ((downed.fill == REVIVE_FILL_GROWING) != (reviver != nullptr))
                group.sendTimer = DOWNED_SEND_MS;
            ShowReviveFill(downedPlayer, downed, reviver != nullptr, members);
            if (reviver)
            {
                downed.reviveMs += diff;
                if (downed.reviveMs >= REVIVE_MS)
                {
                    ReleaseDowned(it->first, downed, members);
                    --group.pool;
                    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op: %s revived %s, pool %u/%u", reviver->GetName(), downedPlayer->GetName(), group.pool, group.cap);
                    downedPlayer->GetBonkPlayer()->GetRun()->ReviveFromGroup(REVIVE_HEALTH);
                    for (Player* member : members)
                    {
                        if (group.pool == 1)
                            member->GetBonkPlayer()->Notify(BONK_STRING_COOP_REVIVED_ONE_LEFT, { reviver->GetName(), downedPlayer->GetName() });
                        else
                            member->GetBonkPlayer()->Notify(BONK_STRING_COOP_REVIVED_LEFT, { reviver->GetName(), downedPlayer->GetName(), std::to_string(group.pool) });
                    }
                    it = group.downed.erase(it);
                    group.sendTimer = DOWNED_SEND_MS;
                    continue;
                }
            }
            else
            {
                downed.bleedMs = downed.bleedMs > diff ? downed.bleedMs - diff : 0;
                if (downed.bleedMs == 0)
                {
                    downed.spectator = true;
                    downed.reviveMs = 0;
                    HideDownedLook(downed, members);
                    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Co-op: %s bled out", downedPlayer->GetName());
                    for (Player* member : members)
                        member->GetBonkPlayer()->Notify(BONK_STRING_COOP_BLED_OUT, { downedPlayer->GetName() });
                    group.sendTimer = DOWNED_SEND_MS;
                }
            }
            ++it;
        }
        if (!AnyoneStanding(host))
        {
            Wipe(host, group);
            continue;
        }
        group.sendTimer += diff;
        if (group.sendTimer >= DOWNED_SEND_MS)
        {
            group.sendTimer = 0;
            SendDowned(group, members);
        }
    }
}

#ifndef BONK_LEADERBOARD_H
#define BONK_LEADERBOARD_H

#include "Common.h"

class Player;

namespace BonkLeaderboard
{
    void Send(Player* player);
    void SendPage(Player* player, uint32 view, uint32 classId, uint32 offset);
    uint32 GetClimbTop(uint32 characterGuid);
}

void AddSC_bonk_leaderboard();

#endif

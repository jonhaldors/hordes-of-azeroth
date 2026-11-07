#ifndef MANGOS_BONKCODEX_H
#define MANGOS_BONKCODEX_H

#include "Common.h"

#include <cstdint>
#include <string>

class BonkPlayer;
class Player;
struct BonkCard;

namespace BonkCodex
{
    void Send(Player* player, std::string const& npc, bool deck = false);
    void SendKeywordGlossary(BonkPlayer* bonk);
    void SendTermGlossary(BonkPlayer* bonk);
    std::string DescribeCardTotal(BonkCard const& card, uint32_t copies, LocaleConstant locale);
}

#endif

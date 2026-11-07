#ifndef MANGOS_BONKVERSION_H
#define MANGOS_BONKVERSION_H

#include "Common.h"

#include <string>

class Player;

namespace BonkVersion
{
    std::string BuildMotd(std::string const& welcome);
    void SendPatchLines(Player* player);
    void Update(uint32 diff);
}

#endif

#ifndef MANGOS_BONKSANDBOX_H
#define MANGOS_BONKSANDBOX_H

class Creature;
class Player;

namespace BonkSandbox
{
    bool IsAllowed(Player const* player);
    bool IsHiddenFrom(Creature const* creature, Player const* viewer);
}

#endif

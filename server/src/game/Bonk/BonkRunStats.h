#ifndef MANGOS_BONKRUNSTATS_H
#define MANGOS_BONKRUNSTATS_H

#include "Common.h"
#include "BonkMgr.h"
#include "ObjectGuid.h"

#include <deque>
#include <map>
#include <set>
#include <string>
#include <vector>

class Player;
class Unit;
class SpellEntry;

struct BonkRecentHit
{
    uint32 ms = 0;
    uint32 amount = 0;
    uint32 healthAfter = 0;
    bool heal = false;
    std::string source;
    std::string spell;
    std::string icon;
    BonkSpawnKind kind = BONK_SPAWN_NORMAL;
};

struct BonkRunStats
{
    struct Spell
    {
        uint64 damage = 0;
        uint32 kills = 0;
    };

    std::map<uint32, Spell> bySpell;
    std::map<uint32, std::map<uint32, Spell>> dotBySpell;
    uint64 damageTaken = 0;
    uint64 biggestHit = 0;
    uint32 kindKills[MAX_BONK_SPAWN_KIND] = {};
    std::map<ObjectGuid, uint32> killingSpells;
    std::map<ObjectGuid, uint32> killingDots;
    std::deque<BonkRecentHit> recentHits;
};

struct BonkOtherSource
{
    uint32 spellId = 0;
    std::string icon;
    std::string name;
    uint64 damage = 0;
    uint32 kills = 0;
    std::string type;
};

struct BonkSummaryWeapon
{
    uint32 spellId = 0;
    std::vector<uint32> spellIds;
    std::string name;
    std::string icon;
    uint32 level = 1;
    uint32 maxLevel = 1;
    bool evolved = false;
};

namespace BonkStats
{
    void Reset(ObjectGuid player);
    uint32 CountKill(ObjectGuid player, ObjectGuid enemy, BonkSpawnKind kind);
    BonkRunStats::Spell GetSpellStats(ObjectGuid player, uint32 spellId);
    std::string DescribeDamageTypes(ObjectGuid player, uint32 spellId);
    std::vector<uint32> GetWeaponSpells(BonkWeapon const& weapon);
    std::vector<BonkOtherSource> GetOtherSources(Player* player, std::set<uint32> const& shown);
    uint64 TotalDamage(ObjectGuid guid);
    void SendSummary(Player* player, std::vector<BonkSummaryWeapon> const& weapons);

    void UpdateBossBar(Player* player, uint32 diff);
    void RecordHeroHeal(Player* player, uint32 amount);
}

void BonkOnDamage(Unit* attacker, Unit* victim, uint32 damage, SpellEntry const* spellProto);

#endif

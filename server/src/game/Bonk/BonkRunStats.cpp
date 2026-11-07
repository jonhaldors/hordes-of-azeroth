#include "BonkRunStats.h"
#include "BonkCoop.h"
#include "BonkLocale.h"
#include "BonkMobAI.h"
#include "BonkPlayer.h"
#include "BonkQuests.h"
#include "BonkRun.h"
#include "CellImpl.h"
#include "Creature.h"
#include "Database/DBCFileLoader.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "HoaProtocol.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "SpellEntry.h"
#include "SpellMgr.h"
#include "TemporarySummon.h"
#include "Timer.h"
#include "World.h"
#include "WorldSession.h"

#include <algorithm>

#include <list>
#include <mutex>
#include <set>

namespace
{
    uint32 const BONK_BOSS_BAR_MS    = 250;
    float const BONK_BOSS_BAR_RANGE  = 150.0f;
    size_t const BONK_BOSS_BAR_MAX   = 4;

    struct BossBar
    {
        uint32 timer = 0;
        std::string lastLine;
    };

    std::mutex s_lock;

    std::string SpellNameFor(SpellEntry const* spell, int localeIndex)
    {
        if (!spell)
            return "";
        if (localeIndex >= 0 && size_t(localeIndex) < spell->SpellName.size() && !spell->SpellName[localeIndex].empty())
            return spell->SpellName[localeIndex];
        return spell->SpellName[0];
    }
    std::map<ObjectGuid, BonkRunStats> s_stats;
    std::map<ObjectGuid, BossBar> s_bossBars;

    bool InRun(Player const* player)
    {
        return player->GetBonkPlayer()->GetRun() != nullptr;
    }

    BonkRun const* GetPausedRunOf(Unit const* victim)
    {
        Creature const* mob = victim->ToCreature();
        BonkMobAI const* ai = mob ? dynamic_cast<BonkMobAI const*>(mob->AI()) : nullptr;
        Player* owner = ai ? sObjectAccessor.FindPlayer(ai->GetOwnerGuid()) : nullptr;
        BonkRun const* run = owner ? owner->GetBonkPlayer()->GetRun() : nullptr;
        return run && run->IsPaused() && !run->IsAway() ? run : nullptr;
    }

    void LogPausedHit(Unit* attacker, Unit* victim, uint32 damage, SpellEntry const* spellProto)
    {
        if (!GetPausedRunOf(victim))
            return;
        uint32 const createdBy = attacker->GetUInt32Value(UNIT_CREATED_BY_SPELL);
        sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Bonk paused hit: %s (entry %u, %s, created by spell %u, time frozen %s) hit %s (entry %u) for %u with spell %u %s, health %u of %u",
            attacker->GetName(), attacker->GetEntry(), attacker->GetGuidStr().c_str(), createdBy, attacker->IsTimeFrozen() ? "yes" : "no",
            victim->GetName(), victim->GetEntry(), damage, spellProto ? spellProto->Id : 0, spellProto ? spellProto->SpellName[0].c_str() : "melee",
            victim->GetHealth(), victim->GetMaxHealth());
    }

    std::string KeywordStacksText(Player* player, Creature const* victim)
    {
        BonkRun const* run = player->GetBonkPlayer()->GetRun();
        std::string text;
        if (!run)
            return text;
        for (auto const& itr : sBonkMgr.GetKeywords())
            if (uint32 const stacks = run->GetKeywordStacks(victim, itr.second.id))
                text += (text.empty() ? "" : ",") + std::to_string(uint32(itr.second.id)) + ":" + std::to_string(stacks);
        return text;
    }

    char const* const BONK_SCHOOL_TYPES[MAX_SPELL_SCHOOL] = { "phys", "holy", "fire", "nature", "frost", "shadow", "arcane" };

    std::string SchoolType(uint32 spellId)
    {
        SpellEntry const* spellInfo = spellId ? sSpellMgr.GetSpellEntry(spellId) : nullptr;
        return BONK_SCHOOL_TYPES[spellInfo && spellInfo->School < MAX_SPELL_SCHOOL ? spellInfo->School : SPELL_SCHOOL_NORMAL];
    }

    std::string DamageType(uint32 spellId)
    {
        if (BonkKeywordInfo const* keyword = spellId ? sBonkMgr.GetKeywordBySpell(spellId) : nullptr)
        {
            switch (keyword->id)
            {
                case BONK_KEYWORD_BLEED:   return "bleed";
                case BONK_KEYWORD_POISON:  return "poison";
                case BONK_KEYWORD_BURNING: return "burn";
                case BONK_KEYWORD_DECAY:   return "decay";
                case BONK_KEYWORD_AGONY:   return "agony";
                case BONK_KEYWORD_MOONFIRE: return "moonfire";
                case BONK_KEYWORD_STATIC:  return "static";
                default:                   break;
            }
        }
        return SchoolType(spellId);
    }

    uint32 const BONK_RECAP_WINDOW_MS   = 10000;
    uint32 const BONK_RECAP_SLOT_MS     = 100;
    uint32 const BONK_RECAP_MAX_SOURCES = 4;
    uint32 const BONK_RECAP_MAX_EVENTS  = 150;
    size_t const BONK_RECAP_LINE_CHARS  = 220;
    char const* const BONK_ICON_PREFIX  = "Interface\\Icons\\";
    char const* const BONK_MELEE_ICON   = "INV_Sword_04";
    char const* const BONK_UNKNOWN_ICON = "INV_Misc_QuestionMark";

    std::string SpellIconName(SpellEntry const* spellInfo)
    {
        static std::map<uint32, std::string> icons;
        static std::once_flag loaded;
        std::call_once(loaded, []()
        {
            DBCFileLoader file;
            std::string const path = sWorld.GetDataPath() + std::to_string(uint32(SUPPORTED_CLIENT_BUILD)) + "/dbc/SpellIcon.dbc";
            if (!file.Load(path.c_str(), "ns"))
                return;
            size_t const prefixLength = strlen(BONK_ICON_PREFIX);
            for (uint32 i = 0; i < file.GetNumRows(); ++i)
            {
                DBCFileLoader::Record row = file.getRecord(i);
                char const* texture = row.getString(1);
                if (!texture || !StringStartsWithCaseInsensitive(texture, BONK_ICON_PREFIX))
                    continue;
                icons[row.getUInt(0)] = texture + prefixLength;
            }
        });
        if (!spellInfo)
            return BONK_MELEE_ICON;
        auto itr = icons.find(spellInfo->SpellIconID);
        return itr != icons.end() ? itr->second : BONK_UNKNOWN_ICON;
    }

    BonkSpawnKind SpawnKindOf(Creature* creature)
    {
        BonkMobAI const* ai = creature ? dynamic_cast<BonkMobAI const*>(creature->AI()) : nullptr;
        return ai ? ai->GetKind() : BONK_SPAWN_NORMAL;
    }

    Creature* NamedSource(Unit* attacker)
    {
        Creature* creature = attacker->ToCreature();
        if (!creature || *creature->GetName() || !creature->IsTemporarySummon())
            return creature;
        Creature* summoner = attacker->GetMap()->GetCreature(static_cast<TemporarySummon*>(creature)->GetSummonerGuid());
        return summoner && *summoner->GetName() ? summoner : creature;
    }

    BonkRecentHit DescribeHit(Unit* attacker, SpellEntry const* spellProto, int localeIndex)
    {
        BonkRecentHit hit;
        Creature* source = NamedSource(attacker);
        hit.source = source ? source->GetNameForLocaleIdx(localeIndex) : attacker->GetNameForLocaleIdx(localeIndex);
        hit.kind = SpawnKindOf(source);
        hit.spell = spellProto ? SpellNameFor(spellProto, localeIndex) : "Melee";
        hit.icon = SpellIconName(spellProto);
        if (hit.source.empty())
        {
            hit.source = hit.spell;
            hit.spell.clear();
        }
        return hit;
    }

    void TrimRecentHits(std::deque<BonkRecentHit>& hits, uint32 now)
    {
        while (!hits.empty() && WorldTimer::getMSTimeDiff(hits.front().ms, now) > BONK_RECAP_WINDOW_MS)
            hits.pop_front();
    }

    void PushRecentHit(Player* player, BonkRecentHit hit)
    {
        hit.ms = WorldTimer::getMSTime();
        std::lock_guard<std::mutex> guard(s_lock);
        std::deque<BonkRecentHit>& hits = s_stats[player->GetObjectGuid()].recentHits;
        hits.push_back(std::move(hit));
        TrimRecentHits(hits, hits.back().ms);
    }

    char const* KindTag(BonkSpawnKind kind)
    {
        switch (kind)
        {
            case BONK_SPAWN_BOSS:     return "b";
            case BONK_SPAWN_MINIBOSS: return "m";
            case BONK_SPAWN_ELITE:    return "e";
            default:                  return "";
        }
    }

    struct RecapSource
    {
        BonkRecentHit const* sample = nullptr;
        uint64 damage = 0;
        uint32 index = 0;
    };

    std::string SourceKey(BonkRecentHit const& hit)
    {
        return hit.source + "~" + hit.spell;
    }

    void SendLines(BonkPlayer* bonk, std::vector<std::string> const& items)
    {
        auto send = [bonk](std::string const& text)
        {
            if (!bonk->IsAddonReady())
                return;
            WorldPacket data(SMSG_HOA_MESSAGE);
            HoAWriteDeathEvents(data, text);
            bonk->GetPlayer()->GetSession()->SendPacket(&data);
        };
        std::string line;
        for (std::string const& item : items)
        {
            if (!line.empty() && line.size() + item.size() + 1 > BONK_RECAP_LINE_CHARS)
            {
                send(line);
                line.clear();
            }
            line += (line.empty() ? "" : ",") + item;
        }
        if (!line.empty())
            send(line);
    }

    std::vector<RecapSource*> RankSources(std::map<std::string, RecapSource>& byKey, RecapSource* killer)
    {
        std::vector<RecapSource*> ranked;
        for (auto& itr : byKey)
            ranked.push_back(&itr.second);
        std::sort(ranked.begin(), ranked.end(), [](RecapSource const* a, RecapSource const* b) { return a->damage > b->damage; });

        auto const shownEnd = ranked.begin() + std::min<size_t>(ranked.size(), BONK_RECAP_MAX_SOURCES);
        if (std::find(ranked.begin(), shownEnd, killer) == shownEnd)
            std::iter_swap(shownEnd - 1, std::find(ranked.begin(), ranked.end(), killer));

        for (size_t i = 0; i < ranked.size(); ++i)
            ranked[i]->index = uint32(std::min<size_t>(i, BONK_RECAP_MAX_SOURCES) + 1);
        return ranked;
    }

    std::vector<std::string> RecapEvents(std::deque<BonkRecentHit> const& hits, std::map<std::string, RecapSource>& byKey, uint32 windowStart, uint32 maxHealth)
    {
        std::vector<std::string> events;
        uint32 const lastSlot = BONK_RECAP_WINDOW_MS / BONK_RECAP_SLOT_MS;
        uint32 slotKey = UINT32_MAX;
        uint32 slotAmount = 0;
        uint32 slotHealth = 0;
        auto flush = [&]()
        {
            if (slotKey != UINT32_MAX)
                events.push_back(std::to_string(slotKey >> 8) + ":" + std::to_string(slotKey & 0xFF) + ":" + std::to_string(slotAmount) + ":" +
                    std::to_string(uint64(slotHealth) * 1000 / maxHealth));
        };
        for (BonkRecentHit const& hit : hits)
        {
            uint32 const elapsed = WorldTimer::getMSTimeDiff(windowStart, hit.ms);
            uint32 const slot = elapsed > BONK_RECAP_WINDOW_MS ? 0 : std::min(lastSlot, elapsed / BONK_RECAP_SLOT_MS);
            uint32 const key = (slot << 8) | (hit.heal ? 0 : byKey[SourceKey(hit)].index);
            if (key != slotKey)
            {
                flush();
                slotKey = key;
                slotAmount = 0;
            }
            slotAmount += hit.amount;
            slotHealth = hit.healthAfter;
        }
        flush();
        if (events.size() > BONK_RECAP_MAX_EVENTS)
            events.erase(events.begin(), events.end() - BONK_RECAP_MAX_EVENTS);
        return events;
    }

    void SendDeathRecap(Player* player, uint32 overkill)
    {
        std::deque<BonkRecentHit> hits;
        {
            std::lock_guard<std::mutex> guard(s_lock);
            hits = s_stats[player->GetObjectGuid()].recentHits;
        }
        if (hits.empty() || hits.back().heal)
            return;

        uint32 const maxHealth = std::max<uint32>(1, player->GetMaxHealth());
        std::map<std::string, RecapSource> byKey;
        uint64 taken = 0;
        uint64 healed = 0;
        for (BonkRecentHit const& hit : hits)
        {
            if (hit.heal)
            {
                healed += hit.amount;
                continue;
            }
            taken += hit.amount;
            RecapSource& source = byKey[SourceKey(hit)];
            source.sample = &hit;
            source.damage += hit.amount;
        }

        BonkRecentHit const& last = hits.back();
        BonkRecentHit const& first = hits.front();
        RecapSource* killer = &byKey[SourceKey(last)];
        std::vector<RecapSource*> const ranked = RankSources(byKey, killer);
        uint32 const startHealth = std::min(maxHealth, first.heal ? first.healthAfter - std::min(first.healthAfter, first.amount) : first.healthAfter + first.amount);

        BonkPlayer* bonk = player->GetBonkPlayer();
        if (bonk->IsAddonReady())
        {
            WorldPacket data(SMSG_HOA_MESSAGE);
            HoAWriteDeathRecap(data, maxHealth, startHealth * 1000 / maxHealth, killer->index, last.amount, overkill, taken, healed);
            player->GetSession()->SendPacket(&data);
        }

        uint64 othersDamage = 0;
        for (RecapSource const* source : ranked)
        {
            if (source->index > BONK_RECAP_MAX_SOURCES)
            {
                othersDamage += source->damage;
                continue;
            }
            if (!bonk->IsAddonReady())
                continue;
            BonkRecentHit const& sample = *source->sample;
            WorldPacket data(SMSG_HOA_MESSAGE);
            HoAWriteDeathSource(data, source->index, sample.icon, sample.source, sample.spell, KindTag(sample.kind), source->damage);
            player->GetSession()->SendPacket(&data);
        }
        if (othersDamage && bonk->IsAddonReady())
        {
            WorldPacket data(SMSG_HOA_MESSAGE);
            HoAWriteDeathSource(data, BONK_RECAP_MAX_SOURCES + 1, BONK_UNKNOWN_ICON, "Others", "", "", othersDamage);
            player->GetSession()->SendPacket(&data);
        }

        SendLines(bonk, RecapEvents(hits, byKey, last.ms - BONK_RECAP_WINDOW_MS, maxHealth));
    }
}

std::string BonkStats::DescribeDamageTypes(ObjectGuid player, uint32 spellId)
{
    std::string text = SchoolType(spellId);
    std::lock_guard<std::mutex> guard(s_lock);
    auto stats = s_stats.find(player);
    if (stats == s_stats.end())
        return text;
    auto dots = stats->second.dotBySpell.find(spellId);
    if (dots == stats->second.dotBySpell.end())
        return text;
    for (auto const& dot : dots->second)
        if (dot.second.damage)
            text += "/" + DamageType(dot.first) + ":" + std::to_string(dot.second.damage);
    return text;
}

void BonkStats::Reset(ObjectGuid player)
{
    std::lock_guard<std::mutex> guard(s_lock);
    s_stats[player] = BonkRunStats();
    s_bossBars.erase(player);
}

uint32 BonkStats::CountKill(ObjectGuid player, ObjectGuid enemy, BonkSpawnKind kind)
{
    std::lock_guard<std::mutex> guard(s_lock);
    BonkRunStats& stats = s_stats[player];
    if (kind < MAX_BONK_SPAWN_KIND)
        ++stats.kindKills[kind];

    uint32 spellId = 0;
    auto itr = stats.killingSpells.find(enemy);
    if (itr != stats.killingSpells.end())
    {
        spellId = itr->second;
        stats.killingSpells.erase(itr);
    }
    ++stats.bySpell[spellId].kills;
    auto dot = stats.killingDots.find(enemy);
    if (dot != stats.killingDots.end())
    {
        ++stats.dotBySpell[spellId][dot->second].kills;
        stats.killingDots.erase(dot);
    }
    return spellId;
}

BonkRunStats::Spell BonkStats::GetSpellStats(ObjectGuid player, uint32 spellId)
{
    std::lock_guard<std::mutex> guard(s_lock);
    auto stats = s_stats.find(player);
    if (stats == s_stats.end())
        return BonkRunStats::Spell();
    auto spell = stats->second.bySpell.find(spellId);
    return spell != stats->second.bySpell.end() ? spell->second : BonkRunStats::Spell();
}

namespace
{
    uint32 const BONK_SHAPESHIFT_CREDITS[] = { 1082, 6807, 16689 };
}

std::vector<uint32> BonkStats::GetWeaponSpells(BonkWeapon const& weapon)
{
    std::vector<uint32> spellIds;
    for (uint32 spellId : { weapon.spellId, weapon.altSpellId })
    {
        SpellEntry const* spellInfo = spellId ? sSpellMgr.GetSpellEntry(spellId) : nullptr;
        if (!spellInfo)
            continue;
        spellIds.push_back(spellId);
        for (uint32 i = 0; i < MAX_EFFECT_INDEX; ++i)
            if (spellInfo->EffectTriggerSpell[i])
                spellIds.push_back(spellInfo->EffectTriggerSpell[i]);
    }
    if (weapon.behavior == BONK_BEHAVIOR_SHAPESHIFT)
        spellIds.insert(spellIds.end(), std::begin(BONK_SHAPESHIFT_CREDITS), std::end(BONK_SHAPESHIFT_CREDITS));
    return spellIds;
}

uint64 BonkStats::TotalDamage(ObjectGuid guid)
{
    std::lock_guard<std::mutex> guard(s_lock);
    auto const stats = s_stats.find(guid);
    if (stats == s_stats.end())
        return 0;
    uint64 total = 0;
    for (auto const& spell : stats->second.bySpell)
        total += spell.second.damage;
    return total;
}

std::vector<BonkOtherSource> BonkStats::GetOtherSources(Player* player, std::set<uint32> const& shown)
{
    std::map<uint32, BonkRunStats::Spell> bySpell;
    {
        std::lock_guard<std::mutex> guard(s_lock);
        auto stats = s_stats.find(player->GetObjectGuid());
        if (stats == s_stats.end())
            return {};
        bySpell = stats->second.bySpell;
    }

    BonkPlayer* bonk = player->GetBonkPlayer();
    std::vector<BonkOtherSource> sources;
    for (auto const& itr : bySpell)
    {
        if (shown.count(itr.first) || (!itr.second.damage && !itr.second.kills))
            continue;
        BonkOtherSource source;
        source.spellId = itr.first;
        source.icon = "INV_Misc_QuestionMark";
        source.name = bonk->GetString(BONK_STRING_SPELL_NUMBERED, { std::to_string(itr.first) });
        if (!itr.first)
        {
            source.icon = "INV_Sword_04";
            source.name = "Melee";
        }
        else if (BonkKeywordInfo const* keyword = sBonkMgr.GetKeywordBySpell(itr.first))
        {
            source.icon = keyword->icon.empty() ? source.icon : keyword->icon;
            source.name = bonk->Localize(BONK_FIELD_KEYWORD_NAME, uint32(keyword->id), keyword->name);
        }
        else if (SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(itr.first))
            source.name = SpellNameFor(spellInfo, player->GetSession()->GetSessionDbLocaleIndex());
        source.damage = itr.second.damage;
        source.kills = itr.second.kills;
        source.type = DamageType(itr.first);
        sources.push_back(std::move(source));
    }
    return sources;
}

void BonkStats::SendSummary(Player* player, std::vector<BonkSummaryWeapon> const& weapons)
{
    BonkRunStats stats;
    {
        std::lock_guard<std::mutex> guard(s_lock);
        stats = s_stats[player->GetObjectGuid()];
    }

    BonkPlayer* bonk = player->GetBonkPlayer();
    if (!bonk->IsAddonReady())
        return;
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteRunSummary(data, stats.damageTaken, stats.kindKills[BONK_SPAWN_ELITE], stats.kindKills[BONK_SPAWN_MINIBOSS],
            stats.kindKills[BONK_SPAWN_BOSS]);
        player->GetSession()->SendPacket(&data);
    }

    std::set<uint32> sent;
    for (BonkSummaryWeapon const& weapon : weapons)
    {
        if (sent.count(weapon.spellId))
            continue;
        uint64 damage = 0;
        uint32 kills = 0;
        std::vector<uint32> const spellIds = weapon.spellIds.empty() ? std::vector<uint32>{ weapon.spellId } : weapon.spellIds;
        for (uint32 spellId : spellIds)
        {
            if (!sent.insert(spellId).second)
                continue;
            auto itr = stats.bySpell.find(spellId);
            if (itr == stats.bySpell.end())
                continue;
            damage += itr->second.damage;
            kills += itr->second.kills;
        }
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteSummaryWeapon(data, weapon.icon, weapon.name, weapon.level, weapon.maxLevel, weapon.evolved, damage, kills,
            SchoolType(weapon.spellId));
        player->GetSession()->SendPacket(&data);

        std::map<uint32, BonkRunStats::Spell> dots;
        for (uint32 spellId : spellIds)
        {
            auto itr = stats.dotBySpell.find(spellId);
            if (itr == stats.dotBySpell.end())
                continue;
            for (auto const& dot : itr->second)
            {
                dots[dot.first].damage += dot.second.damage;
                dots[dot.first].kills += dot.second.kills;
            }
        }
        for (auto const& dot : dots)
        {
            BonkKeywordInfo const* keyword = sBonkMgr.GetKeywordBySpell(dot.first);
            SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(dot.first);
            std::string const icon = keyword && !keyword->icon.empty() ? keyword->icon : "INV_Misc_QuestionMark";
            std::string name = keyword ? bonk->Localize(BONK_FIELD_KEYWORD_NAME, uint32(keyword->id), keyword->name) :
                SpellNameFor(spellInfo, player->GetSession()->GetSessionDbLocaleIndex());
            if (name.empty())
                name = bonk->GetString(BONK_STRING_SPELL_NUMBERED, { std::to_string(dot.first) });
            WorldPacket data(SMSG_HOA_MESSAGE);
            HoAWriteSummarySpell(data, icon, name, dot.second.damage, dot.second.kills);
            player->GetSession()->SendPacket(&data);
        }
    }

    for (BonkOtherSource const& other : GetOtherSources(player, sent))
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteSummaryWeapon(data, other.icon, other.name, 0, 0, false, other.damage, other.kills, other.type);
        player->GetSession()->SendPacket(&data);
    }

    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteSummaryEnd(data);
        player->GetSession()->SendPacket(&data);
    }
}

void BonkStats::UpdateBossBar(Player* player, uint32 diff)
{
    BossBar* bar;
    {
        std::lock_guard<std::mutex> guard(s_lock);
        bar = &s_bossBars[player->GetObjectGuid()];
    }
    bar->timer += diff;
    if (bar->timer < BONK_BOSS_BAR_MS)
        return;
    bar->timer = 0;

    struct ShownBoss
    {
        Creature* creature;
        bool isBoss;
        float distance;
    };
    std::vector<ShownBoss> shown;
    if (player->IsInWorld() && !player->IsBeingTeleported())
    {
        std::list<Creature*> creatures;
        MaNGOS::AnyUnitInObjectRangeCheck check(player, BONK_BOSS_BAR_RANGE);
        MaNGOS::CreatureListSearcher<MaNGOS::AnyUnitInObjectRangeCheck> searcher(creatures, check);
        Cell::VisitGridObjects(player, searcher, BONK_BOSS_BAR_RANGE);

        std::vector<Player*> const party = BonkCoop::RunGroupOf(player);
        for (Creature* creature : creatures)
        {
            if (!creature->IsAlive() || !creature->IsTemporarySummon())
                continue;
            ObjectGuid const summoner = static_cast<TemporarySummon*>(creature)->GetSummonerGuid();
            if (std::none_of(party.begin(), party.end(), [&](Player const* member) { return member->GetObjectGuid() == summoner; }))
                continue;
            BonkMobAI const* ai = dynamic_cast<BonkMobAI const*>(creature->AI());
            if (!ai || (ai->GetKind() != BONK_SPAWN_BOSS && ai->GetKind() != BONK_SPAWN_MINIBOSS))
                continue;
            shown.push_back({ creature, ai->GetKind() == BONK_SPAWN_BOSS, player->GetDistance(creature) });
        }
        std::sort(shown.begin(), shown.end(), [](ShownBoss const& a, ShownBoss const& b)
        {
            return a.isBoss != b.isBoss ? a.isBoss : a.distance < b.distance;
        });
        if (shown.size() > BONK_BOSS_BAR_MAX)
            shown.resize(BONK_BOSS_BAR_MAX);
    }

    std::string data;
    if (!shown.empty())
    {
        data += std::to_string(shown.size());
        for (ShownBoss const& entry : shown)
        {
            Creature* creature = entry.creature;
            BonkMobAI const* ai = static_cast<BonkMobAI const*>(creature->AI());
            data += "~" + player->GetBonkPlayer()->GetLocalName(creature) + "~" + std::to_string(ai->GetTrueHealth(creature->GetHealth())) + "~" +
                std::to_string(ai->GetTrueHealth(creature->GetMaxHealth())) + "~" + (entry.isBoss ? "boss" : "mini") + "~" +
                ai->GetAffixNames(player->GetBonkPlayer()->GetLocale()) + "~" + KeywordStacksText(player, creature) + "~" + BonkMobAI::GetUnitGuidText(creature);
        }
    }
    if (data == bar->lastLine)
        return;
    bar->lastLine = data;
    if (!player->GetBonkPlayer()->IsAddonReady())
        return;
    WorldPacket packet(SMSG_HOA_MESSAGE);
    HoAWriteBossBar(packet, data);
    player->GetSession()->SendPacket(&packet);
}

void BonkOnDamage(Unit* attacker, Unit* victim, uint32 damage, SpellEntry const* spellProto)
{
    if (!damage || attacker == victim)
        return;

    LogPausedHit(attacker, victim, damage, spellProto);

    uint32 const health = victim->GetHealth();
    uint32 const dealt = std::min(damage, health);

    bool const swing = !spellProto;
    SpellEntry const* const hitSpell = spellProto;
    Player* owner = nullptr;
    if (attacker->IsCreature() && !victim->IsPlayer())
        if (Player* hero = attacker->GetCharmerOrOwnerPlayerOrPlayerItself())
            if (uint32 const createdBy = attacker->GetUInt32Value(UNIT_CREATED_BY_SPELL))
            {
                owner = hero;
                spellProto = sSpellMgr.GetSpellEntry(createdBy);
            }

    if (Player* player = owner ? owner : attacker->ToPlayer())
    {
        if (!victim->IsCreature() || !InRun(player))
            return;

        BonkRun* run = player->GetBonkPlayer()->GetRun();
        std::vector<std::pair<uint32, uint32>> credits;
        if (spellProto)
            run->CreditDamageOverTime(victim, spellProto->Id, dealt, credits);
        uint32 const dotSpellId = !credits.empty() ? spellProto->Id : 0;
        uint32 const partSpellId = dotSpellId ? dotSpellId : owner ? 0 : run->GetMeterPartSpell();
        if (credits.empty())
            credits.emplace_back(spellProto ? spellProto->Id : 0, dealt);

        if (!owner)
        {
            run->OnTalentDamage(victim, spellProto);
            run->PlayMeleeHitFeel(victim, hitSpell);
        }
        if (damage >= health && !victim->GetInvincibilityHpThreshold())
        {
            run->OnKillingBlow(victim);
            run->PlayKillFeel(victim, damage, health);
            if (!owner && spellProto && !dotSpellId)
            {
                run->ResetOnKill(spellProto->Id);
                run->OnSpellKill(spellProto->Id);
            }
            if (owner && !dotSpellId)
                run->OnSummonKill(attacker, victim);
            if (dotSpellId)
                sBonkQuests.OnProgress(player, BONK_QUEST_DOT_KILLS, 0, 1);
        }
        else if (!dotSpellId)
        {
            run->OnWeaponHit(victim, spellProto);
            if (!owner)
                run->StaggerOnHit(victim);
        }
        if (owner && swing)
            run->OnPetBite(attacker->ToCreature(), victim);
        if (owner && attacker->GetEntry() != BONK_PROJECTILE && damage < health)
            run->ApplySummonHitKeyword(attacker, victim, hitSpell);
        if ((!owner || attacker->GetEntry() == BONK_PROJECTILE) && !dotSpellId)
        {
            double const trueDamage = double(BonkRun::GetTrueAmount(victim, damage));
            run->OnHeroHit(victim, trueDamage, spellProto);
        }
        if (!owner)
            run->CountThunderHit(spellProto);

        bool newBiggestHit = false;
        {
            std::lock_guard<std::mutex> guard(s_lock);
            BonkRunStats& stats = s_stats[player->GetObjectGuid()];
            for (auto const& credit : credits)
            {
                stats.bySpell[credit.first].damage += BonkRun::GetTrueAmount(victim, credit.second);
                if (partSpellId && credit.first != partSpellId)
                    stats.dotBySpell[credit.first][partSpellId].damage += BonkRun::GetTrueAmount(victim, credit.second);
            }
            uint64 const trueHit = BonkRun::GetTrueAmount(victim, damage);
            if (trueHit > stats.biggestHit)
            {
                stats.biggestHit = trueHit;
                newBiggestHit = true;
            }
            if (damage >= health)
            {
                stats.killingSpells[victim->GetObjectGuid()] = credits.front().first;
                if (partSpellId && credits.front().first != partSpellId)
                    stats.killingDots[victim->GetObjectGuid()] = partSpellId;
            }
        }
        if (newBiggestHit && run->IsSandbox())
            sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Bonk biggest hit: %s %llu from spell %u | %s", player->GetName(), (unsigned long long)BonkRun::GetTrueAmount(victim, damage), spellProto ? spellProto->Id : 0,
                run->DescribeBigHit(spellProto, victim).c_str());
    }
    else if (Player* player = victim->ToPlayer())
    {
        if (!InRun(player))
            return;

        {
            std::lock_guard<std::mutex> guard(s_lock);
            s_stats[player->GetObjectGuid()].damageTaken += dealt;
        }

        BonkRecentHit hit = DescribeHit(attacker, spellProto, player->GetSession()->GetSessionDbLocaleIndex());
        hit.amount = dealt;
        hit.healthAfter = health - dealt;
        PushRecentHit(player, std::move(hit));
        if (damage >= health)
            SendDeathRecap(player, damage - health);
    }
}

void BonkStats::RecordHeroHeal(Player* player, uint32 amount)
{
    if (!amount || !InRun(player))
        return;
    BonkRecentHit hit;
    hit.heal = true;
    hit.amount = amount;
    hit.healthAfter = player->GetHealth();
    PushRecentHit(player, std::move(hit));
}

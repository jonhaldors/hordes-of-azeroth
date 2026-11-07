#include "BonkSandbox.h"
#include "BonkLocale.h"
#include "BonkMgr.h"
#include "BonkMobAI.h"
#include "BonkPlayer.h"
#include "BonkRun.h"
#include "Chat.h"
#include "Creature.h"
#include "GossipDef.h"
#include "HoaProtocol.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "BonkTransmog.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "TemporarySummon.h"
#include "World.h"
#include "WorldSession.h"
#include "Utilities/Random.h"

#include <algorithm>
#include <cmath>
#include <iterator>
#include <set>
#include <string>
#include <vector>

namespace
{
    uint32 const BONK_SANDBOX_KEEPER = 900123;
    uint32 const BONK_SANDBOX_DUMMY  = 900124;
    uint32 const BONK_SANDBOX_MAP    = 3;
    float const BONK_SANDBOX_X       = 981.3f;
    float const BONK_SANDBOX_Y       = -2912.6f;
    float const BONK_SANDBOX_Z       = 91.7f;
    float const BONK_SANDBOX_O       = 2.94f;

    uint32 const BONK_TEXT_SANDBOX_CAMP   = 900012;
    uint32 const BONK_TEXT_SANDBOX_MENU   = 900013;
    uint32 const BONK_TEXT_SANDBOX_REFUSE = 900014;

    float const BONK_SANDBOX_KEEPER_BEHIND    = 3.0f;
    float const BONK_SANDBOX_FRONT_RANGE      = 15.0f;
    uint32 const BONK_SANDBOX_TICK_MS         = 500;
    uint32 const BONK_SANDBOX_SPAWNS_PER_TICK = 20;
    float const BONK_SANDBOX_ENEMY_DISTANCE   = 20.0f;
    uint32 const BONK_SANDBOX_CRYSTALS        = 100;
    float const BONK_SANDBOX_CRYSTAL_INNER    = 12.0f;
    float const BONK_SANDBOX_CRYSTAL_MARGIN   = 4.0f;
    float const BONK_SANDBOX_CRYSTAL_SPREAD   = 35.0f;
    uint32 const BONK_SANDBOX_PAGE            = 12;
    uint32 const BONK_SANDBOX_SPELL_PAGE      = 9;
    uint32 const BONK_SANDBOX_RANKS[]         = { 1, 5, 10, 15 };

    uint32 const BONK_DUMMY_REFILL_MS  = 3000;
    float const BONK_DUMMY_DISTANCE    = 12.0f;
    float const BONK_DUMMY_GRID_NEAR   = 10.0f;
    float const BONK_DUMMY_GRID_FAR    = 15.0f;
    float const BONK_DUMMY_SPACING     = 2.5f;
    uint32 const BONK_DUMMY_COLUMNS    = 5;
    float const BONK_DUMMY_ELITE_SCALE = 1.35f;
    float const BONK_DUMMY_BOSS_SCALE  = 1.8f;
    float const BONK_DEEP_DUMMY_HEALTH = 100.0f;
    float const BONK_DEEP_DUMMY_REFILL = 0.5f;
    uint32 const BONK_SANDBOX_DEFAULT_PACK = 30;
    uint32 const BONK_MELEE_PICK_TRIES     = 20;

    enum SandboxSender : uint32
    {
        SENDER_OPEN = 1,
        SENDER_ENTER,
        SENDER_DUMMY,
        SENDER_PACK,
        SENDER_ENEMY,
        SENDER_TOGGLE,
        SENDER_LEVELS,
        SENDER_SPELL_ADD,
        SENDER_SPELL_REPLACE,
        SENDER_SPELL_RANK,
        SENDER_SPELL_REMOVE,
        SENDER_EVOLVE,
        SENDER_PASSIVE,
        SENDER_CARD,
        SENDER_RESET,
        SENDER_LEAVE,
        SENDER_SET_LEVEL,
        SENDER_CROWD_DUMMY,
    };

    enum SandboxMenu : uint32
    {
        MENU_MAIN,
        MENU_DUMMIES,
        MENU_ENEMIES,
        MENU_ENEMY_LIST,
        MENU_LEVELS,
        MENU_SPELLS,
        MENU_SPELL,
        MENU_PASSIVES,
        MENU_CARDS,
        MENU_RESET,
    };

    enum SandboxToggle : uint32
    {
        TOGGLE_PASSIVE = 1,
        TOGGLE_UNKILLABLE,
        TOGGLE_GOD,
        TOGGLE_MOVES_OFF,
        TOGGLE_REACH_REPORT,
        TOGGLE_DEEP_DUMMIES,
    };

    enum SandboxReset : uint32
    {
        RESET_CLEAR = 1,
        RESET_HEAL,
        RESET_COOLDOWNS,
        RESET_DUMMIES,
        RESET_SPELLS,
    };

    enum SandboxEnemyType : uint32
    {
        ENEMY_CASTER,
        ENEMY_RANGED,
        ENEMY_CHARGER,
        ENEMY_ELITE,
        ENEMY_MINIBOSS,
        ENEMY_BOSS,
        MAX_ENEMY_TYPE
    };

    BonkString const ENEMY_TYPE_LABELS[MAX_ENEMY_TYPE] = { BONK_STRING_SANDBOX_ENEMY_CASTER, BONK_STRING_SANDBOX_ENEMY_RANGED,
        BONK_STRING_SANDBOX_ENEMY_CHARGER, BONK_STRING_SANDBOX_ENEMY_ELITE, BONK_STRING_SANDBOX_ENEMY_MINIBOSS, BONK_STRING_SANDBOX_ENEMY_BOSS };

    struct SandboxEnemy
    {
        uint32 entry = 0;
        std::string label;
    };

    uint32 MenuAction(SandboxMenu menu, uint32 page = 0, uint32 context = 0)
    {
        return uint32(menu) | (page << 8) | (context << 16);
    }

    SandboxMenu MenuOf(uint32 action) { return SandboxMenu(action & 0xFF); }
    uint32 PageOf(uint32 action) { return (action >> 8) & 0xFF; }
    uint32 ContextOf(uint32 action) { return action >> 16; }

    uint32 DummyAction(uint32 count, BonkSpawnKind kind) { return (uint32(kind) << 8) | count; }
    uint32 PairAction(uint32 high, uint32 low) { return (high << 16) | (low & 0xFFFF); }

    void AddItem(Player* player, uint8 icon, std::string const& text, uint32 sender, uint32 action)
    {
        player->PlayerTalkClass->GetGossipMenu().AddMenuItem(icon, text.c_str(), sender, action);
    }

    std::string Text(Player* player, BonkString id, std::vector<std::string> const& args = {})
    {
        return player->GetBonkPlayer()->GetString(id, args);
    }

    void AddBack(Player* player, SandboxMenu menu, uint32 page = 0, uint32 context = 0)
    {
        AddItem(player, GOSSIP_ICON_CHAT, Text(player, BONK_STRING_SANDBOX_BACK), SENDER_OPEN, MenuAction(menu, page, context));
    }

    std::string Toggled(Player* player, bool on, std::string const& label)
    {
        return Text(player, on ? BONK_STRING_SANDBOX_TOGGLE_ON : BONK_STRING_SANDBOX_TOGGLE_OFF, { label });
    }

    uint32 ClampPage(uint32 page, size_t total, uint32 pageSize = BONK_SANDBOX_PAGE)
    {
        uint32 const last = total ? uint32((total - 1) / pageSize) : 0;
        return std::min(page, last);
    }

    void AddPaging(Player* player, SandboxMenu menu, uint32 page, uint32 context, size_t total)
    {
        if (page > 0)
            AddItem(player, GOSSIP_ICON_CHAT, Text(player, BONK_STRING_SANDBOX_PREVIOUS_PAGE), SENDER_OPEN, MenuAction(menu, page - 1, context));
        if ((page + 1) * BONK_SANDBOX_PAGE < total)
            AddItem(player, GOSSIP_ICON_CHAT, Text(player, BONK_STRING_SANDBOX_NEXT_PAGE), SENDER_OPEN, MenuAction(menu, page + 1, context));
    }

    bool IsEnemyType(BonkMapCreature const& creature, SandboxEnemyType type)
    {
        BonkMob const* mob = sBonkMgr.GetMob(creature.entry);
        bool const hasAbilities = mob && !mob->abilities.empty();
        switch (type)
        {
            case ENEMY_CASTER:
                return creature.kind == BONK_SPAWN_NORMAL && creature.archetype == BONK_ARCHETYPE_CASTER && hasAbilities;
            case ENEMY_RANGED:
                return mob && mob->role == BONK_ROLE_RANGED && hasAbilities;
            case ENEMY_CHARGER:
                return creature.kind == BONK_SPAWN_NORMAL && creature.archetype == BONK_ARCHETYPE_CHARGER;
            case ENEMY_ELITE:
                return creature.kind == BONK_SPAWN_ELITE && hasAbilities;
            case ENEMY_MINIBOSS:
                return creature.kind == BONK_SPAWN_MINIBOSS && hasAbilities;
            case ENEMY_BOSS:
                return creature.kind == BONK_SPAWN_BOSS && hasAbilities;
            default:
                return false;
        }
    }

    std::vector<SandboxEnemy> ListEnemies(SandboxEnemyType type, BonkPlayer const* viewer = nullptr)
    {
        std::vector<SandboxEnemy> list;
        std::set<uint32> seen;
        for (auto const& itr : sBonkMgr.GetMaps())
            for (BonkMapCreature const& creature : itr.second.creatures)
            {
                if (!IsEnemyType(creature, type) || !seen.insert(creature.entry).second)
                    continue;
                if (CreatureInfo const* info = sObjectMgr.GetCreatureTemplate(creature.entry))
                {
                    std::string const name = viewer ? viewer->GetCreatureName(creature.entry, info->name) : info->name;
                    std::string const place = viewer ? viewer->Localize(BONK_FIELD_MAP_NAME, itr.second.id, itr.second.name) : itr.second.name;
                    list.push_back({ creature.entry, viewer ? viewer->GetString(BONK_STRING_SANDBOX_NAME_IN_PARENS, { name, place }) : name + " (" + place + ")" });
                }
            }
        return list;
    }

    BonkMapCreature const* FindMapCreature(uint32 entry)
    {
        for (auto const& itr : sBonkMgr.GetMaps())
            for (BonkMapCreature const& creature : itr.second.creatures)
                if (creature.entry == entry)
                    return &creature;
        return nullptr;
    }

    BonkMapCreature const* PickNormalCreature(BonkMap const& map)
    {
        uint32 total = 0;
        for (BonkMapCreature const& creature : map.creatures)
            if (creature.kind == BONK_SPAWN_NORMAL && !creature.flyer)
                total += creature.weight;
        if (!total)
            return nullptr;

        uint32 roll = urand(1, total);
        for (BonkMapCreature const& creature : map.creatures)
        {
            if (creature.kind != BONK_SPAWN_NORMAL || creature.flyer)
                continue;
            if (roll <= creature.weight)
                return &creature;
            roll -= creature.weight;
        }
        return nullptr;
    }

    float GroundHeight(Player const* player, float x, float y, float aboutZ)
    {
        float const z = player->GetMap()->GetHeight(x, y, aboutZ + 5.0f, true, 15.0f);
        return z > INVALID_HEIGHT ? z : aboutZ;
    }

    void AddMainItems(Player* player)
    {
        AddItem(player, GOSSIP_ICON_BATTLE, Text(player, BONK_STRING_SANDBOX_MENU_DUMMIES), SENDER_OPEN, MenuAction(MENU_DUMMIES));
        AddItem(player, GOSSIP_ICON_BATTLE, Text(player, BONK_STRING_SANDBOX_MENU_ENEMIES), SENDER_OPEN, MenuAction(MENU_ENEMIES));
        AddItem(player, GOSSIP_ICON_TRAINER, Text(player, BONK_STRING_SANDBOX_MENU_LEVELS), SENDER_OPEN, MenuAction(MENU_LEVELS));
        AddItem(player, GOSSIP_ICON_TRAINER, Text(player, BONK_STRING_SANDBOX_MENU_SPELLS), SENDER_OPEN, MenuAction(MENU_SPELLS));
        AddItem(player, GOSSIP_ICON_INTERACT_1, Text(player, BONK_STRING_SANDBOX_MENU_RESET), SENDER_OPEN, MenuAction(MENU_RESET));
        AddItem(player, GOSSIP_ICON_TAXI, Text(player, BONK_STRING_SANDBOX_MENU_LEAVE), SENDER_LEAVE, 0);
    }

    void AddDummyItems(Player* player, bool deep)
    {
        AddItem(player, GOSSIP_ICON_BATTLE, Text(player, BONK_STRING_SANDBOX_DUMMY_ONE), SENDER_DUMMY, DummyAction(1, BONK_SPAWN_NORMAL));
        AddItem(player, GOSSIP_ICON_BATTLE, Text(player, BONK_STRING_SANDBOX_DUMMY_ROW), SENDER_DUMMY, DummyAction(5, BONK_SPAWN_NORMAL));
        AddItem(player, GOSSIP_ICON_BATTLE, Text(player, BONK_STRING_SANDBOX_DUMMY_GRID), SENDER_DUMMY, DummyAction(20, BONK_SPAWN_NORMAL));
        AddItem(player, GOSSIP_ICON_BATTLE, Text(player, BONK_STRING_SANDBOX_DUMMY_CIRCLE), SENDER_CROWD_DUMMY, 20);
        AddItem(player, GOSSIP_ICON_BATTLE, Text(player, BONK_STRING_SANDBOX_DUMMY_ELITE), SENDER_DUMMY, DummyAction(1, BONK_SPAWN_ELITE));
        AddItem(player, GOSSIP_ICON_BATTLE, Text(player, BONK_STRING_SANDBOX_DUMMY_BOSS), SENDER_DUMMY, DummyAction(1, BONK_SPAWN_BOSS));
        AddItem(player, GOSSIP_ICON_INTERACT_1, Toggled(player, deep, Text(player, BONK_STRING_SANDBOX_DUMMY_DEEP)), SENDER_TOGGLE, TOGGLE_DEEP_DUMMIES);
        AddItem(player, GOSSIP_ICON_INTERACT_1, Text(player, BONK_STRING_SANDBOX_REFILL_DUMMIES), SENDER_RESET, RESET_DUMMIES);
        AddBack(player, MENU_MAIN);
    }

    void AddEnemyItems(Player* player, bool passive, bool unkillable, bool movesOff, bool reachReport)
    {
        for (uint32 count : { 10u, 30u, 100u })
            AddItem(player, GOSSIP_ICON_BATTLE, Text(player, BONK_STRING_SANDBOX_PACK, { std::to_string(count) }), SENDER_PACK, count);
        for (uint32 type = 0; type < MAX_ENEMY_TYPE; ++type)
        {
            size_t const choices = ListEnemies(SandboxEnemyType(type)).size();
            AddItem(player, GOSSIP_ICON_CHAT, Text(player, BONK_STRING_SANDBOX_NAME_IN_PARENS, { Text(player, ENEMY_TYPE_LABELS[type]), std::to_string(choices) }), SENDER_OPEN,
                MenuAction(MENU_ENEMY_LIST, 0, type));
        }
        AddItem(player, GOSSIP_ICON_INTERACT_1, Toggled(player, passive, Text(player, BONK_STRING_SANDBOX_ENEMIES_PASSIVE)), SENDER_TOGGLE, TOGGLE_PASSIVE);
        AddItem(player, GOSSIP_ICON_INTERACT_1, Toggled(player, unkillable, Text(player, BONK_STRING_SANDBOX_ENEMIES_UNKILLABLE)), SENDER_TOGGLE, TOGGLE_UNKILLABLE);
        AddItem(player, GOSSIP_ICON_INTERACT_1, Toggled(player, movesOff, Text(player, BONK_STRING_SANDBOX_ENEMY_MOVES_OFF)), SENDER_TOGGLE, TOGGLE_MOVES_OFF);
        AddItem(player, GOSSIP_ICON_INTERACT_1, Toggled(player, reachReport, Text(player, BONK_STRING_SANDBOX_REPORT_REACH)), SENDER_TOGGLE, TOGGLE_REACH_REPORT);
        AddBack(player, MENU_MAIN);
    }

    void AddEnemyList(Player* player, SandboxEnemyType type, uint32 page)
    {
        std::vector<SandboxEnemy> const list = ListEnemies(type, player->GetBonkPlayer());
        if (list.empty())
            AddItem(player, GOSSIP_ICON_CHAT, Text(player, BONK_STRING_SANDBOX_NO_ENEMIES), SENDER_OPEN, MenuAction(MENU_ENEMIES));
        page = ClampPage(page, list.size());
        size_t const end = std::min(list.size(), size_t(page + 1) * BONK_SANDBOX_PAGE);
        for (size_t i = size_t(page) * BONK_SANDBOX_PAGE; i < end; ++i)
            AddItem(player, GOSSIP_ICON_BATTLE, list[i].label, SENDER_ENEMY, list[i].entry);
        AddPaging(player, MENU_ENEMY_LIST, page, type, list.size());
        AddBack(player, MENU_ENEMIES);
    }

    void AddLevelItems(Player* player)
    {
        AddItem(player, GOSSIP_ICON_TRAINER, Text(player, BONK_STRING_SANDBOX_LEVEL_PLUS_ONE), SENDER_LEVELS, 1);
        AddItem(player, GOSSIP_ICON_TRAINER, Text(player, BONK_STRING_SANDBOX_LEVEL_PLUS_FIVE), SENDER_LEVELS, 5);
        AddItem(player, GOSSIP_ICON_TRAINER, Text(player, BONK_STRING_SANDBOX_LEVEL_PLUS_TEN), SENDER_LEVELS, 10);
        for (uint32 level : { 10u, 20u, 30u, 40u, 50u, 60u })
            AddItem(player, GOSSIP_ICON_TRAINER, Text(player, BONK_STRING_SANDBOX_SET_LEVEL, { std::to_string(level) }), SENDER_SET_LEVEL, level);
        AddItem(player, GOSSIP_ICON_INTERACT_1, Text(player, BONK_STRING_SANDBOX_SPAWN_CRYSTALS), SENDER_LEVELS, 0);
        AddBack(player, MENU_MAIN);
    }

    void AddResetItems(Player* player)
    {
        AddItem(player, GOSSIP_ICON_INTERACT_1, Text(player, BONK_STRING_SANDBOX_CLEAR_ALL), SENDER_RESET, RESET_CLEAR);
        AddItem(player, GOSSIP_ICON_INTERACT_1, Text(player, BONK_STRING_SANDBOX_FULL_HEAL), SENDER_RESET, RESET_HEAL);
        AddItem(player, GOSSIP_ICON_INTERACT_1, Text(player, BONK_STRING_SANDBOX_RESET_COOLDOWNS), SENDER_RESET, RESET_COOLDOWNS);
        AddItem(player, GOSSIP_ICON_INTERACT_1, Text(player, BONK_STRING_SANDBOX_REFILL_DUMMIES), SENDER_RESET, RESET_DUMMIES);
        AddItem(player, GOSSIP_ICON_INTERACT_1, Toggled(player, player->GetBonkPlayer()->IsTestGod(), Text(player, BONK_STRING_SANDBOX_GOD_MODE)), SENDER_TOGGLE, TOGGLE_GOD);
        AddBack(player, MENU_MAIN);
    }
}

namespace BonkSandbox
{
    bool IsAllowed(Player const* player)
    {
        return player && player->GetSession() && player->GetSession()->GetSecurity() >= SEC_GAMEMASTER;
    }

    bool IsHiddenFrom(Creature const* creature, Player const* viewer)
    {
        return creature->GetEntry() == BONK_SANDBOX_KEEPER && !IsAllowed(viewer);
    }
}

bool BonkPlayer::IsInSandbox() const
{
    return m_run && m_run->IsSandbox();
}

bool BonkPlayer::StartSandbox(std::string& error)
{
    if (!BonkSandbox::IsAllowed(m_player))
        error = GetString(BONK_STRING_SANDBOX_IS_FOR_GAME_MASTERS);
    else if (m_run)
        error = GetString(BONK_STRING_YOU_ARE_ALREADY_IN_RUN);
    else if (!IsAtCamp())
        error = GetString(BONK_STRING_GO_BACK_TO_INN_TO);
    else if (m_player->IsInCombat())
        error = GetString(BONK_STRING_CANT_ENTER_SANDBOX_IN_COMBAT);
    else if (m_player->IsTaxiFlying())
        error = GetString(BONK_STRING_CANT_ENTER_SANDBOX_WHILE_FLYING);
    else if (!IsPlayableClass(m_player->GetClass()) || !sBonkMgr.HasStarterSpell(m_player->GetClassMask()))
        error = GetString(BONK_STRING_CLASS_REWORKED_NO_SANDBOX, { GetClassName() });
    if (!error.empty())
        return false;

    BonkMap const* map = sBonkMgr.GetMap(BONK_SANDBOX_MAP);
    BonkTier const* tier = map ? sBonkMgr.GetTier(map->tierId) : nullptr;
    if (!tier)
    {
        std::vector<BonkTier const*> const& tiers = sBonkMgr.GetTiersInOrder();
        tier = tiers.empty() ? nullptr : tiers.front();
    }
    if (!map || map->creatures.empty() || !tier)
    {
        error = GetString(BONK_STRING_SANDBOX_MAP_IS_NOT_SET);
        return false;
    }

    bool const godBefore = m_testGod;
    m_testGod = true;
    m_run.reset(new BonkRun(m_player, *tier));
    m_run->MakeSandbox(godBefore);
    if (m_run->Begin(error))
        return true;

    m_run.reset();
    m_testGod = godBefore;
    m_player->SetCheatGod(godBefore);
    return false;
}

BonkMap const* BonkRun::GetSandboxMap() const
{
    BonkMap const* map = sBonkMgr.GetMap(BONK_SANDBOX_MAP);
    return map && !map->creatures.empty() ? map : nullptr;
}

bool BonkRun::TeleportToSandbox(std::string& error)
{
    if (!m_player->TeleportTo(m_map.mapId, BONK_SANDBOX_X, BONK_SANDBOX_Y, BONK_SANDBOX_Z + 0.5f, BONK_SANDBOX_O))
    {
        error = GetString(BONK_STRING_YOU_COULDNT_TRAVEL_TO_SANDBOX);
        return false;
    }
    m_state = STATE_ENTERING;
    m_enterTimer = 0;
    return true;
}

void BonkRun::StartSandbox()
{
    SendFullState();
    SummonSandboxKeeper();
    m_player->GetBonkPlayer()->Notify(BONK_STRING_WELCOME_TO_SANDBOX_TALK_TO);
}

void BonkRun::SummonSandboxKeeper()
{
    float const x = BONK_SANDBOX_X - BONK_SANDBOX_KEEPER_BEHIND * std::cos(BONK_SANDBOX_O);
    float const y = BONK_SANDBOX_Y - BONK_SANDBOX_KEEPER_BEHIND * std::sin(BONK_SANDBOX_O);
    float const z = GroundHeight(m_player, x, y, BONK_SANDBOX_Z);
    Creature* keeper = m_player->SummonCreature(BONK_SANDBOX_KEEPER, x, y, z, BONK_SANDBOX_O, TEMPSUMMON_MANUAL_DESPAWN, 0);
    m_sandboxKeeper = keeper ? keeper->GetObjectGuid() : ObjectGuid();
}

void BonkRun::UpdateSandbox(uint32 diff)
{
    m_sandboxTimer += diff;
    if (m_sandboxTimer < BONK_SANDBOX_TICK_MS)
        return;
    uint32 const elapsed = m_sandboxTimer;
    m_sandboxTimer = 0;

    PruneMobs();
    SpawnQueuedSandboxPack();
    RefillIdleDummies(elapsed);
    if (m_sandboxKeeper.IsEmpty() || !m_player->GetMap()->GetCreature(m_sandboxKeeper))
        SummonSandboxKeeper();
}

void BonkRun::SpawnQueuedSandboxPack()
{
    for (uint32 i = 0; i < BONK_SANDBOX_SPAWNS_PER_TICK && m_sandboxPackLeft; ++i)
    {
        --m_sandboxPackLeft;
        if (BonkMapCreature const* creature = PickSandboxPackCreature())
            SpawnMob(*creature);
    }
}

BonkMapCreature const* BonkRun::PickSandboxPackCreature() const
{
    BonkMapCreature const* creature = PickNormalCreature(m_map);
    for (uint32 tries = 1; m_sandboxPackMeleeOnly && creature && creature->archetype == BONK_ARCHETYPE_CASTER && tries < BONK_MELEE_PICK_TRIES; ++tries)
        creature = PickNormalCreature(m_map);
    return creature && m_sandboxPackMeleeOnly && creature->archetype == BONK_ARCHETYPE_CASTER ? nullptr : creature;
}

void BonkRun::RefillIdleDummies(uint32 elapsedMs)
{
    Map* map = m_player->GetMap();
    for (auto itr = m_sandboxDummies.begin(); itr != m_sandboxDummies.end();)
    {
        Creature* dummy = map->GetCreature(itr->first);
        if (!dummy || !dummy->IsAlive())
        {
            itr = m_sandboxDummies.erase(itr);
            continue;
        }

        SandboxDummy& state = itr->second;
        uint32 const health = dummy->GetHealth();
        if (m_sandboxDeepDummies && health < uint32(dummy->GetMaxHealth() * BONK_DEEP_DUMMY_REFILL))
        {
            dummy->SetHealth(dummy->GetMaxHealth());
            state.health = dummy->GetHealth();
            state.idleMs = 0;
        }
        else if (health != state.health)
        {
            state.health = health;
            state.idleMs = 0;
        }
        else if (health < dummy->GetMaxHealth())
        {
            state.idleMs += elapsedMs;
            if (state.idleMs >= BONK_DUMMY_REFILL_MS)
            {
                dummy->SetHealth(dummy->GetMaxHealth());
                state.health = dummy->GetHealth();
                state.idleMs = 0;
            }
        }
        ++itr;
    }
}

void BonkRun::PrepareSandboxMob(Creature* mob)
{
    BonkMobAI* ai = dynamic_cast<BonkMobAI*>(mob->AI());
    if (mob->GetEntry() == BONK_SANDBOX_DUMMY)
    {
        mob->SetInvincibilityHpThreshold(1);
        if (ai)
            ai->SetStationary();
        m_sandboxDummies[mob->GetObjectGuid()].health = mob->GetHealth();
        return;
    }

    if (m_sandboxUnkillable)
        mob->SetInvincibilityHpThreshold(1);
    if (m_sandboxPassive && ai)
        ai->SetPassive(true);
    if (m_sandboxMovesOff && ai)
        ai->SetMovesOff(true);
}

void BonkRun::ReviveInSandbox()
{
    m_player->ResurrectPlayer(1.0f);
    m_player->SpawnCorpseBones();
    m_player->GetBonkPlayer()->Notify(BONK_STRING_YOU_FELL_SO_SANDBOX_BROUGHT);
}

void BonkRun::EndSandbox()
{
    if (Map* map = m_player->FindMap())
        if (Creature* keeper = map->GetCreature(m_sandboxKeeper))
            keeper->DespawnOrUnsummon();
    m_sandboxKeeper.Clear();
    m_sandboxDummies.clear();
    m_sandboxPackLeft = 0;

    m_player->GetBonkPlayer()->SetTestGod(m_sandboxGodBefore);
    m_player->SetCheatGod(m_sandboxGodBefore);
}

void BonkRun::LeaveSandbox()
{
    if (m_state == STATE_FINISHED || m_state == STATE_ENDING)
        return;

    BonkPlayer* bonk = m_player->GetBonkPlayer();
    if (m_state == STATE_RUNNING)
    {
        if (bonk->IsAddonReady())
        {
            WorldPacket data(SMSG_HOA_MESSAGE);
            HoAWriteRunEnd(data, true, m_totalMs / IN_MILLISECONDS, m_kills, 0, uint8(m_player->GetLevel()), m_stage, 0,
                false, false, 0, 0, "", 0);
            m_player->GetSession()->SendPacket(&data);
        }
        else
            ChatHandler(m_player).SendSysMessage(GetString(BONK_STRING_SANDBOX_YOU_LEFT).c_str());
    }
    Exit();
}

float BonkRun::GetSandboxFront() const
{
    Creature const* keeper = m_sandboxKeeper.IsEmpty() ? nullptr : m_player->GetMap()->GetCreature(m_sandboxKeeper);
    if (keeper && keeper->IsWithinDistInMap(m_player, BONK_SANDBOX_FRONT_RANGE) && keeper->GetDistance2d(m_player) > 1.0f)
        return keeper->GetAngle(m_player);
    return m_player->GetOrientation();
}

namespace
{
    float const BONK_CROWD_DUMMY_FIRST_RING = 3.0f;
    float const BONK_CROWD_DUMMY_RING_STEP  = 3.0f;
    float const BONK_CROWD_DUMMY_SPACING    = 2.5f;
    uint32 const BONK_CROWD_DUMMY_MAX       = 30;
}

bool BonkRun::GetSandboxDummySpot(uint32 index, uint32 count, float ringRadius, float& x, float& y) const
{
    float const heroX = m_player->GetPositionX();
    float const heroY = m_player->GetPositionY();
    if (ringRadius < 0.0f)
    {
        GetCrowdDummySpot(index, x, y);
        return true;
    }
    if (ringRadius > 0.0f)
    {
        float const angle = 2.0f * M_PI_F * index / count;
        x = heroX + ringRadius * std::cos(angle);
        y = heroY + ringRadius * std::sin(angle);
        return true;
    }

    float const front = GetSandboxFront();
    uint32 const columns = std::min(count, BONK_DUMMY_COLUMNS);
    uint32 const rows = (count + columns - 1) / columns;
    uint32 const row = index / columns;
    uint32 const column = index % columns;
    float const ahead = rows > 1 ? BONK_DUMMY_GRID_NEAR + (BONK_DUMMY_GRID_FAR - BONK_DUMMY_GRID_NEAR) * row / float(rows - 1) : BONK_DUMMY_DISTANCE;
    float const side = (float(column) - float(columns - 1) / 2.0f) * BONK_DUMMY_SPACING;
    x = heroX + ahead * std::cos(front) - side * std::sin(front);
    y = heroY + ahead * std::sin(front) + side * std::cos(front);
    return true;
}

void BonkRun::GetCrowdDummySpot(uint32 index, float& x, float& y) const
{
    float radius = BONK_CROWD_DUMMY_FIRST_RING;
    uint32 first = 0;
    for (;;)
    {
        uint32 const capacity = std::max(1u, uint32(2.0f * M_PI_F * radius / BONK_CROWD_DUMMY_SPACING));
        if (index < first + capacity)
        {
            float const turn = (index - first) / float(capacity) + (radius / BONK_CROWD_DUMMY_RING_STEP) * 0.5f / float(capacity);
            float const angle = 2.0f * M_PI_F * turn;
            x = m_player->GetPositionX() + radius * std::cos(angle);
            y = m_player->GetPositionY() + radius * std::sin(angle);
            return;
        }
        first += capacity;
        radius += BONK_CROWD_DUMMY_RING_STEP;
    }
}

void BonkRun::SpawnSandboxDummies(uint32 count, BonkSpawnKind kind, float ringRadius)
{
    if (!count)
        return;

    float const heroZ = m_player->GetPositionZ();

    BonkMapCreature dummy;
    dummy.entry = BONK_SANDBOX_DUMMY;
    dummy.kind = kind;
    dummy.archetype = BONK_ARCHETYPE_GRUNT;
    dummy.scale = kind == BONK_SPAWN_BOSS ? BONK_DUMMY_BOSS_SCALE : kind == BONK_SPAWN_ELITE ? BONK_DUMMY_ELITE_SCALE : 1.0f;
    dummy.healthMultiplier = m_sandboxDeepDummies ? BONK_DEEP_DUMMY_HEALTH : 1.0f;

    uint32 spawned = 0;
    for (uint32 i = 0; i < count; ++i)
    {
        float x = 0.0f, y = 0.0f;
        GetSandboxDummySpot(i, count, ringRadius, x, y);
        BonkMobAI::SetNextAffixCount(0);
        if (SpawnMobAt(dummy, x, y, GroundHeight(m_player, x, y, heroZ)))
            ++spawned;
        BonkMobAI::SetNextAffixCount(-1);
    }

    BonkPlayer* bonk = m_player->GetBonkPlayer();
    if (!spawned)
        bonk->Notify(BONK_STRING_THERE_IS_NO_ROOM_FOR);
    else if (spawned == 1)
        bonk->Notify(kind == BONK_SPAWN_BOSS ? BONK_STRING_BOSS_TRAINING_DUMMY_READY : kind == BONK_SPAWN_ELITE ? BONK_STRING_ELITE_TRAINING_DUMMY_READY :
            BONK_STRING_TRAINING_DUMMY_READY);
    else
        bonk->Notify(kind == BONK_SPAWN_BOSS ? BONK_STRING_BOSS_TRAINING_DUMMIES_READY : kind == BONK_SPAWN_ELITE ? BONK_STRING_ELITE_TRAINING_DUMMIES_READY :
            BONK_STRING_TRAINING_DUMMIES_READY, { std::to_string(spawned) });
}

void BonkRun::QueueSandboxPack(uint32 count, bool meleeOnly)
{
    m_sandboxPackMeleeOnly = meleeOnly;
    PruneMobs();
    uint32 const busy = uint32(m_mobs.size()) + m_sandboxPackLeft;
    uint32 const room = m_tier.maxAlive > busy ? m_tier.maxAlive - busy : 0;
    uint32 const queued = std::min(count, room);
    m_sandboxPackLeft += queued;
    m_player->GetBonkPlayer()->Notify(queued ? BONK_STRING_ENEMIES_ON_THEIR_WAY : BONK_STRING_SANDBOX_IS_FULL, { std::to_string(queued) });
}

Creature* BonkRun::SpawnSandboxEnemy(uint32 entry)
{
    BonkMapCreature const* creature = FindMapCreature(entry);
    if (!creature)
    {
        m_player->GetBonkPlayer()->Notify(BONK_STRING_THAT_ENEMY_IS_NOT_ON);
        return nullptr;
    }

    float x, y, z;
    if (!FindSpawnPositionAt(GetSandboxFront(), BONK_SANDBOX_ENEMY_DISTANCE, x, y, z) &&
        !FindMobPosition(x, y, z, m_map.spawnMinDistance, m_map.spawnMaxDistance))
    {
        m_player->GetBonkPlayer()->Notify(BONK_STRING_THERE_IS_NO_ROOM_FOR_IT);
        return nullptr;
    }
    Creature* mob = SpawnMobAt(*creature, x, y, z);
    if (mob)
        m_player->GetBonkPlayer()->Notify(BONK_STRING_ARRIVED, { std::string(mob->GetName()) });
    return mob;
}

std::vector<Creature*> BonkRun::GetSandboxBosses() const
{
    std::vector<Creature*> bosses;
    Map* map = m_player->GetMap();
    for (ObjectGuid const& guid : m_mobs)
    {
        Creature* mob = map->GetCreature(guid);
        BonkMobAI const* ai = mob && mob->IsAlive() ? dynamic_cast<BonkMobAI const*>(mob->AI()) : nullptr;
        if (ai && (ai->GetKind() == BONK_SPAWN_BOSS || ai->GetKind() == BONK_SPAWN_MINIBOSS))
            bosses.push_back(mob);
    }
    return bosses;
}

void BonkRun::ListSandboxBosses(BonkSpawnKind kind) const
{
    ChatHandler chat(m_player);
    std::set<uint32> seen;
    for (auto const& itr : sBonkMgr.GetMaps())
    {
        std::string line;
        for (BonkMapCreature const& creature : itr.second.creatures)
        {
            if (creature.kind != kind || !seen.insert(creature.entry).second)
                continue;
            if (CreatureInfo const* info = sObjectMgr.GetCreatureTemplate(creature.entry))
                line += (line.empty() ? "" : ", ") + info->name + " " + std::to_string(creature.entry);
        }
        if (!line.empty())
            chat.SendSysMessage((itr.second.name + ": " + line).c_str());
    }
}

void BonkRun::DescribeSandboxBoss(Creature const* mob) const
{
    ChatHandler chat(m_player);
    char line[512];
    snprintf(line, sizeof(line), "%s has %u health (%.0f%% of a stage boss's). Its moves, for .bonk sandbox ability <number>:",
        mob->GetName(), mob->GetMaxHealth(), 100.0f * mob->GetMaxHealth() / std::max(1u, GetSpawnHealth(BONK_SPAWN_BOSS, BONK_ARCHETYPE_GRUNT, 1.0f)));
    chat.SendSysMessage(line);
    BonkMob const* info = sBonkMgr.GetMob(mob->GetEntry());
    if (!info || info->abilities.empty())
    {
        chat.SendSysMessage("It has no moves.");
        return;
    }
    uint32 number = 0;
    for (BonkMobAbility const& ability : info->abilities)
    {
        std::string const name = ability.label.empty() ? "spell " + std::to_string(ability.spellId) : ability.label;
        snprintf(line, sizeof(line), "%u. %s (every %.0f s, %.0f-%.0f yd%s)", ++number, name.c_str(), ability.cooldownMs / 1000.0f,
            ability.minRange, ability.maxRange, ability.belowHealth < 100.0f ? (", below " + std::to_string(int32(ability.belowHealth)) + "% health").c_str() : "");
        chat.SendSysMessage(line);
    }
}

bool BonkRun::RunSandboxBossVerb(std::string const& verb, uint32 first, std::string& error)
{
    BonkSpawnKind const kind = verb == "miniboss" ? BONK_SPAWN_MINIBOSS : BONK_SPAWN_BOSS;
    if (verb == "boss" || verb == "miniboss")
    {
        if (!first)
        {
            ListSandboxBosses(kind);
            return true;
        }
        Creature* mob = SpawnSandboxEnemy(first);
        BonkMobAI const* ai = mob ? dynamic_cast<BonkMobAI const*>(mob->AI()) : nullptr;
        if (ai && ai->GetKind() != BONK_SPAWN_BOSS && ai->GetKind() != BONK_SPAWN_MINIBOSS)
            ChatHandler(m_player).SendSysMessage(GetString(BONK_STRING_SANDBOX_NOT_A_BOSS).c_str());
        if (mob)
            DescribeSandboxBoss(mob);
        return mob != nullptr;
    }

    std::vector<Creature*> const bosses = GetSandboxBosses();
    if (bosses.empty())
    {
        error = GetString(BONK_STRING_NO_BOSS_IS_HERE_USE);
        return false;
    }
    if (verb == "bosshealth" && !first)
    {
        for (Creature* mob : bosses)
            if (BonkMobAI const* ai = dynamic_cast<BonkMobAI const*>(mob->AI()))
                m_player->GetBonkPlayer()->Notify(BONK_STRING_SANDBOX_BOSS_TRUE_HEALTH, { mob->GetName(), std::to_string(ai->GetTrueHealth(mob->GetHealth())),
                    std::to_string(ai->GetTrueHealth(mob->GetMaxHealth())), std::to_string(mob->GetHealth()), std::to_string(ai->GetHealthOverflow()) });
        return true;
    }
    if (verb == "bosshealth")
    {
        float const percent = float(std::max(1u, std::min(first, 100u)));
        for (Creature* mob : bosses)
            mob->SetHealthPercent(percent);
        m_player->GetBonkPlayer()->Notify(BONK_STRING_BOSSES_HERE_ARE_AT_HEALTH, { std::to_string(int32(percent)) });
        return true;
    }
    for (Creature* mob : bosses)
        if (BonkMobAI* ai = dynamic_cast<BonkMobAI*>(mob->AI()))
            if (!ai->ForceAbility(first))
            {
                error = GetString(BONK_STRING_ENEMY_HAS_NO_MOVE, { m_player->GetBonkPlayer()->GetLocalName(mob), std::to_string(first) });
                return false;
            }
    return true;
}

void BonkRun::ToggleSandbox(uint32 toggle)
{
    BonkPlayer* bonk = m_player->GetBonkPlayer();
    if (toggle == TOGGLE_GOD)
    {
        bool const on = !bonk->IsTestGod();
        bonk->SetTestGod(on);
        m_player->SetCheatGod(on);
        bonk->Notify(on ? BONK_STRING_GOD_MODE_ON : BONK_STRING_GOD_MODE_OFF);
        return;
    }
    if (toggle == TOGGLE_DEEP_DUMMIES)
    {
        m_sandboxDeepDummies = !m_sandboxDeepDummies;
        bonk->Notify(m_sandboxDeepDummies ? BONK_STRING_DEEP_DUMMIES_ON : BONK_STRING_DEEP_DUMMIES_OFF);
        return;
    }
    if (toggle == TOGGLE_REACH_REPORT)
    {
        m_sandboxReachReport = !m_sandboxReachReport;
        bonk->Notify(m_sandboxReachReport ? BONK_STRING_REACH_REPORT_ON : BONK_STRING_REACH_REPORT_OFF);
        return;
    }
    if (toggle == TOGGLE_MOVES_OFF)
    {
        m_sandboxMovesOff = !m_sandboxMovesOff;
        Map* map = m_player->GetMap();
        for (ObjectGuid const& guid : m_mobs)
            if (Creature* mob = map->GetCreature(guid))
                if (BonkMobAI* ai = dynamic_cast<BonkMobAI*>(mob->AI()))
                    ai->SetMovesOff(m_sandboxMovesOff);
        bonk->Notify(m_sandboxMovesOff ? BONK_STRING_ENEMY_MOVES_OFF : BONK_STRING_ENEMY_MOVES_ON);
        return;
    }
    if (toggle != TOGGLE_PASSIVE && toggle != TOGGLE_UNKILLABLE)
        return;

    bool& setting = toggle == TOGGLE_PASSIVE ? m_sandboxPassive : m_sandboxUnkillable;
    setting = !setting;
    Map* map = m_player->GetMap();
    for (ObjectGuid const& guid : m_mobs)
    {
        Creature* mob = map->GetCreature(guid);
        if (!mob || !mob->IsAlive() || mob->GetEntry() == BONK_SANDBOX_DUMMY)
            continue;
        if (toggle == TOGGLE_UNKILLABLE)
            mob->SetInvincibilityHpThreshold(setting ? 1 : 0);
        else if (BonkMobAI* ai = dynamic_cast<BonkMobAI*>(mob->AI()))
            ai->SetPassive(setting);
    }

    if (toggle == TOGGLE_PASSIVE)
        bonk->Notify(setting ? BONK_STRING_ENEMIES_PASSIVE_ON : BONK_STRING_ENEMIES_PASSIVE_OFF);
    else
        bonk->Notify(setting ? BONK_STRING_ENEMIES_UNKILLABLE_ON : BONK_STRING_ENEMIES_UNKILLABLE_OFF);
}

void BonkRun::ReportSandboxSwing(Creature const* mob) const
{
    if (!m_sandbox || !m_sandboxReachReport)
        return;
    float const dx = mob->GetPositionX() - m_heroNow.x;
    float const dy = mob->GetPositionY() - m_heroNow.y;
    float const reach = mob->GetCombatReachToTarget(m_player, false, 0.0f);
    ChatHandler(m_player).PSendSysMessage("%s swings from %.1f yd (melee reach %.1f yd).", mob->GetName(), std::sqrt(dx * dx + dy * dy), reach);
}

void BonkRun::GiveSandboxLevels(uint32 levels)
{
    uint32 const maxLevel = sWorld.getConfig(CONFIG_UINT32_MAX_PLAYER_LEVEL);
    uint32 const before = m_player->GetLevel() + m_overcapLevel;
    for (uint32 i = 0; i < levels; ++i)
    {
        uint32 const next = GetNextLevelXp();
        uint32 const have = m_player->GetLevel() >= maxLevel ? m_overcapXp : m_player->GetUInt32Value(PLAYER_XP);
        if (!next || next <= have)
            break;
        GiveExperience(next - have);
    }

    uint32 const after = m_player->GetLevel() + m_overcapLevel;
    m_player->GetBonkPlayer()->Notify(after > before ? BONK_STRING_YOU_ARE_NOW_LEVEL : BONK_STRING_CANT_GAIN_MORE_LEVELS, { std::to_string(after) });
}

void BonkRun::SetSandboxLevel(uint32 level)
{
    uint32 const maxLevel = sWorld.getConfig(CONFIG_UINT32_MAX_PLAYER_LEVEL);
    level = std::max(1u, std::min(level, maxLevel));
    m_overcapLevel = 0;
    m_overcapXp = 0;
    m_player->GiveLevel(level);
    m_player->SetUInt32Value(PLAYER_XP, 0);
    m_lastLevel = m_player->GetLevel();
    m_player->SetHealth(m_player->GetMaxHealth());
    SendState();
    m_player->GetBonkPlayer()->Notify(BONK_STRING_YOU_ARE_NOW_LEVEL, { std::to_string(m_player->GetLevel()) });
}

void BonkRun::SpawnSandboxCrystals(Creature const* keeper)
{
    uint32 const level = m_player->GetLevel() + m_overcapLevel;
    float const killsForLevel = 4.0f + 1.5f * level + 0.05f * level * level;
    float const growth = 1.0f + GetPassiveTotal(BONK_PASSIVE_GROWTH) / 100.0f;
    BonkArchetypeInfo const& grunt = sBonkMgr.GetArchetype(BONK_ARCHETYPE_GRUNT);
    uint32 const xp = std::max(1u, uint32(std::ceil(GetNextLevelXp() / killsForLevel * grunt.experience * growth)));

    WorldObject const* center = keeper ? static_cast<WorldObject const*>(keeper) : m_player;
    float const centerX = center->GetPositionX();
    float const centerY = center->GetPositionY();
    float const centerZ = center->GetPositionZ();
    float const inner = std::max(BONK_SANDBOX_CRYSTAL_INNER,
        GetMagnetRange() + m_player->GetDistance2d(centerX, centerY) + BONK_SANDBOX_CRYSTAL_MARGIN);
    float const outer = inner + BONK_SANDBOX_CRYSTAL_SPREAD;
    for (uint32 i = 0; i < BONK_SANDBOX_CRYSTALS; ++i)
    {
        float const angle = frand(0.0f, 2.0f * M_PI_F);
        float const distance = std::sqrt(frand(inner * inner, outer * outer));
        float const x = centerX + distance * std::cos(angle);
        float const y = centerY + distance * std::sin(angle);
        SpawnOrb(x, y, GroundHeight(m_player, x, y, centerZ), xp, grunt.orb);
    }
    m_player->GetBonkPlayer()->Notify(keeper ? BONK_STRING_EXPERIENCE_CRYSTALS_AROUND : BONK_STRING_EXPERIENCE_CRYSTALS_SURROUND_YOU,
        { keeper ? m_player->GetBonkPlayer()->GetLocalName(keeper) : std::string() });
}

BonkRun::OwnedWeapon* BonkRun::FindSandboxSpell(uint32 baseId)
{
    if (!baseId)
        return nullptr;
    auto itr = std::find_if(m_weapons.begin(), m_weapons.end(), [baseId](OwnedWeapon const& owned)
    {
        return owned.weapon.id == baseId || owned.weapon.evolvesFrom == baseId;
    });
    return itr != m_weapons.end() ? &*itr : nullptr;
}

bool BonkRun::AddSandboxGlyph(uint32 glyphId, std::string& error)
{
    BonkGlyph const* glyph = sBonkMgr.GetGlyph(glyphId);
    if (!glyph)
    {
        error = GetString(BONK_STRING_THAT_GLYPH_DOES_NOT_EXIST);
        return false;
    }
    if (std::find(m_glyphs.begin(), m_glyphs.end(), glyph) != m_glyphs.end())
    {
        error = GetString(BONK_STRING_YOU_ALREADY_HAVE_THAT_GLYPH);
        return false;
    }
    TakeGlyph(*glyph);
    m_player->GetBonkPlayer()->Notify(BONK_STRING_YOU_GAINED, { Localize(BONK_FIELD_GLYPH_NAME, glyph->id, glyph->name) });
    return true;
}

void BonkRun::SetSandboxTalent(uint32 nodeId, uint32 rank)
{
    m_sandboxTalents[nodeId] = uint8(std::min(rank, 255u));
    m_mastery = sBonkMastery.Evaluate(m_sandboxTalents);
    ApplyPassives();
    HealInSandbox();
}

bool BonkRun::SetSandboxBenchItem(uint32 entry, std::string& error)
{
    if (!entry)
        m_sandboxBenchItems.clear();
    else if (!sBonkMgr.GetItemStat(entry))
    {
        error = GetString(BONK_STRING_ITEM_HAS_NO_BONK_STATS, { std::to_string(entry) });
        return false;
    }
    else
        m_sandboxBenchItems.push_back(entry);
    UpdateGear();
    ApplyPassives();
    HealInSandbox();
    return true;
}

void BonkRun::SetSandboxTraining(uint32 rank)
{
    m_bonuses = BonkRunBonuses();
    for (auto const& itr : sBonkMgr.GetUpgrades())
        if (itr.second.layout.tree == BONK_TRAINING_TREE && itr.second.utility < 0)
            m_bonuses.passives[itr.second.effect] += itr.second.valuePerRank * std::min<uint32>(rank, itr.second.maxRank);
    ApplyPassives();
    HealInSandbox();
}

bool BonkRun::SetSandboxTier(uint32 tierId, uint32 bandLevel, std::string& error)
{
    BonkTier const* tier = sBonkMgr.GetTier(tierId);
    if (!tier)
    {
        error = GetString(BONK_STRING_THAT_DIFFICULTY_DOES_NOT_EXIST);
        return false;
    }
    m_tier = *tier;
    uint32 const band = tier->IsEndlessLevels() ? std::max(1u, bandLevel) : std::max(1u, std::min(bandLevel, tier->levels));
    m_difficultyLevel = tier->firstLevel + band - 1;
    m_levelRow = sBonkMgr.GetLevel(*tier, band);
    m_stage = 1;
    m_player->GetBonkPlayer()->Notify(BONK_STRING_SANDBOX_ENEMIES_NOW_FIGHT_AS, { m_player->GetBonkPlayer()->GetLevelName(m_difficultyLevel), std::to_string(m_stage) });
    return true;
}

void BonkRun::ReportSandboxVitals()
{
    uint32 const maxHealth = std::max(1u, m_player->GetMaxHealth());
    m_player->GetBonkPlayer()->Notify("vitals hp " + std::to_string(m_player->GetHealth() * 100 / maxHealth) +
        " shield " + std::to_string(uint64(m_spellShield) * 100 / maxHealth) +
        " taken " + std::to_string(m_damageTaken) + " absorbed " + std::to_string(m_damageAbsorbed) +
        " deaths " + std::to_string(m_sandboxDeaths));
}

bool BonkRun::AddSandboxCards(uint32 cardId, uint32 copies, std::string& error)
{
    BonkCard const* card = sBonkMgr.GetCard(cardId);
    if (!card)
    {
        error = GetString(BONK_STRING_THAT_CARD_DOES_NOT_EXIST);
        return false;
    }
    for (uint32 i = 0; i < copies && error.empty(); ++i)
    {
        if (card->maxCopies && GetCardCopies(cardId) >= card->maxCopies)
            break;
        GiveCard(cardId, error);
    }
    return error.empty();
}

bool BonkRun::AddSandboxSpell(uint32 baseId, std::string& error)
{
    BonkWeapon const* base = sBonkMgr.GetWeapon(baseId);
    if (!base || !ForceEvolve(baseId, error))
        return false;
    if (UsesShotSources())
        WarmShotSources();
    m_player->GetBonkPlayer()->Notify(BONK_STRING_YOU_LEARNED, { Localize(BONK_FIELD_WEAPON_NAME, base->id, base->name) });
    return true;
}

void BonkRun::SetSandboxRank(uint32 baseId, uint32 rank, bool epicRoundRobin)
{
    OwnedWeapon* owned = FindSandboxSpell(baseId);
    if (!owned || !rank)
        return;

    owned->rank = 1;
    owned->damageBonus = 0.0f;
    std::fill(std::begin(owned->upgrades), std::end(owned->upgrades), 0.0f);
    owned->rarities.clear();
    size_t nextUpgrade = 0;
    while (owned->rank < rank)
    {
        Offer step;
        step.id = owned->weapon.id;
        step.newLevel = owned->rank + 1;
        step.rarity = epicRoundRobin ? BONK_RARITY_EPIC : RollRarity(BONK_RARITY_COMMON);
        step.step = BONK_STEP_RANK;
        if (epicRoundRobin)
            PickUpgradesInTurn(*owned, step, nextUpgrade);
        else
            RollUpgrades(*owned, step);
        ApplyStep(*owned, step);
    }
    SendLoadout();
    m_player->GetBonkPlayer()->Notify(BONK_STRING_NOW_RANK, { Localize(BONK_FIELD_WEAPON_NAME, owned->weapon.id, owned->weapon.name), std::to_string(owned->rank) });
}

void BonkRun::PickUpgradesInTurn(OwnedWeapon const& owned, Offer& offer, size_t& nextUpgrade) const
{
    for (BonkSpellUpgrade& upgrade : offer.upgrades)
        upgrade = BONK_SPELL_UPGRADE_NONE;
    std::vector<BonkWeaponUpgrade> const& all = owned.weapon.upgrades;
    if (all.empty())
        return;

    float rolled[MAX_BONK_SPELL_UPGRADE] = {};
    uint8 const count = GetRankUpgradeCount(&owned, offer.rarity);
    for (uint8 i = 0; i < count; ++i)
    {
        std::vector<BonkWeaponUpgrade const*> const options = GetUpgradeOptions(owned, offer.rarity, rolled);
        BonkWeaponUpgrade const* pick = nullptr;
        for (size_t tried = 0; tried < all.size() && !pick; ++tried)
        {
            BonkWeaponUpgrade const* candidate = &all[(nextUpgrade + tried) % all.size()];
            if (std::find(options.begin(), options.end(), candidate) != options.end())
            {
                pick = candidate;
                nextUpgrade = (nextUpgrade + tried + 1) % all.size();
            }
        }
        if (!pick)
            break;
        offer.upgrades[i] = pick->upgrade;
        rolled[pick->upgrade] += pick->step;
    }
}

void BonkRun::SetSandboxPassiveRank(uint32 passiveId, uint32 rank)
{
    std::string error;
    auto current = [this, passiveId]()
    {
        auto itr = m_passiveRanks.find(passiveId);
        return itr != m_passiveRanks.end() ? uint32(itr->second) : 0u;
    };
    while (current() < rank && GivePassive(passiveId, error))
        ;
    if (!error.empty())
        m_player->GetBonkPlayer()->Notify(error);
}

void BonkRun::RemoveSandboxSpells(uint32 baseId)
{
    DespawnPets();
    DespawnTraps();
    DespawnLandMines();
    DespawnWeaponOrbs();
    DespawnProjectiles();
    DespawnShotSources();
    ClearHunterEvolutions();
    ResetWarriorState();
    ResetMageState();
    m_pendingCasts.clear();
    m_heldShotSources.clear();

    m_weapons.erase(std::remove_if(m_weapons.begin(), m_weapons.end(), [baseId](OwnedWeapon const& owned)
    {
        return !baseId || owned.weapon.id == baseId || owned.weapon.evolvesFrom == baseId;
    }), m_weapons.end());
    RebuildWeaponSpells();
    if (UsesShotSources())
        WarmShotSources();
    ApplyPassives();
    SendLoadout();
}

void BonkRun::ResetSandbox(uint32 reset)
{
    BonkPlayer* bonk = m_player->GetBonkPlayer();
    switch (reset)
    {
        case RESET_CLEAR:
            ClearSandboxEnemies();
            bonk->Notify(BONK_STRING_ALL_ENEMIES_AND_DUMMIES_ARE);
            break;
        case RESET_HEAL:
            HealInSandbox();
            bonk->Notify(BONK_STRING_YOU_ARE_FULLY_HEALED);
            break;
        case RESET_COOLDOWNS:
            ResetSandboxCooldowns();
            bonk->Notify(BONK_STRING_ALL_YOUR_COOLDOWNS_ARE_READY);
            break;
        case RESET_DUMMIES:
            RefillSandboxDummies();
            bonk->Notify(BONK_STRING_TRAINING_DUMMIES_ARE_WHOLE_AGAIN);
            break;
        case RESET_SPELLS:
            RemoveSandboxSpells(0);
            bonk->Notify(BONK_STRING_YOU_FORGOT_ALL_YOUR_SPELLS);
            break;
        default:
            break;
    }
}

void BonkRun::ClearSandboxEnemies()
{
    m_sandboxPackLeft = 0;
    DespawnMobs();
    m_sandboxDummies.clear();
    m_telegraphs.Clear(m_player);
    m_voidZones.clear();
    DespawnPools();
    m_pendingKeywords.clear();
    m_pendingConsumes.clear();
    m_dyingKeywords.clear();
    m_pendingDotBursts.clear();
    m_volleyHits = 0;
    m_explosiveArrows = 0;
    m_explosiveArrowReadyMs = 0;
    m_dotBurstTimes.clear();
    m_dotBurstLookTimes.clear();
    m_dotStacks.clear();
    m_crowdControl.clear();
    SetNecroticStacks(0);
    if (m_player->GetBonkPlayer()->IsAddonReady())
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteMobClear(data);
        m_player->GetSession()->SendPacket(&data);
    }
}

void BonkRun::HealInSandbox()
{
    if (!m_player->IsAlive())
        ReviveInSandbox();
    m_player->SetHealth(m_player->GetMaxHealth());
    m_player->SetPower(POWER_MANA, m_player->GetMaxPower(POWER_MANA));
    RefillShield(GetMaxShield());
    m_shieldIdleMs = 0;
    SetNecroticStacks(0);
}

void BonkRun::EnterSandboxBench()
{
    m_sandboxBench = true;
    m_bonuses = BonkRunBonuses();
    m_sandboxBenchItems.clear();
    m_mastery = BonkMasteryBonuses();
    RemoveSandboxSpells(0);
    UpdateGear();
    ApplyPassives();
    HealInSandbox();
    m_player->GetBonkPlayer()->Notify(BONK_STRING_BENCH_MODE_IS_ON_TALENTS);
}

void BonkRun::ResetSandboxCooldowns()
{
    for (OwnedWeapon& owned : m_weapons)
        owned.timer = 0;
    std::fill(std::begin(m_cardCooldowns), std::end(m_cardCooldowns), 0);
    m_player->RemoveAllCooldowns();
    SendCardCooldowns();
    SendLoadout();
}

void BonkRun::RefillSandboxDummies()
{
    Map* map = m_player->GetMap();
    for (auto& itr : m_sandboxDummies)
        if (Creature* dummy = map->GetCreature(itr.first))
            if (dummy->IsAlive())
            {
                dummy->SetHealth(dummy->GetMaxHealth());
                itr.second.health = dummy->GetHealth();
                itr.second.idleMs = 0;
            }
}

void BonkRun::ShowSandboxMenu(Creature* keeper, uint32 menu)
{
    m_sandboxMenu = menu;
    PlayerMenu* talk = m_player->PlayerTalkClass;
    talk->ClearMenus();
    switch (MenuOf(menu))
    {
        case MENU_DUMMIES:
            AddDummyItems(m_player, m_sandboxDeepDummies);
            break;
        case MENU_ENEMIES:
            AddEnemyItems(m_player, m_sandboxPassive, m_sandboxUnkillable, m_sandboxMovesOff, m_sandboxReachReport);
            break;
        case MENU_ENEMY_LIST:
            AddEnemyList(m_player, SandboxEnemyType(ContextOf(menu)), PageOf(menu));
            break;
        case MENU_LEVELS:
            AddLevelItems(m_player);
            break;
        case MENU_SPELLS:
            AddSandboxSpellItems(PageOf(menu));
            break;
        case MENU_SPELL:
            AddSandboxSpellPage(ContextOf(menu));
            break;
        case MENU_PASSIVES:
            AddSandboxPassiveItems(PageOf(menu));
            break;
        case MENU_CARDS:
            AddSandboxCardItems(PageOf(menu));
            break;
        case MENU_RESET:
            AddResetItems(m_player);
            break;
        default:
            AddMainItems(m_player);
            break;
    }
    talk->SendGossipMenu(BONK_TEXT_SANDBOX_MENU, keeper->GetObjectGuid());
}

void BonkRun::AddSandboxSpellItems(uint32 page)
{
    uint32 const classMask = m_player->GetClassMask();
    std::vector<BonkWeapon const*> spells;
    for (auto const& itr : sBonkMgr.GetWeapons())
    {
        BonkWeapon const& base = itr.second;
        if (!base.evolvesFrom && (!base.classMask || (base.classMask & classMask)))
            spells.push_back(&base);
    }
    page = ClampPage(page, spells.size(), BONK_SANDBOX_SPELL_PAGE);
    size_t const end = std::min(spells.size(), size_t(page + 1) * BONK_SANDBOX_SPELL_PAGE);
    for (size_t i = size_t(page) * BONK_SANDBOX_SPELL_PAGE; i < end; ++i)
    {
        BonkWeapon const& base = *spells[i];
        OwnedWeapon const* owned = FindSandboxSpell(base.id);
        std::string const text = owned ? GetString(BONK_STRING_SANDBOX_SPELL_RANKED, { Localize(BONK_FIELD_WEAPON_NAME, owned->weapon.id, owned->weapon.name), std::to_string(owned->rank) }) : Localize(BONK_FIELD_WEAPON_NAME, base.id, base.name);
        AddItem(m_player, owned ? GOSSIP_ICON_TRAINER : GOSSIP_ICON_CHAT, text, SENDER_OPEN, MenuAction(MENU_SPELL, 0, base.id));
    }
    if (page > 0)
        AddItem(m_player, GOSSIP_ICON_CHAT, Text(m_player, BONK_STRING_SANDBOX_PREVIOUS_PAGE), SENDER_OPEN, MenuAction(MENU_SPELLS, page - 1));
    if (end < spells.size())
        AddItem(m_player, GOSSIP_ICON_CHAT, Text(m_player, BONK_STRING_SANDBOX_NEXT_PAGE), SENDER_OPEN, MenuAction(MENU_SPELLS, page + 1));
    AddItem(m_player, GOSSIP_ICON_TRAINER, Text(m_player, BONK_STRING_SANDBOX_GIVE_PASSIVE), SENDER_OPEN, MenuAction(MENU_PASSIVES));
    AddItem(m_player, GOSSIP_ICON_TRAINER, Text(m_player, BONK_STRING_SANDBOX_GIVE_CARD), SENDER_OPEN, MenuAction(MENU_CARDS));
    AddItem(m_player, GOSSIP_ICON_INTERACT_1, Text(m_player, BONK_STRING_SANDBOX_REMOVE_ALL_SPELLS), SENDER_RESET, RESET_SPELLS);
    AddBack(m_player, MENU_MAIN);
}

void BonkRun::AddSandboxSpellPage(uint32 baseId)
{
    BonkWeapon const* base = sBonkMgr.GetWeapon(baseId);
    if (!base)
    {
        AddBack(m_player, MENU_SPELLS);
        return;
    }

    OwnedWeapon const* owned = FindSandboxSpell(baseId);
    std::string const status = owned ?
        GetString(BONK_STRING_SANDBOX_SPELL_STATUS_OWNED, { Localize(BONK_FIELD_WEAPON_NAME, owned->weapon.id, owned->weapon.name), std::to_string(owned->rank),
            std::to_string(m_weapons.size()), std::to_string(GetSpellSlots()) }) :
        GetString(BONK_STRING_SANDBOX_SPELL_STATUS_NOT_LEARNED, { Localize(BONK_FIELD_WEAPON_NAME, base->id, base->name), std::to_string(m_weapons.size()), std::to_string(GetSpellSlots()) });
    AddItem(m_player, GOSSIP_ICON_CHAT, status, SENDER_OPEN, MenuAction(MENU_SPELL, 0, baseId));

    std::vector<BonkWeapon const*> const evolutions = sBonkMgr.GetEvolutions(baseId);
    if (owned)
    {
        for (uint32 rank : BONK_SANDBOX_RANKS)
            AddItem(m_player, GOSSIP_ICON_TRAINER, GetString(BONK_STRING_SANDBOX_SET_RANK, { std::to_string(rank) }), SENDER_SPELL_RANK, PairAction(rank, baseId));
        for (BonkWeapon const* evolved : evolutions)
        {
            bool const held = owned->weapon.id == evolved->id;
            AddItem(m_player, held ? GOSSIP_ICON_CHAT : GOSSIP_ICON_BATTLE, held ? GetString(BONK_STRING_SANDBOX_EVOLVED_HELD, { Localize(BONK_FIELD_WEAPON_NAME, evolved->id, evolved->name) }) : GetString(BONK_STRING_SANDBOX_EVOLVE_INTO, { Localize(BONK_FIELD_WEAPON_NAME, evolved->id, evolved->name) }),
                SENDER_EVOLVE, evolved->id);
        }
        AddItem(m_player, GOSSIP_ICON_INTERACT_1, GetString(BONK_STRING_SANDBOX_REMOVE_SPELL, { Localize(BONK_FIELD_WEAPON_NAME, owned->weapon.id, owned->weapon.name) }), SENDER_SPELL_REMOVE, baseId);
    }
    else
    {
        if (m_weapons.size() < GetSpellSlots())
            AddItem(m_player, GOSSIP_ICON_BATTLE, GetString(BONK_STRING_SANDBOX_ADD_SPELL, { Localize(BONK_FIELD_WEAPON_NAME, base->id, base->name) }), SENDER_SPELL_ADD, baseId);
        else
            for (OwnedWeapon const& other : m_weapons)
                AddItem(m_player, GOSSIP_ICON_INTERACT_1, GetString(BONK_STRING_SANDBOX_REPLACE_SPELL, { Localize(BONK_FIELD_WEAPON_NAME, other.weapon.id, other.weapon.name) }), SENDER_SPELL_REPLACE,
                    PairAction(baseId, other.weapon.evolvesFrom ? other.weapon.evolvesFrom : other.weapon.id));
        for (BonkWeapon const* evolved : evolutions)
            AddItem(m_player, GOSSIP_ICON_BATTLE, GetString(BONK_STRING_SANDBOX_ADD_AS, { Localize(BONK_FIELD_WEAPON_NAME, evolved->id, evolved->name) }), SENDER_EVOLVE, evolved->id);
    }
    AddBack(m_player, MENU_SPELLS);
}

void BonkRun::AddSandboxPassiveItems(uint32 page)
{
    std::vector<BonkPassive const*> passives;
    for (auto const& itr : sBonkMgr.GetPassives())
        passives.push_back(&itr.second);

    page = ClampPage(page, passives.size());
    size_t const end = std::min(passives.size(), size_t(page + 1) * BONK_SANDBOX_PAGE);
    for (size_t i = size_t(page) * BONK_SANDBOX_PAGE; i < end; ++i)
    {
        BonkPassive const& passive = *passives[i];
        auto const rank = m_passiveRanks.find(passive.id);
        uint32 const current = rank != m_passiveRanks.end() ? rank->second : 0;
        AddItem(m_player, !passive.IsMaxed(current) ? GOSSIP_ICON_TRAINER : GOSSIP_ICON_CHAT,
            Localize(BONK_FIELD_PASSIVE_NAME, passive.id, passive.name) + " " + std::to_string(current) + (passive.maxRank ? "/" + std::to_string(passive.maxRank) : ""), SENDER_PASSIVE, passive.id);
    }
    AddPaging(m_player, MENU_PASSIVES, page, 0, passives.size());
    AddBack(m_player, MENU_SPELLS);
}

void BonkRun::AddSandboxCardItems(uint32 page)
{
    std::vector<BonkCard const*> cards;
    for (auto const& itr : sBonkMgr.GetCards())
        cards.push_back(&itr.second);

    page = ClampPage(page, cards.size());
    size_t const end = std::min(cards.size(), size_t(page + 1) * BONK_SANDBOX_PAGE);
    for (size_t i = size_t(page) * BONK_SANDBOX_PAGE; i < end; ++i)
    {
        BonkCard const& card = *cards[i];
        uint32 const copies = GetCardCopies(card.id);
        AddItem(m_player, GOSSIP_ICON_VENDOR, copies ? GetString(BONK_STRING_SANDBOX_CARD_HELD, { Localize(BONK_FIELD_CARD_NAME, card.id, card.name), std::to_string(copies) }) : Localize(BONK_FIELD_CARD_NAME, card.id, card.name), SENDER_CARD, card.id);
    }
    AddPaging(m_player, MENU_CARDS, page, 0, cards.size());
    AddBack(m_player, MENU_SPELLS);
}

void BonkRun::SelectSandboxOption(Creature* keeper, uint32 sender, uint32 action)
{
    if (m_state != STATE_RUNNING)
    {
        m_player->PlayerTalkClass->CloseGossip();
        return;
    }

    std::string error;
    uint32 next = m_sandboxMenu;
    switch (sender)
    {
        case SENDER_OPEN:
            next = action;
            break;
        case SENDER_DUMMY:
            SpawnSandboxDummies(action & 0xFF, BonkSpawnKind(action >> 8));
            break;
        case SENDER_CROWD_DUMMY:
            SpawnSandboxDummies(std::min(action, BONK_CROWD_DUMMY_MAX), BONK_SPAWN_NORMAL, -1.0f);
            break;
        case SENDER_PACK:
            QueueSandboxPack(action, false);
            break;
        case SENDER_ENEMY:
            SpawnSandboxEnemy(action);
            break;
        case SENDER_TOGGLE:
            ToggleSandbox(action);
            break;
        case SENDER_LEVELS:
            if (action)
                GiveSandboxLevels(action);
            else
                SpawnSandboxCrystals(keeper);
            break;
        case SENDER_SET_LEVEL:
            SetSandboxLevel(action);
            break;
        case SENDER_SPELL_ADD:
            AddSandboxSpell(action, error);
            break;
        case SENDER_SPELL_REPLACE:
            if (FindSandboxSpell(action & 0xFFFF))
                RemoveSandboxSpells(action & 0xFFFF);
            AddSandboxSpell(action >> 16, error);
            next = MenuAction(MENU_SPELL, 0, action >> 16);
            break;
        case SENDER_SPELL_RANK:
            SetSandboxRank(action & 0xFFFF, action >> 16, false);
            break;
        case SENDER_SPELL_REMOVE:
            if (OwnedWeapon const* owned = FindSandboxSpell(action))
            {
                std::string const name = Localize(BONK_FIELD_WEAPON_NAME, owned->weapon.id, owned->weapon.name);
                RemoveSandboxSpells(action);
                m_player->GetBonkPlayer()->Notify(BONK_STRING_YOU_FORGOT, { name });
            }
            break;
        case SENDER_EVOLVE:
            ForceEvolve(action, error);
            break;
        case SENDER_PASSIVE:
            GivePassive(action, error);
            break;
        case SENDER_CARD:
        {
            BonkCard const* card = sBonkMgr.GetCard(action);
            if (card && card->maxCopies && GetCardCopies(action) >= card->maxCopies)
                error = GetString(BONK_STRING_YOU_ALREADY_HOLD_EVERY_COPY, { Localize(BONK_FIELD_CARD_NAME, card->id, card->name) });
            else
                GiveCard(action, error);
            break;
        }
        case SENDER_RESET:
            ResetSandbox(action);
            break;
        case SENDER_LEAVE:
            m_player->PlayerTalkClass->CloseGossip();
            LeaveSandbox();
            return;
        default:
            break;
    }

    if (!error.empty())
        m_player->GetBonkPlayer()->Notify(error);
    ShowSandboxMenu(keeper, next);
}

bool GossipHello_npc_bonk_sandbox(Player* player, Creature* creature)
{
    if (!BonkSandbox::IsAllowed(player))
    {
        player->PlayerTalkClass->SendGossipMenu(BONK_TEXT_SANDBOX_REFUSE, creature->GetObjectGuid());
        return true;
    }

    BonkRun* run = player->GetBonkPlayer()->GetRun();
    if (run && run->IsSandbox())
    {
        run->ShowSandboxMenu(creature, MenuAction(MENU_MAIN));
        return true;
    }

    if (!run)
        AddItem(player, GOSSIP_ICON_BATTLE, Text(player, BONK_STRING_SANDBOX_ENTER), SENDER_ENTER, 0);
    player->PlayerTalkClass->SendGossipMenu(BONK_TEXT_SANDBOX_CAMP, creature->GetObjectGuid());
    return true;
}

bool GossipSelect_npc_bonk_sandbox(Player* player, Creature* creature, uint32 sender, uint32 action)
{
    bool const allowed = BonkSandbox::IsAllowed(player);
    BonkRun* run = player->GetBonkPlayer()->GetRun();
    if (allowed && run && run->IsSandbox())
    {
        run->SelectSandboxOption(creature, sender, action);
        return true;
    }

    player->PlayerTalkClass->CloseGossip();
    if (!allowed || run || sender != SENDER_ENTER)
        return true;

    std::string error;
    if (!player->GetBonkPlayer()->StartSandbox(error))
        player->GetBonkPlayer()->Notify(error);
    return true;
}

bool BonkRun::OfferSandboxGear(uint32 entry, std::string& error)
{
    uint32 const tier = BonkMgr::GetGearTier(entry);
    if (!tier)
    {
        error = GetString(BONK_STRING_THAT_ISNT_RUN_GEAR);
        return false;
    }
    PendingGear piece(entry);
    piece.gear.tier = tier;
    m_pendingGear.push_back(piece);
    OfferGear();
    return true;
}

void BonkRun::QueueSandboxGearOffer(uint8 quality)
{
    PendingGear piece;
    if (!MakeBagPiece(quality, piece))
        return;
    m_pendingGear.push_back(piece);
    UpdateOffers();
}

void BonkRun::RollSandboxDrops(uint8 quality, uint32 count)
{
    for (uint32 roll = 0; roll < count; ++roll)
    {
        PendingGear piece;
        if (!MakeBagPiece(quality, piece))
            continue;
        ItemPrototype const* proto = sObjectMgr.GetItemPrototype(piece.entry);
        m_player->GetBonkPlayer()->Notify("droptest " + std::to_string(piece.entry) + " " + (proto ? proto->Name1 : "?") +
            " challenge " + GetChallengeMapKey());
    }
}

bool BonkRun::RunSandboxVerb(std::string const& verb, uint32 first, uint32 second, std::string& error)
{
    if (m_state != STATE_RUNNING)
    {
        error = GetString(BONK_STRING_SANDBOX_IS_NOT_READY_YET);
        return false;
    }

    BonkPlayer* bonk = m_player->GetBonkPlayer();
    if (verb == "pack")
        QueueSandboxPack(first ? first : BONK_SANDBOX_DEFAULT_PACK, second != 0);
    else if (verb == "dummies")
        SpawnSandboxDummies(std::max(1u, std::min(first, 20u)), BONK_SPAWN_NORMAL, float(second));
    else if (verb == "challenge")
        m_dungeonId = first;
    else if (verb == "droptest")
        RollSandboxDrops(uint8(first), std::max(1u, std::min(second, 20u)));
    else if (verb == "gearoffer")
        QueueSandboxGearOffer(uint8(first));
    else if (verb == "tabardroll")
        for (uint32 roll = 0; roll < first; ++roll)
            BonkTransmog::RollTabardDrops(m_player, m_map.key);
    else if (verb == "crowddummies")
        SpawnSandboxDummies(std::max(1u, std::min(first, BONK_CROWD_DUMMY_MAX)), BONK_SPAWN_NORMAL, -1.0f);
    else if (verb == "spell")
        return AddSandboxSpell(first, error);
    else if (verb == "evolve")
        return ForceEvolve(first, error);
    else if (verb == "form")
        ShapeshiftTo(first);
    else if (verb == "formcycle")
        m_formCycleMs = first;
    else if (verb == "rank")
        SetSandboxRank(first, second, false);
    else if (verb == "maxrank")
        SetSandboxRank(first, second, true);
    else if (verb == "passive")
        SetSandboxPassiveRank(first, second);
    else if (verb == "glyph")
        return AddSandboxGlyph(first, error);
    else if (verb == "card")
        return AddSandboxCards(first, std::max(1u, second), error);
    else if (verb == "tier")
        return SetSandboxTier(first, second, error);
    else if (verb == "talent")
        SetSandboxTalent(first, second);
    else if (verb == "item")
        return SetSandboxBenchItem(first, error);
    else if (verb == "training")
        SetSandboxTraining(first);
    else if (verb == "vitals")
        ReportSandboxVitals();
    else if (verb == "trinkets")
        ReportSandboxTrinkets();
    else if (verb == "valor")
    {
        GainValor(first);
        SendState();
    }
    else if (verb == "enchanter")
        PlaceEnchanter(m_player->GetPositionX() + 4.0f * std::cos(m_player->GetOrientation()), m_player->GetPositionY() + 4.0f * std::sin(m_player->GetOrientation()),
            m_player->GetPositionZ(), m_player->GetOrientation() + M_PI_F);
    else if (verb == "forget")
        RemoveSandboxSpells(first);
    else if (verb == "level")
        SetSandboxLevel(first);
    else if (verb == "gear")
        return OfferSandboxGear(first, error);
    else if (verb == "clear")
        ResetSandbox(RESET_CLEAR);
    else if (verb == "heal")
        ResetSandbox(RESET_HEAL);
    else if (verb == "cooldowns")
        ResetSandbox(RESET_COOLDOWNS);
    else if (verb == "god")
        ToggleSandbox(TOGGLE_GOD);
    else if (verb == "necrotic")
    {
        if (!first)
            SetNecroticStacks(0);
        else
            for (uint32 i = 0; i < first; ++i)
                AddNecroticStack();
    }
    else if (verb == "passive")
        ToggleSandbox(TOGGLE_PASSIVE);
    else if (verb == "unkillable")
        ToggleSandbox(TOGGLE_UNKILLABLE);
    else if (verb == "moves")
        ToggleSandbox(TOGGLE_MOVES_OFF);
    else if (verb == "reach")
        ToggleSandbox(TOGGLE_REACH_REPORT);
    else if (verb == "deep")
        ToggleSandbox(TOGGLE_DEEP_DUMMIES);
    else if (verb == "minute")
    {
        m_sandboxMinute = first ? float(first) : -1.0f;
        bonk->Notify(first ? BONK_STRING_SANDBOX_TOUGHNESS_MINUTE : BONK_STRING_SANDBOX_TOUGHNESS_TIME, { std::to_string(first) });
    }
    else if (verb == "boss" || verb == "miniboss" || verb == "bosshealth" || verb == "ability")
        return RunSandboxBossVerb(verb, first, error);
    else if (verb == "elite")
    {
        std::vector<SandboxEnemy> const elites = ListEnemies(ENEMY_ELITE);
        if (elites.empty())
        {
            error = GetString(BONK_STRING_NO_ELITES_ARE_ON_ANY);
            return false;
        }
        for (uint32 i = 0; i < std::max(1u, first); ++i)
            SpawnSandboxEnemy(elites[urand(0, uint32(elites.size()) - 1)].entry);
    }
    else if (verb == "quiet")
    {
        m_sandboxQuietLevels = !m_sandboxQuietLevels;
        bonk->Notify(m_sandboxQuietLevels ? BONK_STRING_LEVEL_UPS_QUIET : BONK_STRING_LEVEL_UPS_OFFER_CHOICES);
    }
    else if (verb == "bench")
        EnterSandboxBench();
    else
    {
        error = GetString(BONK_STRING_USE_BONK_SANDBOX_PACK_DUMMIES);
        return false;
    }
    return true;
}

bool ChatHandler::HandleBonkSandboxCommand(char* args)
{
    BonkPlayer* bonk = m_session->GetPlayer()->GetBonkPlayer();
    std::string error;
    char* verb = ExtractLiteralArg(&args);
    if (!verb)
    {
        if (bonk->StartSandbox(error))
            return true;
    }
    else if (!bonk->IsInSandbox())
        error = bonk->GetString(BONK_STRING_YOU_ARE_NOT_IN_SANDBOX);
    else
    {
        uint32 first = 0, second = 0;
        ExtractUInt32(&args, first);
        ExtractUInt32(&args, second);
        if (bonk->GetRun()->RunSandboxVerb(verb, first, second, error))
            return true;
    }

    SendSysMessage(error.c_str());
    SetSentErrorMessage(true);
    return false;
}

void AddSC_bonk_sandbox()
{
    Script* newscript = new Script;
    newscript->Name = "npc_bonk_sandbox";
    newscript->pGossipHello = &GossipHello_npc_bonk_sandbox;
    newscript->pGossipSelect = &GossipSelect_npc_bonk_sandbox;
    newscript->RegisterSelf();
}

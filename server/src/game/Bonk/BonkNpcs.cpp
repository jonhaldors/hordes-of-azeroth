#include "BonkCodex.h"
#include "BonkCoop.h"
#include "BonkLocale.h"
#include "BonkMastery.h"
#include "BonkMgr.h"
#include "BonkPlayer.h"
#include "BonkRun.h"
#include "Creature.h"
#include "GameObject.h"
#include "HoaProtocol.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include "WorldSession.h"

#include <cctype>

namespace
{
    uint32 const BONK_TEXT_RUN_MASTER    = 900001;
    uint32 const BONK_TEXT_PORTAL        = 900002;
    uint32 const BONK_TEXT_QUARTERMASTER = 900003;
    uint32 const BONK_TEXT_TALENTS       = 900004;
    uint32 const BONK_TEXT_MASTERY       = 900008;
    uint32 const BONK_TEXT_MASTERY_SOON  = 900009;
    uint32 const BONK_TEXT_VAULT_EMPTY   = 900010;
    uint32 const BONK_TEXT_VAULT         = 900011;
    uint32 const BONK_TEXT_PORTAL_FINAL  = 900016;
    uint32 const BONK_TEXT_COOP          = 900190;

    uint32 const COOP_ACTION_PAUSE = GOSSIP_ACTION_INFO_DEF + 1;
    uint32 const COOP_ACTION_XP    = GOSSIP_ACTION_INFO_DEF + 2;

    uint32 const MASTERY_ACTION_RESPEC = GOSSIP_ACTION_INFO_DEF - 1;

    uint32 const SENDER_BUY    = GOSSIP_SENDER_MAIN;
    uint32 const SENDER_TOGGLE = GOSSIP_SENDER_MAIN + 1;

    enum PortalAction
    {
        PORTAL_ACTION_NEXT = GOSSIP_ACTION_INFO_DEF + 1,
        PORTAL_ACTION_HOME = GOSSIP_ACTION_INFO_DEF + 2,
        PORTAL_ACTION_HOME_SURE = GOSSIP_ACTION_INFO_DEF + 3,
        PORTAL_ACTION_BACK = GOSSIP_ACTION_INFO_DEF + 4,
        PORTAL_ACTION_ENDLESS = GOSSIP_ACTION_INFO_DEF + 5,
    };

    uint32 const SENDER_VAULT_PUT  = GOSSIP_SENDER_MAIN + 1;
    uint32 const SENDER_VAULT_TAKE = GOSSIP_SENDER_MAIN + 2;
    uint32 const SENDER_VAULT_SEND = GOSSIP_SENDER_MAIN + 3;
}

bool GossipHello_npc_bonk_run_master(Player* player, Creature* creature)
{
    BonkPlayer* bonk = player->GetBonkPlayer();

    if (bonk->IsAddonReady())
    {
        bonk->OpenArena(creature);
        player->SEND_GOSSIP_MENU(BONK_TEXT_RUN_MASTER, creature->GetObjectGuid());
        return true;
    }

    for (BonkTier const* tierPtr : sBonkMgr.GetTiersInOrder())
    {
        if (player->PlayerTalkClass->GetGossipMenu().MenuItemCount() >= GOSSIP_MAX_MENU_ITEMS)
            break;

        BonkTier const& tier = *tierPtr;
        std::string const text = bonk->IsTierUnlocked(tier) ? bonk->GetLevelName(bonk->GetOpenLevel(tier)) :
            bonk->GetString(BONK_STRING_TIER_LOCKED, { bonk->Localize(BONK_FIELD_TIER_NAME, tier.id, tier.name), bonk->GetUnlockHint(tier) });
        player->ADD_GOSSIP_ITEM(GOSSIP_ICON_BATTLE, text.c_str(), GOSSIP_SENDER_MAIN, GOSSIP_ACTION_INFO_DEF + tier.id);
    }

    player->SEND_GOSSIP_MENU(BONK_TEXT_RUN_MASTER, creature->GetObjectGuid());
    return true;
}

bool GossipSelect_npc_bonk_run_master(Player* player, Creature* , uint32 , uint32 action)
{
    player->CLOSE_GOSSIP_MENU();

    BonkTier const* tier = action >= GOSSIP_ACTION_INFO_DEF ? sBonkMgr.GetTier(action - GOSSIP_ACTION_INFO_DEF) : nullptr;
    if (!tier)
        return true;

    std::string error;
    if (!player->GetBonkPlayer()->StartRun(*tier, error))
        player->GetBonkPlayer()->Notify(error);
    return true;
}

bool GossipHello_npc_bonk_quartermaster(Player* player, Creature* creature)
{
    BonkPlayer* bonk = player->GetBonkPlayer();

    if (bonk->IsAddonReady())
    {
        bonk->OpenShop(BONK_SHOP_UPGRADES, creature);
        player->SEND_GOSSIP_MENU(BONK_TEXT_QUARTERMASTER, creature->GetObjectGuid());
        return true;
    }

    for (auto const& itr : sBonkMgr.GetUpgrades())
    {
        if (player->PlayerTalkClass->GetGossipMenu().MenuItemCount() >= GOSSIP_MAX_MENU_ITEMS)
            break;

        BonkUpgrade const& upgrade = itr.second;
        uint8 const rank = bonk->GetUpgradeRank(upgrade.id);
        std::string text = bonk->GetString(BONK_STRING_GOSSIP_RANK_LINE, { bonk->Localize(BONK_FIELD_UPGRADE_NAME, upgrade.id, upgrade.name),
            std::to_string(rank), std::to_string(upgrade.maxRank), bonk->Localize(BONK_FIELD_UPGRADE_DESCRIPTION, upgrade.id, upgrade.description) });
        text += " (" + (rank < upgrade.maxRank ? FormatBonkMoney(upgrade.GetCost(rank), bonk->GetLocale()) : bonk->GetString(BONK_STRING_GOSSIP_MAX_RANK)) + ")";
        player->ADD_GOSSIP_ITEM(rank < upgrade.maxRank ? GOSSIP_ICON_TRAINER : GOSSIP_ICON_CHAT, text.c_str(), SENDER_BUY,
            GOSSIP_ACTION_INFO_DEF + upgrade.id);
    }

    player->SEND_GOSSIP_MENU(BONK_TEXT_QUARTERMASTER, creature->GetObjectGuid());
    return true;
}

bool GossipSelect_npc_bonk_quartermaster(Player* player, Creature* creature, uint32 , uint32 action)
{
    if (action >= GOSSIP_ACTION_INFO_DEF)
    {
        std::string message;
        player->GetBonkPlayer()->BuyUpgrade(action - GOSSIP_ACTION_INFO_DEF, message);
        if (!message.empty())
            player->GetBonkPlayer()->Notify(message);
    }

    return GossipHello_npc_bonk_quartermaster(player, creature);
}

bool GossipHello_npc_bonk_talents(Player* player, Creature* creature)
{
    BonkPlayer* bonk = player->GetBonkPlayer();

    if (bonk->IsAddonReady())
    {
        BonkCodex::Send(player, "");
        bonk->OpenShop(BONK_SHOP_TALENTS, creature);
        player->SEND_GOSSIP_MENU(BONK_TEXT_TALENTS, creature->GetObjectGuid());
        return true;
    }

    for (auto const& itr : sBonkMgr.GetTalents())
    {
        if (player->PlayerTalkClass->GetGossipMenu().MenuItemCount() >= GOSSIP_MAX_MENU_ITEMS)
            break;

        BonkTalent const& talent = itr.second;
        uint8 const rank = bonk->GetTalentRank(talent.id);
        uint32 const action = GOSSIP_ACTION_INFO_DEF + talent.id;

        if (talent.IsToggle() && rank)
        {
            std::string const text = bonk->GetString(bonk->IsTalentEnabled(talent.id) ? BONK_STRING_GOSSIP_TOGGLE_ON : BONK_STRING_GOSSIP_TOGGLE_OFF,
                { bonk->Localize(BONK_FIELD_TALENT_NAME, talent.id, talent.name), bonk->Localize(BONK_FIELD_TALENT_DESCRIPTION, talent.id, talent.description) });
            player->ADD_GOSSIP_ITEM(GOSSIP_ICON_BATTLE, text.c_str(), SENDER_TOGGLE, action);
            continue;
        }

        std::string const name = bonk->Localize(BONK_FIELD_TALENT_NAME, talent.id, talent.name);
        std::string const description = bonk->Localize(BONK_FIELD_TALENT_DESCRIPTION, talent.id, talent.description);
        std::string text = talent.IsToggle() ? bonk->GetString(BONK_STRING_GOSSIP_NAME_LINE, { name, description }) :
            bonk->GetString(BONK_STRING_GOSSIP_RANK_LINE, { name, std::to_string(rank), std::to_string(talent.maxRank), description });
        text += " (" + (rank < talent.maxRank ? FormatBonkShards(talent.GetCost(rank), bonk->GetLocale()) : bonk->GetString(BONK_STRING_GOSSIP_MAX_RANK)) + ")";
        player->ADD_GOSSIP_ITEM(rank < talent.maxRank ? GOSSIP_ICON_TRAINER : GOSSIP_ICON_CHAT, text.c_str(), SENDER_BUY, action);
    }

    player->SEND_GOSSIP_MENU(BONK_TEXT_TALENTS, creature->GetObjectGuid());
    return true;
}

bool GossipSelect_npc_bonk_talents(Player* player, Creature* creature, uint32 sender, uint32 action)
{
    if (action >= GOSSIP_ACTION_INFO_DEF)
    {
        uint32 const talentId = action - GOSSIP_ACTION_INFO_DEF;
        std::string message;
        if (sender == SENDER_TOGGLE)
            player->GetBonkPlayer()->ToggleTalent(talentId, message);
        else
            player->GetBonkPlayer()->BuyTalent(talentId, message);
        if (!message.empty())
            player->GetBonkPlayer()->Notify(message);
    }

    return GossipHello_npc_bonk_talents(player, creature);
}

bool GossipHello_npc_bonk_mastery(Player* player, Creature* creature)
{
    BonkPlayer* bonk = player->GetBonkPlayer();

    if (!sBonkMastery.HasTrees(player->GetClass()))
    {
        player->SEND_GOSSIP_MENU(BONK_TEXT_MASTERY_SOON, creature->GetObjectGuid());
        return true;
    }

    if (bonk->IsAddonReady())
    {
        bonk->OpenShop(BONK_SHOP_MASTERY, creature);
        player->SEND_GOSSIP_MENU(BONK_TEXT_MASTERY, creature->GetObjectGuid());
        return true;
    }

    uint32 const points = bonk->GetMasteryPoints();
    uint32 const spent = bonk->GetMasterySpent();
    uint32 const unspent = points > spent ? points - spent : 0;
    std::string const header = bonk->GetString(unspent == 1 ? BONK_STRING_GOSSIP_MASTERY_HEADER_ONE : BONK_STRING_GOSSIP_MASTERY_HEADER,
        { std::to_string(bonk->GetMasteryLevel()), std::to_string(unspent) });
    player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, header.c_str(), GOSSIP_SENDER_MAIN, GOSSIP_ACTION_INFO_DEF);
    for (auto const& itr : sBonkMastery.GetNodes())
    {
        BonkMasteryNode const& node = itr.second;
        if (node.classId != player->GetClass())
            continue;
        if (player->PlayerTalkClass->GetGossipMenu().MenuItemCount() >= GOSSIP_MAX_MENU_ITEMS - 1)
            break;
        uint8 const rank = bonk->GetMasteryRank(node.id);
        std::string const text = bonk->GetString(BONK_STRING_GOSSIP_RANK_LINE, { bonk->Localize(BONK_FIELD_MASTERY_NAME, node.id, node.name),
            std::to_string(rank), std::to_string(node.maxRank), bonk->Localize(BONK_FIELD_MASTERY_DESCRIPTION, node.id, node.description) });
        player->ADD_GOSSIP_ITEM(rank < node.maxRank ? GOSSIP_ICON_TRAINER : GOSSIP_ICON_CHAT, text.c_str(), SENDER_BUY,
            GOSSIP_ACTION_INFO_DEF + node.id);
    }
    player->ADD_GOSSIP_ITEM(GOSSIP_ICON_INTERACT_1, bonk->GetString(BONK_STRING_GOSSIP_RESET_TALENTS).c_str(), SENDER_BUY, MASTERY_ACTION_RESPEC);

    player->SEND_GOSSIP_MENU(BONK_TEXT_MASTERY, creature->GetObjectGuid());
    return true;
}

bool GossipSelect_npc_bonk_mastery(Player* player, Creature* creature, uint32 , uint32 action)
{
    std::string message;
    if (action == MASTERY_ACTION_RESPEC)
        player->GetBonkPlayer()->ResetMastery(message);
    else if (action > GOSSIP_ACTION_INFO_DEF)
        player->GetBonkPlayer()->LearnMastery(action - GOSSIP_ACTION_INFO_DEF, message);
    if (!message.empty())
        player->GetBonkPlayer()->Notify(message);

    return GossipHello_npc_bonk_mastery(player, creature);
}

bool GOHello_go_bonk_chest(Player* player, GameObject* go)
{
    if (BonkRun* run = player->GetBonkPlayer()->GetRun())
        run->UseChest(go);
    return true;
}

bool GossipHello_npc_bonk_vendor(Player* player, Creature* creature)
{
    if (BonkRun* run = player->GetBonkPlayer()->GetRun())
        run->OpenVendor(creature);
    return true;
}

bool GOHello_go_bonk_shrine(Player* player, GameObject* go)
{
    if (BonkRun* run = player->GetBonkPlayer()->GetRun())
        run->UseShrine(go);
    return true;
}

bool GOHello_go_bonk_portal(Player* player, GameObject* go)
{
    BonkRun* run = player->GetBonkPlayer()->GetRun();
    BonkRun* portalRun = run && run->IsOwnPortal(go) ? run : BonkCoop::GroupPortalRun(player, go);
    if (!portalRun)
        return true;

    if (portalRun->GetStage() >= portalRun->GetTier().stages)
    {
        if (portalRun == run)
            player->ADD_GOSSIP_ITEM(GOSSIP_ICON_TAXI, run->GetString(BONK_STRING_PORTAL_FINISH_RUN).c_str(), GOSSIP_SENDER_MAIN, PORTAL_ACTION_HOME);
        if (portalRun->GetNextMap())
            player->ADD_GOSSIP_ITEM(GOSSIP_ICON_BATTLE, run->GetString(BONK_STRING_PORTAL_CONTINUE_ENDLESS).c_str(), GOSSIP_SENDER_MAIN, PORTAL_ACTION_ENDLESS);
        player->SEND_GOSSIP_MENU(BONK_TEXT_PORTAL_FINAL, go->GetObjectGuid());
        return true;
    }

    if (BonkMap const* next = portalRun->GetNextMap())
    {
        std::string const mapName = run->Localize(BONK_FIELD_MAP_NAME, next->id, next->name);
        std::string const text = run->GetString(BONK_STRING_PORTAL_NEXT_STAGE, { std::to_string(portalRun->GetStage() + 1), mapName });
        player->ADD_GOSSIP_ITEM(GOSSIP_ICON_BATTLE, text.c_str(), GOSSIP_SENDER_MAIN, PORTAL_ACTION_NEXT);
    }
    if (portalRun == run)
        player->ADD_GOSSIP_ITEM(GOSSIP_ICON_TAXI, run->GetString(BONK_STRING_PORTAL_RETURN_HOME).c_str(), GOSSIP_SENDER_MAIN, PORTAL_ACTION_HOME);
    player->SEND_GOSSIP_MENU(BONK_TEXT_PORTAL, go->GetObjectGuid());
    return true;
}

bool GOGossipSelect_go_bonk_portal(Player* player, GameObject* go, uint32 , uint32 action)
{
    BonkRun* run = player->GetBonkPlayer()->GetRun();
    if (run && action == PORTAL_ACTION_ENDLESS && player->GetBonkPlayer()->IsAddonReady() && (run->IsOwnPortal(go) || BonkCoop::GroupPortalRun(player, go)))
    {
        player->CLOSE_GOSSIP_MENU();
        if (player->GetBonkPlayer()->IsAddonReady())
        {
            WorldPacket data(SMSG_HOA_MESSAGE);
            HoAWritePortalEndless(data);
            player->GetSession()->SendPacket(&data);
        }
        return true;
    }
    if (action == PORTAL_ACTION_ENDLESS)
        action = PORTAL_ACTION_NEXT;
    if (run && action == PORTAL_ACTION_NEXT && BonkCoop::InGroupRun(player) && (run->IsOwnPortal(go) || BonkCoop::GroupPortalRun(player, go)))
    {
        player->CLOSE_GOSSIP_MENU();
        BonkCoop::RequestNextStage(player);
        return true;
    }
    if (!run || !run->IsOwnPortal(go))
    {
        player->CLOSE_GOSSIP_MENU();
        return true;
    }

    if (action == PORTAL_ACTION_HOME && player->GetBonkPlayer()->IsAddonReady())
    {
        player->CLOSE_GOSSIP_MENU();
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWritePortalHome(data, run->IsVaultEmptyWithFinds(), run->GetStage() >= run->GetTier().stages);
        player->GetSession()->SendPacket(&data);
        return true;
    }
    if (action == PORTAL_ACTION_HOME && run->IsVaultEmptyWithFinds())
    {
        player->PlayerTalkClass->ClearMenus();
        player->ADD_GOSSIP_ITEM(GOSSIP_ICON_TAXI, run->GetString(BONK_STRING_PORTAL_GO_HOME_ANYWAY).c_str(), GOSSIP_SENDER_MAIN, PORTAL_ACTION_HOME_SURE);
        player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, run->GetString(BONK_STRING_PORTAL_BACK).c_str(), GOSSIP_SENDER_MAIN, PORTAL_ACTION_BACK);
        player->SEND_GOSSIP_MENU(BONK_TEXT_VAULT_EMPTY, go->GetObjectGuid());
        return true;
    }
    if (action == PORTAL_ACTION_BACK)
    {
        player->PlayerTalkClass->ClearMenus();
        return GOHello_go_bonk_portal(player, go);
    }

    player->CLOSE_GOSSIP_MENU();
    if (action == PORTAL_ACTION_NEXT)
        run->EnterNextStage();
    else if (action == PORTAL_ACTION_HOME || action == PORTAL_ACTION_HOME_SURE)
        run->GoHome();
    return true;
}

bool GOHello_go_bonk_hidden(Player* player, GameObject* go)
{
    if (BonkRun* run = player->GetBonkPlayer()->GetRun())
        run->UseHidden(go);
    return true;
}

bool GOHello_go_bonk_vault(Player* player, GameObject* go)
{
    BonkRun* run = player->GetBonkPlayer()->GetRun();
    if (!run || !run->IsOwnVault(go))
    {
        if (Player* owner = BonkCoop::VaultOwner(player, go))
            if (owner != player)
                player->GetBonkPlayer()->Notify(BONK_STRING_COOP_VAULT_NOT_YOURS, { owner->GetName() });
        return true;
    }

    if (player->GetBonkPlayer()->IsAddonReady())
    {
        run->UseVault();
        return true;
    }

    if (run->IsHearthVaultReady())
    {
        for (BonkRun::VaultFind const& find : run->GetVaultFinds())
            if (ItemPrototype const* proto = sObjectMgr.GetItemPrototype(find.entry))
                player->ADD_GOSSIP_ITEM(GOSSIP_ICON_VENDOR, player->GetBonkPlayer()->GetString(BONK_STRING_VAULT_GOSSIP_SEND,
                    { player->GetBonkPlayer()->GetItemName(proto) }).c_str(), SENDER_VAULT_SEND, find.guid.GetCounter());
        player->SEND_GOSSIP_MENU(BONK_TEXT_VAULT, go->GetObjectGuid());
        return true;
    }

    for (BonkRun::VaultFind const& find : run->GetVaultFinds())
    {
        ItemPrototype const* proto = sObjectMgr.GetItemPrototype(find.entry);
        if (!proto)
            continue;
        BonkPlayer const* bonk = player->GetBonkPlayer();
        std::string const text = find.inVault ? bonk->GetString(BONK_STRING_VAULT_GOSSIP_TAKE, { bonk->GetItemName(proto) }) :
            bonk->GetString(BONK_STRING_VAULT_GOSSIP_PUT, { bonk->GetItemName(proto), FormatBonkMoney(find.sellCopper, bonk->GetLocale()) });
        player->ADD_GOSSIP_ITEM(find.inVault ? GOSSIP_ICON_INTERACT_1 : GOSSIP_ICON_VENDOR, text.c_str(),
            find.inVault ? SENDER_VAULT_TAKE : SENDER_VAULT_PUT, find.guid.GetCounter());
    }
    player->SEND_GOSSIP_MENU(BONK_TEXT_VAULT, go->GetObjectGuid());
    return true;
}

bool GOGossipSelect_go_bonk_vault(Player* player, GameObject* go, uint32 sender, uint32 action)
{
    BonkRun* run = player->GetBonkPlayer()->GetRun();
    if (!run || !run->IsOwnVault(go))
    {
        player->CLOSE_GOSSIP_MENU();
        return true;
    }

    std::string error;
    bool const done = sender == SENDER_VAULT_SEND ? run->SendHomeFromHearth(action, error) :
        sender == SENDER_VAULT_TAKE ? run->TakeFromVault(action, error) : run->PutInVault(action, error);
    if (!done)
        player->GetBonkPlayer()->Notify(error);
    player->PlayerTalkClass->ClearMenus();
    return GOHello_go_bonk_vault(player, go);
}

bool GossipHello_npc_bonk_coop(Player* player, Creature* creature)
{
    BonkPlayer const* bonk = player->GetBonkPlayer();
    bool const host = BonkCoop::IsGroupHost(player);
    auto item = [bonk, host](BonkString setting)
    {
        std::string const text = bonk->GetString(setting);
        return host ? bonk->GetString(BONK_STRING_COOP_SETTING_CHANGE, { text }) : text;
    };
    std::string const pause = item(BonkCoop::SharesPause(player) ? BONK_STRING_COOP_SETTING_PAUSE_SHARED : BONK_STRING_COOP_SETTING_PAUSE_OFF);
    std::string const xp = item(BonkCoop::SharesXp(player) ? BONK_STRING_COOP_SETTING_XP_SHARED : BONK_STRING_COOP_SETTING_XP_OWN);
    player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, pause.c_str(), GOSSIP_SENDER_MAIN, COOP_ACTION_PAUSE);
    player->ADD_GOSSIP_ITEM(GOSSIP_ICON_CHAT, xp.c_str(), GOSSIP_SENDER_MAIN, COOP_ACTION_XP);
    player->SEND_GOSSIP_MENU(BONK_TEXT_COOP, creature->GetObjectGuid());
    return true;
}

bool GossipSelect_npc_bonk_coop(Player* player, Creature* creature, uint32 , uint32 action)
{
    if (!BonkCoop::IsGroupHost(player))
    {
        player->CLOSE_GOSSIP_MENU();
        player->GetBonkPlayer()->Notify(BONK_STRING_COOP_ONLY_HOST_SETTINGS);
        return true;
    }
    if (action == COOP_ACTION_PAUSE)
        BonkCoop::SetSharedPause(player, !BonkCoop::SharesPause(player));
    else if (action == COOP_ACTION_XP)
        BonkCoop::SetSharedXp(player, !BonkCoop::SharesXp(player));
    player->PlayerTalkClass->ClearMenus();
    return GossipHello_npc_bonk_coop(player, creature);
}

void AddSC_bonk_npcs()
{
    Script* newscript;

    newscript = new Script;
    newscript->Name = "npc_bonk_coop";
    newscript->pGossipHello = &GossipHello_npc_bonk_coop;
    newscript->pGossipSelect = &GossipSelect_npc_bonk_coop;
    newscript->RegisterSelf();

    newscript = new Script;
    newscript->Name = "npc_bonk_run_master";
    newscript->pGossipHello = &GossipHello_npc_bonk_run_master;
    newscript->pGossipSelect = &GossipSelect_npc_bonk_run_master;
    newscript->RegisterSelf();

    newscript = new Script;
    newscript->Name = "npc_bonk_quartermaster";
    newscript->pGossipHello = &GossipHello_npc_bonk_quartermaster;
    newscript->pGossipSelect = &GossipSelect_npc_bonk_quartermaster;
    newscript->RegisterSelf();

    newscript = new Script;
    newscript->Name = "npc_bonk_talents";
    newscript->pGossipHello = &GossipHello_npc_bonk_talents;
    newscript->pGossipSelect = &GossipSelect_npc_bonk_talents;
    newscript->RegisterSelf();

    newscript = new Script;
    newscript->Name = "npc_bonk_mastery";
    newscript->pGossipHello = &GossipHello_npc_bonk_mastery;
    newscript->pGossipSelect = &GossipSelect_npc_bonk_mastery;
    newscript->RegisterSelf();

    newscript = new Script;
    newscript->Name = "go_bonk_chest";
    newscript->pGOHello = &GOHello_go_bonk_chest;
    newscript->RegisterSelf();

    newscript = new Script;
    newscript->Name = "npc_bonk_vendor";
    newscript->pGossipHello = &GossipHello_npc_bonk_vendor;
    newscript->RegisterSelf();

    newscript = new Script;
    newscript->Name = "go_bonk_shrine";
    newscript->pGOHello = &GOHello_go_bonk_shrine;
    newscript->RegisterSelf();

    newscript = new Script;
    newscript->Name = "go_bonk_portal";
    newscript->pGOHello = &GOHello_go_bonk_portal;
    newscript->pGOGossipSelect = &GOGossipSelect_go_bonk_portal;
    newscript->RegisterSelf();

    newscript = new Script;
    newscript->Name = "go_bonk_hidden";
    newscript->pGOHello = &GOHello_go_bonk_hidden;
    newscript->RegisterSelf();

    newscript = new Script;
    newscript->Name = "go_bonk_vault";
    newscript->pGOHello = &GOHello_go_bonk_vault;
    newscript->pGOGossipSelect = &GOGossipSelect_go_bonk_vault;
    newscript->RegisterSelf();
}

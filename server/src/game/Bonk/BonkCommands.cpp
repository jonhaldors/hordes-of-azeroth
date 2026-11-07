#include "Bag.h"
#include "BonkCoop.h"
#include "BonkCodex.h"
#include "BonkEnchant.h"
#include "BonkLeaderboard.h"
#include "BonkLocale.h"
#include "BonkMgr.h"
#include "BonkMobAI.h"
#include "BonkPlayer.h"
#include "BonkQuests.h"
#include "BonkRun.h"
#include "CellImpl.h"
#include "Chat.h"
#include "Creature.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Player.h"
#include "TemporarySummon.h"
#include "WorldSession.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <list>

namespace
{
    float const BONK_MOBINFO_SEARCH_RANGE = 50.0f;

    std::string GetString(WorldSession* session, BonkString id, std::vector<std::string> const& args = {})
    {
        return session->GetPlayer()->GetBonkPlayer()->GetString(id, args);
    }

    Creature* FindNearestEnemy(Player* player)
    {
        std::list<Creature*> creatures;
        MaNGOS::AnyUnitInObjectRangeCheck check(player, BONK_MOBINFO_SEARCH_RANGE);
        MaNGOS::CreatureListSearcher<MaNGOS::AnyUnitInObjectRangeCheck> searcher(creatures, check);
        Cell::VisitGridObjects(player, searcher, BONK_MOBINFO_SEARCH_RANGE);

        Creature* nearest = nullptr;
        for (Creature* creature : creatures)
            if (!creature->IsFriendlyTo(player) && (!nearest || player->GetDistance(creature) < player->GetDistance(nearest)))
                nearest = creature;
        return nearest;
    }

    char const* YesNo(bool value)
    {
        return value ? "yes" : "no";
    }

    void SendAddonData(Player* player)
    {
        BonkPlayer* bonk = player->GetBonkPlayer();
        if (BonkRun* run = bonk->GetRun())
            run->SetMenuOpen(false);
        bonk->SendTierList();
        bonk->SendGearInfo();
        BonkMobAI::SendAffixInfo(bonk);
        BonkCodex::SendKeywordGlossary(bonk);
        bonk->SendGlyphInfo();
        bonk->SendMasteryState();
        bonk->FlushMasteryNotice();
        bonk->SendWallet();
        bonk->SendDash();
        bonk->SendDetermination();
        sBonkQuests.SendLog(player, "");
        if (BonkRun* run = bonk->GetRun())
            run->SendFullState();
    }
}

bool ChatHandler::HandleBonkPerfDipCommand(char*)
{
    if (BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun())
        run->LogPerfDip();
    return true;
}

bool ChatHandler::HandleBonkStarterCommand(char* args)
{
    Player* player = m_session->GetPlayer();
    uint32 weaponId = 0;
    if (!ExtractUInt32(&args, weaponId))
    {
        player->GetBonkPlayer()->SendStarters();
        return true;
    }

    std::string error;
    if (!player->GetBonkPlayer()->ChooseStarter(weaponId, error))
    {
        SendSysMessage(error.c_str());
        SetSentErrorMessage(true);
        return false;
    }
    return true;
}

bool ChatHandler::HandleBonkStartCommand(char* args)
{
    Player* player = m_session->GetPlayer();
    if (!player->IsAlive())
    {
        SendSysMessage(GetString(m_session, BONK_STRING_CANT_START_RUN_WHILE_DEAD).c_str());
        SetSentErrorMessage(true);
        return false;
    }
    char* key = ExtractArg(&args);

    BonkTier const* tier = key ? sBonkMgr.FindTier(key) : nullptr;
    if (!tier)
    {
        SendSysMessage(GetString(m_session, BONK_STRING_CHOOSE_DIFFICULTY_HEADER).c_str());
        player->GetBonkPlayer()->SendTierList();
        SetSentErrorMessage(true);
        return false;
    }

    BonkRunChoice choice;
    while (char* word = ExtractArg(&args))
    {
        std::string const option = word;
        if (option == "random")
            continue;
        if (option == "invade")
            choice.invade = true;
        else if (option == "nopause")
            choice.noPause = true;
        else if (isdigit(static_cast<unsigned char>(option[0])))
            choice.level = tier->firstLevel + std::max(1u, uint32(atoi(option.c_str()))) - 1;
        else if (BonkMap const* dungeon = sBonkMgr.FindDungeon(option))
            choice.dungeon = dungeon;
        else if (BonkMap const* map = sBonkMgr.FindTierMap(*tier, option))
            choice.startMap = map;
        else
        {
            SendSysMessage(GetString(m_session, BONK_STRING_NO_ZONE_OR_DUNGEON_CALLED,
                { m_session->GetPlayer()->GetBonkPlayer()->Localize(BONK_FIELD_TIER_NAME, tier->id, tier->name), option }).c_str());
            SetSentErrorMessage(true);
            return false;
        }
    }

    std::string error;
    if (!player->GetBonkPlayer()->StartRun(*tier, error, choice))
    {
        SendSysMessage(error.c_str());
        SetSentErrorMessage(true);
        return false;
    }
    return true;
}

bool ChatHandler::HandleBonkStopCommand(char*)
{
    BonkPlayer* bonk = m_session->GetPlayer()->GetBonkPlayer();
    if (!bonk->GetRun())
    {
        SendSysMessage(GetString(m_session, BONK_STRING_NOT_IN_A_RUN).c_str());
        SetSentErrorMessage(true);
        return false;
    }

    bonk->StopRun();
    return true;
}

bool ChatHandler::HandleBonkHomeCommand(char*)
{
    BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun();
    if (!run)
    {
        SendSysMessage(GetString(m_session, BONK_STRING_NOT_IN_A_RUN).c_str());
        SetSentErrorMessage(true);
        return false;
    }

    run->GoHome();
    return true;
}

bool ChatHandler::HandleBonkEndlessCommand(char*)
{
    Player* player = m_session->GetPlayer();
    BonkRun* run = player->GetBonkPlayer()->GetRun();
    if (!run)
    {
        SendSysMessage(GetString(m_session, BONK_STRING_NOT_IN_A_RUN).c_str());
        SetSentErrorMessage(true);
        return false;
    }

    if (BonkCoop::InGroupRun(player))
        BonkCoop::RequestNextStage(player);
    else if (run->GetStage() >= run->GetTier().stages)
        run->EnterNextStage();
    return true;
}

bool ChatHandler::HandleBonkPickCommand(char* args)
{
    BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun();
    uint32 choice;
    if (!ExtractUInt32(&args, choice))
        return false;

    std::string error = GetString(m_session, BONK_STRING_NOT_IN_A_RUN);
    if (!run || !run->Pick(choice, error))
    {
        SendSysMessage(error.c_str());
        SetSentErrorMessage(true);
        return false;
    }
    return true;
}

bool ChatHandler::HandleBonkRerollCommand(char*)
{
    BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun();
    std::string error = GetString(m_session, BONK_STRING_NOT_IN_A_RUN);
    if (!run || !run->Reroll(error))
    {
        SendSysMessage(error.c_str());
        SetSentErrorMessage(true);
        return false;
    }
    return true;
}

bool ChatHandler::HandleBonkBanishCommand(char* args)
{
    uint32 choice;
    if (!ExtractUInt32(&args, choice))
        return false;

    BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun();
    std::string error = GetString(m_session, BONK_STRING_NOT_IN_A_RUN);
    if (!run || !run->Banish(choice, error))
    {
        SendSysMessage(error.c_str());
        SetSentErrorMessage(true);
        return false;
    }
    return true;
}

bool ChatHandler::HandleBonkPassCommand(char*)
{
    BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun();
    std::string error = GetString(m_session, BONK_STRING_NOT_IN_A_RUN);
    if (!run || !run->Skip(error))
    {
        SendSysMessage(error.c_str());
        SetSentErrorMessage(true);
        return false;
    }
    return true;
}

bool ChatHandler::HandleBonkLockCommand(char* args)
{
    uint32 choice;
    if (!ExtractUInt32(&args, choice))
        return false;

    BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun();
    std::string error = GetString(m_session, BONK_STRING_NOT_IN_A_RUN);
    if (!run || !run->Lock(choice, error))
    {
        SendSysMessage(error.c_str());
        SetSentErrorMessage(true);
        return false;
    }
    return true;
}

bool ChatHandler::HandleBonkLearnCommand(char* args)
{
    uint32 id;
    if (!ExtractUInt32(&args, id))
        return false;

    m_session->GetPlayer()->GetBonkPlayer()->ShopLearn(id);
    return true;
}

bool ChatHandler::HandleBonkUnlearnCommand(char* args)
{
    uint32 id;
    if (!ExtractUInt32(&args, id))
        return false;

    m_session->GetPlayer()->GetBonkPlayer()->ShopUnlearn(id);
    return true;
}

bool ChatHandler::HandleBonkRespecCommand(char*)
{
    m_session->GetPlayer()->GetBonkPlayer()->ShopRespec();
    return true;
}

bool ChatHandler::HandleBonkPresetCommand(char* args)
{
    uint32 slot;
    if (!ExtractUInt32(&args, slot))
        return false;

    m_session->GetPlayer()->GetBonkPlayer()->ShopPreset(uint8(std::min(slot, 255u)));
    return true;
}

bool ChatHandler::HandleBonkToggleCommand(char* args)
{
    uint32 id;
    if (!ExtractUInt32(&args, id))
        return false;

    m_session->GetPlayer()->GetBonkPlayer()->ShopToggle(id);
    return true;
}

bool ChatHandler::HandleBonkShardsCommand(char* args)
{
    uint32 count;
    if (!ExtractUInt32(&args, count) || !count)
        return false;

    Player* target = GetSelectedPlayer();
    if (!target)
        target = m_session->GetPlayer();

    target->GetBonkPlayer()->AddShards(count);
    PSendSysMessage("%s now has %s.", target->GetName(), FormatBonkShards(target->GetBonkPlayer()->GetShards()).c_str());
    return true;
}

bool ChatHandler::HandleBonkCoopSettingsCommand(char* args)
{
    Player* player = m_session->GetPlayer();
    char* setting = ExtractLiteralArg(&args);
    if (!setting)
        return false;
    if (!BonkCoop::IsGroupHost(player))
    {
        SendSysMessage("Only the host can change the group settings.");
        SetSentErrorMessage(true);
        return false;
    }
    std::string const which = setting;
    if (which == "pause")
        BonkCoop::SetSharedPause(player, !BonkCoop::SharesPause(player));
    else if (which == "xp")
        BonkCoop::SetSharedXp(player, !BonkCoop::SharesXp(player));
    else
        return false;
    return true;
}

bool ChatHandler::HandleBonkPortalCommand(char*)
{
    BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun();
    if (!run || !run->ForcePortal())
    {
        SendSysMessage("You need to be fighting on a stage of a run.");
        SetSentErrorMessage(true);
        return false;
    }
    SendSysMessage("The portal is open.");
    return true;
}

bool ChatHandler::HandleBonkSkipCommand(char* args)
{
    BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun();
    if (!run || run->IsSandbox())
    {
        SendSysMessage(run ? "The sandbox has no stage clock." : "You are not in a run.");
        SetSentErrorMessage(true);
        return false;
    }

    if (run->IsPortalOpen())
    {
        run->EnterNextStage();
        SendSysMessage(run->IsPortalOpen() ? "Still at the portal." : "Entered the next stage.");
        return true;
    }

    uint32 seconds = 0;
    if (*args && !ExtractUInt32(&args, seconds))
        return false;

    std::string error;
    if (!run->SkipTime(seconds, error))
    {
        SendSysMessage(error.c_str());
        SetSentErrorMessage(true);
        return false;
    }

    SendSysMessage(seconds ? "Skipped ahead." : "Skipped to the boss.");
    return true;
}

bool ChatHandler::HandleBonkMenuCommand(char* args)
{
    uint32 open = 0;
    if (!ExtractUInt32(&args, open))
        return false;
    if (BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun())
        run->SetMenuOpen(open != 0);
    return true;
}

bool ChatHandler::HandleBonkResyncCommand(char* )
{
    if (BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun())
        run->ResyncPause();
    return true;
}

bool ChatHandler::HandleBonkStatsCommand(char* args)
{
    char* watching = ExtractLiteralArg(&args);
    m_session->GetPlayer()->GetBonkPlayer()->WatchStats(watching && !strcmp(watching, "on"));
    return true;
}

bool ChatHandler::HandleBonkVaultCommand(char* args)
{
    BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun();
    char* action = ExtractLiteralArg(&args);
    if (action && !strcmp(action, "close"))
    {
        if (run)
            run->CloseVault();
        return true;
    }
    uint32 guidLow = 0;
    bool const known = action && (!strcmp(action, "put") || !strcmp(action, "take") || !strcmp(action, "send"));
    if (!run || !known || !ExtractUInt32(&args, guidLow))
    {
        SendSysMessage(GetString(m_session, run ? BONK_STRING_VAULT_USAGE : BONK_STRING_NOT_IN_A_RUN).c_str());
        SetSentErrorMessage(true);
        return false;
    }

    std::string error;
    bool done = false;
    if (!strcmp(action, "send"))
        done = run->SendHomeFromHearth(guidLow, error);
    else if (!strcmp(action, "put"))
        done = run->PutInVault(guidLow, error);
    else
        done = run->TakeFromVault(guidLow, error);
    if (!done)
        m_session->GetPlayer()->GetBonkPlayer()->Notify(error);
    return true;
}

bool ChatHandler::HandleBonkBanSlotCommand(char* args)
{
    char* kind = ExtractLiteralArg(&args);
    BonkQuestReward const type = kind && !strcmp(kind, "c") ? BONK_REWARD_CARD : kind && !strcmp(kind, "g") ? BONK_REWARD_GLYPH : MAX_BONK_REWARD;
    if (type == MAX_BONK_REWARD)
    {
        SendSysMessage(GetString(m_session, BONK_STRING_BANSLOT_USAGE).c_str());
        SetSentErrorMessage(true);
        return false;
    }

    Player* player = m_session->GetPlayer();
    BonkPlayer* bonk = player->GetBonkPlayer();
    std::string message;
    bonk->BuyBanSlot(type, message);
    bonk->Notify(message);
    BonkCodex::Send(player, "", bonk->IsAtDeck());
    return true;
}

bool ChatHandler::HandleBonkPoolCommand(char* args)
{
    char* kind = ExtractLiteralArg(&args);
    uint32 id = 0;
    BonkQuestReward type = MAX_BONK_REWARD;
    if (kind && !strcmp(kind, "w"))
        type = BONK_REWARD_WEAPON;
    else if (kind && !strcmp(kind, "p"))
        type = BONK_REWARD_PASSIVE;
    else if (kind && !strcmp(kind, "c"))
        type = BONK_REWARD_CARD;
    else if (kind && !strcmp(kind, "g"))
        type = BONK_REWARD_GLYPH;
    char* state = nullptr;
    if (type != MAX_BONK_REWARD && ExtractUInt32(&args, id))
        state = ExtractLiteralArg(&args);
    if (!state || (strcmp(state, "on") && strcmp(state, "off")))
    {
        SendSysMessage(GetString(m_session, BONK_STRING_POOL_USAGE).c_str());
        SetSentErrorMessage(true);
        return false;
    }

    Player* player = m_session->GetPlayer();
    if (player->GetBonkPlayer()->GetRun())
    {
        SendSysMessage(GetString(m_session, BONK_STRING_CANT_CHANGE_POOL_DURING_RUN).c_str());
        SetSentErrorMessage(true);
        return false;
    }
    std::string error;
    if (!sBonkQuests.SetDisabled(player->GetBonkPlayer()->GetProgressAccount(), type, id, !strcmp(state, "off"),
        player->GetBonkPlayer()->GetBanSlots(type), error, player->GetBonkPlayer()->GetLocale()))
        player->GetBonkPlayer()->Notify(error);
    BonkCodex::Send(player, "", player->GetBonkPlayer()->IsAtDeck());
    return true;
}

bool ChatHandler::HandleBonkGlyphCommand(char* args)
{
    BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun();
    if (run && args && !strcmp(args, "reroll"))
    {
        std::string error;
        if (run->RerollGlyphs(error))
            return true;
        SendSysMessage(error.c_str());
        SetSentErrorMessage(true);
        return false;
    }
    uint32 choice = 0;
    if (!run || !ExtractUInt32(&args, choice))
    {
        SendSysMessage(GetString(m_session, run ? BONK_STRING_GLYPH_USAGE : BONK_STRING_NOT_IN_A_RUN).c_str());
        SetSentErrorMessage(true);
        return false;
    }
    std::string error;
    if (!run->ChooseGlyph(choice, error))
    {
        SendSysMessage(error.c_str());
        SetSentErrorMessage(true);
        return false;
    }
    return true;
}

bool ChatHandler::HandleBonkTitleCommand(char* args)
{
    BonkPlayer* bonk = m_session->GetPlayer()->GetBonkPlayer();
    uint32 titleId = 0;
    if (!ExtractUInt32(&args, titleId))
    {
        bonk->SendTitles();
        return true;
    }
    std::string error;
    if (!bonk->SetTitle(titleId, error))
    {
        SendSysMessage(error.c_str());
        SetSentErrorMessage(true);
        return false;
    }
    return true;
}

bool ChatHandler::HandleBonkGearCommand(char* args)
{
    std::string const tab = args ? args : "";
    if (tab.compare(0, 8, "upgrade ") == 0)
    {
        std::string error;
        if (!m_session->GetPlayer()->GetBonkPlayer()->UpgradeFoundGear(uint32(atoi(tab.c_str() + 8)), error))
            m_session->GetPlayer()->GetBonkPlayer()->Notify(error);
        return true;
    }
    if (tab.compare(0, 11, "rerollpick ") == 0 || tab.compare(0, 7, "reroll ") == 0)
    {
        bool const pick = tab.compare(0, 11, "rerollpick ") == 0;
        uint32 guidLow = 0, index = 0;
        sscanf(tab.c_str() + (pick ? 11 : 7), "%u %u", &guidLow, &index);
        BonkPlayer* bonk = m_session->GetPlayer()->GetBonkPlayer();
        std::string error;
        if (!(pick ? bonk->PickFoundReroll(guidLow, uint8(index), error) : bonk->RerollFoundGear(guidLow, uint8(index), error)))
            bonk->Notify(error);
        return true;
    }
    if (tab.compare(0, 10, "testfound ") == 0 && GetAccessLevel() >= SEC_GAMEMASTER)
    {
        uint32 tier = 1, lines = 0;
        sscanf(tab.c_str() + 10, "%u %u", &tier, &lines);
        std::string error;
        if (!m_session->GetPlayer()->GetBonkPlayer()->GiveTestFoundGear(tier, lines, error))
            m_session->GetPlayer()->GetBonkPlayer()->Notify(error);
        return true;
    }
    if (tab == "testshop" && GetAccessLevel() >= SEC_GAMEMASTER)
    {
        Player* player = m_session->GetPlayer();
        uint32 const quartermasterEntry = 900002;
        if (Creature* quartermaster = player->FindNearestCreature(quartermasterEntry, 10.0f))
            player->GetBonkPlayer()->OpenShop(BONK_SHOP_UPGRADES, quartermaster);
        else
            SendSysMessage("No Quartermaster within 10 yards.");
        return true;
    }
    if (tab == "testticket" && GetAccessLevel() >= SEC_GAMEMASTER)
    {
        if (BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun())
            run->PlaceTicketsAhead();
        else
            SendSysMessage("Tickets need a run.");
        return true;
    }
    if (tab == "testglyph" && GetAccessLevel() >= SEC_GAMEMASTER)
    {
        if (BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun())
            run->GiveGlyphPickNow();
        else
            SendSysMessage("Glyph picks need a run.");
        return true;
    }
    if (tab == "testsayge" && GetAccessLevel() >= SEC_GAMEMASTER)
    {
        Player* player = m_session->GetPlayer();
        uint32 const saygeEntry = 900003;
        if (Creature* sayge = player->FindNearestCreature(saygeEntry, 10.0f))
            player->GetBonkPlayer()->OpenShop(BONK_SHOP_TALENTS, sayge);
        else
            SendSysMessage("No Sayge within 10 yards.");
        return true;
    }
    if (tab.compare(0, 12, "testtabards ") == 0 && GetAccessLevel() >= SEC_GAMEMASTER)
    {
        BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun();
        uint32 const rolls = uint32(atoi(tab.c_str() + 12));
        if (!run)
            SendSysMessage("You are not in a run.");
        else
            for (uint32 roll = 0; roll < rolls; ++roll)
                run->RollGroupTabardDrops();
        return true;
    }
    if (tab.compare(0, 9, "testbags ") == 0 && GetAccessLevel() >= SEC_GAMEMASTER)
    {
        BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun();
        Creature* mob = GetSelectedCreature();
        if (run && !mob)
            for (ObjectGuid const& guid : run->GetMobGuids())
                if ((mob = m_session->GetPlayer()->GetMap()->GetCreature(guid)))
                    break;
        if (!run || !mob)
            SendSysMessage("Target a creature in a run.");
        else
            run->DropTestBags(mob, uint32(atoi(tab.c_str() + 9)));
        return true;
    }
    if (tab == "testvault" && GetAccessLevel() >= SEC_GAMEMASTER)
    {
        BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun();
        if (run)
            PSendSysMessage("Put %u run gear pieces in the vault.", run->PutRunGearInVault());
        else
            SendSysMessage("You are not in a run.");
        return true;
    }
    if (tab == "testhearth" && GetAccessLevel() >= SEC_GAMEMASTER)
    {
        Player* player = m_session->GetPlayer();
        BonkRun* run = player->GetBonkPlayer()->GetRun();
        if (run && run->IsHearthVaultReady())
        {
            run->UseVault();
            return true;
        }
        Item* stone = nullptr;
        for (uint8 slot = INVENTORY_SLOT_ITEM_START; slot < INVENTORY_SLOT_ITEM_END && !stone; ++slot)
            if (Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
                if (item->GetEntry() == BONK_ITEM_HEARTHSTONE)
                    stone = item;
        for (uint8 bag = INVENTORY_SLOT_BAG_START; bag < INVENTORY_SLOT_BAG_END && !stone; ++bag)
            if (Bag* container = dynamic_cast<Bag*>(player->GetItemByPos(INVENTORY_SLOT_BAG_0, bag)))
                stone = container->GetItemByEntry(BONK_ITEM_HEARTHSTONE);
        if (!stone || !run || !run->UseItem(stone))
            SendSysMessage("You need a Hearthstone in a run.");
        return true;
    }
    if (tab == "enchant open" || tab == "enchant discard" || tab.compare(0, 13, "enchant pick ") == 0 || tab.compare(0, 13, "enchant roll ") == 0)
    {
        Player* player = m_session->GetPlayer();
        BonkRun* run = player->GetBonkPlayer()->GetRun();
        std::string error;
        if (!run)
            error = GetString(m_session, BONK_STRING_ENCHANTER_ONLY_DURING_RUN);
        else if (tab == "enchant open")
            run->OpenEnchanter();
        else if (tab == "enchant discard")
            run->DiscardEnchantOffers();
        else if (tab.compare(0, 13, "enchant pick ") == 0)
            run->PickEnchant(uint8(atoi(tab.c_str() + 13)), error);
        else
            run->RollEnchant(uint8(atoi(tab.c_str() + 13)), error);
        if (!error.empty())
            player->GetBonkPlayer()->Notify(error);
        return true;
    }
    if (tab == "found")
    {
        m_session->GetPlayer()->GetBonkPlayer()->SendFoundItems();
        return true;
    }

    BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun();
    if (!run)
    {
        SendSysMessage(GetString(m_session, BONK_STRING_NOT_IN_A_RUN).c_str());
        SetSentErrorMessage(true);
        return false;
    }

    std::string const choice = args ? args : "";
    bool const equipInSlot = choice.compare(0, 6, "equip ") == 0;
    if (choice != "equip" && choice != "loot" && choice != "salvage" && !equipInSlot)
    {
        SendSysMessage(GetString(m_session, BONK_STRING_GEAR_USAGE).c_str());
        SetSentErrorMessage(true);
        return false;
    }

    std::string error;
    uint8 const slot = equipInSlot ? uint8(atoi(choice.c_str() + 6)) : uint8(NULL_SLOT);
    BonkRun::GearChoice const gearChoice = choice == "loot" ? BonkRun::GEAR_CHOICE_LOOT :
        choice == "salvage" ? BonkRun::GEAR_CHOICE_SALVAGE : BonkRun::GEAR_CHOICE_EQUIP;
    if (!run->ChooseGear(gearChoice, slot, error))
    {
        SendSysMessage(error.c_str());
        SetSentErrorMessage(true);
        return false;
    }
    return true;
}

bool ChatHandler::HandleBonkCardCommand(char* args)
{
    BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun();
    if (!run)
    {
        SendSysMessage(GetString(m_session, BONK_STRING_NOT_IN_A_RUN).c_str());
        SetSentErrorMessage(true);
        return false;
    }

    uint32 cardId = 0;
    if (!ExtractUInt32(&args, cardId))
        return false;

    std::string error;
    if (!run->GiveCard(cardId, error))
    {
        SendSysMessage(error.c_str());
        SetSentErrorMessage(true);
        return false;
    }
    return true;
}

bool ChatHandler::HandleBonkEvolveCommand(char* args)
{
    BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun();
    if (!run)
    {
        SendSysMessage(GetString(m_session, BONK_STRING_NOT_IN_A_RUN).c_str());
        SetSentErrorMessage(true);
        return false;
    }

    uint32 weaponId = 0;
    if (!ExtractUInt32(&args, weaponId))
        return false;

    std::string error;
    if (!run->ForceEvolve(weaponId, error))
    {
        SendSysMessage(error.c_str());
        SetSentErrorMessage(true);
        return false;
    }
    return true;
}

bool ChatHandler::HandleBonkPassiveCommand(char* args)
{
    BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun();
    if (!run)
    {
        SendSysMessage(GetString(m_session, BONK_STRING_NOT_IN_A_RUN).c_str());
        SetSentErrorMessage(true);
        return false;
    }

    uint32 passiveId = 0;
    if (!ExtractUInt32(&args, passiveId))
        return false;

    std::string error;
    if (!run->GivePassive(passiveId, error))
    {
        SendSysMessage(error.c_str());
        SetSentErrorMessage(true);
        return false;
    }
    return true;
}

bool ChatHandler::HandleBonkMasteryCommand(char* args)
{
    uint32 xp = 0;
    if (!ExtractUInt32(&args, xp) || !xp)
        return false;

    BonkPlayer* bonk = m_session->GetPlayer()->GetBonkPlayer();
    bonk->AddMasteryXp(xp);
    PSendSysMessage("Mastery level %u, %u talent points earned.", bonk->GetMasteryLevel(), bonk->GetMasteryPoints());
    return true;
}

bool ChatHandler::HandleBonkGodCommand(char* args)
{
    Player* player = m_session->GetPlayer();
    BonkPlayer* bonk = player->GetBonkPlayer();
    std::string const wanted = args ? args : "";
    bool const on = wanted == "on" ? true : wanted == "off" ? false : !bonk->IsTestGod();
    bonk->SetTestGod(on);
    player->SetCheatGod(on);
    SendSysMessage(on ? "God mode on: damage stops at 1 health." : "God mode off.");
    return true;
}

bool ChatHandler::HandleBonkChestCommand(char*)
{
    Player* player = m_session->GetPlayer();
    BonkRun* run = player->GetBonkPlayer()->GetRun();
    if (!run || !run->IsActive())
    {
        SendSysMessage("Start a run first.");
        return false;
    }
    Player* spot = GetSelectedPlayer();
    if (!run->SpawnFreeChestAt(spot ? spot : player))
    {
        SendSysMessage("The chest couldn't be placed there.");
        return false;
    }
    PSendSysMessage("Free chest placed next to %s.", (spot ? spot : player)->GetName());
    return true;
}

bool ChatHandler::HandleBonkQuestsCommand(char*)
{
    Player* player = m_session->GetPlayer();
    if (player->GetBonkPlayer()->IsAddonReady())
    {
        sBonkQuests.SendLog(player, "");
        return true;
    }

    SendSysMessage(GetString(m_session, BONK_STRING_QUESTS_HEADER).c_str());
    for (std::string const& line : sBonkQuests.DescribeAll(player))
        PSendSysMessage("  %s", line.c_str());
    return true;
}

bool ChatHandler::HandleBonkCodexCommand(char*)
{
    Player* player = m_session->GetPlayer();
    if (!player->GetBonkPlayer()->IsAddonReady())
    {
        SendSysMessage(GetString(m_session, BONK_STRING_SPELLBOOK_NEEDS_ADDON).c_str());
        return true;
    }
    BonkCodex::Send(player, "");
    return true;
}

bool ChatHandler::HandleBonkRestCommand(char* /*args*/)
{
    Player* player = m_session->GetPlayer();
    if (!player->GetBonkPlayer()->RequestRest())
    {
        SendSysMessage(player->GetBonkPlayer()->GetString(BONK_STRING_HARDCORE_REST_ONLY_FALLEN).c_str());
        return true;
    }
    return true;
}

bool ChatHandler::HandleBonkHelloCommand(char* args)
{
    Player* player = m_session->GetPlayer();
    BonkPlayer* bonk = player->GetBonkPlayer();
    if (char* name = ExtractArg(&args))
    {
        LocaleConstant locale;
        if (BonkLocale::ParseLocale(name, locale))
            bonk->SetLocale(locale);
        else
            SendSysMessage(bonk->GetString(BONK_STRING_LANGUAGE_UNKNOWN, { name, BonkLocale::ListLocales() }).c_str());
    }
    bonk->SetAddonReady();
    SendAddonData(player);
    bonk->SendUpdateNotices();
    bonk->SendUnannouncedFall();
    return true;
}

bool ChatHandler::HandleBonkEffectsCommand(char* args)
{
    uint32 percent = 0;
    if (!ExtractUInt32(&args, percent))
        return false;
    m_session->GetPlayer()->GetBonkPlayer()->SetOtherEffects(percent);
    return true;
}

bool ChatHandler::HandleBonkRingCommand(char* args)
{
    BonkPlayer* bonk = m_session->GetPlayer()->GetBonkPlayer();
    char* action = ExtractArg(&args);
    if (!action)
        return false;
    uint32 first = 0;
    if (!strcmp(action, "slot") && ExtractUInt32(&args, first))
    {
        bonk->ChooseReachRingSlot(first);
        return true;
    }
    if (!strcmp(action, "preview") && ExtractUInt32(&args, first))
    {
        bonk->SetReachRingPreview(first != 0);
        return true;
    }
    uint32 style = 0, filled = 0, opacity = 0;
    if (!strcmp(action, "set") && ExtractUInt32(&args, first) && ExtractUInt32(&args, style) && ExtractUInt32(&args, filled) &&
        ExtractUInt32(&args, opacity))
    {
        bonk->SetReachRing(first, style, filled != 0, opacity);
        return true;
    }
    return false;
}

bool ChatHandler::HandleBonkNoticeCommand(char* args)
{
    char* which = ExtractArg(&args);
    if (!which || std::string(which) != "gear")
        return false;
    m_session->GetPlayer()->GetBonkPlayer()->SeeGearNotice();
    return true;
}

bool ChatHandler::HandleBonkBoardCommand(char* /*args*/)
{
    BonkLeaderboard::Send(m_session->GetPlayer());
    return true;
}

bool ChatHandler::HandleBonkBoardPageCommand(char* args)
{
    uint32 view = 0;
    uint32 classId = 0;
    uint32 offset = 0;
    if (!ExtractUInt32(&args, view) || !ExtractUInt32(&args, classId) || !ExtractUInt32(&args, offset))
        return false;
    BonkLeaderboard::SendPage(m_session->GetPlayer(), view, classId, offset);
    return true;
}

bool ChatHandler::HandleBonkBoardJoinCommand(char* args)
{
    uint32 show = 0;
    if (!ExtractUInt32(&args, show))
        return false;
    m_session->GetPlayer()->GetBonkPlayer()->SetBoardChoice(show != 0);
    return true;
}

bool ChatHandler::HandleBonkLangCommand(char* args)
{
    Player* player = m_session->GetPlayer();
    BonkPlayer* bonk = player->GetBonkPlayer();
    char* name = ExtractArg(&args);
    if (!name)
    {
        SendSysMessage(bonk->GetString(BONK_STRING_LANGUAGE_USAGE, { localeNames[bonk->GetLocale()] }).c_str());
        SetSentErrorMessage(true);
        return false;
    }

    LocaleConstant locale;
    if (!BonkLocale::ParseLocale(name, locale))
    {
        SendSysMessage(bonk->GetString(BONK_STRING_LANGUAGE_UNKNOWN, { name, BonkLocale::ListLocales() }).c_str());
        SetSentErrorMessage(true);
        return false;
    }

    bonk->SetLocale(locale);
    SendSysMessage(bonk->GetString(BONK_STRING_LANGUAGE_SET, { localeNames[locale] }).c_str());
    if (bonk->IsAddonReady())
        SendAddonData(player);
    return true;
}

bool ChatHandler::HandleBonkStringsExportCommand(char* args)
{
    char* name = ExtractArg(&args);
    LocaleConstant locale = LOCALE_enUS;
    if (!name || !BonkLocale::ParseLocale(name, locale) || locale == LOCALE_enUS)
    {
        SendSysMessage("Usage: .bonk strings export <locale>, for example .bonk strings export zhCN. Writes every Bonk string and its translation to the logs folder.");
        SetSentErrorMessage(true);
        return false;
    }

    std::string path;
    if (!sBonkLocale.Export(locale, path))
    {
        PSendSysMessage("Could not write %s.", path.c_str());
        SetSentErrorMessage(true);
        return false;
    }

    PSendSysMessage("Wrote %s.", path.c_str());
    return true;
}

bool ChatHandler::HandleBonkMapsCommand(char*)
{
    SendSysMessage(GetString(m_session, BONK_STRING_DIFFICULTIES_HEADER).c_str());
    m_session->GetPlayer()->GetBonkPlayer()->SendTierList();
    return true;
}

bool ChatHandler::HandleBonkCampCommand(char*)
{
    Player* player = m_session->GetPlayer();
    BonkPlayer* bonk = player->GetBonkPlayer();
    if (bonk->GetRun())
    {
        SendSysMessage(GetString(m_session, BONK_STRING_LEAVE_RUN_FIRST).c_str());
        SetSentErrorMessage(true);
        return false;
    }
    if (player->IsInCombat() || player->IsTaxiFlying())
    {
        SendSysMessage(GetString(m_session, BONK_STRING_CANT_GO_BACK_TO_INN).c_str());
        SetSentErrorMessage(true);
        return false;
    }

    bonk->TeleportToCamp();
    return true;
}

bool ChatHandler::HandleBonkSpotCommand(char* args)
{
    std::string name = args ? args : "";
    while (!name.empty() && (name.back() == ' ' || name.back() == ':'))
        name.pop_back();
    size_t const start = name.find_first_not_of(' ');
    name = start == std::string::npos ? std::string() : name.substr(start, 48);
    if (name.empty())
    {
        SendSysMessage("Use .bonk spot <name>, for example .bonk spot run master.");
        SetSentErrorMessage(true);
        return false;
    }

    Player* player = m_session->GetPlayer();
    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, "Bonk spot: %s | map %u | %.3f %.3f %.3f | %.4f", name.c_str(), player->GetMapId(),
        player->GetPositionX(), player->GetPositionY(), player->GetPositionZ(), player->GetOrientation());
    PSendSysMessage("Saved %s: %.1f %.1f %.1f, facing %.2f.", name.c_str(), player->GetPositionX(), player->GetPositionY(),
        player->GetPositionZ(), player->GetOrientation());
    return true;
}

bool ChatHandler::HandleBonkReloadCommand(char*)
{
    if (m_session && m_session->GetPlayer()->GetBonkPlayer()->GetRun())
    {
        SendSysMessage(GetString(m_session, BONK_STRING_LEAVE_RUN_FIRST).c_str());
        SetSentErrorMessage(true);
        return false;
    }

    sBonkMgr.Load();
    SendSysMessage("Bonk tables reloaded.");
    return true;
}

bool ChatHandler::HandleBonkTelegraphCommand(char* args)
{
    char* shapeArg = ExtractArg(&args);
    BonkTelegraphShape shape = BONK_TELEGRAPH_CIRCLE;
    if (!shapeArg || !ParseBonkTelegraphShape(shapeArg, shape))
    {
        SendSysMessage("Usage: .bonk telegraph circle|cone|line [size] [seconds]");
        SetSentErrorMessage(true);
        return false;
    }

    float size = shape == BONK_TELEGRAPH_LINE ? 20.0f : shape == BONK_TELEGRAPH_CONE ? 10.0f : 5.0f;
    float seconds = 2.0f;
    ExtractFloat(&args, size);
    ExtractFloat(&args, seconds);
    size = std::max(0.5f, std::min(size, 60.0f));
    uint32 const durationMs = uint32(std::max(0.2f, std::min(seconds, 30.0f)) * IN_MILLISECONDS);

    Player* player = m_session->GetPlayer();
    float const o = player->GetOrientation();
    float x = player->GetPositionX(), y = player->GetPositionY();
    if (shape == BONK_TELEGRAPH_CIRCLE)
    {
        x += (size + 2.0f) * std::cos(o);
        y += (size + 2.0f) * std::sin(o);
    }
    float const z = player->GetPositionZ();

    if (BonkRun* run = player->GetBonkPlayer()->GetRun())
    {
        if (!run->IsActive() || run->IsPaused())
        {
            SendSysMessage("Not while the run is paused or over.");
            SetSentErrorMessage(true);
            return false;
        }
        run->AddTelegraph(shape, x, y, z, o, size, durationMs, [run, x, y, z]() { run->Erupt(BonkEnemyHit(), x, y, z, 0.0f); });
    }
    else
        player->GetBonkPlayer()->PreviewTelegraph(shape, x, y, z, o, size, durationMs);

    PSendSysMessage("A %s of %.1f yards, %.1f seconds.", GetBonkTelegraphShapeName(shape), size, durationMs / float(IN_MILLISECONDS));
    return true;
}

bool ChatHandler::HandleBonkObjectiveCommand(char* args)
{
    Player* player = m_session->GetPlayer();
    BonkRun* run = player->GetBonkPlayer()->GetRun();
    if (!run || !run->IsActive())
    {
        SendSysMessage("Objectives need a run.");
        SetSentErrorMessage(true);
        return false;
    }

    char* kindArg = ExtractArg(&args);
    if (kindArg && !strcmp(kindArg, "clear"))
    {
        std::vector<uint32> ids;
        for (BonkObjective const& objective : run->GetObjectives().GetAll())
            ids.push_back(objective.id);
        for (uint32 id : ids)
            run->RemoveObjective(id);
        PSendSysMessage("%u objectives taken away.", uint32(ids.size()));
        return true;
    }

    BonkObjectiveKind kind = BONK_OBJECTIVE_SHRINE;
    if (!kindArg || !ParseBonkObjectiveKind(kindArg, kind))
    {
        SendSysMessage("Usage: .bonk objective shrine|vendor|event [seconds] | clear");
        SetSentErrorMessage(true);
        return false;
    }
    uint32 seconds = 0;
    ExtractUInt32(&args, seconds);

    char const* const labels[MAX_BONK_OBJECTIVE_KIND] = { "Shrine", "Goblin Merchant", "Event" };
    BonkSpot spot;
    bool const atSpot = run->TakeSpawnPoint(120.0f, 250.0f, spot);
    if (!atSpot)
    {
        float const o = player->GetOrientation();
        spot.x = player->GetPositionX() + 30.0f * std::cos(o);
        spot.y = player->GetPositionY() + 30.0f * std::sin(o);
        spot.z = player->GetMap()->GetHeight(spot.x, spot.y, player->GetPositionZ() + 10.0f, true, 30.0f);
        if (spot.z <= INVALID_HEIGHT)
            spot.z = player->GetPositionZ();
    }
    uint32 const id = run->AddObjective(kind, spot.x, spot.y, spot.z, labels[kind], seconds);
    PSendSysMessage("Objective %u (%s) %.0f yards away, %s.", id, GetBonkObjectiveKindName(kind), player->GetDistance2dToCenter(spot.x, spot.y),
        atSpot ? "at a spawn point" : "30 yards ahead (no free spawn point yet)");
    return true;
}

bool ChatHandler::HandleBonkSpotsCommand(char*)
{
    Player* player = m_session->GetPlayer();
    BonkRun* run = player->GetBonkPlayer()->GetRun();
    if (!run || !run->IsActive())
    {
        SendSysMessage("Spawn points need a run.");
        SetSentErrorMessage(true);
        return false;
    }

    uint32 taken = 0;
    for (BonkSpot const& spot : run->GetSpawnPoints().GetSpots())
    {
        player->SummonGameObject(900020 + BONK_OBJECTIVE_EVENT, spot.x, spot.y, spot.z, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 20, false);
        taken += spot.taken ? 1 : 0;
    }
    PSendSysMessage("%u spawn points (%u taken), shown for 20 seconds.", uint32(run->GetSpawnPoints().GetSpots().size()), taken);
    return true;
}

bool ChatHandler::HandleBonkEventCommand(char* args)
{
    char* nameArg = ExtractArg(&args);
    BonkMiniEventType type = BONK_MINI_EVENT_HORDE;
    if (!nameArg || !ParseBonkMiniEvent(nameArg, type))
    {
        SendSysMessage("Usage: .bonk event horde|goblin|bounty|kobolds|scourge|portal|stampede|caravan");
        SetSentErrorMessage(true);
        return false;
    }

    BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun();
    std::string error;
    if (!run || run->IsSandbox())
        error = run ? "The sandbox has no mini-events." : "Mini-events need a run.";
    else if (run->StartMiniEventNow(type, error))
    {
        PSendSysMessage("Mini-event %s started.", GetBonkMiniEventName(type));
        return true;
    }
    SendSysMessage(error.c_str());
    SetSentErrorMessage(true);
    return false;
}

bool ChatHandler::HandleBonkShrineCommand(char* args)
{
    char* nameArg = ExtractArg(&args);
    BonkShrineType type = BONK_SHRINE_LEY_LINE;
    if (!nameArg || !ParseBonkShrine(nameArg, type))
    {
        SendSysMessage("Usage: .bonk shrine leyline|greed|altar|moonwell|stone");
        SetSentErrorMessage(true);
        return false;
    }

    BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun();
    std::string error;
    if (!run || run->IsSandbox())
        error = run ? "The sandbox has no shrines." : "Shrines need a run.";
    else if (run->PlaceShrineNow(type, error))
    {
        PSendSysMessage("Shrine %s placed.", GetBonkShrineName(type));
        return true;
    }
    SendSysMessage(error.c_str());
    SetSentErrorMessage(true);
    return false;
}

bool ChatHandler::HandleBonkPowerupCommand(char* args)
{
    static std::pair<char const*, uint32> const powerups[] =
    {
        { "restoration", 900004 }, { "berserking", 900005 }, { "speed", 900006 }, { "magnet", 900050 },
        { "holynova", 900051 }, { "frostnova", 900052 }, { "valor", 900053 },
    };
    char* nameArg = ExtractArg(&args);
    uint32 entry = 0;
    for (auto const& powerup : powerups)
        if (nameArg && !strcmp(nameArg, powerup.first))
            entry = powerup.second;
    if (!entry)
    {
        SendSysMessage("Usage: .bonk powerup magnet|holynova|frostnova|valor|restoration|berserking|speed [take]");
        SetSentErrorMessage(true);
        return false;
    }

    BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun();
    char* takeArg = ExtractArg(&args);
    std::string error;
    if (!run)
        error = "Power-ups need a run or the sandbox.";
    else if (takeArg && !strcmp(takeArg, "take") && run->TakePowerupNow(entry))
    {
        PSendSysMessage("Power-up %s taken.", nameArg);
        return true;
    }
    else if (run->PlacePowerupNow(entry, error))
    {
        PSendSysMessage("Power-up %s placed 10 yards in front of you.", nameArg);
        return true;
    }
    SendSysMessage(error.c_str());
    SetSentErrorMessage(true);
    return false;
}

bool ChatHandler::HandleBonkDropLooksCommand(char* args)
{
    BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun();
    std::string error = "Drop looks need a run or the sandbox.";
    bool const chests = args && std::string(args).find("chests") != std::string::npos;
    if (run && (chests ? run->PlaceChestLooksNow(error) : run->PlaceDropLooksNow(error)))
    {
        SendSysMessage("Every drop look is laid out 10 yards in front of you.");
        return true;
    }
    SendSysMessage(error.c_str());
    SetSentErrorMessage(true);
    return false;
}

bool ChatHandler::HandleBonkLeyPickCommand(char* args)
{
    uint32 index = 0;
    BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun();
    std::string error;
    if (!run)
        error = GetString(m_session, BONK_STRING_NOT_IN_A_RUN);
    else if (!ExtractUInt32(&args, index))
        error = GetString(m_session, BONK_STRING_LEYPICK_USAGE);
    else if (run->PickLeyBuff(index, error))
        return true;
    SendSysMessage(error.c_str());
    SetSentErrorMessage(true);
    return false;
}

bool ChatHandler::HandleBonkInspectCommand(char*)
{
    BonkPlayer* bonk = m_session->GetPlayer()->GetBonkPlayer();
    BonkRun* run = bonk->GetRun();
    if (!run)
    {
        SendSysMessage(GetString(m_session, BONK_STRING_INSPECT_TALENTS_DURING_RUN).c_str());
        SetSentErrorMessage(true);
        return false;
    }
    bonk->SendMasteryShop(true, true);
    return true;
}

bool ChatHandler::HandleBonkVendorCommand(char* args)
{
    char* action = ExtractArg(&args);
    BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun();
    std::string error;
    uint32 index = 0;
    if (!action)
        error = GetString(m_session, BONK_STRING_VENDOR_USAGE);
    else if (!run)
        error = GetString(m_session, BONK_STRING_NOT_IN_A_RUN);
    else if (!strcmp(action, "buy") || !strcmp(action, "lock"))
    {
        if (!ExtractUInt32(&args, index))
            error = GetString(m_session, BONK_STRING_VENDOR_ACTION_USAGE, { action });
        else if (!strcmp(action, "buy") ? run->BuyFromVendor(index, error) : run->LockVendorSlot(index, error))
            return true;
    }
    else if (!strcmp(action, "reroll"))
    {
        if (run->RerollVendor(error))
            return true;
    }
    else if (!strcmp(action, "close"))
    {
        run->CloseVendor();
        return true;
    }
    else if (!strcmp(action, "spawn") && GetAccessLevel() >= SEC_GAMEMASTER)
    {
        if (run->IsSandbox())
            error = GetString(m_session, BONK_STRING_SANDBOX_HAS_NO_MERCHANT);
        else if (run->SpawnVendorNow(error))
        {
            SendSysMessage(GetString(m_session, BONK_STRING_MERCHANT_ON_HIS_WAY).c_str());
            return true;
        }
    }
    else
        error = GetString(m_session, BONK_STRING_VENDOR_USAGE);

    SendSysMessage(error.c_str());
    SetSentErrorMessage(true);
    return false;
}

bool ChatHandler::HandleBonkKeywordCommand(char* args)
{
    BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun();
    if (!run || !run->IsActive())
    {
        SendSysMessage("You are not in a running stage.");
        SetSentErrorMessage(true);
        return false;
    }

    char* nameArg = ExtractArg(&args);
    uint32 stacks = 1;
    if (!nameArg || (*args && !ExtractUInt32(&args, stacks)))
        return false;

    std::string wanted = nameArg;
    std::transform(wanted.begin(), wanted.end(), wanted.begin(), ::tolower);
    BonkKeywordInfo const* keyword = nullptr;
    std::string names;
    for (auto const& itr : sBonkMgr.GetKeywords())
    {
        std::string name = itr.second.name;
        std::transform(name.begin(), name.end(), name.begin(), ::tolower);
        if (!keyword && name.compare(0, wanted.size(), wanted) == 0)
            keyword = &itr.second;
        names += (names.empty() ? "" : ", ") + itr.second.name;
    }
    if (!keyword)
    {
        PSendSysMessage("No keyword starts with \"%s\". Keywords: %s.", nameArg, names.c_str());
        SetSentErrorMessage(true);
        return false;
    }

    Creature* mob = GetSelectedCreature();
    if (!mob || !run->ApplyKeyword(mob, keyword->id, stacks))
    {
        SendSysMessage("Select a living enemy of your run (one still immune after a hold can't be held again yet).");
        SetSentErrorMessage(true);
        return false;
    }

    PSendSysMessage("%s: %u %s.", mob->GetName(), run->GetKeywordStacks(mob, keyword->id), keyword->name.c_str());
    return true;
}

bool ChatHandler::HandleBonkScalingCommand(char*)
{
    BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun();
    if (!run || !run->IsActive())
    {
        SendSysMessage("You are not in a running stage.");
        SetSentErrorMessage(true);
        return false;
    }

    for (std::string const& line : run->DescribeScaling())
        SendSysMessage(line.c_str());
    return true;
}

bool ChatHandler::HandleBonkCoopReadyCommand(char* args)
{
    std::string const answer = args ? args : "";
    BonkCoop::AnswerReady(m_session->GetPlayer(), answer == "1" || answer == "yes");
    return true;
}

bool ChatHandler::HandleBonkWatchNextCommand(char* args)
{
    BonkCoop::WatchNext(m_session->GetPlayer(), !args || std::string(args) != "prev");
    return true;
}

bool ChatHandler::HandleBonkStressCommand(char* args)
{
    BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun();
    if (!run || !run->IsActive())
    {
        SendSysMessage("You are not in a running stage.");
        SetSentErrorMessage(true);
        return false;
    }

    std::string const wanted = args ? args : "";
    if (wanted == "on" || wanted == "off")
        run->SetStress(wanted == "on");
    else
        run->ToggleStress();
    return true;
}

bool ChatHandler::HandleBonkCrowdCommand(char* args)
{
    std::vector<std::pair<char const*, float*>> const tunables = BonkCrowd::GetTunables();
    char* name = ExtractArg(&args);
    if (name)
    {
        float value;
        auto const tunable = std::find_if(tunables.begin(), tunables.end(),
            [name](std::pair<char const*, float*> const& entry) { return strcmp(entry.first, name) == 0; });
        if (tunable == tunables.end() || !ExtractFloat(&args, value) || value < 0.0f)
        {
            SendSysMessage("Usage: .bonk crowd [name value]. Names are listed by .bonk crowd.");
            SetSentErrorMessage(true);
            return false;
        }
        *tunable->second = value;
    }

    std::string line;
    for (auto const& entry : tunables)
        line += std::string(line.empty() ? "" : ", ") + entry.first + " " + std::to_string(*entry.second).substr(0, 4);
    SendSysMessage(line.c_str());
    if (BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun())
        SendSysMessage(run->GetCrowd().Describe().c_str());
    return true;
}

bool ChatHandler::HandleBonkSpawnLookCommand(char* args)
{
    uint32 kit, leadMs;
    if (ExtractUInt32(&args, kit))
        BonkRun::SetSpawnKit(kit);
    if (ExtractUInt32(&args, leadMs))
        BonkRun::SetSpawnLookLeadMs(leadMs);
    PSendSysMessage("Spawn look kit %u; enemies turn hostile %u ms after it. Usage: .bonk spawnlook [kit] [hostile after ms].",
        BonkRun::GetSpawnKit(), BonkRun::GetSpawnLookLeadMs());
    BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun();
    if (!run)
    {
        SendSysMessage("Start a run to preview it.");
        return true;
    }
    SendSysMessage(run->DescribeSpawnLook().c_str());
    if (BonkRun::GetSpawnKit())
        run->PreviewSpawnLook();
    return true;
}

bool ChatHandler::HandleBonkBossTuneCommand(char* args)
{
    char* key = ExtractArg(&args);
    if (key)
    {
        float value;
        if (!ExtractFloat(&args, value) || !BonkMobAI::SetBossTune(key, value))
        {
            SendSysMessage("Usage: .bonk bosstune [key value]. Keys are listed below; values last until the server restarts.");
            key = nullptr;
        }
        else
            PSendSysMessage("Boss tune %s is now %g.", key, value);
    }
    if (!key)
        for (std::string const& line : BonkMobAI::DescribeBossTune())
            SendSysMessage(line.c_str());
    return true;
}

bool ChatHandler::HandleBonkDashCommand(char*)
{
    m_session->GetPlayer()->GetBonkPlayer()->Dash();
    return true;
}

bool ChatHandler::HandleBonkShapeshiftCommand(char* args)
{
    BonkRun* run = m_session->GetPlayer()->GetBonkPlayer()->GetRun();
    if (!run)
        return true;
    bool const picksForm = args && *args && m_session->GetSecurity() >= SEC_GAMEMASTER;
    run->Shapeshift(picksForm ? args : nullptr);
    return true;
}

bool ChatHandler::HandleBonkKillBossCommand(char*)
{
    Player* player = m_session->GetPlayer();
    BonkRun* run = player->GetBonkPlayer()->GetRun();
    Creature* boss = run ? player->GetMap()->GetCreature(run->GetBossGuid()) : nullptr;
    if (!boss || !boss->IsAlive())
    {
        SendSysMessage("There is no stage boss alive.");
        SetSentErrorMessage(true);
        return false;
    }
    PSendSysMessage("%s had %u of %u health.", boss->GetName(), boss->GetHealth(), boss->GetMaxHealth());
    return HandleDieHelper(boss);
}

bool ChatHandler::HandleBonkMobInfoCommand(char*)
{
    Player* player = m_session->GetPlayer();
    Creature* mob = GetSelectedCreature();
    if (!mob)
        mob = FindNearestEnemy(player);
    if (!mob)
    {
        PSendSysMessage("Select a creature, or stand within %.0f yards of an enemy.", BONK_MOBINFO_SEARCH_RANGE);
        SetSentErrorMessage(true);
        return false;
    }

    PSendSysMessage("%s, entry %u, %s", mob->GetName(), mob->GetEntry(), mob->GetGuidStr().c_str());
    PSendSysMessage("Alive: %s (death state %u), health %u of %u, despawning: %s, time frozen: %s, evading: %s", YesNo(mob->IsAlive()),
        uint32(mob->GetDeathState()), mob->GetHealth(), mob->GetMaxHealth(), YesNo(mob->HasCreatureState(CSTATE_DESPAWNING)),
        YesNo(mob->IsTimeFrozen()), YesNo(mob->IsInEvadeMode()));

    BonkMobAI const* ai = dynamic_cast<BonkMobAI const*>(mob->AI());
    PSendSysMessage("Bonk AI: %s", ai ? ai->Describe().c_str() : "no");

    uint32 const flags = mob->GetUInt32Value(UNIT_FIELD_FLAGS);
    PSendSysMessage("Faction %u, unit flags 0x%08X (selectable: %s, immune to players: %s, immune to NPCs: %s), Bonk enemy: %s",
        mob->GetFactionTemplateId(), flags, YesNo((flags & UNIT_FLAG_NOT_SELECTABLE) == 0), YesNo((flags & UNIT_FLAG_IMMUNE_TO_PLAYER) != 0),
        YesNo((flags & UNIT_FLAG_IMMUNE_TO_NPC) != 0), YesNo(mob->IsBonkEnemy()));

    ObjectGuid const summoner = mob->IsTemporarySummon() ? static_cast<TemporarySummon*>(mob)->GetSummonerGuid() : ObjectGuid();
    PSendSysMessage("Summoned by %s, owner %s", summoner.GetString().c_str(), mob->GetCharmerOrOwnerGuid().GetString().c_str());
    PSendSysMessage("Distance %.1f yards, line of sight: %s", player->GetDistance(mob), YesNo(player->IsWithinLOSInMap(mob)));

    if (BonkRun const* run = player->GetBonkPlayer()->GetRun())
        for (std::string const& line : run->DescribeMob(mob))
            SendSysMessage(line.c_str());
    else
        SendSysMessage(GetString(m_session, BONK_STRING_NOT_IN_A_RUN).c_str());
    return true;
}

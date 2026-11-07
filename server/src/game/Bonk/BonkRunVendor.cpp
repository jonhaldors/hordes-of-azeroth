#include "BonkRun.h"
#include "BonkLocale.h"
#include "BonkMobAI.h"
#include "BonkPlayer.h"
#include "BonkQuests.h"
#include "Chat.h"
#include "Creature.h"
#include "HoaProtocol.h"
#include "Log.h"
#include "Map.h"
#include "Player.h"
#include "Utilities/Random.h"
#include "WorldSession.h"

namespace
{
    uint32 const BONK_VENDOR_ENTRY         = 900010;
    size_t const BONK_VENDOR_DARKMOON_SLOTS = 1;
    uint32 const BONK_VENDOR_SECONDS       = 60;
    uint32 const BONK_VENDOR_EARLIEST      = 120;
    uint32 const BONK_VENDOR_LATEST        = 480;
    uint32 const BONK_VENDOR_BOSS_MARGIN   = 60;
    uint32 const BONK_VENDOR_GAP           = 60;
    uint32 const BONK_VENDOR_CHECK_MS      = 1000;
    float const BONK_VENDOR_MIN_DISTANCE   = 100.0f;
    float const BONK_VENDOR_MAX_DISTANCE   = 250.0f;

    float const BONK_VENDOR_CARD_PRICE     = 1.5f;
    float const BONK_VENDOR_RARITY_PRICE[MAX_BONK_RARITY] = { 0.8f, 1.0f, 1.25f, 1.6f, 2.0f };
    float const BONK_VENDOR_CHARGE_PRICE   = 1.0f;
    float const BONK_VENDOR_REROLL_PRICE   = 0.5f;
    float const BONK_VENDOR_REROLL_GROWTH  = 0.5f;
    BonkRarity const BONK_VENDOR_MIN_RARITY = BONK_RARITY_RARE;

    char const* const BONK_VENDOR_NAME        = "Zixil";
    char const* const BONK_VENDOR_ICON        = "INV_Misc_Bag_10";

    std::string VendorName(Player* player)
    {
        return player->GetBonkPlayer()->GetCreatureName(BONK_VENDOR_ENTRY, BONK_VENDOR_NAME);
    }

    enum BonkVendorCharge : uint8
    {
        BONK_VENDOR_CHARGE_REROLL = 0,
        BONK_VENDOR_CHARGE_BANISH = 1,
        BONK_VENDOR_CHARGE_SKIP   = 2,
        MAX_BONK_VENDOR_CHARGE
    };
    BonkString const CHARGE_NAMES[MAX_BONK_VENDOR_CHARGE] = { BONK_STRING_CHARGE_REROLL, BONK_STRING_CHARGE_BANISH, BONK_STRING_CHARGE_SKIP };
    char const* const CHARGE_ICONS[MAX_BONK_VENDOR_CHARGE] = { "Spell_Nature_Reincarnation", "Spell_Shadow_Cripple", "Ability_Rogue_Sprint" };
    BonkString const CHARGE_DESCRIPTIONS[MAX_BONK_VENDOR_CHARGE] = { BONK_STRING_CHARGE_REROLL_TEXT, BONK_STRING_CHARGE_BANISH_TEXT,
        BONK_STRING_CHARGE_SKIP_TEXT };
}

void BonkRun::ResetVendor()
{
    DespawnVendor();
    m_vendorVisits.clear();
    m_vendorCheckMs = 0;
    if (m_map.type == BONK_MAP_ARENA)
        return;

    uint32 const latest = std::min(BONK_VENDOR_LATEST,
        m_map.durationSeconds > BONK_VENDOR_BOSS_MARGIN + BONK_VENDOR_SECONDS ? m_map.durationSeconds - BONK_VENDOR_BOSS_MARGIN - BONK_VENDOR_SECONDS : 0u);
    if (latest < BONK_VENDOR_EARLIEST)
        return;

    if (urand(0, 1) && latest >= BONK_VENDOR_EARLIEST + 2 * BONK_VENDOR_GAP)
    {
        uint32 const middle = (BONK_VENDOR_EARLIEST + latest) / 2;
        m_vendorVisits.push_back(urand(BONK_VENDOR_EARLIEST, middle - BONK_VENDOR_GAP / 2));
        m_vendorVisits.push_back(urand(middle + BONK_VENDOR_GAP / 2, latest));
    }
    else
        m_vendorVisits.push_back(urand(BONK_VENDOR_EARLIEST, latest));
}

void BonkRun::UpdateVendor(uint32 diff)
{
    if (!m_vendorGuid.IsEmpty())
    {
        Creature* vendor = m_player->GetMap()->GetCreature(m_vendorGuid);
        if (vendor && vendor->IsAlive() && m_vendorLeftMs > diff)
        {
            m_vendorLeftMs -= diff;
            return;
        }
        if (vendor)
            m_player->GetBonkPlayer()->Notify(BONK_STRING_VENDOR_LEAVES, { VendorName(m_player) });
        DespawnVendor();
        return;
    }

    if (m_vendorVisits.empty() || m_elapsedMs < m_vendorVisits.front() * IN_MILLISECONDS)
        return;
    m_vendorCheckMs += diff;
    if (m_vendorCheckMs < BONK_VENDOR_CHECK_MS)
        return;
    m_vendorCheckMs = 0;

    if (m_elapsedMs / IN_MILLISECONDS + BONK_VENDOR_BOSS_MARGIN + BONK_VENDOR_SECONDS >= m_map.durationSeconds)
    {
        m_vendorVisits.clear();
        return;
    }
    if (m_bossSpawned || IsBossUp())
        return;
    if (SpawnVendor())
        m_vendorVisits.erase(m_vendorVisits.begin());
}

bool BonkRun::IsBossUp() const
{
    Map* map = m_player->GetMap();
    for (ObjectGuid const& guid : m_mobs)
        if (Creature* mob = map->GetCreature(guid))
            if (BonkMobAI* ai = dynamic_cast<BonkMobAI*>(mob->AI()))
                if (mob->IsAlive() && (ai->GetKind() == BONK_SPAWN_BOSS || ai->GetKind() == BONK_SPAWN_MINIBOSS))
                    return true;
    return false;
}

bool BonkRun::SpawnVendor()
{
    BonkSpot spot;
    if (!m_spawnPoints.Take(m_player, BONK_VENDOR_MIN_DISTANCE, BONK_VENDOR_MAX_DISTANCE, spot))
        return false;

    float const facing = std::atan2(m_player->GetPositionY() - spot.y, m_player->GetPositionX() - spot.x);
    Creature* vendor = m_player->SummonCreature(BONK_VENDOR_ENTRY, spot.x, spot.y, spot.z, facing, TEMPSUMMON_MANUAL_DESPAWN, 0);
    if (!vendor)
    {
        m_spawnPoints.Release(spot.x, spot.y);
        return false;
    }

    m_vendorGuid = vendor->GetObjectGuid();
    m_vendorLeftMs = BONK_VENDOR_SECONDS * IN_MILLISECONDS;
    m_vendorRerolls = 0;
    m_vendorObjective = m_objectives.Add(m_player, BONK_OBJECTIVE_VENDOR, spot.x, spot.y, spot.z, GetString(BONK_STRING_VENDOR_LABEL), BONK_VENDOR_SECONDS,
        BONK_VENDOR_ICON, GetString(BONK_STRING_VENDOR_TEXT, { VendorName(m_player) }));
    StockVendor(false);
    m_player->GetBonkPlayer()->Notify(BONK_STRING_VENDOR_ARRIVES, { VendorName(m_player) });
    return true;
}

void BonkRun::StockVendor(bool reroll)
{
    std::vector<VendorSlot> const previous = reroll ? m_vendorStock : std::vector<VendorSlot>();
    std::vector<VendorSlot> carried;
    if (!reroll)
    {
        carried = m_vendorKept;
        m_vendorKept.clear();
    }

    std::vector<Offer> kept, shown, keptDarkmoon, shownDarkmoon;
    for (VendorSlot const& slot : carried)
        if (!slot.isCharge)
            (slot.card.isCard ? keptDarkmoon : kept).push_back(slot.card);
    for (VendorSlot const& slot : previous)
        if (!slot.isCharge)
            (slot.card.isCard ? shownDarkmoon : shown).push_back(slot.card);

    m_rarityFloor = BONK_VENDOR_MIN_RARITY;
    std::vector<Offer> cards;
    OfferUpgrades(OFFER_LEVEL, reroll ? &shown : nullptr, &kept, &cards);
    if (!sBonkMgr.GetCards().empty())
    {
        std::vector<Offer> darkmoon;
        OfferCards(BONK_VENDOR_DARKMOON_SLOTS, reroll ? &shownDarkmoon : nullptr, &keptDarkmoon, &darkmoon);
        cards.insert(cards.end(), darkmoon.begin(), darkmoon.end());
    }
    m_rarityFloor = BONK_RARITY_COMMON;

    std::vector<VendorSlot> stock;
    for (Offer const& card : cards)
    {
        VendorSlot slot;
        slot.card = card;
        slot.price = GetVendorPrice(&card);
        for (VendorSlot const& old : carried)
            if (!old.isCharge && old.card.isWeapon == card.isWeapon && old.card.isCard == card.isCard && old.card.id == card.id &&
                old.card.evolveTo == card.evolveTo)
            {
                slot.price = old.price;
                slot.locked = true;
            }
        stock.push_back(slot);
    }

    VendorSlot special;
    special.isCharge = true;
    special.charge = uint8(urand(0, MAX_BONK_VENDOR_CHARGE - 1));
    special.price = GetVendorPrice(nullptr);
    for (VendorSlot const& old : carried)
        if (old.isCharge)
            special = old;
    stock.push_back(special);

    m_vendorStock = reroll ? KeepVendorPlaces(previous, stock) : stock;
}

std::vector<BonkRun::VendorSlot> BonkRun::KeepVendorPlaces(std::vector<VendorSlot> const& previous, std::vector<VendorSlot> stock)
{
    auto shelf = [](VendorSlot const& slot) { return slot.isCharge ? 2 : slot.card.isCard ? 1 : 0; };
    for (int shelfId = 0; shelfId < 3; ++shelfId)
    {
        std::vector<size_t> places;
        for (size_t i = 0; i < stock.size(); ++i)
            if (shelf(stock[i]) == shelfId)
                places.push_back(i);
        size_t position = 0;
        for (VendorSlot const& old : previous)
        {
            if (shelf(old) != shelfId)
                continue;
            bool const stays = old.state == VENDOR_SOLD || (old.locked && old.state == VENDOR_FOR_SALE);
            if (stays && position < places.size())
                stock[places[position]] = old;
            ++position;
        }
    }
    return stock;
}

void BonkRun::CheckVendorStock()
{
    for (VendorSlot& slot : m_vendorStock)
    {
        if (slot.isCharge || slot.state != VENDOR_FOR_SALE)
            continue;
        Offer card = slot.card;
        if (!RefreshKeptOffer(card))
        {
            slot.state = VENDOR_GONE;
            slot.locked = false;
        }
        else if (card.newLevel != slot.card.newLevel)
            slot.card = card;
    }
}

uint32 BonkRun::GetVendorPrice(Offer const* card) const
{
    float scale = BONK_VENDOR_CHARGE_PRICE;
    if (card)
    {
        scale = BONK_VENDOR_CARD_PRICE;
        if ((card->isCard || (card->isWeapon && card->step != BONK_STEP_NEW)) && card->rarity < MAX_BONK_RARITY)
            scale *= BONK_VENDOR_RARITY_PRICE[card->rarity];
    }
    return std::max(1u, uint32(GetChestPrice() * scale + 0.5f));
}

uint32 BonkRun::GetVendorRerollCost() const
{
    return std::max(1u, uint32(GetChestPrice() * BONK_VENDOR_REROLL_PRICE * (1.0f + BONK_VENDOR_REROLL_GROWTH * m_vendorRerolls) + 0.5f));
}

uint32 BonkRun::GetVendorRestocksLeft() const
{
    uint32 const allowed = uint32(GetUtility(BONK_UTILITY_VENDOR_REROLLS) + 0.5f);
    return allowed > m_vendorRerolls ? allowed - m_vendorRerolls : 0;
}

void BonkRun::OpenVendor(Creature* vendor)
{
    if (m_state != STATE_RUNNING || !vendor || vendor->GetObjectGuid() != m_vendorGuid)
        return;
    if (!m_offer.empty() || !m_leyOffer.empty())
    {
        m_player->GetBonkPlayer()->Notify(BONK_STRING_MAKE_YOUR_CHOICE_FIRST);
        return;
    }

    if (!m_vendorOpen)
    {
        m_vendorOpen = true;
        CheckVendorStock();
        SetPaused(true);
    }
    SendVendor();
}

void BonkRun::CloseVendor()
{
    if (!m_vendorOpen)
        return;
    m_vendorOpen = false;
    if (m_player->GetBonkPlayer()->IsAddonReady())
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteVendorClose(data);
        m_player->GetSession()->SendPacket(&data);
    }
    ResumeUnlessChoiceOpen();
    UpdateOffers();
}

bool BonkRun::BuyFromVendor(uint32 index, std::string& error)
{
    if (!m_vendorOpen)
    {
        error = GetString(BONK_STRING_VENDOR_SHOP_NOT_OPEN, { VendorName(m_player) });
        return false;
    }
    if (index < 1 || index > m_vendorStock.size())
    {
        error = GetString(BONK_STRING_CHOOSE_NUMBER_FROM_1_TO, { std::to_string(m_vendorStock.size()) });
        return false;
    }

    VendorSlot& slot = m_vendorStock[index - 1];
    if (slot.state != VENDOR_FOR_SALE)
    {
        error = slot.state == VENDOR_SOLD ? GetString(BONK_STRING_ALREADY_BOUGHT_THAT) : GetString(BONK_STRING_NO_LONGER_FITS_YOUR_BUILD);
        SendVendor();
        return false;
    }
    if (m_coins < slot.price)
    {
        error = GetString(BONK_STRING_THAT_COSTS_VALOR_YOU_HAVE, { std::to_string(slot.price), std::to_string(m_coins) });
        SendVendor();
        return false;
    }

    m_coins -= slot.price;
    m_valorInShops += slot.price;
    slot.state = VENDOR_SOLD;
    sBonkQuests.OnProgress(m_player, BONK_QUEST_VENDOR_BOUGHT, 0, 1);
    slot.locked = false;
    std::string name;
    if (slot.isCharge)
    {
        switch (slot.charge)
        {
            case BONK_VENDOR_CHARGE_REROLL: ++m_rerolls; break;
            case BONK_VENDOR_CHARGE_BANISH: ++m_banishes; break;
            default:                        ++m_skips; break;
        }
        name = GetString(BONK_STRING_VENDOR_ONE_MORE, { GetString(CHARGE_NAMES[slot.charge < MAX_BONK_VENDOR_CHARGE ? slot.charge : BONK_VENDOR_CHARGE_SKIP]) });
    }
    else
    {
        name = DescribeOffer(slot.card, nullptr);
        sLog.Player(m_player->GetSession(), LOG_LEVELUP, LOG_LVL_BASIC,
            "Bonk buy: %s buys %s rank %u for %u Valor at run minute %.2f, level %u",
            m_player->GetName(), name.c_str(), slot.card.newLevel, slot.price, GetRunMinutes(), m_player->GetLevel());
        ApplyVendorCard(slot.card);
        SendLoadout();
        CheckVendorStock();
    }

    m_player->GetBonkPlayer()->Notify(BONK_STRING_YOU_BOUGHT, { name });
    SendState();
    SendVendor();
    return true;
}

void BonkRun::ApplyVendorCard(Offer const& card)
{
    if (card.isCard)
    {
        if (BonkCard const* darkmoon = sBonkMgr.GetCard(card.id))
            AddCard(*darkmoon);
        return;
    }
    if (card.isWeapon)
    {
        if (OwnedWeapon* owned = FindOwned(card.id))
            ApplyStep(*owned, card);
        else if (BonkWeapon const* weapon = sBonkMgr.GetWeapon(card.id))
            AddWeapon(*weapon);
    }
    else
    {
        m_passiveRanks[card.id] = uint8(card.newLevel);
        ApplyPassives();
    }
}

bool BonkRun::LockVendorSlot(uint32 index, std::string& error)
{
    if (!m_vendorOpen)
    {
        error = GetString(BONK_STRING_VENDOR_SHOP_NOT_OPEN, { VendorName(m_player) });
        return false;
    }
    if (index < 1 || index > m_vendorStock.size() || m_vendorStock[index - 1].state != VENDOR_FOR_SALE)
    {
        error = GetString(BONK_STRING_CHOOSE_SOMETHING_STILL_FOR_SALE);
        return false;
    }

    m_vendorStock[index - 1].locked = !m_vendorStock[index - 1].locked;
    SendVendor();
    return true;
}

bool BonkRun::RerollVendor(std::string& error)
{
    if (!m_vendorOpen)
    {
        error = GetString(BONK_STRING_VENDOR_SHOP_NOT_OPEN, { VendorName(m_player) });
        return false;
    }
    if (GetVendorRestocksLeft() == 0)
    {
        error = GetString(GetUtility(BONK_UTILITY_VENDOR_REROLLS) > 0.0f ? BONK_STRING_VENDOR_NO_MORE_WARES : BONK_STRING_VENDOR_DOESNT_RESTOCK,
            { VendorName(m_player) });
        SendVendor();
        return false;
    }
    uint32 const cost = GetVendorRerollCost();
    if (m_coins < cost)
    {
        error = GetString(BONK_STRING_REROLL_COSTS_VALOR_YOU_HAVE, { std::to_string(cost), std::to_string(m_coins) });
        SendVendor();
        return false;
    }

    m_coins -= cost;
    m_valorInShops += cost;
    ++m_vendorRerolls;
    StockVendor(true);
    SendState();
    SendVendor();
    return true;
}

bool BonkRun::SpawnVendorNow(std::string& error)
{
    if (m_state != STATE_RUNNING)
    {
        error = GetString(BONK_STRING_ONLY_RUNNING_STAGE_MERCHANT);
        return false;
    }
    if (!m_vendorGuid.IsEmpty())
    {
        error = GetString(BONK_STRING_MERCHANT_IS_ALREADY_HERE);
        return false;
    }
    if (!SpawnVendor())
    {
        error = GetString(BONK_STRING_NO_MERCHANT_SPAWN_POINT);
        return false;
    }
    return true;
}

void BonkRun::DespawnVendor()
{
    CloseVendor();

    for (VendorSlot const& slot : m_vendorStock)
        if (slot.locked && slot.state == VENDOR_FOR_SALE)
            m_vendorKept.push_back(slot);
    m_vendorStock.clear();

    if (Map* map = m_player->FindMap())
    {
        if (Creature* vendor = map->GetCreature(m_vendorGuid))
            vendor->DespawnOrUnsummon();
        if (m_vendorObjective)
            RemoveObjective(m_vendorObjective);
    }
    m_vendorGuid.Clear();
    m_vendorObjective = 0;
}

void BonkRun::SendVendor() const
{
    BonkPlayer* bonk = m_player->GetBonkPlayer();
    uint32 const rerollCost = GetVendorRerollCost();
    if (bonk->IsAddonReady())
    {
        WorldPacket open(SMSG_HOA_MESSAGE);
        HoAWriteVendorOpen(open, m_coins, rerollCost, (m_vendorLeftMs + IN_MILLISECONDS - 1) / IN_MILLISECONDS, VendorName(m_player),
            GetVendorRestocksLeft());
        m_player->GetSession()->SendPacket(&open);
        for (size_t i = 0; i < m_vendorStock.size(); ++i)
        {
            VendorSlot const& slot = m_vendorStock[i];
            std::string kind = "c", name, icon, description, rarity;
            uint32 rank = 0, maxRank = 0;
            if (slot.isCharge)
            {
                uint8 const charge = slot.charge < MAX_BONK_VENDOR_CHARGE ? slot.charge : BONK_VENDOR_CHARGE_SKIP;
                name = GetString(BONK_STRING_VENDOR_CHARGE, { GetString(CHARGE_NAMES[charge]) });
                icon = CHARGE_ICONS[charge];
                description = GetString(CHARGE_DESCRIPTIONS[charge]);
            }
            else
            {
                Offer const& card = slot.card;
                name = DescribeOffer(card, &icon);
                kind = card.isCard ? "d" : card.step == BONK_STEP_EVOLVE ? "e" : card.isWeapon ? "w" : "p";
                rank = card.newLevel;
                if (card.isCard)
                {
                    if (BonkCard const* darkmoon = sBonkMgr.GetCard(card.id))
                        maxRank = darkmoon->maxCopies;
                }
                else if (!card.isWeapon)
                    if (BonkPassive const* passive = sBonkMgr.GetPassive(card.id))
                        maxRank = passive->maxRank;
                description = DescribeStep(card);
                if (card.isCard || (card.isWeapon && card.step != BONK_STEP_NEW))
                    rarity = std::to_string(card.rarity);
            }
            WorldPacket data(SMSG_HOA_MESSAGE);
            HoAWriteVendorSlot(data, i + 1, kind, rank, maxRank, name, icon, description, rarity, slot.locked, slot.price,
                slot.state);
            m_player->GetSession()->SendPacket(&data);
        }
        WorldPacket end(SMSG_HOA_MESSAGE);
        HoAWriteVendorEnd(end);
        m_player->GetSession()->SendPacket(&end);
        return;
    }

    ChatHandler handler(m_player);
    handler.SendSysMessage(GetString(BONK_STRING_VENDOR_CHAT_HEADER, { VendorName(m_player), std::to_string(m_coins), std::to_string(rerollCost),
        std::to_string(GetVendorRestocksLeft()) }).c_str());
    for (size_t i = 0; i < m_vendorStock.size(); ++i)
    {
        VendorSlot const& slot = m_vendorStock[i];
        std::string name;
        if (slot.isCharge)
            name = GetString(BONK_STRING_VENDOR_CHARGE, { GetString(CHARGE_NAMES[slot.charge < MAX_BONK_VENDOR_CHARGE ? slot.charge : BONK_VENDOR_CHARGE_SKIP]) });
        else
        {
            std::string const offer = DescribeOffer(slot.card, nullptr);
            std::string const rank = std::to_string(slot.card.newLevel);
            name = slot.card.isWeapon && slot.card.step != BONK_STEP_NEW ?
                GetString(BONK_STRING_VENDOR_CHAT_RANK_RARITY, { offer, rank, GetString(GetBonkRarityString(slot.card.rarity)) }) :
                GetString(BONK_STRING_VENDOR_CHAT_RANK, { offer, rank });
            name += ": " + JoinBonkLines(DescribeStep(slot.card));
        }
        BonkString const price = slot.state == VENDOR_SOLD ? BONK_STRING_VENDOR_CHAT_PRICE_BOUGHT : slot.state == VENDOR_GONE ? BONK_STRING_VENDOR_CHAT_PRICE_GONE :
            slot.locked ? BONK_STRING_VENDOR_CHAT_PRICE_LOCKED : BONK_STRING_VENDOR_CHAT_PRICE;
        handler.PSendSysMessage("  %u) %s (%s)", uint32(i + 1), name.c_str(), GetString(price, { std::to_string(slot.price) }).c_str());
    }
}

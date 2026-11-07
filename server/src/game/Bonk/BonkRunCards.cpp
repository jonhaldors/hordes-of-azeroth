#include "BonkRun.h"
#include "BonkAura.h"
#include "BonkCodex.h"
#include "BonkLocale.h"
#include "BonkMgr.h"
#include "BonkMobAI.h"
#include "BonkPlayer.h"
#include "BonkQuests.h"
#include "Creature.h"
#include "HoaProtocol.h"
#include "Item.h"
#include "Log.h"
#include "Player.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "Utilities/Random.h"
#include "WorldSession.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <iterator>

namespace
{
    BonkRarity const BONK_CARD_CHEST_MIN_RARITY = BONK_RARITY_UNCOMMON;

    uint32 const BONK_SPELL_CARD_FIRE      = 13342;
    uint32 const BONK_SPELL_CARD_CHAIN_THREE = 22355;
    uint32 const BONK_SPELL_CARD_CHAIN_FIVE  = 25021;
    uint32 const BONK_SPELL_STOCK_THORNS   = 467;
    uint32 const BONK_SPELL_CARD_NOVA      = 11307;
    uint32 const BONK_SPELL_CARD_SHADOW    = 16583;
    uint32 const BONK_SPELL_HEALTHSTONE    = 11732;
    float const BONK_SHADOW_BURST_HEAL     = 0.1f;
    float const BONK_CARD_COPY_DECAY       = 0.85f;
    float const BONK_CARD_COPY_FLOOR       = 0.1f;
    float const BONK_CHAMPION_MAX_REDUCTION = 60.0f;
    BonkCardEffect const BONK_CAST_CHARGE_EFFECTS[] = { BONK_CARD_DEATH_RAY, BONK_CARD_FIRE_BURST, BONK_CARD_SHADOW_BURST, BONK_CARD_CHAIN };

    uint32 const BONK_KIT_FIRE_IMPACT      = 728;
    uint32 const BONK_KIT_NOVA             = 984;
    uint32 const BONK_KIT_DEATH_RAY        = 419;
    uint32 const BONK_KIT_SHADOW_IMPACT    = 2350;
    uint32 const BONK_KIT_THORNS_BURST     = 6377;

    bool IsCardSpell(SpellEntry const* spell)
    {
        if (!spell)
            return false;
        switch (spell->Id)
        {
            case BONK_SPELL_CARD_FIRE:
            case BONK_SPELL_CARD_CHAIN_THREE:
            case BONK_SPELL_CARD_CHAIN_FIVE:
            case BONK_SPELL_STOCK_THORNS:
            case BONK_SPELL_CARD_NOVA:
            case BONK_SPELL_CARD_SHADOW:
                return true;
            default:
                return false;
        }
    }

    float StackChance(float percent, uint32 copies)
    {
        if (!copies || percent <= 0.0f)
            return 0.0f;
        float miss = 1.0f;
        for (uint32 copy = 1; copy <= copies; ++copy)
            miss *= 1.0f - std::min(percent * BonkRun::GetCopyWeight(copy), 100.0f) / 100.0f;
        return 100.0f * (1.0f - miss);
    }
}

float BonkRun::GetCopyWeight(uint32 copy)
{
    if (!copy)
        return 0.0f;
    return std::max(BONK_CARD_COPY_FLOOR, std::pow(BONK_CARD_COPY_DECAY, float(copy - 1)));
}

float BonkRun::GetStatCopyWeight(uint8 stat, uint32 copy)
{
    return stat == BONK_PASSIVE_AMOUNT ? (copy ? 1.0f : 0.0f) : GetCopyWeight(copy);
}

float BonkRun::GetStatCopySum(uint8 stat, uint32 copies)
{
    return stat == BONK_PASSIVE_AMOUNT ? float(copies) : GetCopySum(copies);
}

float BonkRun::GetStackedChance(float percent, uint32 copies)
{
    return StackChance(percent, copies);
}

float BonkRun::GetChampionMaxReduction()
{
    return BONK_CHAMPION_MAX_REDUCTION;
}

float BonkRun::GetCopySum(uint32 copies)
{
    float sum = 0.0f;
    for (uint32 copy = 1; copy <= copies; ++copy)
        sum += GetCopyWeight(copy);
    return sum;
}

std::pair<bool, uint32> BonkRun::GetBanishKey(Offer const& offer)
{
    uint32 const BONK_CARD_BANISH_OFFSET = 1000000;
    uint32 const BONK_EVOLUTION_BANISH_OFFSET = 2000000;
    if (offer.isCard)
        return { false, BONK_CARD_BANISH_OFFSET + offer.id };
    if (offer.isWeapon && offer.step == BONK_STEP_EVOLVE)
        return { true, BONK_EVOLUTION_BANISH_OFFSET + offer.evolveTo };
    return { offer.isWeapon, offer.id };
}

uint32 BonkRun::GetCardCopies(uint32 cardId) const
{
    for (OwnedCard const& owned : m_cards)
        if (owned.card->id == cardId)
            return owned.copies;
    return 0;
}

float BonkRun::GetCardTotal(BonkCardEffect effect, uint8 index) const
{
    float total = 0.0f;
    if (index < 3 && m_cardCopies[effect])
        for (OwnedCard const& owned : m_cards)
            if (owned.card->effect == effect)
                total += owned.card->values[index] * GetCopySum(owned.copies);
    return total;
}

float BonkRun::GetCardChance(BonkCardEffect effect) const
{
    if (!m_cardCopies[effect])
        return 0.0f;
    float miss = 1.0f;
    for (OwnedCard const& owned : m_cards)
        if (owned.card->effect == effect)
            miss *= 1.0f - StackChance(owned.card->values[0], owned.copies) / 100.0f;
    return 100.0f * (1.0f - miss);
}

uint32 BonkRun::GetCardCooldown(BonkCardEffect effect) const
{
    BonkCard const* card = m_cardByEffect[effect];
    if (!card)
        return 0;
    return uint32(card->cooldownMs * GetCopyWeight(m_cardCopies[effect]));
}

float BonkRun::GetCardPower(Unit const* victim) const
{
    float power = 0.0f;

    if (BonkCard const* brooch = m_cardByEffect[BONK_CARD_KILL_POWER])
        power += std::min(brooch->values[1], brooch->values[0] * m_killPowerKills) *
            GetCopySum(m_cardCopies[BONK_CARD_KILL_POWER]);

    if (HasCard(BONK_CARD_UNHIT_POWER))
    {
        float const seconds = float(GetCardAuraStacks(BONK_SPELL_UNHIT_POWER_AURA));
        power += std::min(GetCardTotal(BONK_CARD_UNHIT_POWER, 1), GetCardTotal(BONK_CARD_UNHIT_POWER, 0) * seconds);
    }

    if (m_player->HasAura(BONK_SPELL_DARKMOON_SURGE))
        power += GetCardTotal(BONK_CARD_POWER_SURGE, 0);
    power += GetTrinketPower();

    if (HasCard(BONK_CARD_BIG_GAME) && victim && victim->IsCreature())
        if (BonkMobAI const* ai = dynamic_cast<BonkMobAI const*>(static_cast<Creature const*>(victim)->AI()))
            if (ai->GetKind() != BONK_SPAWN_NORMAL)
                power += GetCardTotal(BONK_CARD_BIG_GAME, 0);

    return power;
}

bool BonkRun::IsCardInPool(BonkCard const& card) const
{
    if (m_coopOwnXp && card.effect == BONK_CARD_MAGNET)
        return false;
    return card.inChests && sBonkQuests.IsInPool(m_player->GetBonkPlayer()->GetProgressAccount(), BONK_REWARD_CARD, card.id);
}

size_t BonkRun::PickWeightedCard(std::vector<BonkCard const*> const& pool) const
{
    uint32 printed[BONK_RARITY_LEGENDARY] = {};
    for (auto const& itr : sBonkMgr.GetCards())
        if (itr.second.rarity < BONK_RARITY_LEGENDARY && IsCardInPool(itr.second))
            ++printed[itr.second.rarity];

    uint8 const lift = GetGlyph(BONK_GLYPH_GAMBLER) ? 1 : 0;
    std::vector<float> weights;
    float total = 0.0f;
    for (BonkCard const* card : pool)
    {
        bool const drawable = card->rarity < BONK_RARITY_LEGENDARY && card->rarity >= lift;
        float const weight = drawable ? GetRarityWeight(card->rarity - lift, BONK_RARITY_COMMON) / std::max(1u, printed[card->rarity]) : 0.0f;
        weights.push_back(weight);
        total += weight;
    }

    if (total <= 0.0f)
    {
        auto const best = std::max_element(pool.begin(), pool.end(), [](BonkCard const* a, BonkCard const* b) { return a->rarity < b->rarity; });
        return size_t(best - pool.begin());
    }

    float roll = frand(0.0f, total);
    for (size_t i = 0; i < weights.size(); ++i)
    {
        if (weights[i] > 0.0f && roll < weights[i])
            return i;
        roll -= weights[i];
    }
    return size_t(std::find_if(weights.rbegin(), weights.rend(), [](float weight) { return weight > 0.0f; }).base() - weights.begin()) - 1;
}

void BonkRun::GiveStartCard()
{
    float const draw = GetUtility(BONK_UTILITY_START_CARD);
    if (draw < 1.0f)
        return;
    BonkRarity const rarity = draw >= 2.0f ? BONK_RARITY_UNCOMMON : BONK_RARITY_COMMON;
    std::vector<BonkCard const*> pool;
    for (auto const& itr : sBonkMgr.GetCards())
        if (itr.second.rarity == rarity && IsCardInPool(itr.second) && itr.second.effect != BONK_CARD_MAGNET)
            pool.push_back(&itr.second);
    if (pool.empty())
        return;
    BonkCard const& card = *pool[urand(0, uint32(pool.size()) - 1)];
    AddCard(card);
    m_player->GetBonkPlayer()->Notify(BONK_STRING_LUCKY_DRAW_GAVE_YOU, { Localize(BONK_FIELD_CARD_NAME, card.id, card.name) });
}

bool BonkRun::IsCardCapped(BonkCard const& card) const
{
    if (card.effect == BONK_CARD_ASCENSION)
        return !HasEvolutionLeft();
    if (card.effect != BONK_CARD_NONE)
        return false;
    uint32 const nextCopy = GetCardCopies(card.id) + 1;
    bool grantsStat = false;
    for (uint8 i = 0; i < 2; ++i)
    {
        BonkPassiveEffect const stat = card.stats[i];
        if (stat >= MAX_BONK_PASSIVE_EFFECT)
            continue;
        if (!IsGainTooSmall(stat, card.statValues[i] * GetStatCopyWeight(stat, nextCopy)))
            return false;
        grantsStat = true;
    }
    return grantsStat;
}

bool BonkRun::OfferCards(size_t offerSize, std::vector<Offer> const* avoid, std::vector<Offer> const* kept, std::vector<Offer>* drawn)
{
    std::vector<Offer> cards;
    std::vector<Offer> carried;
    if (kept)
        carried = *kept;
    else
    {
        carried = m_lockedOffers;
        m_lockedOffers.clear();
    }
    for (Offer offer : carried)
        if (cards.size() < offerSize && RefreshKeptOffer(offer))
        {
            offer.locked = true;
            cards.push_back(offer);
        }

    auto makeOffer = [this](BonkCard const& card)
    {
        Offer offer;
        offer.isWeapon = false;
        offer.isCard = true;
        offer.id = card.id;
        offer.rarity = card.rarity;
        offer.newLevel = GetCardCopies(card.id) + 1;
        return offer;
    };
    auto shown = [&cards](uint32 id)
    {
        return std::any_of(cards.begin(), cards.end(), [id](Offer const& card) { return card.isCard && card.id == id; });
    };

    std::vector<BonkCard const*> fresh;
    std::vector<BonkCard const*> repeats;
    for (auto const& itr : sBonkMgr.GetCards())
    {
        BonkCard const& card = itr.second;
        Offer probe;
        probe.isWeapon = false;
        probe.isCard = true;
        probe.id = card.id;
        if (!IsCardInPool(card) || m_banished.count(GetBanishKey(probe)) || shown(card.id) || (card.maxCopies && GetCardCopies(card.id) >= card.maxCopies) ||
            IsCardCapped(card))
            continue;
        bool const avoided = avoid && std::any_of(avoid->begin(), avoid->end(), [&](Offer const& offer) { return offer.isCard && offer.id == card.id; });
        (avoided ? repeats : fresh).push_back(&card);
    }

    for (std::vector<BonkCard const*>* pool : { &fresh, &repeats })
        while (cards.size() < offerSize && !pool->empty())
        {
            size_t const chosen = PickWeightedCard(*pool);
            cards.push_back(makeOffer(*(*pool)[chosen]));
            pool->erase(pool->begin() + chosen);
        }

    if (std::none_of(cards.begin(), cards.end(), [](Offer const& card) { return card.rarity >= BONK_CARD_CHEST_MIN_RARITY; }))
    {
        std::vector<BonkCard const*> better;
        for (std::vector<BonkCard const*> const* pool : { &fresh, &repeats })
            for (BonkCard const* card : *pool)
                if (card->rarity >= BONK_CARD_CHEST_MIN_RARITY)
                    better.push_back(card);
        auto replaced = std::find_if(cards.rbegin(), cards.rend(), [](Offer const& card) { return !card.locked; });
        if (!better.empty() && replaced != cards.rend())
            *replaced = makeOffer(*better[PickWeightedCard(better)]);
    }

    if (drawn)
    {
        *drawn = cards;
        return !cards.empty();
    }

    m_offer = cards;
    if (m_offer.empty())
    {
        if (!m_pendingChestChoices.empty())
            m_pendingChestChoices.erase(m_pendingChestChoices.begin());
        uint32 const gold = m_map.goldPerKill * 25;
        uint32 const paid = uint32(gold * GetGoldMultiplier());
        GiveGold(gold);
        m_player->GetBonkPlayer()->Notify(paid ? BONK_STRING_DECK_EMPTY_GOLD : BONK_STRING_DECK_EMPTY, { FormatBonkMoney(paid, GetLocale()) });
        return false;
    }

    m_offerSource = OFFER_CHEST;
    SetPaused(true);
    SendOffer();
    return true;
}

void BonkRun::AddCard(BonkCard const& card)
{
    auto owned = std::find_if(m_cards.begin(), m_cards.end(), [&card](OwnedCard const& held) { return held.card->id == card.id; });
    if (owned == m_cards.end())
        m_cards.push_back({ &card, 1 });
    else
        ++owned->copies;

    uint32 const copies = GetCardCopies(card.id);
    for (uint8 i = 0; i < 2; ++i)
        if (card.stats[i] < MAX_BONK_PASSIVE_EFFECT)
            m_cardStats[card.stats[i]] += card.statValues[i] * GetStatCopyWeight(card.stats[i], copies);

    if (card.effect != BONK_CARD_NONE)
    {
        ++m_cardCopies[card.effect];
        if (!m_cardByEffect[card.effect] || card.rarity >= m_cardByEffect[card.effect]->rarity)
            m_cardByEffect[card.effect] = &card;
    }
    switch (card.effect)
    {
        case BONK_CARD_SOULSTONE:
            ++m_soulstones;
            break;
        case BONK_CARD_THORNS:
            RefreshThornsAura();
            break;
        case BONK_CARD_KILL_POWER:
            RefreshKillPowerAura();
            break;
        case BONK_CARD_UNHIT_POWER:
            RefreshUnhitPowerAura();
            break;
        case BONK_CARD_CRIT_HEAL:
            if (m_cardCopies[card.effect] == 1)
                m_cardCritsSeen = m_crits;
            break;
        default:
            break;
    }

    ApplyPassives();
    SendCards();
}

void BonkRun::RemoveCard(BonkCard const& card)
{
    auto owned = std::find_if(m_cards.begin(), m_cards.end(), [&card](OwnedCard const& held) { return held.card->id == card.id; });
    if (owned == m_cards.end())
        return;
    uint32 const copies = owned->copies;
    if (--owned->copies == 0)
        m_cards.erase(owned);

    for (uint8 i = 0; i < 2; ++i)
        if (card.stats[i] < MAX_BONK_PASSIVE_EFFECT)
            m_cardStats[card.stats[i]] -= card.statValues[i] * GetStatCopyWeight(card.stats[i], copies);

    if (card.effect != BONK_CARD_NONE && m_cardCopies[card.effect])
    {
        --m_cardCopies[card.effect];
        m_cardByEffect[card.effect] = nullptr;
        for (OwnedCard const& held : m_cards)
            if (held.card->effect == card.effect && (!m_cardByEffect[card.effect] || held.card->rarity >= m_cardByEffect[card.effect]->rarity))
                m_cardByEffect[card.effect] = held.card;
    }

    ApplyPassives();
    SendCards();
}

void BonkRun::SyncGearCards()
{
    std::vector<uint32> worn;
    if (!m_sandboxBench)
        for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
            if (Item const* item = m_player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
                if (uint32 const cardId = sBonkMgr.GetItemCard(item->GetEntry()))
                    worn.push_back(cardId);
    std::sort(worn.begin(), worn.end());
    if (worn == m_gearCards)
        return;

    std::vector<uint32> gone, added;
    std::set_difference(m_gearCards.begin(), m_gearCards.end(), worn.begin(), worn.end(), std::back_inserter(gone));
    std::set_difference(worn.begin(), worn.end(), m_gearCards.begin(), m_gearCards.end(), std::back_inserter(added));
    m_gearCards = worn;
    for (uint32 cardId : gone)
        if (BonkCard const* card = sBonkMgr.GetCard(cardId))
            RemoveCard(*card);
    for (uint32 cardId : added)
        if (BonkCard const* card = sBonkMgr.GetCard(cardId))
            AddCard(*card);
}

bool BonkRun::GiveCard(uint32 cardId, std::string& error)
{
    BonkCard const* card = sBonkMgr.GetCard(cardId);
    if (!card)
    {
        error = GetString(BONK_STRING_THERE_IS_NO_CARD, { std::to_string(cardId) });
        return false;
    }
    AddCard(*card);
    m_player->GetBonkPlayer()->Notify(BONK_STRING_EXCLAIM, { Localize(BONK_FIELD_CARD_NAME, card->id, card->name) });
    return true;
}

void BonkRun::UpdateCards(uint32 diff)
{
    if (m_cards.empty() || !m_player->IsAlive())
        return;

    for (int32& cooldown : m_cardCooldowns)
        if (cooldown > 0)
            cooldown -= int32(diff);

    float const health = m_player->GetHealthPercent();
    uint32 const maxHealth = m_player->GetMaxHealth();

    if (BonkCard const* stone = m_cardByEffect[BONK_CARD_HEALTHSTONE])
        if (m_cardCooldowns[BONK_CARD_HEALTHSTONE] <= 0 && health < stone->values[0])
        {
            SupportScope scope(*this, CardSupport(BONK_CARD_HEALTHSTONE));
            HealHero(ReduceHealing(uint32(maxHealth * stone->values[1] / 100.0f)), BONK_SPELL_HEALTHSTONE);
            StartCardCooldown(BONK_CARD_HEALTHSTONE, GetCardCooldown(BONK_CARD_HEALTHSTONE));
        }

    if (BonkCard const* potion = m_cardByEffect[BONK_CARD_SWIFTNESS])
    {
        if (!m_player->HasAura(BONK_SPELL_CARD_SWIFT) && m_cardCooldowns[BONK_CARD_SWIFTNESS] <= 0 && health < potion->values[0])
        {
            if (SpellAuraHolder* holder = m_player->AddAura(BONK_SPELL_CARD_SWIFT, ADD_AURA_POSITIVE))
            {
                int32 const duration = int32(potion->values[2]);
                holder->SetAuraDuration(duration);
                holder->SetAuraMaxDuration(duration);
                holder->UpdateAuraDuration();
            }
            SendCardAuraText(BONK_SPELL_CARD_SWIFT, *potion);
            StartCardCooldown(BONK_CARD_SWIFTNESS, GetCardCooldown(BONK_CARD_SWIFTNESS));
        }
        bool const swift = m_player->HasAura(BONK_SPELL_CARD_SWIFT);
        if (swift != m_cardSwiftActive)
        {
            m_cardSwiftActive = swift;
            ApplyPassives();
        }
    }

    if (BonkCard const* charm = m_cardByEffect[BONK_CARD_POWER_SURGE])
        if (m_cardCooldowns[BONK_CARD_POWER_SURGE] <= 0)
        {
            if (SpellAuraHolder* holder = m_player->AddAura(BONK_SPELL_DARKMOON_SURGE, ADD_AURA_POSITIVE))
            {
                int32 const duration = int32(charm->values[1]);
                holder->SetAuraDuration(duration);
                holder->SetAuraMaxDuration(duration);
                holder->UpdateAuraDuration();
                holder->SetStackAmount(GetCardCopies(charm->id));
                m_player->ForceValuesUpdateAtIndex(UNIT_FIELD_AURA + holder->GetAuraSlot());
                m_player->ForceValuesUpdateAtIndex(UNIT_FIELD_AURAFLAGS + (holder->GetAuraSlot() >> 3));
                m_player->ExecuteDelayedActions();
                m_player->SendForcedObjectUpdate();
                // The surge window's aura text states the live bonus (copies included), not the
                // trinket card's every-30-sec rule.
                if (BonkAuraEntry const* surge = sBonkAura.Get(BONK_SPELL_DARKMOON_SURGE))
                    m_player->GetBonkPlayer()->SendAuraText(BONK_SPELL_DARKMOON_SURGE,
                        sBonkAura.Format(*surge, GetLocale(), { FormatBonkNumber(GetCardTotal(BONK_CARD_POWER_SURGE, 0)) }));
            }
            StartCardCooldown(BONK_CARD_POWER_SURGE, charm->cooldownMs);
            m_player->GetBonkPlayer()->Notify(BONK_STRING_POWER_SURGE, { Localize(BONK_FIELD_CARD_NAME, charm->id, charm->name), FormatBonkNumber(GetCardTotal(BONK_CARD_POWER_SURGE, 0)),
                FormatBonkNumber(charm->values[1] / 1000.0f) });
        }

    if (HasCard(BONK_CARD_MAGNET) && m_cardCooldowns[BONK_CARD_MAGNET] <= 0)
    {
        PullAllCurrency();
        StartCardCooldown(BONK_CARD_MAGNET, GetCardCooldown(BONK_CARD_MAGNET));
    }

    if (m_player->IsMoving())
        m_stillSinceMs = m_totalMs;

    m_cardTickMs += diff;
    if (m_cardTickMs < IN_MILLISECONDS)
        return;
    m_cardTickMs -= IN_MILLISECONDS;
    RefreshUnhitPowerAura();

    auto healFromCard = [&](BonkCardEffect effect, float percent)
    {
        if (percent <= 0.0f)
            return;
        SupportScope scope(*this, CardSupport(effect));
        RegenerateHero(ReduceHealing(std::max(1u, uint32(maxHealth * percent / 100.0f))));
    };
    if (BonkCard const* bandage = m_cardByEffect[BONK_CARD_BANDAGE])
    {
        bool const ready = !m_hurt || m_totalMs - m_lastHurtMs >= uint32(bandage->values[1] * IN_MILLISECONDS);
        if (ready)
            healFromCard(BONK_CARD_BANDAGE, GetCardTotal(BONK_CARD_BANDAGE, 0));
        bool const changed = SyncStackAura(BONK_SPELL_BANDAGE_AURA, ready ? GetCardCopies(bandage->id) : 0);
        if (ready && changed)
            SendCardAuraText(BONK_SPELL_BANDAGE_AURA, *bandage);
    }
    else
        SyncStackAura(BONK_SPELL_BANDAGE_AURA, 0);
    if (BonkCard const* campfire = m_cardByEffect[BONK_CARD_CAMPFIRE])
    {
        bool const ready = m_totalMs - m_stillSinceMs >= uint32(campfire->values[1] * IN_MILLISECONDS);
        if (ready)
            healFromCard(BONK_CARD_CAMPFIRE, GetCardTotal(BONK_CARD_CAMPFIRE, 0));
        bool const changed = SyncStackAura(BONK_SPELL_CAMPFIRE_AURA, ready ? GetCardCopies(campfire->id) : 0);
        if (ready && changed)
            SendCardAuraText(BONK_SPELL_CAMPFIRE_AURA, *campfire);
    }
    else
        SyncStackAura(BONK_SPELL_CAMPFIRE_AURA, 0);
    if (BonkCard const* heroism = m_cardByEffect[BONK_CARD_CRIT_HEAL])
    {
        uint32 const crits = m_crits - m_cardCritsSeen;
        m_cardCritsSeen = m_crits;
        healFromCard(BONK_CARD_CRIT_HEAL, std::min(crits * GetCardChance(BONK_CARD_CRIT_HEAL) / 100.0f * heroism->values[1],
            GetCardTotal(BONK_CARD_CRIT_HEAL, 2)));
    }

    SendCardStatus(false);
}

std::string BonkRun::DescribeCardNow(BonkCard const& card) const
{
    auto percent = [](float value)
    {
        char buffer[32];
        snprintf(buffer, sizeof(buffer), "%.2f", value);
        std::string text = buffer;
        while (!text.empty() && text.back() == '0')
            text.pop_back();
        if (!text.empty() && text.back() == '.')
            text.pop_back();
        return text;
    };

    switch (card.effect)
    {
        case BONK_CARD_KILL_POWER:
        {
            float const power = std::min(card.values[1], card.values[0] * m_killPowerKills) *
                GetCopySum(GetCardCopies(card.id));
            return GetString(BONK_STRING_CARD_NOW_POWER, { percent(power) });
        }
        case BONK_CARD_UNHIT_POWER:
        {
            float const seconds = float(GetCardAuraStacks(BONK_SPELL_UNHIT_POWER_AURA));
            float const power = std::min(GetCardTotal(BONK_CARD_UNHIT_POWER, 1), GetCardTotal(BONK_CARD_UNHIT_POWER, 0) * seconds);
            return GetString(BONK_STRING_CARD_NOW_POWER, { percent(power) });
        }
        case BONK_CARD_HASTE_BURST:
            if (m_player->HasAura(BONK_SPELL_CARD_HASTE))
                return GetString(BONK_STRING_CARD_ACTIVE_HASTE, { percent(GetCardTotal(BONK_CARD_HASTE_BURST, 1)) });
            return "";
        case BONK_CARD_POWER_SURGE:
            if (SpellAuraHolder const* holder = m_player->GetSpellAuraHolder(BONK_SPELL_DARKMOON_SURGE))
            {
                int32 const leftMs = std::max(0, holder->GetAuraDuration());
                if (leftMs > 0)
                {
                    uint32 const left = (uint32(leftMs) + 999) / IN_MILLISECONDS;
                    return GetString(left == 1 ? BONK_STRING_CARD_ACTIVE_POWER_ONE : BONK_STRING_CARD_ACTIVE_POWER,
                        { percent(GetCardTotal(BONK_CARD_POWER_SURGE, 0)), std::to_string(left) });
                }
            }
            return "";
        case BONK_CARD_SOULSTONE:
            return GetString(m_soulstones == 1 ? BONK_STRING_CARD_CHARGES_LEFT_ONE : BONK_STRING_CARD_CHARGES_LEFT, { std::to_string(m_soulstones) });
        case BONK_CARD_ASCENSION:
            if (OwnedWeapon const* owned = FindAscensionWeapon())
                return GetString(BONK_STRING_CARD_ASCENSION_READY, { Localize(BONK_FIELD_WEAPON_NAME, owned->weapon.id, owned->weapon.name) });
            return "";
        default:
            return "";
    }
}

void BonkRun::SendCardStatus(bool force) const
{
    BonkPlayer* bonk = m_player->GetBonkPlayer();
    for (OwnedCard const& owned : m_cards)
    {
        std::string const text = DescribeCardNow(*owned.card);
        auto sent = m_cardNowSent.find(owned.card->id);
        if (!force && (sent != m_cardNowSent.end() ? sent->second == text : text.empty()))
            continue;
        m_cardNowSent[owned.card->id] = text;
        if (bonk->IsAddonReady())
        {
            WorldPacket data(SMSG_HOA_MESSAGE);
            HoAWriteCardNow(data, owned.card->id, text);
            m_player->GetSession()->SendPacket(&data);
        }
    }
}

void BonkRun::RegenerateHero(uint32 amount)
{
    m_regenerating = true;
    HealHero(amount);
    m_regenerating = false;
}

void BonkRun::HealHero(uint32 amount, uint32 textSpellId)
{
    if (!amount || !m_player->IsAlive())
        return;

    SupportScope scope(*this, m_supportSource.name.empty() ? SpellSupport(textSpellId) : m_supportSource);
    uint32 const maxHealth = m_player->GetMaxHealth();
    uint32 const healed = std::min(amount, maxHealth - std::min(maxHealth, m_player->GetHealth()));
    if (healed)
    {
        if (SpellEntry const* text = textSpellId ? sSpellMgr.GetSpellEntry(textSpellId) : nullptr)
            m_player->DealHeal(m_player, healed, text);
        else
            m_player->ModifyHealth(int32(healed));
    }

    if (amount > healed && !m_regenerating && HasCard(BONK_CARD_OVERHEAL))
    {
        uint32 const cap = uint32(maxHealth * GetCardTotal(BONK_CARD_OVERHEAL, 0) / 100.0f);
        SupportScope overheal(*this, CardSupport(BONK_CARD_OVERHEAL));
        if (m_spellShield < cap)
            AddSpellShield(std::min(amount - healed, cap - m_spellShield));
    }
    if (amount > healed)
        OnPriestOverheal();
}

void BonkRun::OnCardHitTaken()
{
    if (BonkCard const* insignia = m_cardByEffect[BONK_CARD_HIT_IMMUNE])
        if (m_cardCooldowns[BONK_CARD_HIT_IMMUNE] <= 0)
        {
            if (SpellAuraHolder* holder = m_player->AddAura(BONK_SPELL_CARD_IMMUNE, ADD_AURA_POSITIVE))
            {
                int32 const duration = int32(insignia->values[0]);
                holder->SetAuraDuration(duration);
                holder->SetAuraMaxDuration(duration);
                holder->UpdateAuraDuration();
            }
            SendCardAuraText(BONK_SPELL_CARD_IMMUNE, *insignia);
            StartCardCooldown(BONK_CARD_HIT_IMMUNE, GetCardCooldown(BONK_CARD_HIT_IMMUNE));
        }
}

void BonkRun::OnShieldBroken()
{
    BonkCard const* disk = m_cardByEffect[BONK_CARD_SHIELD_NOVA];
    SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(BONK_SPELL_CARD_NOVA);
    if (!disk || !spellInfo || m_cardProc)
        return;

    float const damage = GetProcBaseHealth() * GetCardTotal(BONK_CARD_SHIELD_NOVA, 0);
    m_player->SendPlaySpellVisualKit(BONK_KIT_NOVA);
    m_cardProc = true;
    for (Creature* mob : GetMobsInRange(disk->values[1]))
        DealSpellHit(spellInfo, mob, damage);
    m_cardProc = false;
}

bool BonkRun::RollFreeChest() const
{
    return HasCard(BONK_CARD_FREE_CHEST) && roll_chance_f(GetCardChance(BONK_CARD_FREE_CHEST));
}

void BonkRun::OnHeroHitBy(Creature* attacker, uint32 damage)
{
    ShakeOnHeroHit(damage);
    if (damage)
        TriggerGlyphNova();
    BonkCard const* choker = m_cardByEffect[BONK_CARD_THORNS];
    if (!damage || !attacker || !choker || m_cardProc || m_cardCooldowns[BONK_CARD_THORNS] > 0)
        return;
    SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(BONK_SPELL_STOCK_THORNS);
    if (!spellInfo)
        return;
    m_cardCooldowns[BONK_CARD_THORNS] = int32(choker->values[2]);
    float const burst = GetProcBaseHealth() * GetCardTotal(BONK_CARD_THORNS, 0) / 100.0f;
    m_player->SendPlaySpellVisualKit(BONK_KIT_THORNS_BURST);
    m_cardProc = true;
    for (Creature* mob : GetMobsInRange(choker->values[1]))
        DealSpellHit(spellInfo, mob, burst);
    m_cardProc = false;
}

void BonkRun::ModifyHeroHit(Unit* victim, uint32& damage)
{
    if (!m_cardProc)
        ModifyGlyphHit(victim, damage);
}

void BonkRun::RollCastCharges(OwnedWeapon& owned)
{
    owned.forcedCrit = m_vanishCritPending;
    m_vanishCritPending = false;
    if (owned.weapon.IsPassiveTrigger())
        return;
    if (int32(m_totalMs - owned.castRollAtMs) < 0)
    {
        owned.castCharges &= ~owned.castChargesSpent;
        owned.castChargesSpent = 0;
        return;
    }
    owned.castRollAtMs = m_totalMs + GetWeaponCooldown(owned);
    owned.castCharges = 0;
    owned.castChargesSpent = 0;
    if (m_cards.empty())
        return;
    for (BonkCardEffect effect : BONK_CAST_CHARGE_EFFECTS)
        if (HasCard(effect) && roll_chance_f(GetCardChance(effect)))
            owned.castCharges |= 1u << effect;

    if (BonkCard const* dragon = m_cardByEffect[BONK_CARD_HASTE_BURST])
        if (m_cardCooldowns[BONK_CARD_HASTE_BURST] <= 0 && roll_chance_f(GetCardChance(BONK_CARD_HASTE_BURST)))
        {
            if (SpellAuraHolder* holder = m_player->AddAura(BONK_SPELL_CARD_HASTE, ADD_AURA_POSITIVE))
            {
                int32 const duration = int32(dragon->values[2]);
                holder->SetAuraDuration(duration);
                holder->SetAuraMaxDuration(duration);
                holder->UpdateAuraDuration();
                holder->SetStackAmount(GetCardCopies(dragon->id));
            }
            SendCardAuraText(BONK_SPELL_CARD_HASTE, *dragon);
            StartCardCooldown(BONK_CARD_HASTE_BURST, dragon->cooldownMs);
        }
}

bool BonkRun::SpendCastCharge(OwnedWeapon& owned, BonkCardEffect effect)
{
    uint32 const bit = 1u << effect;
    if (!(owned.castCharges & bit) || (owned.castChargesSpent & bit))
        return false;
    owned.castChargesSpent |= bit;
    return true;
}

float BonkRun::GetCastChargePower(SpellEntry const* spell, Unit const* victim) const
{
    BonkCard const* ray = m_cardByEffect[BONK_CARD_DEATH_RAY];
    if (!ray || !spell || !victim || m_cardProc)
        return 0.0f;
    OwnedWeapon const* owned = FindOwnedBySpell(spell->Id);
    return owned && IsCastCharged(*owned, BONK_CARD_DEATH_RAY) ? ray->values[1] : 0.0f;
}

std::string BonkRun::DescribeBigHit(SpellEntry const* spell, Unit const* victim) const
{
    float const power = GetRunPower() + GetBuffPower() + GetCardPower(victim) + GetGlyphPower() + GetTalentDamagePercent();
    char text[512];
    snprintf(text, sizeof(text), "total x%.2f | power %.0f%% | gear x%.2f | keyword x%.2f | mage x%.2f | shaman x%.2f | priest x%.2f | rogue x%.2f | "
        "paladin x%.2f | ray +%.0f%% | capstone x%.2f | glyph x%.2f | victim %.0f%% health",
        GetDamageMultiplier(spell, victim), power, GetGearDamageScale(), GetKeywordDamageMultiplier(spell, victim), GetMageDamageMultiplier(victim),
        GetShamanDamageMultiplier(spell, victim), GetPriestDamageMultiplier(victim), GetRogueDamageMultiplier(victim), GetPaladinDamageMultiplier(victim),
        GetCastChargePower(spell, victim), GetCapstoneDamageMultiplier(true, victim), spell ? GetGlyphDamageMultiplier(spell) : 1.0f,
        victim ? victim->GetHealthPercent() : 0.0f);
    return text;
}

float BonkRun::GetChampionDamageTaken(BonkSpawnKind kind) const
{
    if (kind == BONK_SPAWN_NORMAL || !HasCard(BONK_CARD_BIG_GAME))
        return 1.0f;
    return 1.0f - std::min(BONK_CHAMPION_MAX_REDUCTION, GetCardTotal(BONK_CARD_BIG_GAME, 1)) / 100.0f;
}

uint32 BonkRun::GetCardAuraStacks(uint32 spellId) const
{
    SpellAuraHolder const* holder = m_player->GetSpellAuraHolder(spellId);
    return holder ? holder->GetStackAmount() : 0;
}

void BonkRun::RefreshKillPowerAura() const
{
    if (!HasCard(BONK_CARD_KILL_POWER))
        m_killPowerKills = 0;
    uint32 const stacks = std::min<uint32>(255, m_killPowerKills);
    if (!HasCard(BONK_CARD_KILL_POWER) || !stacks)
    {
        m_player->RemoveAurasDueToSpell(BONK_SPELL_KILL_POWER_AURA);
        return;
    }
    if (SpellAuraHolder* holder = m_player->AddAura(BONK_SPELL_KILL_POWER_AURA, ADD_AURA_POSITIVE | ADD_AURA_PERMANENT))
        holder->SetStackAmount(stacks);
    if (BonkCard const* card = m_cardByEffect[BONK_CARD_KILL_POWER])
        SendCardAuraText(BONK_SPELL_KILL_POWER_AURA, *card);
}

void BonkRun::AddKillPowerStack() const
{
    if (!HasCard(BONK_CARD_KILL_POWER))
        return;
    ++m_killPowerKills;
    uint32 const stacks = std::min<uint32>(255, m_killPowerKills);
    if (SpellAuraHolder* holder = m_player->AddAura(BONK_SPELL_KILL_POWER_AURA, ADD_AURA_POSITIVE | ADD_AURA_PERMANENT))
        holder->SetStackAmount(stacks);
    if (BonkCard const* card = m_cardByEffect[BONK_CARD_KILL_POWER])
        SendCardAuraText(BONK_SPELL_KILL_POWER_AURA, *card);
}

void BonkRun::RefreshUnhitPowerAura() const
{
    uint32 stacks = 0;
    if (HasCard(BONK_CARD_UNHIT_POWER))
    {
        float const seconds = float(m_totalMs - (m_hurt ? m_lastHurtMs : 0)) / IN_MILLISECONDS;
        float const perSecond = GetCardTotal(BONK_CARD_UNHIT_POWER, 0);
        float const cap = GetCardTotal(BONK_CARD_UNHIT_POWER, 1);
        // One stack is one second, but stacks past the card's cap do no work.
        uint32 const shown = perSecond > 0.0f ? uint32(std::floor(cap / perSecond)) : 255;
        stacks = std::min<uint32>(std::min<uint32>(255, shown), uint32(std::floor(seconds)));
    }
    if (!stacks)
    {
        m_player->RemoveAurasDueToSpell(BONK_SPELL_UNHIT_POWER_AURA);
        return;
    }
    if (SpellAuraHolder* holder = m_player->AddAura(BONK_SPELL_UNHIT_POWER_AURA, ADD_AURA_POSITIVE | ADD_AURA_PERMANENT))
        holder->SetStackAmount(stacks);
    if (BonkCard const* card = m_cardByEffect[BONK_CARD_UNHIT_POWER])
        SendCardAuraText(BONK_SPELL_UNHIT_POWER_AURA, *card);
}

void BonkRun::RefreshThornsAura() const
{
    uint32 const copies = m_cardCopies[BONK_CARD_THORNS];
    if (!copies)
    {
        m_player->RemoveAurasDueToSpell(BONK_SPELL_CARD_THORNS);
        return;
    }
    if (SpellAuraHolder* holder = m_player->AddAura(BONK_SPELL_CARD_THORNS, ADD_AURA_POSITIVE | ADD_AURA_PERMANENT))
        holder->SetStackAmount(copies);
    if (BonkCard const* card = m_cardByEffect[BONK_CARD_THORNS])
        SendCardAuraText(BONK_SPELL_CARD_THORNS, *card);
}

bool BonkRun::IsCardImmune() const
{
    return m_player->HasAura(BONK_SPELL_CARD_IMMUNE);
}

float BonkRun::GetBurstHaste() const
{
    float haste = 0.0f;
    if (m_player->HasAura(BONK_SPELL_CARD_HASTE))
        haste += GetCardTotal(BONK_CARD_HASTE_BURST, 1);
    if (m_player->HasAura(BONK_SPELL_GLYPH_HASTE_AURA))
        haste += GetGlyphValue(BONK_GLYPH_KILL_HASTE, 1);
    if (IsLastStand())
        haste += GetGlyphValue(BONK_GLYPH_LAST_STAND, 1);
    return haste;
}

float BonkRun::GetDotCardScale() const
{
    return 1.0f + GetCardTotal(BONK_CARD_DOT_DAMAGE, 0) / 100.0f;
}

void BonkRun::OnHeroHit(Unit* victim, double damage, SpellEntry const* spell)
{
    if (!damage || m_cardProc || IsCardSpell(spell) || m_cards.empty())
        return;

    OwnedWeapon* owned = spell ? const_cast<OwnedWeapon*>(FindOwnedBySpell(spell->Id)) : nullptr;
    if (!owned)
        return;

    float const multiplier = std::max(0.1f, GetDamageMultiplier(nullptr, victim, 1.0f, GetCastChargePower(spell, victim)));

    if (SpendCastCharge(*owned, BONK_CARD_DEATH_RAY))
        victim->SendPlaySpellVisualKit(BONK_KIT_DEATH_RAY);

    auto burstTargets = [this, victim](float radius)
    {
        std::vector<Creature*> mobs = GetMobsInRange(radius, victim);
        if (victim->IsAlive() && victim->IsCreature())
            mobs.push_back(static_cast<Creature*>(victim));
        return mobs;
    };

    if (BonkCard const* hand = m_cardByEffect[BONK_CARD_FIRE_BURST])
        if (SpendCastCharge(*owned, BONK_CARD_FIRE_BURST))
            if (SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(BONK_SPELL_CARD_FIRE))
            {
                float const burst = damage * hand->values[1] / multiplier;
                m_cardProc = true;
                for (Creature* mob : burstTargets(hand->values[2]))
                {
                    mob->SendPlaySpellVisualKit(BONK_KIT_FIRE_IMPACT);
                    DealSpellHit(spellInfo, mob, burst);
                }
                m_cardProc = false;
            }

    if (BonkCard const* blade = m_cardByEffect[BONK_CARD_SHADOW_BURST])
        if (SpendCastCharge(*owned, BONK_CARD_SHADOW_BURST))
            if (SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(BONK_SPELL_CARD_SHADOW))
            {
                float const burst = damage * blade->values[1] / multiplier;
                uint32 struck = 0;
                m_cardProc = true;
                for (Creature* mob : burstTargets(blade->values[2]))
                {
                    mob->SendPlaySpellVisualKit(BONK_KIT_SHADOW_IMPACT);
                    DealSpellHit(spellInfo, mob, burst);
                    ++struck;
                }
                m_cardProc = false;
                if (struck)
                {
                    SupportScope scope(*this, { blade->icon, Localize(BONK_FIELD_CARD_NAME, blade->id, blade->name) });
                    HealHero(ReduceHealing(uint32(burst * multiplier * struck * BONK_SHADOW_BURST_HEAL)));
                }
            }

    if (BonkCard const* maelstrom = m_cardByEffect[BONK_CARD_CHAIN])
        if (SpendCastCharge(*owned, BONK_CARD_CHAIN))
        {
            uint32 const chainSpellId = maelstrom->values[2] > 3.0f ? BONK_SPELL_CARD_CHAIN_FIVE : BONK_SPELL_CARD_CHAIN_THREE;
            Unit* target = victim->IsAlive() ? victim : nullptr;
            if (!target)
            {
                std::vector<Creature*> nearby = GetMobsInRange(15.0f, victim);
                target = nearby.empty() ? nullptr : nearby.front();
            }
            if (target)
            {
                int32 const strike = std::max(1, int32(std::min(double(MaxHitDamage), damage * maelstrom->values[1] / multiplier)));
                m_cardProc = true;
                m_player->CastCustomSpell(target, chainSpellId, strike, {}, {}, true);
                m_cardProc = false;
            }
        }
}

std::string BonkRun::DescribeHeldCard(BonkCard const& card, uint32 copies, LocaleConstant locale)
{
    std::string const description = sBonkLocale.Localize(BONK_FIELD_CARD_DESCRIPTION, card.id, card.description, locale);
    if (copies <= 1)
        return description;
    std::string const total = BonkCodex::DescribeCardTotal(card, copies, locale);
    if (total.empty())
        return description;
    if (card.effect == BONK_CARD_NONE)
        return sBonkLocale.GetString(BONK_STRING_SENTENCE, locale, { total });
    return description + BONK_LINE_BREAK + sBonkLocale.GetString(BONK_STRING_CURRENT_TOTAL, locale, { total });
}

void BonkRun::SendCardAuraText(uint32 spellId, BonkCard const& card) const
{
    // An aura with a dynamic template (the surge window's live bonus) states the active effect,
    // not the held card's rule; the rest fall back to the card description with its total line.
    if (BonkAuraEntry const* entry = sBonkAura.Get(spellId))
    {
        std::string const formatted = sBonkAura.Format(*entry, GetLocale(),
            { FormatBonkNumber(GetCardTotal(card.effect, 0)) });
        if (!formatted.empty())
        {
            m_player->GetBonkPlayer()->SendAuraText(spellId, formatted);
            return;
        }
    }
    m_player->GetBonkPlayer()->SendAuraText(spellId, DescribeHeldCard(card, GetCardCopies(card.id), GetLocale()));
}

void BonkRun::SendCards() const
{
    BonkPlayer* bonk = m_player->GetBonkPlayer();
    if (!bonk->IsAddonReady())
        return;
    std::string entries;
    for (OwnedCard const& owned : m_cards)
        if (!m_glyphCardIds.count(owned.card->id))
            entries += std::to_string(owned.card->id) + ":" + std::to_string(owned.copies) + ":" + std::to_string(owned.card->rarity) + ":" +
                owned.card->icon + ":" + std::to_string(owned.card->maxCopies) + ",";
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteCards(data, entries);
        m_player->GetSession()->SendPacket(&data);
    }
    for (OwnedCard const& owned : m_cards)
        if (!m_glyphCardIds.count(owned.card->id))
        {
            WorldPacket data(SMSG_HOA_MESSAGE);
            HoAWriteCardTip(data, owned.card->id, Localize(BONK_FIELD_CARD_NAME, owned.card->id, owned.card->name),
                DescribeHeldCard(*owned.card, owned.copies, GetLocale()));
            m_player->GetSession()->SendPacket(&data);
        }
    SendCardCooldowns();
    SendCardStatus(true);
}

void BonkRun::StartCardCooldown(BonkCardEffect effect, uint32 ms)
{
    m_cardCooldowns[effect] = int32(ms);
    m_cardCooldownTotals[effect] = ms;
    SendCardCooldown(effect);
}

void BonkRun::SendCardCooldown(BonkCardEffect effect) const
{
    BonkCard const* card = m_cardByEffect[effect];
    if (!card)
        return;
    if (!m_player->GetBonkPlayer()->IsAddonReady())
        return;
    WorldPacket data(SMSG_HOA_MESSAGE);
    HoAWriteCardCooldown(data, card->id, std::max(0, m_cardCooldowns[effect]), m_cardCooldownTotals[effect]);
    m_player->GetSession()->SendPacket(&data);
}

void BonkRun::SendCardCooldowns() const
{
    for (uint8 effect = 0; effect < MAX_BONK_CARD_EFFECT; ++effect)
        if (m_cardByEffect[effect] && m_cardCooldowns[effect] > 0)
            SendCardCooldown(BonkCardEffect(effect));
}

#include "BonkRun.h"
#include "BonkCoop.h"
#include "BonkLocale.h"
#include "BonkMobAI.h"
#include "BonkPlayer.h"
#include "Chat.h"
#include "Creature.h"
#include "GameObject.h"
#include "HoaProtocol.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Utilities/Random.h"
#include "WorldSession.h"

#include <algorithm>
#include <cstdio>
#include <cstring>
#include <functional>

namespace
{
    uint32 const BONK_GO_SHRINE            = 900030;
    uint32 const BONK_SHRINE_MODEL_SEC     = 3600;
    uint32 const BONK_SHRINE_PLACE_MS      = 2000;
    float const BONK_SHRINE_MIN_DISTANCE   = 60.0f;
    float const BONK_SHRINE_MAX_DISTANCE   = 400.0f;
    float const BONK_SHRINE_SPREAD         = 150.0f;
    uint32 const BONK_SHRINE_FIRST_SEC     = 20;
    uint32 const BONK_SHRINE_LAST_BEFORE_BOSS_SEC = 60;
    uint32 const BONK_SHRINE_ENDLESS_MIN_SEC = 90;
    uint32 const BONK_SHRINE_ENDLESS_MAX_SEC = 180;

    struct ShrineCount
    {
        uint32 least;
        uint32 extra;
    };
    ShrineCount const BONK_SHRINE_COUNT[MAX_BONK_MAP_TYPE] = { { 4, 2 }, { 3, 1 }, { 1, 1 } };
    uint32 const BONK_SHRINE_WEIGHTS[MAX_BONK_SHRINE] = { 35, 30, 20, 15, 0 };
    uint32 const BONK_MAX_LEY_LINES = 2;

    float const BONK_LEY_RADIUS            = 7.0f;
    char const* const BONK_LEY_LINE_TEXTURE = "World\\Goober\\RuneGroundBlue01.blp";

    std::string GetShrineMarkKey(uint32 markKey)
    {
        return "shrine" + std::to_string(markKey);
    }

    uint32 const BONK_LEY_CAPTURE_MS       = 8000;
    uint32 const BONK_LEY_SEND_MS          = 250;
    uint32 const BONK_LEY_CHOICES          = 3;
    float const BONK_LEY_CARD_CHANCE       = 35.0f;

    float const BONK_GREED_REWARD          = 5.0f;
    float const BONK_GREED_CROWD           = 5.0f;

    uint32 const BONK_ALTAR_PACK           = 3;
    uint32 const BONK_ALTAR_AFFIXES        = 2;
    uint32 const BONK_ALTAR_CHEST_CHOICES  = 5;
    float const BONK_ALTAR_PACK_SPREAD     = 6.0f;
    int32 const BONK_SUMMON_DELAY_MS       = 3000;
    int32 const BONK_SUMMON_GLOW_MS        = 1000;
    uint32 const BONK_KIT_SUMMON_CIRCLE    = 1485;
    uint32 const BONK_SPELL_SUMMON_SMOKE   = 10389;

    float const BONK_MOONWELL_RADIUS       = 10.0f;
    uint32 const BONK_MOONWELL_SECONDS     = 10;
    float const BONK_MOONWELL_HEAL         = 0.08f;

    float const BONK_STONE_BOSS_DISTANCE   = 8.0f;

    char const* const SHRINE_NAMES[MAX_BONK_SHRINE] = { "leyline", "greed", "altar", "moonwell", "stone" };
    BonkString const SHRINE_LABELS[MAX_BONK_SHRINE] = { BONK_STRING_SHRINE_LEY_LINE, BONK_STRING_SHRINE_GREED_TOTEM, BONK_STRING_SHRINE_CHALLENGE_ALTAR,
        BONK_STRING_SHRINE_MOONWELL, BONK_STRING_SHRINE_SUMMONING_STONE };
    char const* const SHRINE_ICONS[MAX_BONK_SHRINE] = {
        "Spell_Arcane_StarFire", "INV_Misc_Coin_02", "Ability_Warrior_Challange", "Spell_Arcane_TeleportMoonglade", "Spell_Shadow_Twilight" };
    BonkString const SHRINE_DESCRIPTIONS[MAX_BONK_SHRINE] = { BONK_STRING_SHRINE_LEY_LINE_TEXT, BONK_STRING_SHRINE_GREED_TOTEM_TEXT,
        BONK_STRING_SHRINE_CHALLENGE_ALTAR_TEXT, BONK_STRING_SHRINE_MOONWELL_TEXT, BONK_STRING_SHRINE_SUMMONING_STONE_TEXT };

    void SendCapture(BonkPlayer* bonk, int32 percent)
    {
        if (!bonk->IsAddonReady())
            return;
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteCapture(data, bonk->GetString(SHRINE_LABELS[BONK_SHRINE_LEY_LINE]), percent);
        bonk->GetPlayer()->GetSession()->SendPacket(&data);
    }

    void SendMoonwell(BonkPlayer* bonk, uint32 seconds, bool inside, uint32 total)
    {
        if (!bonk->IsAddonReady())
            return;
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteMoonwell(data, seconds, inside, total);
        bonk->GetPlayer()->GetSession()->SendPacket(&data);
    }

    void SendLeyBless(BonkPlayer* bonk, std::string const& name, std::string const& icon, std::string const& text)
    {
        if (!bonk->IsAddonReady())
            return;
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteLeyBless(data, name, icon, text);
        bonk->GetPlayer()->GetSession()->SendPacket(&data);
    }

    struct LeyStat
    {
        BonkPassiveEffect effect;
        float value;
        BonkString name;
        BonkString phrase;
        char const* icon;
        bool points;
    };
    LeyStat const LEY_STATS[] = {
        { BONK_PASSIVE_POWER,       15.0f, BONK_STRING_STAT_POWER,          BONK_STRING_STAT_POWER,           "Spell_Nature_Strength",      false },
        { BONK_PASSIVE_MAX_HEALTH,  15.0f, BONK_STRING_LEY_MAX_HEALTH,      BONK_STRING_LEY_MAX_HEALTH_TEXT,  "Spell_Holy_WordFortitude",   false },
        { BONK_PASSIVE_ARMOR,       10.0f, BONK_STRING_STAT_ARMOR,          BONK_STRING_STAT_ARMOR,           "Spell_Holy_DevotionAura",    true },
        { BONK_PASSIVE_DODGE,        6.0f, BONK_STRING_LEY_DODGE,           BONK_STRING_LEY_DODGE_TEXT,       "Spell_Shadow_ShadowWard",    false },
        { BONK_PASSIVE_CRIT,         8.0f, BONK_STRING_LEY_CRIT,            BONK_STRING_LEY_CRIT_TEXT,        "Ability_CriticalStrike",     false },
        { BONK_PASSIVE_CRIT_DAMAGE, 25.0f, BONK_STRING_LEY_CRIT_DAMAGE,     BONK_STRING_LEY_CRIT_DAMAGE_TEXT, "Spell_Holy_PowerInfusion",   false },
        { BONK_PASSIVE_SHIELD,      15.0f, BONK_STRING_STAT_SHIELD,         BONK_STRING_LEY_SHIELD_TEXT,      "Spell_Holy_InnerFire",       false },
        { BONK_PASSIVE_HASTE,       10.0f, BONK_STRING_STAT_HASTE,          BONK_STRING_STAT_HASTE,           "Racial_Troll_Berserk",       false },
        { BONK_PASSIVE_AREA,        20.0f, BONK_STRING_STAT_AREA,           BONK_STRING_LEY_AREA_TEXT,        "Spell_Holy_ArcaneIntellect", false },
        { BONK_PASSIVE_MOVE_SPEED,  10.0f, BONK_STRING_STAT_MOVEMENT_SPEED, BONK_STRING_LEY_MOVE_SPEED_TEXT,  "Ability_Mount_JungleTiger",  false },
        { BONK_PASSIVE_PICKUP,      40.0f, BONK_STRING_STAT_PICKUP_RANGE,   BONK_STRING_LEY_PICKUP_TEXT,      "INV_Gizmo_02",               false },
        { BONK_PASSIVE_LUCK,        10.0f, BONK_STRING_STAT_LUCK,           BONK_STRING_STAT_LUCK,            "INV_Misc_Foot_Kodo",         true },
    };
    float const LEY_RARITY_SCALE[] = { 1.0f, 1.3f, 1.6f, 2.0f };

    LeyStat const* GetLeyStat(BonkPassiveEffect effect)
    {
        for (LeyStat const& stat : LEY_STATS)
            if (stat.effect == effect)
                return &stat;
        return nullptr;
    }

    std::string FormatLeyValue(LeyStat const& stat, float value, LocaleConstant locale)
    {
        char number[32];
        std::snprintf(number, sizeof(number), "%.0f", value);
        return sBonkLocale.GetString(stat.points ? BONK_STRING_LEY_VALUE_POINTS : BONK_STRING_LEY_VALUE_PERCENT, locale,
            { number, sBonkLocale.GetString(stat.phrase, locale) });
    }

    std::string LeyStatIcon(LeyStat const& stat)
    {
        for (auto const& itr : sBonkMgr.GetPassives())
            if (itr.second.effect == stat.effect && !itr.second.icon.empty())
                return itr.second.icon;
        return stat.icon;
    }

    float DistanceSq(float x1, float y1, float x2, float y2)
    {
        return (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2);
    }
}

char const* GetBonkShrineName(BonkShrineType type)
{
    return type < MAX_BONK_SHRINE ? SHRINE_NAMES[type] : "";
}

bool ParseBonkShrine(char const* name, BonkShrineType& type)
{
    for (uint8 i = 0; i < MAX_BONK_SHRINE; ++i)
        if (!strcmp(name, SHRINE_NAMES[i]))
        {
            type = BonkShrineType(i);
            return true;
        }
    return false;
}

void BonkRun::UpdateShrines(uint32 diff)
{
    m_shrineTimer += diff;
    if (m_shrineTimer >= BONK_SHRINE_PLACE_MS)
    {
        m_shrineTimer = 0;
        PlaceDueShrine();
    }

    UpdatePendingSummons(diff);

    if (m_missedBoss)
        return;

    for (size_t i = 0; i < m_shrines.size(); )
    {
        size_t const count = m_shrines.size();
        switch (m_shrines[i].type)
        {
            case BONK_SHRINE_LEY_LINE: UpdateLeyLine(i, diff); break;
            case BONK_SHRINE_MOONWELL: UpdateMoonwell(i, diff); break;
            case BONK_SHRINE_ALTAR:    UpdateAltar(i); break;
            default: break;
        }
        if (m_shrines.size() == count)
            ++i;
    }
}

void BonkRun::PlaceDueShrine()
{
    if (m_placeStone && !m_stonePlaced)
    {
        PlaceShrine(BONK_SHRINE_STONE);
        return;
    }
    if (IsFinale() && m_shrineDueMs.empty())
        m_shrineDueMs.push_back(m_elapsedMs + urand(BONK_SHRINE_ENDLESS_MIN_SEC, BONK_SHRINE_ENDLESS_MAX_SEC) * IN_MILLISECONDS);
    if (!m_shrineDueMs.empty() && m_elapsedMs >= m_shrineDueMs.back() && PlaceShrine(PickShrineType()))
        m_shrineDueMs.pop_back();
}

BonkShrineType BonkRun::PickShrineType() const
{
    auto const allowed = [this](uint8 type)
    {
        return type != BONK_SHRINE_STONE && (type != BONK_SHRINE_MOONWELL || !m_moonwellPlaced) &&
            (type != BONK_SHRINE_LEY_LINE || m_leyLinesPlaced < BONK_MAX_LEY_LINES);
    };
    uint32 total = 0;
    for (uint8 i = 0; i < MAX_BONK_SHRINE; ++i)
        if (allowed(i))
            total += BONK_SHRINE_WEIGHTS[i];

    uint32 roll = urand(1, total);
    for (uint8 i = 0; i < MAX_BONK_SHRINE; ++i)
    {
        if (!allowed(i))
            continue;
        if (roll <= BONK_SHRINE_WEIGHTS[i])
            return BonkShrineType(i);
        roll -= BONK_SHRINE_WEIGHTS[i];
    }
    return BONK_SHRINE_GREED;
}

bool BonkRun::PlaceShrine(BonkShrineType type)
{
    if ((type == BONK_SHRINE_MOONWELL && m_moonwellPlaced) || (type == BONK_SHRINE_STONE && m_stonePlaced) ||
        (type == BONK_SHRINE_LEY_LINE && m_leyLinesPlaced >= BONK_MAX_LEY_LINES))
        return false;

    Shrine shrine;
    shrine.type = type;
    auto const apart = [this](BonkSpot const& spot)
    {
        for (Shrine const& other : m_shrines)
            if (DistanceSq(spot.x, spot.y, other.spot.x, other.spot.y) < BONK_SHRINE_SPREAD * BONK_SHRINE_SPREAD)
                return false;
        return true;
    };
    if (!m_spawnPoints.Take(m_player, BONK_SHRINE_MIN_DISTANCE, BONK_SHRINE_MAX_DISTANCE, shrine.spot, apart))
        return false;

    BonkSpot const& spot = shrine.spot;
    if (type == BONK_SHRINE_LEY_LINE)
    {
        shrine.markKey = NextBonkAuraKey();
        SendBonkMark(m_player, GetShrineMarkKey(shrine.markKey), BONK_TELEGRAPH_CIRCLE, spot.x, spot.y, spot.z, frand(0.0f, 2.0f * M_PI_F), BONK_LEY_RADIUS, 0,
            true, BONK_TELEGRAPH_STYLE_ARCANE, ObjectGuid(), BONK_LEY_LINE_TEXTURE);
    }
    else if (GameObject* model = m_player->SummonGameObject(BONK_GO_SHRINE + type, spot.x, spot.y, spot.z, frand(0.0f, 2.0f * M_PI_F),
        0.0f, 0.0f, 0.0f, 0.0f, BONK_SHRINE_MODEL_SEC, false))
        shrine.model = model->GetObjectGuid();
    shrine.objectiveId = m_objectives.Add(m_player, BONK_OBJECTIVE_SHRINE, spot.x, spot.y, spot.z, GetString(SHRINE_LABELS[type]), 0, SHRINE_ICONS[type],
        GetString(SHRINE_DESCRIPTIONS[type]));
    if (type == BONK_SHRINE_MOONWELL)
        m_moonwellPlaced = true;
    if (type == BONK_SHRINE_STONE)
        m_stonePlaced = true;
    if (type == BONK_SHRINE_LEY_LINE)
        ++m_leyLinesPlaced;
    m_shrines.push_back(shrine);
    return true;
}

void BonkRun::RemoveShrine(size_t index)
{
    Shrine const& shrine = m_shrines[index];
    if (shrine.markKey)
        SendBonkUnmark(m_player, GetShrineMarkKey(shrine.markKey));
    if (Map* map = m_player->FindMap())
        if (GameObject* model = map->GetGameObject(shrine.model))
            model->Delete();
    RemoveObjective(shrine.objectiveId);
    m_shrines.erase(m_shrines.begin() + index);
}

void BonkRun::UpdateLeyLine(size_t index, uint32 diff)
{
    Shrine& shrine = m_shrines[index];
    bool const inside = DistanceSq(m_player->GetPositionX(), m_player->GetPositionY(), shrine.spot.x, shrine.spot.y) <=
        BONK_LEY_RADIUS * BONK_LEY_RADIUS;
    BonkPlayer* bonk = m_player->GetBonkPlayer();
    if (!inside)
    {
        if (m_captureShown && shrine.progressMs)
        {
            SendCapture(bonk, -1);
            m_captureShown = false;
        }
        return;
    }

    uint32 const captureMs = uint32(BONK_LEY_CAPTURE_MS / (1.0f + (GetUtility(BONK_UTILITY_SHRINE_SPEED) + GetGlyphValue(BONK_GLYPH_LEY_LINE, 0)) / 100.0f));
    shrine.progressMs += diff;
    m_captureSendMs += diff;
    if (shrine.progressMs >= captureMs)
    {
        SendCapture(bonk, 100);
        SendCapture(bonk, -1);
        m_captureShown = false;
        bonk->Notify(BONK_STRING_YOU_CAPTURED_LEY_LINE);
        RemoveShrine(index);
        ++m_pendingLeyOffers;
        return;
    }
    if (!m_captureShown || m_captureSendMs >= BONK_LEY_SEND_MS)
    {
        m_captureSendMs = 0;
        m_captureShown = true;
        SendCapture(bonk, int32(shrine.progressMs * 100 / captureMs));
    }
}

void BonkRun::OfferLeyBuffs()
{
    --m_pendingLeyOffers;

    std::vector<LeyStat const*> pool;
    for (LeyStat const& stat : LEY_STATS)
    {
        if (IsStatCapped(stat.effect))
            continue;
        pool.push_back(&stat);
    }

    float const luck = std::max(0.0f, GetPassiveTotal(BONK_PASSIVE_LUCK));
    float const epic = 4.0f + 0.2f * luck;
    float const rare = epic + 12.0f + 0.4f * luck;
    float const uncommon = rare + 30.0f + 0.4f * luck;

    m_leyOffer.clear();
    uint32 const choices = BONK_LEY_CHOICES + uint32(GetGlyphValue(BONK_GLYPH_LEY_LINE, 1));
    for (uint32 i = 0; i < choices && !pool.empty(); ++i)
    {
        size_t const pick = urand(0, uint32(pool.size()) - 1);
        LeyStat const* stat = pool[pick];
        pool.erase(pool.begin() + pick);

        float const roll = frand(0.0f, 100.0f);
        LeyBuff buff;
        buff.effect = stat->effect;
        buff.rarity = roll < epic ? BONK_RARITY_EPIC : roll < rare ? BONK_RARITY_RARE : roll < uncommon ? BONK_RARITY_UNCOMMON : BONK_RARITY_COMMON;
        buff.value = stat->value * LEY_RARITY_SCALE[buff.rarity] * GetCopyWeight(m_shrinePicks[stat->effect] + 1);
        m_leyOffer.push_back(buff);
    }
    if (m_leyOffer.empty())
        return;

    if (roll_chance_f(BONK_LEY_CARD_CHANCE) && !sBonkMgr.GetCards().empty())
    {
        std::vector<Offer> const none;
        std::vector<Offer> drawn;
        if (OfferCards(1, nullptr, &none, &drawn) && !drawn.empty())
        {
            LeyBuff card;
            card.cardId = drawn.front().id;
            card.rarity = drawn.front().rarity;
            m_leyOffer.back() = card;
        }
    }

    SetPaused(true);
    SendLeyOffer();
}

void BonkRun::SendLeyOffer() const
{
    BonkPlayer* bonk = m_player->GetBonkPlayer();
    if (bonk->IsAddonReady())
    {
        WorldPacket open(SMSG_HOA_MESSAGE);
        HoAWriteLeyOpen(open, m_leyOffer.size());
        m_player->GetSession()->SendPacket(&open);
        for (size_t i = 0; i < m_leyOffer.size(); ++i)
        {
            LeyBuff const& buff = m_leyOffer[i];
            if (buff.cardId)
            {
                if (BonkCard const* card = sBonkMgr.GetCard(buff.cardId))
                {
                    WorldPacket option(SMSG_HOA_MESSAGE);
                    HoAWriteLeyOption(option, i + 1, Localize(BONK_FIELD_CARD_NAME, card->id, card->name), card->icon,
                        Localize(BONK_FIELD_CARD_DESCRIPTION, card->id, card->description), buff.rarity, "c",
                        GetCardCopies(card->id) + 1, card->maxCopies);
                    m_player->GetSession()->SendPacket(&option);
                }
                continue;
            }
            LeyStat const* stat = GetLeyStat(buff.effect);
            if (!stat)
                continue;
            WorldPacket option(SMSG_HOA_MESSAGE);
            HoAWriteLeyOption(option, i + 1, GetString(stat->name), LeyStatIcon(*stat),
                GetString(BONK_STRING_LEY_FOR_THE_RUN, { FormatLeyValue(*stat, buff.value, GetLocale()) }), buff.rarity, "",
                0, 0);
            m_player->GetSession()->SendPacket(&option);
        }
        WorldPacket end(SMSG_HOA_MESSAGE);
        HoAWriteLeyEnd(end);
        m_player->GetSession()->SendPacket(&end);
        return;
    }

    ChatHandler handler(m_player);
    handler.SendSysMessage(GetString(BONK_STRING_LEY_OFFER_CHAT).c_str());
    for (size_t i = 0; i < m_leyOffer.size(); ++i)
    {
        if (m_leyOffer[i].cardId)
        {
            if (BonkCard const* card = sBonkMgr.GetCard(m_leyOffer[i].cardId))
                handler.PSendSysMessage("%u. %s: %s", uint32(i + 1), Localize(BONK_FIELD_CARD_NAME, card->id, card->name).c_str(),
                    Localize(BONK_FIELD_CARD_DESCRIPTION, card->id, card->description).c_str());
        }
        else if (LeyStat const* stat = GetLeyStat(m_leyOffer[i].effect))
            handler.PSendSysMessage("%u. %s", uint32(i + 1), FormatLeyValue(*stat, m_leyOffer[i].value, GetLocale()).c_str());
    }
}

void BonkRun::SendLeyBlessings() const
{
    BonkPlayer* bonk = m_player->GetBonkPlayer();
    if (!bonk->IsAddonReady())
        return;
    WorldPacket start(SMSG_HOA_MESSAGE);
    HoAWriteLeyBlessings(start);
    m_player->GetSession()->SendPacket(&start);
    for (uint8 effect = 0; effect < MAX_BONK_PASSIVE_EFFECT; ++effect)
    {
        LeyStat const* stat = GetLeyStat(BonkPassiveEffect(effect));
        if (stat && m_shrineBonuses[effect] > 0.0f)
            SendLeyBless(bonk, GetString(stat->name), LeyStatIcon(*stat), FormatLeyValue(*stat, m_shrineBonuses[effect], GetLocale()));
    }
    WorldPacket end(SMSG_HOA_MESSAGE);
    HoAWriteLeyBlessEnd(end);
    m_player->GetSession()->SendPacket(&end);
}

bool BonkRun::PickLeyBuff(uint32 index, std::string& error)
{
    if (m_leyOffer.empty())
    {
        error = GetString(BONK_STRING_THERE_IS_NO_LEY_LINE);
        return false;
    }
    if (!index || index > m_leyOffer.size())
    {
        error = GetString(BONK_STRING_CHOOSE_NUMBER_FROM_1_TO, { std::to_string(m_leyOffer.size()) });
        return false;
    }

    LeyBuff const buff = m_leyOffer[index - 1];
    m_leyOffer.clear();
    BonkPlayer* bonk = m_player->GetBonkPlayer();
    if (bonk->IsAddonReady())
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteLeyClosed(data);
        m_player->GetSession()->SendPacket(&data);
    }
    if (buff.cardId)
    {
        if (BonkCard const* card = sBonkMgr.GetCard(buff.cardId))
        {
            AddCard(*card);
            bonk->Notify(BONK_STRING_LEY_LINE_GRANTS_YOU, { Localize(BONK_FIELD_CARD_NAME, card->id, card->name) });
        }
    }
    else
    {
        m_shrineBonuses[buff.effect] += buff.value;
        ++m_shrinePicks[buff.effect];
        ApplyPassives();
        if (LeyStat const* stat = GetLeyStat(buff.effect))
            bonk->Notify(BONK_STRING_LEY_LINE_GRANTS_YOU, { FormatLeyValue(*stat, buff.value, GetLocale()) });
        SendLeyBlessings();
    }
    ResumeUnlessChoiceOpen();
    SendState();
    return true;
}

uint32 BonkRun::GetGreedRewardPercent() const
{
    return uint32(BONK_GREED_REWARD * m_greedStacks);
}

float BonkRun::GetGreedCrowdPercent() const
{
    return BONK_GREED_CROWD * m_greedStacks * (m_greedStacks + 1) / 2.0f;
}

void BonkRun::SendGreed() const
{
    if (!m_player->GetBonkPlayer()->IsAddonReady())
        return;
    WorldPacket data(SMSG_HOA_MESSAGE);
    HoAWriteGreed(data, m_greedStacks, GetGreedRewardPercent(), uint32(GetGreedCrowdPercent() + 0.5f));
    m_player->GetSession()->SendPacket(&data);
}

void BonkRun::UseShrine(GameObject* go)
{
    if (m_state != STATE_RUNNING || m_paused)
        return;

    if (m_missedBoss)
    {
        m_player->GetBonkPlayer()->Notify(BONK_STRING_COOP_CHESTS_CLOSED_AFTER_DOWN);
        return;
    }

    for (size_t i = 0; i < m_shrines.size(); ++i)
    {
        Shrine& shrine = m_shrines[i];
        if (shrine.model != go->GetObjectGuid())
            continue;

        BonkPlayer* bonk = m_player->GetBonkPlayer();
        switch (shrine.type)
        {
            case BONK_SHRINE_GREED:
            {
                ++m_greedStacks;
                SendGreed();
                bonk->Notify(BONK_STRING_YOU_NOW_EARN_MORE_GOLD, { std::to_string(GetGreedRewardPercent()), std::to_string(uint32(GetGreedCrowdPercent() + 0.5f)) });
                RemoveShrine(i);
                break;
            }
            case BONK_SHRINE_ALTAR:
            {
                if (shrine.active)
                    break;
                shrine.active = true;
                for (uint32 n = 0; n < BONK_ALTAR_PACK; ++n)
                {
                    BonkMapCreature const* creature = PickCreature(BONK_SPAWN_ELITE);
                    if (!creature)
                        break;
                    float const angle = 2.0f * M_PI_F * n / BONK_ALTAR_PACK;
                    float x = shrine.spot.x + BONK_ALTAR_PACK_SPREAD * std::cos(angle);
                    float y = shrine.spot.y + BONK_ALTAR_PACK_SPREAD * std::sin(angle);
                    float z = m_player->GetMap()->GetHeight(x, y, shrine.spot.z + 5.0f, true, 15.0f);
                    if (z <= INVALID_HEIGHT)
                    {
                        x = shrine.spot.x;
                        y = shrine.spot.y;
                        z = shrine.spot.z;
                    }
                    QueueSummon(creature, x, y, z, BONK_ALTAR_AFFIXES, shrine.model, false, n == 0);
                }
                break;
            }
            case BONK_SHRINE_MOONWELL:
            {
                if (shrine.active)
                    break;
                shrine.active = true;
                shrine.leftMs = GetMoonwellSeconds() * IN_MILLISECONDS;
                shrine.tickMs = IN_MILLISECONDS;
                bonk->Notify(BONK_STRING_MOONWELLS_WATERS_STIR_STAND_IN);
                break;
            }
            case BONK_SHRINE_STONE:
            {
                BonkRun* summoner = this;
                if (IsCoopGuest())
                {
                    Player* host = ObjectAccessor::FindPlayerNotInWorld(m_coopHost);
                    summoner = host && host->GetMap() == m_player->GetMap() ? host->GetBonkPlayer()->GetRun() : nullptr;
                }
                if (summoner && summoner->SummonBossAtStone(shrine.spot, m_player))
                    RemoveShrine(i);
                break;
            }
            default:
                break;
        }
        return;
    }
}

std::vector<Player*> BonkRun::NoticeGroup(bool wholeGroup) const
{
    return wholeGroup ? BonkCoop::RunGroupOf(m_player) : std::vector<Player*>{ m_player };
}

bool BonkRun::SummonBossAtStone(BonkSpot const& stone, Player* user)
{
    if (m_state != STATE_RUNNING)
        return false;
    if (m_bossSpawned)
    {
        user->GetBonkPlayer()->Notify(BONK_STRING_BOSS_IS_ALREADY_HERE);
        return false;
    }
    BonkMapCreature const* creature = PickCreature(BONK_SPAWN_BOSS);
    if (!creature)
        return false;
    float const angle = std::atan2(user->GetPositionY() - stone.y, user->GetPositionX() - stone.x) + M_PI_F;
    float x = stone.x + BONK_STONE_BOSS_DISTANCE * std::cos(angle);
    float y = stone.y + BONK_STONE_BOSS_DISTANCE * std::sin(angle);
    float z = m_player->GetMap()->GetHeight(x, y, stone.z + 5.0f, true, 15.0f);
    if (z <= INVALID_HEIGHT)
    {
        x = stone.x;
        y = stone.y;
        z = stone.z;
    }
    QueueSummon(creature, x, y, z, 0, ObjectGuid(), true, true);
    return true;
}

void BonkRun::QueueSummon(BonkMapCreature const* creature, float x, float y, float z, uint32 affixes, ObjectGuid const& altar, bool boss,
    bool countdown)
{
    PendingSummon summon;
    summon.creature = creature;
    summon.x = x;
    summon.y = y;
    summon.z = z;
    summon.affixes = affixes;
    summon.altar = altar;
    summon.boss = boss;
    summon.leftMs = BONK_SUMMON_DELAY_MS;
    summon.countdown = countdown;
    m_pendingSummons.push_back(summon);
}

bool BonkRun::IsAltarWaking(ObjectGuid const& altar) const
{
    return std::any_of(m_pendingSummons.begin(), m_pendingSummons.end(), [&altar](PendingSummon const& summon) { return summon.altar == altar; });
}

void BonkRun::UpdatePendingSummons(uint32 diff)
{
    std::vector<PendingSummon> ready;
    BonkPlayer* bonk = m_player->GetBonkPlayer();
    for (auto itr = m_pendingSummons.begin(); itr != m_pendingSummons.end();)
    {
        itr->glowMs -= int32(diff);
        if (itr->glowMs <= 0 && itr->leftMs > 0)
        {
            itr->glowMs = BONK_SUMMON_GLOW_MS;
            PlayKitAt(ObjectGuid(), itr->x, itr->y, itr->z, BONK_KIT_SUMMON_CIRCLE, true);
            int32 const seconds = (itr->leftMs + IN_MILLISECONDS - 1) / IN_MILLISECONDS;
            if (itr->countdown)
                for (Player* member : NoticeGroup(itr->boss))
                    member->GetBonkPlayer()->Notify(itr->boss ? BONK_STRING_SUMMONS_ANSWERED_ARRIVES_IN : BONK_STRING_ALTAR_GUARDIANS_ARRIVE_IN,
                        { member->GetBonkPlayer()->GetString(seconds == 1 ? BONK_STRING_DURATION_SECOND : BONK_STRING_DURATION_SECONDS, { std::to_string(seconds) }) });
        }
        itr->leftMs -= int32(diff);
        if (itr->leftMs > 0)
        {
            ++itr;
            continue;
        }
        ready.push_back(*itr);
        itr = m_pendingSummons.erase(itr);
    }

    for (PendingSummon const& summon : ready)
    {
        BonkMobAI::SetNextAffixCount(summon.affixes);
        if (summon.boss)
            m_scalingMinuteOverride = std::max(GetRunMinutes(), m_map.durationSeconds / 60.0f);
        Creature* mob = SpawnMobAt(*summon.creature, summon.x, summon.y, summon.z);
        m_scalingMinuteOverride = -1.0f;
        BonkMobAI::SetNextAffixCount(0);
        if (!mob)
            continue;
        if (summon.boss)
        {
            m_bossSpawned = true;
            m_stoneBoss = true;
        }
        mob->CastSpell(mob, BONK_SPELL_SUMMON_SMOKE, true);
        if (summon.boss)
            for (Player* member : NoticeGroup(true))
                member->GetBonkPlayer()->Notify(BONK_STRING_SUMMONED_ANSWERS, { member->GetBonkPlayer()->GetLocalName(mob) });
        if (summon.altar.IsEmpty())
            continue;
        for (Shrine& shrine : m_shrines)
            if (shrine.model == summon.altar)
            {
                shrine.pack.push_back(mob->GetObjectGuid());
                if (!IsAltarWaking(summon.altar) && shrine.pack.size() == 1)
                    bonk->Notify(BONK_STRING_ALTARS_GUARDIANS_AWAKEN);
            }
    }
}

void BonkRun::UpdateAltar(size_t index)
{
    Shrine const& shrine = m_shrines[index];
    if (!shrine.active || IsAltarWaking(shrine.model))
        return;

    Map* map = m_player->GetMap();
    for (ObjectGuid const& guid : shrine.pack)
        if (Creature* mob = map->GetCreature(guid))
            if (mob->IsAlive())
                return;

    SpawnChest(true, shrine.spot.x, shrine.spot.y, shrine.spot.z, BONK_ALTAR_CHEST_CHOICES);
    m_player->GetBonkPlayer()->Notify(BONK_STRING_CHALLENGE_ALTAR_YIELDS_ITS_TREASURE);
    RemoveShrine(index);
}

void BonkRun::UpdateMoonwell(size_t index, uint32 diff)
{
    Shrine& shrine = m_shrines[index];
    bool const inside = DistanceSq(m_player->GetPositionX(), m_player->GetPositionY(), shrine.spot.x, shrine.spot.y) <=
        BONK_MOONWELL_RADIUS * BONK_MOONWELL_RADIUS;
    BonkPlayer* bonk = m_player->GetBonkPlayer();
    if (!shrine.active)
        return;

    if (shrine.leftMs <= diff)
    {
        SendMoonwell(bonk, 0, false, GetMoonwellSeconds());
        bonk->Notify(BONK_STRING_MOONWELL_RUNS_DRY);
        RemoveShrine(index);
        return;
    }
    shrine.leftMs -= diff;

    if (!inside)
    {
        if (shrine.progressMs)
        {
            shrine.progressMs = 0;
            SendMoonwell(bonk, 0, false, GetMoonwellSeconds());
        }
        return;
    }

    bool const entered = !shrine.progressMs;
    shrine.progressMs = 1;
    shrine.tickMs += diff;
    if (!entered && shrine.tickMs < IN_MILLISECONDS)
        return;
    if (shrine.tickMs >= IN_MILLISECONDS)
    {
        shrine.tickMs -= IN_MILLISECONDS;
        if (m_player->IsAlive() && m_player->GetHealth() < m_player->GetMaxHealth())
        {
            SupportScope scope(*this, { "Spell_Nature_Rejuvenation", GetString(BONK_STRING_SHRINE_MOONWELL) });
            m_player->ModifyHealth(int32(ReduceHealing(std::max(1u, uint32(m_player->GetMaxHealth() * BONK_MOONWELL_HEAL)))));
        }
    }
    SendMoonwell(bonk, (shrine.leftMs + IN_MILLISECONDS - 1) / IN_MILLISECONDS, true, GetMoonwellSeconds());
}

uint32 BonkRun::GetMoonwellSeconds() const
{
    return uint32(BONK_MOONWELL_SECONDS * (1.0f + GetUtility(BONK_UTILITY_SHRINE_SPEED) / 100.0f) + 0.5f);
}

bool BonkRun::IsInMoonwell(float x, float y) const
{
    for (Shrine const& shrine : m_shrines)
        if (shrine.type == BONK_SHRINE_MOONWELL && shrine.active &&
            DistanceSq(x, y, shrine.spot.x, shrine.spot.y) <= BONK_MOONWELL_RADIUS * BONK_MOONWELL_RADIUS)
            return true;
    return false;
}

void BonkRun::ResetShrines()
{
    DespawnShrines();
    m_shrineTimer = 0;
    m_moonwellPlaced = false;
    m_leyLinesPlaced = 0;
    m_stonePlaced = false;
    Player* host = IsCoopGuest() ? ObjectAccessor::FindPlayerNotInWorld(m_coopHost) : nullptr;
    m_placeStone = m_stage < m_tier.stages || m_difficultyLevel <= (host ? host : m_player)->GetBonkPlayer()->GetCarriedLevel();
    if (IsFinale())
        return;

    ShrineCount const& count = BONK_SHRINE_COUNT[m_map.type < MAX_BONK_MAP_TYPE ? m_map.type : BONK_MAP_OPEN];
    uint32 shrines = count.least + urand(0, count.extra);
    if (m_placeStone && shrines > 1)
        --shrines;
    uint32 const firstSec = BONK_SHRINE_FIRST_SEC;
    uint32 const lastSec = std::max(firstSec, m_map.durationSeconds > BONK_SHRINE_LAST_BEFORE_BOSS_SEC ? m_map.durationSeconds - BONK_SHRINE_LAST_BEFORE_BOSS_SEC : 0);
    for (uint32 i = 0; i < shrines; ++i)
        m_shrineDueMs.push_back(m_elapsedMs + urand(firstSec, lastSec) * IN_MILLISECONDS);
    std::sort(m_shrineDueMs.begin(), m_shrineDueMs.end(), std::greater<uint32>());
}

void BonkRun::DespawnShrines()
{
    Map* map = m_player->FindMap();
    for (Shrine const& shrine : m_shrines)
    {
        if (shrine.markKey)
            SendBonkUnmark(m_player, GetShrineMarkKey(shrine.markKey));
        if (map)
            if (GameObject* model = map->GetGameObject(shrine.model))
                model->Delete();
        RemoveObjective(shrine.objectiveId);
    }
    m_shrines.clear();
    m_pendingSummons.clear();
    m_shrineDueMs.clear();
    m_placeStone = false;
    if (m_captureShown)
    {
        SendCapture(m_player->GetBonkPlayer(), -1);
        m_captureShown = false;
    }
}

bool BonkRun::PlaceShrineNow(BonkShrineType type, std::string& error)
{
    if (m_state != STATE_RUNNING)
    {
        error = GetString(BONK_STRING_ONLY_RUNNING_STAGE_SHRINE);
        return false;
    }
    if ((type == BONK_SHRINE_MOONWELL && m_moonwellPlaced) || (type == BONK_SHRINE_STONE && m_stonePlaced))
    {
        error = GetString(BONK_STRING_STAGE_ALREADY_HAD_SHRINE, { GetString(SHRINE_LABELS[type]) });
        return false;
    }
    if (type == BONK_SHRINE_LEY_LINE && m_leyLinesPlaced >= BONK_MAX_LEY_LINES)
    {
        error = GetString(BONK_STRING_STAGE_ALREADY_HAD_LEY_LINES, { std::to_string(BONK_MAX_LEY_LINES) });
        return false;
    }
    if (!PlaceShrine(type))
    {
        error = GetString(BONK_STRING_NO_SHRINE_SPAWN_POINT);
        return false;
    }
    return true;
}

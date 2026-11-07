#include "BonkRun.h"
#include "BonkLocale.h"
#include "BonkMobAI.h"
#include "BonkPlayer.h"
#include "BonkQuests.h"
#include "Creature.h"
#include "GameObject.h"
#include "Map.h"
#include "Player.h"
#include "Utilities/Random.h"

namespace
{
    float const BONK_HIDDEN_MIN_DISTANCE  = 80.0f;
    float const BONK_HIDDEN_MAX_DISTANCE  = 180.0f;
    uint32 const BONK_HIDDEN_PLACE_MS     = 5000;
    uint32 const BONK_HIDDEN_LIFETIME_SEC = 3600;
    float const BONK_HIDDEN_NEAR          = 25.0f;
    float const BONK_HIDDEN_BAND_MIN      = 4.0f;
    float const BONK_HIDDEN_BAND_MAX      = 9.0f;
    uint32 const BONK_SPELL_HIDDEN_SPARKLE = 33455;
    float const BONK_HIDDEN_SPARKLE_SCALE = 1.5f;
}

void BonkRun::RollHidden()
{
    m_hidden = HiddenEncounter();
    std::vector<BonkHidden const*> candidates;
    for (BonkHidden const& hidden : sBonkMgr.GetHiddenEncounters())
        if (hidden.mapId == m_map.id && roll_chance_f(hidden.chance))
            candidates.push_back(&hidden);
    if (!candidates.empty())
        m_hidden.hidden = candidates[urand(0, uint32(candidates.size()) - 1)];
}

void BonkRun::UpdateHidden(uint32 diff)
{
    BonkHidden const* hidden = m_hidden.hidden;
    if (!hidden || m_hidden.triggered)
        return;

    if (!m_hidden.placed)
    {
        m_hidden.placeTimer += diff;
        if (m_hidden.placeTimer < BONK_HIDDEN_PLACE_MS)
            return;
        m_hidden.placeTimer = 0;
        if (!m_spawnPoints.Take(m_player, BONK_HIDDEN_MIN_DISTANCE, BONK_HIDDEN_MAX_DISTANCE, m_hidden.spot))
            return;
        m_hidden.placed = true;
        if (GameObject* go = PlaceObject(hidden->objectEntry, m_hidden.spot.x, m_hidden.spot.y, m_hidden.spot.z, BONK_HIDDEN_LIFETIME_SEC))
        {
            m_hidden.object = go->GetObjectGuid();
            m_hidden.sparkle = PlaceMarker(go, BONK_SPELL_HIDDEN_SPARKLE, BONK_HIDDEN_SPARKLE_SCALE);
        }
        return;
    }

    if (hidden->trigger == BONK_HIDDEN_NEAR_TRIGGER && m_player->GetDistance2d(m_hidden.spot.x, m_hidden.spot.y) <= BONK_HIDDEN_NEAR)
        TriggerHidden();
}

bool BonkRun::UseHidden(GameObject* go)
{
    if (!m_hidden.hidden || m_hidden.triggered || go->GetObjectGuid() != m_hidden.object || m_state != STATE_RUNNING)
        return false;
    TriggerHidden();
    return true;
}

void BonkRun::TriggerHidden()
{
    BonkHidden const* hidden = m_hidden.hidden;
    m_hidden.triggered = true;
    RemoveHiddenSparkle();
    BonkSpot const& spot = m_hidden.spot;

    if (hidden->trigger == BONK_HIDDEN_USE_TRIGGER)
        if (GameObject* go = m_player->GetMap()->GetGameObject(m_hidden.object))
            go->Delete();

    BonkMapCreature boss;
    boss.entry = hidden->bossEntry;
    boss.kind = BONK_SPAWN_MINIBOSS;
    boss.scale = hidden->bossScale;
    boss.speed = 0.8f;
    Creature* mob = SpawnMobAt(boss, spot.x, spot.y, spot.z);
    if (mob)
    {
        m_hidden.boss = mob->GetObjectGuid();
        if (!hidden->yell.empty())
            mob->MonsterYell(Localize(BONK_FIELD_HIDDEN_YELL, hidden->id, hidden->yell).c_str());
    }

    BonkMapCreature add;
    add.entry = hidden->addEntry;
    add.kind = BONK_SPAWN_NORMAL;
    add.archetype = BONK_ARCHETYPE_GRUNT;
    for (uint32 i = 0; add.entry && i < hidden->addCount; ++i)
    {
        float const angle = 2.0f * M_PI_F * i / float(hidden->addCount);
        float const distance = frand(BONK_HIDDEN_BAND_MIN, BONK_HIDDEN_BAND_MAX);
        float const x = spot.x + distance * std::cos(angle);
        float const y = spot.y + distance * std::sin(angle);
        float const z = m_player->GetMap()->GetHeight(x, y, spot.z + 5.0f, true, 15.0f);
        if (z > INVALID_HEIGHT)
            SpawnMobAt(add, x, y, z);
    }

    if (hidden->foundText.empty())
        m_player->GetBonkPlayer()->Notify(BONK_STRING_YOU_FOUND, { Localize(BONK_FIELD_HIDDEN_NAME, hidden->id, hidden->name) });
    else
        m_player->GetBonkPlayer()->Notify(Localize(BONK_FIELD_HIDDEN_FOUND_TEXT, hidden->id, hidden->foundText));
}

void BonkRun::OnHiddenKilled(Creature const* mob)
{
    BonkHidden const* hidden = m_hidden.hidden;
    if (!hidden || mob->GetObjectGuid() != m_hidden.boss)
        return;
    m_hidden.boss.Clear();
    sBonkQuests.OnProgress(m_player, BONK_QUEST_DISCOVER, hidden->id, 1);
    SpawnChest(true, mob->GetPositionX(), mob->GetPositionY(), mob->GetPositionZ(), hidden->chestChoices);
    m_player->GetBonkPlayer()->Notify(BONK_STRING_YOU_DEFEATED_AND_CHEST_APPEARS, { Localize(BONK_FIELD_HIDDEN_NAME, hidden->id, hidden->name) });
}

void BonkRun::RemoveHiddenSparkle()
{
    if (!m_hidden.sparkle)
        return;
    SendBonkAuraGone(m_player, m_hidden.sparkle);
    m_hidden.sparkle = 0;
}

void BonkRun::ClearHidden()
{
    RemoveHiddenSparkle();
    if (Map* map = m_player->FindMap())
        if (GameObject* go = map->GetGameObject(m_hidden.object))
            go->Delete();
    if (m_hidden.placed)
        m_spawnPoints.Release(m_hidden.spot.x, m_hidden.spot.y);
    m_hidden = HiddenEncounter();
}

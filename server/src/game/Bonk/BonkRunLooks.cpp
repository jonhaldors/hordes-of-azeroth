#include "BonkRun.h"
#include "BonkPlayer.h"
#include "BonkTelegraph.h"
#include "ObjectAccessor.h"
#include "Packets/Misc.h"
#include "Player.h"
#include "SpellMgr.h"
#include "World.h"
#include "Utilities/Random.h"

#include <ctime>

#include <algorithm>

namespace
{
    struct BonkSkyWindow
    {
        uint32 weight;
        uint32 firstMinute;
        uint32 spanMinutes;
    };

    BonkSkyWindow const BONK_SKY_WINDOWS[] =
    {
        { 25, 22 * 60, 6 * 60 },
        { 13, 19 * 60 + 30, 90 },
        { 12, 5 * 60, 90 },
        { 50, 9 * 60, 8 * 60 },
    };

    uint32 const BONK_MINUTES_PER_DAY = 24 * 60;
    float const BONK_WEATHER_CHANCE = 20.0f;
    float const BONK_WEATHER_MIN_GRADE = 0.4f;
    float const BONK_WEATHER_MAX_GRADE = 1.0f;

    struct BonkMapWeather
    {
        char const* mapKey;
        WeatherType type;
    };

    BonkMapWeather const BONK_MAP_WEATHER[] =
    {
        { "moltencore", WEATHER_TYPE_FINE },
        { "dunmorogh", WEATHER_TYPE_SNOW },
        { "tanaris", WEATHER_TYPE_STORM },
        { "badlands", WEATHER_TYPE_STORM },
        { "desolace", WEATHER_TYPE_STORM },
        { "ruinsaq", WEATHER_TYPE_STORM },
    };

    uint32 const BONK_WEATHER_SOUNDS[][3] =
    {
        { 0, 0, 0 },
        { 8533, 8534, 8535 },
        { 8536, 8537, 8538 },
        { 8556, 8557, 8558 },
    };

    WeatherType GetMapWeather(std::string const& mapKey)
    {
        for (BonkMapWeather const& entry : BONK_MAP_WEATHER)
            if (mapKey == entry.mapKey)
                return entry.type;
        return WEATHER_TYPE_RAIN;
    }

    uint32 GetWeatherSound(WeatherType type, float grade)
    {
        if (type > WEATHER_TYPE_STORM || grade < 0.3f)
            return 0;
        return BONK_WEATHER_SOUNDS[type][grade < 0.6f ? 0 : grade < 0.9f ? 1 : 2];
    }

    void SendWeather(Player* player, WeatherType type, float grade)
    {
        auto packet = std::make_unique<WorldPackets::Misc::WeatherUpdate>();
        packet->weatherType = type;
        packet->grade = grade;
        packet->soundId = GetWeatherSound(type, grade);
        packet->instantChange = true;
        player->GetSession()->SendPacket(std::move(packet));
    }

    void SendSkyTime(Player* player, time_t gameTime)
    {
        auto packet = std::make_unique<WorldPackets::Misc::LoginSetTimeSpeed>();
        packet->gameTime = uint32(gameTime);
        packet->gameSpeedMinutesPerSecond = 1.0f / 60.0f;
        player->GetSession()->SendPacket(std::move(packet));
    }

    uint32 RollSkyMinute()
    {
        uint32 total = 0;
        for (BonkSkyWindow const& window : BONK_SKY_WINDOWS)
            total += window.weight;
        uint32 roll = urand(0, total - 1);
        for (BonkSkyWindow const& window : BONK_SKY_WINDOWS)
        {
            if (roll < window.weight)
                return (window.firstMinute + urand(0, window.spanMinutes)) % BONK_MINUTES_PER_DAY;
            roll -= window.weight;
        }
        return 12 * 60;
    }

    time_t AtMinuteOfToday(uint32 minuteOfDay)
    {
        time_t const now = sWorld.GetGameTime();
        std::tm const local = *std::localtime(&now);
        time_t const midnight = now - (local.tm_hour * HOUR + local.tm_min * MINUTE + local.tm_sec);
        return midnight + time_t(minuteOfDay) * MINUTE;
    }
    uint32 const BONK_HERO_LOOK_SPELLS[] =
    {
        33447,
        33448,
        33449,
        33450,
        33451,
        33452,
        33453,
    };

    uint32 const BONK_HERO_RING_FIRST_SPELLS[] =
    {
        33402,
        33425,
        33471,
        33510,
        33540,
        33562,
        33600,
    };

    uint32 const BONK_OLD_BLOOD_AURA_LOOK = 33401;
    float const BONK_HERO_RING_STEPS_PER_YARD = 10.0f;

    static_assert(sizeof(BONK_HERO_LOOK_SPELLS) / sizeof(uint32) == size_t(BonkHeroLook::Count), "Every hero look needs a spell.");
    static_assert(sizeof(BONK_HERO_RING_FIRST_SPELLS) / sizeof(uint32) == size_t(BonkHeroRing::Count), "Every hero ring needs a first spell.");
}

void BonkRun::ShowHeroLook(BonkHeroLook look, bool shown)
{
    uint32 const spellId = BONK_HERO_LOOK_SPELLS[size_t(look)];
    shown = shown && m_player->IsAlive();
    if (shown == m_player->HasAura(spellId))
        return;
    if (!shown)
        m_player->RemoveAurasDueToSpell(spellId);
    else if (sSpellMgr.GetSpellEntry(spellId))
        m_player->CastSpell(m_player, spellId, true);
}

BonkTelegraphStyle BonkRun::GetRingStyle(BonkHeroRing ring)
{
    switch (ring)
    {
        case BonkHeroRing::BloodAura:  return BONK_TELEGRAPH_STYLE_BLOOD;
        case BonkHeroRing::IcePath:    return BONK_TELEGRAPH_STYLE_FROST;
        case BonkHeroRing::TimeBubble: return BONK_TELEGRAPH_STYLE_ARCANE;
        case BonkHeroRing::Nature:     return BONK_TELEGRAPH_STYLE_NATURE;
        default:                       return BONK_TELEGRAPH_STYLE_DANGER;
    }
}

std::string BonkRun::GetHeroRingKey(BonkHeroRing ring)
{
    return "hero" + std::to_string(uint32(ring));
}

void BonkRun::ShowHeroRing(BonkHeroRing ring, float reach, uint32 fillMs)
{
    uint32 const shown = std::max(1u, uint32(reach * BONK_HERO_RING_STEPS_PER_YARD + 0.5f));
    if (!m_player->IsAlive() || shown == m_heroRingSpells[size_t(ring)])
        return;
    m_heroRingSpells[size_t(ring)] = shown;
    SendBonkMark(m_player, GetHeroRingKey(ring), BONK_TELEGRAPH_CIRCLE, m_player->GetPositionX(), m_player->GetPositionY(),
        m_player->GetPositionZ(), 0.0f, reach, fillMs, !fillMs, GetRingStyle(ring), m_player->GetObjectGuid(), "", 0, !fillMs);
}

void BonkRun::HideHeroRing(BonkHeroRing ring)
{
    if (m_heroRingSpells[size_t(ring)])
        RemoveHeroRingAuras(ring);
}

void BonkRun::RemoveHeroRingAuras(BonkHeroRing ring)
{
    uint32 const firstSpell = BONK_HERO_RING_FIRST_SPELLS[size_t(ring)];
    for (uint32 i = 0; i < GetBonkStandInSizeCount(); ++i)
        m_player->RemoveAurasDueToSpell(firstSpell + i);
    if (m_heroRingSpells[size_t(ring)])
        SendBonkUnmark(m_player, GetHeroRingKey(ring));
    m_heroRingSpells[size_t(ring)] = 0;
}

void BonkRun::RemoveHeroLooks()
{
    for (uint32 spellId : BONK_HERO_LOOK_SPELLS)
        m_player->RemoveAurasDueToSpell(spellId);
    for (size_t ring = 0; ring < size_t(BonkHeroRing::Count); ++ring)
        RemoveHeroRingAuras(BonkHeroRing(ring));
    m_player->RemoveAurasDueToSpell(BONK_OLD_BLOOD_AURA_LOOK);
    ClearWeaponGlows();
}

uint32 BonkRun::GetSkyKey() const
{
    return m_sandbox ? 0 : m_stage * 100000 + m_map.id + 1;
}

time_t BonkRun::GetSkyTime() const
{
    uint32 const key = GetSkyKey();
    if (!key)
        return sWorld.GetGameTime();
    if (key != m_skyKey && TakeHostSky(key))
        return m_skyTime;
    if (key != m_skyKey)
    {
        m_skyKey = key;
        m_skyTime = AtMinuteOfToday(RollSkyMinute());
        bool const wet = roll_chance_f(BONK_WEATHER_CHANCE);
        m_skyWeather = wet ? uint8(GetMapWeather(m_map.key)) : uint8(WEATHER_TYPE_FINE);
        m_skyWeatherGrade = wet ? frand(BONK_WEATHER_MIN_GRADE, BONK_WEATHER_MAX_GRADE) : 0.0f;
    }
    return m_skyTime;
}

bool BonkRun::TakeHostSky(uint32 key) const
{
    if (!IsCoopGuest())
        return false;
    Player* host = ObjectAccessor::FindPlayerNotInWorld(m_coopHost);
    BonkRun const* hostRun = host ? host->GetBonkPlayer()->GetRun() : nullptr;
    if (!hostRun || hostRun->GetSkyKey() != key)
        return false;
    m_skyTime = hostRun->GetSkyTime();
    m_skyKey = key;
    m_skyWeather = hostRun->m_skyWeather;
    m_skyWeatherGrade = hostRun->m_skyWeatherGrade;
    return true;
}

void BonkRun::UpdateSky()
{
    uint32 const key = GetSkyKey();
    if (!key || key == m_skySentKey || m_player->GetMapId() != m_map.mapId || m_player->IsBeingTeleported())
        return;
    m_skySentKey = key;
    SendSkyTime(m_player, GetSkyTime());
    SendWeather(m_player, WeatherType(m_skyWeather), m_skyWeatherGrade);
}

void BonkRun::ClearSky()
{
    if (!m_skySentKey || !m_player->GetSession())
        return;
    m_skySentKey = 0;
    SendSkyTime(m_player, sWorld.GetGameTime());
    SendWeather(m_player, WEATHER_TYPE_FINE, 0.0f);
}

time_t BonkPlayer::GetSkyTime() const
{
    return m_run ? m_run->GetSkyTime() : sWorld.GetGameTime();
}

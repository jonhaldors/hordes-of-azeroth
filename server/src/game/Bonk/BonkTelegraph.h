#ifndef BONK_TELEGRAPH_H
#define BONK_TELEGRAPH_H

#include "Common.h"
#include "ObjectGuid.h"

#include <functional>
#include <string>
#include <vector>

class Map;
class Player;

enum BonkTelegraphShape : uint8
{
    BONK_TELEGRAPH_CIRCLE = 0,
    BONK_TELEGRAPH_CONE   = 1,
    BONK_TELEGRAPH_LINE   = 2,
    BONK_TELEGRAPH_RING   = 3,
    MAX_BONK_TELEGRAPH_SHAPE
};

enum BonkTelegraphStyle : uint8
{
    BONK_TELEGRAPH_STYLE_DANGER = 0,
    BONK_TELEGRAPH_STYLE_ARCANE = 1,
    BONK_TELEGRAPH_STYLE_NATURE = 2,
    BONK_TELEGRAPH_STYLE_FROST  = 3,
    BONK_TELEGRAPH_STYLE_BLOOD  = 4
};

char const* GetBonkTelegraphShapeName(BonkTelegraphShape shape);
bool ParseBonkTelegraphShape(std::string const& name, BonkTelegraphShape& shape);

bool IsInBonkTelegraph(BonkTelegraphShape shape, float originX, float originY, float orientation, float size, float x, float y);

uint32 GetBonkTelegraphLeadMs(BonkTelegraphShape shape);

float GetBonkRingInnerRadius(float size);

float GetBonkTelegraphGround(Map* map, float x, float y, float z, float reach);

uint32 GetBonkStandInSizeCount();
uint32 GetBonkStandInSizeIndex(float size);

void SendBonkKitAt(Player* player, uint32 kit, float x, float y, float z, float orientation, uint32 holdMs, bool raised = false);
void SendBonkFlight(Player* player, uint32 id, float fromX, float fromY, float fromZ, float toX, float toY, float toZ, uint32 flightMs,
    uint32 display, float scale);
void SendBonkLanding(Player* player, uint32 id);
void SendBonkMissile(Player* player, uint32 spellId, float fromX, float fromY, float fromZ, float toX, float toY, float toZ, uint32 holdMs);
void SendBonkMark(Player* player, std::string const& key, BonkTelegraphShape shape, float x, float y, float z, float orientation, float size,
    uint32 durationMs, bool outlineOnly, uint8 style, ObjectGuid const& follow = ObjectGuid(), std::string const& texture = "", uint32 doneMs = 0,
    bool groundEffect = false, uint32 opacityPercent = 100);
void SendBonkUnmark(Player* player, std::string const& key);
void SendBonkAuraAt(Player* player, uint32 key, uint32 spellId, float x, float y, float z, float scale = 1.0f);
void SendBonkAuraGone(Player* player, uint32 key);
void SendBonkProp(Player* player, uint32 key, uint32 display, float x, float y, float z, float orientation, float scale = 1.0f);
void SendBonkPropGone(Player* player, uint32 key);
uint32 NextBonkAuraKey();
uint32 NextBonkFlightId();

class BonkTelegraphs
{
    public:
        void Add(Player* owner, BonkTelegraphShape shape, float x, float y, float z, float orientation, float size, uint32 durationMs,
            std::function<void()> onFire = nullptr, bool lingers = false, ObjectGuid const& caster = ObjectGuid(), uint32 windId = 0,
            BonkTelegraphStyle style = BONK_TELEGRAPH_STYLE_DANGER);
        void Update(Player* owner, uint32 diff);
        void Clear(Player* owner);
        void CancelFrom(Player* owner, ObjectGuid const& caster, uint32 windId = 0);
        void Dismiss(Player* owner);
        size_t Count() const { return m_telegraphs.size(); }
        size_t CountStandIns() const { return m_standIns.size(); }
        size_t CountBusyStandIns() const;

        ObjectGuid Borrow(Player* owner, float x, float y, float z, uint32 display);
        void Dress(Player* owner, ObjectGuid const& guid, uint32 display);
        void Release(Player* owner, ObjectGuid const& guid);
        void Hide(Player* owner, ObjectGuid const& guid);
        void Resize(Player* owner, ObjectGuid const& guid, float stretch);

    private:
        struct Telegraph
        {
            uint32 id = 0;
            int32 leftMs = 0;
            std::function<void()> onFire;
            ObjectGuid caster;
            uint32 windId = 0;
        };

        struct StandIn
        {
            ObjectGuid guid;
            float baseScale = 1.0f;
            bool busy = true;
            uint32 goneAtMs = 0;
        };

        void TakeOff(Player* owner, Telegraph const& telegraph);
        void Tend(Player* owner);

        std::vector<Telegraph> m_telegraphs;
        std::vector<StandIn> m_standIns;
        uint32 m_clockMs = 0;
        uint32 m_nextId = 0;
        uint32 m_mapId = 0;
        uint32 m_instanceId = 0;
};

#endif

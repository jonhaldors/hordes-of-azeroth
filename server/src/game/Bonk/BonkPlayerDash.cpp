#include "BonkPlayer.h"
#include "HoaProtocol.h"
#include "BonkRun.h"
#include "BonkQuests.h"
#include "Anticheat.h"
#include "Map.h"
#include "MoveSpline.h"
#include "MovementPacketSender.h"
#include "Player.h"
#include "SpellAuras.h"
#include "WorldSession.h"
#include "Utilities/Random.h"

#include <algorithm>
#include <cmath>

namespace
{
    float const BONK_DASH_DISTANCE          = 8.0f;
    uint32 const BONK_DASH_MS               = 200;
    uint32 const BONK_DASH_INVULNERABLE_MS  = 250;
    uint32 const BONK_DASH_COOLDOWN_MS      = 10000;
    uint32 const BONK_DASH_MIN_COOLDOWN_MS  = 3000;
    uint32 const BONK_BLINK_MIN_COOLDOWN_MS = 2000;
    uint32 const BONK_DASH_CHARGES          = 1;
    uint32 const BONK_DASH_MAX_AGE_MS       = 1000;
    uint32 const BONK_KIT_BLINK_LEAVE       = 267;
    uint32 const BONK_KIT_BLINK_ARRIVE      = 3394;
}

float BonkPlayer::GetDashDistance() const
{
    return (BONK_DASH_DISTANCE + GetUpgradeUtility(BONK_UTILITY_DASH_RANGE)) * (m_run ? m_run->GetTrinketDashScale() : 1.0f);
}

uint32 BonkPlayer::GetDashCooldownMs() const
{
    int32 const cooldown = int32(BONK_DASH_COOLDOWN_MS) - int32(GetUpgradeUtility(BONK_UTILITY_DASH_COOLDOWN) * IN_MILLISECONDS);
    float const blinkRate = m_run ? m_run->GetDashRechargeRate() * m_run->GetGlyphDashRecharge() : 1.0f;
    uint32 const floor = m_run && m_run->IsBlinkDash() ? BONK_BLINK_MIN_COOLDOWN_MS : BONK_DASH_MIN_COOLDOWN_MS;
    return uint32(std::max(int32(cooldown / blinkRate), int32(floor)));
}

uint32 BonkPlayer::GetDashMaxCharges() const
{
    uint32 const blinkCharges = m_run ? m_run->GetBlinkCharges() + m_run->GetGlyphDashCharges() : 0;
    return BONK_DASH_CHARGES + uint32(GetUpgradeUtility(BONK_UTILITY_DASH_CHARGES)) + blinkCharges;
}

float BonkPlayer::GetDashSpeed() const
{
    return GetDashDistance() * IN_MILLISECONDS / BONK_DASH_MS;
}

bool BonkPlayer::IsDashPaused() const
{
    return m_run && m_run->IsPaused();
}

bool BonkPlayer::Dash()
{
    if (m_run && ((!m_run->IsActive() && !m_run->IsPortalOpen()) || m_run->IsPaused()))
        return false;
    if (m_dashSpent >= GetDashMaxCharges())
        return false;
    if (!m_player->IsInWorld() || !m_player->IsAlive() || m_player->IsBeingTeleported() || m_player->IsTaxiFlying())
        return false;
    if (m_player->HasUnitState(UNIT_STATE_STUNNED | UNIT_STATE_ROOT) || !m_player->movespline->Finalized() ||
        m_player->HasPendingMovementChange(KNOCK_BACK))
        return false;

    MovementInfo const& mi = m_player->m_movementInfo;
    if (mi.moveFlags & (MOVEFLAG_ROOT | MOVEFLAG_SWIMMING | MOVEFLAG_ONTRANSPORT))
        return false;

    bool const blink = m_run && m_run->IsBlinkDash();
    if (m_run)
        m_run->OnDash();
    bool const backfire = m_run && m_run->RollDashBackfire();

    m_dashRunTracked = false;
    if (blink)
        BlinkHero(backfire);
    else if (backfire)
        ThrowHero(frand(0.0f, 2.0f * float(M_PI)), GetDashSpeed());
    else if (mi.moveFlags & (MOVEFLAG_JUMPING | MOVEFLAG_FALLINGFAR))
    {
        float facing = m_player->GetOrientation();
        uint32 const age = std::min(WorldTimer::getMSTimeDiffToNow(mi.stime), BONK_DASH_MAX_AGE_MS);
        float x, y, z, o;
        if (m_player->ExtrapolateMovement(mi, age, x, y, z, o))
            facing = o;
        ThrowHero(facing, GetDashSpeed());
    }
    else
    {
        TrackDashRun();
        m_dashBurstUntilMs = m_dashClockMs + BONK_DASH_MS;
        SetDashBurst(true);
    }

    if (!m_dashSpent++)
        m_dashRechargeMs = GetDashCooldownMs();
    if (m_dashSpent == 1)
        m_dashRechargeUntilMs = m_dashClockMs + m_dashRechargeMs;
    m_dashInvulnerableUntilMs = m_dashClockMs + std::max(BONK_DASH_INVULNERABLE_MS, blink ? m_run->GetBlinkInvulnerableMs() : 0u) +
        (m_run ? m_run->GetVanishMs() : 0u);
    if (m_run && !m_run->IsSandbox())
        sBonkQuests.OnProgress(m_player, BONK_QUEST_DASHES, 0, 1);
    SendDash();
    return true;
}

void BonkPlayer::TrackDashRun()
{
    if (!m_dashBursting)
        m_dashRunBaseSpeed = m_player->GetSpeedForMovementInfo(m_player->m_movementInfo);
    m_dashRunStartedAtMs = WorldTimer::getMSTime() + m_player->GetSession()->GetLatency();
    m_dashRunTracked = true;
}

bool BonkPlayer::GetDashRunTravel(uint32 fromMs, uint32 toMs, float& travel) const
{
    if (!m_dashRunTracked)
        return false;
    uint32 const dashEndMs = m_dashRunStartedAtMs + BONK_DASH_MS;
    if (fromMs >= dashEndMs && !m_dashBursting)
        return false;
    uint32 const burstFromMs = std::max(fromMs, m_dashRunStartedAtMs);
    uint32 const burstToMs = std::min(toMs, dashEndMs);
    uint32 const burstMs = burstToMs > burstFromMs ? burstToMs - burstFromMs : 0;
    travel = (m_dashRunBaseSpeed * (toMs - fromMs) + (GetDashSpeed() - m_dashRunBaseSpeed) * burstMs) / IN_MILLISECONDS;
    return true;
}

void BonkPlayer::SetDashBurst(bool on)
{
    m_dashBursting = on;
    if (m_player->IsInWorld())
        for (UnitMoveType type : { MOVE_WALK, MOVE_RUN, MOVE_RUN_BACK })
            m_player->UpdateSpeed(type, false);
}

void BonkPlayer::ThrowHero(float angle, float speed)
{
    float const vcos = std::cos(angle);
    float const vsin = std::sin(angle);
    MovementPacketSender::SendKnockBackToController(m_player, vcos, vsin, speed, 0.0f);
    m_player->SetJumpInitialSpeed(0.0f);
    if (Player* mover = m_player->GetPlayerMovingMe())
        if (MovementAnticheat* cheatData = mover->GetCheatData())
            cheatData->OnKnockBack(m_player, speed, 0.0f, vcos, vsin);
}

float BonkPlayer::GetMoveAngle() const
{
    MovementInfo const& mi = m_player->m_movementInfo;
    float facing = m_player->GetOrientation();
    float x, y, z, o;
    uint32 const age = std::min(WorldTimer::getMSTimeDiffToNow(mi.stime), BONK_DASH_MAX_AGE_MS);
    if (m_player->ExtrapolateMovement(mi, age, x, y, z, o))
        facing = o;

    float forward = 0.0f, left = 0.0f;
    if (mi.moveFlags & MOVEFLAG_FORWARD)
        forward += 1.0f;
    if (mi.moveFlags & MOVEFLAG_BACKWARD)
        forward -= 1.0f;
    if (mi.moveFlags & MOVEFLAG_STRAFE_LEFT)
        left += 1.0f;
    if (mi.moveFlags & MOVEFLAG_STRAFE_RIGHT)
        left -= 1.0f;
    if (forward == 0.0f && left == 0.0f)
        return facing;
    return facing + std::atan2(left, forward);
}

void BonkPlayer::BlinkHero(bool backfire)
{
    MovementInfo const& mi = m_player->m_movementInfo;
    float x = m_player->GetPositionX(), y = m_player->GetPositionY(), z = m_player->GetPositionZ(), o = m_player->GetOrientation();
    uint32 const age = std::min(WorldTimer::getMSTimeDiffToNow(mi.stime), BONK_DASH_MAX_AGE_MS);
    m_player->ExtrapolateMovement(mi, age, x, y, z, o);

    bool const airborne = (mi.moveFlags & (MOVEFLAG_JUMPING | MOVEFLAG_FALLINGFAR)) != 0;
    float const angle = backfire ? frand(0.0f, 2.0f * float(M_PI)) : airborne ? o : GetMoveAngle();
    float destX = x + GetDashDistance() * std::cos(angle);
    float destY = y + GetDashDistance() * std::sin(angle);
    float destZ = z;
    m_player->GetMap()->GetWalkHitPosition(nullptr, x, y, z, destX, destY, destZ);

    m_player->SendPlaySpellVisualKit(BONK_KIT_BLINK_LEAVE);
    m_player->NearTeleportTo(destX, destY, destZ, m_player->GetOrientation(),
        TELE_TO_NOT_LEAVE_TRANSPORT | TELE_TO_NOT_LEAVE_COMBAT | TELE_TO_NOT_UNSUMMON_PET | TELE_TO_SPELL);
    m_player->SendPlaySpellVisualKit(BONK_KIT_BLINK_ARRIVE);
}

void BonkPlayer::UpdateDash(uint32 diff)
{
    if (IsDashPaused())
        return;
    m_dashClockMs += diff;

    if (m_dashSpent && int32(m_dashClockMs - m_dashRechargeUntilMs) >= 0)
    {
        --m_dashSpent;
        m_dashRechargeMs = m_dashSpent ? GetDashCooldownMs() : 0;
        m_dashRechargeUntilMs = m_dashSpent ? m_dashClockMs + m_dashRechargeMs : 0;
        SendDash();
    }

    if (m_dashBursting && m_dashClockMs >= m_dashBurstUntilMs)
        SetDashBurst(false);
}

void BonkPlayer::SendDash() const
{
    uint32 const maxCharges = GetDashMaxCharges();
    uint32 const available = maxCharges - std::min(m_dashSpent, maxCharges);
    uint32 const rechargeMs = m_dashSpent && int32(m_dashRechargeUntilMs - m_dashClockMs) > 0
        ? m_dashRechargeUntilMs - m_dashClockMs : 0;
    if (m_addonReady)
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteDash(data, uint8(maxCharges), rechargeMs, GetDashCooldownMs(), m_run && m_run->IsBlinkDash(),
            uint8(available));
        m_player->GetSession()->SendPacket(&data);
    }
}


local L = VanillaBonkL
local UI = VanillaBonkUI

local CAPTURE_WIDTH = 260
local MOONWELL_WIDTH = 240
local FILL_SPEED = 6
local FADE = 0.15
local FLASH = 0.6
local STACK_GAP = 6

local Restack

local function Bar(width, r, g, b)
    local rim = UI.CastRim(UIParent, width)
    rim:SetFrameStrata("MEDIUM")
    rim.bar = CreateFrame("StatusBar", nil, rim.opening)
    rim.bar:SetAllPoints(rim.opening)
    rim.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    rim.bar:SetStatusBarColor(r, g, b)
    rim.bar:SetMinMaxValues(0, 1)
    rim.bar:SetValue(0)
    rim.bar:SetFrameLevel(rim.opening:GetFrameLevel() + 1)
    rim.spark = rim.bar:CreateTexture(nil, "OVERLAY")
    rim.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    rim.spark:SetBlendMode("ADD")
    rim.spark:SetWidth(24)
    rim.spark:SetHeight(28)
    rim.flash = rim.art:CreateTexture(nil, "OVERLAY")
    rim.flash:SetTexture("Interface\\CastingBar\\UI-CastingBar-Flash")
    rim.flash:SetBlendMode("ADD")
    rim.flash:SetPoint("TOPLEFT", rim, "TOPLEFT", -20, 22)
    rim.flash:SetPoint("BOTTOMRIGHT", rim, "BOTTOMRIGHT", 20, -22)
    rim.flash:SetAlpha(0)
    rim.text = UI.Text(rim.art, 12)
    rim.text:SetPoint("CENTER", rim.opening, "CENTER", 0, 1)
    rim.value, rim.target = 0, 0
    rim.alpha, rim.want = 0, 0
    rim.flashLeft = 0
    rim:SetAlpha(0)
    rim:Hide()
    return rim
end

local function SetValue(rim, value)
    rim.value = value
    rim.bar:SetValue(value)
    rim.spark:ClearAllPoints()
    rim.spark:SetPoint("CENTER", rim.bar, "LEFT", rim.bar:GetWidth() * value, 0)
    if value > 0 and value < 1 then
        rim.spark:Show()
    else
        rim.spark:Hide()
    end
end

local function FadeIn(rim)
    if rim.want ~= 1 then
        rim.want = 1
        Restack()
    end
    rim:Show()
end

local function FadeOut(rim)
    if rim.want ~= 0 then
        rim.want = 0
        Restack()
    end
end

local function Update(rim, elapsed)
    if rim.endsAt then
        rim.target = max(rim.floor, (rim.endsAt - GetTime()) / rim.total)
        SetValue(rim, rim.target)
    elseif rim.value ~= rim.target then
        local value = rim.value + (rim.target - rim.value) * min(1, elapsed * FILL_SPEED)
        if abs(value - rim.target) < 0.002 then
            value = rim.target
        end
        SetValue(rim, value)
    end
    if rim.alpha ~= rim.want then
        local step = elapsed / FADE
        rim.alpha = rim.want > rim.alpha and min(rim.want, rim.alpha + step) or max(rim.want, rim.alpha - step)
        rim:SetAlpha(rim.alpha)
        if rim.alpha <= 0 then
            rim:Hide()
        end
    end
    if rim.flashLeft > 0 then
        rim.flashLeft = max(0, rim.flashLeft - elapsed)
        rim.flash:SetAlpha(rim.flashLeft / FLASH)
        if rim.flashLeft == 0 and rim.goAfterFlash then
            rim.goAfterFlash = nil
            FadeOut(rim)
        end
    end
end

local capture = Bar(CAPTURE_WIDTH, 0.45, 0.6, 1.0)
capture:SetScript("OnUpdate", function() Update(this, arg1) end)

local hearth = Bar(CAPTURE_WIDTH, 0.45, 0.6, 1.0)
hearth:SetScript("OnUpdate", function() Update(this, arg1) end)

local moonwell = Bar(MOONWELL_WIDTH, 0.3, 0.9, 0.75)
moonwell:SetScript("OnUpdate", function() Update(this, arg1) end)
moonwell.total = 0

local event = Bar(CAPTURE_WIDTH, 1, 0.55, 0.1)
event:SetScript("OnUpdate", function() Update(this, arg1) end)

local revive = Bar(CAPTURE_WIDTH, 0.4, 1, 0.4)
revive:SetScript("OnUpdate", function() Update(this, arg1) end)

local wait = Bar(CAPTURE_WIDTH, 1, 0.82, 0.2)
wait:SetScript("OnUpdate", function() Update(this, arg1) end)

local stack = { wait, revive, event, hearth, capture, moonwell }

Restack = function()
    local above
    for _, rim in ipairs(stack) do
        if rim.want == 1 or not above then
            rim:ClearAllPoints()
            if above then
                rim:SetPoint("TOP", above, "BOTTOM", 0, -STACK_GAP)
            else
                rim:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
            end
        end
        if rim.want == 1 then
            above = rim
        end
    end
end
Restack()

local function HideAll()
    event.endsAt = nil
    for _, rim in ipairs(stack) do
        rim.want, rim.alpha = 0, 0
        rim.value, rim.target = 0, 0
        rim.flashLeft = 0
        rim.goAfterFlash = nil
        rim:SetAlpha(0)
        rim:Hide()
    end
    moonwell.total = 0
end

local handlers = {}

handlers["capture"] = function(f)
    local percent = tonumber(f[3] or "")
    if not percent or percent < 0 then
        if capture.flashLeft > 0 then
            capture.goAfterFlash = true
        else
            FadeOut(capture)
        end
        return
    end
    capture.goAfterFlash = nil
    local label = f[2] ~= "" and f[2] or L["Capturing"]
    if not capture:IsShown() or capture.want == 0 then
        SetValue(capture, percent / 100)
    end
    capture.target = min(1, percent / 100)
    if percent >= 100 then
        SetValue(capture, 1)
        capture.text:SetText("|cff80ff80" .. label .. L[" captured|r"])
        if capture.flashLeft == 0 then
            capture.flashLeft = FLASH
            PlaySound("igQuestListComplete")
        end
    else
        capture.text:SetText(label .. "  " .. floor(percent) .. "%")
        capture.flashLeft = 0
        capture.flash:SetAlpha(0)
    end
    FadeIn(capture)
end

handlers["hearth"] = function(f)
    local percent = tonumber(f[2] or "")
    if not percent or percent < 0 then
        if hearth.flashLeft > 0 then
            hearth.goAfterFlash = true
        else
            FadeOut(hearth)
        end
        return
    end
    hearth.goAfterFlash = nil
    if not hearth:IsShown() or hearth.want == 0 then
        SetValue(hearth, percent / 100)
    end
    hearth.target = min(1, percent / 100)
    local seconds = tonumber(f[4] or "") or 0
    if percent >= 100 then
        SetValue(hearth, 1)
        hearth.bar:SetStatusBarColor(0.45, 0.6, 1.0)
        hearth.text:SetText(L["|cff80ff80Returning to the Inn|r"])
        if hearth.flashLeft == 0 then
            hearth.flashLeft = FLASH
            PlaySound("igQuestListComplete")
        end
    elseif f[3] == "1" then
        hearth.bar:SetStatusBarColor(0.45, 0.6, 1.0)
        hearth.text:SetText(L["Hearthstone  "] .. seconds .. "s")
    else
        hearth.bar:SetStatusBarColor(0.8, 0.25, 0.2)
        hearth.text:SetText(L["|cffff7060Get back in the ring!|r  "] .. seconds .. "s")
    end
    FadeIn(hearth)
end

handlers["moonwell"] = function(f)
    local seconds = tonumber(f[2] or "") or 0
    if seconds <= 0 then
        FadeOut(moonwell)
        moonwell.total = 0
        return
    end
    moonwell.total = tonumber(f[4] or "") or max(moonwell.total, seconds)
    local inside = f[3] == "1"
    moonwell.target = seconds / max(1, moonwell.total)
    if not moonwell:IsShown() or moonwell.want == 0 then
        SetValue(moonwell, moonwell.target)
    end
    if inside then
        moonwell.text:SetText(L["|cff80ff80Healing in the Moonwell|r ("] .. seconds .. "s)")
        moonwell.bar:SetStatusBarColor(0.3, 0.9, 0.75)
    else
        moonwell.text:SetText(L["Step into the Moonwell to heal ("] .. seconds .. "s)")
        moonwell.bar:SetStatusBarColor(0.2, 0.5, 0.42)
    end
    FadeIn(moonwell)
end

handlers["eventtimer"] = function(f)
    local seconds = tonumber(f[3] or "") or 0
    local total = tonumber(f[4] or "") or 0
    if seconds <= 0 or total <= 0 or (f[2] or "") == "" then
        event.endsAt = nil
        FadeOut(event)
        return
    end
    event.total = total
    event.endsAt = GetTime() + seconds
    event.floor = max(0, seconds - 1) / total
    event.text:SetText(f[2] .. "  " .. seconds .. "s")
    if not event:IsShown() or event.want == 0 then
        SetValue(event, seconds / total)
    end
    FadeIn(event)
end

function UI.SetReviveBar(label, fraction)
    if not label then
        if revive.want == 1 and revive.value > 0.5 and revive.flashLeft == 0 then
            SetValue(revive, 1)
            revive.flashLeft = FLASH
            revive.goAfterFlash = true
            PlaySound("igQuestListComplete")
        elseif revive.flashLeft == 0 then
            FadeOut(revive)
        end
        return
    end
    revive.goAfterFlash = nil
    if not revive:IsShown() or revive.want == 0 then
        SetValue(revive, fraction)
    end
    revive.target = min(1, fraction)
    revive.text:SetText(label .. "  " .. floor(fraction * 100) .. "%")
    FadeIn(revive)
end

function UI.SetWaitBar(label, seconds, total)
    if not label then
        wait.endsAt = nil
        FadeOut(wait)
        return
    end
    wait.total = total
    wait.endsAt = GetTime() + seconds
    wait.floor = 0
    wait.text:SetText(label .. "  " .. seconds .. "s")
    if not wait:IsShown() or wait.want == 0 then
        SetValue(wait, seconds / total)
    end
    FadeIn(wait)
end

handlers["start"] = HideAll
handlers["end"] = HideAll

UI.Listen(handlers)

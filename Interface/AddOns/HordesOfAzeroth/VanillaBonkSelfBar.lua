local L = VanillaBonkL
local UI = VanillaBonkUI

local LIFT = 0
local NUDGE_X = 0
local NORMAL_KIND = 0
local COLOR = { 0.24, 0.70, 0.28 }
local BAR_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"
local NUMBERS_FONT = "Interface\\AddOns\\HordesOfAzeroth\\Fonts\\Barlow-Bold.ttf"
local PLATE_NUMBER_SIZE = 7
local FRAME_NUMBER_SIZE = 9
local NUMBERED_PLATE = { width = 78, height = 14, name = 0, percent = 0 }

UI.HEALTH_BAR_MODES = {
    { value = "frame", label = L["Unit Frame"] },
    { value = "plate", label = L["Nameplate"] },
    { value = "both", label = L["Both"] },
}

local shield = 0
local activeMode

local function MakeBar(customSize)
    local made = UI.SamplePlate(UIParent, NORMAL_KIND, nil, nil, customSize)
    made:SetFrameStrata("BACKGROUND")
    made:SetMinMaxValues(0, 1)
    made:Hide()
    local shine = made:CreateTexture(nil, "OVERLAY")
    shine:SetTexture(BAR_TEXTURE)
    shine:SetBlendMode("ADD")
    shine:SetVertexColor(UI.SHIELD_COLOR[1], UI.SHIELD_COLOR[2], UI.SHIELD_COLOR[3], UI.SHIELD_COLOR[4])
    shine:SetPoint("TOPLEFT", made, "TOPLEFT", 0, 0)
    shine:SetPoint("BOTTOMLEFT", made, "BOTTOMLEFT", 0, 0)
    shine:Hide()
    made.shine = shine
    return made
end

local function MakeNumbers(owner, size)
    local layer = CreateFrame("Frame", nil, owner)
    layer:SetAllPoints(owner)
    layer:SetFrameLevel(owner:GetFrameLevel() + 3)
    local text = layer:CreateFontString(nil, "OVERLAY")
    text:SetFont(NUMBERS_FONT, size, "OUTLINE")
    text:SetPoint("CENTER", owner, "CENTER", 0, 0)
    return text
end

local plainBar = MakeBar(nil)
local numberedBar = MakeBar(NUMBERED_PLATE)
local plateNumbers = MakeNumbers(numberedBar, PLATE_NUMBER_SIZE)
local frameNumbers = MakeNumbers(PlayerFrameHealthBar, FRAME_NUMBER_SIZE)

function UI.HealthNumbers()
    return UI.Option("healthNumbers", true)
end

local function ActiveBar()
    return UI.HealthNumbers() and numberedBar or plainBar
end

local function HealthText()
    return format("%d / %d", UnitHealth("player"), UnitHealthMax("player"))
end

local function RefreshFrameNumbers()
    local on = UI.HealthNumbers()
    if on then
        frameNumbers:SetText(HealthText())
        frameNumbers:Show()
    else
        frameNumbers:Hide()
    end
    if PlayerFrameHealthBarText then
        PlayerFrameHealthBarText:SetAlpha(on and 0 or 1)
    end
end

function UI.ApplyHealthNumbers()
    plainBar:Hide()
    numberedBar:Hide()
    RefreshFrameNumbers()
end

function UI.HealthBarMode()
    local mode = UI.Option("healthBar", nil)
    if mode then
        return mode
    end
    local selfBar = UI.Option("selfBar", nil)
    if selfBar == nil then
        return "plate"
    end
    return selfBar and "both" or "frame"
end

local function ActiveMode()
    return activeMode or UI.HealthBarMode()
end

function UI.ApplyHealthBarMode(mode)
    activeMode = mode or UI.HealthBarMode()
    if UI.PlaceDarkmoonCards then
        UI.PlaceDarkmoonCards(activeMode == "plate")
    end
    if activeMode == "plate" then
        PlayerFrame:Hide()
    else
        PlayerFrame:Show()
    end
end

local BasePlayerFrameShow = PlayerFrame:GetScript("OnShow")
PlayerFrame:SetScript("OnShow", function()
    if ActiveMode() == "plate" then
        this:Hide()
        return
    end
    if BasePlayerFrameShow then
        BasePlayerFrameShow()
    end
end)

local function Wanted()
    return ActiveMode() ~= "frame" and HoAController_GetPlayerHead and not UnitIsDeadOrGhost("player")
end

local function RefreshShield(bar, maxHealth)
    local share = maxHealth > 0 and math.min(1, shield / maxHealth) or 0
    if share <= 0 then
        bar.shine:Hide()
        return
    end
    bar.shine:SetWidth(bar:GetWidth() * share)
    bar.shine:SetTexCoord(0, share, 0, 1)
    bar.shine:Show()
end

local function Refresh(bar)
    local health, maxHealth = UnitHealth("player"), UnitHealthMax("player")
    if bar.shownHealth == health and bar.shownMax == maxHealth and bar.shownShield == shield then
        return
    end
    bar.shownHealth, bar.shownMax, bar.shownShield = health, maxHealth, shield
    local share = maxHealth > 0 and health / maxHealth or 0
    bar:SetValue(share)
    bar:SetStatusBarColor(COLOR[1], COLOR[2], COLOR[3])
    RefreshShield(bar, maxHealth)
    if bar == numberedBar then
        plateNumbers:SetText(HealthText())
    end
end

local driver = CreateFrame("Frame")
driver:SetScript("OnUpdate", function()
    local bar = ActiveBar()
    if not Wanted() then
        bar:Hide()
        return
    end
    local x, y = HoAController_GetPlayerHead()
    if not x then
        bar:Hide()
        return
    end
    local worldWidth = WorldFrame:GetWidth()
    if bar.headX ~= x or bar.headY ~= y or bar.worldWidth ~= worldWidth or not bar:IsShown() then
        bar.headX, bar.headY, bar.worldWidth = x, y, worldWidth
        local worldScale = WorldFrame:GetEffectiveScale()
        local scale = bar:GetEffectiveScale()
        bar:ClearAllPoints()
        bar:SetPoint("BOTTOM", WorldFrame, "BOTTOMLEFT", x * worldWidth * worldScale / scale + NUDGE_X,
            y * WorldFrame:GetHeight() * worldScale / scale + LIFT)
    end
    Refresh(bar)
    bar:Show()
end)
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:RegisterEvent("UNIT_HEALTH")
driver:RegisterEvent("UNIT_MAXHEALTH")
driver:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        if GetCVar("statusBarText") == "1" then
            SetCVar("statusBarText", "0")
        end
        UI.ApplyHealthBarMode()
        UI.ApplyHealthNumbers()
    elseif arg1 == "player" then
        RefreshFrameNumbers()
    end
end)

UI.Listen({
    shield = function(f)
        shield = tonumber(f[2]) or 0
    end,
})

UI.SelfBar = plainBar

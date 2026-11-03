local L = VanillaBonkL
local UI = VanillaBonkUI

local WIDTH = 330
local LEFT = 26
local RIGHT = 36
local CONTENT_WIDTH = WIDTH - LEFT - RIGHT
local ROW = 22

local window = UI.Window("VanillaBonkRangeRing", WIDTH, 400)
window:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
window.title:SetText(L["Range Ring"])
window.colors = {}

window.intro = UI.Text(window, 12)
window.intro:SetWidth(CONTENT_WIDTH)
window.intro:SetJustifyH("LEFT")
window.intro:SetTextColor(0.91, 0.86, 0.75)
window.intro:SetPoint("TOPLEFT", window, "TOPLEFT", LEFT, -84)
window.intro:SetText(L["During a run, Alt-click a spell on your bar to show a ring of its reach around you. Alt-click it again to hide the ring."])

local cursor = 0

local function Place(widget, x, height)
    widget:SetPoint("TOPLEFT", window.intro, "BOTTOMLEFT", x or 0, -cursor)
    cursor = cursor + (height or 0)
end

local function Header(text)
    local header = UI.Text(window, 13)
    header:SetTextColor(1, 0.82, 0)
    header:SetText(text)
    cursor = cursor + 14
    Place(header, 0, 20)
end

local function ColorChoice(color)
    local radio = CreateFrame("CheckButton", "VanillaBonkRangeRingColor" .. color.style, window, "UIRadioButtonTemplate")
    radio.style = color.style
    radio.label = UI.Text(radio, 12)
    radio.label:SetPoint("LEFT", radio, "RIGHT", 4, 0)
    radio.label:SetTextColor(color.r, color.g, color.b)
    radio.label:SetText(color.label)
    radio:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        UI.ChangeSetting(UI.REACH_RING_COLOR_SETTING, this.style)
    end)
    Place(radio, 4, ROW)
    tinsert(window.colors, radio)
end

Header(L["Color"])
for _, color in ipairs(UI.REACH_RING_COLORS) do
    ColorChoice(color)
end

Header(L["Look"])
window.fill = CreateFrame("CheckButton", "VanillaBonkRangeRingFill", window, "UICheckButtonTemplate")
window.fill:SetWidth(24)
window.fill:SetHeight(24)
getglobal(window.fill:GetName() .. "Text"):SetFontObject(GameFontHighlightSmall)
getglobal(window.fill:GetName() .. "Text"):SetText(UI.REACH_RING_FILL_SETTING.label)
window.fill:SetScript("OnClick", function()
    PlaySound(this:GetChecked() and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
    UI.ChangeSetting(UI.REACH_RING_FILL_SETTING, this:GetChecked() and true or false)
end)
window.fill:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText(UI.REACH_RING_FILL_SETTING.tooltip, 1, 1, 1, 1, 1)
end)
window.fill:SetScript("OnLeave", function() GameTooltip:Hide() end)
Place(window.fill, 0, 30)

local opacity = UI.REACH_RING_OPACITY_SETTING
window.opacity = CreateFrame("Slider", "VanillaBonkRangeRingOpacity", window, "OptionsSliderTemplate")
window.opacity:SetWidth(CONTENT_WIDTH - 60)
window.opacity:SetMinMaxValues(opacity.min, 100)
window.opacity:SetValueStep(10)
getglobal(window.opacity:GetName() .. "Text"):SetText(opacity.label)
getglobal(window.opacity:GetName() .. "Low"):SetText(opacity.low)
getglobal(window.opacity:GetName() .. "High"):SetText(opacity.high)
window.opacity.value = UI.Text(window.opacity, 11)
window.opacity.value:SetPoint("LEFT", window.opacity, "RIGHT", 10, 0)
window.opacity:SetScript("OnValueChanged", function()
    this.value:SetText(opacity.valueText(this:GetValue()))
end)
window.opacity:SetScript("OnMouseUp", function()
    local value = math.floor(this:GetValue() + 0.5)
    if value ~= UI.SettingValue(opacity) then
        PlaySound("igMainMenuOptionCheckBoxOn")
        UI.ChangeSetting(opacity, value)
    end
end)
window.opacity:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText(opacity.tooltip, 1, 1, 1, 1, 1)
end)
window.opacity:SetScript("OnLeave", function() GameTooltip:Hide() end)
cursor = cursor + 16
Place(window.opacity, 8, 40)

window.preview = UI.Button(window, 110, L["Preview"], function()
    PlaySound("igMainMenuOptionCheckBoxOn")
    UI.PreviewReachRing()
end)
window.preview:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText(L("Shows the ring around you for {1} seconds.", UI.REACH_RING_PREVIEW_SECONDS), 1, 1, 1, 1, 1)
end)
window.preview:SetScript("OnLeave", function() GameTooltip:Hide() end)
window.done = UI.Button(window, 100, L["Done"], function() window:Hide() end)

local footerTop = 84 + window.intro:GetHeight() + cursor + 10
window.preview:SetPoint("TOPLEFT", window, "TOPLEFT", LEFT, -footerTop)
window.done:SetPoint("TOPRIGHT", window, "TOPRIGHT", -RIGHT, -footerTop)
UI.SetWindowSize(window, WIDTH, footerTop + 22 + 24)

local function Refresh()
    if not window:IsShown() then
        return
    end
    local style = UI.SettingValue(UI.REACH_RING_COLOR_SETTING)
    for _, radio in ipairs(window.colors) do
        radio:SetChecked(radio.style == style)
    end
    window.fill:SetChecked(UI.SettingValue(UI.REACH_RING_FILL_SETTING))
    window.opacity:SetValue(UI.SettingValue(opacity))
end

UI.WatchSettings(Refresh)
window:SetScript("OnShow", function()
    PlaySound("igCharacterInfoOpen")
    SetPortraitTexture(this.portrait, "player")
    Refresh()
end)
window:SetScript("OnHide", function()
    PlaySound("igCharacterInfoClose")
end)

function UI.ShowRangeRingWindow(beside)
    window:ClearAllPoints()
    if beside and beside:IsShown() then
        window:SetPoint("TOPLEFT", beside, "TOPRIGHT", -8, 0)
    else
        window:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    end
    window:Show()
end

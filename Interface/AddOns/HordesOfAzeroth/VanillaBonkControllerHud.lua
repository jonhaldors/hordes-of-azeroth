local L = VanillaBonkL
local UI = VanillaBonkUI
local Controller = VanillaBonkController

local HUD_HEIGHT = 34
local HUD_RIGHT = 10
local HUD_BOTTOM = 5
local GLYPH_SIZE = 24
local LABEL_GAP = 5
local ITEM_GAP = 14
local SHADE_TEXTURE = "Interface\\AddOns\\HordesOfAzeroth\\Textures\\CornerShade"
local SHADE_WIDTH = 460
local SHADE_HEIGHT = 120
local METER_EDGE = 20
local METER_LIFT = HUD_HEIGHT + 6
local KEY_REFRESH = 1
local PAIR_GAP = 2
local ITEMS = {
    { button = "lt", with = "rs", label = L["Zoom"], padOnly = true },
    { action = "dash", label = L["Dash"], dash = true },
    { button = "a", label = L["Jump"], command = "JUMP" },
    { action = "character", label = L["Character"], command = "TOGGLECHARACTER0", click = function() Controller.ToggleCharacterAndBags() end },
    { action = "map", label = L["Map"], command = "TOGGLEWORLDMAP", click = function() ToggleWorldMap() end },
}

local hud = CreateFrame("Frame", "VanillaBonkControllerHud", UIParent)
hud:SetFrameStrata("BACKGROUND")
hud:SetHeight(HUD_HEIGHT)
hud:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -HUD_RIGHT, HUD_BOTTOM)

hud.shade = hud:CreateTexture(nil, "BACKGROUND")
hud.shade:SetTexture(SHADE_TEXTURE)
hud.shade:SetWidth(SHADE_WIDTH)
hud.shade:SetHeight(SHADE_HEIGHT)
hud.shade:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)

local function MakeItem(item)
    local frame = CreateFrame("Button", nil, hud)
    frame:SetHeight(HUD_HEIGHT)
    if item.click then
        frame:SetScript("OnClick", item.click)
    end
    frame.cap = UI.KeyCap(frame)
    frame.cap:SetPoint("LEFT", frame, "LEFT", 0, 0)
    frame.glyph = frame:CreateTexture(nil, "ARTWORK")
    frame.glyph:SetWidth(GLYPH_SIZE)
    frame.glyph:SetHeight(GLYPH_SIZE)
    frame.glyph:SetPoint("LEFT", frame, "LEFT", 0, 0)
    if item.with then
        frame.plus = UI.Text(frame, 12)
        frame.plus:SetText("+")
        frame.plus:SetPoint("LEFT", frame.glyph, "RIGHT", PAIR_GAP, 0)
        frame.glyph2 = frame:CreateTexture(nil, "ARTWORK")
        frame.glyph2:SetWidth(GLYPH_SIZE)
        frame.glyph2:SetHeight(GLYPH_SIZE)
        frame.glyph2:SetPoint("LEFT", frame.plus, "RIGHT", PAIR_GAP, 0)
    end
    frame.label = UI.Text(frame, 12)
    frame.label:SetText(item.label)
    frame.item = item
    return frame
end

local function KeyText(item)
    if item.dash then
        return UI.DashKeyText and UI.DashKeyText() or ""
    end
    return UI.BindingText and UI.BindingText(item.command) or ""
end

hud.items = {}
for index, item in ipairs(ITEMS) do
    hud.items[index] = MakeItem(item)
end

local function ShowPair(frame, shown)
    if not frame.glyph2 then
        return
    end
    if shown then
        frame.plus:Show()
        frame.glyph2:Show()
    else
        frame.plus:Hide()
        frame.glyph2:Hide()
    end
end

local function ShowIcon(frame, keyboard)
    ShowPair(frame, not keyboard)
    if keyboard then
        frame.glyph:Hide()
        frame.cap:Show()
        return frame.cap
    end
    frame.cap:Hide()
    frame.glyph:Show()
    return frame.glyph2 or frame.glyph
end

local function IconWidth(frame)
    if frame.icon == frame.glyph2 then
        return GLYPH_SIZE * 2 + frame.plus:GetStringWidth() + 2 * PAIR_GAP
    end
    return frame.icon:GetWidth()
end

local function Layout()
    local width = 0
    for _, frame in ipairs(hud.items) do
        if frame.shown then
            local icon = frame.icon
            frame.label:ClearAllPoints()
            frame.label:SetPoint("LEFT", icon, "RIGHT", LABEL_GAP, 0)
            local itemWidth = IconWidth(frame) + LABEL_GAP + frame.label:GetStringWidth()
            frame:SetWidth(itemWidth)
            frame:ClearAllPoints()
            frame:SetPoint("LEFT", hud, "LEFT", width + (width > 0 and ITEM_GAP or 0), 0)
            width = width + itemWidth + (width > 0 and ITEM_GAP or 0)
        end
    end
    hud:SetWidth(math.max(1, width))
end

local function InRun()
    return UI.InRun ~= nil and UI.InRun() == true
end

local function RefreshIcons()
    local keyboard = Controller.kind == nil
    local signature = keyboard and "keys" or Controller.PadSignature()
    for _, frame in ipairs(hud.items) do
        local item = frame.item
        frame.icon = ShowIcon(frame, keyboard)
        frame.shown = not (item.padOnly and keyboard)
        if keyboard then
            if frame.shown then
                local text = KeyText(item)
                UI.SetKeyCap(frame.cap, text)
                frame.shown = text ~= ""
                signature = signature .. "|" .. text
            end
        else
            Controller.SetGlyph(frame.glyph, item.action and Controller.ButtonFor(item.action) or item.button)
            if frame.glyph2 then
                Controller.SetGlyph(frame.glyph2, item.with)
            end
        end
        frame:EnableMouse(keyboard and frame.item.click ~= nil)
        if frame.shown then
            frame:Show()
        else
            frame:Hide()
        end
    end
    hud.signature = signature
    Layout()
end

local function PlaceMeter(lifted)
    local meter = getglobal("VanillaBonkMeter")
    if not meter or meter.lifted == lifted then
        return
    end
    meter.lifted = lifted
    meter:ClearAllPoints()
    meter:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -METER_EDGE, METER_EDGE + (lifted and METER_LIFT or 0))
end

local function HideMenuBar()
    local bar = getglobal("VanillaBonkMenuBar")
    if bar and bar:IsShown() then
        bar:Hide()
    end
end

local watcher = CreateFrame("Frame")
watcher:SetScript("OnUpdate", function()
    HideMenuBar()
    local shownHere = not InRun() and Controller.kind ~= nil
    PlaceMeter(shownHere)
    local hidden = not shownHere or (Controller.PromptsVisible and Controller.PromptsVisible())
    if hidden and hud:IsShown() then
        hud:Hide()
    elseif not hidden and not hud:IsShown() then
        hud:Show()
    end
    hud.keysAt = (hud.keysAt or 0) + arg1
    local keyboard = Controller.kind == nil
    local changed = hud.keyboard ~= keyboard
    if changed or (not keyboard and Controller.PadSignature() ~= hud.signature) or (keyboard and hud.keysAt >= KEY_REFRESH) then
        hud.keysAt = 0
        hud.keyboard = keyboard
        RefreshIcons()
    end
end)

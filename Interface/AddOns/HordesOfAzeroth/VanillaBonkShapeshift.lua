local L = VanillaBonkL
local UI = VanillaBonkUI

local SHAPESHIFT = "VANILLABONK_SHAPESHIFT"
local SPELL_NAME = L["Shapeshift"]
local SEND_INTERVAL = 0.25
local GLYPH_SIZE = 16
BINDING_NAME_VANILLABONK_SHAPESHIFT = L["Shapeshift"]

local FORM_ICONS = {
    moonkin = "Interface\\Icons\\Spell_Nature_ForceOfNature",
    cat = "Interface\\Icons\\Ability_Druid_CatForm",
    bear = "Interface\\Icons\\Ability_Racial_BearForm",
    tree = "Interface\\Icons\\Spell_Nature_ProtectionformNature",
}

local BONUS_COLORS = {
    g = { 0.25, 1, 0.25 },
    r = { 1, 0.2, 0.2 },
}
local BORDER_TEXTURE = "Interface\\Buttons\\UI-ActionButton-Border"

local current
local lastSent = 0
local slotStates = {}
local bordered = {}

function VanillaBonk_Shapeshift()
    if keystate == "up" or not current then
        return
    end
    local now = GetTime()
    if now - lastSent < SEND_INTERVAL then
        return
    end
    lastSent = now
    SendChatMessage(".bonk shapeshift", "SAY")
end

local function KeyLabel(slot)
    if slot.shapeshiftKey then
        return slot.shapeshiftKey
    end
    local layer = CreateFrame("Frame", nil, slot)
    layer:SetAllPoints(slot)
    layer:SetFrameLevel(slot:GetFrameLevel() + 6)
    local text = UI.Text(layer, 11, UI.NUMBER_FONT, "OUTLINE")
    text:SetPoint("TOPLEFT", slot, "TOPLEFT", 2, -2)
    text:SetTextColor(0.85, 0.85, 0.85)
    text.glyph = layer:CreateTexture(nil, "OVERLAY")
    text.glyph:SetWidth(GLYPH_SIZE)
    text.glyph:SetHeight(GLYPH_SIZE)
    text.glyph:SetPoint("TOPLEFT", slot, "TOPLEFT", 1, -1)
    text.glyph:Hide()
    slot.shapeshiftKey = text
    return text
end

local function ShowKey(slot)
    local text = KeyLabel(slot)
    VanillaBonkController.ShowKey(text, text.glyph, VanillaBonkController.ButtonFor("shapeshift"), UI.BindingText(SHAPESHIFT))
end

local marked

local function Unmark()
    if marked and marked.shapeshiftKey then
        marked.shapeshiftKey:SetText("")
        marked.shapeshiftKey.glyph:Hide()
    end
    marked = nil
end

local function BonusBorder(slot)
    if slot.formBorder then
        return slot.formBorder
    end
    local layer = CreateFrame("Frame", nil, slot)
    layer:SetAllPoints(slot)
    layer:SetFrameLevel(slot:GetFrameLevel() + 5)
    local border = layer:CreateTexture(nil, "OVERLAY")
    border:SetTexture(BORDER_TEXTURE)
    border:SetBlendMode("ADD")
    border:SetWidth(slot:GetWidth() * 62 / 36)
    border:SetHeight(slot:GetHeight() * 62 / 36)
    border:SetPoint("CENTER", slot, "CENTER", 0, 0)
    slot.formBorder = border
    return border
end

local function RefreshBorders()
    local shown = {}
    for index, state in ipairs(slotStates) do
        local color = BONUS_COLORS[state]
        local slot = color and UI.HeroSpellSlotAt and UI.HeroSpellSlotAt(index)
        if slot then
            local border = BonusBorder(slot)
            border:SetVertexColor(color[1], color[2], color[3])
            border:Show()
            shown[slot] = true
        end
    end
    for slot in pairs(bordered) do
        if not shown[slot] then
            slot.formBorder:Hide()
        end
    end
    bordered = shown
end

local driver = CreateFrame("Frame")
driver:SetScript("OnUpdate", function()
    RefreshBorders()
    local slot = current and UI.HeroSpellSlot and UI.HeroSpellSlot(SPELL_NAME)
    if slot ~= marked then
        Unmark()
    end
    if not slot then
        return
    end
    marked = slot
    ShowKey(slot)
    local icon = FORM_ICONS[current]
    if icon and slot.icon:GetTexture() ~= icon then
        slot.icon:SetTexture(icon)
        UI.CropIcon(slot.icon)
    end
end)

UI.Listen({
    druidform = function(f)
        current = FORM_ICONS[f[2]] and f[2] or nil
    end,
    druidslots = function(f)
        slotStates = {}
        for index = 2, table.getn(f) do
            slotStates[index - 1] = f[index]
        end
    end,
})

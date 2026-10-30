local L = VanillaBonkL
local UI = VanillaBonkUI

UI.ENCHANTER_NAME = L["Ilsa Runeweaver"]
UI.enchants = UI.enchants or {}

local WIDTH = 440
local LEFT = 26
local RIGHT = 36
local CONTENT_WIDTH = WIDTH - LEFT - RIGHT
local ROW_HEIGHT = 40
local ICON_SIZE = 32
local ROLL_WIDTH = 92
local NO_ENCHANT = 255
local GREETING = L["For Valor I will bind magic into your gear until this run ends. The enchant stays on the slot, whatever you wear there, and grows with the piece."]
local OFFER_COUNT = 3
local OFFER_HEIGHT = 26

local SLOTS = {
    { slot = 0, name = L["Head"], art = "Head" },
    { slot = 2, name = L["Shoulders"], art = "Shoulder" },
    { slot = 4, name = L["armor slot::Chest"], art = "Chest" },
    { slot = 8, name = L["Wrists"], art = "Wrists" },
    { slot = 9, name = L["Hands"], art = "Hands" },
    { slot = 5, name = L["Waist"], art = "Waist" },
    { slot = 6, name = L["Legs"], art = "Legs" },
    { slot = 7, name = L["Feet"], art = "Feet" },
}
local GRADES = {
    [0] = { name = L["Minor"], color = { 0.8, 0.8, 0.8 } },
    [1] = { name = L["Lesser"], color = { 0.12, 1, 0 } },
    [2] = { name = L["Greater"], color = { 0, 0.44, 0.87 } },
    [3] = { name = L["Superior"], color = { 0.64, 0.21, 0.93 } },
    [4] = { name = L["Godly"], color = { 1, 0.5, 0 } },
}

local state = { cost = 0, valor = 0, slots = {}, offers = nil }
local incoming

local window = UI.Window("VanillaBonkEnchanter", WIDTH, 650)
window:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
window.title:SetText(UI.ENCHANTER_NAME)

window.greeting = UI.Text(window, 12)
window.greeting:SetWidth(CONTENT_WIDTH)
window.greeting:SetJustifyH("LEFT")
window.greeting:SetTextColor(0.91, 0.86, 0.75)
window.greeting:SetPoint("TOPLEFT", window, "TOPLEFT", LEFT, -84)
window.greeting:SetText(GREETING)

window.cost = UI.Text(window, 11)
window.cost:SetWidth(CONTENT_WIDTH)
window.cost:SetJustifyH("LEFT")
window.cost:SetTextColor(0.78, 0.75, 0.69)
window.cost:SetPoint("TOPLEFT", window.greeting, "BOTTOMLEFT", 0, -10)

local function EnchantText(effect, grade, value)
    local info = GRADES[grade]
    if not effect or effect == NO_ENCHANT or not info then
        return "|cff8a8478" .. L["No enchant"] .. "|r"
    end
    local color = info.color
    return format("|cff%02x%02x%02x%s:|r %s", color[1] * 255, color[2] * 255, color[3] * 255, info.name, UI.StatText and UI.StatText(effect, value) or "")
end

local function SlotTexture(entry)
    local texture = GetInventoryItemTexture("player", entry.slot + 1)
    return texture or ("Interface\\PaperDoll\\UI-PaperDoll-Slot-" .. entry.art)
end

local rows = {}

local function Roll(slot)
    PlaySound("igMainMenuOptionCheckBoxOn")
    SendChatMessage(".bonk gear enchant roll " .. slot, "SAY")
end

for index, entry in ipairs(SLOTS) do
    local row = CreateFrame("Frame", nil, window)
    row:SetWidth(CONTENT_WIDTH)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", window.cost, "BOTTOMLEFT", 0, -10 - (index - 1) * ROW_HEIGHT)
    row.entry = entry
    row.icon = UI.Slot(row, ICON_SIZE, "Frame")
    row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.label = UI.Text(row, 12)
    row.label:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 10, -1)
    row.label:SetTextColor(1, 0.82, 0)
    row.label:SetText(entry.name)
    row.enchant = UI.Text(row, 11)
    row.enchant:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 10, 1)
    row.enchant:SetWidth(CONTENT_WIDTH - ICON_SIZE - ROLL_WIDTH - 24)
    row.enchant:SetJustifyH("LEFT")
    row.roll = UI.Button(row, ROLL_WIDTH, L["Enchant"], function() Roll(this:GetParent().entry.slot) end)
    row.roll:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    rows[index] = row
end

window.pending = UI.Panel(window)
window.pending:SetWidth(CONTENT_WIDTH)
window.pending:SetHeight(68 + OFFER_COUNT * OFFER_HEIGHT)
window.pending:SetPoint("TOPLEFT", window.cost, "BOTTOMLEFT", 0, -18 - table.getn(SLOTS) * ROW_HEIGHT)
window.pending.text = UI.Text(window.pending, 12)
window.pending.text:SetPoint("TOPLEFT", window.pending, "TOPLEFT", 12, -10)
window.pending.text:SetWidth(CONTENT_WIDTH - 24)
window.pending.text:SetJustifyH("LEFT")
window.pending.offers = {}
for index = 1, OFFER_COUNT do
    local offer = UI.Button(window.pending, CONTENT_WIDTH - 24, "", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        SendChatMessage(".bonk gear enchant pick " .. this.index, "SAY")
    end)
    offer.index = index - 1
    offer:SetPoint("TOPLEFT", window.pending, "TOPLEFT", 12, -30 - (index - 1) * OFFER_HEIGHT)
    window.pending.offers[index] = offer
end
window.pending.discard = UI.Button(window.pending, 120, L["Keep current"], function()
    PlaySound("igMainMenuOptionCheckBoxOff")
    SendChatMessage(".bonk gear enchant discard", "SAY")
end)
window.pending.discard:SetPoint("BOTTOMRIGHT", window.pending, "BOTTOMRIGHT", -8, 8)
window.pending.hint = UI.Text(window.pending, 10)
window.pending.hint:SetPoint("BOTTOMLEFT", window.pending, "BOTTOMLEFT", 12, 13)
window.pending.hint:SetTextColor(0.54, 0.52, 0.47)

local function SlotName(slot)
    for _, entry in ipairs(SLOTS) do
        if entry.slot == slot then
            return entry.name
        end
    end
    return ""
end

local function Refresh()
    if not window:IsShown() then
        return
    end
    window.cost:SetText(L("Each enchant costs |cffffe873{1} Valor|r, and the next one this visit costs more. You have {2}.", state.cost, state.valor))
    local offers = state.offers
    for _, row in ipairs(rows) do
        local slot = state.slots[row.entry.slot] or {}
        row.icon.icon:SetTexture(SlotTexture(row.entry))
        row.enchant:SetText(EnchantText(slot.effect, slot.grade, slot.value))
        if offers or state.valor < state.cost then
            row.roll:Disable()
        else
            row.roll:Enable()
        end
    end
    if offers then
        local current = state.slots[offers.slot] or {}
        window.pending.text:SetText(L("Choose an enchant for your {1}:", string.lower(SlotName(offers.slot))))
        for index, button in ipairs(window.pending.offers) do
            local offer = offers[index]
            if offer then
                button:SetText(EnchantText(offer.effect, offer.grade, offer.value))
                button:Show()
            else
                button:Hide()
            end
        end
        window.pending.hint:SetText(L("Now: {1}", EnchantText(current.effect, current.grade, current.value)))
        window.pending:Show()
    else
        window.pending:Hide()
    end
end

window:SetScript("OnShow", function()
    PlaySound("igCharacterInfoOpen")
    UI.SetPortrait(this)
    Refresh()
end)

window:SetScript("OnHide", function()
    PlaySound("igCharacterInfoClose")
    if this.fromGossip then
        this.fromGossip = nil
        if not this.gossipClosed then
            CloseGossip()
        end
    end
    this.gossipClosed = nil
end)

local PreviousGossipOnEvent = GossipFrame_OnEvent
function GossipFrame_OnEvent()
    if event == "GOSSIP_SHOW" and UI.TalkingTo(UI.ENCHANTER_NAME) then
        window.fromGossip = true
        SendChatMessage(".bonk gear enchant open", "SAY")
        return
    elseif event == "GOSSIP_CLOSED" and window.fromGossip and window:IsShown() then
        window.gossipClosed = true
        window:Hide()
    end
    PreviousGossipOnEvent()
end

local handlers = {}

handlers["enchantclear"] = function()
    incoming = { slots = {} }
end

handlers["enchantinfo"] = function(f)
    if incoming then
        incoming.cost = tonumber(f[2] or "") or 0
        incoming.valor = tonumber(f[3] or "") or 0
    end
end

handlers["enchantslot"] = function(f)
    local slot = tonumber(f[2] or "")
    if incoming and slot then
        incoming.slots[slot] = { effect = tonumber(f[3] or ""), grade = tonumber(f[4] or ""), value = tonumber(f[5] or "") or 0 }
    end
end

handlers["enchantoffer"] = function(f)
    local slot = tonumber(f[2] or "")
    local index = tonumber(f[3] or "")
    if incoming and slot and index then
        incoming.offers = incoming.offers or { slot = slot }
        incoming.offers[index + 1] = { effect = tonumber(f[4] or ""), grade = tonumber(f[5] or ""), value = tonumber(f[6] or "") or 0 }
    end
end

handlers["enchantend"] = function()
    if not incoming then
        return
    end
    state.cost = incoming.cost or state.cost
    state.slots = incoming.slots
    state.valor = incoming.valor or state.valor
    state.offers = incoming.offers
    incoming = nil
    UI.enchants = {}
    for slot, enchant in pairs(state.slots) do
        if enchant.effect and enchant.effect ~= NO_ENCHANT then
            UI.enchants[slot + 1] = { stat = enchant.effect, value = enchant.value, grade = enchant.grade }
        end
    end
    Refresh()
end

handlers["enchantopen"] = function()
    if window:IsShown() then
        Refresh()
    else
        window:Show()
    end
end

handlers["enchantclose"] = function()
    if window:IsShown() then
        window:Hide()
    end
end

UI.Listen(handlers)

window:RegisterEvent("UNIT_INVENTORY_CHANGED")
window:SetScript("OnEvent", Refresh)

function UI.EnchantLine(inventorySlot)
    local enchant = UI.enchants[inventorySlot]
    if not enchant or not UI.StatText then
        return nil
    end
    return L("Enchanted: {1} {2}", GRADES[enchant.grade].name, UI.StatText(enchant.stat, enchant.value))
end

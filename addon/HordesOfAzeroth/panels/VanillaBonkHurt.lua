local L = VanillaBonkL
local UI = VanillaBonkUI

local SIZE = 15
local CRIT_SIZE = 20
local WORD_SIZE = 12
local RISE = 64
local LIFE = 1.1
local FADE = 0.4
local MAX_TEXTS = 10
local START_X, START_Y = -46, -6
local STEP_X, STEP_Y, STEPS = -10, -16, 5

local RED = { 1, 0.15, 0.1 }
local SPELL_PINK = { 0.79, 0.3, 0.85 }
local GREY = { 0.7, 0.7, 0.7 }
local PHYSICAL_SCHOOL = 0

local WORDS = {
    MISS = L["hoa.addon.miss"], DODGE = L["hoa.addon.dodge"], PARRY = L["hoa.addon.parry"], BLOCK = L["hoa.addon.block"], RESIST = L["hoa.addon.resist"],
    IMMUNE = L["hoa.addon.immune"], EVADE = L["hoa.addon.evade"], DEFLECT = L["hoa.addon.deflect"], ABSORB = L["hoa.addon.absorb"], REFLECT = L["hoa.addon.reflect"],
}

local frame = CreateFrame("Frame", "VanillaBonkHurt", UIParent)
frame:SetAllPoints(UIParent)
frame:SetFrameStrata("LOW")
frame:Hide()

local texts = {}
for index = 1, MAX_TEXTS do
    local text = UI.Text(frame, SIZE, UI.FONT, "OUTLINE")
    text:Hide()
    texts[index] = text
end

local slot = 1
local step = 0

local function Show(message, color, size)
    if not UI.Option("incomingNumbers", true) then
        return
    end
    local text = texts[slot]
    slot = mod(slot, MAX_TEXTS) + 1
    text:SetFont(UI.FONT, size, "OUTLINE")
    text:SetText(message)
    text:SetTextColor(color[1], color[2], color[3])
    text.x = START_X + math.mod(step, 2) * STEP_X
    text.y = START_Y + step * STEP_Y
    text.born = GetTime()
    step = mod(step + 1, STEPS)
    text:ClearAllPoints()
    text:SetPoint("RIGHT", frame, "CENTER", text.x, text.y)
    text:SetAlpha(1)
    text:Show()
    frame:Show()
end

frame:SetScript("OnUpdate", function()
    local now = GetTime()
    local any = false
    for _, text in ipairs(texts) do
        if text:IsShown() then
            local age = now - text.born
            if age >= LIFE then
                text:Hide()
            else
                any = true
                local t = age / LIFE
                local rise = RISE * (1 - (1 - t) * (1 - t))
                text:SetPoint("RIGHT", this, "CENTER", text.x, text.y + rise)
                text:SetAlpha(age > LIFE - FADE and (LIFE - age) / FADE or 1)
            end
        end
    end
    if not any then
        this:Hide()
    end
end)

local STOCK_DAMAGE_TYPES = { "DAMAGE", "DAMAGE_CRIT", "SPELL_DAMAGE", "SPLIT_DAMAGE" }

local function MuteStockDamageText()
    if not COMBAT_TEXT_TYPE_INFO then
        return
    end
    for _, messageType in ipairs(STOCK_DAMAGE_TYPES) do
        local info = COMBAT_TEXT_TYPE_INFO[messageType]
        if info then
            info.show = nil
        end
    end
end

MuteStockDamageText()

UI.Module("hurt"):Listen({
    ADDON_LOADED = function(name)
        if name == "Blizzard_CombatText" then
            MuteStockDamageText()
        end
    end,
    UNIT_COMBAT = function(unit, action, flags, amount, school)
        if unit ~= "player" then
            return
        end
        amount = tonumber(amount) or 0
        school = tonumber(school) or PHYSICAL_SCHOOL
        if action == "WOUND" then
            if amount > 0 then
                local big = flags == "CRITICAL" or flags == "CRUSHING"
                Show("-" .. amount, school == PHYSICAL_SCHOOL and RED or SPELL_PINK, big and CRIT_SIZE or SIZE)
            elseif WORDS[flags] then
                Show(WORDS[flags], GREY, WORD_SIZE)
            end
        elseif WORDS[action] then
            Show(WORDS[action], GREY, WORD_SIZE)
        end
    end,
})

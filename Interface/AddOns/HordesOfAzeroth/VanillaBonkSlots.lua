local L = VanillaBonkL
local LOCKED_SLOTS = {
    WARRIOR = { "Ranged", "Ammo" },
    PALADIN = { "Ranged", "Ammo" },
    ROGUE   = { "Ranged", "Ammo" },
    PRIEST  = { "Ranged", "Ammo" },
    SHAMAN  = { "Ranged", "Ammo" },
    MAGE    = { "Ranged", "Ammo" },
    WARLOCK = { "Ranged", "Ammo" },
    DRUID   = { "SecondaryHand", "Ranged", "Ammo" },
    HUNTER  = { "MainHand", "SecondaryHand" },
}

local CLASS_WEAPONS = {
    WARRIOR = L["Warriors fight using melee weapons."],
    PALADIN = L["Paladins fight using melee weapons and shields."],
    ROGUE   = L["Rogues fight using melee weapons."],
    PRIEST  = L["Priests fight using maces, staves and held items."],
    SHAMAN  = L["Shamans fight using melee weapons and shields."],
    MAGE    = L["Mages fight using staves, swords, daggers and held items."],
    WARLOCK = L["Warlocks fight using staves, swords, daggers and held items."],
    DRUID   = L["Druids fight using staves and two-handed maces."],
    HUNTER  = L["Hunters fight using ranged weapons."],
}

local DIM = 0.35

local slots = { locked = {}, why = nil }

local function IsLocked(button)
    return slots.locked[button:GetName()] and not button.hasItem
end

local function Cross(button)
    if not button.bonkCross then
        local size = math.floor(button:GetWidth() / 2)
        local cross = button:CreateTexture(nil, "OVERLAY")
        cross:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
        cross:SetWidth(size)
        cross:SetHeight(size)
        cross:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
        button.bonkCross = cross
    end
    return button.bonkCross
end

local function ShowLock(button)
    if not button or not slots.locked[button:GetName()] then
        return
    end
    if button.hasItem then
        Cross(button):Hide()
        return
    end
    SetItemButtonDesaturated(button, 1, DIM, DIM, DIM)
    Cross(button):Show()
end

local function ShowLockTooltip(button)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(TEXT(getglobal(strupper(strsub(button:GetName(), 10)))), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
    GameTooltip:AddLine(L["Not used by your class."], RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
    GameTooltip:AddLine(slots.why, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
    GameTooltip:Show()
end

local function Guard(button)
    for _, script in ipairs({ "OnClick", "OnReceiveDrag", "OnDragStart" }) do
        local original = button:GetScript(script)
        if original then
            button:SetScript(script, function()
                if not IsLocked(this) then
                    original()
                end
            end)
        end
    end
end

local updateSlot = PaperDollItemSlotButton_Update
PaperDollItemSlotButton_Update = function(cooldownOnly)
    updateSlot(cooldownOnly)
    ShowLock(this)
end

local enterSlot = PaperDollItemSlotButton_OnEnter
PaperDollItemSlotButton_OnEnter = function()
    if IsLocked(this) then
        ShowLockTooltip(this)
    else
        enterSlot()
    end
end

local updateSlotLock = PaperDollItemSlotButton_UpdateLock
PaperDollItemSlotButton_UpdateLock = function()
    updateSlotLock()
    ShowLock(this)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:SetScript("OnEvent", function()
    this:UnregisterEvent("PLAYER_ENTERING_WORLD")
    local _, class = UnitClass("player")
    slots.why = CLASS_WEAPONS[class]
    for _, slot in ipairs(LOCKED_SLOTS[class] or {}) do
        local button = getglobal("Character" .. slot .. "Slot")
        if button then
            slots.locked[button:GetName()] = true
            Guard(button)
            ShowLock(button)
        end
    end
end)

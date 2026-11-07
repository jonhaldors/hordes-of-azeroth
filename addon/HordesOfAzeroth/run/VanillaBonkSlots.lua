local L = VanillaBonkL
local UI = VanillaBonkUI
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
    WARRIOR = L["hoa.addon.warriors_fight_using_melee_weapons"],
    PALADIN = L["hoa.addon.paladins_fight_using_melee_weapons_and_shields"],
    ROGUE   = L["hoa.addon.rogues_fight_using_melee_weapons"],
    PRIEST  = L["hoa.addon.priests_fight_using_maces_staves_and_held_items"],
    SHAMAN  = L["hoa.addon.shamans_fight_using_melee_weapons_and_shields"],
    MAGE    = L["hoa.addon.mages_fight_using_staves_swords_daggers_and_held_items"],
    WARLOCK = L["hoa.addon.warlocks_fight_using_staves_swords_daggers_and_held_items"],
    DRUID   = L["hoa.addon.druids_fight_using_staves_and_two_handed_maces"],
    HUNTER  = L["hoa.addon.hunters_fight_using_ranged_weapons"],
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
    GameTooltip:AddLine(L["hoa.addon.not_used_by_your_class"], RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
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

local slotsReady = false
UI.Module("slots"):OnEnterWorld(function()
    if slotsReady then
        return
    end
    slotsReady = true
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

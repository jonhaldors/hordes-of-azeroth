local L = VanillaBonkL
local UI = VanillaBonkUI

local BAGS = { 0, 1, 2, 3, 4 }
local COLUMNS = 8
local SLOT = 37
local SPACING = 2
local PADDING = 12
local TITLE_HEIGHT = 30
local FOOTER_HEIGHT = 26

local frame = CreateFrame("Frame", "VanillaBonkBags", UIParent)
frame:SetFrameStrata("MEDIUM")
frame:SetToplevel(true)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetClampedToScreen(true)
frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -12, 92)
frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
frame:SetBackdropColor(0, 0, 0, 0.85)
frame:SetBackdropBorderColor(0.7, 0.7, 0.7)
frame:Hide()
tinsert(UISpecialFrames, "VanillaBonkBags")

frame:SetScript("OnMouseDown", function()
    if arg1 == "LeftButton" then
        this:StartMoving()
    end
end)
frame:SetScript("OnMouseUp", function()
    this:StopMovingOrSizing()
end)
frame:SetScript("OnShow", function()
    PlaySound("igBackPackOpen")
end)
frame:SetScript("OnHide", function()
    PlaySound("igBackPackClose")
end)

frame.title = UI.Text(frame, 13)
frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -10)
frame.title:SetTextColor(1, 0.82, 0)

frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 2, 2)

frame.free = UI.Text(frame, 11)
frame.free:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PADDING, 11)
frame.free:SetTextColor(0.75, 0.75, 0.75)

frame.money = CreateFrame("Frame", "VanillaBonkBagsMoney", frame, "SmallMoneyFrameTemplate")
frame.money:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 4, 9)

local bagFrames = {}
for _, bag in ipairs(BAGS) do
    local holder = CreateFrame("Frame", nil, frame)
    holder:SetID(bag)
    holder:SetAllPoints(frame)
    holder.slots = {}
    bagFrames[bag] = holder
end

local function SlotButton(bag, slot)
    local holder = bagFrames[bag]
    local button = holder.slots[slot]
    if button then
        return button
    end
    button = CreateFrame("Button", "VanillaBonkBagsItem" .. bag .. "_" .. slot, holder, "ContainerFrameItemButtonTemplate")
    button:SetID(slot)
    button.empty = button:CreateTexture(nil, "BACKGROUND")
    button.empty:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")
    button.empty:SetAllPoints(button)
    button.quality = button:CreateTexture(nil, "OVERLAY")
    button.quality:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    button.quality:SetBlendMode("ADD")
    button.quality:SetWidth(SLOT * 64 / 37)
    button.quality:SetHeight(SLOT * 64 / 37)
    button.quality:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.quality:Hide()
    holder.slots[slot] = button
    return button
end

local function QualityColor(link)
    if not link then
        return nil
    end
    local _, _, hex = strfind(link, "|c%x%x(%x%x%x%x%x%x)")
    if not hex or hex == "ffffff" or hex == "9d9d9d" then
        return nil
    end
    return tonumber(strsub(hex, 1, 2), 16) / 255, tonumber(strsub(hex, 3, 4), 16) / 255, tonumber(strsub(hex, 5, 6), 16) / 255
end

local function UpdateSlot(button, bag, slot)
    local texture, count, locked = GetContainerItemInfo(bag, slot)
    SetItemButtonTexture(button, texture)
    SetItemButtonCount(button, count)
    SetItemButtonDesaturated(button, locked, 0.5, 0.5, 0.5)
    if texture then
        button.empty:Hide()
        ContainerFrame_UpdateCooldown(bag, button)
        local r, g, b = QualityColor(GetContainerItemLink(bag, slot))
        if r then
            button.quality:SetVertexColor(r, g, b)
            button.quality:Show()
        else
            button.quality:Hide()
        end
    else
        button.empty:Show()
        button.quality:Hide()
        getglobal(button:GetName() .. "Cooldown"):Hide()
    end
    button:Show()
end

local function Layout()
    local index, free, total = 0, 0, 0
    for _, bag in ipairs(BAGS) do
        local holder = bagFrames[bag]
        local size = GetContainerNumSlots(bag)
        for slot = 1, size do
            local button = SlotButton(bag, slot)
            local column = mod(index, COLUMNS)
            local row = floor(index / COLUMNS)
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING + column * (SLOT + SPACING), -TITLE_HEIGHT - row * (SLOT + SPACING))
            UpdateSlot(button, bag, slot)
            if not GetContainerItemInfo(bag, slot) then
                free = free + 1
            end
            index = index + 1
        end
        total = total + size
        for slot = size + 1, getn(holder.slots) do
            holder.slots[slot]:Hide()
        end
    end
    local rows = max(1, ceil(index / COLUMNS))
    frame:SetWidth(PADDING * 2 + COLUMNS * SLOT + (COLUMNS - 1) * SPACING)
    frame:SetHeight(TITLE_HEIGHT + rows * SLOT + (rows - 1) * SPACING + FOOTER_HEIGHT + 4)
    frame.title:SetText((UnitName("player") or L["Hero"]) .. L["'s Bags"])
    frame.free:SetText(free .. L[" of "] .. total .. L[" slots free"])
    MoneyFrame_Update("VanillaBonkBagsMoney", GetMoney())
end

local function UpdateBag(bag)
    local holder = bagFrames[bag]
    if not holder then
        return
    end
    for slot = 1, GetContainerNumSlots(bag) do
        if holder.slots[slot] then
            UpdateSlot(holder.slots[slot], bag, slot)
        end
    end
end

local function OpenBags()
    Layout()
    frame:Show()
end

local function CloseBags()
    frame:Hide()
end

local function ToggleBags()
    if frame:IsShown() then
        CloseBags()
    else
        OpenBags()
    end
end

local OriginalToggleBag, OriginalOpenBag, OriginalCloseBag = ToggleBag, OpenBag, CloseBag
local function IsCarried(id)
    return id and id >= 0 and id <= 4
end
function ToggleBag(id)
    if IsCarried(id) then
        ToggleBags()
    else
        OriginalToggleBag(id)
    end
end
function OpenBag(id)
    if IsCarried(id) then
        OpenBags()
    else
        OriginalOpenBag(id)
    end
end
function CloseBag(id)
    if IsCarried(id) then
        CloseBags()
    else
        OriginalCloseBag(id)
    end
end
function ToggleBackpack()
    ToggleBags()
end
function OpenBackpack()
    OpenBags()
end
function CloseBackpack()
    CloseBags()
end
function OpenAllBags(forceOpen)
    if frame:IsShown() and not forceOpen then
        CloseBags()
    else
        OpenBags()
    end
end
function CloseAllBags()
    CloseBags()
end

local events = CreateFrame("Frame")
events:RegisterEvent("BAG_UPDATE")
events:RegisterEvent("ITEM_LOCK_CHANGED")
events:RegisterEvent("BAG_UPDATE_COOLDOWN")
events:RegisterEvent("PLAYER_MONEY")
events:SetScript("OnEvent", function()
    if not frame:IsShown() then
        return
    end
    if event == "BAG_UPDATE" then
        Layout()
    elseif event == "PLAYER_MONEY" then
        MoneyFrame_Update("VanillaBonkBagsMoney", GetMoney())
    else
        for _, bag in ipairs(BAGS) do
            UpdateBag(bag)
        end
    end
end)

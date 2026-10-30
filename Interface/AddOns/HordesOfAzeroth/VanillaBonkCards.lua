local L = VanillaBonkL
local UI = VanillaBonkUI

local SIZE = 24
local GAP = 4
local PER_ROW = 10
local NUMBER_COLOR = { 1, 1, 1 }
local LABEL_HEIGHT = 16
local LEY_RARITY = 2

local held = {}
local tips = {}
local cooldowns = {}
local states = {}
local leys = {}
local incomingLeys

local holder = CreateFrame("Frame", "VanillaBonkCards", UIParent)
holder:SetWidth(PER_ROW * (SIZE + GAP))
holder:SetHeight(SIZE + 16)
holder:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", 89, -82)
holder:Hide()

function UI.PlaceDarkmoonCards(withoutUnitFrame)
    holder:ClearAllPoints()
    if withoutUnitFrame then
        holder:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -20)
    else
        holder:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", 89, -82)
    end
end

holder.label = UI.Text(holder, 11)
holder.label:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
holder.label:SetTextColor(1, 0.82, 0)
holder.label:SetText(L["Darkmoon Cards"])

holder.leyLabel = UI.Text(holder, 11)
holder.leyLabel:SetTextColor(1, 0.82, 0)
holder.leyLabel:SetText(L["Ley Lines"])

local buttons = {}
local leyButtons = {}

local function CardTooltip(owner, index, anchor)
    local card = held[index]
    if not card then
        return
    end
    local tip = tips[card.id] or {}
    local color = UI.RARITY[card.rarity] or UI.RARITY[0]
    GameTooltip:SetOwner(owner, anchor or "ANCHOR_BOTTOMRIGHT")
    GameTooltip:AddLine(tip.name or L["Darkmoon Card"], color.r, color.g, color.b)
    local copies = ""
    if card.maxCopies > 1 then
        copies = card.copies .. "/" .. card.maxCopies .. L[" copies"]
    elseif card.copies > 1 then
        copies = "x" .. card.copies
    end
    GameTooltip:AddDoubleLine(color.name .. L[" Darkmoon Card"], copies, 0.6, 0.6, 0.6, 1, 1, 1)
    if tip.description and tip.description ~= "" then
        GameTooltip:AddLine(tip.description, 1, 0.82, 0, 1)
    end
    if states[card.id] then
        GameTooltip:AddLine(states[card.id], 0.1, 1, 0.1, 1)
    end
    GameTooltip:Show()
end

local function ShowTooltip(button)
    CardTooltip(button, button.index)
end

function UI.DarkmoonCardTooltip(owner, index)
    CardTooltip(owner, index, "ANCHOR_RIGHT")
end

function UI.HeldDarkmoonCards()
    return held
end

local function PlaceInGrid(button, index, top)
    local row = floor((index - 1) / PER_ROW)
    local column = mod(index - 1, PER_ROW)
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", holder, "TOPLEFT", column * (SIZE + GAP) + 2, -top - LABEL_HEIGHT - row * (SIZE + GAP))
end

local function GridHeight(count)
    return LABEL_HEIGHT + ceil(count / PER_ROW) * (SIZE + GAP)
end

local function StyledButton()
    local button = CreateFrame("Button", nil, holder)
    button:SetWidth(SIZE)
    button:SetHeight(SIZE)

    button.rarity = button:CreateTexture(nil, "BACKGROUND")
    button.rarity:SetTexture(UI.FLAT)
    button.rarity:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2)
    button.rarity:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
    button.edge = button:CreateTexture(nil, "BORDER")
    button.edge:SetTexture(UI.FLAT)
    button.edge:SetVertexColor(0, 0, 0)
    button.edge:SetPoint("TOPLEFT", button, "TOPLEFT", -1, 1)
    button.edge:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, -1)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints(button)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
    button.highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    button.highlight:SetBlendMode("ADD")
    button.highlight:SetAllPoints(button)
    button.cooldown = CreateFrame("Model", nil, button, "CooldownFrameTemplate")
    button.cooldown:ClearAllPoints()
    button.cooldown:SetWidth(SIZE)
    button.cooldown:SetHeight(SIZE)
    button.cooldown:SetPoint("CENTER", button, "CENTER", 0, -1)
    button.cooldown:Hide()
    local top = CreateFrame("Frame", nil, button)
    top:SetAllPoints(button)
    top:SetFrameLevel(button:GetFrameLevel() + 3)
    button.timer = UI.Text(top, 12, UI.NUMBER_FONT, "OUTLINE")
    button.timer:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.timer:SetTextColor(1, 0.82, 0)

    button.count = UI.Text(top, 12, UI.NUMBER_FONT, "OUTLINE")
    button.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, 0)
    button.count:SetTextColor(NUMBER_COLOR[1], NUMBER_COLOR[2], NUMBER_COLOR[3])

    button.value = UI.Text(top, 10, UI.NUMBER_FONT, "OUTLINE")
    button.value:SetPoint("BOTTOM", button, "BOTTOM", 0, -2)
    button.value:SetTextColor(0.1, 1, 0.1)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return button
end

local function Button(index)
    local button = StyledButton()
    PlaceInGrid(button, index, 0)
    button.index = index
    button:SetScript("OnEnter", function() ShowTooltip(this) end)
    buttons[index] = button
    return button
end

local function LeyTooltip(button)
    local ley = leys[button.index]
    if not ley then
        return
    end
    GameTooltip:SetOwner(button, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:AddLine(ley.name, 1, 1, 1)
    GameTooltip:AddLine(L["Ley Line blessing"], 0.6, 0.6, 0.6)
    GameTooltip:AddLine(ley.text, 1, 0.82, 0, 1)
    GameTooltip:Show()
end

local function LeyButton(index)
    local button = StyledButton()
    button.index = index
    button:SetScript("OnEnter", function() LeyTooltip(this) end)
    leyButtons[index] = button
    return button
end

local function ValueOf(state)
    if not state then
        return ""
    end
    local _, _, number = string.find(state, "(%d+%.?%d*)")
    return number or ""
end

local function Refresh()
    local count = getn(held)
    for index = 1, max(count, getn(buttons)) do
        local card = held[index]
        local button = buttons[index] or (card and Button(index))
        if card then
            local color = UI.RARITY[card.rarity] or UI.RARITY[0]
            button.rarity:SetVertexColor(color.r, color.g, color.b)
            button.icon:SetTexture(UI.ICON_PATH .. (card.icon ~= "" and card.icon or "INV_Misc_QuestionMark"))
            button.count:SetText(card.copies > 1 and card.copies or "")
            button.value:SetText(ValueOf(states[card.id]))
            local cooldown = cooldowns[card.id]
            if cooldown and GetTime() < cooldown.start + cooldown.total then
                CooldownFrame_SetTimer(button.cooldown, cooldown.start, cooldown.total, 1)
            else
                button.cooldown:Hide()
                button.timer:SetText("")
            end
            button:Show()
        elseif button then
            button:Hide()
        end
    end
    local leyTop = count > 0 and GridHeight(count) or 0
    local leyCount = getn(leys)
    local leyColor = UI.RARITY[LEY_RARITY]
    for index = 1, max(leyCount, getn(leyButtons)) do
        local ley = leys[index]
        local button = leyButtons[index] or (ley and LeyButton(index))
        if ley then
            PlaceInGrid(button, index, leyTop)
            button.rarity:SetVertexColor(leyColor.r, leyColor.g, leyColor.b)
            button.icon:SetTexture(UI.ICON_PATH .. (ley.icon ~= "" and ley.icon or "INV_Misc_QuestionMark"))
            button.value:SetText(ValueOf(ley.text))
            button:Show()
        elseif button then
            button:Hide()
        end
    end
    holder.leyLabel:ClearAllPoints()
    holder.leyLabel:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, -leyTop)
    if count > 0 then
        holder.label:Show()
    else
        holder.label:Hide()
    end
    if leyCount > 0 then
        holder.leyLabel:Show()
    else
        holder.leyLabel:Hide()
    end
    if count > 0 or leyCount > 0 then
        holder:SetHeight(leyTop + (leyCount > 0 and GridHeight(leyCount) or 0))
        holder:Show()
    else
        holder:Hide()
    end
end

holder:SetScript("OnUpdate", function()
    this.elapsed = (this.elapsed or 0) + arg1
    if this.elapsed < 0.1 then
        return
    end
    this.elapsed = 0
    local now = GetTime()
    for index, card in ipairs(held) do
        local cooldown = cooldowns[card.id]
        local button = buttons[index]
        if button then
            local left = cooldown and cooldown.start + cooldown.total - now or 0
            button.timer:SetText(left > 0 and ceil(left) or "")
        end
    end
end)

local handlers = {}

handlers["cards"] = function(f)
    held = {}
    for _, item in ipairs(f[2] and f[2] ~= "" and UI.Split(f[2], ",") or {}) do
        local parts = UI.Split(item, ":")
        if parts[1] and parts[1] ~= "" then
            tinsert(held, {
                id = parts[1],
                copies = tonumber(parts[2] or "") or 1,
                rarity = tonumber(parts[3] or "") or 0,
                icon = parts[4] or "",
                maxCopies = tonumber(parts[5] or "") or 0,
            })
        end
    end
    Refresh()
end

handlers["cardtip"] = function(f)
    if f[2] and f[2] ~= "" then
        tips[f[2]] = { name = f[3] or "", description = f[4] or "" }
    end
end

handlers["cardcd"] = function(f)
    local id = f[2]
    local left = (tonumber(f[3] or "") or 0) / 1000
    local total = (tonumber(f[4] or "") or 0) / 1000
    if not id or id == "" then
        return
    end
    if left <= 0 or total <= 0 then
        cooldowns[id] = nil
    else
        cooldowns[id] = { start = GetTime() - (total - left), total = total }
    end
    Refresh()
end

handlers["cardnow"] = function(f)
    local id = f[2]
    if not id or id == "" then
        return
    end
    states[id] = (f[3] and f[3] ~= "") and f[3] or nil
    for index, card in ipairs(held) do
        local button = buttons[index]
        if card.id == id and button then
            button.value:SetText(ValueOf(states[id]))
            if GameTooltip:IsOwned(button) then
                ShowTooltip(button)
            end
        end
    end
end

handlers["leyblessings"] = function()
    incomingLeys = {}
end

handlers["leybless"] = function(f)
    if incomingLeys then
        tinsert(incomingLeys, { name = f[2] or "", icon = f[3] or "", text = f[4] or "" })
    end
end

handlers["leyblessend"] = function()
    if incomingLeys then
        leys = incomingLeys
        incomingLeys = nil
        Refresh()
    end
end

local function Clear()
    held = {}
    cooldowns = {}
    states = {}
    leys = {}
    Refresh()
end
handlers["start"] = Clear
handlers["end"] = Clear

UI.Listen(handlers)

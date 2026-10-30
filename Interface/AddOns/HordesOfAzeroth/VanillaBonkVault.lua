local UI = VanillaBonkUI

local CARD_WIDTH = 118
local CARD_HEIGHT = 168
local CARD_GAP = 10
local PER_ROW = 8
local PER_PAGE = PER_ROW * 2
local SLOT_SIZE = 52
local CARDS_TOP = 40
local CARDS_ROOM = 320
local WALK_AWAY = 3
local SAVED_LABEL = "Your saved piece"
local RETRY, RETRIES = 0.25, 12
local STONE_BORDER = { edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 24 }

local ARROW_UP = "Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up"
local ARROW_DOWN = "Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up"

local vault = { slots = 1, chosen = {}, order = {}, finds = {}, pillar = false, page = 1 }
local incoming

local function Command(text)
    SendChatMessage(".bonk vault " .. text, "SAY")
end

local function QualityColor(quality)
    local color = UI.RARITY[quality - 1] or UI.RARITY[1]
    return color.r, color.g, color.b
end

local frame = CreateFrame("Frame", "VanillaBonkVault", UIParent)
frame:SetAllPoints(UIParent)
frame:SetFrameStrata("DIALOG")
frame:Hide()
tinsert(UISpecialFrames, "VanillaBonkVault")

frame.dim = frame:CreateTexture(nil, "BACKGROUND")
frame.dim:SetTexture("Interface\\AddOns\\HordesOfAzeroth\\Textures\\OfferVignette")
frame.dim:SetPoint("TOPLEFT", WorldFrame, "TOPLEFT", -2, 2)
frame.dim:SetPoint("BOTTOMRIGHT", WorldFrame, "BOTTOMRIGHT", 2, -2)
frame.dim:SetVertexColor(0, 0, 0, 1)

frame.title = frame:CreateFontString(nil, "OVERLAY")
frame.title:SetFont(UI.TITLE_FONT, 40, "OUTLINE")
frame.title:SetPoint("CENTER", frame, "CENTER", 0, 262)
frame.title:SetTextColor(1, 0.82, 0)
frame.title:SetText("Extraction Vault")

frame.subtitle = UI.Text(frame, 13)
frame.subtitle:SetPoint("CENTER", frame, "CENTER", 0, 226)
frame.subtitle:SetTextColor(0.9, 0.83, 0.64)

for side = 1, 2 do
    local line = frame:CreateTexture(nil, "ARTWORK")
    line:SetTexture(UI.FLAT)
    line:SetWidth(60)
    line:SetHeight(1)
    if side == 1 then
        line:SetPoint("RIGHT", frame.subtitle, "LEFT", -12, 0)
        line:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0, 1, 0.82, 0, 0.7)
    else
        line:SetPoint("LEFT", frame.subtitle, "RIGHT", 12, 0)
        line:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0.7, 1, 0.82, 0, 0)
    end
end

frame.box = CreateFrame("Frame", nil, frame)
frame.box:SetHeight(128)
frame.box:SetPoint("CENTER", frame, "CENTER", 0, 132)
frame.box:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", tile = true, tileSize = 32,
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border", edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
frame.box.label = UI.Text(frame.box, 12)
frame.box.label:SetPoint("TOP", frame.box, "TOP", 0, -16)
frame.box.label:SetTextColor(1, 0.82, 0)
frame.box.label:SetText("Mailed to you when you leave")
frame.box.slots = {}

local function CursorOnRightHalf()
    local x = GetCursorPosition()
    return x / UIParent:GetEffectiveScale() > GetScreenWidth() / 2
end

local function ShowSaved(find)
    local onLeft = CursorOnRightHalf()
    local previous = GameTooltip
    for index = 1, min(2, getn(find.saved)) do
        local tooltip = getglobal("ShoppingTooltip" .. index)
        if not tooltip then
            return
        end
        tooltip:SetOwner(GameTooltip, "ANCHOR_NONE")
        tooltip:ClearAllPoints()
        local gap = previous == GameTooltip and -10 or 0
        if onLeft then
            tooltip:SetPoint("TOPRIGHT", previous, "TOPLEFT", 0, gap)
        else
            tooltip:SetPoint("TOPLEFT", previous, "TOPRIGHT", 0, gap)
        end
        local link = "item:" .. find.saved[index] .. ":0:0:0"
        tooltip:SetHyperlink(link)
        if VanillaBonk_AddGearLines then
            VanillaBonk_AddGearLines(tooltip, link)
        end
        tooltip:AddLine(" ")
        tooltip:AddLine(SAVED_LABEL, 1, 0.82, 0)
        tooltip:AddLine("You came into the run with it.", 0.7, 0.7, 0.7)
        tooltip:Show()
        previous = tooltip
    end
end

local function WorthText(find)
    local parts = {}
    if find.sell > 0 then
        tinsert(parts, UI.FormatGold(find.sell))
    end
    if find.scrap > 0 then
        tinsert(parts, find.scrap .. " Scrap")
    end
    return table.concat(parts, " and ")
end

local function LeftOutText(gold, scrap)
    if gold > 0 and scrap > 0 then
        return "sells for " .. UI.FormatGold(gold) .. " and gives " .. scrap .. " Scrap"
    elseif scrap > 0 then
        return "gives " .. scrap .. " Scrap"
    end
    return "sells for " .. UI.FormatGold(gold)
end

local function ShowItemTooltip(owner, find, line)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    UI.nextFound = find.found
    GameTooltip:SetHyperlink("item:" .. find.entry .. ":0:0:0")
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(line, 1, 0.82, 0)
    if find.owned then
        GameTooltip:AddLine("You already own this piece at this tier.", 1, 0.5, 0.25)
    elseif find.tier > 0 and find.best > 0 then
        GameTooltip:AddLine("Your best for this slot: Tier " .. find.best .. ".", 0.7, 0.7, 0.7)
    end
    if not vault.pillar then
        local text = LeftOutText(find.sell, find.scrap)
        GameTooltip:AddLine(strupper(strsub(text, 1, 1)) .. strsub(text, 2) .. " if you leave it out of the vault.", 0.7, 0.7, 0.7)
    end
    if getn(find.saved) == 0 then
        GameTooltip:AddLine("You have nothing saved in this slot.", 0.7, 0.7, 0.7)
    end
    GameTooltip:Show()
    ShowSaved(find)
end

local function VaultSlot(index)
    local slot = frame.box.slots[index]
    if slot then
        return slot
    end
    slot = UI.Slot(frame.box, SLOT_SIZE)
    slot.glow = slot:CreateTexture(nil, "OVERLAY")
    slot.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    slot.glow:SetBlendMode("ADD")
    slot.glow:SetWidth(SLOT_SIZE * 96 / 56)
    slot.glow:SetHeight(SLOT_SIZE * 96 / 56)
    slot.glow:SetPoint("CENTER", slot, "CENTER", 0, 0)
    slot.caption = UI.Text(frame.box, 10)
    slot.caption:SetPoint("TOP", slot, "BOTTOM", 0, -6)
    slot.caption:SetWidth(130)
    slot:SetScript("OnClick", function()
        if this.find then
            PlaySound("igMainMenuOptionCheckBoxOff")
            Command("take " .. this.find.guid)
        end
    end)
    slot:SetScript("OnEnter", function()
        if this.find then
            ShowItemTooltip(this, this.find, "Click to take it out of the vault.")
        else
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Empty", 1, 1, 1)
            GameTooltip:AddLine("Click an item below to put it in the vault.", 1, 0.82, 0, 1)
            GameTooltip:Show()
        end
    end)
    slot:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame.box.slots[index] = slot
    return slot
end

local SENT_SLOT_SIZE = 40
local SENT_SPACING = 70
local SENT_SHOWN = 8

frame.sent = CreateFrame("Frame", nil, frame)
frame.sent:SetHeight(128)
frame.sent:SetPoint("CENTER", frame, "CENTER", 0, 132)
frame.sent:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", tile = true, tileSize = 32,
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border", edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
frame.sent.label = UI.Text(frame.sent, 12)
frame.sent.label:SetPoint("TOP", frame.sent, "TOP", 0, -16)
frame.sent.label:SetTextColor(1, 0.82, 0)
frame.sent.label:SetText("Sent home this run")
frame.sent.empty = UI.Text(frame.sent, 11)
frame.sent.empty:SetPoint("CENTER", frame.sent, "CENTER", 0, -8)
frame.sent.empty:SetTextColor(0.62, 0.62, 0.62)
frame.sent.empty:SetText("Nothing yet. Each pillar sends 1 piece.")
frame.sent.slots = {}
frame.sent:Hide()

local function SentSlot(index)
    local slot = frame.sent.slots[index]
    if slot then
        return slot
    end
    slot = UI.Slot(frame.sent, SENT_SLOT_SIZE)
    slot.caption = UI.Text(frame.sent, 10)
    slot.caption:SetPoint("TOP", slot, "BOTTOM", 0, -5)
    slot.caption:SetTextColor(0.8, 0.8, 0.8)
    slot:SetScript("OnEnter", function()
        if this.piece then
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("item:" .. this.piece.entry .. ":0:0:0")
            GameTooltip:AddLine("Sent home on floor " .. this.piece.floor .. ".", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end
    end)
    slot:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame.sent.slots[index] = slot
    return slot
end

local function ShowSent()
    local pieces = vault.sent or {}
    local count = getn(pieces)
    local first = max(1, count - SENT_SHOWN + 1)
    local shown = count - first + 1
    frame.sent:SetWidth(max(300, 40 + max(shown, 1) * SENT_SPACING))
    if count == 0 then
        frame.sent.empty:Show()
    else
        frame.sent.empty:Hide()
    end
    for index = 1, max(SENT_SHOWN, getn(frame.sent.slots)) do
        local slot = SentSlot(index)
        local piece = index <= shown and pieces[first + index - 1] or nil
        slot.piece = piece
        if piece then
            local _, _, _, _, _, _, _, _, texture = GetItemInfo(piece.entry)
            slot.icon:SetTexture(texture or (UI.ICON_PATH .. "INV_Misc_QuestionMark"))
            slot.icon:Show()
            slot:ClearAllPoints()
            slot:SetPoint("TOP", frame.sent, "TOP", (index - (shown + 1) / 2) * SENT_SPACING, -40)
            slot.caption:SetText("Floor " .. piece.floor)
            slot:Show()
            slot.caption:Show()
        else
            slot:Hide()
            slot.caption:Hide()
        end
    end
    frame.sent:Show()
end

frame.cards = CreateFrame("Frame", nil, frame)
frame.cards.list = {}

local function Card(index)
    local card = frame.cards.list[index]
    if card then
        return card
    end
    card = CreateFrame("Button", nil, frame.cards)
    card:SetWidth(CARD_WIDTH)
    card:SetHeight(CARD_HEIGHT)
    card:SetBackdrop(STONE_BORDER)
    card.bg = card:CreateTexture(nil, "BACKGROUND")
    card.bg:SetTexture(UI.FLAT)
    card.bg:SetPoint("TOPLEFT", card, "TOPLEFT", 7, -7)
    card.bg:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -7, 7)
    card.bg:SetGradientAlpha("VERTICAL", 0.02, 0.02, 0.01, 0.95, 0.12, 0.09, 0.06, 0.9)
    card.line = CreateFrame("Frame", nil, card)
    card.line:SetPoint("TOPLEFT", card, "TOPLEFT", 6, -6)
    card.line:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -6, 6)
    card.line:SetBackdrop({ edgeFile = UI.FLAT, edgeSize = 1 })

    card.slot = UI.Slot(card, 40, "Frame")
    card.slot:SetPoint("TOP", card, "TOP", 0, -22)
    card.name = UI.Text(card, 11)
    card.name:SetPoint("TOP", card, "TOP", 0, -72)
    card.name:SetWidth(CARD_WIDTH - 20)
    card.where = UI.Text(card, 10)
    card.where:SetPoint("TOP", card, "TOP", 0, -104)
    card.where:SetTextColor(0.63, 0.63, 0.63)
    card.saved = UI.Text(card, 10)
    card.saved:SetPoint("TOP", card, "TOP", 0, -118)
    card.saved:SetWidth(CARD_WIDTH - 16)
    card.saved:SetHeight(24)
    card.saved:SetJustifyV("TOP")
    card.price = UI.Text(card, 12, UI.NUMBER_FONT)
    card.price:SetPoint("BOTTOM", card, "BOTTOM", 0, 12)

    card.tier = UI.Text(card, 10)
    card.tier:SetPoint("TOPLEFT", card, "TOPLEFT", 11, -10)
    card.tier:SetTextColor(1, 0.82, 0)
    card.arrow = card:CreateTexture(nil, "OVERLAY")
    card.arrow:SetWidth(14)
    card.arrow:SetHeight(14)
    card.arrow:SetTexCoord(0.25, 0.75, 0.25, 0.75)
    card.arrow:SetPoint("LEFT", card.tier, "RIGHT", 1, 0)
    card.owned = UI.Text(card, 10)
    card.owned:SetPoint("TOPRIGHT", card, "TOPRIGHT", -11, -10)
    card.owned:SetTextColor(1, 0.5, 0.25)
    card.owned:SetText("Owned")

    card.ribbon = card:CreateTexture(nil, "OVERLAY")
    card.ribbon:SetTexture(UI.FLAT)
    card.ribbon:SetVertexColor(0, 0, 0, 0.8)
    card.ribbon:SetHeight(20)
    card.ribbon:SetPoint("LEFT", card, "LEFT", 6, 4)
    card.ribbon:SetPoint("RIGHT", card, "RIGHT", -6, 4)
    card.ribbonText = UI.Text(card, 11)
    card.ribbonText:SetPoint("CENTER", card.ribbon, "CENTER", 0, 0)
    card.ribbonText:SetTextColor(1, 0.82, 0)
    card.ribbonText:SetText("In the vault")

    card.highlight = card:CreateTexture(nil, "HIGHLIGHT")
    card.highlight:SetTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
    card.highlight:SetBlendMode("ADD")
    card.highlight:SetTexCoord(0, 0.625, 0, 0.6875)
    card.highlight:SetAlpha(0.3)
    card.highlight:SetAllPoints(card.bg)

    card:SetScript("OnClick", function()
        local find = this.find
        if not find then
            return
        end
        if vault.pillar then
            PlaySound("igMainMenuOptionCheckBoxOn")
            Command("send " .. find.guid)
        elseif vault.chosen[find.guid] then
            PlaySound("igMainMenuOptionCheckBoxOff")
            Command("take " .. find.guid)
        else
            PlaySound("igMainMenuOptionCheckBoxOn")
            Command("put " .. find.guid)
        end
    end)
    card:SetScript("OnEnter", function()
        local find = this.find
        if find then
            local line = vault.chosen[find.guid] and "Click to take it out of the vault." or "Click to put it in the vault."
            ShowItemTooltip(this, find, vault.pillar and "Click to send it home now." or line)
        end
    end)
    card:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame.cards.list[index] = card
    return card
end

frame.rest = UI.Text(frame, 12)
frame.hint = UI.Text(frame, 11)
frame.hint:SetTextColor(0.72, 0.72, 0.72)
frame.done = UI.Button(frame, 100, "Done", function()
    frame:Hide()
end)
frame.pageText = UI.Text(frame, 12)
frame.pageText:SetTextColor(1, 0.82, 0)

local function SavedText(find)
    if getn(find.saved) == 0 then
        return "|cff9d9d9dYours: nothing|r", true
    end
    local names = {}
    for _, entry in ipairs(find.saved) do
        local name, _, quality = GetItemInfo(entry)
        if not name then
            return "", false
        end
        local r, g, b = QualityColor(quality or 2)
        tinsert(names, format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, name))
    end
    return "|cff9d9d9dYours:|r " .. table.concat(names, ", "), true
end

local function FillCard(card, find)
    local name, _, _, _, _, _, _, _, texture = GetItemInfo(find.entry)
    local r, g, b = QualityColor(find.quality)
    card.find = find
    card.slot.icon:SetTexture(texture or (UI.ICON_PATH .. "INV_Misc_QuestionMark"))
    card.name:SetText(name or "")
    card.name:SetTextColor(r, g, b)
    card.where:SetText(find.worn and "Equipped" or "In bags")
    local saved, savedKnown = SavedText(find)
    card.saved:SetText(saved)
    card.price:SetText(vault.pillar and "" or WorthText(find))
    if find.tier > 0 then
        local lines = find.found and table.getn(find.found.lines) or 0
        card.tier:SetText(UI.TierText(find.tier) .. (lines > 0 and ("  |cffff66cc+" .. lines .. "|r") or ""))
        card.tier:Show()
    else
        card.tier:Hide()
    end
    if find.tier > 0 and find.tier ~= find.best then
        local better = find.tier > find.best
        card.arrow:SetTexture(better and ARROW_UP or ARROW_DOWN)
        card.arrow:SetVertexColor(better and 0.2 or 1, better and 1 or 0.25, better and 0.2 or 0.25)
        card.arrow:Show()
    else
        card.arrow:Hide()
    end
    if find.owned then
        card.owned:Show()
    else
        card.owned:Hide()
    end
    card:SetBackdropBorderColor(r, g, b)
    card.line:SetBackdropBorderColor(r, g, b, 0.8)
    if vault.chosen[find.guid] then
        card:SetAlpha(0.45)
        card.ribbon:Show()
        card.ribbonText:Show()
    else
        card:SetAlpha(1)
        card.ribbon:Hide()
        card.ribbonText:Hide()
    end
    return name ~= nil and savedKnown
end

local function ShownOrder()
    local shown = {}
    for _, find in ipairs(vault.finds) do
        tinsert(shown, find)
    end
    table.sort(shown, function(a, b)
        if a.tier ~= b.tier then
            return a.tier > b.tier
        end
        if a.quality ~= b.quality then
            return a.quality > b.quality
        end
        if a.sell ~= b.sell then
            return a.sell > b.sell
        end
        return a.scrap > b.scrap
    end)
    return shown
end

local Refresh

local function TurnPage(step)
    vault.page = vault.page + step
    PlaySound("igMainMenuOptionCheckBoxOn")
    Refresh()
end

frame.prev = UI.Button(frame, 90, "Previous", function() TurnPage(-1) end)
frame.next = UI.Button(frame, 90, "Next", function() TurnPage(1) end)

function Refresh()
    local slots = max(1, vault.slots)
    frame.title:SetText(vault.pillar and "Extraction Pillar" or "Extraction Vault")
    if vault.pillar then
        frame.subtitle:SetText("1 piece goes home right now. It leaves your character.")
        frame.box:Hide()
        ShowSent()
    else
        frame.sent:Hide()
        frame.subtitle:SetText(slots == 1 and "1 piece comes home with you." or slots .. " pieces come home with you.")
        frame.box:Show()
    end

    local byGuid = {}
    for _, find in ipairs(vault.finds) do
        byGuid[find.guid] = find
    end
    local inVault = {}
    for _, guid in ipairs(vault.order) do
        if byGuid[guid] then
            tinsert(inVault, byGuid[guid])
        end
    end
    frame.box:SetWidth(slots == 1 and 220 or 300)
    for index = 1, max(slots, getn(frame.box.slots)) do
        local slot = VaultSlot(index)
        if index > slots then
            slot:Hide()
            slot.caption:Hide()
        else
            local find = inVault[index]
            slot:ClearAllPoints()
            slot:SetPoint("TOP", frame.box, "TOP", (index - (slots + 1) / 2) * 104, -36)
            slot.find = find
            if find then
                local name, _, _, _, _, _, _, _, texture = GetItemInfo(find.entry)
                local r, g, b = QualityColor(find.quality)
                slot.icon:SetTexture(texture or (UI.ICON_PATH .. "INV_Misc_QuestionMark"))
                slot.icon:Show()
                slot.glow:SetVertexColor(r, g, b)
                slot.glow:Show()
                slot.caption:SetText(name or "")
                slot.caption:SetTextColor(r, g, b)
            else
                slot.icon:Hide()
                slot.glow:Hide()
                slot.caption:SetText(index == 2 and "Empty (Pack Mule)" or "Empty")
                slot.caption:SetTextColor(0.62, 0.62, 0.62)
            end
            slot:Show()
            slot.caption:Show()
        end
    end

    local shown = ShownOrder()
    local total = getn(shown)
    local pages = max(1, ceil(total / PER_PAGE))
    vault.page = max(1, min(vault.page, pages))
    local first = (vault.page - 1) * PER_PAGE
    local count = max(0, min(PER_PAGE, total - first))
    local perRow = max(1, min(count, PER_ROW))
    local rows = max(1, ceil(count / perRow))
    local width = perRow * CARD_WIDTH + (perRow - 1) * CARD_GAP
    local height = rows * CARD_HEIGHT + (rows - 1) * CARD_GAP
    local scale = min(1, CARDS_ROOM / height, (UIParent:GetWidth() - 60) / width)
    frame.cards:SetScale(scale)
    frame.cards:SetWidth(width)
    frame.cards:SetHeight(height)
    frame.cards:ClearAllPoints()
    frame.cards:SetPoint("TOP", frame, "CENTER", 0, CARDS_TOP / scale)
    local missing = false
    local rest, restScrap = 0, 0
    for _, find in ipairs(vault.finds) do
        if not vault.chosen[find.guid] then
            rest = rest + find.sell
            restScrap = restScrap + find.scrap
        end
    end
    restScrap = floor(restScrap * (1 + (vault.scrapBonus or 0) / 100) + 0.5)
    for index = 1, count do
        local find = shown[first + index]
        local card = Card(index)
        local row = floor((index - 1) / perRow)
        local column = mod(index - 1, perRow)
        local inRow = min(perRow, count - row * perRow)
        local x = (column - (inRow - 1) / 2) * (CARD_WIDTH + CARD_GAP)
        card:ClearAllPoints()
        card:SetPoint("TOP", frame.cards, "TOP", x, -row * (CARD_HEIGHT + CARD_GAP))
        if not FillCard(card, find) then
            missing = true
        end
        card:Show()
    end
    for index = count + 1, getn(frame.cards.list) do
        frame.cards.list[index]:Hide()
    end

    local anchor = frame.cards
    if pages > 1 then
        frame.pageText:SetText("Page " .. vault.page .. " of " .. pages .. "  (" .. total .. " items)")
        frame.pageText:ClearAllPoints()
        frame.pageText:SetPoint("TOP", frame.cards, "BOTTOM", 0, -12)
        frame.prev:ClearAllPoints()
        frame.prev:SetPoint("RIGHT", frame.pageText, "LEFT", -14, 0)
        frame.next:ClearAllPoints()
        frame.next:SetPoint("LEFT", frame.pageText, "RIGHT", 14, 0)
        if vault.page > 1 then frame.prev:Enable() else frame.prev:Disable() end
        if vault.page < pages then frame.next:Enable() else frame.next:Disable() end
        frame.pageText:Show()
        frame.prev:Show()
        frame.next:Show()
        anchor = frame.pageText
    else
        frame.pageText:Hide()
        frame.prev:Hide()
        frame.next:Hide()
    end

    frame.rest:ClearAllPoints()
    frame.rest:SetPoint("TOP", anchor, "BOTTOM", 0, -14)
    if count == 0 then
        frame.rest:SetText("|cff9d9d9dNothing found this run yet.|r")
    elseif vault.pillar then
        frame.rest:SetText("The pillar can send 1 piece.")
    else
        frame.rest:SetText("The rest " .. LeftOutText(rest, restScrap) .. ".")
    end
    frame.done:ClearAllPoints()
    if vault.pillar then
        frame.hint:ClearAllPoints()
        frame.hint:SetPoint("TOP", frame.rest, "BOTTOM", 0, -8)
        frame.hint:SetText("Click an item to send it home now. It leaves your character for the rest of the run.")
        frame.hint:Show()
        frame.done:SetPoint("TOP", frame.hint, "BOTTOM", 0, -12)
    else
        frame.hint:Hide()
        frame.done:SetPoint("TOP", frame.rest, "BOTTOM", 0, -12)
    end

    if missing then
        frame.retries = frame.retries or RETRIES
        frame.retryIn = RETRY
    else
        frame.retries = nil
    end
end

local function HeroSpot()
    if not UnitPosition then
        return nil
    end
    local x, y = UnitPosition("player")
    return x, y
end

frame:SetScript("OnUpdate", function()
    if this.retries and this.retries > 0 then
        this.retryIn = this.retryIn - arg1
        if this.retryIn <= 0 then
            this.retries = this.retries - 1
            Refresh()
        end
    end
    if this.openedAt then
        local x, y = HeroSpot()
        if x then
            local dx, dy = x - this.openedAt[1], y - this.openedAt[2]
            if dx * dx + dy * dy > WALK_AWAY * WALK_AWAY then
                this:Hide()
            end
        end
    end
end)

frame:SetScript("OnShow", function()
    PlaySound("igMainMenuOpen")
end)
frame:SetScript("OnHide", function()
    Command("close")
    this.openedAt = nil
    this.retries = nil
    GameTooltip:Hide()
    PlaySound("igMainMenuClose")
end)

local handlers = {}

handlers["vaultclear"] = function()
    incoming = {}
end

local function SavedEntries(field)
    local entries = {}
    for _, text in ipairs(UI.Split(field or "", ",")) do
        local entry = tonumber(text)
        if entry then
            tinsert(entries, entry)
        end
    end
    return entries
end

handlers["vaultsent"] = function(f)
    vault.sent = {}
    for _, text in ipairs(UI.Split(f[2] or "", ",")) do
        local _, _, entry, floor = string.find(text, "^(%d+):(%d+)$")
        if entry then
            tinsert(vault.sent, { entry = tonumber(entry), floor = tonumber(floor) })
        end
    end
end

handlers["vaultitem"] = function(f)
    local guid, entry = f[2], tonumber(f[3] or "")
    if not incoming or not guid or guid == "" or not entry then
        return
    end
    tinsert(incoming, {
        guid = guid,
        entry = entry,
        quality = tonumber(f[4] or "") or 2,
        worn = f[5] == "1",
        sell = tonumber(f[6] or "") or 0,
        saved = SavedEntries(f[7]),
        tier = tonumber(f[8] or "") or 0,
        best = tonumber(f[9] or "") or 0,
        owned = f[10] == "1",
        scrap = tonumber(f[11] or "") or 0,
        found = UI.ParseFound(f[8], f[12], f[13]),
    })
end

handlers["vaultopen"] = function(f)
    vault.slots = tonumber(f[2] or "") or 1
    vault.pillar = f[4] == "pillar"
    vault.scrapBonus = tonumber(f[5] or "") or 0
    vault.chosen, vault.order = {}, {}
    for _, guid in ipairs(UI.Split(f[3] or "", ",")) do
        if guid ~= "" then
            vault.chosen[guid] = true
            tinsert(vault.order, guid)
        end
    end
    if incoming then
        vault.finds = incoming
        incoming = nil
    end
    frame.retries = nil
    Refresh()
    if not frame:IsShown() then
        local x, y = HeroSpot()
        frame.openedAt = x and { x, y } or nil
        vault.page = 1
        frame:Show()
    end
end

handlers["vaultclose"] = function()
    frame:Hide()
end

handlers["end"] = function()
    frame:Hide()
    vault.finds, vault.chosen, vault.order = {}, {}, {}
end

UI.Listen(handlers)

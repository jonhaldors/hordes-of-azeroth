local L = VanillaBonkL
local UI = VanillaBonkUI

VanillaBonkDeck = {}
local Deck = VanillaBonkDeck

local W, H = 980, 610
local GRID_X, GRID_TOP, GRID_WIDTH = 22, 128, 652
local SIDE_X = GRID_X + GRID_WIDTH + 18
local SIDE_WIDTH = W - SIDE_X - 24
local COLUMNS = 6
local CARD_W, CARD_H, CARD_GAP = 94, 130, 8
local HEADER_HEIGHT = 26
local BIG_W, BIG_H = 112, 156
local PIP_W, PIP_H, PIP_GAP = 24, 32, 7
local SOFT = { 0.78, 0.75, 0.7 }
local HAIR = { 0.47, 0.39, 0.24 }
local TITLE_COLOR = { 0.85, 0.66, 1 }
local BAN_RED = { 0.82, 0.09, 0.09 }
local BAN_MARK_SCALE = 3
local DARKMOON_CLOTH = "World\\ENVIRONMENT\\DOODAD\\Carnival\\bm_Carnie_tarp01"
local DARKMOON_BANNER = "World\\ENVIRONMENT\\DOODAD\\Carnival\\Darkmoon_Banner01"
local GLYPH_ART = "Interface\\TalentFrame\\MageArcane-TopLeft"
local KINDS = {
    { key = "c", tab = L["Darkmoon Cards"], list = "cards", noun = L["card"], bans = L["Card bans"],
        blurb = L["Every card you own can turn up in a chest. Ban the ones you never want to see."] },
    { key = "g", tab = L["Glyphs"], list = "glyphs", noun = L["Glyph"], bans = L["Glyph bans"],
        blurb = L["Every Glyph you own can be offered after a mini-boss. Ban the ones you never want to see."] },
}

local book
local kindIndex = 1
local selected = {}
local frame, grid, side

local function Kind()
    return KINDS[kindIndex]
end

local function Flat(parent, layer, r, g, b, a)
    local texture = parent:CreateTexture(nil, layer or "ARTWORK")
    texture:SetTexture(UI.FLAT)
    texture:SetVertexColor(r or 1, g or 1, b or 1, a or 1)
    return texture
end

local function Hairline(parent, width)
    local line = UI.Divider(parent, width)
    line.left:SetVertexColor(HAIR[1], HAIR[2], HAIR[3])
    line.right:SetVertexColor(HAIR[1], HAIR[2], HAIR[3])
    return line
end

local function Rarity(entry)
    return UI.RARITY[entry.rarity or 0] or UI.RARITY[0]
end

local function Entries()
    local list = {}
    for _, entry in pairs(book and book[Kind().list] or {}) do
        tinsert(list, entry)
    end
    table.sort(list, function(a, b)
        if a.rarity ~= b.rarity then
            return a.rarity < b.rarity
        end
        return a.name < b.name
    end)
    return list
end

local function Pool()
    return book and book.pool[Kind().key] or { used = 0, slots = 0 }
end

local function Bans()
    return book and book.bans[Kind().key] or {}
end

local function NextSale()
    for _, source in ipairs(Bans()) do
        if not source.earned and source.tickets > 0 then
            return source
        end
    end
end

local function SelectedEntry()
    local id = selected[Kind().key]
    local list = book and book[Kind().list]
    local entry = list and id and list[id]
    if entry then
        return entry
    end
    for _, candidate in ipairs(Entries()) do
        if candidate.owned then
            selected[Kind().key] = candidate.key or candidate.id
            return candidate
        end
    end
end

local function EntryKey(entry)
    return entry.key or entry.id
end

local function DressPanel(panel)
    panel:SetBackdropColor(0, 0, 0, 0)
    panel.art = panel:CreateTexture(nil, "BACKGROUND")
    panel.art:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
    panel.art:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -4, 4)
    panel.dim = panel:CreateTexture(nil, "BORDER")
    panel.dim:SetAllPoints(panel.art)
    UI.Shade(panel.dim, 0.88, 0.72)
end

local function SetPanelArt(panel, glyph)
    panel.art:SetTexture(glyph and GLYPH_ART or DARKMOON_CLOTH)
    panel.art:SetTexCoord(0, 1, 0, 1)
end

local function PaintCard(card, r, g, b, lineAlpha)
    card:SetBackdropBorderColor(r, g, b)
    card.line:SetBackdropBorderColor(r, g, b, lineAlpha)
end

local function StyleCardFace(card, entry)
    local rarity = Rarity(entry)
    local glyph = Kind().key == "g"
    card.entry = entry
    if glyph then
        card.art:SetTexture(GLYPH_ART)
        UI.TalentArtCoords(card.art, card:GetWidth() - 10, card:GetHeight() - 10)
        UI.Shade(card.shade, 0.95, 0.1)
        card.crest:Hide()
        card.eye:Hide()
        card.halo:Show()
        card.stone:Show()
    else
        card.art:SetTexture(DARKMOON_CLOTH)
        card.art:SetTexCoord(0, 1, 0, 1)
        UI.Shade(card.shade, 0.95, 0.4)
        card.crest:Show()
        card.eye:Show()
        card.halo:Hide()
        card.stone:Hide()
    end
    local ring = glyph and card.stone or card.eye
    local icon = entry.locked and "INV_Misc_QuestionMark" or (entry.icon ~= "" and entry.icon or "INV_Misc_QuestionMark")
    ring.icon:SetTexture(UI.ICON_PATH .. icon)
    if entry.locked then
        card.art:SetVertexColor(0.35, 0.35, 0.35)
        card.crest:SetVertexColor(0.35, 0.35, 0.35)
        card.halo:Hide()
        ring.icon:SetVertexColor(0.6, 0.6, 0.6)
        card.name:SetText("???")
        card.name:SetTextColor(0.55, 0.55, 0.55)
        PaintCard(card, 0.42, 0.42, 0.42, 0.35)
        card.ban:Hide()
    elseif entry.off then
        card.art:SetVertexColor(0.5, 0.5, 0.5)
        card.crest:SetVertexColor(0.5, 0.5, 0.5)
        card.halo:Hide()
        ring.icon:SetVertexColor(0.4, 0.4, 0.4)
        card.name:SetText(entry.name)
        card.name:SetTextColor(0.55, 0.55, 0.55)
        PaintCard(card, rarity.r * 0.5, rarity.g * 0.5, rarity.b * 0.5, 0.5)
        card.ban:Show()
    else
        card.art:SetVertexColor(1, 1, 1)
        card.crest:SetVertexColor(1, 1, 1)
        card.halo:SetVertexColor(rarity.r, rarity.g, rarity.b)
        ring.icon:SetVertexColor(1, 1, 1)
        card.name:SetText(entry.name)
        card.name:SetTextColor(rarity.r, rarity.g, rarity.b)
        PaintCard(card, rarity.r, rarity.g, rarity.b, 0.9)
        card.ban:Hide()
    end
end

local function CreateCardFace(parent, width, height)
    local card = CreateFrame("Button", nil, parent)
    card:SetWidth(width)
    card:SetHeight(height)
    card:SetBackdrop({ edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 16 })
    card.art = card:CreateTexture(nil, "BACKGROUND")
    card.art:SetPoint("TOPLEFT", card, "TOPLEFT", 5, -5)
    card.art:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -5, 5)
    card.shade = card:CreateTexture(nil, "BORDER")
    card.shade:SetAllPoints(card.art)
    card.line = CreateFrame("Frame", nil, card)
    card.line:SetPoint("TOPLEFT", card, "TOPLEFT", 5, -5)
    card.line:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -5, 5)
    card.line:SetBackdrop({ edgeFile = UI.FLAT, edgeSize = 1 })

    local crestSize = math.floor(width * 0.7)
    card.crest = card:CreateTexture(nil, "ARTWORK")
    card.crest:SetTexture(DARKMOON_BANNER)
    card.crest:SetTexCoord(8 / 256, 182 / 256, 16 / 256, 190 / 256)
    card.crest:SetWidth(crestSize)
    card.crest:SetHeight(crestSize)
    card.crest:SetPoint("TOP", card, "TOP", 0, -10)
    card.eye = UI.Ring(card, math.floor(width * 0.36), true)
    card.eye:SetPoint("CENTER", card.crest, "CENTER", 0, 0)
    card.eye.icon = UI.RingArt(card.eye, "")

    local stoneSize = math.floor(width * 0.46)
    card.halo = card:CreateTexture(nil, "ARTWORK")
    card.halo:SetTexture("Interface\\Cooldown\\star4")
    card.halo:SetBlendMode("ADD")
    card.halo:SetWidth(stoneSize * 2.2)
    card.halo:SetHeight(stoneSize * 2.2)
    card.halo:SetPoint("CENTER", card.crest, "CENTER", 0, 0)
    card.stone = UI.Ring(card, stoneSize, true)
    card.stone:SetPoint("CENTER", card.crest, "CENTER", 0, 0)
    card.stone.icon = UI.RingArt(card.stone, "")

    card.name = UI.Text(card, width >= 110 and 13 or 11)
    card.name:SetPoint("TOP", card.crest, "BOTTOM", 0, -4)
    card.name:SetWidth(width - 14)
    card.name:SetJustifyH("CENTER")
    card.banLayer = CreateFrame("Frame", nil, card)
    card.banLayer:SetAllPoints(card)
    card.banLayer:SetFrameLevel(card:GetFrameLevel() + 10)
    card.banLayer:SetScale(BAN_MARK_SCALE)
    card.ban = UI.Text(card.banLayer, math.floor(width * 1.2 / BAN_MARK_SCALE), UI.NUMBER_FONT, "THICKOUTLINE")
    card.ban:SetPoint("CENTER", card.banLayer, "CENTER", 0, 0)
    card.ban:SetTextColor(BAN_RED[1], BAN_RED[2], BAN_RED[3])
    card.ban:SetText("X")
    return card
end

local function ToggleBan(entry)
    if entry and VanillaBonkCodex.TogglePool(entry) then
        Deck.Refresh()
    end
end

local function ShowLockedTooltip(card, entry)
    local rarity = Rarity(entry)
    local lock = book.locks[Kind().key .. entry.id]
    GameTooltip:SetOwner(card, "ANCHOR_RIGHT")
    GameTooltip:AddLine(L["Undiscovered "] .. (Kind().key == "g" and L["Glyph"] or L["Darkmoon Card"]), 0.62, 0.62, 0.62)
    GameTooltip:AddLine(rarity.name, rarity.r, rarity.g, rarity.b)
    if lock then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Quest: "] .. lock.name, 1, 0.82, 0)
        GameTooltip:AddLine(lock.description, 1, 1, 1, 1)
        UI.AddQuestProgress(GameTooltip, lock)
    end
    GameTooltip:Show()
end

local function ShowCardTooltip(card)
    if not card.entry then
        return
    end
    if card.entry.locked then
        ShowLockedTooltip(card, card.entry)
        return
    end
    VanillaBonkCodex.ShowEntryTooltip(card, card.entry, true)
end

local function GridCard(index)
    local card = grid.cards[index]
    if card then
        return card
    end
    card = CreateCardFace(grid.child, CARD_W, CARD_H)
    card:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    card:SetScript("OnClick", function()
        if arg1 == "RightButton" then
            ToggleBan(this.entry)
            return
        end
        if this.entry and not this.entry.locked then
            PlaySound("igMainMenuOptionCheckBoxOn")
            selected[Kind().key] = EntryKey(this.entry)
            Deck.Refresh()
        end
    end)
    card:SetScript("OnEnter", function() ShowCardTooltip(this) end)
    card:SetScript("OnLeave", function() GameTooltip:Hide() end)
    grid.cards[index] = card
    return card
end

local function SectionHeader(index)
    local header = grid.headers[index]
    if header then
        return header
    end
    header = CreateFrame("Frame", nil, grid.child)
    header:SetWidth(COLUMNS * (CARD_W + CARD_GAP) - CARD_GAP)
    header:SetHeight(HEADER_HEIGHT)
    header.name = UI.Text(header, 13)
    header.name:SetPoint("LEFT", header, "LEFT", 0, 0)
    header.count = UI.Text(header, 11)
    header.count:SetPoint("LEFT", header.name, "RIGHT", 8, 0)
    header.count:SetTextColor(0.54, 0.52, 0.47)
    header.line = header:CreateTexture(nil, "ARTWORK")
    header.line:SetHeight(1)
    header.line:SetPoint("LEFT", header.count, "RIGHT", 10, 0)
    header.line:SetPoint("RIGHT", header, "RIGHT", 0, 0)
    UI.Gradient(header.line, "HORIZONTAL", HAIR[1], HAIR[2], HAIR[3], 1, 0)
    grid.headers[index] = header
    return header
end

local function ShowGrid()
    local entries = Entries()
    local top, shownCards, shownHeaders = 0, 0, 0
    local current = SelectedEntry()
    local index = 1
    while index <= getn(entries) do
        local rarity = entries[index].rarity
        local last = index
        local owned = 0
        while last <= getn(entries) and entries[last].rarity == rarity do
            if entries[last].owned then
                owned = owned + 1
            end
            last = last + 1
        end
        shownHeaders = shownHeaders + 1
        local header = SectionHeader(shownHeaders)
        local look = UI.RARITY[rarity] or UI.RARITY[0]
        header.name:SetText(look.name)
        header.name:SetTextColor(look.r, look.g, look.b)
        header.count:SetText(owned .. " / " .. (last - index))
        header:ClearAllPoints()
        header:SetPoint("TOPLEFT", grid.child, "TOPLEFT", 0, -top)
        header:Show()
        top = top + HEADER_HEIGHT + 4
        for slot = index, last - 1 do
            local position = slot - index
            shownCards = shownCards + 1
            local card = GridCard(shownCards)
            StyleCardFace(card, entries[slot])
            if current and entries[slot] == current then
                PaintCard(card, 1, 0.82, 0, 1)
            end
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT", grid.child, "TOPLEFT", math.mod(position, COLUMNS) * (CARD_W + CARD_GAP),
                -(top + math.floor(position / COLUMNS) * (CARD_H + CARD_GAP)))
            card:Show()
        end
        top = top + math.ceil((last - index) / COLUMNS) * (CARD_H + CARD_GAP) + 10
        index = last
    end
    for hidden = shownCards + 1, getn(grid.cards) do
        grid.cards[hidden]:Hide()
    end
    for hidden = shownHeaders + 1, getn(grid.headers) do
        grid.headers[hidden]:Hide()
    end
    grid.child:SetHeight(max(1, top))
    grid.scroll:UpdateScrollChildRect()
    grid.empty:SetText(getn(entries) == 0 and L["Nothing here yet."] or "")
end

local function UnlockText(entry)
    if entry.locked then
        local lock = book.locks[Kind().key .. entry.id]
        return L["|cffff6060Locked: "] .. (lock and lock.name or L["a quest"]) .. "|r"
    end
    local lock = book.locks[Kind().key .. entry.id]
    if lock then
        return L["|cff40ff40Unlocked by "] .. lock.name .. "|r"
    end
    return L["|cff9d9d9dStarter|r"]
end

local function ShowDetail()
    local entry = SelectedEntry()
    if not entry then
        side.detail:Hide()
        return
    end
    side.detail:Show()
    local rarity = Rarity(entry)
    StyleCardFace(side.big, entry)
    side.name:SetText(entry.name)
    side.name:SetTextColor(rarity.r, rarity.g, rarity.b)
    side.rarity:SetText(rarity.name .. (Kind().key == "g" and L[" Glyph"] or L[" Darkmoon Card"]))
    side.source:SetText(UnlockText(entry))
    local text = entry.description or ""
    if entry.drawback and entry.drawback ~= "" then
        text = text .. "\n|cffff4a3a" .. entry.drawback .. "|r"
    end
    side.text:SetText(text)
    local stack = Kind().key == "c" and book.stacks and book.stacks[entry.id]
    if stack and entry.maxCopies ~= 1 then
        side.oneValue:SetText(stack.one)
        side.fiveValue:SetText(stack.five)
        side.copies:Show()
    else
        side.copies:Hide()
    end
    local pool = Pool()
    if entry.off then
        side.ban:SetText(L["Allow this "] .. Kind().noun)
        side.ban:Enable()
    else
        side.ban:SetText(L["Ban this "] .. Kind().noun)
        if pool.used < pool.slots then
            side.ban:Enable()
        else
            side.ban:Disable()
        end
    end
end

local function Pip(index)
    local pip = side.pips[index]
    if pip then
        return pip
    end
    pip = CreateFrame("Frame", nil, side.slots)
    pip:SetWidth(PIP_W)
    pip:SetHeight(PIP_H)
    pip:SetBackdrop({ bgFile = UI.FLAT, edgeFile = UI.FLAT, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    pip.mark = UI.Text(pip, 18, UI.NUMBER_FONT, "OUTLINE")
    pip.mark:SetPoint("CENTER", pip, "CENTER", 0, 0)
    pip.lock = pip:CreateTexture(nil, "ARTWORK")
    pip.lock:SetTexture("Interface\\ChatFrame\\UI-ChatFrame-LockIcon")
    pip.lock:SetWidth(18)
    pip.lock:SetHeight(18)
    pip.lock:SetPoint("CENTER", pip, "CENTER", 0, 0)
    pip:SetPoint("TOPLEFT", side.slots, "TOPLEFT", (index - 1) * (PIP_W + PIP_GAP), 0)
    side.pips[index] = pip
    return pip
end

local function ShowSlots()
    local pool = Pool()
    local sources = Bans()
    side.count:SetText(pool.used .. " / " .. pool.slots)
    for index = 1, getn(sources) do
        local pip = Pip(index)
        if index <= pool.used then
            pip:SetBackdropColor(0.23, 0.05, 0.05, 1)
            pip:SetBackdropBorderColor(0.69, 0.13, 0.13)
            pip.mark:SetText("X")
            pip.mark:SetTextColor(BAN_RED[1], BAN_RED[2], BAN_RED[3])
            pip.lock:Hide()
        elseif index <= pool.slots then
            pip:SetBackdropColor(0, 0, 0, 0.4)
            pip:SetBackdropBorderColor(0.66, 0.54, 0.28)
            pip.mark:SetText("")
            pip.lock:Hide()
        else
            pip:SetBackdropColor(0.043, 0.039, 0.031, 1)
            pip:SetBackdropBorderColor(0.23, 0.2, 0.14)
            pip.mark:SetText("")
            pip.lock:Show()
        end
        pip:Show()
    end
    for index = getn(sources) + 1, getn(side.pips) do
        side.pips[index]:Hide()
    end
    side.slotText:SetText(pool.used .. L[" used, "] .. max(0, pool.slots - pool.used) .. L[" free"])
    local sale = NextSale()
    if sale then
        side.buy:SetText(L["Buy a ban slot: "] .. sale.tickets .. L[" tickets"])
        if (book.tickets or 0) >= sale.tickets then
            side.buy:Enable()
        else
            side.buy:Disable()
        end
        side.buy:Show()
    else
        side.buy:Hide()
    end
    side.tickets:SetText((book.tickets or 0) .. L[" Darkmoon Tickets"])
end

local function ShowHelp(owner)
    GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
    GameTooltip:AddLine(L["Getting more "] .. strlower(Kind().bans), 1, 0.82, 0)
    for _, source in ipairs(Bans()) do
        local right = source.earned and L["Earned"] or (source.tickets > 0 and (source.tickets .. L[" tickets"]) or source.detail)
        if source.earned then
            GameTooltip:AddDoubleLine(source.label, right, 0.25, 1, 0.25, 0.25, 1, 0.25)
        else
            GameTooltip:AddDoubleLine(source.label, right, 1, 1, 1, 0.62, 0.62, 0.62)
        end
    end
    GameTooltip:AddLine(Kind().key == "c" and L["Glyph bans are counted on their own, on the Glyphs tab."] or
        L["Card bans are counted on their own, on the Darkmoon Cards tab."], 0.62, 0.62, 0.62, 1)
    GameTooltip:Show()
end

local function BuildFrame()
    frame = CreateFrame("Frame", "VanillaBonkDeckFrame", UIParent)
    frame:SetFrameStrata("DIALOG")
    frame:SetWidth(W)
    frame:SetHeight(H)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    if frame.SetClampedToScreen then
        frame:SetClampedToScreen(true)
    end
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    frame:Hide()
    tinsert(UISpecialFrames, "VanillaBonkDeckFrame")
    frame:SetFrameLevel(4)
    frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 11, top = 11, bottom = 11 } })
    frame.base = CreateFrame("Frame", nil, frame)
    frame.base:SetFrameLevel(3)
    frame.base:SetAllPoints(frame)
    frame.base:SetBackdrop({ bgFile = UI.FLAT, insets = { left = 11, right = 11, top = 11, bottom = 11 } })
    frame.base:SetBackdropColor(UI.WINDOW_BG[1], UI.WINDOW_BG[2], UI.WINDOW_BG[3], 1)
    frame:SetScript("OnShow", function() PlaySound("igSpellBookOpen") end)
    frame:SetScript("OnHide", function() PlaySound("igSpellBookClose") end)

    frame.plate = frame:CreateTexture(nil, "ARTWORK")
    frame.plate:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    frame.plate:SetWidth(280)
    frame.plate:SetHeight(64)
    frame.plate:SetPoint("TOP", frame, "TOP", 0, 12)
    frame.plateText = UI.Text(frame, 13)
    frame.plateText:SetPoint("TOP", frame.plate, "TOP", 0, -14)
    frame.plateText:SetTextColor(1, 0.82, 0)
    frame.plateText:SetText(L["Darkmoon Deck"])

    frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

    frame.label = UI.Text(frame, 11)
    frame.label:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -30)
    frame.label:SetTextColor(1, 0.82, 0)
    frame.label:SetText(L["Sayge's Table"])
    frame.title = UI.Text(frame, 30, UI.TITLE_FONT)
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 26, -46)
    frame.title:SetTextColor(TITLE_COLOR[1], TITLE_COLOR[2], TITLE_COLOR[3])
    frame.blurb = UI.Text(frame, 11)
    frame.blurb:SetPoint("LEFT", frame.title, "RIGHT", 22, -2)
    frame.blurb:SetWidth(W - 360)
    frame.blurb:SetJustifyH("LEFT")
    frame.blurb:SetTextColor(SOFT[1], SOFT[2], SOFT[3])
    frame.line = Hairline(frame, W - 52)
    frame.line:SetPoint("TOPLEFT", frame, "TOPLEFT", 26, -92)

    grid = { cards = {}, headers = {} }
    grid.panel = UI.Panel(frame)
    DressPanel(grid.panel)
    grid.panel:SetPoint("TOPLEFT", frame, "TOPLEFT", GRID_X, -GRID_TOP)
    grid.panel:SetWidth(GRID_WIDTH)
    grid.panel:SetHeight(H - GRID_TOP - 22)
    grid.scroll = CreateFrame("ScrollFrame", "VanillaBonkDeckScroll", grid.panel, "UIPanelScrollFrameTemplate")
    grid.scroll:SetPoint("TOPLEFT", grid.panel, "TOPLEFT", 16, -14)
    grid.scroll:SetPoint("BOTTOMRIGHT", grid.panel, "BOTTOMRIGHT", -30, 10)
    grid.child = CreateFrame("Frame", nil, grid.scroll)
    grid.child:SetWidth(GRID_WIDTH - 46)
    grid.child:SetHeight(1)
    grid.scroll:SetScrollChild(grid.child)
    grid.empty = UI.Text(grid.panel, 12)
    grid.empty:SetPoint("TOP", grid.panel, "TOP", 0, -40)
    grid.empty:SetTextColor(0.6, 0.6, 0.6)
    grid.tabs = UI.PanelTabs(grid.panel, 10, function(index)
        kindIndex = index
        grid.scroll:SetVerticalScroll(0)
        Deck.Refresh()
    end)
    local labels = {}
    for _, kind in ipairs(KINDS) do
        tinsert(labels, kind.tab)
    end
    grid.tabs:SetTabs(labels)

    side = { pips = {} }
    side.header = UI.Text(frame, 12)
    side.header:SetPoint("TOPLEFT", frame, "TOPLEFT", SIDE_X, -GRID_TOP + 20)
    side.header:SetTextColor(1, 0.82, 0)
    side.count = UI.Text(frame, 15)
    side.count:SetPoint("TOPRIGHT", frame, "TOPLEFT", SIDE_X + SIDE_WIDTH, -GRID_TOP + 22)

    side.detail = UI.Panel(frame)
    DressPanel(side.detail)
    side.detail:SetPoint("TOPLEFT", frame, "TOPLEFT", SIDE_X, -GRID_TOP)
    side.detail:SetWidth(SIDE_WIDTH)
    side.detail:SetHeight(262)
    side.big = CreateCardFace(side.detail, BIG_W, BIG_H)
    side.big:SetPoint("TOPLEFT", side.detail, "TOPLEFT", 14, -14)
    side.big:SetScript("OnEnter", function() ShowCardTooltip(this) end)
    side.big:SetScript("OnLeave", function() GameTooltip:Hide() end)
    local textX = 14 + BIG_W + 12
    local textWidth = SIDE_WIDTH - textX - 14
    side.name = UI.Text(side.detail, 14)
    side.name:SetPoint("TOPLEFT", side.detail, "TOPLEFT", textX, -16)
    side.name:SetWidth(textWidth)
    side.name:SetJustifyH("LEFT")
    side.rarity = UI.Text(side.detail, 10)
    side.rarity:SetPoint("TOPLEFT", side.name, "BOTTOMLEFT", 0, -4)
    side.rarity:SetTextColor(0.62, 0.62, 0.62)
    side.source = UI.Text(side.detail, 10)
    side.source:SetPoint("TOPLEFT", side.rarity, "BOTTOMLEFT", 0, -3)
    side.source:SetWidth(textWidth)
    side.source:SetJustifyH("LEFT")
    side.text = UI.Text(side.detail, 11)
    side.text:SetPoint("TOPLEFT", side.source, "BOTTOMLEFT", 0, -8)
    side.text:SetWidth(textWidth)
    side.text:SetJustifyH("LEFT")
    side.copies = CreateFrame("Frame", nil, side.detail)
    side.copies:SetPoint("TOPLEFT", side.big, "BOTTOMLEFT", 0, -10)
    side.copies:SetWidth(SIDE_WIDTH - 28)
    side.copies:SetHeight(34)
    side.oneLabel = UI.Text(side.copies, 11)
    side.oneLabel:SetPoint("TOPLEFT", side.copies, "TOPLEFT", 0, 0)
    side.oneLabel:SetTextColor(0.62, 0.62, 0.62)
    side.oneLabel:SetText(L["1 copy"])
    side.oneValue = UI.Text(side.copies, 11)
    side.oneValue:SetPoint("TOPRIGHT", side.copies, "TOPRIGHT", 0, 0)
    side.fiveLabel = UI.Text(side.copies, 11)
    side.fiveLabel:SetPoint("TOPLEFT", side.oneLabel, "BOTTOMLEFT", 0, -4)
    side.fiveLabel:SetTextColor(0.62, 0.62, 0.62)
    side.fiveLabel:SetText(L["5 copies"])
    side.fiveValue = UI.Text(side.copies, 11)
    side.fiveValue:SetPoint("TOPRIGHT", side.oneValue, "BOTTOMRIGHT", 0, -4)
    side.ban = UI.Button(side.detail, SIDE_WIDTH - 28, "", function() ToggleBan(SelectedEntry()) end)
    side.ban:SetPoint("BOTTOMLEFT", side.detail, "BOTTOMLEFT", 14, 14)

    side.slotLabel = UI.Text(frame, 12)
    side.slotLabel:SetPoint("TOPLEFT", side.detail, "BOTTOMLEFT", 0, -22)
    side.slotLabel:SetTextColor(1, 0.82, 0)
    side.slotLabel:SetText(L["Ban slots"])
    side.help = CreateFrame("Button", nil, frame)
    side.help:SetWidth(18)
    side.help:SetHeight(18)
    side.help:SetPoint("LEFT", side.slotLabel, "RIGHT", 5, 0)
    side.help:SetNormalTexture("Interface\\GossipFrame\\ActiveQuestIcon")
    side.help:SetScript("OnEnter", function() ShowHelp(this) end)
    side.help:SetScript("OnLeave", function() GameTooltip:Hide() end)
    side.slots = CreateFrame("Frame", nil, frame)
    side.slots:SetPoint("TOPLEFT", side.slotLabel, "BOTTOMLEFT", 0, -8)
    side.slots:SetWidth(SIDE_WIDTH)
    side.slots:SetHeight(PIP_H)
    side.slotText = UI.Text(frame, 11)
    side.slotText:SetPoint("TOPLEFT", side.slots, "BOTTOMLEFT", 0, -10)
    side.slotText:SetTextColor(SOFT[1], SOFT[2], SOFT[3])
    side.buy = UI.Button(frame, SIDE_WIDTH, "", function()
        PlaySound("LOOTWINDOWCOINSOUND")
        SendChatMessage(".bonk banslot " .. Kind().key, "SAY")
    end)
    side.buy:SetPoint("TOPLEFT", side.slotText, "BOTTOMLEFT", 0, -14)
    side.tickets = UI.Text(frame, 11)
    side.tickets:SetPoint("TOPLEFT", side.buy, "BOTTOMLEFT", 0, -12)
    side.tickets:SetTextColor(SOFT[1], SOFT[2], SOFT[3])

    frame.done = UI.Button(frame, 100, L["Close"], function() frame:Hide() end)
    frame.done:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -24, 22)
end

function Deck.Refresh(received)
    if received then
        book = received
    end
    if not frame or not book then
        return
    end
    local kind = Kind()
    frame.title:SetText(kind.tab)
    SetPanelArt(grid.panel, kind.key == "g")
    SetPanelArt(side.detail, kind.key == "g")
    frame.blurb:SetText(kind.blurb)
    side.header:SetText(kind.bans)
    grid.tabs:Select(kindIndex)
    ShowGrid()
    ShowDetail()
    ShowSlots()
end

function Deck.Open(received)
    if not frame then
        BuildFrame()
    end
    book = received
    frame:Show()
    Deck.Refresh()
end

function Deck.IsShown()
    return frame and frame:IsShown()
end

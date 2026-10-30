local L = VanillaBonkL
local UI = VanillaBonkUI

local SOCKET_SIZE = 26
local SOCKETS = 7
local ORDINALS = { "first", "second", "third", "fourth", "fifth", "sixth", "seventh" }
local FADE = 0.2
local BAD = { 1, 0.25, 0.2 }
local MAX_CARDS = 4
local CARD_WIDTH = 200
local CARD_HEIGHT = 312
local CARD_GAP = 20
local CARD_CENTER_Y = 4
local STONE_SIZE = 72
local TEXT_WIDTH = CARD_WIDTH - 28
local CARD_ART = "Interface\\TalentFrame\\MageArcane-TopLeft"
local STONE_BORDER = { edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 24 }
local QUIET_LINE = { 0.85, 0.75, 0.5, 0.35 }

local info = {}
VanillaBonkGlyphInfo = info
local offer = { pick = 1, ids = {} }
local taken = {}
local counts = {}

function VanillaBonk_GlyphsTaken()
    return taken
end

local function Rarity(glyph)
    return UI.RARITY[glyph and glyph.rarity or 0] or UI.RARITY[0]
end

local function KindText(glyph)
    local text = Rarity(glyph).name .. L[" Glyph"]
    if glyph and glyph.drawback ~= "" then
        text = text .. L[" with a |cffff4a3adrawback|r"]
    end
    return text
end

local function GlyphTooltip(owner, glyph)
    local rarity = Rarity(glyph)
    GameTooltip:SetOwner(owner, "ANCHOR_TOP")
    GameTooltip:AddLine(glyph.name, rarity.r, rarity.g, rarity.b)
    GameTooltip:AddLine(KindText(glyph), 0.8, 0.8, 0.8)
    GameTooltip:AddLine(glyph.description, 1, 0.82, 0, 1)
    if glyph.drawback ~= "" then
        GameTooltip:AddLine(glyph.drawback, 1, 0.29, 0.23, 1)
    end
    GameTooltip:Show()
end

function VanillaBonk_GlyphInfo(id)
    return info[id]
end

function VanillaBonk_GlyphTooltip(owner, id)
    local glyph = info[id]
    if not glyph then
        return false
    end
    GlyphTooltip(owner, glyph)
    return true
end

local function TintRing(ring, r, g, b)
    if ring.top then
        ring.top:SetVertexColor(r, g, b)
        ring.bottom:SetVertexColor(r, g, b)
    elseif ring.border then
        ring.border:SetVertexColor(r, g, b)
    end
end

local function GlyphIcon(glyph)
    return UI.ICON_PATH .. (glyph.icon ~= "" and glyph.icon or "INV_Misc_QuestionMark")
end

local frame = CreateFrame("Frame", "VanillaBonkGlyphs", UIParent)
frame:SetAllPoints(UIParent)
frame:SetFrameStrata("DIALOG")
frame:Hide()

frame.dim = frame:CreateTexture(nil, "BACKGROUND")
frame.dim:SetTexture("Interface\\AddOns\\HordesOfAzeroth\\Textures\\OfferVignette")
frame.dim:SetPoint("TOPLEFT", WorldFrame, "TOPLEFT", -2, 2)
frame.dim:SetPoint("BOTTOMRIGHT", WorldFrame, "BOTTOMRIGHT", 2, -2)
frame.dim:SetVertexColor(0, 0, 0, 1)

frame.title = frame:CreateFontString(nil, "OVERLAY")
frame.title:SetFont(UI.TITLE_FONT, 44, "OUTLINE")
frame.title:SetPoint("CENTER", frame, "CENTER", 0, 244)
frame.title:SetTextColor(1, 0.82, 0)
frame.title:SetText(L["Choose a Glyph"])

frame.subtitle = UI.Text(frame, 13)
frame.subtitle:SetPoint("CENTER", frame, "CENTER", 0, 202)
frame.subtitle:SetTextColor(0.9, 0.83, 0.64)
for side = 1, 2 do
    local line = frame:CreateTexture(nil, "ARTWORK")
    line:SetTexture(UI.FLAT)
    line:SetWidth(70)
    line:SetHeight(1)
    if side == 1 then
        line:SetPoint("RIGHT", frame.subtitle, "LEFT", -14, 0)
        line:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0, 1, 0.82, 0, 0.75)
    else
        line:SetPoint("LEFT", frame.subtitle, "RIGHT", 14, 0)
        line:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0.75, 1, 0.82, 0, 0)
    end
end

frame.hint = UI.Text(frame, 11)
frame.hint:SetPoint("CENTER", frame, "CENTER", 0, -224)
frame.hint:SetTextColor(0.78, 0.78, 0.78)

local function Pick(index)
    if not frame.open or frame.picking or not offer.ids[index] then
        return
    end
    frame.picking = true
    PlaySound("igMainMenuOptionCheckBoxOn")
    SendChatMessage(".bonk glyph " .. index, "SAY")
end

local function Divider(card, r, g, b)
    local left = card:CreateTexture(nil, "ARTWORK")
    left:SetTexture(UI.FLAT)
    left:SetHeight(1)
    left:SetWidth((CARD_WIDTH - 48) / 2)
    left:SetGradientAlpha("HORIZONTAL", r, g, b, 0, r, g, b, 0.75)
    local right = card:CreateTexture(nil, "ARTWORK")
    right:SetTexture(UI.FLAT)
    right:SetHeight(1)
    right:SetWidth((CARD_WIDTH - 48) / 2)
    right:SetGradientAlpha("HORIZONTAL", r, g, b, 0.75, r, g, b, 0)
    return left, right
end

local function PlaceDivider(left, right, anchor, gap)
    left:ClearAllPoints()
    left:SetPoint("TOPRIGHT", anchor, "BOTTOM", 0, -gap)
    right:ClearAllPoints()
    right:SetPoint("TOPLEFT", anchor, "BOTTOM", 0, -gap)
end

local function SetCardLine(card, color)
    card.line:SetBackdropBorderColor(color[1], color[2], color[3], color[4])
end

frame.cards = {}
for index = 1, MAX_CARDS do
    local card = CreateFrame("Button", nil, frame)
    card:SetWidth(CARD_WIDTH)
    card:SetHeight(CARD_HEIGHT)
    card.index = index

    card.art = card:CreateTexture(nil, "BACKGROUND")
    card.art:SetTexture(CARD_ART)
    card.art:SetPoint("TOPLEFT", card, "TOPLEFT", 9, -9)
    card.art:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -9, 9)
    UI.TalentArtCoords(card.art, CARD_WIDTH - 18, CARD_HEIGHT - 18)
    card.shade = card:CreateTexture(nil, "BORDER")
    card.shade:SetAllPoints(card.art)
    UI.Shade(card.shade, 0.95, 0.1)

    card:SetBackdrop(STONE_BORDER)
    card.line = CreateFrame("Frame", nil, card)
    card.line:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -8)
    card.line:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 8)
    card.line:SetBackdrop({ edgeFile = UI.FLAT, edgeSize = 1 })
    card.lineColor = QUIET_LINE

    card.halo = card:CreateTexture(nil, "ARTWORK")
    card.halo:SetTexture("Interface\\Cooldown\\star4")
    card.halo:SetBlendMode("ADD")
    card.halo:SetWidth(180)
    card.halo:SetHeight(180)
    card.halo:SetPoint("CENTER", card, "TOP", 0, -24 - STONE_SIZE / 2)

    card.stone = UI.Ring(card, STONE_SIZE, true)
    card.stone:SetPoint("TOP", card, "TOP", 0, -24)
    card.icon = UI.RingArt(card.stone, "")
    card.circle = card.stone:CreateTexture(nil, "OVERLAY")
    card.circle:SetTexture("Interface\\MiniMap\\Ping\\ping4")
    card.circle:SetBlendMode("ADD")
    card.circle:SetWidth(STONE_SIZE * 1.22)
    card.circle:SetHeight(STONE_SIZE * 1.22)
    card.circle:SetPoint("CENTER", card.stone, "CENTER", 0, 0)

    card.key = UI.Ring(card, 28)
    card.key:SetPoint("TOPLEFT", card, "TOPLEFT", 13, -13)
    card.key.text = UI.Text(card.key, 13)
    card.key.text:SetPoint("CENTER", card.key, "CENTER", 0, 0)
    card.key.text:SetTextColor(1, 0.82, 0)
    card.key.text:SetText(index)

    card.name = UI.Text(card, 15)
    card.name:SetPoint("TOP", card, "TOP", 0, -108)
    card.name:SetWidth(CARD_WIDTH - 24)
    card.kind = UI.Text(card, 11)
    card.kind:SetPoint("TOP", card.name, "BOTTOM", 0, -3)
    card.kind:SetTextColor(0.82, 0.82, 0.82)
    card.ruleLeft, card.ruleRight = Divider(card, 1, 0.82, 0)
    PlaceDivider(card.ruleLeft, card.ruleRight, card.kind, 10)

    card.description = UI.Text(card, 13)
    card.description:SetPoint("TOP", card.ruleLeft, "BOTTOMRIGHT", 0, -10)
    card.description:SetWidth(TEXT_WIDTH)
    card.description:SetTextColor(1, 0.82, 0)

    card.badLeft, card.badRight = Divider(card, 1, 0.23, 0.16)
    PlaceDivider(card.badLeft, card.badRight, card.description, 10)
    card.badLabel = UI.Text(card, 9)
    card.badLabel:SetPoint("TOP", card.badLeft, "BOTTOMRIGHT", 0, -7)
    card.badLabel:SetTextColor(1, 0.48, 0.42)
    card.badLabel:SetText(L["DRAWBACK"])
    card.drawback = UI.Text(card, 12)
    card.drawback:SetPoint("TOP", card.badLabel, "BOTTOM", 0, -3)
    card.drawback:SetWidth(TEXT_WIDTH)
    card.drawback:SetTextColor(1, 0.29, 0.23)

    card.highlight = card:CreateTexture(nil, "HIGHLIGHT")
    card.highlight:SetTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
    card.highlight:SetBlendMode("ADD")
    card.highlight:SetTexCoord(0, 0.625, 0, 0.6875)
    card.highlight:SetAlpha(0.35)
    card.highlight:SetAllPoints(card.art)

    card:SetScript("OnEnter", function()
        SetCardLine(this, { 1, 0.82, 0, 1 })
        this.halo:SetAlpha(0.9)
    end)
    card:SetScript("OnLeave", function()
        SetCardLine(this, this.lineColor)
        this.halo:SetAlpha(0.55)
    end)
    card:SetScript("OnClick", function()
        Pick(this.index)
    end)
    frame.cards[index] = card
end

frame.mine = CreateFrame("Frame", nil, frame)
frame.mine:SetHeight(SOCKET_SIZE)
frame.mine:SetPoint("CENTER", frame, "CENTER", 0, -182)
frame.mine.label = UI.Text(frame.mine, 11)
frame.mine.label:SetPoint("LEFT", frame.mine, "LEFT", 0, 0)
frame.mine.label:SetTextColor(0.78, 0.72, 0.56)
frame.mine.label:SetText(L["Your Glyphs"])
frame.mine.sockets = {}
for index = 1, SOCKETS do
    local socket = UI.Ring(frame.mine, SOCKET_SIZE, true)
    socket:SetPoint("LEFT", frame.mine.label, "RIGHT", 10 + (index - 1) * (SOCKET_SIZE + 6), 0)
    socket.icon = UI.RingArt(socket, "")
    frame.mine.sockets[index] = socket
end
frame.mine:SetWidth(frame.mine.label:GetStringWidth() + 10 + SOCKETS * (SOCKET_SIZE + 6) - 6)

local function FillCard(card, glyph)
    local rarity = Rarity(glyph)
    card.icon:SetTexture(GlyphIcon(glyph))
    card.halo:SetVertexColor(rarity.r, rarity.g, rarity.b)
    card.halo:SetAlpha(0.55)
    local bad = glyph.drawback ~= ""
    if bad then
        card.circle:SetVertexColor(BAD[1], BAD[2], BAD[3])
        TintRing(card.stone, 1, 0.45, 0.4)
    else
        card.circle:SetVertexColor(rarity.r, rarity.g, rarity.b)
        TintRing(card.stone, 1, 1, 1)
    end
    card.lineColor = glyph.rarity > 0 and { rarity.r, rarity.g, rarity.b, 0.9 } or QUIET_LINE
    SetCardLine(card, card.lineColor)
    card.name:SetText(glyph.name)
    card.name:SetTextColor(rarity.r, rarity.g, rarity.b)
    card.kind:SetText(UI.RarityText(glyph.rarity, rarity.name) .. L[" Glyph"])
    card.description:SetText(glyph.description)
    card.drawback:SetText(glyph.drawback)
    for _, part in ipairs({ card.badLeft, card.badRight, card.badLabel, card.drawback }) do
        if bad then
            part:Show()
        else
            part:Hide()
        end
    end
end

local function FillMine()
    for index, socket in ipairs(frame.mine.sockets) do
        local glyph = info[taken[index]]
        if glyph then
            socket.icon:SetTexture(GlyphIcon(glyph))
            socket.icon:Show()
        else
            socket.icon:Hide()
        end
    end
end

local function Fill()
    frame.subtitle:SetText(L["Your "] .. (ORDINALS[offer.pick] or "next") .. L[" Glyph lasts the whole run. The run is paused while you choose."])
    local glyphs = {}
    for index = 1, MAX_CARDS do
        local glyph = info[offer.ids[index]]
        if glyph then
            tinsert(glyphs, index)
        end
    end
    local count = getn(glyphs)
    local left = -((count * CARD_WIDTH + (count - 1) * CARD_GAP) / 2) + CARD_WIDTH / 2
    for index, card in ipairs(frame.cards) do
        local glyph = info[offer.ids[index]]
        if glyph then
            FillCard(card, glyph)
            card:ClearAllPoints()
            card:SetPoint("CENTER", frame, "CENTER", left + (index - 1) * (CARD_WIDTH + CARD_GAP), CARD_CENTER_Y)
            card:Show()
        else
            card:Hide()
        end
    end
    FillMine()
    frame.hint:SetText("")
end

frame:SetScript("OnUpdate", function()
    local want = this.open and 1 or 0
    if this.alpha ~= want then
        local step = arg1 / FADE
        this.alpha = want > this.alpha and min(want, this.alpha + step) or max(want, this.alpha - step)
        this:SetAlpha(this.alpha)
        if this.alpha <= 0 then
            this:Hide()
        end
    end
end)

local function Open()
    Fill()
    frame.picking = false
    if not frame.open then
        frame.open = true
        frame.alpha = 0
        frame:SetAlpha(0)
        PlaySound("LEVELUP")
        if VanillaBonk_TakeChoiceKeys then
            VanillaBonk_TakeChoiceKeys()
        end
    end
    frame:Show()
end

local function Close()
    if not frame.open then
        return
    end
    frame.open = false
    frame.picking = false
    if VanillaBonk_GiveBackChoiceKeys and not (VanillaBonkOffer and VanillaBonkOffer.open) then
        VanillaBonk_GiveBackChoiceKeys()
    end
end

function VanillaBonk_GlyphKey(index)
    if not frame.open then
        return false
    end
    Pick(index)
    return true
end

local sockets = {}

local function MakeSockets()
    local anchor = UI.GlyphAnchor
    if not anchor or sockets[1] then
        return
    end
    for index = 1, SOCKETS do
        local socket = UI.Ring(anchor:GetParent(), SOCKET_SIZE, true)
        socket:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", (index - 1) * (SOCKET_SIZE + 6), 0)
        socket:SetFrameLevel(anchor:GetParent():GetFrameLevel() + 7)
        socket.icon = UI.RingArt(socket, "")
        socket.circle = socket:CreateTexture(nil, "OVERLAY")
        socket.circle:SetTexture("Interface\\MiniMap\\Ping\\ping4")
        socket.circle:SetBlendMode("ADD")
        socket.circle:SetWidth(SOCKET_SIZE * 1.08)
        socket.circle:SetHeight(SOCKET_SIZE * 1.08)
        socket.circle:SetPoint("CENTER", socket, "CENTER", 0, 0)
        socket.count = UI.Text(socket, 11, UI.NUMBER_FONT, "OUTLINE", "OVERLAY")
        socket.count:SetPoint("BOTTOMRIGHT", socket, "BOTTOMRIGHT", 2, -2)
        socket.index = index
        socket:EnableMouse(true)
        socket:SetScript("OnEnter", function()
            local glyph = info[taken[this.index]]
            if glyph then
                GlyphTooltip(this, glyph)
            end
        end)
        socket:SetScript("OnLeave", function() GameTooltip:Hide() end)
        sockets[index] = socket
    end
end

local function RefreshSockets()
    MakeSockets()
    for index, socket in ipairs(sockets) do
        local glyph = info[taken[index]]
        if glyph then
            local rarity = Rarity(glyph)
            socket.icon:SetTexture(GlyphIcon(glyph))
            socket.icon:Show()
            if glyph.drawback ~= "" then
                socket.circle:SetVertexColor(BAD[1], BAD[2], BAD[3])
            else
                socket.circle:SetVertexColor(rarity.r, rarity.g, rarity.b)
            end
            socket.circle:Show()
            socket.count:SetText(counts[taken[index]] or "")
            socket:Show()
        else
            socket:Hide()
        end
    end
end

local handlers = {}

handlers["glyphinfo"] = function(f)
    local id = f[2]
    if not id or id == "" then
        return
    end
    info[id] = {
        name = f[3] or "",
        icon = f[4] or "",
        rarity = tonumber(f[5] or "") or 0,
        description = f[6] or "",
        drawback = f[7] or "",
    }
end

handlers["glyphoffer"] = function(f)
    offer.pick = tonumber(f[2] or "") or 1
    offer.ids = {}
end

handlers["glyphopt"] = function(f)
    local index = tonumber(f[2] or "")
    if index and f[3] and f[3] ~= "" then
        offer.ids[index] = f[3]
    end
end

handlers["glyphofferend"] = Open
handlers["glyphclose"] = Close

handlers["glyphs"] = function(f)
    taken = {}
    for _, id in ipairs(UI.Split(f[2] or "", ",")) do
        if id ~= "" then
            tinsert(taken, id)
        end
    end
    RefreshSockets()
end

handlers["glyphcount"] = function(f)
    if f[2] and f[2] ~= "" then
        counts[f[2]] = f[3] ~= "0" and f[3] or nil
        RefreshSockets()
    end
end

handlers["start"] = function()
    taken = {}
    counts = {}
    RefreshSockets()
end

handlers["end"] = function()
    Close()
    frame.alpha = 0
    frame:Hide()
end

UI.Listen(handlers)

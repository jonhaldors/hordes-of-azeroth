local L = VanillaBonkL
local PREFIX = "BONK~"
local ICON_PATH = "Interface\\Icons\\"
local FONT = "Fonts\\FRIZQT__.TTF"

local VB = {
    tiers = {},
    pendingTiers = {},
    offer = {},
    inRun = false,
}

local function Split(text, separator)
    local fields = {}
    local start = 1
    while true do
        local found = strfind(text, separator, start, true)
        if not found then
            tinsert(fields, strsub(text, start))
            return fields
        end
        tinsert(fields, strsub(text, start, found - 1))
        start = found + 1
    end
end

local function Command(text)
    SendChatMessage(".bonk " .. text, "SAY")
end

local function FormatTime(seconds)
    seconds = tonumber(seconds) or 0
    return format("%d:%02d", floor(seconds / 60), mod(seconds, 60))
end

local function FormatGold(copper)
    copper = tonumber(copper) or 0
    local gold = floor(copper / 10000)
    local silver = floor(mod(copper, 10000) / 100)
    local text = format(L["|cffeda55f%dc|r"], mod(copper, 100))
    if silver > 0 or gold > 0 then
        text = format(L["|cffc7c7cf%ds|r "], silver) .. text
    end
    if gold > 0 then
        text = format(L["|cffffd700%dg|r "], gold) .. text
    end
    return text
end

local function Notice(text)
    UIErrorsFrame:AddMessage(text, 1.0, 0.82, 0.0, 1.0, 5)
end

local function SetFont(fontString, size, flags)
    fontString:SetFont(FONT, size, flags or "OUTLINE")
end

local function DialogBackdrop(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
end

local function TooltipBackdrop(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
end

local hiddenBars = CreateFrame("Frame")
hiddenBars:Hide()

for index = 1, 12 do
    getglobal("ActionButton" .. index):SetParent(hiddenBars)
end
for _, name in ipairs({ "BonusActionBarFrame", "ShapeshiftBarFrame", "MultiBarBottomLeft", "MultiBarBottomRight",
        "MultiBarRight", "MultiBarLeft", "ActionBarUpButton", "ActionBarDownButton" }) do
    local frame = getglobal(name)
    if frame then
        frame:SetParent(hiddenBars)
    end
end
for _, name in ipairs({ "MainMenuBarTexture0", "MainMenuBarTexture1", "MainMenuBarTexture2", "MainMenuBarTexture3",
        "MainMenuBarLeftEndCap", "MainMenuBarRightEndCap", "MainMenuBarPageNumber" }) do
    local region = getglobal(name)
    if region then
        region:Hide()
    end
end

UseAction = function() end

local RARITIES = {
    [0] = { name = L["Common"], r = 1, g = 1, b = 1 },
    [1] = { name = L["Uncommon"], r = 0.12, g = 1, b = 0 },
    [2] = { name = L["Rare"], r = 0, g = 0.44, b = 0.87 },
    [3] = { name = L["Epic"], r = 0.64, g = 0.21, b = 0.93 },
    [4] = { name = L["Legendary"], r = 1, g = 0.5, b = 0 },
}

local function RarityText(rarity, text)
    local color = RARITIES[rarity] or RARITIES[0]
    return format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, text)
end

local buffTimers = CreateFrame("Frame")
buffTimers:RegisterEvent("VARIABLES_LOADED")
buffTimers:SetScript("OnEvent", function()
    SHOW_BUFF_DURATIONS = "1"
end)

local offerFrame = CreateFrame("Frame", "VanillaBonkOffer", UIParent)
offerFrame:SetAllPoints(UIParent)
offerFrame:SetFrameStrata("DIALOG")
offerFrame:EnableMouse(false)
offerFrame:Hide()

offerFrame.dim = offerFrame:CreateTexture(nil, "BACKGROUND")
offerFrame.dim:SetTexture("Interface\\AddOns\\HordesOfAzeroth\\Textures\\OfferVignette")
offerFrame.dim:SetPoint("TOPLEFT", WorldFrame, "TOPLEFT", -2, 2)
offerFrame.dim:SetPoint("BOTTOMRIGHT", WorldFrame, "BOTTOMRIGHT", 2, -2)

offerFrame.chrome = CreateFrame("Frame", nil, offerFrame)
offerFrame.chrome:SetAllPoints(offerFrame)

offerFrame.title = offerFrame.chrome:CreateFontString(nil, "OVERLAY")
offerFrame.title:SetFont("Fonts\\MORPHEUS.TTF", 46, "OUTLINE")
offerFrame.title:SetPoint("CENTER", offerFrame, "CENTER", 0, 230)
offerFrame.title:SetTextColor(1, 0.82, 0)

offerFrame.subtitle = offerFrame.chrome:CreateFontString(nil, "OVERLAY")
SetFont(offerFrame.subtitle, 13, "")
offerFrame.subtitle:SetShadowColor(0, 0, 0, 1)
offerFrame.subtitle:SetShadowOffset(1, -1)
offerFrame.subtitle:SetPoint("CENTER", offerFrame, "CENTER", 0, 186)
offerFrame.subtitle:SetTextColor(0.9, 0.83, 0.64)
offerFrame.subtitle:SetText(L["Choose an upgrade"])

for side = 1, 2 do
    local line = offerFrame.chrome:CreateTexture(nil, "ARTWORK")
    line:SetTexture(VanillaBonkUI.FLAT)
    line:SetWidth(60)
    line:SetHeight(1)
    if side == 1 then
        line:SetPoint("RIGHT", offerFrame.subtitle, "LEFT", -12, 0)
        line:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0, 1, 0.82, 0, 0.7)
    else
        line:SetPoint("LEFT", offerFrame.subtitle, "RIGHT", 12, 0)
        line:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0.7, 1, 0.82, 0, 0)
    end
end

offerFrame.hint = offerFrame.chrome:CreateFontString(nil, "OVERLAY")
SetFont(offerFrame.hint, 11, "")
offerFrame.hint:SetShadowColor(0, 0, 0, 1)
offerFrame.hint:SetShadowOffset(1, -1)
offerFrame.hint:SetPoint("CENTER", offerFrame, "CENTER", 0, -206)
offerFrame.hint:SetTextColor(0.78, 0.78, 0.78)

offerFrame.cards = {}
offerFrame.cardDrop = 0
offerFrame.MAX_GROWTH = 120

local BANISH_RED = { 1, 0.25, 0.2 }

offerFrame.banishEscape = CreateFrame("Frame", "VanillaBonkBanishEscape", UIParent)
offerFrame.banishEscape:SetWidth(1)
offerFrame.banishEscape:SetHeight(1)
offerFrame.banishEscape:Hide()
tinsert(UISpecialFrames, "VanillaBonkBanishEscape")

local function SetBanishMode(on)
    on = on and true or false
    offerFrame.banishing = on
    for _, card in ipairs(offerFrame.cards) do
        if card:IsShown() and card.lineColor then
            if on then
                card:SetBackdropBorderColor(BANISH_RED[1], BANISH_RED[2], BANISH_RED[3])
                card.line:SetBackdropBorderColor(BANISH_RED[1], BANISH_RED[2], BANISH_RED[3], 1)
                card.art:SetVertexColor(1, 0.55, 0.5)
                card.highlight:SetVertexColor(1, 0.3, 0.25)
            else
                local color = card.lineColor
                local border = card.borderColor
                card:SetBackdropBorderColor(border[1], border[2], border[3])
                card.line:SetBackdropBorderColor(color[1], color[2], color[3], color[4])
                card.art:SetVertexColor(1, 1, 1)
                card.highlight:SetVertexColor(1, 1, 1)
            end
            if GetMouseFocus() == card then
                if on then
                    card.line:SetBackdropBorderColor(1, 0.1, 0.05, 1)
                else
                    card.line:SetBackdropBorderColor(1, 0.82, 0, 1)
                end
            end
        end
    end
    if offerFrame.banish then
        offerFrame.banish:SetText(on and L["Cancel"] or (L["|cffff6060Banish ("] .. (VB.banishes or 0) .. ")|r"))
    end
    offerFrame.hint:SetText(on and L["|cffff6060Click a card to banish it, or press Escape to cancel.|r"] or (offerFrame.hintText or ""))
    if on then
        offerFrame.banishEscape:Show()
    else
        offerFrame.banishEscape:Hide()
    end
end

offerFrame.banishEscape:SetScript("OnHide", function()
    if not this:IsShown() and offerFrame.banishing then
        SetBanishMode(false)
    end
end)

local function Pick(index)
    if not VB.offer[index] or VB.picking then
        return
    end
    VB.picking = true
    VB.pickedIndex = index
    Command((VB.offerSource == "ley" and "leypick " or "pick ") .. index)
end

local function Banish(index)
    if not VB.offer[index] or VB.picking or (VB.banishes or 0) < 1 or VB.offerSource == "ley" then
        return
    end
    VB.picking = true
    SetBanishMode(false)
    Command("banish " .. index)
end

local function ToggleBanish()
    if offerFrame.banishing then
        SetBanishMode(false)
    elseif not VB.picking and (VB.banishes or 0) > 0 and VB.offerSource ~= "ley" then
        SetBanishMode(true)
    end
end

local function Reroll()
    if VB.picking or (VB.rerolls or 0) < 1 then
        return
    end
    VB.picking = true
    Command("reroll")
end

local function Skip()
    if VB.picking or (VB.skips or 0) < 1 then
        return
    end
    VB.picking = true
    Command("pass")
end

local function Lock(index)
    if not VB.offer[index] or VB.picking or VB.offerSource ~= "chest" then
        return
    end
    Command("lock " .. index)
end

offerFrame.skip = VanillaBonkUI.SliceButton(CreateFrame("Button", nil, offerFrame.chrome, "UIPanelButtonTemplate"))
offerFrame.skip:SetWidth(120)
offerFrame.skip:SetHeight(24)
offerFrame.skip:SetScript("OnClick", Skip)

offerFrame.reroll = VanillaBonkUI.SliceButton(CreateFrame("Button", nil, offerFrame.chrome, "UIPanelButtonTemplate"))
offerFrame.reroll:SetWidth(120)
offerFrame.reroll:SetHeight(24)
offerFrame.reroll:SetScript("OnClick", Reroll)

offerFrame.banish = VanillaBonkUI.SliceButton(CreateFrame("Button", nil, offerFrame.chrome, "UIPanelButtonTemplate"))
offerFrame.banish:SetWidth(120)
offerFrame.banish:SetHeight(24)
offerFrame.banish:SetScript("OnClick", ToggleBanish)

offerFrame.autopick = VanillaBonkUI.SliceButton(CreateFrame("Button", nil, offerFrame.chrome, "UIPanelButtonTemplate"))
offerFrame.autopick:SetWidth(120)
offerFrame.autopick:SetHeight(24)
offerFrame.autopick:SetScript("OnClick", function()
    if VB.picking then
        return
    end
    PlaySound("igMainMenuOptionCheckBoxOn")
    Command("pick auto")
end)
offerFrame.autopick:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_TOP")
    GameTooltip:SetText("Auto-pick")
    GameTooltip:AddLine("Picks your remaining " .. (VB.catchUp or 0) .. " level-ups.", 1, 1, 1, 1)
    GameTooltip:AddLine("Prioritizes spells and passives you have already chosen.", 1, 1, 1, 1)
    GameTooltip:AddLine("Will stop when the selection only shows new cards.", 1, 1, 1, 1)
    GameTooltip:Show()
end)
offerFrame.autopick:SetScript("OnLeave", function() GameTooltip:Hide() end)

local CardArt = VanillaBonkUI.CardArt

local CARD_HEIGHT = 300
local DAMAGE_ROW_HEIGHT = 14
local DAMAGE_ROW_GAP = 4
local DAMAGE_ARROW_SIZE = 12
local DAMAGE_ARROW = "Interface\\MoneyFrame\\Arrow-Right-Up"
local STAT_BLOCK = { labelSize = 10, valueSize = 16, step = 40, arrowGap = 4 }

local STONE_BORDER = { edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 24 }
local DARKMOON_CLOTH = "World\\ENVIRONMENT\\DOODAD\\Carnival\\bm_Carnie_tarp01"
local DARKMOON_BANNER = "World\\ENVIRONMENT\\DOODAD\\Carnival\\Darkmoon_Banner01"
local MAX_CARDS = 6
local KEYWORD_ALIASES = {
    ["Chill"] = { "Chilled" },
    ["Frozen"] = { "Freezes", "Freeze", "Shatter" },
    ["Hunter's Mark"] = { "Marked" },
    ["Poison"] = { "Poisoned" },
    ["Bleed"] = { "Bleeding" },
    ["Dazed"] = { "Dazes", "Daze" },
}
VB.keywords = {}

local function IsLetter(char)
    return char ~= "" and strfind(char, "%a") ~= nil
end

local function KeywordTerms()
    if VB.keywordTerms then
        return VB.keywordTerms
    end
    local terms = {}
    for id, keyword in pairs(VB.keywords) do
        tinsert(terms, { text = keyword.name, id = id })
        for _, alias in ipairs(KEYWORD_ALIASES[keyword.name] or {}) do
            tinsert(terms, { text = alias, id = id })
        end
    end
    for _, term in ipairs(VB.statTerms or {}) do
        tinsert(terms, term)
    end
    table.sort(terms, function(a, b) return strlen(a.text) > strlen(b.text) end)
    VB.keywordTerms = terms
    return terms
end

local HTML_ESCAPES = { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;" }

local function MatchKeyword(text, pos, terms)
    if IsLetter(strsub(text, pos - 1, pos - 1)) then
        return nil
    end
    for _, term in ipairs(terms) do
        local stop = pos + strlen(term.text) - 1
        if strsub(text, pos, stop) == term.text and not IsLetter(strsub(text, stop + 1, stop + 1)) then
            local wholeLabel = pos == 1 and stop == strlen(text)
            if not term.stat or wholeLabel or strfind(strsub(text, max(1, pos - 2), pos - 1), "^[%d%%] $") then
                return term, stop
            end
        end
    end
end

VB.keywordColors = {
    ["Chill"] = { 0.41, 0.8, 0.94 },
    ["Frozen"] = { 0.41, 0.8, 0.94 },
    ["Burning"] = { 1, 0.71, 0.24 },
    ["Fire Vulnerability"] = { 1, 0.49, 0.1 },
    ["Bleed"] = { 1, 0.33, 0.33 },
    ["Poison"] = { 0.4, 0.85, 0.3 },
    ["Nature Vulnerability"] = { 0.25, 0.78, 0.71 },
    ["Static"] = { 0.25, 0.78, 0.71 },
    ["Decay"] = { 0.7, 0.55, 1 },
    ["Shadow Vulnerability"] = { 0.7, 0.55, 1 },
    ["Sunder Armor"] = { 0.78, 0.61, 0.43 },
    ["Dazed"] = { 0.78, 0.61, 0.43 },
    ["Hunter's Mark"] = { 0.78, 0.61, 0.43 },
}

function VB.KeywordRGB(id)
    if VB.statTips and VB.statTips[id] then
        return 1, 1, 1
    end
    local keyword = VB.keywords[id]
    local color = keyword and VB.keywordColors[keyword.name]
    if color then
        return color[1], color[2], color[3]
    end
    return 0.41, 0.8, 0.94
end

function VB.TermColor(term)
    local r, g, b = VB.KeywordRGB(term.id)
    return format("|cff%02x%02x%02x", floor(r * 255 + 0.5), floor(g * 255 + 0.5), floor(b * 255 + 0.5))
end

local function KeywordHtml(text)
    local terms = KeywordTerms()
    local pieces, links = {}, {}
    local pos, length = 1, strlen(text)
    while pos <= length do
        local char = strsub(text, pos, pos)
        if char == "|" then
            local size = strsub(text, pos + 1, pos + 1) == "c" and 10 or 2
            tinsert(pieces, strsub(text, pos, pos + size - 1))
            pos = pos + size
        elseif char == "\n" then
            tinsert(pieces, "<br/>")
            pos = pos + 1
        else
            local term, stop = MatchKeyword(text, pos, terms)
            if term then
                tinsert(pieces, VB.TermColor(term) .. '<a href="bonkkw:' .. term.id .. '">' .. term.text .. "</a>|r")
                tinsert(links, term.id)
                pos = stop + 1
            else
                tinsert(pieces, HTML_ESCAPES[char] or char)
                pos = pos + 1
            end
        end
    end
    return '<html><body><p align="center">' .. table.concat(pieces) .. "</p></body></html>", links
end

local function FindKeyword(text)
    local terms = KeywordTerms()
    for pos = 1, strlen(text) do
        local term, stop = MatchKeyword(text, pos, terms)
        if term then
            return term, pos, stop
        end
    end
end

local function ColorKeywords(text)
    local terms = KeywordTerms()
    local pieces = {}
    local pos, length = 1, strlen(text)
    while pos <= length do
        local term, stop = MatchKeyword(text, pos, terms)
        if term then
            tinsert(pieces, VB.TermColor(term) .. term.text .. "|r")
            pos = stop + 1
        else
            tinsert(pieces, strsub(text, pos, pos))
            pos = pos + 1
        end
    end
    return table.concat(pieces)
end

function VanillaBonkUI.InspectShown()
    return VanillaBonkShop:IsShown() and VB.shop ~= nil and VB.shop.inspect == true
end

function VanillaBonkUI.HideInspect()
    VanillaBonkShop:Hide()
end

function VanillaBonkUI.InRun()
    return VB.inRun
end

function VanillaBonkUI.HasKeywordTip(id)
    return id ~= nil and ((VB.statTips and VB.statTips[id]) or VB.keywords[id]) ~= nil
end

function VanillaBonkUI.FillKeywordTip(tooltip, id)
    local stat = VB.statTips and VB.statTips[id]
    if stat then
        tooltip:AddLine(stat.name, 1, 1, 1)
        tooltip:AddLine(stat.text, 1, 0.82, 0, 1)
        return
    end
    local keyword = VB.keywords[id]
    tooltip:AddLine(keyword.name, VB.KeywordRGB(id))
    tooltip:AddLine(keyword.description, 1, 1, 1, 1)
end

local function ShowKeywordTooltip(id, owner)
    if not VanillaBonkUI.HasKeywordTip(id) then
        return
    end
    GameTooltip:SetOwner(owner, "ANCHOR_TOP")
    VanillaBonkUI.FillKeywordTip(GameTooltip, id)
    GameTooltip:Show()
end

local function HighlightCard(card)
    if offerFrame.banishing then
        card.line:SetBackdropBorderColor(1, 0.1, 0.05, 1)
    else
        card.line:SetBackdropBorderColor(1, 0.82, 0, 1)
    end
end

local function UnhighlightCard(card)
    if offerFrame.banishing then
        card.line:SetBackdropBorderColor(BANISH_RED[1], BANISH_RED[2], BANISH_RED[3], 1)
        return
    end
    local color = card.lineColor
    card.line:SetBackdropBorderColor(color[1], color[2], color[3], color[4])
end

local function ClickCard(card, button)
    if button == "RightButton" then
        if offerFrame.banishing then
            SetBanishMode(false)
        end
    elseif offerFrame.banishing then
        Banish(card.index)
    else
        Pick(card.index)
    end
end

local KEYWORD_HOVER_MIN_FRAMES = 2
local KEYWORD_HOVER_MAX_FRAMES = 120
local function UnderlineKeyword(hover, width)
    local dotWidth, dotStep = 2, 4
    hover.dots = hover.dots or {}
    local count = floor((width - dotWidth) / dotStep) + 1
    local r, g, b = VB.KeywordRGB(hover.keyword)
    for index = 1, count do
        local dot = hover.dots[index]
        if not dot then
            dot = hover:CreateTexture(nil, "OVERLAY")
            dot:SetTexture(VanillaBonkUI.FLAT)
            dot:SetWidth(dotWidth)
            dot:SetHeight(1)
            hover.dots[index] = dot
        end
        dot:SetVertexColor(r, g, b, 0.85)
        dot:ClearAllPoints()
        dot:SetPoint("BOTTOMLEFT", hover, "BOTTOMLEFT", (index - 1) * dotStep, 0)
        dot:Show()
    end
    for index = count + 1, table.getn(hover.dots) do
        hover.dots[index]:Hide()
    end
end

local function ReadingOrder(a, b)
    local aTop, bTop = a:GetTop(), b:GetTop()
    if math.abs(aTop - bTop) > 2 then
        return aTop > bTop
    end
    return a:GetLeft() < b:GetLeft()
end

local function KeywordSpans(html)
    local spans = {}
    for _, span in ipairs({ html:GetChildren() }) do
        if span:IsShown() and span:GetLeft() and span:GetTop() then
            span:EnableMouse(false)
            tinsert(spans, span)
        end
    end
    table.sort(spans, ReadingOrder)
    return spans
end

local function CreateKeywordHover(card, index, parent)
    local hover = CreateFrame("Button", nil, parent or card)
    hover:SetFrameLevel(card.description:GetFrameLevel() + 2)
    hover:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    hover.card = card
    hover:SetScript("OnEnter", function()
        HighlightCard(this.card)
        ShowKeywordTooltip(this.keyword, this)
    end)
    hover:SetScript("OnLeave", function()
        GameTooltip:Hide()
        if not MouseIsOver(this.card) then
            UnhighlightCard(this.card)
        end
    end)
    hover:SetScript("OnClick", function()
        ClickCard(this.card, arg1)
    end)
    if index then
        card.hovers[index] = hover
    end
    return hover
end

local function PlaceKeywordHovers(card, spans)
    local html = card.description
    for index, span in ipairs(spans) do
        local hover = card.hovers[index] or CreateKeywordHover(card, index)
        hover:ClearAllPoints()
        hover:SetPoint("TOPLEFT", html, "TOPLEFT", span:GetLeft() - html:GetLeft(), span:GetTop() - html:GetTop())
        hover:SetWidth(span:GetWidth())
        hover:SetHeight(span:GetHeight())
        hover.keyword = card.descriptionLinks and card.descriptionLinks[index]
        UnderlineKeyword(hover, span:GetWidth())
        hover:Show()
    end
    for index = table.getn(spans) + 1, table.getn(card.hovers) do
        card.hovers[index]:Hide()
    end
end

local function SetKeywordText(card)
    for _, hover in ipairs(card.hovers) do
        hover:Hide()
    end
    card.description:SetText(card.descriptionHtml or "")
    card.description.hoverFrames = 0
end

local function UpdateKeywordHovers(html)
    local links = table.getn(html.card.descriptionLinks or {})
    if links == 0 then
        html.hoverFrames = nil
        return
    end
    html.hoverFrames = html.hoverFrames + 1
    if html.hoverFrames < KEYWORD_HOVER_MIN_FRAMES then
        return
    end
    local spans = KeywordSpans(html)
    if table.getn(spans) >= links then
        html.hoverFrames = nil
        PlaceKeywordHovers(html.card, spans)
    elseif html.hoverFrames >= KEYWORD_HOVER_MAX_FRAMES then
        html.hoverFrames = nil
    end
end

local function RebuildKeywordLinks(card)
    if card.descriptionHtml then
        SetKeywordText(card)
    end
end

for index = 1, MAX_CARDS do
    local card = CreateFrame("Button", nil, offerFrame)
    card:SetHeight(CARD_HEIGHT)
    card:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    card.index = index

    card.art = card:CreateTexture(nil, "BACKGROUND")
    card.art:SetPoint("TOPLEFT", card, "TOPLEFT", 9, -9)
    card.art:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -9, 9)
    card.shade = card:CreateTexture(nil, "BORDER")
    card.shade:SetAllPoints(card.art)
    VanillaBonkUI.Shade(card.shade, 0.95, 0.1)

    card:SetBackdrop(STONE_BORDER)
    card.line = CreateFrame("Frame", nil, card)
    card.line:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -8)
    card.line:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 8)
    card.line:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })

    card.slot = VanillaBonkUI.Slot(card, 56, "Frame")
    card.slot:SetPoint("TOP", card, "TOP", 0, -34)
    card.glow = card.slot:CreateTexture(nil, "OVERLAY")
    card.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    card.glow:SetBlendMode("ADD")
    card.glow:SetWidth(96)
    card.glow:SetHeight(96)
    card.glow:SetPoint("CENTER", card.slot, "CENTER", 0, 0)

    card.crest = card:CreateTexture(nil, "ARTWORK")
    card.crest:SetTexture(DARKMOON_BANNER)
    card.crest:SetTexCoord(8 / 256, 182 / 256, 16 / 256, 190 / 256)
    card.crest:SetWidth(116)
    card.crest:SetHeight(116)
    card.crest:SetPoint("TOP", card, "TOP", 0, -32)
    card.crest:Hide()
    card.eye = VanillaBonkUI.Ring(card, 52, true)
    card.eye:SetPoint("CENTER", card.crest, "CENTER", 0, 0)
    card.eye.icon = VanillaBonkUI.RingArt(card.eye, "")
    card.eye:Hide()

    card.key = VanillaBonkUI.Ring(card, 28)
    card.key:SetPoint("TOPLEFT", card, "TOPLEFT", 13, -13)
    card.key.text = VanillaBonkUI.Text(card.key, 13)
    card.key.text:SetPoint("CENTER", card.key, "CENTER", 0, 0)
    card.key.text:SetTextColor(1, 0.82, 0)
    card.key.text:SetText(index)

    card.name = VanillaBonkUI.Text(card, 17)
    card.name:SetPoint("TOP", card, "TOP", 0, -104)
    card.name:SetJustifyH("CENTER")

    card.level = VanillaBonkUI.Text(card, 11)
    card.level:SetPoint("TOP", card.name, "BOTTOM", 0, -4)
    card.level:SetTextColor(0.85, 0.85, 0.85)

    card.divider = card:CreateTexture(nil, "ARTWORK")
    card.divider:SetTexture(VanillaBonkUI.FLAT)
    card.divider:SetHeight(1)
    card.divider:SetPoint("TOPRIGHT", card.level, "BOTTOM", 0, -11)
    card.divider:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0, 1, 0.82, 0, 0.75)
    card.dividerRight = card:CreateTexture(nil, "ARTWORK")
    card.dividerRight:SetTexture(VanillaBonkUI.FLAT)
    card.dividerRight:SetHeight(1)
    card.dividerRight:SetPoint("TOPLEFT", card.level, "BOTTOM", 0, -11)
    card.dividerRight:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0.75, 1, 0.82, 0, 0)

    card.count = VanillaBonkUI.Text(card, 11)
    card.count:SetPoint("TOPRIGHT", card, "TOPRIGHT", -16, -17)
    card.count:SetTextColor(0.85, 0.85, 0.85)

    card.measure = VanillaBonkUI.Text(card, 13)
    card.measure:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
    card.measure:SetJustifyH("CENTER")
    card.measure:SetTextColor(0, 0, 0, 0)
    card.measure:SetShadowColor(0, 0, 0, 0)

    card.damage = CreateFrame("Frame", nil, card)
    card.damage:SetHeight(DAMAGE_ROW_HEIGHT)
    card.damage.label = VanillaBonkUI.Text(card.damage, 12)
    card.damage.label:SetTextColor(0.85, 0.85, 0.85)
    card.damage.before = VanillaBonkUI.Text(card.damage, 12)
    card.damage.before:SetTextColor(0.6, 0.6, 0.6)
    card.damage.strike = card.damage:CreateTexture(nil, "OVERLAY")
    card.damage.strike:SetTexture(VanillaBonkUI.FLAT)
    card.damage.strike:SetVertexColor(0.75, 0.75, 0.75)
    card.damage.strike:SetHeight(1)
    card.damage.strike:SetPoint("LEFT", card.damage.before, "LEFT", 0, 0)
    card.damage.arrow = card.damage:CreateTexture(nil, "ARTWORK")
    card.damage.arrow:SetTexture(DAMAGE_ARROW)
    card.damage.arrow:SetWidth(DAMAGE_ARROW_SIZE)
    card.damage.arrow:SetHeight(DAMAGE_ARROW_SIZE)
    card.damage.after = VanillaBonkUI.Text(card.damage, 12)
    card.damage.after:SetTextColor(0.13, 1, 0.13)
    card.damage:Hide()

    card.description = CreateFrame("SimpleHTML", nil, card)
    card.description:SetPoint("TOP", card.divider, "BOTTOMRIGHT", 0, -10)
    card.description:SetFont("P", FONT, 13, "")
    card.description:SetTextColor("P", 1, 0.82, 0)
    card.description:SetShadowColor("P", 0, 0, 0, 1)
    card.description:SetShadowOffset("P", 1, -1)
    card.description.card = card
    card.hovers = {}
    card.description:SetScript("OnUpdate", function()
        if this.hoverFrames then
            UpdateKeywordHovers(this)
        end
    end)

    card.highlight = card:CreateTexture(nil, "HIGHLIGHT")
    card.highlight:SetTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
    card.highlight:SetBlendMode("ADD")
    card.highlight:SetTexCoord(0, 0.625, 0, 0.6875)
    card.highlight:SetAlpha(0.35)
    card.highlight:SetAllPoints(card.art)

    card:SetScript("OnClick", function()
        ClickCard(this, arg1)
    end)
    card:SetScript("OnEnter", function()
        HighlightCard(this)
    end)
    card:SetScript("OnLeave", function()
        UnhighlightCard(this)
    end)

    card.lock = VanillaBonkUI.SliceButton(CreateFrame("Button", nil, card, "UIPanelButtonTemplate"))
    card.lock:SetWidth(80)
    card.lock:SetHeight(20)
    card.lock:SetPoint("BOTTOM", card, "BOTTOM", 0, 18)
    card.lock.index = index
    card.lock:SetScript("OnClick", function()
        Lock(this.index)
    end)

    offerFrame.cards[index] = card
end

local OFFER_POP = 0.24
local OFFER_STAGGER = 0.05
local OFFER_CLOSE = 0.18
local OFFER_DIM = 1
local GARBAGE_DUE = 0.75

local function CollectGarbageIfDue()
    local used, threshold = gcinfo()
    if used and threshold and threshold > 0 and used >= threshold * GARBAGE_DUE then
        collectgarbage()
    end
end

local function EaseOut(t)
    t = 1 - t
    return 1 - t * t * t
end

local function EaseBack(t)
    t = t - 1
    return 1 + 2.70158 * t * t * t + 1.70158 * t * t
end

local function Progress(t, start, length)
    return min(1, max(0, (t - start) / length))
end

local function PlaceCard(card, scale, alpha, rise)
    card:SetScale(scale)
    card:SetAlpha(alpha)
    card.alphaNow = alpha
    card:ClearAllPoints()
    card:SetPoint("CENTER", offerFrame, "CENTER", card.x / scale, (16 - offerFrame.cardDrop + rise) / scale)
end

local CHOICE_KEYS = {
    ["1"] = "VANILLABONK_CHOICE1", ["2"] = "VANILLABONK_CHOICE2", ["3"] = "VANILLABONK_CHOICE3",
    ["4"] = "VANILLABONK_CHOICE4", ["5"] = "VANILLABONK_CHOICE5", ["6"] = "VANILLABONK_CHOICE6",
    ["R"] = "VANILLABONK_REROLL", ["X"] = "VANILLABONK_SKIP", ["B"] = "VANILLABONK_BANISH",
}
BINDING_HEADER_VANILLABONK = "Hordes of Azeroth"
for index = 1, 6 do
    setglobal("BINDING_NAME_VANILLABONK_CHOICE" .. index, L("Level-up choice: card {1}", index))
end
BINDING_NAME_VANILLABONK_REROLL = L["Level-up choice: reroll"]
BINDING_NAME_VANILLABONK_SKIP = L["Level-up choice: skip"]
BINDING_NAME_VANILLABONK_BANISH = L["Level-up choice: banish"]

local function GiveBackChoiceKeys()
    if not VanillaBonkChoiceKeys or (VanillaBonkGlyphs and VanillaBonkGlyphs.open) then
        return
    end
    for key, action in pairs(VanillaBonkChoiceKeys) do
        if action ~= "" then
            SetBinding(key, action)
        else
            SetBinding(key)
        end
    end
    VanillaBonkChoiceKeys = nil
end

local function TakeChoiceKeys()
    if VanillaBonkChoiceKeys then
        return
    end
    local before = {}
    for key, action in pairs(CHOICE_KEYS) do
        before[key] = GetBindingAction(key) or ""
        SetBinding(key, action)
    end
    VanillaBonkChoiceKeys = before
end

VanillaBonk_TakeChoiceKeys = TakeChoiceKeys
VanillaBonk_GiveBackChoiceKeys = GiveBackChoiceKeys

function VanillaBonk_ChoiceKey(key)
    if VanillaBonkMenu and VanillaBonkMenu:IsShown() then
        return
    end
    local index = tonumber(key)
    if index and VanillaBonk_GlyphKey and VanillaBonk_GlyphKey(index) then
        return
    end
    if not offerFrame.open then
        return
    end
    if index and offerFrame.banishing then
        Banish(index)
    elseif index then
        Pick(index)
    elseif key == "R" then
        Reroll()
    elseif key == "X" then
        Skip()
    elseif key == "B" then
        ToggleBanish()
    end
end

local choiceKeys = CreateFrame("Frame")
choiceKeys:RegisterEvent("VARIABLES_LOADED")
choiceKeys:RegisterEvent("PLAYER_LOGOUT")
choiceKeys:SetScript("OnEvent", GiveBackChoiceKeys)

local CARD_TEXT_WIDTH = 220
local function LayoutDamageRow(card, option, hasLock)
    local row = card.damage
    local after = option and option.damageAfter or ""
    if after == "" then
        row:Hide()
        return 0
    end
    local before = option.damageBefore or ""
    local label = option.damageLabel or ""
    if label == "" then
        label = L["Damage"]
    end
    row.label:SetText(label ~= "" and label .. ":" or "")
    row.before:SetText(before)
    row.after:SetText(after)
    local changed = before ~= ""
    local labelWidth = label ~= "" and row.label:GetStringWidth() + DAMAGE_ROW_GAP or 0
    local beforeWidth = changed and row.before:GetStringWidth() or 0
    local arrowWidth = changed and DAMAGE_ARROW_SIZE + 2 * DAMAGE_ROW_GAP or 0
    local total = labelWidth + beforeWidth + arrowWidth + row.after:GetStringWidth()
    if labelWidth > 0 and total > card:GetWidth() - 16 then
        row.label:SetText("")
        total = total - labelWidth
        labelWidth = 0
    end
    row:SetWidth(total)
    row:ClearAllPoints()
    row:SetPoint("BOTTOM", card, "BOTTOM", 0, hasLock and 46 or 18)
    row.label:ClearAllPoints()
    row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.before:ClearAllPoints()
    row.before:SetPoint("LEFT", row, "LEFT", labelWidth, 0)
    row.strike:SetWidth(max(1, beforeWidth))
    row.arrow:ClearAllPoints()
    row.arrow:SetPoint("LEFT", row, "LEFT", labelWidth + beforeWidth + DAMAGE_ROW_GAP, 0)
    row.after:ClearAllPoints()
    row.after:SetPoint("LEFT", row, "LEFT", labelWidth + beforeWidth + arrowWidth, 0)
    if changed then
        row.before:Show()
        row.strike:Show()
        row.arrow:Show()
    else
        row.before:Hide()
        row.strike:Hide()
        row.arrow:Hide()
    end
    row:Show()
    return DAMAGE_ROW_HEIGHT + DAMAGE_ROW_GAP
end

local function FitCardText(card, width, darkmoon, hasLock, damageRoom)
    local scale = min(1, width / CARD_TEXT_WIDTH)
    card.name:SetFont(FONT, max(12, floor(17 * scale + 0.5)))
    card.name:SetWidth(width - 28)
    card.level:SetFont(FONT, max(9, floor(11 * scale + 0.5)))
    card.level:SetWidth(width - 20)
    card.count:SetFont(FONT, max(9, floor(11 * scale + 0.5)))
    card.description:SetWidth(width - 36)
    card.measure:SetWidth(width - 36)
    card.measure:SetText(card.descriptionText or "")

    local top = darkmoon and 158 or 104
    local used = top + card.name:GetHeight() + 4 + card.level:GetHeight() + 11 + 1 + 10
    local room = offerFrame.cardHeight - used - (hasLock and 46 or 18) - (damageRoom or 0)
    local size = max(10, floor(13 * scale + 0.5))
    while size > 9 do
        card.measure:SetFont(FONT, size)
        local needed = card.measure:GetHeight()
        if not needed or needed == 0 or needed <= room then
            break
        end
        size = size - 1
    end
    card.measure:SetFont(FONT, size)
    card.overflow = max(0, (card.measure:GetHeight() or 0) - room)
    card.description:SetFont("P", FONT, size, "")
    card.description:SetHeight(max(room, 12))
    card.descriptionHtml, card.descriptionLinks = KeywordHtml(card.descriptionText or "")
    SetKeywordText(card)
    return room
end

local function GetStatBlock(card, index)
    card.stats = card.stats or {}
    local block = card.stats[index]
    if block then
        return block
    end
    block = CreateFrame("Frame", nil, card)
    block.label = VanillaBonkUI.Text(block, STAT_BLOCK.labelSize)
    block.label:SetTextColor(0.65, 0.65, 0.65)
    block.label:SetJustifyH("CENTER")
    block.label:SetPoint("TOP", block, "TOP", 0, 0)
    block.before = VanillaBonkUI.Text(block, STAT_BLOCK.valueSize)
    block.before:SetTextColor(0.6, 0.6, 0.6)
    block.arrow = block:CreateTexture(nil, "ARTWORK")
    block.arrow:SetTexture(DAMAGE_ARROW)
    block.after = VanillaBonkUI.Text(block, STAT_BLOCK.valueSize)
    block.after:SetTextColor(0.13, 1, 0.13)
    block.measure = VanillaBonkUI.Text(block, STAT_BLOCK.labelSize)
    block.measure:SetTextColor(0, 0, 0, 0)
    block.measure:SetShadowColor(0, 0, 0, 0)
    block.measure:SetPoint("TOPLEFT", block, "TOPLEFT", 0, 0)
    block.hover = CreateKeywordHover(card, nil, block)
    card.stats[index] = block
    return block
end

local function HideStats(card, from)
    if not card.stats then
        return
    end
    for index = from, getn(card.stats) do
        card.stats[index]:Hide()
    end
end

function STAT_BLOCK.PlaceKeyword(block, label, size)
    local hover = block.hover
    local term, start = FindKeyword(label)
    if not term then
        hover:Hide()
        return
    end
    block.measure:SetFont(FONT, size)
    block.measure:SetText(strsub(label, 1, start - 1))
    local prefix = start > 1 and block.measure:GetStringWidth() or 0
    block.measure:SetText(term.text)
    local word = block.measure:GetStringWidth()
    hover:ClearAllPoints()
    hover:SetPoint("TOPLEFT", block, "TOP", prefix - block.label:GetStringWidth() / 2, 0)
    hover:SetWidth(word)
    hover:SetHeight(size + 2)
    hover.keyword = term.id
    UnderlineKeyword(hover, word)
    hover:Show()
end

local function LayoutStats(card, stats, width, room)
    local scale = min(1, width / CARD_TEXT_WIDTH)
    local count = getn(stats)
    local labelSize = max(8, floor(STAT_BLOCK.labelSize * scale + 0.5))
    local step = min(floor(STAT_BLOCK.step * scale + 0.5), floor(room / max(1, count)))
    local valueSize = max(10, min(floor(STAT_BLOCK.valueSize * scale + 0.5), step - labelSize - 8))
    local arrowSize = floor(valueSize * 0.8 + 0.5)
    for index, stat in ipairs(stats) do
        local block = GetStatBlock(card, index)
        block:SetWidth(width - 20)
        block:SetHeight(step)
        block:ClearAllPoints()
        block:SetPoint("TOP", card.divider, "BOTTOMRIGHT", 0, -8 - (index - 1) * step)
        block.label:SetFont(FONT, labelSize)
        block.label:SetWidth(width - 24)
        block.label:SetText(ColorKeywords(stat.label))
        STAT_BLOCK.PlaceKeyword(block, stat.label, labelSize)
        block.before:SetFont(FONT, valueSize)
        block.after:SetFont(FONT, valueSize)
        local capped = stat.before == stat.after
        block.before:SetText(capped and (stat.before .. L[" (at cap)"]) or stat.before)
        block.after:SetText(capped and "" or stat.after)
        block.arrow:SetWidth(arrowSize)
        block.arrow:SetHeight(arrowSize)
        local total = block.before:GetStringWidth()
        if capped then
            block.arrow:Hide()
        else
            block.arrow:Show()
            total = total + arrowSize + 2 * STAT_BLOCK.arrowGap + block.after:GetStringWidth()
        end
        block.before:ClearAllPoints()
        block.before:SetPoint("TOPLEFT", block, "TOP", -total / 2, -(block.label:GetHeight() + 3))
        block.arrow:ClearAllPoints()
        block.arrow:SetPoint("LEFT", block.before, "RIGHT", STAT_BLOCK.arrowGap, 0)
        block.after:ClearAllPoints()
        block.after:SetPoint("LEFT", block.arrow, "RIGHT", STAT_BLOCK.arrowGap, 0)
        block:Show()
    end
    HideStats(card, count + 1)
end

function offerFrame.FitCard(card, option, width, hasLock)
    local darkmoon = option.kind == "c"
    if not darkmoon then
        VanillaBonkUI.TalentArtCoords(card.art, width - 18, offerFrame.cardHeight - 18)
    end
    if option.stats and getn(option.stats) > 0 then
        card.descriptionText = ""
        card.damage:Hide()
        LayoutStats(card, option.stats, width, FitCardText(card, width, darkmoon, hasLock, 0))
    else
        HideStats(card, 1)
        card.descriptionText = option.description
        FitCardText(card, width, darkmoon, hasLock, LayoutDamageRow(card, option, hasLock))
    end
end

function offerFrame.GrowCardsToFit(width, hasLock)
    local grow = 0
    for index, card in ipairs(offerFrame.cards) do
        if VB.offer[index] then
            grow = max(grow, card.overflow or 0)
        end
    end
    grow = min(ceil(grow), offerFrame.MAX_GROWTH)
    if grow > 0 then
        offerFrame.cardHeight = CARD_HEIGHT + grow
        for index, card in ipairs(offerFrame.cards) do
            local option = VB.offer[index]
            if option then
                card:SetHeight(offerFrame.cardHeight)
                offerFrame.FitCard(card, option, width, hasLock)
            end
        end
    end
    offerFrame.cardDrop = grow / 2
    for index, card in ipairs(offerFrame.cards) do
        if VB.offer[index] and not card.pop then
            PlaceCard(card, 1, 1, 0)
        end
    end
    offerFrame.hint:SetPoint("CENTER", offerFrame, "CENTER", 0, -206 - grow)
    return grow
end

function offerFrame.Subtitle()
    if VB.offerSource == "ley" then
        return L["Choose a blessing"]
    end
    local cards, upgrades = 0, 0
    for _, option in ipairs(VB.offer) do
        if option.kind == "c" then
            cards = cards + 1
        else
            upgrades = upgrades + 1
        end
    end
    if cards > 0 and upgrades > 0 then
        return L["Choose a reward"]
    end
    return cards > 0 and L["Choose a Darkmoon Card"] or L["Choose an upgrade"]
end

local function ShowOffer(level)
    if offerFrame.anim and offerFrame.anim.mode == "close" then
        offerFrame.deferred = { level = level }
        return
    end
    local fresh = not offerFrame.open
    if not fresh and not offerFrame.anim then
        offerFrame.anim = { mode = "pop", t = 0 }
    end

    if VB.offerSource == "chest" then
        offerFrame.title:SetText(L["Chest"])
    elseif VB.offerSource == "ley" then
        offerFrame.title:SetText(L["Ley Line"])
    else
        offerFrame.title:SetText(L["Level "] .. level)
    end
    offerFrame.subtitle:SetText(offerFrame.Subtitle())

    local count = getn(VB.offer)
    local gap = count <= 3 and 20 or 12
    local width = count <= 3 and 220 or (count == 4 and 200 or 180)
    width = min(width, floor((UIParent:GetWidth() - 40 - (count - 1) * gap) / max(1, count)))
    local left = -((count * width + (count - 1) * gap) / 2) + width / 2
    local hasLock = VB.offerSource == "chest"
    offerFrame.cardHeight = CARD_HEIGHT

    for index, card in ipairs(offerFrame.cards) do
        local option = VB.offer[index]
        if option then
            card:SetWidth(width)
            card:SetHeight(CARD_HEIGHT)
            card.x = left + (index - 1) * (width + gap)
            local look = option.name .. option.icon .. option.newLevel .. (option.rarity or "")
            if fresh then
                card.pop = 0.08 + (index - 1) * OFFER_STAGGER
                PlaceCard(card, 0.8, 0, -24)
            elseif card.look ~= look or not card:IsShown() then
                card.pop = offerFrame.anim.t
                PlaceCard(card, 0.8, 0, -24)
            elseif not card.pop then
                PlaceCard(card, 1, 1, 0)
            end
            card.look = look
            card.divider:SetWidth((width - 48) / 2)
            card.dividerRight:SetWidth((width - 48) / 2)

            local darkmoon = option.kind == "c"
            if darkmoon then
                card.art:SetTexture(DARKMOON_CLOTH)
                card.art:SetTexCoord(0, 1, 0, 1)
                VanillaBonkUI.Shade(card.shade, 0.95, 0.4)
                card.slot:Hide()
                card.crest:Show()
                card.eye.icon:SetTexture(ICON_PATH .. option.icon)
                card.eye:Show()
                card.name:SetPoint("TOP", card, "TOP", 0, -158)
            else
                card.art:SetTexture("Interface\\TalentFrame\\" .. CardArt(option.icon) .. "-TopLeft")
                VanillaBonkUI.Shade(card.shade, 0.95, 0.1)
                card.slot:Show()
                card.crest:Hide()
                card.eye:Hide()
                card.name:SetPoint("TOP", card, "TOP", 0, -104)
            end
            card.slot.icon:SetTexture(ICON_PATH .. option.icon)
            card.name:SetText(option.name)

            local rarity = option.kind == "e" and 4 or option.rarity
            local color = rarity and RARITIES[rarity]
            if color then
                card.name:SetTextColor(color.r, color.g, color.b)
                card.lineColor = { color.r, color.g, color.b, 0.9 }
                card.glow:SetVertexColor(color.r, color.g, color.b)
                card.glow:Show()
            else
                card.name:SetTextColor(1, 1, 1)
                card.lineColor = { 0.85, 0.75, 0.5, 0.35 }
                card.glow:Hide()
            end
            local rarityName = option.rarity and RARITIES[option.rarity] and RarityText(option.rarity, RARITIES[option.rarity].name)
            if option.kind == "e" then
                card.level:SetText(RarityText(4, L["Legendary"]) .. L[" Evolution"])
            elseif option.kind == "ley" then
                card.level:SetText((rarityName and rarityName .. " " or "") .. L["Blessing"])
            elseif option.kind == "c" then
                card.level:SetText((rarityName and rarityName .. " " or "") .. L["Darkmoon Card"])
            elseif option.newLevel == 1 then
                card.level:SetText(option.kind == "p" and L["|cff20ff20New passive|r"] or L["|cff20ff20New spell|r"])
            elseif option.kind == "p" then
                card.level:SetText((rarityName and rarityName .. " " or "") .. L["Passive"])
            else
                card.level:SetText((rarityName and rarityName .. " " or "") .. L["Spell"])
            end
            if option.kind == "ley" or option.kind == "e" then
                card.count:SetText("")
            elseif option.kind == "c" and option.maxLevel > 1 then
                card.count:SetText(option.newLevel .. "/" .. option.maxLevel .. L[" copies"])
            elseif option.kind == "c" and option.newLevel > 1 then
                card.count:SetText(option.newLevel .. L[" copies"])
            elseif option.maxLevel > 1 then
                card.count:SetText(L["Rank "] .. option.newLevel .. "/" .. option.maxLevel)
            elseif option.newLevel > 1 then
                card.count:SetText(L["Rank "] .. option.newLevel)
            else
                card.count:SetText("")
            end
            card.line:SetBackdropBorderColor(card.lineColor[1], card.lineColor[2], card.lineColor[3], card.lineColor[4])
            card.borderColor = color and { color.r, color.g, color.b } or { 1, 1, 1 }
            card:SetBackdropBorderColor(card.borderColor[1], card.borderColor[2], card.borderColor[3])
            offerFrame.FitCard(card, option, width, hasLock)
            if hasLock then
                card.lock:SetText(option.locked and L["Locked"] or L["Lock"])
                card.lock:Show()
            else
                card.lock:Hide()
            end
            card:Show()
        else
            card.pop = nil
            card.look = nil
            card:Hide()
        end
    end

    local grow = offerFrame.GrowCardsToFit(width, hasLock)
    local hint = ""
    local keys = {}
    if (VB.skips or 0) > 0 then
        tinsert(keys, L["X to skip"])
    end
    local canBanish = (VB.banishes or 0) > 0 and VB.offerSource ~= "ley"
    if (VB.rerolls or 0) > 0 then
        tinsert(keys, L["R to reroll"])
    end
    if canBanish then
        tinsert(keys, L["|cffff8080B to banish|r"])
    end
    if getn(keys) > 0 then
        local text = keys[1]
        for index = 2, getn(keys) do
            text = text .. (index == getn(keys) and L[" or "] or ", ") .. keys[index]
        end
        hint = L["Press "] .. text .. "."
    end
    offerFrame.hintText = hint

    local buttons = {}
    if (VB.catchUp or 0) > 0 and VB.offerSource == "level" then
        offerFrame.autopick:SetText("Auto-pick (" .. VB.catchUp .. ")")
        tinsert(buttons, offerFrame.autopick)
    else
        offerFrame.autopick:Hide()
    end
    if (VB.rerolls or 0) > 0 then
        offerFrame.reroll:SetText(L["Reroll ("] .. VB.rerolls .. ")")
        tinsert(buttons, offerFrame.reroll)
    else
        offerFrame.reroll:Hide()
    end
    if canBanish then
        tinsert(buttons, offerFrame.banish)
    else
        offerFrame.banish:Hide()
    end
    if (VB.skips or 0) > 0 then
        offerFrame.skip:SetText(L["Skip ("] .. VB.skips .. ")")
        tinsert(buttons, offerFrame.skip)
    else
        offerFrame.skip:Hide()
    end
    local total = getn(buttons) * 120 + (getn(buttons) - 1) * 12
    for index, button in ipairs(buttons) do
        button:ClearAllPoints()
        button:SetPoint("CENTER", offerFrame, "CENTER", -total / 2 + 60 + (index - 1) * 132, -170 - grow)
        button:Show()
    end

    VB.picking = false
    VB.pickedIndex = nil
    SetBanishMode(false)
    if fresh then
        CollectGarbageIfDue()
        PlaySound("LEVELUP")
        offerFrame.open = true
        TakeChoiceKeys()
        offerFrame.anim = { mode = "open", t = 0, dimFrom = offerFrame.dimAlpha or 0 }
        offerFrame.chrome:SetAlpha(0)
        offerFrame.dim:SetVertexColor(0, 0, 0, OFFER_DIM * (offerFrame.dimAlpha or 0))
    end
    offerFrame:Show()
end

local function AnimateOffer(frame, elapsed)
    local anim = frame.anim
    anim.t = anim.t + elapsed
    local t = anim.t

    if anim.mode == "close" then
        local e = Progress(t, 0, OFFER_CLOSE)
        if not frame.deferred then
            frame.dimAlpha = anim.dimFrom * (1 - e)
            frame.dim:SetVertexColor(0, 0, 0, OFFER_DIM * frame.dimAlpha)
        end
        frame.chrome:SetAlpha(anim.chromeFrom * (1 - e))
        for _, card in ipairs(frame.cards) do
            if card:IsShown() then
                if card.index == VB.pickedIndex then
                    PlaceCard(card, 1 + 0.08 * EaseOut(e), card.closeFrom * (1 - e), 6 * e)
                else
                    PlaceCard(card, 1 - 0.06 * e, card.closeFrom * max(0, 1 - e * 1.5), -12 * e)
                end
            end
        end
        if e >= 1 then
            frame.anim = nil
            local deferred = frame.deferred
            frame.deferred = nil
            if deferred then
                ShowOffer(deferred.level)
            else
                frame:Hide()
            end
        end
        return
    end

    local busy = false
    if anim.mode == "open" then
        frame.dimAlpha = anim.dimFrom + (1 - anim.dimFrom) * EaseOut(Progress(t, 0, 0.2))
        frame.dim:SetVertexColor(0, 0, 0, OFFER_DIM * frame.dimAlpha)
        local header = EaseOut(Progress(t, 0.04, 0.26))
        frame.chrome:SetAlpha(header)
        frame.title:SetPoint("CENTER", frame, "CENTER", 0, 230 + 16 * (1 - header))
        busy = header < 1
    end
    for _, card in ipairs(frame.cards) do
        if card.pop then
            local p = Progress(t, card.pop, OFFER_POP)
            PlaceCard(card, 0.8 + 0.2 * EaseBack(p), min(1, p * 2), -24 * (1 - EaseOut(p)))
            if p >= 1 then
                card.pop = nil
                RebuildKeywordLinks(card)
            else
                busy = true
            end
        end
    end
    if not busy then
        frame.anim = nil
    end
end

offerFrame:SetScript("OnUpdate", function()
    if this.anim then
        AnimateOffer(this, arg1)
    end
end)

offerFrame:SetScript("OnShow", function()
    if this.open then
        TakeChoiceKeys()
    end
    for _, card in ipairs(this.cards) do
        if card:IsShown() and not card.pop then
            RebuildKeywordLinks(card)
        end
    end
end)

offerFrame:SetScript("OnHide", function()
    GiveBackChoiceKeys()
    if this:IsShown() then
        return
    end
    SetBanishMode(false)
    this.anim = nil
    this.open = false
    this.deferred = nil
    this.dimAlpha = 0
end)

local function CloseOffer()
    if not offerFrame:IsShown() or not offerFrame.open then
        return
    end
    GiveBackChoiceKeys()
    SetBanishMode(false)
    offerFrame:EnableMouse(false)
    offerFrame.open = false
    offerFrame.anim = { mode = "close", t = 0, dimFrom = offerFrame.dimAlpha or 1, chromeFrom = offerFrame.chrome:GetAlpha() }
    for _, card in ipairs(offerFrame.cards) do
        card.pop = nil
        card.closeFrom = card.alphaNow or 1
    end
end

local results = CreateFrame("Frame", "VanillaBonkResults", UIParent)
results:SetWidth(360)
results:SetHeight(210)
results:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
results:SetFrameStrata("DIALOG")
DialogBackdrop(results)
results:Hide()

results.title = results:CreateFontString(nil, "OVERLAY")
SetFont(results.title, 26)
results.title:SetPoint("TOP", results, "TOP", 0, -24)

results.body = results:CreateFontString(nil, "OVERLAY")
SetFont(results.body, 13, "")
results.body:SetPoint("TOP", results.title, "BOTTOM", 0, -14)
results.body:SetJustifyH("CENTER")

results.close = VanillaBonkUI.SliceButton(CreateFrame("Button", nil, results, "UIPanelButtonTemplate"))
results.close:SetWidth(100)
results.close:SetHeight(22)
results.close:SetPoint("BOTTOM", results, "BOTTOM", 0, 18)
results.close:SetText(L["Close"])
results.close:SetScript("OnClick", function()
    results:Hide()
end)

function VB.TakeOverGossip(pending)
    if VB.gossipFrame and VB.gossipFrame ~= pending.frame then
        VB.gossipFrame.gossipClosed = true
        VB.gossipFrame:Hide()
    end
    VB.gossipFrame = pending.frame
    pending.refresh()
    pending.frame:Show()
end

function VB.HideBlizzardGossipKeepingItOpen()
    local onHide = GossipFrame:GetScript("OnHide")
    GossipFrame:SetScript("OnHide", nil)
    HideUIPanel(GossipFrame)
    GossipFrame:SetScript("OnHide", onHide)
end

local function ReplaceNextGossip(frame, npc, refresh)
    local pending = { frame = frame, npc = npc, refresh = refresh }
    if GossipFrame:IsShown() and UnitName("npc") == npc then
        VB.gossipPending = nil
        VB.HideBlizzardGossipKeepingItOpen()
        VB.TakeOverGossip(pending)
        return
    end
    VB.gossipPending = pending
end

local function GossipWindowHidden(frame)
    if VB.gossipFrame == frame then
        VB.gossipFrame = nil
        if not frame.gossipClosed then
            CloseGossip()
        end
    end
    frame.gossipClosed = nil
end

local BlizzardGossipOnEvent = GossipFrame_OnEvent
function GossipFrame_OnEvent()
    if event == "GOSSIP_SHOW" then
        local pending = VB.gossipPending
        VB.gossipPending = nil
        if pending and UnitName("npc") == pending.npc then
            VB.TakeOverGossip(pending)
            return
        end
    elseif event == "GOSSIP_CLOSED" and VB.gossipFrame then
        VB.gossipFrame.gossipClosed = true
        VB.gossipFrame:Hide()
    end
    BlizzardGossipOnEvent()
end

local UI = VanillaBonkUI

local ARENA_WIDTH, ARENA_HEIGHT = 920, 600
local STARTER_SIZE, STARTER_STEP = 28, 34

local arena = UI.GoldWindow("VanillaBonkArena", ARENA_WIDTH, ARENA_HEIGHT)
arena:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
arena.title:SetText(L["Run Master"])

local content = CreateFrame("Frame", nil, arena)
content:SetAllPoints(arena)
content:SetFrameLevel(arena:GetFrameLevel() + 2)
arena.content = content

arena.hero = UI.Text(content, 12)
arena.hero:SetPoint("TOPRIGHT", arena, "TOPRIGHT", -36, -20)
arena.hero:SetJustifyH("RIGHT")

local LOADOUT_X, LOADOUT_TOP, LOADOUT_WIDTH = 22, 252, 214
local LOADOUT_GREY = { 0.51, 0.49, 0.44 }

arena.loadoutDivider = UI.Divider(content, LOADOUT_WIDTH)
arena.loadoutDivider:SetPoint("TOPLEFT", arena, "TOPLEFT", LOADOUT_X, -(LOADOUT_TOP - 14))
arena.loadoutLabel = UI.Text(content, 11)
arena.loadoutLabel:SetPoint("TOPLEFT", arena, "TOPLEFT", LOADOUT_X, -LOADOUT_TOP)
arena.loadoutLabel:SetTextColor(1, 0.82, 0)
arena.loadoutLabel:SetText(L["Your loadout"])

arena.challengesLabel = UI.Text(content, 10)
arena.challengesLabel:SetPoint("TOPLEFT", arena, "TOPLEFT", LOADOUT_X, -(LOADOUT_TOP + 84))
arena.challengesLabel:SetTextColor(LOADOUT_GREY[1], LOADOUT_GREY[2], LOADOUT_GREY[3])
arena.challengesLabel:SetText(L["Dark Fortunes"])
arena.challenges = UI.Text(content, 10)
arena.challenges:SetPoint("TOPRIGHT", arena, "TOPLEFT", LOADOUT_X + LOADOUT_WIDTH, -(LOADOUT_TOP + 84))
arena.challenges:SetWidth(120)
arena.challenges:SetJustifyH("RIGHT")

arena.perksLabel = UI.Text(content, 10)
arena.perksLabel:SetTextColor(LOADOUT_GREY[1], LOADOUT_GREY[2], LOADOUT_GREY[3])
arena.perksLabel:SetText(L["Perks"])
arena.perks = UI.Text(content, 10)
arena.perks:SetPoint("TOPRIGHT", arena.challenges, "BOTTOMRIGHT", 0, -5)
arena.perks:SetWidth(140)
arena.perks:SetJustifyH("RIGHT")
arena.perksLabel:SetPoint("LEFT", arena, "LEFT", LOADOUT_X, 0)
arena.perksLabel:SetPoint("TOP", arena.perks, "TOP", 0, 0)

VB.starters = {}
VB.pendingStarters = {}

local function ChosenStarter()
    for _, option in ipairs(VB.starters) do
        if option.chosen then
            return option
        end
    end
end

local function ShowStarterTooltip(owner, option)
    if not option then
        return
    end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if option.unlocked then
        GameTooltip:AddLine(option.name, 1, 0.82, 0)
    else
        GameTooltip:AddLine(option.name, 0.6, 0.6, 0.6)
    end
    GameTooltip:AddLine(option.description, 1, 1, 1, 1)
    if option.chosen then
        GameTooltip:AddLine(L["Your runs start with this spell."], 0.25, 1, 0.25, 1)
    elseif option.unlocked then
        GameTooltip:AddLine(L["Click to start your runs with it."], 1, 0.82, 0, 1)
    else
        GameTooltip:AddLine(option.hint, 1, 0.3, 0.3, 1)
    end
    GameTooltip:Show()
end

local function ChooseStarter(option)
    if not option or option.chosen or not option.unlocked or VB.inRun then
        return
    end
    PlaySound("igMainMenuOptionCheckBoxOn")
    Command("starter " .. option.id)
end

local function SetStarterIcon(texture, option)
    texture:SetTexture(ICON_PATH .. (option and option.icon ~= "" and option.icon or "INV_Misc_QuestionMark"))
    SetDesaturation(texture, option and not option.unlocked)
end

local starterBox = CreateFrame("Frame", nil, content)
starterBox:SetPoint("TOPLEFT", arena, "TOPLEFT", LOADOUT_X, -(LOADOUT_TOP + 26))
starterBox:SetWidth(LOADOUT_WIDTH)
starterBox:SetHeight(48)
starterBox.label = UI.Text(starterBox, 10)
starterBox.label:SetPoint("TOPLEFT", starterBox, "TOPLEFT", 0, 0)
starterBox.label:SetTextColor(LOADOUT_GREY[1], LOADOUT_GREY[2], LOADOUT_GREY[3])
starterBox.label:SetText(L["Starter spell"])
starterBox.name = UI.Text(starterBox, 11)
starterBox.name:SetJustifyH("LEFT")
starterBox.slots = {}

local function StarterSlot(index)
    local slot = starterBox.slots[index]
    if not slot then
        slot = CreateFrame("Button", nil, starterBox)
        slot:SetWidth(STARTER_SIZE)
        slot:SetHeight(STARTER_SIZE)
        slot:SetPoint("TOPLEFT", starterBox, "TOPLEFT", (index - 1) * STARTER_STEP, -16)
        slot:SetBackdrop({ edgeFile = UI.FLAT, edgeSize = 1 })
        slot.icon = slot:CreateTexture(nil, "ARTWORK")
        slot.icon:SetPoint("TOPLEFT", slot, "TOPLEFT", 1, -1)
        slot.icon:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -1, 1)
        UI.CropIcon(slot.icon)
        slot:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        slot:SetScript("OnClick", function() ChooseStarter(this.option) end)
        slot:SetScript("OnEnter", function() ShowStarterTooltip(this, this.option) end)
        slot:SetScript("OnLeave", function() GameTooltip:Hide() end)
        slot.glow = slot:CreateTexture(nil, "OVERLAY")
        slot.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        slot.glow:SetBlendMode("ADD")
        slot.glow:SetVertexColor(1, 0.82, 0)
        slot.glow:SetWidth(STARTER_SIZE * 1.8)
        slot.glow:SetHeight(STARTER_SIZE * 1.8)
        slot.glow:SetPoint("CENTER", slot, "CENTER", 0, 0)
        starterBox.slots[index] = slot
    end
    return slot
end

local function RefreshStarters()
    if getn(VB.starters) == 0 then
        starterBox:Hide()
        return
    end
    for _, slot in ipairs(starterBox.slots) do
        slot:Hide()
    end
    local chosen = ChosenStarter()
    local last
    for index, option in ipairs(VB.starters) do
        local slot = StarterSlot(index)
        slot.option = option
        SetStarterIcon(slot.icon, option)
        if option.chosen then
            slot.icon:SetVertexColor(1, 1, 1)
            slot:SetBackdropBorderColor(1, 0.82, 0, 1)
            slot.glow:Show()
        else
            slot.icon:SetVertexColor(0.6, 0.6, 0.6)
            slot:SetBackdropBorderColor(0, 0, 0, 1)
            slot.glow:Hide()
        end
        slot:Show()
        last = slot
    end
    starterBox.name:ClearAllPoints()
    starterBox.name:SetPoint("LEFT", last, "RIGHT", 10, 0)
    starterBox.name:SetText(chosen and chosen.name or "")
    starterBox:Show()
end

arena.button = UI.Button(content, 140, L["Start run"], function()
    local tier = arena.tier
    if not tier or not tier.unlocked or VB.inRun or not VanillaBonkRunMaster.CanStart(tier) then
        return
    end
    Command("start " .. VanillaBonkRunMaster.StartArgs(tier))
    arena:Hide()
end)
arena.button:SetWidth(ARENA_WIDTH - 22 - 560)
arena.button:SetHeight(38)
arena.button:SetPoint("TOPLEFT", arena, "TOPLEFT", 560, -(ARENA_HEIGHT - 62))
arena.button:SetText("")
arena.button.label = UI.Text(arena.button, 15)
arena.button.label:SetPoint("CENTER", arena.button, "CENTER", 0, 5)
arena.button.label:SetTextColor(1, 0.82, 0)
arena.button.caption = UI.Text(arena.button, 9)
arena.button.caption:SetPoint("CENTER", arena.button, "CENTER", 0, -9)
arena.button.caption:SetTextColor(0.94, 0.82, 0.63)

arena:SetScript("OnShow", function()
    PlaySound("igCharacterInfoOpen")
    arena.title:SetText(UnitExists("npc") and UnitName("npc") or L["Run Master"])
    local _, classToken = UnitClass("player")
    local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
    local name = UnitName("player") or ""
    if color then
        name = format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, name)
    end
    arena.hero:SetText(name .. "|cffffffff, " .. (UnitClass("player") or "") .. "|r")
end)

arena:SetScript("OnHide", function()
    PlaySound("igCharacterInfoClose")
    GossipWindowHidden(arena)
end)

local ShowArenaDetail

ShowArenaDetail = function(tier)
    arena.tier = tier
    RefreshStarters()
    VanillaBonkRunMaster.Show(tier)
    if not tier.unlocked then
        arena.button.label:SetText(L["Locked"])
        arena.button:Disable()
    elseif not VanillaBonkRunMaster.CanStart(tier) then
        arena.button.label:SetText(L["Start run"])
        arena.button:Disable()
    else
        arena.button.label:SetText(L["Start run"])
        arena.button:Enable()
    end
end

local RefreshArena

RefreshArena = function()
    local selected
    for _, tier in ipairs(VB.tiers) do
        if tier.id == VB.arenaSelected then
            selected = tier
        end
    end
    if not selected then
        for _, tier in ipairs(VB.tiers) do
            if tier.unlocked or not selected then
                selected = tier
            end
        end
        VB.arenaSelected = selected and selected.id
    end

    VanillaBonkRunMaster.SetTiers(VB.tiers, VB.arenaSelected, function(tier)
        VB.arenaSelected = tier.id
        RefreshArena()
    end)
    if selected then
        ShowArenaDetail(selected)
    end

    local info = VB.arenaInfo or {}
    if info.challenges and info.challenges ~= "" then
        local lines = ""
        for _, name in ipairs(UI.Split(info.challenges, ",")) do
            local trimmed = gsub(name, "^%s+", "")
            if trimmed ~= "" then
                lines = lines .. (lines ~= "" and ", " or "") .. trimmed
            end
        end
        arena.challenges:SetText("|cffffffff" .. lines .. "|r |cffffe873+" .. (info.goldBonus or 0) .. L["% gold|r"])
    else
        arena.challenges:SetText(L["|cff9d9d9dNone|r"])
    end
    if info.perks and info.perks ~= "" then
        arena.perks:SetText("|cffffffff" .. gsub(info.perks, ", ", "\n") .. "|r")
    else
        arena.perks:SetText(L["|cff9d9d9dNone yet|r"])
    end
end

StaticPopupDialogs["VANILLABONK_LEAVE_RUN"] = {
    text = L["End this run? It counts as a defeat. You keep the gold and Darkmoon Tickets you earned, but loot you haven't extracted is lost."],
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        Command("stop")
    end,
    timeout = 0,
    whileDead = 1,
}

SLASH_VANILLABONK1 = "/bonk"
SlashCmdList["VANILLABONK"] = function(message)
    if message == "stop" then
        Command("stop")
    elseif VB.inRun then
        StaticPopup_Show("VANILLABONK_LEAVE_RUN")
    elseif arena:IsShown() then
        arena:Hide()
    else
        VB.arenaRequested = true
        Command("hello " .. UI.Language())
    end
end

local SHOP_TITLES = { ["1"] = L["Upgrades"], ["2"] = L["Sayge's Fortunes"], ["3"] = L["Talents"] }
local SHOP_HINTS = {
    ["1"] = L["Upgrades count for all your heroes. Right-click to refund a rank."],
    ["2"] = L["Click a Dark Fortune to buy it or switch it on or off. Right-click to refund it."],
    ["3"] = L["Talent points come from Mastery levels. Right-click to refund one."],
}
local MASTERY_SHOP = "3"
local FORTUNE_SHOP = "2"
local SHOP_REFUNDS = {
    ["1"] = { label = L["Refund all"], text = L["Refunds every upgrade you bought. You get all your gold back."] },
    ["2"] = { label = L["Refund all"], text = L["Refunds every Dark Fortune you bought. You get all your Darkmoon Tickets back."] },
    ["3"] = { label = L["Reset points"], text = L["Refunds every talent point you spent."] },
}

local TREE_LAYOUTS = {
    wide = { width = 296, column = 63, left = 35 },
    narrow = { width = 251, column = 54, left = 26 },
}
local treeLayout = TREE_LAYOUTS.wide
local TREE_GAP = 12
local TREE_SPACING = 63
local TREE_OFFSET_Y = 34
local TREE_MIN_ROWS = 4
local TREE_TOP = 74
local SHOP_FOOTER = 40

local SHOP_NODE_SIZE = 36
local SHOP_NODE_HALF = SHOP_NODE_SIZE / 2

local shop = VanillaBonkUI.Window("VanillaBonkShop", 400, 400)
shop:SetPoint("CENTER", UIParent, "CENTER", 0, 40)

shop.gold = shop.headerRight

shop.hint = shop:CreateFontString(nil, "OVERLAY")
SetFont(shop.hint, 11, "")
shop.hint:SetShadowColor(0, 0, 0, 1)
shop.hint:SetShadowOffset(1, -1)
shop.hint:SetPoint("BOTTOMLEFT", shop, "BOTTOMLEFT", 26, 26)
shop.hint:SetTextColor(0.7, 0.7, 0.7)

shop.respec = VanillaBonkUI.SliceButton(CreateFrame("Button", nil, shop, "UIPanelButtonTemplate"))
shop.respec:SetWidth(110)
shop.respec:SetHeight(22)
shop.respec:SetPoint("BOTTOMRIGHT", shop, "BOTTOMRIGHT", -28, 22)
shop.respec:SetText(L["Reset points"])
shop.respec:SetScript("OnClick", function()
    if VB.shopBusy then
        return
    end
    VB.shopBusy = GetTime()
    Command("respec")
end)
shop.respec:SetScript("OnEnter", function()
    local refund = SHOP_REFUNDS[shop.kind] or SHOP_REFUNDS[MASTERY_SHOP]
    GameTooltip:SetOwner(this, "ANCHOR_TOP")
    GameTooltip:AddLine(refund.label, 1, 1, 1)
    GameTooltip:AddLine(refund.text, 1, 0.82, 0, 1)
    GameTooltip:Show()
end)
shop.respec:SetScript("OnLeave", function() GameTooltip:Hide() end)
shop.respec:Hide()

do
    local bar = CreateFrame("Frame", nil, shop)
    bar:SetWidth(1)
    bar:SetHeight(22)
    bar:SetPoint("BOTTOMRIGHT", shop.respec, "BOTTOMLEFT", -14, 0)
    bar:Hide()
    shop.presetBar = bar

    local function SendPreset()
        if VB.shopBusy or not shop.presetSlot then
            return
        end
        VB.shopBusy = GetTime()
        Command("preset " .. shop.presetSlot)
    end

    local function ShowTip(title, text)
        GameTooltip:SetOwner(this, "ANCHOR_TOP")
        GameTooltip:AddLine(title, 1, 1, 1)
        GameTooltip:AddLine(text, 1, 0.82, 0, 1)
        GameTooltip:Show()
    end

    local function AddButton(width, label, anchor)
        local button = VanillaBonkUI.SliceButton(CreateFrame("Button", nil, bar, "UIPanelButtonTemplate"))
        button:SetWidth(width)
        button:SetHeight(22)
        if anchor then
            button:SetPoint("RIGHT", anchor, "LEFT", -4, 0)
        else
            button:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
        end
        button:SetText(label)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
        return button
    end

    bar.activate = AddButton(84, "Set active")
    bar.activate:SetScript("OnClick", SendPreset)
    bar.activate:SetScript("OnEnter", function()
        ShowTip("Set active", "Switches to the talents saved in the selected preset. Your current talents stay in their preset.")
    end)

    bar.slots = {}
    local anchor = bar.activate
    for slot = 3, 1, -1 do
        local button = AddButton(26, tostring(slot), anchor)
        button.slot = slot
        button:SetScript("OnClick", function()
            PlaySound("igMainMenuOptionCheckBoxOn")
            shop.presetSlot = this.slot
            shop.Refresh()
        end)
        button:SetScript("OnEnter", function()
            local points = shop.presets and shop.presets.points[this.slot] or 0
            local text = points > 0 and (points .. (points == 1 and " talent point" or " talent points")) or "Empty"
            if shop.presets and shop.presets.active == this.slot then
                text = text .. "\n|cff20ff20Active. Talent changes save here.|r"
            end
            ShowTip("Preset " .. this.slot, text)
        end)
        bar.slots[slot] = button
        anchor = button
    end

    bar.label = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bar.label:SetPoint("RIGHT", bar.slots[1], "LEFT", -6, 0)
    bar.label:SetText("Presets")

    shop.PreviewSlot = function(data)
        local presets = not data.inspect and data.presets
        local slot = presets and (shop.presetSlot or presets.active)
        if not slot or slot == presets.active then
            return nil
        end
        return slot
    end

    shop.PreviewData = function(data, slot)
        local ranks = data.presets.ranks[slot]
        local view = {}
        for key, value in pairs(data) do
            view[key] = value
        end
        view.nodes = {}
        local spentByTree, spent = {}, 0
        for id, node in pairs(data.nodes) do
            local copy = {}
            for key, value in pairs(node) do
                copy[key] = value
            end
            copy.rank = ranks[id] or 0
            if copy.rank > 0 then
                spentByTree[copy.tree] = (spentByTree[copy.tree] or 0) + copy.rank
                spent = spent + copy.rank
            end
            view.nodes[id] = copy
        end
        view.trees = {}
        for index, tree in ipairs(data.trees) do
            local copy = {}
            for key, value in pairs(tree) do
                copy[key] = value
            end
            copy.spent = spentByTree[tree.id] or 0
            view.trees[index] = copy
        end
        view.balance = max(0, (data.earned or 0) - spent)
        return view
    end

    shop.RefreshPresets = function()
        local presets = shop.presets
        if not presets then
            bar:Hide()
            return
        end
        shop.presetSlot = shop.presetSlot or presets.active
        for slot, button in pairs(bar.slots) do
            if slot == shop.presetSlot then
                button:LockHighlight()
            else
                button:UnlockHighlight()
            end
            if slot == presets.active then
                button:SetTextColor(1, 0.82, 0)
                button:SetHighlightTextColor(1, 0.82, 0)
            elseif presets.points[slot] > 0 then
                button:SetTextColor(0.6, 0.49, 0)
                button:SetHighlightTextColor(1, 1, 1)
            else
                button:SetTextColor(0.5, 0.5, 0.5)
                button:SetHighlightTextColor(1, 1, 1)
            end
        end
        if presets.active ~= shop.presetSlot then
            bar.activate:Enable()
        else
            bar.activate:Disable()
        end
        bar:Show()
    end
end

shop.panels = {}

local function ShopBalance()
    if VB.shop.currency == "shards" or VB.shop.currency == "points" then
        return VB.shop.balance
    end
    return GetMoney()
end

local function FormatPoints(count)
    return "|cff80d0ff" .. count .. (count == 1 and L[" Talent point"] or L[" Talent points"]) .. "|r"
end

local function FormatShards(count)
    return "|cffc080ff" .. count .. (count == 1 and L[" Darkmoon Ticket"] or L[" Darkmoon Tickets"]) .. "|r"
end

local function FormatCost(amount)
    if VB.shop.currency == "shards" then
        return FormatShards(amount)
    elseif VB.shop.currency == "points" then
        return FormatPoints(amount)
    end
    return FormatGold(amount)
end

local function TreeSpent(treeId)
    local spent = 0
    for _, other in pairs(VB.shop.nodes) do
        if other.tree == treeId then
            spent = spent + other.rank
        end
    end
    return spent
end

local function TreeName(treeId)
    for _, tree in ipairs(VB.shop.trees) do
        if tree.id == treeId then
            return tree.name
        end
    end
    return ""
end

local function MissingRequirement(node)
    if node.locked then
        local text = L["Requires the quest \""] .. node.quest .. "\""
        if node.questDescription ~= "" then
            local what = gsub(node.questDescription, "%.$", "")
            what = strlower(strsub(what, 1, 1)) .. strsub(what, 2)
            text = text .. " (" .. what .. ")"
        end
        return text .. "."
    end
    local gate = VB.shop.gates and VB.shop.gates[node.row]
    if gate and gate.above < gate.need then
        return L["Requires "] .. gate.need .. L[" Darkmoon Tickets spent in the rows above"]
    end
    local perRow = VB.shop.pointsPerRow or 0
    if perRow > 0 and node.row > 1 and TreeSpent(node.tree) < (node.row - 1) * perRow then
        return L["Requires "] .. ((node.row - 1) * perRow) .. L[" points in "] .. TreeName(node.tree)
    end
    local required = VB.shop.nodes[node.requiredId]
    if not required or node.requiredRank < 1 or required.rank >= node.requiredRank then
        return nil
    end
    if required.maxRank <= 1 then
        return L["Requires "] .. required.name
    end
    return L["Requires "] .. node.requiredRank .. (node.requiredRank == 1 and L[" rank in "] or L[" ranks in "]) .. required.name
end

function VB.IsEndless(node)
    return node.maxRank >= VB.ENDLESS_RANKS
end
VB.ENDLESS_RANKS = 255

local function DescribeRanks(node, ranks)
    local perRank = tonumber(node.valuePerRank)
    if not perRank or perRank == 0 then
        return nil
    end
    local text, out, start, value = node.description, "", 1, nil
    while true do
        local first, last = strfind(text, "%d[%d%.]*", start)
        if not first then
            break
        end
        if strsub(text, last, last) == "." then
            last = last - 1
        end
        local number = strsub(text, first, last)
        out = out .. strsub(text, start, first - 1)
        if tonumber(number) == perRank then
            out = out .. format("%g", perRank * ranks)
            if not value then
                local sign, unit = strsub(text, first - 1, first - 1), strsub(text, last + 1, last + 1)
                value = ((sign == "+" or sign == "-") and sign or "") .. format("%g", perRank * ranks) .. (unit == "%" and unit or "")
            end
        else
            out = out .. number
        end
        start = last + 1
    end
    if not value then
        return nil
    end
    return out .. strsub(text, start), value
end

local function RefundBlocker(node)
    local perRow = VB.shop.pointsPerRow or 0
    for _, other in pairs(VB.shop.nodes) do
        if other ~= node and other.rank > 0 then
            if other.requiredId == node.id and node.rank - 1 < other.requiredRank then
                return L["Refund "] .. other.name .. L[" first. It depends on this one."]
            end
            local gate = VB.shop.gates and VB.shop.gates[other.row]
            if gate and other.row > node.row and gate.above - node.refund < gate.need then
                return L["Refund "] .. other.name .. L[" first. It needs the tickets you spent here."]
            end
            if perRow > 0 and other.tree == node.tree and other.row > node.row then
                local above = 0
                for _, placed in pairs(VB.shop.nodes) do
                    if placed.tree == other.tree and placed.row < other.row then
                        above = above + placed.rank
                    end
                end
                if above - 1 < (other.row - 1) * perRow then
                    return L["Refund "] .. other.name .. L[" first. It needs the points you spent in "] .. TreeName(node.tree) .. "."
                end
            end
        end
    end
    return nil
end

local function ShowNodeTooltip(button)
    local node = button.node
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:AddLine(node.name, 1, 1, 1)
    if node.toggle then
        GameTooltip:AddLine(L["Dark Fortune"], 1, 1, 1)
    else
        GameTooltip:AddLine(VB.IsEndless(node) and (L["Rank "] .. node.rank) or (L["Rank "] .. node.rank .. "/" .. node.maxRank), 1, 1, 1)
    end

    local missing = MissingRequirement(node)
    if missing and node.rank < node.maxRank then
        GameTooltip:AddLine(missing, 1, 0.1, 0.1, 1)
    end
    local nextRank, nextValue = nil, nil
    if node.maxRank > 1 then
        nextRank, nextValue = DescribeRanks(node, node.rank + 1)
    end
    if nextRank then
        if node.rank > 0 then
            GameTooltip:AddLine(DescribeRanks(node, node.rank), 1, 0.82, 0, 1)
            if VB.IsEndless(node) then
                GameTooltip:AddLine(L["Next rank: |cff20ff20"] .. nextRank .. "|r", 1, 1, 1, 1)
            elseif node.rank < node.maxRank then
                GameTooltip:AddLine(L["Next rank: |cff20ff20"] .. nextValue .. "|r", 1, 1, 1)
            end
        else
            GameTooltip:AddLine(nextRank, 1, 0.82, 0, 1)
        end
    elseif node.maxRank > 1 then
        GameTooltip:AddLine(L["Each rank: "] .. node.description, 1, 0.82, 0, 1)
    else
        GameTooltip:AddLine(node.description, 1, 0.82, 0, 1)
    end
    if node.description and string.find(node.description, "Valor") then
        GameTooltip:AddLine(L["Valor is spent during a run to open chests and buy from shops. Resets every run, it's not kept."], 0.6, 0.6, 0.6, 1)
    end

    GameTooltip:AddLine(" ")
    if node.rank < node.maxRank then
        GameTooltip:AddLine(L["Cost: "] .. FormatCost(node.cost), 1, 1, 1)
        if ShopBalance() < node.cost then
            GameTooltip:AddLine(L["You have "] .. FormatCost(ShopBalance()), 1, 0.1, 0.1)
        elseif not missing then
            GameTooltip:AddLine(L["Click to learn"], 0.1, 1, 0.1)
        end
    elseif node.toggle then
        if node.enabled then
            GameTooltip:AddLine(L["Switched on"], 0.1, 1, 0.1)
            GameTooltip:AddLine(L["Click to switch off"], 0.7, 0.7, 0.7)
        else
            GameTooltip:AddLine(L["Switched off"], 0.6, 0.6, 0.6)
            GameTooltip:AddLine(L["Click to switch on"], 0.7, 0.7, 0.7)
        end
    else
        GameTooltip:AddLine(L["Fully learned"], 1, 0.82, 0)
    end
    if node.rank > 0 then
        local blocker = RefundBlocker(node)
        if blocker then
            GameTooltip:AddLine(blocker, 0.6, 0.6, 0.6, 1)
        elseif node.refund > 0 then
            GameTooltip:AddLine(L["Right-click to refund "] .. FormatCost(node.refund), 0.7, 0.7, 0.7)
        else
            GameTooltip:AddLine(L["Right-click to refund"], 0.7, 0.7, 0.7)
        end
    end
    GameTooltip:Show()
end

local function ShopNode_OnClick()
    local node = this.node
    if VB.shopBusy then
        return
    end

    if arg1 == "RightButton" then
        if node.rank < 1 then
            return
        end
        local blocker = RefundBlocker(node)
        if blocker then
            Notice(blocker)
            return
        end
        VB.shopBusy = GetTime()
        Command("unlearn " .. node.id)
        return
    end

    local command
    if node.toggle and node.rank > 0 then
        command = "toggle " .. node.id
    elseif node.rank < node.maxRank then
        local missing = MissingRequirement(node)
        if missing then
            Notice(missing)
            return
        end
        if ShopBalance() < node.cost then
            Notice(L["You need "] .. FormatCost(node.cost))
            return
        end
        command = "learn " .. node.id
    else
        return
    end

    VB.shopBusy = GetTime()
    Command(command)
end

local function CreateNodeButton(panel, index)
    local name = panel.name .. "Node" .. index
    local button = CreateFrame("Button", name, panel)
    button:SetWidth(SHOP_NODE_SIZE)
    button:SetHeight(SHOP_NODE_SIZE)
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    VanillaBonkTalents.StyleButton(button)

    button:SetScript("OnEnter", function() ShowNodeTooltip(this) end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", ShopNode_OnClick)

    panel.buttons[index] = button
    return button
end

local function SetNode(button, node)
    button.node = node
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", button:GetParent(), "TOPLEFT",
        treeLayout.left + (node.column - 1) * treeLayout.column, -(TREE_OFFSET_Y + (node.row - 1) * TREE_SPACING))
    local missing = MissingRequirement(node)
    local which, text, colour = "locked", VB.IsEndless(node) and tostring(node.rank) or (node.rank .. "/" .. node.maxRank), nil
    if node.toggle and node.rank > 0 then
        which = node.enabled and "on" or "off"
        text = node.enabled and L["On"] or L["Off"]
        colour = node.enabled and { 0.1, 1, 0.1 } or { 0.8, 0.8, 0.8 }
    elseif not missing and node.rank >= node.maxRank then
        which = "max"
    elseif not missing and ShopBalance() >= node.cost then
        which = node.rank > 0 and "part" or "open"
    elseif not missing and node.rank > 0 then
        which = "max"
    end
    VanillaBonkTalents.StyleNode(button, node.toggle, which, node.icon ~= "" and node.icon or "INV_Misc_QuestionMark", text, colour)
    button:Show()

    if GameTooltip:IsOwned(button) then
        ShowNodeTooltip(button)
    end
end

local function CreateTreePanel(index)
    local panel = CreateFrame("Frame", "VanillaBonkShopTree" .. index, shop)
    panel.name = "VanillaBonkShopTree" .. index
    panel.buttons = {}
    panel.branches = {}
    panel.arrows = {}

    panel.art = {}
    for _, piece in ipairs({ "TopLeft", "TopRight", "BottomLeft", "BottomRight" }) do
        panel.art[piece] = panel:CreateTexture(nil, "BACKGROUND")
    end

    panel.edge = CreateFrame("Frame", nil, panel)
    panel.edge:SetAllPoints(panel)
    panel.edge:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    panel.edge:SetBackdropBorderColor(0, 0, 0, 1)

    panel.band = panel:CreateTexture(nil, "BORDER")
    panel.band:SetPoint("TOPLEFT", panel, "TOPLEFT", 1, -1)
    panel.band:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -1, -1)
    panel.band:SetHeight(26)
    VanillaBonkUI.Shade(panel.band, 0, 0.75)

    panel.header = panel:CreateFontString(nil, "OVERLAY")
    SetFont(panel.header, 13, "")
    panel.header:SetShadowColor(0, 0, 0, 1)
    panel.header:SetShadowOffset(1, -1)
    panel.header:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -7)
    panel.header:SetTextColor(1, 0.82, 0)

    panel.spent = panel:CreateFontString(nil, "OVERLAY")
    SetFont(panel.spent, 11, "")
    panel.spent:SetShadowColor(0, 0, 0, 1)
    panel.spent:SetShadowOffset(1, -1)
    panel.spent:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -8)

    shop.panels[index] = panel
    return panel
end

local function LayoutArt(panel, background, height)
    local width = treeLayout.width
    local scale = width / 256
    local topHeight, bottomHeight = 256 * scale, 128 * scale
    local base = "Interface\\TalentFrame\\" .. background .. "-"
    local art = panel.art

    local top = min(height, topHeight)
    local bottom = min(height - top, bottomHeight)
    art.TopLeft:SetTexture(base .. "TopLeft")
    art.TopLeft:SetWidth(width)
    art.TopLeft:SetHeight(top)
    art.TopLeft:SetTexCoord(0, 1, 0, top / topHeight)
    art.TopLeft:ClearAllPoints()
    art.TopLeft:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    art.TopLeft:Show()
    if bottom > 0 then
        art.BottomLeft:SetTexture(base .. "BottomLeft")
        art.BottomLeft:SetWidth(width)
        art.BottomLeft:SetHeight(bottom)
        art.BottomLeft:SetTexCoord(0, 1, 0, bottom / bottomHeight)
        art.BottomLeft:ClearAllPoints()
        art.BottomLeft:SetPoint("TOPLEFT", art.TopLeft, "BOTTOMLEFT", 0, 0)
        art.BottomLeft:Show()
    else
        art.BottomLeft:Hide()
    end
    art.TopRight:Hide()
    art.BottomRight:Hide()
end

local function DrawTree(panel, tree)
    local nodes = VB.shop.nodes
    for _, list in ipairs({ panel.buttons, panel.branches }) do
        for _, region in ipairs(list) do
            region:Hide()
        end
    end

    local count, spent = 0, 0
    for _, node in pairs(nodes) do
        if node.tree == tree.id then
            count = count + 1
            SetNode(panel.buttons[count] or CreateNodeButton(panel, count), node)
            spent = spent + node.rank
        end
    end
    panel.header:SetText(tree.name)
    if tree.tickets then
        panel.spent:SetText(tree.tickets .. (tree.tickets == 1 and L[" ticket spent"] or L[" tickets spent"]))
    else
        panel.spent:SetText(spent .. (spent == 1 and L[" point spent"] or L[" points spent"]))
    end

    local height = panel:GetHeight()
    local function Centre(node)
        return treeLayout.left + (node.column - 1) * treeLayout.column + SHOP_NODE_HALF,
            height - TREE_OFFSET_Y - (node.row - 1) * TREE_SPACING - SHOP_NODE_HALF
    end
    local lines, treeRows = 0, 0
    for _, node in pairs(nodes) do
        if node.tree == tree.id then
            treeRows = max(treeRows, node.row)
        end
        local required = nodes[node.requiredId]
        if node.tree == tree.id and required and required.tree == tree.id then
            local sx, sy = Centre(required)
            local ex, ey = Centre(node)
            local kind = MissingRequirement(node) and "dark" or node.rank > 0 and "lit" or "open"
            lines = lines + 1
            VanillaBonkTalents.ShopLine(panel, panel.branches, lines, sx, sy, ex, ey, kind)
        end
    end

    VanillaBonkTalents.HideShopGates(panel.arrows)
    local gates = VB.shop.gates
    if gates then
        local count = 0
        for row = 2, min(table.getn(gates), treeRows) do
            if gates[row].need > gates[row - 1].need then
                count = count + 1
                local lit = gates[row].above >= gates[row].need
                local text = lit and (L["Unlocked at "] .. gates[row].need .. L[" tickets spent"]) or (gates[row].need .. L[" tickets spent to unlock"])
                VanillaBonkTalents.ShopGate(panel, panel.arrows, count, -(TREE_OFFSET_Y + (row - 1.5) * TREE_SPACING + SHOP_NODE_HALF), text, lit)
            end
        end
    end
end

local RefreshShop

local function UpdateShopTabs(data)
    shop.tab = nil
    UI.Tabs(shop, {}, nil)
end

RefreshShop = function()
    local data = VB.shop
    local previewSlot = shop.PreviewSlot(data)
    if previewSlot then
        data = shop.PreviewData(data, previewSlot)
    end
    if VanillaBonkTalents then
        VanillaBonkTalents.muted = previewSlot ~= nil
    end
    UpdateShopTabs(data)
    TREE_SPACING = data.gates and 84 or 63
    local rows = TREE_MIN_ROWS
    for _, node in pairs(data.nodes) do
        rows = max(rows, node.row)
    end
    local height = TREE_OFFSET_Y * 2 + (rows - 1) * TREE_SPACING + 37

    for _, panel in ipairs(shop.panels) do
        panel:Hide()
    end
    if VanillaBonkTalents and VanillaBonkTalents.Wants(data) then
        local freeWidth, freeHeight = VanillaBonkTalents.Show(shop, data, TREE_TOP)
        height = freeHeight
        VanillaBonkUI.SetWindowSize(shop, freeWidth, TREE_TOP + height + SHOP_FOOTER + 9)
    else
        if VanillaBonkTalents then
            VanillaBonkTalents.Hide()
        end
        local count = table.getn(data.trees)
        treeLayout = count >= 4 and TREE_LAYOUTS.narrow or TREE_LAYOUTS.wide
        local width = treeLayout.width
        for index, tree in ipairs(data.trees) do
            local panel = shop.panels[index] or CreateTreePanel(index)
            panel:ClearAllPoints()
            panel:SetPoint("TOPLEFT", shop, "TOPLEFT", 20 + (index - 1) * (width + TREE_GAP), -TREE_TOP)
            panel:SetWidth(width)
            panel:SetHeight(height)
            LayoutArt(panel, tree.background, height)
            DrawTree(panel, tree)
            panel:Show()
        end

        count = max(count, 1)
        VanillaBonkUI.SetWindowSize(shop, max(360, 30 + count * width + (count - 1) * TREE_GAP), TREE_TOP + height + SHOP_FOOTER + 9)
    end
    shop.title:SetText((data.className and (data.className .. " ") or "") .. (SHOP_TITLES[data.kind] or ""))
    shop.header:SetText(data.npc)
    shop.hint:SetText(data.inspect and "Talents can only be changed at the Inn." or
        previewSlot and ("Preset " .. previewSlot .. ". Click Set active to use these talents.") or SHOP_HINTS[data.kind] or "")
    if VanillaBonkTalents then
        VanillaBonkTalents.readOnly = data.inspect or previewSlot ~= nil
    end
    if data.currency == "shards" then
        shop.gold:SetText(FormatShards(data.balance))
    elseif data.currency == "points" then
        local level = L["|cffffffffMastery "] .. data.level .. "/" .. data.maxLevel .. "|r"
        if data.xpNext > 0 then
            level = level .. " |cff9d9d9d(" .. data.xp .. "/" .. data.xpNext .. ")|r"
        end
        shop.gold:SetText(level .. "   " .. FormatPoints(data.balance))
    else
        shop.gold:SetText(FormatGold(GetMoney()))
    end
    shop.kind = data.kind
    local refund = not data.inspect and not previewSlot and SHOP_REFUNDS[data.kind]
    if refund then
        shop.respec:SetText(refund.label)
        shop.respec:Show()
    else
        shop.respec:Hide()
    end
    shop.presets = not data.inspect and data.presets or nil
    shop.RefreshPresets()
end

shop.Refresh = RefreshShop

shop:SetScript("OnShow", function()
    PlaySound("TalentScreenOpen")
    VanillaBonkUI.SetPortrait(shop)
end)

shop:SetScript("OnHide", function()
    PlaySound("TalentScreenClose")
    VB.shopBusy = nil
    shop.presetSlot = nil
    GossipWindowHidden(shop)
end)

shop:SetScript("OnUpdate", function()
    if VB.shopBusy and GetTime() - VB.shopBusy > 3 then
        VB.shopBusy = nil
    end
end)

local handlers = {}

handlers["hello"] = function()
    VB.connected = true
end

handlers["kwd"] = function(f)
    local id = tonumber(f[2])
    if not id then
        return
    end
    VB.keywords[id] = { name = f[3] or "", icon = f[4] or "", description = f[5] or "" }
    VB.keywordTerms = nil
end

handlers["arena"] = function(f)
    VB.arenaInfo = { goldBonus = tonumber(f[4]) or 0, challenges = f[5] or "", perks = f[6] or "" }
    VB.arenaNpc = f[2] == "1" and f[3] or nil
end

handlers["tier"] = function(f)
    local maps = {}
    for _, item in ipairs(Split(f[10] or "", ",")) do
        if item ~= "" then
            local parts = Split(item, ":")
            tinsert(maps, { icon = parts[1] or "", name = parts[2] or parts[1], type = parts[3], reward = tonumber(parts[4] or ""), key = parts[5] or "" })
        end
    end
    local dungeons = {}
    for _, item in ipairs(Split(f[13] or "", ",")) do
        local parts = Split(item, ":")
        if parts[1] and parts[1] ~= "" then
            tinsert(dungeons, { key = parts[1], icon = parts[2] or "", name = parts[3] or parts[1], open = parts[4] == "1" })
        end
    end
    tinsert(VB.pendingTiers, { id = f[2], key = f[3], name = f[4], unlocked = f[5] == "1", hint = f[6] or "", best = tonumber(f[7]) or 0,
        description = f[8] or "", art = f[9] or "", maps = maps, stages = tonumber(f[11] or ""), endless = f[12] == "1",
        dungeons = dungeons, details = f[14] or "" })
end

handlers["starter"] = function(f)
    tinsert(VB.pendingStarters, { id = f[2], icon = f[3] or "", name = f[4] or "", unlocked = f[5] == "1", chosen = f[6] == "1",
        hint = f[7] or "", description = f[8] or "" })
end

handlers["starterend"] = function()
    VB.starters = VB.pendingStarters
    VB.pendingStarters = {}
    if arena:IsShown() then
        RefreshStarters()
    end
end

handlers["tierend"] = function()
    VB.tiers = VB.pendingTiers
    VB.pendingTiers = {}
    if VB.arenaNpc then
        ReplaceNextGossip(arena, VB.arenaNpc, RefreshArena)
        VB.arenaNpc = nil
    elseif arena:IsShown() then
        RefreshArena()
    elseif VB.arenaRequested then
        VB.arenaRequested = nil
        RefreshArena()
        arena:Show()
    end
end

local combatLogQuiet = false

local function IsCombatLogGroup(group)
    return strsub(group, 1, 7) == "COMBAT_" or strsub(group, 1, 6) == "SPELL_"
end

local function SetCombatLogQuiet(quiet)
    if quiet == combatLogQuiet or not ChatTypeGroup then
        return
    end
    combatLogQuiet = quiet
    for index = 1, NUM_CHAT_WINDOWS do
        local chat = getglobal("ChatFrame" .. index)
        if chat then
            if quiet then
                for group, chatEvents in pairs(ChatTypeGroup) do
                    if IsCombatLogGroup(group) then
                        for _, chatEvent in ipairs(chatEvents) do
                            chat:UnregisterEvent(chatEvent)
                        end
                    end
                end
            elseif chat.messageTypeList then
                for _, group in ipairs(chat.messageTypeList) do
                    if IsCombatLogGroup(group) and ChatTypeGroup[group] then
                        for _, chatEvent in ipairs(ChatTypeGroup[group]) do
                            chat:RegisterEvent(chatEvent)
                        end
                    end
                end
            end
        end
    end
end

handlers["start"] = function(f)
    VB.inRun = true
    SetCombatLogQuiet(true)
    VB.duration = tonumber(f[4]) or 0
    results:Hide()
    arena:Hide()
    shop:Hide()
end

handlers["state"] = function()
    VB.inRun = true
    SetCombatLogQuiet(true)
end

handlers["offer"] = function(f)
    VB.offer = {}
    VB.offerLevel = f[2]
    VB.offerSource = f[4]
    VB.rerolls = tonumber(f[5]) or 0
    VB.banishes = tonumber(f[6]) or 0
    VB.skips = tonumber(f[7]) or 0
    VB.catchUp = tonumber(f[8] or "") or 0
end

handlers["opt"] = function(f)
    local description = gsub(f[8] or "", "|n", "\n")
    if f[3] == "c" then
        description = gsub(description, "%s*You hold %d+%.?$", "")
    end
    VB.offer[tonumber(f[2])] = {
        kind = f[3],
        newLevel = tonumber(f[4]) or 1,
        maxLevel = tonumber(f[5]) or 0,
        name = f[6],
        icon = f[7],
        description = description,
        rarity = tonumber(f[9] or ""),
        locked = f[10] == "1",
        damageBefore = f[11] or "",
        damageAfter = f[12] or "",
        damageLabel = f[13] or "",
        stats = {},
    }
end

handlers["ostat"] = function(f)
    local option = VB.offer[tonumber(f[2])]
    if option then
        tinsert(option.stats, { label = f[3] or "", before = f[4] or "", after = f[5] or "" })
    end
end

handlers["offerend"] = function()
    ShowOffer(VB.offerLevel)
end

handlers["picked"] = function()
    VB.offer = {}
    CloseOffer()
end

handlers["leyoffer"] = function()
    VB.offer = {}
    VB.offerLevel = nil
    VB.offerSource = "ley"
    VB.rerolls, VB.banishes, VB.skips = 0, 0, 0
end

handlers["leyopt"] = function(f)
    local index = tonumber(f[2] or "")
    if not index then
        return
    end
    local card = f[7] == "c"
    VB.offer[index] = {
        kind = card and "c" or "ley",
        newLevel = card and tonumber(f[8] or "") or 1,
        maxLevel = card and tonumber(f[9] or "") or 0,
        name = f[3] or "",
        icon = f[4] or "",
        description = card and gsub(f[5] or "", "%s*You hold %d+%.?$", "") or (f[5] or ""),
        rarity = tonumber(f[6] or ""),
    }
end

handlers["leyofferend"] = function()
    ShowOffer(nil)
end

handlers["leyofferclose"] = function()
    VB.offer = {}
    CloseOffer()
end

handlers["end"] = function(f)
    VB.inRun = false
    if VanillaBonkUI.InspectShown() then
        shop:Hide()
    end
    SetCombatLogQuiet(false)
    VB.offer = {}
    offerFrame:Hide()
    if f[9] == "1" then
        results.title:SetText(L["|cffffd100Victory!|r"])
        PlaySound("QUESTCOMPLETED")
    elseif f[2] == "1" then
        results.title:SetText(L["|cff20ff20Run complete!|r"])
        PlaySound("QUESTCOMPLETED")
    else
        results.title:SetText(L["|cffff3030Defeated|r"])
    end
    results.body:SetText(L["Reached floor "] .. (f[7] or "1") .. L[" in "] .. FormatTime(f[3]) .. "\n" ..
        L["Kills: "] .. f[4] .. L["    Level: "] .. f[6] .. "\n" ..
        L["Gold earned: "] .. FormatGold(f[5]) .. "\n" ..
        L["Darkmoon Tickets: |cffc080ff"] .. (f[8] or "0") .. "|r\n\n" ..
        L["|cffaaaaaaReturning to the Inn...|r"])
    results:Show()
end

handlers["msg"] = function(f)
    Notice(f[2])
end

handlers["find"] = function(f)
    UIErrorsFrame:AddMessage(f[2], 0.3, 0.8, 1.0, 1.0, 10)
    PlaySound("igQuestListComplete")
end

handlers["shard"] = function()
    PlaySound("LOOTWINDOWCOINSOUND")
end

handlers["valor"] = function()
    PlaySound("LOOTWINDOWCOINSOUND")
end

handlers["shop"] = function(f)
    VB.shopIncoming = { kind = f[2], open = f[3] == "1", npc = f[4] or "", currency = f[5] or "gold", balance = tonumber(f[6]) or 0,
        trees = {}, nodes = {} }
    if f[2] == MASTERY_SHOP then
        local data = VB.shopIncoming
        data.level = tonumber(f[7]) or 0
        data.xp = tonumber(f[8]) or 0
        data.xpNext = tonumber(f[9]) or 0
        data.maxLevel = tonumber(f[10]) or 0
        data.earned = tonumber(f[11]) or 0
        data.fromQuests = tonumber(f[12]) or 0
        data.className = f[13]
        data.pointsPerRow = tonumber(f[14]) or 0
        data.inspect = f[15] == "1"
    elseif f[2] == FORTUNE_SHOP and f[7] and f[7] ~= "" then
        local data = VB.shopIncoming
        data.gates = {}
        for need, above in string.gfind(f[7], "(%d+):(%d+)") do
            tinsert(data.gates, { need = tonumber(need), above = tonumber(above) })
        end
    end
end

handlers["tree"] = function(f)
    if VB.shopIncoming then
        local tree = { id = f[2], name = f[3] or "", background = f[4] or "MageFire" }
        if VB.shopIncoming.kind == FORTUNE_SHOP then
            tree.tickets = tonumber(f[5])
        end
        if VB.shopIncoming.kind == MASTERY_SHOP and VanillaBonkTalents then
            VanillaBonkTalents.ParseTree(tree, f)
        end
        tinsert(VB.shopIncoming.trees, tree)
    end
end

handlers["presets"] = function(f)
    if VB.shopIncoming then
        VB.shopIncoming.presets = { active = tonumber(f[2]) or 0, points = { tonumber(f[3]) or 0, tonumber(f[4]) or 0, tonumber(f[5]) or 0 },
            ranks = { {}, {}, {} } }
    end
end

handlers["presetranks"] = function(f)
    local presets = VB.shopIncoming and VB.shopIncoming.presets
    local ranks = presets and presets.ranks[tonumber(f[2])]
    if not ranks then
        return
    end
    for id, rank in string.gfind(f[3] or "", "(%d+):(%d+)") do
        ranks[id] = tonumber(rank)
    end
end

handlers["node"] = function(f)
    if not VB.shopIncoming then
        return
    end
    VB.shopIncoming.nodes[f[3]] = {
        tree = f[2],
        id = f[3],
        row = tonumber(f[4]) or 1,
        column = tonumber(f[5]) or 1,
        icon = f[6] or "",
        rank = tonumber(f[7]) or 0,
        maxRank = tonumber(f[8]) or 1,
        cost = tonumber(f[9]) or 0,
        requiredId = f[10],
        requiredRank = tonumber(f[11]) or 0,
        toggle = f[12] == "1",
        enabled = f[13] == "1",
        name = f[14] or "",
        description = f[15] or "",
        locked = f[16] == "1",
        quest = f[17] or "",
        valuePerRank = f[18] or "",
        refund = tonumber(f[19]) or 0,
        questDescription = f[20] or "",
    }
    if VB.shopIncoming.kind == MASTERY_SHOP and VanillaBonkTalents then
        VanillaBonkTalents.ParseNode(VB.shopIncoming.nodes[f[3]], f)
    end
end

local function ShopChanges(before, after)
    local changes = {}
    for id, node in pairs(after.nodes) do
        local old = before.nodes[id]
        if old and node.rank > old.rank then
            changes.learned = true
        elseif old and node.rank < old.rank then
            changes.refunded = true
        elseif old and node.enabled ~= old.enabled then
            changes.switched = node.enabled and "on" or "off"
        end
    end
    return changes
end

local function PlayShopChangeSound(before, after)
    local changes = ShopChanges(before, after)
    if changes.learned then
        PlaySoundFile("Sound\\Interface\\uSpellIconDrop.wav")
    elseif changes.refunded and after.kind == MASTERY_SHOP then
        PlaySound("igMainMenuOptionCheckBoxOff")
    elseif changes.refunded then
        PlaySound("LOOTWINDOWCOINSOUND")
    elseif changes.switched == "on" then
        PlaySound("igMainMenuOptionCheckBoxOn")
    elseif changes.switched == "off" then
        PlaySound("igMainMenuOptionCheckBoxOff")
    end
end

local function PlayPurchaseSound()
    local money = GetMoney()
    local spent = VB.lastMoney and money < VB.lastMoney
    VB.lastMoney = money
    if not spent or VB.inRun then
        return
    end
    if shop:IsShown() then
        return
    end
    PlaySound("LOOTWINDOWCOINSOUND")
end

handlers["shopend"] = function()
    local incoming = VB.shopIncoming
    VB.shopIncoming = nil
    if not incoming then
        return
    end

    VB.shopBusy = nil
    if incoming.inspect then
        shop.tab = nil
        VB.shop = incoming
        RefreshShop()
        shop:Show()
    elseif incoming.open then
        shop.tab = nil
        VB.shop = incoming
        ReplaceNextGossip(shop, incoming.npc, RefreshShop)
    elseif shop:IsShown() and VB.shop and VB.shop.kind == incoming.kind then
        local before = VB.shop
        VB.shop = incoming
        RefreshShop()
        PlayShopChangeSound(before, incoming)
    end
end

handlers["shopclose"] = function()
    VB.shopBusy = nil
    shop:Hide()
end

local STATS = {
    [0]  = { name = L["Power"], pct = true, text = L["Increases all damage you and your minions deal by %s."] },
    [1]  = { name = L["Haste"], pct = true, curve = 75, gearCap = 20, text = L["Increases the speed of your attacks, damage over time and minions by %s."] },
    [2]  = { name = L["Count"], cap = 5, text = L["Your spells fire %s extra bolts, shots or swings."] },
    [3]  = { name = L["Movement speed"], short = L["Speed"], pct = true, cap = 50, text = L["Increases movement speed by %s."] },
    [4]  = { name = L["Max health"], pct = true, text = L["Increases maximum health by %s."] },
    [5]  = { name = L["Regen"], pct = true, text = L["Restores %s of maximum health every sec."] },
    [6]  = { name = L["Gold"], pct = true, text = L["Increases gold found by %s."] },
    [7]  = { name = L["Experience"], pct = true, text = L["Increases experience gained by %s."] },
    [8]  = { name = L["Pickup range"], pct = true, cap = 400, text = L["Increases pickup range by %s."] },
    [9]  = { name = L["Leech"], pct = true, text = L["Your hits have a %s chance to heal you for 1%% of maximum health."] },
    [10] = { name = L["Area"], pct = true, curve = 60, text = L["Increases the size of your AoE spells by %s."] },
    [11] = { name = L["Duration"], pct = true, text = L["Increases the duration of your spells by %s."] },
    [12] = { name = L["Armor"], text = L["Reduces damage taken by %s."] },
    [14] = { name = L["Dodge chance"], short = L["Dodge"], pct = true, cap = 60, text = L["Increases your chance to dodge attacks by %s."] },
    [15] = { name = L["Critical strike chance"], short = L["Crit chance"], pct = true, text = L["Increases your critical strike chance by %s."] },
    [16] = { name = L["Critical strike damage"], short = L["Crit damage"], pct = true, text = L["Increases critical strike damage by %s."] },
    [17] = { name = L["Shield"], pct = true, text = L["Absorbs damage equal to %s of maximum health."], note = L["Shield is restored after 4 sec without taking damage."] },
    [18] = { name = L["Luck"], text = L["Improves the rarity of chest and level-up choices."] },
    [19] = { name = L["Poison damage"], pct = true, text = L["Increases Poison damage by %s."] },
}
local STAT_ORDER = { 0, 12, 14, 15, 16, 17, 1, 10, 8, 18, 4, 3, 5, 9, 11, 19, 6, 7, 2 }

VB.statTips = {
    s0 = { name = L["Power"], text = L["Increases all damage you and your minions deal."] },
    s1 = { name = L["Haste"], text = L["Increases the speed of your attacks, damage over time and minions."] },
    s2 = { name = L["Count"], text = L["Your spells fire extra bolts, shots or swings. Does not affect AoE spells."] },
    s3 = { name = L["Movement speed"], text = L["Increases movement speed."] },
    s4 = { name = L["Maximum health"], text = L["Increases maximum health."] },
    s5 = { name = L["Health regeneration"], text = L["Restores a share of maximum health every sec."] },
    s7 = { name = L["Experience"], text = L["Increases experience gained."] },
    s8 = { name = L["Pickup range"], text = L["Increases the range you collect experience, food and gear from."] },
    s10 = { name = L["Area"], text = L["Increases the size of your AoE spells."] },
    s12 = { name = L["Armor"], text = L["Reduces damage taken."] },
    s14 = { name = L["Dodge chance"], text = L["Increases your chance to dodge attacks."] },
    s15 = { name = L["Critical strike chance"], text = L["Increases your critical strike chance."] },
    s16 = { name = L["Critical strike damage"], text = L["Increases critical strike damage."] },
    s18 = { name = L["Luck"], text = L["Improves the rarity of chest and level-up choices."] },
}
function VB.BuildStatTerms(names)
    VB.statTerms = {}
    for text, id in pairs(names) do
        tinsert(VB.statTerms, { text = text, id = id, stat = true })
    end
    VB.keywordTerms = nil
end

VB.BuildStatTerms({
    ["Power"] = "s0", ["Haste"] = "s1", ["Count"] = "s2",
    ["Movement speed"] = "s3", ["movement speed"] = "s3",
    ["Maximum health"] = "s4", ["maximum health"] = "s4", ["Max health"] = "s4",
    ["Health regained each second"] = "s5",
    ["Experience"] = "s7", ["experience"] = "s7",
    ["Pickup range"] = "s8", ["pickup range"] = "s8",
    ["Area"] = "s10", ["Armor"] = "s12",
    ["Dodge chance"] = "s14", ["chance to dodge"] = "s14",
    ["Critical strike chance"] = "s15", ["critical strike chance"] = "s15", ["Crit chance"] = "s15",
    ["Critical strike damage"] = "s16", ["critical strike damage"] = "s16",
    ["Luck"] = "s18",
})

VB.gear = {}
VB.tierGear = { first = 0, tiers = 0, slots = 0, classes = 0, stats = {} }
setmetatable(VB.gear, { __index = function(gear, id)
    local tierGear = VB.tierGear
    local index = (tonumber(id) or 0) - tierGear.first
    local perClass = tierGear.tiers * tierGear.slots
    if tierGear.first == 0 or perClass == 0 or index < 0 or index >= perClass * tierGear.classes then
        return nil
    end
    local stats = tierGear.stats[floor(mod(index, perClass) / tierGear.slots) + 1]
    return stats and { set = 0, stats = stats }
end })
VB.sets = {}
VB.stats = {}
VB.statsInRun = false

local EQUIPPED_SLOTS = 19

local function Percent(value)
    return format("%g", value) .. "%"
end

local function FormatStat(id, value)
    if STATS[id] and STATS[id].pct then
        return Percent(value)
    end
    return format("%g", value)
end

local function ParseStats(text)
    local stats = {}
    for _, pair in ipairs(Split(text or "", ",")) do
        local colon = strfind(pair, ":", 1, true)
        if colon then
            local id = tonumber(strsub(pair, 1, colon - 1))
            if id then
                stats[id] = tonumber(strsub(pair, colon + 1)) or 0
            end
        end
    end
    return stats
end

local function ItemIdFromLink(link)
    if not link then
        return nil
    end
    local _, _, id = strfind(link, "item:(%d+)")
    return tonumber(id)
end

local function WornItems()
    local worn = {}
    for slot = 1, EQUIPPED_SLOTS do
        local id = ItemIdFromLink(GetInventoryItemLink("player", slot))
        if id then
            worn[id] = true
        end
    end
    return worn
end

local function IsPieceWorn(piece, worn)
    for _, entry in ipairs(piece.entries) do
        if worn[entry] then
            return true
        end
    end
    return false
end

local function WornPieces(set, worn)
    local count = 0
    for _, piece in ipairs(set.pieces) do
        if IsPieceWorn(piece, worn) then
            count = count + 1
        end
    end
    return count
end

local function GearTotals()
    local totals = {}
    local counts = {}
    for slot = 1, EQUIPPED_SLOTS do
        local id = ItemIdFromLink(GetInventoryItemLink("player", slot))
        local stat = id and VB.gear[id]
        if stat then
            for statId, value in pairs(stat.stats) do
                totals[statId] = (totals[statId] or 0) + value
            end
            if stat.set > 0 then
                counts[stat.set] = (counts[stat.set] or 0) + 1
            end
        end
        local enchant = VanillaBonkUI.enchants and VanillaBonkUI.enchants[slot]
        if enchant then
            totals[enchant.stat] = (totals[enchant.stat] or 0) + enchant.value
        end
        local found = VanillaBonkUI.FoundAt and VanillaBonkUI.FoundAt("inv", slot)
        if found then
            for statId, value in pairs(found.extra) do
                totals[statId] = (totals[statId] or 0) + value
            end
            for _, line in ipairs(found.lines) do
                totals[line.stat] = (totals[line.stat] or 0) + line.value
            end
        end
    end

    local active = {}
    for setId, count in pairs(counts) do
        local set = VB.sets[setId]
        if set then
            for _, bonus in ipairs(set.bonuses) do
                if count >= bonus.pieces then
                    for statId, value in pairs(bonus.stats) do
                        totals[statId] = (totals[statId] or 0) + value
                    end
                    tinsert(active, { set = set.name, pieces = bonus.pieces, text = bonus.text })
                end
            end
        end
    end
    return totals, active
end

local PRIMARY_STATS = { 12, 0, 4 }

function PRIMARY_STATS.Has(statId)
    for _, primary in ipairs(PRIMARY_STATS) do
        if primary == statId then
            return true
        end
    end
    return false
end

function PRIMARY_STATS.AddLine(tooltip, statId, value, r, g, b)
    if not value or value == 0 then
        return
    end
    local sign = value > 0 and "+" or ""
    tooltip:AddLine(sign .. FormatStat(statId, value) .. " " .. STATS[statId].name, r, g, b)
end

function VanillaBonkUI.StatText(statId, value)
    local stat = STATS[statId]
    if not stat or not value then
        return ""
    end
    return (value > 0 and "+" or "") .. FormatStat(statId, value) .. " " .. stat.name
end

function VanillaBonkUI.StatRangeText(statId, low, high)
    if not STATS[statId] or not low or not high then
        return ""
    end
    return "(" .. FormatStat(statId, low) .. "-" .. FormatStat(statId, high) .. ")"
end

local function AddGearLines(tooltip, link, found, enchantLine)
    local id = ItemIdFromLink(link)
    local stat = id and VB.gear[id]
    if not stat then
        return
    end

    local extra = found and found.extra or {}
    for _, statId in ipairs(PRIMARY_STATS) do
        PRIMARY_STATS.AddLine(tooltip, statId, (stat.stats[statId] or 0) + (extra[statId] or 0), 1, 1, 1)
    end
    for _, statId in ipairs(STAT_ORDER) do
        if not PRIMARY_STATS.Has(statId) then
            PRIMARY_STATS.AddLine(tooltip, statId, (stat.stats[statId] or 0) + (extra[statId] or 0), 0.12, 1, 0.12)
        end
    end
    if found then
        local color = VanillaBonkUI.FOUND_LINE_COLOR
        for _, line in ipairs(found.lines) do
            PRIMARY_STATS.AddLine(tooltip, line.stat, line.value, color[1], color[2], color[3])
        end
    end
    if enchantLine then
        tooltip:AddLine(enchantLine, 0.12, 1, 0.12)
    end
    local tier = found and found.tier or (VanillaBonkUI.GearTier and VanillaBonkUI.GearTier(id))
    local tierText = tier and tooltip:GetName() and getglobal(tooltip:GetName() .. "TextRight1")
    if tierText then
        tierText:SetText(L["Tier "] .. tier)
        tierText:SetTextColor(1, 0.82, 0)
        tierText:Show()
    end
    local proc = VanillaBonkUI.trinketTips and VanillaBonkUI.trinketTips[id]
    if proc then
        local bindLine = tooltip:GetName() and getglobal(tooltip:GetName() .. "TextLeft2")
        local bindText = bindLine and bindLine:GetText()
        if bindText == ITEM_BIND_ON_PICKUP then
            bindLine:SetText(bindText .. "\n" .. L["Unique-Equipped (1)"])
        elseif not (bindText and strfind(bindText, L["Unique-Equipped"], 1, true)) then
            tooltip:AddLine(L["Unique-Equipped (1)"], 1, 1, 1)
        end
        tooltip:AddLine(L["Equip: "] .. proc, 0.12, 1, 0.12, 1)
    end

    local set = stat.set > 0 and VB.sets[stat.set]
    if set then
        local worn = WornItems()
        local count = WornPieces(set, worn)
        tooltip:AddLine(" ")
        tooltip:AddLine(set.name .. " (" .. count .. "/" .. getn(set.pieces) .. ")", 1, 0.82, 0)
        for _, piece in ipairs(set.pieces) do
            if IsPieceWorn(piece, worn) then
                tooltip:AddLine("  " .. piece.name, 1, 1, 0.6)
            else
                tooltip:AddLine("  " .. piece.name, 0.5, 0.5, 0.5)
            end
        end
        tooltip:AddLine(" ")
        for _, bonus in ipairs(set.bonuses) do
            local text = "(" .. bonus.pieces .. L[") Set: "] .. bonus.text
            if count >= bonus.pieces then
                tooltip:AddLine(text, 0.1, 1, 0.1, 1)
            else
                tooltip:AddLine(text, 0.5, 0.5, 0.5, 1)
            end
        end
    end
    tooltip:Show()
end

VanillaBonkUI.AddGearLines = AddGearLines

local function HookTooltip(tooltip, method, linkOf)
    local original = tooltip and tooltip[method]
    if not original then
        return
    end
    tooltip[method] = function(self, a1, a2, a3)
        local r1, r2, r3 = original(self, a1, a2, a3)
        AddGearLines(self, linkOf(a1, a2, a3))
        return r1, r2, r3
    end
end

do
    local SOLID_TOOLTIP = {
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 },
    }

    local function MakeTooltipSolid(tooltip)
        if not tooltip then
            return
        end
        local background = TOOLTIP_DEFAULT_BACKGROUND_COLOR or { r = 0.09, g = 0.09, b = 0.19 }
        local border = TOOLTIP_DEFAULT_COLOR or { r = 1, g = 1, b = 1 }
        tooltip:SetBackdrop(SOLID_TOOLTIP)
        tooltip:SetBackdropColor(background.r, background.g, background.b)
        tooltip:SetBackdropBorderColor(border.r, border.g, border.b)
    end

    MakeTooltipSolid(GameTooltip)
    MakeTooltipSolid(ItemRefTooltip)
end

HookTooltip(GameTooltip, "SetBagItem", function(bag, slot) return GetContainerItemLink(bag, slot), VanillaBonkUI.FoundAt(bag, slot) end)
HookTooltip(GameTooltip, "SetInventoryItem", function(unit, slot)
    if unit ~= "player" then
        return GetInventoryItemLink(unit, slot)
    end
    return GetInventoryItemLink(unit, slot), VanillaBonkUI.FoundAt("inv", slot), VanillaBonkUI.EnchantLine and VanillaBonkUI.EnchantLine(slot)
end)
HookTooltip(GameTooltip, "SetMerchantItem", function(index) return GetMerchantItemLink(index) end)
HookTooltip(GameTooltip, "SetLootItem", function(slot) return GetLootSlotLink(slot) end)
HookTooltip(GameTooltip, "SetHyperlink", function(link) return link, VanillaBonkUI.TakeHyperlinkFound() end)
HookTooltip(ItemRefTooltip, "SetHyperlink", function(link) return link end)

local function GearLinkNamed(name)
    if not name then
        return nil
    end
    for id in pairs(VB.gear) do
        if GetItemInfo(id) == name then
            return "item:" .. id .. ":0:0:0"
        end
    end
end

local function InboxItemLink(index)
    return GearLinkNamed(GetInboxItem(index))
end

HookTooltip(GameTooltip, "SetInboxItem", InboxItemLink)

local SLOTS_BY_EQUIP_LOC = {
    INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 }, INVTYPE_BODY = { 4 },
    INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 }, INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 },
    INVTYPE_FEET = { 8 }, INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 }, INVTYPE_FINGER = { 11, 12 },
    INVTYPE_TRINKET = { 13, 14 }, INVTYPE_CLOAK = { 15 }, INVTYPE_WEAPON = { 16, 17 },
    INVTYPE_SHIELD = { 17 }, INVTYPE_2HWEAPON = { 16 }, INVTYPE_WEAPONMAINHAND = { 16 },
    INVTYPE_WEAPONOFFHAND = { 17 }, INVTYPE_HOLDABLE = { 17 }, INVTYPE_RANGED = { 18 },
    INVTYPE_THROWN = { 18 }, INVTYPE_RANGEDRIGHT = { 18 }, INVTYPE_RELIC = { 18 }, INVTYPE_TABARD = { 19 },
}

local function HideCompare()
    for index = 1, 2 do
        local tooltip = getglobal("ShoppingTooltip" .. index)
        if tooltip then
            tooltip:Hide()
        end
    end
end

local function EquippedSlotsFor(link)
    local id = ItemIdFromLink(link)
    if not id then
        return nil
    end
    local _, _, _, _, _, _, _, equipLoc = GetItemInfo(id)
    return equipLoc and SLOTS_BY_EQUIP_LOC[equipLoc]
end

local function CursorOnRightHalf()
    local x = GetCursorPosition()
    return x / UIParent:GetEffectiveScale() > GetScreenWidth() / 2
end

local function ShowCompare(link)
    HideCompare()
    local slots = EquippedSlotsFor(link)
    if not slots or not ShoppingTooltip1 then
        return
    end

    local onLeft = CursorOnRightHalf()
    local previous = GameTooltip
    local shown = 0
    for _, slot in ipairs(slots) do
        if shown < 2 and GetInventoryItemLink("player", slot) then
            shown = shown + 1
            local tooltip = getglobal("ShoppingTooltip" .. shown)
            tooltip:SetOwner(GameTooltip, "ANCHOR_NONE")
            tooltip:ClearAllPoints()
            local gap = previous == GameTooltip and -10 or 0
            if onLeft then
                tooltip:SetPoint("TOPRIGHT", previous, "TOPLEFT", 0, gap)
            else
                tooltip:SetPoint("TOPLEFT", previous, "TOPRIGHT", 0, gap)
            end
            tooltip:SetInventoryItem("player", slot)
            previous = tooltip
        end
    end
end

local function CompareOn(method, linkOf)
    local original = GameTooltip[method]
    if not original then
        return
    end
    GameTooltip[method] = function(self, a1, a2, a3)
        local r1, r2, r3 = original(self, a1, a2, a3)
        ShowCompare(linkOf(a1, a2, a3))
        return r1, r2, r3
    end
end

CompareOn("SetBagItem", function(bag, slot) return GetContainerItemLink(bag, slot) end)
CompareOn("SetLootItem", function(slot) return GetLootSlotLink(slot) end)
CompareOn("SetMerchantItem", function(index) return GetMerchantItemLink(index) end)
CompareOn("SetInboxItem", InboxItemLink)

local compareOnHide = GameTooltip:GetScript("OnHide")
GameTooltip:SetScript("OnHide", function()
    if compareOnHide then
        compareOnHide()
    end
    HideCompare()
end)
local function WornLinkNamed(tooltip)
    for line = 1, 3 do
        local text = getglobal(tooltip:GetName() .. "TextLeft" .. line)
        local name = text and text:GetText()
        if name and name ~= "" then
            for slot = 1, EQUIPPED_SLOTS do
                local link = GetInventoryItemLink("player", slot)
                if link and strfind(link, "[" .. name .. "]", 1, true) then
                    return link, name, slot
                end
            end
        end
    end
end

for _, name in ipairs({ "ShoppingTooltip1", "ShoppingTooltip2" }) do
    local tooltip = getglobal(name)
    if tooltip then
        local onUpdate = tooltip:GetScript("OnUpdate")
        tooltip:SetScript("OnUpdate", function()
            if onUpdate then
                onUpdate()
            end
            local link, itemName, slot = WornLinkNamed(this)
            if link and (itemName ~= this.bonkItem or this:NumLines() < (this.bonkLines or 0)) then
                this.bonkItem = itemName
                AddGearLines(this, link, VanillaBonkUI.FoundAt("inv", slot))
                this.bonkLines = this:NumLines()
            end
        end)
        local onHide = tooltip:GetScript("OnHide")
        tooltip:SetScript("OnHide", function()
            if onHide then
                onHide()
            end
            this.bonkItem = nil
            this.bonkLines = nil
        end)
    end
end

function VanillaBonk_HookItemTooltip(tooltip)
    HookTooltip(tooltip, "SetHyperlink", function(link) return link, VanillaBonkUI.TakeHyperlinkFound() end)
end

function VanillaBonk_AddGearLines(tooltip, link, found)
    AddGearLines(tooltip, link, found)
    local name = getglobal(tooltip:GetName() .. "TextLeft1")
    tooltip.bonkItem = name and name:GetText()
    tooltip.bonkLines = tooltip:NumLines()
end
if GetBuybackItemLink then
    HookTooltip(GameTooltip, "SetBuybackItem", function(index) return GetBuybackItemLink(index) end)
end

local heroStats = CreateFrame("Frame", "VanillaBonkHeroStats", PaperDollFrame)
if CharacterAttributesFrame then
    heroStats:SetAllPoints(CharacterAttributesFrame)
else
    heroStats:SetPoint("TOPLEFT", PaperDollFrame, "TOPLEFT", 67, -291)
    heroStats:SetWidth(230)
    heroStats:SetHeight(78)
end

local STAT_ROW_HEIGHT = 11

local function CreateStatLine(column, row)
    local line = CreateFrame("Frame", nil, heroStats)
    line:SetWidth(104)
    line:SetHeight(STAT_ROW_HEIGHT)
    line:SetPoint("TOPLEFT", heroStats, "TOPLEFT", column == 1 and 6 or 122, -1 - (row - 1) * STAT_ROW_HEIGHT)
    line:EnableMouse(true)

    line.label = line:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    line.label:SetPoint("LEFT", line, "LEFT", 0, 0)
    line.value = line:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    line.value:SetPoint("RIGHT", line, "RIGHT", 0, 0)

    line:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText(this.title or "", 1, 1, 1)
        for _, text in ipairs(this.lines or {}) do
            GameTooltip:AddLine(text, 1, 0.82, 0, 1)
        end
        GameTooltip:Show()
    end)
    line:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return line
end

local STAT_LAYOUT = {
    { 0, 1, 15, 16, 10, 18 },
    { 12, 14, 17, 4, 3, 8 },
}
local statLines = {}
for column, ids in ipairs(STAT_LAYOUT) do
    for row, statId in ipairs(ids) do
        local line = CreateStatLine(column, row)
        line.label:SetText((STATS[statId].short or STATS[statId].name) .. ":")
        statLines[statId] = line
    end
end
local setsLine = CreateStatLine(2, 7)
setsLine.label:SetText(L["Set bonuses:"])

local function RefreshHeroStats()
    if CharacterAttributesFrame then
        CharacterAttributesFrame:Hide()
    end

    local gear, active = GearTotals()

    for statId, line in pairs(statLines) do
        local stat = STATS[statId]
        local gearTotal = gear[statId] or 0
        local fromGear = stat.gearCap and min(gearTotal, stat.gearCap) or gearTotal
        local fromRest = VB.stats[statId] or 0
        local total = fromGear + fromRest
        if statId == 0 then
            total = ((1 + fromRest / 100) * (1 + fromGear / 200) - 1) * 100
        end
        local shown = stat.cap and min(total, stat.cap) or total
        if stat.curve and total > 0 then
            shown = floor(10 * stat.curve * (1 - math.exp(-total / stat.curve)) + 0.5) / 10
        end

        local compact = math.abs(shown) >= 100 and floor(shown + 0.5) or floor(10 * shown + 0.5) / 10
        line.value:SetText(FormatStat(statId, compact))
        line.title = stat.name
        local explained = FormatStat(statId, shown)
        if statId == 12 then
            explained = Percent(floor(1000 * min(0.6, max(0, shown) / (max(0, shown) * 4 / 3 + 100)) + 0.5) / 10)
        end
        line.lines = { format(stat.text, explained) }
        if statId == 9 and shown > 0 then
            tinsert(line.lines, "Heals at most " .. Percent(floor(3 * shown + 0.5) / 100) .. " of maximum health per sec.")
        end
        if statId == 12 and shown > 300 then
            tinsert(line.lines, "Armor past 300 gives " .. Percent(floor(5 * (shown - 300) + 0.5) / 10) .. " maximum health.")
        end
        if stat.cap then
            tinsert(line.lines, L["Maximum "] .. FormatStat(statId, stat.cap) .. ".")
        end
        if stat.note then
            tinsert(line.lines, " ")
            tinsert(line.lines, stat.note)
        end
    end

    setsLine.value:SetText(tostring(getn(active)))
    setsLine.title = L["Set bonuses"]
    setsLine.lines = {}
    for _, bonus in ipairs(active) do
        tinsert(setsLine.lines, bonus.set .. " (" .. bonus.pieces .. "): " .. bonus.text)
    end
    if getn(active) == 0 then
        tinsert(setsLine.lines, L["Wear 2 or more pieces of an epic set from the Inn's gear vendor."])
    end
end

local paperDollOnShow = PaperDollFrame:GetScript("OnShow")
PaperDollFrame:SetScript("OnShow", function()
    if paperDollOnShow then
        paperDollOnShow()
    end
    RefreshHeroStats()
end)

local gearEvents = CreateFrame("Frame")
gearEvents:RegisterEvent("UNIT_INVENTORY_CHANGED")
gearEvents:SetScript("OnEvent", function()
    if arg1 == "player" and PaperDollFrame:IsVisible() then
        RefreshHeroStats()
    end
end)

handlers["gear"] = function(f)
    VB.gear[tonumber(f[2])] = { set = tonumber(f[3]) or 0, stats = ParseStats(f[4]) }
end

handlers["tiergear"] = function(f)
    VB.tierGear.first = tonumber(f[2]) or 0
    VB.tierGear.tiers = tonumber(f[3]) or 0
    VB.tierGear.slots = tonumber(f[4]) or 0
    VB.tierGear.classes = tonumber(f[5]) or 0
end

handlers["tierstats"] = function(f)
    VB.tierGear.stats[tonumber(f[2]) or 0] = ParseStats(f[3])
end

handlers["set"] = function(f)
    local set = { name = f[3], pieces = {}, bonuses = {} }
    local byName = {}
    for _, piece in ipairs(Split(f[4] or "", ",")) do
        local colon = strfind(piece, ":", 1, true)
        if colon then
            local entry, name = tonumber(strsub(piece, 1, colon - 1)), strsub(piece, colon + 1)
            if byName[name] then
                tinsert(byName[name].entries, entry)
            else
                byName[name] = { entry = entry, name = name, entries = { entry } }
                tinsert(set.pieces, byName[name])
            end
        end
    end
    VB.sets[tonumber(f[2])] = set
end

handlers["setbonus"] = function(f)
    local set = VB.sets[tonumber(f[2])]
    if set then
        tinsert(set.bonuses, { pieces = tonumber(f[3]) or 0, stats = ParseStats(f[4]), text = f[5] or "" })
    end
end

handlers["gearend"] = function()
    if PaperDollFrame:IsVisible() then
        RefreshHeroStats()
    end
end

handlers["stats"] = function(f)
    VB.statsInRun = f[2] == "1"
    VB.stats = {}
    local values = Split(f[3] or "", ",")
    for i = 1, getn(values) do
        VB.stats[i - 1] = tonumber(values[i]) or 0
    end
    if PaperDollFrame:IsVisible() then
        RefreshHeroStats()
    end
end

local shieldBar = CreateFrame("StatusBar", "VanillaBonkShieldBar", PlayerFrame)
shieldBar:SetAllPoints(PlayerFrameHealthBar)
shieldBar:SetFrameLevel(PlayerFrameHealthBar:GetFrameLevel() + 1)
VanillaBonkUI.DressShield(shieldBar)
shieldBar:Hide()
VB.shield = 0

local function RefreshShield()
    local maxHealth = UnitHealthMax("player")
    if VB.shield <= 0 or not maxHealth or maxHealth <= 0 then
        shieldBar:Hide()
        return
    end
    shieldBar:SetValue(min(1, VB.shield / maxHealth))
    shieldBar:Show()
end

handlers["shield"] = function(f)
    VB.shield = tonumber(f[2]) or 0
    RefreshShield()
end

local necroticText = PlayerFrame:CreateFontString(nil, "OVERLAY")
SetFont(necroticText, 11)
necroticText:SetPoint("TOPLEFT", PlayerFrameManaBar, "BOTTOMLEFT", 0, -4)
necroticText:SetTextColor(0.4, 1, 0.3)

handlers["necrotic"] = function(f)
    local stacks = tonumber(f[2]) or 0
    if stacks > 0 then
        necroticText:SetText(L["Necrotic x"] .. stacks .. ": " .. (f[3] or "") .. L[" less healing"])
    else
        necroticText:SetText("")
    end
end

do
    local woundsText = PlayerFrame:CreateFontString(nil, "OVERLAY")
    SetFont(woundsText, 11)
    woundsText:SetPoint("TOPLEFT", necroticText, "BOTTOMLEFT", 0, -2)
    woundsText:SetTextColor(1, 0.3, 0.3)

    handlers["wounds"] = function(f)
        local stacks = tonumber(f[2]) or 0
        if stacks > 0 then
            woundsText:SetText(L["Wounded x"] .. stacks .. ": " .. (f[3] or "") .. L[" less healing"])
        else
            woundsText:SetText("")
        end
    end
end

local shieldEvents = CreateFrame("Frame")
shieldEvents:RegisterEvent("UNIT_MAXHEALTH")
shieldEvents:SetScript("OnEvent", function()
    if arg1 == "player" then
        RefreshShield()
    end
end)

local function Handle(text)
    local fields = Split(strsub(text, strlen(PREFIX) + 1), "~")
    local handler = handlers[fields[1]]
    if handler then
        handler(fields)
    end
end

local function LinePattern(text)
    if not text then
        return nil
    end
    text = gsub(text, "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    text = gsub(text, "%%%%s", ".+")
    text = gsub(text, "%%%%d", "%%d+")
    return "^" .. text .. "$"
end

local HIDDEN_SYSTEM_LINES = {}
for _, text in ipairs({ ERR_LEARN_SPELL_S, ERR_LEARN_ABILITY_S, ERR_SPELL_UNLEARNED_S, ERR_SKILL_GAINED_S, ERR_SKILL_UP_SI }) do
    local pattern = LinePattern(text)
    if pattern then
        tinsert(HIDDEN_SYSTEM_LINES, pattern)
    end
end

local HIDDEN_CHANNEL_NOTICES = { YOU_JOINED = true, YOU_CHANGED = true, YOU_LEFT = true }

local OriginalChatFrameOnEvent = ChatFrame_OnEvent
function ChatFrame_OnEvent(event)
    if event == "PLAYER_LEVEL_UP" or event == "CHAT_MSG_SKILL" then
        return
    end
    if event == "CHAT_MSG_CHANNEL_NOTICE" and HIDDEN_CHANNEL_NOTICES[arg1] then
        return
    end
    if event == "CHAT_MSG_SYSTEM" and arg1 then
        if strsub(arg1, 1, strlen(PREFIX)) == PREFIX then
            return
        end
        for _, pattern in ipairs(HIDDEN_SYSTEM_LINES) do
            if strfind(arg1, pattern) then
                return
            end
        end
    end
    OriginalChatFrameOnEvent(event)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("CHAT_MSG_SYSTEM")
events:RegisterEvent("PLAYER_MONEY")
events:SetScript("OnEvent", function()
    if event == "CHAT_MSG_SYSTEM" then
        if arg1 and strsub(arg1, 1, strlen(PREFIX)) == PREFIX then
            Handle(arg1)
        end
    elseif event == "PLAYER_MONEY" then
        PlayPurchaseSound()
        if shop:IsShown() then
            RefreshShop()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        VB.lastMoney = GetMoney()
        if not VB.helloSent then
            VB.helloSent = true
            Command("hello " .. UI.Language())
        end
    end
end)

function UI.NavPrompt(box, primary, second)
    box.navButtons = { primary, second }
    UI.navPrompts = UI.navPrompts or {}
    tinsert(UI.navPrompts, box)
end
